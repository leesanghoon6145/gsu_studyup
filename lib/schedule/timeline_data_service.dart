// ============================================================================
// 🆕 [일반 플래너 2단계] TimelineDataService
// "타임라인" 섹션(오늘의 타임라인/루틴/실행기록/타임라인기록/분석)에서
// 공통으로 쓰는 데이터 모델과 SharedPreferences 저장/불러오기를 관리합니다.
//
// TimelineBlock: 특정 날짜의 계획된 시간 블록 하나 (계획시간 + 실제시간 + 상태)
// RoutineTemplate: "기상/운동/출근..." 같은 반복 일과 템플릿. 오늘 타임라인에
// 한 번에 적용(복사)할 수 있습니다.
// ============================================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TimelineBlock {
  final String id;
  final String date; // 'yyyy-MM-dd'
  final String plannedStart; // 'HH:mm'
  final String plannedEnd; // 'HH:mm'
  final String title;
  final String category; // 자유 텍스트 (예: 업무/운동/휴식/이동/자기계발)
  final bool isRoutine;
  String? actualStart; // 'HH:mm', 시작 전엔 null
  String? actualEnd; // 'HH:mm', 완료 전엔 null
  String status; // 'planned' | 'running' | 'completed'

  TimelineBlock({
    required this.id,
    required this.date,
    required this.plannedStart,
    required this.plannedEnd,
    required this.title,
    this.category = '일반',
    this.isRoutine = false,
    this.actualStart,
    this.actualEnd,
    this.status = 'planned',
  });

  // 🆕 계획 소요 시간(분)
  int get plannedMinutes => _diffMinutes(plannedStart, plannedEnd);

  // 🆕 실제 소요 시간(분) - 시작/종료가 모두 기록된 경우만 계산, 아니면 null
  int? get actualMinutes {
    if (actualStart == null || actualEnd == null) return null;
    return _diffMinutes(actualStart!, actualEnd!);
  }

  // 🆕 계획 대비 실제 시간 차이(분). 양수면 더 오래 걸림, 음수면 더 빨리 끝냄.
  int? get diffMinutes {
    final actual = actualMinutes;
    if (actual == null) return null;
    return actual - plannedMinutes;
  }

  static int _diffMinutes(String start, String end) {
    final s = _parseToMinutes(start);
    final e = _parseToMinutes(end);
    int diff = e - s;
    if (diff < 0) diff += 24 * 60; // 자정을 넘기는 경우 보정
    return diff;
  }

  static int _parseToMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'plannedStart': plannedStart,
    'plannedEnd': plannedEnd,
    'title': title,
    'category': category,
    'isRoutine': isRoutine,
    'actualStart': actualStart,
    'actualEnd': actualEnd,
    'status': status,
  };

  factory TimelineBlock.fromJson(Map<String, dynamic> json) => TimelineBlock(
    id: json['id'] as String,
    date: json['date'] as String,
    plannedStart: json['plannedStart'] as String? ?? '00:00',
    plannedEnd: json['plannedEnd'] as String? ?? '00:00',
    title: json['title'] as String? ?? '',
    category: json['category'] as String? ?? '일반',
    isRoutine: json['isRoutine'] as bool? ?? false,
    actualStart: json['actualStart'] as String?,
    actualEnd: json['actualEnd'] as String?,
    status: json['status'] as String? ?? 'planned',
  );
}

class RoutineItem {
  final String startTime;
  final String endTime;
  final String title;
  final String category;

  RoutineItem({
    required this.startTime,
    required this.endTime,
    required this.title,
    this.category = '일반',
  });

  Map<String, dynamic> toJson() => {
    'startTime': startTime,
    'endTime': endTime,
    'title': title,
    'category': category,
  };

  factory RoutineItem.fromJson(Map<String, dynamic> json) => RoutineItem(
    startTime: json['startTime'] as String? ?? '00:00',
    endTime: json['endTime'] as String? ?? '00:00',
    title: json['title'] as String? ?? '',
    category: json['category'] as String? ?? '일반',
  );
}

class RoutineTemplate {
  final String id;
  final String name;
  final List<RoutineItem> items;

  RoutineTemplate({required this.id, required this.name, required this.items});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'items': items.map((e) => e.toJson()).toList(),
  };

  factory RoutineTemplate.fromJson(Map<String, dynamic> json) => RoutineTemplate(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    items: (json['items'] as List<dynamic>? ?? [])
        .map((e) => RoutineItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

class TimelineDataService {
  static const String _kTimelineKey = 'gke_general_planner_timeline_v1';
  static const String _kRoutineKey = 'gke_general_planner_routines_v1';

  // ------------------------- 타임라인 블록 -------------------------

  static Future<List<TimelineBlock>> loadAllBlocks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kTimelineKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((e) => TimelineBlock.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<TimelineBlock>> loadForDate(String dateKey) async {
    final all = await loadAllBlocks();
    final filtered = all.where((b) => b.date == dateKey).toList();
    filtered.sort((a, b) => a.plannedStart.compareTo(b.plannedStart));
    return filtered;
  }

  static Future<void> addBlock(TimelineBlock block) async {
    final all = await loadAllBlocks();
    all.add(block);
    await _saveAllBlocks(all);
  }

  static Future<void> updateBlock(TimelineBlock updated) async {
    final all = await loadAllBlocks();
    final idx = all.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      all[idx] = updated;
      await _saveAllBlocks(all);
    }
  }

  static Future<void> deleteBlock(String id) async {
    final all = await loadAllBlocks();
    all.removeWhere((e) => e.id == id);
    await _saveAllBlocks(all);
  }

  // 🆕 완료된(status == completed) 블록만 전체 조회 - 실행기록/분석 화면용
  static Future<List<TimelineBlock>> loadCompletedBlocks() async {
    final all = await loadAllBlocks();
    final completed = all.where((b) => b.status == 'completed').toList();
    completed.sort((a, b) => b.date.compareTo(a.date)); // 최신 날짜 먼저
    return completed;
  }

  // 🆕 일정이 하나라도 있는 날짜들 (타임라인 기록 화면의 날짜 목록용)
  static Future<List<String>> loadDatesWithTimeline() async {
    final all = await loadAllBlocks();
    final dates = all.map((e) => e.date).toSet().toList();
    dates.sort((a, b) => b.compareTo(a)); // 최신 날짜 먼저
    return dates;
  }

  static Future<void> _saveAllBlocks(List<TimelineBlock> blocks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(blocks.map((e) => e.toJson()).toList());
      await prefs.setString(_kTimelineKey, encoded);
    } catch (e) {
      // 저장 실패 시 다음 시도에서 재시도됨
    }
  }

  // ------------------------- 루틴 템플릿 -------------------------

  static Future<List<RoutineTemplate>> loadRoutines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kRoutineKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((e) => RoutineTemplate.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> addRoutine(RoutineTemplate routine) async {
    final all = await loadRoutines();
    all.add(routine);
    await _saveRoutines(all);
  }

  static Future<void> deleteRoutine(String id) async {
    final all = await loadRoutines();
    all.removeWhere((e) => e.id == id);
    await _saveRoutines(all);
  }

  static Future<void> _saveRoutines(List<RoutineTemplate> routines) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(routines.map((e) => e.toJson()).toList());
      await prefs.setString(_kRoutineKey, encoded);
    } catch (e) {
      // 저장 실패 시 다음 시도에서 재시도됨
    }
  }

  // 🆕 루틴 템플릿을 특정 날짜의 타임라인에 통째로 복사(적용)
  static Future<void> applyRoutineToDate(RoutineTemplate routine, String dateKey) async {
    final all = await loadAllBlocks();
    for (final item in routine.items) {
      all.add(TimelineBlock(
        id: '${DateTime.now().microsecondsSinceEpoch}_${item.startTime}',
        date: dateKey,
        plannedStart: item.startTime,
        plannedEnd: item.endTime,
        title: item.title,
        category: item.category,
        isRoutine: true,
      ));
    }
    await _saveAllBlocks(all);
  }
}
