// ============================================================================
// 🆕 [일반 플래너 - 전체 연동 재설계] GoalDataService
// "목표" 섹션(인생목표/연간~오늘목표/ToDo/진행률/성취)에서 공통으로 쓰는
// 데이터 모델과 저장/불러오기를 관리합니다.
//
// 🆕 [핵심 변경] 연간/월간/주간/오늘 목표는 이제 애매한 periodKey 문자열
// 대신, 실제 날짜 범위(periodStart~periodEnd)를 저장합니다. 이 범위를
// ReportDataService.summarize()에 그대로 넘기면, 캘린더+타임라인에서
// 실제로 완료한 것을 기준으로 진행률이 자동 계산됩니다(period_goal_screen.dart
// 참고). 즉 "오늘 목표"의 진행률은 오늘 캘린더+타임라인 완료율과 동일한
// 숫자를 보게 됩니다 - 더 이상 따로 할 일을 만들 필요가 없습니다.
//
// 인생 목표(life)만 예외적으로 특정 날짜 범위가 없으므로, 기존처럼
// TodoItem을 연결해서 할 일 체크 기반으로 진행률을 계산합니다.
// ============================================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GoalItem {
  final String id;
  final String type; // 'life' | 'yearly' | 'monthly' | 'weekly' | 'today'
  final String title;
  final String category; // 분야: 건강/재정/자기계발/관계 등 (자유 텍스트)
  final String periodStart; // 'yyyy-MM-dd', life 타입은 빈 문자열
  final String periodEnd; // 'yyyy-MM-dd', life 타입은 빈 문자열
  bool isAchieved;
  final String createdAt;

  GoalItem({
    required this.id,
    required this.type,
    required this.title,
    this.category = '일반',
    this.periodStart = '',
    this.periodEnd = '',
    this.isAchieved = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'category': category,
    'periodStart': periodStart,
    'periodEnd': periodEnd,
    'isAchieved': isAchieved,
    'createdAt': createdAt,
  };

  factory GoalItem.fromJson(Map<String, dynamic> json) => GoalItem(
    id: json['id'] as String,
    type: json['type'] as String,
    title: json['title'] as String? ?? '',
    category: json['category'] as String? ?? '일반',
    periodStart: json['periodStart'] as String? ?? '',
    periodEnd: json['periodEnd'] as String? ?? '',
    isAchieved: json['isAchieved'] as bool? ?? false,
    createdAt: json['createdAt'] as String? ?? '',
  );
}

class TodoItem {
  final String id;
  final String? goalId; // null이면 목표에 안 묶인 독립 할 일 (인생목표 또는 todo_screen 전용)
  final String title;
  final String date; // 'yyyy-MM-dd'
  bool isCompleted;
  String createdAt; // 🆕 [정렬 수정] 같은 날 여러 개 만들어도 정확한 순서로 "최근 입력이 맨 위" 정렬 가능하게 함

  TodoItem({required this.id, this.goalId, required this.title, required this.date, this.isCompleted = false, String? createdAt})
      : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toJson() => {'id': id, 'goalId': goalId, 'title': title, 'date': date, 'isCompleted': isCompleted, 'createdAt': createdAt};

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
    id: json['id'] as String,
    goalId: json['goalId'] as String?,
    title: json['title'] as String? ?? '',
    date: json['date'] as String? ?? '',
    isCompleted: json['isCompleted'] as bool? ?? false,
    createdAt: json['createdAt'] as String?,
  );
}

class AchievementRecord {
  final String id;
  final String goalTitle;
  final String goalType;
  final String achievedDate; // 'yyyy-MM-dd'

  AchievementRecord({required this.id, required this.goalTitle, required this.goalType, required this.achievedDate});

  Map<String, dynamic> toJson() => {'id': id, 'goalTitle': goalTitle, 'goalType': goalType, 'achievedDate': achievedDate};

  factory AchievementRecord.fromJson(Map<String, dynamic> json) => AchievementRecord(
    id: json['id'] as String,
    goalTitle: json['goalTitle'] as String? ?? '',
    goalType: json['goalType'] as String? ?? '',
    achievedDate: json['achievedDate'] as String? ?? '',
  );
}

class GoalDataService {
  static const String _kGoalKey = 'gke_general_planner_goals_v2'; // 🆕 구조 변경으로 키 버전 올림(v1과 분리)
  static const String _kTodoKey = 'gke_general_planner_todos_v1';
  static const String _kAchievementKey = 'gke_general_planner_achievements_v1';

  // ------------------------- 목표(Goal) -------------------------

  static Future<List<GoalItem>> loadAllGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kGoalKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => GoalItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<GoalItem>> loadGoalsByType(String type) async {
    final all = await loadAllGoals();
    final filtered = all.where((g) => g.type == type).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  static Future<void> addGoal(GoalItem goal) async {
    final all = await loadAllGoals();
    all.add(goal);
    await _saveGoals(all);
  }

  static Future<void> updateGoal(GoalItem updated) async {
    final all = await loadAllGoals();
    final idx = all.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      all[idx] = updated;
      await _saveGoals(all);
    }
  }

  static Future<void> deleteGoal(String id) async {
    final all = await loadAllGoals();
    all.removeWhere((e) => e.id == id);
    await _saveGoals(all);
    final todos = await loadAllTodos();
    todos.removeWhere((t) => t.goalId == id);
    await _saveTodos(todos);
  }

  static Future<void> _saveGoals(List<GoalItem> goals) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kGoalKey, jsonEncode(goals.map((e) => e.toJson()).toList()));
    } catch (e) {}
  }

  // ------------------------- 할 일(Todo) - 인생목표 전용 + 독립 할 일 -------------------------

  static Future<List<TodoItem>> loadAllTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kTodoKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => TodoItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<TodoItem>> loadTodosForGoal(String goalId) async {
    final all = await loadAllTodos();
    return all.where((t) => t.goalId == goalId).toList();
  }

  static Future<List<TodoItem>> loadStandaloneTodos() async {
    final all = await loadAllTodos();
    return all.where((t) => t.goalId == null).toList();
  }

  static Future<void> addTodo(TodoItem todo) async {
    final all = await loadAllTodos();
    all.add(todo);
    await _saveTodos(all);
  }

  static Future<void> updateTodo(TodoItem updated) async {
    final all = await loadAllTodos();
    final idx = all.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      all[idx] = updated;
      await _saveTodos(all);
    }
  }

  static Future<void> deleteTodo(String id) async {
    final all = await loadAllTodos();
    all.removeWhere((e) => e.id == id);
    await _saveTodos(all);
  }

  static Future<void> _saveTodos(List<TodoItem> todos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kTodoKey, jsonEncode(todos.map((e) => e.toJson()).toList()));
    } catch (e) {}
  }

  // 🆕 인생목표 전용 진행률(0.0~1.0) - 연결된 할 일 완료 비율. 기간별 목표는 더 이상
  // 이 함수를 쓰지 않고, period_goal_screen.dart에서 ReportDataService.summarize()로
  // 캘린더+타임라인 실제 데이터를 기준으로 진행률을 계산합니다.
  static Future<double> calcGoalProgress(String goalId) async {
    final todos = await loadTodosForGoal(goalId);
    if (todos.isEmpty) return 0.0;
    final completed = todos.where((t) => t.isCompleted).length;
    return completed / todos.length;
  }

  // ------------------------- 성취(Achievement) -------------------------

  static Future<List<AchievementRecord>> loadAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kAchievementKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      final list = decoded.map((e) => AchievementRecord.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      list.sort((a, b) => b.achievedDate.compareTo(a.achievedDate));
      return list;
    } catch (e) {
      return [];
    }
  }

  static Future<void> markGoalAchieved(GoalItem goal) async {
    goal.isAchieved = true;
    await updateGoal(goal);

    final now = DateTime.now();
    final String todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final record = AchievementRecord(id: DateTime.now().microsecondsSinceEpoch.toString(), goalTitle: goal.title, goalType: goal.type, achievedDate: todayKey);

    final all = await loadAchievements();
    all.add(record);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAchievementKey, jsonEncode(all.map((e) => e.toJson()).toList()));
    } catch (e) {}
  }
}
