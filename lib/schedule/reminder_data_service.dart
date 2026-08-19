// ============================================================================
// 🆕 [일반 플래너 - 알림] ReminderDataService
// 알림(제목/날짜/시간/반복/켜짐여부/메모)을 저장/불러오는 서비스입니다.
//
// 🆕 [실제 알림 연동 완료] 이제 add/update/delete 시 notification_service.dart를
// 통해 실제 푸시 알림이 예약/취소됩니다. 기존 타이머 알림(Timer2Service)과는
// 완전히 별도의 독립된 알림 채널을 사용하므로 서로 영향을 주지 않습니다.
//
// ✅ [2026-08-16 추가] "매주" 반복 시 여러 요일(예: 화요일+금요일)을 선택할
// 수 있도록 weekdays 필드를 추가했습니다. Dart의 DateTime.weekday 값
// (월=1, 화=2, 수=3, 목=4, 금=5, 토=6, 일=7)을 콤마로 이어붙인 문자열로
// 저장합니다(예: "2,5"). 예전에 저장된 데이터(이 필드가 없음)와의 호환을
// 위해, 비어있으면 저장된 date의 요일 하나만 쓰는 것으로 자동 처리됩니다
// (reminder_watcher_service.dart에서 처리).
// ============================================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart'; // 🆕 [실제 알림 연동]

class ReminderItem {
  final String id;
  final String title;
  final String date; // 'yyyy-MM-dd'
  final String time; // 'HH:mm'
  final String repeatType; // '한번' | '매일' | '매주'
  bool isEnabled;
  final String memo;
  String createdAt; // 🆕 [정렬 수정] 최근 입력이 목록 맨 위로 오도록 하는 기준 시각
  final String weekdays; // 🆕 [2026-08-16 추가] '매주' 반복 시 선택한 요일들. DateTime.weekday(월=1~일=7) 값을 콤마로 이어붙임 (예: "2,5" = 화,금). 비어있으면 date의 요일 하나만 사용(예전 데이터 호환).

  ReminderItem({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    this.repeatType = '한번',
    this.isEnabled = true,
    this.memo = '',
    String? createdAt,
    this.weekdays = '',
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date,
    'time': time,
    'repeatType': repeatType,
    'isEnabled': isEnabled,
    'memo': memo,
    'createdAt': createdAt,
    'weekdays': weekdays,
  };

  factory ReminderItem.fromJson(Map<String, dynamic> json) => ReminderItem(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    date: json['date'] as String? ?? '',
    time: json['time'] as String? ?? '',
    repeatType: json['repeatType'] as String? ?? '한번',
    isEnabled: json['isEnabled'] as bool? ?? true,
    memo: json['memo'] as String? ?? '',
    createdAt: json['createdAt'] as String?,
    weekdays: json['weekdays'] as String? ?? '', // 🆕 예전 데이터는 이 필드가 없어서 빈 문자열로 자동 대체됨
  );
}

class ReminderDataService {
  static const String _kKey = 'gke_general_planner_reminders_v1';

  static Future<List<ReminderItem>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      final list = decoded.map((e) => ReminderItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      // 🆕 [정렬 재변경] "최근 입력순"이 아니라 "지금 시각에 가장 가까운 순"으로 변경.
      // 아직 안 지난 알림 중 가장 빨리 울릴 것이 맨 위, 이미 지난 알림은 아래로 내려감.
      final now = DateTime.now();
      final String todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final String nowHHmm = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      bool isPast(ReminderItem item) {
        // 반복 알림(매일/매주)은 항상 다시 돌아오므로 '지난 것'으로 취급하지 않음
        if (item.repeatType == '매일' || item.repeatType == '매주') return false;
        if (item.date.compareTo(todayKey) < 0) return true;
        if (item.date.compareTo(todayKey) > 0) return false;
        if (item.time.isEmpty) return false;
        return item.time.compareTo(nowHHmm) < 0;
      }

      list.sort((a, b) {
        final bool aPast = isPast(a);
        final bool bPast = isPast(b);
        if (aPast != bPast) return aPast ? 1 : -1; // 지난 것은 아래로
        if (!aPast) {
          // 아직 안 지난 것들끼리는 날짜+시간이 가까운(빠른) 순
          final cmp = a.date.compareTo(b.date);
          if (cmp != 0) return cmp;
          return a.time.compareTo(b.time);
        } else {
          // 지난 것들끼리는 가장 최근에 지난 것이 위로
          final cmp = b.date.compareTo(a.date);
          if (cmp != 0) return cmp;
          return b.time.compareTo(a.time);
        }
      });
      return list;
    } catch (e) {
      return [];
    }
  }

  static Future<void> add(ReminderItem item) async {
    final all = await loadAll();
    all.add(item);
    await _saveAll(all);
    if (item.isEnabled) {
      await NotificationService.scheduleAt(
        id: item.id,
        title: item.title,
        body: item.memo.isNotEmpty ? item.memo : 'GKE StudyUp 알림',
        date: item.date,
        time: item.time,
        repeatType: item.repeatType,
      );
    }
  }

  static Future<void> update(ReminderItem updated) async {
    final all = await loadAll();
    final idx = all.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      all[idx] = updated;
      await _saveAll(all);
    }
    // 🆕 [실제 알림 연동] 켜짐 상태면 다시 예약, 꺼짐 상태면 취소
    if (updated.isEnabled) {
      await NotificationService.scheduleAt(
        id: updated.id,
        title: updated.title,
        body: updated.memo.isNotEmpty ? updated.memo : 'GKE StudyUp 알림',
        date: updated.date,
        time: updated.time,
        repeatType: updated.repeatType,
      );
    } else {
      await NotificationService.cancel(updated.id);
    }
  }

  static Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((e) => e.id == id);
    await _saveAll(all);
    await NotificationService.cancel(id); // 🆕 [실제 알림 연동] 삭제 시 예약된 알림도 취소
  }

  static Future<void> _saveAll(List<ReminderItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kKey, jsonEncode(items.map((e) => e.toJson()).toList()));
    } catch (e) {}
  }
}
