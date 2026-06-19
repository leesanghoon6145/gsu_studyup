import 'global_lang.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_dashboard_screen.dart';
import 'signup_screen.dart';
import 'package:gsu_studyup/global_lang.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👑 [DKE 글로벌 언어 사전 엔진 발동]
  await DkeLang.initialize();

  runApp(const GsuStudyUpApp());
}

class GsuStudyUpApp extends StatelessWidget {
  const GsuStudyUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GSU StudyUp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFDE047), // 황금색 포인트
      ),
      // 처음 시작 화면을 EntranceScreen으로 설정
      home: const EntranceScreen(),
    );
  }
}

// -----------------------------------------
// [1] 메인 입장 화면 (설명글 삭제 및 투명 버튼 적용)// -----------------------------------------
class EntranceScreen extends StatelessWidget {
  const EntranceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/main_bg.png',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            bottom: 15,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 260,
                height: 60,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginSignupScreen()),
                    );
                  },
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------
// [2] 회원가입 / 로그인 화면 (이미지 디자인 완벽 반영 버전)
// -----------------------------------------
class LoginSignupScreen extends StatelessWidget {
  const LoginSignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🌟 키보드가 올라올 때 노란 줄무늬(OVERFLOWED)가 생기지 않도록 방어하는 핵심 설정!
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF030712),
              Color(0xFF0B132B),
            ],
          ),
        ),
        child: SafeArea(
          // 🌟 자판이 올라오면 화면을 위아래로 부드럽게 밀어 올려주는 천하무적 스크롤 부품!
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/images/logo.png',
                    width: 245,  // 👈 크기가 너무 크거나 작으면 이 숫자를 고치면 됩니다!
                    height: 245,
                  ),
                  const SizedBox(height: 10),

                  // 서브 타이틀
                  Text(
                    '노력하는 너를 응원하는 별이 되어 줄게',
                    style: GoogleFonts.gowunBatang(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.85),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ✨ 시그니처 십자 별빛 플레어 효과 효과
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 240,
                        height: 1.8,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0x33FDE047),
                              Color(0xFFFFFDF0),
                              Color(0x33FDE047),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 1.8,
                        height: 36,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(0xFFFFFDF0),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFF59E0B),
                              blurRadius: 10,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 45),

                  // 📬 이메일 입력창
                  _buildCustomTextField(
                    hintText: 'Email Address',
                    icon: Icons.mail_outline_rounded,
                  ),
                  const SizedBox(height: 15),

                  // 🔒 비밀번호 입력창 (노란줄 완전 제거 + 닫힌 자물쇠로 변경!)
                  _buildCustomTextField(
                    hintText: 'Password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: 45),

                  // 🟡 CREATE ACCOUNT (회원가입) 버튼
                  _buildGradientButton(
                    title: 'CREATE ACCOUNT (회원가입)',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignupScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 15),

                  // ⚪ SIGN IN (로그인) 테두리 버튼
                  _buildOutlineButton(
                    title: 'SIGN IN (로그인)',
                    onPressed: () {
                      // 1. 로그인 환영 메시지 띄우기 (영어 선행 매너 적용)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Welcome to GSU StudyUp! (GSU StudyUp에 오신 것을 환영합니다!)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      );

                      // 2. 🔥 [연결 완성] 버튼 클릭 시 설정 대시보드 화면으로 부드럽게 진입!
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeDashboardScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// ➔ [입력창 도구 코드 수정] _buildCustomTextField 함수 안을 보세요!
  Widget _buildCustomTextField({
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1527),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        obscureText: isPassword,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold, // 👈 사용자가 타이핑하는 글자 진하게!
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFFFCD34D)),
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Colors.white60,     // 👈 글씨가 더 잘 보이게 색상 명도 업!
            fontWeight: FontWeight.bold, // 👈 'Email Address', 'Password' 안내 문구 진하게!
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // 🛠️ 그라데이션 버튼을 만드는 전용 도구
  Widget _buildGradientButton({required String title, required VoidCallback onPressed}) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFCD34D), Color(0xFFF59E0B)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          title,
          style: const TextStyle(color: Color(0xFF030712), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  // 🛠️ 테두리 버튼을 만드는 전용 도구
  Widget _buildOutlineButton({required String title, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFCD34D)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          title,
          style: const TextStyle(color: Color(0xFFFCD34D), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
} // 👈 main.dart 파일의 진짜 최종 마감 끝자락!