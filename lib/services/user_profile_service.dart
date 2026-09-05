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
  // 🆕 [요청 2026-09-04] 학교/학년 캐시 키 추가 (성취도 화면 "OO학교 O학년 이름" 표시용)
  static const String _kCachedSchoolKey = 'dke_user_school_cache';
  static const String _kCachedGradeKey = 'dke_user_grade_cache';

  // ===========================================================================
  // 1) 가입 완료 시점에 실제 입력한 이름/유형/연동 정보를 저장.
  //    🆕 이제 "이 계정(uid)"에 정확히 묶어서 Firestore에 저장합니다.
  //    🆕 [요청 2026-09-04] school/grade 파라미터 추가 (학생 가입 시 signup_screen.dart의
  //    _schoolController/_gradeController 입력값을 그대로 저장). 학부모/일반 가입은 null로 옴.
  // ===========================================================================
  static Future<void> saveProfileOnSignup({
    required String realName,
    required String userType, // '학생' / '학부모' / '일반'
    String? childEmail,
    String? parentEmail,
    String? school, // 🆕 [요청 2026-09-04]
    String? grade, // 🆕 [요청 2026-09-04]
  }) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return; // 계정 생성이 안 된 상태면 저장할 곳이 없음

    try {
      await _db.collection(_collection).doc(uid).set({
        'realName': realName,
        'userType': userType,
        if (childEmail != null && childEmail.isNotEmpty) 'childEmail': childEmail,
        if (parentEmail != null && parentEmail.isNotEmpty) 'parentEmail': parentEmail,
        if (school != null && school.isNotEmpty) 'school': school, // 🆕
        if (grade != null && grade.isNotEmpty) 'grade': grade, // 🆕
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 로컬 캐시도 함께 갱신 (다음 실행 시 잠깐 보여줄 용도)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCachedUserTypeKey, userType);
      await prefs.setString(_kCachedNameKey, realName);
      if (school != null && school.isNotEmpty) await prefs.setString(_kCachedSchoolKey, school); // 🆕
      if (grade != null && grade.isNotEmpty) await prefs.setString(_kCachedGradeKey, grade); // 🆕
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

  // 🆕 [요청 2026-09-04] 학교명 조회 — member_achievement_screen.dart의
  // "GKE 고등학교 2학년" 고정 문구를 실제 값으로 교체하기 위해 신규 추가.
  static Future<String?> getSchoolName() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    try {
      final doc = await _db.collection(_collection).doc(uid).get();
      final String? school = doc.data()?['school'] as String?;
      if (school != null && school.isNotEmpty) return school;
      return null;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kCachedSchoolKey);
    }
  }

  // 🆕 [요청 2026-09-04] 학년 조회 — 위와 동일한 목적.
  static Future<String?> getGrade() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    try {
      final doc = await _db.collection(_collection).doc(uid).get();
      final String? grade = doc.data()?['grade'] as String?;
      if (grade != null && grade.isNotEmpty) return grade;
      return null;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kCachedGradeKey);
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

  // 🆕 [요청 2026-09-04] 마이페이지에서 학교/학년을 나중에 입력·수정할 수 있도록 신규 추가.
  // 가입 시점(saveProfileOnSignup)이 아니라도, 기존 가입자가 마이페이지에서 언제든
  // 학교/학년을 채우거나 고칠 수 있게 하는 용도. 이름/유형 등 다른 필드는 건드리지 않고
  // school/grade 두 필드만 병합(merge) 저장함.
  static Future<void> updateSchoolGrade({
    required String school,
    required String grade,
  }) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection(_collection).doc(uid).set({
        'school': school,
        'grade': grade,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCachedSchoolKey, school);
      await prefs.setString(_kCachedGradeKey, grade);
    } catch (e) {
      // 저장 실패해도 앱 흐름을 막지 않음
    }
  }

  // 🆕 [요청 2026-09-05] 이름이 "학습자"로만 나타나는 계정을 위해, 마이페이지에서 이름을
  // 직접 입력·수정할 수 있도록 신규 추가. (가입 시점에 realName 저장이 누락됐거나
  // 오래된 계정이라 비어있는 경우를 직접 채울 수 있게 함)
  static Future<void> updateRealName({required String realName}) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection(_collection).doc(uid).set({
        'realName': realName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCachedNameKey, realName);
    } catch (e) {
      // 저장 실패해도 앱 흐름을 막지 않음
    }
  }
}
