import 'dart:math';
import 'dart:convert'; // 🆕 [7일 보관함] jsonEncode/jsonDecode용
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🆕 [본인 데이터만 접근] 소유자 확인용
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // 🆕 [학부모 가시성 확보] debugPrint / kDebugMode 사용
import 'user_profile_service.dart'; // 🆕 [자녀 이름 표시 2026-09-18] DkeUserProfile.getRealName() 조회용
import 'dart:async'; // 🆕 [자녀 이름 표시 2026-09-18] unawaited() 함수 사용을 위함

// 학생↔부모 기기 연결을 담당하는 서비스
// (다른 서비스들과 동일하게 "단일 게이트웨이" 패턴 — 이 파일만 Firestore와 직접 통신)
//
// 🆕 [2026-09-04 보안/안정성 점검 반영] 아래 8가지를 이번에 함께 수정했습니다.
// 1) generateLinkCode 코드 충돌 시 기존 문서 덮어쓰기 → 트랜잭션 + 재시도로 방지
// 2) pushSessionRecord 무한 배열 증가(Firestore 1MiB 문서 한도) → 최근 N개만 유지
// 3) removeLinkedCode가 로컬 목록만 지우고 서버 parentUids는 안 지움 → 서버에서도 제거
// 4) maxParentsPerChild 정원 체크의 동시 요청 race condition → 트랜잭션으로 원자적 처리
// 5) Random() 예측 가능한 의사난수 → Random.secure()로 교체
// 6) connectWithCode 실패 사유(없는 코드/정원초과/미로그인/기타)를 구분 못하던 문제 → enum 추가
// 7) 전송 주기 주석(3분/5분 불일치) 정정
// 8) sendTestMessage가 운영 빌드에서도 동작하던 문제 → kDebugMode로 차단
//
// ⚠️ [서버 측 병행 조치 필요] 4)는 클라이언트에서 트랜잭션으로 최대한 막았지만,
// 진짜 강제는 Firestore 보안 규칙에서 parentUids.size() <= 3 을 검증해야 완전해집니다.
// (클라이언트 코드만으로는 규칙을 우회하는 요청까지 막을 수 없습니다.)
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
  //
  // 🆕 [버그 수정] 예전에는 존재 여부 확인 없이 바로 .set()을 호출해서, 90만 개뿐인 6자리
  // 코드가 우연히 겹치면 이미 사용 중인 다른 가족의 연결 문서(parentUids, sessionHistory
  // 포함)를 통째로 덮어쓰는 심각한 문제가 있었습니다. 지금은 트랜잭션 안에서 "존재하지
  // 않을 때만 생성"을 원자적으로 처리하고, 겹치면 최대 5회까지 새 코드로 재시도합니다.
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
          // 🆕 [버그 수정 2026-09-09] 이 기기의 로컬 저장(SharedPreferences)이 지워지면
          // (예: 앱 데이터 삭제, 재설치) 서버엔 코드가 멀쩡히 있어도 앱이 "연결된 적 없음"으로
          // 착각하는 문제가 있었습니다. uid → 코드 매핑을 서버에도 별도로 남겨서, 로컬 캐시가
          // 사라져도 getMyLinkCode()가 이걸로 되찾아올 수 있게 합니다.
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

  // ============================================================================
  // 🆕 [코드 남발 방지 2026-09-18] 학생 화면이 앱을 열 때마다 무작정
  // generateLinkCode()를 직접 부르면, 그때마다 매번 새 코드가 만들어져서
  // Firestore에 주인 없는 코드가 계속 쌓이는 문제가 있었음(555792, 555793처럼
  // 짧은 시간에 여러 개 생성됨). 학생 화면은 이제부터 generateLinkCode()를
  // 직접 부르지 말고, 반드시 이 함수를 불러야 함 — "이미 내 코드가 있으면
  // 그걸 그대로 재사용"하고, 정말 하나도 없을 때만 새로 생성함.
  // ============================================================================
  static Future<String> getOrCreateMyLinkCode() async {
    // 1) 이미 코드가 있는지 먼저 확인 (로컬 → 서버 순으로 확인하는 기존 로직 재사용)
    final String? existing = await getMyLinkCode();
    if (existing != null && existing.isNotEmpty) {
      // 🆕 [자녀 이름 표시 2026-09-18] pushStudentName()은 "코드가 이미 있어야만"
      // 성공하는데, main.dart의 로그인 로직은 정확히 "코드가 아직 없을 때"
      // 이름을 보내려 시도해서 매번 조용히 실패하고 있었음(원인 확정).
      // 여기서 코드를 확인/생성할 때마다 이름도 함께 재전송해서, 부모방에
      // "코드 104367"처럼 번호만 뜨는 문제를 근본적으로 막음.
      unawaited(_resendMyNameIfAvailable());
      return existing;
    }
    // 2) 정말 하나도 없을 때만 새로 생성
    final String newCode = await generateLinkCode();
    // 🆕 새로 코드를 만든 직후에도 이름을 바로 보냄 — 코드 생성 시점엔 이름이
    // 전혀 저장되지 않았던(ownerUid만 저장) 원래 설계의 빈틈을 여기서 메움.
    unawaited(_resendMyNameIfAvailable());
    return newCode;
  }

  // 🆕 [자녀 이름 표시 2026-09-18] DkeUserProfile에 저장된 실명을 다시 읽어서
  // pushStudentName()으로 재전송하는 헬퍼. main.dart가 이미 가진 실명 조회
  // 로직(DkeUserProfile.getRealName())과 동일한 방식을 그대로 재사용함.
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

  // ============================================================================
  // 🆕 [방치 코드 정리 2026-09-18] 학생이 코드를 여러 번 생성하다 예전 코드를
  // 잊어버리고 방치하는 문제(555792, 555793 등)를 해결하기 위한 기능.
  //
  // 절대 원칙: 이 기능은 코드를 자동으로 지우지 않습니다. 오직 "5주 이상 학습
  // 기록이 하나도 없는, 지금 쓰지 않는 예전 코드"를 찾아서 화면에 보여주기만
  // 하고, 실제 삭제는 학생이 직접 "삭제" 버튼을 눌러야만 일어납니다. 그래서
  // 몇 달 뒤 접속해도 본인이 지운 적 없는 코드는 절대 사라지지 않습니다.
  // ============================================================================
  static const int _abandonedCodeThresholdDays = 35; // 5주 = 35일

  // 🆕 학생 쪽에서 호출: "내가 예전에 만들었지만 지금 안 쓰고 있고, 학습 기록도
  // 없이 5주 넘게 방치된 코드"가 있는지 확인. 있으면 그 코드 문자열을 반환하고,
  // 없으면 null을 반환함. userLinkCodes/{uid}는 uid당 코드 하나만 담는 매핑이라
  // "예전 코드들"을 전부 찾으려면 links 컬렉션에서 ownerUid로 직접 조회해야 함.
  static Future<String?> findAbandonedOwnCode() async {
    final String? myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return null;

    final String? currentCode = await getMyLinkCode();

    try {
      // 내가(ownerUid) 만든 모든 코드 문서를 조회
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _db
          .collection(_collection)
          .where('ownerUid', isEqualTo: myUid)
          .get();

      final DateTime cutoff =
      DateTime.now().subtract(const Duration(days: _abandonedCodeThresholdDays));

      for (final doc in snapshot.docs) {
        final String code = doc.id;
        if (code == currentCode) continue; // 지금 쓰고 있는 코드는 절대 대상에서 제외

        final Map<String, dynamic> data = doc.data();
        final Timestamp? createdAt = data['createdAt'] as Timestamp?;
        final List<dynamic> sessionHistory =
            (data['sessionHistory'] as List<dynamic>?) ?? [];
        final Map<String, dynamic>? scholarship =
        data['scholarship'] as Map<String, dynamic>?;

        // 학습 기록이 조금이라도 있으면 "방치"로 보지 않음 (안전장치)
        final bool hasAnyActivity =
            sessionHistory.isNotEmpty || (scholarship != null && scholarship.isNotEmpty);
        if (hasAnyActivity) continue;

        // 생성된 지 5주(35일) 미만이면 아직 방치라고 보지 않음
        if (createdAt == null || createdAt.toDate().isAfter(cutoff)) continue;

        return code; // 조건을 만족하는 첫 번째 방치 코드를 반환
      }
    } catch (e) {
      debugPrint('[FamilyLinkService] findAbandonedOwnCode 실패(무시): $e');
    }
    return null; // 방치된 코드 없음
  }

  // 🆕 학생이 팝업에서 "삭제"를 직접 눌렀을 때만 호출되는 함수. 서버 문서와
  // (혹시 이 기기에 로컬 흔적이 남아있다면) 로컬 코드도 함께 정리함.
  static Future<void> deleteAbandonedCode(String code) async {
    try {
      await _db.collection(_collection).doc(code).delete();
      final String? myUid = FirebaseAuth.instance.currentUser?.uid;
      // 혹시 userLinkCodes/{uid}가 이 방치된 코드를 가리키고 있었다면 함께 정리
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

  // 🆕 [부모] 연결된 자녀 코드 목록 (최대 5명)
  static const String _kMyLinkedCodesKey = 'family_linked_codes';
  static const int maxChildren = 5;

  static Future<List<String>> getLinkedCodes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_scopedKey(_kMyLinkedCodesKey)) ?? [];
  }

  // 부모 쪽에서 자녀 코드를 목록에 추가. 이미 5명이면 false 반환(추가 실패)
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
    return true;
  }

  // 🆕 [보안 수정] 로컬 기기 목록에서만 지우면, 서버 문서의 parentUids에는 내 uid가 그대로
  // 남아있어서 "연결 해제" 후에도 서버 규칙상 계속 자녀 데이터를 읽을 수 있는 문제가 있었습니다.
  // 이제 로컬 목록 제거와 함께 서버 parentUids에서도 반드시 내 uid를 제거합니다.
  static Future<void> removeLinkedCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = _scopedKey(_kMyLinkedCodesKey);
    final list = prefs.getStringList(key) ?? [];
    list.remove(code);
    await prefs.setStringList(key, list);

    final String? myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return; // 로그인 정보가 없으면 서버 반영은 건너뜀 (로컬 해제는 이미 완료)
    try {
      await _db.collection(_collection).doc(code).update({
        'parentUids': FieldValue.arrayRemove([myUid]),
      });
    } catch (e) {
      // 서버 반영에 실패해도 로컬 연결 해제 자체는 이미 끝난 상태 - 다음 기회에 재시도 필요
      debugPrint('[FamilyLinkService] removeLinkedCode 서버 반영 실패: $e');
    }
  }

  // 🆕 [다중 학부모 지원 2026-09-01] 한 자녀(코드)에 연결 가능한 부모 최대 인원.
  // 지금은 무료로 3명까지 열어두고, 나중에 결제 시스템을 붙일 때 이 상수를
  // "무료 1명 + 유료 결제 시 추가"처럼 사용자별 조건부 값으로 바꾸면 됨.
  // ⚠️ Firestore 보안 규칙(/links/{code} allow update)에도 반드시 같은 숫자(3)로
  // 맞춰둬야 함 — 클라이언트 트랜잭션은 동시 요청 경합을 크게 줄여주지만, 최종 강제는
  // 항상 서버 규칙이 담당해야 완전해집니다.
  static const int maxParentsPerChild = 3;

  // 🆕 [실패 사유 구분] 예전엔 "없는 코드"/"정원 초과"/"권한 거부"가 전부 false 하나로
  // 뭉뚱그려져서 화면에서 정확한 안내 메시지를 보여줄 수 없었습니다. 이제 이 enum으로
  // 구분해서 반환합니다. 기존 connectWithCode()는 하위 호환을 위해 bool을 그대로 반환하고,
  // 새로 이 enum이 필요한 화면은 connectWithCodeResult()를 사용하면 됩니다.
  static Future<bool> connectWithCode(String code) async {
    final ConnectResult result = await connectWithCodeResult(code);
    return result == ConnectResult.success;
  }

  // [부모] 코드를 입력해서 연결 시도.
  //
  // 🆕 [버그 수정 2026-09-01] 앱을 지웠다 재설치한 뒤 "예전에 이미 연결했던 코드"를 다시
  // 입력하면, 이미 connected 상태인 코드에는 보안 규칙상 update 자체가 거부(PERMISSION_DENIED)
  // 됐던 문제 - 내 uid가 이미 parentUids에 있으면 서버에 다시 쓰지 않고 바로 성공 처리합니다.
  //
  // 🆕 [동시성 수정] "현재 인원 확인 → 인원 추가"를 트랜잭션 하나로 묶어서, 두 부모가 거의
  // 동시에 연결을 시도해도 정원(maxParentsPerChild)을 넘겨 연결되는 경합을 방지합니다.
  static Future<ConnectResult> connectWithCodeResult(String code) async {
    final String? myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return ConnectResult.notLoggedIn; // 로그인 안 된 상태면 연결 불가

    final docRef = _db.collection(_collection).doc(code);

    try {
      final ConnectResult result = await _db.runTransaction<ConnectResult>((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          return ConnectResult.codeNotFound; // 존재하지 않는 코드
        }

        final List<dynamic> existingParentUids =
            (snapshot.data()?['parentUids'] as List<dynamic>?) ?? [];

        // 🆕 [버그 수정 핵심] 이미 내가 연결되어 있는 코드라면, 서버에 다시 쓰지 않고 바로 성공 처리.
        if (existingParentUids.contains(myUid)) {
          return ConnectResult.success; // 서버엔 이미 연결되어 있지만, 로컬 목록엔 없을 수 있으므로
        }

        // 🆕 [다중 학부모 지원 + 동시성 수정] 트랜잭션 안에서 정원 확인 → 즉시 반영까지 원자적으로 처리
        if (existingParentUids.length >= maxParentsPerChild) {
          return ConnectResult.capacityFull;
        }

        transaction.update(docRef, {
          'status': 'connected',
          'connectedAt': FieldValue.serverTimestamp(),
          'parentUids': FieldValue.arrayUnion([myUid]), // 🆕 [본인 데이터만 접근] 나를 허용 목록에 추가
        });
        return ConnectResult.success;
      });

      if (result == ConnectResult.success) {
        await addLinkedCode(code);
      }
      return result;
    } catch (e) {
      // 🆕 [버그 수정] 권한 거부 등 예상치 못한 오류가 나도 앱이 멈추지 않고 실패로 처리.
      return ConnectResult.unknownError;
    }
  }

  // 🆕 [디버깅/복구용 2026-09-05] 기기에 저장된 연결 코드를 지웁니다. 코드를 생성했던
  // 계정과 실제로 학습 기록을 쌓은 계정이 서로 달라 서버가 쓰기를 거부하는 상황일 때,
  // 이 함수로 로컬 코드를 초기화한 뒤 generateLinkCode()를 다시 호출하면 "현재 로그인된
  // 계정" 기준으로 완전히 새 코드가 만들어집니다. (기존 Firestore 문서는 그대로 남지만
  // 더 이상 이 기기와 연결되지 않으므로, 부모님도 새 코드로 다시 연결해야 합니다.)
  static Future<void> clearMyLinkCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scopedKey(_kMyLinkCodeKey));
  }

  // 🆕 [학생] 내 기기에 연결 코드를 저장 (앱 재시작해도 유지됨)
  static Future<void> saveMyLinkCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scopedKey(_kMyLinkCodeKey), code);
  }

  // 🆕 [학생] 저장된 내 연결 코드 조회 (없으면 null — 아직 연결 안 한 상태)
  // 🆕 [버그 수정 2026-09-09] 로컬 캐시가 비어있으면(앱 데이터 삭제 등으로 사라진 경우),
  // 서버의 userLinkCodes/{uid} 매핑에서 되찾아와서 로컬에 다시 저장해둡니다.
  // 이렇게 하면 "서버엔 연결이 있는데 앱만 모르는" 상태를 자동으로 복구합니다.
  static Future<String?> getMyLinkCode() async {
    final prefs = await SharedPreferences.getInstance();
    final String? localCode = prefs.getString(_scopedKey(_kMyLinkCodeKey));
    if (localCode != null && localCode.isNotEmpty) return localCode;

    final String? myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return null;

    try {
      final doc = await _db.collection('userLinkCodes').doc(myUid).get();
      final String? recoveredCode = doc.exists ? (doc.data()?['code'] as String?) : null;
      if (recoveredCode != null && recoveredCode.isNotEmpty) {
        await saveMyLinkCode(recoveredCode); // 다음부턴 다시 로컬에서 바로 찾도록 캐시 복원
        debugPrint('[디버깅] getMyLinkCode: 로컬 캐시 없어서 서버에서 복구함 - $recoveredCode');
        return recoveredCode;
      }
    } catch (e) {
      debugPrint('[FamilyLinkService] getMyLinkCode 서버 조회 실패: $e');
    }
    return null;
  }

  // 🆕 [동기화 주기 설정] 3분에 한 번만 서버로 전송 (서버 부담 최소화, 회원 늘어나면 재조정 예정)
  static const Duration _pushInterval = Duration(minutes: 3);
  static const String _kLastPushKey = 'family_link_last_push_ms';

  // 🆕 [학생→서버] 실제 학습 데이터(별/레벨)를 Firestore에 올림.
  // DkeStars.addStars()가 호출될 때마다 자동으로 이 함수가 실행됨.
  // 단, 마지막 전송 후 3분이 안 지났으면 이번엔 조용히 건너뜀 (로컬 저장은 이미 끝난 상태라 데이터 유실 없음).
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
      return; // 3분 안 지났으면 이번 전송은 건너뜀
    }

    await _db.collection(_collection).doc(code).set({
      'totalStars': totalStars,
      'todayStars': todayStars,
      'level': level,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await prefs.setInt(_kLastPushKey, nowMs);
  }

  // 🆕 [학부모 가시성 확보 2026-09-04] 학생 실명을 links/{code} 문서에도 함께 올립니다.
  // userProfiles/{uid}는 보안 규칙상 본인(uid 일치)만 읽을 수 있어서 부모가 직접 읽을 수
  // 없습니다. 대신 이미 부모에게 읽기 권한이 열려있는 links 문서에 이름을 복사해두면,
  // 보안 규칙을 새로 손대지 않고도 부모 화면에서 자녀 이름을 표시할 수 있습니다.
  static Future<void> pushStudentName(String realName) async {
    final code = await getMyLinkCode();
    if (code == null) return; // 아직 부모와 연결 안 됐으면 조용히 넘어감

    try {
      await _db.collection(_collection).doc(code).set({
        'studentName': realName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FamilyLinkService] pushStudentName 실패(로컬 기능에는 영향 없음): $e');
    }
  }

  // ============================================================================
  // 🆕 [학부모 가시성 확보 2026-09-02] 학생이 타이머 화면에서 "학습 기록"을 저장할 때
  // (timer_screen.dart의 _showStudyInputFieldForm 저장 버튼), 로컬 저장(SharedPreferences)은
  // 그대로 두고 이 함수를 통해 Firestore에도 요약본을 함께 올립니다.
  //
  // 🆕 [무한증가 방지 수정] 예전엔 sessionHistory 배열에 arrayUnion으로 계속 붙이기만 해서,
  // 장기간 누적되면 Firestore 문서 크기 한도(1MiB)에 도달해 이후 모든 쓰기가 조용히
  // 실패할 위험이 있었습니다. 이제 매번 현재 배열을 읽어 최근 _kMaxSessionHistory개만
  // 남기고 트리밍한 뒤 다시 저장합니다 - 오래된 세션은 자동으로 정리되어 한도 걱정 없이
  // 계속 사용할 수 있습니다.
  //
  // ⚠️ [현재 범위] 이 함수는 "서버에 데이터를 올리는 것"까지만 담당합니다.
  // 학부모 대시보드 화면(4개 탭)이 이 sessionHistory 필드를 실제로 읽어서
  // 화면에 표시하는 부분은 아직 별도 작업이 필요합니다.
  static const int _kMaxSessionHistory = 300; // 🆕 최근 300건만 유지 (그 이전 기록은 자동으로 잘려나감)

  static Future<void> pushSessionRecord(Map<String, dynamic> record) async {
    final code = await getMyLinkCode();
    if (code == null) return; // 아직 부모와 연결 안 됐으면 조용히 넘어감 (로컬 저장은 이미 끝난 상태라 데이터 유실 없음)

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
      // 🆕 실패해도 로컬 저장은 이미 끝났으므로 학생 화면/데이터에는 영향 없음. 조용히 무시.
      debugPrint('[FamilyLinkService] pushSessionRecord 실패(로컬 저장은 안전): $e');
    }
  }

  // 🆕 [학부모 가시성 확보 2026-09-04] 시험 성적(주평가/단원평가/중간고사/기말고사/모의고사)도
  // links/{code} 문서에 함께 올립니다. sessionHistory와 동일하게 최근 N개만 유지해서
  // Firestore 문서 크기 한도(1MiB)에 걸리지 않도록 합니다.
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

  // 🆕 [학부모 가시성 확보 2026-09-04] 성적관리(GradeManagementService) 데이터는 세션/평가
  // 기록처럼 이어붙이는 형태가 아니라 "현재 전체 스냅샷"이므로, 변경(추가/수정/삭제/이름변경)이
  // 있을 때마다 통째로 덮어씁니다.
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
  // 🆕 [장학금 방 2026-09-17] 학생 쪽에서 쌓인 월간 기본별/보너스별 요약을
  // links/{code} 문서에 올립니다. scholarship_service.dart가 보너스별이 새로
  // 쌓일 때마다 이 함수를 호출합니다. 다른 push* 함수들과 완전히 동일한 패턴
  // (merge 저장, 실패해도 로컬은 안전, code 없으면 조용히 스킵)입니다.
  //
  // 문서 구조: links/{code}.scholarship.{monthKey} = {
  //   monthlyBaseStars, monthlyBonusStars, bonusBreakdown, updatedAt
  // }
  // 월별로 필드를 분리해두어, 지난달 기록이 이번달 갱신으로 지워지지 않고
  // 부모가 나중에 지난달 내역도 조회할 수 있게 합니다.
  // ============================================================================
  static Future<void> pushScholarshipData({
    required String monthKey,
    required int monthlyBaseStars,
    required int monthlyBonusStars,
    required Map<String, int> bonusBreakdown,
  }) async {
    final code = await getMyLinkCode();
    if (code == null) return; // 아직 부모와 연결 안 됐으면 조용히 넘어감

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

  // 🆕 [장학금 방 2026-09-17] [부모] 이번 달 지급 유형(성장형/도전형/성취형)을 직접 선택해서
  // 저장합니다. pushEmojiToChild/pushEncouragementToChild와 동일하게 부모가 코드를 이미
  // 알고 있는 상태에서 직접 쓰는 패턴을 그대로 따릅니다.
  // typeKey: 'growth' | 'challenge' | 'achievement' (ScholarshipService.typeToKey() 참고)
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

  // ============================================================================
  // 🆕 [부모-자녀 응원 시스템 2026-09-04] 앱의 핵심 취지 - 부모가 보낸 이모지/응원문자가
  // 학생 기기 화면에 실제로 나타나도록 합니다. 답장 기능은 의도적으로 넣지 않습니다
  // (학습 방해 요소를 없애기 위함).
  // ============================================================================

  // [부모] 자녀 코드에 이모지+문구를 전송. 학생이 "확인"을 누르기 전까지 화면에 남아있음.
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

  // [부모] 자녀 코드에 응원 문구를 전송. 학생 화면에 팝업으로 표시됨(답장 없음).
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

  // [학생] 이모지를 "확인"한 뒤 Firestore에서 지움 (내 코드 문서에서만 지우므로 owner 규칙으로 허용됨)
  // ============================================================================
  // 🆕 [요청 2026-09-09] 이모지/응원문자 7일 보관함. 받을 때마다 이 기기(계정별로 구분)에
  // 이력을 남기고, 조회할 때마다 7일 지난 것은 자동으로 정리합니다. 서버가 아니라 이
  // 기기에만 저장되므로 별도 Firestore 비용이 들지 않습니다.
  // ============================================================================
  static const String _kHistoryKey = 'family_encouragement_history';
  static const int _historyRetentionDays = 7;

  // [학생] 이모지/응원문자를 받을 때마다 호출 - 보관함에 추가하고 7일 지난 기록은 정리
  static Future<void> saveEncouragementToHistory({
    required String type, // 'emoji' 또는 'message'
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

  // [학생] 보관함 조회 - 최신순으로 정렬해서 반환. 조회 시점에도 7일 지난 것은 함께 정리.
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
        // 정리된 결과를 그대로 저장해서, 다음부턴 지운 걸 다시 안 읽음
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

  // [학생] 응원 문구 팝업을 닫은 뒤 Firestore에서 지움
  static Future<void> clearPendingMessage() async {
    final code = await getMyLinkCode();
    if (code == null) return;
    try {
      await _db.collection(_collection).doc(code).update({'pendingMessage': FieldValue.delete()});
    } catch (e) {
      debugPrint('[FamilyLinkService] clearPendingMessage 실패: $e');
    }
  }

  // [테스트용, 개발 전용] 학생이 임의 메시지를 Firestore에 저장
  // 🆕 [보안 수정] 운영 빌드(릴리즈)에서는 아무 동작도 하지 않도록 차단했습니다.
  // 누구든 코드만 알면 임의 필드를 써넣을 수 있는 상태였던 문제를 해소합니다.
  static Future<void> sendTestMessage(String code, String message) async {
    if (!kDebugMode) return;
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

// 🆕 [실패 사유 구분] connectWithCodeResult()가 반환하는 상세 결과.
// 화면에서 이 값에 따라 다른 안내 메시지를 보여줄 수 있습니다.
enum ConnectResult {
  success, // 연결 성공 (이미 연결되어 있던 경우 포함)
  codeNotFound, // 존재하지 않는 코드
  capacityFull, // 이미 정원(maxParentsPerChild)이 가득 참
  notLoggedIn, // 로그인이 안 된 상태
  unknownError, // 그 외 예기치 못한 오류(네트워크, 권한 거부 등)
}
