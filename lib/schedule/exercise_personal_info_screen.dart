// exercise_personal_info_screen.dart
//
// 🆕 [개인정보 입력 화면] 운동 칼로리 계산 정확도를 위한 몸무게 입력 화면.
// 다른 개인정보(키, 나이 등)가 나중에 필요해지면 이 화면 하나에 계속
// 추가하면 됨 - "운동 관련 개인정보"를 모아두는 단일 창구.
//
// ⚠️ [투명성] 이 값이 정확히 어디에 어떻게 쓰이는지, 서버로 전송되지
// 않는다는 것을 화면에 명시적으로 안내함.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'exercise_theme.dart';
import 'exercise_profile_service.dart';

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
      ExerciseTheme.showLuxeSnackBar(context, '올바른 몸무게(kg)를 입력해주세요.');
      return;
    }
    await ExerciseProfileService.setWeightKg(weight);
    setState(() => _hasSavedWeight = true);
    if (mounted) {
      ExerciseTheme.showLuxeSnackBar(context, '저장했습니다. 앞으로 칼로리 계산에 반영됩니다.');
    }
  }

  Future<void> _clear() async {
    final bool confirmed = await ExerciseTheme.showLuxeConfirmDialog(
      context,
      title: '몸무게 정보 삭제',
      message: '저장된 몸무게를 삭제하시겠습니까? 삭제하면 칼로리 계산은 평균값(${ExerciseProfileService.defaultWeightKg.toInt()}kg) 기준으로 돌아갑니다.',
      isDestructive: true,
    );
    if (!confirmed) return;
    await ExerciseProfileService.clearWeightKg();
    if (!mounted) return;
    setState(() {
      _weightController.clear();
      _hasSavedWeight = false;
    });
    ExerciseTheme.showLuxeSnackBar(context, '삭제했습니다.');
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
                    '입력하신 몸무게는 이 기기 안에만 저장되며, 오직 운동 칼로리 계산에만 사용됩니다. 서버로 전송되거나 다른 곳에 공유되지 않습니다. 입력은 선택사항이며, 입력 안 하면 평균값(${ExerciseProfileService.defaultWeightKg.toInt()}kg)으로 계산됩니다.',
                    style: ExerciseTheme.bodyStyle(size: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('WEIGHT', style: GoogleFonts.gowunBatang(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11)),
          Text('몸무게 (kg)', style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
                hintText: '예: 65.0',
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
              child: ExerciseTheme.biButtonLabel('Save', '저장', color: ExerciseTheme.pageBg, size: 14.5),
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
                child: Text('삭제 (평균값으로 되돌리기)', style: TextStyle(color: ExerciseTheme.dangerRed, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
