// exercise_consent_service.dart
//
// 🆕 [건강정보 수집 동의] 운동 기록 기능은 심박수, 몸무게, 걸음수/운동시간
// (폰 센서 또는 연동한 워치로부터)처럼 건강과 관련된 정보를 다룬다. 이런
// 정보를 다루기 전에 사용자에게 명확히 안내하고 동의를 받아야 한다는 원칙에
// 따라, [운동] 섹션에 최초로 들어올 때 딱 한 번 동의를 받는다.
//
// ⚠️ [저장 원칙] 동의 여부는 이 기기 안(SharedPreferences)에만 저장된다.
// 실제 건강정보(심박수/몸무게/걸음수) 자체도 마찬가지로 전부 기기 안에만
// 저장되며 서버로 전송되지 않는다 - 이 사실을 동의 화면에 명시한다.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'exercise_theme.dart';

class ExerciseConsentService {
  ExerciseConsentService._();

  static const String _kConsentKey = 'gke_exercise_health_data_consent';
  static const String _kConsentDateKey = 'gke_exercise_health_data_consent_date';

  static Future<bool> hasConsented() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kConsentKey) ?? false;
  }

  static Future<void> setConsented(bool consented) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kConsentKey, consented);
    if (consented) {
      await prefs.setString(_kConsentDateKey, DateTime.now().toIso8601String());
    }
  }

  /// 🆕 [동의 철회] 사용자가 언제든 동의를 취소할 수 있어야 한다는 원칙.
  /// 철회하면 다음에 [운동] 섹션에 들어올 때 동의 화면이 다시 뜬다.
  static Future<void> revokeConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kConsentKey);
    await prefs.remove(_kConsentDateKey);
  }

  static Future<String?> getConsentDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kConsentDateKey);
  }

  /// 🆕 [동의 화면] [운동] 섹션 최초 진입 시 표시. 동의해야 true를 반환하고,
  /// 동의 안 하면 false를 반환해서 호출한 쪽에서 운동 섹션 진입을 막는다.
  static Future<bool> showConsentDialog(BuildContext context) async {
    final bool? agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: LuxuryDialogFrame(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                luxuryDialogHeader(
                  icon: Icons.health_and_safety_outlined,
                  en: 'HEALTH DATA CONSENT',
                  ko: '건강정보 수집 동의',
                  translations: const {
                    'JA': '健康情報収集への同意', 'ZH': '健康信息收集同意', 'FR': 'Consentement aux données de santé',
                    'DE': 'Einwilligung zu Gesundheitsdaten', 'RU': 'Согласие на сбор данных о здоровье',
                    'AR': 'الموافقة على جمع البيانات الصحية', 'HI': 'स्वास्थ्य डेटा सहमति',
                    'VI': 'Đồng ý thu thập dữ liệu sức khỏe', 'ES': 'Consentimiento de datos de salud',
                    'TH': 'ยินยอมเก็บข้อมูลสุขภาพ',
                  },
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: ExerciseTheme.pageBg, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    '운동 기록 기능은 아래와 같은 건강 관련 정보를 다룹니다:\n\n'
                        '• 심박수 (평균/최고, 직접 입력 시)\n'
                        '• 몸무게 (칼로리 계산용, 선택 입력)\n'
                        '• 걸음수·운동시간 (폰 센서 또는 연동한 워치로부터 자동 수집)\n\n'
                        '위 정보는 전부 이 기기 안에만 저장되며, 외부 서버로 전송되거나 '
                        '제3자와 공유되지 않습니다. 동의는 언제든 설정에서 철회할 수 있고, '
                        '철회 시 저장된 정보도 삭제할 수 있습니다.\n\n'
                        '동의하셔야 운동 기록 기능을 사용할 수 있습니다.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('동의 안 함', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ExerciseTheme.brandGolden,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('동의합니다', style: TextStyle(color: ExerciseTheme.pageBg, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final bool result = agreed ?? false;
    if (result) await setConsented(true);
    return result;
  }
}
