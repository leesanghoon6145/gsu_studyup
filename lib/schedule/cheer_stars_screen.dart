// cheer_stars_screen.dart
//
// 🆕 [부모 운동 응원별 2026-09-29] 운동 타이머 + 별 통장 화면
// - 일반인·학부모 누구나 사용 (별 모으기는 모두 가능, 보내기는 자녀 연결 뒤)
// - 타이머: 학생 timer_screen.dart와 같은 "실제 시계 기준" 계산, 6색 막대,
//   다른 앱으로 나가면 자동 일시정지, 작동 중 화면 꺼짐 방지
// - 목표 60분. 넘으면 가장 오래된 10분 칸이 잘려 나가고 새 칸이 오른쪽에 붙음
// - 운동 5분 = 별 1개, 끝낼 때 보너스 계산 (exercise_star_service.dart)
// - 끝낸 운동은 일반 플래너 운동 기록에도 저장되어 캘린더·운동 분석에 함께 보임
// - 글자: 큰 제목·중간 제목만 영문(진한 명조)+한글, 나머지는 한글만
// - 🆕 [다국어 2026-09-29] 모든 글자는 cheer_stars_i18n.dart에서 꺼냄
//   한국어 = 위 규칙 / English = 영어만 / 10개 언어 = 그 언어만

import 'dart:async';
import 'dart:math' show cos, sin; // 🆕 [2026-10-01] 황금장 별 그리기
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/exercise_star_service.dart';
import '../services/family_link_service.dart';
import 'exercise_models.dart';
import 'exercise_data_service.dart';
import 'exercise_theme.dart'; // 🆕 운동 모듈 공용 고급 팝업(LuxuryDialogFrame 등) 재사용
import 'today_exercise_screen.dart'; // 🆕 끝낸 뒤 "세부 기록하기"로 해당 종목 기록 화면 열기
import 'app_language_service.dart'; // 🆕 [다국어 2026-09-29] 지금 언어 확인
import 'cheer_phrases.dart'; // 🆕 [2026-09-29] 응원 문구 6개 (12개 언어)
import 'cheer_stars_i18n.dart'; // 🆕 [다국어 2026-09-29] 이 화면의 모든 글자 (12개 언어)
import 'family_check_dialog.dart'; // 🆕 [가족 활동 체크 2026-09-30]
import '../services/supporter_service.dart'; // 🆕 [응원 가족 2026-09-30]
import '../services/user_profile_service.dart'; // 🆕 [응원 가족] 내 이름

class CheerStarsScreen extends StatefulWidget {
  const CheerStarsScreen({super.key});

  @override
  State<CheerStarsScreen> createState() => _CheerStarsScreenState();
}

class _ExerciseChoice {
  final String typeId; // 일반 플래너 운동 종목 id와 같음 (기록 저장에 사용)
  final String labelKey; // 🆕 [다국어] 번역 사전 이름표 (예: 'ex_walking')
  final IconData icon;
  const _ExerciseChoice(this.typeId, this.labelKey, this.icon);
  String get label => cs(labelKey); // 지금 언어의 종목 이름
}

class _CheerStarsScreenState extends State<CheerStarsScreen> with WidgetsBindingObserver {
  static const Color _gold = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _cardBg = Color(0xFF0D1527);
  static const Color _cream = Color(0xFFFFF6D6);

  static const int _goalSeconds = 3600; // 목표 60분
  static const int _segmentSeconds = 600; // 한 칸 10분

  // 학생 타이머와 같은 6색 (빨강·주황·노랑·초록·파랑·남색)
  static const List<Color> _rainbow = [
    Color(0xFFFF3B30),
    Color(0xFFFF9500),
    Color(0xFFFFCC00),
    Color(0xFF34C759),
    Color(0xFF007AFF),
    Color(0xFF5856D6),
  ];

  static const List<_ExerciseChoice> _choices = [
    _ExerciseChoice('walking', 'ex_walking', Icons.directions_walk_rounded),
    _ExerciseChoice('running', 'ex_running', Icons.directions_run_rounded),
    _ExerciseChoice('gym', 'ex_gym', Icons.fitness_center_rounded),
    _ExerciseChoice('cycling', 'ex_cycling', Icons.directions_bike_rounded),
    _ExerciseChoice('swimming', 'ex_swimming', Icons.pool_rounded),
    _ExerciseChoice('yoga', 'ex_yoga', Icons.self_improvement_rounded),
    _ExerciseChoice('pilates', 'ex_pilates', Icons.accessibility_new_rounded),
    _ExerciseChoice('hiking', 'ex_hiking', Icons.terrain_rounded),
    _ExerciseChoice('etc', 'ex_etc', Icons.sports_rounded),
  ];

  String _selectedTypeId = 'walking';

  Timer? _timer;
  bool _isRunning = false;
  bool _isFinishing = false;
  bool _leaveNoticeShown = false;

  // 실제 시계 기준 계산용 (화면이 잠깐 멈춰도 시간이 정확함)
  int _elapsedSeconds = 0;
  DateTime? _anchorTime;
  int _accumulatedAtAnchor = 0;

  int _starsAccrued = 0; // 이번 운동에서 쌓인 시간 별
  final GlobalKey _chooseKey = GlobalKey(); // 🆕 [가족 활동 체크] "타이머로 모으기" 누르면 여기로 내려감

  late Future<List<String>> _linkedCodesFuture;
  // 🆕 [응원 가족 2026-09-30] 내가 "응원 가족"으로 연결된 아이들 (보호자로 연결된 아이와 따로)
  Set<String> _supporterCodes = {};
  Map<String, SupportTarget> _supportInfo = {};
  List<SupportTarget> _pendingTargets = [];
  Future<List<ExerciseRecord>>? _recentRecordsFuture; // 🆕 타이머로 한 최근 운동 기록

  // 🆕 종목별 표시 색 (_choices 순서와 같음)
  static const List<Color> _typeColors = [
    Color(0xFF34C759), // 걷기
    Color(0xFFFF3B30), // 달리기
    Color(0xFFFF9500), // 헬스
    Color(0xFF007AFF), // 자전거
    Color(0xFF00C7BE), // 수영
    Color(0xFFAF52DE), // 요가
    Color(0xFFFF2D55), // 필라테스
    Color(0xFF8B5E3C), // 등산
    Color(0xFF8E8E93), // 기타
  ];

  // 🆕 보너스 종류별 색 (학생 "보너스별 상세 내역"처럼 색 점으로 구분)
  static const Map<String, Color> _bonusColors = {
    'record': Color(0xFF34C759),
    'd60': Color(0xFFFF9500),
    'streak': Color(0xFF60A5FA),
    'week': Color(0xFFAF52DE),
    'month': Color(0xFFFFD700),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    appLanguage.addListener(_onLanguageChanged); // 🆕 [다국어] 언어를 바꾸면 바로 다시 그림
    _linkedCodesFuture = _loadSendTargets(); // 🆕 [응원 가족] 보호자 자녀 + 응원 가족 아이 함께
    _recentRecordsFuture = _loadRecentRecords();
  }

  // 🆕 [응원 가족 2026-09-30] 보낼 수 있는 아이 = 보호자로 연결된 자녀 + 승인된 응원 가족 아이
  Future<List<String>> _loadSendTargets() async {
    final List<String> guardian = await FamilyLinkService.getLinkedCodes();
    final List<SupportTarget> targets = await SupporterService.getMyTargets();
    final Map<String, SupportTarget> info = {};
    final Set<String> sup = {};
    final List<SupportTarget> pending = [];
    for (final t in targets) {
      if (guardian.contains(t.code)) continue; // 보호자로 이미 연결된 아이는 보호자로 보냄
      if (t.approved) {
        sup.add(t.code);
        info[t.code] = t;
      } else {
        pending.add(t);
      }
    }
    if (mounted) {
      setState(() {
        _supporterCodes = sup;
        _supportInfo = info;
        _pendingTargets = pending;
      });
    }
    return [...guardian, ...sup];
  }

  void _refreshSendTargets() {
    setState(() => _linkedCodesFuture = _loadSendTargets());
  }

  String _relationLabel(String relation, String relationText) {
    if (relation == 'other' && relationText.trim().isNotEmpty) return relationText.trim();
    return cs('rel_$relation');
  }

  // 🆕 이 화면(타이머)으로 한 운동 기록만 최근 10개
  Future<List<ExerciseRecord>> _loadRecentRecords() async {
    final List<ExerciseRecord> all = await ExerciseDataService.instance.getAllRecords();
    final List<ExerciseRecord> mine = all.where((r) => r.recordId.startsWith('cheer_')).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return mine.take(10).toList();
  }

  void _refreshRecords() {
    if (!mounted) return;
    setState(() => _recentRecordsFuture = _loadRecentRecords());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appLanguage.removeListener(_onLanguageChanged);
    _timer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  // 다른 앱으로 나가거나 화면을 벗어나면 자동 일시정지 (자녀 타이머와 같은 규칙)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (_isRunning) _stopTicking();
    }
  }

  // ---------------------------------------------------------------------------
  // 타이머 동작
  // ---------------------------------------------------------------------------

  void _stopTicking() {
    _timer?.cancel();
    _accumulatedAtAnchor = _elapsedSeconds;
    _anchorTime = null;
    WakelockPlus.disable();
    if (mounted) setState(() => _isRunning = false);
  }

  Future<void> _start() async {
    if (!_leaveNoticeShown && _elapsedSeconds == 0) {
      _leaveNoticeShown = true;
      await _showLeaveNotice();
      if (!mounted) return;
    }
    await WakelockPlus.enable();
    _accumulatedAtAnchor = _elapsedSeconds;
    _anchorTime = DateTime.now();
    setState(() => _isRunning = true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_anchorTime == null || !mounted) return;
    final int computed = _accumulatedAtAnchor + DateTime.now().difference(_anchorTime!).inSeconds;
    setState(() => _elapsedSeconds = computed);

    // 총 경과시간 ÷ 5분 = 지금까지 쌓였어야 할 별 (학생 타이머와 같은 계산)
    final int shouldHave = computed ~/ ExerciseStarService.secondsPerStar;
    final int newly = shouldHave - _starsAccrued;
    if (newly > 0) {
      _starsAccrued = shouldHave;
      ExerciseStarService.addTimeStars(newly);
    }
  }

  Future<void> _onMainButton() async {
    if (_isFinishing) return;
    if (_isRunning) {
      _stopTicking();
      await _showPauseDialog();
    } else {
      await _start();
    }
  }

  Future<void> _finish({bool thenLeave = false}) async {
    if (_isFinishing) return;
    if (_isRunning) _stopTicking();

    final int minutes = _elapsedSeconds ~/ 60;
    if (minutes < 1) {
      _resetSession();
      if (thenLeave && mounted) Navigator.of(context).pop();
      return;
    }

    setState(() => _isFinishing = true);
    final int timeStars = _starsAccrued;
    final String typeId = _selectedTypeId;
    final ExerciseSessionResult result = await ExerciseStarService.finishSession(sessionMinutes: minutes);
    final ExerciseRecord? savedRecord = await _saveExerciseRecord(minutes, typeId);
    if (!mounted) return;
    setState(() => _isFinishing = false);

    // 🆕 끝나면 바로 "별 결과 + 운동 기록" 팝업. "세부 기록하기"를 누르면
    // 방금 고른 종목의 기록 화면이 열리고, 운동 시간이 이미 채워져 있음
    final bool wantsDetail = await _showResultDialog(minutes, timeStars, result, typeId, savedRecord);
    _resetSession();
    if (wantsDetail && savedRecord != null && mounted) {
      await _openRecordDetail(typeId, savedRecord);
    }
    _refreshRecords(); // 🆕 아래 "나의 운동 기록" 목록에 바로 보이게
    if (thenLeave && mounted) Navigator.of(context).pop();
  }

  void _resetSession() {
    if (!mounted) return;
    setState(() {
      _elapsedSeconds = 0;
      _accumulatedAtAnchor = 0;
      _starsAccrued = 0;
      _anchorTime = null;
    });
  }

  // 끝낸 운동을 일반 플래너 운동 기록에도 저장 (캘린더·운동 분석에 함께 보임)
  Future<ExerciseRecord?> _saveExerciseRecord(int minutes, String typeId) async {
    try {
      final ExerciseRecord record = ExerciseRecord(
        recordId: 'cheer_${DateTime.now().millisecondsSinceEpoch}',
        exerciseTypeId: typeId,
        date: DateTime.now(),
        durationMin: minutes,
        rpe: null, // 🆕 [2026-09-30] 타이머 운동은 힘든 정도를 적지 않음 → 평균 강도 계산에서 빠짐
        avgHeartRateBpm: null,
        maxHeartRateBpm: null,
        memo: cs('recordMemo'),
        detail: <String, dynamic>{},
      );
      await ExerciseDataService.instance.addRecord(record);
      return record;
    } catch (e) {
      debugPrint('[CheerStarsScreen] 운동 기록 저장 실패(별은 이미 안전): $e');
      return null;
    }
  }

  // 🆕 방금 저장된 기록을 "수정" 상태로 열어서, 거리·걸음수 같은 세부 내용만 더 적게 함.
  // 기록 화면(today_exercise_screen.dart)은 한 줄도 고치지 않고 그대로 사용.
  Future<void> _openRecordDetail(String typeId, ExerciseRecord record) async {
    final ExerciseType? type = await ExerciseDataService.instance.getExerciseTypeById(typeId);
    if (type == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TodayExerciseScreen(exerciseType: type, existingRecord: record)),
    );
  }

  Future<void> _confirmLeave() async {
    if (_isRunning) _stopTicking();
    final bool? finishAndLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _goldDialog(
        title: cs('leaveTitle'),
        message: cs('leaveMsg'),
        actions: [
          _dialogButton(cs('btnKeepGoing'), filled: false, onTap: () => Navigator.pop(dialogContext, false)),
          _dialogButton(cs('btnFinishLeave'), filled: true, onTap: () => Navigator.pop(dialogContext, true)),
        ],
      ),
    );
    if (finishAndLeave == true) {
      await _finish(thenLeave: true);
    }
  }

  // ---------------------------------------------------------------------------
  // 안내창
  // ---------------------------------------------------------------------------

  Future<void> _showLeaveNotice() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _goldDialog(
        icon: Icons.shield_moon_outlined,
        title: cs('stayTitle'),
        message: cs('stayMsg'),
        actions: [
          _dialogButton(cs('btnGotIt'), filled: true, onTap: () => Navigator.pop(dialogContext)),
        ],
      ),
    );
  }

  Future<void> _showPauseDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _goldDialog(
        title: cs('pauseTitle'),
        message: cs('pauseMsg'),
        actions: [
          _dialogButton(cs('btnContinue'), filled: false, onTap: () {
            Navigator.pop(dialogContext);
            _start();
          }),
          _dialogButton(cs('btnFinish'), filled: true, onTap: () {
            Navigator.pop(dialogContext);
            _finish();
          }),
        ],
      ),
    );
  }

  // 🆕 [2026-09-29] 운동을 끝내면 뜨는 팝업 — 별 결과 + 운동 기록 안내를 한 창에.
  // 운동 모듈의 고급 팝업 부품(LuxuryDialogFrame / luxuryDialogHeader)을 그대로 써서
  // 일반 플래너 운동 화면들과 같은 모양. "세부 기록하기"를 누르면 true를 돌려줌.
  Future<bool> _showResultDialog(
      int minutes,
      int timeStars,
      ExerciseSessionResult result,
      String typeId,
      ExerciseRecord? savedRecord,
      ) async {
    final int total = timeStars + result.bonusStars;
    final _ExerciseChoice choice = _choices.firstWhere((c) => c.typeId == typeId, orElse: () => _choices.last);

    Widget starRow(String label, String value, {bool strong = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: GoogleFonts.notoSansKr(color: strong ? _cream : Colors.white70, fontSize: strong ? 13.5 : 12.5, fontWeight: strong ? FontWeight.bold : FontWeight.normal)),
            ),
            Text(value, style: GoogleFonts.notoSansKr(color: _gold, fontSize: strong ? 17 : 12.5, fontWeight: strong ? FontWeight.w900 : FontWeight.bold)),
          ],
        ),
      );
    }

    final bool? wantsDetail = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: LuxuryDialogFrame(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                luxuryDialogHeader(
                  icon: Icons.emoji_events_rounded,
                  en: csEn('resultTitle'),
                  ko: csKo('resultTitle'),
                  translations: kCheerStarsText['resultTitle'], // 🆕 [다국어] English·10개 언어
                ),

                // ① 오늘 운동 한 줄 요약
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_gold.withOpacity(0.18), _gold.withOpacity(0.04)]),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _gold.withOpacity(0.45)),
                  ),
                  child: Row(
                    children: [
                      Icon(choice.icon, color: _gold, size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(choice.label, style: GoogleFonts.notoSansKr(color: _cream, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      Text(cs('nMin', args: {'n': minutes}), style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 24)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ② 받은 별 내역
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: ExerciseTheme.pageBg, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      starRow(cs('resultTimeStars'), '+$timeStars'),
                      ...result.bonusKeys.map((k) => starRow(cs('bonus_$k'), '+${ExerciseStarService.bonusCategoryStars[k] ?? 0}')),
                      const Divider(color: Colors.white12, height: 18),
                      starRow(cs('resultTotal'), '+${cs('nStars', args: {'n': total})}', strong: true),
                    ],
                  ),
                ),

                // ③ 운동 기록 안내
                if (savedRecord != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ExerciseTheme.pageBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _gold.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.edit_note_rounded, color: _gold, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cs('resultSaved', args: {'ex': choice.label, 'm': minutes}),
                            style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, height: 1.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          savedRecord != null ? cs('btnLater') : cs('btnOk'),
                          style: GoogleFonts.notoSansKr(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                    if (savedRecord != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ExerciseTheme.brandGolden,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            cs('btnDetail'),
                            style: GoogleFonts.notoSansKr(color: ExerciseTheme.pageBg, fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return wantsDetail == true;
  }

  Widget _goldDialog({
    IconData? icon,
    required String title,
    String? message,
    Widget? messageWidget,
    required List<Widget> actions,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF11192E), Color(0xFF0A0F1E)],
          ),
          border: Border.all(color: _gold.withOpacity(0.5), width: 1.2),
          boxShadow: [
            BoxShadow(color: _gold.withOpacity(0.15), blurRadius: 30, spreadRadius: 1),
            const BoxShadow(color: Colors.black, blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: _gold, size: 32),
              const SizedBox(height: 12),
            ],
            Text(title, textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: _gold, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (messageWidget != null) messageWidget,
            if (message != null)
              Text(message, textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, height: 1.6)),
            const SizedBox(height: 20),
            Row(
              children: [
                for (int i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: actions[i]),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogButton(String label, {required bool filled, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: filled ? _gold : const Color(0xFF1E293B),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: GoogleFonts.notoSansKr(color: filled ? _pageBg : Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 화면
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _elapsedSeconds == 0 && !_isRunning,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: _pageBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          toolbarHeight: 74,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🆕 [다국어] 한국어 = 영문(20)+한글(17) 두 줄 / 그 외 = 그 언어 한 줄
              if (appLanguage.isDefault) ...[
                Text(csEn('appTitle'), style: GoogleFonts.gowunBatang(color: _gold, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.2)),
                const SizedBox(height: 2),
                Text(csKo('appTitle'), style: GoogleFonts.notoSansKr(color: _cream, fontWeight: FontWeight.bold, fontSize: 17)),
              ] else
                Text(
                  cs('appTitle'),
                  style: appLanguage.isEnglishOnly
                      ? GoogleFonts.gowunBatang(color: _gold, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.2)
                      : GoogleFonts.notoSans(color: _gold, fontWeight: FontWeight.bold, fontSize: 19),
                ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('secBank'),
              const SizedBox(height: 10),
              _buildBankCard(),
              const SizedBox(height: 12),
              _buildModeButtons(), // 🆕 [가족 활동 체크] 반반 버튼: 타이머로 모으기 / 가족 활동 체크
              const SizedBox(height: 26),
              KeyedSubtree(key: _chooseKey, child: _buildSectionTitle('secChoose')),
              const SizedBox(height: 10),
              _buildExerciseChips(),
              const SizedBox(height: 26),
              _buildSectionTitle('secTimer'),
              const SizedBox(height: 10),
              _buildTimerCard(),
              const SizedBox(height: 26),
              _buildSectionTitle('secWorkouts'), // 🆕 수정·삭제 (삼색 연필)
              const SizedBox(height: 10),
              _buildRecentRecords(),
              const SizedBox(height: 26),
              _buildSectionTitle('secCollection'), // 🆕 자녀에게 보내기 바로 위
              const SizedBox(height: 10),
              _buildStarCollectionCard(),
              const SizedBox(height: 26),
              _buildSectionTitle('secSend'),
              const SizedBox(height: 10),
              _buildSendCard(),
              const SizedBox(height: 26),
              _buildSectionTitle('secHow'),
              const SizedBox(height: 10),
              _buildRulesCard(),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 [가족 활동 체크 2026-09-30] 별 통장 바로 아래 반반 버튼
  // 왼쪽: 아래 운동 고르기로 내려감 / 오른쪽: 가족 활동 체크 금테 팝업
  Widget _buildModeButtons() {
    Widget modeButton({required IconData icon, required String label, required bool filled, required VoidCallback onTap}) {
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            gradient: filled ? const LinearGradient(colors: [Color(0xFFE9C860), Color(0xFFD4AF37)]) : null,
            color: filled ? null : _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _gold.withOpacity(filled ? 1.0 : 0.55), width: 1.2),
            boxShadow: filled ? [BoxShadow(color: _gold.withOpacity(0.25), blurRadius: 14, spreadRadius: 0.5)] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: filled ? _pageBg : _gold),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, style: GoogleFonts.notoSansKr(color: filled ? _pageBg : _gold, fontWeight: FontWeight.w900, fontSize: 13.5)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: modeButton(
            icon: Icons.timer_outlined,
            label: cs('btnTimerMode'),
            filled: false,
            onTap: () {
              final ctx = _chooseKey.currentContext;
              if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: modeButton(
            icon: Icons.fact_check_rounded,
            label: cs('btnCheckMode'),
            filled: true,
            onTap: () async {
              await showFamilyCheckDialog(context);
              if (mounted) setState(() {}); // 통장·수집 현황은 실시간으로 바뀜
            },
          ),
        ),
      ],
    );
  }

  // 🆕 [다국어] 중간 제목: 한국어 = 영문+한글 두 줄 / 그 외 = 그 언어 한 줄
  Widget _buildSectionTitle(String key) {
    if (!appLanguage.isDefault) {
      return Text(
        cs(key),
        style: appLanguage.isEnglishOnly
            ? GoogleFonts.gowunBatang(color: _gold, fontWeight: FontWeight.bold, fontSize: 14.5, letterSpacing: 0.6)
            : GoogleFonts.notoSans(color: _gold, fontWeight: FontWeight.bold, fontSize: 14),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(csEn(key), style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.6)),
        Text(csKo(key), style: GoogleFonts.notoSansKr(color: _gold, fontWeight: FontWeight.bold, fontSize: 13.5)),
      ],
    );
  }

  // ---------------- 나의 별 통장 ----------------
  Widget _buildBankCard() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ExerciseStarService.watchMyBank(),
      builder: (context, snapshot) {
        final Map<String, dynamic> data = snapshot.data?.data() ?? {};
        final int balance = (data['balance'] as num?)?.toInt() ?? 0;
        final int totalEarned = (data['totalEarned'] as num?)?.toInt() ?? 0;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_gold.withOpacity(0.22), _gold.withOpacity(0.04)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gold.withOpacity(0.6), width: 1.3),
            boxShadow: [BoxShadow(color: _gold.withOpacity(0.12), blurRadius: 18, spreadRadius: 1)],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cs('bankSaved'), style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12.5)),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(cs('nStars', args: {'n': balance}), style: GoogleFonts.notoSansKr(color: _gold, fontSize: 30, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 4),
                    Text(cs('bankTotal', args: {'n': totalEarned}), style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 11.5)),
                  ],
                ),
              ),
              Container(
                width: 54,
                height: 54,
                child: const FacetedGoldStar(size: 54), // 🆕 [2026-10-01] 고급 황금장 별 (원장님 그림의 앞쪽 별 모양)
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- 운동 고르기 ----------------
  Widget _buildExerciseChips() {
    final bool locked = _elapsedSeconds > 0; // 운동 중에는 종목을 바꾸지 못함
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _choices.map((c) {
        final bool isSel = _selectedTypeId == c.typeId;
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: locked ? null : () => setState(() => _selectedTypeId = c.typeId),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSel ? _gold : _cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSel ? _gold : _gold.withOpacity(locked ? 0.12 : 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(c.icon, size: 15, color: isSel ? _pageBg : (locked ? Colors.white24 : _gold)),
                const SizedBox(width: 5),
                Text(
                  c.label,
                  style: GoogleFonts.notoSansKr(
                    color: isSel ? _pageBg : (locked ? Colors.white24 : Colors.white70),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------- 운동 타이머 ----------------
  bool get _isOverGoal => _elapsedSeconds > _goalSeconds;

  // 60분이 넘으면 막대가 "가장 최근 60분"만 보여줌 → 맨 왼쪽 칸 번호가 하나씩 밀려남
  int get _windowFirstSegment => _isOverGoal ? (_elapsedSeconds ~/ _segmentSeconds) - 5 : 0;

  String _formatTime(int totalSeconds) {
    final int h = totalSeconds ~/ 3600;
    final int m = (totalSeconds % 3600) ~/ 60;
    final int s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _statusText {
    final int minutes = _elapsedSeconds ~/ 60;
    if (!_isOverGoal) {
      final int pct = ((_elapsedSeconds / _goalSeconds) * 100).floor();
      return cs('statusUnder', args: {'m': minutes, 'p': pct});
    }
    final int inSegment = (_elapsedSeconds % _segmentSeconds) ~/ 60;
    return cs('statusOver', args: {'m': minutes, 's': inSegment});
  }

  Widget _buildTimerCard() {
    final String mainLabel = _isFinishing
        ? cs('btnSaving')
        : (_isRunning ? cs('btnPause') : (_elapsedSeconds == 0 ? cs('btnStart') : cs('btnResume')));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withOpacity(0.3), width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            _formatTime(_elapsedSeconds),
            style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 60, fontWeight: FontWeight.w700, height: 1.0, letterSpacing: 1.0),
          ),
          const SizedBox(height: 6),
          Text(
            cs('sessionStars', args: {'n': _starsAccrued}),
            style: GoogleFonts.notoSansKr(color: _gold, fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(_statusText, style: GoogleFonts.notoSansKr(color: _cream, fontSize: 12.5, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          _buildSixColorBar(),
          const SizedBox(height: 6),
          _buildBarLabels(),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isFinishing ? null : _onMainButton,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRunning ? const Color(0xFF1E293B) : _gold,
                disabledBackgroundColor: const Color(0xFF1F2937),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _gold.withOpacity(_isRunning ? 0.7 : 0.0), width: 1.2),
                ),
              ),
              child: Text(
                mainLabel,
                style: GoogleFonts.notoSansKr(color: _isRunning ? _gold : _pageBg, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
          if (_elapsedSeconds > 0 && !_isRunning && !_isFinishing) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _finish(),
              child: Text(cs('btnFinishToday'), style: GoogleFonts.notoSansKr(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSixColorBar() {
    final int first = _windowFirstSegment;
    return Row(
      children: [
        // 60분이 넘으면 왼쪽에 가위 표시 (가장 오래된 칸이 잘려 나감)
        if (_isOverGoal) ...[
          const Icon(Icons.content_cut_rounded, color: _gold, size: 16),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double itemWidth = (constraints.maxWidth - 2.0) / 6;
              return Container(
                height: 18,
                decoration: BoxDecoration(
                  color: _pageBg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _gold.withOpacity(0.3), width: 1.0),
                ),
                child: Row(
                  children: List.generate(6, (i) {
                    final int seg = first + i;
                    final double fill = ((_elapsedSeconds - seg * _segmentSeconds) / _segmentSeconds).clamp(0.0, 1.0).toDouble();
                    return Container(
                      width: itemWidth,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        border: i < 5 ? Border(right: BorderSide(color: _gold.withOpacity(0.25), width: 1.0)) : null,
                      ),
                      child: Stack(
                        children: [
                          if (fill > 0)
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: fill,
                              child: Container(color: _rainbow[seg % 6]),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBarLabels() {
    final int first = _windowFirstSegment;
    return Padding(
      padding: EdgeInsets.only(left: _isOverGoal ? 20 : 0),
      child: Row(
        children: List.generate(6, (i) {
          final int seg = first + i;
          final String text = _isOverGoal
              ? cs('barOver', args: {'a': seg * 10, 'b': (seg + 1) * 10})
              : cs('barUnder', args: {'m': (seg + 1) * 10, 'p': (((seg + 1) / 6) * 100).round()});
          return Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, height: 1.2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------------- 🆕 나의 운동 기록 (삼색 연필로 수정·삭제) ----------------
  int _choiceIndex(String typeId) {
    final int i = _choices.indexWhere((c) => c.typeId == typeId);
    return i < 0 ? _choices.length - 1 : i;
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  // 자기주도 플래너 일정 목록과 같은 삼색선 + 금색 연필 아이콘
  Widget _threeColorPencil() {
    return SizedBox(
      width: 30,
      height: 24,
      child: Stack(
        children: [
          Positioned(left: 0, top: 3, child: _pencilLine(const Color(0xFFEF4444), 22)),
          Positioned(left: 0, top: 9, child: _pencilLine(const Color(0xFFFACC15), 22)),
          Positioned(left: 0, top: 15, child: _pencilLine(const Color(0xFF3B82F6), 18)),
          const Positioned(right: 0, bottom: 0, child: Icon(Icons.edit_rounded, color: _gold, size: 13)),
        ],
      ),
    );
  }

  Widget _pencilLine(Color color, double width) {
    return Container(width: width, height: 3.5, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)));
  }

  Widget _buildRecentRecords() {
    _recentRecordsFuture ??= _loadRecentRecords(); // 🆕 준비가 안 됐으면 여기서 바로 불러옴
    return FutureBuilder<List<ExerciseRecord>>(
      future: _recentRecordsFuture,
      builder: (context, snapshot) {
        final List<ExerciseRecord> records = snapshot.data ?? [];
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(color: _gold, strokeWidth: 2)));
        }
        if (records.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
            child: Text(cs('recordsEmpty'), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 12.5)),
          );
        }
        return Column(
          children: records.map((r) {
            final int idx = _choiceIndex(r.exerciseTypeId);
            final _ExerciseChoice choice = _choices[idx];
            final String when = '${_two(r.date.month)}/${_two(r.date.day)} ${_two(r.date.hour)}:${_two(r.date.minute)}';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF050B14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Container(width: 16, height: 16, decoration: BoxDecoration(color: _typeColors[idx], borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 12),
                  Text(when, style: GoogleFonts.gowunBatang(color: _gold, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${choice.label}  ${cs('nMin', args: {'n': r.durationMin})}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _openEditDialog(r),
                    child: Padding(padding: const EdgeInsets.all(6), child: _threeColorPencil()),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // 🆕 자기주도 플래너 "알람 설정"과 같은 가운데 금테 팝업
  // (왼쪽 아래 Delete / 삭제, 오른쪽 Close / 닫기 + 금색 Save / 저장)
  Future<void> _openEditDialog(ExerciseRecord record) async {
    String typeId = _choices.any((c) => c.typeId == record.exerciseTypeId) ? record.exerciseTypeId : 'etc';
    final TextEditingController durationController = TextEditingController(text: '${record.durationMin}');
    final TextEditingController memoController = TextEditingController(text: record.memo);
    String? errorText;
    int newMinutes = record.durationMin;

    final String? action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Widget fieldLabel(String key) => Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 8),
            child: Text(cs(key), style: GoogleFonts.gowunBatang(color: _gold, fontWeight: FontWeight.bold, fontSize: 15)),
          );

          InputDecoration fieldDecoration({String? suffix}) => InputDecoration(
            suffixText: suffix,
            suffixStyle: GoogleFonts.notoSansKr(color: _gold, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF111827),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _gold)),
          );

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
              decoration: BoxDecoration(
                color: const Color(0xFF050B14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _gold, width: 1.5),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cs('editTitle'), style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),

                    fieldLabel('fldExercise'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_choices.length, (i) {
                        final _ExerciseChoice c = _choices[i];
                        final bool isSel = typeId == c.typeId;
                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => setDialogState(() => typeId = c.typeId),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSel ? _typeColors[i] : const Color(0xFF111827),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSel ? _typeColors[i] : Colors.white.withOpacity(0.1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isSel) ...[
                                  Container(width: 11, height: 11, decoration: BoxDecoration(color: _typeColors[i], borderRadius: BorderRadius.circular(2))),
                                  const SizedBox(width: 7),
                                ],
                                Text(c.label, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),

                    fieldLabel('fldDuration'),
                    TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 16),
                      decoration: fieldDecoration(suffix: cs('unitMin')),
                    ),

                    fieldLabel('fldDate'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Text(
                        '${record.date.year}.${_two(record.date.month)}.${_two(record.date.day)}  ${_two(record.date.hour)}:${_two(record.date.minute)}',
                        style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 16),
                      ),
                    ),

                    fieldLabel('fldMemo'),
                    TextField(
                      controller: memoController,
                      maxLines: 2,
                      style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14.5),
                      decoration: fieldDecoration(),
                    ),

                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => Navigator.of(dialogContext).pop('detail'),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_note_rounded, color: _gold, size: 18),
                          const SizedBox(width: 6),
                          Text(cs('openDetail'), style: GoogleFonts.notoSansKr(color: _gold, fontWeight: FontWeight.bold, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      cs('editNote'),
                      style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 11.5),
                    ),

                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(errorText!, style: GoogleFonts.notoSansKr(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],

                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Flexible(
                          child: TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop('delete'),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(cs('btnDelete'), style: GoogleFonts.notoSansKr(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(cs('btnClose'), style: GoogleFonts.notoSansKr(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: () {
                            final int? m = int.tryParse(durationController.text.trim());
                            if (m == null || m < 1 || m > 600) {
                              setDialogState(() => errorText = cs('errDuration'));
                              return;
                            }
                            newMinutes = m;
                            Navigator.of(dialogContext).pop('save');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _gold,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text(cs('btnSave'), style: GoogleFonts.notoSansKr(color: _pageBg, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    final String memo = memoController.text.trim();
    // 🆕 [빨간 화면 수정 2026-09-30] 창이 닫히는 움직임이 끝난 뒤에 정리
    Future.delayed(const Duration(milliseconds: 500), () {
      durationController.dispose();
      memoController.dispose();
    });
    if (!mounted || action == null) return;

    if (action == 'save') {
      try {
        await ExerciseDataService.instance.updateRecord(ExerciseRecord(
          recordId: record.recordId,
          exerciseTypeId: typeId,
          date: record.date,
          durationMin: newMinutes,
          rpe: record.rpe,
          avgHeartRateBpm: record.avgHeartRateBpm,
          maxHeartRateBpm: record.maxHeartRateBpm,
          memo: memo,
          // 종목을 바꾸면 이전 종목의 세부 칸(거리·타수 등)은 맞지 않으므로 비움
          detail: typeId == record.exerciseTypeId ? record.detail : <String, dynamic>{},
        ));
      } catch (e) {
        debugPrint('[CheerStarsScreen] 기록 수정 실패: $e');
      }
      _refreshRecords();
    } else if (action == 'delete') {
      final bool? sure = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => _goldDialog(
          icon: Icons.delete_rounded,
          title: cs('delTitle'),
          message: cs('delMsg'),
          actions: [
            _dialogButton(cs('btnCancel'), filled: false, onTap: () => Navigator.pop(dialogContext, false)),
            _dialogButton(cs('btnDel'), filled: true, onTap: () => Navigator.pop(dialogContext, true)),
          ],
        ),
      );
      if (sure == true) {
        await ExerciseDataService.instance.deleteRecord(record.recordId);
        _refreshRecords();
      }
    } else if (action == 'detail') {
      await _openRecordDetail(record.exerciseTypeId, record);
      _refreshRecords();
    }
  }

  // ---------------- 🆕 나의 별 수집 현황 (학생 "나의 성취별 현황"과 같은 구성) ----------------
  Widget _buildStarCollectionCard() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ExerciseStarService.watchMyBank(),
      builder: (context, snapshot) {
        final Map<String, dynamic> data = snapshot.data?.data() ?? {};
        final Map<String, dynamic> monthly = Map<String, dynamic>.from((data['monthly'] as Map?) ?? {});
        final Map<String, dynamic> thisMonth =
        Map<String, dynamic>.from((monthly[ExerciseStarService.monthKey(DateTime.now())] as Map?) ?? {});
        final int timeStars = (thisMonth['timeStars'] as num?)?.toInt() ?? 0;
        final int checkStars = (thisMonth['checkStars'] as num?)?.toInt() ?? 0; // 🆕 [가족 활동 체크]
        final int bonusStars = (thisMonth['bonusStars'] as num?)?.toInt() ?? 0;
        final int minutes = (thisMonth['minutes'] as num?)?.toInt() ?? 0;
        final int sent = (thisMonth['sent'] as num?)?.toInt() ?? 0;
        final Map<String, dynamic> counts = Map<String, dynamic>.from((thisMonth['bonusCounts'] as Map?) ?? {});
        final int total = timeStars + bonusStars + checkStars; // 🆕 가족 활동 별 포함
        final List<String> shownBonus = ExerciseStarService.bonusCategories
            .where((k) => ((counts[k] as num?)?.toInt() ?? 0) > 0)
            .toList();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF11192E), Color(0xFF0A0F1E)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _gold.withOpacity(0.35), width: 1.3),
            boxShadow: [BoxShadow(color: _gold.withOpacity(0.12), blurRadius: 18, spreadRadius: 1)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ① 이번 달 모은 별
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_gold.withOpacity(0.18), Colors.transparent]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gold.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cs('colMonth'), style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12.5)),
                          const SizedBox(height: 4),
                          Text(cs('nStars', args: {'n': total}), style: GoogleFonts.notoSansKr(color: _gold, fontWeight: FontWeight.w900, fontSize: 28)),
                        ],
                      ),
                    ),
                    const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 36),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ② 운동 시간 별 / 가족 활동 별 / 보너스 별 (🆕 3칸)
              Row(
                children: [
                  Expanded(child: _miniStat(Icons.timer_outlined, const Color(0xFF34C759), cs('nStars', args: {'n': timeStars}), cs('colTime'))),
                  const SizedBox(width: 8),
                  Expanded(child: _miniStat(Icons.favorite_rounded, const Color(0xFFFF6B8A), cs('nStars', args: {'n': checkStars}), cs('colCheck'))),
                  const SizedBox(width: 8),
                  Expanded(child: _miniStat(Icons.auto_awesome_rounded, const Color(0xFFAF52DE), cs('nStars', args: {'n': bonusStars}), cs('colBonus'))),
                ],
              ),
              const SizedBox(height: 16),

              // ③ 보너스 별 상세 내역 (색 점)
              Text(cs('colDetail'), style: GoogleFonts.notoSansKr(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              if (shownBonus.isEmpty)
                Text(cs('colEmpty'), style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12))
              else
                ...shownBonus.map((k) {
                  final int n = (counts[k] as num?)?.toInt() ?? 0;
                  final int per = ExerciseStarService.bonusCategoryStars[k] ?? 0;
                  final Color color = _bonusColors[k] ?? _gold;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cs('colBonusRow', args: {'name': cs('bonus_$k'), 'per': per, 'n': n}),
                            style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13.5),
                          ),
                        ),
                        Text('+${per * n}', style: GoogleFonts.notoSansKr(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 16),

              // ④ 이번 달 운동 시간 / 자녀에게 보낸 별
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_gold.withOpacity(0.14), Colors.transparent]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gold.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Expanded(child: _bottomStat(cs('colMonthMin'), cs('nMin', args: {'n': minutes}), _cream)),
                    Container(width: 1, height: 34, color: Colors.white12),
                    Expanded(child: _bottomStat(cs('colSent'), cs('nStars', args: {'n': sent}), const Color(0xFFFF6B8A))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _miniStat(IconData icon, Color iconColor, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11.5)),
        ],
      ),
    );
  }

  Widget _bottomStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.notoSansKr(color: Colors.white60, fontSize: 11.5)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.notoSansKr(color: valueColor, fontWeight: FontWeight.w900, fontSize: 18)),
      ],
    );
  }

  // ---------------- 자녀에게 보내기 ----------------
  // 🆕 [응원 가족 2026-09-30] 보호자 자녀 + 응원 가족 아이를 함께 보여 주고,
  // 아래에 [응원 가족으로 연결] 버튼과 "승인 기다리는 중" 목록을 둠
  Widget _buildSendCard() {
    return FutureBuilder<List<String>>(
      future: _linkedCodesFuture,
      builder: (context, snapshot) {
        final List<String> codes = snapshot.data ?? [];

        final Widget connectButton = SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openSupporterConnectDialog,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _gold.withOpacity(0.6)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.group_add_rounded, color: _gold, size: 18),
            label: Text(cs('supConnectBtn'), style: GoogleFonts.notoSansKr(color: _gold, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        );

        final List<Widget> pendingRows = _pendingTargets
            .map((t) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              const Icon(Icons.hourglass_top_rounded, color: Colors.white38, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(cs('supPending', args: {'c': t.code}), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11.5)),
              ),
            ],
          ),
        ))
            .toList();

        // 응원 가족으로 연결된 아이: 이름 + 이번 달 총 공부 시간·공부한 날 수 (그 이상은 볼 수 없음)
        final List<Widget> supporterRows = _supportInfo.values
            .map((t) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Text(SupporterService.relationEmoji[t.relation] ?? '💛', style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.studentName.isNotEmpty ? t.studentName : cs('codeLabel', args: {'c': t.code}),
                      style: GoogleFonts.notoSansKr(color: _cream, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      cs('supMonthLine', args: {'h': (t.monthMinutes / 60).toStringAsFixed(1), 'd': t.monthDays}),
                      style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(_relationLabel(t.relation, t.relationText), style: GoogleFonts.notoSansKr(color: _gold, fontSize: 11.5, fontWeight: FontWeight.bold)),
            ],
          ),
        ))
            .toList();

        if (codes.isEmpty) {
          // 🔒 자녀 연결 전: 궁금증을 만드는 안내 + 응원 가족 연결 버튼
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_rounded, color: _gold, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cs('sendLocked'),
                            style: GoogleFonts.notoSansKr(color: _cream, fontWeight: FontWeight.bold, fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cs('sendLockedHint'),
                            style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11.5, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              connectButton,
              ...pendingRows,
            ],
          );
        }
        // 자녀 연결 뒤: 보내기 버튼
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gold.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cs('sendLinked', args: {'n': codes.length}), style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12.5)),
              const SizedBox(height: 10),
              ...supporterRows,
              if (supporterRows.isNotEmpty) const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _openSendDialog(codes),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.favorite_rounded, color: _pageBg, size: 18),
                  label: Text(cs('btnSendStars'), style: GoogleFonts.notoSansKr(color: _pageBg, fontWeight: FontWeight.w900, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 10),
              connectButton,
              ...pendingRows,
            ],
          ),
        );
      },
    );
  }

  // 🆕 [응원 가족 2026-09-30] 응원 가족 신청 창 (알람 설정과 같은 금테 가운데 팝업)
  Future<void> _openSupporterConnectDialog() async {
    final TextEditingController codeController = TextEditingController();
    final TextEditingController nameController = TextEditingController(text: (await DkeUserProfile.getRealName()) ?? '');
    final TextEditingController otherController = TextEditingController();
    if (!mounted) return;
    String relation = 'grandma';
    bool sending = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          InputDecoration deco(String hint) => InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.notoSansKr(color: Colors.white30, fontSize: 12.5),
            filled: true,
            fillColor: const Color(0xFF111827),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _gold)),
          );
          Widget fieldLabel(String t) => Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(t, style: GoogleFonts.notoSansKr(color: _gold, fontWeight: FontWeight.bold, fontSize: 12.5)),
          );

          Future<void> submit() async {
            setDialogState(() {
              sending = true;
              errorText = null;
            });
            final String? err = await SupporterService.requestToSupport(
              code: codeController.text.trim(),
              name: nameController.text.trim(),
              relation: relation,
              relationText: relation == 'other' ? otherController.text.trim() : '',
            );
            if (err != null) {
              setDialogState(() {
                sending = false;
                errorText = cs(err);
              });
              return;
            }
            if (dialogContext.mounted) Navigator.pop(dialogContext);
            if (mounted) {
              ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(cs('supReqDone'), style: GoogleFonts.notoSansKr())));
              _refreshSendTargets();
            }
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF050B14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _gold, width: 1.5),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (appLanguage.isDefault) ...[
                      Text(csEn('supDlgTitle'), style: GoogleFonts.gowunBatang(color: _gold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1)),
                      Text(csKo('supDlgTitle'), style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19)),
                    ] else
                      Text(cs('supDlgTitle'), style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 6),
                    Text(cs('supDlgIntro'), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11.5, height: 1.5)),

                    fieldLabel(cs('supCodeLabel')),
                    TextField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: GoogleFonts.notoSans(color: Colors.white, fontSize: 20, letterSpacing: 4),
                      decoration: deco('000000'),
                    ),

                    fieldLabel(cs('supNameLabel')),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14),
                      decoration: deco(cs('supNameLabel')),
                    ),

                    fieldLabel(cs('supRelLabel')),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: SupporterService.supporterRelations.map((r) {
                        final bool sel = relation == r;
                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => setDialogState(() => relation = r),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: sel ? _gold : const Color(0xFF111827),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: sel ? _gold : Colors.white12),
                            ),
                            child: Text(
                              '${SupporterService.relationEmoji[r] ?? ''} ${cs('rel_$r')}',
                              style: GoogleFonts.notoSansKr(color: sel ? _pageBg : Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (relation == 'other') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: otherController,
                        style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13.5),
                        decoration: deco(cs('supOtherHint')),
                      ),
                    ],
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(errorText!, style: GoogleFonts.notoSansKr(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Spacer(),
                        TextButton(
                          onPressed: sending ? null : () => Navigator.pop(dialogContext),
                          child: Text(cs('btnClose'), style: GoogleFonts.notoSansKr(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: sending ? null : submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _gold,
                            disabledBackgroundColor: const Color(0xFF1F2937),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text(sending ? cs('btnSaving') : cs('supSendReq'), style: GoogleFonts.notoSansKr(color: _pageBg, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      codeController.dispose();
      nameController.dispose();
      otherController.dispose();
    });
  }

  // 연결된 자녀들의 이름 불러오기 (이름이 없으면 "코드 123456"으로 표시)
  Future<Map<String, String>> _loadChildNames(List<String> codes) async {
    final Map<String, String> names = {};
    for (final code in codes) {
      // 🆕 [응원 가족] 응원 가족은 아이 문서를 읽을 수 없으니 요약에서 받은 이름을 씀
      if (_supporterCodes.contains(code)) {
        final String n = _supportInfo[code]?.studentName ?? '';
        names[code] = n.isNotEmpty ? n : cs('codeLabel', args: {'c': code});
        continue;
      }
      try {
        final snap = await FamilyLinkService.watch(code).first.timeout(const Duration(seconds: 5));
        final String? name = snap.data()?['studentName'] as String?;
        names[code] = (name != null && name.trim().isNotEmpty) ? name : cs('codeLabel', args: {'c': code});
      } catch (_) {
        names[code] = cs('codeLabel', args: {'c': code});
      }
    }
    return names;
  }

  // 🆕 [부모 운동 응원별 2026-09-29 수정] 자녀에게 별 보내기 창
  // - 받을 자녀를 여러 명 한꺼번에 고름 (처음엔 모두 선택 — 한 명만 빠지는 일 방지)
  // - 일반 응원·특별 축하 모두 "한 명당 몇 개"를 직접 정함 (특별 축하도 전부 보내지 않음)
  // - 일반 응원은 한 명당 최대 2,500개, 특별 축하는 모아 둔 별 안에서 자유
  // - 응원 문구 6개 중 고르거나 직접 씀 (cheer_phrases.dart, 12개 언어)
  // - 🆕 [다국어] 창 안의 모든 글자는 cheer_stars_i18n.dart에서 꺼냄
  Future<void> _openSendDialog(List<String> codes) async {
    // 🆕 [2026-09-30] 창 위쪽에 총 별 / 보낸 별 / 현재 별을 함께 보여줌
    final (int totalEarned, int totalSent, int balance) = await ExerciseStarService.getMyBankSummary();
    final Map<String, String> names = await _loadChildNames(codes);
    String guardianRelation = await SupporterService.getMyGuardianRelation(); // 🆕 [응원 가족] 보호자가 고른 관계 기억
    final String myName = (await DkeUserProfile.getRealName()) ?? '';
    if (!mounted) return;
    if (balance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(cs('noStars'), style: GoogleFonts.notoSansKr())),
      );
      return;
    }

    const int cap = ExerciseStarService.maxStarsPerSend;
    final Set<String> selectedCodes = codes.toSet(); // 처음엔 모든 자녀 선택
    bool isSpecial = false;
    bool sending = false;
    String? errorText;
    final int firstMax = balance ~/ codes.length;
    final TextEditingController countController =
    TextEditingController(text: '${firstMax >= 10 ? 10 : (firstMax > 0 ? firstMax : 1)}');
    final List<String> phrases = cheerPhrasesFor(appLanguage.current); // 지금 언어의 응원 문구 6개
    final TextEditingController messageController = TextEditingController(text: phrases[3]);
    final FocusNode messageFocus = FocusNode(); // 🆕 [2026-09-30] 문구를 고르면 바로 고쳐 쓸 수 있게
    final GlobalKey messageFieldKey = GlobalKey(); // 🆕 [2026-09-30] 문구를 고르면 고쳐 쓰는 칸으로 자동 이동

    // 서비스가 돌려준 오류 이름표를 지금 언어 문장으로
    String errorToText(String code) {
      if (code.startsWith('errBalanceLow:')) {
        return cs('errBalanceLow', args: {'b': code.substring('errBalanceLow:'.length)});
      }
      if (code == 'errCap') return cs('errCap', args: {'cap': cap});
      return cs(code);
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final int childCount = selectedCodes.length;
          final int perChild = int.tryParse(countController.text.trim()) ?? 0;
          final int byBalance = childCount == 0 ? 0 : balance ~/ childCount;
          final int maxPerChild = isSpecial ? byBalance : (byBalance < cap ? byBalance : cap);

          Widget choiceChip(String label, bool selected, VoidCallback onTap) {
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: sending ? null : onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? _gold : _pageBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? _gold : _gold.withOpacity(0.3)),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.notoSansKr(color: selected ? _pageBg : Colors.white70, fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
            );
          }

          Widget label(String text) => Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(text, style: GoogleFonts.notoSansKr(color: _gold, fontWeight: FontWeight.bold, fontSize: 13)),
          );

          InputDecoration inputDecoration({String? suffix}) => InputDecoration(
            suffixText: suffix,
            suffixStyle: GoogleFonts.notoSansKr(color: _gold, fontSize: 12),
            filled: true,
            fillColor: _pageBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _gold.withOpacity(0.3))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _gold)),
          );

          Future<void> send() async {
            if (selectedCodes.isEmpty) {
              setDialogState(() => errorText = cs('errPickChild'));
              return;
            }
            final int stars = int.tryParse(countController.text.trim()) ?? 0;
            if (stars <= 0) {
              setDialogState(() => errorText = cs('errCount'));
              return;
            }
            if (stars * selectedCodes.length > balance) {
              setDialogState(() => errorText = cs('errNotEnough', args: {'b': balance, 'max': maxPerChild}));
              return;
            }
            if (!isSpecial && stars > cap) {
              setDialogState(() => errorText = cs('errCap', args: {'cap': cap}));
              return;
            }
            final String msg = messageController.text.trim().isEmpty ? cs('defaultMsg') : messageController.text.trim();
            setDialogState(() {
              sending = true;
              errorText = null;
            });

            final List<String> sentNames = [];
            String? failMessage;
            SupporterService.setMyGuardianRelation(guardianRelation);
            for (final String code in selectedCodes.toList()) {
              // 🆕 [응원 가족 2026-09-30] 응원 가족으로 연결된 아이인지, 보호자로 연결된 아이인지
              final bool asSup = _supporterCodes.contains(code);
              final SupportTarget? st = _supportInfo[code];
              final String rel = asSup ? (st?.relation ?? 'other') : guardianRelation;
              final String relText = asSup ? (st?.relationText ?? '') : '';
              final String fromName = asSup && (st?.myName ?? '').isNotEmpty ? st!.myName : myName;
              final String who =
                  '${SupporterService.relationEmoji[rel] ?? ''} ${_relationLabel(rel, relText)}${fromName.isNotEmpty ? ' ($fromName)' : ''}';
              final String? error = await ExerciseStarService.sendStarsToChild(
                code: code,
                stars: stars,
                message: msg,
                isSpecial: isSpecial,
                fromName: fromName,
                fromRelation: rel,
                fromRelationText: relText,
                asSupporter: asSup,
              );
              if (error != null) {
                failMessage = '${names[code] ?? cs('codeLabel', args: {'c': code})}: ${errorToText(error)}';
                break;
              }
              // 자녀 화면에 응원 팝업 (맨 위에 "누가 보냈는지" 한 줄)
              final String popup = '${cs('popupFrom', args: {'who': who})}\n'
                  '${isSpecial ? cs('popupSpecial', args: {'n': stars, 'msg': msg}) : cs('popupNormal', args: {'n': stars, 'msg': msg})}';
              if (asSup) {
                await SupporterService.pushMessageAsSupporter(code, popup);
              } else {
                await FamilyLinkService.pushEncouragementToChild(code, message: popup);
              }
              sentNames.add(names[code] ?? cs('codeLabel', args: {'c': code}));
            }

            if (failMessage != null) {
              setDialogState(() {
                sending = false;
                errorText = sentNames.isEmpty ? failMessage : cs('errPartial', args: {'names': sentNames.join(', '), 'fail': failMessage!});
              });
              return;
            }
            ExerciseStarService.creditCheerMessage(); // 🆕 [가족 활동 체크] 응원을 보냈으니 "응원 문자" 자동 인정 (하루 2회까지)
            if (dialogContext.mounted) Navigator.pop(dialogContext);
            if (mounted) {
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(content: Text(cs('sentOk', args: {'names': sentNames.join(', '), 'n': stars}), style: GoogleFonts.notoSansKr())),
              );
            }
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF11192E), Color(0xFF0A0F1E)],
                ),
                border: Border.all(color: _gold.withOpacity(0.5), width: 1.2),
                boxShadow: [BoxShadow(color: _gold.withOpacity(0.15), blurRadius: 30, spreadRadius: 1)],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 창 제목: 한국어 = 영문+한글 / 그 외 = 그 언어 한 줄
                    if (appLanguage.isDefault) ...[
                      Center(child: Text(csEn('sendTitle'), style: GoogleFonts.gowunBatang(color: _gold, fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 1.0))),
                      Center(child: Text(csKo('sendTitle'), style: GoogleFonts.notoSansKr(color: _cream, fontWeight: FontWeight.bold, fontSize: 14))),
                    ] else
                      Center(child: Text(cs('sendTitle'), textAlign: TextAlign.center, style: GoogleFonts.notoSans(color: _gold, fontWeight: FontWeight.bold, fontSize: 17))),
                    const SizedBox(height: 6),
                    // 🆕 [2026-09-30] 총 별 · 보낸 별 · 현재 별 세 칸
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: _pageBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _gold.withOpacity(0.25), width: 1),
                            ),
                            child: Column(
                              children: [
                                FittedBox(fit: BoxFit.scaleDown, child: Text(cs('sumTotal'), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11))),
                                const SizedBox(height: 2),
                                FittedBox(fit: BoxFit.scaleDown, child: Text(cs('nStars', args: {'n': totalEarned}), style: GoogleFonts.notoSansKr(color: _cream, fontWeight: FontWeight.w900, fontSize: 15))),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: _pageBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _gold.withOpacity(0.25), width: 1),
                            ),
                            child: Column(
                              children: [
                                FittedBox(fit: BoxFit.scaleDown, child: Text(cs('sumSent'), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11))),
                                const SizedBox(height: 2),
                                FittedBox(fit: BoxFit.scaleDown, child: Text(cs('nStars', args: {'n': totalSent}), style: GoogleFonts.notoSansKr(color: Colors.white60, fontWeight: FontWeight.w900, fontSize: 15))),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: _pageBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _gold, width: 1.3),
                            ),
                            child: Column(
                              children: [
                                FittedBox(fit: BoxFit.scaleDown, child: Text(cs('sumNow'), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11))),
                                const SizedBox(height: 2),
                                FittedBox(fit: BoxFit.scaleDown, child: Text(cs('nStars', args: {'n': balance}), style: GoogleFonts.notoSansKr(color: const Color(0xFFFFD700), fontWeight: FontWeight.w900, fontSize: 15))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    label(cs('lblReceivers')),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (codes.length > 1)
                          choiceChip(cs('chipAll'), selectedCodes.length == codes.length, () {
                            setDialogState(() {
                              if (selectedCodes.length == codes.length) {
                                selectedCodes.clear();
                              } else {
                                selectedCodes
                                  ..clear()
                                  ..addAll(codes);
                              }
                            });
                          }),
                        ...codes.map((code) => choiceChip(names[code] ?? cs('codeLabel', args: {'c': code}), selectedCodes.contains(code), () {
                          setDialogState(() {
                            if (selectedCodes.contains(code)) {
                              selectedCodes.remove(code);
                            } else {
                              selectedCodes.add(code);
                            }
                          });
                        })),
                      ],
                    ),

                    // 🆕 [응원 가족 2026-09-30] 보호자로 보낼 때 "보내는 사람" 고르기 (아이 카드에 이름표로 보임)
                    if (selectedCodes.any((c) => !_supporterCodes.contains(c))) ...[
                      label(cs('senderLabel')),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: SupporterService.guardianRelations
                            .map((r) => choiceChip(
                          '${SupporterService.relationEmoji[r] ?? ''} ${cs('rel_$r')}',
                          guardianRelation == r,
                              () => setDialogState(() => guardianRelation = r),
                        ))
                            .toList(),
                      ),
                    ],

                    label(cs('lblMode')),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        choiceChip(cs('modeNormal'), !isSpecial, () => setDialogState(() => isSpecial = false)),
                        choiceChip(cs('modeSpecial'), isSpecial, () => setDialogState(() => isSpecial = true)),
                      ],
                    ),
                    if (isSpecial) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _gold.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _gold.withOpacity(0.35)),
                        ),
                        child: Text(cs('specialInfo'), style: GoogleFonts.notoSansKr(color: _cream, fontSize: 12.5, height: 1.5)),
                      ),
                    ],

                    label(cs('lblCount')),
                    TextField(
                      controller: countController,
                      enabled: !sending,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setDialogState(() {}),
                      style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      decoration: inputDecoration(suffix: cs('unitStar')),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [10, 50, 100, 500, 1000]
                          .where((n) => n <= maxPerChild)
                          .map((n) => choiceChip('$n', countController.text.trim() == '$n', () => setDialogState(() => countController.text = '$n')))
                          .toList(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      childCount == 0
                          ? cs('countHintNone')
                          : cs('countHint', args: {'max': maxPerChild, 'c': childCount, 'p': perChild, 't': perChild * childCount}),
                      style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 11, height: 1.4),
                    ),

                    label(cs('lblMessage')),
                    ...List.generate(phrases.length, (i) {
                      final bool picked = messageController.text == phrases[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: sending
                              ? null
                              : () {
                            // 🆕 [2026-09-30] 고른 문구를 아래 칸에 넣고, 바로 고쳐 쓸 수 있게 커서를 끝에 둠
                            setDialogState(() {
                              messageController.text = phrases[i];
                              messageController.selection = TextSelection.collapsed(offset: phrases[i].length);
                            });
                            messageFocus.requestFocus();
                            // 🆕 자판이 올라온 뒤, 고쳐 쓰는 칸이 화면 가운데쯤 오도록 자동으로 내려감
                            Future.delayed(const Duration(milliseconds: 350), () {
                              final BuildContext? fieldCtx = messageFieldKey.currentContext;
                              if (fieldCtx != null) {
                                Scrollable.ensureVisible(fieldCtx, duration: const Duration(milliseconds: 300), curve: Curves.easeOut, alignment: 0.3);
                              }
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: picked ? _gold.withOpacity(0.16) : _pageBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: picked ? _gold : Colors.white12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${i + 1}', style: GoogleFonts.notoSansKr(color: _gold, fontWeight: FontWeight.bold, fontSize: 12.5)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    phrases[i],
                                    style: GoogleFonts.notoSansKr(color: picked ? _cream : Colors.white70, fontSize: 12, height: 1.45),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                    // 🆕 [2026-09-30] 고른 문구를 고쳐 쓰는 칸 (눈에 잘 띄게 안내 + 3줄)
                    Row(
                      children: [
                        const Icon(Icons.edit_rounded, color: _gold, size: 15),
                        const SizedBox(width: 5),
                        Expanded(child: Text(cs('lblEditMsg'), style: GoogleFonts.notoSansKr(color: _gold, fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      key: messageFieldKey, // 🆕 자동 이동 목표
                      controller: messageController,
                      focusNode: messageFocus,
                      enabled: !sending,
                      minLines: 3,
                      maxLines: 5,
                      onChanged: (_) => setDialogState(() {}),
                      style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13.5, height: 1.5),
                      decoration: inputDecoration(),
                    ),

                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(errorText!, style: GoogleFonts.notoSansKr(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: sending ? null : () => Navigator.pop(dialogContext),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E293B),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(cs('btnCancel'), style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: sending ? null : send,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _gold,
                              disabledBackgroundColor: const Color(0xFF1F2937),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              sending ? cs('btnSending') : cs('btnSend'),
                              style: GoogleFonts.notoSansKr(color: _pageBg, fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    // 🆕 [빨간 화면 수정 2026-09-30] 창이 닫히는 움직임이 끝난 뒤에 정리 (바로 정리하면 오류)
    Future.delayed(const Duration(milliseconds: 500), () {
      countController.dispose();
      messageController.dispose();
      messageFocus.dispose();
    });
  }

  // ---------------- 별 모으는 방법 ----------------
  Widget _buildRulesCard() {
    final List<List<String>> rules = [
      [cs('rule5min'), cs('rule1Star')],
      [cs('ruleRecord'), '+5'],
      [cs('rule60'), '+10'],
      [cs('ruleStreak'), '+10'],
      [cs('ruleWeek'), '+10'],
      [cs('ruleMonth'), '+100'],
      [cs('ruleCheck'), '+1~5'], // 🆕 [가족 활동 체크]
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          ...rules.map((r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Expanded(child: Text(r[0], style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12.5))),
                Text(r[1], style: GoogleFonts.notoSansKr(color: _gold, fontWeight: FontWeight.bold, fontSize: 12.5)),
              ],
            ),
          )),
          const Divider(color: Colors.white12, height: 20),
          Text(
            cs('ruleNote'),
            style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}


// ============================================================================
// 🆕 [2026-10-01] 고급 황금장 별 — 원장님이 주신 그림의 "앞쪽 별"을 그대로 그린 것.
// 다섯 꼭짓점마다 밝은 면·어두운 면 두 조각으로 나눠 입체감(보석처럼 깎인 면)을 줌.
// 🆕 [2026-10-01 수정] 뒤쪽 배경 번짐과 흰 줄 없이 별만 깔끔하게. 그림 파일이 아니라 코드로 그려서 어떤 크기에도 선명함.
// ============================================================================
class FacetedGoldStar extends StatelessWidget {
  final double size;
  const FacetedGoldStar({super.key, this.size = 54});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FacetedGoldStarPainter()),
    );
  }
}

class _FacetedGoldStarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2 + size.height * 0.03);
    final double outer = size.width * 0.5;
    final double inner = outer * 0.43;

    Offset pt(double deg, double r) {
      final double rad = deg * 3.141592653589793 / 180;
      return Offset(c.dx + r * cos(rad), c.dy + r * sin(rad));
    }

    final Rect box = Rect.fromCircle(center: c, radius: outer);
    final Paint light = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF4C2), Color(0xFFFFD34D), Color(0xFFF2B21C)],
      ).createShader(box);
    final Paint dark = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF0A81A), Color(0xFFD4860B), Color(0xFFA8650A)],
      ).createShader(box);

    for (int i = 0; i < 5; i++) {
      final double a = -90 + i * 72.0;
      final Offset tip = pt(a, outer);
      final Offset left = pt(a - 36, inner);
      final Offset right = pt(a + 36, inner);
      // 왼쪽 면(밝게) / 오른쪽 면(어둡게) — 깎인 보석처럼
      canvas.drawPath(Path()..moveTo(c.dx, c.dy)..lineTo(left.dx, left.dy)..lineTo(tip.dx, tip.dy)..close(), light);
      canvas.drawPath(Path()..moveTo(c.dx, c.dy)..lineTo(tip.dx, tip.dy)..lineTo(right.dx, right.dy)..close(), dark);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
