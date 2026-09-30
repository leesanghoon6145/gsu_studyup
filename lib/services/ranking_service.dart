// ranking_service.dart
//
// 🆕 [랭킹 2026-10-01] 친구 학습 랭킹 · 전 세계 학습 랭킹을 "진짜로" 계산.
// - 기준: 이번 달 공부 시간(분). 매달 1일에 새로 시작.
// - 친구 = 같은 학교 · 같은 학년 학생들 (가입 때 넣은 학교·학년)
// - 전 세계 = 이 앱을 쓰는 모든 학생
// - 서버(rankings/{이번달}/users/{내 계정})에는 공부 시간과 "학교·학년을 섞어 만든 암호 이름표"만
//   올라감. 이름·학교 이름은 절대 올라가지 않고, 화면에는 "내 순위"만 보임.
// - 학생이 혼자면 1위(1명 중), 학생이 늘어나면 순위가 저절로 바뀜.

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'user_profile_service.dart';

class RankResult {
  final int rank;
  final int total;
  const RankResult(this.rank, this.total);

  /// 상위 몇 % (1위면 작은 값). 1명뿐이면 100%가 아니라 1위로만 보이게 화면에서 처리
  int get topPercent => total <= 0 ? 100 : ((rank / total) * 100).ceil().clamp(1, 100);
}

class RankingService {
  RankingService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String _monthKey(DateTime d) => '${d.year}${d.month.toString().padLeft(2, '0')}';

  // 학교·학년을 섞어 만든 암호 이름표 (서버에 학교 이름이 그대로 남지 않게)
  static String _groupKey(String school, String grade) {
    final String s = '${school.replaceAll(' ', '').toLowerCase()}|${grade.replaceAll(' ', '')}';
    int h = 0x811c9dc5;
    for (final int c in utf8.encode(s)) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16);
  }

  /// 내 이번 달 공부 시간을 올리고, 친구 순위·전 세계 순위를 받아 옴.
  static Future<({RankResult? friend, RankResult? global, bool hasGroup})> updateAndFetch(int monthMinutes) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return (friend: null, global: null, hasGroup: false);

    final col = _db.collection('rankings').doc(_monthKey(DateTime.now())).collection('users');
    String groupKey = '';
    try {
      final String school = (await DkeUserProfile.getSchoolName()) ?? '';
      final String grade = (await DkeUserProfile.getGrade()) ?? '';
      if (school.trim().isNotEmpty && grade.trim().isNotEmpty) groupKey = _groupKey(school, grade);
    } catch (_) {}

    try {
      await col.doc(uid).set({
        'minutes': monthMinutes,
        'groupKey': groupKey,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[RankingService] 내 공부 시간 올리기 실패: $e');
    }

    RankResult? global;
    try {
      final higher = await col.where('minutes', isGreaterThan: monthMinutes).count().get();
      final all = await col.count().get();
      global = RankResult((higher.count ?? 0) + 1, (all.count ?? 1).clamp(1, 1 << 30));
    } catch (e) {
      debugPrint('[RankingService] 전 세계 순위 계산 실패: $e');
    }

    RankResult? friend;
    if (groupKey.isNotEmpty) {
      try {
        final snap = await col.where('groupKey', isEqualTo: groupKey).get();
        final int higher = snap.docs.where((d) => ((d.data()['minutes'] as num?) ?? 0) > monthMinutes).length;
        friend = RankResult(higher + 1, snap.docs.isEmpty ? 1 : snap.docs.length);
      } catch (e) {
        debugPrint('[RankingService] 친구 순위 계산 실패: $e');
      }
    }
    return (friend: friend, global: global, hasGroup: groupKey.isNotEmpty);
  }
}
