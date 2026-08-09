// ============================================================================
// 🆕 [일반 플래너 4단계] ReportDataService
// "리포트" 섹션(일간/주간/월간/연간/통계)에서 쓰는 통계를 계산합니다.
// 새로운 데이터를 따로 저장하지 않고, 이미 저장된 일정(ScheduleDataService)/
// 타임라인(TimelineDataService)/목표(GoalDataService)의 실제 기록만 그때그때
// 집계합니다. 데이터가 없는 구간은 0%가 아니라 "데이터 없음"으로 구분해서
// 돌려주므로, 화면에서 가짜 수치처럼 보이지 않게 처리할 수 있습니다.
// ============================================================================

import 'schedule_data_service.dart';
import 'timeline_data_service.dart';
import 'goal_data_service.dart';

class ReportSummary {
  final int totalCount; // 일정 + 타임라인 전체 항목 수
  final int completedCount; // 그중 완료된 항목 수
  final Map<String, int> categoryMinutes; // 타임라인 완료 항목의 분류별 실제 소요시간(분)
  final bool hasData; // 이 기간에 기록이 하나라도 있는지

  ReportSummary({
    required this.totalCount,
    required this.completedCount,
    required this.categoryMinutes,
    required this.hasData,
  });

  double get completionRate => totalCount == 0 ? 0 : completedCount / totalCount;
  int get completionPercent => (completionRate * 100).round();
  int get totalMinutes => categoryMinutes.values.fold(0, (a, b) => a + b);
}

class ReportDataService {
  static String _dateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static bool _inRange(String dateKey, DateTime start, DateTime end) {
    // 날짜 문자열('yyyy-MM-dd')은 사전순 비교가 날짜순 비교와 동일하게 동작함
    final s = _dateKey(start);
    final e = _dateKey(end);
    return dateKey.compareTo(s) >= 0 && dateKey.compareTo(e) <= 0;
  }

  // 🆕 특정 기간(start~end, 포함)의 일정+타임라인 완료율과 분류별 시간을 집계
  static Future<ReportSummary> summarize(DateTime start, DateTime end) async {
    final allSchedules = await ScheduleDataService.loadAll();
    final allBlocks = await TimelineDataService.loadAllBlocks();

    final schedulesInRange = allSchedules.where((s) => _inRange(s.date, start, end)).toList();
    final blocksInRange = allBlocks.where((b) => _inRange(b.date, start, end)).toList();

    final int totalCount = schedulesInRange.length + blocksInRange.length;
    final int completedCount =
        schedulesInRange.where((s) => s.isCompleted).length + blocksInRange.where((b) => b.status == 'completed').length;

    final Map<String, int> categoryMinutes = {};
    for (final block in blocksInRange) {
      if (block.status != 'completed') continue;
      final minutes = block.actualMinutes;
      if (minutes == null) continue;
      categoryMinutes[block.category] = (categoryMinutes[block.category] ?? 0) + minutes;
    }

    return ReportSummary(
      totalCount: totalCount,
      completedCount: completedCount,
      categoryMinutes: categoryMinutes,
      hasData: totalCount > 0,
    );
  }

  // 🆕 [주간 리포트] 이 기간 중 타임라인 항목이 가장 많이 등록된 요일 (데이터 없으면 null)
  static Future<String?> findBusiestWeekday(DateTime start, DateTime end) async {
    final allBlocks = await TimelineDataService.loadAllBlocks();
    final inRange = allBlocks.where((b) => _inRange(b.date, start, end)).toList();
    if (inRange.isEmpty) return null;

    const weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final Map<int, int> countByWeekday = {};
    for (final block in inRange) {
      final parts = block.date.split('-');
      if (parts.length != 3) continue;
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      countByWeekday[date.weekday] = (countByWeekday[date.weekday] ?? 0) + 1;
    }
    if (countByWeekday.isEmpty) return null;

    final busiest = countByWeekday.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return weekdayNames[busiest.key - 1];
  }

  // 🆕 [주간 리포트] 완료된 타임라인 항목이 가장 많이 시작된 시간대(예: '09:00~12:00'), 데이터 없으면 null
  static Future<String?> findMostProductiveHourRange(DateTime start, DateTime end) async {
    final allBlocks = await TimelineDataService.loadAllBlocks();
    final completed = allBlocks.where((b) => _inRange(b.date, start, end) && b.status == 'completed').toList();
    if (completed.isEmpty) return null;

    // 3시간 단위 구간(0~2,3~5,...)으로 나눠서 가장 많이 몰린 구간을 찾음
    final Map<int, int> countByBucket = {};
    for (final block in completed) {
      final hour = int.tryParse(block.plannedStart.split(':').first) ?? 0;
      final bucket = hour ~/ 3;
      countByBucket[bucket] = (countByBucket[bucket] ?? 0) + 1;
    }
    if (countByBucket.isEmpty) return null;

    final busiest = countByBucket.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final int startHour = busiest.key * 3;
    final int endHour = startHour + 3;
    return '${startHour.toString().padLeft(2, '0')}:00~${endHour.toString().padLeft(2, '0')}:00';
  }

  // 🆕 [월간 리포트] 루틴에서 온 타임라인 항목의 완료율(%), 데이터 없으면 null
  static Future<int?> calcRoutineSuccessRate(DateTime start, DateTime end) async {
    final allBlocks = await TimelineDataService.loadAllBlocks();
    final routineBlocks = allBlocks.where((b) => _inRange(b.date, start, end) && b.isRoutine).toList();
    if (routineBlocks.isEmpty) return null;
    final completed = routineBlocks.where((b) => b.status == 'completed').length;
    return ((completed / routineBlocks.length) * 100).round();
  }

  // 🆕 [연간 리포트/통계] 1~12월 각각의 완료율(%). 그 달에 기록이 전혀 없으면 -1로 표시(구분용)
  static Future<Map<int, int>> calcMonthlyCompletionRates(int year) async {
    final Map<int, int> result = {};
    for (int month = 1; month <= 12; month++) {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 0);
      final summary = await summarize(start, end);
      result[month] = summary.hasData ? summary.completionPercent : -1;
    }
    return result;
  }

  // 🆕 [연간 리포트] 완료 항목이 가장 많았던 달 (1~12), 데이터 없으면 null
  static Future<int?> findMostProductiveMonth(int year) async {
    int? bestMonth;
    int bestCount = 0;
    final allBlocks = await TimelineDataService.loadAllBlocks();
    final allSchedules = await ScheduleDataService.loadAll();

    for (int month = 1; month <= 12; month++) {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 0);
      final blockCount = allBlocks.where((b) => _inRange(b.date, start, end) && b.status == 'completed').length;
      final scheduleCount = allSchedules.where((s) => _inRange(s.date, start, end) && s.isCompleted).length;
      final total = blockCount + scheduleCount;
      if (total > bestCount) {
        bestCount = total;
        bestMonth = month;
      }
    }
    return bestMonth;
  }

  // 🆕 [연간 리포트/통계] 완료된 타임라인 중 가장 많이 등장한 요일(문자열), 데이터 없으면 null
  static Future<String?> findMostActiveWeekdayOverall(DateTime start, DateTime end) => findBusiestWeekday(start, end);

  // 🆕 [목표 연동] 이 기간 안에 달성(성취완료)된 목표 개수
  static Future<int> countAchievementsInRange(DateTime start, DateTime end) async {
    final all = await GoalDataService.loadAchievements();
    return all.where((a) => _inRange(a.achievedDate, start, end)).length;
  }
}
