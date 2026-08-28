import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🆕 [본인 데이터만 접근] 소유자 확인용
import 'package:shared_preferences/shared_preferences.dart';

// 학생↔부모 기기 연결을 담당하는 서비스
// (다른 서비스들과 동일하게 "단일 게이트웨이" 패턴 — 이 파일만 Firestore와 직접 통신)
class FamilyLinkService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'links';
  static const String _kMyLinkCodeKey = 'family_link_code'; // 내 기기에 저장해둘 연결 코드

  // [학생] 6자리 코드를 새로 만들어서 Firestore에 등록하고, 내 기기에도 저장(자동 동기화용)
  static Future<String> generateLinkCode() async {
    final String code = (100000 + Random().nextInt(900000)).toString();
    final String? myUid = FirebaseAuth.instance.currentUser?.uid;
    await _db.collection(_collection).doc(code).set({
      'status': 'waiting', // waiting → connected
      'ownerUid': myUid, // 🆕 [본인 데이터만 접근] 이 데이터의 진짜 주인(학생) uid
      'parentUids': <String>[], // 🆕 [본인 데이터만 접근] 연결 허용된 부모 uid 목록
      'createdAt': FieldValue.serverTimestamp(),
    });
    await saveMyLinkCode(code);
    return code;
  }

  // 🆕 [부모] 연결된 자녀 코드 목록 (최대 5명)
  static const String _kMyLinkedCodesKey = 'family_linked_codes';
  static const int maxChildren = 5;

  static Future<List<String>> getLinkedCodes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kMyLinkedCodesKey) ?? [];
  }

  // 부모 쪽에서 자녀 코드를 목록에 추가. 이미 5명이면 false 반환(추가 실패)
  static Future<bool> addLinkedCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kMyLinkedCodesKey) ?? [];
    if (list.contains(code)) return true; // 이미 등록된 코드면 그냥 성공 처리
    if (list.length >= maxChildren) return false; // 5명 초과
    list.add(code);
    await prefs.setStringList(_kMyLinkedCodesKey, list);
    return true;
  }

  static Future<void> removeLinkedCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kMyLinkedCodesKey) ?? [];
    list.remove(code);
    await prefs.setStringList(_kMyLinkedCodesKey, list);
  }

  // [부모] 코드를 입력해서 연결 시도. 성공하면 true 반환 (내 자녀 목록에도 자동 추가)
  static Future<bool> connectWithCode(String code) async {
    final String? myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return false; // 로그인 안 된 상태면 연결 불가 (본인 확인 불가능)

    final docRef = _db.collection(_collection).doc(code);
    final doc = await docRef.get();
    if (!doc.exists) {
      return false; // 존재하지 않는 코드
    }
    await docRef.update({
      'status': 'connected',
      'connectedAt': FieldValue.serverTimestamp(),
      'parentUids': FieldValue.arrayUnion([myUid]), // 🆕 [본인 데이터만 접근] 나를 허용 목록에 추가
    });
    await addLinkedCode(code);
    return true;
  }

  // 🆕 [학생] 내 기기에 연결 코드를 저장 (앱 재시작해도 유지됨)
  static Future<void> saveMyLinkCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMyLinkCodeKey, code);
  }

  // 🆕 [학생] 저장된 내 연결 코드 조회 (없으면 null — 아직 연결 안 한 상태)
  static Future<String?> getMyLinkCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kMyLinkCodeKey);
  }

  // 🆕 [동기화 주기 설정] 3분에 한 번만 서버로 전송 (서버 부담 최소화, 회원 늘어나면 재조정 예정)
  static const Duration _pushInterval = Duration(minutes: 3);
  static const String _kLastPushKey = 'family_link_last_push_ms';

  // 🆕 [학생→서버] 실제 학습 데이터(별/레벨)를 Firestore에 올림.
  // DkeStars.addStars()가 호출될 때마다 자동으로 이 함수가 실행됨.
  // 단, 마지막 전송 후 5분이 안 지났으면 이번엔 조용히 건너뜀 (로컬 저장은 이미 끝난 상태라 데이터 유실 없음).
  static Future<void> pushStudentStats({
    required int totalStars,
    required int todayStars,
    required int level,
  }) async {
    final code = await getMyLinkCode();
    if (code == null) return; // 아직 부모와 연결 안 됐으면 그냥 조용히 넘어감

    final prefs = await SharedPreferences.getInstance();
    final int lastPushMs = prefs.getInt(_kLastPushKey) ?? 0;
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - lastPushMs < _pushInterval.inMilliseconds) {
      return; // 5분 안 지났으면 이번 전송은 건너뜀
    }

    await _db.collection(_collection).doc(code).set({
      'totalStars': totalStars,
      'todayStars': todayStars,
      'level': level,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await prefs.setInt(_kLastPushKey, nowMs);
  }

  // [테스트용, 유지] 학생이 임의 메시지를 Firestore에 저장
  static Future<void> sendTestMessage(String code, String message) async {
    await _db.collection(_collection).doc(code).update({
      'testMessage': message,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // [부모] 해당 코드 문서를 실시간으로 구독 (연결 상태 + 학습 데이터 모두 여기서 흘러나옴)
  static Stream<DocumentSnapshot<Map<String, dynamic>>> watch(String code) {
    return _db.collection(_collection).doc(code).snapshots();
  }
}
