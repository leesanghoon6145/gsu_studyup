// ============================================================================
// 🆕 [일반 플래너 - 고급 팝업 적용] TimelineHistoryScreen (타임 기록)
// 타임라인이 등록된 날짜 목록을 최신순으로 보여주고, 날짜를 탭하면 그 날의
// 전체 타임라인을 조회/수정/삭제하거나 새 항목을 추가할 수 있습니다.
// 🆕 [고급 팝업] 진한 골드 테두리+글로우, 가로 3선(빨/노/파) 연필 아이콘,
// 하단 삭제/취소/저장 한 줄 배치를 실행기록 화면과 동일하게 적용.
// ============================================================================

import 'package:flutter/material.dart';
import 'timeline_data_service.dart';
import 'bilingual_text.dart';

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
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: const BiTitle(en: 'TIMELINE HISTORY', ko: '타임라인 기록', enSize: 16, koSize: 13),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : _dates.isEmpty
          ? Center(child: BiInline(en: 'No timeline history yet', ko: '아직 저장된 타임라인 기록이 없습니다', color: Colors.white38, fontSize: 14))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _dates.length,
        itemBuilder: (context, index) => _buildDateTile(_dates[index]),
      ),
    );
  }

  Widget _buildDateTile(String dateKey) {
    return InkWell(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => _DateTimelineDetailScreen(dateKey: dateKey)));
        await _loadDates(); // 상세화면에서 전부 삭제했을 경우 목록 갱신
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _brandGolden.withOpacity(0.3))),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: _brandGolden, size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text(dateKey, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

// 🆕 [고급 팝업 적용] 특정 날짜의 타임라인을 조회 + 수정/삭제/추가할 수 있는 상세 화면
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
    setState(() => _isLoading = true);
    final blocks = await TimelineDataService.loadForDate(widget.dateKey);
    if (!mounted) return;
    setState(() {
      _blocks = blocks;
      _isLoading = false;
    });
  }

  String _fmtTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _showBlockDialog({TimelineBlock? existing}) async {
    final bool isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final categoryCtrl = TextEditingController(text: existing?.category ?? '');

    TimeOfDay parseOrNow(String? s) {
      if (s != null && s.contains(':')) {
        final p = s.split(':');
        return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      }
      return TimeOfDay.now();
    }

    TimeOfDay plannedStart = parseOrNow(existing?.plannedStart);
    TimeOfDay plannedEnd = parseOrNow(existing?.plannedEnd);

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
                    luxuryDialogHeader(icon: isEdit ? Icons.edit_note_rounded : Icons.add_task_rounded, en: isEdit ? 'EDIT TIMELINE' : 'ADD TIMELINE', ko: isEdit ? '타임라인 수정' : '타임라인 추가'),

                    _buildField(icon: Icons.title_rounded, controller: titleCtrl, hintEn: 'Title', hintKo: 'e.g. 독서'),
                    const SizedBox(height: 12),
                    _buildField(icon: Icons.category_outlined, controller: categoryCtrl, hintEn: 'Category', hintKo: '분류, 비워도 됨'),
                    const SizedBox(height: 14),

                    Row(children: [
                      timeButton('Start', plannedStart, (v) => plannedStart = v),
                      const SizedBox(width: 8),
                      timeButton('End', plannedEnd, (v) => plannedEnd = v),
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
      await _load();
      return;
    }

    if (action == 'save' && titleCtrl.text.trim().isNotEmpty) {
      if (isEdit) {
        final updated = TimelineBlock(
          id: existing!.id,
          date: existing.date,
          plannedStart: _fmtTime(plannedStart),
          plannedEnd: _fmtTime(plannedEnd),
          title: titleCtrl.text.trim(),
          category: categoryCtrl.text.trim().isEmpty ? '일반' : categoryCtrl.text.trim(),
          isRoutine: existing.isRoutine,
          actualStart: existing.actualStart,
          actualEnd: existing.actualEnd,
          status: existing.status,
        );
        await TimelineDataService.updateBlock(updated);
      } else {
        final newBlock = TimelineBlock(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          date: widget.dateKey,
          plannedStart: _fmtTime(plannedStart),
          plannedEnd: _fmtTime(plannedEnd),
          title: titleCtrl.text.trim(),
          category: categoryCtrl.text.trim().isEmpty ? '일반' : categoryCtrl.text.trim(),
        );
        await TimelineDataService.addBlock(newBlock);
      }
      await _load();
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
    final int completed = _blocks.where((b) => b.status == 'completed').length;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text(widget.dateKey, style: const TextStyle(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BiInline(en: 'Completed $completed / ${_blocks.length}', ko: '완료 $completed / ${_blocks.length}', color: _brandGolden, fontWeight: FontWeight.bold),
          const SizedBox(height: 12),
          if (_blocks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(child: BiInline(en: 'No timeline items for this date', ko: '이 날짜에는 등록된 타임라인이 없습니다', color: Colors.white38, fontSize: 13)),
            )
          else
            ..._blocks.map((b) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _brandGolden.withOpacity(0.3))),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      b.status = b.status == 'completed' ? 'planned' : 'completed';
                      if (b.status == 'completed' && (b.actualEnd == null || b.actualEnd!.isEmpty)) {
                        final now = DateTime.now();
                        b.actualEnd = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                      }
                      await TimelineDataService.updateBlock(b);
                      setState(() {});
                    },
                    child: Icon(b.status == 'completed' ? Icons.check_circle : Icons.radio_button_unchecked, color: b.status == 'completed' ? _brandGolden : Colors.white38, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text('${b.plannedStart}~${b.plannedEnd}', style: const TextStyle(color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(b.title, style: const TextStyle(color: Colors.white))),
                  IconButton(
                    icon: const HorizontalPencilIcon(size: 18),
                    onPressed: () => _showBlockDialog(existing: b),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  ),
                ],
              ),
            )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _brandGolden,
        onPressed: () => _showBlockDialog(),
        child: const Icon(Icons.add, color: _pageBg),
      ),
    );
  }
}
