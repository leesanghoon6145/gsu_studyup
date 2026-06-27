import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ParentLiveStatusWidget extends StatefulWidget {
  final String childName;
  final num currentElapsedTime;
  final int totalCollectedStars;
  final bool isMonitoringActive;
  final int monitoringCountdown;
  final Color premiumCardBg;
  final Color brandGolden;
  final Color luxuryDarkBg;
  final VoidCallback onStartMonitoring;
  final Function(String, String) onSendEmojiMessage;
  final Function(String) onSendCustomMessage;
  final String lastSentTimeText;
  final Widget Function(String, String, {required double fontSize}) buildCustomSectionTitle;

  const ParentLiveStatusWidget({
    Key? key,
    required this.childName,
    required this.currentElapsedTime,
    required this.totalCollectedStars,
    required this.isMonitoringActive,
    required this.monitoringCountdown,
    required this.premiumCardBg,
    required this.brandGolden,
    required this.luxuryDarkBg,
    required this.onStartMonitoring,
    required this.onSendEmojiMessage,
    required this.onSendCustomMessage,
    required this.lastSentTimeText,
    required this.buildCustomSectionTitle,
  }) : super(key: key);

  @override
  State<ParentLiveStatusWidget> createState() => _ParentLiveStatusWidgetState();
}

class _ParentLiveStatusWidgetState extends State<ParentLiveStatusWidget> {
  final TextEditingController _customMessageController = TextEditingController();

  final List<String> _quickMessages = [
    "우리 아이 정말 대단해! 제일 자랑스러워.",
    "조금만 더 힘내! 네 노력은 절대 안 변해.",
    "노력하는 모습 볼 때마다 가슴이 따뜻해져.",
    "최선을 다하는 너, 이미 충분히 멋져!",
    "힘들 때마다 네가 떠올라. 네가 제일 예뻐.",
    "작은 노력이 큰 꿈을 만들어. 항상 응원해!",
  ];

  @override
  void dispose() {
    _customMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: widget.premiumCardBg,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: widget.brandGolden.withValues(alpha: 0.3), width: 1.2),
            ),
            child: Column(
              children: [
                Text(
                  "${widget.childName}님이 현재 \"수학\" 과목 집중 진행 중",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    color: Colors.white,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                // 🛠️ [실시간 연동형 완성본] 글자는 선배님 멘트대로 유지하되, 숫자만 실시간 변수와 바인딩합니다.
                Text(
                  "현재 과목 초 집중 '${widget.currentElapsedTime}분'째 진행중",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    color: widget.brandGolden,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "격려 메세지 전송",
                  style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 🛠️ [수정 사항 1] 이모지 하단 명칭 변경 반영 (밝음 / 최고 / 열공 / 1등)
                    _buildEmojiButton("😊", "밝음", "집중도 최고야!"),
                    _buildEmojiButton("👍", "최고", "포기하지 마라!"),
                    _buildEmojiButton("🔥", "열공", "너의 노력을 응원해"),
                    _buildEmojiButton("👑", "1등", "최고의 집중력이야"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 🛠️ [수정 사항 2] 지시하신 한글 명칭 텍스트 수정 완료
          // 첫 번째 인자값만 "Encourage Self-Directed Learning"으로 교체
          widget.buildCustomSectionTitle("Encourage Self-Directed Learning", "자기주도 학습 응원하기", fontSize: 14.0),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.premiumCardBg,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: widget.brandGolden.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "자주 쓰는 응원 문구 (터치 시 자동 입력)",
                  style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 34,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _quickMessages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ActionChip(
                          backgroundColor: Colors.black38,
                          side: BorderSide(color: widget.brandGolden.withValues(alpha: 0.15)),
                          label: Text(
                            _quickMessages[index],
                            style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 11),
                          ),
                          onPressed: () {
                            setState(() {
                              _customMessageController.text = _quickMessages[index];
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _customMessageController,
                  maxLength: 50, // 🛠️ 50자로 제한 확장 완료!
                  style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13),
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                    return Text(
                      "$currentLength / $maxLength자", // 이제 자동으로 "0 / 50자"로 바뀝니다.
                      style: GoogleFonts.rajdhani(color: widget.brandGolden, fontSize: 11, fontWeight: FontWeight.bold),
                    );
                  },
                  decoration: InputDecoration(
                    hintText: "자녀의 타이머 세션을 점유할 문구를 입력하세요.",
                    hintStyle: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12),
                    filled: true,
                    fillColor: Colors.black45,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: widget.brandGolden),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.lastSentTimeText.isNotEmpty
                          ? "[최근 전송 성공 - ${widget.lastSentTimeText}]"
                          : "대기 중...",
                      style: GoogleFonts.notoSansKr(color: widget.brandGolden.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.brandGolden,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        if (_customMessageController.text.trim().isEmpty) return;
                        widget.onSendCustomMessage(_customMessageController.text.trim());
                        _customMessageController.clear();
                        FocusScope.of(context).unfocus();
                      },
                      icon: const Icon(Icons.send_rounded, color: Colors.black, size: 14),
                      label: Text(
                        "응원 문자 전송",
                        style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          widget.buildCustomSectionTitle("Today's Accumulated Stars", "오늘의 별 수집 현황 : ${widget.totalCollectedStars}개", fontSize: 14.0),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildEmojiButton(String emoji, String label, String message) {
    return InkWell(
      onTap: () => widget.onSendEmojiMessage(emoji, message),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.luxuryDarkBg,
              shape: BoxShape.circle,
              border: Border.all(color: widget.brandGolden.withValues(alpha: 0.3)),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}