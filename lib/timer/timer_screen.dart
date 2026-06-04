import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// 💡 글로벌 타임존 무결성 수호를 위한 패키지 임포트
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TimerScreen extends StatefulWidget {
  final String selectedSubject;
  final int selectedDurationMinutes;
  final String dynamicTestTitle;
  // 📅 대시보드 달력 엔진에서 넘겨주는 목표 시험 날짜를 안전하게 수신합니다.
  final DateTime? targetExamDate;

  const TimerScreen({
    Key? key,
    required this.selectedSubject,
    required this.selectedDurationMinutes,
    required this.dynamicTestTitle,
    this.targetExamDate, // 인자 확장 완료
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
    // 🌟 타임존 데이터베이스 초기화 엔진 기동
    tz.initializeTimeZones();
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
              Navigator.of(context).pop();
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
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              Positioned.fill(
                child: Column(
                  children: [
                    const SizedBox(height: 163),

                    // 🌍 [GSU StudyUp 글로벌 수호] IANA Time Zone 기반 초정밀 D-Day 연산 엔진
                    Builder(
                      builder: (context) {
                        // 1. 달력에서 선택된 날짜가 오면 해당 날짜를 쓰고, 없으면 안전 백업용으로 오늘 날짜 처리
                        final DateTime baseDate = widget.targetExamDate ?? DateTime.now();

                        // 2. 전 세계 현재 순간을 순수 UTC 시간선으로 동기화
                        final DateTime nowUtc = DateTime.now().toUtc();

                        // 3. IANA 타임존 ID 자동 추적 지정 (한국 기준 Asia/Seoul)
                        // 영국의 경우 Europe/London, 미국의 경우 America/New_York 등으로 변경 가능
                        const String targetTimeZoneId = 'Asia/Seoul';
                        final tz.Location targetLocation = tz.getLocation(targetTimeZoneId);

                        // 4. 지정된 국가의 시험 당일 00시 00분 타임존 값 생성
                        final tz.TZDateTime examTargetLocal = tz.TZDateTime(
                          targetLocation,
                          baseDate.year,
                          baseDate.month,
                          baseDate.day,
                        );

                        // 5. 타임존이 결합된 목표 시점을 절대 UTC 타임스탬프로 수평 동기화
                        final DateTime examDateUtc = examTargetLocal.toUtc();

                        // 6. 현재 UTC와 시험 목표 UTC 간의 순수한 시간 시차(Hours) 계산 후 Day로 올림 가공
                        final int remainingHours = examDateUtc.difference(nowUtc).inHours;
                        final int difference = (remainingHours / 24).ceil();

                        String dDayString;
                        if (difference < 0) {
                          dDayString = "D+${difference.abs()}";
                        } else if (difference == 0) {
                          dDayString = "D-Day";
                        } else {
                          dDayString = "D-$difference";
                        }

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

                    // 📐 아래 기존의 모든 그래픽 레이아웃 및 완벽한 무지개 바 코드 블록 완전 보존
                    const SizedBox(height: 240),

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
                              "실시간 별 획득 현황 :  ${_elapsedSeconds ~/ 60} / ${widget.selectedDurationMinutes} Mins",
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

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
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

                          LayoutBuilder(
                            builder: (context, constraints) {
                              final List<List<Color>> rainbowGradients = [
                                [const Color(0xFFFF4D4D), const Color(0xFFFF2A2A)],
                                [const Color(0xFFFF9F43), const Color(0xFFFF7F11)],
                                [const Color(0xFFFECA57), const Color(0xFFFFB142)],
                                [const Color(0xFF1DD1A1), const Color(0xFF10AC84)],
                                [const Color(0xFF54A0FF), const Color(0xFF2E86DE)],
                                [const Color(0xFF5F27CD), const Color(0xFF341F97)],
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
                                    double itemWidth = (constraints.maxWidth - 2.0) / 6;
                                    double startFactor = index / 6.0;
                                    double endFactor = (index + 1) / 6.0;

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
                    const Spacer(flex: 2),
                    const Spacer(flex: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50.0),
                      child: GestureDetector(
                        onTap: _toggleTimer,
                        child: Container(
                          width: double.infinity,
                          height: 60,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/btn_start.png'),
                              fit: BoxFit.fill,
                            ),
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _isRunning ? "PAUSE (일시 중지)" : "START FOCUS (공부 시작)",
                                  style: GoogleFonts.gowunBatang(
                                      color: const Color(0xFFFFF6D6),
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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