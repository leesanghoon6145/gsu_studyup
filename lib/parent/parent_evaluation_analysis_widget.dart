import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class ParentEvaluationAnalysisWidget extends StatelessWidget {
  final String childName;
  final String selectedEvaluationType;
  final String selectedBigUnit;
  final String selectedMidUnit;
  final int selectedSemesterFilter;
  final TabController timeTabController;
  final List<dynamic> mirroredExamRecords;
  final List<Map<String, dynamic>> parentMasterTimeData;
  final Color premiumCardBg;
  final Color brandGolden;
  final Color luxuryDarkBg;
  final Function(String) onEvaluationTypeChanged;
  final Function(String) onBigUnitChanged;
  final Function(String) onMidUnitChanged;
  final Function(int) onSemesterFilterChanged;
  final VoidCallback onShowDetailAnalysisReport;
  final Widget Function(String, String, {required double fontSize}) buildCustomSectionTitle;

  const ParentEvaluationAnalysisWidget({
    Key? key,
    required this.childName,
    required this.selectedEvaluationType,
    required this.selectedBigUnit,
    required this.selectedMidUnit,
    required this.selectedSemesterFilter,
    required this.timeTabController,
    required this.mirroredExamRecords,
    required this.parentMasterTimeData,
    required this.premiumCardBg,
    required this.brandGolden,
    required this.luxuryDarkBg,
    required this.onEvaluationTypeChanged,
    required this.onBigUnitChanged,
    required this.onMidUnitChanged,
    required this.onSemesterFilterChanged,
    required this.onShowDetailAnalysisReport,
    required this.buildCustomSectionTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildCustomSectionTitle("Academic Evaluation Matrix", "[ 평가 결과 ]", fontSize: 14.0),
              Text(
                "\"$childName\" 성적 기록 보기",
                style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ["주평가", "단원평가", "중간고사", "기말고사", "모의고사"].map((type) {
                bool isSelected = selectedEvaluationType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(type, style: GoogleFonts.notoSansKr(color: isSelected ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    selected: isSelected,
                    selectedColor: brandGolden,
                    backgroundColor: premiumCardBg,
                    onSelected: (_) => onEvaluationTypeChanged(type),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: premiumCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: brandGolden.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectedEvaluationType == "주평가") ...[
                  Text("[주평가 과거 선택 조회]", style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("년도 선택", style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ["2026년", "2027년", "2028년", "2029년", "2030년"].map((y) => Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: _buildInlineFilterChip(y, selectedBigUnit == y, () => onBigUnitChanged(y)),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("월 선택", style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    dropdownColor: premiumCardBg,
                    value: selectedMidUnit.contains("월") ? selectedMidUnit : "1월",
                    style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                    items: List.generate(12, (i) => "${i + 1}월").map((m) => DropdownMenuItem<String>(value: m, child: Text(m))).toList(),
                    onChanged: (val) => onMidUnitChanged(val!),
                  ),
                  const SizedBox(height: 8),
                  Text("주 평가 선택", style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ["1주차", "2주차", "3주차", "4주차", "5주차"].map((w) => Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: _buildInlineFilterChip(w, selectedMidUnit == w, () => onMidUnitChanged(w)),
                      )).toList(),
                    ),
                  ),
                ] else if (selectedEvaluationType == "단원평가") ...[
                  Text("대단원 선택", style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(
                    children: ["대단원 1", "대단원 2", "대단원 3", "대단원 4"].map((v) => Padding(padding: const EdgeInsets.only(right:4), child: _buildInlineFilterChip(v, selectedBigUnit == v, () => onBigUnitChanged(v)))).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text("중단원 선택", style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(
                    children: ["중단원 1", "중단원 2", "중단원 3", "중단원 4"].map((v) => Padding(padding: const EdgeInsets.only(right:4), child: _buildInlineFilterChip(v, selectedMidUnit == v, () => onMidUnitChanged(v)))).toList(),
                  ),
                ] else ...[
                  Text("학년 선택하면 해당 학기가 활성화됩니다", style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 6),
                  Row(
                    children: ["1학년", "2학년", "3학년"].map((g) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _buildInlineFilterChip(g, selectedBigUnit == g, () { onBigUnitChanged(g); onSemesterFilterChanged(1); }),
                    )).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text("학기 선택", style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildInlineFilterChip("1학기", selectedSemesterFilter == 1, () => onSemesterFilterChanged(1)),
                      const SizedBox(width: 6),
                      _buildInlineFilterChip("2학기", selectedSemesterFilter == 2, () => onSemesterFilterChanged(2)),
                    ],
                  ),
                ],
                const Divider(color: Colors.white10, height: 16),
                Text("그래프 출력 타겟 지정 (학년/학기 연동 인프라 대기 완료)", style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _buildParentEvaluationChart(selectedEvaluationType),
          const SizedBox(height: 24),

          buildCustomSectionTitle("Learning Time Dashboard", "[ 학습시간 ]", fontSize: 14.0),
          const SizedBox(height: 12),
          Container(
            width: double.infinity, height: 42, padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFF0D1527), borderRadius: BorderRadius.circular(10), border: Border.all(color: brandGolden.withValues(alpha: 0.3))),
            child: TabBar(
              controller: timeTabController,
              indicator: BoxDecoration(color: brandGolden, borderRadius: const BorderRadius.all(Radius.circular(6))), // ← 179라인 const 버그 수정
              labelColor: Colors.black, unselectedLabelColor: Colors.white,
              labelStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.w900, fontSize: 12),
              unselectedLabelStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold, fontSize: 12),
              tabs: const [Tab(text: "일간"), Tab(text: "주간"), Tab(text: "월간"), Tab(text: "연간")],
            ),
          ),
          const SizedBox(height: 14),

          _buildParentTimeChartDashboard(timeTabController.index),

          const Divider(color: Colors.white10, height: 32),
          buildCustomSectionTitle("Diagnostic Evaluation Analysis", "[ 오늘의 평가 분석 ]", fontSize: 14.0),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D1527),
              side: BorderSide(color: brandGolden, width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              shadowColor: brandGolden.withValues(alpha: 0.1),
            ),
            onPressed: onShowDetailAnalysisReport,
            icon: Icon(Icons.analytics_rounded, color: brandGolden, size: 18), // ← 203라인 const 버그 수정
            label: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "금일 자녀 학업 성취도 정밀 분석 리포트 조회",
                  style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: brandGolden, size: 12), // ← 211라인 const 버그 수정
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentEvaluationChart(String type) {
    List<dynamic> rawRecords = mirroredExamRecords.where((rec) => rec.type == type).toList();
    if (rawRecords.isEmpty) {
      rawRecords = [
        _ParentExamRecordMock(type: type, subject: "평균", score: 80.0),
        _ParentExamRecordMock(type: type, subject: "수학", score: 95.0),
        _ParentExamRecordMock(type: type, subject: "영어", score: 75.0),
        _ParentExamRecordMock(type: type, subject: "국어", score: 88.0),
        _ParentExamRecordMock(type: type, subject: "과학", score: 65.0),
      ];
    }

    final List<Color> scoreColors = [
      const Color(0xFF34C759),
      const Color(0xFFFF3B30),
      const Color(0xFF007AFF),
      const Color(0xFFFFCC00),
      const Color(0xFFAF52DE),
      const Color(0xFFFF9500),
      const Color(0xFF0500FF),
    ];

    const double chartMaxHeight = 205.0;
    final List<String> scores = ["100점", "90점", "80점", "70점", "60점"];
    const double barWidth = 20.0;
    const double barMargin = 6.0;

    return Container(
      height: 240,
      padding: const EdgeInsets.only(top: 16, bottom: 4, left: 12, right: 12),
      decoration: BoxDecoration(color: premiumCardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 37,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: scores.map((s) => Container(
                      height: 16,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(s, style: GoogleFonts.rajdhani(color: brandGolden, fontSize: 12, fontWeight: FontWeight.w600)),
                    )).toList(),
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(width: 2.5, color: brandGolden),
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (idx) => Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        )),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: rawRecords.length,
                    itemBuilder: (ctx, idx) {
                      final rec = rawRecords[idx];
                      Color barColor = rec.subject == "평균"
                          ? Colors.grey
                          : scoreColors[idx % scoreColors.length];

                      double normalizedScore = (rec.score - 60).clamp(0, 40);
                      double finalBarHeight = (normalizedScore / 40) * (chartMaxHeight - 15);

                      return Container(
                        width: barWidth + (barMargin * 2),
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Positioned(
                              bottom: finalBarHeight + 1,
                              child: Text(
                                "${rec.score.toInt()}%",
                                style: GoogleFonts.rajdhani(color: barColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              height: finalBarHeight < 4 ? 4 : finalBarHeight,
                              width: barWidth,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 37),
            child: Container(height: 2.5, color: brandGolden),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 49),
            child: SizedBox(
              height: 24,
              child: Row(
                children: rawRecords.map((rec) => Container(
                  width: barWidth + (barMargin * 2),
                  alignment: Alignment.center,
                  child: Text(
                    rec.subject,
                    style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentTimeChartDashboard(int tabIndex) {
    String unitLabel;
    double yMin, yMax;
    List<String> yTicks;
    List<Map<String, dynamic>> subjectData;

    if (tabIndex == 0) {
      unitLabel = "";
      subjectData = [
        {"subject": "수학", "avg": 200.0, "value": 280.0},
        {"subject": "영어", "avg": 185.0, "value": 200.0},
        {"subject": "국어", "avg": 180.0, "value": 190.0},
        {"subject": "과학", "avg": 220.5, "value": 245.0},
      ];
    } else if (tabIndex == 1) {
      unitLabel = "h";
      subjectData = [
        {"subject": "수학", "avg": 20.0, "value": 21.0},
        {"subject": "영어", "avg": 20.0, "value": 20.5},
        {"subject": "국어", "avg": 19.5, "value": 21.8},
        {"subject": "과학", "avg": 20.0, "value": 20.5},
      ];
    } else if (tabIndex == 2) {
      unitLabel = "h";
      subjectData = [
        {"subject": "수학", "avg": 29.1, "value": 30.5},
        {"subject": "영어", "avg": 29.1, "value": 30.0},
        {"subject": "국어", "avg": 29.1, "value": 30.0},
        {"subject": "과학", "avg": 30.1, "value": 30.5},
      ];
    } else {
      unitLabel = "h";
      subjectData = [
        {"subject": "수학", "avg": 71.5, "value": 78.0},
        {"subject": "영어", "avg": 75.5, "value": 79.0},
        {"subject": "국어", "avg": 72.5, "value": 79.0},
        {"subject": "과학", "avg": 70.5, "value": 72.0},
      ];
    }

    double allMax = subjectData.map((e) => (e["value"] as double) > (e["avg"] as double) ? (e["value"] as double) : (e["avg"] as double)).reduce((a, b) => a > b ? a : b);
    double allMin = subjectData.map((e) => (e["value"] as double) < (e["avg"] as double) ? (e["value"] as double) : (e["avg"] as double)).reduce((a, b) => a < b ? a : b);

    yMax = tabIndex == 0 ? allMax + 20.0 : allMax + 1.0;
    yMin = tabIndex == 0 ? (allMin - 20.0).clamp(0.0, double.infinity) : (allMin - 1.0).clamp(0.0, double.infinity);
    double step = (yMax - yMin) / 3;
    yTicks = List.generate(4, (i) => "${(yMax - step * i).toStringAsFixed(tabIndex == 0 ? 0 : 1)}$unitLabel").toList();

    const double barW = 17.0;
    const double pairGap = 0.7;
    const double groupGap = 14.0;
    const double chartH = 190.0;

    double multiplier = (tabIndex == 0) ? 1.0 : (tabIndex == 1) ? 5.0 : (tabIndex == 2) ? 22.0 : 250.0;
    double totalMinutes = 0;
    for (var item in parentMasterTimeData) {
      totalMinutes += (item["baseMinutes"] as int) * multiplier;
    }

    final List<Color> subjectColors = [
      const Color(0xFFFF3B30),
      const Color(0xFF007AFF),
      const Color(0xFF34C759),
      const Color(0xFFFF9500),
    ];

    double calcBarH(double val) {
      double delta = (yMax - yMin) == 0 ? 1 : (yMax - yMin);
      return ((val - yMin) / delta * chartH).clamp(2.0, chartH);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 12, 0),
          decoration: BoxDecoration(
            color: const Color(0xFF070E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: brandGolden.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(width: 10, height: 10, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text("평균", style: GoogleFonts.notoSansKr(color: Colors.white60, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      SizedBox(
                        height: chartH,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: 55,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: yTicks.map((t) {
                                  String formattedText = t.contains('h') ? t : '${t.replaceAll('m', '')}m';
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: Text(
                                      formattedText,
                                      style: GoogleFonts.rajdhani(color: brandGolden, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                Container(width: 2, color: brandGolden),
                                Positioned.fill(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: List.generate(4, (idx) => Container(
                                      width: 6, height: 6,
                                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    )),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: chartH,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(subjectData.length, (idx) {
                                final item = subjectData[idx];
                                double avgH = calcBarH((item["avg"] as double));
                                double valH = calcBarH((item["value"] as double));
                                Color col = subjectColors[idx % subjectColors.length];
                                return Padding(
                                  padding: EdgeInsets.only(left: groupGap),
                                  child: SizedBox(
                                    height: chartH,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Text("${(item["avg"] as double).toStringAsFixed(1)}$unitLabel", style: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 2),
                                            Container(width: barW, height: avgH, decoration: const BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.vertical(top: Radius.circular(3)))),
                                          ],
                                        ),
                                        const SizedBox(width: pairGap),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Text("${(item["value"] as double).toStringAsFixed(1)}$unitLabel", style: GoogleFonts.rajdhani(color: col, fontSize: 8, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 2),
                                            Container(width: barW, height: valH, decoration: BoxDecoration(color: col, borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                        Container(height: 2, color: brandGolden),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const SizedBox(width: 1),
                              ...List.generate(subjectData.length, (idx) {
                                return Container(
                                  width: 36.0,
                                  margin: const EdgeInsets.only(left: 18),
                                  alignment: Alignment.center,
                                  child: Text(
                                    subjectData[idx]["subject"] as String,
                                    style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        const Divider(color: Colors.white10, height: 24),
        Row(
          children: [
            Expanded(
              flex: 6,
              child: Center(
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(180, 180),
                        painter: _ParentDashboardPiePainterComponent(),
                      ),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(color: premiumCardBg, shape: BoxShape.circle), // ← 591라인 const 버그 수정
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Total', style: GoogleFonts.gowunBatang(color: Colors.white38, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text("${totalMinutes.round()}m", style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: ["수학 (39%)", "영어 (28%)", "국어 (18%)", "과학 (15%)"]
                    .asMap()
                    .entries
                    .map((entry) {
                  int idx = entry.key;
                  String txt = entry.value;
                  List<Color> cols = [
                    const Color(0xFFFF3B30),
                    const Color(0xFF007AFF),
                    const Color(0xFF34C759),
                    const Color(0xFFFF9500),
                  ];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(color: cols[idx % cols.length], shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(txt, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInlineFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? brandGolden : Colors.black38,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: brandGolden.withValues(alpha: 0.25)),
        ),
        child: Text(label, style: GoogleFonts.notoSansKr(color: isSelected ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _ParentExamRecordMock {
  final String type;
  final String subject;
  final double score;
  _ParentExamRecordMock({required this.type, required this.subject, required this.score});
}

class _ParentDashboardPiePainterComponent extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()..style = PaintingStyle.fill..isAntiAlias = true;
    double start = -math.pi / 2;
    List<Color> cols = [const Color(0xFFFF3B30), const Color(0xFF007AFF), const Color(0xFF34C759), const Color(0xFFFF9500)];
    List<double> sweeps = [math.pi * 0.78, math.pi * 0.56, math.pi * 0.36, math.pi * 0.3];

    for (int i = 0; i < sweeps.length; i++) {
      p.color = cols[i];
      canvas.drawArc(Rect.fromLTWH(0, 0, size.width, size.height), start, sweeps[i], true, p);
      start += sweeps[i];
    }
  }
  @override
  bool shouldRepaint(CustomPainter old) => false;
}