// exercise_type_screen.dart (v3)
//
// 🆕 [영문+한글 병기] 앱 전체 컨벤션(BiTitle/BiInline)에 맞춰 타이틀/라벨을 두 줄로 표시.
// 🆕 [골드 아이콘 통일] 이모지 대신 종목별 머티리얼 아이콘을 전부 골드톤으로 표시.
// 🆕 [수정 UX 통합] 휴지통 아이콘 제거. 3색 연필 아이콘 하나만 남기고, 그 안에서
//    수정/삭제/저장을 모두 처리한다(캘린더 화면과 동일한 패턴).
// 🆕 [분석 진입] 앱바에 분석 아이콘 추가 -> exercise_analysis_screen.dart로 이동.
// 🆕 [2026-10-08] 언어 버튼을 일반 플래너와 똑같은 모양(🌐 + KO 글자 · 골드 둥근 테두리)으로
//    맨 왼쪽(뒤로가기 옆)에 두고, 오른쪽 아이콘 3개와 폭을 맞춰 제목이 정가운데 오게 함.
// 🆕 [2026-10-08] 종목 카드 이름이 한글로만 나오던 문제 수정 → 12개 언어 (exercise_type_names.dart)

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
import 'exercise_type_data.dart'; // 🆕 [자유운동 2026-10-07]
import 'exercise_type_names.dart'; // 🆕 [2026-10-08] 종목 이름 12개 언어
import 'app_language_service.dart'; // 🆕 [2026-10-08] 언어 버튼

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
      ExerciseTheme.showLuxeSnackBar(context, exerciseSavedMessage(type)); // 🆕 [2026-10-08] 12개 언어
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
      // 🆕 [2026-10-08] 왼쪽: 뒤로가기 + 언어 버튼 / 가운데: 제목 / 오른쪽: 아이콘 3개 (좌우 폭 같게)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leadingWidth: 144, // 오른쪽 아이콘 3개(48 × 3)와 같은 폭 → 제목이 정가운데
        leading: Row(
          children: [
            if (Navigator.of(context).canPop())
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: ExerciseTheme.brandGolden),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            else
              const SizedBox(width: 8),
            Flexible(child: _buildLanguageSelector(context)),
          ],
        ),
        title: const BiTitle(
          en: 'EXERCISE',
          ko: '운동',
          enSize: 17,
          koSize: 17,
          translations: {
            'JA': '運動', 'ZH': '运动', 'FR': 'Exercice', 'DE': 'Sport', 'RU': 'Упражнение',
            'AR': 'تمرين', 'HI': 'व्यायाम', 'VI': 'Tập thể dục', 'ES': 'Ejercicio', 'TH': 'ออกกำลังกาย',
          },
        ),
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
          childAspectRatio: 1.4, // 🆕 [2026-10-08] 1.5 → 1.4 (카드 조금 더 높게)
        ),
        itemCount: _types.length,
        // 🆕 [2026-10-08] 언어를 바꾸면 카드 이름도 바로 바뀌게
        itemBuilder: (context, index) => ListenableBuilder(
          listenable: appLanguage,
          builder: (context, _) => _buildTypeCard(_types[index]),
        ),
      ),
    );
  }

  // 🆕 [2026-10-08] 언어 선택 버튼 — 일반 플래너 홈과 똑같은 모양 (🌐 + 지금 언어 글자)
  Widget _buildLanguageSelector(BuildContext context) {
    return ListenableBuilder(
      listenable: appLanguage,
      builder: (context, _) {
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showLanguagePicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: ExerciseTheme.brandGolden.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ExerciseTheme.brandGolden.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language_rounded, color: ExerciseTheme.brandGolden, size: 15),
                const SizedBox(width: 5),
                Text(
                  appLanguage.current,
                  style: const TextStyle(color: ExerciseTheme.brandGolden, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🆕 [2026-10-08] 언어 선택 팝업 — 일반 플래너 홈과 똑같은 목록 (한국어 · English · 10개 외국어)
  Future<void> _showLanguagePicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final double maxHeight = MediaQuery.of(sheetContext).size.height * 0.8;
        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            color: Color(0xFF0D1527),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LANGUAGE', style: GoogleFonts.gowunBatang(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                Text('언어 선택', style: GoogleFonts.notoSansKr(color: ExerciseTheme.brandGolden, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                _buildLanguageOption(sheetContext, code: 'KO', label: AppLanguageService.languageDisplayNames['KO'] ?? '한국어 (기본)'),
                _buildLanguageOption(sheetContext, code: 'EN', label: AppLanguageService.languageDisplayNames['EN'] ?? 'English (영어만)'),
                const Divider(color: Colors.white12, height: 20),
                ...AppLanguageService.foreignLanguageCodes.map((code) => _buildLanguageOption(
                  sheetContext,
                  code: code,
                  label: AppLanguageService.languageDisplayNames[code] ?? code,
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext sheetContext, {required String code, required String label}) {
    final bool isSelected = appLanguage.current == code;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        await appLanguage.setLanguage(code);
        if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? ExerciseTheme.brandGolden : Colors.white38,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(color: isSelected ? ExerciseTheme.brandGolden : Colors.white70, fontSize: 13.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(ExerciseType type) {
    final String enName = type.id == 'etc' ? 'FREE WORKOUT' : ExerciseTheme.englishNameForType(type.id, type.name);

    // ✅ [2026-09-13 최종 원복] 종목 허브 화면을 거치던 것도, 카드에 버튼
    // 2개를 넣던 것도 전부 되돌림. 입력/분석은 이제 각 종목 화면(today_
    // exercise_screen.dart) 안에 있는 하단 탭으로 접근하므로, 목록 화면은
    // 원래처럼 카드 전체 탭 한 번으로 바로 입력화면 이동만 하면 됨(깔끔하게).
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _onTypeTapped(type),
      child: Container(
        decoration: ExerciseTheme.luxeCardDecoration(highlighted: true),
        padding: const EdgeInsets.all(12), // 🆕 [2026-10-08] 14 → 12
        // 🆕 [2026-10-08 넘침 수정] 카드가 좁은 폰·큰 글씨 설정에서도 절대 넘치지 않게:
        //   카드 높이가 모자라면 카드 안 전체를 그 칸에 맞게 살짝 줄여서 보여줌
        child: LayoutBuilder(
          builder: (context, box) => FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: box.maxWidth,
              height: box.maxHeight < 100 ? 100 : box.maxHeight,
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
                  // 🆕 [2026-10-08 넘침 수정] 아랍어 등 글자가 크고 긴 언어에서 카드 아래가 넘치던 문제
                  //   → 이름 부분을 남은 칸 안에 맞춰 자동으로 살짝 줄여서 보여줌 (잘림 · 노란 줄무늬 없음)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) => Align(
                        alignment: Alignment.bottomLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.bottomLeft,
                          child: SizedBox(
                            width: box.maxWidth,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 🆕 [2026-10-08] 종목 이름 12개 언어
                                //   한국어: 영문(고운바탕 굵게) + 한글(노토산스) 함께
                                //   English: 영어만 (고운바탕 굵게) / 10개 외국어: 그 나라 말만
                                if (appLanguage.isDefault && type.id == 'etc') ...[
                                  // 자유 운동: 위 영문 · 아래 한글 (기록 항목 수 줄이 없어서 두 줄 들어감)
                                  Text('FREE WORKOUT', style: GoogleFonts.gowunBatang(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text('자유 운동', style: GoogleFonts.notoSansKr(color: ExerciseTheme.brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
                                ] else if (appLanguage.isDefault) ...[
                                  // 나머지 종목: 왼쪽 영문 · 오른쪽 한글 (예전 그대로 — 카드 높이 넘침 방지)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(child: Text(enName, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.gowunBatang(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11))),
                                      Text(
                                        exerciseDisplayName(type),
                                        style: GoogleFonts.notoSansKr(color: ExerciseTheme.brandGolden, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ] else
                                  Text(
                                    exerciseLocalName(type),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: appLanguage.isEnglishOnly
                                        ? GoogleFonts.gowunBatang(color: ExerciseTheme.brandGolden, fontWeight: FontWeight.bold, fontSize: 15)
                                        : GoogleFonts.notoSansKr(color: ExerciseTheme.brandGolden, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                // 자유 운동 카드는 "기록 항목 수" 줄 없음
                                if (type.id != 'etc') ...[
                                  const SizedBox(height: 4),
                                  BiInline(
                                    en: '${type.fields.length} fields',
                                    ko: '${type.fields.length}개 기록 항목',
                                    // 🆕 [2026-10-08] 10개 언어
                                    translations: {
                                      'JA': '記録項目 ${type.fields.length}個', 'ZH': '${type.fields.length} 个记录项', 'FR': '${type.fields.length} champs',
                                      'DE': '${type.fields.length} Felder', 'RU': 'Полей: ${type.fields.length}', 'AR': '${type.fields.length} حقول',
                                      'HI': '${type.fields.length} फ़ील्ड', 'VI': '${type.fields.length} mục', 'ES': '${type.fields.length} campos', 'TH': '${type.fields.length} รายการ',
                                    },
                                    color: Colors.white54,
                                    fontSize: 11.5,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
