// ============================================================================
// 🆕 [일반 플래너 3단계] ProgressScreen
// 모든 목표(인생/연간/월간/주간/오늘)의 진행률을 유형별로 모아 한눈에
// 보여줍니다. 각 목표의 진행률은 GoalDataService.calcGoalProgress()로 실시간
// 계산되며, 목표가 하나도 없으면 가짜 숫자 대신 빈 상태 안내를 보여줍니다.
//
// ✅ [2026-09-04 추가] 운동(EXERCISE) 연동. 목표 시스템과는 별개로, 이번 주
// 운동 현황을 보여주는 정보성 카드를 상단에 추가 (GoalItem과 무관한 순수 정보).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'goal_data_service.dart';
import 'report_data_service.dart'; // 🆕 [버그 수정] 기간별 목표는 캘린더+타임라인 실데이터로 진행률 계산
import 'bilingual_text.dart';
import 'exercise_data_service.dart'; // 🆕 [운동 연동]

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  static const Map<String, String> _typeLabels = {
    'life': '인생 목표',
    'yearly': '연간 목표',
    'monthly': '월간 목표',
    'weekly': '주간 목표',
    'today': '오늘 목표',
  };
  static const Map<String, String> _typeLabelsEn = {
    'life': 'Life Goal',
    'yearly': 'Yearly Goal',
    'monthly': 'Monthly Goal',
    'weekly': 'Weekly Goal',
    'today': 'Today Goal',
  };
  // 🆕 [10개국어 확장] 목표 유형별 이름 번역
  static const Map<String, Map<String, String>> _typeLabelsTranslations = {
    'life': {'JA': '人生の目標', 'ZH': '人生目标', 'FR': 'Objectif de vie', 'DE': 'Lebensziel', 'RU': 'Жизненная цель', 'AR': 'هدف الحياة', 'HI': 'जीवन लक्ष्य', 'VI': 'Mục tiêu cuộc đời', 'ES': 'Objetivo de vida', 'TH': 'เป้าหมายชีวิต'},
    'yearly': {'JA': '年間目標', 'ZH': '年度目标', 'FR': 'Objectif annuel', 'DE': 'Jahresziel', 'RU': 'Годовая цель', 'AR': 'الهدف السنوي', 'HI': 'वार्षिक लक्ष्य', 'VI': 'Mục tiêu năm', 'ES': 'Objetivo anual', 'TH': 'เป้าหมายรายปี'},
    'monthly': {'JA': '月間目標', 'ZH': '月度目标', 'FR': 'Objectif mensuel', 'DE': 'Monatsziel', 'RU': 'Месячная цель', 'AR': 'الهدف الشهري', 'HI': 'मासिक लक्ष्य', 'VI': 'Mục tiêu tháng', 'ES': 'Objetivo mensual', 'TH': 'เป้าหมายรายเดือน'},
    'weekly': {'JA': '週間目標', 'ZH': '每周目标', 'FR': 'Objectif hebdomadaire', 'DE': 'Wochenziel', 'RU': 'Недельная цель', 'AR': 'الهدف الأسبوعي', 'HI': 'साप्ताहिक लक्ष्य', 'VI': 'Mục tiêu tuần', 'ES': 'Objetivo semanal', 'TH': 'เป้าหมายรายสัปดาห์'},
    'today': {'JA': '今日の目標', 'ZH': '今日目标', 'FR': "Objectif du jour", 'DE': 'Tagesziel', 'RU': 'Цель на сегодня', 'AR': 'هدف اليوم', 'HI': 'आज का लक्ष्य', 'VI': 'Mục tiêu hôm nay', 'ES': 'Objetivo de hoy', 'TH': 'เป้าหมายวันนี้'},
  };

  List<GoalItem> _allGoals = [];
  Map<String, double> _progressCache = {};
  int _weeklyExerciseSessions = 0; // 🆕 [운동 연동]
  int _weeklyExerciseMinutes = 0; // 🆕 [운동 연동]
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final all = await GoalDataService.loadAllGoals();
    final Map<String, double> progressMap = {};
    for (final g in all) {
      if (g.type == 'life') {
        // 🆕 인생목표만 할 일 체크 기반으로 계산 (의도된 예외)
        progressMap[g.id] = await GoalDataService.calcGoalProgress(g.id);
      } else {
        // 🆕 [버그 수정] 연간/월간/주간/오늘 목표는 캘린더+타임라인 실데이터 기준으로 계산
        // (period_goal_screen.dart와 완전히 동일한 방식 - 더 이상 할 일 체크를 쓰지 않음)
        final start = DateTime.tryParse(g.periodStart) ?? DateTime.now();
        final end = DateTime.tryParse(g.periodEnd) ?? DateTime.now();
        final summary = await ReportDataService.summarize(start, end);
        progressMap[g.id] = summary.completionRate;
      }
    }

    // 🆕 [운동 연동] 이번 주(월~일) 운동 세션/시간 - 목표 시스템과 무관한 정보성 지표
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final allExercises = await ExerciseDataService.instance.getAllRecords();
    final weekExercises = allExercises.where((r) {
      final day = DateTime(r.date.year, r.date.month, r.date.day);
      final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final end = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);
      return !day.isBefore(start) && !day.isAfter(end);
    }).toList();

    if (!mounted) return;
    setState(() {
      _allGoals = all;
      _progressCache = progressMap;
      _weeklyExerciseSessions = weekExercises.length; // 🆕 [운동 연동]
      _weeklyExerciseMinutes = weekExercises.fold<int>(0, (sum, r) => sum + r.durationMin); // 🆕 [운동 연동]
      _isLoading = false;
    });
  }

  double get _overallAverage {
    if (_allGoals.isEmpty) return 0;
    final sum = _allGoals.fold<double>(0, (acc, g) => acc + (_progressCache[g.id] ?? 0));
    return sum / _allGoals.length;
  }

  @override
  Widget build(BuildContext context) {
    // 🆕 [운동 연동] 목표가 하나도 없어도 운동 기록이 있으면 완전히 빈 화면 대신 운동 카드는 보여준다.
    final bool hasAnything = _allGoals.isNotEmpty || _weeklyExerciseSessions > 0;

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
        title: BiTitle(
          en: 'PROGRESS', ko: '진행률', enSize: 19, koSize: 14,
          translations: const {'JA': '進捗', 'ZH': '进度', 'FR': 'Progrès', 'DE': 'Fortschritt', 'RU': 'Прогресс', 'AR': 'التقدم', 'HI': 'प्रगति', 'VI': 'Tiến độ', 'ES': 'Progreso', 'TH': 'ความคืบหน้า'},
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : !hasAnything
          ? Center(
        child: BiInline(
          en: 'No goals yet. Create a goal and check off tasks\nto see progress here.',
          ko: '등록된 목표가 없습니다.\n목표를 만들고 할 일을 체크하면\n여기에 진행률이 표시됩니다.',
          color: Colors.white38,
          fontSize: 14,
          textAlign: TextAlign.center,
          translations: const {
            'JA': 'まだ目標がありません。\n目標を作成して作業をチェックすると、\nここに進捗が表示されます。',
            'ZH': '暂无目标。\n创建目标并勾选任务后，\n进度会显示在这里。',
            'FR': "Aucun objectif pour l'instant.\nCréez un objectif et cochez des tâches\npour voir la progression ici.",
            'DE': 'Noch keine Ziele.\nErstellen Sie ein Ziel und haken Sie Aufgaben ab,\num hier den Fortschritt zu sehen.',
            'RU': 'Пока нет целей.\nСоздайте цель и отмечайте задачи,\nчтобы увидеть прогресс здесь.',
            'AR': 'لا توجد أهداف بعد.\nأنشئ هدفًا وحدد المهام\nلرؤية التقدم هنا.',
            'HI': 'अभी तक कोई लक्ष्य नहीं है।\nलक्ष्य बनाएं और कार्य चेक करें\nयहां प्रगति देखने के लिए।',
            'VI': 'Chưa có mục tiêu nào.\nTạo mục tiêu và đánh dấu công việc\nđể xem tiến độ tại đây.',
            'ES': 'Aún no hay objetivos.\nCrea un objetivo y marca tareas\npara ver el progreso aquí.',
            'TH': 'ยังไม่มีเป้าหมาย\nสร้างเป้าหมายและทำเครื่องหมายงาน\nเพื่อดูความคืบหน้าที่นี่',
          },
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_allGoals.isNotEmpty) ...[
            _buildOverallCard(),
            const SizedBox(height: 16),
          ],
          if (_weeklyExerciseSessions > 0) ...[
            _buildExerciseCard(), // 🆕 [운동 연동]
            const SizedBox(height: 16),
          ],
          ..._typeLabels.entries.map((entry) => _buildTypeSection(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildOverallCard() {
    final int percent = (_overallAverage * 100).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BiInline(
            en: 'Overall Average Progress', ko: '전체 목표 평균 진행률', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
            translations: const {'JA': '全体平均進捗', 'ZH': '总体平均进度', 'FR': 'Progression moyenne globale', 'DE': 'Durchschnittlicher Gesamtfortschritt', 'RU': 'Средний общий прогресс', 'AR': 'متوسط التقدم الإجمالي', 'HI': 'कुल औसत प्रगति', 'VI': 'Tiến độ trung bình tổng thể', 'ES': 'Progreso promedio general', 'TH': 'ความคืบหน้าเฉลี่ยโดยรวม'},
          ),
          const SizedBox(height: 8),
          Text('$percent%', style: GoogleFonts.rajdhani(color: _brandGolden, fontSize: 36, fontWeight: FontWeight.bold)),
          BiInline(
            en: 'Total ${_allGoals.length} goals', ko: '총 ${_allGoals.length}개 목표', color: Colors.white38, fontSize: 12,
            translations: {
              'JA': '合計 ${_allGoals.length}件', 'ZH': '共 ${_allGoals.length} 个目标', 'FR': '${_allGoals.length} objectifs au total', 'DE': 'Insgesamt ${_allGoals.length} Ziele',
              'RU': 'Всего ${_allGoals.length} целей', 'AR': 'إجمالي ${_allGoals.length} أهداف', 'HI': 'कुल ${_allGoals.length} लक्ष्य', 'VI': 'Tổng ${_allGoals.length} mục tiêu',
              'ES': 'Total ${_allGoals.length} objetivos', 'TH': 'ทั้งหมด ${_allGoals.length} เป้าหมาย',
            },
          ),
        ],
      ),
    );
  }

  // 🆕 [운동 연동] 이번 주 운동 현황 - GoalItem과 무관한 순수 정보성 카드
  Widget _buildExerciseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Row(
        children: [
          const Icon(Icons.fitness_center_rounded, color: _brandGolden, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: BiInline(
              en: 'This Week: Exercise', ko: '이번 주 운동 현황', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
              translations: const {'JA': '今週の運動状況', 'ZH': '本周运动情况', 'FR': "Cette semaine : exercice", 'DE': 'Diese Woche: Training', 'RU': 'На этой неделе: тренировки', 'AR': 'هذا الأسبوع: التمرين', 'HI': 'इस सप्ताह: व्यायाम', 'VI': 'Tuần này: Tập luyện', 'ES': 'Esta semana: ejercicio', 'TH': 'สัปดาห์นี้: ออกกำลังกาย'},
            ),
          ),
          Text(
            '$_weeklyExerciseSessions회 · $_weeklyExerciseMinutes분',
            style: GoogleFonts.rajdhani(color: _brandGolden, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSection(String type, String label) {
    final goals = _allGoals.where((g) => g.type == type).toList();
    if (goals.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BiInline(en: _typeLabelsEn[type] ?? type, ko: label, color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 14, translations: _typeLabelsTranslations[type]),
            const SizedBox(height: 10),
            ...goals.map((g) {
              final double progress = _progressCache[g.id] ?? 0.0;
              final int pct = (progress * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Text(g.title,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: g.isAchieved ? Colors.white38 : Colors.white, fontSize: 13, decoration: g.isAchieved ? TextDecoration.lineThrough : null))),
                        Text('$pct%', style: const TextStyle(color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation<Color>(_brandGolden)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
