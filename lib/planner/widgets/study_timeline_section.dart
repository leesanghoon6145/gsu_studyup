import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================================================
/// [GKE StudyUp] 학습 타임라인 및 시험대비 자동 전환 전담 위젯 섹션
/// ============================================================================
class StudyTimelineSection extends StatelessWidget {
  final List<Map<String, dynamic>> fixedDayTimelines;
  final DateTime selectedDayDate;
  final Color goldColor;
  final Color slate400;
  final Color slate800;
  final Color examColor;
  final Function(Map<String, dynamic>, int) onUnifiedPopupTrack;
  final VoidCallback onAddNewTimeSlot;

  const StudyTimelineSection({
    Key? key,
    required this.fixedDayTimelines,
    required this.selectedDayDate,
    required this.goldColor,
    required this.slate400,
    required this.slate800,
    required this.examColor,
    required this.onUnifiedPopupTrack,
    required this.onAddNewTimeSlot,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // [주석] 타임라인 인스턴스 리스트 루프 생성 구간
        ...fixedDayTimelines.asMap().entries.map((entry) {
          final timelineItem = entry.value;
          final index = entry.key;

          return GestureDetector(
            onTap: () => onUnifiedPopupTrack(timelineItem, index),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: slate800),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // [주석] 시간대 레이블 표시 구역
                  SizedBox(
                    width: 105,
                    child: Text(
                      timelineItem['time'],
                      style: GoogleFonts.notoSerif(
                        fontSize: 15, // 원장님 지시: 타이틀/강조 글자크기 15 준수
                        color: goldColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // [주석] 학습 계획 명칭 및 세부 메모 영역 (자동 줄바꿈 커버)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                timelineItem['title'],
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 12, // 원장님 지시: 일반 글자크기 12 준수
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                softWrap: true,
                              ),
                            ),
                            if (timelineItem['is_starred'] == true) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.star, color: goldColor, size: 14),
                            ]
                          ],
                        ),
                        if ((timelineItem['memo'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            timelineItem['memo'],
                            style: GoogleFonts.notoSansKr(
                              fontSize: 12, // 원장님 지시: 일반 글자크기 12 준수
                              color: slate400,
                            ),
                            softWrap: true,
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.remove_red_eye, color: Colors.blueGrey, size: 14),
                ],
              ),
            ),
          );
        }).toList(),

        const SizedBox(height: 12),

        // [주석] 새로운 학습 시간대 확장 추가 버튼 레일
        SizedBox(
          width: double.infinity,
          height: 48, // 가독성을 위해 크기 최적화
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: goldColor.withOpacity(0.5)),
              backgroundColor: const Color(0xFF020617),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: Icon(Icons.more_time, color: goldColor, size: 16),
            label: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'EXTEND TIMELINE',
                  style: GoogleFonts.notoSerif(
                    fontSize: 12,
                    color: goldColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '새로운 학습 시간대 확장 추가',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12, // 원장님 지시: 일반 글자크기 12 준수
                    color: goldColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            onPressed: onAddNewTimeSlot,
          ),
        ),
      ],
    );
  }
}