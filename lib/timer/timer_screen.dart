import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimerScreen extends StatefulWidget {
  final String selectedSubject;
  final int selectedDurationMinutes;
  final String dynamicTestTitle;

  const TimerScreen({
    Key? key,
    required this.selectedSubject,
    required this.selectedDurationMinutes,
    required this.dynamicTestTitle,
  }) : super(key: key);

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late int _totalSeconds;
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.selectedDurationMinutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    setState(() {
      if (_isRunning) {
        _timer?.cancel();
        _isRunning = false;
      } else {
        _isRunning = true;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            if (_elapsedSeconds < _totalSeconds) {
              _elapsedSeconds++;
            } else {
              _timer?.cancel();
              _isRunning = false;
              _showCompletionDialog();
            }
          });
        });
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1527),
        title: Text(
          "학습 완료! 🎉",
          style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontWeight: FontWeight.bold),
        ),
        content: Text(
          "설정한 목표 시간을 완벽하게 달성하여 별빛을 수집했습니다.",
          style: GoogleFonts.gowunBatang(color: const Color(0xFFEFEFEF)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // 대시보드로 복귀
            },
            child: Text(
              "확인",
              style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDisplayTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int mins = (totalSeconds % 3600) ~/ 60;
    int secs = totalSeconds % 60;

    String hourStr = hours < 10 ? "0$hours" : "$hours";
    String minStr = mins < 10 ? "0$mins" : "$mins";
    String secStr = secs < 10 ? "0$secs" : "$secs";

    return "$hourStr:$minStr:$secStr";
  }
  @override
  Widget build(BuildContext context) {
    // 실시간 별 획득 현황 분 연산
    int currentMinutes = _elapsedSeconds ~/ 60;
    double progressPercent = _totalSeconds > 0 ? _elapsedSeconds / _totalSeconds : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF050B14),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/timer.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 🛡️ 상단 뒤로가기 내비게이션 바
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              // 🏛️ 메인 콘텐츠 아키텍처 뷰포트
              Positioned.fill(
                child: Column(
                  children: [
                    // 📐 [교정 지시사항] 왕관부터 전체 요소를 10mm 하향 조정하기 위해 기존 125에서 163으로 스페이서 변경
                    const SizedBox(height: 163),

                    // 🌍 [GSU StudyUp 글로벌 수호] 전 세계 모든 시험대응 시차 동기화 D-Day 엔진
                    Builder(
                      builder: (context) {
                        DateTime nowUtc = DateTime.now().toUtc();

                        // 👑 글로벌 세팅 시트: 시험을 치르는 국가의 타깃 연도/월/일 설정
                        int examYear = 2026;
                        int examMonth = 11;
                        int examDay = 16;

                        // 💡 시차 튜닝 마스터 밸브 (한국 수능: 9 / 영국 사법시험: 0)
                        int targetUtcOffsetHours = 9;

                        DateTime examTargetLocal = DateTime(examYear, examMonth, examDay);
                        DateTime examDateUtc = examTargetLocal.subtract(Duration(hours: targetUtcOffsetHours));

                        if (nowUtc.isAfter(examDateUtc)) {
                          examTargetLocal = DateTime(examYear + 1, examMonth, examDay);
                          examDateUtc = examTargetLocal.subtract(Duration(hours: targetUtcOffsetHours));
                        }

                        int remainingHours = examDateUtc.difference(nowUtc).inHours;
                        int difference = (remainingHours / 24).ceil();
                        String dDayString = difference <= 0 ? "D-Day" : "D-$difference";

                        return Column(
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
                                const Text("✧───  ", style: TextStyle(color: Color(0xFFE5C158), fontSize: 12, fontWeight: FontWeight.bold)),
                                Text(
                                  widget.dynamicTestTitle,
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
                            const SizedBox(height: 4),
                            Text(
                              dDayString,
                              style: GoogleFonts.gowunBatang(
                                color: const Color(0xFFFFF6D6),
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    // 📐 황금 별 트랙 공간 확보용 프리셋 스페이서
                    const SizedBox(height: 238),

                    // 👑 [원장님 지시사항] 중앙 큰 별 맨 아래 끝을 기준으로 정확히 1mm(1.0) 아래 배치 고정 그룹
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 1.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, color: Color(0xFFE5C158), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              "실시간 별 획득 현황 :  $currentMinutes / ${widget.selectedDurationMinutes} Mins",
                              style: GoogleFonts.gowunBatang(
                                color: const Color(0xFFE5C158),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 1.0),
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
                      ],
                    ),

                    const Spacer(),

                    // 🔊 [학습 바 구역] 원장님 지시사항 반영: 6등분 칸별 별빛 채우기 엔진
// 🔊 [학습 바 구역] 원장님 지시사항 반영: 과목명 길이에 대응하는 2행 고정 구조
// 🔊 [학습 바 구역] 원장님 지시사항 반영: 과목명 분리 및 6색 연결 바 시스템
// 🔊 [학습 바 구역] 원장님 지시사항 반영: 2행 분리, 무지개 6등분 선 연결 바, 오버플로우 방지 엔진
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1행: 과목명 독립 배치 (오버플로우 방지용 엘리먼트 가드 적용)
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "🔊 ${widget.selectedSubject}",
                                  style: GoogleFonts.gowunBatang(
                                      color: const Color(0xFFE5C158),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold
                                  ),
                                  overflow: TextOverflow.ellipsis, // 혹시나 과목명이 너무 길면 뒤를 ...으로 깔끔하게 마감
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // 2행: "실시간 집중 모드"와 "목표 시간: ??분" 우측 절대 고정 배치
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "실시간 집중 모드",
                                style: GoogleFonts.gowunBatang(
                                    color: const Color(0xFFE5C158),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                              // 🛡️ 바 오른쪽 오버플로우 에러를 원천 차단하기 위해 텍스트 폭 가드 및 우측 고정
                              SizedBox(
                                child: Text(
                                  "목표 시간: ${widget.selectedDurationMinutes}분",
                                  textAlign: TextAlign.end,
                                  style: GoogleFonts.gowunBatang(
                                      color: Colors.white70,
                                      fontSize: 12
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 🧱 [원장님 지시사항] 빽빽하게 밀착 연결하되, 가느다란 내부 선으로 6등분 구분한 자동 무지개 바
                          LayoutBuilder(
                            builder: (context, constraints) {
                              // 빨, 주, 노, 초, 파, 보 자동 채우기 그라데이션 컬러 맵
                              final List<List<Color>> rainbowGradients = [
                                [const Color(0xFFFF4D4D), const Color(0xFFFF2A2A)], // 빨강
                                [const Color(0xFFFF9F43), const Color(0xFFFF7F11)], // 주황
                                [const Color(0xFFFECA57), const Color(0xFFFFB142)], // 노랑
                                [const Color(0xFF1DD1A1), const Color(0xFF10AC84)], // 초록
                                [const Color(0xFF54A0FF), const Color(0xFF2E86DE)], // 파랑
                                [const Color(0xFF5F27CD), const Color(0xFF341F97)], // 보라
                              ];

                              return Container(
                                width: constraints.maxWidth,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D1527),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: const Color(0xFFE5C158).withOpacity(0.3),
                                      width: 1.0
                                  ),
                                ),
                                child: Row(
                                  children: List.generate(6, (index) {
                                    // 전체 너비를 소수점 오차 없이 완전 균등하게 6등분 배치
                                    double itemWidth = (constraints.maxWidth - 2.0) / 6;
                                    double startFactor = index / 6.0;
                                    double endFactor = (index + 1) / 6.0;

                                    // 현재 집중 진행 시간에 맞춰 6칸 빌더가 개별 진행률을 자동으로 계산
                                    double itemProgress = 0.0;
                                    if (progressPercent >= endFactor) {
                                      itemProgress = 1.0;
                                    } else if (progressPercent <= startFactor) {
                                      itemProgress = 0.0;
                                    } else {
                                      itemProgress = (progressPercent - startFactor) / (endFactor - startFactor);
                                    }

                                    return Container(
                                      width: itemWidth,
                                      height: double.infinity,
                                      // 💡 칸과 칸 사이를 분리하지 않고 밀착시키되, 내부에 얇은 선으로 경계를 명확히 구분
                                      decoration: BoxDecoration(
                                        border: index < 5 ? Border(
                                          right: BorderSide(
                                            color: const Color(0xFFE5C158).withOpacity(0.25),
                                            width: 1.0,
                                          ),
                                        ) : null,
                                      ),
                                      child: Stack(
                                        children: [
                                          if (itemProgress > 0)
                                            FractionallySizedBox(
                                              widthFactor: itemProgress,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: rainbowGradients[index],
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              );
                            },
                          ),
                          // 아래 분($\%$) 인디케이터 구역으로 단 1자 오차 없이 완벽 연결...
                          // 아래 분($\%$) 인디케이터 구역으로 정상 연결...
                          const SizedBox(height: 6),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              int intervalMinutes = widget.selectedDurationMinutes ~/ 6;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(6, (index) {
                                  int currentIntervalMinutes = intervalMinutes * (index + 1);
                                  int currentPercentage = ((index + 1) / 6.0 * 100).round();
                                  double itemWidth = constraints.maxWidth / 6;

                                  return SizedBox(
                                    width: itemWidth,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "${currentIntervalMinutes}분\n($currentPercentage%)",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.gowunBatang(
                                          color: Colors.white60,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
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
                              style: GoogleFonts.gowunBatang(
                                  color: const Color(0xFFFFF6D6),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold
                              ),
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
        ),
      ),
    );
  }
}