// exercise_step_service.dart
//
// 걸음수 자동 측정 추상화 레이어.
// - 1단계: 폰 자체 만보기 센서 (PhonePedometerSource, pedometer 패키지)
// - 2단계(이번 추가): 워치 연동 (WatchHealthStepSource, health 패키지 ->
//   안드로이드는 Health Connect, iOS는 HealthKit을 거쳐 삼성헬스/애플헬스에
//   동기화된 워치 걸음수를 읽어옴)
//
// ✅ [2단계 - 인터페이스 통일] 워치는 폰 센서처럼 "기기 부팅 이후 누적값"을
// 안 주고, "특정 구간의 걸음수"를 조회하는 방식이라 데이터 형태가 근본적으로
// 다르다. 그래서 인터페이스를 "오늘 자정부터 지금까지의 누적 걸음수"로
// 통일했다 - 소스가 폰이든 워치든 항상 이 의미로 값을 내보내게 만들어서,
// StepTrackingSession(세션 측정)/DailyStepWatcherService(매일 자동기록)는
// 소스가 뭔지 몰라도 항상 같은 방식으로 계산할 수 있다.
//
// today_exercise_screen.dart는 이 파일의 공개 클래스만 알고, 실제 걸음수가
// 폰에서 오는지 워치에서 오는지는 전혀 모른다. 설정에서 소스만 바꾸면 됨.
//
// ⚠️ [사전 조건]
// pubspec.yaml:
//   pedometer: ^4.0.1
//   health: ^12.2.0   (버전에 따라 API가 조금씩 다를 수 있음 - 컴파일 에러
//                       나면 설치된 버전의 health 패키지 문서에서 메서드명 확인)
// 안드로이드: AndroidManifest.xml에 ACTIVITY_RECOGNITION(폰 센서) +
//   Health Connect 관련 권한/쿼리 선언 필요 (추가함).
// iOS: Info.plist에 NSMotionUsageDescription, NSHealthShareUsageDescription
//   키 추가 필요.
// 안드로이드 기기에는 "Health Connect" 앱이 설치되어 있어야 하고(안드로이드
// 14+는 기본 내장), 삼성헬스 등에서 Health Connect로 걸음수 동기화가 켜져
// 있어야 워치 걸음수가 실제로 넘어옴.

import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'exercise_data_service.dart';
import 'exercise_models.dart';

/// 걸음수 데이터 출처가 구현해야 하는 공통 인터페이스.
abstract class StepDataSource {
  /// 이 출처를 지금 사용할 수 있는 상태인지 (권한/기기 지원 여부 등)
  Future<bool> isAvailable();

  /// 🆕 [2단계] "오늘 자정부터 지금까지의 누적 걸음수"를 내보내는 스트림.
  /// 폰 센서든 워치든 항상 이 의미로 통일해서 내보낸다.
  Stream<int> todayStepsStream();
}

/// 🆕 [1단계] 폰 자체 만보기 센서 (pedometer 패키지, 안드로이드
/// TYPE_STEP_COUNTER / iOS CoreMotion 기반).
///
/// 원본 센서값은 "기기 부팅 이후 누적값"이라 그대로 쓰면 안 됨. 그래서 오늘
/// 날짜의 기준값(baseline)을 SharedPreferences에 저장해두고, 매 이벤트마다
/// (원본값 - 오늘의 기준값)을 계산해서 "오늘 걸음수"로 변환해 내보낸다.
/// 기준값을 SharedPreferences에 저장하기 때문에 앱을 재시작해도 오늘 걸음수가
/// 유지된다.
class PhonePedometerSource implements StepDataSource {
  static const String _kBaselineDateKey = 'gke_pedometer_baseline_date';
  static const String _kBaselineCountKey = 'gke_pedometer_baseline_count';

  @override
  Future<bool> isAvailable() async {
    try {
      final completer = Completer<bool>();
      late StreamSubscription sub;
      sub = Pedometer.stepCountStream.listen(
            (_) {
          if (!completer.isCompleted) completer.complete(true);
          sub.cancel();
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(false);
          sub.cancel();
        },
        cancelOnError: true,
      );
      return await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          sub.cancel();
          return false;
        },
      );
    } catch (e) {
      return false;
    }
  }

  String _dateKeyOf(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Stream<int> todayStepsStream() {
    return Pedometer.stepCountStream.asyncMap((event) async {
      final prefs = await SharedPreferences.getInstance();
      final String todayKey = _dateKeyOf(DateTime.now());
      final String? storedDate = prefs.getString(_kBaselineDateKey);
      int? baseline = prefs.getInt(_kBaselineCountKey);

      if (storedDate != todayKey || baseline == null) {
        // 🆕 오늘 처음 받은 값을 오늘의 기준값으로 저장 (자정이 지나 날짜가
        // 바뀌었을 때도 이 분기를 타서 자동으로 기준값이 새로 세팅됨)
        baseline = event.steps;
        await prefs.setString(_kBaselineDateKey, todayKey);
        await prefs.setInt(_kBaselineCountKey, baseline);
      }
      return (event.steps - baseline).clamp(0, 1000000);
    });
  }
}

/// 🆕 [2단계] 워치 연동 소스. health 패키지로 Health Connect(안드로이드)/
/// HealthKit(iOS)에서 "오늘 걸음수"를 주기적으로(30초마다) 조회해서 내보낸다.
/// 워치 자체와 직접 통신하지 않고, 워치가 이미 삼성헬스/애플헬스 등에
/// 동기화해둔 걸음수를 Health Connect/HealthKit을 거쳐 읽어오는 방식이다.
class WatchHealthStepSource implements StepDataSource {
  final Health _health = Health();
  Timer? _pollTimer;
  StreamController<int>? _controller;

  @override
  Future<bool> isAvailable() async {
    try {
      const types = [HealthDataType.STEPS];
      const permissions = [HealthDataAccess.READ];
      bool granted = await _health.hasPermissions(types, permissions: permissions) ?? false;
      if (!granted) {
        granted = await _health.requestAuthorization(types, permissions: permissions);
      }
      return granted;
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<int> todayStepsStream() {
    _controller?.close();
    _pollTimer?.cancel();
    final controller = StreamController<int>.broadcast();
    _controller = controller;

    Future<void> poll() async {
      try {
        final now = DateTime.now();
        final midnight = DateTime(now.year, now.month, now.day);
        final int steps = await _health.getTotalStepsInInterval(midnight, now) ?? 0;
        if (!controller.isClosed) controller.add(steps);
      } catch (e) {
        // 조회 실패는 조용히 무시하고 다음 폴링에서 재시도 (네트워크 일시 오류 등)
      }
    }

    poll(); // 구독 시작하자마자 한 번 즉시 조회
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => poll());
    return controller.stream;
  }

  void dispose() {
    _pollTimer?.cancel();
    _controller?.close();
  }
}

/// 걸음수 측정 소스 종류 (설정 화면/토글에서 사용자가 고름)
enum StepSourceType { phone, watch }

/// 걸음수 측정 소스를 앱 전체에서 한 곳에서 관리.
class ExerciseStepService {
  ExerciseStepService._();

  static const String _kSourcePrefKey = 'gke_step_source_type';

  static StepDataSource activeSource = PhonePedometerSource();
  static StepSourceType activeSourceType = StepSourceType.phone;

  /// 앱 시작 시(또는 걷기 화면 진입 시) 사용자가 이전에 골라둔 소스를 불러옴.
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

  /// 사용자가 "폰으로 측정" / "워치로 측정"을 고르면 호출. 선택은 계속 기억됨.
  static Future<void> setPreferredSource(StepSourceType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSourcePrefKey, type == StepSourceType.watch ? 'watch' : 'phone');
    activeSource = type == StepSourceType.watch ? WatchHealthStepSource() : PhonePedometerSource();
    activeSourceType = type;
  }

  /// 평균 보폭(m). 걸음수 → 거리(km) 자동 환산에 사용.
  static const double averageStrideMeters = 0.7;

  static double stepsToKm(int steps) => (steps * averageStrideMeters) / 1000.0;
}

/// 측정 시작~종료 한 세션을 다루는 컨트롤러. 스트림의 첫 값을 "세션 시작
/// 시점의 오늘 누적 걸음수"로 기록해두고, 그 이후 값에서 빼서 "이번 세션에서
/// 걸은 걸음수"만 뽑아낸다. 소스가 폰이든 워치든 todayStepsStream()이 항상
/// "오늘 걸음수"를 주기 때문에 이 계산은 소스 종류와 무관하게 항상 맞다.
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
    final available = await source.isAvailable();
    if (!available) return false;

    isTracking = true;
    _baselineSteps = null;
    currentSteps = 0;

    _subscription = source.todayStepsStream().listen(
          (todaySteps) {
        _baselineSteps ??= todaySteps; // 측정 시작 시점의 오늘 누적값을 기준선으로 고정
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

  void dispose() {
    _subscription?.cancel();
  }
}

// ============================================================================
// 🆕 [매일 자동기록] DailyStepWatcherService
//
// ReminderWatcherService(30초마다 알람 시각 확인하는 감시자)와 같은 설계
// 원칙: 앱이 켜져있는 동안 계속 "오늘 걸음수"를 받아서, 그날 날짜로 자동
// 기록을 갱신한다.
//
// ✅ [2단계 - 로직 단순화] todayStepsStream()이 이제 소스 종류와 무관하게
// 항상 "오늘 걸음수"를 직접 주기 때문에(자정 기준 계산은 각 소스 내부에서
// 이미 처리됨), 이 서비스는 더 이상 자체적으로 기준값/롤오버 계산을 할
// 필요가 없다. 그냥 받은 값을 오늘 날짜의 기록에 반영하기만 하면 되고,
// 자정이 지나 소스가 스스로 리셋하면 자동으로 새 날짜에 새 값이 쌓인다.
// 어제 기록은 자정 전 마지막으로 반영된 값 그대로 남아있어 별도 "확정" 절차가
// 필요 없다.
//
// ⚠️ [제약사항] 앱 프로세스가 살아있어야 갱신됩니다. 완전히 종료하면 그
// 사이엔 자동 기록이 안 쌓이다가, 다음에 앱을 열면 그 시점 값으로 갱신됩니다
// (걸음 자체가 사라지는 건 아니고, 실시간 반영이 잠시 멈추는 것뿐).
// ============================================================================
class DailyStepWatcherService {
  DailyStepWatcherService._();
  static final DailyStepWatcherService instance = DailyStepWatcherService._();

  static const String _kEnabledKey = 'gke_daily_step_auto_enabled';
  static const String _kAutoRecordIdPrefix = 'auto_daily_walk_';

  StreamSubscription<int>? _subscription;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  /// 사용자가 "매일 자동 기록"을 켜둔 적이 있는지 확인 (앱 재시작 후에도 기억함)
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabledKey) ?? false;
  }

  /// 토글 스위치에서 호출 - 켜면 즉시 감시 시작, 끄면 감시 중단(저장된 기록은 남음)
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabledKey, enabled);
    if (enabled) {
      await start();
    } else {
      stop();
    }
  }

  /// 🆕 앱 시작 시 한 번 호출 - 이전에 "매일 자동 기록"을 켜둔 적이 있으면
  /// 걷기 화면에 안 들어가도 자동으로 다시 감시를 시작함.
  Future<void> resumeIfEnabled() async {
    if (await isEnabled()) {
      await start();
    }
  }

  Future<void> start() async {
    if (_isRunning) return;
    final source = ExerciseStepService.activeSource;
    final available = await source.isAvailable();
    if (!available) return;

    _isRunning = true;
    _subscription = source.todayStepsStream().listen((todaySteps) async {
      final String todayKey = _dateKeyOf(DateTime.now());
      await _upsertAutoRecord(todayKey, todaySteps);
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _isRunning = false;
  }

  String _dateKeyOf(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 해당 날짜의 자동 걷기 기록을 새로 만들거나(없으면) 갱신(있으면)한다.
  /// id를 날짜 기반으로 고정해서 같은 날에는 절대 중복 생성되지 않는다.
  Future<void> _upsertAutoRecord(String dateKey, int steps) async {
    final parts = dateKey.split('-');
    final DateTime date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final String recordId = '$_kAutoRecordIdPrefix$dateKey';

    final all = await ExerciseDataService.instance.getAllRecords();
    final existingList = all.where((r) => r.recordId == recordId).toList();

    final Map<String, dynamic> detail = {
      'steps': steps,
      'distanceKm': double.parse(ExerciseStepService.stepsToKm(steps).toStringAsFixed(2)),
    };

    if (existingList.isNotEmpty) {
      final updated = existingList.first.copyWith(detail: detail);
      await ExerciseDataService.instance.updateRecord(updated);
    } else {
      final newRecord = ExerciseRecord(
        recordId: recordId,
        exerciseTypeId: 'walking',
        date: date,
        durationMin: 0,
        memo: '자동 기록 (만보기, 매일 자동)',
        detail: detail,
      );
      await ExerciseDataService.instance.addRecord(newRecord);
    }
  }
}
