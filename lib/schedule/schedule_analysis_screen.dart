// ============================================================================
// 🆕 [일반 플래너] ScheduleAnalysisScreen (일정분석)
// 캘린더/오늘의 일정에 저장된 실제 ScheduleItem 데이터를 분석합니다.
// 전체 완료율, 카테고리별(중요/회사/개인) 분포, 다가오는 미완료 일정 개수,
// 가장 일정이 많은 요일을 계산합니다. 전부 실제 데이터 기반이며, 데이터가
// 없으면 가짜 숫자 대신 "데이터 없음"으로 표시합니다.
//
// ✅ [2026-09-04 추가] 운동(EXERCISE) 연동.
// - 활동 유형별 비중을 도넛차트(일정/약속/운동, 골드·실버·브론즈 톤)로 표시
// - 요일별 전체 활동량을 막대그래프로 표시 (일정+약속+운동 합산)
// - "가장 활동이 많은 요일" 인사이트도 운동까지 포함해 계산하도록 확장
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'schedule_data_service.dart';
import 'appointment_data_service.dart'; // 🆕 [약속 연동] 리포트와 동일하게 일정분석에도 약속 데이터 포함
import 'calendar_screen.dart' show categoryColorOf, kScheduleCategories; // 🆕 캘린더와 동일한 카테고리 색상 재사용
import 'bilingual_text.dart';
import 'exercise_data_service.dart'; // 🆕 [운동 연동]
import 'exercise_models.dart'; // 🆕 [운동 연동]

class ScheduleAnalysisScreen extends StatefulWidget {
  const ScheduleAnalysisScreen({super.key});

  @override
  State<ScheduleAnalysisScreen> createState() => _ScheduleAnalysisScreenState();
}

class _ScheduleAnalysisScreenState extends State<ScheduleAnalysisScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  // 🆕 [운동 연동] 도넛차트용 골드/실버/브론즈 3색 팔레트 - 앱의 골드 톤과 어울리는 "메달" 색상
  static const Color _silverTone = Color(0xFFC7CDD6);
  static const Color _bronzeTone = Color(0xFFCD7F32);

  List<ScheduleItem> _all = [];
  List<AppointmentItem> _allAppointments = []; // 🆕 [약속 연동]
  List<ExerciseRecord> _allExercises = []; // 🆕 [운동 연동]
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
    final allExercises = await ExerciseDataService.instance.getAllRecords(); // 🆕 [운동 연동]
    if (!mounted) return;
    setState(() {
      _all = all;
      _allAppointments = allAppointments;
      _allExercises = allExercises; // 🆕 [운동 연동]
      _isLoading = false;
    });
  }

  // 🆕 [약속 연동] 일정+약속을 합쳐서 완료율 계산 (리포트 화면과 동일한 방식)
  // 운동은 "완료/미완료" 개념이 없는 실행 기록이므로 완료율 계산에서는 제외하고,
  // 아래 도넛차트/막대그래프에서 별도로 반영한다.
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

  // 🆕 [운동 연동] 요일별 전체 활동량(일정+약속+운동 합산) 집계.
  // 문자열 날짜(yyyy-mm-dd)와 ExerciseRecord.date(DateTime)를 함께 처리.
  Map<int, int> get _weekdayCounts {
    final Map<int, int> counts = {};
    void addDateStr(String dateStr) {
      final parts = dateStr.split('-');
      if (parts.length != 3) return;
      try {
        final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        counts[d.weekday] = (counts[d.weekday] ?? 0) + 1;
      } catch (e) {
        // 파싱 실패한 날짜는 건너뜀
      }
    }

    for (final item in _all) {
      addDateStr(item.date);
    }
    for (final a in _allAppointments) {
      addDateStr(a.date);
    }
    for (final r in _allExercises) {
      counts[r.date.weekday] = (counts[r.date.weekday] ?? 0) + 1;
    }
    return counts;
  }

  // 🆕 [운동 연동] "가장 바쁜 요일"도 일정+약속+운동 전체 활동 기준으로 계산하도록 확장.
  String? get _busiestWeekday {
    final counts = _weekdayCounts;
    if (counts.isEmpty) return null;
    const weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final busiest = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return weekdayNames[busiest.key - 1];
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAnyData = _all.isNotEmpty || _allAppointments.isNotEmpty || _allExercises.isNotEmpty;

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
          : !hasAnyData
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
          _buildActivityDonutCard(), // 🆕 [운동 연동] 도넛차트
          const SizedBox(height: 16),
          _buildWeekdayBarChartCard(), // 🆕 [운동 연동] 막대그래프
          const SizedBox(height: 16),
          if (_categoryCounts.isNotEmpty) ...[
            _buildCategoryCard(),
            const SizedBox(height: 16),
          ],
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

  // 🆕 [운동 연동] 일정/약속/운동 세 유형의 비중을 골드·실버·브론즈 톤 도넛차트로 표시.
  Widget _buildActivityDonutCard() {
    final int scheduleCount = _all.length;
    final int appointmentCount = _allAppointments.length;
    final int exerciseCount = _allExercises.length;
    final int total = scheduleCount + appointmentCount + exerciseCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BiInline(
            en: 'By Activity Type', ko: '활동 유형별 비중', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
            translations: const {'JA': 'アクティビティ種類別', 'ZH': '按活动类型', 'FR': "Par type d'activité", 'DE': 'Nach Aktivitätstyp', 'RU': 'По типу активности', 'AR': 'حسب نوع النشاط', 'HI': 'गतिविधि प्रकार अनुसार', 'VI': 'Theo loại hoạt động', 'ES': 'Por tipo de actividad', 'TH': 'ตามประเภทกิจกรรม'},
          ),
          const SizedBox(height: 14),
          if (total == 0)
            BiInline(en: 'No data', ko: '데이터 없음', color: Colors.white38, fontSize: 12)
          else
            Row(
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 38,
                      sections: [
                        if (scheduleCount > 0)
                          PieChartSectionData(
                            value: scheduleCount.toDouble(),
                            color: _brandGolden,
                            title: '',
                            radius: 26,
                          ),
                        if (appointmentCount > 0)
                          PieChartSectionData(
                            value: appointmentCount.toDouble(),
                            color: _silverTone,
                            title: '',
                            radius: 26,
                          ),
                        if (exerciseCount > 0)
                          PieChartSectionData(
                            value: exerciseCount.toDouble(),
                            color: _bronzeTone,
                            title: '',
                            radius: 26,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDonutLegendRow(_brandGolden, 'Schedule', '일정', scheduleCount, total),
                      const SizedBox(height: 10),
                      _buildDonutLegendRow(_silverTone, 'Appointment', '약속', appointmentCount, total),
                      const SizedBox(height: 10),
                      _buildDonutLegendRow(_bronzeTone, 'Exercise', '운동', exerciseCount, total),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDonutLegendRow(Color color, String en, String ko, int count, int total) {
    final int pct = total == 0 ? 0 : ((count / total) * 100).round();
    return Row(
      children: [
        Container(width: 11, height: 11, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(child: BiInline(en: en, ko: ko, color: Colors.white, fontSize: 12.5)),
        Text('$count · $pct%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // 🆕 [운동 연동] 요일별 전체 활동량(일정+약속+운동 합산) 막대그래프.
  Widget _buildWeekdayBarChartCard() {
    final counts = _weekdayCounts;
    const weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    final values = List.generate(7, (i) => (counts[i + 1] ?? 0).toDouble());
    final double maxVal = values.isEmpty ? 5 : (values.reduce((a, b) => a > b ? a : b) * 1.25).clamp(3, 100000);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BiInline(
            en: 'Activity by Weekday', ko: '요일별 활동량', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
            translations: const {'JA': '曜日別アクティビティ', 'ZH': '按星期活动量', 'FR': 'Activité par jour', 'DE': 'Aktivität nach Wochentag', 'RU': 'Активность по дням недели', 'AR': 'النشاط حسب اليوم', 'HI': 'सप्ताह के दिन अनुसार गतिविधि', 'VI': 'Hoạt động theo ngày trong tuần', 'ES': 'Actividad por día', 'TH': 'กิจกรรมตามวัน'},
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: counts.isEmpty
                ? Center(child: BiInline(en: 'No data', ko: '데이터 없음', color: Colors.white38, fontSize: 12))
                : BarChart(
              BarChartData(
                maxY: maxVal.toDouble(),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= weekdayLabels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(weekdayLabels[idx], style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(7, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: values[i],
                        color: _brandGolden,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxVal.toDouble(),
                          color: Colors.white.withOpacity(0.04),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
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
    // 🆕 [운동 연동] 운동 총 시간도 인사이트에 추가
    final int exerciseTotalMinutes = _allExercises.fold<int>(0, (sum, r) => sum + r.durationMin);

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
            'Busiest Weekday', '가장 활동이 많은 요일', _busiestWeekday != null ? '$_busiestWeekday요일' : '데이터 없음',
            translations: const {'JA': '最も忙しい曜日', 'ZH': '最繁忙的星期', 'FR': 'Jour le plus chargé', 'DE': 'Geschäftigster Wochentag', 'RU': 'Самый загруженный день недели', 'AR': 'أكثر أيام الأسبوع ازدحامًا', 'HI': 'सबसे व्यस्त दिन', 'VI': 'Ngày bận rộn nhất', 'ES': 'Día más ocupado', 'TH': 'วันที่ยุ่งที่สุด'},
          ),
          if (exerciseTotalMinutes > 0) ...[
            const SizedBox(height: 10),
            _buildInsightRow(
              'Total Exercise Time', '누적 운동시간', '$exerciseTotalMinutes분',
              translations: const {'JA': '累計運動時間', 'ZH': '累计运动时间', 'FR': "Temps d'exercice total", 'DE': 'Gesamte Trainingszeit', 'RU': 'Общее время тренировок', 'AR': 'إجمالي وقت التمرين', 'HI': 'कुल व्यायाम समय', 'VI': 'Tổng thời gian tập', 'ES': 'Tiempo total de ejercicio', 'TH': 'เวลาออกกำลังกายรวม'},
            ),
          ],
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
