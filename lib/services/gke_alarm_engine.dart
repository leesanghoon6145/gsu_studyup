// ============================================================================
// 🆕 [2026-10-16] GkeAlarmEngine — GKE StudyUp 알람 총괄 담당 (학생 · 일반 · 약속)
//
// 원장님 확정 원칙 (2026-10-16)
// · 폰 화면이 꺼져 있든 · 잠겨 있든 · 앱이 닫혀 있든 · 진동/무음이든 → 맞춘 시각 "정시"에 울림
// · 소리 통로 = 폰 시계와 같은 "알람 소리" (미디어 · 알림 소리 아님)
// · 울리는 길이 = 원장님/학생이 고른 1분 또는 5분 → 지나면 저절로 멈춤 (모든 알람 공통)
// · 울리는 순간 잠금 화면 위 · 앱 어느 화면 위든 [알람 끄기] 팝업 (+ 알림창 [알람 끄기] 단추)
// · 매일 · 요일 반복은 끄더라도 오늘 것만 꺼지고 다음 알람은 그대로
// · 재부팅 · 자동 업데이트 뒤에도 폰이 스스로 다시 예약 (앱을 열 필요 없음)
// · 약속: 정각 · 30분 전 · 1시간 전 · 1일 전 중 고른 시점마다 울림
//
// 어떻게 울리나
// · 안드로이드 "알람 시계" 예약(AlarmManager setAlarmClock) → 앱이 죽어 있어도 정시에 깨어남
// · 알림 1개가 알람 소리를 끝없이 되풀이(FLAG_INSISTENT) → 1분/5분 뒤 알림이 스스로 사라지며 소리도 멈춤
// · 앱 안 감시(ReminderWatcherService · PlannerAlarmWatcherService · 포그라운드 감시)는 예비용 —
//   '정확한 알람' 권한이 꺼져 이 예약이 안 될 때만 대신 울림 (두 번 울리지 않게)
//
// 예약 관리
// · 저장된 알람 목록(일반 알림 · 약속 · 학생 플래너)을 읽어 "통째로 다시 맞춤"(sync) — 저장 · 수정 · 삭제 ·
//   켜기/끄기 · 앱 시작 · 로그인 · 1분/5분 변경 때마다. 예전 방식으로 걸려 있던 예약은 처음 한 번 모두 정리.
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart' show FlutterForegroundTask; // 이름 겹침 방지: 필요한 것만 가져옴
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:gsu_studyup/schedule/appointment_data_service.dart';
import 'package:gsu_studyup/schedule/notification_service.dart';
import 'package:gsu_studyup/schedule/reminder_data_service.dart';
import 'package:gsu_studyup/planner/global_alarm_stop_overlay.dart';
import 'timer2_services.dart';

/// 새 알람 통로 (한 번 만들면 소리 설정이 고정되므로 이름을 바꾸지 말 것)
const String kGkeAlarmChannelId = 'gke_alarm_v3';

/// 1분 / 5분 (일반 알림 첫 안내 팝업과 같은 저장 이름)
const String kGkeRingMinutesKey = 'gke_alarm_ring_duration_minutes';

/// 예비 감시가 쉬어도 되는지 (알람 시계 예약이 잘 됐으면 true)
const String kGkeReadyGeneralKey = 'gke_alarm_system_ready_general';
const String kGkeReadyPlannerKey = 'gke_alarm_system_ready_planner';

/// 앱이 꺼져 있을 때 알림창 [알람 끄기]를 누른 경우 — 알림이 지워지면서 소리도 함께 멈추므로 따로 할 일 없음
@pragma('vm:entry-point')
void gkeAlarmBackgroundResponse(NotificationResponse response) {}

class _Plan {
  final int id;
  final String title;
  final String body;
  final tz.TZDateTime when;
  final DateTimeComponents? match;
  final String payload;
  _Plan(this.id, this.title, this.body, this.when, this.match, this.payload);
}

class GkeAlarmEngine {
  GkeAlarmEngine._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _inited = false;
  static Future<void> _chain = Future<void>.value();

  /// 예전 방식의 반복 소리 알림 통로 (끄기 · 감지용)
  static const Set<String> _legacyLoopChannels = {
    'gke_looping_alarm_channel_v1', // 일반 플래너 (예전)
    'gsu_self_directed_planner_looping_channel', // 학생 플래너 (예전)
  };

  static final Int64List _vibe = Int64List.fromList(<int>[0, 900, 600, 900, 600, 900]);

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  // -------------------------------------------------------------------------
  // 시작
  // -------------------------------------------------------------------------
  static Future<void> init() async {
    if (_inited) return;
    _inited = true;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    } catch (_) {}
    try {
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: onResponse,
        onDidReceiveBackgroundNotificationResponse: gkeAlarmBackgroundResponse,
      );
      await _android?.createNotificationChannel(AndroidNotificationChannel(
        kGkeAlarmChannelId,
        'GKE 학습 알람',
        description: '정해 둔 시각에 알람 소리로 울리고, 고른 1분 · 5분 뒤 저절로 멈춥니다.',
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('soft_alarm'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: true,
        vibrationPattern: _vibe,
      ));
      try {
        await _android?.requestNotificationsPermission();
      } catch (_) {}
    } catch (e) {
      debugPrint('[GkeAlarmEngine] 시작 실패: $e');
    }
  }

  // -------------------------------------------------------------------------
  // 1분 / 5분
  // -------------------------------------------------------------------------
  static Future<int> ringMinutes() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return (prefs.getInt(kGkeRingMinutesKey) ?? 1) == 5 ? 5 : 1;
    } catch (_) {
      return 1;
    }
  }

  static Future<void> setRingMinutes(int minutes) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(kGkeRingMinutesKey, minutes == 5 ? 5 : 1);
    } catch (_) {}
    await syncAll(); // 이미 맞춘 알람에도 새 길이를 적용
  }

  /// 예비 감시가 쉬어도 되는지 ('general' / 'planner') — 다른 격리 공간에서도 읽을 수 있게 폰 저장 사용
  static Future<bool> systemReady(String group) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      return prefs.getBool(group == 'planner' ? kGkeReadyPlannerKey : kGkeReadyGeneralKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // 알람 알림 모양
  // -------------------------------------------------------------------------
  static NotificationDetails _details(int minutes) => NotificationDetails(
    android: AndroidNotificationDetails(
      kGkeAlarmChannelId,
      'GKE 학습 알람',
      channelDescription: '정해 둔 시각에 알람 소리로 울리고, 고른 1분 · 5분 뒤 저절로 멈춥니다.',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('soft_alarm'),
      audioAttributesUsage: AudioAttributesUsage.alarm, // 폰 시계와 같은 알람 소리 통로 (진동 · 무음에서도 울림)
      enableVibration: true,
      vibrationPattern: _vibe,
      additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT: 끌 때까지 소리 되풀이
      timeoutAfter: minutes * 60 * 1000, // 1분 / 5분 뒤 알림이 스스로 사라지며 소리도 멈춤
      fullScreenIntent: true, // 화면이 꺼져 있으면 켜지며 [알람 끄기] 팝업
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
      ticker: 'GKE 알람',
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction('stop_alarm', '알람 끄기', cancelNotification: true),
      ],
    ),
    iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
  );

  // -------------------------------------------------------------------------
  // 다시 맞추기 (sync) — 저장된 목록을 읽어 통째로 다시 예약
  // -------------------------------------------------------------------------
  static Future<void> syncAll() async {
    await syncGeneral();
    await syncPlanner();
  }

  static Future<void> syncGeneral() => _queue('general', _buildGeneral);
  static Future<void> syncPlanner() => _queue('planner', _buildPlanner);

  /// 동시에 여러 번 불려도 차례대로 하나씩 처리
  static Future<void> _queue(String group, Future<List<_Plan>> Function() build) {
    _chain = _chain.then((_) => _doSync(group, build)).catchError((Object e) {
      debugPrint('[GkeAlarmEngine] $group 예약 실패: $e');
    });
    return _chain;
  }

  static Future<void> _doSync(String group, Future<List<_Plan>> Function() build) async {
    // 일반 플래너 알람은 계정별로 저장되므로, 로그인 정보가 아직 없으면 건드리지 않음 (알람이 지워지지 않게)
    if (group == 'general') {
      try {
        if (FirebaseAuth.instance.currentUser == null) return;
      } catch (_) {
        return;
      }
    }
    await init();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    // ① 예전 방식으로 걸려 있던 예약은 처음 한 번 모두 정리 (학사 타임라인 시작 · 끝 알림은 그대로 둠)
    if (!(prefs.getBool('gke_alarm_engine_migrated_v1') ?? false)) {
      try {
        final List<PendingNotificationRequest> pend = await _plugin.pendingNotificationRequests();
        for (final PendingNotificationRequest p in pend) {
          if (p.id >= 1000) await _plugin.cancel(p.id);
        }
      } catch (_) {}
      await prefs.setBool('gke_alarm_engine_migrated_v1', true);
    }

    // ② 이 묶음에서 지난번에 걸어 둔 예약을 모두 풀고
    //   🔧 [2026-10-16 점검] 지금 울리고 있는 알람은 건드리지 않음 — 예전에는 알람이 앱을 여는 순간
    //   앱 시작 다시 맞추기가 울리는 알람까지 지워 버려 화면 꺼짐 상태 알람이 바로 꺼졌음
    final Set<int> ringingNow = await _activeEngineIds();
    final String regKey = 'gke_alarm_engine_ids_$group';
    for (final String s in prefs.getStringList(regKey) ?? const <String>[]) {
      final int? id = int.tryParse(s);
      if (id != null && !ringingNow.contains(id)) {
        try {
          await _plugin.cancel(id);
        } catch (_) {}
      }
    }

    // ③ 지금 저장된 목록대로 다시 예약
    bool exact = true;
    try {
      exact = await _android?.canScheduleExactNotifications() ?? true;
    } catch (_) {}
    final NotificationDetails details = _details(await ringMinutes());
    final List<_Plan> plans = await build();
    final List<String> ids = <String>[];
    bool allOk = true;
    for (final _Plan p in plans) {
      try {
        await _plugin.zonedSchedule(
          p.id,
          p.title,
          p.body,
          p.when,
          details,
          androidScheduleMode: exact ? AndroidScheduleMode.alarmClock : AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: p.match,
          payload: p.payload,
        );
        ids.add('${p.id}');
      } catch (e) {
        allOk = false;
        debugPrint('[GkeAlarmEngine] 예약 실패 ${p.title} ${p.when}: $e');
      }
    }
    await prefs.setStringList(regKey, ids);
    await prefs.setBool(group == 'planner' ? kGkeReadyPlannerKey : kGkeReadyGeneralKey, exact && allOk);
    debugPrint('[GkeAlarmEngine] $group 예약 ${ids.length}개 (정확한 알람: $exact)');
  }

  // -------------------------------------------------------------------------
  // 일반 플래너: 알림(학습 알림 · 운동) + 약속
  // -------------------------------------------------------------------------
  static Future<List<_Plan>> _buildGeneral() async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final List<_Plan> out = <_Plan>[];

    List<ReminderItem> reminders = <ReminderItem>[];
    try {
      reminders = await ReminderDataService.loadAll();
    } catch (_) {}
    for (final ReminderItem r in reminders) {
      if (!r.isEnabled) continue;
      final List<int>? hm = _hm(r.time);
      if (hm == null) continue;
      final String body = r.memo.isNotEmpty ? r.memo : '⏰ 알람 시간입니다';
      final String payload = 'gke_alarm|reminder|${r.id}';
      if (r.repeatType == '매일') {
        out.add(_Plan(_idOf('r|${r.id}|d'), r.title, body, _nextDaily(now, hm), DateTimeComponents.time, payload));
      } else if (r.repeatType == '매주') {
        for (final int wd in _reminderWeekdays(r.weekdays, r.date)) {
          out.add(_Plan(_idOf('r|${r.id}|w$wd'), r.title, body, _nextWeekday(now, wd, hm), DateTimeComponents.dayOfWeekAndTime, payload));
        }
      } else {
        final DateTime? d = DateTime.tryParse(r.date);
        if (d == null) continue;
        final tz.TZDateTime when = tz.TZDateTime(tz.local, d.year, d.month, d.day, hm[0], hm[1]);
        if (when.isAfter(now)) out.add(_Plan(_idOf('r|${r.id}|o'), r.title, body, when, null, payload));
      }
    }

    List<AppointmentItem> appts = <AppointmentItem>[];
    try {
      appts = await AppointmentDataService.loadAll();
    } catch (_) {}
    for (final AppointmentItem a in appts) {
      if (a.isCompleted) continue;
      final List<int>? hm = _hm(a.time);
      final DateTime? d = DateTime.tryParse(a.date);
      if (hm == null || d == null) continue;
      final tz.TZDateTime at = tz.TZDateTime(tz.local, d.year, d.month, d.day, hm[0], hm[1]);
      final List<int> offsets = a.alarmOffsets.isEmpty ? const <int>[0] : a.alarmOffsets;
      for (final int off in offsets) {
        final tz.TZDateTime when = at.subtract(Duration(minutes: off));
        if (!when.isAfter(now)) continue;
        final String who = <String>[
          if (a.withPerson.isNotEmpty) '${a.withPerson}님',
          if (a.location.isNotEmpty) a.location,
        ].join(' · ');
        final String body = off == 0
            ? '지금 약속 시간입니다${who.isNotEmpty ? ' ($who)' : ''}'
            : '${kAppointmentOffsetLabel(off)} 알림 · ${a.date} ${a.time}${who.isNotEmpty ? ' · $who' : ''}';
        out.add(_Plan(_idOf('a|${a.id}|$off'), '약속: ${a.title}', body, when, null, 'gke_alarm|appointment|${a.id}'));
      }
    }
    return out;
  }

  // -------------------------------------------------------------------------
  // 학생 자기주도 플래너 (gke_global_schedules)
  // -------------------------------------------------------------------------
  static Future<List<_Plan>> _buildPlanner() async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final List<_Plan> out = <_Plan>[];
    List<dynamic> list = <dynamic>[];
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString('gke_global_schedules');
      if (raw != null && raw.isNotEmpty) list = jsonDecode(raw) as List<dynamic>;
    } catch (_) {}
    for (final dynamic e in list) {
      if (e is! Map) continue;
      final Map<String, dynamic> it = Map<String, dynamic>.from(e);
      if (it['alarmOn'] != true) continue;
      final String sid = (it['id'] ?? '').toString();
      final List<int>? hm = _hm((it['time'] ?? '').toString());
      if (sid.isEmpty || hm == null) continue;
      final String title = (it['title'] ?? '').toString().isEmpty ? '자기주도 플래너 알람' : it['title'].toString();
      const String body = '📚 자기주도 플래너 알람 시간입니다';
      final String payload = 'gke_alarm|planner|$sid';
      final String repeat = (it['alarmRepeat'] ?? 'once').toString();
      if (repeat == 'daily') {
        out.add(_Plan(_idOf('p|$sid|d'), title, body, _nextDaily(now, hm), DateTimeComponents.time, payload));
      } else if (repeat == 'weekly') {
        final List<int> days = it['alarmWeekdays'] is List
            ? (it['alarmWeekdays'] as List).map((x) => x is int ? x : int.tryParse('$x') ?? -1).where((x) => x >= 0 && x <= 6).toList()
            : <int>[];
        for (final int w in days) {
          final int wd = w == 0 ? 7 : w; // 0=일 → Dart 일요일 7
          out.add(_Plan(_idOf('p|$sid|w$wd'), title, body, _nextWeekday(now, wd, hm), DateTimeComponents.dayOfWeekAndTime, payload));
        }
      } else {
        final int? y = (it['year'] as num?)?.toInt();
        final int? m = (it['month'] as num?)?.toInt();
        final int? d = (it['day'] as num?)?.toInt();
        if (y == null || m == null || d == null) continue;
        final tz.TZDateTime when = tz.TZDateTime(tz.local, y, m, d, hm[0], hm[1]);
        if (when.isAfter(now)) out.add(_Plan(_idOf('p|$sid|o'), title, body, when, null, payload));
      }
    }
    return out;
  }

  // -------------------------------------------------------------------------
  // 누르기 · 끄기
  // -------------------------------------------------------------------------
  /// 모든 알림 누르기 · 단추를 여기서 한 번에 처리 (학사 타임라인 · 일반 · 학생 공통)
  static void onResponse(NotificationResponse r) {
    // 🔧 [2026-10-16 점검] 화면이 꺼져 있을 때 알람이 "전체 화면"으로 앱을 여는 것도 '누르기'로 들어옴.
    //   예전에는 여기서 바로 끄는 바람에 화면 꺼짐 상태 알람이 켜지자마자 꺼졌음 →
    //   이제 [알람 끄기] 단추를 눌렀을 때만 끄고, 그냥 열리거나 누른 경우는 팝업이 뜨도록 그대로 둠
    final String? action = r.actionId;
    if (action != null && action.isNotEmpty) {
      unawaited(stopAll());
      return;
    }
    final String? payload = r.payload;
    if (payload != null && payload.startsWith('{')) {
      try {
        final Map<String, dynamic> data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
        if (data['type'] == 'start') {
          Timer2Service.onNotificationStartTapped?.call(data); // 학사 타임라인 → 타이머 화면
          return;
        }
        if (data['type'] == 'end') return;
      } catch (_) {}
    }
    // 알람 알림을 누르거나 전체 화면으로 열린 경우 → 끄지 않음 (앱 위 [알람 끄기] 팝업이 뜸)
  }

  /// 지금 울리는 알람 제목 (없으면 null) — 끄기 팝업이 1초마다 확인
  static Future<String?> activeAlarmTitle() async {
    try {
      final List<ActiveNotification> active = await _android?.getActiveNotifications() ?? const <ActiveNotification>[];
      for (final ActiveNotification n in active) {
        if (n.channelId == kGkeAlarmChannelId || _legacyLoopChannels.contains(n.channelId)) return n.title ?? '';
      }
    } catch (_) {}
    return null;
  }

  /// 지금 알림창에 떠 있는(울리는 중인) 새 알람 번호들
  static Future<Set<int>> _activeEngineIds() async {
    final Set<int> ids = <int>{};
    try {
      final List<ActiveNotification> active = await _android?.getActiveNotifications() ?? const <ActiveNotification>[];
      for (final ActiveNotification n in active) {
        if (n.channelId == kGkeAlarmChannelId && n.id != null) ids.add(n.id!);
      }
    } catch (_) {}
    return ids;
  }

  // -------------------------------------------------------------------------
  // 🆕 [2026-10-16 점검] 알람 건강 검사 — 정시에 울리는 데 꼭 필요한 폰 설정 확인
  // -------------------------------------------------------------------------
  /// 알림 허용 여부
  static Future<bool> notificationsAllowed() async {
    try {
      return await _android?.areNotificationsEnabled() ?? true;
    } catch (_) {
      return true;
    }
  }

  /// '알람 및 리마인더'(정확한 알람) 허용 여부 — 꺼져 있으면 화면이 꺼진 동안 몇 분~수십 분 늦거나 안 울림
  static Future<bool> exactAllowed() async {
    try {
      return await _android?.canScheduleExactNotifications() ?? true;
    } catch (_) {
      return true;
    }
  }

  /// 배터리 사용 '제한 없음' 여부 — 삼성 '절전 · 딥 슬립'에 걸리면 알람이 막힐 수 있음
  static Future<bool> batteryUnrestricted() async {
    try {
      return await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    } catch (_) {
      return true;
    }
  }

  static Future<void> askNotifications() async {
    try {
      await _android?.requestNotificationsPermission();
    } catch (_) {}
  }

  static Future<void> askExact() async {
    try {
      await _android?.requestExactAlarmsPermission();
    } catch (_) {}
    await syncAll(); // 허용되면 바로 정확한 알람으로 다시 맞춤
  }

  static Future<void> askBattery() async {
    try {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    } catch (_) {}
  }

  static Future<void> askFullScreen() async {
    try {
      await _android?.requestFullScreenIntentPermission();
    } catch (_) {}
  }

  /// 시험 알람: 지금부터 1분 뒤 (실제 알람과 똑같은 방식) — 화면을 끄고 기다려 확인
  static Future<DateTime> scheduleTestAlarm() async {
    await init();
    final tz.TZDateTime when = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
    final bool exact = await exactAllowed();
    await _plugin.zonedSchedule(
      _idOf('gke_test_alarm'),
      '시험 알람',
      '알람이 정시에 잘 울립니다 ✅',
      when,
      _details(await ringMinutes()),
      androidScheduleMode: exact ? AndroidScheduleMode.alarmClock : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'gke_alarm|test',
    );
    return when;
  }

  /// 모든 알람을 한 번에 끔: 소리 · 진동 · 알림 · 예전 반복 소리 · 뒤에서 울리는 소리까지
  static Future<void> stopAll() async {
    bool hadEngineAlarm = false;
    try {
      final List<ActiveNotification> active = await _android?.getActiveNotifications() ?? const <ActiveNotification>[];
      for (final ActiveNotification n in active) {
        final bool engine = n.channelId == kGkeAlarmChannelId;
        if (!engine && !_legacyLoopChannels.contains(n.channelId)) continue;
        if (engine) hadEngineAlarm = true;
        final int? id = n.id;
        if (id != null) await _plugin.cancel(id, tag: n.tag);
      }
    } catch (_) {}
    try {
      await NotificationService.stopAlarmSound();
    } catch (_) {}
    try {
      await PlannerAlarmHooks.stop?.call();
    } catch (_) {}
    try {
      FlutterForegroundTask.sendDataToTask('stop_alarm');
    } catch (_) {}
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(kAlarmRingingAtKey);
      await prefs.remove(kAlarmRingingTitleKey);
    } catch (_) {}
    // 알림을 지우면 반복 예약까지 풀리므로, 매일 · 요일 알람의 다음 회차를 바로 다시 예약
    if (hadEngineAlarm) await syncAll();
  }

  // -------------------------------------------------------------------------
  // 도움 함수
  // -------------------------------------------------------------------------
  /// 같은 글자 → 언제나 같은 번호 (1,073,741,824 이상 — 학사 타임라인 번호와 겹치지 않음)
  static int _idOf(String key) {
    int h = 0x811c9dc5;
    for (final int c in key.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return (h & 0x3FFFFFFF) | 0x40000000;
  }

  static List<int>? _hm(String time) {
    final List<String> p = time.trim().split(':');
    if (p.length < 2) return null;
    final int? h = int.tryParse(p[0]);
    final int? m = int.tryParse(p[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) return null;
    return <int>[h, m];
  }

  static tz.TZDateTime _nextDaily(tz.TZDateTime now, List<int> hm) {
    tz.TZDateTime t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hm[0], hm[1]);
    if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
    return t;
  }

  /// wd: Dart 요일 (월=1 … 일=7)
  static tz.TZDateTime _nextWeekday(tz.TZDateTime now, int wd, List<int> hm) {
    tz.TZDateTime t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hm[0], hm[1]);
    for (int i = 0; i < 8 && (t.weekday != wd || !t.isAfter(now)); i++) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }

  /// 일반 알림의 요일 "2,5" (월=1~일=7). 비어 있으면 처음 날짜의 요일 하나
  static List<int> _reminderWeekdays(String weekdays, String date) {
    final List<int> list = weekdays
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .where((v) => v >= 1 && v <= 7)
        .toSet()
        .toList();
    if (list.isNotEmpty) return list;
    final DateTime? d = DateTime.tryParse(date);
    return <int>[d?.weekday ?? DateTime.now().weekday];
  }
}

/// 약속 알림 시점 이름
String kAppointmentOffsetLabel(int minutes) {
  switch (minutes) {
    case 0:
      return '정각';
    case 30:
      return '30분 전';
    case 60:
      return '1시간 전';
    case 1440:
      return '1일 전';
    default:
      return minutes >= 60 ? '${minutes ~/ 60}시간 전' : '$minutes분 전';
  }
}

/// 약속 알림 시점 고르기 순서
const List<int> kAppointmentOffsets = <int>[0, 30, 60, 1440];

// ============================================================================
// ⏱ 알람이 울리는 시간 고르기 (1분 / 5분) + 🆕 [2026-10-16 점검] 알람 건강 검사 · 시험 알람
//   일반 알림 화면 · 학생 알람 설정 창에 넣어 씀
//   · 정시에 울리는 데 꼭 필요한 폰 설정이 꺼져 있으면 빨간 줄로 알려 주고, 누르면 그 설정 화면으로 바로 이동
//   · [1분 뒤 시험 알람] — 누르고 화면을 끈 채 기다리면 실제 알람과 똑같이 울리는지 확인
// ============================================================================
class GkeRingMinutesPicker extends StatefulWidget {
  const GkeRingMinutesPicker({super.key});

  @override
  State<GkeRingMinutesPicker> createState() => _GkeRingMinutesPickerState();
}

class _GkeRingMinutesPickerState extends State<GkeRingMinutesPicker> with WidgetsBindingObserver {
  static const Color _gold = Color(0xFFE5C158);
  static const Color _red = Color(0xFFDC2626);
  static const Color _green = Color(0xFF22C55E);
  int _min = 1;
  bool _checked = false;
  bool _notiOk = true;
  bool _exactOk = true;
  bool _batteryOk = true;
  String _testMsg = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    GkeAlarmEngine.ringMinutes().then((v) {
      if (mounted) setState(() => _min = v);
    });
    _health();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 설정 화면에 다녀오면 다시 검사
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _health(resync: true);
  }

  Future<void> _health({bool resync = false}) async {
    final bool n = await GkeAlarmEngine.notificationsAllowed();
    final bool e = await GkeAlarmEngine.exactAllowed();
    final bool b = await GkeAlarmEngine.batteryUnrestricted();
    if (resync && e && !_exactOk) unawaited(GkeAlarmEngine.syncAll()); // 막 허용했으면 정확한 알람으로 다시 맞춤
    if (!mounted) return;
    setState(() {
      _checked = true;
      _notiOk = n;
      _exactOk = e;
      _batteryOk = b;
    });
  }

  Future<void> _pick(int m) async {
    setState(() => _min = m);
    await GkeAlarmEngine.setRingMinutes(m);
  }

  Future<void> _test() async {
    try {
      final DateTime at = await GkeAlarmEngine.scheduleTestAlarm();
      final String hm = '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}:${at.second.toString().padLeft(2, '0')}';
      if (mounted) setState(() => _testMsg = '$hm 에 울립니다. 지금 화면을 끄고 기다려 보세요.');
    } catch (e) {
      if (mounted) setState(() => _testMsg = '시험 알람을 맞추지 못했습니다: $e');
    }
  }

  Widget _chip(int m) {
    final bool on = _min == m;
    return Expanded(
      child: GestureDetector(
        onTap: () => _pick(m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? _gold.withValues(alpha: 0.18) : const Color(0xFF030712),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: on ? _gold : Colors.white12, width: on ? 1.4 : 1),
          ),
          child: Text('$m분', style: GoogleFonts.notoSansKr(color: on ? Colors.white : Colors.white54, fontSize: 13, fontWeight: on ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _warn(String text, String button, Future<void> Function() onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
        decoration: BoxDecoration(
          color: _red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: _red.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: _red, size: 17),
            const SizedBox(width: 6),
            Expanded(child: Text(text, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 11.5, height: 1.4))),
            TextButton(
              onPressed: () async {
                await onTap();
                await _health(resync: true);
              },
              style: TextButton.styleFrom(foregroundColor: _gold, padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 30)),
              child: Text(button, style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool allOk = _notiOk && _exactOk && _batteryOk;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1527),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (_checked && !allOk) ? _red : _gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: _gold, size: 18),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RING TIME', style: GoogleFonts.gowunBatang(color: _gold, fontWeight: FontWeight.bold, fontSize: 10.5)),
                    Text('알람이 울리는 시간', style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                  ],
                ),
              ),
              _chip(1),
              const SizedBox(width: 6),
              _chip(5),
            ],
          ),
          if (_checked && !_notiOk) _warn('알림이 꺼져 있어 알람이 울리지 않습니다.', '허용하기', GkeAlarmEngine.askNotifications),
          if (_checked && !_exactOk)
            _warn('"알람 및 리마인더"가 꺼져 있어 화면이 꺼진 동안 알람이 늦거나 울리지 않습니다.', '허용하기', GkeAlarmEngine.askExact),
          if (_checked && !_batteryOk) _warn('배터리 절전에 걸려 알람이 막힐 수 있습니다. "제한 없음"으로 바꿔 주세요.', '바꾸기', GkeAlarmEngine.askBattery),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(allOk ? Icons.verified_rounded : Icons.warning_amber_rounded, color: allOk ? _green : _red, size: 15),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  !_checked ? '알람 상태 확인 중…' : (allOk ? '알람 준비 완료 — 화면이 꺼져 있어도 정시에 울립니다' : '위 빨간 줄을 눌러 해결해 주세요'),
                  style: GoogleFonts.notoSansKr(color: allOk ? Colors.white70 : _red, fontSize: 11.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _test,
                  icon: const Icon(Icons.alarm_add_rounded, size: 16),
                  label: Text('1분 뒤 시험 알람', style: GoogleFonts.notoSansKr(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(foregroundColor: _gold, side: BorderSide(color: _gold.withValues(alpha: 0.6)), padding: const EdgeInsets.symmetric(vertical: 8)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: GkeAlarmEngine.askFullScreen,
                  icon: const Icon(Icons.lock_open_rounded, size: 16),
                  label: Text('잠금 화면 팝업 허용', style: GoogleFonts.notoSansKr(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 8)),
                ),
              ),
            ],
          ),
          if (_testMsg.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_testMsg, style: GoogleFonts.notoSansKr(color: _gold, fontSize: 11.5)),
            ),
        ],
      ),
    );
  }
}
