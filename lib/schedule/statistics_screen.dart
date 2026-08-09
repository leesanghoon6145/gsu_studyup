// ============================================================================
// 🆕 [일반 플래너 4단계] StatisticsScreen
// 전체 기간 누적 분류별 시간 비중과, 올해 1~12월 완료율 막대그래프를
// 보여줍니다. 기록이 없는 달은 회색 "데이터 없음" 막대로 구분해서 표시하고,
// 0%처럼 보이는 가짜 값을 만들지 않습니다.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'report_data_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  static const List<Color> _categoryColors = [
    Color(0xFFE5C158),
    Color(0xFF60A5FA),
    Color(0xFF34D399),
    Color(0xFFF87171),
    Color(0xFFA78BFA),
    Color(0xFFFBBF24),
  ];

  ReportSummary? _allTimeSummary;
  Map<int, int> _monthlyRates = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    // 전체 기간 집계를 위해 넉넉히 5년 전부터 오늘까지로 범위를 잡음
    final summary = await ReportDataService.summarize(DateTime(now.year - 5, 1, 1), now);
    final monthly = await ReportDataService.calcMonthlyCompletionRates(now.year);

    if (!mounted) return;
    setState(() {
      _allTimeSummary = summary;
      _monthlyRates = monthly;
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
            Text('STATISTICS', style: GoogleFonts.gowunBatang(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('통계', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCategoryBreakdownCard(),
          const SizedBox(height: 16),
          _buildMonthlyBarChartCard(),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownCard() {
    final categoryMinutes = _allTimeSummary?.categoryMinutes ?? {};
    final int total = categoryMinutes.values.fold(0, (a, b) => a + b);
    final entries = categoryMinutes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('시간 사용 비율 (전체 기간)', style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          if (total == 0)
            Text('아직 완료된 타임라인 기록이 없습니다.', style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12))
          else ...[
            // 가로 누적 막대 (원형 그래프 대신, 실제 개발 시간을 절약할 수 있는 누적 바 형태로 표현)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 24,
                child: Row(
                  children: List.generate(entries.length, (i) {
                    final e = entries[i];
                    final double flexValue = e.value / total;
                    return Expanded(
                      flex: (flexValue * 1000).round().clamp(1, 1000),
                      child: Container(color: _categoryColors[i % _categoryColors.length]),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...List.generate(entries.length, (i) {
              final e = entries[i];
              final int pct = ((e.value / total) * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: _categoryColors[i % _categoryColors.length], shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 13))),
                    Text('$pct%', style: const TextStyle(color: _brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyBarChartCard() {
    final now = DateTime.now();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${now.year}년 월별 목표 달성률', style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...List.generate(12, (i) {
            final int month = i + 1;
            final int rate = _monthlyRates[month] ?? -1;
            final bool hasData = rate >= 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(width: 32, child: Text('${month}월', style: const TextStyle(color: Colors.white70, fontSize: 12))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: hasData ? rate / 100 : 0,
                        minHeight: 14,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(hasData ? _brandGolden : Colors.white24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 60,
                    child: Text(
                      hasData ? '$rate%' : '데이터없음',
                      style: TextStyle(color: hasData ? _brandGolden : Colors.white24, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
