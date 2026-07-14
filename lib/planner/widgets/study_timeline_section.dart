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
  // [주석] 학사 타임라인 전용 렌더링 및 수정/삭제 팝업 연동 위젯 (study_timeline_section.dart 최하단 추가)
  Widget _buildAcademicTimelineSection(BuildContext context, String timelineName, List<Map<String, String>> scheduleList) {
    return ListView(
      shrinkWrap: true, // 👈 스크롤 충돌 방지
      physics: const NeverScrollableScrollPhysics(), // 👈 외부 스크롤과 연동
      padding: EdgeInsets.zero, // 👈 사이공간 없이 최소한으로 붙이기 위한 패딩 제거
      children: [
        // 1. gsu_logo.png 최상단 밀착 배치 (사이공간 최소화)
        Image.asset(
          'assets/gsu_logo.png',
          height: 40,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
        ),
        const SizedBox(height: 4), // 👈 로고와 타이틀 사이 최소한의 간격

        // 2. 타이틀 영역: 영문 명조체 + 노토 산스 한글 "학사 타임라인"
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ACADEMIC TIMELINE', style: GoogleFonts.notoSerif(fontSize: 16, color: goldColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('학사 타임라인', style: GoogleFonts.notoSansKr(fontSize: 18, color: goldColor, fontWeight: FontWeight.bold)),
            const Divider(color: Color(0xFF1E293B), height: 20),
          ],
        ),

        // 3. 타임라인 명칭 표시 (좌측 정렬 뱃지 스타일)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: goldColor, width: 1),
          ),
          child: Text(
            timelineName,
            style: GoogleFonts.notoSansKr(fontSize: 13, color: goldColor, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),

        // 4. 시간표 목록 아래로 좌악 렌더링 + 각 타임별 [수정] / [삭제] 팝업 연동
        if (scheduleList.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Text('등록된 타임라인 상세 일정이 없습니다.', style: GoogleFonts.notoSansKr(color: Colors.grey, fontSize: 13)),
            ),
          )
        else
          ...scheduleList.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, String> item = entry.value;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 85,
                    child: Text(item['time'] ?? '', style: GoogleFonts.notoSerif(fontSize: 12, color: goldColor, fontWeight: FontWeight.bold)),
                  ),
                  Container(width: 2, height: 28, margin: const EdgeInsets.symmetric(horizontal: 8), color: goldColor),
                  Expanded(
                    child: Text(item['task'] ?? '', style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16, color: Colors.amberAccent),
                    tooltip: '수정',
                    onPressed: () {
                      _showEditTaskPopup(context, index, item);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 16, color: Colors.redAccent),
                    tooltip: '삭제',
                    onPressed: () {
                      _showDeleteTaskPopup(context, index);
                    },
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  void _showEditTaskPopup(BuildContext context, int index, Map<String, String> currentItem) {
    TextEditingController timeController = TextEditingController(text: currentItem['time']);
    TextEditingController taskController = TextEditingController(text: currentItem['task']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: Text('타임라인 항목 수정', style: GoogleFonts.notoSansKr(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: timeController, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: const InputDecoration(labelText: '시간', labelStyle: TextStyle(color: Colors.grey))),
              const SizedBox(height: 8),
              TextField(controller: taskController, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: const InputDecoration(labelText: '내용/과목', labelStyle: TextStyle(color: Colors.grey))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.grey))),
            TextButton(onPressed: () => Navigator.pop(context), child: Text('저장', style: TextStyle(color: goldColor))),
          ],
        );
      },
    );
  }

  void _showDeleteTaskPopup(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: Text('항목 삭제', style: GoogleFonts.notoSansKr(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.bold)),
          content: Text('선택하신 타임라인 일정을 정말 삭제하시겠습니까?', style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.grey))),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('삭제', style: TextStyle(color: Colors.redAccent))),
          ],
        );
      },
    );
  }
}