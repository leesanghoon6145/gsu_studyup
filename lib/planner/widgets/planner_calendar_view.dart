import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../global_lang.dart'; // 👑 [12개국 연동] 전역 언어 스위치와 연결

/// ============================================================================
/// [GKE StudyUp] 일간 뷰 전용 달력 제어 레일 및 날짜 선택 그리드 위젯
/// 🆕 [2026-07-30] 이전달/다음달 이동 기능 추가: 선택된 날짜와 별개로 달력에 표시되는
/// "달"을 독립적으로 넘겨볼 수 있도록 StatefulWidget으로 전환함.
/// ============================================================================
class PlannerCalendarView extends StatefulWidget {
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
  State<PlannerCalendarView> createState() => _PlannerCalendarViewState();
}

class _PlannerCalendarViewState extends State<PlannerCalendarView> {
  // 🆕 [2026-07-30] 달력에 "표시 중인 달" — selectedDayDate와 독립적으로 이전/다음 이동 가능
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(widget.selectedDayDate.year, widget.selectedDayDate.month, 1);
  }

  @override
  void didUpdateWidget(covariant PlannerCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // [주석] 외부(다른 화면 등)에서 selectedDayDate의 달이 바뀌면 달력도 그 달을 따라감
    if (oldWidget.selectedDayDate.year != widget.selectedDayDate.year ||
        oldWidget.selectedDayDate.month != widget.selectedDayDate.month) {
      _displayedMonth = DateTime(widget.selectedDayDate.year, widget.selectedDayDate.month, 1);
    }
  }

  void _goToPreviousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  // ============================================================================
  // 🆕 [12개국 언어 시스템]
  // 기본값(마이페이지에서 12개국 중 하나를 고르기 전, 즉 DkeLang.current == 'KO' 상태 포함)은
  // 항상 "영문 + 한글"이 함께 보입니다 — 12개국에 없는 다른 나라 사용자도 영어로 볼 수 있게 하기 위함.
  // 한국어/영어를 "제외한" 나머지 10개국 중 하나를 선택했을 때만 그 언어 단독으로 전환됩니다.
  // ============================================================================
  static const List<String> _foreignLanguages = ['JA', 'ZH', 'FR', 'DE', 'RU', 'AR', 'HI', 'VI', 'ES', 'TH'];
  static bool get _isForeignSelected => _foreignLanguages.contains(DkeLang.current);

  static const Map<String, Map<String, String>> _uiText = {
    'viewSelectedDateMemo': {
      'KO': '선택 날짜 메모 보기', 'EN': 'View Notes for Selected Date',
      'JA': '選択日のメモを見る', 'ZH': '查看所选日期备注', 'FR': 'Voir les notes de la date sélectionnée',
      'DE': 'Notizen zum gewählten Datum ansehen', 'RU': 'Просмотр заметок за выбранную дату', 'AR': 'عرض ملاحظات التاريخ المحدد',
      'HI': 'चयनित तिथि के नोट्स देखें', 'VI': 'Xem ghi chú ngày đã chọn', 'ES': 'Ver notas de la fecha seleccionada', 'TH': 'ดูบันทึกของวันที่เลือก',
    },
    'dateControlRail': {
      'KO': '달력 제어 레일', 'EN': 'Date Control Rail',
      'JA': 'カレンダー操作パネル', 'ZH': '日历控制面板', 'FR': 'Panneau de contrôle du calendrier',
      'DE': 'Kalender-Steuerleiste', 'RU': 'Панель управления календарём', 'AR': 'شريط التحكم بالتقويم',
      'HI': 'कैलेंडर नियंत्रण पैनल', 'VI': 'Bảng điều khiển lịch', 'ES': 'Panel de control del calendario', 'TH': 'แผงควบคุมปฏิทิน',
    },
  };

  static String _foreignOnly(Map<String, String> map) {
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? '';
  }

  // 🆕 한 줄짜리 문자열에서 사용: 기본값 = "EN / KO" 한 줄, 10개국 선택 시 = 단일 언어
  static String _biStr(String key) {
    if (_isForeignSelected) return _foreignOnly(_uiText[key]!);
    final map = _uiText[key]!;
    return '${map['EN']} / ${map['KO']}';
  }

  // 🆕 [12개국 요일] 언어별(10개국) 일요일 시작 요일 약어 배열 — 선택된 언어 단독 표시용
  static const Map<String, List<String>> _weekdaySunFirstForeign = {
    'JA': ['日', '月', '火', '水', '木', '金', '土'],
    'ZH': ['日', '一', '二', '三', '四', '五', '六'],
    'FR': ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'],
    'DE': ['So', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa'],
    'RU': ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'],
    'AR': ['أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'],
    'HI': ['रवि', 'सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि'],
    'VI': ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'],
    'ES': ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'],
    'TH': ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'],
  };
  // 🆕 [12개국] 기본값(영+한)용 고정 배열 — 항상 일요일 시작
  static const List<String> _weekdaySunFirstEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const List<String> _weekdaySunFirstKo = ['일', '월', '화', '수', '목', '금', '토'];

  static List<String>? get _weekdaysForeignOrNull => _weekdaySunFirstForeign[DkeLang.current];

  // 🆕 [12개국 어순 대응] 기본값(영+한)은 "2026 / 7" 형식, 10개국 선택 시엔 그대로 숫자만 사용
  static String _yearMonthNumeric(int year, int month) => '$year / $month';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // [주석] 👑 "07/02" 형태의 달력 열기·닫기 토글 버튼 (팝업 삭제 및 순수 토글 기능만 연동)
        GestureDetector(
          onTap: () {
            // [주석] 팝업 호출 코드를 삭제하고 오직 달력 열기/닫기 토글만 실행
            widget.onToggleCalendar();
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
                // 🆕 [오버플로우 방지 2026-07-29] Expanded로 감싸서 남은 폭 안에서만 표시되도록 제한.
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        color: Color(0xFFE5C158),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // [주석] 👑 "07/02" 월일 동적 표시 (명조체 글자크기 15, 황금색)
                            Text(
                              '${widget.selectedDayDate.month.toString().padLeft(2, '0')}/${widget.selectedDayDate.day.toString().padLeft(2, '0')}',
                              style: GoogleFonts.notoSerif(
                                fontSize: 15,
                                color: const Color(0xFFE5C158),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // [주석] 👑 12개국 확장: 선택 날짜 메모 보기 안내 문구 (기본값 = 영+한 한 줄, 10개국 선택 시 단일 언어)
                            Text(
                              _biStr('viewSelectedDateMemo'),
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              maxLines: 1,
                              style: GoogleFonts.notoSans(
                                fontSize: 12,
                                color: const Color(0xFFE5C158),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  widget.isDayCalendarVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color(0xFFE5C158),
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        // [주석] 펼침 상태일 때 달력 본판 그리드 출력 (오버플로 방지 패딩 및 비율 최적화)
        if (widget.isDayCalendarVisible) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.slate800),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🆕 [2026-07-30] 이전달/다음달 이동 화살표 + 연/월 + "달력 제어 레일" 텍스트
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _goToPreviousMonth,
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        child: Icon(Icons.chevron_left, color: widget.goldColor, size: 22),
                      ),
                    ),

                    Expanded(
                      child: Text(
                        '${_yearMonthNumeric(_displayedMonth.year, _displayedMonth.month)} ${_biStr('dateControlRail')}',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        maxLines: 1,
                        style: GoogleFonts.notoSansKr(fontSize: 13, color: widget.goldColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _goToNextMonth,
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        child: Icon(Icons.chevron_right, color: widget.goldColor, size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // [주석] 요일 헤더 라인 (일~토) — 🆕 [12개국] 기본값 = 영문+한글 2줄, 10개국 선택 시 = 단일 언어
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 7,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1.3),
                  itemBuilder: (context, index) {
                    final Color dayColor = index == 0 ? widget.examColor : (index == 6 ? widget.schoolColor : widget.slate400);
                    if (_isForeignSelected) {
                      final foreignList = _weekdaysForeignOrNull;
                      final label = foreignList != null ? foreignList[index] : _weekdaySunFirstEn[index];
                      return Center(
                        child: Text(
                          label,
                          style: GoogleFonts.notoSans(fontSize: 12, color: dayColor, fontWeight: FontWeight.bold),
                        ),
                      );
                    }
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_weekdaySunFirstEn[index], style: GoogleFonts.notoSerif(fontSize: 10, color: dayColor, fontWeight: FontWeight.bold)),
                          Text(_weekdaySunFirstKo[index], style: GoogleFonts.notoSansKr(fontSize: 12, color: dayColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(color: Color(0xFF1E293B), height: 6),

                // [주석] 날짜 숫자 그리드 빌더 (오버플로 차단 규격) — 🆕 이제 _displayedMonth 기준으로 계산
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _totalCalendarGridItemsCount,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, index) {
                    int displayDayNum = 1;
                    bool isBlurred = false;

                    if (index < _emptyPrefixCellsCount) {
                      displayDayNum = _prevMonthTotalDays - (_emptyPrefixCellsCount - index - 1);
                      isBlurred = true;
                    } else if (index >= (_emptyPrefixCellsCount + _totalDaysInMonth)) {
                      displayDayNum = index - (_emptyPrefixCellsCount + _totalDaysInMonth) + 1;
                      isBlurred = true;
                    } else {
                      displayDayNum = index - _emptyPrefixCellsCount + 1;
                    }

                    // [주석] 해당 날짜의 스케줄 도트 색상 판별 매핑 트랙 (🆕 _displayedMonth 기준)
                    bool hasSchool = false; bool hasAcademy = false; bool hasExam = false; bool hasPersonal = false;
                    int dayScheduleCount = 0;

                    if (!isBlurred) {
                      var daySchedules = widget.globalSchedules.where((s) =>
                      s['year'] == _displayedMonth.year && s['month'] == _displayedMonth.month && s['day'] == displayDayNum);
                      dayScheduleCount = daySchedules.length;
                      for (var s in daySchedules) {
                        if (s['color'] == widget.schoolColor) hasSchool = true;
                        if (s['color'] == widget.academyColor) hasAcademy = true;
                        if (s['color'] == widget.examColor) hasExam = true;
                        if (s['color'] == widget.personalColor) hasPersonal = true;
                      }
                    }

                    // 🆕 선택 상태 판별에 연/월까지 같이 비교 (이제 다른 달을 보고 있을 수 있으므로)
                    bool isSelected = !isBlurred &&
                        widget.selectedDayDate.year == _displayedMonth.year &&
                        widget.selectedDayDate.month == _displayedMonth.month &&
                        widget.selectedDayDate.day == displayDayNum;

                    return GestureDetector(
                      onTap: () {
                        if (isBlurred) return;
                        widget.onDaySelected(DateTime(_displayedMonth.year, _displayedMonth.month, displayDayNum));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected ? widget.goldColor.withValues(alpha: 0.15) : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isSelected ? widget.goldColor : widget.slate800, width: isSelected ? 1.5 : 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$displayDayNum', style: GoogleFonts.notoSerif(fontSize: 12, color: isBlurred ? widget.slate500 : (isSelected ? widget.goldColor : Colors.white), fontWeight: FontWeight.bold)),
                            if (!isBlurred)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (hasSchool) Container(width: 3.5, height: 3.5, margin: const EdgeInsets.symmetric(horizontal: 0.5), color: widget.schoolColor),
                                  if (hasAcademy) Container(width: 3.5, height: 3.5, margin: const EdgeInsets.symmetric(horizontal: 0.5), color: widget.academyColor),
                                  if (hasExam) Container(width: 3.5, height: 3.5, margin: const EdgeInsets.symmetric(horizontal: 0.5), color: widget.examColor),
                                  if (hasPersonal) Container(width: 3.5, height: 3.5, margin: const EdgeInsets.symmetric(horizontal: 0.5), color: widget.personalColor),
                                ],
                              )
                            else
                              const SizedBox(height: 3),

                            // 🆕 [12개국] 숫자만 표시 (칸이 작아 언어 문구를 넣기 어려워 국제 공통 숫자만 사용)
                            if (!isBlurred && dayScheduleCount > 0)
                              Text('$dayScheduleCount', overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSans(fontSize: 10, color: widget.goldColor, fontWeight: FontWeight.bold))
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

  // [주석] 매월 1일의 요일 및 그리드 칸수 자동 역산 알고리즘 구간 (🆕 이제 _displayedMonth 기준)
  int get _firstDayWeekdayIndex {
    final firstDayOfCurrentMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    return firstDayOfCurrentMonth.weekday;
  }

  int get _emptyPrefixCellsCount => _firstDayWeekdayIndex == 7 ? 0 : _firstDayWeekdayIndex;
  int get _totalDaysInMonth => DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
  int get _prevMonthTotalDays => DateTime(_displayedMonth.year, _displayedMonth.month, 0).day;

  int get _totalCalendarGridItemsCount {
    int count = _emptyPrefixCellsCount + _totalDaysInMonth;
    if (count % 7 != 0) {
      count += (7 - (count % 7));
    }
    return count;
  }
}
