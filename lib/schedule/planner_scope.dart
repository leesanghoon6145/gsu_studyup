// planner_scope.dart
//
// 🆕 [계정별 분리 2026-09-30] 일반 플래너의 모든 저장 이름 끝에 로그인한 계정 번호(uid)를
// 붙여서, 한 휴대폰에서 학부모·일반인 계정을 바꿔 써도 일정·약속·프로젝트·타임라인·
// 목표·리마인더가 서로 섞이지 않게 한다. (운동 기록 exercise_data_service.dart와 같은 방식)
//
// - plannerScopedKey(): 저장 이름 만들기 (로그인 전이면 예전 이름 그대로)
// - migrateUnscopedPlannerData(): 업데이트 전에 쓰던 옛 데이터를, 업데이트 후 처음
//   일반 플래너에 들어온 계정으로 딱 한 번 옮김 → 테스터들의 일정·알림이 사라지지 않음.
//   옮긴 뒤 공용 칸은 비워서, 다른 계정에 또 옮겨지지 않게 함.
//
// ⚠️ 여기 목록에 없는 것 (일부러 계정별로 나누지 않음)
// - 타이머 계산기 알람(general_planner_alarm_list_v1): 휴대폰 시계 알람처럼 기기에 예약되므로
//   계정을 바꿔도 휴대폰에서는 계속 울림 → 목록도 기기 하나로 두는 것이 맞음
// - 자기주도 플래너(학생) 알람(gke_global_schedules): 학생 쪽 데이터라 이번 작업과 무관

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 저장 이름 끝에 계정 번호를 붙임. 로그인 전이면 예전 이름 그대로.
String plannerScopedKey(String base) {
  try {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null ? base : '${base}_$uid';
  } catch (_) {
    return base;
  }
}

// 계정별로 나누는 일반 플래너 저장 이름 전체 (검색 결과 10개와 같음)
const List<String> kPlannerBaseKeys = [
  'gke_general_planner_schedules_v1',
  'gke_general_planner_appointments_v1',
  'gke_general_planner_projects_v1',
  'gke_general_planner_project_tasks_v1',
  'gke_general_planner_timeline_v1',
  'gke_general_planner_routines_v1',
  'gke_general_planner_goals_v2',
  'gke_general_planner_todos_v1',
  'gke_general_planner_achievements_v1',
  'gke_general_planner_reminders_v1',
];

/// 업데이트 전 옛 데이터를 지금 로그인한 계정으로 한 번만 옮김.
/// 일반 플래너 홈에 들어올 때마다 불러도 안전함 (옮길 것이 없으면 아무것도 안 함).
Future<void> migrateUnscopedPlannerData() async {
  try {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    for (final String base in kPlannerBaseKeys) {
      final String? old = prefs.getString(base);
      if (old == null || old.isEmpty || old == '[]') continue;
      final String scoped = '${base}_$uid';
      final String? existing = prefs.getString(scoped);
      if (existing == null || existing.isEmpty || existing == '[]') {
        await prefs.setString(scoped, old);
        await prefs.remove(base); // 옮겼으면 공용 칸은 비움 → 다른 계정에 또 옮겨지지 않음
        debugPrint('[planner_scope] 옛 데이터 옮김: $base → 계정별');
      }
    }
  } catch (e) {
    debugPrint('[planner_scope] 옛 데이터 옮기기 실패(다음에 다시 시도): $e');
  }
}
