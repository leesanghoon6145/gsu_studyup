// ============================================================================
// 🆕 [일반 플래너 2단계] TimelineHistoryScreen
// 타임라인이 등록된 날짜 목록을 최신순으로 보여주고, 날짜를 탭하면 그 날의
// 전체 타임라인(계획/실제/완료여부)을 조회할 수 있습니다. 오늘의 타임라인
// 화면과 달리 시작/완료 버튼은 없는 "읽기 전용 조회" 화면입니다.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'timeline_data_service.dart';

class TimelineHistoryScreen extends StatefulWidget {
  const TimelineHistoryScreen({super.key});

  @override
  State<TimelineHistoryScreen> createState() => _TimelineHistoryScreenState();
}

class _TimelineHistoryScreenState extends State<TimelineHistoryScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  List<String> _dates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDates();
  }

  Future<void> _loadDates() async {
    setState(() => _isLoading = true);
    final dates = await TimelineDataService.loadDatesWithTimeline();
    if (!mounted) return;
    setState(() {
      _dates = dates;
      _isLoading = false;
    });
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
            Text('TIMELINE HISTORY', style: GoogleFonts.gowunBatang(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('타임라인 기록', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : _dates.isEmpty
          ? Center(
        child: Text('아직 저장된 타임라인 기록이 없습니다.',
            style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 14)),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _dates.length,
        itemBuilder: (context, index) {
          final dateKey = _dates[index];
          return _buildDateTile(dateKey);
        },
      ),
    );
  }

  Widget _buildDateTile(String dateKey) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _DateTimelineDetailScreen(dateKey: dateKey)),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _containerBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: _brandGolden, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(dateKey, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

// 🆕 특정 날짜의 타임라인을 읽기 전용으로 보여주는 상세 화면
class _DateTimelineDetailScreen extends StatefulWidget {
  final String dateKey;
  const _DateTimelineDetailScreen({required this.dateKey});

  @override
  State<_DateTimelineDetailScreen> createState() => _DateTimelineDetailScreenState();
}

class _DateTimelineDetailScreenState extends State<_DateTimelineDetailScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  List<TimelineBlock> _blocks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final blocks = await TimelineDataService.loadForDate(widget.dateKey);
    if (!mounted) return;
    setState(() {
      _blocks = blocks;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int completed = _blocks.where((b) => b.status == 'completed').length;

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
        title: Text(widget.dateKey, style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('완료 $completed / ${_blocks.length}', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._blocks.map((b) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
            child: Row(
              children: [
                Icon(
                  b.status == 'completed' ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: b.status == 'completed' ? _brandGolden : Colors.white38,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text('${b.plannedStart}~${b.plannedEnd}', style: const TextStyle(color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Expanded(child: Text(b.title, style: const TextStyle(color: Colors.white))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
