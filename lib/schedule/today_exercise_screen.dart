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
import 'package:google_fonts/google_fonts.dart';
import 'exercise_models.dart';
import 'exercise_data_service.dart';
import 'exercise_calculations.dart';
import 'exercise_theme.dart';
import 'exercise_step_service.dart'; // 🆕 [만보기 연동 1단계+매일 자동기록] StepTrackingSession, DailyStepWatcherService
import 'exercise_profile_service.dart'; // 🆕 [개인정보 - 칼로리 계산용] 저장된 몸무게 반영

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
  Future<Map<String, int>>? _stepsHistoryFuture; // 🆕 매 rebuild마다 다시 안 불러오게 캐시

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
    _stepsHistoryFuture = _loadDailyMetricByDate(); // 🆕 [모든 종목 공통] 일별 추이 그래프 데이터는 종목 무관하게 항상 로드
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
    _durationController.dispose();
    _avgHrController.dispose();
    _maxHrController.dispose();
    _memoController.dispose();
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
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

  // 🆕 [2단계] 측정 소스를 폰 센서 ↔ 워치(Health Connect/HealthKit)로 전환.
  // 측정 중이었다면 먼저 멈추고, 새 소스로 다시 시작해야 하므로 진행 중인
  // 세션은 초기화됨(사용자에게 안내).
  Future<void> _switchStepSource(StepSourceType type) async {
    if (ExerciseStepService.activeSourceType == type) return;
    if (_isStepTracking) {
      _stepSession?.stop();
      setState(() {
        _isStepTracking = false;
        _autoSteps = 0;
      });
    }
    await ExerciseStepService.setPreferredSource(type);
    setState(() => _stepUnavailable = false);

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
      onTap: () => _switchStepSource(type),
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
                Text(
                  _isStepTracking
                      ? '측정 중... $_autoSteps 보'
                      : (_autoSteps > 0 ? '측정 완료: $_autoSteps 보' : '아직 측정 전'),
                  style: TextStyle(
                    color: _isStepTracking ? ExerciseTheme.brandGolden : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _toggleStepTracking,
                  icon: Icon(_isStepTracking ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 18),
                  label: Text(_isStepTracking ? '측정 종료' : '측정 시작'),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('오늘 자동 기록', style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 11.5)),
                    Text(
                      _liveAutoSteps == null
                          ? '불러오는 중...'
                      // 🆕 [칼로리 추가] 걸음수 기준 추정 칼로리도 거리와 함께 표시
                          : '$_liveAutoSteps 보 · ${_formatAutoDistance(_liveAutoSteps!)} · ${_estimateCaloriesForSteps(_liveAutoSteps!).round()}kcal',
                      style: TextStyle(color: ExerciseTheme.brandGolden, fontWeight: FontWeight.bold, fontSize: 13),
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

  // 🆕 [모든 종목 공통] 걷기는 '걸음수'를, 그 외 종목은 '운동시간(분)'을
  // 날짜별로 합산해서 조회. 자동기록(걷기)과 수동기록 전부 포함.
  Future<Map<String, int>> _loadDailyMetricByDate() async {
    final all = await ExerciseDataService.instance.getAllRecords();
    final Map<String, int> byDate = {};
    for (final r in all) {
      if (r.exerciseTypeId != widget.exerciseType.id) continue;
      int? value;
      if (_hasStepsField) {
        final dynamic stepsRaw = r.detail['steps'];
        if (stepsRaw is int) value = stepsRaw;
      } else {
        value = r.durationMin;
      }
      if (value == null) continue;
      final key = _localDateKey(r.date);
      byDate[key] = (byDate[key] ?? 0) + value;
    }
    return byDate;
  }

  String _localDateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // 🆕 [운동시간용 눈금 간격] 걸음수(500 고정)와 달리, 종목마다 운동시간
  // 범위가 천차만별이라 최댓값에 맞춰 보기 좋은 간격(10/20/30/60분)을 고름.
  int _niceMinuteInterval(int maxVal) {
    if (maxVal <= 60) return 10;
    if (maxVal <= 120) return 20;
    if (maxVal <= 300) return 30;
    return 60;
  }

  // 🆕 [모든 종목 공통] 걷기는 X축=일자·Y축=걸음수(500보 간격, 2500보 넘으면
  // 원점이 1000보로 올라가는 절단 규칙 적용), 그 외 종목은 X축=일자·Y축=
  // 운동시간(분)으로 동일한 스타일(무지개색·30일 스크롤·칼로리 라벨)을 재사용.
  Widget _buildDailyTrendChart() {
    return FutureBuilder<Map<String, int>>(
      future: _stepsHistoryFuture,
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

        // 🆕 [축 규칙 - 종목별 분기]
        // 걷기(걸음수): 기본 원점 500, 2500보 넘으면 원점이 1000으로 올라가며 절단 표시.
        // 그 외(운동시간 분): 원점 0, 최댓값에 맞는 보기 좋은 간격 자동 계산, 절단 없음.
        final bool isSteps = _hasStepsField;
        final bool isBroken = isSteps && maxVal > 2500;
        final double interval = isSteps ? 500 : _niceMinuteInterval(maxVal).toDouble();
        final double base = isSteps ? (isBroken ? 1000 : 500) : 0;
        double top = base;
        final double minTop = isSteps ? 2500 : (interval * 4);
        while (top < minTop || top < maxVal + interval) {
          top += interval;
        }

        // 🆕 [30일 스크롤] 하루당 슬롯 폭(막대+간격)
        const double perDaySlotWidth = 46;

        // 🆕 처음 열었을 때 오늘(맨 오른쪽)이 보이도록 자동 스크롤
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_stepsChartScrollController.hasClients) {
            _stepsChartScrollController.jumpTo(_stepsChartScrollController.position.maxScrollExtent);
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
                  // 🆕 [Y축 고정] Row로 "고정된 Y축 패널"과 "스크롤되는 날짜+막대 패널"을
                  // 나란히 배치. Y축 눈금(왼쪽)은 화면에 항상 고정되어 있고, 오른쪽의
                  // 날짜+막대만 좌우로 스크롤된다.
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🆕 [고정 Y축 패널] 실제 막대는 없고 눈금(라벨)만 그리는 전용 차트.
                      // 오른쪽 스크롤 차트와 높이/여백(reservedSize)을 똑같이 맞춰서
                      // 눈금 위치가 정확히 일치하도록 함.
                      SizedBox(
                        width: 52,
                        height: 240,
                        child: BarChart(
                          BarChartData(
                            minY: base,
                            maxY: top,
                            alignment: BarChartAlignment.spaceAround,
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(
                              show: true,
                              border: Border(
                                left: BorderSide(color: ExerciseTheme.brandGolden.withOpacity(0.5), width: 1.4),
                                bottom: BorderSide.none,
                                top: BorderSide.none,
                                right: BorderSide.none,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              // 🆕 [X축 자리는 숨기되 높이는 오른쪽과 똑같이 맞춤]
                              bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 28)),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 48,
                                  interval: interval,
                                  getTitlesWidget: (value, meta) {
                                    if (value < base - 0.5) return const SizedBox.shrink();
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Text(
                                        '${value.toInt()} •',
                                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                                        textAlign: TextAlign.right,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: const [], // 🆕 눈금만 그리는 패널이라 막대 없음
                          ),
                        ),
                      ),
                      // 🆕 [스크롤 패널] 날짜(X축 라벨)와 막대가 여기서 함께 좌우로 스크롤됨
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _stepsChartScrollController,
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
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      // 🆕 [Y축 라벨은 여기서 숨김] 왼쪽 고정 패널이 이미 그리고 있음
                                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
                                      // 🆕 [X축: 일자(날짜)] 막대와 함께 스크롤됨
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
                                // 🆕 [가위질(절단) 표시] 걸음수 원점이 500->1000으로 올라간
                                // 경우에만 표시. 운동시간 차트는 0부터 시작하므로 표시 안 함.
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
            decoration: _decoration(field.label, unit: field.unit),
          ),
        );
      case ExerciseFieldType.text:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _textControllers[field.key],
            style: const TextStyle(color: Colors.white),
            decoration: _decoration(field.label),
          ),
        );
      case ExerciseFieldType.select:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            initialValue: _selectValues[field.key],
            dropdownColor: ExerciseTheme.containerBgElevated,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration(field.label),
            items: (field.options ?? [])
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: (v) => setState(() => _selectValues[field.key] = v),
          ),
        );
      case ExerciseFieldType.counter:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: ExerciseTheme.luxeCardDecoration(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(field.label, style: ExerciseTheme.bodyStyle(color: Colors.white, size: 14)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: ExerciseTheme.brandGolden),
                      onPressed: () => setState(() {
                        _counterValues[field.key] = (_counterValues[field.key] ?? 0) - 1;
                        if (_counterValues[field.key]! < 0) _counterValues[field.key] = 0;
                      }),
                    ),
                    Text(
                      '${_counterValues[field.key] ?? 0}',
                      style: ExerciseTheme.titleStyle(size: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: ExerciseTheme.brandGolden),
                      onPressed: () => setState(() {
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

  Widget _buildMultiSetField(ExerciseField field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: ExerciseTheme.luxeCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label, style: ExerciseTheme.titleStyle(size: 14)),
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
                      '자각 운동강도 (RPE $_rpe · ${kRpeLabels[_rpe] ?? ''})',
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

          ...type.fields.map(_buildField),

          // 🆕 [모든 종목 공통] 걷기의 일별 걸음수 그래프와 같은 형태로,
          // 걷기가 아닌 종목은 '일별 운동시간(분)' 추이를 대신 보여줌.
          const SizedBox(height: 12),
          _buildDailyTrendChart(),

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
