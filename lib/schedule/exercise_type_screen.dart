// exercise_type_screen.dart (v3)
//
// 🆕 [영문+한글 병기] 앱 전체 컨벤션(BiTitle/BiInline)에 맞춰 타이틀/라벨을 두 줄로 표시.
// 🆕 [골드 아이콘 통일] 이모지 대신 종목별 머티리얼 아이콘을 전부 골드톤으로 표시.
// 🆕 [수정 UX 통합] 휴지통 아이콘 제거. 3색 연필 아이콘 하나만 남기고, 그 안에서
//    수정/삭제/저장을 모두 처리한다(캘린더 화면과 동일한 패턴).
// 🆕 [분석 진입] 앱바에 분석 아이콘 추가 -> exercise_analysis_screen.dart로 이동.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'exercise_models.dart';
import 'exercise_data_service.dart';
import 'exercise_type_edit_screen.dart';
import 'today_exercise_screen.dart';
import 'exercise_analysis_screen.dart';
import 'exercise_personal_info_screen.dart'; // 🆕 [개인정보 - 칼로리 계산용]
import 'exercise_consent_service.dart'; // 🆕 [건강정보 수집 동의]
import 'exercise_theme.dart';

class ExerciseTypeScreen extends StatefulWidget {
  const ExerciseTypeScreen({super.key});

  @override
  State<ExerciseTypeScreen> createState() => _ExerciseTypeScreenState();
}

class _ExerciseTypeScreenState extends State<ExerciseTypeScreen> {
  final _service = ExerciseDataService.instance;
  List<ExerciseType> _types = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkConsentThenReload(); // 🆕 [건강정보 수집 동의] 최초 진입 시 동의부터 확인
  }

  // 🆕 [건강정보 수집 동의] 이미 동의했으면 바로 진행, 아직이면 동의 화면을
  // 먼저 보여주고, 동의 안 하면 이 화면(운동 섹션)에서 바로 나가게 함.
  Future<void> _checkConsentThenReload() async {
    final bool consented = await ExerciseConsentService.hasConsented();
    if (!consented) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final bool agreed = await ExerciseConsentService.showConsentDialog(context);
        if (!mounted) return;
        if (!agreed) {
          Navigator.of(context).pop(); // 동의 안 하면 운동 섹션 진입 취소
          return;
        }
        _reload();
      });
    } else {
      _reload();
    }
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final types = await _service.getExerciseTypes();
    setState(() {
      _types = types;
      _loading = false;
    });
  }

  Future<void> _onAddPressed() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ExerciseTypeEditScreen()),
    );
    if (result == true) _reload();
  }

  // 🆕 [수정 UX 통합] 3색 연필 하나로 진입 -> 그 화면(exercise_type_edit_screen) 안에서
  // 수정/삭제/저장을 전부 처리하고 결과(true=변경됨)만 돌려받는다.
  Future<void> _onEditPressed(ExerciseType type) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ExerciseTypeEditScreen(existingType: type)),
    );
    if (result == true) _reload();
  }

  Future<void> _onTypeTapped(ExerciseType type) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TodayExerciseScreen(exerciseType: type)),
    );
    if (saved == true && mounted) {
      ExerciseTheme.showLuxeSnackBar(context, "'${type.name}' 기록을 저장했습니다.");
    }
  }

  void _onAnalysisPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExerciseAnalysisScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExerciseTheme.pageBg,
      appBar: ExerciseTheme.biAppBar(
        en: 'EXERCISE',
        ko: '운동',
        enSize: 17,
        koSize: 17,
        translations: const {
          'JA': '運動', 'ZH': '运动', 'FR': 'Exercice', 'DE': 'Sport', 'RU': 'Упражнение',
          'AR': 'تمرين', 'HI': 'व्यायाम', 'VI': 'Tập thể dục', 'ES': 'Ejercicio', 'TH': 'ออกกำลังกาย',
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_rounded, color: ExerciseTheme.brandGolden),
            tooltip: 'Overall Analysis',
            onPressed: _onAnalysisPressed,
          ),
          // 🆕 [개인정보 - 칼로리 계산용] 몸무게 입력 화면 진입 버튼
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: ExerciseTheme.brandGolden),
            tooltip: 'Personal Info',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExercisePersonalInfoScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: ExerciseTheme.brandGolden),
            tooltip: 'Add',
            onPressed: _onAddPressed,
          ),
        ],
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(color: ExerciseTheme.brandGolden),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
        ),
        itemCount: _types.length,
        itemBuilder: (context, index) => _buildTypeCard(_types[index]),
      ),
    );
  }

  Widget _buildTypeCard(ExerciseType type) {
    final String enName = ExerciseTheme.englishNameForType(type.id, type.name);

    // ✅ [2026-09-13 최종 원복] 종목 허브 화면을 거치던 것도, 카드에 버튼
    // 2개를 넣던 것도 전부 되돌림. 입력/분석은 이제 각 종목 화면(today_
    // exercise_screen.dart) 안에 있는 하단 탭으로 접근하므로, 목록 화면은
    // 원래처럼 카드 전체 탭 한 번으로 바로 입력화면 이동만 하면 됨(깔끔하게).
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _onTypeTapped(type),
      child: Container(
        decoration: ExerciseTheme.luxeCardDecoration(highlighted: true),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 🆕 [골드 아이콘 통일] 이모지 대신 종목별 머티리얼 아이콘을 골드로 표시
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ExerciseTheme.brandGolden.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(ExerciseTheme.iconForType(type.id), color: ExerciseTheme.brandGolden, size: 24),
                ),
                // 🆕 [3색 연필 통합] 휴지통 아이콘 제거 - 연필 하나로 수정/삭제/저장 진입
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _onEditPressed(type),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: ThreeColorPencilIcon(size: 18),
                  ),
                ),
              ],
            ),
            const Spacer(),
            appLanguage.isDefault
                ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(enName, style: GoogleFonts.gowunBatang(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11)),
                Text(
                  type.name,
                  style: GoogleFonts.notoSansKr(color: ExerciseTheme.brandGolden, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            )
                : Align(
              alignment: Alignment.centerRight,
              child: Text(
                type.name,
                style: GoogleFonts.notoSansKr(color: ExerciseTheme.brandGolden, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(height: 4),
            BiInline(
              en: '${type.fields.length} fields',
              ko: '${type.fields.length}개 기록 항목',
              color: Colors.white54,
              fontSize: 11.5,
            ),
          ],
        ),
      ),
    );
  }
}
