import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MemberAchievementScreen extends StatefulWidget {
  const MemberAchievementScreen({Key? key}) : super(key: key);

  @override
  State<MemberAchievementScreen> createState() => _MemberAchievementScreenState();
}

class _MemberAchievementScreenState extends State<MemberAchievementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 👥 [원장님 지시사항 반영]: 타인은 전부 제외하고, 로그인한 '나'의 인적사항 및 과목 데이터만 단독 고정
  final String _mySchoolInfo = "GSU High School 2nd Grade - James Lee\n(GSU고등학교 2학년 이제임스)";
  final String _myNextLevel = "(33h 남음)";
  final String _myGoalRate = "🎯 82%";

  // 📖 홈 대시보드 과목 생성 기능과 훗날 실시간 결합될 개인 독점 과목 스택
  final List<Map<String, dynamic>> _mySubjects = [
    {"subject": "Math (수학)", "score": 0.85, "color": const Color(0xFFE5C158)},
    {"subject": "English (영어)", "score": 0.72, "color": const Color(0xFF00F0FF)},
    {"subject": "Korean (국어)", "score": 0.90, "color": Colors.white},
    {"subject": "Science (과학)", "score": 0.65, "color": Colors.greenAccent},
    {"subject": "Social (사회)", "score": 0.78, "color": Colors.orangeAccent},
    {"subject": "Ethics (도덕)", "score": 0.95, "color": Colors.purpleAccent},
    {"subject": "History (역사)", "score": 0.80, "color": Colors.blueAccent},
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

  @override
  Widget build(BuildContext context) {
    const Color brandGolden = Color(0xFFE5C158);

    return Scaffold(
      backgroundColor: const Color(0xFF141414), // 홈 대시보드 다크 톤앤매너 100% 일치
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
              style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 21),
            ),
            const SizedBox(height: 4),
            Text(
              '(멤버 성취도)',
              style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.normal, fontSize: 14),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👑 [개인 고정 지시사항]: 다른 회원 전면 제거, 오직 나의 인적사항 명찰만 상단에 웅장하게 고정
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: brandGolden.withValues(alpha: 0.1), // 은은한 골드 안개빛 포근함
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: brandGolden.withValues(alpha: 0.4), width: 1.2),
              ),
              child: Center(
                child: Text(
                  _mySchoolInfo,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.gowunBatang(
                    color: brandGolden,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5, // 단독 명찰에 맞춘 가독성 스케일업
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 👑 독립 분리된 고품격 실행 버튼 구역
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E24),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: brandGolden.withValues(alpha: 0.4), width: 1.2),
                      ),
                      child: Column(
                        children: [
                          Text('Summary', style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 16.5)),
                          const SizedBox(height: 2),
                          Text('(종합 리포트)', style: GoogleFonts.gowunBatang(color: brandGolden.withValues(alpha: 0.8), fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E24),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: brandGolden.withValues(alpha: 0.4), width: 1.2),
                      ),
                      child: Column(
                        children: [
                          Text('Detailed Analytics', style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.5)),
                          const SizedBox(height: 2),
                          Text('(상세 분석 기록)', style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 13)),
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
                Text(
                  'Progress & Achievements',
                  style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '(성취도 리포트)',
                  style: GoogleFonts.gowunBatang(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 📐 개인 맞춤 세로폭 50% 확장 안정화 대시보드 격자
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.65,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0x61000000),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: brandGolden.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Next Level Road', style: GoogleFonts.gowunBatang(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('(다음 레벨까지)', style: GoogleFonts.gowunBatang(color: Colors.white38, fontSize: 10)),
                      const SizedBox(height: 4),
                      Text(_myNextLevel, style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0x61000000),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: brandGolden.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Goal Attainment Rate', style: GoogleFonts.gowunBatang(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('(목표 달성률)', style: GoogleFonts.gowunBatang(color: Colors.white38, fontSize: 10)),
                      const SizedBox(height: 4),
                      Text(_myGoalRate, style: GoogleFonts.gowunBatang(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 📅 정중앙 완벽 균등 대칭 정렬 3분할 탭바
            Opacity(
              opacity: 0.9,
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0x3B000000),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  isScrollable: false,
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: brandGolden,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: GoogleFonts.gowunBatang(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: "Today (오늘)"),
                    Tab(text: "Weekly (주)"),
                    Tab(text: "Month (이번달)"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 📊 개인 과목 가로형 막대그래프 리스트
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHorizontalGraph(_mySubjects),
                  _buildHorizontalGraph(_mySubjects),
                  _buildHorizontalGraph(_mySubjects),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalGraph(List<Map<String, dynamic>> subjects) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final data = subjects[index];
        final double scorePercentage = data["score"] as double;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              SizedBox(
                width: 140, // 140 포격수 수호
                child: Text(
                  data["subject"] as String,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: scorePercentage,
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: data["color"] as Color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      child: Text(
                        "${(scorePercentage * 100).toInt()}%",
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}