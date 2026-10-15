// ============================================================================
// 🆕 [2026-10-15] 📖 자주 묻는 상담 (FAQ) — 공지 및 교육상담 → 교육상담
//
// · 원장님(관리자)만 질문과 답을 올리고 · 고치고 · 지울 수 있음
// · 학생 · 학부모는 읽기만 (기다림 없이 바로 보는 상담)
// · 분류: 전체 / 공부 방법 / 교재 · 진단 / 앱 사용법 / 별 · 장학금 / 마음 · 생활
// · 보는 사람: 모두 / 학생만 / 학부모만 — 고른 사람에게만 보임 (관리자는 모두 보임)
// · 📌 추천 질문은 맨 위 · 찾기 칸으로 질문 · 답에서 낱말 찾기
// · 처음 비어 있을 때 관리자 화면에 [기본 질문 8개 넣기] 단추 (원장님이 고쳐 쓰면 됨)
//
// 서버: Firestore faqs 컬렉션 (질문 · 답 · 분류 · 보는 사람 · 순서 · 추천)
// ⚠️ Firestore 규칙에 faqs 블록 추가 필요 (읽기 = 로그인한 사람, 쓰기 = 관리자)
// 글자: 한글 = Noto Sans KR, 영어 = 고운바탕 굵게
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsu_studyup/global_lang.dart';
import 'package:gsu_studyup/services/notice_counsel_service.dart';

const Color _kBg = Color(0xFF030712);
const Color _kCard = Color(0xFF0D1527);
const Color _kCardHi = Color(0xFF111A2E);
const Color _kGold = Color(0xFFE5C158);
const Color _kDeepGold = Color(0xFFD4AF37);
const Color _kCream = Color(0xFFFFF6D6);

// ---------------------------------------------------------------------------
// 분류 · 보는 사람
// ---------------------------------------------------------------------------
const List<String> kFaqCats = ['study', 'book', 'app', 'star', 'mind'];
const Map<String, List<String>> _kCatLabel = {
  'all': ['전체', 'All'],
  'study': ['공부 방법', 'Study'],
  'book': ['교재 · 진단', 'Books'],
  'app': ['앱 사용법', 'App'],
  'star': ['별 · 장학금', 'Stars'],
  'mind': ['마음 · 생활', 'Life'],
};
const Map<String, String> _kCatEmoji = {
  'all': '✨',
  'study': '📘',
  'book': '📚',
  'app': '📱',
  'star': '⭐',
  'mind': '🌿',
};
const Map<String, List<String>> _kAudLabel = {
  'all': ['모두', 'Everyone'],
  'student': ['학생', 'Students'],
  'parent': ['학부모', 'Parents'],
};

bool get _ko => !DkeLang.isForeignSelected && DkeLang.current != 'EN';
String _lbl(List<String> pair) => _ko ? pair[0] : pair[1];

// ---------------------------------------------------------------------------
// 데이터
// ---------------------------------------------------------------------------
class FaqItem {
  final String id;
  final String question;
  final String answer;
  final String category;
  final String audience; // all / student / parent
  final int order;
  final bool pinned;
  final DateTime? createdAt;
  FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.audience,
    required this.order,
    required this.pinned,
    required this.createdAt,
  });

  factory FaqItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final Map<String, dynamic> m = d.data() ?? {};
    final dynamic ts = m['createdAt'];
    return FaqItem(
      id: d.id,
      question: (m['question'] ?? '').toString(),
      answer: (m['answer'] ?? '').toString(),
      category: (m['category'] ?? 'study').toString(),
      audience: (m['audience'] ?? 'all').toString(),
      order: (m['order'] as num?)?.toInt() ?? 100,
      pinned: m['pinned'] == true,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

class FaqService {
  FaqService._();
  static final CollectionReference<Map<String, dynamic>> _col = FirebaseFirestore.instance.collection('faqs');

  static Stream<List<FaqItem>> watch() {
    return _col.snapshots().map((s) {
      final List<FaqItem> list = s.docs.map(FaqItem.fromDoc).toList();
      list.sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        if (a.order != b.order) return a.order.compareTo(b.order);
        return (b.createdAt ?? DateTime(2100)).compareTo(a.createdAt ?? DateTime(2100));
      });
      return list;
    });
  }

  static Future<bool> save({
    String? id,
    required String question,
    required String answer,
    required String category,
    required String audience,
    required int order,
    required bool pinned,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'question': question,
        'answer': answer,
        'category': category,
        'audience': audience,
        'order': order,
        'pinned': pinned,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (id == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await _col.add(data);
      } else {
        await _col.doc(id).set(data, SetOptions(merge: true));
      }
      return true;
    } catch (e) {
      debugPrint('[FaqService] 저장 실패: $e');
      return false;
    }
  }

  static Future<bool> delete(String id) async {
    try {
      await _col.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('[FaqService] 삭제 실패: $e');
      return false;
    }
  }

  /// 처음 비어 있을 때 넣는 기본 질문 (원장님이 고쳐 쓰시면 됨)
  static Future<int> seedDefaults() async {
    int n = 0;
    for (int i = 0; i < _kSeed.length; i++) {
      final Map<String, String> q = _kSeed[i];
      final bool ok = await save(
        question: q['q']!,
        answer: q['a']!,
        category: q['c']!,
        audience: q['w']!,
        order: (i + 1) * 10,
        pinned: i < 2,
      );
      if (ok) n++;
    }
    return n;
  }
}

const List<Map<String, String>> _kSeed = [
  {
    'c': 'study',
    'w': 'all',
    'q': '하루에 몇 시간 공부해야 하나요?',
    'a': '시간보다 "매일 빠짐없이"가 더 중요합니다. 처음에는 하루 50분이라도 꾸준히 기록하는 습관부터 만드세요. 25분 집중 + 5분 휴식(포모도로)을 두세 번 하면 금방 50~75분이 됩니다. 2주 동안 빠짐없이 기록이 쌓이면 그때 목표 시간을 조금씩 늘려 가세요.',
  },
  {
    'c': 'study',
    'w': 'student',
    'q': '공부할 때 자꾸 휴대폰을 보게 돼요.',
    'a': '의지의 문제가 아니라 환경의 문제입니다. 타이머를 켜면 다른 앱으로 나갈 때 자동으로 멈추니, 휴대폰은 타이머만 켜 둔 채 손이 닿지 않는 곳에 두세요. 처음엔 25분만 버티면 됩니다. 25분을 지켜 낸 날은 스스로 칭찬해 주세요.',
  },
  {
    'c': 'study',
    'w': 'all',
    'q': '오답 정리는 꼭 해야 하나요?',
    'a': '네, 성적이 오르는 학생과 제자리인 학생의 가장 큰 차이가 오답 정리입니다. 틀린 문제를 다시 푸는 것보다 "왜 틀렸는지"를 한 줄로 적는 것이 핵심입니다. 개념을 몰랐는지, 실수였는지, 시간이 부족했는지만 구분해도 다음 시험이 달라집니다.',
  },
  {
    'c': 'book',
    'w': 'parent',
    'q': '아이에게 어떤 교재를 사 줘야 할지 모르겠어요.',
    'a': '교육상담의 📚 교재 길잡이에서 학년 · 과목을 고르고 [진단하기]를 해 보세요. 최근 점수와 몇 가지 질문으로 개념 · 기본 · 실력 · 심화 중 지금 단계를 알려 드리고, 그 단계에 맞는 시중 교재를 순서대로 추천합니다. 교재는 "어려운 책"보다 "끝까지 풀 수 있는 책"이 좋습니다.',
  },
  {
    'c': 'book',
    'w': 'all',
    'q': '선행 학습은 꼭 해야 하나요?',
    'a': '현재 학년 내용을 80점 이상 안정적으로 받고 있다면 선행이 도움이 됩니다. 하지만 지금 학년 개념이 흔들리는데 선행만 하면 모래 위에 집을 짓는 것과 같습니다. 먼저 지금 학년의 기본 유형서를 끝까지 풀어 본 뒤 결정하세요.',
  },
  {
    'c': 'app',
    'w': 'all',
    'q': '알람이 울리지 않아요.',
    'a': '폰 설정 → 앱 → GKE StudyUp에서 ① 알림 허용 ② 알람 및 리마인더 허용 ③ 배터리 → 절전 예외 앱 등록, 세 가지를 확인해 주세요. 삼성 폰은 오래 쓰지 않은 앱을 재우기 때문에 절전 예외 등록이 꼭 필요합니다. 알람이 울리면 앱 어느 화면에서든 [알람 끄기] 화면이 뜹니다.',
  },
  {
    'c': 'star',
    'w': 'parent',
    'q': '별은 어떻게 모이고, 장학금은 어떻게 계산되나요?',
    'a': '타이머로 1분 공부하면 별 1개가 모이고, 학습기록 · 평가 기록 등을 하면 보너스별이 더해집니다. 장학금은 학부모님이 성장형 · 도전형 · 성취형 중 하나를 고르시면, 이번 달 모은 별에 그 유형의 단가를 곱해 한도 안에서 자동 계산됩니다. 부모님 · 가족이 보낸 응원별은 장학금에 들어가지 않고 따로 표시됩니다.',
  },
  {
    'c': 'mind',
    'w': 'all',
    'q': '공부가 하기 싫고 자꾸 지쳐요.',
    'a': '누구에게나 그런 날이 있습니다. 그런 날은 목표를 크게 낮춰 "25분 한 번"만 해 보세요. 작은 성공이 다시 힘을 줍니다. 잠이 부족하지 않은지도 꼭 살펴 주세요. 마음이 많이 힘들다면 혼자 견디지 말고 1:1 학습상담이나 청소년상담 1388에 이야기해 주세요.',
  },
];

// ============================================================================
// 화면
// ============================================================================
class FaqScreen extends StatefulWidget {
  /// 보는 사람: 'student' / 'parent' (관리자는 모두 보임)
  final String viewer;
  const FaqScreen({super.key, this.viewer = 'parent'});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  late final Stream<List<FaqItem>> _stream = FaqService.watch();
  final TextEditingController _search = TextEditingController();
  String _cat = 'all';
  String _query = '';
  final Set<String> _open = {};
  bool _seeding = false;

  bool get _admin => NoticeCounselService.isAdmin;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<FaqItem> _filter(List<FaqItem> all) {
    final String q = _query.trim().toLowerCase();
    return all.where((f) {
      if (!_admin && f.audience != 'all' && f.audience != widget.viewer) return false;
      if (_cat != 'all' && f.category != _cat) return false;
      if (q.isNotEmpty && !f.question.toLowerCase().contains(q) && !f.answer.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  void _snack(String ko, String en) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: _kCard,
      content: Text(_ko ? ko : en, style: GoogleFonts.notoSansKr(color: _kCream, fontWeight: FontWeight.bold)),
    ));
  }

  // ---------------------------------------------------------------- 화면 틀
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kGold),
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Common Questions', style: GoogleFonts.gowunBatang(color: _kGold, fontWeight: FontWeight.bold, fontSize: 13)),
            if (_ko) Text('자주 묻는 상담', style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
      floatingActionButton: _admin
          ? FloatingActionButton.extended(
        backgroundColor: _kGold,
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_comment_rounded, color: Colors.black),
        label: Text(_ko ? '질문 올리기' : 'Add Q&A', style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold)),
      )
          : null,
      body: StreamBuilder<List<FaqItem>>(
        stream: _stream,
        builder: (context, snap) {
          final List<Widget> items = [_hero(), _searchBox(), _catChips()];
          if (snap.hasError) {
            items.add(_empty(_ko ? '불러오지 못했어요. 잠시 후 다시 열어 주세요.' : 'Could not load. Please try again.'));
          } else if (!snap.hasData) {
            items.add(const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(color: _kGold)),
            ));
          } else {
            final List<FaqItem> all = snap.data!;
            final List<FaqItem> shown = _filter(all);
            if (all.isEmpty) {
              items.add(_empty(_ko ? '아직 올라온 질문이 없어요.\n곧 원장님이 자주 묻는 상담을 채워 드릴게요.' : 'No questions yet.'));
              if (_admin) items.add(_seedButton());
            } else if (shown.isEmpty) {
              items.add(_empty(_ko ? '찾는 질문이 없어요.\n궁금한 점은 💬 1:1 학습상담으로 물어봐 주세요.' : 'No matching questions.'));
            } else {
              items.add(Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                child: Text(
                  _ko ? '질문 ${shown.length}개 · 눌러서 답 보기' : '${shown.length} questions · tap to open',
                  style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 11.5),
                ),
              ));
              for (final FaqItem f in shown) {
                items.add(_faqCard(f));
              }
            }
          }
          items.add(_footer());
          return ListView(padding: const EdgeInsets.only(bottom: 100), children: items);
        },
      ),
    );
  }

  Widget _hero() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF16213A), Color(0xFF0A0F1E)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGold.withValues(alpha: 0.55), width: 1.2),
        boxShadow: [BoxShadow(color: _kGold.withValues(alpha: 0.12), blurRadius: 24)],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFFF6DD8A), _kDeepGold]),
            ),
            child: const Text('📖', style: TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FAQ', style: GoogleFonts.gowunBatang(color: _kGold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 2)),
                const SizedBox(height: 2),
                Text(
                  _ko ? '기다림 없이 바로 보는 상담' : 'Answers without waiting',
                  style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.5),
                ),
                const SizedBox(height: 4),
                Text(
                  _ko ? '40년 교육 현장에서 가장 많이 받은 질문에 원장님이 직접 답했습니다.' : 'Answers to the most common questions from 40 years of teaching.',
                  style: GoogleFonts.notoSansKr(color: Colors.white60, fontSize: 11.5, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v),
        style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13.5),
        decoration: InputDecoration(
          hintText: _ko ? '궁금한 낱말로 찾기 (예: 오답, 교재, 알람)' : 'Search (e.g. books, alarm)',
          hintStyle: GoogleFonts.notoSansKr(color: Colors.white30, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: _kGold),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white38),
            onPressed: () => setState(() {
              _search.clear();
              _query = '';
            }),
          ),
          filled: true,
          fillColor: _kCard,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _kGold.withValues(alpha: 0.25))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kGold)),
        ),
      ),
    );
  }

  Widget _catChips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: ['all', ...kFaqCats].map((c) {
          final bool on = _cat == c;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
            child: GestureDetector(
              onTap: () => setState(() => _cat = c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? _kGold : _kCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: on ? _kGold : _kGold.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${_kCatEmoji[c]} ${_lbl(_kCatLabel[c]!)}',
                  style: GoogleFonts.notoSansKr(color: on ? Colors.black : Colors.white70, fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _faqCard(FaqItem f) {
    final bool open = _open.contains(f.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GestureDetector(
        onTap: () => setState(() => open ? _open.remove(f.id) : _open.add(f.id)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: open ? _kCardHi : _kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: open ? _kGold.withValues(alpha: 0.75) : _kGold.withValues(alpha: 0.22), width: open ? 1.3 : 1),
            boxShadow: open ? [BoxShadow(color: _kGold.withValues(alpha: 0.10), blurRadius: 18)] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _badge('Q', filled: true),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (f.pinned) _tag('📌 ${_ko ? '추천' : 'Top'}', _kGold),
                            _tag('${_kCatEmoji[f.category] ?? ''} ${_lbl(_kCatLabel[f.category] ?? _kCatLabel['study']!)}', Colors.white54),
                            if (_admin) _tag('👁 ${_lbl(_kAudLabel[f.audience] ?? _kAudLabel['all']!)}', const Color(0xFF7DD3FC)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(f.question, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5, height: 1.45)),
                      ],
                    ),
                  ),
                  if (_admin)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.edit_note_rounded, color: _kGold),
                      onPressed: () => _openEditor(existing: f),
                    ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.keyboard_arrow_down_rounded, color: _kGold),
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                child: !open
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: [
                      Container(height: 1, color: _kGold.withValues(alpha: 0.18)),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _badge('A', filled: false),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SelectableText(
                              f.answer,
                              style: GoogleFonts.notoSansKr(color: _kCream, fontSize: 13.5, height: 1.75),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String t, {required bool filled}) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: filled ? const LinearGradient(colors: [Color(0xFFF6DD8A), _kDeepGold]) : null,
        border: filled ? null : Border.all(color: _kGold, width: 1.3),
      ),
      child: Text(t, style: GoogleFonts.gowunBatang(color: filled ? Colors.black : _kGold, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _tag(String t, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Text(t, style: GoogleFonts.notoSansKr(color: c, fontSize: 10.5, fontWeight: FontWeight.bold)),
    );
  }

  Widget _empty(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 20),
      child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 13, height: 1.7)),
    );
  }

  Widget _seedButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
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
          final int n = await FaqService.seedDefaults();
          if (!mounted) return;
          setState(() => _seeding = false);
          _snack('기본 질문 $n개를 넣었어요. 눌러서 고쳐 쓰세요.', '$n questions added.');
        },
        icon: const Icon(Icons.auto_awesome_rounded, color: _kGold),
        label: Text(
          _seeding ? (_ko ? '넣는 중...' : 'Adding...') : (_ko ? '기본 질문 8개 넣기 (관리자)' : 'Add 8 starter questions'),
          style: GoogleFonts.notoSansKr(color: _kGold, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            const Text('💬', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _ko ? '찾는 답이 없으면 1:1 학습상담에 물어봐 주세요.\n자주 받는 질문은 이곳에 차곡차곡 쌓아 갑니다.' : 'Not here? Ask in 1:1 Counseling.',
                style: GoogleFonts.notoSansKr(color: Colors.white60, fontSize: 12, height: 1.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- 관리자: 올리기 · 고치기
  Future<void> _openEditor({FaqItem? existing}) async {
    final TextEditingController q = TextEditingController(text: existing?.question ?? '');
    final TextEditingController a = TextEditingController(text: existing?.answer ?? '');
    final TextEditingController ord = TextEditingController(text: '${existing?.order ?? 100}');
    String cat = existing?.category ?? 'study';
    String aud = existing?.audience ?? 'all';
    bool pin = existing?.pinned ?? false;
    bool saving = false;

    InputDecoration deco(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.notoSansKr(color: Colors.white30, fontSize: 12.5),
      filled: true,
      fillColor: _kBg,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _kGold.withValues(alpha: 0.25))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kGold)),
    );
    Widget label(String en, String ko) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Row(children: [
        Text(en, style: GoogleFonts.gowunBatang(color: _kGold, fontWeight: FontWeight.bold, fontSize: 11)),
        const SizedBox(width: 6),
        Text(ko, style: GoogleFonts.notoSansKr(color: _kCream, fontWeight: FontWeight.bold, fontSize: 12.5)),
      ]),
    );
    Widget pill(String text, bool on, VoidCallback tap) => GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: on ? _kGold : _kBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on ? _kGold : _kGold.withValues(alpha: 0.3)),
        ),
        child: Text(text, style: GoogleFonts.notoSansKr(color: on ? Colors.black : Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );

    await showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (ctx, setD) => Dialog(
          backgroundColor: _kCard,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: _kGold, width: 1.3)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(existing == null ? 'NEW Q&A' : 'EDIT Q&A', style: GoogleFonts.gowunBatang(color: _kGold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 2)),
                Text(existing == null ? '자주 묻는 상담 올리기' : '자주 묻는 상담 고치기', style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label('CATEGORY', '분류'),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: kFaqCats
                              .map((c) => pill('${_kCatEmoji[c]} ${_kCatLabel[c]![0]}', cat == c, () => setD(() => cat = c)))
                              .toList(),
                        ),
                        label('AUDIENCE', '보는 사람'),
                        Wrap(
                          spacing: 6,
                          children: ['all', 'student', 'parent']
                              .map((w) => pill(_kAudLabel[w]![0], aud == w, () => setD(() => aud = w)))
                              .toList(),
                        ),
                        label('QUESTION', '질문'),
                        TextField(
                          controller: q,
                          maxLines: 3,
                          minLines: 1,
                          style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                          decoration: deco('예: 하루에 몇 시간 공부해야 하나요?'),
                        ),
                        label('ANSWER', '답'),
                        TextField(
                          controller: a,
                          maxLines: 10,
                          minLines: 5,
                          maxLength: 3000,
                          style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13.5, height: 1.6),
                          decoration: deco('학생 · 학부모가 바로 이해할 수 있게 쉽게 써 주세요.'),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Switch(value: pin, activeThumbColor: _kGold, onChanged: (v) => setD(() => pin = v)),
                                  Text('📌 추천 (맨 위)', style: GoogleFonts.notoSansKr(color: _kCream, fontSize: 12.5, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 92,
                              child: TextField(
                                controller: ord,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13),
                                decoration: deco('순서').copyWith(labelText: '순서', labelStyle: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11)),
                              ),
                            ),
                          ],
                        ),
                        Text('순서 숫자가 작을수록 위에 보여요.', style: GoogleFonts.notoSansKr(color: Colors.white30, fontSize: 10.5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (existing != null)
                      TextButton(
                        onPressed: saving
                            ? null
                            : () async {
                          final bool? yes = await showDialog<bool>(
                            context: ctx,
                            builder: (c2) => AlertDialog(
                              backgroundColor: _kCard,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: _kGold)),
                              content: Text('이 질문을 지울까요?', style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c2, false), child: Text('닫기', style: GoogleFonts.notoSansKr(color: Colors.white54))),
                                TextButton(onPressed: () => Navigator.pop(c2, true), child: Text('삭제', style: GoogleFonts.notoSansKr(color: Colors.redAccent, fontWeight: FontWeight.bold))),
                              ],
                            ),
                          );
                          if (yes != true) return;
                          setD(() => saving = true);
                          final bool ok = await FaqService.delete(existing.id);
                          if (dctx.mounted) Navigator.pop(dctx);
                          if (mounted) _snack(ok ? '지웠어요.' : '지우지 못했어요.', ok ? 'Deleted.' : 'Failed.');
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Delete', style: GoogleFonts.gowunBatang(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                            Text('삭제', style: GoogleFonts.notoSansKr(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12.5)),
                          ],
                        ),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(dctx),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Close', style: GoogleFonts.gowunBatang(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 11)),
                          Text('닫기', style: GoogleFonts.notoSansKr(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kGold,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: saving
                          ? null
                          : () async {
                        if (q.text.trim().isEmpty || a.text.trim().isEmpty) {
                          _snack('질문과 답을 모두 써 주세요.', 'Please fill in both.');
                          return;
                        }
                        setD(() => saving = true);
                        final bool ok = await FaqService.save(
                          id: existing?.id,
                          question: q.text.trim(),
                          answer: a.text.trim(),
                          category: cat,
                          audience: aud,
                          order: int.tryParse(ord.text.trim()) ?? 100,
                          pinned: pin,
                        );
                        if (dctx.mounted) Navigator.pop(dctx);
                        if (mounted) _snack(ok ? '저장했어요.' : '저장하지 못했어요. 서버 규칙을 확인해 주세요.', ok ? 'Saved.' : 'Save failed.');
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Save', style: GoogleFonts.gowunBatang(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                          Text(saving ? '저장 중' : '저장', style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
