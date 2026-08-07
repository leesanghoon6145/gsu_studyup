// ============================================================================
// 🆕 [일반 플래너 2단계] TodayTimelineScreen
// 오늘의 시간 블록(00:00~24:00)을 시간순으로 보여줍니다.
// 각 블록마다 [시작] 버튼으로 실행을 시작하고, [완료] 버튼으로 종료하면
// 실제 시작/종료 시간이 자동 기록되어 계획 시간과의 차이가 즉시 계산됩니다.
// 루틴 적용은 RoutineScreen에서 처리하고, 이 화면에는 "루틴 적용" 버튼만 둡니다.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'timeline_data_service.dart';
import 'routine_screen.dart';

class TodayTimelineScreen extends StatefulWidget {
  const TodayTimelineScreen({super.key});

  @override
  State<TodayTimelineScreen> createState() => _TodayTimelineScreenState();
}

class _TodayTimelineScreenState extends State<TodayTimelineScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  List<TimelineBlock> _blocks = [];
  bool _isLoading = true;

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String get _nowHHmm {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    setState(() => _isLoading = true);
    final blocks = await TimelineDataService.loadForDate(_todayKey);
    if (!mounted) return;
    setState(() {
      _blocks = blocks;
      _isLoading = false;
    });
  }

  Future<void> _showAddBlockDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController categoryController = TextEditingController();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(hour: (TimeOfDay.now().hour + 1) % 24, minute: TimeOfDay.now().minute);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: _containerBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'ADD TIMELINE BLOCK\n(타임라인 추가)',
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
                    hintText: '제목 (예: 운동)',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: _pageBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: categoryController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '분류 (예: 업무/운동/휴식, 비워도 됨)',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: _pageBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: _brandGolden)),
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: startTime);
                          if (picked != null) setDialogState(() => startTime = picked);
                        },
                        child: Text('시작 ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: _brandGolden)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: _brandGolden)),
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: endTime);
                          if (picked != null) setDialogState(() => endTime = picked);
                        },
                        child: Text('종료 ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: _brandGolden)),
                      ),
                    ),
                  ],
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
          );
        },
      ),
    );

    if (confirmed == true && titleController.text.trim().isNotEmpty) {
      final newBlock = TimelineBlock(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        date: _todayKey,
        plannedStart: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
        plannedEnd: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
        title: titleController.text.trim(),
        category: categoryController.text.trim().isEmpty ? '일반' : categoryController.text.trim(),
      );
      await TimelineDataService.addBlock(newBlock);
      await _loadTimeline();
    }
  }

  Future<void> _startExecution(TimelineBlock block) async {
    block.actualStart = _nowHHmm;
    block.status = 'running';
    await TimelineDataService.updateBlock(block);
    await _loadTimeline();
  }

  Future<void> _completeExecution(TimelineBlock block) async {
    block.actualEnd = _nowHHmm;
    block.status = 'completed';
    await TimelineDataService.updateBlock(block);
    await _loadTimeline();
  }

  Future<void> _deleteBlock(TimelineBlock block) async {
    await TimelineDataService.deleteBlock(block.id);
    await _loadTimeline();
  }

  Future<void> _copyBlock(TimelineBlock block) async {
    final copy = TimelineBlock(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: block.date,
      plannedStart: block.plannedStart,
      plannedEnd: block.plannedEnd,
      title: '${block.title} (복사)',
      category: block.category,
    );
    await TimelineDataService.addBlock(copy);
    await _loadTimeline();
  }

  Future<void> _applyRoutine() async {
    final applied = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => RoutineScreen(applyToDate: _todayKey)),
    );
    if (applied == true) {
      await _loadTimeline();
    }
  }

  @override
  Widget build(BuildContext context) {
    final int completed = _blocks.where((b) => b.status == 'completed').length;
    final int total = _blocks.length;
    final double rate = total == 0 ? 0 : completed / total;

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
            Text("TODAY'S TIMELINE", style: GoogleFonts.gowunBatang(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('오늘의 타임라인', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.repeat, color: _brandGolden),
            tooltip: '루틴 적용',
            onPressed: _applyRoutine,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : RefreshIndicator(
        color: _brandGolden,
        backgroundColor: _containerBg,
        onRefresh: _loadTimeline,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProgressCard(completed, total, rate),
            const SizedBox(height: 16),
            if (_blocks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    '오늘 등록된 타임라인이 없습니다.\n+ 버튼으로 추가하거나, 상단 🔁으로 루틴을 적용해 보세요.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 13),
                  ),
                ),
              )
            else
              ..._blocks.map((b) => _buildTimelineTile(b)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _brandGolden,
        onPressed: _showAddBlockDialog,
        child: const Icon(Icons.add, color: _pageBg),
      ),
    );
  }

  Widget _buildProgressCard(int completed, int total, double rate) {
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
              Text('완료율', style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              Text('$completed / $total 완료', style: GoogleFonts.notoSansKr(color: _brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 10,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(_brandGolden),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTile(TimelineBlock block) {
    final bool isPlanned = block.status == 'planned';
    final bool isRunning = block.status == 'running';
    final bool isCompleted = block.status == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _containerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isRunning ? _brandGolden : Colors.white12, width: isRunning ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(6)),
                child: Text('${block.plannedStart}~${block.plannedEnd}',
                    style: const TextStyle(color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              if (block.isRoutine)
                const Icon(Icons.repeat, color: Colors.white38, size: 14),
              const Spacer(),
              PopupMenuButton<String>(
                color: _containerBg,
                icon: const Icon(Icons.more_vert, color: Colors.white38, size: 20),
                onSelected: (value) {
                  if (value == 'copy') _copyBlock(block);
                  if (value == 'delete') _deleteBlock(block);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'copy', child: Text('복사', style: GoogleFonts.notoSansKr(color: Colors.white))),
                  PopupMenuItem(value: 'delete', child: Text('삭제', style: GoogleFonts.notoSansKr(color: Colors.redAccent))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            block.title,
            style: TextStyle(
              color: isCompleted ? Colors.white38 : Colors.white,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text('(${block.category})', style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 11)),

          if (isCompleted) ...[
            const SizedBox(height: 8),
            _buildCompletionSummary(block),
          ],

          const SizedBox(height: 10),
          if (isPlanned)
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                onPressed: () => _startExecution(block),
                style: ElevatedButton.styleFrom(backgroundColor: _brandGolden),
                icon: const Icon(Icons.play_arrow, color: _pageBg, size: 18),
                label: const Text('시작', style: TextStyle(color: _pageBg, fontWeight: FontWeight.bold)),
              ),
            ),
          if (isRunning)
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                onPressed: () => _completeExecution(block),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.shade400),
                icon: const Icon(Icons.check, color: _pageBg, size: 18),
                label: Text('완료 (시작 ${block.actualStart})', style: const TextStyle(color: _pageBg, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompletionSummary(TimelineBlock block) {
    final int? diff = block.diffMinutes;
    final String diffText = diff == null
        ? '-'
        : (diff == 0 ? '정확히 맞춤' : (diff > 0 ? '+$diff분 초과' : '${diff.abs()}분 단축'));
    final Color diffColor = (diff == null || diff == 0)
        ? Colors.white54
        : (diff > 0 ? Colors.orangeAccent : Colors.lightGreenAccent);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Expanded(
            child: _buildStat('실제', '${block.actualStart}~${block.actualEnd}'),
          ),
          Expanded(
            child: _buildStat('계획', '${block.plannedMinutes}분'),
          ),
          Expanded(
            child: _buildStat('차이', diffText, color: diffColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10)),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
