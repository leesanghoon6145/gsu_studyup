// ============================================================================
// 🆕 [일반 플래너 3단계] TodoScreen
// 특정 목표에 묶이지 않은, 자유로운 할 일 목록입니다 (goalId == null인 항목).
// 목표에 묶인 할 일은 각 목표 화면(인생/연간~오늘)에서 "할 일 보기"로 관리하고,
// 여기서는 목표와 상관없는 잡다한 할 일을 빠르게 적어두고 체크하는 용도입니다.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'goal_data_service.dart';

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
    todos.sort((a, b) => b.date.compareTo(a.date));
    if (!mounted) return;
    setState(() {
      _todos = todos;
      _isLoading = false;
    });
  }

  Future<void> _showAddDialog() async {
    final TextEditingController controller = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _containerBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('ADD TODO\n(할 일 추가)', textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 17)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '할 일을 입력하세요',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: _pageBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _brandGolden),
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.of(context).pop(true);
            },
            child: const Text('추가', style: TextStyle(color: _pageBg, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      final now = DateTime.now();
      final todo = TodoItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: controller.text.trim(),
        date: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      );
      await GoalDataService.addTodo(todo);
      await _loadTodos();
    }
  }

  Future<void> _toggle(TodoItem todo) async {
    todo.isCompleted = !todo.isCompleted;
    await GoalDataService.updateTodo(todo);
    await _loadTodos();
  }

  Future<void> _delete(TodoItem todo) async {
    await GoalDataService.deleteTodo(todo.id);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('TODO', style: GoogleFonts.gowunBatang(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 20)),
            Text('할 일', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('$done / $total 완료', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _todos.isEmpty
                ? Center(child: Text('할 일이 없습니다.', style: GoogleFonts.notoSansKr(color: Colors.white38)))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _todos.length,
              itemBuilder: (context, index) {
                final todo = _todos[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                  child: CheckboxListTile(
                    value: todo.isCompleted,
                    onChanged: (_) => _toggle(todo),
                    activeColor: _brandGolden,
                    checkColor: _pageBg,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(todo.title,
                        style: TextStyle(color: todo.isCompleted ? Colors.white38 : Colors.white, decoration: todo.isCompleted ? TextDecoration.lineThrough : null)),
                    subtitle: Text(todo.date, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    secondary: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 18),
                      onPressed: () => _delete(todo),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _brandGolden,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: _pageBg),
      ),
    );
  }
}
