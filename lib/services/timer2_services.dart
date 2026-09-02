import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:shared_preferences/shared_preferences.dart'; // 🆕 [12개국어 지원 2026-09-02] 저장된 언어 설정을 읽기 위함

class Timer2Service {
  Timer2Service._();

  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  // 🔑 알림 탭 시 화면 이동을 위한 전역 네비게이터 키 (main.dart의 MaterialApp에 연결)
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  // 알림을 탭했을 때 실행할 콜백. main.dart에서 등록합니다.
  static void Function(Map<String, dynamic> data)? onNotificationStartTapped;

  static const String _channelId = 'studyup_timeline_channel';
  // 🆕 [12개국어 지원 2026-09-02] 채널 이름/설명은 더 이상 고정 문자열이 아니라
  // _notif 카탈로그 + _getCurrentLangCode()로 매번 언어에 맞게 구성됩니다.
  // (기존 _channelName/_channelDesc 상수는 더 이상 쓰지 않아 제거함)

  // ============================================================================
  // 🆕 [12개국어 완전 지원 2026-09-02] 이 서비스는 화면(Widget)이 아니라 정적(static)
  // 클래스라서, 다른 화면들처럼 State의 _currentLanguageCode를 바로 쓸 수 없습니다.
  // 대신 다른 화면들과 완전히 동일한 저장 키('saved_language_code')를 SharedPreferences에서
  // 직접 읽어와 판단합니다 - 화면 어디서 저장했든 항상 최신 값을 그대로 따라갑니다.
  // ============================================================================
  static const List<String> _foreignLangs = ['JA', 'ZH', 'FR', 'DE', 'RU', 'AR', 'HI', 'VI', 'ES', 'TH'];

  static Future<String> _getCurrentLangCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getString('saved_language_code') ?? 'ko').toUpperCase();
    } catch (e) {
      return 'KO';
    }
  }

  // 🆕 [12개국어] 알림 채널 이름/설명, 시작/종료 알림 제목·본문 카탈로그
  static const Map<String, Map<String, String>> _notif = {
    'channelName': {
      'EN': 'StudyUp Timeline Notification', 'KO': 'StudyUp 학습 타임라인 알림',
      'JA': 'StudyUp学習タイムライン通知', 'ZH': 'StudyUp学习时间表通知', 'FR': 'Notification chronologie StudyUp',
      'DE': 'StudyUp Zeitplan-Benachrichtigung', 'RU': 'Уведомление о расписании StudyUp',
      'AR': 'إشعار الجدول الزمني لـ StudyUp', 'HI': 'StudyUp समयरेखा सूचना', 'VI': 'Thông báo dòng thời gian StudyUp',
      'ES': 'Notificación de cronograma StudyUp', 'TH': 'การแจ้งเตือนไทม์ไลน์ StudyUp',
    },
    'channelDesc': {
      'EN': 'Notifies the start/end of each timetable item when "Start Full Day" is used.',
      'KO': '오늘 하루 전체 시작 시 각 시간표 항목의 시작/종료를 알려줍니다',
      'JA': '「1日全体を開始」使用時、各時間割項目の開始・終了をお知らせします。',
      'ZH': '使用"开始全天"时，通知每个时间表项目的开始/结束。',
      'FR': 'Notifie le début/fin de chaque créneau lorsque "Démarrer la journée complète" est utilisé.',
      'DE': 'Benachrichtigt über Beginn/Ende jedes Zeitplanpunkts bei Nutzung von "Ganzen Tag starten".',
      'RU': 'Уведомляет о начале/окончании каждого пункта расписания при использовании "Начать весь день".',
      'AR': 'يُعلم ببداية/نهاية كل عنصر في الجدول عند استخدام "بدء اليوم بالكامل".',
      'HI': '"पूरा दिन शुरू करें" का उपयोग करते समय प्रत्येक समय-सारणी आइटम की शुरुआत/समाप्ति की सूचना देता है।',
      'VI': 'Thông báo bắt đầu/kết thúc mỗi mục trong lịch trình khi dùng "Bắt đầu cả ngày".',
      'ES': 'Notifica el inicio/fin de cada elemento del horario al usar "Iniciar día completo".',
      'TH': 'แจ้งเตือนการเริ่ม/สิ้นสุดของแต่ละรายการตารางเวลาเมื่อใช้ "เริ่มทั้งวัน"',
    },
    'startTitle': {
      'EN': '📖 Study Start', 'KO': '📖 학습 시작', 'JA': '📖 学習開始', 'ZH': '📖 学习开始', 'FR': '📖 Début de l\'étude',
      'DE': '📖 Lernbeginn', 'RU': '📖 Начало занятия', 'AR': '📖 بدء الدراسة', 'HI': '📖 अध्ययन प्रारंभ',
      'VI': '📖 Bắt đầu học', 'ES': '📖 Inicio del estudio', 'TH': '📖 เริ่มเรียน',
    },
    'startBody': {
      'EN': 'Time to start now', 'KO': '지금 시작할 시간입니다', 'JA': '今が開始の時間です', 'ZH': '现在是开始的时间',
      'FR': 'C\'est le moment de commencer', 'DE': 'Es ist Zeit anzufangen', 'RU': 'Пора начинать',
      'AR': 'حان وقت البدء الآن', 'HI': 'अभी शुरू करने का समय है', 'VI': 'Đã đến giờ bắt đầu',
      'ES': 'Es hora de empezar', 'TH': 'ถึงเวลาเริ่มแล้ว',
    },
    'endTitle': {
      'EN': '✅ Study End', 'KO': '✅ 학습 종료', 'JA': '✅ 学習終了', 'ZH': '✅ 学习结束', 'FR': '✅ Fin de l\'étude',
      'DE': '✅ Lernen beendet', 'RU': '✅ Конец занятия', 'AR': '✅ انتهاء الدراسة', 'HI': '✅ अध्ययन समाप्त',
      'VI': '✅ Kết thúc học', 'ES': '✅ Fin del estudio', 'TH': '✅ เรียนจบแล้ว',
    },
    'endBody': {
      'EN': 'Completed - get ready for the next item', 'KO': '완료 · 다음 항목을 준비하세요',
      'JA': '完了・次の項目の準備をしましょう', 'ZH': '已完成 · 请准备下一项', 'FR': 'Terminé · préparez l\'élément suivant',
      'DE': 'Abgeschlossen · bereiten Sie den nächsten Punkt vor', 'RU': 'Завершено · подготовьтесь к следующему пункту',
      'AR': 'اكتمل · استعد للعنصر التالي', 'HI': 'पूर्ण · अगली वस्तु के लिए तैयार हों',
      'VI': 'Hoàn thành · chuẩn bị cho mục tiếp theo', 'ES': 'Completado · prepárate para el siguiente elemento',
      'TH': 'เสร็จสิ้น · เตรียมพร้อมสำหรับรายการถัดไป',
    },
  };

  // 🆕 [버그 수정] 정확한 알람 권한이 실제로 허용됐는지 마지막으로 확인한 결과를 기억해둠.
  // false면 scheduleFullDaySchedule()이 zonedSchedule을 시도조차 하지 않고 바로 결과를 반환해서
  // "2~3분 동안 멈춘 것처럼 보이는" 현상을 막음.
  static bool _exactAlarmPermissionGranted = false;

  static Future<void> initialize() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul')); // 한국 학생 대상 앱이므로 고정

    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
    InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // 🆕 [버그 수정] 알림 권한 요청 자체가 예외를 던지는 기기/OS 버전이 있을 수 있어 try/catch로 감쌈
    try {
      await androidImpl?.requestNotificationsPermission();
    } catch (e) {
      debugPrint("[Timer2Service] 알림 권한 요청 실패: $e");
    }

    // 🆕 [버그 수정] Android 12+ "정확한 알람" 권한은 다이얼로그가 아니라 설정 화면으로 이동하는 방식이라
    // 사용자가 실제로 켜줬는지 별도로 확인해서 _exactAlarmPermissionGranted에 저장해둠.
    try {
      await androidImpl?.requestExactAlarmsPermission();
      final bool? granted = await androidImpl?.canScheduleExactNotifications();
      _exactAlarmPermissionGranted = granted ?? false;
    } catch (e) {
      debugPrint("[Timer2Service] 정확한 알람 권한 확인 실패(구버전 OS이거나 미지원 기기일 수 있음): $e");
      // 권한 확인 자체를 지원하지 않는 기기/OS는 일반 알람 모드로라도 시도할 수 있게 true로 간주
      _exactAlarmPermissionGranted = true;
    }

    // 🆕 [12개국어 지원] 채널 생성 시점의 언어로 이름/설명을 정합니다.
    // ⚠️ [Android 제약] 안드로이드 알림 채널은 한 번 만들어지면 이름/설명이 코드로
    // 다시 안 바뀌는 특성이 있습니다(notification_service.dart에도 동일 메모 있음).
    // 그래서 앱을 처음 설치했을 때의 언어로 고정되며, 이후 언어를 바꿔도 이미 생성된
    // 채널의 표시 이름은 안 바뀔 수 있습니다(안드로이드 OS 자체의 한계).
    final String langCode = await _getCurrentLangCode();
    final bool isForeign = _foreignLangs.contains(langCode);
    final String channelName = isForeign
        ? (_notif['channelName']![langCode] ?? _notif['channelName']!['EN']!)
        : '${_notif['channelName']!['EN']} (${_notif['channelName']!['KO']})';
    final String channelDesc = isForeign
        ? (_notif['channelDesc']![langCode] ?? _notif['channelDesc']!['EN']!)
        : '${_notif['channelDesc']!['EN']} (${_notif['channelDesc']!['KO']})';

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      channelName,
      description: channelDesc,
      importance: Importance.high,
    );
    await androidImpl?.createNotificationChannel(channel);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload == null) return;
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      if (data['type'] == 'start') {
        onNotificationStartTapped?.call(data);
      }
      // type == 'end'는 이동 없이 정보 전달용 알림입니다.
    } catch (_) {}
  }

  /// 오늘 하루 전체 스케줄에 대해 항목별 시작/종료 알림을 예약합니다.
  /// - 이미 지난 시각의 항목은 건너뜁니다.
  /// - 🆕 [버그 수정] 정확한 알람 권한이 없으면 처음부터 시도하지 않고 즉시 반환합니다
  ///   (예전엔 권한 없이 zonedSchedule을 계속 호출하다가 예외로 멈춰서 화면이 "예약 처리 중"에서
  ///   영원히 안 넘어가는 것처럼 보였습니다).
  /// - 🆕 개별 항목 예약이 실패해도 나머지 항목은 계속 진행합니다 (한 개 실패로 전체가 멈추지 않음).
  /// - 반환값: {scheduled: 예약된 항목 수, skippedPast: 지나서 제외된 항목 수,
  ///           failed: 예약 시도했지만 실패한 항목 수, permissionDenied: 권한이 없어 아예 시도 못 했으면 1, 아니면 0}
  static Future<Map<String, int>> scheduleFullDaySchedule({
    required List<Map<String, String>> schedule,
    required String examTitle,
  }) async {
    int scheduledCount = 0;
    int skippedCount = 0;
    int failedCount = 0;
    final DateTime now = DateTime.now();

    // 🆕 [12개국어 지원] 이번 예약 작업 전체에 쓸 언어를 한 번만 조회 (항목마다 반복 조회하지 않도록)
    final String langCode = await _getCurrentLangCode();
    final bool isForeign = _foreignLangs.contains(langCode);
    String tr(String key) => isForeign ? (_notif[key]![langCode] ?? _notif[key]!['EN']!) : '${_notif[key]!['EN']} (${_notif[key]!['KO']})';
    final String channelNameLocalized = tr('channelName');
    final String channelDescLocalized = tr('channelDesc');

    // 🆕 [버그 수정] 권한이 없으면 아예 시도하지 않고 즉시 반환 -> "무한 대기"처럼 보이는 현상 방지
    if (!_exactAlarmPermissionGranted) {
      debugPrint("[Timer2Service] 정확한 알람 권한이 없어 예약을 진행하지 않습니다. 설정에서 권한을 켜주세요.");
      return {
        'scheduled': 0,
        'skippedPast': 0,
        'failed': 0,
        'permissionDenied': 1,
      };
    }

    try {
      await cancelAllTimelineNotifications().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint("[Timer2Service] 기존 알림 취소가 10초 넘게 걸려서 건너뛰고 계속 진행합니다.");
        },
      );
    } catch (e) {
      debugPrint("[Timer2Service] 기존 알림 취소 중 오류(무시하고 계속 진행): $e");
    }

    for (int i = 0; i < schedule.length; i++) {
      final item = schedule[i];
      final String timeStr = item['time'] ?? '';
      final String taskText = item['task'] ?? '';
      // [추가] 휴식/식사/취침 등은 알림 대상에서 제외
      if (_isRestOrMealTask(taskText)) {
        continue;
      }
      final times = _parseStartEnd(timeStr);
      if (times == null) continue;

      final DateTime startDt = times[0];
      final DateTime endDt = times[1];

      if (startDt.isBefore(now)) {
        skippedCount++;
        continue;
      }

      final int startId = _makeNotificationId(i, isEnd: false);
      final int endId = _makeNotificationId(i, isEnd: true);

      // 🆕 [버그 수정] 항목 하나 예약 실패해도 catch로 잡아서 다음 항목으로 계속 진행
      try {
        await _plugin.zonedSchedule(
          startId,
          '${tr('startTitle')} / $taskText',
          '$timeStr · ${tr('startBody')}',
          tz.TZDateTime.from(startDt, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              channelNameLocalized,
              channelDescription: channelDescLocalized,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
          payload: jsonEncode({
            'type': 'start',
            'task': taskText,
            'time': timeStr,
            'examTitle': examTitle,
            'durationMinutes': endDt.difference(startDt).inMinutes,
          }),
        );

        await _plugin.zonedSchedule(
          endId,
          '${tr('endTitle')} / $taskText',
          '$timeStr ${tr('endBody')}',
          tz.TZDateTime.from(endDt, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              channelNameLocalized,
              channelDescription: channelDescLocalized,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
          payload: jsonEncode({'type': 'end', 'task': taskText, 'time': timeStr}),
        );

        scheduledCount++;
      } catch (e) {
        debugPrint("[Timer2Service] '$taskText' 항목 예약 실패(건너뛰고 계속 진행): $e");
        failedCount++;
      }
    }

    _lastScheduledItemCount = schedule.length; // [추가] 다음 취소 시 사용할 범위 갱신
    return {
      'scheduled': scheduledCount,
      'skippedPast': skippedCount,
      'failed': failedCount,
      'permissionDenied': 0,
    };
  }

// [추가] 마지막으로 예약했던 항목 개수를 기억해서, 다음 취소 시 그 범위만 처리 (속도 개선)
  static int _lastScheduledItemCount = 60; // 최초 1회는 넉넉히 잡아둠

  static Future<void> cancelAllTimelineNotifications() async {
    final List<Future<void>> cancelFutures = [];
    for (int i = 0; i < _lastScheduledItemCount; i++) {
      cancelFutures.add(_plugin.cancel(_makeNotificationId(i, isEnd: false)));
      cancelFutures.add(_plugin.cancel(_makeNotificationId(i, isEnd: true)));
    }
    await Future.wait(cancelFutures); // 순차 대기 대신 동시 처리
  }

  static int _makeNotificationId(int index, {required bool isEnd}) {
    return index * 2 + (isEnd ? 1 : 0);
  }

  // [추가] 휴식/식사/취침 성격의 항목인지 판별 (알림 예약 제외 대상)
  static bool _isRestOrMealTask(String task) {
    const restKeywords = ['기상', '체조', '아침식사', '점심', '저녁', '학교생활', '취침', '마무리', '휴식'];
    return restKeywords.any((k) => task.contains(k));
  }

  /// "09:00 - 10:00" 형식을 오늘 날짜의 [시작DateTime, 종료DateTime]으로 변환
  static List<DateTime>? _parseStartEnd(String timeStr) {
    try {
      final parts = timeStr.split(RegExp(r'[-~–]'));
      if (parts.length < 2) return null;
      final startParts = parts.first.trim().split(':');
      final endParts = parts.last.trim().split(':');
      if (startParts.length < 2 || endParts.length < 2) return null;

      final now = DateTime.now();
      DateTime start = DateTime(
        now.year, now.month, now.day,
        int.parse(startParts[0]), int.parse(startParts[1]),
      );
      DateTime end = DateTime(
        now.year, now.month, now.day,
        int.parse(endParts[0]), int.parse(endParts[1]),
      );
      if (!end.isAfter(start)) {
        end = end.add(const Duration(days: 1)); // 자정 넘김 보정
      }
      return [start, end];
    } catch (_) {
      return null;
    }
  }
}
