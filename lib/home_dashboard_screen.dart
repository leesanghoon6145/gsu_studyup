import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:gsu_studyup/timer/timer_screen.dart'; // 💡 상위 폴더 구조에 맞춘 임포트 경로 수호

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  // 🌟 게이미피케이션 핵심 상태 변수 (원장님 지시: 기본 메인 기준 75개 설정)
  String userName = '이규현';
  int currentStars = 75;
  final int maxTargetStars = 90;

  String selectedSubject = '';
  String selectedMode = 'Weekday (주중 학습)';
  int selectedDuration = 30;
  String selectedSound = '';

  late AudioPlayer _audioPlayer;

  final List<Map<String, String>> subjects = [
// 📚 [원장님 지시사항 반영] 1열부터 7열까지 자로 잰 듯 정렬된 14대 마스터 과목 데이터 세트
    // 1열
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
                        final bool isCurrentSelected = temporarySelectedExam ==
                            exam && customExamController.text.isEmpty;
                        return GestureDetector(
                          onTap: () {
                            setPopupState(() {
                              temporarySelectedExam = exam;
                              customExamController.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isCurrentSelected
                                  ? const Color(0xFFE5C158)
                                  : Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCurrentSelected ? const Color(
                                    0xFFE5C158) : Colors.white24,
                              ),
                            ),
                            child: Text(
                              exam,
                              style: GoogleFonts.gowunBatang(
                                color: isCurrentSelected
                                    ? Colors.black
                                    : const Color(0xB3FFFFFF),
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
                        const Icon(Icons.edit_note_rounded, color: Color(
                            0xFFE5C158), size: 20),
                        const SizedBox(width: 6),
                        Text(
                          "Custom Input (직접 입력)",
                          style: GoogleFonts.gowunBatang(color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5C158)
                            .withOpacity(0.4)),
                      ),
                      child: TextField(
                        controller: customExamController,
                        style: GoogleFonts.gowunBatang(color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                        onChanged: (val) {
                          if (val.isNotEmpty) {
                            setPopupState(() {
                              temporarySelectedExam = '';
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: "e.g. 사법고시, 행정고시, TOEIC",
                          hintStyle: GoogleFonts.gowunBatang(
                              color: Colors.white38, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
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
                            SnackBar(content: Text('시험 종류를 선택하거나 직접 입력해 주세요!',
                                style: GoogleFonts.gowunBatang())),
                          );
                          return;
                        }

                        Navigator.of(context).pop();
                        _openDatePickerAndNavigate(finalExamName);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5C158),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius
                            .circular(10)),
                      ),
                      child: Text(
                        "NEXT: SELECT DATE (날짜 선택)",
                        style: GoogleFonts.gowunBatang(color: Colors.black,
                            fontWeight: FontWeight.bold),
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
      if (!mounted) return;

      // 🚨 [매개변수 일치 정밀 튜닝 완료] timer_screen.dart 아키텍처와 변수 100% 동기화
      final missionResult = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              TimerScreen(
                selectedSubject: selectedSubject,
                selectedDurationMinutes: selectedDuration,
                dynamicTestTitle: examName,
                targetExamDate: pickedDate,
              ),
        ),
      );

      // 만약 타이머 미션이 성공하여 별 보상 데이터가 반환되었다면 실시간 갱신 처리
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
          style: GoogleFonts.gowunBatang(color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 1.5),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          // 👈 cross 뒤에 AxisAlignment를 붙이고 콜론(:)으로 연결!
          children: [

            // 🏰 [웅장한 아트워크 구역] 마법의 책과 탑 비주얼 + 게이미피케이션 현황판
// 🏰 [원장님 지시사항 반영] 불필요한 별빛 구역 완전 삭제 및 영문 병기 6대 핵심 관리 메뉴
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1527),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: brandGolden.withOpacity(0.3), width: 1.2),
              ),
              child: Column(
                children: [
                  // 🎛️ 글로벌 상용화 스펙: 영문 병기 및 가독성 확보를 위한 2열 격자 배치
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 2.1, // 👈 영문이 들어가면서 늘어난 텍스트 높이를 받아주는 황금 배율 설정
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildMenuButton(
                        icon: Icons.forum_rounded,
                        label: "학친방",
                        subLabel: "Friends Study Room",
                      ),
                      _buildMenuButton(
                        icon: Icons.assignment_ind_rounded,
                        label: "개인이름 성취도",
                        subLabel: "Personal Achievement",
                      ),
                      _buildMenuButton(
                        icon: Icons.language_rounded, // 🌍 글로벌 규격 지구본 아이콘 적용
                        label: "동시접속자",
                        subLabel: "Concurrent Users",
                        isBadge: true,
                      ),
                      _buildMenuButton(
                        icon: Icons.fort_rounded,
                        label: "나의제국",
                        subLabel: "My Empire",
                      ),
                      _buildMenuButton(
                        icon: Icons.support_agent_rounded,
                        label: "교육상담",
                        subLabel: "Education Counseling",
                      ),
                      _buildMenuButton(
                        icon: Icons.rate_review_rounded,
                        label: "건의사항",
                        subLabel: "Suggestions",
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Q1. 과목 선택
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

            // Q2. 학습 모드
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
                  onTap: () =>
                      setState(() =>
                      selectedMode = 'Weekend/Vacation (주말·방학 학습)'),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Q3. 집중 시간 선택
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

            // Q4. 백색소음 선택
            _buildSectionTitle('White Noise Selection\n[백색소음 선택]'),
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
                  SnackBar(content: Text(
                      '먼저 과목을 선택해 주세요!', style: GoogleFonts.gowunBatang())),
                );
              }
                  : () {
                _showExamSelectionDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGolden,
                minimumSize: const Size(double.infinity, 58),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Select Exam Type & Date\n(목표 시험 및 일정 선택 후 집중 시작)',
                style: GoogleFonts.gowunBatang(color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
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
    return Text(title, style: GoogleFonts.gowunBatang(color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
        height: 1.4));
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
          border: Border.all(
              color: isSelected ? brandGolden : Colors.white12, width: 1.5),
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

  Widget _buildExpandedToggleButton(
      {required String title, required bool isActive, required VoidCallback onTap}) {
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

// 🎨 [원장님 기획 완벽 반영] 1행(로고+한글), 2행(로고 없이 영문 대폭 확대) 쾌적 가독성 버튼 빌더
  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required String subLabel,
    bool isBadge = false,
  }) {
    const Color brandGolden = Color(0xFFE5C158);
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${label.replaceAll('\n', ' ')} 페이지 준비 중입니다.',
              style: GoogleFonts.gowunBatang(),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: brandGolden.withOpacity(0.2), width: 1.0),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1행: 로고(아이콘) 배치 + 선명한 한글 타이틀
                Row(
                  children: [
                    Icon(icon, color: brandGolden, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          label,
                          style: GoogleFonts.gowunBatang(
                            color: const Color(0xFFFFF6D6),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7), // 👈 글로벌 규격의 쾌적함을 위한 황금 행간 세팅

                // 2행: 원장님 핵심 지시 (앞에 로고를 완전히 제거하여 영문 타이포 공간 100% 확보 및 시원하게 확대)
                Padding(
                  padding: const EdgeInsets.only(left: 2), // 한글 로고 라인과 예쁘게 정렬을 맞추는 마진
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      subLabel,
                      style: GoogleFonts.gowunBatang(
                        color: Colors.white70, // 은은하면서 눈이 편안한 화이트 스케일
                        fontWeight: FontWeight.bold, // 글로벌 위엄이 살아나는 Bold 두께 고정
                        fontSize: 13.5, // 👈 학생들이 절대 짜증 나지 않도록 글자 크기를 시원하게 상향 조정!
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (isBadge)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "LIVE",
                    style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} // 👈 🚨 [체크 필수] 이 파일의 가장 마지막 최종 닫는 중괄호입니다!/ 👈 클래스가 끝나는 파일의 최하단 최종 중괄호의 위치를 꼭 확인해 주세요!