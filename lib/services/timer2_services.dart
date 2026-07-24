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
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

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
  /// - 반환값: {scheduled: 예약된 항목 수, skippedPast: 지나서 제외된 항목 수}
  static Future<Map<String, int>> scheduleFullDaySchedule({
    required List<Map<String, String>> schedule,
    required String examTitle,
  }) async {
    int scheduledCount = 0;
    int skippedCount = 0;
    final DateTime now = DateTime.now();

    await cancelAllTimelineNotifications(); // 재예약 전 기존 것 정리 (중복 방지)

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
    }

    _lastScheduledItemCount = schedule.length; // [추가] 다음 취소 시 사용할 범위 갱신
    return {'scheduled': scheduledCount, 'skippedPast': skippedCount};
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