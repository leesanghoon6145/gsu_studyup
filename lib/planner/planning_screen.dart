import 'package:flutter/material.dart';
// [주석] 구글 폰트 패키지 임포트
import 'package:google_fonts/google_fonts.dart';

/// ============================================================================
/// [GKE StudyUp] 자기주도 학습 플래너 - 학습 계획 스크린 (planning_screen.dart)
/// ============================================================================
class PlanningScreen extends StatefulWidget {
  const PlanningScreen({Key? key}) : super(key: key);

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> with SingleTickerProviderStateMixin {
  // [주석] 상단 [연][월][주][일] 4개 탭 제어 컨트롤러
  late TabController _tabController;

  // [주석] 카테고리별 테마 색상 (지시사항 준수)
  final Color schoolColor = const Color(0xFF3B82F6);   // 학교 일정 (블루)
  final Color academyColor = const Color(0xFFA855F7);  // 학원 일정 (퍼플)
  final Color examColor = const Color(0xFFEF4444);     // 시험 일정 (레드)
  final Color personalColor = const Color(0xFF10B981); // 개인 일정 (그린)
  final Color goldColor = const Color(0xFFD4AF37);     // 공식 황금색

  // [주석] 테마 컬러 상수 정의
  final Color slate300 = const Color(0xFFCBD5E1);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color slate500 = const Color(0xFF64748B);
  final Color slate800 = const Color(0xFF1E293B);

  // [주석] 확장 상태 제어 변수
  bool _isYearTargetExpanded = true;
  bool _isMonthTargetExpanded = true;
  bool _isWeekTargetExpanded = true;
  int? _expandedDayScheduleIndex;

  // 🛠️ 가로 스크롤 연도 리스트 정의
  int _selectedYearIndex = 0;
  final List<String> _scrollableYears = ['2026년 목표', '2027년 목표', '2028년 목표', '2029년 목표', '2030년 목표'];

  // ============================================================================
  // 🛠️ [수정]: 연도별로 목표 데이터가 다르게 변하도록 Map(딕셔너리) 구조로 확장 개편
  // ============================================================================
  late Map<String, List<Map<String, dynamic>>> _yearlyTargetsMap;

  // [주석] 등록된 주요 학사 일정 리스트
  List<Map<String, dynamic>> _annualSchedules = [
    {'time': '3월 (March)', 'title': '개학', 'color': const Color(0xFF3B82F6)},
    {'time': '7월 (July)', 'title': '여름방학', 'color': const Color(0xFF10B981)},
    {'time': '11월 (November)', 'title': '수능', 'color': const Color(0xFFEF4444)},
    {'time': '12월 (December)', 'title': '겨울방학', 'color': const Color(0xFF10B981)},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // 🛠️ [수정]: 연도별 초기 데이터 분리 할당 (각 연도를 클릭할 때마다 독립된 목표가 나타납니다)
    _yearlyTargetsMap = {
      '2026년 목표': [
        {'title': '2026 민사고 합격', 'done': true},
        {'title': '2026 수학 1등급 달성', 'done': false},
        {'title': '2026 영어 1등급 고수', 'done': false},
      ],
      '2027년 목표': [
        {'title': '2027 고등 선행 심화 마스터', 'done': false},
        {'title': '2027 전국 모의고사 상위 0.5%', 'done': false},
      ],
      '2028년 목표': [
        {'title': '2028 수능 전과목 만점 베이스캠프', 'done': false},
      ],
      '2029년 목표': [],
      '2030년 목표': [],
    };
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// ============================================================================
  /// [주석] 화면 메인 빌더
  /// ============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // 딥 네이비
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 8),
        child: AppBar(
          backgroundColor: const Color(0xFF020617), // 다크 블랙
          elevation: 0,
          automaticallyImplyLeading: false, // 뒤로가기 화살표 자동 생성 완전 차단
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: TabBar(
              controller: _tabController,
              indicatorColor: goldColor,
              labelColor: goldColor,
              unselectedLabelColor: slate400,
              tabs: [
                Tab(child: Text('YEAR\n연', textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(fontSize: 14, fontWeight: FontWeight.bold))),
                Tab(child: Text('MONTH\n월', textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(fontSize: 14, fontWeight: FontWeight.bold))),
                Tab(child: Text('WEEK\n주', textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(fontSize: 14, fontWeight: FontWeight.bold))),
                Tab(child: Text('DAY\n일', textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(fontSize: 14, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildYearView(),
          _buildMonthView(),
          _buildWeekView(),
          _buildDayView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddScheduleBottomSheet(context),
        backgroundColor: goldColor,
        child: const Icon(Icons.add, color: Color(0xFF020617), size: 28),
      ),
    );
  }

  /// ============================================================================
  /// [주석] 1. 연간 뷰 (YEAR VIEW)
  /// ============================================================================
  Widget _buildYearView() {
    // 🛠️ [수정]: 현재 선택된 연도 이름 문자열 추출 ('2026년 목표' 등)
    String currentYearKey = _scrollableYears[_selectedYearIndex];
    // 🛠️ [수정]: 선택된 연도에 해당하는 전용 목표 리스트만 실시간으로 매칭
    List<Map<String, dynamic>> currentTargets = _yearlyTargetsMap[currentYearKey] ?? [];

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text('YEARLY TARGET', style: GoogleFonts.notoSerif(fontSize: 16, color: goldColor, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        // 연도별 가로 자동 스크롤 위젯
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _scrollableYears.length,
            itemBuilder: (context, index) {
              bool isSelected = _selectedYearIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedYearIndex = index; // 🛠️ 클릭 시 인덱스 변경 및 UI 동적 리프레시 발생
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? goldColor.withOpacity(0.15) : const Color(0xFF020617),
                    border: Border.all(color: isSelected ? goldColor : slate800, width: 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      _scrollableYears[index],
                      style: GoogleFonts.notoSansKr(
                          fontSize: 13,
                          color: isSelected ? goldColor : slate300,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        Card(
          color: const Color(0xFF020617),
          shape: RoundedRectangleBorder(side: BorderSide(color: slate800)),
          child: ExpansionTile(
            key: ValueKey(currentYearKey), // 🛠️ [수정]: 연도가 바뀔 때 위젯 상태를 확실하게 재랜더링 하도록 키값 명시
            initiallyExpanded: _isYearTargetExpanded,
            title: Text('$currentYearKey 리스트', style: GoogleFonts.notoSansKr(color: goldColor, fontSize: 15)),
            iconColor: goldColor,
            collapsedIconColor: slate400,
            onExpansionChanged: (val) => setState(() => _isYearTargetExpanded = val),
            children: [
              if (currentTargets.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Text('등록된 목표가 없습니다. 하단 + 버튼으로 추가하세요.', style: GoogleFonts.notoSansKr(color: slate500, fontSize: 12)),
                )
              else
              // 🛠️ [수정]: 독립 분리된 현재 연도의 목표 리스트만 화면에 뿌려줌
                ...currentTargets.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var target = entry.value;
                  return _buildYearChecklistItem(target['title'], target['done'], idx, currentYearKey);
                }).toList(),
              const SizedBox(height: 10),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionHeader('ANNUAL SCHEDULE', '주요 학사 일정'),
        const SizedBox(height: 10),
        ..._annualSchedules.map((schedule) => _buildScheduleTimelineItem(schedule['time'], schedule['title'], schedule['color'])).toList(),
      ],
    );
  }

  /// ============================================================================
  /// [주석] 2. 월간 뷰, 3. 주간 뷰, 4. 일간 뷰 및 컴포넌트 헬퍼 (기존 기능 완전 유지)
  /// ============================================================================
  Widget _buildMonthView() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionHeader('JULY 2026 CALENDAR', '2026년 7월 달력'),
        const SizedBox(height: 10),
        Container(
          height: 80,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(8)),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 31,
            itemBuilder: (context, index) {
              int dayNum = index + 1;
              bool isToday = dayNum == 14;
              return Container(
                width: 55,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: isToday ? goldColor.withOpacity(0.2) : Colors.transparent,
                  border: Border.all(color: isToday ? goldColor : Colors.transparent, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$dayNum', style: GoogleFonts.notoSerif(color: isToday ? goldColor : Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 5, height: 5, decoration: BoxDecoration(color: schoolColor, shape: BoxShape.circle)),
                        const SizedBox(width: 2),
                        Container(width: 5, height: 5, decoration: BoxDecoration(color: academyColor, shape: BoxShape.circle)),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionHeader('MONTHLY GOALS', '이번달 목표'),
        const SizedBox(height: 10),
        Card(
          color: const Color(0xFF020617),
          shape: RoundedRectangleBorder(side: BorderSide(color: slate800)),
          child: ExpansionTile(
            initiallyExpanded: _isMonthTargetExpanded,
            title: Text('OBJECTIVES\n월간 세부 목표', style: GoogleFonts.notoSansKr(color: goldColor, fontSize: 15)),
            iconColor: goldColor,
            collapsedIconColor: slate400,
            onExpansionChanged: (val) => setState(() => _isMonthTargetExpanded = val),
            children: [
              _buildChecklistItem('영어단어 1000개 암기', false),
              _buildChecklistItem('수학 문제집 완성', true),
              _buildChecklistItem('과학 3단원 완벽 마스터', false),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekView() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionHeader('SECOND WEEK OF JULY', '7월 둘째주 주간 관리'),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['월', '화', '수', '목', '금', '토', '일'].map((day) {
            bool isWed = day == '수';
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isWed ? goldColor : const Color(0xFF020617),
                shape: BoxShape.circle,
              ),
              child: Text(day, style: GoogleFonts.notoSansKr(color: isWed ? const Color(0xFF020617) : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            );
          }).toList(),
        ),
        const SizedBox(height: 25),
        _buildSectionHeader('WEEKLY TARGETS', '이번주 목표 학습 시간'),
        const SizedBox(height: 10),
        Card(
          color: const Color(0xFF020617),
          shape: RoundedRectangleBorder(side: BorderSide(color: slate800)),
          child: ExpansionTile(
            initiallyExpanded: _isWeekTargetExpanded,
            title: Text('WEEKLY TASKS\n주간 도달 과제', style: GoogleFonts.notoSansKr(color: goldColor, fontSize: 15)),
            iconColor: goldColor,
            collapsedIconColor: slate400,
            onExpansionChanged: (val) => setState(() => _isWeekTargetExpanded = val),
            children: [
              _buildChecklistItem('수학 자기주도 학습 20시간', true),
              _buildChecklistItem('영어 심화 독해 10시간', false),
              _buildChecklistItem('과학 오답노트 정리 및 복습', false),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayView() {
    final List<Map<String, dynamic>> daySchedules = [
      {'time': '07:00', 'title': '기상 및 명상', 'type': '개인', 'color': personalColor, 'memo': '하루의 시작을 대시보드와 함께 연동'},
      {'time': '09:00', 'title': '학교 정규 수업', 'type': '학교', 'color': schoolColor, 'memo': '집중하여 수업 참여 및 핵심 노트 정리'},
      {'time': '18:00', 'title': '영어학원 심화반', 'type': '학원', 'color': academyColor, 'memo': '글로벌 상용화 대비 에세이 작성 훈련'},
      {'time': '20:00', 'title': '수학 단원평가 대비', 'type': '시험', 'color': examColor, 'memo': '취약 유형 오답 정밀 클리닉'},
      {'time': '22:00', 'title': '개인 총복습 및 별 수집', 'type': '개인', 'color': personalColor, 'memo': '오늘 학습량 정산 후 게이미피케이션 별 누적'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionHeader('JULY 14TH DAILY ROUTINE', '7월 14일 오늘 일정'),
        const SizedBox(height: 5),
        Text(
          'CLICK TO EXPAND DETAILS / 누르면 상세 내용이 펼쳐집니다.',
          style: GoogleFonts.notoSansKr(fontSize: 12, color: goldColor.withOpacity(0.8)),
        ),
        const SizedBox(height: 15),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: daySchedules.length,
          itemBuilder: (context, index) {
            final item = daySchedules[index];
            bool isExpanded = _expandedDayScheduleIndex == index;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _expandedDayScheduleIndex = isExpanded ? null : index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF020617),
                  border: Border.all(color: isExpanded ? goldColor : slate800),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: item['color'], borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            item['type'],
                            style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item['time'],
                          style: GoogleFonts.notoSerif(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            item['title'],
                            style: GoogleFonts.notoSansKr(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: slate400,
                          size: 20,
                        )
                      ],
                    ),
                    if (isExpanded) ...[
                      const Divider(color: Color(0xFF1E293B), height: 16),
                      Text(
                        'SCHEDULE MEMO / 일정 상세 메모',
                        style: GoogleFonts.notoSerif(fontSize: 12, color: goldColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['memo'],
                        style: GoogleFonts.notoSansKr(fontSize: 12, color: slate300),
                      ),
                    ]
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String eng, String kor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eng, style: GoogleFonts.notoSerif(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold)),
        Text(kor, style: GoogleFonts.notoSansKr(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // 🛠️ [수정]: 삭제 타겟 연도 구분을 위해 yearKey 파라미터 추가 연동
  Widget _buildYearChecklistItem(String title, bool isChecked, int index, String yearKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _yearlyTargetsMap[yearKey]![index]['done'] = !isChecked;
              });
            },
            child: Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank, color: isChecked ? goldColor : slate500, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                color: isChecked ? slate400 : Colors.white,
                decoration: isChecked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                // 🛠️ [수정]: 특정 연도의 맵 리스트 안에서 정확히 아이템 삭제 처리
                _yearlyTargetsMap[yearKey]!.removeAt(index);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
              child: Icon(
                Icons.cancel,
                color: Colors.white.withOpacity(0.25),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String title, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: [
          Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank, color: isChecked ? goldColor : slate500, size: 20),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              color: isChecked ? slate400 : Colors.white,
              decoration: isChecked ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTimelineItem(String timeLabel, String eventTitle, Color leftBarColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        border: Border(left: BorderSide(color: leftBarColor, width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(timeLabel, style: GoogleFonts.notoSerif(fontSize: 12, color: goldColor)),
          Text(eventTitle, style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// ============================================================================
  /// [주석] 목표 추가 기능 바텀 시트
  /// ============================================================================
  void _showAddScheduleBottomSheet(BuildContext context) {
    String entryType = '일정';
    String selectedCategory = '학교';

    final TextEditingController titleController = TextEditingController();
    final TextEditingController dateController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    final TextEditingController memoController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF020617),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (BuildContext bc) {
        return StatefulBuilder(
          builder: (BuildContext modalContext, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 20.0,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ADD NEW ENTRY', style: GoogleFonts.notoSerif(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold)),
                    Text('새 리스트 추가하기', style: GoogleFonts.notoSansKr(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                    const Divider(color: Color(0xFF1E293B), height: 20),

                    Row(
                      children: ['일정', '목표'].map((type) {
                        return Row(
                          children: [
                            Radio<String>(
                              value: type,
                              groupValue: entryType,
                              activeColor: goldColor,
                              onChanged: (value) => setModalState(() => entryType = value!),
                            ),
                            Text(type, style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white)),
                            const SizedBox(width: 20),
                          ],
                        );
                      }).toList(),
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 15),

                    if (entryType == '일정') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: ['학교', '학원', '시험', '개인'].map((cat) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: cat,
                                groupValue: selectedCategory,
                                activeColor: goldColor,
                                onChanged: (value) => setModalState(() => selectedCategory = value!),
                              ),
                              Text(cat, style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white)),
                            ],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 15),
                    ],

                    TextField(
                      controller: titleController,
                      style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: entryType == '일정' ? 'TITLE / 일정 제목 입력' : 'TARGET / 현재 선택된 연도 목표 입력',
                        hintStyle: GoogleFonts.notoSansKr(color: slate400, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                      ),
                    ),

                    if (entryType == '일정') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: dateController,
                        style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'DATE / 날짜 및 월 (예: 7월 또는 2026-07-14)',
                          hintStyle: GoogleFonts.notoSansKr(color: slate400, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: timeController,
                        style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'TIME / 시간 기입 (선택사항)',
                          hintStyle: GoogleFonts.notoSansKr(color: slate400, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                    TextField(
                      controller: memoController,
                      maxLines: 2,
                      style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'MEMO / 세부 메모란',
                        hintStyle: GoogleFonts.notoSansKr(color: slate400, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: goldColor),
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) return;

                          if (entryType == '목표') {
                            // 🛠️ [수정]: 바텀 시트 저장 시 현재 선택된 상단 연도 탭에 동적 삽입되도록 구현 완료
                            String currentYearKey = _scrollableYears[_selectedYearIndex];
                            setState(() {
                              _yearlyTargetsMap[currentYearKey]!.add({
                                'title': titleController.text.trim(),
                                'done': false,
                              });
                            });
                          }
                          else {
                            Color sColor = schoolColor;
                            if (selectedCategory == '학원') sColor = academyColor;
                            if (selectedCategory == '시험') sColor = examColor;
                            if (selectedCategory == '개인') sColor = personalColor;

                            String timeText = dateController.text.trim();
                            if (timeController.text.trim().isNotEmpty) {
                              timeText += " (${timeController.text.trim()})";
                            }

                            setState(() {
                              _annualSchedules.add({
                                'time': timeText.isEmpty ? '수시' : timeText,
                                'title': titleController.text.trim(),
                                'color': sColor,
                              });
                            });
                          }

                          Navigator.pop(modalContext);
                        },
                        child: Text(
                          'SAVE AND APPLY / 저장 및 적용하기',
                          style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF020617), fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}