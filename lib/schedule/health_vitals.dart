// ============================================================================
// 🆕 [2026-10-16] HealthVitals — 오늘의 건강: 혈압 · 혈당 · 심폐 체력 · 체성분
//
// 원장님 요청 (2026-10-16)
// · 운동 기록 화면 '오늘 심박' 카드 아래에 혈압 · 혈당 · 신체 체력지수(심폐 체력 + 체성분)를 함께 보여 줌
// · 삼성헬스 → 헬스 커넥트로 넘어온 값은 자동으로 채우고, 본인이 직접 써넣을 수도 있음
// · 직접 쓴 칸은 자동 값으로 덮어쓰지 않음 (칸을 비우고 저장하면 다시 자동)
//
// 어디서 오나
// · 혈압(수축기 · 이완기) · 혈당 · 체중 · 키 · 체지방률 → 헬스 커넥트에서 그날 가장 최근 값
// · 체질량지수(BMI) → 체중 ÷ (키 × 키) 로 앱이 계산
// · 심폐 체력(VO₂max) → 🆕 워치 '평상 심박'과 출생연도로 앱이 매일 자동 추정 (직접 입력하면 그 값 우선)
//     공식(Uth-Sørensen): 최대 심박 = 208 − 0.7 × 나이,  VO₂max ≈ 15.3 × 최대 심박 ÷ 평상 심박
// · 골격근량 → 지금 삼성헬스가 헬스 커넥트로 넘겨주지 않음 → 직접 입력
//
// 비용 · 개인정보
// · 폰 안의 헬스 커넥트에서 읽고 폰 안에만 저장 → 인터넷 · 서버를 쓰지 않음 (데이터 요금 0원)
// · 계정마다 따로 저장 (plannerScopedKey)
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'exercise_theme.dart';
import 'exercise_step_service.dart'; // 오늘 심박(평상) — 심폐 체력 자동 추정용
import 'planner_scope.dart';
import '../services/user_profile_service.dart'; // 🆕 회원가입 생년월일 → 출생연도

class DayVitals {
  int? sys; // 수축기 (mmHg)
  int? dia; // 이완기 (mmHg)
  DateTime? bpAt;
  int? glucose; // 혈당 (mg/dL)
  DateTime? glucoseAt;
  double? vo2max; // 심폐 체력 (mL/kg/min)
  double? weight; // kg
  double? heightCm; // cm
  double? fat; // 체지방률 %
  double? muscle; // 골격근량 kg
  DateTime? bodyAt;
  Set<String> manual; // 직접 쓴 칸 이름
  int? restHr; // 심폐 체력 추정에 쓴 평상 심박

  DayVitals({
    this.sys,
    this.dia,
    this.bpAt,
    this.glucose,
    this.glucoseAt,
    this.vo2max,
    this.weight,
    this.heightCm,
    this.fat,
    this.muscle,
    this.bodyAt,
    Set<String>? manual,
  }) : manual = manual ?? <String>{};

  double? get bmi {
    if (weight == null || heightCm == null || heightCm! < 50) return null;
    final double m = heightCm! / 100;
    return weight! / (m * m);
  }

  Map<String, dynamic> toJson() => {
    'sys': sys,
    'dia': dia,
    'bpAt': bpAt?.toIso8601String(),
    'glucose': glucose,
    'glucoseAt': glucoseAt?.toIso8601String(),
    'vo2max': vo2max,
    'weight': weight,
    'heightCm': heightCm,
    'fat': fat,
    'muscle': muscle,
    'bodyAt': bodyAt?.toIso8601String(),
    'manual': manual.toList(),
    'restHr': restHr,
  };

  static DayVitals fromJson(Map<String, dynamic> j) {
    DateTime? d(String k) => DateTime.tryParse('${j[k] ?? ''}');
    double? f(String k) => (j[k] as num?)?.toDouble();
    int? i(String k) => (j[k] as num?)?.toInt();
    return DayVitals(
      sys: i('sys'),
      dia: i('dia'),
      bpAt: d('bpAt'),
      glucose: i('glucose'),
      glucoseAt: d('glucoseAt'),
      vo2max: f('vo2max'),
      weight: f('weight'),
      heightCm: f('heightCm'),
      fat: f('fat'),
      muscle: f('muscle'),
      bodyAt: d('bodyAt'),
      manual: (j['manual'] is List) ? (j['manual'] as List).map((e) => '$e').toSet() : <String>{},
    )..restHr = i('restHr');
  }
}

class HealthVitals {
  HealthVitals._();

  static final Health _h = Health();
  static bool _configured = false;

  static const List<HealthDataType> _types = [
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
  ];
  static List<HealthDataAccess> get _access => List<HealthDataAccess>.filled(_types.length, HealthDataAccess.READ);

  static Future<void> _cfg() async {
    if (_configured) return;
    try {
      await _h.configure();
      _configured = true;
    } catch (e) {
      debugPrint('[HealthVitals] configure 오류: $e');
    }
  }

  static Future<bool> hasPermission() async {
    await _cfg();
    try {
      return await _h.hasPermissions(_types, permissions: _access) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestPermission() async {
    await _cfg();
    try {
      return await _h.requestAuthorization(_types, permissions: _access);
    } catch (e) {
      debugPrint('[HealthVitals] 권한 요청 오류: $e');
      return false;
    }
  }

  // ─── 출생연도 (심폐 체력 추정용, 한 번만 입력) ───
  static String get _birthKey => plannerScopedKey('gke_birth_year');

  /// 출생연도: ① 회원가입 때 넣은 생년월일 → ② 오늘의 건강에서 직접 넣은 값
  static Future<int?> birthYear() async {
    try {
      final int? fromProfile = await DkeUserProfile.getBirthYear();
      if (fromProfile != null) return fromProfile;
    } catch (_) {}
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_birthKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setBirthYear(int? y) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (y == null) {
        await prefs.remove(_birthKey);
      } else {
        await prefs.setInt(_birthKey, y);
        await DkeUserProfile.updateBirthYear(y); // 회원 정보에도 저장 → 다른 폰에서도 자동
      }
    } catch (_) {}
  }

  /// 심폐 체력(VO₂max) 추정 — Uth-Sørensen 공식
  static double? estimateVo2(int? restHr, int? birth, DateTime day) {
    if (restHr == null || birth == null || restHr < 35 || restHr > 110) return null;
    final int age = day.year - birth;
    if (age < 10 || age > 100) return null;
    final double hrMax = 208 - 0.7 * age;
    return double.parse((15.3 * hrMax / restHr).toStringAsFixed(1));
  }

  static String _key(DateTime d) =>
      plannerScopedKey('gke_day_vitals_${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');

  static Future<DayVitals> load(DateTime day) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_key(day));
      if (raw != null && raw.isNotEmpty) return DayVitals.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {}
    return DayVitals();
  }

  static Future<void> save(DateTime day, DayVitals v) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(day), jsonEncode(v.toJson()));
    } catch (_) {}
  }

  /// 가장 최근 값 하나 (값, 잰 시각)
  static Future<(double?, DateTime?)> _latest(HealthDataType t, DateTime from, DateTime to) async {
    try {
      final List<HealthDataPoint> pts =
      _h.removeDuplicates(await _h.getHealthDataFromTypes(types: [t], startTime: from, endTime: to));
      HealthDataPoint? best;
      for (final HealthDataPoint p in pts) {
        if (p.value is! NumericHealthValue) continue;
        if (best == null || p.dateTo.isAfter(best.dateTo)) best = p;
      }
      if (best == null) return (null, null);
      return ((best.value as NumericHealthValue).numericValue.toDouble(), best.dateTo);
    } catch (e) {
      debugPrint('[HealthVitals] 읽기 오류($t): $e');
      return (null, null);
    }
  }

  /// 헬스 커넥트에서 그날 값을 받아 직접 쓰지 않은 칸만 채우고 저장
  static Future<DayVitals> refresh(DateTime day) async {
    final DayVitals v = await load(day);
    if (!await hasPermission()) {
      await _autoVo2(day, v); // 심박 권한만 있어도 심폐 체력은 추정
      await save(day, v);
      return v;
    }
    final DateTime from = DateTime(day.year, day.month, day.day);
    final DateTime now = DateTime.now();
    final DateTime dayEnd = from.add(const Duration(days: 1));
    final DateTime to = dayEnd.isBefore(now) ? dayEnd : now;

    final (double? s, DateTime? sAt) = await _latest(HealthDataType.BLOOD_PRESSURE_SYSTOLIC, from, to);
    final (double? d, DateTime? _) = await _latest(HealthDataType.BLOOD_PRESSURE_DIASTOLIC, from, to);
    if (!v.manual.contains('bp') && s != null && d != null) {
      v.sys = s.round();
      v.dia = d.round();
      v.bpAt = sAt;
    }
    final (double? g, DateTime? gAt) = await _latest(HealthDataType.BLOOD_GLUCOSE, from, to);
    if (!v.manual.contains('glucose') && g != null) {
      // 헬스 커넥트가 mmol/L로 주는 경우(값이 40 미만)는 mg/dL로 바꿈
      v.glucose = (g < 40 ? g * 18.0 : g).round();
      v.glucoseAt = gAt;
    }
    // 체중 · 체지방률은 매일 재지 않으므로 최근 30일 중 가장 최근 값, 키는 최근 1년 값
    final DateTime bodyFrom = to.subtract(const Duration(days: 30));
    final (double? w, DateTime? wAt) = await _latest(HealthDataType.WEIGHT, bodyFrom, to);
    if (!v.manual.contains('weight') && w != null) {
      v.weight = double.parse(w.toStringAsFixed(1));
      v.bodyAt = wAt;
    }
    final (double? f, DateTime? fAt) = await _latest(HealthDataType.BODY_FAT_PERCENTAGE, bodyFrom, to);
    if (!v.manual.contains('fat') && f != null) {
      v.fat = double.parse(f.toStringAsFixed(1));
      v.bodyAt ??= fAt;
    }
    final (double? h, DateTime? _) = await _latest(HealthDataType.HEIGHT, to.subtract(const Duration(days: 365)), to);
    if (!v.manual.contains('height') && h != null) {
      v.heightCm = double.parse((h < 3 ? h * 100 : h).toStringAsFixed(1)); // 미터로 오면 cm로
    }
    await _autoVo2(day, v);
    await save(day, v);
    return v;
  }

  /// 직접 쓰지 않았으면 그날 평상 심박 + 출생연도로 심폐 체력 자동 추정
  static Future<void> _autoVo2(DateTime day, DayVitals v) async {
    if (v.manual.contains('vo2max')) return;
    try {
      final DayHeartStats? h = await HealthLink.dayHeartStats(day);
      final double? est = estimateVo2(h?.rest, await birthYear(), day);
      if (est != null) {
        v.vo2max = est;
        v.restHr = h?.rest;
      }
    } catch (_) {}
  }
}

// ============================================================================
// 🩺 오늘의 건강 카드 — 혈압 · 혈당 · 심폐 체력 · 체성분 (자동 + 직접 입력)
// ============================================================================
class HealthVitalsCard extends StatefulWidget {
  final DateTime day;
  const HealthVitalsCard({super.key, required this.day});

  @override
  State<HealthVitalsCard> createState() => _HealthVitalsCardState();
}

class _HealthVitalsCardState extends State<HealthVitalsCard> {
  static const Color _gold = ExerciseTheme.brandGolden;
  DayVitals _v = DayVitals();
  bool _perm = true;
  int? _birth; // 출생연도
  bool _busy = false;
  Timer? _retry;

  @override
  void initState() {
    super.initState();
    _refresh();
    // 삼성헬스 → 헬스 커넥트로 늦게 넘어오므로 화면이 열려 있는 동안 1분마다 다시 받음
    _retry = Timer.periodic(const Duration(seconds: 60), (_) => _refresh(quiet: true));
  }

  @override
  void didUpdateWidget(covariant HealthVitalsCard old) {
    super.didUpdateWidget(old);
    if (old.day != widget.day) _refresh();
  }

  @override
  void dispose() {
    _retry?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool quiet = false}) async {
    if (_busy) return;
    _busy = true;
    try {
      final bool p = await HealthVitals.hasPermission();
      final DayVitals v = await HealthVitals.refresh(widget.day);
      final int? by = await HealthVitals.birthYear();
      if (!mounted) return;
      setState(() {
        _perm = p;
        _v = v;
        _birth = by;
      });
    } finally {
      _busy = false;
    }
  }

  Future<void> _connect() async {
    await HealthVitals.requestPermission();
    await _refresh();
  }

  String _hm(DateTime? t) => t == null ? '' : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  String _md(DateTime? t) => t == null ? '' : '${t.month}/${t.day}';
  String _n(double? x, [int digits = 1]) => x == null ? '-' : x.toStringAsFixed(digits);

  // 혈압 판정 (대한고혈압학회 기준)
  (String, Color) _bpLevel(int s, int d) {
    if (s >= 140 || d >= 90) return ('고혈압', ExerciseTheme.dangerRed);
    if (s >= 130 || d >= 80) return ('고혈압 전단계', const Color(0xFFF59E0B));
    if (s >= 120) return ('주의 혈압', const Color(0xFFFBBF24));
    return ('정상', const Color(0xFF22C55E));
  }

  // 혈당 판정 (공복 기준, 참고용)
  (String, Color) _gluLevel(int g) {
    if (g >= 126) return ('높음', ExerciseTheme.dangerRed);
    if (g >= 100) return ('주의', const Color(0xFFF59E0B));
    if (g < 70) return ('낮음', const Color(0xFF60A5FA));
    return ('정상', const Color(0xFF22C55E));
  }

  // 심폐 체력 대략 구분 (성인 일반 기준, 참고용)
  Widget _vo2Tag(double x) {
    if (x >= 45) return _tag('아주 좋음', const Color(0xFF22C55E));
    if (x >= 38) return _tag('좋음', const Color(0xFF84CC16));
    if (x >= 30) return _tag('보통', const Color(0xFFFBBF24));
    return _tag('키워요', const Color(0xFFF59E0B));
  }

  Widget _tag(String text, Color c) => Container(
    margin: const EdgeInsets.only(left: 6),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(5), border: Border.all(color: c.withValues(alpha: 0.6))),
    child: Text(text, style: GoogleFonts.notoSansKr(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _row({
    required IconData icon,
    required Color iconColor,
    required String en,
    required String ko,
    required String value,
    String unit = '',
    Widget? tag,
    String sub = '',
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          SizedBox(
            width: 82,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(en, style: GoogleFonts.gowunBatang(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 9.5)),
                Text(ko, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(value,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.rajdhani(color: value == '-' ? Colors.white30 : Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
                    ),
                    if (unit.isNotEmpty && value != '-')
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 3),
                        child: Text(unit, style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    if (tag != null) tag,
                  ],
                ),
                if (sub.isNotEmpty) Text(sub, style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _src(String field, DateTime? at, {bool daily = true}) {
    if (_v.manual.contains(field)) return '직접 입력';
    if (at == null) return '';
    return daily ? '자동 · ${_hm(at)} 측정' : '자동 · ${_md(at)} 측정';
  }

  @override
  Widget build(BuildContext context) {
    final DayVitals v = _v;
    final bool hasBp = v.sys != null && v.dia != null;
    final (String, Color)? bpLv = hasBp ? _bpLevel(v.sys!, v.dia!) : null;
    final (String, Color)? gLv = v.glucose != null ? _gluLevel(v.glucose!) : null;
    final double? bmi = v.bmi;
    final List<String> bodyParts = <String>[
      if (v.weight != null) '체중 ${_n(v.weight)}kg',
      if (v.fat != null) '체지방 ${_n(v.fat)}%',
      if (v.muscle != null) '골격근 ${_n(v.muscle)}kg',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: ExerciseTheme.luxeCardDecoration(highlighted: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_heart_outlined, color: _gold, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("TODAY'S HEALTH", style: GoogleFonts.gowunBatang(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 9.5)),
                    Text('오늘의 건강', style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                tooltip: '다시 받기',
                onPressed: () => _refresh(),
                icon: const Icon(Icons.refresh_rounded, color: _gold, size: 20),
              ),
            ],
          ),
          if (!_perm)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: OutlinedButton.icon(
                onPressed: _connect,
                icon: const Icon(Icons.link_rounded, size: 16),
                label: Text('삼성헬스 혈압 · 혈당 · 체성분 연결하기', style: GoogleFonts.notoSansKr(fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(foregroundColor: _gold, side: BorderSide(color: _gold.withValues(alpha: 0.6))),
              ),
            ),
          _row(
            icon: Icons.bloodtype_outlined,
            iconColor: ExerciseTheme.dangerRed,
            en: 'BLOOD PRESSURE',
            ko: '혈압',
            value: hasBp ? '${v.sys} / ${v.dia}' : '-',
            unit: 'mmHg',
            tag: bpLv == null ? null : _tag(bpLv.$1, bpLv.$2),
            sub: _src('bp', v.bpAt),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          _row(
            icon: Icons.water_drop_outlined,
            iconColor: const Color(0xFF60A5FA),
            en: 'BLOOD GLUCOSE',
            ko: '혈당',
            value: v.glucose?.toString() ?? '-',
            unit: 'mg/dL',
            tag: gLv == null ? null : _tag(gLv.$1, gLv.$2),
            sub: _src('glucose', v.glucoseAt),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          _row(
            icon: Icons.air_rounded,
            iconColor: const Color(0xFF22C55E),
            en: 'VO2 MAX',
            ko: '심폐 체력',
            value: _n(v.vo2max),
            unit: 'mL/kg/min',
            tag: v.vo2max == null ? null : _vo2Tag(v.vo2max!),
            sub: v.manual.contains('vo2max')
                ? '직접 입력'
                : v.vo2max != null
                ? '자동 추정 · 평상 심박 ${v.restHr ?? '-'} · ${_birth != null ? '${widget.day.year - _birth!}세' : ''} 기준'
                : (_birth == null ? '[직접 입력]에서 출생연도를 넣으면 매일 자동 계산됩니다' : '워치 평상 심박이 들어오면 자동 계산됩니다'),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          _row(
            icon: Icons.accessibility_new_rounded,
            iconColor: _gold,
            en: 'BODY COMPOSITION',
            ko: '체성분',
            value: bmi == null ? '-' : 'BMI ${bmi.toStringAsFixed(1)}',
            sub: [
              if (bodyParts.isNotEmpty) bodyParts.join(' · '),
              if (bmi == null && v.weight != null && v.heightCm == null) '키를 넣으면 BMI가 계산됩니다',
              if (v.weight == null && v.fat == null && v.muscle == null) '워치 체성분 측정값이 자동으로 들어옵니다',
              if (_v.bodyAt != null && !_v.manual.contains('weight')) '자동 · ${_md(_v.bodyAt)} 측정',
            ].join('\n'),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text('삼성헬스 값은 자동으로 채워지고, 직접 고쳐 쓸 수도 있습니다 · 폰 안에만 저장',
                    style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10.5)),
              ),
              TextButton.icon(
                onPressed: _edit,
                icon: const Icon(Icons.edit_rounded, size: 15, color: _gold),
                label: Text('직접 입력', style: GoogleFonts.notoSansKr(color: _gold, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 직접 입력 창 — 칸을 비우면 다시 자동으로 ───
  Future<void> _edit() async {
    final DayVitals v = _v;
    String t(num? x, [int digits = 0]) => x == null ? '' : (digits == 0 ? x.round().toString() : x.toStringAsFixed(digits));
    final TextEditingController sys = TextEditingController(text: t(v.sys));
    final TextEditingController dia = TextEditingController(text: t(v.dia));
    final TextEditingController glu = TextEditingController(text: t(v.glucose));
    final TextEditingController vo2 = TextEditingController(text: t(v.vo2max, 1));
    final TextEditingController wt = TextEditingController(text: t(v.weight, 1));
    final TextEditingController ht = TextEditingController(text: t(v.heightCm, 1));
    final TextEditingController fat = TextEditingController(text: t(v.fat, 1));
    final TextEditingController mus = TextEditingController(text: t(v.muscle, 1));
    final TextEditingController birth = TextEditingController(text: _birth?.toString() ?? '');
    final bool vo2WasAuto = !v.manual.contains('vo2max');
    if (vo2WasAuto) vo2.text = ''; // 자동 추정값은 비워 둠 → 비워 두면 계속 자동

    Widget field(String label, TextEditingController c, String unit) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 12),
          suffixText: unit,
          suffixStyle: const TextStyle(color: Colors.white38),
          isDense: true,
          filled: true,
          fillColor: ExerciseTheme.pageBg,
          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white12), borderRadius: BorderRadius.circular(9)),
          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: _gold), borderRadius: BorderRadius.circular(9)),
        ),
      ),
    );

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ExerciseTheme.containerBg,
        shape: RoundedRectangleBorder(side: const BorderSide(color: _gold, width: 1.2), borderRadius: BorderRadius.circular(14)),
        title: Text('오늘의 건강 직접 입력', style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('칸을 비워 두면 삼성헬스 값이 자동으로 들어갑니다.',
                  style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11.5)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: field('혈압 수축기', sys, 'mmHg')),
                const SizedBox(width: 8),
                Expanded(child: field('이완기', dia, 'mmHg')),
              ]),
              field('혈당', glu, 'mg/dL'),
              Row(children: [
                Expanded(child: field('출생연도 (예: 1959)', birth, '년')),
                const SizedBox(width: 8),
                Expanded(child: field('심폐 체력 (비우면 자동)', vo2, 'mL/kg/min')),
              ]),
              Row(children: [
                Expanded(child: field('체중', wt, 'kg')),
                const SizedBox(width: 8),
                Expanded(child: field('키', ht, 'cm')),
              ]),
              Row(children: [
                Expanded(child: field('체지방률', fat, '%')),
                const SizedBox(width: 8),
                Expanded(child: field('골격근량', mus, 'kg')),
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('닫기', style: GoogleFonts.notoSansKr(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _gold),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('저장', style: GoogleFonts.notoSansKr(color: ExerciseTheme.pageBg, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    double? p(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.'));
    final DateTime now = DateTime.now();

    // 혈압
    final double? s = p(sys), d = p(dia);
    if (s != null && d != null) {
      if (!(v.manual.contains('bp') && v.sys == s.round() && v.dia == d.round())) v.bpAt = now;
      v.sys = s.round();
      v.dia = d.round();
      v.manual.add('bp');
    } else {
      v.manual.remove('bp');
      v.sys = null;
      v.dia = null;
      v.bpAt = null;
    }
    // 혈당
    final double? g = p(glu);
    if (g != null) {
      if (v.glucose != g.round()) v.glucoseAt = now;
      v.glucose = g.round();
      v.manual.add('glucose');
    } else {
      v.manual.remove('glucose');
      v.glucose = null;
      v.glucoseAt = null;
    }
    // 출생연도 (심폐 체력 자동 추정용)
    final int? by = int.tryParse(birth.text.trim());
    await HealthVitals.setBirthYear(by != null && by > 1900 && by <= now.year ? by : null);
    // 심폐 체력: 쓰면 직접 입력, 비우면 자동 추정
    final double? vo = p(vo2);
    if (vo != null) {
      v.vo2max = vo;
      v.manual.add('vo2max');
    } else {
      v.vo2max = null;
      v.manual.remove('vo2max');
    }
    // 골격근량 (직접 입력 전용)
    v.muscle = p(mus);
    v.muscle == null ? v.manual.remove('muscle') : v.manual.add('muscle');
    // 체중 · 키 · 체지방률
    final double? w = p(wt), h = p(ht), f = p(fat);
    if (w != null) {
      v.weight = w;
      v.manual.add('weight');
    } else {
      v.manual.remove('weight');
      v.weight = null;
    }
    if (h != null) {
      v.heightCm = h;
      v.manual.add('height');
    } else {
      v.manual.remove('height');
      v.heightCm = null;
    }
    if (f != null) {
      v.fat = f;
      v.manual.add('fat');
    } else {
      v.manual.remove('fat');
      v.fat = null;
    }
    await HealthVitals.save(widget.day, v);
    await _refresh(); // 비운 칸은 자동 값으로 다시 채움
  }
}
