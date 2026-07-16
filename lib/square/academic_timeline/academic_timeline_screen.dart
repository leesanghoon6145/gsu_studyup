import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// [중요] 상대 경로로 안전하게 import 합니다.
// 현재 위치(academic_timeline/)에서 상위 상위 상위로 가서 planner/widgets를 찾는 구조입니다.
import '../../planner/widgets/study_timelines.dart';

class AcademicTimelineScreen extends StatefulWidget {
  const AcademicTimelineScreen({super.key});

  @override
  State<AcademicTimelineScreen> createState() => _AcademicTimelineScreenState();
}

class _AcademicTimelineScreenState extends State<AcademicTimelineScreen> {
  // ============================================================
  // 색상 및 폰트 테마 (기존 앱과 통일)
  // ============================================================
  final Color goldColor = const Color(0xFFD4AF37);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color slate500 = const Color(0xFF64748B);
  final Color slate800 = const Color(0xFF1E293B);

  // ============================================================
  // 상단 트랙 선택 상태
  // ============================================================
  String _selectedTrack = 'NORMAL_PERIOD';

  // ------------------------------------------------------------
  // 1. 평상시(NORMAL_PERIOD) 관련: 요일 선택 (오늘 날짜 기준 자동 연동)
  // ------------------------------------------------------------
  String _selectedWeekdayEn = 'Monday';
  final List<Map<String, String>> _weekdayOptions = [
    {'en': 'Monday', 'ko': '월'},
    {'en': 'Tuesday', 'ko': '화'},
    {'en': 'Wednesday', 'ko': '수'},
    {'en': 'Thursday', 'ko': '목'},
    {'en': 'Friday', 'ko': '금'},
    {'en': 'Saturday', 'ko': '토'},
    {'en': 'Sunday', 'ko': '일'},
  ];

  // ------------------------------------------------------------
  // 2. 방학(VACATION_SUMMER_WINTER) 관련
  // ------------------------------------------------------------
  DateTime? _vacationStartDate;
  DateTime? _vacationEndDate;
  String? _selectedPomodoroKey; // 'vacationPomodoro1' ~ 'vacationPomodoro4'
  bool _isPomodoroFreeModeEnabled = false;

  // ------------------------------------------------------------
  // 3 & 4. 시험(EXAM_PREP_PERIOD / EXAM_DAY_TRACK) 공통 관련
  // ------------------------------------------------------------
  bool _isFinalExamMode = false; // false = 중간고사, true = 기말고사
  DateTime? _examStartDate; // 시험 시작일 (D-day)

  // ------------------------------------------------------------
  // 5. 타임라인 커스텀 수정/삭제/리셋 상태 관리용 메모리 캐시
  // ------------------------------------------------------------
  final Map<String, List<Map<String, String>>> _customSchedules = {};

  @override
  void initState() {
    super.initState();
    _initAutoWeekday();
    _loadAllSettings();
  }

  // 오늘 날짜에 맞춰 평상시 요일 자동 설정
  void _initAutoWeekday() {
    final int weekdayNum = DateTime.now().weekday; // 1(월) ~ 7(일)
    const weekdayMap = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
    _selectedWeekdayEn = weekdayMap[weekdayNum] ?? 'Monday';
  }

  // ============================================================
  // 설정 저장 / 불러오기
  // ============================================================
  Future<void> _loadAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? vacStart = prefs.getString('gke_vacation_start_date');
    final String? vacEnd = prefs.getString('gke_vacation_end_date');
    final String? pomodoroKey = prefs.getString('gke_selected_pomodoro_key');
    final bool freeMode = prefs.getBool('gke_pomodoro_free_mode') ?? false;
    final String? examType = prefs.getString('gke_selected_exam_type');
    final String? examStartStr = prefs.getString('gke_exam_start_date');

    if (mounted) {
      setState(() {
        _vacationStartDate = vacStart != null ? DateTime.parse(vacStart) : null;
        _vacationEndDate = vacEnd != null ? DateTime.parse(vacEnd) : null;
        _selectedPomodoroKey = pomodoroKey;
        _isPomodoroFreeModeEnabled = freeMode;
        _isFinalExamMode = (examType == '기말고사');
        _examStartDate = examStartStr != null ? DateTime.parse(examStartStr) : null;
      });
    }
  }

  Future<void> _saveVacationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (_vacationStartDate != null) {
      await prefs.setString('gke_vacation_start_date', _vacationStartDate!.toIso8601String());
    } else {
      await prefs.remove('gke_vacation_start_date');
    }
    if (_vacationEndDate != null) {
      await prefs.setString('gke_vacation_end_date', _vacationEndDate!.toIso8601String());
    } else {
      await prefs.remove('gke_vacation_end_date');
    }
    if (_selectedPomodoroKey != null) {
      await prefs.setString('gke_selected_pomodoro_key', _selectedPomodoroKey!);
    } else {
      await prefs.remove('gke_selected_pomodoro_key');
    }
    await prefs.setBool('gke_pomodoro_free_mode', _isPomodoroFreeModeEnabled);
  }

  Future<void> _saveExamSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gke_selected_exam_type', _isFinalExamMode ? '기말고사' : '중간고사');
    if (_examStartDate != null) {
      await prefs.setString('gke_exam_start_date', _examStartDate!.toIso8601String());
    } else {
      await prefs.remove('gke_exam_start_date');
    }
  }

  // ============================================================
  // 데이터 매핑 및 커스텀 스케줄 관리 헬퍼
  // ============================================================
  List<Map<String, String>> _getCurrentActiveSchedule() {
    String cacheKey = '';
    List<Map<String, String>> defaultList = [];

    if (_selectedTrack == 'NORMAL_PERIOD') {
      cacheKey = 'NORMAL_PERIOD_$_selectedWeekdayEn';
      defaultList = StudyTimelines.normalPeriod[_selectedWeekdayEn] ?? [];
    } else if (_selectedTrack == 'VACATION_SUMMER_WINTER') {
      cacheKey = 'VACATION_${_selectedPomodoroKey ?? 'none'}';
      defaultList = _selectedPomodoroKey != null ? _getPomodoroListByKey(_selectedPomodoroKey!) : [];
    } else if (_selectedTrack == 'EXAM_PREP_PERIOD') {
      final int weekNum = _calcExamPrepWeekNum();
      final String dayType = _calcExamPrepDayType(weekNum);
      cacheKey = 'EXAM_PREP_${_isFinalExamMode ? "final" : "mid"}_w${weekNum}_$dayType';
      defaultList = weekNum > 0 ? _getExamPrepList(weekNum, dayType, _isFinalExamMode) : [];
    } else if (_selectedTrack == 'EXAM_DAY_TRACK') {
      final DateTime today = DateTime.now();
      final DateTime cleanToday = DateTime(today.year, today.month, today.day);
      final DateTime cleanExamStart = _examStartDate != null
          ? DateTime(_examStartDate!.year, _examStartDate!.month, _examStartDate!.day)
          : cleanToday;
      final int diff = cleanToday.difference(cleanExamStart).inDays;
      cacheKey = 'EXAM_DAY_${_isFinalExamMode ? "final" : "mid"}_diff_$diff';

      if (_examStartDate != null && diff >= -3 && diff <= 4) {
        defaultList = StudyTimelines.getTimelineForDate(
          cleanToday,
          cleanExamStart,
          isExamPeriod: true,
          isActualExamWeek: true,
          isFinalExam: _isFinalExamMode,
        );
      } else {
        defaultList = [];
      }
    }

    if (_customSchedules.containsKey(cacheKey)) {
      return _customSchedules[cacheKey]!;
    }
    return defaultList;
  }

  String _getCurrentCacheKey() {
    if (_selectedTrack == 'NORMAL_PERIOD') {
      return 'NORMAL_PERIOD_$_selectedWeekdayEn';
    } else if (_selectedTrack == 'VACATION_SUMMER_WINTER') {
      return 'VACATION_${_selectedPomodoroKey ?? 'none'}';
    } else if (_selectedTrack == 'EXAM_PREP_PERIOD') {
      final int weekNum = _calcExamPrepWeekNum();
      final String dayType = _calcExamPrepDayType(weekNum);
      return 'EXAM_PREP_${_isFinalExamMode ? "final" : "mid"}_w${weekNum}_$dayType';
    } else {
      final DateTime today = DateTime.now();
      final DateTime cleanToday = DateTime(today.year, today.month, today.day);
      final DateTime cleanExamStart = _examStartDate != null
          ? DateTime(_examStartDate!.year, _examStartDate!.month, _examStartDate!.day)
          : cleanToday;
      final int diff = cleanToday.difference(cleanExamStart).inDays;
      return 'EXAM_DAY_${_isFinalExamMode ? "final" : "mid"}_diff_$diff';
    }
  }

  int _calcExamPrepWeekNum() {
    if (_examStartDate == null) return 0;
    final DateTime today = DateTime.now();
    final DateTime cleanToday = DateTime(today.year, today.month, today.day);
    final DateTime cleanExamStart = DateTime(_examStartDate!.year, _examStartDate!.month, _examStartDate!.day);
    final int daysUntilExam = cleanExamStart.difference(cleanToday).inDays;
    if (daysUntilExam <= 0 || daysUntilExam > 28) return 0;
    return daysUntilExam > 21 ? 4 : (daysUntilExam > 14 ? 3 : (daysUntilExam > 7 ? 2 : 1));
  }

  String _calcExamPrepDayType(int weekNum) {
    if (_examStartDate == null) return 'weekday';
    final DateTime today = DateTime.now();
    final DateTime cleanToday = DateTime(today.year, today.month, today.day);
    if (weekNum == 1) {
      return cleanToday.weekday == 6 ? 'saturday' : (cleanToday.weekday == 7 ? 'sunday' : 'weekday');
    } else {
      return (cleanToday.weekday == 6 || cleanToday.weekday == 7) ? 'weekend' : 'weekday';
    }
  }

  List<Map<String, String>> _getPomodoroListByKey(String key) {
    switch (key) {
      case 'vacationPomodoro1':
        return StudyTimelines.vacationPomodoro1;
      case 'vacationPomodoro2':
        return StudyTimelines.vacationPomodoro2;
      case 'vacationPomodoro3':
        return StudyTimelines.vacationPomodoro3;
      case 'vacationPomodoro4':
        return StudyTimelines.vacationPomodoro4;
      default:
        return [];
    }
  }

  String _getPomodoroDisplayName(String key) {
    switch (key) {
      case 'vacationPomodoro1':
        return '스타일 1 (초집중 25분형)';
      case 'vacationPomodoro2':
        return '스타일 2 (집중 40분형)';
      case 'vacationPomodoro3':
        return '스타일 3 (과목별 45분형)';
      case 'vacationPomodoro4':
        return '스타일 4 (집중 60분형)';
      default:
        return '미선택';
    }
  }

  List<Map<String, String>> _getExamPrepList(int weekNum, String dayType, bool isFinal) {
    if (!isFinal) {
      switch (weekNum) {
        case 4:
          return dayType == 'weekday' ? StudyTimelinesExamPrepMid.midTermWeek4Weekday : StudyTimelinesExamPrepMid.midTermWeek4Weekend;
        case 3:
          return dayType == 'weekday' ? StudyTimelinesExamPrepMid.midTermWeek3Weekday : StudyTimelinesExamPrepMid.midTermWeek3Weekend;
        case 2:
          return dayType == 'weekday' ? StudyTimelinesExamPrepMid.midTermWeek2Weekday : StudyTimelinesExamPrepMid.midTermWeek2Weekend;
        default:
          if (dayType == 'weekday') return StudyTimelinesExamPrepMid.midTermWeek1Weekday;
          if (dayType == 'saturday') return StudyTimelinesExamPrepMid.midTermWeek1Saturday;
          return StudyTimelinesExamPrepMid.midTermWeek1Sunday;
      }
    } else {
      switch (weekNum) {
        case 4:
          return dayType == 'weekday' ? StudyTimelinesExamPrepFinal.finalTermWeek4Weekday : StudyTimelinesExamPrepFinal.finalTermWeek4Weekend;
        case 3:
          return dayType == 'weekday' ? StudyTimelinesExamPrepFinal.finalTermWeek3Weekday : StudyTimelinesExamPrepFinal.finalTermWeek3Weekend;
        case 2:
          return dayType == 'weekday' ? StudyTimelinesExamPrepFinal.finalTermWeek2Weekday : StudyTimelinesExamPrepFinal.finalTermWeek2Weekend;
        default:
          if (dayType == 'weekday') return StudyTimelinesExamPrepFinal.finalTermWeek1Weekday;
          if (dayType == 'saturday') return StudyTimelinesExamPrepFinal.finalTermWeek1Saturday;
          return StudyTimelinesExamPrepFinal.finalTermWeek1Sunday;
      }
    }
  }

  // ============================================================
  // 시간 경과 체크 함수 (현재 시간 기준 완료 여부 판단)
  // ============================================================
  bool _isTimePassed(String timeStr) {
    try {
      final parts = timeStr.split(RegExp(r'[-~–]'));
      if (parts.isNotEmpty) {
        final endTimeStr = parts.last.trim();
        final hm = endTimeStr.split(':');
        if (hm.length >= 2) {
          final int endHour = int.parse(hm[0]);
          final int endMinute = int.parse(hm[1]);

          final now = DateTime.now();
          final targetTime = DateTime(now.year, now.month, now.day, endHour, endMinute);

          return now.isAfter(targetTime);
        }
      }
    } catch (_) {}
    return false;
  }

  // ============================================================
  // 팝업 기반 수정 / 삭제 / 원본 리셋 처리 함수
  // ============================================================
  void _showEditItemDialog({int? index, String? initialTime, String? initialTask}) {
    final TextEditingController timeController = TextEditingController(text: initialTime ?? '');
    final TextEditingController taskController = TextEditingController(text: initialTask ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            index == null ? '타임라인 항목 추가' : '타임라인 항목 수정 / 삭제',
            style: GoogleFonts.notoSansKr(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: timeController,
                style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: '시간 (예: 09:00 - 10:00)',
                  labelStyle: GoogleFonts.notoSansKr(color: slate400, fontSize: 12),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: slate800)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: taskController,
                style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: '내용 (예: 수학 집중 학습)',
                  labelStyle: GoogleFonts.notoSansKr(color: slate400, fontSize: 12),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: slate800)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
                ),
              ),
            ],
          ),
          actions: [
            if (index != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    String cacheKey = _getCurrentCacheKey();
                    List<Map<String, String>> currentList = List.from(_getCurrentActiveSchedule());
                    currentList.removeAt(index);
                    _customSchedules[cacheKey] = currentList;
                  });
                  Navigator.pop(context);
                },
                child: Text('삭제', style: GoogleFonts.notoSansKr(color: Colors.redAccent, fontSize: 12)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소', style: GoogleFonts.notoSansKr(color: slate400, fontSize: 12)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: goldColor),
              onPressed: () {
                if (timeController.text.trim().isEmpty || taskController.text.trim().isEmpty) return;
                setState(() {
                  String cacheKey = _getCurrentCacheKey();
                  List<Map<String, String>> currentList = List.from(_getCurrentActiveSchedule());
                  if (index == null) {
                    currentList.add({'time': timeController.text.trim(), 'task': taskController.text.trim()});
                  } else {
                    currentList[index] = {'time': timeController.text.trim(), 'task': taskController.text.trim()};
                  }
                  _customSchedules[cacheKey] = currentList;
                });
                Navigator.pop(context);
              },
              child: Text('저장', style: GoogleFonts.notoSansKr(color: const Color(0xFF020617), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _resetToDefaultSchedule() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text('원본 리셋', style: GoogleFonts.notoSansKr(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold)),
          content: Text('현재 화면의 타임라인을 원본 기본 데이터로 초기화하시겠습니까?', style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소', style: GoogleFonts.notoSansKr(color: slate400, fontSize: 12)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: goldColor),
              onPressed: () {
                setState(() {
                  String cacheKey = _getCurrentCacheKey();
                  _customSchedules.remove(cacheKey);
                });
                Navigator.pop(context);
              },
              child: Text('리셋 확인', style: GoogleFonts.notoSansKr(color: const Color(0xFF020617), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // build
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        automaticallyImplyLeading: false, // 화살표 삭제
        toolbarHeight: 90,
        title: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/gsu_logo.png',
                width: 180,
                height: 28,
              ),
              const SizedBox(height: 0.5),
              // 2행: 영문 명조체 타이틀 (황금색)
              Text(
                'ACADEMIC TIMER',
                style: GoogleFonts.notoSerif(
                  color: goldColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // 3행: 한글 타이틀 (노토 산스 한글, 황금색)
              Text(
                '학사 타이머',
                style: GoogleFonts.notoSansKr(
                  color: goldColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTrackSelector(),
          const Divider(color: Color(0xFF1E293B), height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildTrackBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackSelector() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: [
          _trackButton('평상시', 'NORMAL_PERIOD'),
          _trackButton('방학', 'VACATION_SUMMER_WINTER'),
          _trackButton('시험준비', 'EXAM_PREP_PERIOD'),
          _trackButton('시험당일', 'EXAM_DAY_TRACK'),
        ],
      ),
    );
  }

  Widget _trackButton(String label, String trackKey) {
    bool isSelected = _selectedTrack == trackKey;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? goldColor : slate800,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: () => setState(() => _selectedTrack = trackKey),
      child: Text(
        label,
        style: GoogleFonts.notoSansKr(
          color: isSelected ? const Color(0xFF020617) : Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 트랙별 본문 라우팅
  // ------------------------------------------------------------
  Widget _buildTrackBody() {
    switch (_selectedTrack) {
      case 'NORMAL_PERIOD':
        return _buildNormalPeriodBody();
      case 'VACATION_SUMMER_WINTER':
        return _buildVacationBody();
      case 'EXAM_PREP_PERIOD':
        return _buildExamPrepBody();
      case 'EXAM_DAY_TRACK':
        return _buildExamDayBody();
      default:
        return _buildNormalPeriodBody();
    }
  }

  // ------------------------------------------------------------
  // 1. 평상시: 요일 선택 (자동 날짜 연동)
  // ------------------------------------------------------------
  Widget _buildNormalPeriodBody() {
    List<Map<String, String>> schedule = _getCurrentActiveSchedule();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NORMAL PERIOD', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold)),
        Text('평상시 기본 타임라인 - 오늘 요일 자동 연동', style: GoogleFonts.notoSansKr(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _weekdayOptions.map((day) {
            bool isSel = _selectedWeekdayEn == day['en'];
            return ChoiceChip(
              label: Text(day['ko']!,
                  style: GoogleFonts.notoSansKr(
                      fontSize: 12, color: isSel ? const Color(0xFF020617) : Colors.white, fontWeight: FontWeight.bold)),
              selected: isSel,
              selectedColor: goldColor,
              backgroundColor: slate800,
              side: BorderSide(color: isSel ? goldColor : slate800),
              onSelected: (_) {
                setState(() {
                  _selectedWeekdayEn = day['en']!;
                });
              },
            );
          }).toList(),
        ),
        const Divider(color: Color(0xFF1E293B), height: 30),
        _buildScheduleHeaderBar(),
        const SizedBox(height: 8),
        ..._buildScheduleList(schedule),
      ],
    );
  }

  // ------------------------------------------------------------
  // 2. 방학: 기간 설정 + 포모도로 스타일 설정
  // ------------------------------------------------------------
  Widget _buildVacationBody() {
    List<Map<String, String>> schedule = _getCurrentActiveSchedule();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('VACATION SUMMER/WINTER', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold)),
        Text('방학 포모도로 타임라인 - 기간 및 스타일 설정', style: GoogleFonts.notoSansKr(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: slate800.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: slate800)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('VACATION PERIOD / 방학 기간', style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(side: BorderSide(color: slate800)),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _vacationStartDate ?? DateTime.now(),
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() {
                            _vacationStartDate = picked;
                          });
                          await _saveVacationSettings();
                        }
                      },
                      child: Text(
                        _vacationStartDate == null
                            ? '시작일 선택'
                            : '${_vacationStartDate!.year}.${_vacationStartDate!.month}.${_vacationStartDate!.day}',
                        style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('~', style: GoogleFonts.notoSansKr(color: slate400)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(side: BorderSide(color: slate800)),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _vacationEndDate ?? (_vacationStartDate ?? DateTime.now()),
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() {
                            _vacationEndDate = picked;
                          });
                          await _saveVacationSettings();
                        }
                      },
                      child: Text(
                        _vacationEndDate == null
                            ? '종료일 선택'
                            : '${_vacationEndDate!.year}.${_vacationEndDate!.month}.${_vacationEndDate!.day}',
                        style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: slate800.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: slate800)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('POMODORO STYLE / 포모도로 스타일 (직접 선택)',
                  style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('스타일마다 구성이 달라 자동 전환하지 않습니다. 원하는 스타일을 직접 골라주세요.',
                  style: GoogleFonts.notoSansKr(fontSize: 11, color: slate500)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['vacationPomodoro1', 'vacationPomodoro2', 'vacationPomodoro3', 'vacationPomodoro4'].map((key) {
                  bool isSel = _selectedPomodoroKey == key;
                  return ChoiceChip(
                    label: Text(
                      _getPomodoroDisplayName(key),
                      style: GoogleFonts.notoSansKr(
                          fontSize: 11, color: isSel ? const Color(0xFF020617) : Colors.white, fontWeight: FontWeight.bold),
                    ),
                    selected: isSel,
                    selectedColor: goldColor,
                    backgroundColor: const Color(0xFF0F172A),
                    side: BorderSide(color: isSel ? goldColor : slate800),
                    onSelected: (selected) async {
                      setState(() {
                        _selectedPomodoroKey = selected ? key : null;
                      });
                      await _saveVacationSettings();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text('평일에도 이 스타일 자유롭게 사용',
                        style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white)),
                  ),
                  Switch(
                    value: _isPomodoroFreeModeEnabled,
                    activeColor: goldColor,
                    onChanged: (val) async {
                      setState(() {
                        _isPomodoroFreeModeEnabled = val;
                      });
                      await _saveVacationSettings();
                    },
                  ),
                ],
              ),
              Text('켜두면 방학 기간이 아닌 평일에도 위에서 고른 스타일을 그대로 사용할 수 있습니다.',
                  style: GoogleFonts.notoSansKr(fontSize: 11, color: slate500)),
            ],
          ),
        ),

        const Divider(color: Color(0xFF1E293B), height: 30),

        if (_selectedPomodoroKey == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Text('선택된 포모도로 스타일이 없습니다. 위에서 스타일을 선택해주세요.',
                style: GoogleFonts.notoSansKr(color: slate500, fontSize: 12)),
          )
        else ...[
          Text('선택된 스타일: ${_getPomodoroDisplayName(_selectedPomodoroKey!)}',
              style: GoogleFonts.notoSansKr(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildScheduleHeaderBar(),
          const SizedBox(height: 8),
          ..._buildScheduleList(schedule),
        ],
      ],
    );
  }

  // ------------------------------------------------------------
  // 3. 시험 준비: 시험 정보만 입력하면 자동 계산
  // ------------------------------------------------------------
  Widget _buildExamPrepBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('EXAM PREP PERIOD', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold)),
        Text('시험 준비 타임라인 - 시험 정보를 입력하면 자동 계산됩니다',
            style: GoogleFonts.notoSansKr(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildExamSettingsCard(),
        const Divider(color: Color(0xFF1E293B), height: 30),
        _buildExamPrepResult(),
      ],
    );
  }

  Widget _buildExamSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: slate800.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: slate800)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EXAM INFO / 시험 정보 입력', style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: ['중간고사', '기말고사'].map((type) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<String>(
                      value: type,
                      groupValue: _isFinalExamMode ? '기말고사' : '중간고사',
                      activeColor: goldColor,
                      onChanged: (value) async {
                        setState(() {
                          _isFinalExamMode = (value == '기말고사');
                        });
                        await _saveExamSettings();
                      },
                    ),
                    Text(type, style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(side: BorderSide(color: slate800)),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _examStartDate ?? DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                setState(() {
                  _examStartDate = picked;
                });
                await _saveExamSettings();
              }
            },
            child: Text(
              _examStartDate == null
                  ? '시험 시작일(D-day) 선택'
                  : '시험 시작일: ${_examStartDate!.year}.${_examStartDate!.month}.${_examStartDate!.day}',
              style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamPrepResult() {
    if (_examStartDate == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Text('시험 시작일을 입력하면 오늘 기준 몇 주 전 타임라인인지 자동으로 계산됩니다.',
            style: GoogleFonts.notoSansKr(color: slate500, fontSize: 12)),
      );
    }

    final DateTime today = DateTime.now();
    final DateTime cleanToday = DateTime(today.year, today.month, today.day);
    final DateTime cleanExamStart = DateTime(_examStartDate!.year, _examStartDate!.month, _examStartDate!.day);
    final int daysUntilExam = cleanExamStart.difference(cleanToday).inDays;

    if (daysUntilExam <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Text('이미 시험 준비 기간이 지났습니다. [시험당일] 탭에서 D-day 트랙을 확인해주세요.',
            style: GoogleFonts.notoSansKr(color: slate500, fontSize: 12)),
      );
    }
    if (daysUntilExam > 28) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Text('아직 시험 준비 4주 전 기간이 시작되지 않았습니다. (D-$daysUntilExam)',
            style: GoogleFonts.notoSansKr(color: slate500, fontSize: 12)),
      );
    }

    int weekNum = daysUntilExam > 21 ? 4 : (daysUntilExam > 14 ? 3 : (daysUntilExam > 7 ? 2 : 1));
    String dayType = _calcExamPrepDayType(weekNum);
    List<Map<String, String>> schedule = _getCurrentActiveSchedule();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_isFinalExamMode ? "기말고사" : "중간고사"} 준비 $weekNum주 전 (D-$daysUntilExam)',
          style: GoogleFonts.notoSansKr(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildScheduleHeaderBar(),
        const SizedBox(height: 8),
        ..._buildScheduleList(schedule),
      ],
    );
  }

  // ------------------------------------------------------------
  // 4. 시험 당일: D-3 ~ D+4 자동 계산
  // ------------------------------------------------------------
  Widget _buildExamDayBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('EXAM DAY TRACK', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold)),
        Text('시험 당일 D-day 타임라인 - 자동 계산됩니다',
            style: GoogleFonts.notoSansKr(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildExamSettingsCard(),
        const Divider(color: Color(0xFF1E293B), height: 30),
        _buildExamDayResult(),
      ],
    );
  }

  Widget _buildExamDayResult() {
    if (_examStartDate == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Text('시험 시작일을 입력하면 D-3 ~ D+4 구간의 정확한 트랙이 자동으로 표시됩니다.',
            style: GoogleFonts.notoSansKr(color: slate500, fontSize: 12)),
      );
    }

    final DateTime today = DateTime.now();
    final DateTime cleanToday = DateTime(today.year, today.month, today.day);
    final DateTime cleanExamStart = DateTime(_examStartDate!.year, _examStartDate!.month, _examStartDate!.day);
    final int diff = cleanToday.difference(cleanExamStart).inDays;

    if (diff < -3 || diff > 4) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Text(
          '오늘은 시험 당일 트랙 구간(D-3 ~ D+4)이 아닙니다. 현재 기준 ${diff > 0 ? "D+$diff" : "D$diff"} 입니다.',
          style: GoogleFonts.notoSansKr(color: slate500, fontSize: 12),
        ),
      );
    }

    List<Map<String, String>> schedule = _getCurrentActiveSchedule();
    String dDayLabel = diff == 0 ? 'D-Day' : (diff < 0 ? 'D$diff' : 'D+$diff');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_isFinalExamMode ? "기말고사" : "중간고사"} 시험 당일 트랙 ($dDayLabel)',
          style: GoogleFonts.notoSansKr(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildScheduleHeaderBar(),
        const SizedBox(height: 8),
        ..._buildScheduleList(schedule),
      ],
    );
  }

  // ------------------------------------------------------------
  // 스케줄 리스트 상단 컨트롤러 바 (추가 및 원본 리셋 기능 제공)
  // ------------------------------------------------------------
  Widget _buildScheduleHeaderBar() {
    bool isCustomized = _customSchedules.containsKey(_getCurrentCacheKey());
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (isCustomized)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: goldColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                child: Text('사용자 편집됨', style: GoogleFonts.notoSansKr(color: goldColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            if (isCustomized)
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                onPressed: _resetToDefaultSchedule,
                icon: const Icon(Icons.refresh, size: 14, color: Colors.amberAccent),
                label: Text('원본 리셋', style: GoogleFonts.notoSansKr(color: Colors.amberAccent, fontSize: 11)),
              ),
          ],
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: slate800,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
          ),
          onPressed: () => _showEditItemDialog(),
          icon: const Icon(Icons.add, size: 14, color: Colors.white),
          label: Text('항목 추가', style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 11)),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // 공통 리스트 렌더러 (시간 경과 시 회색 흐릿하게 자동 변환 + 폰트 14 적용)
  // ------------------------------------------------------------
  List<Widget> _buildScheduleList(List<Map<String, String>> schedule) {
    if (schedule.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text('표시할 데이터가 없습니다.', style: GoogleFonts.notoSansKr(color: slate500, fontSize: 14)),
        )
      ];
    }
    return schedule.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, String> item = entry.value;

      final String timeText = item['time'] ?? '';
      final String taskText = item['task'] ?? '';
      final bool timePassed = _isTimePassed(timeText);

      final Color timeColor = timePassed ? slate500 : goldColor;
      final Color taskColor = timePassed ? slate400 : Colors.white;

      return GestureDetector(
        onTap: () => _showEditItemDialog(
          index: index,
          initialTime: timeText,
          initialTask: taskText,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: timePassed ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
            border: timePassed ? Border.all(color: slate800.withValues(alpha: 0.5)) : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 92,
                child: Text(
                  timeText,
                  style: GoogleFonts.notoSerif(
                    color: timeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  taskText,
                  style: GoogleFonts.notoSansKr(
                    color: taskColor,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(
                Icons.edit,
                size: 14,
                color: timePassed ? slate500 : const Color(0xFF64748B),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}