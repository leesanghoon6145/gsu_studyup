import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../global_lang.dart'; // 👑 [12개국 연동] 전역 언어 스위치와 연결

/// ============================================================================
/// [GKE StudyUp] 자기주도 학습 플래너 — 리포트 스크린 (report_screen.dart)
/// 계획 탭에서 등록한 일정(gke_global_schedules)의 "완료(completed)" 체크 데이터를 그대로
/// 가져와서, 학교/학원/시험/개인 카테고리별 실행률을 도넛+막대 그래프로 보여줌.
/// 과목별 성적이 아니라 "계획한 일정을 얼마나 실행했는가"에 집중한 리포트임.
/// ============================================================================
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => ReportScreenState();
}

class ReportScreenState extends State<ReportScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final Color schoolColor = const Color(0xFF3B82F6);
  final Color academyColor = const Color(0xFFFACC15);
  final Color examColor = const Color(0xFFEF4444);
  final Color personalColor = const Color(0xFF8B5CF6);
  // 🆕 [2026-08-18] 원장님 지시: 도넛 차트 3색 통일 - 계획(노랑)/완료(초록)/미완료(빨강)
  final Color plannedColor = const Color(0xFFFACC15);
  final Color completedColor = const Color(0xFF22C55E);
  final Color incompleteColor = const Color(0xFFEF4444);
  final Color goldColor = const Color(0xFFD4AF37);
  final Color slate300 = const Color(0xFFCBD5E1);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color slate500 = const Color(0xFF64748B);
  final Color slate800 = const Color(0xFF1E293B);

  List<Map<String, dynamic>> _globalSchedules = [];
  bool _loaded = false;
  // 'week' | 'month' | 'all'
  String _period = 'week';

  // ============================================================================
  // 🆕 [12개국 언어 시스템]
  // ============================================================================
  static const List<String> _foreignLanguages = ['JA', 'ZH', 'FR', 'DE', 'RU', 'AR', 'HI', 'VI', 'ES', 'TH'];
  static bool get _isForeignSelected => _foreignLanguages.contains(DkeLang.current);

  static const Map<String, Map<String, String>> _uiText = {
    'reportSectionTitle': {'KO': '실행 리포트', 'EN': 'Execution Report', 'JA': '実行レポート', 'ZH': '执行报告', 'FR': 'Rapport d\'exécution', 'DE': 'Ausführungsbericht', 'RU': 'Отчёт о выполнении', 'AR': 'تقرير التنفيذ', 'HI': 'निष्पादन रिपोर्ट', 'VI': 'Báo cáo thực hiện', 'ES': 'Informe de ejecución', 'TH': 'รายงานการดำเนินการ'},
    'periodWeek': {'KO': '이번 주', 'EN': 'This Week', 'JA': '今週', 'ZH': '本周', 'FR': 'Cette semaine', 'DE': 'Diese Woche', 'RU': 'Эта неделя', 'AR': 'هذا الأسبوع', 'HI': 'यह सप्ताह', 'VI': 'Tuần này', 'ES': 'Esta semana', 'TH': 'สัปดาห์นี้'},
    'periodMonth': {'KO': '이번 달', 'EN': 'This Month', 'JA': '今月', 'ZH': '本月', 'FR': 'Ce mois-ci', 'DE': 'Diesen Monat', 'RU': 'Этот месяц', 'AR': 'هذا الشهر', 'HI': 'इस महीने', 'VI': 'Tháng này', 'ES': 'Este mes', 'TH': 'เดือนนี้'},
    'periodAll': {'KO': '전체', 'EN': 'All Time', 'JA': '全期間', 'ZH': '全部', 'FR': 'Tout', 'DE': 'Gesamt', 'RU': 'Всё время', 'AR': 'الكل', 'HI': 'सभी', 'VI': 'Tất cả', 'ES': 'Todo', 'TH': 'ทั้งหมด'},
    'executionRateLabel': {'KO': '전체 실행률', 'EN': 'Overall Execution Rate', 'JA': '全体実行率', 'ZH': '整体执行率', 'FR': 'Taux d\'exécution global', 'DE': 'Gesamtausführungsrate', 'RU': 'Общий процент выполнения', 'AR': 'معدل التنفيذ الإجمالي', 'HI': 'कुल निष्पादन दर', 'VI': 'Tỷ lệ thực hiện tổng thể', 'ES': 'Tasa de ejecución general', 'TH': 'อัตราการดำเนินการโดยรวม'},
    'plannedLabel': {'KO': '계획', 'EN': 'Planned', 'JA': '計画', 'ZH': '计划', 'FR': 'Prévu', 'DE': 'Geplant', 'RU': 'Запланировано', 'AR': 'المخطط', 'HI': 'योजनाबद्ध', 'VI': 'Đã lên kế hoạch', 'ES': 'Planificado', 'TH': 'วางแผนไว้'},
    'completedLabel': {'KO': '완료', 'EN': 'Completed', 'JA': '完了', 'ZH': '已完成', 'FR': 'Terminé', 'DE': 'Abgeschlossen', 'RU': 'Выполнено', 'AR': 'مكتمل', 'HI': 'पूर्ण', 'VI': 'Hoàn thành', 'ES': 'Completado', 'TH': 'เสร็จสิ้น'},
    'incompleteLabel': {'KO': '미완료', 'EN': 'Incomplete', 'JA': '未完了', 'ZH': '未完成', 'FR': 'Incomplet', 'DE': 'Nicht abgeschlossen', 'RU': 'Не выполнено', 'AR': 'غير مكتمل', 'HI': 'अपूर्ण', 'VI': 'Chưa hoàn thành', 'ES': 'Incompleto', 'TH': 'ยังไม่เสร็จ'},
    'categoryBreakdownTitle': {'KO': '분류별 실행 현황', 'EN': 'Execution by Category', 'JA': '分類別実行状況', 'ZH': '分类执行情况', 'FR': 'Exécution par catégorie', 'DE': 'Ausführung nach Kategorie', 'RU': 'Выполнение по категориям', 'AR': 'التنفيذ حسب الفئة', 'HI': 'श्रेणी अनुसार निष्पादन', 'VI': 'Thực hiện theo danh mục', 'ES': 'Ejecución por categoría', 'TH': 'การดำเนินการตามหมวดหมู่'},
    'emptyReport': {'KO': '이 기간에 등록된 일정이 없습니다.', 'EN': 'No schedules registered for this period.', 'JA': 'この期間に登録された日程がありません。', 'ZH': '该时段暂无已登记的日程。', 'FR': 'Aucun programme enregistré pour cette période.', 'DE': 'Kein Termin für diesen Zeitraum registriert.', 'RU': 'На этот период расписание не добавлено.', 'AR': 'لا يوجد جدول مسجل لهذه الفترة.', 'HI': 'इस अवधि के लिए कोई कार्यक्रम दर्ज नहीं है।', 'VI': 'Chưa có lịch nào được đăng ký cho giai đoạn này.', 'ES': 'No hay horario registrado para este período.', 'TH': 'ไม่มีตารางที่ลงทะเบียนไว้สำหรับช่วงเวลานี้'},
    'catSchool': {'KO': '학교', 'EN': 'School', 'JA': '学校', 'ZH': '学校', 'FR': 'École', 'DE': 'Schule', 'RU': 'Школа', 'AR': 'المدرسة', 'HI': 'स्कूल', 'VI': 'Trường học', 'ES': 'Escuela', 'TH': 'โรงเรียน'},
    'catAcademy': {'KO': '학원', 'EN': 'Academy', 'JA': '塾', 'ZH': '补习班', 'FR': 'Institut', 'DE': 'Institut', 'RU': 'Академия', 'AR': 'المعهد', 'HI': 'अकादमी', 'VI': 'Trung tâm', 'ES': 'Academia', 'TH': 'สถาบันกวดวิชา'},
    'catExam': {'KO': '시험', 'EN': 'Exam', 'JA': '試験', 'ZH': '考试', 'FR': 'Examen', 'DE': 'Prüfung', 'RU': 'Экзамен', 'AR': 'الاختبار', 'HI': 'परीक्षा', 'VI': 'Kỳ thi', 'ES': 'Examen', 'TH': 'ข้อสอบ'},
    'catPersonal': {'KO': '개인', 'EN': 'Personal', 'JA': '個人', 'ZH': '个人', 'FR': 'Personnel', 'DE': 'Persönlich', 'RU': 'Личное', 'AR': 'شخصي', 'HI': 'व्यक्तिगत', 'VI': 'Cá nhân', 'ES': 'Personal', 'TH': 'ส่วนตัว'},
    'bestCategoryLabel': {'KO': '가장 잘 지킨 분류', 'EN': 'Best Kept Category', 'JA': '最も守れた分類', 'ZH': '执行最好的分类', 'FR': 'Catégorie la mieux respectée', 'DE': 'Am besten eingehaltene Kategorie', 'RU': 'Лучшая категория', 'AR': 'أفضل فئة تم الالتزام بها', 'HI': 'सबसे अच्छी तरह पालन की गई श्रेणी', 'VI': 'Danh mục thực hiện tốt nhất', 'ES': 'Categoría mejor cumplida', 'TH': 'หมวดหมู่ที่ทำได้ดีที่สุด'},
    'noDataYet': {'KO': '아직 데이터가 부족합니다.', 'EN': 'Not enough data yet.', 'JA': 'まだデータが不足しています。', 'ZH': '数据尚不充足。', 'FR': 'Pas encore assez de données.', 'DE': 'Noch nicht genug Daten.', 'RU': 'Пока недостаточно данных.', 'AR': 'لا توجد بيانات كافية بعد.', 'HI': 'अभी पर्याप्त डेटा नहीं है।', 'VI': 'Chưa đủ dữ liệu.', 'ES': 'Aún no hay suficientes datos.', 'TH': 'ยังมีข้อมูลไม่เพียงพอ'},
  };

  static String _t(String key) {
    final map = _uiText[key];
    if (map == null) return key;
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? key;
  }

  static String _biStr(String key) {
    final map = _uiText[key];
    if (map == null) return key;
    if (_isForeignSelected) {
      return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? key;
    }
    return '${map['EN'] ?? ''} / ${map['KO'] ?? ''}';
  }

  static Widget _biTitle(
      String key, {
        required TextStyle enStyle,
        required TextStyle koStyle,
        TextStyle? foreignStyle,
      }) {
    final map = _uiText[key] ?? {'EN': key, 'KO': key};
    if (_isForeignSelected) {
      return Text(
        map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? key,
        style: foreignStyle ?? koStyle,
        overflow: TextOverflow.fade,
        softWrap: false,
        maxLines: 1,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(map['EN'] ?? '', style: enStyle, overflow: TextOverflow.fade, softWrap: false, maxLines: 1),
        Text(map['KO'] ?? '', style: koStyle, overflow: TextOverflow.fade, softWrap: false, maxLines: 1),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  // 🆕 [버그 수정 2026-08-18] 계획 탭에서 "완료 체크"를 눌러도 리포트 탭이 반영 안 되던 문제 수정.
  // 이 화면은 AutomaticKeepAliveClientMixin으로 항상 살아있어서 initState()가 딱 한 번만 실행되고,
  // 탭을 다시 봐도 자동으로 새로고침되지 않았음. main_self_learning_planner_screen.dart가 리포트
  // 탭으로 돌아올 때 이 공개 메서드를 호출해서 최신 데이터를 다시 불러오게 함(계획/실행 탭이 이미
  // 쓰고 있던 refreshFromExternalChanges()와 동일한 이름·원리로 통일함).
  Future<void> refreshFromExternalChanges() async {
    await _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString('gke_global_schedules');
      List<Map<String, dynamic>> list = [];
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        list = decoded.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          if (map['color'] is int) {
            map['color'] = Color(map['color'] as int);
          }
          return map;
        }).toList();
      }
      if (mounted) {
        setState(() {
          _globalSchedules = list;
          _loaded = true;
        });
      }
    } catch (e) {
      debugPrint('[ReportScreen] 일정 로드 실패: $e');
      if (mounted) setState(() => _loaded = true);
    }
  }

  // 🆕 계획 탭이 'category' 문자열 필드 없이 'color'만 저장하므로, 색상 값으로 카테고리를 역추적함
  // (다른 화면들의 기존 매칭 방식과 동일한 규칙).
  String _categoryOf(Map<String, dynamic> item) {
    final Color? c = item['color'] is Color ? item['color'] as Color : null;
    if (c == null) return '학교';
    if (c.toARGB32() == academyColor.toARGB32()) return '학원';
    if (c.toARGB32() == examColor.toARGB32()) return '시험';
    if (c.toARGB32() == personalColor.toARGB32()) return '개인';
    return '학교';
  }

  Color _categoryColorFor(String catValue) {
    switch (catValue) {
      case '학원':
        return academyColor;
      case '시험':
        return examColor;
      case '개인':
        return personalColor;
      default:
        return schoolColor;
    }
  }

  String _categoryLabelKey(String catValue) {
    switch (catValue) {
      case '학원':
        return 'catAcademy';
      case '시험':
        return 'catExam';
      case '개인':
        return 'catPersonal';
      default:
        return 'catSchool';
    }
  }

  DateTime _computeWeekStart(DateTime date) {
    final DateTime dayOnly = DateTime(date.year, date.month, date.day);
    return dayOnly.subtract(Duration(days: dayOnly.weekday % 7));
  }

  List<Map<String, dynamic>> get _filteredSchedules {
    if (_period == 'all') return _globalSchedules;

    final DateTime now = DateTime.now();
    if (_period == 'month') {
      return _globalSchedules.where((s) => s['year'] == now.year && s['month'] == now.month).toList();
    }
    // week
    final DateTime weekStart = _computeWeekStart(now);
    final DateTime weekEnd = weekStart.add(const Duration(days: 6));
    return _globalSchedules.where((s) {
      final DateTime d = DateTime(s['year'] as int, s['month'] as int, s['day'] as int);
      return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    }

    final List<Map<String, dynamic>> items = _filteredSchedules;
    final int total = items.length;
    final int completed = items.where((s) => s['completed'] == true).length;
    final double rate = total == 0 ? 0.0 : completed / total;

    // 카테고리별 집계
    final List<String> categories = ['학교', '학원', '시험', '개인'];
    final Map<String, int> catTotal = {for (final c in categories) c: 0};
    final Map<String, int> catCompleted = {for (final c in categories) c: 0};
    for (final item in items) {
      final String cat = _categoryOf(item);
      catTotal[cat] = (catTotal[cat] ?? 0) + 1;
      if (item['completed'] == true) {
        catCompleted[cat] = (catCompleted[cat] ?? 0) + 1;
      }
    }

    // 가장 잘 지킨 분류 (계획이 1건 이상 있는 것 중 실행률 최고)
    String? bestCat;
    double bestRate = -1;
    for (final c in categories) {
      final int t = catTotal[c] ?? 0;
      if (t == 0) continue;
      final double r = (catCompleted[c] ?? 0) / t;
      if (r > bestRate) {
        bestRate = r;
        bestCat = c;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _biTitle(
            'reportSectionTitle',
            enStyle: GoogleFonts.gowunBatang(fontSize: 13, color: goldColor, fontWeight: FontWeight.bold),
            koStyle: GoogleFonts.notoSansKr(fontSize: 16, color: goldColor, fontWeight: FontWeight.bold),
            foreignStyle: GoogleFonts.notoSans(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          _buildPeriodSelector(),
          const SizedBox(height: 18),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48.0),
              child: Center(
                child: Text(_t('emptyReport'), style: GoogleFonts.notoSansKr(color: slate500, fontSize: 13)),
              ),
            )
          else ...[
            _buildSummaryCard(total: total, completed: completed, rate: rate),
            const SizedBox(height: 20),
            _buildCategoryBreakdownCard(categories: categories, catTotal: catTotal, catCompleted: catCompleted),
            if (bestCat != null) ...[
              const SizedBox(height: 16),
              _buildBestCategoryBanner(bestCat, bestRate),
            ],
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final List<Map<String, String>> options = [
      {'value': 'week', 'labelKey': 'periodWeek'},
      {'value': 'month', 'labelKey': 'periodMonth'},
      {'value': 'all', 'labelKey': 'periodAll'},
    ];
    return Row(
      children: options.map((o) {
        final bool isSel = _period == o['value'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => setState(() => _period = o['value']!),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSel ? goldColor.withValues(alpha: 0.15) : const Color(0xFF020617),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSel ? goldColor : slate800, width: isSel ? 1.5 : 1),
                ),
                child: Center(
                  child: Text(
                    _t(o['labelKey']!),
                    overflow: TextOverflow.fade, softWrap: false, maxLines: 1,
                    style: GoogleFonts.notoSansKr(fontSize: 13, color: isSel ? goldColor : slate400, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard({required int total, required int completed, required double rate}) {
    final int incomplete = total - completed;
    final int percent = (rate * 100).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [const Color(0xFF11192E), const Color(0xFF0A0F1E)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: goldColor.withValues(alpha: 0.55), width: 1.4),
        boxShadow: [BoxShadow(color: goldColor.withValues(alpha: 0.08), blurRadius: 24, spreadRadius: 1)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 128,
            height: 128,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 2,
                    centerSpaceRadius: 42,
                    sections: [
                      PieChartSectionData(
                        value: completed.toDouble().clamp(0.0001, double.infinity),
                        color: completedColor,
                        radius: 20,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: incomplete.toDouble().clamp(0.0001, double.infinity),
                        color: incompleteColor,
                        radius: 20,
                        showTitle: false,
                      ),
                    ],
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 500),
                  swapAnimationCurve: Curves.easeOutCubic,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$percent%', style: GoogleFonts.notoSerif(fontSize: 22, color: goldColor, fontWeight: FontWeight.bold)),
                    Text(_biStr('executionRateLabel'), textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(fontSize: 9, color: slate400)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendRow(color: plannedColor, labelKey: 'plannedLabel', count: total),
                const SizedBox(height: 10),
                _buildLegendRow(color: completedColor, labelKey: 'completedLabel', count: completed),
                const SizedBox(height: 10),
                _buildLegendRow(color: incompleteColor, labelKey: 'incompleteLabel', count: incomplete),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow({required Color color, required String labelKey, required int count}) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(_biStr(labelKey), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white)),
        ),
        Text('$count', style: GoogleFonts.notoSerif(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCategoryBreakdownCard({
    required List<String> categories,
    required Map<String, int> catTotal,
    required Map<String, int> catCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: slate800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _biTitle(
            'categoryBreakdownTitle',
            enStyle: GoogleFonts.gowunBatang(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold),
            koStyle: GoogleFonts.notoSansKr(fontSize: 14, color: goldColor, fontWeight: FontWeight.bold),
            foreignStyle: GoogleFonts.notoSans(fontSize: 13, color: goldColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...categories.map((cat) {
            final int t = catTotal[cat] ?? 0;
            final int c = catCompleted[cat] ?? 0;
            final double r = t == 0 ? 0.0 : c / t;
            final Color color = _categoryColorFor(cat);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_biStr(_categoryLabelKey(cat)), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      Text(
                        t == 0 ? '—' : '$c / $t',
                        style: GoogleFonts.notoSerif(fontSize: 12, color: slate400, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: r),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedValue, _) => LinearProgressIndicator(
                        value: t == 0 ? 0.0 : animatedValue,
                        minHeight: 18,
                        backgroundColor: const Color(0xFF0F172A),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBestCategoryBanner(String bestCat, double bestRate) {
    final Color color = _categoryColorFor(bestCat);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_biStr('bestCategoryLabel'), style: GoogleFonts.notoSansKr(fontSize: 11, color: slate400)),
                const SizedBox(height: 2),
                Text(
                  '${_biStr(_categoryLabelKey(bestCat))} · ${(bestRate * 100).round()}%',
                  style: GoogleFonts.notoSansKr(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
