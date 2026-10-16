// ============================================================================
// 🆕 [2026-10-16] GeneralGuide — GKE StudyUp 일반 플래너 사용 설명서 (첫 접속 팝업)
//
// 원장님 확정 (2026-10-16)
// · 일반 플래너에 들어오면 첫 화면 위에 바로 뜨는 카드 스타일 팝업 (9장)
// · [나중에 다시 보기] → 닫고 다음 접속 때 또 뜸
// · 마지막 장 [사용 방법을 확인했습니다] → 그 뒤로는 자동으로 뜨지 않음
// · 화면 왼쪽 아래 금빛 📖 단추로 언제든 다시 보기
// · 큰 글씨 · 넉넉한 줄 간격 (60~70대 기준) · 바깥을 눌러도 닫히지 않음
// · 가족 응원 장은 살구빛으로 따로 강조 (격려가 먼저, 별 보내기는 마지막)
// · 계정마다 따로 기억 (plannerScopedKey)
//
// 쓰는 법: 일반 플래너 첫 화면을 GeneralGuideGate로 감싸기
//   const GeneralGuideGate(child: GeneralPlannerHomeScreen())
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'planner_scope.dart';

const Color _gGold = Color(0xFFE5C158);
const Color _gGoldSoft = Color(0xFFFFF6D6);
const Color _gInk = Color(0xFF030712);
const Color _gCard = Color(0xFF0F1626);
const Color _gHl = Color(0xFF1C2740);
const Color _gPeach = Color(0xFFE5A58F);
const Color _gPeachSoft = Color(0xFFFFE1DC);

class _GItem {
  final IconData? icon;
  final int? number;
  final String bold;
  final String desc;
  const _GItem(IconData this.icon, this.bold, this.desc) : number = null;
  const _GItem.num(int this.number, this.bold, this.desc) : icon = null;
}

class _GPage {
  final String tag;
  final IconData icon;
  final String title;
  final List<String> leads;
  final List<_GItem> items;
  final String highlight;
  final String closing;
  final bool family;
  const _GPage({
    required this.tag,
    required this.icon,
    required this.title,
    required this.leads,
    required this.items,
    required this.highlight,
    required this.closing,
    required this.family,
  });
}

const List<_GPage> _gPages = [
  _GPage(
    tag: 'WELCOME',
    icon: Icons.auto_awesome_rounded,
    title: '나의 하루, 나의 성장',
    leads: ['계획하고, 실천하고, 돌아보며 더 나은 내일을 만들어 갑니다.', '학생뿐 아니라 직장인 · 자영업자 · 주부 · 은퇴하신 분까지, 누구나 자신의 하루와 목표를 관리하는 공간입니다.'],
    items: [
      _GItem(Icons.sentiment_satisfied_alt_rounded, '스마트폰이 익숙하지 않으셔도 괜찮습니다.', '한 장에 한 가지씩만, 천천히 안내해 드립니다.'),
      _GItem(Icons.swipe_rounded, '옆으로 밀거나 [다음]을 누르세요.', '아래 금빛 점을 누르면 원하는 장으로 바로 갑니다.'),
    ],
    highlight: '처음부터 모든 기능을 쓰실 필요는 없습니다.',
    closing: 'GKE StudyUp과 함께 오늘부터 시작해 보세요.',
    family: false,
  ),
  _GPage(
    tag: 'SCHEDULE',
    icon: Icons.event_note_rounded,
    title: '나의 일정',
    leads: ['오늘 해야 할 일을 적어 두는 곳입니다.', '업무 · 장보기 · 병원 방문 · 운동 · 가족과의 약속까지 무엇이든 적어 보세요.'],
    items: [
      _GItem(Icons.alarm_rounded, '시간을 정하면 알람이 울립니다.', '화면이 꺼져 있어도, 진동 · 무음이어도 정한 시각에 울립니다.'),
      _GItem(Icons.schedule_rounded, '약속은 미리 알려 드립니다.', '정각 · 30분 전 · 1시간 전 · 1일 전 중에서 여러 개 고를 수 있습니다.'),
    ],
    highlight: '처음에는 오늘 꼭 해야 할 일 세 가지만 적어 보세요.',
    closing: '작은 계획 하나가 알찬 하루를 만듭니다.',
    family: false,
  ),
  _GPage(
    tag: 'TIMELINE',
    icon: Icons.view_timeline_rounded,
    title: '나의 하루 돌아보기',
    leads: ['나의 시간을 어떻게 썼는지 살펴보는 곳입니다.'],
    items: [
      _GItem(Icons.timelapse_rounded, '하루의 흐름을 봅니다.', '오늘 한 일과 활동이 시간 순서대로 보입니다.'),
      _GItem(Icons.balance_rounded, '균형을 살핍니다.', '업무 · 운동 · 휴식에 시간을 어떻게 나눴는지 돌아보세요.'),
      _GItem(Icons.favorite_border_rounded, '중요한 일에 썼나요?', '나에게 소중한 일에 시간을 잘 쓰고 있는지 확인해 보세요.'),
    ],
    highlight: '시간을 많이 보내는 것보다 의미 있게 쓰는 것이 더 중요합니다.',
    closing: '오늘의 돌아봄이 내일의 지혜가 됩니다.',
    family: false,
  ),
  _GPage(
    tag: 'GOAL',
    icon: Icons.flag_rounded,
    title: '나의 목표',
    leads: ['앞으로 이루고 싶은 일을 정하는 곳입니다.'],
    items: [
      _GItem(Icons.check_circle_outline_rounded, '건강을 위해 꾸준히 운동하기', ''),
      _GItem(Icons.check_circle_outline_rounded, '일과 생활의 균형 맞추기', ''),
      _GItem(Icons.check_circle_outline_rounded, '독서나 새로운 공부 시작하기', ''),
      _GItem(Icons.check_circle_outline_rounded, '미뤄 둔 일을 하나씩 실천하기', ''),
    ],
    highlight: '큰 목표가 아니어도 됩니다. 오늘 할 수 있는 작은 목표 하나부터 시작하세요.',
    closing: '작은 실천이 쌓여 큰 변화가 됩니다.',
    family: false,
  ),
  _GPage(
    tag: 'REPORT',
    icon: Icons.insights_rounded,
    title: '나의 실천 기록',
    leads: ['계획한 일을 얼마나 해냈는지 돌아보는 곳입니다.'],
    items: [
      _GItem(Icons.bar_chart_rounded, '기록을 확인합니다.', '주간 · 월간 · 연간으로 실천한 내용을 그래프로 보여 드립니다.'),
      _GItem(Icons.star_border_rounded, '잘한 점을 찾습니다.', '잘하고 있는 부분과 다듬을 부분을 함께 살펴보세요.'),
      _GItem(Icons.autorenew_rounded, '다음 계획으로 잇습니다.', '돌아본 내용을 바탕으로 다음 주 계획을 세웁니다.'),
    ],
    highlight: '기록은 나를 탓하기 위한 것이 아닙니다. 더 나은 내일을 준비하는 소중한 자료입니다.',
    closing: '꾸준한 기록이 나의 성장을 보여 줍니다.',
    family: false,
  ),
  _GPage(
    tag: 'EXERCISE & HEALTH',
    icon: Icons.favorite_rounded,
    title: '운동과 건강한 생활',
    leads: ['건강한 생활은 작은 실천에서 시작됩니다.', '가벼운 걷기부터 시작해도 좋습니다.'],
    items: [
      _GItem(Icons.edit_note_rounded, '운동 기록은 세 걸음입니다.', '운동 카드 누르기 → 시간과 힘든 정도 적기 → [저장].'),
      _GItem(Icons.watch_rounded, '워치를 차면 저절로 기록됩니다.', '삼성헬스의 걸음과 운동이 자동으로 들어옵니다. 노란 확인 카드가 뜨면 [확인]만 누르세요.'),
      _GItem(Icons.favorite_border_rounded, '오늘의 건강을 한눈에 봅니다.', '심박(최저 · 평상 · 평균 · 최고)과 혈압 · 혈당 · 심폐 체력 · 체성분. 직접 적을 수도 있습니다.'),
    ],
    highlight: '몸이 불편하거나 어지러우면 바로 멈추고 쉬세요. 걱정되는 수치가 계속되면 꼭 의사 선생님과 상의하세요.',
    closing: '무리하지 않고 꾸준히 하는 것이 가장 중요합니다.',
    family: false,
  ),
  _GPage(
    tag: 'FAMILY SUPPORT',
    icon: Icons.volunteer_activism_rounded,
    title: '가족의 응원이 아이의 꿈을 키웁니다',
    leads: ['혹시 공부하는 자녀 · 손자 · 손녀 · 조카 · 동생이 있으신가요?', '여러분의 작은 관심과 따뜻한 격려는 아이들에게 큰 힘이 될 수 있습니다.'],
    items: [
      _GItem(Icons.chat_bubble_outline_rounded, '따뜻한 응원 한마디를 전해 보세요.', '“오늘도 네 꿈을 향해 한 걸음 나아가는구나. 늘 응원할게!”'),
      _GItem(Icons.chat_bubble_outline_rounded, '결과보다 노력을 칭찬해 주세요.', '“포기하지 않고 노력하는 네 모습이 참 자랑스럽단다.”'),
      _GItem(Icons.volunteer_activism_outlined, '아이의 노력을 함께 응원해 주세요.', '아이에게 받은 연결 코드로 이어지면, 가족 응원 · 별 보내기로 공부하는 아이의 성장을 응원할 수 있습니다. 할머니 · 할아버지 · 삼촌 · 이모도 함께할 수 있습니다.'),
    ],
    highlight: '큰 선물보다 오래 기억되는 것은 진심 어린 응원입니다.',
    closing: '나의 건강한 하루가 아이의 밝은 미래를 응원합니다.',
    family: true,
  ),
  _GPage(
    tag: 'FIRST STEPS',
    icon: Icons.directions_walk_rounded,
    title: '처음에는 이렇게 시작하세요',
    leads: ['아래 다섯 가지를 차례로 해 보세요.'],
    items: [
      _GItem.num(1, '오늘 해야 할 일을 일정에 적어 보세요.', ''),
      _GItem.num(2, '실천할 수 있는 작은 목표 하나를 정하세요.', ''),
      _GItem.num(3, '할 수 있는 만큼 움직이고 기록을 남기세요.', ''),
      _GItem.num(4, '하루가 끝나면 오늘의 실천을 돌아보세요.', ''),
      _GItem.num(5, '공부하는 가족이 있다면 따뜻한 응원도 전해 보세요.', ''),
    ],
    highlight: '한 가지씩 천천히 익히시면 됩니다.',
    closing: '오늘의 첫 기록이 새로운 시작입니다.',
    family: false,
  ),
  _GPage(
    tag: 'OUR PROMISE',
    icon: Icons.workspace_premium_rounded,
    title: 'GKE StudyUp이 전하는 약속',
    leads: ['이곳은 더 많은 일을 하라고 재촉하는 곳이 아닙니다.', '나의 시간을 소중히 쓰고, 건강한 습관을 만들고, 작은 실천으로 성장하도록 돕는 곳입니다. 그리고 사랑하는 가족의 꿈을 함께 응원하는 곳입니다.'],
    items: [
      _GItem(Icons.wb_sunny_outlined, '나이와 직업에 관계없이', '누구에게나 새로운 시작은 가능합니다.'),
      _GItem(Icons.lock_outline_rounded, '기록은 안전하게', '이 폰 안에 소중히 보관됩니다. 이 설명서는 화면 왼쪽 아래 금빛 책 단추로 언제든 다시 볼 수 있습니다.'),
    ],
    highlight: '나의 공부가 기록되고, 나의 성장이 성취가 됩니다.',
    closing: 'GKE StudyUp과 함께 오늘부터 의미 있는 변화를 시작하세요.',
    family: false,
  ),];

class GeneralGuide {
  GeneralGuide._();

  static String get _doneKey => plannerScopedKey('gke_general_guide_done_v1');

  /// 일반 플래너에 들어올 때: [사용 방법을 확인했습니다]를 누르기 전까지는 매번 뜸
  static Future<void> showIfNeeded(BuildContext context) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_doneKey) == true) return;
    } catch (_) {}
    if (!context.mounted) return;
    await show(context);
  }

  /// 언제든 다시 보기
  static Future<void> show(BuildContext context) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: '사용 설명서',
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 360),
      pageBuilder: (_, __, ___) => const _GuideDialog(),
      transitionBuilder: (_, anim, __, child) {
        final CurvedAnimation c = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: c,
          child: ScaleTransition(scale: Tween<double>(begin: 0.94, end: 1).animate(c), child: child),
        );
      },
    );
  }

  static Future<void> _markDone() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_doneKey, true);
    } catch (_) {}
  }
}

class _GuideDialog extends StatefulWidget {
  const _GuideDialog();

  @override
  State<_GuideDialog> createState() => _GuideDialogState();
}

class _GuideDialogState extends State<_GuideDialog> {
  final PageController _pc = PageController();
  int _i = 0;

  bool get _last => _i == _gPages.length - 1;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _go(int k) {
    if (k < 0 || k >= _gPages.length) return;
    _pc.animateToPage(k, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  Future<void> _confirm() async {
    await GeneralGuide._markDone();
    if (mounted) Navigator.of(context).pop();
  }

  void _later() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final double h = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 480, maxHeight: h * 0.92),
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _gCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _gGold.withValues(alpha: 0.55)),
                boxShadow: [
                  BoxShadow(color: _gGold.withValues(alpha: 0.12), blurRadius: 36),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 30, offset: const Offset(0, 14)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pc,
                        itemCount: _gPages.length,
                        onPageChanged: (k) => setState(() => _i = k),
                        itemBuilder: (_, k) => _page(_gPages[k]),
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

  // ─── 한 장: 아이콘 타일 머리 → 안내 → 금빛 선 → 항목 → 강조 상자 → 맺음말 ───
  Widget _page(_GPage p) {
    final Color tileA = p.family ? _gPeachSoft : _gGoldSoft;
    final Color tileB = p.family ? _gPeach : _gGold;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [tileA, tileB]),
                  boxShadow: [BoxShadow(color: tileB.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: Icon(p.icon, color: _gInk, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GKE STUDYUP · ${p.tag}',
                        style: GoogleFonts.gowunBatang(color: _gGold, fontWeight: FontWeight.bold, fontSize: 12.5, letterSpacing: 0.6)),
                    const SizedBox(height: 2),
                    Text(p.title,
                        style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 21, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final String l in p.leads)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l, style: GoogleFonts.notoSansKr(color: Colors.white.withValues(alpha: 0.8), fontSize: 17, height: 1.7)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(height: 1, color: _gGold.withValues(alpha: 0.38)),
          ),
          for (final _GItem it in p.items) _item(it),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: _gHl,
              borderRadius: BorderRadius.circular(12),
              border: p.family ? Border.all(color: _gPeach.withValues(alpha: 0.4)) : null,
            ),
            child: Text(p.highlight,
                style: GoogleFonts.notoSansKr(color: _gGold, fontSize: 16.5, height: 1.65, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(p.closing,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 16.5, height: 1.6, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _item(_GItem it) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: it.number != null
                ? Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _gGold.withValues(alpha: 0.12),
                border: Border.all(color: _gGold.withValues(alpha: 0.5)),
              ),
              child: Text('${it.number}',
                  style: GoogleFonts.gowunBatang(color: _gGold, fontWeight: FontWeight.bold, fontSize: 14)),
            )
                : Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(it.icon, color: _gGold, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(it.bold, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17.5, height: 1.5)),
                if (it.desc.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(it.desc, style: GoogleFonts.notoSansKr(color: Colors.white.withValues(alpha: 0.78), fontSize: 16, height: 1.65)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 아래: 쪽 번호 · 점 · 이전 / [나중에 다시 보기] [다음 → / 사용 방법을 확인했습니다] ───
  Widget _footer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: _gInk.withValues(alpha: 0.45),
        border: Border(top: BorderSide(color: _gGold.withValues(alpha: 0.38))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 52,
                child: Text('${_i + 1} / ${_gPages.length}',
                    style: GoogleFonts.gowunBatang(color: _gGoldSoft, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(_gPages.length, (k) {
                    final bool on = k == _i;
                    return GestureDetector(
                      onTap: () => _go(k),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: on ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: on ? _gGold : Colors.white24,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              SizedBox(
                width: 52,
                child: _i == 0
                    ? const SizedBox.shrink()
                    : GestureDetector(
                  onTap: () => _go(_i - 1),
                  child: Text('← 이전',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 14)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: _later,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _gGold.withValues(alpha: 0.55)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('나중에 다시 보기',
                          style: GoogleFonts.notoSansKr(color: _gGoldSoft, fontWeight: FontWeight.w900, fontSize: 16)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(colors: [_gGoldSoft, _gGold]),
                    ),
                    child: ElevatedButton(
                      onPressed: _last ? _confirm : () => _go(_i + 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(_last ? '사용 방법을 확인했습니다' : '다음 →',
                            style: GoogleFonts.notoSansKr(color: _gInk, fontWeight: FontWeight.w900, fontSize: 16.5)),
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
// 🚪 GeneralGuideGate — 일반 플래너 첫 화면을 감싸서
//   ① 들어오자마자 설명서를 띄우고  ② 왼쪽 아래 금빛 📖 단추로 언제든 다시 열게 함
// ============================================================================
class GeneralGuideGate extends StatefulWidget {
  final Widget child;
  const GeneralGuideGate({super.key, required this.child});

  @override
  State<GeneralGuideGate> createState() => _GeneralGuideGateState();
}

class _GeneralGuideGateState extends State<GeneralGuideGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) GeneralGuide.showIfNeeded(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets pad = MediaQuery.of(context).padding;
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 12 + pad.left,
          bottom: 84 + pad.bottom, // 아래 탭 · 단추와 겹치지 않게
          child: Material(
            color: Colors.transparent,
            child: Tooltip(
              message: '사용 설명서',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => GeneralGuide.show(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _gCard.withValues(alpha: 0.92),
                    border: Border.all(color: _gGold.withValues(alpha: 0.75), width: 1.2),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8)],
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: _gGold, size: 22),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
