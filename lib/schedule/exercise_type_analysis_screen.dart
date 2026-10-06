// exercise_type_analysis_screen.dart
//
// ✅ [2026-09-13 신규] 종목별 "상세 분석" 화면. 종목 하나(예: 골프)를 골라
// 들어오면:
//  1) 상단에서 날짜를 ◀/▶로 하루씩 넘기며 과거 기록도 조회 가능
//  2) 그 날짜의 "구성"(예: 버디/이글/보기 이상 등 카운터형 항목 비중)을 도넛차트로
//  3) 숫자형 항목마다 각각 막대그래프(최근 14일 추이)를 항목별로 분리해서 표시
//
// 🆕 [2026-10-04] 16개 종목 공통
//  - 막대 2배 이상 굵게, 한 화면에 5~6일, 좌우로 밀면 2주 (처음엔 오늘이 오른쪽 끝)
//  - 색: 위부터 빨강 · 녹색 · 파랑 · 황금 · 흰색 · 남색 · 노랑 (밝게)
//  - 날짜를 매일 표시

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

  // 🆕 [2026-10-04] 위부터 빨강 · 녹색 · 파랑 · 황금 · 흰색 · 남색 · 노랑 (밝게)
  static const List<Color> _kFieldColors = [
    Color(0xFFEF4444), // 빨강
    Color(0xFF22C55E), // 녹색
    Color(0xFF3B82F6), // 파랑
    ExerciseTheme.brandGolden, // 황금
    Color(0xFFF8FAFC), // 흰색
    Color(0xFF6366F1), // 남색 (어두운 바탕에서 보이게 밝은 남색)
    Color(0xFFFACC15), // 노랑
  ];
  static Color _fieldColor(int i) => _kFieldColors[(i < 0 ? 0 : i) % _kFieldColors.length];

  bool _isSameDate(DateTime a, DateTime b) => _dateKey(a) == _dateKey(b);

  // ✅ 필드 라벨을 appLanguage 상태에 맞게 병기(영문(한글) 또는 10개국어)
  String _bilabel(ExerciseField field) {
    if (field.enLabel == null || field.enLabel!.isEmpty) return field.label;
    if (appLanguage.isEnglishOnly) return field.enLabel!; // 🆕 English = 영어만
    if (appLanguage.isForeignSelected) {
      final String? translated = kExerciseTermTranslations[field.enLabel]?[appLanguage.current];
      return translated ?? field.enLabel!;
    }
    return field.label; // 🆕 [2026-09-30] 한국어 = 쉬운 한글만
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
            '항목마다 색이 고정되어 있어, 다른 종목과 비교할 때도 같은 색은 같은 성격의 항목입니다. 그래프를 좌우로 밀면 2주를 볼 수 있어요.',
            style: ExerciseTheme.bodyStyle(size: 10.5, color: Colors.white38),
          ),
          const SizedBox(height: 14),
          ..._buildPerFieldCharts(),
          // 🆕 [헬스 2026-10-04] 운동별(스쿼트 등) 최고 무게 2주 추이
          if (widget.type.id == 'gym') ...[
            const SizedBox(height: 14),
            _buildSectionTitle('BEST WEIGHT BY EXERCISE (14 DAYS)', '운동별 최고 무게 (14일)'),
            const SizedBox(height: 4),
            Text(
              '그날 그 운동에서 가장 무겁게 든 무게입니다. 자주 한 운동부터 최대 6개까지 보여요.',
              style: ExerciseTheme.bodyStyle(size: 10.5, color: Colors.white38),
            ),
            const SizedBox(height: 14),
            ..._buildGymExerciseCharts(),
          ],
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
                  final int idx = counterFields.indexOf(e.value.key);
                  final Color color = _fieldColor(idx);
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
                final int idx = counterFields.indexOf(e.key);
                final Color color = _fieldColor(idx);
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

  // ✅ 최댓값에 맞춰 Y축 눈금 간격을 5개 안팎으로 자동 계산
  double _niceAxisInterval(double top) {
    if (top <= 0) return 1;
    final double rough = top / 4;
    final List<double> steps = [1, 2, 5, 10, 20, 25, 50, 100, 200, 500, 1000];
    for (final s in steps) {
      if (rough <= s) return s;
    }
    return (rough / 100).ceil() * 100;
  }

  // ✅ [항목별 막대그래프] 숫자형 항목마다 최근 14일 추이를 각각 분리해서 표시
  List<Widget> _buildPerFieldCharts() {
    final List<ExerciseField> numberFields = widget.type.fields.where((f) => f.type == ExerciseFieldType.number).toList();
    if (numberFields.isEmpty) return [_emptyCard('이 종목은 숫자형 추이 항목이 없습니다.')];

    final DateTime today = DateTime.now();
    final List<DateTime> days = List.generate(14, (i) {
      return DateTime(today.year, today.month, today.day).subtract(Duration(days: 13 - i));
    });

    return numberFields.map((field) {
      final int idx = numberFields.indexOf(field);
      final Color color = _fieldColor(idx); // 🆕 [2026-10-04] 위부터 빨·녹·파·황금·흰·남·노
      final List<num> values = _last14DaysValues(field.key);
      final double maxVal = values.isEmpty ? 0 : values.map((v) => v.toDouble()).reduce((a, b) => a > b ? a : b);
      final double top = maxVal <= 0 ? 4 : maxVal * 1.25;
      final double interval = _niceAxisInterval(top);
      // 🆕 [2026-10-04] 맨 위 눈금 글자가 반쯤 잘리지 않게, 눈금 위에 여유를 조금 둠
      final double maxY = (top / interval).ceil() * interval + interval * 0.25;

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
            // 🆕 [2026-10-04] Y축(왼쪽 눈금)은 고정, 막대와 날짜(X축)만 좌우로 스크롤
            // 한 화면에 5~6일, 좌우로 밀면 2주, 처음엔 오늘(오른쪽 끝)
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 고정된 Y축: 막대 없이 눈금 글자만 그리는 좁은 그래프 (오른쪽 그래프와 높이·눈금이 정확히 같음)
                  SizedBox(
                    width: 40,
                    child: BarChart(_chartData(color: color, maxY: maxY, interval: interval, days: days, values: const [], showLeft: true)),
                  ),
                  // ── 좌우로 움직이는 막대 + 날짜
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: SizedBox(
                          width: box.maxWidth / 5.5 * 14,
                          child: BarChart(_chartData(color: color, maxY: maxY, interval: interval, days: days, values: values, showLeft: false)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }


  // 🆕 [헬스 2026-10-04] 운동별 최고 무게 그래프 (스쿼트 · 벤치프레스 …)
  // 새 기록(exercises 목록)과 예전 기록(exerciseName + sets) 모두 읽음
  List<Widget> _buildGymExerciseCharts() {
    final DateTime today = DateTime.now();
    final List<DateTime> days = List.generate(14, (i) {
      return DateTime(today.year, today.month, today.day).subtract(Duration(days: 13 - i));
    });
    final Map<String, Map<String, double>> best = {}; // 운동 이름 → 날짜 → 그날 최고 무게
    final Map<String, int> freq = {};
    for (final r in _records) {
      final dynamic ex = r.detail['exercises'];
      List<Map> lines = [];
      if (ex is List) {
        lines = ex.whereType<Map>().toList();
      } else if ((r.detail['exerciseName'] ?? '').toString().trim().isNotEmpty) {
        lines = [
          {'name': r.detail['exerciseName'], 'sets': r.detail['sets']},
        ];
      }
      for (final line in lines) {
        final String name = (line['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        double top = 0;
        for (final s in (line['sets'] as List?) ?? const []) {
          if (s is Map && s['weightKg'] is num) {
            final double w = (s['weightKg'] as num).toDouble();
            if (w > top) top = w;
          }
        }
        if (top <= 0) continue;
        final String k = _dateKey(r.date);
        final Map<String, double> m = best.putIfAbsent(name, () => {});
        if (top > (m[k] ?? 0)) m[k] = top;
        freq[name] = (freq[name] ?? 0) + 1;
      }
    }
    if (best.isEmpty) {
      return [_emptyCard('운동 이름과 세트 무게를 기록하면 운동별 최고 무게 그래프가 나와요.')];
    }
    String kg(double v) => v == v.roundToDouble() ? '${v.toInt()}kg' : '${v.toStringAsFixed(1)}kg';
    final List<String> names = freq.keys.toList()..sort((a, b) => freq[b]!.compareTo(freq[a]!));
    return names.take(6).toList().asMap().entries.map((e) {
      final String name = e.value;
      final Color color = _fieldColor(e.key);
      final List<num> values = days.map((d) => best[name]![_dateKey(d)] ?? 0).toList();
      final List<double> done = values.where((v) => v > 0).map((v) => v.toDouble()).toList();
      String change = '';
      if (done.length >= 2) {
        final double diff = done.last - done.first;
        change = '${kg(done.first)} → ${kg(done.last)}  (${diff >= 0 ? '+' : ''}${kg(diff)})';
      } else if (done.length == 1) {
        change = kg(done.first);
      }
      return _trendCard(title: name, unit: 'kg', color: color, values: values, days: days, note: change);
    }).toList();
  }

  // 🆕 [2026-10-04] 추이 카드 하나 (Y축 고정 · 막대와 날짜만 좌우 스크롤)
  Widget _trendCard({
    required String title,
    String? unit,
    required Color color,
    required List<num> values,
    required List<DateTime> days,
    String note = '',
  }) {
    final double maxVal = values.isEmpty ? 0 : values.map((v) => v.toDouble()).reduce((a, b) => a > b ? a : b);
    final double top = maxVal <= 0 ? 4 : maxVal * 1.25;
    final double interval = _niceAxisInterval(top);
    final double maxY = (top / interval).ceil() * interval + interval * 0.25;
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
                child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              if (unit != null) Text(unit, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(note, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 40,
                  child: BarChart(_chartData(color: color, maxY: maxY, interval: interval, days: days, values: const [], showLeft: true)),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: SizedBox(
                        width: box.maxWidth / 5.5 * 14,
                        child: BarChart(_chartData(color: color, maxY: maxY, interval: interval, days: days, values: values, showLeft: false)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 [2026-10-04] 고정 Y축 그래프와 움직이는 막대 그래프가 같은 눈금·높이를 쓰도록 한 곳에서 만듦
  BarChartData _chartData({
    required Color color,
    required double maxY,
    required double interval,
    required List<DateTime> days,
    required List<num> values,
    required bool showLeft,
  }) {
    const TextStyle axisStyle = TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold); // 🆕 진하고 또렷하게
    return BarChartData(
      minY: 0,
      maxY: maxY,
      alignment: BarChartAlignment.spaceAround,
      gridData: FlGridData(
        show: !showLeft,
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withOpacity(0.08), strokeWidth: 1),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          right: showLeft ? BorderSide(color: color.withOpacity(0.6), width: 1.2) : BorderSide.none, // 고정 Y축의 세로선
          bottom: showLeft ? BorderSide.none : BorderSide(color: color.withOpacity(0.6), width: 1.2),
          top: BorderSide.none,
          left: BorderSide.none,
        ),
      ),
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: showLeft,
            reservedSize: 38,
            interval: interval,
            getTitlesWidget: (value, meta) {
              if (value > maxY - interval * 0.2) return const SizedBox.shrink(); // 여유 칸에는 글자 없음
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1),
                  style: axisStyle,
                  textAlign: TextAlign.right,
                ),
              );
            },
          ),
        ),
        // X축 날짜: 고정 Y축 쪽도 같은 높이를 비워 두어 두 그래프의 바닥선이 정확히 맞음
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            getTitlesWidget: (value, meta) {
              if (showLeft) return const SizedBox.shrink();
              final int i = value.toInt();
              if (i < 0 || i >= days.length) return const SizedBox.shrink();
              final DateTime d = days[i];
              final bool isToday = i == days.length - 1;
              return Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '${d.month}/${d.day}',
                  style: axisStyle.copyWith(color: isToday ? ExerciseTheme.brandGolden : Colors.white),
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
              color: color.withOpacity(0.9),
              width: 22, // 막대 2배 이상
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }),
    );
  }
}
