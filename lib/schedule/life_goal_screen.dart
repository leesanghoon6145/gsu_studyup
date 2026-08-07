// ============================================================================
// 🆕 [일반 플래너 3단계] LifeGoalScreen
// 장기적인 인생 목표(예: "50세까지 내 집 마련", "건강하게 은퇴하기")를
// 관리하는 화면입니다. 기간별 목표(연간~오늘)와 구조는 동일하지만, 기간
// 개념이 없다는 점만 다르므로 독립된 화면으로 만들었습니다.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'goal_data_service.dart';

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

  Future<void> _showAddGoalDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController categoryController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _containerBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'ADD LIFE GOAL\n(인생 목표 추가)',
          textAlign: TextAlign.center,
          style: GoogleFonts.gowunBatang(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '목표 (예: 건강하게 은퇴하기)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: _pageBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: categoryController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '분야 (예: 건강/재정/가족, 비워도 됨)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: _pageBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(12),
              ),
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
            child: const Text('저장', style: TextStyle(color: _pageBg, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && titleController.text.trim().isNotEmpty) {
      final newGoal = GoalItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: 'life',
        title: titleController.text.trim(),
        category: categoryController.text.trim().isEmpty ? '일반' : categoryController.text.trim(),
        createdAt: DateTime.now().toIso8601String(),
      );
      await GoalDataService.addGoal(newGoal);
      await _loadGoals();
    }
  }

  Future<void> _showAddTodoDialog(GoalItem goal) async {
    final TextEditingController controller = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _containerBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('할 일 추가', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '예: 매달 50만원 저축',
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
                Text(goal.title, style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                if (todos.isEmpty)
                  Text('연결된 할 일이 없습니다.', style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 13))
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

  Future<void> _achieveGoal(GoalItem goal) async {
    await GoalDataService.markGoalAchieved(goal);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${goal.title}" 목표를 달성했습니다! 🎉', style: GoogleFonts.notoSansKr())),
    );
    await _loadGoals();
  }

  Future<void> _deleteGoal(GoalItem goal) async {
    await GoalDataService.deleteGoal(goal.id);
    await _loadGoals();
  }

  @override
  Widget build(BuildContext context) {
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
            Text('LIFE GOAL', style: GoogleFonts.gowunBatang(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('인생 목표', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : _goals.isEmpty
          ? Center(
        child: Text('등록된 인생 목표가 없습니다.\n+ 버튼으로 추가해 보세요.',
            textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 14)),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _goals.length,
        itemBuilder: (context, index) => _buildGoalCard(_goals[index]),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _brandGolden,
        onPressed: _showAddGoalDialog,
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
      decoration: BoxDecoration(
        color: _containerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: goal.isAchieved ? _brandGolden : Colors.white12, width: goal.isAchieved ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (goal.isAchieved) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.emoji_events, color: _brandGolden, size: 18)),
              Expanded(
                child: Text(goal.title,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, decoration: goal.isAchieved ? TextDecoration.lineThrough : null)),
              ),
              PopupMenuButton<String>(
                color: _containerBg,
                icon: const Icon(Icons.more_vert, color: Colors.white38, size: 20),
                onSelected: (value) {
                  if (value == 'delete') _deleteGoal(goal);
                  if (value == 'achieve') _achieveGoal(goal);
                },
                itemBuilder: (context) => [
                  if (!goal.isAchieved) PopupMenuItem(value: 'achieve', child: Text('성취 완료', style: GoogleFonts.notoSansKr(color: _brandGolden))),
                  PopupMenuItem(value: 'delete', child: Text('삭제', style: GoogleFonts.notoSansKr(color: Colors.redAccent))),
                ],
              ),
            ],
          ),
          Text('(${goal.category})', style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(_brandGolden),
            ),
          ),
          const SizedBox(height: 6),
          Text('$percent% 진행', style: GoogleFonts.notoSansKr(color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: _brandGolden)),
                  onPressed: () => _showGoalTodos(goal),
                  icon: const Icon(Icons.checklist, color: _brandGolden, size: 16),
                  label: Text('할 일 보기', style: GoogleFonts.notoSansKr(color: _brandGolden, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38)),
                  onPressed: () => _showAddTodoDialog(goal),
                  icon: const Icon(Icons.add, color: Colors.white70, size: 16),
                  label: Text('할 일 추가', style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
