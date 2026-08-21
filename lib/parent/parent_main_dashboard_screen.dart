import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'parent_live_status_widget.dart';
import 'parent_detailed_analysis_widget.dart';
import 'parent_evaluation_analysis_widget.dart';
import '../services/parent_data_service.dart';
import '../services/diagnosis_service.dart'; // 🆕 [요청] 300자 이상 AI 진단문 + 재사용 규칙 서비스

class ParentMainDashboardScreen extends StatefulWidget {
  final String parentEmail;
  final String childName;

  const ParentMainDashboardScreen({
    Key? key,
    required this.parentEmail,
    this.childName = "학습자",
  }) : super(key: key);

  @override
  _ParentMainDashboardScreenState createState() => _ParentMainDashboardScreenState();
}

class _ParentMainDashboardScreenState extends State<ParentMainDashboardScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isVipMember = false;
  bool _isLoading = true;

  static const Color luxuryDarkBg = Color(0xFF030712);
  static const Color premiumCardBg = Color(0xFF0D1527);
  static const Color brandGolden = Color(0xFFE5C158);

  bool _isMonitoringActive = false;
  int _monitoringCountdown = 60;
  int _totalCollectedStars = 0;

  String _lastSentTimeText = "";

  String _selectedEvaluationType = "주평가";
  String _selectedBigUnit = "대단원 1";
  String _selectedMidUnit = "중단원 1";
  int _selectedSemesterFilter = 1;

  // 🆕 [버그 수정] 주평가 전용 년/월/주차 상태 신설 - 기존엔 단원평가용 변수(_selectedBigUnit/
  // _selectedMidUnit)를 그대로 빌려쓰고 있어서 월/주차 선택이 서로 충돌하고 필터링도 안 됐음.
  // 오늘 날짜를 기준으로 자동 초기화(member_achievement_screen.dart의 주차 계산과 동일한 방식).
  static String _computeCurrentWeekOfMonth() {
    final DateTime now = DateTime.now();
    final DateTime firstOfMonth = DateTime(now.year, now.month, 1);
    final int sundayIndex = firstOfMonth.weekday % 7; // 0=일, 1=월, ... 6=토
    final int weekNum = ((now.day - 1 + sundayIndex) ~/ 7) + 1;
    return "$weekNum주차";
  }

  String _selectedYear = "${DateTime.now().year}년";
  String _selectedMonth = "${DateTime.now().month}월";
  String _selectedWeek = _computeCurrentWeekOfMonth();

  late TabController _timeTabController;

  // 🆕 [실데이터 연동] 아래 필드들은 전부 ParentDataService를 통해 채워집니다.
  String _realChildName = "학습자";
  List<ParentSessionRecord> _todaySessions = [];
  List<ParentSessionRecord> _allSessions = [];
  List<ParentExamRecord> _examRecords = [];
  List<Map<String, dynamic>> _subjectAggregates = [];

  int _todayTotalMinutes = 0;
  int _yesterdayTotalMinutes = 0;
  int _weeklyAvgMinutesPerDay = 0;
  String? _strongestSubject;
  String? _weakestSubject;

  @override
  void initState() {
    super.initState();
    _timeTabController = TabController(length: 4, vsync: this);
    _timeTabController.addListener(() { if (!_timeTabController.indexIsChanging) setState(() {}); });
    _loadRealData();
  }

  // 🆕 [실데이터 연동] ParentDataService를 통해 학생의 실제 학습 데이터를 불러옵니다.
  Future<void> _loadRealData() async {
    try {
      final String? realName = await ParentDataService.getStudentName();
      final List<ParentSessionRecord> today = await ParentDataService.loadTodaySessions();
      final List<ParentSessionRecord> all = await ParentDataService.loadAllSessions();
      final List<ParentExamRecord> exams = await ParentDataService.loadExamRecords();
      final List<Map<String, dynamic>> aggregates = await ParentDataService.loadSubjectAggregates();
      final int todayStars = await ParentDataService.getTodayStars();

      final DateTime now = DateTime.now();
      final DateTime todayStart = DateTime(now.year, now.month, now.day);
      final DateTime yesterdayStart = todayStart.subtract(const Duration(days: 1));

      final int todayMinutes = ParentDataService.totalMinutesForDay(all, todayStart);
      final int yesterdayMinutes = ParentDataService.totalMinutesForDay(all, yesterdayStart);

      // 최근 7일(오늘 제외) 총 학습분 / 7 = 일 평균
      int weeklyTotal = 0;
      for (int i = 1; i <= 7; i++) {
        weeklyTotal += ParentDataService.totalMinutesForDay(all, todayStart.subtract(Duration(days: i)));
      }
      final int weeklyAvg = (weeklyTotal / 7).round();

      final Map<String, double> subjectAvgScores = ParentDataService.computeSubjectAverageScores(exams);
      String? strongest;
      String? weakest;
      if (subjectAvgScores.isNotEmpty) {
        final sorted = subjectAvgScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        strongest = "${sorted.first.key} (평균 ${sorted.first.value.toStringAsFixed(0)}점)";
        weakest = "${sorted.last.key} (평균 ${sorted.last.value.toStringAsFixed(0)}점)";
      }

      if (!mounted) return;
      setState(() {
        _realChildName = realName ?? widget.childName;
        _todaySessions = today;
        _allSessions = all;
        _examRecords = exams;
        _subjectAggregates = aggregates;
        _totalCollectedStars = todayStars;
        _todayTotalMinutes = todayMinutes;
        _yesterdayTotalMinutes = yesterdayMinutes;
        _weeklyAvgMinutesPerDay = weeklyAvg;
        _strongestSubject = strongest;
        _weakestSubject = weakest;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("[ParentDashboard] 실데이터 로딩 실패: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🆕 [실데이터 연동] 오늘 세션 목록 + 실제 AI 종합 총평(150~200자, DiagnosisService)을 함께 보여줍니다.
  Future<String> _buildSummaryReportText() async {
    if (_todaySessions.isEmpty) {
      return "오늘 아직 기록된 학습 세션이 없습니다. 자녀가 학습을 마치고 기록을 저장하면 이곳에 요약이 표시됩니다.";
    }
    final buffer = StringBuffer();
    buffer.writeln("[종합 리포트]\n");
    for (int i = 0; i < _todaySessions.length; i++) {
      final rec = _todaySessions[i];
      buffer.writeln("제${i + 1}교시 · ${rec.subject} · ${rec.durationMinutes}분 집중완료");
      if (rec.recordType == '평가' && rec.score != null) {
        buffer.writeln("  점수: ${rec.score}점");
      }
    }
    buffer.writeln("\n오늘 총 학습시간: $_todayTotalMinutes분");

    // 🆕 [요청] 오늘 학습한 과목 전체를 종합한 150~200자 AI 총평을 별도 문단으로 추가
    final int subjectCount = _todaySessions.map((r) => r.subject).toSet().length;
    final String dailySummary = await DiagnosisService.getDailySummary(
      personKey: 'student_$_realChildName',
      subjectCount: subjectCount,
      totalMinutes: _todayTotalMinutes,
    );
    buffer.writeln("\n[오늘의 종합 분석]");
    buffer.writeln(dailySummary);

    return buffer.toString();
  }

  // 🆕 [버그 수정] 기존엔 가장 최근 세션 1건만 보여줬음 -> 오늘 학습한 모든 세션을
  // 제1교시, 제2교시... 순서대로 전부 나열하도록 수정 (요청사항)
  String _buildDetailedAnalysisText() {
    if (_todaySessions.isEmpty) {
      return "오늘 상세 분석할 학습 기록이 아직 없습니다.";
    }
    final buffer = StringBuffer();
    buffer.writeln("[상세분석기록 - 오늘 학습한 모든 세션]\n");
    for (int i = 0; i < _todaySessions.length; i++) {
      final rec = _todaySessions[i];
      buffer.writeln("■ 제${i + 1}교시 · ${rec.subject} (${rec.recordType})");
      buffer.writeln("  상세내용: ${rec.details.isNotEmpty ? rec.details : '기록 없음'}");
      if (rec.recordType == '평가' && rec.score != null) buffer.writeln("  점수: ${rec.score}점");
      if (rec.understanding != null) buffer.writeln("  이해도: ${rec.understanding}%");
      if (rec.difficulty != null) buffer.writeln("  난이도: ${rec.difficulty}");
      if (rec.concentration != null) buffer.writeln("  집중도: ${rec.concentration}");
      if (rec.condition != null) buffer.writeln("  학습컨디션: ${rec.condition}");
      if (rec.incorrectNote != null) buffer.writeln("  오답정리: ${rec.incorrectNote}");
      if (rec.nextGoal.isNotEmpty) buffer.writeln("  다음목표: ${rec.nextGoal}");
      buffer.writeln();
    }
    return buffer.toString();
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: luxuryDarkBg,
        body: const Center(child: CircularProgressIndicator(color: brandGolden)),
      );
    }

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
          ParentLiveStatusWidget(
            childName: _realChildName,
            lastSessionSubject: _todaySessions.isNotEmpty ? _todaySessions.last.subject : null,
            lastSessionDurationMinutes: _todaySessions.isNotEmpty ? _todaySessions.last.durationMinutes : 0,
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

          ParentDetailedAnalysisWidget(
            childName: _realChildName,
            premiumCardBg: premiumCardBg,
            brandGolden: brandGolden,
            luxuryDarkBg: luxuryDarkBg,
            buildCustomSectionTitle: _buildCustomSectionTitle,
            onShowReportPopup: () async {
              final String content = await _buildSummaryReportText();
              if (!mounted) return;
              _showReportPopup(context, "오늘 종합 리포트 조회", content);
            },
            onShowDetailedAnalysisPopup: () => _showReportPopup(context, "오늘 상세 분석기록 조회", _buildDetailedAnalysisText()),
            todaySessions: _todaySessions,
            todayTotalMinutes: _todayTotalMinutes,
            yesterdayTotalMinutes: _yesterdayTotalMinutes,
            weeklyAvgMinutesPerDay: _weeklyAvgMinutesPerDay,
            strongestSubject: _strongestSubject,
            weakestSubject: _weakestSubject,
          ),

          ParentEvaluationAnalysisWidget(
            childName: _realChildName,
            selectedEvaluationType: _selectedEvaluationType,
            selectedBigUnit: _selectedBigUnit,
            selectedMidUnit: _selectedMidUnit,
            selectedSemesterFilter: _selectedSemesterFilter,
            selectedYear: _selectedYear,
            selectedMonth: _selectedMonth,
            selectedWeek: _selectedWeek,
            timeTabController: _timeTabController,
            mirroredExamRecords: _examRecords,
            parentMasterTimeData: _subjectAggregates,
            premiumCardBg: premiumCardBg,
            brandGolden: brandGolden,
            luxuryDarkBg: luxuryDarkBg,
            buildCustomSectionTitle: _buildCustomSectionTitle,
            onEvaluationTypeChanged: (type) => setState(() => _selectedEvaluationType = type),
            onBigUnitChanged: (unit) => setState(() => _selectedBigUnit = unit),
            onMidUnitChanged: (unit) => setState(() => _selectedMidUnit = unit),
            onSemesterFilterChanged: (filter) => setState(() => _selectedSemesterFilter = filter),
            onYearChanged: (year) => setState(() => _selectedYear = year),
            onMonthChanged: (month) => setState(() => _selectedMonth = month),
            onWeekChanged: (week) => setState(() => _selectedWeek = week),
            onShowDetailAnalysisReport: () async {
              // 🆕 [요청] 300자 이상 상세 진단 + 같은 사람에게 3개월 내 재사용 금지 + 생성된 문구는
              // 반드시 저장 후 유사한 사람(같은 점수 구간)에게 재사용. DiagnosisService가 전담 관리.
              if (_examRecords.isEmpty) {
                _showReportPopup(
                  context,
                  "👑 오늘의 교육성취 정밀 진단서",
                  "아직 기록된 평가 데이터가 없습니다. 평가가 기록되면 정밀 분석 리포트가 제공됩니다.",
                );
                return;
              }
              final lastExam = _examRecords.last;
              final String content = await DiagnosisService.getAnalysis(
                personKey: 'student_$_realChildName',
                type: lastExam.type,
                subject: lastExam.subject,
                score: lastExam.score,
              );
              if (!mounted) return;
              _showReportPopup(context, "👑 오늘의 교육성취 정밀 진단서", content);
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
