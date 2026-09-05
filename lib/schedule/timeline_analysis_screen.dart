// ============================================================================
// 🆕 [일반 플래너 2단계] TimelineAnalysisScreen
// 실제로 완료(completed)된 타임라인 블록만 근거로 통계를 계산합니다.
// 데이터가 없으면 가짜 숫자로 채우지 않고 "아직 분석할 데이터가 없다"는
// 안내만 보여줍니다 (ai_consulting_room_screen.dart에서 발견됐던 문제를
// 반복하지 않기 위한 원칙 적용).
//
// ✅ [2026-09-04 추가] 운동(EXERCISE) 연동. 전체 기간 누적 운동 요약(세션/
// 시간/평균 RPE) 카드를 추가.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'timeline_data_service.dart';
import 'bilingual_text.dart'; // 🆕 [42건 정리] 이 화면만 병기 공용위젯이 빠져있었음
import 'exercise_data_service.dart'; // 🆕 [운동 연동]

class TimelineAnalysisScreen extends StatefulWidget {
  const TimelineAnalysisScreen({super.key});

  @override
  State<TimelineAnalysisScreen> createState() => _TimelineAnalysisScreenState();
}

class _TimelineAnalysisScreenState extends State<TimelineAnalysisScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  List<TimelineBlock> _allBlocks = [];
  List<TimelineBlock> _completedBlocks = [];
  int _totalExerciseSessions = 0; // 🆕 [운동 연동]
  int _totalExerciseMinutes = 0; // 🆕 [운동 연동]
  double? _avgExerciseRpe; // 🆕 [운동 연동]
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final all = await TimelineDataService.loadAllBlocks();
    final completed = all.where((b) => b.status == 'completed').toList();

    // 🆕 [운동 연동] 전체 기간 누적 운동 기록
    final allExercises = await ExerciseDataService.instance.getAllRecords();
    final exerciseMinutes = allExercises.fold<int>(0, (sum, r) => sum + r.durationMin);
    final rpeValues = allExercises.where((r) => r.rpe != null).map((r) => r.rpe!).toList();
    final avgRpe = rpeValues.isEmpty ? null : rpeValues.reduce((a, b) => a + b) / rpeValues.length;

    if (!mounted) return;
    setState(() {
      _allBlocks = all;
      _completedBlocks = completed;
      _totalExerciseSessions = allExercises.length; // 🆕 [운동 연동]
      _totalExerciseMinutes = exerciseMinutes; // 🆕 [운동 연동]
      _avgExerciseRpe = avgRpe; // 🆕 [운동 연동]
      _isLoading = false;
    });
  }

  // 🆕 전체 완료율 (전체 블록 중 완료된 비율)
  double get _overallCompletionRate {
    if (_allBlocks.isEmpty) return 0;
    return _completedBlocks.length / _allBlocks.length;
  }

  // 🆕 분류(category)별 실제 소요시간 총합(분) - 완료된 블록만 집계
  Map<String, int> get _categoryMinutes {
    final Map<String, int> result = {};
    for (final block in _completedBlocks) {
      final int? minutes = block.actualMinutes;
      if (minutes == null) continue;
      result[block.category] = (result[block.category] ?? 0) + minutes;
    }
    return result;
  }

  // 🆕 평균 시간 차이(분) - 완료된 블록들의 diffMinutes 평균 (계획보다 얼마나 늦거나 빨랐는지)
  double? get _averageDiffMinutes {
    final diffs = _completedBlocks.map((b) => b.diffMinutes).whereType<int>().toList();
    if (diffs.isEmpty) return null;
    return diffs.reduce((a, b) => a + b) / diffs.length;
  }

  @override
  Widget build(BuildContext context) {
    // 🆕 [운동 연동] 완료된 타임라인이 없어도 운동 기록이 있으면 빈 화면 대신 분석을 보여준다.
    final bool hasAnyData = _completedBlocks.isNotEmpty || _totalExerciseSessions > 0;

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
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('TIMELINE ANALYSIS', style: GoogleFonts.gowunBatang(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('타임라인 분석', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : !hasAnyData
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BiInline(
            en: 'No data to analyze yet.\nThe more timeline items you run and complete,\nthe more accurate this analysis becomes.',
            ko: '아직 분석할 데이터가 없습니다.\n타임라인을 실행하고 완료할수록\n더 정확한 분석을 볼 수 있습니다.',
            color: Colors.white38,
            fontSize: 13,
            textAlign: TextAlign.center,
            translations: const {
              'JA': 'まだ分析するデータがありません。\nタイムラインを実行して完了するほど、\nより正確な分析が見られます。',
              'ZH': '暂无可分析的数据。\n运行并完成的时间线越多，\n分析就越准确。',
              'FR': "Aucune donnée à analyser pour l'instant.\nPlus vous exécutez et terminez d'éléments,\nplus cette analyse devient précise.",
              'DE': 'Noch keine Daten zur Analyse.\nJe mehr Zeitleisteneinträge Sie ausführen und abschließen,\ndesto genauer wird diese Analyse.',
              'RU': 'Пока нет данных для анализа.\nЧем больше элементов хронологии вы выполните,\nтем точнее будет анализ.',
              'AR': 'لا توجد بيانات للتحليل بعد.\nكلما نفذت وأكملت المزيد من عناصر الجدول الزمني،\nأصبح هذا التحليل أكثر دقة.',
              'HI': 'अभी विश्लेषण के लिए कोई डेटा नहीं है।\nजितने अधिक समयरेखा आइटम चलाएंगे और पूरा करेंगे,\nविश्लेषण उतना ही सटीक होगा।',
              'VI': 'Chưa có dữ liệu để phân tích.\nBạn chạy và hoàn thành càng nhiều mục dòng thời gian,\nphân tích này càng chính xác.',
              'ES': 'Aún no hay datos para analizar.\nCuantos más elementos de cronología ejecutes y completes,\nmás preciso será este análisis.',
              'TH': 'ยังไม่มีข้อมูลให้วิเคราะห์\nยิ่งคุณดำเนินการและทำรายการไทม์ไลน์เสร็จมากเท่าไร\nการวิเคราะห์นี้จะยิ่งแม่นยำมากขึ้นเท่านั้น',
            },
          ),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_completedBlocks.isNotEmpty) ...[
            _buildOverallCard(),
            const SizedBox(height: 16),
            _buildCategoryCard(),
            const SizedBox(height: 16),
            _buildDiffCard(),
            const SizedBox(height: 16),
          ],
          if (_totalExerciseSessions > 0) _buildExerciseCard(), // 🆕 [운동 연동]
        ],
      ),
    );
  }

  Widget _buildOverallCard() {
    final int percent = (_overallCompletionRate * 100).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
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
            en: 'Completed ${_completedBlocks.length} / Total ${_allBlocks.length}', ko: '완료 ${_completedBlocks.length} / 전체 ${_allBlocks.length}건', color: Colors.white38, fontSize: 12,
            translations: {
              'JA': '完了 ${_completedBlocks.length} / 全体 ${_allBlocks.length}',
              'ZH': '完成 ${_completedBlocks.length} / 总计 ${_allBlocks.length}',
              'FR': 'Terminé ${_completedBlocks.length} / Total ${_allBlocks.length}',
              'DE': 'Erledigt ${_completedBlocks.length} / Gesamt ${_allBlocks.length}',
              'RU': 'Выполнено ${_completedBlocks.length} / Всего ${_allBlocks.length}',
              'AR': 'مكتمل ${_completedBlocks.length} / الإجمالي ${_allBlocks.length}',
              'HI': 'पूर्ण ${_completedBlocks.length} / कुल ${_allBlocks.length}',
              'VI': 'Hoàn thành ${_completedBlocks.length} / Tổng ${_allBlocks.length}',
              'ES': 'Completado ${_completedBlocks.length} / Total ${_allBlocks.length}',
              'TH': 'เสร็จ ${_completedBlocks.length} / ทั้งหมด ${_allBlocks.length}',
            },
          ),
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
              const Icon(Icons.fitness_center_rounded, color: _brandGolden, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: BiInline(
                  en: 'Exercise (All Time)', ko: '운동 (전체 기간)', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
                  translations: const {'JA': '運動（全期間）', 'ZH': '运动（全部时间）', 'FR': "Exercice (toute période)", 'DE': 'Training (gesamter Zeitraum)', 'RU': 'Тренировки (за всё время)', 'AR': 'التمرين (كل الفترات)', 'HI': 'व्यायाम (संपूर्ण अवधि)', 'VI': 'Tập luyện (toàn bộ)', 'ES': 'Ejercicio (todo el período)', 'TH': 'ออกกำลังกาย (ทั้งหมด)'},
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
        Text(value, style: GoogleFonts.rajdhani(color: _brandGolden, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        BiInline(en: en, ko: ko, color: Colors.white54, fontSize: 10),
      ],
    );
  }

  Widget _buildCategoryCard() {
    final categoryMinutes = _categoryMinutes;
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
            en: 'Time by Category (Actual)', ko: '분류별 실제 사용 시간', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
            translations: const {'JA': 'カテゴリー別実使用時間', 'ZH': '按分类实际用时', 'FR': 'Temps réel par catégorie', 'DE': 'Tatsächliche Zeit nach Kategorie', 'RU': 'Фактическое время по категориям', 'AR': 'الوقت الفعلي حسب الفئة', 'HI': 'श्रेणी अनुसार वास्तविक समय', 'VI': 'Thời gian thực tế theo danh mục', 'ES': 'Tiempo real por categoría', 'TH': 'เวลาจริงตามหมวดหมู่'},
          ),
          const SizedBox(height: 12),
          if (total == 0)
            BiInline(en: 'No data', ko: '데이터 없음', color: Colors.white38, fontSize: 12, translations: commonButtonTranslations['No data'])
          else
            ...entries.map((e) {
              final int pct = total == 0 ? 0 : ((e.value / total) * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        Text('${e.value}min (${e.value}분) $pct%', style: const TextStyle(color: _brandGolden, fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : e.value / total,
                        minHeight: 8,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(_brandGolden),
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

  Widget _buildDiffCard() {
    final double? avgDiff = _averageDiffMinutes;
    String summaryText;
    Color summaryColor;

    if (avgDiff == null) {
      summaryText = '데이터 없음';
      summaryColor = Colors.white38;
    } else if (avgDiff.abs() < 1) {
      summaryText = '평균적으로 계획한 시간과 정확히 맞춰 실행하고 있습니다.';
      summaryColor = Colors.white70;
    } else if (avgDiff > 0) {
      summaryText = '평균적으로 계획보다 ${avgDiff.round()}분 더 오래 걸리고 있습니다.';
      summaryColor = Colors.orangeAccent;
    } else {
      summaryText = '평균적으로 계획보다 ${avgDiff.abs().round()}분 더 빠르게 마치고 있습니다.';
      summaryColor = Colors.lightGreenAccent;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BiInline(
            en: 'Planned vs Actual Trend', ko: '계획 대비 실행 경향', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
            translations: const {'JA': '計画対実行の傾向', 'ZH': '计划与执行趋势', 'FR': 'Tendance prévu vs réel', 'DE': 'Geplant vs. tatsächlich Trend', 'RU': 'Тенденция план/факт', 'AR': 'اتجاه المخطط مقابل الفعلي', 'HI': 'नियोजित बनाम वास्तविक रुझान', 'VI': 'Xu hướng kế hoạch và thực tế', 'ES': 'Tendencia planificado vs real', 'TH': 'แนวโน้มแผนเทียบกับจริง'},
          ),
          const SizedBox(height: 10),
          Text(summaryText, style: GoogleFonts.notoSansKr(color: summaryColor, fontSize: 14, fontWeight: FontWeight.bold, height: 1.5)),
        ],
      ),
    );
  }
}
