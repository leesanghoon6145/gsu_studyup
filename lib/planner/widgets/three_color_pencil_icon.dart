import 'package:flutter/material.dart';

/// ============================================================================
/// [GKE StudyUp] 앱 전체 "수정" 액션 공용 아이콘.
/// 가로 3색 막대(빨강/노랑/파랑) + 우하단 연필 오버레이 조합. 터치 타겟 44x44px 고정.
/// 기존에 화면마다 제각각이던 눈(👁)/메뉴+연필 등의 아이콘을 전부 이걸로 통일함.
/// ============================================================================
class ThreeColorPencilIcon extends StatelessWidget {
  final double size;

  const ThreeColorPencilIcon({Key? key, this.size = 16}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double barWidth = size;
    final double barHeight = size / 5.2;
    final double barGap = size / 10;

    return SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: SizedBox(
          width: size + 8,
          height: size + 8,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: barWidth, height: barHeight, color: const Color(0xFFEF4444)),
                  SizedBox(height: barGap),
                  Container(width: barWidth, height: barHeight, color: const Color(0xFFFACC15)),
                  SizedBox(height: barGap),
                  Container(width: barWidth, height: barHeight, color: const Color(0xFF3B82F6)),
                ],
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Icon(Icons.edit, size: size * 0.75, color: const Color(0xFFD4AF37)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
