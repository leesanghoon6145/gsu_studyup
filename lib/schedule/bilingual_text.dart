// ============================================================================
// 🆕 [일반 플래너 - 다국어 정리] BiText 계열 공용 위젯
// 지금까지 각 화면에서 "EN" Text와 "KO" Text를 따로따로 두 줄로 작성하던 것을
// 한 번의 호출로 끝낼 수 있도록 만든 공용 헬퍼입니다. 앞으로 새로 만들거나
// 수정하는 모든 화면의 제목/버튼/힌트/안내문은 이 위젯들을 사용해서
// 영어+한글이 항상 함께 표시되도록 통일합니다.
//
// 사용 예시:
//   BiTitle(en: 'CALENDAR', ko: '캘린더')                    // 화면 상단 제목용 (2줄, 큰 글씨)
//   BiInline(en: 'Save', ko: '저장')                          // 버튼/라벨용 (1줄, "Save (저장)")
//   biHint('Enter title', '제목을 입력하세요')                // TextField 힌트용 문자열
//   biSnack(context, 'Saved', '저장되었습니다')                // SnackBar 문구용
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 🆕 화면 상단 AppBar 제목처럼 "영문 큰 글씨 + 한글 작은 글씨" 2줄 구조
class BiTitle extends StatelessWidget {
  final String en;
  final String ko;
  final Color color;
  final double enSize;
  final double koSize;

  const BiTitle({
    super.key,
    required this.en,
    required this.ko,
    this.color = const Color(0xFFE5C158),
    this.enSize = 18,
    this.koSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(en, style: GoogleFonts.gowunBatang(color: color, fontWeight: FontWeight.bold, fontSize: enSize)),
        Text(ko, style: GoogleFonts.notoSansKr(color: color, fontWeight: FontWeight.bold, fontSize: koSize)),
      ],
    );
  }
}

// 🆕 버튼/라벨/섹션제목처럼 한 줄로 "EN (KO)" 형태로 보여주는 인라인 텍스트
class BiInline extends StatelessWidget {
  final String en;
  final String ko;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final int? maxLines;

  const BiInline({
    super.key,
    required this.en,
    required this.ko,
    this.color = Colors.white,
    this.fontSize = 14,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.start,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$en ($ko)',
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: GoogleFonts.notoSansKr(color: color, fontWeight: fontWeight, fontSize: fontSize),
    );
  }
}

// 🆕 TextField의 hintText처럼 순수 문자열이 필요한 자리에 쓰는 함수형 헬퍼
String biHint(String en, String ko) => '$en ($ko)';

// 🆕 SnackBar 문구용 헬퍼 - 바로 ScaffoldMessenger에 넘겨서 사용
void biSnack(BuildContext context, String en, String ko, {Color? backgroundColor}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$en ($ko)', style: GoogleFonts.notoSansKr()),
      backgroundColor: backgroundColor,
    ),
  );
}

// 🆕 [가로형 3선 연필 아이콘 - 빨강/노랑/파랑] 타임기록/실행기록 화면의 수정 버튼용.
// 기존 대각선(파랑/노랑/흰색) 연필 아이콘과는 별도로, 이번 화면들은 가로로
// 놓인 3선(빨강/노랑/파랑)으로 표시합니다.
class HorizontalPencilIcon extends StatelessWidget {
  final double size;
  const HorizontalPencilIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: size * 0.9, height: size * 0.16, margin: const EdgeInsets.symmetric(vertical: 0.8), decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(2))),
          Container(width: size * 0.9, height: size * 0.16, margin: const EdgeInsets.symmetric(vertical: 0.8), decoration: BoxDecoration(color: const Color(0xFFFACC15), borderRadius: BorderRadius.circular(2))),
          Container(width: size * 0.9, height: size * 0.16, margin: const EdgeInsets.symmetric(vertical: 0.8), decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }
}

// 🆕 [고급 팝업 공용 컨테이너] 골드 테두리를 더 선명하고 진하게, 글로우를 강하게 준 버전.
// 캘린더 등 기존 화면보다 한 단계 더 고급스러운 느낌을 원할 때 이 위젯으로 감싸서 사용.
class LuxuryDialogFrame extends StatelessWidget {
  final Widget child;
  const LuxuryDialogFrame({super.key, required this.child});

  static const Color _brandGolden = Color(0xFFE5C158);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF141D33), Color(0xFF090D1A)],
        ),
        border: Border.all(color: _brandGolden.withOpacity(0.75), width: 1.6), // 🆕 더 선명한 골드 테두리
        boxShadow: [
          BoxShadow(color: _brandGolden.withOpacity(0.32), blurRadius: 42, spreadRadius: 2), // 🆕 강한 골드 글로우
          const BoxShadow(color: Colors.black, blurRadius: 26, offset: Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
      child: child,
    );
  }
}

// 🆕 [고급 팝업 헤더] 아이콘 + 영/한 제목 + 진한 골드 구분선
Widget luxuryDialogHeader({required IconData icon, required String en, required String ko}) {
  const Color brandGolden = Color(0xFFE5C158);
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: brandGolden, size: 22),
          const SizedBox(width: 8),
          BiTitle(en: en, ko: ko, enSize: 16, koSize: 12.5),
        ],
      ),
      const SizedBox(height: 10),
      Container(
        height: 1.4,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.transparent, brandGolden.withOpacity(0.85), Colors.transparent]), // 🆕 더 선명한 구분선
        ),
      ),
      const SizedBox(height: 18),
    ],
  );
}

// 🆕 [맨 아래 버튼 한 줄] Delete(선택)/Cancel/Save를 한 줄에 배치하는 공용 위젯.
// showDelete가 true면 3개, false면 Cancel/Save 2개만 표시.
Widget luxuryBottomActions({
  required VoidCallback onCancel,
  required VoidCallback onSave,
  VoidCallback? onDelete,
  bool isEdit = false,
}) {
  const Color brandGolden = Color(0xFFE5C158);
  const Color pageBg = Color(0xFF030712);

  return Row(
    children: [
      if (onDelete != null) ...[
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFDC2626)), padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: onDelete,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Delete', style: GoogleFonts.gowunBatang(color: const Color(0xFFDC2626), fontSize: 10.5, fontWeight: FontWeight.bold)),
              Text('삭제', style: GoogleFonts.notoSansKr(color: const Color(0xFFDC2626), fontSize: 10.5, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
        const SizedBox(width: 8),
      ],
      Expanded(
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: onCancel,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Cancel', style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold)),
            Text('취소', style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: brandGolden, padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 4, shadowColor: brandGolden.withOpacity(0.5)),
          onPressed: onSave,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(isEdit ? 'Update' : 'Save', style: GoogleFonts.gowunBatang(color: pageBg, fontSize: 10.5, fontWeight: FontWeight.bold)),
            Text(isEdit ? '수정완료' : '저장', style: GoogleFonts.notoSansKr(color: pageBg, fontSize: 10.5, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    ],
  );
}

