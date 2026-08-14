// ============================================================================
// 🆕 [일반 플래너 - 병기+연동 정리] YearlyReportScreen
// 올해의 목표 달성률, 총 일정 완료 수, 가장 생산적인 달, 가장 활동적인
// 요일, 올해 달성한 목표 개수를 보여줍니다. 실제 쌓인 데이터만으로
// 정직하게 계산합니다 (데이터 없으면 "데이터 없음").
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'report_data_service.dart';
import 'bilingual_text.dart';

class YearlyReportScreen extends StatefulWidget {
  const YearlyReportScreen({super.key});

  @override
  State<YearlyReportScreen> createState() => _YearlyReportScreenState();
}

class _YearlyReportScreenState extends State<YearlyReportScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  ReportSummary? _summary;
  int? _mostProductiveMonth;
  String? _mostActiveWeekday;
  int _achievedGoalCount = 0;
  int _completedProjectCount = 0; // 🆕 [프로젝트 연동]
  late DateTime _yearStart;
  late DateTime _yearEnd;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _yearStart = DateTime(now.year, 1, 1);
    _yearEnd = DateTime(now.year, 12, 31);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final summary = await ReportDataService.summarize(_yearStart, _yearEnd);
    final month = await ReportDataService.findMostProductiveMonth(_yearStart.year);
    final weekday = await ReportDataService.findMostActiveWeekdayOverall(_yearStart, _yearEnd);
    final projectCount = await ReportDataService.countProjectsCompletedInRange(_yearStart, _yearEnd);
    final achievedCount = await ReportDataService.countAchievementsInRange(_yearStart, _yearEnd);

    if (!mounted) return;
    setState(() {
      _summary = summary;
      _mostProductiveMonth = month;
      _mostActiveWeekday = weekday;
      _achievedGoalCount = achievedCount;
      _completedProjectCount = projectCount;
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
          en: 'YEARLY REPORT', ko: '연간 리포트', enSize: 16, koSize: 13,
          translations: const {'JA': '年次レポート', 'ZH': '年报', 'FR': 'Rapport annuel', 'DE': 'Jahresbericht', 'RU': 'Годовой отчёт', 'AR': 'التقرير السنوي', 'HI': 'वार्षिक रिपोर्ट', 'VI': 'Báo cáo hàng năm', 'ES': 'Informe anual', 'TH': 'รายงานรายปี'},
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : (_summary == null || !_summary!.hasData)
          ? Center(
        child: BiInline(
          en: 'No records for this year yet.', ko: '올해 등록된 기록이 없습니다.', color: Colors.white38, fontSize: 14, textAlign: TextAlign.center,
          translations: const {'JA': '今年の記録がまだありません。', 'ZH': '今年暂无记录。', 'FR': "Aucun enregistrement cette année pour l'instant.", 'DE': 'Noch keine Aufzeichnungen für dieses Jahr.', 'RU': 'Пока нет записей за этот год.', 'AR': 'لا توجد سجلات لهذا العام بعد.', 'HI': 'इस वर्ष के लिए अभी तक कोई रिकॉर्ड नहीं।', 'VI': 'Chưa có bản ghi nào cho năm này.', 'ES': 'Aún no hay registros para este año.', 'TH': 'ยังไม่มีบันทึกสำหรับปีนี้'},
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${_yearStart.year}', style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildCompletionCard(),
          const SizedBox(height: 16),
          _buildGoalAchievedCard(),
          const SizedBox(height: 16),
          _buildProjectCompletedCard(),
          const SizedBox(height: 16),
          _buildInsightCard(),
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
            en: "This Year's Completion", ko: '올해 목표 달성률', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
            translations: const {'JA': '今年の達成率', 'ZH': '今年完成率', 'FR': "Taux d'achèvement de cette année", 'DE': 'Dieses Jahr Fertigstellung', 'RU': 'Процент выполнения за этот год', 'AR': 'نسبة إنجاز هذا العام', 'HI': 'इस वर्ष की पूर्णता दर', 'VI': 'Tỷ lệ hoàn thành năm nay', 'ES': 'Finalización de este año', 'TH': 'อัตราความสำเร็จปีนี้'},
          ),
          const SizedBox(height: 8),
          Text('${s.completionPercent}%', style: GoogleFonts.rajdhani(color: _brandGolden, fontSize: 36, fontWeight: FontWeight.bold)),
          BiInline(
            en: 'Total ${s.totalCount} · Completed ${s.completedCount}', ko: '총 일정 ${s.totalCount}개 · 완료 ${s.completedCount}개', color: Colors.white38, fontSize: 12,
            translations: {
              'JA': '合計 ${s.totalCount} · 完了 ${s.completedCount}', 'ZH': '总计 ${s.totalCount} · 完成 ${s.completedCount}', 'FR': 'Total ${s.totalCount} · Terminé ${s.completedCount}', 'DE': 'Gesamt ${s.totalCount} · Erledigt ${s.completedCount}',
              'RU': 'Всего ${s.totalCount} · Выполнено ${s.completedCount}', 'AR': 'الإجمالي ${s.totalCount} · مكتمل ${s.completedCount}', 'HI': 'कुल ${s.totalCount} · पूर्ण ${s.completedCount}', 'VI': 'Tổng ${s.totalCount} · Hoàn thành ${s.completedCount}',
              'ES': 'Total ${s.totalCount} · Completado ${s.completedCount}', 'TH': 'ทั้งหมด ${s.totalCount} · เสร็จ ${s.completedCount}',
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
              en: 'Goals Achieved This Year', ko: '올해 달성한 목표', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
              translations: const {'JA': '今年達成した目標', 'ZH': '今年达成目标', 'FR': 'Objectifs atteints cette année', 'DE': 'Dieses Jahr erreichte Ziele', 'RU': 'Цели, достигнутые в этом году', 'AR': 'الأهداف المحققة هذا العام', 'HI': 'इस वर्ष हासिल किए गए लक्ष्य', 'VI': 'Mục tiêu đạt được năm nay', 'ES': 'Objetivos logrados este año', 'TH': 'เป้าหมายที่บรรลุปีนี้'},
            ),
          ),
          Text('$_achievedGoalCount', style: const TextStyle(color: _brandGolden, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 🆕 [프로젝트 연동] 올해 완료된 프로젝트 개수
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
              en: 'Projects Completed This Year', ko: '올해 완료된 프로젝트', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
              translations: const {'JA': '今年完了したプロジェクト', 'ZH': '今年完成的项目', 'FR': 'Projets terminés cette année', 'DE': 'Dieses Jahr abgeschlossene Projekte', 'RU': 'Проекты, завершённые в этом году', 'AR': 'المشاريع المكتملة هذا العام', 'HI': 'इस वर्ष पूर्ण की गई परियोजनाएं', 'VI': 'Dự án hoàn thành năm nay', 'ES': 'Proyectos completados este año', 'TH': 'โครงการที่เสร็จปีนี้'},
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
          _buildRow(
            'Most Productive Month', '가장 생산적인 달', _mostProductiveMonth != null ? '${_mostProductiveMonth}월' : '데이터 없음',
            translations: const {'JA': '最も生産的な月', 'ZH': '效率最高的月份', 'FR': 'Mois le plus productif', 'DE': 'Produktivster Monat', 'RU': 'Самый продуктивный месяц', 'AR': 'أكثر الأشهر إنتاجية', 'HI': 'सबसे उत्पादक महीना', 'VI': 'Tháng hiệu quả nhất', 'ES': 'Mes más productivo', 'TH': 'เดือนที่มีประสิทธิผลที่สุด'},
          ),
          const SizedBox(height: 10),
          _buildRow(
            'Most Active Weekday', '가장 많이 활동한 요일', _mostActiveWeekday != null ? '$_mostActiveWeekday요일' : '데이터 없음',
            translations: const {'JA': '最も活動的な曜日', 'ZH': '最活跃的星期', 'FR': 'Jour le plus actif', 'DE': 'Aktivster Wochentag', 'RU': 'Самый активный день недели', 'AR': 'أكثر أيام الأسبوع نشاطًا', 'HI': 'सबसे सक्रिय दिन', 'VI': 'Ngày hoạt động nhiều nhất', 'ES': 'Día más activo', 'TH': 'วันที่กระตือรือร้นที่สุด'},
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String en, String ko, String value, {Map<String, String>? translations}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: BiInline(en: en, ko: ko, color: Colors.white70, fontSize: 13, translations: translations)),
        Text(value, style: const TextStyle(color: _brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
