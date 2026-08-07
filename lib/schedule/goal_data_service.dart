// ============================================================================
// 🆕 [일반 플래너 3단계] GoalDataService
// "목표" 섹션(인생목표/연간~오늘목표/ToDo/진행률/성취)에서 공통으로 쓰는
// 데이터 모델과 저장/불러오기를 관리합니다.
//
// 구조: GoalItem(목표) ↔ TodoItem(할 일, goalId로 목표와 연결)
// 진행률(progress)은 저장된 숫자가 아니라, 그 목표에 연결된 할 일 중
// 완료된 비율을 그때그때 계산합니다 (가짜 숫자를 저장하지 않기 위함).
// 목표를 "성취 완료" 처리하면 AchievementRecord로 별도 저장됩니다.
// ============================================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GoalItem {
  final String id;
  final String type; // 'life' | 'yearly' | 'monthly' | 'weekly' | 'today'
  final String title;
  final String category; // 분야: 건강/재정/자기계발/관계 등 (자유 텍스트)
  final String periodKey; // 생성 시점 기준 기간 표시용 문자열 (예: '2026', '2026-08', 'today:2026-08-07')
  bool isAchieved;
  final String createdAt;

  GoalItem({
    required this.id,
    required this.type,
    required this.title,
    this.category = '일반',
    this.periodKey = '',
    this.isAchieved = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'category': category,
    'periodKey': periodKey,
    'isAchieved': isAchieved,
    'createdAt': createdAt,
  };

  factory GoalItem.fromJson(Map<String, dynamic> json) => GoalItem(
    id: json['id'] as String,
    type: json['type'] as String,
    title: json['title'] as String? ?? '',
    category: json['category'] as String? ?? '일반',
    periodKey: json['periodKey'] as String? ?? '',
    isAchieved: json['isAchieved'] as bool? ?? false,
    createdAt: json['createdAt'] as String? ?? '',
  );
}

class TodoItem {
  final String id;
  final String? goalId; // null이면 목표에 안 묶인 독립 할 일
  final String title;
  final String date; // 'yyyy-MM-dd'
  bool isCompleted;

  TodoItem({
    required this.id,
    this.goalId,
    required this.title,
    required this.date,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'goalId': goalId,
    'title': title,
    'date': date,
    'isCompleted': isCompleted,
  };

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
    id: json['id'] as String,
    goalId: json['goalId'] as String?,
    title: json['title'] as String? ?? '',
    date: json['date'] as String? ?? '',
    isCompleted: json['isCompleted'] as bool? ?? false,
  );
}

class AchievementRecord {
  final String id;
  final String goalTitle;
  final String goalType;
  final String achievedDate; // 'yyyy-MM-dd'

  AchievementRecord({
    required this.id,
    required this.goalTitle,
    required this.goalType,
    required this.achievedDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'goalTitle': goalTitle,
    'goalType': goalType,
    'achievedDate': achievedDate,
  };

  factory AchievementRecord.fromJson(Map<String, dynamic> json) => AchievementRecord(
    id: json['id'] as String,
    goalTitle: json['goalTitle'] as String? ?? '',
    goalType: json['goalType'] as String? ?? '',
    achievedDate: json['achievedDate'] as String? ?? '',
  );
}

class GoalDataService {
  static const String _kGoalKey = 'gke_general_planner_goals_v1';
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
    // 목표를 지우면 거기 연결된 할 일도 함께 정리
    final todos = await loadAllTodos();
    todos.removeWhere((t) => t.goalId == id);
    await _saveTodos(todos);
  }

  static Future<void> _saveGoals(List<GoalItem> goals) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kGoalKey, jsonEncode(goals.map((e) => e.toJson()).toList()));
    } catch (e) {
      // 다음 저장 시도에서 재시도됨
    }
  }

  // ------------------------- 할 일(Todo) -------------------------

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

  // 🆕 특정 목표(goalId)에 연결된 할 일만 조회
  static Future<List<TodoItem>> loadTodosForGoal(String goalId) async {
    final all = await loadAllTodos();
    return all.where((t) => t.goalId == goalId).toList();
  }

  // 🆕 목표에 안 묶인 독립 할 일만 조회 (todo_screen.dart용)
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
    } catch (e) {
      // 다음 저장 시도에서 재시도됨
    }
  }

  // 🆕 목표 하나의 진행률(0.0~1.0) 실시간 계산 - 저장된 숫자가 아니라 그때그때 계산
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

  // 🆕 목표를 "성취 완료" 처리 - isAchieved를 true로 바꾸고 AchievementRecord를 함께 저장
  static Future<void> markGoalAchieved(GoalItem goal) async {
    goal.isAchieved = true;
    await updateGoal(goal);

    final now = DateTime.now();
    final String todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final record = AchievementRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      goalTitle: goal.title,
      goalType: goal.type,
      achievedDate: todayKey,
    );

    final all = await loadAchievements();
    all.add(record);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAchievementKey, jsonEncode(all.map((e) => e.toJson()).toList()));
    } catch (e) {
      // 다음 저장 시도에서 재시도됨
    }
  }
}
