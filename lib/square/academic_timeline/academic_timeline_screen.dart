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
  final Color darkGrey = const Color(0xFF333333); // 취침용 진한 회색 정의

  // 1개 세트 구분용 7가지 색상 순서 (빨, 파, 노, 초, 주, 남, 보)
  final List<Color> _rainbowColors = [
    Colors.red,      // 빨간색
    Colors.blue,     // 파란색
    Colors.yellow,   // 노란색
    Colors.green,    // 초록색
    Colors.orange,   // 주황색
    Colors.indigo,   // 남색
    Colors.purple,   // 보라색
  ];

  // ============================================================
  // 상단 트랙 선택 상태
  // ============================================================
  String _selectedTrack = 'NORMAL_PERIOD';

  // ------------------------------------------------------------
  // 1. 평상시(NORMAL_PERIOD) 관련: 요일 선택 (오늘 날짜 기준 자동 연동)
  // ------------------------------------------------------------
  String _selectedWeekdayEn = 'Monday';
  final List<Map<String, String>> _weekdayOptions = [
    {'en': 'Monday', 'ko': '월요일', 'abbr': 'Mon'},
    {'en': 'Tuesday', 'ko': '화요일', 'abbr': 'Tue'},
    {'en': 'Wednesday', 'ko': '수요일', 'abbr': 'Wed'},
    {'en': 'Thursday', 'ko': '목요일', 'abbr': 'Thu'},
    {'en': 'Friday', 'ko': '금요일', 'abbr': 'Fri'},
    {'en': 'Saturday', 'ko': '토요일', 'abbr': 'Sat'},
    {'en': 'Sunday', 'ko': '일요일', 'abbr': 'Sun'},
  ];
  bool _isNormalWeekdayExpanded = true; // 평상시 요일 선택 영역 접었다 폈다 토글 상태

  // ------------------------------------------------------------
  // 2. 방학(VACATION_SUMMER_WINTER) 관련
  // ------------------------------------------------------------
  DateTime? _vacationStartDate;
  DateTime? _vacationEndDate;
  String? _selectedPomodoroKey; // 'vacationPomodoro1' ~ 'vacationPomodoro4'
  bool _isPomodoroFreeModeEnabled = false;
  bool _isVacationStyleExpanded = true; // 방학 포모도로 스타일 설정 영역 접었다 폈다 토글 상태

  // ------------------------------------------------------------
  // 3 & 4. 시험(EXAM_PREP_PERIOD / EXAM_DAY_TRACK) 공통 관련
  // ------------------------------------------------------------
  bool _isFinalExamMode = false; // false = 중간고사, true = 기말고사
  DateTime? _examStartDate; // 시험 시작일 (D-day)

  // 시험 준비 탭 전용 상태 변수들
  int _selectedExamPrepWeek = 4; // '1주 전' 삭제 후 4주전, 3주전, 2주전만 선택 가능
  bool _isExamSettingExpanded = true; // 시험 정보 설정 및 목록 전체 영역 접었다 폈다 토글 상태
  final List<Map<String, String>> _customExamRecords = []; // [날짜, 시험과목, 시험범위] 기록 리스트

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
      final int weekNum = _selectedExamPrepWeek;
      final String dayType = _calcExamPrepDayType(weekNum);
      cacheKey = 'EXAM_PREP_${_isFinalExamMode ? "final" : "mid"}_w${weekNum}_$dayType';
      defaultList = _getExamPrepList(weekNum, dayType, _isFinalExamMode);
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
      final int weekNum = _selectedExamPrepWeek;
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

  String _calcExamPrepDayType(int weekNum) {
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
        return 'Style 1 (Ultra Focus 25m) / 스타일 1 (초집중 25분형)';
      case 'vacationPomodoro2':
        return 'Style 2 (Focus 40m) / 스타일 2 (집중 40분형)';
      case 'vacationPomodoro3':
        return 'Style 3 (Subject 45m) / 스타일 3 (과목별 45분형)';
      case 'vacationPomodoro4':
        return 'Style 4 (Focus 60m) / 스타일 4 (집중 60분형)';
      default:
        return 'Not Selected / 미선택';
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
  // 타임라인 세트별 바("|") 색상 지정 함수
  // ============================================================
  Color _getTimelineBarColor(String track, String timeText, String taskText, int index) {
    if (taskText.contains('기상') ||
        taskText.contains('체조') ||
        taskText.contains('아침식사') ||
        taskText.contains('점심') ||
        taskText.contains('저녁') ||
        taskText.contains('학교생활') ||
        taskText.contains('취침 준비') ||
        taskText.contains('마무리')) {
      return Colors.purple;
    }
    if (taskText.contains('취침')) {
      return darkGrey;
    }

    if (track == 'NORMAL_PERIOD') {
      if (_selectedWeekdayEn == 'Saturday' || _selectedWeekdayEn == 'Sunday') {
        if (timeText.contains('07:00') && timeText.contains('08:00')) {
          return Colors.purple;
        }
        int adjustedIndex = (index > 0 ? index - 1 : 0) ~/ 2;
        return _rainbowColors[adjustedIndex % _rainbowColors.length];
      } else {
        if (timeText.contains('07:00') && timeText.contains('08:00')) {
          return Colors.red;
        }
        if ((timeText.contains('08:00') && timeText.contains('16:00')) ||
            (timeText.contains('16:00') && timeText.contains('17:00'))) {
          return Colors.purple;
        }
        int adjustedIndex = index >= 3 ? (index - 3) ~/ 2 : index;
        return _rainbowColors[adjustedIndex % _rainbowColors.length];
      }
    }

    if (track == 'VACATION_SUMMER_WINTER' && _selectedPomodoroKey == 'vacationPomodoro1') {
      if ((timeText.contains('06:00') && timeText.contains('06:30')) ||
          (timeText.contains('06:30') && timeText.contains('07:00'))) {
        return Colors.purple;
      }
      if (index >= 2 && index <= 7) return Colors.red;
      if (index >= 8 && index <= 13) return Colors.blue;
      if (index >= 14 && index <= 19) return Colors.yellow;
      if (index >= 20 && index <= 20) return Colors.purple;
      if (index >= 21 && index <= 26) return Colors.green;
      if (index >= 27 && index <= 32) return Colors.orange;
      if (index >= 33 && index <= 40) return Colors.indigo;
      if (index >= 41 && index <= 47) return Colors.red;
      if (index >= 48) return Colors.purple;
    }

    if (track == 'VACATION_SUMMER_WINTER' && _selectedPomodoroKey == 'vacationPomodoro2') {
      if (taskText.contains('기상') || taskText.contains('아침식사') || taskText.contains('점심') || taskText.contains('취침')) {
        return Colors.purple;
      }
      int setIndex = index >= 2 ? (index - 2) ~/ 2 : 0;
      return _rainbowColors[setIndex % _rainbowColors.length];
    }

    if (track == 'VACATION_SUMMER_WINTER' && _selectedPomodoroKey == 'vacationPomodoro3') {
      if (index >= 2 && index <= 7) return Colors.red;
      if (index >= 8 && index <= 13) return Colors.blue;
      if (index >= 14 && index <= 14) return Colors.purple;
      if (index >= 15 && index <= 20) return Colors.yellow;
      if (index >= 21 && index <= 21) return Colors.purple;
      if (index >= 22 && index <= 27) return Colors.green;
      if (index >= 28 && index <= 29) return Colors.orange;
      if (index >= 30) return Colors.purple;
    }

    if (track == 'VACATION_SUMMER_WINTER' && _selectedPomodoroKey == 'vacationPomodoro4') {
      if ((timeText.contains('06:00') && timeText.contains('06:30')) ||
          (timeText.contains('06:30') && timeText.contains('07:00'))) {
        return Colors.purple;
      }
      if (index >= 2 && index <= 5) return Colors.red;
      if (index >= 6 && index <= 9) return Colors.blue;
      if (index >= 10 && index <= 10) return Colors.purple;
      if (index >= 11 && index <= 14) return Colors.yellow;
      if (index >= 15 && index <= 18) return Colors.green;
      if (index >= 19 && index <= 19) return Colors.purple;
      if (index >= 20 && index <= 22) return Colors.orange;
      if (index >= 23) return Colors.purple;
    }

    return _rainbowColors[index % _rainbowColors.length];
  }

  // ============================================================
  // 효율적인 연속 입력 달력 및 일괄 저장 시스템
  // ============================================================
  Future<void> _handleExamRecordFlow() async {
    List<Map<String, String>> sessionRecords = [];
    DateTime? firstSelectedDate;
    bool isAdding = true;

    while (isAdding) {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: firstSelectedDate ?? DateTime.now(),
        firstDate: firstSelectedDate ?? DateTime(2024),
        lastDate: DateTime(2035),
      );

      if (pickedDate == null) {
        return;
      }

      if (firstSelectedDate == null) {
        firstSelectedDate = pickedDate;
      }

      String formattedDate = '${pickedDate.year}.${pickedDate.month}.${pickedDate.day}';

      if (!mounted) return;

      final TextEditingController subjectController = TextEditingController();
      final TextEditingController scopeController = TextEditingController();

      String? actionType = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: Text(
              '[$formattedDate] Exam Subject & Scope / 시험 과목 및 범위 기록',
              style: GoogleFonts.notoSerif(color: goldColor, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectController,
                  style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Subject (e.g., Math) / 시험 과목 (예: 수학)',
                    labelStyle: GoogleFonts.notoSerif(color: slate400, fontSize: 12),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: slate800)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: scopeController,
                  style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Scope (e.g., Limits) / 시험 범위 (예: 함수 ~ 미적분)',
                    labelStyle: GoogleFonts.notoSerif(color: slate400, fontSize: 12),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: slate800)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancel'),
                child: Text('Cancel / 취소', style: GoogleFonts.notoSerif(color: slate400, fontSize: 12)),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(side: BorderSide(color: goldColor)),
                onPressed: () {
                  if (subjectController.text.trim().isEmpty) return;
                  Navigator.pop(context, 'next');
                },
                child: Text('Next Date / 다음 날짜 입력', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: goldColor),
                onPressed: () {
                  if (subjectController.text.trim().isEmpty) return;
                  Navigator.pop(context, 'save');
                },
                child: Text('Save / 저장', style: GoogleFonts.notoSerif(color: const Color(0xFF020617), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );

      if (actionType == 'cancel' || actionType == null) {
        return;
      }

      sessionRecords.add({
        'date': formattedDate,
        'subject': subjectController.text.trim(),
        'scope': scopeController.text.trim(),
      });

      if (actionType == 'save') {
        isAdding = false;
      }
    }

    if (!mounted) return;
    bool? confirmSave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            'Save Exam Schedule / 시험 일정 저장',
            style: GoogleFonts.notoSerif(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'All exam schedules and subjects will be applied to all dates. Do you want to save?\n모든 일자에 시험 일정과 과목이 적용됩니다. 저장하시겠습니까?',
            style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 13),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel / 취소', style: GoogleFonts.notoSerif(color: slate400, fontSize: 12)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: goldColor),
              onPressed: () => Navigator.pop(context, true),
              child: Text('Confirm / 확인', style: GoogleFonts.notoSerif(color: const Color(0xFF020617), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmSave == true) {
      setState(() {
        _customExamRecords.addAll(sessionRecords);
      });

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: Text('Saved / 저장 완료', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold)),
            content: Text(
              'Exam schedule and subjects have been applied to all dates.\n모든 일자에 시험 일정과 과목이 적용됩니다.',
              style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 13),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: goldColor),
                onPressed: () => Navigator.pop(context),
                child: Text('Confirm / 확인', style: GoogleFonts.notoSerif(color: const Color(0xFF020617), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    }
  }

  // ============================================================
  // 등록된 시험 과목/범위 수정 및 삭제 팝업 함수 (버튼 일렬 정렬 반영)
  // ============================================================
  void _showEditExamRecordDialog(int index) {
    final record = _customExamRecords[index];
    final TextEditingController subjectController = TextEditingController(text: record['subject']);
    final TextEditingController scopeController = TextEditingController(text: record['scope']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            '[${record['date']}] Edit / 시험 과목 수정 및 삭제',
            style: GoogleFonts.notoSerif(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Subject / 시험 과목',
                  labelStyle: GoogleFonts.notoSerif(color: slate400, fontSize: 12),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: slate800)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: scopeController,
                style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Scope / 시험 범위',
                  labelStyle: GoogleFonts.notoSerif(color: slate400, fontSize: 12),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: slate800)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _customExamRecords.removeAt(index);
                });
                Navigator.pop(context);
              },
              child: Text('Delete / 삭제', style: GoogleFonts.notoSerif(color: Colors.redAccent, fontSize: 12)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel / 취소', style: GoogleFonts.notoSerif(color: slate400, fontSize: 12)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: goldColor),
              onPressed: () {
                if (subjectController.text.trim().isEmpty) return;
                setState(() {
                  _customExamRecords[index] = {
                    'date': record['date']!,
                    'subject': subjectController.text.trim(),
                    'scope': scopeController.text.trim(),
                  };
                });
                Navigator.pop(context);
              },
              child: Text('Save / 수정 저장', style: GoogleFonts.notoSerif(color: const Color(0xFF020617), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // 일반 타임라인 항목 추가/수정 팝업 함수 (버튼 일렬 정렬 반영)
  // ============================================================
  void _showEditItemDialog({int? index, String? initialTime, String? initialTask}) {
    final TextEditingController timeController = TextEditingController(text: initialTime ?? '');
    final TextEditingController taskController = TextEditingController(text: initialTask ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // 1. 검정 바탕색 설정
          backgroundColor: const Color(0xFF0B0F19),
          // 2. 노란 테두리 적용
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
          ),
          title: Text(
            index == null ? 'Add Schedule / 타임라인 항목 추가' : 'Edit / 타임라인 항목 수정 및 삭제',
            style: GoogleFonts.notoSerif(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: timeController,
                style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Time (e.g., 09:00 - 10:00) / 시간',
                  labelStyle: GoogleFonts.notoSerif(color: slate400, fontSize: 12),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: slate800)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: taskController,
                style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Content / 내용',
                  labelStyle: GoogleFonts.notoSerif(color: slate400, fontSize: 12),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: slate800)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
                ),
              ),
            ],
          ),
          // 3. 버튼들을 가로로 꽉 차게 배치하기 위한 Row 구성
          actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          actions: [
            Row(
              children: [
                if (index != null)
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          String cacheKey = _getCurrentCacheKey();
                          List<Map<String, String>> currentList = List.from(_getCurrentActiveSchedule());
                          currentList.removeAt(index);
                          _customSchedules[cacheKey] = currentList;
                        });
                        Navigator.pop(context);
                      },
                      child: Text('Delete / 삭제', style: GoogleFonts.notoSerif(color: Colors.redAccent, fontSize: 12)),
                    ),
                  ),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel / 취소', style: GoogleFonts.notoSerif(color: slate400, fontSize: 12)),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
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
                    child: Text('Save/저장', style: GoogleFonts.notoSerif(color: const Color(0xFF020617), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
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
          title: Text('Reset / 원본 리셋', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold)),
          content: Text('Reset to default schedule?\n현재 화면의 타임라인을 원본 기본 데이터로 초기화하시겠습니까?', style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 14)),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel / 취소', style: GoogleFonts.notoSerif(color: slate400, fontSize: 12)),
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
              child: Text('Confirm / 리셋 확인', style: GoogleFonts.notoSerif(color: const Color(0xFF020617), fontSize: 12, fontWeight: FontWeight.bold)),
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
              Text(
                'ACADEMIC TIMER',
                style: GoogleFonts.notoSerif(
                  color: goldColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '학사 타이머',
                style: GoogleFonts.notoSerif(
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

  // [요청사항 1] 상단 4개 트랙 버튼 크기를 동일하게 배치 (Expanded 활용)
  Widget _buildTrackSelector() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(child: _trackButton('Normal\n평상시', 'NORMAL_PERIOD')),
          const SizedBox(width: 6),
          Expanded(child: _trackButton('Vacation\n방학', 'VACATION_SUMMER_WINTER')),
          const SizedBox(width: 6),
          Expanded(child: _trackButton('Exam Prep\n시험준비', 'EXAM_PREP_PERIOD')),
          const SizedBox(width: 6),
          Expanded(child: _trackButton('Exam Day\n시험당일', 'EXAM_DAY_TRACK')),
        ],
      ),
    );
  }

  Widget _trackButton(String label, String trackKey) {
    bool isSelected = _selectedTrack == trackKey;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? goldColor : slate800,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        minimumSize: const Size(0, 44),
      ),
      onPressed: () => setState(() => _selectedTrack = trackKey),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.notoSerif(
          color: isSelected ? const Color(0xFF020617) : Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          height: 1.2,
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
  // 1. 평상시: 요일 선택 토글 + 영문 약자 포함 2열 배치 + 실시간 D-day
  // ------------------------------------------------------------
  Widget _buildNormalPeriodBody() {
    List<Map<String, String>> schedule = _getCurrentActiveSchedule();

    // D-day 실시간 계산 로직
    String dDayText = 'D-Day 없음';
    if (_examStartDate != null) {
      final DateTime today = DateTime.now();
      final DateTime cleanToday = DateTime(today.year, today.month, today.day);
      final DateTime cleanExamStart = DateTime(_examStartDate!.year, _examStartDate!.month, _examStartDate!.day);
      final int diff = cleanExamStart.difference(cleanToday).inDays;
      String examName = _isFinalExamMode ? '기말' : '중간';
      String examNameEn = _isFinalExamMode ? 'Final' : 'Mid';
      if (diff == 0) {
        dDayText = '$examNameEn/$examName D-Day';
      } else if (diff > 0) {
        dDayText = '$examNameEn/$examName D-$diff';
      } else {
        dDayText = '$examNameEn/$examName D+${diff.abs()}';
      }
    }

    final currentSelectedObj = _weekdayOptions.firstWhere((d) => d['en'] == _selectedWeekdayEn, orElse: () => _weekdayOptions[0]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NORMAL PERIOD', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold)),
        Text('평상시 기본 타임라인 - 오늘 요일 자동 연동', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        // [요청사항 1, 2] 요일 선택 영역 접었다 폈다 및 영문 약자 포함 2열 배치
        Container(
          decoration: BoxDecoration(
            color: slate800.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: slate800),
          ),
          child: ExpansionTile(
            initiallyExpanded: _isNormalWeekdayExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _isNormalWeekdayExpanded = expanded;
              });
            },
            collapsedTextColor: goldColor,
            textColor: goldColor,
            iconColor: goldColor,
            collapsedIconColor: slate400,
            title: Text(
// currentSelectedObj가 null이거나 내부 값이 없을 때를 대비한 안전 장치 추가
              'Select Weekday / 요일 선택 (${currentSelectedObj?['abbr'] ?? 'MON'} / ${currentSelectedObj?['ko'] ?? '월요일'})',
              style: GoogleFonts.notoSerif(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 3.5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: _weekdayOptions.map((day) {
                    bool isSel = _selectedWeekdayEn == day['en'];
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedWeekdayEn = day['en']!;
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSel ? goldColor : slate800,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSel ? goldColor : slate800),
                        ),
                        child: Text(
                          '${day['abbr']} / ${day['ko']}',
                          style: GoogleFonts.notoSerif(
                            fontSize: 12,
                            color: isSel ? const Color(0xFF020617) : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // [요청사항 2] 요일 아래이자 "항목 추가" 버튼과 같은 라인의 왼쪽에 실시간 D-day 표시
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: goldColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: goldColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  dDayText,
                  style: GoogleFonts.notoSerif(
                    color: goldColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildScheduleHeaderBar(),
          ],
        ),

        const SizedBox(height: 8),
        ..._buildScheduleList(schedule),
      ],
    );
  }

  // ------------------------------------------------------------
  // 2. 방학: 포모도로 스타일 설정 영역 접었다 폈다 추가
  // ------------------------------------------------------------
  Widget _buildVacationBody() {
    List<Map<String, String>> schedule = _getCurrentActiveSchedule();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('VACATION SUMMER/WINTER', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold)),
        Text('방학 포모도로 타임라인 - 기간 및 스타일 설정', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: slate800.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: slate800)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('VACATION PERIOD / 방학 기간', style: GoogleFonts.notoSerif(fontSize: 16, color: goldColor, fontWeight: FontWeight.bold)),
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
                        style: GoogleFonts.notoSerif(fontSize: 15, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('~', style: GoogleFonts.notoSerif(color: slate400)),
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
                        style: GoogleFonts.notoSerif(fontSize: 15, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // [요청사항 4] POMODORO STYLE / 포모도로 스타일(직접 선택) 영역 접었다 폈다 추가
        Container(
          decoration: BoxDecoration(
            color: slate800.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: slate800),
          ),
          child: ExpansionTile(
            initiallyExpanded: _isVacationStyleExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _isVacationStyleExpanded = expanded;
              });
            },
            collapsedTextColor: goldColor,
            textColor: goldColor,
            iconColor: goldColor,
            collapsedIconColor: slate400,
            title: Text(
              'POMODORO STYLE / 포모도로 스타일 (직접 선택)',
              style: GoogleFonts.notoSerif(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('스타일마다 구성이 달라 자동 전환하지 않습니다. 원하는 스타일을 직접 골라주세요.',
                        style: GoogleFonts.notoSerif(fontSize: 12, color: slate500)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['vacationPomodoro1', 'vacationPomodoro2', 'vacationPomodoro3', 'vacationPomodoro4'].map((key) {
                        bool isSel = _selectedPomodoroKey == key;
                        return ChoiceChip(
                          label: Text(
                            _getPomodoroDisplayName(key),
                            style: GoogleFonts.notoSerif(
                                fontSize: 12, color: isSel ? const Color(0xFF020617) : Colors.white, fontWeight: FontWeight.bold),
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
                              style: GoogleFonts.notoSerif(fontSize: 12, color: Colors.white)),
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
                        style: GoogleFonts.notoSerif(fontSize: 11, color: slate500)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(color: Color(0xFF1E293B), height: 30),

        if (_selectedPomodoroKey == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Text('선택된 포모도로 스타일이 없습니다. 위에서 스타일을 선택해주세요.',
                style: GoogleFonts.notoSerif(color: slate500, fontSize: 12)),
          )
        else ...[
          Column(
            children: [

// 한글 부분: 기존 함수 사용
              Text(
                '${_getPomodoroDisplayName(_selectedPomodoroKey!)}',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSerif(color: goldColor.withValues(alpha: 0.8), fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildScheduleHeaderBar(),
          const SizedBox(height: 5),
          ..._buildScheduleList(schedule),
        ],
      ],
    );
  }

  // ------------------------------------------------------------
  // 3. 시험 준비: [요청사항 최종 반영] Final/기말 표기 수정
  // ------------------------------------------------------------
  Widget _buildExamPrepBody() {
    List<Map<String, String>> schedule = _getCurrentActiveSchedule();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('EXAM PREP PERIOD', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 17, fontWeight: FontWeight.bold)),
        Text('시험 준비 타임라인 - 시험 정보 및 주차별 설정',
            style: GoogleFonts.notoSerif(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            color: slate800.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: slate800),
          ),
          child: ExpansionTile(
            initiallyExpanded: _isExamSettingExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _isExamSettingExpanded = expanded;
              });
            },
            collapsedTextColor: goldColor,
            textColor: goldColor,
            iconColor: goldColor,
            collapsedIconColor: slate400,
            title: Row(
              children: [
                Text('EXAM INFO / 시험 정보 설정', style: GoogleFonts.notoSerif(fontSize: 14, color: goldColor, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Text(
                  // [요청사항 4] Final/기말고사 -> Final/기말 로 수정
                  '(${_isFinalExamMode ? "Final / 기말" : "Mid / 중간"})',
                  style: GoogleFonts.notoSerif(fontSize: 13, color: slate400),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: ['중간고사', '기말고사'].map((type) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 17.0),
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
                              Text(type, style: GoogleFonts.notoSerif(fontSize: 13, color: Colors.white)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),

                    Text('시험일 주차 선택', style: GoogleFonts.notoSerif(fontSize: 13, color: slate400, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [4, 3, 2].map((week) {
                        bool isSel = _selectedExamPrepWeek == week;
                        return ChoiceChip(
                          label: Text(
                            '시험일 ${week}주 전',
                            style: GoogleFonts.notoSerif(
                                fontSize: 11, color: isSel ? const Color(0xFF020617) : Colors.white, fontWeight: FontWeight.bold),
                          ),
                          selected: isSel,
                          selectedColor: goldColor,
                          backgroundColor: const Color(0xFF0F172A),
                          side: BorderSide(color: isSel ? goldColor : slate800),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedExamPrepWeek = week;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: goldColor),
                      onPressed: _handleExamRecordFlow,
                      icon: const Icon(Icons.calendar_today, size: 14, color: Color(0xFF020617)),
                      label: Text('시험 과목 및 범위 기록 추가 (연속 입력)', style: GoogleFonts.notoSerif(color: const Color(0xFF020617), fontSize: 14, fontWeight: FontWeight.bold)),
                    ),

                    const SizedBox(height: 14),

                    if (_customExamRecords.isNotEmpty) ...[
                      Text('등록된 시험 과목 및 범위 (${_customExamRecords.length}개)', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._customExamRecords.asMap().entries.map((entry) {
                        int idx = entry.key;
                        Map<String, String> record = entry.value;
                        return GestureDetector(
                          onTap: () => _showEditExamRecordDialog(idx),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Text('[${record['date']}] ', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
                                Text('${record['subject']} : ', style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    '범위: ${record['scope']}',
                                    style: GoogleFonts.notoSerif(color: slate400, fontSize: 12),
                                  ),
                                ),
                                Icon(Icons.edit, size: 12, color: slate500),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(color: Color(0xFF1E293B), height: 30),
// 1. 텍스트를 그리기 직전에 타이틀 문자열을 깔끔하게 완성합니다.
        Text(
          '${_isFinalExamMode ? "기말고사" : "중간고사"} 준비 ${_selectedExamPrepWeek}주 전 타임라인${_examStartDate != null ? ' (D-${_examStartDate!.difference(DateTime.now()).inDays + 1}일 / ${["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"][_examStartDate!.weekday - 1]})' : ''}',
          style: GoogleFonts.notoSerif(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold),
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
            style: GoogleFonts.notoSerif(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildExamSettingsCardForExamDay(),
        const Divider(color: Color(0xFF1E293B), height: 30),
        _buildExamDayResult(),
      ],
    );
  }

  Widget _buildExamSettingsCardForExamDay() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: slate800.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: slate800)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EXAM INFO / 시험 정보 입력', style: GoogleFonts.notoSerif(fontSize: 14, color: goldColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: ['중간고사', '기말고사'].map((type) {
              return Padding(
                padding: const EdgeInsets.only(right: 17.0),
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
                    Text(type, style: GoogleFonts.notoSerif(fontSize: 12, color: Colors.white)),
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
              style: GoogleFonts.notoSerif(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamDayResult() {
    if (_examStartDate == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Text('시험 시작일을 입력하면 D-3 ~ D+4 구간의 정확한 트랙이 자동으로 표시됩니다.',
            style: GoogleFonts.notoSerif(color: slate500, fontSize: 12)),
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
          style: GoogleFonts.notoSerif(color: slate500, fontSize: 12),
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
          style: GoogleFonts.notoSerif(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold),
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
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCustomized)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: goldColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                child: Text('Edited / 편집됨', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            if (isCustomized)
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 30)),
                onPressed: _resetToDefaultSchedule,
                icon: const Icon(Icons.refresh, size: 14, color: Colors.amberAccent),
                label: Text('Reset', style: GoogleFonts.notoSerif(color: Colors.amberAccent, fontSize: 11)),
              ),
          ],
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: slate800,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
          ),
          onPressed: () => _showEditItemDialog(),
          icon: const Icon(Icons.add, size: 14, color: Colors.white),
          label: Text('Add / 항목 추가', style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 11)),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // 공통 리스트 렌더러 ([요청사항 3] 윗줄 영문, 아래줄 한글 2열 배치 적용)
  // ------------------------------------------------------------
  List<Widget> _buildScheduleList(List<Map<String, String>> schedule) {
    if (schedule.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text('No data available / 표시할 데이터가 없습니다.', style: GoogleFonts.notoSerif(color: slate500, fontSize: 14)),
        )
      ];
    }
    return schedule.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, String> item = entry.value;

      final String timeText = item['time'] ?? '';
      final String taskText = item['task'] ?? '';
      final bool timePassed = _isTimePassed(timeText);

      final Color barColor = _getTimelineBarColor(_selectedTrack, timeText, taskText, index);

      final Color timeColor = timePassed ? slate500 : goldColor;
      final Color taskColor = timePassed ? slate400 : Colors.white;

      // taskText를 영어와 한글 영역으로 나누거나 변환 매핑 (예시 형태 유지하며 2열 분리)
      // 한글과 영문이 섞여있는 경우 자동 분리하거나 영문명 부여
      String engText = _getEnglishTaskTranslation(taskText);
      String korText = taskText;

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
              const SizedBox(width: 8),
              Container(
                width: 3.0,
                height: 32.0, // 2줄 레이아웃에 맞춰 세로 바 높이 확장
                color: timePassed ? slate500 : barColor,
              ),
              const SizedBox(width: 10),
              // [요청사항 3] 윗줄 영문, 아래줄 한글 2열 세로 배치 (기존 글자 크기 14 유지)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      engText,
                      style: GoogleFonts.notoSerif(
                        color: taskColor.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      korText,
                      style: GoogleFonts.notoSerif(
                        color: taskColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
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

  // 타임라인 내용 영문 매핑 헬퍼 함수
  String _getEnglishTaskTranslation(String kor) {
    if (kor.contains('기상')) return 'Wake up & Stretching';
    if (kor.contains('아침식사')) return 'Breakfast';
    if (kor.contains('점심')) return 'Lunch & Break';
    if (kor.contains('저녁')) return 'Dinner & Break';
    if (kor.contains('휴식')) return 'Break Time';
    if (kor.contains('수학')) return 'Focused Mathematics';
    if (kor.contains('국어')) return 'Focused Korean Literature';
    if (kor.contains('영어')) return 'Focused English';
    if (kor.contains('과학')) return 'Focused Science';
    if (kor.contains('취침')) return 'Sleep & Bedtime Routine';
    if (kor.contains('학교')) return 'School Schedule';
    return 'Study Session';
  }
}