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
// ✅ [2026-08-15 수정 1] 예약 모드를 AndroidScheduleMode.alarmClock 에서
// AndroidScheduleMode.exactAllowWhileIdle 로 변경했습니다. 학생용
// timer2_services.dart와 동일한, 실기기에서 검증된 방식으로 통일했습니다.
//
// ✅ [2026-08-15 수정 2] 진단용 "즉시 알림 테스트" 기능 추가.
// Logcat 분석 결과, 시스템이 예약 시각에 ScheduledNotificationReceiver로
// 브로드캐스트(신호)를 정확히 전달하는 것까지는 확인됐지만, 그 이후 실제
// NotificationListener/Pipeline 처리 로그가 전혀 없었습니다(카카오톡 등
// 다른 앱과 비교해서 확인). "예약(스케줄링)" 문제인지 "발동(표시)" 자체의
// 문제인지 구분하기 위해, 예약 없이 즉시 알림을 띄우는 showNow()와 그
// 버튼을 추가했습니다. 기존 scheduleAt/cancel 로직은 전혀 변경하지
// 않았습니다. (테스트 결과: 즉시 알림은 소리/표시 전부 정상 작동 확인됨 —
// 문제는 "예약→발동" 사이에만 있는 것으로 확정됨)
//
// ✅ [2026-08-15 수정 3] 1차 예약 모드를 exactAllowWhileIdle에서
// inexactAllowWhileIdle로 변경. (즉시 알림은 정상 작동하는데 예약만
// 실패하는 것으로 확인되어, 이 기기(삼성 One UI)에서 exact 계열 정확한
// 알람 등록 자체가 원인일 가능성을 테스트하기 위함)
//
// ✅ [2026-09-05 추가 - 알람 끄기 UX 전면 개선] 기존엔 알람을 끄려면
// (1) 알림창의 액션 버튼을 누르거나 (2) 앱 안의 인라인 배너를 직접 찾아서
// 눌러야 했습니다. 둘 다 "화면이 꺼져있거나/잠겨있거나/다른 화면에 있을 때"
// 찾기 어렵다는 문제가 있었습니다. 이번 수정:
// 1) fireLoopingAlarm()의 알림에 fullScreenIntent:true + category:alarm을
//    추가해서, 화면이 꺼져있거나 잠겨있을 때 시스템이 강제로 화면을 깨우고
//    앱을 최상단에 띄우도록 함 (AndroidManifest.xml의 USE_FULL_SCREEN_INTENT
//    권한 + MainActivity의 showWhenLocked/turnScreenOn 속성과 함께 작동).
// 2) RingingAlarmStopBanner를 "찾아서 눌러야 하는 인라인 배너"에서 "알람이
//    울리기 시작하면 그 즉시 전체화면 팝업이 자동으로 뜨는" 방식으로 전면
//    교체. 이 위젯이 마운트되어 있는 한, 앱의 어느 화면을 보고 있든 그 위로
//    전체화면 팝업이 덮어씌워짐 (rootNavigator 사용).
// ============================================================================

import 'dart:async'; // 🆕 [2026-08-16 추가] 반복 알람 안전장치(자동 정지) 타이머용
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:audioplayers/audioplayers.dart'; // 🆕 [2026-08-16 추가] 알람 소리 반복 재생용
import 'package:shared_preferences/shared_preferences.dart'; // 🆕 [2026-08-16 추가] 사용자가 선택한 알람 안전정지 시간 저장/조회용

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // 🆕 [2026-08-16 추가] 반복 알람(fireLoopingAlarm) 관련 상태
  static final AudioPlayer _alarmPlayer = AudioPlayer();
  static Timer? _autoStopTimer;
  static const String _loopingAlarmChannelId = 'gke_looping_alarm_channel_v1';

  // 🆕 [2026-08-16 추가] 사용자가 리마인더 화면 첫 안내 팝업에서 선택한
  // "안전 정지 시간(분)"을 저장/조회하는 키. reminder_screen.dart의 안내
  // 팝업과 반드시 동일한 문자열을 써야 합니다.
  static const String prefsAlarmRingMinutesKey = 'gke_alarm_ring_duration_minutes';

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
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      // 🆕 [2026-08-16 추가] 알림을 탭하거나 "알람 끄기" 버튼을 눌렀을 때 반복 재생 중인
      // 소리를 멈추기 위한 콜백. 반복 알람이 아닌 일반 알림(showCustomNow 등)을 탭해도
      // 그냥 아무 반복 재생이 없는 상태라 stopAlarmSound()가 조용히 무시됩니다.
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

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

  // 🆕 [2026-08-16 추가] 알림 탭 또는 액션 버튼("알람 끄기") 응답 처리
  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint('[NotificationService] 알림 응답: actionId=${response.actionId}, notifId=${response.id}');
    stopAlarmSound();
    if (response.id != null) {
      _plugin.cancel(response.id!);
    }
  }

  // 🆕 같은 문자열 id를 항상 같은 정수로 변환 (알림 예약/취소 시 식별용)
  static int _notifId(String stringId) => stringId.hashCode & 0x7FFFFFFF;

  static AndroidNotificationDetails _androidDetails() {
    return const AndroidNotificationDetails(
      'gke_general_planner_channel_v3', // 🆕 [2026-08-16 채널명 변경] 채널ID를 v2→v3로 바꿔서, "GKE StudyUp 알림"으로 이미 기기에 저장된 채널을 무시하고 "포근한 알림"이라는 새 이름으로 새 채널을 만듦 (채널은 한번 만들어지면 이름이 코드로 안 바뀌고 고정되기 때문)
      '포근한 알림', // 🆕 [2026-08-16 이름 확정] "부드러운 알람"으로 부르기로 하여 지음. 짧고 부드럽게 한 번 울리는 지금 방식의 성격과 어울리는 이름
      channelDescription: '일반 플래너 알림/약속 알림',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true, // 🆕 [명시적 설정] 소리 재생을 명시적으로 켬
      sound: RawResourceAndroidNotificationSound('soft_alarm'), // 🆕 [2026-08-16 추가] android/app/src/main/res/raw/soft_alarm.mp3 커스텀 사운드 연결 (확장자 .mp3는 빼고 파일명만 적음)
      enableVibration: true,
    );
  }

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
        android: _androidDetails(),
        iOS: const DarwinNotificationDetails(),
      );

      try {
        // ✅ [2026-08-15 수정 3] exactAllowWhileIdle -> inexactAllowWhileIdle 로 변경.
        // 즉시 알림(showNow)은 소리/표시 전부 정상 작동하는 게 확인됐고, 오직
        // "미래 시각 예약"만 실패하고 있어서, 이 기기(삼성 One UI)에서
        // exactAllowWhileIdle 계열 정확한 알람 등록 자체가 원인일 가능성이
        // 높다고 판단했습니다. 근사 시각 모드로 1차 시도를 바꿔봅니다.
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
        debugPrint('[NotificationService] ✅ 근사 알람으로 예약 성공! notifId=${_notifId(id)}, 예약시각=$scheduledDate');
      } catch (e) {
        // 🆕 [2차 시도 - 안전장치] 근사 알람도 실패한 경우, 정확한 알람 모드로
        // 재시도.
        debugPrint('[NotificationService] 근사 알람 예약 실패, 정확한 알람으로 재시도: $e');
        try {
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
        } catch (e2) {
          debugPrint('[NotificationService] 정확한 알람 예약도 실패: $e2');
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

  // 🆕 [2026-08-15 추가 - 진단 전용] 예약(스케줄링) 과정을 완전히 건너뛰고,
  // 지금 이 순간 즉시 알림을 띄웁니다. scheduleAt과 완전히 동일한 채널/소리
  // 설정을 사용합니다. 이게 뜨면 "표시/소리" 자체는 정상이고 "예약" 쪽에만
  // 문제가 있다는 뜻이고, 이것도 안 뜨면 채널/플러그인 자체를 더 의심해야
  // 합니다. (2026-08-15 저녁 테스트 결과: 정상 작동 확인됨 - 소리/표시 문제없음)
  // 🆕 [2026-08-16 추가 - 우회로(감시자) 전용] "예약(zonedSchedule) → 자동 발동"
  // 경로가 이 기기에서 계속 실패해서(로그로 여러 차례 확인됨: 시스템이 신호는
  // 정확히 보내는데 그 이후 알림이 실제로 안 뜸, 오류도 전혀 없음), 이미
  // 100% 정상 작동이 확인된 즉시 알림(showNow와 동일 메커니즘)을 커스텀
  // 제목/내용으로 띄울 수 있게 만든 함수입니다. ReminderWatcherService가
  // 이 함수를 사용해서 "예약된 알림을 직접 감시하다가 시각이 되면 이 함수로
  // 대신 띄우는" 우회로 역할을 합니다.
  static Future<void> showCustomNow(String title, String body, {String? id}) async {
    await _ensureInitialized();
    try {
      final details = NotificationDetails(
        android: _androidDetails(),
        iOS: const DarwinNotificationDetails(),
      );
      final int notifId = _notifId(id ?? 'custom_now_${DateTime.now().millisecondsSinceEpoch}');
      await _plugin.show(notifId, title, body, details);
      debugPrint('[NotificationService] ✅ showCustomNow 완료: title=$title, notifId=$notifId');
    } catch (e) {
      debugPrint('[NotificationService] ❌ showCustomNow 실패: $e');
    }
  }

  // 🆕 [2026-08-16 추가 - 진짜 기상 알람용] 소리를 반복 재생하고, 사용자가
  // 알림의 "알람 끄기" 버튼을 누르거나 알림을 탭해야만 멈춥니다. 리마인더
  // 워처(ReminderWatcherService)가 "학습 알람"(리마인더) 발동 시 이 함수를
  // 사용합니다. 안전장치로 3분이 지나면 자동으로 멈춥니다(배터리/소음 방지).
  //
  // ⚠️ [사전 조건] assets/sounds/soft_alarm.mp3 파일이 있어야 하고,
  // pubspec.yaml의 flutter > assets 목록에 assets/sounds/ 가 포함되어
  // 있어야 합니다(이미 포함되어 있음, 백색소음 재생에 쓰던 것과 동일 목록).
  //
  // ✅ [2026-09-05 추가] fullScreenIntent:true + category:alarm 적용.
  // AndroidManifest.xml의 USE_FULL_SCREEN_INTENT 권한, MainActivity의
  // showWhenLocked/turnScreenOn 속성과 함께 작동해서, 화면이 꺼져있거나
  // 잠겨있을 때도 시스템이 강제로 화면을 깨우고 앱을 최상단에 띄웁니다.
  // 화면이 켜져있고 잠금 해제된 상태에서 다른 앱을 쓰고 있을 때는 OS 정책상
  // 강제로 화면을 뺏지는 않고 높은 우선순위 알림(헤드업)으로 표시되는 게
  // 일반적인 동작입니다 - 이 경우엔 앱을 열면 RingingAlarmStopBanner가
  // 즉시 전체화면 팝업으로 뜹니다.
  static Future<void> fireLoopingAlarm({
    required String title,
    required String body,
    String? id,
  }) async {
    debugPrint('[NotificationService] fireLoopingAlarm 호출됨: title=$title');
    await _ensureInitialized();
    try {
      final int notifId = _notifId(id ?? 'loop_alarm_${DateTime.now().millisecondsSinceEpoch}');

      // 🆕 [알림 자체 소리는 끔] 소리는 아래에서 audioplayers로 직접 반복
      // 재생하므로, 알림 채널의 소리는 꺼서 소리가 겹치지 않게 함. 반복
      // 알람 전용의 별도 채널을 사용(기존 '포근한 알림' 채널과는 다름 —
      // 채널은 한번 만들어지면 소리 설정이 고정되기 때문에 애초에 분리함).
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _loopingAlarmChannelId,
          '학습 알람 (반복)',
          channelDescription: '직접 꺼야 멈추는 반복 알람 채널',
          importance: Importance.max,
          priority: Priority.max,
          playSound: false,
          enableVibration: true,
          ongoing: true, // 🆕 스와이프로 안 지워짐 (직접 꺼야 함)
          autoCancel: false,
          fullScreenIntent: true, // 🆕 [2026-09-05 추가] 화면 꺼짐/잠금 상태에서도 최상단에 강제 표시
          category: AndroidNotificationCategory.alarm, // 🆕 [2026-09-05 추가] "알람" 성격임을 시스템에 명시 (방해금지 모드 우회에도 도움)
          visibility: NotificationVisibility.public, // 🆕 [2026-09-05 추가] 잠금화면에서도 내용이 가려지지 않고 그대로 보이도록 함
          actions: const [
            AndroidNotificationAction('stop_alarm', '알람 끄기', cancelNotification: true),
          ],
        ),
        iOS: const DarwinNotificationDetails(),
      );

      await _plugin.show(notifId, title, body, details);
      await _startLoopingSound();
      debugPrint('[NotificationService] ✅ fireLoopingAlarm 표시 완료 및 반복 재생 시작 (notifId=$notifId)');

      // ✅ [2026-08-16 변경] 리마인더 화면 첫 안내 팝업에서 사용자가 직접
      // 고른 시간(1분 또는 5분)을 안전 정지 시간으로 사용합니다. 아직 선택
      // 안 한 상태(팝업을 아직 못 본 경우)라면 1분을 기본값으로 사용합니다.
      _autoStopTimer?.cancel();
      final int ringMinutes = await _getAlarmRingMinutes();
      debugPrint('[NotificationService] 안전 정지 시간: $ringMinutes분');
      _autoStopTimer = Timer(Duration(minutes: ringMinutes), () async {
        debugPrint('[NotificationService] ⏱️ $ringMinutes분 경과, 안전장치로 반복 알람 자동 정지');
        await stopAlarmSound();
        await _plugin.cancel(notifId);
      });
    } catch (e) {
      debugPrint('[NotificationService] ❌ fireLoopingAlarm 실패: $e');
    }
  }

  // 🆕 [2026-08-16 추가] 사용자가 안내 팝업에서 선택한 안전 정지 시간(분)을
  // 읽어옵니다. 아직 선택 안 했으면(팝업을 못 봤으면) 1분을 기본값으로 함.
  static Future<int> _getAlarmRingMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(prefsAlarmRingMinutesKey) ?? 1;
    } catch (e) {
      return 1;
    }
  }

  static Future<void> _startLoopingSound() async {
    try {
      await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
      await _alarmPlayer.play(AssetSource('sounds/soft_alarm.mp3'));
    } catch (e) {
      debugPrint('[NotificationService] 반복 재생 시작 실패: $e');
    }
  }

  // 🆕 [2026-08-16 추가] 지금 반복 알람이 울리고 있는지 확인 (화면에 "알람
  // 끄기" 버튼을 보여줄지 판단하는 용도)
  static Future<bool> isAlarmRinging() async {
    try {
      final state = _alarmPlayer.state;
      return state == PlayerState.playing;
    } catch (e) {
      return false;
    }
  }

  // 🆕 [2026-08-16 추가] 반복 재생 중인 알람 소리를 멈춥니다. "알람 끄기"
  // 버튼이나 알림 탭 시 자동으로 호출됩니다(_onNotificationResponse 참고).
  static Future<void> stopAlarmSound() async {
    try {
      await _alarmPlayer.stop();
    } catch (e) {
      debugPrint('[NotificationService] 반복 재생 정지 중 오류(무시): $e');
    }
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
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

// ============================================================================
// 🆕 [2026-08-16 추가, 2026-09-05 전면 개편] RingingAlarmStopBanner
//
// [기존 방식의 문제] 안드로이드 알림창의 "알람 끄기" 액션 버튼이 일부 삼성
// 기기에서 알림 자체가 사라지면서 같이 없어지는 문제가 있었고, 그 대안으로
// 만들었던 인라인 배너도 "그 화면을 찾아가서 봐야만" 보이는 방식이라 여전히
// 끄기 어렵다는 피드백을 받았습니다.
//
// [2026-09-05 개편] 이 위젯이 화면 트리 어딘가에 마운트되어 있기만 하면:
// 1초마다 알람이 울리는지 확인하다가, 울리기 "시작하는 순간" 그 즉시
// rootNavigator 위에 전체화면 팝업(barrierDismissible:false, 뒤로가기로도
// 안 닫힘)을 자동으로 띄웁니다. 사용자가 지금 어떤 화면을 보고 있었든
// 상관없이 그 위로 전체화면이 덮이고, 큰 버튼 한 번으로 즉시 끌 수
// 있습니다(예전의 2단계 확인 팝업 제거 - 전체화면 자체가 이미 "의도적으로
// 확인하는 상태"이므로 이중 확인이 불필요한 마찰이라고 판단).
//
// ⚠️ [적용 범위 안내] 이 위젯은 마운트된 화면 트리 아래에서 열리는 모든
// 라우트 위에 뜹니다. 앱의 정말 모든 상태(로그인 화면 포함)에서 확실하게
// 뜨게 하려면, main.dart의 MaterialApp builder에 최상위로 한 번만
// 넣어두는 것을 권장합니다 (예: `builder: (context, child) => Stack(
// children: [child!, const RingingAlarmStopBanner()])`).
// ============================================================================
class RingingAlarmStopBanner extends StatefulWidget {
  const RingingAlarmStopBanner({super.key});

  @override
  State<RingingAlarmStopBanner> createState() => _RingingAlarmStopBannerState();
}

class _RingingAlarmStopBannerState extends State<RingingAlarmStopBanner> {
  bool _ringing = false;
  bool _dialogShowing = false; // 🆕 [2026-09-05 추가] 팝업 중복 호출 방지
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _check();
    // 🆕 [2026-09-05 변경] 1초마다 확인해서 울리기 시작하면 즉시 전체화면 팝업을 띄움
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => _check());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    final bool ringing = await NotificationService.isAlarmRinging();
    if (!mounted) return;
    if (ringing == _ringing) return;

    setState(() => _ringing = ringing);

    if (ringing && !_dialogShowing) {
      _showFullScreenAlarmDialog(); // 🆕 [2026-09-05 추가] 울리기 시작하면 자동으로 전체화면 팝업
    } else if (!ringing && _dialogShowing) {
      // 🆕 [2026-09-05 추가] 안전정지 타이머 등 다른 경로로 알람이 이미 꺼졌다면
      // 열려있는 팝업도 자동으로 닫아줌 (사용자가 끄지 않았는데도 계속 떠있는 것 방지)
      _dismissDialogIfShowing();
    }
  }

  void _dismissDialogIfShowing() {
    if (!mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  // 🆕 [2026-09-05 추가] 알람이 울리기 시작하면 자동으로 뜨는 전체화면 팝업.
  // rootNavigator를 써서, 지금 어떤 화면(다이얼로그/탭/중첩 라우트) 위에
  // 있었든 상관없이 앱의 최상단에 뜨도록 함.
  Future<void> _showFullScreenAlarmDialog() async {
    _dialogShowing = true;
    await showGeneralDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false, // 바깥을 눌러도 안 닫힘
      barrierColor: Colors.black.withOpacity(0.92),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return PopScope(
          canPop: false, // 🆕 뒤로가기 버튼으로도 안 닫힘 (반드시 끄기 버튼을 눌러야 함)
          child: _FullScreenAlarmStopView(
            onStop: () async {
              await NotificationService.stopAlarmSound();
              if (Navigator.of(dialogContext, rootNavigator: true).canPop()) {
                Navigator.of(dialogContext, rootNavigator: true).pop();
              }
            },
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
    _dialogShowing = false;
  }

  @override
  Widget build(BuildContext context) {
    // 🆕 [2026-09-05 변경] 이 위젯 자체는 화면에 아무것도 그리지 않음 - 실제
    // 표시는 위 _showFullScreenAlarmDialog()가 담당. 감시 전용 위젯.
    return const SizedBox.shrink();
  }
}

// 🆕 [2026-09-05 신규] 전체화면 알람 끄기 화면. 큰 아이콘 + 문구 + 아주 큰
// 빨간 버튼 하나로 구성해서, 한 번의 탭으로 확실하게 끌 수 있게 함.
class _FullScreenAlarmStopView extends StatelessWidget {
  final Future<void> Function() onStop;
  const _FullScreenAlarmStopView({required this.onStop});

  static const Color _pageBg = Color(0xFF030712);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _pageBg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.85, end: 1.0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOut,
                builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                child: const Icon(Icons.alarm_rounded, color: Color(0xFFDC2626), size: 96),
              ),
              const SizedBox(height: 24),
              const Text(
                '알람이 울리고 있습니다',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                '아래 버튼을 눌러 알람을 끄세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onStop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                  ),
                  child: const Text(
                    '알람 끄기',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

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
