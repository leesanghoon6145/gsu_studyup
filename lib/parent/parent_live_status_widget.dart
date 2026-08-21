import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ParentLiveStatusWidget extends StatefulWidget {
  final String childName;
  // 🆕 [실데이터 연동] "현재 진행 중"을 실제로 감지할 방법이 없어(부모 화면은 별도 프로세스이므로),
  // 가장 최근 학습 세션 정보로 대체 표시합니다. 값이 없으면 lastSessionSubject가 null입니다.
  final String? lastSessionSubject;
  final int lastSessionDurationMinutes;
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
    required this.lastSessionSubject,
    required this.lastSessionDurationMinutes,
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
    "우리 아이 정말 대단해! 자랑스럽고 고맙다.",
    "조금만 더 힘내! 네 노력은 절대 헛되지 않아.",
    "노력하는 모습 볼 때마다 가슴이 따뜻해져.",
    "최선을 다하는 너, 이미 충분히 멋져!",
    "힘들 때마다 네가 떠올라. 네가 제일 좋아.",
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
                  widget.lastSessionSubject != null
                      ? "${widget.childName}님의 가장 최근 학습: \"${widget.lastSessionSubject}\""
                      : "${widget.childName}님의 학습 기록이 아직 없습니다",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    color: Colors.white,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.lastSessionSubject != null)
                  Text(
                    "최근 세션 집중시간 '${widget.lastSessionDurationMinutes}분'",
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
                    _buildEmojiButton("😊", "밝음", "집중도 최고야!"),
                    _buildEmojiButton("👍", "최고", "포기하지 마라!"),
                    _buildEmojiButton("🔥", "열공", "너의 노력을 응원해"),
                    _buildEmojiButton("👑", "1등", "최고의 집중력이야"),
                  ],
                ),
              ],
            ),
          ),

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
                  maxLength: 50,
                  style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13),
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                    return Text(
                      "$currentLength / $maxLength자",
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

// ============================================================================
// 🪐 FullMirrorTimerScreen — 실데이터와 무관한 데모용 미러 타이머 화면이라 원본 그대로 유지
// ============================================================================
class FullMirrorTimerScreen extends StatefulWidget {
  final Color brandGolden;
  final String childName;
  const FullMirrorTimerScreen({Key? key, required this.brandGolden, required this.childName}) : super(key: key);

  @override
  State<FullMirrorTimerScreen> createState() => _FullMirrorTimerScreenState();
}

class _FullMirrorTimerScreenState extends State<FullMirrorTimerScreen> {
  Timer? _runningTimer;
  int _totalSeconds = 0;
  final int _maxLoopSecs = 30;

  @override
  void initState() {
    super.initState();
    _runningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _totalSeconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _runningTimer?.cancel();
    super.dispose();
  }

  String _formatToClock(int secs) {
    int h = secs ~/ 3600;
    int m = (secs % 3600) ~/ 60;
    int s = secs % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    double progressRatio = (_totalSeconds % _maxLoopSecs) / _maxLoopSecs;
    int currentSec = _totalSeconds % _maxLoopSecs;

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/timer.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF020617)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 25),
                  Text(
                    "GKE\nSTUDYUP",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansKr(
                      color: widget.brandGolden,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Image.asset(
                    'assets/images/crown_wings.png',
                    width: 150,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.wb_twighlight, color: Color(0xFFE5C158), size: 35),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "— 2027 대학수능 —",
                    style: GoogleFonts.nanumMyeongjo(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "D - Day",
                    style: GoogleFonts.notoSansKr(
                      color: const Color(0xFFFFFDF0),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Icon(Icons.star_rounded, color: Color(0xFFE5C158), size: 105),
                  const SizedBox(height: 15),
                  Text(
                    "★ 배속 실험 모드 가동 : $currentSec / 30 Secs",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Gothic',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatToClock(_totalSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Gothic',
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.volume_up_rounded, color: Color(0xFFFCD34D), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "Native Language (국어)",
                        style: GoogleFonts.gowunBatang(
                          color: const Color(0xFFFCD34D),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "실시간 집중 모드 (실험)",
                        style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "목표 시간: 30분",
                        style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progressRatio,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFF0000),
                                Color(0xFFFF7F00),
                                Color(0xFFFFFF00),
                                Color(0xFF00FF00),
                                Color(0xFF0000FF),
                                Color(0xFF4B0082),
                                Color(0xFF8B00FF),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${currentSec.toDouble().toStringAsFixed(1)}초 (${(progressRatio * 100).toStringAsFixed(0)}%)",
                        style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "30.0초 (100%)",
                        style: TextStyle(color: widget.brandGolden, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12, right: 2),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: widget.brandGolden.withValues(alpha: 0.4), width: 1.2),
                        ),
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 12),
                          label: Text(
                            "뒤로가기  ",
                            style: GoogleFonts.notoSansKr(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
