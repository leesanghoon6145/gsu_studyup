// ============================================================================
// 🆕 [일반 플래너 4단계] DailyReportScreen
// 오늘의 완료율, 분류별 실제 사용 시간, 어제 대비 변화를 보여줍니다.
// 오늘/어제 데이터가 모두 실제 기록에서 계산되며, 오늘 기록이 없으면
// 가짜 숫자 대신 빈 상태 안내를 보여줍니다.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'report_data_service.dart';

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

    if (!mounted) return;
    setState(() {
      _today = today;
      _yesterday = yesterdaySummary;
      _isLoading = false;
    });
  }

  String get _oneLineComment {
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
    final String todayDisplay = '${now.month}월 ${now.day}일 (${weekdayNames[now.weekday - 1]})';

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('DAILY REPORT', style: GoogleFonts.gowunBatang(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('일간 리포트', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : (_today == null || !_today!.hasData)
          ? Center(
        child: Text('오늘 등록된 일정이나 타임라인이 없습니다.\n일정을 추가하고 실행해보세요.',
            textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 14)),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(todayDisplay, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildCompletionCard(),
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
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('오늘의 완료율', style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${today.completionPercent}%', style: GoogleFonts.rajdhani(color: _brandGolden, fontSize: 36, fontWeight: FontWeight.bold)),
          Text('완료 ${today.completedCount}건 · 미완료 ${today.totalCount - today.completedCount}건',
              style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12)),
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
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('분류별 시간 사용', style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text('완료된 타임라인 항목이 없습니다.', style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12))
          else
            ...entries.map((e) {
              final int hours = e.value ~/ 60;
              final int mins = e.value % 60;
              final String timeText = hours > 0 ? '${hours}시간 ${mins}분' : '${mins}분';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 13))),
                    Text(timeText, style: const TextStyle(color: _brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          if (total > 0) ...[
            const Divider(color: Colors.white12, height: 20),
            Text('총 사용 시간: ${total ~/ 60}시간 ${total % 60}분', style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _brandGolden.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.4))),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: _brandGolden, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_oneLineComment, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
