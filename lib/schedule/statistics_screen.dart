// ============================================================================
// 🆕 [일반 플래너 - 병기+연동 정리] StatisticsScreen
// 전체 기간 누적 분류별 시간 비중, 올해 1~12월 완료율 막대그래프, 그리고
// 지금까지 총 달성한 목표 개수를 보여줍니다. 기록이 없는 달은 회색
// "No Data" 막대로 구분해서 표시하고, 가짜 값을 만들지 않습니다.
//
// ✅ [2026-09-04 추가] 운동(EXERCISE) 연동. 전체 기간 누적 운동 요약(세션/
// 시간/평균 RPE) 카드를 추가.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'report_data_service.dart';
import 'goal_data_service.dart'; // 🆕 [목표 연동] 총 달성 목표 개수 표시용
import 'project_data_service.dart'; // 🆕 [프로젝트 연동] 총 완료 프로젝트 개수 표시용
import 'bilingual_text.dart';
import 'exercise_data_service.dart'; // 🆕 [운동 연동]

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  static const List<Color> _categoryColors = [
    Color(0xFFE5C158),
    Color(0xFF60A5FA),
    Color(0xFF34D399),
    Color(0xFFF87171),
    Color(0xFFA78BFA),
    Color(0xFFFBBF24),
  ];

  ReportSummary? _allTimeSummary;
  Map<int, int> _monthlyRates = {};
  int _totalAchievements = 0; // 🆕 [목표 연동]
  int _totalCompletedProjects = 0; // 🆕 [프로젝트 연동]
  int _totalExerciseSessions = 0; // 🆕 [운동 연동]
  int _totalExerciseMinutes = 0; // 🆕 [운동 연동]
  double? _avgExerciseRpe; // 🆕 [운동 연동]
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    final summary = await ReportDataService.summarize(DateTime(now.year - 5, 1, 1), now);
    final monthly = await ReportDataService.calcMonthlyCompletionRates(now.year);
    final achievements = await GoalDataService.loadAchievements(); // 🆕 [목표 연동]
    final allProjects = await ProjectDataService.loadAll(); // 🆕 [프로젝트 연동]
    final completedProjects = allProjects.where((p) => p.status == '완료').length;

    // 🆕 [운동 연동] 전체 기간 누적 운동 기록
    final allExerciseRecords = await ExerciseDataService.instance.getAllRecords();
    final exerciseMinutes = allExerciseRecords.fold<int>(0, (sum, r) => sum + r.durationMin);
    final rpeValues = allExerciseRecords.where((r) => r.rpe != null).map((r) => r.rpe!).toList();
    final avgRpe = rpeValues.isEmpty ? null : rpeValues.reduce((a, b) => a + b) / rpeValues.length;

    if (!mounted) return;
    setState(() {
      _allTimeSummary = summary;
      _monthlyRates = monthly;
      _totalAchievements = achievements.length;
      _totalCompletedProjects = completedProjects;
      _totalExerciseSessions = allExerciseRecords.length; // 🆕 [운동 연동]
      _totalExerciseMinutes = exerciseMinutes; // 🆕 [운동 연동]
      _avgExerciseRpe = avgRpe; // 🆕 [운동 연동]
      _isLoading = false;
    });
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
          en: 'STATISTICS', ko: '통계', enSize: 19, koSize: 14,
          translations: const {'JA': '統計', 'ZH': '统计', 'FR': 'Statistiques', 'DE': 'Statistik', 'RU': 'Статистика', 'AR': 'الإحصائيات', 'HI': 'सांख्यिकी', 'VI': 'Thống kê', 'ES': 'Estadísticas', 'TH': 'สถิติ'},
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAchievementCard(), // 🆕 [목표 연동]
          const SizedBox(height: 16),
          _buildProjectCard(), // 🆕 [프로젝트 연동]
          const SizedBox(height: 16),
          if (_totalExerciseSessions > 0) ...[
            _buildExerciseCard(), // 🆕 [운동 연동]
            const SizedBox(height: 16),
          ],
          _buildCategoryBreakdownCard(),
          const SizedBox(height: 16),
          _buildMonthlyBarChartCard(),
        ],
      ),
    );
  }

  // 🆕 [목표 연동] 지금까지 총 달성한 목표 개수
  Widget _buildAchievementCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: _brandGolden, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: BiInline(
              en: 'Total Goals Achieved', ko: '총 달성한 목표', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
              translations: const {'JA': '達成した目標の合計', 'ZH': '累计达成目标', 'FR': 'Total des objectifs atteints', 'DE': 'Insgesamt erreichte Ziele', 'RU': 'Всего достигнутых целей', 'AR': 'إجمالي الأهداف المحققة', 'HI': 'कुल हासिल किए गए लक्ष्य', 'VI': 'Tổng mục tiêu đạt được', 'ES': 'Total de objetivos logrados', 'TH': 'เป้าหมายที่บรรลุทั้งหมด'},
            ),
          ),
          Text('$_totalAchievements', style: GoogleFonts.rajdhani(color: _brandGolden, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 🆕 [프로젝트 연동] 지금까지 총 완료한 프로젝트 개수
  Widget _buildProjectCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Row(
        children: [
          const Icon(Icons.rocket_launch_rounded, color: _brandGolden, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: BiInline(
              en: 'Total Projects Completed', ko: '총 완료된 프로젝트', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
              translations: const {'JA': '完了したプロジェクトの合計', 'ZH': '累计完成项目', 'FR': 'Total des projets terminés', 'DE': 'Insgesamt abgeschlossene Projekte', 'RU': 'Всего завершённых проектов', 'AR': 'إجمالي المشاريع المكتملة', 'HI': 'कुल पूर्ण की गई परियोजनाएं', 'VI': 'Tổng dự án hoàn thành', 'ES': 'Total de proyectos completados', 'TH': 'โครงการที่เสร็จทั้งหมด'},
            ),
          ),
          Text('$_totalCompletedProjects', style: GoogleFonts.rajdhani(color: _brandGolden, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 🆕 [운동 연동] 전체 기간 누적 운동 요약 - 세션/시간/평균 RPE
  Widget _buildExerciseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center_rounded, color: _brandGolden, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: BiInline(
                  en: 'Total Exercise (All Time)', ko: '누적 운동 (전체 기간)', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
                  translations: const {'JA': '累計運動（全期間）', 'ZH': '累计运动（全部时间）', 'FR': "Exercice total (toute période)", 'DE': 'Gesamttraining (gesamter Zeitraum)', 'RU': 'Всего тренировок (за всё время)', 'AR': 'إجمالي التمرين (كل الفترات)', 'HI': 'कुल व्यायाम (संपूर्ण अवधि)', 'VI': 'Tổng tập luyện (toàn bộ)', 'ES': 'Ejercicio total (todo el período)', 'TH': 'ออกกำลังกายทั้งหมด (ทั้งหมด)'},
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _exerciseStat('SESSIONS', '세션', '$_totalExerciseSessions')),
              Expanded(child: _exerciseStat('MINUTES', '시간(분)', '$_totalExerciseMinutes')),
              Expanded(child: _exerciseStat('AVG RPE', '평균 강도', _avgExerciseRpe == null ? '-' : _avgExerciseRpe!.toStringAsFixed(1))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _exerciseStat(String en, String ko, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.rajdhani(color: _brandGolden, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        BiInline(en: en, ko: ko, color: Colors.white54, fontSize: 10),
      ],
    );
  }

  Widget _buildCategoryBreakdownCard() {
    final categoryMinutes = _allTimeSummary?.categoryMinutes ?? {};
    final int total = categoryMinutes.values.fold(0, (a, b) => a + b);
    final entries = categoryMinutes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BiInline(
            en: 'Time Usage (All Time)', ko: '시간 사용 비율 (전체 기간)', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
            translations: const {'JA': '時間使用率（全期間）', 'ZH': '时间使用比例（全部时间）', 'FR': 'Utilisation du temps (toute période)', 'DE': 'Zeitnutzung (gesamter Zeitraum)', 'RU': 'Использование времени (за всё время)', 'AR': 'استخدام الوقت (كل الفترات)', 'HI': 'समय उपयोग (संपूर्ण अवधि)', 'VI': 'Sử dụng thời gian (toàn bộ)', 'ES': 'Uso del tiempo (todo el período)', 'TH': 'การใช้เวลา (ทั้งหมด)'},
          ),
          const SizedBox(height: 14),
          if (total == 0)
            BiInline(
              en: 'No completed timeline records yet.', ko: '아직 완료된 타임라인 기록이 없습니다.', color: Colors.white38, fontSize: 12,
              translations: const {'JA': 'まだ完了したタイムライン記録がありません。', 'ZH': '暂无已完成的时间线记录。', 'FR': "Aucun enregistrement de chronologie terminé pour l'instant.", 'DE': 'Noch keine abgeschlossenen Zeitleistenaufzeichnungen.', 'RU': 'Пока нет завершённых записей хронологии.', 'AR': 'لا توجد سجلات جدول زمني مكتملة بعد.', 'HI': 'अभी तक कोई पूर्ण समयरेखा रिकॉर्ड नहीं।', 'VI': 'Chưa có bản ghi dòng thời gian nào hoàn thành.', 'ES': 'Aún no hay registros de cronología completados.', 'TH': 'ยังไม่มีบันทึกไทม์ไลน์ที่เสร็จสิ้น'},
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 24,
                child: Row(
                  children: List.generate(entries.length, (i) {
                    final e = entries[i];
                    final double flexValue = e.value / total;
                    return Expanded(flex: (flexValue * 1000).round().clamp(1, 1000), child: Container(color: _categoryColors[i % _categoryColors.length]));
                  }),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...List.generate(entries.length, (i) {
              final e = entries[i];
              final int pct = ((e.value / total) * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: _categoryColors[i % _categoryColors.length], shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 13))),
                    Text('$pct%', style: const TextStyle(color: _brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyBarChartCard() {
    final now = DateTime.now();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BiInline(
            en: '${now.year} Monthly Completion', ko: '${now.year}년 월별 목표 달성률', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
            translations: {
              'JA': '${now.year}年 月別達成率', 'ZH': '${now.year}年 月度完成率', 'FR': "Achèvement mensuel ${now.year}", 'DE': 'Monatliche Fertigstellung ${now.year}',
              'RU': 'Ежемесячное выполнение ${now.year}', 'AR': 'الإنجاز الشهري ${now.year}', 'HI': '${now.year} मासिक पूर्णता', 'VI': 'Hoàn thành hàng tháng ${now.year}',
              'ES': 'Finalización mensual ${now.year}', 'TH': 'ความสำเร็จรายเดือน ${now.year}',
            },
          ),
          const SizedBox(height: 16),
          ...List.generate(12, (i) {
            final int month = i + 1;
            final int rate = _monthlyRates[month] ?? -1;
            final bool hasData = rate >= 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(width: 32, child: Text(appLanguage.isDefault ? '$month월' : '$month', style: const TextStyle(color: Colors.white70, fontSize: 12))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: hasData ? rate / 100 : 0, minHeight: 14, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation<Color>(hasData ? _brandGolden : Colors.white24)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 62,
                    child: Text(hasData ? '$rate%' : 'No Data', style: TextStyle(color: hasData ? _brandGolden : Colors.white24, fontSize: 10.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
