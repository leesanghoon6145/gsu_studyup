import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerScreen extends StatefulWidget {
  final String selectedSubject;
  final int selectedDurationMinutes;
  final String dynamicTestTitle;
  final DateTime? targetExamDate;
  final String selectedSoundFile;

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

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin {
  late int _totalSeconds;
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _isRunning = false;
  double progressPercent = 0.0;

  late AudioPlayer _timerAudioPlayer;

  late AnimationController _targetController;
  late AnimationController _univController;

  late Animation<double> _targetOpacity;
  late Animation<double> _targetScale;
  late Animation<double> _univOpacity;
  late Animation<double> _univScale;

  int _animationCycleTick = 0;
  bool _showVipOverlay = false;
  bool _isTargetPhase = true;

  late String _currentUniversity;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.selectedDurationMinutes;

    _currentUniversity = widget.targetUniversity;
    _initializeAndSyncUniversity();

    tz.initializeTimeZones();
    _timerAudioPlayer = AudioPlayer();
    _timerAudioPlayer.setReleaseMode(ReleaseMode.loop);

    _targetController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _targetOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)), weight: 37.5),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 25.0),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 37.5),
    ]).animate(_targetController);

    _targetScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.2, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 37.5),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 25.0),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.7).chain(CurveTween(curve: Curves.easeInCubic)), weight: 37.5),
    ]).animate(_targetController);

    _univController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 19),
    );

    _univOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)), weight: 36.8),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 26.4),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 36.8),
    ]).animate(_univController);

    _univScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.05, end: 1.2).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 36.8),
      TweenSequenceItem(tween: ConstantTween<double>(1.2), weight: 26.4),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 0.05).chain(CurveTween(curve: Curves.easeInCubic)), weight: 36.8),
    ]).animate(_univController);

    _targetController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _showVipOverlay) {
        setState(() {
          _isTargetPhase = false;
        });
        _univController.forward(from: 0.0);
      }
    });

    // 👑 [DKE 이어하기 엔진]: 빌드 완료 직후 동일 과목 캐싱 이력 체크 진입
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkResumeInterceptionData();
    });
  }

  // 👑 [DKE 이어하기 엔진 제어실]: 진입 시 임시저장 내역 추적 매칭 구조
  Future<void> _checkResumeInterceptionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? tempSubject = prefs.getString('dke_temp_subject');
      final int? tempSeconds = prefs.getInt('dke_temp_elapsed');

      if (tempSubject == widget.selectedSubject && tempSeconds != null && tempSeconds > 0) {
        const Color brandGolden = Color(0xFFE5C158);
        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0D1527),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Column(
              children: [
                Text('Would you like to continue from where you left off?', textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Text('(이어서 학습하시겠습니까?)', textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () async {
                  // 아니오 -> 처음부터 리셋 진행
                  await prefs.remove('dke_temp_subject');
                  await prefs.remove('dke_temp_elapsed');
                  Navigator.of(context).pop();
                },
                child: Text('NO (아니오)', style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: brandGolden, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () {
                  // 예 -> 데이터 바인딩 로드 진행
                  setState(() {
                    _elapsedSeconds = tempSeconds;
                    progressPercent = _elapsedSeconds / _totalSeconds;
                  });
                  Navigator.of(context).pop();
                },
                child: Text('YES (예)', style: GoogleFonts.gowunBatang(color: const Color(0xFF030712), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint("임시저장 추적 오류: $e");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSavedUniversity();
  }

  Future<void> _initializeAndSyncUniversity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedUniv = prefs.getString('saved_target_university');

      if (savedUniv == null || savedUniv.isEmpty) {
        await prefs.setString('saved_target_university', widget.targetUniversity);
        setState(() {
          _currentUniversity = widget.targetUniversity;
        });
      } else {
        setState(() {
          _currentUniversity = savedUniv;
        });
      }
    } catch (e) {
      debugPrint("초기 대학명 동기화 에러: $e");
    }
  }

  Future<void> _loadSavedUniversity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedUniv = prefs.getString('saved_target_university');

      if (savedUniv != null && savedUniv.isNotEmpty) {
        if (_currentUniversity != savedUniv) {
          setState(() {
            _currentUniversity = savedUniv;
          });
        }
      }
    } catch (e) {
      debugPrint("저장소 대학명 로드 에러: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerAudioPlayer.stop();
    _timerAudioPlayer.dispose();
    _targetController.dispose();
    _univController.dispose();
    super.dispose();
  }

  void _runVipStarStrictRotationEngine() {
    if (!widget.isVipMember) return;
    _animationCycleTick++;

    if (_animationCycleTick == 1) {
      setState(() {
        _showVipOverlay = true;
        _isTargetPhase = true;
      });
      _univController.stop();
      _targetController.forward(from: 0.0);
    }
    else if (_animationCycleTick == 28) {
      setState(() {
        _showVipOverlay = false;
      });
    }
    else if (_animationCycleTick >= 627) {
      _animationCycleTick = 0;
    }
  }

  void _toggleTimer() async {
    try {
      if (_isRunning) {
        _timer?.cancel();
        setState(() => _isRunning = false);
        await _timerAudioPlayer.pause();
        if (widget.isVipMember) {
          _targetController.stop();
          _univController.stop();
        }
        _showPauseChoiceDialog();
      } else {
        setState(() => _isRunning = true);
        if (widget.selectedSoundFile.isNotEmpty) {
          await _timerAudioPlayer.play(AssetSource('sounds/${widget.selectedSoundFile}'));
        }
        if (widget.isVipMember && _elapsedSeconds == 0) {
          _animationCycleTick = 0;
          setState(() {
            _showVipOverlay = true;
            _isTargetPhase = true;
          });
          _targetController.forward(from: 0.0);
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
      debugPrint("타이머 에러: $e");
    }
  }

  // 👑 [지시 반영]: 첫 중단 팝업 문구 및 데이터 임시 세이브 라우팅 개조 완료
  void _showPauseChoiceDialog() {
    const Color brandGolden = Color(0xFFE5C158);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1527),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Text('Are you sure you want to stop learning?', textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text('(학습을 중단하시겠습니까?)', textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () { Navigator.of(context).pop(); _toggleTimer(); },
            child: Text('RESUME (재시작)', style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandGolden, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              // 끝내기 클릭 시 임시 캐시 디스크 킵 기동
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('dke_temp_subject', widget.selectedSubject);
              await prefs.setInt('dke_temp_elapsed', _elapsedSeconds);

              if (!mounted) return;
              Navigator.of(context).pop();
              _showRecordWarningDialog();
            },
            child: Text('FINISH (끝내기)', style: GoogleFonts.gowunBatang(color: const Color(0xFF030712), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 👑 [지시 반영]: 두 번째 중단 안내 경고 팝업 규칙 개조 완료
  void _showRecordWarningDialog() {
    const Color brandGolden = Color(0xFFE5C158);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1527),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Text('Please leave a record of your efforts! The more records you have, the more accurate the learning analysis will be.', textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Text('(노력의 기록을 남겨주세요! 기록이 많을 수록 학습분석이 더욱 정확해집니다.)', textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandGolden, minimumSize: const Size(140, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () { Navigator.of(context).pop(); _showStudyInputFieldForm(); },
            child: Text('WRITE RECORD (기록하기)', style: GoogleFonts.gowunBatang(color: const Color(0xFF030712), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 👑 [지시 반영]: 학습 탑 완수 성공 다이얼로그 개조 완료
  void _showCompletionDialog() {
    const Color brandGolden = Color(0xFFE5C158);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1527),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Text('Good job! You have successfully achieved your learning goals.', textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text('(수고 하셨습니다. 학습 목표를 성공적으로 달성 하였습니다.)', textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showGrowthBridgeDialog(); // 중간 징검다리 팝업으로 라우팅 이행
              },
              child: Text("OK (확인)", style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 16))
          ),
        ],
      ),
    );
  }

  // 👑 [지시 반영]: 완수와 기록장 사이의 중간 성장의 한 걸음 징검다리 팝업 완전체 구축
  void _showGrowthBridgeDialog() {
    const Color brandGolden = Color(0xFFE5C158);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1527),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Text('Record a step of your growth.\nThe more records you have, the more accurate the learning analysis will be.', textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Text('(성장의 한 걸음을 기록해 보세요\n기록이 많을 수록 학습분석이 더욱 정확해집니다.)', textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showStudyInputFieldForm();
              },
              child: Text("OK (확인)", style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 16))
          ),
        ],
      ),
    );
  }

  // 👑 [지시 반영]: DKE 대원칙이 적용된 프리미엄 선택형 데이터 인풋 기록장 폼 대개조 완료
  void _showStudyInputFieldForm() {
    const Color brandGolden = Color(0xFFE5C158);
    final TextEditingController detailController = TextEditingController();
    final TextEditingController scoreController = TextEditingController();
    final TextEditingController nextGoalController = TextEditingController(); // 다음 목표 추가

    // 선택형 가변 데이터 싱크 벨트 선언
    int selectedUnderstanding = 100; // 20, 40, 60, 80, 100
    String selectedDifficulty = '보통'; // 매우어려움, 어려움, 보통, 쉬움
    String selectedFocus = '보통'; // 높음, 보통, 낮음
    String selectedCondition = '보통'; // 좋음, 보통, 피곤함
    bool isIncorrectNoted = true; // 오답노트 보존 상태

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0D1527),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: brandGolden, width: 1)),
          title: Column(
            children: [
              Text('STUDY RECORD', style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 23)),
              Text('(학습 기록 작성)', style: GoogleFonts.notoSansKr(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 과목명 자동생성 블록
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('SUBJECT (과목) : ', style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(widget.selectedSubject, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), softWrap: true),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 상세내용 인풋
                  Text('DETAILS (상세 내용)', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: detailController,
                    maxLines: 2,
                    style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g., Solved concepts and problems.\n(예: 개념 및 문제풀이 함)',
                      hintStyle: GoogleFonts.notoSansKr(color: Colors.white.withOpacity(0.34), fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF050B14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 점수 인풋
                  Text('SCORE (점수)', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: scoreController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '100',
                      hintStyle: GoogleFonts.rajdhani(color: Colors.white24, fontSize: 18),
                      suffixText: 'Points (점)',
                      suffixStyle: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF050B14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🚨 [철칙 수호]: 오답노트 상태 유지 선언 구역
                  Text('INCORRECT NOTE STATUS (오답노트 상태)', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFF050B14), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => isIncorrectNoted = true),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(color: isIncorrectNoted ? brandGolden : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                              child: Text('COMPLETED (정리함)', style: GoogleFonts.notoSansKr(color: isIncorrectNoted ? const Color(0xFF030712) : Colors.white60, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => isIncorrectNoted = false),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(color: !isIncorrectNoted ? brandGolden : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                              child: Text('NOT YET (정리 안함)', style: GoogleFonts.notoSansKr(color: !isIncorrectNoted ? const Color(0xFF030712) : Colors.white60, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🎯 [지시 반영 선택 칩]: UNDERSTANDING (이해도)
                  Text('UNDERSTANDING (이해도)', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [20, 40, 60, 80, 100].map((val) {
                        final bool isSel = selectedUnderstanding == val;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            label: Text('$val%', style: GoogleFonts.rajdhani(color: isSel ? const Color(0xFF030712) : Colors.white, fontWeight: FontWeight.bold)),
                            selected: isSel,
                            selectedColor: brandGolden,
                            backgroundColor: const Color(0xFF050B14),
                            onSelected: (_) => setDialogState(() => selectedUnderstanding = val),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🎯 [지시 반영 선택 칩]: DIFFICULTY (난이도)
                  Text('DIFFICULTY (난이도)', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6.0,
                    children: ['매우어려움', '어려움', '보통', '쉬움'].map((val) {
                      final bool isSel = selectedDifficulty == val;
                      return ChoiceChip(
                        label: Text(val, style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        selected: isSel,
                        selectedColor: brandGolden,
                        backgroundColor: const Color(0xFF050B14),
                        onSelected: (_) => setDialogState(() => selectedDifficulty = val),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 🎯 [지시 반영 선택 칩]: CONCENTRATION (집중도)
                  Text('CONCENTRATION (집중도)', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: ['높음', '보통', '낮음'].map((val) {
                      final bool isSel = selectedFocus == val;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label: Text(val, style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          selected: isSel,
                          selectedColor: brandGolden,
                          backgroundColor: const Color(0xFF050B14),
                          onSelected: (_) => setDialogState(() => selectedFocus = val),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 🎯 [지시 반영 선택 칩]: CONDITION (학습 컨디션 이모지 일체형)
                  Text('LEARNING CONDITION (학습 컨디션)', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      {'label': '좋음', 'emoji': '😊'},
                      {'label': '보통', 'emoji': '😐'},
                      {'label': '피곤함', 'emoji': '😴'}
                    ].map((item) {
                      final String val = item['label']!;
                      final String emoji = item['emoji']!;
                      final bool isSel = selectedCondition == val;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label: Text('$emoji $val', style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          selected: isSel,
                          selectedColor: brandGolden,
                          backgroundColor: const Color(0xFF050B14),
                          onSelected: (_) => setDialogState(() => selectedCondition = val),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 🎯 [지시 반영]: NEXT GOAL (다음 목표 직접 기록란)
                  Text('NEXT GOAL (다음 목표)', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nextGoalController,
                    style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g., Advanced function problems (예: 함수 심화문제)',
                      hintStyle: GoogleFonts.notoSansKr(color: Colors.white.withOpacity(0.34), fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF050B14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: brandGolden, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () async {
                // 임시저장 내역 무력화 소독 진행
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('dke_temp_subject');
                await prefs.remove('dke_temp_elapsed');

                final Map<String, dynamic> dkeFinalPacket = {
                  'subject': widget.selectedSubject,
                  'details': detailController.text.trim(),
                  'score': int.tryParse(scoreController.text.trim()) ?? 0,
                  'incorrectNote': isIncorrectNoted ? '정리함' : '정리 안함',
                  'understanding': selectedUnderstanding,
                  'difficulty': selectedDifficulty,
                  'concentration': selectedFocus,
                  'condition': selectedCondition,
                  'nextGoal': nextGoalController.text.trim(),
                  'timestamp': DateTime.now().toUtc().toString(),
                };
                debugPrint("👑 DKE 글로벌 마스터 저장 데이터 연동 패킷 성공: $dkeFinalPacket");

                if (!mounted) return;
                Navigator.of(context).pop();
                _showFinalSubjectSetupRedirectDialog(); // 최종 대시보드 리다이렉션 징검다리 호출
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('SAVE RECORD', textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: const Color(0xFF030712), fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('(성장 데이터 저장)', textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: const Color(0xFF030712), fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 👑 [지시 반영]: 저장 처리 후 로비 대시보드로 복귀 자동 강제 이동 제어 다이얼로그
  void _showFinalSubjectSetupRedirectDialog() {
    const Color brandGolden = Color(0xFFE5C158);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1527),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Text('Set your next learning subject and target time.\nPlanned learning is the beginning of steady growth.', textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Text('(다음 학습 과목과 목표 시간을 설정해 보세요\n계획적인 학습은 꾸준한 성장의 시작입니다.)', textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 현재 다이얼로그 닫기
              // 👑 [자동저장 후 로비 복귀 연동]: 현재 화면 스택을 날리고 홈 대시보드로 다이렉트 자동 이동
              Navigator.of(context).pop();
            },
            child: Text("OK (확인)", style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  String _formatDisplayTime(int totalSeconds) {
    int mins = totalSeconds ~/ 60;
    int secs = totalSeconds % 60;
    String minStr = mins < 10 ? "0$mins" : "$mins";
    String secStr = secs < 10 ? "0$secs" : "$secs";
    return "00:$minStr:$secStr";
  }

  Widget _buildVipSmartDynamicText(String text, Color brandGolden) {
    String firstLine = ""; String secondLine = "";
    if (text.contains('(') && text.contains(')')) {
      int openParenthesis = text.indexOf('(');
      firstLine = text.substring(0, openParenthesis).trim();
      secondLine = text.substring(openParenthesis).trim();
    } else if (text.contains(' ') && text.length > 12) {
      int middleSpace = text.indexOf(' ', text.length ~/ 2);
      if (middleSpace == -1) middleSpace = text.indexOf(' ');
      firstLine = text.substring(0, middleSpace).trim();
      secondLine = text.substring(middleSpace).trim();
    } else { firstLine = text; }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(firstLine, textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.w900, fontSize: 19.5, height: 1.15, shadows: const [Shadow(color: Color(0xFF050B14), offset: Offset(0, 1), blurRadius: 3)])),
        if (secondLine.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(secondLine, textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.w900, fontSize: 18.0, height: 1.15, shadows: const [Shadow(color: Color(0xFF050B14), offset: Offset(0, 1), blurRadius: 3)])),
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
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/timer.png'), fit: BoxFit.cover)),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    const SizedBox(height: 163),
                    Builder(builder: (context) {
                      final DateTime baseDate = widget.targetExamDate ?? DateTime.now();
                      final DateTime nowUtc = DateTime.now().toUtc();
                      final tz.Location targetLocation = tz.getLocation('Asia/Seoul');
                      final tz.TZDateTime examTargetLocal = tz.TZDateTime(targetLocation, baseDate.year, baseDate.month, baseDate.day);
                      final int difference = (examTargetLocal.toUtc().difference(nowUtc).inHours / 24).ceil();
                      String dDayString = difference < 0 ? "D+${difference.abs()}" : (difference == 0 ? "D-Day" : "D-$difference");
                      return Column(mainAxisSize: MainAxisSize.min, children: [
                        Image.asset('assets/images/crown_wings.png', width: 100, fit: BoxFit.contain),
                        const SizedBox(height: 2),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Text("✧───  ", style: TextStyle(color: Color(0xFFE5C158), fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(widget.dynamicTestTitle, style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                          const Text("  ───✧", style: TextStyle(color: Color(0xFFE5C158), fontSize: 12, fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 4),
                        Text(dDayString, style: GoogleFonts.gowunBatang(color: const Color(0xFFFFF6D6), fontSize: 34, fontWeight: FontWeight.bold, height: 1.0, letterSpacing: 0.5)),
                      ]);
                    }),
                    const SizedBox(height: 240),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.star, color: Color(0xFFE5C158), size: 16),
                        const SizedBox(width: 6),
                        Text("배속 실험 모드 가동 :  $_elapsedSeconds / ${widget.selectedDurationMinutes} Secs", style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      ]),
                      const SizedBox(height: 1.0),
                      Text(_formatDisplayTime(_elapsedSeconds), style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 78, fontWeight: FontWeight.w700, letterSpacing: 1.0, height: 0.9)),
                    ]),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [Expanded(child: Text("🔊 ${widget.selectedSubject}", style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))]),
                        const SizedBox(height: 4),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text("실시간 집중 모드 (실험)", style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 13, fontWeight: FontWeight.bold)),
                          Text("목표 시간: ${widget.selectedDurationMinutes}분", textAlign: TextAlign.end, style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 10),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final List<Color> rainbowColors = [
                              const Color(0xFFFF3B30),
                              const Color(0xFFFF9500),
                              const Color(0xFFFFCC00),
                              const Color(0xFF34C759),
                              const Color(0xFF007AFF),
                              const Color(0xFF5856D6),
                            ];
                            return Container(
                              width: constraints.maxWidth,
                              height: 18,
                              decoration: BoxDecoration(
                                  color: const Color(0xFF0D1527),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFE5C158).withOpacity(0.3), width: 1.0)
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
                                        border: index < 5 ? Border(right: BorderSide(color: const Color(0xFFE5C158).withOpacity(0.25), width: 1.0)) : null
                                    ),
                                    child: Stack(
                                      children: [
                                        if (itemProgress > 0)
                                          FractionallySizedBox(
                                            widthFactor: itemProgress,
                                            child: Container(color: rainbowColors[index]),
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
                            double interval = widget.selectedDurationMinutes / 6.0;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(6, (index) {
                                double currentInterval = interval * (index + 1);
                                int currentPercentage = ((index + 1) / 6.0 * 100).round();
                                double itemWidth = constraints.maxWidth / 6;
                                return SizedBox(
                                  width: itemWidth,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                        "${currentInterval.toStringAsFixed(1)}초\n($currentPercentage%)",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1.2)
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ]),
                    ),
                    const Spacer(flex: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50.0),
                      child: GestureDetector(
                        onTap: _toggleTimer,
                        child: Container(
                          width: double.infinity, height: 60,
                          decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/btn_start.png'), fit: BoxFit.fill)),
                          child: Center(child: Text(_isRunning ? "PAUSE (일시 중지)" : "START FOCUS (공부 시작)", style: GoogleFonts.gowunBatang(color: const Color(0xFFFFF6D6), fontSize: 17, fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              if (widget.isVipMember && _showVipOverlay)
                Positioned.fill(
                  child: Center(
                    child: SizedBox(
                      width: 340, height: 300,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isTargetPhase)
                            AnimatedBuilder(
                              animation: _targetController,
                              builder: (context, child) => Opacity(opacity: _targetOpacity.value, child: Transform.scale(scale: _targetScale.value, child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Text("TARGET", textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: 4.0)),
                                const SizedBox(height: 6),
                                Text("목표", textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 4.0)),
                              ]))),
                            ),
                          if (!_isTargetPhase)
                            AnimatedBuilder(
                              animation: _univController,
                              builder: (context, child) => Opacity(opacity: _univOpacity.value, child: Transform.scale(scale: _univScale.value, child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Image.asset('assets/images/crown_wings.png', height: 42, fit: BoxFit.contain),
                                const SizedBox(height: 4),
                                _buildVipSmartDynamicText(_currentUniversity, brandGolden),
                              ]))),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(top: 10, left: 10, child: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 22), onPressed: () => Navigator.of(context).pop())),
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