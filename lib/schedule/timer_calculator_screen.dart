import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// 일반 플래너 전용 타이머 계산기.
/// 학생용 TimerScreen / Timer2Service / 학습기록과 완전히 분리한다.
class TimerCalculatorScreen extends StatefulWidget {
  const TimerCalculatorScreen({super.key});
  @override
  State<TimerCalculatorScreen> createState() => _TimerCalculatorScreenState();
}

class _TimerCalculatorScreenState extends State<TimerCalculatorScreen>
    with SingleTickerProviderStateMixin {
  static const bg = Color(0xFF030712);
  static const card = Color(0xFF0D1527);
  static const gold = Color(0xFFE5C158);
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: bg,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white70, size: 19),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('TIMER CALCULATOR',
            style: GoogleFonts.gowunBatang(
                color: gold,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: .8)),
        Text('타이머 계산기',
            style: GoogleFonts.notoSansKr(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 12)),
      ]),
    ),
    body: Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bg, Color(0xFF091225)])),
      child: SafeArea(
        top: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: gold.withOpacity(.35))),
              child: TabBar(
                controller: _tabs,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                    color: gold.withOpacity(.14),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: gold.withOpacity(.55))),
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: gold,
                unselectedLabelColor: Colors.white54,
                tabs: const [
                  Tab(icon: Icon(Icons.timer_outlined, size: 23), text: 'TIMER'),
                  Tab(icon: Icon(Icons.calculate_outlined, size: 23), text: 'CALCULATOR'),
                ],
              ),
            ),
          ),
          Expanded(child: TabBarView(controller: _tabs, children: const [
            _TimerTab(),
            _CalculatorTab(),
          ])),
        ]),
      ),
    ),
  );
}

class _TimerTab extends StatelessWidget {
  const _TimerTab();
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 2, 18, 30),
    children: const [
      _IntroCard(),
      SizedBox(height: 14),
      _CountdownCard(),
      SizedBox(height: 14),
      _StopwatchCard(),
      SizedBox(height: 14),
      _AlarmCard(),
      SizedBox(height: 14),
      _WorldClockCard(),
    ],
  );
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
          colors: [Color(0xFF111B31), Color(0xFF08101F)]),
      border: Border.all(color: const Color(0x55E5C158)),
      boxShadow: const [
        BoxShadow(color: Color(0x26000000), blurRadius: 18, offset: Offset(0, 8))
      ],
    ),
    child: Row(children: [
      Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x19E5C158),
              border: Border.all(color: const Color(0x66E5C158))),
          child: const Icon(Icons.auto_awesome_rounded,
              color: Color(0xFFE5C158), size: 28)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('EVERYDAY TIMER',
            style: GoogleFonts.gowunBatang(
                color: const Color(0xFFE5C158),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text('시간을 더 정확하게',
            style: GoogleFonts.notoSansKr(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 3),
        Text('측정 · 알람 · 세계시간을 한곳에서',
            style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11.5)),
      ])),
    ]),
  );
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.icon, required this.title, required this.subtitle, required this.child, this.trailing});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
    decoration: BoxDecoration(
        color: const Color(0xFF0D1527),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x35E5C158)),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 6))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: const Color(0x1AE5C158),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x35E5C158))),
            child: Icon(icon, color: const Color(0xFFE5C158), size: 23)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.gowunBatang(
                  color: const Color(0xFFE5C158), fontWeight: FontWeight.bold, fontSize: 14.5)),
          const SizedBox(height: 2),
          Text(subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 9.5)),
        ])),
        if (trailing != null) trailing!,
      ]),
      const SizedBox(height: 11),
      child,
    ]),
  );
}

class _GoldButton extends StatelessWidget {
  const _GoldButton(this.text, this.icon, this.onTap);
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        height: 45,
        decoration: BoxDecoration(color: const Color(0xFFE5C158), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: const Color(0xFF080F1E), size: 21),
          const SizedBox(width: 4),
          Text(text, style: GoogleFonts.notoSansKr(color: const Color(0xFF080F1E), fontWeight: FontWeight.bold, fontSize: 11.5)),
        ]),
      ),
    ),
  );
}

class _DarkButton extends StatelessWidget {
  const _DarkButton(this.text, this.icon, this.onTap);
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        height: 45,
        decoration: BoxDecoration(color: const Color(0xFF111B31), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white70, size: 21),
          const SizedBox(width: 4),
          Text(text, style: GoogleFonts.notoSansKr(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11.5)),
        ]),
      ),
    ),
  );

}

class _CountdownCard extends StatefulWidget {
  const _CountdownCard();
  @override
  State<_CountdownCard> createState() => _CountdownCardState();
}

class _CountdownCardState extends State<_CountdownCard> {
  final _h = FixedExtentScrollController();
  final _m = FixedExtentScrollController(initialItem: 10);
  final _s = FixedExtentScrollController();
  Timer? _timer;
  int _remaining = 0;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    _h.dispose();
    _m.dispose();
    _s.dispose();
    super.dispose();
  }

  int _wheel(FixedExtentScrollController c, int max) => c.hasClients ? c.selectedItem % max : 0;
  String _fmt(int n) {
    final h = n ~/ 3600;
    final m = (n % 3600) ~/ 60;
    final s = n % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _setTime() => setState(() {
    _remaining = _wheel(_h, 24) * 3600 + _wheel(_m, 60) * 60 + _wheel(_s, 60);
    _running = false;
    _timer?.cancel();
  });

  void _start() {
    if (_remaining <= 0) _setTime();
    if (_remaining <= 0) return;
    _timer?.cancel();
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= 1) {
        _timer?.cancel();
        setState(() {
          _remaining = 0;
          _running = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('시간측정이 완료되었습니다.')));
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _remaining = 0;
      _running = false;
    });
  }

  Widget _wheelView(FixedExtentScrollController c, int count, String label) => SizedBox(
    width: 78,
    height: 118,
    child: Column(children: [
      Expanded(
        child: ListWheelScrollView.useDelegate(
          controller: c,
          itemExtent: 34,
          diameterRatio: 1.25,
          physics: const FixedExtentScrollPhysics(),
          childDelegate: ListWheelChildLoopingListDelegate(
            children: List.generate(count, (i) => Center(
              child: Text(i.toString().padLeft(2, '0'), style: GoogleFonts.notoSans(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            )),
          ),
        ),
      ),
      Text(label, style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10)),
    ]),
  );

  @override
  Widget build(BuildContext context) => _ToolCard(
    icon: Icons.timer_outlined,
    title: '시간측정',
    subtitle: '위아래로 직접 시간을 선택하세요',
    child: Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFF080F1E), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0x35E5C158))),
        child: Column(children: [
          Text(_fmt(_remaining), style: GoogleFonts.notoSans(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w700, letterSpacing: 2)),
          if (!_running) const SizedBox(height: 7),
          if (!_running)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _wheelView(_h, 24, '시간'),
              _wheelView(_m, 60, '분'),
              _wheelView(_s, 60, '초'),
            ]),
        ]),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _GoldButton('설정', Icons.check_rounded, _setTime)),
        const SizedBox(width: 7),
        Expanded(child: _GoldButton(_running ? '일시정지' : '시작', _running ? Icons.pause_rounded : Icons.play_arrow_rounded, _running ? _pause : _start)),
        const SizedBox(width: 7),
        Expanded(child: _DarkButton('초기화', Icons.refresh_rounded, _reset)),
      ]),
    ]),
  );
}

class _StopwatchCard extends StatefulWidget {
  const _StopwatchCard();
  @override
  State<_StopwatchCard> createState() => _StopwatchCardState();
}

class _StopwatchCardState extends State<_StopwatchCard> {
  final _watch = Stopwatch();
  Timer? _timer;
  final List<String> _laps = [];
  String _format(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    final cs = (d.inMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0');
    return '$h:$m:$s.$cs';
  }
  void _start() {
    _watch.start();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) { if (mounted) setState(() {}); });
    setState(() {});
  }
  void _pause() { _watch.stop(); _timer?.cancel(); setState(() {}); }
  void _lap() { if (_watch.elapsedMilliseconds > 0) setState(() => _laps.insert(0, _format(_watch.elapsed))); }
  void _reset() { _watch.reset(); _timer?.cancel(); setState(() => _laps.clear()); }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) => _ToolCard(
    icon: Icons.av_timer_rounded,
    title: '스톱워치',
    subtitle: '현재보다 약 30% 크게 확대된 숫자',
    child: Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 5),
        decoration: BoxDecoration(color: const Color(0xFF080F1E), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0x35E5C158))),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(_format(_watch.elapsed), style: GoogleFonts.notoSans(color: Colors.white, fontSize: 43, fontWeight: FontWeight.w700, letterSpacing: 1.3))),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _GoldButton(_watch.isRunning ? '일시정지' : '시작', _watch.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, _watch.isRunning ? _pause : _start)),
        const SizedBox(width: 7),
        Expanded(child: _DarkButton('랩', Icons.flag_rounded, _lap)),
        const SizedBox(width: 7),
        Expanded(child: _DarkButton('초기화', Icons.refresh_rounded, _reset)),
      ]),
      if (_laps.isNotEmpty) ...[
        const SizedBox(height: 8),
        SizedBox(height: 110, child: ListView.builder(itemCount: _laps.length, itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('LAP ${_laps.length - i}', style: GoogleFonts.notoSans(color: const Color(0xFFE5C158), fontSize: 11, fontWeight: FontWeight.bold)),
            Text(_laps[i], style: GoogleFonts.notoSans(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
        ))),
      ],
    ]),
  );
}

class _AlarmCard extends StatefulWidget {
  const _AlarmCard();
  @override
  State<_AlarmCard> createState() => _AlarmCardState();
}

class _AlarmCardState extends State<_AlarmCard> {
  final _plugin = FlutterLocalNotificationsPlugin();
  final List<_AlarmItem> _alarms = [];
  bool _ready = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      tz_data.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone));
      const init = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(init, onDidReceiveNotificationResponse: (_) {});
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        'general_planner_alarm_v1', '일반 플래너 알람',
        description: '일반인용 타이머 계산기 알람', importance: Importance.max, playSound: true,
      ));
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('general_planner_alarm_list_v1');
      if (raw != null) {
        final list = (jsonDecode(raw) as List)
            .map((e) => _AlarmItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _alarms.addAll(list);
      }
      if (mounted) setState(() { _ready = true; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _ready = false; _loading = false; });
    }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('general_planner_alarm_list_v1', jsonEncode(_alarms.map((e) => e.toJson()).toList()));
  }

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      'general_planner_alarm_v1', '일반 플래너 알람',
      channelDescription: '일반인용 타이머 계산기 알람',
      importance: Importance.max, priority: Priority.max,
      playSound: true, enableVibration: true,
      category: AndroidNotificationCategory.alarm,
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true, sound: 'default'),
  );

  int _id(String key, int suffix) => (key.hashCode.abs() % 100000) * 10 + suffix;

  tz.TZDateTime _nextTime(int h, int m) {
    final now = tz.TZDateTime.now(tz.local);
    var d = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
    if (!d.isAfter(now)) d = d.add(const Duration(days: 1));
    return d;
  }

  tz.TZDateTime _nextWeekday(int weekday, int h, int m) {
    final now = tz.TZDateTime.now(tz.local);
    var d = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
    var add = (weekday - now.weekday) % 7;
    if (add < 0) add += 7;
    d = d.add(Duration(days: add));
    if (!d.isAfter(now)) d = d.add(const Duration(days: 7));
    return d;
  }

  Future<void> _schedule(_AlarmItem a) async {
    if (a.repeat == '1회') {
      final id = _id(a.id, 0);
      await _plugin.zonedSchedule(id, a.name, '알람 시간입니다.', _nextTime(a.hour, a.minute), _details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
      a.ids..clear()..add(id);
      return;
    }
    final ids = <int>[];
    if (a.repeat == '매일') {
      final id = _id(a.id, 0);
      await _plugin.zonedSchedule(id, a.name, '알람 시간입니다.', _nextTime(a.hour, a.minute), _details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time);
      ids.add(id);
    } else {
      final days = a.repeat == '평일'
          ? [1, 2, 3, 4, 5]
          : a.repeat == '주말'
          ? [6, 7]
          : a.weekdays;
      for (final day in days) {
        final id = _id(a.id, day);
        await _plugin.zonedSchedule(id, a.name, '알람 시간입니다.', _nextWeekday(day, a.hour, a.minute), _details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime);
        ids.add(id);
      }
    }
    a.ids..clear()..addAll(ids);
  }

  Future<void> _cancel(_AlarmItem a) async {
    for (final id in a.ids) {
      await _plugin.cancel(id);
    }
  }

  Future<void> _add() async {
    final a = await showDialog<_AlarmItem>(context: context, builder: (_) => const _AlarmDialog());
    if (a == null) return;
    if (!_ready) {
      _msg('알림 기능을 초기화하지 못했습니다. Android 알림 권한을 확인하세요.');
      return;
    }
    try {
      await _schedule(a);
      setState(() => _alarms.add(a));
      await _save();
      _msg('알람이 저장되었습니다.');
    } catch (_) {
      _msg('알람 설정에 실패했습니다. 정확한 알람 권한을 확인하세요.');
    }
  }

  Future<void> _toggle(_AlarmItem a, bool value) async {
    try {
      await _cancel(a);
      if (value) await _schedule(a);
      final i = _alarms.indexOf(a);
      if (i >= 0) setState(() => _alarms[i] = a.copyWith(enabled: value));
      await _save();
    } catch (_) {
      _msg('알람 상태 변경에 실패했습니다.');
    }
  }

  Future<void> _remove(_AlarmItem a) async {
    await _cancel(a);
    setState(() => _alarms.remove(a));
    await _save();
  }

  void _msg(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFF0D1527),
    content: Text(s, style: GoogleFonts.notoSansKr(color: Colors.white)),
  ));

  @override
  Widget build(BuildContext context) => _ToolCard(
    icon: Icons.alarm_outlined,
    title: '알람',
    subtitle: '1회 · 매일 · 평일 · 주말 · 사용자 지정 / 소리·진동',
    trailing: IconButton(onPressed: _loading ? null : _add, icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFE5C158), size: 29)),
    child: _loading
        ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFFE5C158))))
        : _alarms.isEmpty
        ? Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 21),
      decoration: BoxDecoration(color: const Color(0xFF080F1E), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        const Icon(Icons.alarm_add_rounded, color: Color(0xFFE5C158), size: 30),
        const SizedBox(height: 7),
        Text('등록된 알람이 없습니다.', style: GoogleFonts.notoSansKr(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
        Text('+ 버튼으로 알람을 추가하세요.', style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10.5)),
      ]),
    )
        : Column(children: _alarms.map((a) => _alarmTile(a)).toList()),
  );

  Widget _alarmTile(_AlarmItem a) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.fromLTRB(13, 10, 6, 10),
    decoration: BoxDecoration(color: const Color(0xFF080F1E), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x2EE5C158))),
    child: Row(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0x19E5C158), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.alarm_rounded, color: Color(0xFFE5C158), size: 26)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${a.hour.toString().padLeft(2, '0')}:${a.minute.toString().padLeft(2, '0')}', style: GoogleFonts.notoSans(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w700)),
        Text('${a.name} · ${a.repeat}', style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 10.5)),
      ])),
      Switch(value: a.enabled, activeColor: const Color(0xFFE5C158), onChanged: (v) => _toggle(a, v)),
      IconButton(onPressed: () => _remove(a), icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 22)),
    ]),
  );
}

class _AlarmDialog extends StatefulWidget {
  const _AlarmDialog();
  @override
  State<_AlarmDialog> createState() => _AlarmDialogState();
}

class _AlarmDialogState extends State<_AlarmDialog> {
  TimeOfDay _time = TimeOfDay.now();
  String _repeat = '1회';
  String _name = '일반 알람';
  final Set<int> _days = {};

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: const Color(0xFF0D1527),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: Text('알람 설정', style: GoogleFonts.notoSansKr(color: const Color(0xFFE5C158), fontWeight: FontWeight.bold)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      InkWell(
        onTap: () async {
          final t = await showTimePicker(context: context, initialTime: _time);
          if (t != null && mounted) setState(() => _time = t);
        },
        child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15), decoration: BoxDecoration(color: const Color(0xFF080F1E), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x55E5C158))), child: Center(child: Text(_time.format(context), style: GoogleFonts.notoSans(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700)))),
      ),
      const SizedBox(height: 12),
      TextField(style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: '알람명', labelStyle: TextStyle(color: Colors.white54)), onChanged: (v) => _name = v.trim().isEmpty ? '일반 알람' : v.trim()),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _repeat,
        dropdownColor: const Color(0xFF111B31),
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(labelText: '반복', labelStyle: TextStyle(color: Colors.white54)),
        items: const ['1회', '매일', '평일', '주말', '사용자 지정'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => setState(() => _repeat = v ?? '1회'),
      ),
      if (_repeat == '사용자 지정') ...[
        const SizedBox(height: 9),
        Wrap(spacing: 5, children: List.generate(7, (i) {
          final day = i + 1;
          const names = ['월', '화', '수', '목', '금', '토', '일'];
          final selected = _days.contains(day);
          return FilterChip(label: Text(names[i]), selected: selected, selectedColor: const Color(0x44E5C158), labelStyle: TextStyle(color: selected ? const Color(0xFFE5C158) : Colors.white70), onSelected: (v) => setState(() => v ? _days.add(day) : _days.remove(day)));
        })),
      ],
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.white54))),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5C158), foregroundColor: const Color(0xFF080F1E)),
        onPressed: () {
          if (_repeat == '사용자 지정' && _days.isEmpty) return;
          Navigator.pop(context, _AlarmItem(id: DateTime.now().microsecondsSinceEpoch.toString(), hour: _time.hour, minute: _time.minute, name: _name, repeat: _repeat, weekdays: _days.toList()..sort(), enabled: true));
        },
        child: const Text('저장'),
      ),
    ],
  );
}

class _AlarmItem {
  _AlarmItem({required this.id, required this.hour, required this.minute, required this.name, required this.repeat, required this.weekdays, required this.enabled, List<int>? ids}) : ids = ids ?? [];
  final String id;
  final int hour;
  final int minute;
  final String name;
  final String repeat;
  final List<int> weekdays;
  final bool enabled;
  final List<int> ids;
  _AlarmItem copyWith({bool? enabled}) => _AlarmItem(id: id, hour: hour, minute: minute, name: name, repeat: repeat, weekdays: List<int>.from(weekdays), enabled: enabled ?? this.enabled, ids: List<int>.from(ids));
  Map<String, dynamic> toJson() => {'id': id, 'hour': hour, 'minute': minute, 'name': name, 'repeat': repeat, 'weekdays': weekdays, 'enabled': enabled, 'ids': ids};
  factory _AlarmItem.fromJson(Map<String, dynamic> j) => _AlarmItem(
    id: j['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
    hour: (j['hour'] as num?)?.toInt() ?? 0,
    minute: (j['minute'] as num?)?.toInt() ?? 0,
    name: j['name']?.toString() ?? '일반 알람',
    repeat: j['repeat']?.toString() ?? '1회',
    weekdays: ((j['weekdays'] as List?) ?? const []).map((e) => (e as num).toInt()).toList(),
    enabled: j['enabled'] as bool? ?? true,
    ids: ((j['ids'] as List?) ?? const []).map((e) => (e as num).toInt()).toList(),
  );
}

class _WorldClockCard extends StatefulWidget {
  const _WorldClockCard();
  @override
  State<_WorldClockCard> createState() => _WorldClockCardState();
}

class _WorldClockCardState extends State<_WorldClockCard> {
  Timer? _ticker;
  DateTime _now = DateTime.now();
  static const cities = [
    ['서울', 'Seoul', 'Asia/Seoul', '🇰🇷'], ['도쿄', 'Tokyo', 'Asia/Tokyo', '🇯🇵'], ['싱가포르', 'Singapore', 'Asia/Singapore', '🇸🇬'],
    ['홍콩', 'Hong Kong', 'Asia/Hong_Kong', '🇭🇰'], ['방콕', 'Bangkok', 'Asia/Bangkok', '🇹🇭'], ['델리', 'Delhi', 'Asia/Kolkata', '🇮🇳'],
    ['두바이', 'Dubai', 'Asia/Dubai', '🇦🇪'], ['시드니', 'Sydney', 'Australia/Sydney', '🇦🇺'], ['파리', 'Paris', 'Europe/Paris', '🇫🇷'],
    ['런던', 'London', 'Europe/London', '🇬🇧'], ['베를린', 'Berlin', 'Europe/Berlin', '🇩🇪'], ['모스크바', 'Moscow', 'Europe/Moscow', '🇷🇺'],
    ['요하네스버그', 'Johannesburg', 'Africa/Johannesburg', '🇿🇦'], ['상파울루', 'São Paulo', 'America/Sao_Paulo', '🇧🇷'], ['뉴욕', 'New York', 'America/New_York', '🇺🇸'],
    ['토론토', 'Toronto', 'America/Toronto', '🇨🇦'], ['시카고', 'Chicago', 'America/Chicago', '🇺🇸'], ['로스앤젤레스', 'Los Angeles', 'America/Los_Angeles', '🇺🇸'],
    ['멕시코시티', 'Mexico City', 'America/Mexico_City', '🇲🇽'], ['오클랜드', 'Auckland', 'Pacific/Auckland', '🇳🇿'],
  ];
  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() => _now = DateTime.now()); });
  }
  @override
  void dispose() { _ticker?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => _ToolCard(
    icon: Icons.public_rounded,
    title: '세계시간',
    subtitle: '좌우로 스크롤하여 전 세계 주요 도시 확인',
    child: SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: cities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final c = cities[i];
          final local = tz.TZDateTime.from(_now, tz.getLocation(c[2]));
          final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
          return Container(
            width: 158,
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
            decoration: BoxDecoration(color: const Color(0xFF080F1E), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0x33E5C158))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${c[3]}  ${c[0]}', style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 3),
              Text(c[1], style: GoogleFonts.notoSans(color: Colors.white38, fontSize: 9.5)),
              const Spacer(),
              Text(time, style: GoogleFonts.notoSans(color: const Color(0xFFE5C158), fontSize: 26, fontWeight: FontWeight.w700)),
              Text('${local.month}/${local.day}', style: GoogleFonts.notoSans(color: Colors.white54, fontSize: 10)),
            ]),
          );
        },
      ),
    ),
  );
}

class _CalculatorTab extends StatefulWidget {
  const _CalculatorTab();
  @override
  State<_CalculatorTab> createState() => _CalculatorTabState();
}

class _CalculatorTabState extends State<_CalculatorTab> {
  String display = '0';
  double? first;
  String? op;
  bool fresh = true;
  bool currency = false;
  final amount = TextEditingController(text: '10000');
  String from = 'KRW';
  String to = 'USD';
  double rate = .00074;

  static const currencies = [
    ['대한민국', 'KRW', '원', '🇰🇷', '1350'], ['미국', 'USD', '달러', '🇺🇸', '1'], ['일본', 'JPY', '엔', '🇯🇵', '148'], ['유럽연합', 'EUR', '유로', '🇪🇺', '.86'],
    ['중국', 'CNY', '위안', '🇨🇳', '7.18'], ['영국', 'GBP', '파운드', '🇬🇧', '.74'], ['호주', 'AUD', '호주 달러', '🇦🇺', '1.54'], ['캐나다', 'CAD', '캐나다 달러', '🇨🇦', '1.38'],
    ['스위스', 'CHF', '프랑', '🇨🇭', '.80'], ['홍콩', 'HKD', '홍콩 달러', '🇭🇰', '7.82'], ['싱가포르', 'SGD', '싱가포르 달러', '🇸🇬', '1.28'], ['대만', 'TWD', '대만 달러', '🇹🇼', '32.4'],
    ['태국', 'THB', '바트', '🇹🇭', '35.2'], ['베트남', 'VND', '동', '🇻🇳', '25500'], ['인도', 'INR', '루피', '🇮🇳', '83.8'], ['뉴질랜드', 'NZD', '뉴질랜드 달러', '🇳🇿', '1.68'],
    ['스웨덴', 'SEK', '크로나', '🇸🇪', '9.45'], ['노르웨이', 'NOK', '크로네', '🇳🇴', '10.2'], ['덴마크', 'DKK', '크로네', '🇩🇰', '6.42'], ['아랍에미리트', 'AED', '디르함', '🇦🇪', '3.6725'],
  ];

  @override
  void dispose() { amount.dispose(); super.dispose(); }

  String fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(10).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  void key(String k) {
    setState(() {
      if (k == 'AC') { display = '0'; first = null; op = null; fresh = true; return; }
      if (k == '+/-') { if (display != '0') display = display.startsWith('-') ? display.substring(1) : '-$display'; return; }
      if (k == '%') { display = fmt((double.tryParse(display) ?? 0) / 100); fresh = true; return; }
      if ('0123456789.'.contains(k)) {
        if (fresh || display == '0') { display = k == '.' ? '0.' : k; fresh = false; }
        else if (k != '.' || !display.contains('.')) display += k;
        return;
      }
      if ('+-×÷'.contains(k)) {
        final cur = double.tryParse(display) ?? 0;
        if (first != null && op != null && !fresh) display = fmt(calc(first!, cur, op!));
        first = double.tryParse(display) ?? 0; op = k; fresh = true; return;
      }
      if (k == '=' && first != null && op != null) {
        display = fmt(calc(first!, double.tryParse(display) ?? 0, op!)); first = null; op = null; fresh = true;
      }
    });
  }
  double calc(double a, double b, String o) => o == '+' ? a + b : o == '-' ? a - b : o == '×' ? a * b : b == 0 ? 0 : a / b;
  double referenceRate(String a, String b) {
    double usd(String code) => double.parse(currencies.firstWhere((x) => x[1] == code)[4]);
    return usd(b) / usd(a);
  }

  Future<void> pickCurrency(bool isFrom) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0D1527),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(15, 12, 15, 30),
        itemCount: currencies.length,
        separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
        itemBuilder: (_, i) => ListTile(
          leading: Text(currencies[i][3], style: const TextStyle(fontSize: 23)),
          title: Text('${currencies[i][0]} · ${currencies[i][1]}', style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Text(currencies[i][2], style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10)),
          onTap: () => Navigator.pop(context, currencies[i][1]),
        ),
      ),
    );
    if (selected == null) return;
    setState(() { if (isFrom) from = selected; else to = selected; rate = referenceRate(from, to); });
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 2, 18, 30),
    children: [
      Container(
        height: 116,
        padding: const EdgeInsets.all(16),
        alignment: Alignment.bottomRight,
        decoration: BoxDecoration(color: const Color(0xFF080F1E), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x44E5C158))),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(display, style: GoogleFonts.notoSans(color: Colors.white, fontSize: 39, fontWeight: FontWeight.w700)),),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _mode('일반 계산', !currency, () => setState(() => currency = false))),
        const SizedBox(width: 8),
        Expanded(child: _mode('환율 계산', currency, () => setState(() => currency = true))),
      ]),
      const SizedBox(height: 10),
      currency ? _currencyView() : _calculatorView(),
    ],
  );

  Widget _mode(String text, bool selected, VoidCallback tap) => GestureDetector(
    onTap: tap,
    child: Container(height: 46, alignment: Alignment.center, decoration: BoxDecoration(color: selected ? const Color(0x24E5C158) : const Color(0xFF0D1527), borderRadius: BorderRadius.circular(13), border: Border.all(color: selected ? const Color(0x99E5C158) : Colors.white12)), child: Text(text, style: GoogleFonts.notoSansKr(color: selected ? const Color(0xFFE5C158) : Colors.white54, fontWeight: FontWeight.bold, fontSize: 12.5))),
  );

  Widget _calculatorView() {
    const rows = [['AC', '+/-', '%', '÷'], ['7', '8', '9', '×'], ['4', '5', '6', '-'], ['1', '2', '3', '+'], ['0', '.', '=']];
    return Column(children: rows.map((row) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: row.map((k) {
        final operator = '+-×÷='.contains(k);
        return Expanded(flex: k == '0' ? 2 : 1, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Material(color: Colors.transparent, child: InkWell(onTap: () => key(k), borderRadius: BorderRadius.circular(16), child: Ink(height: 67, decoration: BoxDecoration(color: operator ? const Color(0x22E5C158) : const Color(0xFF0D1527), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: Center(child: Text(k, style: GoogleFonts.notoSans(color: operator ? const Color(0xFFE5C158) : Colors.white, fontSize: operator ? 32 : 25, fontWeight: FontWeight.w700))))))));
      }).toList()),
    )).toList());
  }

  Widget _currencyView() {
    final input = double.tryParse(amount.text.replaceAll(',', '')) ?? 0;
    final output = input * rate;
    final f = currencies.firstWhere((x) => x[1] == from);
    final t = currencies.firstWhere((x) => x[1] == to);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFF0D1527), borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0x4DE5C158))),
      child: Column(children: [
        _currencyRow(f, true),
        IconButton(onPressed: () => setState(() { final x = from; from = to; to = x; rate = referenceRate(from, to); }), icon: const Icon(Icons.swap_vert_rounded, color: Color(0xFFE5C158), size: 34)),
        _currencyRow(t, false),
        const SizedBox(height: 12),
        Text('1 $from = ${rate.toStringAsFixed(6)} $to', style: GoogleFonts.notoSans(color: const Color(0xFFE5C158), fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text('20개 주요 통화를 표시합니다. 현재는 참고 환율로 계산하며, 최신 환율 API 연결 시 자동 갱신 구조로 확장합니다.', textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 9.5, height: 1.4)),
      ]),
    );
  }

  Widget _currencyRow(List<String> c, bool input) => Row(children: [
    InkWell(onTap: () => pickCurrency(input), borderRadius: BorderRadius.circular(12), child: Container(width: 145, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), decoration: BoxDecoration(color: const Color(0xFF080F1E), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)), child: Row(children: [Text(c[3], style: const TextStyle(fontSize: 21)), const SizedBox(width: 7), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c[1], style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)), Text(c[0], overflow: TextOverflow.ellipsis, style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 9.5))])), const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38, size: 18)]))),
    const SizedBox(width: 9),
    Expanded(child: input ? TextField(controller: amount, onChanged: (_) => setState(() {}), keyboardType: const TextInputType.numberWithOptions(decimal: true), style: GoogleFonts.notoSans(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w700), decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: '0')) : Text(outputText(c), textAlign: TextAlign.right, style: GoogleFonts.notoSans(color: const Color(0xFFE5C158), fontSize: 25, fontWeight: FontWeight.w700))),
  ]);

  String outputText(List<String> _) {
    final v = (double.tryParse(amount.text.replaceAll(',', '')) ?? 0) * rate;
    return v >= 100 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  }
}
