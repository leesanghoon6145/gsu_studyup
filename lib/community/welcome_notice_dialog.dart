import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ─────────────────────────────────────────────────────────────
/// GKE StudyUp 로그인 화면 첫 안내 팝업
///  - 방문 감사 + "앱 사용 설명서" 읽기 안내
///  - 맨 아래: [오늘 하루 보지 않기] / [다시 보지 않기]
///  - 기기 단위로 기억 (로그인 전이므로 계정과 무관)
/// 사용법: WelcomeNoticeDialog.showIfNeeded(context);
/// ─────────────────────────────────────────────────────────────
class WelcomeNoticeDialog {
  static const String _keyHideDate = 'gke_welcome_notice_hide_date';
  static const String _keyHideForever = 'gke_welcome_notice_hide_forever';

  static bool _isShowing = false;

  static String _today() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  /// 보여줄 조건이면 팝업을 띄움
  static Future<void> showIfNeeded(BuildContext context) async {
    if (_isShowing) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_keyHideForever) == true) return;
      if (prefs.getString(_keyHideDate) == _today()) return;
    } catch (_) {
      // 저장소를 읽지 못해도 팝업은 그대로 보여줌
    }
    if (!context.mounted) return;

    _isShowing = true;
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'welcome_notice',
      barrierColor: const Color(0xC0000000),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, a1, a2) => const _WelcomeNoticeCard(),
      transitionBuilder: (ctx, anim, a2, child) {
        final curved =
        CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
    _isShowing = false;
  }

  static Future<void> _hideToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyHideDate, _today());
    } catch (_) {}
  }

  static Future<void> _hideForever() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHideForever, true);
    } catch (_) {}
  }
}

class _WelcomeNoticeCard extends StatelessWidget {
  const _WelcomeNoticeCard();

  static const Color _gold = Color(0xFFD4AF37);
  static const Color _goldLight = Color(0xFFE5C158);
  static const Color _goldDeep = Color(0xFFB8922A);
  static const Color _textMain = Color(0xFFF3F4F6);
  static const Color _textSub = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final cardW = (screenW - 48).clamp(260.0, 380.0);

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: cardW,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF111827), Color(0xFF030712)],
            ),
            border: Border.all(color: _gold, width: 1.3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55D4AF37),
                blurRadius: 28,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Color(0xAA000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 금빛 원형 아이콘 ──
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_goldLight, _goldDeep],
                    ),
                    boxShadow: [
                      BoxShadow(color: Color(0x66D4AF37), blurRadius: 16),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: Color(0xFF030712),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),

                // ── 제목 ──
                const Text(
                  'WELCOME',
                  style: TextStyle(
                    color: _goldLight,
                    fontSize: 12,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'GKE StudyUp',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 14),

                // ── 금색 구분선 + 마름모 ──
                Row(
                  children: [
                    Expanded(child: _goldLine(reverse: true)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Transform.rotate(
                        angle: 0.785398,
                        child: Container(width: 7, height: 7, color: _gold),
                      ),
                    ),
                    Expanded(child: _goldLine()),
                  ],
                ),
                const SizedBox(height: 18),

                // ── 감사 인사 ──
                const Text(
                  'GKE StudyUp을 찾아 주셔서\n진심으로 감사드립니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textMain,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 14),

                // ── 설명서 안내 ──
                const Text.rich(
                  TextSpan(
                    style: TextStyle(
                      color: _textMain,
                      fontSize: 15,
                      height: 1.7,
                    ),
                    children: [
                      TextSpan(text: '로그인하신 뒤에는\n'),
                      TextSpan(
                        text: '「앱 사용 설명서」',
                        style: TextStyle(
                          color: _goldLight,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(text: '를 꼭 먼저\n읽어 주시길 정중히 부탁드립니다.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  '설명서를 읽으시면 학생·학부모·일반 회원 모두\n앱을 훨씬 알차고 편리하게 이용하실 수 있습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textSub,
                    fontSize: 12.5,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 22),

                // ── 확인 버튼 (금색) ──
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [_goldLight, _gold, _goldDeep],
                      ),
                      boxShadow: const [
                        BoxShadow(color: Color(0x55D4AF37), blurRadius: 12),
                      ],
                    ),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        '확인했습니다',
                        style: TextStyle(
                          color: Color(0xFF030712),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── 맨 아래: 오늘 하루 보지 않기 / 다시 보지 않기 ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _bottomButton(
                      label: '오늘 하루 보지 않기',
                      onTap: () async {
                        await WelcomeNoticeDialog._hideToday();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                    Container(width: 1, height: 12, color: const Color(0xFF4B5563)),
                    _bottomButton(
                      label: '다시 보지 않기',
                      onTap: () async {
                        await WelcomeNoticeDialog._hideForever();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _goldLine({bool reverse = false}) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: reverse
              ? const [Color(0x00D4AF37), _gold]
              : const [_gold, Color(0x00D4AF37)],
        ),
      ),
    );
  }

  static Widget _bottomButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _textSub,
          fontSize: 12.5,
          decoration: TextDecoration.underline,
          decorationColor: Color(0xFF6B7280),
        ),
      ),
    );
  }
}
