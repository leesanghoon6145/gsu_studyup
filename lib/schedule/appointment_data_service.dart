// ============================================================================
// 🆕 [일반 플래너 - 약속] AppointmentDataService
// "약속" 항목(누구와 만나는지, 언제, 어디서)을 저장/불러오는 서비스입니다.
// ============================================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart'; // 🆕 [실제 알림 연동] 약속 시간에 실제 알림이 울리도록 연결

class AppointmentItem {
  final String id;
  final String title;
  final String withPerson; // 누구와
  final String date; // 'yyyy-MM-dd'
  final String time; // 'HH:mm'
  final String location;
  final String memo;
  bool isCompleted;

  AppointmentItem({
    required this.id,
    required this.title,
    this.withPerson = '',
    required this.date,
    this.time = '',
    this.location = '',
    this.memo = '',
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'withPerson': withPerson,
    'date': date,
    'time': time,
    'location': location,
    'memo': memo,
    'isCompleted': isCompleted,
  };

  factory AppointmentItem.fromJson(Map<String, dynamic> json) => AppointmentItem(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    withPerson: json['withPerson'] as String? ?? '',
    date: json['date'] as String? ?? '',
    time: json['time'] as String? ?? '',
    location: json['location'] as String? ?? '',
    memo: json['memo'] as String? ?? '',
    isCompleted: json['isCompleted'] as bool? ?? false,
  );
}

class AppointmentDataService {
  static const String _kKey = 'gke_general_planner_appointments_v1';

  static Future<List<AppointmentItem>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      final list = decoded.map((e) => AppointmentItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      // 날짜+시간 순으로 정렬 (다가오는 약속이 위로)
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

  static Future<void> add(AppointmentItem item) async {
    final all = await loadAll();
    all.add(item);
    await _saveAll(all);
    // 🆕 [실제 알림 연동] 시간이 설정된 약속이면 그 시각에 실제 알림 예약
    await NotificationService.scheduleAt(
      id: item.id,
      title: '약속: ${item.title}',
      body: item.withPerson.isNotEmpty ? '${item.withPerson}님과의 약속입니다.' : '약속 시간입니다.',
      date: item.date,
      time: item.time,
    );
  }

  static Future<void> update(AppointmentItem updated) async {
    final all = await loadAll();
    final idx = all.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      all[idx] = updated;
      await _saveAll(all);
    }
    // 🆕 [실제 알림 연동] 수정 시 예약을 새 시간으로 다시 걸어줌
    await NotificationService.scheduleAt(
      id: updated.id,
      title: '약속: ${updated.title}',
      body: updated.withPerson.isNotEmpty ? '${updated.withPerson}님과의 약속입니다.' : '약속 시간입니다.',
      date: updated.date,
      time: updated.time,
    );
  }

  static Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((e) => e.id == id);
    await _saveAll(all);
    await NotificationService.cancel(id); // 🆕 [실제 알림 연동] 삭제 시 예약된 알림도 취소
  }

  static Future<void> _saveAll(List<AppointmentItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kKey, jsonEncode(items.map((e) => e.toJson()).toList()));
    } catch (e) {
      // 다음 저장 시도에서 재시도됨
    }
  }
}
