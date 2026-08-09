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

  ProjectItem({
    required this.id,
    required this.title,
    this.category = '일반',
    this.deadline = '',
    this.status = '진행중',
    this.description = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'deadline': deadline,
    'status': status,
    'description': description,
    'createdAt': createdAt,
  };

  factory ProjectItem.fromJson(Map<String, dynamic> json) => ProjectItem(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    category: json['category'] as String? ?? '일반',
    deadline: json['deadline'] as String? ?? '',
    status: json['status'] as String? ?? '진행중',
    description: json['description'] as String? ?? '',
    createdAt: json['createdAt'] as String? ?? '',
  );
}

class ProjectTask {
  final String id;
  final String projectId;
  final String title;
  bool isCompleted;

  ProjectTask({required this.id, required this.projectId, required this.title, this.isCompleted = false});

  Map<String, dynamic> toJson() => {'id': id, 'projectId': projectId, 'title': title, 'isCompleted': isCompleted};

  factory ProjectTask.fromJson(Map<String, dynamic> json) => ProjectTask(
    id: json['id'] as String,
    projectId: json['projectId'] as String? ?? '',
    title: json['title'] as String? ?? '',
    isCompleted: json['isCompleted'] as bool? ?? false,
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
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
    return all.where((t) => t.projectId == projectId).toList();
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
