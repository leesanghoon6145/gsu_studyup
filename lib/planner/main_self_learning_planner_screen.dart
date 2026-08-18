import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// 🆕 하위 서브 스크린 파일 인프라 정밀 바인딩 완수
import 'planning_screen.dart';
import 'learning_screen.dart';
import 'report_screen.dart';
import '../global_lang.dart'; // 👑 [12개국 연동] 전역 언어 스위치와 연결

/// GKE StudyUp 글로벌 하이엔드 자기주도 학습 플래너 총괄 컨트롤 타워
class MainSelfLearningPlannerScreen extends StatefulWidget {
  const MainSelfLearningPlannerScreen({Key? key}) : super(key: key);

  @override
  State<MainSelfLearningPlannerScreen> createState() => _MainSelfLearningPlannerScreenState();
}

class _MainSelfLearningPlannerScreenState extends State<MainSelfLearningPlannerScreen> with TickerProviderStateMixin {
  // ============================================================================
  // 🗺️ SECTION: 1. CORE CONTROLLER PROPERTY (핵심 제어 컨트롤러 정의 구역)
  // ============================================================================
  late TabController _tabController;

  // 지시사항 2, 3번: 접속 시 오늘 날짜 및 요일 자동 연동 및 오토 포커스 상태 관리
  late DateTime _todayDate;
  late DateTime _selectedDate;

  // 🆕 [2026-08-14] 계획 탭 ↔ 실행 탭이 같은 일정 데이터(gke_global_schedules)를 공유하므로,
  // 한쪽에서 수정한 뒤 다른 탭으로 돌아오면 최신 데이터로 새로고침되도록 GlobalKey로 연결함.
  final GlobalKey<PlanningScreenState> _planningKey = GlobalKey<PlanningScreenState>();
  final GlobalKey<LearningScreenState> _learningKey = GlobalKey<LearningScreenState>();
  // 🆕 [버그 수정 2026-08-18] 리포트 탭도 같은 데이터를 읽으므로 동일한 방식으로 새로고침 연결.
  // 지금까지 이 연결이 없어서 계획 탭에서 "완료 체크"를 눌러도 리포트에 반영이 안 됐음.
  final GlobalKey<ReportScreenState> _reportKey = GlobalKey<ReportScreenState>();

  final List<String> _todayMainSchedules = [];

  // ============================================================================
  // 🆕 [12개국 언어 시스템]
  // 기본값(마이페이지에서 12개국 중 하나를 고르기 전, 즉 DkeLang.current == 'KO' 상태 포함)은
  // 항상 "영문 + 한글"이 함께 보입니다 — 12개국에 없는 다른 나라 사용자도 영어로 볼 수 있게 하기 위함.
  // 한국어/영어를 "제외한" 나머지 10개국 중 하나를 선택했을 때만 그 언어 단독으로 전환됩니다.
  // ============================================================================
  static const List<String> _foreignLanguages = ['JA', 'ZH', 'FR', 'DE', 'RU', 'AR', 'HI', 'VI', 'ES', 'TH'];
  static bool get _isForeignSelected => _foreignLanguages.contains(DkeLang.current);

  static const Map<String, Map<String, String>> _uiText = {
    'plannerTitle': {'KO': '자기주도 플래너', 'EN': 'Self-Directed Planner', 'JA': '自己主導プランナー', 'ZH': '自主学习规划', 'FR': 'Planificateur autonome', 'DE': 'Selbstgesteuerter Planer', 'RU': 'Планировщик самообучения', 'AR': 'مخطط التعلم الذاتي', 'HI': 'स्व-निर्देशित प्लानर', 'VI': 'Kế hoạch tự học', 'ES': 'Planificador autónomo', 'TH': 'แผนการเรียนด้วยตนเอง'},
    'tabPlanning': {'KO': '계획', 'EN': 'Planning', 'JA': '計画', 'ZH': '计划', 'FR': 'Planification', 'DE': 'Planung', 'RU': 'План', 'AR': 'التخطيط', 'HI': 'योजना', 'VI': 'Lập kế hoạch', 'ES': 'Planificación', 'TH': 'วางแผน'},
    'tabLearning': {'KO': '알람실행', 'EN': 'Alarm', 'JA': 'アラーム実行', 'ZH': '闹钟执行', 'FR': 'Alarme', 'DE': 'Alarm', 'RU': 'Будильник', 'AR': 'المنبه', 'HI': 'अलार्म', 'VI': 'Báo thức', 'ES': 'Alarma', 'TH': 'ปลุก'},
    'tabReport': {'KO': '리포트', 'EN': 'Report', 'JA': 'レポート', 'ZH': '报告', 'FR': 'Rapport', 'DE': 'Bericht', 'RU': 'Отчёт', 'AR': 'التقرير', 'HI': 'रिपोर्ट', 'VI': 'Báo cáo', 'ES': 'Informe', 'TH': 'รายงาน'},
  };

  static String _foreignOnly(String key) {
    final map = _uiText[key]!;
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? key;
  }

  // 🆕 제목형 위젯에서 사용: 기본값 = 영문(위) + 한글(아래) 2줄, 10개국 선택 시 = 단일 언어 1줄
  static Widget _biTitle(
      String key, {
        required TextStyle enStyle,
        required TextStyle koStyle,
        TextStyle? foreignStyle,
        TextAlign? textAlign,
      }) {
    if (_isForeignSelected) {
      return Text(
        _foreignOnly(key),
        textAlign: textAlign,
        overflow: TextOverflow.fade,
        softWrap: false,
        maxLines: 1,
        style: foreignStyle ?? koStyle,
      );
    }
    final map = _uiText[key]!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(map['EN']!, textAlign: textAlign, overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: enStyle),
        Text(map['KO']!, textAlign: textAlign, overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: koStyle),
      ],
    );
  }

  // 🆕 [12개국 요일 약어] 요일 인덱스(1=월요일 ~ 7=일요일) 기준 조회 — 나머지 10개국 선택 시 단독 표시용
  static const Map<String, List<String>> _weekdayShortForeign = {
    'JA': ['月', '火', '水', '木', '金', '土', '日'],
    'ZH': ['一', '二', '三', '四', '五', '六', '日'],
    'FR': ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'],
    'DE': ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'],
    'RU': ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'],
    'AR': ['اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'],
    'HI': ['सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'रवि'],
    'VI': ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'],
    'ES': ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'],
    'TH': ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'],
  };
  // 🆕 [12개국] 기본값(영+한)용 고정 배열 — 항상 월요일 시작
  static const List<String> _weekdayShortEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const List<String> _weekdayShortKo = ['월', '화', '수', '목', '금', '토', '일'];

  // 🆕 [12개국] 기본값 = "Mon / 월", 10개국 선택 시 = 단일 언어 요일 약어
  static String _weekdayLabel(int weekdayIndex1to7) {
    final idx = weekdayIndex1to7 - 1;
    if (_isForeignSelected) {
      final list = _weekdayShortForeign[DkeLang.current] ?? _weekdayShortEn;
      return list[idx];
    }
    return '${_weekdayShortEn[idx]} / ${_weekdayShortKo[idx]}';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // 현재 UTC/KST 기준 오늘 날짜 자동 할당 (지시사항 2, 3번)
    final now = DateTime.now();
    _todayDate = DateTime(now.year, now.month, now.day);
    _selectedDate = _todayDate; // 접속 시 자동으로 오늘 날짜에 선택 표시

    // 🆕 [2026-08-14] 계획(0)/실행(1) 탭이 같은 일정 데이터를 공유하므로, 탭을 전환해서 그
    // 화면으로 돌아올 때마다 최신 데이터로 새로고침함 (한쪽에서 추가한 일정이 다른 쪽에도
    // 바로 보이도록).
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 0) {
          _planningKey.currentState?.refreshFromExternalChanges();
        } else if (_tabController.index == 1) {
          _learningKey.currentState?.refreshSchedules();
        } else if (_tabController.index == 2) {
          // 🆕 [버그 수정 2026-08-18] 리포트 탭으로 돌아올 때마다 최신 완료 체크 상태를 다시 읽어옴
          _reportKey.currentState?.refreshFromExternalChanges();
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ============================================================================
  // 🗺️ SECTION: 2. GLOBAL BRAND COLOR SETTING (시그니처 테마 정의 구역)
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    const Color brandDarkBg = Color(0xFF070B14);
    const Color brandGolden = Color(0xFFE5C158);

    // [수정] build 시작 부분에 요일 매핑 배치 (에러 원천 차단)
    // 🆕 [12개국] 기본값 = "Mon / 월" 조합, 10개국 선택 시 = 단일 언어 요일 약어
    String currentWeekdayStr = _weekdayLabel(_selectedDate.weekday);

    return Scaffold(
      backgroundColor: brandDarkBg,

      // ============================================================================
      // 🗺️ SECTION: 3. CENTERED APP BAR HEADER (선배님 지시: 황금색 통일 및 좌우 센터 배치 구역)
      // ============================================================================
      appBar: AppBar(
        backgroundColor: brandDarkBg,
        elevation: 0,
        toolbarHeight: 120, // 📐 센터링 타이포그래피 가독성을 위한 최적 뷰포트 높이 고정
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ), // end of leading

        // 🎯 [정중앙 정렬 수칙] 타이틀 전체를 상단바 좌우 센터에 완벽 강제 배치
        centerTitle: true,

        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center, // 수직 정렬 축도 센터로 일치
          children: [
            // 🖼️ [로고 여백 대칭 수칙] 가로는 늘리되 세로 확대 절대 금지
            Container(
              width: 210, // 📐 아래 타이틀 전체 폭과 정확히 일치화
              padding: const EdgeInsets.symmetric(horizontal: 2), // ⚖️ 좌우 동일 여백 밸런스 단속
              child: Image.asset(
                'assets/images/gsu_logo.png',
                height: 16, // 🚨 세로 크기 슬림 고정 (가로세로 동시확대 절대 금지 수칙 엄수)
                fit: BoxFit.fill, // 가로 대칭 폭에 맞춰 이미지를 자연스럽게 스트레치
              ), // end of Image.asset
            ), // end of Container

            const SizedBox(height: 4), // 📏 로고와 타이틀 사이 여백

            // 🆕 [12개국] 기본값 = 영문(위)+한글(아래) 2단, 10개국 선택 시 = 단일 언어
            // 🆕 [버그 수정 2026-08-10] 지시사항: "자기주도 플래너" 글씨가 너무 진하지 않게,
            // 영문 글자크기 15 / 한글 글자크기 14로 조정. 기존 한글 fontSize 23 / FontWeight.w900
            // (가장 굵은 값)을 fontSize 14 / FontWeight.w600(중간 굵기)으로 낮춤.
            // 🆕 [2026-08-18] 원장님 지시: 타이틀 글자 크기 3만큼 확대 (영문 15→18, 한글 14→17)
            SizedBox(
              width: 210,
              child: _biTitle(
                'plannerTitle',
                textAlign: TextAlign.center,
                enStyle: GoogleFonts.notoSans(color: brandGolden, fontSize: 18, fontWeight: FontWeight.w600),
                koStyle: GoogleFonts.notoSans(color: brandGolden, fontSize: 17, fontWeight: FontWeight.w600),
                foreignStyle: GoogleFonts.notoSans(color: brandGolden, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ], // end of title children
        ), // end of Column
      ), // end of appBar

      // ============================================================================
      // 🗺️ SECTION: 4. MAIN CENTRAL VIEWPORT (중앙 독립 3대 서브 레이어 뷰포트)
      // ============================================================================
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1단계: 필수 파라미터와 함께 구동되는  계획 레이어
          PlanningScreen(
            key: _planningKey,
            selectedDate: _selectedDate,
            currentWeekday: currentWeekdayStr,
            mainSchedules: _todayMainSchedules,
            onDateTap: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),
          // 2단계:  실행 레이어
          LearningScreen(key: _learningKey),
          // 3단계:  리포트 레이어
          ReportScreen(key: _reportKey),
        ],
      ),

      // ============================================================================
      // 🗺️ SECTION: 5. BOTTOM NAVIGATION TAB BAR (하단 안착 메뉴 탭바 구역)
      // ============================================================================
      bottomNavigationBar: Container(
        color: brandDarkBg,
        padding: const EdgeInsets.only(bottom: 10), // 🛠️ 앞서 정밀 디버깅 완료한 문법 수칙 적용
        child: TabBar(
          controller: _tabController,
          indicatorColor: brandGolden, // 활성화 바 황금빛 매핑
          indicatorWeight: 3,
          labelColor: brandGolden,
          unselectedLabelColor: Colors.grey.shade500,
          // 🆕 [12개국] 기본값 = 영문+한글 2단, 10개국 선택 시 = 단일 언어
          tabs: [
            Tab(
              child: _biTitle(
                'tabPlanning',
                enStyle: GoogleFonts.notoSans(fontSize: 9, fontWeight: FontWeight.bold),
                koStyle: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.bold),
                foreignStyle: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ), // end of PLANNING Tab
            Tab(
              child: _biTitle(
                'tabLearning',
                enStyle: GoogleFonts.notoSans(fontSize: 9, fontWeight: FontWeight.bold),
                koStyle: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.bold),
                foreignStyle: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ), // end of LEARNING Tab
            Tab(
              child: _biTitle(
                'tabReport',
                enStyle: GoogleFonts.notoSans(fontSize: 9, fontWeight: FontWeight.bold),
                koStyle: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.bold),
                foreignStyle: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ), // end of REPORT Tab
          ], // end of TabBar tabs
        ), // end of TabBar
      ), // end of bottomNavigationBar Container
    ); // end of Scaffold
  } // end of build
}
