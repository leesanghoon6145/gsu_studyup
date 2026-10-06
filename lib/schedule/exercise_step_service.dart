// exercise_step_service.dart
//
// 🆕 [2026-10-05 전면 정비] 삼성헬스(워치 포함) + 폰 센서 걸음 자동 기록
//
// ■ 원칙
//  - 걸음수는 두 곳에서 읽는다
//      ① 삼성헬스 → Health Connect : 폰과 워치를 삼성헬스가 겹치지 않게 합친 값
//      ② 폰 자체 걸음 센서(pedometer) : 앱이 켜져 있는 동안 센 값
//    → 그날 "더 많은 쪽"을 그날 걸음으로 기록 (두 값을 더하지 않음 = 두 번 세지 않음)
//  - 거리 : 삼성헬스 거리가 있으면 그 값, 없으면 걸음 × 보폭(0.7m)으로 추정
//  - 걸린 시간 : 걸음 ÷ 1분 85보(보통 걸음)로 추정, 1km 걸린 시간 = 시간 ÷ 거리 (추정 표시)
//  - 어제 기록 : 앱을 열 때 삼성헬스에서 어제 하루치를 다시 읽어 확정 (앱이 꺼져 있던 사이 걸음까지)
//  - 확인 : 어제 자동 기록을 "맞나요? [확인] [고치기]"로 물어보고, 확인하지 않아도 그대로 저장
//  - 고치기 : 사용자가 고친 기록(userEdited)·확인한 기록(autoConfirmed)은 자동으로 덮어쓰지 않음
//  - 연결 점검 : 어느 단계에서 막혔는지 화면에서 바로 보이게 (runConnectionCheck)
//
// ■ 사전 조건 (2026-10-04 점검 완료)
//  - AndroidManifest.xml : ACTIVITY_RECOGNITION, health.READ_STEPS, health.READ_DISTANCE 등
//  - MainActivity : FlutterFragmentActivity
//  - minSdk 26
//  - 폰 : Health Connect 앱 설치(안드로이드 13 이하) + 삼성헬스 → Health Connect 연결 켜기
//
// ■ today_exercise_screen.dart 와의 약속 (예전 이름 그대로 유지)
//  StepDataSource, PhonePedometerSource, WatchHealthStepSource, StepSourceType,
//  ExerciseStepService, StepTrackingSession, DailyStepWatcherService

import 'dart:async';
import 'dart:convert'; // 🆕 [수면 2026-10-05] 수면 요약 저장
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer/pedometer.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'exercise_data_service.dart';
import 'exercise_models.dart';

// ============================================================================
// Health Connect(삼성헬스 · 워치) 창구 — 한 곳에서만 다룸
// ============================================================================
class HealthLink {
  HealthLink._();

  static final Health _h = Health();
  static bool _configured = false;

  static const List<HealthDataType> _types = [HealthDataType.STEPS, HealthDataType.DISTANCE_DELTA];
  static const List<HealthDataAccess> _access = [HealthDataAccess.READ, HealthDataAccess.READ];

  // health 패키지는 무엇을 하든 먼저 configure()가 필요함
  static Future<void> _cfg() async {
    if (_configured) return;
    try {
      await _h.configure();
      _configured = true;
    } catch (e) {
      debugPrint('[HealthLink] configure 오류: $e');
    }
  }

  /// Health Connect 설치 상태 (null = 확인 실패)
  static Future<HealthConnectSdkStatus?> sdkStatus() async {
    await _cfg();
    try {
      return await _h.getHealthConnectSdkStatus();
    } catch (e) {
      debugPrint('[HealthLink] sdkStatus 오류: $e');
      return null;
    }
  }

  static Future<bool> isInstalled() async => (await sdkStatus()) == HealthConnectSdkStatus.sdkAvailable;

  /// 걸음·거리 읽기 권한이 이미 있는지 (팝업 안 띄움)
  static Future<bool> hasPermission() async {
    await _cfg();
    try {
      return await _h.hasPermissions(_types, permissions: _access) ?? false;
    } catch (e) {
      debugPrint('[HealthLink] hasPermission 오류: $e');
      return false;
    }
  }

  /// 걸음·거리 읽기 권한 요청 (Health Connect 권한 화면이 뜸)
  static Future<bool> requestPermission() async {
    await _cfg();
    if (!await isInstalled()) return false;
    try {
      final bool ok = await _h.requestAuthorization(_types, permissions: _access);
      debugPrint('[HealthLink] 권한 요청 결과=$ok');
      return ok;
    } catch (e) {
      debugPrint('[HealthLink] requestPermission 오류: $e');
      return false;
    }
  }

  /// 설치돼 있고 권한도 있으면 true
  static Future<bool> isReady() async => await isInstalled() && await hasPermission();

  // 🆕 [1단계 + 수면 2026-10-05] 워치 운동 · 심박 · 칼로리 · 속도 · 수면 (걸음 권한과 따로 요청 →
  // 이쪽을 거절해도 걸음 자동 기록은 그대로 작동)
  static const List<HealthDataType> _extTypes = [
    HealthDataType.WORKOUT,
    HealthDataType.HEART_RATE,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.SLEEP_SESSION,
  ];
  static const List<HealthDataAccess> _extAccess = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  static Future<bool> hasExtendedPermission() async {
    await _cfg();
    try {
      return await _h.hasPermissions(_extTypes, permissions: _extAccess) ?? false;
    } catch (e) {
      debugPrint('[HealthLink] hasExtendedPermission 오류: $e');
      return false;
    }
  }

  static Future<bool> requestExtendedPermission() async {
    await _cfg();
    if (!await isInstalled()) return false;
    try {
      final bool ok = await _h.requestAuthorization(_extTypes, permissions: _extAccess);
      debugPrint('[HealthLink] 운동·심박·수면 권한 요청 결과=$ok');
      return ok;
    } catch (e) {
      debugPrint('[HealthLink] requestExtendedPermission 오류: $e');
      return false;
    }
  }

  static Future<List<HealthDataPoint>> _read(List<HealthDataType> t, DateTime from, DateTime to) async {
    try {
      return _h.removeDuplicates(await _h.getHealthDataFromTypes(types: t, startTime: from, endTime: to));
    } catch (e) {
      debugPrint('[HealthLink] 읽기 오류($t): $e');
      return [];
    }
  }

  static Future<List<HealthDataPoint>> workoutsBetween(DateTime from, DateTime to) => _read(const [HealthDataType.WORKOUT], from, to);

  /// 구간 평균 · 최고 심박 (없으면 null)
  static Future<(int?, int?)> heartRateBetween(DateTime from, DateTime to) async {
    final pts = await _read(const [HealthDataType.HEART_RATE], from, to);
    final List<double> v = [
      for (final p in pts)
        if (p.value is NumericHealthValue) (p.value as NumericHealthValue).numericValue.toDouble(),
    ];
    if (v.isEmpty) return (null, null);
    final double avg = v.reduce((a, b) => a + b) / v.length;
    final double mx = v.reduce((a, b) => a > b ? a : b);
    return (avg.round(), mx.round());
  }

  /// 구간 최고 속도 — 지금 쓰는 health 꾸러미에는 속도 항목이 없어 null (1km 가장 빠른 시간은 비워 둠)
  static Future<double?> maxSpeedBetween(DateTime from, DateTime to) async => null;

  /// 구간 칼로리 합계 (kcal, 없으면 null)
  static Future<double?> caloriesBetween(DateTime from, DateTime to) async {
    final pts = await _read(const [HealthDataType.TOTAL_CALORIES_BURNED], from, to);
    double sum = 0;
    for (final p in pts) {
      if (p.value is NumericHealthValue) sum += (p.value as NumericHealthValue).numericValue.toDouble();
    }
    return sum > 0 ? sum : null;
  }

  /// 구간 수면 (여러 조각이면 합침, 없으면 null)
  static Future<SleepSummary?> sleepBetween(DateTime from, DateTime to) async {
    final pts = await _read(const [HealthDataType.SLEEP_SESSION], from, to);
    if (pts.isEmpty) return null;
    int minutes = 0;
    DateTime? start;
    DateTime? end;
    for (final p in pts) {
      minutes += p.dateTo.difference(p.dateFrom).inMinutes;
      if (start == null || p.dateFrom.isBefore(start)) start = p.dateFrom;
      if (end == null || p.dateTo.isAfter(end)) end = p.dateTo;
    }
    if (minutes <= 0) return null;
    return SleepSummary(minutes: minutes, start: start, end: end);
  }

  /// Play 스토어의 Health Connect 설치·업데이트 화면 열기
  static Future<void> install() async {
    await _cfg();
    try {
      await _h.installHealthConnect();
    } catch (e) {
      debugPrint('[HealthLink] install 오류: $e');
    }
  }

  /// 구간 걸음 합계 (삼성헬스가 폰·워치를 겹치지 않게 합친 값). 실패하면 null
  static Future<int?> stepsBetween(DateTime from, DateTime to) async {
    try {
      return await _h.getTotalStepsInInterval(from, to);
    } catch (e) {
      debugPrint('[HealthLink] stepsBetween 오류: $e');
      return null;
    }
  }

  /// 구간 거리 합계(km). 없거나 실패하면 null
  static Future<double?> distanceKmBetween(DateTime from, DateTime to) async {
    try {
      final List<HealthDataPoint> points = _h.removeDuplicates(
        await _h.getHealthDataFromTypes(types: const [HealthDataType.DISTANCE_DELTA], startTime: from, endTime: to),
      );
      double meters = 0;
      for (final p in points) {
        final HealthValue v = p.value;
        if (v is NumericHealthValue) meters += v.numericValue.toDouble();
      }
      return meters > 0 ? meters / 1000.0 : null;
    } catch (e) {
      debugPrint('[HealthLink] distanceKmBetween 오류: $e');
      return null;
    }
  }
}

/// 🆕 [수면 2026-10-05] 하룻밤 수면 요약
class SleepSummary {
  final int minutes;
  final DateTime? start;
  final DateTime? end;
  const SleepSummary({required this.minutes, this.start, this.end});

  Map<String, dynamic> toJson() => {'minutes': minutes, 'start': start?.toIso8601String(), 'end': end?.toIso8601String()};

  factory SleepSummary.fromJson(Map<String, dynamic> j) => SleepSummary(
    minutes: (j['minutes'] as num?)?.toInt() ?? 0,
    start: DateTime.tryParse(j['start']?.toString() ?? ''),
    end: DateTime.tryParse(j['end']?.toString() ?? ''),
  );

  String get hoursText => '${minutes ~/ 60}시간 ${minutes % 60}분';
  String _hm(DateTime? d) => d == null ? '-' : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  String get rangeText => '${_hm(start)} ~ ${_hm(end)}';
}

/// 연결 점검표 한 줄
class StepCheckItem {
  final String label;
  final bool ok;
  final String detail;
  const StepCheckItem(this.label, this.ok, this.detail);
}

// ============================================================================
// 걸음 출처 공통 모양 (예전 이름 유지)
// ============================================================================
abstract class StepDataSource {
  Future<bool> isAvailable();
  Stream<int> todayStepsStream();
  Future<void> refreshNow();
}

/// 폰 자체 걸음 센서. 센서 값은 "부팅 이후 누적"이라 오늘 처음 받은 값을 기준으로 빼서 "오늘 걸음"으로 바꿈
class PhonePedometerSource implements StepDataSource {
  static const String _kBaselineDateKey = 'gke_pedometer_baseline_date';
  static const String _kBaselineCountKey = 'gke_pedometer_baseline_count';

  @override
  Future<bool> isAvailable() async {
    try {
      PermissionStatus status = await Permission.activityRecognition.status;
      if (!status.isGranted) status = await Permission.activityRecognition.request();
      debugPrint('[PhonePedometerSource] 신체 활동 권한=$status');
      return status.isGranted;
    } catch (e) {
      debugPrint('[PhonePedometerSource] isAvailable 오류: $e');
      return false;
    }
  }

  static Future<bool> isPermanentlyDenied() async => (await Permission.activityRecognition.status).isPermanentlyDenied;

  String _dateKeyOf(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static const String _kLastRawKey = 'gke_pedometer_last_raw'; // 🆕 마지막으로 본 센서 누적값
  static const String _kLastRawDateKey = 'gke_pedometer_last_raw_date';

  // 🆕 [2026-10-05] 앱을 늦게 열어도 아침부터 걸은 걸음이 빠지지 않게:
  // 오늘의 기준값 = "어제 마지막으로 본 센서 누적값" (휴대폰을 껐다 켜서 누적값이 줄었으면 0부터)
  @override
  Stream<int> todayStepsStream() {
    return Pedometer.stepCountStream.asyncMap((event) async {
      final prefs = await SharedPreferences.getInstance();
      final String todayKey = _dateKeyOf(DateTime.now());
      final String? storedDate = prefs.getString(_kBaselineDateKey);
      int? baseline = prefs.getInt(_kBaselineCountKey);
      final int raw = event.steps;

      if (storedDate != todayKey || baseline == null) {
        final int? lastRaw = prefs.getInt(_kLastRawKey);
        final String? lastRawDate = prefs.getString(_kLastRawDateKey);
        final DateTime n = DateTime.now();
        final String yesterdayKey = _dateKeyOf(DateTime(n.year, n.month, n.day).subtract(const Duration(days: 1)));
        if (lastRaw != null && lastRawDate == yesterdayKey && raw >= lastRaw) {
          baseline = lastRaw; // 어제 마지막 값 이후 걸음은 모두 오늘 걸음
        } else if (lastRaw != null && raw < lastRaw) {
          baseline = 0; // 휴대폰을 다시 켜서 센서가 0부터 다시 셈
        } else {
          baseline = raw; // 처음 쓰는 날
        }
        await prefs.setString(_kBaselineDateKey, todayKey);
        await prefs.setInt(_kBaselineCountKey, baseline);
      } else if (raw < baseline) {
        baseline = 0; // 오늘 중에 휴대폰을 다시 켬
        await prefs.setInt(_kBaselineCountKey, 0);
      }
      await prefs.setInt(_kLastRawKey, raw);
      await prefs.setString(_kLastRawDateKey, todayKey);
      return (raw - baseline).clamp(0, 1000000);
    });
  }

  @override
  Future<void> refreshNow() async {}
}

/// 삼성헬스(워치 포함) 출처 — Health Connect에서 오늘 걸음을 1분마다 읽음
class WatchHealthStepSource implements StepDataSource {
  Timer? _pollTimer;
  StreamController<int>? _controller;

  @override
  Future<bool> isAvailable() async {
    if (!await HealthLink.isInstalled()) return false;
    if (await HealthLink.hasPermission()) return true;
    return HealthLink.requestPermission();
  }

  @override
  Stream<int> todayStepsStream() {
    _controller?.close();
    _pollTimer?.cancel();
    final controller = StreamController<int>.broadcast();
    _controller = controller;
    _poll();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _poll());
    return controller.stream;
  }

  Future<void> _poll() async {
    final now = DateTime.now();
    final int? steps = await HealthLink.stepsBetween(DateTime(now.year, now.month, now.day), now);
    debugPrint('[WatchHealthStepSource] 오늘 걸음=$steps');
    if (steps != null && _controller != null && !_controller!.isClosed) _controller!.add(steps);
  }

  @override
  Future<void> refreshNow() => _poll();

  void dispose() {
    _pollTimer?.cancel();
    _controller?.close();
  }
}

enum StepSourceType { phone, watch }

class ExerciseStepService {
  ExerciseStepService._();

  static const String _kSourcePrefKey = 'gke_step_source_type';

  static StepDataSource activeSource = PhonePedometerSource();
  static StepSourceType activeSourceType = StepSourceType.phone;

  static Future<void> loadPreferredSource() async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_kSourcePrefKey);
    if (saved == 'watch') {
      activeSource = WatchHealthStepSource();
      activeSourceType = StepSourceType.watch;
    } else {
      activeSource = PhonePedometerSource();
      activeSourceType = StepSourceType.phone;
    }
  }

  static Future<void> setPreferredSource(StepSourceType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSourcePrefKey, type == StepSourceType.watch ? 'watch' : 'phone');
    activeSource = type == StepSourceType.watch ? WatchHealthStepSource() : PhonePedometerSource();
    activeSourceType = type;
  }

  /// 새로고침 단추: 지금 출처 + 자동 기록 모두 즉시 다시 읽기
  static Future<void> refreshNow() async {
    await activeSource.refreshNow();
    await DailyStepWatcherService.instance.syncNow();
  }

  static const double averageStrideMeters = 0.7;
  static double stepsToKm(int steps) => (steps * averageStrideMeters) / 1000.0;
}

/// "측정 시작~종료" 한 번 (예전 기능 유지)
class StepTrackingSession {
  StreamSubscription<int>? _subscription;
  int? _baselineSteps;
  int currentSteps = 0;
  bool isTracking = false;

  final void Function(int steps) onUpdate;
  final void Function(Object error)? onError;

  StepTrackingSession({required this.onUpdate, this.onError});

  Future<bool> start() async {
    final source = ExerciseStepService.activeSource;
    if (!await source.isAvailable()) return false;
    isTracking = true;
    _baselineSteps = null;
    currentSteps = 0;
    _subscription = source.todayStepsStream().listen(
          (todaySteps) {
        _baselineSteps ??= todaySteps;
        currentSteps = (todaySteps - _baselineSteps!).clamp(0, 1000000);
        onUpdate(currentSteps);
      },
      onError: (e) => onError?.call(e),
    );
    return true;
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    isTracking = false;
  }

  void dispose() => _subscription?.cancel();
}

// ============================================================================
// 매일 자동 기록 — 삼성헬스와 폰 센서 중 많은 쪽 + 어제 확정 + 확인 카드
// ============================================================================
class DailyStepWatcherService {
  DailyStepWatcherService._();
  static final DailyStepWatcherService instance = DailyStepWatcherService._();

  static const String _kEnabledKey = 'gke_daily_step_auto_enabled';
  static const String autoRecordIdPrefix = 'auto_daily_walk_';
  static const String _kLegacyMemo = '자동 기록 (만보기, 매일 자동)';
  static const String _kMemo = '⌚ 자동 기록 (삼성헬스·폰 중 많은 걸음)';
  static const String _kExtAskedKey = 'gke_health_ext_asked';
  static const String _kImportedKey = 'gke_imported_workout_ids';
  static const String workoutRecordIdPrefix = 'auto_workout_';

  StreamSubscription<int>? _phoneSub;
  Timer? _timer;
  bool _isRunning = false;
  bool _syncing = false;

  int _phoneToday = 0;
  int _healthToday = 0;
  double? _healthDistanceToday;
  String _todayKey = '';

  /// 연결 점검표에 보여 줄 최근 값
  int get lastPhoneSteps => _phoneToday;
  int get lastHealthSteps => _healthToday;
  DateTime? lastSyncAt;

  final StreamController<int> _liveStepsController = StreamController<int>.broadcast();
  Stream<int> get liveTodaySteps => _liveStepsController.stream;

  bool get isRunning => _isRunning;

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabledKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabledKey, enabled);
    if (enabled) {
      await start();
    } else {
      stop();
    }
  }

  Future<void> resumeIfEnabled() async {
    if (await isEnabled()) {
      await ExerciseStepService.loadPreferredSource();
      await start();
    }
  }

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    // ① 폰 센서 (권한이 있을 때만 — 없으면 삼성헬스만으로 기록)
    final phone = PhonePedometerSource();
    if (await phone.isAvailable()) {
      _phoneSub = phone.todayStepsStream().listen(
            (s) {
          _rollDateIfNeeded();
          _phoneToday = s;
          _applyToday();
        },
        onError: (e) => debugPrint('[DailyStepWatcher] 폰 센서 오류: $e'),
      );
    }

    // ② 삼성헬스(Health Connect) — 권한이 아직 없으면 한 번 요청
    if (await HealthLink.isInstalled() && !await HealthLink.hasPermission()) {
      await HealthLink.requestPermission();
    }
    // ③ 🆕 워치 운동 · 심박 · 칼로리 · 속도 · 수면 — 처음 한 번만 물어봄 (거절해도 걸음 기록은 그대로)
    final prefs0 = await SharedPreferences.getInstance();
    if (await HealthLink.isInstalled() && !(prefs0.getBool(_kExtAskedKey) ?? false) && !await HealthLink.hasExtendedPermission()) {
      await prefs0.setBool(_kExtAskedKey, true);
      await HealthLink.requestExtendedPermission();
    }

    await syncNow();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => syncNow());
  }

  void stop() {
    _phoneSub?.cancel();
    _phoneSub = null;
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  void _rollDateIfNeeded() {
    final String k = _dateKeyOf(DateTime.now());
    if (k != _todayKey) {
      _todayKey = k;
      _phoneToday = 0;
      _healthToday = 0;
      _healthDistanceToday = null;
    }
  }

  /// 삼성헬스에서 오늘 · 어제를 다시 읽어 기록에 반영 (앱 열 때 · 1분마다 · 새로고침 단추)
  Future<void> syncNow() async {
    if (_syncing) return;
    _syncing = true;
    try {
      _rollDateIfNeeded();
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      if (await HealthLink.isReady()) {
        _healthToday = await HealthLink.stepsBetween(today, now) ?? _healthToday;
        _healthDistanceToday = await HealthLink.distanceKmBetween(today, now) ?? _healthDistanceToday;

        // 어제 하루치 확정 (앱이 꺼져 있던 사이 걸은 것까지)
        final DateTime yesterday = today.subtract(const Duration(days: 1));
        final int? ySteps = await HealthLink.stepsBetween(yesterday, today);
        if (ySteps != null && ySteps > 0) {
          final double? yKm = await HealthLink.distanceKmBetween(yesterday, today);
          await _upsertAutoRecord(_dateKeyOf(yesterday), ySteps, source: 'samsungHealth', distanceKm: yKm, keepMax: true);
        }
      }
      // 🆕 워치 운동 자동 가져오기 + 어젯밤 수면
      if (await HealthLink.isInstalled() && await HealthLink.hasExtendedPermission()) {
        await _importWorkouts(today.subtract(const Duration(days: 1)), now);
        await _syncSleep(today);
      }
      await _applyToday();
      lastSyncAt = DateTime.now();
    } catch (e) {
      debugPrint('[DailyStepWatcher] syncNow 오류: $e');
    } finally {
      _syncing = false;
    }
  }

  Future<void> _applyToday() async {
    final bool healthWins = _healthToday >= _phoneToday && _healthToday > 0;
    final int steps = healthWins ? _healthToday : _phoneToday;
    if (steps <= 0) return;
    await _upsertAutoRecord(
      _dateKeyOf(DateTime.now()),
      steps,
      source: healthWins ? 'samsungHealth' : 'phone',
      distanceKm: healthWins ? _healthDistanceToday : null,
      keepMax: true,
    );
    _liveStepsController.add(steps);
  }

  String _dateKeyOf(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<int?> getTodaySavedSteps() async {
    final String todayKey = _dateKeyOf(DateTime.now());
    final all = await ExerciseDataService.instance.getAllRecords();
    final existing = all.where((r) => r.recordId == '$autoRecordIdPrefix$todayKey').toList();
    if (existing.isEmpty) return null;
    final steps = existing.first.detail['steps'];
    return steps is num ? steps.toInt() : null;
  }

  /// 🆕 확인을 기다리는 자동 기록 (종목별) — 어제 걸음 + 어제·오늘 워치 운동
  Future<List<ExerciseRecord>> getPendingConfirmRecords(String typeId) async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime since = today.subtract(const Duration(days: 1));
    final all = await ExerciseDataService.instance.getAllRecords();
    final List<ExerciseRecord> list = all.where((r) {
      if (r.exerciseTypeId != typeId || !r.recordId.startsWith('auto_')) return false;
      final d = r.detail;
      if (d['userEdited'] == true || d['autoConfirmed'] == true) return false;
      if (d['autoSource'] == null && r.memo != _kLegacyMemo) return false;
      final DateTime day = DateTime(r.date.year, r.date.month, r.date.day);
      if (day.isBefore(since)) return false; // 이틀 지나면 확인 없이 그대로 확정
      if (r.recordId.startsWith(autoRecordIdPrefix) && !day.isBefore(today)) return false; // 오늘 걸음은 아직 늘어나는 중
      return true;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// 예전 이름 (걷기 확인 카드)
  Future<ExerciseRecord?> getPendingConfirmRecord() async {
    final list = await getPendingConfirmRecords('walking');
    return list.isEmpty ? null : list.first;
  }

  // 🆕 [수면 2026-10-05] 그날 아침 기준 "어젯밤 수면"
  Future<void> _syncSleep(DateTime today) async {
    final SleepSummary? s = await HealthLink.sleepBetween(
      today.subtract(const Duration(hours: 6)), // 어제 18시부터
      today.add(const Duration(hours: 14)), // 오늘 14시까지
    );
    if (s == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gke_sleep_${_dateKeyOf(today)}', jsonEncode(s.toJson()));
  }

  /// 그날 아침에 깬 수면 (저장된 것, 없으면 null)
  Future<SleepSummary?> getSleepFor(DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('gke_sleep_${_dateKeyOf(day)}');
    if (raw == null) return null;
    try {
      return SleepSummary.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  // 🆕 [워치 운동 2026-10-05] 삼성헬스 운동 → 우리 종목으로
  // 걷기 운동은 "걸음 자동 기록"과 시간이 겹쳐 두 번 세지 않도록 가져오지 않음
  static String? _mapWorkout(String raw) {
    final String n = raw.toUpperCase();
    if (n.contains('WALK')) return null;
    if (n.contains('TABLE_TENNIS')) return 'tabletennis';
    if (n.contains('TENNIS')) return 'tennis';
    if (n.contains('BADMINTON')) return 'badminton';
    if (n.contains('BASKETBALL')) return 'basketball';
    if (n.contains('SOCCER')) return 'soccer';
    if (n.contains('GOLF')) return 'golf';
    if (n.contains('SWIM')) return 'swimming';
    if (n.contains('RUN') || n.contains('JOG')) return 'running';
    if (n.contains('BIK') || n.contains('CYCL')) return 'cycling';
    if (n.contains('HIK') || n.contains('MOUNTAIN') || n.contains('CLIMB')) return 'hiking';
    if (n.contains('SKI') || n.contains('SNOWBOARD')) return 'skiing';
    if (n.contains('PILATES')) return 'pilates';
    if (n.contains('YOGA')) return 'yoga';
    if (n.contains('STRENGTH') || n.contains('WEIGHT')) return 'gym';
    return 'etc';
  }

  Future<void> _importWorkouts(DateTime from, DateTime to) async {
    final prefs = await SharedPreferences.getInstance();
    final Set<String> done = (prefs.getStringList(_kImportedKey) ?? const <String>[]).toSet();
    final List<HealthDataPoint> pts = await HealthLink.workoutsBetween(from, to);
    bool changed = false;
    for (final p in pts) {
      final HealthValue v = p.value;
      if (v is! WorkoutHealthValue) continue;
      final String uid = p.uuid;
      if (uid.isEmpty || done.contains(uid)) continue; // 한 번 가져온 운동은 다시 안 가져옴 (지워도 되살아나지 않음)
      done.add(uid);
      changed = true;

      final String rawType = v.workoutActivityType.name;
      final String? typeId = _mapWorkout(rawType);
      final int minutes = p.dateTo.difference(p.dateFrom).inMinutes;
      if (typeId == null || minutes < 3) continue;

      final (int? avgHr, int? maxHr) = await HealthLink.heartRateBetween(p.dateFrom, p.dateTo);
      final double? maxSpeed = await HealthLink.maxSpeedBetween(p.dateFrom, p.dateTo);
      double? kcal = v.totalEnergyBurned?.toDouble();
      if (kcal == null || kcal <= 0) kcal = await HealthLink.caloriesBetween(p.dateFrom, p.dateTo);
      final double? meters = v.totalDistance?.toDouble();
      final double? km = (meters != null && meters > 0) ? meters / 1000.0 : null;

      final Map<String, dynamic> detail = {
        'autoSource': 'samsungHealth',
        'autoWorkout': true,
      };
      if (typeId == 'etc') detail['activityName'] = rawType;
      if (km != null) {
        if (typeId == 'swimming') {
          detail['distanceM'] = meters!.round();
        } else {
          detail['distanceKm'] = double.parse(km.toStringAsFixed(2));
        }
        if (typeId == 'running' || typeId == 'hiking') {
          detail['paceMinPerKm'] = double.parse((minutes / km).toStringAsFixed(1));
        }
        if (typeId == 'cycling') {
          detail['avgSpeedKmh'] = double.parse((km / (minutes / 60.0)).toStringAsFixed(1));
        }
      }
      if (maxSpeed != null) {
        if (typeId == 'running') {
          // 순간 최고 속도로 계산한 값이라 "추정"
          detail['maxPaceMinPerKm'] = double.parse((60 / (maxSpeed * 3.6)).toStringAsFixed(1));
          detail['estimated'] = true;
        }
        if (typeId == 'cycling') detail['maxSpeedKmh'] = double.parse((maxSpeed * 3.6).toStringAsFixed(1));
      }
      if (kcal != null && kcal > 0) detail['calories'] = kcal.round();

      await ExerciseDataService.instance.addRecord(ExerciseRecord(
        recordId: '$workoutRecordIdPrefix$uid',
        exerciseTypeId: typeId,
        date: p.dateFrom,
        startTime: p.dateFrom,
        endTime: p.dateTo,
        durationMin: minutes,
        avgHeartRateBpm: avgHr,
        maxHeartRateBpm: maxHr,
        memo: '⌚ 워치 운동 자동 기록 (삼성헬스)',
        detail: detail,
      ));
      debugPrint('[DailyStepWatcher] 워치 운동 가져옴: $rawType → $typeId, $minutes분');
    }
    if (changed) await prefs.setStringList(_kImportedKey, done.toList());
  }

  /// "맞아요" — 그대로 확정 (이후 자동으로 바뀌지 않음)
  Future<void> confirm(ExerciseRecord r) async {
    final Map<String, dynamic> d = Map<String, dynamic>.from(r.detail)..['autoConfirmed'] = true;
    await ExerciseDataService.instance.updateRecord(r.copyWith(detail: d));
  }

  /// 그날 자동 걷기 기록을 만들거나 갱신. 고친 기록 · 확인한 기록은 건드리지 않음
  Future<void> _upsertAutoRecord(String dateKey, int steps, {required String source, double? distanceKm, bool keepMax = false}) async {
    final parts = dateKey.split('-');
    final DateTime date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final String recordId = '$autoRecordIdPrefix$dateKey';

    final all = await ExerciseDataService.instance.getAllRecords();
    final existingList = all.where((r) => r.recordId == recordId).toList();
    final ExerciseRecord? existing = existingList.isEmpty ? null : existingList.first;

    if (existing != null) {
      final d = existing.detail;
      if (d['userEdited'] == true || d['autoConfirmed'] == true) return; // 사람이 손댄 기록은 그대로
      if (d['autoSource'] == null && existing.memo != _kLegacyMemo) return; // 직접 만든 기록
      final int old = (d['steps'] as num?)?.toInt() ?? 0;
      if (keepMax && old > steps) return; // 이미 더 큰 값이 있으면 그대로 (많은 쪽 원칙)
      if (old == steps && d['autoSource'] == source) return; // 바뀐 게 없으면 쓰지 않음
    }

    final double km = (distanceKm != null && distanceKm > 0)
        ? double.parse(distanceKm.toStringAsFixed(2))
        : double.parse(ExerciseStepService.stepsToKm(steps).toStringAsFixed(2));
    final int minutes = (steps / 85).round(); // 🆕 [2026-10-05] 보통 걸음 1분 80~90보 → 85보로 추정
    final Map<String, dynamic> detail = {
      'steps': steps,
      'distanceKm': km,
      if (km > 0 && minutes > 0) 'paceMinPerKm': double.parse((minutes / km).toStringAsFixed(1)),
      'autoSource': source, // samsungHealth / phone
      'estimated': true, // 시간 · 1km 걸린 시간은 추정
      if (distanceKm == null || distanceKm <= 0) 'distanceEstimated': true,
    };

    if (existing != null) {
      await ExerciseDataService.instance.updateRecord(existing.copyWith(detail: detail, durationMin: minutes, memo: _kMemo));
    } else {
      await ExerciseDataService.instance.addRecord(ExerciseRecord(
        recordId: recordId,
        exerciseTypeId: 'walking',
        date: date,
        durationMin: minutes,
        memo: _kMemo,
        detail: detail,
      ));
    }
  }

  // ==========================================================================
  // 🔍 연결 점검 — 어느 단계에서 막혔는지 한눈에
  // ==========================================================================
  static Future<List<StepCheckItem>> runConnectionCheck() async {
    final List<StepCheckItem> items = [];
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    final HealthConnectSdkStatus? st = await HealthLink.sdkStatus();
    final bool installed = st == HealthConnectSdkStatus.sdkAvailable;
    items.add(StepCheckItem(
      '① Health Connect 설치',
      installed,
      st == null
          ? '확인하지 못했어요'
          : installed
          ? '설치됨'
          : st == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired
          ? '업데이트가 필요해요 → [설치·업데이트]'
          : '설치돼 있지 않아요 → [설치·업데이트]',
    ));

    final bool perm = installed && await HealthLink.hasPermission();
    items.add(StepCheckItem('② 걸음·거리 읽기 권한', perm, perm ? '허용됨' : '허용 안 됨 → [권한 다시 요청]'));

    int? hSteps;
    if (perm) hSteps = await HealthLink.stepsBetween(today, now);
    items.add(StepCheckItem(
      '③ 삼성헬스 → 오늘 걸음',
      (hSteps ?? 0) > 0,
      !perm
          ? '권한이 있어야 읽을 수 있어요'
          : hSteps == null
          ? '읽지 못했어요'
          : hSteps == 0
          ? '0보 — 삼성헬스 → 설정 → Health Connect 연결을 켜 주세요'
          : '$hSteps보',
    ));

    final bool phonePerm = (await Permission.activityRecognition.status).isGranted;
    items.add(StepCheckItem('④ 폰 신체 활동 권한', phonePerm, phonePerm ? '허용됨' : '허용 안 됨 → [폰 권한 설정 열기]'));

    final DailyStepWatcherService w = DailyStepWatcherService.instance;
    items.add(StepCheckItem('⑤ 폰 센서 → 오늘 걸음', phonePerm, phonePerm ? '${w.lastPhoneSteps}보 (앱이 켜져 있는 동안 센 값)' : '권한이 있어야 세요'));

    final bool ext = installed && await HealthLink.hasExtendedPermission();
    items.add(StepCheckItem('⑦ 워치 운동 · 심박 · 수면 권한', ext, ext ? '허용됨 (워치 운동 · 수면 자동 기록)' : '허용 안 됨 → [운동·수면 권한 요청]'));

    final bool on = await w.isEnabled() && w.isRunning;
    items.add(StepCheckItem(
      '⑥ 매일 자동 기록',
      on,
      on
          ? '켜짐 · 마지막 확인 ${w.lastSyncAt == null ? '-' : '${w.lastSyncAt!.hour.toString().padLeft(2, '0')}:${w.lastSyncAt!.minute.toString().padLeft(2, '0')}'}'
          : '꺼짐 → [자동 기록 켜기]',
    ));
    return items;
  }
}
