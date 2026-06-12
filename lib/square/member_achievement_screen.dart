import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class MemberAchievementScreen extends StatefulWidget {
  const MemberAchievementScreen({Key? key}) : super(key: key);

  @override
  State<MemberAchievementScreen> createState() => _MemberAchievementScreenState();
}

class _ThemeColors {
  static const Color brandGolden = Color(0xFFE5C158);
  static const Color luxuryDarkBg = Color(0xFF141414);
  static const Color premiumCardBg = Color(0xFF1E1E24);
}

class _MemberAchievementScreenState extends State<MemberAchievementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _warningAnimController;
  late Animation<double> _warningAnimation;

  // 👥 [홈 대시보드 연동 기틀 마스터 스택]
  final String _mySchoolInfo = "GSU High School 2nd Grade - James Lee\n(GSU고등학교 2학년 이제임스)";
  final String _currentLevel = "Lv.26";
  final String _myStars = "12,580";

  // 🏆 랭킹 시스템 스택 매핑
  final String _friendRankEn = "Friend Rank: 3rd";
  final String _friendRankKr = "(친구 랭킹: 3위)";
  final String _globalRankEn = "Global Rank: Top 1.2%";
  final String _globalRankKr = "(전 세계 랭킹: 상위 1.2%)";

  // 🏫 목표 대학 표기 체계 (좌측 정렬 사수)
  final String _targetUniTitle = "Target:";
  final String _targetUniEn = "Seoul National University";
  final String _targetUniKr = "(목표: 서울대학교)";

  // 📈 성장 지표 스택 [영문 완벽 동기화 완료]
  final String _myGoalRate = "90%";
  final String _streakEn = "Streak: 56 Days";
  final String _streakKr = "(연속 학습일: 56일)";
  final String _totalHoursEn = "Total Focus: 1,257/h";
  final String _totalHoursKr = "(총 학습: 1,257/h)";
  final String _growthRate = "Progress: +20% vs Yesterday\n(어제 대비 오늘 +20%)";
  final String _bestGrowthSubject = "Most Improved: English\n(가장 성장한 과목: 영어)";
  final String _mostStudiedSubjectEn = "Most Studied:";
  final String _mostStudiedSubjectKr = "Math (수학)";

  // 🌈 무지개 컬러 팔레트 표준 체계
  final List<Color> _todayColors = [
    const Color(0xFFFF3B30), const Color(0xFFFF9500), const Color(0xFFFFCC00),
    const Color(0xFF34C759), const Color(0xFF007AFF), const Color(0xFF0500FF),
    const Color(0xFFAF52DE), const Color(0xFF5856D6),
  ];

  final List<Color> _weeklyColors = [
    const Color(0xFF34C759), const Color(0xFF0500FF), const Color(0xFF007AFF),
    const Color(0xFFAF52DE), const Color(0xFFFF3B30), const Color(0xFFFF9500),
    const Color(0xFFFFCC00), const Color(0xFF5856D6),
  ];

  // 👥 [실시간 데이터 허브]: 공부 과목 마스터 데이터 소스
  final List<Map<String, dynamic>> _masterSubjectData = [
    {"subject": "Math\n(수학)", "score": 0.85, "averageScore": 0.65, "hasStudiedToday": true, "hasStudiedWeekly": true, "hasStudiedMonthly": true, "baseMinutes": 120, "isStarEligible": true},
    {"subject": "English\n(영어)", "score": 0.72, "averageScore": 0.70, "hasStudiedToday": true, "hasStudiedWeekly": true, "hasStudiedMonthly": true, "baseMinutes": 90, "isStarEligible": true},
    {"subject": "Korean\n(국어)", "score": 0.90, "averageScore": 0.58, "hasStudiedToday": false, "hasStudiedWeekly": true, "hasStudiedMonthly": true, "baseMinutes": 80, "isStarEligible": true},
    {"subject": "Science\n(과학)", "score": 0.65, "averageScore": 0.60, "hasStudiedToday": false, "hasStudiedWeekly": true, "hasStudiedMonthly": true, "baseMinutes": 70, "isStarEligible": true},
    {"subject": "Social\n(사회)", "score": 0.78, "averageScore": 0.75, "hasStudiedToday": false, "hasStudiedWeekly": false, "hasStudiedMonthly": true, "baseMinutes": 60, "isStarEligible": true},
    {"subject": "Ethics\n(도덕)", "score": 0.95, "averageScore": 0.80, "hasStudiedToday": false, "hasStudiedWeekly": false, "hasStudiedMonthly": true, "baseMinutes": 50, "isStarEligible": true},
    {"subject": "History\n(역사)", "score": 0.80, "averageScore": 0.62, "hasStudiedToday": false, "hasStudiedWeekly": false, "hasStudiedMonthly": true, "baseMinutes": 45, "isStarEligible": true},
    {"subject": "Info\n(정보)", "score": 0.88, "averageScore": 0.68, "hasStudiedToday": false, "hasStudiedWeekly": false, "hasStudiedMonthly": true, "baseMinutes": 40, "isStarEligible": true},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() { if (!_tabController.indexIsChanging) setState(() {}); });
    _warningAnimController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)..repeat(reverse: true);
    _warningAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(CurvedAnimation(parent: _warningAnimController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _warningAnimController.dispose();
    super.dispose();
  }

  void _showReportPopup(BuildContext context, String title, String subTitle, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _ThemeColors.premiumCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.3), width: 1.5)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(subTitle, style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden.withOpacity(0.6), fontSize: 13)),
                    ]),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white60), onPressed: () => Navigator.pop(context))
                  ],
                ),
                const Divider(color: Colors.white10, height: 20, thickness: 1.2),
                Text(content, style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 14.5, height: 1.6)),
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
      backgroundColor: _ThemeColors.luxuryDarkBg,
      appBar: AppBar(
        backgroundColor: _ThemeColors.luxuryDarkBg,
        elevation: 0,
        toolbarHeight: 80,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Member Achievement', style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 21)),
          const SizedBox(height: 2),
          Text('(멤버 성취도)', style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.normal, fontSize: 14)),
        ]),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(color: _ThemeColors.brandGolden.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.35), width: 1.2)),
                child: Center(child: Text(_mySchoolInfo, textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 14.5, height: 1.35))),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  _buildTopButton('Summary', '(종합 리포트)', 40, "📊 Comprehensive Academic Summary:\n• Target tracking is highly optimal.\n• Weakest areas have been fortified through consistent focus.\n\n(종합 학업 성취도 분석 리포트:\n• 목표 달성도 추이가 최적의 안정 궤도를 유지 중입니다.\n• 취약 과목이 집중 학습을 통해 완벽히 보완되고 있습니다.)"),
                  const SizedBox(width: 8),
                  _buildTopButton('Detailed Analytics', '(상세 분석 기록)', 60, "⏱️ Deep Analytics Data Track:\n• Total Focus Duration: 62 Hours\n• Peak Concentration Zone: 20:00 - 22:30\n\n(상세 분석 기록 모니터링:\n• 순공 집중 시간: 누적 62시간 달성 완료\n• 최고 몰입 타임라인: 오후 8시 - 10시 30분 관측)"),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🎇 좌측 패널: 295px 및 글자 크기/정렬 동기화
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      height: 295,
                      decoration: BoxDecoration(
                        color: const Color(0x61000000),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.25), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Next Level Road', style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 14.0, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(color: _ThemeColors.brandGolden, borderRadius: BorderRadius.circular(4)),
                                // 🚨 [오타 완전 세척]: 기존의 'Colors Black' 오타를 'Colors.black' 점을 찍어 완벽하게 수리 완료!
                                child: Text(_currentLevel, style: GoogleFonts.gowunBatang(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              _buildLuxuryGlowingStar(),
                              const SizedBox(width: 6),
                              Text(_myStars, style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 16.0)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_friendRankEn, style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                              Text(_friendRankKr, style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(_globalRankEn, style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontSize: 12.5, fontWeight: FontWeight.bold)),
                              Text(_globalRankKr, style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden.withOpacity(0.8), fontSize: 11.5, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                            decoration: BoxDecoration(color: const Color(0x2AFFFFFF), borderRadius: BorderRadius.circular(4)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_targetUniTitle, style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 11.5)),
                                const SizedBox(height: 2),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_targetUniEn, style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.0), overflow: TextOverflow.ellipsis),
                                      Text(_targetUniKr, style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.w700, fontSize: 10.5), overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 🎇 우측 패널: 영문 완벽 표기 및 295px 수직 동기화 사수
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      height: 295,
                      decoration: BoxDecoration(
                        color: const Color(0x61000000),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.25), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Goal Attainment', style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 14.0, fontWeight: FontWeight.bold)),
                              Text(_myGoalRate, style: GoogleFonts.gowunBatang(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16.5)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_streakEn, style: GoogleFonts.gowunBatang(color: const Color(0xFFFFF6D6), fontSize: 12.5, fontWeight: FontWeight.bold)),
                              Text(_streakKr, style: GoogleFonts.gowunBatang(color: const Color(0xFFFFF6D6).withOpacity(0.8), fontSize: 11.5, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(_totalHoursEn, style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                              Text(_totalHoursKr, style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(color: const Color(0x1F34C759), borderRadius: BorderRadius.circular(6)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_growthRate, style: GoogleFonts.gowunBatang(color: Colors.greenAccent, fontSize: 11.0, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 3),
                                Text(_bestGrowthSubject, style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 3),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(text: "$_mostStudiedSubjectEn ", style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w500)),
                                      TextSpan(text: "\n$_mostStudiedSubjectKr", style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontSize: 11.0, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 👑 [순정 탭바]
              Container(
                width: double.infinity, height: 38,
                decoration: BoxDecoration(color: const Color(0x3B000000), borderRadius: BorderRadius.circular(8)),
                child: TabBar(
                  controller: _tabController,
                  indicatorPadding: const EdgeInsets.symmetric(horizontal: 0.5, vertical: 2.5),
                  indicator: BoxDecoration(color: _ThemeColors.brandGolden, borderRadius: BorderRadius.circular(6)),
                  labelColor: Colors.black, unselectedLabelColor: Colors.white,
                  labelStyle: GoogleFonts.gowunBatang(fontWeight: FontWeight.bold, fontSize: 12.5),
                  tabs: const [Tab(text: "Today(오늘)"), Tab(text: "Weekly(주)"), Tab(text: "Month(이번달)")],
                ),
              ),
              const SizedBox(height: 12),

              _buildAdvancedChartDashboard(_tabController.index),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopButton(String t1, String t2, int flex, String contentText) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => _showReportPopup(context, t1, t2, contentText),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: _ThemeColors.premiumCardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.3))),
          child: Column(children: [
            Text(t1, style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 13.5)),
            Text(t2, style: GoogleFonts.gowunBatang(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11.0)),
          ]),
        ),
      ),
    );
  }

  Widget _buildLuxuryGlowingStar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: _ThemeColors.brandGolden.withOpacity(0.7), blurRadius: 6, spreadRadius: 2.0),
            ],
          ),
        ),
        const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 15),
      ],
    );
  }

  Widget _buildAdvancedChartDashboard(int tabIndex) {
    List<Map<String, dynamic>> targetSubjects = [];

    if (tabIndex == 0) {
      targetSubjects = _masterSubjectData.where((e) => e["hasStudiedToday"] == true).toList();
    } else if (tabIndex == 1) {
      targetSubjects = _masterSubjectData.where((e) => e["hasStudiedWeekly"] == true).toList();
    } else {
      targetSubjects = _masterSubjectData.where((e) => e["hasStudiedMonthly"] == true).toList();
    }

    List<Color> colorPalette = (tabIndex == 1) ? _weeklyColors : _todayColors;
    List<String> yAxisLabels = (tabIndex == 0) ? ["5h", "4h", "3h", "2h", "1h", "0h"] : (tabIndex == 1) ? ["35h", "30h", "25h", "20h", "15h", "7h", "0h"] : ["120h", "90h", "60h", "30h", "10h", "0h"];

    double timeMultiplier = (tabIndex == 0) ? 1.0 : (tabIndex == 1) ? 5.0 : 22.0;

    int totalMinutes = targetSubjects.fold<int>(0, (sum, item) {
      return sum + ((item["baseMinutes"] as int) * timeMultiplier).round();
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 240,
          child: Stack(
            children: [
              Positioned(left: 45, top: 0, child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 5),
                Text("Average(평균)", style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold)),
              ])),
              Positioned.fill(left: 36, right: 0, top: 25, bottom: 44, child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(yAxisLabels.length, (i) => Container(width: double.infinity, height: 0.8, color: Colors.white.withOpacity(0.08))))),
              Positioned(left: 36, top: 25, bottom: 44, child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate((yAxisLabels.length * 2) - 1, (i) => Container(width: i % 2 != 0 ? 4.0 : 0.0, height: 1.5, color: _ThemeColors.brandGolden.withOpacity(0.4))))),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 28, child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const SizedBox(height: 22),
                    ...yAxisLabels.take(yAxisLabels.length - 1).map((l) => Expanded(child: Text(l, style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 10)))),
                    Text(yAxisLabels.last, style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 10)),
                    const SizedBox(height: 48),
                  ])),
                  const SizedBox(width: 8),
                  Container(width: 2.2, margin: const EdgeInsets.only(top: 25, bottom: 44), color: _ThemeColors.brandGolden.withOpacity(0.6)),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.bottomLeft,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(targetSubjects.length, (index) {
                              final data = targetSubjects[index];
                              const double hMax = 100.0;
                              final Color pCol = colorPalette[index % colorPalette.length];
                              return Container(
                                width: 52, margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                child: Column(mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                                  SizedBox(height: hMax + 16, width: 52, child: Stack(alignment: Alignment.bottomCenter, children: [
                                    Positioned(
                                      left: 8, bottom: 0,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text("${(data["averageScore"] * 100).toInt()}%", style: const TextStyle(color: Colors.white54, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                          Container(height: data["averageScore"] * hMax, width: 18, decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: const BorderRadius.vertical(top: Radius.circular(2.5)))),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      left: 26, bottom: 0,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text("${(data["score"] * 100).toInt()}%", style: TextStyle(color: pCol, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                          Container(height: data["score"] * hMax, width: 18, decoration: BoxDecoration(color: pCol, borderRadius: const BorderRadius.vertical(top: Radius.circular(2.5)))),
                                        ],
                                      ),
                                    ),
                                  ])),
                                  const SizedBox(height: 8),
                                  SizedBox(height: 36, child: Text(data["subject"], textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1.2))),
                                ]),
                              );
                            }),
                          ),
                        ),
                        Positioned(left: 0, right: 0, bottom: 44, child: Container(width: double.infinity, height: 2.2, color: _ThemeColors.brandGolden.withOpacity(0.6))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white10, height: 16),

        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Comprehensive Life Balance', style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 14.5)),
          Text('(오늘/주/이번달 종합 생활 균형 밸런스)', style: GoogleFonts.gowunBatang(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 11.0)),
        ]),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 50,
              child: Center(
                child: SizedBox(
                  width: 170, height: 170,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(170, 170),
                        painter: _GsuPiePainter(targetSubjects: targetSubjects, colors: colorPalette, multiplier: timeMultiplier),
                      ),
                      Container(width: 80, height: 80, decoration: const BoxDecoration(color: Color(0xFF1E1E24), shape: BoxShape.circle), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('Total', style: GoogleFonts.gowunBatang(color: Colors.white38, fontSize: 9.5)),
                        Text("${totalMinutes}/m", style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 13.0)),
                      ])),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(targetSubjects.length, (idx) {
                  final item = targetSubjects[idx];
                  final int calculatedMin = ((item["baseMinutes"] as int) * timeMultiplier).round();
                  final int percent = totalMinutes > 0 ? ((calculatedMin / totalMinutes) * 100).round() : 0;
                  final Color c = colorPalette[idx % colorPalette.length];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                    child: Row(
                      children: [
                        Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text("${item["subject"].toString().replaceAll('\n', ' ')}  $percent%", style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                          Text(item["isStarEligible"] ? "✨ +${calculatedMin} Stars" : "🚫 No Stars", style: GoogleFonts.gowunBatang(color: item["isStarEligible"] ? _ThemeColors.brandGolden.withOpacity(0.8) : Colors.white38, fontSize: 9.0)),
                        ])),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (targetSubjects.isEmpty)
          AnimatedBuilder(
            animation: _warningAnimation,
            builder: (c, child) => Transform.translate(offset: Offset(0, _warningAnimation.value), child: child),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF2C2514), borderRadius: BorderRadius.circular(8), border: Border.all(color: _ThemeColors.brandGolden, width: 1.2)),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: _ThemeColors.brandGolden, size: 18),
                const SizedBox(width: 8),
                Text("Warning: Database Sync Delay. Retrying...\n(경고: 데이터베이스 동기화 지연. 재시도 중...)", style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
      ],
    );
  }
}

class _GsuPiePainter extends CustomPainter {
  final List<Map<String, dynamic>> targetSubjects;
  final List<Color> colors;
  final double multiplier;

  _GsuPiePainter({required this.targetSubjects, required this.colors, required this.multiplier});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = targetSubjects.fold<double>(0.0, (s, i) => s + ((i["baseMinutes"] as int) * multiplier).toDouble());
    if (total == 0) return;

    final Paint p = Paint()..style = PaintingStyle.fill..isAntiAlias = true;
    double start = -math.pi / 2;

    for (int i = 0; i < targetSubjects.length; i++) {
      final double calculatedMin = ((targetSubjects[i]["baseMinutes"] as int) * multiplier).toDouble();
      final double sweep = (calculatedMin / total) * 2 * math.pi;
      p.color = colors[i % colors.length];
      canvas.drawArc(Rect.fromLTWH(0, 0, size.width, size.height), start, sweep, true, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) => true;
}