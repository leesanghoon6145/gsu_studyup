import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:audioplayers/audioplayers.dart'; // 🆕 [2026-08-17] 반복 알람 소리 재생용 (일반 플래너와 동일 패키지, 이미 pubspec에 있음)
import '../global_lang.dart';
import 'widgets/three_color_pencil_icon.dart';
import 'planner_alarm_foreground_task.dart'; // 🆕 [2026-08-18] 알람 켜서 저장할 때만 권한 요청

// ============================================================================
// [GKE StudyUp] 자기주도 플래너 — 실행 탭 전용 알람 서비스
// 🆕 [2026-08-17 재설계] 일반 플래너 쪽에서 Logcat으로 정밀 확인된 사실:
// "예약(zonedSchedule) → 시스템이 알아서 나중에 자동 발동"하는 경로가 이 기기(삼성 One UI)에서
// 조용히 실패함(시스템은 신호를 정확히 보내지만, 그 이후 실제 알림 표시 단계가 매번 실패 — 오류
// 기록도 전혀 없음). 반면 "예약 없이 지금 당장 띄우는" 즉시 알림은 100% 정상 작동함이 확인됨.
// 그래서 이 파일도 동일한 해법을 적용함: 예약(schedule)은 혹시 몰라 안전망으로 그대로 남겨두되,
// 진짜로 울리게 하는 주된 방법은 PlannerAlarmWatcherService(30초마다 직접 확인 후 즉시 발동) +
// 직접 꺼야 멈추는 반복 알람(fireLoopingAlarm)으로 바꿈.
// 🆕 [2026-08-17] 글로벌 타임존 자동감지(flutter_timezone) 새 패키지 의존성은, 아직 검증 안 된
// 알람이 실제로 안 울리는 문제부터 확실히 잡기 위해 일단 제거함. 일반 플래너와 동일하게 검증된
// 고정 Asia/Seoul 방식으로 전환 — 해외 지원은 알람이 확실히 울리는 게 확인된 다음 별도로 논의.
// ============================================================================
class PlannerAlarmService {
  PlannerAlarmService._();

  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const String _channelId = 'gsu_self_directed_planner_alarm_channel';
  static const String _channelName = 'GKE Self-Directed Planner Alarm';
  static const String _channelDesc =
      'Alarms for schedules registered in the Self-Directed Planner execution tab.';

  /// 일정 id → 32bit 양수 알림 ID (다른 서비스와 충돌 방지)
  static int _baseIdFor(String scheduleId) => scheduleId.hashCode & 0x7fffffff;

  /// 요일별 알림 ID (weekly 시 요일마다 별도 예약)
  /// weekday: 0=일 … 6=토
  static int _idForWeekday(String scheduleId, int weekday) =>
      (_baseIdFor(scheduleId) ^ ((weekday + 1) * 0x10000)) & 0x7fffffff;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();

      // 🆕 [2026-08-17] 일반 플래너에서 실제로 검증된 방식으로 통일: 동적 감지 대신
      // 고정 Asia/Seoul. (동적 감지 패키지는 아직 검증 안 된 새 의존성이라 일단 제외함)
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

      const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const InitializationSettings initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
      // 🆕 [2026-08-17] 반복 알람 알림을 탭하거나 "알람 끄기" 버튼을 눌렀을 때 소리를 멈추기 위한 콜백
      await _plugin.initialize(initSettings, onDidReceiveNotificationResponse: _onNotificationResponse);

      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      try {
        await androidImpl?.requestNotificationsPermission();
      } catch (e) {
        debugPrint('[PlannerAlarmService] notification permission: $e');
      }

      // 정확한 알람 권한은 설치 후 1회만 요청 (재시작마다 튕김 방지)
      try {
        final prefs = await SharedPreferences.getInstance();
        final bool already =
            prefs.getBool('gsu_exact_alarm_permission_requested') ?? false;
        if (!already) {
          await androidImpl?.requestExactAlarmsPermission();
          await prefs.setBool('gsu_exact_alarm_permission_requested', true);
        }
      } catch (e) {
        debugPrint('[PlannerAlarmService] exact alarm permission: $e');
      }

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      );
      await androidImpl?.createNotificationChannel(channel);

      _initialized = true;
    } catch (e) {
      debugPrint('[PlannerAlarmService] init failed: $e');
    }
  }

  static NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  /// 기기 로컬 TZ 기준 TZDateTime 생성
  static tz.TZDateTime _tzOf(DateTime localDt) {
    return tz.TZDateTime(
      tz.local,
      localDt.year,
      localDt.month,
      localDt.day,
      localDt.hour,
      localDt.minute,
      localDt.second,
    );
  }

  /// 한 번만 / 매일 / 요일 선택 통합 예약
  ///
  /// [repeat] : 'once' | 'daily' | 'weekly'
  /// [weekdays] : 0=일 … 6=토 (weekly일 때만 사용, 비어 있으면 예약 안 함)
  /// [date] : once일 때 기준 날짜 / daily·weekly일 때 시간만 사용
  static Future<bool> schedule({
    required String scheduleId,
    required DateTime date,
    required String timeHHmm, // "09:00"
    required String title,
    required String body,
    required String repeat, // once | daily | weekly
    List<int> weekdays = const [],
  }) async {
    await initialize();

    // 시간 파싱 강화: "9:00", "09:00", "09:00:00", "9시" 등 방어
    int hh = 0, mm = 0;
    try {
      final cleaned = timeHHmm.trim().replaceAll(RegExp(r'[시분초\s]'), ':');
      final parts = cleaned.split(RegExp(r'[:：]')).where((s) => s.isNotEmpty).toList();
      if (parts.isNotEmpty) hh = int.parse(parts[0]);
      if (parts.length > 1) mm = int.parse(parts[1]);
      if (hh < 0 || hh > 23) hh = 0;
      if (mm < 0 || mm > 59) mm = 0;
    } catch (e) {
      debugPrint('[PlannerAlarmService] time parse fail "$timeHHmm": $e');
    }

    // 기존 예약 전부 취소 후 재등록 (수정 시 중복 방지)
    await cancelAllFor(scheduleId);

    final int notifId = _baseIdFor(scheduleId);
    debugPrint(
        '[PlannerAlarmService] schedule id=$scheduleId notifId=$notifId '
            'repeat=$repeat date=${date.year}-${date.month}-${date.day} '
            'time=$hh:$mm tz=${tz.local.name}');

    try {
      if (repeat == 'once') {
        // 기기 로컬 달력 시각 → TZDateTime (로컬 타임존 성분 그대로)
        final tz.TZDateTime when = tz.TZDateTime(
          tz.local,
          date.year,
          date.month,
          date.day,
          hh,
          mm,
        );
        final now = tz.TZDateTime.now(tz.local);
        if (!when.isAfter(now)) {
          debugPrint('[PlannerAlarmService] past time, skip once: $when (now=$now)');
          return false;
        }
        await _plugin.zonedSchedule(
          notifId,
          title,
          body,
          when,
          _details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('[PlannerAlarmService] once scheduled at $when');
        return true;
      }

      if (repeat == 'daily') {
        tz.TZDateTime when = tz.TZDateTime(tz.local, date.year, date.month, date.day, hh, mm);
        final now = tz.TZDateTime.now(tz.local);
        if (!when.isAfter(now)) {
          when = when.add(const Duration(days: 1));
        }
        await _plugin.zonedSchedule(
          notifId,
          title,
          body,
          when,
          _details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint('[PlannerAlarmService] daily scheduled at $when');
        return true;
      }

      if (repeat == 'weekly') {
        if (weekdays.isEmpty) return false;
        bool any = false;
        final now = tz.TZDateTime.now(tz.local);

        for (final int w in weekdays) {
          // 우리 배열: 0=일 … 6=토 → Dart weekday (월=1 … 일=7)
          final int dartWeekday = w == 0 ? 7 : w;

          final tz.TZDateTime when = _nextWeekdayTime(
            from: now,
            dartWeekday: dartWeekday,
            hour: hh,
            minute: mm,
          );

          await _plugin.zonedSchedule(
            _idForWeekday(scheduleId, w),
            title,
            body,
            when,
            _details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
          debugPrint('[PlannerAlarmService] weekly w=$w scheduled at $when');
          any = true;
        }
        return any;
      }
    } catch (e, st) {
      debugPrint('[PlannerAlarmService] schedule failed: $e\n$st');
    }
    return false;
  }

  /// from 이후(포함하지 않음) 가장 가까운 해당 요일·시각
  static tz.TZDateTime _nextWeekdayTime({
    required tz.TZDateTime from,
    required int dartWeekday,
    required int hour,
    required int minute,
  }) {
    var candidate = tz.TZDateTime(
      tz.local,
      from.year,
      from.month,
      from.day,
      hour,
      minute,
    );
    // 오늘이 해당 요일이고 아직 시각이 안 지났으면 오늘
    if (candidate.weekday == dartWeekday && candidate.isAfter(from)) {
      return candidate;
    }
    // 아니면 다음 해당 요일까지 진행
    int guard = 0;
    while (guard < 8) {
      candidate = candidate.add(const Duration(days: 1));
      if (candidate.weekday == dartWeekday) {
        return tz.TZDateTime(
          tz.local,
          candidate.year,
          candidate.month,
          candidate.day,
          hour,
          minute,
        );
      }
      guard++;
    }
    return candidate;
  }

  static Future<void> cancelAllFor(String scheduleId) async {
    await initialize();
    try {
      await _plugin.cancel(_baseIdFor(scheduleId));
      for (int w = 0; w <= 6; w++) {
        await _plugin.cancel(_idForWeekday(scheduleId, w));
      }
    } catch (e) {
      debugPrint('[PlannerAlarmService] cancel failed: $e');
    }
  }

  /// 하위 호환: 기존 호출부용 래퍼
  static Future<bool> scheduleAlarm({
    required String scheduleId,
    required DateTime dateTime,
    required String title,
    required String body,
  }) {
    final t =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return schedule(
      scheduleId: scheduleId,
      date: dateTime,
      timeHHmm: t,
      title: title,
      body: body,
      repeat: 'once',
    );
  }

  static Future<void> cancelAlarm(String scheduleId) =>
      cancelAllFor(scheduleId);

  // ============================================================================
  // 🆕 [2026-08-17] 직접 꺼야 멈추는 반복 알람 — 일반 플래너의 fireLoopingAlarm과 완전히 동일한
  // 원리이되, 채널·플레이어를 완전히 분리해서 서로 절대 안 부딪히게 함. 이게 실제로 학생에게
  // "확실히 울렸다"고 느끼게 하는 진짜 알람입니다. PlannerAlarmWatcherService가 이 함수를 씀.
  // ============================================================================
  static final AudioPlayer _alarmPlayer = AudioPlayer();
  static Timer? _autoStopTimer;
  static const String _loopingChannelId = 'gsu_self_directed_planner_looping_channel';

  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint('[PlannerAlarmService] 알림 응답: actionId=${response.actionId}');
    stopAlarmSound();
    if (response.id != null) {
      _plugin.cancel(response.id!);
    }
  }

  // 🆕 [2026-08-17] 원장님 지시: "팝업이 즉시 안 뜨고 나갔다 들어와야 뜸" 문제 수정.
  // 1초마다 "지금 울리고 있나?" 물어보는(polling) 방식 대신, 상태가 "바뀌는 바로 그 순간"에
  // 알려주는 ValueNotifier로 전환함. fireLoopingAlarm/stopAlarmSound가 호출되는 즉시 값이
  // 바뀌고, 이걸 구독하는 화면은 폴링 간격 없이 그 즉시 반응함.
  static final ValueNotifier<bool> ringingNotifier = ValueNotifier<bool>(false);

  static Future<void> fireLoopingAlarm({
    required String title,
    required String body,
    String? id,
  }) async {
    await initialize();
    try {
      final int notifId = _baseIdFor(id ?? 'loop_${DateTime.now().millisecondsSinceEpoch}');
      final NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails(
          _loopingChannelId,
          '자기주도 플래너 학습 알람 (반복)',
          channelDescription: '직접 꺼야 멈추는 반복 알람 채널',
          importance: Importance.max,
          priority: Priority.max,
          playSound: false, // 소리는 아래 audioplayers로 직접 반복 재생함(채널 소리는 꺼서 안 겹치게)
          enableVibration: true,
          ongoing: true, // 스와이프로 안 지워짐
          autoCancel: false,
          actions: const [
            AndroidNotificationAction('stop_alarm', '알람 끄기', cancelNotification: true),
          ],
        ),
        iOS: const DarwinNotificationDetails(),
      );
      await _plugin.show(notifId, title, body, details);
      await _startLoopingSound();
      ringingNotifier.value = true; // 🆕 이 줄이 실행되는 즉시 구독 중인 화면이 반응함
      debugPrint('[PlannerAlarmService] ✅ fireLoopingAlarm 표시+재생 시작 (notifId=$notifId)');

      _autoStopTimer?.cancel();
      _autoStopTimer = Timer(const Duration(minutes: 3), () async {
        debugPrint('[PlannerAlarmService] ⏱️ 3분 경과, 안전장치로 반복 알람 자동 정지');
        await stopAlarmSound();
        await _plugin.cancel(notifId);
      });
    } catch (e) {
      debugPrint('[PlannerAlarmService] fireLoopingAlarm 실패: $e');
    }
  }

  static Future<void> _startLoopingSound() async {
    try {
      await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
      await _alarmPlayer.play(AssetSource('sounds/soft_alarm.mp3'));
    } catch (e) {
      debugPrint('[PlannerAlarmService] 반복 재생 시작 실패: $e');
    }
  }

  static Future<bool> isAlarmRinging() async {
    try {
      return _alarmPlayer.state == PlayerState.playing;
    } catch (_) {
      return false;
    }
  }

  static Future<void> stopAlarmSound() async {
    try {
      await _alarmPlayer.stop();
    } catch (e) {
      debugPrint('[PlannerAlarmService] 반복 재생 정지 중 오류(무시): $e');
    }
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    ringingNotifier.value = false; // 🆕 꺼지는 순간도 즉시 반영
  }
}

// ============================================================================
// 🆕 [2026-08-17] PlannerAlarmWatcherService — 진짜로 알람을 울리게 하는 핵심 메커니즘.
// "예약 → 시스템 자동 발동"이 실기기에서 조용히 실패하는 문제를, 앱이 켜져있는 동안 직접
// 30초마다 "지금이 알람 시각인 일정이 있는지" 확인해서, 있으면 검증된 즉시 발동 방식
// (fireLoopingAlarm)으로 바로 띄우는 우회로입니다. 일반 플래너의 ReminderWatcherService와
// 완전히 동일한 설계입니다.
// ⚠️ [제약사항] 앱 프로세스가 살아있어야 작동함(완전 종료 시 감시 중단). 나중에 여유 되면
// 포그라운드 서비스로 업그레이드 가능.
// ============================================================================
class PlannerAlarmWatcherService {
  PlannerAlarmWatcherService._();
  static final PlannerAlarmWatcherService instance = PlannerAlarmWatcherService._();

  Timer? _timer;
  bool _isRunning = false;
  final Set<String> _firedKeysCache = {};
  static const String _prefsKeyPrefix = 'gke_planner_watcher_fired_';

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    debugPrint('[PlannerAlarmWatcherService] 감시 시작 (30초마다 확인)');
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    debugPrint('[PlannerAlarmWatcherService] 감시 중지');
  }

  String _todayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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

  Future<void> _tick() async {
    try {
      await _checkSchedules();
    } catch (e) {
      debugPrint('[PlannerAlarmWatcherService] 확인 중 오류(무시하고 계속): $e');
    }
  }

  Future<void> _checkSchedules() async {
    final DateTime now = DateTime.now();
    final String nowStamp =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('gke_global_schedules');
    if (raw == null || raw.isEmpty) {
      debugPrint('[PlannerAlarmWatcherService] 틱 $nowStamp — 저장된 일정 없음');
      return;
    }

    List<dynamic> decoded;
    try {
      decoded = jsonDecode(raw) as List<dynamic>;
    } catch (e) {
      debugPrint('[PlannerAlarmWatcherService] 틱 $nowStamp — 일정 JSON 파싱 실패: $e');
      return;
    }

    final String todayKey = _todayKey(now);
    final int alarmOnCount = decoded.where((e) => (e as Map)['alarmOn'] == true).length;
    // 🆕 [진단용 2026-08-17] 매 틱마다 "지금 몇 시고, 알람 켜진 항목이 몇 개인지" 반드시 로그로
    // 남김 - 감시자가 실제로 30초마다 돌고 있는지 로그만으로 100% 확인 가능하게 함.
    debugPrint('[PlannerAlarmWatcherService] 틱 $nowStamp — 전체 ${decoded.length}건 중 알람ON ${alarmOnCount}건');

    for (final dynamic rawItem in decoded) {
      final Map<String, dynamic> item = Map<String, dynamic>.from(rawItem as Map);
      if (item['alarmOn'] != true) continue;

      final String timeStr = (item['time'] ?? '').toString();
      final List<String> tp = timeStr.split(':');
      if (tp.length != 2) {
        debugPrint('[PlannerAlarmWatcherService]   - "${item['title']}" 시간 형식 이상함: "$timeStr"');
        continue;
      }
      final int hh = int.tryParse(tp[0]) ?? -1;
      final int mm = int.tryParse(tp[1]) ?? -1;
      if (hh < 0 || mm < 0) {
        debugPrint('[PlannerAlarmWatcherService]   - "${item['title']}" 시간 파싱 실패: "$timeStr"');
        continue;
      }
      // 🆕 [진단용] 알람ON인 모든 항목에 대해, 지금 시각과 얼마나 맞는지 항상 로그로 남김
      debugPrint('[PlannerAlarmWatcherService]   - "${item['title']}" 목표=$hh:$mm 반복=${item['alarmRepeat']} / 지금=${now.hour}:${now.minute}');
      if (now.hour != hh || now.minute != mm) continue; // 지금 이 순간(분 단위)이 아니면 스킵

      final String repeat = (item['alarmRepeat'] ?? 'once').toString();
      bool isDueToday;
      if (repeat == 'daily') {
        isDueToday = true;
      } else if (repeat == 'weekly') {
        final List<int> weekdays = item['alarmWeekdays'] is List
            ? List<int>.from((item['alarmWeekdays'] as List).map((e) => e is int ? e : int.tryParse('$e') ?? -1))
            : <int>[];
        final int todayIdx = now.weekday % 7; // 0=일 … 6=토
        isDueToday = weekdays.contains(todayIdx);
      } else {
        // once: 등록된 그 날짜여야만 발동
        isDueToday = item['year'] == now.year && item['month'] == now.month && item['day'] == now.day;
      }
      if (!isDueToday) {
        debugPrint('[PlannerAlarmWatcherService]   - "${item['title']}" 시간은 맞는데 날짜/요일 조건 불충족');
        continue;
      }

      final String scheduleId = (item['id'] ?? '').toString();
      if (scheduleId.isEmpty) {
        debugPrint('[PlannerAlarmWatcherService]   - "${item['title']}" id 없음, 스킵');
        continue;
      }
      final String fireKey = '$_prefsKeyPrefix${scheduleId}_$todayKey';
      if (await _alreadyFired(fireKey)) {
        debugPrint('[PlannerAlarmWatcherService]   - "${item['title']}" 오늘 이미 발동 기록됨(fireKey=$fireKey)');
        continue;
      }

      debugPrint('[PlannerAlarmWatcherService] 🔔 발동: ${item['title']} ($todayKey $timeStr)');
      await PlannerAlarmService.fireLoopingAlarm(
        title: (item['title'] ?? '').toString(),
        body: '${(item['month'] ?? '').toString().padLeft(2, '0')}/${(item['day'] ?? '').toString().padLeft(2, '0')} 알람 설정',
        id: 'planner_watcher_${scheduleId}_$todayKey',
      );
      await _markFired(fireKey);
    }
  }
}

// ============================================================================
// 🆕 [2026-08-17] PlannerRingingAlarmStopBanner — 지금 울리는 알람을 확실하게 끄는 버튼.
// 안드로이드 알림창의 "알람 끄기" 버튼이 일부 삼성 기기에서 알림 자체가 사라지며 같이 없어지는
// 문제가 있어서, 앱 화면 안에 직접 만든 확실한 끄기 수단입니다. 울리고 있을 때만 나타납니다.
// 🆕 [버그 수정 2026-08-17] 1초 폴링 대신 ValueListenableBuilder로 상태 변화에 즉시 반응하고,
// AnimatedSwitcher로 부드럽게 나타나고 사라지도록 함(기존엔 뚝 튀어나오듯 버벅였음).
// ============================================================================
class PlannerRingingAlarmStopBanner extends StatelessWidget {
  const PlannerRingingAlarmStopBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PlannerAlarmService.ringingNotifier,
      builder: (context, ringing, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(sizeFactor: animation, child: child),
          ),
          child: !ringing
              ? const SizedBox.shrink(key: ValueKey('hidden'))
              : Container(
            key: const ValueKey('shown'),
            margin: const EdgeInsets.only(bottom: 12),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await PlannerAlarmService.stopAlarmSound();
              },
              icon: const Icon(Icons.notifications_off_rounded, size: 22),
              label: Text(
                '지금 울리는 알람 끄기',
                style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 6,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// [GKE StudyUp] 자기주도 학습 플래너 — 실행 스크린 (learning_screen.dart)
// 계획 탭 일정(gke_global_schedules)과 양방향 연동 + 글로벌 알람
// ============================================================================
class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => LearningScreenState();
}

class LearningScreenState extends State<LearningScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final Color schoolColor = const Color(0xFF3B82F6);
  final Color academyColor = const Color(0xFFFACC15);
  final Color examColor = const Color(0xFFEF4444);
  final Color personalColor = const Color(0xFF8B5CF6);
  final Color goldColor = const Color(0xFFD4AF37);
  final Color slate300 = const Color(0xFFCBD5E1);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color slate500 = const Color(0xFF64748B);
  final Color slate800 = const Color(0xFF1E293B);

  List<Map<String, dynamic>> _globalSchedules = [];
  bool _loaded = false;
  late DateTime _displayedMonth;
  late DateTime _selectedDate;
  DateTime? _expandedAlarmDate;
  // 🆕 [2026-08-17] 알람이 울리는 순간 자동으로 끄기 팝업을 띄우기 위한 상태.
  // 이 화면(LearningScreenState)은 AutomaticKeepAliveClientMixin으로 항상 살아있으므로,
  // 다른 탭(계획/리포트)에 있어도 PlannerAlarmService.ringingNotifier 구독은 계속 살아있고,
  // showDialog()는 기본적으로 앱 전체 최상위(root) 네비게이터를 쓰기 때문에 팝업이 어느
  // 화면에 있든 최상단에 즉시 뜸.
  bool _alarmDialogShowing = false;

  // ─── 12개국 언어 ───────────────────────────────────────────
  static const List<String> _foreignLanguages = [
    'JA', 'ZH', 'FR', 'DE', 'RU', 'AR', 'HI', 'VI', 'ES', 'TH'
  ];
  static bool get _isForeignSelected =>
      _foreignLanguages.contains(DkeLang.current);

  static const Map<String, Map<String, String>> _uiText = {
    'sectionExecution': {
      'KO': '오늘 실행 및 알람 캘린더',
      'EN': 'Execution & Alarm Calendar',
      'JA': '実行・アラームカレンダー',
      'ZH': '执行与闹钟日历',
      'FR': 'Exécution et calendrier d\'alarme',
      'DE': 'Ausführung & Alarmkalender',
      'RU': 'Календарь выполнения и будильников',
      'AR': 'التنفيذ وتقويم المنبه',
      'HI': 'निष्पादन और अलार्म कैलेंडर',
      'VI': 'Lịch thực hiện & báo thức',
      'ES': 'Calendario de ejecución y alarmas',
      'TH': 'ปฏิทินการดำเนินการและปลุก'
    },
    'upcomingList': {
      'KO': '다가오는 일정',
      'EN': 'Upcoming Schedule',
      'JA': '近日の日程',
      'ZH': '即将到来的日程',
      'FR': 'Programme à venir',
      'DE': 'Bevorstehender Termin',
      'RU': 'Ближайшее расписание',
      'AR': 'الجدول القادم',
      'HI': 'आगामी कार्यक्रम',
      'VI': 'Lịch sắp tới',
      'ES': 'Próximo horario',
      'TH': 'ตารางที่กำลังจะมาถึง'
    },
    'emptySchedule': {
      'KO': '등록된 일정이 없습니다.',
      'EN': 'No schedule registered.',
      'JA': '登録された日程がありません。',
      'ZH': '暂无已登记的日程。',
      'FR': 'Aucun programme enregistré.',
      'DE': 'Kein Termin registriert.',
      'RU': 'Расписание не добавлено.',
      'AR': 'لا يوجد جدول مسجل.',
      'HI': 'कोई कार्यक्रम दर्ज नहीं है।',
      'VI': 'Chưa có lịch nào được đăng ký.',
      'ES': 'No hay horario registrado.',
      'TH': 'ไม่มีตารางที่ลงทะเบียนไว้'
    },
    'alarmSettingTitle': {
      'KO': '알람 설정',
      'EN': 'Alarm Settings',
      'JA': 'アラーム設定',
      'ZH': '闹钟设置',
      'FR': 'Paramètres d\'alarme',
      'DE': 'Alarmeinstellungen',
      'RU': 'Настройки будильника',
      'AR': 'إعدادات المنبه',
      'HI': 'अलार्म सेटिंग्स',
      'VI': 'Cài đặt báo thức',
      'ES': 'Configuración de alarma',
      'TH': 'ตั้งค่าปลุก'
    },
    'alarmOnLabel': {
      'KO': '알람 켜기',
      'EN': 'Turn On Alarm',
      'JA': 'アラームをオン',
      'ZH': '开启闹钟',
      'FR': 'Activer l\'alarme',
      'DE': 'Alarm einschalten',
      'RU': 'Включить будильник',
      'AR': 'تفعيل المنبه',
      'HI': 'अलार्म चालू करें',
      'VI': 'Bật báo thức',
      'ES': 'Activar alarma',
      'TH': 'เปิดปลุก'
    },
    'noAlarmToday': {
      'KO': '이 날짜에 등록된 일정이 없습니다.',
      'EN': 'No schedule for this date.',
      'JA': 'この日に登録された日程がありません。',
      'ZH': '该日期暂无已登记的日程。',
      'FR': 'Aucun programme pour cette date.',
      'DE': 'Kein Termin für dieses Datum.',
      'RU': 'На эту дату расписание не добавлено.',
      'AR': 'لا يوجد جدول لهذا التاريخ.',
      'HI': 'इस तारीख के लिए कोई कार्यक्रम नहीं है।',
      'VI': 'Không có lịch cho ngày này.',
      'ES': 'No hay horario para esta fecha.',
      'TH': 'ไม่มีตารางสำหรับวันที่นี้'
    },
    'labelTime': {
      'KO': '시간 설정',
      'EN': 'Time',
      'JA': '時間設定',
      'ZH': '时间设置',
      'FR': 'Heure',
      'DE': 'Uhrzeit',
      'RU': 'Время',
      'AR': 'الوقت',
      'HI': 'समय',
      'VI': 'Thời gian',
      'ES': 'Hora',
      'TH': 'เวลา'
    },
    'labelTitleField': {
      'KO': '일정 제목',
      'EN': 'Title',
      'JA': '日程タイトル',
      'ZH': '日程标题',
      'FR': 'Titre',
      'DE': 'Titel',
      'RU': 'Название',
      'AR': 'العنوان',
      'HI': 'शीर्षक',
      'VI': 'Tiêu đề',
      'ES': 'Título',
      'TH': 'ชื่อเรื่อง'
    },
    'labelCategorySelect': {
      'KO': '일정 분류',
      'EN': 'Category',
      'JA': '日程分類',
      'ZH': '日程分类',
      'FR': 'Catégorie',
      'DE': 'Kategorie',
      'RU': 'Категория',
      'AR': 'التصنيف',
      'HI': 'श्रेणी',
      'VI': 'Phân loại',
      'ES': 'Categoría',
      'TH': 'หมวดหมู่'
    },
    'labelRepeat': {
      'KO': '반복',
      'EN': 'Repeat',
      'JA': '繰り返し',
      'ZH': '重复',
      'FR': 'Répétition',
      'DE': 'Wiederholung',
      'RU': 'Повтор',
      'AR': 'تكرار',
      'HI': 'दोहराएँ',
      'VI': 'Lặp lại',
      'ES': 'Repetir',
      'TH': 'ทำซ้ำ'
    },
    'repeatOnce': {
      'KO': '한 번만',
      'EN': 'Once',
      'JA': '一度だけ',
      'ZH': '仅一次',
      'FR': 'Une fois',
      'DE': 'Einmal',
      'RU': 'Один раз',
      'AR': 'مرة واحدة',
      'HI': 'एक बार',
      'VI': 'Một lần',
      'ES': 'Una vez',
      'TH': 'ครั้งเดียว'
    },
    'repeatDaily': {
      'KO': '매일',
      'EN': 'Daily',
      'JA': '毎日',
      'ZH': '每天',
      'FR': 'Tous les jours',
      'DE': 'Täglich',
      'RU': 'Ежедневно',
      'AR': 'يومياً',
      'HI': 'रोज़ाना',
      'VI': 'Hàng ngày',
      'ES': 'Diario',
      'TH': 'ทุกวัน'
    },
    'repeatWeekly': {
      'KO': '요일 선택',
      'EN': 'Weekly',
      'JA': '曜日選択',
      'ZH': '按星期',
      'FR': 'Jours de la semaine',
      'DE': 'Wochentage',
      'RU': 'По дням недели',
      'AR': 'أيام الأسبوع',
      'HI': 'सप्ताह के दिन',
      'VI': 'Theo thứ',
      'ES': 'Días de la semana',
      'TH': 'เลือกวัน'
    },
    'btnClose': {
      'KO': '닫기',
      'EN': 'Close',
      'JA': '閉じる',
      'ZH': '关闭',
      'FR': 'Fermer',
      'DE': 'Schließen',
      'RU': 'Закрыть',
      'AR': 'إغلاق',
      'HI': 'बंद करें',
      'VI': 'Đóng',
      'ES': 'Cerrar',
      'TH': 'ปิด'
    },
    'btnDelete': {
      'KO': '삭제',
      'EN': 'Delete',
      'JA': '削除',
      'ZH': '删除',
      'FR': 'Supprimer',
      'DE': 'Löschen',
      'RU': 'Удалить',
      'AR': 'حذف',
      'HI': 'हटाएं',
      'VI': 'Xóa',
      'ES': 'Eliminar',
      'TH': 'ลบ'
    },
    'btnSave': {
      'KO': '저장',
      'EN': 'Save',
      'JA': '保存',
      'ZH': '保存',
      'FR': 'Enregistrer',
      'DE': 'Speichern',
      'RU': 'Сохранить',
      'AR': 'حفظ',
      'HI': 'सहेजें',
      'VI': 'Lưu',
      'ES': 'Guardar',
      'TH': 'บันทึก'
    },
    'catSchool': {
      'KO': '학교',
      'EN': 'School',
      'JA': '学校',
      'ZH': '学校',
      'FR': 'École',
      'DE': 'Schule',
      'RU': 'Школа',
      'AR': 'المدرسة',
      'HI': 'स्कूल',
      'VI': 'Trường học',
      'ES': 'Escuela',
      'TH': 'โรงเรียน'
    },
    'catAcademy': {
      'KO': '학원',
      'EN': 'Academy',
      'JA': '塾',
      'ZH': '补习班',
      'FR': 'Institut',
      'DE': 'Institut',
      'RU': 'Академия',
      'AR': 'المعهد',
      'HI': 'अकादमी',
      'VI': 'Trung tâm',
      'ES': 'Academia',
      'TH': 'สถาบันกวดวิชา'
    },
    'catExam': {
      'KO': '시험',
      'EN': 'Exam',
      'JA': '試験',
      'ZH': '考试',
      'FR': 'Examen',
      'DE': 'Prüfung',
      'RU': 'Экзамен',
      'AR': 'الاختبار',
      'HI': 'परीक्षा',
      'VI': 'Kỳ thi',
      'ES': 'Examen',
      'TH': 'ข้อสอบ'
    },
    'catPersonal': {
      'KO': '개인',
      'EN': 'Personal',
      'JA': '個人',
      'ZH': '个人',
      'FR': 'Personnel',
      'DE': 'Persönlich',
      'RU': 'Личное',
      'AR': 'شخصي',
      'HI': 'व्यक्तिगत',
      'VI': 'Cá nhân',
      'ES': 'Personal',
      'TH': 'ส่วนตัว'
    },
    'hintScheduleTitle': {
      'KO': '간단한 일정 제목을 입력하세요',
      'EN': 'Enter a brief schedule title',
      'JA': '簡単な日程タイトルを入力してください',
      'ZH': '请输入简短的日程标题',
      'FR': 'Saisissez un titre de programme',
      'DE': 'Kurzen Termintitel eingeben',
      'RU': 'Введите краткое название',
      'AR': 'أدخل عنوانًا موجزًا للجدول',
      'HI': 'संक्षिप्त कार्यक्रम शीर्षक दर्ज करें',
      'VI': 'Nhập tiêu đề lịch ngắn gọn',
      'ES': 'Ingrese un título breve del horario',
      'TH': 'กรอกชื่อตารางแบบสั้น'
    },
    'selectWeekdayHint': {
      'KO': '울릴 요일을 선택하세요',
      'EN': 'Select days to ring',
      'JA': '鳴らす曜日を選択',
      'ZH': '选择响铃的星期',
      'FR': 'Choisissez les jours',
      'DE': 'Wochentage wählen',
      'RU': 'Выберите дни',
      'AR': 'اختر الأيام',
      'HI': 'दिन चुनें',
      'VI': 'Chọn các ngày',
      'ES': 'Seleccione los días',
      'TH': 'เลือกวันที่จะปลุก'
    },
  };

  static String _t(String key) {
    final map = _uiText[key];
    if (map == null) return key;
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? key;
  }

  static String _biStr(String key) {
    final map = _uiText[key];
    if (map == null) return key;
    if (_isForeignSelected) {
      return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? key;
    }
    return '${map['EN'] ?? ''} / ${map['KO'] ?? ''}';
  }

  static Widget _biTitle(
      String key, {
        required TextStyle enStyle,
        required TextStyle koStyle,
        TextStyle? foreignStyle,
      }) {
    final map = _uiText[key] ?? {'EN': key, 'KO': key};
    if (_isForeignSelected) {
      return Text(
        map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? key,
        style: foreignStyle ?? koStyle,
        overflow: TextOverflow.fade,
        softWrap: false,
        maxLines: 1,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(map['EN'] ?? '',
            style: enStyle, overflow: TextOverflow.fade, softWrap: false, maxLines: 1),
        Text(map['KO'] ?? '',
            style: koStyle, overflow: TextOverflow.fade, softWrap: false, maxLines: 1),
      ],
    );
  }

  static const Map<String, List<String>> _weekdaySunFirst = {
    'KO': ['일', '월', '화', '수', '목', '금', '토'],
    'EN': ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    'JA': ['日', '月', '火', '水', '木', '金', '土'],
    'ZH': ['日', '一', '二', '三', '四', '五', '六'],
    'FR': ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'],
    'DE': ['So', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa'],
    'RU': ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'],
    'AR': ['أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'],
    'HI': ['रवि', 'सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि'],
    'VI': ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'],
    'ES': ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'],
    'TH': ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'],
  };
  static List<String> _weekdaysSunFirst() =>
      _weekdaySunFirst[DkeLang.current] ?? _weekdaySunFirst['EN']!;

  static const List<String> _weekdayFullEn = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  static const List<String> _weekdayFullKo = [
    '월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'
  ];

  @override
  void initState() {
    super.initState();
    PlannerAlarmService.initialize();
    // 🆕 [2026-08-17] 예약 자동발동이 실기기에서 실패하는 문제의 우회로 - 직접 감시 시작
    PlannerAlarmWatcherService.instance.start();
    // 🆕 [버그 수정 2026-08-17] "팝업이 즉시 안 뜨고 나갔다 들어와야 뜸" 문제 수정.
    // 1초 폴링(Timer.periodic) 대신, 알람이 실제로 울리기/꺼지기 시작하는 바로 그 순간 값이
    // 바뀌는 ValueNotifier를 구독함 - 폴링 간격에 따른 지연이 없어서 즉시 반응함.
    PlannerAlarmService.ringingNotifier.addListener(_onAlarmRingingChanged);
    // 화면이 처음 만들어질 때 이미 알람이 울리고 있는 상태였다면(예: 다른 탭에 있다가 왔는데
    // 이미 울리는 중이었던 경우) 첫 프레임이 그려진 직후 바로 팝업을 띄움.
    if (PlannerAlarmService.ringingNotifier.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showRingingAlarmDialog();
      });
    }
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _loadSchedules();
  }

  // 🆕 [버그 수정 2026-08-17] ValueNotifier 값이 바뀌는 즉시 호출되는 콜백
  void _onAlarmRingingChanged() {
    if (PlannerAlarmService.ringingNotifier.value && !_alarmDialogShowing && mounted) {
      _showRingingAlarmDialog();
    }
  }

  @override
  void dispose() {
    PlannerAlarmService.ringingNotifier.removeListener(_onAlarmRingingChanged);
    super.dispose();
  }

  // 🆕 [2026-08-17] 알람이 울리는 순간 자동으로 뜨는 끄기 팝업. barrierDismissible: false와
  // PopScope(canPop: false)로 감싸서 "알람 끄기" 버튼 외에는 절대 못 닫히게 함(뒤로가기/바깥
  // 탭으로 실수로 안 끄고 넘어가는 것 방지).
  void _showRingingAlarmDialog() {
    if (_alarmDialogShowing) return;
    _alarmDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: const Color(0xFF020617),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: examColor, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.notifications_active, color: examColor, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '알람이 울리고 있습니다',
                    overflow: TextOverflow.fade, softWrap: false, maxLines: 1,
                    style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              '설정하신 학습 알람 시간이 되었습니다.',
              style: GoogleFonts.notoSansKr(color: slate400, fontSize: 13),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await PlannerAlarmService.stopAlarmSound();
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  },
                  icon: const Icon(Icons.notifications_off_rounded, size: 22),
                  label: Text('알람 끄기', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: examColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      _alarmDialogShowing = false;
    });
  }

  Future<void> refreshSchedules() async {
    await _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString('gke_global_schedules');
      List<Map<String, dynamic>> list = [];
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        list = decoded.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          if (map['color'] is int) {
            map['color'] = Color(map['color'] as int);
          }
          return map;
        }).toList();
      }
      if (mounted) {
        setState(() {
          _globalSchedules = list;
          _loaded = true;
        });
      }
    } catch (e) {
      debugPrint('[LearningScreen] load failed: $e');
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _saveSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> serializable =
      _globalSchedules.map((item) {
        final Map<String, dynamic> copy = Map<String, dynamic>.from(item);
        if (copy['color'] is Color) {
          copy['color'] = (copy['color'] as Color).toARGB32();
        }
        return copy;
      }).toList();
      await prefs.setString('gke_global_schedules', jsonEncode(serializable));
    } catch (e) {
      debugPrint('[LearningScreen] save failed: $e');
    }
  }

  String _genScheduleId() =>
      'sch_${DateTime.now().microsecondsSinceEpoch}_${_globalSchedules.length}';

  Color _categoryColorFor(String? catValue) {
    switch (catValue) {
      case '학원':
        return academyColor;
      case '시험':
        return examColor;
      case '개인':
        return personalColor;
      default:
        return schoolColor;
    }
  }

  DateTime _itemDateTime(Map<String, dynamic> item) {
    final String timeStr = (item['time'] ?? '00:00').toString();
    final List<String> parts = timeStr.split(':');
    int hh = 0, mm = 0;
    try {
      hh = int.parse(parts[0]);
      mm = parts.length > 1 ? int.parse(parts[1]) : 0;
    } catch (_) {}
    return DateTime(
      item['year'] as int,
      item['month'] as int,
      item['day'] as int,
      hh,
      mm,
    );
  }

  // 🆕 [2026-08-17] 원장님 지시: 반복(매일/요일선택) 알람은 절대 목록에서 사라지면 안 됨(실제로
  // 계속 울리고 있으므로). "한 번만"(once) 알람만 실제로 끝난 뒤 24시간 지나면 숨김. 반복 알람은
  // 원래 등록한 날짜가 아니라 "다음에 울릴 시각"을 계산해서 그 기준으로 정렬/표시함.
  DateTime _effectiveDateTime(Map<String, dynamic> item) {
    final bool alarmOn = item['alarmOn'] == true;
    final String repeat = (item['alarmRepeat'] ?? 'once').toString();
    if (!alarmOn || repeat == 'once') {
      return _itemDateTime(item);
    }

    final String timeStr = (item['time'] ?? '00:00').toString();
    final List<String> parts = timeStr.split(':');
    int hh = 0, mm = 0;
    try {
      hh = int.parse(parts[0]);
      mm = parts.length > 1 ? int.parse(parts[1]) : 0;
    } catch (_) {}
    final DateTime now = DateTime.now();

    if (repeat == 'daily') {
      DateTime candidate = DateTime(now.year, now.month, now.day, hh, mm);
      if (!candidate.isAfter(now)) candidate = candidate.add(const Duration(days: 1));
      return candidate;
    }

    if (repeat == 'weekly') {
      final List<int> weekdays = item['alarmWeekdays'] is List
          ? List<int>.from((item['alarmWeekdays'] as List).map((e) => e is int ? e : int.tryParse('$e') ?? -1))
          : <int>[];
      if (weekdays.isEmpty) return _itemDateTime(item);
      for (int dayOffset = 0; dayOffset < 8; dayOffset++) {
        final DateTime candidate = DateTime(now.year, now.month, now.day, hh, mm).add(Duration(days: dayOffset));
        final int weekdayIdx = candidate.weekday % 7; // 0=일 … 6=토
        if (weekdays.contains(weekdayIdx) && candidate.isAfter(now)) {
          return candidate;
        }
      }
    }
    return _itemDateTime(item);
  }

  bool _isRepeatingAlarm(Map<String, dynamic> item) {
    final bool alarmOn = item['alarmOn'] == true;
    final String repeat = (item['alarmRepeat'] ?? 'once').toString();
    return alarmOn && (repeat == 'daily' || repeat == 'weekly');
  }

  /// 다가오는 일정 목록:
  /// - 반복(매일/요일선택) 알람: 절대 사라지지 않음, "다음 발생 시각" 기준으로 정렬
  /// - 한 번만(once) 일정: 미래는 가까운 순 위로, 과거 24시간 이내는 흐릿하게 아래, 24시간 초과는 숨김
  List<Map<String, dynamic>> get _sortedByProximity {
    final DateTime now = DateTime.now();
    final List<Map<String, dynamic>> list = [];

    for (final item in _globalSchedules) {
      if (_isRepeatingAlarm(item)) {
        list.add(item); // 반복 알람은 무조건 유지
        continue;
      }
      final DateTime dt = _itemDateTime(item);
      final Duration age = now.difference(dt); // 양수 = 이미 지남
      if (age > const Duration(hours: 24)) continue; // 24시간 지난 과거(once만)는 숨김
      list.add(item);
    }

    list.sort((a, b) {
      final DateTime da = _effectiveDateTime(a);
      final DateTime db = _effectiveDateTime(b);
      final bool aPast = da.isBefore(now);
      final bool bPast = db.isBefore(now);

      // 미래 일정이 위, 과거(24h 이내)는 아래
      if (aPast != bPast) return aPast ? 1 : -1;

      if (!aPast && !bPast) {
        // 미래: 가까운 시간이 위 (오름차순)
        return da.compareTo(db);
      }
      // 과거: 더 최근에 지난 것이 위 (내림차순 → 지금과 가까운 과거가 위)
      return db.compareTo(da);
    });
    return list;
  }

  /// 이미 지났지만 24시간 이내인지 (흐릿 표시용) - 반복 알람은 절대 흐리게 표시 안 함
  bool _isPastWithin24h(Map<String, dynamic> item) {
    if (_isRepeatingAlarm(item)) return false;
    final DateTime dt = _itemDateTime(item);
    final Duration age = DateTime.now().difference(dt);
    return age > Duration.zero && age <= const Duration(hours: 24);
  }

  void _goToPreviousMonth() {
    setState(() =>
    _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1));
  }

  void _goToNextMonth() {
    setState(() =>
    _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1));
  }

  int get _firstDayWeekdayIndex =>
      DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday;
  int get _emptyPrefixCellsCount =>
      _firstDayWeekdayIndex == 7 ? 0 : _firstDayWeekdayIndex;
  int get _totalDaysInMonth =>
      DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
  int get _prevMonthTotalDays =>
      DateTime(_displayedMonth.year, _displayedMonth.month, 0).day;
  int get _totalCalendarGridItemsCount {
    int count = _emptyPrefixCellsCount + _totalDaysInMonth;
    if (count % 7 != 0) count += (7 - (count % 7));
    return count;
  }

  String _repeatBadge(Map<String, dynamic> item) {
    final r = (item['alarmRepeat'] ?? 'once').toString();
    if (r == 'daily') return _t('repeatDaily');
    if (r == 'weekly') return _t('repeatWeekly');
    return _t('repeatOnce');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_loaded) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    }
    final List<Map<String, dynamic>> sortedList = _sortedByProximity;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const PlannerRingingAlarmStopBanner(), // 🆕 [2026-08-17] 지금 울리는 알람 확실하게 끄는 버튼, 울릴 때만 보임
          _biTitle(
            'sectionExecution',
            enStyle: GoogleFonts.gowunBatang(
                fontSize: 13, color: goldColor, fontWeight: FontWeight.bold),
            koStyle: GoogleFonts.notoSansKr(
                fontSize: 16, color: goldColor, fontWeight: FontWeight.bold),
            foreignStyle: GoogleFonts.notoSans(
                fontSize: 15, color: goldColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildCalendarCard(),
          if (_expandedAlarmDate != null)
            _buildExpandedDatePanel(_expandedAlarmDate!),
          const SizedBox(height: 20),
          _biTitle(
            'upcomingList',
            enStyle: GoogleFonts.gowunBatang(
                fontSize: 12, color: goldColor, fontWeight: FontWeight.bold),
            koStyle: GoogleFonts.notoSansKr(
                fontSize: 15, color: goldColor, fontWeight: FontWeight.bold),
            foreignStyle: GoogleFonts.notoSans(
                fontSize: 14, color: goldColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (sortedList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                  child: Text(_t('emptySchedule'),
                      style: GoogleFonts.notoSansKr(
                          color: slate500, fontSize: 12))),
            )
          else
            ...sortedList.map((item) {
              final DateTime dt = _itemDateTime(item);
              // 🆕 [2026-08-17] 반복 알람은 목록에 "다음 발생 날짜/시간"이 보이도록 함
              final DateTime displayDt = _effectiveDateTime(item);
              final Color catColor = item['color'] is Color
                  ? item['color'] as Color
                  : _categoryColorFor(item['category'] as String?);
              final bool alarmOn = item['alarmOn'] == true;
              final int gIdx = _globalSchedules.indexOf(item);
              final bool isPastDim = _isPastWithin24h(item);
              return Opacity(
                opacity: isPastDim ? 0.42 : 1.0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showAlarmEditPopup(
                      DateTime(dt.year, dt.month, dt.day),
                      globalIdx: gIdx),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xFF020617),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isPastDim
                                ? slate800.withValues(alpha: 0.6)
                                : slate800)),
                    child: Row(
                      children: [
                        Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                                color: catColor,
                                borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 76,
                          child: Text(
                            '${displayDt.month.toString().padLeft(2, '0')}/${displayDt.day.toString().padLeft(2, '0')} ${item['time'] ?? ''}',
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            maxLines: 1,
                            style: GoogleFonts.notoSerif(
                                fontSize: 11,
                                color: goldColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['title'] ?? '',
                                  style: GoogleFonts.notoSansKr(
                                      fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis),
                              if (alarmOn)
                                Text(_repeatBadge(item),
                                    style: GoogleFonts.notoSansKr(
                                        fontSize: 10, color: slate400)),
                            ],
                          ),
                        ),
                        if (alarmOn)
                          Icon(Icons.notifications_active,
                              color: goldColor, size: 16),
                        const SizedBox(width: 4),
                        const ThreeColorPencilIcon(size: 14),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildExpandedDatePanel(DateTime date) {
    final List<int> dateIdxs = [];
    for (int i = 0; i < _globalSchedules.length; i++) {
      final s = _globalSchedules[i];
      if (s['year'] == date.year &&
          s['month'] == date.month &&
          s['day'] == date.day) {
        dateIdxs.add(i);
      }
    }
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFF020617),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: goldColor.withValues(alpha: 0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} '
                      '${_weekdayFullEn[date.weekday - 1]}/${_weekdayFullKo[date.weekday - 1]}',
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  maxLines: 1,
                  style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      color: goldColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showAlarmEditPopup(date, globalIdx: null),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: goldColor, width: 1.5)),
                  child: Icon(Icons.add, color: goldColor, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (dateIdxs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(_t('noAlarmToday'),
                  style:
                  GoogleFonts.notoSansKr(color: slate500, fontSize: 12)),
            )
          else
            ...dateIdxs.map((gIdx) {
              final item = _globalSchedules[gIdx];
              final Color catColor = item['color'] is Color
                  ? item['color'] as Color
                  : _categoryColorFor(item['category'] as String?);
              final bool alarmOnFlag = item['alarmOn'] == true;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showAlarmEditPopup(date, globalIdx: gIdx),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: slate800)),
                  child: Row(
                    children: [
                      Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                              color: catColor,
                              borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 8),
                      SizedBox(
                          width: 56,
                          child: Text(item['time'] ?? '',
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              maxLines: 1,
                              style: GoogleFonts.notoSerif(
                                  fontSize: 11,
                                  color: goldColor,
                                  fontWeight: FontWeight.bold))),
                      Expanded(
                          child: Text(item['title'] ?? '',
                              style: GoogleFonts.notoSansKr(
                                  fontSize: 12, color: Colors.white),
                              overflow: TextOverflow.ellipsis)),
                      if (alarmOnFlag)
                        Icon(Icons.notifications_active,
                            color: goldColor, size: 14),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFF020617),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: slate800)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                  onTap: _goToPreviousMonth,
                  child: Icon(Icons.chevron_left, color: goldColor, size: 22)),
              Text('${_displayedMonth.year} / ${_displayedMonth.month}',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 14,
                      color: goldColor,
                      fontWeight: FontWeight.bold)),
              GestureDetector(
                  onTap: _goToNextMonth,
                  child: Icon(Icons.chevron_right, color: goldColor, size: 22)),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 7,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, childAspectRatio: 1.6),
            itemBuilder: (context, index) {
              final Color c =
              index == 0 ? examColor : (index == 6 ? schoolColor : slate400);
              return Center(
                  child: Text(_weekdaysSunFirst()[index],
                      style: GoogleFonts.notoSansKr(
                          fontSize: 11, color: c, fontWeight: FontWeight.bold)));
            },
          ),
          const Divider(color: Color(0xFF1E293B), height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _totalCalendarGridItemsCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 0.85),
            itemBuilder: (context, index) {
              int displayDayNum = 1;
              bool isBlurred = false;
              if (index < _emptyPrefixCellsCount) {
                displayDayNum =
                    _prevMonthTotalDays - (_emptyPrefixCellsCount - index - 1);
                isBlurred = true;
              } else if (index >= (_emptyPrefixCellsCount + _totalDaysInMonth)) {
                displayDayNum =
                    index - (_emptyPrefixCellsCount + _totalDaysInMonth) + 1;
                isBlurred = true;
              } else {
                displayDayNum = index - _emptyPrefixCellsCount + 1;
              }

              List<Color> dayColors = [];
              if (!isBlurred) {
                final daySchedules = _globalSchedules.where((s) =>
                s['year'] == _displayedMonth.year &&
                    s['month'] == _displayedMonth.month &&
                    s['day'] == displayDayNum);
                final Set<int> seen = {};
                for (final s in daySchedules) {
                  final Color c = s['color'] is Color
                      ? s['color'] as Color
                      : _categoryColorFor(s['category'] as String?);
                  if (seen.add(c.toARGB32()) && dayColors.length < 4) {
                    dayColors.add(c);
                  }
                }
              }

              final bool isToday = !isBlurred &&
                  _displayedMonth.year == DateTime.now().year &&
                  _displayedMonth.month == DateTime.now().month &&
                  displayDayNum == DateTime.now().day;
              final bool isSelected = !isBlurred &&
                  _selectedDate.year == _displayedMonth.year &&
                  _selectedDate.month == _displayedMonth.month &&
                  _selectedDate.day == displayDayNum;

              return GestureDetector(
                onTap: () {
                  if (isBlurred) return;
                  final DateTime tapped = DateTime(
                      _displayedMonth.year, _displayedMonth.month, displayDayNum);
                  setState(() {
                    _selectedDate = tapped;
                    _expandedAlarmDate = (_expandedAlarmDate != null &&
                        _expandedAlarmDate!.year == tapped.year &&
                        _expandedAlarmDate!.month == tapped.month &&
                        _expandedAlarmDate!.day == tapped.day)
                        ? null
                        : tapped;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? goldColor.withValues(alpha: 0.15)
                        : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: isSelected
                            ? goldColor
                            : (isToday
                            ? goldColor.withValues(alpha: 0.5)
                            : slate800),
                        width: isSelected ? 1.5 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$displayDayNum',
                          style: GoogleFonts.notoSerif(
                              fontSize: 12,
                              color: isBlurred
                                  ? slate500
                                  : (isSelected ? goldColor : Colors.white),
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      if (dayColors.isNotEmpty)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 2,
                          children: dayColors
                              .map((c) => Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: c,
                                  borderRadius: BorderRadius.circular(1.5))))
                              .toList(),
                        )
                      else
                        const SizedBox(height: 6),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── 알람 편집 팝업 (한 번만 / 매일 / 요일 선택) ─────────────────
  void _showAlarmEditPopup(DateTime date, {int? globalIdx}) {
    final Map<String, dynamic>? item =
    globalIdx != null ? _globalSchedules[globalIdx] : null;

    final TextEditingController timeController =
    TextEditingController(text: item?['time'] as String? ?? '09:00');
    final TextEditingController titleController =
    TextEditingController(text: item?['title'] as String? ?? '');

    String selectedCategory = item?['category'] as String? ?? '학교';
    bool alarmOn = item?['alarmOn'] == true;
    String repeat = (item?['alarmRepeat'] as String?) ?? 'once';
    // weekdays: 0=일 … 6=토
    List<int> selectedWeekdays = [];
    if (item?['alarmWeekdays'] is List) {
      selectedWeekdays = List<int>.from(
          (item!['alarmWeekdays'] as List).map((e) => e is int ? e : int.tryParse('$e') ?? 0));
    }
    // 새 항목이고 요일이 비어 있으면 탭한 날짜의 요일을 기본 선택
    if (selectedWeekdays.isEmpty && globalIdx == null) {
      selectedWeekdays = [date.weekday % 7]; // DateTime.weekday 일=7 → 0
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext sbContext, StateSetter setPopState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF020617),
              shape: RoundedRectangleBorder(
                  side: BorderSide(color: goldColor, width: 1.5),
                  borderRadius: BorderRadius.circular(12)),
              title: Text(
                _t('alarmSettingTitle'),
                overflow: TextOverflow.fade,
                softWrap: false,
                maxLines: 1,
                style: GoogleFonts.notoSansKr(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 카테고리
                    Text(_biStr('labelCategorySelect'),
                        style: GoogleFonts.notoSerif(
                            fontSize: 11,
                            color: goldColor,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        {'value': '학교', 'labelKey': 'catSchool'},
                        {'value': '학원', 'labelKey': 'catAcademy'},
                        {'value': '시험', 'labelKey': 'catExam'},
                        {'value': '개인', 'labelKey': 'catPersonal'},
                      ].map((cat) {
                        final bool isSel = selectedCategory == cat['value'];
                        return GestureDetector(
                          onTap: () => setPopState(
                                  () => selectedCategory = cat['value']!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? _categoryColorFor(cat['value'])
                                  : const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: isSel
                                      ? _categoryColorFor(cat['value'])
                                      : slate800),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                    width: 10,
                                    height: 10,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                        color: _categoryColorFor(cat['value']),
                                        borderRadius: BorderRadius.circular(2))),
                                Text(_biStr(cat['labelKey']!),
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    maxLines: 1,
                                    style: GoogleFonts.notoSansKr(
                                        fontSize: 11,
                                        color: isSel
                                            ? const Color(0xFF020617)
                                            : Colors.white)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // 제목
                    Text(_biStr('labelTitleField'),
                        style: GoogleFonts.notoSerif(
                            fontSize: 11,
                            color: goldColor,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: titleController,
                      style: GoogleFonts.notoSansKr(
                          color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: _biStr('hintScheduleTitle'),
                        hintStyle: GoogleFonts.notoSansKr(
                            color: slate500, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: slate800)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: goldColor)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 시간
                    Text(_biStr('labelTime'),
                        style: GoogleFonts.notoSerif(
                            fontSize: 11,
                            color: goldColor,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: timeController,
                      style: GoogleFonts.notoSansKr(
                          color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: '09:00',
                        hintStyle: GoogleFonts.notoSansKr(
                            color: slate500, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: slate800)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: goldColor)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 반복 옵션
                    Text(_biStr('labelRepeat'),
                        style: GoogleFonts.notoSerif(
                            fontSize: 11,
                            color: goldColor,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _repeatChipRow(
                      selected: repeat,
                      onSelect: (v) => setPopState(() => repeat = v),
                    ),
                    if (repeat == 'weekly') ...[
                      const SizedBox(height: 10),
                      Text(_t('selectWeekdayHint'),
                          style: GoogleFonts.notoSansKr(
                              fontSize: 11, color: slate400)),
                      const SizedBox(height: 6),
                      _weekdaySelector(
                        selected: selectedWeekdays,
                        onToggle: (w) {
                          setPopState(() {
                            if (selectedWeekdays.contains(w)) {
                              selectedWeekdays =
                              List<int>.from(selectedWeekdays)..remove(w);
                            } else {
                              selectedWeekdays =
                              List<int>.from(selectedWeekdays)..add(w);
                              selectedWeekdays.sort();
                            }
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 14),

                    // 알람 ON/OFF
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: slate800)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.notifications_active_outlined,
                                  color: goldColor, size: 18),
                              const SizedBox(width: 8),
                              Text(_biStr('alarmOnLabel'),
                                  style: GoogleFonts.notoSansKr(
                                      fontSize: 13, color: Colors.white)),
                            ],
                          ),
                          Switch(
                            value: alarmOn,
                            activeColor: goldColor,
                            onChanged: (v) => setPopState(() => alarmOn = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (globalIdx != null)
                      Flexible(
                        child: TextButton(
                          onPressed: () async {
                            final String? scheduleId =
                            _globalSchedules[globalIdx]['id'] as String?;
                            setState(() => _globalSchedules.removeAt(globalIdx));
                            await _saveSchedules();
                            if (scheduleId != null) {
                              await PlannerAlarmService.cancelAllFor(scheduleId);
                            }
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          },
                          child: Text(_biStr('btnDelete'),
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              maxLines: 1,
                              style: GoogleFonts.notoSansKr(
                                  color: examColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(_biStr('btnClose'),
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              maxLines: 1,
                              style: GoogleFonts.notoSansKr(
                                  color: slate400,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: goldColor),
                          onPressed: () async {
                            final String time = timeController.text.trim();
                            final String title = titleController.text.trim();
                            if (time.isEmpty || title.isEmpty) return;
                            if (repeat == 'weekly' && selectedWeekdays.isEmpty) {
                              return; // 요일 미선택 시 저장 차단
                            }

                            final String scheduleId = (globalIdx == null)
                                ? _genScheduleId()
                                : ((_globalSchedules[globalIdx]['id']
                            as String?) ??
                                _genScheduleId());

                            setState(() {
                              if (globalIdx == null) {
                                _globalSchedules.add({
                                  'id': scheduleId,
                                  'year': date.year,
                                  'month': date.month,
                                  'day': date.day,
                                  'time': time,
                                  'title': title,
                                  'category': selectedCategory,
                                  'color': _categoryColorFor(selectedCategory),
                                  'memo': '',
                                  'alarmOn': alarmOn,
                                  'alarmRepeat': repeat,
                                  'alarmWeekdays':
                                  List<int>.from(selectedWeekdays),
                                });
                              } else {
                                _globalSchedules[globalIdx]['id'] = scheduleId;
                                _globalSchedules[globalIdx]['time'] = time;
                                _globalSchedules[globalIdx]['title'] = title;
                                _globalSchedules[globalIdx]['category'] =
                                    selectedCategory;
                                _globalSchedules[globalIdx]['color'] =
                                    _categoryColorFor(selectedCategory);
                                _globalSchedules[globalIdx]['alarmOn'] =
                                    alarmOn;
                                _globalSchedules[globalIdx]['alarmRepeat'] =
                                    repeat;
                                _globalSchedules[globalIdx]['alarmWeekdays'] =
                                List<int>.from(selectedWeekdays);
                              }
                            });

                            // UI 먼저 닫기 → 체감 반응 즉시
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }

                            await _saveSchedules();

                            if (alarmOn) {
                              // 🆕 [버그 수정 2026-08-18] 원장님 지시: 앱 켤 때가 아니라, 학생이
                              // "알람 켜기"를 켜고 저장하는 바로 이 순간에만 알림/배터리 권한
                              // 팝업이 뜨도록 함. 이미 허용된 상태라면 조용히 넘어가고 다시
                              // 안 물어봄(내부에서 상태 확인 후 필요할 때만 요청함).
                              await initAndStartPlannerAlarmForegroundService();
                              await PlannerAlarmService.schedule(
                                scheduleId: scheduleId,
                                date: date,
                                timeHHmm: time,
                                title: title,
                                body:
                                '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} · ${_t('alarmSettingTitle')}',
                                repeat: repeat,
                                weekdays: selectedWeekdays,
                              );
                            } else {
                              await PlannerAlarmService.cancelAllFor(scheduleId);
                            }
                          },
                          child: Text(_biStr('btnSave'),
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              maxLines: 1,
                              style: GoogleFonts.notoSansKr(
                                  fontSize: 12,
                                  color: const Color(0xFF020617),
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _repeatChipRow({
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    final options = [
      {'value': 'once', 'key': 'repeatOnce'},
      {'value': 'daily', 'key': 'repeatDaily'},
      {'value': 'weekly', 'key': 'repeatWeekly'},
    ];
    return Row(
      children: options.map((o) {
        final bool isSel = selected == o['value'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => onSelect(o['value']!),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSel
                      ? goldColor.withValues(alpha: 0.18)
                      : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isSel ? goldColor : slate800, width: isSel ? 1.5 : 1),
                ),
                child: Center(
                  child: Text(
                    _t(o['key']!),
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    maxLines: 1,
                    style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        color: isSel ? goldColor : slate400,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _weekdaySelector({
    required List<int> selected,
    required ValueChanged<int> onToggle,
  }) {
    final labels = _weekdaysSunFirst();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final bool on = selected.contains(i);
        final Color accent = i == 0
            ? examColor
            : (i == 6 ? schoolColor : goldColor);
        return GestureDetector(
          onTap: () => onToggle(i),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? accent.withValues(alpha: 0.2) : const Color(0xFF0F172A),
              border: Border.all(color: on ? accent : slate800, width: on ? 1.5 : 1),
            ),
            child: Center(
              child: Text(
                labels[i],
                style: GoogleFonts.notoSansKr(
                    fontSize: 11,
                    color: on ? accent : slate400,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }),
    );
  }
}
