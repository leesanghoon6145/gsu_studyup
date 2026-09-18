import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../star_economy.dart';
import 'family_link_service.dart';

// ============================================================================
// 👑 [장학금 방 2026-09-17] ScholarshipService
//
// 절대 원칙: 이 파일은 timer_screen.dart / star_economy.dart의 기존 로직을
// 단 한 줄도 수정하지 않고, 오직 "이미 저장된 결과"만 읽어오거나, 완전히
// 새로운 별도의 데이터(보너스별)를 쌓습니다. 별이 적립되는 속도나 방식 자체는
// 이 파일이 절대 건드리지 않습니다.
//
// 구조:
// 1) 기본별(시간비례, 1분=1별) — DkeStars.getMonthlyBaseStars()에서 그대로 가져옴 (읽기 전용)
// 2) 이벤트 보너스별 — 학습 활동 발생 시 지급:
//    - 타이머 70% 이상 완주: +10 / 학습기록 작성 완료: +10
//    - 주간평가 +10 / 단원평가 +10 / 중간고사 +50 / 기말고사 +50 / 모의고사 +50
// 3) 🆕 [2026-09-17] 출석 보너스별 — 타이머가 실제로 작동한 "꾸준함"에 지급:
//    - 하루 50분(=기본별 50개) 이상 학습: +50 (그날 즉시 확정)
//    - 일주일(일~토) 매일 50개 이상: +300 (토요일에 조건 충족 시 확정)
//    - 한 달(1일~말일) 매일 50개 이상: +1,000 (그 달 마지막 날에 조건 충족 시 확정)
// 4) 위 세 종류를 전부 하나의 "총별"로 합산한 뒤, 부모가 선택한 유형
//    (성장형/도전형/성취형)에 따라 최종 장학금(원)을 계산.
//
// 호출 지점: timer_screen.dart의 두 곳에 기존 코드를 건드리지 않고 새 함수 호출
// 한 줄씩만 추가되어 있음(변경 없음, 그대로 재사용):
//   ① _showStudyInputFieldForm() 저장 버튼 안, pushSessionRecord() 다음 줄
//      → recordSessionCompletion() 호출 — 여기서 출석 보너스 판정도 함께 수행
//   ② appendExamRecord() 함수 끝 → recordExamCategoryBonus() 호출
// ============================================================================

enum ScholarshipType { growth, challenge, achievement }

class ScholarshipService {
  ScholarshipService._();

  // ---------------------------------------------------------------------
  // 계정별(uid) 스코프 — family_link_service.dart / star_economy.dart와
  // 동일한 패턴. 계정을 바꿔 로그인해도 서로 다른 학생의 보너스별이 섞이지 않음.
  // ---------------------------------------------------------------------
  static String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  static String _scopedKey(String base) {
    final String? uid = _currentUid;
    return uid == null ? base : '${base}_$uid';
  }

  static String _monthKey(DateTime d) => '${d.year}${d.month.toString().padLeft(2, '0')}';
  static String _dateKey(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------
  // 보너스 별 지급 액수 (학부모/학생 안내문에 명시된 값과 반드시 일치해야 함)
  // ---------------------------------------------------------------------
  static const int bonusTimer70Completion = 10;
  static const int bonusRecordWrite = 10;
  static const int bonusWeeklyAssessment = 10;
  static const int bonusUnitTest = 10;
  static const int bonusMidterm = 50;
  static const int bonusFinalExam = 50;
  static const int bonusMockExam = 50;

  // 🆕 [출석 보너스 2026-09-17] 하루 학습 인정 기준(기본별 개수, = 분) 및 지급 별 개수
  static const int dailyAttendanceThresholdStars = 50; // 하루 50분 이상 학습 = 기본별 50개 이상

  // 🆕 [허점 수정 2026-09-18 최종] 아래 두 기준선. 퍼센트가 아니라 전부
  // "타이머가 실제로 몇 분 작동했는가"라는 절대 시간 기준입니다.
  // ① 학습기록 작성 보너스: 예전엔 몇 초짜리 세션도 "기록만 저장하면" 무조건
  //    +10을 줬던 허점을 막기 위해, 타이머가 실제로 30분(1800초) 이상
  //    작동한 뒤 작성한 기록에만 지급됩니다.
  // ② 주간평가/단원평가 보너스: 타이머가 실제로 30분(1800초) 이상 작동한
  //    뒤 저장한 평가에만 지급됩니다.
  static const int recordWriteMinSeconds = 30 * 60; // 30분
  static const int examWeeklyUnitMinSeconds = 30 * 60; // 30분
  static const int bonusDailyAttendance = 50;
  static const int bonusWeeklyAttendance = 300;
  static const int bonusMonthlyAttendance = 1000;

  // ---------------------------------------------------------------------
  // 유형별 단가(원/별) / 성취보너스 상한(원) / 월 지급 한도(원)
  // ---------------------------------------------------------------------
  static const Map<ScholarshipType, int> starRateWon = {
    ScholarshipType.growth: 2,
    ScholarshipType.challenge: 3,
    ScholarshipType.achievement: 4,
  };

  static const Map<ScholarshipType, int> maxAchievementBonusWon = {
    ScholarshipType.growth: 3000,
    ScholarshipType.challenge: 5000,
    ScholarshipType.achievement: 10000,
  };

  static const Map<ScholarshipType, int> monthlyCapWon = {
    ScholarshipType.growth: 20000,
    ScholarshipType.challenge: 30000,
    ScholarshipType.achievement: 50000,
  };

  static const Map<ScholarshipType, String> typeLabelKo = {
    ScholarshipType.growth: '🌱 성장형',
    ScholarshipType.challenge: '🔥 도전형',
    ScholarshipType.achievement: '🏆 성취형',
  };

  static ScholarshipType? typeFromKey(String? key) {
    switch (key) {
      case 'growth':
        return ScholarshipType.growth;
      case 'challenge':
        return ScholarshipType.challenge;
      case 'achievement':
        return ScholarshipType.achievement;
      default:
        return null;
    }
  }

  static String typeToKey(ScholarshipType type) => type.name;

  // =======================================================================
  // 중복 지급 방지
  // 이벤트마다 고유 ID를 만들어 "이미 처리된 이벤트 목록"에 있으면 재지급하지
  // 않음. 목록은 최근 1000건만 유지(무한 증가 방지, star_economy.dart의
  // sessionHistory 트리밍과 동일한 패턴).
  // =======================================================================
  static const String _kProcessedEventsKey = 'scholarship_processed_events';
  static const int _kMaxProcessedEvents = 1000;

  static Future<bool> _isEventProcessed(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> processed = prefs.getStringList(_scopedKey(_kProcessedEventsKey)) ?? [];
    return processed.contains(eventId);
  }

  static Future<void> _markEventProcessed(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = _scopedKey(_kProcessedEventsKey);
    final List<String> processed = prefs.getStringList(key) ?? [];
    if (processed.contains(eventId)) return;
    processed.add(eventId);
    final List<String> trimmed = processed.length > _kMaxProcessedEvents
        ? processed.sublist(processed.length - _kMaxProcessedEvents)
        : processed;
    await prefs.setStringList(key, trimmed);
  }

  // =======================================================================
  // 보너스 별 저장 (월간 누적, uid별 완전 분리)
  // =======================================================================
  static const String _kBonusMonthPrefix = 'scholarship_bonus_month_';
  // 🆕 [보너스 항목별 세부 내역] "나의 성취별 현황" 화면에 항목별로 나열하기 위해,
  // 합계뿐 아니라 이벤트 타입별 개수도 함께 누적 저장.
  static const String _kBonusBreakdownPrefix = 'scholarship_bonus_breakdown_';

  static Future<void> _addBonusStars(int amount, String eventType) async {
    if (amount <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final String monthSuffix = _monthKey(DateTime.now());

    final String totalKey = _scopedKey('$_kBonusMonthPrefix$monthSuffix');
    final int currentTotal = prefs.getInt(totalKey) ?? 0;
    await prefs.setInt(totalKey, currentTotal + amount);

    final String breakdownKey = _scopedKey('$_kBonusBreakdownPrefix${monthSuffix}_$eventType');
    final int currentCount = prefs.getInt(breakdownKey) ?? 0;
    await prefs.setInt(breakdownKey, currentCount + 1);

    await _syncMonthlySummaryToFirestore();
  }

  // =======================================================================
  // ① 타이머 관련 이벤트 — timer_screen.dart의 저장 버튼 로직 끝에서 호출
  //
  // sessionEventId: 이 학습 세션 저장을 유일하게 식별할 수 있는 값.
  // (예: DateTime.now().toUtc().toString() — 이미 dkeFinalPacket['timestamp']로
  // 쓰이고 있는 값을 그대로 재사용하면 새 변수를 만들 필요도 없음)
  // =======================================================================
  static Future<void> recordSessionCompletion({
    required String sessionEventId,
    required int elapsedSeconds,
    required int totalSeconds,
  }) async {
    // 70% 이상 완주 보너스
    if (totalSeconds > 0 && (elapsedSeconds / totalSeconds) >= 0.7) {
      final String eventId = 'timer70_$sessionEventId';
      if (!await _isEventProcessed(eventId)) {
        await _addBonusStars(bonusTimer70Completion, 'timer70');
        await _markEventProcessed(eventId);
      }
    }

    // 🆕 [허점 수정 2026-09-18 최종] 학습기록 작성 완료 보너스 — 예전엔 저장
    // 버튼을 누르기만 하면(몇 초짜리 세션이든) 무조건 지급했던 허점을 막기 위해,
    // 타이머가 실제로 30분(1800초) 이상 작동한 세션에서만 지급됩니다.
    // (퍼센트가 아니라 절대 시간 비교)
    if (elapsedSeconds >= recordWriteMinSeconds) {
      final String recordEventId = 'recordwrite_$sessionEventId';
      if (!await _isEventProcessed(recordEventId)) {
        await _addBonusStars(bonusRecordWrite, 'recordwrite');
        await _markEventProcessed(recordEventId);
      }
    }

    // 🆕 [출석 보너스 2026-09-17] 매 세션 저장 시점마다 일일/주간/월간 출석 보너스도
    // 함께 확인. 타이머 로직은 전혀 건드리지 않고, 이미 쌓인 일별 기본별 데이터만
    // 읽어서 조건 충족 여부를 판정함.
    await _checkAttendanceBonuses();
  }

  // =======================================================================
  // 🆕 [출석 보너스 2026-09-17] 일일/주간/월간 출석 보너스 판정.
  // - 일일: 오늘(또는 최근 확인 안 된 과거 날짜)의 기본별이 50개 이상이면 즉시 확정.
  // - 주간: 오늘이 토요일이고, 이번 주(일~토) 7일 모두 50개 이상이면 확정.
  // - 월간: 오늘이 이번 달 마지막 날이고, 1일부터 오늘까지 매일 50개 이상이면 확정.
  // 전부 이미 저장된 일별 데이터(DkeStars.getDailyStarsInRange)만 읽어서 판정하며,
  // 중복 지급은 이벤트 ID(날짜/주/월 단위)로 방지됨.
  // =======================================================================
  static Future<void> _checkAttendanceBonuses() async {
    final DateTime today = DateTime.now();
    final DateTime todayDay = DateTime(today.year, today.month, today.day);
    final DateTime monthStart = DateTime(today.year, today.month, 1);

    final Map<DateTime, int> monthDaily = await DkeStars.getDailyStarsInRange(
      start: monthStart,
      end: todayDay,
    );

    // --- 일일 출석 보너스: 이번 달 안에서 아직 확정 안 된 날짜 중 50개 이상인 날 전부 지급 ---
    for (final entry in monthDaily.entries) {
      if (entry.value < dailyAttendanceThresholdStars) continue;
      final String eventId = 'dailyattend_${_dateKey(entry.key)}';
      if (await _isEventProcessed(eventId)) continue;
      await _addBonusStars(bonusDailyAttendance, 'dailyattend');
      await _markEventProcessed(eventId);
    }

    // --- 주간 출석 보너스: 오늘이 토요일(weekday==6)일 때만 그 주(일~토) 판정 ---
    // Dart의 DateTime.weekday: 월=1 ... 토=6, 일=7
    if (todayDay.weekday == 6) {
      final DateTime weekStart = todayDay.subtract(const Duration(days: 6)); // 지난 일요일
      final Map<DateTime, int> weekDaily = await DkeStars.getDailyStarsInRange(
        start: weekStart,
        end: todayDay,
      );
      final bool fullWeek = weekDaily.length == 7 &&
          weekDaily.values.every((v) => v >= dailyAttendanceThresholdStars);
      if (fullWeek) {
        final String eventId = 'weeklyattend_${_dateKey(weekStart)}';
        if (!await _isEventProcessed(eventId)) {
          await _addBonusStars(bonusWeeklyAttendance, 'weeklyattend');
          await _markEventProcessed(eventId);
        }
      }
    }

    // --- 월간 출석 보너스: 오늘이 이번 달 마지막 날일 때만 1일~오늘 전체 판정 ---
    final DateTime nextMonth = DateTime(today.year, today.month + 1, 1);
    final DateTime lastDayOfMonth = nextMonth.subtract(const Duration(days: 1));
    if (todayDay.year == lastDayOfMonth.year &&
        todayDay.month == lastDayOfMonth.month &&
        todayDay.day == lastDayOfMonth.day) {
      final bool fullMonth = monthDaily.values.every((v) => v >= dailyAttendanceThresholdStars) &&
          monthDaily.length == lastDayOfMonth.day;
      if (fullMonth) {
        final String eventId = 'monthlyattend_${_monthKey(today)}';
        if (!await _isEventProcessed(eventId)) {
          await _addBonusStars(bonusMonthlyAttendance, 'monthlyattend');
          await _markEventProcessed(eventId);
        }
      }
    }
  }

  // 🆕 [허점 수정 2026-09-18 최종] elapsedSeconds 파라미터 신규 추가. 주간평가/
  // 단원평가는 실제 타이머 작동시간이 30분(1800초) 미만이면 보너스를 지급하지
  // 않습니다. 이 값은 timer_screen.dart의 appendExamRecord()가 이미 갖고 있는
  // _elapsedSeconds를 그대로 넘겨받아 판정만 하며, 성적 저장(시험 점수 기록
  // 자체)은 이 함수가 불리기 전에 이미 끝난 상태라 전혀 영향받지 않습니다 —
  // 즉 30분 미만이어도 시험 점수는 정상 기록되고, 보너스별만 안 붙습니다.
  static Future<void> recordExamCategoryBonus({
    required String examCategory, // 주평가/단원평가/중간고사/기말고사/모의고사
    required String examRecordId,
    required int elapsedSeconds,
  }) async {
    final int amount;
    final String eventType;
    switch (examCategory) {
      case '주평가':
      // 🆕 타이머 30분 미만이면 조건 미충족 — 보너스 없이 조용히 종료
        if (elapsedSeconds < examWeeklyUnitMinSeconds) return;
        amount = bonusWeeklyAssessment;
        eventType = 'weekly';
        break;
      case '단원평가':
        if (elapsedSeconds < examWeeklyUnitMinSeconds) return;
        amount = bonusUnitTest;
        eventType = 'unittest';
        break;
      case '중간고사':
        amount = bonusMidterm;
        eventType = 'midterm';
        break;
      case '기말고사':
        amount = bonusFinalExam;
        eventType = 'final';
        break;
      case '모의고사':
        amount = bonusMockExam;
        eventType = 'mock';
        break;
      default:
        return; // 알 수 없는 유형은 조용히 무시(방어적 처리)
    }

    final String eventId = 'exam_${eventType}_$examRecordId';
    if (await _isEventProcessed(eventId)) return;
    await _addBonusStars(amount, eventType);
    await _markEventProcessed(eventId);
  }

  // =======================================================================
  // 월간 집계 조회
  // =======================================================================
  static Future<int> getMonthlyBonusStars() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = _scopedKey('$_kBonusMonthPrefix${_monthKey(DateTime.now())}');
    return prefs.getInt(key) ?? 0;
  }

  // 🆕 [나의 성취별 현황용] 이번 달 보너스별 항목별 개수
  // (예: {'timer70': 12, 'recordwrite': 12, 'weekly': 4, 'dailyattend': 20, ...})
  static Future<Map<String, int>> getMonthlyBonusBreakdown() async {
    final prefs = await SharedPreferences.getInstance();
    final String monthSuffix = _monthKey(DateTime.now());
    final List<String> types = [
      'timer70', 'recordwrite', 'weekly', 'unittest', 'midterm', 'final', 'mock',
      'dailyattend', 'weeklyattend', 'monthlyattend', // 🆕 출석 보너스 3종
    ];
    final Map<String, int> result = {};
    for (final t in types) {
      final key = _scopedKey('$_kBonusBreakdownPrefix${monthSuffix}_$t');
      final int count = prefs.getInt(key) ?? 0;
      if (count > 0) result[t] = count;
    }
    return result;
  }

  // 기본별(시간비례)은 star_economy.dart에서 그대로 읽어옴 — 이 파일은 절대 재계산하지 않음
  static Future<int> getMonthlyBaseStars() => DkeStars.getMonthlyBaseStars();

  static Future<int> getMonthlyTotalStars() async {
    final int base = await getMonthlyBaseStars();
    final int bonus = await getMonthlyBonusStars();
    return base + bonus;
  }

  // =======================================================================
  // 유형별 최종 금액 계산 (순수 함수 — 부모 화면에서 유형 선택 시 즉시 호출)
  //
  // 🆕 [2026-09-17 최종 확정 - 재수정] "성취보너스(원화 별도 가산)"는 삭제함.
  // 이벤트 보너스 7종 + 출석 보너스 3종은 전부 이미 "별"로 환산되어 총별
  // (monthlyTotalStars)에 포함되어 있으므로, 원화로 된 성취보너스를 여기에
  // 다시 더하면 이중 가산이 됨. 학부모 안내문(kScholarshipParentNoticeText)에
  // 명시된 계산 방식과 완전히 일치시킴.
  //
  // 공식: MIN[월간 누적 총별 × 유형별 단가, 유형별 월한도]
  // =======================================================================
  static int calculateAmountWon({
    required int monthlyTotalStars,
    required ScholarshipType type,
  }) {
    final int rate = starRateWon[type]!;
    final int cap = monthlyCapWon[type]!;
    final int raw = monthlyTotalStars * rate;
    return raw > cap ? cap : raw;
  }

  // =======================================================================
  // Firestore 동기화 — 학생 쪽에서 보너스별이 쌓일 때마다 월간 요약을
  // links/{code} 문서에 올려서, 학부모 화면이 이 값을 그대로 읽을 수 있게 함.
  // =======================================================================
  static Future<void> _syncMonthlySummaryToFirestore() async {
    try {
      final int base = await getMonthlyBaseStars();
      final int bonus = await getMonthlyBonusStars();
      final Map<String, int> breakdown = await getMonthlyBonusBreakdown();
      await FamilyLinkService.pushScholarshipData(
        monthKey: _monthKey(DateTime.now()),
        monthlyBaseStars: base,
        monthlyBonusStars: bonus,
        bonusBreakdown: breakdown,
      );
    } catch (e) {
      // 🆕 실패해도 로컬 저장(보너스별 자체)은 이미 끝났으므로 학생 화면엔 영향 없음. 조용히 무시.
      // (family_link_service.dart의 다른 push* 함수들과 동일한 에러 처리 패턴)
    }
  }
}
