import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================================================
/// [GKE StudyUp] 일간 뷰 - 오늘 주요 일정(Todo) 목록 전담 위젯 섹션
/// ============================================================================
class DailyTodoListSection extends StatelessWidget {
  final List<Map<String, dynamic>> targetDaySchedules;

  // [주석] 카테고리별 구분을 위한 테마 색상팩 바인딩
  final Color schoolColor;
  final Color academyColor;
  final Color examColor;
  final Color personalColor;
  final Color goldColor;
  final Color slate500;

  // [주석] 부모 위젯과의 팝업 연동 콜백 채널
  final Function(Map<String, dynamic>) onUnifiedPopupTrack;

  const DailyTodoListSection({
    Key? key,
    required this.targetDaySchedules,
    required this.schoolColor,
    required this.academyColor,
    required this.examColor,
    required this.personalColor,
    required this.goldColor,
    required this.slate500,
    required this.onUnifiedPopupTrack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // [주석] 오늘 등록된 일정이 아예 없을 때의 예외 가드 뷰
    if (targetDaySchedules.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Text(
            '오늘 등록된 주요 일정이 없습니다.',
            style: GoogleFonts.notoSansKr(
                color: slate500,
                fontSize: 12
            ), // 원장님 지시: 일반글자 크기 12 준수
          ),
        ),
      );
    }

    // [주석] 일정이 존재할 경우 카테고리별 마스터 팩 루프 구동
    return Column(
      children: targetDaySchedules.map((item) {
        String categoryLabel = '[학교]';
        Color squareColor = schoolColor;

        if (item['color'] == academyColor) {
          categoryLabel = '[학원]';
          squareColor = academyColor;
        } else if (item['color'] == examColor) {
          categoryLabel = '[시험]';
          squareColor = examColor;
        } else if (item['color'] == personalColor) {
          categoryLabel = '[개인]';
          squareColor = personalColor;
        }

        return GestureDetector(
          onTap: () => onUnifiedPopupTrack(item),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFF020617),
                border: Border.all(color: squareColor.withOpacity(0.3))
            ),
            child: Row(
              children: [
                Text(
                    '■ ',
                    style: TextStyle(color: squareColor, fontSize: 26, fontWeight: FontWeight.bold)
                ),
                Text(
                    '$categoryLabel ',
                    style: GoogleFonts.notoSansKr(
                        color: squareColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold
                    ) // 원장님 지시: 일반글자 크기 12 준수
                ),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(
                        '${item['time']} - ${item['title']}',
                        style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold
                        ),
                        overflow: TextOverflow.ellipsis
                    )
                ),
                Icon(Icons.remove_red_eye, color: goldColor.withOpacity(0.7), size: 18),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}