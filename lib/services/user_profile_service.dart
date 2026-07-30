import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// 🆕 [실사용 전환 인프라] 2026-07-29 신규 생성 — 회원 프로필 "창구" 서비스
// -----------------------------------------------------------------------------
// paywall_service.dart와 동일한 원칙: 화면 코드는 이 파일을 통해서만 회원 정보를
// 읽고 쓰고, 이 파일 내부가 지금은 SharedPreferences(로컬)를 쓰다가 나중에
// Firebase로 바뀌어도 화면 코드는 단 한 줄도 다시 손댈 필요가 없습니다.
//
// 🚨 [현재의 한계 — 반드시 이해하고 있을 것]
// 지금은 서버가 없으므로:
//   - 이 정보는 "이 폰 안에서만" 유효합니다. 다른 기기에서는 안 보입니다.
//   - 실제 이메일 인증 발송도 안 됩니다 (signup_screen.dart의 인증 버튼은 여전히 UI 목업).
//   - 부모-자녀가 서로 다른 기기라면 실제 연결이 안 됩니다 (같은 기기 안에서만 시뮬레이션됨).
// Firebase 연동 후에는 아래 함수들의 "내부 구현"만 SharedPreferences → Firestore
// 호출로 교체하면 되고, 함수 이름/사용법은 그대로 유지할 계획입니다.
// =============================================================================

class DkeUserProfile {
  static const String _kUserNameKey = 'dke_user_real_name';
  static const String _kUserTypeKey = 'dke_user_type'; // '학생' / '학부모' / '일반'
  static const String _kChildEmailKey = 'dke_linked_child_email'; // 학부모 계정일 때만 사용
  static const String _kParentEmailKey = 'dke_linked_parent_email'; // 학생 계정일 때만 사용(14세 미만)
  static const String _kIsDeveloperKey = 'dke_is_developer_mode';

  // ===========================================================================
  // 1) 가입 완료 시점에 실제 입력한 이름/유형/연동 정보를 저장
  //    (signup_screen.dart의 실제 "가입 완료" 처리 지점에서 호출 예정)
  // ===========================================================================
  static Future<void> saveProfileOnSignup({
    required String realName,
    required String userType, // '학생' / '학부모' / '일반'
    String? childEmail,
    String? parentEmail,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUserNameKey, realName);
      await prefs.setString(_kUserTypeKey, userType);
      if (childEmail != null && childEmail.isNotEmpty) {
        await prefs.setString(_kChildEmailKey, childEmail);
      }
      if (parentEmail != null && parentEmail.isNotEmpty) {
        await prefs.setString(_kParentEmailKey, parentEmail);
      }
    } catch (e) {
      // 저장 실패해도 앱 흐름을 막지 않음 (다음 진입 시 재시도 가능)
    }
  }

  // ===========================================================================
  // 2) 현재 로그인된(이 기기에 저장된) 사용자의 실제 이름 조회
  //    - 아직 가입 기록이 없으면 null 반환 (화면에서 null이면 안내용 기본 문구 표시하도록 처리)
  // ===========================================================================
  static Future<String?> getRealName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? name = prefs.getString(_kUserNameKey);
      return (name != null && name.isNotEmpty) ? name : null;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getUserType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kUserTypeKey);
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getLinkedChildEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kChildEmailKey);
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getLinkedParentEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kParentEmailKey);
    } catch (e) {
      return null;
    }
  }

  // ===========================================================================
  // 3) 🆕 [개발자 만능 권한 모드]
  // -----------------------------------------------------------------------------
  // 🚨 [보안/아동보호 필수 경고] 이 기능은 개발/테스트 전용입니다.
  //    아래 kDeveloperMasterEmail에 등록된 이메일로 가입/로그인하면 보호자 인증,
  //    나이 제한, 유료화(Paywall) 등 모든 검증을 건너뜁니다.
  //    ⚠️ 스토어에 정식 출시하기 전에는 반드시:
  //       (A) kDeveloperMasterEmail을 실제 값이 아닌 빈 문자열("")로 바꾸거나
  //       (B) 이 클래스 전체를 특정 기기 고유ID 기반의 더 강력한 방식으로 교체할 것.
  //    이 상수가 실제 이메일 값을 가진 채로 출시되면, 그 이메일을 알아내는 사람은
  //    누구나 미성년자 보호 장치를 우회할 수 있게 되어 심각한 보안/법적 위험이 됩니다.
  // ===========================================================================
  static const String kDeveloperMasterEmail = ""; // 🆕 [입력 필요] 개발 중에만 실제 이메일을 넣고, 출시 전 반드시 다시 빈 문자열로 되돌릴 것

  static bool isDeveloperEmail(String email) {
    if (kDeveloperMasterEmail.isEmpty) return false; // 마스터 이메일이 설정 안 되어 있으면 항상 false (안전 기본값)
    return email.trim().toLowerCase() == kDeveloperMasterEmail.trim().toLowerCase();
  }

  // 가입/로그인 시점에 입력된 이메일이 개발자 이메일이면 개발자 모드를 활성화하고 영구 저장
  static Future<void> activateDeveloperModeIfMatches(String email) async {
    if (!isDeveloperEmail(email)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsDeveloperKey, true);
    } catch (e) {
      // 무시 (다음 진입 시 재시도)
    }
  }

  // 화면 쪽에서 "지금 개발자 모드인지" 확인할 때 사용. true면 보호자 인증/나이제한/유료화 전부 건너뛰기 가능.
  static Future<bool> isDeveloperMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kIsDeveloperKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // 테스트 중 개발자 모드를 끄고 싶을 때(일반 사용자 흐름 재테스트 용)
  static Future<void> deactivateDeveloperMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsDeveloperKey, false);
    } catch (e) {
      // 무시
    }
  }
}
