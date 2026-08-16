// ============================================================================
// 🆕 [2026-08-16 신규 - 알람 우회로(감시자)] ReminderWatcherService
//
// ⚠️ [왜 만들었는지] flutter_local_notifications의 "예약(zonedSchedule) →
// 시스템이 알아서 나중에 자동 발동" 경로가 이 기기(삼성 One UI)에서 계속
// 실패했습니다. Logcat 정밀 분석 결과: 시스템(AlarmManager)은 예약을
// 정확히 등록하고, 목표 시각에 신호(브로드캐스트)까지 정확히 보내는 게
// 확인됐지만, 그 신호를 받은 뒤 실제로 화면에 알림을 띄우는 마지막 단계가
// 매번 조용히 실패했습니다(오류/충돌 기록도 전혀 없음). 반면 "예약 없이
// 지금 당장 띄우는" 즉시 알림(NotificationService.showNow/showCustomNow)은
// 100% 정상 작동하는 게 확인되었습니다.
//
// 그래서 이 파일은, 고장난 "자동 발동"을 기다리는 대신, 앱이 켜져 있는
// 동안 직접 "지금이 알림 시각인 항목이 있는지" 30초마다 확인하고, 있으면
// 이미 검증된 즉시 알림 방식으로 그 자리에서 바로 띄우는 우회로입니다.
//
// ⚠️ [제약사항] 이 방식은 앱 프로세스가 살아있어야 작동합니다. 포그라운드는
// 물론, 백그라운드로 보내도 되지만, 완전히 종료(최근 앱 목록에서 스와이프로
// 지움)하면 타이머가 멈춰서 그동안은 감시가 안 됩니다. 나중에 여유가
// 되면 포그라운드 서비스(foreground service) 방식으로 업그레이드해서
// 앱을 완전히 꺼도 계속 감시하게 만들 수 있습니다. 지금은 "전혀 안 울리는"
// 상태보다 훨씬 낫다는 판단으로 우선 이 방식으로 구현합니다.
//
// ⚠️ [기존 예약(scheduleAt) 로직과의 관계] 기존의 scheduleAt()/cancel()은
// 그대로 남겨뒀습니다. 혹시 나중에 OS 업데이트나 플러그인 업데이트로
// 정상화되면 자동으로 같이 작동할 수 있도록 안전망 역할입니다. 이 감시자는
// 완전히 별도로 추가된 것이라, 기존 코드는 전혀 건드리지 않았습니다.
// ============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reminder_data_service.dart';
import 'appointment_data_service.dart';
import 'notification_service.dart';

class ReminderWatcherService {
  ReminderWatcherService._();
  static final ReminderWatcherService instance = ReminderWatcherService._();

  Timer? _timer;
  bool _isRunning = false;

  // 🆕 같은 세션(앱 실행 중) 안에서 중복 확인을 줄이기 위한 메모리 캐시.
  // 실제 중복 방지의 최종 근거는 SharedPreferences(아래)입니다.
  final Set<String> _firedKeysCache = {};

  static const String _prefsKeyPrefix = 'gke_watcher_fired_';

  // 🆕 앱이 실행되는 동안 딱 한 번만 타이머가 시작되도록 방지 (여러 화면에서
  // 중복으로 start()를 호출해도 안전함)
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    debugPrint('[ReminderWatcherService] 감시 시작 (30초마다 확인)');
    _tick(); // 시작하자마자 한 번 즉시 확인
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    debugPrint('[ReminderWatcherService] 감시 중지');
  }

  Future<void> _tick() async {
    try {
      await _checkReminders();
    } catch (e) {
      debugPrint('[ReminderWatcherService] 리마인더 확인 중 오류(무시하고 계속): $e');
    }
    try {
      await _checkAppointments();
    } catch (e) {
      debugPrint('[ReminderWatcherService] 약속 확인 중 오류(무시하고 계속): $e');
    }
  }

  String _todayKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<bool> _alreadyFired(String fireKey) async {
    if (_firedKeysCache.contains(fireKey)) return true;
    final prefs = await SharedPreferences.getInstance();
    final bool fired = prefs.getBool(fireKey) ?? false;
    if (fired) _firedKeysCache.add(fireKey);
    return fired;
  }

  Future<void> _markFired(String fireKey) async {
    _firedKeysCache.add(fireKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(fireKey, true);
  }

  Future<void> _checkReminders() async {
    final items = await ReminderDataService.loadAll();
    final now = DateTime.now();
    final String todayKey = _todayKey(now);

    for (final item in items) {
      if (!item.isEnabled) continue;
      if (item.time.isEmpty) continue;

      final timeParts = item.time.split(':');
      if (timeParts.length != 2) continue;
      final int hh = int.tryParse(timeParts[0]) ?? -1;
      final int mm = int.tryParse(timeParts[1]) ?? -1;
      if (hh < 0 || mm < 0) continue;

      bool isDueNow;
      if (item.repeatType == '매일') {
        isDueNow = now.hour == hh && now.minute == mm;
      } else if (item.repeatType == '매주') {
        final itemDate = DateTime.tryParse(item.date);
        isDueNow = itemDate != null && itemDate.weekday == now.weekday && now.hour == hh && now.minute == mm;
      } else {
        // 한번(1회성): 날짜 + 시간 둘 다 정확히 일치해야 함
        isDueNow = item.date == todayKey && now.hour == hh && now.minute == mm;
      }

      if (!isDueNow) continue;

      final String fireKey = '$_prefsKeyPrefix reminder_${item.id}_$todayKey';
      if (await _alreadyFired(fireKey)) continue;

      debugPrint('[ReminderWatcherService] 🔔 리마인더 발동 조건 충족: ${item.title} ($todayKey ${item.time})');
      // 🆕 [2026-08-16 변경] 리마인더는 "학습 알람"이라 직접 꺼야 멈추는
      // 반복 알람(fireLoopingAlarm)으로 발동합니다. 약속(_checkAppointments)은
      // 기존처럼 한 번만 알려주는 부드러운 알림(showCustomNow)을 유지합니다.
      await NotificationService.fireLoopingAlarm(
        title: item.title,
        body: item.memo.isNotEmpty ? item.memo : item.title,
        id: 'watcher_reminder_${item.id}_$todayKey',
      );
      await _markFired(fireKey);
    }
  }

  Future<void> _checkAppointments() async {
    final items = await AppointmentDataService.loadAll();
    final now = DateTime.now();
    final String todayKey = _todayKey(now);

    for (final item in items) {
      if (item.isCompleted) continue;
      if (item.time.isEmpty) continue;

      final timeParts = item.time.split(':');
      if (timeParts.length != 2) continue;
      final int hh = int.tryParse(timeParts[0]) ?? -1;
      final int mm = int.tryParse(timeParts[1]) ?? -1;
      if (hh < 0 || mm < 0) continue;

      // 🆕 약속은 반복 개념이 없으므로(1회성) 날짜+시간 둘 다 일치해야 함
      final bool isDueNow = item.date == todayKey && now.hour == hh && now.minute == mm;
      if (!isDueNow) continue;

      final String fireKey = '$_prefsKeyPrefix appointment_${item.id}_$todayKey';
      if (await _alreadyFired(fireKey)) continue;

      final String body = item.location.isNotEmpty ? '${item.withPerson} · ${item.location}' : item.withPerson;
      debugPrint('[ReminderWatcherService] 🔔 약속 발동 조건 충족: ${item.title} ($todayKey ${item.time})');
      await NotificationService.showCustomNow(
        item.title,
        body.isNotEmpty ? body : item.title,
        id: 'watcher_appointment_${item.id}_$todayKey',
      );
      await _markFired(fireKey);
    }
  }
}
