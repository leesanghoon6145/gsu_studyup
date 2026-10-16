// ============================================================================
// 🆕 [2026-10-15 · 2026-10-16 새 알람 방식] GlobalAlarmStopOverlay — 앱 어디서든 뜨는 "알람 끄기" 팝업
//
// · 알람이 울리면 앱의 어느 화면(로그인 화면 포함) 위에도 큰 [알람 끄기] 화면이 바로 덮어 뜸
// · 화면이 꺼져 있을 때는 알람이 화면을 켜며 앱을 열고, 그 위에 이 팝업이 뜸
// · 확인 대상: ① 새 알람(gke_alarm_v3 — GkeAlarmEngine) ② 예전 방식 반복 소리(예비 감시) ③ 뒤에서 울린 표시
// · [알람 끄기] → GkeAlarmEngine.stopAll(): 소리 · 진동 · 알림 · 뒤에서 울리는 소리까지 한 번에 끄고,
//   매일 · 요일 알람은 다음 회차를 다시 예약
// · 고른 1분 · 5분이 지나 알람이 스스로 멈추면 팝업도 저절로 닫힘
//
// ⚠️ 이 파일은 lib/planner 폴더에 둡니다 (main.dart: import 'planner/global_alarm_stop_overlay.dart').
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gsu_studyup/schedule/notification_service.dart';
import 'package:gsu_studyup/services/gke_alarm_engine.dart';

/// 학생 · 일반 예비 감시가 "울리는 중"을 남기는 폰 저장 이름 (두 서비스와 반드시 같은 글자)
const String kAlarmRingingAtKey = 'gke_alarm_ringing_at';
const String kAlarmRingingTitleKey = 'gke_alarm_ringing_title';

/// 공용 끄기 화면을 쓰는지 (true면 각 화면의 옛 끄기 팝업은 띄우지 않음 — 두 개 겹침 방지)
const bool kGlobalAlarmOverlayOn = true;

/// 학생 자기주도 플래너 예비 감시 연결 고리 — learning_screen.dart의 PlannerAlarmService가 울릴 때 채워 넣음
class PlannerAlarmHooks {
  static ValueNotifier<bool>? ringing;
  static Future<void> Function()? stop;
}

class GlobalAlarmStopOverlay extends StatefulWidget {
  final Widget child;
  const GlobalAlarmStopOverlay({super.key, required this.child});

  @override
  State<GlobalAlarmStopOverlay> createState() => _GlobalAlarmStopOverlayState();
}

class _GlobalAlarmStopOverlayState extends State<GlobalAlarmStopOverlay> with WidgetsBindingObserver {
  static const Color _bg = Color(0xFF030712);
  static const Color _gold = Color(0xFFE5C158);
  static const Color _red = Color(0xFFDC2626);

  Timer? _poll;
  bool _ringing = false;
  bool _stopping = false;
  bool _checking = false;
  String _title = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
    _poll = Timer.periodic(const Duration(seconds: 1), (_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  // 화면이 꺼졌다 켜지거나 앱으로 돌아오면 바로 한 번 더 확인
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (_stopping || _checking) return;
    _checking = true;
    try {
      String? title = await GkeAlarmEngine.activeAlarmTitle(); // ① 새 알람 (알림창에 떠 있는 동안)
      bool ringing = title != null;
      if (!ringing) {
        ringing = PlannerAlarmHooks.ringing?.value ?? false; // ② 예비 감시 (학생)
        if (!ringing) {
          try {
            ringing = await NotificationService.isAlarmRinging(); // ② 예비 감시 (일반)
          } catch (_) {}
        }
        try {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.reload();
          final DateTime? at = DateTime.tryParse(prefs.getString(kAlarmRingingAtKey) ?? '');
          if (at != null && DateTime.now().difference(at).inMinutes < 6) ringing = true; // ③ 뒤에서 울린 표시
          if (ringing) title = prefs.getString(kAlarmRingingTitleKey) ?? '';
        } catch (_) {}
      }
      if (!mounted) return;
      final String t = title ?? '';
      if (ringing != _ringing || t != _title) {
        setState(() {
          _ringing = ringing;
          _title = t;
        });
      }
    } finally {
      _checking = false;
    }
  }

  Future<void> _stopAll() async {
    if (_stopping) return;
    setState(() => _stopping = true);
    try {
      await GkeAlarmEngine.stopAll();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _ringing = false;
      _stopping = false;
      _title = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_ringing) Positioned.fill(child: _buildStopScreen()),
      ],
    );
  }

  Widget _buildStopScreen() {
    return Material(
      color: _bg.withValues(alpha: 0.97),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.85, end: 1.0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOut,
                builder: (context, s, child) => Transform.scale(scale: s, child: child),
                child: const Icon(Icons.alarm_rounded, color: _red, size: 96),
              ),
              const SizedBox(height: 22),
              Text('ALARM', style: GoogleFonts.gowunBatang(color: _gold, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 3)),
              const SizedBox(height: 6),
              Text('알람이 울리고 있습니다',
                  textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              if (_title.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1527),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _gold.withValues(alpha: 0.5)),
                  ),
                  child: Text(_title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansKr(color: _gold, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
              const SizedBox(height: 10),
              Text('아래 버튼을 누르면 알람이 꺼집니다.\n누르지 않으면 정해 둔 1분 · 5분 뒤 저절로 멈춥니다.',
                  textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white60, fontSize: 13.5, height: 1.6)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _stopping ? null : _stopAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                  ),
                  child: Column(
                    children: [
                      Text('STOP', style: GoogleFonts.gowunBatang(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('알람 끄기', style: GoogleFonts.notoSansKr(fontSize: 21, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
