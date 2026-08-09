// ============================================================================
// 🆕 [일반 플래너 - 병기 업그레이드] RoutineScreen
// 반복되는 일과(기상/운동/출근...)를 템플릿으로 만들어두고, 오늘의 타임라인에
// 버튼 한 번으로 통째로 적용할 수 있는 화면입니다.
// applyToDate가 전달된 경우: 목록에서 루틴을 고르면 그 날짜 타임라인에 적용.
// applyToDate가 null인 경우: 루틴 목록 관리(생성/삭제)만 하는 화면으로 동작.
// 🆕 캘린더/약속/프로젝트/타임라인과 동일한 골드 글로우 팝업 디자인 + 영한 병기.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'timeline_data_service.dart';
import 'bilingual_text.dart';

class RoutineScreen extends StatefulWidget {
  final String? applyToDate;

  const RoutineScreen({super.key, this.applyToDate});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  List<RoutineTemplate> _routines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    setState(() => _isLoading = true);
    final routines = await TimelineDataService.loadRoutines();
    if (!mounted) return;
    setState(() {
      _routines = routines;
      _isLoading = false;
    });
  }

  Future<void> _showCreateRoutineDialog() async {
    final TextEditingController nameController = TextEditingController();
    final List<RoutineItem> tempItems = [];

    final bool? saved = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> addItem() async {
            final TextEditingController titleController = TextEditingController();
            TimeOfDay start = const TimeOfDay(hour: 6, minute: 0);
            TimeOfDay end = const TimeOfDay(hour: 7, minute: 0);

            final bool? itemAdded = await showDialog<bool>(
              context: context,
              builder: (context) => StatefulBuilder(
                builder: (context, setItemState) {
                  return AlertDialog(
                    backgroundColor: _containerBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const BiTitle(en: 'ADD ITEM', ko: '루틴 항목 추가', enSize: 15, koSize: 12),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: biHint('Item Name', 'e.g. 기상'),
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: _pageBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: _brandGolden)),
                                onPressed: () async {
                                  final picked = await showTimePicker(context: context, initialTime: start);
                                  if (picked != null) setItemState(() => start = picked);
                                },
                                child: Text('${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: _brandGolden)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: _brandGolden)),
                                onPressed: () async {
                                  final picked = await showTimePicker(context: context, initialTime: end);
                                  if (picked != null) setItemState(() => end = picked);
                                },
                                child: Text('${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: _brandGolden)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const BiInline(en: 'Cancel', ko: '취소', color: Colors.white54)),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _brandGolden),
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) return;
                          Navigator.of(context).pop(true);
                        },
                        child: const BiInline(en: 'Add', ko: '추가', color: _pageBg, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                },
              ),
            );

            if (itemAdded == true && titleController.text.trim().isNotEmpty) {
              setDialogState(() {
                tempItems.add(RoutineItem(
                  startTime: '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                  endTime: '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                  title: titleController.text.trim(),
                ));
              });
            }
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 22),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF11192E), Color(0xFF0A0F1E)]),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.repeat_rounded, color: _brandGolden, size: 22),
                        const SizedBox(width: 8),
                        const BiTitle(en: 'CREATE ROUTINE', ko: '루틴 만들기', enSize: 16, koSize: 12.5),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, _brandGolden.withOpacity(0.5), Colors.transparent]))),
                    const SizedBox(height: 18),

                    Container(
                      decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                      child: TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.label_outline, color: _brandGolden.withOpacity(0.85), size: 19),
                          hintText: biHint('Routine Name', 'e.g. 평일 아침 루틴'),
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (tempItems.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 160),
                        child: ListView(
                          shrinkWrap: true,
                          children: tempItems
                              .map((item) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 13)),
                            subtitle: Text('${item.startTime} ~ ${item.endTime}', style: const TextStyle(color: _brandGolden, fontSize: 11)),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white38, size: 16),
                              onPressed: () => setDialogState(() => tempItems.remove(item)),
                            ),
                          ))
                              .toList(),
                        ),
                      ),
                    TextButton.icon(
                      onPressed: addItem,
                      icon: const Icon(Icons.add, color: _brandGolden, size: 18),
                      label: const BiInline(en: 'Add Item', ko: '항목 추가', color: _brandGolden, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const BiInline(en: 'Cancel', ko: '취소', color: Colors.white70, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: _brandGolden, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 4, shadowColor: _brandGolden.withOpacity(0.5)),
                            onPressed: () {
                              if (nameController.text.trim().isEmpty || tempItems.isEmpty) return;
                              Navigator.of(context).pop(true);
                            },
                            child: const BiInline(en: 'Save', ko: '저장', color: _pageBg, fontWeight: FontWeight.bold),
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

    if (saved == true && nameController.text.trim().isNotEmpty && tempItems.isNotEmpty) {
      final newRoutine = RoutineTemplate(id: DateTime.now().microsecondsSinceEpoch.toString(), name: nameController.text.trim(), items: tempItems);
      await TimelineDataService.addRoutine(newRoutine);
      await _loadRoutines();
    }
  }

  Future<void> _deleteRoutine(RoutineTemplate routine) async {
    await TimelineDataService.deleteRoutine(routine.id);
    await _loadRoutines();
  }

  Future<void> _applyRoutine(RoutineTemplate routine) async {
    if (widget.applyToDate == null) return;
    await TimelineDataService.applyRoutineToDate(routine, widget.applyToDate!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${routine.name}" applied to today (오늘 타임라인에 적용되었습니다)', style: GoogleFonts.notoSansKr())),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bool isApplyMode = widget.applyToDate != null;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: BiTitle(en: 'ROUTINE', ko: isApplyMode ? '루틴 선택해서 적용' : '루틴', enSize: 19, koSize: 13),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : _routines.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BiInline(en: 'No routines yet. Tap + to create one.', ko: '만들어둔 루틴이 없습니다. + 버튼으로 새 루틴을 만들어 보세요.', color: Colors.white38, fontSize: 13, textAlign: TextAlign.center),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _routines.length,
        itemBuilder: (context, index) {
          final routine = _routines[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _brandGolden.withOpacity(0.25))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(routine.name, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20), onPressed: () => _deleteRoutine(routine)),
                  ],
                ),
                BiInline(en: '${routine.items.length} items', ko: '${routine.items.length}개 항목', color: Colors.white38, fontSize: 12),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: routine.items
                      .map((item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(6)),
                    child: Text('${item.startTime} ${item.title}', style: const TextStyle(color: _brandGolden, fontSize: 11)),
                  ))
                      .toList(),
                ),
                if (isApplyMode) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _brandGolden),
                      onPressed: () => _applyRoutine(routine),
                      child: const BiInline(en: 'Apply to Today', ko: '오늘 타임라인에 적용', color: _pageBg, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _brandGolden,
        onPressed: _showCreateRoutineDialog,
        child: const Icon(Icons.add, color: _pageBg),
      ),
    );
  }
}
