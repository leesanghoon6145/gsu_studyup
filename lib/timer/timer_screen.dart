import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:audioplayers/audioplayers.dart'; // 💡 사운드 믹스 오디오 엔진 주입 완벽 수호

class TimerScreen extends StatefulWidget {
  final String selectedSubject;
  final int selectedDurationMinutes;
  final String dynamicTestTitle;
  final DateTime? targetExamDate;
  final String selectedSoundFile;

  const TimerScreen({
    Key? key,
    required this.selectedSubject,
    required this.selectedDurationMinutes,
    required this.dynamicTestTitle,
    this.targetExamDate,
    required this.selectedSoundFile,
  }) : super(key: key);

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late int _totalSeconds;
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _isRunning = false;
  double progressPercent = 0.0; // 🌟 무지개 바 가산 제어 변수 선언 완벽 보존

  late AudioPlayer _timerAudioPlayer;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.selectedDurationMinutes * 60;
    tz.initializeTimeZones();

    _timerAudioPlayer = AudioPlayer();
    _timerAudioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerAudioPlayer.stop();
    _timerAudioPlayer.dispose();
    super.dispose();
  }

  //  지시사항 1 & 2번 결합 해결: 타이머 연산 복구 및 백색소음 동시 싱크 연동 엔진
  void _toggleTimer() async {
    try {
      if (_isRunning) {
        _timer?.cancel();
        setState(() => _isRunning = false);
        await _timerAudioPlayer.pause();
      } else {
        setState(() => _isRunning = true);

        // 백색소음 파일명이 존재할 때만 정밀 타격하여 플레이 가동
        if (widget.selectedSoundFile.isNotEmpty) {
          await _timerAudioPlayer.play(AssetSource('sounds/${widget.selectedSoundFile}'));
        }

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            if (_elapsedSeconds < _totalSeconds) {
              _elapsedSeconds++;
              // 🌟 원장님의 소중한 무지개 바 실시간 갱신 수식 복원 완료
              progressPercent = _elapsedSeconds / _totalSeconds;
            } else {
              _timer?.cancel();
              _isRunning = false;
              _timerAudioPlayer.stop();
              _showCompletionDialog();
            }
          });
        });
      }
    } catch (e) {
      debugPrint("타이머 오디오 및 기동 제어 실패: $e");
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1527),
        title: Text("학습 완료! 🎉", style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontWeight: FontWeight.bold)),
        content: Text("설정한 목표 시간을 완벽하게 달성하여 별빛을 수집했습니다.", style: GoogleFonts.gowunBatang(color: const Color(0xFFEFEFEF))),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text("확인", style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158))),
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
    return Scaffold(
      backgroundColor: const Color(0xFF050B14),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/timer.png'), fit: BoxFit.cover)),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 10, left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned.fill(
                child: Column(
                  children: [
                    const SizedBox(height: 163),
                    Builder(
                      builder: (context) {
                        final DateTime baseDate = widget.targetExamDate ?? DateTime.now();
                        final DateTime nowUtc = DateTime.now().toUtc();
                        const String targetTimeZoneId = 'Asia/Seoul';
                        final tz.Location targetLocation = tz.getLocation(targetTimeZoneId);

                        final tz.TZDateTime examTargetLocal = tz.TZDateTime(targetLocation, baseDate.year, baseDate.month, baseDate.day);
                        final DateTime examDateUtc = examTargetLocal.toUtc();
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
                            Image.asset('assets/images/crown_wings.png', width: 100, fit: BoxFit.contain),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("✧───  ", style: TextStyle(color: Color(0xFFE5C158), fontSize: 12, fontWeight: FontWeight.bold)),
                                Text(
                                  widget.dynamicTestTitle,
                                  style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.0),
                                ),
                                const Text("  ───✧", style: TextStyle(color: Color(0xFFE5C158), fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dDayString,
                              style: GoogleFonts.gowunBatang(color: const Color(0xFFFFF6D6), fontSize: 34, fontWeight: FontWeight.bold, height: 1.0, letterSpacing: 0.5),
                            ),
                          ],
                        );
                      },
                    ),
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
                            // 🌟 실시간 별 획득 현황판 스펙 완벽 보존
                            Text(
                              "실시간 별 획득 현황 :  ${_elapsedSeconds ~/ 60} / ${widget.selectedDurationMinutes} Mins",
                              style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1.0),
                        Text(
                          _formatDisplayTime(_elapsedSeconds),
                          style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 78, fontWeight: FontWeight.w700, letterSpacing: 1.0, height: 0.9),
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
                              Expanded(child: Text("🔊 ${widget.selectedSubject}", style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("실시간 집중 모드", style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 13, fontWeight: FontWeight.bold)),
                              Text("목표 시간: ${widget.selectedDurationMinutes}분", textAlign: TextAlign.end, style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 12)),
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
                                decoration: BoxDecoration(color: const Color(0xFF0D1527), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFE5C158).withOpacity(0.3), width: 1.0)),
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
                                      decoration: BoxDecoration(border: index < 5 ? Border(right: BorderSide(color: const Color(0xFFE5C158).withOpacity(0.25), width: 1.0)) : null),
                                      child: Stack(
                                        children: [
                                          if (itemProgress > 0)
                                            FractionallySizedBox(widthFactor: itemProgress, child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: rainbowGradients[index])))),
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
                                      child: Text("${currentIntervalMinutes}분\n($currentPercentage%)", textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600, height: 1.2)),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50.0),
                      child: GestureDetector(
                        onTap: _toggleTimer,
                        child: Container(
                          width: double.infinity,
                          height: 60,
                          decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/btn_start.png'), fit: BoxFit.fill)),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(_isRunning ? "PAUSE (일시 중지)" : "START FOCUS (공부 시작)", style: GoogleFonts.gowunBatang(color: const Color(0xFFFFF6D6), fontSize: 17, fontWeight: FontWeight.bold)),
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