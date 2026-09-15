// exercise_type_analysis_screen.dart
//
// ✅ [2026-09-13 신규] 종목별 "상세 분석" 화면. 종목 하나(예: 골프)를 골라
// 들어오면:
//  1) 상단에서 날짜를 ◀/▶로 하루씩 넘기며 과거 기록도 조회 가능
//  2) 그 날짜의 "구성"(예: 버디/이글/보기 이상 등 카운터형 항목 비중)을 도넛차트로
//  3) 숫자형 항목마다 각각 작은 막대그래프(최근 14일 추이)를 항목별로 분리해서 표시
//
// 색상 원칙: ExerciseTheme.rainbowCycleColorAt(index) - 빨주노초파남보 순환.
// 항목 순서(인덱스)로 색을 고정하기 때문에, 같은 항목은 이 화면을 다시 열어도
// 항상 같은 색으로 보인다.
//
// 이 화면은 모든 종목에 공용으로 재사용 가능하도록 ExerciseType 하나를 받아서
// 동작한다 - 골프에서 먼저 검증한 뒤 다른 15종목에도 그대로 연결하면 됨.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'exercise_models.dart';
import 'exercise_data_service.dart';
import 'exercise_theme.dart';
import 'exercise_i18n.dart';

class ExerciseTypeAnalysisScreen extends StatefulWidget {
  final ExerciseType type;
  const ExerciseTypeAnalysisScreen({super.key, required this.type});

  @override
  State<ExerciseTypeAnalysisScreen> createState() => _ExerciseTypeAnalysisScreenState();
}

class _ExerciseTypeAnalysisScreenState extends State<ExerciseTypeAnalysisScreen> {
  bool _loading = true;
  List<ExerciseRecord> _records = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await ExerciseDataService.instance.getRecordsByType(widget.type.id);
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _isSameDate(DateTime a, DateTime b) => _dateKey(a) == _dateKey(b);

  // ✅ 필드 라벨을 appLanguage 상태에 맞게 병기(영문(한글) 또는 10개국어)
  String _bilabel(ExerciseField field) {
    if (field.enLabel == null || field.enLabel!.isEmpty) return field.label;
    if (appLanguage.isForeignSelected) {
      final String? translated = kExerciseTermTranslations[field.enLabel]?[appLanguage.current];
      return translated ?? field.enLabel!;
    }
    return '${field.enLabel} (${field.label})';
  }

  num? _valueOn(DateTime date, String fieldKey) {
    num total = 0;
    bool found = false;
    for (final r in _records) {
      if (!_isSameDate(r.date, date)) continue;
      final dynamic v = r.detail[fieldKey];
      if (v is num) {
        total += v;
        found = true;
      }
    }
    return found ? total : null;
  }

  List<num> _last14DaysValues(String fieldKey) {
    final DateTime today = DateTime.now();
    return List.generate(14, (i) {
      final d = DateTime(today.year, today.month, today.day).subtract(Duration(days: 13 - i));
      return _valueOn(d, fieldKey) ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String enName = ExerciseTheme.englishNameForType(widget.type.id, widget.type.name);
    return Scaffold(
      backgroundColor: ExerciseTheme.pageBg,
      appBar: ExerciseTheme.biAppBar(
        en: '$enName ANALYSIS',
        ko: '${widget.type.name} 상세분석',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ExerciseTheme.brandGolden))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDateNavigator(),
          const SizedBox(height: 20),
          _buildSectionTitle('TODAY\'S COMPOSITION', '오늘의 구성'),
          const SizedBox(height: 12),
          _buildCompositionDonut(),
          const SizedBox(height: 28),
          _buildSectionTitle('TRENDS (14 DAYS)', '항목별 14일 추이'),
          const SizedBox(height: 4),
          Text(
            '항목마다 색이 고정되어 있어, 다른 종목과 비교할 때도 같은 색은 같은 성격의 항목입니다.',
            style: ExerciseTheme.bodyStyle(size: 10.5, color: Colors.white38),
          ),
          const SizedBox(height: 14),
          ..._buildPerFieldCharts(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String en, String ko) {
    return BiInline(en: en, ko: ko, color: ExerciseTheme.goldenLight, fontWeight: FontWeight.bold, fontSize: 14.5);
  }

  // ✅ [날짜 좌우 이동] ◀ 오늘/과거 날짜 ▶. 오늘보다 미래로는 못 넘어가게 제한.
  Widget _buildDateNavigator() {
    final bool isToday = _isSameDate(_selectedDate, DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: ExerciseTheme.luxeCardDecoration(highlighted: true),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: ExerciseTheme.brandGolden),
            onPressed: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
          ),
          Column(
            children: [
              Text(
                isToday ? 'TODAY' : '${_selectedDate.month}/${_selectedDate.day}',
                style: GoogleFonts.gowunBatang(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11),
              ),
              Text(
                '${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.day.toString().padLeft(2, '0')}',
                style: ExerciseTheme.titleStyle(size: 15),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded, color: isToday ? Colors.white24 : ExerciseTheme.brandGolden),
            onPressed: isToday
                ? null
                : () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }

  // ✅ [도넛차트] 카운터형(counter) 항목들 - 선택된 날짜의 값 비중을 보여줌.
  // 골프 기준: 3퍼팅/이글/버디/보기 이상/OB 등. 전부 0이면 "기록 없음" 표시.
  Widget _buildCompositionDonut() {
    final List<ExerciseField> counterFields = widget.type.fields.where((f) => f.type == ExerciseFieldType.counter).toList();
    if (counterFields.isEmpty) {
      return _emptyCard('이 종목은 구성 비중으로 보여줄 항목이 없습니다.');
    }
    final List<MapEntry<ExerciseField, num>> entries = [];
    for (final f in counterFields) {
      final v = _valueOn(_selectedDate, f.key) ?? 0;
      if (v > 0) entries.add(MapEntry(f, v));
    }
    if (entries.isEmpty) {
      return _emptyCard('선택한 날짜에 기록된 항목이 없습니다.');
    }
    final num sum = entries.fold(0, (s, e) => s + e.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ExerciseTheme.luxeCardDecoration(highlighted: true),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 32,
                sections: entries.asMap().entries.map((e) {
                  final int idx = counterFields.indexOf(e.value.key); // ✅ [2026-09-14 버그 수정] 전체 필드 목록이 아닌 counterFields 목록 안에서의 순서
                  final Color color = ExerciseTheme.rainbowCycleColorAt(idx);
                  return PieChartSectionData(
                    value: e.value.value.toDouble(),
                    color: color,
                    radius: 22,
                    showTitle: false,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.map((e) {
                final int idx = counterFields.indexOf(e.key); // ✅ [2026-09-14 버그 수정] 동일하게 counterFields 기준
                final Color color = ExerciseTheme.rainbowCycleColorAt(idx);
                final double pct = sum == 0 ? 0 : (e.value / sum * 100);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_bilabel(e.key), style: const TextStyle(color: Colors.white70, fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Text('${e.value.toInt()} (${pct.toStringAsFixed(0)}%)', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11.5)),
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

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ExerciseTheme.luxeCardDecoration(),
      child: Text(message, style: ExerciseTheme.bodyStyle(size: 12, color: Colors.white38)),
    );
  }

  // ✅ [항목별 미니 막대그래프] 숫자형(number) 항목마다 최근 14일 추이를
  // 각각 작은 차트로 분리 - 한 그래프에 다 넣으면 항목마다 단위가 달라
  // 비교가 불가능해지므로, 항목별로 나누는 게 원칙(사용자 제안 반영).
  // ✅ [2026-09-13 추가] 최댓값에 맞춰 Y축 눈금 간격을 5개 안팎으로 보기 좋게
  // 자동 계산 (1/2/5/10/20/50/100 배수 중 하나로 반올림하는 흔한 방식).
  double _niceAxisInterval(double top) {
    if (top <= 0) return 1;
    final double rough = top / 4;
    final List<double> steps = [1, 2, 5, 10, 20, 25, 50, 100, 200, 500, 1000];
    for (final s in steps) {
      if (rough <= s) return s;
    }
    return (rough / 100).ceil() * 100;
  }

  List<Widget> _buildPerFieldCharts() {
    final List<ExerciseField> numberFields = widget.type.fields.where((f) => f.type == ExerciseFieldType.number).toList();
    if (numberFields.isEmpty) return [_emptyCard('이 종목은 숫자형 추이 항목이 없습니다.')];

    // ✅ [2026-09-13 추가] 막대 14개 각각이 정확히 어느 날짜인지 라벨에 쓰기 위해
    // _last14DaysValues와 완전히 같은 순서로 날짜 목록도 같이 만든다.
    final DateTime today = DateTime.now();
    final List<DateTime> days = List.generate(14, (i) {
      final d = DateTime(today.year, today.month, today.day).subtract(Duration(days: 13 - i));
      return d;
    });

    return numberFields.map((field) {
      final int idx = numberFields.indexOf(field); // ✅ [2026-09-14 버그 수정] 전체 필드 목록이 아닌 numberFields 목록 안에서의 순서 - 같은 색 겹침 방지
      final Color color = ExerciseTheme.rainbowCycleColorAt(idx);
      final List<num> values = _last14DaysValues(field.key);
      final double maxVal = values.isEmpty ? 0 : values.map((v) => v.toDouble()).reduce((a, b) => a > b ? a : b);
      // ✅ [Y축 눈금] 최댓값에 맞춰 5개 안팎의 보기 좋은 눈금 간격을 자동 계산.
      final double top = maxVal <= 0 ? 4 : maxVal * 1.25;
      final double interval = _niceAxisInterval(top);

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: ExerciseTheme.luxeCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _bilabel(field),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (field.unit != null)
                  Text(field.unit!, style: const TextStyle(color: Colors.white38, fontSize: 10.5)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: top,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withOpacity(0.06), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: color.withOpacity(0.4), width: 1),
                      bottom: BorderSide(color: color.withOpacity(0.4), width: 1),
                      top: BorderSide.none,
                      right: BorderSide.none,
                    ),
                  ),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    // ✅ [Y축] 항목 수치 눈금
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 && meta.max != 0) {
                            // 0은 X축 바로 위라 굳이 안 겹치게 생략 가능하지만, 첫 눈금이라 표시함
                          }
                          return Text(
                            value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white54, fontSize: 9.5),
                          );
                        },
                      ),
                    ),
                    // ✅ [X축] 날짜(일). 14개 전부 표시하면 겹치니 이틀에 하나씩만 표시.
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        getTitlesWidget: (value, meta) {
                          final int i = value.toInt();
                          if (i < 0 || i >= days.length) return const SizedBox.shrink();
                          if (i % 2 != 0 && i != days.length - 1) return const SizedBox.shrink(); // 이틀에 하나 + 마지막(오늘)은 항상 표시
                          final DateTime d = days[i];
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('${d.month}/${d.day}', style: const TextStyle(color: Colors.white38, fontSize: 9)),
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
                          color: color.withOpacity(0.85),
                          width: 8,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
