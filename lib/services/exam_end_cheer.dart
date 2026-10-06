// exam_end_cheer.dart
//
// 🆕 [2026-10-06] 시험이 끝난 다음 날부터, 학생이 첫 화면이나 자기주도 플래너
// (평상시 · 방학 · 시험준비 · 개인시간표 어디로 들어가든)를 열면 "시험 보느라 수고했어요"
// 위로 팝업을 보여 줌.
//  - 맨 아래 [오늘만 그만보기] : 오늘은 다시 안 뜸
//  - 맨 아래 [그만보기]        : 이번 시험에 대해서는 다시 안 뜸
//  - 시험 끝난 뒤 7일이 지나면 저절로 안 뜸
//  - 앱을 한 번 켜 둔 동안에는 한 번만 뜸 (화면을 오갈 때마다 반복되지 않게)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExamEndCheer {
  ExamEndCheer._();

  static const String _kOffForExam = 'gke_exam_end_cheer_off'; // 그만보기 누른 시험(마지막 날)
  static const String _kHiddenDate = 'gke_exam_end_cheer_hidden_date'; // 오늘만 그만보기 누른 날
  static const String kLastEndKey = 'gke_exam_last_end_date'; // 시험 시간표를 끈 뒤에도 기억하는 마지막 날
  static bool _shownThisRun = false;

  static const Color _gold = Color(0xFFE5C158);

  // 100자 이내 위로 문장
  static const String _msgKo = '시험 보느라 정말 수고 많았어요.\n결과보다 끝까지 해낸 그 노력이 더 소중해요.\n오늘은 마음 편히 쉬고, 다시 천천히 시작해요. 🌙';
  static const String _msgEn = 'You worked so hard through your exams. Your effort matters more than any result. Rest well today, and start again gently. 🌙';

  static String _key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 보여 줄 때가 되면 팝업을 띄움. (아니면 아무것도 안 함)
  static Future<void> maybeShow(BuildContext context) async {
    if (_shownThisRun) return;
    final prefs = await SharedPreferences.getInstance();
    final String? endStr = prefs.getString('gke_exam_end_date') ?? prefs.getString(kLastEndKey);
    if (endStr == null) return;
    final DateTime? end = DateTime.tryParse(endStr);
    if (end == null) return;

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime endDay = DateTime(end.year, end.month, end.day);
    final int daysAfter = today.difference(endDay).inDays;
    if (daysAfter < 1 || daysAfter > 7) return; // 끝난 다음 날 ~ 7일까지만

    final String endKey = _key(endDay);
    if (prefs.getString(_kOffForExam) == endKey) return; // 이번 시험은 그만보기
    if (prefs.getString(_kHiddenDate) == _key(today)) return; // 오늘만 그만보기
    if (!context.mounted) return;

    _shownThisRun = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dctx) => Dialog(
        backgroundColor: const Color(0xFF0D1527),
        insetPadding: const EdgeInsets.symmetric(horizontal: 26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _gold, width: 1.4),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌸', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              Text('Well done on your exams', style: GoogleFonts.gowunBatang(color: Colors.white54, fontSize: 12.5, fontWeight: FontWeight.bold)),
              Text('시험 보느라 수고했어요', style: GoogleFonts.notoSansKr(color: _gold, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                _msgKo,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14, height: 1.7),
              ),
              const SizedBox(height: 8),
              Text(
                _msgEn,
                textAlign: TextAlign.center,
                style: GoogleFonts.gowunBatang(color: Colors.white54, fontSize: 11.5, height: 1.5),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await prefs.setString(_kHiddenDate, _key(today));
                        if (dctx.mounted) Navigator.pop(dctx);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white30),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('오늘만 그만보기', style: GoogleFonts.notoSansKr(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await prefs.setString(_kOffForExam, endKey);
                        if (dctx.mounted) Navigator.pop(dctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('그만보기', style: GoogleFonts.notoSansKr(color: const Color(0xFF030712), fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
