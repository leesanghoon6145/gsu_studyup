// ============================================================================
// 🆕 [일반 플래너 - 고급 팝업 + 병기 적용] TodoScreen
// 특정 목표에 묶이지 않은, 자유로운 할 일 목록입니다 (goalId == null인 항목).
// 목표에 묶인 할 일은 각 목표 화면에서 "할 일 보기"로 관리하고, 여기서는
// 목표와 상관없는 잡다한 할 일을 빠르게 적어두고 체크하는 용도입니다.
// 🆕 다른 화면과 동일한 진한 골드 팝업 + 가로3선 연필 + 하단 삭제/취소/저장.
// ============================================================================

import 'package:flutter/material.dart';
import 'goal_data_service.dart';
import 'bilingual_text.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  List<TodoItem> _todos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    setState(() => _isLoading = true);
    final todos = await GoalDataService.loadStandaloneTodos();
    todos.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 🆕 [정렬 수정] 날짜만이 아니라 정확한 시각까지 비교해서 최근 입력이 맨 위로
    if (!mounted) return;
    setState(() {
      _todos = todos;
      _isLoading = false;
    });
  }

  Future<void> _showTodoDialog({TodoItem? existing}) async {
    final bool isEdit = existing != null;
    final controller = TextEditingController(text: existing?.title ?? '');

    final String? action = await showDialog<String>(
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
              luxuryDialogHeader(icon: isEdit ? Icons.edit_note_rounded : Icons.playlist_add_rounded, en: isEdit ? 'EDIT TODO' : 'ADD TODO', ko: isEdit ? '할 일 수정' : '할 일 추가'),
              Container(
                decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.check_box_outlined, color: _brandGolden.withOpacity(0.85), size: 19),
                    hintText: biHint('Task', '할 일을 입력하세요'),
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              luxuryBottomActions(
                isEdit: isEdit,
                onDelete: isEdit ? () => Navigator.of(context).pop('delete') : null,
                onCancel: () => Navigator.of(context).pop(null),
                onSave: () {
                  if (controller.text.trim().isEmpty) return;
                  Navigator.of(context).pop('save');
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (action == 'delete' && existing != null) {
      await GoalDataService.deleteTodo(existing.id);
      await _loadTodos();
      return;
    }

    if (action == 'save' && controller.text.trim().isNotEmpty) {
      if (isEdit) {
        final updated = TodoItem(id: existing!.id, goalId: existing.goalId, title: controller.text.trim(), date: existing.date, isCompleted: existing.isCompleted);
        await GoalDataService.updateTodo(updated);
      } else {
        final now = DateTime.now();
        final newTodo = TodoItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: controller.text.trim(),
          date: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        );
        await GoalDataService.addTodo(newTodo);
      }
      await _loadTodos();
    }
  }

  Future<void> _toggle(TodoItem todo) async {
    todo.isCompleted = !todo.isCompleted;
    await GoalDataService.updateTodo(todo);
    await _loadTodos();
  }

  @override
  Widget build(BuildContext context) {
    final int total = _todos.length;
    final int done = _todos.where((t) => t.isCompleted).length;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: const BiTitle(en: 'TODO', ko: '할 일', enSize: 19, koSize: 14),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: BiInline(en: '$done / $total Completed', ko: '$done / $total 완료', color: _brandGolden, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: _todos.isEmpty
                ? Center(child: BiInline(en: 'No tasks yet', ko: '할 일이 없습니다', color: Colors.white38))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _todos.length,
              itemBuilder: (context, index) {
                final todo = _todos[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _brandGolden.withOpacity(0.35))),
                  child: Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          value: todo.isCompleted,
                          onChanged: (_) => _toggle(todo),
                          activeColor: _brandGolden,
                          checkColor: _pageBg,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(todo.title, style: TextStyle(color: todo.isCompleted ? Colors.white38 : Colors.white, decoration: todo.isCompleted ? TextDecoration.lineThrough : null)),
                          subtitle: Text(todo.date, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        ),
                      ),
                      IconButton(
                        icon: const ThreeColorPencilIcon(size: 18),
                        onPressed: () => _showTodoDialog(existing: todo),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _brandGolden,
        onPressed: () => _showTodoDialog(),
        child: const Icon(Icons.add, color: _pageBg),
      ),
    );
  }
}
