// ============================================================================
// 🆕 [일반 플래너 3단계] AchievementScreen
// "성취 완료" 처리된 목표들의 기록을 모아 보여줍니다. GoalDataService에
// 저장된 AchievementRecord만 표시하며, 실제로 달성한 것이 없으면 빈 상태
// 안내만 보여줍니다 (가짜 트로피 없음).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'goal_data_service.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
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

  List<AchievementRecord> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);
    final list = await GoalDataService.loadAchievements();
    if (!mounted) return;
    setState(() {
      _achievements = list;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ACHIEVEMENT', style: GoogleFonts.gowunBatang(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('성취', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : _achievements.isEmpty
          ? Center(
        child: Text('아직 달성한 목표가 없습니다.\n목표 화면에서 "성취 완료"를 눌러보세요.',
            textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 14)),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.3))),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: _brandGolden, size: 32),
                const SizedBox(width: 12),
                Text('총 ${_achievements.length}개 달성', style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          ..._achievements.map((a) => _buildAchievementTile(a)),
        ],
      ),
    );
  }

  Widget _buildAchievementTile(AchievementRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: _brandGolden, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.goalTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${_typeLabels[record.goalType] ?? record.goalType} · ${record.achievedDate}',
                    style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
