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

  // 👑 [회의 반영]: 마이페이지 직통 데이터 전선 수혈 파이프라인 개방
  final String targetUniversity;
  final bool isVipMember;

  const TimerScreen({
    Key? key,
    required this.selectedSubject,
    required this.selectedDurationMinutes,
    required this.dynamicTestTitle,
    this.targetExamDate,
    required this.selectedSoundFile,
    this.targetUniversity = "Seoul National University (서울대학교)", // 안심 디폴트값 배정
    this.isVipMember = false, // 기본 FREE 회원 락
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

  // 👑 [애니메이션 상태 머신 코어]: 5분(300초) 주기 숨쉬는 명문대 텍스트 트리거 제어실
  int _animationCycleTick = 0; // 주기 안에서 현재 초수를 카운트 (0 ~ 305초 순환)
  String _animatedText = "";   // 별 중앙에 현재 표출할 글자
  double _textOpacity = 0.0;   // 은은한 페이드 인/아웃 투명도 수식

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

  // 👑 [VIP 전용 타임라인 알고리즘]: 1초마다 시계와 싱크되어 5분 주기 순환 연산 처리
  void _runVipAuraAnimationLogic() {
    if (!widget.isVipMember) return; // 일반 회원은 가두리 락 발동 차단

    _animationCycleTick++;

    if (_animationCycleTick == 1) {
      // 1초째: "목표" 글자 세팅 및 서서히 피어오름
      _animatedText = "목표";
      _textOpacity = 1.0;
    } else if (_animationCycleTick == 3) {
      // 3초째: 2초 머물렀으니 서서히 사라짐
      _textOpacity = 0.0;
    } else if (_animationCycleTick == 5) {
      // 5초째: 사라지자마자 "내가 마이페이지에 입력한 대학" 장착 후 서서히 피어오름
      _animatedText = widget.targetUniversity;
      _textOpacity = 1.0;
    } else if (_animationCycleTick == 7) {
      // 7초째: 대학 이름 2초 머물렀으니 다시 서서히 완전 소멸
      _textOpacity = 0.0;
    } else if (_animationCycleTick >= 307) {
      // 7초 이후부터 정확히 300초(5분) 동안은 완전히 소멸한 침묵 상태를 유지하다가,
      // 307초(5분 7초)가 도달하는 순간 틱 카운터를 초기화하여 "목표"부터 무한 궤도 재출발!
      _animationCycleTick = 0;
    }
  }

  void _toggleTimer() async {
    try {
      if (_isRunning) {
        _timer?.cancel();
        setState(() => _isRunning = false);
        await _timerAudioPlayer.pause();
      } else {
        setState(() => _isRunning = true);

        if (widget.selectedSoundFile.isNotEmpty) {
          await _timerAudioPlayer.play(AssetSource('sounds/${widget.selectedSoundFile}'));
        }

        // 최초 기동 타임에 VIP 회원이면 강제 0초 즉시 시발점 기폭
        if (widget.isVipMember && _elapsedSeconds == 0) {
          _animationCycleTick = 0;
          _animatedText = "목표";
          _textOpacity = 1.0;
        }

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            if (_elapsedSeconds < _totalSeconds) {
              _elapsedSeconds++;
              progressPercent = _elapsedSeconds / _totalSeconds;

              // 👑 1초 시계 흘러갈 때 VIP 연쇄 애니메이션 엔진 실시간 동시 가동
              _runVipAuraAnimationLogic();
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
    const Color brandGolden = Color(0xFFE5C158);

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
                            Text(
                              "실시간 별 획득 현황 :  ${_elapsedSeconds ~/ 60} / ${widget.selectedDurationMinutes} Mins",
                              style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1.0),

                        // 👑 [하이라이트 마스터피스 구역]: 중앙 숫자 시계 상단에 숨쉬는 명문대 텍스트 투영
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // ⏱️ 순정 숫자 초시계 레이아웃은 그대로 존재
                            Text(
                              _formatDisplayTime(_elapsedSeconds),
                              style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 78, fontWeight: FontWeight.w700, letterSpacing: 1.0, height: 0.9),
                            ),

                            // 👑 VIP 작동 시 황금빛 그라데이션 광채를 품고 숫자를 덮으며 웅장하게 피어오르는 목표 대학 레이어
                            if (widget.isVipMember)
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 600), // 0.6초 은은한 스르륵 효과
                                opacity: _textOpacity,
                                child: Container(
                                  width: 290, height: 80,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF050B14).withOpacity(0.95), // 숫자를 부드럽게 가리는 블랙 아우라 베이스
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _animatedText,
                                        style: GoogleFonts.gowunBatang(
                                            color: brandGolden,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 26, // 거대하고 웅장한 아우라 폰트 스케일
                                            shadows: [
                                              BoxShadow(color: brandGolden.withOpacity(0.6), blurRadius: 10, spreadRadius: 4)
                                            ]
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
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