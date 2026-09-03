import 'package:shared_preferences/shared_preferences.dart';
import '../star_economy.dart';

// ============================================================================
// 👑 [자기주도학습 장학금] ScholarshipService
// - DkeStars가 이미 저장하고 있는 일별 별 개수(stars_daily_YYYYMMDD)를 그대로 읽어서
//   장학금을 계산합니다. star_economy.dart 파일 자체는 수정하지 않고, 이미 공개된
//   키 형식(stars_daily_ + yyyyMMdd)과 levelForStars()/getTotalStars() 정적 함수만
//   재사용합니다.
// - 별 1개 = 3원 환산이 모든 유형의 공통 기준입니다.
// - 유형별 월 최대 한도: 기본형 15,000원 / 동기부여형 30,000원 / 챔피언형 50,000원
// ============================================================================

enum ScholarshipType { basic, motivation, champion }

extension ScholarshipTypeCap on ScholarshipType {
  int get monthlyCap {
    switch (this) {
      case ScholarshipType.basic:
        return 15000;
      case ScholarshipType.motivation:
        return 30000;
      case ScholarshipType.champion:
        return 50000;
    }
  }
}

class ScholarshipResult {
  final ScholarshipType type;
  final int starToMoney; // 별 환산액 (이번 달)
  final int attendanceBonus; // 주간 출석 보너스 합계 (이번 달)
  final int streakBonus; // 7일 연속 출석 보너스 합계 (이번 달)
  final int levelUpBonus; // 레벨업 보너스 (챔피언형만, 0이면 미해당)
  final int rawTotal; // 캡 적용 전 합계
  final int finalTotal; // 캡 적용 후 최종 금액 (실제 지급액)
  final int cappedAway; // 캡 때문에 못 받은 금액 (0이면 캡에 안 걸림)

  ScholarshipResult({
    required this.type,
    required this.starToMoney,
    required this.attendanceBonus,
    required this.streakBonus,
    required this.levelUpBonus,
    required this.rawTotal,
    required this.finalTotal,
    required this.cappedAway,
  });
}

class ScholarshipService {
  ScholarshipService._();

  static const String _kDailyPrefix = 'stars_daily_';
  static const int _wonPerStar = 3;
  static const String _kSelectedTypeKey = 'scholarship_selected_type';

  // 🆕 선택된 장학금 유형 저장/조회 (부모 1명당 1개 선택, 기기 로컬 저장)
  static Future<ScholarshipType> getSelectedType() async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_kSelectedTypeKey);
    switch (saved) {
      case 'motivation':
        return ScholarshipType.motivation;
      case 'champion':
        return ScholarshipType.champion;
      case 'basic':
        return ScholarshipType.basic;
      default:
        return ScholarshipType.motivation; // 기본값: 동기부여형
    }
  }

  static Future<void> setSelectedType(ScholarshipType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSelectedTypeKey, type.name);
  }

  static String _dailyKeyFor(DateTime d) =>
      '$_kDailyPrefix${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  static int _starsOnDate(SharedPreferences prefs, DateTime d) =>
      prefs.getInt(_dailyKeyFor(d)) ?? 0;

  // 이번 달 1일부터 오늘까지의 [날짜 → 별 개수] 맵
  static Map<DateTime, int> _monthDailyStars(
      SharedPreferences prefs, DateTime monthStart, DateTime today) {
    final Map<DateTime, int> map = {};
    DateTime cursor = monthStart;
    while (!cursor.isAfter(today)) {
      map[cursor] = _starsOnDate(prefs, cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return map;
  }

  // ISO 기준 주 시작일(월요일) 계산
  static DateTime _weekStartOf(DateTime d) {
    final DateTime dayOnly = DateTime(d.year, d.month, d.day);
    return dayOnly.subtract(Duration(days: dayOnly.weekday - 1)); // 월=1 ... 일=7
  }

  // 주간 출석 보너스: 이번 달에 걸친 각 주(월~일)마다 "50분(=별 50개) 이상 학습한 날"이
  // 주 5일 기준 몇 % 채워졌는지로 등급을 매깁니다.
  // 100% 이상 = 5000 / 80% 이상 = 3000 / 50% 이상 = 2000 / 미달 = 0
  static int _computeWeeklyAttendanceBonus(Map<DateTime, int> monthDaily) {
    if (monthDaily.isEmpty) return 0;
    final Map<DateTime, List<int>> byWeek = {};
    monthDaily.forEach((date, stars) {
      final weekStart = _weekStartOf(date);
      byWeek.putIfAbsent(weekStart, () => []).add(stars);
    });

    int total = 0;
    byWeek.forEach((weekStart, starsList) {
      final int attendedDays = starsList.where((s) => s >= 50).length;
      final double rate = (attendedDays / 5.0).clamp(0.0, 1.0);
      if (rate >= 1.0) {
        total += 5000;
      } else if (rate >= 0.8) {
        total += 3000;
      } else if (rate >= 0.5) {
        total += 2000;
      }
    });
    return total;
  }

  // 7일 연속 출석(50분 이상) 보너스: 이번 달 안에서 연속 7일 달성이 몇 번 있었는지
  // (겹치지 않게) 세어서 매번 2000원씩 지급합니다.
  static int _computeStreakBonus(Map<DateTime, int> monthDaily) {
    final sortedDates = monthDaily.keys.toList()..sort();
    int streak = 0;
    int bonus = 0;
    for (final date in sortedDates) {
      final bool attended = (monthDaily[date] ?? 0) >= 50;
      if (attended) {
        streak++;
        if (streak == 7) {
          bonus += 2000;
          streak = 0; // 겹치지 않게 다음 7일부터 다시 카운트
        }
      } else {
        streak = 0;
      }
    }
    return bonus;
  }

  // 챔피언형 전용 - 이번 달 안에 레벨업이 몇 번 있었는지 추정합니다.
  // (레벨업이 "언제" 일어났는지는 별도로 기록되지 않으므로, "이번 달 시작 전까지의
  //  누적 별 개수로 계산한 레벨"과 "현재 누적 별 개수로 계산한 레벨"의 차이로 근사합니다.)
  static Future<int> _computeLevelUpBonus(
      SharedPreferences prefs, DateTime monthStart) async {
    final Set<String> allKeys = prefs.getKeys();
    int starsBeforeMonth = 0;
    for (final key in allKeys.where((k) => k.startsWith(_kDailyPrefix))) {
      final String dateStr = key.substring(_kDailyPrefix.length);
      if (dateStr.length != 8) continue;
      try {
        final int y = int.parse(dateStr.substring(0, 4));
        final int m = int.parse(dateStr.substring(4, 6));
        final int d = int.parse(dateStr.substring(6, 8));
        final DateTime date = DateTime(y, m, d);
        if (date.isBefore(monthStart)) {
          starsBeforeMonth += prefs.getInt(key) ?? 0;
        }
      } catch (_) {
        // 손상된 키 1건은 건너뛰고 계속 집계
      }
    }
    final int totalStarsNow = await DkeStars.getTotalStars();
    final int levelBefore = DkeStars.levelForStars(starsBeforeMonth);
    final int levelNow = DkeStars.levelForStars(totalStarsNow);
    final int levelUps = (levelNow - levelBefore).clamp(0, 999);
    return levelUps * 1000;
  }

  // 🆕 메인 계산 함수 - 지정된 유형으로 "이번 달" 장학금을 계산합니다.
  static Future<ScholarshipResult> calculate(ScholarshipType type) async {
    final prefs = await SharedPreferences.getInstance();
    final DateTime now = DateTime.now();
    final DateTime monthStart = DateTime(now.year, now.month, 1);
    final DateTime today = DateTime(now.year, now.month, now.day);

    final Map<DateTime, int> monthDaily =
    _monthDailyStars(prefs, monthStart, today);
    final int totalStarsThisMonth =
    monthDaily.values.fold(0, (a, b) => a + b);
    final int starToMoney = totalStarsThisMonth * _wonPerStar;

    int attendanceBonus = 0;
    int streakBonus = 0;
    int levelUpBonus = 0;

    if (type == ScholarshipType.motivation || type == ScholarshipType.champion) {
      attendanceBonus = _computeWeeklyAttendanceBonus(monthDaily);
      streakBonus = _computeStreakBonus(monthDaily);
    }
    if (type == ScholarshipType.champion) {
      levelUpBonus = await _computeLevelUpBonus(prefs, monthStart);
    }

    final int rawTotal = starToMoney + attendanceBonus + streakBonus + levelUpBonus;
    final int cap = type.monthlyCap;
    final int finalTotal = rawTotal > cap ? cap : rawTotal;
    final int cappedAway = rawTotal > cap ? (rawTotal - cap) : 0;

    return ScholarshipResult(
      type: type,
      starToMoney: starToMoney,
      attendanceBonus: attendanceBonus,
      streakBonus: streakBonus,
      levelUpBonus: levelUpBonus,
      rawTotal: rawTotal,
      finalTotal: finalTotal,
      cappedAway: cappedAway,
    );
  }
}
