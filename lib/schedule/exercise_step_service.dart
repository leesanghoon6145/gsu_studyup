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
import 'package:flutter/foundation.dart'; // ✅ [2026-09-13 추가] debugPrint 사용
import 'package:permission_handler/permission_handler.dart'; // ✅ [2026-09-13 추가] 신체활동 인식 권한 명시적 요청용
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

  /// 🆕 [실시간성 개선] 지금 당장 한 번 더 조회를 시도. 폴링 기반인 워치
  /// 소스에서 대기 시간을 건너뛰고 즉시 확인하고 싶을 때 사용. 폰 센서처럼
  /// 이미 실시간 이벤트 스트림인 소스는 비워둬도 무방함.
  Future<void> refreshNow();
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
      // ✅ [2026-09-13 1차 수정] 권한을 명시적으로 요청하도록 고침.
      PermissionStatus status = await Permission.activityRecognition.status;
      debugPrint('[PhonePedometerSource] 신체활동 인식 권한 상태(요청 전)=$status');
      if (!status.isGranted) {
        status = await Permission.activityRecognition.request();
        debugPrint('[PhonePedometerSource] 신체활동 인식 권한 요청 결과=$status');
      }
      // ✅ [2026-09-14 추가] "영구 거부(permanentlyDenied)"면 request()를
      // 아무리 호출해도 시스템 팝업이 다시 안 뜬다(이전에 거부한 적이 있는
      // 경우 Android 정책). 이 상태를 밖에서 구분할 수 있도록 별도 로그 남김.
      if (status.isPermanentlyDenied) {
        debugPrint('[PhonePedometerSource] ⚠️ 영구 거부 상태 - 설정에서 수동으로 켜야 함');
      }
      if (!status.isGranted) return false;

      // ✅ [2026-09-14 2차 수정 - 진짜 원인] 걸음수 센서(TYPE_STEP_COUNTER)는
      // 실제로 "걸음을 내디뎌야만" 이벤트를 보낸다. 예전 코드는 권한 확인 후
      // 3초 안에 이벤트가 안 오면 "사용 불가"로 판정했는데, 이러면 그 순간
      // 가만히 있기만 해도(당연히 자주 그럴 수밖에 없음) 매번 실패 처리됐다.
      // 권한만 확인되면 "사용 가능"으로 판단하고, 실제 걸음 데이터는
      // todayStepsStream()이 걸을 때마다 알아서 들어오게 둔다.
      return true;
    } catch (e) {
      debugPrint('[PhonePedometerSource] isAvailable 오류: $e');
      return false;
    }
  }

  // ✅ [2026-09-14 추가] 영구 거부 상태인지 밖(화면)에서 확인할 수 있는 헬퍼.
  // 이 상태면 request()가 아무 효과 없으니, 화면에서 "설정으로 이동" 안내를
  // 보여줘야 한다.
  static Future<bool> isPermanentlyDenied() async {
    return (await Permission.activityRecognition.status).isPermanentlyDenied;
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

  @override
  Future<void> refreshNow() async {
    // 🆕 폰 센서는 이미 실시간 이벤트 스트림이라 별도 새로고침이 필요 없음.
  }
}

/// 🆕 [2단계] 워치 연동 소스. health 패키지로 Health Connect(안드로이드)/
/// HealthKit(iOS)에서 "오늘 걸음수"를 주기적으로(5초마다) 조회해서 내보낸다.
/// 워치 자체와 직접 통신하지 않고, 워치가 이미 삼성헬스/애플헬스 등에
/// 동기화해둔 걸음수를 Health Connect/HealthKit을 거쳐 읽어오는 방식이다.
class WatchHealthStepSource implements StepDataSource {
  final Health _health = Health();
  Timer? _pollTimer;
  StreamController<int>? _controller;
  static bool _configured = false; // ✅ [2026-09-13 추가] 중복 초기화 방지

  // ✅ [2026-09-13 추가] 최신 health 패키지는 권한 요청 전에 반드시 configure()를
  // 먼저 호출해야 한다. 이게 빠지면 앱이 Health Connect에 아예 등록조차 안 되고
  // "permissions were not granted" 에러만 계속 반복되는 증상이 나타난다.
  Future<void> _ensureConfigured() async {
    if (_configured) return;
    try {
      await _health.configure();
      _configured = true;
      debugPrint('[WatchHealthStepSource] Health.configure() 완료');
    } catch (e) {
      debugPrint('[WatchHealthStepSource] Health.configure() 오류: $e');
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      await _ensureConfigured(); // ✅ [2026-09-13 추가] 권한 요청 전 반드시 먼저 호출
      const types = [HealthDataType.STEPS];
      const permissions = [HealthDataAccess.READ];
      bool granted = await _health.hasPermissions(types, permissions: permissions) ?? false;
      debugPrint('[WatchHealthStepSource] hasPermissions=$granted');
      if (!granted) {
        granted = await _health.requestAuthorization(types, permissions: permissions);
        debugPrint('[WatchHealthStepSource] requestAuthorization 결과=$granted');
      }
      return granted;
    } catch (e) {
      // ✅ [2026-09-13 추가] 원인 파악용 로그. 실기기 테스트 시 안드로이드
      // 스튜디오 하단 Logcat/Run 창에서 "[WatchHealthStepSource]"로 검색하면
      // 정확한 에러 내용을 볼 수 있음.
      debugPrint('[WatchHealthStepSource] isAvailable 오류: $e');
      return false;
    }
  }

  @override
  Stream<int> todayStepsStream() {
    _controller?.close();
    _pollTimer?.cancel();
    final controller = StreamController<int>.broadcast();
    _controller = controller;

    _poll(); // 구독 시작하자마자 한 번 즉시 조회
    // ✅ [실시간성 개선 2026-09-06] 30초 -> 5초로 단축해서 테스트/확인이
    // 훨씬 빨라지도록 함. Health Connect/HealthKit 조회는 로컬 데이터라
    // 자주 조회해도 비용이나 배터리 부담이 크지 않음.
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
    return controller.stream;
  }

  // 🆕 [실시간성 개선] poll 로직을 재사용 가능한 인스턴스 메서드로 분리해서,
  // 주기적 폴링뿐 아니라 refreshNow()로도 똑같이 호출할 수 있게 함.
  Future<void> _poll() async {
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final int steps = await _health.getTotalStepsInInterval(midnight, now) ?? 0;
      // ✅ [2026-09-13 추가] 조회 결과를 항상 로그로 남김 - 권한은 됐는데
      // 값이 0으로만 나올 때, 진짜 0인지 조회 자체가 실패했는지 구분하기 위함.
      debugPrint('[WatchHealthStepSource] getTotalStepsInInterval($midnight ~ $now) 결과=$steps');
      if (_controller != null && !_controller!.isClosed) _controller!.add(steps);
    } catch (e) {
      // ✅ [2026-09-13 추가] 예전엔 조용히 무시했는데, 그러면 왜 0인지 전혀
      // 알 수가 없어서 로그를 남기도록 변경.
      debugPrint('[WatchHealthStepSource] _poll 오류: $e');
    }
  }

  @override
  Future<void> refreshNow() => _poll();

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

  /// 🆕 [실시간성 개선] 지금 사용 중인 소스에서 즉시 한 번 더 값을 조회.
  /// 워치처럼 폴링 기반인 소스에서 대기 없이 바로 테스트/확인하고 싶을 때 사용.
  static Future<void> refreshNow() => activeSource.refreshNow();

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

  // 🆕 [화면 실시간 표시] 자동 기록이 갱신될 때마다 오늘 걸음수를 흘려보내는
  // 방송용 스트림. today_exercise_screen.dart가 이걸 구독해서 "뒤에서 자동
  // 기록이 잘 되고 있는지"를 화면에 실시간으로 보여줄 수 있게 한다. 기존에는
  // 이 값을 볼 방법이 화면에 전혀 없어서 "0으로 보인다"는 혼란이 있었음.
  final StreamController<int> _liveStepsController = StreamController<int>.broadcast();
  Stream<int> get liveTodaySteps => _liveStepsController.stream;

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
      // ✅ [2026-09-14 버그 수정 - 진짜 원인] 예전엔 여기서 바로 start()를
      // 불러서, ExerciseStepService.activeSource가 아직 기본값(폰)인
      // 상태로 자동기록이 시작됐다. 사용자가 "워치"를 저장해뒀어도, 앱을
      // 새로 켤 때마다 이 시점엔 아직 그 설정을 안 불러온 상태라 폰으로
      // 고정되어 버리고, 나중에 [걷기] 화면을 열어서 칩이 "워치"로 바뀌어
      // 보여도 뒤에서 도는 자동기록은 계속 폰만 보고 있었다. 먼저 저장된
      // 선호 소스를 불러온 뒤에 시작하도록 순서를 바로잡았다.
      await ExerciseStepService.loadPreferredSource();
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
      _liveStepsController.add(todaySteps); // 🆕 화면에 실시간 반영
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
  /// 🆕 [화면 초기값용] 화면을 처음 열었을 때, 다음 스트림 이벤트가 오기 전까지
  /// 기다리지 않고 이미 저장되어 있는 오늘 자동기록 걸음수를 바로 보여주기 위한 조회.
  Future<int?> getTodaySavedSteps() async {
    final String todayKey = _dateKeyOf(DateTime.now());
    final all = await ExerciseDataService.instance.getAllRecords();
    final existing = all.where((r) => r.recordId == '$_kAutoRecordIdPrefix$todayKey').toList();
    if (existing.isEmpty) return null;
    final steps = existing.first.detail['steps'];
    return steps is int ? steps : null;
  }

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
