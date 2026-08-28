import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// 🆕 [실사용 전환 인프라] 2026-07-29 신규 생성 — 회원 프로필 "창구" 서비스
// -----------------------------------------------------------------------------
// 🚨 [2026-08-28 버그 수정] 예전에는 이 정보를 "폰 하나"에 공용으로 저장해서,
// 같은 폰에서 학생/학부모/일반 계정을 각각 가입하면 서로의 정보를 덮어써버리는
// 심각한 문제가 있었습니다 (마지막에 가입한 유형으로 전부 고정되는 현상).
//
// 지금부터는 이 정보를 "로그인한 계정(uid) 하나하나"에 정확히 묶어서 Firestore에
// 저장합니다. 즉, 같은 폰이라도 로그인한 계정이 다르면 서로 다른 유형/이름이
// 정확히 구분되어 불러와집니다.
// =============================================================================

class DkeUserProfile {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'userProfiles';

  // 로컬 캐시 키 (오프라인 등 즉시 응답이 필요할 때 마지막으로 불러온 값을 잠깐 보여주는 용도)
  static const String _kCachedUserTypeKey = 'dke_user_type_cache';
  static const String _kCachedNameKey = 'dke_user_real_name_cache';

  // ===========================================================================
  // 1) 가입 완료 시점에 실제 입력한 이름/유형/연동 정보를 저장.
  //    🆕 이제 "이 계정(uid)"에 정확히 묶어서 Firestore에 저장합니다.
  // ===========================================================================
  static Future<void> saveProfileOnSignup({
    required String realName,
    required String userType, // '학생' / '학부모' / '일반'
    String? childEmail,
    String? parentEmail,
  }) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return; // 계정 생성이 안 된 상태면 저장할 곳이 없음

    try {
      await _db.collection(_collection).doc(uid).set({
        'realName': realName,
        'userType': userType,
        if (childEmail != null && childEmail.isNotEmpty) 'childEmail': childEmail,
        if (parentEmail != null && parentEmail.isNotEmpty) 'parentEmail': parentEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 로컬 캐시도 함께 갱신 (다음 실행 시 잠깐 보여줄 용도)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCachedUserTypeKey, userType);
      await prefs.setString(_kCachedNameKey, realName);
    } catch (e) {
      // 저장 실패해도 앱 흐름을 막지 않음
    }
  }

  // ===========================================================================
  // 2) 현재 로그인된 계정(uid)의 실제 이름 조회 — Firestore에서 정확히 그 계정 것만 가져옴
  // ===========================================================================
  static Future<String?> getRealName() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    try {
      final doc = await _db.collection(_collection).doc(uid).get();
      final String? name = doc.data()?['realName'] as String?;
      if (name != null && name.isNotEmpty) return name;
      return null;
    } catch (e) {
      // 오프라인 등으로 실패하면 마지막 캐시라도 보여줌
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kCachedNameKey);
    }
  }

  // 🆕 [버그 수정 핵심] 반드시 "현재 로그인된 계정"의 uid로 조회 — 폰 공용 값이 아님
  static Future<String?> getUserType() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    try {
      final doc = await _db.collection(_collection).doc(uid).get();
      return doc.data()?['userType'] as String?;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kCachedUserTypeKey);
    }
  }

  static Future<String?> getLinkedChildEmail() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    try {
      final doc = await _db.collection(_collection).doc(uid).get();
      return doc.data()?['childEmail'] as String?;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getLinkedParentEmail() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    try {
      final doc = await _db.collection(_collection).doc(uid).get();
      return doc.data()?['parentEmail'] as String?;
    } catch (e) {
      return null;
    }
  }
}
