import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🆕 [장학금 준비 2026-09-17] 계정별(uid) 데이터 분리용
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
//
// 🆕 [계정별 데이터 분리 2026-09-17] 예전엔 stars_all_time_total / stars_daily_* /
// stars_subject_* 키가 계정 구분 없이 폰 하나에 하나만 존재해서, 같은 폰에서 계정을
// 바꿔 로그인하면 이전 계정이 쌓아둔 별 총합이 새 계정에 그대로 이어지는 문제가 있었음
// (장학금 제도가 이 총합을 근거로 돈을 계산하므로 반드시 고쳐야 했던 부분).
// family_link_service.dart의 _scopedKey()와 동일한 패턴으로, 모든 키에 현재 로그인
// uid를 접미사로 붙여 계정별로 완전히 독립적으로 저장/조회되게 함.
// ⚠️ [의도적 결정 - B안] 기존에 쌓여 있던 uid-미분리 데이터는 자동으로 옮기지 않음.
// 이 수정 이후로는 uid별로 0부터 새로 쌓입니다(원장님 확인 완료: 테스트 단계라 이전
// 데이터의 의미가 없어 마이그레이션 없이 새로 시작하는 쪽을 선택함).
// 계산 로직(적립 속도, 레벨 공식) 자체는 이번 수정에서 단 한 줄도 바뀌지 않았습니다.
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

  // 🆕 [계정별 데이터 분리] 현재 로그인된 uid를 모든 키에 접미사로 붙임.
  // family_link_service.dart의 _scopedKey()와 완전히 동일한 패턴.
  static String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  static String _scopedKey(String base) {
    final String? uid = _currentUid;
    return uid == null ? base : '${base}_$uid';
  }

  static String _dateStamp(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  static String _todayKey() {
    final now = DateTime.now();
    return _scopedKey('$_kDailyPrefix${_dateStamp(now)}');
  }

  // 🆕 별 [count]개를 전체 누적치 + 오늘 누적치 + (선택) 과목별 누적치에 더해서 저장.
  // 반환값 = 저장 후의 "전체 누적 별 개수".
  static Future<int> addStars(int count, {String? subject}) async {
    if (count <= 0) return getTotalStarsSync(await SharedPreferences.getInstance());

    final prefs = await SharedPreferences.getInstance();

    final String allTimeKey = _scopedKey(_kAllTimeTotalKey);
    final int newAllTimeTotal = (prefs.getInt(allTimeKey) ?? 0) + count;
    await prefs.setInt(allTimeKey, newAllTimeTotal);

    final String todayKey = _todayKey();
    final int newTodayTotal = (prefs.getInt(todayKey) ?? 0) + count;
    await prefs.setInt(todayKey, newTodayTotal);

    if (subject != null && subject.isNotEmpty) {
      final String subjectKey = _scopedKey('$_kSubjectPrefix$subject');
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
    return prefs.getInt(_scopedKey(_kAllTimeTotalKey)) ?? 0;
  }

  // 🆕 이미 열려있는 SharedPreferences 인스턴스가 있을 때 쓰는 동기 버전(내부용)
  static int getTotalStarsSync(SharedPreferences prefs) {
    return prefs.getInt(_scopedKey(_kAllTimeTotalKey)) ?? 0;
  }

  // 🆕 오늘 하루 누적 별 개수 조회
  static Future<int> getTodayStars() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_todayKey()) ?? 0;
  }

  // 🆕 특정 과목의 누적 별 개수 조회
  static Future<int> getSubjectStars(String subject) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_scopedKey('$_kSubjectPrefix$subject')) ?? 0;
  }

  // ==========================================================================
  // 🆕 [장학금 준비 2026-09-17] 이번 달(1일~오늘) 누적 기본별 합산 조회.
  // 기존엔 "오늘"과 "전체 누적"만 있고 "이번 달" 집계가 없어서, 매일 쌓이는
  // stars_daily_* 항목들을 이번 달 범위로 순수 읽기(다시 계산/저장 없음)만 하는
  // 신규 함수. 별 적립 로직이나 기존 키 구조는 전혀 건드리지 않고, 이미 저장된
  // 일별 데이터를 그대로 합산하기만 함 — scholarship_service.dart가 이 값을
  // "월간 기본별"로 그대로 가져다 씀.
  // ==========================================================================
  static Future<int> getMonthlyBaseStars() async {
    final prefs = await SharedPreferences.getInstance();
    final Set<String> allKeys = prefs.getKeys();
    final DateTime now = DateTime.now();
    final String monthPrefix =
        '$_kDailyPrefix${now.year}${now.month.toString().padLeft(2, '0')}';
    final String? uid = _currentUid;

    int total = 0;
    for (final String key in allKeys) {
      String base = key;
      if (uid != null) {
        final String suffix = '_$uid';
        if (!key.endsWith(suffix)) continue;
        base = key.substring(0, key.length - suffix.length);
      }
      if (base.startsWith(monthPrefix)) {
        total += prefs.getInt(key) ?? 0;
      }
    }
    return total;
  }

  // ==========================================================================
  // 🆕 [장학금 방 - 출석 보너스 2026-09-17] 지정한 날짜 구간(start~end, 양끝 포함)의
  // "날짜별 기본별 개수"를 그대로 반환하는 읽기 전용 함수. 별 적립 로직이나 저장
  // 방식은 전혀 건드리지 않고, 이미 저장된 stars_daily_* 값을 날짜별로 꺼내오기만
  // 합니다. scholarship_service.dart가 일일/주간/월간 출석 보너스를 판정할 때
  // (하루 50개 이상인지, 특정 기간 내내 50개 이상이었는지) 이 함수만 사용합니다.
  // ==========================================================================
  static Future<Map<DateTime, int>> getDailyStarsInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<DateTime, int> result = {};
    DateTime cursor = DateTime(start.year, start.month, start.day);
    final DateTime endDay = DateTime(end.year, end.month, end.day);
    while (!cursor.isAfter(endDay)) {
      final String key = _scopedKey('$_kDailyPrefix${_dateStamp(cursor)}');
      result[cursor] = prefs.getInt(key) ?? 0;
      cursor = cursor.add(const Duration(days: 1));
    }
    return result;
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
