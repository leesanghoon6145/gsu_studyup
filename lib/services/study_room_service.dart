// lib/services/study_room_service.dart
//
// 🆕 [2026-10-11] 친구 학습방 — 가상 방 · 가상 학생 모두 삭제, 서버에 진짜 방을 만들고 함께 들어감
// - studyRooms/{방}: 방 이름 · 최대 인원 · 비밀번호(암호 이름표) · 만든 사람 · 참여 학생 목록
// - cheers/{응원}: 방 안에서 친구에게 보낸 👍 🔥 응원 (오늘 것만 보여 줌)
// - 🆕 [2026-10-11 수정] 아무도 없는 방은 24시간 동안 그대로 남고(예전 10분 → 너무 빨리 사라져서 변경),
//   24시간 동안 아무도 들어오지 않으면 목록에서 사라지고 만든 사람이 목록을 열 때 정리됨

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'presence_service.dart';

/// 🆕 [함께 공부 2026-10-11] 방장이 정한 함께 공부 (과목 · 시간 · 시험 · 백색소음)
class GroupSession {
  final String id;
  final String subject;
  final int minutes;
  final String examTitle;
  final String sound;
  final String mode; // 🆕 학사 모드: normal · vacation · examBefore · examDuring
  final String hostUid;
  final String hostName;
  final DateTime startAt;
  final DateTime endAt;

  const GroupSession({
    required this.id,
    required this.subject,
    required this.minutes,
    required this.examTitle,
    required this.sound,
    this.mode = 'normal',
    required this.hostUid,
    required this.hostName,
    required this.startAt,
    required this.endAt,
  });

  static GroupSession? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final Timestamp? st = raw['startAt'] as Timestamp?;
    final Timestamp? en = raw['endAt'] as Timestamp?;
    if (st == null || en == null) return null;
    return GroupSession(
      id: (raw['id'] as String?) ?? '${st.millisecondsSinceEpoch}',
      subject: (raw['subject'] as String?) ?? '',
      minutes: (raw['minutes'] as num?)?.toInt() ?? 50,
      examTitle: (raw['examTitle'] as String?) ?? '',
      sound: (raw['sound'] as String?) ?? '',
      mode: (raw['mode'] as String?) ?? 'normal',
      hostUid: (raw['hostUid'] as String?) ?? '',
      hostName: (raw['hostName'] as String?) ?? '',
      startAt: st.toDate(),
      endAt: en.toDate(),
    );
  }

  bool get isActive => DateTime.now().isBefore(endAt);
  bool get isToday {
    final DateTime n = DateTime.now();
    return startAt.year == n.year && startAt.month == n.month && startAt.day == n.day;
  }

  /// 지금 같이 시작하면 남은 분 (방장과 같이 끝나도록)
  int get remainingMinutes {
    final int sec = endAt.difference(DateTime.now()).inSeconds;
    return sec <= 0 ? 0 : (sec / 60).ceil();
  }
}

class StudyRoom {
  final String id;
  final String title;
  final int maxUsers;
  final bool hasPassword;
  final String pwHash;
  final String creatorUid;
  final List<String> members;
  final DateTime? lastActive;
  final GroupSession? session;

  const StudyRoom({
    required this.id,
    required this.title,
    required this.maxUsers,
    required this.hasPassword,
    required this.pwHash,
    required this.creatorUid,
    required this.members,
    required this.lastActive,
    this.session,
  });

  factory StudyRoom.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final Map<String, dynamic> m = d.data() ?? {};
    return StudyRoom(
      id: d.id,
      title: (m['title'] as String?) ?? '',
      maxUsers: (m['maxUsers'] as num?)?.toInt() ?? 5,
      hasPassword: m['hasPassword'] == true,
      pwHash: (m['pwHash'] as String?) ?? '',
      creatorUid: (m['creatorUid'] as String?) ?? '',
      members: ((m['members'] as List?) ?? []).map((e) => e.toString()).toList(),
      lastActive: (m['lastActive'] as Timestamp?)?.toDate(),
      session: GroupSession.fromMap(m['session']),
    );
  }

  // 🆕 [버그 수정 2026-10-11] 방을 막 만든 순간에는 서버 시간(lastActive)이 아직 비어 있어
  // "오래된 빈 방"으로 잘못 보고 지워 버리던 문제 → 시간이 확인된 빈 방만 10분 뒤 정리
  bool get isEmptyAndStale =>
      members.isEmpty && lastActive != null && DateTime.now().difference(lastActive!) > emptyRoomLife;

  /// 🆕 [2026-10-11] 빈 방을 남겨 두는 시간 (예전 10분 → 24시간)
  static const Duration emptyRoomLife = Duration(hours: 24);
}

class CheerItem {
  final String to;
  final String from;
  final String fromName;
  final String emoji;
  const CheerItem(this.to, this.from, this.fromName, this.emoji);
}

class StudyRoomService {
  StudyRoomService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _rooms = 'studyRooms';
  static const String _cheers = 'cheers';
  static const int minUsers = 2;
  static const int maxUsersLimit = 10;
  static String lastError = ''; // 🆕 [2026-10-11] 실패 이유를 화면에 보여 주기 위함

  static String hashPw(String pw) {
    int h = 0x811c9dc5;
    for (final int c in utf8.encode('gke|$pw')) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16);
  }

  /// 방 목록 (최근에 움직인 순). 빈 지 24시간 넘은 방은 숨기고, 내가 만든 방이면 지움
  static Stream<List<StudyRoom>> watchRooms() {
    final String? me = PresenceService.myUid;
    return _db.collection(_rooms).orderBy('lastActive', descending: true).limit(40).snapshots().map((snap) {
      final List<StudyRoom> out = [];
      for (final d in snap.docs) {
        final StudyRoom r = StudyRoom.fromDoc(d);
        if (r.isEmptyAndStale) {
          if (r.creatorUid == me) deleteRoom(r.id);
          continue;
        }
        out.add(r);
      }
      return out;
    });
  }

  static Stream<StudyRoom?> watchRoom(String id) {
    return _db.collection(_rooms).doc(id).snapshots().map((d) => d.exists ? StudyRoom.fromDoc(d) : null);
  }

  static Future<String?> createRoom({required String title, required int maxUsers, required String password}) async {
    final String? me = PresenceService.myUid;
    if (me == null) {
      lastError = 'not-logged-in';
      return null;
    }
    try {
      final ref = await _db.collection(_rooms).add({
        'title': title,
        'maxUsers': maxUsers.clamp(minUsers, maxUsersLimit),
        'hasPassword': password.isNotEmpty,
        'pwHash': password.isEmpty ? '' : hashPw(password),
        'creatorUid': me,
        'members': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (e) {
      debugPrint('[StudyRoom] 방 만들기 실패: $e');
      lastError = e is FirebaseException ? e.code : e.toString();
      return null;
    }
  }

  static Future<bool> join(String id) async {
    final String? me = PresenceService.myUid;
    if (me == null) return false;
    try {
      await _db.collection(_rooms).doc(id).update({
        'members': FieldValue.arrayUnion([me]),
        'lastActive': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('[StudyRoom] 입장 실패: $e');
      return false;
    }
  }

  static Future<void> leave(String id) async {
    final String? me = PresenceService.myUid;
    if (me == null) return;
    try {
      await _db.collection(_rooms).doc(id).update({
        'members': FieldValue.arrayRemove([me]),
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[StudyRoom] 나가기 실패: $e');
    }
  }

  /// 🆕 [함께 공부] 방장이 함께 공부를 시작 (방 문서에 기록 → 다른 학생 화면에 팝업)
  static Future<bool> startSession(
      String roomId, {
        required String subject,
        required int minutes,
        required String examTitle,
        required String sound,
        String mode = 'normal',
      }) async {
    final String? me = PresenceService.myUid;
    if (me == null) return false;
    final DateTime now = DateTime.now();
    try {
      await _db.collection(_rooms).doc(roomId).update({
        'session': {
          'id': '${now.millisecondsSinceEpoch}',
          'subject': subject,
          'minutes': minutes,
          'examTitle': examTitle,
          'sound': sound,
          'mode': mode,
          'hostUid': me,
          'hostName': PresenceService.myName,
          'startAt': Timestamp.fromDate(now),
          'endAt': Timestamp.fromDate(now.add(Duration(minutes: minutes))),
        },
        'lastActive': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('[StudyRoom] 함께 공부 시작 실패: $e');
      lastError = e is FirebaseException ? e.code : e.toString();
      return false;
    }
  }

  static Future<bool> deleteRoom(String id) async {
    try {
      await _db.collection(_rooms).doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('[StudyRoom] 방 삭제 실패: $e');
      return false;
    }
  }

  static Future<bool> sendCheer({required String to, required String emoji}) async {
    final String? me = PresenceService.myUid;
    if (me == null || to == me) return false;
    try {
      await _db.collection(_cheers).add({
        'to': to,
        'from': me,
        'fromName': PresenceService.myName,
        'emoji': emoji,
        'dateKey': PresenceService.dateKey(DateTime.now()),
        'at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('[StudyRoom] 응원 보내기 실패: $e');
      return false;
    }
  }

  /// 오늘 이 학생들이 받은 응원 (받는 사람별로 묶음)
  static Future<Map<String, List<CheerItem>>> fetchTodayCheers(List<String> uids) async {
    final Map<String, List<CheerItem>> out = {};
    if (uids.isEmpty) return out;
    final String dk = PresenceService.dateKey(DateTime.now());
    try {
      for (int i = 0; i < uids.length; i += 10) {
        final List<String> part = uids.sublist(i, (i + 10).clamp(0, uids.length));
        final snap = await _db
            .collection(_cheers)
            .where('dateKey', isEqualTo: dk)
            .where('to', whereIn: part)
            .limit(200)
            .get();
        for (final d in snap.docs) {
          final Map<String, dynamic> m = d.data();
          final CheerItem c = CheerItem(
            (m['to'] as String?) ?? '',
            (m['from'] as String?) ?? '',
            (m['fromName'] as String?) ?? '',
            (m['emoji'] as String?) ?? '👍',
          );
          out.putIfAbsent(c.to, () => []).add(c);
        }
      }
    } catch (e) {
      debugPrint('[StudyRoom] 응원 읽기 실패: $e');
    }
    return out;
  }

  // ==========================================================================
  // 🆕 [초대 2026-10-11] 방장이 친구를 초대 → 친구 폰에 팝업 → 수락하면 바로 입장
  // roomInvites/{보낸사람uid_받는사람uid}: 한 친구에게 초대는 한 장만 (새로 보내면 덮어씀)
  // 10분이 지나면 저절로 무시, 거절한 친구는 1시간 동안 다시 초대 못 함
  // ==========================================================================
  static const String _invites = 'roomInvites';
  static const Duration inviteLife = Duration(minutes: 10);
  static const Duration declineCooldown = Duration(hours: 1);

  /// 'ok' · 'cooldown' · 'error'
  static Future<String> sendInvite({required String to, required String roomId, required String roomTitle}) async {
    final String? me = PresenceService.myUid;
    if (me == null || to == me) return 'error';
    final DocumentReference<Map<String, dynamic>> ref = _db.collection(_invites).doc('${me}_$to');
    try {
      final snap = await ref.get();
      final Map<String, dynamic>? old = snap.data();
      if (old != null && old['status'] == 'declined') {
        final DateTime? at = (old['answeredAt'] as Timestamp?)?.toDate();
        if (at != null && DateTime.now().difference(at) < declineCooldown) return 'cooldown';
      }
    } catch (_) {}
    try {
      final DateTime now = DateTime.now();
      await ref.set({
        'from': me,
        'fromName': PresenceService.myName,
        'to': to,
        'roomId': roomId,
        'roomTitle': roomTitle,
        'status': 'pending',
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(now.add(inviteLife)),
      });
      return 'ok';
    } catch (e) {
      debugPrint('[StudyRoom] 초대 보내기 실패: $e');
      lastError = e is FirebaseException ? e.code : e.toString();
      return 'error';
    }
  }

  /// 나에게 온 기다리는 초대 (실시간)
  static Stream<List<RoomInvite>> watchMyInvites() {
    final String? me = PresenceService.myUid;
    if (me == null) return const Stream.empty();
    return _db
        .collection(_invites)
        .where('to', isEqualTo: me)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map(RoomInvite.fromDoc).where((i) => i.isValid).toList());
  }

  static Future<void> answerInvite(String inviteId, bool accept) async {
    try {
      await _db.collection(_invites).doc(inviteId).update({
        'status': accept ? 'accepted' : 'declined',
        'answeredAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[StudyRoom] 초대 답하기 실패: $e');
    }
  }

  static Future<StudyRoom?> getRoom(String id) async {
    try {
      final d = await _db.collection(_rooms).doc(id).get();
      return d.exists ? StudyRoom.fromDoc(d) : null;
    } catch (_) {
      return null;
    }
  }
}

class RoomInvite {
  final String id;
  final String from;
  final String fromName;
  final String roomId;
  final String roomTitle;
  final DateTime? expiresAt;
  const RoomInvite(this.id, this.from, this.fromName, this.roomId, this.roomTitle, this.expiresAt);

  factory RoomInvite.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final Map<String, dynamic> m = d.data() ?? {};
    return RoomInvite(
      d.id,
      (m['from'] as String?) ?? '',
      (m['fromName'] as String?) ?? '',
      (m['roomId'] as String?) ?? '',
      (m['roomTitle'] as String?) ?? '',
      (m['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  bool get isValid => roomId.isNotEmpty && expiresAt != null && DateTime.now().isBefore(expiresAt!);
}
