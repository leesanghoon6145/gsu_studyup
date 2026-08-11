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
import '../star_economy.dart'; // 🆕 [별 경제 시스템] 별 적립 속도/누적저장/레벨계산을 한 곳에서 관리

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
  final bool isFinalExamMode; // [추가] 기말고사 여부 (기본값 false = 중간고사)
  final bool isExamTrackMode; // 🆕 [2026-07-29] true=시험준비/시험당일에서 실행됨(D-day 표시), false=평상시/방학/개인시간표(목표만 표시)

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
    this.isFinalExamMode = false, // [추가]
    this.isExamTrackMode = true, // 🆕 [2026-07-29 수정] 기본값 true로 되돌림 - home_dashboard_screen.dart 등 기존 호출부는 안 건드리고 원래대로 작동. academic_timeline_screen.dart만 평상시/방학/개인시간표일 때 명시적으로 false를 넘겨서 "목표"만 표시함.
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
  late AudioPlayer _cueAudioPlayer; // [추가] 시작/종료 알림음 전용 플레이어

  // 👑 10분 락 연동용 초정밀 타이밍 제어 변수 스펙
  int _animationCycleSeconds = 0;
  bool _showVipOverlay = false;

  // 🆕 [별 경제 시스템] 실시간 자동 적립 카운터 - DkeStars.starAccrualInterval 마다 별 1개씩 즉시 저장.
  // 30분 단위로 몰아서 저장하지 않고, 적립 주기 그대로 바로 SharedPreferences에 반영해서
  // 앱이 중간에 꺼져도 이미 적립된 별은 안전하게 보존됨.
  int _secondsSinceLastStarAccrual = 0;
  int _starsEarnedThisSession = 0;

  late String _currentUniversity;
  String _currentLanguageCode = 'ko';
  bool _currentIsVip = false; // 👈 🎯 영구 동기화용 실시간 VIP 상태 필터 스펙 추가

  // 👑 하단 자식 애니메이션 엔진을 타이머 화면에서 직접 흔들어 깨우기 위한 고유 Key 부품 신설
  final GlobalKey<_DkeBigStarTargetAnimationModuleState> _animKey = GlobalKey<_DkeBigStarTargetAnimationModuleState>();

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.selectedDurationMinutes * 60; // 🆕 [버그 수정 2026-07-29] 1초=1분 테스트모드 폐기, 정상적으로 분→초 변환

    // 초기값 셋팅
    _currentUniversity = widget.targetUniversity;
    _currentIsVip = widget.isVipMember;

    // 타임라인 초기화
    _currentSelectedDate = DateTime.now();
    _updateActiveTimeline();

    tz.initializeTimeZones();
    _timerAudioPlayer = AudioPlayer();
    _timerAudioPlayer.setReleaseMode(ReleaseMode.loop);
    _cueAudioPlayer = AudioPlayer(); // [추가]

    // 🆕 [버그 수정] 시험 일정을 SharedPreferences에 실제로 저장.
    // 기존엔 targetExamDate/needTimelineGen 등이 이 화면의 파라미터로만 존재하고 저장이 안 되어서,
    // planning_screen.dart의 학사 타임라인과 home_dashboard_screen.dart의 D-day 팝업이
    // 둘 다 "시험 일정 없음" 상태로 판정되어 아예 동작하지 않았음.
    _persistExamScheduleToPrefs();

    // ⚡ [0초 정각 초강력 동기화 트리거]: 화면이 픽셀로 안착하자마자 기기 저장 데이터를 강제 복원
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _forceSyncSavedDataOnStartup();
      _checkResumeInterceptionData();
    });
  }

  // 🆕 [버그 수정] planning_screen.dart / home_dashboard_screen.dart가 읽는 것과 동일한 키로 저장.
  // 이 저장이 빠져있어서 D-day 팝업이 조건상 항상 "시험 일정 없음"으로 판정되고 있었음.
  Future<void> _persistExamScheduleToPrefs() async {
    if (widget.targetExamDate == null) return; // 시험 일정 없이 들어온 일반 학습 세션이면 저장하지 않음
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gke_selected_exam_type', widget.dynamicTestTitle);
      await prefs.setString('gke_exam_start_date', widget.targetExamDate!.toIso8601String());
      if (widget.targetExamEndDate != null) {
        await prefs.setString('gke_exam_end_date', widget.targetExamEndDate!.toIso8601String());
      }
      await prefs.setString('gke_exam_prep_period', widget.prepPeriodStr);
      await prefs.setBool('gke_exam_timeline_enabled', widget.needTimelineGen);
    } catch (e) {
      debugPrint("[TimerScreen] 시험 일정 저장 실패: $e");
    }
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
      isFinalExam: widget.isFinalExamMode, // [수정] 기말고사 버그 수정
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
    _cueAudioPlayer.dispose(); // [추가]
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

  // ============================================================================
  // 🆕 [별 경제 시스템] 실시간 자동 별 적립 체크.
  // Timer.periodic 1초 틱마다 호출되며, DkeStars.starAccrualInterval(지금 1초, 실사용 시 1분)에
  // 도달할 때마다 별 1개를 즉시 DkeStars에 저장합니다. 30분 몰아서 저장하지 않고 그때그때 저장하므로
  // 앱이 중간에 꺼져도 이미 적립된 별은 안전합니다.
  // ============================================================================
  void _checkAndAccrueStar() {
    _secondsSinceLastStarAccrual++;
    final int intervalSeconds = DkeStars.starAccrualInterval.inSeconds;
    if (intervalSeconds <= 0) return;

    if (_secondsSinceLastStarAccrual >= intervalSeconds) {
      _secondsSinceLastStarAccrual = 0;
      _starsEarnedThisSession += 1;
      // 저장 자체는 비동기로 흘려보내되(화면 끊김 없게), 실패해도 다음 틱에서 계속 누적되므로 안전.
      DkeStars.addStars(1, subject: widget.selectedSubject);
    }
  }

  // ============================================================================
  // 🆕 [알람 순서 보장] 학습 시작 알림음(start_bell.mp3, 13초)이 실제로 "재생 완료"될 때까지
  // 이벤트 기반으로 기다린 뒤, 다음 단계(백색소음 재생)로 넘어가는 헬퍼.
  // 기존엔 고정된 ms(600ms)만큼 기다렸다가 넘어가서, 벨소리 파일 실제 길이와 안 맞으면
  // 백색소음이 벨소리를 덮어버리거나(너무 짧게 기다림) 어색한 정적이 생기는(너무 길게 기다림) 문제가 있었음.
  // onPlayerComplete 이벤트를 직접 기다리므로 벨소리 파일 길이가 바뀌어도 항상 정확히 이어짐.
  // 혹시 이벤트가 발생하지 않는 예외 상황을 대비해 최대 15초 안전장치(timeout)를 둠.
  // ============================================================================
  Future<void> _playStartBellAndWait() async {
    try {
      final Completer<void> completer = Completer<void>();
      late final StreamSubscription<void> sub;
      sub = _cueAudioPlayer.onPlayerComplete.listen((event) {
        sub.cancel();
        if (!completer.isCompleted) completer.complete();
      });

      await _cueAudioPlayer.play(AssetSource('sounds/start_bell.mp3'));

      // 혹시 onPlayerComplete가 발생하지 않는 예외 상황 대비, 안전장치(timeout).
      // start_bell.mp3가 13초이므로 그보다 넉넉한 15초로 설정 (너무 짧으면 정상 재생 중에도 잘릴 위험).
      await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          sub.cancel();
        },
      );
    } catch (e) {
      debugPrint("시작 알림음 재생 대기 오류: $e");
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
        // 🆕 [알람 순서 보장] 학습 시작 알림음이 실제로 끝날 때까지 기다린 뒤 백색소음 재생
        if (_elapsedSeconds == 0) {
          await _playStartBellAndWait();
        }
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
              _checkAndAccrueStar(); // 🆕 [별 경제 시스템] 실시간 자동 적립 체크
            } else {
              _timer?.cancel();
              _isRunning = false;
              _timerAudioPlayer.stop();
              // [추가] 학습 종료(목표 달성) 알림음 (트랙 공통 1개) - 백색소음 정지 후 반드시 재생됨
              _cueAudioPlayer.play(AssetSource('sounds/end_bell.mp3'));
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
    // 🆕 [기록 유형 구분] 개념강의만 들은 경우엔 점수가 없을 수 있으므로,
    // "강의"와 "평가"를 먼저 구분해서 강의는 세부 유형만, 평가는 기존처럼 점수를 기록하도록 분기함.
    String? selectedRecordType; // '강의' 또는 '평가'
    String? selectedLectureSubType; // '개념강의' 또는 '단원정리 및 문제해설' (강의일 때만 사용)

    // 🆕 [버그 수정 2026-08-10] 각 입력 구간(섹션)에 고유 GlobalKey를 부여해서,
    // 선택할 때마다 "다음에 입력해야 할 항목"이 화면에 정확히 보이도록 Scrollable.ensureVisible로
    // 스크롤을 이동시킴. 기존엔 고정된 픽셀 offset(140, 180, 260...)을 그대로 스크롤했는데,
    // 강의/평가 선택에 따라 위에 있는 항목 개수/높이가 달라지므로 실제 콘텐츠 위치와 offset이 어긋나서
    // 필요 이상으로 더 내려가거나 다음 입력칸이 화면 밖으로 벗어나는 문제가 있었음.
    final GlobalKey keyLectureType = GlobalKey();
    final GlobalKey keyDetails = GlobalKey();
    final GlobalKey keyScore = GlobalKey();
    final GlobalKey keyIncorrectNote = GlobalKey();
    final GlobalKey keyUnderstanding = GlobalKey();
    final GlobalKey keyDifficulty = GlobalKey();
    final GlobalKey keyFocus = GlobalKey();
    final GlobalKey keyCondition = GlobalKey();
    final GlobalKey keyNextGoal = GlobalKey();
    final GlobalKey keySaveButton = GlobalKey();

    // 🆕 [연동 2026-08-10] 타이머에서 [평가] 기록 시, 그 점수를 '나의 성적 기록'(gke_exam_records,
    // 주평가/단원평가/중간고사/기말고사/모의고사)에도 자동으로 반영하기 위한 추가 상태값들.
    String? selectedExamCategory; // 주평가/단원평가/중간고사/기말고사/모의고사
    int? selectedBigUnitNum; // 단원평가일 때만 사용 (1~4)
    int? selectedMidUnitNum; // 단원평가일 때만 사용 (1~4)
    int selectedGradeNum = 2; // 학년 (기본값 2학년 - member_achievement_screen.dart 기본값과 동일)
    final TextEditingController mockMonthController = TextEditingController(); // 모의고사일 때만 사용
    final TextEditingController mockRankController = TextEditingController(); // 모의고사일 때만 사용

    final GlobalKey keyExamCategory = GlobalKey();
    final GlobalKey keyUnitDetail = GlobalKey(); // 단원평가(대/중단원) 또는 모의고사(월/등급) 입력칸 공용
    final GlobalKey keyGrade = GlobalKey();

    // 🆕 [연동] member_achievement_screen.dart의 주평가 단원명 자동 생성 로직과 동일한 방식으로
    // "몇주차"를 계산 (일요일을 한 주의 시작으로 보고, 그 달 1일이 포함된 주를 1주차로 계산).
    String computeWeekOfMonthLabel(DateTime now) {
      final DateTime firstOfMonth = DateTime(now.year, now.month, 1);
      final int sundayIndex = firstOfMonth.weekday % 7;
      final int weekNum = ((now.day - 1 + sundayIndex) ~/ 7) + 1;
      return "$weekNum주차";
    }

    // 🆕 [연동] 3~8월=1학기, 9~2월=2학기로 자동 판별 (한국 학사일정 기준 근사치).
    String computeSemesterLabel(DateTime now) {
      return (now.month >= 3 && now.month <= 8) ? "1학기" : "2학기";
    }

    int computeSemesterInt(DateTime now) {
      return (now.month >= 3 && now.month <= 8) ? 1 : 2;
    }

    // 🆕 [연동] 시험 유형별로 member_achievement_screen.dart가 저장/조회에 사용하는 것과
    // 동일한 형식의 단원명(unit) 문자열을 생성. 이 형식이 어긋나면 "주평가"/"단원평가" 탭의
    // 필터(연도/월/주차, 대단원/중단원 일치검사)에서 기록이 조회되지 않으므로 형식을 정확히 맞춤.
    String buildExamUnitLabel(String category) {
      final DateTime now = DateTime.now();
      switch (category) {
        case '주평가':
          return "${now.year}년 ${now.month}월 ${computeWeekOfMonthLabel(now)}";
        case '단원평가':
          return "대단원 ${selectedBigUnitNum ?? 1} (중단원 ${selectedMidUnitNum ?? 1})";
        case '모의고사':
          return "${mockMonthController.text.trim()} 모의고사 (${mockRankController.text.trim()})";
        default: // 중간고사, 기말고사
          return computeSemesterLabel(now);
      }
    }

    // 🆕 [연동] member_achievement_screen.dart의 _ExamRecord.toJson()과 완전히 동일한 필드 구조로
    // gke_exam_records(SharedPreferences, 단일 JSON 배열 문자열)에 새 레코드를 이어붙여 저장.
    Future<void> appendExamRecord({
      required String category,
      required String subject,
      required double score,
      required String difficulty,
      required int understandingPercent,
      required int durationMinutes,
    }) async {
      final prefs = await SharedPreferences.getInstance();
      final String? existingJson = prefs.getString('gke_exam_records');
      List<dynamic> list = [];
      if (existingJson != null && existingJson.isNotEmpty) {
        try {
          list = jsonDecode(existingJson) as List<dynamic>;
        } catch (_) {
          list = [];
        }
      }

      // 이해도(%)를 만족도 별점(1~5)으로 환산 (100%->5, 80%->4 ... 20%->1)
      final int starSatisfaction = (understandingPercent / 20).round().clamp(1, 5);
      // 이해도가 80% 이상이면 복습 불필요로, 그 미만이면 복습 필요로 자동 판단
      final String reviewRequired = understandingPercent >= 80 ? "불필요" : "필요";

      final Map<String, dynamic> newRecord = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': category,
        'grade': selectedGradeNum,
        'semester': computeSemesterInt(DateTime.now()),
        'date': DateTime.now().toIso8601String(),
        'subject': subject,
        'unit': buildExamUnitLabel(category),
        'score': score,
        'durationText': "$durationMinutes분",
        'difficultyLevel': difficulty,
        'starSatisfaction': starSatisfaction,
        'errorCauses': const ["개념부족"],
        'reviewRequired': reviewRequired,
        'mockMonth': category == '모의고사' ? mockMonthController.text.trim() : "",
        'mockRank': category == '모의고사' ? mockRankController.text.trim() : "",
      };

      list.add(newRecord);
      await prefs.setString('gke_exam_records', jsonEncode(list));
    }

    // 다음 표시할 항목의 key로 정확히 스크롤 이동. 고정 offset을 쓰지 않으므로
    // 현재 화면에 어떤 항목이 조건부로 보이거나 안 보이는지와 관계없이 항상 정확하게 동작함.
    void scrollToNext(GlobalKey targetKey) {
      Future.delayed(const Duration(milliseconds: 150), () {
        final ctx = targetKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            alignment: 0.05, // 화면 상단 쪽에 가깝게 배치해서 다음 항목이 확실히 보이게 함
          );
        }
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (context, setDialogState) {

            // 🆕 [기록 유형 구분] "평가"일 때만 점수(SCORE)를 필수로 요구.
            // "강의"일 때는 세부 유형(개념강의/단원정리 및 문제해설) 선택을 필수로 요구.
            // "오답노트 상태"는 평가이거나, 강의 중 "단원정리 및 문제해설"(문제를 실제로 풀어본 경우)일 때만 필요.
            final bool needsIncorrectNoteField = selectedRecordType == '평가' ||
                (selectedRecordType == '강의' && selectedLectureSubType == '단원정리 및 문제해설');

            // 🆕 [연동 2026-08-10] "평가" 기록일 때 시험 유형 선택 + 유형별 상세 입력까지 필수로 검증.
            final bool examCategoryDetailFilled = selectedExamCategory == null
                ? false
                : (selectedExamCategory == '단원평가'
                ? (selectedBigUnitNum != null && selectedMidUnitNum != null)
                : (selectedExamCategory == '모의고사'
                ? (mockMonthController.text.trim().isNotEmpty && mockRankController.text.trim().isNotEmpty)
                : true));

            bool isAllFilled = detailController.text.trim().isNotEmpty &&
                nextGoalController.text.trim().isNotEmpty &&
                selectedUnderstanding != null &&
                selectedDifficulty != null &&
                selectedFocus != null &&
                selectedCondition != null &&
                selectedRecordType != null &&
                (selectedRecordType == '평가'
                    ? (scoreController.text.trim().isNotEmpty && examCategoryDetailFilled)
                    : selectedLectureSubType != null) &&
                (!needsIncorrectNoteField || isIncorrectNoted != null);

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

                      // 🆕 [기록 유형 구분] 강의(개념강의/단원정리)만 들은 경우엔 점수가 없을 수 있으므로,
                      // 먼저 "강의"인지 "평가"인지 선택하게 하고, 이에 따라 아래 항목이 달라짐.
                      Text('RECORD TYPE (기록 유형) *필수', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      // 🆕 [버그 수정 2026-08-10] Row → Wrap 교체.
                      // "강의 (Lecture)" / "평가 (Evaluation)" 라벨이 길어서, 화면이 좁은 기기에서
                      // Row 안의 ChoiceChip 두 개가 가로 폭을 초과해 우측이 잘리는(오버플로우) 문제가 있었음.
                      // Wrap은 폭이 부족하면 자동으로 다음 줄로 넘어가므로 어떤 화면 크기에서도 잘리지 않음.
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: ['강의', '평가'].map((type) {
                          final bool isSel = selectedRecordType == type;
                          return ChoiceChip(
                            label: Text(
                              type == '강의' ? '강의 (Lecture)' : '평가 (Evaluation)',
                              style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            selected: isSel,
                            selectedColor: brandGolden,
                            backgroundColor: const Color(0xFF050B14),
                            onSelected: (_) {
                              setDialogState(() {
                                selectedRecordType = type;
                                if (type == '평가') {
                                  selectedLectureSubType = null; // 평가로 바꾸면 강의 세부유형 초기화
                                } else {
                                  scoreController.clear(); // 강의로 바꾸면 점수 입력값 초기화
                                }
                              });
                              // 강의를 고르면 다음 필수 항목은 "강의 세부 유형", 평가를 고르면 곧바로 "상세 내용"
                              scrollToNext(type == '강의' ? keyLectureType : keyDetails);
                            },
                          );
                        }).toList(),
                      ),

                      // 🆕 [기록 유형 구분] "강의" 선택 시에만 세부 유형(개념강의/단원정리 및 문제해설) 선택 노출
                      if (selectedRecordType == '강의') ...[
                        const SizedBox(height: 12),
                        Column(
                          key: keyLectureType,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('LECTURE TYPE (강의 세부 유형) *필수', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6.0,
                              runSpacing: 6.0,
                              children: ['개념강의', '단원정리 및 문제해설'].map((val) {
                                final bool isSel = selectedLectureSubType == val;
                                return ChoiceChip(
                                  label: Text(val, style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                                  selected: isSel,
                                  selectedColor: brandGolden,
                                  backgroundColor: const Color(0xFF050B14),
                                  onSelected: (_) {
                                    setDialogState(() => selectedLectureSubType = val);
                                    scrollToNext(keyDetails);
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),

                      Column(
                        key: keyDetails,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DETAILS (상세 내용) *필수', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: detailController,
                            maxLines: 2,
                            style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14),
                            onChanged: (_) => setDialogState(() {}),
                            onSubmitted: (_) => scrollToNext(
                                selectedRecordType == '평가' ? keyScore : (needsIncorrectNoteField ? keyIncorrectNote : keyUnderstanding)),
                            decoration: InputDecoration(
                              hintText: 'e.g., Solved concepts and problems. (예: 개념 및 문제풀이 함)',
                              hintStyle: GoogleFonts.notoSansKr(color: Colors.white.withOpacity(0.24), fontSize: 12),
                              filled: true,
                              fillColor: const Color(0xFF050B14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.all(10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 🆕 [기록 유형 구분] "평가"일 때만 SCORE 필드 노출 (강의는 점수 없음)
                      if (selectedRecordType == '평가') ...[
                        Column(
                          key: keyScore,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SCORE (점수) *필수', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: scoreController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              onChanged: (_) => setDialogState(() {}),
                              onSubmitted: (_) => scrollToNext(keyExamCategory),
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
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 🆕 [연동 2026-08-10] "평가" 기록의 점수를 '나의 성적 기록'(주평가/단원평가/중간고사/
                        // 기말고사/모의고사)에도 자동으로 반영하기 위해, 어떤 시험 유형인지 반드시 선택하게 함.
                        Column(
                          key: keyExamCategory,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('EXAM CATEGORY (시험 유형) *필수', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6.0,
                              runSpacing: 6.0,
                              children: ['주평가', '단원평가', '중간고사', '기말고사', '모의고사'].map((cat) {
                                final bool isSel = selectedExamCategory == cat;
                                return ChoiceChip(
                                  label: Text(cat, style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                                  selected: isSel,
                                  selectedColor: brandGolden,
                                  backgroundColor: const Color(0xFF050B14),
                                  onSelected: (_) {
                                    setDialogState(() {
                                      selectedExamCategory = cat;
                                      // 시험 유형이 바뀌면 이전에 입력해둔 단원평가/모의고사 전용 값은 초기화
                                      selectedBigUnitNum = null;
                                      selectedMidUnitNum = null;
                                      mockMonthController.clear();
                                      mockRankController.clear();
                                    });
                                    if (cat == '단원평가' || cat == '모의고사') {
                                      scrollToNext(keyUnitDetail);
                                    } else {
                                      scrollToNext(keyGrade);
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),

                        // 🆕 [연동] "단원평가" 선택 시에만 대단원/중단원 번호 선택 노출
                        if (selectedExamCategory == '단원평가') ...[
                          const SizedBox(height: 16),
                          Column(
                            key: keyUnitDetail,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('BIG UNIT (대단원) *필수', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6.0,
                                runSpacing: 6.0,
                                children: [1, 2, 3, 4].map((n) {
                                  final bool isSel = selectedBigUnitNum == n;
                                  return ChoiceChip(
                                    label: Text('대단원 $n', style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                                    selected: isSel,
                                    selectedColor: brandGolden,
                                    backgroundColor: const Color(0xFF050B14),
                                    onSelected: (_) {
                                      setDialogState(() => selectedBigUnitNum = n);
                                      if (selectedMidUnitNum != null) scrollToNext(keyGrade);
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              Text('MID UNIT (중단원) *필수', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6.0,
                                runSpacing: 6.0,
                                children: [1, 2, 3, 4].map((n) {
                                  final bool isSel = selectedMidUnitNum == n;
                                  return ChoiceChip(
                                    label: Text('중단원 $n', style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                                    selected: isSel,
                                    selectedColor: brandGolden,
                                    backgroundColor: const Color(0xFF050B14),
                                    onSelected: (_) {
                                      setDialogState(() => selectedMidUnitNum = n);
                                      scrollToNext(keyGrade);
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ],

                        // 🆕 [연동] "모의고사" 선택 시에만 몇월/등급(석차) 직접 입력 노출
                        if (selectedExamCategory == '모의고사') ...[
                          const SizedBox(height: 16),
                          Column(
                            key: keyUnitDetail,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('MOCK MONTH (몇 월 모의고사) *필수', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: mockMonthController,
                                style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14),
                                onChanged: (_) => setDialogState(() {}),
                                onSubmitted: (_) => scrollToNext(keyGrade),
                                decoration: InputDecoration(
                                  hintText: 'e.g., 6월 (예: 6월)',
                                  hintStyle: GoogleFonts.notoSansKr(color: Colors.white.withOpacity(0.24), fontSize: 12),
                                  filled: true,
                                  fillColor: const Color(0xFF050B14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text('MOCK RANK (등급 또는 석차) *필수', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: mockRankController,
                                style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14),
                                onChanged: (_) => setDialogState(() {}),
                                onSubmitted: (_) => scrollToNext(keyGrade),
                                decoration: InputDecoration(
                                  hintText: 'e.g., 1등급 (예: 1등급)',
                                  hintStyle: GoogleFonts.notoSansKr(color: Colors.white.withOpacity(0.24), fontSize: 12),
                                  filled: true,
                                  fillColor: const Color(0xFF050B14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // 🆕 [연동] 시험 유형이 선택된 이후, 학년 선택 (grade 필드는 filter 매칭에 필요)
                        if (selectedExamCategory != null) ...[
                          const SizedBox(height: 16),
                          Column(
                            key: keyGrade,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('GRADE (학년) *필수', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6.0,
                                runSpacing: 6.0,
                                children: [1, 2, 3].map((n) {
                                  final bool isSel = selectedGradeNum == n;
                                  return ChoiceChip(
                                    label: Text('$n학년', style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                                    selected: isSel,
                                    selectedColor: brandGolden,
                                    backgroundColor: const Color(0xFF050B14),
                                    onSelected: (_) {
                                      setDialogState(() => selectedGradeNum = n);
                                      scrollToNext(needsIncorrectNoteField ? keyIncorrectNote : keyUnderstanding);
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],

                      // 🆕 [기록 유형 구분] 평가이거나, 강의 중 "단원정리 및 문제해설"(문제풀이 포함)일 때만 노출
                      if (needsIncorrectNoteField) ...[
                        Column(
                          key: keyIncorrectNote,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                        scrollToNext(keyUnderstanding);
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
                                        scrollToNext(keyUnderstanding);
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
                          ],
                        ),
                        const SizedBox(height: 16),
                      ], // needsIncorrectNoteField 조건부 블록 닫힘

                      Column(
                        key: keyUnderstanding,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                      scrollToNext(keyDifficulty);
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Column(
                        key: keyDifficulty,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DIFFICULTY (난이도) *필수', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6.0,
                            runSpacing: 6.0,
                            children: ['매우어려움', '어려움', '보통', '쉬움'].map((val) {
                              final bool isSel = selectedDifficulty == val;
                              return ChoiceChip(
                                label: Text(val, style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                                selected: isSel,
                                selectedColor: brandGolden,
                                backgroundColor: const Color(0xFF050B14),
                                onSelected: (_) {
                                  setDialogState(() => selectedDifficulty = val);
                                  scrollToNext(keyFocus);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Column(
                        key: keyFocus,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CONCENTRATION (집중도) *필수', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6.0,
                            runSpacing: 6.0,
                            children: ['높음', '보통', '낮음'].map((val) {
                              final bool isSel = selectedFocus == val;
                              return ChoiceChip(
                                label: Text(val, style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                                selected: isSel,
                                selectedColor: brandGolden,
                                backgroundColor: const Color(0xFF050B14),
                                onSelected: (_) {
                                  setDialogState(() => selectedFocus = val);
                                  scrollToNext(keyCondition);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Column(
                        key: keyCondition,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LEARNING CONDITION (학습 컨디션) *필수', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6.0,
                            runSpacing: 6.0,
                            children: [
                              {'label': '좋음', 'emoji': '😊'},
                              {'label': '보통', 'emoji': '😐'},
                              {'label': '피곤함', 'emoji': '😴'}
                            ].map((item) {
                              final String val = item['label']!;
                              final String emoji = item['emoji']!;
                              final bool isSel = selectedCondition == val;
                              return ChoiceChip(
                                label: Text('$emoji $val', style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                                selected: isSel,
                                selectedColor: brandGolden,
                                backgroundColor: const Color(0xFF050B14),
                                onSelected: (_) {
                                  setDialogState(() => selectedCondition = val);
                                  scrollToNext(keyNextGoal);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Column(
                        key: keyNextGoal,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NEXT GOAL (다음 목표) *필수', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nextGoalController,
                            style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14),
                            onChanged: (_) => setDialogState(() {}),
                            onSubmitted: (_) => scrollToNext(keySaveButton),
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
                      SizedBox(key: keySaveButton, height: 4),
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

                      final String subjectKey = "dke_history_${widget
                          .selectedSubject}";

                      // 🆕 [기록 유형 구분] "강의"(특히 개념강의) 기록은 실제 점수가 없으므로
                      // score/incorrectNote를 0이나 임의값으로 채우지 않고 null로 저장함.
                      // (0을 저장하면 나중에 성취도 화면의 평균 점수 계산에 실제 0점처럼 섞여 통계가 왜곡됨)
                      final Map<String, dynamic> dkeFinalPacket = {
                        'subject': widget.selectedSubject,
                        'recordType': selectedRecordType, // '강의' 또는 '평가'
                        'lectureSubType': selectedLectureSubType, // '개념강의' / '단원정리 및 문제해설' (강의일 때만)
                        'details': detailController.text.trim(),
                        'score': selectedRecordType == '평가'
                            ? (int.tryParse(scoreController.text.trim()) ?? 0)
                            : null,
                        'incorrectNote': needsIncorrectNoteField
                            ? (isIncorrectNoted == true ? '정리함' : '정리 안함')
                            : null,
                        'understanding': selectedUnderstanding,
                        'difficulty': selectedDifficulty,
                        'concentration': selectedFocus,
                        'condition': selectedCondition,
                        'nextGoal': nextGoalController.text.trim(),
                        'durationSeconds': _elapsedSeconds,
                        'timestamp': DateTime.now().toUtc().toString(),
                      };

                      List<String> subjectHistoryList = prefs.getStringList(
                          subjectKey) ?? [];
                      subjectHistoryList.add(jsonEncode(dkeFinalPacket));
                      await prefs.setStringList(subjectKey, subjectHistoryList);

                      // 🆕 [연동 2026-08-10] "평가" 기록이면서 시험 유형(주평가/단원평가/중간고사/기말고사/모의고사)이
                      // 선택된 경우, 같은 점수를 member_achievement_screen.dart의 "나의 성적 기록"(gke_exam_records)에도
                      // 자동으로 이어붙여 저장함. 이제 학생이 같은 점수를 두 번 입력할 필요가 없음.
                      if (selectedRecordType == '평가' && selectedExamCategory != null) {
                        await appendExamRecord(
                          category: selectedExamCategory!,
                          subject: widget.selectedSubject,
                          score: (int.tryParse(scoreController.text.trim()) ?? 0).toDouble(),
                          difficulty: selectedDifficulty ?? "보통",
                          understandingPercent: selectedUnderstanding ?? 60,
                          durationMinutes: (_elapsedSeconds / 60).round(),
                        );
                      }

                      // 🆕 [별 경제 시스템] 별은 이미 학습 중 실시간으로 DkeStars에 적립/저장되어 있으므로
                      // 여기서는 다시 계산해서 더하지 않고, 이번 세션에서 쌓인 값 + 현재 전체 누적치만 조회함.
                      // (기존 _calcStarsFromSeconds/_saveStarsAndGetTotal은 이중 적립을 막기 위해 제거하고 DkeStars로 통합함)
                      final int earnedStars = _starsEarnedThisSession;
                      final int newAllTimeTotal = await DkeStars.getTotalStars();

                      if (!mounted) return;
                      Navigator.of(context).pop();
                      _showFinalSubjectSetupRedirectDialog(
                          earnedStars, newAllTimeTotal);
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

  void _showFinalSubjectSetupRedirectDialog(int earnedStars, int allTimeTotalStars) {
    const Color brandGolden = Color(0xFFE5C158);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1527),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(Icons.star, color: brandGolden, size: 32),
            const SizedBox(height: 8),
            Text('$earnedStars 개의 별을 획득했습니다.', textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text('누적 $allTimeTotalStars 개', textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 12)),
            const Divider(color: Colors.white24, height: 24),
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
              Navigator.of(context).pop(allTimeTotalStars);
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
// 🆕 [2026-07-29] 시험준비/시험당일 트랙에서 실행된 경우에만 시험명+D-day 표시.
                    // 평상시/방학/개인시간표에서 실행된 경우에는 마이페이지에서 설정한 실제 목표
                    // (예: 서울대학교, 민족사관고등학교, 사법고시 등)를 그대로 표시하고 D-day는 제거.
                    widget.isExamTrackMode
                        ? Builder(builder: (context) {
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
                    })
                        : Column(mainAxisSize: MainAxisSize.min, children: [
                      Image.asset('assets/images/crown_wings.png', width: 100, fit: BoxFit.contain),
                      const SizedBox(height: 2),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text("✧───  ", style: TextStyle(color: Color(0xFFE5C158), fontSize: 12, fontWeight: FontWeight.bold)),
                        Text("목표", style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                        const Text("  ───✧", style: TextStyle(color: Color(0xFFE5C158), fontSize: 12, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          _currentUniversity, // 🆕 마이페이지에서 실제 저장한 목표 (대학/고교/고시 등 무엇이든 그대로 표시)
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.gowunBatang(color: const Color(0xFFFFF6D6), fontSize: 24, fontWeight: FontWeight.bold, height: 1.0, letterSpacing: 0.5),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 260),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      // 🆕 [정리 2026-07-29] "배속 실험 모드 가동" 디버그 표시줄 삭제함
                      // (테스트용 임시 문구였고, 바로 아래 큰 타이머와 중복 표시였음)
                      Text(_formatDisplayTime(_elapsedSeconds), style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 78, fontWeight: FontWeight.w700, letterSpacing: 1.0, height: 0.9)),
                    ]),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [Expanded(child: Text("🔊 ${widget.selectedSubject}", style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))]),
                        const SizedBox(height: 4),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text("실시간 집중 모드", style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 13, fontWeight: FontWeight.bold)),
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
                                        "${currentInterval.toStringAsFixed(1)}분\n($currentPercentage%)",
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

  // 🆕 [수정: 2026-08-07] 12개국어 완전 지원으로 교체.
  // 기존엔 'ko'/'ja'/'zh'/'en' 4개만 처리하고 나머지 8개 언어(FR/DE/RU/AR/HI/VI/ES/TH)는
  // 전부 영어로 표시되던 문제를 수정함. 또한 main.dart의 DkeLang 언어코드 표기(대문자: JA, ZH...)와
  // 이 화면이 SharedPreferences에서 불러오는 saved_language_code 값의 대소문자가 어긋나 있을 가능성에
  // 대비해, 비교 시 대소문자를 구분하지 않도록(toUpperCase) 안전장치를 추가함.
  // 디자인/폰트/색상/레이아웃은 100% 원본 그대로이며, 오직 이 함수의 번역 매핑만 확장함.
  String _getTranslatedTarget() {
    final String code = widget.currentLanguageCode.toUpperCase();
    switch (code) {
      case 'KO':
        return '목표';
      case 'EN':
        return 'Target';
      case 'JA':
        return '目標';
      case 'ZH':
        return '目标';
      case 'FR':
        return 'Objectif';
      case 'DE':
        return 'Ziel';
      case 'RU':
        return 'Цель';
      case 'AR':
        return 'الهدف';
      case 'HI':
        return 'लक्ष्य';
      case 'VI':
        return 'Mục tiêu';
      case 'ES':
        return 'Objetivo';
      case 'TH':
        return 'เป้าหมาย';
      default:
      // 알 수 없는 코드가 들어와도 앱이 멈추지 않도록 기본(한글) 표시로 안전하게 처리
        return '목표';
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
