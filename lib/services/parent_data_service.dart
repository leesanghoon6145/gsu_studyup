import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../star_economy.dart';
import 'user_profile_service.dart';

// ============================================================================
// 👑 [부모 화면 데이터 창구] ParentDataService
// - 학부모 화면은 이 파일을 통해서만 학생의 학습 데이터를 읽습니다.
// - 지금은 SharedPreferences(같은 기기 안에서만 유효)를 사용하지만,
//   나중에 서버(Firebase 등) 연동 시 이 파일 내부 구현만 교체하면 되고
//   화면(위젯) 코드는 손댈 필요가 없도록 설계했습니다.
// - star_economy.dart(DkeStars), user_profile_service.dart(DkeUserProfile)와
//   동일한 "창구 하나로 통일" 원칙을 따릅니다.
// ============================================================================

class ParentSessionRecord {
  final String subject;
  final String recordType; // '강의' 또는 '평가'
  final String? lectureSubType;
  final String details;
  final int? score;
  final String? incorrectNote;
  final int? understanding;
  final String? difficulty;
  final String? concentration;
  final String? condition;
  final String nextGoal;
  final int durationSeconds;
  final DateTime timestamp;

  ParentSessionRecord({
    required this.subject,
    required this.recordType,
    this.lectureSubType,
    required this.details,
    this.score,
    this.incorrectNote,
    this.understanding,
    this.difficulty,
    this.concentration,
    this.condition,
    required this.nextGoal,
    required this.durationSeconds,
    required this.timestamp,
  });

  int get durationMinutes => (durationSeconds / 60).round();

  factory ParentSessionRecord.fromJson(Map<String, dynamic> json) {
    return ParentSessionRecord(
      subject: json['subject'] as String? ?? '',
      recordType: json['recordType'] as String? ?? '평가',
      lectureSubType: json['lectureSubType'] as String?,
      details: json['details'] as String? ?? '',
      score: (json['score'] as num?)?.toInt(),
      incorrectNote: json['incorrectNote'] as String?,
      understanding: (json['understanding'] as num?)?.toInt(),
      difficulty: json['difficulty'] as String?,
      concentration: json['concentration'] as String?,
      condition: json['condition'] as String?,
      nextGoal: json['nextGoal'] as String? ?? '',
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class ParentExamRecord {
  final String type; // 주평가/단원평가/중간고사/기말고사/모의고사
  final int grade;
  final int semester;
  final String subject;
  final String unit;
  final double score;
  final DateTime date;

  ParentExamRecord({
    required this.type,
    required this.grade,
    required this.semester,
    required this.subject,
    required this.unit,
    required this.score,
    required this.date,
  });

  factory ParentExamRecord.fromJson(Map<String, dynamic> json) {
    return ParentExamRecord(
      type: json['type'] as String? ?? '주평가',
      grade: (json['grade'] as num?)?.toInt() ?? 1,
      semester: (json['semester'] as num?)?.toInt() ?? 1,
      subject: json['subject'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class ParentDataService {
  ParentDataService._();

  // 학생 실명 조회 (회원가입 시 저장된 이름 그대로 재사용)
  static Future<String?> getStudentName() => DkeUserProfile.getRealName();

  // 오늘 하루 모든 과목(dke_history_*, 강의+평가 전부)을 시간순으로 모아 반환
  static Future<List<ParentSessionRecord>> loadTodaySessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Set<String> allKeys = prefs.getKeys();
      final Iterable<String> historyKeys = allKeys.where((k) => k.startsWith('dke_history_'));

      final DateTime now = DateTime.now();
      final DateTime todayStart = DateTime(now.year, now.month, now.day);

      final List<ParentSessionRecord> todaySessions = [];

      for (final key in historyKeys) {
        final List<String>? entries = prefs.getStringList(key);
        if (entries == null) continue;
        for (final raw in entries) {
          try {
            final Map<String, dynamic> item = jsonDecode(raw);
            final rec = ParentSessionRecord.fromJson(item);
            if (!rec.timestamp.isBefore(todayStart)) {
              todaySessions.add(rec);
            }
          } catch (_) {
            // 손상된 기록 1건은 건너뛰고 나머지는 계속 집계
          }
        }
      }

      todaySessions.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return todaySessions;
    } catch (e) {
      return [];
    }
  }

  // 전체 기간(오늘 제한 없음) dke_history_* 세션을 시간순으로 반환
  // — "어제 대비", "1주 평균 대비" 등 변화량 계산에 사용
  static Future<List<ParentSessionRecord>> loadAllSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Set<String> allKeys = prefs.getKeys();
      final Iterable<String> historyKeys = allKeys.where((k) => k.startsWith('dke_history_'));

      final List<ParentSessionRecord> all = [];
      for (final key in historyKeys) {
        final List<String>? entries = prefs.getStringList(key);
        if (entries == null) continue;
        for (final raw in entries) {
          try {
            final Map<String, dynamic> item = jsonDecode(raw);
            all.add(ParentSessionRecord.fromJson(item));
          } catch (_) {}
        }
      }
      all.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return all;
    } catch (e) {
      return [];
    }
  }

  // gke_exam_records(평가 유형만) 전체를 불러옴 — member_achievement_screen.dart와 동일 포맷
  static Future<List<ParentExamRecord>> loadExamRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? json = prefs.getString('gke_exam_records');
      if (json == null || json.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(json);
      final List<ParentExamRecord> list = [];
      for (final e in decoded) {
        try {
          list.add(ParentExamRecord.fromJson(Map<String, dynamic>.from(e as Map)));
        } catch (_) {}
      }
      return list;
    } catch (e) {
      return [];
    }
  }

  // 과목별 학습시간 집계(오늘/주간/월간/연간 여부 + 활동일 평균 분)
  // — member_achievement_screen.dart의 _loadRealSubjectStudyData()와 동일 방식
  static Future<List<Map<String, dynamic>>> loadSubjectAggregates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Set<String> allKeys = prefs.getKeys();
      final Iterable<String> historyKeys = allKeys.where((k) => k.startsWith('dke_history_'));

      final DateTime now = DateTime.now();
      final DateTime todayStart = DateTime(now.year, now.month, now.day);
      final DateTime weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      final DateTime monthStart = DateTime(now.year, now.month, 1);
      final DateTime yearStart = DateTime(now.year, 1, 1);

      final List<Map<String, dynamic>> aggregated = [];

      for (final key in historyKeys) {
        final String subjectName = key.substring('dke_history_'.length);
        final List<String>? entries = prefs.getStringList(key);
        if (entries == null || entries.isEmpty) continue;

        bool studiedToday = false, studiedWeekly = false, studiedMonthly = false, studiedYearly = false;
        int totalMinutesAllTime = 0;
        final Set<String> activeDayKeys = {};

        for (final raw in entries) {
          try {
            final Map<String, dynamic> item = jsonDecode(raw);
            final DateTime ts = DateTime.tryParse(item['timestamp']?.toString() ?? '')?.toLocal() ?? now;
            final int durationSeconds = (item['durationSeconds'] as num?)?.toInt() ?? 0;
            final int minutes = (durationSeconds / 60).round();

            if (!ts.isBefore(yearStart)) studiedYearly = true;
            if (!ts.isBefore(monthStart)) studiedMonthly = true;
            if (!ts.isBefore(weekStart)) studiedWeekly = true;
            if (!ts.isBefore(todayStart)) studiedToday = true;

            totalMinutesAllTime += minutes;
            activeDayKeys.add("${ts.year}-${ts.month}-${ts.day}");
          } catch (_) {}
        }

        if (!(studiedToday || studiedWeekly || studiedMonthly || studiedYearly)) continue;

        final int activeDays = activeDayKeys.isEmpty ? 1 : activeDayKeys.length;
        final int avgMinutesPerActiveDay = (totalMinutesAllTime / activeDays).round();

        aggregated.add({
          "subject": subjectName,
          "hasStudiedToday": studiedToday,
          "hasStudiedWeekly": studiedWeekly,
          "hasStudiedMonthly": studiedMonthly,
          "hasStudiedYearly": studiedYearly,
          "baseMinutes": avgMinutesPerActiveDay,
        });
      }

      return aggregated;
    } catch (e) {
      return [];
    }
  }

  // 과목별 평가 평균 점수 — "잘하는 과목/취약 과목" 판단용
  static Map<String, double> computeSubjectAverageScores(List<ParentExamRecord> records) {
    final Map<String, List<double>> bucket = {};
    for (final r in records) {
      bucket.putIfAbsent(r.subject, () => []).add(r.score);
    }
    final Map<String, double> result = {};
    bucket.forEach((subject, scores) {
      result[subject] = scores.reduce((a, b) => a + b) / scores.length;
    });
    return result;
  }

  // 오늘 적립된 별 개수
  static Future<int> getTodayStars() => DkeStars.getTodayStars();

  // 특정 날짜(자정 기준) 하루 총 학습분 계산 헬퍼
  static int totalMinutesForDay(List<ParentSessionRecord> sessions, DateTime dayStart) {
    final DateTime dayEnd = dayStart.add(const Duration(days: 1));
    int total = 0;
    for (final s in sessions) {
      if (!s.timestamp.isBefore(dayStart) && s.timestamp.isBefore(dayEnd)) {
        total += s.durationMinutes;
      }
    }
    return total;
  }
}
