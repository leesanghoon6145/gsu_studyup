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

  // [주석] 부모 위젯(본가)과 통신하기 위한 콜백 함수 채널
  final VoidCallback onToggleCalendar;
  final Function(DateTime) onDaySelected;

  const PlannerCalendarView({
    Key? key,
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
  }) : super(key: key);

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
      children: [
        // [주석] 달력 컨트롤러 대문 토글 버튼
        GestureDetector(
          onTap: onToggleCalendar,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: goldColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month, color: goldColor, size: 20),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CALENDAR CONTROLLER', style: GoogleFonts.notoSerif(fontSize: 12, color: goldColor, fontWeight: FontWeight.bold)),
                        Text('달력 열기·닫기', style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
                Icon(isDayCalendarVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: goldColor)
              ],
            ),
          ),
        ),

        // [주석] 펼침 상태일 때 달력 본판 그리드 출력
        if (isDayCalendarVisible) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(12), border: Border.all(color: slate800)),
            child: Column(
              children: [
                Text('DATE CONTROL RAIL', style: GoogleFonts.notoSerif(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold)),
                Text('${selectedDayDate.year}년 ${selectedDayDate.month}월 달력 제어 레일', style: GoogleFonts.notoSansKr(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                // [주석] 요일 헤더 라인 (일~토)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 7,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 2),
                  itemBuilder: (context, index) {
                    return Center(
                      child: Text(
                        weekLabelList[index],
                        style: GoogleFonts.notoSansKr(
                          fontSize: 12, // 규격 준수
                          color: weekLabelList[index] == '일' ? examColor : (weekLabelList[index] == '토' ? schoolColor : slate400),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(color: Color(0xFF1E293B), height: 10),

                // [주석] 날짜 숫자 그리드 빌더
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalCalendarGridItemsCount,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.85),
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
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected ? goldColor.withOpacity(0.15) : const Color(0xFF0F172A),
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
                                  if (hasSchool) Container(width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1), color: schoolColor),
                                  if (hasAcademy) Container(width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1), color: academyColor),
                                  if (hasExam) Container(width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1), color: examColor),
                                  if (hasPersonal) Container(width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1), color: personalColor),
                                ],
                              )
                            else
                              const SizedBox(height: 5),

                            if (!isBlurred && dayScheduleCount > 0)
                              Text('$dayScheduleCount개', style: GoogleFonts.notoSansKr(fontSize: 12, color: goldColor, fontWeight: FontWeight.bold))
                            else
                              const SizedBox(height: 10),
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