// ============================================================================
// 🆕 [2026-10-15] 🩺 실력진단 — 공지 및 교육상담 → 교육상담
//
// 원장님 설계 (2026-10-15 확정)
// · 과목: 국어 · 영어 · 수학 · 과학 (4과목만)
// · 시험지 3장 중 학생이 직접 고름
//     🌱🌿 기초·기본 시험지 (1장) / 🌳 실력 시험지 / 🌲 심화 시험지
// · 점수 구간: 기초(=교재 길잡이 🌱개념) 50점 미만 · 기본 50~69 · 실력 70~89 · 심화 90 이상
// · 높은 시험지에서 점수가 낮으면 한 단계 아래로 판정하되, 경계 점수는 융통성 있게
//     50점대 후반 → 기본 / 70점대 후반 → 실력 / 80점대 후반 → 심화 교재도 함께 고를 수 있게
// · 푸는 방법 2가지: ① 앱에서 문제 보며 풀기  ② 시험지 인쇄(PDF) → 종이에 풀고 답만 입력
// · 답지 제출 → 바로 채점 → 간단 리포트 → [교재 길잡이에서 내 교재 보기]
// · 진단 기록은 따로 저장 (학생 연결 문서 skillDiagHistory + 폰)
//     과목마다 첫 진단 = 출발점(skillDiagBase) → 30일 뒤 성장 비교에 사용
// · 시험지 · 문제는 서버(diagPapers)에 저장 — 관리자(원장님)만 넣고 고침
//     처음엔 [샘플 시험지 넣기]: 중2 1학기 수학 「유리수와 순환소수」 3장(5문항씩)
//
// ⚠️ Firestore 규칙에 diagPapers 블록 추가 필요 (읽기 = 로그인, 쓰기 = 관리자)
// ⚠️ pubspec.yaml에 pdf · printing 꾸러미 추가 필요 (시험지 인쇄)
// 글자: 한글 = Noto Sans KR, 영어 = 고운바탕 굵게
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:gsu_studyup/global_lang.dart';
import 'package:gsu_studyup/services/family_link_service.dart';
import 'package:gsu_studyup/services/notice_counsel_service.dart';
import 'textbook_guide_screen.dart';

// ---------------------------------------------------------------------------
// 색 · 글자
// ---------------------------------------------------------------------------
const Color _kBg = Color(0xFF030712);
const Color _kCard = Color(0xFF0D1527);
const Color _kCardHi = Color(0xFF111A2E);
const Color _kGold = Color(0xFFE5C158);
const Color _kDeepGold = Color(0xFFD4AF37);
const Color _kCream = Color(0xFFFFF6D6);
const Color _kOk = Color(0xFF34D399);
const Color _kNo = Color(0xFFF87171);
const LinearGradient _kGoldGrad = LinearGradient(colors: [Color(0xFFF6DD8A), _kDeepGold]);

bool get _ko => !DkeLang.isForeignSelected && DkeLang.current != 'EN';
String _kr(String ko, String en) => _ko ? ko : en;
TextStyle _en(double size, {Color color = _kGold}) =>
    GoogleFonts.gowunBatang(color: color, fontWeight: FontWeight.bold, fontSize: size);
TextStyle _ks(double size, {Color color = Colors.white, FontWeight w = FontWeight.bold, double? h}) =>
    GoogleFonts.notoSansKr(color: color, fontWeight: w, fontSize: size, height: h);

const List<String> kDiagSubjects = ['국어', '영어', '수학', '과학'];
const Map<String, String> _kSubjectEn = {'국어': 'Korean', '영어': 'English', '수학': 'Math', '과학': 'Science'};
const Map<String, String> _kSubjectEmoji = {'국어': '📖', '영어': '🔤', '수학': '📐', '과학': '🔬'};
const List<String> kDiagGrades = ['초3', '초4', '초5', '초6', '중1', '중2', '중3', '고1', '고2', '고3'];

/// 시험지 3장
const List<String> kPaperLevels = ['basic', 'skilled', 'advanced'];
const Map<String, List<String>> _kPaperLabel = {
  'basic': ['기초 · 기본 시험지', 'Foundation Paper', '🌱🌿'],
  'skilled': ['실력 시험지', 'Skill Paper', '🌳'],
  'advanced': ['심화 시험지', 'Advanced Paper', '🌲'],
};
const Map<String, List<String>> _kPaperDesc = {
  'basic': ['개념과 기본 유형을 확인해요. 처음이거나 자신이 없으면 여기서 시작!', 'Concepts and basic types.'],
  'skilled': ['여러 개념을 엮은 문제예요. 학교 시험 80점 안팎이면 도전!', 'Mixed-concept problems.'],
  'advanced': ['깊이 생각해야 하는 문제예요. 90점 이상을 노린다면 도전!', 'Deep-thinking problems.'],
};

/// 판정 단계 (교재 길잡이와 같은 이름)
const Map<String, List<String>> _kLevelLabel = {
  'concept': ['🌱', '개념(기초)', 'Concept'],
  'basic': ['🌿', '기본', 'Basic'],
  'skilled': ['🌳', '실력', 'Skilled'],
  'advanced': ['🌲', '심화', 'Advanced'],
};
String _lvText(String lv) => '${_kLevelLabel[lv]![0]} ${_kr(_kLevelLabel[lv]![1], _kLevelLabel[lv]![2])}';

// ============================================================================
// 데이터
// ============================================================================
class DiagQuestion {
  String type; // mc = 객관식 ①~⑤ / short = 단답형
  String text;
  List<String> choices;
  String answer; // mc: '1'~'5' / short: '4/9', '12' 등
  int points;
  String concept; // 세부 개념 (약한 개념 분석용)
  DiagQuestion({
    this.type = 'mc',
    this.text = '',
    List<String>? choices,
    this.answer = '',
    this.points = 20,
    this.concept = '',
  }) : choices = choices ?? List<String>.filled(5, '');

  Map<String, dynamic> toMap() => {
    'type': type,
    'text': text,
    'choices': choices,
    'answer': answer,
    'points': points,
    'concept': concept,
  };

  factory DiagQuestion.fromMap(Map<String, dynamic> m) => DiagQuestion(
    type: (m['type'] ?? 'mc').toString(),
    text: (m['text'] ?? '').toString(),
    choices: ((m['choices'] as List?) ?? const []).map((e) => e.toString()).toList(),
    answer: (m['answer'] ?? '').toString(),
    points: (m['points'] as num?)?.toInt() ?? 20,
    concept: (m['concept'] ?? '').toString(),
  );
}

class DiagPaper {
  String id;
  String subject;
  String grade;
  int semester;
  String unit;
  String level; // basic / skilled / advanced
  bool active;
  int order;
  List<DiagQuestion> questions;
  DiagPaper({
    this.id = '',
    this.subject = '수학',
    this.grade = '중2',
    this.semester = 1,
    this.unit = '',
    this.level = 'basic',
    this.active = true,
    this.order = 100,
    List<DiagQuestion>? questions,
  }) : questions = questions ?? [];

  int get totalPoints => questions.fold<int>(0, (s, q) => s + q.points);

  Map<String, dynamic> toMap() => {
    'subject': subject,
    'grade': grade,
    'semester': semester,
    'unit': unit,
    'level': level,
    'active': active,
    'order': order,
    'questions': questions.map((q) => q.toMap()).toList(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory DiagPaper.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final Map<String, dynamic> m = d.data() ?? {};
    return DiagPaper(
      id: d.id,
      subject: (m['subject'] ?? '수학').toString(),
      grade: (m['grade'] ?? '중2').toString(),
      semester: (m['semester'] as num?)?.toInt() ?? 1,
      unit: (m['unit'] ?? '').toString(),
      level: (m['level'] ?? 'basic').toString(),
      active: m['active'] != false,
      order: (m['order'] as num?)?.toInt() ?? 100,
      questions: ((m['questions'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => DiagQuestion.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  String get unitKey => '$subject|$grade|$semester|$unit';
}

class DiagResult {
  final String paperId;
  final String subject;
  final String grade;
  final int semester;
  final String unit;
  final String paperLevel;
  final int score;
  final String level; // 판정 단계
  final String? flexLevel; // 융통성 있게 함께 볼 수 있는 단계
  final String note;
  final List<bool> correct;
  final List<String> answers;
  final Map<String, List<int>> concepts; // 개념 → [맞은 수, 전체 수]
  final int seconds;
  final String mode; // app / paper
  final DateTime date;
  bool isBaseline;

  DiagResult({
    required this.paperId,
    required this.subject,
    required this.grade,
    required this.semester,
    required this.unit,
    required this.paperLevel,
    required this.score,
    required this.level,
    required this.flexLevel,
    required this.note,
    required this.correct,
    required this.answers,
    required this.concepts,
    required this.seconds,
    required this.mode,
    required this.date,
    this.isBaseline = false,
  });

  Map<String, dynamic> toMap() => {
    'paperId': paperId,
    'subject': subject,
    'grade': grade,
    'semester': semester,
    'unit': unit,
    'paperLevel': paperLevel,
    'score': score,
    'level': level,
    'flexLevel': flexLevel,
    'note': note,
    'correct': correct,
    'answers': answers,
    'concepts': concepts.map((k, v) => MapEntry(k, v)),
    'seconds': seconds,
    'mode': mode,
    'date': date.toIso8601String(),
    'isBaseline': isBaseline,
  };

  factory DiagResult.fromMap(Map<String, dynamic> m) => DiagResult(
    paperId: (m['paperId'] ?? '').toString(),
    subject: (m['subject'] ?? '').toString(),
    grade: (m['grade'] ?? '').toString(),
    semester: (m['semester'] as num?)?.toInt() ?? 1,
    unit: (m['unit'] ?? '').toString(),
    paperLevel: (m['paperLevel'] ?? 'basic').toString(),
    score: (m['score'] as num?)?.toInt() ?? 0,
    level: (m['level'] ?? 'basic').toString(),
    flexLevel: m['flexLevel']?.toString(),
    note: (m['note'] ?? '').toString(),
    correct: ((m['correct'] as List?) ?? const []).map((e) => e == true).toList(),
    answers: ((m['answers'] as List?) ?? const []).map((e) => e.toString()).toList(),
    concepts: ((m['concepts'] as Map?) ?? const {}).map((k, v) => MapEntry(
      k.toString(),
      ((v as List?) ?? const [0, 0]).map((e) => (e as num).toInt()).toList(),
    )),
    seconds: (m['seconds'] as num?)?.toInt() ?? 0,
    mode: (m['mode'] ?? 'app').toString(),
    date: DateTime.tryParse((m['date'] ?? '').toString()) ?? DateTime.now(),
    isBaseline: m['isBaseline'] == true,
  );
}

/// 판정 결과
class DiagJudge {
  final String level;
  final String? flex;
  final String note;
  const DiagJudge(this.level, this.flex, this.note);
}

// ============================================================================
// 서비스
// ============================================================================
class SkillDiagService {
  SkillDiagService._();
  static final CollectionReference<Map<String, dynamic>> _papers =
  FirebaseFirestore.instance.collection('diagPapers');

  static Stream<List<DiagPaper>> watchPapers() => _papers.snapshots().map((s) {
    final List<DiagPaper> list = s.docs.map(DiagPaper.fromDoc).toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  });

  static Future<bool> savePaper(DiagPaper p) async {
    try {
      if (p.id.isEmpty) {
        final ref = await _papers.add(p.toMap());
        p.id = ref.id;
      } else {
        await _papers.doc(p.id).set(p.toMap(), SetOptions(merge: true));
      }
      return true;
    } catch (e) {
      debugPrint('[SkillDiag] 시험지 저장 실패: $e');
      return false;
    }
  }

  static Future<bool> deletePaper(String id) async {
    try {
      await _papers.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('[SkillDiag] 시험지 삭제 실패: $e');
      return false;
    }
  }

  // -------------------------------------------------------------- 채점
  static String _norm(String s) {
    String t = s.trim().replaceAll(RegExp(r'\s'), '');
    const Map<String, String> circled = {'①': '1', '②': '2', '③': '3', '④': '4', '⑤': '5'};
    circled.forEach((k, v) => t = t.replaceAll(k, v));
    return t.replaceAll('번', '');
  }

  /// '4/9', '-3/11', '0.75', '12' → 숫자 (못 읽으면 null)
  static double? _num(String s) {
    final String t = _norm(s);
    if (t.contains('/')) {
      final List<String> p = t.split('/');
      if (p.length != 2) return null;
      final double? a = double.tryParse(p[0]);
      final double? b = double.tryParse(p[1]);
      if (a == null || b == null || b == 0) return null;
      return a / b;
    }
    return double.tryParse(t);
  }

  static bool isCorrect(DiagQuestion q, String given) {
    if (given.trim().isEmpty) return false;
    final String g = _norm(given);
    final String a = _norm(q.answer);
    if (g == a) return true;
    if (q.type == 'mc') return false;
    // 여러 정답 허용: "4/9|0.4̇" 처럼 | 로 나눠 적을 수 있음
    for (final String alt in q.answer.split('|')) {
      if (_norm(alt) == g) return true;
      final double? x = _num(alt);
      final double? y = _num(given);
      if (x != null && y != null && (x - y).abs() < 1e-9) {
        // 분수 문제는 기약분수로 썼는지까지는 보지 않음 (값이 같으면 정답)
        return true;
      }
    }
    return false;
  }

  /// 원장님 판정표 (2026-10-15) — 숫자만 바꾸면 기준이 바뀜
  static DiagJudge judge(String paper, int s) {
    switch (paper) {
      case 'basic': // 기초 · 기본 시험지
        if (s < 50) {
          return DiagJudge('concept', s >= 45 ? 'basic' : null,
              _kr('개념부터 차근차근 다지면 금방 올라갑니다.', 'Build concepts step by step.'));
        }
        if (s < 70) {
          return DiagJudge('basic', s >= 65 ? 'skilled' : null,
              _kr('기본 유형을 끝까지 풀어 실력 단계로 올라가요.', 'Finish basic types to move up.'));
        }
        return DiagJudge('basic', 'skilled',
            _kr('기본은 탄탄합니다! 실력 시험지에도 도전해 보세요.', 'Solid basics! Try the Skill Paper.'));
      case 'skilled': // 실력 시험지
        if (s < 50) {
          return DiagJudge('basic', null,
              _kr('기초·기본 시험지로 지금 단계를 다시 확인해 보세요.', 'Try the Foundation Paper first.'));
        }
        if (s < 70) {
          return DiagJudge('basic', s >= 65 ? 'skilled' : null,
              _kr('기본은 갖췄어요. 실력 문제를 조금씩 늘려 가요.', 'Basics are there. Add skill problems.'));
        }
        if (s < 90) {
          return DiagJudge('skilled', s >= 85 ? 'advanced' : null,
              _kr('실력 단계입니다. 틀린 개념만 다시 잡으면 심화도 가능해요.', 'Skilled level. Fix weak spots for advanced.'));
        }
        return DiagJudge('skilled', 'advanced',
            _kr('실력 단계 완성! 심화 시험지에 도전해 보세요.', 'Skilled mastered! Try the Advanced Paper.'));
      default: // 심화 시험지
        if (s < 70) {
          return DiagJudge('skilled', null,
              _kr('심화는 아직 일러요. 실력 시험지로 단계를 확인해 보세요.', 'Try the Skill Paper first.'));
        }
        if (s < 90) {
          return DiagJudge('skilled', s >= 85 ? 'advanced' : null,
              _kr('실력은 충분합니다. 심화 문제로 한 걸음 더!', 'Strong skills. One more step to advanced!'));
        }
        return DiagJudge('advanced', null, _kr('최상위 심화 단계입니다. 훌륭해요!', 'Top advanced level. Excellent!'));
    }
  }

  static DiagResult grade(DiagPaper p, List<String> answers, {required int seconds, required String mode}) {
    final List<bool> correct = [];
    int got = 0;
    final Map<String, List<int>> concepts = {};
    for (int i = 0; i < p.questions.length; i++) {
      final DiagQuestion q = p.questions[i];
      final bool ok = isCorrect(q, i < answers.length ? answers[i] : '');
      correct.add(ok);
      if (ok) got += q.points;
      final String c = q.concept.trim().isEmpty ? _kr('기타', 'Other') : q.concept.trim();
      final List<int> v = concepts.putIfAbsent(c, () => [0, 0]);
      v[1] += 1;
      if (ok) v[0] += 1;
    }
    final int total = p.totalPoints == 0 ? 1 : p.totalPoints;
    final int score = (got * 100 / total).round();
    final DiagJudge j = judge(p.level, score);
    return DiagResult(
      paperId: p.id,
      subject: p.subject,
      grade: p.grade,
      semester: p.semester,
      unit: p.unit,
      paperLevel: p.level,
      score: score,
      level: j.level,
      flexLevel: j.flex,
      note: j.note,
      correct: correct,
      answers: List<String>.from(answers),
      concepts: concepts,
      seconds: seconds,
      mode: mode,
      date: DateTime.now(),
    );
  }

  // -------------------------------------------------------------- 저장
  static String get _localKey => 'gke_skill_diag_${FirebaseAuth.instance.currentUser?.uid ?? 'guest'}';

  static Future<List<DiagResult>> _loadLocal() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> raw = prefs.getStringList(_localKey) ?? const [];
      return raw.map((s) => DiagResult.fromMap(Map<String, dynamic>.from(jsonDecode(s) as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  /// 결과 저장 — 과목마다 첫 진단은 출발점(isBaseline)으로 표시
  static Future<void> saveResult(DiagResult r) async {
    final List<DiagResult> local = await _loadLocal();
    String code = '';
    Map<String, dynamic> doc = {};
    try {
      code = (await FamilyLinkService.getMyLinkCode()) ?? '';
      if (code.isNotEmpty) {
        doc = (await FirebaseFirestore.instance.collection('links').doc(code).get()).data() ?? {};
      }
    } catch (_) {}
    final Map<String, dynamic> base = Map<String, dynamic>.from((doc['skillDiagBase'] as Map?) ?? const {});
    final bool hasLocalBase = local.any((x) => x.subject == r.subject && x.isBaseline);
    r.isBaseline = !base.containsKey(r.subject) && !hasLocalBase;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> raw = prefs.getStringList(_localKey) ?? <String>[];
      raw.add(jsonEncode(r.toMap()));
      while (raw.length > 100) {
        raw.removeAt(0);
      }
      await prefs.setStringList(_localKey, raw);
    } catch (_) {}

    if (code.isNotEmpty) {
      try {
        final Map<String, dynamic> data = {
          'skillDiagHistory': FieldValue.arrayUnion([r.toMap()]),
          'skillDiagUpdatedAt': FieldValue.serverTimestamp(),
        };
        if (r.isBaseline) data['skillDiagBase'] = {r.subject: r.toMap()};
        await FirebaseFirestore.instance.collection('links').doc(code).set(data, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[SkillDiag] 서버 저장 실패(폰에는 저장됨): $e');
      }
    }
  }

  /// 내 진단 기록 (서버 우선, 없으면 폰)
  static Future<List<DiagResult>> myHistory() async {
    try {
      final String code = (await FamilyLinkService.getMyLinkCode()) ?? '';
      if (code.isNotEmpty) {
        final Map<String, dynamic> d =
            (await FirebaseFirestore.instance.collection('links').doc(code).get()).data() ?? {};
        final List<DiagResult> list = historyFromDoc(d);
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}
    final List<DiagResult> local = await _loadLocal();
    local.sort((a, b) => a.date.compareTo(b.date));
    return local;
  }

  static List<DiagResult> historyFromDoc(Map<String, dynamic> d) {
    final List<DiagResult> list = ((d['skillDiagHistory'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => DiagResult.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// 한 달 성장 문장 (출발점 → 최근) — 리포트에도 그대로 씀
  static String growthText(List<DiagResult> hist, String subject) {
    final List<DiagResult> s = hist.where((r) => r.subject == subject).toList();
    if (s.isEmpty) return '';
    final DiagResult base = s.firstWhere((r) => r.isBaseline, orElse: () => s.first);
    final DiagResult last = s.last;
    final int days = last.date.difference(base.date).inDays;
    if (identical(base, last) || s.length == 1) {
      final int left = 30 - DateTime.now().difference(base.date).inDays;
      return _kr(
        '출발점 ${base.score}점(${_lvText(base.level)}) 저장됨 · ${left > 0 ? '$left일 뒤' : '지금'} 다시 진단하면 한 달 성장을 비교해 드려요.',
        'Baseline ${base.score} saved. Re-test ${left > 0 ? 'in $left days' : 'now'} to see growth.',
      );
    }
    final int diff = last.score - base.score;
    final String arrow = diff > 0 ? '▲ $diff' : (diff < 0 ? '▼ ${-diff}' : '＝ 0');
    return _kr(
      '출발 ${base.score}점(${_lvText(base.level)}) → $days일 뒤 ${last.score}점(${_lvText(last.level)})  $arrow점',
      'Start ${base.score} → ${last.score} after $days days ($arrow)',
    );
  }

  // -------------------------------------------------------------- 샘플 시험지
  static Future<int> seedSamples() async {
    int n = 0;
    for (final MapEntry<String, DiagPaper> e in _samplePapers().entries) {
      try {
        await _papers.doc(e.key).set(e.value.toMap());
        n++;
      } catch (err) {
        debugPrint('[SkillDiag] 샘플 넣기 실패: $err');
      }
    }
    return n;
  }

  static Map<String, DiagPaper> _samplePapers() {
    const String unit = '유리수와 순환소수';
    DiagQuestion mc(String t, List<String> c, String a, String concept) =>
        DiagQuestion(type: 'mc', text: t, choices: c, answer: a, points: 20, concept: concept);
    DiagQuestion sh(String t, String a, String concept) =>
        DiagQuestion(type: 'short', text: t, answer: a, points: 20, concept: concept);
    return {
      'sample_m2s1_rational_basic': DiagPaper(subject: '수학', grade: '중2', semester: 1, unit: unit, level: 'basic', order: 10, questions: [
        mc('다음 중 유한소수로 나타낼 수 있는 것은?', ['1/3', '2/7', '3/8', '5/12', '7/15'], '3', '유한소수 판별'),
        sh('순환소수 0.4̇ (= 0.444…) 를 분수로 나타내시오.', '4/9', '순환소수 → 분수'),
        sh('순환소수 2.353535… 의 순환마디를 쓰시오.', '35', '순환마디'),
        sh('분수 7/12 를 소수로 나타낼 때 순환마디를 쓰시오.', '3', '분수 → 소수'),
        mc('다음 중 옳은 것은?', ['모든 순환소수는 유리수이다.', '무한소수는 모두 유리수이다.', '정수가 아닌 유리수는 모두 유한소수이다.', '0.1̇ 은 유리수가 아니다.', 'π 는 순환소수이다.'], '1', '유리수의 뜻'),
      ]),
      'sample_m2s1_rational_skilled': DiagPaper(subject: '수학', grade: '중2', semester: 1, unit: unit, level: 'skilled', order: 20, questions: [
        sh('분수 a/60 이 유한소수가 되도록 하는 두 자리 자연수 a 중 가장 작은 수를 구하시오.', '12', '유한소수 조건'),
        sh('순환소수 0.12̇3̇ (= 0.12323…) 을 기약분수로 나타내시오.', '61/495', '순환소수 → 분수'),
        sh('순환소수 0.3̇ 에 어떤 자연수 x 를 곱하면 자연수가 된다. 가장 작은 x 를 구하시오.', '3', '순환소수 활용'),
        sh('분수 1/7 을 소수로 나타낼 때, 소수점 아래 50번째 자리의 숫자를 구하시오.', '4', '순환마디 규칙'),
        sh('0.2̇ + 0.3̇ 을 계산하여 기약분수로 나타내시오.', '5/9', '순환소수 계산'),
      ]),
      'sample_m2s1_rational_advanced': DiagPaper(subject: '수학', grade: '중2', semester: 1, unit: unit, level: 'advanced', order: 30, questions: [
        sh('분수 x/84 가 유한소수가 되도록 하는 10 이상 80 이하의 자연수 x 의 개수를 구하시오.', '3', '유한소수 조건'),
        sh('순환소수 0.ȧḃ 를 기약분수로 나타내면 4/11 이다. 한 자리 숫자 a, b 에 대하여 a + b 의 값을 구하시오.', '9', '순환소수 ↔ 분수'),
        sh('1.2̇ × A = 0.3̇ 일 때, A 를 기약분수로 나타내시오.', '3/11', '순환소수 방정식'),
        sh('분수 3/(2²×5×a) 가 유한소수가 되도록 하는 한 자리 자연수 a 의 개수를 구하시오.', '7', '유한소수 조건 심화'),
        sh('분수 1/13 을 소수로 나타낼 때, 소수점 아래 100번째 자리의 숫자를 구하시오.', '9', '순환마디 규칙'),
      ]),
    };
  }

  // -------------------------------------------------------------- 시험지 인쇄 (A4 PDF)
  static Future<void> printPaper(DiagPaper p, {bool withAnswers = false}) async {
    pw.Font? font;
    pw.Font? bold;
    try {
      font = await PdfGoogleFonts.nanumGothicRegular(); // 한글 글꼴 (인터넷에서 한 번 받아 둠)
      bold = await PdfGoogleFonts.nanumGothicBold();
    } catch (_) {}
    final pw.ThemeData theme = font != null ? pw.ThemeData.withFont(base: font, bold: bold ?? font) : pw.ThemeData();
    const PdfColor gold = PdfColor.fromInt(0xFFB8922E);
    const PdfColor ink = PdfColor.fromInt(0xFF1F2937);
    const List<String> circled = ['①', '②', '③', '④', '⑤'];

    final pw.Document doc = pw.Document(theme: theme);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
        header: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: gold, width: 1.5))),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('GKE StudyUp  실력진단', style: pw.TextStyle(color: gold, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.SizedBox(height: 2),
                pw.Text('${p.subject} · ${p.grade} ${p.semester}학기 · ${p.unit}',
                    style: pw.TextStyle(color: ink, fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.Text('${_kPaperLabel[p.level]![0]}${withAnswers ? '  (정답)' : ''}', style: const pw.TextStyle(color: ink, fontSize: 11)),
              ]),
              pw.Container(
                width: 170,
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: gold), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('이름 :', style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 6),
                  pw.Text('날짜 :          점수 :', style: const pw.TextStyle(fontSize: 10)),
                ]),
              ),
            ],
          ),
        ),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ),
        build: (ctx) => [
          pw.SizedBox(height: 10),
          for (int i = 0; i < p.questions.length; i++) ...[
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('${i + 1}. ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('${p.questions[i].text}  (${p.questions[i].points}점)', style: const pw.TextStyle(fontSize: 12, lineSpacing: 3)),
                  pw.SizedBox(height: 6),
                  if (p.questions[i].type == 'mc')
                    pw.Wrap(spacing: 14, runSpacing: 4, children: [
                      for (int c = 0; c < p.questions[i].choices.length && c < 5; c++)
                        pw.Text('${circled[c]} ${p.questions[i].choices[c]}', style: const pw.TextStyle(fontSize: 11.5)),
                    ])
                  else
                    pw.Container(
                      width: 160,
                      height: 22,
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600))),
                      child: pw.Text(withAnswers ? '답: ${p.questions[i].answer}' : '답:', style: const pw.TextStyle(fontSize: 11)),
                    ),
                  if (withAnswers && p.questions[i].type == 'mc')
                    pw.Text('정답: ${circled[(int.tryParse(p.questions[i].answer) ?? 1) - 1]}',
                        style: pw.TextStyle(color: gold, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                ]),
              ),
            ]),
            pw.SizedBox(height: 18),
          ],
          pw.SizedBox(height: 10),
          pw.Text('※ 다 풀었으면 앱의 [종이로 풀기 → 답 입력표]에 답만 넣고 제출하세요. 바로 채점됩니다.',
              style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700)),
        ],
      ),
    );
    await Printing.layoutPdf(
      name: 'GKE_실력진단_${p.subject}_${p.grade}_${p.unit}',
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }
}

// ============================================================================
// 첫 화면: 과목 · 학년 · 학기 → 단원 → 시험지 고르기
// ============================================================================
class SkillDiagnosisScreen extends StatefulWidget {
  final bool isStudent;
  const SkillDiagnosisScreen({super.key, this.isStudent = false});

  @override
  State<SkillDiagnosisScreen> createState() => _SkillDiagnosisScreenState();
}

class _SkillDiagnosisScreenState extends State<SkillDiagnosisScreen> {
  final Stream<List<DiagPaper>> _stream = SkillDiagService.watchPapers();
  String _subject = '수학';
  String _grade = '중2';
  int _semester = 1;
  String? _unit;
  List<DiagResult> _history = [];
  List<_KidDiag> _kids = []; // 학부모: 자녀별 진단 기록
  bool _seeding = false;

  bool get _admin => NoticeCounselService.isAdmin;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (widget.isStudent) {
      final List<DiagResult> h = await SkillDiagService.myHistory();
      if (mounted) setState(() => _history = h);
      return;
    }
    final List<_KidDiag> kids = [];
    try {
      final List<String> codes = await FamilyLinkService.getLinkedCodes();
      for (final String code in codes) {
        try {
          final Map<String, dynamic> d =
              (await FirebaseFirestore.instance.collection('links').doc(code).get()).data() ?? {};
          final String name = (d['studentName'] ?? '').toString();
          kids.add(_KidDiag(name.isEmpty ? code : name, SkillDiagService.historyFromDoc(d)));
        } catch (_) {}
      }
    } catch (_) {}
    if (mounted) setState(() => _kids = kids);
  }

  void _snack(String ko, String en) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: _kCard,
      content: Text(_kr(ko, en), style: _ks(13, color: _kCream)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kGold),
        centerTitle: true,
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Skill Check', style: _en(13)),
          if (_ko) Text('실력진단', style: _ks(16)),
        ]),
      ),
      floatingActionButton: _admin
          ? FloatingActionButton.extended(
        backgroundColor: _kGold,
        onPressed: () => _openEditor(DiagPaper(subject: _subject, grade: _grade, semester: _semester, unit: _unit ?? '')),
        icon: const Icon(Icons.post_add_rounded, color: Colors.black),
        label: Text(_kr('시험지 만들기', 'New Paper'), style: _ks(13, color: Colors.black)),
      )
          : null,
      body: StreamBuilder<List<DiagPaper>>(
        stream: _stream,
        builder: (context, snap) {
          final List<DiagPaper> all = (snap.data ?? const <DiagPaper>[]).where((p) => _admin || p.active).toList();
          final List<DiagPaper> here =
          all.where((p) => p.subject == _subject && p.grade == _grade && p.semester == _semester).toList();
          final List<String> units = <String>{for (final DiagPaper p in here) p.unit}.toList();
          if (_unit != null && !units.contains(_unit)) _unit = null;
          final String? unit = _unit ?? (units.isNotEmpty ? units.first : null);
          final List<DiagPaper> papers = here.where((p) => p.unit == unit).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            children: [
              _hero(),
              const SizedBox(height: 14),
              if (widget.isStudent && _history.isNotEmpty) ...[_myGrowthCard(), const SizedBox(height: 14)],
              if (!widget.isStudent && _kids.isNotEmpty) ...[_kidsCard(), const SizedBox(height: 14)],
              _sectionTitle('SUBJECT', '과목'),
              _chipRow(kDiagSubjects, _subject, (s) => setState(() {
                _subject = s;
                _unit = null;
              }), label: (s) => '${_kSubjectEmoji[s]} ${_ko ? s : _kSubjectEn[s]}'),
              const SizedBox(height: 12),
              _sectionTitle('GRADE', '학년 · 학기'),
              _chipRow(kDiagGrades, _grade, (g) => setState(() {
                _grade = g;
                _unit = null;
              })),
              const SizedBox(height: 8),
              _chipRow(const ['1', '2'], '$_semester', (s) => setState(() {
                _semester = int.parse(s);
                _unit = null;
              }), label: (s) => _kr('$s학기', 'Sem. $s')),
              const SizedBox(height: 16),
              if (!snap.hasData)
                const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(color: _kGold)))
              else if (units.isEmpty) ...[
                _emptyBox(),
                if (_admin && all.isEmpty) _seedButton(),
              ] else ...[
                _sectionTitle('UNIT', '단원'),
                _chipRow(units, unit!, (u) => setState(() => _unit = u)),
                const SizedBox(height: 16),
                _sectionTitle('CHOOSE YOUR PAPER', '시험지 고르기'),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(_kr('자신 있는 시험지를 직접 골라 보세요. 결과에 맞춰 단계를 알려 드려요.', 'Pick the paper you feel ready for.'),
                      style: _ks(12, color: Colors.white54, w: FontWeight.w500)),
                ),
                for (final String lv in kPaperLevels) _paperCard(lv, papers.where((p) => p.level == lv).toList()),
              ],
              const SizedBox(height: 10),
              _ruleCard(),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------- 꾸밈 조각
  Widget _hero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF16213A), Color(0xFF0A0F1E)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGold.withValues(alpha: 0.55), width: 1.2),
        boxShadow: [BoxShadow(color: _kGold.withValues(alpha: 0.12), blurRadius: 24)],
      ),
      child: Row(children: [
        Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _kGoldGrad),
          child: const Text('🩺', style: TextStyle(fontSize: 26)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DIAGNOSTIC TEST', style: _en(12).copyWith(letterSpacing: 2)),
            const SizedBox(height: 2),
            Text(_kr('지금 내 실력, 정확히 알기', 'Know your level'), style: _ks(16)),
            const SizedBox(height: 4),
            Text(
              _kr('시험지를 골라 앱이나 종이로 풀고 답을 내면 바로 채점 · 단계 판정 · 맞춤 교재까지 이어집니다.',
                  'Solve, submit, and get your level and matching books instantly.'),
              style: _ks(11.5, color: Colors.white60, w: FontWeight.w500, h: 1.45),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _sectionTitle(String en, String ko) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Text(en, style: _en(11).copyWith(letterSpacing: 1.5)),
      if (_ko) ...[const SizedBox(width: 8), Text(ko, style: _ks(13.5, color: _kCream))],
    ]),
  );

  Widget _chipRow(List<String> items, String sel, ValueChanged<String> onTap, {String Function(String)? label}) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((it) {
        final bool on = it == sel;
        return GestureDetector(
          onTap: () => onTap(it),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              gradient: on ? _kGoldGrad : null,
              color: on ? null : _kCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kGold.withValues(alpha: on ? 1 : 0.3)),
            ),
            child: Text(label?.call(it) ?? it, style: _ks(12.5, color: on ? Colors.black : Colors.white70)),
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyBox() => Container(
    margin: const EdgeInsets.only(top: 6),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
    child: Text(
      _kr('이 학년 · 학기의 시험지를 준비하고 있어요.\n곧 원장님이 시험지를 올려 드릴게요.', 'Papers for this grade are coming soon.'),
      textAlign: TextAlign.center,
      style: _ks(13, color: Colors.white38, w: FontWeight.w500, h: 1.7),
    ),
  );

  Widget _seedButton() => Padding(
    padding: const EdgeInsets.fromLTRB(30, 14, 30, 0),
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _kGold),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _seeding
          ? null
          : () async {
        setState(() => _seeding = true);
        final int n = await SkillDiagService.seedSamples();
        if (!mounted) return;
        setState(() {
          _seeding = false;
          _subject = '수학';
          _grade = '중2';
          _semester = 1;
        });
        _snack('샘플 시험지 $n장을 넣었어요 (중2 1학기 수학).', '$n sample papers added.');
      },
      icon: const Icon(Icons.auto_awesome_rounded, color: _kGold),
      label: Text(_seeding ? _kr('넣는 중...', 'Adding...') : _kr('샘플 시험지 3장 넣기 (관리자)', 'Add 3 sample papers'),
          style: _ks(13, color: _kGold)),
    ),
  );

  Widget _paperCard(String lv, List<DiagPaper> list) {
    final List<String> lab = _kPaperLabel[lv]!;
    final DiagPaper? p = list.isEmpty ? null : list.first;
    final bool ready = p != null && p.questions.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kGold.withValues(alpha: ready ? 0.55 : 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(lab[2], style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_kr(lab[0], lab[1]), style: _ks(15.5)),
              Text(ready ? _kr('${p!.questions.length}문항 · ${p.totalPoints}점 만점', '${p.questions.length} questions') : _kr('준비 중', 'Coming soon'),
                  style: _ks(11.5, color: ready ? _kGold : Colors.white30, w: FontWeight.w600)),
            ]),
          ),
          if (_admin && p != null)
            IconButton(icon: const Icon(Icons.edit_note_rounded, color: _kGold), onPressed: () => _openEditor(p)),
          if (_admin && p != null && !p.active) Text(_kr('숨김', 'Hidden'), style: _ks(11, color: Colors.white38)),
        ]),
        const SizedBox(height: 6),
        Text(_kr(_kPaperDesc[lv]![0], _kPaperDesc[lv]![1]), style: _ks(12, color: Colors.white60, w: FontWeight.w500, h: 1.45)),
        if (ready) ...[
          const SizedBox(height: 10),
          Row(children: [
            if (widget.isStudent || _admin) ...[
              Expanded(
                child: _goldButton(Icons.edit_rounded, _kr('앱에서 풀기', 'Solve in App'), () => _start(p!, 'app')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _lineButton(Icons.description_outlined, _kr('종이로 풀기', 'On Paper'), () => _start(p!, 'paper')),
              ),
            ] else
              Expanded(
                child: _lineButton(Icons.print_rounded, _kr('시험지 인쇄 (자녀용)', 'Print for child'), () => SkillDiagService.printPaper(p!)),
              ),
          ]),
        ],
      ]),
    );
  }

  Widget _goldButton(IconData icon, String text, VoidCallback onTap) => SizedBox(
    height: 42,
    child: ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: _kGold,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      onPressed: onTap,
      icon: Icon(icon, color: Colors.black, size: 18),
      label: FittedBox(child: Text(text, style: _ks(13, color: Colors.black))),
    ),
  );

  Widget _lineButton(IconData icon, String text, VoidCallback onTap) => SizedBox(
    height: 42,
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _kGold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      onPressed: onTap,
      icon: Icon(icon, color: _kGold, size: 18),
      label: FittedBox(child: Text(text, style: _ks(13, color: _kGold))),
    ),
  );

  Widget _ruleCard() {
    Widget row(String lv, String range) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 90, child: Text(_lvText(lv), style: _ks(12.5, color: _kCream))),
        Text(range, style: _ks(12, color: Colors.white60, w: FontWeight.w500)),
      ]),
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_kr('📏 단계 기준', '📏 Levels'), style: _ks(13, color: _kGold)),
        const SizedBox(height: 6),
        row('concept', _kr('50점 미만', 'under 50')),
        row('basic', _kr('50 ~ 69점', '50 – 69')),
        row('skilled', _kr('70 ~ 89점', '70 – 89')),
        row('advanced', _kr('90점 이상', '90+')),
        const SizedBox(height: 6),
        Text(
          _kr('경계 점수(50점대 후반 · 70점대 후반 · 80점대 후반)는 한 단계 위 교재도 함께 고를 수 있게 알려 드려요.',
              'Near the next level, we also suggest books one step up.'),
          style: _ks(11, color: Colors.white38, w: FontWeight.w500, h: 1.5),
        ),
      ]),
    );
  }

  Widget _myGrowthCard() {
    final List<String> subs = kDiagSubjects.where((s) => _history.any((r) => r.subject == s)).toList();
    return _growthBox(_kr('📈 나의 진단 기록', '📈 My Results'), [
      for (final String s in subs) _growthLine(s, SkillDiagService.growthText(_history, s)),
    ]);
  }

  Widget _kidsCard() {
    final List<Widget> rows = [];
    for (final _KidDiag k in _kids) {
      final List<String> subs = kDiagSubjects.where((s) => k.hist.any((r) => r.subject == s)).toList();
      if (subs.isEmpty) continue;
      rows.add(Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 2),
        child: Text('👤 ${k.name}', style: _ks(13, color: _kCream)),
      ));
      for (final String s in subs) {
        rows.add(_growthLine(s, SkillDiagService.growthText(k.hist, s)));
      }
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return _growthBox(_kr('📈 자녀 진단 기록', '📈 Child Results'), rows);
  }

  Widget _growthBox(String title, List<Widget> rows) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _kCardHi,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _kGold.withValues(alpha: 0.4)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: _ks(13.5, color: _kGold)),
      const SizedBox(height: 4),
      ...rows,
    ]),
  );

  Widget _growthLine(String subject, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${_kSubjectEmoji[subject]} ', style: const TextStyle(fontSize: 14)),
      SizedBox(width: 44, child: Text(_ko ? subject : _kSubjectEn[subject]!, style: _ks(12.5))),
      Expanded(child: Text(text, style: _ks(12, color: Colors.white70, w: FontWeight.w500, h: 1.45))),
    ]),
  );

  // ---------------------------------------------------------------- 시작
  Future<void> _start(DiagPaper p, String mode) async {
    final DiagResult? r = await Navigator.of(context).push<DiagResult>(
      MaterialPageRoute(builder: (_) => _SolveScreen(paper: p, mode: mode)),
    );
    if (r == null || !mounted) return;
    await SkillDiagService.saveResult(r);
    await _loadHistory();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _ReportScreen(paper: p, result: r, history: _history, isStudent: widget.isStudent),
    ));
  }

  Future<void> _openEditor(DiagPaper p) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _PaperEditorScreen(paper: p)));
  }
}

class _KidDiag {
  final String name;
  final List<DiagResult> hist;
  _KidDiag(this.name, this.hist);
}

// ============================================================================
// 풀기 화면 — 앱에서 풀기 / 종이로 풀기(답 입력표)
// ============================================================================
class _SolveScreen extends StatefulWidget {
  final DiagPaper paper;
  final String mode; // app / paper
  const _SolveScreen({required this.paper, required this.mode});

  @override
  State<_SolveScreen> createState() => _SolveScreenState();
}

class _SolveScreenState extends State<_SolveScreen> {
  late final List<String> _answers = List<String>.filled(widget.paper.questions.length, '');
  late final List<TextEditingController> _ctrls =
  List.generate(widget.paper.questions.length, (_) => TextEditingController());
  final Stopwatch _watch = Stopwatch()..start();
  Timer? _tick;

  bool get _paperMode => widget.mode == 'paper';
  int get _done => _answers.where((a) => a.trim().isNotEmpty).length;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    for (final TextEditingController c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  String get _clock {
    final int s = _watch.elapsed.inSeconds;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  Future<bool> _confirmLeave() async {
    if (_done == 0) return true;
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (c) => _luxConfirm(c, _kr('풀던 답이 사라져요. 나갈까요?', 'Leave? Your answers will be lost.'), _kr('나가기', 'Leave')),
    );
    return yes == true;
  }

  Future<void> _submit() async {
    final int empty = _answers.length - _done;
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (c) => _luxConfirm(
        c,
        empty > 0
            ? _kr('아직 답하지 않은 문항이 $empty개 있어요.\n그래도 제출할까요?', '$empty unanswered. Submit anyway?')
            : _kr('답지를 제출할까요?\n제출하면 바로 채점됩니다.', 'Submit your answers?'),
        _kr('제출', 'Submit'),
      ),
    );
    if (yes != true || !mounted) return;
    _watch.stop();
    final DiagResult r = SkillDiagService.grade(widget.paper, _answers, seconds: _watch.elapsed.inSeconds, mode: widget.mode);
    Navigator.of(context).pop(r);
  }

  @override
  Widget build(BuildContext context) {
    final DiagPaper p = widget.paper;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBg,
          elevation: 0,
          iconTheme: const IconThemeData(color: _kGold),
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(_paperMode ? 'ANSWER SHEET' : 'TEST', style: _en(11).copyWith(letterSpacing: 1.5)),
            Text('${_kr(_kPaperLabel[p.level]![0], _kPaperLabel[p.level]![1])} · ${p.unit}', style: _ks(14), overflow: TextOverflow.ellipsis),
          ]),
          actions: [
            if (_paperMode)
              IconButton(
                tooltip: _kr('시험지 인쇄', 'Print'),
                icon: const Icon(Icons.print_rounded, color: _kGold),
                onPressed: () => SkillDiagService.printPaper(p),
              ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Text('⏱ $_clock', style: _ks(13, color: _kCream)),
              ),
            ),
          ],
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(children: [
              Row(children: [
                Text(_kr('답한 문항', 'Answered'), style: _ks(12, color: Colors.white54, w: FontWeight.w500)),
                const Spacer(),
                Text('$_done / ${p.questions.length}', style: _ks(13, color: _kGold)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: p.questions.isEmpty ? 0 : _done / p.questions.length,
                  minHeight: 6,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation(_kGold),
                ),
              ),
            ]),
          ),
          if (_paperMode)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kGold.withValues(alpha: 0.3))),
              child: Row(children: [
                const Text('🖨️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _kr('위 인쇄 단추로 시험지를 뽑아 종이에 푼 뒤, 아래 답 입력표에 답만 넣고 제출하세요.',
                        'Print with the button above, solve on paper, then enter only your answers.'),
                    style: _ks(11.5, color: Colors.white70, w: FontWeight.w500, h: 1.45),
                  ),
                ),
              ]),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              itemCount: p.questions.length,
              itemBuilder: (_, i) => _paperMode ? _omrRow(i) : _questionCard(i),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 6,
                  ),
                  onPressed: _submit,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('SUBMIT', style: _en(11, color: Colors.black)),
                    Text(_kr('답지 제출 · 바로 채점', 'Submit & Grade'), style: _ks(15, color: Colors.black)),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _numBadge(int i) => Container(
    width: 30,
    height: 30,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: _answers[i].trim().isNotEmpty ? _kGoldGrad : null,
      border: _answers[i].trim().isNotEmpty ? null : Border.all(color: _kGold),
    ),
    child: Text('${i + 1}', style: _en(14, color: _answers[i].trim().isNotEmpty ? Colors.black : _kGold)),
  );

  Widget _choiceDots(int i) {
    const List<String> circled = ['①', '②', '③', '④', '⑤'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (c) {
        final bool on = _answers[i] == '${c + 1}';
        return GestureDetector(
          onTap: () => setState(() => _answers[i] = on ? '' : '${c + 1}'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 46,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: on ? _kGoldGrad : null,
              color: on ? null : _kBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kGold.withValues(alpha: on ? 1 : 0.35)),
            ),
            child: Text(circled[c], style: TextStyle(fontSize: 18, color: on ? Colors.black : _kCream, fontWeight: FontWeight.bold)),
          ),
        );
      }),
    );
  }

  Widget _shortField(int i) => TextField(
    controller: _ctrls[i],
    onChanged: (v) => setState(() => _answers[i] = v),
    style: _ks(15, color: Colors.white),
    decoration: InputDecoration(
      hintText: _kr('답 입력 (분수는 4/9 처럼)', 'Answer (fractions like 4/9)'),
      hintStyle: _ks(12.5, color: Colors.white30, w: FontWeight.w500),
      filled: true,
      fillColor: _kBg,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _kGold.withValues(alpha: 0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kGold)),
    ),
  );

  Widget _questionCard(int i) {
    final DiagQuestion q = widget.paper.questions[i];
    const List<String> circled = ['①', '②', '③', '④', '⑤'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kGold.withValues(alpha: _answers[i].trim().isNotEmpty ? 0.6 : 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _numBadge(i),
          const SizedBox(width: 10),
          Expanded(child: Text(q.text, style: _ks(14.5, h: 1.6, w: FontWeight.w600))),
          const SizedBox(width: 6),
          Text(_kr('${q.points}점', '${q.points}pt'), style: _ks(11, color: Colors.white38)),
        ]),
        const SizedBox(height: 12),
        if (q.type == 'mc')
          ...List.generate(q.choices.length.clamp(0, 5), (c) {
            final bool on = _answers[i] == '${c + 1}';
            return GestureDetector(
              onTap: () => setState(() => _answers[i] = on ? '' : '${c + 1}'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: on ? _kGold.withValues(alpha: 0.16) : _kBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: on ? _kGold : Colors.white12),
                ),
                child: Row(children: [
                  Text(circled[c], style: TextStyle(fontSize: 17, color: on ? _kGold : Colors.white54, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(q.choices[c], style: _ks(13.5, color: on ? _kCream : Colors.white70, w: FontWeight.w500))),
                ]),
              ),
            );
          })
        else
          _shortField(i),
      ]),
    );
  }

  Widget _omrRow(int i) {
    final DiagQuestion q = widget.paper.questions[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: Row(children: [
        _numBadge(i),
        const SizedBox(width: 10),
        Expanded(child: q.type == 'mc' ? _choiceDots(i) : _shortField(i)),
      ]),
    );
  }
}

Widget _luxConfirm(BuildContext c, String msg, String okText) => AlertDialog(
  backgroundColor: _kCard,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _kGold, width: 1.2)),
  content: Text(msg, textAlign: TextAlign.center, style: _ks(14, h: 1.6)),
  actionsAlignment: MainAxisAlignment.center,
  actions: [
    TextButton(onPressed: () => Navigator.pop(c, false), child: Text(_kr('닫기', 'Close'), style: _ks(13, color: Colors.white54))),
    ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: _kGold),
      onPressed: () => Navigator.pop(c, true),
      child: Text(okText, style: _ks(13, color: Colors.black)),
    ),
  ],
);

// ============================================================================
// 리포트 — 점수 · 단계 · 문항별 O/X · 개념별 분석 · 교재 길잡이 연결
// ============================================================================
class _ReportScreen extends StatelessWidget {
  final DiagPaper paper;
  final DiagResult result;
  final List<DiagResult> history;
  final bool isStudent;
  const _ReportScreen({required this.paper, required this.result, required this.history, required this.isStudent});

  /// 교재 길잡이 과목 이름 (고등 과학 = 통합과학)
  String get _guideSubject => (result.subject == '과학' && result.grade.startsWith('고')) ? '통합과학' : result.subject;

  void _openGuide(BuildContext context, String level) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TextbookGuideScreen(
        isStudent: isStudent,
        initialGrade: result.grade,
        initialSubject: _guideSubject,
        initialLevel: level,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final DiagResult r = result;
    final int ok = r.correct.where((e) => e).length;
    final int mins = r.seconds ~/ 60;
    final int secs = r.seconds % 60;
    final List<MapEntry<String, List<int>>> concepts = r.concepts.entries.toList()
      ..sort((a, b) => (a.value[0] / a.value[1]).compareTo(b.value[0] / b.value[1]));
    final List<String> weak = concepts.where((e) => e.value[0] < e.value[1]).map((e) => e.key).toList();

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kGold),
        centerTitle: true,
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('DIAGNOSIS REPORT', style: _en(12).copyWith(letterSpacing: 1.5)),
          if (_ko) Text('진단 리포트', style: _ks(16)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
        children: [
          // ---------------- 점수 · 단계
          Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A2440), Color(0xFF0A0F1E)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kGold.withValues(alpha: 0.7), width: 1.3),
              boxShadow: [BoxShadow(color: _kGold.withValues(alpha: 0.15), blurRadius: 28)],
            ),
            child: Column(children: [
              Text('${r.subject} · ${r.grade} ${r.semester}${_kr('학기', '')} · ${r.unit}', style: _ks(12.5, color: Colors.white60, w: FontWeight.w500)),
              Text(_kr(_kPaperLabel[r.paperLevel]![0], _kPaperLabel[r.paperLevel]![1]), style: _ks(13, color: _kCream)),
              const SizedBox(height: 16),
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: r.score / 100,
                      strokeWidth: 10,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation(_kGold),
                    ),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${r.score}', style: GoogleFonts.gowunBatang(color: _kGold, fontWeight: FontWeight.bold, fontSize: 46)),
                    Text(_kr('점', 'points'), style: _ks(12, color: Colors.white54)),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(gradient: _kGoldGrad, borderRadius: BorderRadius.circular(24)),
                child: Text('${_kr('판정', 'Level')}  ${_lvText(r.level)}', style: _ks(16, color: Colors.black)),
              ),
              if (r.flexLevel != null) ...[
                const SizedBox(height: 8),
                Text(_kr('✨ ${_lvText(r.flexLevel!)} 교재도 함께 고를 수 있어요', '✨ ${_lvText(r.flexLevel!)} books also fit'),
                    style: _ks(12.5, color: _kGold)),
              ],
              const SizedBox(height: 10),
              Text(r.note, textAlign: TextAlign.center, style: _ks(13, color: _kCream, w: FontWeight.w600, h: 1.5)),
              const SizedBox(height: 10),
              Text(
                _kr('맞은 문항 $ok / ${r.correct.length} · 걸린 시간 $mins분 $secs초 · ${r.mode == 'paper' ? '종이로 풂' : '앱에서 풂'}',
                    '$ok / ${r.correct.length} correct · ${mins}m ${secs}s'),
                style: _ks(11.5, color: Colors.white54, w: FontWeight.w500),
              ),
            ]),
          ),
          const SizedBox(height: 14),

          // ---------------- 문항별 O / X
          _box(_kr('📝 문항별 채점', '📝 By Question'), [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(r.correct.length, (i) {
                final bool c = r.correct[i];
                return Container(
                  width: 54,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: (c ? _kOk : _kNo).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: (c ? _kOk : _kNo).withValues(alpha: 0.6)),
                  ),
                  child: Column(children: [
                    Text('${i + 1}', style: _ks(12, color: Colors.white70)),
                    Text(c ? 'O' : 'X', style: GoogleFonts.gowunBatang(color: c ? _kOk : _kNo, fontWeight: FontWeight.bold, fontSize: 18)),
                  ]),
                );
              }),
            ),
            const SizedBox(height: 10),
            for (int i = 0; i < r.correct.length; i++)
              if (!r.correct[i] && i < paper.questions.length)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${i + 1}${_kr('번', '.')}  ${_kr('내 답', 'Mine')}: ${r.answers[i].isEmpty ? '—' : _showAns(paper.questions[i], r.answers[i])}   ·   ${_kr('정답', 'Answer')}: ${_showAns(paper.questions[i], paper.questions[i].answer.split('|').first)}',
                    style: _ks(12, color: Colors.white60, w: FontWeight.w500),
                  ),
                ),
          ]),
          const SizedBox(height: 12),

          // ---------------- 개념별
          _box(_kr('🔍 개념별 분석', '🔍 By Concept'), [
            for (final MapEntry<String, List<int>> e in concepts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  SizedBox(width: 120, child: Text(e.key, style: _ks(12.5, color: _kCream), overflow: TextOverflow.ellipsis)),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: e.value[1] == 0 ? 0 : e.value[0] / e.value[1],
                        minHeight: 8,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation(e.value[0] == e.value[1] ? _kOk : (e.value[0] == 0 ? _kNo : _kGold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${e.value[0]}/${e.value[1]}', style: _ks(12, color: Colors.white60)),
                ]),
              ),
            if (weak.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_kr('👉 다시 볼 개념: ${weak.join(' · ')}', '👉 Review: ${weak.join(' · ')}'), style: _ks(12.5, color: _kGold, h: 1.5)),
            ] else ...[
              const SizedBox(height: 8),
              Text(_kr('👏 모든 개념을 맞혔어요!', '👏 All concepts correct!'), style: _ks(12.5, color: _kOk)),
            ],
          ]),
          const SizedBox(height: 12),

          // ---------------- 성장
          _box(_kr('📈 출발점과 성장', '📈 Growth'), [
            Text(
              r.isBaseline
                  ? _kr('이번 진단이 ${r.subject}의 출발점으로 저장됐어요. 한 달 뒤 다시 진단하면 성장을 비교해 드려요.',
                  'Saved as your ${r.subject} baseline. Re-test in a month to compare.')
                  : SkillDiagService.growthText(history, r.subject),
              style: _ks(12.5, color: _kCream, w: FontWeight.w500, h: 1.6),
            ),
          ]),
          const SizedBox(height: 18),

          // ---------------- 교재 길잡이
          SizedBox(
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 6,
              ),
              onPressed: () => _openGuide(context, r.level),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('TEXTBOOK GUIDE', style: _en(11, color: Colors.black)),
                Text(_kr('📚 ${_lvText(r.level)} 교재 보기', '📚 See ${_lvText(r.level)} books'), style: _ks(15, color: Colors.black)),
              ]),
            ),
          ),
          if (r.flexLevel != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kGold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _openGuide(context, r.flexLevel!),
                child: Text(_kr('✨ ${_lvText(r.flexLevel!)} 교재도 보기', '✨ Also see ${_lvText(r.flexLevel!)}'), style: _ks(14, color: _kGold)),
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_kr('닫기', 'Close'), style: _ks(13, color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  static String _showAns(DiagQuestion q, String a) {
    if (q.type != 'mc') return a;
    const List<String> circled = ['①', '②', '③', '④', '⑤'];
    final int? n = int.tryParse(a.trim());
    return (n != null && n >= 1 && n <= 5) ? circled[n - 1] : a;
  }

  Widget _box(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kGold.withValues(alpha: 0.25))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: _ks(14, color: _kGold)),
      const SizedBox(height: 10),
      ...children,
    ]),
  );
}

// ============================================================================
// 관리자 — 시험지 만들기 · 고치기 (문제 · 보기 · 정답 · 배점 · 개념)
// ============================================================================
class _PaperEditorScreen extends StatefulWidget {
  final DiagPaper paper;
  const _PaperEditorScreen({required this.paper});

  @override
  State<_PaperEditorScreen> createState() => _PaperEditorScreenState();
}

class _PaperEditorScreenState extends State<_PaperEditorScreen> {
  late final DiagPaper p = DiagPaper(
    id: widget.paper.id,
    subject: widget.paper.subject,
    grade: widget.paper.grade,
    semester: widget.paper.semester,
    unit: widget.paper.unit,
    level: widget.paper.level,
    active: widget.paper.active,
    order: widget.paper.order,
    questions: widget.paper.questions
        .map((q) => DiagQuestion(type: q.type, text: q.text, choices: List<String>.from(q.choices), answer: q.answer, points: q.points, concept: q.concept))
        .toList(),
  );
  late final TextEditingController _unit = TextEditingController(text: p.unit);
  bool _saving = false;

  @override
  void dispose() {
    _unit.dispose();
    super.dispose();
  }

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: _ks(12, color: Colors.white30, w: FontWeight.w500),
    filled: true,
    fillColor: _kBg,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: _kGold.withValues(alpha: 0.25))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: _kGold)),
  );

  Widget _pills(List<String> items, String sel, ValueChanged<String> on, {String Function(String)? label}) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: items
        .map((it) => GestureDetector(
      onTap: () => setState(() => on(it)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: it == sel ? _kGold : _kBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kGold.withValues(alpha: it == sel ? 1 : 0.3)),
        ),
        child: Text(label?.call(it) ?? it, style: _ks(12, color: it == sel ? Colors.black : Colors.white70)),
      ),
    ))
        .toList(),
  );

  Widget _label(String en, String ko) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Row(children: [Text(en, style: _en(11)), const SizedBox(width: 6), Text(ko, style: _ks(12.5, color: _kCream))]),
  );

  Future<void> _save() async {
    p.unit = _unit.text.trim();
    if (p.unit.isEmpty || p.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('단원 이름과 문제를 1개 이상 넣어 주세요.', style: _ks(13))));
      return;
    }
    setState(() => _saving = true);
    final bool ok = await SkillDiagService.savePaper(p);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: _kCard,
      content: Text(ok ? '저장했어요.' : '저장하지 못했어요. 서버 규칙(diagPapers)을 확인해 주세요.', style: _ks(13, color: _kCream)),
    ));
    if (ok) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final bool? yes = await showDialog<bool>(context: context, builder: (c) => _luxConfirm(c, '이 시험지를 지울까요?', '삭제'));
    if (yes != true) return;
    final bool ok = await SkillDiagService.deletePaper(p.id);
    if (mounted && ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kGold),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(p.id.isEmpty ? 'NEW PAPER' : 'EDIT PAPER', style: _en(11)),
          Text(p.id.isEmpty ? '시험지 만들기' : '시험지 고치기', style: _ks(15)),
        ]),
        actions: [
          if (p.id.isNotEmpty) IconButton(icon: const Icon(Icons.print_rounded, color: _kGold), tooltip: '정답지 인쇄', onPressed: () => SkillDiagService.printPaper(p, withAnswers: true)),
          if (p.id.isNotEmpty) IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        children: [
          _label('SUBJECT', '과목'),
          _pills(kDiagSubjects, p.subject, (v) => p.subject = v),
          _label('GRADE', '학년 · 학기'),
          _pills(kDiagGrades, p.grade, (v) => p.grade = v),
          const SizedBox(height: 6),
          _pills(const ['1', '2'], '${p.semester}', (v) => p.semester = int.parse(v), label: (v) => '$v학기'),
          _label('UNIT', '단원 이름'),
          TextField(controller: _unit, style: _ks(13.5), decoration: _deco('예: 유리수와 순환소수')),
          _label('PAPER', '시험지'),
          _pills(kPaperLevels, p.level, (v) => p.level = v, label: (v) => '${_kPaperLabel[v]![2]} ${_kPaperLabel[v]![0]}'),
          Row(children: [
            Switch(value: p.active, activeThumbColor: _kGold, onChanged: (v) => setState(() => p.active = v)),
            Text(p.active ? '학생에게 보이기' : '숨김 (만드는 중)', style: _ks(12.5, color: _kCream)),
          ]),
          _label('QUESTIONS', '문제 (${p.questions.length}개 · ${p.totalPoints}점)'),
          for (int i = 0; i < p.questions.length; i++) _qEditor(i),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _kGold),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => setState(() => p.questions.add(DiagQuestion(points: p.questions.isEmpty ? 20 : p.questions.last.points))),
            icon: const Icon(Icons.add_rounded, color: _kGold),
            label: Text('문제 추가', style: _ks(13, color: _kGold)),
          ),
          const SizedBox(height: 6),
          Text('· 단답형 정답이 여러 모양이면 | 로 나눠 적으세요 (예: 4/9|0.444…)\n· 분수는 값이 같으면 정답으로 채점합니다 (예: 2/4 = 1/2)',
              style: _ks(11, color: Colors.white38, w: FontWeight.w500, h: 1.6)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _kGold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _saving ? null : _save,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Save', style: _en(11, color: Colors.black)),
                Text(_saving ? '저장 중...' : '시험지 저장', style: _ks(14, color: Colors.black)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _qEditor(int i) {
    final DiagQuestion q = p.questions[i];
    const List<String> circled = ['①', '②', '③', '④', '⑤'];
    return Container(
      key: ObjectKey(q),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kGold.withValues(alpha: 0.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${i + 1}번', style: _ks(14, color: _kGold)),
          const SizedBox(width: 10),
          _pills(const ['mc', 'short'], q.type, (v) => q.type = v, label: (v) => v == 'mc' ? '객관식' : '단답형'),
          const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
            onPressed: () => setState(() => p.questions.removeAt(i)),
          ),
        ]),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: q.text,
          maxLines: 4,
          minLines: 2,
          onChanged: (v) => q.text = v,
          style: _ks(13, w: FontWeight.w500),
          decoration: _deco('문제'),
        ),
        if (q.type == 'mc') ...[
          const SizedBox(height: 6),
          for (int c = 0; c < 5; c++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                SizedBox(width: 26, child: Text(circled[c], style: const TextStyle(color: _kGold, fontSize: 16))),
                Expanded(
                  child: TextFormField(
                    initialValue: c < q.choices.length ? q.choices[c] : '',
                    onChanged: (v) {
                      while (q.choices.length < 5) {
                        q.choices.add('');
                      }
                      q.choices[c] = v;
                    },
                    style: _ks(12.5, w: FontWeight.w500),
                    decoration: _deco('보기 ${c + 1}'),
                  ),
                ),
              ]),
            ),
        ],
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: q.answer,
              onChanged: (v) => q.answer = v.trim(),
              style: _ks(13, color: _kGold),
              decoration: _deco(q.type == 'mc' ? '정답 번호 (1~5)' : '정답 (예: 4/9)'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: '${q.points}',
              keyboardType: TextInputType.number,
              onChanged: (v) => setState(() => q.points = int.tryParse(v) ?? q.points),
              style: _ks(13),
              decoration: _deco('배점'),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: q.concept,
          onChanged: (v) => q.concept = v,
          style: _ks(12.5, w: FontWeight.w500),
          decoration: _deco('세부 개념 (예: 순환마디) — 리포트 분석용'),
        ),
      ]),
    );
  }
}
