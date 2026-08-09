// ============================================================================
// 🆕 [일반 플래너 - 고급 팝업 + 병기 적용] PeriodGoalScreen (공용 구현)
// 연간/월간/주간/오늘 목표는 화면 구조가 동일하므로, 이 파일 하나에 실제
// 구현을 두고 yearly/monthly/weekly/today_goal_screen.dart는 이 위젯을
// 얇게 감싸서 사용합니다 (goalType만 다르게 넘김).
//
// 🆕 [설계 변경] 기존에 팝업메뉴(⋮)로 따로 있던 "성취 완료"를 수정 팝업 안의
// "달성함" 스위치로 통합했습니다. 이렇게 하면 하단 삭제/취소/저장 3버튼
// 패턴을 그대로 유지할 수 있어 다른 화면들과 일관성이 생깁니다.
// 목표 카드의 가로 3선(빨/노/파) 연필 아이콘을 누르면 수정 팝업이 열립니다.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'goal_data_service.dart';
import 'bilingual_text.dart';

class PeriodGoalScreen extends StatefulWidget {
  final String goalType; // 'yearly' | 'monthly' | 'weekly' | 'today'
  final String enTitle;
  final String koTitle;

  const PeriodGoalScreen({super.key, required this.goalType, required this.enTitle, required this.koTitle});

  @override
  State<PeriodGoalScreen> createState() => _PeriodGoalScreenState();
}

class _PeriodGoalScreenState extends State<PeriodGoalScreen> {
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
    final goals = await GoalDataService.loadGoalsByType(widget.goalType);
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

  String get _currentPeriodKey {
    final now = DateTime.now();
    switch (widget.goalType) {
      case 'yearly':
        return '${now.year}';
      case 'monthly':
        return '${now.year}-${now.month.toString().padLeft(2, '0')}';
      case 'weekly':
        return '${now.year}-W${((now.day + now.weekday) / 7).ceil()}';
      case 'today':
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      default:
        return '';
    }
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
                    luxuryDialogHeader(icon: isEdit ? Icons.edit_note_rounded : Icons.flag_rounded, en: isEdit ? 'EDIT GOAL' : 'ADD GOAL', ko: isEdit ? '목표 수정' : '목표 추가'),

                    _buildField(icon: Icons.title_rounded, controller: titleController, hintEn: 'Goal', hintKo: 'e.g. 매일 30분 독서'),
                    const SizedBox(height: 12),
                    _buildField(icon: Icons.category_outlined, controller: categoryController, hintEn: 'Category', hintKo: '건강/자기계발/재정, 비워도 됨'),
                    const SizedBox(height: 14),

                    // 🆕 [설계 변경] 달성 여부를 스위치로 통합
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const BiInline(en: 'Achieved', ko: '달성함', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
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
          type: existing.type,
          title: titleController.text.trim(),
          category: categoryController.text.trim().isEmpty ? '일반' : categoryController.text.trim(),
          periodKey: existing.periodKey,
          isAchieved: isAchieved,
          createdAt: existing.createdAt,
        );
        if (isAchieved && !wasAchieved) {
          await GoalDataService.markGoalAchieved(updated); // 새로 달성 처리된 경우 성취 기록도 생성
        } else {
          await GoalDataService.updateGoal(updated);
        }
      } else {
        final newGoal = GoalItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: widget.goalType,
          title: titleController.text.trim(),
          category: categoryController.text.trim().isEmpty ? '일반' : categoryController.text.trim(),
          periodKey: _currentPeriodKey,
          isAchieved: isAchieved,
          createdAt: DateTime.now().toIso8601String(),
        );
        if (isAchieved) {
          await GoalDataService.addGoal(newGoal);
          await GoalDataService.markGoalAchieved(newGoal);
        } else {
          await GoalDataService.addGoal(newGoal);
        }
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
              luxuryDialogHeader(icon: Icons.playlist_add_rounded, en: 'ADD TASK', ko: '할 일 추가'),
              _buildField(icon: Icons.check_box_outlined, controller: controller, hintEn: 'Task', hintKo: 'e.g. 책 1챕터 읽기'),
              const SizedBox(height: 20),
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
                      style: ElevatedButton.styleFrom(backgroundColor: _brandGolden, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () {
                        if (controller.text.trim().isEmpty) return;
                        Navigator.of(context).pop(true);
                      },
                      child: const BiInline(en: 'Add', ko: '추가', color: _pageBg, fontWeight: FontWeight.bold),
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
    final todos = await GoalDataService.loadTodosForGoal(goal.id);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: _containerBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BiInline(en: goal.title, ko: 'Tasks (할 일)', color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 15),
                const SizedBox(height: 12),
                if (todos.isEmpty)
                  const BiInline(en: 'No tasks yet', ko: '연결된 할 일이 없습니다', color: Colors.white38, fontSize: 13)
                else
                  ...todos.map((t) => CheckboxListTile(
                    value: t.isCompleted,
                    onChanged: (val) async {
                      t.isCompleted = val ?? false;
                      await GoalDataService.updateTodo(t);
                      setSheetState(() {});
                      await _loadGoals();
                    },
                    title: Text(t.title, style: TextStyle(color: t.isCompleted ? Colors.white38 : Colors.white, decoration: t.isCompleted ? TextDecoration.lineThrough : null)),
                    activeColor: _brandGolden,
                    checkColor: _pageBg,
                    controlAffinity: ListTileControlAffinity.leading,
                  )),
              ],
            ),
          );
        },
      ),
    );
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
        title: BiTitle(en: widget.enTitle, ko: widget.koTitle, enSize: 17, koSize: 13),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : _goals.isEmpty
          ? Center(child: BiInline(en: 'No goals yet. Tap + to add one.', ko: '등록된 목표가 없습니다. + 버튼으로 추가해 보세요.', color: Colors.white38, fontSize: 13, textAlign: TextAlign.center))
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
                icon: const HorizontalPencilIcon(size: 18),
                onPressed: () => _showGoalDialog(existing: goal),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
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
          BiInline(en: '$percent% Complete', ko: '$percent% 진행', color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: _brandGolden)),
                  onPressed: () => _showGoalTodos(goal),
                  icon: const Icon(Icons.checklist, color: _brandGolden, size: 16),
                  label: const BiInline(en: 'View Tasks', ko: '할 일 보기', color: _brandGolden, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38)),
                  onPressed: () => _showAddTodoDialog(goal),
                  icon: const Icon(Icons.add, color: Colors.white70, size: 16),
                  label: const BiInline(en: 'Add Task', ko: '할 일 추가', color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
