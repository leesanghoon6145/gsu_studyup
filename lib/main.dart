import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
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
// [1] 메인 입장 화면 (설명글 삭제 및 투명 버튼 적용)
// -----------------------------------------
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
// [2] 회원가입 / 로그인 화면 (새로 만드는 화면)
// -----------------------------------------
class LoginSignupScreen extends StatelessWidget {
  const LoginSignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 어두운 판타지 감성 배경 (그라데이션으로 처리)
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E293B), Color(0xFF020617)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 소제목
                Text(
                  'GSU STUDYUP',
                  style: GoogleFonts.cinzel(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFDE047),
                    letterSpacing: 5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '마법 도서관에 오신 것을 환영합니다',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 60),

                // 이메일 입력창 (서판 느낌)
                _buildTextField(label: '이메일 주소', icon: Icons.email_outlined),
                const SizedBox(height: 20),

                // 비밀번호 입력창
                _buildTextField(label: '비밀번호', icon: Icons.lock_outline, isPassword: true),
                const SizedBox(height: 40),

                // [회원가입 버튼] - kery님 요청대로 별도 분리
                _buildAuthButton(
                  title: '신규 마법사 등록 (회원가입)',
                  isPrimary: true,
                  onPressed: () {
                    print('회원가입 클릭');
                  },
                ),
                const SizedBox(height: 15),

                // [로그인 버튼]
                _buildAuthButton(
                  title: '기존 마법사 입장 (로그인)',
                  isPrimary: false,
                  onPressed: () {
                    print('로그인 클릭');
                  },
                ),

                const SizedBox(height: 30),
                // 뒤로가기 버튼
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('처음 화면으로 돌아가기', style: TextStyle(color: Colors.white38)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 입력창 디자인 위젯
  Widget _buildTextField({required String label, required IconData icon, bool isPassword = false}) {
    return TextField(
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, color: const Color(0xFFFDE047)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFFDE047)),
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
      ),
    );
  }

  // 로그인/회원가입 버튼 디자인 위젯
  Widget _buildAuthButton({required String title, required bool isPrimary, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFFFDE047) : Colors.transparent,
          foregroundColor: isPrimary ? Colors.black : Colors.white,
          side: isPrimary ? null : const BorderSide(color: Color(0xFFFDE047)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: isPrimary ? 5 : 0,
        ),
        child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}