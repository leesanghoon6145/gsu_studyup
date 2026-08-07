// ============================================================================
// 🆕 [일반 플래너 3단계 갱신] GeneralPlannerHomeScreen
// 1단계(일정)+2단계(타임라인)에 이어, 3단계(목표: 인생/연간/월간/주간/오늘
// 목표/ToDo/진행률/성취)까지 전부 실제로 연결되었습니다. 리포트 섹션만
// 아직 "준비 중"이며 4단계에서 이어서 만들 예정입니다.
// 디자인 톤: 기존 home_dashboard_screen.dart와 동일한 다크네이비+골드 테마.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'calendar_screen.dart';
import 'today_schedule_screen.dart';
import 'today_timeline_screen.dart';
import 'routine_screen.dart';
import 'execution_record_screen.dart';
import 'timeline_history_screen.dart';
import 'timeline_analysis_screen.dart';
import 'life_goal_screen.dart';
import 'yearly_goal_screen.dart';
import 'monthly_goal_screen.dart';
import 'weekly_goal_screen.dart';
import 'today_goal_screen.dart';
import 'todo_screen.dart';
import 'progress_screen.dart';
import 'achievement_screen.dart';

class GeneralPlannerHomeScreen extends StatelessWidget {
  const GeneralPlannerHomeScreen({super.key});

  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('GENERAL PLANNER', style: GoogleFonts.gowunBatang(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 22)),
            Text('일반 플래너', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('SCHEDULE', '일정'),
            const SizedBox(height: 12),
            _buildMenuGrid(context, [
              _MenuEntry('📅', 'CALENDAR', '캘린더', () => _navigate(context, const CalendarScreen())),
              _MenuEntry('📝', "TODAY'S SCHEDULE", '오늘의 일정', () => _navigate(context, const TodayScheduleScreen())),
              _MenuEntry('⏰', 'APPOINTMENT', '약속', () => _showComingSoon(context, '약속')),
              _MenuEntry('📌', 'PROJECT', '프로젝트', () => _showComingSoon(context, '프로젝트')),
              _MenuEntry('🔔', 'REMINDER', '알림', () => _showComingSoon(context, '알림')),
              _MenuEntry('📈', 'SCHEDULE ANALYSIS', '일정 분석', () => _showComingSoon(context, '일정 분석')),
            ]),
            const SizedBox(height: 30),

            _buildSectionTitle('TIMELINE', '타임라인'),
            const SizedBox(height: 12),
            _buildMenuGrid(context, [
              _MenuEntry('🕒', "TODAY'S TIMELINE", '오늘의 타임라인', () => _navigate(context, const TodayTimelineScreen())),
              _MenuEntry('🔁', 'ROUTINE', '루틴', () => _navigate(context, const RoutineScreen())),
              _MenuEntry('📜', 'TIMELINE HISTORY', '타임라인 기록', () => _navigate(context, const TimelineHistoryScreen())),
              _MenuEntry('✅', 'EXECUTION RECORD', '실행 기록', () => _navigate(context, const ExecutionRecordScreen())),
              _MenuEntry('📊', 'TIMELINE ANALYSIS', '타임라인 분석', () => _navigate(context, const TimelineAnalysisScreen())),
            ]),
            const SizedBox(height: 30),

            _buildSectionTitle('GOAL', '목표'),
            const SizedBox(height: 12),
            _buildMenuGrid(context, [
              _MenuEntry('🎯', 'LIFE GOAL', '인생 목표', () => _navigate(context, const LifeGoalScreen())),
              _MenuEntry('📅', 'YEARLY GOAL', '연간 목표', () => _navigate(context, const YearlyGoalScreen())),
              _MenuEntry('📅', 'MONTHLY GOAL', '월간 목표', () => _navigate(context, const MonthlyGoalScreen())),
              _MenuEntry('📅', 'WEEKLY GOAL', '주간 목표', () => _navigate(context, const WeeklyGoalScreen())),
              _MenuEntry('📅', 'TODAY GOAL', '오늘 목표', () => _navigate(context, const TodayGoalScreen())),
              _MenuEntry('✅', 'TODO', '할 일', () => _navigate(context, const TodoScreen())),
              _MenuEntry('📈', 'PROGRESS', '진행률', () => _navigate(context, const ProgressScreen())),
              _MenuEntry('🏆', 'ACHIEVEMENT', '성취', () => _navigate(context, const AchievementScreen())),
            ]),
            const SizedBox(height: 30),

            _buildSectionTitle('REPORT', '리포트'),
            const SizedBox(height: 12),
            _buildMenuGrid(context, [
              _MenuEntry('📊', 'DAILY REPORT', '일간 리포트', () => _showComingSoon(context, '일간 리포트')),
              _MenuEntry('📊', 'WEEKLY REPORT', '주간 리포트', () => _showComingSoon(context, '주간 리포트')),
              _MenuEntry('📊', 'MONTHLY REPORT', '월간 리포트', () => _showComingSoon(context, '월간 리포트')),
              _MenuEntry('📊', 'YEARLY REPORT', '연간 리포트', () => _showComingSoon(context, '연간 리포트')),
              _MenuEntry('📈', 'STATISTICS', '통계', () => _showComingSoon(context, '통계')),
            ]),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label 화면은 준비 중입니다. (Coming Soon)', style: GoogleFonts.notoSansKr())),
    );
  }

  Widget _buildSectionTitle(String en, String ko) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(en, style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        Text('($ko)', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildMenuGrid(BuildContext context, List<_MenuEntry> entries) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: entries.map((e) => _buildMenuButton(e)).toList(),
    );
  }

  Widget _buildMenuButton(_MenuEntry entry) {
    return InkWell(
      onTap: entry.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _containerBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _brandGolden.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Text(entry.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.enLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansKr(color: const Color(0xFFFFF6D6), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    entry.koLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.gowunBatang(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuEntry {
  final String emoji;
  final String enLabel;
  final String koLabel;
  final VoidCallback onTap;

  _MenuEntry(this.emoji, this.enLabel, this.koLabel, this.onTap);
}
