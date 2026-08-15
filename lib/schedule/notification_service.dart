// ============================================================================
// 🆕 [일반 플래너 - 실제 알림 연동] NotificationService
// 알림(Reminder)과 약속(Appointment)의 실제 푸시 알림 예약/취소를 담당합니다.
//
// ⚠️ [중요] 기존 타이머 화면에서 쓰는 Timer2Service(알림 발송)와는 완전히
// 별도로 만들었습니다. 기존 기능을 건드리지 않기 위해 독립된 플러그인
// 인스턴스를 사용합니다.
//
// ⚠️ [사전 조건] 이 파일이 작동하려면 pubspec.yaml에 아래 패키지가 있어야
// 합니다 (이미 타이머 알림에서 쓰고 있어서 설치되어 있을 가능성이 높음):
//   flutter_local_notifications: ^17.0.0 (또는 그 이상)
//   timezone: ^0.9.0 (또는 그 이상)
// 만약 빌드 에러가 나면 pubspec.yaml에 위 줄을 추가해 주세요.
//
// ⚠️ [Android 권한] Android 13 이상은 알림 권한, Android 12 이상은 정확한
// 시각 알람 권한이 필요합니다. 아래 코드에서 앱 실행 중 권한을 요청하지만,
// 사용자가 권한을 거부하면 알림이 울리지 않을 수 있습니다. 실기기에서
// 최초 실행 시 권한 요청 팝업이 뜨면 반드시 허용해 주세요.
//
// ✅ [2026-08-15 수정] 예약 모드를 AndroidScheduleMode.alarmClock 에서
// AndroidScheduleMode.exactAllowWhileIdle 로 변경했습니다. 실제 기기에서
// alarmClock 모드는 예약 로그상 "성공"으로 찍히는데도 실제 알림이 발동하지
// 않는 문제가 있었습니다. 반면 학생용 timer2_services.dart는 처음부터
// exactAllowWhileIdle 모드를 쓰고 있고 실기기에서 안정적으로 작동 중이므로,
// 검증된 방식으로 통일했습니다. (다른 로직은 전혀 변경하지 않았습니다)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

    // 🆕 🔴 [핵심 버그 수정] tz.local의 기본값은 UTC입니다. 이걸 한국 시간대로
    // 명시적으로 지정하지 않으면, 사용자가 오후 6시로 맞춘 알림이 실제로는
    // UTC 오후 6시(한국시간 새벽 3시, 다음날)로 예약되어 9시간 차이가 발생합니다.
    // 이게 "알람이 안 울린다"고 느껴졌던 진짜 원인입니다.
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: androidSettings, iOS: iosSettings));

    // 🆕 [권한 요청] Android 13+(알림), Android 12+(정확한 알람)
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    try {
      await androidImpl?.requestNotificationsPermission();
      await androidImpl?.requestExactAlarmsPermission();
    } catch (e) {
      // 권한 요청이 실패해도 앱이 멈추지 않도록 함 (일부 기기/버전에서 메서드가 없을 수 있음)
    }

    _initialized = true;
  }

  // 🆕 같은 문자열 id를 항상 같은 정수로 변환 (알림 예약/취소 시 식별용)
  static int _notifId(String stringId) => stringId.hashCode & 0x7FFFFFFF;

  // 🆕 [핵심] 알림/약속 공용 예약 함수
  // repeatType: null 또는 '한번' = 1회성, '매일' = 매일 반복, '매주' = 매주 반복
  static Future<void> scheduleAt({
    required String id,
    required String title,
    required String body,
    required String date, // 'yyyy-MM-dd'
    required String time, // 'HH:mm'
    String? repeatType,
  }) async {
    debugPrint('[NotificationService] scheduleAt 호출됨: id=$id, date=$date, time=$time, repeatType=$repeatType');
    await _ensureInitialized();
    debugPrint('[NotificationService] 초기화 완료');
    await cancel(id); // 기존 예약이 있으면 먼저 취소하고 새로 등록 (수정 시 중복 방지)

    if (time.isEmpty) {
      debugPrint('[NotificationService] 시간이 비어있어서 예약 건너뜀');
      return;
    }

    final dateParts = date.split('-');
    final timeParts = time.split(':');
    if (dateParts.length != 3 || timeParts.length != 2) {
      debugPrint('[NotificationService] 날짜/시간 형식이 잘못됨: date=$date, time=$time');
      return;
    }

    try {
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      final now = tz.TZDateTime.now(tz.local);
      debugPrint('[NotificationService] 예약 목표시각=$scheduledDate / 지금=$now / tz.local=${tz.local.name}');
      DateTimeComponents? matchComponents;

      if (repeatType == '매일') {
        matchComponents = DateTimeComponents.time;
        if (scheduledDate.isBefore(now)) scheduledDate = scheduledDate.add(const Duration(days: 1));
      } else if (repeatType == '매주') {
        matchComponents = DateTimeComponents.dayOfWeekAndTime;
        if (scheduledDate.isBefore(now)) scheduledDate = scheduledDate.add(const Duration(days: 7));
      } else {
        // 1회성 알림인데 이미 지난 시각이면 등록하지 않음
        if (scheduledDate.isBefore(now)) {
          debugPrint('[NotificationService] ⚠️ 목표시각이 이미 지나서 예약을 건너뜀! (목표=$scheduledDate, 지금=$now) - 초기화/권한요청에 시간이 오래 걸려서 짧은 테스트가 이미 지나버렸을 수 있음');
          return;
        }
      }

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'gke_general_planner_channel_v2', // 🆕 [알람 소리 수정] 채널ID를 바꿔서, 예전에 소리 꺼진 채로 기기에 저장된 채널 설정을 무시하고 새로 만듦 (안드로이드는 채널을 한번 만들면 설정이 코드로 안 바뀌고 고정되기 때문)
          'GKE StudyUp 알림',
          channelDescription: '일반 플래너 알림/약속 알림',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true, // 🆕 [명시적 설정] 소리 재생을 명시적으로 켬
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(),
      );

      try {
        // ✅ [2026-08-15 수정] alarmClock -> exactAllowWhileIdle 로 변경.
        // 학생용 timer2_services.dart와 동일한, 실기기에서 검증된 예약 모드로 통일함.
        await _plugin.zonedSchedule(
          _notifId(id),
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: matchComponents,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('[NotificationService] ✅ 정확한 알람으로 예약 성공! notifId=${_notifId(id)}, 예약시각=$scheduledDate');
      } catch (e) {
        // 🆕 [2차 시도 - 안전장치] 정확한 알람 권한이 없어서 실패한 경우,
        // 조용히 무시하지 않고 "근사 시각" 알람으로라도 등록해서 최소한 울리게 함.
        debugPrint('[NotificationService] 정확한 알람 예약 실패, 근사 알람으로 재시도: $e');
        try {
          await _plugin.zonedSchedule(
            _notifId(id),
            title,
            body,
            scheduledDate,
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: matchComponents,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          );
        } catch (e2) {
          debugPrint('[NotificationService] 근사 알람 예약도 실패: $e2');
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] 알림 예약 준비 중 오류: $e');
    }
  }

  static Future<void> cancel(String id) async {
    try {
      await _plugin.cancel(_notifId(id));
    } catch (e) {
      // 취소 실패해도 무시 (예약된 적 없는 id를 취소하는 경우 등)
    }
  }

  // 🆕 [권한 상태 확인] 사용자가 설정에서 알림을 꺼버렸는지 확인.
  // 꺼져 있으면 앱이 다시 팝업을 띄울 수 없으므로(안드로이드 정책), 화면에
  // 경고 배너를 보여주는 용도로 사용합니다.
  static Future<bool> areNotificationsEnabled() async {
    await _ensureInitialized();
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await androidImpl?.areNotificationsEnabled();
      return enabled ?? true; // 확인 불가한 환경(iOS 등)에서는 과도한 경고를 막기 위해 true로 간주
    } catch (e) {
      return true;
    }
  }
}

// ============================================================================
// 🆕 [권한 상태 확인 + 안내 배너] 사용자가 설정에서 알림을 꺼버리면 앱이 다시
// 팝업을 띄울 수 없으므로(안드로이드 정책), 대신 화면 안에 "알림이 꺼져있어요"
// 안내 배너를 보여줘서 사용자가 직접 설정으로 가도록 유도합니다.
// ============================================================================

class NotificationPermissionBanner extends StatefulWidget {
  const NotificationPermissionBanner({super.key});

  @override
  State<NotificationPermissionBanner> createState() => _NotificationPermissionBannerState();
}

class _NotificationPermissionBannerState extends State<NotificationPermissionBanner> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final enabled = await NotificationService.areNotificationsEnabled();
    if (mounted) setState(() => _enabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    if (_enabled == null || _enabled == true) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_rounded, color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Notifications are turned off.\nGo to Settings > Apps > This App > Notifications to turn them back on.\n(알림이 꺼져 있습니다. 설정 > 앱 > 알림에서 다시 켜주세요.)',
              style: TextStyle(color: Colors.white, fontSize: 11.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 🆕 [진단 도구] NotificationTestButton
// "폰 설정을 확인해달라"는 안내만 반복하지 않고, 앱 안에서 직접 30초 뒤
// 테스트 알림을 예약해볼 수 있는 버튼. 30초 안에 알림이 오면 코드는 정상이고
// 순수하게 폰 설정(배터리 최적화, 정확한 알람 권한) 문제라는 게 확실해지고,
// 30초가 지나도 안 오면 다른 원인을 찾아야 한다는 것도 명확해집니다.
// ============================================================================
class NotificationTestButton extends StatefulWidget {
  const NotificationTestButton({super.key});

  @override
  State<NotificationTestButton> createState() => _NotificationTestButtonState();
}

class _NotificationTestButtonState extends State<NotificationTestButton> {
  bool _isTesting = false;

  Future<void> _runTest() async {
    setState(() => _isTesting = true);
    final target = DateTime.now().add(const Duration(seconds: 30)); // 🆕 [경합 방지] 초기화/권한요청 시간을 고려해 10초 -> 30초로 여유있게
    final String dateKey = '${target.year}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')}';
    final String timeKey = '${target.hour.toString().padLeft(2, '0')}:${target.minute.toString().padLeft(2, '0')}';

    await NotificationService.scheduleAt(
      id: 'test_notification_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Test Alarm (테스트 알림)',
      body: 'If you see this, notifications are working! (이게 보이면 알림 정상 작동 중입니다)',
      date: dateKey,
      time: timeKey,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification in 30s - send the app to background and wait. (30초 후 테스트 알림이 울립니다. 앱을 백그라운드로 보내고 기다려보세요.)')),
      );
    }

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _isTesting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1527),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5C158).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.science_outlined, color: Color(0xFFE5C158), size: 18),
              SizedBox(width: 8),
              Text('Notification Test (알림 테스트)', style: TextStyle(color: Color(0xFFE5C158), fontWeight: FontWeight.bold, fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '아래 버튼을 누르면 30초 뒤 테스트 알림이 예약됩니다. 앱을 백그라운드로 보내고 30초 기다려서 실제로 오는지 확인해보세요.',
            style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isTesting ? null : _runTest,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5C158), padding: const EdgeInsets.symmetric(vertical: 11)),
              child: Text(
                _isTesting ? 'Scheduled... (예약됨...)' : 'Test in 30 seconds (30초 후 테스트)',
                style: const TextStyle(color: Color(0xFF030712), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
