import 'package:flutter/material.dart';
// [주석] 구글 폰트 패키지 임포트
import 'package:google_fonts/google_fonts.dart';

/// ============================================================================
/// [GKE StudyUp] 자기주도 학습 플래너 - 학습 계획 스크린 (planning_screen.dart)
/// ============================================================================
class PlanningScreen extends StatefulWidget {
  const PlanningScreen({Key? key}) : super(key: key);

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> with SingleTickerProviderStateMixin {
  // [주석] 상단 [연간][월간][주간][일간] 4개 탭 제어 컨트롤러
  late TabController _tabController;

  // [주석] 카테고리별 테마 색상 (지시사항 엄격 준수)
  final Color schoolColor = const Color(0xFF3B82F6);   // 학교 일정 (파랑색 사각형)
  final Color academyColor = const Color(0xFF10B981);  // 학원 일정 (녹색 사각형)
  final Color examColor = const Color(0xFFEF4444);     // 시험 일정 (기존 빨강색 유지)
  final Color personalColor = const Color(0xFFFACC15); // 개인 일정 (노랑색 사각형으로 변경)
  final Color goldColor = const Color(0xFFD4AF37);     // 공식 황금색

  // [주석] 테마 컬러 상수 정의
  final Color slate300 = const Color(0xFFCBD5E1);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color slate500 = const Color(0xFF64748B);
  final Color slate800 = const Color(0xFF1E293B);

  // [주석] 확장 및 숨김 상태 제어 변수
  bool _isYearTargetExpanded = true;
  bool _isDayCalendarVisible = false;

  // [주석] 지시사항 2번: 시간대 타임라인 VS 오늘 주요 일정 동적 토글 선택 제어 변수
  bool _isTimeViewSelected = true;

  // [주석] 연간 뷰 가로 스크롤 연도 리스트
  int _selectedYearIndex = 0;
  final List<String> _scrollableYears = [
    '2026년 목표',
    '2027년 목표',
    '2028년 목표',
    '2029년 목표',
    '2030년 목표',
  ];

  // [주석] 월간 뷰 가로 스크롤 인덱스 (2026년 7월 기준 자동 선택: 인덱스 6)
  int _selectedMonthIndex = 6;

  // [주석] 주간 뷰 가로 스크롤 주차 리스트
  int _selectedWeekIndex = 0;
  final List<String> _scrollableWeeks = [
    '1주차',
    '2주차',
    '3주차',
    '4주차',
    '5주차',
  ];

  // [주석] 일간 뷰 동적 날짜 선택 변수 (기본값: 2026년 7월 1일 오늘 날짜 자동 설정)
  DateTime _selectedDayDate = DateTime(2026, 7, 1);

  // ============================================================================
  // [주석] 글로벌 데이터 센터: 모든 탭이 실시간으로 동기화되어 순환하는 마스터 모델
  // ============================================================================
  late Map<String, List<Map<String, dynamic>>> _yearlyTargetsMap;
  late List<Map<String, dynamic>> _globalSchedules;

  // [주석] 지시사항 반영: 일간 날짜별 정밀 고정 타임라인 관리 데이터 센터
  late List<Map<String, dynamic>> _fixedDayTimelines;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // [주석] 연도별 목표 초기 데이터
    _yearlyTargetsMap = {
      '2026년 목표': [
        {'title': '2026 민사고 합격 독점 스케줄', 'done': true},
        {'title': '2026 수학 내신 1등급 완성', 'done': false},
        {'title': '2026 영어 수능 최저학력기준 충족', 'done': false},
      ],
      '2027년 목표': [
        {'title': '2027 고등 전과목 심화 마스터', 'done': false},
      ],
      '2028년 목표': [],
      '2029년 목표': [],
      '2030년 목표': [],
    };

    // [주석] 통합 바인딩형 마스터 스케줄 데이터 센터
    _globalSchedules = [
      {
        'year': 2026,
        'month': 7,
        'day': 1,
        'time': '08:00',
        'title': '고등학교 학업 평가단 입과 수행',
        'color': schoolColor,
        'memo': '새로운 고등 학업의 시작점 세팅',
      },
      {
        'year': 2026,
        'month': 7,
        'day': 1,
        'time': '16:00',
        'title': '대성학원 대입 종합 윈터클리닉 연동',
        'color': academyColor,
        'memo': '심화 연동 마스터 코스 배정 완료',
      },
      {
        'year': 2026,
        'month': 7,
        'day': 1,
        'time': '21:00',
        'title': '전국 연합 모의고사 오답 백서 검증',
        'color': examColor,
        'memo': '오답노트 완벽 정리 및 취약 영역 분석',
      },
      {
        'year': 2026,
        'month': 7,
        'day': 1,
        'time': '22:30',
        'title': '개인 플래너 별 누적 리프레시',
        'color': personalColor,
        'memo': '대시보드 별 누적 시스템 가동',
      },
    ];

    // [주석] 지시사항 준수: 정밀 24시간 순차적 타임라인 트랙 원형 데이터 바인딩
    _fixedDayTimelines = [
      {'time': '06:00 ~ 07:00', 'title': '기상 및 암기', 'memo': '새벽 기상 후 핵심 단어 및 암기과정 마스터 리프레시'},
      {'time': '08:00', 'title': '등교', 'memo': '오전 등교 및 주간 자율 플래너 로드 진입 완료'},
      {'time': '08:00 ~ 16:00', 'title': '학교생활', 'memo': '학교 정규 교과 수업 집중 이수 및 학업 성취도 빌드업'},
      {'time': '16:00 ~ 17:00', 'title': '휴식', 'memo': '에너지 충전 및 하교 후 자기주도 학습 모드 전환 휴식'},
      {'time': '17:00 ~ 18:00', 'title': '고등수학', 'memo': '고등 수학 기본 개념 맵핑 및 유형별 고난도 문제 격파'},
      {'time': '18:00 ~ 19:00', 'title': '저녁식사', 'memo': '균형 잡힌 영양 섭취 및 야간 집중 자습 리커버리 시간'},
      {'time': '19:00 ~ 20:00', 'title': '고등영어 자이스토리 실전', 'memo': '자이스토리 실전 모의고사 분석 및 고난도 구문 독해 트레이닝'},
      {'time': '20:00 ~ 21:00', 'title': '중등2-2 진도', 'memo': '중등 2학년 2학기 핵심 기하 파트 심화 진도 선행 점검'},
      {'time': '21:00 ~ 22:00', 'title': '세계사', 'memo': '세계사 주요 연표 마인드맵핑 및 흐름 정리 암기 트랙'},
      {'time': '22:00 ~ 23:00', 'title': '오늘것 오답 또는 총정리', 'memo': '오늘 진행된 전체 진도 오답노트 정밀 기록 및 최종 스터디업 클로징'},
    ];

    _sortGlobalSchedules();
  }

  void _sortGlobalSchedules() {
    _globalSchedules.sort((a, b) {
      int monthComp = (a['month'] as int).compareTo(b['month'] as int);
      if (monthComp != 0) return monthComp;
      return (a['day'] as int).compareTo(b['day'] as int);
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

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      children: [
        Text('YEARLY TARGET', style: GoogleFonts.notoSerif(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold)),
        Text('연간 목표 관리', style: GoogleFonts.notoSansKr(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold)),
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
                    child: Text(_scrollableYears[index], style: GoogleFonts.notoSansKr(fontSize: 12, color: isSelected ? goldColor : slate300)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFF020617),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(side: BorderSide(color: slate800)),
          child: ExpansionTile(
            key: ValueKey(currentYearKey),
            initiallyExpanded: _isYearTargetExpanded,
            title: Text('$currentYearKey 리스트', style: GoogleFonts.notoSansKr(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold)),
            iconColor: goldColor,
            collapsedIconColor: slate400,
            onExpansionChanged: (val) { setState(() { _isYearTargetExpanded = val; }); },
            children: [
              if (currentTargets.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Text('등록된 목표가 없습니다. 우측 + 버튼으로 추가하세요.', style: GoogleFonts.notoSansKr(color: slate500, fontSize: 12)),
                )
              else
                ...currentTargets.asMap().entries.map((entry) {
                  return _buildYearChecklistItem(entry.value['title'], entry.value['done'], entry.key, currentYearKey);
                }).toList(),
              const SizedBox(height: 10),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildDynamicSectionHeader('YEARLY TARGET TIMELINE', '연간 목표 및 일정 타임라인', () { _showAddScheduleBottomSheet(context, '일정'); }),
        const SizedBox(height: 10),
        ..._globalSchedules.asMap().entries.map((entry) {
          return _buildScheduleTimelineItem('${entry.value['month']}월 ${entry.value['day']}일', entry.value['title'], entry.value['color'], entry.key, entry.value['memo'] ?? '');
        }).toList(),
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
        _buildDynamicSectionHeader('MONTHLY TARGET OVERVIEW', '월간 학습 계획 관리', () { _showAddScheduleBottomSheet(context, '일정'); }),
        const SizedBox(height: 15),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 12,
            itemBuilder: (context, index) {
              bool isSelected = _selectedMonthIndex == index;
              return GestureDetector(
                onTap: () { setState(() { _selectedMonthIndex = index; }); },
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
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF020617),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: slate800, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Month $targetMonth Schedules', style: GoogleFonts.notoSerif(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold)),
                      Text('$targetMonth월 주요 통합 계획 리스트', style: GoogleFonts.notoSansKr(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: goldColor, borderRadius: BorderRadius.circular(12)),
                    child: Text('${filteredMonthSchedules.length}건', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF020617), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF1E293B), height: 16),
              if (filteredMonthSchedules.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('해당 월에 등록된 주요 계획 및 스케줄이 없습니다.', style: GoogleFonts.notoSansKr(fontSize: 12, color: slate500)),
                )
              else
                ...filteredMonthSchedules.map((schedule) {
                  return GestureDetector(
                    onTap: () { _showEditDeletePopup(schedule); },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6), border: Border.all(color: slate800)),
                      child: Row(
                        children: [
                          Container(width: 4, height: 20, color: schedule['color']),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('[${schedule['day']}일] ${schedule['title']}', style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                Text(schedule['memo'] ?? '', style: GoogleFonts.notoSansKr(fontSize: 12, color: slate400), overflow: TextOverflow.ellipsis),
                              ],
                            ),
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
    );
  }

  /// ============================================================================
  /// 📅 3. 주간 뷰 (WEEK VIEW)
  /// ============================================================================
  Widget _buildWeekView() {
    final List<String> weekdays = ['일', '월', '화', '수', '목', '금', '토'];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      children: [
        _buildDynamicSectionHeader('WEEKLY TRACKING SYSTEM', '주간 목표 학습 시간 및 계획', () { _showAddScheduleBottomSheet(context, '목표'); }),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _scrollableWeeks.length,
            itemBuilder: (context, index) {
              bool isSelected = _selectedWeekIndex == index;
              return GestureDetector(
                onTap: () { setState(() { _selectedWeekIndex = index; }); },
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
        const SizedBox(height: 15),
        Text('${_scrollableWeeks[_selectedWeekIndex]} 요일별 계획 리스트 (상세보기 클릭)', style: GoogleFonts.notoSansKr(fontSize: 12, color: slate400)),
        const SizedBox(height: 10),
        ... weekdays.map((day) {
          String uniqueScheduleKey = '${_scrollableWeeks[_selectedWeekIndex]}_$day';
          Map<String, dynamic> weekSchedule;
          try {
            weekSchedule = _globalSchedules.firstWhere((s) => s['week_key'] == uniqueScheduleKey);
          } catch (_) {
            weekSchedule = {
              'week_key': uniqueScheduleKey,
              'title': day == '월' ? '월요 영단어 1000개 심화 암기' : (day == '수' ? '수요 수학 고난도 문제집 단원 완성' : '$day요일 자기주도 학습 목표 도달 훈련'),
              'memo': '$day요일 진도 계획 준수 및 플래너 별 누적 리프레시 검증.',
              'time': '종일',
              'color': goldColor,
              'is_weekly': true
            };
          }

          return GestureDetector(
            onTap: () { _showEditDeletePopup(weekSchedule, isWeeklyType: true); },
            child: Container(
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
                        Text(weekSchedule['title'], style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
                        Text(weekSchedule['memo'], style: GoogleFonts.notoSansKr(fontSize: 12, color: slate500), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_calendar, color: goldColor.withValues(alpha: 0.6), size: 16),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  /// ============================================================================
  /// 📅 4. 일간 뷰 (DAY VIEW)
  /// ============================================================================
  Widget _buildDayView() {
    String formattedDayStr = _selectedDayDate.day < 10 ? '0${_selectedDayDate.day}일' : '${_selectedDayDate.day}일';

    List<Map<String, dynamic>> targetDaySchedules = _globalSchedules
        .where((s) =>
    (s['year'] ?? _selectedDayDate.year) == _selectedDayDate.year &&
        s['month'] == _selectedDayDate.month &&
        s['day'] == _selectedDayDate.day)
        .toList();

    // 🛠️ [지시사항 1 반영]: 선택한 달의 1일 시작 요일 및 총 일수를 반영하는 정밀 알고리즘
    final List<String> weekLabelList = ['월', '화', '수', '목', '금', '토', '일'];
    DateTime firstDayOfCurrentMonth = DateTime(_selectedDayDate.year, _selectedDayDate.month, 1);
    int firstDayWeekdayIndex = firstDayOfCurrentMonth.weekday; // 월요일: 1 ~ 일요일: 7
    int totalDaysInMonth = DateTime(_selectedDayDate.year, _selectedDayDate.month + 1, 0).day;
    int emptyPrefixCellsCount = firstDayWeekdayIndex - 1; // 앞에 비워두어야 할 공백 개수 계산
    int totalCalendarGridItemsCount = totalDaysInMonth + emptyPrefixCellsCount;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      children: [
        _buildDynamicSectionHeader('DAILY SCHEDULER NAVI', '오늘 일정 관리 및 날짜 변경 레일', () { _showAddScheduleBottomSheet(context, '일정'); }),
        const SizedBox(height: 12),

        GestureDetector(
          onTap: () { setState(() { _isDayCalendarVisible = !_isDayCalendarVisible; }); },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: goldColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month, color: goldColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'CALENDAR / 달력 열기.닫기',
                      style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Icon(_isDayCalendarVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: goldColor)
              ],
            ),
          ),
        ),

        if (_isDayCalendarVisible) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(12), border: Border.all(color: slate800)),
            child: Column(
              children: [
                Text('DATE CONTROL RAIL', style: GoogleFonts.notoSerif(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold)),
                Text('${_selectedDayDate.year}년 ${_selectedDayDate.month}월 달력 제어 레일', style: GoogleFonts.notoSansKr(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                // 달력 요일 텍스트 상단 레일 바 추가
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 7,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 0,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2,
                  ),
                  itemBuilder: (context, index) {
                    return Center(
                      child: Text(
                        weekLabelList[index],
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11,
                          color: weekLabelList[index] == '일' ? examColor : (weekLabelList[index] == '토' ? schoolColor : slate400),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(color: Color(0xFF1E293B), height: 10),
                // 요일 자동 계산 매칭 그리드
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalCalendarGridItemsCount,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1),
                  itemBuilder: (context, index) {
                    if (index < emptyPrefixCellsCount) {
                      return const SizedBox.shrink(); // 월 시작 이전 칸은 빈 공백 처리
                    }

                    int dayButtonNum = index - emptyPrefixCellsCount + 1;
                    bool isSelected = _selectedDayDate.day == dayButtonNum;
                    bool hasData = _globalSchedules.any((s) =>
                    (s['year'] ?? _selectedDayDate.year) == _selectedDayDate.year &&
                        s['month'] == _selectedDayDate.month &&
                        s['day'] == dayButtonNum);

                    return GestureDetector(
                      onTap: () {
                        setState(() { _selectedDayDate = DateTime(_selectedDayDate.year, _selectedDayDate.month, dayButtonNum); });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? goldColor : (hasData ? goldColor.withValues(alpha: 0.12) : const Color(0xFF0F172A)),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isSelected ? goldColor : (hasData ? goldColor : slate800)),
                        ),
                        child: Center(
                          child: Text('$dayButtonNum', style: GoogleFonts.notoSerif(fontSize: 12, color: isSelected ? const Color(0xFF020617) : Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // 🛠️ [지시사항 2 반영]: DATE TIMELINE과 MAIN SCHEDULE 전체를 각각 하나의 터치 가능한 카드 디자인 행으로 완전 묶음 처리 (에러 완벽 수정)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // [왼쪽] DATE TIMELINE 카드 묶음 패널
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() { _isTimeViewSelected = true; });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isTimeViewSelected ? goldColor : slate800, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DATE TIMELINE', style: GoogleFonts.notoSerif(fontSize: 14, color: _isTimeViewSelected ? goldColor : slate400, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$formattedDayStr 시간대 타임라인', style: GoogleFonts.notoSansKr(fontSize: 12, color: _isTimeViewSelected ? Colors.white : slate500, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            // [오른쪽] MAIN SCHEDULE 카드 묶음 패널
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() { _isTimeViewSelected = false; });
                },
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: !_isTimeViewSelected ? goldColor : slate800, width: 1.5),
                  ),
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

        // [주석] 사용자가 시간대 버튼을 활성화 하였을 때 전개되는 영역
        if (_isTimeViewSelected) ...[
          ..._fixedDayTimelines.asMap().entries.map((entry) {
            final timelineItem = entry.value;
            return GestureDetector(
              onTap: () { _showEditDeletePopup(timelineItem, isFixedTimelineType: true, index: entry.key); },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(8), border: Border.all(color: slate800)),
                child: Row(
                  children: [
                    // 🛠 *[지시사항 3 반영]: 시간의 글자 크기를 15로 전격 확대 조정
                    Text(
                      timelineItem['time'],
                      style: GoogleFonts.notoSerif(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        timelineItem['title'],
                        style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Icon(Icons.edit, color: slate500, size: 14),
                  ],
                ),
              ),
            );
          }).toList(),
        ] else ...[
          // [주석] 사용자가 주요 일정 버튼을 활성화 하였을 때 전개되는 레이아웃 구역
          if (targetDaySchedules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: Text('오늘 등록된 주요 일정이 없습니다.', style: GoogleFonts.notoSansKr(color: slate500, fontSize: 12)),
              ),
            )
          else
            ...targetDaySchedules.map((item) {
              String categoryLabel = '[학교]';
              Color squareColor = schoolColor; // 파랑색

              if (item['color'] == academyColor) {
                categoryLabel = '[학원]';
                squareColor = academyColor; // 녹색
              } else if (item['color'] == examColor) {
                categoryLabel = '[시험]';
                squareColor = examColor; // 빨강색
              } else if (item['color'] == personalColor) {
                categoryLabel = '[개인]';
                squareColor = personalColor; // 노랑색
              }

              return GestureDetector(
                onTap: () { _showEditDeletePopup(item); },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: squareColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '■ ',
                        style: TextStyle(color: squareColor, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$categoryLabel ',
                        style: GoogleFonts.notoSansKr(color: squareColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item['time']} - ${item['title']}',
                              style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item['memo'] != null)
                              Text(
                                item['memo'],
                                style: GoogleFonts.notoSansKr(fontSize: 12, color: slate400),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit_note, color: goldColor.withValues(alpha: 0.7), size: 18),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],

        const SizedBox(height: 10),
        // 🛠 *[지시사항 4 반영]: 최하단에 중복 배치되어 화면 가림 및 혼선을 주던 영문 및 한글 텍스트 블록 완전 영구 삭제 완료
      ],
    );
  }

  /// ============================================================================
  /// [주석] 지시사항 반영: 통합 일정/목표/타임라인 수정 및 삭제 팝업 제어 모듈
  /// ============================================================================
  void _showEditDeletePopup(Map<String, dynamic> targetItem, {bool isWeeklyType = false, bool isFixedTimelineType = false, int index = 0}) {
    final TextEditingController editTimeController = TextEditingController(text: targetItem['time'] ?? '');
    final TextEditingController editTitleController = TextEditingController(text: targetItem['title'] ?? '');
    final TextEditingController editMemoController = TextEditingController(text: targetItem['memo'] ?? '');

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF020617),
          shape: RoundedRectangleBorder(side: BorderSide(color: goldColor, width: 1), borderRadius: BorderRadius.circular(12)),
          titlePadding: const EdgeInsets.only(top: 14, left: 16, right: 16, bottom: 4),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EDIT ENTRY', style: GoogleFonts.notoSerif(fontSize: 14, color: goldColor, fontWeight: FontWeight.bold)),
              Text('일정 수정 및 삭제', style: GoogleFonts.notoSansKr(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: editTimeController,
                  style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'TIME / 시간 입력 (예: 09:00)',
                    hintStyle: GoogleFonts.notoSansKr(color: slate400, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: editTitleController,
                  style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'TITLE / 제목 입력',
                    hintStyle: GoogleFonts.notoSansKr(color: slate400, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: editMemoController,
                  maxLines: 2,
                  style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'MEMO / 상세 메모 입력',
                    hintStyle: GoogleFonts.notoSansKr(color: slate400, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (!isFixedTimelineType)
              TextButton(
                onPressed: () {
                  setState(() {
                    if (isWeeklyType) {
                      _globalSchedules.removeWhere((s) => s['week_key'] == targetItem['week_key']);
                    } else {
                      int idx = _globalSchedules.indexOf(targetItem);
                      if (idx == -1) {
                        idx = _globalSchedules.indexWhere((s) =>
                        s['year'] == targetItem['year'] &&
                            s['month'] == targetItem['month'] &&
                            s['day'] == targetItem['day'] &&
                            s['title'] == targetItem['title']);
                      }
                      if (idx != -1) _globalSchedules.removeAt(idx);
                    }
                  });
                  Navigator.of(dialogContext).pop();
                },
                child: Text('DELETE / 삭제', style: GoogleFonts.notoSansKr(color: examColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text('CANCEL / 취소', style: GoogleFonts.notoSansKr(color: slate400, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () {
                String newTime = editTimeController.text.trim();
                String newTitle = editTitleController.text.trim();
                String newMemo = editMemoController.text.trim();
                if (newTitle.isEmpty) return;

                setState(() {
                  if (isFixedTimelineType) {
                    _fixedDayTimelines[index]['time'] = newTime.isEmpty ? _fixedDayTimelines[index]['time'] : newTime;
                    _fixedDayTimelines[index]['title'] = newTitle;
                    _fixedDayTimelines[index]['memo'] = newMemo;
                  } else if (isWeeklyType) {
                    int idx = _globalSchedules.indexWhere((s) => s['week_key'] == targetItem['week_key']);
                    if (idx != -1) {
                      _globalSchedules[idx]['time'] = newTime.isEmpty ? '종일' : newTime;
                      _globalSchedules[idx]['title'] = newTitle;
                      _globalSchedules[idx]['memo'] = newMemo;
                    } else {
                      _globalSchedules.add({
                        'week_key': targetItem['week_key'],
                        'title': newTitle,
                        'memo': newMemo,
                        'time': newTime.isEmpty ? '종일' : newTime,
                        'color': goldColor,
                        'is_weekly': true,
                      });
                    }
                  } else {
                    int idx = _globalSchedules.indexOf(targetItem);
                    if (idx == -1) {
                      idx = _globalSchedules.indexWhere((s) =>
                      s['year'] == targetItem['year'] &&
                          s['month'] == targetItem['month'] &&
                          s['day'] == targetItem['day'] &&
                          s['title'] == targetItem['title']);
                    }
                    if (idx != -1) {
                      _globalSchedules[idx]['time'] = newTime.isEmpty ? '종일' : newTime;
                      _globalSchedules[idx]['title'] = newTitle;
                      _globalSchedules[idx]['memo'] = newMemo;
                      _sortGlobalSchedules();
                    }
                  }
                });

                Navigator.of(dialogContext).pop();
              },
              child: Text('SAVE / 저장', style: GoogleFonts.notoSansKr(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  /// ============================================================================
  /// [주석] 정밀 UI 컴포넌트 팩토리 가독성 확보 메서드군
  /// ============================================================================
  Widget _buildDynamicSectionHeader(String eng, String kor, VoidCallback onAddTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: goldColor, width: 1.5),
              color: goldColor.withValues(alpha: 0.08),
            ),
            child: Icon(Icons.add, color: goldColor, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildYearChecklistItem(String title, bool isChecked, int index, String yearKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _yearlyTargetsMap[yearKey]![index]['done'] = !isChecked;
              });
            },
            child: Icon(
              isChecked ? Icons.check_box : Icons.check_box_outline_blank,
              color: isChecked ? goldColor : slate500,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                color: isChecked ? slate400 : Colors.white,
                decoration: isChecked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _yearlyTargetsMap[yearKey]!.removeAt(index);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
              child: Icon(Icons.cancel, color: Colors.white.withValues(alpha: 0.25), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTimelineItem(String timeLabel, String eventTitle, Color leftBarColor, int index, String memo) {
    return GestureDetector(
      onTap: () {
        if (index >= 0 && index < _globalSchedules.length) {
          _showEditDeletePopup(_globalSchedules[index]);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF020617),
          border: Border(left: BorderSide(color: leftBarColor, width: 4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(timeLabel, style: GoogleFonts.notoSerif(fontSize: 12, color: goldColor)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Text(
                  eventTitle,
                  style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (index >= 0 && index < _globalSchedules.length) {
                    _globalSchedules.removeAt(index);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
                child: Icon(Icons.cancel, color: Colors.white.withValues(alpha: 0.25), size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ============================================================================
  /// [주석] 입력창 자판 가림 방지 및 일정/목표 추가 연동 바텀 시트
  /// ============================================================================
  void _showAddScheduleBottomSheet(BuildContext context, String initialType) {
    String entryType = initialType;
    String selectedCategory = '학교';

    final TextEditingController titleController = TextEditingController();
    final TextEditingController monthController = TextEditingController();
    final TextEditingController dayController = TextEditingController();
    final TextEditingController memoController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF020617),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (BuildContext bc) {
        return StatefulBuilder(
          builder: (BuildContext modalContext, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 20.0,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ADD NEW ENTRY', style: GoogleFonts.notoSerif(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold)),
                    Text('새 리스트 추가하기', style: GoogleFonts.notoSansKr(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                    const Divider(color: Color(0xFF1E293B), height: 20),
                    Row(
                      children: ['일정', '목표'].map((type) {
                        return Row(
                          children: [
                            Radio<String>(
                              value: type,
                              groupValue: entryType,
                              activeColor: goldColor,
                              onChanged: (value) {
                                setModalState(() { entryType = value!; });
                              },
                            ),
                            Text(type, style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white)),
                            const SizedBox(width: 20),
                          ],
                        );
                      }).toList(),
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 15),
                    if (entryType == '일정') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: ['학교', '학원', '시험', '개인'].map((cat) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: cat,
                                groupValue: selectedCategory,
                                activeColor: goldColor,
                                onChanged: (value) {
                                  setModalState(() { selectedCategory = value!; });
                                },
                              ),
                              Text(cat, style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white)),
                            ],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 15),
                    ],
                    TextField(
                      controller: titleController,
                      style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: entryType == '일정' ? 'TITLE / 일정 제목 입력' : 'TARGET / 목표 내용 입력',
                        hintStyle: GoogleFonts.notoSansKr(color: slate400, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                      ),
                    ),
                    if (entryType == '일정') ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: monthController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'MONTH / 월 숫자 (예: 4)',
                                hintStyle: GoogleFonts.notoSansKr(color: slate400, fontSize: 12),
                                filled: true,
                                fillColor: const Color(0xFF0F172A),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: dayController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'DAY / 일 숫자 (예: 15)',
                                hintStyle: GoogleFonts.notoSansKr(color: slate400, fontSize: 12),
                                filled: true,
                                fillColor: const Color(0xFF0F172A),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: memoController,
                      maxLines: 2,
                      style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'MEMO / 상세 학습 계획 및 연동 메모 기입',
                        hintStyle: GoogleFonts.notoSansKr(color: slate400, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: goldColor),
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) return;

                          if (entryType == '목표') {
                            String currentYearKey = _scrollableYears[_selectedYearIndex];
                            setState(() {
                              _yearlyTargetsMap[currentYearKey]!.add({
                                'title': titleController.text.trim(),
                                'done': false,
                              });
                            });
                          } else {
                            Color sColor = schoolColor;
                            if (selectedCategory == '학원') sColor = academyColor;
                            if (selectedCategory == '시험') sColor = examColor;
                            if (selectedCategory == '개인') sColor = personalColor;

                            int inputMonth = int.tryParse(monthController.text.trim()) ?? 7;
                            int inputDay = int.tryParse(dayController.text.trim()) ?? 1;

                            setState(() {
                              _globalSchedules.add({
                                'year': 2026,
                                'month': inputMonth,
                                'day': inputDay,
                                'time': '종일',
                                'title': titleController.text.trim(),
                                'color': sColor,
                                'memo': memoController.text.trim().isEmpty ? '상세 계획 수립 완료' : memoController.text.trim(),
                              });

                              _sortGlobalSchedules();
                              _selectedDayDate = DateTime(2026, inputMonth, inputDay);
                            });
                          }

                          Navigator.pop(modalContext);
                        },
                        child: Text(
                          'SAVE AND APPLY / 저장 및 연동 적용하기',
                          style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF020617), fontWeight: FontWeight.bold),
                        ),
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