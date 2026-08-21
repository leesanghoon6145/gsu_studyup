import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/parent_data_service.dart';

class ParentDetailedAnalysisWidget extends StatelessWidget {
  final String childName;
  final Color premiumCardBg;
  final Color brandGolden;
  final Color luxuryDarkBg;
  final VoidCallback onShowReportPopup;
  final VoidCallback onShowDetailedAnalysisPopup;
  final Widget Function(String, String, {required double fontSize}) buildCustomSectionTitle;

  // 🆕 [실데이터 연동] 오늘 하루 실제 학습 세션 목록 (강의+평가 전부 포함, 시간순 정렬됨)
  final List<ParentSessionRecord> todaySessions;

  // 🆕 [실데이터 연동] 어제 대비 / 1주 평균 대비 학습시간 변화량 계산용
  final int todayTotalMinutes;
  final int yesterdayTotalMinutes;
  final int weeklyAvgMinutesPerDay;

  // 🆕 [실데이터 연동] 평가 평균 점수 기준 가장 잘하는 과목 / 가장 취약한 과목
  final String? strongestSubject;
  final String? weakestSubject;

  const ParentDetailedAnalysisWidget({
    Key? key,
    required this.childName,
    required this.premiumCardBg,
    required this.brandGolden,
    required this.luxuryDarkBg,
    required this.onShowReportPopup,
    required this.onShowDetailedAnalysisPopup,
    required this.buildCustomSectionTitle,
    required this.todaySessions,
    required this.todayTotalMinutes,
    required this.yesterdayTotalMinutes,
    required this.weeklyAvgMinutesPerDay,
    this.strongestSubject,
    this.weakestSubject,
  }) : super(key: key);

  int get _todayVsYesterdayPercent {
    if (yesterdayTotalMinutes <= 0) return todayTotalMinutes > 0 ? 100 : 0;
    return (((todayTotalMinutes - yesterdayTotalMinutes) / yesterdayTotalMinutes) * 100).round();
  }

  int get _todayVsWeeklyAvgPercent {
    if (weeklyAvgMinutesPerDay <= 0) return todayTotalMinutes > 0 ? 100 : 0;
    return (((todayTotalMinutes - weeklyAvgMinutesPerDay) / weeklyAvgMinutesPerDay) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        buildCustomSectionTitle("Self-Directed Learning Records", "$childName 오늘 자기주도 학습 성취도 상세보기", fontSize: 14.0),
        const SizedBox(height: 14),

        // 🆕 [실데이터 연동] 오늘 실제 세션 목록을 제1교시부터 순서대로 표시 (강의/평가 전부 포함)
        if (todaySessions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: premiumCardBg,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              "오늘 아직 기록된 학습 세션이 없습니다.",
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 13),
            ),
          )
        else
          ...List.generate(todaySessions.length, (idx) {
            final rec = todaySessions[idx];
            return _buildAdvancedTimelineCard(
              period: "제${idx + 1}교시",
              subject: rec.subject,
              duration: "${rec.durationMinutes}분 집중완료",
              content: rec.details.isNotEmpty
                  ? rec.details
                  : (rec.recordType == '강의' ? (rec.lectureSubType ?? '강의 학습') : '평가 기록'),
              score: rec.recordType == '평가' && rec.score != null ? "${rec.score}점" : null,
              understanding: rec.understanding != null ? "${rec.understanding}%" : null,
              difficulty: rec.difficulty,
              concentration: rec.concentration,
              condition: rec.condition,
              incorrect: rec.incorrectNote,
              recordTypeLabel: rec.recordType,
            );
          }),
        const SizedBox(height: 16),

        buildCustomSectionTitle("Learning Variation Analytics", "최근 학습 변화량 분석 데이터", fontSize: 14.0),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: premiumCardBg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: brandGolden.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              _buildAlignedVariationRow(
                "오늘 학습시간",
                "어제 대비 ${_todayVsYesterdayPercent >= 0 ? '+' : ''}$_todayVsYesterdayPercent% ${_todayVsYesterdayPercent >= 0 ? '🔺' : '🔻'}",
                "1주 평균 대비 ${_todayVsWeeklyAvgPercent >= 0 ? '+' : ''}$_todayVsWeeklyAvgPercent% ${_todayVsWeeklyAvgPercent >= 0 ? '🔺' : '🔻'}",
              ),
              const Divider(color: Colors.white10, height: 20),
              _buildAlignedVariationRow(
                "오늘 학습 세션 수",
                "${todaySessions.length}개 세션 기록됨",
                todayTotalMinutes > 0 ? "총 $todayTotalMinutes분 집중" : "아직 기록 없음",
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: brandGolden.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextFeatureRow("✨ 잘하고 있는 과목", strongestSubject ?? "데이터 수집 중"),
              const Divider(color: Colors.white10, height: 18),
              _buildTextFeatureRow("🌋 가장 성적이 안나오는 과목", weakestSubject ?? "데이터 수집 중"),
              const Divider(color: Colors.white10, height: 18),
              _buildTextFeatureRow(
                "🛡️ 가정에서 도와줄 포인트",
                weakestSubject != null ? "$weakestSubject 학습 시간 확보 및 오답 정리 지원 권장" : "평가 기록이 쌓이면 안내됩니다",
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        buildCustomSectionTitle("Diagnostic Qualitative Analysis", "학습 기록 분석 진단 센터", fontSize: 14.0),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: premiumCardBg,
                  side: BorderSide(color: brandGolden, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onShowReportPopup,
                icon: Icon(Icons.analytics_rounded, color: brandGolden, size: 16),
                label: Text(
                  "오늘 종합 리포트 보기 🔺",
                  style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: premiumCardBg,
                  side: BorderSide(color: brandGolden, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onShowDetailedAnalysisPopup,
                icon: Icon(Icons.manage_search_rounded, color: brandGolden, size: 16),
                label: Text(
                  "오늘 상세 분석 보기 🔺",
                  style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedTimelineCard({
    required String period,
    required String subject,
    required String duration,
    required String content,
    required String recordTypeLabel,
    String? score,
    String? understanding,
    String? difficulty,
    String? concentration,
    String? condition,
    String? incorrect,
  }) {
    // 🆕 [실데이터 연동] 값이 있는 지표만 동적으로 구성 (강의 기록은 점수/오답노트가 없을 수 있음)
    final List<MapEntry<String, String>> metrics = [];
    if (score != null) metrics.add(MapEntry("점수", score));
    if (understanding != null) metrics.add(MapEntry("이해도", understanding));
    if (difficulty != null) metrics.add(MapEntry("난이도", difficulty));
    if (concentration != null) metrics.add(MapEntry("집중도", concentration));
    if (condition != null) metrics.add(MapEntry("학습컨디션", condition));
    if (incorrect != null) metrics.add(MapEntry("오답정리", incorrect));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: premiumCardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "[$period $subject] $duration",
                  style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: recordTypeLabel == '강의' ? Colors.blueAccent.withValues(alpha: 0.2) : brandGolden.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  recordTypeLabel,
                  style: GoogleFonts.notoSansKr(
                    color: recordTypeLabel == '강의' ? Colors.lightBlueAccent : brandGolden,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "\"상세내용 - $content\"",
            style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: metrics.map((m) => _buildMiniMetricBox(m.key, m.value)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniMetricBox(String label, String val) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: luxuryDarkBg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(val, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAlignedVariationRow(String title, String yesterday, String weekly) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text("- $title", style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(yesterday, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12)),
              Text(weekly, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 11.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextFeatureRow(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: "$label : ", style: GoogleFonts.notoSansKr(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
          TextSpan(text: value, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}
