// ============================================================================
// 🆕 [일반 플래너 - 신규 고급 팝업 전면 교체] RoutineScreen
// 반복되는 일과(기상/운동/출근...)를 템플릿으로 만들어두고, 오늘의 타임라인에
// 버튼 한 번으로 통째로 적용할 수 있는 화면입니다.
//
// 🆕 [전면 교체] 기존 팝업(예전 스타일 Dialog+Container)을 전부 없애고,
// bilingual_text.dart의 LuxuryDialogFrame/luxuryDialogHeader/luxuryBottomActions
// 공용 부품으로 다시 만들었습니다. 기존에는 "삭제"만 가능했는데, 이제
// 가로3선(빨/노/파) 연필 아이콘으로 "수정" 진입이 가능하고, 팝업 맨 아래에
// 삭제/취소/저장이 한 줄로 배치됩니다 (신규 생성 시에는 취소/저장 2개만).
//
// applyToDate가 전달된 경우: 목록에서 루틴을 고르면 그 날짜 타임라인에 적용.
// applyToDate가 null인 경우: 루틴 목록 관리(생성/수정/삭제)만 하는 화면으로 동작.
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

  // 🆕 [신 팝업] 루틴 항목(기상/운동 등) 추가 - LuxuryDialogFrame 적용
  Future<RoutineItem?> _showAddItemDialog() async {
    final TextEditingController titleController = TextEditingController();
    TimeOfDay start = const TimeOfDay(hour: 6, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 7, minute: 0);

    final String? action = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (context) => StatefulBuilder(
        builder: (context, setItemState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: LuxuryDialogFrame(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  luxuryDialogHeader(icon: Icons.playlist_add_rounded, en: 'ADD ITEM', ko: '루틴 항목 추가'),

                  Container(
                    decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                    child: TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.label_outline, color: _brandGolden.withOpacity(0.85), size: 19),
                        hintText: biHint('Item Name', 'e.g. 기상'),
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 12)),
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
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 12)),
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: end);
                            if (picked != null) setItemState(() => end = picked);
                          },
                          child: Text('${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: _brandGolden)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  luxuryBottomActions(
                    onCancel: () => Navigator.of(context).pop(null),
                    onSave: () {
                      if (titleController.text.trim().isEmpty) return;
                      Navigator.of(context).pop('save');
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (action == 'save' && titleController.text.trim().isNotEmpty) {
      return RoutineItem(
        startTime: '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
        endTime: '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
        title: titleController.text.trim(),
      );
    }
    return null;
  }

  // 🆕 [신 팝업 전면 교체] 루틴 생성/수정 - 삭제/취소/저장 한 줄 (수정일 때만 삭제 표시)
  Future<void> _showRoutineDialog({RoutineTemplate? existing}) async {
    final bool isEdit = existing != null;
    final TextEditingController nameController = TextEditingController(text: existing?.name ?? '');
    final List<RoutineItem> tempItems = existing != null ? List<RoutineItem>.from(existing.items) : [];

    final String? action = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> addItem() async {
            final newItem = await _showAddItemDialog();
            if (newItem != null) {
              setDialogState(() {
                tempItems.add(newItem);
                // 🆕 [버그 수정] 추가만 하고 정렬을 안 해서 맨 아래에 쌓이던 문제 - 시간순으로 자동 정렬
                tempItems.sort((a, b) => a.startTime.compareTo(b.startTime));
              });
            }
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
                    luxuryDialogHeader(icon: isEdit ? Icons.edit_note_rounded : Icons.repeat_rounded, en: isEdit ? 'EDIT ROUTINE' : 'CREATE ROUTINE', ko: isEdit ? '루틴 수정' : '루틴 만들기'),

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
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: ListView(
                          shrinkWrap: true,
                          children: tempItems
                              .map((item) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                            child: Row(
                              children: [
                                Text('${item.startTime}~${item.endTime}', style: const TextStyle(color: _brandGolden, fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 13))),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white38, size: 16),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                  onPressed: () => setDialogState(() => tempItems.remove(item)),
                                ),
                              ],
                            ),
                          ))
                              .toList(),
                        ),
                      ),
                    TextButton.icon(
                      onPressed: addItem,
                      icon: const Icon(Icons.add, color: _brandGolden, size: 18),
                      label: BiInline(
                        en: 'Add Item', ko: '항목 추가', color: _brandGolden, fontWeight: FontWeight.bold,
                        translations: const {'JA': '項目を追加', 'ZH': '添加项目', 'FR': 'Ajouter un élément', 'DE': 'Element hinzufügen', 'RU': 'Добавить элемент', 'AR': 'إضافة عنصر', 'HI': 'आइटम जोड़ें', 'VI': 'Thêm mục', 'ES': 'Añadir elemento', 'TH': 'เพิ่มรายการ'},
                      ),
                    ),

                    const SizedBox(height: 16),
                    luxuryBottomActions(
                      isEdit: isEdit,
                      onDelete: isEdit ? () => Navigator.of(context).pop('delete') : null,
                      onCancel: () => Navigator.of(context).pop(null),
                      onSave: () {
                        if (nameController.text.trim().isEmpty || tempItems.isEmpty) return;
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
      await TimelineDataService.deleteRoutine(existing.id);
      await _loadRoutines();
      return;
    }

    if (action == 'save' && nameController.text.trim().isNotEmpty && tempItems.isNotEmpty) {
      if (isEdit) {
        final updated = RoutineTemplate(id: existing!.id, name: nameController.text.trim(), items: tempItems);
        await TimelineDataService.updateRoutine(updated);
      } else {
        final newRoutine = RoutineTemplate(id: DateTime.now().microsecondsSinceEpoch.toString(), name: nameController.text.trim(), items: tempItems);
        await TimelineDataService.addRoutine(newRoutine);
      }
      await _loadRoutines();
    }
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
        title: BiTitle(
          en: 'ROUTINE', ko: isApplyMode ? '루틴 선택해서 적용' : '루틴', enSize: 19, koSize: 13,
          translations: isApplyMode
              ? {'JA': 'ルーティンを選んで適用', 'ZH': '选择常规并应用', 'FR': 'Choisir et appliquer une routine', 'DE': 'Routine auswählen und anwenden', 'RU': 'Выбрать и применить распорядок', 'AR': 'اختر وطبق الروتين', 'HI': 'दिनचर्या चुनें और लागू करें', 'VI': 'Chọn và áp dụng thói quen', 'ES': 'Elegir y aplicar rutina', 'TH': 'เลือกและใช้กิจวัตร'}
              : {'JA': 'ルーティン', 'ZH': '常规', 'FR': 'Routine', 'DE': 'Routine', 'RU': 'Распорядок', 'AR': 'الروتين', 'HI': 'दिनचर्या', 'VI': 'Thói quen', 'ES': 'Rutina', 'TH': 'กิจวัตร'},
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : _routines.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BiInline(
            en: 'No routines yet. Tap + to create one.', ko: '만들어둔 루틴이 없습니다. + 버튼으로 새 루틴을 만들어 보세요.', color: Colors.white38, fontSize: 13, textAlign: TextAlign.center,
            translations: const {
              'JA': 'まだルーティンがありません。+ボタンで作成してください。',
              'ZH': '暂无常规。点击+号创建。',
              'FR': "Aucune routine pour l'instant. Appuyez sur + pour en créer une.",
              'DE': 'Noch keine Routinen. Tippen Sie auf +, um eine zu erstellen.',
              'RU': 'Пока нет распорядков. Нажмите +, чтобы создать.',
              'AR': 'لا يوجد روتين بعد. اضغط + للإنشاء.',
              'HI': 'अभी तक कोई दिनचर्या नहीं है। + दबाकर बनाएं।',
              'VI': 'Chưa có thói quen nào. Nhấn + để tạo.',
              'ES': 'Aún no hay rutinas. Toca + para crear una.',
              'TH': 'ยังไม่มีกิจวัตร แตะ + เพื่อสร้าง',
            },
          ),
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
            decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _brandGolden.withOpacity(0.45))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(routine.name, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                    // 🆕 [신 팝업] 삭제 아이콘 단독 제거 -> 가로3선 연필로 교체 (수정 팝업 안에서 삭제 가능)
                    IconButton(
                      icon: const ThreeColorPencilIcon(size: 18),
                      onPressed: () => _showRoutineDialog(existing: routine),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),
                  ],
                ),
                BiInline(
                  en: '${routine.items.length} items', ko: '${routine.items.length}개 항목', color: Colors.white38, fontSize: 12,
                  translations: {
                    'JA': '${routine.items.length}項目', 'ZH': '${routine.items.length}个项目', 'FR': '${routine.items.length} éléments', 'DE': '${routine.items.length} Elemente',
                    'RU': '${routine.items.length} элементов', 'AR': '${routine.items.length} عنصر', 'HI': '${routine.items.length} आइटम', 'VI': '${routine.items.length} mục',
                    'ES': '${routine.items.length} elementos', 'TH': '${routine.items.length} รายการ',
                  },
                ),
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
                      child: BiInline(
                        en: 'Apply to Today', ko: '오늘 타임라인에 적용', color: _pageBg, fontWeight: FontWeight.bold,
                        translations: const {'JA': '今日のタイムラインに適用', 'ZH': '应用到今日时间线', 'FR': "Appliquer à la chronologie du jour", 'DE': 'Auf heutige Zeitleiste anwenden', 'RU': 'Применить к хронологии сегодня', 'AR': 'تطبيق على الجدول الزمني لليوم', 'HI': 'आज की समयरेखा पर लागू करें', 'VI': 'Áp dụng vào dòng thời gian hôm nay', 'ES': 'Aplicar a la cronología de hoy', 'TH': 'ใช้กับไทม์ไลน์วันนี้'},
                      ),
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
        onPressed: () => _showRoutineDialog(),
        child: const Icon(Icons.add, color: _pageBg),
      ),
    );
  }
}
