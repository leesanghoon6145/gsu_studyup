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
// ============================================================================

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

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
    await _ensureInitialized();
    await cancel(id); // 기존 예약이 있으면 먼저 취소하고 새로 등록 (수정 시 중복 방지)

    if (time.isEmpty) return; // 시간이 없으면 정확한 알림 시점을 특정할 수 없어 건너뜀

    final dateParts = date.split('-');
    final timeParts = time.split(':');
    if (dateParts.length != 3 || timeParts.length != 2) return;

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
      DateTimeComponents? matchComponents;

      if (repeatType == '매일') {
        matchComponents = DateTimeComponents.time;
        if (scheduledDate.isBefore(now)) scheduledDate = scheduledDate.add(const Duration(days: 1));
      } else if (repeatType == '매주') {
        matchComponents = DateTimeComponents.dayOfWeekAndTime;
        if (scheduledDate.isBefore(now)) scheduledDate = scheduledDate.add(const Duration(days: 7));
      } else {
        // 1회성 알림인데 이미 지난 시각이면 등록하지 않음
        if (scheduledDate.isBefore(now)) return;
      }

      await _plugin.zonedSchedule(
        _notifId(id),
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'gke_general_planner_channel',
            'GKE StudyUp 알림',
            channelDescription: '일반 플래너 알림/약속 알림',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchComponents,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, // 🆕 [버전 호환] 설치된 flutter_local_notifications 버전에서 필수 요구하는 매개변수
      );
    } catch (e) {
      // 알림 예약 실패 시에도 앱의 나머지 기능(데이터 저장 등)은 정상 동작해야 하므로 조용히 무시
    }
  }

  static Future<void> cancel(String id) async {
    try {
      await _plugin.cancel(_notifId(id));
    } catch (e) {
      // 취소 실패해도 무시 (예약된 적 없는 id를 취소하는 경우 등)
    }
  }
}
