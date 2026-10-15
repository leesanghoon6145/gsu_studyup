// ============================================================================
// 🆕 [2026-10-15] GlobalAlarmStopOverlay — 앱 어디서든 뜨는 "알람 끄기" 화면
//
// 원장님 요청: 알람이 울리면 일반 플래너에 로그인해서 그 화면까지 들어가야 끌 수 있어 너무 불편함.
// → 폰을 켜면 앱의 어느 화면(로그인 화면 포함)이든 그 위에 큰 "알람 끄기" 화면이 바로 뜨게 함.
//   학생 자기주도 플래너 알람(PlannerAlarmService) + 일반 플래너 알람(NotificationService) 모두.
//
// 작동 방식
//  1) 1초마다 "지금 울리는 알람이 있나" 확인
//     - 이 화면과 같은 곳에서 울리는 알람: 각 서비스의 울림 상태로 확인
//     - 화면이 꺼져 있을 때 뒤에서(포그라운드 감시) 울린 알람: 폰에 남긴 "울리는 중" 표시로 확인
//  2) 울리면 앱 맨 위에 전체 화면으로 덮어 보여 줌 (화면 이동 · 로그인과 상관없음)
//  3) [알람 끄기] → 두 알람 소리 모두 끄고, 뒤에서 울리는 알람에도 "꺼라" 신호를 보내고,
//     알림창에 남은 알람 알림도 지움
//
// ⚠️ 이 파일은 lib 폴더 바로 안(main.dart와 같은 곳)에 둡니다.
// ⚠️ main.dart의 MaterialApp에 builder 한 줄로 연결해야 작동합니다.
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gsu_studyup/schedule/notification_service.dart';

/// 학생 플래너 · 일반 플래너가 "울리는 중"을 남기는 폰 저장 이름 (두 서비스와 반드시 같은 글자)
const String kAlarmRingingAtKey = 'gke_alarm_ringing_at';
const String kAlarmRingingTitleKey = 'gke_alarm_ringing_title';

/// 🆕 학생 자기주도 플래너 알람 연결 고리 — learning_screen.dart의 PlannerAlarmService가 울릴 때 스스로 채워 넣음
/// (이 파일을 lib 폴더 바로 안에 두어도 되도록, 플래너 파일을 직접 부르지 않고 이 고리로 연결)
class PlannerAlarmHooks {
  static ValueNotifier<bool>? ringing;
  static Future<void> Function()? stop;
}

/// 공용 끄기 화면을 쓰는지 (true면 각 화면의 옛 끄기 팝업은 띄우지 않음 — 두 개 겹침 방지)
const bool kGlobalAlarmOverlayOn = true;

class GlobalAlarmStopOverlay extends StatefulWidget {
  final Widget child;
  const GlobalAlarmStopOverlay({super.key, required this.child});

  @override
  State<GlobalAlarmStopOverlay> createState() => _GlobalAlarmStopOverlayState();
}

class _GlobalAlarmStopOverlayState extends State<GlobalAlarmStopOverlay> {
  static const Color _bg = Color(0xFF030712);
  static const Color _gold = Color(0xFFE5C158);
  static const Color _red = Color(0xFFDC2626);

  // 알람 소리를 따로 내는 두 알림 통로 (각 서비스의 반복 알람 통로 이름과 같아야 함)
  static const Set<String> _loopingChannels = {
    'gke_looping_alarm_channel_v1', // 일반 플래너
    'gsu_self_directed_planner_looping_channel', // 학생 자기주도 플래너
  };

  Timer? _poll;
  bool _ringing = false;
  bool _stopping = false;
  String _title = '';

  @override
  void initState() {
    super.initState();
    // 뒤에서 도는 알람 감시(포그라운드 감시)에 "꺼라" 신호를 보낼 수 있게 연결
    try {
      FlutterForegroundTask.initCommunicationPort();
    } catch (_) {}
    _check();
    _poll = Timer.periodic(const Duration(seconds: 1), (_) => _check());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_stopping) return;
    bool ringing = PlannerAlarmHooks.ringing?.value ?? false;
    if (!ringing) {
      try {
        ringing = await NotificationService.isAlarmRinging();
      } catch (_) {}
    }
    String title = '';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final String? at = prefs.getString(kAlarmRingingAtKey);
      final DateTime? atTime = at == null ? null : DateTime.tryParse(at);
      // 뒤에서 울린 알람: 표시가 남아 있고 6분 안이면 울리는 중으로 봄 (자동 정지가 최대 5분)
      if (atTime != null && DateTime.now().difference(atTime).inMinutes < 6) {
        ringing = true;
      }
      title = prefs.getString(kAlarmRingingTitleKey) ?? '';
    } catch (_) {}
    if (!mounted) return;
    if (ringing != _ringing || title != _title) {
      setState(() {
        _ringing = ringing;
        _title = title;
      });
    }
  }

  Future<void> _stopAll() async {
    if (_stopping) return;
    setState(() => _stopping = true);
    try {
      await NotificationService.stopAlarmSound();
    } catch (_) {}
    try {
      await PlannerAlarmHooks.stop?.call();
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(kAlarmRingingAtKey);
      await prefs.remove(kAlarmRingingTitleKey);
    } catch (_) {}
    // 화면이 꺼져 있을 때 뒤에서 울리던 알람에도 "꺼라" 신호
    try {
      FlutterForegroundTask.sendDataToTask('stop_alarm');
    } catch (_) {}
    // 알림창에 남아 있는 "알람 끄기" 알림도 지움 (예약해 둔 다른 알람은 건드리지 않음)
    try {
      final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
      final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final List<ActiveNotification>? active = await android?.getActiveNotifications();
      for (final ActiveNotification n in active ?? const <ActiveNotification>[]) {
        if (n.id != null && _loopingChannels.contains(n.channelId)) {
          await plugin.cancel(n.id!, tag: n.tag);
        }
      }
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
              Text(
                'ALARM',
                style: GoogleFonts.gowunBatang(color: _gold, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 3),
              ),
              const SizedBox(height: 6),
              Text(
                '알람이 울리고 있습니다',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              if (_title.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1527),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _gold.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansKr(color: _gold, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                '아래 버튼을 눌러 알람을 끄세요.',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(color: Colors.white60, fontSize: 14),
              ),
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
