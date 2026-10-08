// exercise_personal_info_screen.dart
//
// 🆕 [개인정보 입력 화면] 운동 칼로리 계산 정확도를 위한 몸무게 입력 화면.
// 다른 개인정보(키, 나이 등)가 나중에 필요해지면 이 화면 하나에 계속
// 추가하면 됨 - "운동 관련 개인정보"를 모아두는 단일 창구.
//
// ⚠️ [투명성] 이 값이 정확히 어디에 어떻게 쓰이는지, 서버로 전송되지
// 않는다는 것을 화면에 명시적으로 안내함.
// 🆕 [2026-10-08] 모든 안내 · 단추 · 창 글자를 12개 언어로

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'exercise_theme.dart';
import 'exercise_profile_service.dart';
import 'exercise_screen_text.dart'; // 🆕 [2026-10-08] 글자 12개 언어

class ExercisePersonalInfoScreen extends StatefulWidget {
  const ExercisePersonalInfoScreen({super.key});

  @override
  State<ExercisePersonalInfoScreen> createState() => _ExercisePersonalInfoScreenState();
}

class _ExercisePersonalInfoScreenState extends State<ExercisePersonalInfoScreen> {
  final TextEditingController _weightController = TextEditingController();
  bool _isLoading = true;
  bool _hasSavedWeight = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await ExerciseProfileService.getWeightKg();
    if (!mounted) return;
    setState(() {
      if (saved != null) {
        _weightController.text = saved.toStringAsFixed(1);
        _hasSavedWeight = true;
      }
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    final double? weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0 || weight > 300) {
      ExerciseTheme.showLuxeSnackBar(context, exText('piBad'));
      return;
    }
    await ExerciseProfileService.setWeightKg(weight);
    setState(() => _hasSavedWeight = true);
    if (mounted) {
      ExerciseTheme.showLuxeSnackBar(context, exText('piSaved'));
    }
  }

  Future<void> _clear() async {
    final bool confirmed = await ExerciseTheme.showLuxeConfirmDialog(
      context,
      title: exText('piDelTitle'),
      message: exText('piDelMsg', {'w': ExerciseProfileService.defaultWeightKg.toInt()}),
      confirmLabel: exText('del'),
      isDestructive: true,
    );
    if (!confirmed) return;
    await ExerciseProfileService.clearWeightKg();
    if (!mounted) return;
    setState(() {
      _weightController.clear();
      _hasSavedWeight = false;
    });
    ExerciseTheme.showLuxeSnackBar(context, exText('piDeleted'));
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExerciseTheme.pageBg,
      appBar: ExerciseTheme.biAppBar(
        en: 'PERSONAL INFO',
        ko: '개인정보 (칼로리 계산용)',
        enSize: 17,
        koSize: 15,
        translations: const {
          'JA': '個人情報（カロリー計算用）', 'ZH': '个人信息（用于卡路里计算）', 'FR': 'Infos personnelles (calcul des calories)',
          'DE': 'Persönliche Daten (für Kalorienberechnung)', 'RU': 'Личные данные (для расчёта калорий)',
          'AR': 'معلومات شخصية (لحساب السعرات)', 'HI': 'व्यक्तिगत जानकारी (कैलोरी गणना हेतु)',
          'VI': 'Thông tin cá nhân (tính calo)', 'ES': 'Información personal (cálculo de calorías)',
          'TH': 'ข้อมูลส่วนตัว (สำหรับคำนวณแคลอรี่)',
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: ExerciseTheme.brandGolden))
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 🆕 [투명성 안내] 이 정보가 어디에 어떻게 쓰이는지 명시
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ExerciseTheme.brandGolden.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ExerciseTheme.brandGolden.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_outline_rounded, color: ExerciseTheme.brandGolden, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    exText('piInfo', {'w': ExerciseProfileService.defaultWeightKg.toInt()}),
                    style: ExerciseTheme.bodyStyle(size: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 🆕 [2026-10-08] 한국어 = 위 영문 · 아래 한글 / 그 외 = 그 언어만
          if (appLanguage.isDefault) ...[
            Text('WEIGHT', style: GoogleFonts.gowunBatang(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11)),
            Text('몸무게 (kg)', style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ] else
            Text(
              exText('piWeight'),
              style: appLanguage.isEnglishOnly
                  ? GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                  : GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: ExerciseTheme.containerBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.monitor_weight_outlined, color: ExerciseTheme.brandGolden),
                suffixText: 'kg',
                suffixStyle: const TextStyle(color: Colors.white54),
                hintText: exText('piHint'),
                hintStyle: const TextStyle(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: ExerciseTheme.brandGolden,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: appLanguage.isDefault
                  ? ExerciseTheme.biButtonLabel('Save', '저장', color: ExerciseTheme.pageBg, size: 14.5)
                  : Text(exText('saveBtn'), style: const TextStyle(color: ExerciseTheme.pageBg, fontWeight: FontWeight.bold, fontSize: 14.5)),
            ),
          ),
          if (_hasSavedWeight) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _clear,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: ExerciseTheme.dangerRed.withOpacity(0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(exText('piDelBtn'), textAlign: TextAlign.center, style: TextStyle(color: ExerciseTheme.dangerRed, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
