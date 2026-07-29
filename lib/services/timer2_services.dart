import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

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
  static const String _channelName = 'StudyUp 학습 타임라인 알림';
  static const String _channelDesc = '오늘 하루 전체 시작 시 각 시간표 항목의 시작/종료를 알려줍니다';

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

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
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
          '📖 학습 시작 / $taskText',
          '$timeStr · 지금 시작할 시간입니다',
          tz.TZDateTime.from(startDt, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDesc,
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
          '✅ 학습 종료 / $taskText',
          '$timeStr 완료 · 다음 항목을 준비하세요',
          tz.TZDateTime.from(endDt, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDesc,
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
