// ============================================================================
// 🆕 [일반 플래너 1단계] CalendarScreen
// 월간 캘린더를 보여주고, 일정이 있는 날짜에 점(●)을 표시합니다.
// 날짜를 탭하면 그날의 일정 목록을 하단에 보여주고, 그 자리에서 새 일정을
// 추가할 수 있습니다. 데이터는 ScheduleDataService를 통해 다른 화면과 공유됩니다.
// 디자인 톤: 기존 앱과 동일한 다크네이비(#030712)+골드(#E5C158) 테마.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'schedule_data_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  DateTime _displayedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime.now();

  Set<String> _datesWithSchedule = {};
  List<ScheduleItem> _selectedDateItems = [];
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
    final dates = await ScheduleDataService.loadDatesWithSchedule();
    final items = await ScheduleDataService.loadForDate(_dateKey(_selectedDate));
    if (!mounted) return;
    setState(() {
      _datesWithSchedule = dates;
      _selectedDateItems = items;
      _isLoading = false;
    });
  }

  Future<void> _onDateTapped(DateTime date) async {
    setState(() => _selectedDate = date);
    final items = await ScheduleDataService.loadForDate(_dateKey(date));
    if (!mounted) return;
    setState(() => _selectedDateItems = items);
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

  Future<void> _showAddScheduleDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    final TextEditingController memoController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _containerBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'ADD SCHEDULE\n(일정 추가)',
          textAlign: TextAlign.center,
          style: GoogleFonts.gowunBatang(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '제목 (예: 병원 예약)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: _pageBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: timeController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '시간 (예: 14:30, 비워도 됨)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: _pageBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: memoController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '메모 (선택)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: _pageBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _brandGolden),
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              Navigator.of(context).pop(true);
            },
            child: const Text('저장', style: TextStyle(color: _pageBg, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && titleController.text.trim().isNotEmpty) {
      final newItem = ScheduleItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        date: _dateKey(_selectedDate),
        time: timeController.text.trim(),
        title: titleController.text.trim(),
        memo: memoController.text.trim(),
      );
      await ScheduleDataService.add(newItem);
      await _loadCalendarData();
    }
  }

  Future<void> _toggleComplete(ScheduleItem item) async {
    item.isCompleted = !item.isCompleted;
    await ScheduleDataService.update(item);
    await _loadCalendarData();
  }

  Future<void> _deleteItem(ScheduleItem item) async {
    await ScheduleDataService.delete(item.id);
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
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('CALENDAR', style: GoogleFonts.gowunBatang(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 20)),
            Text('캘린더', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
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
        onPressed: _showAddScheduleDialog,
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
          '${_displayedMonth.year}년 ${_displayedMonth.month}월',
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
    // 일요일 시작 기준 앞쪽 빈 칸 개수 (weekday: 월=1...일=7 -> 일요일 시작 오프셋으로 변환)
    final int leadingEmpty = firstWeekday % 7; // 일요일이면 0, 월요일이면 1 ...

    final List<Widget> dayCells = [];

    const weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];
    for (final label in weekdayLabels) {
      dayCells.add(
        Center(
          child: Text(label, style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      );
    }

    for (int i = 0; i < leadingEmpty; i++) {
      dayCells.add(const SizedBox.shrink());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final DateTime thisDate = DateTime(_displayedMonth.year, _displayedMonth.month, day);
      final String key = _dateKey(thisDate);
      final bool hasSchedule = _datesWithSchedule.contains(key);
      final bool isSelected = _dateKey(_selectedDate) == key;
      final bool isToday = _dateKey(DateTime.now()) == key;

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
                Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected ? _pageBg : Colors.white,
                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (hasSchedule)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSelected ? _pageBg : _brandGolden,
                      shape: BoxShape.circle,
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
          Text(
            '${_selectedDate.month}월 ${_selectedDate.day}일 일정',
            style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          if (_selectedDateItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('등록된 일정이 없습니다.', style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 13)),
              ),
            )
          else
            ..._selectedDateItems.map((item) => _buildScheduleTile(item)),
        ],
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
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 18),
            onPressed: () => _deleteItem(item),
          ),
        ],
      ),
    );
  }
}
