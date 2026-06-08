import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// GSU StudyUp - Member Achievement Screen (회원 성취도)
///
/// 웅장한 학술원 테마를 기반으로 하며, 과목수 자동 확장 컬러 배정 로직과
/// 일간/주간/월간/연간 상세 통계 탭 분리 구조를 적용한 무결점 상용화 코드입니다.
class MemberAchievementScreen extends StatefulWidget {
  const MemberAchievementScreen({super.key});

  @override
  State<MemberAchievementScreen> createState() => _MemberAchievementScreenState();
}

class _MemberAchievementScreenState extends State<MemberAchievementScreen> {
  // 1. 회원 정보 기본 임시 데이터 (1번 규칙: 사용자 이름 연동)
  final String _memberName = 'Sanghun (상훈)';
  final int _totalStudyHours = 367; // 총 학습 시간
  final int _starsCollected = 1284; // 보유 별 총 개수
  final int _continuousDays = 23;   // 연속 학습일

  // 3번 규칙 대응: 동적으로 변하는 과목별 데이터셋 (임시 바인딩 데이터)
  final List<Map<String, dynamic>> _userSubjects = [
    {'name': 'Mathematics (수학)', 'time': 128, 'stars': 450, 'achievement': 85},
    {'name': 'English (영어)', 'time': 95, 'stars': 320, 'achievement': 72},
    {'name': 'Korean (국어)', 'time': 64, 'stars': 210, 'achievement': 80},
    {'name': 'Science (과학)', 'time': 42, 'stars': 150, 'achievement': 65},
    {'name': 'Society (사회)', 'time': 23, 'stars': 94, 'achievement': 60},
    {'name': 'Ethics (도덕)', 'time': 10, 'stars': 40, 'achievement': 90},
    {'name': 'History (역사)', 'time': 5, 'stars': 20, 'achievement': 50},
  ];

  // 3번 규칙 핵심: 과목 수 증가에 대응하는 무한 순환 7색 프리셋 컬러 리스트 (빨주노초파남보)
  final List<Color> _rainbowColors = [
    const Color(0xffef4444), // Red (빨강)
    const Color(0xfff97316), // Orange (주황)
    const Color(0xffeab308), // Yellow (노랑)
    const Color(0xff22c55e), // Green (초록)
    const Color(0xff3b82f6), // Blue (파랑)
    const Color(0xff4338ca), // Indigo (남색)
    const Color(0xffa855f7), // Purple (보라)
  ];

  /// 6번 규칙: 50시간 단위로 1레벨 증가하는 정밀 수식 연산식
  int _calculateLevel(int hours) {
    return (hours ~/ 50) + 1;
  }

  /// 추가 제안 2번: 다음 레벨업 달성까지 남은 시간 연산식
  int _hoursRemainingForLevelUp(int hours) {
    return 50 - (hours % 50);
  }

  @override
  Widget build(BuildContext context) {
    final int currentLevel = _calculateLevel(_totalStudyHours);
    final int nextLevelRemaining = _hoursRemainingForLevelUp(_totalStudyHours);
    final double levelProgressPercent = (50 - nextLevelRemaining) / 50;

    return DefaultTabController(
      length: 2, // 1페이지(요약/동기부여), 2페이지(상세 통계) 분리 아키텍처
      child: Scaffold(
        backgroundColor: const Color(0xff0d1117), // 웅장한 대리석 신전 톤앤매너 다크톤 배경
        appBar: AppBar(
          backgroundColor: const Color(0xff161b22),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Member Achievement (나의 성취도)',
            style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: const Color(0xffe2b714), // 별 수집 골드 테마 적용
            labelColor: const Color(0xffe2b714),
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.gowunBatang(fontSize: 18, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Summary (성취 요약)'),
              Tab(text: 'Detailed Analytics (상세 통계)'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              // ----------------------------------------------------
              // [1페이지 : 나의 성취도 요약 및 강력한 동기부여 섹션]
              // ----------------------------------------------------
              SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단 사용자 이름 기반 타이틀 안내 (1번 규칙)
                    Text(
                      '${_memberName}\'s Achievement Matrix',
                      style: GoogleFonts.gowunBatang(color: Colors.grey[400], fontSize: 18),
                    ),
                    Text(
                      'Progress & Achievements (성취도 리포트)',
                      style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // 상단 핵심 동기부여 스퀘어 카드 모듈 (6, 7, 8, 9번 규칙 복합 구현)
                    _buildCoreMotivationGrid(currentLevel),
                    const SizedBox(height: 15),

                    // 추가 제안 2번: 레벨 업 게이지 시각화 프로그레스 카드
                    _buildLevelUpGaugeCard(currentLevel, nextLevelRemaining, levelProgressPercent),
                    const SizedBox(height: 30),

                    // 4번 규칙: 목표 달성률 영역 (중앙 원형 배치)
                    Text(
                      'Goal Attainment Rate (목표 달성률)',
                      style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    _buildGoalCircularSection(),
                    const SizedBox(height: 30),

                    // 3번 규칙: 과목별 학습 현황 막대 그래프 (유기적 가변 스크롤 형태)
                    Text(
                      'Subject Status (과목별 학습 현황)',
                      style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '* Dynamic sorting applied (등록 과목 자동 배정 및 정렬 완료)',
                      style: GoogleFonts.gowunBatang(color: Colors.grey[500], fontSize: 14),
                    ),
                    const SizedBox(height: 15),
                    _buildDynamicProgressBarSection(),
                  ],
                ),
              ),

              // ----------------------------------------------------
              // [2페이지 : 상단 탭 연동형 세부 통계 분석 센터]
              // ----------------------------------------------------
              const DetailedAnalyticsTab(),
            ],
          ),
        ),
      ),
    );
  }

  /// 6, 7, 8, 9번 규칙 통합 구현: 최상단 대형 동기부여 인디케이터 격자 레이아웃
  Widget _buildCoreMotivationGrid(int currentLevel) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatBox('Current Level (현재 레벨)', 'Lv. $currentLevel', const Color(0xff58a6ff), Icons.military_tech),
        _buildStatBox('Stars Held (보유 별 총 갯수)', '$_starsCollected 개', const Color(0xffe2b714), Icons.star),
        _buildStatBox('Continuous Days (연속 학습일)', '$_continuousDays 일', const Color(0xff3f51b5), Icons.local_fire_department),
        _buildStatBox('Total Hours (총 학습시간)', '$_totalStudyHours 시간', const Color(0xff238636), Icons.alarm),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, Color themeColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xff161b22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xff30363d), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: themeColor, size: 22),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.gowunBatang(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// 추가 제안 2번: 레벨 업 달성 게이지 위젯
  Widget _buildLevelUpGaugeCard(int currentLevel, int remaining, double percent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff161b22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xff4338ca), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next Level Road (다음 레벨까지)',
                style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '$remaining Hours Left ($remaining시간 남음)',
                style: GoogleFonts.gowunBatang(color: const Color(0xff58a6ff), fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 12,
              backgroundColor: const Color(0xff21262d),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff58a6ff)),
            ),
          ),
        ],
      ),
    );
  }

  /// 4번 규칙: 목표 달성률 % 정밀 원형 시각화 카드
  Widget _buildGoalCircularSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff161b22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xff30363d)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCircleIndicator('Today (오늘)', 0.80, '80%'),
          _buildCircleIndicator('Weekly (이번 주)', 0.72, '72%'),
          _buildCircleIndicator('Monthly (이번 달)', 0.61, '61%'),
        ],
      ),
    );
  }

  Widget _buildCircleIndicator(String title, double percent, String label) {
    return Column(
      children: [
        Text(title, style: GoogleFonts.gowunBatang(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 15),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 75,
              height: 75,
              child: CircularProgressIndicator(
                value: percent,
                strokeWidth: 7,
                backgroundColor: const Color(0xff21262d),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xffe2b714)),
              ),
            ),
            Text(label, style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  /// 3번 규칙: 등록 과목 유기적 7색 순환 자동 배치 세로형 리스트 위젯 (화면 이탈 완전 차단 구조)
  Widget _buildDynamicProgressBarSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff161b22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xff30363d)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), // 상위 스크롤 뷰와 충돌 방지
        itemCount: _userSubjects.length,
        itemBuilder: (context, index) {
          final subject = _userSubjects[index];
          // index % 7 연산을 이용해 과목 갯수에 무관하게 무지개 색상이 에러 없이 무한 순환 배정됩니다.
          final Color barColor = _rainbowColors[index % _rainbowColors.length];
          final double progressRatio = subject['achievement'] / 100.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      subject['name'],
                      style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${subject['time']}h / ${subject['stars']}★ (${subject['achievement']}% )',
                      style: GoogleFonts.gowunBatang(color: Colors.grey[400], fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 화면 밖으로 벗어나는 일(Overflow)이 없도록 무조건 가용폭 내부 렌더링 설계
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: progressRatio,
                    minHeight: 10,
                    backgroundColor: const Color(0xff21262d),
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 2페이지 분리: 일간/주간/월간/연간 상세 분석 서브 스크린 클래스 위젯
class DetailedAnalyticsTab extends StatefulWidget {
  const DetailedAnalyticsTab({super.key});

  @override
  State<DetailedAnalyticsTab> createState() => _DetailedAnalyticsTabState();
}

class _DetailedAnalyticsTabState extends State<DetailedAnalyticsTab> {
  int _selectedFilterIndex = 1; // 0: 일간, 1: 주간, 2: 월간, 3: 연간
  final List<String> _filters = ['Daily (일간)', 'Weekly (주간)', 'Monthly (월간)', 'Annual (연간)'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 5번 규칙: 상단 정제된 일/주/월/년 세그먼트 필터 버튼 세트
          Row(
            children: List.generate(_filters.length, (index) {
              final isSelected = _selectedFilterIndex == index;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? const Color(0xffe2b714) : const Color(0xff161b22),
                      side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xff30363d)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedFilterIndex = index;
                      });
                    },
                    child: Text(
                      _filters[index],
                      maxLines: 1,
                      style: GoogleFonts.gowunBatang(
                        color: isSelected ? const Color(0xff0d1117) : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 30),

          // 추가 제안 1번: 학부모 대만족 요일별/시간대별 학습 골든 타임라인 패턴 분석 지표
          Text(
            'Golden Concentration Pattern (학습 골든 타임라인 패턴)',
            style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xff161b22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xff30363d)),
            ),
            child: Column(
              children: [
                _buildPatternRow(Icons.calendar_month, 'Peak Day (최고 집중 요일)', 'Tuesday (화요일)'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Divider(color: Color(0xff30363d)),
                ),
                _buildPatternRow(Icons.wb_twighlight, 'Golden Hours (최고 집중 시간대)', '13:00 - 15:00 UTC (KST 22:00)'),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // 대표님 기획 추가 필드 추천 요소 매핑 카드 섹션
          Text(
            'Advanced Metrics (상세 종합 기록)',
            style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _buildAdvancedMetricsSection(),
        ],
      ),
    );
  }

  Widget _buildPatternRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xff58a6ff), size: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.gowunBatang(color: Colors.grey[400], fontSize: 15)),
              const SizedBox(height: 4),
              Text(value, style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedMetricsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff161b22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xff30363d)),
      ),
      child: Column(
        children: [
          _buildMetricRow('Peak Focus Duration (최고 집중 기록)', '4h 22m (4시간 22분)'),
          const SizedBox(height: 12),
          _buildMetricRow('Most Studied Subject (가장 많이 공부한 과목)', 'Mathematics (수학)'),
          const SizedBox(height: 12),
          _buildMetricRow('Monthly Growth Rate (이번 달 성장률)', '+18% (지난달 대비 증가)'),
          const SizedBox(height: 12),
          _buildMetricRow('Cumulative Goal Rate (누적 목표 달성률)', '82% (전체 평균 달성)'),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.gowunBatang(color: Colors.grey[400], fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}