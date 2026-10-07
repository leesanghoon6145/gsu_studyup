// lib/services/subject_category.dart
//
// 🆕 [과목 2단 구조 2026-10-07]
// 1단 = 교과 (12개 고정) · 2단 = 세부 (선택)
// - 새로 만드는 과목 이름 모양: "English · Reading (영어 · 독해)"  → 교과 = 영어, 세부 = 독해
// - 예전에 만든 과목 이름("Math (수학)", "영어 문법", "Native Language (국어)" 등)도
//   글자를 보고 자동으로 교과를 찾아 줌 → 지난 기록은 하나도 지우지 않고 그래프에서 합쳐짐
// - 어느 교과인지 알 수 없는 이름은 "기타"

class SubjectCategory {
  final String ko;
  final String en;
  final List<String> keys; // 예전 과목 이름에서 교과를 찾을 때 쓰는 낱말 (소문자)
  final List<List<String>> details; // [한글, 영어]
  const SubjectCategory(this.ko, this.en, this.keys, this.details);
}

/// 12개 교과 (화면에 보이는 순서)
const List<SubjectCategory> kSubjectCategories = [
  SubjectCategory('국어', 'Korean', ['국어', '문학', '비문학', '고전', '화법', '작문', '언어와 매체', 'native language'], [
    ['문학', 'Literature'], ['비문학(독서)', 'Non-fiction'], ['문법', 'Grammar'], ['고전', 'Classics'], ['화법·작문', 'Speech & Writing'],
  ]),
  SubjectCategory('영어', 'English', ['영어', 'english', '토익', 'toeic', '토플', 'toefl'], [
    ['문법', 'Grammar'], ['독해', 'Reading'], ['듣기', 'Listening'], ['어휘', 'Vocabulary'], ['영작', 'Writing'],
  ]),
  SubjectCategory('수학', 'Math', ['수학', 'math', '미적분', '확률과 통계', '기하', '수1', '수2'], [
    ['중1', 'Grade 7'], ['중2', 'Grade 8'], ['중3', 'Grade 9'], ['공통수학', 'Common Math'], ['수학Ⅰ', 'Math I'],
    ['수학Ⅱ', 'Math II'], ['미적분', 'Calculus'], ['확률과 통계', 'Probability & Statistics'], ['기하', 'Geometry'],
  ]),
  SubjectCategory('과학', 'Science', ['과학', '물리', '화학', '생명', '생물', '지구과학', 'science', 'physics', 'chemistry', 'biology'], [
    ['통합과학', 'Integrated Science'], ['물리', 'Physics'], ['화학', 'Chemistry'], ['생명과학', 'Life Science'], ['지구과학', 'Earth Science'],
  ]),
  SubjectCategory('사회', 'Social Studies', ['사회', '지리', '경제', '정치', 'social', 'geography', 'economics'], [
    ['통합사회', 'Integrated Social Studies'], ['지리', 'Geography'], ['일반사회', 'General Social Studies'], ['경제', 'Economics'], ['정치와 법', 'Politics & Law'],
  ]),
  SubjectCategory('역사', 'History', ['한국사', '역사', '세계사', '동아시아사', 'history'], [
    ['한국사', 'Korean History'], ['세계사', 'World History'], ['동아시아사', 'East Asian History'],
  ]),
  SubjectCategory('도덕·윤리', 'Ethics', ['도덕', '윤리', 'ethics', 'moral'], [
    ['도덕', 'Morals'], ['생활과 윤리', 'Life & Ethics'], ['윤리와 사상', 'Ethics & Thought'],
  ]),
  SubjectCategory('기술·가정', 'Tech & Home Ec.', ['기술', '가정', 'technology', 'home economics'], [
    ['기술', 'Technology'], ['가정', 'Home Economics'],
  ]),
  SubjectCategory('정보', 'Informatics', ['정보', '코딩', '프로그래밍', '컴퓨터', 'coding', 'computer', 'informatics'], [
    ['정보', 'Informatics'], ['코딩', 'Coding'],
  ]),
  SubjectCategory('제2외국어', '2nd Language', ['제2외국어', '일본어', '중국어', '한문', '프랑스어', '독일어', '스페인어', 'japanese', 'chinese', 'french', 'german', 'spanish'], [
    ['일본어', 'Japanese'], ['중국어', 'Chinese'], ['한문', 'Classical Chinese'], ['프랑스어', 'French'], ['독일어', 'German'], ['스페인어', 'Spanish'],
  ]),
  SubjectCategory('예체능', 'Arts & PE', ['예체능', '음악', '미술', '체육', '운동', 'music', 'exercise', 'sports'], [
    ['음악', 'Music'], ['미술', 'Art'], ['체육', 'PE'],
  ]),
  SubjectCategory('기타', 'Other', [], [
    ['독서', 'Reading'], ['논술', 'Essay'], ['자격증', 'Certificate'],
  ]),
];

SubjectCategory get kOtherCategory => kSubjectCategories.last;

// 🆕 [다국어 2026-10-07] 교과 이름 10개 외국어 (KO · EN은 위 목록에 있음)
const Map<String, Map<String, String>> kSubjectCategoryNames = {
  '국어': {'JA': '国語', 'ZH': '语文', 'FR': 'Coréen', 'DE': 'Koreanisch', 'RU': 'Корейский язык', 'AR': 'اللغة الكورية', 'HI': 'कोरियाई भाषा', 'VI': 'Ngữ văn', 'ES': 'Lengua coreana', 'TH': 'ภาษาเกาหลี'},
  '영어': {'JA': '英語', 'ZH': '英语', 'FR': 'Anglais', 'DE': 'Englisch', 'RU': 'Английский', 'AR': 'الإنجليزية', 'HI': 'अंग्रेज़ी', 'VI': 'Tiếng Anh', 'ES': 'Inglés', 'TH': 'ภาษาอังกฤษ'},
  '수학': {'JA': '数学', 'ZH': '数学', 'FR': 'Mathématiques', 'DE': 'Mathematik', 'RU': 'Математика', 'AR': 'الرياضيات', 'HI': 'गणित', 'VI': 'Toán', 'ES': 'Matemáticas', 'TH': 'คณิตศาสตร์'},
  '과학': {'JA': '理科', 'ZH': '科学', 'FR': 'Sciences', 'DE': 'Naturwissenschaften', 'RU': 'Естествознание', 'AR': 'العلوم', 'HI': 'विज्ञान', 'VI': 'Khoa học', 'ES': 'Ciencias', 'TH': 'วิทยาศาสตร์'},
  '사회': {'JA': '社会', 'ZH': '社会', 'FR': 'Sciences sociales', 'DE': 'Gesellschaftskunde', 'RU': 'Обществознание', 'AR': 'الدراسات الاجتماعية', 'HI': 'सामाजिक अध्ययन', 'VI': 'Xã hội', 'ES': 'Ciencias sociales', 'TH': 'สังคมศึกษา'},
  '역사': {'JA': '歴史', 'ZH': '历史', 'FR': 'Histoire', 'DE': 'Geschichte', 'RU': 'История', 'AR': 'التاريخ', 'HI': 'इतिहास', 'VI': 'Lịch sử', 'ES': 'Historia', 'TH': 'ประวัติศาสตร์'},
  '도덕·윤리': {'JA': '道徳・倫理', 'ZH': '道德·伦理', 'FR': 'Morale', 'DE': 'Ethik', 'RU': 'Этика', 'AR': 'الأخلاق', 'HI': 'नैतिक शिक्षा', 'VI': 'Đạo đức', 'ES': 'Ética', 'TH': 'จริยธรรม'},
  '기술·가정': {'JA': '技術・家庭', 'ZH': '技术·家政', 'FR': 'Technologie', 'DE': 'Technik & Hauswirtschaft', 'RU': 'Технология', 'AR': 'التكنولوجيا والاقتصاد المنزلي', 'HI': 'प्रौद्योगिकी व गृह विज्ञान', 'VI': 'Công nghệ', 'ES': 'Tecnología', 'TH': 'การงานอาชีพ'},
  '정보': {'JA': '情報', 'ZH': '信息技术', 'FR': 'Informatique', 'DE': 'Informatik', 'RU': 'Информатика', 'AR': 'المعلوماتية', 'HI': 'सूचना प्रौद्योगिकी', 'VI': 'Tin học', 'ES': 'Informática', 'TH': 'วิทยาการคำนวณ'},
  '제2외국어': {'JA': '第二外国語', 'ZH': '第二外语', 'FR': 'Seconde langue', 'DE': 'Zweitsprache', 'RU': 'Второй иностранный', 'AR': 'لغة أجنبية ثانية', 'HI': 'द्वितीय विदेशी भाषा', 'VI': 'Ngoại ngữ 2', 'ES': 'Segunda lengua', 'TH': 'ภาษาต่างประเทศที่สอง'},
  '예체능': {'JA': '芸術・体育', 'ZH': '艺体', 'FR': 'Arts et sport', 'DE': 'Kunst & Sport', 'RU': 'Искусство и физкультура', 'AR': 'الفنون والرياضة', 'HI': 'कला व खेल', 'VI': 'Nghệ thuật & Thể chất', 'ES': 'Artes y deporte', 'TH': 'ศิลปะและพลศึกษา'},
  '기타': {'JA': 'その他', 'ZH': '其他', 'FR': 'Autre', 'DE': 'Sonstiges', 'RU': 'Другое', 'AR': 'أخرى', 'HI': 'अन्य', 'VI': 'Khác', 'ES': 'Otro', 'TH': 'อื่น ๆ'},
};

/// 화면 언어에 맞는 교과 이름 (KO=한글, EN=영어, 10개 언어=그 언어)
String subjectCategoryLabel(SubjectCategory c, String lang) {
  final String l = lang.toUpperCase();
  if (l == 'KO') return c.ko;
  if (l == 'EN') return c.en;
  return kSubjectCategoryNames[c.ko]?[l] ?? c.en;
}

// 교과를 찾는 순서: "제2외국어"는 "국어"보다, "한국사"는 "국어"보다 먼저 봐야 잘못 묶이지 않음
const List<String> _kMatchOrder = ['역사', '제2외국어', '국어', '영어', '수학', '과학', '사회', '도덕·윤리', '기술·가정', '정보', '예체능'];

SubjectCategory? subjectCategoryByKo(String ko) {
  for (final c in kSubjectCategories) {
    if (c.ko == ko) return c;
  }
  return null;
}

/// 과목 이름에서 한글 부분 꺼내기 ("English · Reading (영어 · 독해)" → "영어 · 독해")
String subjectKoPart(String subject) {
  final String s = subject.trim();
  final int open = s.lastIndexOf('(');
  if (open >= 0 && s.endsWith(')')) return s.substring(open + 1, s.length - 1).trim();
  return s;
}

/// 과목 이름 → 교과 (새 이름은 앞부분 교과, 예전 이름은 낱말로 찾음, 못 찾으면 기타)
SubjectCategory subjectCategoryOf(String subject) {
  final String ko = subjectKoPart(subject);
  if (ko.contains(' · ')) {
    final SubjectCategory? c = subjectCategoryByKo(ko.split(' · ').first.trim());
    if (c != null) return c;
  }
  final SubjectCategory? exact = subjectCategoryByKo(ko);
  if (exact != null) return exact;
  final String lower = subject.toLowerCase();
  for (final String name in _kMatchOrder) {
    final SubjectCategory c = subjectCategoryByKo(name)!;
    for (final String k in c.keys) {
      if (lower.contains(k)) return c;
    }
  }
  return kOtherCategory;
}

/// 과목 이름 → 세부 (없으면 빈 글자). 예전 이름은 이름 전체를 세부로 봄
String subjectDetailOf(String subject) {
  final String ko = subjectKoPart(subject);
  if (ko.contains(' · ')) return ko.split(' · ').sublist(1).join(' · ').trim();
  if (subjectCategoryByKo(ko) != null) return '';
  return ko;
}

/// 교과 + 세부 → 첫 화면 과목 칩 {'en', 'ko'}
Map<String, String> subjectEnKo(SubjectCategory c, {String detailKo = '', String detailEn = ''}) {
  final String dKo = detailKo.trim();
  String dEn = detailEn.trim();
  if (dKo.isNotEmpty && dEn.isEmpty) {
    for (final d in c.details) {
      if (d[0] == dKo) dEn = d[1];
    }
  }
  return {
    'en': dEn.isEmpty ? c.en : '${c.en} · $dEn',
    'ko': dKo.isEmpty ? c.ko : '${c.ko} · $dKo',
  };
}

/// 교과 + 세부 → 저장용 과목 이름 ("English · Reading (영어 · 독해)")
String subjectFullName(SubjectCategory c, {String detailKo = '', String detailEn = ''}) {
  final Map<String, String> m = subjectEnKo(c, detailKo: detailKo, detailEn: detailEn);
  return '${m['en']} (${m['ko']})';
}

/// 과목별 분(또는 별) 합계 → 교과별 합계로 묶기 (그래프용)
Map<String, int> groupMinutesByCategory(Map<String, int> bySubject) {
  final Map<String, int> out = {};
  bySubject.forEach((subject, v) {
    final String k = subjectCategoryOf(subject).ko;
    out[k] = (out[k] ?? 0) + v;
  });
  return out;
}

/// 한 교과 안의 세부별 합계 (원그래프 조각을 눌렀을 때)
Map<String, int> detailMinutesOf(String categoryKo, Map<String, int> bySubject) {
  final Map<String, int> out = {};
  bySubject.forEach((subject, v) {
    if (subjectCategoryOf(subject).ko != categoryKo) return;
    final String d = subjectDetailOf(subject);
    final String key = d.isEmpty ? '(세부 없음)' : d;
    out[key] = (out[key] ?? 0) + v;
  });
  return out;
}
