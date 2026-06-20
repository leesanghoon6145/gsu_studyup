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

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  String userName = '이규현';
  int currentStars = 75;
  final int maxTargetStars = 90;

  String selectedSubject = '';
  String selectedMode = 'Weekday (주중 학습)';
  int selectedDuration = 30;

  String selectedSound = '';
  String selectedSoundFile = '';

  late AudioPlayer _audioPlayer;
  Timer? _previewTimer;
  String previewingSound = '';

  // 🎯 마이페이지와 실시간 연동될 핵심 데이터 필드
  bool _isVipMember = false;
  String _targetUniversity = "Seoul National University (서울대학교)";

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
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
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

  void _showExamSelectionDialog() {
    String temporarySelectedExam = '';
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
                      "CHOOSE YOUR TARGET EXAM\n[목표 시험 종류 선택]",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: ['학기중 학습', '기말고사', '공무원 시험', 'TOEIC', '2027 대학수능', '운동'].map((exam) {
                        final bool isCurrentSelected = temporarySelectedExam == exam && customExamController.text.isEmpty;
                        return GestureDetector(
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
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.edit_note_rounded, color: Color(0xFFE5C158), size: 20),
                        const SizedBox(width: 6),
                        Text("Custom Input (직접 입력)", style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5C158).withOpacity(0.4))),
                      child: TextField(
                        controller: customExamController,
                        style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        onChanged: (val) {
                          if (val.isNotEmpty) {
                            setPopupState(() => temporarySelectedExam = '');
                          }
                        },
                        decoration: InputDecoration(
                          hintText: "e.g. 사법고시, 행정고시, TOEIC",
                          hintStyle: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        String finalExamName = customExamController.text.trim();
                        if (finalExamName.isEmpty) finalExamName = temporarySelectedExam;
                        if (finalExamName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('試験 종류를 선택하거나 직접 입력해 주세요!', style: GoogleFonts.notoSansKr())));
                          return;
                        }
                        Navigator.of(context).pop();
                        _openDatePickerAndNavigate(finalExamName);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5C158), minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: Text("NEXT: SELECT DATE (날짜 선택)", style: GoogleFonts.gowunBatang(color: Colors.black, fontWeight: FontWeight.bold)),
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

  void _openDatePickerAndNavigate(String examName) async {
    final DateTime now = DateTime.now();
    final DateTime todayZeroClock = DateTime(now.year, now.month, now.day);

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: todayZeroClock,
      firstDate: todayZeroClock,
      lastDate: todayZeroClock.add(const Duration(days: 365 * 3)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFFE5C158), onPrimary: Colors.black, surface: Color(0xFF0D1527), onSurface: Colors.white),
            dialogBackgroundColor: const Color(0xFF030712),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (!mounted) return;

      final missionResult = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TimerScreen(
            selectedSubject: selectedSubject,
            selectedDurationMinutes: selectedDuration,
            dynamicTestTitle: examName,
            targetExamDate: pickedDate,
            selectedSoundFile: selectedSoundFile,
            targetUniversity: _targetUniversity,
            isVipMember: _isVipMember,
          ),
        ),
      );

      if (missionResult != null && missionResult is int) {
        setState(() {
          currentStars = missionResult;
          if (currentStars > maxTargetStars) currentStars = maxTargetStars;
        });
      }
    }
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
            Image.asset(
              'assets/images/gsu_logo.png',
              width: 180,
              height: 24,
              fit: BoxFit.fill,
            ),
            const SizedBox(height: 0.5),
            Text(
              'GKE STUDYUP',
              style: GoogleFonts.gowunBatang(
                color: brandGolden,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1527),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: brandGolden.withOpacity(0.3), width: 1.2),
                ),
                child: Column(
                  children: [
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 2.1,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        _buildMenuButton(
                          icon: Icons.forum_rounded,
                          label: "친구 학습방",
                          subLabel: "Friends Study Room",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const FriendStudyRoomScreen()),
                            );
                          },
                        ),
                        _buildMenuButton(
                          icon: Icons.assignment_ind_rounded,
                          label: "개인이름 성취도",
                          subLabel: "Personal Achievement",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MemberAchievementScreen()),
                            );
                          },
                        ),
                        _buildMenuButton(
                          icon: Icons.people_alt_rounded,
                          label: "동시 접속자",
                          subLabel: "Live Active Users",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LiveActiveUsersScreen()),
                            );
                          },
                        ),
                        _buildMenuButton(icon: Icons.fort_rounded, label: "나의제국 게시판", subLabel: "Empire Forum"),
                        _buildMenuButton(
                          icon: Icons.support_agent_rounded,
                          label: "교육상담",
                          subLabel: "Education Counseling",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EducationalConsultationScreen(),
                              ),
                            );
                          },
                        ),
                        // 👑 [에러 완벽 소독 완료] 신형 마이페이지 전용 최적화 호출 라인! 괄호 일자 정렬!
                        _buildMenuButton(
                          icon: Icons.account_circle_rounded,
                          label: "👑 마이페이지",
                          subLabel: "마이페이지",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MyPageScreen(
                                  isVipMember: _isVipMember,
                                  onSave: (isVip, university) {
                                    setState(() {
                                      _isVipMember = isVip;
                                      _targetUniversity = university;
                                    });
                                  },
                                ),
                              ),
                            );
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
                          engText: sub['en']!,
                          korText: sub['ko']!,
                          isSelected: isSelected,
                          onTap: () => setState(() => selectedSubject = '${sub['en']} (${sub['ko']})'),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => _deleteSubject(sub, '${sub['en']} (${sub['ko']})'),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24, width: 1),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 10,
                              color: Colors.white60,
                            ),
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
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: brandGolden, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.add_circle_outline_rounded, color: brandGolden, size: 16),
                label: Text(
                  "새로운 과목 생성 Create New Subject",
                  style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 30),

              _buildSectionTitle('Learning Mode Selection', '학습 모드 선택'),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildExpandedToggleButton(
                    engTitle: 'Weekday',
                    korTitle: '주중 학습',
                    isActive: selectedMode == 'Weekday (주중 학습)',
                    onTap: () => setState(() => selectedMode = 'Weekday (주중 학습)'),
                  ),
                  const SizedBox(width: 10),
                  _buildExpandedToggleButton(
                    engTitle: 'Weekend/Vacation',
                    korTitle: '주말·방학 학습',
                    isActive: selectedMode == 'Weekend/Vacation (주말·방학 학습)',
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
                    engText: '$mins Mins',
                    korText: '분',
                    isSelected: selectedDuration == mins,
                    onTap: () => setState(() => selectedDuration = mins),
                    horizontalPadding: 12.0,
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),

              _buildSectionTitle('White Noise Selection', '백색소음 선택'),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                    decoration: BoxDecoration(
                      color: isSelected ? brandGoldenColor : const Color(0xFF0D1527),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? brandGoldenColor : Colors.white12, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _handleSoundPreview(displayName, snd['file']!),
                          icon: Icon(isPreviewing ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded, size: 16, color: isSelected ? const Color(0xFF030712) : brandGoldenColor),
                          label: Text(
                            isPreviewing ? "STOP\n[정지]" : "LISTEN 10s\n[미리듣기]",
                            style: GoogleFonts.notoSansKr(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF030712) : const Color(0xFFEFEFEF)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.black.withOpacity(0.15) : Colors.black45,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(text: "${snd['en']} ", style: GoogleFonts.gowunBatang(color: isSelected ? const Color(0xFF030712) : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                TextSpan(text: "(${snd['ko']})", style: GoogleFonts.notoSansKr(color: isSelected ? const Color(0xFF030712) : brandGolden, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _handleSoundSelect(displayName, snd['file']!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? const Color(0xFF030712) : Colors.black45,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: BorderSide(color: isSelected ? Colors.transparent : const Color(0x80E5C158)),
                            ),
                          ),
                          child: Text(
                            isSelected ? "UNSELECT\n[해제]" : "SELECT\n[선택]",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.gowunBatang(fontSize: 11, fontWeight: FontWeight.bold, color: brandGoldenColor),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),

              InkWell(
                onTap: selectedSubject.isEmpty
                    ? () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('먼저 과목을 선택해 주세요!', style: GoogleFonts.notoSansKr())));
                }
                    : () => _showExamSelectionDialog(),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: double.infinity,
                  height: 85,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/light_blue_btn.png'),
                      fit: BoxFit.fill,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.transparent, blurRadius: 0, spreadRadius: 0),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Select Exam Type & Date',
                        style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, shadows: [const Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 4)]),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '(목표 시험 및 일정 선택 후 집중 시작)',
                        style: GoogleFonts.notoSansKr(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 13, shadows: [const Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 4)]),
                      ),
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
        Text(
          engTitle,
          style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, height: 1.2),
        ),
        const SizedBox(height: 4),
        Text(
          "($korTitle)",
          style: GoogleFonts.notoSansKr(
            color: const Color(0xFFE5C158),
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectableChip({
    required String engText,
    required String korText,
    required bool isSelected,
    required VoidCallback onTap,
    double horizontalPadding = 16.0,
  }) {
    const Color brandGolden = Color(0xFFE5C158);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? brandGolden : const Color(0xFF0D1527),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? brandGolden : Colors.white12, width: 1.5),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "$engText ",
                style: GoogleFonts.gowunBatang(
                  color: isSelected ? const Color(0xFF030712) : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              TextSpan(
                text: "($korText)",
                style: GoogleFonts.notoSansKr(
                  color: isSelected ? const Color(0xFF030712) : brandGolden,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedToggleButton({
    required String engTitle,
    required String korTitle,
    required bool isActive,
    required VoidCallback onTap
  }) {
    const Color brandGolden = Color(0xFFE5C158);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? brandGolden : const Color(0xFF0D1527),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isActive ? brandGolden : Colors.white12),
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: "$engTitle\n",
                  style: GoogleFonts.gowunBatang(color: isActive ? const Color(0xFF030712) : Colors.white60, fontWeight: FontWeight.bold, fontSize: 13, height: 1.3),
                ),
                TextSpan(
                  text: "($korTitle)",
                  style: GoogleFonts.notoSansKr(color: isActive ? const Color(0xFF030712) : brandGolden, fontWeight: FontWeight.bold, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required String subLabel,
    bool isBadge = false,
    VoidCallback? onTap,
  }) {
    const Color brandGolden = Color(0xFFE5C158);
    return InkWell(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${label.replaceAll('\n', ' ')} 페이지 준비 중입니다. (Page Under Construction)',
              style: GoogleFonts.notoSansKr(),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10), border: Border.all(color: brandGolden.withOpacity(0.2), width: 1.0)),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(icon, color: brandGolden, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(label, style: GoogleFonts.notoSansKr(color: const Color(0xFFFFF6D6), fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(subLabel, style: GoogleFonts.gowunBatang(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13.5)),
                  ),
                ),
              ],
            ),
            if (isBadge)
              Positioned(
                right: 0, top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)),
                  child: const Text("LIVE", style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}