import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:gsu_studyup/square/member_achievement_screen.dart';
import 'dart:async';
import 'package:gsu_studyup/timer/timer_screen.dart';
import 'square/friend_study_room_screen.dart';
import 'package:gsu_studyup/square/live_active_users_screen.dart';
import 'package:gsu_studyup/square/educational_consultation/educational_consultation_screen.dart';
import 'package:gsu_studyup/square/my_page_screen.dart';
import 'planner/main_self_learning_planner_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gsu_studyup/square/academic_timeline/academic_timeline_screen.dart';
import 'planner/widgets/study_timelines.dart'; // 🆕 [D-day 팝업 연동] 시험 D-day 응원/실전팁 팝업 데이터 참조
import 'package:gsu_studyup/square/my_growth_path_screen.dart'; // 나의 성장로 화면 연동
// 또는 실제 경로에 맞게 // 앞서 생성한 학사 타임라인 화면

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> with WidgetsBindingObserver {
  String _examBreakTimeSelection = '20분';

  String selectedSubject = '';
  String selectedMode = 'Weekday (주중 학습)';
  int selectedDuration = 30;

  String selectedSound = '';
  String selectedSoundFile = '';

  late AudioPlayer _audioPlayer;
  Timer? _previewTimer;
  String previewingSound = '';

  bool _isVipMember = false;
  String _targetUniversity = "Seoul National University (서울대학교)";

  // 🆕 목표 시험 종류 마스터 패킷 리스트
  List<String> _examTypes = ['중간고사', '기말고사', '학기중 학습', '공무원 시험', 'TOEIC', '2027 대학수능'];

  List<Map<String, String>> subjects = [
    {'en': 'Native Language', 'ko': '국어'},
    {'en': 'Math', 'ko': '수학'},
    {'en': 'Exercise', 'ko': '운동'},
    {'en': 'Reading', 'ko': '독서'},
  ];

  final List<Map<String, String>> sounds = [
    {'en': 'Crickets', 'ko': '귀뚜라미 소리', 'file': 'crickets.mp3'},
    {'en': 'Spring Morning', 'ko': '봄 아침소리', 'file': 'spring_morning.mp3'},
    {'en': 'Forest Birds', 'ko': '숲속의 새소리', 'file': 'forest_birds.mp3'},
    {'en': 'Cool Rain', 'ko': '시원한 빗소리', 'file': 'cool_rain.mp3'},
    {'en': 'Clear Stream', 'ko': '맑은 시냇물', 'file': 'clear_stream.mp3'},
    {'en': 'Blue Waves', 'ko': '푸른 파도소리', 'file': 'blue_waves.mp3'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 🆕 [버그 수정] 앱 재개(resume) 감지용
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);

    // 🆕 [D-day 팝업 연동] 첫 화면 진입 시(아침 6~10시 사이) 시험 D-day 응원 팝업 체크
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowExamDayPopup();
    });
  }

  // 🆕 [버그 수정] 기존엔 initState 때 딱 1번만 체크해서, 앱을 며칠째 안 끄고 계속 켜두면
  // (화면만 껐다 켜거나 다른 앱 갔다 돌아오는 경우) 다음날 아침 6~10시가 되어도 재확인이 안 됐음.
  // 앱이 포그라운드로 돌아올 때(resumed)마다 다시 체크하도록 보강.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkAndShowExamDayPopup();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 🆕 옵저버 해제
    _previewTimer?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ============================================================================
  // 🆕 [D-day 팝업 연동] 시험 시작일(gke_exam_start_date) 기준으로 D-1/D-day/D+1~D+4
  // 팝업을 판단하고, 아침 6~9시 & "오늘 하루 안 보기" 미선택 상태일 때만 팝업 체인을 띄움
  // ============================================================================
  Future<void> _checkAndShowExamDayPopup() async {
    final DateTime now = DateTime.now();

    final prefs = await SharedPreferences.getInstance();

    final String todayKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final String? hiddenForDate = prefs.getString('gke_exam_popup_hidden_date');
    if (hiddenForDate == todayKey) return; // "오늘 하루 안 보기"를 이미 눌렀으면 스킵

    final bool timelineEnabled = prefs.getBool('gke_exam_timeline_enabled') ?? false;
    final String? startStr = prefs.getString('gke_exam_start_date');
    if (!timelineEnabled || startStr == null) return; // 시험 일정이 기록되어 있지 않으면 팝업 없음

    final DateTime examStartDate = DateTime.parse(startStr);
    final DateTime examStartZero = DateTime(examStartDate.year, examStartDate.month, examStartDate.day);
    final DateTime todayZero = DateTime(now.year, now.month, now.day);
    final int differenceInDays = todayZero.difference(examStartZero).inDays; // -1: D-1, 0: D-day, 1~4: D+1~D+4

    final String? primaryMessage = StudyTimelinesMidTermAllDays.getPrimaryPopupMessage(differenceInDays);
    if (primaryMessage == null) return; // 팝업 대상 구간(D-1~D+4)이 아니면 종료

    final List<String> popupMessages = [primaryMessage];
    if (StudyTimelinesMidTermAllDays.hasSecondaryPopup(differenceInDays)) {
      popupMessages.add(StudyTimelinesMidTermAllDays.examPopupSecondaryTips); // D-1은 2번째 팝업 없음
    }

    if (!mounted) return;
    _showExamDayPopupChain(popupMessages, todayKey);
  }

  // 🆕 [D-day 팝업 연동] 팝업 1개(D-1) 또는 2개(D-day, D+1~D+4)를 순서대로 스윽 전환하며 보여주는 다이얼로그.
  // [확인] 클릭 시 다음 팝업으로 전환(마지막이면 닫기), [오늘 하루 안 보기] 클릭 시 즉시 닫고 오늘 날짜를 저장.
  void _showExamDayPopupChain(List<String> popupMessages, String todayKey) {
    int currentIndex = 0;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (dialogContext, anim1, anim2) {
        return StatefulBuilder(
          builder: (statefulContext, setPopupState) {
            Future<void> handleClose({required bool hideToday}) async {
              if (hideToday) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('gke_exam_popup_hidden_date', todayKey);
                Navigator.of(dialogContext).pop();
                return;
              }
              if (currentIndex < popupMessages.length - 1) {
                setPopupState(() { currentIndex++; }); // 다음 팝업으로 스윽 전환
              } else {
                Navigator.of(dialogContext).pop();
              }
            }

            return Dialog(
              backgroundColor: const Color(0xFF0D1527),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE5C158), width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      transitionBuilder: (child, anim) {
                        final slideAnim = Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero).animate(anim);
                        return SlideTransition(
                          position: slideAnim,
                          child: FadeTransition(opacity: anim, child: child),
                        );
                      },
                      child: SingleChildScrollView(
                        key: ValueKey(currentIndex),
                        child: Text(
                          popupMessages[currentIndex],
                          style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14, height: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => handleClose(hideToday: true),
                            child: Text(
                              '오늘 하루 안 보기',
                              style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => handleClose(hideToday: false),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5C158)),
                            child: Text(
                              '확인',
                              style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
            child: child,
          ),
        );
      },
    );
  }

  void _addNewSubject(String nameKo, String nameEn) {
    setState(() {
      final finalEn = nameEn.isEmpty ? '' : '$nameEn ';
      subjects.add({'en': finalEn, 'ko': nameKo});
    });
  }

  void _deleteSubject(Map<String, String> targetSub, String displayName) {
    setState(() {
      subjects.remove(targetSub);
      if (selectedSubject == displayName) {
        selectedSubject = '';
      }
    });
  }

  void _handleSoundPreview(String displayName, String fileName) async {
    try {
      _previewTimer?.cancel();
      await _audioPlayer.stop();

      if (previewingSound == displayName) {
        setState(() => previewingSound = '');
      } else {
        setState(() => previewingSound = displayName);
        await _audioPlayer.play(AssetSource('sounds/$fileName'));

        _previewTimer = Timer(const Duration(seconds: 10), () async {
          await _audioPlayer.stop();
          if (mounted) {
            setState(() => previewingSound = '');
          }
        });
      }
    } catch (e) {
      debugPrint("오디오 미리듣기 재생 실패: $e");
    }
  }

  void _handleSoundSelect(String displayName, String fileName) async {
    _previewTimer?.cancel();
    await _audioPlayer.stop();
    setState(() {
      previewingSound = '';
      if (selectedSound == displayName) {
        selectedSound = '';
        selectedSoundFile = '';
      } else {
        selectedSound = displayName;
        selectedSoundFile = fileName;
      }
    });
  }
  /// ============================================================================
  /// [회의 스펙 반영] 목표 시험 종류 선택 및 캘린더 연동 팝업 팩토리 (최종 수정판)
  /// ============================================================================
  void _showExamSelectionDialog() {
    String temporarySelectedExam = '';
    String prepPeriodSelection = '4주 전'; // 기본값 4주전
    String generateSpecialTimeline = '예';  // 기본값 예
    final TextEditingController customExamController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            return Dialog(
              backgroundColor: const Color(0xFF0D1527),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "CHOOSE YOUR TARGET EXAM\n[시험 종류 선택]",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 18),

                    // 1. 시험 종류 선택 칩 리스트
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: _examTypes.map((exam) {
                        final bool isCurrentSelected = temporarySelectedExam == exam && customExamController.text.isEmpty;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setPopupState(() {
                                  temporarySelectedExam = exam;
                                  customExamController.clear();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isCurrentSelected ? const Color(0xFFE5C158) : Colors.black26,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isCurrentSelected ? const Color(0xFFE5C158) : Colors.white24),
                                ),
                                child: Text(
                                  exam,
                                  style: GoogleFonts.notoSansKr(color: isCurrentSelected ? Colors.black : const Color(0xB3FFFFFF), fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                            Positioned(
                              top: -5, right: -5,
                              child: GestureDetector(
                                onTap: () {
                                  setPopupState(() {
                                    _examTypes.remove(exam);
                                    if (temporarySelectedExam == exam) temporarySelectedExam = '';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                                  child: const Icon(Icons.close_rounded, size: 11, color: Colors.white38),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // 2. 직접 입력 보조 채널
                    Row(
                      children: [
                        const Icon(Icons.edit_note_rounded, color: Color(0xFFE5C158), size: 20),
                        const SizedBox(width: 6),
                        Text("Custom Input (직접 입력)", style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        SizedBox(
                          height: 28,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE5C158),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onPressed: () {
                              final text = customExamController.text.trim();
                              if (text.isEmpty) return;
                              setPopupState(() {
                                if (!_examTypes.contains(text)) _examTypes.add(text);
                                temporarySelectedExam = text;
                                customExamController.clear();
                              });
                            },
                            child: Text("생성", style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5C158).withOpacity(0.4))),
                      child: TextField(
                        controller: customExamController,
                        style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        onChanged: (val) {
                          if (val.isNotEmpty) setPopupState(() => temporarySelectedExam = '');
                        },
                        decoration: InputDecoration(
                          hintText: "e.g. 중간고사, 기말고사, 모의고사 직접 기입",
                          hintStyle: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 30),

                    // 3. 시험 준비 시작 선택 구간 (2주전, 3주전, 4주전)
                    Text("EXAM PREPARATION START / 시험 준비 시작", style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['2주 전', '3주 전', '4주 전'].map((period) {
                        bool isSel = prepPeriodSelection == period;
                        return InkWell(
                          onTap: () { setPopupState(() { prepPeriodSelection = period; }); },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: isSel ? const Color(0xFFE5C158) : Colors.black12, borderRadius: BorderRadius.circular(6), border: Border.all(color: isSel ? const Color(0xFFE5C158) : Colors.white12)),
                            child: Text(period, style: GoogleFonts.notoSansKr(color: isSel ? Colors.black : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // 4. 시험기간 전용 시간표 생성 여부 토글 버튼 (예/아니오)
                    Text("CREATE EXAM TIMELINE? / 시험기간 전용 시간표 생성하시겠습니까?", style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: ['예', '아니오'].map((choice) {
                        bool isSel = generateSpecialTimeline == choice;
                        return Expanded(
                          child: InkWell(
                            onTap: () { setPopupState(() { generateSpecialTimeline = choice; }); },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: isSel ? const Color(0xFFE5C158) : Colors.black12, borderRadius: BorderRadius.circular(6), border: Border.all(color: isSel ? const Color(0xFFE5C158) : Colors.white12)),
                              child: Text(choice, style: GoogleFonts.notoSansKr(color: isSel ? Colors.black : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // 5. 👑 [수정 완료] 휴식 시간 선택 UI (10분 / 15분 / 20분 + 영문 표기 결합)
                    Text('REST TIME / 휴식 시간 선택', style: GoogleFonts.notoSerif(fontSize: 11, color: const Color(0xFFE5C158), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setPopupState(() => _examBreakTimeSelection = '10분'),
                            style: OutlinedButton.styleFrom(side: BorderSide(color: _examBreakTimeSelection == '10분' ? const Color(0xFFE5C158) : Colors.white38)),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('10분', style: TextStyle(color: _examBreakTimeSelection == '10분' ? const Color(0xFFE5C158) : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                Text('10 MINS', style: GoogleFonts.gowunBatang(color: _examBreakTimeSelection == '10분' ? const Color(0xFFE5C158) : Colors.white60, fontSize: 9)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setPopupState(() => _examBreakTimeSelection = '15분'),
                            style: OutlinedButton.styleFrom(side: BorderSide(color: _examBreakTimeSelection == '15분' ? const Color(0xFFE5C158) : Colors.white38)),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('15분', style: TextStyle(color: _examBreakTimeSelection == '15분' ? const Color(0xFFE5C158) : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                Text('15 MINS', style: GoogleFonts.gowunBatang(color: _examBreakTimeSelection == '15분' ? const Color(0xFFE5C158) : Colors.white60, fontSize: 9)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setPopupState(() => _examBreakTimeSelection = '20분'),
                            style: OutlinedButton.styleFrom(side: BorderSide(color: _examBreakTimeSelection == '20분' ? const Color(0xFFE5C158) : Colors.white38)),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('20분', style: TextStyle(color: _examBreakTimeSelection == '20분' ? const Color(0xFFE5C158) : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                Text('20 MINS', style: GoogleFonts.gowunBatang(color: _examBreakTimeSelection == '20분' ? const Color(0xFFE5C158) : Colors.white60, fontSize: 9)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 6. 다음 버튼 (시험 기간 설정)
                    ElevatedButton(
                      onPressed: () async {
                        String finalExamName = customExamController.text.trim();
                        if (finalExamName.isEmpty) finalExamName = temporarySelectedExam;

                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('gke_exam_break_time', _examBreakTimeSelection);

                        Navigator.of(context).pop();
                        _openDatePickerRangeAndNavigate(
                            examName: finalExamName,
                            prepPeriod: prepPeriodSelection,
                            isTimelineGeneration: generateSpecialTimeline == '예'
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5C158), minimumSize: const Size(double.infinity, 48)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('NEXT: SELECT DATES', style: GoogleFonts.gowunBatang(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('시험 기간 설정', style: GoogleFonts.notoSansKr(color: Colors.black87, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// ============================================================================
  /// 🎯 [회의 스펙 반영] 시험 시작일 달력 선택 ➡️ 시험 종료일 달력 선택 연속 연동 바인딩
  /// ============================================================================
  void _openDatePickerRangeAndNavigate({
    required String examName,
    required String prepPeriod,
    required bool isTimelineGeneration
  }) async {
    final DateTime now = DateTime.now();
    final DateTime todayZeroClock = DateTime(now.year, now.month, now.day);

    // 1. 시험 시작일 '달력'에서 선택
    if (!mounted) return;
    DateTime? startDate = await showDatePicker(
      context: context,
      initialDate: todayZeroClock,
      firstDate: todayZeroClock,
      lastDate: todayZeroClock.add(const Duration(days: 365 * 10)), // 10년 치 보장
      helpText: "SELECT EXAM START DATE [시험 시작일 선택]",
      builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFFE5C158), onPrimary: Colors.black, surface: Color(0xFF0D1527), onSurface: Colors.white)), child: child!),
    );

    if (startDate == null) return;

    // 2. 시험 종료일 '달력'에서 선택 (시작일 이후 날짜만 찍히도록 제어)
    if (!mounted) return;
    DateTime? endDate = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: startDate,
      lastDate: startDate.add(const Duration(days: 90)), // 시험 기간 한도 가드
      helpText: "SELECT EXAM END DATE [시험 종료일 선택]",
      builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFFE5C158), onPrimary: Colors.black, surface: Color(0xFF0D1527), onSurface: Colors.white)), child: child!),
    );

    if (endDate == null) return;

    // 3. 🚀 타이머 및 학습계획 타임라인에 누적 저장 처리할 수 있도록 스펙 정보 패키징 전송
    if (!mounted) return;
    final missionResult = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TimerScreen(
          selectedSubject: selectedSubject,
          selectedDurationMinutes: selectedDuration,
          dynamicTestTitle: examName,
          targetExamDate: startDate,      // 시험 시작일 매핑
          targetExamEndDate: endDate,    // 시험 종료일 완벽 연동
          prepPeriodStr: prepPeriod,     // 2주전, 3주전, 4주전 선택 플래그
          needTimelineGen: isTimelineGeneration, // 생성 여부 플래그
          selectedSoundFile: selectedSoundFile,
          targetUniversity: _targetUniversity,
          isVipMember: _isVipMember,
        ),
      ),
    );
  }

  void _showAddSubjectDialog() {
    final TextEditingController subjectController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF0D1527),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "CREATE NEW SUBJECT\n[새로운 과목 생성]",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24)),
                  child: TextField(
                    controller: subjectController,
                    style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "e.g. 요가, 축구, 영어, Yoga, Hobby",
                      hintStyle: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("CANCEL [취소]", style: GoogleFonts.notoSansKr(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton(
                      onPressed: () {
                        final text = subjectController.text.trim();
                        if (text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('과목명을 입력해 주세요!', style: GoogleFonts.notoSansKr())));
                          return;
                        }
                        _addNewSubject(text, '');
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5C158),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: Text("CREATE [생성]", style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color brandGolden = Color(0xFFE5C158);

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 110,
        automaticallyImplyLeading: false,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/gsu_logo.png', width: 180, height: 24, fit: BoxFit.fill),
            const SizedBox(height: 0.5),
            Text('GKE STUDYUP', style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 1.5)),
          ],
        ),
        centerTitle: true,
      ),
      body: SizedBox(
        width: double.infinity, height: double.infinity,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF0D1527), borderRadius: BorderRadius.circular(16), border: Border.all(color: brandGolden.withOpacity(0.3), width: 1.2)),
                child: Column(
                  children: [
                    GridView.count(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2, childAspectRatio: 2.1,
                      mainAxisSpacing: 12, crossAxisSpacing: 12,
                      children: [
                        _buildMenuButton(
                          icon: Icons.calendar_month_rounded, label: "자기주도 플래너", subLabel: "Self Learning Planner",
                          // [확인된 위치] 564번 줄부터 572번 줄까지의 기존 onTap 영역
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MainSelfLearningPlannerScreen(),
                              ),
                            );
                          },
                        ),

                        _buildMenuButton(
                          icon: Icons.calendar_month_rounded,
                          label: "학사 타임라인",
                          subLabel: "Academic Timeline",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AcademicTimelineScreen(),
                              ),
                            );
                          },
                        ),

                        _buildMenuButton(
                          icon: Icons.assignment_ind_rounded, label: "개인이름 성취도", subLabel: "Personal Achievement",
                          onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const MemberAchievementScreen())); },
                        ),

                        _buildMenuButton(
                          icon: Icons.forum_rounded, label: "친구 학습방", subLabel: "Friends Study Room",
                          onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendStudyRoomScreen())); },
                        ),
                        _buildMenuButton(
                          icon: Icons.people_alt_rounded, label: "동시 접속자", subLabel: "Live Active Users",
                          onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const LiveActiveUsersScreen())); },
                        ),
                        _buildMenuButton(
                          icon: Icons.fort_rounded, label: "나의 성장로", subLabel: "My Growth Path",
                          onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const MyGrowthPathScreen())); },
                        ),
                        _buildMenuButton(
                          icon: Icons.support_agent_rounded, label: "교육상담", subLabel: "Education Counseling",
                          onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const EducationalConsultationScreen())); },
                        ),
                        _buildMenuButton(
                          icon: Icons.account_circle_rounded, label: "👑 마이페이지", subLabel: "마이페이지",
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => MyPageScreen(
                              isVipMember: _isVipMember,
                              onSave: (isVip, university) {
                                setState(() { _isVipMember = isVip; _targetUniversity = university; });
                              },
                            )));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              _buildSectionTitle('Subject Selection', '과목 선택'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: subjects.map((sub) {
                  final bool isSelected = selectedSubject == '${sub['en']} (${sub['ko']})';
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4, right: 6),
                        child: _buildSelectableChip(
                          engText: sub['en']!, korText: sub['ko']!, isSelected: isSelected,
                          onTap: () => setState(() => selectedSubject = '${sub['en']} (${sub['ko']})'),
                        ),
                      ),
                      Positioned(
                        top: 0, right: 2,
                        child: GestureDetector(
                          onTap: () => _deleteSubject(sub, '${sub['en']} (${sub['ko']})'),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1)),
                            child: const Icon(Icons.close_rounded, size: 10, color: Colors.white60),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              OutlinedButton.icon(
                onPressed: () => _showAddSubjectDialog(),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: brandGolden, width: 1.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
                icon: const Icon(Icons.add_circle_outline_rounded, color: brandGolden, size: 16),
                label: Text("새로운 과목 생성 Create New Subject", style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),

              _buildSectionTitle('Learning Mode Selection', '학습 모드 선택'),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildExpandedToggleButton(
                    engTitle: 'Weekday', korTitle: '주중 학습', isActive: selectedMode == 'Weekday (주중 학습)',
                    onTap: () => setState(() => selectedMode = 'Weekday (주중 학습)'),
                  ),
                  const SizedBox(width: 10),
                  _buildExpandedToggleButton(
                    engTitle: 'Weekend/Vacation', korTitle: '주말·방학 학습', isActive: selectedMode == 'Weekend/Vacation (주말·방학 학습)',
                    onTap: () => setState(() => selectedMode = 'Weekend/Vacation (주말·방학 학습)'),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              _buildSectionTitle('Focus Mode Selection', '집중 모드 선택'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [30, 60, 90].map((mins) {
                  return _buildSelectableChip(
                    engText: '$mins Mins', korText: '분', isSelected: selectedDuration == mins,
                    onTap: () => setState(() => selectedDuration = mins), horizontalPadding: 12.0,
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),

              _buildSectionTitle('White Noise Selection', '백색소음 선택'),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                itemCount: sounds.length,
                itemBuilder: (context, index) {
                  final snd = sounds[index];
                  final displayName = '${snd['en']} (${snd['ko']})';
                  final bool isSelected = selectedSound == displayName;
                  final bool isPreviewing = previewingSound == displayName;
                  final Color brandGoldenColor = const Color(0xFFE5C158);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: isSelected ? brandGoldenColor : const Color(0xFF0D1527), borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? brandGoldenColor : Colors.white12, width: 1.5)),
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _handleSoundPreview(displayName, snd['file']!),
                          icon: Icon(isPreviewing ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded, size: 16, color: isSelected ? const Color(0xFF030712) : brandGoldenColor),
                          label: Text(isPreviewing ? "STOP\n[정지]" : "LISTEN 10s\n[미리듣기]", style: GoogleFonts.notoSansKr(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF030712) : const Color(0xFFEFEFEF))),
                          style: ElevatedButton.styleFrom(backgroundColor: isSelected ? Colors.black.withOpacity(0.15) : Colors.black45, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), minimumSize: Size.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(text: "${snd['en']} ", style: GoogleFonts.gowunBatang(color: isSelected ? const Color(0xFF030312) : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                TextSpan(text: "(${snd['ko']})", style: GoogleFonts.notoSansKr(color: isSelected ? const Color(0xFF030712) : brandGolden, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _handleSoundSelect(displayName, snd['file']!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? const Color(0xFF030712) : Colors.black45, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: isSelected ? Colors.transparent : const Color(0x80E5C158))),
                          ),
                          child: Text(isSelected ? "UNSELECT\n[해제]" : "SELECT\n[선택]", textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(fontSize: 11, fontWeight: FontWeight.bold, color: brandGoldenColor)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),

              InkWell(
                onTap: selectedSubject.isEmpty
                    ? () { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('먼저 과목을 선택해 주세요!', style: GoogleFonts.notoSansKr()))); }
                    : () => _showExamSelectionDialog(),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: double.infinity, height: 85,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), image: const DecorationImage(image: AssetImage('assets/images/light_blue_btn.png'), fit: BoxFit.fill)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Select Exam Type & Date', style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, shadows: [const Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 4)])),
                      const SizedBox(height: 3),
                      Text('(목표 시험 및 일정 선택 후 집중 시작)', style: GoogleFonts.notoSansKr(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 13, shadows: [const Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 4)])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String engTitle, String korTitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(engTitle, style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, height: 1.2)),
        const SizedBox(height: 4),
        Text("($korTitle)", style: GoogleFonts.notoSansKr(color: const Color(0xFFE5C158), fontWeight: FontWeight.bold, fontSize: 16.0, height: 1.3)),
      ],
    );
  }

  Widget _buildSelectableChip({
    required String engText, required String korText, required bool isSelected, required VoidCallback onTap, double horizontalPadding = 16.0,
  }) {
    const Color brandGolden = Color(0xFFE5C158);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
        decoration: BoxDecoration(color: isSelected ? brandGolden : const Color(0xFF0D1527), borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? brandGolden : Colors.white12, width: 1.5)),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(text: "$engText ", style: GoogleFonts.gowunBatang(color: isSelected ? const Color(0xFF030712) : Colors.white70, fontWeight: FontWeight.bold, fontSize: 15)),
              TextSpan(text: "($korText)", style: GoogleFonts.notoSansKr(color: isSelected ? const Color(0xFF030712) : brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedToggleButton({
    required String engTitle, required String korTitle, required bool isActive, required VoidCallback onTap
  }) {
    const Color brandGolden = Color(0xFFE5C158);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10), alignment: Alignment.center,
          decoration: BoxDecoration(color: isActive ? brandGolden : const Color(0xFF0D1527), borderRadius: BorderRadius.circular(12), border: Border.all(color: isActive ? brandGolden : Colors.white12)),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(text: "$engTitle\n", style: GoogleFonts.gowunBatang(color: isActive ? const Color(0xFF030712) : Colors.white60, fontWeight: FontWeight.bold, fontSize: 13, height: 1.3)),
                TextSpan(text: "($korTitle)", style: GoogleFonts.notoSansKr(color: isActive ? const Color(0xFF030712) : brandGolden, fontWeight: FontWeight.bold, fontSize: 12, height: 1.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon, required String label, required String subLabel, bool isBadge = false, VoidCallback? onTap,
  }) {
    const Color brandGolden = Color(0xFFE5C158);
    return InkWell(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${label.replaceAll('\n', ' ')} 페이지 준비 중입니다. (Page Under Construction)', style: GoogleFonts.notoSansKr())));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10), border: Border.all(color: brandGolden.withOpacity(0.2), width: 1.0)),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(icon, color: brandGolden, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
                        child: Text(label, style: GoogleFonts.notoSansKr(color: const Color(0xFFFFF6D6), fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
                    child: Text(subLabel, style: GoogleFonts.gowunBatang(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13.5)),
                  ),
                ),
              ],
            ),
            if (isBadge)
              Positioned(
                right: 0, top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)),
                  child: const Text("LIVE", style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
