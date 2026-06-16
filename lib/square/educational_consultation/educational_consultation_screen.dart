import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// 👑 [주소지 연결]: 하위 폴더에 안착한 AI 실시간 상담방 연결선 유지
import 'package:gsu_studyup/square/educational_consultation/ai_consulting_room_screen.dart';

class EducationalConsultationScreen extends StatelessWidget {
  const EducationalConsultationScreen({Key? key}) : super(key: key);

  // 👑 [가로 터짐 철벽 방어 및 2줄 요약 팝업 엔진]
  void _showConsultationPopup(
      BuildContext context,
      String title,
      String line1,
      String line2,
      String targetRoom
      ) {
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
          style: GoogleFonts.gowunBatang(
              color: const Color(0xFFE5C158),
              fontWeight: FontWeight.bold,
              fontSize: 18
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1행: 영문 가이드라인
            Text(
                line1,
                textAlign: TextAlign.center,
                style: GoogleFonts.gowunBatang(color: const Color(0xFFEFEFEF), fontSize: 15, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 12),
            // 👑 [복원 완수]: 누락되었던 한글 번역 가이드라인 구역 완벽 심폐소생
            Text(
                line2,
                textAlign: TextAlign.center,
                style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 13.5, fontWeight: FontWeight.w500)
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "Cancel (취소)",
                  style: GoogleFonts.gowunBatang(color: Colors.white60, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();

                  if (targetRoom == "AI_ROOM") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AiConsultingRoomScreen(),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF0D1527),
                        duration: const Duration(seconds: 3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFE5C158), width: 1),
                        ),
                        content: Text(
                          "Coming Soon! The premium consultation room is preparing to open.\n(개통 준비 중입니다! 프리미엄 상담실 오픈을 준비하고 있습니다.)",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }
                },
                child: Text(
                  "Start (상담 시작)",
                  style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgSpaceDark = Color(0xFF050B14);
    const Color cardSpaceDark = Color(0xFF0D1527);
    const Color textWhite = Color(0xFFEFEFEF);
    const Color brandGolden = Color(0xFFE5C158);

    return Scaffold(
      backgroundColor: bgSpaceDark,
      appBar: AppBar(
        backgroundColor: bgSpaceDark,
        elevation: 0,
        toolbarHeight: 75,
        leading: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: textWhite, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Educational Consultation",
                style: GoogleFonts.gowunBatang(color: textWhite, fontSize: 23, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                "(교육상담)",
                style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: cardSpaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: brandGolden.withOpacity(0.3), width: 1.2),
                ),
                child: Column(
                  children: [
                    Text(
                      "Premium Consultation Benefits",
                      style: GoogleFonts.gowunBatang(color: textWhite, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    Text(
                      "(최고 존엄 GSU 교육상담만의 독점적 장점)",
                      style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(color: Colors.white10, height: 1),
                    ),
                    _buildAdvantageRow("✦", "Data-Driven Analysis", "(유저의 실시간 학습 타이머 및 성취도 기반 초정밀 분석)"),
                    const SizedBox(height: 6),
                    _buildAdvantageRow("✦", "Global Elite Mentors", "(전 세계 명문대 학부생 수석 멘토단과의 1:1 비밀 매칭)"),
                    const SizedBox(height: 6),
                    _buildAdvantageRow("✦", "Perfect Care for Parents", "(결제권을 쥔 학부모님들을 위한 프리미엄 상위 1% 정보망)"),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // 💎 1. AI Real-time Consulting (그린 에메랄드)
              _buildJewelButton(
                context: context,
                imagePath: 'assets/images/green_btn.png',
                englishTitle: "AI Real-time Consulting",
                koreanTitle: "(AI 실시간 컨설팅)",
                onTap: () => _showConsultationPopup(
                    context,
                    "AI Real-time Consulting",
                    "Analyze your custom study pattern and receive a personalized recipe instantly.",
                    // 👑 [원장님 지시 완수]: "3초 만에"를 "즉시"로 전격 교정 완료!
                    "(나의 실시간 학습 패턴을 분석하여 즉시 맞춤형 처방전을 발행해 드립니다.)",
                    "AI_ROOM"
                ),
              ),
              const SizedBox(height: 20),

              // 💎 2. Global Mentor Room (퍼플 자수정)
              _buildJewelButton(
                context: context,
                imagePath: 'assets/images/purple_btn.png',
                englishTitle: "Global Mentor Room",
                koreanTitle: "(글로벌 멘토 상담실)",
                onTap: () => _showConsultationPopup(
                    context,
                    "Global Mentor Room",
                    "Get 1:1 premium exam strategies and feedback from prestigious university mentors.",
                    "(명문대 수석 멘토들에게 1:1로 비밀 입시 전략과 초정밀 피드백을 받아보실 수 있습니다.)",
                    "MENTOR_ROOM"
                ),
              ),
              const SizedBox(height: 20),

              // 💎 3. Parent Premium Lounge (다크 블루 사파이어)
              _buildJewelButton(
                context: context,
                imagePath: 'assets/images/dark_blue_btn.png',
                englishTitle: "Parent Premium Lounge",
                koreanTitle: "(학부모 프리미엄 라운지)",
                onTap: () => _showConsultationPopup(
                    context,
                    "Parent Premium Lounge",
                    "Check your child's live tracking report and share elite educational data.",
                    "(자녀의 실시간 학습 리포트를 점검하고, 최고 존엄의 엘리트 교육 정보를 공유합니다.)",
                    "PARENT_ROOM"
                ),
              ),
              const SizedBox(height: 20),

              // 💎 4. Custom Subject Strategy (라이트 블루 토파즈)
              _buildJewelButton(
                context: context,
                imagePath: 'assets/images/light_blue_btn.png',
                englishTitle: "Custom Subject Strategy",
                koreanTitle: "(과목별 학습 전략 가이드)",
                onTap: () => _showConsultationPopup(
                    context,
                    "Custom Subject Strategy",
                    "Access strategic high-score guides matching your current subject time ratio.",
                    "(현재 나의 과목별 공부 시간 비율에 맞는 상위 1% 고득점 돌파 비법서를 열람합니다.)",
                    "STRATEGY_ROOM"
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

// 👑 [장점 텍스트 빌더 - 영문: 고운바탕체 진명조 / 한글: 노토산스 고딕 하이브리드 매립]
  Widget _buildAdvantageRow(String icon, String eng, String kor) {
    const Color brandGolden = Color(0xFFE5C158);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0), // 行간 황금 여백
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(icon, style: const TextStyle(color: brandGolden, fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1행: 영문 -> 👑 원래 원칙대로 웅장한 한국형 진명조 수호!
                Text(
                  eng,
                  style: GoogleFonts.gowunBatang(
                    color: Colors.white,
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3), // 미세 간격
                // 2행: 한글 -> 👑 원장님 지시: 제미나이 스타일 Noto Sans KR 고딕체로 전격 교체!
                Text(
                  kor,
                  style: GoogleFonts.notoSansKr(
                    color: brandGolden, // 황금색 유지
                    fontSize: 13.5,     // 고딕체 특성상 시각적 균형을 맞춘 프리미엄 크기 조정
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJewelButton({
    required BuildContext context,
    required String imagePath,
    required String englishTitle,
    required String koreanTitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        height: 85,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              englishTitle,
              style: GoogleFonts.gowunBatang(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                shadows: [const Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 4)],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              koreanTitle,
              style: GoogleFonts.gowunBatang(
                color: const Color(0xFFE5C158),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                shadows: [const Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 4)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}