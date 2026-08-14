// ============================================================================
// [일반 플래너 - 10개국어 확장 1단계] LanguageSettingsScreen
// 언어를 선택하는 화면입니다. 기본값(영어+한글) + 10개 외국어 중 하나를
// 골라서, 앱 전체 화면의 표시 언어를 즉시 바꿀 수 있습니다.
// (BiTitle/BiInline이 언어 변경을 자동으로 감지해서 다시 그려지므로,
// 앱을 재시작할 필요 없이 이 화면에서 고르는 즉시 반영됩니다.)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_language_service.dart';
import 'bilingual_text.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  @override
  Widget build(BuildContext context) {
    final List<String> allOptions = ['EN', ...AppLanguageService.foreignLanguageCodes]; // 🆕 [수정] kDefault 대신 실제 'EN' 값 사용

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: const BiTitle(en: 'LANGUAGE', ko: '언어 설정', enSize: 18, koSize: 13),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allOptions.length,
        itemBuilder: (context, index) {
          final code = allOptions[index];
          // 🆕 [수정] 'EN' 항목은 실제 저장값이 KO든 EN이든(둘 다 병기모드) 선택된 것으로 표시
          final bool isSelected = code == 'EN' ? appLanguage.isDefault : appLanguage.current == code;
          return InkWell(
            onTap: () async {
              await appLanguage.setLanguage(code);
              if (mounted) setState(() {});
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? _brandGolden.withOpacity(0.15) : _containerBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? _brandGolden : Colors.white12, width: isSelected ? 1.4 : 1),
              ),
              child: Row(
                children: [
                  Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? _brandGolden : Colors.white38, size: 20),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      AppLanguageService.languageDisplayNames[code] ?? code,
                      style: GoogleFonts.notoSansKr(color: isSelected ? Colors.white : Colors.white70, fontSize: 15, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
