import 'dart:async'; // 비동기 타이머 엔진 및 실시간 모니터링 구동용 마스터 패킷
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

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

// 학생 성취도 화면 데이터 모델 스펙트럼과 100% 무결점 동기화
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

  // 디자인 톤앤매너 테마 상수 (home_dashboard_screen과 100% 동기화)
  static const Color luxuryDarkBg = Color(0xFF030712);
  static const Color premiumCardBg = Color(0xFF0D1527);
  static const Color brandGolden = Color(0xFFE5C158);

  // 실시간 1분 감시 하이브리드 제어 변수
  bool _isMonitoringActive = false;
  int _monitoringCountdown = 60;
  num _currentElapsedTime = 36; // 실시간 누적 분 패킷
  int _totalCollectedStars = 387; // 오늘의 별 수집 현황 마스터 데이터

  // 평가 결과 필터 상태 보존 마스터 분기 팩
  String _selectedEvaluationType = "주평가";
  String _selectedBigUnit = "대단원 1"; // 대단원 1 ~ 4 선택 수정 스펙
  String _selectedMidUnit = "중단원 1";
  int _selectedSemesterFilter = 1; // 1학기, 2학기 선택 수정 스펙

  // 학습 시간 동기화 전용 독립 탭 컨트롤러 스펙
  late TabController _timeTabController;

  // 학생 성취도 입력 창에서 저장된 원본 성적 패킷 미러링 데이터 로드
  List<_ParentExamRecord> _mirroredExamRecords = [];

  // "정성 피드백 5대 절대 규칙" 임베딩 데이터셋 (종합 리포트 팩)
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

  // 멤버 아카이브먼트 그래프 렌더링용 마스터 타임 벨류 패킷 정의
  List<Map<String, dynamic>> get _parentMasterTimeData => [
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
              border: Border.all(color: brandGolden.withOpacity(0.4), width: 1.5),
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
        toolbarHeight: 120,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 80),
              Expanded(
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
                      'GKE STUDYUP PARENT',
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
              GestureDetector(
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
                    border: Border.all(color: brandGolden.withOpacity(0.5)),
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
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildLiveStatusTab(),
          _buildTimelineTab(),
          _buildAnalysisReportTab(),
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
          BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: '상세 기록'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: '평가 분석'),
        ],
      ),
    );
  }

  // ==========================================
  // 1. 실시간 현황 탭
  // ==========================================
  Widget _buildLiveStatusTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: premiumCardBg,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: brandGolden.withOpacity(0.3), width: 1.2),
            ),
            child: Column(
              children: [
                Text(
                  "${widget.childName}님이 현재 \"수학\" 과목 집중 진행 중",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    color: Colors.white,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "현재 설정하고 학습하는 과목 수행 ${_currentElapsedTime}분째",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    color: brandGolden,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "격려 메세지 전송",
                  style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildEmojiButton("😊", "집중도 최고야!"),
                    _buildEmojiButton("👍", "포기하지 마라!"),
                    _buildEmojiButton("🔥", "너의 노력을 응원해"),
                    _buildEmojiButton("👑", "최고의 집중력이야"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildCustomSectionTitle("Real-time Monitoring Control", "실시간 모니터링 제어 시스템", fontSize: 14.0),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: premiumCardBg,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: brandGolden.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                if (!_isMonitoringActive)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandGolden,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
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
                    icon: const Icon(Icons.videocam_rounded, color: Colors.black),
                    label: Text(
                      "실시간 타이머 잠시 들여다보기 (클릭 시 1분간 연결)",
                      style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: brandGolden),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "자녀 타이머 실시간 동기화 중 ... [1분 뒤 종료됨 : ${_monitoringCountdown}초]",
                              style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AbsorbPointer(
                          absorbing: true,
                          child: Opacity(
                            opacity: 0.9,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(color: luxuryDarkBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: brandGolden.withOpacity(0.3))),
                              child: Text(
                                "00:${_currentElapsedTime < 10 ? '0$_currentElapsedTime' : _currentElapsedTime}:24",
                                style: GoogleFonts.rajdhani(color: brandGolden, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildCustomSectionTitle("Today's Accumulated Stars", "오늘의 별 수집 현황 : $_totalCollectedStars개", fontSize: 14.0),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildEmojiButton(String emoji, String message) {
    return InkWell(
      onTap: () {
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
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: luxuryDarkBg,
          shape: BoxShape.circle,
          border: Border.all(color: brandGolden.withOpacity(0.3)),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
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

  // ==========================================
  // 2. 상세 기록 타임라인 탭
  // ==========================================
  Widget _buildTimelineTab() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        _buildCustomSectionTitle("Self-Directed Learning Records", "(멤버) ${widget.childName} 오늘 학습 성취도 상세결과", fontSize: 14.0),
        const SizedBox(height: 14),

        _buildAdvancedTimelineCard(
          period: "제1교시",
          subject: "수학",
          duration: "60분 집중완료",
          content: "미적분수능 기출문제집 20p~25p 개념 정리 및 오답풀이",
          score: "95점",
          understanding: "80%",
          difficulty: "보통",
          concentration: "높음",
          condition: "좋음",
          incorrect: "정리함",
        ),
        _buildAdvancedTimelineCard(
          period: "제2교시",
          subject: "영어",
          duration: "90분 집중완료",
          content: "EBS 수능특강 고난도 구문 독해 및 취약 어휘 매핑",
          score: "92점",
          understanding: "85%",
          difficulty: "어려움",
          concentration: "최상",
          condition: "좋음",
          incorrect: "정리함",
        ),
        const SizedBox(height: 16),

        _buildCustomSectionTitle("Learning Variation Analytics", "최근 학습 변화량 분석 데이터", fontSize: 14.0),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: premiumCardBg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: brandGolden.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              _buildAlignedVariationRow("오늘 학습시간", "어제 대비 +1.5시간 (15% 증가) 🔺", "1주 평균 대비 +0.8시간 (8% 증가) 🔺"),
              const Divider(color: Colors.white10, height: 20),
              _buildAlignedVariationRow("과목 전체 완료율", "어제 대비 +12% 완성 🔺", "1주 평균 대비 +5% 향상 🔺"),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: brandGolden.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextFeatureRow("✨ 잘하고 있는 과목", "수학 (학습기록장의 나의 레전드 과목)"),
              const Divider(color: Colors.white10, height: 18),
              _buildTextFeatureRow("🌋 가장 성적이 안나오는 과목", "과학 (학습기록장의 나의 블랙홀 과목)"),
              const Divider(color: Colors.white10, height: 18),
              _buildTextFeatureRow("🛡️ 가정에서 도와줄 포인트", "탐구 교과 오답 연동 분석 인프라 지원 요청"),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _buildCustomSectionTitle("Diagnostic Qualitative Analysis", "학습 기록 분석 진단 센터", fontSize: 14.0),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: premiumCardBg,
                  side: const BorderSide(color: brandGolden, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showReportPopup(context, "오늘 종합 리포트 조회", _embeddedStrictFeedbackReport),
                icon: const Icon(Icons.analytics_rounded, color: brandGolden, size: 16),
                label: Text(
                  "오늘 종합 리포트 보기 🔺",
                  style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: premiumCardBg,
                  side: const BorderSide(color: brandGolden, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showReportPopup(context, "오늘 상세 분석기록 조회", _embeddedDetailedAnalysisLog),
                icon: const Icon(Icons.manage_search_rounded, color: brandGolden, size: 16),
                label: Text(
                  "오늘 상세 분석 보기 🔺",
                  style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedTimelineCard({
    required String period,
    required String subject,
    required String duration,
    required String content,
    required String score,
    required String understanding,
    required String difficulty,
    required String concentration,
    required String condition,
    required String incorrect,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: premiumCardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "[$period $subject] $duration",
            style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "\"상세내용 - $content\"",
            style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMiniMetricBox("점수", score),
                _buildMiniMetricBox("이해도", understanding),
                _buildMiniMetricBox("난이도", difficulty),
                _buildMiniMetricBox("집중도", concentration),
                _buildMiniMetricBox("학습컨디션", condition),
                _buildMiniMetricBox("오답정리", incorrect),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMiniMetricBox(String label, String val) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: luxuryDarkBg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(val, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAlignedVariationRow(String title, String yesterday, String weekly) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text("- $title", style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(yesterday, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12)),
              Text(weekly, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 11.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextFeatureRow(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: "$label : ", style: GoogleFonts.notoSansKr(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
          TextSpan(text: value, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  // ==========================================
  // 3. 평가 및 분석 리포트 탭
  // ==========================================
  Widget _buildAnalysisReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCustomSectionTitle("Academic Evaluation Matrix", "[ 평가 결과 ]", fontSize: 14.0),
              Text(
                "\"홍길동\" 성적 기록 보기",
                style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ["주평가", "단원평가", "중간고사", "기말고사", "모의고사"].map((type) {
                bool isSelected = _selectedEvaluationType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(type, style: GoogleFonts.notoSansKr(color: isSelected ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    selected: isSelected,
                    selectedColor: brandGolden,
                    backgroundColor: premiumCardBg,
                    onSelected: (_) {
                      setState(() {
                        _selectedEvaluationType = type;
                      });
                    },
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
              border: Border.all(color: brandGolden.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedEvaluationType == "주평가") ...[
                  Text("[주평가 과거 선택 조회]", style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("년도 선택", style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ["2026년", "2027년", "2028년", "2029년", "2030년"].map((y) => Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: _buildInlineFilterChip(y, _selectedBigUnit == y, () => setState(() => _selectedBigUnit = y)),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("월 선택", style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    dropdownColor: premiumCardBg,
                    value: _selectedMidUnit.contains("월") ? _selectedMidUnit : "1월",
                    style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                    items: List.generate(12, (i) => "${i + 1}월").map((m) => DropdownMenuItem<String>(value: m, child: Text(m))).toList(),
                    onChanged: (val) => setState(() => _selectedMidUnit = val!),
                  ),
                  const SizedBox(height: 8),
                  Text("주 평가 선택", style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ["1주차", "2주차", "3주차", "4주차", "5주차"].map((w) => Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: _buildInlineFilterChip(w, _selectedMidUnit == w, () => setState(() => _selectedMidUnit = w)),
                      )).toList(),
                    ),
                  ),
                ] else if (_selectedEvaluationType == "단원평가") ...[
                  Text("대단원 선택", style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(
                    children: ["대단원 1", "대단원 2", "대단원 3", "대단원 4"].map((v) => Padding(padding: const EdgeInsets.only(right:4), child: _buildInlineFilterChip(v, _selectedBigUnit == v, () => setState(() => _selectedBigUnit = v)))).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text("중단원 선택", style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(
                    children: ["중단원 1", "중단원 2", "중단원 3", "중단원 4"].map((v) => Padding(padding: const EdgeInsets.only(right:4), child: _buildInlineFilterChip(v, _selectedMidUnit == v, () => setState(() => _selectedMidUnit = v)))).toList(),
                  ),
                ] else ...[
                  Text("학년 선택하면 해당 학기가 활성화됩니다", style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 6),
                  Row(
                    children: ["1학년", "2학년", "3학년"].map((g) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _buildInlineFilterChip(g, _selectedBigUnit == g, () => setState(() { _selectedBigUnit = g; _selectedSemesterFilter = 1; })),
                    )).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text("학기 선택", style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildInlineFilterChip("1학기", _selectedSemesterFilter == 1, () => setState(() => _selectedSemesterFilter = 1)),
                      const SizedBox(width: 6),
                      _buildInlineFilterChip("2학기", _selectedSemesterFilter == 2, () => setState(() => _selectedSemesterFilter = 2)),
                    ],
                  ),
                ],
                const Divider(color: Colors.white10, height: 16),
                Text("그래프 출력 타겟 지정 (학년/학기 연동 인프라 대기 완료)", style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _buildParentEvaluationChart(_selectedEvaluationType),
          const SizedBox(height: 24),

          _buildCustomSectionTitle("Learning Time Dashboard", "[ 학습시간 ]", fontSize: 14.0),
          const SizedBox(height: 12),
          Container(
            width: double.infinity, height: 42, padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFF0D1527), borderRadius: BorderRadius.circular(10), border: Border.all(color: brandGolden.withOpacity(0.3))),
            child: TabBar(
              controller: _timeTabController,
              indicator: const BoxDecoration(color: brandGolden, borderRadius: BorderRadius.all(Radius.circular(6))),
              labelColor: Colors.black, unselectedLabelColor: Colors.white,
              labelStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.w900, fontSize: 12),
              unselectedLabelStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold, fontSize: 12),
              tabs: const [Tab(text: "일간"), Tab(text: "주간"), Tab(text: "월간"), Tab(text: "연간")],
            ),
          ),
          const SizedBox(height: 14),

          _buildParentTimeChartDashboard(_timeTabController.index),
        ],
      ),
    );
  }

  // ==========================================
  // 성적 막대그래프 엔진
  // ==========================================
  Widget _buildParentEvaluationChart(String type) {
    List<_ParentExamRecord> rawRecords = _mirroredExamRecords.where((rec) => rec.type == type).toList();
    if (rawRecords.isEmpty) {
      rawRecords = [
        _ParentExamRecord(type: type, grade: 2, semester: 1, subject: "평균", score: 80.0, unit: ""),
        _ParentExamRecord(type: type, grade: 2, semester: 1, subject: "수학", score: 95.0, unit: ""),
        _ParentExamRecord(type: type, grade: 2, semester: 1, subject: "영어", score: 75.0, unit: ""),
        _ParentExamRecord(type: type, grade: 2, semester: 1, subject: "국어", score: 88.0, unit: ""),
        _ParentExamRecord(type: type, grade: 2, semester: 1, subject: "과학", score: 65.0, unit: ""),
      ];
    }

    final List<Color> scoreColors = [
      const Color(0xFF34C759), // 초록
      const Color(0xFFFF3B30), // 빨강
      const Color(0xFF007AFF), // 파랑
      const Color(0xFFFFCC00), // 노랑
      const Color(0xFFAF52DE), // 보라
      const Color(0xFFFF9500), // 주황
      const Color(0xFF0500FF), // 남색
    ];

    const double chartMaxHeight = 205.0;
    final List<String> scores = ["100점", "90점", "80점", "70점", "60점"];

    const double barWidth = 20.0;
    const double barMargin = 6.0;

    return Container(
      height: 240,
      padding: const EdgeInsets.only(top: 16, bottom: 4, left: 12, right: 12),
      decoration: BoxDecoration(color: premiumCardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 37,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: scores.map((s) => Container(
                      height: 16,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        s,
                        style: GoogleFonts.rajdhani(color: brandGolden, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    )).toList(),
                  ),
                ),
                Stack(
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
                const SizedBox(width: 12),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: rawRecords.length,
                    itemBuilder: (ctx, idx) {
                      final rec = rawRecords[idx];
                      Color barColor = rec.subject == "평균"
                          ? Colors.grey
                          : scoreColors[idx % scoreColors.length];

                      double normalizedScore = (rec.score - 60).clamp(0, 40);
                      double finalBarHeight = (normalizedScore / 40) * (chartMaxHeight - 15);

                      return Container(
                        width: barWidth + (barMargin * 2),
                        margin: const EdgeInsets.symmetric(horizontal: 0),
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
                            Container(
                              height: finalBarHeight < 4 ? 4 : finalBarHeight,
                              width: barWidth,
                              margin: const EdgeInsets.only(bottom: 0),
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 37),
            child: Container(height: 2.5, color: brandGolden),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 49),
            child: SizedBox(
              height: 24,
              child: Row(
                children: rawRecords.map((rec) => Container(
                  width: barWidth + (barMargin * 2),
                  alignment: Alignment.center,
                  child: Text(
                    rec.subject,
                    style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 학습시간 동적 스크롤 대시보드 엔진
  // ==========================================
  Widget _buildParentTimeChartDashboard(int tabIndex) {
    String unitLabel;
    double yMin, yMax;
    List<String> yTicks;
    List<Map<String, dynamic>> subjectData;

    if (tabIndex == 0) {
      unitLabel = "";
      subjectData = [
        {"subject": "수학", "avg": 200.0, "value": 280.0},
        {"subject": "영어", "avg": 185.0, "value": 200.0},
        {"subject": "국어", "avg": 180.0, "value": 190.0},
        {"subject": "과학", "avg": 220.5, "value": 245.0},
      ];
    } else if (tabIndex == 1) {
      unitLabel = "h";
      subjectData = [
        {"subject": "수학", "avg": 20.0, "value": 21.0},
        {"subject": "영어", "avg": 20.0, "value": 20.5},
        {"subject": "국어", "avg": 19.5, "value": 21.8},
        {"subject": "과학", "avg": 20.0, "value": 20.5},
      ];
    } else if (tabIndex == 2) {
      unitLabel = "h";
      subjectData = [
        {"subject": "수학", "avg": 29.1, "value": 30.5},
        {"subject": "영어", "avg": 29.1, "value": 30.0},
        {"subject": "국어", "avg": 29.1, "value": 30.0},
        {"subject": "과학", "avg": 30.1, "value": 30.5},
      ];
    } else {
      unitLabel = "h";
      subjectData = [
        {"subject": "수학", "avg": 71.5, "value": 78.0},
        {"subject": "영어", "avg": 75.5, "value": 79.0},
        {"subject": "국어", "avg": 72.5, "value": 79.0},
        {"subject": "과학", "avg": 70.5, "value": 72.0},
      ];
    }

    double allMax = subjectData.map((e) => (e["value"] as double) > (e["avg"] as double) ? (e["value"] as double) : (e["avg"] as double)).reduce((a, b) => a > b ? a : b);
    double allMin = subjectData.map((e) => (e["value"] as double) < (e["avg"] as double) ? (e["value"] as double) : (e["avg"] as double)).reduce((a, b) => a < b ? a : b);

    yMax = tabIndex == 0 ? allMax + 20.0 : allMax + 1.0;
    yMin = tabIndex == 0 ? (allMin - 20.0).clamp(0.0, double.infinity) : (allMin - 1.0).clamp(0.0, double.infinity);
    double step = (yMax - yMin) / 3;
    yTicks = List.generate(4, (i) => "${(yMax - step * i).toStringAsFixed(tabIndex == 0 ? 0 : 1)}$unitLabel").toList();

    const double barW = 17.0;
    const double pairGap = 0.7;
    const double groupGap = 14.0;
    const double chartH = 190.0;

    double multiplier = (tabIndex == 0) ? 1.0 : (tabIndex == 1) ? 5.0 : (tabIndex == 2) ? 22.0 : 250.0;
    double totalMinutes = 0;
    for (var item in _parentMasterTimeData) {
      totalMinutes += (item["baseMinutes"] as int) * multiplier;
    }

    final List<Color> subjectColors = [
      const Color(0xFFFF3B30), // 수학 - 빨강
      const Color(0xFF007AFF), // 영어 - 파랑
      const Color(0xFF34C759), // 국어 - 초록
      const Color(0xFFFF9500), // 과학 - 주황
    ];

    double calcBarH(double val) {
      double delta = (yMax - yMin) == 0 ? 1 : (yMax - yMin);
      return ((val - yMin) / delta * chartH).clamp(2.0, chartH);
    }

    Widget buildPair(int idx, Map<String, dynamic> item) {
      double avgH = calcBarH((item["avg"] as double));
      double valH = calcBarH((item["value"] as double));
      Color col = subjectColors[idx % subjectColors.length];
      double avgVal = item["avg"] as double;
      double subVal = item["value"] as double;

      return SizedBox(
        height: chartH,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("${avgVal.toStringAsFixed(1)}$unitLabel", style: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Container(
                  width: barW, height: avgH,
                  decoration: const BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.vertical(top: Radius.circular(3))),
                ),
              ],
            ),
            const SizedBox(width: pairGap),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("${subVal.toStringAsFixed(1)}$unitLabel", style: GoogleFonts.rajdhani(color: col, fontSize: 8, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Container(
                  width: barW, height: valH,
                  decoration: BoxDecoration(color: col, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 12, 0),
          decoration: BoxDecoration(
            color: const Color(0xFF070E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: brandGolden.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(width: 10, height: 10, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text("평균", style: GoogleFonts.notoSansKr(color: Colors.white60, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 6),
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
                              width: 42,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: yTicks.map((t) => Text(t, style: GoogleFonts.rajdhani(color: brandGolden, fontSize: 11, fontWeight: FontWeight.bold))).toList(),
                              ),
                            ),
                            Container(width: 2, color: brandGolden),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: chartH,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(subjectData.length, (idx) {
                                return Padding(
                                  padding: EdgeInsets.only(left: idx == 0 ? groupGap : groupGap),
                                  child: buildPair(idx, subjectData[idx]),
                                );
                              }),
                            ),
                          ),
                        ),
                        Container(height: 2, color: brandGolden),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(subjectData.length, (idx) {
                              return Container(
                                width: (barW * 2) + pairGap + groupGap,
                                padding: const EdgeInsets.only(left: 8.0),
                                alignment: Alignment.center,
                                child: Text(
                                  subjectData[idx]["subject"] as String,
                                  style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        const Divider(color: Colors.white10, height: 24),

        Row(
          children: [
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 120, height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(120, 120),
                        painter: _ParentDashboardPiePainter(),
                      ),
                      Container(
                        width: 60, height: 60,
                        decoration: const BoxDecoration(color: premiumCardBg, shape: BoxShape.circle),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Total', style: GoogleFonts.gowunBatang(color: Colors.white38, fontSize: 9)),
                            Text("${totalMinutes.round()}m", style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: ["수학 (39%)", "영어 (28%)", "국어 (18%)", "과학 (15%)"].map((txt) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: brandGolden, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(txt, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
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
        decoration: BoxDecoration(color: isSelected ? brandGolden : Colors.black38, borderRadius: BorderRadius.circular(6), border: Border.all(color: brandGolden.withOpacity(0.25))),
        child: Text(label, style: GoogleFonts.notoSansKr(color: isSelected ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
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
}

class _ParentDashboardPiePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()..style = PaintingStyle.fill..isAntiAlias = true;
    double start = -math.pi / 2;
    List<Color> cols = [const Color(0xFFFF3B30), const Color(0xFF007AFF), const Color(0xFF34C759), const Color(0xFFFF9500)];
    List<double> sweeps = [math.pi * 0.78, math.pi * 0.56, math.pi * 0.36, math.pi * 0.3];

    for (int i = 0; i < sweeps.length; i++) {
      p.color = cols[i];
      canvas.drawArc(Rect.fromLTWH(0, 0, size.width, size.height), start, sweeps[i], true, p);
      start += sweeps[i];
    }
  }
  @override
  bool shouldRepaint(CustomPainter old) => false;
}