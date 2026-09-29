import '../global_lang.dart';

// ============================================================================
// 🆕 [2026-09-27] 장학금 화폐 자동 전환 (나라별 고정 단가표 · B안)
//
// - 앱 언어가 바뀌면 그 나라에서 쓰는 화폐로 자동 표시
//     KO 원(₩) / EN 달러($) / JA 엔(¥) / ZH 위안(元) / FR·DE·ES 유로(€)
//     RU 루블(₽) / AR 리얄(ر.س) / HI 루피(₹) / VI 동(₫) / TH 바트(฿)
// - 실시간 환율이 아니라, 나라별로 "자녀에게 주기 편한 둥근 금액"을 미리 정한 고정표
//   (환율이 바뀌어도 금액이 흔들리지 않음)
// - 계산: 이번 달 총 별 × 유형별 별 1개 단가 → 월 한도를 넘으면 한도 금액
//         → 그 나라 화폐 단위로 보기 좋게 반올림 (예: 달러 0.5, 엔 10, 동 1,000 단위)
// - 유형 순서: 0 성장형 / 1 도전형 / 2 성취형
// - 단가·한도·반올림 단위를 바꾸고 싶으면 아래 표의 숫자만 고치면 됨
// - 원화(KRW) 숫자는 기존 장학금 규칙(2·3·4원, 한도 2만·3만·5만)과 똑같음
// ============================================================================
class ScholarshipCurrency {
  ScholarshipCurrency._();

  // 언어 → 화폐
  static const Map<String, String> _langToCurrency = {
    'KO': 'KRW',
    'EN': 'USD',
    'JA': 'JPY',
    'ZH': 'CNY',
    'FR': 'EUR',
    'DE': 'EUR',
    'ES': 'EUR',
    'RU': 'RUB',
    'AR': 'SAR',
    'HI': 'INR',
    'VI': 'VND',
    'TH': 'THB',
  };

  // 별 1개 단가 [성장형, 도전형, 성취형]
  static const Map<String, List<double>> _rates = {
    'KRW': [2, 3, 4],
    'USD': [0.0015, 0.002, 0.003],
    'JPY': [0.2, 0.3, 0.4],
    'CNY': [0.01, 0.015, 0.02],
    'EUR': [0.0015, 0.002, 0.003],
    'RUB': [0.1, 0.15, 0.2],
    'SAR': [0.005, 0.0075, 0.01],
    'INR': [0.1, 0.15, 0.2],
    'VND': [30, 45, 60],
    'THB': [0.05, 0.075, 0.1],
  };

  // 월 한도 [성장형, 도전형, 성취형]
  static const Map<String, List<double>> _caps = {
    'KRW': [20000, 30000, 50000],
    'USD': [15, 20, 35],
    'JPY': [2000, 3000, 5000],
    'CNY': [100, 150, 250],
    'EUR': [15, 20, 35],
    'RUB': [1000, 1500, 2500],
    'SAR': [50, 75, 125],
    'INR': [1000, 1500, 2500],
    'VND': [300000, 450000, 750000],
    'THB': [500, 750, 1250],
  };

  // 주기 편한 반올림 단위
  static const Map<String, double> _step = {
    'KRW': 100,
    'USD': 0.5,
    'JPY': 10,
    'CNY': 1,
    'EUR': 0.5,
    'RUB': 10,
    'SAR': 1,
    'INR': 10,
    'VND': 1000,
    'THB': 5,
  };

  // 지금 앱 언어에 맞는 화폐 코드 (모르는 언어면 원화)
  static String get code => _langToCurrency[DkeLang.current] ?? 'KRW';

  static int _safeType(int typeIndex) => typeIndex.clamp(0, 2);

  static double _raw(int totalStars, int typeIndex) =>
      totalStars * _rates[code]![_safeType(typeIndex)];

  static double _roundStep(double v) {
    final double s = _step[code]!;
    return (v / s).round() * s;
  }

  // 최종 지급 금액 (한도 적용 + 반올림)
  static double amount(int totalStars, int typeIndex) {
    final double cap = _caps[code]![_safeType(typeIndex)];
    final double raw = _raw(totalStars, typeIndex);
    final double v = _roundStep(raw > cap ? cap : raw);
    return v > cap ? cap : v;
  }

  // 한도를 넘었는지
  static bool isCapped(int totalStars, int typeIndex) =>
      _raw(totalStars, typeIndex) > _caps[code]![_safeType(typeIndex)];

  // 화면 표시용 글자
  static String amountText(int totalStars, int typeIndex) => format(amount(totalStars, typeIndex));
  static String rawText(int totalStars, int typeIndex) => format(_roundStep(_raw(totalStars, typeIndex)));
  static String capText(int typeIndex) => format(_caps[code]![_safeType(typeIndex)]);
  static String rateText(int typeIndex) => format(_rates[code]![_safeType(typeIndex)], isRate: true);

  // 소수점 자리수: 단가는 필요한 만큼(최대 4자리), 금액은 정수면 0자리, 아니면 2자리
  static int _decimals(double v, bool isRate) {
    if (v == v.roundToDouble()) return 0;
    if (!isRate) return 2;
    for (int d = 1; d <= 4; d++) {
      final double m = v * _pow10(d);
      if ((m - m.round()).abs() < 1e-9) return d;
    }
    return 4;
  }

  static double _pow10(int d) {
    double r = 1;
    for (int i = 0; i < d; i++) {
      r *= 10;
    }
    return r;
  }

  static String _num(double v, int decimals, {String thousands = ',', String dec = '.'}) {
    final String s = v.toStringAsFixed(decimals);
    final List<String> parts = s.split('.');
    String intPart = parts[0];
    final bool neg = intPart.startsWith('-');
    if (neg) intPart = intPart.substring(1);
    final StringBuffer buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(thousands);
      buf.write(intPart[i]);
    }
    final String frac = decimals > 0 ? '$dec${parts[1]}' : '';
    return '${neg ? '-' : ''}$buf$frac';
  }

  // 나라마다 익숙한 모양으로 (기호 위치·천 단위 구분 기호)
  static String format(double v, {bool isRate = false}) {
    final int d = _decimals(v, isRate);
    switch (code) {
      case 'KRW':
        return '${_num(v, d)}원';
      case 'USD':
        return '\$${_num(v, d)}';
      case 'JPY':
        return '¥${_num(v, d)}';
      case 'CNY':
        return '${_num(v, d)} 元';
      case 'EUR':
        return '${_num(v, d, thousands: '.', dec: ',')} €';
      case 'RUB':
        return '${_num(v, d, thousands: ' ', dec: ',')} ₽';
      case 'SAR':
        return '${_num(v, d)} ر.س';
      case 'INR':
        return '₹${_num(v, d)}';
      case 'VND':
        return '${_num(v, d, thousands: '.', dec: ',')} ₫';
      case 'THB':
        return '฿${_num(v, d)}';
      default:
        return _num(v, d);
    }
  }
}
