import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🆕 [본인 데이터만 접근] 소유자 확인용
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // 🆕 [학부모 가시성 확보] debugPrint 사용

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

  // 🆕 [다중 학부모 지원 2026-09-01] 한 자녀(코드)에 연결 가능한 부모 최대 인원.
  // 지금은 무료로 3명까지 열어두고, 나중에 결제 시스템을 붙일 때 이 상수를
  // "무료 1명 + 유료 결제 시 추가"처럼 사용자별 조건부 값으로 바꾸면 됨.
  // ⚠️ Firestore 보안 규칙(/links/{code} allow update)에도 반드시 같은 숫자(3)로
  // 맞춰둬야 함 — 클라이언트 체크는 UX용이고, 실제 강제는 서버 규칙이 담당.
  static const int maxParentsPerChild = 3;

  // 🆕 [버그 수정 2026-09-01] [부모] 코드를 입력해서 연결 시도. 성공하면 true 반환 (내 자녀 목록에도 자동 추가)
  //
  // 예전 문제: 앱을 지웠다 재설치한 뒤 "예전에 이미 연결했던 코드"를 다시 입력하면,
  // Firestore 보안 규칙이 "코드 상태가 waiting일 때만 update 허용"하기 때문에
  // 이미 connected 상태인 코드에는 update 자체가 거부(PERMISSION_DENIED)됨.
  // 게다가 이 함수에 try/catch가 없어서 예외가 그대로 위로 전파되고,
  // 호출부(화면)의 로딩 상태가 안 풀려서 "버튼이 먹통"인 것처럼 보였음.
  //
  // 수정 내용:
  // 1) update 시도 전에 먼저 문서를 읽어서, 내 uid가 이미 parentUids에 있으면
  //    서버에 다시 쓰지 않고 바로 성공 처리 (재설치 후 재연결 시나리오 해결).
  // 2) 아직 연결 안 된 새로운 부모라면, 현재 인원이 maxParentsPerChild(3명) 미만일
  //    때만 추가 연결을 허용 (다중 학부모 지원).
  // 3) update 호출 전체를 try/catch로 감싸서, 정말 예상치 못한 오류가 나도
  //    앱이 멈추지 않고 false를 반환하도록 방어.
  static Future<bool> connectWithCode(String code) async {
    final String? myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return false; // 로그인 안 된 상태면 연결 불가 (본인 확인 불가능)

    final docRef = _db.collection(_collection).doc(code);

    try {
      final doc = await docRef.get();
      if (!doc.exists) {
        return false; // 존재하지 않는 코드
      }

      // 🆕 [버그 수정 핵심] 이미 내가 연결되어 있는 코드라면, 서버에 다시 쓰지 않고 바로 성공 처리.
      // (재설치 후 같은 코드를 다시 입력하는 경우가 여기 해당됨 — 보안 규칙 충돌을 원천 회피)
      final List<dynamic> existingParentUids =
          (doc.data()?['parentUids'] as List<dynamic>?) ?? [];
      if (existingParentUids.contains(myUid)) {
        await addLinkedCode(code);
        return true;
      }

      // 🆕 [다중 학부모 지원] 새로운 부모인데 이미 정원이 찼으면 연결 거부
      if (existingParentUids.length >= maxParentsPerChild) {
        return false;
      }

      await docRef.update({
        'status': 'connected',
        'connectedAt': FieldValue.serverTimestamp(),
        'parentUids': FieldValue.arrayUnion([myUid]), // 🆕 [본인 데이터만 접근] 나를 허용 목록에 추가
      });
      await addLinkedCode(code);
      return true;
    } catch (e) {
      // 🆕 [버그 수정] 권한 거부 등 예상치 못한 오류가 나도 앱이 멈추지 않고 실패로 처리.
      return false;
    }
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

  // ============================================================================
  // 🆕 [학부모 가시성 확보 2026-09-02] 학생이 타이머 화면에서 "학습 기록"을 저장할 때
  // (timer_screen.dart의 _showStudyInputFieldForm 저장 버튼), 로컬 저장(SharedPreferences)은
  // 그대로 두고 이 함수를 통해 Firestore에도 요약본을 함께 올립니다.
  //
  // ⚠️ [설계 메모] 하루/건마다 문서를 따로 만들지 않고, 학생 코드 문서 하나 안의
  // 배열 필드(sessionHistory)에 계속 이어붙이는 방식입니다. 이렇게 하면 학부모가
  // 나중에 기록을 조회할 때 Firestore 읽기 1회로 전체 이력을 다 가져올 수 있어
  // 비용이 절감됩니다 (이미 합의된 설계 방향과 동일).
  //
  // ⚠️ [현재 범위] 이 함수는 "서버에 데이터를 올리는 것"까지만 담당합니다.
  // 학부모 대시보드 화면(4개 탭)이 이 sessionHistory 필드를 실제로 읽어서
  // 화면에 표시하는 부분은 아직 별도 작업이 필요합니다 (기존에 로컬 데이터만
  // 읽던 4개 탭을 Firestore 기반으로 재설계하는 큰 작업과 함께 진행 예정).
  static Future<void> pushSessionRecord(Map<String, dynamic> record) async {
    final code = await getMyLinkCode();
    if (code == null) return; // 아직 부모와 연결 안 됐으면 조용히 넘어감 (로컬 저장은 이미 끝난 상태라 데이터 유실 없음)

    try {
      await _db.collection(_collection).doc(code).set({
        'sessionHistory': FieldValue.arrayUnion([record]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // 🆕 실패해도 로컬 저장은 이미 끝났으므로 학생 화면/데이터에는 영향 없음. 조용히 무시.
      debugPrint('[FamilyLinkService] pushSessionRecord 실패(로컬 저장은 안전): $e');
    }
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
