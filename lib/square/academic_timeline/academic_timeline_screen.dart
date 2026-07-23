import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../planner/widgets/study_timelines.dart';
import '../../timer/timer_screen.dart';

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
  final Color darkGrey = const Color(0xFF333333);

  final List<Color> _rainbowColors = [
    Colors.red,
    Colors.blue,
    Colors.yellow,
    Colors.green,
    Colors.orange,
    Colors.indigo,
    Colors.purple,
  ];

  String _selectedTrack = 'NORMAL_PERIOD';

  // 1. 평상시
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
  bool _isNormalWeekdayExpanded = true;

  // 2. 방학
  DateTime? _vacationStartDate;
  DateTime? _vacationEndDate;
  String? _selectedPomodoroKey;
  bool _isPomodoroFreeModeEnabled = false;
  bool _isVacationStyleExpanded = true;

  // 3 & 4. 시험 공통
  bool _isFinalExamMode = false;
  DateTime? _examStartDate;
  DateTime? _examEndDate; // [추가] 시험 종료일
  int? _manualExamPrepWeek; // [추가] 4/3/2주 수동 선택 (null=날짜 자동계산)
  bool _isExamSettingExpanded = true;
  final List<Map<String, String>> _customExamRecords = [];

  final Map<String, List<Map<String, String>>> _customSchedules = {};
  int? _selectedScheduleIndex; // [추가] 사용자가 선택한 시간표 항목의 인덱스

  @override
  void initState() {
    super.initState();
    _initAutoWeekday();
    _loadAllSettings();
  }

  void _initAutoWeekday() {
    final int weekdayNum = DateTime.now().weekday;
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
  // 설정 저장 / 불러오기 (날짜 파싱 오류 방어 및 동기화 강화)
  // ============================================================
  Future<void> _loadAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? vacStart = prefs.getString('gke_vacation_start_date');
    final String? vacEnd = prefs.getString('gke_vacation_end_date');
    final String? pomodoroKey = prefs.getString('gke_selected_pomodoro_key');
    final bool freeMode = prefs.getBool('gke_pomodoro_free_mode') ?? false;
    final String? examType = prefs.getString('gke_selected_exam_type');
    final String? examStartStr = prefs.getString('gke_exam_start_date');
    final String? examEndStr = prefs.getString('gke_exam_end_date');

    if (mounted) {
      setState(() {
        _vacationStartDate = vacStart != null ? DateTime.tryParse(vacStart) : null;
        _vacationEndDate = vacEnd != null ? DateTime.tryParse(vacEnd) : null;
        _selectedPomodoroKey = pomodoroKey;
        _isPomodoroFreeModeEnabled = freeMode;
        _isFinalExamMode = (examType == '기말고사');
        _examStartDate = examStartStr != null ? DateTime.tryParse(examStartStr) : null;
        _examEndDate = examEndStr != null ? DateTime.tryParse(examEndStr) : null;
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
    if (_examEndDate != null) {
      await prefs.setString('gke_exam_end_date', _examEndDate!.toIso8601String());
    } else {
      await prefs.remove('gke_exam_end_date');
    }
  }

  // ============================================================
  // 데이터 매핑 및 타임라인 연동 로직
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
      final DateTime today = DateTime.now();
      if (_isAfterExamEnd()) {
        final int wd = DateTime.now().weekday;
        final String todayEn = _weekdayOptions[wd - 1]['en']!;
        cacheKey = 'NORMAL_PERIOD_$todayEn';
        defaultList = StudyTimelines.normalPeriod[todayEn] ?? [];
      } else {
        final DateTime cleanToday = DateTime(today.year, today.month, today.day);

        if (_manualExamPrepWeek != null) {
          final String dayType = _calcExamPrepDayTypeForDate(cleanToday, _manualExamPrepWeek!);
          cacheKey = 'EXAM_PREP_${_isFinalExamMode ? "final" : "mid"}_w${_manualExamPrepWeek}_$dayType';
          defaultList = _getExamPrepList(_manualExamPrepWeek!, dayType, _isFinalExamMode);
        } else if (_examStartDate != null) {
          final DateTime cleanExamStart = DateTime(_examStartDate!.year, _examStartDate!.month, _examStartDate!.day);
          final int diffDays = cleanExamStart.difference(cleanToday).inDays;

          if (diffDays >= -3 && diffDays <= 4) {
            defaultList = StudyTimelines.getTimelineForDate(
              cleanToday,
              cleanExamStart,
              isExamPeriod: true,
              isActualExamWeek: true,
              isFinalExam: _isFinalExamMode,
            );
            cacheKey = 'EXAM_PREP_OVERLAP_${_isFinalExamMode ? "final" : "mid"}_diff_$diffDays';
          } else {
            int weekNum = _calcExamPrepWeekNum(diffDays);
            final String dayType = _calcExamPrepDayTypeForDate(cleanToday, weekNum);
            cacheKey = 'EXAM_PREP_${_isFinalExamMode ? "final" : "mid"}_w${weekNum}_$dayType';
            defaultList = _getExamPrepList(weekNum, dayType, _isFinalExamMode);
          }
        } else {
          cacheKey = 'EXAM_PREP_${_isFinalExamMode ? "final" : "mid"}_w4_weekday';
          defaultList = _getExamPrepList(4, 'weekday', _isFinalExamMode);
        }
      }

    } else if (_selectedTrack == 'EXAM_DAY_TRACK') {
      final DateTime today = DateTime.now();
      if (_isAfterExamEnd()) {
        final int wd = DateTime.now().weekday;
        final String todayEn = _weekdayOptions[wd - 1]['en']!;
        return StudyTimelines.normalPeriod[todayEn] ?? [];
      }
      final DateTime cleanToday = DateTime(today.year, today.month, today.day);
      final DateTime cleanExamStart = _examStartDate != null
          ? DateTime(_examStartDate!.year, _examStartDate!.month, _examStartDate!.day)
          : cleanToday;
      final int diff = cleanToday.difference(cleanExamStart).inDays;
      cacheKey = 'EXAM_DAY_${_isFinalExamMode ? "final" : "mid"}_diff_$diff';

      // 7월 20일 시험일 지정 시 D-3(Diff = -3)부터 정확히 타임라인이 표출되도록 방어 로직 적용
      if (_examStartDate != null && diff >= -3 && diff <= 4) {
        defaultList = StudyTimelines.getTimelineForDate(
          cleanToday,
          cleanExamStart,
          isExamPeriod: true,
          isActualExamWeek: true,
          isFinalExam: _isFinalExamMode,
        );
      } else if (_examStartDate != null) {
        defaultList = StudyTimelines.getTimelineForDate(
          cleanToday,
          cleanExamStart,
          isExamPeriod: true,
          isActualExamWeek: diff >= -3 && diff <= 4,
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
      final DateTime today = DateTime.now();
      final DateTime cleanToday = DateTime(today.year, today.month, today.day);
      if (_examStartDate != null) {
        final DateTime cleanExamStart = DateTime(_examStartDate!.year, _examStartDate!.month, _examStartDate!.day);
        final int diffDays = cleanExamStart.difference(cleanToday).inDays;
        if (diffDays >= -3 && diffDays <= 4) {
          return 'EXAM_PREP_OVERLAP_${_isFinalExamMode ? "final" : "mid"}_diff_$diffDays';
        }
        int weekNum = (diffDays > 21) ? 4 : (diffDays > 14 ? 3 : (diffDays > 7 ? 2 : 1));
        final String dayType = _calcExamPrepDayTypeForDate(cleanToday, weekNum);
        return 'EXAM_PREP_${_isFinalExamMode ? "final" : "mid"}_w${weekNum}_$dayType';
      }
      return 'EXAM_PREP_${_isFinalExamMode ? "final" : "mid"}_w4_weekday';
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

  String _calcExamPrepDayTypeForDate(DateTime targetDate, int weekNum) {
    if (weekNum == 1) {
      return targetDate.weekday == 6 ? 'saturday' : (targetDate.weekday == 7 ? 'sunday' : 'weekday');
    } else {
      return (targetDate.weekday == 6 || targetDate.weekday == 7) ? 'weekend' : 'weekday';
    }
  }
// [추가] 주차 계산 통합 (중복 로직 제거)
  int _calcExamPrepWeekNum(int diffDays) {
    if (diffDays > 21) return 4;
    if (diffDays > 14) return 3;
    if (diffDays > 7) return 2;
    return 1;
  }

  // [추가] 시험 종료일 23시가 지났는지 체크 → 지났으면 평일 시간표로 자동 복귀
  bool _isAfterExamEnd() {
    if (_examEndDate == null) return false;
    final DateTime cutoff = DateTime(_examEndDate!.year, _examEndDate!.month, _examEndDate!.day, 23, 0);
    return DateTime.now().isAfter(cutoff);
  }

  // [추가] 'yyyy.m.d' 형식 문자열을 DateTime으로 파싱
  DateTime? _parseRecordDate(String formatted) {
    try {
      final parts = formatted.split('.');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
    } catch (_) {}
    return null;
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
// [추가] "09:00 ~ 09:50" 형식에서 실제 분(分) 길이 계산 (자정 넘김 보정 포함)
  int? _calcDurationMinutes(String timeStr) {
    try {
      final parts = timeStr.split(RegExp(r'[-~–]'));
      if (parts.length < 2) return null;
      final startParts = parts.first.trim().split(':');
      final endParts = parts.last.trim().split(':');
      if (startParts.length < 2 || endParts.length < 2) return null;
      int startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      int endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      if (endMin <= startMin) endMin += 24 * 60;
      return endMin - startMin;
    } catch (_) {
      return null;
    }
  }

  // [추가] TIM 버튼 실행 로직: 사용자가 선택한 항목으로 TimerScreen 이동. 선택 없으면 안내
  void _runTimerAction(List<Map<String, String>> schedule) {
    if (schedule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실행할 시간표 항목이 없습니다.', style: GoogleFonts.notoSerif())),
      );
      return;
    }
    if (_selectedScheduleIndex == null || _selectedScheduleIndex! >= schedule.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('먼저 학습할 시간표 항목을 선택해주세요.', style: GoogleFonts.notoSerif())),
      );
      return;
    }
    final item = schedule[_selectedScheduleIndex!];
    final String taskText = item['task'] ?? '학습';
    final int? durationMinutes = _calcDurationMinutes(item['time'] ?? '');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimerScreen(
          selectedSubject: taskText,
          selectedDurationMinutes: durationMinutes ?? 30,
          dynamicTestTitle: _isFinalExamMode ? '기말고사' : '중간고사',
          targetExamDate: _examStartDate,
          targetExamEndDate: _examEndDate,
          prepPeriodStr: _manualExamPrepWeek != null ? '${_manualExamPrepWeek}주 전' : '',
          needTimelineGen: false,
          selectedSoundFile: '',
          isFinalExamMode: _isFinalExamMode,
        ),
      ),
    );
  }

// [수정] timer_play_btn.png 이미지로 교체된 TIM 실행 버튼
  Widget _buildTimButton(List<Map<String, String>> Function() scheduleGetter) {
    return GestureDetector(
      onTap: () => _runTimerAction(scheduleGetter()),
      child: Image.asset(
        'assets/images/timer_play_btn.png',
        width: 100,
        height: 60,
        fit: BoxFit.contain,
      ),
    );
  }

  Color _getTimelineBarColor(String track, String timeText, String taskText, int index) {
    // [추가] 방학 스타일2의 마지막 항목은 키워드 규칙보다 우선하여 보라색 지정

    if (track == 'VACATION_SUMMER_WINTER' && _selectedPomodoroKey == 'vacationPomodoro2' && index == 33) {
      return Colors.purple;
    }
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
    if (taskText.contains('취침')) {
      return darkGrey;
    }

    // [추가] 방학 스타일 1 전용 구간별 색상 지정
    if (track == 'VACATION_SUMMER_WINTER' && _selectedPomodoroKey == 'vacationPomodoro1') {
      if (index >= 2 && index <= 7) return Colors.red;
      if (index >= 8 && index <= 13) return Colors.blue;
      if (index >= 14 && index <= 19) return Colors.amber; // 노랑
      if (index >= 21 && index <= 26) return Colors.green;
      if (index >= 27 && index <= 32) return Colors.orange;
      if (index >= 34 && index <= 39) return Colors.indigo; // 남색
      if (index >= 40 && index <= 45) return Colors.red;
    }

    // [추가] 방학 스타일 2 전용 구간별 색상 지정
    if (track == 'VACATION_SUMMER_WINTER' && _selectedPomodoroKey == 'vacationPomodoro2') {
      if (index == 2 || index == 3) return Colors.red;
      if (index == 4 || index == 5) return Colors.blue;
      if (index == 6 || index == 7) return Colors.amber;
      if (index == 8 || index == 9) return Colors.green;
      if (index == 10 || index == 11) return Colors.orange;
      if (index == 13 || index == 14) return Colors.green;
      if (index == 15 || index == 16) return Colors.orange;
      if (index == 17 || index == 18) return Colors.indigo;
      if (index == 19 || index == 20) return Colors.red;
      if (index == 21 || index == 22) return Colors.blue;
      if (index == 23 || index == 24) return Colors.amber;
      if (index == 26 || index == 27) return Colors.green;
      if (index == 28 || index == 29) return Colors.orange;
      if (index == 30 || index == 31) return Colors.indigo;
      if (index == 32) return Colors.red;
    }

    // [추가] 방학 스타일 3 전용 구간별 색상 지정
    if (track == 'VACATION_SUMMER_WINTER' && _selectedPomodoroKey == 'vacationPomodoro3') {
      if (index >= 2 && index <= 7) return Colors.red;
      if (index >= 8 && index <= 13) return Colors.blue;
      if (index >= 15 && index <= 20) return Colors.amber;
      if (index >= 22 && index <= 27) return Colors.green;
      if (index == 28 || index == 29) return Colors.indigo;
    }

    // [추가] 방학 스타일 4 전용 구간별 색상 지정
    if (track == 'VACATION_SUMMER_WINTER' && _selectedPomodoroKey == 'vacationPomodoro4') {
      if (index >= 2 && index <= 5) return Colors.red;
      if (index >= 6 && index <= 9) return Colors.blue;
      if (index >= 11 && index <= 14) return Colors.amber;
      if (index >= 15 && index <= 18) return Colors.green;
      if (index >= 20 && index <= 22) return Colors.indigo;
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

    return _rainbowColors[index % _rainbowColors.length];
  }

  // ============================================================
  // 효율적인 연속 입력 달력 및 일괄 저장 시스템 (오버플로우 및 커서 튀는 현상 완벽 해결)
  // ============================================================
  Future<void> _handleExamRecordFlow() async {
    List<Map<String, String>> sessionRecords = [];
    DateTime? nextTargetDate = firstSelectedDateOrDefault();
    bool isAdding = true;

    while (isAdding) {
      // [요구사항 2] 달력 색상 및 선택 날짜 황금색 강조 적용, 연속 입력 시 다음 날짜로 포커스 이동 유지
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: nextTargetDate ?? DateTime.now(),
        firstDate: DateTime(2024),
        lastDate: DateTime(2035),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: goldColor,
                onPrimary: const Color(0xFF020617),
                surface: const Color(0xFF0B0F19),
                onSurface: Colors.white,
              ),
              dialogBackgroundColor: const Color(0xFF0B0F19),
            ),
            child: child!,
          );
        },
      );

      if (pickedDate == null) {
        return;
      }

      nextTargetDate = pickedDate.add(const Duration(days: 1)); // 다음 날짜 자동 포커스 준비
      String formattedDate = '${pickedDate.year}.${pickedDate.month}.${pickedDate.day}';

      if (!mounted) return;

      final TextEditingController subjectController = TextEditingController();
      final TextEditingController scopeController = TextEditingController();

      // [요구사항 1] 팝업 내부 버튼 그룹 오버플로우 방지를 위한 Flexible/Wrap 구조 적용 및 우아한 디자인 유지
      String? actionType = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0B0F19),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
              side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MISSION DETAILS',
                  style: GoogleFonts.notoSerif(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  '[$formattedDate] 학습 계획 상세 조회',
                  style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Divider(color: Color(0xFF1E293B), height: 1),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⏰ SUBJECT / 시험 과목', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: subjectController,
                    style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '예: 수학 (함수 ~ 미적분)',
                      hintStyle: GoogleFonts.notoSerif(color: slate500, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF1E293B).withValues(alpha: 0.5),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: slate800)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: goldColor)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('📚 SCOPE / 시험 범위', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: scopeController,
                    style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '예: 교과서 p.12 ~ p.45',
                      hintStyle: GoogleFonts.notoSerif(color: slate500, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF1E293B).withValues(alpha: 0.5),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: slate800)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: goldColor)),
                    ),
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancel'),
                child: Text('CLOSE', style: GoogleFonts.notoSerif(color: slate400, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: goldColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      if (subjectController.text.trim().isEmpty) return;
                      Navigator.pop(context, 'next');
                    },
                    child: Text('NEXT', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      if (subjectController.text.trim().isEmpty) return;
                      Navigator.pop(context, 'save');
                    },
                    child: Text('SAVE', style: GoogleFonts.notoSerif(color: const Color(0xFF020617), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
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
          backgroundColor: const Color(0xFF0B0F19),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
          ),
          title: Text(
            'Save Exam Schedule / 시험 일정 저장',
            style: GoogleFonts.notoSerif(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: Text(
            '시험 일정과 과목이 적용됩니다. 저장하시겠습니까?',
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

      // [추가] 등록된 시험 기록의 최소/최대 날짜로 시험 시작일·종료일 자동 연동
      List<DateTime> allDates = _customExamRecords
          .map((r) => _parseRecordDate(r['date'] ?? ''))
          .whereType<DateTime>()
          .toList();
      if (allDates.isNotEmpty) {
        allDates.sort();
        setState(() {
          _examStartDate = allDates.first;
          _examEndDate = allDates.last;
        });
        await _saveExamSettings();
      }
    }
  }

  DateTime firstSelectedDateOrDefault() {
    if (_examStartDate != null) return _examStartDate!;
    return DateTime.now();
  }

  void _showEditExamRecordDialog(int index) {
    final record = _customExamRecords[index];
    final TextEditingController subjectController = TextEditingController(text: record['subject']);
    final TextEditingController scopeController = TextEditingController(text: record['scope']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0B0F19),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
          ),
          title: Text(
            '[${record['date']}] EDIT MODE RUN / 수정 및 삭제',
            style: GoogleFonts.notoSerif(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'SUBJECT OR TITLE / 시험 과목',
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
                  labelText: 'MEMO / DETAILS / 시험 범위',
                  labelStyle: GoogleFonts.notoSerif(color: slate400, fontSize: 12),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: slate800)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _customExamRecords.removeAt(index);
                });
                Navigator.pop(context);
              },
              child: Text('DELETE / 삭제', style: GoogleFonts.notoSerif(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
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
              child: Text('SAVE / 저장', style: GoogleFonts.notoSerif(color: const Color(0xFF020617), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showEditItemDialog({int? index, String? initialTime, String? initialTask}) {
    final TextEditingController timeController = TextEditingController(text: initialTime ?? '');
    final TextEditingController taskController = TextEditingController(text: initialTask ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0B0F19),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
          ),
          title: Text(
            index == null ? 'ADD SCHEDULE / 타임라인 항목 추가' : 'EDIT MODE RUN / 수정 및 삭제',
            style: GoogleFonts.notoSerif(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: timeController,
                style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'TIME / 시간 (예: 09:00 - 10:00)',
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
                  labelText: 'CONTENT / 내용',
                  labelStyle: GoogleFonts.notoSerif(color: slate400, fontSize: 12),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: slate800)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
                ),
              ),
            ],
          ),
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
                      child: Text('DELETE / 삭제', style: GoogleFonts.notoSerif(color: Colors.redAccent, fontSize: 12)),
                    ),
                  ),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('CLOSE / 닫기', style: GoogleFonts.notoSerif(color: slate400, fontSize: 12)),
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
                    child: Text('SAVE / 저장', style: GoogleFonts.notoSerif(color: const Color(0xFF020617), fontSize: 12, fontWeight: FontWeight.bold)),
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
          backgroundColor: const Color(0xFF0B0F19),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        automaticallyImplyLeading: false,
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
      onPressed: () => setState(() {
        _selectedTrack = trackKey;
        _selectedScheduleIndex = null;
      }),

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

  Widget _buildNormalPeriodBody() {
    List<Map<String, String>> schedule = _getCurrentActiveSchedule();

    final currentSelectedObj = _weekdayOptions.firstWhere((d) => d['en'] == _selectedWeekdayEn, orElse: () => _weekdayOptions[0]);
    // [수정] 평상시 화면에서는 D-day 대신 현재 선택된 요일을 표시 (요일 펼침메뉴가 접혀있어도 바로 확인 가능)
    final String dDayText = '${currentSelectedObj['abbr']} / ${currentSelectedObj['ko']}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NORMAL PERIOD', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('평상시 기본 타임라인 - 오늘 요일 자동', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buildTimButton(() => _getCurrentActiveSchedule()),
          ],
        ),
        const SizedBox(height: 12),
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
              'Select Weekday/요일선택 (${currentSelectedObj['abbr']} / ${currentSelectedObj['ko']})',
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
                    fontSize: 15,
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
  // 2. 방학 바디 (시작일 ~ 종료일 완벽 표출 반영)
  // ------------------------------------------------------------
  Widget _buildVacationBody() {
    List<Map<String, String>> schedule = _getCurrentActiveSchedule();

    String vacationPeriodDisplay = '방학 기간 미설정';
    if (_vacationStartDate != null && _vacationEndDate != null) {
      vacationPeriodDisplay = '방학 기간: ${_vacationStartDate!.year}.${_vacationStartDate!.month}.${_vacationStartDate!.day} ~ ${_vacationEndDate!.year}.${_vacationEndDate!.month}.${_vacationEndDate!.day}';
    } else if (_vacationStartDate != null) {
      vacationPeriodDisplay = '방학 시작일: ${_vacationStartDate!.year}.${_vacationStartDate!.month}.${_vacationStartDate!.day} ~ (종료일 미설정)';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('VACATION SUMMER/WINTER', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('방학 포모도로 타임라인 - 기간 및 스타일 설정', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buildTimButton(() => _getCurrentActiveSchedule()),
          ],
        ),
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
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: ColorScheme.dark(primary: goldColor, onPrimary: const Color(0xFF020617), surface: const Color(0xFF0B0F19), onSurface: Colors.white),
                                dialogBackgroundColor: const Color(0xFF0B0F19),
                              ),
                              child: child!,
                            );
                          },
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
                        style: GoogleFonts.notoSerif(fontSize: 14, color: Colors.white),
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
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: ColorScheme.dark(primary: goldColor, onPrimary: const Color(0xFF020617), surface: const Color(0xFF0B0F19), onSurface: Colors.white),
                                dialogBackgroundColor: const Color(0xFF0B0F19),
                              ),
                              child: child!,
                            );
                          },
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
                        style: GoogleFonts.notoSerif(fontSize: 14, color: Colors.white),
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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'POMODORO STYLE',
                  style: GoogleFonts.notoSerif(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  '포모도로 스타일 (직접 선택)',
                  style: GoogleFonts.notoSerif(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
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
          Builder(builder: (context) {
            // [추가] "Style 2 (Focus 40m) / 스타일 2 (집중 40분형)" 형식을 영문/한글 두 줄로 분리
            final String fullName = _getPomodoroDisplayName(_selectedPomodoroKey!);
            final List<String> parts = fullName.split(' / ');
            final String enPart = parts.isNotEmpty ? parts[0] : fullName;
            final String koPart = parts.length > 1 ? parts[1] : '';

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enPart,
                        style: GoogleFonts.notoSerif(color: goldColor.withValues(alpha: 0.8), fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      if (koPart.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          koPart,
                          style: GoogleFonts.notoSerif(color: goldColor.withValues(alpha: 0.7), fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildAddButton(), // [추가] 오른쪽 끝에 항목 추가 버튼
              ],
            );
          }),
          const SizedBox(height: 10),
          _buildScheduleHeaderBar(showAddButton: false), // [수정] Add는 위에서 이미 표시했으므로 Edited/Reset만
          const SizedBox(height: 5),
          ..._buildScheduleList(schedule),
        ],
      ],
    );
  }

  // ------------------------------------------------------------
  // 3. 시험 준비 바디 (시험 시작일 정확한 날짜 연동 표출 반영)
  // ------------------------------------------------------------
  Widget _buildExamPrepBody() {
    List<Map<String, String>> schedule = _getCurrentActiveSchedule();

    String dDayDisplay = '';
    String examDateText = '시험 시작일(D-day) 설정';
    if (_examStartDate != null) {
      examDateText = '시험 시작일: ${_examStartDate!.year}.${_examStartDate!.month}.${_examStartDate!.day}';
      final DateTime today = DateTime.now();
      final DateTime cleanToday = DateTime(today.year, today.month, today.day);
      final DateTime cleanExamStart = DateTime(_examStartDate!.year, _examStartDate!.month, _examStartDate!.day);
      final int diff = cleanExamStart.difference(cleanToday).inDays;
      if (diff == 0) {
        dDayDisplay = ' (D-Day)';
      } else if (diff > 0) {
        dDayDisplay = ' (D-$diff)';
      } else {
        dDayDisplay = ' (D+${diff.abs()})';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('EXAM PREP PERIOD', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 17, fontWeight: FontWeight.bold)),
        Text('시험 준비 타임라인 - 시험 정보 및 날짜별 자동 연동',
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
                  '(${_isFinalExamMode ? "Final/기말" : "Mid/중간"})',
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
                    Row(
                      children: [4, 3, 2].map((w) {
                        bool sel = _manualExamPrepWeek == w;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: w != 2 ? 6 : 0),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: sel ? goldColor : null,
                                side: BorderSide(color: goldColor),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              onPressed: () {
                                setState(() {
                                  _manualExamPrepWeek = sel ? null : w;
                                });
                              },
                              child: Text(
                                '시험$w주 전',
                                style: GoogleFonts.notoSerif(
                                  color: sel ? const Color(0xFF020617) : goldColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 3, right: 4),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Colors.redAccent),
                        ),
                        Expanded(
                          child: Text(
                            '선택 시 날짜와 무관하게 해당 주차 시간표를 미리 봅니다. 다시 누르면 해제(자동계산으로 복귀).',
                            style: GoogleFonts.notoSerif(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (_manualExamPrepWeek != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.redAccent),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.redAccent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '지금 "시험$_manualExamPrepWeek주 전" 수동 미리보기 중입니다 (오늘 날짜 자동계산 아님)',
                                style: GoogleFonts.notoSerif(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(side: BorderSide(color: slate800)),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _examStartDate ?? DateTime.now(),
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2035),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.dark().copyWith(
                                      colorScheme: ColorScheme.dark(primary: goldColor, onPrimary: const Color(0xFF020617), surface: const Color(0xFF0B0F19), onSurface: Colors.white),
                                      dialogBackgroundColor: const Color(0xFF0B0F19),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  _examStartDate = picked;
                                });
                                await _saveExamSettings();
                              }
                            },
                            child: Text(
                              _examStartDate == null ? '시작일 선택' : '${_examStartDate!.year}.${_examStartDate!.month}.${_examStartDate!.day}',
                              style: GoogleFonts.notoSerif(fontSize: 12, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('~', style: GoogleFonts.notoSerif(color: slate400)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(side: BorderSide(color: slate800)),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _examEndDate ?? (_examStartDate ?? DateTime.now()),
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2035),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.dark().copyWith(
                                      colorScheme: ColorScheme.dark(primary: goldColor, onPrimary: const Color(0xFF020617), surface: const Color(0xFF0B0F19), onSurface: Colors.white),
                                      dialogBackgroundColor: const Color(0xFF0B0F19),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  _examEndDate = picked;
                                });
                                await _saveExamSettings();
                              }
                            },
                            child: Text(
                              _examEndDate == null ? '종료일 선택' : '${_examEndDate!.year}.${_examEndDate!.month}.${_examEndDate!.day}',
                              style: GoogleFonts.notoSerif(fontSize: 12, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: goldColor),
                      onPressed: _handleExamRecordFlow,
                      icon: const Icon(Icons.calendar_today, size: 14, color: Color(0xFF020617)),
                      label: Text('시험 과목 및 범위 기록 추가 (연속 입력)', style: GoogleFonts.notoSerif(color: const Color(0xFF020617), fontSize: 13, fontWeight: FontWeight.bold)),
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

        // 그려주신 스케치 구조 반영: 좌측(타이틀 + 추가 버튼) vs 우측(TIM 실행 버튼) 배치
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_isFinalExamMode ? "기말고사" : "중간고사"} 준비 타임라인$dDayDisplay',
                    style: GoogleFonts.notoSerif(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAddButton(), // [수정] 제목 바로 아래, 왼쪽 정렬로 세로 배치
                      const SizedBox(width: 8),
                      _buildScheduleHeaderBar(showAddButton: false), // Edited/Reset 표시 (있을 때만)
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildTimButton(() => _getCurrentActiveSchedule()), // [수정] 오른쪽에 독립 배치
          ],
        ),
        const SizedBox(height: 12),
        ..._buildScheduleList(schedule),
      ],
    );
  }

  // ------------------------------------------------------------
  // 4. 시험 당일 트랙
  // ------------------------------------------------------------
  Widget _buildExamDayBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EXAM DAY TRACK', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('시험 당일 D-day 타임라인 - 자동 계산',
                      style: GoogleFonts.notoSerif(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buildTimButton(() => _getCurrentActiveSchedule()),
          ],
        ),
        const SizedBox(height: 16),
        _buildExamSettingsCardForExamDay(),
        const Divider(color: Color(0xFF1E293B), height: 30),
        _buildExamDayResult(),
      ],
    );
  }

  Widget _buildExamSettingsCardForExamDay() {
    String examDateText = '시험 시작일(D-day) 선택';
    if (_examStartDate != null) {
      examDateText = '시험 시작일: ${_examStartDate!.year}.${_examStartDate!.month}.${_examStartDate!.day}';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: slate800.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: slate800)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EXAM INFO / 시험 정보 입력', style: GoogleFonts.notoSerif(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold)),
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
                    Text(type, style: GoogleFonts.notoSerif(fontSize: 13, color: Colors.white)),
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
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: ColorScheme.dark(primary: goldColor, onPrimary: const Color(0xFF020617), surface: const Color(0xFF0B0F19), onSurface: Colors.white),
                      dialogBackgroundColor: const Color(0xFF0B0F19),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _examStartDate = picked;
                });
                await _saveExamSettings();
              }
            },
            child: Text(
              examDateText,
              style: GoogleFonts.notoSerif(fontSize: 15, color: Colors.white),
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
            style: GoogleFonts.notoSerif(color: slate500, fontSize: 13)),
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_isFinalExamMode ? "Final" : "Mid-term"} Exam Day Track ($dDayLabel)',
                    style: GoogleFonts.notoSerif(color: goldColor, fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 1, // [추가] 한 줄로 제한
                    overflow: TextOverflow.ellipsis, // [추가] 넘치면 "..." 표시
                  ),
                  Text(
                    '${_isFinalExamMode ? "기말고사" : "중간고사"} 시험 당일 트랙 ($dDayLabel)',
                    style: GoogleFonts.notoSerif(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildAddButton(),
          ],
        ),
        const SizedBox(height: 12),
        _buildScheduleHeaderBar(showAddButton: false),
        const SizedBox(height: 8),
        ..._buildScheduleList(schedule),
      ],
    );
  }

// [추가] "+Add/항목 추가" 버튼만 별도로 분리 (시험준비 화면에서 재사용하기 위함)
  Widget _buildAddButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: slate800,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
      ),
      onPressed: () => _showEditItemDialog(),
      icon: const Icon(Icons.add, size: 14, color: Colors.white),
      label: Text('Add / 항목 추가', style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 11)),
    );
  }

  Widget _buildScheduleHeaderBar({bool showAddButton = true}) {
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
        if (showAddButton) const SizedBox(width: 8),
        if (showAddButton) _buildAddButton(),
      ],
    );
  }
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

      String engText = _getEnglishTaskTranslation(taskText);
      String korText = taskText;
      final bool isSelected = _selectedScheduleIndex == index;

      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedScheduleIndex = isSelected ? null : index;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? goldColor.withValues(alpha: 0.18)
                : (timePassed ? const Color(0xFF0F172A) : const Color(0xFF1E293B)),
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: goldColor, width: 2)
                : (timePassed ? Border.all(color: slate800.withValues(alpha: 0.5)) : null),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 92,
                child: Text(
                  timeText,
                  style: GoogleFonts.notoSerif(
                    color: isSelected ? goldColor : timeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 3.0,
                height: 32.0,
                color: isSelected ? goldColor : (timePassed ? slate500 : barColor),
              ),
              const SizedBox(width: 10),
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
                      korTest(korText),
                      style: GoogleFonts.notoSerif(
                        color: isSelected ? Colors.white : taskColor,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, size: 20, color: Colors.amberAccent)
              else
                GestureDetector(
                  behavior: HitTestBehavior.opaque, // [추가] 투명 영역까지 탭 인식되도록
                  onTap: () => _showEditItemDialog(
                    index: index,
                    initialTime: timeText,
                    initialTask: taskText,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10), // [추가] 탭 가능 영역을 눈에 보이는 것보다 넓게 확장
                    child: Icon(
                      Icons.edit,
                      size: 14,
                      color: timePassed ? slate500 : const Color(0xFF64748B),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  String korTest(String kor) {
    return kor;
  }

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