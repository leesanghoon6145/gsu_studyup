// ============================================================================
// 🆕 [일반 플래너 - 병기+연동 정리] MonthlyReportScreen
// 이번 달의 완료율, 루틴 성공률, 분류별 시간 사용, 이번 달 달성한 목표
// 개수를 보여줍니다. 데이터가 없는 항목(예: 루틴을 아직 안 쓴 경우)은
// 가짜 %가 아니라 "데이터 없음"으로 구분해서 표시합니다.
//
// ✅ [2026-09-04 추가] 운동(EXERCISE) 연동. 이번 달 운동 요약(세션/시간/평균
// RPE + 종목별 랭킹) 카드를 추가.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'report_data_service.dart';
import 'bilingual_text.dart';
import 'exercise_data_service.dart'; // 🆕 [운동 연동]
import 'exercise_models.dart'; // 🆕 [운동 연동]
import 'exercise_theme.dart' show ExerciseTheme; // 🆕 [운동 연동]

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  ReportSummary? _summary;
  int? _routineSuccessRate;
  int _achievedGoalCount = 0;
  int _completedProjectCount = 0; // 🆕 [프로젝트 연동]
  List<ExerciseRecord> _exercises = []; // 🆕 [운동 연동]
  Map<String, ExerciseType> _exerciseTypesById = {}; // 🆕 [운동 연동]
  late DateTime _monthStart;
  late DateTime _monthEnd;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthStart = DateTime(now.year, now.month, 1);
    _monthEnd = DateTime(now.year, now.month + 1, 0);
    _load();
  }

  bool _inRange(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final start = DateTime(_monthStart.year, _monthStart.month, _monthStart.day);
    final end = DateTime(_monthEnd.year, _monthEnd.month, _monthEnd.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final summary = await ReportDataService.summarize(_monthStart, _monthEnd);
    final routineRate = await ReportDataService.calcRoutineSuccessRate(_monthStart, _monthEnd);
    final projectCount = await ReportDataService.countProjectsCompletedInRange(_monthStart, _monthEnd);
    final achievedCount = await ReportDataService.countAchievementsInRange(_monthStart, _monthEnd);

    // 🆕 [운동 연동] 이번 달 운동 기록 + 종목(아이콘/이름 조회용) 로드
    final exerciseTypes = await ExerciseDataService.instance.getExerciseTypes(includeHidden: true);
    final typesById = {for (final t in exerciseTypes) t.id: t};
    final allExerciseRecords = await ExerciseDataService.instance.getAllRecords();
    final monthExercises = allExerciseRecords.where((r) => _inRange(r.date)).toList();

    if (!mounted) return;
    setState(() {
      _summary = summary;
      _routineSuccessRate = routineRate;
      _achievedGoalCount = achievedCount;
      _completedProjectCount = projectCount;
      _exercises = monthExercises; // 🆕 [운동 연동]
      _exerciseTypesById = typesById; // 🆕 [운동 연동]
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasReportableData = (_summary != null && _summary!.hasData) || _exercises.isNotEmpty; // 🆕 [운동 연동]

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: BiTitle(
          en: 'MONTHLY REPORT', ko: '월간 리포트', enSize: 16, koSize: 13,
          translations: const {'JA': '月次レポート', 'ZH': '月报', 'FR': 'Rapport mensuel', 'DE': 'Monatsbericht', 'RU': 'Месячный отчёт', 'AR': 'التقرير الشهري', 'HI': 'मासिक रिपोर्ट', 'VI': 'Báo cáo hàng tháng', 'ES': 'Informe mensual', 'TH': 'รายงานรายเดือน'},
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : !hasReportableData
          ? Center(
        child: BiInline(
          en: 'No records for this month yet.', ko: '이번 달 등록된 기록이 없습니다.', color: Colors.white38, fontSize: 14, textAlign: TextAlign.center,
          translations: const {'JA': '今月の記録がまだありません。', 'ZH': '本月暂无记录。', 'FR': "Aucun enregistrement ce mois-ci pour l'instant.", 'DE': 'Noch keine Aufzeichnungen für diesen Monat.', 'RU': 'Пока нет записей за этот месяц.', 'AR': 'لا توجد سجلات لهذا الشهر بعد.', 'HI': 'इस महीने के लिए अभी तक कोई रिकॉर्ड नहीं।', 'VI': 'Chưa có bản ghi nào cho tháng này.', 'ES': 'Aún no hay registros para este mes.', 'TH': 'ยังไม่มีบันทึกสำหรับเดือนนี้'},
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${_monthStart.year}.${_monthStart.month.toString().padLeft(2, '0')}', style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_summary != null && _summary!.hasData) ...[
            _buildCompletionCard(),
            const SizedBox(height: 16),
          ],
          if (_exercises.isNotEmpty) ...[
            _buildExerciseSummaryCard(), // 🆕 [운동 연동]
            const SizedBox(height: 16),
          ],
          _buildGoalAchievedCard(),
          const SizedBox(height: 16),
          _buildProjectCompletedCard(),
          const SizedBox(height: 16),
          _buildRoutineCard(),
          if (_summary != null && _summary!.hasData) ...[
            const SizedBox(height: 16),
            _buildCategoryCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletionCard() {
    final s = _summary!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BiInline(
            en: 'Monthly Completion', ko: '목표 달성률', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
            translations: const {'JA': '月間達成率', 'ZH': '月度完成率', 'FR': "Taux d'achèvement mensuel", 'DE': 'Monatliche Fertigstellung', 'RU': 'Месячный процент выполнения', 'AR': 'نسبة الإنجاز الشهرية', 'HI': 'मासिक पूर्णता दर', 'VI': 'Tỷ lệ hoàn thành hàng tháng', 'ES': 'Finalización mensual', 'TH': 'อัตราความสำเร็จรายเดือน'},
          ),
          const SizedBox(height: 8),
          Text('${s.completionPercent}%', style: GoogleFonts.rajdhani(color: _brandGolden, fontSize: 36, fontWeight: FontWeight.bold)),
          BiInline(
            en: 'Completed ${s.completedCount} / Total ${s.totalCount}', ko: '완료 ${s.completedCount}건 / 전체 ${s.totalCount}건', color: Colors.white38, fontSize: 12,
            translations: {
              'JA': '完了 ${s.completedCount} / 全体 ${s.totalCount}', 'ZH': '完成 ${s.completedCount} / 总计 ${s.totalCount}', 'FR': 'Terminé ${s.completedCount} / Total ${s.totalCount}', 'DE': 'Erledigt ${s.completedCount} / Gesamt ${s.totalCount}',
              'RU': 'Выполнено ${s.completedCount} / Всего ${s.totalCount}', 'AR': 'مكتمل ${s.completedCount} / الإجمالي ${s.totalCount}', 'HI': 'पूर्ण ${s.completedCount} / कुल ${s.totalCount}', 'VI': 'Hoàn thành ${s.completedCount} / Tổng ${s.totalCount}',
              'ES': 'Completado ${s.completedCount} / Total ${s.totalCount}', 'TH': 'เสร็จ ${s.completedCount} / ทั้งหมด ${s.totalCount}',
            },
          ),
        ],
      ),
    );
  }

  // 🆕 [운동 연동] 이번 달 운동 요약 카드 - 세션/시간/평균RPE + 종목별 랭킹
  Widget _buildExerciseSummaryCard() {
    final totalMinutes = _exercises.fold<int>(0, (sum, r) => sum + r.durationMin);
    final rpeValues = _exercises.where((r) => r.rpe != null).map((r) => r.rpe!).toList();
    final avgRpe = rpeValues.isEmpty ? null : rpeValues.reduce((a, b) => a + b) / rpeValues.length;
    final Map<String, int> countByType = {};
    for (final r in _exercises) {
      countByType[r.exerciseTypeId] = (countByType[r.exerciseTypeId] ?? 0) + 1;
    }
    final ranked = countByType.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center_rounded, color: _brandGolden, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: BiInline(
                  en: 'Exercise This Month', ko: '이번 달 운동', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
                  translations: const {'JA': '今月の運動', 'ZH': '本月运动', 'FR': "Exercice ce mois-ci", 'DE': 'Training diesen Monat', 'RU': 'Тренировки в этом месяце', 'AR': 'تمرين هذا الشهر', 'HI': 'इस महीने व्यायाम', 'VI': 'Tập luyện tháng này', 'ES': 'Ejercicio este mes', 'TH': 'ออกกำลังกายเดือนนี้'},
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _exerciseStat('SESSIONS', '세션', '${_exercises.length}')),
              Expanded(child: _exerciseStat('MINUTES', '시간(분)', '$totalMinutes')),
              Expanded(child: _exerciseStat('AVG RPE', '평균 강도', avgRpe == null ? '-' : avgRpe.toStringAsFixed(1))),
            ],
          ),
          if (ranked.isNotEmpty) ...[
            const Divider(color: Colors.white12, height: 24),
            ...ranked.take(5).map((e) {
              final type = _exerciseTypesById[e.key];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(ExerciseTheme.iconForType(e.key), color: _brandGolden, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(type?.name ?? e.key, style: const TextStyle(color: Colors.white, fontSize: 13))),
                    Text('${e.value}회', style: const TextStyle(color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _exerciseStat(String en, String ko, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: _brandGolden, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        BiInline(en: en, ko: ko, color: Colors.white54, fontSize: 10),
      ],
    );
  }

  Widget _buildGoalAchievedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: _brandGolden, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: BiInline(
              en: 'Goals Achieved This Month', ko: '이번 달 달성한 목표', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
              translations: const {'JA': '今月達成した目標', 'ZH': '本月达成目标', 'FR': 'Objectifs atteints ce mois-ci', 'DE': 'Diesen Monat erreichte Ziele', 'RU': 'Цели, достигнутые в этом месяце', 'AR': 'الأهداف المحققة هذا الشهر', 'HI': 'इस महीने हासिल किए गए लक्ष्य', 'VI': 'Mục tiêu đạt được tháng này', 'ES': 'Objetivos logrados este mes', 'TH': 'เป้าหมายที่บรรลุเดือนนี้'},
            ),
          ),
          Text('$_achievedGoalCount', style: const TextStyle(color: _brandGolden, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 🆕 [프로젝트 연동] 이번 달 완료된 프로젝트 개수
  Widget _buildProjectCompletedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Row(
        children: [
          const Icon(Icons.rocket_launch_rounded, color: _brandGolden, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: BiInline(
              en: 'Projects Completed This Month', ko: '이번 달 완료된 프로젝트', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
              translations: const {'JA': '今月完了したプロジェクト', 'ZH': '本月完成的项目', 'FR': 'Projets terminés ce mois-ci', 'DE': 'Diesen Monat abgeschlossene Projekte', 'RU': 'Проекты, завершённые в этом месяце', 'AR': 'المشاريع المكتملة هذا الشهر', 'HI': 'इस महीने पूर्ण की गई परियोजनाएं', 'VI': 'Dự án hoàn thành tháng này', 'ES': 'Proyectos completados este mes', 'TH': 'โครงการที่เสร็จเดือนนี้'},
            ),
          ),
          Text('$_completedProjectCount', style: const TextStyle(color: _brandGolden, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRoutineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BiInline(
            en: 'Routine Success Rate', ko: '루틴 성공률', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
            translations: const {'JA': 'ルーティン成功率', 'ZH': '常规成功率', 'FR': 'Taux de réussite des routines', 'DE': 'Routine-Erfolgsquote', 'RU': 'Успешность распорядка', 'AR': 'معدل نجاح الروتين', 'HI': 'दिनचर्या सफलता दर', 'VI': 'Tỷ lệ thành công thói quen', 'ES': 'Tasa de éxito de rutinas', 'TH': 'อัตราความสำเร็จของกิจวัตร'},
          ),
          Text(_routineSuccessRate != null ? '$_routineSuccessRate%' : '-', style: const TextStyle(color: _brandGolden, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard() {
    final categoryMinutes = _summary!.categoryMinutes;
    final entries = categoryMinutes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final int totalMinutes = _summary!.totalMinutes;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BiInline(
            en: 'Time by Category', ko: '분류별 시간 사용', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
            translations: const {'JA': 'カテゴリー別使用時間', 'ZH': '按分类用时', 'FR': 'Temps par catégorie', 'DE': 'Zeit nach Kategorie', 'RU': 'Время по категориям', 'AR': 'الوقت حسب الفئة', 'HI': 'श्रेणी अनुसार समय', 'VI': 'Thời gian theo danh mục', 'ES': 'Tiempo por categoría', 'TH': 'เวลาตามหมวดหมู่'},
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            BiInline(
              en: 'No completed timeline items yet.', ko: '완료된 타임라인 항목이 없습니다.', color: Colors.white38, fontSize: 12,
              translations: const {'JA': 'まだ完了したタイムライン項目がありません。', 'ZH': '暂无已完成的时间线项目。', 'FR': "Aucun élément de chronologie terminé pour l'instant.", 'DE': 'Noch keine abgeschlossenen Zeitleisteneinträge.', 'RU': 'Пока нет завершённых элементов хронологии.', 'AR': 'لا توجد عناصر جدول زمني مكتملة بعد.', 'HI': 'अभी तक कोई पूर्ण समयरेखा आइटम नहीं।', 'VI': 'Chưa có mục dòng thời gian nào hoàn thành.', 'ES': 'Aún no hay elementos de cronología completados.', 'TH': 'ยังไม่มีรายการไทม์ไลน์ที่เสร็จสิ้น'},
            )
          else
            ...entries.map((e) {
              final int hours = e.value ~/ 60;
              final int mins = e.value % 60;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 13))),
                    Text('${hours}h ${mins}m (${hours}시간 ${mins}분)', style: const TextStyle(color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          if (totalMinutes > 0) ...[
            const Divider(color: Colors.white12, height: 20),
            BiInline(
              en: 'Total: ${totalMinutes ~/ 60}h ${totalMinutes % 60}m', ko: '총 자기계발/활동 시간: ${totalMinutes ~/ 60}시간 ${totalMinutes % 60}분', color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold,
              translations: {
                'JA': '合計: ${totalMinutes ~/ 60}時間${totalMinutes % 60}分', 'ZH': '总计: ${totalMinutes ~/ 60}小时${totalMinutes % 60}分', 'FR': 'Total : ${totalMinutes ~/ 60}h ${totalMinutes % 60}min', 'DE': 'Gesamt: ${totalMinutes ~/ 60}Std ${totalMinutes % 60}Min',
                'RU': 'Всего: ${totalMinutes ~/ 60}ч ${totalMinutes % 60}мин', 'AR': 'الإجمالي: ${totalMinutes ~/ 60}س ${totalMinutes % 60}د', 'HI': 'कुल: ${totalMinutes ~/ 60}घं ${totalMinutes % 60}मि', 'VI': 'Tổng: ${totalMinutes ~/ 60}g ${totalMinutes % 60}p',
                'ES': 'Total: ${totalMinutes ~/ 60}h ${totalMinutes % 60}m', 'TH': 'รวม: ${totalMinutes ~/ 60}ชม ${totalMinutes % 60}น',
              },
            ),
          ],
        ],
      ),
    );
  }
}
