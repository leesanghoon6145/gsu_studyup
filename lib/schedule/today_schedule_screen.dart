// ============================================================================
// 🆕 [일반 플래너 1단계] TodayScheduleScreen
// 오늘 날짜의 일정만 모아서 시간순으로 보여줍니다. 추가/완료체크/삭제 가능.
// CalendarScreen과 동일한 ScheduleDataService를 사용하므로, 캘린더에서 오늘
// 추가한 일정이 이 화면에도 즉시 나타나고, 반대 방향도 동일하게 반영됩니다.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'schedule_data_service.dart';

class TodayScheduleScreen extends StatefulWidget {
  const TodayScheduleScreen({super.key});

  @override
  State<TodayScheduleScreen> createState() => _TodayScheduleScreenState();
}

class _TodayScheduleScreenState extends State<TodayScheduleScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  List<ScheduleItem> _todayItems = [];
  bool _isLoading = true;

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadTodaySchedule();
  }

  Future<void> _loadTodaySchedule() async {
    setState(() => _isLoading = true);
    final items = await ScheduleDataService.loadForDate(_todayKey);
    if (!mounted) return;
    setState(() {
      _todayItems = items;
      _isLoading = false;
    });
  }

  int get _completedCount => _todayItems.where((e) => e.isCompleted).length;

  double get _completionRate {
    if (_todayItems.isEmpty) return 0;
    return _completedCount / _todayItems.length;
  }

  Future<void> _toggleComplete(ScheduleItem item) async {
    item.isCompleted = !item.isCompleted;
    await ScheduleDataService.update(item);
    await _loadTodaySchedule();
  }

  Future<void> _deleteItem(ScheduleItem item) async {
    await ScheduleDataService.delete(item.id);
    await _loadTodaySchedule();
  }

  Future<void> _showAddDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController timeController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _containerBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "TODAY'S SCHEDULE\n(오늘의 일정 추가)",
          textAlign: TextAlign.center,
          style: GoogleFonts.gowunBatang(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '제목',
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
                hintText: '시간 (예: 09:00, 비워도 됨)',
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
        date: _todayKey,
        time: timeController.text.trim(),
        title: titleController.text.trim(),
      );
      await ScheduleDataService.add(newItem);
      await _loadTodaySchedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final String todayDisplay = '${now.month}월 ${now.day}일 (${weekdayNames[now.weekday - 1]})';

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
            Text("TODAY'S SCHEDULE", style: GoogleFonts.gowunBatang(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('오늘의 일정', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : RefreshIndicator(
        color: _brandGolden,
        backgroundColor: _containerBg,
        onRefresh: _loadTodaySchedule,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(todayDisplay, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildProgressCard(),
            const SizedBox(height: 20),
            if (_todayItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('오늘 등록된 일정이 없습니다.\n+ 버튼으로 추가해 보세요.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 14)),
                ),
              )
            else
              ..._todayItems.map((item) => _buildScheduleTile(item)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _brandGolden,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: _pageBg),
      ),
    );
  }

  Widget _buildProgressCard() {
    final int total = _todayItems.length;
    final int done = _completedCount;
    final int percent = (total == 0) ? 0 : (_completionRate * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _containerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _brandGolden.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('오늘의 완료율', style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              Text('$done / $total 완료', style: GoogleFonts.notoSansKr(color: _brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _completionRate,
              minHeight: 10,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(_brandGolden),
            ),
          ),
          const SizedBox(height: 6),
          Text('$percent%', style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildScheduleTile(ScheduleItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _containerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleComplete(item),
            child: Icon(
              item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: item.isCompleted ? _brandGolden : Colors.white38,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          if (item.time.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(6)),
              child: Text(item.time, style: const TextStyle(color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(
                color: item.isCompleted ? Colors.white38 : Colors.white,
                decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
            onPressed: () => _deleteItem(item),
          ),
        ],
      ),
    );
  }
}
