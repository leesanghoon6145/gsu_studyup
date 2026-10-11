// lib/services/presence_service.dart
//
// 🆕 [2026-10-11] 동시 접속자 · 친구 학습방을 "진짜 사람"으로 보여 주기 위한 접속 기록
// - 학생 계정만 presence/{내 uid} 문서 1개를 가짐 (학부모·일반인은 기록 안 함)
// - 공부 중이면 타이머가 이미 보내는 신호(FamilyLinkService.pushLiveStudyStatus)에 얹혀서
//   5분에 한 번만 서버에 씀 (공부 시작·멈춤 순간은 바로 씀) → 타이머 파일은 전혀 안 건드림
// - 화면은 5분마다 한 번 새로 셈 (실시간 구독이 아니라 비용이 적음)
// - 서버에 올라가는 것: 이름 · 학교 · 학년 이름표(암호) · 공부 중 여부 · 과목 · 오늘 공부 시간 ·
//   레벨 · 별 · 목표 · 교과별 오늘 공부 시간. 연락처 · 성적은 절대 올라가지 않음.

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../star_economy.dart';
import 'user_profile_service.dart';
import 'subject_category.dart';

class PresenceInfo {
  final String uid;
  final String name;
  final String school;
  final bool studying;
  final String subject;
  final int todayMinutes;
  final int level;
  final int totalStars;
  final String target;
  final String dateKey;
  final DateTime? lastSeen;

  const PresenceInfo({
    required this.uid,
    required this.name,
    required this.school,
    required this.studying,
    required this.subject,
    required this.todayMinutes,
    required this.level,
    required this.totalStars,
    required this.target,
    required this.dateKey,
    required this.lastSeen,
  });

  factory PresenceInfo.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final Map<String, dynamic> m = d.data() ?? {};
    final Timestamp? until = m['studyingUntil'] as Timestamp?;
    final bool nowStudying = (m['studying'] == true) && until != null && until.toDate().isAfter(DateTime.now());
    final String dk = (m['dateKey'] as String?) ?? '';
    final bool today = dk == PresenceService.dateKey(DateTime.now());
    return PresenceInfo(
      uid: d.id,
      name: (m['name'] as String?) ?? '',
      school: (m['school'] as String?) ?? '',
      studying: nowStudying,
      subject: (m['subject'] as String?) ?? '',
      todayMinutes: today ? ((m['todayMinutes'] as num?)?.toInt() ?? 0) : 0,
      level: (m['level'] as num?)?.toInt() ?? 1,
      totalStars: (m['totalStars'] as num?)?.toInt() ?? 0,
      target: (m['target'] as String?) ?? '',
      dateKey: dk,
      lastSeen: (m['lastSeen'] as Timestamp?)?.toDate(),
    );
  }
}

class PresenceStats {
  final int online; // 최근 10분 안에 접속
  final int studying; // 지금 공부 중
  final int studentsToday; // 오늘 공부한 학생
  final int minutesToday; // 오늘 전체 공부 시간(분)
  final int goalToday; // 오늘 50분 이상 공부한 학생
  final List<int> categoryMinutes; // 12개 교과별 오늘 공부 시간(분)
  const PresenceStats({
    required this.online,
    required this.studying,
    required this.studentsToday,
    required this.minutesToday,
    required this.goalToday,
    required this.categoryMinutes,
  });
}

class PresenceService {
  PresenceService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String col = 'presence';
  // 오늘 통계용 하루 기록: presenceDaily/{날짜}/users/{uid} (색인 추가 설정 없이 합계를 내려고 날짜별로 나눔)
  static const String dailyCol = 'presenceDaily';
  static const Duration beatInterval = Duration(minutes: 5);
  static const Duration onlineWindow = Duration(minutes: 10);
  static const int goalMinutes = 50;

  // 내 정보 (앱이 켜져 있는 동안 한 번만 서버에서 읽음)
  static String? _cachedUid;
  static bool _profileLoaded = false;
  static bool _isStudent = false;
  static String _name = '';
  static String _school = '';
  static String _grade = '';

  static bool _lastStudying = false;
  static String _lastSubject = '';
  static int _lastBeatMs = 0;

  static String get myName => _name;
  /// 🆕 [초대 2026-10-11] 지금 타이머로 공부 중인지 (공부 중에는 초대 팝업을 미룸)
  static bool get isStudyingNow => _lastStudying;
  static String get mySchool => _school;
  static String? get myUid => FirebaseAuth.instance.currentUser?.uid;

  static String dateKey(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  // ranking_service.dart 와 같은 방식의 "학교·학년 암호 이름표"
  static String groupKeyOf(String school, String grade) {
    if (school.trim().isEmpty || grade.trim().isEmpty) return '';
    final String s = '${school.replaceAll(' ', '').toLowerCase()}|${grade.replaceAll(' ', '')}';
    int h = 0x811c9dc5;
    for (final int c in utf8.encode(s)) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16);
  }

  static String get myGroupKey => groupKeyOf(_school, _grade);

  /// 내 프로필을 한 번 읽어 둠. 학생이면 true
  static Future<bool> loadProfile() async {
    final String? uid = myUid;
    if (uid == null) return false;
    if (_profileLoaded && _cachedUid == uid) return _isStudent;
    try {
      final String type = (await DkeUserProfile.getUserType()) ?? '';
      _isStudent = type == '학생' || type.toLowerCase() == 'student';
      _name = (await DkeUserProfile.getRealName()) ?? '';
      _school = (await DkeUserProfile.getSchoolName()) ?? '';
      _grade = (await DkeUserProfile.getGrade()) ?? '';
      _cachedUid = uid;
      _profileLoaded = true;
      _lastStudying = false;
      _lastBeatMs = 0;
    } catch (e) {
      debugPrint('[Presence] 프로필 읽기 실패: $e');
    }
    return _isStudent;
  }

  // 오늘 교과별 공부 시간: 과목별 누적 별(1분 = 1개)이 오늘 아침 기준값에서 얼마나 늘었는지로 계산
  static Future<Map<String, int>> _todayCategoryMinutes(SharedPreferences prefs, String uid) async {
    const String prefix = 'stars_subject_';
    final String suffix = '_$uid';
    final List<int> cur = List<int>.filled(kSubjectCategories.length, 0);
    for (final String k in prefs.getKeys()) {
      if (!k.startsWith(prefix) || !k.endsWith(suffix)) continue;
      final String subject = k.substring(prefix.length, k.length - suffix.length);
      final int idx = kSubjectCategories.indexOf(subjectCategoryOf(subject));
      cur[idx < 0 ? kSubjectCategories.length - 1 : idx] += prefs.getInt(k) ?? 0;
    }
    final String baseKey = 'presence_subj_base_$uid';
    final String today = dateKey(DateTime.now());
    List<int> base = cur;
    try {
      final String? raw = prefs.getString(baseKey);
      final Map<String, dynamic>? saved = raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
      if (saved != null && saved['date'] == today) {
        base = (saved['base'] as List).map((e) => (e as num).toInt()).toList();
      } else {
        await prefs.setString(baseKey, jsonEncode({'date': today, 'base': cur}));
      }
    } catch (_) {}
    final Map<String, int> out = {};
    for (int i = 0; i < cur.length; i++) {
      final int b = i < base.length ? base[i] : 0;
      final int v = cur[i] - b;
      if (v > 0) out['c$i'] = v;
    }
    return out;
  }

  /// 접속 신호 보내기. 5분에 한 번만 서버에 씀 (공부 시작 · 멈춤은 바로)
  static Future<void> beat({bool? studying, String? subject, bool force = false}) async {
    final String? uid = myUid;
    if (uid == null) return;
    if (!await loadProfile()) return; // 학생만
    bool changed = false;
    if (studying != null) {
      changed = studying != _lastStudying;
      _lastStudying = studying;
    }
    if (subject != null && subject.isNotEmpty) _lastSubject = subject;
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    if (!force && !changed && nowMs - _lastBeatMs < beatInterval.inMilliseconds) return;
    _lastBeatMs = nowMs;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int todayMin = await DkeStars.getTodayStars();
      final int total = await DkeStars.getTotalStars();
      final String target = prefs.getString('saved_target_university') ?? '';
      final Map<String, int> sc = await _todayCategoryMinutes(prefs, uid);
      final DateTime now = DateTime.now();
      final String dk = dateKey(now);
      await _db.collection(col).doc(uid).set({
        'name': _name,
        'school': _school,
        'groupKey': myGroupKey,
        'studying': _lastStudying,
        'subject': _lastStudying ? _lastSubject : '',
        'studyingUntil': _lastStudying
            ? Timestamp.fromDate(now.add(onlineWindow))
            : Timestamp.fromMillisecondsSinceEpoch(0),
        'lastSeen': FieldValue.serverTimestamp(),
        'dateKey': dk,
        'todayMinutes': todayMin,
        'goalHit': todayMin >= goalMinutes,
        'level': DkeStars.levelForStars(total),
        'totalStars': total,
        'target': target,
        'rankScore': int.parse(dk) * 100000 + todayMin.clamp(0, 99999),
        'sc': sc,
      });
      await _db.collection(dailyCol).doc(dk).collection('users').doc(uid).set({
        'todayMinutes': todayMin,
        'goalHit': todayMin >= goalMinutes,
        'sc': sc,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Presence] 접속 신호 실패(다음에 다시 시도): $e');
      _lastBeatMs = 0;
    }
  }

  // ---------------------------------------------------------------- 읽기 (5분마다)

  /// 접속 중 · 공부 중 · 오늘 통계 · 교과별 비율
  static Future<PresenceStats> fetchStats() async {
    final DateTime now = DateTime.now();
    final CollectionReference<Map<String, dynamic>> c = _db.collection(col);
    final String dk = dateKey(now);
    int online = 0, studyingN = 0, students = 0, minutes = 0, goal = 0;
    final List<int> cats = List<int>.filled(kSubjectCategories.length, 0);
    try {
      final a = await c.where('lastSeen', isGreaterThanOrEqualTo: Timestamp.fromDate(now.subtract(onlineWindow))).count().get();
      online = a.count ?? 0;
    } catch (e) {
      debugPrint('[Presence] 접속 수 실패: $e');
    }
    try {
      final a = await c.where('studyingUntil', isGreaterThanOrEqualTo: Timestamp.fromDate(now)).count().get();
      studyingN = a.count ?? 0;
    } catch (e) {
      debugPrint('[Presence] 공부 중 수 실패: $e');
    }
    final CollectionReference<Map<String, dynamic>> todayQ = _db.collection(dailyCol).doc(dk).collection('users');
    try {
      final a = await todayQ.aggregate(count(), sum('todayMinutes')).get();
      students = a.count ?? 0;
      minutes = (a.getSum('todayMinutes') ?? 0).round();
    } catch (e) {
      debugPrint('[Presence] 오늘 통계 실패: $e');
    }
    try {
      final a = await todayQ.where('goalHit', isEqualTo: true).count().get();
      goal = a.count ?? 0;
    } catch (e) {
      debugPrint('[Presence] 목표 달성 수 실패: $e');
    }
    // 교과 12개 → 4개씩 3번 나눠 합계 (한 번에 최대 5개까지라서)
    for (int start = 0; start < cats.length; start += 4) {
      try {
        final List<String> f = [for (int i = start; i < start + 4 && i < cats.length; i++) 'sc.c$i'];
        final a = await todayQ
            .aggregate(
          sum(f[0]),
          f.length > 1 ? sum(f[1]) : null,
          f.length > 2 ? sum(f[2]) : null,
          f.length > 3 ? sum(f[3]) : null,
        )
            .get();
        for (int j = 0; j < f.length; j++) {
          cats[start + j] = (a.getSum(f[j]) ?? 0).round();
        }
      } catch (e) {
        debugPrint('[Presence] 교과 합계 실패: $e');
      }
    }
    return PresenceStats(
      online: online,
      studying: studyingN,
      studentsToday: students,
      minutesToday: minutes,
      goalToday: goal,
      categoryMinutes: cats,
    );
  }

  /// 같은 학교 · 같은 학년 친구 (나는 빼고). 공부 중 → 오늘 많이 한 순
  static Future<List<PresenceInfo>> fetchFriends() async {
    await loadProfile();
    final String g = myGroupKey;
    if (g.isEmpty) return [];
    try {
      final snap = await _db.collection(col).where('groupKey', isEqualTo: g).limit(60).get();
      final List<PresenceInfo> list =
      snap.docs.where((d) => d.id != myUid).map(PresenceInfo.fromDoc).toList();
      list.sort((a, b) {
        if (a.studying != b.studying) return a.studying ? -1 : 1;
        return b.todayMinutes.compareTo(a.todayMinutes);
      });
      return list;
    } catch (e) {
      debugPrint('[Presence] 친구 목록 실패: $e');
      return [];
    }
  }

  /// 오늘 공부 시간 상위 학생들 (랭킹 · 인기 목표 · 성취 알림에 씀)
  static Future<List<PresenceInfo>> fetchTodayTop({int limit = 50}) async {
    final String dk = dateKey(DateTime.now());
    try {
      final snap = await _db.collection(col).orderBy('rankScore', descending: true).limit(limit).get();
      return snap.docs.map(PresenceInfo.fromDoc).where((p) => p.dateKey == dk && p.todayMinutes > 0).toList();
    } catch (e) {
      debugPrint('[Presence] 오늘 상위 학생 실패: $e');
      return [];
    }
  }

  /// 여러 학생 정보 한꺼번에 (친구 학습방 참여 학생)
  static Future<List<PresenceInfo>> fetchMany(List<String> uids) async {
    if (uids.isEmpty) return [];
    final List<PresenceInfo> out = [];
    try {
      for (int i = 0; i < uids.length; i += 10) {
        final List<String> part = uids.sublist(i, (i + 10).clamp(0, uids.length));
        final snap = await _db.collection(col).where(FieldPath.documentId, whereIn: part).get();
        out.addAll(snap.docs.map(PresenceInfo.fromDoc));
      }
    } catch (e) {
      debugPrint('[Presence] 학생 정보 실패: $e');
    }
    return out;
  }

  /// 이름 가리기 (전체 랭킹 · 알림용): 김철수 → 김○○ / Emma → E***
  static String maskName(String name) {
    final String n = name.trim();
    if (n.isEmpty) return '○○○';
    final String first = String.fromCharCode(n.runes.first);
    final bool latin = RegExp(r'^[A-Za-z]').hasMatch(first);
    return latin ? '$first***' : '$first○○';
  }
}
