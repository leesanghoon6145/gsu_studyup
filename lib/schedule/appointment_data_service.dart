// ============================================================================
// 🆕 [일반 플래너 - 약속] AppointmentDataService
// "약속" 항목(누구와 만나는지, 언제, 어디서)을 저장/불러오는 서비스입니다.
// ============================================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  }

  static Future<void> update(AppointmentItem updated) async {
    final all = await loadAll();
    final idx = all.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      all[idx] = updated;
      await _saveAll(all);
    }
  }

  static Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((e) => e.id == id);
    await _saveAll(all);
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
