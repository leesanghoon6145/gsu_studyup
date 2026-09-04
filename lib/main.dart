import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart'; // 🆕 [한국어 달력 등 시스템 위젯 현지화]
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🆕 [부모-자녀 응원 시스템] 로그인 상태 변화 감지용
import 'package:cloud_firestore/cloud_firestore.dart'; // 🆕 [부모-자녀 응원 시스템] DocumentSnapshot 타입 참조용
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dart:async';
import 'home_dashboard_screen.dart';
import 'signup_screen.dart';
import 'parent/parent_main_dashboard_screen.dart'; // 🆕 [유형별 라우팅] 학부모 화면
import 'schedule/general_planner_home_screen.dart'; // 🆕 [유형별 라우팅] 일반 사용자 화면
import 'package:gsu_studyup/global_lang.dart';
import 'services/timer2_services.dart';
import 'services/auth_service.dart'; // 🆕 [실제 로그인/회원가입]
import 'services/user_profile_service.dart'; // 🆕 [유형별 라우팅] 가입 시 저장한 회원 유형 조회
import 'services/family_link_service.dart'; // 🆕 [부모-자녀 응원 시스템] 이모지/응원문구 실시간 수신
import 'timer/timer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화 (학생-부모 기기 연결용 서버 연결)
  await Firebase.initializeApp();

  // 웹에서는 포그라운드 태스크 초기화 건너뛰기
  if (!kIsWeb) {
    FlutterForegroundTask.initCommunicationPort();
  }

  await DkeLang.initialize();

  // 알림 서비스도 웹에서는 스킵
  if (!kIsWeb) {
    await Timer2Service.initialize();

    Timer2Service.onNotificationStartTapped = (data) {
      Timer2Service.navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => TimerScreen(
            selectedSubject: data['task'] ?? '학습',
            selectedDurationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 30,
            dynamicTestTitle: data['examTitle'] ?? '',
            targetExamDate: null,
            targetExamEndDate: null,
            prepPeriodStr: '',
            needTimelineGen: false,
            selectedSoundFile: '',
            isFinalExamMode: data['examTitle'] == '기말고사',
          ),
        ),
      );
    };
  }

  // 🆕 [부모-자녀 응원 시스템 2026-09-04] 앱의 핵심 취지 - 학생이 어떤 화면에 있든
  // (과목 설정 중이든, 홈 화면이든, 플래너를 보든) 부모가 보낸 이모지/응원문구가
  // 최우선으로 나타나야 하므로, 개별 화면이 아니라 앱 전체 최상단에서 감시를 시작합니다.
  // 답장 기능은 의도적으로 넣지 않습니다(학습 방해 요소를 없애기 위함).
  if (!kIsWeb) {
    ParentEncouragementManager.start();
  }

  runApp(const GsuStudyUpApp());
}

// ============================================================================
// 🆕 [부모-자녀 응원 시스템 2026-09-04] 앱 전체 최상단에서 딱 한 번만 동작하는
// 전역 관리자. 개별 화면(timer_screen.dart 등)에는 이 로직을 절대 중복으로 넣지
// 않습니다 - 화면이 여러 개 동시에 감시하면 팝업이 중복으로 뜨는 문제가 생깁니다.
//
// [동작 원리]
// - Firebase Auth의 로그인 상태 변화를 감지해서, 로그인될 때마다(=학생이 로그인한
//   기기라면) 그 계정의 연결 코드 문서(links/{code})를 실시간 구독합니다.
// - pendingEmoji/pendingMessage 필드가 채워지면, Timer2Service.navigatorKey를 통해
//   "현재 어떤 화면이 떠 있든" 그 위에 오버레이(이모지)/다이얼로그(응원문구)를 띄웁니다.
//   navigatorKey는 main.dart의 MaterialApp에 이미 연결되어 있어서, 특정 화면의
//   BuildContext 없이도 전역에서 화면 위에 뭔가를 띄울 수 있게 해줍니다.
// - 로그아웃하면 구독을 정리하고, 다시 로그인하면 새 계정 기준으로 다시 시작합니다.
// ============================================================================
class ParentEncouragementManager {
  ParentEncouragementManager._();

  static StreamSubscription<User?>? _authSub;
  static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _linkSub;
  static OverlayEntry? _emojiOverlayEntry;
  static bool _isEmojiShowing = false;
  static bool _isMessageShowing = false;

  static void start() {
    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _linkSub?.cancel();
      _linkSub = null;
      _removeEmojiOverlay();
      _isMessageShowing = false;

      if (user == null) return; // 로그아웃 상태면 감시할 대상 없음
      _subscribeToMyLinkDoc();
    });
  }

  static Future<void> _subscribeToMyLinkDoc() async {
    final String? code = await FamilyLinkService.getMyLinkCode();
    if (code == null) return; // 아직 부모와 연결 안 된 계정(학생이 아니거나 미연결)이면 조용히 넘어감

    _linkSub = FamilyLinkService.watch(code).listen((snapshot) {
      if (!snapshot.exists) return;
      final Map<String, dynamic>? data = snapshot.data();
      if (data == null) return;

      final Map<String, dynamic>? emojiData = data['pendingEmoji'] != null
          ? Map<String, dynamic>.from(data['pendingEmoji'] as Map)
          : null;
      if (emojiData != null && !_isEmojiShowing) {
        _showEmojiOverlay(emojiData);
      }

      final Map<String, dynamic>? messageData = data['pendingMessage'] != null
          ? Map<String, dynamic>.from(data['pendingMessage'] as Map)
          : null;
      if (messageData != null && !_isMessageShowing) {
        _showEncouragementDialog(messageData['text'] as String? ?? '');
      }
    });
  }

  // 🆕 [부모-자녀 응원 시스템] 이모지 - 현재 화면이 무엇이든 그 위에 떠 있는 카드로 표시.
  // "확인"을 누르기 전까지 화면 전환을 해도 계속 남아있습니다(Overlay는 Navigator 스택
  // 전체 위에 그려지므로 라우트가 바뀌어도 사라지지 않음).
  static void _showEmojiOverlay(Map<String, dynamic> emojiData) {
    final OverlayState? overlay = Timer2Service.navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _isEmojiShowing = true;
    const Color brandGolden = Color(0xFFE5C158);
    final String emoji = emojiData['emoji'] as String? ?? '💛';
    final String message = emojiData['message'] as String? ?? '';

    _emojiOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF11192E), Color(0xFF0A0F1E)]),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: brandGolden.withOpacity(0.6), width: 1.3),
              boxShadow: [
                BoxShadow(color: brandGolden.withOpacity(0.25), blurRadius: 22, spreadRadius: 1),
                const BoxShadow(color: Colors.black, blurRadius: 16, offset: Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _acknowledgeEmoji,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(color: brandGolden, borderRadius: BorderRadius.circular(10)),
                    child: Text('확인', style: GoogleFonts.notoSansKr(color: const Color(0xFF030712), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(_emojiOverlayEntry!);
  }

  static Future<void> _acknowledgeEmoji() async {
    _removeEmojiOverlay();
    await FamilyLinkService.clearPendingEmoji();
  }

  static void _removeEmojiOverlay() {
    _emojiOverlayEntry?.remove();
    _emojiOverlayEntry = null;
    _isEmojiShowing = false;
  }

  // 🆕 [부모-자녀 응원 시스템] 응원 문구 - navigatorKey의 context로 다이얼로그를 띄우면,
  // 현재 화면이 어디든 그 위에 모달로 나타납니다. 답장 입력창은 넣지 않습니다.
  static Future<void> _showEncouragementDialog(String message) async {
    if (message.trim().isEmpty) return;
    final BuildContext? context = Timer2Service.navigatorKey.currentState?.overlay?.context;
    if (context == null) return;

    _isMessageShowing = true;
    const Color brandGolden = Color(0xFFE5C158);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF11192E), Color(0xFF0A0F1E)]),
            border: Border.all(color: brandGolden.withOpacity(0.6), width: 1.3),
            boxShadow: [
              BoxShadow(color: brandGolden.withOpacity(0.2), blurRadius: 30, spreadRadius: 1),
              const BoxShadow(color: Colors.black, blurRadius: 20, offset: Offset(0, 8)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(26, 30, 26, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_rounded, color: brandGolden, size: 32),
              const SizedBox(height: 14),
              Text('부모님의 응원', style: GoogleFonts.notoSansKr(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14.5, height: 1.6, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGolden,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('힘낼게요!', style: GoogleFonts.notoSansKr(color: const Color(0xFF030712), fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    _isMessageShowing = false;
    await FamilyLinkService.clearPendingMessage();
  }
}

class GsuStudyUpApp extends StatelessWidget {
  const GsuStudyUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: Timer2Service.navigatorKey, // ← 이 줄만 추가
      title: 'GSU StudyUp',
      debugShowCheckedModeBanner: false,
      // 🆕 [한국어 달력 등 시스템 위젯 현지화] 생년월일 선택 달력 등이 영어 대신 한국어로 표시되도록 등록
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
      ],
      locale: const Locale('ko'), // 기본 로케일 한국어
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
// [1] 메인 입장 화면 (지구본 정중앙 순차 줌인/아웃 애니메이션 결합판)
// 🆕 [12개국 다국어 연동] 2026-07-29 수정:
//   - 브랜드명 "GKE StudyUp"은 조사 없이 모든 언어 공통으로 고정 표시 (번역 대상 아님)
//   - 기본(언어 미선택 = EN+KO) 모드: GKE StudyUp → 응원 합니다(한글) → We're Cheering for You!(영문) 3단계 반복
//   - 10개국어(JA/ZH/FR/DE/RU/AR/HI/VI/ES/TH) 중 하나 선택 시: GKE StudyUp → 해당 언어 응원 문구 2단계 반복
//   - 각 단계의 줌인(1/3)-정지(1/3)-줌아웃(1/3) 3초씩 리듬은 원본과 완전히 동일하게 유지 (폰트크기/색상/레이아웃 불변)
// -----------------------------------------
class EntranceScreen extends StatefulWidget {
  const EntranceScreen({super.key});

  @override
  State<EntranceScreen> createState() => _EntranceScreenState();
}

class _EntranceScreenState extends State<EntranceScreen> with TickerProviderStateMixin {

  // 👑 [명칭: 대문 지구본 응원 애니메이션 제어 엔진]
  late AnimationController _cheeringController;

  // 🆕 [12개국 다국어 연동] 단계별(브랜드/응원문구) 텍스트·스타일·애니메이션을 가변 개수로 관리
  late int _totalStages;
  late List<String> _stageTexts;
  late List<TextStyle> _stageStyles;
  late List<Animation<double>> _stageScales;
  late List<Animation<double>> _stageOpacities;

  // 🆕 [12개국 다국어 연동] 10개국어 목록 (기존 study_timeline_section.dart 등과 동일한 코드 체계)
  static const List<String> _foreignLanguages = ['JA', 'ZH', 'FR', 'DE', 'RU', 'AR', 'HI', 'VI', 'ES', 'TH'];
  static bool get _isForeignSelected => _foreignLanguages.contains(DkeLang.current);

  // 🆕 [12개국 다국어 연동] 브랜드명은 조사 없이 모든 언어 공통 고정
  static const String _brandText = 'GKE StudyUp';

  // 🆕 [12개국 다국어 연동] 응원 문구 - 기본(EN+KO) 모드용 한글/영문, 10개국어용 번역
  static const String _cheerKo = '응원 합니다';
  static const String _cheerEn = "We're Cheering for You!";
  static const Map<String, String> _cheerForeign = {
    'JA': '応援しています！',
    'ZH': '我们支持你！',
    'FR': 'Nous vous encourageons !',
    'DE': 'Wir drücken dir die Daumen!',
    'RU': 'Мы болеем за тебя!',
    'AR': 'نحن ندعمك!',
    'HI': 'हम आपका समर्थन करते हैं!',
    'VI': 'Chúng tôi cổ vũ cho bạn!',
    'ES': '¡Te apoyamos!',
    'TH': 'เราเป็นกำลังใจให้คุณ!',
  };

  @override
  void initState() {
    super.initState();

    const Color brandGolden = Color(0xFFE5C158);

    final bool foreignMode = _isForeignSelected;
    _totalStages = foreignMode ? 2 : 3;

    _stageTexts = [];
    _stageStyles = [];

    // 1단계: 브랜드명 (모든 언어 공통, 원본의 두꺼운 5중 그림자 스타일 완전 동일 유지)
    _stageTexts.add(_brandText);
    _stageStyles.add(GoogleFonts.nanumMyeongjo(
      color: brandGolden,
      fontSize: 23,
      fontWeight: FontWeight.w900,
      shadows: [
        Shadow(color: Colors.black, blurRadius: 2, offset: const Offset(-1.5, -1.5)),
        Shadow(color: Colors.black, blurRadius: 2, offset: const Offset(1.5, -1.5)),
        Shadow(color: Colors.black, blurRadius: 2, offset: const Offset(1.5, 1.5)),
        Shadow(color: Colors.black, blurRadius: 2, offset: const Offset(-1.5, 1.5)),
        Shadow(color: Colors.black87, blurRadius: 20, offset: const Offset(4, 4)),
      ],
    ));

    // 나머지 단계: 응원 문구 (원본의 단일 그림자 스타일, 폰트크기 23, 굵게, 황금색 완전 동일 유지)
    final TextStyle cheerBaseStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 23,
      color: brandGolden,
      shadows: const [Shadow(color: Colors.black87, blurRadius: 15, offset: Offset(2, 2))],
    );

    if (foreignMode) {
      final String cheerText = _cheerForeign[DkeLang.current] ?? _cheerEn;
      _stageTexts.add(cheerText);
      _stageStyles.add(GoogleFonts.notoSans(textStyle: cheerBaseStyle));
    } else {
      _stageTexts.add(_cheerKo);
      _stageStyles.add(GoogleFonts.notoSansKr(textStyle: cheerBaseStyle));
      _stageTexts.add(_cheerEn);
      _stageStyles.add(GoogleFonts.notoSerif(textStyle: cheerBaseStyle));
    }

    // ⏳ [명칭: 단계별 체인 타임라인 제어기] - 단계 하나당 9초(3초 줌인+3초 정지+3초 줌아웃),
    // 전체 길이는 (9초 × 단계 수)로 자동 확장/축소됨 (기존 2단계=18초 리듬은 완전히 그대로 유지)
    _cheeringController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 9 * _totalStages),
    );

    _stageScales = [];
    _stageOpacities = [];
    for (int i = 0; i < _totalStages; i++) {
      _stageScales.add(_buildSlotScale(i, _totalStages));
      _stageOpacities.add(_buildSlotOpacity(i, _totalStages));
    }

    // ⚡ [명칭: 진입 정각 즉시 가동 스케줄러] - 폰 아이콘 누르자마자 0초 만에 시동 거는 트리거
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _cheeringController.forward(from: 0.0);
        _cheeringController.repeat();
      }
    });
  }

  // 🆕 [12개국 다국어 연동] 전체 타임라인을 단계 수(totalSlots)만큼 균등 분할하고,
  // 각 단계 구간 안에서 원본과 동일하게 줌인(1/3)-정지(1/3)-줌아웃(1/3) 패턴을 적용하는 스케일 애니메이션 생성기.
  // 기존 2단계(18초, 9초씩) 구조와 완전히 동일한 리듬을 유지하면서 단계 수만 가변으로 늘릴 수 있도록 일반화함.
  Animation<double> _buildSlotScale(int slotIndex, int totalSlots) {
    final double slotWeight = 100.0 / totalSlots;
    final double third = slotWeight / 3;
    final double before = slotWeight * slotIndex;
    final double after = 100.0 - before - slotWeight;

    final List<TweenSequenceItem<double>> items = [];
    if (before > 0.01) items.add(TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: before));
    items.add(TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic)), weight: third));
    items.add(TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: third));
    items.add(TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInCubic)), weight: third));
    if (after > 0.01) items.add(TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: after));

    return TweenSequence<double>(items).animate(_cheeringController);
  }

  // 🆕 [12개국 다국어 연동] 위와 동일한 구간 분할로 투명도(디졸브) 애니메이션 생성 (원본 로직과 동일한 페이드 형태)
  Animation<double> _buildSlotOpacity(int slotIndex, int totalSlots) {
    final double slotWeight = 100.0 / totalSlots;
    final double third = slotWeight / 3;
    final double before = slotWeight * slotIndex;
    final double after = 100.0 - before - slotWeight;

    final List<TweenSequenceItem<double>> items = [];
    if (before > 0.01) items.add(TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: before));
    items.add(TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: third));
    items.add(TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: third));
    items.add(TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: third));
    if (after > 0.01) items.add(TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: after));

    return TweenSequence<double>(items).animate(_cheeringController);
  }

  @override
  void dispose() {
    _cheeringController.dispose(); // 👑 [역할: 자원 해제] 백그라운드 스레드 유령 구동 완전 차단
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  // 🆕 [12개국 다국어 연동] 단계 수(_totalStages)만큼 자막을 동적으로 생성 (레이아웃/스타일 구조는 원본 그대로)
                  children: List.generate(_totalStages, (i) {
                    return FadeTransition(
                      opacity: _stageOpacities[i],
                      child: ScaleTransition(
                        scale: _stageScales[i],
                        child: Text(
                          _stageTexts[i],
                          textAlign: TextAlign.center,
                          style: _stageStyles[i],
                        ),
                      ),
                    );
                  }),
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
// [2] 회원가입 / 로그인 화면 (체크박스 상태 유지를 위해 StatefulWidget으로 완벽 세공 및 승격)
// 🆕 [12개국 다국어 연동] 2026-07-29 수정: 태그라인/입력힌트/기억하기문구/버튼/환영오버레이
//   총 6곳을 DkeLang 게터로 교체. 디자인/레이아웃/색상/폰트/크기는 100% 원본 동일 유지.
// -----------------------------------------
class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  // 🗺️ [선배님 지시: 로그인 전용 계정 기억하기 단일 상태 레버 변수 안착]
  bool _isRememberMeChecked = false;

  // 🆕 [실제 로그인 연결] 이메일/비밀번호 입력값을 실제로 붙잡아두는 컨트롤러
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  bool _isLoggingIn = false;

  // 🆕 [실제 로그인 연결] 이메일/비밀번호를 Firebase Authentication으로 실제 검증
  Future<void> _handleSignIn(BuildContext context) async {
    if (_isLoggingIn) return;
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일과 비밀번호를 입력해주세요.')),
      );
      return;
    }
    setState(() => _isLoggingIn = true);
    try {
      await AuthService.signIn(email: email, password: password);
      if (!mounted) return;

      // 🆕 [이메일 인증 필수화] 인증 안 된 계정은 여기서 막고, 대시보드로 못 들어가게 함
      final bool verified = await AuthService.isEmailVerified();
      if (!verified) {
        if (!mounted) return;
        await _showEmailVerificationRequiredDialog(email);
        setState(() => _isLoggingIn = false);
        return; // 인증 전에는 절대 다음 화면으로 안 보냄
      }

      // 🆕 [유형별 라우팅] 가입할 때 저장해둔 회원 유형(학생/학부모/일반)에 따라 다른 화면으로 이동
      final String? userType = await DkeUserProfile.getUserType();
      if (!mounted) return;

      if (userType == '학부모') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ParentMainDashboardScreen(
              parentEmail: email,
              childName: '', // 🆕 대시보드 내부에서 실제 연결된 자녀 목록을 직접 불러오도록 추후 개선 예정
            ),
          ),
        );
      } else if (userType == '일반') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GeneralPlannerHomeScreen()),
        );
      } else {
        // 기본값(학생 또는 유형 정보 없음)은 기존과 동일하게 학생용 대시보드로
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
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  // 🆕 [이메일 인증 필수화] 인증 안 된 계정으로 로그인 시도했을 때 보여주는 안내창
  Future<void> _showEmailVerificationRequiredDialog(String email) async {
    bool isResending = false;
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFF0D1527),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('이메일 인증이 필요합니다', style: TextStyle(color: Color(0xFFE5C158), fontWeight: FontWeight.bold)),
            content: Text(
              '$email 주소로 보낸 인증 메일의 링크를 눌러주세요.\n\n인증을 완료하신 뒤, 이 창을 닫고 다시 "SIGN IN" 버튼을 눌러주세요.',
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: isResending
                    ? null
                    : () async {
                  setDialogState(() => isResending = true);
                  try {
                    await AuthService.sendVerificationEmail();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('인증 메일을 다시 보냈습니다. 메일함(스팸함 포함)을 확인해주세요.')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  } finally {
                    setDialogState(() => isResending = false);
                  }
                },
                child: Text(isResending ? '발송 중...' : '인증 메일 재발송', style: const TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5C158)),
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('확인', style: TextStyle(color: Color(0xFF030712), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

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
                    DkeLang.loginTagline, // 🆕 [12개국 다국어] 원문: '노력하는 너를 응원하는 별이 되어 줄게'
                    textAlign: TextAlign.center,
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
                    hintText: DkeLang.emailHint, // 🆕 [12개국 다국어] 원문: 'Email Address'
                    icon: Icons.mail_outline_rounded,
                    controller: _loginEmailController,
                  ),
                  const SizedBox(height: 15),
                  _buildCustomTextField(
                    hintText: DkeLang.passwordHint, // 🆕 [12개국 다국어] 원문: 'Password'
                    icon: Icons.lock_outline,
                    isPassword: true,
                    controller: _loginPasswordController,
                  ),

                  // 📐 기존 45 간격을 네모 박스 배치를 위해 슬림하게 10으로 축소 조율
                  const SizedBox(height: 10),

                  // ============================================================================
                  // 🗺️ SECTION: LOGIN REMEMBER ME CHECKBOX (선배님 지시: 이메일 / 패스워드 기억하기 박스 구현)
                  // ============================================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start, // 폰 화면 좌측 정렬 단속
                    children: [
                      Checkbox(
                        value: _isRememberMeChecked, // 🚨 파일 최상단에 선언된 정품 변수 연동
                        activeColor: const Color(0xFFE5C158), // 시그니처 프리미엄 황금색 테마 일치화
                        checkColor: const Color(0xFF030712),  // 체크 표시 색상 (뒷배경과 동일한 다크 니트 톤)
                        side: const BorderSide(color: Colors.white38, width: 1.5), // 빈 박스일 때 테두리 색상
                        onChanged: (bool? value) {
                          // 🕹️ 클릭 시 네모 박스 실시간 토글 완벽 가동
                          setState(() {
                            _isRememberMeChecked = value ?? false;
                          });
                        },
                      ), // end of Checkbox

                      const SizedBox(width: 4), // 네모 박스와 글자 사이 미세 여백 단속

                      // 🆕 [오버플로우 방지] 2026-07-29 수정: Expanded로 남은 폭만큼만 차지하도록 제한하고,
                      // 넘치는 텍스트는 1줄 유지 + 말줄임표(...) 처리. 폰트/색상/크기는 원본과 100% 동일.
                      Expanded(
                        child: Text(
                          DkeLang.rememberMe, // 🆕 [12개국 다국어] 원문: "이메일 / 패스워드 기억하기"
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.gowunBatang( // 프로젝트 시그니처 서체 '고운바탕' 완벽 일치화
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ), // end of GoogleFonts
                        ), // end of Text
                      ), // end of Expanded
                    ], // end of Row children
                  ), // end of Row

                  const SizedBox(height: 25), // 📐 네모 박스와 아래 'CREATE ACCOUNT' 버튼 사이의 최적 황금 마진 확보
                  _buildGradientButton(
                    title: DkeLang.createAccountBtn, // 🆕 [12개국 다국어] 원문: 'CREATE ACCOUNT (회원가입)'
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildOutlineButton(
                    title: _isLoggingIn ? '로그인 중...' : DkeLang.signInBtn, // 🆕 [12개국 다국어] 원문: 'SIGN IN (로그인)'
                    onPressed: () => _handleSignIn(context),
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
    TextEditingController? controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1527),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis, // 🆕 [오버플로우 방지 2026-07-29]
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis, // 🆕 [오버플로우 방지 2026-07-29]
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
                      DkeLang.welcomeOverlay, // 🆕 [12개국 다국어] 원문: 'Welcome to GKE STUDYUP! (...)'
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
