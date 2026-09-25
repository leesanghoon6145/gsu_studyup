import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🆕 [빨간 점] 마지막으로 본 시각 저장

// ============================================================================
// 🆕 [2026-09-24] 공지 및 교육상담 전용 서비스 (Firestore 단일 창구)
// - notices   : 공지 (관리자만 쓰기, 로그인 사용자 모두 읽기, 대상=학생/학부모/일반인 여러 개 선택)
// - feedback  : 학생 게시판 / 학부모·일반인 의견함 (본인 + 관리자만 읽기, 댓글은 관리자만)
// - counsels  : 1:1 상담 (본인 + 관리자만 읽기, 댓글은 관리자만)
// 권한은 앱 화면이 아니라 Firestore 보안 규칙(지킴 규칙)에서 최종적으로 막습니다.
// ============================================================================

class NoticeItem {
  final String id;
  final String title;
  final String body;
  final String category; // catImportant / catOperation / catUpdate / catEvent
  // 🆕 [2026-09-24] 공지 대상(여러 개 가능): student / parent / general
  final List<String> audiences;
  final bool pinned;
  final DateTime createdAt;
  final String? prevId; // 🆕 [연재 2026-09-25] 이 공지가 이어지는 "이전 편" 공지 id (없으면 첫 편·단독)

  NoticeItem({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.audiences,
    required this.pinned,
    required this.createdAt,
    this.prevId,
  });

  factory NoticeItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final Map<String, dynamic> m = d.data() ?? {};
    return NoticeItem(
      id: d.id,
      title: (m['title'] as String?) ?? '',
      body: (m['body'] as String?) ?? '',
      category: (m['category'] as String?) ?? 'catOperation',
      audiences: _readAudiences(m),
      pinned: m['pinned'] == true,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      prevId: ((m['prevId'] as String?) ?? '').isEmpty ? null : m['prevId'] as String,
    );
  }
}

// 🆕 공지 대상 읽기 - 새 방식(audiences 목록) 우선, 예전 방식(audience 한 값)도 호환
// 대상 값이 아예 없는 예전 공지는 전체(학생+학부모+일반인)로 처리
const List<String> kAllAudiences = ['student', 'parent', 'general'];

List<String> _readAudiences(Map<String, dynamic> m) {
  final dynamic raw = m['audiences'];
  if (raw is List && raw.isNotEmpty) {
    return raw.map((e) => e.toString()).toList();
  }
  final String? old = m['audience'] as String?;
  if (old == 'student') return ['student'];
  if (old == 'parent') return ['parent'];
  return List<String>.from(kAllAudiences);
}

// 🆕 [2026-09-25] 관리자 댓글 1개 (한 글에 여러 개 달 수 있음)
class PostComment {
  final String text;
  final DateTime createdAt;
  final Map<String, dynamic>? raw; // 삭제할 때 원본 그대로 필요 (예전 방식 답변이면 null)

  PostComment({required this.text, required this.createdAt, this.raw});
}

class PrivatePost {
  final String id;
  final String uid;
  final String role; // parent / student / general
  final String category; // catParent / catStudent / catSuggest / ... / catFeedback
  final String text;
  final List<PostComment> comments; // 🆕 관리자 댓글 목록 (오래된 순)
  final bool edited; // 🆕 글쓴이가 수정한 적 있는지
  final DateTime createdAt;

  PrivatePost({
    required this.id,
    required this.uid,
    required this.role,
    required this.category,
    required this.text,
    required this.comments,
    required this.edited,
    required this.createdAt,
  });

  factory PrivatePost.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final Map<String, dynamic> m = d.data() ?? {};
    return PrivatePost(
      id: d.id,
      uid: (m['uid'] as String?) ?? '',
      role: (m['role'] as String?) ?? 'student',
      category: (m['category'] as String?) ?? 'catFeedback',
      text: (m['text'] as String?) ?? '',
      comments: _readComments(m),
      edited: m['editedAt'] != null,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// 예전 방식(reply 한 개) + 새 방식(replies 목록)을 모두 읽어 날짜순으로 합침
List<PostComment> _readComments(Map<String, dynamic> m) {
  final List<PostComment> list = [];
  final String? old = m['reply'] as String?;
  if (old != null && old.trim().isNotEmpty) {
    list.add(PostComment(
      text: old,
      createdAt: (m['repliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    ));
  }
  final dynamic raw = m['replies'];
  if (raw is List) {
    for (final e in raw) {
      if (e is Map) {
        final Map<String, dynamic> c = Map<String, dynamic>.from(e);
        list.add(PostComment(
          text: (c['text'] as String?) ?? '',
          createdAt: (c['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          raw: c,
        ));
      }
    }
  }
  list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return list;
}

class NoticeCounselService {
  // 🔧 [2026-09-24] 관리자: 상훈님 학부모 계정 1개 (어느 화면에서든 공지 쓰기·모든 답변 가능)
  // Firebase 콘솔 → Authentication → 사용자 목록의 "사용자 UID"를 복사해 넣습니다.
  // Firestore 보안 규칙의 isNoticeAdmin() 목록에도 똑같이 넣어야 합니다.
  // 관리자를 더 늘리려면 이 목록에 줄을 추가하면 됩니다 (규칙에도 똑같이).
  static const List<String> adminUids = [
    'VyEAoAftu6dXAiggrU0806f47et2', // 상훈님 학부모 계정(l2259@naver.com) - 관리자
    // 'QJNpsDXlWnZ27TLse0St3TG7eAs2', // 학생 계정 - 필요하면 앞의 // 를 지우면 관리자로 추가됨
  ];

  static const String noticeCol = 'notices';
  static const String feedbackCol = 'feedback';
  static const String counselCol = 'counsels';

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static String? get myUid => FirebaseAuth.instance.currentUser?.uid;

  static bool get isAdmin {
    final String? u = myUid;
    return u != null && adminUids.contains(u);
  }

  // ---------------------------------------------------------------- 공지
  // 최근 30개만 한 번에 읽어 비용 절약. 고정 공지는 맨 위로.
  // 🆕 [2026-09-24] 대상별 표시: viewer(student/parent/general)가 대상에 들어 있는 공지만
  //                관리자는 어느 화면에서든 전체 공지를 보고 관리할 수 있음
  static Stream<List<NoticeItem>> watchNotices({required String viewer}) {
    final bool admin = isAdmin;
    return _db
        .collection(noticeCol)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) {
      final List<NoticeItem> list = snap.docs
          .map((d) => NoticeItem.fromDoc(d))
          .where((n) => admin || n.audiences.contains(viewer))
          .toList();
      list.sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  static Future<bool> addNotice({
    required String title,
    required String body,
    required String category,
    required List<String> audiences,
    required bool pinned,
    String? prevId, // 🆕 [연재] 이전 편
  }) async {
    try {
      await _db.collection(noticeCol).add({
        if (prevId != null) 'prevId': prevId,
        'title': title,
        'body': body,
        'category': category,
        'audiences': audiences,
        'pinned': pinned,
        'authorUid': myUid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('[NOTICE] addNotice 실패: $e');
      return false;
    }
  }

  // 🆕 [2026-09-25] 공지 수정 (관리자)
  static Future<bool> updateNotice(
      String id, {
        required String title,
        required String body,
        required String category,
        required List<String> audiences,
        required bool pinned,
        String? prevId, // 🆕 [연재] 이전 편 (null이면 연결 해제)
      }) async {
    try {
      await _db.collection(noticeCol).doc(id).update({
        'prevId': prevId ?? FieldValue.delete(),
        'title': title,
        'body': body,
        'category': category,
        'audiences': audiences,
        'pinned': pinned,
        'editedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('[NOTICE] updateNotice 실패: $e');
      return false;
    }
  }

  static Future<bool> deleteNotice(String id) async {
    try {
      await _db.collection(noticeCol).doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('[NOTICE] deleteNotice 실패: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------- 의견함 / 1:1 상담
  // 일반 사용자: 내 글만 (uid 조건) / 관리자: 전체 최근 100개
  // 정렬은 앱에서 해서 Firestore 복합 색인이 필요 없도록 함.
  static Stream<List<PrivatePost>> watchPosts(String collection) {
    final String? uid = myUid;
    if (uid == null) return Stream.value(<PrivatePost>[]);
    Query<Map<String, dynamic>> q = _db.collection(collection);
    if (isAdmin) {
      q = q.orderBy('createdAt', descending: true).limit(100);
    } else {
      q = q.where('uid', isEqualTo: uid).limit(50);
    }
    return q.snapshots().map((snap) {
      final List<PrivatePost> list = snap.docs.map((d) => PrivatePost.fromDoc(d)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  static Future<bool> addPost(
      String collection, {
        required String text,
        required String category,
        required String role,
      }) async {
    final String? uid = myUid;
    if (uid == null) return false;
    try {
      await _db.collection(collection).add({
        'uid': uid,
        'role': role,
        'category': category,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('[COUNSEL] addPost 실패: $e');
      return false;
    }
  }

  // 🆕 [2026-09-25] 글쓴이 본인의 글 수정 (내용·분류만 바꿀 수 있음 - 보안 규칙도 동일하게 제한)
  static Future<bool> updatePost(
      String collection,
      String id, {
        required String text,
        required String category,
      }) async {
    try {
      await _db.collection(collection).doc(id).update({
        'text': text,
        'category': category,
        'editedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('[COUNSEL] updatePost 실패: $e');
      return false;
    }
  }

  // 🆕 [2026-09-25] 관리자 댓글 수정 - 목록 안의 해당 댓글만 글자를 바꾸고 작성 시각은 유지
  static Future<bool> editComment(String collection, String id, PostComment c, String newText) async {
    try {
      final DocumentReference<Map<String, dynamic>> ref = _db.collection(collection).doc(id);
      if (c.raw == null) {
        // 예전 방식 답변(reply 한 개)
        await ref.update({'reply': newText});
        return true;
      }
      await _db.runTransaction((tx) async {
        final DocumentSnapshot<Map<String, dynamic>> snap = await tx.get(ref);
        final List<dynamic> list = List<dynamic>.from((snap.data()?['replies'] as List?) ?? []);
        final int i = list.indexWhere((e) => e is Map && e['text'] == c.raw!['text'] && e['at'] == c.raw!['at']);
        if (i < 0) throw Exception('댓글을 찾지 못함');
        list[i] = {'text': newText, 'at': c.raw!['at']};
        tx.update(ref, {'replies': list});
      });
      return true;
    } catch (e) {
      debugPrint('[COUNSEL] editComment 실패: $e');
      return false;
    }
  }

  // 🆕 [2026-09-25] 관리자 댓글 추가 (여러 번 가능)
  // 목록 안에는 서버시간을 넣을 수 없어서 기기 시간(Timestamp.now)을 사용
  static Future<bool> addComment(String collection, String id, String text) async {
    try {
      await _db.collection(collection).doc(id).update({
        'replies': FieldValue.arrayUnion([
          {'text': text, 'at': Timestamp.now()},
        ]),
        'repliedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('[COUNSEL] addComment 실패: $e');
      return false;
    }
  }

  // 🆕 [2026-09-25] 관리자 댓글 삭제
  static Future<bool> deleteComment(String collection, String id, PostComment c) async {
    try {
      final DocumentReference<Map<String, dynamic>> ref = _db.collection(collection).doc(id);
      if (c.raw != null) {
        await ref.update({'replies': FieldValue.arrayRemove([c.raw])});
      } else {
        // 예전 방식 답변(reply 한 개)
        await ref.update({'reply': FieldValue.delete()});
      }
      return true;
    } catch (e) {
      debugPrint('[COUNSEL] deleteComment 실패: $e');
      return false;
    }
  }

  static Future<bool> deletePost(String collection, String id) async {
    try {
      await _db.collection(collection).doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('[COUNSEL] deletePost 실패: $e');
      return false;
    }
  }

  // ============================================================================
  // 🆕 [빨간 점 2026-09-25] 새 공지·새 답변(학생·학부모·일반인) / 새 글(관리자) 알림
  // 탭마다 "마지막으로 본 시각"을 휴대폰에 저장해 두고, 그 뒤에 생긴 것이 있으면 빨간 점
  //   공지  : 내 대상(학생/학부모/일반인) 공지 중 마지막으로 본 뒤 올라온 것
  //   게시판·의견함 / 교육상담 : 내 글에 마지막으로 본 뒤 달린 원장님 댓글
  //   관리자 : 마지막으로 본 뒤 새로 들어온 글
  // 읽는 양을 줄이려고 공지는 최근 10개, 내 글은 최대 50개, 관리자는 최신 1개만 확인
  // ============================================================================
  static const String kSeenNotice = 'nc_seen_notice';
  static const String kSeenBoard = 'nc_seen_board';
  static const String kSeenCounsel = 'nc_seen_counsel';

  static String _seenKey(String base) => '${base}_${myUid ?? ''}';

  static Future<int> _getSeen(String base) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_seenKey(base)) ?? 0;
  }

  // 그 탭을 열어 보면 "지금 봤다"로 기록 → 빨간 점 사라짐
  static Future<void> markSeen(String base) async {
    if (myUid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seenKey(base), DateTime.now().millisecondsSinceEpoch);
  }

  // 결과: {'notice': true/false, 'board': true/false, 'counsel': true/false}
  static Future<Map<String, bool>> checkUnread({required String viewer}) async {
    final Map<String, bool> result = {'notice': false, 'board': false, 'counsel': false};
    final String? uid = myUid;
    if (uid == null) return result;
    final bool admin = isAdmin;
    try {
      if (!admin) {
        final int seenNotice = await _getSeen(kSeenNotice);
        final QuerySnapshot<Map<String, dynamic>> snap =
        await _db.collection(noticeCol).orderBy('createdAt', descending: true).limit(10).get();
        result['notice'] = snap.docs
            .map((d) => NoticeItem.fromDoc(d))
            .any((n) => n.audiences.contains(viewer) && n.createdAt.millisecondsSinceEpoch > seenNotice);
      }
      result['board'] = await _hasNewIn(feedbackCol, await _getSeen(kSeenBoard), admin, uid);
      if (viewer != 'general') {
        result['counsel'] = await _hasNewIn(counselCol, await _getSeen(kSeenCounsel), admin, uid);
      }
    } catch (e) {
      debugPrint('[NOTICE] checkUnread 실패(빨간 점만 안 보임): $e');
    }
    return result;
  }

  static Future<bool> _hasNewIn(String collection, int seenMs, bool admin, String uid) async {
    if (admin) {
      final QuerySnapshot<Map<String, dynamic>> snap =
      await _db.collection(collection).orderBy('createdAt', descending: true).limit(1).get();
      if (snap.docs.isEmpty) return false;
      final Timestamp? ts = snap.docs.first.data()['createdAt'] as Timestamp?;
      return ts != null && ts.millisecondsSinceEpoch > seenMs;
    }
    final QuerySnapshot<Map<String, dynamic>> snap =
    await _db.collection(collection).where('uid', isEqualTo: uid).limit(50).get();
    for (final d in snap.docs) {
      final Timestamp? ts = d.data()['repliedAt'] as Timestamp?;
      if (ts != null && ts.millisecondsSinceEpoch > seenMs) return true;
    }
    return false;
  }
}
