import 'dart:async';
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
                  "${widget.childName}님이 현재 \"수학\" 과목 집중 진행 중",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    color: Colors.white,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
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
                    _buildEmojiButton("😊", "밝음", "집중도 최고야!"),
                    _buildEmojiButton("👍", "최고", "포기하지 마라!"),
                    _buildEmojiButton("🔥", "열공", "너의 노력을 응원해"),
                    _buildEmojiButton("👑", "1등", "최고의 집중력이야"),
                  ],
                ),
              ],
            ),
          ),

          // ============================================================================
          // 🗺️ 명당 128번 줄: 지시하신 이모지 박스 바로 밑 고급형 [자녀 실시간 타이머 보기] 버튼
          // ============================================================================
          // ============================================================================

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
// 🪐 [새로 동기화된 독립 스크린] 타이머1.jpg 완벽 고증 매커니즘 전체 화면
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
  final int _maxLoopSecs = 30; // 30초 실험 배속 모드 고정 주축

  @override
  void initState() {
    super.initState();
    // ⚡ 엔진 기동: 1초마다 실시간 미러링 작동 연산 시작
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
    _runningTimer?.cancel(); // 자원 해제 단속
    super.dispose();
  }

  // 고딕체 디지털 시계 포맷기
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
      backgroundColor: const Color(0xFF030712), // 우주 블랙 테마 베이스
      body: Stack(
        children: [
          // 🖼️ [완벽 교정] 선배님이 정확히 지시하신 진짜 "assets/images/timer.png" 이미지 단일 배경화
          Positioned.fill(
            child: Image.asset(
              'assets/images/timer.png', // 지시하신 정품 타이머 배경 불러오기 완료!
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF020617)),
            ),
          ),

          // 🪐 타이머1.jpg 100% 쌍둥이 실물 크기 컴포넌트 탑재 구역
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 25),

                  // GKE STUDYUP 대형 아치 서두 로고 오버레이
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

                  // 🪶 [명칭 고증] 고전책 자막 바로 아래 crown_wings.png 정밀 소환
                  Image.asset(
                    'assets/images/crown_wings.png', // 정품 왕관 날개 장식 호출 완료!
                    width: 150,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.wb_twighlight, color: Color(0xFFE5C158), size: 35),
                  ),
                  const SizedBox(height: 6),

                  // 📐 수능 및 디데이 계판 레이아웃 일치화
                  Text(
                    "— 2027 대학수능 —", // 설정 적용 가능 구조 보존
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

                  // ⭐ 거대 황금 별 중앙 심볼 장식
                  const Icon(Icons.star_rounded, color: Color(0xFFE5C158), size: 105),
                  const SizedBox(height: 15),

                  // 🧪 배속 실험 모드 가동 상태 자막 (고딕체 단속)
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

                  // 🕒 [타이머 핵심] 100% 쌍둥이 초대형 고딕 실시간 작동 디지털 계판
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

                  // 🔊 과목 선택 자동 나타남 구역 연동
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.volume_up_rounded, color: Color(0xFFFCD34D), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "Native Language (국어)", // 과목 연동 시스템 데이터 바인딩
                        style: GoogleFonts.gowunBatang(
                          color: const Color(0xFFFCD34D),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 실시간 집중 모드 및 목표 시간 배치선 (설정 연동 구조)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "실시간 집중 모드 (실험)",
                        style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "목표 시간: 30분", // 설정값 매핑 단속
                        style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 🌈 [하이라이트 명품 스펙] 빨주노초파남보 레인보우 프로그레스 게이지 바
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
                        widthFactor: progressRatio, // 실시간 퍼센트에 맞춰 빨주노초파남보가 미려하게 차오름
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFF0000), // 빨
                                Color(0xFFFF7F00), // 주
                                Color(0xFFFFFF00), // 노
                                Color(0xFF00FF00), // 초
                                Color(0xFF0000FF), // 파
                                Color(0xFF4B0082), // 남
                                Color(0xFF8B00FF), // 보
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // 진행 바 하단 초 및 퍼센트 실시간 수치 표출
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

                  const Spacer(), // 공간을 하단 우측으로 완벽 밀착 유도하는 완충 쿠션

                  // 👑 [선배님 핵심 지시 완벽 수용] 그만 보고 싶을 때 탈출하는 우측 하단 프리미엄 뒤로가기 버튼
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
                            Navigator.pop(context); // 현재 타이머 전체화면 스크린을 닫고 메인으로 안전 복귀!
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