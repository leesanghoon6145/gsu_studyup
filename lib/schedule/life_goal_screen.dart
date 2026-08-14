// ============================================================================
// 🆕 [일반 플래너 - 고급 팝업 + 병기 적용] LifeGoalScreen
// 장기적인 인생 목표를 관리합니다. period_goal_screen.dart와 동일한 디자인
// 원칙(진한 골드 팝업, 가로3선 연필, 하단 삭제/취소/저장 한 줄, 영한 병기)을
// 적용했습니다. 기간(periodKey) 개념이 없다는 점만 기간별 목표와 다릅니다.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'goal_data_service.dart';
import 'bilingual_text.dart';

class LifeGoalScreen extends StatefulWidget {
  const LifeGoalScreen({super.key});

  @override
  State<LifeGoalScreen> createState() => _LifeGoalScreenState();
}

class _LifeGoalScreenState extends State<LifeGoalScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  List<GoalItem> _goals = [];
  Map<String, double> _progressCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    final goals = await GoalDataService.loadGoalsByType('life');
    final Map<String, double> progressMap = {};
    for (final g in goals) {
      progressMap[g.id] = await GoalDataService.calcGoalProgress(g.id);
    }
    if (!mounted) return;
    setState(() {
      _goals = goals;
      _progressCache = progressMap;
      _isLoading = false;
    });
  }

  Future<void> _showGoalDialog({GoalItem? existing}) async {
    final bool isEdit = existing != null;
    final titleController = TextEditingController(text: existing?.title ?? '');
    final categoryController = TextEditingController(text: existing?.category ?? '');
    bool isAchieved = existing?.isAchieved ?? false;

    final String? action = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: LuxuryDialogFrame(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    luxuryDialogHeader(
                      icon: isEdit ? Icons.edit_note_rounded : Icons.stars_rounded,
                      en: isEdit ? 'EDIT LIFE GOAL' : 'ADD LIFE GOAL', ko: isEdit ? '인생 목표 수정' : '인생 목표 추가',
                      translations: isEdit
                          ? {'JA': '人生目標を編集', 'ZH': '编辑人生目标', 'FR': 'Modifier objectif de vie', 'DE': 'Lebensziel bearbeiten', 'RU': 'Изменить жизненную цель', 'AR': 'تعديل هدف الحياة', 'HI': 'जीवन लक्ष्य संपादित करें', 'VI': 'Sửa mục tiêu cuộc đời', 'ES': 'Editar objetivo de vida', 'TH': 'แก้ไขเป้าหมายชีวิต'}
                          : {'JA': '人生目標を追加', 'ZH': '添加人生目标', 'FR': 'Ajouter objectif de vie', 'DE': 'Lebensziel hinzufügen', 'RU': 'Добавить жизненную цель', 'AR': 'إضافة هدف الحياة', 'HI': 'जीवन लक्ष्य जोड़ें', 'VI': 'Thêm mục tiêu cuộc đời', 'ES': 'Añadir objetivo de vida', 'TH': 'เพิ่มเป้าหมายชีวิต'},
                    ),

                    _buildField(
                      icon: Icons.title_rounded, controller: titleController, hintEn: 'Goal', hintKo: 'e.g. 건강하게 은퇴하기',
                      translations: const {'JA': '目標 (例: 健康に引退する)', 'ZH': '目标 (例: 健康退休)', 'FR': 'Objectif (ex. Prendre une retraite en bonne santé)', 'DE': 'Ziel (z. B. gesund in Rente gehen)', 'RU': 'Цель (напр., выйти на пенсию здоровым)', 'AR': 'الهدف (مثال: التقاعد بصحة جيدة)', 'HI': 'लक्ष्य (जैसे: स्वस्थ रिटायरमेंट)', 'VI': 'Mục tiêu (VD: Nghỉ hưu khỏe mạnh)', 'ES': 'Objetivo (ej. Jubilarme con salud)', 'TH': 'เป้าหมาย (เช่น เกษียณอย่างมีสุขภาพดี)'},
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      icon: Icons.category_outlined, controller: categoryController, hintEn: 'Category', hintKo: '건강/재정/가족, 비워도 됨',
                      translations: const {'JA': 'カテゴリー (任意)', 'ZH': '分类 (可留空)', 'FR': 'Catégorie (facultatif)', 'DE': 'Kategorie (optional)', 'RU': 'Категория (необязательно)', 'AR': 'الفئة (اختياري)', 'HI': 'श्रेणी (वैकल्पिक)', 'VI': 'Danh mục (không bắt buộc)', 'ES': 'Categoría (opcional)', 'TH': 'หมวดหมู่ (ไม่บังคับ)'},
                    ),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          BiInline(
                            en: 'Achieved', ko: '달성함', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
                            translations: const {'JA': '達成済み', 'ZH': '已达成', 'FR': 'Atteint', 'DE': 'Erreicht', 'RU': 'Достигнуто', 'AR': 'تم تحقيقه', 'HI': 'हासिल किया', 'VI': 'Đã đạt được', 'ES': 'Logrado', 'TH': 'บรรลุแล้ว'},
                          ),
                          Switch(value: isAchieved, activeColor: _brandGolden, onChanged: (v) => setDialogState(() => isAchieved = v)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    luxuryBottomActions(
                      isEdit: isEdit,
                      onDelete: isEdit ? () => Navigator.of(context).pop('delete') : null,
                      onCancel: () => Navigator.of(context).pop(null),
                      onSave: () {
                        if (titleController.text.trim().isEmpty) return;
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
      await GoalDataService.deleteGoal(existing.id);
      await _loadGoals();
      return;
    }

    if (action == 'save' && titleController.text.trim().isNotEmpty) {
      if (isEdit) {
        final wasAchieved = existing!.isAchieved;
        final updated = GoalItem(
          id: existing.id,
          type: 'life',
          title: titleController.text.trim(),
          category: categoryController.text.trim().isEmpty ? '일반' : categoryController.text.trim(),
          isAchieved: isAchieved,
          createdAt: existing.createdAt,
        );
        if (isAchieved && !wasAchieved) {
          await GoalDataService.markGoalAchieved(updated);
        } else {
          await GoalDataService.updateGoal(updated);
        }
      } else {
        final newGoal = GoalItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: 'life',
          title: titleController.text.trim(),
          category: categoryController.text.trim().isEmpty ? '일반' : categoryController.text.trim(),
          isAchieved: isAchieved,
          createdAt: DateTime.now().toIso8601String(),
        );
        await GoalDataService.addGoal(newGoal);
        if (isAchieved) await GoalDataService.markGoalAchieved(newGoal);
      }
      await _loadGoals();
    }
  }

  Future<void> _showAddTodoDialog(GoalItem goal) async {
    final controller = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: LuxuryDialogFrame(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              luxuryDialogHeader(
                icon: Icons.playlist_add_rounded, en: 'ADD TASK', ko: '할 일 추가',
                translations: const {'JA': '作業を追加', 'ZH': '添加任务', 'FR': 'Ajouter une tâche', 'DE': 'Aufgabe hinzufügen', 'RU': 'Добавить задачу', 'AR': 'إضافة مهمة', 'HI': 'कार्य जोड़ें', 'VI': 'Thêm công việc', 'ES': 'Añadir tarea', 'TH': 'เพิ่มงาน'},
              ),
              _buildField(icon: Icons.check_box_outlined, controller: controller, hintEn: 'Task', hintKo: 'e.g. 매달 50만원 저축'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: BiInline(en: 'Cancel', ko: '취소', color: Colors.white70, fontWeight: FontWeight.bold, translations: commonButtonTranslations['Cancel']),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _brandGolden, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () {
                        if (controller.text.trim().isEmpty) return;
                        Navigator.of(context).pop(true);
                      },
                      child: BiInline(en: 'Add', ko: '추가', color: _pageBg, fontWeight: FontWeight.bold, translations: commonButtonTranslations['Add']),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      final now = DateTime.now();
      final todo = TodoItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        goalId: goal.id,
        title: controller.text.trim(),
        date: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      );
      await GoalDataService.addTodo(todo);
      await _loadGoals();
    }
  }

  Future<void> _showGoalTodos(GoalItem goal) async {
    List<TodoItem> todos = await GoalDataService.loadTodosForGoal(goal.id);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: _containerBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> refreshTodos() async {
            todos = await GoalDataService.loadTodosForGoal(goal.id);
            setSheetState(() {});
            await _loadGoals();
          }

          // 🆕 [버그 수정] 할 일 추가 후 수정/삭제가 아예 안 되던 문제 - 연필 눌러서
          // 수정/삭제할 수 있는 팝업을 새로 추가함.
          Future<void> showEditTodoDialog(TodoItem todo) async {
            final controller = TextEditingController(text: todo.title);
            final String? action = await showDialog<String>(
              context: sheetContext,
              barrierColor: Colors.black.withOpacity(0.65),
              builder: (editDialogContext) => Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                child: LuxuryDialogFrame(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      luxuryDialogHeader(
                        icon: Icons.edit_note_rounded, en: 'EDIT TASK', ko: '할 일 수정',
                        translations: const {'JA': '作業を編集', 'ZH': '编辑任务', 'FR': 'Modifier la tâche', 'DE': 'Aufgabe bearbeiten', 'RU': 'Изменить задачу', 'AR': 'تعديل المهمة', 'HI': 'कार्य संपादित करें', 'VI': 'Sửa công việc', 'ES': 'Editar tarea', 'TH': 'แก้ไขงาน'},
                      ),
                      _buildField(icon: Icons.check_box_outlined, controller: controller, hintEn: 'Task', hintKo: '할 일 내용'),
                      const SizedBox(height: 20),
                      luxuryBottomActions(
                        isEdit: true,
                        onDelete: () => Navigator.of(editDialogContext).pop('delete'),
                        onCancel: () => Navigator.of(editDialogContext).pop(null),
                        onSave: () {
                          if (controller.text.trim().isEmpty) return;
                          Navigator.of(editDialogContext).pop('save');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );

            if (action == 'delete') {
              await GoalDataService.deleteTodo(todo.id);
              await refreshTodos();
            } else if (action == 'save' && controller.text.trim().isNotEmpty) {
              final updated = TodoItem(id: todo.id, goalId: todo.goalId, title: controller.text.trim(), date: todo.date, isCompleted: todo.isCompleted, createdAt: todo.createdAt);
              await GoalDataService.updateTodo(updated);
              await refreshTodos();
            }
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BiInline(en: goal.title, ko: 'Tasks (할 일)', color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 15), // goal.title은 사용자가 직접 입력한 목표명이라 번역 대상 아님
                  const SizedBox(height: 12),
                  if (todos.isEmpty)
                    BiInline(
                      en: 'No tasks yet', ko: '연결된 할 일이 없습니다', color: Colors.white38, fontSize: 13,
                      translations: const {'JA': 'まだ作業がありません', 'ZH': '暂无关联任务', 'FR': "Aucune tâche liée pour l'instant", 'DE': 'Noch keine verknüpften Aufgaben', 'RU': 'Пока нет связанных задач', 'AR': 'لا توجد مهام مرتبطة بعد', 'HI': 'अभी तक कोई जुड़ा कार्य नहीं', 'VI': 'Chưa có công việc liên kết', 'ES': 'Aún no hay tareas vinculadas', 'TH': 'ยังไม่มีงานที่เชื่อมโยง'},
                    )
                  else
                    ...todos.map((t) => CheckboxListTile(
                      value: t.isCompleted,
                      onChanged: (val) async {
                        t.isCompleted = val ?? false;
                        await GoalDataService.updateTodo(t);
                        await refreshTodos();
                      },
                      title: Text(t.title, style: TextStyle(color: t.isCompleted ? Colors.white38 : Colors.white, decoration: t.isCompleted ? TextDecoration.lineThrough : null)),
                      activeColor: _brandGolden,
                      checkColor: _pageBg,
                      controlAffinity: ListTileControlAffinity.leading,
                      secondary: IconButton(
                        icon: const ThreeColorPencilIcon(size: 20),
                        onPressed: () => showEditTodoDialog(t),
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      ),
                    )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField({required IconData icon, required TextEditingController controller, required String hintEn, required String hintKo, Map<String, String>? translations}) {
    return Container(
      decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _brandGolden.withOpacity(0.85), size: 19),
          hintText: biHint(hintEn, hintKo, translations: translations),
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
        title: BiTitle(
          en: 'LIFE GOAL', ko: '인생 목표', enSize: 17, koSize: 13,
          translations: const {'JA': '人生の目標', 'ZH': '人生目标', 'FR': 'Objectif de vie', 'DE': 'Lebensziel', 'RU': 'Жизненная цель', 'AR': 'هدف الحياة', 'HI': 'जीवन लक्ष्य', 'VI': 'Mục tiêu cuộc đời', 'ES': 'Objetivo de vida', 'TH': 'เป้าหมายชีวิต'},
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : _goals.isEmpty
          ? Center(
        child: BiInline(
          en: 'No life goals yet. Tap + to add one.', ko: '등록된 인생 목표가 없습니다. + 버튼으로 추가해 보세요.', color: Colors.white38, fontSize: 13, textAlign: TextAlign.center,
          translations: const {
            'JA': 'まだ人生目標がありません。+ボタンで追加してください。',
            'ZH': '暂无人生目标。点击+号添加。',
            'FR': "Aucun objectif de vie pour l'instant. Appuyez sur + pour en ajouter un.",
            'DE': 'Noch keine Lebensziele. Tippen Sie auf +, um eines hinzuzufügen.',
            'RU': 'Пока нет жизненных целей. Нажмите +, чтобы добавить.',
            'AR': 'لا توجد أهداف حياة بعد. اضغط + للإضافة.',
            'HI': 'अभी तक कोई जीवन लक्ष्य नहीं है। + दबाकर जोड़ें।',
            'VI': 'Chưa có mục tiêu cuộc đời nào. Nhấn + để thêm.',
            'ES': 'Aún no hay objetivos de vida. Toca + para añadir uno.',
            'TH': 'ยังไม่มีเป้าหมายชีวิต แตะ + เพื่อเพิ่ม',
          },
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _goals.length,
        itemBuilder: (context, index) => _buildGoalCard(_goals[index]),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _brandGolden,
        onPressed: () => _showGoalDialog(),
        child: const Icon(Icons.add, color: _pageBg),
      ),
    );
  }

  Widget _buildGoalCard(GoalItem goal) {
    final double progress = _progressCache[goal.id] ?? 0.0;
    final int percent = (progress * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _brandGolden.withOpacity(goal.isAchieved ? 0.7 : 0.4), width: goal.isAchieved ? 1.6 : 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (goal.isAchieved) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.emoji_events, color: _brandGolden, size: 18)),
              Expanded(
                child: Text(goal.title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, decoration: goal.isAchieved ? TextDecoration.lineThrough : null)),
              ),
              IconButton(
                icon: const ThreeColorPencilIcon(size: 18),
                onPressed: () => _showGoalDialog(existing: goal),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ],
          ),
          Text('(${goal.category})', style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation<Color>(_brandGolden)),
          ),
          const SizedBox(height: 6),
          BiInline(
            en: '$percent% Complete', ko: '$percent% 진행', color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold,
            translations: {
              'JA': '$percent% 完了', 'ZH': '$percent% 完成', 'FR': '$percent % Terminé', 'DE': '$percent % Erledigt',
              'RU': '$percent% Выполнено', 'AR': '$percent% مكتمل', 'HI': '$percent% पूर्ण', 'VI': '$percent% Hoàn thành',
              'ES': '$percent% Completado', 'TH': '$percent% เสร็จสิ้น',
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: _brandGolden)),
                  onPressed: () => _showGoalTodos(goal),
                  icon: const Icon(Icons.checklist, color: _brandGolden, size: 16),
                  label: BiInline(
                    en: 'View Tasks', ko: '할 일 보기', color: _brandGolden, fontSize: 11, fontWeight: FontWeight.bold,
                    translations: const {'JA': '作業を見る', 'ZH': '查看任务', 'FR': 'Voir les tâches', 'DE': 'Aufgaben ansehen', 'RU': 'Просмотр задач', 'AR': 'عرض المهام', 'HI': 'कार्य देखें', 'VI': 'Xem công việc', 'ES': 'Ver tareas', 'TH': 'ดูงาน'},
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38)),
                  onPressed: () => _showAddTodoDialog(goal),
                  icon: const Icon(Icons.add, color: Colors.white70, size: 16),
                  label: BiInline(
                    en: 'Add Task', ko: '할 일 추가', color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold,
                    translations: const {'JA': '作業を追加', 'ZH': '添加任务', 'FR': 'Ajouter une tâche', 'DE': 'Aufgabe hinzufügen', 'RU': 'Добавить задачу', 'AR': 'إضافة مهمة', 'HI': 'कार्य जोड़ें', 'VI': 'Thêm công việc', 'ES': 'Añadir tarea', 'TH': 'เพิ่มงาน'},
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
