import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../global_lang.dart'; // 👑 글로벌 사전 연결

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

// 🎯 성적 입력을 위한 내부 데이터 모델링 패킷 정의
class _ExamRecord {
  final String id;
  final String type; // 주평가, 단원평가, 중간고사, 기말고사, 모의고사
  final int grade;   // 1, 2, 3학년
  final int semester; // 1, 2학기
  final DateTime date;
  final String subject;
  final String unit;
  final double score;

  _ExamRecord({
    required this.id,
    required this.type,
    required this.grade,
    required this.semester,
    required this.date,
    required this.subject,
    required this.unit,
    required this.score,
  });
}

class _MemberAchievementScreenState extends State<MemberAchievementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _warningAnimController;
  late Animation<double> _warningAnimation;

  final String _mySchoolInfo = DkeLang.schoolInfo;
  final String _currentLevel = DkeLang.current == 'KO' ? "학습레벨 26" : "Lv.26";
  final String _myStars = "12,580";

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

  final List<Color> _evalColors = [
    const Color(0xFF34C759), // 초
    const Color(0xFFFF3B30), // 빨
    const Color(0xFF007AFF), // 파
    const Color(0xFFFF9500), // 주
    const Color(0xFF5856D6), // 남
    const Color(0xFFFFCC00), // 노
    const Color(0xFFAF52DE), // 보
  ];

  List<Map<String, dynamic>> get _masterSubjectData => [
    {"subject": DkeLang.current == 'KO' ? "수학" : "Math", "score": 0.85, "averageScore": 0.65, "hasStudiedToday": true, "hasStudiedWeekly": true, "hasStudiedMonthly": true, "hasStudiedYearly": true, "baseMinutes": 120, "isStarEligible": true},
    {"subject": DkeLang.current == 'KO' ? "영어" : "English", "score": 0.72, "averageScore": 0.70, "hasStudiedToday": true, "hasStudiedWeekly": true, "hasStudiedMonthly": true, "hasStudiedYearly": true, "baseMinutes": 90, "isStarEligible": true},
    {"subject": DkeLang.current == 'KO' ? "국어" : "Korean", "score": 0.90, "averageScore": 0.58, "hasStudiedToday": false, "hasStudiedWeekly": true, "hasStudiedMonthly": true, "hasStudiedYearly": true, "baseMinutes": 80, "isStarEligible": true},
    {"subject": DkeLang.current == 'KO' ? "과학" : "Science", "score": 0.65, "averageScore": 0.60, "hasStudiedToday": false, "hasStudiedWeekly": true, "hasStudiedMonthly": true, "hasStudiedYearly": true, "baseMinutes": 70, "isStarEligible": true},
    {"subject": DkeLang.current == 'KO' ? "사회" : "Social", "score": 0.78, "averageScore": 0.75, "hasStudiedToday": false, "hasStudiedWeekly": false, "hasStudiedMonthly": true, "hasStudiedYearly": true, "baseMinutes": 30, "isStarEligible": true},
    {"subject": DkeLang.current == 'KO' ? "도덕" : "Ethics", "score": 0.95, "averageScore": 0.80, "hasStudiedToday": false, "hasStudiedWeekly": false, "hasStudiedMonthly": true, "hasStudiedYearly": true, "baseMinutes": 50, "isStarEligible": true},
    {"subject": DkeLang.current == 'KO' ? "역사" : "History", "score": 0.80, "averageScore": 0.62, "hasStudiedToday": false, "hasStudiedWeekly": false, "hasStudiedMonthly": true, "hasStudiedYearly": true, "baseMinutes": 45, "isStarEligible": true},
    {"subject": DkeLang.current == 'KO' ? "정보" : "Info", "score": 0.88, "averageScore": 0.68, "hasStudiedToday": false, "hasStudiedWeekly": false, "hasStudiedMonthly": true, "hasStudiedYearly": true, "baseMinutes": 40, "isStarEligible": true},
  ];

  String _timerSubject = "";
  String _timerDetails = "";
  int _timerScore = 100;
  String _timerIncorrect = "";
  int _timerDurationMinutes = 0;

  String? _selectedExamType;
  List<_ExamRecord> _allRecords = [];

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _scoreController = TextEditingController();
  int _inputGrade = 1;
  int _inputSemester = 1;

  // 과거 조회 필터링 다중 조건 변수
  String _filterExamType = "주평가";
  int _filterGrade = 2;
  int _filterSemester = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() { if (!_tabController.indexIsChanging) setState(() {}); });
    _warningAnimController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)..repeat(reverse: true);
    _warningAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(CurvedAnimation(parent: _warningAnimController, curve: Curves.easeInOut));

    _syncTimerSharedDataPackets();
    _mockInitialExamRecords();
  }

  void _mockInitialExamRecords() {
    _allRecords = [
      _ExamRecord(id: "1", type: "주평가", grade: 2, semester: 1, date: DateTime.now(), subject: DkeLang.current == 'KO' ? "수학" : "Math", unit: "삼각함수", score: 95),
      _ExamRecord(id: "2", type: "주평가", grade: 2, semester: 1, date: DateTime.now(), subject: DkeLang.current == 'KO' ? "영어" : "English", unit: "관계대명사", score: 70),
      _ExamRecord(id: "3", type: "단원평가", grade: 2, semester: 1, date: DateTime.now(), subject: DkeLang.current == 'KO' ? "국어" : "Korean", unit: "고전시가", score: 85),
    ];
  }

// 👑 교정 완료: 파라미터로 들어오는 시험 유형(type)을 다이렉트로 매핑하여 필터링 엇박자 완벽 해결
  List<_ExamRecord> _getFilteredRecords(String type) {
    return _allRecords.where((rec) {
      return rec.type == type
          && rec.grade == _filterGrade
          && rec.semester == _filterSemester;
    }).toList();
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
    _subjectController.dispose();
    _unitController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  void _showReportPopup(BuildContext context, String mainTitle, String content) {
    String finalContent = content;
    final activeExams = _allRecords.where((e) => e.type == "주평가").toList();
    if (activeExams.isNotEmpty && mainTitle.contains("종합")) {
      String examSummary = "\n\n[직접 작성 주평가 실시간 연동]\n";
      for (var ex in activeExams) {
        examSummary += "• ${ex.subject}(${ex.unit}): \$${ex.score.toInt()}점\$\n";
      }
      finalContent = content + examSummary;
    }

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
                  Theme(
                    data: Theme.of(context).copyWith(
                      scrollbarTheme: ScrollbarThemeData(
                        thumbColor: MaterialStateProperty.all(_ThemeColors.brandGolden.withOpacity(0.5)),
                      ),
                    ),
                    child: Row(
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
                  ),
                  const Divider(color: Colors.white10, height: 20, thickness: 1.2),
                  Text(finalContent, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14.5, height: 1.6)),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 92,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/gsu_logo.png',
              width: 180,
              height: 24,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 0.5),
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
            Text(
              '\$이규현\$ 성취도',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(
                color: _ThemeColors.brandGolden,
                fontWeight: FontWeight.bold,
                fontSize: 23,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      '\$GKE 고등학교 2학년 이제임스\$',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansKr(
                        color: _ThemeColors.brandGolden,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '현재도 전국 전 세계 사람들 학습중입니다.',
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

              Row(
                children: [
                  _buildTopButton(DkeLang.current == 'KO' ? "종합 리포트" : "Total Report", 40, summaryDynamicContent),
                  const SizedBox(width: 8),
                  _buildTopButton(DkeLang.current == 'KO' ? "상세분석기록" : "Detailed Analytics", 60, detailedDynamicContent),
                ],
              ),
              const SizedBox(height: 12),

              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                            Text(DkeLang.current == 'KO' ? "학습레벨로드" : "Next Level Road", style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 14.5, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text(DkeLang.current == 'KO' ? "학습레벨 26" : "Lv.26", style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _buildLuxuryGlowingStar(),
                                const SizedBox(width: 6),
                                Text(DkeLang.current == 'KO' ? "\$ 23,487 개\$" : "\$ 23,487 Stars\$", style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.bold),
                                children: [
                                  const TextSpan(text: "친구 학습 랭킹: ", style: TextStyle(color: Colors.white)),
                                  const TextSpan(text: "\$3위\$\n\n", style: TextStyle(color: _ThemeColors.brandGolden)),
                                  const TextSpan(text: "전 세계 학습 랭킹:\n", style: TextStyle(color: Colors.white)),
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
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.bold, height: 1.5),
                                children: [
                                  const TextSpan(text: "어제 대비 오늘 ", style: TextStyle(color: Colors.white)),
                                  const TextSpan(text: "\$+20%\$\n\n", style: TextStyle(color: _ThemeColors.brandGolden)),
                                  const TextSpan(text: "가장 성장한 학습과목\n", style: TextStyle(color: Colors.white)),
                                  const TextSpan(text: "\$영어\$\n\n", style: TextStyle(color: _ThemeColors.brandGolden)),
                                  const TextSpan(text: "가장 많이 학습한 과목\n", style: TextStyle(color: Colors.white)),
                                  const TextSpan(text: "\$수학\$", style: TextStyle(color: _ThemeColors.brandGolden)),
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
                                        style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.bold, height: 1.4),
                                        children: [
                                          const TextSpan(text: "총 학습시간:\n", style: TextStyle(color: Colors.white)),
                                          const TextSpan(text: "\$1,257시간\$", style: TextStyle(color: _ThemeColors.brandGolden)),
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

              _buildMyExamScoreSection(),
              const SizedBox(height: 20),

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

  Widget _buildMyExamScoreSection() {
    final List<String> examTypes = ["주평가", "단원평가", "중간고사", "기말고사", "모의고사"];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ThemeColors.premiumCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.2), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DkeLang.current == 'KO' ? "나의 성적 기록 직접 작성" : "My Score Self Record",
            style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: examTypes.map((type) {
                bool isSelected = _selectedExamType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedExamType = isSelected ? null : type;
                        if (_selectedExamType != null) {
                          _filterExamType = _selectedExamType!;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _ThemeColors.brandGolden : Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.4)),
                      ),
                      child: Text(
                        type,
                        style: GoogleFonts.notoSansKr(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          if (_selectedExamType != null) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "[${_selectedExamType} 입력 및 차트]",
                      style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      "과거 조회 필터",
                      style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: examTypes.map((t) {
                            bool isCurrentFilter = _filterExamType == t;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _filterExamType = t;
                                  _selectedExamType = t;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isCurrentFilter ? _ThemeColors.brandGolden.withOpacity(0.2) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: isCurrentFilter ? _ThemeColors.brandGolden : Colors.white24),
                                ),
                                child: Text(
                                  t,
                                  style: GoogleFonts.notoSansKr(
                                    color: isCurrentFilter ? _ThemeColors.brandGolden : Colors.white70,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _filterGrade,
                                  dropdownColor: _ThemeColors.premiumCardBg,
                                  style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  icon: const Icon(Icons.arrow_drop_down, color: _ThemeColors.brandGolden, size: 16),
                                  items: [1, 2, 3].map((g) => DropdownMenuItem(value: g, child: Text("$g학년"))).toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() { _filterGrade = v; });
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _filterSemester,
                                  dropdownColor: _ThemeColors.premiumCardBg,
                                  style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  icon: const Icon(Icons.arrow_drop_down, color: _ThemeColors.brandGolden, size: 16),
                                  items: [1, 2].map((s) => DropdownMenuItem(value: s, child: Text("$s학기"))).toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() { _filterSemester = v; });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _inputGrade,
                    decoration: const InputDecoration(labelText: "학년", labelStyle: TextStyle(color: Colors.white60, fontSize: 11)),
                    dropdownColor: _ThemeColors.premiumCardBg,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    items: [1, 2, 3].map((g) => DropdownMenuItem(value: g, child: Text("$g학년"))).toList(),
                    onChanged: (v) { if (v != null) setState(() { _inputGrade = v; }); },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _inputSemester,
                    decoration: const InputDecoration(labelText: "학기", labelStyle: TextStyle(color: Colors.white60, fontSize: 11)),
                    dropdownColor: _ThemeColors.premiumCardBg,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    items: [1, 2].map((s) => DropdownMenuItem(value: s, child: Text("$s학기"))).toList(),
                    onChanged: (v) { if (v != null) setState(() { _inputSemester = v; }); },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subjectController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(hintText: "과목생성", hintStyle: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _unitController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(hintText: "단원생성", hintStyle: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _scoreController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(hintText: "점수", hintStyle: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _ThemeColors.brandGolden),
                  onPressed: () {
                    if (_subjectController.text.isEmpty || _scoreController.text.isEmpty) return;
                    double? parsedScore = double.tryParse(_scoreController.text);
                    if (parsedScore == null) return;

                    setState(() {
                      _allRecords.add(_ExamRecord(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        type: _selectedExamType!,
                        grade: _inputGrade,
                        semester: _inputSemester,
                        date: DateTime.now(),
                        subject: _subjectController.text,
                        unit: _unitController.text,
                        score: parsedScore,
                      ));
                      _subjectController.clear();
                      _unitController.clear();
                      _scoreController.clear();

                      FocusScope.of(context).unfocus();
                    });
                  },
                  child: const Text("저장", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),

            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _getFilteredRecords(_selectedExamType!).length,
                itemBuilder: (ctx, idx) {
                  final rec = _getFilteredRecords(_selectedExamType!)[idx];
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${rec.subject}[${rec.unit}]: ${rec.score.toInt()}점",
                          style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _allRecords.removeWhere((element) => element.id == rec.id);
                            });
                          },
                          child: const Icon(Icons.close, color: Colors.white60, size: 14),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            _buildFixedEvaluationChart(_selectedExamType!),
          ]
        ],
      ),
    );
  }

  Widget _buildFixedEvaluationChart(String type) {
    List<_ExamRecord> evalRecords = _getFilteredRecords(type);

    if (evalRecords.isEmpty) {
      return Container(
        height: 140,
        width: double.infinity,
        alignment: Alignment.center,
        child: Text(
          DkeLang.current == 'KO' ? "평가가 기록된 과목만 그래프에 나타나게한다" : "No evaluation marks matching filter.",
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      );
    }

    List<String> scoreLabels = ["100점", "90점", "80점", "70점", "60점"];
    const double hMax = 130.0;
    const double scoreMin = 60.0;
    const double scoreMax = 100.0;
    const double scoreRange = scoreMax - scoreMin;

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 25),
                ...scoreLabels.take(4).map((label) => Expanded(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Text(label, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                    )
                )),
                Align(
                  alignment: Alignment.topRight,
                  child: Text(scoreLabels.last, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 44),
              ],
            ),
          ),
          const SizedBox(width: 4),

          Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: 2.2,
                margin: const EdgeInsets.only(top: 25, bottom: 44),
                color: _ThemeColors.brandGolden.withOpacity(0.6),
              ),
              Positioned.fill(
                top: 25,
                bottom: 44,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (index) => Container(
                    width: 6,
                    height: 1.5,
                    color: _ThemeColors.brandGolden,
                  )),
                ),
              ),
            ],
          ),

          Expanded(
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Positioned.fill(
                  top: 10,
                  bottom: 0,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(width: 6), // 👑 Y축 구분선과 첫 막대 사이 여백 (20px 고정 매칭)
                        ...List.generate(evalRecords.length, (idx) {
                          final rec = evalRecords[idx];
                          final Color barColor = _evalColors[idx % _evalColors.length];

                          double scoreVal = rec.score.clamp(scoreMin, scoreMax);
                          double drawScoreHeight = ((scoreVal - scoreMin) / scoreRange) * hMax;
                          if (drawScoreHeight < 2) drawScoreHeight = 2;
                          if (drawScoreHeight > hMax) drawScoreHeight = hMax;

                          return Container(
                            width: 24, // 👑 컴팩트한 막대 가로 배치 공간 확보
                            margin: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: hMax + 16,
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Positioned(
                                        bottom: 0,
                                        child: Container(
                                          height: drawScoreHeight,
                                          width: 14,
                                          decoration: BoxDecoration(
                                            color: barColor,
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(2.0)),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: drawScoreHeight + 2,
                                        child: Text(
                                          "${rec.score.toInt()}",
                                          style: TextStyle(color: barColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // 👑 꼬여있던 과목명 렌더링 위젯을 Container 구조 내부로 귀속시켜 완벽하게 복원 완료
                                SizedBox(
                                  height: 36,
                                  child: Text(
                                    rec.subject,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    style: GoogleFonts.notoSansKr(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0, right: 0, bottom: 44,
                  child: Container(width: double.infinity, height: 2.2, color: _ThemeColors.brandGolden.withOpacity(0.6)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAdvancedChartDashboard(int tabIndex) {
    List<Map<String, dynamic>> rawData = _masterSubjectData;
    double multiplier = (tabIndex == 0) ? 1.0 : (tabIndex == 1) ? 5.0 : (tabIndex == 2) ? 22.0 : 250.0;

    List<Map<String, dynamic>> targetSubjects = [];
    for (var item in rawData) {
      bool isValid = false;
      if (tabIndex == 0 && item["hasStudiedToday"] == true) isValid = true;
      if (tabIndex == 1 && item["hasStudiedWeekly"] == true) isValid = true;
      if (tabIndex == 2 && item["hasStudiedMonthly"] == true) isValid = true;
      if (tabIndex == 3 && item["hasStudiedYearly"] == true) isValid = true;

      if (isValid) {
        double totalMins = (item["baseMinutes"] as int).toDouble() * multiplier;
        if (totalMins > 0) {
          targetSubjects.add({
            ...item,
            "calculatedMinutes": totalMins,
          });
        }
      }
    }

    targetSubjects.sort((a, b) => (b["calculatedMinutes"] as double).compareTo(a["calculatedMinutes"] as double));

    double maxMinutesFound = 0.0;
    for (var item in targetSubjects) {
      if ((item["calculatedMinutes"] as double) > maxMinutesFound) {
        maxMinutesFound = item["calculatedMinutes"] as double;
      }
    }

    double minCeiling = 180.0;
    if (tabIndex == 1) minCeiling = 2.0 * 60.0;
    if (tabIndex == 2) minCeiling = 5.0 * 60.0;
    if (tabIndex == 3) minCeiling = 5.0 * 60.0;

    if (maxMinutesFound < minCeiling) {
      maxMinutesFound = minCeiling;
    }

    double yAxisMaxBoundary = maxMinutesFound / 0.90;
    if (yAxisMaxBoundary <= 0) yAxisMaxBoundary = 100.0;

    if (tabIndex == 1 && yAxisMaxBoundary > 25.0 * 60.0) yAxisMaxBoundary = 25.0 * 60.0;
    if (tabIndex == 2 && yAxisMaxBoundary > 120.0 * 60.0) yAxisMaxBoundary = 120.0 * 60.0;
    if (tabIndex == 3 && yAxisMaxBoundary > 1500.0 * 60.0) yAxisMaxBoundary = 1500.0 * 60.0;

    List<String> dynamicYAxisLabels = [];
    for (int i = 4; i >= 0; i--) {
      double currentSliceValue = (yAxisMaxBoundary / 4) * i;
      if (tabIndex == 0) {
        dynamicYAxisLabels.add("${currentSliceValue.round()}m");
      } else {
        double hoursValue = currentSliceValue / 60.0;
        dynamicYAxisLabels.add("${hoursValue.toStringAsFixed(1)}h");
      }
    }

    List<Color> colorPalette = (tabIndex == 1) ? _weeklyColors : _todayColors;

    int totalMinutes = targetSubjects.fold<int>(0, (sum, item) {
      return sum + (item["calculatedMinutes"] as double).round();
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
                left: 42, right: 0, top: 25, bottom: 44,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (i) => Container(width: double.infinity, height: 0.8, color: Colors.white.withOpacity(0.08))),
                ),
              ),
              Positioned(
                left: 42, top: 25, bottom: 44,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(9, (i) => Container(width: i % 2 != 0 ? 4.0 : 0.0, height: 1.5, color: _ThemeColors.brandGolden.withOpacity(0.4))),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 34,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: 22),
                        ...dynamicYAxisLabels.take(4).map((label) => Expanded(child: Text(label, style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 9.5)))),
                        Text(dynamicYAxisLabels.last, style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 9.5)),
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
                        Positioned.fill(
                          top: 7,
                          bottom: 0,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(targetSubjects.length, (index) {
                                final data = targetSubjects[index];
                                const double hMaxDashboard = 120.0;
                                final Color pCol = colorPalette[index % colorPalette.length];

                                double currentMins = data["calculatedMinutes"] as double;
                                double drawScoreHeight = (currentMins / yAxisMaxBoundary) * hMaxDashboard;
                                double drawAvgHeight = ((data["averageScore"] as double) * (currentMins * 0.8) / yAxisMaxBoundary) * hMaxDashboard;

                                if (drawScoreHeight < 4) drawScoreHeight = 4;
                                if (drawAvgHeight < 2) drawAvgHeight = 2;
                                if (drawScoreHeight > hMaxDashboard) drawScoreHeight = hMaxDashboard;

                                return Container(
                                  width: 53,
                                  margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: hMaxDashboard + 16, width: 53,
                                        child: Stack(
                                          alignment: Alignment.bottomCenter,
                                          children: [
                                            Positioned(
                                              left: 10, bottom: 0,
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Text("${(data["averageScore"] * 100).toInt()}%", style: const TextStyle(color: Colors.white54, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                                  Container(
                                                    height: drawAvgHeight, width: 16,
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
                                                    height: drawScoreHeight, width: 16,
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
                                        child: Text(data["subject"], textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold, height: 1.2)),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
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
                        painter: _GsuPiePainter(targetSubjects: targetSubjects, colors: colorPalette),
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
                  final int calculatedMin = (item["calculatedMinutes"] as double).round();
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

  _GsuPiePainter({required this.targetSubjects, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = targetSubjects.fold<double>(0.0, (s, i) => s + (i["calculatedMinutes"] as double));
    if (total == 0) return;

    final Paint p = Paint()..style = PaintingStyle.fill..isAntiAlias = true;
    double start = -math.pi / 2;

    for (int i = 0; i < targetSubjects.length; i++) {
      final double calculatedMin = targetSubjects[i]["calculatedMinutes"] as double;
      final double sweep = (calculatedMin / total) * 2 * math.pi;
      p.color = colors[i % colors.length];
      canvas.drawArc(Rect.fromLTWH(0, 0, size.width, size.height), start, sweep, true, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) => true;
}