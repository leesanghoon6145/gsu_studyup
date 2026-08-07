// ============================================================================
// 🆕 [일반 플래너 2단계] RoutineScreen
// 반복되는 일과(기상/운동/출근...)를 템플릿으로 만들어두고, 오늘의 타임라인에
// 버튼 한 번으로 통째로 적용할 수 있는 화면입니다.
// applyToDate가 전달된 경우: 목록에서 루틴을 고르면 그 날짜 타임라인에 적용하고
//   true를 반환하며 이 화면을 닫습니다 (TodayTimelineScreen에서 호출하는 경우).
// applyToDate가 null인 경우: 루틴 목록 관리(생성/삭제)만 하는 화면으로 동작합니다.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'timeline_data_service.dart';

class RoutineScreen extends StatefulWidget {
  final String? applyToDate; // null이면 관리 모드, 값이 있으면 적용 모드

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
                    title: Text('루틴 항목 추가', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '항목 이름 (예: 기상)',
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
                                child: Text('${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(color: _brandGolden)),
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
                                child: Text('${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(color: _brandGolden)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소', style: TextStyle(color: Colors.white54))),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _brandGolden),
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) return;
                          Navigator.of(context).pop(true);
                        },
                        child: const Text('추가', style: TextStyle(color: _pageBg, fontWeight: FontWeight.bold)),
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

          return AlertDialog(
            backgroundColor: _containerBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'CREATE ROUTINE\n(루틴 만들기)',
              textAlign: TextAlign.center,
              style: GoogleFonts.gowunBatang(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 17),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '루틴 이름 (예: 평일 아침 루틴)',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: _pageBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (tempItems.isNotEmpty)
                    SizedBox(
                      height: 150,
                      child: ListView(
                        children: tempItems
                            .map((item) => ListTile(
                          dense: true,
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
                    label: Text('항목 추가', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소', style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _brandGolden),
                onPressed: () {
                  if (nameController.text.trim().isEmpty || tempItems.isEmpty) return;
                  Navigator.of(context).pop(true);
                },
                child: const Text('저장', style: TextStyle(color: _pageBg, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );

    if (saved == true && nameController.text.trim().isNotEmpty && tempItems.isNotEmpty) {
      final newRoutine = RoutineTemplate(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: nameController.text.trim(),
        items: tempItems,
      );
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
      SnackBar(content: Text('"${routine.name}" 루틴이 오늘 타임라인에 적용되었습니다.', style: GoogleFonts.notoSansKr())),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ROUTINE', style: GoogleFonts.gowunBatang(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 20)),
            Text(isApplyMode ? '루틴 선택해서 적용' : '루틴', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : _routines.isEmpty
          ? Center(
        child: Text(
          '만들어둔 루틴이 없습니다.\n+ 버튼으로 새 루틴을 만들어 보세요.',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 14),
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
            decoration: BoxDecoration(
              color: _containerBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _brandGolden.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(routine.name, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
                      onPressed: () => _deleteRoutine(routine),
                    ),
                  ],
                ),
                Text('${routine.items.length}개 항목', style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: routine.items
                      .map((item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(6)),
                    child: Text('${item.startTime} ${item.title}',
                        style: const TextStyle(color: _brandGolden, fontSize: 11)),
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
                      child: const Text('오늘 타임라인에 적용', style: TextStyle(color: _pageBg, fontWeight: FontWeight.bold)),
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
