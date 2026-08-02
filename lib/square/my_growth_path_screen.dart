import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsu_studyup/star_economy.dart'; // 👑 DkeStars 별 경제 시스템 연동

/// ============================================================================
/// [GKE StudyUp] 나의 성장로 화면 (My Growth Path)
/// - DkeStars에 누적 저장된 전체 별 개수와 레벨을 보여주는 개인 성장 기록 화면
/// ============================================================================
class MyGrowthPathScreen extends StatefulWidget {
  const MyGrowthPathScreen({super.key});

  @override
  State<MyGrowthPathScreen> createState() => _MyGrowthPathScreenState();
}

class _MyGrowthPathScreenState extends State<MyGrowthPathScreen> {
  static const Color brandGolden = Color(0xFFE5C158);
  static const Color bgColor = Color(0xFF030712);
  static const Color cardColor = Color(0xFF0D1527);

  int _totalStars = 0;
  int _todayStars = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStarData();
  }

  Future<void> _loadStarData() async {
    final total = await DkeStars.getTotalStars();
    final today = await DkeStars.getTodayStars();
    if (!mounted) return;
    setState(() {
      _totalStars = total;
      _todayStars = today;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int level = DkeStars.levelForStars(_totalStars);
    final int intoLevel = DkeStars.starsIntoCurrentLevel(_totalStars);
    final int untilNext = DkeStars.starsUntilNextLevel(_totalStars);
    final double progress = intoLevel / DkeStars.starsPerLevel;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'MY GROWTH PATH (나의 성장로)',
          style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: brandGolden))
          : RefreshIndicator(
        onRefresh: _loadStarData,
        color: brandGolden,
        backgroundColor: cardColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // [주석] 레벨 + 전체 누적 별 카드
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: brandGolden.withOpacity(0.35), width: 1.2),
                ),
                child: Column(
                  children: [
                    Text(
                      'LEVEL $level',
                      style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 30),
                    ),
                    Text(
                      '(레벨 $level)',
                      style: GoogleFonts.notoSansKr(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded, color: brandGolden, size: 26),
                        const SizedBox(width: 8),
                        Text(
                          '$_totalStars',
                          style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Total Stars (전체 누적 별)',
                          style: GoogleFonts.notoSansKr(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // [주석] 다음 레벨까지 진행률 게이지바
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 12,
                        backgroundColor: Colors.black38,
                        valueColor: const AlwaysStoppedAnimation<Color>(brandGolden),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Next Level in $untilNext Stars (다음 레벨까지 $untilNext개)',
                      style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // [주석] 오늘 적립한 별 카드
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Today (오늘 적립)', style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: brandGolden, size: 20),
                        const SizedBox(width: 6),
                        Text('$_todayStars', style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 20)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
