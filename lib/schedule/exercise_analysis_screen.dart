// exercise_analysis_screen.dart
//
// [운동 > 분석] 화면. exercise_data_service.dart의 전체 기록을 읽어와
// fl_chart로 시각화한다 (pubspec.yaml에 이미 등록된 fl_chart 재사용).
//
// 구성:
// 1) 요약 카드 3개 - 총 세션 수 / 총 운동시간 / 평균 RPE
// 2) 최근 7일 운동시간 막대그래프
// 3) 최근 14일 RPE 추이 라인그래프
// 4) 종목별 비중 (세션 수 기준 랭킹 바)

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'exercise_models.dart';
import 'exercise_data_service.dart';
import 'exercise_theme.dart';

class ExerciseAnalysisScreen extends StatefulWidget {
  const ExerciseAnalysisScreen({super.key});

  @override
  State<ExerciseAnalysisScreen> createState() => _ExerciseAnalysisScreenState();
}

class _ExerciseAnalysisScreenState extends State<ExerciseAnalysisScreen> {
  bool _loading = true;
  List<ExerciseRecord> _records = [];
  Map<String, ExerciseType> _typesById = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final types = await ExerciseDataService.instance.getExerciseTypes(includeHidden: true);
    final records = await ExerciseDataService.instance.getAllRecords();
    if (!mounted) return;
    setState(() {
      _typesById = {for (final t in types) t.id: t};
      _records = records;
      _loading = false;
    });
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExerciseTheme.pageBg,
      appBar: ExerciseTheme.biAppBar(
        en: 'EXERCISE ANALYSIS',
        ko: '운동 분석',
        translations: const {
          'JA': '運動分析', 'ZH': '运动分析', 'FR': 'Analyse des exercices', 'DE': 'Sportanalyse',
          'RU': 'Анализ упражнений', 'AR': 'تحليل التمارين', 'HI': 'व्यायाम विश्लेषण',
          'VI': 'Phân tích tập luyện', 'ES': 'Análisis de ejercicio', 'TH': 'วิเคราะห์การออกกำลังกาย',
        },
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ExerciseTheme.brandGolden))
          : _records.isEmpty
          ? Center(
        child: BiInline(
          en: 'No exercise records yet',
          ko: '아직 운동 기록이 없습니다',
          color: Colors.white38,
          fontSize: 14,
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryRow(),
          const SizedBox(height: 20),
          _buildSectionTitle('LAST 7 DAYS', '최근 7일 운동시간'),
          const SizedBox(height: 12),
          _buildWeeklyDurationChart(),
          const SizedBox(height: 24),
          _buildSectionTitle('RPE TREND (14 DAYS)', '최근 14일 RPE 추이'),
          const SizedBox(height: 12),
          _buildRpeTrendChart(),
          const SizedBox(height: 24),
          _buildSectionTitle('BY EXERCISE TYPE', '종목별 비중'),
          const SizedBox(height: 12),
          _buildTypeBreakdown(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String en, String ko) {
    return BiInline(en: en, ko: ko, color: ExerciseTheme.goldenLight, fontWeight: FontWeight.bold, fontSize: 14.5);
  }

  Widget _buildSummaryRow() {
    final totalSessions = _records.length;
    final totalMinutes = _records.fold<int>(0, (sum, r) => sum + r.durationMin);
    final rpeValues = _records.where((r) => r.rpe != null).map((r) => r.rpe!).toList();
    final avgRpe = rpeValues.isEmpty ? 0.0 : rpeValues.reduce((a, b) => a + b) / rpeValues.length;

    return Row(
      children: [
        Expanded(child: _summaryCard('SESSIONS', '세션', '$totalSessions')),
        const SizedBox(width: 10),
        Expanded(child: _summaryCard('MINUTES', '총 시간(분)', '$totalMinutes')),
        const SizedBox(width: 10),
        Expanded(child: _summaryCard('AVG RPE', '평균 강도', avgRpe.toStringAsFixed(1))),
      ],
    );
  }

  Widget _summaryCard(String en, String ko, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: ExerciseTheme.luxeCardDecoration(),
      child: Column(
        children: [
          Text(value, style: ExerciseTheme.titleStyle(size: 22)),
          const SizedBox(height: 6),
          BiInline(en: en, ko: ko, color: Colors.white54, fontSize: 10.5),
        ],
      ),
    );
  }

  Widget _buildWeeklyDurationChart() {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final values = days.map((d) {
      final key = _dateKey(d);
      return _records
          .where((r) => _dateKey(r.date) == key)
          .fold<int>(0, (sum, r) => sum + r.durationMin);
    }).toList();
    final maxVal = values.isEmpty ? 60.0 : (values.reduce((a, b) => a > b ? a : b) * 1.2).clamp(30, 1000000).toDouble();

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: ExerciseTheme.luxeCardDecoration(),
      child: BarChart(
        BarChartData(
          maxY: maxVal,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                  const weekday = ['월', '화', '수', '목', '금', '토', '일'];
                  final d = days[idx];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      weekday[d.weekday - 1],
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(values.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  color: ExerciseTheme.brandGolden,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildRpeTrendChart() {
    final now = DateTime.now();
    final days = List.generate(14, (i) => now.subtract(Duration(days: 13 - i)));
    final spots = <FlSpot>[];
    for (var i = 0; i < days.length; i++) {
      final key = _dateKey(days[i]);
      final dayRecords = _records.where((r) => _dateKey(r.date) == key && r.rpe != null).toList();
      if (dayRecords.isNotEmpty) {
        final avg = dayRecords.map((r) => r.rpe!).reduce((a, b) => a + b) / dayRecords.length;
        spots.add(FlSpot(i.toDouble(), avg));
      }
    }

    if (spots.isEmpty) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: ExerciseTheme.luxeCardDecoration(),
        child: BiInline(en: 'No RPE data yet', ko: '아직 RPE 데이터가 없습니다', color: Colors.white38, fontSize: 12.5),
      );
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 12, 8),
      decoration: ExerciseTheme.luxeCardDecoration(),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 10,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withOpacity(0.06), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2,
                reservedSize: 24,
                getTitlesWidget: (value, meta) =>
                    Text(value.toInt().toString(), style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: ExerciseTheme.brandGolden,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: ExerciseTheme.brandGolden.withOpacity(0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBreakdown() {
    final Map<String, int> countByType = {};
    for (final r in _records) {
      countByType[r.exerciseTypeId] = (countByType[r.exerciseTypeId] ?? 0) + 1;
    }
    final sorted = countByType.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = sorted.isEmpty ? 1 : sorted.first.value;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: ExerciseTheme.luxeCardDecoration(),
      child: Column(
        children: sorted.map((entry) {
          final type = _typesById[entry.key];
          final ratio = entry.value / maxCount;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(ExerciseTheme.iconForType(entry.key), color: ExerciseTheme.brandGolden, size: 18),
                const SizedBox(width: 10),
                SizedBox(
                  width: 64,
                  child: Text(
                    type?.name ?? entry.key,
                    style: ExerciseTheme.bodyStyle(color: Colors.white, size: 12.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 10,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(ExerciseTheme.brandGolden),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${entry.value}', style: ExerciseTheme.titleStyle(size: 13)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
