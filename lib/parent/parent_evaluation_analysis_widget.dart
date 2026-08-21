import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class ParentEvaluationAnalysisWidget extends StatelessWidget {
  final String childName;
  final String selectedEvaluationType;
  final String selectedBigUnit;
  final String selectedMidUnit;
  final int selectedSemesterFilter;
  // 🆕 [버그 수정] 주평가 전용 년/월/주차 상태 - 기존엔 단원평가용 selectedBigUnit/selectedMidUnit을
  // 그대로 빌려쓰고 있어서 월/주차가 서로 덮어쓰며 충돌했고, 애초에 필터링에 반영도 안 되고 있었음.
  final String selectedYear;
  final String selectedMonth;
  final String selectedWeek;
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
  final Function(String) onYearChanged;
  final Function(String) onMonthChanged;
  final Function(String) onWeekChanged;
  final VoidCallback onShowDetailAnalysisReport;
  final Widget Function(String, String, {required double fontSize}) buildCustomSectionTitle;

  const ParentEvaluationAnalysisWidget({
    Key? key,
    required this.childName,
    required this.selectedEvaluationType,
    required this.selectedBigUnit,
    required this.selectedMidUnit,
    required this.selectedSemesterFilter,
    required this.selectedYear,
    required this.selectedMonth,
    required this.selectedWeek,
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
    required this.onYearChanged,
    required this.onMonthChanged,
    required this.onWeekChanged,
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
                        child: _buildInlineFilterChip(y, selectedYear == y, () => onYearChanged(y)),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("월 선택", style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    dropdownColor: premiumCardBg,
                    value: selectedMonth,
                    style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                    items: List.generate(12, (i) => "${i + 1}월").map((m) => DropdownMenuItem<String>(value: m, child: Text(m))).toList(),
                    onChanged: (val) => onMonthChanged(val!),
                  ),
                  const SizedBox(height: 8),
                  Text("주 평가 선택", style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ["1주차", "2주차", "3주차", "4주차", "5주차"].map((w) => Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: _buildInlineFilterChip(w, selectedWeek == w, () => onWeekChanged(w)),
                      )).toList(),
                    ),
                  ),
                ] else if (selectedEvaluationType == "단원평가") ...[
                  // 🆕 [단원 확장] 과목마다 대단원 개수가 다름(4단원짜리도, 12단원짜리도 있음)을 고려해
                  // 대단원 1~12까지 전부 노출하고 가로 스크롤로 넘겨볼 수 있게 함.
                  Text("대단원 선택", style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(12, (i) => "대단원 ${i + 1}").map((v) => Padding(padding: const EdgeInsets.only(right:4), child: _buildInlineFilterChip(v, selectedBigUnit == v, () => onBigUnitChanged(v)))).toList(),
                    ),
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

          buildCustomSectionTitle("Subject Scores", "[ 과목 점수 ]", fontSize: 14.0),
          const SizedBox(height: 12),
          _buildParentEvaluationChart(selectedEvaluationType),
          const SizedBox(height: 24),

          buildCustomSectionTitle("Learning Time Dashboard", "[ 학습시간 ]", fontSize: 14.0),
          const SizedBox(height: 12),
          Container(
            width: double.infinity, height: 42, padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFF0D1527), borderRadius: BorderRadius.circular(10), border: Border.all(color: brandGolden.withValues(alpha: 0.3))),
            child: TabBar(
              controller: timeTabController,
              indicator: BoxDecoration(color: brandGolden, borderRadius: const BorderRadius.all(Radius.circular(6))),
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
            icon: Icon(Icons.analytics_rounded, color: brandGolden, size: 18),
            label: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "금일 자녀 학업 성취도 정밀 분석 리포트 조회",
                  style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: brandGolden, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 [실데이터 연동] mirroredExamRecords(gke_exam_records 실제 데이터)만 사용,
  // 기록이 없으면 가짜 점수 대신 빈 상태 안내를 표시합니다.
  Widget _buildParentEvaluationChart(String type) {
    List<dynamic> rawRecords = mirroredExamRecords.where((rec) => rec.type == type).toList();

    // 🆕 [버그 수정] 년도/월/주차 선택이 화면에 전혀 반영되지 않던 문제 - 필터링 로직이 아예
    // 없었음. 학생 화면(member_achievement_screen.dart _getFilteredRecords)과 동일하게
    // rec.unit에 선택한 년/월/주차 문자열이 모두 포함된 기록만 남기도록 수정.
    if (type == "주평가") {
      rawRecords = rawRecords.where((rec) {
        final String unit = rec.unit.toString();
        return unit.contains(selectedYear) && unit.contains(selectedMonth) && unit.contains(selectedWeek);
      }).toList();
    }

    if (rawRecords.isEmpty) {
      return Container(
        height: 140,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: premiumCardBg, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text(
          "아직 \"$type\" 기록이 없습니다.\n평가가 기록되면 자동으로 표시됩니다.",
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12, height: 1.5),
        ),
      );
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

    // 🆕 [버그 수정] 막대 스케일과 Y축 라벨 위치가 서로 다른 기준으로 계산되어 어긋나던 문제 -
    // Y축 세로 폭을 줄이고(220→190) 카드 전체 높이는 넉넉하게 늘려서(275→300) 막대가 X축을 넘지 않도록 함
    const double chartMaxHeight = 210.0;
    final List<String> scores = ["100점", "90점", "80점", "70점", "60점"];
    // 🆕 [원장님 최종 확정] 막대 폭 32 / 20 고정 (member_achievement_screen.dart와 동일 원칙)
    const double barWidth = 20.0;
    // 🆕 [요청] X축 아래 과목명칭 영역이 좁아서 조금 넓힘 (6→9)
    const double barMargin = 9.0;

    return Container(
      height: 300,
      padding: const EdgeInsets.only(top: 24, bottom: 4, left: 12, right: 12),
      decoration: BoxDecoration(color: premiumCardBg, borderRadius: BorderRadius.circular(12)),
      // 🆕 [버그 수정] 막대+라벨을 스크롤 하나로 합치는 과정에서 실수로 빠졌던 X축 기준선(60점 가로선)을
      // Stack + Positioned로 복원. 스크롤 여부와 무관하게 항상 고정된 위치(60점 높이)에 표시됩니다.
      child: Stack(
        children: [
          Row(
            // 🆕 [버그 수정] stretch로 인해 Y축 라벨/세로선이 카드 전체 높이만큼 늘어나서
            // "60점" 라벨이 실제 막대 스케일(chartMaxHeight)보다 훨씬 아래에 표시되던 근본 원인 수정.
            // 이제 Y축도 막대와 정확히 같은 chartMaxHeight를 기준으로 그려서 눈금과 막대가 딱 맞습니다.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 17),
                child: SizedBox(
                  width: 37,
                  height: chartMaxHeight,
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
              ),
              Padding(
                padding: const EdgeInsets.only(top: 17),
                child: SizedBox(
                  height: chartMaxHeight,
                  child: Stack(
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
                ),
              ),
              const SizedBox(width: 12),
              // 🆕 [버그 수정] 막대와 과목명 라벨을 같은 스크롤 안에 하나로 합쳐서, 막대만 스크롤되고
              // 라벨은 고정된 채 화면 밖으로 튕겨나가던(오른쪽 오버플로우) 문제를 근본적으로 해결
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(rawRecords.length, (idx) {
                      final rec = rawRecords[idx];
                      Color barColor = scoreColors[idx % scoreColors.length];

                      double normalizedScore = (rec.score - 60).clamp(0, 40);
                      // 🆕 [요청] 100점일 때 점수 숫자가 위쪽 여백 부족으로 안 보이던 문제 수정 -
                      // 막대 최대 높이를 chartMaxHeight의 82%로 제한해서 점수 라벨이 들어갈 여유 공간을 확보
                      double finalBarHeight = (normalizedScore / 40) * (chartMaxHeight * 0.99);

                      return Container(
                        width: barWidth + (barMargin * 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: chartMaxHeight + 15,
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
                                  Positioned(
                                    bottom: -0,
                                    child: Container(
                                      height: finalBarHeight < 4 ? 4 : finalBarHeight,
                                      width: barWidth,
                                      decoration: BoxDecoration(
                                        color: barColor,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 30,
                              child: Text(
                                rec.subject,
                                textAlign: TextAlign.center,
                                maxLines: 2, // 🆕 [요청] 과목명이 길어도 2줄까지 허용, 넘치면 말줄임
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, height: 1.2),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
          // 🆕 [버그 수정] X축 기준선(60점 라인) - 세로선이 시작하는 지점부터 오른쪽 끝까지, 60점 높이에 고정 표시
          Positioned(
            left: 37,
            right: 0,
            top: chartMaxHeight +15,
            child: Container(height: 2.5, color: brandGolden),
          ),
        ],
      ),
    );
  }

  // 🆕 [실데이터 연동] parentMasterTimeData(ParentDataService.loadSubjectAggregates() 결과)를
  // 사용해 실제 학습시간 막대그래프를 그립니다. "평균"은 다른 학생과 비교할 서버 데이터가 없는
  // 현재로서는 본인 과목들의 평균값으로 표시합니다(member_achievement_screen.dart와 동일한 처리 방식).
  Widget _buildParentTimeChartDashboard(int tabIndex) {
    final List<String> flagKeys = ["hasStudiedToday", "hasStudiedWeekly", "hasStudiedMonthly", "hasStudiedYearly"];
    final String flagKey = flagKeys[tabIndex];
    final String unitLabel = tabIndex == 0 ? "" : "h";
    double multiplier = (tabIndex == 0) ? 1.0 : (tabIndex == 1) ? 5.0 : (tabIndex == 2) ? 22.0 : 250.0;

    List<Map<String, dynamic>> subjectData = parentMasterTimeData
        .where((e) => e[flagKey] == true)
        .map((e) => {
      "subject": e["subject"] as String,
      "value": (e["baseMinutes"] as int) * multiplier,
    })
        .where((e) => (e["value"] as double) > 0)
        .toList();

    subjectData.sort((a, b) => (b["value"] as double).compareTo(a["value"] as double));

    if (subjectData.isEmpty) {
      return Container(
        height: 160,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: premiumCardBg, borderRadius: BorderRadius.circular(12)),
        child: Text("아직 집계된 학습시간 기록이 없습니다.", style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12)),
      );
    }

    final double overallAvg = subjectData.map((e) => e["value"] as double).reduce((a, b) => a + b) / subjectData.length;
    for (final item in subjectData) {
      item["avg"] = overallAvg;
    }

    double allMax = subjectData.map((e) => (e["value"] as double) > (e["avg"] as double) ? (e["value"] as double) : (e["avg"] as double)).reduce((a, b) => a > b ? a : b);
    double allMin = subjectData.map((e) => (e["value"] as double) < (e["avg"] as double) ? (e["value"] as double) : (e["avg"] as double)).reduce((a, b) => a < b ? a : b);

    double yMax = tabIndex == 0 ? allMax + 20.0 : allMax + 1.0;
    double yMin = tabIndex == 0 ? (allMin - 20.0).clamp(0.0, double.infinity) : (allMin - 1.0).clamp(0.0, double.infinity);
    double step = (yMax - yMin) / 3;
    List<String> yTicks = List.generate(4, (i) => "${(yMax - step * i).toStringAsFixed(tabIndex == 0 ? 0 : 1)}$unitLabel").toList();

    const double barW = 17.0;
    const double pairGap = 0.7;
    const double groupGap = 8.4; // 🆕 [요청] 과목 간 간격 40% 축소 (14 → 8.4)
    const double chartH = 190.0;

    int totalMinutes = subjectData.fold<int>(0, (sum, e) => sum + (e["value"] as double).round());

    final List<Color> subjectColors = [
      const Color(0xFFFF3B30),
      const Color(0xFF007AFF),
      const Color(0xFF34C759),
      const Color(0xFFFF9500),
      const Color(0xFFAF52DE),
      const Color(0xFFFFCC00),
    ];

    double calcBarH(double val) {
      double delta = (yMax - yMin) == 0 ? 1 : (yMax - yMin);
      // 🆕 [버그 수정] 막대가 꽉 차면 그 위의 숫자 라벨이 위쪽 밖으로 넘치던(overflow) 문제 -
      // 최대 높이를 85%로 제한해서 라벨이 들어갈 여유 공간을 항상 확보
      return ((val - yMin) / delta * chartH).clamp(2.0, chartH * 0.85);
    }

    // 🆕 [요청] "2)수학(A급) 집중 학습 (50분)"처럼 긴 원본 과목명을
    // "2)수학(A급)" / "집중 학습 50분" 두 줄로 자동 정리. "집중 학습" 표현이 없는
    // 과목명은 그대로 두고 화면에서 2줄까지만 허용(넘치면 말줄임).
    List<String> shortSubjectLines(String raw) {
      const marker = '집중 학습';
      final idx = raw.indexOf(marker);
      if (idx > 0) {
        final String line1 = raw.substring(0, idx).trim();
        String line2 = raw.substring(idx).trim();
        line2 = line2.replaceAllMapped(RegExp(r'\((\d+분)\)'), (m) => m.group(1)!);
        return [line1, line2];
      }
      return [raw];
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
                  Text("본인 과목 평균", style: GoogleFonts.notoSansKr(color: Colors.white60, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 6),
              // 🆕 [버그 수정] Y축(왼쪽 눈금)+막대 스크롤 영역을 Stack으로 감싸서, 병합 과정에서
              // 실수로 빠졌던 X축 기준선(0 높이 가로선)을 다시 그려 넣습니다.
              Stack(
                children: [
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
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(subjectData.length, (idx) {
                              final item = subjectData[idx];
                              double avgH = calcBarH((item["avg"] as double));
                              double valH = calcBarH((item["value"] as double));
                              Color col = subjectColors[idx % subjectColors.length];
                              final List<String> labelLines = shortSubjectLines(item["subject"] as String);
                              return Padding(
                                padding: EdgeInsets.only(left: groupGap),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
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
                                    const SizedBox(height: 6),
                                    // 🆕 [버그 수정] 라벨이 1줄이든 2줄이든 항상 같은 높이(28)를 차지하도록 고정 -
                                    // 라벨 줄 수가 다르면 Row(crossAxisAlignment:end) 때문에 막대 자체가
                                    // 위아래로 어긋나 보이던(연간 탭 맨 끝 "수학" 막대만 아래로 처짐) 문제 해결
                                    SizedBox(
                                      width: 64,
                                      height: 28,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: labelLines.map((line) => Text(
                                          line,
                                          textAlign: TextAlign.center,
                                          maxLines: labelLines.length > 1 ? 1 : 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, height: 1.25),
                                        )).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 🆕 [버그 수정] X축 기준선(0 높이 가로선) - Y축 눈금 컬럼(55) 바로 옆부터 오른쪽 끝까지,
                  // 막대 그래프 영역(chartH) 바닥과 정확히 일치하는 위치에 고정 표시
                  Positioned(
                    left: 57,
                    right: 0,
                    top: chartH,
                    child: Container(height: 2, color: brandGolden),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        const Divider(color: Colors.white10, height: 24),
        buildCustomSectionTitle("Subject Ratio", "[ 과목비율 ]", fontSize: 13.0),
        const SizedBox(height: 12),
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
                        painter: _ParentDashboardPiePainterComponent(subjectData: subjectData, colors: subjectColors),
                      ),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(color: premiumCardBg, shape: BoxShape.circle),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Total', style: GoogleFonts.gowunBatang(color: Colors.white38, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text("${totalMinutes}m", style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
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
                children: List.generate(subjectData.length, (idx) {
                  final item = subjectData[idx];
                  final int percent = totalMinutes > 0 ? (((item["value"] as double).round() / totalMinutes) * 100).round() : 0;
                  final Color col = subjectColors[idx % subjectColors.length];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3.0),
                          child: Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // 🆕 [버그 수정] 과목명이 길어 오른쪽으로 넘치던 문제 - Expanded + 2줄 허용으로 해결
                        Expanded(
                          child: Text(
                            "${shortSubjectLines(item["subject"] as String).join(' ')} ($percent%)",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
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

// 🆕 [실데이터 연동] 실제 subjectData(value 비중)에 맞춰 파이차트 조각을 그립니다.
class _ParentDashboardPiePainterComponent extends CustomPainter {
  final List<Map<String, dynamic>> subjectData;
  final List<Color> colors;

  _ParentDashboardPiePainterComponent({required this.subjectData, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = subjectData.fold<double>(0.0, (s, i) => s + (i["value"] as double));
    if (total == 0) return;

    final Paint p = Paint()..style = PaintingStyle.fill..isAntiAlias = true;
    double start = -math.pi / 2;

    for (int i = 0; i < subjectData.length; i++) {
      final double value = subjectData[i]["value"] as double;
      final double sweep = (value / total) * 2 * math.pi;
      p.color = colors[i % colors.length];
      canvas.drawArc(Rect.fromLTWH(0, 0, size.width, size.height), start, sweep, true, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) => true;
}
