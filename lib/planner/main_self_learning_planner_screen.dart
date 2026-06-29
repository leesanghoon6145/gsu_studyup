import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// 🆕 하위 서브 스크린 파일 인프라 정밀 바인딩 완수
import 'planning_screen.dart';
import 'learning_screen.dart';
import 'report_screen.dart';

/// GKE StudyUp 글로벌 하이엔드 자기주도 학습 플래너 총괄 컨트롤 타워
class MainSelfLearningPlannerScreen extends StatefulWidget {
  const MainSelfLearningPlannerScreen({Key? key}) : super(key: key);

  @override
  State<MainSelfLearningPlannerScreen> createState() => _MainSelfLearningPlannerScreenState();
}

class _MainSelfLearningPlannerScreenState extends State<MainSelfLearningPlannerScreen> with SingleTickerProviderStateMixin {
  // ============================================================================
  // 🗺️ SECTION: 1. CORE CONTROLLER PROPERTY (핵심 제어 컨트롤러 정의 구역)
  // ============================================================================
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ============================================================================
    // 🗺️ SECTION: 2. GLOBAL BRAND COLOR SETTING (시그니처 테마 정의 구역)
    // ============================================================================
    const Color brandDarkBg = Color(0xFF070B14); // 프리미엄 다크 니트 베이스
    const Color brandGolden = Color(0xFFE5C158); // 👑 선배님 지시: 모든 타이틀 통합 황금색

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

        // 🎯 [정중앙 정렬 수칙] 영문/한글 타이틀 전체를 상단바 좌우 센터에 완벽 강제 배치
        centerTitle: true,

        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center, // 수직 정렬 축도 센터로 일치
          children: [
            // 🖼️ [로고 여백 대칭 수칙] 가로는 늘리되 세로 확대 절대 금지
            // 영문 'S' 이전의 좌측 여백과 'R' 이후의 우측 여백을 평형 저울처럼 완벽 대칭 세공
            Container(
              width: 210, // 📐 아래 영문 23크기 'SELF~PLANNER' 전체 폭과 정확히 일치화
              padding: const EdgeInsets.symmetric(horizontal: 2), // ⚖️ 좌우 동일 여백 밸런스 단속
              child: Image.asset(
                'assets/images/gsu_logo.png',
                height: 16, // 🚨 세로 크기 슬림 고정 (가로세로 동시확대 절대 금지 수칙 엄수)
                fit: BoxFit.fill, // 가로 대칭 폭에 맞춰 이미지를 자연스럽게 스트레치
              ), // end of Image.asset
            ), // end of Container

            const SizedBox(height: 2), // 📏 로고와 영문 사이 0.1mm 단위 정밀 초밀착 압축 여백

            // 🔤 [영문 수칙] "SELF LEARNING PLANNER" 크기 23 고정 + 황금색 컬러 체인지 완수
            Text(
              "SELF LEARNING PLANNER",
              style: GoogleFonts.notoSerif(
                color: brandGolden, // 🚨 선배님 지시: 영문 타이틀 황금색 강제 전환
                fontSize: 21,       // 🚨 선배님 지시: 영문 글자 크기 23 유지
                fontWeight: FontWeight.w400,
                letterSpacing: -0.4, // 센터링 배열 시 자간 흐트러짐 미세 보정
              ), // end of GoogleFonts.notoSerif
            ), // end of Text

            const SizedBox(height: 1), // 📏 영문과 한글 사이 0.1mm 단위 초밀착 여백

            // 🇰🇷 [한글 수칙] 문구 변경 명세 수용 + 황금색 23크기 센터링 완전 이식
            Text(
              "자기주도 학습 계획", // 🚨 선배님 지시: "자기주도 학습 계획"으로 문구 최종 변경
              style: GoogleFonts.notoSansKr(
                color: brandGolden, // 🚨 선배님 지시: 한글 타이틀 황금색 유지
                fontSize: 23,       // 🚨 규격 크기 23 칼준수
                fontWeight: FontWeight.w900,
              ), // end of GoogleFonts.notoSansKr
            ), // end of Text
          ], // end of title children
        ), // end of Column
      ), // end of appBar

      // ============================================================================
      // 🗺️ SECTION: 4. MAIN CENTRAL VIEWPORT (중앙 독립 3대 서브 레이어 뷰포트)
      // ============================================================================
      body: TabBarView(
        controller: _tabController,
        children: const [
          PlanningScreen(), // 📅 1단계: 학습 계획 레이어
          LearningScreen(), // 📚 2단계: 학습 실행 레이어
          ReportScreen(),   // 📊 3단계: 학습 리포트 레이어
        ], // end of TabBarView children
      ), // end of body

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
          tabs: [
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("PLANNING", style: GoogleFonts.notoSerif(fontSize: 11, fontWeight: FontWeight.bold)),
                  Text("학습 계획", style: GoogleFonts.notoSansKr(fontSize: 11, fontWeight: FontWeight.w500)),
                ], // end of PLANNING tab children
              ), // end of Column
            ), // end of PLANNING Tab
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("LEARNING", style: GoogleFonts.notoSerif(fontSize: 11, fontWeight: FontWeight.bold)),
                  Text("학습 실행", style: GoogleFonts.notoSansKr(fontSize: 11, fontWeight: FontWeight.w500)),
                ], // end of LEARNING tab children
              ), // end of Column
            ), // end of LEARNING Tab
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("REPORT", style: GoogleFonts.notoSerif(fontSize: 11, fontWeight: FontWeight.bold)),
                  Text("학습 리포트", style: GoogleFonts.notoSansKr(fontSize: 11, fontWeight: FontWeight.w500)),
                ], // end of REPORT tab children
              ), // end of Column
            ), // end of REPORT Tab
          ], // end of TabBar tabs
        ), // end of TabBar
      ), // end of bottomNavigationBar Container
    ); // end of Scaffold
  } // end of build
}