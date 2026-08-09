// ============================================================================
// 🆕 [일반 플래너 4단계] MonthlyReportScreen
// 이번 달의 완료율, 루틴 성공률, 분류별 시간 사용을 보여줍니다.
// 데이터가 없는 항목(예: 루틴을 아직 안 쓴 경우)은 가짜 %가 아니라
// "데이터 없음"으로 구분해서 표시합니다.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'report_data_service.dart';

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

    if (!mounted) return;
    setState(() {
      _summary = summary;
      _routineSuccessRate = routineRate;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('MONTHLY REPORT', style: GoogleFonts.gowunBatang(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('월간 리포트', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : (_summary == null || !_summary!.hasData)
          ? Center(
        child: Text('이번 달 등록된 기록이 없습니다.',
            textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 14)),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${_monthStart.year}년 ${_monthStart.month}월', style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildCompletionCard(),
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
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('목표 달성률', style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${s.completionPercent}%', style: GoogleFonts.rajdhani(color: _brandGolden, fontSize: 36, fontWeight: FontWeight.bold)),
          Text('일정 완료 ${s.completedCount}건 / 전체 ${s.totalCount}건', style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRoutineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('루틴 성공률', style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          Text(
            _routineSuccessRate != null ? '$_routineSuccessRate%' : '데이터 없음',
            style: const TextStyle(color: _brandGolden, fontSize: 15, fontWeight: FontWeight.bold),
          ),
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
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 13))),
                    Text('${hours}시간 ${mins}분', style: const TextStyle(color: _brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          if (totalMinutes > 0) ...[
            const Divider(color: Colors.white12, height: 20),
            Text('총 자기계발/활동 시간: ${totalMinutes ~/ 60}시간 ${totalMinutes % 60}분',
                style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }
}
