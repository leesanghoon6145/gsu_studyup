// ============================================================================
// 🆕 [일반 플래너 - 고급 팝업 적용] ExecutionRecordScreen (실행 기록)
// 완료(status='completed')된 타임라인 블록 전체를 최신순으로 모아 보여줍니다.
// 각 기록을 눌러서 수정/삭제할 수 있고, + 버튼으로 지나간 실행 기록을 직접
// 추가할 수도 있습니다(예: 방금 깜빡하고 앱에 기록 안 한 운동을 나중에 기입).
// 🆕 [고급 팝업] 더 진하고 선명한 골드 테두리+글로우, 가로 3선(빨/노/파)
// 연필 아이콘으로 수정 진입, 하단 삭제/취소/저장 한 줄 배치.
// ============================================================================

import 'package:flutter/material.dart';
import 'timeline_data_service.dart';
import 'bilingual_text.dart';

class ExecutionRecordScreen extends StatefulWidget {
  const ExecutionRecordScreen({super.key});

  @override
  State<ExecutionRecordScreen> createState() => _ExecutionRecordScreenState();
}

class _ExecutionRecordScreenState extends State<ExecutionRecordScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  List<TimelineBlock> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final records = await TimelineDataService.loadCompletedBlocks();
    if (!mounted) return;
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  String _fmtTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _showRecordDialog({TimelineBlock? existing}) async {
    final bool isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final categoryCtrl = TextEditingController(text: existing?.category ?? '');
    DateTime selectedDate = existing != null && existing.date.isNotEmpty ? DateTime.tryParse(existing.date) ?? DateTime.now() : DateTime.now();

    TimeOfDay parseOrNow(String? s) {
      if (s != null && s.contains(':')) {
        final p = s.split(':');
        return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      }
      return TimeOfDay.now();
    }

    TimeOfDay plannedStart = parseOrNow(existing?.plannedStart);
    TimeOfDay plannedEnd = parseOrNow(existing?.plannedEnd);
    TimeOfDay actualStart = parseOrNow(existing?.actualStart);
    TimeOfDay actualEnd = parseOrNow(existing?.actualEnd);

    final String? action = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Widget timeButton(String label, TimeOfDay value, void Function(TimeOfDay) onPicked) {
            return Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 10)),
                onPressed: () async {
                  final picked = await showTimePicker(context: context, initialTime: value);
                  if (picked != null) setDialogState(() => onPicked(picked));
                },
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
                  Text(_fmtTime(value), style: const TextStyle(color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
              ),
            );
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: LuxuryDialogFrame(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    luxuryDialogHeader(icon: isEdit ? Icons.edit_note_rounded : Icons.add_task_rounded, en: isEdit ? 'EDIT RECORD' : 'ADD RECORD', ko: isEdit ? '기록 수정' : '기록 추가'),

                    _buildField(icon: Icons.title_rounded, controller: titleCtrl, hintEn: 'Title', hintKo: 'e.g. 아침 운동'),
                    const SizedBox(height: 12),
                    _buildField(icon: Icons.category_outlined, controller: categoryCtrl, hintEn: 'Category', hintKo: '분류, 비워도 됨'),
                    const SizedBox(height: 14),

                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 12), minimumSize: const Size(double.infinity, 0)),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(DateTime.now().year - 2),
                          lastDate: DateTime.now(),
                          builder: (ctx, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: _brandGolden, onPrimary: _pageBg, surface: _containerBg)), child: child!),
                        );
                        if (picked != null) setDialogState(() => selectedDate = picked);
                      },
                      icon: const Icon(Icons.event_rounded, color: _brandGolden, size: 16),
                      label: Text('${selectedDate.year}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.day.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                    const SizedBox(height: 14),

                    const BiInline(en: 'PLANNED', ko: '계획 시간', color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 12),
                    const SizedBox(height: 8),
                    Row(children: [
                      timeButton('Start', plannedStart, (v) => plannedStart = v),
                      const SizedBox(width: 8),
                      timeButton('End', plannedEnd, (v) => plannedEnd = v),
                    ]),
                    const SizedBox(height: 14),

                    const BiInline(en: 'ACTUAL', ko: '실제 시간', color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 12),
                    const SizedBox(height: 8),
                    Row(children: [
                      timeButton('Start', actualStart, (v) => actualStart = v),
                      const SizedBox(width: 8),
                      timeButton('End', actualEnd, (v) => actualEnd = v),
                    ]),

                    const SizedBox(height: 20),
                    luxuryBottomActions(
                      isEdit: isEdit,
                      onDelete: isEdit ? () => Navigator.of(context).pop('delete') : null,
                      onCancel: () => Navigator.of(context).pop(null),
                      onSave: () {
                        if (titleCtrl.text.trim().isEmpty) return;
                        Navigator.of(context).pop('save');
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (action == 'delete' && existing != null) {
      await TimelineDataService.deleteBlock(existing.id);
      await _loadRecords();
      return;
    }

    if (action == 'save' && titleCtrl.text.trim().isNotEmpty) {
      final dateKey = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      if (isEdit) {
        final updated = TimelineBlock(
          id: existing!.id,
          date: dateKey,
          plannedStart: _fmtTime(plannedStart),
          plannedEnd: _fmtTime(plannedEnd),
          title: titleCtrl.text.trim(),
          category: categoryCtrl.text.trim().isEmpty ? '일반' : categoryCtrl.text.trim(),
          isRoutine: existing.isRoutine,
          actualStart: _fmtTime(actualStart),
          actualEnd: _fmtTime(actualEnd),
          status: 'completed',
        );
        await TimelineDataService.updateBlock(updated);
      } else {
        final newBlock = TimelineBlock(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          date: dateKey,
          plannedStart: _fmtTime(plannedStart),
          plannedEnd: _fmtTime(plannedEnd),
          title: titleCtrl.text.trim(),
          category: categoryCtrl.text.trim().isEmpty ? '일반' : categoryCtrl.text.trim(),
          actualStart: _fmtTime(actualStart),
          actualEnd: _fmtTime(actualEnd),
          status: 'completed',
        );
        await TimelineDataService.addBlock(newBlock);
      }
      await _loadRecords();
    }
  }

  Widget _buildField({required IconData icon, required TextEditingController controller, required String hintEn, required String hintKo}) {
    return Container(
      decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
      child: TextField(
        controller: controller,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: const BiTitle(en: 'EXECUTION RECORD', ko: '실행 기록', enSize: 16, koSize: 13),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : _records.isEmpty
          ? Center(child: BiInline(en: 'No records yet. Tap + to add one.', ko: '아직 완료된 실행 기록이 없습니다. + 버튼으로 추가해 보세요.', color: Colors.white38, fontSize: 13, textAlign: TextAlign.center))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _records.length,
        itemBuilder: (context, index) => _buildRecordTile(_records[index]),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _brandGolden,
        onPressed: () => _showRecordDialog(),
        child: const Icon(Icons.add, color: _pageBg),
      ),
    );
  }

  Widget _buildRecordTile(TimelineBlock block) {
    final int? diff = block.diffMinutes;
    final String diffText = diff == null ? '-' : (diff == 0 ? 'On time (정확히 맞춤)' : (diff > 0 ? '+${diff}min (${diff}분 초과)' : '${diff.abs()}min saved (${diff.abs()}분 단축)'));
    final Color diffColor = (diff == null || diff == 0) ? Colors.white54 : (diff > 0 ? Colors.orangeAccent : Colors.lightGreenAccent);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _brandGolden.withOpacity(0.4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(block.date, style: const TextStyle(color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('(${block.category})', style: const TextStyle(color: Colors.white38, fontSize: 11)),
              const SizedBox(width: 4),
              IconButton(
                icon: const ThreeColorPencilIcon(size: 18),
                onPressed: () => _showRecordDialog(existing: block),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ],
          ),
          Text(block.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Expanded(child: _buildStat('Planned', '계획', '${block.plannedStart}~${block.plannedEnd}')),
                Expanded(child: _buildStat('Actual', '실제', '${block.actualStart}~${block.actualEnd}')),
                Expanded(child: _buildStat('Diff', '차이', diffText, color: diffColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String en, String ko, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BiInline(en: en, ko: ko, color: Colors.white38, fontSize: 9),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
