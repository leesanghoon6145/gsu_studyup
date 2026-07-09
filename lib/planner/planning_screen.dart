import 'dart:convert'; // [주석] 마스터 데이터 JSON 직렬화 및 역직렬화를 위한 패키지 임포트
import 'package:flutter/material.dart';
// [주석] 구글 폰트 패키지 임포트
import 'package:google_fonts/google_fonts.dart';
// [주석] 사용자의 마지막 제어 상태 및 마스터 데이터를 기기 내부에 영구 보존하기 위한 shared_preferences 임포트
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/study_timeline_section.dart'; // [주석] 새로 분가한 학습 타임라인 섹션 임포트
import 'widgets/planner_calendar_view.dart'; // [주석] 새로 분가한 플래너 달력 그리드 위젯 임포트
import 'widgets/daily_todo_list_section.dart'; // [주석] 새로 분가한 하루 주요 일정 섹션 임포트
/// ============================================================================
/// [GKE StudyUp] 자기주도 학습 플래너 - 학습 계획 스크린 (planning_screen.dart)
/// ============================================================================
class PlanningScreen extends StatefulWidget {
  const PlanningScreen({Key? key}) : super(key: key);

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 👑 [주석] 탭 전환 시 화면 유지 및 버벅임 방지
  // [주석] 상단 [연간][월간][주간][일간] 4개 탭 제어 컨트롤러
  late TabController _tabController;

  // [주석] 카테고리별 테마 색상 (지시사항 엄격 준수)
  final Color schoolColor = const Color(0xFF3B82F6);   // 학교 일정 (파랑색)
  final Color academyColor = const Color(0xFF10B981);  // 학원 일정 (녹색)
  final Color examColor = const Color(0xFFEF4444);     // 시험 일정 (빨강색)
  final Color personalColor = const Color(0xFFFACC15); // 개인 일정 (노랑색)
  final Color goldColor = const Color(0xFFD4AF37);     // 공식 황금색

  // [주석] 테마 컬러 상수 정의
  final Color slate300 = const Color(0xFFCBD5E1);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color slate500 = const Color(0xFF64748B);
  final Color slate800 = const Color(0xFF1E293B);

  // [주석] 확장 및 숨김 상태 제어 변수
  bool _isYearTargetExpanded = true;
  bool _isDayCalendarVisible = true;

  // [주석] 연간, 월간, 주간, 일간 독립형 이원화 선택 패널 제어 변수
  bool _isYearTargetSelected = true;
  bool _isMonthTargetSelected = true;
  bool _isWeekTimelineSelected = true;
  bool _isTimeViewSelected = true;

  // [주석] 연간 뷰 가로 스크롤 연도 리스트
  int _selectedYearIndex = 0;
  final List<String> _scrollableYears = ['2026년', '2027년', '2028년', '2029년', '2030년'];

  // [주석] 월간 뷰 가로 스크롤 인덱스 (기본값: 0, initState에서 오늘 날짜 기준으로 동적 재매핑됨)
  int _selectedMonthIndex = 0;

  // [주석] 주간 뷰 가로 스크롤 주차 리스트
  int _selectedWeekIndex = 0;
  final List<String> _scrollableWeeks = ['1주차', '2주차', '3주차', '4주차', '5주차'];

  // [주석] 일간 뷰 동적 날짜 선택 변수 (기본값: DateTime.now() 오늘 날짜로 자동 매핑 및 결합)
  late DateTime _selectedDayDate;

  // ============================================================================
  // [GKE StudyUp] 글로벌 마스터 데이터 센터
  // ============================================================================
  late Map<String, List<Map<String, dynamic>>> _yearlyTargetsMap;
  late List<Map<String, dynamic>> _globalSchedules;

  // [주석] 5개 주차(0~4) × 7개 요일(1~7) 단위의 순환형 주간 고정 시간표 템플릿 마스터
  late Map<int, Map<int, List<Map<String, dynamic>>>> _weeklyTemplateMaster;

  // [주석] 사용자가 특정 날짜에 수행하고 완료(별 획득)한 실제 기록 인스턴스 저장소
  late Map<String, List<Map<String, dynamic>>> _dailyExecutionInstanceMap;

  // [주석] 일간 날짜별 정밀 고정 타임라인 관리 실시간 화면 매핑 변수
  late List<Map<String, dynamic>> _fixedDayTimelines;

  // [주석] 역방향 폭포수 연동을 위한 월간 실시간 달성도 지표 게이지 (0.0 ~ 1.0)
  double _monthlyProgressGauge = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    final DateTime today = DateTime.now();
    _selectedDayDate = DateTime(today.year, today.month, today.day);

    final String currentYearStr = '${today.year}년';
    final int matchedYearIdx = _scrollableYears.indexOf(currentYearStr);
    _selectedYearIndex = matchedYearIdx != -1 ? matchedYearIdx : 0;
    _selectedMonthIndex = today.month - 1;

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _saveState();
      }
    });

    // --------------------------------------------------------------------------
    // 🎯 주간 토요일/일요일 이미지 스펙 완벽 반영 고정 템플릿 구조
    // --------------------------------------------------------------------------
    _weeklyTemplateMaster = {
      for (int w = 0; w < 5; w++)
        w: {
          // 월요일(1) ~ 금요일(5) 기존 루틴 유지
          for (int d = 1; d <= 5; d++)
            d: [
              {'time': '06:00 ~ 07:00', 'title': '기상 및 암기', 'memo': '새벽 기상 후 핵심 단어 및 암기과정 마스터 리프레시', 'category': '기타', 'custom_book': '', 'is_starred': false},
              {'time': '07:00 ~ 08:00', 'title': '등교', 'memo': '오전 등교 및 주간 자율 플래너 로드 진입 완료', 'category': '기타', 'custom_book': '', 'is_starred': false},
              {'time': '08:00 ~ 16:00', 'title': '학교생활', 'memo': '학교 정규 교과 수업 집중 이수 및 학업 성취도 빌드업', 'category': '교과서', 'custom_book': '', 'is_starred': false},
              {'time': '16:00 ~ 17:00', 'title': '휴식', 'memo': '에너지 충전 및 하교 후 자기주도 학습 모드 전환 휴식', 'category': '기타', 'custom_book': '', 'is_starred': false},
              {'time': '17:00 ~ 18:00', 'title': '고등수학', 'memo': '고등 수학 기본 개념 맵핑 및 유형별 고난도 문제 격파', 'category': '문제집', 'custom_book': '블랙라벨', 'is_starred': false},
              {'time': '18:00 ~ 19:00', 'title': '저녁식사', 'memo': '균형 잡힌 영양 섭취 및 야간 집중 자습 리커버리 시간', 'category': '기타', 'custom_book': '', 'is_starred': false},
              {'time': '19:00 ~ 20:00', 'title': '고등영어 자이스토리 실전', 'memo': '자이스토리 실전 모의고사 분석 및 고난도 구문 독해 트레이닝', 'category': '문제집', 'custom_book': '기출문제집', 'is_starred': false},
              {'time': '20:00 ~ 21:00', 'title': '중등2-2 진도', 'memo': '중등 2학년 2학기 핵심 기하 파트 심화 진도 선행 점검', 'category': '동영상', 'custom_book': '', 'is_starred': false},
              {'time': '21:00 ~ 22:00', 'title': '세계사', 'memo': '세계사 주요 연표 마인드맵핑 및 흐름 정리 암기 트랙', 'category': '교과서', 'custom_book': '', 'is_starred': false},
              {'time': '22:00 ~ 23:00', 'title': '오늘것 오답 또는 총정리', 'memo': '오늘 진행된 전체 진도 오답노트 정밀 기록 및 최종 스터디업 클로징', 'category': '문제집', 'custom_book': '', 'is_starred': false},
            ],

          // 토요일 템플릿(6)
          6: [
            {'time': '06:00 ~ 07:00', 'title': '기상 + 가벼운 운동/스트레칭', 'memo': '물 마시고 산책 or 홈트', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '07:00 ~ 08:00', 'title': '아침 준비 + 명상/일기', 'memo': '하루 계획 세우기', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '08:00 ~ 08:40', 'title': '아침 식사', 'memo': '-', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '08:40 ~ 09:00', 'title': '휴식 / 산책', 'memo': '-', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '09:00 ~ 10:30', 'title': '학습 블록 1 (90분)', 'memo': '가장 집중력 좋은 시간 (고등수학/과학 등 사고력 중심)', 'category': '문제집', 'custom_book': '', 'is_starred': false},
            {'time': '10:30 ~ 10:50', 'title': '휴식 + 간식', 'memo': '20분 충분히 쉬기', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '11:00 ~ 12:30', 'title': '학습 블록 2 (90분)', 'memo': '심화 문제풀이 및 핵심 개념 고착화', 'category': '문제집', 'custom_book': '', 'is_starred': false},
            {'time': '12:30 ~ 13:30', 'title': '점심 식사 + 여유로운 휴식', 'memo': '-', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '13:30 ~ 14:00', 'title': '낮잠 or 가벼운 산책', 'memo': '피로 회복 및 오후 몰입 준비', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '14:00 ~ 15:20', 'title': '학습 블록 3 (80분)', 'memo': '오후 집중력 보통 (영어 구문 독해 및 모의고사 분석)', 'category': '문제집', 'custom_book': '', 'is_starred': false},
            {'time': '15:20 ~ 15:40', 'title': '휴식 + 운동 or 스트레칭', 'memo': '-', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '15:40 ~ 16:40', 'title': '학습 블록 4 (60분)', 'memo': '짧게 마무리 및 주간 누락 진도 보완', 'category': '문제집', 'custom_book': '', 'is_starred': false},
            {'time': '16:40 ~ 20:00', 'title': '자유 시간 / 취미 / 가족 / 저녁 식사 / 휴식', 'memo': '충분한 여유 시간 (정신적 리커버리)', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '20:00 ~ 21:30', 'title': '학습 블록 5 (90분)', 'memo': '추가된 저녁 블록 (당일 오답 정리 및 핵심 피드백 암기)', 'category': '문제집', 'custom_book': '', 'is_starred': false},
            {'time': '21:30 ~ 22:00', 'title': '휴식 / 가벼운 정리', 'memo': '-', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '22:00 ~ 23:00', 'title': '취침 준비', 'memo': '샤워, 명상 (※ 스마트폰 멀리하기 철저 이행)', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '23:00 ~ 07:00', 'title': '취침 (8시간 수면)', 'memo': '다음날 07:00 기상', 'category': '기타', 'custom_book': '', 'is_starred': false},
          ],

          // 일요일 템플릿(7)
          7: [
            {'time': '06:00 ~ 07:00', 'title': '기상 + 가벼운 운동/스트레칭', 'memo': '토요일과 동일', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '07:00 ~ 08:00', 'title': '아침 준비 + 명상/일기', 'memo': '하루 평가 계획 세우기', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '08:00 ~ 08:40', 'title': '아침 식사', 'memo': '-', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '08:40 ~ 09:00', 'title': '휴식 / 산책', 'memo': '-', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '09:00 ~ 10:00', 'title': '총복습 1', 'memo': '이번 주 전체 과목 빠르게 훑기', 'category': '교과서', 'custom_book': '', 'is_starred': false},
            {'time': '10:00 ~ 10:20', 'title': '휴식 + 간식', 'memo': '-', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '10:20 ~ 11:20', 'title': '총복습 2', 'memo': '취약했던 부분 중심 타격 복습', 'category': '문제집', 'custom_book': '', 'is_starred': false},
            {'time': '11:20 ~ 11:40', 'title': '휴식', 'memo': '-', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '11:40 ~ 12:30', 'title': '총복습 3 + 정리', 'memo': '약점 체크리스트 만들기', 'category': '문제집', 'custom_book': '', 'is_starred': false},
            {'time': '12:30 ~ 14:00', 'title': '점심 + 산책 + 여유 시간', 'memo': '충분히 쉬기', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '14:00 ~ 14:50', 'title': '주평가 1 (50분)', 'memo': '국어 or 영어 실전 테스트', 'category': '문제집', 'custom_book': '기출문제집', 'is_starred': false},
            {'time': '14:50 ~ 15:05', 'title': '짧은 휴식', 'memo': '-', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '15:05 ~ 15:55', 'title': '주평가 2 (50분)', 'memo': '수학 단원 완성 정밀 평가', 'category': '문제집', 'custom_book': '블랙라벨', 'is_starred': false},
            {'time': '15:55 ~ 16:10', 'title': '휴식', 'memo': '-', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '16:10 ~ 17:00', 'title': '주평가 3 (50분)', 'memo': '과학 or 사회 평가', 'category': '문제집', 'custom_book': '', 'is_starred': false},
            {'time': '17:00 ~ 18:30', 'title': '자유 시간 + 저녁 식사', 'memo': '완전 휴식 (멘탈 리셋 및 충전)', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '18:30 ~ 19:20', 'title': '주평가 4 (50분)', 'memo': '고등수학 심화 트랙 테스트', 'category': '문제집', 'custom_book': '', 'is_starred': false},
            {'time': '19:20 ~ 19:35', 'title': '휴식', 'memo': '-', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '19:35 ~ 20:25', 'title': '주평가 5 (50분)', 'memo': '고등영어 고난도 구문 독해 평가', 'category': '문제집', 'custom_book': '', 'is_starred': false},
            {'time': '20:25 ~ 20:40', 'title': '휴식', 'memo': '-', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '20:40 ~ 21:30', 'title': '주평가 6 + 오답 정리', 'memo': '일주일 누적 오답 백서 기록 최종 정밀 검증', 'category': '문제집', 'custom_book': '오답노트', 'is_starred': false},
            {'time': '21:30 ~ 22:00', 'title': '자유 시간 / 가벼운 정리', 'memo': '-', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '22:00 ~ 23:00', 'title': '취침 준비', 'memo': '-', 'category': '기타', 'custom_book': '', 'is_starred': false},
            {'time': '23:00 ~ 07:00', 'title': '취침', 'memo': '8시간 수면', 'category': '기타', 'custom_book': '', 'is_starred': false},
          ],
        }
    };

    _yearlyTargetsMap = {
      '2026년': [
        {'title': '2026 민사고 합격 독점 스케줄', 'done': true},
        {'title': '2026 수학 내신 1등급 완성', 'done': false},
        {'title': '2026 영어 수능 최저학력기준 충족', 'done': false},
      ],
      '2027년': [{'title': '2027 고등 전과목 심화 마스터', 'done': false}],
      '2028년': [], '2029년': [], '2030년': [],
    };

    // 💡 [안정성 패치]: 캘린더 에러 방지를 위해 변수들을 여기서 확실하게 강제 초기화
    _globalSchedules = [
      {
        'year': 2026, 'month': 7, 'day': 3, 'time': '12:00',
        'title': '자기주도 학습 핵심 아키텍처 가동', 'color': schoolColor, 'memo': '시스템 리팩토링 및 캘린더 엔진 결합',
      }
    ];
    _fixedDayTimelines = [];

    _sortGlobalSchedules();

    // 동적 데이터 연동 파이프라인 작동
    _initStorageAndLoad().then((_) {
      _syncDailyTimelineForDate(_selectedDayDate);
      _calculateMonthlyProgress();
    });
  }

  /// ============================================================================
  /// [GKE StudyUp] 톱니바퀴형 연속 주차 알고리즘 및 폭포수 연동 엔진
  /// ============================================================================
  int _getContinuousWeekIndex(DateTime date) {
    final DateTime yearStart = DateTime(date.year, 1, 1);
    final int daysDiff = date.difference(yearStart).inDays;
    final int yearWeekNumber = ((daysDiff + yearStart.weekday) / 7).ceil();
    return (yearWeekNumber - 1) % 5;
  }

  void _syncDailyTimelineForDate(DateTime date) async {
    final String dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final prefs = await SharedPreferences.getInstance();

    // [주석] 홈 대시보드 연동용 마스터 키값 안전하게 로드
    final String? examType = prefs.getString('gke_selected_exam_type'); // 중간고사, 기말고사 등
    final String? startStr = prefs.getString('gke_exam_start_date');
    final String? endStr = prefs.getString('gke_exam_end_date');
    final String? prepPeriod = prefs.getString('gke_exam_prep_period'); // 2주 전, 3주 전, 4주 전
    final bool timelineEnabled = prefs.getBool('gke_exam_timeline_enabled') ?? false;

    bool isExamModeActive = false;
    String examStatusTitleEn = "REGULAR STUDY RUN";
    String examStatusTitleKo = "평상시 자율 학습 계획 트랙";

    if (timelineEnabled && startStr != null && endStr != null) {
      final DateTime examStartDate = DateTime.parse(startStr);
      final DateTime examEndDate = DateTime.parse(endStr);

      // [주석] 선택한 준비 기간(2주/3주/4주)에 따른 역산 일수 계산 가드
      int prepDays = 28; // 기본값 4주 전
      if (prepPeriod == '2주 전') prepDays = 14;
      if (prepPeriod == '3주 전') prepDays = 21;

      final DateTime prepStartDate = examStartDate.subtract(Duration(days: prepDays));
      // [주석] 시험 종료일 밤 24:00 정밀 매핑을 위해 하루를 더한 뒤 자정으로 기준 설정
      final DateTime examEndMidnight = DateTime(examEndDate.year, examEndDate.month, examEndDate.day).add(const Duration(days: 1));

      // 🎯 [원장님 핵심 지시사항]: 현재 날짜가 시험 준비 시작일과 종료일 자정 사이에 있는지 판정
      if ((date.isAfter(prepStartDate) || date.isAtSameMomentAs(prepStartDate)) && date.isBefore(examEndMidnight)) {
        isExamModeActive = true;

        // [주석] 몇 주차 몇 일차인지 자동 연산 메커니즘 가동
        int daysDiffFromStart = date.difference(prepStartDate).inDays;
        int currentExamWeek = (daysDiffFromStart / 7).floor() + 1;
        int currentExamDayNum = (daysDiffFromStart % 7) + 1;

        // [주석] 정밀 요일별 D-Day 카운터 분기 트랙 반영
        int dDayCount = DateTime(examStartDate.year, examStartDate.month, examStartDate.day).difference(date).inDays;
        String dDayLabel = "";
        if (dDayCount > 0) {
          dDayLabel = "D-$dDayCount";
        } else if (dDayCount == 0) {
          dDayLabel = "D-Day";
        } else {
          dDayLabel = "D+${dDayCount.abs()}";
        }

        examStatusTitleEn = "EXAM PREP: WEEK $currentExamWeek DAY $currentExamDayNum ($dDayLabel)";
        examStatusTitleKo = "[$examType 대비] $currentExamWeek주차 $currentExamDayNum일차 실전 모드 ($dDayLabel)";
      }
    }

    // [주석] 이미 기록된 인스턴스가 없을 때만 새로운 시간표 인스턴스를 동적 조립
    if (!_dailyExecutionInstanceMap.containsKey(dateKey)) {
      List<Map<String, dynamic>> freshInstance = [];

      if (isExamModeActive) {
        // 🎯 [원장님 지시 스펙]: 시험 기간 전용 시간표 레이아웃 빌드업
        freshInstance = [
          {'time': '06:00 ~ 08:00', 'title': 'EXAM INTENSIVE MEMORY\n[시험과목 핵심 요약 암기 특강]', 'memo': examStatusTitleKo, 'category': '교과서', 'custom_book': '', 'is_starred': false},
          {'time': '08:00 ~ 16:00', 'title': 'SCHOOL EXAM CONTEXT\n[학교 시험 대비 집중 수업 청취]', 'memo': '학교 기출 유형 완벽 분석 및 오답 정리', 'category': '교과서', 'custom_book': '', 'is_starred': false},
          {'time': '16:00 ~ 18:00', 'title': 'MOCK EXAM PRACTICE\n[기출문제집 실전 모의고사 제한시간 격파]', 'memo': '과거 3개년 인근 학교 족보 정밀 마스터', 'category': '문제집', 'custom_book': '기출문제집', 'is_starred': false},
          {'time': '18:00 ~ 22:00', 'title': 'INTENSIVE WEAKNESS FEEDBACK\n[단원별 취약점 파괴 및 1:1 오답 클리닉]', 'memo': '완벽한 개념 이해를 위한 수집 레이스 트랙', 'category': '문제집', 'custom_book': '오답노트', 'is_starred': false},
          {'time': '22:00 ~ 23:00', 'title': 'CLOSING SUMMARY & STAR COLLECT\n[오늘 시험 범위 최종 마감 및 별 수집]', 'memo': '자정 전 완벽 리커버리', 'category': '기타', 'custom_book': '', 'is_starred': false},
        ];
      } else {
        // [주석] 평상시(상시) 기간일 때는 기존 순환형 5주차 기본 시간표 템플릿 적용
        int calculatedWeekIdx = _getContinuousWeekIndex(date);
        int weekdayIdx = date.weekday;
        List<Map<String, dynamic>> templateList = _weeklyTemplateMaster[calculatedWeekIdx]?[weekdayIdx] ?? [];
        freshInstance = templateList.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      _dailyExecutionInstanceMap[dateKey] = freshInstance;
    } else {
      // [주석] 기존에 편집된 인스턴스가 존재하더라도 시험 모드에 돌입했다면 실시간 정보 업데이트 반영
      if (isExamModeActive && _dailyExecutionInstanceMap[dateKey]!.isNotEmpty) {
        _dailyExecutionInstanceMap[dateKey]![0]['memo'] = examStatusTitleKo;
      }
    }

    if (mounted) {
      setState(() {
        _fixedDayTimelines = _dailyExecutionInstanceMap[dateKey]!;
        _selectedWeekIndex = _getContinuousWeekIndex(date);
      });
    }
  }

  void _calculateMonthlyProgress() {
    int totalTasks = 0;
    int completedTasks = 0;
    final String monthPrefix = "${_selectedDayDate.year}-${_selectedDayDate.month.toString().padLeft(2, '0')}-";

    _dailyExecutionInstanceMap.forEach((key, list) {
      if (key.startsWith(monthPrefix)) {
        for (var task in list) {
          totalTasks++;
          if (task['is_starred'] == true) { completedTasks++; }
        }
      }
    });

    setState(() {
      _monthlyProgressGauge = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;
    });
  }

  /// ============================================================================
  /// [주석] SharedPreferences 영구 저장 및 동적 복원 메소드 모듈
  /// ============================================================================

  Future<void> _initStorageAndLoad() async {
    await _loadMasterData();
    await _loadSavedState();
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('gke_tab_index', _tabController.index);
      await prefs.setInt('gke_selected_year_index', _selectedYearIndex);
      await prefs.setInt('gke_selected_month_index', _selectedMonthIndex);
      await prefs.setInt('gke_selected_week_index', _selectedWeekIndex);
      await prefs.setString('gke_selected_day_date', _selectedDayDate.toIso8601String());

      await prefs.setBool('gke_is_year_target_selected', _isYearTargetSelected);
      await prefs.setBool('gke_is_month_target_selected', _isMonthTargetSelected);
      await prefs.setBool('gke_is_week_timeline_selected', _isWeekTimelineSelected);
      await prefs.setBool('gke_is_time_view_selected', _isTimeViewSelected);
      await prefs.setBool('gke_is_year_target_expanded', _isYearTargetExpanded);
      await prefs.setBool('gke_is_day_calendar_visible', _isDayCalendarVisible);
    } catch (e) {
      debugPrint('[GKE StudyUp] Error saving configuration state: $e');
    }
  }

  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? savedTabIndex = prefs.getInt('gke_tab_index');
      final int? savedYearIndex = prefs.getInt('gke_selected_year_index');
      final int? savedMonthIndex = prefs.getInt('gke_selected_month_index');
      final int? savedWeekIndex = prefs.getInt('gke_selected_week_index');
      final String? savedDayDateStr = prefs.getString('gke_selected_day_date');

      final bool? savedYearTargetSel = prefs.getBool('gke_is_year_target_selected');
      final bool? savedMonthTargetSel = prefs.getBool('gke_is_month_target_selected');
      final bool? savedWeekTimelineSel = prefs.getBool('gke_is_week_timeline_selected');
      final bool? savedTimeViewSel = prefs.getBool('gke_is_time_view_selected');
      final bool? savedYearTargetExp = prefs.getBool('gke_is_year_target_expanded');
      final bool? savedDayCalendarVis = prefs.getBool('gke_is_day_calendar_visible');

      setState(() {
        if (savedTabIndex != null) { _tabController.index = savedTabIndex; }
        if (savedYearIndex != null && savedYearIndex < _scrollableYears.length) { _selectedYearIndex = savedYearIndex; }
        if (savedMonthIndex != null && savedMonthIndex < 12) { _selectedMonthIndex = savedMonthIndex; }
        if (savedWeekIndex != null && savedWeekIndex < _scrollableWeeks.length) { _selectedWeekIndex = savedWeekIndex; }
        if (savedDayDateStr != null) { _selectedDayDate = DateTime.parse(savedDayDateStr); }

        if (savedYearTargetSel != null) _isYearTargetSelected = savedYearTargetSel;
        if (savedMonthTargetSel != null) _isMonthTargetSelected = savedMonthTargetSel;
        if (savedWeekTimelineSel != null) _isWeekTimelineSelected = savedWeekTimelineSel;
        if (savedTimeViewSel != null) _isTimeViewSelected = savedTimeViewSel;
        if (savedYearTargetExp != null) _isYearTargetExpanded = savedYearTargetExp;
        if (savedDayCalendarVis != null) _isDayCalendarVisible = savedDayCalendarVis;
      });

      // [주석] 홈 대시보드 팝업창에서 저장된 시험 설정 정보 실시간 강제 연동 동기화
      _syncDailyTimelineForDate(_selectedDayDate);
    } catch (e) {
      debugPrint('[GKE StudyUp] Error loading configuration state: $e');
    }
  }

  Future<void> _saveMasterData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gke_yearly_targets_map', jsonEncode(_yearlyTargetsMap));

      final List<Map<String, dynamic>> serializableSchedules = _globalSchedules.map((item) {
        final Map<String, dynamic> copy = Map.from(item);
        if (copy['color'] is Color) { copy['color'] = (copy['color'] as Color).value; }
        return copy;
      }).toList();
      await prefs.setString('gke_global_schedules', jsonEncode(serializableSchedules));
      await prefs.setString('gke_daily_execution_instance_map', jsonEncode(_dailyExecutionInstanceMap));
    } catch (e) {
      debugPrint('[GKE StudyUp] Error serializing master data: $e');
    }
  }

  Future<void> _loadMasterData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? yearlyTargetsJson = prefs.getString('gke_yearly_targets_map');
      if (yearlyTargetsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(yearlyTargetsJson);
        setState(() {
          _yearlyTargetsMap = decoded.map((key, value) {
            final List<dynamic> list = value as List<dynamic>;
            return MapEntry(key, list.map((item) => Map<String, dynamic>.from(item as Map)).toList());
          });
        });
      }

      final String? globalSchedulesJson = prefs.getString('gke_global_schedules');
      if (globalSchedulesJson != null) {
        final List<dynamic> decodedList = jsonDecode(globalSchedulesJson);
        setState(() {
          _globalSchedules = decodedList.map((item) {
            final Map<String, dynamic> map = Map<String, dynamic>.from(item as Map);
            if (map['color'] is int) { map['color'] = Color(map['color'] as int); }
            return map;
          }).toList();
          _sortGlobalSchedules();
        });
      }

      final String? dailyExecJson = prefs.getString('gke_daily_execution_instance_map');
      if (dailyExecJson != null) {
        final Map<String, dynamic> decodedMap = jsonDecode(dailyExecJson);
        setState(() {
          _dailyExecutionInstanceMap = decodedMap.map((key, value) {
            final List<dynamic> list = value as List<dynamic>;
            return MapEntry(key, list.map((item) => Map<String, dynamic>.from(item as Map)).toList());
          });
        });
      }
    } catch (e) {
      debugPrint('[GKE StudyUp] Error deserializing master data: $e');
    }
  }
  void _sortGlobalSchedules() {
    _globalSchedules.sort((a, b) {
      int yearComp = (a['year'] as int).compareTo(b['year'] as int);
      if (yearComp != 0) return yearComp;
      int monthComp = (a['month'] as int).compareTo(b['month'] as int);
      if (monthComp != 0) return monthComp;
      int dayComp = (a['day'] as int).compareTo(b['day'] as int);
      if (dayComp != 0) return dayComp;
      return (a['time'] as String).compareTo(b['time'] as String);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 8),
        child: AppBar(
          backgroundColor: const Color(0xFF020617),
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: TabBar(
              controller: _tabController,
              indicatorColor: goldColor,
              labelColor: goldColor,
              unselectedLabelColor: slate400,
              tabs: [
                Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('YEAR', style: GoogleFonts.notoSerif(fontSize: 12, color: goldColor, fontWeight: FontWeight.bold)),
                      Text('연간', style: GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('MONTH', style: GoogleFonts.notoSerif(fontSize: 12, color: goldColor, fontWeight: FontWeight.bold)),
                      Text('월간', style: GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('WEEK', style: GoogleFonts.notoSerif(fontSize: 12, color: goldColor, fontWeight: FontWeight.bold)),
                      Text('주간', style: GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('DAY', style: GoogleFonts.notoSerif(fontSize: 12, color: goldColor, fontWeight: FontWeight.bold)),
                      Text('일간', style: GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildYearView(),
          _buildMonthView(),
          _buildWeekView(),
          _buildDayView(),
        ],
      ),
    );
  }
  /// ============================================================================
  /// 📅 1. 연간 뷰 (YEAR VIEW)
  /// ============================================================================
  Widget _buildYearView() {
    String currentYearKey = _scrollableYears[_selectedYearIndex];
    List<Map<String, dynamic>> currentTargets = _yearlyTargetsMap[currentYearKey] ?? [];

    int numericYear = int.tryParse(currentYearKey.replaceAll('년', '')) ?? 2026;
    List<Map<String, dynamic>> filteredYearSchedules = _globalSchedules.where((s) => (s['year'] ?? 2026) == numericYear).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      children: [
        _buildDynamicSectionHeader('YEARLY TARGET SYSTEM', '연간 계획 및 일정 제어', () { _showAddScheduleBottomSheet(context, '목표'); }),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _scrollableYears.length,
            itemBuilder: (context, index) {
              bool isSelected = _selectedYearIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() { _selectedYearIndex = index; });
                  _saveState();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? goldColor.withValues(alpha: 0.15) : const Color(0xFF020617),
                    border: Border.all(color: isSelected ? goldColor : slate800, width: 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text('${_scrollableYears[index]} 목표', style: GoogleFonts.notoSansKr(fontSize: 12, color: isSelected ? goldColor : slate300)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () { setState(() { _isYearTargetSelected = true; }); _saveState(); },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isYearTargetSelected ? goldColor : slate800, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YEARLY TARGET LIST', style: GoogleFonts.notoSerif(fontSize: 14, color: _isYearTargetSelected ? goldColor : slate400, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$currentYearKey 목표 리스트', style: GoogleFonts.notoSansKr(fontSize: 12, color: _isYearTargetSelected ? Colors.white : slate500, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () { setState(() { _isYearTargetSelected = false; }); _saveState(); },
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: !_isYearTargetSelected ? goldColor : slate800, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YEARLY MAIN SCHEDULE', style: GoogleFonts.notoSerif(fontSize: 14, color: !_isYearTargetSelected ? goldColor : slate400, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$currentYearKey 주요 일정', style: GoogleFonts.notoSansKr(fontSize: 12, color: !_isYearTargetSelected ? Colors.white : slate500, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isYearTargetSelected) ...[
          Card(
            color: const Color(0xFF020617),
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(side: BorderSide(color: slate800)),
            child: ExpansionTile(
              key: ValueKey(currentYearKey),
              initiallyExpanded: _isYearTargetExpanded,
              title: Text('$currentYearKey 목표 분석 레일', style: GoogleFonts.notoSansKr(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold)),
              iconColor: goldColor,
              collapsedIconColor: slate400,
              onExpansionChanged: (val) { setState(() { _isYearTargetExpanded = val; }); _saveState(); },
              children: [
                if (currentTargets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Text('등록된 연간 목표 목표치가 없습니다.', style: GoogleFonts.notoSansKr(color: slate500, fontSize: 12)),
                  )
                else
                  ...currentTargets.asMap().entries.map((entry) {
                    return _buildYearChecklistItem(entry.value['title'], entry.value['done'], entry.key, currentYearKey);
                  }).toList(),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ] else ...[
          if (filteredYearSchedules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Center(child: Text('해당 연도에 편성된 주요 일정이 없습니다.', style: GoogleFonts.notoSansKr(color: slate500, fontSize: 12))),
            )
          else
            ...filteredYearSchedules.asMap().entries.map((entry) {
              return _buildScheduleTimelineItem('${entry.value['month']}월 ${entry.value['day']}일', entry.value['title'], entry.value['color'], _globalSchedules.indexOf(entry.value), entry.value['memo'] ?? '');
            }).toList(),
        ],
      ],
    );
  }

  /// ============================================================================
  /// 📅 2. 월간 뷰 (MONTH VIEW)
  /// ============================================================================
  Widget _buildMonthView() {
    int targetMonth = _selectedMonthIndex + 1;
    List<Map<String, dynamic>> filteredMonthSchedules = _globalSchedules.where((s) => s['month'] == targetMonth).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      children: [
        _buildDynamicSectionHeader('MONTHLY MANAGEMENT', '월간 학습 계획 관리', () { _showAddScheduleBottomSheet(context, '일정'); }),
        const SizedBox(height: 15),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(10), border: Border.all(color: slate800)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('MONTHLY ACHIEVEMENT GAUGE', style: GoogleFonts.notoSerif(fontSize: 12, color: goldColor, fontWeight: FontWeight.bold)),
                  Text('${(_monthlyProgressGauge * 100).toStringAsFixed(1)}%', style: GoogleFonts.notoSerif(fontSize: 13, color: goldColor, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _monthlyProgressGauge,
                  minHeight: 8,
                  backgroundColor: const Color(0xFF0F172A),
                  valueColor: AlwaysStoppedAnimation<Color>(goldColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 12,
            itemBuilder: (context, index) {
              bool isSelected = _selectedMonthIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() { _selectedMonthIndex = index; });
                  _saveState();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? goldColor.withValues(alpha: 0.15) : const Color(0xFF020617),
                    border: Border.all(color: isSelected ? goldColor : slate800, width: 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text('${index + 1}월', style: GoogleFonts.notoSansKr(fontSize: 12, color: isSelected ? goldColor : slate300)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () { setState(() { _isMonthTargetSelected = true; }); _saveState(); },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isMonthTargetSelected ? goldColor : slate800, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MONTHLY TARGET LIST', style: GoogleFonts.notoSerif(fontSize: 14, color: _isMonthTargetSelected ? goldColor : slate400, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$targetMonth월 학습 리스트', style: GoogleFonts.notoSansKr(fontSize: 12, color: _isMonthTargetSelected ? Colors.white : slate500, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () { setState(() { _isMonthTargetSelected = false; }); _saveState(); },
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: !_isMonthTargetSelected ? goldColor : slate800, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MONTHLY MAIN SCHEDULE', style: GoogleFonts.notoSerif(fontSize: 14, color: !_isMonthTargetSelected ? goldColor : slate400, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$targetMonth월 주요 일정', style: GoogleFonts.notoSansKr(fontSize: 12, color: !_isMonthTargetSelected ? Colors.white : slate500, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isMonthTargetSelected) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(10), border: Border.all(color: slate800)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$targetMonth월 핵심 학습 마스터 팩', style: GoogleFonts.notoSansKr(fontSize: 13, color: goldColor, fontWeight: FontWeight.bold)),
                const Divider(color: Color(0xFF1E293B), height: 16),
                _buildReadOnlyStaticTargetItem('$targetMonth월 내신 선행 진도 격파 스케줄'),
                _buildReadOnlyStaticTargetItem('$targetMonth월 모의고사 취약 유형 누적 복습 트랙'),
                _buildReadOnlyStaticTargetItem('$targetMonth월 게이미피케이션 기반 별 수집 레이스 달성'),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(10), border: Border.all(color: slate800)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$targetMonth월 등록 스케줄 건수', style: GoogleFonts.notoSansKr(fontSize: 12, color: slate400)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: goldColor, borderRadius: BorderRadius.circular(12)),
                      child: Text('${filteredMonthSchedules.length}건', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF020617), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF1E293B), height: 16),
                if (filteredMonthSchedules.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('해당 월에 배정된 메인 주요 일정이 존재하지 않습니다.', style: GoogleFonts.notoSansKr(fontSize: 12, color: slate500)),
                  )
                else
                  ...filteredMonthSchedules.map((schedule) {
                    return GestureDetector(
                      onTap: () { _showUnifiedPopupTrack(schedule, typeKey: 'MONTH'); },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6), border: Border.all(color: slate800)),
                        child: Row(
                          children: [
                            Container(width: 4, height: 20, color: schedule['color']),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('[${schedule['day']}일] ${schedule['title']}', style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            ),
                            Icon(Icons.edit_note, color: goldColor, size: 18),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// ============================================================================
  /// 📅 3. 주간 뷰 (WEEK VIEW)
  /// ============================================================================
  Widget _buildWeekView() {
    final List<String> weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    String currentWeekLabel = _scrollableWeeks[_selectedWeekIndex];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      children: [
        _buildDynamicSectionHeader('WEEKLY ANALYTICS', '주간 시간표 및 일정 스위칭', () { _showAddScheduleBottomSheet(context, '목표'); }),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _scrollableWeeks.length,
            itemBuilder: (context, index) {
              bool isSelected = _selectedWeekIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() { _selectedWeekIndex = index; });
                  _saveState();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? goldColor : const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? goldColor : slate800),
                  ),
                  child: Center(
                    child: Text(_scrollableWeeks[index], style: GoogleFonts.notoSansKr(fontSize: 12, color: isSelected ? const Color(0xFF020617) : Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () { setState(() { _isWeekTimelineSelected = true; }); _saveState(); },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isWeekTimelineSelected ? goldColor : slate800, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WEEKLY TIMELINE', style: GoogleFonts.notoSerif(fontSize: 14, color: _isWeekTimelineSelected ? goldColor : slate400, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$currentWeekLabel 학습 타임라인', style: GoogleFonts.notoSansKr(fontSize: 12, color: _isWeekTimelineSelected ? Colors.white : slate500, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () { setState(() { _isWeekTimelineSelected = false; }); _saveState(); },
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: !_isWeekTimelineSelected ? goldColor : slate800, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WEEKLY MAIN SCHEDULE', style: GoogleFonts.notoSerif(fontSize: 14, color: !_isWeekTimelineSelected ? goldColor : slate400, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$currentWeekLabel 주요 일정', style: GoogleFonts.notoSansKr(fontSize: 12, color: !_isWeekTimelineSelected ? Colors.white : slate500, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isWeekTimelineSelected) ...[
          Text('$currentWeekLabel 요일별 고정 기본 템플릿 정보 조망', style: GoogleFonts.notoSansKr(fontSize: 12, color: slate400)),
          const SizedBox(height: 10),
          ...weekdays.map((day) {
            int dayIdx = weekdays.indexOf(day) + 1;
            var list = _weeklyTemplateMaster[_selectedWeekIndex]?[dayIdx] ?? [];
            String mainTaskTitle = list.isNotEmpty ? list[0]['title'] : '자율 학습 설정 트랙';

            Map<String, dynamic> weekSummary = {
              'title': '$day요일: $mainTaskTitle 등 대표 편성',
              'memo': '순환형 주차 톱니바퀴 결합에 따른 고정 템플릿 루틴 구간입니다.',
              'time': '고정 템플릿',
              'color': goldColor
            };

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(8), border: Border.all(color: slate800)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: day == '일' ? examColor : goldColor.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: Text(day, style: GoogleFonts.notoSansKr(fontSize: 12, color: day == '일' ? Colors.white : goldColor, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(weekSummary['title'], style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
                        Text(weekSummary['memo'], style: GoogleFonts.notoSansKr(fontSize: 12, color: slate500), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Icon(Icons.lock_clock, color: slate500, size: 16),
                ],
              ),
            );
          }).toList(),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(8), border: Border.all(color: slate800)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⚡ 주간 고정 결합 일정 브리핑', style: GoogleFonts.notoSansKr(fontSize: 13, color: goldColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildReadOnlyStaticTargetItem('주말 전국단위 오프라인 모의평가 스케줄 바인딩'),
                  _buildReadOnlyStaticTargetItem('주중 피드백 심화 인강 주기적 스트리밍 점검'),
                ],
              ),
            ),
          )
        ],
      ],
    );
  }

  /// ============================================================================
  /// 📅 4. 일간 뷰 (DAY VIEW) - [핵심 패치] 오버플로우 방지 및 무한 시간 확장 지원
  /// ============================================================================
  Widget _buildDayView() {
    List<Map<String, dynamic>> targetDaySchedules = _globalSchedules
        .where((s) =>
    s['year'] == _selectedDayDate.year &&
        s['month'] == _selectedDayDate.month &&
        s['day'] == _selectedDayDate.day)
        .toList();

    final List<String> weekLabelList = ['일', '월', '화', '수', '목', '금', '토'];

    DateTime firstDayOfCurrentMonth = DateTime(_selectedDayDate.year, _selectedDayDate.month, 1);
    int firstDayWeekdayIndex = firstDayOfCurrentMonth.weekday;

    int emptyPrefixCellsCount = firstDayWeekdayIndex == 7 ? 0 : firstDayWeekdayIndex;
    int totalDaysInMonth = DateTime(_selectedDayDate.year, _selectedDayDate.month + 1, 0).day;
    int prevMonthTotalDays = DateTime(_selectedDayDate.year, _selectedDayDate.month, 0).day;

    int totalCalendarGridItemsCount = emptyPrefixCellsCount + totalDaysInMonth;
    if (totalCalendarGridItemsCount % 7 != 0) {
      totalCalendarGridItemsCount += (7 - (totalCalendarGridItemsCount % 7));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      children: [
        _buildDynamicSectionHeader('DAILY SCHEDULER NAVI', '오늘 일정 관리 및 날짜 변경 레일', () { _showAddScheduleBottomSheet(context, '일정'); }),
        const SizedBox(height: 12),

        // [주석] 복잡했던 달력 제어 판 전체를 widgets/planner_calendar_view.dart 새집으로 분가시켜 가동
        PlannerCalendarView(
          selectedDayDate: _selectedDayDate,
          isDayCalendarVisible: _isDayCalendarVisible,
          globalSchedules: _globalSchedules,
          goldColor: goldColor,
          examColor: examColor,
          schoolColor: schoolColor,
          academyColor: academyColor,
          personalColor: personalColor,
          slate400: slate400,
          slate500: slate500,
          slate800: slate800,
          onToggleCalendar: () {
            setState(() { _isDayCalendarVisible = !_isDayCalendarVisible; });
            _saveState();
          },
          onDaySelected: (newDate) {
            setState(() { _selectedDayDate = newDate; });
            _saveState();
            _syncDailyTimelineForDate(_selectedDayDate);
            _calculateMonthlyProgress();
            _showCalendarDaySchedulesPopup(_selectedDayDate.day);
          },
        ),

        // 일간 뷰 좌측 정밀 날짜 인디케이터 블록
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(10), border: Border.all(color: slate800, width: 1.5)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: goldColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: goldColor, width: 1.5)),
                child: Text(
                  '${_selectedDayDate.month.toString().padLeft(2, '0')}/${_selectedDayDate.day.toString().padLeft(2, '0')}',
                  style: GoogleFonts.notoSerif(fontSize: 23, color: goldColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedDayDate.year == DateTime.now().year && _selectedDayDate.month == DateTime.now().month && _selectedDayDate.day == DateTime.now().day
                          ? 'SELECTED TARGET DATE / TODAY STATUS'
                          : 'SELECTED TARGET DATE / ARCHIVE STATUS',
                      style: GoogleFonts.notoSerif(fontSize: 12, color: goldColor, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${['월', '화', '수', '목', '금', '토', '일'][_selectedDayDate.weekday - 1]}요일 오늘의 학습 상태',
                      style: GoogleFonts.notoSansKr(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () { setState(() { _isTimeViewSelected = true; }); _saveState(); },
                child: Container(
                  margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(8), border: Border.all(color: _isTimeViewSelected ? goldColor : slate800, width: 1.5)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DATE TIMELINE', style: GoogleFonts.notoSerif(fontSize: 14, color: _isTimeViewSelected ? goldColor : slate400, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('학습 타임라인', style: GoogleFonts.notoSansKr(fontSize: 12, color: _isTimeViewSelected ? Colors.white : slate500, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () { setState(() { _isTimeViewSelected = false; }); _saveState(); },
                child: Container(
                  margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(8), border: Border.all(color: !_isTimeViewSelected ? goldColor : slate800, width: 1.5)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MAIN SCHEDULE', style: GoogleFonts.notoSerif(fontSize: 14, color: !_isTimeViewSelected ? goldColor : slate400, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('오늘 주요 일정', style: GoogleFonts.notoSansKr(fontSize: 12, color: !_isTimeViewSelected ? Colors.white : slate500, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 🎯 [핵심 패치] 내용이 아무리 길어도 무한 줄바꿈 처리 및 우측 아이콘 배치 안정화
        if (_isTimeViewSelected) ...[
          // [주석] 복잡한 타임라인 렌더링을 widgets/study_timeline_section.dart 새집으로 이사하여 연결 가동
          StudyTimelineSection(
            fixedDayTimelines: _fixedDayTimelines,
            selectedDayDate: _selectedDayDate,
            goldColor: goldColor,
            slate400: slate400,
            slate800: slate800,
            examColor: examColor,
            onUnifiedPopupTrack: (timelineItem, index) {
              _showUnifiedPopupTrack(timelineItem, typeKey: 'DAY_TIME', index: index);
            },
            onAddNewTimeSlot: () {
              _showAddNewTimeSlotDialog();
            },
          ),
        ] else ...[
// [주석] 길었던 오늘 주요 일정 렌더링 파트를 widgets/daily_todo_list_section.dart 새집으로 완전히 분가시켜 무선 연결 가동
          DailyTodoListSection(
            targetDaySchedules: targetDaySchedules,
            schoolColor: schoolColor,
            academyColor: academyColor,
            examColor: examColor,
            personalColor: personalColor,
            goldColor: goldColor,
            slate500: slate500,
            onUnifiedPopupTrack: (item) {
              _showUnifiedPopupTrack(item, typeKey: 'DAY_MAIN');
            },
          ),
        ],
        const SizedBox(height: 10),
      ],
    );
  }

  /// ============================================================================
  /// ➕ [신규 함수 결합] 사용자가 직접 시간대를 무한 확장하여 주입할 수 있는 팝업창
  /// ============================================================================
  void _showAddNewTimeSlotDialog() {
    final TextEditingController newTimeRangeController = TextEditingController();
    final TextEditingController newTitleController = TextEditingController();
    final TextEditingController newMemoController = TextEditingController();
    String customCategory = '기타';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext popContext, StateSetter setPopState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF020617),
              shape: RoundedRectangleBorder(side: BorderSide(color: goldColor, width: 1.5), borderRadius: BorderRadius.circular(12)),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EXTEND TIMELINE SLOT', style: GoogleFonts.notoSerif(fontSize: 14, color: goldColor, fontWeight: FontWeight.bold)),
                  Text('새로운 커스텀 학습 시간대 추가', style: GoogleFonts.notoSansKr(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TIME RANGE / 확장 시간 범위 (예: 23:00 ~ 24:00)', style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: newTimeRangeController, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: '예) 23:00 ~ 24:00 또는 24:00 ~ 01:00',
                        filled: true, fillColor: const Color(0xFF0F172A),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('ACTIVITY TITLE / 활동 계획 과목명', style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: newTitleController, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: '심화 자율 학습 및 오답 정밀 피드백 등', hintStyle: GoogleFonts.notoSansKr(color: slate500, fontSize: 12),
                        filled: true, fillColor: const Color(0xFF0F172A),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('MEMO / 세부 계획 내용', style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: newMemoController, maxLines: 2, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: '상세 진도 혹은 점검 계획 기입', hintStyle: GoogleFonts.notoSansKr(color: slate500, fontSize: 12),
                        filled: true, fillColor: const Color(0xFF0F172A),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () { Navigator.of(dialogContext).pop(); },
                  child: Text('CANCEL / 취소', style: GoogleFonts.notoSansKr(color: slate400, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () {
                    if (newTimeRangeController.text.trim().isEmpty || newTitleController.text.trim().isEmpty) return;

                    final String dateKey = "${_selectedDayDate.year}-${_selectedDayDate.month.toString().padLeft(2, '0')}-${_selectedDayDate.day.toString().padLeft(2, '0')}";

                    setState(() {
                      _fixedDayTimelines.add({
                        'time': newTimeRangeController.text.trim(),
                        'title': newTitleController.text.trim(),
                        'memo': newMemoController.text.trim(),
                        'category': customCategory,
                        'custom_book': '',
                        'is_starred': false
                      });

                      // 인스턴스 테이블에 실시간 강제 보관 조립
                      _dailyExecutionInstanceMap[dateKey] = _fixedDayTimelines;
                    });

                    _calculateMonthlyProgress();
                    _saveMasterData(); // 영구 디스크 저장소 파일 백업 동기화
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text('EXTEND ADD / 시간표 추가 적용', style: GoogleFonts.notoSansKr(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// ============================================================================
  /// 📅 [달력 연동] 주요 일정 브리핑 팝업창
  /// ============================================================================
  void _showCalendarDaySchedulesPopup(int dayNum) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext innerContext, StateSetter setPopupState) {
            List<Map<String, dynamic>> targetSchedules = _globalSchedules
                .where((s) => s['year'] == _selectedDayDate.year && s['month'] == _selectedDayDate.month && s['day'] == dayNum)
                .toList();

            return AlertDialog(
              backgroundColor: const Color(0xFF020617),
              shape: RoundedRectangleBorder(side: BorderSide(color: goldColor, width: 1.5), borderRadius: BorderRadius.circular(12)),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DATE MAIN SCHEDULES', style: GoogleFonts.notoSerif(fontSize: 14, color: goldColor, fontWeight: FontWeight.bold)),
                  Text('${_selectedDayDate.month}월 ${dayNum}일 주요 일정 브리핑', style: GoogleFonts.notoSansKr(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Color(0xFF1E293B), height: 10),
                      const SizedBox(height: 8),

                      if (targetSchedules.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(child: Text('해당 날짜에 등록된 주요 일정이 없습니다.', style: GoogleFonts.notoSansKr(fontSize: 12, color: slate500))),
                        )
                      else
                        ...targetSchedules.map((item) {
                          String catStr = '[학교]';
                          if (item['color'] == academyColor) catStr = '[학원]';
                          if (item['color'] == examColor) catStr = '[시험]';
                          if (item['color'] == personalColor) catStr = '[개인]';

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 5), padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8), border: Border.all(color: item['color'].withValues(alpha: 0.4), width: 1)),
                            child: Row(
                              children: [
                                Text('■ ', style: TextStyle(color: item['color'], fontSize: 16)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('$catStr ${item['title']}', style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                                      if ((item['memo'] ?? '').toString().isNotEmpty)
                                        Padding(padding: const EdgeInsets.only(top: 2.0), child: Text(item['memo'], style: GoogleFonts.notoSansKr(fontSize: 11, color: slate400))),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () { Navigator.of(dialogContext).pop(); _showActualEditorPopup(item, typeKey: 'DAY_MAIN'); },
                                  child: Icon(Icons.settings, color: goldColor, size: 16),
                                )
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () { Navigator.of(dialogContext).pop(); },
                      child: Text('CLOSE / 닫기', style: GoogleFonts.notoSansKr(color: slate400, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: goldColor, visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.add, size: 14, color: Color(0xFF020617)),
                      label: Text('ADD / 일정 추가', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF020617), fontWeight: FontWeight.bold)),
                      onPressed: () { Navigator.of(dialogContext).pop(); _showCalendarQuickAddPopup(dayNum); },
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// ============================================================================
  /// 🎯 [오버플로우 무력화] 일정 신규 생성 입력 팝업창
  /// ============================================================================
  void _showCalendarQuickAddPopup(int dayNum) {
    final TextEditingController quickTitleController = TextEditingController();
    final TextEditingController quickMemoController = TextEditingController();
    String tempCategory = '학교';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext popContext, StateSetter setPopState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF020617),
              shape: RoundedRectangleBorder(side: BorderSide(color: goldColor, width: 1.5), borderRadius: BorderRadius.circular(12)),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ADD CALENDAR ENTRY', style: GoogleFonts.notoSerif(fontSize: 14, color: goldColor, fontWeight: FontWeight.bold)),
                  Text('${_selectedDayDate.month}월 ${dayNum}일 새 주요 일정 추가', style: GoogleFonts.notoSansKr(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CATEGORY / 일정 분류', style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: ['학교', '학원', '시험', '개인'].map((cat) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: cat, groupValue: tempCategory, activeColor: goldColor,
                                onChanged: (value) { setPopState(() { tempCategory = value!; }); },
                              ),
                              Text(cat, style: GoogleFonts.notoSansKr(fontSize: 11, color: Colors.white)),
                            ],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      Text('TITLE / 일정 제목', style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: quickTitleController, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: '간단한 일정 제목을 입력하세요', hintStyle: GoogleFonts.notoSansKr(color: slate500, fontSize: 12),
                          filled: true, fillColor: const Color(0xFF0F172A),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text('MEMO / 상세 내용', style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: quickMemoController, maxLines: 2, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: '상세 일정 내용(메모)을 입력하세요', hintStyle: GoogleFonts.notoSansKr(color: slate500, fontSize: 12),
                          filled: true, fillColor: const Color(0xFF0F172A),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: goldColor),
                      onPressed: () {
                        if (quickTitleController.text.trim().isEmpty) return;

                        Color choiceColor = schoolColor;
                        if (tempCategory == '학원') choiceColor = academyColor;
                        if (tempCategory == '시험') choiceColor = examColor;
                        if (tempCategory == '개인') choiceColor = personalColor;

                        setState(() {
                          _globalSchedules.add({
                            'year': _selectedDayDate.year, 'month': _selectedDayDate.month, 'day': dayNum, 'time': '12:00',
                            'title': quickTitleController.text.trim(), 'color': choiceColor, 'memo': quickMemoController.text.trim(),
                          });
                          _sortGlobalSchedules();
                        });

                        _saveMasterData();
                        Navigator.of(dialogContext).pop();
                        _showCalendarDaySchedulesPopup(dayNum);
                      },
                      child: Text('SAVE AND APPLY / 일정 등록 저장하기', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF020617), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// ============================================================================
  /// 💎 정밀 컴포넌트 편의성 메서드 트랙
  /// ============================================================================
  Widget _buildReadOnlyStaticTargetItem(String targetText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(Icons.adjust, color: goldColor, size: 14),
          const SizedBox(width: 10),
          Expanded(child: Text(targetText, style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white))),
        ],
      ),
    );
  }

  /// ============================================================================
  /// 📢 미션 상세 조회 및 게이미피케이션 별 수집 동적 통제 팝업창
  /// ============================================================================
  void _showUnifiedPopupTrack(Map<String, dynamic> targetItem, {required String typeKey, int index = 0}) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        bool isStarred = targetItem['is_starred'] ?? false;

        return StatefulBuilder(
          builder: (BuildContext viewContext, StateSetter setViewState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF020617),
              shape: RoundedRectangleBorder(side: BorderSide(color: goldColor, width: 1.5), borderRadius: BorderRadius.circular(12)),
              titlePadding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 4),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MISSION DETAILS', style: GoogleFonts.notoSerif(fontSize: 14, color: goldColor, fontWeight: FontWeight.bold)),
                  Text('학습 계획 상세 조회', style: GoogleFonts.notoSansKr(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: Color(0xFF1E293B), height: 10),
                    const SizedBox(height: 8),
                    _buildReadOnlyLine('⏰ TIME / 시간 설정', targetItem['time'] ?? '종일 설정됨'),
                    _buildReadOnlyLine('📚 TITLE / 계획 명칭', targetItem['title'] ?? ''),

                    if (typeKey == 'DAY_TIME') ...[
                      _buildReadOnlyLine('📂 CATEGORY / 학습 형태', '[${targetItem['category'] ?? '기타'}]'),
                      if (targetItem['category'] == '문제집' && (targetItem['custom_book'] ?? '').toString().isNotEmpty)
                        _buildReadOnlyLine('📘 TEXTBOOK / 교재 정보', targetItem['custom_book']),
                    ],

                    _buildReadOnlyLine('📢 MEMO / 상세 계획', targetItem['memo'] ?? '기록된 메모 내역이 존재하지 않습니다.'),
                    const SizedBox(height: 10),

                    if (typeKey == 'DAY_TIME') ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: isStarred ? slate500 : goldColor, width: 1.5),
                            backgroundColor: isStarred ? Colors.transparent : goldColor.withValues(alpha: 0.08),
                          ),
                          icon: Icon(isStarred ? Icons.star : Icons.star_border, color: goldColor, size: 18),
                          label: Text(
                            isStarred ? 'STAR COLLECTED / 별 수집 완료' : 'COLLECT STAR / 미션 완료! 별 수집하기',
                            style: GoogleFonts.notoSansKr(fontSize: 12, color: isStarred ? slate400 : goldColor, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            setViewState(() { isStarred = !isStarred; });
                            setState(() { _fixedDayTimelines[index]['is_starred'] = isStarred; });
                            _calculateMonthlyProgress();
                            _saveMasterData();
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () { Navigator.of(dialogContext).pop(); },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text('CLOSE / 닫기', style: GoogleFonts.notoSansKr(color: slate400, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: goldColor, visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.settings, size: 14, color: Color(0xFF020617)),
                      label: Text('EDIT / 수정·삭제', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF020617), fontWeight: FontWeight.bold)),
                      onPressed: () { Navigator.of(dialogContext).pop(); _showActualEditorPopup(targetItem, typeKey: typeKey, index: index); },
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildReadOnlyLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// ============================================================================
  /// 🛠️ 세부 계획 정밀 에디터 변경 모달 제어판
  /// ============================================================================
  void _showActualEditorPopup(Map<String, dynamic> targetItem, {required String typeKey, int index = 0}) {
    final TextEditingController editTimeController = TextEditingController(text: targetItem['time'] ?? '');
    final TextEditingController editTitleController = TextEditingController(text: targetItem['title'] ?? '');
    final TextEditingController editMemoController = TextEditingController(text: targetItem['memo'] ?? '');

    String currentCategory = targetItem['category'] ?? '기타';
    final List<String> categoriesList = ['학원', '동영상', '문제집', '교과서', '기타'];
    final TextEditingController bookInputController = TextEditingController(text: targetItem['custom_book'] ?? '');

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext popContext, StateSetter setPopState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF020617),
              shape: RoundedRectangleBorder(side: BorderSide(color: goldColor, width: 1), borderRadius: BorderRadius.circular(12)),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EDIT MODE RUN', style: GoogleFonts.notoSerif(fontSize: 14, color: goldColor, fontWeight: FontWeight.bold)),
                  Text('학습 계획 편집 및 변경', style: GoogleFonts.notoSansKr(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TIME', style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                    TextField(
                      controller: editTimeController, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'TIME / 시간 입력', hintStyle: GoogleFonts.notoSansKr(color: slate400, fontSize: 12),
                        filled: true, fillColor: const Color(0xFF0F172A),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('SUBJECT OR TITLE', style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                    TextField(
                      controller: editTitleController, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'TITLE / 제목 입력', hintStyle: GoogleFonts.notoSansKr(color: slate400, fontSize: 12),
                        filled: true, fillColor: const Color(0xFF0F172A),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (typeKey == 'DAY_TIME') ...[
                      Text('CATEGORY SELECT', style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 6, runSpacing: 4,
                        children: categoriesList.map((category) {
                          bool isSel = currentCategory == category;
                          return ChoiceChip(
                            label: Text(category, style: GoogleFonts.notoSansKr(fontSize: 11, color: isSel ? const Color(0xFF020617) : Colors.white, fontWeight: FontWeight.bold)),
                            selected: isSel, selectedColor: goldColor, backgroundColor: const Color(0xFF0F172A),
                            checkmarkColor: const Color(0xFF020617), side: BorderSide(color: isSel ? goldColor : slate800),
                            onSelected: (bool selected) { if (selected) { setPopState(() { currentCategory = category; }); } },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      if (currentCategory == '문제집') ...[
                        Text('WORKBOOK NAME', style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                        TextField(
                          controller: bookInputController, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: '예) "블랙라벨"', hintStyle: GoogleFonts.notoSansKr(color: slate500, fontSize: 12),
                            filled: true, fillColor: const Color(0xFF0F172A),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],

                    Text('MEMO / DETAILS', style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                    TextField(
                      controller: editMemoController, maxLines: 2, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'MEMO / 상세 메모 입력', hintStyle: GoogleFonts.notoSansKr(color: slate400, fontSize: 12),
                        filled: true, fillColor: const Color(0xFF0F172A),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (typeKey == 'DAY_TIME')
                      TextButton(
                        onPressed: () {
                          final String dateKey = "${_selectedDayDate.year}-${_selectedDayDate.month.toString().padLeft(2, '0')}-${_selectedDayDate.day.toString().padLeft(2, '0')}";
                          setState(() {
                            _fixedDayTimelines.removeAt(index);
                            _dailyExecutionInstanceMap[dateKey] = _fixedDayTimelines;
                          });
                          _calculateMonthlyProgress();
                          _saveMasterData();
                          Navigator.of(dialogContext).pop();
                        },
                        child: Text('DELETE / 삭제', style: GoogleFonts.notoSansKr(color: examColor, fontSize: 13, fontWeight: FontWeight.bold)),
                      )
                    else if (typeKey != 'DAY_TIME')
                      TextButton(
                        onPressed: () {
                          setState(() { _globalSchedules.removeWhere((s) => s['title'] == targetItem['title'] && s['day'] == targetItem['day'] && s['month'] == targetItem['month']); });
                          _saveMasterData();
                          Navigator.of(dialogContext).pop();
                        },
                        child: Text('DELETE / 삭제', style: GoogleFonts.notoSansKr(color: examColor, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        String newTime = editTimeController.text.trim();
                        String newTitle = editTitleController.text.trim();
                        String newMemo = editMemoController.text.trim();
                        if (newTitle.isEmpty) return;

                        setState(() {
                          if (typeKey == 'DAY_TIME') {
                            _fixedDayTimelines[index]['time'] = newTime.isEmpty ? _fixedDayTimelines[index]['time'] : newTime;
                            _fixedDayTimelines[index]['title'] = newTitle;
                            _fixedDayTimelines[index]['memo'] = newMemo;
                            _fixedDayTimelines[index]['category'] = currentCategory;
                            _fixedDayTimelines[index]['custom_book'] = currentCategory == '문제집' ? bookInputController.text.trim() : '';
                          } else {
                            int idx = _globalSchedules.indexOf(targetItem);
                            if (idx != -1) {
                              _globalSchedules[idx]['time'] = newTime;
                              _globalSchedules[idx]['title'] = newTitle;
                              _globalSchedules[idx]['memo'] = newMemo;
                              _sortGlobalSchedules();
                            }
                          }
                        });

                        _calculateMonthlyProgress();
                        _saveMasterData();
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text('SAVE / 저장', style: GoogleFonts.notoSansKr(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDynamicSectionHeader(String eng, String kor, VoidCallback onAddTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(eng, style: GoogleFonts.notoSerif(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold)),
            Text(kor, style: GoogleFonts.notoSansKr(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold)),
          ],
        ),
        GestureDetector(
          onTap: onAddTap,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: goldColor, width: 1.5), color: goldColor.withValues(alpha: 0.08)),
            child: Icon(Icons.add, color: goldColor, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildYearChecklistItem(String title, bool isChecked, int index, String yearKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() { _yearlyTargetsMap[yearKey]![index]['done'] = !isChecked; });
              _saveMasterData();
            },
            child: Container(
              padding: const EdgeInsets.all(4.0), color: Colors.transparent,
              child: Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank, color: isChecked ? goldColor : slate500, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                _showUnifiedPopupTrack({
                  'time': '$yearKey 전반 마스터 리전', 'title': title,
                  'memo': '국내 및 글로벌 상용화 목표 달성을 위한 연간 전개 스케줄 목표치입니다.', 'done': isChecked,
                }, typeKey: 'YEAR');
              },
              child: Container(
                color: Colors.transparent, alignment: Alignment.centerLeft,
                child: Text(title, style: GoogleFonts.notoSansKr(fontSize: 12, color: isChecked ? slate400 : Colors.white, decoration: isChecked ? TextDecoration.lineThrough : null)),
              ),
            ),
          ),
          Icon(Icons.remove_red_eye, color: goldColor.withValues(alpha: 0.5), size: 14),
        ],
      ),
    );
  }

  Widget _buildScheduleTimelineItem(String timeLabel, String eventTitle, Color leftBarColor, int index, String memo) {
    return GestureDetector(
      onTap: () { if (index >= 0 && index < _globalSchedules.length) { _showUnifiedPopupTrack(_globalSchedules[index], typeKey: 'YEAR'); } },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF020617), border: Border(left: BorderSide(color: leftBarColor, width: 4))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(timeLabel, style: GoogleFonts.notoSerif(fontSize: 12, color: goldColor)),
            Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14.0), child: Text(eventTitle, style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.right))),
            Icon(Icons.remove_red_eye, color: goldColor.withValues(alpha: 0.5), size: 14),
          ],
        ),
      ),
    );
  }

  void _showAddScheduleBottomSheet(BuildContext context, String initialType) {
    String entryType = initialType; String selectedCategory = '학교';
    final TextEditingController titleController = TextEditingController();
    final TextEditingController monthController = TextEditingController();
    final TextEditingController dayController = TextEditingController();
    final TextEditingController memoController = TextEditingController();

    showModalBottomSheet(
      context: context, backgroundColor: const Color(0xFF020617), isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (BuildContext bc) {
        return StatefulBuilder(
          builder: (BuildContext modalContext, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ADD NEW ENTRY', style: GoogleFonts.notoSerif(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold)),
                    Text('새 리스트 추가하기', style: GoogleFonts.notoSansKr(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                    const Divider(color: Color(0xFF1E293B), height: 20),
                    Row(
                      children: ['일정', '목표'].map((type) {
                        return Row(children: [
                          Radio<String>(value: type, groupValue: entryType, activeColor: goldColor, onChanged: (value) { setModalState(() { entryType = value!; }); }),
                          Text(type, style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white)), const SizedBox(width: 20),
                        ]);
                      }).toList(),
                    ),
                    if (entryType == '일정') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: ['학교', '학원', '시험', '개인'].map((cat) {
                          return Row(mainAxisSize: MainAxisSize.min, children: [
                            Radio<String>(value: cat, groupValue: selectedCategory, activeColor: goldColor, onChanged: (value) { setModalState(() { selectedCategory = value!; }); }),
                            Text(cat, style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white)),
                          ]);
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleController, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(hintText: entryType == '일정' ? 'TITLE / 일정 제목' : 'TARGET / 목표 내용', filled: true, fillColor: const Color(0xFF0F172A), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor))),
                    ),
                    if (entryType == '일정') ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: monthController, keyboardType: TextInputType.number, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12), decoration: InputDecoration(hintText: 'MONTH / 월 숫자', filled: true, fillColor: const Color(0xFF0F172A), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor))))),
                          const SizedBox(width: 10),
                          Expanded(child: TextField(controller: dayController, keyboardType: TextInputType.number, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12), decoration: InputDecoration(hintText: 'DAY / 일 숫자', filled: true, fillColor: const Color(0xFF0F172A), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor))))),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: memoController, maxLines: 2, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(hintText: 'MEMO / 상세 내용 계획 기입', filled: true, fillColor: const Color(0xFF0F172A), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor))),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity, height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: goldColor),
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) return;
                          if (entryType == '목표') {
                            String currentYearKey = _scrollableYears[_selectedYearIndex];
                            setState(() { _yearlyTargetsMap[currentYearKey]!.add({'title': titleController.text.trim(), 'done': false}); });
                            _saveMasterData();
                          } else {
                            Color sColor = schoolColor;
                            if (selectedCategory == '학원') sColor = academyColor;
                            if (selectedCategory == '시험') sColor = examColor;
                            if (selectedCategory == '개인') sColor = personalColor;
                            int inputMonth = int.tryParse(monthController.text.trim()) ?? 7;
                            int inputDay = int.tryParse(dayController.text.trim()) ?? 1;

                            setState(() {
                              _globalSchedules.add({
                                'year': 2026, 'month': inputMonth, 'day': inputDay, 'time': '12:00',
                                'title': titleController.text.trim(), 'color': sColor, 'memo': memoController.text.trim(),
                              });
                              _sortGlobalSchedules();
                              _selectedDayDate = DateTime(2026, inputMonth, inputDay);
                            });

                            _syncDailyTimelineForDate(_selectedDayDate);
                            _calculateMonthlyProgress();
                            _saveState();
                            _saveMasterData();
                          }
                          Navigator.pop(modalContext);
                        },
                        child: Text('SAVE AND APPLY / 저장 및 연동 적용하기', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF020617), fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}