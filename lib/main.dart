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

  // 👑 30년 베테랑의 무결점 60프레임 오버레이 애니메이션 제어 모듈 (화면 먹통/터치 락 완벽 박멸)
  void _showOverlayWelcomeBar(BuildContext targetContext) {
    final OverlayState overlayState = Overlay.of(targetContext);

    late OverlayEntry overlayEntry;

    // 부드러운 애니메이션 처리를 위한 독립 위젯 생성
    overlayEntry = OverlayEntry(
      builder: (context) {
        return _SmoothWelcomeOverlayWidget(
          onRemove: () {
            overlayEntry.remove();
          },
        );
      },
    );

    overlayState.insert(overlayEntry);
  }

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
                      // 1. 🔥 [연결 완성] 대시보드 화면으로 먼저 완벽하게 이동 (백 버튼 유발 요인 완전 박멸)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (dashboardContext) {
                            // 2. 🎯 화면이 완전히 렌더링된 뒤 터치 방해를 전혀 주지 않는 비배리어(Non-barrier) 오버레이 호출
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _showOverlayWelcomeBar(dashboardContext);
                            });
                            return const HomeDashboardScreen();
                          },
                        ),
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
}

// 👑 30년 베테랑의 60프레임 무결점 오버레이 전용 슬라이딩 애니메이션 내부 조립 위젯
class _SmoothWelcomeOverlayWidget extends StatefulWidget {
  final VoidCallback onRemove;
  const _SmoothWelcomeOverlayWidget({required this.onRemove});

  @override
  State<_SmoothWelcomeOverlayWidget> createState() => _SmoothWelcomeOverlayWidgetState();
}

class _SmoothWelcomeOverlayWidgetState extends State<_SmoothWelcomeOverlayWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // 화면 외부 바닥 대기
      end: const Offset(0, 0),   // 화면 내부 정위치 안착
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.fastOutSlowIn));

    // 실행 즉시 부드럽게 스~윽 업
    _animController.forward();

    // 2초간 유지 후 부드럽게 스~윽 다운되며 메모리에서 완전 자가 해제 처리
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _animController.reverse().then((_) {
          widget.onRemove();
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SlideTransition(
            position: _slideAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D1527), // 프리미엄 다크 네이비 단색 매칭
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)), // 네 모서리 부드러운 라운드
                  ),
                  child: SafeArea(
                    top: false,
                    child: Text(
                      'Welcomto to GKE STUDYUP! ( GKE STUDYUP에 들어 오신것을 환영합니다 )',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansKr(
                        color: Colors.white, // 흰색 글자 단일 동기화
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}