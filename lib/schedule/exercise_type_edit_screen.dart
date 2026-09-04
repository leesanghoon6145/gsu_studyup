// exercise_type_edit_screen.dart (v3)
//
// 🆕 [수정/삭제/저장 통합] 하단 버튼 행에 삭제(수정 모드일 때만)/취소/저장 3개를
//    한 줄로 배치. calendar_screen.dart의 _showScheduleDialog와 동일한 패턴.
// 🆕 [영문+한글 병기] 정적 라벨/버튼을 BiInline·biButtonLabel로 통일.

import 'package:flutter/material.dart';
import 'exercise_models.dart';
import 'exercise_data_service.dart';
import 'exercise_theme.dart';

class ExerciseTypeEditScreen extends StatefulWidget {
  final ExerciseType? existingType;

  const ExerciseTypeEditScreen({super.key, this.existingType});

  @override
  State<ExerciseTypeEditScreen> createState() => _ExerciseTypeEditScreenState();
}

class _ExerciseTypeEditScreenState extends State<ExerciseTypeEditScreen> {
  final _service = ExerciseDataService.instance;

  late TextEditingController _nameController;
  late TextEditingController _iconController;
  late List<ExerciseField> _fields;

  bool get _isEditMode => widget.existingType != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingType?.name ?? '');
    _iconController = TextEditingController(text: widget.existingType?.icon ?? '💪');
    _fields = List<ExerciseField>.from(widget.existingType?.fields ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String enHint, String koHint) => InputDecoration(
    hintText: biHint(enHint, koHint),
    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
    filled: true,
    fillColor: ExerciseTheme.containerBg,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: ExerciseTheme.brandGolden.withOpacity(0.25)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: ExerciseTheme.brandGolden.withOpacity(0.25)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ExerciseTheme.brandGolden),
    ),
  );

  Future<void> _addFieldDialog() async {
    final keyController = TextEditingController();
    final labelController = TextEditingController();
    final unitController = TextEditingController();
    final optionsController = TextEditingController();
    ExerciseFieldType selectedType = ExerciseFieldType.number;

    final result = await showDialog<ExerciseField>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: ExerciseTheme.containerBgElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: ExerciseTheme.brandGolden.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BiInline(en: 'ADD FIELD', ko: '필드 추가', color: ExerciseTheme.brandGolden, fontWeight: FontWeight.bold, fontSize: 14),
                  const SizedBox(height: 16),
                  TextField(
                    controller: labelController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _decoration('Field name (e.g. Distance)', '필드 이름 (예: 거리)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: keyController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _decoration('Save key (e.g. distanceKm)', '저장용 key (영문, 예: distanceKm)'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<ExerciseFieldType>(
                    initialValue: selectedType,
                    dropdownColor: ExerciseTheme.containerBgElevated,
                    style: const TextStyle(color: Colors.white),
                    decoration: _decoration('Input type', '입력 타입'),
                    items: ExerciseFieldType.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedType = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: unitController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _decoration('Unit (optional, e.g. km)', '단위 (선택, 예: km)'),
                  ),
                  if (selectedType == ExerciseFieldType.select) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: optionsController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _decoration('Options (comma separated)', '옵션 목록 (쉼표로 구분)'),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: ExerciseTheme.biButtonLabel('Cancel', '취소', color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ExerciseTheme.brandGolden,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 4,
                            shadowColor: ExerciseTheme.brandGolden.withOpacity(0.5),
                          ),
                          onPressed: () {
                            if (labelController.text.trim().isEmpty || keyController.text.trim().isEmpty) {
                              return;
                            }
                            final options = optionsController.text.trim().isEmpty
                                ? null
                                : optionsController.text.split(',').map((e) => e.trim()).toList();
                            Navigator.of(ctx).pop(
                              ExerciseField(
                                key: keyController.text.trim(),
                                type: selectedType,
                                label: labelController.text.trim(),
                                unit: unitController.text.trim().isEmpty ? null : unitController.text.trim(),
                                options: options,
                              ),
                            );
                          },
                          child: ExerciseTheme.biButtonLabel('Add', '추가', color: ExerciseTheme.pageBg),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() => _fields.add(result));
    }
  }

  void _removeField(int index) {
    setState(() => _fields.removeAt(index));
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    final icon = _iconController.text.trim();
    if (name.isEmpty || _fields.isEmpty) {
      ExerciseTheme.showLuxeSnackBar(context, '종목명과 필드를 1개 이상 입력해 주세요.');
      return;
    }

    if (_isEditMode) {
      final updated = widget.existingType!.copyWith(name: name, icon: icon, fields: _fields);
      await _service.updateExerciseType(updated);
    } else {
      await _service.addExerciseType(name: name, icon: icon, fields: _fields);
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  // 🆕 [삭제 통합] 3색 연필로 들어온 이 화면 안에서 삭제까지 처리.
  Future<void> _onDelete() async {
    final type = widget.existingType!;
    final confirmed = await ExerciseTheme.showLuxeConfirmDialog(
      context,
      title: type.isDefault ? '종목 숨기기' : '종목 삭제',
      message: type.isDefault
          ? "'${type.name}' 종목을 목록에서 숨길까요?\n과거 기록 보호를 위해 완전 삭제 대신 숨김 처리됩니다."
          : "'${type.name}' 종목을 삭제할까요?\n이 작업은 되돌릴 수 없습니다.",
      confirmLabel: '삭제',
      isDestructive: true,
      icon: Icons.delete_rounded,
    );
    if (confirmed && mounted) {
      await _service.deleteExerciseType(type.id);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExerciseTheme.pageBg,
      appBar: ExerciseTheme.biAppBar(
        en: _isEditMode ? 'EDIT EXERCISE' : 'ADD EXERCISE',
        ko: _isEditMode ? '종목 수정' : '종목 추가',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                child: TextField(
                  controller: _iconController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 22),
                  decoration: _decoration('Icon', '아이콘'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('Name', '종목명'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BiInline(en: 'RECORD FIELDS', ko: '기록 필드', color: ExerciseTheme.brandGolden, fontWeight: FontWeight.bold, fontSize: 13),
              TextButton.icon(
                onPressed: _addFieldDialog,
                icon: const Icon(Icons.add, color: ExerciseTheme.brandGolden, size: 18),
                label: BiInline(en: 'ADD FIELD', ko: '필드 추가', color: ExerciseTheme.brandGolden, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._fields.asMap().entries.map((entry) {
            final index = entry.key;
            final field = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: ExerciseTheme.luxeCardDecoration(),
              child: ListTile(
                title: Text(field.label, style: ExerciseTheme.bodyStyle(color: Colors.white, size: 14)),
                subtitle: Text(
                  '${field.type.name}${field.unit != null ? ' · ${field.unit}' : ''}',
                  style: ExerciseTheme.bodyStyle(size: 11.5),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => _removeField(index),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),

          // 🆕 [수정/삭제/저장 통합] 삭제(수정 모드만)/취소/저장을 한 줄로 배치
          luxuryBottomActions(
            isEdit: _isEditMode,
            onDelete: _isEditMode ? _onDelete : null,
            onCancel: () => Navigator.of(context).pop(false),
            onSave: _onSave,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
