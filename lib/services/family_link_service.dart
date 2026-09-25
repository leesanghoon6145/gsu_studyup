import 'dart:math';
import 'dart:convert'; // 🆕 [7일 보관함] jsonEncode/jsonDecode용
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🆕 [본인 데이터만 접근] 소유자 확인용
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // 🆕 [학부모 가시성 확보] debugPrint / kDebugMode 사용
import 'user_profile_service.dart'; // 🆕 [자녀 이름 표시 2026-09-18] DkeUserProfile.getRealName() 조회용
import 'dart:async'; // 🆕 [자녀 이름 표시 2026-09-18] unawaited() 함수 사용을 위함
import '../star_economy.dart'; // 🆕 [재설치 복원 2026-09-25] 별 복원용

// 학생↔부모 기기 연결을 담당하는 서비스
// (다른 서비스들과 동일하게 "단일 게이트웨이" 패턴 — 이 파일만 Firestore와 직접 통신)
class FamilyLinkService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'links';
  static const String _kMyLinkCodeKey = 'family_link_code'; // 내 기기에 저장해둘 연결 코드

  // 🆕 [버그 수정 2026-09-09] 예전엔 이 키가 계정 구분 없이 기기 하나에 딱 하나만 있어서,
  // 같은 폰에서 학생↔부모 계정을 바꿔 로그인하면 이전 계정이 남긴 코드를 새 계정이
  // 그대로 이어받는 심각한 문제가 있었습니다(부모가 보낸 응원을 부모 자신이 받는 등).
  // 지금 로그인된 uid를 키에 포함시켜서, 계정마다 완전히 독립적으로 저장/조회되게 합니다.
  static String _scopedKey(String base) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null ? base : '${base}_$uid';
  }

  // [학생] 6자리 코드를 새로 만들어서 Firestore에 등록하고, 내 기기에도 저장(자동 동기화용)
  static Future<String> generateLinkCode() async {
    final String? myUid = FirebaseAuth.instance.currentUser?.uid;
    final Random random = Random.secure(); // 🆕 예측 가능한 의사난수 대신 암호학적으로 안전한 난수 사용
    const int maxAttempts = 5;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final String code = (100000 + random.nextInt(900000)).toString();
      final docRef = _db.collection(_collection).doc(code);

      try {
        final bool created = await _db.runTransaction<bool>((transaction) async {
          final snapshot = await transaction.get(docRef);
          if (snapshot.exists) {
            return false; // 이미 사용 중인 코드 - 이 트랜잭션에서는 생성하지 않음
          }
          transaction.set(docRef, {
            'status': 'waiting', // waiting → connected
            'ownerUid': myUid, // 🆕 [본인 데이터만 접근] 이 데이터의 진짜 주인(학생) uid
            'parentUids': <String>[], // 🆕 [본인 데이터만 접근] 연결 허용된 부모 uid 목록
            'createdAt': FieldValue.serverTimestamp(),
          });
          return true;
        });

        if (created) {
          await saveMyLinkCode(code);
          await _writeLinkCodeIndex(code); // 🆕 [보안 2026-09-25] 부모 연결 확인용 작은 문서
          if (myUid != null) {
            try {
              await _db.collection('userLinkCodes').doc(myUid).set({'code': code});
            } catch (e) {
              debugPrint('[FamilyLinkService] userLinkCodes 매핑 저장 실패(무시하고 진행): $e');
            }
          }
          return code;
        }
      } catch (_) {
        // 이번 시도에서 예기치 못한 오류가 나도 다음 시도로 넘어감
      }
    }
    throw StateError('6자리 코드 생성 실패 - $maxAttempts회 시도');
  }

  static Future<String> getOrCreateMyLinkCode() async {
    final String? existing = await getMyLinkCode();
    if (existing != null && existing.isNotEmpty) {
      unawaited(_resendMyNameIfAvailable());
      return existing;
    }
    final String newCode = await generateLinkCode();
    unawaited(_resendMyNameIfAvailable());
    return newCode;
  }

  static Future<void> _resendMyNameIfAvailable() async {
    try {
      final String? realName = await DkeUserProfile.getRealName();
      if (realName != null && realName.isNotEmpty) {
        await pushStudentName(realName);
      }
    } catch (e) {
      debugPrint('[FamilyLinkService] _resendMyNameIfAvailable 실패(무시): $e');
    }
  }

  static const int _abandonedCodeThresholdDays = 35; // 5주 = 35일

  static Future<String?> findAbandonedOwnCode() async {
    final String? myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return null;

    final String? currentCode = await getMyLinkCode();

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _db
          .collection(_collection)
          .where('ownerUid', isEqualTo: myUid)
          .get();

      final DateTime cutoff =
      DateTime.now().subtract(const Duration(days: _abandonedCodeThresholdDays));

      for (final doc in snapshot.docs) {
        final String code = doc.id;
        if (code == currentCode) continue;

        final Map<String, dynamic> data = doc.data();
        final Timestamp? createdAt = data['createdAt'] as Timestamp?;
        final List<dynamic> sessionHistory =
            (data['sessionHistory'] as List<dynamic>?) ?? [];
        final Map<String, dynamic>? scholarship =
        data['scholarship'] as Map<String, dynamic>?;

        final bool hasAnyActivity =
            sessionHistory.isNotEmpty || (scholarship != null && scholarship.isNotEmpty);
        if (hasAnyActivity) continue;

        if (createdAt == null || createdAt.toDate().isAfter(cutoff)) continue;

        return code;
      }
    } catch (e) {
      debugPrint('[FamilyLinkService] findAbandonedOwnCode 실패(무시): $e');
    }
    return null;
  }

  static Future<void> deleteAbandonedCode(String code) async {
    try {
      await _db.collection(_collection).doc(code).delete();
      final String? myUid = FirebaseAuth.instance.currentUser?.uid;
      if (myUid != null) {
        final doc = await _db.collection('userLinkCodes').doc(myUid).get();
        if (doc.exists && (doc.data()?['code'] as String?) == code) {
          await _db.collection('userLinkCodes').doc(myUid).delete();
        }
      }
      debugPrint('[FamilyLinkService] 방치 코드 삭제 완료: $code');
    } catch (e) {
      debugPrint('[FamilyLinkService] deleteAbandonedCode 실패: $e');
    }
  }
  // ============================================================================
  // 🆕 [보안 2026-09-25] 연결 확인용 작은 문서 linkCodes/{code}
  // 학습 기록은 전혀 없고 "이 코드가 있다"는 것만 알려주는 문서.
  // 부모는 이 작은 문서만 읽고 연결하므로, 연결 전(대기 중)에는 학습 기록(links/{code})을
  // 주인 학생 말고는 아무도 읽을 수 없게 잠글 수 있음.
  // ============================================================================
  static const String _indexCollection = 'linkCodes';
  static const String _kIndexDonePrefix = 'family_link_index_done_';

  static Future<void> _writeLinkCodeIndex(String code) async {
    final String? myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    try {
      await _db.collection(_indexCollection).doc(code).set({
        'ownerUid': myUid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_scopedKey('$_kIndexDonePrefix$code'), true);
    } catch (e) {
      debugPrint('[FamilyLinkService] linkCodes 작성 실패(다음 실행 때 다시 시도): $e');
    }
  }

  // 이번 수정 전에 만든 코드도, 학생 앱이 한 번 열리면 자동으로 확인용 문서가 생김
  static Future<void> _ensureLinkCodeIndex(String code) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_scopedKey('$_kIndexDonePrefix$code')) == true) return;
    await _writeLinkCodeIndex(code);
  }

  // ============================================================================
  // 🆕 [재설치 복원 2026-09-25] 부모가 연결한 자녀 코드 목록을 서버(parentLinks/{uid})에도 보관.
  // 부모가 앱을 새로 깔아도 자녀 목록이 사라지지 않음.
  // ============================================================================
  static const String _parentLinksCollection = 'parentLinks';
  static const String _kLinkedCodesSyncedKey = 'family_linked_codes_synced';

  static Future<void> _syncLinkedCodesToCloud(List<String> list) async {
    final String? myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    try {
      await _db.collection(_parentLinksCollection).doc(myUid).set({
        'codes': list,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_scopedKey(_kLinkedCodesSyncedKey), true);
    } catch (e) {
      debugPrint('[FamilyLinkService] parentLinks 저장 실패(다음에 다시 시도): $e');
    }
  }

  // ============================================================================
  // 🆕 [재설치 복원 2026-09-25] 학생이 앱을 새로 깔고 로그인했을 때, 휴대폰 기록이 비어 있으면
  // 서버(links/{내 코드})에 올라가 있던 기록을 다시 받아옴. 계정마다 딱 1번만 실행.
  // 휴대폰에 이미 기록이 있으면 절대 덮어쓰지 않음(중복·손실 방지).
  // ============================================================================
  static const String _kRestoreDoneKey = 'family_cloud_restore_done';

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // 서버 시간값(Timestamp)이 섞여 있어도 글자로 바꿔서 저장할 수 있게
  static Object? _toEncodable(Object? o) {
    if (o is Timestamp) return o.toDate().toIso8601String();
    return o.toString();
  }

  static Future<void> restoreFromCloudIfNeeded() async {
    final String? myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final String doneKey = _scopedKey(_kRestoreDoneKey);
    if (prefs.getBool(doneKey) == true) return;

    final String? code = await getMyLinkCode();
    if (code == null) return; // 코드가 없으면 복원할 것도 없음

    try {
      final doc = await _db.collection(_collection).doc(code).get();
      final Map<String, dynamic>? data = doc.data();
      if (data == null || data['ownerUid'] != myUid) return;

      // ① 별 - 휴대폰 누적 별이 0일 때만 서버 값으로
      final int cloudTotal = (data['totalStars'] as num?)?.toInt() ?? 0;
      final Timestamp? updatedAt = data['updatedAt'] as Timestamp?;
      final bool updatedToday = updatedAt != null && _sameDay(updatedAt.toDate(), DateTime.now());
      final int cloudToday = updatedToday ? ((data['todayStars'] as num?)?.toInt() ?? 0) : 0;
      await DkeStars.restoreFromCloudIfEmpty(totalStars: cloudTotal, todayStars: cloudToday);

      // ② 학습 세션 기록 - 휴대폰에 dke_history_ 기록이 하나도 없을 때만
      final bool hasLocalHistory = prefs.getKeys().any((k) => k.startsWith('dke_history_'));
      final List<dynamic> sessions = (data['sessionHistory'] as List<dynamic>?) ?? [];
      if (!hasLocalHistory && sessions.isNotEmpty) {
        final Map<String, List<String>> bySubject = {};
        for (final s in sessions) {
          if (s is! Map) continue;
          final Map<String, dynamic> m = Map<String, dynamic>.from(s);
          final String subject = (m['subject'] as String?) ?? '';
          if (subject.isEmpty) continue;
          bySubject.putIfAbsent(subject, () => []).add(jsonEncode(m, toEncodable: _toEncodable));
        }
        for (final entry in bySubject.entries) {
          await prefs.setStringList('dke_history_${entry.key}', entry.value);
        }
      }

      // ③ 평가 기록 - 휴대폰 gke_exam_records가 비어 있을 때만
      final String? localExams = prefs.getString('gke_exam_records');
      final List<dynamic> exams = (data['examRecords'] as List<dynamic>?) ?? [];
      final bool localExamsEmpty = localExams == null || localExams.isEmpty || localExams == '[]';
      if (localExamsEmpty && exams.isNotEmpty) {
        await prefs.setString('gke_exam_records', jsonEncode(exams, toEncodable: _toEncodable));
      }

      await prefs.setBool(doneKey, true);
      debugPrint('[FamilyLinkService] 재설치 복원 완료: 별=$cloudTotal, 세션=${sessions.length}, 평가=${exams.length}');
    } catch (e) {
      debugPrint('[FamilyLinkService] 재설치 복원 실패(다음 실행 때 다시 시도): $e');
    }
  }

  static const String _kMyLinkedCodesKey = 'family_linked_codes';
  static const int maxChildren = 5;
  static Future<List<String>> getLinkedCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> local = prefs.getStringList(_scopedKey(_kMyLinkedCodesKey)) ?? [];
    if (local.isNotEmpty) {
      // 🆕 [재설치 복원] 예전에 연결한 목록도 서버에 한 번 올려둠 (계정마다 1번)
      if (prefs.getBool(_scopedKey(_kLinkedCodesSyncedKey)) != true) {
        unawaited(_syncLinkedCodesToCloud(local));
      }
      return local;
    }
    // 🆕 [재설치 복원] 휴대폰 목록이 비어 있으면 서버에 보관된 목록을 받아옴
    final String? myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return [];
    try {
      final doc = await _db.collection(_parentLinksCollection).doc(myUid).get();
      final List<String> cloud =
      ((doc.data()?['codes'] as List<dynamic>?) ?? []).map((e) => e.toString()).toList();
      if (cloud.isNotEmpty) {
        await prefs.setStringList(_scopedKey(_kMyLinkedCodesKey), cloud);
        await prefs.setBool(_scopedKey(_kLinkedCodesSyncedKey), true);
        debugPrint('[FamilyLinkService] 자녀 목록 서버에서 복원: $cloud');
      }
      return cloud;
    } catch (e) {
      debugPrint('[FamilyLinkService] 자녀 목록 복원 실패: $e');
      return [];
    }
  }

  static Future<bool> addLinkedCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = _scopedKey(_kMyLinkedCodesKey);
    final list = prefs.getStringList(key) ?? [];
    debugPrint('[addLinkedCode] 현재 저장된 코드 목록: $list (개수: ${list.length})');
    if (list.contains(code)) {
      debugPrint('[addLinkedCode] 이미 목록에 있음: $code');
      return true;
    }
    if (list.length >= maxChildren) {
      debugPrint('[addLinkedCode] 정원초과(5명)로 추가 실패!');
      return false;
    }
    list.add(code);
    await prefs.setStringList(key, list);
    unawaited(_syncLinkedCodesToCloud(list)); // 🆕 [재설치 복원] 서버에도 보관
    return true;
  }

  static Future<void> removeLinkedCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = _scopedKey(_kMyLinkedCodesKey);
    final list = prefs.getStringList(key) ?? [];
    list.remove(code);
    await prefs.setStringList(key, list);
    unawaited(_syncLinkedCodesToCloud(list)); // 🆕 [재설치 복원] 서버에도 반영

    final String? myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    try {
      await _db.collection(_collection).doc(code).update({
        'parentUids': FieldValue.arrayRemove([myUid]),
      });
    } catch (e) {
      debugPrint('[FamilyLinkService] removeLinkedCode 서버 반영 실패: $e');
    }
  }
  static const int maxParentsPerChild = 3;

  static Future<bool> connectWithCode(String code) async {
    final ConnectResult result = await connectWithCodeResult(code);
    return result == ConnectResult.success;
  }

  static Future<ConnectResult> connectWithCodeResult(String code) async {
    final String? myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return ConnectResult.notLoggedIn;

    // 🆕 [보안 2026-09-25] 학습 기록 문서(links)는 읽지 않고, 확인용 작은 문서(linkCodes)만 확인
    try {
      final idx = await _db.collection(_indexCollection).doc(code).get();
      if (!idx.exists) return ConnectResult.codeNotFound;
    } catch (e) {
      debugPrint('[FamilyLinkService] linkCodes 조회 실패: $e');
      return ConnectResult.unknownError;
    }

    // 🆕 정원(3명) 검사는 서버 보안 규칙이 대신 함 - 꽉 찼으면 서버가 거부함.
    // 이미 연결된 부모가 재설치 후 다시 입력하는 경우도 규칙 (2)번으로 그대로 허용됨.
    try {
      await _db.collection(_collection).doc(code).update({
        'status': 'connected',
        'connectedAt': FieldValue.serverTimestamp(),
        'parentUids': FieldValue.arrayUnion([myUid]),
      });
    } on FirebaseException catch (e) {
      debugPrint('[FamilyLinkService] 연결 거부: ${e.code}');
      if (e.code == 'not-found') return ConnectResult.codeNotFound;
      if (e.code == 'permission-denied') return ConnectResult.capacityFull;
      return ConnectResult.unknownError;
    } catch (e) {
      return ConnectResult.unknownError;
    }

    await addLinkedCode(code);
    return ConnectResult.success;
  }

  static Future<void> clearMyLinkCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scopedKey(_kMyLinkCodeKey));
  }

  static Future<void> saveMyLinkCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scopedKey(_kMyLinkCodeKey), code);
  }

  static Future<String?> getMyLinkCode() async {
    final prefs = await SharedPreferences.getInstance();
    final String? localCode = prefs.getString(_scopedKey(_kMyLinkCodeKey));
    if (localCode != null && localCode.isNotEmpty) {
      unawaited(_ensureOwnerUid(localCode));
      unawaited(_ensureLinkCodeIndex(localCode)); // 🆕 [보안 2026-09-25]
      return localCode;
    }

    final String? myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return null;

    try {
      final doc = await _db.collection('userLinkCodes').doc(myUid).get();
      final String? recoveredCode = doc.exists ? (doc.data()?['code'] as String?) : null;
      if (recoveredCode != null && recoveredCode.isNotEmpty) {
        await saveMyLinkCode(recoveredCode);
        unawaited(_ensureLinkCodeIndex(recoveredCode)); // 🆕 [보안 2026-09-25]
        debugPrint('[FamilyLinkService] getMyLinkCode: 서버에서 코드 복구함 - $recoveredCode');
        return recoveredCode;
      }
    } catch (e) {
      debugPrint('[FamilyLinkService] getMyLinkCode 서버 조회 실패: $e');
    }
    return null;
  }
  // 🆕 [보안 규칙 오류 자동 복구 2026-09-20] 오래된 코드(464471, 955478 등)는
  // ownerUid 필드 없이 생성되어, Firestore 보안 규칙의 get 조건
  // (request.auth.uid == resource.data.ownerUid)이 평가 자체에서 실패하며
  // 읽기가 거부되는 문제가 있었음. 내 코드를 확인할 때마다, 그 문서에
  // ownerUid가 비어있으면 지금 로그인된 내 uid로 자동으로 채워넣어서
  // 다시는 이 문제가 반복되지 않게 함.
  static Future<void> _ensureOwnerUid(String code) async {
    final String? myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    try {
      final doc = await _db.collection(_collection).doc(code).get();
      final dynamic existing = doc.data()?['ownerUid'];
      if (existing == null || existing == '') {
        await _db.collection(_collection).doc(code).set({
          'ownerUid': myUid,
        }, SetOptions(merge: true));
        debugPrint('[FamilyLinkService] ownerUid 자동 채움 완료: $code');
      }
    } catch (e) {
      debugPrint('[FamilyLinkService] ownerUid 자동 채움 실패(무시): $e');
    }
  }
  static const Duration _pushInterval = Duration(minutes: 3);
  static const String _kLastPushKey = 'family_link_last_push_ms';

  static Future<void> pushStudentStats({
    required int totalStars,
    required int todayStars,
    required int level,
  }) async {
    final code = await getMyLinkCode();
    if (code == null) return;

    final prefs = await SharedPreferences.getInstance();
    final int lastPushMs = prefs.getInt(_kLastPushKey) ?? 0;
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - lastPushMs < _pushInterval.inMilliseconds) {
      return;
    }

    await _db.collection(_collection).doc(code).set({
      'totalStars': totalStars,
      'todayStars': todayStars,
      'level': level,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await prefs.setInt(_kLastPushKey, nowMs);
  }

  static Future<void> pushStudentName(String realName) async {
    final code = await getMyLinkCode();
    if (code == null) return;

    try {
      await _db.collection(_collection).doc(code).set({
        'studentName': realName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FamilyLinkService] pushStudentName 실패(로컬 기능에는 영향 없음): $e');
    }
  }

  static const int _kMaxSessionHistory = 300;

  static Future<void> pushSessionRecord(Map<String, dynamic> record) async {
    final code = await getMyLinkCode();
    if (code == null) return;

    final docRef = _db.collection(_collection).doc(code);
    try {
      final snapshot = await docRef.get();
      final List<dynamic> current =
          (snapshot.data()?['sessionHistory'] as List<dynamic>?) ?? [];
      final List<dynamic> updated = [...current, record];
      final List<dynamic> trimmed = updated.length > _kMaxSessionHistory
          ? updated.sublist(updated.length - _kMaxSessionHistory)
          : updated;

      await docRef.set({
        'sessionHistory': trimmed,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FamilyLinkService] pushSessionRecord 실패(로컬 저장은 안전): $e');
    }
  }

  static const int _kMaxExamRecords = 200;

  static Future<void> pushExamRecord(Map<String, dynamic> record) async {
    final code = await getMyLinkCode();
    if (code == null) return;

    final docRef = _db.collection(_collection).doc(code);
    try {
      final snapshot = await docRef.get();
      final List<dynamic> current = (snapshot.data()?['examRecords'] as List<dynamic>?) ?? [];
      final List<dynamic> updated = [...current, record];
      final List<dynamic> trimmed = updated.length > _kMaxExamRecords
          ? updated.sublist(updated.length - _kMaxExamRecords)
          : updated;

      await docRef.set({
        'examRecords': trimmed,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FamilyLinkService] pushExamRecord 실패(로컬 저장은 안전): $e');
    }
  }

  static Future<void> pushGradeManagementSnapshot({
    required List<Map<String, dynamic>> records,
    required List<Map<String, dynamic>> configs,
  }) async {
    final code = await getMyLinkCode();
    if (code == null) return;

    try {
      await _db.collection(_collection).doc(code).set({
        'gradeRecords': records,
        'gradeConfigs': configs,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FamilyLinkService] pushGradeManagementSnapshot 실패(로컬 저장은 안전): $e');
    }
  }

  // ============================================================================
  // 🆕 [실시간 학습 현황 2026-09-19] 부모가 "지금 이 순간 자녀가 학습 중인지"를
  // 볼 수 있게 하는 기능.
  // 🆕 [버그 수정 2026-09-19] _kLastLiveStatusPushKey가 uid 스코프 안 되어 있던 것을
  // 다른 키들과 동일한 패턴(_scopedKey)으로 수정함.
  // 🔍 [진단용 로그 2026-09-19] liveStatus 필드가 Firestore에 전혀 생기지 않는 문제를
  // 추적하기 위해 각 단계마다 debugPrint를 추가함. 원인이 확인되면 제거 예정 — 원인만
  // 찾고 나면 이 로그들은 지워도 됩니다.
  // ============================================================================
  static const String _kLastLiveStatusPushKey = 'family_link_last_live_status_push_ms';

  static Future<void> pushLiveStudyStatus({
    required bool isStudying,
    String? subject,
    int elapsedSeconds = 0,
    int totalSeconds = 0,
  }) async {
    final code = await getMyLinkCode();
    if (code == null) return;

    final prefs = await SharedPreferences.getInstance();
    final int lastPushMs = prefs.getInt(_scopedKey(_kLastLiveStatusPushKey)) ?? 0;
    final int nowMs = DateTime.now().millisecondsSinceEpoch;

    final int intervalMs = elapsedSeconds <= 60
        ? const Duration(seconds: 15).inMilliseconds
        : const Duration(seconds: 90).inMilliseconds;
    if (nowMs - lastPushMs < intervalMs) return;

    try {
      await _db.collection(_collection).doc(code).set({
        'liveStatus': {
          'isStudying': isStudying,
          'subject': subject ?? '',
          'elapsedSeconds': elapsedSeconds,
          'totalSeconds': totalSeconds,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
      await prefs.setInt(_scopedKey(_kLastLiveStatusPushKey), nowMs);
    } catch (e) {
      debugPrint('[FamilyLinkService] pushLiveStudyStatus 실패(로컬은 안전): $e');
    }
  }

  static Future<void> clearLiveStudyStatus() async {
    final code = await getMyLinkCode();
    if (code == null) return;
    try {
      // 🆕 [요청 2026-09-21] 정지/종료 시 elapsedSeconds/totalSeconds/subject를 0으로
      // 지우지 않고 그대로 남겨서, 부모방에서 마지막 진행 상태(무지개 바)가 유지된 채로
      // 상태 줄만 "휴식중"으로 바뀌도록 함. isStudying만 false로 바꿈.
      await _db.collection(_collection).doc(code).update({
        'liveStatus.isStudying': false,
        'liveStatus.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FamilyLinkService] clearLiveStudyStatus 실패: $e');
    }
  }

  static Future<void> pushScholarshipData({
    required String monthKey,
    required int monthlyBaseStars,
    required int monthlyBonusStars,
    required Map<String, int> bonusBreakdown,
  }) async {
    final code = await getMyLinkCode();
    if (code == null) return;

    try {
      await _db.collection(_collection).doc(code).set({
        'scholarship': {
          monthKey: {
            'monthlyBaseStars': monthlyBaseStars,
            'monthlyBonusStars': monthlyBonusStars,
            'bonusBreakdown': bonusBreakdown,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FamilyLinkService] pushScholarshipData 실패(로컬 저장은 안전): $e');
    }
  }

  static Future<void> setScholarshipType(String code, {required String monthKey, required String typeKey}) async {
    try {
      await _db.collection(_collection).doc(code).set({
        'scholarshipTypeSelections': {
          monthKey: typeKey,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FamilyLinkService] setScholarshipType 실패: $e');
    }
  }

  static Future<void> pushEmojiToChild(String code, {required String emoji, required String message}) async {
    try {
      await _db.collection(_collection).doc(code).set({
        'pendingEmoji': {
          'emoji': emoji,
          'message': message,
          'sentAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FamilyLinkService] pushEmojiToChild 실패: $e');
    }
  }

  static Future<void> pushEncouragementToChild(String code, {required String message}) async {
    try {
      await _db.collection(_collection).doc(code).set({
        'pendingMessage': {
          'text': message,
          'sentAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FamilyLinkService] pushEncouragementToChild 실패: $e');
    }
  }

  static const String _kHistoryKey = 'family_encouragement_history';
  static const int _historyRetentionDays = 7;

  static Future<void> saveEncouragementToHistory({
    required String type,
    String? emoji,
    required String text,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = _scopedKey(_kHistoryKey);
      final List<String> raw = prefs.getStringList(key) ?? [];

      final List<Map<String, dynamic>> entries = raw
          .map((s) {
        try {
          return Map<String, dynamic>.from(jsonDecode(s) as Map);
        } catch (_) {
          return null;
        }
      })
          .whereType<Map<String, dynamic>>()
          .toList();

      entries.add({
        'type': type,
        'emoji': emoji,
        'text': text,
        'timestamp': DateTime.now().toIso8601String(),
      });

      final DateTime cutoff = DateTime.now().subtract(const Duration(days: _historyRetentionDays));
      final List<Map<String, dynamic>> kept = entries.where((e) {
        final DateTime? ts = DateTime.tryParse(e['timestamp'] as String? ?? '');
        return ts != null && ts.isAfter(cutoff);
      }).toList();

      await prefs.setStringList(key, kept.map((e) => jsonEncode(e)).toList());
    } catch (e) {
      debugPrint('[FamilyLinkService] saveEncouragementToHistory 실패: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getEncouragementHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = _scopedKey(_kHistoryKey);
      final List<String> raw = prefs.getStringList(key) ?? [];

      final List<Map<String, dynamic>> entries = raw
          .map((s) {
        try {
          return Map<String, dynamic>.from(jsonDecode(s) as Map);
        } catch (_) {
          return null;
        }
      })
          .whereType<Map<String, dynamic>>()
          .toList();

      final DateTime cutoff = DateTime.now().subtract(const Duration(days: _historyRetentionDays));
      final List<Map<String, dynamic>> kept = entries.where((e) {
        final DateTime? ts = DateTime.tryParse(e['timestamp'] as String? ?? '');
        return ts != null && ts.isAfter(cutoff);
      }).toList();

      if (kept.length != entries.length) {
        await prefs.setStringList(key, kept.map((e) => jsonEncode(e)).toList());
      }

      kept.sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String));
      return kept;
    } catch (e) {
      debugPrint('[FamilyLinkService] getEncouragementHistory 실패: $e');
      return [];
    }
  }

  static Future<void> clearPendingEmoji() async {
    final code = await getMyLinkCode();
    if (code == null) return;
    try {
      await _db.collection(_collection).doc(code).update({'pendingEmoji': FieldValue.delete()});
    } catch (e) {
      debugPrint('[FamilyLinkService] clearPendingEmoji 실패: $e');
    }
  }

  static Future<void> clearPendingMessage() async {
    final code = await getMyLinkCode();
    if (code == null) return;
    try {
      await _db.collection(_collection).doc(code).update({'pendingMessage': FieldValue.delete()});
    } catch (e) {
      debugPrint('[FamilyLinkService] clearPendingMessage 실패: $e');
    }
  }

  static Future<void> sendTestMessage(String code, String message) async {
    if (!kDebugMode) return;
    await _db.collection(_collection).doc(code).update({
      'testMessage': message,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> watch(String code) {
    return _db.collection(_collection).doc(code).snapshots();
  }
  // ============================================================================
  // 🆕 [보호자 인증 전용 2026-09-21] 학생 코드 시스템(links 컬렉션)과 완전히 분리된
  // 별도 컬렉션(parentConsentCodes) 사용. 회원가입 도중(계정 생성 전)에도 호출 가능해야
  // 하므로 FirebaseAuth.currentUser에 의존하지 않음. 실제 학습 데이터와 전혀 무관한,
  // 순수히 "이 순간 보호자가 실제로 확인했는지"만 기록하는 일회용 코드.
  // ============================================================================
  static const String _consentCollection = 'parentConsentCodes';

  static Future<String> generateConsentCode() async {
    final Random random = Random.secure();
    const int maxAttempts = 5;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final String code = (100000 + random.nextInt(900000)).toString();
      final docRef = _db.collection(_consentCollection).doc(code);

      try {
        final bool created = await _db.runTransaction<bool>((transaction) async {
          final snapshot = await transaction.get(docRef);
          if (snapshot.exists) return false;
          transaction.set(docRef, {
            'code': code,
            'status': 'waiting',
            'connected': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
          return true;
        });
        if (created) return code;
      } catch (_) {
        // 이번 시도 실패해도 다음 시도로 넘어감
      }
    }
    throw StateError('보호자 인증 코드 생성 실패 - $maxAttempts회 시도');
  }

  // 부모가 코드를 입력해서 "확인했다"고 표시. 계정 생성 전 학생이 실시간으로 이 변화를 감지함.
  static Future<bool> confirmConsentCode(String code) async {
    final docRef = _db.collection(_consentCollection).doc(code);
    try {
      final bool success = await _db.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return false;
        final bool alreadyConnected = (snapshot.data()?['connected'] as bool?) ?? false;
        if (alreadyConnected) return true; // 이미 연결됐으면 성공으로 간주(중복 클릭 대비)
        transaction.update(docRef, {
          'status': 'connected',
          'connected': true,
          'connectedAt': FieldValue.serverTimestamp(),
        });
        return true;
      });
      return success;
    } catch (e) {
      debugPrint('[FamilyLinkService] confirmConsentCode 실패: $e');
      return false;
    }
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> watchConsentCode(String code) {
    return _db.collection(_consentCollection).doc(code).snapshots();
  }
  }

enum ConnectResult {
  success,
  codeNotFound,
  capacityFull,
  notLoggedIn,
  unknownError,
}
