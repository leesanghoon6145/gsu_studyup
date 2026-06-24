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
// [1] 메인 입장 화면 (지구본 정중앙 18초 순차 줌인/아웃 애니메이션 결합판)
// -----------------------------------------
class EntranceScreen extends StatefulWidget {
  const EntranceScreen({super.key});

  @override
  State<EntranceScreen> createState() => _EntranceScreenState();
}

class _EntranceScreenState extends State<EntranceScreen> with TickerProviderStateMixin {

  // 👑 [명칭: 대문 지구본 응원 애니메이션 제어 엔진]
  late AnimationController _cheeringController;
  late Animation<double> _firstWordScale;
  late Animation<double> _firstWordOpacity;
  late Animation<double> _secondWordScale;
  late Animation<double> _secondWordOpacity;

  @override
  void initState() {
    super.initState();

    // ⏳ [명칭: 18초 체인 타임라인 제어기] - 3초 단위 시퀀스 구동 설계
    _cheeringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );

    // 🔤 [명칭: GKE StudyUp이 줌인/아웃 스케일 필터]
    _firstWordScale = TweenSequence<double>([
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 16.6), // 0~3초: 줌인
      TweenSequenceItem<double>(tween: ConstantTween<double>(1.0), weight: 16.6),                                                  // 3~6초: 멈춤
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInCubic)), weight: 16.6),  // 6~9초: 줌아웃
      TweenSequenceItem<double>(tween: ConstantTween<double>(0.0), weight: 50.2),                                                  // 9~18초: 대기
    ]).animate(_cheeringController);

    // 🔤 [명칭: GKE StudyUp이 투명도 디졸브 필터]
    _firstWordOpacity = TweenSequence<double>([
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 16.6), // 0~3초: 페이드인
      TweenSequenceItem<double>(tween: ConstantTween<double>(1.0), weight: 16.6),          // 3~6초: 고정
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 16.6), // 6~9초: 페이드아웃
      TweenSequenceItem<double>(tween: ConstantTween<double>(0.0), weight: 50.2),          // 9~18초: 소멸
    ]).animate(_cheeringController);

    // 🇰🇷 [명칭: 응원 합니다 줌인/아웃 스케일 필터]
    _secondWordScale = TweenSequence<double>([
      TweenSequenceItem<double>(tween: ConstantTween<double>(0.0), weight: 50.0),                                                  // 0~9초: 대기
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 16.6), // 9~12초: 줌인
      TweenSequenceItem<double>(tween: ConstantTween<double>(1.0), weight: 16.6),                                                  // 12~15초: 멈춤
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInCubic)), weight: 16.8),  // 15~18초: 줌아웃
    ]).animate(_cheeringController);

    // 🇰🇷 [명칭: 응원 합니다 투명도 디졸브 필터]
    _secondWordOpacity = TweenSequence<double>([
      TweenSequenceItem<double>(tween: ConstantTween<double>(0.0), weight: 50.0),          // 0~9초: 대기
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 16.6), // 9~12초: 페이드인
      TweenSequenceItem<double>(tween: ConstantTween<double>(1.0), weight: 16.6),          // 12~15초: 고정
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 16.8), // 15~18초: 페이드아웃
    ]).animate(_cheeringController);

    // ⚡ [명칭: 진입 정각 즉시 가동 스케줄러] - 폰 아이콘 누르자마자 0초 만에 시동 거는 트리거
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _cheeringController.forward(from: 0.0);
        _cheeringController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _cheeringController.dispose(); // 👑 [역할: 자원 해제] 백그라운드 스레드 유령 구동 완전 차단
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandGolden = Color(0xFFE5C158); // GKE STUDYUP 전역 황금 컬러 스펙 동기화

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Stack(
        children: [
          // 🖼️ [명칭: 메인 대문 배경 지구본 패널]
          Positioned.fill(
            child: Image.asset(
              'assets/images/main_bg.png',
              fit: BoxFit.contain,
            ),
          ),

          // 👑 🎯 [명칭: 지구본 원의 정중앙 조준 애니메이션 스크린 컴포넌트]
          Positioned.fill(
            child: Center(
              child: Container(
                width: double.infinity,
                height: 150, // 자막이 상하로 흔들림 없이 우아하게 표출될 독립 구역 확보
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 🔤 [명칭: 1단계 자막 - GKE StudyUp이 가동부]
                    FadeTransition(
                      opacity: _firstWordOpacity,
                      child: ScaleTransition(
                        scale: _firstWordScale,
                        child: Text(
                          'GKE StudyUp이',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nanumMyeongjo(
                            color: brandGolden,
                            fontSize: 23,
                            // 1. 글자 자체를 가장 두꺼운 등급(w900)으로 상승
                            fontWeight: FontWeight.w900,
                            shadows: [
                              // 2. 글자 뒤편에 진한 외곽선을 겹쳐서 물리적으로 더 두껍게 확장
                              Shadow(color: Colors.black, blurRadius: 2, offset: const Offset(-1.5, -1.5)),
                              Shadow(color: Colors.black, blurRadius: 2, offset: const Offset(1.5, -1.5)),
                              Shadow(color: Colors.black, blurRadius: 2, offset: const Offset(1.5, 1.5)),
                              Shadow(color: Colors.black, blurRadius: 2, offset: const Offset(-1.5, 1.5)),
                              Shadow(color: Colors.black87, blurRadius: 20, offset: const Offset(4, 4)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 🇰🇷 [명칭: 2단계 자막 - 응원 합니다 가동부]
                    FadeTransition(
                      opacity: _secondWordOpacity,
                      child: ScaleTransition(
                        scale: _secondWordScale,
                        child: Text(
                          '응원 합니다',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSansKr( // 규칙 8: 한글 서체 노토산스 단일화
                            color: brandGolden,
                            fontWeight: FontWeight.bold,
                            fontSize: 23, // 규칙 8: 강조 타이틀 크기 23 고정
                            shadows: const [
                              Shadow(color: Colors.black87, blurRadius: 15, offset: Offset(2, 2)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🖱️ [명칭: 하단 입장용 투명 버튼 터치 영역] - 기존 배치 좌표 및 크기 100% 동결 보존
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
                    color: Colors.transparent, // 투명 터치 기능 유지
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

  void _showOverlayWelcomeBar(BuildContext targetContext) {
    final OverlayState overlayState = Overlay.of(targetContext);
    late OverlayEntry overlayEntry;

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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/images/logo.png',
                    width: 245,
                    height: 245,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '노력하는 너를 응원하는 별이 되어 줄게',
                    style: GoogleFonts.gowunBatang(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.85),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                  _buildCustomTextField(
                    hintText: 'Email Address',
                    icon: Icons.mail_outline_rounded,
                  ),
                  const SizedBox(height: 15),
                  _buildCustomTextField(
                    hintText: 'Password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: 45),
                  _buildGradientButton(
                    title: 'CREATE ACCOUNT (회원가입)',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildOutlineButton(
                    title: 'SIGN IN (로그인)',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (dashboardContext) {
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
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFFFCD34D)),
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Colors.white60,
            fontWeight: FontWeight.bold,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

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
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.fastOutSlowIn));

    _animController.forward();

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
                    color: Color(0xFF0D1527),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Text(
                      'Welcomto to GKE STUDYUP! ( GKE STUDYUP에 들어 오신것을 환영합니다 )',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansKr(
                        color: Colors.white,
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