// lib/services/sleep_log_service.dart
//
// 🆕 [수면 직접 기록 2026-10-07] 원장님 원칙
// 1) 삼성헬스(워치)가 있으면 자동으로 읽고, 없으면 학생이 "잔 시각 · 일어난 시각" 두 칸만 직접 기록
// 2) 직접 기록한 값이 자동 값보다 우선 (자동 값은 직접 기록을 덮어쓰지 않음)
// 3) 오늘 아침 기록은 부모님 화면(links/{코드}/lastSleep)으로 보냄
// 4) 저장 위치는 운동 화면과 같은 'gke_sleep_YYYY-MM-DD' → 성취도·일간 리포트에서 함께 사용

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../schedule/exercise_step_service.dart';
import 'family_link_service.dart';

class SleepLogService {
  SleepLogService._();

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static String _key(DateTime d) => 'gke_sleep_${_dateKey(d)}';

  static Future<Map<String, dynamic>?> _raw(DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key(day));
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  /// 그날 아침에 깬 수면 (직접 기록 또는 삼성헬스)
  static Future<SleepSummary?> get(DateTime day) async {
    final Map<String, dynamic>? m = await _raw(day);
    if (m == null) return null;
    final SleepSummary s = SleepSummary.fromJson(m);
    return s.minutes > 0 ? s : null;
  }

  /// 직접 기록한 값인지
  static Future<bool> isManual(DateTime day) async => (await _raw(day))?['manual'] == true;

  /// 삼성헬스 값 저장 — 직접 기록이 있으면 덮어쓰지 않음
  static Future<void> saveAuto(DateTime day, SleepSummary s) async {
    if (await isManual(day)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(day), jsonEncode(s.toJson()));
  }

  /// 직접 기록 저장 (+ 오늘이면 부모님께 보냄)
  static Future<SleepSummary> saveManual(DateTime day, DateTime start, DateTime end) async {
    final SleepSummary s = SleepSummary(minutes: end.difference(start).inMinutes, start: start, end: end);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(day), jsonEncode({...s.toJson(), 'manual': true}));
    await pushToParents(day, s, manual: true);
    return s;
  }

  /// 오늘 아침 수면만 부모님 화면으로 보냄 (지난 날짜는 보내지 않음)
  static Future<void> pushToParents(DateTime day, SleepSummary s, {bool manual = false}) async {
    try {
      final DateTime n = DateTime.now();
      if (_dateKey(day) != _dateKey(n)) return;
      final String? code = await FamilyLinkService.getMyLinkCode();
      if (code == null) return;
      await FirebaseFirestore.instance.collection('links').doc(code).set({
        'lastSleep': {
          'date': _dateKey(day),
          'minutes': s.minutes,
          'start': s.start?.toIso8601String(),
          'end': s.end?.toIso8601String(),
          'manual': manual,
        },
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[수면] 부모님께 보내기 실패: $e');
    }
  }

  /// 잔 시각 · 일어난 시각 입력 창. 저장하면 true.
  /// day = 그날 아침(일어난 날). 비우면 오늘.
  static Future<bool> showEditor(BuildContext context, {DateTime? day}) async {
    final DateTime base = day ?? DateTime.now();
    final DateTime d = DateTime(base.year, base.month, base.day);
    final SleepSummary? cur = await get(d);
    TimeOfDay bed = cur?.start != null ? TimeOfDay.fromDateTime(cur!.start!) : const TimeOfDay(hour: 23, minute: 0);
    TimeOfDay wake = cur?.end != null ? TimeOfDay.fromDateTime(cur!.end!) : const TimeOfDay(hour: 7, minute: 0);
    if (!context.mounted) return false;

    const Color gold = Color(0xFFE5C158);
    String t(TimeOfDay x) => '${x.hour.toString().padLeft(2, '0')}:${x.minute.toString().padLeft(2, '0')}';

    // 잔 시각이 낮 12시 이후면 전날 밤, 그 전이면(새벽) 그날
    DateTime bedAt() => DateTime(d.year, d.month, d.day - (bed.hour >= 12 ? 1 : 0), bed.hour, bed.minute);
    DateTime wakeAt() => DateTime(d.year, d.month, d.day, wake.hour, wake.minute);

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final int mins = wakeAt().difference(bedAt()).inMinutes;
          final bool valid = mins > 0 && mins <= 16 * 60;
          Widget pick(String label, TimeOfDay v, void Function(TimeOfDay) onPicked) => Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final TimeOfDay? p = await showTimePicker(context: ctx, initialTime: v);
                if (p != null) setD(() => onPicked(p));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: gold.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Text(label, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(t(v), style: GoogleFonts.notoSansKr(color: gold, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          );
          return AlertDialog(
            backgroundColor: const Color(0xFF0D1527),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('😴 ${d.month}/${d.day} 아침 · 수면 기록',
                style: GoogleFonts.notoSansKr(color: gold, fontWeight: FontWeight.bold, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    pick('🌙 잔 시각', bed, (p) => bed = p),
                    const SizedBox(width: 10),
                    pick('☀️ 일어난 시각', wake, (p) => wake = p),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  valid ? '총 ${mins ~/ 60}시간 ${mins % 60}분 잤어요' : '시각을 다시 확인해 주세요',
                  style: GoogleFonts.notoSansKr(color: valid ? Colors.white : Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text('시각을 누르면 바꿀 수 있어요. 직접 기록은 삼성헬스 값보다 먼저 쓰여요.',
                    textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 11)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('취소', style: GoogleFonts.notoSansKr(color: Colors.white60, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: gold),
                onPressed: valid ? () => Navigator.pop(ctx, true) : null,
                child: Text('저장', style: GoogleFonts.notoSansKr(color: const Color(0xFF030712), fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
    if (saved != true) return false;
    await saveManual(d, bedAt(), wakeAt());
    return true;
  }
}
