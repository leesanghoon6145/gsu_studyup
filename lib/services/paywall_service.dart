import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// 🆕 [결제/Paywall 인프라] 2026-07-29 신규 생성
// -----------------------------------------------------------------------------
// 이 파일은 어떤 기존 화면에도 아직 연결되어 있지 않습니다. (상훈님 요청: "코딩만 해두고
// 화면에는 안 보였으면 함") 지금은 그냥 독립적으로 존재만 하는 서비스 파일입니다.
//
// 나중에 실제로 사용하실 때는 딱 두 곳만 연결하시면 됩니다:
//
// 1) 회원가입이 "진짜로 완료되는 시점" (예: signup_screen.dart의 TermsAgreementScreen
//    안에 있는 'SIGNUP COMPLETE' 버튼 onPressed 안, 스낵바 뜨기 직전 등) 딱 한 줄 추가:
//        await DkePaywall.recordSignupIfFirstTime();
//
// 2) VIP 전용 기능(예: timer_screen.dart의 VIP 크라운 애니메이션, 특정 프리미엄 화면 등)을
//    잠그고 싶은 곳에서:
//        final bool unlocked = await DkePaywall.isVipUnlocked();
//        if (unlocked) { /* VIP 기능 보여주기 */ } else { /* 잠금 화면/결제 유도 */ }
//
// 지금은 _isPaywallActive = false 로 꺼져 있어서, 2)를 어디에 연결해두어도
// isVipUnlocked()는 항상 true(무료 개방)를 반환합니다. 실제 스토어 결제 연동이 끝나면
// 이 파일의 _isPaywallActive 값 하나만 true로 바꾸면 앱 전체에 자동으로 적용됩니다.
// (화면 코드는 그 시점에 전혀 다시 손댈 필요 없음)
// =============================================================================

class DkePaywall {
  // 🔑 [마스터 스위치] 지금은 false로 꺼져있어 전체 유저가 모든 기능을 무료로 이용합니다.
  // 실제 결제(Google Play Billing / Apple StoreKit) 연동을 마친 뒤, 이 값 하나만 true로
  // 바꾸면 아래 isVipUnlocked() 로직이 실제로 작동하기 시작합니다.
  static const bool _isPaywallActive = false;

  // 🆕 [입력 필요] 창립 멤버(얼리버드) 20% 평생 할인 마감 기준일.
  // 이 날짜 이전에 가입을 완료한 사용자는 영구적으로 20% 할인 대상자로 기록됩니다.
  // 실제 스토어 출시일이 확정되면 이 날짜를 그에 맞게 조정해주세요.
  static final DateTime earlyAdopterCutoffDate = DateTime(2026, 12, 31);

  // 🆕 [입력 필요] 창립 멤버 영구 할인율 (20% = 0.20)
  static const double earlyAdopterDiscountRate = 0.20;

  // 🆕 무료체험 기간(일). 가입일 기준으로 계산되므로, 출시 첫날 가입자나 한 달 뒤
  // 가입자나 동일하게 30일씩 공평하게 체험할 수 있습니다.
  static const int freeTrialDays = 30;

  static const String _kSignupTimestampKey = 'dke_paywall_signup_timestamp';
  static const String _kIsEarlyAdopterKey = 'dke_paywall_is_early_adopter';

  // ===========================================================================
  // 1) 가입 시점 기록 (최초 1회만 저장됨 - 이미 기록되어 있으면 아무 동작 안 함)
  // ===========================================================================
  static Future<void> recordSignupIfFirstTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? existing = prefs.getInt(_kSignupTimestampKey);
      if (existing != null) return; // 이미 가입 시점이 기록되어 있으면 덮어쓰지 않음(중복가입/재로그인 대비)

      final DateTime now = DateTime.now();
      await prefs.setInt(_kSignupTimestampKey, now.millisecondsSinceEpoch);

      // 얼리버드 마감일 이전 가입이면 영구 할인 대상으로 기록
      final bool qualifiesForEarlyAdopter = now.isBefore(earlyAdopterCutoffDate);
      await prefs.setBool(_kIsEarlyAdopterKey, qualifiesForEarlyAdopter);
    } catch (e) {
      // 저장 실패 시에도 앱 흐름에 영향 주지 않도록 조용히 무시(다음 앱 실행 시 재시도됨)
    }
  }

  // ===========================================================================
  // 2) 가입일로부터 경과된 일수 계산 (아직 가입 기록이 없으면 null 반환)
  // ===========================================================================
  static Future<int?> daysSinceSignup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? ts = prefs.getInt(_kSignupTimestampKey);
      if (ts == null) return null;
      final DateTime signupDate = DateTime.fromMillisecondsSinceEpoch(ts);
      return DateTime.now().difference(signupDate).inDays;
    } catch (e) {
      return null;
    }
  }

  // ===========================================================================
  // 3) 아직 30일 무료체험 기간 안인지 여부
  // ===========================================================================
  static Future<bool> isInFreeTrial() async {
    final int? days = await daysSinceSignup();
    if (days == null) return true; // 가입 기록이 아직 없으면(예: 온보딩 전) 우선 체험 가능한 것으로 취급
    return days < freeTrialDays;
  }

  // ===========================================================================
  // 4) 남은 무료체험 일수 (화면에 "D-7" 같은 안내 문구를 나중에 붙일 때 사용)
  // ===========================================================================
  static Future<int> remainingTrialDays() async {
    final int? days = await daysSinceSignup();
    if (days == null) return freeTrialDays;
    final int remaining = freeTrialDays - days;
    return remaining > 0 ? remaining : 0;
  }

  // ===========================================================================
  // 5) 창립 멤버(얼리버드) 20% 영구 할인 대상 여부
  // ===========================================================================
  static Future<bool> isEarlyAdopter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kIsEarlyAdopterKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // 6) 이 사용자에게 적용할 할인율 (창립 멤버면 0.20, 아니면 0.0)
  //    나중에 결제 화면에서 "정가 대비 X% 할인가"를 계산할 때 그대로 사용 가능
  // ===========================================================================
  static Future<double> discountRateForUser() async {
    final bool earlyAdopter = await isEarlyAdopter();
    return earlyAdopter ? earlyAdopterDiscountRate : 0.0;
  }

  // ===========================================================================
  // 7) 🌟 VIP 기능 접근 가능 여부 — 화면 쪽에서 실제로 부를 함수는 사실상 이것 하나면 충분함
  //    - 마스터 스위치(_isPaywallActive)가 꺼져 있으면: 무조건 true (전원 무료 개방)
  //    - 켜져 있으면: 무료체험 기간 안이거나, 유료 구독중이면 true
  //    🚨 [출시 전 필수 작업] 아래 '유료 구독 여부 확인' 부분은 실제 Google Play Billing /
  //       Apple StoreKit 연동 후 실제 구독 상태 조회 로직으로 교체해야 합니다. 지금은
  //       자리만 마련해둔 상태이며, 결제 연동 전까지는 이 부분이 호출될 일이 없습니다
  //       (마스터 스위치가 꺼져 있으므로 항상 위에서 true로 먼저 반환됨).
  // ===========================================================================
  static Future<bool> isVipUnlocked() async {
    if (!_isPaywallActive) return true;

    final bool trial = await isInFreeTrial();
    if (trial) return true;

    // TODO(결제 연동 시): 아래를 실제 구독 상태 확인 로직으로 교체
    final bool hasActiveSubscription = await _checkActiveSubscriptionPlaceholder();
    return hasActiveSubscription;
  }

  // 🚨 [결제 연동 전까지 사용되지 않는 자리 표시자] 항상 false를 반환합니다.
  static Future<bool> _checkActiveSubscriptionPlaceholder() async {
    return false;
  }
}
