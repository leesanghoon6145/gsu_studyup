// report_archive_service.dart
//
// 🆕 [리포트 저장 2026-10-01] 원장님 원칙
// 1) 한 번 보여 준 리포트는 서버(links/{코드}/reports)에 저장 → 부모·자녀가 같은 글을 보고,
//    며칠 뒤 다시 열어도 그대로 나옴 (생업으로 2~3일 뒤 몰아 보는 부모님 배려)
// 2) 점수대가 다르면 글도 다름 (98점 리포트 ≠ 80점 리포트)
// 3) 같은 학생에게는 전에 받은 문장 조합을 다시 쓰지 않음 (1차 98점과 2차 98점은 비슷해도 100% 같지 않게).
//    모든 조합을 다 쓴 뒤에만 가장 오래전 것을 다시 쓰고, 이때도 날짜·시간·과목이 달라 글이 똑같지 않음
// 4) 다른 학생과는 같은 문장 은행을 함께 씀 (비슷한 점수대 문장을 가져다 사용)

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'diagnosis_service.dart';
import 'parent_data_service.dart'; // 🆕 [2026-10-07] 앞 6일 공부 시간 계산

class ReportArchiveService {
  ReportArchiveService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _col(String code) =>
      _db.collection('links').doc(code).collection('reports');

  static String ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 평가 기록 하나를 늘 같은 이름표로 바꿈 (같은 평가를 다시 열면 같은 리포트가 나오게)
  static String stableId(Object? raw) {
    final String s = jsonEncode(raw, toEncodable: (o) => o.toString());
    int h = 0x811c9dc5;
    for (final int c in utf8.encode(s)) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16);
  }

  /// 🆕 [2026-10-01] 부모 화면과 학생 화면이 "같은 평가"를 같은 이름표로 찾도록
  /// 평가 종류·과목·점수·날짜(앞 10글자)만으로 이름표를 만듦
  static String examKeyOf({
    required String type,
    required String subject,
    required double score,
    Object? rawExam,
  }) {
    String d = '';
    if (rawExam is Map && rawExam['date'] != null) {
      final String full = rawExam['date'].toString();
      d = full.length >= 10 ? full.substring(0, 10) : full;
    }
    return stableId({'t': type, 's': subject, 'sc': score.round(), 'd': d});
  }

  // 이 학생이 이미 받은 문장 조합 → 받은 시각
  static Future<Map<String, String>> _seen(String code, String bucket) async {
    try {
      final d = await _col(code).doc('_seen').get();
      final Map raw = (d.data()?[bucket] as Map?) ?? {};
      return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _markSeen(String code, String bucket, String comboId) async {
    try {
      await _col(code).doc('_seen').set({
        bucket: {comboId: DateTime.now().toIso8601String()},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[ReportArchiveService] 사용 기록 저장 실패: $e');
    }
  }
  /// 🆕 [2026-10-07] 그날 이전 6일의 날짜별 공부 시간(분) — 부모·학생이 같은 기록(links 문서)을 보므로 두 화면 결과가 같음
  static Future<List<int>> _previousDaysMinutes(String code, DateTime day) async {
    try {
      final snap = await _db.collection('links').doc(code).get();
      final List raw = (snap.data()?['sessionHistory'] as List?) ?? const [];
      final List<ParentSessionRecord> all = [];
      for (final e in raw) {
        try {
          all.add(ParentSessionRecord.fromJson(Map<String, dynamic>.from(e as Map)));
        } catch (_) {}
      }
      final DateTime d0 = DateTime(day.year, day.month, day.day);
      return [for (int i = 1; i <= 6; i++) ParentDataService.totalMinutesForDay(all, d0.subtract(Duration(days: i)))];
    } catch (e) {
      debugPrint('[ReportArchiveService] 앞 6일 기록 읽기 실패(예전 방식으로): $e');
      return const [];
    }
  }

  /// 그날의 종합 총평. 저장된 글이 있으면 그대로, 없으면 새로 만들어 저장.
  /// 오늘은 공부가 더 쌓여 구간(짧음→많음)이 바뀌면 새 글로 바꿈. 지난 날짜는 절대 바뀌지 않음.
  static Future<String> dailySummary({
    required String code,
    required String personKey,
    required DateTime day,
    required int subjectCount,
    required int totalMinutes,
  }) async {
    // 🆕 [2026-10-07] 앞 6일과 비교해서 단계 결정 (비교 못 하면 '짧다' 문장 안 씀)
    final List<int> prev = await _previousDaysMinutes(code, day);
    final String tier = DiagnosisService.dailyTierSafe(totalMinutes, prev);
    final ref = _col(code).doc('daily_${ymd(day)}');
    try {
      final snap = await ref.get();
      final Map<String, dynamic>? data = snap.data();
      Map<String, String> texts;
      if (data != null && data['tier'] == tier && data['texts'] is Map) {
        texts = Map<String, dynamic>.from(data['texts'] as Map).map((k, v) => MapEntry(k, v.toString()));
      } else {
        final Map<String, dynamic> combo = DiagnosisService.newDailyCombo(tier, await _seen(code, 'daily'));
        texts = Map<String, String>.from(combo['texts'] as Map);
        await ref.set({
          'tier': tier,
          'comboId': combo['comboId'],
          'texts': texts,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _markSeen(code, 'daily', combo['comboId'] as String);
      }
      final Map<String, String> filled = texts.map((k, v) => MapEntry(
        k,
        v.replaceAll('{subjectCount}', '$subjectCount').replaceAll('{totalMinutes}', '$totalMinutes'),
      ));
      // 🆕 [2026-10-07] 실제 숫자 비교 한 줄을 끝에 붙임
      final Map<String, String> cmp = DiagnosisService.dailyCompareTexts(totalMinutes, prev);
      final Map<String, String> withCmp = filled.map((k, v) => MapEntry(k, cmp[k] != null ? '$v ${cmp[k]}' : v));
      return DiagnosisService.displayTexts(withCmp);
    } catch (e) {
      debugPrint('[ReportArchiveService] 종합 총평 저장·조회 실패(기기 안에서 만든 글로 대신): $e');
      return DiagnosisService.getDailySummary(personKey: personKey, subjectCount: subjectCount, totalMinutes: totalMinutes);
    }
  }

  /// 평가 하나에 대한 정밀 진단서. 같은 평가는 언제 열어도 같은 글, 새 평가는 전에 안 쓴 조합으로.
  static Future<String> examAnalysis({
    required String code,
    required String personKey,
    required Object? rawExam,
    required String type,
    required String subject,
    required double score,
  }) async {
    final ref = _col(code).doc('exam_${examKeyOf(type: type, subject: subject, score: score, rawExam: rawExam)}');
    try {
      final snap = await ref.get();
      final Map<String, dynamic>? data = snap.data();
      Map<String, String> texts;
      if (data != null && data['texts'] is Map) {
        texts = Map<String, dynamic>.from(data['texts'] as Map).map((k, v) => MapEntry(k, v.toString()));
      } else {
        final Map<String, dynamic> combo = DiagnosisService.newAnalysisCombo(
          score: score,
          type: type,
          subject: subject,
          seen: await _seen(code, 'diag'),
        );
        texts = Map<String, String>.from(combo['texts'] as Map);
        await ref.set({
          'comboId': combo['comboId'],
          'score': score,
          'subject': subject,
          'type': type,
          'texts': texts,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _markSeen(code, 'diag', combo['comboId'] as String);
      }
      return DiagnosisService.displayTexts(texts);
    } catch (e) {
      debugPrint('[ReportArchiveService] 진단서 저장·조회 실패(기기 안에서 만든 글로 대신): $e');
      return DiagnosisService.getAnalysis(personKey: personKey, type: type, subject: subject, score: score);
    }
  }
}
