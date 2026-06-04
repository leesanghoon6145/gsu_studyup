import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:gsu_studyup/timer/timer_screen.dart';
 // 💡 상위 폴더 구조에 맞춘 임포트 경로 수호

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  // 🌟 게이미피케이션 핵심 상태 변수 (원장님 지시: 기본 메인 기준 75개 설정)
  int currentStars = 75;
  final int maxTargetStars = 90;

  String selectedSubject = '';
  String selectedMode = 'Weekday (주중 학습)';
  int selectedDuration = 30;
  String selectedSound = '';

  late AudioPlayer _audioPlayer;

  final List<Map<String, String>> subjects = [
    {'en': 'Korean', 'ko': '국어'}, {'en': 'English', 'ko': '영어'},
    {'en': 'English Voca', 'ko': '영어단·숙어'}, {'en': 'English Speaking', 'ko': '영어회화'},
    {'en': 'Math', 'ko': '수학'}, {'en': 'Science', 'ko': '과학'},
    {'en': 'Social Studies', 'ko': '사회'}, {'en': 'History', 'ko': '역사'},
    {'en': 'Second Language', 'ko': '제2외국어'}, {'en': 'Ethics', 'ko': '도덕'},
    {'en': 'Tech & Home', 'ko': '기술/가정'}, {'en': 'Chinese Characters', 'ko': '한문'},
    {'en': 'Information Tech', 'ko': '정보'},
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
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _handleSoundPlay(String displayName, String fileName) async {
    try {
      if (selectedSound == displayName) {
        await _audioPlayer.stop();
        setState(() => selectedSound = '');
      } else {
        await _audioPlayer.stop();
        setState(() => selectedSound = displayName);
        await _audioPlayer.play(AssetSource('sounds/$fileName'));
      }
    } catch (e) {
      debugPrint("오디오 재생 실패: $e");
    }
  }

  // 👑 [원장님 기획] 시험 종류 선택 + 일반인 주관식 입력창 통합 팝업 엔진
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
                      style: GoogleFonts.gowunBatang(
                        color: const Color(0xFFE5C158),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 18),

                    Wrap(
                      spacing: 8, runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        '중간고사', '기말고사', '모의고사', '2027 대학수능'
                      ].map((exam) {
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
                              border: Border.all(
                                color: isCurrentSelected ? const Color(0xFFE5C158) : Colors.white24,
                              ),
                            ),
                            child: Text(
                              exam,
                              style: GoogleFonts.gowunBatang(
                                color: isCurrentSelected ? Colors.black : const Color(0xB3FFFFFF),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
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
                        Text(
                          "Custom Input (직접 입력)",
                          style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5C158).withOpacity(0.4)),
                      ),
                      child: TextField(
                        controller: customExamController,
                        style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        onChanged: (val) {
                          if (val.isNotEmpty) {
                            setPopupState(() {
                              temporarySelectedExam = '';
                            });
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
                        if (finalExamName.isEmpty) {
                          finalExamName = temporarySelectedExam;
                        }

                        if (finalExamName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('시험 종류를 선택하거나 직접 입력해 주세요!', style: GoogleFonts.gowunBatang())),
                          );
                          return;
                        }

                        Navigator.of(context).pop();
                        _openDatePickerAndNavigate(finalExamName);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5C158),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        "NEXT: SELECT DATE (날짜 선택)",
                        style: GoogleFonts.gowunBatang(color: Colors.black, fontWeight: FontWeight.bold),
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

  // 📅 [글로벌 달력 연동 마스터 엔진]
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
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE5C158),
              onPrimary: Colors.black,
              surface: Color(0xFF0D1527),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF030712),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      DateTime pickedDateOnly = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
      int differenceInDays = pickedDateOnly.difference(todayZeroClock).inDays;

      String calculatedDDay = "D - $differenceInDays";
      if (differenceInDays == 0) calculatedDDay = "D - DAY";

      if (!mounted) return;

      // 🚨 [핵심 동기화] 타이머 화면이 닫힐 때 전송하는 완료 데이터를 대시보드로 수집
      final missionResult = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TimerScreen(
            selectedSubject: selectedSubject,
            selectedMode: selectedMode,
            selectedDurationMinutes: selectedDuration,
            dynamicTestTitle: examName,
            calculatedDDay: calculatedDDay,
          ),
        ),
      );

      // 만약 타이머 미션이 성공하여 별 보상 데이터가 반환되었다면 실시간 갱신 처리
      if (missionResult != null && missionResult is Map<String, dynamic>) {
        if (missionResult['isSuccess'] == true) {
          int earned = missionResult['earnedStars'] ?? 1;
          setState(() {
            currentStars += earned;
            if (currentStars > maxTargetStars) currentStars = maxTargetStars;
          });
        }
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

            // 🏰 [웅장한 아트워크 구역] 마법의 책과 탑 비주얼 + 게이미피케이션 현황판
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1527),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: brandGolden.withOpacity(0.3), width: 1.2),
                image: const DecorationImage(
                  image: AssetImage('assets/images/dashboard_tower_bg.png'), // 마법의 탑 배경 지정 백업
                  fit: BoxFit.cover,
                  opacity: 0.15,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.menu_book_rounded, color: brandGolden, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            "Magic Tower Status",
                            style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      // 실시간 텍스트 수집 인디케이터 (75/90)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: brandGolden.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: brandGolden, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              "$currentStars / $maxTargetStars",
                              style: const TextStyle(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 마법의 탑 웅장한 게이미피케이션 프로그레스 바
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: currentStars / maxTargetStars,
                      minHeight: 12,
                      backgroundColor: Colors.black38,
                      valueColor: const AlwaysStoppedAnimation<Color>(brandGolden),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Collect Time Stars to complete the Great Magic Tower Journey!\n(타임스타를 수집하여 위대한 마법의 탑 여정을 완수하세요!)",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.gowunBatang(color: Colors.white38, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Q1. 과목 선택
            _buildSectionTitle('Which subject will you study?\n(어떤 과목을 공부할까요?)'),
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

            // Q2. 학습 모드
            _buildSectionTitle('Which learning mode will you start?\n(어떤 학습 모드로 시작할까요?)'),
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

            // Q3. 집중 시간 선택
            _buildSectionTitle('How long will you focus?\n(얼마나 집중해 볼까요?)'),
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

            // Q4. 백색소음 선택
            _buildSectionTitle('Choose a sound to help you focus.\n(집중을 도울 소리를 골라보세요)'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: sounds.map((snd) {
                final displayName = '${snd['en']} (${snd['ko']})';
                return _buildSelectableChip(
                  text: displayName,
                  isSelected: selectedSound == displayName,
                  onTap: () => _handleSoundPlay(displayName, snd['file']!),
                  isSoundChip: true,
                );
              }).toList(),
            ),
            const SizedBox(height: 40),

            // 거대 시작 버튼 (브랜드 황금색 컬러 단일화 완료)
            ElevatedButton(
              onPressed: selectedSubject.isEmpty
                  ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('먼저 과목을 선택해 주세요!', style: GoogleFonts.gowunBatang())),
                );
              }
                  : () {
                _showExamSelectionDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGolden,
                minimumSize: const Size(double.infinity, 58),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
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

  Widget _buildSelectableChip({
    required String text, required bool isSelected, required VoidCallback onTap,
    bool isSoundChip = false,
  }) {
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSoundChip && isSelected) ...[
              const Icon(Icons.music_note, color: Color(0xFF030712), size: 16),
              const SizedBox(width: 4),
            ],
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: GoogleFonts.gowunBatang(
                  color: isSelected ? const Color(0xFF030712) : Colors.white60,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? brandGolden : const Color(0xFF0D1527),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isActive ? brandGolden : Colors.white12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.gowunBatang(
              color: isActive ? const Color(0xFF030712) : Colors.white60,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}