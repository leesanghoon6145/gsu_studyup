// ============================================================================
// 🆕 [일반 플래너] ScheduleDataService
// "일정" 섹션(캘린더/오늘의 일정/약속/프로젝트 등)에서 공통으로 쓰는
// 일정 데이터 모델과 SharedPreferences 저장/불러오기를 한 곳에서 관리합니다.
//
// 저장 방식: 모든 일정을 하나의 리스트(JSON 문자열 배열)로 저장합니다.
// 화면마다 따로 저장소를 만들지 않고 이 서비스를 통해서만 읽고 쓰면,
// 캘린더 화면에서 추가한 일정이 오늘의 일정 화면에도 즉시 반영됩니다.
// ============================================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleItem {
  final String id;
  final String date; // 'yyyy-MM-dd' 형식
  final String time; // 'HH:mm' 형식 (없으면 빈 문자열)
  final String title;
  final String memo;
  final String category; // '일정' / '약속' / '프로젝트' 등 (1단계에서는 자유 텍스트)
  bool isCompleted;

  ScheduleItem({
    required this.id,
    required this.date,
    required this.time,
    required this.title,
    this.memo = '',
    this.category = '일정',
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'time': time,
    'title': title,
    'memo': memo,
    'category': category,
    'isCompleted': isCompleted,
  };

  factory ScheduleItem.fromJson(Map<String, dynamic> json) => ScheduleItem(
    id: json['id'] as String,
    date: json['date'] as String,
    time: json['time'] as String? ?? '',
    title: json['title'] as String? ?? '',
    memo: json['memo'] as String? ?? '',
    category: json['category'] as String? ?? '일정',
    isCompleted: json['isCompleted'] as bool? ?? false,
  );
}

class ScheduleDataService {
  static const String _kScheduleKey = 'gke_general_planner_schedules_v1';

  // 🆕 전체 일정 목록 불러오기
  static Future<List<ScheduleItem>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kScheduleKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((e) => ScheduleItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // 🆕 특정 날짜('yyyy-MM-dd')의 일정만 필터링해서 가져오기
  static Future<List<ScheduleItem>> loadForDate(String dateKey) async {
    final all = await loadAll();
    final filtered = all.where((item) => item.date == dateKey).toList();
    // 시간 순으로 정렬 (시간 없는 항목은 맨 위)
    filtered.sort((a, b) => a.time.compareTo(b.time));
    return filtered;
  }

  // 🆕 일정이 하나라도 있는 날짜들의 집합 (캘린더에 점 표시용)
  static Future<Set<String>> loadDatesWithSchedule() async {
    final all = await loadAll();
    return all.map((e) => e.date).toSet();
  }

  // 🆕 일정 추가
  static Future<void> add(ScheduleItem item) async {
    final all = await loadAll();
    all.add(item);
    await _saveAll(all);
  }

  // 🆕 일정 수정 (완료 체크 토글 등)
  static Future<void> update(ScheduleItem updated) async {
    final all = await loadAll();
    final idx = all.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      all[idx] = updated;
      await _saveAll(all);
    }
  }

  // 🆕 일정 삭제
  static Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((e) => e.id == id);
    await _saveAll(all);
  }

  static Future<void> _saveAll(List<ScheduleItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(items.map((e) => e.toJson()).toList());
      await prefs.setString(_kScheduleKey, encoded);
    } catch (e) {
      // 저장 실패는 조용히 무시하지 않고 다음 시도에서 재시도됨 (호출부에서 필요시 안내)
    }
  }
}
