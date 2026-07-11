import 'dart:convert'; // 🎯 과목별 객체 데이터 인코딩용 패키지 주입
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
// 👑 파일 트리 구조 분석에 따른 무결점 순정 상대 경로 임포트 고정 완료
import '../square/my_page_screen.dart';
import '../planner/widgets/study_timelines.dart'; // 타임라인 연동용 임포트

class TimerScreen extends StatefulWidget {
  final String selectedSubject;
  final int selectedDurationMinutes;
  final String dynamicTestTitle;
  final DateTime? targetExamDate;
  final String selectedSoundFile;
  final DateTime? targetExamEndDate;
  final String prepPeriodStr;
  final bool needTimelineGen;
  final String targetUniversity;
  final bool isVipMember;

  const TimerScreen({
    Key? key,
    required this.selectedSubject,
    required this.selectedDurationMinutes,
    required this.dynamicTestTitle,
    this.targetExamDate,
    required this.targetExamEndDate,
    required this.prepPeriodStr,
    required this.needTimelineGen,
    required this.selectedSoundFile,
    this.targetUniversity = "Seoul National University (서울대학교)",
    this.isVipMember = false,
  }) : super(key: key);
  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin {
  // 타임라인 관련 상태 변수
  late DateTime _currentSelectedDate;
  List<Map<String, String>> _activeTimeline = [];

  late int _totalSeconds;
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _isRunning = false;
  double progressPercent = 0.0;

  late AudioPlayer _timerAudioPlayer;

  // 👑 10분 락 연동용 초정밀 타이밍 제어 변수 스펙
  int _animationCycleSeconds = 0;
  bool _showVipOverlay = false;

  late String _currentUniversity;
  String _currentLanguageCode = 'ko';
  bool _currentIsVip = false; // 👈 🎯 영구 동기화용 실시간 VIP 상태 필터 스펙 추가

  // 👑 하단 자식 애니메이션 엔진을 타이머 화면에서 직접 흔들어 깨우기 위한 고유 Key 부품 신설
  final GlobalKey<_DkeBigStarTargetAnimationModuleState> _animKey = GlobalKey<_DkeBigStarTargetAnimationModuleState>();

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.selectedDurationMinutes;

    // 초기값 셋팅
    _currentUniversity = widget.targetUniversity;
    _currentIsVip = widget.isVipMember;

    // 타임라인 초기화
    _currentSelectedDate = DateTime.now();
    _updateActiveTimeline();

    tz.initializeTimeZones();
    _timerAudioPlayer = AudioPlayer();
    _timerAudioPlayer.setReleaseMode(ReleaseMode.loop);

    // ⚡ [0초 정각 초강력 동기화 트리거]: 화면이 픽셀로 안착하자마자 기기 저장 데이터를 강제 복원
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _forceSyncSavedDataOnStartup();
      _checkResumeInterceptionData();
    });
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _currentSelectedDate = newDate;
      _updateActiveTimeline();
    });
  }

  void _updateActiveTimeline() {
    _activeTimeline = StudyTimelines.getTimelineForDate(
      _currentSelectedDate,
      widget.targetExamDate ?? DateTime.now(),
    );
  }

  // 👑 🎯 요구사항 완전 해결 장치: 앱을 완전히 껐다 켜도 마이페이지 데이터 백업 세션을 100% 즉시 복원하는 유일한 마스터 스케줄러
  Future<void> _forceSyncSavedDataOnStartup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedUniv = prefs.getString('saved_target_university');
      final String savedLang = prefs.getString('saved_language_code') ?? 'ko';
      final bool savedVipStatus = prefs.getBool('saved_vip_status') ?? widget.isVipMember;

      if (!mounted) return;

      setState(() {
        if (savedUniv != null && savedUniv.isNotEmpty) {
          _currentUniversity = savedUniv;
        }
        _currentLanguageCode = savedLang;
        _currentIsVip = savedVipStatus; // 👈 껐다 켜도 마이페이지 VIP 인증 내역을 완벽하게 계승
      });
    } catch (e) {
      debugPrint("앱 기동 즉시 저장소 강제 복원 에러: $e");
    }
  }

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
              Navigator.canPop(context) ? ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () async {
                  await prefs.remove('dke_temp_subject');
                  await prefs.remove('dke_temp_elapsed');
                  Navigator.of(context).pop();
                },
                child: Text('NO (아니오)', style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold)),
              ) : const SizedBox.shrink(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: brandGolden, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () {
                  setState(() {
                    _elapsedSeconds = tempSeconds;
                    progressPercent = _elapsedSeconds / _totalSeconds;
                    _animationCycleSeconds = _elapsedSeconds % 630;
                    if (_animationCycleSeconds < 30) {
                      _showVipOverlay = true;
                    }
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

  Future<void> _loadSavedUniversity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedUniv = prefs.getString('saved_target_university');
      final String savedLang = prefs.getString('saved_language_code') ?? 'ko';
      final bool savedVipStatus = prefs.getBool('saved_vip_status') ?? widget.isVipMember;

      if (savedUniv != null && savedUniv.isNotEmpty) {
        if (_currentUniversity != savedUniv || _currentLanguageCode != savedLang || _currentIsVip != savedVipStatus) {
          setState(() {
            _currentUniversity = savedUniv;
            _currentLanguageCode = savedLang;
            _currentIsVip = savedVipStatus;
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
    super.dispose();
  }

  // 👑 🎯 10분 주기 무한 루프 제어 엔진 교차 검증 완료판
  void _runVipStarStrictRotationEngine() {
    if (!_currentIsVip) return; // 👈 실시간 영구 연동 변수로 전면 전환 보호막 장착

    _animationCycleSeconds++;

    if (_animationCycleSeconds == 1) {
      setState(() {
        _showVipOverlay = true;
      });
      _animKey.currentState?.resetAndPlay();
    }
    else if (_animationCycleSeconds == 30) {
      setState(() {
        _showVipOverlay = false;
      });
    }
    else if (_animationCycleSeconds >= 630) {
      _animationCycleSeconds = 0;
    }
  }

  void _toggleTimer() async {
    try {
      if (_isRunning) {
        _timer?.cancel();
        setState(() => _isRunning = false);
        await _timerAudioPlayer.pause();
        _animKey.currentState?.pauseEngine();
        _showPauseChoiceDialog();
      } else {
        setState(() => _isRunning = true);
        if (widget.selectedSoundFile.isNotEmpty) {
          await _timerAudioPlayer.play(AssetSource('sounds/${widget.selectedSoundFile}'));
        }

        if (_currentIsVip) {
          _animKey.currentState?.resumeEngine();
          if (_elapsedSeconds == 0) {
            _animationCycleSeconds = 0;
            setState(() {
              _showVipOverlay = true;
            });
          }
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
                _showGrowthBridgeDialog();
              },
              child: Text("OK (확인)", style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 16))
          ),
        ],
      ),
    );
  }

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

  void _showStudyInputFieldForm() {
    const Color brandGolden = Color(0xFFE5C158);
    final TextEditingController detailController = TextEditingController();
    final TextEditingController scoreController = TextEditingController();
    final TextEditingController nextGoalController = TextEditingController();

    final ScrollController dialogScrollController = ScrollController();

    int? selectedUnderstanding;
    String? selectedDifficulty;
    String? selectedFocus;
    String? selectedCondition;
    bool? isIncorrectNoted;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (context, setDialogState) {

            bool isAllFilled = detailController.text.trim().isNotEmpty &&
                scoreController.text.trim().isNotEmpty &&
                nextGoalController.text.trim().isNotEmpty &&
                selectedUnderstanding != null &&
                selectedDifficulty != null &&
                selectedFocus != null &&
                selectedCondition != null &&
                isIncorrectNoted != null;

            void autoScrollNext(double offset) {
              Future.delayed(const Duration(milliseconds: 100), () {
                if (dialogScrollController.hasClients) {
                  dialogScrollController.animateTo(
                    offset,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                }
              });
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF0D1527),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isAllFilled ? brandGolden : Colors.white12, width: 1)),
              title: Column(
                children: [
                  Text('STUDY RECORD', style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 23)),
                  Text('(학습 기록 작성)', style: GoogleFonts.notoSansKr(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  controller: dialogScrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('SUBJECT (과목) : ', style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(widget.selectedSubject, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), softWrap: true),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text('DETAILS (상세 내용) *필수', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: detailController,
                        maxLines: 2,
                        style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14),
                        onChanged: (_) => setDialogState(() {}),
                        onSubmitted: (_) => autoScrollNext(80.0),
                        decoration: InputDecoration(
                          hintText: 'e.g., Solved concepts and problems. (예: 개념 및 문제풀이 함)',
                          hintStyle: GoogleFonts.notoSansKr(color: Colors.white.withOpacity(0.24), fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF050B14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text('SCORE (점수) *필수', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: scoreController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        onChanged: (_) => setDialogState(() {}),
                        onSubmitted: (_) => autoScrollNext(180.0),
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

                      Text('INCORRECT NOTE STATUS (오답노트 상태) *필수', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(color: const Color(0xFF050B14), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setDialogState(() => isIncorrectNoted = true);
                                  autoScrollNext(260.0);
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                      color: isIncorrectNoted == true ? brandGolden : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8)
                                  ),
                                  child: Text('COMPLETED (정리함)', style: GoogleFonts.notoSansKr(color: isIncorrectNoted == true ? const Color(0xFF030712) : Colors.white60, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setDialogState(() => isIncorrectNoted = false);
                                  autoScrollNext(260.0);
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                      color: isIncorrectNoted == false ? brandGolden : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8)
                                  ),
                                  child: Text('NOT YET (정리 안함)', style: GoogleFonts.notoSansKr(color: isIncorrectNoted == false ? const Color(0xFF030712) : Colors.white60, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text('UNDERSTANDING (이해도) *필수', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [20, 40, 60, 80, 100].map((val) {
                            final bool isSel = selectedUnderstanding == val;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ChoiceChip(
                                label: Text('$val%', style: GoogleFonts.rajdhani(color: isSel ? const Color(0xFF030712) : Colors.white60, fontWeight: FontWeight.bold)),
                                selected: isSel,
                                selectedColor: brandGolden,
                                backgroundColor: const Color(0xFF050B14),
                                onSelected: (_) {
                                  setDialogState(() => selectedUnderstanding = val);
                                  autoScrollNext(360.0);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text('DIFFICULTY (난이도) *필수', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6.0,
                        children: ['매우어려움', '어려움', '보통', '쉬움'].map((val) {
                          final bool isSel = selectedDifficulty == val;
                          return ChoiceChip(
                            label: Text(val, style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                            selected: isSel,
                            selectedColor: brandGolden,
                            backgroundColor: const Color(0xFF050B14),
                            onSelected: (_) {
                              setDialogState(() => selectedDifficulty = val);
                              autoScrollNext(440.0);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      Text('CONCENTRATION (집중도) *필수', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: ['높음', '보통', '낮음'].map((val) {
                          final bool isSel = selectedFocus == val;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: ChoiceChip(
                              label: Text(val, style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                              selected: isSel,
                              selectedColor: brandGolden,
                              backgroundColor: const Color(0xFF050B14),
                              onSelected: (_) {
                                setDialogState(() => selectedFocus = val);
                                autoScrollNext(520.0);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      Text('LEARNING CONDITION (학습 컨디션) *필수', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
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
                              label: Text('$emoji $val', style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                              selected: isSel,
                              selectedColor: brandGolden,
                              backgroundColor: const Color(0xFF050B14),
                              onSelected: (_) {
                                setDialogState(() => selectedCondition = val);
                                autoScrollNext(620.0);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      Text('NEXT GOAL (다음 목표) *필수', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nextGoalController,
                        style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14),
                        onChanged: (_) => setDialogState(() {}),
                        onSubmitted: (_) => autoScrollNext(700.0),
                        decoration: InputDecoration(
                          hintText: 'e.g., Advanced function problems (예: 함수 심화문제)',
                          hintStyle: GoogleFonts.notoSansKr(color: Colors.white.withOpacity(0.24), fontSize: 12),
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
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAllFilled ? brandGolden : const Color(0xFF1F2937),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: isAllFilled ? 4 : 0,
                    ),
                    onPressed: !isAllFilled ? null : () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('dke_temp_subject');
                      await prefs.remove('dke_temp_elapsed');

                      final String subjectKey = "dke_history_${widget.selectedSubject}";

                      final Map<String, dynamic> dkeFinalPacket = {
                        'subject': widget.selectedSubject,
                        'details': detailController.text.trim(),
                        'score': int.tryParse(scoreController.text.trim()) ?? 0,
                        'incorrectNote': isIncorrectNoted == true ? '정리함' : '정리 안함',
                        'understanding': selectedUnderstanding,
                        'difficulty': selectedDifficulty,
                        'concentration': selectedFocus,
                        'condition': selectedCondition,
                        'nextGoal': nextGoalController.text.trim(),
                        'durationSeconds': _elapsedSeconds,
                        'timestamp': DateTime.now().toUtc().toString(),
                      };

                      List<String> subjectHistoryList = prefs.getStringList(subjectKey) ?? [];
                      subjectHistoryList.add(jsonEncode(dkeFinalPacket));
                      await prefs.setStringList(subjectKey, subjectHistoryList);

                      if (!mounted) return;
                      Navigator.of(context).pop();
                      _showFinalSubjectSetupRedirectDialog();
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('SAVE RECORD', style: GoogleFonts.gowunBatang(color: isAllFilled ? const Color(0xFF030712) : Colors.white38, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text('(성장 데이터 저장)', style: GoogleFonts.notoSansKr(color: isAllFilled ? const Color(0xFF030712) : Colors.white24, fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

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
              Navigator.of(context).pop();
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
              if (_currentIsVip && _showVipOverlay) // 👈 🎯 수정한 부분: widget.isVipMember 대신 실시간 강제 복원된 _currentIsVip 사용!
                Positioned.fill(
                  child: Center(
                    child: SizedBox(
                      width: 340,
                      height: 300,
                      child: DkeBigStarTargetAnimationModule(
                        key: _animKey,
                        targetUniversityName: _currentUniversity,
                        currentLanguageCode: _currentLanguageCode,
                      ),
                    ),
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

class DkeBigStarTargetAnimationModule extends StatefulWidget {
  final String targetUniversityName;
  final String currentLanguageCode;

  const DkeBigStarTargetAnimationModule({
    Key? key,
    required this.targetUniversityName,
    required this.currentLanguageCode,
  }) : super(key: key);

  @override
  State<DkeBigStarTargetAnimationModule> createState() => _DkeBigStarTargetAnimationModuleState();
}

class _DkeBigStarTargetAnimationModuleState extends State<DkeBigStarTargetAnimationModule> with TickerProviderStateMixin {
  late AnimationController _timelineController;
  late Animation<double> _targetWordScale;
  late Animation<double> _targetWordOpacity;
  late Animation<double> _uniWordScale;
  late Animation<double> _uniWordOpacity;

  @override
  void initState() {
    super.initState();

    _timelineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );

    _targetWordScale = TweenSequence<double>([
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.fastOutSlowIn)), weight: 10),
      TweenSequenceItem<double>(tween: ConstantTween<double>(1.0), weight: 10),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.fastOutSlowIn)), weight: 10),
      TweenSequenceItem<double>(tween: ConstantTween<double>(0.0), weight: 70),
    ]).animate(_timelineController);

    _targetWordOpacity = TweenSequence<double>([
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem<double>(tween: ConstantTween<double>(1.0), weight: 10),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 10),
      TweenSequenceItem<double>(tween: ConstantTween<double>(0.0), weight: 70),
    ]).animate(_timelineController);

    _uniWordScale = TweenSequence<double>([
      TweenSequenceItem<double>(tween: ConstantTween<double>(0.0), weight: 30),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.0, end: 1.8).chain(CurveTween(curve: Curves.linearToEaseOut)), weight: 23),
      TweenSequenceItem<double>(tween: ConstantTween<double>(1.8), weight: 23),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.8, end: 0.0).chain(CurveTween(curve: Curves.fastOutSlowIn)), weight: 24),
    ]).animate(_timelineController);

    _uniWordOpacity = TweenSequence<double>([
      TweenSequenceItem<double>(tween: ConstantTween<double>(0.0), weight: 30),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 23),
      TweenSequenceItem<double>(tween: ConstantTween<double>(1.0), weight: 23),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 24),
    ]).animate(_timelineController);
  }

  void resetAndPlay() {
    if (mounted) _timelineController.forward(from: 0.0);
  }

  void pauseEngine() {
    if (mounted && _timelineController.isAnimating) _timelineController.stop();
  }

  void resumeEngine() {
    if (mounted && !_timelineController.isAnimating && _timelineController.value > 0.0 && _timelineController.value < 1.0) {
      _timelineController.forward();
    }
  }

  String _getTranslatedTarget() {
    switch (widget.currentLanguageCode) {
      case 'ko': return '목표';
      case 'ja': return '目標';
      case 'zh': return '目标';
      case 'en': return 'Target';
      default: return 'Target';
    }
  }

  @override
  void dispose() {
    _timelineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          FadeTransition(
            opacity: _targetWordOpacity,
            child: ScaleTransition(
              scale: _targetWordScale,
              child: Text(
                _getTranslatedTarget(),
                style: GoogleFonts.notoSansKr(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE5C158),
                  shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _uniWordOpacity,
            child: ScaleTransition(
              scale: _uniWordScale,
              child: SizedBox(
                width: 280,
                height: 150,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      top: 30,
                      child: Image.asset(
                        'assets/images/crown_wings.png',
                        width: 150,
                        height: 60,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    Positioned(
                      top: 70,
                      left: 0,
                      right: 0,
                      child: Text(
                        widget.targetUniversityName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: GoogleFonts.gowunBatang(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
