// ============================================================================
// 🆕 [일반 플래너] ScheduleAnalysisScreen (일정분석)
// 캘린더/오늘의 일정에 저장된 실제 ScheduleItem 데이터를 분석합니다.
// 전체 완료율, 카테고리별(중요/회사/개인) 분포, 다가오는 미완료 일정 개수,
// 가장 일정이 많은 요일을 계산합니다. 전부 실제 데이터 기반이며, 데이터가
// 없으면 가짜 숫자 대신 "데이터 없음"으로 표시합니다.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'schedule_data_service.dart';
import 'calendar_screen.dart' show categoryColorOf, kScheduleCategories; // 🆕 캘린더와 동일한 카테고리 색상 재사용
import 'bilingual_text.dart';

class ScheduleAnalysisScreen extends StatefulWidget {
  const ScheduleAnalysisScreen({super.key});

  @override
  State<ScheduleAnalysisScreen> createState() => _ScheduleAnalysisScreenState();
}

class _ScheduleAnalysisScreenState extends State<ScheduleAnalysisScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  List<ScheduleItem> _all = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final all = await ScheduleDataService.loadAll();
    if (!mounted) return;
    setState(() {
      _all = all;
      _isLoading = false;
    });
  }

  int get _completedCount => _all.where((e) => e.isCompleted).length;
  double get _completionRate => _all.isEmpty ? 0 : _completedCount / _all.length;

  Map<String, int> get _categoryCounts {
    final Map<String, int> result = {};
    for (final item in _all) {
      result[item.category] = (result[item.category] ?? 0) + 1;
    }
    return result;
  }

  int get _upcomingIncompleteCount {
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return _all.where((e) => !e.isCompleted && e.date.compareTo(todayKey) >= 0).length;
  }

  String? get _busiestWeekday {
    if (_all.isEmpty) return null;
    const weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final Map<int, int> countByWeekday = {};
    for (final item in _all) {
      final parts = item.date.split('-');
      if (parts.length != 3) continue;
      try {
        final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        countByWeekday[date.weekday] = (countByWeekday[date.weekday] ?? 0) + 1;
      } catch (e) {
        continue;
      }
    }
    if (countByWeekday.isEmpty) return null;
    final busiest = countByWeekday.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return weekdayNames[busiest.key - 1];
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
        title: const BiTitle(en: 'SCHEDULE ANALYSIS', ko: '일정 분석', enSize: 17, koSize: 13),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : _all.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BiInline(en: 'No schedule data yet', ko: '아직 분석할 일정 데이터가 없습니다', color: Colors.white38, fontSize: 14, textAlign: TextAlign.center),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOverallCard(),
          const SizedBox(height: 16),
          _buildCategoryCard(),
          const SizedBox(height: 16),
          _buildInsightCard(),
        ],
      ),
    );
  }

  Widget _buildOverallCard() {
    final int percent = (_completionRate * 100).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BiInline(en: 'Overall Completion', ko: '전체 완료율', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
          const SizedBox(height: 8),
          Text('$percent%', style: GoogleFonts.rajdhani(color: _brandGolden, fontSize: 36, fontWeight: FontWeight.bold)),
          BiInline(en: 'Completed $_completedCount / Total ${_all.length}', ko: '완료 $_completedCount건 / 전체 ${_all.length}건', color: Colors.white38, fontSize: 12),
        ],
      ),
    );
  }

  Widget _buildCategoryCard() {
    final counts = _categoryCounts;
    final int total = counts.values.fold(0, (a, b) => a + b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BiInline(en: 'By Category', ko: '분류별 비중', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
          const SizedBox(height: 14),
          if (total == 0)
            BiInline(en: 'No data', ko: '데이터 없음', color: Colors.white38, fontSize: 12)
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 22,
                child: Row(
                  children: counts.entries.map((e) {
                    final double flexValue = e.value / total;
                    return Expanded(
                      flex: (flexValue * 1000).round().clamp(1, 1000),
                      child: Container(color: categoryColorOf(e.key)),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...counts.entries.map((e) {
              final int pct = ((e.value / total) * 100).round();
              final matched = kScheduleCategories.where((c) => c.koLabel == e.key).toList();
              final String enName = matched.isNotEmpty ? matched.first.enLabel : 'Other';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: categoryColorOf(e.key), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Expanded(child: BiInline(en: enName, ko: e.key, color: Colors.white, fontSize: 13)),
                    Text('${e.value}건 ($pct%)', style: const TextStyle(color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ],
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
          _buildInsightRow('Upcoming Incomplete', '다가오는 미완료 일정', '$_upcomingIncompleteCount건'),
          const SizedBox(height: 10),
          _buildInsightRow('Busiest Weekday', '가장 일정이 많은 요일', _busiestWeekday != null ? '$_busiestWeekday요일' : '데이터 없음'),
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
}
