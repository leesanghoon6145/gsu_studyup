import 'dart:async';
import 'dart:convert';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'learning_screen.dart'; // PlannerAlarmService.fireLoopingAlarm() 재사용

// ============================================================================
// [GKE StudyUp] 자기주도 플래너 — 알람 포그라운드 감시 태스크
// 🆕 [2026-08-18] 원장님 지시: "30초마다 확인"하는 방식이 화면이 꺼지고 시간이 지나면
// 안드로이드(특히 삼성/샤오미)가 앱 프로세스를 통째로 죽여버려서 매일/매주 반복 알람이
// 다음 날부터 안 울리는 근본 원인이었음. flutter_foreground_task로 "포그라운드 서비스"
// 등록해서, 화면이 꺼지고 잠들어 있어도 안드로이드가 함부로 못 죽이게 만듦.
//
// 판정 로직(언제 알람을 울릴지)은 learning_screen.dart의 PlannerAlarmWatcherService와
// 완전히 동일함 — 그대로 복제해서 여기 격리 공간(isolate) 안에서 돌게 옮긴 것뿐, 로직 자체는
// 하나도 안 바꿈. 데이터도 똑같이 SharedPreferences('gke_global_schedules')를 그대로 읽음.
// ============================================================================

// 🆕 백그라운드 격리 공간에서 이 콜백이 진입점이 됨. 반드시 최상위 함수 + @pragma 필요
// (안 붙이면 릴리즈 빌드에서 트리셰이킹으로 삭제되어 아예 안 실행됨).
@pragma('vm:entry-point')
void plannerAlarmForegroundStartCallback() {
  FlutterForegroundTask.setTaskHandler(PlannerAlarmTaskHandler());
}

class PlannerAlarmTaskHandler extends TaskHandler {
  final Set<String> _firedKeysCache = {};
  static const String _prefsKeyPrefix = 'gke_planner_watcher_fired_';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // 서비스가 막 시작된 순간에도 한 번 즉시 확인 (재부팅 직후 등에도 바로 커버되도록)
    await _checkSchedules();
  }

  // 🆕 ForegroundTaskOptions의 eventAction 주기(아래 main.dart에서 30초로 설정)마다 호출됨
  @override
  void onRepeatEvent(DateTime timestamp) {
    _checkSchedules();
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  String _todayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<bool> _alreadyFired(String fireKey) async {
    if (_firedKeysCache.contains(fireKey)) return true;
    final prefs = await SharedPreferences.getInstance();
    final bool fired = prefs.getBool(fireKey) ?? false;
    if (fired) _firedKeysCache.add(fireKey);
    return fired;
  }

  Future<void> _markFired(String fireKey) async {
    _firedKeysCache.add(fireKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(fireKey, true);
  }

  // 🆕 [판정 로직] learning_screen.dart의 PlannerAlarmWatcherService._checkSchedules()와
  // 완전히 동일한 규칙. "매일" = 날짜 무관 무조건 통과, "매주" = 오늘 요일이 선택된 요일에
  // 포함되는지, "한 번만" = 등록된 그 날짜인지.
  Future<void> _checkSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('gke_global_schedules');
    if (raw == null || raw.isEmpty) return;

    List<dynamic> decoded;
    try {
      decoded = jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return;
    }

    final DateTime now = DateTime.now();
    final String todayKey = _todayKey(now);

    for (final dynamic rawItem in decoded) {
      final Map<String, dynamic> item = Map<String, dynamic>.from(rawItem as Map);
      if (item['alarmOn'] != true) continue;

      final String timeStr = (item['time'] ?? '').toString();
      final List<String> tp = timeStr.split(':');
      if (tp.length != 2) continue;
      final int hh = int.tryParse(tp[0]) ?? -1;
      final int mm = int.tryParse(tp[1]) ?? -1;
      if (hh < 0 || mm < 0) continue;
      if (now.hour != hh || now.minute != mm) continue;

      final String repeat = (item['alarmRepeat'] ?? 'once').toString();
      bool isDueToday;
      if (repeat == 'daily') {
        isDueToday = true;
      } else if (repeat == 'weekly') {
        final List<int> weekdays = item['alarmWeekdays'] is List
            ? List<int>.from((item['alarmWeekdays'] as List).map((e) => e is int ? e : int.tryParse('$e') ?? -1))
            : <int>[];
        final int todayIdx = now.weekday % 7; // 0=일 … 6=토
        isDueToday = weekdays.contains(todayIdx);
      } else {
        isDueToday = item['year'] == now.year && item['month'] == now.month && item['day'] == now.day;
      }
      if (!isDueToday) continue;

      final String scheduleId = (item['id'] ?? '').toString();
      if (scheduleId.isEmpty) continue;
      final String fireKey = '$_prefsKeyPrefix${scheduleId}_$todayKey';
      if (await _alreadyFired(fireKey)) continue;

      await PlannerAlarmService.fireLoopingAlarm(
        title: (item['title'] ?? '').toString(),
        body: '${(item['month'] ?? '').toString().padLeft(2, '0')}/${(item['day'] ?? '').toString().padLeft(2, '0')} 알람 설정',
        id: 'planner_watcher_${scheduleId}_$todayKey',
      );
      await _markFired(fireKey);
    }
  }
}

// 🆕 [main.dart에서 호출] 포그라운드 서비스 초기화 + 시작. 이 함수 하나만 main()에서 불러주면 됨.
Future<void> initAndStartPlannerAlarmForegroundService() async {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'gsu_planner_alarm_guard_channel',
      channelName: '자기주도 플래너 알람 감시',
      channelDescription: '학습 알람을 놓치지 않도록 백그라운드에서 계속 확인합니다.',
      // 🆕 조용히, 눈에 안 띄게 - 이 알림 자체가 시끄러우면 안 됨(진짜 알람은 따로 울림)
      channelImportance: NotificationChannelImportance.MIN,
      priority: NotificationPriority.MIN,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(30000), // 30초마다
      autoRunOnBoot: true, // 재부팅 후에도 자동으로 다시 시작
      autoRunOnMyPackageReplaced: true, // 앱 업데이트 후에도 자동 재시작
      allowWakeLock: true, // CPU 잠들어도 깨워서 확인
      allowWifiLock: false,
    ),
  );

  // 알림 권한(안드로이드 13+) 확인 - 없으면 알람 자체가 안 뜨므로 필수
  final NotificationPermission notiPermission =
  await FlutterForegroundTask.checkNotificationPermission();
  if (notiPermission != NotificationPermission.granted) {
    await FlutterForegroundTask.requestNotificationPermission();
  }

  // 배터리 최적화 제외 요청 - 삼성/샤오미 등에서 강제 종료를 막는 가장 강력한 한 수
  final bool isIgnoring = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
  if (!isIgnoring) {
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
  }

  final ServiceRequestResult result = await FlutterForegroundTask.startService(
    serviceId: 900001,
    notificationTitle: '자기주도 플래너',
    notificationText: '학습 알람을 지켜보고 있어요',
    callback: plannerAlarmForegroundStartCallback,
  );

  if (result is ServiceRequestFailure) {
    // 실패해도 앱이 죽지 않게 함 - 기존 30초 폴링(PlannerAlarmWatcherService)이 안전망으로 남아있음
  }
}
