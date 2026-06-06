import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:gsu_studyup/timer/timer_screen.dart'; // 💡 실제 프로젝트 트리 경로 수호

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

  // 📚 14대 마스터 과목 데이터 완벽 수호 (영어/한국어 엄격 병기)
  final List<Map<String, String>> subjects = [
    {'en': 'Native Language', 'ko': '국어'},
    {'en': 'English', 'ko': '영어'}, {'en': 'Math', 'ko': '수학'},
    {'en': 'Convo', 'ko': '회화'},   {'en': 'Science', 'ko': '과학'},
    {'en': 'Social', 'ko': '사회'},  {'en': 'Hist', 'ko': '역사'},
    {'en': 'Ethics', 'ko': '도덕'},  {'en': 'SFL', 'ko': '제2외국어'},
    {'en': 'Info', 'ko': '정보'}, {'en': 'Lit Chinese', 'ko': '한문'},
    {'en': 'Tech & Home Assump', 'ko': '기술/가정'},
    {'en': 'Vocabulary & Idioms', 'ko': '영단어·숙어'},
    {'en': 'Other Subjects', 'ko': '기타과목'},
  ];

  // 🔊 백색소음 에셋 매핑 리스트
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

  // 🎧 지시사항 1번 해결: 10초 미리듣기 사운드 파이프라인 표준 정밀 교정
  void _handleSoundPreview(String displayName, String fileName) async {
    try {
      _previewTimer?.cancel();
      await _audioPlayer.stop();

      if (previewingSound == displayName) {
        setState(() => previewingSound = '');
      } else {
        setState(() => previewingSound = displayName);
        // 에셋 소스 다이렉트 주입 규격 준수
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

  // 🔘 단독 토글 활성화 및 음원 제어
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
                      children: ['중간고사', '기말고사', '모의고사', '2027 대학수능'].map((exam) {
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

      final missionResult = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TimerScreen(
            selectedSubject: selectedSubject,
            selectedDurationMinutes: selectedDuration,
            dynamicTestTitle: examName,
            targetExamDate: pickedDate,
            selectedSoundFile: selectedSoundFile,
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
                      _buildMenuButton(icon: Icons.forum_rounded, label: "학친방", subLabel: "Friends Study Room"),
                      _buildMenuButton(icon: Icons.assignment_ind_rounded, label: "개인이름 성취도", subLabel: "Personal Achievement"),
                      _buildMenuButton(icon: Icons.language_rounded, label: "동시접속자", subLabel: "Concurrent Users", isBadge: true),
                      _buildMenuButton(icon: Icons.fort_rounded, label: "나의제국", subLabel: "My Empire"),
                      _buildMenuButton(icon: Icons.support_agent_rounded, label: "교육상담", subLabel: "Education Counseling"),
                      _buildMenuButton(icon: Icons.rate_review_rounded, label: "건의사항", subLabel: "Suggestions"),
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
                return _buildSelectableChip(
                  text: displayName,
                  isSelected: selectedSubject == displayName,
                  onTap: () => setState(() => selectedSubject = displayName),
                );
              }).toList(),
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
                            // 무결성 테두리 규격 확보 완료
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? brandGolden : const Color(0xFF0D1527),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? brandGolden : Colors.white12, width: 1.5),
        ),
        child: Text(
          text,
          style: GoogleFonts.gowunBatang(color: isSelected ? const Color(0xFF030712) : Colors.white60, fontWeight: FontWeight.bold, fontSize: 13),
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

  Widget _buildMenuButton({required IconData icon, required String label, required String subLabel, bool isBadge = false}) {
    const Color brandGolden = Color(0xFFE5C158);
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${label.replaceAll('\n', ' ')} 페이지 준비 중입니다.', style: GoogleFonts.gowunBatang())));
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