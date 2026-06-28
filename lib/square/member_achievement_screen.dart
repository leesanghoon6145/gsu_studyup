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

// 🎯 성적 입력을 위한 내부 데이터 모델링 패킷 정의 (선배님 피드백 메트릭 인프라 보강)
class _ExamRecord {
  final String id;
  final String type; // 주평가, 단원평가, 중간고사, 기말고사, 모의고사
  final int grade;   // 1, 2, 3학년
  final int semester; // 1, 2학기
  final DateTime date;
  final String subject;
  final String unit;
  final double score;

  // 🆕 [선배님 지시사항]: 팝업창 저장 데이터 세션 확장 바인딩
  final String durationText;   // 소요시간 (예: 45분)
  final String difficultyLevel; // 난이도 (매우쉬움, 쉬움, 보통, 어려움, 매우어려움)
  final int starSatisfaction;  // 시험 만족도 (별점 1~5)
  final List<String> errorCauses; // 실수 원인 복수 선택 리스트
  final String reviewRequired;  // 복습 필요 여부 (필요, 예정, 불필요)

  // 모의고사 전용 추가 필드
  final String mockMonth;      // 몇월 모의고사
  final String mockRank;       // 등급 또는 석차

  _ExamRecord({
    required this.id,
    required this.type,
    required this.grade,
    required this.semester,
    required this.date,
    required this.subject,
    required this.unit,
    required this.score,
    this.durationText = "45분",
    this.difficultyLevel = "보통",
    this.starSatisfaction = 5,
    this.errorCauses = const ["개념부족"],
    this.reviewRequired = "필요",
    this.mockMonth = "",
    this.mockRank = "",
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

  String? _selectedExamType = "주평가";
  List<_ExamRecord> _allRecords = [];

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _scoreController = TextEditingController();

  int _inputGrade = 2;
  int _inputSemester = 1;

  String _filterExamType = "주평가";
  int _filterGrade = 2;
  int _filterSemester = 1;

  String _inputYear = "2026년";
  String _inputMonth = "6월";
  String _inputWeek = "1주차";
  String _inputBigUnit = "대단원 1";
  String _inputMidUnit = "중단원 1";
  String _inputSemesterGroup = "1학기";

  _ExamRecord? _lastSavedRecordForDisplay;

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
      _ExamRecord(id: "1", type: "주평가", grade: 2, semester: 1, date: DateTime.now(), subject: DkeLang.current == 'KO' ? "수학" : "Math", unit: "2026년 6월 1주차", score: 95, durationText: "45분", difficultyLevel: "보통", starSatisfaction: 4, errorCauses: ["계산실수"], reviewRequired: "예정"),
      _ExamRecord(id: "2", type: "주평가", grade: 2, semester: 1, date: DateTime.now(), subject: DkeLang.current == 'KO' ? "영어" : "English", unit: "2026년 6월 1주차", score: 70, durationText: "50분", difficultyLevel: "어려움", starSatisfaction: 3, errorCauses: ["시간부족"], reviewRequired: "필요"),
      _ExamRecord(id: "3", type: "단원평가", grade: 2, semester: 1, date: DateTime.now(), subject: DkeLang.current == 'KO' ? "국어" : "Korean", unit: "대단원 1 (중단원 1)", score: 85, durationText: "40분", difficultyLevel: "쉬움", starSatisfaction: 5, errorCauses: ["개념부족"], reviewRequired: "불필요"),
    ];
    if (_allRecords.isNotEmpty) {
      _lastSavedRecordForDisplay = _allRecords.first;
    }
  }
    List<_ExamRecord> _getFilteredRecords(String type) {
      return _allRecords.where((rec) {
        bool baseMatch = rec.type == type
            && rec.grade == _filterGrade
            && rec.semester == _filterSemester;

        if (type == "주평가") {
          return baseMatch && rec.unit.contains(_inputYear) && rec.unit.contains(_inputMonth) && rec.unit.contains(_inputWeek);
        } else if (type == "단원평가") {
          return baseMatch && rec.unit.contains(_inputBigUnit) && rec.unit.contains(_inputMidUnit);
        } else {
          return baseMatch && rec.unit.contains(_inputSemesterGroup);
        }
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

  // 🆕 [선배님 지시 완료]: 당근과 채찍 + 전문적 주석 해설 알고리즘이 내장된 150자 이상 분석 팝업 개설
  void _showDetailAnalysisPopup(String type) {
    final filtered = _getFilteredRecords(type);
    String diagnosisText = "";

    if (filtered.isEmpty) {
      diagnosisText = "현재 해당 카테고리에 누적된 성적 메트릭이 식별되지 않아 기본 정성 분석을 수행합니다.\n\n"
          "학습자의 메타인지(자신의 인지 활동을 모니터링하고 조절하는 능력) 수준은 양호하나 과목 간 편차가 존재할 수 있습니다. "
          "실전에서 흔들리지 않기 위해서는 개념 정합성 확인 프로세스를 고도화해야 합니다. 언제나 가능성이 열려있으니 포기하지 말고 전진합시다.";
    } else {
      final lastExam = filtered.last;
      double avgScore = lastExam.score;

      if (avgScore >= 90) {
        diagnosisText = "[$type 분석 보고서 - 성취도 최상위권]\n\n"
            "금일 기록된 ${lastExam.subject} 평가는 매우 뛰어난 성과를 보여주고 있습니다. "
            "스스로 설정한 인지적 과부하를 통제하며 고난도 문항에 대한 학업적 몰입도(학업 스트레스 속 집중 유지 밀도)를 최상으로 유지했습니다. "
            "자아참조효과(새로운 정보를 자신과 연관시켜 기억 효율을 높이는 현상)가 완벽하게 발현되어 개념 정합성이 매우 견고합니다. "
            "이 끈기를 유지한다면 목표하는 서울대학교 진입은 현실이 될 것입니다. 대단히 자랑스럽습니다, 계속해서 도약하십시오!";
      } else if (avgScore >= 80) {
        diagnosisText = "[$type 분석 보고서 - 성취도 안정권]\n\n"
            "이번 ${lastExam.subject} 세션은 전반적인 이해도가 견고하나 세부 변별 과정에서 미세한 빈틈이 발견됩니다. "
            "학습 초기 단계에서 스키마(지식의 구조적 네트워크) 확장에 과도한 시간이 할당되는 지체 현상이 식별되었습니다. "
            "이로 인해 응용 심화 추론 단계에서의 시간 안배 엇박자가 유발될 수 있습니다. "
            "충분히 최상위권으로 치고 올라갈 수 있는 훌륭한 저력을 가진 학습자이니, 오답 변형 훈련 강도를 의도적으로 조금만 더 높여봅시다. 파이팅입니다!";
      } else {
        // 🚨 성적이 떨어지거나 낮은 경우: 따끔한 채찍 한마디 탑재 완료
        diagnosisText = "[$type 분석 보고서 - 경고 및 정밀 진단 제언]\n\n"
            "냉정하게 진단하겠습니다. 현재 기록된 ${lastExam.subject} 성취도는 기초 정착 단계에서 심각한 균열을 나타내고 있습니다. "
            "오답 변별 과정에서 구조적 오인(개념의 뼈대를 잘못 이해하고 오답을 도출하는 현상)이 빈번하게 관찰되며, "
            "인지적 기만(본인이 이해했다고 주관적으로 착각하는 심리적 상태)에 빠져 복습 프로세스를 무분별하게 생략했을 가능성이 매우 큽니다. "
            "지금의 느슨한 태도로는 글로벌 경쟁에서 도태될 뿐입니다! 당장 취약 교과 단원의 기본 인지 평정 수치 복습에 즉각 착수하십시오. "
            "단, 낙담하라는 뜻이 아닙니다. 이 따끔한 경고를 성장의 채찍질로 삼아 내일부터 의도적인 초기 몰입 속도를 가속화한다면 반드시 반등할 수 있습니다.";
      }
    }

    _showReportPopup(context, "👑 DKE 교육성취 정밀 진단서", diagnosisText);
  }

  void _showFeedbackRegistrationDialog({
    required String type,
    required String subject,
    required String unit,
    required double score,
    required int grade,
    required int semester,
  }) {
    final TextEditingController durationController = TextEditingController(text: "45분");
    final TextEditingController mockMonthController = TextEditingController(text: "6월");
    final TextEditingController mockRankController = TextEditingController(text: "1등급");

    String difficulty = "보통";
    int rating = 5;
    List<String> selectedCauses = ["개념부족"];
    String reviewStatus = "필요";

    final List<String> diffOptions = ["매우쉬움", "쉬움", "보통", "어려움", "매우어려움"];
    final List<String> causeOptions = ["개념부족", "계산실수", "시간부족", "문해력 부족", "긴장", "집중력 부족", "기타"];
    final List<String> reviewOptions = ["필요", "예정", "불필요"];

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          return StatefulBuilder(
              builder: (context, setPopupState) {
                return Dialog(
                    backgroundColor: _ThemeColors.premiumCardBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.4), width: 1.5),
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Exam Evaluation Settings",
                                        style: GoogleFonts.gowunBatang(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      Text(
                                        type == "모의고사" ? "모의고사 정밀 평가 진단" : "시험 성취도 세부 피드백 설정",
                                        style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                                  onPressed: () => Navigator.pop(ctx),
                                )
                              ],
                            ),
                            const Divider(color: Colors.white10, height: 16),

                            if (type == "모의고사") ...[
                              Text("• 몇 월 모의고사 (직접 입력)", style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: mockMonthController,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true, fillColor: Colors.black26,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white12), borderRadius: BorderRadius.circular(6)),
                                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: _ThemeColors.brandGolden), borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text("• 등급 또는 석차 (직접 입력)", style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: mockRankController,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true, fillColor: Colors.black26,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white12), borderRadius: BorderRadius.circular(6)),
                                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: _ThemeColors.brandGolden), borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            Text("1. 소요시간 (직접 입력)", style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: durationController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                filled: true, fillColor: Colors.black26,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white12), borderRadius: BorderRadius.circular(6)),
                                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: _ThemeColors.brandGolden), borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                            const SizedBox(height: 14),

                            Text("2. 난이도 설정 (단일 선택)", style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 4, runSpacing: 4,
                              children: diffOptions.map((d) {
                                bool isSel = difficulty == d;
                                return ChoiceChip(
                                  label: Text(d, style: TextStyle(color: isSel ? Colors.black : Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  selected: isSel,
                                  selectedColor: _ThemeColors.brandGolden,
                                  backgroundColor: Colors.black38,
                                  onSelected: (bool selected) { if (selected) setPopupState(() => difficulty = d); },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),

                            Text("3. 시험 만족도 지표", style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(5, (index) {
                                int currentStarWeight = index + 1;
                                bool isActive = currentStarWeight <= rating;
                                return GestureDetector(
                                  onTap: () => setPopupState(() => rating = currentStarWeight),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 4.0),
                                    child: Icon(
                                      Icons.star_rounded,
                                      color: isActive ? _ThemeColors.brandGolden : Colors.white24,
                                      size: 28,
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 14),

                            Text("4. 실수 원인 진단 (복수 선택 가능)", style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                children: causeOptions.map((cause) {
                                  bool isChecked = selectedCauses.contains(cause);
                                  return CheckboxListTile(
                                    title: Text(cause, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                    value: isChecked,
                                    dense: true,
                                    activeColor: _ThemeColors.brandGolden,
                                    checkColor: Colors.black,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    contentPadding: EdgeInsets.zero,
                                    onChanged: (bool? checked) {
                                      setPopupState(() {
                                        if (checked == true) {
                                          if (!selectedCauses.contains(cause)) selectedCauses.add(cause);
                                        } else {
                                          selectedCauses.remove(cause);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 14),

                            Text("5. 복습 필요 여부 선택", style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: reviewOptions.map((r) {
                                bool isSel = reviewStatus == r;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6.0),
                                  child: ChoiceChip(
                                    label: Text(r, style: TextStyle(color: isSel ? Colors.black : Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    selected: isSel,
                                    selectedColor: _ThemeColors.brandGolden,
                                    backgroundColor: Colors.black38,
                                    onSelected: (bool selected) { if (selected) setPopupState(() => reviewStatus = r); },
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 18),

                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: _ThemeColors.brandGolden, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                onPressed: () async {
                                  String finalUnitLabel = unit;
                                  if (type == "모의고사") {
                                    finalUnitLabel = "${mockMonthController.text} 모의고사 (${mockRankController.text})";
                                  }

                                  final newRecord = _ExamRecord(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    type: type,
                                    grade: grade,
                                    semester: semester,
                                    date: DateTime.now(),
                                    subject: subject,
                                    unit: finalUnitLabel,
                                    score: score,
                                    durationText: durationController.text,
                                    difficultyLevel: difficulty,
                                    starSatisfaction: rating,
                                    errorCauses: List.from(selectedCauses),
                                    reviewRequired: reviewStatus,
                                    mockMonth: type == "모의고사" ? mockMonthController.text : "",
                                    mockRank: type == "모의고사" ? mockRankController.text : "",
                                  );

                                  // 👑 [학부모 메인보드 파이프라인 완벽 연동]: SharedPreferences 공유 스토리지에 동적 패킷 강제 인젝션 처리
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString('dke_parent_shared_type', type);
                                  await prefs.setString('dke_parent_shared_subject', subject);
                                  await prefs.setDouble('dke_parent_shared_score', score);
                                  await prefs.setString('dke_parent_shared_duration', durationController.text);
                                  await prefs.setString('dke_parent_shared_difficulty', difficulty);

                                  setState(() {
                                    _allRecords.add(newRecord);
                                    _lastSavedRecordForDisplay = newRecord;
                                    _subjectController.clear();
                                    _unitController.clear();
                                    _scoreController.clear();
                                  });

                                  Navigator.pop(ctx);
                                  FocusScope.of(context).unfocus();
                                },
                                child: Text("확인", style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                );
              }
          );
        }
    );
  }

  Widget _buildBeautifulFeedbackDisplayPanel() {
    if (_lastSavedRecordForDisplay == null) {
      return const SizedBox.shrink();
    }

    final rec = _lastSavedRecordForDisplay!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ThemeColors.premiumCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.35), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent Exam Metric Analysis",
            style: GoogleFonts.gowunBatang(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            "[최근 작성] ${rec.type} 성취 피드백 메트릭스",
            style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            "타겟 과목: ${rec.subject} (${rec.unit}) | 점수: ${rec.score.toInt()}점",
            style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),

          _buildMetricDisplayItem("1. 시험 소요시간", rec.durationText, Icons.timer_outlined),
          _buildMetricDisplayItem("2. 출제 난이도", rec.difficultyLevel, Icons.speed_outlined),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_outline_rounded, color: _ThemeColors.brandGolden, size: 14),
                    const SizedBox(width: 6),
                    Text("3. 시험 만족도", style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12.5)),
                  ],
                ),
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      Icons.star_rounded,
                      color: (i < rec.starSatisfaction) ? _ThemeColors.brandGolden : Colors.white12,
                      size: 14,
                    );
                  }),
                ),
              ],
            ),
          ),

          _buildMetricDisplayItem("4. 주요 실수 원인", rec.errorCauses.join(", "), Icons.report_problem_outlined),
          _buildMetricDisplayItem("5. 복습 필요 여부", rec.reviewRequired, Icons.flaky_outlined),
        ],
      ),
    );
  }

  Widget _buildMetricDisplayItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: _ThemeColors.brandGolden, size: 14),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12.5)),
            ],
          ),
          Text(value, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
        ],
      ),
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
        "2. SUBJECT: \$English\n"
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

              _buildFixedEvaluationChart(_selectedExamType ?? "주평가"),

              _buildBeautifulFeedbackDisplayPanel(),

              // 🆕 [선배님 핵심 지시 완료]: 학습시간 바로 위에 장착된 연동형 가변 팝업 분석 버튼 인프라
// 🆕 [선배님 지시사항]: 학습 시간 바로 위에 탑재되는 버튼 이름 가변형 정밀 분석 브릿지 인프라
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D1527),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE5C158), width: 1.2),
                    ),
                  ),
                  onPressed: () {
                    final random = math.Random();
                    String currentType = _selectedExamType ?? "주평가";
                    final filtered = _allRecords.where((r) => r.type == currentType).toList();
                    String diagnosisText = "";

                    // 1️⃣ [90점 이상]
                    final dynamicGoodOpenings = [
                      "이번 평가에서 90점 이상의 우수한 고득점을 기록한 것은 학습자의 숨겨진 잠재력이 마침내 표면 위로 발현되기 시작했음을 증명하는 매우 기쁜 소식입니다. ",
                      "이번에 달성한 높은 성적은 그동안 묵묵히 쌓아온 학습의 밀도가 드디어 가시적인 성과로 도출되었음을 시사하는 대단히 고무적인 결과물입니다. "
                    ];
                    final dynamicGoodClosings = [
                      "그러나 현재의 기초 체급을 고려할 때, 이번 결과에 취해 단 한순간이라도 안일해지는 즉시 성적은 하락세로 돌아설 수 있습니다. 진정한 만점자로 안착하기 위해서는 실전에서 발생한 미세한 균열을 메워야 하므로, 틀린 문제는 반드시 누적 오답정리(틀린 원인을 기록하고 분석하는 과정)를 완수하고 최소 3번 이상 반복하여 완전히 본인의 것으로 만드는 철저한 회독 습관을 기르십시오. 자만하지 않고 이 정합성 확인 루틴을 성실히 유지한다면, 다음 실전에서도 흔들리지 않는 진짜 탑클래스로 우뚝 설 것입니다.",
                      "다만 지금의 위치에서 방심하여 루틴이 느슨해진다면 차기 평가에서는 아쉬운 결과를 맛보게 될 수 있습니다. 완전무결한 성취를 지속하기 위해서는 취약 문항의 누적 오답정리(틀린 원인을 기록하고 분석하는 과정)를 철저히 이행하고, 오답을 3번 이상 재차 정밀 분석하여 풀어내는 훈련이 필수적입니다. 나태함을 경계하고 메타인지 루틴을 사수하여 흔들림 없는 정점에 도달하십시오."
                    ];

                    // 2️⃣ [80점대]
                    final dynamicMidOpenings = [
                      "현재 도달한 성취도의 위치는 조금만 더 정밀하게 메타인지(자신의 인지 활동을 모니터링하고 조절하는 능력)를 조율하면 언제든 만점까지 단숨에 바라볼 수 있는 고지가 바로 눈앞에 와 있는 단계입니다. ",
                      "이번에 확보한 상위권 점수는 안정적인 성장을 의미하지만, 동시에 조금의 임계점만 넘어서면 언제든 최상위권의 벽을 깨부수고 만점으로 직행할 수 있는 가장 중요한 기로의 점수대입니다. "
                    ];
                    final dynamicMidClosings = [
                      "지금 단계에서 가장 유의해야 할 것은 '이 정도면 됐다'는 주관적인 안주와 타협입니다. 문항 분석 시 개념 스키마(지식의 구조적 네트워크)의 뼈대는 훌륭하나, 조건 해석의 정밀도가 다소 부족하여 감점이 발생하고 있습니다. 취약 단원의 고난도 변형 문제를 집중 공략하고 실전 시간 안배의 정밀도를 한 단계만 가속화하십시오. 정상으로 가는 마지막 관문이니, 조금만 더 고도의 학업적 몰입도를 발휘해 만점의 영광을 함께 쟁취합시다!",
                      "현재 상태에서 성장을 한 단계 더 정체시키는 원인은 주관적인 안일함에 있을 수 있습니다. 인지 구조 내의 기본 스키마(지식의 구조적 네트워크)는 안정적이나, 세부 변별 과정에서 집중력의 미세한 누수가 관찰됩니다. 안일함을 지워내고 문항 단독 피드백 검토 단계를 한층 더 확장하십시오. 조금만 더 치열하게 벽을 두드린다면 반드시 차기 세션에서 만점을 거머쥘 수 있습니다."
                    ];

                    // 3️⃣ [70점대]
                    final dynamicSeventyOpenings = [
                      "이번 평가에서 기록한 70점대의 수치는 학습자가 현재 지닌 역량에 비해 다소 아쉬운 결과이며, 현재의 약점을 방치할 경우 아래 점수대로 내려갈 수 있는 경계선에 있습니다. ",
                      "현재 포지션은 탄탄한 도약이냐 지체냐를 결정짓는 중대한 기로입니다. 구조적 점검이 신속하게 이루어지지 않는다면 다음 평가에서 예상치 못한 하락세를 맞이할 위험이 공존합니다. "
                    ];
                    final dynamicSeventyClosings = [
                      "하지만 역설적으로, 지금 이 순간 올바른 피드백을 통해 노력을 올바르게 투입한다면 전체 점수대 중 가장 폭발적이고 드라마틱하게 성적이 오를 수 있는 최고의 황금 구간이기도 합니다. 발생하는 오답들은 구조적 오인(개념의 뼈대를 잘못 이해하고 오답을 도출하는 현상)을 다듬으면 충분히 해결 가능한 자산입니다. 기본 원리 분석부터 차근차근 다시 정립하여 취약점을 지워내십시오. 가장 극적인 반등의 주인공은 바로 학습자가 될 수 있습니다.",
                      "좌절할 필요는 전혀 없습니다. 이 구간은 문제점을 명확히 인지하고 혁신하기만 하면 교과과정 전체에서 가장 웅장한 점수 상승 폭을 기록할 수 있는 기회의 땅입니다. 현재의 부진은 눈으로만 대충 훑어본 인지적 기만(이해했다고 착각하는 심리 상태)에서 비롯된 균열일 뿐입니다. 오늘부터 취약 단원 기본서 피드백을 차분하고 독하게 이행해 나간다면 차기 평가에서 가장 놀라운 도약을 이루어낼 것입니다."
                    ];

                    // 4️⃣ [60점대]
                    final dynamicSixtyOpenings = [
                      "현재 누적된 60점대의 성취도는 교과 개념의 정착 단계에서 예상보다 깊은 균열이 발생했음을 나타내며, 신속히 반등의 불씨를 지피지 않으면 하락세를 멈추기 어려운 주의 단계입니다. ",
                      "현재 점수대는 냉정하게 직시했을 때 하위권으로 정착할 것인가, 혹은 상위권으로 치고 올라갈 것인가를 가르는 매우 엄중한 인지적 기로에 서 있음을 뜻합니다. "
                    ];
                    final dynamicSixtyClosings = [
                      "불안해하기보다는 학습 습관의 구조적 전환이 시급함을 깨닫는 계기로 삼아야 합니다. 주관적인 인지적 기만(완전히 이해하지 못했음에도 이해했다고 착각하는 상태)을 완전히 걷어내고, 기본 스키마(지식의 구조적 네트워크) 확장에 몰입해야 합니다. 틀린 문항을 단순히 확인하는 것에 그치지 말고 원리를 파고드는 깊이 있는 복습 루틴을 오늘부터 즉시 가속화하십시오. 지금의 경각심을 변화의 발판으로 삼는다면 충분히 반등할 수 있습니다.",
                      "현재의 성적은 노력이 부족했다기보다는 문항을 분석하고 접근하는 과정에서 고질적인 구조적 오인(개념의 뼈대를 잘못 매핑하는 현상)이 반복되고 있음을 방증합니다. 느슨해진 오답 정비 체계를 철저히 다시 채찍질하고, 핵심 원리 중심의 복습 인프라를 전면 재구축하십시오. 지금 태도를 혁신하지 않으면 다음 평가의 반등은 어려워집니다. 마음을 다잡고 오늘부터 집중도를 극대화합시다."
                    ];

                    // 5️⃣ [60점 미만]
                    final dynamicLowOpenings = [
                      "현재 기록된 평가 수치는 기초 개념 정착 단계에서 전반적인 재조정과 보완이 시급함을 가리키는 엄중한 진단서입니다. ",
                      "현재의 지표는 학습 프로세스 전체에 걸쳐 개념적 누수가 누적되었음을 경고하고 있으며, 즉각적인 학습 루틴의 전면적인 개혁이 필요한 순간입니다. "
                    ];
                    final dynamicLowClosings = [
                      "기초가 흔들린 상태에서 문제 풀이에만 집착하는 것은 인지적 과부하를 가중시킬 뿐입니다. 조급한 마음을 완전히 가라앉히고, 단원별 교과서 핵심 원리 분석과 기본 어휘 스키마(지식의 구조적 네트워크) 빌딩에 즉각 착수하십시오. 기초부터 차근차근 벽돌을 쌓아 올린다면 성적은 반드시 정직하게 반응합니다. 나태해진 마음을 다잡고 오늘 밤부터 기초 평정 수치를 메우는 복습에 집중해 주십시오.",
                      "현재 발생하는 대부분의 오답은 구조적 오인(개념의 기본 뼈대를 오해하는 현상)을 방치한 채 진도만 나간 부작용입니다. 지금 당장 멈추어 서서 취약 단원의 개념을 완벽히 소화하는 인내의 시간이 절대적으로 요구됩니다. 무기력함에 빠지지 말고, 베이스라인부터 다시 견고하게 다지겠다는 단단한 각오로 오늘부터 학습 속도와 밀도를 점진적으로 끌어올려 주십시오."
                    ];

                    if (filtered.isEmpty) {
                      diagnosisText = "현재 해당 카테고리에 누적된 데이터셋이 식별되지 않아 기본 정성 분석을 수행합니다.\n\n학습자의 메타인지 상태는 평균치에 도달했으나 실전 정합성을 높이기 위한 개념 오답 관리가 요구됩니다. 용기를 잃지 말고 내일의 세션에 몰입하십시오.";
                    } else {
                      double lastScore = filtered.last.score;
                      if (lastScore >= 90) {
                        // 🛠️ 괄호 꼬임 레이어 단 한 개의 유실도 없이 정밀 마감 완료
                        diagnosisText = dynamicGoodOpenings[random.nextInt(dynamicGoodOpenings.length)] + dynamicGoodClosings[random.nextInt(dynamicGoodClosings.length)];
                      } else if (lastScore >= 80) {
                        diagnosisText = dynamicMidOpenings[random.nextInt(dynamicMidOpenings.length)] + dynamicMidClosings[random.nextInt(dynamicMidClosings.length)];
                      } else if (lastScore >= 70) {
                        diagnosisText = dynamicSeventyOpenings[random.nextInt(dynamicSeventyOpenings.length)] + dynamicSeventyClosings[random.nextInt(dynamicSeventyClosings.length)];
                      } else if (lastScore >= 60) {
                        diagnosisText = dynamicSixtyOpenings[random.nextInt(dynamicSixtyOpenings.length)] + dynamicSixtyClosings[random.nextInt(dynamicSixtyClosings.length)];
                      } else {
                        diagnosisText = dynamicLowOpenings[random.nextInt(dynamicLowOpenings.length)] + dynamicLowClosings[random.nextInt(dynamicLowClosings.length)];
                      }
                    }

                    if (diagnosisText.length < 350) {
                      diagnosisText += " [추가 정밀 권고] 현재 학습 체계의 임계점(성취도가 도약하기 위해 필요한 최소한의 학업 밀도)을 넘어서기 위해서는 절대 주관적인 타협이나 나태함에 빠져서는 안 됩니다. 스스로의 가능성을 신뢰하고 정합성 확인 루틴을 독하게 사수하십시오!";
                    }

                    SharedPreferences.getInstance().then((prefs) {
                      prefs.setString('dke_parent_shared_type', currentType);
                      prefs.setString('dke_parent_shared_diagnosis', diagnosisText);
                    });

                    _showReportPopup(context, "👑 DKE 교육성취 정밀 진단서", diagnosisText);
                  },
                  icon: const Icon(Icons.psychology_outlined, color: Color(0xFFE5C158), size: 18),
                  label: Text(
                    "[${_selectedExamType ?? '주평가'} 분석 보고서 조회하기] 🔺",
                    style: GoogleFonts.notoSansKr(color: const Color(0xFFE5C158), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Text(
                "Learning Duration Summary",
                style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
              ),
              Text(
                "학습 시간",
                style: GoogleFonts.notoSansKr(
                  color: _ThemeColors.brandGolden,
                  fontWeight: FontWeight.bold,
                  fontSize: 23,
                ),
              ),
              const SizedBox(height: 10),

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

  Widget _buildMyExamScoreSection() {
    final List<String> examTypes = ["주평가", "단원평가", "중간고사", "기말고사", "모의고사"];
    final List<String> years = ["2026년", "2027년", "2028년", "2029년", "2030년"];
    final List<String> months = List.generate(12, (i) => "${i + 1}월");
    final List<String> weeks = ["1주차", "2주차", "3주차", "4주차", "5주차"];
    final List<String> bigUnits = ["대단원 1", "대단원 2", "대단원 3", "대단원 4"];
    final List<String> midUnits = ["중단원 1", "중단원 2", "중단원 3", "중단원 4"];
    final List<String> semesters = ["1학기", "2학기"];

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
                      "[${_selectedExamType} 입력 및 과거 선택 조회]",
                      style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_selectedExamType == "주평가") ...[
                  _buildSubFilterLabel("년도 선택"),
                  _buildSubScrollRow(years, _inputYear, (v) => setState(() => _inputYear = v!)),
                  const SizedBox(height: 8),
                  _buildSubFilterLabel("월 선택"),
                  _buildSubScrollRow(months, _inputMonth, (v) => setState(() => _inputMonth = v!)),
                  const SizedBox(height: 8),
                  _buildSubFilterLabel("주 선택"),
                  _buildSubScrollRow(weeks, _inputWeek, (v) => setState(() => _inputWeek = v!)),
                ] else if (_selectedExamType == "단원평가") ...[
                  _buildSubFilterLabel("대단원 선택"),
                  _buildSubScrollRow(bigUnits, _inputBigUnit, (v) => setState(() => _inputBigUnit = v!)),
                  const SizedBox(height: 8),
                  _buildSubFilterLabel("중단원 선택"),
                  _buildSubScrollRow(midUnits, _inputMidUnit, (v) => setState(() => _inputMidUnit = v!)),
                ] else ...[
                  _buildSubFilterLabel("학기 선택"),
                  Row(
                    children: semesters.map((sem) => _buildSubMiniBtn(sem, _inputSemesterGroup == sem, () => setState(() => _inputSemesterGroup = sem))).toList(),
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 12),

                Text("그래프 출력 타겟 지정 (학년 / 학기)", style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontSize: 11.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
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
                            onChanged: (v) { if (v != null) setState(() { _filterGrade = v; }); },
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
                            onChanged: (v) { if (v != null) setState(() { _filterSemester = v; }); },
                          ),
                        ),
                      ),
                    ),
                  ],
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

                    String generatedUnitLabel = _unitController.text;
                    if (_selectedExamType == "주평가") {
                      generatedUnitLabel = "$_inputYear $_inputMonth $_inputWeek";
                    } else if (_selectedExamType == "단원평가") {
                      generatedUnitLabel = "$_inputBigUnit ($_inputMidUnit)";
                    } else {
                      generatedUnitLabel = _inputSemesterGroup;
                    }

                    _showFeedbackRegistrationDialog(
                      type: _selectedExamType!,
                      subject: _subjectController.text,
                      unit: generatedUnitLabel,
                      score: parsedScore,
                      grade: _inputGrade,
                      semester: _inputSemester,
                    );
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
                              if (_lastSavedRecordForDisplay?.id == rec.id) {
                                _lastSavedRecordForDisplay = _allRecords.isNotEmpty ? _allRecords.last : null;
                              }
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
          ]
        ],
      ),
    );
  }

  Widget _buildSubScrollRow(List<String> items, String selectedValue, ValueChanged<String?> onSelected) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: items.map((item) => _buildSubMiniBtn(item, selectedValue == item, () => onSelected(item))).toList(),
      ),
    );
  }

  Widget _buildSubFilterLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
      child: Text(label, style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildSubMiniBtn(String text, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? _ThemeColors.brandGolden : Colors.black38,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _ThemeColors.brandGolden.withOpacity(isSelected ? 0.7 : 0.2)),
          ),
          child: Text(text, style: GoogleFonts.notoSansKr(color: isSelected ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
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
    const double hMax = 210.0;
    const double scoreMin = 60.0;
    const double scoreMax = 100.0;
    const double scoreRange = scoreMax - scoreMin; // = 40.0

    return SizedBox(
      height: 280,
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
                        const SizedBox(width: 6),
                        ...List.generate(evalRecords.length, (idx) {
                          final rec = evalRecords[idx];
                          final Color barColor = _evalColors[idx % _evalColors.length];

                          double scoreVal = rec.score.clamp(scoreMin, scoreMax);
                          double drawScoreHeight = ((scoreVal - scoreMin) / scoreRange) * hMax;
                          if (drawScoreHeight < 2) drawScoreHeight = 2;
                          if (drawScoreHeight > hMax) drawScoreHeight = hMax;

                          return Container(
                            width: 24,
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
                        ...dynamicYAxisLabels.take(4).map((label) => Expanded(child: Text(label, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 9.5)))),
                        Text(dynamicYAxisLabels.last, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 9.5)),
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
                color: _ThemeColors.brandGolden,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.2),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          DkeLang.current == 'KO' ? "데이터베이스 동기화 알림" : "Database Sync Notification",
                          style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                      ),
                      Text(
                          DkeLang.current == 'KO' ? "(데이터를 안전하게 동기화 중입니다...)" : "(Synchronizing data storage safely...)",
                          style: GoogleFonts.notoSansKr(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w600)
                      ),
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