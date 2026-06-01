import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'timer/timer_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
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
    _audioPlayer.setReleaseMode(ReleaseMode.loop); // 백색소음 1분 뒤 끊김 완벽 방어 설정
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'GSU STUDYUP',
          style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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

            // Q2. 학습 모드 (원장님 요청 피드백: 글자 쪼개짐 완벽 교정 완료)
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

            // Q3. 집중 시간 선택 (원장님 아이디어 반영: 중복 제거 및 넘침 에러 완벽 해결)
            _buildSectionTitle('How long will you focus?\n(얼마나 집중해 볼까요?)'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: [30, 60, 90].map((mins) {
                final displayName = '$mins Mins(분)'; // ➔ 깔끔하게 '30 Mins(분)'으로 가독성 극대화
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

// // 집중 시작 버튼
            ElevatedButton(
              onPressed: selectedSubject.isEmpty
                  ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('먼저 과목을 선택해 주세요!')),
                );
              }
                  : () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const TimerScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCD34),
                minimumSize: const Size(double.infinity, 58),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Start Focus with These Settings\n(이 설정으로 집중 시작하기)',
                style: GoogleFonts.gowunBatang(color: Colors.black, fontWeight: FontWeight.bold),
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
    return Text(title, style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, height: 1.4));
  }

  Widget _buildSelectableChip({
    required String text, required bool isSelected, required VoidCallback onTap,
    bool isSoundChip = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFCD34D) : const Color(0xFF0D1527),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFFFCD34D) : Colors.white12, width: 1.5),
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
                style: TextStyle(
                  color: isSelected ? const Color(0xFF030712) : Colors.white60,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedToggleButton({required String title, required bool isActive, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10), // 내부 여백 최적화
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFCD34D) : const Color(0xFF0D1527),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isActive ? const Color(0xFFFCD34D) : Colors.white12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? const Color(0xFF030712) : Colors.white60,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              height: 1.3, // 줄바꿈 간격 조절
            ),
          ),
        ),
      ),
    );
  }
}