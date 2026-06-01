import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// GSU StudyUp - 글로벌 타이머 및 [Time Star Mission] 연동 스크린
///
/// 핵심 원칙:
/// 1. 타이틀/강조 문구 서체 고운바탕체(gowunBatang) 단일화 준수
/// 2. 글로벌 표준 UTC 시간대 기준 설계
/// 3. [Time Star Mission] 사전 선언 및 사후 검증 제어 메커니즘 탑재
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  // 타이머 관련 상태 변수 (UTC 표준 기준 제어)
  Timer? _ticker;
  int _remainingSeconds = 3600; // 자동 설정 기본 시간: 60분 (3600초)
  bool _isRunning = false;

  // 게이미피케이션 상태 자산 (원장님 지정 메인 기준 75/90)
  int _currentStars = 75;
  final int _maxStars = 90;

  // [Time Star Mission] 사전 선언 데이터 데이터 모델
  final String _subject = "수학";
  final String _targetAmount = "블랙라벨 21p~28p";
  int _achievementRate = 0; // 사후 검증 달성률 (???%)
  bool _isGoalAchieved = false; // 목표달성 예/아니오

  @override
  void initState() {
    super.initState();
    // 화면이 켜지자마자 아이들의 기만 행위를 방지하는 [Time Star Mission] 창을 자동으로 호출합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPreMissionDialog();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// UTC 시간축 기반 타이머 구동 엔진
  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _stopTimer(isCompleted: true);
      }
    });
  }

  void _pauseTimer() {
    if (!_isRunning) return;
    _ticker?.cancel();
    setState(() => _isRunning = false);

    // 중간 중단 시 즉시 탈주 방지 락(Lock) 시스템 가동 및 기록 유도
    _showInterruptedDialog();
  }

  void _stopTimer({required bool isCompleted}) {
    _ticker?.cancel();
    setState(() => _isRunning = false);

    // 학습이 완전히 끝나거나 중단 확정 시 사후 검증 창 자동 오픈
    _showPostMissionDialog(isCompleted);
  }

  /// 초 단위 데이터를 글로벌 표준 MM:SS 포맷으로 정밀 변환
  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  // ==========================================================================
  // 🏛️ [Time Star Mission] 핵심 미션 통제 모달창 아키텍처
  // ==========================================================================

  /// ① 학습 시작 전 [사전 선언 단계] 팝업창
  void _showPreMissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 임의로 창을 닫아 타이머만 가동하는 행위 원천 차단
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "[Time Star Mission] - 사전 선언",
            style: GoogleFonts.gowunBatang(
              color: const Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMissionInfoRow("자동 설정 시간", "60분"),
                _buildMissionInfoRow("선택 과목", _subject),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "📝 현재 목표 학습량",
                    style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                  ),
                  child: Text(
                    _targetAmount,
                    style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "부모님 기만 방지를 위해 미션을 메모장에 기록하고 확인을 완료해 주세요.",
                  style: GoogleFonts.gowunBatang(color: Colors.orangeAccent, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startTimer(); // 선언을 마쳐야만 비로소 타이머 작동 시작
              },
              child: Text(
                "미션 확인 및 타이머 가동",
                style: GoogleFonts.gowunBatang(
                  color: const Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// ② 학습 중간 중단 시 [탈주 방지 락 시스템] 팝업창
  void _showInterruptedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "⚠️ 학습 중단 경고",
            style: GoogleFonts.gowunBatang(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "공부를 하지 않고 타이머만 켜두는 것은 부모님을 기만하는 행위입니다.\n정말 여기서 중단하고 기록을 남기시겠습니까?",
            style: GoogleFonts.gowunBatang(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startTimer(); // 다시 정신 차리고 계속 학습 진행
              },
              child: Text(
                "계속 학습 진행",
                style: GoogleFonts.gowunBatang(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _stopTimer(isCompleted: false); // 중단 확정 후 결과 기록창으로 이동
              },
              child: Text(
                "중단 및 기록 보관",
                style: GoogleFonts.gowunBatang(
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  /// ③ 학습 종료/중단 완료 후 [사후 검증 및 부모님 연동 데이터 기록] 팝업창
  void _showPostMissionDialog(bool isCompleted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                "[Time Star Mission] - 최종 결과 입력",
                style: GoogleFonts.gowunBatang(
                  color: const Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isCompleted ? "축하합니다! 설정한 시간을 모두 채웠습니다." : "중단된 시점까지의 성과를 정직하게 기록하세요.",
                    style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // 달성률 슬라이더 기믹 (???% 완료)
                  Text(
                    "학습 목표 달성률: $_achievementRate%",
                    style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: _achievementRate.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 10,
                    activeColor: const Color(0xFFFFD700),
                    inactiveColor: Colors.white24,
                    label: "$_achievementRate%",
                    onChanged: (value) {
                      setModalState(() {
                        _achievementRate = value.toInt();
                      });
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  // 목표 달성 토글 여부 (예 / 아니오)
                  Text(
                    "최종 목표 달성 여부",
                    style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isGoalAchieved ? const Color(0xFFFFD700) : Colors.grey[800],
                          foregroundColor: _isGoalAchieved ? Colors.black : Colors.white,
                        ),
                        onPressed: () {
                          setModalState(() => _isGoalAchieved = true);
                          setState(() {});
                        },
                        child: Text("예", style: GoogleFonts.gowunBatang(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_isGoalAchieved ? Colors.redAccent : Colors.grey[800],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          setModalState(() => _isGoalAchieved = false);
                          setState(() {});
                        },
                        child: Text("아니오", style: GoogleFonts.gowunBatang(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "💡 완료 시 UTC 타임스탬프와 함께 서버에 전송되며,\n부모님 전용 앱/메모장으로 즉시 실시간 연동됩니다.",
                    style: GoogleFonts.gowunBatang(color: Colors.lightBlueAccent, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // 성공 시 별 게이미피케이션 가산 연동 (메인 기준 75/90 자산 예우)
                    if (_isGoalAchieved && _currentStars < _maxStars) {
                      setState(() {
                        _currentStars++;
                      });
                    }
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // 대시보드로 안전 귀환
                  },
                  child: Text(
                    "기록 영구 보관 및 제출",
                    style: GoogleFonts.gowunBatang(color: const Color(0xFFFFD700), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMissionInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.gowunBatang(color: Colors.white60, fontSize: 14)),
          Text(value, style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  // ==========================================================================
  // 🎨 원장님 명품 아트워크 배경 스케일링 및 메인 레이아웃 UI 빌더
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17), // 백그라운드 기본 암전 처리
      body: Stack(
        children: [
          // 1. 원장님의 전설적인 마법의 책 & 탑 아트워크 배경 이미지 영역
          Positioned.fill(
            child: Image.asset(
              'assets/images/Timer.png', // 리소스 경로 규격 준수
              fit: BoxFit.cover,
            ),
          ),

          // 2. 타이머 콘텐츠 정밀 수직 레이아웃 영역
          SafeArea(
            child: Column(
              children: [
                // 웅장한 로고 배치는 아트워크 내장형 텍스트를 최우선 예우하여 상단 공백 확보
                const SizedBox(height: 40),

                // 게이미피케이션 스코어 실시간 매끄러운 시각화 (75/90 황금별 연동)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFD700), width: 1),
                      ),
                      child: Text(
                        "⭐ $_currentStars / $_maxStars",
                        style: GoogleFonts.gowunBatang(
                          color: const Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // 3. 황금 별 궤도 정중앙 무대 - 실시간 카운트다운 숫자 (가독성 극대화)
                Center(
                  child: Text(
                    _formatDuration(_remainingSeconds),
                    style: GoogleFonts.gowunBatang(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFD700),
                      shadows: [
                        const Shadow(
                          color: Colors.black,
                          offset: Offset(2, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // 4. 최하단 바닥 끝 20픽셀 마진을 완벽하게 확보한 제어 인터페이스
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0), // 원장님 지정 20px 오차 없는 여백
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _isRunning ? _pauseTimer : _startTimer,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                          decoration: BoxDecoration(
                            color: _isRunning ? Colors.amber[700] : const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Text(
                            _isRunning ? "일시 중지" : "공부 시작",
                            style: GoogleFonts.gowunBatang(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
        ],
      ),
    );
  }
}