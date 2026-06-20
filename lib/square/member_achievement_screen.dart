import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../global_lang.dart'; // 👑 1단계에서 만든 글로벌 사전 연결

class MemberAchievementScreen extends StatefulWidget {
  const MemberAchievementScreen({Key? key}) : super(key: key);

  @override
  State<MemberAchievementScreen> createState() => _MemberAchievementScreenState();
}

class _ThemeColors {
  static const Color brandGolden = Color(0xFFE5C158);
  static const Color luxuryDarkBg = Color(0xFF030712);
  static const Color premiumCardBg = Color(0xFF0D1527);
}

class _MemberAchievementScreenState extends State<MemberAchievementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _warningAnimController;
  late Animation<double> _warningAnimation;

  // 🎯 국적/언어별 단일 출력을 위해 기존 더블 변수 구조를 사전형 단일 변수로 전면 다이어트
  final String _mySchoolInfo = DkeLang.schoolInfo;
  final String _currentLevel = DkeLang.current == 'KO' ? "레벨 26" : "Lv.26";
  final String _myStars = "12,580";

  // 내부 차트용 연동 데이터 모델 (국적/언어 스위칭 유연화 대응)
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

  // 각 언어 모드에 맞춰 차트 라벨이 단일화되어 깔끔하게 출력되도록 로직 개조
  List<Map<String, dynamic>> get _masterSubjectData => [
    {"subject": DkeLang.current == 'KO' ? "수학" : "Math", "score": 0.85, "averageScore": 0.65, "hasStudiedToday": true, "hasStudiedWeekly": true, "hasStudiedMonthly": true, "hasStudiedYearly": true, "baseMinutes": 120, "isStarEligible": true},
    {"subject": DkeLang.current == 'KO' ? "영어" : "English", "score": 0.72, "averageScore": 0.70, "hasStudiedToday": true, "hasStudiedWeekly": true, "hasStudiedMonthly": true, "hasStudiedYearly": true, "baseMinutes": 90, "isStarEligible": true},
    {"subject": DkeLang.current == 'KO' ? "국어" : "Korean", "score": 0.90, "averageScore": 0.58, "hasStudiedToday": false, "hasStudiedWeekly": true, "hasStudiedMonthly": true, "hasStudiedYearly": true, "baseMinutes": 80, "isStarEligible": true},
    {"subject": DkeLang.current == 'KO' ? "과학" : "Science", "score": 0.65, "averageScore": 0.60, "hasStudiedToday": false, "hasStudiedWeekly": true, "hasStudiedMonthly": true, "hasStudiedYearly": true, "baseMinutes": 70, "isStarEligible": true},
    {"subject": DkeLang.current == 'KO' ? "사회" : "Social", "score": 0.78, "averageScore": 0.75, "hasStudiedToday": false, "hasStudiedWeekly": false, "hasStudiedMonthly": true, "hasStudiedYearly": true, "baseMinutes": 60, "isStarEligible": true},
    {"subject": DkeLang.current == 'KO' ? "도덕" : "Ethics", "score": 0.95, "averageScore": 0.80, "hasStudiedToday": false, "hasStudiedWeekly": false, "hasStudiedMonthly": true, "hasStudiedYearly": true, "baseMinutes": 50, "isStarEligible": true},
    {"subject": DkeLang.current == 'KO' ? "역사" : "History", "score": 0.80, "averageScore": 0.62, "hasStudiedToday": false, "hasStudiedWeekly": false, "hasStudiedMonthly": true, "hasStudiedYearly": true, "baseMinutes": 45, "isStarEligible": true},
    {"subject": DkeLang.current == 'KO' ? "정보" : "Info", "score": 0.88, "averageScore": 0.68, "hasStudiedToday": false, "hasStudiedWeekly": false, "hasStudiedMonthly": true, "hasStudiedYearly": true, "baseMinutes": 40, "isStarEligible": true},
  ];

  // 타이머 연동 실시간 데이터 버퍼 수소화
  String _timerSubject = "";
  String _timerDetails = "";
  int _timerScore = 100;
  String _timerIncorrect = "";
  int _timerUnderstanding = 100;
  String _timerDifficulty = "";
  String _timerConcentration = "";
  String _timerCondition = "";
  String _timerNextGoal = "";
  String _timerTimestamp = "";
  int _timerDurationMinutes = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() { if (!_tabController.indexIsChanging) setState(() {}); });
    _warningAnimController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)..repeat(reverse: true);
    _warningAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(CurvedAnimation(parent: _warningAnimController, curve: Curves.easeInOut));

    _syncTimerSharedDataPackets();
  }

  Future<void> _syncTimerSharedDataPackets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? tempSubject = prefs.getString('dke_temp_subject');
      final int? tempSeconds = prefs.getInt('dke_temp_elapsed');

      setState(() {
        _timerSubject = tempSubject ?? (DkeLang.current == 'KO' ? "수학" : "Math");
        _timerDetails = DkeLang.current == 'KO' ? "개념 및 심화, 문제풀이 25문제" : "Solved concepts and problems 25 issues.";
        _timerScore = 100;
        _timerIncorrect = DkeLang.current == 'KO' ? "정리함" : "COMPLETED";
        _timerUnderstanding = 80;
        _timerDifficulty = DkeLang.current == 'KO' ? "보통" : "Normal";
        _timerConcentration = DkeLang.current == 'KO' ? "높음" : "High";
        _timerCondition = DkeLang.current == 'KO' ? "좋음 😊" : "Good 😊";
        _timerNextGoal = DkeLang.current == 'KO' ? "함수 심화문제" : "Advanced function problems";
        _timerTimestamp = "2026-06-18 21:36 UTC";
        _timerDurationMinutes = tempSeconds != null ? (tempSeconds ~/ 60 == 0 ? 72 : tempSeconds ~/ 60) : 72;
      });
    } catch (e) {
      debugPrint("성취도 데이터 패킷 결합 추적 예외: $e");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _warningAnimController.dispose();
    super.dispose();
  }

  void _showReportPopup(BuildContext context, String mainTitle, String content) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _ThemeColors.premiumCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.3), width: 1.5),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                            mainTitle,
                            style: DkeLang.current == 'KO'
                                ? GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 23)
                                : GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 22)
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white60), onPressed: () => Navigator.pop(context))
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 20, thickness: 1.2),
                  Text(content, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14.5, height: 1.6)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double achievementRate = (_timerDurationMinutes / 90) * 100;

    // 🎯 3번 지시사항: 종합리포트 고정 포맷 및 게임 요소 배제 8줄 이상 멘트 엄격 반영
    final String summaryDynamicContent = DkeLang.current == 'KO'
        ? "[종합 리포트]\n\n"
        "자기주도 학습 1교시\n"
        "1번 학습일시: \$2026-06-18 21:36 ~ 22:36 끝남 UTC\$\n"
        "2. 학습과목: \$수학\$\n"
        "3. 학습시간: \$72분 / 90분\$\n"
        "4. 목표달성률: \$80%\$\n"
        "5. 별 갯수: \$ ****(4/5)\$\n\n"
        "자기주도학습 2교시\n"
        "1번 학습일시:\n"
        "\$2026-06-18 21:36 ~ 22:36 끝남 UTC\$\n"
        "2. 학습과목: \$영어\$\n"
        "3. 학습시간: \$72분 / 90분\$\n"
        "4. 목표달성률: \$80%\$\n"
        "5. 별 갯수: \$ ****(4/5)\$\n\n"
        "[종합 진단 피드백]\n"
        "금일 진행된 \$이규현\$ 회원의 학습 세션은 시간 관리와 핵심 문항 분석 면에서 고도의 진취성을 나타냈습니다. 계획된 90분의 집중 타임라인 중 실제 몰입 시간의 밀도가 높았으며, 과목 간 균형도 안정적입니다. 다만 학습 개시 단계에서 개념 정립에 소요되는 시간이 평균치보다 다소 길어지는 지체 현상이 관찰되었습니다. 이는 후반부 응용 문제 풀이의 정밀도를 저해하는 요인이 될 수 있으므로, 초기 몰입 속도를 제고하려는 의도적인 노력이 요구됩니다. 전반적인 과목 이해도는 상위권 진입에 무리가 없는 수준이나, 오답을 선별하고 피드백 리포트를 구성할 때 본인의 주관적 판단에만 의존하는 경향은 확실히 교정해야 할 지점입니다. 현재 유지하고 있는 연속 학습의 패턴은 장기적 성과 도출을 위한 훌륭한 기반이 되므로, 스스로의 역량을 확신하고 정진하기 바랍니다. 미진한 영역을 명확히 보완하여 내일의 학습 효율성을 한층 더 고도화할 수 있도록 냉철하게 관리해 나갈 것을 엄중히 제언합니다."
        : "[Total Report]\n\n"
        "Self-Directed Learning Session 1\n"
        "1. TIMESTAMP: \$2026-06-18 21:36 ~ 22:36 End UTC\$\n"
        "2. SUBJECT: \$Math\$\n"
        "3. TIME: \$72 Mins / 90 Mins\$\n"
        "4. ACHIEVEMENT RATE: \$80%\$\n"
        "5. STARS: \$ ****(4/5)\$\n\n"
        "Self-Directed Learning Session 2\n"
        "1. TIMESTAMP:\n"
        "\$2026-06-18 21:36 ~ 22:36 End UTC\$\n"
        "2. SUBJECT: \$English\$\n"
        "3. TIME: \$72 Mins / 90 Mins\$\n"
        "4. ACHIEVEMENT RATE: \$80%\$\n"
        "5. STARS: \$ ****(4/5)\$\n\n"
        "Today's learning sessions showed great progress. Keep moving forward toward your target with strong motivation.";

    // 🎯 4번 지시사항: 상세분석 기록 연동 포맷 및 의욕 고취/경고 멘트 정밀 반영
    final String detailedDynamicContent = DkeLang.current == 'KO'
        ? "[상세분석기록]\n\n"
        "• 상세내용: \$개념 및 심화,문제풀이 25문제\$\n"
        "• 오답노타: \$정리함\$\n"
        "• 이 해 도: \$80%\$\n"
        "• 난 이 도: \$보통\$\n"
        "• 집중도: \$높음\$\n"
        "• 학습컨디션: \$좋음\$\n"
        "• 다음목표: \$함수 심화문제\$\n\n"
        "[심층 교육 제언]\n"
        "차기 목표로 설정된 함수 심화 파트는 고도의 논리적 추론이 수반되는 영역이나, 현재 \$이규현\$ 회원이 보여준 오답 정리 정밀도와 개념 분석력이라면 충분히 안정적으로 돌파해 낼 수 있습니다. 장래의 목표를 실현하기 위한 과정에서 마주하는 고난도 문항은 성장의 기회가 될 것입니다. 단, 난이도가 보통인 문항 스펙트럼에서도 실수가 일부 식별된 점은 자만을 경계하고 기초를 더 철저히 해야 한다는 경고입니다. 스스로의 가능성을 믿고 의욕적으로 도전하되 명밀하게 검토하는 태도를 기르십시오."
        : "[Detailed Analytics]\n\n"
        "• DETAILS: \$Concepts & Problems 25 issues\$\n"
        "• INCORRECT NOTE: \$COMPLETED\$\n"
        "• UNDERSTANDING: \$80%\$\n"
        "• DIFFICULTY: \$Normal\$\n"
        "• CONCENTRATION: \$High\$\n"
        "• CONDITION: \$Good\$\n"
        "• NEXT GOAL: \$Advanced Function Problems\$\n\n"
        "Your potential is unlimited. Learn from your minor mistakes and focus deeper on the next advanced targets.";

    return Scaffold(
      backgroundColor: _ThemeColors.luxuryDarkBg,
      // 👑 파트너님 지시사항 완벽 소독 반영: 중앙정렬 정품 로고 바 탑재 완료
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 92, // 🎯 2번 지시사항: 바닥과 배경 맨 끝부분 여백 70% 축소 반영
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 👑 1. 맨 위 정중앙에 위치하는 로고 이미지
            Image.asset(
              'assets/images/gsu_logo.png',
              width: 180,
              height: 24,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 0.5), // 🎯 지시사항: 이미지와 첫줄 타이틀 사이 여백 정확히 0.5미리 적용

            // 👑 2. 첫째 줄 영문 대문자 정중앙 타이틀
            Text(
              'MEMBER ACHIEVEMENT',
              textAlign: TextAlign.center,
              style: GoogleFonts.gowunBatang(
                color: _ThemeColors.brandGolden,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 2),

            // 👑 3. 둘째 줄 가입회원 이름 매핑 정중앙 정렬
            Text(
              '\$이규현\$ 성취도', // 🎯 1번 지시사항: 회원가입 이름 매핑 대응, 황금색 변경 및 앞뒤 $ 추가
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(
                color: _ThemeColors.brandGolden, // 황금색으로 변경
                fontWeight: FontWeight.bold,
                fontSize: 23, // 8번 원칙: 타이틀 한글 글자크기 23 단일화
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0), // 최상위 const 전면 제거로 자식 위젯 간섭 원천 소독 완료
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------------------------
              // 상단 알림 네모 박스 정밀 가공 (GKE 변경, 괄호 전면 삭제 및 문구 교체)
              // ---------------------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.25), width: 1.2),
                ),
                child: Column(
                  children: [
                    Text(
                      '\$GKE 고등학교 2학년 이제임스\$', // 서비스명 GKE 매핑 및 $ 연동 기호 추가
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansKr(
                        color: _ThemeColors.brandGolden,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '현재도 전국 전 세계 사람들 학습중입니다.', // 이미지에 맞춘 괄호 제거 완성문구
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansKr(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Summary / Detailed Analytics 버튼
              Row(
                children: [
                  _buildTopButton(
                    DkeLang.current == 'KO' ? "종합 리포트" : "Total Report",
                    40,
                    summaryDynamicContent,
                  ),
                  const SizedBox(width: 8),
                  _buildTopButton(
                    DkeLang.current == 'KO' ? "상세분석기록" : "Detailed Analytics",
                    60,
                    detailedDynamicContent,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ---------------------------------------------------------------
              // 사각 네모 박스 크기(높이) 완벽 통일 레이아웃 패널
              // ---------------------------------------------------------------
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- [좌측 패널: 다음 레벨로드] ---
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.25), width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DkeLang.current == 'KO' ? "다음 레벨로드" : "Next Level Road", style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 14.5, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text(
                              DkeLang.current == 'KO' ? "레벨 26" : "Lv.26",
                              style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _buildLuxuryGlowingStar(),
                                const SizedBox(width: 6),
                                Text(DkeLang.current == 'KO' ? "\$ 23,487 개\$" : "\$ 23,487 Stars\$", style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 🎯 라벨 한글 흰색 변경 & 매핑 데이터값 한글/숫자 황금색 분리 및 줄바꿈 완성
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.bold),
                                children: [
                                  const TextSpan(text: "친구 랭킹: ", style: TextStyle(color: Colors.white)),
                                  const TextSpan(text: "\$3위\$\n\n", style: TextStyle(color: _ThemeColors.brandGolden)),
                                  const TextSpan(text: "전 세계 랭킹:\n", style: TextStyle(color: Colors.white)),
                                  const TextSpan(text: "상위 \$1.2%\$", style: TextStyle(color: _ThemeColors.brandGolden)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              decoration: BoxDecoration(color: const Color(0x2AFFFFFF), borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(DkeLang.current == 'KO' ? "목표 대학" : "Target University", style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(height: 3),
                                  Text(DkeLang.current == 'KO' ? "\$서울대학교\$" : "\$Seoul National University\$", style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // --- [우측 패널: 목표 달성도] ---
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.25), width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DkeLang.current == 'KO' ? "목표 달성도" : "Goal Attainment", style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 14.5, fontWeight: FontWeight.bold)),
                                Text("\$85%\$", style: GoogleFonts.notoSansKr(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13.2)),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // 🎯 명칭들은 완전 흰색 처리, 내부 데이터 스펙 수치는 황금색 정밀 연동 및 정렬
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.bold, height: 1.5),
                                children: [
                                  const TextSpan(text: "연속 학습일: ", style: TextStyle(color: Colors.white)),
                                  const TextSpan(text: "\$56일\$\n", style: TextStyle(color: _ThemeColors.brandGolden)),
                                  const TextSpan(text: "총 학습시간:\n", style: TextStyle(color: Colors.white)),
                                  const TextSpan(text: "\$1,257시간\$", style: TextStyle(color: _ThemeColors.brandGolden)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0x1F34C759),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.greenAccent.withOpacity(0.2), width: 1),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.notoSansKr(fontSize: 11, fontWeight: FontWeight.bold, height: 1.4),
                                        children: [
                                          const TextSpan(text: "어제 대비 오늘 ", style: TextStyle(color: Colors.white)),
                                          const TextSpan(text: "\$+20%\$\n", style: TextStyle(color: _ThemeColors.brandGolden)),
                                          const TextSpan(text: "가장 성장한 과목\n", style: TextStyle(color: Colors.white)),
                                          const TextSpan(text: "\$영어\$\n", style: TextStyle(color: _ThemeColors.brandGolden)),
                                          const TextSpan(text: "가장 많이 학습한 과목\n", style: TextStyle(color: Colors.white)),
                                          const TextSpan(text: "\$수학\$", style: TextStyle(color: _ThemeColors.brandGolden)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 👑 품격 있는 가로 확장형 탭바 영역 (자간 확대 및 스페이스 구성 완벽 반영, 부모 const 제거 완료)
              Container(
                width: double.infinity,
                height: 52,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1527),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.3), width: 1.2),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorPadding: const EdgeInsets.symmetric(horizontal: 0.5, vertical: 3),
                  indicator: const BoxDecoration(color: _ThemeColors.brandGolden, borderRadius: BorderRadius.all(Radius.circular(8))),
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.white,
                  labelStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 4.0),
                  unselectedLabelStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 4.0),
                  tabs: [
                    Tab(text: DkeLang.current == 'KO' ? "일 간" : "Daily"),
                    Tab(text: DkeLang.current == 'KO' ? "주 간" : "Weekly"),
                    Tab(text: DkeLang.current == 'KO' ? "월 간" : "Monthly"),
                    Tab(text: DkeLang.current == 'KO' ? "연 간" : "Yearly"),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildAdvancedChartDashboard(_tabController.index),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopButton(String title, int flex, String contentText) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => _showReportPopup(context, title, contentText),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _ThemeColors.premiumCardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 13.5)),
              const SizedBox(width: 4),
              const Icon(Icons.play_arrow_rounded, color: Color(0xFFE5C158), size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuryGlowingStar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 16, height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: _ThemeColors.brandGolden.withOpacity(0.7), blurRadius: 7, spreadRadius: 2.0),
            ],
          ),
        ),
        const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 17),
      ],
    );
  }

  Widget _buildAdvancedChartDashboard(int tabIndex) {
    List<Map<String, dynamic>> targetSubjects = [];

    if (tabIndex == 0) {
      targetSubjects = _masterSubjectData.where((e) => e["hasStudiedToday"] == true).toList();
    } else if (tabIndex == 1) {
      targetSubjects = _masterSubjectData.where((e) => e["hasStudiedWeekly"] == true).toList();
    } else if (tabIndex == 2) {
      targetSubjects = _masterSubjectData.where((e) => e["hasStudiedMonthly"] == true).toList();
    } else {
      targetSubjects = _masterSubjectData.where((e) => e["hasStudiedYearly"] == true).toList();
    }

    List<Color> colorPalette = (tabIndex == 1) ? _weeklyColors : _todayColors;
    List<String> yAxisLabels = (tabIndex == 0)
        ? ["5h", "4h", "3h", "2h", "1h", "0h"]
        : (tabIndex == 1)
        ? ["35h", "30h", "25h", "20h", "15h", "7h", "0h"]
        : (tabIndex == 2)
        ? ["120h", "90h", "60h", "30h", "10h", "0h"]
        : ["1200h", "900h", "600h", "300h", "100h", "0h"];

    double timeMultiplier = (tabIndex == 0) ? 1.0 : (tabIndex == 1) ? 5.0 : (tabIndex == 2) ? 22.0 : 250.0;

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
              Positioned(
                left: 48, top: 0,
                child: Row(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 5),
                  Text(DkeLang.current == 'KO' ? "평균" : "Average", style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),
              Positioned.fill(
                left: 38, right: 0, top: 25, bottom: 44,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(yAxisLabels.length, (i) => Container(width: double.infinity, height: 0.8, color: Colors.white.withOpacity(0.08))),
                ),
              ),
              Positioned(
                left: 38, top: 25, bottom: 44,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate((yAxisLabels.length * 2) - 1, (i) => Container(width: i % 2 != 0 ? 4.0 : 0.0, height: 1.5, color: _ThemeColors.brandGolden.withOpacity(0.4))),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 30,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: 22),
                        ...yAxisLabels.take(yAxisLabels.length - 1).map((l) => Expanded(child: Text(l, style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 10)))),
                        Text(yAxisLabels.last, style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 10)),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 2.2, margin: const EdgeInsets.only(top: 25, bottom: 44), color: _ThemeColors.brandGolden.withOpacity(0.6)),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.bottomLeft,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(targetSubjects.length, (index) {
                              final data = targetSubjects[index];
                              const double hMax = 100.0;
                              final Color pCol = colorPalette[index % colorPalette.length];
                              return Container(
                                width: 54,
                                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: hMax + 16, width: 54,
                                      child: Stack(
                                        alignment: Alignment.bottomCenter,
                                        children: [
                                          Positioned(
                                            left: 8, bottom: 0,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Text("${(data["averageScore"] * 100).toInt()}%", style: const TextStyle(color: Colors.white54, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                                Container(
                                                  height: data["averageScore"] * hMax, width: 18,
                                                  decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: const BorderRadius.vertical(top: Radius.circular(2.5))),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            left: 27, bottom: 0,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Text("${(data["score"] * 100).toInt()}%", style: TextStyle(color: pCol, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                                Container(
                                                  height: data["score"] * hMax, width: 18,
                                                  decoration: BoxDecoration(color: pCol, borderRadius: const BorderRadius.vertical(top: Radius.circular(2.5))),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 36,
                                      child: Text(data["subject"], textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1.2)),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                        Positioned(
                          left: 0, right: 0, bottom: 44,
                          child: Container(width: double.infinity, height: 2.2, color: _ThemeColors.brandGolden.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white10, height: 16),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DkeLang.current == 'KO' ? "종합 생활 균형" : "Comprehensive Life Balance", style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
            Text(DkeLang.current == 'KO' ? "(종합 생활 균형 밸런스 분석)" : "(Comprehensive life balance analysis)", style: GoogleFonts.notoSansKr(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 14),

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
                      Container(
                        width: 82, height: 82,
                        decoration: const BoxDecoration(color: Color(0xFF0D1527), shape: BoxShape.circle),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Total', style: GoogleFonts.gowunBatang(color: Colors.white38, fontSize: 10)),
                            Text("$totalMinutes/m", style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
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
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: Row(
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${item["subject"].toString().replaceAll('\n', ' ')}  $percent%",
                                style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                item["isStarEligible"] ? "✨ +${calculatedMin} Stars" : "🚫 No Stars",
                                style: GoogleFonts.notoSansKr(color: item["isStarEligible"] ? _ThemeColors.brandGolden.withOpacity(0.8) : Colors.white38, fontSize: 10),
                              ),
                            ],
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
        const SizedBox(height: 16),

        if (targetSubjects.isEmpty)
          AnimatedBuilder(
            animation: _warningAnimation,
            builder: (c, child) => Transform.translate(offset: Offset(0, _warningAnimation.value), child: child),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2514),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _ThemeColors.brandGolden, width: 1.2),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: _ThemeColors.brandGolden, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DkeLang.current == 'KO' ? "데이터베이스 동기화 알림" : "Database Sync Notification", style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(DkeLang.current == 'KO' ? "(데이터를 안전하게 동기화 중입니다...)" : "(Synchronizing data storage safely...)", style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden.withOpacity(0.85), fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
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