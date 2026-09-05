// exercise_analysis_screen.dart (전면 개편)
//
// [운동 > 분석] 화면. exercise_data_service.dart의 전체 기록을 읽어와
// fl_chart로 시각화한다 (pubspec.yaml에 이미 등록된 fl_chart 재사용).
//
// 구성:
// 1) 요약 카드 3개 - 총 세션 수 / 총 운동시간 / 평균 RPE
// 2) 최근 7일 운동시간 막대그래프 (월~일 빨주노초파남보 순서 고정색)
// 3) 최근 14일 RPE 추이 라인그래프
// 4) 종목별 비중 (세션 수 기준 랭킹 바, 지정 색상 순서)
// 5) 종목별 운동시간 비율 도넛차트 + 범례
//
// ✅ [2026-09-05 전면 개편]
// - 모든 카드 테두리를 진하게(highlighted) 통일
// - 모든 영문 라벨을 BiInline(영문 명조체+한글 노토산스 병기)으로 통일
// - 막대그래프를 요일별 고정 무지개색으로, Y축엔 시간 단위+구분점, X축엔
//   요일명을 참고 이미지와 동일한 스타일로 표시
// - 종목별 랭킹 색상을 지정된 순서(진한파랑/황금색/빨강/초록/진한남색/보라/노랑)로 고정
// - 종목별 운동시간 비율 도넛차트 신규 추가

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // 🆕 [요일별 고정 무지개색] 월=빨강 화=주황 수=노랑 목=초록 금=파랑 토=남색 일=보라
  // DateTime.weekday: 1=월 ... 7=일 이므로 인덱스는 weekday-1
  static const List<Color> _rainbowWeekColors = [
    Color(0xFFEF4444), // 월 - 빨강
    Color(0xFFF97316), // 화 - 주황
    Color(0xFFFACC15), // 수 - 노랑
    Color(0xFF22C55E), // 목 - 초록
    Color(0xFF3B82F6), // 금 - 파랑
    Color(0xFF4338CA), // 토 - 남색
    Color(0xFF8B5CF6), // 일 - 보라
  ];

  // 🆕 [종목 랭킹 지정 색상 순서] 1위 진한파랑 / 2위 황금색 / 3위 빨강 / 4위 초록 /
  // 5위 진한남색 / 6위 보라 / 7위 노랑 (그 이상은 순환)
  static const List<Color> _rankColors = [
    Color(0xFF1E3A8A), // 1위 진한파랑
    ExerciseTheme.brandGolden, // 2위 황금색
    Color(0xFFDC2626), // 3위 빨강
    Color(0xFF16A34A), // 4위 초록
    Color(0xFF1E1B4B), // 5위 진한남색
    Color(0xFF9333EA), // 6위 보라
    Color(0xFFEAB308), // 7위 노랑
  ];

  static Color _rankColorAt(int index) => _rankColors[index % _rankColors.length];

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
        enSize: 17,
        koSize: 17,
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
          const SizedBox(height: 24),
          _buildSectionTitle('TIME SHARE BY TYPE', '종목별 운동시간 비율'),
          const SizedBox(height: 12),
          _buildTimeShareDonut(),
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
      height: 92, // 🆕 [2026-09-05 수정] 고정 높이로 3개 카드 크기를 완전히 통일
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: ExerciseTheme.luxeCardDecoration(highlighted: true), // 🆕 진한 테두리
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: ExerciseTheme.titleStyle(size: 22)),
          const SizedBox(height: 8),
          // 🆕 [2026-09-05 수정] 윗줄 영문(명조체) / 아랫줄 한글(노토산스)로 명시적 2줄 배치
          Text(en, style: GoogleFonts.gowunBatang(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 10)),
          Text(ko, style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 10.5)),
        ],
      ),
    );
  }

  // 🆕 [최근 7일 막대그래프 - 참고이미지 스타일] 요일별 고정 무지개색 + Y축 시간·구분점 +
  // X축 요일명. fl_chart의 leftTitles/bottomTitles로 참고 이미지의 축 구성을 재현함.
  Widget _buildWeeklyDurationChart() {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final values = days.map((d) {
      final key = _dateKey(d);
      return _records
          .where((r) => _dateKey(r.date) == key)
          .fold<int>(0, (sum, r) => sum + r.durationMin);
    }).toList();

    final double rawMax = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b).toDouble();
    final double maxVal = (rawMax <= 0 ? 60.0 : rawMax * 1.3).clamp(30.0, 1000000.0);
    // 🆕 [Y축 눈금 간격] 4등분해서 참고 이미지처럼 4~5개의 시간 눈금이 보이도록 계산
    final double interval = (maxVal / 4).clamp(10.0, 1000000.0);

    const weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(4, 20, 16, 8),
      decoration: ExerciseTheme.luxeCardDecoration(highlighted: true), // 🆕 진한 테두리
      child: BarChart(
        BarChartData(
          maxY: maxVal,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withOpacity(0.08), strokeWidth: 1),
          ),
          // 🆕 [참고이미지처럼 X/Y축 선만 표시] 위/오른쪽 테두리는 숨기고 왼쪽/아래만 축선으로
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: ExerciseTheme.brandGolden.withOpacity(0.5), width: 1.4),
              bottom: BorderSide(color: ExerciseTheme.brandGolden.withOpacity(0.5), width: 1.4),
              top: BorderSide.none,
              right: BorderSide.none,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            // 🆕 [Y축: 시간(분) + 구분점] 참고 이미지의 "3h•" 처럼 값 옆에 점을 붙여 표시
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  if (value < 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '${value.toInt()}m •',
                      style: const TextStyle(color: Colors.white54, fontSize: 10.5),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            // 🆕 [X축: 요일명] 참고 이미지처럼 막대 아래에 요일(월/화/수...) 표시
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                  final d = days[idx];
                  final String label = weekdayLabels[d.weekday - 1];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: _rainbowWeekColors[d.weekday - 1],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(values.length, (i) {
            final d = days[i];
            final Color barColor = _rainbowWeekColors[d.weekday - 1]; // 🆕 요일 고정 무지개색
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  color: barColor,
                  width: 20,
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
        decoration: ExerciseTheme.luxeCardDecoration(highlighted: true), // 🆕 진한 테두리
        child: BiInline(en: 'No RPE data yet', ko: '아직 RPE 데이터가 없습니다', color: Colors.white38, fontSize: 12.5),
      );
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 12, 8),
      decoration: ExerciseTheme.luxeCardDecoration(highlighted: true), // 🆕 진한 테두리
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
      decoration: ExerciseTheme.luxeCardDecoration(highlighted: true), // 🆕 진한 테두리
      child: Column(
        children: sorted.asMap().entries.map((indexed) {
          final rank = indexed.key;
          final entry = indexed.value;
          final type = _typesById[entry.key];
          final ratio = entry.value / maxCount;
          final Color rankColor = _rankColorAt(rank); // 🆕 지정 순서 색상
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(ExerciseTheme.iconForType(entry.key), color: rankColor, size: 18),
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
                      valueColor: AlwaysStoppedAnimation<Color>(rankColor),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${entry.value}', style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // 🆕 [신규] 종목별 운동시간(분) 비율 도넛차트 + 우측 범례.
  // 위 종목별 비중(세션 수 기준)과 별개로, 여기는 "시간" 기준 비율이며 색상은
  // 동일한 지정 순서 팔레트(_rankColorAt)를 시간 랭킹에 맞춰 다시 적용한다.
  Widget _buildTimeShareDonut() {
    final Map<String, int> minutesByType = {};
    for (final r in _records) {
      minutesByType[r.exerciseTypeId] = (minutesByType[r.exerciseTypeId] ?? 0) + r.durationMin;
    }
    final sorted = minutesByType.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final int total = sorted.fold(0, (sum, e) => sum + e.value);

    if (sorted.isEmpty || total == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: ExerciseTheme.luxeCardDecoration(highlighted: true),
        child: BiInline(en: 'No data', ko: '데이터 없음', color: Colors.white38, fontSize: 12),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ExerciseTheme.luxeCardDecoration(highlighted: true), // 🆕 진한 테두리
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 34,
                sections: sorted.asMap().entries.map((indexed) {
                  final rank = indexed.key;
                  final entry = indexed.value;
                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    color: _rankColorAt(rank),
                    title: '',
                    radius: 28,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sorted.asMap().entries.map((indexed) {
                final rank = indexed.key;
                final entry = indexed.value;
                final type = _typesById[entry.key];
                final int pct = ((entry.value / total) * 100).round();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(color: _rankColorAt(rank), borderRadius: BorderRadius.circular(3)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          type?.name ?? entry.key,
                          style: const TextStyle(color: Colors.white, fontSize: 12.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${entry.value}m · $pct%',
                        style: TextStyle(color: _rankColorAt(rank), fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
