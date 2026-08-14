// ============================================================================
// 🆕 [일반 플래너] ScheduleAnalysisScreen (일정분석)
// 캘린더/오늘의 일정에 저장된 실제 ScheduleItem 데이터를 분석합니다.
// 전체 완료율, 카테고리별(중요/회사/개인) 분포, 다가오는 미완료 일정 개수,
// 가장 일정이 많은 요일을 계산합니다. 전부 실제 데이터 기반이며, 데이터가
// 없으면 가짜 숫자 대신 "데이터 없음"으로 표시합니다.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'schedule_data_service.dart';
import 'appointment_data_service.dart'; // 🆕 [약속 연동] 리포트와 동일하게 일정분석에도 약속 데이터 포함
import 'calendar_screen.dart' show categoryColorOf, kScheduleCategories; // 🆕 캘린더와 동일한 카테고리 색상 재사용
import 'bilingual_text.dart';

class ScheduleAnalysisScreen extends StatefulWidget {
  const ScheduleAnalysisScreen({super.key});

  @override
  State<ScheduleAnalysisScreen> createState() => _ScheduleAnalysisScreenState();
}

class _ScheduleAnalysisScreenState extends State<ScheduleAnalysisScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  List<ScheduleItem> _all = [];
  List<AppointmentItem> _allAppointments = []; // 🆕 [약속 연동]
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final all = await ScheduleDataService.loadAll();
    final allAppointments = await AppointmentDataService.loadAll(); // 🆕 [약속 연동]
    if (!mounted) return;
    setState(() {
      _all = all;
      _allAppointments = allAppointments;
      _isLoading = false;
    });
  }

  // 🆕 [약속 연동] 일정+약속을 합쳐서 완료율 계산 (리포트 화면과 동일한 방식)
  int get _totalCount => _all.length + _allAppointments.length;
  int get _completedCount => _all.where((e) => e.isCompleted).length + _allAppointments.where((a) => a.isCompleted).length;
  double get _completionRate => _totalCount == 0 ? 0 : _completedCount / _totalCount;

  Map<String, int> get _categoryCounts {
    final Map<String, int> result = {};
    for (final item in _all) {
      result[item.category] = (result[item.category] ?? 0) + 1;
    }
    return result;
  }

  int get _upcomingIncompleteCount {
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return _all.where((e) => !e.isCompleted && e.date.compareTo(todayKey) >= 0).length;
  }

  String? get _busiestWeekday {
    if (_all.isEmpty) return null;
    const weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final Map<int, int> countByWeekday = {};
    for (final item in _all) {
      final parts = item.date.split('-');
      if (parts.length != 3) continue;
      try {
        final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        countByWeekday[date.weekday] = (countByWeekday[date.weekday] ?? 0) + 1;
      } catch (e) {
        continue;
      }
    }
    if (countByWeekday.isEmpty) return null;
    final busiest = countByWeekday.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return weekdayNames[busiest.key - 1];
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
          en: 'SCHEDULE ANALYSIS', ko: '일정 분석', enSize: 17, koSize: 13,
          translations: const {'JA': 'スケジュール分析', 'ZH': '日程分析', 'FR': 'Analyse du planning', 'DE': 'Zeitplananalyse', 'RU': 'Анализ расписания', 'AR': 'تحليل الجدول', 'HI': 'शेड्यूल विश्लेषण', 'VI': 'Phân tích lịch trình', 'ES': 'Análisis de horario', 'TH': 'วิเคราะห์ตารางเวลา'},
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : _all.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BiInline(
            en: 'No schedule data yet', ko: '아직 분석할 일정 데이터가 없습니다', color: Colors.white38, fontSize: 14, textAlign: TextAlign.center,
            translations: const {'JA': 'まだ分析する予定データがありません', 'ZH': '暂无可分析的日程数据', 'FR': 'Aucune donnée de programme à analyser', 'DE': 'Noch keine Termindaten zur Analyse', 'RU': 'Пока нет данных расписания для анализа', 'AR': 'لا توجد بيانات جدول للتحليل بعد', 'HI': 'अभी विश्लेषण के लिए कोई शेड्यूल डेटा नहीं', 'VI': 'Chưa có dữ liệu lịch trình để phân tích', 'ES': 'Aún no hay datos de horario para analizar', 'TH': 'ยังไม่มีข้อมูลตารางเวลาให้วิเคราะห์'},
          ),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOverallCard(),
          const SizedBox(height: 16),
          _buildCategoryCard(),
          const SizedBox(height: 16),
          _buildInsightCard(),
        ],
      ),
    );
  }

  Widget _buildOverallCard() {
    final int percent = (_completionRate * 100).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BiInline(
            en: 'Overall Completion', ko: '전체 완료율', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
            translations: const {'JA': '全体達成率', 'ZH': '总完成率', 'FR': "Taux d'achèvement global", 'DE': 'Gesamtfertigstellung', 'RU': 'Общий процент выполнения', 'AR': 'نسبة الإنجاز الكلية', 'HI': 'कुल पूर्णता दर', 'VI': 'Tỷ lệ hoàn thành tổng thể', 'ES': 'Finalización general', 'TH': 'อัตราความสำเร็จโดยรวม'},
          ),
          const SizedBox(height: 8),
          Text('$percent%', style: GoogleFonts.rajdhani(color: _brandGolden, fontSize: 36, fontWeight: FontWeight.bold)),
          BiInline(
            en: 'Completed $_completedCount / Total $_totalCount', ko: '완료 $_completedCount건 / 전체 $_totalCount건', color: Colors.white38, fontSize: 12,
            translations: {
              'JA': '完了 $_completedCount / 全体 $_totalCount',
              'ZH': '完成 $_completedCount / 总计 $_totalCount',
              'FR': 'Terminé $_completedCount / Total $_totalCount',
              'DE': 'Erledigt $_completedCount / Gesamt $_totalCount',
              'RU': 'Выполнено $_completedCount / Всего $_totalCount',
              'AR': 'مكتمل $_completedCount / الإجمالي $_totalCount',
              'HI': 'पूर्ण $_completedCount / कुल $_totalCount',
              'VI': 'Hoàn thành $_completedCount / Tổng $_totalCount',
              'ES': 'Completado $_completedCount / Total $_totalCount',
              'TH': 'เสร็จ $_completedCount / ทั้งหมด $_totalCount',
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard() {
    final counts = _categoryCounts;
    final int total = counts.values.fold(0, (a, b) => a + b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BiInline(
            en: 'By Category', ko: '분류별 비중', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
            translations: const {'JA': 'カテゴリー別', 'ZH': '按分类', 'FR': 'Par catégorie', 'DE': 'Nach Kategorie', 'RU': 'По категориям', 'AR': 'حسب الفئة', 'HI': 'श्रेणी अनुसार', 'VI': 'Theo danh mục', 'ES': 'Por categoría', 'TH': 'ตามหมวดหมู่'},
          ),
          const SizedBox(height: 14),
          if (total == 0)
            BiInline(en: 'No data', ko: '데이터 없음', color: Colors.white38, fontSize: 12, translations: commonButtonTranslations['No data'])
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 22,
                child: Row(
                  children: counts.entries.map((e) {
                    final double flexValue = e.value / total;
                    return Expanded(
                      flex: (flexValue * 1000).round().clamp(1, 1000),
                      child: Container(color: categoryColorOf(e.key)),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...counts.entries.map((e) {
              final int pct = ((e.value / total) * 100).round();
              final matched = kScheduleCategories.where((c) => c.koLabel == e.key).toList();
              final String enName = matched.isNotEmpty ? matched.first.enLabel : 'Other';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: categoryColorOf(e.key), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Expanded(child: BiInline(en: enName, ko: e.key, color: Colors.white, fontSize: 13)),
                    Text('${e.value}건 ($pct%)', style: const TextStyle(color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInsightRow(
            'Upcoming Incomplete', '다가오는 미완료 일정', '$_upcomingIncompleteCount건',
            translations: const {'JA': '今後の未完了予定', 'ZH': '即将到来的未完成日程', 'FR': 'Programmes incomplets à venir', 'DE': 'Bevorstehende unerledigte Termine', 'RU': 'Предстоящие невыполненные события', 'AR': 'المواعيد القادمة غير المكتملة', 'HI': 'आगामी अपूर्ण शेड्यूल', 'VI': 'Lịch trình sắp tới chưa hoàn thành', 'ES': 'Próximos horarios incompletos', 'TH': 'ตารางเวลาที่ยังไม่เสร็จที่จะมาถึง'},
          ),
          const SizedBox(height: 10),
          _buildInsightRow(
            'Busiest Weekday', '가장 일정이 많은 요일', _busiestWeekday != null ? '$_busiestWeekday요일' : '데이터 없음',
            translations: const {'JA': '最も忙しい曜日', 'ZH': '最繁忙的星期', 'FR': 'Jour le plus chargé', 'DE': 'Geschäftigster Wochentag', 'RU': 'Самый загруженный день недели', 'AR': 'أكثر أيام الأسبوع ازدحامًا', 'HI': 'सबसे व्यस्त दिन', 'VI': 'Ngày bận rộn nhất', 'ES': 'Día más ocupado', 'TH': 'วันที่ยุ่งที่สุด'},
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
}
