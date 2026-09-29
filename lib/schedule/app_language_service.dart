// ============================================================================
// [일반 플래너 - 10개국어 확장] AppLanguageService
//
// ⚠️ 학생/학부모 앱의 global_lang.dart(DkeLang)와 저장 키('user_country')를
// 공유합니다. 어디서 바꾸든 전체에 반영됩니다.
//
// 🆕 [2026-09-29 변경] 언어 선택의 뜻을 바꿨습니다 (일반 플래너 쪽 화면 기준).
//   - KO (한국어, 기본) : 한글 위주. 큰 제목·중간 제목만 영문+한글, 입력칸 이름 등은 한글만
//   - EN (English)      : 영어만
//   - 10개 외국어        : 그 언어만 (지금과 같음)
// 예전에는 "기본" 버튼이 EN으로 저장되어 KO와 EN이 둘 다 "영+한 병기"였습니다.
// 그래서 예전에 EN이 저장된 기기는 업데이트 후 첫 실행 때 딱 한 번 KO로 옮겨서,
// 갑자기 영어만 나오는 일이 없게 했습니다.
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageService extends ChangeNotifier {
  static final AppLanguageService _instance = AppLanguageService._internal();
  factory AppLanguageService() => _instance;
  AppLanguageService._internal();

  // 12개국 지원 목록 - 앱 전체 기준
  static const List<String> supportedLanguages = [
    'KO', 'EN', 'JA', 'ZH', 'FR', 'DE', 'RU', 'AR', 'HI', 'VI', 'ES', 'TH',
  ];

  // 10개 외국어 코드 (KO/EN 제외 나머지)
  static const List<String> foreignLanguageCodes = ['JA', 'ZH', 'FR', 'DE', 'RU', 'AR', 'HI', 'VI', 'ES', 'TH'];

  // 언어 선택 화면에 보여줄 이름
  static const Map<String, String> languageDisplayNames = {
    'KO': '한국어 (기본)', // 🆕 [2026-09-29]
    'EN': 'English (영어만)', // 🆕 [2026-09-29] 예전: 'English + 한글 (기본)'
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

  static const String _kPrefsKey = 'user_country';
  // 🆕 [2026-09-29] 예전 "기본(EN)" 저장값을 KO로 한 번만 옮겼는지 표시
  static const String _kKoDefaultMigratedKey = 'lang_ko_default_migrated_v1';

  String current = 'KO';

  // 🆕 [2026-09-29] 한국어(기본) 모드 = KO만. (예전엔 KO 또는 EN)
  // 이 값이 true면 제목은 영문+한글 2줄, BiInline 등은 예전과 같이 병기
  bool get isDefault => current == 'KO';

  // 🆕 [2026-09-29] 영어만 보여주는 모드
  bool get isEnglishOnly => current == 'EN';

  bool get isForeignSelected => foreignLanguageCodes.contains(current);

  // 마이페이지(DkeLang) 등 다른 화면에서 바꾼 언어를 2초마다 확인해서 반영
  Timer? _syncTimer;

  void _startAutoSync() {
    if (_syncTimer != null) return;
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? saved = prefs.getString(_kPrefsKey);
        if (saved == null || saved.isEmpty) return;
        final String normalized = saved.toUpperCase();
        if (supportedLanguages.contains(normalized) && normalized != current) {
          current = normalized;
          notifyListeners();
        }
      } catch (e) {}
    });
  }

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? saved = prefs.getString(_kPrefsKey);
      if (saved != null && saved.isNotEmpty) {
        final String normalized = saved.toUpperCase();
        current = supportedLanguages.contains(normalized) ? normalized : 'KO';
      }

      // 🆕 [2026-09-29] 예전 "기본" 버튼은 EN으로 저장됐으므로, 업데이트 후 첫 실행 때
      // 딱 한 번만 EN → KO로 옮김 (이후 사용자가 English를 고르면 그대로 존중)
      final bool migrated = prefs.getBool(_kKoDefaultMigratedKey) ?? false;
      if (!migrated) {
        if (current == 'EN') {
          current = 'KO';
          await prefs.setString(_kPrefsKey, 'KO');
        }
        await prefs.setBool(_kKoDefaultMigratedKey, true);
      }
    } catch (e) {
      current = 'KO';
    }
    _startAutoSync();
  }

  // 하위호환: 예전에 load()로 부르던 곳도 그대로 작동
  Future<void> load() => initialize();

  Future<void> setLanguage(String langCode) async {
    final String normalized = langCode.toUpperCase();
    current = supportedLanguages.contains(normalized) ? normalized : 'KO'; // 🆕 모르는 값이면 한국어로
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKey, current);
  }

  // 아랍어 RTL(오른쪽에서 왼쪽) 판단
  bool get isRtl => current == 'AR';
}

// 앱 전체에서 공유하는 단일 인스턴스
final appLanguage = AppLanguageService();
