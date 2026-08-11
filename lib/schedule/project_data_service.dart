// ============================================================================
// 🆕 [일반 플래너 - 프로젝트] ProjectDataService
// 프로젝트(제목/분야/마감일/상태)와 그에 연결된 하위 작업(ProjectTask)을
// 저장/불러오는 서비스입니다. 진행률은 저장된 숫자가 아니라, 연결된
// 작업 중 완료된 비율을 그때그때 계산합니다.
// ============================================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProjectItem {
  final String id;
  final String title;
  final String category;
  final String deadline; // 'yyyy-MM-dd', 비워도 됨
  final String status; // '진행중' | '완료' | '보류'
  final String description;
  final String createdAt;
  final String completedDate; // 🆕 [리포트 연동] 상태가 '완료'로 바뀐 날짜('yyyy-MM-dd'), 리포트의 "완료된 프로젝트" 집계에 사용

  ProjectItem({
    required this.id,
    required this.title,
    this.category = '일반',
    this.deadline = '',
    this.status = '진행중',
    this.description = '',
    required this.createdAt,
    this.completedDate = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'deadline': deadline,
    'status': status,
    'description': description,
    'createdAt': createdAt,
    'completedDate': completedDate,
  };

  factory ProjectItem.fromJson(Map<String, dynamic> json) => ProjectItem(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    category: json['category'] as String? ?? '일반',
    deadline: json['deadline'] as String? ?? '',
    status: json['status'] as String? ?? '진행중',
    description: json['description'] as String? ?? '',
    createdAt: json['createdAt'] as String? ?? '',
    completedDate: json['completedDate'] as String? ?? '',
  );
}

class ProjectTask {
  final String id;
  final String projectId;
  final String title;
  bool isCompleted;
  String createdAt; // 🆕 [시간 기록] 'yyyy-MM-dd HH:mm' 형식, 정렬 및 수정에 사용

  ProjectTask({
    required this.id,
    required this.projectId,
    required this.title,
    this.isCompleted = false,
    String? createdAt,
  }) : createdAt = createdAt ?? _nowString();

  static String _nowString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {'id': id, 'projectId': projectId, 'title': title, 'isCompleted': isCompleted, 'createdAt': createdAt};

  factory ProjectTask.fromJson(Map<String, dynamic> json) => ProjectTask(
    id: json['id'] as String,
    projectId: json['projectId'] as String? ?? '',
    title: json['title'] as String? ?? '',
    isCompleted: json['isCompleted'] as bool? ?? false,
    createdAt: json['createdAt'] as String?,
  );
}

class ProjectDataService {
  static const String _kProjectKey = 'gke_general_planner_projects_v1';
  static const String _kTaskKey = 'gke_general_planner_project_tasks_v1';

  static Future<List<ProjectItem>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kProjectKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      final list = decoded.map((e) => ProjectItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      // 🆕 [정렬 버그 수정] 만든 순서가 아니라 마감일이 가까운 순서로 정렬.
      // 마감일이 없는 프로젝트는 맨 아래로 보냄.
      list.sort((a, b) {
        final bool aHasDeadline = a.deadline.isNotEmpty;
        final bool bHasDeadline = b.deadline.isNotEmpty;
        if (aHasDeadline && !bHasDeadline) return -1;
        if (!aHasDeadline && bHasDeadline) return 1;
        if (!aHasDeadline && !bHasDeadline) return b.createdAt.compareTo(a.createdAt); // 둘 다 마감일 없으면 최신 생성순
        return a.deadline.compareTo(b.deadline); // 마감일 가까운 것부터
      });
      return list;
    } catch (e) {
      return [];
    }
  }

  static Future<void> add(ProjectItem item) async {
    final all = await loadAll();
    all.add(item);
    await _saveAll(all);
  }

  static Future<void> update(ProjectItem updated) async {
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
    final tasks = await loadAllTasks();
    tasks.removeWhere((t) => t.projectId == id);
    await _saveAllTasks(tasks);
  }

  static Future<void> _saveAll(List<ProjectItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProjectKey, jsonEncode(items.map((e) => e.toJson()).toList()));
    } catch (e) {}
  }

  // ------------------------- 하위 작업(ProjectTask) -------------------------

  static Future<List<ProjectTask>> loadAllTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kTaskKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => ProjectTask.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<ProjectTask>> loadTasksForProject(String projectId) async {
    final all = await loadAllTasks();
    final filtered = all.where((t) => t.projectId == projectId).toList();
    // 🆕 [정렬 수정] 오래된 것이 아래로, 가장 최근 기록이 맨 위로 오도록 내림차순 정렬
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  static Future<void> addTask(ProjectTask task) async {
    final all = await loadAllTasks();
    all.add(task);
    await _saveAllTasks(all);
  }

  static Future<void> updateTask(ProjectTask updated) async {
    final all = await loadAllTasks();
    final idx = all.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      all[idx] = updated;
      await _saveAllTasks(all);
    }
  }

  static Future<void> deleteTask(String id) async {
    final all = await loadAllTasks();
    all.removeWhere((e) => e.id == id);
    await _saveAllTasks(all);
  }

  static Future<void> _saveAllTasks(List<ProjectTask> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kTaskKey, jsonEncode(tasks.map((e) => e.toJson()).toList()));
    } catch (e) {}
  }

  // 🆕 프로젝트 진행률(0.0~1.0) 실시간 계산
  static Future<double> calcProgress(String projectId) async {
    final tasks = await loadTasksForProject(projectId);
    if (tasks.isEmpty) return 0.0;
    final completed = tasks.where((t) => t.isCompleted).length;
    return completed / tasks.length;
  }
}
