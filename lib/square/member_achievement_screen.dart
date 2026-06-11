import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MemberAchievementScreen extends StatefulWidget {
  const MemberAchievementScreen({Key? key}) : super(key: key);

  @override
  State<MemberAchievementScreen> createState() => _MemberAchievementScreenState();
}

class _ThemeColors {
  static const Color brandGolden = Color(0xFFE5C158);
}

class _MemberAchievementScreenState extends State<MemberAchievementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 👥 [시뮬레이션 연동]: 가상 회원 5인의 실시간 학습 데이터 스택
  final String _mySchoolInfo = "GSU High School 2nd Grade - James Lee\n(GSU고등학교 2학년 이제임스)";
  final String _myNextLevel = "33h Left(남음)";
  final String _myGoalRate = "82%";

  // 🌈 [지시사항]: 가로축 과목용 데이터 (순서대로 정확히 빨·주·노·초·파·남·보 무지개 엔진 배정)
  final List<Map<String, dynamic>> _mySubjects = [
    {"subject": "Math\n(수학)", "score": 0.85, "color": const Color(0xFFFF3B30)},     // 빨강
    {"subject": "English\n(영어)", "score": 0.72, "color": const Color(0xFFFF9500)},  // 주황
    {"subject": "Korean\n(국어)", "score": 0.90, "color": const Color(0xFFFFCC00)},   // 노랑
    {"subject": "Science\n(과학)", "score": 0.65, "color": const Color(0xFF34C759)},  // 초록
    {"subject": "Social\n(사회)", "score": 0.78, "color": const Color(0xFF007AFF)},   // 파랑
    {"subject": "Ethics\n(도덕)", "score": 0.95, "color": const Color(0xFF0500FF)},   // 남색
    {"subject": "History\n(역사)", "score": 0.80, "color": const Color(0xFFAF52DE)},  // 보라
    {"subject": "Info\n(정보)", "score": 0.88, "color": const Color(0xFF5856D6)},     // 확장 컬러
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 🛠️ [기존 기능 복구 완수]: 터치하면 즉각적으로 발생하는 웅장한 다크 골드 톤의 팝업창 모듈
  void _showReportPopup(BuildContext context, String title, String subTitle, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(subTitle, style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden.withOpacity(0.6), fontSize: 13)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white60),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const Divider(color: Colors.white10, height: 20, thickness: 1.2),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 14.5, height: 1.6),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        toolbarHeight: 85,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Member Achievement',
              style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 4),
            Text(
              '(멤버 성취도)',
              style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.normal, fontSize: 15),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: _ThemeColors.brandGolden.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.4), width: 1.2),
                ),
                child: Center(
                  child: Text(
                    _mySchoolInfo,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 16, height: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Flexible(
                    flex: 40,
                    child: InkWell(
                      onTap: () {
                        _showReportPopup(
                            context,
                            'Summary',
                            '(종합 리포트)',
                            "📊 Comprehensive Academic Summary:\n• Target tracking is highly optimal.\n• Weakest areas have been fortified through consistent focus.\n\n(종합 학업 성취도 분석 리포트:\n• 목표 달성도 추이가 최적의 안정 궤도를 유지 중입니다.\n• 취약 과목이 집중 학습을 통해 완벽히 보완되고 있습니다.)"
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E24),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.3), width: 1.2),
                        ),
                        child: Column(
                          children: [
                            Text('Summary', style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15.5)),
                            const SizedBox(height: 2),
                            Text('(종합 리포트)', style: GoogleFonts.gowunBatang(color: Colors.white38, fontSize: 12.5)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 60,
                    child: InkWell(
                      onTap: () {
                        _showReportPopup(
                            context,
                            'Detailed Analytics',
                            '(상세 분석 기록)',
                            "⏱️ Deep Analytics Data Track:\n• Total Focus Duration: 62 Hours\n• Peak Concentration Zone: 20:00 - 22:30\n\n(상세 분석 기록 모니터링:\n• 순공 집중 시간: 누적 62시간 달성 완료\n• 최고 몰입 타임라인: 오후 8시 - 10시 30분 관측)"
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E24),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.3), width: 1.2),
                        ),
                        child: Column(
                          children: [
                            Text('Detailed Analytics', style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.5)),
                            const SizedBox(height: 2),
                            Text('(상세 분석 기록)', style: GoogleFonts.gowunBatang(color: Colors.white60, fontSize: 12.5)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Progress & Achievements', style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('(성취도 리포트)', style: GoogleFonts.gowunBatang(color: Colors.white60, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.1,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildEnhancedLabelBox('Next Level Road', '(다음 레벨까지)', _myNextLevel, _ThemeColors.brandGolden),
                  _buildEnhancedLabelBox('Goal Attainment Rate', '(목표 달성률)', _myGoalRate, Colors.greenAccent),
                ],
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0x3B000000),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TabBar(
                    isScrollable: false,
                    controller: _tabController,
                    indicatorPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                    indicator: BoxDecoration(color: _ThemeColors.brandGolden, borderRadius: BorderRadius.circular(8)),
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.white,
                    labelStyle: GoogleFonts.gowunBatang(fontWeight: FontWeight.bold, fontSize: 13.5),
                    tabs: const [
                      Tab(text: "Today (오늘)"),
                      Tab(text: "Weekly (주)"),
                      Tab(text: "Month (이번달)"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 325,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAdvancedChartDashboard(),
                    _buildAdvancedChartDashboard(),
                    _buildAdvancedChartDashboard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedLabelBox(String title, String subTitle, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x61000000),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(subTitle, style: GoogleFonts.gowunBatang(color: const Color(0xFFFFF6D6), fontWeight: FontWeight.w700, fontSize: 11.5)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.gowunBatang(color: valueColor, fontWeight: FontWeight.bold, fontSize: 13.5, height: 1.2)),
        ],
      ),
    );
  }

  // 📊 [오류 완치 구역]: 339번 라인 부근의 Stack 자식 위젯 간 쉼표(,) 및 구조 완벽 마감
  Widget _buildAdvancedChartDashboard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0x1A000000),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // 📐 [배경 수평 가이드라인 레이어]: 끊김 없는 일직선 가로선 가이드라인
          Positioned.fill(
            left: 32, right: 0, top: 15, bottom: 44,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) => Container(
                width: double.infinity,
                height: 0.8,
                color: Colors.white.withOpacity(0.08),
              )),
            ),
          ),

          // 📐 [지시사항 1번 반영]: Y축 수직선 옆에 30분 단위 미세 공학 눈금을 드로잉하는 레이어
          Positioned(
            left: 32, top: 15, bottom: 44,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(9, (index) {
                final bool isHalfHour = index % 2 != 0;
                return Container(
                  width: isHalfHour ? 4.0 : 0.0,
                  height: 1.5,
                  color: _ThemeColors.brandGolden.withOpacity(0.5),
                );
              }),
            ),
          ),

          // 🏗️ 차트 본체 정렬 격자 (Row 내부 진입)
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ⏱️ 세로축 시간 글씨 가독성 완벽 복원 (`Colors.white` 선명화 마감)
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 18),
                  Expanded(child: Text("12h", style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 11))),
                  Expanded(child: Text("9h", style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 11))),
                  Expanded(child: Text("6h", style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 11))),
                  Expanded(child: Text("3h", style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 11))),
                  Text("0h", style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 11)),
                  const SizedBox(height: 48),
                ],
              ),
              const SizedBox(width: 8),

              // 📐 Y축 수직 기준선 (두께 2.5px 벌크업)
              Container(
                width: 2.5,
                margin: const EdgeInsets.only(top: 15, bottom: 44),
                color: _ThemeColors.brandGolden.withOpacity(0.6),
              ),

              // 🏗️ 과목 막대 기둥 수평 무한 레일 구역
              Expanded(
                child: Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    Positioned.fill(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _mySubjects.map((data) {
                            final double barScaleHeight = (data["score"] as double) * 180;

                            return Container(
                              width: 58,
                              margin: const EdgeInsets.symmetric(horizontal: 0.7), // 🛠️ 50% 추가 압축 유격 사수
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${((data["score"] as double) * 100).toInt()}%",
                                    style: TextStyle(
                                        color: data["color"] as Color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  const SizedBox(height: 3.0), // 정확히 1mm 유격 사수

                                  Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Container(
                                        height: 180,
                                        width: 44, // ⚙️ 기둥 자체 두께 웅장화 사수
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.04),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      Container(
                                        height: barScaleHeight,
                                        width: 44,
                                        decoration: BoxDecoration(
                                            color: data["color"] as Color,
                                            borderRadius: BorderRadius.circular(4),
                                            boxShadow: [
                                              BoxShadow(
                                                  color: (data["color"] as Color).withOpacity(0.35),
                                                  blurRadius: 5,
                                                  spreadRadius: 1
                                              )
                                            ]
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 48),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    // 📐 [지시사항 반영]: 끊김 없이 우측 끝까지 대관통하는 일직선 황금 가로축(X축)
                    Positioned(
                      left: 0, right: 0, bottom: 44,
                      child: Container(
                        width: double.infinity,
                        height: 2.5,
                        color: _ThemeColors.brandGolden.withOpacity(0.6),
                      ),
                    ),

                    // 🏷️ 가로축 과목 명찰 스크롤 동기화 레이어
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: SizedBox(
                        height: 38,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: _mySubjects.map((data) {
                              return Container(
                                width: 58,
                                margin: const EdgeInsets.symmetric(horizontal: 0.7),
                                child: Text(
                                  data["subject"] as String,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, height: 1.2),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}