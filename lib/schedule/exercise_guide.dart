// ============================================================================
// 🆕 [2026-10-16] ExerciseGuide — 운동 사용 설명서 (앱의 얼굴)
//
// 원장님 요청: 일반 운동에 들어오면 사용 설명서를 팝업으로 — 상세하지만 쉽게,
//             60대 · 70대도 알아듣게, 아주 고급스럽게
//
// · 운동 화면에 들어오면 자동으로 뜸 → [다음부터 보지 않기]를 체크하면 그 뒤로는 안 뜸
// · 화면 맨 아래 [📖 사용 설명서]를 누르면 언제든 다시 볼 수 있음
// · 8장: 한 장에 한 가지 이야기만, 큰 글씨 · 번호 · 그림 아이콘
// · 계정마다 따로 기억 (plannerScopedKey)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'planner_scope.dart';

const Color _gold = Color(0xFFE5C158);
const Color _goldSoft = Color(0xFFFFF6D6);
const Color _ink = Color(0xFF030712);
const Color _navy = Color(0xFF0D1527);
const Color _navy2 = Color(0xFF141F38);

class _Step {
  final IconData icon;
  final String title;
  final String body;
  const _Step(this.icon, this.title, this.body);
}

class _Page {
  final IconData icon;
  final Color accent;
  final String eyebrow; // 영어 작은 제목
  final String title;
  final String lead; // 한 줄 요약
  final List<_Step> steps;
  final String? tip; // 노란 도움말 상자
  const _Page({
    required this.icon,
    required this.accent,
    required this.eyebrow,
    required this.title,
    required this.lead,
    required this.steps,
    this.tip,
  });
}

const List<_Page> _pages = [
  _Page(
    icon: Icons.favorite_rounded,
    accent: Color(0xFFEF4444),
    eyebrow: 'WELCOME',
    title: '건강한 하루를\n기록하는 곳입니다',
    lead: '운동한 것을 적어 두면, 날마다 · 주마다 얼마나 좋아지는지 한눈에 보여 드립니다.',
    steps: [
      _Step(Icons.edit_note_rounded, '운동 기록', '걷기 · 달리기 · 자전거 · 수영 · 헬스 등 무엇이든 적을 수 있습니다.'),
      _Step(Icons.watch_rounded, '워치 자동 기록', '갤럭시 워치 · 삼성헬스를 쓰시면 걸음과 운동이 저절로 들어옵니다.'),
      _Step(Icons.monitor_heart_rounded, '오늘의 건강', '심박 · 혈압 · 혈당 · 심폐 체력 · 체성분을 한 화면에서 봅니다.'),
      _Step(Icons.insights_rounded, '그래프 분석', '2주 동안의 변화를 그래프로 보여 드립니다.'),
    ],
    tip: '천천히 넘겨 보세요. 한 장에 한 가지씩만 설명해 드립니다.',
  ),
  _Page(
    icon: Icons.settings_suggest_rounded,
    accent: Color(0xFF60A5FA),
    eyebrow: 'GETTING READY',
    title: '처음 한 번만\n준비하면 됩니다',
    lead: '아래 세 가지를 해 두시면 그다음부터는 거의 저절로 기록됩니다.',
    steps: [
      _Step(Icons.person_outline_rounded, '① 몸무게 넣기',
          '화면 오른쪽 위 사람 모양 단추를 누르고 몸무게를 넣으세요. 소모 칼로리를 정확히 계산해 드립니다.'),
      _Step(Icons.link_rounded, '② 삼성헬스 연결',
          '운동 기록 화면에서 워치 · 삼성헬스 연결 단추가 보이면 누르고, 나오는 화면에서 모두 "허용"을 누르세요.'),
      _Step(Icons.cake_outlined, '③ 출생연도 (필요할 때만)',
          '"오늘의 건강"의 [직접 입력]에서 출생연도를 한 번 넣으면 심폐 체력이 매일 자동 계산됩니다. 회원가입 때 생년월일을 넣으셨다면 할 필요 없습니다.'),
    ],
    tip: '워치가 없어도 괜찮습니다. 손으로 적어도 모든 기능을 쓸 수 있습니다.',
  ),
  _Page(
    icon: Icons.directions_walk_rounded,
    accent: _gold,
    eyebrow: 'HOW TO RECORD',
    title: '운동 기록하는 법\n딱 세 걸음',
    lead: '첫 화면에 보이는 운동 카드 중 하나를 누르면 시작됩니다.',
    steps: [
      _Step(Icons.touch_app_rounded, '① 운동 카드 누르기', '예: "걷기" 카드를 누르면 걷기 기록 화면이 열립니다.'),
      _Step(Icons.timer_outlined, '② 시간 · 힘든 정도 적기',
          '운동한 시간(분)을 쓰고, 막대를 밀어 얼마나 힘들었는지 고르세요. 1은 아주 쉬움, 10은 아주 힘듦입니다.'),
      _Step(Icons.check_circle_rounded, '③ 맨 아래 [저장] 누르기', '끝입니다. 기록은 바로 그래프에 반영됩니다.'),
    ],
    tip: '거리 · 걸음 수 같은 세부 칸은 비워도 됩니다. 아는 것만 적으세요.',
  ),
  _Page(
    icon: Icons.watch_rounded,
    accent: Color(0xFF22C55E),
    eyebrow: 'AUTOMATIC',
    title: '워치를 차면\n저절로 기록됩니다',
    lead: '삼성헬스에 쌓인 걸음과 운동을 앱이 알아서 가져옵니다.',
    steps: [
      _Step(Icons.directions_run_rounded, '걸음 · 워치 운동', '하루 걸음과 워치로 기록한 운동이 저절로 들어옵니다.'),
      _Step(Icons.fact_check_rounded, '확인 카드 → [확인]',
          '운동 화면 위쪽에 노란 확인 카드가 뜨면, 내용이 맞을 때 [확인]을 누르세요. 틀리면 [고치기]를 누르면 됩니다.'),
      _Step(Icons.favorite_rounded, '운동 심박도 자동', '운동한 시간의 심박 평균 · 최고가 기록에 함께 저장됩니다.'),
    ],
    tip: '삼성헬스에서 앱으로 넘어오는 데 몇 분 걸릴 수 있습니다. 화면을 열어 두면 1분마다 다시 받아 옵니다.',
  ),
  _Page(
    icon: Icons.monitor_heart_rounded,
    accent: Color(0xFFEF4444),
    eyebrow: "TODAY'S HEART",
    title: '오늘 심박\n네 가지 숫자',
    lead: '오늘 0시부터 지금까지 워치가 잰 심박을 정리해 보여 드립니다.',
    steps: [
      _Step(Icons.arrow_downward_rounded, '최저', '오늘 가장 낮았던 심박입니다. 보통 잠잘 때 나옵니다.'),
      _Step(Icons.self_improvement_rounded, '평상', '가만히 쉬고 있을 때의 보통 심박입니다. 낮을수록 심장이 튼튼하다는 뜻입니다.'),
      _Step(Icons.horizontal_rule_rounded, '평균', '오늘 하루 전체의 평균입니다.'),
      _Step(Icons.arrow_upward_rounded, '최고', '오늘 가장 높았던 심박입니다. 보통 운동할 때 나옵니다.'),
    ],
    tip: '운동을 꾸준히 하면 몇 주 뒤 "평상" 숫자가 조금씩 내려갑니다. 그것이 좋아지고 있다는 신호입니다.',
  ),
  _Page(
    icon: Icons.health_and_safety_rounded,
    accent: Color(0xFF60A5FA),
    eyebrow: "TODAY'S HEALTH",
    title: '오늘의 건강\n한 장에 모았습니다',
    lead: '삼성헬스에 있는 값은 저절로 들어오고, 직접 적을 수도 있습니다.',
    steps: [
      _Step(Icons.bloodtype_outlined, '혈압', '정상은 120 / 80 미만입니다. 옆에 "정상 · 주의 · 고혈압" 표시가 함께 나옵니다.'),
      _Step(Icons.water_drop_outlined, '혈당', '아침 공복 기준 100 미만이 정상입니다.'),
      _Step(Icons.air_rounded, '심폐 체력', '평상 심박과 나이로 매일 자동 계산합니다. 숫자가 오를수록 체력이 좋아진 것입니다.'),
      _Step(Icons.accessibility_new_rounded, '체성분', '체중 · 체지방률 · 골격근량과 체질량지수(BMI)를 보여 드립니다.'),
      _Step(Icons.edit_rounded, '[직접 입력]', '혈압계 · 혈당계로 잰 값을 적으세요. 칸을 비우면 다시 자동으로 돌아갑니다.'),
    ],
    tip: '이 숫자들은 건강 관리를 돕는 참고용입니다. 걱정되는 숫자가 계속되면 꼭 의사 선생님과 상의하세요.',
  ),
  _Page(
    icon: Icons.insights_rounded,
    accent: _gold,
    eyebrow: 'ANALYSIS',
    title: '얼마나 좋아졌는지\n그래프로 봅니다',
    lead: '기록이 쌓일수록 그래프가 더 또렷해집니다.',
    steps: [
      _Step(Icons.insights_rounded, '전체 분석', '화면 오른쪽 위 그래프 단추를 누르면 모든 운동을 한꺼번에 봅니다.'),
      _Step(Icons.bar_chart_rounded, '종목별 상세', '운동 기록 화면 아래 [운동분석]에서 그 운동만 자세히 봅니다.'),
      _Step(Icons.date_range_rounded, '14일 추이', '거리 · 걸음 · 시간이 2주 동안 어떻게 바뀌었는지 보여 드립니다.'),
    ],
  ),
  _Page(
    icon: Icons.tune_rounded,
    accent: Color(0xFFA78BFA),
    eyebrow: 'MAKE IT YOURS',
    title: '나에게 맞게\n바꿀 수 있습니다',
    lead: '자주 하는 운동을 더하고, 필요 없는 것은 지우세요.',
    steps: [
      _Step(Icons.add_circle_outline_rounded, '운동 더하기', '오른쪽 위 ⊕ 단추로 새 운동(예: 게이트볼 · 등산)을 만들 수 있습니다.'),
      _Step(Icons.edit_rounded, '고치기 · 지우기', '운동 카드의 삼색 연필을 누르면 이름을 고치거나 지울 수 있습니다.'),
      _Step(Icons.language_rounded, '언어 바꾸기', '왼쪽 위 🌐 단추로 12개 언어 중 고를 수 있습니다.'),
      _Step(Icons.lock_outline_rounded, '안심하세요', '건강 기록은 이 폰 안에만 저장되고, 인터넷 요금도 들지 않습니다.'),
    ],
    tip: '이 설명서는 화면 맨 아래 [📖 사용 설명서]를 누르면 언제든 다시 볼 수 있습니다.',
  ),
];

class ExerciseGuide {
  ExerciseGuide._();

  static String get _hideKey => plannerScopedKey('gke_exercise_guide_hide_v1');

  /// 운동 화면에 들어올 때: "다음부터 보지 않기"를 고르지 않았으면 보여 줌
  static Future<void> showIfNeeded(BuildContext context) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_hideKey) == true) return;
    } catch (_) {}
    if (!context.mounted) return;
    await show(context, fromAuto: true);
  }

  /// 언제든 다시 보기
  static Future<void> show(BuildContext context, {bool fromAuto = false}) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: '사용 설명서',
      barrierColor: Colors.black.withValues(alpha: 0.82),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => _GuideDialog(fromAuto: fromAuto),
      transitionBuilder: (_, anim, __, child) {
        final CurvedAnimation c = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: c,
          child: ScaleTransition(scale: Tween<double>(begin: 0.92, end: 1).animate(c), child: child),
        );
      },
    );
  }

  static Future<void> _setHidden(bool hide) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hideKey, hide);
    } catch (_) {}
  }
}

class _GuideDialog extends StatefulWidget {
  final bool fromAuto;
  const _GuideDialog({required this.fromAuto});

  @override
  State<_GuideDialog> createState() => _GuideDialogState();
}

class _GuideDialogState extends State<_GuideDialog> {
  final PageController _pc = PageController();
  int _index = 0;
  bool _hideNext = false;

  @override
  void initState() {
    super.initState();
    // 이미 "보지 않기"를 골라 둔 상태에서 다시 열었으면 체크된 채로 보여 줌
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _hideNext = p.getBool(ExerciseGuide._hideKey) == true);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _pages.length - 1;

  Future<void> _close() async {
    await ExerciseGuide._setHidden(_hideNext);
    if (mounted) Navigator.of(context).pop();
  }

  void _go(int i) => _pc.animateToPage(i, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final _Page page = _pages[_index];
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 520, maxHeight: size.height * 0.92),
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_navy2, _navy, _ink],
                ),
                border: Border.all(color: _gold.withValues(alpha: 0.75), width: 1.4),
                boxShadow: [
                  BoxShadow(color: _gold.withValues(alpha: 0.18), blurRadius: 40, spreadRadius: 1),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 30, offset: const Offset(0, 14)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Column(
                  children: [
                    _header(page),
                    Expanded(
                      child: PageView.builder(
                        controller: _pc,
                        itemCount: _pages.length,
                        onPageChanged: (i) => setState(() => _index = i),
                        itemBuilder: (_, i) => _pageBody(_pages[i]),
                      ),
                    ),
                    _footer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── 머리: 브랜드 줄 + 쪽 번호 + 닫기 ───
  Widget _header(_Page page) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _gold.withValues(alpha: 0.18))),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [_goldSoft, _gold]),
              boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.4), blurRadius: 10)],
            ),
            child: const Icon(Icons.menu_book_rounded, color: _ink, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GKE EXERCISE GUIDE',
                    style: GoogleFonts.gowunBatang(color: _gold, fontWeight: FontWeight.bold, fontSize: 11.5, letterSpacing: 2)),
                Text('운동 사용 설명서', style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _gold.withValues(alpha: 0.5)),
            ),
            child: Text('${_index + 1} / ${_pages.length}',
                style: GoogleFonts.gowunBatang(color: _goldSoft, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          IconButton(
            tooltip: '닫기',
            onPressed: _close,
            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 24),
          ),
        ],
      ),
    );
  }

  // ─── 본문 한 장 ───
  Widget _pageBody(_Page p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 큰 메달 아이콘
          Center(
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [p.accent.withValues(alpha: 0.35), p.accent.withValues(alpha: 0.05)]),
                border: Border.all(color: p.accent.withValues(alpha: 0.8), width: 1.6),
                boxShadow: [BoxShadow(color: p.accent.withValues(alpha: 0.35), blurRadius: 28)],
              ),
              child: Icon(p.icon, color: Colors.white, size: 46),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(p.eyebrow,
                style: GoogleFonts.gowunBatang(color: _gold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 3)),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(p.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 25, height: 1.35)),
          ),
          const SizedBox(height: 10),
          Center(
            child: Container(width: 46, height: 2, color: _gold.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 12),
          Text(p.lead,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 16.5, height: 1.65, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          ...p.steps.map(_stepTile),
          if (p.tip != null) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _gold.withValues(alpha: 0.45)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_rounded, color: _gold, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(p.tip!,
                        style: GoogleFonts.notoSansKr(color: _goldSoft, fontSize: 15.5, height: 1.6, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepTile(_Step s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _gold.withValues(alpha: 0.12),
              border: Border.all(color: _gold.withValues(alpha: 0.45)),
            ),
            child: Icon(s.icon, color: _gold, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.title, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, height: 1.3)),
                const SizedBox(height: 4),
                Text(s.body, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 16, height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 아래: 점 · 보지 않기 · 이전/다음 ───
  Widget _footer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _gold.withValues(alpha: 0.18))),
        color: _ink.withValues(alpha: 0.6),
      ),
      child: Column(
        children: [
          // 쪽 점
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) {
              final bool on = i == _index;
              return GestureDetector(
                onTap: () => _go(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: on ? 24 : 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: on ? _gold : Colors.white24,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          // 다음부터 보지 않기
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _hideNext = !_hideNext),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _hideNext ? _gold : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _hideNext ? _gold : Colors.white38, width: 1.6),
                    ),
                    child: _hideNext ? const Icon(Icons.check_rounded, color: _ink, size: 18) : null,
                  ),
                  const SizedBox(width: 10),
                  Text('다음부터 자동으로 보지 않기',
                      style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (_index > 0) ...[
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => _go(_index - 1),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _gold.withValues(alpha: 0.55)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('이전', style: GoogleFonts.notoSansKr(color: _goldSoft, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(colors: [_goldSoft, _gold]),
                      boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLast ? _close : () => _go(_index + 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_isLast ? '운동 시작하기' : '다음',
                              style: GoogleFonts.notoSansKr(color: _ink, fontSize: 19, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 6),
                          Icon(_isLast ? Icons.directions_run_rounded : Icons.arrow_forward_rounded, color: _ink, size: 22),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 📖 운동 첫 화면 맨 아래 — [사용 설명서] 다시 보기 띠
// ============================================================================
class ExerciseGuideBar extends StatelessWidget {
  const ExerciseGuideBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => ExerciseGuide.show(context),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(colors: [_gold.withValues(alpha: 0.16), _gold.withValues(alpha: 0.06)]),
              border: Border.all(color: _gold.withValues(alpha: 0.6), width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.menu_book_rounded, color: _gold, size: 22),
                const SizedBox(width: 10),
                Text('GUIDE', style: GoogleFonts.gowunBatang(color: _gold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 2)),
                const SizedBox(width: 8),
                Text('사용 설명서 보기', style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
