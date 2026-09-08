// today_exercise_screen.dart
//
// 종목 카드를 탭하면 진입하는 기록 입력 화면.
// - 상단: 공통 필드 (날짜/시간/RPE/심박수/메모)
// - 하단: 선택한 종목(ExerciseType)의 상세 필드를 스키마 기반으로 동적 렌더링
// - 저장 시 exercise_calculations.dart의 공식으로 계산필드(isCalculated)를 채워
//   ExerciseRecord를 완성한 뒤 exercise_data_service.dart에 저장한다.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'exercise_models.dart';
import 'exercise_data_service.dart';
import 'exercise_calculations.dart';
import 'exercise_theme.dart';
import 'exercise_step_service.dart'; // 🆕 [만보기 연동 1단계+매일 자동기록] StepTrackingSession, DailyStepWatcherService

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

  bool get _isEditMode => widget.existingRecord != null;

  // 🆕 [만보기 연동 1단계] 이 종목이 '걸음수(steps)' 필드를 갖고 있을 때만
  // 자동 측정 카드를 보여준다 (걷기 외에 나중에 다른 종목이 steps 필드를
  // 추가해도 자동으로 지원됨 - 종목 id를 하드코딩하지 않음).
  bool get _hasStepsField => widget.exerciseType.fields.any((f) => f.key == 'steps');

  @override
  void initState() {
    super.initState();
    if (_hasStepsField) {
      _loadDailyAutoState(); // 🆕 [매일 자동기록] 토글 초기 상태 불러오기
      ExerciseStepService.loadPreferredSource().then((_) {
        if (mounted) setState(() {}); // 🆕 [2단계] 폰/워치 선택 상태를 화면에 반영
      });
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
    if (mounted) {
      ExerciseTheme.showLuxeSnackBar(
        context,
        type == StepSourceType.watch ? '워치(Health Connect/HealthKit) 측정으로 전환했습니다.' : '폰 센서 측정으로 전환했습니다.',
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
          detail['calories'] = calcCaloriesByMet(met: met, durationMin: durationMin);
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
          // 🆕 [2단계] 측정 소스 선택: 폰 센서 ↔ 워치(Health Connect/HealthKit)
          Row(
            children: [
              Expanded(child: _buildSourceChip('📱 폰', StepSourceType.phone)),
              const SizedBox(width: 8),
              Expanded(child: _buildSourceChip('⌚ 워치', StepSourceType.watch)),
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
          ],
        ],
      ),
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
