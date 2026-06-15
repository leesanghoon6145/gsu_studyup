import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:gsu_studyup/square/member_achievement_screen.dart';
import 'dart:async';
import 'package:gsu_studyup/timer/timer_screen.dart'; // 💡 실제 프로젝트 트리 경로 수호
import 'square/friend_study_room_screen.dart';
import 'package:gsu_studyup/square/live_active_users_screen.dart';
import 'package:gsu_studyup/square/educational_consultation_screen.dart';

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

  // 👑 [비즈니스 모델 연동]: 유료화 VIP 가두리 코어 상태 변수 선제 배치
  bool _isVipMember = false; // 기본 FREE 회원(false), 활성화 버튼 누르면 VIP(true) 시뮬레이션 스위칭
  String _targetUniversity = "Seoul National University (서울대학교)";

  // 📚 14대 과목 정리 리스트 수호
  List<Map<String, String>> subjects = [
    {'en': 'Native Language', 'ko': '국어'},
    {'en': 'Math', 'ko': '수학'},
    {'en': 'Exercise', 'ko': '운동'},
    {'en': 'Reading', 'ko': '독서'},
  ];

  // 🔊 백색소음 에셋 매핑 리스트 완벽 수호
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
                              style: GoogleFonts.gowunBatang(color: isCurrentSelected ? Colors.black : const Color(0xB3FFFFFF), fontWeight: FontWeight.bold, fontSize: 13),
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
                        Text("Custom Input (직접 입력)", style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5C158).withOpacity(0.4))),
                      child: TextField(
                        controller: customExamController,
                        style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        onChanged: (val) {
                          if (val.isNotEmpty) {
                            setPopupState(() => temporarySelectedExam = '');
                          }
                        },
                        decoration: InputDecoration(
                          hintText: "e.g. 사법고시, 행정고시, TOEIC",
                          hintStyle: GoogleFonts.gowunBatang(color: Colors.white38, fontSize: 13),
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
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('시험 종류를 선택하거나 직접 입력해 주세요!', style: GoogleFonts.gowunBatang())));
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

      // 👑 [전선 연결]: 타이머 화면을 호출할 때 마이페이지의 목표 대학과 VIP 변수를 직통으로 던져줍니다!
      final missionResult = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TimerScreen(
            selectedSubject: selectedSubject,
            selectedDurationMinutes: selectedDuration,
            dynamicTestTitle: examName,
            targetExamDate: pickedDate,
            selectedSoundFile: selectedSoundFile,
            targetUniversity: _targetUniversity, // ⚡ 추가 수혈
            isVipMember: _isVipMember,           // ⚡ 추가 수혈
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
                    style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "e.g. 요가, 축구, 영어, Yoga, Hobby",
                      hintStyle: GoogleFonts.gowunBatang(color: Colors.white38, fontSize: 12),
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
                      child: Text("CANCEL [취소]", style: GoogleFonts.gowunBatang(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton(
                      onPressed: () {
                        final text = subjectController.text.trim();
                        if (text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('과목명을 입력해 주세요!', style: GoogleFonts.gowunBatang())));
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
                      child: Text("CREATE [생성]", style: GoogleFonts.gowunBatang(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
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

  // ==============================================================================
  // 👑 [마이페이지 개설 및 유료화 VIP 가두리 락 스택 팝업 제어 엔클로저]
  // ==============================================================================
  void _openVipMyPagePopup() {
    final TextEditingController uniController = TextEditingController(text: _targetUniversity);
    const Color brandGolden = Color(0xFFE5C158);

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('👑 GSU MY PAGE', style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 17)),
                            Text('(마이페이지 / VIP 결제 센터)', style: GoogleFonts.gowunBatang(color: Colors.white38, fontSize: 11.5)),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20), onPressed: () => Navigator.pop(context))
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ⚙️ [정밀 교정 완료]: 379번 라인 오타였던 'Colors.whiteAA'를 순정 'Colors.white70'으로 완벽 소독!
                        Text("현재 등급 회원:", style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isVipMember ? brandGolden : Colors.black45,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _isVipMember ? brandGolden : Colors.white12),
                          ),
                          child: Text(
                            _isVipMember ? "👑 PREMIUM VIP" : "FREE 일반 회원",
                            style: GoogleFonts.gowunBatang(color: _isVipMember ? Colors.black : Colors.white60, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text("🎯 나의 목표 대학 설정 (개인별 변경 가능)", style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
                      child: TextField(
                        controller: uniController,
                        style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "목표 대학을 입력하세요",
                          hintStyle: GoogleFonts.gowunBatang(color: Colors.white24, fontSize: 12),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (!_isVipMember)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0x1FFF3B30), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0x40FF3B30))),
                        child: Text(
                          "🚫 알림: 일반회원은 입력하신 대학명이 타이머 화면 중앙 별 애니메이션 및 성취도 리포트에 실시간 연동 발동되지 않고 강력 제한됩니다.",
                          style: GoogleFonts.gowunBatang(color: const Color(0xFFFF453A), fontSize: 11.0, fontWeight: FontWeight.bold, height: 1.35),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0x1F34C759), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0x4034C759))),
                        child: Text(
                          "✨ VIP 연동 잠금이 해제되었습니다! 설정하신 명문대 목표가 타이머 중앙 별 한복판에 5분 주기 황금빛 아우라로 실시간 연동 발동 중입니다.",
                          style: GoogleFonts.gowunBatang(color: Colors.greenAccent, fontSize: 11.0, fontWeight: FontWeight.bold, height: 1.35),
                        ),
                      ),
                    const SizedBox(height: 22),

                    GestureDetector(
                      onTap: () {
                        setState(() { _isVipMember = !_isVipMember; });
                        setPopupState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isVipMember
                                  ? [Colors.grey.shade800, Colors.grey.shade900]
                                  : [const Color(0xFFF1C40F), brandGolden],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              if (!_isVipMember) BoxShadow(color: brandGolden.withOpacity(0.35), blurRadius: 8, spreadRadius: 1)
                            ]
                        ),
                        // ⚙️ [가독성 수술 마감]: 389번 라인의 삼항 연산자 구조 및 괄호 마감을 무결점으로 완벽 정리!
                        child: Center(
                          child: Text(
                            _isVipMember ? "Membership 해제 (구독 테스트용)" : "👑 GSU VIP 멤버십 활성화 (월 1,900원)",
                            style: GoogleFonts.gowunBatang(color: _isVipMember ? Colors.white60 : Colors.black, fontWeight: FontWeight.bold, fontSize: 13.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() { _targetUniversity = uniController.text.trim().isEmpty ? "미설정" : uniController.text.trim(); });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: Text("저장 및 닫기", style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
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
        automaticallyImplyLeading: false,
        title: Text(
          'GSU STUDYUP',
          style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 1.5),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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
                          // 📡 원래 주소인 친구 학습방 스크린으로만 안전하게 진입!
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
                          // 📡 웅장한 전 세계 과목 비율 원그래프 라이브 스크린으로 분리 진입!
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
                          // 👑 [교육상담 보석 버튼 성문 개통]: 기존 화면을 보존하고 새 화면으로 진격!
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EducationalConsultationScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuButton(
                        icon: Icons.account_circle_rounded,
                        label: "👑 마이페이지",
                        subLabel: "VIP My Page",
                        onTap: () => _openVipMyPagePopup(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildSectionTitle('Subject Selection\n[과목 선택]'),
            const SizedBox(height: 12),

            Wrap(
              spacing: 10, runSpacing: 10,
              children: subjects.map((sub) {
                final displayName = '${sub['en']} (${sub['ko']})';
                final bool isSelected = selectedSubject == displayName;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4, right: 6),
                      child: _buildSelectableChip(
                        text: displayName,
                        isSelected: isSelected,
                        onTap: () => setState(() => selectedSubject = displayName),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => _deleteSubject(sub, displayName),
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
                style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),

            _buildSectionTitle('Learning Mode Selection\n[학습 모드 선택]'),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildExpandedToggleButton(
                  title: 'Weekday\n(주중 학습)',
                  isActive: selectedMode == 'Weekday (주중 학습)',
                  onTap: () => setState(() => selectedMode = 'Weekday (주중 학습)'),
                ),
                const SizedBox(width: 10),
                _buildExpandedToggleButton(
                  title: 'Weekend/Vacation\n(주말·방학 학습)',
                  isActive: selectedMode == 'Weekend/Vacation (주말·방학 학습)',
                  onTap: () => setState(() => selectedMode = 'Weekend/Vacation (주말·방학 학습)'),
                ),
              ],
            ),
            const SizedBox(height: 30),

            _buildSectionTitle('Focus Mode Selection\n[집중 모드 선택]'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: [30, 60, 90].map((mins) {
                final displayName = '$mins Mins(분)';
                return _buildSelectableChip(
                  text: displayName,
                  isSelected: selectedDuration == mins,
                  onTap: () => setState(() => selectedDuration = mins),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),

            _buildSectionTitle('White Noise Selection\n[백색소음 선택]'),
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
                          style: GoogleFonts.gowunBatang(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF030712) : const Color(0xFFEFEFEF)),
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
                        child: Text(
                          displayName,
                          style: GoogleFonts.gowunBatang(color: isSelected ? const Color(0xFF030712) : Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
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

            ElevatedButton(
              onPressed: selectedSubject.isEmpty
                  ? () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('먼저 과목을 선택해 주세요!', style: GoogleFonts.gowunBatang())));
              }
                  : () => _showExamSelectionDialog(),
              style: ElevatedButton.styleFrom(backgroundColor: brandGolden, minimumSize: const Size(double.infinity, 58), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(
                'Select Exam Type & Date\n(목표 시험 및 일정 선택 후 집중 시작)',
                style: GoogleFonts.gowunBatang(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, height: 1.4));
  }

  Widget _buildSelectableChip({required String text, required bool isSelected, required VoidCallback onTap}) {
    const Color brandGolden = Color(0xFFE5C158);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? brandGolden : const Color(0xFF0D1527),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? brandGolden : Colors.white12, width: 1.5),
        ),
        child: Text(
          text,
          style: GoogleFonts.gowunBatang(
            color: isSelected ? const Color(0xFF030712) : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedToggleButton({required String title, required bool isActive, required VoidCallback onTap}) {
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
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.gowunBatang(color: isActive ? const Color(0xFF030712) : Colors.white60, fontWeight: FontWeight.bold, fontSize: 13, height: 1.3),
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
              style: GoogleFonts.gowunBatang(),
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
                        child: Text(label, style: GoogleFonts.gowunBatang(color: const Color(0xFFFFF6D6), fontWeight: FontWeight.bold, fontSize: 13)),
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