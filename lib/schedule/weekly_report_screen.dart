// ============================================================================
// 🆕 [일반 플래너 - 병기+연동 정리] WeeklyReportScreen
// 이번 주(월~일)의 완료율, 가장 바쁜 요일, 가장 생산적인 시간대, 이번 주
// 달성한 목표 개수를 보여줍니다. 전부 실제 캘린더/타임라인/목표 데이터
// 기준으로 계산됩니다.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'report_data_service.dart';
import 'bilingual_text.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  ReportSummary? _summary;
  String? _busiestWeekday;
  String? _productiveHourRange;
  int _achievedGoalCount = 0;
  int _completedProjectCount = 0; // 🆕 [프로젝트 연동]
  late DateTime _weekStart;
  late DateTime _weekEnd;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
    _weekEnd = _weekStart.add(const Duration(days: 6));
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final summary = await ReportDataService.summarize(_weekStart, _weekEnd);
    final busiest = await ReportDataService.findBusiestWeekday(_weekStart, _weekEnd);
    final productive = await ReportDataService.findMostProductiveHourRange(_weekStart, _weekEnd);
    final projectCount = await ReportDataService.countProjectsCompletedInRange(_weekStart, _weekEnd);
    final achievedCount = await ReportDataService.countAchievementsInRange(_weekStart, _weekEnd);

    if (!mounted) return;
    setState(() {
      _summary = summary;
      _busiestWeekday = busiest;
      _productiveHourRange = productive;
      _achievedGoalCount = achievedCount;
      _completedProjectCount = projectCount;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String rangeText = '${_weekStart.month}/${_weekStart.day} ~ ${_weekEnd.month}/${_weekEnd.day}';

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: const BiTitle(en: 'WEEKLY REPORT', ko: '주간 리포트', enSize: 16, koSize: 13),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : (_summary == null || !_summary!.hasData)
          ? Center(child: BiInline(en: 'No records for this week yet.', ko: '이번 주 등록된 기록이 없습니다.', color: Colors.white38, fontSize: 14, textAlign: TextAlign.center))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(rangeText, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildCompletionCard(),
          const SizedBox(height: 16),
          _buildGoalAchievedCard(),
          const SizedBox(height: 16),
          _buildProjectCompletedCard(),
          const SizedBox(height: 16),
          _buildInsightCard(),
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
          const BiInline(en: 'Weekly Completion', ko: '주간 달성률', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
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
          const Expanded(child: BiInline(en: 'Goals Achieved This Week', ko: '이번 주 달성한 목표', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
          Text('$_achievedGoalCount', style: const TextStyle(color: _brandGolden, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 🆕 [프로젝트 연동] 이번 주 완료된 프로젝트 개수
  Widget _buildProjectCompletedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Row(
        children: [
          const Icon(Icons.rocket_launch_rounded, color: _brandGolden, size: 22),
          const SizedBox(width: 12),
          const Expanded(child: BiInline(en: 'Projects Completed This Week', ko: '이번 주 완료된 프로젝트', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
          Text('$_completedProjectCount', style: const TextStyle(color: _brandGolden, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInsightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInsightRow('Busiest Weekday', '가장 바쁜 요일', _busiestWeekday != null ? '$_busiestWeekday요일' : '데이터 없음'),
          const SizedBox(height: 10),
          _buildInsightRow('Most Productive Time', '가장 생산적인 시간', _productiveHourRange ?? '데이터 없음'),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String en, String ko, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: BiInline(en: en, ko: ko, color: Colors.white70, fontSize: 13)),
        Text(value, style: const TextStyle(color: _brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCategoryCard() {
    final categoryMinutes = _summary!.categoryMinutes;
    final entries = categoryMinutes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

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
        ],
      ),
    );
  }
}
