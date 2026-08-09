// ============================================================================
// 🆕 [일반 플래너 - 알림] ReminderDataService
// 알림(제목/날짜/시간/반복/켜짐여부/메모)을 저장/불러오는 서비스입니다.
//
// ⚠️ [중요 - 다음 작업 필요] 이 서비스는 "알림 데이터"를 저장/관리하는
// 부분까지만 구현되어 있습니다. 저장된 알림을 실제로 정해진 시각에 폰에서
// 푸시 알림으로 띄우는 것은 별도 연결이 필요합니다. 이 앱에는 이미
// services/timer2_services.dart(Timer2Service)라는 알림 발송 서비스가
// 타이머 화면에서 쓰이고 있으므로, 그 서비스의 실제 코드를 확인한 뒤
// 안전하게 연결해야 합니다(잘못 연결하면 기존 타이머 알림 기능이
// 깨질 위험이 있어 이번 작업에서는 데이터 저장까지만 완료했습니다).
// ============================================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderItem {
  final String id;
  final String title;
  final String date; // 'yyyy-MM-dd'
  final String time; // 'HH:mm'
  final String repeatType; // '한번' | '매일' | '매주'
  bool isEnabled;
  final String memo;

  ReminderItem({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    this.repeatType = '한번',
    this.isEnabled = true,
    this.memo = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date,
    'time': time,
    'repeatType': repeatType,
    'isEnabled': isEnabled,
    'memo': memo,
  };

  factory ReminderItem.fromJson(Map<String, dynamic> json) => ReminderItem(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    date: json['date'] as String? ?? '',
    time: json['time'] as String? ?? '',
    repeatType: json['repeatType'] as String? ?? '한번',
    isEnabled: json['isEnabled'] as bool? ?? true,
    memo: json['memo'] as String? ?? '',
  );
}

class ReminderDataService {
  static const String _kKey = 'gke_general_planner_reminders_v1';

  static Future<List<ReminderItem>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      final list = decoded.map((e) => ReminderItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      list.sort((a, b) {
        final cmp = a.date.compareTo(b.date);
        if (cmp != 0) return cmp;
        return a.time.compareTo(b.time);
      });
      return list;
    } catch (e) {
      return [];
    }
  }

  static Future<void> add(ReminderItem item) async {
    final all = await loadAll();
    all.add(item);
    await _saveAll(all);
  }

  static Future<void> update(ReminderItem updated) async {
    final all = await loadAll();
    final idx = all.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      all[idx] = updated;
      await _saveAll(all);
    }
  }

  static Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((e) => e.id == id);
    await _saveAll(all);
  }

  static Future<void> _saveAll(List<ReminderItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kKey, jsonEncode(items.map((e) => e.toJson()).toList()));
    } catch (e) {}
  }
}
