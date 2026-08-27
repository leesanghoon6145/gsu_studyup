import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/family_link_service.dart';

// ============================================================================
// 👑 [별 경제 시스템] DkeStars
// - 별(스타) 적립 속도, 전체 누적 저장, 레벨 계산을 이 파일 한 곳에서만 관리합니다.
// - timer_screen.dart가 이미 쓰고 있던 'stars_all_time_total' 키를 그대로 재사용해서
//   기존에 쌓인 데이터와 충돌 없이 이어집니다.
// - 다른 화면(member_achievement_screen.dart 등)은 항상 이 클래스를 통해서만
//   별/레벨을 읽고 씁니다. (여러 화면이 각자 SharedPreferences를 직접 건드리면
//   나중에 값이 어긋나는 사고가 나기 쉬워서, 이 파일 하나로 창구를 통일합니다.)
// 🆕 [Firebase 연동] addStars() 호출 시, 부모와 연결되어 있으면(family_link_code 존재)
//   자동으로 최신 별/레벨을 Firestore에도 함께 올립니다. 연결 안 되어 있으면 조용히 스킵.
// ============================================================================
class DkeStars {
  // ==========================================================================
  // 🧪 [테스트/실사용 전환 스위치] — 지금은 "1초에 별 1개"로 테스트합니다.
  // 실제 서비스로 전환할 때는 이 한 줄만 Duration(minutes: 1)로 바꾸면,
  // 타이머 자동 적립 로직 전체에 그대로 반영됩니다. (다른 파일은 손댈 필요 없음)
  // ==========================================================================
  static const Duration starAccrualInterval = Duration(minutes: 1); // 🆕 [실사용 전환] 1초 -> 1분으로 변경 완료

  // 👑 [레벨 공식] 별 500개당 1레벨. (별 0~499개 = 레벨 1, 500~999개 = 레벨 2, ...)
  static const int starsPerLevel = 500;

  static const String _kAllTimeTotalKey = 'stars_all_time_total';
  static const String _kDailyPrefix = 'stars_daily_';
  static const String _kSubjectPrefix = 'stars_subject_';

  static String _todayKey() {
    final now = DateTime.now();
    return '$_kDailyPrefix${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  // 🆕 별 [count]개를 전체 누적치 + 오늘 누적치 + (선택) 과목별 누적치에 더해서 저장.
  // 반환값 = 저장 후의 "전체 누적 별 개수".
  static Future<int> addStars(int count, {String? subject}) async {
    if (count <= 0) return getTotalStarsSync(await SharedPreferences.getInstance());

    final prefs = await SharedPreferences.getInstance();

    final int newAllTimeTotal = (prefs.getInt(_kAllTimeTotalKey) ?? 0) + count;
    await prefs.setInt(_kAllTimeTotalKey, newAllTimeTotal);

    final String todayKey = _todayKey();
    final int newTodayTotal = (prefs.getInt(todayKey) ?? 0) + count;
    await prefs.setInt(todayKey, newTodayTotal);

    if (subject != null && subject.isNotEmpty) {
      final String subjectKey = '$_kSubjectPrefix$subject';
      final int newSubjectTotal = (prefs.getInt(subjectKey) ?? 0) + count;
      await prefs.setInt(subjectKey, newSubjectTotal);
    }

    // 🆕 [Firebase 연동] 부모와 연결되어 있으면 최신 수치를 서버로 전송 (연결 안 됐으면 내부에서 조용히 스킵)
    // 실패해도(오프라인 등) 로컬 저장은 이미 끝났으므로 앱 사용에는 지장 없음.
    unawaited(FamilyLinkService.pushStudentStats(
      totalStars: newAllTimeTotal,
      todayStars: newTodayTotal,
      level: levelForStars(newAllTimeTotal),
    ));

    return newAllTimeTotal;
  }

  // 🆕 전체 누적 별 개수 조회
  static Future<int> getTotalStars() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kAllTimeTotalKey) ?? 0;
  }

  // 🆕 이미 열려있는 SharedPreferences 인스턴스가 있을 때 쓰는 동기 버전(내부용)
  static int getTotalStarsSync(SharedPreferences prefs) {
    return prefs.getInt(_kAllTimeTotalKey) ?? 0;
  }

  // 🆕 오늘 하루 누적 별 개수 조회
  static Future<int> getTodayStars() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_todayKey()) ?? 0;
  }

  // 🆕 특정 과목의 누적 별 개수 조회
  static Future<int> getSubjectStars(String subject) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_kSubjectPrefix$subject') ?? 0;
  }

  // 👑 [레벨 계산] 500개당 1레벨. 레벨은 1부터 시작.
  static int levelForStars(int totalStars) {
    if (totalStars < 0) return 1;
    return (totalStars ~/ starsPerLevel) + 1;
  }

  // 👑 현재 레벨 안에서 채운 별 개수 (0~499) — 다음 레벨까지의 진행률 표시용
  static int starsIntoCurrentLevel(int totalStars) {
    if (totalStars < 0) return 0;
    return totalStars % starsPerLevel;
  }

  // 👑 다음 레벨까지 남은 별 개수
  static int starsUntilNextLevel(int totalStars) {
    return starsPerLevel - starsIntoCurrentLevel(totalStars);
  }
}
