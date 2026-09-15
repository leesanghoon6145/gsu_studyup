// today_exercise_screen.dart
//
// 종목 카드를 탭하면 진입하는 기록 입력 화면.
// - 상단: 공통 필드 (날짜/시간/RPE/심박수/메모)
// - 하단: 선택한 종목(ExerciseType)의 상세 필드를 스키마 기반으로 동적 렌더링
// - 저장 시 exercise_calculations.dart의 공식으로 계산필드(isCalculated)를 채워
//   ExerciseRecord를 완성한 뒤 exercise_data_service.dart에 저장한다.

import 'dart:async'; // 🆕 [화면 실시간 표시] StreamSubscription 사용
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // 🆕 [일별 걸음수 그래프]
import 'package:shared_preferences/shared_preferences.dart'; // ✅ [2026-09-13 추가] 설정안내 팝업의 "오늘 그만 보기" 저장용
import 'package:permission_handler/permission_handler.dart'; // ✅ [2026-09-14 추가] 영구거부 시 설정으로 바로 이동시키는 openAppSettings() 사용
import 'package:google_fonts/google_fonts.dart';
import 'exercise_models.dart';
import 'exercise_data_service.dart';
import 'exercise_calculations.dart';
import 'exercise_theme.dart';
import 'app_language_service.dart'; // ✅ [2026-09-06 추가] appLanguage 접근용 (exercise_theme.dart가 재수출하지만 명시적으로도 import)
import 'exercise_step_service.dart'; // 🆕 [만보기 연동 1단계+매일 자동기록] StepTrackingSession, DailyStepWatcherService
import 'exercise_profile_service.dart'; // 🆕 [개인정보 - 칼로리 계산용] 저장된 몸무게 반영
import 'exercise_i18n.dart'; // ✅ [2026-09-06 추가] 필드/옵션/RPE 10개국어 번역 사전
import 'exercise_type_analysis_screen.dart'; // ✅ [2026-09-13 추가] 하단 "운동분석" 탭 진입용

class TodayExerciseScreen extends StatefulWidget {
  final ExerciseType exerciseType;
  final ExerciseRecord? existingRecord; // null이면 신규 기록

  const TodayExerciseScreen({
    super.key,
    required this.exerciseType,
    this.existingRecord,
  });

  @override
  State<TodayExerciseScreen> createState() => _TodayExerciseScreenState();
}

class _SetRow {
  final TextEditingController weight = TextEditingController();
  final TextEditingController reps = TextEditingController();
  int rpe = 7;
}

class _TodayExerciseScreenState extends State<TodayExerciseScreen> {
  final _service = ExerciseDataService.instance;

  // 🆕 [일별 걸음수 그래프] 요일별 고정 무지개색 (월=빨강 ~ 일=보라).
  // DateTime.weekday: 1=월 ... 7=일 이므로 인덱스는 weekday-1
  static const List<Color> _rainbowWeekColors = [
    Color(0xFFEF4444), // 월 - 빨강
    Color(0xFFF97316), // 화 - 주황
    Color(0xFFFACC15), // 수 - 노랑
    Color(0xFF22C55E), // 목 - 초록
    Color(0xFF3B82F6), // 금 - 파랑
    Color(0xFF4338CA), // 토 - 남색
    Color(0xFF8B5CF6), // 일 - 보라
  ];

  DateTime _date = DateTime.now();
  final _durationController = TextEditingController(text: '30');
  int _rpe = 5;
  final _avgHrController = TextEditingController();
  final _maxHrController = TextEditingController();
  final _memoController = TextEditingController();

  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, String?> _selectValues = {};
  final Map<String, List<String>> _multiSelectValues = {}; // 🆕 [중복선택] 헬스 운동부위/수영 영법/요가 유형용
  final Map<String, int> _counterValues = {};
  final List<_SetRow> _setRows = [];

  // 🆕 [만보기 연동 1단계] 걸음수 자동 측정 상태
  StepTrackingSession? _stepSession;
  bool _isStepTracking = false;
  bool _stepUnavailable = false;
  int _autoSteps = 0;
  DateTime? _stepTrackingStartTime;

  // 🆕 [매일 자동기록] "매일 자동 기록" 토글의 현재 상태 (SharedPreferences에서 로드)
  bool _dailyAutoEnabled = false;

  // 🆕 [개인정보 - 칼로리 계산용] 저장된 몸무게. 화면 열 때 한 번 불러와서
  // 계속 재사용(칼로리 계산 콜백들이 동기 함수라 그때그때 비동기 조회를 못 함).
  double _bodyWeightKg = ExerciseProfileService.defaultWeightKg;

  // 🆕 [일별 걸음수 그래프 - 스크롤] 최근 30일치를 불러와서 좌우로 스크롤해
  // 과거까지 볼 수 있게 함. 처음 열었을 때는 오늘(가장 오른쪽)이 보이도록
  // 자동으로 맨 끝까지 스크롤함.
  static const int _stepsHistoryDays = 30;
  final ScrollController _stepsChartScrollController = ScrollController();
  final ScrollController _durationChartScrollController = ScrollController(); // 🆕 [8번] 걷기의 시간 그래프용 - 걸음수 그래프와 별개 스크롤
  Future<Map<String, int>>? _stepsHistoryFuture; // 🆕 매 rebuild마다 다시 안 불러오게 캐시
  Future<Map<String, int>>? _durationHistoryFuture; // 🆕 [8번] 모든 종목 공통 - 운동시간(분) 히스토리

  // 🆕 [화면 실시간 표시] 뒤에서 돌아가는 매일 자동기록의 "오늘 걸음수"를 화면에
  // 실시간으로 보여주기 위한 구독. 이게 없으면 자동 기록이 실제로 잘 되고 있어도
  // 화면에서는 전혀 확인할 방법이 없었음.
  StreamSubscription<int>? _liveStepsSub;
  int? _liveAutoSteps;

  bool get _isEditMode => widget.existingRecord != null;

  // 🆕 [만보기 연동 1단계] 이 종목이 '걸음수(steps)' 필드를 갖고 있을 때만
  // 자동 측정 카드를 보여준다 (걷기 외에 나중에 다른 종목이 steps 필드를
  // 추가해도 자동으로 지원됨 - 종목 id를 하드코딩하지 않음).
  bool get _hasStepsField => widget.exerciseType.fields.any((f) => f.key == 'steps');

  @override
  void initState() {
    super.initState();
    // 🆕 [8번] 시간(분) 그래프는 모든 종목 공통으로 항상 로드
    _durationHistoryFuture = _loadDurationByDate();
    // 🆕 [걸음수 그래프] 걷기류(steps 필드가 있는 종목)에서만 별도로 로드
    if (_hasStepsField) _stepsHistoryFuture = _loadStepsByDate();
    // 🆕 [개인정보 - 칼로리 계산용] 저장된 몸무게 불러오기 (없으면 평균값 유지)
    ExerciseProfileService.getWeightKgOrDefault().then((w) {
      if (mounted) setState(() => _bodyWeightKg = w);
    });
    if (_hasStepsField) {
      _loadDailyAutoState(); // 🆕 [매일 자동기록] 토글 초기 상태 불러오기
      ExerciseStepService.loadPreferredSource().then((_) {
        if (mounted) setState(() {}); // 🆕 [2단계] 폰/워치 선택 상태를 화면에 반영
      });
      _loadLiveAutoSteps(); // 🆕 [화면 실시간 표시] 저장된 오늘 값 먼저 보여주고
      _liveStepsSub = DailyStepWatcherService.instance.liveTodaySteps.listen((steps) {
        if (mounted) setState(() => _liveAutoSteps = steps);
      }); // 🆕 이후로는 실시간 갱신값을 계속 반영
    }
    for (final field in widget.exerciseType.fields) {
      if (field.isCalculated) continue;
      switch (field.type) {
        case ExerciseFieldType.number:
        case ExerciseFieldType.duration:
        case ExerciseFieldType.text:
          _textControllers[field.key] = TextEditingController();
          break;
        case ExerciseFieldType.select:
          _selectValues[field.key] = null;
          break;
        case ExerciseFieldType.multiSelect: // 🆕 [중복선택]
          _multiSelectValues[field.key] = [];
          break;
        case ExerciseFieldType.counter:
          _counterValues[field.key] = 0;
          break;
        case ExerciseFieldType.multiSet:
          _setRows.add(_SetRow());
          break;
      }
    }

    final existing = widget.existingRecord;
    if (existing != null) {
      _date = existing.date;
      _durationController.text = existing.durationMin.toString();
      _rpe = existing.rpe ?? 5;
      _avgHrController.text = existing.avgHeartRateBpm?.toString() ?? '';
      _maxHrController.text = existing.maxHeartRateBpm?.toString() ?? '';
      _memoController.text = existing.memo;
      existing.detail.forEach((key, value) {
        if (_textControllers.containsKey(key)) {
          _textControllers[key]!.text = value.toString();
        } else if (_selectValues.containsKey(key)) {
          _selectValues[key] = value as String?;
        } else if (_multiSelectValues.containsKey(key)) { // 🆕 [중복선택]
          _multiSelectValues[key] = (value as List).map((e) => e.toString()).toList();
        } else if (_counterValues.containsKey(key)) {
          _counterValues[key] = value as int;
        }
      });
    }
  }

  @override
  void dispose() {
    _stepSession?.dispose(); // 🆕 [만보기 연동 1단계] 측정 중이었다면 스트림 구독 해제
    _liveStepsSub?.cancel(); // 🆕 [화면 실시간 표시] 화면을 나가면 구독 해제
    _stepsChartScrollController.dispose(); // 🆕 [일별 걸음수 그래프 - 스크롤]
    _durationChartScrollController.dispose(); // 🆕 [8번] 시간 그래프 - 스크롤
    _durationController.dispose();
    _avgHrController.dispose();
    _maxHrController.dispose();
    _memoController.dispose();
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // 🆕 [전 종목 세부기록 영문 보완] 필드 라벨을 "English (한글)" 한 줄로 합쳐서
  // InputDecoration.labelText처럼 단일 문자열만 받는 자리에도 바로 쓸 수 있게 함.
  // enLabel이 없는(커스텀) 필드는 한글 라벨만 그대로 보여줌(하위호환).
  // ✅ [2026-09-06 개편] 언어선택 상태(appLanguage)까지 반영하도록 확장.
  // - 기본(EN/KO) 모드: "English (한글)" 형태 그대로 유지
  // - 10개국어 중 하나 선택: exercise_i18n.dart의 사전에서 그 언어 번역을 찾아 보여줌
  //   (사전에 없으면 영문으로, 영문도 없으면 한글 그대로 - 안전하게 단계적으로 대체)
  // ✅ [2026-09-13 추가 - 고급 디자인] 종목의 필드 목록을 section(구획) 단위로
  // 묶어서, 구획이 바뀔 때마다 골드색 소제목+구분선을 넣어 "정리된 명세서"
  // 느낌으로 보여준다. 숫자/카운터처럼 짧은 값 입력 필드는 한 줄에 2개씩
  // 나란히 배치해서, 항목이 12~16개로 늘어나도 스크롤이 과하게 길어지지
  // 않게 한다. section이 없는(커스텀) 필드는 예전처럼 구획 없이 한 줄씩 표시.
  List<Widget> _buildSectionedFields(List<ExerciseField> fields) {
    final List<Widget> widgets = [];
    String? currentSection;
    final List<ExerciseField> pendingShortFields = [];

    void flushShortFields() {
      if (pendingShortFields.isEmpty) return;
      for (int i = 0; i < pendingShortFields.length; i += 2) {
        final ExerciseField first = pendingShortFields[i];
        final ExerciseField? second = (i + 1 < pendingShortFields.length) ? pendingShortFields[i + 1] : null;
        widgets.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildField(first)),
            const SizedBox(width: 10),
            Expanded(child: second != null ? _buildField(second) : const SizedBox.shrink()),
          ],
        ));
      }
      pendingShortFields.clear();
    }

    bool isShortField(ExerciseField f) => f.type == ExerciseFieldType.number || f.type == ExerciseFieldType.counter;

    for (final field in fields) {
      if (field.section != currentSection) {
        flushShortFields();
        currentSection = field.section;
        if (currentSection != null) {
          widgets.add(_buildSectionHeader(field.sectionEn ?? currentSection!, currentSection!));
        }
      }
      if (isShortField(field)) {
        pendingShortFields.add(field);
      } else {
        flushShortFields();
        widgets.add(_buildField(field));
      }
    }
    flushShortFields();
    return widgets;
  }

  // ✅ [2026-09-13 추가 - 고급 디자인] 골드 세로 악센트 바 + 영문 소문자(스몰캡스
  // 느낌) + 한글 + 옅어지는 골드 구분선으로 구성된 구획 소제목.
  Widget _buildSectionHeader(String en, String ko) {
    // ✅ [2026-09-14 버그 수정] EN+KO를 한 줄(Row)에 같이 넣다 보니, 이름이 긴
    // 구획("페어웨이 · 그린 · 페널티" 등)에서 화면 밖으로 밀려 오버플로우가
    // 났다. EN은 위, KO는 아래로 나눠서 각자 한 줄씩 차지하게 하고, 그래도
    // 넘칠 만큼 길면 말줄임(...)으로 안전하게 자르도록 재구성.
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 15, decoration: BoxDecoration(color: ExerciseTheme.brandGolden, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  en.toUpperCase(),
                  style: GoogleFonts.gowunBatang(color: ExerciseTheme.brandGolden, fontWeight: FontWeight.bold, fontSize: 10.5, letterSpacing: 0.6),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 11, top: 2),
            child: Text(
              ko,
              style: GoogleFonts.notoSansKr(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [ExerciseTheme.brandGolden.withOpacity(0.35), ExerciseTheme.brandGolden.withOpacity(0.0)]),
            ),
          ),
        ],
      ),
    );
  }

  String _bilabel(ExerciseField field) {
    if (field.enLabel == null || field.enLabel!.isEmpty) return field.label;
    if (appLanguage.isForeignSelected) {
      final String? translated = kExerciseTermTranslations[field.enLabel]?[appLanguage.current];
      return translated ?? field.enLabel!;
    }
    return '${field.enLabel} (${field.label})';
  }

  // ✅ [2026-09-06 추가] select/multiSelect 옵션 값(한글, 실제 저장값) 하나를 화면에
  // 보여줄 때 언어선택 상태에 맞게 변환. 원리는 _bilabel과 동일함.
  String _optionLabel(ExerciseField field, String value) {
    if (field.options == null || field.optionEnLabels == null) return value;
    final int idx = field.options!.indexOf(value);
    if (idx < 0 || idx >= field.optionEnLabels!.length) return value;
    final String en = field.optionEnLabels![idx];
    if (en.isEmpty) return value;
    if (appLanguage.isForeignSelected) {
      final String? translated = kExerciseTermTranslations[en]?[appLanguage.current];
      return translated ?? en;
    }
    return '$en ($value)';
  }

  InputDecoration _decoration(String label, {String? unit}) => InputDecoration(
    labelText: label.isEmpty ? null : label,
    suffixText: unit,
    labelStyle: ExerciseTheme.bodyStyle(size: 13),
    suffixStyle: ExerciseTheme.bodyStyle(size: 12),
    filled: true,
    fillColor: ExerciseTheme.containerBg,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: ExerciseTheme.brandGolden.withOpacity(0.25)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: ExerciseTheme.brandGolden.withOpacity(0.25)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ExerciseTheme.brandGolden),
    ),
  );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: ExerciseTheme.brandGolden,
            surface: ExerciseTheme.containerBgElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  // ---------------------------------------------------------------------
  // 🆕 [매일 자동기록] 자정 기준 매일 자동 걸음수 기록 토글
  // ---------------------------------------------------------------------

  // 🆕 [화면 실시간 표시] 화면을 열었을 때, 다음 스트림 이벤트를 기다리지 않고
  // 이미 저장되어 있는 오늘 자동기록 걸음수를 바로 보여줌.
  Future<void> _loadLiveAutoSteps() async {
    final saved = await DailyStepWatcherService.instance.getTodaySavedSteps();
    if (mounted && saved != null) setState(() => _liveAutoSteps = saved);
  }

  Future<void> _loadDailyAutoState() async {
    final enabled = await DailyStepWatcherService.instance.isEnabled();
    if (mounted) setState(() => _dailyAutoEnabled = enabled);
  }

  // ✅ [2026-09-13 추가] 폰/워치 칩을 탭하면 실제 소스 전환 전에 설정 방법
  // 안내 팝업을 먼저 보여줌. "오늘 그만 보기"를 누른 적이 있으면(오늘 날짜
  // 기준) 건너뛰고 바로 전환한다.
  static const String _kHidePopupKeyPrefix = 'gke_step_setup_popup_hide_until_';

  String _todayKeyForPopup() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<bool> _shouldHideSetupPopup(StepSourceType type) async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString('$_kHidePopupKeyPrefix${type.name}');
    return saved == _todayKeyForPopup();
  }

  Future<void> _onSourceChipTapped(StepSourceType type) async {
    final bool hide = await _shouldHideSetupPopup(type);
    if (!hide && mounted) {
      await _showSetupGuideDialog(type);
    }
    await _switchStepSource(type);
  }

  // ✅ [2026-09-13 추가] 폰/워치별 상세 설정 방법 안내 팝업.
  Future<void> _showSetupGuideDialog(StepSourceType type) async {
    final bool isWatch = type == StepSourceType.watch;
    final String titleEn = isWatch ? 'WATCH SETUP GUIDE' : 'PHONE SETUP GUIDE';
    final String titleKo = isWatch ? '워치 연동 설정 방법' : '폰 걸음수 설정 방법';

    final String body = isWatch
        ? '워치 걸음수가 우리 앱까지 오려면 아래 3단계가 전부 되어 있어야 합니다.\n\n'
        '① 워치 ↔ 삼성헬스\n'
        '워치의 Galaxy Wearable 앱이 폰과 페어링되어 있고, 삼성헬스 앱에 실제 걸음수가 찍히는지 확인.\n\n'
        '② Health Connect 설치 + 동기화 켜기\n'
        '폰에 "Health Connect" 앱 설치(안드로이드 14+는 기본 내장) → 삼성헬스 앱 → 설정 → '
        '"Health Connect와 연결하기" → 걸음수 항목 토글 켜기.\n\n'
        '③ 우리 앱 권한 허용\n'
        '이 화면에서 워치를 처음 선택하면 권한 요청 팝업이 뜨는데 "허용"을 눌러야 함. '
        '이미 거부했다면 Health Connect 앱 → 연결된 앱 → GKE StudyUp → 걸음수 읽기 권한 켜기.'
        : '폰 자체 걸음수 센서를 쓰려면 아래가 되어 있어야 합니다.\n\n'
        '① 신체 활동 권한 허용\n'
        '안드로이드 10 이상은 "신체 활동(걸음 수)" 권한을 허용해야 걸음수 센서를 읽을 수 있습니다. '
        '처음 폰을 선택하면 권한 팝업이 뜨는데 "허용"을 눌러주세요.\n\n'
        '② 이미 거부했다면\n'
        '설정 → 앱 → GKE StudyUp → 권한 → 신체 활동 → 허용으로 변경.\n\n'
        '③ 측정 중엔 폰을 몸에 지니고 있기\n'
        '주머니나 손에 들고 걸어야 센서가 걸음을 인식합니다.';

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: LuxuryDialogFrame(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  luxuryDialogHeader(
                    icon: isWatch ? Icons.watch_rounded : Icons.smartphone_rounded,
                    en: titleEn,
                    ko: titleKo,
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: ExerciseTheme.pageBg, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      body,
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('$_kHidePopupKeyPrefix${type.name}', _todayKeyForPopup());
                            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('오늘 그만 보기', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ExerciseTheme.brandGolden,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('닫기', style: TextStyle(color: ExerciseTheme.pageBg, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 🆕 [2단계] 측정 소스를 폰 센서 ↔ 워치(Health Connect/HealthKit)로 전환.
  // 측정 중이었다면 먼저 멈추고, 새 소스로 다시 시작해야 하므로 진행 중인
  // 세션은 초기화됨(사용자에게 안내).
  Future<void> _switchStepSource(StepSourceType type) async {
    // ✅ [2026-09-13 버그 수정] 예전엔 이미 선택된 소스를 다시 탭하면 여기서
    // 바로 return 해버려서, 권한을 거부했거나 안 뜬 경우 "다시 눌러서
    // 재요청"할 방법이 전혀 없었다. 이제 같은 소스를 다시 탭해도 아래
    // isAvailable() 재확인(권한 재요청 포함)까지는 항상 실행한다.
    final bool sameSourceAsBefore = ExerciseStepService.activeSourceType == type;

    if (!sameSourceAsBefore) {
      if (_isStepTracking) {
        _stepSession?.stop();
        setState(() {
          _isStepTracking = false;
          _autoSteps = 0;
        });
      }
      await ExerciseStepService.setPreferredSource(type);
    }
    setState(() => _stepUnavailable = false);

    // ✅ [2026-09-13 추가] 권한 팝업이 실제로 뜨는 지점. 여기서 워치라면
    // Health Connect 권한을, 폰이라면 신체활동 권한을 다시 요청한다.
    final bool available = await ExerciseStepService.activeSource.isAvailable();
    if (!available) {
      setState(() => _stepUnavailable = true);
      if (mounted) {
        // ✅ [2026-09-14 추가] "영구 거부" 상태면 시스템 권한 팝업이 다시는
        // 안 뜨므로(Android 정책), 설명 스낵바 대신 "설정으로 이동" 버튼이
        // 있는 팝업을 보여줘서 사용자가 직접 켤 수 있게 안내한다.
        final bool permanentlyDenied = type == StepSourceType.phone && await PhonePedometerSource.isPermanentlyDenied();
        if (permanentlyDenied && mounted) {
          final bool? goSettings = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: ExerciseTheme.containerBg,
              title: const Text('권한이 꺼져 있습니다', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: const Text(
                '예전에 신체 활동 권한을 거부하신 적이 있어서, 이제는 앱에서 다시 물어보지 못합니다.\n\n설정 화면에서 직접 "신체 활동" 권한을 켜주세요.',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('취소', style: TextStyle(color: Colors.white54))),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('설정 열기', style: TextStyle(color: ExerciseTheme.brandGolden, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          if (goSettings == true) await openAppSettings();
        } else {
          ExerciseTheme.showLuxeSnackBar(
            context,
            type == StepSourceType.watch
                ? '워치 연결 권한이 아직 허용되지 않았습니다. 위 안내를 다시 확인해주세요.'
                : '걸음수 센서 권한이 아직 허용되지 않았습니다. 위 안내를 다시 확인해주세요.',
          );
        }
      }
      return;
    }

    // 🆕 [사용성 개선 2026-09-06] 일반 사용자는 "소스 선택"과 "자동기록 켜기"를
    // 따로 하기 어려워한다는 피드백을 반영. 이제 폰/워치를 고르는 즉시 매일
    // 자동 기록까지 한 번에 켜진다 - 별도 스위치를 안 눌러도 된다.
    // 🆕 [버그 수정] 이미 자동기록이 돌아가던 중이었다면, 먼저 멈춰서 이전
    // 소스 구독을 정리한 뒤 새 소스로 다시 시작해야 실제로 소스가 바뀐다
    // (안 그러면 setEnabled(true)가 "이미 실행 중"으로 보고 아무것도 안 해서,
    // 화면상 소스는 바뀐 것처럼 보여도 실제 기록은 계속 이전 소스 걸로 남았음).
    if (DailyStepWatcherService.instance.isRunning) {
      DailyStepWatcherService.instance.stop();
    }
    setState(() => _liveAutoSteps = null); // 🆕 이전 소스의 값이 잠깐이라도 남아 보이지 않도록 초기화
    await DailyStepWatcherService.instance.setEnabled(true);
    setState(() => _dailyAutoEnabled = true);

    if (mounted) {
      ExerciseTheme.showLuxeSnackBar(
        context,
        type == StepSourceType.watch
            ? '워치 연결 완료 - 오늘부터 자동으로 기록됩니다.'
            : '폰 걸음수 자동 기록을 시작합니다.',
      );
    }
  }

  Future<void> _toggleDailyAuto(bool value) async {
    await DailyStepWatcherService.instance.setEnabled(value);
    setState(() => _dailyAutoEnabled = value);
    if (mounted) {
      ExerciseTheme.showLuxeSnackBar(
        context,
        value ? '매일 자동 기록을 켰습니다. 자정마다 자동으로 다음날로 넘어갑니다.' : '매일 자동 기록을 껐습니다.',
      );
    }
  }

  // ---------------------------------------------------------------------
  // 🆕 [만보기 연동 1단계] 걸음수 자동 측정 시작/종료
  // ---------------------------------------------------------------------

  Future<void> _toggleStepTracking() async {
    if (_isStepTracking) {
      // 측정 종료 -> 걸음수/거리/시간을 관련 필드에 자동으로 채워 넣음
      _stepSession?.stop();
      final int finalSteps = _autoSteps;
      setState(() => _isStepTracking = false);

      _textControllers['steps']?.text = finalSteps.toString();
      if (_textControllers.containsKey('distanceKm')) {
        _textControllers['distanceKm']!.text = ExerciseStepService.stepsToKm(finalSteps).toStringAsFixed(2);
      }
      if (_stepTrackingStartTime != null) {
        final int elapsedMin = DateTime.now().difference(_stepTrackingStartTime!).inMinutes;
        if (elapsedMin > 0) _durationController.text = elapsedMin.toString();
      }
      if (mounted) ExerciseTheme.showLuxeSnackBar(context, '$finalSteps보 측정 완료 - 걸음수/거리에 자동 반영했습니다.');
      return;
    }

    // 측정 시작
    _stepSession = StepTrackingSession(
      onUpdate: (steps) {
        if (mounted) setState(() => _autoSteps = steps);
      },
      onError: (e) {
        if (mounted) setState(() => _stepUnavailable = true);
      },
    );
    final bool started = await _stepSession!.start();
    if (!started) {
      setState(() => _stepUnavailable = true);
      if (mounted) ExerciseTheme.showLuxeSnackBar(context, '이 기기에서는 걸음수 측정을 사용할 수 없습니다. 직접 입력해 주세요.');
      return;
    }
    _stepTrackingStartTime = DateTime.now();
    setState(() {
      _isStepTracking = true;
      _autoSteps = 0;
    });
  }

  // ---------------------------------------------------------------------
  // 저장
  // ---------------------------------------------------------------------

  Future<void> _onSave() async {
    final durationMin = int.tryParse(_durationController.text.trim()) ?? 0;
    if (durationMin <= 0) {
      ExerciseTheme.showLuxeSnackBar(context, '운동 시간을 입력해 주세요.');
      return;
    }

    final detail = <String, dynamic>{};

    // 1) 입력된 원본 값 수집
    for (final field in widget.exerciseType.fields) {
      if (field.isCalculated) continue;
      switch (field.type) {
        case ExerciseFieldType.number:
        case ExerciseFieldType.duration:
          final raw = _textControllers[field.key]?.text.trim();
          if (raw != null && raw.isNotEmpty) {
            detail[field.key] = num.tryParse(raw) ?? raw;
          }
          break;
        case ExerciseFieldType.text:
          final raw = _textControllers[field.key]?.text.trim();
          if (raw != null && raw.isNotEmpty) detail[field.key] = raw;
          break;
        case ExerciseFieldType.select:
          final v = _selectValues[field.key];
          if (v != null) detail[field.key] = v;
          break;
        case ExerciseFieldType.multiSelect: // 🆕 [중복선택] 선택된 항목들을 리스트로 저장
          final list = _multiSelectValues[field.key];
          if (list != null && list.isNotEmpty) detail[field.key] = list;
          break;
        case ExerciseFieldType.counter:
          detail[field.key] = _counterValues[field.key] ?? 0;
          break;
        case ExerciseFieldType.multiSet:
          final sets = <Map<String, dynamic>>[];
          for (var i = 0; i < _setRows.length; i++) {
            final row = _setRows[i];
            final w = double.tryParse(row.weight.text.trim());
            final r = int.tryParse(row.reps.text.trim());
            if (w != null || r != null) {
              sets.add(SetEntry(setNumber: i + 1, weightKg: w, reps: r, rpe: row.rpe).toJson());
            }
          }
          detail[field.key] = sets;
          break;
      }
    }

    // 2) 자동계산 필드 채우기 (종목별 공식은 exercise_calculations.dart 참고)
    _fillCalculatedFields(detail, durationMin);

    final record = ExerciseRecord(
      recordId: widget.existingRecord?.recordId ??
          'rec_${DateTime.now().millisecondsSinceEpoch}',
      exerciseTypeId: widget.exerciseType.id,
      date: _date,
      durationMin: durationMin,
      rpe: _rpe,
      avgHeartRateBpm: int.tryParse(_avgHrController.text.trim()),
      maxHeartRateBpm: int.tryParse(_maxHrController.text.trim()),
      memo: _memoController.text.trim(),
      detail: detail,
    );

    if (_isEditMode) {
      await _service.updateRecord(record);
    } else {
      await _service.addRecord(record);
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  // 🆕 [삭제 기능] 기존 기록을 수정하는 중일 때만 노출. 확인 팝업 후 삭제하고 화면을 닫는다.
  Future<void> _onDelete() async {
    final record = widget.existingRecord;
    if (record == null) return;
    final confirmed = await ExerciseTheme.showLuxeConfirmDialog(
      context,
      title: '기록 삭제',
      message: '이 운동 기록을 삭제할까요?\n이 작업은 되돌릴 수 없습니다.',
      confirmLabel: '삭제',
      isDestructive: true,
      icon: Icons.delete_rounded,
    );
    if (confirmed && mounted) {
      await _service.deleteRecord(record.recordId);
      Navigator.of(context).pop(true);
    }
  }

  /// 종목 id 기준으로 계산 필드(예: 페이스, SWOLF, 볼륨, 추정1RM, 오버파)를 채운다.
  void _fillCalculatedFields(Map<String, dynamic> detail, int durationMin) {
    final typeId = widget.exerciseType.id;
    final hasCalcField = widget.exerciseType.fields.any((f) => f.isCalculated);
    if (!hasCalcField) return;

    switch (typeId) {
      case 'running':
      case 'walking':
        final distanceKm = (detail['distanceKm'] as num?)?.toDouble();
        if (distanceKm != null && distanceKm > 0) {
          detail['paceMinPerKm'] = calcPaceMinPerKm(distanceKm: distanceKm, durationMin: durationMin);
          final met = kExerciseMetValues[typeId] ?? 6.0;
          detail['calories'] = calcCaloriesByMet(met: met, durationMin: durationMin, bodyWeightKg: _bodyWeightKg);
        }
        break;
      case 'swimming':
        final distanceM = (detail['distanceM'] as num?)?.toDouble();
        final laps = (detail['laps'] as num?)?.toDouble();
        final strokePerLap = (detail['strokeCountPerLap'] as num?)?.toInt();
        if (distanceM != null && distanceM > 0) {
          detail['pacePer100m'] = calcSwimPacePer100m(distanceM: distanceM, durationMin: durationMin);
          if (laps != null && laps > 0 && strokePerLap != null) {
            final lapTimeSeconds = ((durationMin * 60) / laps).round();
            detail['swolf'] = calcSwolf(lapTimeSeconds: lapTimeSeconds, strokeCount: strokePerLap);
          }
        }
        break;
      case 'golf':
        final totalScore = (detail['totalScore'] as num?)?.toInt();
        final holeType = detail['holeType'] as String?;
        if (totalScore != null && holeType != null) {
          detail['scoreToPar'] = calcScoreToPar(totalScore: totalScore, holeType: holeType);
        }
        break;
      case 'cycling':
        final distanceKm = (detail['distanceKm'] as num?)?.toDouble();
        if (distanceKm != null && distanceKm > 0) {
          detail['avgSpeedKmh'] = calcAvgSpeedKmh(distanceKm: distanceKm, durationMin: durationMin);
        }
        break;
      case 'gym':
        final rawSets = detail['sets'] as List?;
        if (rawSets != null && rawSets.isNotEmpty) {
          final sets = rawSets
              .map((e) => SetEntry.fromJson(e as Map<String, dynamic>))
              .toList();
          detail['volumeLoad'] = calcVolumeLoad(sets);
          detail['estimated1rm'] = calcEstimated1Rm(sets);
          detail['totalSets'] = sets.length; // ✅ [2026-09-14 추가] 빠져있던 계산 - 세트 개수 자동 집계
        }
        break;
    }
  }

  // ---------------------------------------------------------------------
  // 🆕 [만보기 연동 1단계] 걸음수 자동 측정 카드
  // ---------------------------------------------------------------------

  // 🆕 [2단계] 폰/워치 선택 칩 하나
  Widget _buildSourceChip(String label, StepSourceType type) {
    final bool isSelected = ExerciseStepService.activeSourceType == type;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _onSourceChipTapped(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? ExerciseTheme.brandGolden.withOpacity(0.18) : ExerciseTheme.pageBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? ExerciseTheme.brandGolden : Colors.white12, width: isSelected ? 1.3 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? ExerciseTheme.brandGolden : Colors.white54,
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAutoStepTrackingCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: ExerciseTheme.luxeCardDecoration(highlighted: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_walk_rounded, color: ExerciseTheme.brandGolden, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AUTO STEP TRACKING', style: GoogleFonts.gowunBatang(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 10.5)),
                    Text(
                      ExerciseStepService.activeSourceType == StepSourceType.watch ? '자동 걸음수 측정 (워치)' : '자동 걸음수 측정 (폰 센서)',
                      style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 🆕 [사용성 개선] 탭 한 번으로 자동 기록까지 시작된다는 걸 미리 안내
          Text(
            '탭 한 번으로 연결과 매일 자동 기록이 함께 시작됩니다.',
            style: ExerciseTheme.bodyStyle(size: 10.5, color: Colors.white38),
          ),
          const SizedBox(height: 8),
          // 🆕 [2단계] 측정 소스 선택: 폰 센서 ↔ 워치(Health Connect/HealthKit)
          Row(
            children: [
              Expanded(child: _buildSourceChip('📱 폰', StepSourceType.phone)),
              const SizedBox(width: 8),
              Expanded(child: _buildSourceChip('⌚ 워치', StepSourceType.watch)),
              const SizedBox(width: 8),
              // 🆕 [실시간성 개선] 워치는 30초→5초 폴링으로 단축했지만, 그마저도
              // 기다리기 답답할 때 지금 당장 한 번 더 조회해서 바로 확인 가능하게 함.
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  await ExerciseStepService.refreshNow();
                  if (mounted) ExerciseTheme.showLuxeSnackBar(context, '방금 값을 다시 확인했습니다.');
                },
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: ExerciseTheme.pageBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(Icons.refresh_rounded, color: ExerciseTheme.brandGolden, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_stepUnavailable)
            Text(
              '이 기기에서는 걸음수 센서를 사용할 수 없습니다. 아래 항목에 직접 입력해 주세요.',
              style: ExerciseTheme.bodyStyle(size: 11.5, color: Colors.white38),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ✅ [오버플로우 안전화] 좁은 화면에서 걸음수가 커지면(예: "10000 보")
                // 버튼과 겹치지 않도록 남는 공간만 쓰고 넘치면 줄바꿈되게 함.
                Expanded(
                  child: BiInline(
                    en: _isStepTracking
                        ? 'Tracking... $_autoSteps steps'
                        : (_autoSteps > 0 ? 'Done: $_autoSteps steps' : 'Not started yet'),
                    ko: _isStepTracking
                        ? '측정 중... $_autoSteps 보'
                        : (_autoSteps > 0 ? '측정 완료: $_autoSteps 보' : '아직 측정 전'),
                    color: _isStepTracking ? ExerciseTheme.brandGolden : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _toggleStepTracking,
                  icon: Icon(_isStepTracking ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 18),
                  label: ExerciseTheme.biButtonLabel(
                    _isStepTracking ? 'Stop' : 'Start',
                    _isStepTracking ? '측정 종료' : '측정 시작',
                    color: _isStepTracking ? Colors.white : ExerciseTheme.pageBg,
                    size: 12.5,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isStepTracking ? ExerciseTheme.dangerRed : ExerciseTheme.brandGolden,
                    foregroundColor: _isStepTracking ? Colors.white : ExerciseTheme.pageBg,
                  ),
                ),
              ],
            ),
            if (_isStepTracking) ...[
              const SizedBox(height: 8),
              Text(
                '폰을 주머니나 손에 들고 걸으면 자동으로 걸음수가 올라갑니다.',
                style: ExerciseTheme.bodyStyle(size: 11, color: Colors.white38),
              ),
            ],
            // 🆕 [매일 자동기록] 위 "측정 시작/종료"와는 별개로, 켜두면 자정마다
            // 자동으로 다음날로 넘어가면서 매일 걸음수가 계속 기록됨.
            const Divider(color: Colors.white12, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DAILY AUTO RECORD', style: GoogleFonts.gowunBatang(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 10)),
                      Text('매일 자동 기록 (자정 기준)', style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                    ],
                  ),
                ),
                Switch(
                  value: _dailyAutoEnabled,
                  activeColor: ExerciseTheme.brandGolden,
                  onChanged: _toggleDailyAuto,
                ),
              ],
            ),
            if (_dailyAutoEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '자정이 지나면 어제 걸음수가 자동 확정 저장되고, 오늘 걸음수가 새로 시작됩니다. 언제든 이 화면에서 직접 수정할 수 있습니다.',
                  style: ExerciseTheme.bodyStyle(size: 10.5, color: Colors.white38),
                ),
              ),
            // 🆕 [화면 실시간 표시] 뒤에서 자동 기록이 실제로 돌아가고 있는지
            // 눈으로 바로 확인할 수 있도록, 오늘 자동 기록된 걸음수·거리·칼로리를 표시.
            if (_dailyAutoEnabled) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: ExerciseTheme.brandGolden.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ExerciseTheme.brandGolden.withOpacity(0.35)),
                ),
                // ✅ [오버플로우 수정 2026-09-06] 예전엔 Row+spaceBetween 한 줄에
                // 라벨과 값을 같이 넣어서 값이 길어지면 오른쪽이 화면 밖으로
                // 잘렸다(오버플로우). 라벨은 위, 값은 아래로 세로 배치하고,
                // 값 부분은 길어질 걸 대비해 좌우로 스크롤되게 만들었다.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BiInline(
                      en: "Today's Auto Record",
                      ko: '오늘 자동 기록',
                      color: Colors.white70,
                      fontSize: 10.5,
                    ),
                    const SizedBox(height: 4),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        _liveAutoSteps == null
                            ? 'Loading... / 불러오는 중...'
                        // 🆕 [칼로리 추가] 걸음수 기준 추정 칼로리도 거리와 함께 표시
                            : '$_liveAutoSteps steps 보 · ${_formatAutoDistance(_liveAutoSteps!)} · ${_estimateCaloriesForSteps(_liveAutoSteps!).round()}kcal',
                        style: const TextStyle(color: ExerciseTheme.brandGolden, fontWeight: FontWeight.bold, fontSize: 14), // 🆕 12 -> 14로 살짝 키움
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // 🆕 [칼로리 추정] 걸음수 → 소요시간(분당 약 100보 가정) → MET 공식으로 칼로리 추정.
  // 저장된 몸무게(_bodyWeightKg)를 반영하며, 입력 안 했으면 평균값으로 계산됨.
  double _estimateCaloriesForSteps(int steps) {
    final double estimatedMinutes = steps / 100.0;
    final double met = kExerciseMetValues['walking'] ?? 3.8;
    return calcCaloriesByMet(met: met, durationMin: estimatedMinutes.round(), bodyWeightKg: _bodyWeightKg);
  }

  // 🆕 [화면 실시간 표시] 짧은 거리는 m, 긴 거리는 km로 보기 좋게 표시
  String _formatAutoDistance(int steps) {
    final double km = ExerciseStepService.stepsToKm(steps);
    if (km < 1) return '${(km * 1000).round()}m';
    return '${km.toStringAsFixed(2)}km';
  }

  // 🆕 [걸음수 그래프 전용] 걷기류(steps 필드가 있는 종목)의 날짜별 걸음수 합계
  Future<Map<String, int>> _loadStepsByDate() async {
    final all = await ExerciseDataService.instance.getAllRecords();
    final Map<String, int> byDate = {};
    for (final r in all) {
      if (r.exerciseTypeId != widget.exerciseType.id) continue;
      final dynamic stepsRaw = r.detail['steps'];
      if (stepsRaw is! int) continue;
      final key = _localDateKey(r.date);
      byDate[key] = (byDate[key] ?? 0) + stepsRaw;
    }
    return byDate;
  }

  // 🆕 [8번 - 시간 그래프] 모든 종목 공통으로 날짜별 운동시간(분) 합계.
  // 걷기 포함 전 종목에서 항상 사용됨(걷기는 걸음수 그래프에 추가로 보여줌).
  Future<Map<String, int>> _loadDurationByDate() async {
    final all = await ExerciseDataService.instance.getAllRecords();
    final Map<String, int> byDate = {};
    for (final r in all) {
      if (r.exerciseTypeId != widget.exerciseType.id) continue;
      final key = _localDateKey(r.date);
      byDate[key] = (byDate[key] ?? 0) + r.durationMin;
    }
    return byDate;
  }

  String _localDateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ✅ [정렬 핵심] 그래프 영역(막대가 그려지는 부분)의 높이. 카드 전체 높이(240)에서
  // X축 날짜 라벨 높이(28)를 뺀 값. 이 숫자를 Y축 눈금 위치 계산과 BarChart의
  // bottomTitles reservedSize 양쪽에 동일하게 써서 절대 어긋나지 않게 한다.
  static const double _chartPlotHeight = 212;

  // 🆕 [Y축 고정] base~top 사이를 interval 간격으로 나눈 눈금들이 그래프 영역
  // 안에서 위에서부터 몇 px 떨어진 위치에 와야 하는지 직접 계산.
  List<_YAxisTick> _buildYAxisTickPositions(double base, double top, double interval) {
    final List<_YAxisTick> ticks = [];
    double v = base;
    while (v <= top + 0.01) {
      final double fraction = (top - v) / (top - base); // top일 때 0(맨 위), base일 때 1(맨 아래)
      ticks.add(_YAxisTick(value: v, offsetFromTop: fraction * _chartPlotHeight));
      v += interval;
    }
    return ticks;
  }

  // ✅ [6·7·8번 - 종목별 시간축 설정] 종목마다 한 세션에 걸리는 시간이 전혀
  // 달라서(골프 4시간 안팎, 수영/러닝 40분 안팎, 구기 2시간 이상, 등산 5시간
  // 이상), 각 종목에 맞는 눈금 간격(interval)과 "이 값을 넘으면 원점이
  // 밀려 올라가며 절단 표시가 뜨는" 기준값(defaultTop)을 따로 둔다.
  // 걸음수(500/1000/2500 규칙)와 완전히 같은 원리이며, 원점은 항상 0에서
  // 시작하다가 defaultTop을 넘는 순간에만 한 칸(interval) 밀려 올라간다.
  _DurationAxisConfig _durationAxisConfigFor(String typeId) {
    const Map<String, _DurationAxisConfig> configs = {
      'golf': _DurationAxisConfig(interval: 50, defaultTop: 200), // 한 라운드 약 4시간
      'swimming': _DurationAxisConfig(interval: 10, defaultTop: 40),
      'running': _DurationAxisConfig(interval: 10, defaultTop: 40),
      'walking': _DurationAxisConfig(interval: 20, defaultTop: 80), // 🆕 [8번] 걷기 시간그래프용
      'gym': _DurationAxisConfig(interval: 15, defaultTop: 90),
      'pilates': _DurationAxisConfig(interval: 15, defaultTop: 90),
      'yoga': _DurationAxisConfig(interval: 15, defaultTop: 90),
      'hiking': _DurationAxisConfig(interval: 60, defaultTop: 300), // 5시간 이상 소요
      'cycling': _DurationAxisConfig(interval: 30, defaultTop: 120),
      'tennis': _DurationAxisConfig(interval: 30, defaultTop: 120),
      'badminton': _DurationAxisConfig(interval: 20, defaultTop: 90),
      'tabletennis': _DurationAxisConfig(interval: 20, defaultTop: 90),
      'basketball': _DurationAxisConfig(interval: 30, defaultTop: 120), // 2시간 이상 소요
      'soccer': _DurationAxisConfig(interval: 30, defaultTop: 120), // 2시간 이상 소요
      'skiing': _DurationAxisConfig(interval: 30, defaultTop: 180),
      'etc': _DurationAxisConfig(interval: 20, defaultTop: 100),
    };
    return configs[typeId] ?? const _DurationAxisConfig(interval: 20, defaultTop: 100);
  }

  // 🆕 [파라미터화] isSteps:true면 걸음수 그래프(걷기 전용), false면 운동시간
  // 그래프(모든 종목 공통, 걷기 포함). 같은 화면 안에 두 그래프가 동시에
  // 있을 수 있어(걷기의 경우) 서로 다른 Future/ScrollController를 쓴다.
  Widget _buildDailyTrendChart({required bool isSteps}) {
    final ScrollController scrollController = isSteps ? _stepsChartScrollController : _durationChartScrollController;
    return FutureBuilder<Map<String, int>>(
      future: isSteps ? _stepsHistoryFuture : _durationHistoryFuture,
      builder: (context, snapshot) {
        final Map<String, int> byDate = snapshot.data ?? {};
        final DateTime today = DateTime.now();
        // 🆕 [30일 스크롤] 최근 30일을 전부 불러오고, 화면에서는 좌우로
        // 밀어서 과거까지 볼 수 있게 함.
        final List<DateTime> days = List.generate(
          _stepsHistoryDays,
              (i) => DateTime(today.year, today.month, today.day).subtract(Duration(days: _stepsHistoryDays - 1 - i)),
        );
        final List<int> values = days.map((d) => byDate[_localDateKey(d)] ?? 0).toList();
        final int maxVal = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);

        // ✅ [축 규칙 - 종목별 분기]
        // 걸음수: 기본 원점 500, 2500보 넘으면 원점이 1000으로 올라가며 절단 표시.
        // 운동시간: 기본 원점 0, 종목별 defaultTop을 넘으면 원점이 한 칸(interval)
        // 밀려 올라가며 절단 표시(6·7·8번 요청).
        final _DurationAxisConfig durationConfig = _durationAxisConfigFor(widget.exerciseType.id);
        final bool isBroken = isSteps ? maxVal > 2500 : maxVal > durationConfig.defaultTop;
        final double interval = isSteps ? 500 : durationConfig.interval;
        final double base = isSteps ? (isBroken ? 1000 : 500) : (isBroken ? durationConfig.interval : 0);
        double top = base;
        final double minTop = isSteps ? 2500 : durationConfig.defaultTop;
        while (top < minTop || top < maxVal + interval) {
          top += interval;
        }

        // 🆕 [30일 스크롤] 하루당 슬롯 폭(막대+간격)
        const double perDaySlotWidth = 46;

        // 🆕 처음 열었을 때 오늘(맨 오른쪽)이 보이도록 자동 스크롤
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          }
        });

        final String enTitle = isSteps ? 'DAILY STEPS' : 'DAILY MINUTES';
        final String koTitle = isSteps ? '일별 걸음수' : '일별 운동시간';
        final String unit = isSteps ? '보' : '분';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: ExerciseTheme.luxeCardDecoration(highlighted: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(enTitle, style: GoogleFonts.gowunBatang(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 10.5)),
                  const SizedBox(width: 6),
                  Text('($koTitle)', style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '좌우로 밀어서 최근 30일까지 볼 수 있습니다. 막대 위 숫자는 그 날의 추정 칼로리입니다.',
                style: ExerciseTheme.bodyStyle(size: 10, color: Colors.white38),
              ),
              const SizedBox(height: 14),
              if (snapshot.connectionState != ConnectionState.done)
                const SizedBox(height: 240, child: Center(child: CircularProgressIndicator(color: ExerciseTheme.brandGolden)))
              else
                SizedBox(
                  height: 240,
                  // ✅ [정렬 유지] Y축 전용 BarChart를 따로 그리는 대신, 그래프
                  // 영역 높이를 직접 계산해서(_chartPlotHeight) 텍스트를 정확한
                  // 위치에 그린다. 그래프(BarChart)도 top/bottom 예약폭을 똑같은
                  // 숫자로 명시해서 두 계산이 절대 어긋날 수 없게 만들었다.
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🆕 [고정 Y축 패널 - 직접 계산] plotHeight(212) 구간에
                      // 눈금 값 위치를 비율로 직접 계산해서 배치.
                      SizedBox(
                        width: 52,
                        height: 240,
                        child: Column(
                          children: [
                            SizedBox(
                              height: _chartPlotHeight,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(width: 1.4, color: ExerciseTheme.brandGolden.withOpacity(0.5)),
                                  ),
                                  ..._buildYAxisTickPositions(base, top, interval).map((tick) {
                                    return Positioned(
                                      top: tick.offsetFromTop - 7,
                                      right: 6,
                                      child: Text(
                                        '${tick.value.toInt()} •',
                                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                                        textAlign: TextAlign.right,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28), // 🆕 스크롤 패널의 날짜 라벨 높이(bottomTitles)와 동일하게 맞춤
                          ],
                        ),
                      ),
                      // 🆕 [스크롤 패널] 날짜(X축 라벨)와 막대가 여기서 함께 좌우로 스크롤됨
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: days.length * perDaySlotWidth,
                            height: 240,
                            child: Stack(
                              children: [
                                BarChart(
                                  BarChartData(
                                    minY: base,
                                    maxY: top,
                                    alignment: BarChartAlignment.spaceAround,
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: interval,
                                      getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withOpacity(0.08), strokeWidth: 1),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border(
                                        left: BorderSide.none, // 🆕 왼쪽 선은 고정 패널이 담당
                                        bottom: BorderSide(color: ExerciseTheme.brandGolden.withOpacity(0.5), width: 1.4),
                                        top: BorderSide.none,
                                        right: BorderSide.none,
                                      ),
                                    ),
                                    // 🆕 [칼로리 라벨] 막대 위에 그 날 추정 칼로리를 항상 표시
                                    barTouchData: BarTouchData(
                                      enabled: false,
                                      touchTooltipData: BarTouchTooltipData(
                                        tooltipBgColor: Colors.transparent,
                                        tooltipPadding: EdgeInsets.zero,
                                        tooltipMargin: 4,
                                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                          if (groupIndex < 0 || groupIndex >= values.length) return null;
                                          final int kcal = isSteps
                                              ? _estimateCaloriesForSteps(values[groupIndex]).round()
                                              : calcCaloriesByMet(
                                            met: kExerciseMetValues[widget.exerciseType.id] ?? 5.0,
                                            durationMin: values[groupIndex],
                                            bodyWeightKg: _bodyWeightKg,
                                          ).round();
                                          return BarTooltipItem(
                                            '${kcal}kcal',
                                            TextStyle(color: _rainbowWeekColors[days[groupIndex].weekday - 1], fontSize: 9, fontWeight: FontWeight.bold),
                                          );
                                        },
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      // ✅ [정렬 핵심] top/left 예약폭을 0으로 명시해서 실제
                                      // 그래프 영역 높이가 정확히 _chartPlotHeight(212)가 되도록 함
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
                                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
                                      // 🆕 [X축: 일자(날짜)] 막대와 함께 스크롤됨. 높이(28)는
                                      // 왼쪽 고정 패널의 하단 여백과 반드시 같아야 함.
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 28,
                                          getTitlesWidget: (value, meta) {
                                            final int idx = value.toInt();
                                            if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                                            final DateTime d = days[idx];
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Text(
                                                '${d.day}',
                                                style: TextStyle(
                                                  color: _rainbowWeekColors[d.weekday - 1],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    barGroups: List.generate(days.length, (i) {
                                      final DateTime d = days[i];
                                      return BarChartGroupData(
                                        x: i,
                                        barRods: [
                                          BarChartRodData(
                                            toY: values[i].toDouble().clamp(base, top),
                                            color: _rainbowWeekColors[d.weekday - 1], // 🆕 요일 고정 무지개색
                                            width: 20,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ],
                                        showingTooltipIndicators: values[i] > 0 ? [0] : [], // 🆕 칼로리 라벨 항상 표시
                                      );
                                    }),
                                  ),
                                ),
                                // 🆕 [가위질(절단) 표시] 원점이 밀려 올라간 경우에만 표시
                                if (isBroken)
                                  Positioned(
                                    left: 4,
                                    bottom: 40,
                                    child: Transform.rotate(
                                      angle: -0.4,
                                      child: CustomPaint(
                                        size: const Size(26, 12),
                                        painter: _AxisBreakPainter(color: ExerciseTheme.brandGolden),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (isBroken)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '※ ${unit == '보' ? '걸음수' : '기록'}가 많아 0~${base.toInt()}$unit 구간은 생략해서 표시했습니다.',
                    style: ExerciseTheme.bodyStyle(size: 10, color: Colors.white38),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // 필드별 위젯 빌더
  // ---------------------------------------------------------------------

  Widget _buildField(ExerciseField field) {
    if (field.isCalculated) return const SizedBox.shrink();

    switch (field.type) {
      case ExerciseFieldType.number:
      case ExerciseFieldType.duration:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _textControllers[field.key],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: _decoration(_bilabel(field), unit: field.unit),
          ),
        );
      case ExerciseFieldType.text:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _textControllers[field.key],
            style: const TextStyle(color: Colors.white),
            decoration: _decoration(_bilabel(field)),
          ),
        );
      case ExerciseFieldType.select:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            initialValue: _selectValues[field.key],
            dropdownColor: ExerciseTheme.containerBgElevated,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration(_bilabel(field)),
            items: (field.options ?? [])
                .map((o) => DropdownMenuItem(value: o, child: Text(_optionLabel(field, o))))
                .toList(),
            onChanged: (v) => setState(() => _selectValues[field.key] = v),
          ),
        );
      case ExerciseFieldType.multiSelect: // 🆕 [중복선택] 칩을 여러 개 동시에 켤 수 있는 UI
        final List<String> selected = _multiSelectValues[field.key] ?? [];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_bilabel(field), style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (field.options ?? []).map((option) {
                  final bool isSelected = selected.contains(option);
                  return FilterChip(
                    label: Text(_optionLabel(field, option)),
                    selected: isSelected,
                    backgroundColor: ExerciseTheme.pageBg,
                    selectedColor: ExerciseTheme.brandGolden.withOpacity(0.25),
                    checkmarkColor: ExerciseTheme.brandGolden,
                    labelStyle: TextStyle(color: isSelected ? ExerciseTheme.brandGolden : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    side: BorderSide(color: isSelected ? ExerciseTheme.brandGolden : Colors.white24),
                    onSelected: (v) => setState(() {
                      final list = _multiSelectValues[field.key] ?? [];
                      if (v) {
                        if (!list.contains(option)) list.add(option);
                      } else {
                        list.remove(option);
                      }
                      _multiSelectValues[field.key] = list;
                    }),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      case ExerciseFieldType.counter:
      // ✅ [2026-09-13 버그 수정] 숫자 카운터를 한 줄에 2개씩 절반 폭으로
      // 배치하게 되면서, 라벨이 길 때 줄바꿈 없이 그대로 밀려나 +/- 버튼이
      // 화면 밖으로 밀려서 눌러도 안 눌리는(오버플로우) 문제가 있었다.
      // 라벨은 위에 2줄까지 줄바꿈되게 하고, +/- 버튼은 훨씬 작고 컴팩트한
      // 원형 버튼으로 바꿔서 절반 폭 안에서도 절대 넘치지 않게 했다.
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: ExerciseTheme.luxeCardDecoration(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bilabel(field),
                  style: ExerciseTheme.bodyStyle(color: Colors.white, size: 12.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _compactCounterButton(
                      Icons.remove_rounded,
                          () => setState(() {
                        _counterValues[field.key] = (_counterValues[field.key] ?? 0) - 1;
                        if (_counterValues[field.key]! < 0) _counterValues[field.key] = 0;
                      }),
                    ),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '${_counterValues[field.key] ?? 0}',
                        textAlign: TextAlign.center,
                        style: ExerciseTheme.titleStyle(size: 16),
                      ),
                    ),
                    _compactCounterButton(
                      Icons.add_rounded,
                          () => setState(() {
                        _counterValues[field.key] = (_counterValues[field.key] ?? 0) + 1;
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      case ExerciseFieldType.multiSet:
        return _buildMultiSetField(field);
    }
  }

  // ✅ [2026-09-13 추가] 절반 폭 안에서도 절대 넘치지 않는 작은 원형 +/- 버튼.
  // 표준 IconButton(최소 48x48)보다 훨씬 작아서(30x30) 2단 배치에 안전함.
  Widget _compactCounterButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: ExerciseTheme.brandGolden.withOpacity(0.12), shape: BoxShape.circle),
        child: Icon(icon, color: ExerciseTheme.brandGolden, size: 18),
      ),
    );
  }

  Widget _buildMultiSetField(ExerciseField field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: ExerciseTheme.luxeCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_bilabel(field), style: ExerciseTheme.titleStyle(size: 14)),
          const SizedBox(height: 10),
          ..._setRows.asMap().entries.map((entry) {
            final i = entry.key;
            final row = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(width: 28, child: Text('${i + 1}', style: ExerciseTheme.bodyStyle())),
                  Expanded(
                    child: TextField(
                      controller: row.weight,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _decoration('중량', unit: 'kg'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: row.reps,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _decoration('횟수'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.white54),
                    onPressed: () => setState(() => _setRows.removeAt(i)),
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => setState(() => _setRows.add(_SetRow())),
            icon: const Icon(Icons.add, color: ExerciseTheme.brandGolden, size: 18),
            label: ExerciseTheme.biButtonLabel('Add Set', '세트 추가', color: ExerciseTheme.brandGolden, size: 12.5),
          ),
        ],
      ),
    );
  }

  // ✅ [2026-09-13 추가] 화면 맨 아래 "운동입력(현재)/운동분석" 고정 탭.
  // "운동입력"은 지금 이 화면 자체라 탭 이동 없이 눌러도 그대로 있고,
  // "운동분석"만 실제로 상세분석 화면으로 넘어감.
  Widget _buildBottomTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: ExerciseTheme.containerBg,
        border: Border(top: BorderSide(color: ExerciseTheme.brandGolden.withOpacity(0.2))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _buildBottomTab(icon: Icons.edit_note_rounded, en: 'INPUT', ko: '운동입력', active: true, onTap: null),
            ),
            Container(width: 1, height: 36, color: Colors.white12),
            Expanded(
              child: _buildBottomTab(
                icon: Icons.insights_rounded,
                en: 'ANALYSIS',
                ko: '운동분석',
                active: false,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseTypeAnalysisScreen(type: widget.exerciseType))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomTab({required IconData icon, required String en, required String ko, required bool active, VoidCallback? onTap}) {
    final Color color = active ? ExerciseTheme.brandGolden : Colors.white54;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 3),
            Text(
              appLanguage.isDefault ? ko : en,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.exerciseType;
    final String enName = ExerciseTheme.englishNameForType(type.id, type.name);
    return Scaffold(
      backgroundColor: ExerciseTheme.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ExerciseTheme.iconForType(type.id), color: ExerciseTheme.brandGolden, size: 20),
            const SizedBox(width: 8),
            BiTitle(en: enName, ko: type.name, enSize: 17, koSize: 17),
          ],
        ),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: ExerciseTheme.dangerRed),
              tooltip: 'Delete',
              onPressed: _onDelete,
            ),
          IconButton(
            icon: const Icon(Icons.check_circle_rounded, color: ExerciseTheme.brandGolden),
            tooltip: 'Save',
            onPressed: _onSave,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 공통: 날짜
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ExerciseTheme.brandGolden.withOpacity(0.18),
                    ExerciseTheme.brandGolden.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ExerciseTheme.brandGolden.withOpacity(0.5), width: 1.2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: ExerciseTheme.brandGolden, size: 18),
                  const SizedBox(width: 10),
                  BiInline(en: 'DATE', ko: '기록 날짜', color: Colors.white70, fontSize: 12),
                  const Spacer(),
                  Text(
                    '${_date.year}.${_date.month.toString().padLeft(2, '0')}.${_date.day.toString().padLeft(2, '0')}',
                    style: GoogleFonts.notoSansKr(
                      color: ExerciseTheme.brandGolden,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 공통: 운동시간
          BiInline(en: 'DURATION', ko: '운동시간', color: ExerciseTheme.brandGolden, fontWeight: FontWeight.bold, fontSize: 12),
          const SizedBox(height: 6),
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration('', unit: '분'),
          ),
          const SizedBox(height: 16),

          // 공통: RPE (자각 운동강도)
          Container(
            decoration: ExerciseTheme.luxeCardDecoration(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RPE (Perceived Exertion)',
                      style: GoogleFonts.gowunBatang(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // ✅ [2026-09-06 개편] 10개국어 선택 시 사전에서 해당 언어로 표시
                      appLanguage.isForeignSelected
                          ? '자각 운동강도 (RPE $_rpe · ${kExerciseTermTranslations[kRpeLabelsEn[_rpe]]?[appLanguage.current] ?? kRpeLabelsEn[_rpe] ?? ''})'
                          : '자각 운동강도 (RPE $_rpe · ${kRpeLabelsEn[_rpe] ?? ''} / ${kRpeLabels[_rpe] ?? ''})',
                      style: GoogleFonts.notoSansKr(color: ExerciseTheme.brandGolden, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: ExerciseTheme.brandGolden,
                    thumbColor: ExerciseTheme.brandGolden,
                    inactiveTrackColor: ExerciseTheme.brandGolden.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: _rpe.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (v) => setState(() => _rpe = v.round()),
                  ),
                ),
              ],
            ),
          ),

          // 공통: 심박수 (선택)
          BiInline(en: 'HEART RATE (OPTIONAL)', ko: '심박수 (선택)', color: ExerciseTheme.brandGolden, fontWeight: FontWeight.bold, fontSize: 12),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _avgHrController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('', unit: 'bpm')
                      .copyWith(hintText: biHint('Average', '평균')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _maxHrController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('', unit: 'bpm')
                      .copyWith(hintText: biHint('Max', '최고')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Divider(color: ExerciseTheme.brandGolden.withOpacity(0.2)),
          const SizedBox(height: 12),
          BiInline(
            en: '${ExerciseTheme.englishNameForType(type.id, type.name)} DETAILS',
            ko: '${type.name} 세부 기록',
            color: ExerciseTheme.goldenLight,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          const SizedBox(height: 12),

          // 🆕 [만보기 연동 1단계] '걸음수' 필드가 있는 종목에서만 자동측정 카드 노출
          if (_hasStepsField) ...[
            _buildAutoStepTrackingCard(),
            const SizedBox(height: 12),
          ],

          ..._buildSectionedFields(type.fields),

          // 🆕 [모든 종목 공통] 걷기는 '걸음수' 그래프에 더해 '운동시간' 그래프도
          // 골프와 동일한 스타일로 함께 보여줌(8번 요청). 그 외 종목은 운동시간
          // 그래프만 보여줌 - 종목별로 세션 길이가 다르므로(골프 200분, 수영/
          // 러닝 40분, 구기 120분, 등산 300분 등) 눈금/절단 기준을 종목마다 다르게 함.
          const SizedBox(height: 12),
          if (_hasStepsField) ...[
            _buildDailyTrendChart(isSteps: true),
            const SizedBox(height: 12),
          ],
          _buildDailyTrendChart(isSteps: false),

          const SizedBox(height: 12),
          BiInline(en: 'MEMO', ko: '메모', color: ExerciseTheme.brandGolden, fontWeight: FontWeight.bold, fontSize: 12),
          const SizedBox(height: 6),
          TextField(
            controller: _memoController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration(''),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: ExerciseTheme.brandGolden,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 6,
                shadowColor: ExerciseTheme.brandGolden.withOpacity(0.5),
              ),
              child: ExerciseTheme.biButtonLabel('Save Record', '기록 저장', color: ExerciseTheme.pageBg, size: 14.5),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
      // ✅ [2026-09-13 추가] 골프 화면 자체 맨 아래에도 "운동입력(현재 화면)/
      // 운동분석" 두 탭을 고정으로 넣어서, 종목 목록으로 안 나가고도 바로
      // 분석 화면으로 넘어갈 수 있게 함.
      bottomNavigationBar: _buildBottomTabBar(),
    );
  }
}

// 🆕 [일별 걸음수 그래프 - 축 절단 표시] Y축 원점이 0이 아니라는 걸 보여주는
// 작은 지그재그(가위질) 선. 원점이 500/1000처럼 0이 아닌 값부터 시작할 때만
// 좌측 하단에 그려서, "이 아래 구간은 생략됐다"는 걸 시각적으로 알려준다.
class _AxisBreakPainter extends CustomPainter {
  final Color color;
  _AxisBreakPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.lineTo(size.width * 0.3, size.height * 0.2);
    path.lineTo(size.width * 0.55, size.height * 0.8);
    path.lineTo(size.width * 0.8, size.height * 0.2);
    path.lineTo(size.width, size.height * 0.6);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AxisBreakPainter oldDelegate) => oldDelegate.color != color;
}

// 🆕 [Y축 고정] Y축 눈금 하나(값 + 화면상 위치)를 담는 작은 데이터 클래스.
class _YAxisTick {
  final double value;
  final double offsetFromTop;
  _YAxisTick({required this.value, required this.offsetFromTop});
}

// ✅ [6·7·8번] 종목별 운동시간 Y축 설정(눈금 간격 + 절단 기준값)을 담는 작은 데이터 클래스.
class _DurationAxisConfig {
  final double interval;
  final double defaultTop;
  const _DurationAxisConfig({required this.interval, required this.defaultTop});
}
