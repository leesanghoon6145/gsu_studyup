// ============================================================================
// 🆕 [일반 플래너 4단계] YearlyReportScreen
// 올해의 목표 달성률, 총 일정 완료 수, 가장 생산적인 달, 가장 활동적인 요일을
// 보여줍니다. 아직 사용 기간이 짧아 1년치 데이터가 없더라도, 지금까지 쌓인
// 실제 데이터만으로 정직하게 계산합니다 (데이터 없으면 "데이터 없음").
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'report_data_service.dart';

class YearlyReportScreen extends StatefulWidget {
  const YearlyReportScreen({super.key});

  @override
  State<YearlyReportScreen> createState() => _YearlyReportScreenState();
}

class _YearlyReportScreenState extends State<YearlyReportScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  ReportSummary? _summary;
  int? _mostProductiveMonth;
  String? _mostActiveWeekday;
  late DateTime _yearStart;
  late DateTime _yearEnd;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _yearStart = DateTime(now.year, 1, 1);
    _yearEnd = DateTime(now.year, 12, 31);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final summary = await ReportDataService.summarize(_yearStart, _yearEnd);
    final month = await ReportDataService.findMostProductiveMonth(_yearStart.year);
    final weekday = await ReportDataService.findMostActiveWeekdayOverall(_yearStart, _yearEnd);

    if (!mounted) return;
    setState(() {
      _summary = summary;
      _mostProductiveMonth = month;
      _mostActiveWeekday = weekday;
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
            Text('YEARLY REPORT', style: GoogleFonts.gowunBatang(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('연간 리포트', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : (_summary == null || !_summary!.hasData)
          ? Center(
        child: Text('올해 등록된 기록이 없습니다.',
            textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 14)),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${_yearStart.year}년', style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildCompletionCard(),
          const SizedBox(height: 16),
          _buildInsightCard(),
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
          Text('올해 목표 달성률', style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${s.completionPercent}%', style: GoogleFonts.rajdhani(color: _brandGolden, fontSize: 36, fontWeight: FontWeight.bold)),
          Text('총 일정 ${s.totalCount}개 · 완료 ${s.completedCount}개', style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInsightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow('가장 생산적인 달', _mostProductiveMonth != null ? '${_mostProductiveMonth}월' : '데이터 없음'),
          const SizedBox(height: 10),
          _buildRow('가장 많이 활동한 요일', _mostActiveWeekday != null ? '$_mostActiveWeekday요일' : '데이터 없음'),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13)),
        Text(value, style: const TextStyle(color: _brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
