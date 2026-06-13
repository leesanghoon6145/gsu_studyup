import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:audioplayers/audioplayers.dart';

class TimerScreen extends StatefulWidget {
  final String selectedSubject;
  final int selectedDurationMinutes;
  final String dynamicTestTitle;
  final DateTime? targetExamDate;
  final String selectedSoundFile;

  // 👑 [마이페이지 연동]: 프리미엄 VIP 회원 전선 결합 허브
  final String targetUniversity;
  final bool isVipMember;

  const TimerScreen({
    Key? key,
    required this.selectedSubject,
    required this.selectedDurationMinutes,
    required this.dynamicTestTitle,
    this.targetExamDate,
    required this.selectedSoundFile,
    this.targetUniversity = "Seoul National University (서울대학교)",
    this.isVipMember = false,
  }) : super(key: key);

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

// 👑 [감동의 애니메이션 믹스인]: 끊김 현상을 완벽 차단하기 위한 TickerProvider 사수
class _TimerScreenState extends State<TimerScreen> with SingleTickerProviderStateMixin {
  late int _totalSeconds;
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _isRunning = false;
  double progressPercent = 0.0;

  late AudioPlayer _timerAudioPlayer;

  // ==============================================================================
  // 🌌 [원장님 독점 지시]: 15초 시네마틱 무한 확장 및 별 일치 마스킹 제어실
  //    타임라인: 별 소멸(0~0.5s) → "목표"(0.5~3.0s) → 왕관+대학명(3.0~13.0s) → 별 복귀(13~15s)
  // ==============================================================================
  late AnimationController _vipAnimationController;

  // 🚨 [에러 원천 진압]: 변수의 데이터 타입을 명확히 선언하여 빨간 줄 완전 소독
  late Animation<double> _goalTextOpacity;   // "TARGET/목표" 텍스트가 부드럽게 나타났다 사라지는 곡선
  late Animation<double> _textOpacity;       // 대학명 유닛이 부드럽게 스며드는 곡선
  late Animation<double> _textScale;         // 왕관+대학명 구간 동안 줌인->유지->줌아웃되는 곡선

  int _animationCycleTick = 0;
  bool _showVipOverlay = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.selectedDurationMinutes * 60;
    tz.initializeTimeZones();

    _timerAudioPlayer = AudioPlayer();
    _timerAudioPlayer.setReleaseMode(ReleaseMode.loop);

    // 🎬 [25초 대서사시 타임라인 선언]
    _vipAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    );

    // 1. "TARGET / 목표" 텍스트 페이드 (0~2초 구간에서만 등장)
    _goalTextOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: CurveTween(curve: Curves.easeInCubic)
            .chain(Tween<double>(begin: 0.0, end: 1.0)),
        weight: 4.0,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 4.0),
      TweenSequenceItem(
        tween: CurveTween(curve: Curves.easeOutCubic)
            .chain(Tween<double>(begin: 1.0, end: 0.0)),
        weight: 4.0,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 88.0),
    ]).animate(_vipAnimationController);

    // 2. 왕관+대학명 페이드 (2~22초 구간, 줌인 -> 유지 -> 줌아웃)
    _textOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 8.0),
      TweenSequenceItem(
        tween: CurveTween(curve: Curves.easeInCubic)
            .chain(Tween<double>(begin: 0.0, end: 1.0)),
        weight: 4.0,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 64.0),
      TweenSequenceItem(
        tween: CurveTween(curve: Curves.easeOutCubic)
            .chain(Tween<double>(begin: 1.0, end: 0.0)),
        weight: 4.0,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 20.0),
    ]).animate(_vipAnimationController);

    // 3. 대학명 줌인 -> 유지 -> 줌아웃 스케일 (2~22초 구간, 웅장하고 우아한 확대/축소)
    _textScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.3), weight: 8.0),
      TweenSequenceItem(
        tween: CurveTween(curve: Curves.easeOutCubic)
            .chain(Tween<double>(begin: 0.3, end: 1.0)),
        weight: 12.0,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 56.0),
      TweenSequenceItem(
        tween: CurveTween(curve: Curves.easeInCubic)
            .chain(Tween<double>(begin: 1.0, end: 0.7)),
        weight: 12.0,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0.7), weight: 12.0),
    ]).animate(_vipAnimationController);

  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerAudioPlayer.stop();
    _timerAudioPlayer.dispose();
    _vipAnimationController.dispose();
    super.dispose();
  }

  // 👑 [정밀 우주 회전 궤도]: 15초 감동 연출 후 10분 침묵 사이클 가동
  void _runVipStarStrictRotationEngine() {
    if (!widget.isVipMember) return;

    _animationCycleTick++;

    if (_animationCycleTick == 1) {
      setState(() => _showVipOverlay = true);
      _vipAnimationController.forward(from: 0.0);
    }
    else if (_animationCycleTick == 25) {
      setState(() => _showVipOverlay = false);
    }
    else if (_animationCycleTick >= 625) {
      _animationCycleTick = 0;
    }
  }

  void _toggleTimer() async {
    try {
      if (_isRunning) {
        _timer?.cancel();
        setState(() => _isRunning = false);
        await _timerAudioPlayer.pause();
        if (widget.isVipMember) _vipAnimationController.stop();
      } else {
        setState(() => _isRunning = true);

        if (widget.selectedSoundFile.isNotEmpty) {
          await _timerAudioPlayer.play(AssetSource('sounds/${widget.selectedSoundFile}'));
        }

        if (widget.isVipMember && _elapsedSeconds == 0) {
          _animationCycleTick = 0;
          setState(() => _showVipOverlay = true);
          _vipAnimationController.forward(from: 0.0);
        }

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            if (_elapsedSeconds < _totalSeconds) {
              _elapsedSeconds++;
              progressPercent = _elapsedSeconds / _totalSeconds;
              _runVipStarStrictRotationEngine();
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
      debugPrint("타이머 제어 에러: $e");
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

  // 👑 [중복 제거]: TARGET 문구를 도려내고 오직 원장님의 프리미엄 목표 대학명만 선명하게 출력
  Widget _buildVipSmartDynamicText(String text, Color brandGolden) {
    String firstLine = "";
    String secondLine = "";

    if (text.contains('(') && text.contains(')')) {
      int openParenthesis = text.indexOf('(');
      firstLine = text.substring(0, openParenthesis).trim();
      secondLine = text.substring(openParenthesis).trim();
    } else if (text.contains(' ') && text.length > 12) {
      int middleSpace = text.indexOf(' ', text.length ~/ 2);
      if (middleSpace == -1) middleSpace = text.indexOf(' ');
      firstLine = text.substring(0, middleSpace).trim();
      secondLine = text.substring(middleSpace).trim();
    } else {
      firstLine = text;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          firstLine,
          textAlign: TextAlign.center,
          style: GoogleFonts.gowunBatang(
            color: brandGolden,
            fontWeight: FontWeight.w900, // 원장님 지시: 초고진형 진하고 두껍게 고정
            fontSize: 19.5,
            height: 1.15,
            shadows: const [
              Shadow(color: Color(0xFF050B14), offset: Offset(0, 1), blurRadius: 3),
              Shadow(color: Color(0xFF050B14), offset: Offset(0, -1), blurRadius: 3),
              Shadow(color: Color(0xFF050B14), offset: Offset(1, 0), blurRadius: 3),
              Shadow(color: Color(0xFF050B14), offset: Offset(-1, 0), blurRadius: 3),
            ],
          ),
        ),
        if (secondLine.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            secondLine,
            textAlign: TextAlign.center,
            style: GoogleFonts.gowunBatang(
              color: brandGolden,
              fontWeight: FontWeight.w900,
              fontSize: 18.0,
              height: 1.15,
              shadows: const [
                Shadow(color: Color(0xFF050B14), offset: Offset(0, 1), blurRadius: 3),
                Shadow(color: Color(0xFF050B14), offset: Offset(0, -1), blurRadius: 3),
                Shadow(color: Color(0xFF050B14), offset: Offset(1, 0), blurRadius: 3),
                Shadow(color: Color(0xFF050B14), offset: Offset(-1, 0), blurRadius: 3),
              ],
            ),
          ),
        ],
      ],
    );
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
              // ----------------------------------------------------------------------
              // ⏱️ [오리지널 순정 레이아웃 벨트]: 철통 방어 구역 (100% 원형 박제)
              // ----------------------------------------------------------------------
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

                    const SizedBox(height: 240), // 🚨 순정 마진 수치 박제 (절대 밀림 없음)

                    // 🚨 캡처로 짚어주신 317~327번 라인 오타 완전 정화 정렬 구역
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

              // ----------------------------------------------------------------------
              // 🌌 [25초 시네마틱 엔진]
              //    0~2s: "TARGET/목표" 표시 → 2~22s: 왕관+대학명 줌인→유지→줌아웃
              //    → 22~25s: 오버레이 소멸, 배경 황금별 자연 복귀
              // ----------------------------------------------------------------------
              if (widget.isVipMember && _showVipOverlay)
                Positioned(
                  top: 220,
                  left: 0, right: 0,
                  child: Center(
                    child: SizedBox(
                      width: 290,
                      height: 260,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 👑 "TARGET / 목표" 텍스트 (별이 사라진 직후 부드럽게 등장 → 2초 유지 → 사라짐)
                          AnimatedBuilder(
                            animation: _vipAnimationController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _goalTextOpacity.value,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "TARGET",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.gowunBatang(
                                        color: brandGolden,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 28,
                                        letterSpacing: 4.0,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "목표",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.gowunBatang(
                                        color: brandGolden,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 22,
                                        letterSpacing: 4.0,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // 👑 지시사항 2: 작은 점으로부터 최대 크기까지 지속 확장되는 왕관+대학명
                          AnimatedBuilder(
                            animation: _vipAnimationController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _textOpacity.value,
                                child: Transform.scale(
                                  scale: _textScale.value,
                                  child: IntrinsicWidth(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // 👑 가변 황금관: 대학교 가로폭 길이에 자석처럼 밀착 결합
                                        Image.asset(
                                          'assets/images/crown_wings.png',
                                          height: 42,
                                          fit: BoxFit.fill,
                                        ),
                                        const SizedBox(height: 0.1),
                                        _buildVipSmartDynamicText(widget.targetUniversity, brandGolden),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              Positioned(
                top: 10, left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    final double outerRadius = size.width * 0.48;
    final double innerRadius = size.width * 0.21;

    double angle = -math.pi / 2;
    final double angleStep = math.pi / 5;

    path.moveTo(cx + outerRadius * math.cos(angle), cy + outerRadius * math.sin(angle));

    for (int i = 0; i < 10; i++) {
      angle += angleStep;
      double r = (i % 2 == 0) ? innerRadius : outerRadius;
      path.lineTo(cx + r * math.cos(angle), cy + r * math.sin(angle));
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
