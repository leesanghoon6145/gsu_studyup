// ============================================================================
// 🆕 [일반 플래너 - 병기+연동 정리] DailyReportScreen
// 오늘의 완료율(캘린더+타임라인 실데이터), 분류별 실제 사용 시간, 어제 대비
// 변화, 오늘 달성한 목표 개수를 보여줍니다. 전부 실제 저장된 데이터로만
// 계산되며, 기록이 없으면 가짜 숫자 대신 빈 상태 안내를 보여줍니다.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'report_data_service.dart';
import 'bilingual_text.dart';

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  ReportSummary? _today;
  ReportSummary? _yesterday;
  int _achievedGoalCount = 0;
  int _completedProjectCount = 0; // 🆕 [프로젝트 연동]
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    final today = await ReportDataService.summarize(now, now);
    final yesterdaySummary = await ReportDataService.summarize(yesterday, yesterday);
    final projectCount = await ReportDataService.countProjectsCompletedInRange(now, now);
    final achievedCount = await ReportDataService.countAchievementsInRange(now, now);

    if (!mounted) return;
    setState(() {
      _today = today;
      _yesterday = yesterdaySummary;
      _achievedGoalCount = achievedCount;
      _completedProjectCount = projectCount;
      _isLoading = false;
    });
  }

  String get _oneLineCommentEn {
    final today = _today!;
    if (!today.hasData) return '';
    String comment = "You've completed ${today.completionPercent}% of today's plan.";
    if (_yesterday != null && _yesterday!.hasData) {
      final diff = today.completionPercent - _yesterday!.completionPercent;
      if (diff > 0) {
        comment += '\nUp ${diff}%p from yesterday.';
      } else if (diff < 0) {
        comment += '\nDown ${diff.abs()}%p from yesterday.';
      } else {
        comment += '\nSame as yesterday.';
      }
    }
    return comment;
  }

  String get _oneLineCommentKo {
    final today = _today!;
    if (!today.hasData) return '';
    String comment = '오늘의 목표를 ${today.completionPercent}% 달성했습니다.';
    if (_yesterday != null && _yesterday!.hasData) {
      final diff = today.completionPercent - _yesterday!.completionPercent;
      if (diff > 0) {
        comment += '\n어제보다 $diff%p 향상되었습니다.';
      } else if (diff < 0) {
        comment += '\n어제보다 ${diff.abs()}%p 낮아졌습니다.';
      } else {
        comment += '\n어제와 동일한 완료율입니다.';
      }
    }
    return comment;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final String todayDisplay = '${now.month}/${now.day} (${weekdayNames[now.weekday - 1]})';

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: const BiTitle(en: 'DAILY REPORT', ko: '일간 리포트', enSize: 16, koSize: 13),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : (_today == null || !_today!.hasData)
          ? Center(child: BiInline(en: 'No schedule or timeline records for today.\nAdd and complete some to see your report.', ko: '오늘 등록된 일정이나 타임라인이 없습니다.\n일정을 추가하고 완료해 보세요.', color: Colors.white38, fontSize: 13, textAlign: TextAlign.center))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(todayDisplay, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildCompletionCard(),
          const SizedBox(height: 16),
          _buildGoalAchievedCard(),
          const SizedBox(height: 16),
          _buildProjectCompletedCard(),
          const SizedBox(height: 16),
          _buildCategoryCard(),
          const SizedBox(height: 16),
          _buildCommentCard(),
        ],
      ),
    );
  }

  Widget _buildCompletionCard() {
    final today = _today!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BiInline(en: "Today's Completion", ko: '오늘의 완료율', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
          const SizedBox(height: 8),
          Text('${today.completionPercent}%', style: GoogleFonts.rajdhani(color: _brandGolden, fontSize: 36, fontWeight: FontWeight.bold)),
          BiInline(en: 'Completed ${today.completedCount} · Pending ${today.totalCount - today.completedCount}', ko: '완료 ${today.completedCount}건 · 미완료 ${today.totalCount - today.completedCount}건', color: Colors.white38, fontSize: 12),
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
          const Expanded(child: BiInline(en: 'Goals Achieved Today', ko: '오늘 달성한 목표', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
          Text('$_achievedGoalCount', style: const TextStyle(color: _brandGolden, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 🆕 [프로젝트 연동] 오늘 완료된 프로젝트 개수
  Widget _buildProjectCompletedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Row(
        children: [
          const Icon(Icons.rocket_launch_rounded, color: _brandGolden, size: 22),
          const SizedBox(width: 12),
          const Expanded(child: BiInline(en: 'Projects Completed Today', ko: '오늘 완료된 프로젝트', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
          Text('$_completedProjectCount', style: const TextStyle(color: _brandGolden, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard() {
    final categoryMinutes = _today!.categoryMinutes;
    final int total = _today!.totalMinutes;
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
              final String timeText = hours > 0 ? '${hours}h ${mins}m (${hours}시간 ${mins}분)' : '${mins}m (${mins}분)';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 13))),
                    Text(timeText, style: const TextStyle(color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          if (total > 0) ...[
            const Divider(color: Colors.white12, height: 20),
            BiInline(en: 'Total: ${total ~/ 60}h ${total % 60}m', ko: '총 사용 시간: ${total ~/ 60}시간 ${total % 60}분', color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _brandGolden.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.5))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: _brandGolden, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_oneLineCommentEn, style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold, height: 1.5)),
                const SizedBox(height: 4),
                Text(_oneLineCommentKo, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
