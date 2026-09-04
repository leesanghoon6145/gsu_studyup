// exercise_theme.dart (v3)
//
// today_timeline_screen.dart에서 이미 쓰고 있는 프리미엄 UI 부품
// (LuxuryDialogFrame, luxuryDialogHeader, ThreeColorPencilIcon, biSnack 등)을
// bilingual_text.dart에서 그대로 가져와 재사용한다.
// 운동 모듈만의 새 디자인 언어를 만들지 않고, 앱 전체가 이미 쓰고 있는
// "고급 다이얼로그 프레임 + 3색 연필 아이콘" 톤에 맞춘 것이 이 파일의 핵심 목적.
//
// export 'bilingual_text.dart' 를 통해, 이 파일을 import하는 다른 exercise_*.dart
// 화면들은 별도로 bilingual_text.dart를 import하지 않아도
// LuxuryDialogFrame / luxuryDialogHeader / ThreeColorPencilIcon / biSnack /
// appLanguage 등을 바로 쓸 수 있다.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bilingual_text.dart';

export 'bilingual_text.dart';

class ExerciseTheme {
  ExerciseTheme._();

  static const Color brandGolden = Color(0xFFE5C158);
  static const Color goldenLight = Color(0xFFFFF6D6);
  static const Color pageBg = Color(0xFF030712);
  static const Color containerBg = Color(0xFF0D1527);
  static const Color containerBgElevated = Color(0xFF141F38);
  static const Color dangerRed = Color(0xFFDC2626);

  /// 종목 카드 등에 쓰는 고급 컨테이너 데코레이션.
  /// today_timeline_screen의 _buildProgressCard와 동일한 톤(골드 테두리+은은한 글로우).
  static BoxDecoration luxeCardDecoration({bool highlighted = false}) {
    return BoxDecoration(
      color: containerBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: brandGolden.withOpacity(highlighted ? 0.7 : 0.45),
        width: highlighted ? 1.6 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: brandGolden.withOpacity(0.08),
          blurRadius: 18,
          spreadRadius: 1,
        ),
      ],
    );
  }

  static TextStyle titleStyle({double size = 15}) => GoogleFonts.notoSansKr(
    color: goldenLight,
    fontWeight: FontWeight.bold,
    fontSize: size,
  );

  static TextStyle bodyStyle({double size = 13, Color? color}) => GoogleFonts.notoSansKr(
    color: color ?? Colors.white70,
    fontSize: size,
  );

  static AppBar appBar(String title, {List<Widget>? actions, Widget? leading}) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: leading,
      title: Text(title, style: titleStyle(size: 18)),
      actions: actions,
    );
  }

  /// 삭제 등 파괴적 액션 확인 다이얼로그.
  /// today_timeline_screen._showResetConfirmDialog와 동일한 부품(LuxuryDialogFrame +
  /// luxuryDialogHeader)과 버튼 스타일(OutlinedButton/ElevatedButton, 라운드 10, elevation)을 그대로 사용.
  static Future<bool> showLuxeConfirmDialog(
      BuildContext context, {
        required String title,
        required String message,
        String confirmLabel = '확인',
        String cancelLabel = '취소',
        bool isDestructive = false,
        IconData icon = Icons.info_outline_rounded,
      }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: LuxuryDialogFrame(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                luxuryDialogHeader(icon: icon, en: title, ko: title),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: pageBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    message,
                    style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12.5, height: 1.5),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(
                          cancelLabel,
                          style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDestructive ? dangerRed : brandGolden,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 4,
                          shadowColor: (isDestructive ? dangerRed : brandGolden).withOpacity(0.5),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(
                          confirmLabel,
                          style: GoogleFonts.notoSansKr(
                            color: isDestructive ? Colors.white : pageBg,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  /// 저장/완료 피드백. 앱 전체가 이미 쓰고 있는 biSnack을 그대로 사용해
  /// 다른 화면의 스낵바와 동일하게 보이도록 한다.
  static void showLuxeSnackBar(BuildContext context, String message) {
    biSnack(context, message, message);
  }

  // ---------------------------------------------------------------------
  // 🆕 [영문+한글 병기 통일] 앱 전체 컨벤션(BiTitle/BiInline)에 맞춘 헬퍼.
  // ---------------------------------------------------------------------

  /// 다른 화면들과 동일하게 영문(진한 명조체)+한글(노토산스) 두 줄 타이틀을 쓰는 AppBar.
  static AppBar biAppBar({
    required String en,
    required String ko,
    List<Widget>? actions,
    Widget? leading,
    Map<String, String>? translations,
  }) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: leading,
      title: BiTitle(en: en, ko: ko, enSize: 18, koSize: 13, translations: translations),
      actions: actions,
    );
  }

  /// 버튼 안에 들어가는 영문+한글 두 줄 라벨. 외국어 선택 시엔 한 줄로 자동 전환.
  /// today_timeline_screen 등 기존 화면의 버튼 라벨 패턴과 동일하게 맞춤.
  static Widget biButtonLabel(String en, String ko, {required Color color, double size = 13}) {
    if (appLanguage.isDefault) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(en, style: GoogleFonts.gowunBatang(color: color, fontSize: size - 2, fontWeight: FontWeight.bold)),
          Text(ko, style: GoogleFonts.notoSansKr(color: color, fontSize: size - 2, fontWeight: FontWeight.bold)),
        ],
      );
    }
    return Text(tButton(en), style: GoogleFonts.notoSansKr(color: color, fontSize: size, fontWeight: FontWeight.bold));
  }

  /// 종목 id별 골드톤 머티리얼 아이콘. 이모지는 색을 입힐 수 없어 전부 아이콘으로 통일.
  static const Map<String, IconData> _typeIcons = {
    'golf': Icons.golf_course_rounded,
    'swimming': Icons.pool_rounded,
    'running': Icons.directions_run_rounded,
    'walking': Icons.directions_walk_rounded,
    'gym': Icons.fitness_center_rounded,
    'pilates': Icons.self_improvement_rounded,
    'yoga': Icons.spa_rounded,
    'hiking': Icons.terrain_rounded,
    'cycling': Icons.directions_bike_rounded,
    'tennis': Icons.sports_tennis_rounded,
    'badminton': Icons.sports_rounded,
    'tabletennis': Icons.sports_rounded,
    'basketball': Icons.sports_basketball_rounded,
    'soccer': Icons.sports_soccer_rounded,
    'skiing': Icons.downhill_skiing_rounded,
    'etc': Icons.sports_rounded,
  };

  static IconData iconForType(String typeId) => _typeIcons[typeId] ?? Icons.sports_rounded;

  /// 기본 16종목의 영문 표기 (커스텀 종목은 매핑이 없으므로 한글명을 그대로 대문자로 사용).
  static const Map<String, String> _typeEnglishNames = {
    'golf': 'GOLF',
    'swimming': 'SWIMMING',
    'running': 'RUNNING',
    'walking': 'WALKING',
    'gym': 'GYM',
    'pilates': 'PILATES',
    'yoga': 'YOGA',
    'hiking': 'HIKING',
    'cycling': 'CYCLING',
    'tennis': 'TENNIS',
    'badminton': 'BADMINTON',
    'tabletennis': 'TABLE TENNIS',
    'basketball': 'BASKETBALL',
    'soccer': 'SOCCER',
    'skiing': 'SKIING',
    'etc': 'OTHER',
  };

  static String englishNameForType(String typeId, String fallbackKoName) =>
      _typeEnglishNames[typeId] ?? fallbackKoName.toUpperCase();
}
