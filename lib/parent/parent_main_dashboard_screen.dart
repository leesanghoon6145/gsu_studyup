import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 3가지 준비된 위젯 파일을 정확하게 연결합니다.
import 'parent_live_status_widget.dart';
import 'parent_detailed_analysis_widget.dart';
import 'parent_evaluation_analysis_widget.dart';

class ParentMainDashboardScreen extends StatefulWidget {
  final String parentEmail;
  final String childName;

  const ParentMainDashboardScreen({
    Key? key,
    required this.parentEmail,
    this.childName = "홍길동",
  }) : super(key: key);

  @override
  _ParentMainDashboardScreenState createState() => _ParentMainDashboardScreenState();
}

class _ParentExamRecord {
  final String id;
  final String type;
  final int grade;
  final int semester;
  final String subject;
  final String unit;
  final double score;

  _ParentExamRecord({
    this.id = "",
    required this.type,
    required this.grade,
    required this.semester,
    required this.subject,
    required this.unit,
    required this.score,
  });
}

class _ParentMainDashboardScreenState extends State<ParentMainDashboardScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isVipMember = false;

  static const Color luxuryDarkBg = Color(0xFF030712);
  static const Color premiumCardBg = Color(0xFF0D1527);
  static const Color brandGolden = Color(0xFFE5C158);

  bool _isMonitoringActive = false;
  int _monitoringCountdown = 60;
  num _currentElapsedTime = 36;
  int _totalCollectedStars = 387;

  // 자녀 폰에 전송 성공한 최근 표준시 시각 레이블을 기록하는 상태값
  String _lastSentTimeText = "";

  String _selectedEvaluationType = "주평가";
  String _selectedBigUnit = "대단원 1";
  String _selectedMidUnit = "중단원 1";
  int _selectedSemesterFilter = 1;

  late TabController _timeTabController;

  List<_ParentExamRecord> _mirroredExamRecords = [];

  final String _embeddedStrictFeedbackReport =
      "[종합 진단 피드백]\n\n"
      "금일 진행된 이규현 학습자의 주도적 학업 세션은 메타인지적 관점에서 매우 유의미한 행동 변화를 나타냈습니다. "
      "스스로 설정한 타임라인 내부에서 인지적 과부하를 능동적으로 제어하며, 고난도 교과 문항에 대한 학업적 몰입 밀도를 극대하여 유지하였습니다. "
      "과목 간 시간 분배의 균형 수치 또한 안정권에 안착했으나, 학습 초기 단계에서 정합성을 검증하는 프로세스에 다소 과도한 시간이 할당되는 지체 현상이 식별되었습니다. "
      "이는 후반부 응용 심화 추론 단계에서의 정밀도 스펙트럼을 저해하는 요인이 될 수 있으므로, 초기 몰입 속도를 가속화하려는 의도적인 피드백 조율이 요구됩니다. "
      "전반적인 교과 이해도는 최상위권 진입에 하등의 무리가 없는 고도화된 수준이나, 오답 변별 과정에서 자아참조효과에 지나치게 의존하는 경향은 향후 객관적 진단 데이터와의 크로스 매핑을 통해 보완되어야 할 지점입니다.";

  final String _embeddedDetailedAnalysisLog =
      "[상세분석기록]\n\n"
      "• 상세내용: 개념 및 심화, 문제풀이 25문항 수행 완료\n"
      "• 오답노트: 학업 정합성 기준 분석 정리 마침\n"
      "• 이 해 도: 80% (단원 인지 평정 수치 기준)\n"
      "• 난 이 도: 보통\n"
      "• 집 중 도: 높음\n"
      "• 학습컨디션: 좋음\n"
      "• 차기 목표: 함수 영역 심화 추론 문항 돌파\n\n"
      "[심층 교육 제언]\n"
      "차기 목표로 설정된 함수 심화 파트는 고도의 논리적 추론이 수반되는 영역이나, 현재 보여준 오답 정리 정밀도와 개념 분석력이라면 충분히 안정적으로 돌파해 낼 수 있습니다.";

  // 🛠️ [에러 원천 차단] Getter 문법을 제거하고 안정적인 표준 리스트 변수로 전면 리팩터링했습니다.
  final List<Map<String, dynamic>> _parentMasterTimeData = [
    {"subject": "수학", "score": 0.85, "averageScore": 0.65, "hasDaily": true, "hasWeekly": true, "hasMonthly": true, "hasYearly": true, "baseMinutes": 120},
    {"subject": "영어", "score": 0.72, "averageScore": 0.70, "hasDaily": true, "hasWeekly": true, "hasMonthly": true, "hasYearly": true, "baseMinutes": 90},
    {"subject": "국어", "score": 0.90, "averageScore": 0.58, "hasDaily": false, "hasWeekly": true, "hasMonthly": true, "hasYearly": true, "baseMinutes": 80},
    {"subject": "과학", "score": 0.65, "averageScore": 0.60, "hasDaily": false, "hasWeekly": true, "hasMonthly": true, "hasYearly": true, "baseMinutes": 70},
  ];

  @override
  void initState() {
    super.initState();
    _timeTabController = TabController(length: 4, vsync: this);
    _timeTabController.addListener(() { if (!_timeTabController.indexIsChanging) setState(() {}); });
    _loadMockedStudentRecords();
  }

  void _loadMockedStudentRecords() {
    _mirroredExamRecords = [
      _ParentExamRecord(id: "1", type: "주평가", grade: 2, semester: 1, subject: "수학", unit: "대단원 1", score: 95),
      _ParentExamRecord(id: "2", type: "주평가", grade: 2, semester: 1, subject: "영어", unit: "대단원 1", score: 70),
      _ParentExamRecord(id: "3", type: "단원평가", grade: 2, semester: 1, subject: "국어", unit: "대단원 2", score: 85),
      _ParentExamRecord(id: "4", type: "중간고사", grade: 2, semester: 1, subject: "과학", unit: "1학기", score: 90),
    ];
  }

  void _showReportPopup(BuildContext context, String mainTitle, String content) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: premiumCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: brandGolden.withValues(alpha: 0.4), width: 1.5),
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
                          style: GoogleFonts.notoSansKr(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 16, thickness: 1.2),
                  Text(
                    content,
                    style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13.5, height: 1.6),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMonitorTimeoutSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E1E2D),
        content: Text(
          "1분 경과로 인한 automatic 블로킹 활성화 (종료됨)",
          style: GoogleFonts.notoSansKr(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCustomSectionTitle(String engTitle, String korTitle, {required double fontSize}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          engTitle,
          style: GoogleFonts.gowunBatang(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: fontSize - 2.0, height: 1.2),
        ),
        const SizedBox(height: 4),
        Text(
          korTitle,
          style: GoogleFonts.notoSansKr(
            color: brandGolden,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timeTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: luxuryDarkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 90,
        automaticallyImplyLeading: false,
        title: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 14.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/gsu_logo.png',
                      width: 180,
                      height: 24,
                      fit: BoxFit.fill,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(height: 24),
                    ),
                    const SizedBox(height: 1.0),
                    Text(
                      'PARENT GKE STUDYUP',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.gowunBatang(
                        color: brandGolden,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isVipMember = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isVipMember ? brandGolden : Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: brandGolden.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _isVipMember ? "👑 VIP" : "회원 연동",
                    style: GoogleFonts.notoSansKr(
                      color: _isVipMember ? Colors.black : brandGolden,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),

      body: IndexedStack(
        index: _currentIndex,
        children: [
          // [연결 1] 실시간 현황 컴포넌트 위젯
          ParentLiveStatusWidget(
            childName: widget.childName,
            currentElapsedTime: _currentElapsedTime,
            totalCollectedStars: _totalCollectedStars,
            isMonitoringActive: _isMonitoringActive,
            monitoringCountdown: _monitoringCountdown,
            premiumCardBg: premiumCardBg,
            brandGolden: brandGolden,
            luxuryDarkBg: luxuryDarkBg,
            lastSentTimeText: _lastSentTimeText,
            buildCustomSectionTitle: _buildCustomSectionTitle,
            onSendEmojiMessage: (emoji, message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: premiumCardBg,
                  content: Text(
                    "자녀의 타이머 세션 상단에 격려 팝업 발송 완료 ☆\n($message)",
                    style: GoogleFonts.notoSansKr(color: brandGolden, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
            onSendCustomMessage: (customText) {
              final now = DateTime.now();
              final hourText = now.hour < 10 ? '0${now.hour}' : '${now.hour}';
              final minText = now.minute < 10 ? '0${now.minute}' : '${now.minute}';

              setState(() {
                _lastSentTimeText = "$hourText:$minText";
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF040B19),
                  shape: RoundedRectangleBorder(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    side: BorderSide(color: brandGolden, width: 1),
                  ),
                  duration: const Duration(seconds: 4),
                  content: Text(
                    "👑 [강제 개입] 자녀 타이머 점유 완료 (답장차단 모달 제어 중)\n내용: \"$customText\"",
                    style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              );
            },
            onStartMonitoring: () {
              setState(() {
                _isMonitoringActive = true;
                _monitoringCountdown = 60;
              });
              Timer.periodic(const Duration(seconds: 1), (timer) {
                if (!mounted || !_isMonitoringActive) {
                  timer.cancel();
                  return;
                }
                setState(() {
                  if (_monitoringCountdown > 1) {
                    _monitoringCountdown--;
                  } else {
                    _isMonitoringActive = false;
                    timer.cancel();
                    _showMonitorTimeoutSnackbar();
                  }
                });
              });
            },
          ),

          // [연결 2] 상세기록 컴포넌트 위젯 (🛠️ 안정적인 매핑 완수)
          ParentDetailedAnalysisWidget(
            childName: widget.childName,
            premiumCardBg: premiumCardBg,
            brandGolden: brandGolden,
            luxuryDarkBg: luxuryDarkBg,
            buildCustomSectionTitle: _buildCustomSectionTitle,
            onShowReportPopup: () => _showReportPopup(context, "오늘 종합 리포트 조회", _embeddedStrictFeedbackReport),
            onShowDetailedAnalysisPopup: () => _showReportPopup(context, "오늘 상세 분석기록 조회", _embeddedDetailedAnalysisLog),
            parentMasterTimeData: _parentMasterTimeData,
          ),

          // [연결 3] 평가분석 컴포넌트 위젯 (🛠️ 변수 규격 일치 완료)
          ParentEvaluationAnalysisWidget(
            childName: widget.childName,
            selectedEvaluationType: _selectedEvaluationType,
            selectedBigUnit: _selectedBigUnit,
            selectedMidUnit: _selectedMidUnit,
            selectedSemesterFilter: _selectedSemesterFilter,
            timeTabController: _timeTabController,
            mirroredExamRecords: _mirroredExamRecords,
            parentMasterTimeData: _parentMasterTimeData,
            premiumCardBg: premiumCardBg,
            brandGolden: brandGolden,
            luxuryDarkBg: luxuryDarkBg,
            buildCustomSectionTitle: _buildCustomSectionTitle,
            onEvaluationTypeChanged: (type) => setState(() => _selectedEvaluationType = type),
            onBigUnitChanged: (unit) => setState(() => _selectedBigUnit = unit),
            onMidUnitChanged: (unit) => setState(() => _selectedMidUnit = unit),
            onSemesterFilterChanged: (filter) => setState(() => _selectedSemesterFilter = filter),
            onShowDetailAnalysisReport: () {
              _showReportPopup(
                  context,
                  "👑 오늘의 교육성취 정밀 진단서",
                  "[학습 분석 보고 요약]\n\n"
                      "금일 분석된 자녀의 성적 메트릭스는 메타인지적 관점에서 매우 유의미한 학업적 성취를 나타냈습니다. "
                      "지정된 교과 평가 내부에서 인지적 과부하를 능동적으로 제어하며, "
                      "고난도 문항에 대한 학업적 몰입 밀도를 최상위권 수준으로 유지하였습니다.\n\n"
                      "교과 단원별 균형 수치 또한 안정권에 안착했으나, 특정 문항 단계에서 정합성을 검증하는 프로세스에 다소 과도한 시간이 할당되는 지체 현상이 식별되었습니다. "
                      "전반적인 교과 이해도는 매우 고도화된 수준이나, 오답 변별 과정에서 자아참조효과에 지나치게 의존하는 경향은 향후 정밀 데이터 분석을 통해 보완되어야 할 지점입니다. "
                      "가정 내에서도 자녀의 학업적 도약을 위해 따뜻한 격려를 전해주시길 권장합니다."
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: premiumCardBg,
        selectedItemColor: brandGolden,
        unselectedItemColor: Colors.white38,
        selectedLabelStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.notoSansKr(fontSize: 11),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bolt_rounded), label: '실시간 현황'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: '상세 보기'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: '평가 분석'),
        ],
      ),
    );
  }
}