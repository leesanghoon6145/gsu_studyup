import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// ============================================================================
// 🆕 [부모 운동 응원별 2026-09-29] 운동 별 통장 서비스 (단일 게이트웨이)
// ----------------------------------------------------------------------------
// - 서버 문서: exerciseStarBanks/{uid}  (본인만 읽고 쓰기)
//     balance      : 지금 통장에 남아 있는 별 (보내면 줄어듦)
//     totalEarned  : 지금까지 모은 별 전체 (보내도 줄지 않음)
//     totalSent    : 지금까지 자녀에게 보낸 별 전체
//     dailyMinutes : 날짜별 운동 시간(분) - 최근 62일만 보관
//     awardedKeys  : 이미 받은 보너스 표시 - 같은 보너스 두 번 지급 방지
//     familyCheck  : 🆕 [가족 활동 체크] 날짜별 항목 칸 수 + '_stars' - 최근 3일만 보관
//     monthly      : 🆕 달별 수집 내역 - 최근 12달만 보관 (checkStars = 가족 활동 별)
//         { '202609': { timeStars, bonusStars, bonusCounts{record,d60,streak,week,month}, minutes, sent } }
// - 학생 별(star_economy.dart)·장학금(scholarship_service.dart)과는 완전히 별개.
//   이 파일은 그 두 파일을 절대 부르지 않음.
// ============================================================================

class ExerciseSessionResult {
  final int bonusStars;
  // 🆕 [다국어 2026-09-29] 받은 보너스 종류 이름표 ('record', 'd60', 'streak', 'week', 'month').
  // 화면이 이 이름표로 12개 언어 번역(cheer_stars_i18n.dart의 'bonus_…')을 찾아 보여줌.
  final List<String> bonusKeys;

  const ExerciseSessionResult({required this.bonusStars, required this.bonusKeys});

  static const ExerciseSessionResult empty = ExerciseSessionResult(bonusStars: 0, bonusKeys: []);
}

class ExerciseStarService {
  ExerciseStarService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'exerciseStarBanks';

  // ---------------------------------------------------------------------------
  // 별 적립 규칙 (2026-09-27 확정)
  // ---------------------------------------------------------------------------
  static const int secondsPerStar = 300; // 운동 5분 = 별 1개
  static const int bonusRecord = 5; // 운동 기록 (5분 이상 운동한 기록, 하루 3번까지)
  static const int maxRecordBonusPerDay = 3;
  static const int bonus60Min = 10; // 하루 합계 60분 이상
  static const int bonusStreakDay = 10; // 어제에 이어 오늘도 운동
  static const int bonusFullWeek = 10; // 일~토 하루도 빠짐없이
  static const int bonusFullMonth = 100; // 한 달 하루도 빠짐없이
  static const int minMinutesForDay = 5; // 하루 합계 이만큼 해야 "운동한 날"로 인정
  static const int maxStarsPerSend = 2500; // 한 번에 보낼 수 있는 최대 개수 (약 1만 원)

  // ---------------------------------------------------------------------------
  // 🆕 [가족 활동 체크 2026-09-30] 운동할 시간이 없는 부모도 자녀를 위한 작은 노력을
  // 체크해서 별을 모음. 같은 별 통장에 쌓이고, 하루 최대 20개 (타이머 별과는 별도 한도).
  // ---------------------------------------------------------------------------
  static const int familyDailyCap = 20;
  static const List<String> familyGroups = ['body', 'heart', 'family', 'self'];
  static const List<FamilyCheckItemDef> familyCheckItems = [
    // 🚶 짧은 몸 활동
    FamilyCheckItemDef(key: 'walk', group: 'body', starsPerUnit: 1, unitSize: 5, unitType: 'min', maxUnits: 6),
    FamilyCheckItemDef(key: 'stretch', group: 'body', starsPerUnit: 1, unitSize: 10, unitType: 'min', maxUnits: 3),
    FamilyCheckItemDef(key: 'stairs', group: 'body', starsPerUnit: 1, unitSize: 50, unitType: 'stairs', maxUnits: 4),
    FamilyCheckItemDef(key: 'steps', group: 'body', starsPerUnit: 1, unitSize: 500, unitType: 'steps', maxUnits: 10),
    // 💬 자녀와 마음
    FamilyCheckItemDef(key: 'cheerMsg', group: 'heart', starsPerUnit: 2, unitSize: 1, unitType: 'times', maxUnits: 2, auto: true),
    FamilyCheckItemDef(key: 'talk', group: 'heart', starsPerUnit: 2, unitSize: 1, unitType: 'times', maxUnits: 2),
    FamilyCheckItemDef(key: 'homework', group: 'heart', starsPerUnit: 2, unitSize: 1, unitType: 'times', maxUnits: 1),
    FamilyCheckItemDef(key: 'praise', group: 'heart', starsPerUnit: 1, unitSize: 1, unitType: 'times', maxUnits: 2),
    FamilyCheckItemDef(key: 'meal', group: 'heart', starsPerUnit: 1, unitSize: 1, unitType: 'times', maxUnits: 2),
    // 👨‍👩‍👧 가족 활동
    FamilyCheckItemDef(key: 'familyWalk', group: 'family', starsPerUnit: 3, unitSize: 1, unitType: 'times', maxUnits: 1),
    FamilyCheckItemDef(key: 'readTogether', group: 'family', starsPerUnit: 2, unitSize: 1, unitType: 'times', maxUnits: 1),
    FamilyCheckItemDef(key: 'outing', group: 'family', starsPerUnit: 5, unitSize: 1, unitType: 'times', maxUnits: 1),
    // 🌱 부모 자기 관리
    FamilyCheckItemDef(key: 'reading', group: 'self', starsPerUnit: 1, unitSize: 10, unitType: 'min', maxUnits: 2),
    FamilyCheckItemDef(key: 'earlySleep', group: 'self', starsPerUnit: 1, unitSize: 1, unitType: 'times', maxUnits: 1),
  ];

  static FamilyCheckItemDef? familyItem(String key) {
    for (final i in familyCheckItems) {
      if (i.key == key) return i;
    }
    return null;
  }

  /// 체크 횟수(칸 수)로 별 개수 계산
  static int familyStarsOf(Map<String, int> units) {
    int total = 0;
    for (final item in familyCheckItems) {
      total += (units[item.key] ?? 0) * item.starsPerUnit;
    }
    return total;
  }

  // 🆕 보너스 종류 (화면의 "보너스 별 상세 내역"에서 이 순서로 보여줌)
  // 이름은 cheer_stars_i18n.dart의 'bonus_record' 등에서 12개 언어로 꺼내 씀
  static const List<String> bonusCategories = ['record', 'd60', 'streak', 'week', 'month'];
  static const Map<String, int> bonusCategoryStars = {
    'record': bonusRecord,
    'd60': bonus60Min,
    'streak': bonusStreakDay,
    'week': bonusFullWeek,
    'month': bonusFullMonth,
  };

  static DocumentReference<Map<String, dynamic>>? _myDoc() {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection(_collection).doc(uid);
  }

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 🆕 달 이름표 (예: 2026년 9월 → '202609')
  static String monthKey(DateTime d) => '${d.year}${d.month.toString().padLeft(2, '0')}';

  // 최근 12달만 남기고 오래된 달은 정리
  static void _trimMonthly(Map<String, dynamic> monthly) {
    final List<String> keys = monthly.keys.toList()..sort();
    while (keys.length > 12) {
      monthly.remove(keys.removeAt(0));
    }
  }

  /// 🆕 [가족 활동 체크] 특정 날짜('yyyy-MM-dd')에 저장된 체크 칸 수 (없으면 빈 맵)
  static Future<Map<String, int>> getFamilyCheckDay(String dayKey) async {
    final ref = _myDoc();
    if (ref == null) return {};
    try {
      final snap = await ref.get();
      final Map<String, dynamic> fc = Map<String, dynamic>.from((snap.data()?['familyCheck'] as Map?) ?? {});
      final Map<String, dynamic> day = Map<String, dynamic>.from((fc[dayKey] as Map?) ?? {});
      final Map<String, int> result = {};
      day.forEach((k, v) {
        if (!k.startsWith('_') && v is num) result[k] = v.toInt();
      });
      return result;
    } catch (e) {
      debugPrint('[ExerciseStarService] getFamilyCheckDay 실패: $e');
      return {};
    }
  }

  /// 🆕 [가족 활동 체크] 저장. 오늘은 늘리기·줄이기 모두, 어제는 늘리기만 가능.
  /// 성공하면 (늘어난 별 수, null), 실패하면 (0, 오류 이름표)
  ///   'fcErrLogin' / 'fcErrDay' / 'fcErrLimit' / 'fcErrSpent' / 'errNetwork'
  static Future<(int, String?)> saveFamilyCheck({required String dayKey, required Map<String, int> units}) async {
    final ref = _myDoc();
    if (ref == null) return (0, 'fcErrLogin');
    final DateTime now = DateTime.now();
    final String todayKey = dateKey(now);
    final String yesterdayKey = dateKey(now.subtract(const Duration(days: 1)));
    if (dayKey != todayKey && dayKey != yesterdayKey) return (0, 'fcErrDay');
    final bool isToday = dayKey == todayKey;

    try {
      return await _db.runTransaction<(int, String?)>((tx) async {
        final snap = await tx.get(ref);
        final Map<String, dynamic> data = snap.data() ?? {};
        final Map<String, dynamic> fc = Map<String, dynamic>.from((data['familyCheck'] as Map?) ?? {});
        final Map<String, dynamic> oldDay = Map<String, dynamic>.from((fc[dayKey] as Map?) ?? {});
        final int oldStars = (oldDay['_stars'] as num?)?.toInt() ?? 0;

        final Map<String, int> newUnits = {};
        for (final item in familyCheckItems) {
          final int old = (oldDay[item.key] as num?)?.toInt() ?? 0;
          if (item.auto) {
            newUnits[item.key] = old; // 자동 인정 항목은 화면에서 못 바꿈
            continue;
          }
          int u = (units[item.key] ?? 0).clamp(0, item.maxUnits).toInt();
          if (!isToday && u < old) u = old; // 어제 것은 늘리기만
          newUnits[item.key] = u;
        }
        final int newStars = familyStarsOf(newUnits);
        if (newStars > familyDailyCap) return (0, 'fcErrLimit');
        final int delta = newStars - oldStars;
        final int balance = (data['balance'] as num?)?.toInt() ?? 0;
        if (balance + delta < 0) return (0, 'fcErrSpent'); // 이미 자녀에게 보낸 별은 되돌릴 수 없음
        if (delta == 0) return (0, null);

        final Map<String, dynamic> newDay = {...newUnits, '_stars': newStars};
        fc[dayKey] = newDay;
        final List<String> days = fc.keys.toList()..sort();
        while (days.length > 3) {
          fc.remove(days.removeAt(0)); // 최근 3일만 보관
        }

        final Map<String, dynamic> monthly = Map<String, dynamic>.from((data['monthly'] as Map?) ?? {});
        final String mk = monthKey(DateTime.parse(dayKey));
        final Map<String, dynamic> thisMonth = Map<String, dynamic>.from((monthly[mk] as Map?) ?? {});
        thisMonth['checkStars'] = ((thisMonth['checkStars'] as num?)?.toInt() ?? 0) + delta;
        monthly[mk] = thisMonth;
        _trimMonthly(monthly);

        final Map<String, dynamic> payload = {
          'balance': balance + delta,
          'totalEarned': ((data['totalEarned'] as num?)?.toInt() ?? 0) + delta,
          'familyCheck': fc,
          'monthly': monthly,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (snap.exists) {
          tx.update(ref, payload);
        } else {
          tx.set(ref, payload);
        }
        return (delta, null);
      });
    } catch (e) {
      debugPrint('[ExerciseStarService] saveFamilyCheck 실패: $e');
      return (0, 'errNetwork');
    }
  }

  /// 🆕 [가족 활동 체크] 자녀에게 응원을 보내면 자동으로 "응원 문자" 별 2개 (하루 2회까지, 하루 한도 안에서)
  static Future<void> creditCheerMessage() async {
    final ref = _myDoc();
    if (ref == null) return;
    final String todayKey = dateKey(DateTime.now());
    const String key = 'cheerMsg';
    final FamilyCheckItemDef item = familyItem(key)!;
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final Map<String, dynamic> data = snap.data() ?? {};
        final Map<String, dynamic> fc = Map<String, dynamic>.from((data['familyCheck'] as Map?) ?? {});
        final Map<String, dynamic> day = Map<String, dynamic>.from((fc[todayKey] as Map?) ?? {});
        final int units = (day[key] as num?)?.toInt() ?? 0;
        final int stars = (day['_stars'] as num?)?.toInt() ?? 0;
        if (units >= item.maxUnits || stars + item.starsPerUnit > familyDailyCap) return;

        day[key] = units + 1;
        day['_stars'] = stars + item.starsPerUnit;
        fc[todayKey] = day;
        final List<String> days = fc.keys.toList()..sort();
        while (days.length > 3) {
          fc.remove(days.removeAt(0));
        }
        final Map<String, dynamic> monthly = Map<String, dynamic>.from((data['monthly'] as Map?) ?? {});
        final String mk = monthKey(DateTime.now());
        final Map<String, dynamic> thisMonth = Map<String, dynamic>.from((monthly[mk] as Map?) ?? {});
        thisMonth['checkStars'] = ((thisMonth['checkStars'] as num?)?.toInt() ?? 0) + item.starsPerUnit;
        monthly[mk] = thisMonth;
        _trimMonthly(monthly);

        final Map<String, dynamic> payload = {
          'balance': ((data['balance'] as num?)?.toInt() ?? 0) + item.starsPerUnit,
          'totalEarned': ((data['totalEarned'] as num?)?.toInt() ?? 0) + item.starsPerUnit,
          'familyCheck': fc,
          'monthly': monthly,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (snap.exists) {
          tx.update(ref, payload);
        } else {
          tx.set(ref, payload);
        }
      });
    } catch (e) {
      debugPrint('[ExerciseStarService] creditCheerMessage 실패: $e');
    }
  }

  /// 내 별 통장을 실시간으로 지켜봄 (화면 표시용). 로그인 안 했으면 null.
  static Stream<DocumentSnapshot<Map<String, dynamic>>>? watchMyBank() => _myDoc()?.snapshots();

  /// 지금 통장에 남아 있는 별 (보내기 창을 열 때 한 번 조회)
  static Future<int> getMyBalance() async {
    final ref = _myDoc();
    if (ref == null) return 0;
    try {
      final snap = await ref.get();
      return (snap.data()?['balance'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('[ExerciseStarService] getMyBalance 실패: $e');
      return 0;
    }
  }

  /// 🆕 [2026-09-30] 보내기 창 위쪽 요약용: (총 모은 별, 보낸 별, 현재 남은 별)
  static Future<(int, int, int)> getMyBankSummary() async {
    final ref = _myDoc();
    if (ref == null) return (0, 0, 0);
    try {
      final data = (await ref.get()).data() ?? {};
      return (
      (data['totalEarned'] as num?)?.toInt() ?? 0,
      (data['totalSent'] as num?)?.toInt() ?? 0,
      (data['balance'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('[ExerciseStarService] getMyBankSummary 실패: $e');
      return (0, 0, 0);
    }
  }

  /// 자녀에게 별 보내기. 내 통장에서 빼고 자녀 문서(links/{code})에 더하는 일을
  /// 한 번에(트랜잭션) 처리 — 중간에 끊겨도 별이 사라지거나 두 번 들어가지 않음.
  /// 자녀 문서에 쌓이는 칸 (자녀 본인 별·장학금과 완전히 별개):
  ///   parentGiftStars        : 부모에게 받은 별 전체
  ///   parentGiftSpecialStars : 그중 특별 축하로 받은 별
  ///   parentGiftHistory      : 최근 50번의 보낸 기록 (개수·한마디·방식·시각)
  /// 성공하면 null, 실패하면 오류 이름표를 돌려줌 (화면이 12개 언어로 바꿔 보여줌)
  ///   'errLogin' / 'errCount' / 'errBalanceLow:{남은 별}' / 'errCap' / 'errNoLink' / 'errNetwork'
  static Future<String?> sendStarsToChild({
    required String code,
    required int stars,
    required String message,
    required bool isSpecial,
    String fromName = '', // 🆕 [응원 가족 2026-09-30] 보낸 사람 이름
    String fromRelation = 'guardian', // 🆕 보낸 사람 관계 (mom / grandma 등)
    String fromRelationText = '', // 🆕 관계가 "기타"일 때 직접 쓴 말
    bool asSupporter = false, // 🆕 true = 응원 가족 (아이 문서는 읽지 못하므로 gifts 기록만 남김)
  }) async {
    final bankRef = _myDoc();
    if (bankRef == null) return 'errLogin';
    if (stars <= 0) return 'errCount';
    final linkRef = _db.collection('links').doc(code);
    final giftRef = linkRef.collection('gifts').doc(); // 🆕 누가·몇 개 보냈는지 한 장씩 기록

    try {
      await _db.runTransaction((tx) async {
        final bankSnap = await tx.get(bankRef);
        final DocumentSnapshot<Map<String, dynamic>>? linkSnap = asSupporter ? null : await tx.get(linkRef);

        final Map<String, dynamic> bankData = bankSnap.data() ?? {};
        final int balance = (bankData['balance'] as num?)?.toInt() ?? 0;
        if (stars > balance) throw StateError('errBalanceLow:$balance');
        if (!isSpecial && stars > maxStarsPerSend) throw StateError('errCap');
        if (!asSupporter && !(linkSnap?.exists ?? false)) throw StateError('errNoLink');

        // 🆕 [2026-09-30] 오늘 보낸 사람이 한 일(가족 활동 체크 항목 + 운동 시간)을 함께 담아,
        // 아이 카드에 "오늘 할머니의 노력: 걷기 · 운동 30분"으로 보여줌
        final String todayKey = dateKey(DateTime.now());
        final Map<String, dynamic> fcAll = Map<String, dynamic>.from((bankData['familyCheck'] as Map?) ?? {});
        final Map<String, dynamic> fcToday = Map<String, dynamic>.from((fcAll[todayKey] as Map?) ?? {});
        final List<String> acts = [];
        fcToday.forEach((k, v) {
          if (!k.startsWith('_') && k != 'cheerMsg' && v is num && v > 0) acts.add(k);
        });
        final Map<String, dynamic> dailyAll = Map<String, dynamic>.from((bankData['dailyMinutes'] as Map?) ?? {});
        final int exMin = (dailyAll[todayKey] as num?)?.toInt() ?? 0;

        // 🆕 이번 달 "보낸 별"도 함께 기록
        final Map<String, dynamic> monthly = Map<String, dynamic>.from((bankData['monthly'] as Map?) ?? {});
        final String mk = monthKey(DateTime.now());
        final Map<String, dynamic> thisMonth = Map<String, dynamic>.from((monthly[mk] as Map?) ?? {});
        thisMonth['sent'] = ((thisMonth['sent'] as num?)?.toInt() ?? 0) + stars;
        monthly[mk] = thisMonth;
        _trimMonthly(monthly);

        tx.update(bankRef, {
          'balance': balance - stars,
          'totalSent': FieldValue.increment(stars),
          'monthly': monthly,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 보호자(부모)는 예전처럼 아이 문서의 합계·최근 기록도 함께 갱신
        if (!asSupporter) {
          final Map<String, dynamic> linkData = linkSnap!.data() ?? {};
          final List<dynamic> history = List<dynamic>.from((linkData['parentGiftHistory'] as List?) ?? []);
          history.add({
            'stars': stars,
            'message': message,
            'type': isSpecial ? 'special' : 'normal',
            'sentAt': Timestamp.now(), // 목록 안에서는 서버 시각을 쓸 수 없어 기기 시각 사용
            'acts': acts,
            'exMin': exMin,
          });
          while (history.length > 50) {
            history.removeAt(0);
          }
          tx.update(linkRef, {
            'parentGiftStars': ((linkData['parentGiftStars'] as num?)?.toInt() ?? 0) + stars,
            'parentGiftSpecialStars': ((linkData['parentGiftSpecialStars'] as num?)?.toInt() ?? 0) + (isSpecial ? stars : 0),
            'parentGiftHistory': history,
            'parentGiftUpdatedAt': FieldValue.serverTimestamp(),
          });
        }

        // 🆕 [가족 장학금 2026-10-02] 응원 가족은 이번 달 이 아이에게 보낸 별을 내 문서에 쌓아 둠 (결산용)
        if (asSupporter) {
          final String? me = FirebaseAuth.instance.currentUser?.uid;
          if (me != null) {
            tx.set(_db.collection('supporterLinks').doc(me), {
              'sent': {
                code: {mk: FieldValue.increment(stars)},
              },
            }, SetOptions(merge: true));
          }
        }

        // 🆕 [응원 가족 2026-09-30] 보낸 사람별 기록 한 장 (보호자·응원 가족 모두)
        tx.set(giftRef, {
          'fromUid': FirebaseAuth.instance.currentUser?.uid,
          'fromName': fromName,
          'fromRelation': fromRelation,
          'fromRelationText': fromRelationText,
          'role': asSupporter ? 'supporter' : 'guardian',
          'stars': stars,
          'type': isSpecial ? 'special' : 'normal',
          'message': message,
          'acts': acts,
          'exMin': exMin,
          'sentAt': FieldValue.serverTimestamp(),
        });
      });
      return null;
    } on StateError catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('[ExerciseStarService] sendStarsToChild 실패: $e');
      return 'errNetwork';
    }
  }

  /// 운동 중 5분마다 쌓이는 시간 별. 타이머가 부를 때마다 바로 서버에 더함
  /// (앱이 갑자기 꺼져도 이미 쌓인 별은 안전하게 남음 - 학생 타이머와 같은 방식)
  static Future<void> addTimeStars(int stars) async {
    final ref = _myDoc();
    if (ref == null || stars <= 0) return;
    try {
      await ref.set({
        'balance': FieldValue.increment(stars),
        'totalEarned': FieldValue.increment(stars),
        'monthly': {
          monthKey(DateTime.now()): {'timeStars': FieldValue.increment(stars)}, // 🆕 이번 달 시간 별
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[ExerciseStarService] addTimeStars 실패: $e');
    }
  }

  /// 운동을 끝냈을 때 한 번 부름. 오늘 운동 시간을 기록하고, 받을 수 있는
  /// 보너스를 계산해서 지급. 같은 보너스는 절대 두 번 주지 않음.
  static Future<ExerciseSessionResult> finishSession({required int sessionMinutes}) async {
    final ref = _myDoc();
    if (ref == null || sessionMinutes <= 0) return ExerciseSessionResult.empty;

    try {
      return await _db.runTransaction<ExerciseSessionResult>((tx) async {
        final snap = await tx.get(ref);
        final Map<String, dynamic> data = snap.data() ?? {};
        final Map<String, dynamic> daily = Map<String, dynamic>.from((data['dailyMinutes'] as Map?) ?? {});
        final List<String> awarded = ((data['awardedKeys'] as List?) ?? []).map((e) => e.toString()).toList();

        final DateTime now = DateTime.now();
        final DateTime today = DateTime(now.year, now.month, now.day);
        final String todayKey = dateKey(today);
        daily[todayKey] = ((daily[todayKey] as num?)?.toInt() ?? 0) + sessionMinutes;

        // 🆕 이번 달 수집 내역
        final Map<String, dynamic> monthly = Map<String, dynamic>.from((data['monthly'] as Map?) ?? {});
        final String mk = monthKey(today);
        final Map<String, dynamic> thisMonth = Map<String, dynamic>.from((monthly[mk] as Map?) ?? {});
        final Map<String, dynamic> bonusCounts = Map<String, dynamic>.from((thisMonth['bonusCounts'] as Map?) ?? {});

        int minutesOn(DateTime d) => (daily[dateKey(d)] as num?)?.toInt() ?? 0;
        bool exercisedOn(DateTime d) => minutesOn(d) >= minMinutesForDay;

        int bonus = 0;
        final List<String> keys = [];
        void award(String key, String category) {
          if (awarded.contains(key)) return;
          final int stars = bonusCategoryStars[category] ?? 0;
          awarded.add(key);
          bonus += stars;
          bonusCounts[category] = ((bonusCounts[category] as num?)?.toInt() ?? 0) + 1;
          keys.add(category);
        }

        // ① 운동 기록 보너스 (5분 이상 운동한 기록, 하루 3번까지)
        if (sessionMinutes >= minMinutesForDay) {
          for (int i = 1; i <= maxRecordBonusPerDay; i++) {
            final String key = 'rec_${todayKey}_$i';
            if (!awarded.contains(key)) {
              award(key, 'record');
              break;
            }
          }
        }

        // ② 하루 합계 60분 이상
        if (minutesOn(today) >= 60) {
          award('d60_$todayKey', 'd60');
        }

        // ③ 어제에 이어 오늘도 운동
        if (exercisedOn(today) && exercisedOn(today.subtract(const Duration(days: 1)))) {
          award('streak_$todayKey', 'streak');
        }

        // ④ 일주일(일~토) 하루도 빠짐없이 - 토요일 운동을 끝낼 때 확인
        if (today.weekday == DateTime.saturday) {
          final DateTime sunday = today.subtract(const Duration(days: 6));
          bool allWeek = true;
          for (int i = 0; i < 7; i++) {
            if (!exercisedOn(sunday.add(Duration(days: i)))) {
              allWeek = false;
              break;
            }
          }
          if (allWeek) award('week_${dateKey(sunday)}', 'week');
        }

        // ⑤ 한 달 하루도 빠짐없이 - 그 달 마지막 날 운동을 끝낼 때 확인
        final int lastDay = DateTime(today.year, today.month + 1, 0).day;
        if (today.day == lastDay) {
          bool allMonth = true;
          for (int d = 1; d <= lastDay; d++) {
            if (!exercisedOn(DateTime(today.year, today.month, d))) {
              allMonth = false;
              break;
            }
          }
          if (allMonth) award('month_$mk', 'month');
        }

        // 이번 달 내역 정리
        thisMonth['bonusCounts'] = bonusCounts;
        thisMonth['bonusStars'] = ((thisMonth['bonusStars'] as num?)?.toInt() ?? 0) + bonus;
        thisMonth['minutes'] = ((thisMonth['minutes'] as num?)?.toInt() ?? 0) + sessionMinutes;
        monthly[mk] = thisMonth;
        _trimMonthly(monthly);

        // 오래된 기록 정리 (문서가 끝없이 커지지 않게)
        final List<String> dayKeys = daily.keys.toList()..sort();
        while (dayKeys.length > 62) {
          daily.remove(dayKeys.removeAt(0));
        }
        while (awarded.length > 200) {
          awarded.removeAt(0);
        }

        final int balance = ((data['balance'] as num?)?.toInt() ?? 0) + bonus;
        final int totalEarned = ((data['totalEarned'] as num?)?.toInt() ?? 0) + bonus;
        final Map<String, dynamic> payload = {
          'balance': balance,
          'totalEarned': totalEarned,
          'dailyMinutes': daily,
          'awardedKeys': awarded,
          'monthly': monthly,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (snap.exists) {
          tx.update(ref, payload); // 통째로 바꿔야 정리한 오래된 날짜가 실제로 지워짐
        } else {
          tx.set(ref, payload);
        }
        return ExerciseSessionResult(bonusStars: bonus, bonusKeys: keys);
      });
    } catch (e) {
      debugPrint('[ExerciseStarService] finishSession 실패: $e');
      return ExerciseSessionResult.empty;
    }
  }
}

// 🆕 [가족 활동 체크] 항목 하나의 규칙 (화면 아이콘·이름은 family_check_dialog.dart / cheer_stars_i18n.dart)
class FamilyCheckItemDef {
  final String key; // 저장 이름표 (절대 바꾸지 말 것)
  final String group; // 'body' | 'heart' | 'family' | 'self'
  final int starsPerUnit; // 한 칸당 별
  final int unitSize; // 한 칸 크기 (5분, 50계단, 500보, 1회)
  final String unitType; // 'min' | 'stairs' | 'steps' | 'times'
  final int maxUnits; // 하루 최대 칸 수
  final bool auto; // true면 화면에서 못 누르고 자동으로만 올라감 (응원 문자)

  const FamilyCheckItemDef({
    required this.key,
    required this.group,
    required this.starsPerUnit,
    required this.unitSize,
    required this.unitType,
    required this.maxUnits,
    this.auto = false,
  });
}
