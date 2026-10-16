// ============================================================================
// 🆕 [일반 플래너 - 약속] AppointmentDataService
// "약속" 항목(누구와 만나는지, 언제, 어디서)을 저장/불러오는 서비스입니다.
//
// 🆕 [2026-10-16 새 알람 방식] 약속 알림 시점(alarmOffsets)을 함께 저장합니다.
//   정각(0) · 30분 전(30) · 1시간 전(60) · 1일 전(1440) 중 고른 것 — 여러 개 가능
//   예전에 저장된 약속(이 칸이 없음)은 "정각" 한 번으로 봅니다.
//   저장 · 수정 · 삭제할 때마다 알람 총괄 담당(GkeAlarmEngine)이 약속 알람 전체를 다시 맞춥니다.
// ============================================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gsu_studyup/services/gke_alarm_engine.dart'; // 🆕 [2026-10-16] 알람 총괄 담당
import 'planner_scope.dart'; // 🆕 [계정별 분리 2026-09-30]

class AppointmentItem {
  final String id;
  final String title;
  final String withPerson; // 누구와
  final String date; // 'yyyy-MM-dd'
  final String time; // 'HH:mm'
  final String location;
  final String memo;
  bool isCompleted;
  String createdAt; // 🆕 [정렬 수정] 최근에 입력한 게 맨 위로 오도록 하는 기준 시각
  final List<int> alarmOffsets; // 🆕 [2026-10-16] 약속 알림 시점(분 전): 0 · 30 · 60 · 1440

  AppointmentItem({
    required this.id,
    required this.title,
    this.withPerson = '',
    required this.date,
    this.time = '',
    this.location = '',
    this.memo = '',
    this.isCompleted = false,
    String? createdAt,
    List<int>? alarmOffsets,
  })  : createdAt = createdAt ?? DateTime.now().toIso8601String(),
        alarmOffsets = (alarmOffsets == null || alarmOffsets.isEmpty) ? const <int>[0] : alarmOffsets;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'withPerson': withPerson,
    'date': date,
    'time': time,
    'location': location,
    'memo': memo,
    'isCompleted': isCompleted,
    'createdAt': createdAt,
    'alarmOffsets': alarmOffsets,
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
    createdAt: json['createdAt'] as String?,
    alarmOffsets: (json['alarmOffsets'] is List)
        ? (json['alarmOffsets'] as List).map((e) => e is int ? e : int.tryParse('$e') ?? 0).toList()
        : null, // 🆕 예전 약속은 "정각" 한 번
  );
}

class AppointmentDataService {
  static String get _kKey => plannerScopedKey('gke_general_planner_appointments_v1'); // 🆕 [계정별 분리]

  static Future<List<AppointmentItem>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      final list = decoded.map((e) => AppointmentItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      // 🆕 [정렬 재변경] 지난 날짜/시간이 이미 지난 약속은 아래로 내리고,
      // 아직 안 지난 약속들 사이에서는 최근에 입력한 것이 맨 위로 오도록 정렬.
      final now = DateTime.now();
      final String todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final String nowHHmm = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      bool isPast(AppointmentItem item) {
        if (item.date.compareTo(todayKey) < 0) return true;
        if (item.date.compareTo(todayKey) > 0) return false;
        if (item.time.isEmpty) return false;
        return item.time.compareTo(nowHHmm) < 0;
      }

      list.sort((a, b) {
        final bool aPast = isPast(a);
        final bool bPast = isPast(b);
        if (aPast != bPast) return aPast ? 1 : -1;
        return b.createdAt.compareTo(a.createdAt);
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
    await GkeAlarmEngine.syncGeneral(); // 🆕 [2026-10-16] 약속 알람 다시 맞춤
  }

  static Future<void> update(AppointmentItem updated) async {
    final all = await loadAll();
    final idx = all.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      all[idx] = updated;
      await _saveAll(all);
    }
    await GkeAlarmEngine.syncGeneral(); // 🆕 [2026-10-16] 약속 알람 다시 맞춤 (완료 표시하면 알람도 꺼짐)
  }

  static Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((e) => e.id == id);
    await _saveAll(all);
    await GkeAlarmEngine.syncGeneral(); // 🆕 [2026-10-16] 지운 약속의 알람도 함께 정리
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
