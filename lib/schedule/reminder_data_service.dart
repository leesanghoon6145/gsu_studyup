// ============================================================================
// 🆕 [일반 플래너 - 알림] ReminderDataService
// 알림(제목/날짜/시간/반복/켜짐여부/메모)을 저장/불러오는 서비스입니다.
//
// 🆕 [실제 알림 연동 완료] 이제 add/update/delete 시 notification_service.dart를
// 통해 실제 푸시 알림이 예약/취소됩니다. 기존 타이머 알림(Timer2Service)과는
// 완전히 별도의 독립된 알림 채널을 사용하므로 서로 영향을 주지 않습니다.
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

  ReminderItem({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    this.repeatType = '한번',
    this.isEnabled = true,
    this.memo = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date,
    'time': time,
    'repeatType': repeatType,
    'isEnabled': isEnabled,
    'memo': memo,
  };

  factory ReminderItem.fromJson(Map<String, dynamic> json) => ReminderItem(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    date: json['date'] as String? ?? '',
    time: json['time'] as String? ?? '',
    repeatType: json['repeatType'] as String? ?? '한번',
    isEnabled: json['isEnabled'] as bool? ?? true,
    memo: json['memo'] as String? ?? '',
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
      list.sort((a, b) {
        final cmp = a.date.compareTo(b.date);
        if (cmp != 0) return cmp;
        return a.time.compareTo(b.time);
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
