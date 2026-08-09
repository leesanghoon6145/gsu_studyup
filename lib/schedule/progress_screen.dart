// ============================================================================
// 🆕 [일반 플래너 3단계] ProgressScreen
// 모든 목표(인생/연간/월간/주간/오늘)의 진행률을 유형별로 모아 한눈에
// 보여줍니다. 각 목표의 진행률은 GoalDataService.calcGoalProgress()로 실시간
// 계산되며, 목표가 하나도 없으면 가짜 숫자 대신 빈 상태 안내를 보여줍니다.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'goal_data_service.dart';
import 'bilingual_text.dart';

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

  List<GoalItem> _allGoals = [];
  Map<String, double> _progressCache = {};
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
      progressMap[g.id] = await GoalDataService.calcGoalProgress(g.id);
    }
    if (!mounted) return;
    setState(() {
      _allGoals = all;
      _progressCache = progressMap;
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
        title: const BiTitle(en: 'PROGRESS', ko: '진행률', enSize: 19, koSize: 14),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : _allGoals.isEmpty
          ? Center(
        child: BiInline(
          en: 'No goals yet. Create a goal and check off tasks\nto see progress here.',
          ko: '등록된 목표가 없습니다.\n목표를 만들고 할 일을 체크하면\n여기에 진행률이 표시됩니다.',
          color: Colors.white38,
          fontSize: 14,
          textAlign: TextAlign.center,
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOverallCard(),
          const SizedBox(height: 16),
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
          const BiInline(en: 'Overall Average Progress', ko: '전체 목표 평균 진행률', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
          const SizedBox(height: 8),
          Text('$percent%', style: GoogleFonts.rajdhani(color: _brandGolden, fontSize: 36, fontWeight: FontWeight.bold)),
          BiInline(en: 'Total ${_allGoals.length} goals', ko: '총 ${_allGoals.length}개 목표', color: Colors.white38, fontSize: 12),
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
            BiInline(en: _typeLabelsEn[type] ?? type, ko: label, color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 14),
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
