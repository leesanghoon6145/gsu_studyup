// ============================================================================
// 🆕 [일반 플래너 - 병기+연동 정리] WeeklyReportScreen
// 이번 주(월~일)의 완료율, 가장 바쁜 요일, 가장 생산적인 시간대, 이번 주
// 달성한 목표 개수를 보여줍니다. 전부 실제 캘린더/타임라인/목표 데이터
// 기준으로 계산됩니다.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'report_data_service.dart';
import 'bilingual_text.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  ReportSummary? _summary;
  String? _busiestWeekday;
  String? _productiveHourRange;
  int _achievedGoalCount = 0;
  int _completedProjectCount = 0; // 🆕 [프로젝트 연동]
  late DateTime _weekStart;
  late DateTime _weekEnd;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
    _weekEnd = _weekStart.add(const Duration(days: 6));
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final summary = await ReportDataService.summarize(_weekStart, _weekEnd);
    final busiest = await ReportDataService.findBusiestWeekday(_weekStart, _weekEnd);
    final productive = await ReportDataService.findMostProductiveHourRange(_weekStart, _weekEnd);
    final projectCount = await ReportDataService.countProjectsCompletedInRange(_weekStart, _weekEnd);
    final achievedCount = await ReportDataService.countAchievementsInRange(_weekStart, _weekEnd);

    if (!mounted) return;
    setState(() {
      _summary = summary;
      _busiestWeekday = busiest;
      _productiveHourRange = productive;
      _achievedGoalCount = achievedCount;
      _completedProjectCount = projectCount;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String rangeText = '${_weekStart.month}/${_weekStart.day} ~ ${_weekEnd.month}/${_weekEnd.day}';

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: BiTitle(
          en: 'WEEKLY REPORT', ko: '주간 리포트', enSize: 16, koSize: 13,
          translations: const {'JA': '週次レポート', 'ZH': '周报', 'FR': 'Rapport hebdomadaire', 'DE': 'Wochenbericht', 'RU': 'Недельный отчёт', 'AR': 'التقرير الأسبوعي', 'HI': 'साप्ताहिक रिपोर्ट', 'VI': 'Báo cáo hàng tuần', 'ES': 'Informe semanal', 'TH': 'รายงานรายสัปดาห์'},
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : (_summary == null || !_summary!.hasData)
          ? Center(
        child: BiInline(
          en: 'No records for this week yet.', ko: '이번 주 등록된 기록이 없습니다.', color: Colors.white38, fontSize: 14, textAlign: TextAlign.center,
          translations: const {'JA': '今週の記録がまだありません。', 'ZH': '本周暂无记录。', 'FR': "Aucun enregistrement cette semaine pour l'instant.", 'DE': 'Noch keine Aufzeichnungen für diese Woche.', 'RU': 'Пока нет записей за эту неделю.', 'AR': 'لا توجد سجلات لهذا الأسبوع بعد.', 'HI': 'इस सप्ताह के लिए अभी तक कोई रिकॉर्ड नहीं।', 'VI': 'Chưa có bản ghi nào cho tuần này.', 'ES': 'Aún no hay registros para esta semana.', 'TH': 'ยังไม่มีบันทึกสำหรับสัปดาห์นี้'},
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(rangeText, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildCompletionCard(),
          const SizedBox(height: 16),
          _buildGoalAchievedCard(),
          const SizedBox(height: 16),
          _buildProjectCompletedCard(),
          const SizedBox(height: 16),
          _buildInsightCard(),
          const SizedBox(height: 16),
          _buildCategoryCard(),
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
            en: 'Weekly Completion', ko: '주간 달성률', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
            translations: const {'JA': '週間達成率', 'ZH': '每周完成率', 'FR': "Taux d'achèvement hebdomadaire", 'DE': 'Wöchentliche Fertigstellung', 'RU': 'Недельный процент выполнения', 'AR': 'نسبة الإنجاز الأسبوعية', 'HI': 'साप्ताहिक पूर्णता दर', 'VI': 'Tỷ lệ hoàn thành hàng tuần', 'ES': 'Finalización semanal', 'TH': 'อัตราความสำเร็จรายสัปดาห์'},
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
              en: 'Goals Achieved This Week', ko: '이번 주 달성한 목표', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
              translations: const {'JA': '今週達成した目標', 'ZH': '本周达成目标', 'FR': 'Objectifs atteints cette semaine', 'DE': 'Diese Woche erreichte Ziele', 'RU': 'Цели, достигнутые на этой неделе', 'AR': 'الأهداف المحققة هذا الأسبوع', 'HI': 'इस सप्ताह हासिल किए गए लक्ष्य', 'VI': 'Mục tiêu đạt được tuần này', 'ES': 'Objetivos logrados esta semana', 'TH': 'เป้าหมายที่บรรลุสัปดาห์นี้'},
            ),
          ),
          Text('$_achievedGoalCount', style: const TextStyle(color: _brandGolden, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 🆕 [프로젝트 연동] 이번 주 완료된 프로젝트 개수
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
              en: 'Projects Completed This Week', ko: '이번 주 완료된 프로젝트', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
              translations: const {'JA': '今週完了したプロジェクト', 'ZH': '本周完成的项目', 'FR': 'Projets terminés cette semaine', 'DE': 'Diese Woche abgeschlossene Projekte', 'RU': 'Проекты, завершённые на этой неделе', 'AR': 'المشاريع المكتملة هذا الأسبوع', 'HI': 'इस सप्ताह पूर्ण की गई परियोजनाएं', 'VI': 'Dự án hoàn thành tuần này', 'ES': 'Proyectos completados esta semana', 'TH': 'โครงการที่เสร็จสัปดาห์นี้'},
            ),
          ),
          Text('$_completedProjectCount', style: const TextStyle(color: _brandGolden, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInsightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInsightRow(
            'Busiest Weekday', '가장 바쁜 요일', _busiestWeekday != null ? '$_busiestWeekday요일' : '데이터 없음',
            translations: const {'JA': '最も忙しい曜日', 'ZH': '最繁忙的星期', 'FR': 'Jour le plus chargé', 'DE': 'Geschäftigster Wochentag', 'RU': 'Самый загруженный день недели', 'AR': 'أكثر أيام الأسبوع ازدحامًا', 'HI': 'सबसे व्यस्त दिन', 'VI': 'Ngày bận rộn nhất', 'ES': 'Día más ocupado', 'TH': 'วันที่ยุ่งที่สุด'},
          ),
          const SizedBox(height: 10),
          _buildInsightRow(
            'Most Productive Time', '가장 생산적인 시간', _productiveHourRange ?? '데이터 없음',
            translations: const {'JA': '最も生産的な時間', 'ZH': '效率最高的时段', 'FR': 'Période la plus productive', 'DE': 'Produktivste Zeit', 'RU': 'Самое продуктивное время', 'AR': 'أكثر الأوقات إنتاجية', 'HI': 'सबसे उत्पादक समय', 'VI': 'Thời gian hiệu quả nhất', 'ES': 'Momento más productivo', 'TH': 'ช่วงเวลาที่มีประสิทธิผลที่สุด'},
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String en, String ko, String value, {Map<String, String>? translations}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: BiInline(en: en, ko: ko, color: Colors.white70, fontSize: 13, translations: translations)),
        Text(value, style: const TextStyle(color: _brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCategoryCard() {
    final categoryMinutes = _summary!.categoryMinutes;
    final entries = categoryMinutes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

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
        ],
      ),
    );
  }
}
