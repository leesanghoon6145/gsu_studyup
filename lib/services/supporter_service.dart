// supporter_service.dart
//
// 🆕 [응원 가족 2026-09-30] 부모 말고도 할머니·할아버지·이모·삼촌·형·누나 등
// 최대 5명이 아이를 응원(별·응원 문구)할 수 있게 하는 기능.
//
// 흐름
// 1) 응원 가족이 "일반" 회원으로 가입 → 부모 응원별 화면 → [응원 가족으로 연결]
//    → 아이 코드 + 관계(할머니 등) + 이름 → 신청 (links/{code}.supporterRequests)
// 2) 보호자(부모)가 학부모방에서 [승인] → links/{code}.supporterUids 에 들어감
// 3) 응원 가족은 운동·가족 활동 체크로 모은 별을 아이에게 보냄
//    → links/{code}/gifts/{id} 에 "누가·몇 개" 기록 (보호자가 보낸 것도 함께 기록)
// 4) 응원 가족이 볼 수 있는 아이 정보는 "이번 달 총 공부 시간 + 공부한 날 수"뿐
//    → 아이 앱이 links/{code}/supportView/summary 에 올려 둠
//
// 보안: 응원 가족은 아이의 학습 기록(links/{code})을 읽을 수 없음 (보안 규칙이 막음)

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_profile_service.dart';

class SupportTarget {
  final String code;
  final bool approved;
  final String relation; // rel_ 뒤 이름표 (grandma 등)
  final String relationText; // "기타"일 때 직접 쓴 관계
  final String myName;
  final String studentName; // 승인 뒤에만 알 수 있음
  final int monthMinutes;
  final int monthDays;

  const SupportTarget({
    required this.code,
    required this.approved,
    required this.relation,
    required this.relationText,
    required this.myName,
    this.studentName = '',
    this.monthMinutes = 0,
    this.monthDays = 0,
  });
}

class SupporterService {
  SupporterService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const int maxSupporters = 5;

  /// 응원 가족이 고를 수 있는 관계 (보호자는 제외)
  static const List<String> supporterRelations = [
    'grandma', 'grandpa', 'grandmaM', 'grandpaM',
    'auntM', 'auntP', 'uncleP', 'uncleM', 'uncleW',
    'brother', 'sister', 'mom', 'dad', 'other',
  ];

  /// 보호자가 보낼 때 고르는 관계
  static const List<String> guardianRelations = ['mom', 'dad', 'guardian'];

  /// 🆕 [2026-10-02] "보호자"를 누르면 펼쳐지는 관계 (할머니·할아버지가 키우는 경우 등)
  static const List<String> extendedGuardianRelations = [
    'grandma', 'grandpa', 'uncleP', 'auntP', 'auntM', 'uncleW', 'brother', 'sister',
  ];

  static const Map<String, String> relationEmoji = {
    'mom': '👩', 'dad': '👨', 'guardian': '🧑', 'grandma': '👵', 'grandpa': '👴',
    'grandmaM': '👵', 'grandpaM': '👴', 'auntM': '👩', 'auntP': '👩',
    'uncleP': '👨', 'uncleM': '👨', 'uncleW': '👨', 'brother': '🧑', 'sister': '👧', 'other': '💛',
  };

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ---------------------------------------------------------------------------
  // 응원 가족 쪽
  // ---------------------------------------------------------------------------

  /// 응원 가족 신청. 성공이면 null, 실패면 오류 이름표
  /// ('errLogin' / 'errSup6' / 'errSupCode' / 'errSupFull' / 'errNetwork')
  static Future<String?> requestToSupport({
    required String code,
    required String name,
    required String relation,
    String relationText = '',
  }) async {
    final String? uid = _uid;
    if (uid == null) return 'errLogin';
    if (!RegExp(r'^\d{6}$').hasMatch(code)) return 'errSup6';
    try {
      final idx = await _db.collection('linkCodes').doc(code).get();
      if (!idx.exists) return 'errSupCode';
    } catch (e) {
      debugPrint('[SupporterService] linkCodes 확인 실패: $e');
      return 'errNetwork';
    }
    final Map<String, dynamic> info = {
      'name': name,
      'relation': relation,
      'relationText': relationText,
      'requestedAt': FieldValue.serverTimestamp(),
    };
    try {
      await _db.collection('links').doc(code).set({
        'supporterRequests': {uid: info},
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      debugPrint('[SupporterService] 신청 거부: ${e.code}');
      return e.code == 'permission-denied' ? 'errSupFull' : 'errNetwork';
    } catch (e) {
      return 'errNetwork';
    }
    try {
      await _db.collection('supporterLinks').doc(uid).set({
        'entries': {
          code: {'name': name, 'relation': relation, 'relationText': relationText},
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SupporterService] supporterLinks 저장 실패: $e');
    }
    return null;
  }

  /// 내가 응원 가족으로 신청한 아이 목록 + 승인 여부.
  /// 승인 여부는 "아이 요약(supportView)을 읽을 수 있는가"로 판단 (보안 규칙이 정해 줌).
  static Future<List<SupportTarget>> getMyTargets() async {
    final String? uid = _uid;
    if (uid == null) return [];
    Map<String, dynamic> entries = {};
    try {
      final doc = await _db.collection('supporterLinks').doc(uid).get();
      entries = Map<String, dynamic>.from((doc.data()?['entries'] as Map?) ?? {});
    } catch (e) {
      debugPrint('[SupporterService] supporterLinks 읽기 실패: $e');
      return [];
    }
    final List<SupportTarget> list = [];
    for (final e in entries.entries) {
      final Map<String, dynamic> info = Map<String, dynamic>.from((e.value as Map?) ?? {});
      bool approved = false;
      String studentName = '';
      int minutes = 0;
      int days = 0;
      try {
        final snap = await _db.collection('links').doc(e.key).collection('supportView').doc('summary').get();
        approved = true;
        final d = snap.data() ?? {};
        studentName = (d['studentName'] as String?) ?? '';
        final String mk = _monthKey(DateTime.now());
        if (d['monthKey'] == mk) {
          minutes = (d['monthMinutes'] as num?)?.toInt() ?? 0;
          days = (d['monthDays'] as num?)?.toInt() ?? 0;
        }
      } on FirebaseException catch (err) {
        approved = false; // permission-denied = 아직 승인 전 (또는 해제됨)
        if (err.code != 'permission-denied') debugPrint('[SupporterService] 요약 읽기 오류: ${err.code}');
      } catch (_) {
        approved = false;
      }
      list.add(SupportTarget(
        code: e.key,
        approved: approved,
        relation: (info['relation'] as String?) ?? 'other',
        relationText: (info['relationText'] as String?) ?? '',
        myName: (info['name'] as String?) ?? '',
        studentName: studentName,
        monthMinutes: minutes,
        monthDays: days,
      ));
    }
    return list;
  }

  /// 응원 가족이 아이에게 응원 팝업 보내기 (보안 규칙: pendingMessage 한 칸만 쓸 수 있음)
  static Future<void> pushMessageAsSupporter(String code, String text) async {
    try {
      await _db.collection('links').doc(code).set({
        'pendingMessage': {'text': text, 'sentAt': FieldValue.serverTimestamp()},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SupporterService] 응원 팝업 실패: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 보호자(부모) 쪽 — 학부모방에서 승인·거절·해제
  // ---------------------------------------------------------------------------

  /// 승인. 성공이면 null, 가득 찼으면 'dashSupFull'
  static Future<String?> approve(String code, String supporterUid, Map<String, dynamic> info) async {
    final ref = _db.collection('links').doc(code);
    try {
      final snap = await ref.get();
      final List<dynamic> now = (snap.data()?['supporterUids'] as List?) ?? [];
      if (!now.contains(supporterUid) && now.length >= maxSupporters) return 'dashSupFull';
      await ref.update({
        'supporterUids': FieldValue.arrayUnion([supporterUid]),
        'supporters.$supporterUid': {
          'name': info['name'] ?? '',
          'relation': info['relation'] ?? 'other',
          'relationText': info['relationText'] ?? '',
          'approvedAt': FieldValue.serverTimestamp(),
        },
        'supporterRequests.$supporterUid': FieldValue.delete(),
      });
      return null;
    } catch (e) {
      debugPrint('[SupporterService] 승인 실패: $e');
      return 'errNetwork';
    }
  }

  static Future<void> reject(String code, String supporterUid) async {
    try {
      await _db.collection('links').doc(code).update({'supporterRequests.$supporterUid': FieldValue.delete()});
    } catch (e) {
      debugPrint('[SupporterService] 거절 실패: $e');
    }
  }

  // 🆕 [보호자 승인 2026-10-02] 이미 보호자가 있는 아이에 새 보호자가 연결하려면
  // 먼저 연결된 보호자의 승인이 필요함 (가족이 아이 코드로 보호자인 척 들어오는 것을 막음)
  static Future<String?> approveParent(String code, String parentUid) async {
    final ref = _db.collection('links').doc(code);
    try {
      final snap = await ref.get();
      final List<dynamic> now = (snap.data()?['parentUids'] as List?) ?? [];
      if (!now.contains(parentUid) && now.length >= 3) return 'errSupFull';
      await ref.update({
        'parentUids': FieldValue.arrayUnion([parentUid]),
        'parentRequests.$parentUid': FieldValue.delete(),
      });
      return null;
    } catch (e) {
      debugPrint('[SupporterService] 보호자 승인 실패: $e');
      return 'errNetwork';
    }
  }

  static Future<void> rejectParent(String code, String parentUid) async {
    try {
      await _db.collection('links').doc(code).update({'parentRequests.$parentUid': FieldValue.delete()});
    } catch (e) {
      debugPrint('[SupporterService] 보호자 거절 실패: $e');
    }
  }

  static Future<void> remove(String code, String supporterUid) async {
    try {
      await _db.collection('links').doc(code).update({
        'supporterUids': FieldValue.arrayRemove([supporterUid]),
        'supporters.$supporterUid': FieldValue.delete(),
      });
    } catch (e) {
      debugPrint('[SupporterService] 해제 실패: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 아이(학생) 쪽
  // ---------------------------------------------------------------------------

  /// 받은 응원 기록 (보낸 사람·관계·개수) — 아이 화면 카드용
  static Stream<QuerySnapshot<Map<String, dynamic>>> watchGifts(String code) {
    return _db
        .collection('links')
        .doc(code)
        .collection('gifts')
        .orderBy('sentAt', descending: true)
        .limit(200)
        .snapshots();
  }

  /// 응원 가족에게 보여 줄 요약(이번 달 총 공부 시간 + 공부한 날 수)을 올림.
  /// 학생 앱이 학습 통계를 올릴 때 함께 부름 (family_link_service.dart pushStudentStats).
  static Future<void> pushSupportSummary(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final DateTime now = DateTime.now();
      // 30분에 한 번만 올림 (서버 쓰기 비용 절약)
      final String lastKey = 'support_summary_last_${_uid ?? ''}';
      final int last = prefs.getInt(lastKey) ?? 0;
      if (now.millisecondsSinceEpoch - last < const Duration(minutes: 30).inMilliseconds) return;
      await prefs.setInt(lastKey, now.millisecondsSinceEpoch);
      final DateTime monthStart = DateTime(now.year, now.month, 1);
      int minutes = 0;
      final Set<int> days = {};
      for (final key in prefs.getKeys().where((k) => k.startsWith('dke_history_'))) {
        for (final raw in prefs.getStringList(key) ?? const <String>[]) {
          try {
            final Map<String, dynamic> item = jsonDecode(raw);
            final DateTime? ts = DateTime.tryParse(item['timestamp']?.toString() ?? '')?.toLocal();
            if (ts == null || ts.isBefore(monthStart)) continue;
            final int m = (((item['durationSeconds'] as num?)?.toInt() ?? 0) / 60).round();
            if (m <= 0) continue;
            minutes += m;
            days.add(ts.day);
          } catch (_) {}
        }
      }
      final String name = (await DkeUserProfile.getRealName()) ?? '';
      await _db.collection('links').doc(code).collection('supportView').doc('summary').set({
        'studentName': name,
        'monthKey': _monthKey(now),
        'monthMinutes': minutes,
        'monthDays': days.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[SupporterService] 요약 올리기 실패(무시): $e');
    }
  }

  static String _monthKey(DateTime d) => '${d.year}${d.month.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------------
  // 보호자가 보낼 때 고른 관계를 기억 (계정별)
  // ---------------------------------------------------------------------------
  static Future<String> getMyGuardianRelation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('cheer_guardian_relation_${_uid ?? ''}') ?? 'mom';
  }

  static Future<void> setMyGuardianRelation(String relation) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cheer_guardian_relation_${_uid ?? ''}', relation);
  }
}
