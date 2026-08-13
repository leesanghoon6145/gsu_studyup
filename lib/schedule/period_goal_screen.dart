// ============================================================================
// 🆕 [일반 플래너 - 전체 연동 재설계] PeriodGoalScreen (공용 구현)
// 연간/월간/주간/오늘 목표는 화면 구조가 동일하므로, 이 파일 하나에 실제
// 구현을 두고 yearly/monthly/weekly/today_goal_screen.dart는 이 위젯을
// 얇게 감싸서 사용합니다.
//
// 🆕 [핵심 변경] 더 이상 목표마다 따로 할 일을 만들어서 체크하지 않습니다.
// 목표를 만들면 그 목표의 기간(오늘/이번주/이번달/올해)이 자동으로 정해지고,
// 그 기간에 캘린더+타임라인에서 실제로 완료한 것을 기준으로 진행률이
// 자동 계산됩니다 (ReportDataService.summarize 재사용 - 리포트 화면과
// 완전히 같은 계산 로직/같은 데이터). "달성함" 스위치는 여전히 수동으로
// 켜고 끌 수 있습니다.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'goal_data_service.dart';
import 'report_data_service.dart';
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
  Map<String, ReportSummary> _summaryCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    final goals = await GoalDataService.loadGoalsByType(widget.goalType);
    final Map<String, ReportSummary> summaryMap = {};
    for (final g in goals) {
      final start = DateTime.tryParse(g.periodStart) ?? DateTime.now();
      final end = DateTime.tryParse(g.periodEnd) ?? DateTime.now();
      summaryMap[g.id] = await ReportDataService.summarize(start, end);
    }
    if (!mounted) return;
    setState(() {
      _goals = goals;
      _summaryCache = summaryMap;
      _isLoading = false;
    });
  }

  // 🆕 [핵심] 목표 유형에 따라 "지금" 기준 기간의 시작/끝 날짜를 계산.
  // 이 범위가 캘린더+타임라인 완료율을 조회하는 데 그대로 쓰입니다.
  (DateTime, DateTime) _currentPeriodRange() => _periodRangeWithOffset(0);

  // 🆕 [버그 수정] offset을 받아서 다음달/이전달, 다음주/이전주, 내년/작년 등
  // "지금"이 아닌 다른 기간도 계산할 수 있게 함. offset=0이면 지금과 동일.
  (DateTime, DateTime) _periodRangeWithOffset(int offset) {
    final now = DateTime.now();
    final todayZero = DateTime(now.year, now.month, now.day);
    switch (widget.goalType) {
      case 'today':
        final d = todayZero.add(Duration(days: offset));
        return (d, d);
      case 'weekly':
        final thisWeekStart = todayZero.subtract(Duration(days: now.weekday - 1));
        final start = thisWeekStart.add(Duration(days: 7 * offset));
        final end = start.add(const Duration(days: 6));
        return (start, end);
      case 'monthly':
        final targetMonth = now.month + offset;
        return (DateTime(now.year, targetMonth, 1), DateTime(now.year, targetMonth + 1, 0));
      case 'yearly':
        return (DateTime(now.year + offset, 1, 1), DateTime(now.year + offset, 12, 31));
      default:
        return (todayZero, todayZero);
    }
  }

  String _periodLabel(DateTime start, DateTime end) {
    String fmt(DateTime d) => '${d.month}/${d.day}';
    if (start == end || (start.year == end.year && start.month == end.month && start.day == end.day)) {
      return fmt(start);
    }
    return '${fmt(start)} ~ ${fmt(end)}';
  }

  Future<void> _showGoalDialog({GoalItem? existing}) async {
    final bool isEdit = existing != null;
    final titleController = TextEditingController(text: existing?.title ?? '');
    final categoryController = TextEditingController(text: existing?.category ?? '');
    bool isAchieved = existing?.isAchieved ?? false;
    int periodOffset = 0; // 🆕 [기간 선택] 0=지금, +1=다음 기간, -1=이전 기간 ...

    final (currentStart, currentEnd) = _currentPeriodRange();
    final String editPeriodLabel = isEdit ? _periodLabel(DateTime.tryParse(existing!.periodStart) ?? currentStart, DateTime.tryParse(existing.periodEnd) ?? currentEnd) : '';

    final String? action = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final (selStart, selEnd) = _periodRangeWithOffset(periodOffset);
          final String periodLabel = isEdit ? editPeriodLabel : _periodLabel(selStart, selEnd);

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

                    // 🆕 [버그 수정] 새 목표를 만들 때는 다른 달/주/연도로 이동해서 만들 수 있음
                    // (예: 지금 8월인데 9월 목표를 미리 만들기). 수정할 때는 이미 정해진
                    // 기간이라 이동 불가능(고정 표시만).
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(color: _brandGolden.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: _brandGolden.withOpacity(0.3))),
                      child: Row(
                        children: [
                          if (!isEdit)
                            IconButton(
                              icon: const Icon(Icons.chevron_left, color: _brandGolden),
                              onPressed: () => setDialogState(() => periodOffset -= 1),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          const SizedBox(width: 4),
                          const Icon(Icons.date_range, color: _brandGolden, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: BiInline(en: 'Period: $periodLabel', ko: '기간: $periodLabel', color: _brandGolden, fontSize: 11, fontWeight: FontWeight.bold, textAlign: TextAlign.center),
                          ),
                          if (!isEdit)
                            IconButton(
                              icon: const Icon(Icons.chevron_right, color: _brandGolden),
                              onPressed: () => setDialogState(() => periodOffset += 1),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                        ],
                      ),
                    ),

                    _buildField(icon: Icons.title_rounded, controller: titleController, hintEn: 'Goal', hintKo: 'e.g. 일정 90% 달성하기'),
                    const SizedBox(height: 12),
                    _buildField(icon: Icons.category_outlined, controller: categoryController, hintEn: 'Category', hintKo: '건강/자기계발/재정, 비워도 됨'),
                    const SizedBox(height: 14),

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
          periodStart: existing.periodStart, // 🆕 기간은 수정 시 바뀌지 않음(생성 시 고정)
          periodEnd: existing.periodEnd,
          isAchieved: isAchieved,
          createdAt: existing.createdAt,
        );
        if (isAchieved && !wasAchieved) {
          await GoalDataService.markGoalAchieved(updated);
        } else {
          await GoalDataService.updateGoal(updated);
        }
      } else {
        final (start, end) = _periodRangeWithOffset(periodOffset); // 🆕 [버그 수정] 선택한 기간(미래/과거 포함) 사용
        final dateStr = (DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        final newGoal = GoalItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: widget.goalType,
          title: titleController.text.trim(),
          category: categoryController.text.trim().isEmpty ? '일반' : categoryController.text.trim(),
          periodStart: dateStr(start),
          periodEnd: dateStr(end),
          isAchieved: isAchieved,
          createdAt: DateTime.now().toIso8601String(),
        );
        await GoalDataService.addGoal(newGoal);
        if (isAchieved) await GoalDataService.markGoalAchieved(newGoal);
      }
      await _loadGoals();
    }
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
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BiInline(
            en: 'No goals yet. Tap + to add one.\nProgress is automatically calculated from\nyour calendar & timeline records.',
            ko: '등록된 목표가 없습니다. + 버튼으로 추가해 보세요.\n진행률은 캘린더/타임라인 기록을 기준으로\n자동으로 계산됩니다.',
            color: Colors.white38,
            fontSize: 13,
            textAlign: TextAlign.center,
          ),
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
    final summary = _summaryCache[goal.id];
    final double progress = summary?.completionRate ?? 0.0;
    final int percent = summary?.completionPercent ?? 0;
    final start = DateTime.tryParse(goal.periodStart);
    final end = DateTime.tryParse(goal.periodEnd);
    final String periodLabel = (start != null && end != null) ? _periodLabel(start, end) : '';

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
          Row(
            children: [
              Text('(${goal.category})', style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 11)),
              if (periodLabel.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('· $periodLabel', style: const TextStyle(color: Colors.white24, fontSize: 11)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation<Color>(_brandGolden)),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BiInline(en: '$percent% Complete', ko: '$percent% 진행', color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold),
              if (summary != null)
                Text('${summary.completedCount} / ${summary.totalCount}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          // 🆕 [연동 안내] 데이터가 캘린더/타임라인에서 자동으로 온다는 것을 알려주는 작은 힌트
          if (summary != null && !summary.hasData)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: BiInline(
                en: 'No calendar/timeline records for this period yet.',
                ko: '이 기간에 캘린더/타임라인 기록이 아직 없습니다.',
                color: Colors.white24,
                fontSize: 10.5,
              ),
            ),
        ],
      ),
    );
  }
}
