// ============================================================================
// 🆕 [일반 플래너 2단계] TimelineAnalysisScreen
// 실제로 완료(completed)된 타임라인 블록만 근거로 통계를 계산합니다.
// 데이터가 없으면 가짜 숫자로 채우지 않고 "아직 분석할 데이터가 없다"는
// 안내만 보여줍니다 (ai_consulting_room_screen.dart에서 발견됐던 문제를
// 반복하지 않기 위한 원칙 적용).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'timeline_data_service.dart';

class TimelineAnalysisScreen extends StatefulWidget {
  const TimelineAnalysisScreen({super.key});

  @override
  State<TimelineAnalysisScreen> createState() => _TimelineAnalysisScreenState();
}

class _TimelineAnalysisScreenState extends State<TimelineAnalysisScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  List<TimelineBlock> _allBlocks = [];
  List<TimelineBlock> _completedBlocks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final all = await TimelineDataService.loadAllBlocks();
    final completed = all.where((b) => b.status == 'completed').toList();
    if (!mounted) return;
    setState(() {
      _allBlocks = all;
      _completedBlocks = completed;
      _isLoading = false;
    });
  }

  // 🆕 전체 완료율 (전체 블록 중 완료된 비율)
  double get _overallCompletionRate {
    if (_allBlocks.isEmpty) return 0;
    return _completedBlocks.length / _allBlocks.length;
  }

  // 🆕 분류(category)별 실제 소요시간 총합(분) - 완료된 블록만 집계
  Map<String, int> get _categoryMinutes {
    final Map<String, int> result = {};
    for (final block in _completedBlocks) {
      final int? minutes = block.actualMinutes;
      if (minutes == null) continue;
      result[block.category] = (result[block.category] ?? 0) + minutes;
    }
    return result;
  }

  // 🆕 평균 시간 차이(분) - 완료된 블록들의 diffMinutes 평균 (계획보다 얼마나 늦거나 빨랐는지)
  double? get _averageDiffMinutes {
    final diffs = _completedBlocks.map((b) => b.diffMinutes).whereType<int>().toList();
    if (diffs.isEmpty) return null;
    return diffs.reduce((a, b) => a + b) / diffs.length;
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
            Text('TIMELINE ANALYSIS', style: GoogleFonts.gowunBatang(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('타임라인 분석', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : _completedBlocks.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '아직 분석할 데이터가 없습니다.\n타임라인을 실행하고 완료할수록\n더 정확한 분석을 볼 수 있습니다.',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 14),
          ),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOverallCard(),
          const SizedBox(height: 16),
          _buildCategoryCard(),
          const SizedBox(height: 16),
          _buildDiffCard(),
        ],
      ),
    );
  }

  Widget _buildOverallCard() {
    final int percent = (_overallCompletionRate * 100).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('전체 완료율', style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('$percent%', style: GoogleFonts.rajdhani(color: _brandGolden, fontSize: 36, fontWeight: FontWeight.bold)),
          Text('완료 ${_completedBlocks.length} / 전체 ${_allBlocks.length}건', style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard() {
    final categoryMinutes = _categoryMinutes;
    final int total = categoryMinutes.values.fold(0, (a, b) => a + b);
    final entries = categoryMinutes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('분류별 실제 사용 시간', style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (total == 0)
            Text('데이터 없음', style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12))
          else
            ...entries.map((e) {
              final int pct = total == 0 ? 0 : ((e.value / total) * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        Text('${e.value}분 ($pct%)', style: const TextStyle(color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : e.value / total,
                        minHeight: 8,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(_brandGolden),
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

  Widget _buildDiffCard() {
    final double? avgDiff = _averageDiffMinutes;
    String summaryText;
    Color summaryColor;

    if (avgDiff == null) {
      summaryText = '데이터 없음';
      summaryColor = Colors.white38;
    } else if (avgDiff.abs() < 1) {
      summaryText = '평균적으로 계획한 시간과 정확히 맞춰 실행하고 있습니다.';
      summaryColor = Colors.white70;
    } else if (avgDiff > 0) {
      summaryText = '평균적으로 계획보다 ${avgDiff.round()}분 더 오래 걸리고 있습니다.';
      summaryColor = Colors.orangeAccent;
    } else {
      summaryText = '평균적으로 계획보다 ${avgDiff.abs().round()}분 더 빠르게 마치고 있습니다.';
      summaryColor = Colors.lightGreenAccent;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('계획 대비 실행 경향', style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(summaryText, style: GoogleFonts.notoSansKr(color: summaryColor, fontSize: 14, fontWeight: FontWeight.bold, height: 1.5)),
        ],
      ),
    );
  }
}
