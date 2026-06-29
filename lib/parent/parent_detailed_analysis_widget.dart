import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ParentDetailedAnalysisWidget extends StatelessWidget {
  final String childName;
  final Color premiumCardBg;
  final Color brandGolden;
  final Color luxuryDarkBg;
  final VoidCallback onShowReportPopup;
  final VoidCallback onShowDetailedAnalysisPopup;
  final Widget Function(String, String, {required double fontSize}) buildCustomSectionTitle;

  // 🛠️ 선배님의 원본 뼈대를 100% 유지하면서, 메인의 빨간 줄 에러만 잡기 위한 데이터 통로를 안전하게 개설합니다.
  final List<Map<String, dynamic>> parentMasterTimeData;

  const ParentDetailedAnalysisWidget({
    Key? key,
    required this.childName,
    required this.premiumCardBg,
    required this.brandGolden,
    required this.luxuryDarkBg,
    required this.onShowReportPopup,
    required this.onShowDetailedAnalysisPopup,
    required this.buildCustomSectionTitle,
    required this.parentMasterTimeData, // 🛠️ 메인 파일의 355라인 컴파일 에러를 해결하는 핵심 필수 규격입니다.
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        // 🛠️ 선배님의 완벽한 기획 문구를 보존하되, 요청하신 "(멤버)" 글자만 깔끔하게 제거 처리했습니다.
        buildCustomSectionTitle("Self-Directed Learning Records", "$childName 오늘 자기주도 학습 성취도 상세보기", fontSize: 14.0),
        const SizedBox(height: 14),

        // 💎 선배님 고유의 상세 레이아웃 및 하드코딩 매트릭스 텍스트를 단 한 글자도 건드리지 않고 원본 그대로 유지합니다.
        _buildAdvancedTimelineCard(
          period: "제1교시",
          subject: "수학",
          duration: "60분 집중완료",
          content: "미적분수능 기출문제집 20p~25p 개념 정리 및 오답풀이",
          score: "95점",
          understanding: "80%",
          difficulty: "보통",
          concentration: "높음",
          condition: "좋음",
          incorrect: "정리함",
        ),
        _buildAdvancedTimelineCard(
          period: "제2교시",
          subject: "영어",
          duration: "90분 집중완료",
          content: "EBS 수능특강 고난도 구문 독해 및 취약 어휘 매핑",
          score: "92점",
          understanding: "85%",
          difficulty: "어려움",
          concentration: "최상",
          condition: "좋음",
          incorrect: "정리함",
        ),
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
              _buildAlignedVariationRow("오늘 학습시간", "어제 대비 +1.5시간 (15% 증가) 🔺", "1주 평균 대비 +0.8시간 (8% 증가) 🔺"),
              const Divider(color: Colors.white10, height: 20),
              _buildAlignedVariationRow("과목 전체 완료율", "어제 대비 +12% 완성 🔺", "1주 평균 대비 +5% 향상 🔺"),
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
              _buildTextFeatureRow("✨ 잘하고 있는 과목", "수학 (학습기록장의 나의 레전드 과목)"),
              const Divider(color: Colors.white10, height: 18),
              _buildTextFeatureRow("🌋 가장 성적이 안나오는 과목", "과학 (학습기록장의 나의 블랙홀 과목)"),
              const Divider(color: Colors.white10, height: 18),
              _buildTextFeatureRow("🛡️ 가정에서 도와줄 포인트", "탐구 교과 오답 연동 분석 인프라 지원 요청"),
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
    required String score,
    required String understanding,
    required String difficulty,
    required String concentration,
    required String condition,
    required String incorrect,
  }) {
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
          Text(
            "[$period $subject] $duration",
            style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "\"상세내용 - $content\"",
            style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMiniMetricBox("점수", score),
                _buildMiniMetricBox("이해도", understanding),
                _buildMiniMetricBox("난이도", difficulty),
                _buildMiniMetricBox("집중도", concentration),
                _buildMiniMetricBox("학습컨디션", condition),
                _buildMiniMetricBox("오답정리", incorrect),
              ],
            ),
          )
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