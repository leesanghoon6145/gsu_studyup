import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// GSU StudyUp - 타이머 위치 미세조정 및 선택 시간별 실시간 분당 별 수집 트랙 반영 완료본
class TimerScreen extends StatefulWidget {
  final String selectedSubject;
  final String selectedMode;
  final int selectedDurationMinutes;
  final String dynamicTestTitle;
  final String calculatedDDay;

  const TimerScreen({
    super.key,
    required this.selectedSubject,
    required this.selectedMode,
    required this.selectedDurationMinutes,
    required this.dynamicTestTitle,
    required this.calculatedDDay,
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  Timer? _ticker;
  int _elapsedSeconds = 0; // 0초부터 실시간 빌드업
  late int _totalTargetSeconds; // 목표 분을 초 단위로 환산
  bool _isRunning = false;
  bool _isMissionCompleted = false; // 미션 중복 트리거 방어막

  @override
  void initState() {
    super.initState();
    _totalTargetSeconds = widget.selectedDurationMinutes * 60;

// ⚠️ [개발용 미션 즉시 완료 테스트 치트키]
// 테스트 시 5초 만에 타임스타 미션 완료를 확인하고 싶으시다면 아래 주석을 풀어주세요.
// _totalTargetSeconds = 5;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    setState(() {
      if (_isRunning) {
        _ticker?.cancel();
        _isRunning = false;
      } else {
        _isRunning = true;
        _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            if (_elapsedSeconds < _totalTargetSeconds) {
              _elapsedSeconds++;
            } else {
              _ticker?.cancel();
              _isRunning = false;
              if (!_isMissionCompleted) {
                _isMissionCompleted = true;
                _triggerTimeStarMissionComplete();
              }
            }
          });
        });
      }
    });
  }

// 🌍 글로벌 UTC 기반 성공 판정 및 완료 다이얼로그 팝업
  void _triggerTimeStarMissionComplete() {
    DateTime completionUtcTime = DateTime.now().toUtc();
    debugPrint("🌐 [GSU StudyUp] Mission Completed At (UTC): $completionUtcTime");

    int rewardStars = 1;
    if (widget.selectedDurationMinutes >= 90) {
      rewardStars = 3;
    } else if (widget.selectedDurationMinutes >= 60) {
      rewardStars = 2;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF0D1527),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
// 🎯 [정정 코드] 189번 라인부터의 children 내부를 이 규격으로 교체해 주세요.
              children: [
                const Icon(Icons.workspace_premium_rounded, color: Color(0xFFE5C158), size: 50),
                const SizedBox(height: 16),
                Text(
                  "GSU\nSTUDYUP",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.gowunBatang(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 10),
                Container(width: 40, height: 1.5, color: const Color(0xFFE5C158)),
                const SizedBox(height: 16),
                Text(
                  "TIME STAR MISSION COMPLETE!\n[타임스타 미션 완료]",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.gowunBatang(
                    color: const Color(0xFFE5C158),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "You have successfully focused on ${widget.selectedSubject} for ${widget.selectedDurationMinutes} minutes.\n\n"
                      "축하합니다! ${widget.selectedSubject} 과목을 ${widget.selectedDurationMinutes}분 동안 완벽히 집중하여 타임스타를 획득했습니다.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5C158).withOpacity(0.5)),
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Color(0xFFE5C158), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "+$rewardStars Stars Acquired (별 적립 완료)",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5C158),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    "CONTINUE JOURNEY (계속하기)",
                    style: GoogleFonts.gowunBatang(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDisplayTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    double progressPercent = _totalTargetSeconds > 0 ? _elapsedSeconds / _totalTargetSeconds : 0.0;
    if (progressPercent > 1.0) progressPercent = 1.0;

// 🌟 [원장님 핵심 지시 정밀 수식] 현재 경과한 시간(초)을 분(Minute) 단위 분자 값으로 계산
    int currentMinutes = _elapsedSeconds ~/ 60;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/timer.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white60, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                const SizedBox(height: 125),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/crown_wings.png',
                      width: 100,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 2),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("✧─── ", style: TextStyle(color: Color(0xFFE5C158), fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(
                          widget.dynamicTestTitle,
                          style: GoogleFonts.gowunBatang(
                            color: const Color(0xFFE5C158),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const Text(" ───✧", style: TextStyle(color: Color(0xFFE5C158), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.calculatedDDay,
                      style: GoogleFonts.gowunBatang(
                        color: const Color(0xFFFFF6D6),
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
// 황금 별 트랙 공간 확보용 프리셋 스페이서 (기존 210 유지하여 별 내부 공간 완벽 방어)
                const SizedBox(height: 210),

// 📐 [원장님 최종 지시 마감] 타이머 숫자 '바로 1mm 위' 안착 레이아웃
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Color(0xFFE5C158), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "실시간 별 획득 현황 : $currentMinutes / ${widget.selectedDurationMinutes} Mins",
                      style: GoogleFonts.gowunBatang(
                        color: const Color(0xFFE5C158),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
// 💡 원장님 지시 1mm 미세 격차 조율: 별 획득 상황과 아래 타이머 타이포그래피 간의 초밀착 마진
                const SizedBox(height: 4),
// 🚨 위치 고정 완료: 이미지 일치 규격 타이머 거대 숫자 레이아웃
                Text(
                  _formatDisplayTime(_elapsedSeconds),
                  style: GoogleFonts.rajdhani(
                    color: Colors.white,
                    fontSize: 78,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    height: 0.9,
                  ),
                ),

                const Spacer(flex: 3),

// 학습 바 구역
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("🔊 [${widget.selectedSubject}] 실시간 학습 진행",
                              style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 13, fontWeight: FontWeight.bold)),
                          Text("목표 시간: ${widget.selectedDurationMinutes}분", style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 12)),

                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 20,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5C158), width: 1.2),
                        ),
                        child: Stack(
                          children: [
                            FractionallySizedBox(
                              widthFactor: progressPercent,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(9),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFC1934A), Color(0xFFFF5E5E), Color(0xFF00C2FF)],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

// 최하단 버튼 구역 (공부 시작 / 일시 중지)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36.0),
                  child: GestureDetector(
                    onTap: _toggleTimer,
                    child: Container(
                      width: double.infinity,
                      height: 58,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/btn_start.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _isRunning ? "PAUSE (일시 중지)" : "START FOCUS (공부 시작)",
                          style: GoogleFonts.gowunBatang(color: const Color(0xFFFFF6D6), fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ],
      ),
    );
  }
}