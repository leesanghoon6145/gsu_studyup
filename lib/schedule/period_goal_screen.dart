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
//
// ✅ [2026-09-04 추가] 운동(EXERCISE) 목표 연동. 목표 추가 시 "운동 목표로
// 만들기"를 켜면 캘린더/타임라인 완료율 대신 실제 ExerciseRecord 개수를
// 목표 세션 수와 비교해서 진행률을 계산한다 (예: "이번 주 3회 운동" ->
// 이번 주 실제 운동 기록이 3건이면 100%).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'goal_data_service.dart';
import 'report_data_service.dart';
import 'bilingual_text.dart';
import 'exercise_data_service.dart'; // 🆕 [운동 목표]

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
  Map<String, int> _exerciseSessionCountCache = {}; // 🆕 [운동 목표] 목표별 실제 운동 세션 수

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  // 🆕 [운동 목표] 주어진 기간 안의 실제 운동 기록 개수를 센다.
  Future<int> _countExerciseSessions(DateTime start, DateTime end) async {
    final all = await ExerciseDataService.instance.getAllRecords();
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return all.where((r) {
      final day = DateTime(r.date.year, r.date.month, r.date.day);
      return !day.isBefore(s) && !day.isAfter(e);
    }).length;
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    final goals = await GoalDataService.loadGoalsByType(widget.goalType);
    final Map<String, ReportSummary> summaryMap = {};
    final Map<String, int> exerciseCountMap = {}; // 🆕 [운동 목표]
    for (final g in goals) {
      final start = DateTime.tryParse(g.periodStart) ?? DateTime.now();
      final end = DateTime.tryParse(g.periodEnd) ?? DateTime.now();
      if (g.exerciseTargetSessions != null) {
        // 🆕 [운동 목표] 완료율 대신 실제 운동 세션 수를 센다.
        exerciseCountMap[g.id] = await _countExerciseSessions(start, end);
      } else {
        summaryMap[g.id] = await ReportDataService.summarize(start, end);
      }
    }
    if (!mounted) return;
    setState(() {
      _goals = goals;
      _summaryCache = summaryMap;
      _exerciseSessionCountCache = exerciseCountMap; // 🆕 [운동 목표]
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

    // 🆕 [운동 목표] 이 목표를 "운동 목표"로 만들지 여부 + 목표 세션 수
    bool isExerciseGoal = existing?.exerciseTargetSessions != null;
    final exerciseTargetController = TextEditingController(text: (existing?.exerciseTargetSessions ?? 3).toString());

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
                    luxuryDialogHeader(
                      icon: isEdit ? Icons.edit_note_rounded : Icons.flag_rounded,
                      en: isEdit ? 'EDIT GOAL' : 'ADD GOAL', ko: isEdit ? '목표 수정' : '목표 추가',
                      translations: isEdit
                          ? {'JA': '目標を編集', 'ZH': '编辑目标', 'FR': "Modifier l'objectif", 'DE': 'Ziel bearbeiten', 'RU': 'Изменить цель', 'AR': 'تعديل الهدف', 'HI': 'लक्ष्य संपादित करें', 'VI': 'Sửa mục tiêu', 'ES': 'Editar objetivo', 'TH': 'แก้ไขเป้าหมาย'}
                          : {'JA': '目標を追加', 'ZH': '添加目标', 'FR': 'Ajouter un objectif', 'DE': 'Ziel hinzufügen', 'RU': 'Добавить цель', 'AR': 'إضافة هدف', 'HI': 'लक्ष्य जोड़ें', 'VI': 'Thêm mục tiêu', 'ES': 'Añadir objetivo', 'TH': 'เพิ่มเป้าหมาย'},
                    ),

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
                            child: BiInline(
                              en: 'Period: $periodLabel', ko: '기간: $periodLabel', color: _brandGolden, fontSize: 11, fontWeight: FontWeight.bold, textAlign: TextAlign.center,
                              translations: {
                                'JA': '期間: $periodLabel', 'ZH': '期间: $periodLabel', 'FR': 'Période : $periodLabel', 'DE': 'Zeitraum: $periodLabel',
                                'RU': 'Период: $periodLabel', 'AR': 'الفترة: $periodLabel', 'HI': 'अवधि: $periodLabel', 'VI': 'Giai đoạn: $periodLabel',
                                'ES': 'Período: $periodLabel', 'TH': 'ช่วงเวลา: $periodLabel',
                              },
                            ),
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

                    _buildField(
                      icon: Icons.title_rounded, controller: titleController, hintEn: 'Goal', hintKo: 'e.g. 일정 90% 달성하기',
                      translations: const {'JA': '目標 (例: 予定90%達成)', 'ZH': '目标 (例: 完成90%日程)', 'FR': 'Objectif (ex. Atteindre 90% du programme)', 'DE': 'Ziel (z. B. 90% des Zeitplans erreichen)', 'RU': 'Цель (напр., выполнить 90% расписания)', 'AR': 'الهدف (مثال: تحقيق 90٪ من الجدول)', 'HI': 'लक्ष्य (जैसे: 90% शेड्यूल पूरा करना)', 'VI': 'Mục tiêu (VD: Hoàn thành 90% lịch trình)', 'ES': 'Objetivo (ej. Lograr 90% del horario)', 'TH': 'เป้าหมาย (เช่น ทำตารางเวลาสำเร็จ 90%)'},
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      icon: Icons.category_outlined, controller: categoryController, hintEn: 'Category', hintKo: '건강/자기계발/재정, 비워도 됨',
                      translations: const {'JA': 'カテゴリー (任意)', 'ZH': '分类 (可留空)', 'FR': 'Catégorie (facultatif)', 'DE': 'Kategorie (optional)', 'RU': 'Категория (необязательно)', 'AR': 'الفئة (اختياري)', 'HI': 'श्रेणी (वैकल्पिक)', 'VI': 'Danh mục (không bắt buộc)', 'ES': 'Categoría (opcional)', 'TH': 'หมวดหมู่ (ไม่บังคับ)'},
                    ),
                    const SizedBox(height: 14),

                    // 🆕 [운동 목표] 이 목표를 운동 세션 수 기준으로 만들지 선택하는 토글.
                    // 켜면 아래 완료율 대신 실제 ExerciseRecord 개수로 진행률을 계산한다.
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.fitness_center_rounded, color: _brandGolden, size: 16),
                                  const SizedBox(width: 8),
                                  BiInline(
                                    en: 'Exercise Goal', ko: '운동 목표로 만들기', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12.5,
                                    translations: const {'JA': '運動目標にする', 'ZH': '设为运动目标', 'FR': "Objectif d'exercice", 'DE': 'Als Trainingsziel festlegen', 'RU': 'Сделать целью по тренировкам', 'AR': 'اجعله هدف تمرين', 'HI': 'व्यायाम लक्ष्य बनाएं', 'VI': 'Đặt làm mục tiêu tập luyện', 'ES': 'Convertir en objetivo de ejercicio', 'TH': 'ตั้งเป็นเป้าหมายออกกำลังกาย'},
                                  ),
                                ],
                              ),
                              Switch(value: isExerciseGoal, activeColor: _brandGolden, onChanged: (v) => setDialogState(() => isExerciseGoal = v)),
                            ],
                          ),
                          if (isExerciseGoal) ...[
                            const Divider(color: Colors.white12, height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: BiInline(
                                    en: 'Target sessions for this period', ko: '이 기간 목표 운동 횟수', color: Colors.white54, fontSize: 11.5,
                                    translations: const {'JA': 'この期間の目標運動回数', 'ZH': '本期间目标运动次数', 'FR': "Séances cibles pour cette période", 'DE': 'Zielanzahl für diesen Zeitraum', 'RU': 'Целевое число тренировок за период', 'AR': 'عدد الجلسات المستهدفة لهذه الفترة', 'HI': 'इस अवधि के लिए लक्ष्य सत्र', 'VI': 'Số buổi mục tiêu cho giai đoạn này', 'ES': 'Sesiones objetivo para este período', 'TH': 'จำนวนครั้งเป้าหมายสำหรับช่วงนี้'},
                                  ),
                                ),
                                SizedBox(
                                  width: 64,
                                  child: TextField(
                                    controller: exerciseTargetController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 16),
                                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                                  ),
                                ),
                                BiInline(en: 'times', ko: '회', color: Colors.white54, fontSize: 11.5),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

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
      // 🆕 [운동 목표] 토글이 켜져 있으면 목표 세션 수를 정수로 파싱 (최소 1)
      final int? exerciseTarget = isExerciseGoal ? (int.tryParse(exerciseTargetController.text.trim()) ?? 1).clamp(1, 9999).toInt() : null;

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
          exerciseTargetSessions: exerciseTarget, // 🆕 [운동 목표]
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
          exerciseTargetSessions: exerciseTarget, // 🆕 [운동 목표]
        );
        await GoalDataService.addGoal(newGoal);
        if (isAchieved) await GoalDataService.markGoalAchieved(newGoal);
      }
      await _loadGoals();
    }
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
          en: widget.enTitle, ko: widget.koTitle, enSize: 17, koSize: 13,
          translations: const {
            'yearly': {'JA': '年間目標', 'ZH': '年度目标', 'FR': 'Objectif annuel', 'DE': 'Jahresziel', 'RU': 'Годовая цель', 'AR': 'الهدف السنوي', 'HI': 'वार्षिक लक्ष्य', 'VI': 'Mục tiêu năm', 'ES': 'Objetivo anual', 'TH': 'เป้าหมายรายปี'},
            'monthly': {'JA': '月間目標', 'ZH': '月度目标', 'FR': 'Objectif mensuel', 'DE': 'Monatsziel', 'RU': 'Месячная цель', 'AR': 'الهدف الشهري', 'HI': 'मासिक लक्ष्य', 'VI': 'Mục tiêu tháng', 'ES': 'Objetivo mensual', 'TH': 'เป้าหมายรายเดือน'},
            'weekly': {'JA': '週間目標', 'ZH': '每周目标', 'FR': 'Objectif hebdomadaire', 'DE': 'Wochenziel', 'RU': 'Недельная цель', 'AR': 'الهدف الأسبوعي', 'HI': 'साप्ताहिक लक्ष्य', 'VI': 'Mục tiêu tuần', 'ES': 'Objetivo semanal', 'TH': 'เป้าหมายรายสัปดาห์'},
            'today': {'JA': '今日の目標', 'ZH': '今日目标', 'FR': "Objectif du jour", 'DE': 'Tagesziel', 'RU': 'Цель на сегодня', 'AR': 'هدف اليوم', 'HI': 'आज का लक्ष्य', 'VI': 'Mục tiêu hôm nay', 'ES': 'Objetivo de hoy', 'TH': 'เป้าหมายวันนี้'},
          }[widget.goalType],
        ),
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
            translations: const {
              'JA': 'まだ目標がありません。+ボタンで追加してください。\n進捗はカレンダー/タイムライン記録を基に\n自動で計算されます。',
              'ZH': '暂无目标。点击+号添加。\n进度将根据日历/时间线记录\n自动计算。',
              'FR': "Aucun objectif pour l'instant. Appuyez sur + pour en ajouter un.\nLa progression est calculée automatiquement à partir de\nvos enregistrements de calendrier et de chronologie.",
              'DE': 'Noch keine Ziele. Tippen Sie auf +, um eines hinzuzufügen.\nDer Fortschritt wird automatisch aus Ihren\nKalender- und Zeitleistendaten berechnet.',
              'RU': 'Пока нет целей. Нажмите +, чтобы добавить.\nПрогресс рассчитывается автоматически на основе\nваших записей календаря и хронологии.',
              'AR': 'لا توجد أهداف بعد. اضغط + للإضافة.\nيتم حساب التقدم تلقائيًا استنادًا إلى\nسجلات التقويم والجدول الزمني الخاصة بك.',
              'HI': 'अभी तक कोई लक्ष्य नहीं है। + दबाकर जोड़ें।\nप्रगति आपके कैलेंडर और समयरेखा रिकॉर्ड के आधार पर\nस्वचालित रूप से गणना की जाती है।',
              'VI': 'Chưa có mục tiêu nào. Nhấn + để thêm.\nTiến độ được tính tự động dựa trên\nlịch và dữ liệu dòng thời gian của bạn.',
              'ES': 'Aún no hay objetivos. Toca + para añadir uno.\nEl progreso se calcula automáticamente a partir de\ntus registros de calendario y cronología.',
              'TH': 'ยังไม่มีเป้าหมาย แตะ + เพื่อเพิ่ม\nความคืบหน้าจะคำนวณโดยอัตโนมัติจาก\nบันทึกปฏิทินและไทม์ไลน์ของคุณ',
            },
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
    final start = DateTime.tryParse(goal.periodStart);
    final end = DateTime.tryParse(goal.periodEnd);
    final String periodLabel = (start != null && end != null) ? _periodLabel(start, end) : '';

    // 🆕 [운동 목표] 운동 목표면 완료율(summary) 대신 세션 수 기준으로 진행률 계산
    final bool isExerciseGoal = goal.exerciseTargetSessions != null;
    final ReportSummary? summary = isExerciseGoal ? null : _summaryCache[goal.id];
    final int exerciseCount = _exerciseSessionCountCache[goal.id] ?? 0;
    final double progress = isExerciseGoal
        ? (goal.exerciseTargetSessions! == 0 ? 0.0 : (exerciseCount / goal.exerciseTargetSessions!).clamp(0.0, 1.0))
        : (summary?.completionRate ?? 0.0);
    final int percent = isExerciseGoal ? (progress * 100).round() : (summary?.completionPercent ?? 0);

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
              // 🆕 [운동 목표] 운동 목표 카드에는 아령 아이콘을 앞에 표시해서 구분
              if (isExerciseGoal) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.fitness_center_rounded, color: _brandGolden, size: 18)),
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
              BiInline(
                en: '$percent% Complete', ko: '$percent% 진행', color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold,
                translations: {
                  'JA': '$percent% 完了', 'ZH': '$percent% 完成', 'FR': '$percent % Terminé', 'DE': '$percent % Erledigt',
                  'RU': '$percent% Выполнено', 'AR': '$percent% مكتمل', 'HI': '$percent% पूर्ण', 'VI': '$percent% Hoàn thành',
                  'ES': '$percent% Completado', 'TH': '$percent% เสร็จสิ้น',
                },
              ),
              // 🆕 [운동 목표] "3/5회" 형태로 표시, 일반 목표는 기존처럼 completedCount/totalCount
              if (isExerciseGoal)
                Text('$exerciseCount / ${goal.exerciseTargetSessions}회', style: const TextStyle(color: Colors.white38, fontSize: 11))
              else if (summary != null)
                Text('${summary.completedCount} / ${summary.totalCount}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          // 🆕 [연동 안내] 데이터가 캘린더/타임라인(또는 운동 기록)에서 자동으로 온다는 것을 알려주는 작은 힌트
          if (isExerciseGoal && exerciseCount == 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: BiInline(
                en: 'No exercise records for this period yet.',
                ko: '이 기간에 운동 기록이 아직 없습니다.',
                color: Colors.white24,
                fontSize: 10.5,
                translations: const {
                  'JA': 'この期間の運動記録がまだありません。',
                  'ZH': '此期间暂无运动记录。',
                  'FR': "Aucun enregistrement d'exercice pour cette période pour l'instant.",
                  'DE': 'Noch keine Trainingsdaten für diesen Zeitraum.',
                  'RU': 'Пока нет записей о тренировках за этот период.',
                  'AR': 'لا توجد سجلات تمرين لهذه الفترة بعد.',
                  'HI': 'इस अवधि के लिए अभी तक कोई व्यायाम रिकॉर्ड नहीं है।',
                  'VI': 'Chưa có dữ liệu tập luyện cho giai đoạn này.',
                  'ES': 'Aún no hay registros de ejercicio para este período.',
                  'TH': 'ยังไม่มีบันทึกการออกกำลังกายสำหรับช่วงเวลานี้',
                },
              ),
            )
          else if (!isExerciseGoal && summary != null && !summary.hasData)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: BiInline(
                en: 'No calendar/timeline records for this period yet.',
                ko: '이 기간에 캘린더/타임라인 기록이 아직 없습니다.',
                color: Colors.white24,
                fontSize: 10.5,
                translations: const {
                  'JA': 'この期間のカレンダー/タイムライン記録がまだありません。',
                  'ZH': '此期间暂无日历/时间线记录。',
                  'FR': "Aucun enregistrement de calendrier/chronologie pour cette période pour l'instant.",
                  'DE': 'Noch keine Kalender-/Zeitleistendaten für diesen Zeitraum.',
                  'RU': 'Пока нет записей календаря/хронологии за этот период.',
                  'AR': 'لا توجد سجلات تقويم/جدول زمني لهذه الفترة بعد.',
                  'HI': 'इस अवधि के लिए अभी तक कोई कैलेंडर/समयरेखा रिकॉर्ड नहीं है।',
                  'VI': 'Chưa có dữ liệu lịch/dòng thời gian cho giai đoạn này.',
                  'ES': 'Aún no hay registros de calendario/cronología para este período.',
                  'TH': 'ยังไม่มีบันทึกปฏิทิน/ไทม์ไลน์สำหรับช่วงเวลานี้',
                },
              ),
            ),
        ],
      ),
    );
  }
}
