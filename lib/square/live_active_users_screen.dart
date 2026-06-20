import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class LiveActiveUsersScreen extends StatefulWidget {
  const LiveActiveUsersScreen({Key? key}) : super(key: key);

  @override
  State<LiveActiveUsersScreen> createState() => _LiveActiveUsersScreenState();
}

class _LiveActiveUsersScreenState extends State<LiveActiveUsersScreen> {
  int _liveUserCount = 1287;
  Timer? _updateTimer;
  bool _isTimerRunning = true;

  @override
  void initState() {
    super.initState();
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _liveUserCount = 1280 + (math.Random().nextInt(15));
        });
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _showDetailPopup(BuildContext context, String title, String line1, String line2) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1527),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          side: BorderSide(color: Color(0xFFE5C158), width: 1.5),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(line1, textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: const Color(0xFFEFEFEF), fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(line2, textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Close (닫기)", style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgSpaceDark = Color(0xFF050B14);
    const Color cardSpaceDark = Color(0xFF0D1527);
    const Color brandGolden = Color(0xFFE5C158);
    const Color textWhite = Color(0xFFEFEFEF);

    return Scaffold(
      backgroundColor: bgSpaceDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 140, // 🎯 로고와 타이틀이 모두 여유롭고 예쁘게 들어가도록 높이 확보
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 👑 1. L부터 S까지 타이틀 라인을 예쁘게 감싸도록 배치한 정품 로고 이미지
            Image.asset(
              'assets/images/gsu_logo.png',
              width: 190, // 🎯 타이틀 너비와 시각적 밸런스를 맞추기 위해 정밀 스케일업
              height: 26,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 4), // 🎯 로고와 첫 줄 타이틀 사이 품격 있는 간격

            // 👑 2. 첫째 줄 영문 대문자 정중앙 타이틀 (Bold Serif 스타일)
            Text(
              'LIVE ACTIVE USERS',
              textAlign: TextAlign.center,
              style: GoogleFonts.gowunBatang(
                color: const Color(0xFFE5C158), // 황금색 현상태 유지
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 2),

            // 👑 3. 둘째 줄 한글 강조 타이틀 (노토산스 한글 및 크기 23 단일화 원칙 적용)
            Text(
              '동시 접속자',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(
                color: const Color(0xFFE5C158), // 지시사항 준수: 한글 타이틀 황금색 적용
                fontWeight: FontWeight.bold,
                fontSize: 23, // 8번 원칙: 한글 강조 타이틀 크기 23 단일화 엄격 준수
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    // 👑 [지시사항 2번 수호]: 영문 타이틀 크기를 한글과 동일한 16으로 웅장하게 확대!
                    // 📐 줄 터짐(Overflow) 방지 공학: 글자 간격(`letterSpacing`)을 최소화하여 넘침을 철벽 가두리!
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        "Global Live Studying Platform",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.gowunBatang(color: textWhite.withOpacity(0.6), fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2), // 크기 12 -> 16 / 간격 최소화
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "(현재도 전국 전세계 사람들 학습중입니다.)",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.gowunBatang(color: const Color(0xFFFFF6D6), fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // 1. Live Active Users (세계 현재 학습중)
              _buildCategoryWrapper(
                cardSpaceDark, brandGolden, "1. Live Active Users (세계 현재 학습중)",
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.circle, color: Color(0xFF1DD1A1), size: 12),
                        const SizedBox(width: 8),
                        Text(
                          "$_liveUserCount Users Studying",
                          style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 28, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "(현재 $_liveUserCount명 학습중) ==> 실시간 갱신",
                      style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 14.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // 2. Friends Studying New (현재 학습중인 친구)
              _buildCategoryWrapper(
                cardSpaceDark, brandGolden, "2. Friends Studying New\n(현재 학습중인 친구)",
                Column(
                  children: [
                    _buildFriendOverflowRow(context, _isTimerRunning, "이규현 (Lee Kyu-hyun)", "3시간 22분 (3h 22m)"),
                    const Divider(color: Colors.white10, height: 20),
                    _buildFriendOverflowRow(context, _isTimerRunning, "심유빈 (Sim Yu-bin)", "1시간 08분 (1h 08m)"),
                    const Divider(color: Colors.white10, height: 20),
                    _buildFriendOverflowRow(context, false, "김승훈 (Kim Seung-hoon)", "2시간 15분 (2h 15m)"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text("Timer Status Control: ", style: TextStyle(color: Colors.white30, fontSize: 11)),
                        Switch(
                          value: _isTimerRunning,
                          activeColor: const Color(0xFF1DD1A1),
                          inactiveThumbColor: Colors.grey,
                          onChanged: (val) => setState(() => _isTimerRunning = val),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              // 3. My Ranking (내 순위)
              _buildCategoryWrapper(
                cardSpaceDark, brandGolden, "3. My Ranking (내 순위)",
                InkWell(
                  onTap: () => _showDetailPopup(context, "My Ranking (내 순위)", "Current Rank: 156", "Total Users: 15,789명"),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Current Rank", style: GoogleFonts.gowunBatang(color: textWhite, fontSize: 15, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          "156 / 15,789 Users (156위/15,789명)...",
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Today's Live Ranking (오늘 실시간 랭킹)
              _buildCategoryWrapper(
                cardSpaceDark, brandGolden, "4. Today's Live Ranking\n(오늘 실시간 랭킹)",
                Column(
                  children: [
                    _buildMedalOverflowRow(context, "🥇 Gold Medal (금메달)", "이규현 (Lee Kyu-hyun)", "4시간 12분 (4h 12m)", const Color(0xFFF1C40F)),
                    const SizedBox(height: 12),
                    _buildMedalOverflowRow(context, "🥈 Silver Medal (은메달)", "심유빈 (Sim Yu-bin)", "3시간 58분 (3h 58m)", const Color(0xFFBDC3C7)),
                    const SizedBox(height: 12),
                    _buildMedalOverflowRow(context, "🥉 Bronze Medal (동메달)", "김승훈 (Kim Seung-hoon)", "3시간 57분 (3h 57m)", const Color(0xFFE67E22)),
                  ],
                ),
              ),

              // 6. Today's Popular Targets (오늘의 인기 목표)
              _buildCategoryWrapper(
                cardSpaceDark, brandGolden, "6. Today's Popular Targets\n(오늘의 인기 목표)",
                Column(
                  children: [
                    _buildPopularTargetRow(brandGolden, "1", "Seoul National University (서울대학교)"),
                    _buildPopularTargetRow(brandGolden, "2", "Medical Doctor (의사)"),
                    _buildPopularTargetRow(brandGolden, "3", "TOEIC 900 (토익 900)"),
                    _buildPopularTargetRow(brandGolden, "4", "Public Official (공무원)"),
                    _buildPopularTargetRow(brandGolden, "5", "Police Officer (경찰)"),
                  ],
                ),
              ),

              // 7. Today's Global Statistics (오늘의 전체 통계)
              _buildCategoryWrapper(
                cardSpaceDark, brandGolden, "7. Today's Global Statistics\n(오늘의 전체 통계)",
                Column(
                  children: [
                    _buildStatsOverflowRow(context, textWhite, brandGolden, "Total Study Time (총 학습시간)", "23,345/h"),
                    const Divider(color: Colors.white10, height: 16),
                    _buildStatsOverflowRow(context, textWhite, brandGolden, "Total Stars Collected (총 획득 별)", "1,187,520 ✨"),
                    const Divider(color: Colors.white10, height: 16),
                    _buildStatsOverflowRow(context, textWhite, brandGolden, "Target Achieved (목표 달성)", "1,532 Users (1,532명)"),
                  ],
                ),
              ),

              // 8. Real-time Achievement Alerts (실시간 성취 알림)
              _buildCategoryWrapper(
                cardSpaceDark, brandGolden, "8. Real-time Achievement Alerts\n(실시간 성취 알림)",
                Column(
                  children: [
                    _buildAlertOverflowRow(context, "⭐", "Kim○○ has reached Lv.10 (김○○님 Lv.10 달성)"),
                    const SizedBox(height: 10),
                    _buildAlertOverflowRow(context, "🔥", "Park○○ achieved 30 days consecutive study (박○○님 30일 연속 학습)"),
                    const SizedBox(height: 10),
                    _buildAlertOverflowRow(context, "👑", "Lee○○ collected 1,000 stars (이○○님 별 1,000개 달성)"),
                  ],
                ),
              ),

              // 9. Global Total Subject Ratio (세계 총 과목비율)
              _buildCategoryWrapper(
                cardSpaceDark, brandGolden, "9. Global Total Subject Ratio\n(세계 총 과목비율)",
                Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(color: const Color(0xFFFF4D4D), value: 35, title: '35%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                PieChartSectionData(color: const Color(0xFFFF9F43), value: 25, title: '25%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                PieChartSectionData(color: const Color(0xFFFECA57), value: 19, title: '19%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                PieChartSectionData(color: const Color(0xFF1DD1A1), value: 12, title: '12%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                PieChartSectionData(color: const Color(0xFF54A0FF), value: 10, title: '10%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4.0),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.star, color: brandGolden, size: 32);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildRatioLegendRow(const Color(0xFFFF4D4D), "Mathematics (수학)", "35%"),
                    _buildRatioLegendRow(const Color(0xFFFF9F43), "English (영어)", "25%"),
                    _buildRatioLegendRow(const Color(0xFFFECA57), "Native Language (자국어)", "19%"),
                    _buildRatioLegendRow(const Color(0xFF1DD1A1), "Science (과학)", "12%"),
                    _buildRatioLegendRow(const Color(0xFF54A0FF), "Others (기타)", "10%"),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryWrapper(Color cardBg, Color golden, String title, Widget content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20.0),
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: golden.withOpacity(0.25), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.gowunBatang(color: golden, fontSize: 15, fontWeight: FontWeight.w900, height: 1.3),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Divider(color: Colors.white12, height: 1)),
          const SizedBox(height: 6),
          content,
        ],
      ),
    );
  }

  Widget _buildFriendOverflowRow(BuildContext context, bool isRunning, String name, String time) {
    return InkWell(
      onTap: () => _showDetailPopup(context, isRunning ? "Studying (학습중)" : "Resting (휴식중)", name, time),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRunning ? const Color(0xFF54A0FF) : Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$name - ${isRunning ? '학습중' : '휴식중'}",
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.gowunBatang(color: const Color(0xFFEFEFEF), fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "${time.substring(0, math.min(8, time.length))}...",
            style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMedalOverflowRow(BuildContext context, String medalTitle, String name, String time, Color medalColor) {
    return InkWell(
      onTap: () => _showDetailPopup(context, medalTitle, "Ranker: $name", "Time: $time"),
      child: Row(
        children: [
          Text(medalTitle.split(" ")[0], style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            time,
            style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 13.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverflowRow(BuildContext context, Color textWhite, Color golden, String title, String value) {
    return InkWell(
      onTap: () => _showDetailPopup(context, "Global Statistics Detail", title, value),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.gowunBatang(color: textWhite, fontSize: 13.5, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 15),
          Text(
            value,
            style: GoogleFonts.gowunBatang(color: golden, fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertOverflowRow(BuildContext context, String icon, String systemText) {
    return InkWell(
      onTap: () => _showDetailPopup(context, "System Achievement Alert", "Notification", systemText),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              systemText,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularTargetRow(Color golden, String rank, String targetName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        children: [
          Text("$rank.", style: GoogleFonts.gowunBatang(color: golden, fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(width: 12),
          Expanded(child: Text(targetName, style: GoogleFonts.gowunBatang(color: const Color(0xFFEFEFEF), fontSize: 14.5, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildRatioLegendRow(Color color, String subjectName, String percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 12),
          Expanded(child: Text(subjectName, style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold))),
          Text(percentage, style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 14, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}