// exercise_type_edit_screen.dart (v3)
//
// 🆕 [수정/삭제/저장 통합] 하단 버튼 행에 삭제(수정 모드일 때만)/취소/저장 3개를
//    한 줄로 배치. calendar_screen.dart의 _showScheduleDialog와 동일한 패턴.
// 🆕 [영문+한글 병기] 정적 라벨/버튼을 BiInline·biButtonLabel로 통일.
// 🆕 [2026-10-08] 모든 안내 · 단추 · 창 글자를 12개 언어로 (exercise_screen_text.dart)

import 'package:flutter/material.dart';
import 'exercise_models.dart';
import 'exercise_data_service.dart';
import 'exercise_theme.dart';
import 'exercise_screen_text.dart'; // 🆕 [2026-10-08] 글자 12개 언어
import 'exercise_i18n.dart'; // 🆕 [2026-10-08] 기본 종목 항목 이름 번역
import 'exercise_type_names.dart'; // 🆕 [2026-10-08] 종목 이름 12개 언어

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

  // 🆕 [2026-10-08] 칸 안 안내 글자 = 지금 언어 (key 하나로 12개 언어)
  InputDecoration _decoration(String key) => InputDecoration(
    hintText: exText(key),
    hintMaxLines: 2,
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
                  BiInline(en: 'ADD FIELD', ko: '필드 추가', translations: exTextTranslations('edAddField'), color: ExerciseTheme.brandGolden, fontWeight: FontWeight.bold, fontSize: 14),
                  const SizedBox(height: 16),
                  TextField(
                    controller: labelController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _decoration('edFieldName'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: keyController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _decoration('edKey'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<ExerciseFieldType>(
                    initialValue: selectedType,
                    dropdownColor: ExerciseTheme.containerBgElevated,
                    style: const TextStyle(color: Colors.white),
                    isExpanded: true, // 🆕 [2026-10-08] 넘침 방지
                    decoration: _decoration('edInputType'),
                    items: ExerciseFieldType.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(_typeLabel(t), maxLines: 1, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedType = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: unitController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _decoration('edUnit'),
                  ),
                  if (selectedType == ExerciseFieldType.select) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: optionsController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _decoration('edOptions'),
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
                          child: _btn('cancel', Colors.white70),
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
                          child: _btn('add', ExerciseTheme.pageBg),
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

  // 🆕 [2026-10-08] 단추 글자: 한국어 = 영문+한글 두 줄 / 그 외 = 그 언어만
  Widget _btn(String key, Color color) => appLanguage.isDefault
      ? ExerciseTheme.biButtonLabel(exTextIn(key, 'EN'), exTextIn(key, 'KO'), color: color)
      : Text(exText(key), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13));

  // 🆕 [2026-10-08] 입력 방식 이름 (number → 숫자 …)
  String _typeLabel(ExerciseFieldType t) => exText('ft${t.name}');

  // 🆕 [2026-10-08] 기본 종목의 항목 이름은 지금 언어로, 직접 만든 항목은 적은 그대로
  String _fieldLabel(ExerciseField f) {
    if (appLanguage.isDefault || f.enLabel == null || f.enLabel!.isEmpty) return f.label;
    if (appLanguage.isEnglishOnly) return f.enLabel!;
    return kExerciseTermTranslations[f.enLabel]?[appLanguage.current] ?? f.enLabel!;
  }

  void _removeField(int index) {
    setState(() => _fields.removeAt(index));
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    final icon = _iconController.text.trim();
    if (name.isEmpty || _fields.isEmpty) {
      ExerciseTheme.showLuxeSnackBar(context, exText('edNeed'));
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
      title: exText(type.isDefault ? 'edHideTitle' : 'edDelTitle'),
      message: exText(type.isDefault ? 'edHideMsg' : 'edDelMsg', {'n': exerciseLocalName(type)}),
      confirmLabel: exText('del'),
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
        translations: exTextTranslations(_isEditMode ? 'edEditTitle' : 'edAddTitle'), // 🆕 [2026-10-08]
        enSize: 17,
        koSize: 17,
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
                  decoration: _decoration('edIcon'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('edName'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 🆕 [2026-10-08] 글자가 길면 아래 줄로 내려감 (넘침 없음)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              BiInline(en: 'RECORD FIELDS', ko: '기록 필드', translations: exTextTranslations('edFields'), color: ExerciseTheme.brandGolden, fontWeight: FontWeight.bold, fontSize: 13),
              TextButton.icon(
                onPressed: _addFieldDialog,
                icon: const Icon(Icons.add, color: ExerciseTheme.brandGolden, size: 18),
                label: BiInline(en: 'ADD FIELD', ko: '필드 추가', translations: exTextTranslations('edAddField'), color: ExerciseTheme.brandGolden, fontWeight: FontWeight.bold, fontSize: 12),
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
                title: Text(_fieldLabel(field), style: ExerciseTheme.bodyStyle(color: Colors.white, size: 14)), // 🆕 [2026-10-08]
                subtitle: Text(
                  '${_typeLabel(field.type)}${field.unit != null ? ' · ${exUnit(field.unit)}' : ''}',
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
