// ============================================================================
// [일반 플래너 - 10개국어 확장] AppLanguageService
//
// ⚠️ [중요 수정] 학생/학부모 앱의 실제 global_lang.dart(DkeLang)를 직접
// 확인한 뒤, 그 구조에 정확히 맞춰 다시 작성했습니다.
// - 저장 키를 'user_country'로 통일 → 앱 전체(일반/학생/학부모)가 언어
//   설정을 공유합니다. 어디서 바꾸든 전체에 반영됩니다.
// - 기본값은 가상의 'DEFAULT' 값이 아니라, DkeLang과 동일하게 실제 'KO'를
//   사용합니다. "영+한 병기 모드"는 current가 KO 또는 EN일 때로 판단합니다
//   (DkeLang의 isForeignSelected와 동일한 방식).
// ============================================================================

import 'dart:async'; // 🆕 [연결 버그 수정] Timer 사용을 위해 추가
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageService extends ChangeNotifier {
  static final AppLanguageService _instance = AppLanguageService._internal();
  factory AppLanguageService() => _instance;
  AppLanguageService._internal();

  // 🆕 [DkeLang과 동일] 12개국 지원 목록 - 앱 전체 기준
  static const List<String> supportedLanguages = [
    'KO', 'EN', 'JA', 'ZH', 'FR', 'DE', 'RU', 'AR', 'HI', 'VI', 'ES', 'TH',
  ];

  // 🆕 [DkeLang과 동일] 10개 외국어 코드 (KO/EN 제외 나머지)
  static const List<String> foreignLanguageCodes = ['JA', 'ZH', 'FR', 'DE', 'RU', 'AR', 'HI', 'VI', 'ES', 'TH'];

  // 🆕 [10개국어 확장] 언어 선택 화면에 보여줄 이름
  static const Map<String, String> languageDisplayNames = {
    'EN': 'English + 한글 (기본)',
    'JA': '日本語 (일본어)',
    'ZH': '中文 (중국어)',
    'FR': 'Français (프랑스어)',
    'DE': 'Deutsch (독일어)',
    'RU': 'Русский (러시아어)',
    'AR': 'العربية (아랍어)',
    'HI': 'हिन्दी (힌디어)',
    'VI': 'Tiếng Việt (베트남어)',
    'ES': 'Español (스페인어)',
    'TH': 'ไทย (태국어)',
  };

  // 🆕 [DkeLang과 동일] 저장 키 - 학생/학부모 앱과 완전히 동일한 키를 써서
  // 앱 전체가 언어 설정을 하나로 공유하도록 함
  static const String _kPrefsKey = 'user_country';

  // 🆕 [DkeLang과 동일] 기본값은 'KO' (가상의 DEFAULT 값 사용 안 함)
  String current = 'KO';

  // 🆕 [DkeLang의 isForeignSelected와 동일한 개념] KO 또는 EN이면 영+한 병기 모드
  bool get isDefault => current == 'KO' || current == 'EN';
  bool get isForeignSelected => foreignLanguageCodes.contains(current);

  // 🆕 [연결 버그 수정] DkeLang(마이페이지)은 리스너 알림 기능이 없는 평범한
  // 클래스라서, 마이페이지에서 언어를 바꿔도 이 서비스가 그 순간 자동으로
  // 알아채지 못합니다. 그래서 짧은 주기로 저장된 값을 다시 확인해서, 바뀌었으면
  // 즉시 반영 + 화면에 알림(notifyListeners)을 보내는 방식으로 해결합니다.
  Timer? _syncTimer;

  void _startAutoSync() {
    if (_syncTimer != null) return; // 이미 돌고 있으면 중복 실행 방지
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? saved = prefs.getString(_kPrefsKey);
        if (saved == null || saved.isEmpty) return;
        final String normalized = saved.toUpperCase();
        if (supportedLanguages.contains(normalized) && normalized != current) {
          current = normalized; // 🆕 마이페이지 등 다른 화면에서 바꾼 값을 감지해서 반영
          notifyListeners();
        }
      } catch (e) {}
    });
  }

  // 🆕 [DkeLang과 동일한 함수명] initialize() - 앱 시작 시 저장된 언어 불러옴
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? saved = prefs.getString(_kPrefsKey);
      if (saved != null && saved.isNotEmpty) {
        final String normalized = saved.toUpperCase();
        current = supportedLanguages.contains(normalized) ? normalized : 'KO';
      }
    } catch (e) {
      current = 'KO';
    }
    _startAutoSync(); // 🆕 최초 초기화 시 자동 동기화 시작
  }

  // 🆕 [하위호환] 기존에 load()로 호출해둔 곳이 있어도 계속 작동하도록 별칭 유지
  Future<void> load() => initialize();

  // 🆕 [DkeLang과 동일] 언어 변경 - 저장하고, 구독 중인 모든 화면에 즉시 알림
  Future<void> setLanguage(String langCode) async {
    final String normalized = langCode.toUpperCase();
    current = supportedLanguages.contains(normalized) ? normalized : 'EN';
    notifyListeners(); // 🆕 이 알림 덕분에 화면을 새로고침하지 않아도 즉시 언어가 바뀜
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKey, current);
  }

  // 🆕 [DkeLang과 동일] 아랍어 RTL(오른쪽에서 왼쪽) 판단
  bool get isRtl => current == 'AR';
}

// 🆕 앱 전체에서 공유하는 단일 인스턴스
final appLanguage = AppLanguageService();
