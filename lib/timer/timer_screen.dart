import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// GSU StudyUp - [원장님 최종 지시: 이미지 기반 타이머 폰트/크기 일치화 및 황금색 별갯수 마감본]
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  // 🏛️ 타이머 제어 코어 엔진
  Timer? _ticker;
  int _elapsedSeconds = 45 * 60 + 23; // 이미지와 싱크를 맞추기 위한 초기값 (45분 23초)
  int _totalTargetMinutes = 500; // 이미지 기준 목표 변경 (500분)
  bool _isRunning = false;

  // 🎯 홈 대시보드 및 가입 정보 연동 가변 데이터
  final String _dynamicGradeTitle = "2027 대학수능";
  final String _calendarDDayText = "D - 100";

  // 게이미피케이션 자산 데이터
  int _realtimeStars = 23;
  final int _maxStars = 60;
  final String _subject = "수학";

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
            _elapsedSeconds++;
          });
        });
      }
    });
  }

  String _formatDisplayTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    double progressPercent = _elapsedSeconds / (_totalTargetMinutes * 60);
    if (progressPercent > 1.0) progressPercent = 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: Stack(
        children: [
          // 🎨 오리지널 명품 아트워크 배경 도킹
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

          // 🪐 최상단 가시성 레이아웃
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 뒤로가기 버튼 영역
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

                // 🏛️ 상단 구역: GSU STUDYUP 글자 아래 ~ 별 위 끝점 정중앙 안착존
                const SizedBox(height: 125),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 진짜 펼쳐진 고전 황금 왕관 심볼
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFE5C158),
                      size: 24,
                    ),
                    const SizedBox(height: 1),

                    // 좌우 황금 선 디자인과 가변 학년 타이틀
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("✧───  ", style: TextStyle(color: Color(0xFFE5C158), fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(
                          _dynamicGradeTitle,
                          style: GoogleFonts.gowunBatang(
                            color: const Color(0xFFE5C158),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const Text("  ───✧", style: TextStyle(color: Color(0xFFE5C158), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),

                    const SizedBox(height: 0),

                    // 달력 연동형 D-Day 카운터
                    Text(
                      _calendarDDayText,
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

                // 황금 별 트랙 내부 공간 통과용 프리셋 스페이서
                const SizedBox(height: 210),

                // 🚨 [원장님 지시 완수] 이미지와 100% 일치하는 폰트, 크기, 위치의 타이머 레이아웃
                Text(
                  _formatDisplayTime(_elapsedSeconds),
                  style: GoogleFonts.rajdhani(
                    color: Colors.white,
                    fontSize: 78, // 💡 이미지 속 웅장하고 컴팩트한 비율을 내기 위한 스케일
                    fontWeight: FontWeight.w700, // 세련되게 각진 두께감 수호
                    letterSpacing: 1.0, // 이미지 특유의 자간 거리 적용
                    height: 0.9, // 별 하단 팁에 바짝 붙이기 위한 서체 마진 최적화
                  ),
                ),

                const SizedBox(height: 6), // 타이머와 별갯수 사이 미세 마진

                // ✨ [원장님 지시 완수] 황금색 변환 및 고가시성 볼드 처리된 실시간 별갯수 라인
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Color(0xFFE5C158), size: 15), // 아이콘 황금색 변환
                    const SizedBox(width: 4),
                    Text(
                      "실시간 별갯수: $_realtimeStars개",
                      style: GoogleFonts.gowunBatang(
                        color: const Color(0xFFE5C158), // 💡 원장님 지시: 황금색 마스터 컬러 코딩!
                        fontSize: 14,
                        fontWeight: FontWeight.w800, // 아주 진하게 강조
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 3),

                // 학습 바 구역 (이미지 기반 수치 동기화 완수)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("🔊 실시간 학습 진행 상황", style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 13, fontWeight: FontWeight.bold)),
                          Text("편집 / $_totalTargetMinutes분", style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 12)),
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

                // 최하단 버튼 구역 (공부 시작 / 일시 중지 텍스트 일치 완료)
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
                          "공부 시작 / 일시 중지", // 이미지 명칭과 완벽 싱크
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