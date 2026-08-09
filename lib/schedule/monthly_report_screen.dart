// ============================================================================
// 🆕 [일반 플래너 - 병기+연동 정리] MonthlyReportScreen
// 이번 달의 완료율, 루틴 성공률, 분류별 시간 사용, 이번 달 달성한 목표
// 개수를 보여줍니다. 데이터가 없는 항목(예: 루틴을 아직 안 쓴 경우)은
// 가짜 %가 아니라 "데이터 없음"으로 구분해서 표시합니다.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'report_data_service.dart';
import 'bilingual_text.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  ReportSummary? _summary;
  int? _routineSuccessRate;
  int _achievedGoalCount = 0;
  int _completedProjectCount = 0; // 🆕 [프로젝트 연동]
  late DateTime _monthStart;
  late DateTime _monthEnd;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthStart = DateTime(now.year, now.month, 1);
    _monthEnd = DateTime(now.year, now.month + 1, 0);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final summary = await ReportDataService.summarize(_monthStart, _monthEnd);
    final routineRate = await ReportDataService.calcRoutineSuccessRate(_monthStart, _monthEnd);
    final projectCount = await ReportDataService.countProjectsCompletedInRange(_monthStart, _monthEnd);
    final achievedCount = await ReportDataService.countAchievementsInRange(_monthStart, _monthEnd);

    if (!mounted) return;
    setState(() {
      _summary = summary;
      _routineSuccessRate = routineRate;
      _achievedGoalCount = achievedCount;
      _completedProjectCount = projectCount;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: const BiTitle(en: 'MONTHLY REPORT', ko: '월간 리포트', enSize: 16, koSize: 13),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : (_summary == null || !_summary!.hasData)
          ? Center(child: BiInline(en: 'No records for this month yet.', ko: '이번 달 등록된 기록이 없습니다.', color: Colors.white38, fontSize: 14, textAlign: TextAlign.center))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${_monthStart.year}.${_monthStart.month.toString().padLeft(2, '0')}', style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildCompletionCard(),
          const SizedBox(height: 16),
          _buildGoalAchievedCard(),
          const SizedBox(height: 16),
          _buildProjectCompletedCard(),
          const SizedBox(height: 16),
          _buildRoutineCard(),
          const SizedBox(height: 16),
          _buildCategoryCard(),
        ],
      ),
    );
  }

  Widget _buildCompletionCard() {
    final s = _summary!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BiInline(en: 'Monthly Completion', ko: '목표 달성률', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
          const SizedBox(height: 8),
          Text('${s.completionPercent}%', style: GoogleFonts.rajdhani(color: _brandGolden, fontSize: 36, fontWeight: FontWeight.bold)),
          BiInline(en: 'Completed ${s.completedCount} / Total ${s.totalCount}', ko: '완료 ${s.completedCount}건 / 전체 ${s.totalCount}건', color: Colors.white38, fontSize: 12),
        ],
      ),
    );
  }

  Widget _buildGoalAchievedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: _brandGolden, size: 22),
          const SizedBox(width: 12),
          const Expanded(child: BiInline(en: 'Goals Achieved This Month', ko: '이번 달 달성한 목표', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
          Text('$_achievedGoalCount', style: const TextStyle(color: _brandGolden, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 🆕 [프로젝트 연동] 이번 달 완료된 프로젝트 개수
  Widget _buildProjectCompletedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Row(
        children: [
          const Icon(Icons.rocket_launch_rounded, color: _brandGolden, size: 22),
          const SizedBox(width: 12),
          const Expanded(child: BiInline(en: 'Projects Completed This Month', ko: '이번 달 완료된 프로젝트', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
          Text('$_completedProjectCount', style: const TextStyle(color: _brandGolden, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRoutineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const BiInline(en: 'Routine Success Rate', ko: '루틴 성공률', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
          Text(_routineSuccessRate != null ? '$_routineSuccessRate%' : '-', style: const TextStyle(color: _brandGolden, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard() {
    final categoryMinutes = _summary!.categoryMinutes;
    final entries = categoryMinutes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final int totalMinutes = _summary!.totalMinutes;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BiInline(en: 'Time by Category', ko: '분류별 시간 사용', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const BiInline(en: 'No completed timeline items yet.', ko: '완료된 타임라인 항목이 없습니다.', color: Colors.white38, fontSize: 12)
          else
            ...entries.map((e) {
              final int hours = e.value ~/ 60;
              final int mins = e.value % 60;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 13))),
                    Text('${hours}h ${mins}m (${hours}시간 ${mins}분)', style: const TextStyle(color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          if (totalMinutes > 0) ...[
            const Divider(color: Colors.white12, height: 20),
            BiInline(en: 'Total: ${totalMinutes ~/ 60}h ${totalMinutes % 60}m', ko: '총 자기계발/활동 시간: ${totalMinutes ~/ 60}시간 ${totalMinutes % 60}분', color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
          ],
        ],
      ),
    );
  }
}
