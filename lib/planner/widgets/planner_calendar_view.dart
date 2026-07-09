import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================================================
/// [GKE StudyUp] 일간 뷰 전용 달력 제어 레일 및 날짜 선택 그리드 위젯
/// ============================================================================
class PlannerCalendarView extends StatelessWidget {
  final DateTime selectedDayDate;
  final bool isDayCalendarVisible;
  final List<Map<String, dynamic>> globalSchedules;

  // [주석] 카테고리별 테마 색상 및 슬레이트 색상팩 바인딩
  final Color goldColor;
  final Color examColor;
  final Color schoolColor;
  final Color academyColor;
  final Color personalColor;
  final Color slate400;
  final Color slate500;
  final Color slate800;

  // [주석] 부모 위젯과 통신하기 위한 콜백 함수 채널
  final VoidCallback onToggleCalendar;
  final Function(DateTime) onDaySelected;

  const PlannerCalendarView({
    super.key,
    required this.selectedDayDate,
    required this.isDayCalendarVisible,
    required this.globalSchedules,
    required this.goldColor,
    required this.examColor,
    required this.schoolColor,
    required this.academyColor,
    required this.personalColor,
    required this.slate400,
    required this.slate500,
    required this.slate800,
    required this.onToggleCalendar,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> weekLabelList = ['일', '월', '화', '수', '목', '금', '토'];

    // [주석] 매월 1일의 요일 및 그리드 칸수 자동 역산 알고리즘 구간
    DateTime firstDayOfCurrentMonth = DateTime(selectedDayDate.year, selectedDayDate.month, 1);
    int firstDayWeekdayIndex = firstDayOfCurrentMonth.weekday;

    int emptyPrefixCellsCount = firstDayWeekdayIndex == 7 ? 0 : firstDayWeekdayIndex;
    int totalDaysInMonth = DateTime(selectedDayDate.year, selectedDayDate.month + 1, 0).day;
    int prevMonthTotalDays = DateTime(selectedDayDate.year, selectedDayDate.month, 0).day;

    int totalCalendarGridItemsCount = emptyPrefixCellsCount + totalDaysInMonth;
    if (totalCalendarGridItemsCount % 7 != 0) {
      totalCalendarGridItemsCount += (7 - (totalCalendarGridItemsCount % 7));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // [주석] 👑 "07/02" 형태의 달력 열기·닫기 토글 버튼 (팝업 삭제 및 순수 토글 기능만 연동)
        GestureDetector(
          onTap: () {
            // [주석] 팝업 호출 코드를 삭제하고 오직 달력 열기/닫기 토글만 실행
            onToggleCalendar();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2017), // 홈 대시보드 동일 톤 유지
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE5C158).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: Color(0xFFE5C158),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // [주석] 👑 "07/02" 월일 동적 표시 (명조체 글자크기 15, 황금색)
                        Text(
                          '${selectedDayDate.month.toString().padLeft(2, '0')}/${selectedDayDate.day.toString().padLeft(2, '0')}',
                          style: GoogleFonts.notoSerif(
                            fontSize: 15,
                            color: const Color(0xFFE5C158),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // [주석] 👑 한글 글자 크기 12 (노토 산스 한글, 황금색 유지)
                        Text(
                          '선택 날짜 메모 보기',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            color: const Color(0xFFE5C158),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Icon(
                  isDayCalendarVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color(0xFFE5C158),
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        // [주석] 펼침 상태일 때 달력 본판 그리드 출력 (오버플로 방지 패딩 및 비율 최적화)
        if (isDayCalendarVisible) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: slate800),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('DATE CONTROL RAIL', style: GoogleFonts.notoSerif(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold)),
                Text('${selectedDayDate.year}년 ${selectedDayDate.month}월 달력 제어 레일', style: GoogleFonts.notoSansKr(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // [주석] 요일 헤더 라인 (일~토)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 7,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 2.2),
                  itemBuilder: (context, index) {
                    return Center(
                      child: Text(
                        weekLabelList[index],
                        style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          color: weekLabelList[index] == '일' ? examColor : (weekLabelList[index] == '토' ? schoolColor : slate400),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(color: Color(0xFF1E293B), height: 6),

                // [주석] 날짜 숫자 그리드 빌더 (오버플로 차단 규격)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalCalendarGridItemsCount,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, index) {
                    int displayDayNum = 1;
                    bool isBlurred = false;

                    if (index < emptyPrefixCellsCount) {
                      displayDayNum = prevMonthTotalDays - (emptyPrefixCellsCount - index - 1);
                      isBlurred = true;
                    } else if (index >= (emptyPrefixCellsCount + totalDaysInMonth)) {
                      displayDayNum = index - (emptyPrefixCellsCount + totalDaysInMonth) + 1;
                      isBlurred = true;
                    } else {
                      displayDayNum = index - emptyPrefixCellsCount + 1;
                    }

                    // [주석] 해당 날짜의 스케줄 도트 색상 판별 매핑 트랙
                    bool hasSchool = false; bool hasAcademy = false; bool hasExam = false; bool hasPersonal = false;
                    int dayScheduleCount = 0;

                    if (!isBlurred) {
                      var daySchedules = globalSchedules.where((s) => s['year'] == selectedDayDate.year && s['month'] == selectedDayDate.month && s['day'] == displayDayNum);
                      dayScheduleCount = daySchedules.length;
                      for (var s in daySchedules) {
                        if (s['color'] == schoolColor) hasSchool = true;
                        if (s['color'] == academyColor) hasAcademy = true;
                        if (s['color'] == examColor) hasExam = true;
                        if (s['color'] == personalColor) hasPersonal = true;
                      }
                    }

                    bool isSelected = !isBlurred && selectedDayDate.day == displayDayNum;

                    return GestureDetector(
                      onTap: () {
                        if (isBlurred) return;
                        onDaySelected(DateTime(selectedDayDate.year, selectedDayDate.month, displayDayNum));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected ? goldColor.withValues(alpha: 0.15) : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isSelected ? goldColor : slate800, width: isSelected ? 1.5 : 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$displayDayNum', style: GoogleFonts.notoSerif(fontSize: 12, color: isBlurred ? slate500 : (isSelected ? goldColor : Colors.white), fontWeight: FontWeight.bold)),
                            if (!isBlurred)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (hasSchool) Container(width: 3.5, height: 3.5, margin: const EdgeInsets.symmetric(horizontal: 0.5), color: schoolColor),
                                  if (hasAcademy) Container(width: 3.5, height: 3.5, margin: const EdgeInsets.symmetric(horizontal: 0.5), color: academyColor),
                                  if (hasExam) Container(width: 3.5, height: 3.5, margin: const EdgeInsets.symmetric(horizontal: 0.5), color: examColor),
                                  if (hasPersonal) Container(width: 3.5, height: 3.5, margin: const EdgeInsets.symmetric(horizontal: 0.5), color: personalColor),
                                ],
                              )
                            else
                              const SizedBox(height: 3),

                            if (!isBlurred && dayScheduleCount > 0)
                              Text('$dayScheduleCount개', style: GoogleFonts.notoSansKr(fontSize: 10, color: goldColor, fontWeight: FontWeight.bold))
                            else
                              const SizedBox(height: 6),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}