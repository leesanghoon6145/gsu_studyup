import 'dart:convert'; // [주석] 마스터 데이터 JSON 직렬화 및 역직렬화를 위한 패키지 임포트
import 'package:flutter/material.dart';
// [주석] 구글 폰트 패키지 임포트
import 'package:google_fonts/google_fonts.dart';
// [주석] 사용자의 마지막 제어 상태 및 마스터 데이터를 기기 내부에 영구 보존하기 위한 shared_preferences 임포트
import 'package:shared_preferences/shared_preferences.dart';

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
  // [주석] 글로벌 마스터 데이터 센터: 달력과 4대 탭이 완벽하게 실시간 공유 연동됨
  // ============================================================================
  late Map<String, List<Map<String, dynamic>>> _yearlyTargetsMap;
  late List<Map<String, dynamic>> _globalSchedules;

  // [주석] 일간 날짜별 정밀 고정 타임라인 관리 데이터 센터
  late List<Map<String, dynamic>> _fixedDayTimelines;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // [주석] 시스템 실시간 오늘 날짜 감지 및 자동 매핑 로직 (달력 연동 핵심 기술)
    final DateTime today = DateTime.now();
    _selectedDayDate = DateTime(today.year, today.month, today.day);

    // 현재 실제 연도가 리스트 범위 내에 있는 경우 동적으로 해당 인덱스 자동 매핑
    final String currentYearStr = '${today.year}년';
    final int matchedYearIdx = _scrollableYears.indexOf(currentYearStr);
    _selectedYearIndex = matchedYearIdx != -1 ? matchedYearIdx : 0;

    // 현재 실제 월을 완벽하게 인식하여 기본 월간 가로 레인 인덱스 자동 지정 (0~11)
    _selectedMonthIndex = today.month - 1;

    // [주석] 탭 전환이 완전히 종료되었을 때, 탭 상태값을 영구 보존하기 위한 리스너 탑재
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _saveState();
      }
    });

    _yearlyTargetsMap = {
      '2026년': [
        {'title': '2026 민사고 합격 독점 스케줄', 'done': true},
        {'title': '2026 수학 내신 1등급 완성', 'done': false},
        {'title': '2026 영어 수능 최저학력기준 충족', 'done': false},
      ],
      '2027년': [
        {'title': '2027 고등 전과목 심화 마스터', 'done': false},
      ],
      '2028년': [], '2029년': [], '2030년': [],
    };

    _globalSchedules = [
      {
        'year': 2026, 'month': 7, 'day': 1, 'time': '08:00',
        'title': '고등학교 학업 평가단 입과 수행', 'color': schoolColor, 'memo': '새로운 고등 학업의 시작점 세팅',
      },
      {
        'year': 2026, 'month': 7, 'day': 1, 'time': '16:00',
        'title': '대성학원 대입 종합 윈터클리닉 연동', 'color': academyColor, 'memo': '심화 연동 마스터 코스 배정 완료',
      },
      {
        'year': 2026, 'month': 7, 'day': 1, 'time': '21:00',
        'title': '전국 연합 모의고사 오답 백서 검증', 'color': examColor, 'memo': '오답노트 완벽 정리 및 취약 영역 분석',
      },
      {
        'year': 2026, 'month': 7, 'day': 1, 'time': '22:30',
        'title': '개인 플래너 별 누적 리프레시', 'color': personalColor, 'memo': '대시보드 별 누적 시스템 가동',
      },
      {
        'year': 2026, 'month': 7, 'day': 15, 'time': '09:00',
        'title': '기말고사 1일차 통합 평가 수행', 'color': examColor, 'memo': '전과목 만점 목표 진입',
      },
    ];

    _fixedDayTimelines = [
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
    ];

    _sortGlobalSchedules();

    // [주석] 데이터 로딩 순서 정밀 제어: 마스터 데이터를 먼저 복원한 뒤, 이어서 제어 인덱스 값을 최종 갱신
    _initStorageAndLoad();
  }

  /// ============================================================================
  /// [주석] SharedPreferences 영구 저장 및 동적 복원 메소드 모듈 (베테랑의 기술)
  /// ============================================================================

  /// [주석] 저장소 초기화 및 순차 복원을 동시 비동기 실행하는 모듈
  Future<void> _initStorageAndLoad() async {
    await _loadMasterData();
    await _loadSavedState();
  }

  /// [주석] 현재 사용자가 선택하고 제어 중인 인덱스 및 토글 상태를 영구 저장소에 저장
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 주요 탭 및 리스트 제어 인덱스 저장
      await prefs.setInt('gke_tab_index', _tabController.index);
      await prefs.setInt('gke_selected_year_index', _selectedYearIndex);
      await prefs.setInt('gke_selected_month_index', _selectedMonthIndex);
      await prefs.setInt('gke_selected_week_index', _selectedWeekIndex);

      // 일간 탭의 정밀 캘린더 일자 날짜 저장 (ISO 8601 표준 포맷 대응)
      await prefs.setString('gke_selected_day_date', _selectedDayDate.toIso8601String());

      // 이원화 선택 스위치 및 가시성, 확장 상태 영구 보존
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

  /// [주석] 기기 저장소로부터 상태 정보를 완벽히 읽어와 실시간 UI에 강제 맵핑
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
        if (savedTabIndex != null) {
          _tabController.index = savedTabIndex;
        }
        if (savedYearIndex != null && savedYearIndex < _scrollableYears.length) {
          _selectedYearIndex = savedYearIndex;
        }
        if (savedMonthIndex != null && savedMonthIndex < 12) {
          _selectedMonthIndex = savedMonthIndex;
        }
        if (savedWeekIndex != null && savedWeekIndex < _scrollableWeeks.length) {
          _selectedWeekIndex = savedWeekIndex;
        }
        if (savedDayDateStr != null) {
          _selectedDayDate = DateTime.parse(savedDayDateStr);
        }

        if (savedYearTargetSel != null) _isYearTargetSelected = savedYearTargetSel;
        if (savedMonthTargetSel != null) _isMonthTargetSelected = savedMonthTargetSel;
        if (savedWeekTimelineSel != null) _isWeekTimelineSelected = savedWeekTimelineSel;
        if (savedTimeViewSel != null) _isTimeViewSelected = savedTimeViewSel;
        if (savedYearTargetExp != null) _isYearTargetExpanded = savedYearTargetExp;
        if (savedDayCalendarVis != null) _isDayCalendarVisible = savedDayCalendarVis;
      });
    } catch (e) {
      debugPrint('[GKE StudyUp] Error loading configuration state: $e');
    }
  }

  /// [주석] 인메모리에서 일시적으로 관리되는 마스터 데이터(추가된 일정, 체크박스 달성도, 스타 획득여부 등)를 JSON화 하여 영구 로드 보관
  Future<void> _saveMasterData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. 연간 세부 체크리스트 인포맵 직렬화 저장
      final String yearlyTargetsJson = jsonEncode(_yearlyTargetsMap);
      await prefs.setString('gke_yearly_targets_map', yearlyTargetsJson);

      // 2. 글로벌 일정 정보 직렬화 저장 (Color 구조는 .value 정수값으로 치환 가공)
      final List<Map<String, dynamic>> serializableSchedules = _globalSchedules.map((item) {
        final Map<String, dynamic> copy = Map.from(item);
        if (copy['color'] is Color) {
          copy['color'] = (copy['color'] as Color).value;
        }
        return copy;
      }).toList();
      await prefs.setString('gke_global_schedules', jsonEncode(serializableSchedules));

      // 3. 일간 타임 루틴 데이터 직렬화 저장 (별 획득 수집 상태 추적용)
      await prefs.setString('gke_fixed_day_timelines', jsonEncode(_fixedDayTimelines));

    } catch (e) {
      debugPrint('[GKE StudyUp] Error serializing master data: $e');
    }
  }

  /// [주석] 영구 보존된 JSON 포맷을 디코딩하여 메모리 테이블에 재주입 역직렬화 트래킹
  Future<void> _loadMasterData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. 연간 목표 맵 데이터 복원
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

      // 2. 글로벌 주요 스케줄러 복원 (정수형 컬러값을 복구하여 다시 Color 인스턴스로 대입)
      final String? globalSchedulesJson = prefs.getString('gke_global_schedules');
      if (globalSchedulesJson != null) {
        final List<dynamic> decodedList = jsonDecode(globalSchedulesJson);
        setState(() {
          _globalSchedules = decodedList.map((item) {
            final Map<String, dynamic> map = Map<String, dynamic>.from(item as Map);
            if (map['color'] is int) {
              map['color'] = Color(map['color'] as int);
            }
            return map;
          }).toList();
          _sortGlobalSchedules();
        });
      }

      // 3. 정밀 고정 타임라인 및 수집 완료한 상태값 복원
      final String? fixedTimelinesJson = prefs.getString('gke_fixed_day_timelines');
      if (fixedTimelinesJson != null) {
        final List<dynamic> decodedList = jsonDecode(fixedTimelinesJson);
        setState(() {
          _fixedDayTimelines = decodedList.map((item) {
            return Map<String, dynamic>.from(item as Map);
          }).toList();
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
  /// 📅 1. 연간 뷰 (YEAR VIEW) - 지시사항 2번 버그 완벽 수정 교정 완료
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
                  _saveState(); // [주석] 상태 변화 즉시 디스크 영구 동기화
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
                onTap: () {
                  setState(() { _isYearTargetSelected = true; });
                  _saveState(); // [주석] 상태 변화 즉시 디스크 영구 동기화
                },
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
                onTap: () {
                  setState(() { _isYearTargetSelected = false; });
                  _saveState(); // [주석] 상태 변화 즉시 디스크 영구 동기화
                },
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
              onExpansionChanged: (val) {
                setState(() { _isYearTargetExpanded = val; });
                _saveState(); // [주석] 상태 변화 즉시 디스크 영구 동기화
              },
              children: [
                if (currentTargets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Text('등록된 연간 목표 목표치가 없습니다.', style: GoogleFonts.notoSansKr(color: slate500, fontSize: 12)),
                  )
                else
                // [주석] 지시사항 2 완벽 타격 교정: 위젯 전체 묶음을 없애고 개별 함수 바인딩으로 간섭 원천 배제
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
              child: Center(
                child: Text('해당 연도에 편성된 주요 일정이 없습니다.', style: GoogleFonts.notoSansKr(color: slate500, fontSize: 12)),
              ),
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
                  _saveState(); // [주석] 상태 변화 즉시 디스크 영구 동기화
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
                onTap: () {
                  setState(() { _isMonthTargetSelected = true; });
                  _saveState(); // [주석] 상태 변화 즉시 디스크 영구 동기화
                },
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
                onTap: () {
                  setState(() { _isMonthTargetSelected = false; });
                  _saveState(); // [주석] 상태 변화 즉시 디스크 영구 동기화
                },
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
                  _saveState(); // [주석] 상태 변화 즉시 디스크 영구 동기화
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
                onTap: () {
                  setState(() { _isWeekTimelineSelected = true; });
                  _saveState(); // [주석] 상태 변화 즉시 디스크 영구 동기화
                },
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
                onTap: () {
                  setState(() { _isWeekTimelineSelected = false; });
                  _saveState(); // [주석] 상태 변화 즉시 디스크 영구 동기화
                },
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
          Text('$currentWeekLabel 요일별 학습 루틴 트랙 (상세보기 연동)', style: GoogleFonts.notoSansKr(fontSize: 12, color: slate400)),
          const SizedBox(height: 10),
          ...weekdays.map((day) {
            String uniqueScheduleKey = '${currentWeekLabel}_$day';
            Map<String, dynamic> weekSchedule = {
              'week_key': uniqueScheduleKey,
              'title': day == '월' ? '월요 영단어 1000개 심화 암기' : (day == '수' ? '수요 수학 고난도 문제집 단원 완성' : '$day요일 자기주도 학습 목표 도달 훈련'),
              'memo': '$day요일 진도 계획 준수 및 플래너 별 누적 리프레시 검증.',
              'time': '종일 고정',
              'color': goldColor,
              'is_weekly': true
            };

            return GestureDetector(
              onTap: () { _showUnifiedPopupTrack(weekSchedule, typeKey: 'WEEK'); },
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
  /// 📅 4. 일간 뷰 (DAY VIEW)
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

        GestureDetector(
          onTap: () {
            setState(() { _isDayCalendarVisible = !_isDayCalendarVisible; });
            _saveState(); // [주석] 상태 변화 즉시 디스크 영구 동기화
          },
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
                    // [주석] 지시사항 8 & 9조 완벽 대응: 캘린더 온오프 헤더의 영문-한글 상하배치 가공 트랙
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CALENDAR CONTROLLER', style: GoogleFonts.notoSerif(fontSize: 12, color: goldColor, fontWeight: FontWeight.bold)),
                        Text('달력 열기·닫기', style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
                      ],
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

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 7,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 2),
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

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalCalendarGridItemsCount,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.85
                  ),
                  itemBuilder: (context, index) {
                    int displayDayNum = 1;
                    bool isBlurred = false;

                    if (index < emptyPrefixCellsCount) {
                      displayDayNum = prevMonthTotalDays - (emptyPrefixCellsCount - index - 1);
                      isBlurred = true;
                    } else if (index >= (emptyPrefixCellsCount + totalDaysInMonth)) {
                      displayDayNum = index - (emptyPrefixCellsCount + totalDaysInMonth) + 1;
                      isBlurred = true;
                    } else {
                      displayDayNum = index - emptyPrefixCellsCount + 1;
                    }

                    bool hasSchool = false;
                    bool hasAcademy = false;
                    bool hasExam = false;
                    bool hasPersonal = false;
                    int dayScheduleCount = 0;

                    if (!isBlurred) {
                      var daySchedules = _globalSchedules.where((s) => s['year'] == _selectedDayDate.year && s['month'] == _selectedDayDate.month && s['day'] == displayDayNum);
                      dayScheduleCount = daySchedules.length;
                      for (var s in daySchedules) {
                        if (s['color'] == schoolColor) hasSchool = true;
                        if (s['color'] == academyColor) hasAcademy = true;
                        if (s['color'] == examColor) hasExam = true;
                        if (s['color'] == personalColor) hasPersonal = true;
                      }
                    }

                    bool isSelected = !isBlurred && _selectedDayDate.day == displayDayNum;

                    return GestureDetector(
                      onTap: () {
                        if (isBlurred) return;
                        setState(() {
                          _selectedDayDate = DateTime(_selectedDayDate.year, _selectedDayDate.month, displayDayNum);
                        });
                        _saveState(); // [주석] 사용자가 다른 날짜를 선택할 때마다 실시간 영구 자동저장 수행
                        _showCalendarDaySchedulesPopup(displayDayNum);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected ? goldColor.withValues(alpha: 0.15) : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isSelected ? goldColor : slate800, width: isSelected ? 1.5 : 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$displayDayNum',
                              style: GoogleFonts.notoSerif(
                                  fontSize: 11, color: isBlurred ? slate500 : (isSelected ? goldColor : Colors.white), fontWeight: FontWeight.bold
                              ),
                            ),
                            if (!isBlurred)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (hasSchool) Container(width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1), color: schoolColor),
                                  if (hasAcademy) Container(width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1), color: academyColor),
                                  if (hasExam) Container(width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1), color: examColor),
                                  if (hasPersonal) Container(width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1), color: personalColor),
                                ],
                              )
                            else
                              const SizedBox(height: 5),

                            if (!isBlurred && dayScheduleCount > 0)
                              Text(
                                '$dayScheduleCount개',
                                style: GoogleFonts.notoSansKr(fontSize: 9, color: goldColor, fontWeight: FontWeight.bold),
                              )
                            else
                              const SizedBox(height: 10),
                          ],
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

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() { _isTimeViewSelected = true; });
                  _saveState(); // [주석] 상태 변화 즉시 디스크 영구 동기화
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
                      Text('학습 타임라인', style: GoogleFonts.notoSansKr(fontSize: 12, color: _isTimeViewSelected ? Colors.white : slate500, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() { _isTimeViewSelected = false; });
                  _saveState(); // [주석] 상태 변화 즉시 디스크 영구 동기화
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

        if (_isTimeViewSelected) ...[
          ..._fixedDayTimelines.asMap().entries.map((entry) {
            final timelineItem = entry.value;
            return GestureDetector(
              onTap: () { _showUnifiedPopupTrack(timelineItem, typeKey: 'DAY_TIME', index: entry.key); },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(8), border: Border.all(color: slate800)),
                child: Row(
                  children: [
                    Text(timelineItem['time'], style: GoogleFonts.notoSerif(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Row(
                        children: [
                          Text(timelineItem['title'], style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                          if (timelineItem['is_starred'] == true) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.star, color: goldColor, size: 14),
                          ]
                        ],
                      ),
                    ),
                    Icon(Icons.remove_red_eye, color: slate500, size: 14),
                  ],
                ),
              ),
            );
          }).toList(),
        ] else ...[
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
              Color squareColor = schoolColor;

              if (item['color'] == academyColor) { categoryLabel = '[학원]'; squareColor = academyColor; }
              else if (item['color'] == examColor) { categoryLabel = '[시험]'; squareColor = examColor; }
              else if (item['color'] == personalColor) { categoryLabel = '[개인]'; squareColor = personalColor; }

              return GestureDetector(
                onTap: () { _showUnifiedPopupTrack(item, typeKey: 'DAY_MAIN'); },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF020617), border: Border.all(color: squareColor.withValues(alpha: 0.3))),
                  child: Row(
                    children: [
                      Text('■ ', style: TextStyle(color: squareColor, fontSize: 26, fontWeight: FontWeight.bold)),
                      Text('$categoryLabel ', style: GoogleFonts.notoSansKr(color: squareColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('${item['time']} - ${item['title']}', style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      ),
                      Icon(Icons.remove_red_eye, color: goldColor.withValues(alpha: 0.7), size: 18),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
        const SizedBox(height: 10),
      ],
    );
  }

  /// ============================================================================
  /// 📅 [달력 연동] 1단계: 깔끔한 주요 일정 목록 브리핑 보기 팝업
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
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Color(0xFF1E293B), height: 10),
                      const SizedBox(height: 8),

                      if (targetSchedules.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: Text('해당 날짜에 등록된 주요 일정이 없습니다.', style: GoogleFonts.notoSansKr(fontSize: 12, color: slate500)),
                          ),
                        )
                      else
                        ...targetSchedules.map((item) {
                          String catStr = '[학교]';
                          if (item['color'] == academyColor) catStr = '[학원]';
                          if (item['color'] == examColor) catStr = '[시험]';
                          if (item['color'] == personalColor) catStr = '[개인]';

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: item['color'].withValues(alpha: 0.4), width: 1),
                            ),
                            child: Row(
                              children: [
                                Text('■ ', style: TextStyle(color: item['color'], fontSize: 16)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('$catStr ${item['title']}', style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                                      if ((item['memo'] ?? '').toString().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2.0),
                                          child: Text(item['memo'], style: GoogleFonts.notoSansKr(fontSize: 11, color: slate400)),
                                        ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.of(dialogContext).pop();
                                    _showActualEditorPopup(item, typeKey: 'DAY_MAIN');
                                  },
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
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _showCalendarQuickAddPopup(dayNum);
                      },
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
  /// 🎯 [지시사항 1번 완벽 수정] 2단계: 자판이 터지던 오버플로우 에러를 스크롤로 완벽 무력화 교정 완료
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
              // [주석] 핵심 패치: 최외곽을 SingleChildScrollView로 전격 감싸 하단 상세내용 기입 칸 오버플로우 에러 원천 해결
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                value: cat,
                                groupValue: tempCategory,
                                activeColor: goldColor,
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
                        controller: quickTitleController,
                        style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: '간단한 일정 제목을 입력하세요',
                          hintStyle: GoogleFonts.notoSansKr(color: slate500, fontSize: 12),
                          filled: true, fillColor: const Color(0xFF0F172A),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text('MEMO / 상세 내용', style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: quickMemoController,
                        maxLines: 2,
                        style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: '상세 일정 내용(메모)을 입력하세요',
                          hintStyle: GoogleFonts.notoSansKr(color: slate500, fontSize: 12),
                          filled: true, fillColor: const Color(0xFF0F172A),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
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
                            'year': _selectedDayDate.year,
                            'month': _selectedDayDate.month,
                            'day': dayNum,
                            'time': '12:00',
                            'title': quickTitleController.text.trim(),
                            'color': choiceColor,
                            'memo': quickMemoController.text.trim(),
                          });
                          _sortGlobalSchedules();
                        });

                        _saveMasterData(); // [주석] 신규 일정을 마스터 스케줄 저장소에 반영구 저장

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
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            _saveMasterData(); // [주석] 획득한 별 수집 상태를 즉각 데이터베이스 디스크 파일에 영구 매핑
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
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _showActualEditorPopup(targetItem, typeKey: typeKey, index: index);
                      },
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
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TIME', style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                    TextField(
                      controller: editTimeController,
                      style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'TIME / 시간 입력', hintStyle: GoogleFonts.notoSansKr(color: slate400, fontSize: 12),
                        filled: true, fillColor: const Color(0xFF0F172A),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('SUBJECT OR TITLE', style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                    TextField(
                      controller: editTitleController,
                      style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'TITLE / 제목 입력', hintStyle: GoogleFonts.notoSansKr(color: slate400, fontSize: 12),
                        filled: true, fillColor: const Color(0xFF0F172A),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
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
                          controller: bookInputController,
                          style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: '예) "블랙라벨"', hintStyle: GoogleFonts.notoSansKr(color: slate500, fontSize: 12),
                            filled: true, fillColor: const Color(0xFF0F172A),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],

                    Text('MEMO / DETAILS', style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                    TextField(
                      controller: editMemoController, maxLines: 2,
                      style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'MEMO / 상세 메모 입력', hintStyle: GoogleFonts.notoSansKr(color: slate400, fontSize: 12),
                        filled: true, fillColor: const Color(0xFF0F172A),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (typeKey != 'DAY_TIME')
                      TextButton(
                        onPressed: () {
                          setState(() { _globalSchedules.removeWhere((s) => s['title'] == targetItem['title'] && s['day'] == targetItem['day'] && s['month'] == targetItem['month']); });
                          _saveMasterData(); // [주석] 일정이 완전히 삭제된 최신 정보 리스트를 내부 저장소에 반영
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

                        _saveMasterData(); // [주석] 수정하여 재편성된 고정 시간표 및 세부 계획을 내부 저장소에 반영

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
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: goldColor, width: 1.5), color: goldColor.withValues(alpha: 0.08)),
            child: Icon(Icons.add, color: goldColor, size: 20),
          ),
        ),
      ],
    );
  }

  /// ============================================================================
  /// 🎯 [지시사항 2번 완벽 수정] 연간 체크박스 컴포넌트 독립 분리 구축 완료
  /// ============================================================================
  Widget _buildYearChecklistItem(String title, bool isChecked, int index, String yearKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // [체크박스 아이콘 독립 클릭 감지기] -> 부근 간섭을 없애고 오직 토글 기능만 정확히 수행함
          GestureDetector(
            onTap: () {
              setState(() {
                _yearlyTargetsMap[yearKey]![index]['done'] = !isChecked;
              });
              _saveMasterData(); // [주석] 체크 목표 목록 달성 상태를 저장소에 즉각 업데이트
            },
            child: Container(
              padding: const EdgeInsets.all(4.0),
              color: Colors.transparent, // 터치 인식 영역 확보
              child: Icon(
                  isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isChecked ? goldColor : slate500,
                  size: 20
              ),
            ),
          ),
          const SizedBox(width: 8),

          // [글자 명칭 내용 독립 클릭 감지기] -> 텍스트 문구 부근을 터치할 때만 웅장하고 깔끔한 상세보기 팝업창을 띄워줌
          Expanded(
            child: GestureDetector(
              onTap: () {
                _showUnifiedPopupTrack({
                  'time': '$yearKey 전반 마스터 리전',
                  'title': title,
                  'memo': '국내 및 글로벌 상용화 목표 달성을 위한 연간 전개 스케줄 목표치입니다.',
                  'done': isChecked,
                }, typeKey: 'YEAR');
              },
              child: Container(
                color: Colors.transparent, // 터치 인식 영역 전체 확장
                alignment: Alignment.centerLeft,
                child: Text(
                    title,
                    style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        color: isChecked ? slate400 : Colors.white,
                        decoration: isChecked ? TextDecoration.lineThrough : null
                    )
                ),
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
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
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
    String entryType = initialType;
    String selectedCategory = '학교';
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
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            _saveMasterData(); // [주석] 신규 연간 체크박스 목표 리스트를 로컬 디스크로 백업
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

                            _saveState(); // [주석] 새로 설정한 날짜 포지션을 기억 저장
                            _saveMasterData(); // [주석] 생성한 글로벌 일정을 디바이스 내부에 반영구 저장
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