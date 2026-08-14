// ============================================================================
// 🆕 [일반 플래너 1단계 - 다국어 정리 + 카테고리/디자인 고급화 + UX개선] CalendarScreen
// 월간 캘린더를 보여주고, 일정이 있는 날짜에 카테고리별 색상 점을 표시합니다.
// 날짜를 탭하면 그날의 일정 목록을 하단에 보여주고, 그 자리에서 새 일정을
// 추가/수정할 수 있습니다. 데이터는 ScheduleDataService를 통해 다른 화면과 공유됩니다.
//
// 🆕 [카테고리] 중요일정(빨강)/회사일정(진파랑)/개인일정(진노랑) 3종 프리셋.
// 🆕 [요일 색상] 일요일 날짜 숫자는 빨강, 토요일은 파랑으로 표시.
// 🆕 [수정 UX] 일정 목록의 개별 연필/휴지통 아이콘을 없애고, 3선(파랑/노랑/흰색)
// 연필 모양 아이콘 하나로 통합 — 누르면 수정 팝업이 열리고, 그 팝업 맨 아래에
// 삭제/취소/저장 3개 버튼을 작게 한 줄로 배치함.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'schedule_data_service.dart';
import 'bilingual_text.dart';
import 'holiday_data.dart'; // 🆕 [국경일 표시] 대한민국 공휴일 데이터
import 'appointment_data_service.dart'; // 🆕 [약속 연동] 캘린더에도 약속을 시각적으로 표시
import 'appointment_screen.dart'; // 🆕 [약속 연동] 약속 미리보기 탭하면 이동

// 🆕 카테고리 프리셋 정의 (색상 + 영/한 라벨)
class ScheduleCategory {
  final String koLabel;
  final String enLabel;
  final Color color;
  const ScheduleCategory({required this.koLabel, required this.enLabel, required this.color});
}

const List<ScheduleCategory> kScheduleCategories = [
  ScheduleCategory(koLabel: '중요일정', enLabel: 'Important', color: Color(0xFFDC2626)),
  ScheduleCategory(koLabel: '회사일정', enLabel: 'Company', color: Color(0xFF1E3A8A)),
  ScheduleCategory(koLabel: '개인일정', enLabel: 'Personal', color: Color(0xFFB8860B)),
];

Color categoryColorOf(String category) {
  for (final c in kScheduleCategories) {
    if (c.koLabel == category) return c.color;
  }
  return const Color(0xFFE5C158); // 기존 데이터(분류 미지정)는 골드로 표시
}

// (연필 아이콘 정의는 bilingual_text.dart의 ThreeColorPencilIcon으로 통일됨 - 여기 있던 대각선 버전은 삭제)

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);
  static const Color _sundayRed = Color(0xFFEF4444);
  static const Color _saturdayBlue = Color(0xFF3B82F6);

  DateTime _displayedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime.now();

  Map<String, Set<String>> _categoriesByDate = {};
  Set<String> _datesWithAppointments = {}; // 🆕 [약속 연동]
  List<ScheduleItem> _selectedDateItems = [];
  List<AppointmentItem> _selectedDateAppointments = []; // 🆕 [약속 연동]
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadCalendarData() async {
    setState(() => _isLoading = true);
    final all = await ScheduleDataService.loadAll();
    final Map<String, Set<String>> catMap = {};
    for (final item in all) {
      catMap.putIfAbsent(item.date, () => {}).add(item.category);
    }

    // 🆕 [약속 연동] 약속이 있는 날짜 집합을 만들어 캘린더에 표시
    final allAppointments = await AppointmentDataService.loadAll();
    final Set<String> apptDates = allAppointments.map((a) => a.date).toSet();

    final items = await ScheduleDataService.loadForDate(_dateKey(_selectedDate));
    final selectedAppointments = allAppointments.where((a) => a.date == _dateKey(_selectedDate)).toList();

    if (!mounted) return;
    setState(() {
      _categoriesByDate = catMap;
      _datesWithAppointments = apptDates;
      _selectedDateItems = items;
      _selectedDateAppointments = selectedAppointments;
      _isLoading = false;
    });
  }

  Future<void> _onDateTapped(DateTime date) async {
    setState(() => _selectedDate = date);
    final items = await ScheduleDataService.loadForDate(_dateKey(date));
    final allAppointments = await AppointmentDataService.loadAll();
    final selectedAppointments = allAppointments.where((a) => a.date == _dateKey(date)).toList();
    if (!mounted) return;
    setState(() {
      _selectedDateItems = items;
      _selectedDateAppointments = selectedAppointments; // 🆕 [약속 연동]
    });
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

  // 🆕 [수정/삭제 지원] existingItem이 있으면 "수정 모드" — 팝업 맨 아래에 삭제 버튼도 함께 표시.
  // 반환값: 'save'(저장/수정완료) | 'delete'(삭제) | null(취소)
  Future<void> _showScheduleDialog({ScheduleItem? existingItem}) async {
    final bool isEditMode = existingItem != null;
    final TextEditingController titleController = TextEditingController(text: existingItem?.title ?? '');
    final TextEditingController timeController = TextEditingController(text: existingItem?.time ?? '');
    final TextEditingController memoController = TextEditingController(text: existingItem?.memo ?? '');
    String? selectedCategory = existingItem?.category ??
        (kScheduleCategories.isNotEmpty ? kScheduleCategories.last.koLabel : null); // 기본값: 개인일정

    final String? action = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 22),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF11192E), Color(0xFF0A0F1E)],
                ),
                border: Border.all(color: _brandGolden.withOpacity(0.45), width: 1.2),
                boxShadow: [
                  BoxShadow(color: _brandGolden.withOpacity(0.18), blurRadius: 34, spreadRadius: 1),
                  const BoxShadow(color: Colors.black, blurRadius: 24, offset: Offset(0, 10)),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 상단 헤더
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isEditMode ? Icons.edit_calendar_rounded : Icons.event_available_rounded, color: _brandGolden, size: 22),
                        const SizedBox(width: 8),
                        BiTitle(
                          en: isEditMode ? 'EDIT SCHEDULE' : 'ADD SCHEDULE',
                          ko: isEditMode ? '일정 수정' : '일정 추가',
                          enSize: 17,
                          koSize: 12.5,
                          translations: isEditMode
                              ? {'JA': '予定を編集', 'ZH': '编辑日程', 'FR': 'Modifier le programme', 'DE': 'Termin bearbeiten', 'RU': 'Изменить событие', 'AR': 'تعديل الموعد', 'HI': 'शेड्यूल संपादित करें', 'VI': 'Sửa lịch trình', 'ES': 'Editar horario', 'TH': 'แก้ไขตารางเวลา'}
                              : {'JA': '予定を追加', 'ZH': '添加日程', 'FR': 'Ajouter un programme', 'DE': 'Termin hinzufügen', 'RU': 'Добавить событие', 'AR': 'إضافة موعد', 'HI': 'शेड्यूल जोड़ें', 'VI': 'Thêm lịch trình', 'ES': 'Añadir horario', 'TH': 'เพิ่มตารางเวลา'},
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, _brandGolden.withOpacity(0.5), Colors.transparent],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 카테고리 선택
                    BiInline(
                      en: 'CATEGORY', ko: '분류', color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 12,
                      translations: const {'JA': 'カテゴリー', 'ZH': '分类', 'FR': 'Catégorie', 'DE': 'Kategorie', 'RU': 'Категория', 'AR': 'الفئة', 'HI': 'श्रेणी', 'VI': 'Danh mục', 'ES': 'Categoría', 'TH': 'หมวดหมู่'},
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: kScheduleCategories.map((cat) {
                        final bool isSel = selectedCategory == cat.koLabel;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () => setDialogState(() => selectedCategory = cat.koLabel),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                                decoration: BoxDecoration(
                                  color: isSel ? cat.color.withOpacity(0.18) : _pageBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isSel ? cat.color : Colors.white12, width: isSel ? 1.4 : 1),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(color: cat.color, borderRadius: BorderRadius.circular(3)),
                                    ),
                                    const SizedBox(height: 6),
                                    // 🆕 [영한 병기] 영문(위, 작게) + 한글(아래) 2줄로 표시
                                    Text(
                                      cat.enLabel,
                                      style: GoogleFonts.gowunBatang(
                                        color: isSel ? Colors.white70 : Colors.white38,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      cat.koLabel,
                                      style: GoogleFonts.notoSansKr(
                                        color: isSel ? Colors.white : Colors.white54,
                                        fontSize: 10.5,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    _buildDialogField(icon: Icons.title_rounded, controller: titleController, hintEn: 'Title', hintKo: 'e.g. 병원 예약'),
                    const SizedBox(height: 12),
                    _buildDialogField(icon: Icons.access_time_rounded, controller: timeController, hintEn: 'Time', hintKo: '예: 14:30, 비워도 됨'),
                    const SizedBox(height: 12),
                    _buildDialogField(icon: Icons.notes_rounded, controller: memoController, hintEn: 'Memo', hintKo: '선택 사항', maxLines: 2),

                    const SizedBox(height: 20),

                    // 🆕 [UX개선] 맨 아래 버튼 - 수정 모드일 때만 삭제 버튼 포함, 크기 줄여서 한 줄에 배치
                    Row(
                      children: [
                        if (isEditMode) ...[
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFDC2626)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => Navigator.of(context).pop('delete'),
                              // 🆕 [10개국어 확장] 기본값=2줄(영+한), 외국어 선택시=1줄 단독 표시
                              child: appLanguage.isDefault
                                  ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Delete', style: GoogleFonts.gowunBatang(color: const Color(0xFFDC2626), fontSize: 10.5, fontWeight: FontWeight.bold)),
                                  Text('삭제', style: GoogleFonts.notoSansKr(color: const Color(0xFFDC2626), fontSize: 10.5, fontWeight: FontWeight.bold)),
                                ],
                              )
                                  : Text(tButton('Delete'), style: GoogleFonts.notoSansKr(color: const Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.of(context).pop(null),
                            child: appLanguage.isDefault
                                ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Cancel', style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold)),
                                Text('취소', style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold)),
                              ],
                            )
                                : Text(tButton('Cancel'), style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _brandGolden,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 4,
                              shadowColor: _brandGolden.withOpacity(0.5),
                            ),
                            onPressed: () {
                              if (titleController.text.trim().isEmpty) return;
                              Navigator.of(context).pop('save');
                            },
                            child: appLanguage.isDefault
                                ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(isEditMode ? 'Update' : 'Save', style: GoogleFonts.gowunBatang(color: _pageBg, fontSize: 10.5, fontWeight: FontWeight.bold)),
                                Text(isEditMode ? '수정완료' : '저장', style: GoogleFonts.notoSansKr(color: _pageBg, fontSize: 10.5, fontWeight: FontWeight.bold)),
                              ],
                            )
                                : Text(tButton(isEditMode ? 'Update' : 'Save'), style: GoogleFonts.notoSansKr(color: _pageBg, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (action == 'delete' && existingItem != null) {
      await ScheduleDataService.delete(existingItem.id);
      await _loadCalendarData();
      return;
    }

    if (action == 'save' && titleController.text.trim().isNotEmpty) {
      if (isEditMode) {
        final updated = ScheduleItem(
          id: existingItem!.id,
          date: existingItem.date,
          time: timeController.text.trim(),
          title: titleController.text.trim(),
          memo: memoController.text.trim(),
          category: selectedCategory ?? existingItem.category,
          isCompleted: existingItem.isCompleted,
        );
        await ScheduleDataService.update(updated);
      } else {
        final newItem = ScheduleItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          date: _dateKey(_selectedDate),
          time: timeController.text.trim(),
          title: titleController.text.trim(),
          memo: memoController.text.trim(),
          category: selectedCategory ?? '개인일정',
        );
        await ScheduleDataService.add(newItem);
      }
      await _loadCalendarData();
    }
  }

  Widget _buildDialogField({
    required IconData icon,
    required TextEditingController controller,
    required String hintEn,
    required String hintKo,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _pageBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _brandGolden.withOpacity(0.85), size: 19),
          hintText: biHint(hintEn, hintKo),
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Future<void> _toggleComplete(ScheduleItem item) async {
    item.isCompleted = !item.isCompleted;
    await ScheduleDataService.update(item);
    await _loadCalendarData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: BiTitle(
          en: 'CALENDAR', ko: '캘린더', enSize: 19, koSize: 14,
          translations: const {'JA': 'カレンダー', 'ZH': '日历', 'FR': 'Calendrier', 'DE': 'Kalender', 'RU': 'Календарь', 'AR': 'التقويم', 'HI': 'कैलेंडर', 'VI': 'Lịch', 'ES': 'Calendario', 'TH': 'ปฏิทิน'},
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMonthHeader(),
            const SizedBox(height: 12),
            _buildCalendarGrid(),
            const SizedBox(height: 20),
            _buildSelectedDateSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _brandGolden,
        onPressed: () => _showScheduleDialog(),
        child: const Icon(Icons.add, color: _pageBg),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: _brandGolden),
          onPressed: _goToPreviousMonth,
        ),
        Text(
          '${_displayedMonth.year}.${_displayedMonth.month.toString().padLeft(2, '0')}',
          style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: _brandGolden),
          onPressed: _goToNextMonth,
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final int daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final int firstWeekday = DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday; // 1=월 ~ 7=일
    final int leadingEmpty = firstWeekday % 7; // 일요일 시작 기준 앞쪽 빈 칸

    final List<Widget> dayCells = [];

    const weekdayPairs = [
      ['SUN', '일'], ['MON', '월'], ['TUE', '화'], ['WED', '수'], ['THU', '목'], ['FRI', '금'], ['SAT', '토'],
    ];
    for (int i = 0; i < weekdayPairs.length; i++) {
      final pair = weekdayPairs[i];
      // 🆕 [요일 색상] 요일 헤더도 일요일=빨강, 토요일=파랑으로 구분
      final Color headerColor = i == 0 ? _sundayRed : (i == 6 ? _saturdayBlue : Colors.white);
      dayCells.add(
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(pair[0], style: GoogleFonts.gowunBatang(color: headerColor.withOpacity(0.85), fontSize: 10, fontWeight: FontWeight.w900)),
              Text(pair[1], style: GoogleFonts.notoSansKr(color: headerColor, fontSize: 12, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      );
    }

    for (int i = 0; i < leadingEmpty; i++) {
      dayCells.add(const SizedBox.shrink());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final DateTime thisDate = DateTime(_displayedMonth.year, _displayedMonth.month, day);
      final String key = _dateKey(thisDate);
      final Set<String> cats = _categoriesByDate[key] ?? {};
      final bool isSelected = _dateKey(_selectedDate) == key;
      final bool isToday = _dateKey(DateTime.now()) == key;

      // 🆕 [요일/공휴일 색상] 공휴일이 최우선으로 빨강, 그 다음 일요일 빨강, 토요일 파랑.
      // 선택된 날은 골드 배경과 대비되도록 어두운 색을 유지함.
      final String? holidayName = KoreaHolidays.nameOf(thisDate);
      Color numberColor;
      if (isSelected) {
        numberColor = _pageBg;
      } else if (holidayName != null) {
        numberColor = _sundayRed;
      } else if (thisDate.weekday == DateTime.sunday) {
        numberColor = _sundayRed;
      } else if (thisDate.weekday == DateTime.saturday) {
        numberColor = _saturdayBlue;
      } else {
        numberColor = Colors.white;
      }

      final bool hasAppointment = _datesWithAppointments.contains(key); // 🆕 [약속 연동]

      dayCells.add(
        GestureDetector(
          onTap: () => _onDateTapped(thisDate),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? _brandGolden : (isToday ? _brandGolden.withOpacity(0.15) : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        color: numberColor,
                        fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    // 🆕 [위치 수정] 시계 아이콘을 날짜 숫자 오른쪽 위에 자연스럽게 붙임 (Stack 겹침 대신 Row로 안전하게 배치)
                    if (hasAppointment)
                      Padding(
                        padding: const EdgeInsets.only(left: 1, top: 1),
                        child: Icon(Icons.watch_later_rounded, size: 8, color: isSelected ? _pageBg : Colors.white70),
                      ),
                  ],
                ),
                if (cats.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: cats.take(3).map((c) {
                        final color = isSelected ? _pageBg : categoryColorOf(c);
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.9,
      children: dayCells,
    );
  }

  Widget _buildSelectedDateSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _containerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _brandGolden.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BiInline(
            en: '${_selectedDate.month}/${_selectedDate.day} Schedule',
            ko: '${_selectedDate.month}월 ${_selectedDate.day}일 일정',
            color: _brandGolden,
            fontWeight: FontWeight.bold,
            fontSize: 15,
            translations: {
              'JA': '${_selectedDate.month}月${_selectedDate.day}日の予定',
              'ZH': '${_selectedDate.month}月${_selectedDate.day}日日程',
              'FR': 'Programme du ${_selectedDate.day}/${_selectedDate.month}',
              'DE': 'Termine am ${_selectedDate.day}.${_selectedDate.month}.',
              'RU': 'Расписание на ${_selectedDate.day}.${_selectedDate.month}',
              'AR': 'جدول ${_selectedDate.day}/${_selectedDate.month}',
              'HI': '${_selectedDate.day}/${_selectedDate.month} शेड्यूल',
              'VI': 'Lịch trình ${_selectedDate.day}/${_selectedDate.month}',
              'ES': 'Horario del ${_selectedDate.day}/${_selectedDate.month}',
              'TH': 'ตารางวันที่ ${_selectedDate.day}/${_selectedDate.month}',
            },
          ),
          // 🆕 [국경일 표시] 선택한 날짜가 공휴일이면 이름을 함께 표시
          if (KoreaHolidays.nameOf(_selectedDate) != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.celebration_outlined, color: _sundayRed, size: 14),
                const SizedBox(width: 4),
                Text(
                  KoreaHolidays.nameOf(_selectedDate)!,
                  style: GoogleFonts.notoSansKr(color: _sundayRed, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // 🆕 [시간순 통합 표시] 일정(ScheduleItem)과 약속(AppointmentItem)을 하나로 합쳐서
          // 시간순으로 정렬해 보여줍니다. 이전에는 일정만 보이고 약속은 아예 안 보였습니다.
          Builder(builder: (context) {
            final List<_CalendarDayEntry> combined = [
              ..._selectedDateItems.map((s) => _CalendarDayEntry.schedule(s)),
              ..._selectedDateAppointments.map((a) => _CalendarDayEntry.appointment(a)),
            ];
            final now = DateTime.now();
            final String todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
            final String nowHHmm = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

            if (_dateKey(_selectedDate) == todayKey) {
              // 🆕 [버그 수정] 오늘 날짜를 보고 있으면, 지난 시간은 아래로 내림
              bool isPast(_CalendarDayEntry e) => e.time.isNotEmpty && e.time.compareTo(nowHHmm) < 0;
              combined.sort((a, b) {
                final bool aPast = isPast(a);
                final bool bPast = isPast(b);
                if (aPast != bPast) return aPast ? 1 : -1;
                return b.time.compareTo(a.time); // 같은 그룹 안에서는 최근 시간이 위로
              });
            } else {
              combined.sort((a, b) => a.time.compareTo(b.time));
            }

            if (combined.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: BiInline(
                    en: 'No schedules yet', ko: '등록된 일정이 없습니다', color: Colors.white38, fontSize: 13,
                    translations: const {'JA': 'まだ予定がありません', 'ZH': '暂无日程', 'FR': 'Aucun programme pour le moment', 'DE': 'Noch keine Termine', 'RU': 'Пока нет событий', 'AR': 'لا توجد مواعيد بعد', 'HI': 'अभी तक कोई शेड्यूल नहीं', 'VI': 'Chưa có lịch trình', 'ES': 'Aún no hay horarios', 'TH': 'ยังไม่มีตารางเวลา'},
                  ),
                ),
              );
            }

            return Column(
              children: combined.map((entry) {
                if (entry.schedule != null) return _buildScheduleTile(entry.schedule!);
                return _buildAppointmentPreviewTile(entry.appointment!);
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  // 🆕 [약속 미리보기 타일] 캘린더에서는 약속을 읽기 전용으로 보여주고,
  // 수정/삭제는 약속 화면으로 이동해서 하도록 안내합니다.
  Widget _buildAppointmentPreviewTile(AppointmentItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _pageBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentScreen())),
        child: Row(
          children: [
            Icon(item.isCompleted ? Icons.check_circle : Icons.watch_later_rounded, color: item.isCompleted ? _brandGolden : Colors.white54, size: 20),
            const SizedBox(width: 10),
            if (item.time.isNotEmpty) ...[
              Text(item.time, style: const TextStyle(color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(color: item.isCompleted ? Colors.white38 : Colors.white, decoration: item.isCompleted ? TextDecoration.lineThrough : null, fontWeight: FontWeight.w600),
              ),
            ),
            BiInline(
              en: 'Appt', ko: '약속', color: Colors.white38, fontSize: 10,
              translations: const {'JA': '約束', 'ZH': '约会', 'FR': 'RDV', 'DE': 'Termin', 'RU': 'Встреча', 'AR': 'موعد', 'HI': 'नियुक्ति', 'VI': 'Hẹn', 'ES': 'Cita', 'TH': 'นัด'},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTile(ScheduleItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _pageBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleComplete(item),
            child: Icon(
              item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: item.isCompleted ? _brandGolden : Colors.white38,
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          // 🆕 카테고리 색상 정사각형 (한글 글자 크기)
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: categoryColorOf(item.category), borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 10),
          if (item.time.isNotEmpty) ...[
            Text(item.time, style: const TextStyle(color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(
                color: item.isCompleted ? Colors.white38 : Colors.white,
                decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // 🆕 [UX개선] 연필/휴지통 2개 아이콘 대신 3선 연필 아이콘 하나로 통합 (누르면 수정 팝업, 삭제는 팝업 안에)
          IconButton(
            icon: const ThreeColorPencilIcon(size: 18),
            onPressed: () => _showScheduleDialog(existingItem: item),
          ),
        ],
      ),
    );
  }
}

// 🆕 [시간순 통합 표시] 캘린더 하루 목록에서 일정/약속을 하나로 합쳐 시간순 정렬하기 위한 헬퍼
class _CalendarDayEntry {
  final ScheduleItem? schedule;
  final AppointmentItem? appointment;

  _CalendarDayEntry.schedule(this.schedule) : appointment = null;
  _CalendarDayEntry.appointment(this.appointment) : schedule = null;

  String get time => schedule?.time ?? appointment?.time ?? '';
}
