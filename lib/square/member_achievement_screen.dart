import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:convert'; // 🆕 [데이터 연결] 성적 기록 JSON 직렬화용
import 'package:shared_preferences/shared_preferences.dart';
import '../global_lang.dart'; // 👑 글로벌 사전 연결
import '../services/user_profile_service.dart'; // 🆕 [실사용 전환] 실제 가입자 이름 조회용
import 'package:firebase_auth/firebase_auth.dart'; // 🆕 [반복 방지] 사람 구분(uid)용
import '../star_economy.dart'; // 🆕 [버그 수정] DkeStars 클래스 사용을 위한 import 누락 수정 (Undefined name 'DkeStars' 에러의 원인)
import '../services/scholarship_service.dart'; // 🆕 [장학금 방 2026-09-17] "나의 성취별 현황" 카드용 데이터 조회
import '../services/scholarship_currency.dart'; // 🆕 [2026-09-27] 장학금 화폐 자동 전환
import 'package:cloud_firestore/cloud_firestore.dart'; // 🆕 [실시간 장학금 금액] 부모님이 선택한 유형을 실시간 구독하기 위함
import '../services/family_link_service.dart'; // 🆕 [실시간 장학금 금액] getMyLinkCode()/watch() 사용을 위함
import '../schedule/cheer_stars_i18n.dart'; // 🆕 [다국어 2026-09-29] 받은 응원별 카드 12개 언어
import '../services/supporter_service.dart'; // 🆕 [응원 가족 2026-09-30]
import '../services/report_archive_service.dart'; // 🆕 [리포트 저장·공유 2026-10-01]
import '../services/ranking_service.dart'; // 🆕 [랭킹 2026-10-01] 진짜 순위 계산
import '../services/diagnosis_service.dart'; // 🆕 [리포트 저장·공유 2026-10-01] 부모님 연결 전에 쓰는 문장 은행

class MemberAchievementScreen extends StatefulWidget {
  const MemberAchievementScreen({Key? key}) : super(key: key);

  @override
  State<MemberAchievementScreen> createState() =>
      _MemberAchievementScreenState();
}

class _ThemeColors {
  static const Color brandGolden = Color(0xFFE5C158);
  static const Color luxuryDarkBg = Color(0xFF030712);
  static const Color premiumCardBg = Color(0xFF0D1527);
}

// 🎯 성적 입력을 위한 내부 데이터 모델링 패킷 정의 (선배님 피드백 메트릭 인프라 보강)
class _ExamRecord {
  final String id;
  final String type; // 주평가, 단원평가, 중간고사, 기말고사, 모의고사
  final int grade; // 1, 2, 3학년
  final int semester; // 1, 2학기
  final DateTime date;
  final String subject;
  final String unit;
  final double score;

  // 🆕 [선배님 지시사항]: 팝업창 저장 데이터 세션 확장 바인딩
  final String durationText; // 소요시간 (예: 45분)
  final String difficultyLevel; // 난이도 (매우쉬움, 쉬움, 보통, 어려움, 매우어려움)
  final int starSatisfaction; // 시험 만족도 (별점 1~5)
  final List<String> errorCauses; // 실수 원인 복수 선택 리스트
  final String reviewRequired; // 복습 필요 여부 (필요, 예정, 불필요)

  // 모의고사 전용 추가 필드
  final String mockMonth; // 몇월 모의고사
  final String mockRank; // 등급 또는 석차

  _ExamRecord({
    required this.id,
    required this.type,
    required this.grade,
    required this.semester,
    required this.date,
    required this.subject,
    required this.unit,
    required this.score,
    this.durationText = "45분",
    this.difficultyLevel = "보통",
    this.starSatisfaction = 5,
    this.errorCauses = const ["개념부족"],
    this.reviewRequired = "필요",
    this.mockMonth = "",
    this.mockRank = "",
  });

  // 🆕 [데이터 연결] SharedPreferences 영구 저장을 위한 JSON 직렬화/역직렬화
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'grade': grade,
    'semester': semester,
    'date': date.toIso8601String(),
    'subject': subject,
    'unit': unit,
    'score': score,
    'durationText': durationText,
    'difficultyLevel': difficultyLevel,
    'starSatisfaction': starSatisfaction,
    'errorCauses': errorCauses,
    'reviewRequired': reviewRequired,
    'mockMonth': mockMonth,
    'mockRank': mockRank,
  };

  // 🆕 [버그 수정 2026-07-29] 필수 필드도 null-안전 처리로 변경.
  // 기존엔 id/type/grade/semester/date/subject/unit/score 중 단 하나라도 null이거나 형식이 깨지면
  // 이 레코드 하나 때문에 예외가 발생했고, 그 예외가 _loadExamRecords() 전체를 빈 목록으로 만들어서
  // 저장된 성적 기록이 통째로 화면에서 사라지는 문제가 있었음. 아래처럼 각 필드에 안전한 기본값을 두면
  // 손상된 레코드 하나는 기본값으로 채워져 표시되고, 나머지 정상 레코드는 영향받지 않음.
  factory _ExamRecord.fromJson(Map<String, dynamic> json) => _ExamRecord(
    id:
        json['id'] as String? ??
        DateTime.now().millisecondsSinceEpoch.toString(),
    type: json['type'] as String? ?? "주평가",
    grade: (json['grade'] as num?)?.toInt() ?? 1,
    semester: (json['semester'] as num?)?.toInt() ?? 1,
    date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
    subject: json['subject'] as String? ?? "",
    unit: json['unit'] as String? ?? "",
    score: (json['score'] as num?)?.toDouble() ?? 0.0,
    durationText: json['durationText'] as String? ?? "45분",
    difficultyLevel: json['difficultyLevel'] as String? ?? "보통",
    starSatisfaction: (json['starSatisfaction'] as num?)?.toInt() ?? 5,
    errorCauses:
        (json['errorCauses'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const ["개념부족"],
    reviewRequired: json['reviewRequired'] as String? ?? "필요",
    mockMonth: json['mockMonth'] as String? ?? "",
    mockRank: json['mockRank'] as String? ?? "",
  );
}

class _MemberAchievementScreenState extends State<MemberAchievementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _warningAnimController;
  late Animation<double> _warningAnimation;

  final String _mySchoolInfo = DkeLang.schoolInfo;

  // 🆕 [데이터 연결-버그 수정] 레벨/별은 더 이상 고정값이 아니라 DkeStars(star_economy.dart)에서
  // 실제 누적 데이터를 불러와서 표시합니다. 신규 유저는 0개/레벨1부터 정확히 시작합니다.
  int _totalStars = 0;
  int _currentLevelNumber = 1;

  // 🆕 [데이터 연결] 일간/주간/월간/연간 그래프에 쓸 실제 학습시간 데이터.
  // 더 이상 하드코딩된 가상 8과목 리스트가 아니라, dke_history_* 실제 기록을 집계한 결과입니다.
  List<Map<String, dynamic>> _realSubjectStudyData = [];

  final List<Color> _todayColors = [
    const Color(0xFFFF3B30),
    const Color(0xFFFF9500),
    const Color(0xFFFFCC00),
    const Color(0xFF34C759),
    const Color(0xFF007AFF),
    const Color(0xFF0500FF),
    const Color(0xFFAF52DE),
    const Color(0xFF5856D6),
  ];

  final List<Color> _weeklyColors = [
    const Color(0xFF34C759),
    const Color(0xFF0500FF),
    const Color(0xFF007AFF),
    const Color(0xFFAF52DE),
    const Color(0xFFFF3B30),
    const Color(0xFFFF9500),
    const Color(0xFFFFCC00),
    const Color(0xFF5856D6),
  ];

  final List<Color> _evalColors = [
    const Color(0xFF34C759), // 초
    const Color(0xFFFF3B30), // 빨
    const Color(0xFF007AFF), // 파
    const Color(0xFFFF9500), // 주
    const Color(0xFF5856D6), // 남
    const Color(0xFFFFCC00), // 노
    const Color(0xFFAF52DE), // 보
  ];

  // 🆕 [12개국 확장]: 과목명을 12개 언어로 번역해서 조회하는 맵 + 헬퍼
  static const Map<String, Map<String, String>> _subjectNames = {
    "수학": {
      'KO': '수학',
      'EN': 'Math',
      'JA': '数学',
      'ZH': '数学',
      'FR': 'Maths',
      'DE': 'Mathe',
      'RU': 'Матем.',
      'AR': 'رياضيات',
      'HI': 'गणित',
      'VI': 'Toán',
      'ES': 'Mate',
      'TH': 'คณิต',
    },
    "영어": {
      'KO': '영어',
      'EN': 'En',
      'JA': '英語',
      'ZH': '英语',
      'FR': 'Anglais',
      'DE': 'Englisch',
      'RU': 'Англ.',
      'AR': 'إنجليزي',
      'HI': 'अंग्रेज़ी',
      'VI': 'Tiếng Anh',
      'ES': 'Inglés',
      'TH': 'อังกฤษ',
    },
    "국어": {
      'KO': '국어',
      'EN': 'Kor',
      'JA': '国語',
      'ZH': '语文',
      'FR': 'Coréen',
      'DE': 'Koreanisch',
      'RU': 'Кор. яз.',
      'AR': 'كورية',
      'HI': 'कोरियाई',
      'VI': 'Tiếng Hàn',
      'ES': 'Coreano',
      'TH': 'ภาษาเกาหลี',
    },
    "과학": {
      'KO': '과학',
      'EN': 'Sci',
      'JA': '理科',
      'ZH': '科学',
      'FR': 'Sciences',
      'DE': 'Wissen.',
      'RU': 'Наука',
      'AR': 'علوم',
      'HI': 'विज्ञान',
      'VI': 'Khoa học',
      'ES': 'Ciencia',
      'TH': 'วิทย์',
    },
    "사회": {
      'KO': '사회',
      'EN': 'Soc',
      'JA': '社会',
      'ZH': '社会',
      'FR': 'Sociales',
      'DE': 'Sozial.',
      'RU': 'Обществ.',
      'AR': 'اجتماعيات',
      'HI': 'सामाजिक',
      'VI': 'Xã hội',
      'ES': 'Sociales',
      'TH': 'สังคม',
    },
    "도덕": {
      'KO': '도덕',
      'EN': 'Eth',
      'JA': '道徳',
      'ZH': '道德',
      'FR': 'Éthique',
      'DE': 'Ethik',
      'RU': 'Этика',
      'AR': 'أخلاق',
      'HI': 'नैतिक',
      'VI': 'Đạo đức',
      'ES': 'Ética',
      'TH': 'ศีลธรรม',
    },
    "역사": {
      'KO': '역사',
      'EN': 'Hist',
      'JA': '歴史',
      'ZH': '历史',
      'FR': 'Histoire',
      'DE': 'Gesch.',
      'RU': 'История',
      'AR': 'تاريخ',
      'HI': 'इतिहास',
      'VI': 'Lịch sử',
      'ES': 'Historia',
      'TH': 'ประวัติ',
    },
    "정보": {
      'KO': '정보',
      'EN': 'Info',
      'JA': '情報',
      'ZH': '信息',
      'FR': 'Info',
      'DE': 'Info',
      'RU': 'Информ.',
      'AR': 'معلوماتية',
      'HI': 'सूचना',
      'VI': 'CNTT',
      'ES': 'Informát.',
      'TH': 'ไอที',
    },
  };

  static String _subjectName(String koKey) {
    final map = _subjectNames[koKey];
    if (map == null) return koKey;
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? koKey;
  }

  // 🆕 [12개국 UI 문구 카탈로그] + 조회 헬퍼 _t()
  static const Map<String, Map<String, String>> _uiText = {
    // 🆕 [2026-09-30] "실시간 학습 현황" 카드 누적 별 이름 (이름이 없어 cumulative가 그대로 보이던 문제)
    'cumulative': {
      'KO': '누적 별',
      'EN': 'Total Stars',
      'JA': '累積スター',
      'ZH': '累计星',
      'FR': 'Étoiles cumulées',
      'DE': 'Gesamtsterne',
      'RU': 'Всего звёзд',
      'AR': 'إجمالي النجوم',
      'HI': 'कुल सितारे',
      'VI': 'Tổng sao',
      'ES': 'Estrellas totales',
      'TH': 'ดาวสะสม',
    },

    'lv26': {
      'KO': '학습레벨 26',
      'EN': 'Lv.26',
      'JA': 'レベル26',
      'ZH': '等级26',
      'FR': 'Niv. 26',
      'DE': 'Lvl. 26',
      'RU': 'Уровень 26',
      'AR': 'المستوى 26',
      'HI': 'लेवल 26',
      'VI': 'Cấp 26',
      'ES': 'Nivel 26',
      'TH': 'เลเวล 26',
    },
    'timerDetailDefault': {
      'KO': '개념 및 심화, 문제풀이 25문제',
      'EN': 'Solved concepts and problems, 25 issues',
      'JA': '概念と応用問題25問を解答',
      'ZH': '概念与拓展，完成25道题',
      'FR': 'Concepts et exercices, 25 problèmes résolus',
      'DE': 'Konzepte und Übungen, 25 Aufgaben gelöst',
      'RU': 'Концепции и задачи, решено 25 заданий',
      'AR': 'مفاهيم وتطبيقات، تم حل 25 مسألة',
      'HI': 'अवधारणाएं और अभ्यास, 25 प्रश्न हल किए',
      'VI': 'Khái niệm và bài tập nâng cao, giải 25 câu',
      'ES': 'Conceptos y ejercicios, 25 problemas resueltos',
      'TH': 'แนวคิดและโจทย์เชิงลึก แก้ไปแล้ว 25 ข้อ',
    },
    'completed': {
      'KO': '정리함',
      'EN': 'COMPLETED',
      'JA': '整理済み',
      'ZH': '已整理',
      'FR': 'TERMINÉ',
      'DE': 'ERLEDIGT',
      'RU': 'ЗАВЕРШЕНО',
      'AR': 'مكتمل',
      'HI': 'पूर्ण',
      'VI': 'ĐÃ HOÀN THÀNH',
      'ES': 'COMPLETADO',
      'TH': 'เรียบร้อยแล้ว',
    },
    'examSummaryHeader': {
      'KO': '\n\n[직접 작성 주평가 실시간 연동]\n',
      'EN': '\n\n[Live-Linked Weekly Evaluations]\n',
      'JA': '\n\n[週次評価のリアルタイム連携]\n',
      'ZH': '\n\n[实时联动的每周评估]\n',
      'FR': '\n\n[Évaluations hebdomadaires liées en direct]\n',
      'DE': '\n\n[Live verknüpfte wöchentliche Bewertungen]\n',
      'RU': '\n\n[Еженедельные оценки в реальном времени]\n',
      'AR': '\n\n[التقييمات الأسبوعية المرتبطة مباشرة]\n',
      'HI': '\n\n[लाइव-लिंक्ड साप्ताहिक मूल्यांकन]\n',
      'VI': '\n\n[Đánh giá hằng tuần được liên kết trực tiếp]\n',
      'ES': '\n\n[Evaluaciones semanales vinculadas en vivo]\n',
      'TH': '\n\n[การประเมินรายสัปดาห์ที่เชื่อมโยงสด]\n',
    },
    'diagReportTitle': {
      'KO': '👑 DKE 교육성취 정밀 진단서',
      'EN': '👑 DKE Achievement Diagnosis Report',
      'JA': '👑 DKE 教育成果 精密診断書',
      'ZH': '👑 DKE 教育成果精密诊断报告',
      'FR': '👑 Rapport de diagnostic de réussite DKE',
      'DE': '👑 DKE Leistungsdiagnosebericht',
      'RU': '👑 Отчёт по диагностике успеваемости DKE',
      'AR': '👑 تقرير تشخيص التحصيل الدراسي DKE',
      'HI': '👑 DKE उपलब्धि निदान रिपोर्ट',
      'VI': '👑 Báo cáo chẩn đoán thành tích DKE',
      'ES': '👑 Informe de diagnóstico de logros DKE',
      'TH': '👑 รายงานวินิจฉัยผลสัมฤทธิ์ DKE',
    },
    'mockMonthLabel': {
      'KO': '• 몇 월 모의고사 (직접 입력)',
      'EN': '• Which Month (custom input)',
      'JA': '• 何月の模試か（直接入力）',
      'ZH': '• 几月的模拟考（自定义输入）',
      'FR': '• Quel mois (saisie libre)',
      'DE': '• Welcher Monat (freie Eingabe)',
      'RU': '• Какой месяц (произвольный ввод)',
      'AR': '• أي شهر (إدخال مخصص)',
      'HI': '• कौन सा महीना (कस्टम इनपुट)',
      'VI': '• Tháng nào (nhập tùy chỉnh)',
      'ES': '• Qué mes (entrada personalizada)',
      'TH': '• เดือนไหน (กรอกเอง)',
    },
    'mockRankLabel': {
      'KO': '• 등급 또는 석차 (직접 입력)',
      'EN': '• Grade or Rank (custom input)',
      'JA': '• 等級または順位（直接入力）',
      'ZH': '• 等级或排名（自定义输入）',
      'FR': '• Note ou rang (saisie libre)',
      'DE': '• Note oder Rang (freie Eingabe)',
      'RU': '• Оценка или ранг (произвольный ввод)',
      'AR': '• الدرجة أو الترتيب (إدخال مخصص)',
      'HI': '• ग्रेड या रैंक (कस्टम इनपुट)',
      'VI': '• Xếp hạng hoặc thứ hạng (nhập tùy chỉnh)',
      'ES': '• Nota o clasificación (entrada personalizada)',
      'TH': '• เกรดหรืออันดับ (กรอกเอง)',
    },
    'label1Duration': {
      'KO': '1. 소요시간 (직접 입력)',
      'EN': '1. Duration (custom input)',
      'JA': '1. 所要時間（直接入力）',
      'ZH': '1. 所用时间（自定义输入）',
      'FR': '1. Durée (saisie libre)',
      'DE': '1. Dauer (freie Eingabe)',
      'RU': '1. Продолжительность (произвольный ввод)',
      'AR': '1. المدة (إدخال مخصص)',
      'HI': '1. अवधि (कस्टम इनपुट)',
      'VI': '1. Thời gian (nhập tùy chỉnh)',
      'ES': '1. Duración (entrada personalizada)',
      'TH': '1. ระยะเวลา (กรอกเอง)',
    },
    'label2Difficulty': {
      'KO': '2. 난이도 설정 (단일 선택)',
      'EN': '2. Difficulty (single select)',
      'JA': '2. 難易度設定（単一選択）',
      'ZH': '2. 难度设置（单选）',
      'FR': '2. Difficulté (choix unique)',
      'DE': '2. Schwierigkeit (Einzelauswahl)',
      'RU': '2. Сложность (один вариант)',
      'AR': '2. مستوى الصعوبة (اختيار واحد)',
      'HI': '2. कठिनाई स्तर (एकल चयन)',
      'VI': '2. Độ khó (chọn một)',
      'ES': '2. Dificultad (selección única)',
      'TH': '2. ระดับความยาก (เลือกเดียว)',
    },
    'label3Satisfaction': {
      'KO': '3. 시험 만족도 지표',
      'EN': '3. Satisfaction Rating',
      'JA': '3. 試験満足度指標',
      'ZH': '3. 考试满意度指标',
      'FR': '3. Indice de satisfaction',
      'DE': '3. Zufriedenheitsbewertung',
      'RU': '3. Оценка удовлетворённости',
      'AR': '3. مؤشر الرضا عن الاختبار',
      'HI': '3. संतुष्टि रेटिंग',
      'VI': '3. Mức độ hài lòng',
      'ES': '3. Índice de satisfacción',
      'TH': '3. คะแนนความพึงพอใจ',
    },
    'label4ErrorMulti': {
      'KO': '4. 실수 원인 진단 (복수 선택 가능)',
      'EN': '4. Error Causes (multi-select)',
      'JA': '4. ミスの原因診断（複数選択可）',
      'ZH': '4. 失分原因诊断（可多选）',
      'FR': '4. Causes d\'erreurs (choix multiple)',
      'DE': '4. Fehlerursachen (Mehrfachauswahl)',
      'RU': '4. Причины ошибок (можно выбрать несколько)',
      'AR': '4. أسباب الأخطاء (اختيار متعدد)',
      'HI': '4. गलती के कारण (बहु-चयन)',
      'VI': '4. Nguyên nhân sai sót (chọn nhiều)',
      'ES': '4. Causas de error (selección múltiple)',
      'TH': '4. สาเหตุข้อผิดพลาด (เลือกได้หลายข้อ)',
    },
    'label5ReviewSelect': {
      'KO': '5. 복습 필요 여부 선택',
      'EN': '5. Review Needed?',
      'JA': '5. 復習が必要か選択',
      'ZH': '5. 是否需要复习',
      'FR': '5. Révision nécessaire ?',
      'DE': '5. Wiederholung nötig?',
      'RU': '5. Нужно повторение?',
      'AR': '5. هل تحتاج إلى مراجعة؟',
      'HI': '5. क्या पुनरीक्षण आवश्यक है?',
      'VI': '5. Có cần ôn lại không?',
      'ES': '5. ¿Necesita repaso?',
      'TH': '5. ต้องทบทวนหรือไม่',
    },
    'confirmBtn': {
      'KO': '확인',
      'EN': 'Confirm',
      'JA': '確認',
      'ZH': '确认',
      'FR': 'Confirmer',
      'DE': 'Bestätigen',
      'RU': 'Подтвердить',
      'AR': 'تأكيد',
      'HI': 'पुष्टि करें',
      'VI': 'Xác nhận',
      'ES': 'Confirmar',
      'TH': 'ยืนยัน',
    },
    'label1DurationShort': {
      'KO': '1. 시험 소요시간',
      'EN': '1. Duration',
      'JA': '1. 試験所要時間',
      'ZH': '1. 考试用时',
      'FR': '1. Durée',
      'DE': '1. Dauer',
      'RU': '1. Продолжительность',
      'AR': '1. المدة',
      'HI': '1. अवधि',
      'VI': '1. Thời gian',
      'ES': '1. Duración',
      'TH': '1. ระยะเวลา',
    },
    'label2DifficultyShort': {
      'KO': '2. 출제 난이도',
      'EN': '2. Difficulty',
      'JA': '2. 出題難易度',
      'ZH': '2. 出题难度',
      'FR': '2. Difficulté',
      'DE': '2. Schwierigkeit',
      'RU': '2. Сложность',
      'AR': '2. مستوى الصعوبة',
      'HI': '2. कठिनाई',
      'VI': '2. Độ khó',
      'ES': '2. Dificultad',
      'TH': '2. ความยาก',
    },
    'label3SatisfactionShort': {
      'KO': '3. 시험 만족도',
      'EN': '3. Satisfaction',
      'JA': '3. 試験満足度',
      'ZH': '3. 考试满意度',
      'FR': '3. Satisfaction',
      'DE': '3. Zufriedenheit',
      'RU': '3. Удовлетворённость',
      'AR': '3. الرضا',
      'HI': '3. संतुष्टि',
      'VI': '3. Mức hài lòng',
      'ES': '3. Satisfacción',
      'TH': '3. ความพึงพอใจ',
    },
    'label4ErrorShort': {
      'KO': '4. 주요 실수 원인',
      'EN': '4. Error Causes',
      'JA': '4. 主なミス原因',
      'ZH': '4. 主要失分原因',
      'FR': '4. Causes d\'erreurs',
      'DE': '4. Fehlerursachen',
      'RU': '4. Причины ошибок',
      'AR': '4. أسباب الأخطاء',
      'HI': '4. गलती के कारण',
      'VI': '4. Nguyên nhân sai sót',
      'ES': '4. Causas de error',
      'TH': '4. สาเหตุข้อผิดพลาด',
    },
    'label5ReviewShort': {
      'KO': '5. 복습 필요 여부',
      'EN': '5. Review Needed',
      'JA': '5. 復習の必要性',
      'ZH': '5. 是否需要复习',
      'FR': '5. Révision nécessaire',
      'DE': '5. Wiederholung nötig',
      'RU': '5. Нужно повторение',
      'AR': '5. الحاجة للمراجعة',
      'HI': '5. पुनरीक्षण आवश्यक',
      'VI': '5. Cần ôn lại',
      'ES': '5. Necesita repaso',
      'TH': '5. ต้องทบทวน',
    },
    'totalReport': {
      'KO': '종합 리포트',
      'EN': 'Total Report',
      'JA': '総合レポート',
      'ZH': '综合报告',
      'FR': 'Rapport global',
      'DE': 'Gesamtbericht',
      'RU': 'Общий отчёт',
      'AR': 'التقرير الشامل',
      'HI': 'समग्र रिपोर्ट',
      'VI': 'Báo cáo tổng hợp',
      'ES': 'Informe general',
      'TH': 'รายงานสรุป',
    },
    'detailedAnalytics': {
      'KO': '상세분석기록',
      'EN': 'Detailed Analytics',
      'JA': '詳細分析記録',
      'ZH': '详细分析记录',
      'FR': 'Analyse détaillée',
      'DE': 'Detaillierte Analyse',
      'RU': 'Подробная аналитика',
      'AR': 'تحليل تفصيلي',
      'HI': 'विस्तृत विश्लेषण',
      'VI': 'Phân tích chi tiết',
      'ES': 'Análisis detallado',
      'TH': 'บันทึกวิเคราะห์เชิงลึก',
    },
    'nextLevelRoad': {
      'KO': '학습레벨로드',
      'EN': 'Next Level Road',
      'JA': '次のレベルへの道',
      'ZH': '下一等级之路',
      'FR': 'Vers le niveau suivant',
      'DE': 'Weg zum nächsten Level',
      'RU': 'Путь к следующему уровню',
      'AR': 'الطريق إلى المستوى التالي',
      'HI': 'अगले स्तर की राह',
      'VI': 'Lộ trình cấp độ tiếp theo',
      'ES': 'Camino al siguiente nivel',
      'TH': 'เส้นทางสู่เลเวลถัดไป',
    },
    'todaySessionsTitle': {
      'KO': '오늘 학습한 과목',
      'EN': "Today's Study Sessions",
      'JA': '本日の学習科目',
      'ZH': '今日学习科目',
      'FR': "Sessions d'étude du jour",
      'DE': 'Heutige Lernsitzungen',
      'RU': 'Сегодняшние занятия',
      'AR': 'جلسات الدراسة اليوم',
      'HI': 'आज के अध्ययन सत्र',
      'VI': 'Buổi học hôm nay',
      'ES': 'Sesiones de estudio de hoy',
      'TH': 'วิชาที่เรียนวันนี้',
    },
    'noSessionsToday': {
      'KO': '오늘 진행한 학습 세션이 아직 없습니다.',
      'EN': 'No study sessions recorded today yet.',
      'JA': '本日の学習セッションはまだありません。',
      'ZH': '今天还没有学习记录。',
      'FR': "Aucune session d'étude aujourd'hui pour l'instant.",
      'DE': 'Heute wurden noch keine Lernsitzungen aufgezeichnet.',
      'RU': 'Сегодня пока нет записанных занятий.',
      'AR': 'لا توجد جلسات دراسة مسجلة اليوم بعد.',
      'HI': 'आज तक कोई अध्ययन सत्र दर्ज नहीं हुआ।',
      'VI': 'Hôm nay chưa có buổi học nào được ghi lại.',
      'ES': 'Aún no se han registrado sesiones de estudio hoy.',
      'TH': 'วันนี้ยังไม่มีการบันทึกการเรียน',
    },
    // 🆕 [요청 2026-09-04] 날짜별 조회(좌우 화살표)에서 "오늘"이 아닌 과거 날짜를 볼 때 쓰는 일반화된 문구.
    'noSessionsOnDate': {
      'KO': '해당 날짜에 진행한 학습 세션이 없습니다.',
      'EN': 'No study sessions recorded on this date.',
      'JA': 'この日の学習セッションはありません。',
      'ZH': '该日期没有学习记录。',
      'FR': "Aucune session d'étude enregistrée à cette date.",
      'DE': 'An diesem Tag wurden keine Lernsitzungen aufgezeichnet.',
      'RU': 'В этот день нет записанных занятий.',
      'AR': 'لا توجد جلسات دراسة مسجلة في هذا التاريخ.',
      'HI': 'इस तिथि पर कोई अध्ययन सत्र दर्ज नहीं है।',
      'VI': 'Không có buổi học nào được ghi lại vào ngày này.',
      'ES': 'No se registraron sesiones de estudio en esta fecha.',
      'TH': 'ไม่มีการบันทึกการเรียนในวันนี้',
    },
    // 🆕 [요청 2026-09-04] "오늘"이 아닌 날짜의 카드 제목에 쓰이는 일반 명칭 ("MM/DD 학습한 과목" 형태로 조합)
    'sessionsGenericTitle': {
      'KO': '학습한 과목',
      'EN': 'Study Sessions',
      'JA': '学習科目',
      'ZH': '学习科目',
      'FR': "Sessions d'étude",
      'DE': 'Lernsitzungen',
      'RU': 'Занятия',
      'AR': 'جلسات الدراسة',
      'HI': 'अध्ययन सत्र',
      'VI': 'Buổi học',
      'ES': 'Sesiones de estudio',
      'TH': 'วิชาที่เรียน',
    },
    // 🆕 [위험한 오류 수정 2026-09-05] 세션 목록/리포트에서 강의/평가를 명확히 구분 표시하기 위한 라벨.
    'lectureLabel': {
      'KO': '강의',
      'EN': 'Lecture',
      'JA': '講義',
      'ZH': '讲课',
      'FR': 'Cours',
      'DE': 'Vorlesung',
      'RU': 'Лекция',
      'AR': 'محاضرة',
      'HI': 'व्याख्यान',
      'VI': 'Bài giảng',
      'ES': 'Clase',
      'TH': 'บรรยาย',
    },
    'evaluationLabel': {
      'KO': '평가',
      'EN': 'Evaluation',
      'JA': '評価',
      'ZH': '评估',
      'FR': 'Évaluation',
      'DE': 'Bewertung',
      'RU': 'Оценка',
      'AR': 'تقييم',
      'HI': 'मूल्यांकन',
      'VI': 'Đánh giá',
      'ES': 'Evaluación',
      'TH': 'ประเมิน',
    },
    'sessionOrdinal': {
      'KO': '교시',
      'EN': 'Session',
      'JA': '時限目',
      'ZH': '节',
      'FR': 'Séance',
      'DE': 'Einheit',
      'RU': 'Занятие',
      'AR': 'حصة',
      'HI': 'सत्र',
      'VI': 'Tiết',
      'ES': 'Sesión',
      'TH': 'คาบ',
    },
    'minutesUnitSuffix': {
      'KO': '분',
      'EN': 'min',
      'JA': '分',
      'ZH': '分钟',
      'FR': 'min',
      'DE': 'Min',
      'RU': 'мин',
      'AR': 'دقيقة',
      'HI': 'मिनट',
      'VI': 'phút',
      'ES': 'min',
      'TH': 'นาที',
    },
    'starsCount': {
      'KO': '23,487 개',
      'EN': '23,487 Stars',
      'JA': '23,487個',
      'ZH': '23,487颗',
      'FR': '23 487 étoiles',
      'DE': '23.487 Sterne',
      'RU': '23 487 звёзд',
      'AR': '23,487 نجمة',
      'HI': '23,487 स्टार्स',
      'VI': '23.487 sao',
      'ES': '23.487 estrellas',
      'TH': '23,487 ดาว',
    },
    // 🆕 [데이터 연결] 아래 4개는 실제 숫자와 조합해서 쓰는 "단위/접두어" 문구 (숫자 자체는 더 이상 하드코딩하지 않음)
    'levelPrefix': {
      'KO': '학습레벨 ',
      'EN': 'Lv.',
      'JA': 'レベル',
      'ZH': '等级',
      'FR': 'Niv. ',
      'DE': 'Lvl. ',
      'RU': 'Уровень ',
      'AR': 'المستوى ',
      'HI': 'लेवल ',
      'VI': 'Cấp ',
      'ES': 'Nivel ',
      'TH': 'เลเวล ',
    },
    'starsUnitSuffix': {
      'KO': '개',
      'EN': 'Stars',
      'JA': '個',
      'ZH': '颗',
      'FR': 'étoiles',
      'DE': 'Sterne',
      'RU': 'звёзд',
      'AR': 'نجمة',
      'HI': 'स्टार्स',
      'VI': 'sao',
      'ES': 'estrellas',
      'TH': 'ดาว',
    },
    'hoursUnitSuffix': {
      'KO': '시간',
      'EN': 'hrs',
      'JA': '時間',
      'ZH': '小时',
      'FR': 'h',
      'DE': 'Std.',
      'RU': 'ч',
      'AR': 'ساعة',
      'HI': 'घंटे',
      'VI': 'giờ',
      'ES': 'h',
      'TH': 'ชม.',
    },
    'dataCollectingMsg': {
      'KO': '데이터 수집중',
      'EN': 'Collecting data',
      'JA': 'データ収集中',
      'ZH': '数据收集中',
      'FR': 'Collecte de données...',
      'DE': 'Daten werden gesammelt',
      'RU': 'Сбор данных...',
      'AR': 'جمع البيانات...',
      'HI': 'डेटा एकत्रित हो रहा है',
      'VI': 'Đang thu thập dữ liệu',
      'ES': 'Recopilando datos...',
      'TH': 'กำลังรวบรวมข้อมูล',
    },
    'friendRank': {
      'KO': '친구 학습 랭킹: ',
      'EN': 'Friend Rank: ',
      'JA': '友達学習ランキング: ',
      'ZH': '好友学习排名：',
      'FR': 'Classement amis : ',
      'DE': 'Freunde-Rang: ',
      'RU': 'Рейтинг друзей: ',
      'AR': 'ترتيب الأصدقاء: ',
      'HI': 'मित्र रैंक: ',
      'VI': 'Xếp hạng bạn bè: ',
      'ES': 'Ranking de amigos: ',
      'TH': 'อันดับเพื่อน: ',
    },
    'rank3': {
      'KO': '3위\n\n',
      'EN': '#3\n\n',
      'JA': '3位\n\n',
      'ZH': '第3名\n\n',
      'FR': '#3\n\n',
      'DE': '#3\n\n',
      'RU': '#3\n\n',
      'AR': '#3\n\n',
      'HI': '#3\n\n',
      'VI': '#3\n\n',
      'ES': '#3\n\n',
      'TH': 'อันดับ 3\n\n',
    },
    'globalRank': {
      'KO': '전 세계 학습 랭킹:\n',
      'EN': 'Global Rank:\n',
      'JA': '世界学習ランキング：\n',
      'ZH': '全球学习排名：\n',
      'FR': 'Classement mondial :\n',
      'DE': 'Weltweiter Rang:\n',
      'RU': 'Мировой рейтинг:\n',
      'AR': 'الترتيب العالمي:\n',
      'HI': 'वैश्विक रैंक:\n',
      'VI': 'Xếp hạng toàn cầu:\n',
      'ES': 'Ranking mundial:\n',
      'TH': 'อันดับโลก:\n',
    },
    'top12pct': {
      'KO': '상위 1.2%',
      'EN': 'Top 1.2%',
      'JA': '上位1.2%',
      'ZH': '前1.2%',
      'FR': 'Top 1,2 %',
      'DE': 'Top 1,2 %',
      'RU': 'Топ 1,2%',
      'AR': 'الأعلى 1.2٪',
      'HI': 'शीर्ष 1.2%',
      'VI': 'Top 1.2%',
      'ES': 'Top 1.2%',
      'TH': 'ท็อป 1.2%',
    },
    'targetUniversity': {
      'KO': '목표 대학',
      'EN': 'Target University',
      'JA': '目標大学',
      'ZH': '目标大学',
      'FR': 'Université cible',
      'DE': 'Zieluniversität',
      'RU': 'Целевой университет',
      'AR': 'الجامعة المستهدفة',
      'HI': 'लक्ष्य विश्वविद्यालय',
      'VI': 'Trường mục tiêu',
      'ES': 'Universidad objetivo',
      'TH': 'มหาวิทยาลัยเป้าหมาย',
    },
    'snu': {
      'KO': '서울대학교',
      'EN': 'Seoul National University',
      'JA': 'ソウル大学校',
      'ZH': '首尔大学',
      'FR': 'Université Nationale de Séoul',
      'DE': 'Nationaluniversität Seoul',
      'RU': 'Сеульский национальный университет',
      'AR': 'جامعة سيول الوطنية',
      'HI': 'सियोल नेशनल यूनिवर्सिटी',
      'VI': 'Đại học Quốc gia Seoul',
      'ES': 'Universidad Nacional de Seúl',
      'TH': 'มหาวิทยาลัยแห่งชาติโซล',
    },
    'goalAttainment': {
      'KO': '목표 달성도',
      'EN': 'Goal Attainment',
      'JA': '目標達成度',
      'ZH': '目标达成度',
      'FR': 'Taux d\'atteinte',
      'DE': 'Zielerreichung',
      'RU': 'Достижение цели',
      'AR': 'نسبة تحقيق الهدف',
      'HI': 'लक्ष्य प्राप्ति',
      'VI': 'Mức đạt mục tiêu',
      'ES': 'Logro de objetivos',
      'TH': 'อัตราการบรรลุเป้าหมาย',
    },
    'todayVsYesterday': {
      'KO': '어제 대비 오늘 ',
      'EN': 'Today vs Yesterday ',
      'JA': '昨日比 本日 ',
      'ZH': '今日较昨日 ',
      'FR': 'Aujourd\'hui vs hier ',
      'DE': 'Heute vs. gestern ',
      'RU': 'Сегодня к вчера ',
      'AR': 'اليوم مقارنة بالأمس ',
      'HI': 'आज बनाम कल ',
      'VI': 'Hôm nay so với hôm qua ',
      'ES': 'Hoy vs ayer ',
      'TH': 'วันนี้เทียบเมื่อวาน ',
    },
    'mostImprovedSubject': {
      'KO': '가장 성장한 학습과목\n',
      'EN': 'Most Improved Subject\n',
      'JA': '最も伸びた科目\n',
      'ZH': '进步最大的科目\n',
      'FR': 'Matière la plus améliorée\n',
      'DE': 'Am meisten verbessertes Fach\n',
      'RU': 'Предмет с наибольшим ростом\n',
      'AR': 'أكثر مادة تحسنًا\n',
      'HI': 'सबसे अधिक सुधार वाला विषय\n',
      'VI': 'Môn học tiến bộ nhất\n',
      'ES': 'Materia más mejorada\n',
      'TH': 'วิชาที่พัฒนามากที่สุด\n',
    },
    'mostStudiedSubject': {
      'KO': '가장 많이 학습한 과목\n',
      'EN': 'Most Studied Subject\n',
      'JA': '最も学習した科目\n',
      'ZH': '学习最多的科目\n',
      'FR': 'Matière la plus étudiée\n',
      'DE': 'Meist gelerntes Fach\n',
      'RU': 'Самый изучаемый предмет\n',
      'AR': 'أكثر مادة تمت دراستها\n',
      'HI': 'सबसे अधिक पढ़ा गया विषय\n',
      'VI': 'Môn học được học nhiều nhất\n',
      'ES': 'Materia más estudiada\n',
      'TH': 'วิชาที่เรียนมากที่สุด\n',
    },
    'totalStudyTimeLabel': {
      'KO': '총 학습시간:\n',
      'EN': 'Total Study Time:\n',
      'JA': '総学習時間：\n',
      'ZH': '总学习时间：\n',
      'FR': 'Temps d\'étude total :\n',
      'DE': 'Gesamte Lernzeit:\n',
      'RU': 'Общее время учёбы:\n',
      'AR': 'إجمالي وقت الدراسة:\n',
      'HI': 'कुल अध्ययन समय:\n',
      'VI': 'Tổng thời gian học:\n',
      'ES': 'Tiempo total de estudio:\n',
      'TH': 'เวลาเรียนทั้งหมด:\n',
    },
    'totalStudyHours': {
      'KO': '1,257시간',
      'EN': '1,257 hrs',
      'JA': '1,257時間',
      'ZH': '1,257小时',
      'FR': '1 257 h',
      'DE': '1.257 Std.',
      'RU': '1 257 ч',
      'AR': '1,257 ساعة',
      'HI': '1,257 घंटे',
      'VI': '1.257 giờ',
      'ES': '1.257 h',
      'TH': '1,257 ชม.',
    },
    'studyTime': {
      'KO': '과목 학습 시간',
      'EN': 'Subject Study Time',
      'JA': '科目別学習時間',
      'ZH': '科目学习时间',
      'FR': 'Temps d\'étude par matière',
      'DE': 'Lernzeit pro Fach',
      'RU': 'Время учёбы по предметам',
      'AR': 'وقت الدراسة حسب المادة',
      'HI': 'विषयवार अध्ययन समय',
      'VI': 'Thời gian học theo môn',
      'ES': 'Tiempo de estudio por materia',
      'TH': 'เวลาเรียนตามวิชา',
    },
    'dailyTotalStudyTime': {
      'KO': '일일 전체 학습시간',
      'EN': 'Daily Total Study Time',
      'JA': '日別総学習時間',
      'ZH': '每日总学习时间',
      'FR': 'Temps d\'étude quotidien total',
      'DE': 'Tägliche Gesamtlernzeit',
      'RU': 'Общее время учёбы за день',
      'AR': 'إجمالي وقت الدراسة اليومي',
      'HI': 'दैनिक कुल अध्ययन समय',
      'VI': 'Tổng thời gian học mỗi ngày',
      'ES': 'Tiempo total de estudio diario',
      'TH': 'เวลาเรียนรวมต่อวัน',
    },
    'daily': {
      'KO': '일 간',
      'EN': 'Daily',
      'JA': '日別',
      'ZH': '日',
      'FR': 'Jour',
      'DE': 'Täglich',
      'RU': 'День',
      'AR': 'يومي',
      'HI': 'दैनिक',
      'VI': 'Ngày',
      'ES': 'Diario',
      'TH': 'รายวัน',
    },
    'weekly': {
      'KO': '주 간',
      'EN': 'Weekly',
      'JA': '週別',
      'ZH': '周',
      'FR': 'Semaine',
      'DE': 'Wöchentlich',
      'RU': 'Неделя',
      'AR': 'أسبوعي',
      'HI': 'साप्ताहिक',
      'VI': 'Tuần',
      'ES': 'Semanal',
      'TH': 'รายสัปดาห์',
    },
    'monthly': {
      'KO': '월 간',
      'EN': 'Monthly',
      'JA': '月別',
      'ZH': '月',
      'FR': 'Mois',
      'DE': 'Monatlich',
      'RU': 'Месяц',
      'AR': 'شهري',
      'HI': 'मासिक',
      'VI': 'Tháng',
      'ES': 'Mensual',
      'TH': 'รายเดือน',
    },
    'yearly': {
      'KO': '연 간',
      'EN': 'Yearly',
      'JA': '年別',
      'ZH': '年',
      'FR': 'Année',
      'DE': 'Jährlich',
      'RU': 'Год',
      'AR': 'سنوي',
      'HI': 'वार्षिक',
      'VI': 'Năm',
      'ES': 'Anual',
      'TH': 'รายปี',
    },
    'myScoreRecord': {
      'KO': '나의 성적 기록 직접 작성',
      'EN': 'My Score Self Record',
      'JA': '自分の成績を記録する',
      'ZH': '自主记录我的成绩',
      'FR': 'Mon carnet de notes',
      'DE': 'Meine Notenaufzeichnung',
      'RU': 'Мои записи об оценках',
      'AR': 'سجل درجاتي الخاص',
      'HI': 'मेरा स्कोर रिकॉर्ड',
      'VI': 'Tự ghi điểm của tôi',
      'ES': 'Mi registro de notas',
      'TH': 'บันทึกคะแนนของฉัน',
    },
    'yearSelect': {
      'KO': '년도 선택',
      'EN': 'Year',
      'JA': '年を選択',
      'ZH': '选择年份',
      'FR': 'Année',
      'DE': 'Jahr',
      'RU': 'Год',
      'AR': 'السنة',
      'HI': 'वर्ष',
      'VI': 'Năm',
      'ES': 'Año',
      'TH': 'ปี',
    },
    'monthSelect': {
      'KO': '월 선택',
      'EN': 'Month',
      'JA': '月を選択',
      'ZH': '选择月份',
      'FR': 'Mois',
      'DE': 'Monat',
      'RU': 'Месяц',
      'AR': 'الشهر',
      'HI': 'महीना',
      'VI': 'Tháng',
      'ES': 'Mes',
      'TH': 'เดือน',
    },
    'weekSelect': {
      'KO': '주 선택',
      'EN': 'Week',
      'JA': '週を選択',
      'ZH': '选择周次',
      'FR': 'Semaine',
      'DE': 'Woche',
      'RU': 'Неделя',
      'AR': 'الأسبوع',
      'HI': 'सप्ताह',
      'VI': 'Tuần',
      'ES': 'Semana',
      'TH': 'สัปดาห์',
    },
    'bigUnitSelect': {
      'KO': '대단원 선택',
      'EN': 'Major Unit',
      'JA': '大単元を選択',
      'ZH': '选择大单元',
      'FR': 'Unité principale',
      'DE': 'Haupteinheit',
      'RU': 'Основной раздел',
      'AR': 'الوحدة الرئيسية',
      'HI': 'मुख्य यूनिट',
      'VI': 'Chương lớn',
      'ES': 'Unidad principal',
      'TH': 'บทหลัก',
    },
    'midUnitSelect': {
      'KO': '중단원 선택',
      'EN': 'Sub Unit',
      'JA': '中単元を選択',
      'ZH': '选择中单元',
      'FR': 'Sous-unité',
      'DE': 'Untereinheit',
      'RU': 'Подраздел',
      'AR': 'الوحدة الفرعية',
      'HI': 'सब-यूनिट',
      'VI': 'Chương nhỏ',
      'ES': 'Subunidad',
      'TH': 'บทย่อย',
    },
    'semesterSelect': {
      'KO': '학기 선택',
      'EN': 'Semester',
      'JA': '学期を選択',
      'ZH': '选择学期',
      'FR': 'Semestre',
      'DE': 'Semester',
      'RU': 'Семестр',
      'AR': 'الفصل الدراسي',
      'HI': 'सेमेस्टर',
      'VI': 'Học kỳ',
      'ES': 'Semestre',
      'TH': 'ภาคเรียน',
    },
    'chartTarget': {
      'KO': '그래프 출력 타겟 지정 (학년 / 학기)',
      'EN': 'Chart Target (Grade / Semester)',
      'JA': 'グラフ対象指定（学年／学期）',
      'ZH': '图表目标设置（年级／学期）',
      'FR': 'Cible du graphique (année / semestre)',
      'DE': 'Diagrammziel (Klasse / Semester)',
      'RU': 'Цель графика (класс / семестр)',
      'AR': 'هدف الرسم البياني (الصف / الفصل)',
      'HI': 'चार्ट लक्ष्य (कक्षा / सेमेस्टर)',
      'VI': 'Mục tiêu biểu đồ (khối / học kỳ)',
      'ES': 'Objetivo del gráfico (grado / semestre)',
      'TH': 'เป้าหมายกราฟ (ระดับชั้น/ภาคเรียน)',
    },
    'newRecordGradeSemesterLabel': {
      'KO': '지금 입력할 새 기록의 학년 / 학기',
      'EN': 'Grade / Semester for this new entry',
      'JA': '今回入力する記録の学年／学期',
      'ZH': '本次输入记录的年级／学期',
      'FR': 'Année / semestre de cette nouvelle entrée',
      'DE': 'Klasse / Semester für diesen neuen Eintrag',
      'RU': 'Класс / семестр для новой записи',
      'AR': 'الصف / الفصل لهذا السجل الجديد',
      'HI': 'इस नई प्रविष्टि के लिए कक्षा / सेमेस्टर',
      'VI': 'Khối / học kỳ cho mục nhập mới này',
      'ES': 'Grado / semestre para esta nueva entrada',
      'TH': 'ระดับชั้น/ภาคเรียนสำหรับรายการใหม่นี้',
    },
    'gradeLabel': {
      'KO': '학년',
      'EN': 'Grade',
      'JA': '学年',
      'ZH': '年级',
      'FR': 'Année',
      'DE': 'Klasse',
      'RU': 'Класс',
      'AR': 'الصف',
      'HI': 'कक्षा',
      'VI': 'Khối lớp',
      'ES': 'Grado',
      'TH': 'ระดับชั้น',
    },
    'semesterLabel': {
      'KO': '학기',
      'EN': 'Semester',
      'JA': '学期',
      'ZH': '学期',
      'FR': 'Semestre',
      'DE': 'Semester',
      'RU': 'Семестр',
      'AR': 'الفصل الدراسي',
      'HI': 'सेमेस्टर',
      'VI': 'Học kỳ',
      'ES': 'Semestre',
      'TH': 'ภาคเรียน',
    },
    'subjectHint': {
      'KO': '과목생성',
      'EN': 'Subject',
      'JA': '科目作成',
      'ZH': '创建科目',
      'FR': 'Matière',
      'DE': 'Fach',
      'RU': 'Предмет',
      'AR': 'المادة',
      'HI': 'विषय',
      'VI': 'Môn học',
      'ES': 'Materia',
      'TH': 'วิชา',
    },
    'unitHint': {
      'KO': '단원생성',
      'EN': 'Unit',
      'JA': '単元作成',
      'ZH': '创建单元',
      'FR': 'Unité',
      'DE': 'Einheit',
      'RU': 'Раздел',
      'AR': 'الوحدة',
      'HI': 'यूनिट',
      'VI': 'Chương',
      'ES': 'Unidad',
      'TH': 'บท',
    },
    'scoreHint': {
      'KO': '점수',
      'EN': 'Score',
      'JA': '点数',
      'ZH': '分数',
      'FR': 'Score',
      'DE': 'Punktzahl',
      'RU': 'Балл',
      'AR': 'الدرجة',
      'HI': 'स्कोर',
      'VI': 'Điểm',
      'ES': 'Puntuación',
      'TH': 'คะแนน',
    },
    'saveBtn': {
      'KO': '저장',
      'EN': 'Save',
      'JA': '保存',
      'ZH': '保存',
      'FR': 'Enregistrer',
      'DE': 'Speichern',
      'RU': 'Сохранить',
      'AR': 'حفظ',
      'HI': 'सहेजें',
      'VI': 'Lưu',
      'ES': 'Guardar',
      'TH': 'บันทึก',
    },
    'onlyRecordedSubjectsChart': {
      'KO': '평가가 기록된 과목만 그래프에 나타나게한다',
      'EN': 'Only subjects with recorded evaluations appear on the chart.',
      'JA': '評価が記録された科目だけがグラフに表示されます。',
      'ZH': '仅显示已记录评估的科目。',
      'FR': 'Seules les matières évaluées apparaissent sur le graphique.',
      'DE': 'Nur bewertete Fächer werden im Diagramm angezeigt.',
      'RU': 'На графике отображаются только оценённые предметы.',
      'AR': 'تظهر في الرسم البياني فقط المواد التي تم تسجيل تقييم لها.',
      'HI': 'चार्ट में केवल मूल्यांकित विषय ही दिखाए जाते हैं।',
      'VI': 'Chỉ các môn đã có điểm đánh giá mới hiển thị trên biểu đồ.',
      'ES':
          'Solo las materias con evaluaciones registradas aparecen en el gráfico.',
      'TH': 'กราฟจะแสดงเฉพาะวิชาที่มีการบันทึกผลประเมินเท่านั้น',
    },
    'average': {
      'KO': '평균',
      'EN': 'Average',
      'JA': '平均',
      'ZH': '平均',
      'FR': 'Moyenne',
      'DE': 'Durchschnitt',
      'RU': 'Среднее',
      'AR': 'المتوسط',
      'HI': 'औसत',
      'VI': 'Trung bình',
      'ES': 'Promedio',
      'TH': 'ค่าเฉลี่ย',
    },
    'lifeBalance': {
      'KO': '종합 생활 균형',
      'EN': 'Comprehensive Life Balance',
      'JA': '総合生活バランス',
      'ZH': '综合生活平衡',
      'FR': 'Équilibre de vie global',
      'DE': 'Ganzheitliche Lebensbalance',
      'RU': 'Общий баланс жизни',
      'AR': 'التوازن الشامل في الحياة',
      'HI': 'समग्र जीवन संतुलन',
      'VI': 'Cân bằng cuộc sống tổng thể',
      'ES': 'Equilibrio integral de vida',
      'TH': 'ความสมดุลชีวิตโดยรวม',
    },
    'lifeBalanceSub': {
      'KO': '(종합 생활 균형 밸런스 분석)',
      'EN': '(Comprehensive life balance analysis)',
      'JA': '（総合生活バランス分析）',
      'ZH': '（综合生活平衡分析）',
      'FR': '(Analyse de l\'équilibre de vie global)',
      'DE': '(Analyse der ganzheitlichen Lebensbalance)',
      'RU': '(Анализ общего баланса жизни)',
      'AR': '(تحليل التوازن الشامل في الحياة)',
      'HI': '(समग्र जीवन संतुलन विश्लेषण)',
      'VI': '(Phân tích cân bằng cuộc sống tổng thể)',
      'ES': '(Análisis del equilibrio integral de vida)',
      'TH': '(การวิเคราะห์ความสมดุลชีวิตโดยรวม)',
    },
    // 🆕 [장학금 방 다국어 2026-09-18] 하단 탭 라벨
    'liveAchievementTab': {
      'KO': '실시간 학습성취',
      'EN': 'Live Achievement',
      'JA': 'リアルタイム学習成果',
      'ZH': '实时学习成就',
      'FR': 'Réussite en direct',
      'DE': 'Live-Leistung',
      'RU': 'Успеваемость в реальном времени',
      'AR': 'الإنجاز الفوري',
      'HI': 'लाइव उपलब्धि',
      'VI': 'Thành tích trực tiếp',
      'ES': 'Logro en vivo',
      'TH': 'ผลสัมฤทธิ์เรียลไทม์',
    },
    'liveStarsTab': {
      'KO': '실시간 성취별',
      'EN': 'Live Stars',
      'JA': 'リアルタイム星',
      'ZH': '实时成就星',
      'FR': 'Étoiles en direct',
      'DE': 'Live-Sterne',
      'RU': 'Звёзды в реальном времени',
      'AR': 'النجوم الفورية',
      'HI': 'लाइव सितारे',
      'VI': 'Sao trực tiếp',
      'ES': 'Estrellas en vivo',
      'TH': 'ดาวเรียลไทม์',
    },
    // 🆕 카드 제목
    'liveStatusCardTitle': {
      'KO': '실시간 학습 현황',
      'EN': 'Live Study Status',
      'JA': 'リアルタイム学習状況',
      'ZH': '实时学习现状',
      'FR': "État d'étude en direct",
      'DE': 'Live-Lernstatus',
      'RU': 'Статус обучения в реальном времени',
      'AR': 'حالة الدراسة الفورية',
      'HI': 'लाइव अध्ययन स्थिति',
      'VI': 'Tình trạng học trực tiếp',
      'ES': 'Estado de estudio en vivo',
      'TH': 'สถานะการเรียนเรียลไทม์',
    },
    'achievementStarsCardTitle': {
      'KO': '나의 성취별 현황',
      'EN': 'My Achievement Stars',
      'JA': '私の達成スター状況',
      'ZH': '我的成就星现状',
      'FR': "Mes étoiles de réussite",
      'DE': 'Meine Erfolgssterne',
      'RU': 'Мои звёзды достижений',
      'AR': 'نجوم إنجازاتي',
      'HI': 'मेरे उपलब्धि सितारे',
      'VI': 'Sao thành tích của tôi',
      'ES': 'Mis estrellas de logro',
      'TH': 'ดาวความสำเร็จของฉัน',
    },
    'monthlyBaseStarsLabel': {
      'KO': '기본별(학습시간)',
      'EN': 'Base Stars (Study Time)',
      'JA': '基本スター（学習時間）',
      'ZH': '基础星（学习时间）',
      'FR': 'Étoiles de base (temps)',
      'DE': 'Basissterne (Lernzeit)',
      'RU': 'Базовые звёзды (время)',
      'AR': 'نجوم أساسية (وقت الدراسة)',
      'HI': 'आधार सितारे (समय)',
      'VI': 'Sao cơ bản (thời gian)',
      'ES': 'Estrellas base (tiempo)',
      'TH': 'ดาวพื้นฐาน (เวลาเรียน)',
    },
    'todayBaseStarsLabel': {
      'KO': '오늘 학습별(학습시간)',
      'EN': "Today's Stars (Study Time)",
      'JA': '本日の学習スター（学習時間）',
      'ZH': '今日学习星（学习时间）',
      'FR': "Étoiles du jour (temps d'étude)",
      'DE': 'Heutige Sterne (Lernzeit)',
      'RU': 'Звёзды за сегодня (время)',
      'AR': 'نجوم اليوم (وقت الدراسة)',
      'HI': 'आज के सितारे (समय)',
      'VI': 'Sao hôm nay (thời gian)',
      'ES': 'Estrellas de hoy (tiempo)',
      'TH': 'ดาววันนี้ (เวลาเรียน)',
    },
    'bonusStarsLabel': {
      'KO': '보너스별',
      'EN': 'Bonus Stars',
      'JA': 'ボーナススター',
      'ZH': '奖励星',
      'FR': 'Étoiles bonus',
      'DE': 'Bonussterne',
      'RU': 'Бонусные звёзды',
      'AR': 'نجوم إضافية',
      'HI': 'बोनस सितारे',
      'VI': 'Sao thưởng',
      'ES': 'Estrellas bonus',
      'TH': 'ดาวโบนัส',
    },
    'monthlyTotalStarsLabel': {
      'KO': '이번 달 누적 별',
      'EN': "This Month's Stars",
      'JA': '今月の累積スター',
      'ZH': '本月累计星',
      'FR': 'Étoiles de ce mois-ci',
      'DE': 'Sterne diesen Monat',
      'RU': 'Звёзды за месяц',
      'AR': 'نجوم هذا الشهر',
      'HI': 'इस महीने के सितारे',
      'VI': 'Sao tháng này',
      'ES': 'Estrellas de este mes',
      'TH': 'ดาวสะสมเดือนนี้',
    },
    'bonusBreakdownTitle': {
      'KO': '보너스별 상세 내역',
      'EN': 'Bonus Star Details',
      'JA': 'ボーナススター詳細',
      'ZH': '奖励星详情',
      'FR': 'Détails des étoiles bonus',
      'DE': 'Bonusstern-Details',
      'RU': 'Подробности бонусных звёзд',
      'AR': 'تفاصيل النجوم الإضافية',
      'HI': 'बोनस सितारे विवरण',
      'VI': 'Chi tiết sao thưởng',
      'ES': 'Detalles de estrellas bonus',
      'TH': 'รายละเอียดดาวโบนัส',
    },
    'howToEarnStarsBtn': {
      'KO': '별은 어떻게 모으나요?',
      'EN': 'How do I earn stars?',
      'JA': '星はどうやって集める？',
      'ZH': '如何获得星星？',
      'FR': 'Comment gagner des étoiles ?',
      'DE': 'Wie sammle ich Sterne?',
      'RU': 'Как заработать звёзды?',
      'AR': 'كيف أكسب النجوم؟',
      'HI': 'सितारे कैसे कमाएं?',
      'VI': 'Làm sao để nhận sao?',
      'ES': '¿Cómo gano estrellas?',
      'TH': 'สะสมดาวได้อย่างไร?',
    },
    'scholarshipNoticeTitle': {
      'KO': '⭐ 별을 모으는 방법',
      'EN': '⭐ How to Earn Stars',
      'JA': '⭐ 星の集め方',
      'ZH': '⭐ 如何获得星星',
      'FR': '⭐ Comment gagner des étoiles',
      'DE': '⭐ So sammelst du Sterne',
      'RU': '⭐ Как заработать звёзды',
      'AR': '⭐ كيفية كسب النجوم',
      'HI': '⭐ सितारे कैसे कमाएं',
      'VI': '⭐ Cách nhận sao',
      'ES': '⭐ Cómo ganar estrellas',
      'TH': '⭐ วิธีสะสมดาว',
    },
    'typeNotSelectedYet': {
      'KO': '이번 달 장학금 유형이 아직 선택되지 않았어요. 부모님께서 곧 정해주실 거예요!',
      'EN':
          "This month's scholarship type hasn't been chosen yet. Your parents will pick one soon!",
      'JA': '今月の奨学金タイプはまだ選択されていません。まもなく保護者が決めてくれます！',
      'ZH': '本月奖学金类型尚未选择，家长很快会为你决定！',
      'FR':
          "Le type de bourse de ce mois n'a pas encore été choisi. Vos parents le feront bientôt !",
      'DE':
          'Der Stipendientyp für diesen Monat wurde noch nicht gewählt. Deine Eltern entscheiden bald!',
      'RU':
          'Тип стипендии за этот месяц ещё не выбран. Родители скоро выберут!',
      'AR': 'لم يتم اختيار نوع المنحة لهذا الشهر بعد. سيحدده والداك قريبًا!',
      'HI':
          'इस महीने की छात्रवृत्ति का प्रकार अभी तय नहीं हुआ। आपके माता-पिता जल्द ही चुनेंगे!',
      'VI':
          'Loại học bổng tháng này chưa được chọn. Bố mẹ con sẽ chọn sớm thôi!',
      'ES':
          'Aún no se ha elegido el tipo de beca de este mes. ¡Tus padres lo elegirán pronto!',
      'TH':
          'ยังไม่ได้เลือกประเภททุนการศึกษาของเดือนนี้ พ่อแม่ของหนูจะเลือกเร็วๆ นี้!',
    },
    'thisMonthEstimatedScholarship': {
      'KO': '이번 달 예상 장학금',
      'EN': "This Month's Estimated Scholarship",
      'JA': '今月の予想奨学金',
      'ZH': '本月预计奖学金',
      'FR': 'Bourse estimée ce mois-ci',
      'DE': 'Geschätztes Stipendium diesen Monat',
      'RU': 'Ожидаемая стипендия за месяц',
      'AR': 'المنحة المتوقعة لهذا الشهر',
      'HI': 'इस महीने की अनुमानित छात्रवृत्ति',
      'VI': 'Học bổng dự kiến tháng này',
      'ES': 'Beca estimada de este mes',
      'TH': 'ทุนการศึกษาโดยประมาณเดือนนี้',
    },
    'dbSyncTitle': {
      'KO': '데이터베이스 동기화 알림',
      'EN': 'Database Sync Notification',
      'JA': 'データベース同期通知',
      'ZH': '数据库同步通知',
      'FR': 'Notification de synchronisation',
      'DE': 'Datenbank-Synchronisierung',
      'RU': 'Уведомление о синхронизации',
      'AR': 'إشعار مزامنة قاعدة البيانات',
      'HI': 'डेटाबेस सिंक सूचना',
      'VI': 'Thông báo đồng bộ dữ liệu',
      'ES': 'Notificación de sincronización',
      'TH': 'การแจ้งเตือนซิงค์ข้อมูล',
    },
    'dbSyncSub': {
      'KO': '(데이터를 안전하게 동기화 중입니다...)',
      'EN': '(Synchronizing data storage safely...)',
      'JA': '（データを安全に同期しています...）',
      'ZH': '（正在安全同步数据...）',
      'FR': '(Synchronisation sécurisée des données...)',
      'DE': '(Daten werden sicher synchronisiert...)',
      'RU': '(Безопасная синхронизация данных...)',
      'AR': '(تتم مزامنة البيانات بأمان...)',
      'HI': '(डेटा को सुरक्षित रूप से सिंक किया जा रहा है...)',
      'VI': '(Đang đồng bộ dữ liệu an toàn...)',
      'ES': '(Sincronizando datos de forma segura...)',
      'TH': '(กำลังซิงค์ข้อมูลอย่างปลอดภัย...)',
    },
    'mockDiagTitle': {
      'KO': '모의고사 정밀 평가 진단',
      'EN': 'Mock Exam Detailed Diagnosis',
      'JA': '模試精密評価診断',
      'ZH': '模拟考试精密诊断',
      'FR': 'Diagnostic détaillé de l\'examen blanc',
      'DE': 'Detaillierte Diagnose des Testexamens',
      'RU': 'Подробная диагностика пробного экзамена',
      'AR': 'تشخيص دقيق للاختبار التجريبي',
      'HI': 'मॉक परीक्षा विस्तृत निदान',
      'VI': 'Chẩn đoán chi tiết kỳ thi thử',
      'ES': 'Diagnóstico detallado del examen simulado',
      'TH': 'การวินิจฉัยเชิงลึกข้อสอบจำลอง',
    },
    'examDiagTitle': {
      'KO': '시험 성취도 세부 피드백 설정',
      'EN': 'Exam Achievement Feedback Setup',
      'JA': '試験成果詳細フィードバック設定',
      'ZH': '考试成果详细反馈设置',
      'FR': 'Configuration du retour détaillé sur l\'examen',
      'DE': 'Detailliertes Feedback zur Prüfungsleistung',
      'RU': 'Настройка подробной обратной связи по экзамену',
      'AR': 'إعداد ملاحظات تفصيلية عن نتيجة الاختبار',
      'HI': 'परीक्षा उपलब्धि विस्तृत फ़ीडबैक सेटअप',
      'VI': 'Thiết lập phản hồi chi tiết về kết quả thi',
      'ES': 'Configuración de retroalimentación detallada del examen',
      'TH': 'ตั้งค่าฟีดแบ็กผลสอบแบบละเอียด',
    },
    'emptyFallbackShort': {
      'KO':
          '현재 해당 카테고리에 누적된 데이터셋이 식별되지 않아 기본 정성 분석을 수행합니다.\n\n학습자의 메타인지 상태는 평균치에 도달했으나 실전 정합성을 높이기 위한 개념 오답 관리가 요구됩니다. 용기를 잃지 말고 내일의 세션에 몰입하십시오.',
      'EN':
          'No accumulated dataset found for this category, so a general qualitative analysis is provided.\n\nThe learner\'s metacognitive state is average, but reviewing conceptual mistakes will help solidify readiness. Stay confident and stay focused for tomorrow\'s session.',
      'JA':
          'このカテゴリーには蓄積データが見つからないため、基本的な定性分析を行います。\n\n学習者のメタ認知状態は平均的ですが、実戦力を高めるには概念の誤答管理が必要です。勇気を失わず、明日のセッションに集中しましょう。',
      'ZH':
          '该类别暂无累积数据，因此进行基础定性分析。\n\n学习者的元认知水平处于平均水平，但需要加强概念性错题管理以提升实战能力。请保持信心，专注于明天的学习。',
      'FR':
          'Aucune donnée cumulée n\'a été trouvée pour cette catégorie ; une analyse qualitative générale est donc fournie.\n\nLe niveau métacognitif de l\'apprenant est moyen, mais revoir les erreurs conceptuelles renforcera sa préparation. Restez confiant pour la prochaine session.',
      'DE':
          'Für diese Kategorie wurden keine gesammelten Daten gefunden, daher wird eine allgemeine qualitative Analyse bereitgestellt.\n\nDer metakognitive Zustand des Lernenden ist durchschnittlich, aber die Überprüfung konzeptioneller Fehler wird die Vorbereitung stärken. Bleiben Sie zuversichtlich für die nächste Sitzung.',
      'RU':
          'Накопленных данных по этой категории не найдено, поэтому предоставлен общий качественный анализ.\n\nМетакогнитивное состояние учащегося среднее, но разбор концептуальных ошибок поможет закрепить готовность. Сохраняйте уверенность перед следующим занятием.',
      'AR':
          'لم يتم العثور على بيانات متراكمة لهذه الفئة، لذا يتم تقديم تحليل نوعي عام.\n\nحالة الإدراك الفوقي للمتعلم متوسطة، ولكن مراجعة الأخطاء المفاهيمية ستعزز الاستعداد. حافظ على ثقتك وركز على الجلسة القادمة.',
      'HI':
          'इस श्रेणी के लिए कोई संचित डेटा नहीं मिला, इसलिए एक सामान्य गुणात्मक विश्लेषण प्रदान किया गया है।\n\nसीखने वाले की मेटाकॉग्निटिव स्थिति औसत है, लेकिन वैचारिक गलतियों की समीक्षा तैयारी को मजबूत करेगी। आत्मविश्वास बनाए रखें और आगामी सत्र पर ध्यान दें।',
      'VI':
          'Không tìm thấy dữ liệu tích lũy cho hạng mục này, vì vậy đây là phân tích định tính chung.\n\nTrạng thái nhận thức của người học ở mức trung bình, nhưng việc xem lại các lỗi khái niệm sẽ giúp cải thiện. Hãy giữ tự tin và tập trung cho buổi học tiếp theo.',
      'ES':
          'No se encontraron datos acumulados para esta categoría, por lo que se ofrece un análisis cualitativo general.\n\nEl estado metacognitivo del estudiante es promedio, pero revisar los errores conceptuales fortalecerá su preparación. Mantén la confianza para la próxima sesión.',
      'TH':
          'ไม่พบข้อมูลสะสมในหมวดนี้ จึงขอนำเสนอการวิเคราะห์เชิงคุณภาพทั่วไป\n\nสภาวะการรู้คิดของผู้เรียนอยู่ในระดับเฉลี่ย แต่การทบทวนข้อผิดพลาดด้านแนวคิดจะช่วยเสริมความพร้อม รักษาความมั่นใจและตั้งใจกับครั้งถัดไป',
    },
    'emptyFallbackLong': {
      'KO':
          '현재 해당 카테고리에 누적된 성적 메트릭이 식별되지 않아 기본 정성 분석을 수행합니다.\n\n학습자의 메타인지(자신의 인지 활동을 모니터링하고 조절하는 능력) 수준은 양호하나 과목 간 편차가 존재할 수 있습니다. 실전에서 흔들리지 않기 위해서는 개념 정합성 확인 프로세스를 고도화해야 합니다. 언제나 가능성이 열려있으니 포기하지 말고 전진합시다.',
      'EN':
          'No accumulated score metrics were found for this category, so a general qualitative analysis is provided.\n\nThe learner\'s metacognitive level appears sound, though gaps between subjects may exist. To stay steady under real test conditions, strengthen the concept-verification process. Possibility is always open — keep moving forward.',
      'JA':
          'このカテゴリーには蓄積された成績データが見つからないため、基本的な定性分析を行います。\n\n学習者のメタ認知（自身の認知活動を監視・調整する能力）は良好ですが、科目間の差が存在する可能性があります。実戦で動揺しないためには概念の整合性確認プロセスを高度化する必要があります。可能性は常に開かれているので、諦めずに前進しましょう。',
      'ZH':
          '该类别暂无累积成绩数据，因此进行基础定性分析。\n\n学习者的元认知水平（监控和调节自身认知活动的能力）良好，但学科间可能存在差异。为了在实战中保持稳定，需要提升概念一致性确认流程。可能性始终存在，不要放弃，继续前进。',
      'FR':
          'Aucune métrique de score cumulée n\'a été trouvée pour cette catégorie ; une analyse qualitative générale est donc fournie.\n\nLe niveau métacognitif de l\'apprenant semble bon, bien que des écarts entre matières puissent exister. Pour rester stable en conditions réelles, il faut renforcer le processus de vérification des concepts. Les possibilités restent ouvertes — continuez d\'avancer.',
      'DE':
          'Für diese Kategorie wurden keine gesammelten Notenmetriken gefunden, daher wird eine allgemeine qualitative Analyse bereitgestellt.\n\nDas metakognitive Niveau des Lernenden erscheint solide, wobei Unterschiede zwischen Fächern bestehen können. Um unter realen Testbedingungen stabil zu bleiben, sollte der Konzeptüberprüfungsprozess gestärkt werden. Die Möglichkeit bleibt immer offen — bleiben Sie in Bewegung.',
      'RU':
          'Накопленных показателей успеваемости по этой категории не найдено, поэтому предоставлен общий качественный анализ.\n\nМетакогнитивный уровень учащегося выглядит хорошим, хотя между предметами могут быть расхождения. Чтобы сохранять устойчивость в реальных условиях, нужно усилить процесс проверки концепций. Возможность всегда открыта — продолжайте двигаться вперёд.',
      'AR':
          'لم يتم العثور على مقاييس درجات متراكمة لهذه الفئة، لذا يتم تقديم تحليل نوعي عام.\n\nيبدو مستوى الإدراك الفوقي للمتعلم جيدًا، على الرغم من احتمال وجود فجوات بين المواد. للحفاظ على الثبات في ظروف الاختبار الحقيقية، يجب تعزيز عملية التحقق من المفاهيم. الإمكانية مفتوحة دائمًا — استمر في التقدم.',
      'HI':
          'इस श्रेणी के लिए कोई संचित स्कोर मेट्रिक्स नहीं मिला, इसलिए एक सामान्य गुणात्मक विश्लेषण प्रदान किया गया है।\n\nसीखने वाले का मेटाकॉग्निटिव स्तर अच्छा प्रतीत होता है, हालांकि विषयों के बीच अंतर हो सकता है। वास्तविक परीक्षा स्थितियों में स्थिर रहने के लिए, अवधारणा-सत्यापन प्रक्रिया को मजबूत करें। संभावना हमेशा खुली है — आगे बढ़ते रहें।',
      'VI':
          'Không tìm thấy chỉ số điểm tích lũy cho hạng mục này, vì vậy đây là phân tích định tính chung.\n\nMức độ nhận thức của người học có vẻ tốt, dù có thể có sự chênh lệch giữa các môn. Để giữ ổn định trong điều kiện thi thực tế, cần củng cố quy trình xác minh khái niệm. Khả năng luôn rộng mở — hãy tiếp tục tiến lên.',
      'ES':
          'No se encontraron métricas de puntuación acumuladas para esta categoría, por lo que se ofrece un análisis cualitativo general.\n\nEl nivel metacognitivo del estudiante parece sólido, aunque puede haber diferencias entre materias. Para mantenerse estable en condiciones de examen real, fortalece el proceso de verificación de conceptos. La posibilidad siempre está abierta: sigue avanzando.',
      'TH':
          'ไม่พบข้อมูลคะแนนสะสมในหมวดนี้ จึงขอนำเสนอการวิเคราะห์เชิงคุณภาพทั่วไป\n\nระดับการรู้คิดของผู้เรียนดูเหมาะสมดี แม้อาจมีความแตกต่างระหว่างวิชา เพื่อรักษาความมั่นคงในสถานการณ์สอบจริง ควรเสริมกระบวนการตรวจสอบแนวคิดให้แข็งแกร่งขึ้น โอกาสเปิดกว้างเสมอ อย่าหยุดที่จะก้าวต่อไป',
    },
    'achievementWord': {
      'KO': '성취도',
      'EN': 'Achievement',
      'JA': '成果',
      'ZH': '成就度',
      'FR': 'Réussite',
      'DE': 'Leistung',
      'RU': 'Успеваемость',
      'AR': 'التحصيل',
      'HI': 'उपलब्धि',
      'VI': 'Thành tích',
      'ES': 'Logro',
      'TH': 'ผลสัมฤทธิ์',
    },
    'highSchoolGrade2': {
      'KO': 'GKE 고등학교 2학년',
      'EN': 'GKE High School, Grade 11',
      'JA': 'GKE高校2年生',
      'ZH': 'GKE高中二年级',
      'FR': 'GKE Lycée, 2e année',
      'DE': 'GKE Gymnasium, 2. Klasse',
      'RU': 'GKE школа, 2 курс',
      'AR': 'GKE الصف الثاني الثانوي',
      'HI': 'GKE हाई स्कूल कक्षा 2',
      'VI': 'GKE Cấp 3, lớp 11',
      'ES': 'GKE Bachillerato, 2º año',
      'TH': 'GKE มัธยมปลาย ปีที่ 2',
    },
    'recentFeedbackPrefix': {
      'KO': '[최근 작성]',
      'EN': '[Recent]',
      'JA': '[最近作成]',
      'ZH': '[最近]',
      'FR': '[Récent]',
      'DE': '[Zuletzt]',
      'RU': '[Недавнее]',
      'AR': '[الأحدث]',
      'HI': '[हाल का]',
      'VI': '[Gần đây]',
      'ES': '[Reciente]',
      'TH': '[ล่าสุด]',
    },
    'achievementFeedbackMetrics': {
      'KO': '성취 피드백 메트릭스',
      'EN': 'Achievement Feedback Metrics',
      'JA': '成果フィードバック指標',
      'ZH': '成果反馈指标',
      'FR': 'Indicateurs de progression',
      'DE': 'Leistungs-Feedback-Metriken',
      'RU': 'Метрики обратной связи по успеваемости',
      'AR': 'مؤشرات ملاحظات التحصيل',
      'HI': 'उपलब्धि फ़ीडबैक मेट्रिक्स',
      'VI': 'Chỉ số phản hồi thành tích',
      'ES': 'Métricas de retroalimentación de logros',
      'TH': 'ตัวชี้วัดฟีดแบ็กผลสัมฤทธิ์',
    },
    'targetSubjectLabel': {
      'KO': '타겟 과목',
      'EN': 'Target',
      'JA': '対象科目',
      'ZH': '目标科目',
      'FR': 'Matière ciblée',
      'DE': 'Zielfach',
      'RU': 'Целевой предмет',
      'AR': 'المادة المستهدفة',
      'HI': 'लक्ष्य विषय',
      'VI': 'Môn mục tiêu',
      'ES': 'Materia objetivo',
      'TH': 'วิชาเป้าหมาย',
    },
    'scoreLabel': {
      'KO': '점수',
      'EN': 'Score',
      'JA': '点数',
      'ZH': '分数',
      'FR': 'Score',
      'DE': 'Punktzahl',
      'RU': 'Балл',
      'AR': 'الدرجة',
      'HI': 'स्कोर',
      'VI': 'Điểm',
      'ES': 'Puntuación',
      'TH': 'คะแนน',
    },
    'viewAnalysisReport': {
      'KO': '분석 보고서 조회하기',
      'EN': 'View Analysis Report',
      'JA': '分析レポートを見る',
      'ZH': '查看分析报告',
      'FR': 'Voir le rapport d\'analyse',
      'DE': 'Analysebericht ansehen',
      'RU': 'Просмотреть отчёт анализа',
      'AR': 'عرض تقرير التحليل',
      'HI': 'विश्लेषण रिपोर्ट देखें',
      'VI': 'Xem báo cáo phân tích',
      'ES': 'Ver informe de análisis',
      'TH': 'ดูรายงานการวิเคราะห์',
    },
    'entryAndHistory': {
      'KO': '입력 및 과거 선택 조회',
      'EN': 'Entry & History',
      'JA': '入力と履歴の確認',
      'ZH': '输入与历史查看',
      'FR': 'Saisie et historique',
      'DE': 'Eingabe & Verlauf',
      'RU': 'Ввод и история',
      'AR': 'الإدخال والسجل',
      'HI': 'प्रविष्टि और इतिहास',
      'VI': 'Nhập liệu & lịch sử',
      'ES': 'Entrada e historial',
      'TH': 'บันทึกและประวัติ',
    },
    'summaryReportBody': {
      'KO':
          '[종합 리포트]\n\n자기주도 학습 1교시\n1번 학습일시: 2026-06-18 21:36 ~ 22:36 끝남 UTC\n2. 학습과목: 수학\n3. 학습시간: 72분 / 90분\n4. 목표달성률: 80%\n5. 별 갯수: ****(4/5)\n\n자기주도학습 2교시\n1번 학습일시:\n2026-06-18 21:36 ~ 22:36 끝남 UTC\n2. 학습과목: 영어\n3. 학습시간: 72분 / 90분\n4. 목표달성률: 80%\n5. 별 갯수: ****(4/5)\n\n[종합 진단 피드백]\n금일 진행된 이규현 회원의 학습 세션은 시간 관리와 핵심 문항 분석 면에서 고도의 진취성을 나타냈습니다. 계획된 90분의 집중 타임라인 중 실제 몰입 시간의 밀도가 높았으며, 과목 간 균형도 안정적입니다. 다만 학습 개시 단계에서 개념 정립에 소요되는 시간이 평균치보다 다소 길어지는 지체 현상이 관찰되었습니다. 이는 후반부 응용 문제 풀이의 정밀도를 저해하는 요인이 될 수 있으므로, 초기 몰입 속도를 제고하려는 의도적인 노력이 요구됩니다. 전반적인 과목 이해도는 상위권 진입에 무리가 없는 수준이나, 오답을 선별하고 피드백 리포트를 구성할 때 본인의 주관적 판단에만 의존하는 경향은 확실히 교정해야 할 지점입니다. 현재 유지하고 있는 연속 학습의 패턴은 장기적 성과 도출을 위한 훌륭한 기반이 되므로, 스스로의 역량을 확신하고 정진하기 바랍니다. 미진한 영역을 명확히 보완하여 내일의 학습 효율성을 한층 더 고도화할 수 있도록 냉철하게 관리해 나갈 것을 엄중히 제언합니다.',
      'EN':
          '[Total Report]\n\nSelf-Directed Learning Session 1\n1. TIMESTAMP: 2026-06-18 21:36 ~ 22:36 End UTC\n2. SUBJECT: Math\n3. TIME: 72 Mins / 90 Mins\n4. ACHIEVEMENT RATE: 80%\n5. STARS: ****(4/5)\n\nSelf-Directed Learning Session 2\n1. TIMESTAMP:\n2026-06-18 21:36 ~ 22:36 End UTC\n2. SUBJECT: En\n3. TIME: 72 Mins / 90 Mins\n4. ACHIEVEMENT RATE: 80%\n5. STARS: ****(4/5)\n\nToday\'s learning sessions showed great progress. Keep moving forward toward your target with strong motivation.',
      'JA':
          '[総合レポート]\n\n自己主導学習 第1時限\n1. 学習日時：2026-06-18 21:36〜22:36 終了 UTC\n2. 学習科目：数学\n3. 学習時間：72分／90分\n4. 目標達成率：80%\n5. 星の数：****(4/5)\n\n自己主導学習 第2時限\n1. 学習日時：\n2026-06-18 21:36〜22:36 終了 UTC\n2. 学習科目：英語\n3. 学習時間：72分／90分\n4. 目標達成率：80%\n5. 星の数：****(4/5)\n\n[総合診断フィードバック]\n本日のイ・ギュヒョン会員の学習セッションは時間管理と重要項目の分析において高い積極性を示しました。よく集中して取り組めていますが、概念整理に時間がかかる傾向が見られます。明日はより早く集中に入れるよう意識してみましょう。',
      'ZH':
          '[综合报告]\n\n自主学习 第1节\n1. 学习时间：2026-06-18 21:36～22:36 结束 UTC\n2. 学习科目：数学\n3. 学习时长：72分钟／90分钟\n4. 目标达成率：80%\n5. 星星数量：****(4/5)\n\n自主学习 第2节\n1. 学习时间：\n2026-06-18 21:36～22:36 结束 UTC\n2. 学习科目：英语\n3. 学习时长：72分钟／90分钟\n4. 目标达成率：80%\n5. 星星数量：****(4/5)\n\n[综合诊断反馈]\n今日李圭贤会员的学习表现出较高的时间管理与重点分析能力。整体学习节奏稳定，但在概念梳理阶段耗时略长于平均水平。建议明天从一开始就加快进入专注状态。',
      'FR':
          '[Rapport global]\n\nSession d\'apprentissage autonome 1\n1. HORODATAGE : 2026-06-18 21:36 ~ 22:36 Fin UTC\n2. MATIÈRE : Maths\n3. DURÉE : 72 min / 90 min\n4. TAUX DE RÉUSSITE : 80 %\n5. ÉTOILES : ****(4/5)\n\nSession d\'apprentissage autonome 2\n1. HORODATAGE :\n2026-06-18 21:36 ~ 22:36 Fin UTC\n2. MATIÈRE : Anglais\n3. DURÉE : 72 min / 90 min\n4. TAUX DE RÉUSSITE : 80 %\n5. ÉTOILES : ****(4/5)\n\n[Retour de diagnostic global]\nLa session d\'apprentissage de Lee Gyu-hyun d\'aujourd\'hui a montré une bonne gestion du temps et une analyse solide des points clés. Le rythme reste stable, mais la phase de mise en place des concepts prend un peu plus de temps que la moyenne. Essayez de démarrer plus rapidement demain.',
      'DE':
          '[Gesamtbericht]\n\nSelbstgesteuerte Lerneinheit 1\n1. ZEITSTEMPEL: 2026-06-18 21:36 ~ 22:36 Ende UTC\n2. FACH: Mathe\n3. DAUER: 72 Min / 90 Min\n4. ERFOLGSQUOTE: 80 %\n5. STERNE: ****(4/5)\n\nSelbstgesteuerte Lerneinheit 2\n1. ZEITSTEMPEL:\n2026-06-18 21:36 ~ 22:36 Ende UTC\n2. FACH: Englisch\n3. DAUER: 72 Min / 90 Min\n4. ERFOLGSQUOTE: 80 %\n5. STERNE: ****(4/5)\n\n[Gesamtdiagnose-Feedback]\nDie heutige Lernsitzung von Lee Gyu-hyun zeigte gutes Zeitmanagement und eine solide Analyse der Kernpunkte. Das Tempo bleibt stabil, doch die Konzeptaufbauphase dauert etwas länger als der Durchschnitt. Morgen sollte der Fokus schneller aufgebaut werden.',
      'RU':
          '[Общий отчёт]\n\nСамостоятельное занятие 1\n1. ВРЕМЯ: 2026-06-18 21:36 ~ 22:36 Завершено UTC\n2. ПРЕДМЕТ: Математика\n3. ВРЕМЯ ЗАНЯТИЯ: 72 мин / 90 мин\n4. ДОСТИЖЕНИЕ ЦЕЛИ: 80%\n5. ЗВЁЗДЫ: ****(4/5)\n\nСамостоятельное занятие 2\n1. ВРЕМЯ:\n2026-06-18 21:36 ~ 22:36 Завершено UTC\n2. ПРЕДМЕТ: Английский\n3. ВРЕМЯ ЗАНЯТИЯ: 72 мин / 90 мин\n4. ДОСТИЖЕНИЕ ЦЕЛИ: 80%\n5. ЗВЁЗДЫ: ****(4/5)\n\n[Общая диагностическая обратная связь]\nСегодняшнее занятие ученика Ли Гю Хёна показало хороший тайм-менеджмент и качественный анализ ключевых заданий. Темп остаётся стабильным, но этап усвоения понятий занимает немного больше времени, чем в среднем. Завтра стоит быстрее выходить на нужную концентрацию.',
      'AR':
          '[التقرير الشامل]\n\nجلسة التعلم الذاتي 1\n1. الوقت: 2026-06-18 21:36 ~ 22:36 انتهى UTC\n2. المادة: رياضيات\n3. المدة: 72 دقيقة / 90 دقيقة\n4. نسبة تحقيق الهدف: 80٪\n5. النجوم: ****(4/5)\n\nجلسة التعلم الذاتي 2\n1. الوقت:\n2026-06-18 21:36 ~ 22:36 انتهى UTC\n2. المادة: إنجليزي\n3. المدة: 72 دقيقة / 90 دقيقة\n4. نسبة تحقيق الهدف: 80٪\n5. النجوم: ****(4/5)\n\n[ملاحظات التشخيص الشامل]\nأظهرت جلسة تعلم لي جيو-هيون اليوم إدارة جيدة للوقت وتحليلًا قويًا للنقاط الأساسية. الوتيرة مستقرة، لكن مرحلة بناء المفاهيم استغرقت وقتًا أطول قليلاً من المتوسط. يُنصح بالتركيز بشكل أسرع غدًا.',
      'HI':
          '[समग्र रिपोर्ट]\n\nस्व-निर्देशित शिक्षण सत्र 1\n1. समय: 2026-06-18 21:36 ~ 22:36 समाप्त UTC\n2. विषय: गणित\n3. अवधि: 72 मिनट / 90 मिनट\n4. लक्ष्य प्राप्ति दर: 80%\n5. स्टार: ****(4/5)\n\nस्व-निर्देशित शिक्षण सत्र 2\n1. समय:\n2026-06-18 21:36 ~ 22:36 समाप्त UTC\n2. विषय: अंग्रेज़ी\n3. अवधि: 72 मिनट / 90 मिनट\n4. लक्ष्य प्राप्ति दर: 80%\n5. स्टार: ****(4/5)\n\n[समग्र निदान फ़ीडबैक]\nआज ली ग्यू-ह्युन के अध्ययन सत्र में समय प्रबंधन और मुख्य बिंदुओं का विश्लेषण अच्छा रहा। गति स्थिर है, लेकिन अवधारणा-निर्माण चरण में औसत से थोड़ा अधिक समय लगा। कल जल्दी ध्यान केंद्रित करने का प्रयास करें।',
      'VI':
          '[Báo cáo tổng hợp]\n\nBuổi học tự định hướng 1\n1. THỜI GIAN: 2026-06-18 21:36 ~ 22:36 Kết thúc UTC\n2. MÔN HỌC: Toán\n3. THỜI LƯỢNG: 72 phút / 90 phút\n4. TỶ LỆ ĐẠT MỤC TIÊU: 80%\n5. SỐ SAO: ****(4/5)\n\nBuổi học tự định hướng 2\n1. THỜI GIAN:\n2026-06-18 21:36 ~ 22:36 Kết thúc UTC\n2. MÔN HỌC: Tiếng Anh\n3. THỜI LƯỢNG: 72 phút / 90 phút\n4. TỶ LỆ ĐẠT MỤC TIÊU: 80%\n5. SỐ SAO: ****(4/5)\n\n[Phản hồi chẩn đoán tổng hợp]\nBuổi học hôm nay của Lee Gyu-hyun cho thấy khả năng quản lý thời gian tốt và phân tích trọng điểm chắc chắn. Nhịp độ ổn định, nhưng giai đoạn xây dựng khái niệm mất nhiều thời gian hơn mức trung bình. Ngày mai nên tập trung nhanh hơn ngay từ đầu.',
      'ES':
          '[Informe general]\n\nSesión de aprendizaje autónomo 1\n1. MARCA DE TIEMPO: 2026-06-18 21:36 ~ 22:36 Fin UTC\n2. MATERIA: Matemáticas\n3. DURACIÓN: 72 min / 90 min\n4. TASA DE LOGRO: 80%\n5. ESTRELLAS: ****(4/5)\n\nSesión de aprendizaje autónomo 2\n1. MARCA DE TIEMPO:\n2026-06-18 21:36 ~ 22:36 Fin UTC\n2. MATERIA: Inglés\n3. DURACIÓN: 72 min / 90 min\n4. TASA DE LOGRO: 80%\n5. ESTRELLAS: ****(4/5)\n\n[Retroalimentación de diagnóstico general]\nLa sesión de estudio de hoy de Lee Gyu-hyun mostró buena gestión del tiempo y un análisis sólido de los puntos clave. El ritmo se mantiene estable, aunque la fase de consolidación de conceptos tomó algo más de tiempo que el promedio. Se recomienda concentrarse más rápido desde el inicio de mañana.',
      'TH':
          '[รายงานสรุป]\n\nช่วงเรียนด้วยตนเอง ครั้งที่ 1\n1. เวลา: 2026-06-18 21:36 ~ 22:36 สิ้นสุด UTC\n2. วิชา: คณิตศาสตร์\n3. ระยะเวลา: 72 นาที / 90 นาที\n4. อัตราการบรรลุเป้าหมาย: 80%\n5. จำนวนดาว: ****(4/5)\n\nช่วงเรียนด้วยตนเอง ครั้งที่ 2\n1. เวลา:\n2026-06-18 21:36 ~ 22:36 สิ้นสุด UTC\n2. วิชา: ภาษาอังกฤษ\n3. ระยะเวลา: 72 นาที / 90 นาที\n4. อัตราการบรรลุเป้าหมาย: 80%\n5. จำนวนดาว: ****(4/5)\n\n[ฟีดแบ็กการวินิจฉัยโดยรวม]\nช่วงเรียนของ Lee Gyu-hyun วันนี้แสดงถึงการจัดการเวลาที่ดีและการวิเคราะห์ประเด็นสำคัญที่มั่นคง จังหวะการเรียนคงที่ดี แต่ขั้นตอนปูพื้นแนวคิดใช้เวลานานกว่าค่าเฉลี่ยเล็กน้อย ควรตั้งใจโฟกัสให้เร็วขึ้นตั้งแต่เริ่มพรุ่งนี้',
    },
    'detailedReportBody': {
      'KO':
          '[상세분석기록]\n\n• 상세내용: 개념 및 심화,문제풀이 25문제\n• 오답노타: 정리함\n• 이 해 도: 80%\n• 난 이 도: 보통\n• 집중도: 높음\n• 학습컨디션: 좋음\n• 다음목표: 함수 심화문제\n\n[심층 교육 제언]\n차기 목표로 설정된 함수 심화 파트는 고도의 논리적 추론이 수반되는 영역이나, 현재 이규현 회원이 보여준 오답 정리 정밀도와 개념 분석력이라면 충분히 안정적으로 돌파해 낼 수 있습니다. 장래의 목표를 실현하기 위한 과정에서 마주하는 고난도 문항은 성장의 기회가 될 것입니다. 단, 난이도가 보통인 문항 스펙트럼에서도 실수가 일부 식별된 점은 자만을 경계하고 기초를 더 철저히 해야 한다는 경고입니다. 스스로의 가능성을 믿고 의욕적으로 도전하되 명밀하게 검토하는 태도를 기르십시오.',
      'EN':
          '[Detailed Analytics]\n\n• DETAILS: Concepts & Problems, 25 issues\n• INCORRECT NOTE: COMPLETED\n• UNDERSTANDING: 80%\n• DIFFICULTY: Normal\n• CONCENTRATION: High\n• CONDITION: Good\n• NEXT GOAL: Advanced Function Problems\n\nYour potential is unlimited. Learn from your minor mistakes and focus deeper on the next advanced targets.',
      'JA':
          '[詳細分析記録]\n\n• 詳細内容：概念と応用、25問を解答\n• 誤答ノート：整理済み\n• 理解度：80%\n• 難易度：普通\n• 集中度：高い\n• 学習状態：良好\n• 次の目標：関数の応用問題\n\n[深層教育アドバイス]\n次の目標である関数の応用パートは高度な論理的推論を要しますが、現在の誤答整理の精度と概念分析力があれば十分に突破できます。自信を持って挑戦しつつ、慎重に確認する姿勢を保ちましょう。',
      'ZH':
          '[详细分析记录]\n\n• 详细内容：概念与拓展，共25题\n• 错题笔记：已整理\n• 理解度：80%\n• 难度：普通\n• 专注度：高\n• 学习状态：良好\n• 下一目标：函数拓展题\n\n[深度教育建议]\n下一目标——函数拓展部分需要较强的逻辑推理能力，但凭借目前的错题整理精度和概念分析力，完全可以稳步突破。请保持自信积极挑战，同时养成细致检查的习惯。',
      'FR':
          '[Analyse détaillée]\n\n• DÉTAILS : Concepts et exercices, 25 problèmes\n• NOTE D\'ERREUR : TERMINÉ\n• COMPRÉHENSION : 80 %\n• DIFFICULTÉ : Normale\n• CONCENTRATION : Élevée\n• ÉTAT : Bon\n• PROCHAIN OBJECTIF : Problèmes de fonctions avancés\n\nVotre potentiel est illimité. Apprenez de vos petites erreurs et concentrez-vous davantage sur les prochains objectifs avancés.',
      'DE':
          '[Detaillierte Analyse]\n\n• DETAILS: Konzepte & Übungen, 25 Aufgaben\n• FEHLERNOTIZ: ERLEDIGT\n• VERSTÄNDNIS: 80 %\n• SCHWIERIGKEIT: Normal\n• KONZENTRATION: Hoch\n• ZUSTAND: Gut\n• NÄCHSTES ZIEL: Fortgeschrittene Funktionsaufgaben\n\nIhr Potenzial ist unbegrenzt. Lernen Sie aus kleinen Fehlern und konzentrieren Sie sich stärker auf die nächsten fortgeschrittenen Ziele.',
      'RU':
          '[Подробная аналитика]\n\n• ДЕТАЛИ: Концепции и задачи, 25 заданий\n• ЗАМЕТКА ОБ ОШИБКАХ: ЗАВЕРШЕНО\n• ПОНИМАНИЕ: 80%\n• СЛОЖНОСТЬ: Средняя\n• КОНЦЕНТРАЦИЯ: Высокая\n• СОСТОЯНИЕ: Хорошее\n• СЛЕДУЮЩАЯ ЦЕЛЬ: Продвинутые задачи по функциям\n\nВаш потенциал безграничен. Учитесь на небольших ошибках и глубже сосредоточьтесь на следующих продвинутых целях.',
      'AR':
          '[تحليل تفصيلي]\n\n• التفاصيل: مفاهيم وتطبيقات، 25 مسألة\n• ملاحظة الأخطاء: مكتمل\n• الفهم: 80٪\n• الصعوبة: متوسطة\n• التركيز: مرتفع\n• الحالة: جيدة\n• الهدف التالي: مسائل الدوال المتقدمة\n\nإمكاناتك غير محدودة. تعلّم من أخطائك الصغيرة وركّز بعمق أكبر على الأهداف المتقدمة القادمة.',
      'HI':
          '[विस्तृत विश्लेषण]\n\n• विवरण: अवधारणाएं और अभ्यास, 25 प्रश्न\n• त्रुटि नोट: पूर्ण\n• समझ: 80%\n• कठिनाई: सामान्य\n• एकाग्रता: उच्च\n• स्थिति: अच्छी\n• अगला लक्ष्य: उन्नत फलन प्रश्न\n\nआपकी क्षमता असीम है। छोटी गलतियों से सीखें और आगामी उन्नत लक्ष्यों पर अधिक गहराई से ध्यान दें।',
      'VI':
          '[Phân tích chi tiết]\n\n• CHI TIẾT: Khái niệm và bài tập, 25 câu\n• GHI CHÚ LỖI: ĐÃ HOÀN THÀNH\n• MỨC HIỂU: 80%\n• ĐỘ KHÓ: Trung bình\n• TẬP TRUNG: Cao\n• TRẠNG THÁI: Tốt\n• MỤC TIÊU TIẾP THEO: Bài tập hàm số nâng cao\n\nTiềm năng của bạn là vô hạn. Hãy học từ những lỗi nhỏ và tập trung sâu hơn vào các mục tiêu nâng cao tiếp theo.',
      'ES':
          '[Análisis detallado]\n\n• DETALLES: Conceptos y ejercicios, 25 problemas\n• NOTA DE ERRORES: COMPLETADO\n• COMPRENSIÓN: 80%\n• DIFICULTAD: Normal\n• CONCENTRACIÓN: Alta\n• CONDICIÓN: Buena\n• PRÓXIMO OBJETIVO: Problemas avanzados de funciones\n\nTu potencial es ilimitado. Aprende de tus pequeños errores y concéntrate más en los próximos objetivos avanzados.',
      'TH':
          '[บันทึกวิเคราะห์เชิงลึก]\n\n• รายละเอียด: แนวคิดและโจทย์เชิงลึก 25 ข้อ\n• บันทึกข้อผิดพลาด: เรียบร้อยแล้ว\n• ความเข้าใจ: 80%\n• ความยาก: ปานกลาง\n• สมาธิ: สูง\n• สภาพการเรียน: ดี\n• เป้าหมายถัดไป: โจทย์ฟังก์ชันขั้นสูง\n\nศักยภาพของคุณไม่มีขีดจำกัด เรียนรู้จากข้อผิดพลาดเล็กๆ และตั้งใจกับเป้าหมายขั้นสูงถัดไปให้มากขึ้น',
    },
  };

  static String _t(String key) {
    final map = _uiText[key];
    if (map == null) return key;
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? key;
  }

  // 🆕 [데이터 연결-버그 수정] 그래프 함수(_buildAdvancedChartDashboard)는 이 getter가
  // 반환하는 "데이터 소스"를 실제 기록 기반으로 사용합니다.
  // 🆕 [위험한 오류 수정 2026-09-06] 예전엔 baseMinutes(하루 평균) × 기간별 배수로
  // 주/월/연을 "추정"했으나, 실제와 크게 어긋날 수 있어 폐기하고 weekRealMinutes/
  // monthRealMinutes/yearRealMinutes(그 기간 실제 합산 분)를 그대로 사용하도록 변경함.
  List<Map<String, dynamic>> get _masterSubjectData => _realSubjectStudyData;

  // 🆕 [데이터 연결] timer_screen.dart가 세션마다 저장하는 'dke_history_{과목명}' 실제 기록을
  // 모든 과목에 대해 훑어서(SharedPreferences.getKeys() 사용, 과목명을 미리 알 필요 없음) 집계합니다.
  // - hasStudiedToday/Weekly/Monthly/Yearly: 실제 그 기간에 학습한 적이 있는지 여부(정확함)
  // - todayRealMinutes/weekRealMinutes/monthRealMinutes/yearRealMinutes: 각 기간 안에 실제로
  //   쌓인 학습 분(分)을 그대로 합산한 값. (baseMinutes는 참고용으로 남겨두었으나 그래프 계산에는
  //   더 이상 사용하지 않음 — 추정이 아닌 실제 합산치만 사용)
  Future<void> _loadRealSubjectStudyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Set<String> allKeys = prefs.getKeys();
      final Iterable<String> historyKeys = allKeys.where(
        (k) => k.startsWith('dke_history_'),
      );

      final DateTime now = DateTime.now();
      final DateTime todayStart = DateTime(now.year, now.month, now.day);
      final DateTime yesterdayStart = todayStart.subtract(
        const Duration(days: 1),
      );
      final DateTime weekStart = todayStart.subtract(
        Duration(days: now.weekday % 7), // 🆕 [2026-09-30] 앱 원칙: 일~토
      );
      final DateTime monthStart = DateTime(now.year, now.month, 1);
      final DateTime yearStart = DateTime(now.year, 1, 1);

      final List<Map<String, dynamic>> aggregated = [];
      int grandTotalMinutes = 0;
      String? topSubjectName;
      int topSubjectMinutes = -1;
      // 🆕 [데이터 연결] "어제 대비 오늘"/"목표 달성도" 계산용 - 모든 과목 합산 오늘/어제 학습분
      int todayTotalMinutes = 0;
      int yesterdayTotalMinutes = 0;
      // 🆕 [데이터 연결] "가장 성장한 과목" - 과목별로 오늘-어제 학습분 차이가 가장 큰 과목(양수만 인정)
      String? mostImprovedSubjectName;
      int bestGrowthMinutes = 0;

      for (final key in historyKeys) {
        final String subjectName = key.substring('dke_history_'.length);
        final List<String>? entries = prefs.getStringList(key);
        if (entries == null || entries.isEmpty) continue;

        bool studiedToday = false,
            studiedWeekly = false,
            studiedMonthly = false,
            studiedYearly = false;
        int totalMinutesAllTime = 0;
        int subjectTodayMinutes = 0; // 🆕 이 과목의 오늘 학습분
        int subjectYesterdayMinutes = 0; // 🆕 이 과목의 어제 학습분
        // 🆕 [위험한 오류 수정 2026-09-06] 주/월/연 그래프가 "하루 평균 × 가정 일수"로
        // 추정(extrapolation)하던 방식은 실제와 크게 어긋날 수 있어서 폐기함.
        // 대신 실제 기간(이번 주/이번 달/올해) 안에 쌓인 분(分)을 직접 그대로 합산함.
        int subjectWeekMinutes = 0;
        int subjectMonthMinutes = 0;
        int subjectYearMinutes = 0;
        final Set<String> activeDayKeys = {};
        double latestScoreRatio = 0.0;
        DateTime? latestTimestamp;

        for (final raw in entries) {
          try {
            final Map<String, dynamic> item = jsonDecode(raw);
            final DateTime ts =
                DateTime.tryParse(
                  item['timestamp']?.toString() ?? '',
                )?.toLocal() ??
                now;
            final int durationSeconds =
                (item['durationSeconds'] as num?)?.toInt() ?? 0;
            final int minutes = (durationSeconds / 60).round();

            // 🆕 [위험한 오류 수정 2026-09-06] 각 기간에 해당하면 "그 기간에 공부했는지" 여부뿐 아니라
            // 실제 학습 분(分)도 함께 그대로 합산함(각 조건은 서로 독립적 — 한 기록이 여러 기간에
            // 동시에 포함될 수 있음, 예: 오늘 기록은 주/월/연 합계에도 모두 포함됨).
            if (!ts.isBefore(yearStart)) {
              studiedYearly = true;
              subjectYearMinutes += minutes;
            }
            if (!ts.isBefore(monthStart)) {
              studiedMonthly = true;
              subjectMonthMinutes += minutes;
            }
            if (!ts.isBefore(weekStart)) {
              studiedWeekly = true;
              subjectWeekMinutes += minutes;
            }
            if (!ts.isBefore(todayStart)) studiedToday = true;

            totalMinutesAllTime += minutes;
            activeDayKeys.add("${ts.year}-${ts.month}-${ts.day}");

            if (!ts.isBefore(todayStart)) {
              todayTotalMinutes += minutes;
              subjectTodayMinutes += minutes; // 🆕
            } else if (!ts.isBefore(yesterdayStart)) {
              yesterdayTotalMinutes += minutes;
              subjectYesterdayMinutes += minutes; // 🆕
            }

            if (latestTimestamp == null || ts.isAfter(latestTimestamp)) {
              latestTimestamp = ts;
              final int score = (item['score'] as num?)?.toInt() ?? 0;
              latestScoreRatio = score.clamp(0, 100) / 100.0;
            }
          } catch (_) {
            // 개별 기록 하나가 손상되어 있어도 나머지 집계에는 영향 없게 건너뜀
          }
        }

        if (!(studiedToday || studiedWeekly || studiedMonthly || studiedYearly))
          continue;

        grandTotalMinutes += totalMinutesAllTime;
        if (totalMinutesAllTime > topSubjectMinutes) {
          topSubjectMinutes = totalMinutesAllTime;
          topSubjectName = subjectName;
        }

        // 🆕 [데이터 연결] 이 과목의 성장폭(오늘-어제)이 지금까지 중 가장 크면(양수일 때만) 갱신
        final int subjectGrowth = subjectTodayMinutes - subjectYesterdayMinutes;
        if (subjectGrowth > bestGrowthMinutes) {
          bestGrowthMinutes = subjectGrowth;
          mostImprovedSubjectName = subjectName;
        }

        final int activeDays = activeDayKeys.isEmpty ? 1 : activeDayKeys.length;
        final int avgMinutesPerActiveDay = (totalMinutesAllTime / activeDays)
            .round();

        aggregated.add({
          "subject": subjectName,
          "score": latestScoreRatio,
          // 🆕 "전체 평균" 비교 막대는 다른 학생들 데이터가 있어야 계산 가능(서버 필요)합니다.
          // 서버가 없는 지금은 본인 점수와 동일하게 두어 회색 막대가 왜곡된 가짜 숫자를 보여주지 않게 했습니다.
          "averageScore": latestScoreRatio,
          "hasStudiedToday": studiedToday,
          "hasStudiedWeekly": studiedWeekly,
          "hasStudiedMonthly": studiedMonthly,
          "hasStudiedYearly": studiedYearly,
          "baseMinutes": avgMinutesPerActiveDay,
          // 🆕 [위험한 오류 수정 2026-09-06] 주/월/연 그래프가 실제로 사용할 "그 기간에 실제
          // 쌓인 분(分)" — 더 이상 baseMinutes에 임의의 배수를 곱해 추정하지 않음.
          "todayRealMinutes": subjectTodayMinutes,
          "weekRealMinutes": subjectWeekMinutes,
          "monthRealMinutes": subjectMonthMinutes,
          "yearRealMinutes": subjectYearMinutes,
          "isStarEligible": true,
        });
      }

      if (!mounted) return;
      setState(() {
        _realSubjectStudyData = aggregated;
        _realTotalMinutesCache = grandTotalMinutes;
        _realMostStudiedSubjectCache = topSubjectName;
        _todayTotalStudyMinutes = todayTotalMinutes;
        _yesterdayTotalStudyMinutes = yesterdayTotalMinutes;
        _realMostImprovedSubjectCache = mostImprovedSubjectName; // 🆕
      });
      // 🆕 [랭킹 2026-10-01] 이번 달 공부 시간을 올리고 친구·전 세계 순위를 받아 옴
      _loadRanking(aggregated.fold<int>(0, (sum, e) => sum + (e['monthRealMinutes'] as int)));
    } catch (e) {
      debugPrint("[MemberAchievement] 실제 학습시간 데이터 집계 실패: $e");
    }
  }

  // 🆕 [데이터 연결] 전체 실제 누적 학습시간(모든 과목 합산, 전체 기간) - "총 학습시간" 표시용
  int get _realTotalStudyMinutesAllTime {
    // dke_history_* 최초 로딩 시점에 이미 activeDayKeys 기반 평균으로 집계했기 때문에,
    // 여기서는 별도로 다시 합산하지 않고 로딩 시 함께 채워둔 값을 사용합니다.
    return _realTotalMinutesCache;
  }

  int _realTotalMinutesCache = 0;

  // 🆕 [데이터 연결] "일일 전체 학습시간" 가로스크롤 그래프용 - 기록 있는 날짜만, 최대 15일치
  List<Map<String, dynamic>> _dailyTotalHistory = [];
  final ScrollController _dailyTotalScrollController = ScrollController();

  // 🆕 [요청 2026-09-04] 주평가 "월 선택" 가로 스크롤을 현재 월 위치로 자동 이동시키기 위한 컨트롤러.
  final ScrollController _monthScrollController = ScrollController();
  bool _monthRowAutoScrolled = false; // 한 번만 자동 스크롤하고, 이후 사용자가 직접 스크롤한 위치는 존중함

  // 🆕 [데이터 연결] "어제 대비 오늘" / "목표 달성도" 계산용 실제 오늘·어제 학습분(모든 과목 합산)
  int _todayTotalStudyMinutes = 0;
  int _yesterdayTotalStudyMinutes = 0;

  // 🆕 [요청] 고정 200분 목표는 개인차(예: 영어만 집중 4시간10분=250분)를 반영 못 해서 폐기.
  // 대신 오늘 실제 학습분을 기준으로 50분 단위로 자동 상승하는 목표(100→150→200→250→300...)를 사용.
  // 100분 밑으로는 목표를 낮추지 않고 항상 최소 100분을 기준으로 함(100분 밑은 "가위질"과 동일한 취급).
  int get _dynamicDailyGoalMinutes {
    if (_todayTotalStudyMinutes < 100) return 100;
    return (_todayTotalStudyMinutes / 50.0).ceil() * 50;
  }

  // 🆕 목표 달성도(%) = 오늘 학습분 / 유동 목표(_dynamicDailyGoalMinutes) × 100. 100%를 넘으면 100으로 고정.
  int get _realGoalAttainmentPercent {
    final int pct = ((_todayTotalStudyMinutes / _dynamicDailyGoalMinutes) * 100)
        .round();
    return pct.clamp(0, 100);
  }

  // 🆕 어제 대비 오늘 증감(%) = (오늘 - 어제) / 어제 × 100. 어제 기록이 없으면(0분) 오늘 학습한 만큼 +100%로 표시.
  int get _realTodayVsYesterdayPercent {
    if (_yesterdayTotalStudyMinutes <= 0) {
      return _todayTotalStudyMinutes > 0 ? 100 : 0;
    }
    return (((_todayTotalStudyMinutes - _yesterdayTotalStudyMinutes) /
                _yesterdayTotalStudyMinutes) *
            100)
        .round();
  }
  // ============================================================================
  // 🆕 [랭킹 2026-10-01] "1위" 고정 글자를 없애고 진짜 순위로.
  // 기준: 이번 달 공부 시간. 친구 = 같은 학교·같은 학년. 이름은 절대 안 보이고 내 순위만 보임.
  // 학생이 혼자면 "1위 (1명 중)", 학생이 늘어나면 순위가 저절로 바뀜.
  // ============================================================================
  RankResult? _friendRank;
  RankResult? _globalRank;
  bool _rankLoaded = false;
  bool _hasSchoolGrade = false;

  static const Map<String, Map<String, String>> _kRankText = {
    'loading': {'KO': '집계 중…', 'EN': 'Calculating…', 'JA': '集計中…', 'ZH': '统计中…', 'FR': 'Calcul…', 'DE': 'Wird berechnet…', 'RU': 'Подсчёт…', 'AR': 'جارٍ الحساب…', 'HI': 'गणना हो रही है…', 'VI': 'Đang tính…', 'ES': 'Calculando…', 'TH': 'กำลังคำนวณ…'},
    'needSchool': {'KO': '마이페이지에 학교·학년을 넣으면 보여요', 'EN': 'Add school & grade in My Page', 'JA': 'マイページで学校・学年を入力すると表示', 'ZH': '在我的页面填写学校和年级后显示', 'FR': "Ajoutez école et niveau dans Mon profil", 'DE': 'Schule & Klasse in Mein Profil eintragen', 'RU': 'Укажите школу и класс в профиле', 'AR': 'أضف المدرسة والصف في صفحتي', 'HI': 'मेरे पेज में स्कूल व कक्षा जोड़ें', 'VI': 'Nhập trường & lớp ở Trang của tôi', 'ES': 'Añade escuela y curso en Mi página', 'TH': 'ใส่โรงเรียนและชั้นในหน้าของฉัน'},
    'friend': {'KO': '{r}위 ({t}명 중)', 'EN': '#{r} of {t}', 'JA': '{r}位（{t}人中）', 'ZH': '第{r}名（共{t}人）', 'FR': '{r}e sur {t}', 'DE': 'Platz {r} von {t}', 'RU': '{r}-е из {t}', 'AR': 'المركز {r} من {t}', 'HI': '{t} में से {r}वां', 'VI': 'Hạng {r}/{t}', 'ES': '{r}.º de {t}', 'TH': 'อันดับ {r} จาก {t}'},
    'global': {'KO': '{r}위 · 상위 {p}%', 'EN': '#{r} · Top {p}%', 'JA': '{r}位 · 上位{p}%', 'ZH': '第{r}名 · 前{p}%', 'FR': '{r}e · Top {p} %', 'DE': 'Platz {r} · Top {p} %', 'RU': '{r}-е · Топ {p}%', 'AR': 'المركز {r} · الأعلى {p}٪', 'HI': '{r}वां · शीर्ष {p}%', 'VI': 'Hạng {r} · Top {p}%', 'ES': '{r}.º · Top {p}%', 'TH': 'อันดับ {r} · ท็อป {p}%'},
    'globalOnly': {'KO': '{r}위 ({t}명 중)', 'EN': '#{r} of {t}', 'JA': '{r}位（{t}人中）', 'ZH': '第{r}名（共{t}人）', 'FR': '{r}e sur {t}', 'DE': 'Platz {r} von {t}', 'RU': '{r}-е из {t}', 'AR': 'المركز {r} من {t}', 'HI': '{t} में से {r}वां', 'VI': 'Hạng {r}/{t}', 'ES': '{r}.º de {t}', 'TH': 'อันดับ {r} จาก {t}'},
  };

  static String _rankText(String key, {int r = 0, int t = 0, int p = 0}) {
    final Map<String, String> m = _kRankText[key]!;
    return (m[DkeLang.current] ?? m['EN']!)
        .replaceAll('{r}', '$r')
        .replaceAll('{t}', '$t')
        .replaceAll('{p}', '$p');
  }

  Future<void> _loadRanking(int monthMinutes) async {
    final result = await RankingService.updateAndFetch(monthMinutes);
    if (!mounted) return;
    setState(() {
      _friendRank = result.friend;
      _globalRank = result.global;
      _hasSchoolGrade = result.hasGroup;
      _rankLoaded = true;
    });
  }

  String get _realFriendRankDisplay {
    if (!_rankLoaded) return _rankText('loading');
    if (!_hasSchoolGrade) return _rankText('needSchool');
    final RankResult? f = _friendRank;
    if (f == null) return '-';
    return _rankText('friend', r: f.rank, t: f.total);
  }

  String get _realGlobalRankDisplay {
    if (!_rankLoaded) return _rankText('loading');
    final RankResult? g = _globalRank;
    if (g == null) return '-';
    // 10명 미만일 때는 "상위 %"가 어색하므로 "몇 명 중 몇 위"로
    if (g.total < 10) return _rankText('globalOnly', r: g.rank, t: g.total);
    return _rankText('global', r: g.rank, p: g.topPercent);
  }

  String? get _realMostStudiedSubject => _realMostStudiedSubjectCache;
  String? _realMostStudiedSubjectCache;

  // 🆕 [데이터 연결] 가장 성장한 과목(오늘-어제 학습분 증가폭이 가장 큰 과목, 양수만 인정)
  String? get _realMostImprovedSubject => _realMostImprovedSubjectCache;
  String? _realMostImprovedSubjectCache;

  // 🆕 [데이터 연결] "일일 전체 학습시간" 그래프용 - 모든 과목의 dke_history_* 기록을 날짜별로 묶어서
  // (기록이 있는 날짜만) 최근 15일치를 오래된 날짜→최신 날짜 순으로 정리. 오늘이 항상 맨 오른쪽에 오도록
  // 위젯 쪽에서 스크롤을 맨 끝(오늘)으로 자동 이동시킴.
  Future<void> _loadDailyTotalHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Set<String> allKeys = prefs.getKeys();
      final Iterable<String> historyKeys = allKeys.where(
        (k) => k.startsWith('dke_history_'),
      );

      final Map<String, int> minutesByDay = {};
      final Map<String, DateTime> dateByDayKey = {};

      for (final key in historyKeys) {
        final List<String>? entries = prefs.getStringList(key);
        if (entries == null) continue;
        for (final raw in entries) {
          try {
            final Map<String, dynamic> item = jsonDecode(raw);
            final DateTime ts =
                DateTime.tryParse(
                  item['timestamp']?.toString() ?? '',
                )?.toLocal() ??
                DateTime.now();
            final int durationSeconds =
                (item['durationSeconds'] as num?)?.toInt() ?? 0;
            final int minutes = (durationSeconds / 60).round();
            final String dayKey = "${ts.year}-${ts.month}-${ts.day}";
            minutesByDay[dayKey] = (minutesByDay[dayKey] ?? 0) + minutes;
            dateByDayKey[dayKey] = DateTime(ts.year, ts.month, ts.day);
          } catch (_) {
            // 손상된 기록 하나는 건너뛰고 나머지는 계속 집계
          }
        }
      }

      final List<Map<String, dynamic>> list = minutesByDay.entries
          .where((e) => e.value > 0) // 🆕 기록이 없는(0분) 날은 건너뜀
          .map((e) => {"date": dateByDayKey[e.key]!, "totalMinutes": e.value})
          .toList();

      list.sort(
        (a, b) => (a["date"] as DateTime).compareTo(b["date"] as DateTime),
      );

      // 최근(=날짜가 가장 늦은) 15개까지만 유지 - 오늘이 마지막(맨 오른쪽) 항목이 됨
      final List<Map<String, dynamic>> last15 = list.length > 15
          ? list.sublist(list.length - 15)
          : list;

      if (!mounted) return;
      setState(() {
        _dailyTotalHistory = last15;
      });

      // 🆕 오늘 날짜가 항상 화면 맨 오른쪽에 보이도록, 로딩 후 스크롤을 맨 끝으로 자동 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_dailyTotalScrollController.hasClients) {
          _dailyTotalScrollController.jumpTo(
            _dailyTotalScrollController.position.maxScrollExtent,
          );
        }
      });
    } catch (e) {
      debugPrint("[MemberAchievement] 일일 전체 학습시간 집계 실패: $e");
    }
  }

  String _timerSubject = "";
  String _timerDetails = "";
  int _timerScore = 100;
  String _timerIncorrect = "";
  int _timerDurationMinutes = 0;

  String? _selectedExamType = "주평가";
  bool _isScoreSectionExpanded = true; // 🆕 [요청] "나의 성적 기록 직접 작성" 섹션 접기/펴기 상태
  List<_ExamRecord> _allRecords = [];

  // 🆕 [데이터 연결] 성적 기록을 불러오는 동안 잠깐 빈 화면이 보이지 않도록 하는 로딩 플래그
  bool _isRecordsLoading = true;

  // 🆕 [데이터 연결] 마이페이지에서 실제로 저장한 목표 대학을 그대로 반영 (기존엔 '서울대학교' 고정값이었음)
  String? _realTargetUniversity;

  // 🆕 [데이터 연결] 마이페이지에서 실제로 저장한 목표 대학을 그대로 반영 (기존엔 '서울대학교' 고정값이었음)
  String? _realUserName;

  // 🆕 [요청 2026-09-04] 회원가입 시 입력한 실제 학교명/학년. "GKE 고등학교 2학년" 고정 문구 대체용.
  String? _realSchoolName;
  String? _realGrade;

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _scoreController = TextEditingController();

  int _inputGrade = 2;
  int _inputSemester = 1;

  String _filterExamType = "주평가";
  int _filterGrade = 2;
  int _filterSemester = 1;

  // 🆕 [버그 수정] 예전엔 "2026년/6월/1주차"로 고정되어 있었음 -> 지금 실제 날짜 기준으로 자동 계산
  // 🆕 [버그 재수정] 예전엔 "(day-1)~/7 +1" 방식이라 실제 달력 주차(일요일 시작)와 안 맞았음(7/27이 4주차로 잘못 나옴).
  // 일요일을 한 주의 시작으로 보고, 그 달의 1일이 포함된 주를 1주차로 계산 -> 7/27이 정확히 5주차로 나옴.
  static String _computeCurrentWeekOfMonth() {
    final DateTime now = DateTime.now();
    final DateTime firstOfMonth = DateTime(now.year, now.month, 1);
    final int sundayIndex = firstOfMonth.weekday % 7; // 0=일, 1=월, ... 6=토
    final int weekNum = ((now.day - 1 + sundayIndex) ~/ 7) + 1;
    return "$weekNum주차";
  }

  String _inputYear = "${DateTime.now().year}년";
  String _inputMonth = "${DateTime.now().month}월";
  String _inputWeek = _computeCurrentWeekOfMonth();
  Set<String> _inputBigUnits = {
    "대단원 1",
  }; // 🆕 [요청] 대단원도 중단원과 동일하게 다중선택(범위) 가능하도록 전환
  Set<String> _inputMidUnits = {
    "중단원 1",
  }; // 🆕 [버그 수정] 중단원 여러 개(범위) 선택 가능하도록 단일값→집합으로 전환
  String _inputSemesterGroup = "1학기";

  _ExamRecord? _lastSavedRecordForDisplay;

  // 🆕 [6번] 서버(클라우드) 저장소 재조회 스로틀링용 마지막 동기화 시각
  // 🆕 [6번] 서버(클라우드) 저장소 재조회 스로틀링용 마지막 동기화 시각
  DateTime? _lastRemoteSyncAt;
  static const Duration _remoteSyncInterval = Duration(hours: 1);

  // ============================================================================
  // 🆕 [장학금 방 2026-09-17] "실시간 학습 현황" / "나의 성취별 현황" 카드용 상태값.
  // 이 화면이 이미 로드해둔 데이터(_totalStars, _currentLevelNumber,
  // _todayTotalStudyMinutes 등)는 그대로 재사용하고, 여기서는 scholarship_service.dart가
  // 별도로 관리하는 "월간 기본별/보너스별" 데이터만 새로 불러옵니다.
  // ============================================================================
  int _scholarshipMonthlyBaseStars = 0;
  int _scholarshipMonthlyBonusStars = 0;
  Map<String, int> _scholarshipBonusBreakdown = {};
  bool _isScholarshipDataLoading = true;
  bool _isLiveStatusCardExpanded = true; // 기본값: 펼쳐진 상태로 시작
  bool _isAchievementStarsCardExpanded = false;
  int _currentBottomTab = 0; // 🆕 [장학금 방 UI 개편 2026-09-17] 0=실시간 학습성취, 1=실시간 성취별
  String? _abandonedCodeForPopup; // 🆕 [방치 코드 정리 2026-09-18] 팝업으로 안내할 방치된 예전 코드
  String? _myLinkCode; // 🆕 [실시간 장학금 금액] 부모님의 유형 선택을 실시간 구독하기 위한 내 연결 코드

  // 🆕 [장학금 방] 보너스별 항목 코드 → 한글 라벨 + 지급 별 개수 (안내문과 반드시 일치)
  // 🆕 [장학금 방 다국어 2026-09-18] 보너스 항목 라벨 12개국어
  static const Map<String, Map<String, String>> _bonusTypeLabelMap = {
    'timer70': {
      'KO': '타이머 70% 이상 완주',
      'EN': 'Timer 70%+ Complete',
      'JA': 'タイマー70%以上完走',
      'ZH': '计时器完成70%以上',
      'FR': 'Minuteur 70%+ terminé',
      'DE': 'Timer 70%+ abgeschlossen',
      'RU': 'Таймер завершён на 70%+',
      'AR': 'إكمال المؤقت 70%+',
      'HI': 'टाइमर 70%+ पूर्ण',
      'VI': 'Hoàn thành hẹn giờ 70%+',
      'ES': 'Temporizador 70%+ completo',
      'TH': 'จับเวลาครบ 70%+',
    },
    'recordwrite': {
      'KO': '학습기록 작성',
      'EN': 'Study Record Written',
      'JA': '学習記録作成',
      'ZH': '撰写学习记录',
      'FR': "Fiche d'étude rédigée",
      'DE': 'Lernprotokoll erstellt',
      'RU': 'Запись обучения создана',
      'AR': 'كتابة سجل الدراسة',
      'HI': 'अध्ययन रिकॉर्ड लिखा गया',
      'VI': 'Đã ghi chép học tập',
      'ES': 'Registro de estudio escrito',
      'TH': 'บันทึกการเรียนแล้ว',
    },
    'weekly': {
      'KO': '주간평가 기록',
      'EN': 'Weekly Assessment Logged',
      'JA': '週間評価記録',
      'ZH': '周评估记录',
      'FR': 'Éval. hebdo enregistrée',
      'DE': 'Wochentest erfasst',
      'RU': 'Недельная оценка записана',
      'AR': 'تسجيل التقييم الأسبوعي',
      'HI': 'साप्ताहिक मूल्यांकन दर्ज',
      'VI': 'Đã ghi đánh giá tuần',
      'ES': 'Evaluación semanal registrada',
      'TH': 'บันทึกประเมินรายสัปดาห์',
    },
    'unittest': {
      'KO': '단원평가 기록',
      'EN': 'Unit Test Logged',
      'JA': '単元テスト記録',
      'ZH': '单元测验记录',
      'FR': "Contrôle d'unité enregistré",
      'DE': 'Einheitstest erfasst',
      'RU': 'Тест по разделу записан',
      'AR': 'تسجيل اختبار الوحدة',
      'HI': 'इकाई परीक्षण दर्ज',
      'VI': 'Đã ghi kiểm tra bài',
      'ES': 'Examen de unidad registrado',
      'TH': 'บันทึกทดสอบบทแล้ว',
    },
    'midterm': {
      'KO': '중간고사 기록',
      'EN': 'Midterm Logged',
      'JA': '中間試験記録',
      'ZH': '期中考试记录',
      'FR': 'Examen partiel enregistré',
      'DE': 'Zwischenprüfung erfasst',
      'RU': 'Промежуточный экзамен записан',
      'AR': 'تسجيل اختبار منتصف الفصل',
      'HI': 'मध्यावधि परीक्षा दर्ज',
      'VI': 'Đã ghi thi giữa kỳ',
      'ES': 'Examen parcial registrado',
      'TH': 'บันทึกสอบกลางภาคแล้ว',
    },
    'final': {
      'KO': '기말고사 기록',
      'EN': 'Final Exam Logged',
      'JA': '期末試験記録',
      'ZH': '期末考试记录',
      'FR': 'Examen final enregistré',
      'DE': 'Abschlussprüfung erfasst',
      'RU': 'Итоговый экзамен записан',
      'AR': 'تسجيل الاختبار النهائي',
      'HI': 'अंतिम परीक्षा दर्ज',
      'VI': 'Đã ghi thi cuối kỳ',
      'ES': 'Examen final registrado',
      'TH': 'บันทึกสอบปลายภาคแล้ว',
    },
    'mock': {
      'KO': '모의고사 기록',
      'EN': 'Mock Exam Logged',
      'JA': '模試記録',
      'ZH': '模拟考试记录',
      'FR': 'Examen blanc enregistré',
      'DE': 'Probeprüfung erfasst',
      'RU': 'Пробный экзамен записан',
      'AR': 'تسجيل الاختبار التجريبي',
      'HI': 'मॉक परीक्षा दर्ज',
      'VI': 'Đã ghi thi thử',
      'ES': 'Examen simulacro registrado',
      'TH': 'บันทึกสอบจำลองแล้ว',
    },
    'dailyattend': {
      'KO': '일일 출석 보너스',
      'EN': 'Daily Attendance Bonus',
      'JA': '日次出席ボーナス',
      'ZH': '每日出勤奖励',
      'FR': 'Bonus de présence quotidien',
      'DE': 'Täglicher Anwesenheitsbonus',
      'RU': 'Ежедневный бонус посещаемости',
      'AR': 'مكافأة الحضور اليومي',
      'HI': 'दैनिक उपस्थिति बोनस',
      'VI': 'Thưởng chuyên cần ngày',
      'ES': 'Bono de asistencia diaria',
      'TH': 'โบนัสการเข้าเรียนรายวัน',
    },
    'weeklyattend': {
      'KO': '주간 개근 보너스',
      'EN': 'Weekly Perfect Attendance',
      'JA': '週間皆勤ボーナス',
      'ZH': '每周全勤奖励',
      'FR': 'Bonus de présence parfaite hebdo',
      'DE': 'Wöchentlicher Vollanwesenheitsbonus',
      'RU': 'Недельный бонус за посещаемость',
      'AR': 'مكافأة الحضور الأسبوعي الكامل',
      'HI': 'साप्ताहिक पूर्ण उपस्थिति बोनस',
      'VI': 'Thưởng chuyên cần tuần',
      'ES': 'Bono de asistencia perfecta semanal',
      'TH': 'โบนัสขยันเรียนรายสัปดาห์',
    },
    'monthlyattend': {
      'KO': '월간 개근 보너스',
      'EN': 'Monthly Perfect Attendance',
      'JA': '月間皆勤ボーナス',
      'ZH': '每月全勤奖励',
      'FR': 'Bonus de présence parfaite mensuel',
      'DE': 'Monatlicher Vollanwesenheitsbonus',
      'RU': 'Месячный бонус за посещаемость',
      'AR': 'مكافأة الحضور الشهري الكامل',
      'HI': 'मासिक पूर्ण उपस्थिति बोनस',
      'VI': 'Thưởng chuyên cần tháng',
      'ES': 'Bono de asistencia perfecta mensual',
      'TH': 'โบนัสขยันเรียนรายเดือน',
    },
  };

  static String _bonusLabel(String key) {
    final m = _bonusTypeLabelMap[key];
    if (m == null) return key;
    return m[DkeLang.current] ?? m['EN'] ?? m['KO'] ?? key;
  }

  static const Map<String, Color> _bonusTypeColorMap = {
    'timer70': Color(0xFFFF9500),
    'recordwrite': Color(0xFF34C759),
    'weekly': Color(0xFF60A5FA),
    'unittest': Color(0xFFAF52DE),
    'midterm': Color(0xFFFF3B30),
    'final': Color(0xFFFFCC00),
    'mock': Color(0xFF5856D6),
    'dailyattend': Color(0xFF00C7BE),
    'weeklyattend': Color(0xFFFF2D55),
    'monthlyattend': Color(0xFFFFD700),
  };

  static const Map<String, int> _bonusTypeStarAmount = {
    'timer70': ScholarshipService.bonusTimer70Completion,
    'recordwrite': ScholarshipService.bonusRecordWrite,
    'weekly': ScholarshipService.bonusWeeklyAssessment,
    'unittest': ScholarshipService.bonusUnitTest,
    'midterm': ScholarshipService.bonusMidterm,
    'final': ScholarshipService.bonusFinalExam,
    'mock': ScholarshipService.bonusMockExam,
    'dailyattend': ScholarshipService.bonusDailyAttendance,
    'weeklyattend': ScholarshipService.bonusWeeklyAttendance,
    'monthlyattend': ScholarshipService.bonusMonthlyAttendance,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _warningAnimController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _warningAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _warningAnimController, curve: Curves.easeInOut),
    );

    _syncTimerSharedDataPackets();
    _loadExamRecords(); // 🆕 [데이터 연결] 가상 데이터 대신 실제 저장된 성적 기록을 불러옴
    _loadRealTargetUniversity(); // 🆕 [데이터 연결] 마이페이지에서 저장한 실제 목표 대학 불러옴
    _loadStarsAndLevel(); // 🆕 [데이터 연결] 가상 레벨/별 대신 star_economy.dart의 실제 누적치를 불러옴
    _loadRealSubjectStudyData(); // 🆕 [데이터 연결] 가상 8과목 그래프 대신 실제 학습기록을 집계해서 불러옴
    _loadDailyTotalHistory(); // 🆕 [데이터 연결] 일일 전체 학습시간(가로스크롤) 그래프용 데이터 로드
    _loadRealUserName(); // 🆕 [데이터 연결 2026-07-29] 실제 가입자 이름 불러옴
    _loadRealSchoolGrade(); // 🆕 [요청 2026-09-04] 실제 학교명/학년 불러옴
    _loadSessionsForDate(
      _selectedSessionDate,
    ); // 🆕 [요청 2026-09-04] 선택 날짜(기본값 오늘) 학습 세션 불러옴
    _loadScholarshipSummary(); // 🆕 [장학금 방 2026-09-17] "나의 성취별 현황" 카드용 월간 별 데이터 로드
    _checkAbandonedCode(); // 🆕 [방치 코드 정리 2026-09-18] 5주 이상 방치된 예전 코드가 있는지 확인
    // 🆕 [요청 2026-09-04] 첫 프레임이 렌더링된 직후, "주평가" 월 선택 가로 스크롤을 현재 월 위치로 이동.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollMonthRowToCurrent(),
    );
  }

  // 🆕 [요청 2026-09-04] "월 선택" 가로 스크롤 목록이 항상 1월부터 시작해서 현재 월이
  // 화면 밖에 있던 문제 수정. 첫 렌더링 직후 한 번만, 현재 월 칩이 보이는 위치로 스크롤을 이동시킴.
  // 이후 사용자가 직접 스크롤한 위치는 다시 덮어쓰지 않음(_monthRowAutoScrolled 플래그로 1회만 실행).
  void _scrollMonthRowToCurrent() {
    if (_monthRowAutoScrolled) return;
    if (!_monthScrollController.hasClients) return;
    final int currentMonthIndex = DateTime.now().month - 1; // 0-based
    const double itemExtent = 58.0; // "N월" 칩 1개의 대략적인 폭(패딩+글자+여백 포함 추정치)
    double target =
        (currentMonthIndex * itemExtent) -
        itemExtent; // 현재 월 바로 앞칸부터 보이도록 약간의 여유
    if (target < 0) target = 0;
    final double maxScroll = _monthScrollController.position.maxScrollExtent;
    if (target > maxScroll) target = maxScroll;
    _monthScrollController.jumpTo(target);
    _monthRowAutoScrolled = true;
  }

  // 🆕 [데이터 연결-버그 수정] 레벨/별 실제 연동
  // 기존 문제: "Lv.26", "12,580개"/"23,487개"가 전부 고정 문자열이었음.
  // 수정 내용: star_economy.dart(DkeStars)의 실제 누적 별 개수를 불러와서 레벨(500개당 1레벨)까지 계산.
  Future<void> _loadStarsAndLevel() async {
    try {
      final int total = await DkeStars.getTotalStars();
      if (!mounted) return;
      setState(() {
        _totalStars = total;
        _currentLevelNumber = DkeStars.levelForStars(total);
      });
    } catch (e) {
      debugPrint("[MemberAchievement] 별/레벨 불러오기 실패: $e");
    }
  }

  // ============================================================================
  // 🆕 [장학금 방 2026-09-17] 월간 기본별(star_economy.dart에서 읽기만 함)과
  // 보너스별(scholarship_service.dart) 요약을 불러옵니다. 기존 별 적립 로직에는
  // 전혀 관여하지 않고, 이미 저장된 결과만 조회합니다.
  // ============================================================================
  Future<void> _loadScholarshipSummary() async {
    try {
      final int base = await ScholarshipService.getMonthlyBaseStars();
      final int bonus = await ScholarshipService.getMonthlyBonusStars();
      final Map<String, int> breakdown =
          await ScholarshipService.getMonthlyBonusBreakdown();
      final String? myCode =
          await FamilyLinkService.getMyLinkCode(); // 🆕 [실시간 장학금 금액]
      if (!mounted) return;
      setState(() {
        _scholarshipMonthlyBaseStars = base;
        _scholarshipMonthlyBonusStars = bonus;
        _scholarshipBonusBreakdown = breakdown;
        _myLinkCode = myCode;
        _isScholarshipDataLoading = false;
      });
    } catch (e) {
      debugPrint("[MemberAchievement] 장학금 요약 불러오기 실패: $e");
      if (!mounted) return;
      setState(() => _isScholarshipDataLoading = false);
    }
  }

  // ============================================================================
  // 🆕 [방치 코드 정리 2026-09-18] 화면이 열릴 때 한 번, "5주 이상 방치된 예전
  // 코드"가 있는지 서버에 물어보고, 있으면 팝업으로 안내함. 절대 자동으로
  // 지우지 않으며, 학생이 팝업에서 "삭제"를 직접 눌러야만 실제로 지워짐.
  // "나중에"를 누르면 이번 화면 세션에서는 다시 묻지 않되, 다음에 앱을
  // 다시 열면(그 코드를 계속 안 지웠다면) 또 안내함.
  // ============================================================================
  Future<void> _checkAbandonedCode() async {
    try {
      final String? abandoned = await FamilyLinkService.findAbandonedOwnCode();
      if (!mounted || abandoned == null) return;
      setState(() => _abandonedCodeForPopup = abandoned);
      _showAbandonedCodeDialog(abandoned);
    } catch (e) {
      debugPrint("[MemberAchievement] 방치 코드 확인 실패(무시): $e");
    }
  }

  void _showAbandonedCodeDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1527),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "예전 코드 정리",
          style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          "예전에 만든 코드($code)가 5주 넘게 사용되지 않았어요.\n"
              "학습 기록도 전혀 없는 상태입니다.\n\n"
              "더 이상 필요 없다면 삭제하시겠어요?\n"
              "(원하지 않으시면 그냥 닫으셔도 되고, 코드는 계속 남아있습니다)",
          style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("나중에", style: GoogleFonts.notoSansKr(color: Colors.white60, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _ThemeColors.brandGolden),
            onPressed: () async {
              Navigator.of(context).pop();
              await FamilyLinkService.deleteAbandonedCode(code);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("예전 코드($code)를 삭제했습니다.")),
                );
              }
            },
            child: Text("삭제", style: GoogleFonts.notoSansKr(color: const Color(0xFF030712), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 🆕 [데이터 연결 2026-07-29] 실제 가입자 이름 불러오기.
  // 기존엔 '이규현'/'Lee Gyu-hyun', '이제임스'/'James Lee' 등이 화면에 고정 문자열로 박혀있었음.
  // 이제 signup_screen.dart 가입 완료 시점에 저장된 실제 이름을 불러와서 표시.
  Future<void> _loadRealUserName() async {
    try {
      final String? name = await DkeUserProfile.getRealName();
      if (!mounted) return;
      setState(() {
        _realUserName = name;
      });
    } catch (e) {
      debugPrint("[MemberAchievement] 가입자 이름 불러오기 실패: $e");
    }
  }

  // 🆕 [요청 2026-09-04] 실제 학교명/학년 불러오기.
  // 기존엔 "GKE 고등학교 2학년"이 화면에 고정 문자열로 박혀있었음.
  // 이제 signup_screen.dart 가입 완료 시점에 학생이 입력한 학교/학년(user_profile_service.dart에 저장됨)을
  // 불러와서 표시. 값이 없는 회원(가입 당시 미입력, 또는 학부모/일반 계정)은 기존 고정 문구를 그대로 표시.
  Future<void> _loadRealSchoolGrade() async {
    try {
      final String? school = await DkeUserProfile.getSchoolName();
      final String? grade = await DkeUserProfile.getGrade();
      if (!mounted) return;
      setState(() {
        _realSchoolName = school;
        _realGrade = grade;
      });
    } catch (e) {
      debugPrint("[MemberAchievement] 학교/학년 불러오기 실패: $e");
    }
  }

  // 🆕 [요청 2026-09-04] 학교/학년/이름을 조합한 실제 표시 문자열.
  // 회원가입 때 학교와 학년을 모두 입력한 학생이면 "OO고등학교 2학년 홍길동"처럼
  // 실제 값으로 조합해서 보여주고, 하나라도 비어있으면(가입 당시 미입력, 학부모/일반 계정 등)
  // 기존 고정 문구("GKE 고등학교 2학년" + 이름)로 안전하게 대체합니다.
  String get _schoolGradeNameDisplay {
    final String name =
        _realUserName ?? (DkeLang.current == 'KO' ? "학습자" : "Learner");
    if ((_realSchoolName ?? '').isNotEmpty && (_realGrade ?? '').isNotEmpty) {
      return "$_realSchoolName $_realGrade $name";
    }
    return DkeLang.current == 'KO'
        ? '${_t("highSchoolGrade2")} $name'
        : "${_t('highSchoolGrade2')}, $name";
  }

  // ============================================================================
  // 🆕 [버그 수정 2026-07-29] 레코드 목록 전체를 한 번에 변환하다가 하나라도 실패하면
  // 전체가 빈 목록이 되어버리던 문제를 수정. 이제 레코드 하나씩 개별적으로 파싱해서,
  // 손상된 레코드 하나만 건너뛰고 나머지 정상 레코드는 모두 정상적으로 불러옵니다.
  Future<void> _loadExamRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? recordsJson = prefs.getString('gke_exam_records');

      List<_ExamRecord> loaded = [];
      if (recordsJson != null && recordsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(recordsJson);
        for (final e in decoded) {
          try {
            loaded.add(
              _ExamRecord.fromJson(Map<String, dynamic>.from(e as Map)),
            );
          } catch (itemError) {
            // 개별 레코드 하나가 손상되어 있어도 나머지 레코드는 정상적으로 계속 불러옵니다.
            debugPrint("[MemberAchievement] 손상된 성적 기록 1건 건너뜀: $itemError");
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _allRecords = loaded;
        _lastSavedRecordForDisplay = loaded.isNotEmpty ? loaded.last : null;
        _isRecordsLoading = false;
      });
    } catch (e) {
      debugPrint("[MemberAchievement] 성적 기록 불러오기 실패: $e");
      if (!mounted) return;
      setState(() {
        _allRecords = [];
        _isRecordsLoading = false;
      });
    }
  }

  // 🆕 [데이터 연결] 성적 기록이 추가/삭제될 때마다 호출해서 즉시 영구 저장
  Future<void> _persistExamRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(
        _allRecords.map((r) => r.toJson()).toList(),
      );
      await prefs.setString('gke_exam_records', encoded);
    } catch (e) {
      debugPrint("[MemberAchievement] 성적 기록 저장 실패: $e");
    }
  }

  // 🆕 [데이터 연결 - 버그 수정] 목표 대학 실제 연동
  // 기존 문제: 마이페이지(my_page_screen.dart)에서 학생이 목표 대학을 직접 입력해도
  //           이 화면은 항상 '서울대학교'(_t('snu')) 고정값만 표시했음.
  // 수정 내용: my_page_screen.dart와 동일한 키('saved_target_university')를 그대로 읽어와서 표시.
  //           아직 저장된 값이 없는 신규 유저는 기본 안내 문구를 표시.
  Future<void> _loadRealTargetUniversity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? saved = prefs.getString('saved_target_university');
      if (!mounted) return;
      setState(() {
        _realTargetUniversity = (saved != null && saved.isNotEmpty)
            ? saved
            : null;
      });
    } catch (e) {
      debugPrint("[MemberAchievement] 목표 대학 불러오기 실패: $e");
    }
  }

  List<_ExamRecord> _getFilteredRecords(String type) {
    return _allRecords.where((rec) {
      bool baseMatch =
          rec.type == type &&
          rec.grade == _filterGrade &&
          rec.semester == _filterSemester;

      if (type == "주평가") {
        return baseMatch &&
            rec.unit.contains(_inputYear) &&
            rec.unit.contains(_inputMonth) &&
            rec.unit.contains(_inputWeek);
      } else if (type == "단원평가") {
        return baseMatch &&
            _inputBigUnits.any((bu) => rec.unit.contains(bu)) &&
            _inputMidUnits.any((mu) => rec.unit.contains(mu));
      } else {
        return baseMatch && rec.unit.contains(_inputSemesterGroup);
      }
    }).toList();
  }

  // 🆕 [6번] 로컬(기기 내부, 무료) 데이터는 항상 실시간으로 반영하고,
  // 클라우드 서버(향후 Firestore 등 과금형 저장소) 재조회만 1시간 간격으로 제한하는 게이트.
  // 지금은 전부 SharedPreferences(로컬/무료)라 실제 차단은 없지만, 서버 연동 시 이 게이트를 그대로 사용하면 됨.
  bool _shouldFetchFromRemote() {
    if (_lastRemoteSyncAt == null) return true;
    return DateTime.now().difference(_lastRemoteSyncAt!) >= _remoteSyncInterval;
  }

  Future<void> _syncTimerSharedDataPackets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? tempSubject = prefs.getString('dke_temp_subject');
      final int? tempSeconds = prefs.getInt('dke_temp_elapsed');

      setState(() {
        _timerSubject = tempSubject ?? (_subjectName("수학"));
        _timerDetails = _t('timerDetailDefault');
        _timerScore = 100;
        _timerIncorrect = _t('completed');
        _timerDurationMinutes = tempSeconds != null
            ? (tempSeconds ~/ 60 == 0 ? 72 : tempSeconds ~/ 60)
            : 72;
      });
      // 로컬 저장소 읽기는 무료이므로 실시간 반영. 원격(클라우드) 동기화 시각만 별도 기록.
      _lastRemoteSyncAt = DateTime.now();
    } catch (e) {
      debugPrint("성취도 데이터 패킷 결합 추적 예외: $e");
    }
  }

  // 🆕 [반복 방지 라이브러리 시스템 2026-09-02] 예전엔 "점수 구간 하나당 진단문 1개"만 만들어서
  // 영구 캐시했기 때문에, 같은 점수대에 속하는 모든 학생(심지어 같은 학생이 여러 번 봐도)이
  // 항상 완전히 동일한 문장을 보게 되는 문제가 있었음.
  //
  // 수정 내용: 점수 구간별로 "라이브러리"(여러 개의 진단문 목록)를 저장해두고,
  // 사람(uid)별로 "이미 본 문장 번호"를 따로 기록함. 요청이 오면:
  //  1) 이 사람이 아직 못 본 라이브러리 항목이 있으면 그걸 재사용 (다른 학생에게는 재사용되어도 됨)
  //  2) 이 사람이 라이브러리를 전부 이미 봤거나 라이브러리가 비어있으면, 새로 생성해서
  //     라이브러리에 추가하고 그것을 "본 것"으로 기록
  // 이렇게 하면 "유사한 학생들에게는 재사용되지만, 같은 사람에게는 절대 같은 내용이 다시 나타나지 않음".
  Future<String> _generateOrReuseDiagnosis({
    required String type,
    required double score,
    required String subject,
    required AiTier tier,
  }) async {
    final int bucket = (score ~/ 10) * 10; // 10점 단위 버킷 (예: 83점 -> 80)
    final String lang = DkeLang.current;
    final prefs = await SharedPreferences.getInstance();
    // 🆕 사람을 구분하는 키. 로그인 계정(uid) 기준이며, 계정 정보가 없으면 'guest'로 처리.
    final String personKey = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

    final String libraryKey = 'dke_diagnosis_library_${lang}_${type}_$bucket';
    final String seenKey =
        'dke_diagnosis_seen_${personKey}_${lang}_${type}_$bucket';

    final List<String> library = prefs.getStringList(libraryKey) ?? [];
    final List<String> seenIndices = prefs.getStringList(seenKey) ?? [];

    for (int i = 0; i < library.length; i++) {
      if (!seenIndices.contains('$i')) {
        seenIndices.add('$i');
        await prefs.setStringList(seenKey, seenIndices);
        return library[i];
      }
    }

    // TODO(향후 플스토어 출시 직전): tier == AiTier.pro / AiTier.light 분기에 따라
    // 실제 AI API 호출로 교체. 지금은 기존 규칙 기반(랜덤 문구 조합) 생성 로직을 그대로 사용.
    final String generated = _buildRuleBasedDiagnosisText(
      type: type,
      score: score,
      subject: subject,
    );
    library.add(generated);
    await prefs.setStringList(libraryKey, library);
    seenIndices.add('${library.length - 1}');
    await prefs.setStringList(seenKey, seenIndices);
    return generated;
  }

  // 🆕 [12개국 확장] 진단 문단 뱅크: 한국어/영어는 기존 2개 버전 유지, 나머지 10개 언어는 1개 버전
  static const Map<String, Map<String, List<String>>> _diagOpenings = {
    'good': {
      'KO': [
        '이번 평가에서 90점 이상의 우수한 고득점을 기록한 것은 학습자의 숨겨진 잠재력이 마침내 표면 위로 발현되기 시작했음을 증명하는 매우 기쁜 소식입니다. ',
        '이번에 달성한 높은 성적은 그동안 묵묵히 쌓아온 학습의 밀도가 드디어 가시적인 성과로 도출되었음을 시사하는 대단히 고무적인 결과물입니다. ',
      ],
      'EN': [
        'Scoring above 90 on this evaluation is wonderful news — it shows the learner\'s hidden potential is finally surfacing. ',
        'This high score signals that the quiet, steady effort invested until now has finally produced a clearly visible result. ',
      ],
      'JA': ['今回90点以上の優秀な高得点を記録したことは、学習者の隠れた潜在力がついに表面化し始めたことを示す非常に嬉しい知らせです。'],
      'ZH': ['本次评估取得90分以上的优异成绩，说明学习者潜藏的实力终于开始显现，这是非常令人欣喜的结果。'],
      'FR': [
        'Obtenir plus de 90 points à cette évaluation est une excellente nouvelle : le potentiel caché de l\'apprenant commence enfin à se révéler.',
      ],
      'DE': [
        'Eine Punktzahl von über 90 bei dieser Bewertung ist eine großartige Nachricht — das verborgene Potenzial des Lernenden zeigt sich endlich.',
      ],
      'RU': [
        'Результат выше 90 баллов на этой оценке — прекрасная новость: скрытый потенциал ученика наконец начал проявляться.',
      ],
      'AR': [
        'الحصول على أكثر من 90 درجة في هذا التقييم خبر رائع يدل على أن الإمكانات الكامنة لدى المتعلم بدأت تظهر أخيرًا.',
      ],
      'HI': [
        'इस मूल्यांकन में 90 से अधिक अंक प्राप्त करना बहुत अच्छी खबर है — यह दिखाता है कि सीखने वाले की छिपी क्षमता आखिरकार सामने आने लगी है।',
      ],
      'VI': [
        'Đạt trên 90 điểm trong lần đánh giá này là tin rất đáng mừng — tiềm năng tiềm ẩn của người học cuối cùng đã bắt đầu bộc lộ.',
      ],
      'ES': [
        'Obtener más de 90 puntos en esta evaluación es una excelente noticia: el potencial oculto del estudiante finalmente está saliendo a la luz.',
      ],
      'TH': [
        'การได้คะแนนมากกว่า 90 ในการประเมินครั้งนี้เป็นข่าวดีมาก แสดงว่าศักยภาพที่ซ่อนอยู่ของผู้เรียนเริ่มปรากฏออกมาแล้ว',
      ],
    },
    'mid': {
      'KO': [
        '현재 도달한 성취도의 위치는 조금만 더 정밀하게 메타인지(자신의 인지 활동을 모니터링하고 조절하는 능력)를 조율하면 언제든 만점까지 단숨에 바라볼 수 있는 고지가 바로 눈앞에 와 있는 단계입니다. ',
        '이번에 확보한 상위권 점수는 안정적인 성장을 의미하지만, 동시에 조금의 임계점만 넘어서면 언제든 최상위권의 벽을 깨부수고 만점으로 직행할 수 있는 가장 중요한 기로의 점수대입니다. ',
      ],
      'EN': [
        'This score sits right at the doorstep of a perfect score — a little sharper metacognitive tuning is all that stands between here and the top. ',
        'This upper-tier score reflects steady growth, but it also sits at the exact tipping point where one more push could break straight through to the very top. ',
      ],
      'JA': [
        '現在到達した成績のポジションは、もう少し精密にメタ認知（自身の認知活動を監視・調整する能力）を調整すれば、いつでも満点を視野に入れられる段階です。',
      ],
      'ZH': ['目前所处的成绩位置，只要再稍微精细地调节元认知（监控并调节自身认知活动的能力），随时都有望冲击满分。'],
      'FR': [
        'Le niveau actuel n\'est qu\'à un pas d\'un score parfait — un réglage plus fin de la métacognition suffirait pour franchir le cap.',
      ],
      'DE': [
        'Das aktuelle Niveau liegt direkt vor der Bestnote — eine feinere metakognitive Justierung genügt, um den letzten Schritt zu schaffen.',
      ],
      'RU': [
        'Текущий уровень находится буквально на пороге максимального балла — небольшая настройка метапознания способна привести к вершине.',
      ],
      'AR': [
        'المستوى الحالي يقترب كثيرًا من الدرجة الكاملة — يكفي ضبط أدق للإدراك الفوقي للوصول إلى القمة في أي وقت.',
      ],
      'HI': [
        'वर्तमान स्कोर पूर्ण अंकों की दहलीज पर है — थोड़ा और सटीक मेटाकॉग्निटिव समायोजन शिखर तक पहुंचा सकता है।',
      ],
      'VI': [
        'Vị trí điểm số hiện tại đã rất gần điểm tuyệt đối — chỉ cần điều chỉnh nhận thức tinh tế hơn một chút là có thể vươn tới đỉnh cao.',
      ],
      'ES': [
        'El nivel actual está a un paso del puntaje perfecto: un ajuste metacognitivo más preciso podría llevarte a la cima en cualquier momento.',
      ],
      'TH': [
        'ตำแหน่งคะแนนตอนนี้อยู่ใกล้คะแนนเต็มมาก เพียงปรับกระบวนการรู้คิดให้ละเอียดขึ้นอีกนิดก็สามารถไปถึงจุดสูงสุดได้ทุกเมื่อ',
      ],
    },
    'seventy': {
      'KO': [
        '이번 평가에서 기록한 70점대의 수치는 학습자가 현재 지닌 역량에 비해 다소 아쉬운 결과이며, 현재의 약점을 방치할 경우 아래 점수대로 내려갈 수 있는 경계선에 있습니다. ',
        '현재 포지션은 탄탄한 도약이냐 지체냐를 결정짓는 중대한 기로입니다. 구조적 점검이 신속하게 이루어지지 않는다면 다음 평가에서 예상치 못한 하락세를 맞이할 위험이 공존합니다. ',
      ],
      'EN': [
        'This 70s-range score falls a bit short of the learner\'s real ability, and leaving current weak points unaddressed risks a slide into the lower range. ',
        'This is a genuine fork in the road between a strong leap forward and stagnation. Without a quick structural check, an unexpected drop could show up on the next evaluation. ',
      ],
      'JA': [
        '今回の評価で記録された70点台の数値は、学習者が現在持つ実力に比べてやや惜しい結果であり、現在の弱点を放置すればさらに下の点数帯に落ちる可能性がある境界線にあります。',
      ],
      'ZH': ['本次评估记录的70分段成绩，相较于学习者当前实际具备的能力略显可惜，若放任目前的弱点不管，很可能滑向更低的分数段。'],
      'FR': [
        'Ce score dans les 70 est un peu en deçà du véritable niveau de l\'apprenant, et ignorer les faiblesses actuelles risque de faire chuter encore le résultat.',
      ],
      'DE': [
        'Dieses Ergebnis im 70er-Bereich liegt etwas unter dem tatsächlichen Können des Lernenden, und wenn die aktuellen Schwächen ignoriert werden, droht ein weiterer Abstieg.',
      ],
      'RU': [
        'Результат в диапазоне 70 баллов немного не дотягивает до реального уровня ученика, и если не устранить текущие слабости, есть риск дальнейшего снижения.',
      ],
      'AR': [
        'هذه النتيجة في السبعينيات أقل قليلاً من القدرة الحقيقية للمتعلم، وإهمال نقاط الضعف الحالية قد يؤدي إلى مزيد من التراجع.',
      ],
      'HI': [
        '70 के दशक का यह स्कोर सीखने वाले की वास्तविक क्षमता से थोड़ा कम है, और वर्तमान कमजोरियों को नज़रअंदाज़ करने से स्कोर और गिर सकता है।',
      ],
      'VI': [
        'Điểm số trong khoảng 70 này thấp hơn một chút so với năng lực thực sự của người học, và nếu bỏ qua điểm yếu hiện tại, điểm số có thể tiếp tục giảm.',
      ],
      'ES': [
        'Este puntaje en el rango de los 70 queda un poco por debajo de la capacidad real del estudiante, y si se ignoran las debilidades actuales, podría bajar aún más.',
      ],
      'TH': [
        'คะแนนช่วง 70 นี้ต่ำกว่าความสามารถที่แท้จริงของผู้เรียนเล็กน้อย และหากปล่อยจุดอ่อนปัจจุบันไว้ อาจทำให้คะแนนลดลงไปอีก',
      ],
    },
    'sixty': {
      'KO': [
        '현재 누적된 60점대의 성취도는 교과 개념의 정착 단계에서 예상보다 깊은 균열이 발생했음을 나타내며, 신속히 반등의 불씨를 지피지 않으면 하락세를 멈추기 어려운 주의 단계입니다. ',
        '현재 점수대는 냉정하게 직시했을 때 하위권으로 정착할 것인가, 혹은 상위권으로 치고 올라갈 것인가를 가르는 매우 엄중한 인지적 기로에 서 있음을 뜻합니다. ',
      ],
      'EN': [
        'A score in the 60s points to a deeper-than-expected crack in the foundation, and without acting quickly, the downward trend will be hard to stop. ',
        'Looking at this honestly, this score sits right at the fork between settling into the lower tier or fighting back up toward the top. ',
      ],
      'JA': [
        '現在累積された60点台の成績は、教科概念の定着段階で予想より深い亀裂が生じたことを示しており、迅速に反騰の火種を灯さなければ下降を止めにくい注意段階です。',
      ],
      'ZH': ['目前累积的60分段成绩，说明在学科概念巩固阶段出现了比预期更深的裂痕，若不尽快点燃反弹的契机，下滑趋势将很难止住，需引起重视。'],
      'FR': [
        'Ce score dans les 60 révèle une fissure plus profonde que prévu dans la consolidation des concepts ; sans réaction rapide, la baisse sera difficile à enrayer.',
      ],
      'DE': [
        'Diese Punktzahl im 60er-Bereich zeigt einen tieferen Riss in der Konzeptfestigung als erwartet; ohne schnelles Gegensteuern wird der Abwärtstrend schwer zu stoppen sein.',
      ],
      'RU': [
        'Результат в диапазоне 60 баллов указывает на более глубокий разрыв в закреплении понятий, чем ожидалось; без быстрой реакции остановить спад будет трудно.',
      ],
      'AR': [
        'هذه النتيجة في الستينيات تكشف عن فجوة أعمق من المتوقع في ترسيخ المفاهيم؛ وبدون تحرك سريع، سيصعب وقف التراجع.',
      ],
      'HI': [
        '60 के दशक का यह स्कोर अवधारणा सुदृढ़ीकरण में अपेक्षा से अधिक गहरी दरार दिखाता है; तेज़ी से कार्रवाई किए बिना गिरावट को रोकना मुश्किल होगा।',
      ],
      'VI': [
        'Điểm số trong khoảng 60 này cho thấy một vết nứt sâu hơn dự kiến trong việc củng cố khái niệm; nếu không hành động nhanh, xu hướng giảm sẽ khó ngăn lại.',
      ],
      'ES': [
        'Este puntaje en el rango de los 60 revela una grieta más profunda de lo esperado en la consolidación de conceptos; sin actuar rápido, será difícil detener la caída.',
      ],
      'TH': [
        'คะแนนช่วง 60 นี้แสดงถึงรอยร้าวในการปูพื้นฐานแนวคิดที่ลึกกว่าที่คาดไว้ หากไม่รีบดำเนินการ แนวโน้มขาลงจะหยุดได้ยาก',
      ],
    },
    'low': {
      'KO': [
        '현재 기록된 평가 수치는 기초 개념 정착 단계에서 전반적인 재조정과 보완이 시급함을 가리키는 엄중한 진단서입니다. ',
        '현재의 지표는 학습 프로세스 전체에 걸쳐 개념적 누수가 누적되었음을 경고하고 있으며, 즉각적인 학습 루틴의 전면적인 개혁이 필요한 순간입니다. ',
      ],
      'EN': [
        'This score is a serious signal that the foundational concepts need a full reset and reinforcement. ',
        'This result warns that conceptual gaps have accumulated across the whole learning process, and the study routine needs an immediate, full overhaul. ',
      ],
      'JA': ['現在記録された評価数値は、基礎概念の定着段階で全般的な再調整と補完が急がれることを示す厳重な診断書です。'],
      'ZH': ['当前记录的评估结果，是一份严肃的诊断书，表明在基础概念巩固阶段亟需全面调整与补强。'],
      'FR': [
        'Ce résultat est un signal sérieux indiquant qu\'un réajustement complet des concepts fondamentaux est nécessaire de toute urgence.',
      ],
      'DE': [
        'Dieses Ergebnis ist ein ernstes Signal dafür, dass eine umfassende Neuausrichtung der Grundkonzepte dringend erforderlich ist.',
      ],
      'RU': [
        'Этот результат — серьёзный сигнал о том, что необходима срочная и всесторонняя перестройка базовых понятий.',
      ],
      'AR': [
        'هذه النتيجة إشارة جادة إلى ضرورة إعادة ضبط شاملة وعاجلة للمفاهيم الأساسية.',
      ],
      'HI': [
        'यह स्कोर एक गंभीर संकेत है कि बुनियादी अवधारणाओं में तत्काल और व्यापक पुनर्समायोजन आवश्यक है।',
      ],
      'VI': [
        'Kết quả này là tín hiệu nghiêm túc cho thấy cần điều chỉnh và củng cố toàn diện các khái niệm nền tảng ngay lập tức.',
      ],
      'ES': [
        'Este resultado es una señal seria de que se necesita un reajuste integral y urgente de los conceptos fundamentales.',
      ],
      'TH': [
        'ผลคะแนนนี้เป็นสัญญาณที่ต้องให้ความสำคัญว่าจำเป็นต้องปรับพื้นฐานแนวคิดใหม่อย่างเร่งด่วนและครอบคลุม',
      ],
    },
  };

  static const Map<String, Map<String, List<String>>> _diagClosings = {
    'good': {
      'KO': [
        '그러나 현재의 기초 체급을 고려할 때, 이번 결과에 취해 단 한순간이라도 안일해지는 즉시 성적은 하락세로 돌아설 수 있습니다. 진정한 만점자로 안착하기 위해서는 실전에서 발생한 미세한 균열을 메워야 하므로, 틀린 문제는 반드시 누적 오답정리(틀린 원인을 기록하고 분석하는 과정)를 완수하고 최소 3번 이상 반복하여 완전히 본인의 것으로 만드는 철저한 회독 습관을 기르십시오. 자만하지 않고 이 정합성 확인 루틴을 성실히 유지한다면, 다음 실전에서도 흔들리지 않는 진짜 탑클래스로 우뚝 설 것입니다.',
        '다만 지금의 위치에서 방심하여 루틴이 느슨해진다면 차기 평가에서는 아쉬운 결과를 맛보게 될 수 있습니다. 완전무결한 성취를 지속하기 위해서는 취약 문항의 누적 오답정리(틀린 원인을 기록하고 분석하는 과정)를 철저히 이행하고, 오답을 3번 이상 재차 정밀 분석하여 풀어내는 훈련이 필수적입니다. 나태함을 경계하고 메타인지 루틴을 사수하여 흔들림 없는 정점에 도달하십시오.',
      ],
      'EN': [
        'That said, given the current foundation, even a moment of complacency could send the score back down. To truly lock in top-tier status, log every mistake in an error journal, review it at least three times, and make it fully your own. Keep this consistency routine honest and unshaken results in the next real test will follow.',
        'Be careful not to let the routine loosen just because of this win — a lapse now could mean a disappointing result next time. Keep logging and re-analyzing every weak item at least three times. Guard against complacency and protect your metacognitive routine to reach an unshakeable peak.',
      ],
      'JA': [
        'ただし現在の基礎レベルを考えると、この結果に浮かれて一瞬でも油断すればすぐに成績は下降する可能性があります。真のトップクラスとして定着するためには、間違えた問題は必ず誤答ノート（間違えた原因を記録・分析する過程）を完成させ、最低3回以上繰り返して完全に自分のものにする徹底した復習習慣を身につけてください。慢心せずこの整合性確認ルーティンを誠実に維持すれば、次の実戦でも揺るがない本物のトップクラスとして立つでしょう。',
      ],
      'ZH': [
        '不过考虑到目前的基础水平，若因这次结果而有片刻松懈，成绩很可能立刻出现下滑。要真正稳居顶尖水平，必须将错题整理（记录并分析出错原因的过程）坚持完成，并至少反复复习三次以上，使其完全内化为自己的知识。只要不骄傲自满、认真维持这一巩固流程，下次实战中也能稳如泰山地站在真正的顶尖行列。',
      ],
      'FR': [
        'Cependant, compte tenu du niveau actuel des bases, le moindre relâchement pourrait faire chuter les résultats. Pour consolider durablement ce niveau, notez chaque erreur dans un journal, révisez-la au moins trois fois et faites-en une habitude rigoureuse. En maintenant cette routine avec sérieux, vous resterez stable au sommet lors de la prochaine évaluation.',
      ],
      'DE': [
        'Angesichts der aktuellen Grundlagen könnte jedoch schon ein Moment der Nachlässigkeit die Note wieder sinken lassen. Um wirklich an der Spitze zu bleiben, sollten Sie jeden Fehler in einem Fehlerprotokoll festhalten, mindestens dreimal wiederholen und vollständig verinnerlichen. Bleiben Sie diszipliniert bei dieser Routine, um auch beim nächsten Test stabil an der Spitze zu stehen.',
      ],
      'RU': [
        'Однако, учитывая текущий уровень базы, малейшее самодовольство может привести к падению результатов. Чтобы закрепиться на вершине, обязательно фиксируйте каждую ошибку в журнале ошибок, повторяйте её минимум три раза и полностью усваивайте. Сохраняя эту дисциплину, вы останетесь уверенно на вершине и в следующий раз.',
      ],
      'AR': [
        'لكن نظرًا للمستوى الأساسي الحالي، فإن أي تراخٍ ولو للحظة قد يؤدي إلى تراجع النتيجة. للحفاظ على مكانتك في القمة، سجّل كل خطأ في دفتر الأخطاء وراجعه ثلاث مرات على الأقل حتى تتقنه تمامًا. حافظ على هذا الروتين بجدية لتبقى ثابتًا في القمة في الاختبار القادم أيضًا.',
      ],
      'HI': [
        'लेकिन वर्तमान आधार स्तर को देखते हुए, इस परिणाम से एक पल के लिए भी लापरवाह होना स्कोर को नीचे ला सकता है। शीर्ष स्तर पर स्थिर रहने के लिए, हर गलती को एक त्रुटि पत्रिका में दर्ज करें, कम से कम तीन बार दोहराएं और उसे पूरी तरह आत्मसात करें। इस अनुशासन को बनाए रखें ताकि अगली बार भी शीर्ष पर मजबूती से खड़े रहें।',
      ],
      'VI': [
        'Tuy nhiên, xét theo nền tảng hiện tại, chỉ cần một khoảnh khắc lơ là cũng có thể khiến điểm số giảm sút. Để duy trì vững chắc vị trí hàng đầu, hãy ghi lại mọi lỗi sai vào nhật ký lỗi, ôn lại ít nhất ba lần và biến nó thành kiến thức của riêng mình. Duy trì kỷ luật này để tiếp tục đứng vững ở vị trí cao trong lần đánh giá tới.',
      ],
      'ES': [
        'Sin embargo, dado el nivel base actual, un momento de exceso de confianza podría hacer bajar la puntuación. Para consolidarte en la cima, registra cada error en un diario de errores, repásalo al menos tres veces y asimílalo por completo. Mantén esta rutina con disciplina para seguir firme en la cima la próxima vez.',
      ],
      'TH': [
        'อย่างไรก็ตาม เมื่อพิจารณาระดับพื้นฐานในปัจจุบัน หากเผลอตัวแม้เพียงชั่วขณะ คะแนนก็อาจลดลงได้ทันที เพื่อรักษาตำแหน่งระดับสูงสุดอย่างแท้จริง ควรบันทึกทุกข้อผิดพลาดลงในสมุดบันทึกข้อผิดพลาดและทบทวนอย่างน้อย 3 ครั้งจนเป็นความรู้ของตัวเองอย่างสมบูรณ์ รักษาวินัยนี้ไว้เพื่อยืนหยัดอยู่จุดสูงสุดอย่างมั่นคงในครั้งต่อไป',
      ],
    },
    'mid': {
      'KO': [
        '지금 단계에서 가장 유의해야 할 것은 \'이 정도면 됐다\'는 주관적인 안주와 타협입니다. 문항 분석 시 개념 스키마(지식의 구조적 네트워크)의 뼈대는 훌륭하나, 조건 해석의 정밀도가 다소 부족하여 감점이 발생하고 있습니다. 취약 단원의 고난도 변형 문제를 집중 공략하고 실전 시간 안배의 정밀도를 한 단계만 가속화하십시오. 정상으로 가는 마지막 관문이니, 조금만 더 고도의 학업적 몰입도를 발휘해 만점의 영광을 함께 쟁취합시다!',
        '현재 상태에서 성장을 한 단계 더 정체시키는 원인은 주관적인 안일함에 있을 수 있습니다. 인지 구조 내의 기본 스키마(지식의 구조적 네트워크)는 안정적이나, 세부 변별 과정에서 집중력의 미세한 누수가 관찰됩니다. 안일함을 지워내고 문항 단독 피드백 검토 단계를 한층 더 확장하십시오. 조금만 더 치열하게 벽을 두드린다면 반드시 차기 세션에서 만점을 거머쥘 수 있습니다.',
      ],
      'EN': [
        'The biggest risk right now is settling for \'good enough.\' The core concept structure is solid, but precision in reading question conditions is costing points. Target the hardest variant problems in weak units and tighten exam-time pacing one more notch. This is the final gate to the top — push a little harder and claim it!',
        'The one thing holding growth back may be quiet complacency. The core knowledge structure is stable, but small lapses in concentration show up during fine-grained discrimination. Shed the complacency and expand item-by-item review. A bit more persistence and a perfect score is within reach next session.',
      ],
      'JA': [
        '今の段階で最も気をつけるべきは「これくらいで十分」という主観的な妥協です。問題分析の際、概念スキーマ（知識の構造的ネットワーク）の骨組みは優れていますが、条件解釈の精密さがやや不足して減点が生じています。弱点単元の高難度応用問題を集中攻略し、実戦の時間配分の精度をもう一段階高めてください。頂上への最後の関門なので、もう少し学業への没入度を高めて満点の栄光を勝ち取りましょう！',
      ],
      'ZH': [
        '目前阶段最需要警惕的就是“这样就够了”的主观妥协心态。分析题目时，概念框架（知识的结构性网络）已经相当扎实，但对条件的解读精度略有不足，从而导致失分。请集中攻克薄弱单元的高难度变式题，并将实战时间分配的精度再提升一个层次。这是通往顶峰的最后一关，只要再多投入一点学习专注度，就能共同夺得满分的荣耀！',
      ],
      'FR': [
        'À ce stade, le principal danger est de se satisfaire d\'un « c\'est déjà bien ». La structure conceptuelle est solide, mais la précision dans l\'interprétation des énoncés fait encore perdre des points. Concentrez-vous sur les variantes les plus difficiles des unités faibles et affinez la gestion du temps en conditions réelles. C\'est la dernière étape avant le sommet — un effort supplémentaire suffira à décrocher la perfection !',
      ],
      'DE': [
        'In dieser Phase besteht die größte Gefahr darin, sich mit „das reicht schon“ zufriedenzugeben. Die Konzeptstruktur ist solide, doch die Präzision beim Verständnis der Aufgabenbedingungen kostet noch Punkte. Konzentrieren Sie sich auf die schwierigsten Variantenaufgaben der schwachen Einheiten und verfeinern Sie das Zeitmanagement unter Prüfungsbedingungen. Dies ist das letzte Tor zum Gipfel — mit etwas mehr Einsatz ist die Bestnote erreichbar!',
      ],
      'RU': [
        'На этом этапе главная опасность — успокоиться на достигнутом. Концептуальная база прочная, но точность понимания условий заданий пока стоит баллов. Сосредоточьтесь на самых сложных вариациях заданий в слабых разделах и отточите распределение времени на экзамене. Это последний рубеж перед вершиной — ещё немного усилий, и максимальный балл будет достигнут!',
      ],
      'AR': [
        'في هذه المرحلة، أكبر خطر هو الرضا بـ«هذا يكفي». البنية المفاهيمية قوية، لكن دقة فهم شروط الأسئلة ما زالت تكلفك درجات. ركّز على أصعب أنواع الأسئلة في الوحدات الضعيفة، واضبط إدارة الوقت في ظروف الاختبار الحقيقية بدقة أكبر. هذه هي البوابة الأخيرة نحو القمة — القليل من الجهد الإضافي كافٍ لتحقيق الدرجة الكاملة!',
      ],
      'HI': [
        'इस चरण में सबसे बड़ा खतरा है \'इतना ही काफी है\' सोचकर संतुष्ट हो जाना। अवधारणा संरचना मजबूत है, लेकिन प्रश्नों की शर्तों को समझने की सटीकता में अभी भी अंक छूट रहे हैं। कमजोर यूनिट्स के सबसे कठिन प्रश्नों पर ध्यान केंद्रित करें और वास्तविक परीक्षा समय प्रबंधन को और सटीक बनाएं। यह शिखर की अंतिम सीढ़ी है — थोड़ा और प्रयास और पूर्ण अंक आपके हैं!',
      ],
      'VI': [
        'Ở giai đoạn này, nguy hiểm lớn nhất là hài lòng với suy nghĩ \'thế này là đủ rồi\'. Cấu trúc khái niệm đã vững, nhưng độ chính xác khi hiểu điều kiện câu hỏi vẫn khiến mất điểm. Hãy tập trung vào các dạng bài khó nhất ở những chương yếu, đồng thời tinh chỉnh việc phân bổ thời gian làm bài thực tế. Đây là cánh cửa cuối cùng trước đỉnh cao — chỉ cần nỗ lực thêm một chút là đạt điểm tuyệt đối!',
      ],
      'ES': [
        'En esta etapa, el mayor peligro es conformarse con un \'esto ya es suficiente\'. La estructura conceptual es sólida, pero la precisión al interpretar las condiciones de las preguntas todavía resta puntos. Concéntrate en las variantes más difíciles de las unidades débiles y afina la gestión del tiempo en condiciones reales. Esta es la última puerta hacia la cima: ¡un poco más de esfuerzo y la puntuación perfecta será tuya!',
      ],
      'TH': [
        'ในขั้นตอนนี้ สิ่งที่ต้องระวังที่สุดคือความคิดที่ว่า \'แค่นี้ก็พอแล้ว\' โครงสร้างแนวคิดแข็งแรงดี แต่ความแม่นยำในการตีความเงื่อนไขโจทย์ยังทำให้เสียคะแนนอยู่ ควรมุ่งเน้นโจทย์แบบยากในหน่วยที่ยังอ่อน และปรับการจัดสรรเวลาสอบจริงให้แม่นยำขึ้นอีกขั้น นี่คือด่านสุดท้ายก่อนถึงจุดสูงสุด เพียงทุ่มเทเพิ่มอีกนิดก็จะได้คะแนนเต็ม!',
      ],
    },
    'seventy': {
      'KO': [
        '하지만 역설적으로, 지금 이 순간 올바른 피드백을 통해 노력을 올바르게 투입한다면 전체 점수대 중 가장 폭발적이고 드라마틱하게 성적이 오를 수 있는 최고의 황금 구간이기도 합니다. 발생하는 오답들은 구조적 오인(개념의 뼈대를 잘못 이해하고 오답을 도출하는 현상)을 다듬으면 충분히 해결 가능한 자산입니다. 기본 원리 분석부터 차근차근 다시 정립하여 취약점을 지워내십시오. 가장 극적인 반등의 주인공은 바로 학습자가 될 수 있습니다.',
        '좌절할 필요는 전혀 없습니다. 이 구간은 문제점을 명확히 인지하고 혁신하기만 하면 교과과정 전체에서 가장 웅장한 점수 상승 폭을 기록할 수 있는 기회의 땅입니다. 현재의 부진은 눈으로만 대충 훑어본 인지적 기만(이해했다고 착각하는 심리 상태)에서 비롯된 균열일 뿐입니다. 오늘부터 취약 단원 기본서 피드백을 차분하고 독하게 이행해 나간다면 차기 평가에서 가장 놀라운 도약을 이루어낼 것입니다.',
      ],
      'EN': [
        'Ironically, this is also the golden zone where the right feedback applied right now can produce the single biggest jump in scores across the whole range. Most of the current mistakes trace back to misreading concept structure — a fixable asset once corrected. Rebuild from first principles, unit by unit, and erase the weak spots. The most dramatic turnaround story could belong to this learner.',
        'There\'s no need to feel discouraged. Once the real problem is clearly identified, this range offers the biggest potential score jump in the whole curriculum. The current slump mostly comes from skimming material without truly absorbing it. Starting today, work calmly and thoroughly through core-textbook feedback on weak units for the most dramatic leap yet.',
      ],
      'JA': [
        'しかし逆説的に、今この瞬間正しいフィードバックを通じて努力を正しく投入すれば、全体の点数帯の中で最も劇的に成績が上がる可能性を秘めた黄金区間でもあります。発生している誤答は構造的誤解（概念の骨組みを誤って理解し誤答を導く現象）を整えれば十分解決可能な資産です。基本原理の分析から一つずつ再構築して弱点を消してください。最も劇的な反騰の主人公はまさに学習者になれます。',
      ],
      'ZH': [
        '然而矛盾的是，如果此刻能通过正确的反馈投入恰当的努力，这也正是整个分数段中最有可能实现戏剧性飞跃的黄金区间。目前出现的错题，只要纠正结构性误解（错误理解概念框架而导致答错的现象），完全是可以解决的宝贵资产。请从基本原理分析开始，逐步重建，消除薄弱环节。最具戏剧性的逆转主角完全可能就是这位学习者。',
      ],
      'FR': [
        'Paradoxalement, c\'est aussi la zone la plus propice à un bond spectaculaire si le bon effort est fourni maintenant. La plupart des erreurs viennent d\'une mauvaise compréhension de la structure conceptuelle — un point tout à fait corrigible. Reconstruisez les bases unité par unité pour effacer les faiblesses ; le plus grand rebond pourrait bien être signé par cet apprenant.',
      ],
      'DE': [
        'Paradoxerweise ist dies auch der Bereich, in dem der richtige Einsatz jetzt den dramatischsten Sprung in der Punktzahl bewirken kann. Die meisten Fehler beruhen auf einem Missverständnis der Konzeptstruktur — ein durchaus behebbarer Punkt. Bauen Sie die Grundlagen Einheit für Einheit neu auf, um die Schwächen zu beseitigen; der größte Aufschwung könnte genau von diesem Lernenden kommen.',
      ],
      'RU': [
        'Как ни парадоксально, именно этот диапазон даёт наибольший потенциал для резкого скачка результатов при правильных усилиях сейчас. Большинство ошибок связано с неверным пониманием концептуальной структуры — это вполне исправимо. Перестройте основы раздел за разделом, чтобы устранить слабые места; самый впечатляющий рывок вполне может совершить именно этот ученик.',
      ],
      'AR': [
        'من المفارقات أن هذا النطاق يوفر أكبر إمكانية لقفزة درامية في النتيجة إذا بُذل الجهد الصحيح الآن. معظم الأخطاء الحالية ناتجة عن سوء فهم للبنية المفاهيمية، وهو أمر قابل للتصحيح تمامًا. أعد بناء الأساسيات وحدة تلو الأخرى لإزالة نقاط الضعف؛ قد يكون هذا المتعلم بطل أكبر قفزة في النتائج.',
      ],
      'HI': [
        'विडंबना यह है कि सही प्रयास से यह श्रेणी सबसे नाटकीय स्कोर उछाल की संभावना भी रखती है। अधिकांश गलतियां अवधारणा संरचना की गलतफहमी से आती हैं — जिसे सुधारा जा सकता है। कमजोरियों को मिटाने के लिए यूनिट-दर-यूनिट आधार फिर से बनाएं; सबसे नाटकीय वापसी की कहानी इसी सीखने वाले की हो सकती है।',
      ],
      'VI': [
        'Trớ trêu thay, đây cũng chính là vùng điểm có tiềm năng bứt phá ngoạn mục nhất nếu nỗ lực đúng cách ngay từ bây giờ. Hầu hết lỗi sai đến từ việc hiểu sai cấu trúc khái niệm — điều hoàn toàn có thể khắc phục. Hãy xây dựng lại nền tảng từng chương một để xóa bỏ điểm yếu; câu chuyện bứt phá ấn tượng nhất có thể chính là của người học này.',
      ],
      'ES': [
        'Paradójicamente, este también es el rango con mayor potencial de un salto dramático en la puntuación si se aplica el esfuerzo correcto ahora. La mayoría de los errores provienen de una mala comprensión de la estructura conceptual, algo totalmente corregible. Reconstruye las bases unidad por unidad para eliminar las debilidades; el protagonista del giro más espectacular bien podría ser este estudiante.',
      ],
      'TH': [
        'ที่น่าแปลกคือ ช่วงคะแนนนี้กลับมีศักยภาพในการพลิกผันคะแนนได้มากที่สุด หากทุ่มเทอย่างถูกวิธีตั้งแต่ตอนนี้ ข้อผิดพลาดส่วนใหญ่มาจากความเข้าใจผิดในโครงสร้างแนวคิด ซึ่งแก้ไขได้อย่างแน่นอน ควรปรับพื้นฐานใหม่ทีละหน่วยเพื่อลบล้างจุดอ่อน เรื่องราวการพลิกผันที่น่าทึ่งที่สุดอาจเป็นของผู้เรียนคนนี้ก็ได้',
      ],
    },
    'sixty': {
      'KO': [
        '불안해하기보다는 학습 습관의 구조적 전환이 시급함을 깨닫는 계기로 삼아야 합니다. 주관적인 인지적 기만(완전히 이해하지 못했음에도 이해했다고 착각하는 상태)을 완전히 걷어내고, 기본 스키마(지식의 구조적 네트워크) 확장에 몰입해야 합니다. 틀린 문항을 단순히 확인하는 것에 그치지 말고 원리를 파고드는 깊이 있는 복습 루틴을 오늘부터 즉시 가속화하십시오. 지금의 경각심을 변화의 발판으로 삼는다면 충분히 반등할 수 있습니다.',
        '현재의 성적은 노력이 부족했다기보다는 문항을 분석하고 접근하는 과정에서 고질적인 구조적 오인(개념의 뼈대를 잘못 매핑하는 현상)이 반복되고 있음을 방증합니다. 느슨해진 오답 정비 체계를 철저히 다시 채찍질하고, 핵심 원리 중심의 복습 인프라를 전면 재구축하십시오. 지금 태도를 혁신하지 않으면 다음 평가의 반등은 어려워집니다. 마음을 다잡고 오늘부터 집중도를 극대화합시다.',
      ],
      'EN': [
        'Rather than worry, treat this as the signal that study habits need a structural overhaul. Drop the illusion of understanding, and commit fully to rebuilding the core concept structure. Don\'t just check off wrong answers — dig into the underlying principles starting today. Turn this alarm into the springboard for a real turnaround.',
        'This score likely reflects not a lack of effort but a recurring habit of misreading concept structure. Rebuild the error-review system from the ground up around core principles. Without a real change in approach, the next evaluation won\'t turn around either — so commit fully starting today.',
      ],
      'JA': [
        '不安になるよりも、学習習慣の構造的転換が急務であることに気づく契機とすべきです。主観的な認知的欺瞞（完全に理解していないのに理解したと錯覚する状態）を完全に取り除き、基本スキーマ（知識の構造的ネットワーク）の拡張に没頭してください。間違えた問題を単に確認するだけでなく、原理を掘り下げる深みのある復習ルーティンを今日から即座に加速させてください。今の警戒心を変化の足場とすれば十分に反騰できます。',
      ],
      'ZH': [
        '与其感到不安，不如把这当作意识到学习习惯需要结构性转变的契机。请彻底摆脱“自以为理解了”的认知错觉，全力投入基础知识框架（知识的结构性网络）的扩展。不要只是确认错题，而要从今天起立刻加快深入原理的复习节奏。只要把现在的警觉当作改变的跳板，完全有机会实现反弹。',
      ],
      'FR': [
        'Plutôt que de s\'inquiéter, voyez-y le signal qu\'une refonte des habitudes d\'étude est nécessaire. Abandonnez l\'illusion de compréhension et investissez pleinement dans la reconstruction de la structure conceptuelle de base. Ne vous contentez pas de vérifier les erreurs — creusez les principes sous-jacents dès aujourd\'hui. Transformez cette vigilance en tremplin pour un vrai rebond.',
      ],
      'DE': [
        'Statt sich zu sorgen, sollte dies als Signal für eine strukturelle Überarbeitung der Lerngewohnheiten dienen. Verabschieden Sie sich von der Illusion des Verstehens und investieren Sie voll in den Wiederaufbau der grundlegenden Konzeptstruktur. Prüfen Sie Fehler nicht nur oberflächlich — gehen Sie den zugrunde liegenden Prinzipien ab heute intensiv auf den Grund. Verwandeln Sie diese Wachsamkeit in ein Sprungbrett für einen echten Aufschwung.',
      ],
      'RU': [
        'Вместо беспокойства воспримите это как сигнал к структурной перестройке учебных привычек. Откажитесь от иллюзии понимания и полностью посвятите себя восстановлению базовой концептуальной структуры. Не просто проверяйте ошибки — с сегодняшнего дня углубляйтесь в лежащие в основе принципы. Превратите эту тревогу в трамплин для настоящего подъёма.',
      ],
      'AR': [
        'بدلاً من القلق، اعتبر هذا إشارة إلى ضرورة إعادة هيكلة عادات الدراسة. تخلَّ عن وهم الفهم واستثمر جهدك بالكامل في إعادة بناء البنية المفاهيمية الأساسية. لا تكتفِ بمراجعة الأخطاء سطحيًا — تعمّق في المبادئ الأساسية ابتداءً من اليوم. حوّل هذا التنبيه إلى نقطة انطلاق لتحسن حقيقي.',
      ],
      'HI': [
        'चिंता करने के बजाय, इसे अध्ययन की आदतों में संरचनात्मक बदलाव की आवश्यकता का संकेत मानें। समझने के भ्रम को छोड़ें और मूल अवधारणा संरचना के पुनर्निर्माण में पूरी तरह जुट जाएं। गलतियों की सिर्फ जांच न करें — आज से ही अंतर्निहित सिद्धांतों में गहराई से उतरें। इस सतर्कता को वास्तविक सुधार का आधार बनाएं।',
      ],
      'VI': [
        'Thay vì lo lắng, hãy xem đây là tín hiệu cho thấy cần thay đổi cấu trúc thói quen học tập. Từ bỏ ảo tưởng đã hiểu và toàn tâm đầu tư xây dựng lại cấu trúc khái niệm cơ bản. Đừng chỉ kiểm tra lỗi sai qua loa — hãy đào sâu các nguyên lý nền tảng ngay từ hôm nay. Biến sự cảnh giác này thành bàn đạp cho một sự cải thiện thực sự.',
      ],
      'ES': [
        'En lugar de preocuparte, considera esto una señal de que los hábitos de estudio necesitan una reestructuración. Abandona la ilusión de haber entendido e invierte por completo en reconstruir la estructura conceptual básica. No te limites a revisar los errores superficialmente: profundiza en los principios subyacentes desde hoy. Convierte esta alerta en el trampolín para una mejora real.',
      ],
      'TH': [
        'แทนที่จะกังวล ควรมองว่านี่คือสัญญาณว่าต้องปรับโครงสร้างพฤติกรรมการเรียนใหม่ ละทิ้งภาพลวงตาว่าเข้าใจแล้ว และทุ่มเทสร้างโครงสร้างแนวคิดพื้นฐานขึ้นใหม่อย่างเต็มที่ อย่าแค่ตรวจข้อผิดพลาดผ่านๆ แต่ให้เจาะลึกหลักการพื้นฐานตั้งแต่วันนี้ เปลี่ยนความตื่นตัวนี้ให้เป็นจุดเริ่มต้นของการพลิกฟื้นที่แท้จริง',
      ],
    },
    'low': {
      'KO': [
        '기초가 흔들린 상태에서 문제 풀이에만 집착하는 것은 인지적 과부하를 가중시킬 뿐입니다. 조급한 마음을 완전히 가라앉히고, 단원별 교과서 핵심 원리 분석과 기본 어휘 스키마(지식의 구조적 네트워크) 빌딩에 즉각 착수하십시오. 기초부터 차근차근 벽돌을 쌓아 올린다면 성적은 반드시 정직하게 반응합니다. 나태해진 마음을 다잡고 오늘 밤부터 기초 평정 수치를 메우는 복습에 집중해 주십시오.',
        '현재 발생하는 대부분의 오답은 구조적 오인(개념의 기본 뼈대를 오해하는 현상)을 방치한 채 진도만 나간 부작용입니다. 지금 당장 멈추어 서서 취약 단원의 개념을 완벽히 소화하는 인내의 시간이 절대적으로 요구됩니다. 무기력함에 빠지지 말고, 베이스라인부터 다시 견고하게 다지겠다는 단단한 각오로 오늘부터 학습 속도와 밀도를 점진적으로 끌어올려 주십시오.',
      ],
      'EN': [
        'Pushing straight into more problems while the foundation is shaky only adds cognitive overload. Slow down, and start immediately with unit-by-unit textbook fundamentals and basic concept-building. Scores respond honestly to bricks laid one at a time from the ground up. Refocus tonight on filling the foundational gaps.',
        'Most of the current mistakes come from pushing through material while misunderstanding core concepts. Stop now and take the time needed to fully digest the weak units. Don\'t fall into discouragement — commit to rebuilding the baseline and gradually raising study pace and depth starting today.',
      ],
      'JA': [
        '基礎が揺らいでいる状態で問題演習にばかり執着するのは、認知的過負荷を加重するだけです。焦る気持ちを完全に落ち着かせ、単元別教科書の核心原理分析と基本語彙スキーマ（知識の構造的ネットワーク）構築に即座に着手してください。基礎からじっくり積み上げれば、成績は必ず正直に反応します。今夜から基礎固めの復習に集中してください。',
      ],
      'ZH': [
        '在基础尚不牢固的情况下一味执着于刷题，只会加重认知负荷。请彻底平复急躁的心态，立即着手逐单元梳理教材核心原理，构建基础词汇框架（知识的结构性网络）。只要从基础一步步扎实积累，成绩必然会诚实地作出回应。请从今晚开始专注于弥补基础的复习。',
      ],
      'FR': [
        'S\'acharner sur les exercices alors que les bases vacillent ne fait qu\'aggraver la surcharge cognitive. Calmez-vous complètement et commencez immédiatement par une analyse des principes fondamentaux, unité par unité. En construisant patiemment depuis la base, les résultats répondront honnêtement. Concentrez-vous dès ce soir sur le renforcement des fondamentaux.',
      ],
      'DE': [
        'Sich bei wackligen Grundlagen nur auf das Üben von Aufgaben zu versteifen, erhöht nur die kognitive Überlastung. Beruhigen Sie sich vollständig und beginnen Sie sofort mit einer einheitenweisen Analyse der Kernprinzipien. Wenn die Grundlagen Stein für Stein aufgebaut werden, reagieren die Noten ehrlich darauf. Konzentrieren Sie sich ab heute Abend auf die Grundlagenwiederholung.',
      ],
      'RU': [
        'Упорное решение задач при шатких основах лишь усиливает когнитивную перегрузку. Полностью успокойтесь и немедленно начните разбор ключевых принципов по разделам. Если выстраивать основы кирпичик за кирпичиком, результаты честно отреагируют. Сегодня же вечером сосредоточьтесь на повторении основ.',
      ],
      'AR': [
        'الإصرار على حل المزيد من المسائل بينما الأساس غير ثابت يزيد فقط من العبء الإدراكي. اهدأ تمامًا وابدأ فورًا بتحليل المبادئ الأساسية وحدة تلو الأخرى. عند بناء الأساس لبنة بلبنة، ستستجيب النتيجة بصدق. ركّز الليلة على مراجعة الأساسيات.',
      ],
      'HI': [
        'जब आधार ही कमजोर है, तो केवल अभ्यास प्रश्नों पर अड़े रहना केवल संज्ञानात्मक बोझ बढ़ाता है। पूरी तरह शांत हों और तुरंत यूनिट-दर-यूनिट मूल सिद्धांतों के विश्लेषण से शुरुआत करें। यदि आधार ईंट-दर-ईंट मजबूत किया जाए, तो स्कोर निश्चित रूप से ईमानदारी से प्रतिक्रिया देगा। आज रात से ही आधार को मजबूत करने वाले पुनरीक्षण पर ध्यान दें।',
      ],
      'VI': [
        'Khi nền tảng còn lung lay mà cứ cố làm thêm bài tập chỉ khiến quá tải nhận thức. Hãy bình tĩnh hoàn toàn và bắt đầu ngay việc phân tích nguyên lý cốt lõi theo từng chương. Khi xây nền tảng từng viên gạch một cách chắc chắn, điểm số chắc chắn sẽ phản ánh trung thực. Hãy tập trung củng cố nền tảng ngay từ tối nay.',
      ],
      'ES': [
        'Insistir en más ejercicios cuando la base aún es inestable solo aumenta la sobrecarga cognitiva. Cálmate por completo y comienza de inmediato con un análisis de los principios básicos unidad por unidad. Si construyes la base ladrillo a ladrillo, la puntuación responderá con honestidad. Concéntrate esta misma noche en repasar los fundamentos.',
      ],
      'TH': [
        'การมุ่งแต่ทำโจทย์ทั้งที่พื้นฐานยังไม่มั่นคงมีแต่จะเพิ่มภาระทางความคิด ควรใจเย็นลงอย่างเต็มที่และเริ่มวิเคราะห์หลักการสำคัญทีละหน่วยทันที หากค่อยๆ สร้างพื้นฐานอย่างมั่นคงทีละก้าว คะแนนจะตอบสนองอย่างซื่อตรงแน่นอน ตั้งแต่คืนนี้ควรตั้งใจทบทวนเพื่อเสริมพื้นฐานให้แข็งแรง',
      ],
    },
  };

  static const Map<String, String> _diagAdditionalGuidance = {
    'KO':
        ' [추가 정밀 권고] 현재 학습 체계의 임계점(성취도가 도약하기 위해 필요한 최소한의 학업 밀도)을 넘어서기 위해서는 절대 주관적인 타협이나 나태함에 빠져서는 안 됩니다. 스스로의 가능성을 신뢰하고 정합성 확인 루틴을 독하게 사수하십시오!',
    'EN':
        ' [Additional Guidance] To clear the critical threshold needed for the next jump in achievement, never settle for subjective compromise or complacency. Trust your own potential and hold firmly to the review-and-verify routine!',
    'JA':
        ' [追加精密アドバイス] 現在の学習体系の臨界点（成果が飛躍するために必要な最小限の学習密度）を超えるためには、決して主観的な妥協や怠慢に陥ってはいけません。自身の可能性を信じ、整合性確認ルーティンを徹底的に守り抜いてください！',
    'ZH':
        ' [额外精细建议] 要突破当前学习体系的临界点（成绩实现飞跃所需的最低学习密度），绝不能陷入主观妥协或懈怠。请相信自己的潜力，坚定地坚持这一巩固流程！',
    'FR':
        ' [Conseil supplémentaire] Pour franchir le seuil critique nécessaire à un bond de niveau, ne cédez jamais au compromis ou à la complaisance. Faites confiance à votre potentiel et maintenez fermement cette routine de vérification !',
    'DE':
        ' [Zusätzlicher Hinweis] Um die kritische Schwelle für den nächsten Leistungssprung zu überwinden, dürfen Sie sich niemals mit Kompromissen oder Nachlässigkeit zufriedengeben. Vertrauen Sie auf Ihr Potenzial und halten Sie konsequent an dieser Überprüfungsroutine fest!',
    'RU':
        ' [Дополнительная рекомендация] Чтобы преодолеть критический порог, необходимый для следующего скачка в успеваемости, никогда не идите на компромисс с собой и не позволяйте себе расслабляться. Верьте в свой потенциал и твёрдо придерживайтесь этой проверочной дисциплины!',
    'AR':
        ' [توصية إضافية] لتجاوز العتبة الحرجة اللازمة للقفزة التالية في التحصيل، لا تستسلم أبدًا للتنازل الذاتي أو التراخي. ثق بإمكاناتك والتزم بحزم بروتين المراجعة والتحقق هذا!',
    'HI':
        ' [अतिरिक्त सटीक सलाह] अगली उपलब्धि छलांग के लिए आवश्यक महत्वपूर्ण सीमा को पार करने के लिए, कभी भी व्यक्तिपरक समझौते या लापरवाही में न पड़ें। अपनी क्षमता पर भरोसा रखें और इस सत्यापन दिनचर्या को दृढ़ता से बनाए रखें!',
    'VI':
        ' [Lời khuyên bổ sung] Để vượt qua ngưỡng quan trọng cần thiết cho bước nhảy vọt tiếp theo về thành tích, đừng bao giờ thỏa hiệp chủ quan hay lơ là. Hãy tin vào tiềm năng của bản thân và kiên định duy trì thói quen xác minh này!',
    'ES':
        ' [Recomendación adicional] Para superar el umbral crítico necesario para el próximo salto en el rendimiento, nunca cedas a la complacencia ni al compromiso subjetivo. Confía en tu potencial y mantén con firmeza esta rutina de verificación.',
    'TH':
        ' [คำแนะนำเพิ่มเติมอย่างละเอียด] เพื่อก้าวข้ามจุดวิกฤตที่จำเป็นสำหรับการก้าวกระโดดของผลสัมฤทธิ์ครั้งต่อไป ห้ามยอมประนีประนอมหรือเผลอเลินเล่อเด็ดขาด จงเชื่อมั่นในศักยภาพของตนเองและรักษาวินัยการตรวจสอบนี้ไว้อย่างเคร่งครัด!',
  };

  // 🆕 [위험한 오류 수정 2026-09-05] "일일종합"/"일일상세"(오늘 학습 요약) 전용 문구 뱅크.
  // 기존 버그: 개념강의만 듣고 시험을 전혀 안 본 날에도 위의 _diagOpenings/_diagClosings(전부
  // "이번 평가에서 OO점..." 같은 시험 점수 전제 문구)이 그대로 사용되어, 강의만 들었는데
  // 마치 시험을 본 것처럼 엉뚱하고 위험한 진단문이 나오는 문제가 있었음.
  // 수정 내용: 오늘 요약은 "시험 점수"가 아니라 "목표 달성률"을 기준으로, 학습 습관/집중도에
  // 대한 문구만 사용하도록 완전히 별도의 뱅크로 분리함.
  static const Map<String, Map<String, List<String>>> _dailyDiagOpenings = {
    'good': {
      'KO': [
        '오늘 목표 달성률이 90%를 넘어선 것은 계획한 학습량을 흔들림 없이 소화해냈다는 뜻이며, 스스로 세운 기준을 지켜내는 자기주도 학습 습관이 확실히 자리잡고 있음을 보여주는 매우 고무적인 결과입니다. ',
      ],
      'EN': [
        "Reaching over 90% of today's study goal shows the plan was carried through without wavering, and that a genuinely self-directed study habit is taking firm hold. ",
      ],
    },
    'mid': {
      'KO': [
        '오늘 목표 달성률이 80%대에 도달한 것은 안정적인 학습 리듬을 갖추고 있다는 신호이며, 조금만 더 집중 시간을 늘리면 곧바로 최상위권 달성률에 닿을 수 있는 위치에 있습니다. ',
      ],
      'EN': [
        "Landing in the 80% range for today's goal signals a stable study rhythm, and just a bit more focused time could carry you to the very top. ",
      ],
    },
    'seventy': {
      'KO': [
        '오늘 목표 달성률이 70%대인 것은 학습을 시작은 했으나 계획한 만큼 끝까지 밀도 있게 이어가지 못했음을 나타냅니다. 다만 이 구간은 조금만 습관을 다듬으면 가장 크게 달성률이 뛰어오를 수 있는 구간이기도 합니다. ',
      ],
      'EN': [
        "A 70%-range goal attainment today means the session started but wasn't carried through with full intensity. This range, though, is exactly where a small habit tweak can produce the biggest jump. ",
      ],
    },
    'sixty': {
      'KO': [
        '오늘 목표 달성률이 60%대에 머문 것은 학습 계획과 실제 실행 사이에 다소 큰 간극이 있었음을 의미합니다. 이 자체를 자책하기보다는, 무엇이 학습 흐름을 방해했는지 되짚어보는 계기로 삼는 것이 더 중요합니다. ',
      ],
      'EN': [
        'Staying in the 60% range points to a real gap between the plan and what actually got done today. Rather than being hard on yourself, use this as a chance to notice what interrupted the flow. ',
      ],
    },
    'low': {
      'KO': [
        '오늘 목표 달성률이 60% 미만으로 나타난 것은 학습 루틴 자체를 처음부터 재정비할 필요가 있다는 신호입니다. 이런 날일수록 스스로를 다그치기보다는, 실현 가능한 아주 작은 목표부터 다시 세우는 것이 현실적인 해법입니다. ',
      ],
      'EN': [
        'Falling below 60% today is a sign the whole study routine may need a reset from the ground up. On days like this, setting a much smaller, genuinely achievable goal is the more realistic move than pushing harder. ',
      ],
    },
  };

  static const Map<String, Map<String, List<String>>> _dailyDiagClosings = {
    'good': {
      'KO': [
        '다만 이 페이스에 안주하지 말고, 내일도 오늘과 같은 밀도로 학습을 이어가려는 의식적인 노력이 필요합니다. 개념강의든 평가든 꾸준히 기록을 남기는 습관 자체가 장기적인 성장의 가장 확실한 토대가 되므로, 지금의 리듬을 그대로 유지해 나가시길 바랍니다.',
      ],
      'EN': [
        "Don't get too comfortable with this pace, though — keep making a conscious effort to hit the same density tomorrow. Whether it's a concept lecture or an evaluation, the habit of logging every session is the surest foundation for long-term growth, so keep this rhythm going.",
      ],
    },
    'mid': {
      'KO': [
        '남은 격차를 메우기 위해서는 학습 시작 시점의 집중 진입 속도를 조금 더 끌어올리는 것이 효과적입니다. 개념강의를 들었다면 핵심 내용을 스스로 요약해보고, 평가를 치렀다면 오답을 반드시 복기하는 습관을 더하면 다음 세션에서 100%에 근접한 결과를 기대할 수 있습니다.',
      ],
      'EN': [
        'To close the remaining gap, try speeding up how quickly you settle into focus at the start of a session. Summarize the key points after a lecture, and review mistakes carefully after an evaluation — that combination should push the next session close to 100%.',
      ],
    },
    'seventy': {
      'KO': [
        '학습 중간에 집중력이 흐트러지는 지점이 어디인지 스스로 점검해보고, 오늘처럼 개념강의나 평가를 기록으로 남기는 습관을 하루도 빠짐없이 이어가는 것이 중요합니다. 작은 꾸준함이 쌓이면 다음 세션부터는 달성률이 눈에 띄게 개선될 것입니다.',
      ],
      'EN': [
        'Take a moment to notice where concentration tends to slip mid-session, and keep logging every lecture or evaluation without skipping a day. Small consistency compounds quickly, and the next few sessions should show a noticeable improvement.',
      ],
    },
    'sixty': {
      'KO': [
        '목표 시간을 다소 낮춰서라도 매일 빠짐없이 기록을 남기는 것이, 무리한 목표를 세우고 중도에 포기하는 것보다 훨씬 효과적입니다. 개념강의를 들었다면 짧게라도 배운 내용을 적어보고, 평가를 봤다면 반드시 오답 원인을 확인하는 루틴부터 다시 세워보시기 바랍니다.',
      ],
      'EN': [
        'Logging something every single day, even with a lower target, beats setting an ambitious goal and giving up halfway. Jot down a few lines after a lecture, and make sure to review the cause of any mistakes after an evaluation — rebuilding that basic routine comes first.',
      ],
    },
    'low': {
      'KO': [
        '완벽한 하루를 만들려 하기보다, 하루 10분이라도 개념강의를 듣거나 짧은 평가를 기록하는 최소한의 습관부터 되찾는 것이 우선입니다. 작은 성공 경험이 쌓이면 학습 밀도는 자연스럽게 다시 올라가므로, 지금은 포기하지 않고 이어가는 것 자체에 의미를 두시길 바랍니다.',
      ],
      'EN': [
        "Rather than aiming for a perfect day, the priority is recovering the minimum habit — even ten minutes of a concept lecture or logging a short evaluation. Small wins rebuild momentum naturally, so what matters right now is simply not giving up.",
      ],
    },
  };

  static const Map<String, String> _dailyDiagAdditionalGuidance = {
    'KO':
        ' [참고] 이 요약은 오늘 하루의 학습 세션(강의/평가) 기록을 바탕으로 자동 생성된 것이며, 특정 시험 점수와는 무관합니다. 꾸준한 기록이 쌓일수록 분석의 정확도가 높아집니다.',
    'EN':
        " [Note] This summary is generated from today's logged study sessions (lectures/evaluations) and is not tied to any specific exam score. The more consistently you log sessions, the more accurate this analysis becomes.",
  };

  String _buildRuleBasedDiagnosisText({
    required String type,
    required double score,
    required String subject,
  }) {
    final random = math.Random();
    final String lang = DkeLang.current;
    // 🆕 [위험한 오류 수정 2026-09-05] "일일종합"/"일일상세"는 시험 점수 전제 문구가 아니라
    // 목표 달성률 기반의 학습 습관 문구를 사용해야 함 (강의만 들은 날 오작동 방지)
    final bool isDailySummary = type == '일일종합' || type == '일일상세';

    String tier;
    if (score >= 90) {
      tier = 'good';
    } else if (score >= 80) {
      tier = 'mid';
    } else if (score >= 70) {
      tier = 'seventy';
    } else if (score >= 60) {
      tier = 'sixty';
    } else {
      tier = 'low';
    }

    final Map<String, Map<String, List<String>>> openingsBank = isDailySummary
        ? _dailyDiagOpenings
        : _diagOpenings;
    final Map<String, Map<String, List<String>>> closingsBank = isDailySummary
        ? _dailyDiagClosings
        : _diagClosings;
    final Map<String, String> guidanceBank = isDailySummary
        ? _dailyDiagAdditionalGuidance
        : _diagAdditionalGuidance;

    final List<String> openings =
        openingsBank[tier]![lang] ?? openingsBank[tier]!['EN']!;
    final List<String> closings =
        closingsBank[tier]![lang] ?? closingsBank[tier]!['EN']!;

    String diagnosisText =
        openings[random.nextInt(openings.length)] +
        closings[random.nextInt(closings.length)];

    if (diagnosisText.length < 350) {
      diagnosisText += guidanceBank[lang] ?? guidanceBank['EN']!;
    }
    return diagnosisText;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _warningAnimController.dispose();
    _subjectController.dispose();
    _unitController.dispose();
    _scoreController.dispose();
    _dailyTotalScrollController.dispose(); // 🆕 [데이터 연결] 신규 스크롤 컨트롤러 해제
    _monthScrollController.dispose(); // 🆕 [요청 2026-09-04] 월 선택 스크롤 컨트롤러 해제
    super.dispose();
  }

  void _showReportPopup(
    BuildContext context,
    String mainTitle,
    String content, {
    bool isTotalReport = false,
  }) {
    String finalContent = content;
    final activeExams = _allRecords.where((e) => e.type == "주평가").toList();
    // 🆕 [12개국 대응] 언어별로 제목 문구가 달라지므로 텍스트 매칭 대신 명시적 파라미터로 판별
    if (activeExams.isNotEmpty && isTotalReport) {
      String examSummary = _t('examSummaryHeader');
      for (var ex in activeExams) {
        examSummary += DkeLang.current == 'KO'
            ? "• ${ex.subject}(${ex.unit}): ${ex.score.toInt()}점\n"
            : "• ${ex.subject}(${ex.unit}): ${ex.score.toInt()}\n";
      }
      finalContent = content + examSummary;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _ThemeColors.premiumCardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _ThemeColors.brandGolden.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      scrollbarTheme: ScrollbarThemeData(
                        thumbColor: MaterialStateProperty.all(
                          _ThemeColors.brandGolden.withOpacity(0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            mainTitle,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            maxLines: 1,
                            style: DkeLang.current == 'KO'
                                ? GoogleFonts.notoSansKr(
                                    color: _ThemeColors.brandGolden,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 23,
                                  )
                                : GoogleFonts.gowunBatang(
                                    color: _ThemeColors.brandGolden,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white60),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    color: Colors.white10,
                    height: 20,
                    thickness: 1.2,
                  ),
                  Text(
                    finalContent,
                    style: GoogleFonts.notoSansKr(
                      color: Colors.white,
                      fontSize: 14.5,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 🆕 [선배님 지시 완료]: 당근과 채찍 + 전문적 주석 해설 알고리즘이 내장된 150자 이상 분석 팝업 개설
  Future<void> _showDetailAnalysisPopup(String type) async {
    final filtered = _getFilteredRecords(type);
    String diagnosisText = "";

    if (filtered.isEmpty) {
      diagnosisText = _t('emptyFallbackLong');
    } else {
      final lastExam = filtered.last;
      diagnosisText = await _generateOrReuseDiagnosis(
        type: type,
        score: lastExam.score,
        subject: lastExam.subject,
        tier: AiTier.pro, // 정밀 진단서는 고난도 상담 성격 -> AI Pro 배정 예정
      );
    }

    _showReportPopup(context, _t('diagReportTitle'), diagnosisText);
  }

  void _showFeedbackRegistrationDialog({
    required String type,
    required String subject,
    required String unit,
    required double score,
    required int grade,
    required int semester,
  }) {
    final TextEditingController durationController = TextEditingController(
      text: "45분",
    );
    final TextEditingController mockMonthController = TextEditingController(
      text: "6월",
    );
    final TextEditingController mockRankController = TextEditingController(
      text: "1등급",
    );

    String difficulty = "보통";
    int rating = 5;
    List<String> selectedCauses = ["개념부족"];
    String reviewStatus = "필요";

    final List<String> diffOptions = ["매우쉬움", "쉬움", "보통", "어려움", "매우어려움"];
    final List<String> causeOptions = [
      "개념부족",
      "계산실수",
      "시간부족",
      "문해력 부족",
      "긴장",
      "집중력 부족",
      "기타",
    ];
    final List<String> reviewOptions = ["필요", "예정", "불필요"];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            return Dialog(
              backgroundColor: _ThemeColors.premiumCardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _ThemeColors.brandGolden.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Exam Evaluation Settings",
                                  overflow: TextOverflow.fade,
                                  softWrap: false,
                                  maxLines: 1,
                                  style: GoogleFonts.gowunBatang(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  type == "모의고사"
                                      ? _t('mockDiagTitle')
                                      : _t('examDiagTitle'),
                                  overflow: TextOverflow.fade,
                                  softWrap: false,
                                  maxLines: 1,
                                  style: GoogleFonts.notoSansKr(
                                    color: _ThemeColors.brandGolden,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white60,
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10, height: 16),

                      if (type == "모의고사") ...[
                        Text(
                          _t('mockMonthLabel'),
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          maxLines: 1,
                          style: GoogleFonts.notoSansKr(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: mockMonthController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.black26,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.white12,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: _ThemeColors.brandGolden,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _t('mockRankLabel'),
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          maxLines: 1,
                          style: GoogleFonts.notoSansKr(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: mockRankController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.black26,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.white12,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: _ThemeColors.brandGolden,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      Text(
                        _t('label1Duration'),
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        maxLines: 1,
                        style: GoogleFonts.notoSansKr(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: durationController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.black26,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: _ThemeColors.brandGolden,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text(
                        _t('label2Difficulty'),
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        maxLines: 1,
                        style: GoogleFonts.notoSansKr(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: diffOptions.map((d) {
                          bool isSel = difficulty == d;
                          return ChoiceChip(
                            label: Text(
                              _difficultyLabel(d),
                              style: TextStyle(
                                color: isSel ? Colors.black : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: _ThemeColors.brandGolden,
                            backgroundColor: Colors.black38,
                            onSelected: (bool selected) {
                              if (selected) setPopupState(() => difficulty = d);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      Text(
                        _t('label3Satisfaction'),
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        maxLines: 1,
                        style: GoogleFonts.notoSansKr(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (index) {
                          int currentStarWeight = index + 1;
                          bool isActive = currentStarWeight <= rating;
                          return GestureDetector(
                            onTap: () =>
                                setPopupState(() => rating = currentStarWeight),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: Icon(
                                Icons.star_rounded,
                                color: isActive
                                    ? _ThemeColors.brandGolden
                                    : Colors.white24,
                                size: 28,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 14),

                      Text(
                        _t('label4ErrorMulti'),
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        maxLines: 1,
                        style: GoogleFonts.notoSansKr(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: causeOptions.map((cause) {
                            bool isChecked = selectedCauses.contains(cause);
                            return CheckboxListTile(
                              title: Text(
                                _causeLabel(cause),
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              value: isChecked,
                              dense: true,
                              activeColor: _ThemeColors.brandGolden,
                              checkColor: Colors.black,
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (bool? checked) {
                                setPopupState(() {
                                  if (checked == true) {
                                    if (!selectedCauses.contains(cause))
                                      selectedCauses.add(cause);
                                  } else {
                                    selectedCauses.remove(cause);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text(
                        _t('label5ReviewSelect'),
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        maxLines: 1,
                        style: GoogleFonts.notoSansKr(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: reviewOptions.map((r) {
                          bool isSel = reviewStatus == r;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: ChoiceChip(
                              label: Text(
                                _reviewLabel(r),
                                style: TextStyle(
                                  color: isSel ? Colors.black : Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              selected: isSel,
                              selectedColor: _ThemeColors.brandGolden,
                              backgroundColor: Colors.black38,
                              onSelected: (bool selected) {
                                if (selected)
                                  setPopupState(() => reviewStatus = r);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _ThemeColors.brandGolden,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            String finalUnitLabel = unit;
                            if (type == "모의고사") {
                              finalUnitLabel =
                                  "${mockMonthController.text} ${_examTypeLabel("모의고사")} (${mockRankController.text})";
                            }

                            final newRecord = _ExamRecord(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              type: type,
                              grade: grade,
                              semester: semester,
                              date: DateTime.now(),
                              subject: subject,
                              unit: finalUnitLabel,
                              score: score,
                              durationText: durationController.text,
                              difficultyLevel: difficulty,
                              starSatisfaction: rating,
                              errorCauses: List.from(selectedCauses),
                              reviewRequired: reviewStatus,
                              mockMonth: type == "모의고사"
                                  ? mockMonthController.text
                                  : "",
                              mockRank: type == "모의고사"
                                  ? mockRankController.text
                                  : "",
                            );

                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString(
                              'dke_parent_shared_type',
                              type,
                            );
                            await prefs.setString(
                              'dke_parent_shared_subject',
                              subject,
                            );
                            await prefs.setDouble(
                              'dke_parent_shared_score',
                              score,
                            );
                            await prefs.setString(
                              'dke_parent_shared_duration',
                              durationController.text,
                            );
                            await prefs.setString(
                              'dke_parent_shared_difficulty',
                              difficulty,
                            );

                            setState(() {
                              _allRecords.add(newRecord);
                              _lastSavedRecordForDisplay = newRecord;
                              _subjectController.clear();
                              _unitController.clear();
                              _scoreController.clear();
                            });
                            await _persistExamRecords(); // 🆕 [데이터 연결] 새로 입력한 성적 기록을 즉시 영구 저장

                            Navigator.pop(ctx);
                            FocusScope.of(context).unfocus();
                          },
                          child: Text(
                            _t('confirmBtn'),
                            style: GoogleFonts.notoSansKr(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBeautifulFeedbackDisplayPanel() {
    if (_lastSavedRecordForDisplay == null) {
      return const SizedBox.shrink();
    }

    final rec = _lastSavedRecordForDisplay!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ThemeColors.premiumCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _ThemeColors.brandGolden.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent Exam Metric Analysis",
            overflow: TextOverflow.fade,
            softWrap: false,
            maxLines: 1,
            style: GoogleFonts.gowunBatang(
              color: Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            "${_t('recentFeedbackPrefix')} ${rec.type} ${_t('achievementFeedbackMetrics')}",
            overflow: TextOverflow.fade,
            softWrap: false,
            maxLines: 1,
            style: GoogleFonts.notoSansKr(
              color: _ThemeColors.brandGolden,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DkeLang.current == 'KO'
                ? "${_t('targetSubjectLabel')}: ${rec.subject} (${rec.unit}) | ${_t('scoreLabel')}: ${rec.score.toInt()}점"
                : "${_t('targetSubjectLabel')}: ${rec.subject} (${rec.unit}) | ${_t('scoreLabel')}: ${rec.score.toInt()}",
            overflow: TextOverflow.fade,
            softWrap: false,
            maxLines: 1,
            style: GoogleFonts.notoSansKr(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),

          _buildMetricDisplayItem(
            _t('label1DurationShort'),
            rec.durationText,
            Icons.timer_outlined,
          ),
          _buildMetricDisplayItem(
            _t('label2DifficultyShort'),
            _difficultyLabel(rec.difficultyLevel),
            Icons.speed_outlined,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.star_outline_rounded,
                      color: _ThemeColors.brandGolden,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _t('label3SatisfactionShort'),
                      style: GoogleFonts.notoSansKr(
                        color: Colors.white70,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      Icons.star_rounded,
                      color: (i < rec.starSatisfaction)
                          ? _ThemeColors.brandGolden
                          : Colors.white12,
                      size: 14,
                    );
                  }),
                ),
              ],
            ),
          ),

          _buildMetricDisplayItem(
            _t('label4ErrorShort'),
            rec.errorCauses.map(_causeLabel).join(", "),
            Icons.report_problem_outlined,
          ),
          _buildMetricDisplayItem(
            _t('label5ReviewShort'),
            _reviewLabel(rec.reviewRequired),
            Icons.flaky_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricDisplayItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: _ThemeColors.brandGolden, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.notoSansKr(
                  color: Colors.white70,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.fade,
              softWrap: false,
              maxLines: 1,
              textAlign: TextAlign.right,
              style: GoogleFonts.notoSansKr(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 🆕 [장학금 방 2026-09-17] "실시간 학습 현황" 카드 — 화면 맨 아래, 이미 로드된
  // 오늘의 데이터(레벨/별/오늘 학습시간)를 컬러풀하고 고급스럽게 다시 보여주는 요약 카드.
  // 새 데이터를 따로 불러오지 않고 이 화면이 이미 갖고 있는 상태값을 그대로 재사용합니다.
  // ============================================================================
  Widget _buildLiveStatusCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF11192E), Color(0xFF0A0F1E)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _ThemeColors.brandGolden.withOpacity(0.35),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: _ThemeColors.brandGolden.withOpacity(0.12),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(
              () => _isLiveStatusCardExpanded = !_isLiveStatusCardExpanded,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: _ThemeColors.brandGolden,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _t('liveStatusCardTitle'),
                      style: GoogleFonts.notoSansKr(
                        color: _ThemeColors.brandGolden,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(
                    _isLiveStatusCardExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _ThemeColors.brandGolden,
                  ),
                ],
              ),
            ),
          ),
          if (_isLiveStatusCardExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildLiveStatusMiniStat(
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFFFD700),
                      label: _t('cumulative'),
                      value: "$_totalStars${_t('starsUnitSuffix')}",
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLiveStatusMiniStat(
                      icon: Icons.military_tech_rounded,
                      iconColor: const Color(0xFF60A5FA),
                      label: _t('levelPrefix'),
                      value: "Lv.$_currentLevelNumber",
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLiveStatusMiniStat(
                      icon: Icons.timer_outlined,
                      iconColor: const Color(0xFF34C759),
                      label: _t('daily'),
                      value:
                          "$_todayTotalStudyMinutes${_t('minutesUnitSuffix')}",
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveStatusMiniStat({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.notoSansKr(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.notoSansKr(
              color: Colors.white54,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 🆕 [장학금 방 2026-09-17] "나의 성취별 현황" 카드 — 이번 달 기본별/보너스별을
  // 항목별로 나열해서 학생이 "무엇을 하면 별이 쌓이는지" 직접 눈으로 확인하고
  // 성취감·동기부여를 느끼도록 만든 카드. 안내문은 별도 버튼으로 펼쳐볼 수 있게 구성.
  // ============================================================================
  Widget _buildAchievementStarsCard() {
    final int monthlyTotal =
        _scholarshipMonthlyBaseStars + _scholarshipMonthlyBonusStars;
    final List<Color> bonusColors = [
      const Color(0xFFFF9500),
      const Color(0xFF34C759),
      const Color(0xFF60A5FA),
      const Color(0xFFAF52DE),
      const Color(0xFFFF3B30),
      const Color(0xFFFFCC00),
      const Color(0xFF5856D6),
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF11192E), Color(0xFF0A0F1E)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _ThemeColors.brandGolden.withOpacity(0.35),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: _ThemeColors.brandGolden.withOpacity(0.12),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(
              () => _isAchievementStarsCardExpanded =
                  !_isAchievementStarsCardExpanded,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: _ThemeColors.brandGolden,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _biT('achievementStarsCardTitle'),
                  style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Icon(_isAchievementStarsCardExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: _ThemeColors.brandGolden),
                ],
              ),
            ),
          ),
          if (_isAchievementStarsCardExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _isScholarshipDataLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: _ThemeColors.brandGolden,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 이번 달 총합 요약
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _ThemeColors.brandGolden.withOpacity(0.18),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _ThemeColors.brandGolden.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_biT('monthlyTotalStarsLabel'), style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 11.5)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _starsText(monthlyTotal),
                                    style: GoogleFonts.notoSansKr(
                                      color: _ThemeColors.brandGolden,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFD700),
                                size: 30,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 기본별 / 보너스별 구분
                        Row(
                          children: [
                            Expanded(
                              child: _buildLiveStatusMiniStat(
                                icon: Icons.wb_sunny_rounded,
                                iconColor: const Color(0xFFFFCC00),
                                label: _biT('todayBaseStarsLabel'),
                                value: _starsText(_todayTotalStudyMinutes),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildLiveStatusMiniStat(
                                icon: Icons.timer_outlined,
                                iconColor: const Color(0xFF34C759),
                                label: _biT('monthlyBaseStarsLabel'),
                                value: _starsText(_scholarshipMonthlyBaseStars),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildLiveStatusMiniStat(
                                icon: Icons.auto_awesome_rounded,
                                iconColor: const Color(0xFFAF52DE),
                                label: _biT('bonusStarsLabel'),
                                value: _starsText(_scholarshipMonthlyBonusStars),
                              ),
                            ),
                          ],
                        ),

                        if (_scholarshipBonusBreakdown.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(_biT('bonusBreakdownTitle'), style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ..._scholarshipBonusBreakdown.entries
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) {
                                final int idx = entry.key;
                                final String typeKey = entry.value.key;
                                final int count = entry.value.value;
                                final String label = _bonusLabel(typeKey);
                                final int perEvent =
                                    _bonusTypeStarAmount[typeKey] ?? 0;
                                final Color chipColor =
                                    _bonusTypeColorMap[typeKey] ?? _ThemeColors.brandGolden;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 3.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: chipColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "$label (+$perEvent × ${_timesText(count)})",
                                          style: GoogleFonts.notoSansKr(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "+${perEvent * count}",
                                        style: GoogleFonts.notoSansKr(
                                          color: chipColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                        ],

                        // 🆕 [실시간 장학금 금액 2026-09-17] 부모님이 선택한 유형 기준으로
                        // 계산된 최종 금액만 실시간 표시. 별 단가(원/별)는 학생 화면에 노출하지 않음.
                        if (_myLinkCode != null) ...[
                          const SizedBox(height: 14),
                          _buildLiveScholarshipAmount(),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _ThemeColors.brandGolden.withOpacity(
                                  0.6,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _showScholarshipNoticeDialog,
                            icon: const Icon(
                              Icons.info_outline_rounded,
                              color: _ThemeColors.brandGolden,
                              size: 16,
                            ),
                            label: Text(_biT('howToEarnStarsBtn'), style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontSize: 12.5, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  // 🆕 [실시간 장학금 금액 2026-09-17] 부모님이 이번 달 선택한 유형을 Firestore에서 실시간
  // 구독해서, 그 유형 기준 최종 금액만 계산해 보여줍니다. 별 단가·계산식은 노출하지 않고
  // 최종 금액 한 줄만 표시합니다.
  Widget _buildLiveScholarshipAmount() {
    final String monthKey =
        '${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}';
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FamilyLinkService.watch(_myLinkCode!),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !(snapshot.data?.exists ?? false)) {
          return const SizedBox.shrink();
        }
        final Map<String, dynamic> data = snapshot.data!.data() ?? {};
        final Map<String, dynamic> typeSelections = Map<String, dynamic>.from(
          (data['scholarshipTypeSelections'] as Map?) ?? {},
        );
        final String? typeKey = typeSelections[monthKey] as String?;
        final ScholarshipType? type = ScholarshipService.typeFromKey(typeKey);

        if (type == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _biT('typeNotSelectedYet'),
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 12, height: 1.5),
            ),
          );
        }

        final int monthlyTotal =
            _scholarshipMonthlyBaseStars + _scholarshipMonthlyBonusStars;
        final int amount = ScholarshipService.calculateAmountWon(
          monthlyTotalStars: monthlyTotal,
          type: type,
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _ThemeColors.brandGolden.withOpacity(0.18),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _ThemeColors.brandGolden.withOpacity(0.4),
            ),
          ),
          child: Column(
            children: [
              Text(_typeTitleLine(type.index), textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, height: 1.4)),
              const SizedBox(height: 8),
              Text(
                ScholarshipCurrency.amountText(monthlyTotal, type.index), // 🆕 [2026-09-27] 언어별 화폐 자동 전환
                style: GoogleFonts.notoSansKr(
                  color: _ThemeColors.brandGolden,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🆕 [장학금 방 2026-09-17] 학생용 안내문 팝업.
  // 🆕 [장학금 방 2026-09-17] 학생용 안내문 팝업. 별을 왜/어떻게 모으는지 설명해서
  // 성취감과 동기부여를 만드는 것이 목적. (안내문 문구는 원장님이 작성하신 것을 그대로 반영)
  void _showScholarshipNoticeDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: _ThemeColors.premiumCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 560),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _ThemeColors.brandGolden.withOpacity(0.35),
              width: 1.3,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(_t('scholarshipNoticeTitle'), style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 17)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 18),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    _scholarshipStudentNoticeText,
                    style: GoogleFonts.notoSansKr(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.7,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 [다국어 2026-09-18] 언어별 안내문 맵. 'KO'/'EN'은 확정 완료.
  // 나머지 10개(JA/ZH/FR/DE/RU/AR/HI/VI/ES/TH)는 원장님이 번역해서
  // 큰따옴표 3개(''') 사이에 그대로 채워 넣으시면 됩니다.
  static const Map<String, String> _scholarshipStudentNoticeByLang = {
    'KO': '''
나의 공부가 기록되고, 나의 성장이 성취가 됩니다.

GKE StudyUp은 누가 시켜서 공부하는 것이 아니라 내가 스스로 계획하고 실천하는 힘을 키우기 위한 학습 플랫폼입니다.

내가 공부한 시간, 학습을 실천한 과정, 학습기록과 평가를 남긴 활동은 별로 기록됩니다. 별은 단순한 점수가 아닙니다.

⭐ 별은 내가 스스로 공부한 흔적입니다.

⭐ 어떻게 별을 받을 수 있을까요?

1. 학습시간
1분 학습 = 1별
꾸준히 공부할수록 나의 학습 기록이 쌓입니다.

2. 학습 실천
-타이머 학습을 70% 이상 달성하면 +10별 
-학습을 마친 후 학습기록을 작성하면 +10별 
- 일일 50분이상 학습시 50별 
- 1주 일요일 부터 토요일까지 빠짐없는 학습 300별 
- 1달 빠짐없이 학습시 1000별

3. 학습평가와 기록
· 주간평가 기록 → +10별
· 단원평가 기록 → +10별
· 중간고사 기록 → +50별
· 기말고사 기록 → +50별
· 모의고사 기록 → +50별

시험 점수가 높다고 별을 받는 것이 아닙니다. 시험 결과를 기록하고, 내가 무엇을 잘했고 무엇을 보완해야 하는지 돌아보는 과정도 중요한 학습이라고 생각하기 때문입니다.

4. 꾸준함 보너스
· 하루 50분 이상 타이머가 작동하여 학습하면 → +50별 (일일 출석 보너스)
· 일주일(일요일~토요일) 동안 빠짐없이 매일 타이머가 작동하여 학습하면 → +300별 (주간 개근 보너스)
· 한 달 동안 빠짐없이 매일 타이머가 작동하여 학습하면 → +1,000별 (월간 개근 보너스)

꾸준함 보너스는 앱을 그냥 열어본 것이 아니라, 반드시 타이머가 실제로 작동하여 학습한 시간만을 기준으로 합니다. 하루하루 빠짐없이 이어가는 것 자체가 소중한 성취이기 때문입니다.

🌱 성장형 — "나는 공부 습관을 만들어 가고 있어요."
처음부터 많은 것을 할 필요는 없습니다. 
매일 조금씩이라도 스스로 공부하고, 
학습을 기록하고, 
꾸준히 실천하는 것이 중요합니다. 
성장형은 공부를 시작하고 좋은 학습습관을 만들어 가는 단계입니다.

🔥 도전형 — "조금 더 높은 목표에 도전해 볼래요."
학습습관이 만들어졌다면 이제 한 단계 더 도전해 보세요. 
학습목표를 세우고 실천하면서 나의 학습량과 자기관리 능력을 높여갑니다. 
도전형은 스스로 목표를 세우고 적극적으로 실천하는 단계입니다.

🏆 성취형 — "내가 세운 목표를 스스로 이루어 가고 있어요."
꾸준한 학습뿐만 아니라 학습계획 → 실천 → 기록 → 평가 → 보완 의 
과정을 스스로 관리해 보세요. 
성취형은 자기주도 학습을 꾸준히 실천하고 자신의 학습을 관리하는 단계입니다.

유형의 핵심은 돈이 아닙니다. 내가 얼마나 스스로 성장하고 있는가가 중요합니다.

🎯 기억하세요!
공부는 남과 경쟁하기 위한 것이 아닙니다. 
어제의 나보다 오늘의 내가 조금 더 성장하고, 
오늘의 나보다 내일의 내가 조금 더 발전하는 것입니다.

오늘 10분 더 공부했다면 그것도 성장입니다.
오늘 학습기록을 남겼다면 그것도 성장입니다.
시험 결과를 돌아봤다면 그것도 성장입니다.

작은 실천이 모이면 습관이 되고, 습관이 모이면 실력이 되고, 실력이 모이면 성취가 됩니다.

⭐ 나의 공부는 내가 만들어 갑니다.
계획하고 → 실천하고 → 기록하고 → 돌아보고 → 다시 도전하세요.

GKE StudyUp
Global Knowledge Education
''',
    'EN': '''
Your effort is recorded, and your growth becomes an achievement.

GKE StudyUp isn't a platform where you study because someone tells you to — it's here to help you build the power to plan and act on your own.

The time you study, the effort you put in, and the records and evaluations you leave behind are all recorded as stars. Stars aren't just points.

⭐ Stars are the trace of your own self-directed study.

⭐ How do I earn stars?

1. Study Time
1 minute of study = 1 star
The more consistently you study, the more your record grows.

2. Study Practice
Complete 70% or more of a timer session → +10 stars
Write a study record after finishing → +10 stars

3. Assessments and Records
· Weekly assessment logged → +10 stars
· Unit test logged → +10 stars
· Midterm exam logged → +50 stars
· Final exam logged → +50 stars
· Mock exam logged → +50 stars

You don't earn stars for a high score. You earn them for the act of recording your results and reflecting on what you did well and what you can improve — because that reflection is meaningful learning too.

4. Consistency Bonuses
· Study 50+ minutes in a day with the timer actually running → +50 stars (Daily Attendance Bonus)
· Study every single day for a full week (Sunday–Saturday) with the timer running → +300 stars (Weekly Perfect Attendance Bonus)
· Study every single day for a full month with the timer running → +1,000 stars (Monthly Perfect Attendance Bonus)

Consistency bonuses are based only on time the timer actually ran — simply opening the app doesn't count. Showing up day after day, without missing one, is an achievement in itself.

🌱 Growth Type — "I'm building a study habit."
🔥 Challenge Type — "I want to aim a little higher."
🏆 Achievement Type — "I'm reaching the goals I set for myself."

The type isn't about the money. What matters is how much you're growing on your own.

🎯 Remember this!
Studying isn't about competing with others. It's about being a little better today than you were yesterday, and a little better tomorrow than you are today.

Studying 10 minutes longer today — that's growth.
Leaving a study record today — that's growth.
Reflecting on your exam results — that's growth too.

Small actions become habits. Habits become skill. Skill becomes achievement.

⭐ You are the one building your own study journey.
Plan → Act → Record → Reflect → Try again.

GKE StudyUp
Global Knowledge Education
''',
    // 🔽 원장님이 채워주실 자리 (10개국어) — 큰따옴표 3개 사이에 번역문을 그대로 붙여넣으시면 됩니다
    'JA': '''# 
  ⭐ GKE StudyUp 生徒向け奨学金のご案内

    ## **私の学びを記録し、私の成長を「できた」という成果へ。**

  GKE StudyUpは、誰かに言われたから勉強するためのものではありません。

  **自分で学習計画を立て、自分で実行し、自分自身の学びを育てていく力。**

  GKE StudyUpは、そんな**「自ら学ぶ力」**を身につけるための学習プラットフォームです。

  自分が勉強した時間、学習に取り組んだ過程、学習記録や振り返りを残した活動は、⭐星として記録されます。

  星は、単なる点数ではありません。

  ⭐ **星は、あなたが自分から学んだ証であり、努力してきた足跡です。**

  今日、もう一歩だけ勉強した。

  学習記録を残した。

  テストの結果を振り返った。

  次の学習について考え、計画を立てた。

  その一つひとつの行動が、あなたの学習成果として少しずつ積み重なっていきます。

  ---

  # ⭐ どうすれば星を獲得できるのでしょうか？

  ## 1. 学習時間

  ### **1分の学習 = 1つの星⭐**

  コツコツと学習を続けるほど、あなたの学習記録が積み重なっていきます。

  ---

  # 2. 学習への取り組み

  * **タイマー学習を70％以上達成 → ＋10個の星⭐**
  * **学習を終えた後に学習記録を残す → ＋10個の星⭐**
  * **1日に50分以上学習 → ＋50個の星⭐**
  * **1週間（日曜日から土曜日まで）毎日欠かさず学習 → ＋300個の星⭐**
  * **1か月間、毎日欠かさず学習 → ＋1,000個の星⭐**

  一日続けることは、小さな一歩。

  一週間続けることは、習慣への一歩。

  一か月続けることは、自分自身への大きな挑戦です。

  **一つひとつの「続けた」という経験が、あなたの成長につながっていきます。**

  ---

  # 3. 学習評価と記録

  * **週間評価の記録 → ＋10個の星⭐**
  * **単元テストの記録 → ＋10個の星⭐**
  * **中間テストの記録 → ＋50個の星⭐**
  * **期末テストの記録 → ＋50個の星⭐**
  * **模擬試験の記録 → ＋50個の星⭐**

  ## **テストの点数が高いから、星をもらえるわけではありません。**

  テストの結果を記録し、

  「自分は何ができたのか」

  「何をもっと頑張る必要があるのか」

  を振り返り、

  「次はどうすれば、もっと成長できるだろう？」

  と考える。

  その過程も、**大切な学びの一つ**だと私たちは考えています。

  勉強とは、ただ良い点数を取ることだけではありません。

  **自分自身を知り、昨日の自分より一歩前へ進むこと。**

  それもまた、学びなのです。

  ---

  # 🌱 成長型

  ## **「私は、少しずつ学習習慣を身につけています。」**

  最初から、たくさん勉強する必要はありません。

  毎日少しずつでも、自分から勉強する。

  学習したことを記録する。

  決めたことを、少しずつ続けてみる。

  その小さな積み重ねが、やがて大きな力になります。

  **成長型**は、学習を始め、良い学習習慣を少しずつ身につけていく段階です。

  ---

  # 🔥 挑戦型

  ## **「もう一つ上の目標に、挑戦してみよう。」**

  学習習慣が少しずつ身についてきたら、

  次は、もう一歩前へ進んでみましょう。

  自分で学習目標を決め、

  その目標に向かって一つずつ実行していく。

  その中で、学習量を高め、自分自身を管理する力を育てていきます。

  **挑戦型**は、自分で目標を設定し、積極的に行動していく段階です。

  ---

  # 🏆 達成型

  ## **「自分で決めた目標を、自分の力で一つずつ実現しています。」**

  ただ勉強を続けるだけではありません。

  自分の学びを、自分自身で管理してみましょう。

  ### **学習計画 → 実行 → 記録 → 振り返り → 改善**

  計画を立てる。

  実行する。

  記録する。

  結果を振り返る。

  そして、次の学習をより良くしていく。

  **達成型**は、自主的な学習を継続し、自分自身の学びを自分で管理していく段階です。

  ---

  # 🌱 → 🔥 → 🏆

  ## **私の学びは、こうして成長していきます。**

  ### 🌱 成長型

  ↓
  **学習を続ける習慣をつくる**

  ### 🔥 挑戦型

  ↓
  **より高い目標に挑戦する**

  ### 🏆 達成型

  ↓
  **自分で目標を決め、自分の力で達成していく**

  ---

  # **大切なのは、お金ではありません。**

  成長型、挑戦型、達成型。

  そのどの段階にいるかよりも、

  ## **「私は、どれだけ自分自身で成長しているだろう？」**

  ということが大切です。

  昨日より少し前へ。

  今日より明日へ。

  **一歩ずつ成長していくこと。**

  それがGKE StudyUpが大切にしている学びです。

  ---

  # 💰 では、星はどうなるのでしょうか？

  現在、GKE StudyUpでは、

  ### **⭐ 1つの星 = 2ウォン・3ウォン・4ウォン**

  として奨学金を計算します。

  ただし、星の一番大切な意味は、お金ではありません。

  ## **星は、あなたが学び、努力し、成長してきた記録です。**

  あなたが積み重ねてきた学習成果を保護者の方が確認し、

  その努力を応援する気持ちとして、奨学金を支給することができます。

  **奨学金の金額は、それぞれのご家庭の状況に応じて、保護者の方が決めます。**

  つまり、

  **星は、あなたの努力を記録するもの。**

  **奨学金は、その努力を応援するためのもの。**

  GKE StudyUpでは、この二つを大切に考えています。

  ---

  # 🎯 覚えておいてください。

  ## **勉強は、誰かと競争するためのものではありません。**

  昨日の自分より、

  今日の自分が少し成長すること。

  そして、

  今日の自分より、

  明日の自分がまた少し前へ進むこと。

  それが大切です。

  今日、10分長く勉強した。

  **それも成長です。**

  今日、学習記録を残した。

  **それも成長です。**

  テストの結果を振り返った。

  **それも成長です。**

  思うようにいかなかった学習を、もう一度計画し直した。

  **それも成長です。**

  ---

  ## **小さな行動が積み重なると、習慣になります。**

  ## **習慣が積み重なると、力になります。**

  ## **力が積み重なると、やがて成果になります。**

  ---

  # ⭐ 私の学びは、私自身がつくっていく。

  ### **計画する → 実行する → 記録する → 振り返る → もう一度挑戦する**

  誰かに言われるのを待つのではなく、

  自分で考え、

  自分で決め、

  自分で行動し、

  自分の成長を、自分で確かめていく。

  **あなたの学びは、あなた自身の手でつくっていくことができます。**

  ---

  GKE StudyUpは、皆さんが**自ら学ぶ力**を身につけ、

  自分自身の目標に向かって、

  一歩ずつ成長していけるように応援します。

  今日の小さな努力も、

  今日踏み出した小さな一歩も、

  決して無駄ではありません。

  その一つひとつが積み重なって、

  いつか振り返ったとき、

  **「あのとき、頑張ってよかった」**

  と思える自分につながっていきます。

  ---

  # 🌱 成長型 → 🔥 挑戦型 → 🏆 達成型

  ## **今日の小さな一歩が、明日の自分をつくります。**

  **GKE StudyUp**

  **Global Knowledge Education**
  ''', // 일본어
    'ZH': '''
# ⭐ GKE StudyUp 学生奖学金说明

## **让我的学习被记录，让我的成长成为成就。**

GKE StudyUp 不是一个让别人督促你学习的平台。

它希望帮助你培养一种更重要的能力：

**自己制定学习计划，自己付诸行动，并为自己的学习负责。**

你学习的时间、学习实践的过程，以及留下学习记录和学习评价的活动，都会被记录为⭐星星。

**星星，不只是一个数字，也不仅仅是一项分数。**

⭐ **星星，是你主动学习、努力成长的足迹。**

今天多学习了一点，
留下了一次学习记录，
认真回顾一次考试结果，
为下一阶段的学习制定计划……

每一次小小的行动，都会让你的学习成就一点一点累积起来。

---

# ⭐ 怎样才能获得星星？

## 1. 学习时间

### **学习1分钟 = 1颗星⭐**

坚持学习的时间越长，你的学习记录就会不断累积。

---

## 2. 学习实践

* **计时学习完成70%以上 → +10颗星⭐**
* **完成学习后填写学习记录 → +10颗星⭐**
* **每天学习50分钟以上 → +50颗星⭐**
* **一周从星期日到星期六，每天坚持学习、不间断 → +300颗星⭐**
* **一个月每天坚持学习、不间断 → +1,000颗星⭐**

坚持一天，是一次行动。

坚持一周，是一种习惯。

坚持一个月，是一次真正的自我挑战。

**每一次坚持，都是你成长的证明。**

---

# 3. 学习评价与记录

* **每周学习评价记录 → +10颗星⭐**
* **单元测评记录 → +10颗星⭐**
* **期中考试记录 → +50颗星⭐**
* **期末考试记录 → +50颗星⭐**
* **模拟考试记录 → +50颗星⭐**

### **考试分数高，并不是获得星星的唯一理由。**

因为我们认为：

记录考试结果，
回顾自己做得好的地方，
发现需要改进的地方，
思考下一步应该怎样学习，

这些过程本身，也是非常重要的学习。

**学习不仅仅是得到一个分数，更重要的是从每一次学习中认识自己，并不断进步。**

---

# 🌱 成长型

### **“我正在一步一步养成学习习惯。”**

一开始，不需要做很多。

每天哪怕只学习一点点，
自己主动学习，
认真留下学习记录，
坚持把计划付诸行动，

这些看似微小的事情，都会成为成长的开始。

**成长型**是开始学习，并逐渐建立良好学习习惯的阶段。

---

# 🔥 挑战型

### **“我要不要向更高的目标挑战一下？”**

当学习习惯逐渐形成之后，

现在，就向前再迈出一步吧。

制定自己的学习目标，
并一步一步付诸实践。

在这个过程中，不断提高自己的学习能力、学习量以及自我管理能力。

**挑战型**是主动设定目标，并积极付诸行动的阶段。

---

# 🏆 成就型

### **“我正在一步一步实现自己设定的目标。”**

不仅仅是坚持学习，

还要学会管理自己的整个学习过程：

### **学习计划 → 实践 → 记录 → 评价 → 改进**

自己制定计划，
自己付诸行动，
自己记录过程，
自己回顾结果，
再根据结果调整下一步的学习。

**成就型**是持续进行自主学习，并逐渐掌握自我学习管理能力的阶段。

---

# 🌱 → 🔥 → 🏆

## **我的学习，就是这样一步一步成长起来的。**

### 🌱 成长型

↓
**养成坚持学习的习惯**

### 🔥 挑战型

↓
**向更高的目标发起挑战**

### 🏆 成就型

↓
**自己设定目标，并一步一步实现目标**

---

# **类型的核心，不是钱。**

真正重要的是：

## **我正在成长多少？**

## **我是否比昨天的自己更进一步？**

每一个阶段，都代表着你正在成长。

---

# 💰 那么，星星有什么用呢？

目前，GKE StudyUp 的奖学金计算方式为：

### **⭐ 1颗星 = 2韩元、3韩元或4韩元**

但是，星星最重要的意义，**并不是金钱。**

**星星，是你学习、努力和成长的记录。**

你所积累的学习成果，可以由父母进行确认，并作为对你努力学习的鼓励，以奖学金的方式给予支持。

**奖学金的具体金额，由父母根据家庭实际情况自行决定。**

因此，

**星星记录的是你的努力，
奖学金体现的是父母对你的鼓励。**

---

# 🎯 请记住！

## **学习，不是为了与别人竞争。**

真正重要的是：

**今天的自己，比昨天的自己多成长一点；**

**明天的自己，又比今天的自己多进步一点。**

今天多学习了10分钟，

**这也是成长。**

今天认真留下了一次学习记录，

**这也是成长。**

认真回顾了一次考试结果，

**这也是成长。**

即使这一次学习没有达到预期，
重新制定计划，再一次开始，

**这同样是一种成长。**

---

## **小小的行动积累起来，会成为习惯。**

## **习惯积累起来，会成为能力。**

## **能力不断积累，最终会成为成就。**

---

# ⭐ 我的学习，由我自己创造。

### **制定计划 → 付诸实践 → 记录 → 回顾 → 再次挑战**

不要等待别人告诉你什么时候学习。

学会自己决定，
自己行动，
自己记录，
自己反思，
然后再次向目标出发。

**你的学习道路，由你自己一步一步走出来。**

---

GKE StudyUp 希望帮助每一位学生培养**自主学习的力量**，

让你能够朝着自己的目标，

**一步一步成长，
一天一天进步，
最终实现属于自己的成就。**

无论今天只是多学习了10分钟，
还是坚持完成了一整天的学习，

每一个小小的坚持，都值得被记录。

因为，

**今天的努力，也许只是一个小小的开始，
但它正在成为更好的自己的起点。**

---

# 🌱 成长型 → 🔥 挑战型 → 🏆 成就型

## **今天的小小行动，正在创造属于你的明天。**

**GKE StudyUp**
**Global Knowledge Education**
''', // 중국어
    'FR': '''# ⭐ GKE StudyUp – Présentation de la bourse d’études pour les élèves

    ## **Mes apprentissages sont enregistrés, et mes progrès deviennent des réussites.**

  GKE StudyUp n’est pas une plateforme où l’on étudie simplement parce que quelqu’un nous demande de le faire.

  C’est une plateforme d’apprentissage qui aide chaque élève à développer une capacité essentielle :

  **savoir se fixer ses propres objectifs, établir son propre plan d’apprentissage, passer à l’action et devenir acteur de son propre parcours.**

  Le temps que tu consacres à tes études, tes efforts, ton parcours d’apprentissage, ainsi que tes activités de suivi et d’évaluation sont enregistrés sous forme d’étoiles ⭐.

  Mais une étoile n’est pas simplement un nombre ou une note.

  ⭐ **Une étoile est la trace de tes efforts, de ton apprentissage et de ta volonté de progresser par toi-même.**

  Aujourd’hui, tu as étudié un peu plus.

  Tu as pris le temps d’enregistrer ton apprentissage.

  Tu as regardé tes résultats à un examen pour comprendre ce que tu pouvais améliorer.

  Tu as réfléchi à la suite et préparé ton prochain objectif.

  **Chacun de ces petits gestes fait grandir, petit à petit, ton parcours et tes réussites.**

  ---

  # ⭐ Comment gagner des étoiles ?

  ## 1. Temps d’apprentissage

  ### **1 minute d’apprentissage = 1 étoile ⭐**

  Plus tu apprends régulièrement, plus ton parcours d’apprentissage s’enrichit.

  ---

  # 2. Engagement dans les apprentissages

  * **Atteindre au moins 70 % d’une session d’apprentissage avec le minuteur → +10 étoiles ⭐**
  * **Rédiger une trace de son apprentissage après une session → +10 étoiles ⭐**
  * **Étudier au moins 50 minutes dans une journée → +50 étoiles ⭐**
  * **Étudier chaque jour pendant une semaine complète, du dimanche au samedi, sans interruption → +300 étoiles ⭐**
  * **Étudier chaque jour pendant un mois complet, sans interruption →+1 000 étoiles  ⭐**

  Un jour de persévérance est un petit pas.

  Une semaine de persévérance devient une habitude.

  Un mois de persévérance devient un véritable défi relevé par soi-même.

  **Chaque fois que tu continues malgré les difficultés, tu accumules bien plus que des étoiles : tu construis ta propre force.**

  ---

  # 3. Évaluation et suivi des apprentissages

  * **Évaluation hebdomadaire → +10 étoiles ⭐**
  * **Évaluation d’un chapitre ou d’une unité → +10 étoiles ⭐**
  * **Évaluation de mi-semestre → +50 étoiles ⭐**
  * **Évaluation de fin de semestre → +50 étoiles ⭐**
  * **Examen blanc / examen d’entraînement → +50 étoiles ⭐**

  ## **Les étoiles ne sont pas attribuées parce que tu as obtenu une bonne note.**

  Parce que nous pensons qu’il est tout aussi important de :

  consigner ses résultats,

  regarder ce que l’on a bien réussi,

  identifier ce qui doit encore être amélioré,

  et réfléchir à la manière de mieux apprendre la prochaine fois.

  **Ce processus de réflexion fait lui aussi partie de l’apprentissage.**

  Apprendre, ce n’est pas seulement obtenir une bonne note.

  **C’est aussi apprendre à mieux se connaître, comprendre ses erreurs et avancer un peu plus loin qu’hier.**

  ---

  # 🌱 Niveau Croissance

  ## **« Je suis en train de construire mes habitudes d’apprentissage. »**

  Tu n’as pas besoin de tout réussir dès le début.

  Tu n’as pas besoin d’étudier énormément dès le premier jour.

  Commence simplement par un petit pas.

  Étudier un peu chaque jour.

  Apprendre par toi-même.

  Garder une trace de tes apprentissages.

  Continuer, même lorsque les progrès semblent petits.

  **Le niveau Croissance** correspond à la période où tu commences à apprendre et où tu construis progressivement de bonnes habitudes de travail.

  ---

  # 🔥 Niveau Défi

  ## **« Et si je me fixais un objectif un peu plus ambitieux ? »**

  Lorsque tes habitudes d’apprentissage commencent à s’installer, il est temps d’aller un peu plus loin.

  Fixe-toi ton propre objectif.

  Travaille progressivement pour l’atteindre.

  En avançant, tu développes tes capacités d’apprentissage, ta régularité et ta capacité à gérer ton propre travail.

  **Le niveau Défi** correspond à l’étape où tu commences à te fixer tes propres objectifs et à agir activement pour les atteindre.

  ---

  # 🏆 Niveau Accomplissement

  ## **« Je réalise progressivement les objectifs que je me suis fixés. »**

  Il ne s’agit plus seulement d’étudier régulièrement.

  Il s’agit aussi d’apprendre à gérer ton propre parcours :

  ### **Planifier → Agir → Enregistrer → Évaluer → Améliorer**

  Je planifie.

  Je passe à l’action.

  Je garde une trace de mon travail.

  Je regarde ce que j’ai accompli.

  J’améliore ensuite ma façon d’apprendre.

  **Le niveau Accomplissement** représente une étape où l’on développe durablement son autonomie et où l’on apprend à gérer soi-même son parcours d’apprentissage.

  ---

  # 🌱 → 🔥 → 🏆

  ## **Mon apprentissage grandit ainsi, étape après étape.**

  ### 🌱 Niveau Croissance

  ↓
  **Construire des habitudes d’apprentissage régulières**

  ### 🔥 Niveau Défi

  ↓
  **Se fixer des objectifs plus ambitieux**

  ### 🏆 Niveau Accomplissement

  ↓
  **Se fixer ses propres objectifs et les réaliser**

  ---

  # **L’essentiel n’est pas l’argent.**

  Que tu sois au niveau Croissance, Défi ou Accomplissement, l’important n’est pas la somme que tu peux recevoir.

  La vraie question est :

  ## **« Est-ce que je grandis par moi-même ? »**

  Suis-je un peu plus avancé qu’hier ?

  Est-ce que j’ai fait aujourd’hui un pas que je n’avais pas encore fait hier ?

  **C’est cela qui donne du sens à ton apprentissage.**

  ---

  # 💰 Et que deviennent les étoiles ?

  Actuellement, chez GKE StudyUp, la bourse est calculée selon le principe suivant :

  ### **⭐ 1 étoile = 2, 3 ou 4 wons**

  Mais la signification la plus importante d’une étoile n’est pas l’argent.

  ## **Une étoile est la trace de tes efforts, de ton apprentissage et de ta progression.**

  Les résultats d’apprentissage que tu as accumulés peuvent être consultés par tes parents.

  En signe de reconnaissance et d’encouragement, tes parents peuvent alors décider de t’accorder une bourse en fonction de tes efforts et de tes progrès.

  **Le montant de la bourse est décidé par les parents, en fonction de la situation de chaque famille.**

  Ainsi, les étoiles et la bourse ont deux significations différentes :

  **Les étoiles enregistrent tes efforts et ta progression.**

  **La bourse représente l’encouragement et le soutien de tes parents.**

  ---

  # 🎯 N’oublie jamais !

  ## **Étudier, ce n’est pas une compétition avec les autres.**

  Ce qui compte, ce n’est pas d’être meilleur que quelqu’un d’autre.

  Ce qui compte, c’est que :

  **le toi d’aujourd’hui soit un peu plus avancé que le toi d’hier,**

  et que :

  **le toi de demain puisse aller encore un peu plus loin que celui d’aujourd’hui.**

  Tu as étudié 10 minutes de plus aujourd’hui.

  **C’est déjà un progrès.**

  Tu as pris le temps d’écrire ton apprentissage.

  **C’est aussi un progrès.**

  Tu as regardé honnêtement le résultat d’un examen.

  **C’est encore un progrès.**

  Tu n’as pas obtenu le résultat espéré et tu as recommencé à réfléchir à ton plan.

  **C’est aussi une forme de progrès.**

  ---

  ## **Les petits efforts deviennent des habitudes.**

  ## **Les habitudes deviennent des compétences.**

  ## **Les compétences deviennent des réussites.**

  ---

  # ⭐ **Mon apprentissage, c’est moi qui le construis.**

  ### **Planifier → Agir → Enregistrer → Réfléchir → Relever un nouveau défi**

  N’attends pas que quelqu’un te dise quand apprendre.

  Apprends à :

  penser par toi-même,

  faire tes propres choix,

      passer à l’action,

  observer tes progrès,

  et continuer à avancer.

  ## **Ton parcours d’apprentissage t’appartient.**

  Tu peux le construire toi-même, un pas après l’autre.

  ---

  GKE StudyUp souhaite aider chaque élève à développer **la force d’apprendre par lui-même**,

  à avancer vers ses propres objectifs,

  et à grandir progressivement, un pas après l’autre.

  Peut-être qu’aujourd’hui, ton effort ne représente qu’un petit pas.

  Peut-être que tu n’as étudié que dix minutes de plus.

  Peut-être que tu as simplement écrit ton prochain plan d’apprentissage.

  Peut-être que, malgré une difficulté, tu as décidé de recommencer.

  **Chacun de ces pas a de la valeur.**

  Car les petits pas que l’on continue de faire finissent par nous conduire beaucoup plus loin que l’on ne l’imaginait.

  Et un jour, en regardant le chemin parcouru, tu pourras peut-être te dire :

  ## **« Je suis heureux de ne pas avoir abandonné à ce moment-là. »**

  ---

  # 🌱 Niveau Croissance → 🔥 Niveau Défi → 🏆 Niveau Accomplissement

  ## **Le petit pas que tu fais aujourd’hui construit le toi de demain.**

  **GKE StudyUp**

  **Global Knowledge Education**
  ''', // 프랑스어

    'DE': '''# ⭐ GKE StudyUp – Informationen zum Schülerstipendium

    ## **Meine Lernzeit wird festgehalten. Mein Wachstum wird zu meinem Erfolg.**

  GKE StudyUp ist keine Plattform, auf der man lernt, weil jemand anderes es verlangt.

  GKE StudyUp möchte dir dabei helfen, eine wichtige Fähigkeit zu entwickeln:

  **selbst Lernziele zu setzen, einen eigenen Lernplan zu erstellen, ihn umzusetzen und Verantwortung für den eigenen Lernweg zu übernehmen.**

  Deine Lernzeit, dein Lernprozess sowie deine Lernaufzeichnungen und Reflexionen werden als ⭐ Sterne festgehalten.

  Ein Stern ist jedoch nicht einfach nur eine Zahl oder eine Punktzahl.

  ⭐ **Ein Stern ist ein Zeichen dafür, dass du selbst gelernt hast. Er ist ein Teil deiner persönlichen Lern- und Wachstumsgeschichte.**

  Heute ein bisschen mehr gelernt.

  Einen Lernfortschritt festgehalten.

  Ein Prüfungsergebnis in Ruhe betrachtet.

  Überlegt, wie es beim nächsten Mal weitergehen soll.

  Jeder dieser kleinen Schritte wird zu einem Teil deines persönlichen Lernerfolgs.

  ---

  # ⭐ Wie kann ich Sterne sammeln?

  ## 1. Lernzeit

  ### **1 Minute Lernen = 1 Stern ⭐**

  Je regelmäßiger du lernst, desto mehr wächst deine persönliche Lernaufzeichnung.

  ---

  # 2. Lernaktivitäten

  * **Mindestens 70 % einer Timer-Lerneinheit geschafft → +10 Sterne ⭐**
  * **Nach dem Lernen eine Lernaufzeichnung erstellen → +10 Sterne ⭐**
  * **Mindestens 50 Minuten an einem Tag lernen → +50 Sterne ⭐**
  * **Eine ganze Woche lang von Sonntag bis Samstag jeden Tag lernen → +300 Sterne ⭐**
  * **Einen ganzen Monat lang jeden Tag ohne Unterbrechung lernen → +1.000 Sterne ⭐**

  Ein Tag des Lernens ist ein kleiner Schritt.

  Eine Woche des Durchhaltens wird zu einer Gewohnheit.

  Ein ganzer Monat ist eine echte Herausforderung an dich selbst.

  **Jedes Mal, wenn du weitermachst, sammelst du nicht nur Sterne – du sammelst Erfahrungen, die dich wachsen lassen.**

  ---

  # 3. Lernbewertung und Aufzeichnungen

  * **Wöchentliche Lernbewertung → +10 Sterne ⭐**
  * **Dokumentation eines Unitests → +10 Sterne ⭐**
  * **Dokumentation einer Zwischenprüfung → +50 Sterne ⭐**
  * **Dokumentation einer Abschlussprüfung → +50 Sterne ⭐**
  * **Dokumentation einer Probeprüfung → +50 Sterne ⭐**

  ## **Du bekommst Sterne nicht einfach deshalb, weil du eine hohe Punktzahl erreichst.**

  Denn wir glauben:

  Es ist wichtig, ein Prüfungsergebnis festzuhalten.

  Zu überlegen, was gut gelungen ist.

  Zu erkennen, was noch verbessert werden kann.

  Und sich zu fragen:

  **„Was kann ich beim nächsten Mal anders oder besser machen?“**

  Auch dieser Prozess ist ein wichtiger Teil des Lernens.

  Lernen bedeutet nicht nur, eine gute Punktzahl zu erreichen.

  **Lernen bedeutet auch, sich selbst besser kennenzulernen und Schritt für Schritt weiterzukommen.**

  ---

  # 🌱 Wachstumsstufe

  ## **„Ich baue mir Schritt für Schritt gute Lerngewohnheiten auf.“**

  Du musst nicht von Anfang an besonders viel lernen.

  Schon ein wenig Lernen jeden Tag kann ein guter Anfang sein.

  Selbstständig lernen.

  Den eigenen Lernweg festhalten.

  Dranbleiben.

  Diese kleinen Schritte können mit der Zeit zu einer großen Stärke werden.

  **Die Wachstumsstufe** ist die Phase, in der du mit dem Lernen beginnst und nach und nach gute Lerngewohnheiten entwickelst.

  ---

  # 🔥 Herausforderungsstufe

  ## **„Ich möchte mich an einem etwas höheren Ziel versuchen.“**

  Wenn sich deine Lerngewohnheiten entwickelt haben, kannst du den nächsten Schritt wagen.

  Setze dir ein eigenes Lernziel.

  Arbeite Schritt für Schritt darauf hin.

  Dabei kannst du deine Lernmenge steigern und gleichzeitig lernen, dich selbst besser zu organisieren und zu führen.

  **Die Herausforderungsstufe** steht für den Schritt, bei dem du deine eigenen Ziele setzt und sie aktiv verfolgst.

  ---

  # 🏆 Erfolgsstufe

  ## **„Ich verwirkliche Schritt für Schritt die Ziele, die ich mir selbst gesetzt habe.“**

  Es geht nicht nur darum, regelmäßig zu lernen.

  Lerne, deinen eigenen Lernprozess selbst zu gestalten:

  ### **Lernplan → Umsetzung → Aufzeichnung → Bewertung → Verbesserung**

  Einen Plan erstellen.

  Ihn umsetzen.

  Den eigenen Weg festhalten.

  Das Ergebnis betrachten.

  Und daraus den nächsten Schritt entwickeln.

  **Die Erfolgsstufe** steht für kontinuierliches selbstständiges Lernen und die Fähigkeit, den eigenen Lernprozess immer mehr selbst zu steuern.

  ---

  # 🌱 → 🔥 → 🏆

  ## **So wächst mein Lernen Schritt für Schritt.**

  ### 🌱 Wachstumsstufe

  ↓
  **Gute und regelmäßige Lerngewohnheiten entwickeln**

  ### 🔥 Herausforderungsstufe

  ↓
  **Sich an höheren Zielen versuchen**

  ### 🏆 Erfolgsstufe

  ↓
  **Eigene Ziele setzen und sie selbst erreichen**

  ---

  # **Im Mittelpunkt steht nicht das Geld.**

  Ganz gleich, auf welcher Stufe du dich gerade befindest:

  Wichtig ist nicht, wie viel Geld du bekommen kannst.

  Wichtig ist die Frage:

  ## **„Wie sehr wachse ich aus eigener Kraft?“**

  Gestern ein wenig besser als gestern.

  Heute ein kleiner Schritt nach vorne.

  Morgen wieder ein Schritt weiter.

  **Genau darin liegt der Wert deines Lernens.**

  ---

  # 💰 Was passiert mit den Sternen?

  Bei GKE StudyUp wird das Stipendium derzeit nach folgendem Wert berechnet:

  ### **⭐ 1 Stern = 2, 3 oder 4 KRW**

  Doch die wichtigste Bedeutung eines Sterns ist nicht das Geld.

  ## **Ein Stern ist die Aufzeichnung deiner Anstrengung, deines Lernens und deiner Entwicklung.**

  Die von dir gesammelten Lernerfolge können von deinen Eltern eingesehen werden.

  Als Zeichen der Anerkennung und Ermutigung können Eltern auf Grundlage dieser Leistungen ein Stipendium vergeben.

  **Wie hoch das Stipendium ausfällt, entscheiden die Eltern entsprechend der persönlichen und familiären Situation.**

  Damit haben Sterne und Stipendium unterschiedliche Bedeutungen:

  **Die Sterne halten deine Anstrengungen und deine Entwicklung fest.**

  **Das Stipendium ist die Unterstützung und Ermutigung deiner Eltern für diesen Weg.**

  ---

  # 🎯 Denk daran!

  ## **Lernen bedeutet nicht, sich mit anderen zu vergleichen.**

  Wichtig ist nicht, ob du besser bist als jemand anderes.

  Wichtig ist,

  **dass dein heutiges Ich ein wenig weiter ist als dein gestriges Ich.**

  Und dass dein morgiges Ich wieder ein wenig weiterkommt als dein heutiges Ich.

  Du hast heute 10 Minuten länger gelernt.

  **Auch das ist Wachstum.**

  Du hast heute eine Lernaufzeichnung erstellt.

  **Auch das ist Wachstum.**

  Du hast dein Prüfungsergebnis ehrlich betrachtet.

  **Auch das ist Wachstum.**

  Etwas hat beim Lernen nicht funktioniert, und du hast deinen Plan neu gemacht.

  **Auch das ist Wachstum.**

  ---

  ## **Kleine Schritte werden zu Gewohnheiten.**

  ## **Gewohnheiten werden zu Fähigkeiten.**

  ## **Fähigkeiten werden zu Erfolgen.**

  ---

  # ⭐ **Mein Lernen gestalte ich selbst.**

  ### **Planen → Umsetzen → Aufzeichnen → Reflektieren → Erneut herausfordern**

  Warte nicht darauf, dass jemand dir sagt, wann du lernen sollst.

  Lerne,

  selbst zu denken,

  selbst zu entscheiden,

  selbst zu handeln

  und deinen eigenen Lernweg bewusst weiterzuentwickeln.

  ## **Dein Lernweg gehört dir.**

  Du kannst ihn Schritt für Schritt selbst gestalten.

  ---

  GKE StudyUp möchte dich dabei unterstützen, **die Kraft zum selbstständigen Lernen** zu entwickeln.

  Wir möchten dich dabei begleiten, deine eigenen Ziele zu verfolgen und Schritt für Schritt über dich hinauszuwachsen.

  Vielleicht war die heutige Anstrengung nur ein kleiner Schritt.

  Vielleicht waren es nur zehn zusätzliche Minuten.

  Vielleicht hast du heute einfach nur einen Lernplan geschrieben.

  Vielleicht hast du nach einem Rückschlag noch einmal neu angefangen.

  **Jeder dieser Schritte ist wertvoll.**

  Denn kleine Schritte, die immer wieder gegangen werden, können eines Tages zu etwas Großem werden.

  Und vielleicht wirst du eines Tages zurückblicken und sagen:

  ## **„Gut, dass ich damals nicht aufgegeben habe.“**

  ---

  # 🌱 Wachstumsstufe → 🔥 Herausforderungsstufe → 🏆 Erfolgsstufe

  ## **Der kleine Schritt, den du heute machst, gestaltet dein Morgen.**

  **GKE StudyUp**

  **Global Knowledge Education**
  ''', // 독일어

    'RU': '''# 
  ⭐ GKE StudyUp — Информация о стипендии для учащихся

    ## **Моя учёба сохраняется в истории, а мой рост превращается в достижения.**

  GKE StudyUp — это не платформа, где нужно учиться только потому, что кто-то заставляет тебя это делать.

  Это образовательная платформа, которая помогает развивать гораздо более важную способность:

  **самостоятельно ставить цели, планировать свою учёбу, действовать и постепенно брать ответственность за собственный путь обучения.**

  Время, которое ты посвящаешь учёбе, твои усилия, процесс обучения, учебные записи и результаты самооценки фиксируются в виде ⭐ звёзд.

  Но звезда — это не просто число и не обычная оценка.

  ⭐ **Звезда — это след твоих собственных усилий, доказательство того, что ты учишься сам и постепенно растёшь.**

  Сегодня ты позанимался немного дольше.

  Оставил запись о своей учёбе.

  Посмотрел на результат контрольной или экзамена и подумал, что можно улучшить.

  Запланировал следующий шаг.

  **Каждое такое небольшое действие постепенно становится частью твоего учебного пути и твоих достижений.**

  ---

  # ⭐ Как получить звёзды?

  ## 1. Время обучения

  ### **1 минута обучения = 1 звезда ⭐**

  Чем регулярнее ты учишься, тем больше становится твоя история обучения.

  ---

  # 2. Учебная практика

  * **Выполнить не менее 70% занятия по таймеру → +10 звёзд ⭐**
  * **После занятия сделать запись о своей учёбе → +10 звёзд ⭐**
  * **Учиться не менее 50 минут в день → +50 звёзд ⭐**
  * **Учиться каждый день в течение полной недели — с воскресенья по субботу, без пропусков → +300 звёзд ⭐**
  * **Учиться каждый день в течение целого месяца, без пропусков → +1 000 звёзд ⭐**

  Один день постоянства — это маленький шаг.

  Неделя постоянства постепенно становится привычкой.

  Месяц постоянства — это уже настоящий вызов самому себе.

  **Каждый раз, когда ты продолжаешь идти вперёд, ты собираешь не только звёзды — ты создаёшь собственную силу и уверенность в себе.**

  ---

  # 3. Оценка и записи об обучении

  * **Еженедельная оценка обучения → +10 звёзд ⭐**
  * **Запись о проверке знаний по разделу → +10 звёзд ⭐**
  * **Запись о промежуточном экзамене → +50 звёзд ⭐**
  * **Запись об итоговом экзамене → +50 звёзд ⭐**
  * **Запись о пробном экзамене → +50 звёзд ⭐**

  ## **Звёзды выдаются не за высокие оценки на экзаменах.**

  Потому что мы считаем важным не только сам результат.

  Важно:

  записать результат,

  посмотреть, что получилось хорошо,

  понять, что ещё нужно улучшить,

  и подумать:

  **«Что я могу сделать по-другому в следующий раз?»**

  Сам процесс размышления над своей учёбой — тоже важная часть обучения.

  Учёба — это не только хорошие оценки.

  **Учёба — это возможность лучше узнать себя, понять свои ошибки и сделать следующий шаг вперёд.**

  ---

  # 🌱 Уровень роста

  ## **«Я постепенно формирую свои учебные привычки».**

  Не нужно с самого начала делать всё идеально.

  Не нужно сразу заниматься много часов.

  Начни с маленького шага.

  Учись понемногу каждый день.

  Учись самостоятельно.

  Записывай то, что сделал.

  Старайся продолжать, даже когда результат пока кажется небольшим.

  **Уровень роста** — это этап, на котором ты начинаешь учиться и постепенно формируешь хорошие учебные привычки.

  ---

  # 🔥 Уровень вызова

  ## **«А смогу ли я поставить перед собой цель немного выше?»**

  Когда хорошая учебная привычка уже начинает формироваться, попробуй сделать следующий шаг.

  Поставь собственную цель.

  И постепенно двигайся к ней.

  В процессе ты будешь развивать свои учебные способности, увеличивать объём занятий и учиться лучше управлять своим временем и своими действиями.

  **Уровень вызова** — это этап, на котором ты самостоятельно ставишь цели и активно работаешь над их достижением.

  ---

  # 🏆 Уровень достижения

  ## **«Я постепенно достигаю целей, которые поставил перед собой».**

  Важно не только регулярно заниматься.

  Важно научиться самостоятельно управлять всем своим учебным процессом:

  ### **Планирование → Действие → Запись → Оценка → Улучшение**

  Сначала составить план.

  Затем действовать.

  Записать, что было сделано.

  Посмотреть на результат.

  И использовать этот опыт, чтобы сделать следующий этап обучения ещё лучше.

  **Уровень достижения** — это этап, на котором ты продолжаешь самостоятельно учиться и постепенно учишься управлять собственным учебным процессом.

  ---

  # 🌱 → 🔥 → 🏆

  ## **Так шаг за шагом растёт мой путь обучения.**

  ### 🌱 Уровень роста

  ↓
  **Формировать привычку регулярно учиться**

  ### 🔥 Уровень вызова

  ↓
  **Ставить перед собой более высокие цели**

  ### 🏆 Уровень достижения

  ↓
  **Самостоятельно ставить цели и достигать их**

  ---

  # **Главное — не деньги.**

  Неважно, на каком этапе ты сейчас находишься.

  Самое важное — не то, сколько денег можно получить.

  Главный вопрос:

  ## **«Насколько я сам становлюсь лучше?»**

  Стал ли я сегодня немного сильнее, чем вчера?

  Сделал ли я сегодня хотя бы один шаг вперёд?

  **Именно в этом заключается настоящая ценность обучения.**

  ---

  # 💰 А что происходит со звёздами?

  В настоящее время в GKE StudyUp стипендия рассчитывается следующим образом:

  ### **⭐ 1 звезда = 2, 3 или 4 корейских вона**

  Но самое важное значение звезды — не деньги.

  ## **Звезда — это запись твоих усилий, твоей учёбы и твоего роста.**

  Твои накопленные учебные достижения могут быть доступны для просмотра твоим родителям.

  Родители могут увидеть твои усилия и результаты и, в знак поддержки и признания твоего труда, принять решение о выплате стипендии.

  **Размер стипендии родители определяют самостоятельно, учитывая возможности и обстоятельства своей семьи.**

  Поэтому звезда и стипендия имеют разный смысл:

  **Звезда показывает и сохраняет твой путь, твои усилия и твой рост.**

  **Стипендия — это поддержка и поощрение родителей на этом пути.**

  ---

  # 🎯 Помни!

  ## **Учёба — это не соревнование с другими.**

  Важно не то, лучше ли ты кого-то другого.

  Важно то, что:

  **сегодняшний ты стал немного лучше вчерашнего себя,**

  а

  **завтрашний ты сможет сделать ещё один шаг вперёд по сравнению с сегодняшним собой.**

  Сегодня ты учился на 10 минут дольше.

  **Это тоже рост.**

  Сегодня ты оставил запись о своей учёбе.

  **Это тоже рост.**

  Ты посмотрел на результат экзамена и честно его проанализировал.

  **Это тоже рост.**

  Тебе не удалось достичь желаемого результата, но ты заново составил план и решил попробовать ещё раз.

  **Это тоже рост.**

  ---

  ## **Маленькие действия, повторяемые снова и снова, становятся привычками.**

  ## **Привычки превращаются в навыки.**

  ## **Навыки постепенно превращаются в достижения.**

  ---

  # ⭐ **Мою учёбу создаю я сам.**

  ### **Планировать → Действовать → Записывать → Анализировать → Снова бросать себе вызов**

  Не жди, пока кто-то скажет тебе, когда нужно учиться.

  Учись:

  думать самостоятельно,

  принимать собственные решения,

  действовать,

  видеть свой прогресс

  и продолжать двигаться вперёд.

  ## **Твой путь обучения принадлежит тебе.**

  Ты можешь создавать его сам — **один шаг за другим.**

  ---

  GKE StudyUp хочет помочь каждому учащемуся развить **силу самостоятельного обучения**,

  двигаться к собственным целям

  и постепенно становиться лучше — шаг за шагом, день за днём.

  Возможно, сегодняшнее усилие было совсем небольшим.

  Возможно, ты просто учился на десять минут дольше.

  Возможно, ты всего лишь записал свой план на следующий день.

  А может быть, после неудачи ты решил начать ещё раз.

  **Каждый такой шаг имеет значение.**

  Потому что маленькие шаги, которые мы продолжаем делать, однажды приводят нас намного дальше, чем мы могли представить.

  И однажды, оглянувшись назад, ты сможешь сказать себе:

  ## **«Хорошо, что тогда я не сдался».**

  ---

  # 🌱 Уровень роста → 🔥 Уровень вызова → 🏆 Уровень достижения

  ## **Маленький шаг, который ты делаешь сегодня, создаёт тебя завтрашнего.**

  **GKE StudyUp**

  **Global Knowledge Education**
  ''', // 러시아어

    'AR': '''# 
  ⭐ GKE StudyUp – دليل المنح الدراسية للطلاب

    ## **تعلمِي يُسجَّل، ونموي يتحول إلى إنجاز.**

  GKE StudyUp ليست منصة للدراسة لأن شخصًا آخر يطلب منك ذلك أو يجبرك عليه.

  إنها منصة تعليمية تساعدك على اكتساب قدرة أهم:

  **أن تضع أهدافك بنفسك، وتخطط لتعلمك، وتحوّل خطتك إلى عمل، وتتحمل مسؤولية طريقك في التعلم.**

  يتم تسجيل الوقت الذي تقضيه في الدراسة، وجهودك، وطريقة ممارستك للتعلم، وسجلات التعلم والتقييمات التي تقوم بها على شكل ⭐ نجوم.

  لكن النجمة ليست مجرد رقم أو درجة.

  ⭐ **النجمة هي أثر تعلمك بجهدك أنت، وعلامة على كل خطوة تخطوها في طريق نموك.**

  درست اليوم قليلًا أكثر.

  سجلت ما تعلمته.

  راجعت نتيجة اختبارك.

  فكرت في دراستك القادمة ووضعت خطة جديدة.

  **كل واحدة من هذه الخطوات الصغيرة تتراكم لتصبح جزءًا من إنجازك وتطورك.**

  ---

  # ⭐ كيف يمكنني الحصول على النجوم؟

  ## 1. وقت الدراسة

  ### **دقيقة واحدة من الدراسة = نجمة واحدة ⭐**

  كلما واصلت الدراسة بانتظام، تراكم سجل تعلمك ونما معك.

  ---

  # 2. الممارسة والالتزام بالتعلم

  * **إنجاز 70% أو أكثر من جلسة الدراسة باستخدام المؤقت → +10 نجوم ⭐**
  * **كتابة سجل للتعلم بعد انتهاء الدراسة → +10 نجوم ⭐**
  * **الدراسة لمدة 50 دقيقة أو أكثر في اليوم → +50 نجمة ⭐**
  * **الدراسة كل يوم لمدة أسبوع كامل، من الأحد إلى السبت، دون انقطاع → +300 نجمة ⭐**
  * **الدراسة كل يوم لمدة شهر كامل دون انقطاع → +1000 نجمة ⭐**

  يوم واحد من الاستمرار هو خطوة صغيرة.

  أسبوع من الاستمرار يمكن أن يصبح عادة.

  وشهر من الاستمرار يصبح تحديًا حقيقيًا للنفس.

  **وفي كل مرة تستمر فيها، فأنت لا تجمع النجوم فقط، بل تبني قوة وثقة في نفسك.**

  ---

  # 3. تقييم التعلم وتسجيله

  * **تسجيل التقييم الأسبوعي → +10 نجوم ⭐**
  * **تسجيل تقييم الوحدة الدراسية → +10 نجوم ⭐**
  * **تسجيل اختبار منتصف الفصل → +50 نجمة ⭐**
  * **تسجيل الاختبار النهائي → +50 نجمة ⭐**
  * **تسجيل الاختبار التجريبي → +50 نجمة ⭐**

  ## **لا تحصل على النجوم لمجرد أنك حصلت على درجة عالية في الاختبار.**

  لأننا نؤمن بأن المهم ليس النتيجة وحدها.

  من المهم أن تسجل نتيجة الاختبار،

  وأن تنظر إلى ما أحسنت القيام به،

  وأن تعرف ما الذي تحتاج إلى تحسينه،

  وأن تسأل نفسك:

  **«ماذا يمكنني أن أفعل بشكل أفضل في المرة القادمة؟»**

  إن عملية التفكير في تعلمك ومراجعة تجربتك هي أيضًا جزء مهم من التعلم.

  فالتعلم ليس مجرد الحصول على درجات عالية.

  **التعلم هو أن تعرف نفسك بشكل أفضل، وتتعلم من أخطائك، وتتقدم خطوة أخرى إلى الأمام.**

  ---

  # 🌱 مرحلة النمو

  ## **«أنا أبني عاداتي الدراسية خطوةً بعد خطوة.»**

  لا تحتاج إلى القيام بكل شيء منذ البداية.

  ولا تحتاج إلى الدراسة لساعات طويلة منذ اليوم الأول.

  ابدأ بخطوة صغيرة.

  ادرس قليلًا كل يوم.

  تعلم بإرادتك.

  سجّل ما تعلمته.

  وحاول الاستمرار حتى عندما تبدو خطواتك صغيرة.

  **مرحلة النمو** هي المرحلة التي تبدأ فيها الدراسة وتبني تدريجيًا عادات تعلم جيدة.

  ---

  # 🔥 مرحلة التحدي

  ## **«هل أستطيع أن أتحدى نفسي بهدف أعلى قليلًا؟»**

  عندما تبدأ عاداتك الدراسية في الاستقرار، حان الوقت لتتقدم خطوة أخرى.

  ضع هدفك بنفسك.

  وتقدم نحوه خطوةً بعد خطوة.

  ومع الاستمرار، ستطور قدراتك الدراسية، وتزيد من قدرتك على التعلم، وتتعلم كيف تدير وقتك وجهدك بنفسك.

  **مرحلة التحدي** هي المرحلة التي تبدأ فيها بوضع أهدافك بنفسك والعمل بجد لتحقيقها.

  ---

  # 🏆 مرحلة الإنجاز

  ## **«أنا أحقق تدريجيًا الأهداف التي وضعتها لنفسي.»**

  الأمر لا يتعلق فقط بالاستمرار في الدراسة.

  بل يتعلق أيضًا بأن تتعلم كيف تدير رحلة تعلمك بنفسك:

  ### **التخطيط للتعلم → التنفيذ → التسجيل → التقييم → التحسين**

  أضع خطة.

  أنفذها.

  أسجل ما قمت به.

  أراجع النتيجة.

  ثم أستخدم ما تعلمته لأجعل خطوتي التالية أفضل.

  **مرحلة الإنجاز** هي المرحلة التي تستمر فيها في التعلم الذاتي، وتصبح أكثر قدرة على إدارة تعلمك بنفسك.

  ---

  # 🌱 → 🔥 → 🏆

  ## **هكذا ينمو تعلّمي خطوةً بعد خطوة.**

  ### 🌱 مرحلة النمو

  ↓
  **بناء عادة الاستمرار في الدراسة**

  ### 🔥 مرحلة التحدي

  ↓
  **التحدي من أجل الوصول إلى أهداف أعلى**

  ### 🏆 مرحلة الإنجاز

  ↓
  **وضع أهدافي بنفسي وتحقيقها بجهدي**

  ---

  # **الأهم ليس المال.**

  سواء كنت في مرحلة النمو، أو التحدي، أو الإنجاز،

  فالقيمة الحقيقية ليست في مقدار المال الذي يمكنك الحصول عليه.

  السؤال الأهم هو:

  ## **«كم أتقدم وأتطور بجهدي أنا؟»**

  هل أصبحت اليوم أفضل قليلًا من الأمس؟

  هل خطوت اليوم خطوة إلى الأمام؟

  **هذا هو المعنى الحقيقي لتعلمك.**

  ---

  # 💰 وماذا يحدث للنجوم؟

  في الوقت الحالي، يتم حساب المنحة الدراسية في GKE StudyUp وفق النظام التالي:

  ### **⭐ نجمة واحدة = 2 أو 3 أو 4 وون كوري**

  لكن أهم معنى للنجمة ليس المال.

  ## **النجمة هي سجل لجهدك وتعلمك وتطورك.**

  يمكن لوالديك الاطلاع على الإنجازات التعليمية التي جمعتها خلال رحلة تعلمك.

  وبناءً على هذه الإنجازات والجهود، يمكن للوالدين تقديم منحة دراسية لك باعتبارها **تعبيرًا عن التشجيع والدعم والتقدير لجهودك.**

  **ويحدد الوالدان قيمة المنحة وفقًا لظروف وإمكانات كل أسرة.**

  ولهذا فإن للنجوم والمنحة معنيين مختلفين:

  **النجوم تسجل جهودك وتطورك.**

  **والمنحة تمثل دعم والديك وتشجيعهما لك في طريقك.**

  ---

  # 🎯 تذكّر!

  ## **الدراسة ليست منافسة مع الآخرين.**

  المهم ليس أن تكون أفضل من شخص آخر.

  المهم هو أن:

  **يكون أنت اليوم أفضل قليلًا من أنت بالأمس،**

  وأن:

  **يكون أنت غدًا قد تقدمت خطوة أخرى مقارنةً بنفسك اليوم.**

  درست اليوم 10 دقائق إضافية.

  **هذا أيضًا نمو.**

  كتبت اليوم سجلًا لما تعلمته.

  **هذا أيضًا نمو.**

  راجعت نتيجة اختبارك بصدق.

  **هذا أيضًا نمو.**

  لم تحقق النتيجة التي كنت تتوقعها، لكنك أعدت وضع خطة وقررت أن تحاول مرة أخرى.

  **هذا أيضًا نمو.**

  ---

  ## **الخطوات الصغيرة عندما تتكرر تصبح عادات.**

  ## **والعادات تصبح قدرات.**

  ## **والقدرات المتراكمة تصبح إنجازات.**

  ---

  # ⭐ **أنا من يصنع رحلة تعلمي.**

  ### **خطط → نفّذ → سجّل → راجع → تحدَّ نفسك من جديد**

  لا تنتظر أن يخبرك شخص آخر متى يجب أن تدرس.

  تعلم أن:

  تفكر بنفسك،

  وتتخذ قراراتك بنفسك،

  وتتحرك بنفسك،

  وترى تقدمك بنفسك،

  وتواصل السير إلى الأمام.

  ## **طريق تعلمك ملك لك.**

  وأنت تستطيع أن تصنعه بنفسك، **خطوةً بعد خطوة.**

  ---

  تريد GKE StudyUp أن تساعد كل طالب على اكتساب **قوة التعلم الذاتي**،

  وأن تساعده على التقدم نحو أهدافه الخاصة،

  والنمو تدريجيًا، خطوةً بعد خطوة، ويومًا بعد يوم.

  قد يكون جهدك اليوم صغيرًا جدًا.

  ربما درست عشر دقائق إضافية فقط.

  وربما كتبت خطة دراستك القادمة.

  وربما واجهت صعوبة، ثم قررت أن تبدأ من جديد.

  **كل خطوة من هذه الخطوات لها قيمة.**

  لأن الخطوات الصغيرة التي نستمر في القيام بها يمكن أن تقودنا يومًا ما إلى أبعد بكثير مما كنا نتخيل.

  وفي يوم من الأيام، عندما تنظر إلى الطريق الذي قطعته، قد تقول لنفسك:

  ## **«أنا سعيد لأنني لم أستسلم في ذلك الوقت.»**

  ---

  # 🌱 مرحلة النمو → 🔥 مرحلة التحدي → 🏆 مرحلة الإنجاز

  ## **خطوتك الصغيرة اليوم هي التي تصنع نفسك في الغد.**

  **GKE StudyUp**

  **Global Knowledge Education**
  ''', // 아랍어

    'HI': '''# 
  ⭐ GKE StudyUp – विद्यार्थियों के लिए छात्रवृत्ति मार्गदर्शिका

    ## **मेरी पढ़ाई दर्ज होती है, और मेरी प्रगति मेरी उपलब्धि बनती है।**

  GKE StudyUp केवल ऐसी जगह नहीं है जहाँ आपको किसी के कहने या दबाव डालने पर पढ़ना हो।

  यह एक ऐसा learning platform है जो आपको एक बहुत महत्वपूर्ण शक्ति विकसित करने में मदद करता है—

  **अपने लक्ष्य स्वयं तय करना, अपनी पढ़ाई की योजना बनाना, उस योजना को अमल में लाना और अपनी सीखने की यात्रा की जिम्मेदारी स्वयं लेना।**

  आपने कितना समय पढ़ाई में लगाया, किस तरह सीखने का अभ्यास किया, क्या सीखा, और अपनी पढ़ाई का मूल्यांकन कैसे किया—इन सबका रिकॉर्ड ⭐ सितारों के रूप में जमा होता है।

  लेकिन—

  ## **⭐ सितारा केवल कोई अंक नहीं है।**

  **यह इस बात का निशान है कि आपने स्वयं पढ़ाई की है।**

  यह आपकी मेहनत का एक छोटा-सा प्रमाण है।

  आज आपने कुछ मिनट अधिक पढ़ा।

  आपने अपनी पढ़ाई का रिकॉर्ड लिखा।

  आपने परीक्षा के परिणाम को ध्यान से देखा।

  आपने अपनी अगली पढ़ाई के लिए नई योजना बनाई।

  **इनमें से हर छोटा कदम आपकी सीखने की यात्रा और आपकी प्रगति का हिस्सा बनता जाता है।**

  ---

  # ⭐ सितारे कैसे प्राप्त करें?

  ## 1. पढ़ाई का समय

  ### **1 मिनट की पढ़ाई = 1 ⭐ सितारा**

  जब आप नियमित रूप से पढ़ते रहते हैं, तो आपका learning record भी आपके साथ बढ़ता जाता है।

  ---

  # 2. सीखने का अभ्यास और निरंतरता

  * **Timer से पढ़ाई का 70% या उससे अधिक पूरा करना → +10 ⭐**
  * **पढ़ाई पूरी करने के बाद Learning Record लिखना → +10 ⭐**
  * **एक दिन में 50 मिनट या उससे अधिक पढ़ाई करना → +50 ⭐**
  * **रविवार से शनिवार तक पूरे सप्ताह हर दिन बिना एक भी दिन छोड़े पढ़ाई करना → +300 ⭐**
  * **पूरे एक महीने तक हर दिन बिना एक भी दिन छोड़े पढ़ाई करना → +1,000 ⭐**

  एक दिन लगातार पढ़ना एक छोटा कदम है।

  एक सप्ताह लगातार पढ़ना एक आदत बन सकता है।

  और एक महीने तक लगातार प्रयास करना आपके अपने संकल्प की एक बड़ी चुनौती बन सकता है।

  **हर बार जब आप अपने प्रयास को जारी रखते हैं, तो आप केवल सितारे जमा नहीं कर रहे होते—आप अपने भीतर अनुशासन, आत्मविश्वास और आगे बढ़ने की शक्ति भी बना रहे होते हैं।**

  ---

  # 3. सीखने का मूल्यांकन और रिकॉर्ड

  * **साप्ताहिक Learning Evaluation Record → +10 ⭐**
  * **Unit Evaluation Record → +10 ⭐**
  * **Midterm Exam Record → +50 ⭐**
  * **Final Exam Record → +50 ⭐**
  * **Mock Exam Record → +50 ⭐**

  ## **केवल परीक्षा में अच्छे अंक प्राप्त करने से सितारे नहीं मिलते।**

  क्योंकि हमारे लिए केवल परिणाम ही महत्वपूर्ण नहीं है।

  यह भी महत्वपूर्ण है कि आप अपनी परीक्षा का परिणाम दर्ज करें,

  सोचें कि आपने क्या अच्छा किया,

  समझें कि कहाँ सुधार की आवश्यकता है,

  और स्वयं से पूछें—

  ### **“अगली बार मैं क्या बेहतर कर सकता हूँ?”**

  अपनी पढ़ाई पर पीछे मुड़कर देखना और अपनी सीख से अगला कदम बेहतर बनाना भी सीखने का एक महत्वपूर्ण हिस्सा है।

  **पढ़ाई केवल अच्छे अंक प्राप्त करने का नाम नहीं है।**

  **सीखना अपने आप को बेहतर समझना, अपनी गलतियों से सीखना और हर बार एक कदम आगे बढ़ना है।**

  ---

  # 🌱 विकास चरण

  ## **“मैं धीरे-धीरे अपनी पढ़ाई की अच्छी आदत बना रहा हूँ।”**

  आपको शुरुआत से ही सब कुछ पूरी तरह करने की आवश्यकता नहीं है।

  आपको पहले दिन से घंटों पढ़ने की भी आवश्यकता नहीं है।

  एक छोटे कदम से शुरुआत करें।

  हर दिन थोड़ा पढ़ें।

  अपनी इच्छा से सीखें।

  जो सीखा उसे दर्ज करें।

  और छोटे कदम होने पर भी लगातार आगे बढ़ने का प्रयास करें।

  **विकास चरण** वह समय है जब आप पढ़ाई की शुरुआत करते हैं और धीरे-धीरे अच्छी अध्ययन आदतें बनाते हैं।

  ---

  # 🔥 चुनौती चरण

  ## **“क्या मैं अपने लिए थोड़ा बड़ा लक्ष्य तय करके उसे चुनौती दे सकता हूँ?”**

  जब आपकी पढ़ाई की आदत बनने लगे, तो अब एक कदम और आगे बढ़ने का समय है।

  अपना लक्ष्य स्वयं तय करें।

  फिर उसे पाने के लिए एक-एक कदम आगे बढ़ें।

  लगातार अभ्यास के साथ आप अपनी पढ़ाई की क्षमता बढ़ा सकते हैं, अधिक प्रभावी ढंग से सीखना सीख सकते हैं और अपने समय तथा प्रयास को स्वयं व्यवस्थित करना सीख सकते हैं।

  **चुनौती चरण** वह समय है जब आप अपने लक्ष्य स्वयं तय करते हैं और उन्हें पूरा करने के लिए सक्रिय रूप से प्रयास करते हैं।

  ---

  # 🏆 उपलब्धि चरण

  ## **“मैं अपने द्वारा तय किए गए लक्ष्यों को स्वयं पूरा कर रहा हूँ।”**

  यह केवल लगातार पढ़ते रहने की बात नहीं है।

  यह अपनी सीखने की पूरी प्रक्रिया को स्वयं संभालना सीखने की बात है:

  ### **Learning Plan → Practice → Record → Evaluation → Improvement**

  मैं योजना बनाता हूँ।

  मैं उसे पूरा करने का प्रयास करता हूँ।

  मैं अपने किए हुए काम को दर्ज करता हूँ।

  मैं परिणाम को देखता और समझता हूँ।

  फिर जो सीखा है, उसके आधार पर अपनी अगली योजना को बेहतर बनाता हूँ।

  **उपलब्धि चरण** वह समय है जब आप लगातार आत्मनिर्भर होकर सीखते हैं और अपनी पढ़ाई को स्वयं व्यवस्थित करने की क्षमता विकसित करते हैं।

  ---

  # 🌱 → 🔥 → 🏆

  ## **मेरी सीखने की यात्रा एक कदम से दूसरे कदम तक आगे बढ़ती है।**

  ### 🌱 विकास चरण

  ↓
  **नियमित पढ़ाई की आदत बनाना**

  ### 🔥 चुनौती चरण

  ↓
  **ऊँचे लक्ष्यों के लिए स्वयं को चुनौती देना**

  ### 🏆 उपलब्धि चरण

  ↓
  **अपने लक्ष्य स्वयं तय करना और अपने प्रयास से उन्हें पूरा करना**

  ---

  # **सबसे महत्वपूर्ण बात पैसा नहीं है।**

  चाहे आप विकास चरण में हों, चुनौती चरण में हों या उपलब्धि चरण में—

  आपकी वास्तविक प्रगति इस बात से तय नहीं होती कि आपको कितनी धनराशि मिलती है।

  सबसे महत्वपूर्ण प्रश्न है:

  ## **“मैं अपने प्रयास से कितना सीख रहा हूँ और कितना आगे बढ़ रहा हूँ?”**

  क्या मैं आज कल से थोड़ा बेहतर हूँ?

  क्या मैंने आज एक कदम आगे बढ़ाया?

  **यही आपकी सीखने की वास्तविक प्रगति है।**

  ---

  # 💰 सितारों का छात्रवृत्ति से क्या संबंध है?

  वर्तमान में GKE StudyUp में छात्रवृत्ति की गणना इस प्रकार की जाती है:

  ### **⭐ 1 सितारा = 2, 3 या 4 कोरियाई वॉन (KRW)**

  लेकिन सितारे का सबसे महत्वपूर्ण अर्थ पैसा नहीं है।

  ## **⭐ सितारा आपकी पढ़ाई, मेहनत और प्रगति का रिकॉर्ड है।**

  आपके माता-पिता आपकी सीखने की यात्रा के दौरान जमा हुए learning achievements को देख सकते हैं।

  इन उपलब्धियों और आपके निरंतर प्रयास के आधार पर, माता-पिता आपको छात्रवृत्ति दे सकते हैं—

  **आपकी मेहनत को प्रोत्साहित करने, आपके प्रयास को सराहने और आपकी आगे की यात्रा में आपका साथ देने के लिए।**

  छात्रवृत्ति की राशि प्रत्येक परिवार की परिस्थितियों और आर्थिक क्षमता के अनुसार माता-पिता स्वयं तय करते हैं।

  इसलिए सितारे और छात्रवृत्ति का अर्थ एक जैसा नहीं है।

  ### **सितारे आपकी मेहनत और आपकी प्रगति को दर्ज करते हैं।**

  ### **छात्रवृत्ति आपके माता-पिता के प्रोत्साहन और समर्थन को व्यक्त करती है।**

  इसका उद्देश्य आपके अध्ययन को केवल पैसे के मूल्य में मापना नहीं है।

  **पैसा एक प्रोत्साहन हो सकता है, लेकिन आपकी मेहनत, आपकी आदत, आपका आत्मविश्वास और आपका विकास कहीं अधिक महत्वपूर्ण हैं।**

  ---

  # 🎯 इसे हमेशा याद रखें!

  ## **पढ़ाई दूसरों के साथ प्रतियोगिता नहीं है।**

  महत्वपूर्ण यह नहीं है कि आप किसी दूसरे विद्यार्थी से बेहतर हैं या नहीं।

  महत्वपूर्ण यह है कि—

  **आज का आप कल के अपने आप से थोड़ा बेहतर हो,**

  और

  **कल का आप आज के अपने आप से एक कदम आगे हो।**

  आज आपने 10 मिनट अधिक पढ़ा।

  **यह भी विकास है।**

  आज आपने अपनी पढ़ाई का रिकॉर्ड लिखा।

  **यह भी विकास है।**

  आपने अपनी परीक्षा के परिणाम को ईमानदारी से देखा।

  **यह भी विकास है।**

  पढ़ाई आपकी योजना के अनुसार नहीं हुई, फिर भी आपने दोबारा योजना बनाई और फिर से प्रयास करने का निर्णय लिया।

  **यह भी विकास है।**

  ---

  # **छोटे-छोटे प्रयास दोहराए जाएँ तो आदत बन जाते हैं।**

  # **आदतें मिलकर क्षमता बनाती हैं।**

  # **और लगातार विकसित होती क्षमता अंततः उपलब्धि बनती है।**

  ---

  # ⭐ **मेरी सीखने की यात्रा मैं स्वयं बनाता हूँ।**

  ### **योजना बनाओ → अभ्यास करो → दर्ज करो → पीछे मुड़कर देखो → फिर से चुनौती स्वीकार करो**

  किसी दूसरे व्यक्ति के यह बताने का इंतज़ार मत करो कि आपको कब पढ़ना चाहिए।

  सीखें कि आप—

  **स्वयं सोचें,**

  **स्वयं निर्णय लें,**

  **स्वयं कदम उठाएँ,**

  **अपनी प्रगति स्वयं देखें,**

  और

  **लगातार आगे बढ़ते रहें।**

  ## **आपकी सीखने की यात्रा आपकी अपनी है।**

  और आप इसे स्वयं बना सकते हैं—

  **एक कदम, फिर एक कदम।**

  ---

  GKE StudyUp हर विद्यार्थी को **स्वतंत्र रूप से सीखने की शक्ति** विकसित करने में सहायता करना चाहता है।

  आप अपने लक्ष्य स्वयं तय कर सकें,

  उनकी ओर लगातार आगे बढ़ सकें,

  और हर दिन थोड़ा-थोड़ा विकसित होते रहें।

  हो सकता है कि आज का आपका प्रयास बहुत छोटा हो।

  शायद आपने केवल 10 मिनट अधिक पढ़ा हो।

  शायद आपने अपनी अगली पढ़ाई की योजना लिखी हो।

  शायद आज आपको कठिनाई हुई हो, फिर भी आपने दोबारा शुरुआत करने का निर्णय लिया हो।

  ## **इनमें से हर कदम मूल्यवान है।**

  क्योंकि जो छोटे कदम हम लगातार उठाते रहते हैं,

  वे एक दिन हमें वहाँ पहुँचा सकते हैं

  जहाँ हमने कभी सोचा भी नहीं था कि हम पहुँच पाएँगे।

  और शायद किसी दिन पीछे मुड़कर देखते हुए आप स्वयं से कहेंगे—

  ## **“अच्छा हुआ, उस दिन मैंने हार नहीं मानी।”**

  ---

  # 🌱 विकास चरण → 🔥 चुनौती चरण → 🏆 उपलब्धि चरण

  ## **आज का आपका छोटा कदम ही आपके कल के आपको बनाता है।**

  **GKE StudyUp**

  **Global Knowledge Education**
  ''', // 힌디어

    'VI': '''# 
  ⭐ GKE StudyUp – Hướng dẫn học bổng dành cho học sinh

    ## **Việc học của tôi được ghi lại, và sự trưởng thành của tôi trở thành thành quả.**

  GKE StudyUp không phải là nơi bạn học chỉ vì có ai đó yêu cầu hay ép buộc bạn phải học.

  Đây là một nền tảng học tập giúp bạn phát triển một năng lực quan trọng hơn:

  **tự đặt mục tiêu, tự lập kế hoạch học tập, biến kế hoạch thành hành động và tự chịu trách nhiệm với hành trình học tập của chính mình.**

  Thời gian học, quá trình thực hành, những gì bạn đã học, cũng như các đánh giá và ghi chép về việc học đều được ghi lại bằng ⭐ ngôi sao.

  Nhưng—

  ## **⭐ Ngôi sao không đơn giản chỉ là một điểm số.**

  ### **Ngôi sao là dấu ấn cho thấy bạn đã tự mình học tập.**

  Đó là dấu vết của những nỗ lực mà chính bạn đã thực hiện trên hành trình trưởng thành của mình.

  Hôm nay bạn học thêm một chút.

  Bạn ghi lại những gì mình đã học.

  Bạn nhìn lại kết quả bài kiểm tra.

  Bạn suy nghĩ và lập kế hoạch cho lần học tiếp theo.

  **Mỗi bước nhỏ như vậy đều được tích lũy và trở thành một phần trong thành quả học tập và sự trưởng thành của bạn.**

  ---

  # ⭐ Làm thế nào để nhận được ngôi sao?

  ## 1. Thời gian học

  ### **1 phút học tập = 1 ⭐ ngôi sao**

  Khi bạn duy trì việc học đều đặn, những nỗ lực của bạn sẽ từng ngày được ghi lại và tích lũy.

  ---

  # 2. Thực hành học tập và sự kiên trì

  * **Hoàn thành từ 70% trở lên thời lượng học bằng Timer → +10 ⭐**
  * **Viết nhật ký học tập sau khi hoàn thành buổi học → +10 ⭐**
  * **Học từ 50 phút trở lên trong một ngày → +50 ⭐**
  * **Học mỗi ngày từ Chủ nhật đến Thứ bảy trong trọn một tuần, không bỏ ngày nào → +300 ⭐**
  * **Học mỗi ngày trong trọn một tháng, không bỏ ngày nào → +1,000 ⭐**

  Một ngày kiên trì là một bước nhỏ.

  Một tuần kiên trì có thể trở thành một thói quen.

  Và một tháng kiên trì chính là một thử thách lớn đối với bản thân.

  **Mỗi khi bạn tiếp tục cố gắng, bạn không chỉ tích lũy thêm những ngôi sao. Bạn đang xây dựng sự tự tin, tính kỷ luật và sức mạnh để tiến về phía trước.**

  ---

  # 3. Đánh giá và ghi lại quá trình học tập

  * **Ghi lại đánh giá học tập hằng tuần → +10 ⭐**
  * **Ghi lại đánh giá từng bài/chủ đề học tập → +10 ⭐**
  * **Ghi lại kết quả kiểm tra giữa kỳ → +50 ⭐**
  * **Ghi lại kết quả kiểm tra cuối kỳ → +50 ⭐**
  * **Ghi lại kết quả bài thi thử → +50 ⭐**

  ## **Bạn không nhận được ngôi sao chỉ vì đạt điểm cao trong bài kiểm tra.**

  Bởi vì với GKE StudyUp, kết quả cuối cùng không phải là điều duy nhất quan trọng.

  Điều quan trọng là bạn biết nhìn lại kết quả của chính mình.

  Bạn nhận ra mình đã làm tốt điều gì.

  Bạn hiểu mình cần cải thiện điều gì.

  Và bạn tự hỏi:

  ### **“Lần sau mình có thể làm tốt hơn điều gì?”**

  Nhìn lại quá trình học tập và rút kinh nghiệm cho bước tiếp theo cũng chính là một phần quan trọng của việc học.

  **Học tập không chỉ là đạt điểm cao.**

  **Học tập là hiểu bản thân hơn, học hỏi từ những điều chưa tốt và mỗi ngày tiến thêm một bước.**

  ---

  # 🌱 Giai đoạn Phát triển

  ## **“Mình đang từng bước xây dựng thói quen học tập.”**

  Bạn không cần phải làm mọi thứ thật hoàn hảo ngay từ đầu.

  Bạn cũng không cần phải học hàng giờ ngay từ ngày đầu tiên.

  Hãy bắt đầu bằng một bước nhỏ.

  Học một chút mỗi ngày.

  Tự mình học.

  Ghi lại những gì mình đã học.

  Và cố gắng duy trì ngay cả khi những bước tiến của bạn còn rất nhỏ.

  **Giai đoạn Phát triển** là giai đoạn bạn bắt đầu việc học và từng bước xây dựng những thói quen học tập tốt.

  ---

  # 🔥 Giai đoạn Thử thách

  ## **“Mình muốn thử thách bản thân với một mục tiêu cao hơn một chút.”**

  Khi thói quen học tập của bạn bắt đầu ổn định, hãy bước thêm một bước nữa.

  Tự đặt mục tiêu cho mình.

  Sau đó từng bước tiến về phía mục tiêu ấy.

  Qua quá trình kiên trì, bạn sẽ phát triển khả năng học tập, nâng cao năng lực tự quản lý thời gian và biết cách chủ động quản lý nỗ lực của mình.

  **Giai đoạn Thử thách** là giai đoạn bạn bắt đầu tự đặt ra những mục tiêu cao hơn và chủ động hành động để đạt được chúng.

  ---

  # 🏆 Giai đoạn Thành tựu

  ## **“Mình đang từng bước đạt được những mục tiêu do chính mình đặt ra.”**

  Điều này không chỉ có nghĩa là học đều đặn.

  Đó còn là việc học cách tự quản lý toàn bộ quá trình học tập của mình:

  ### **Lập kế hoạch học tập → Thực hiện → Ghi lại → Đánh giá → Cải thiện**

  Mình lập kế hoạch.

  Mình thực hiện.

  Mình ghi lại những gì đã làm.

  Mình nhìn lại kết quả.

  Sau đó, mình dùng những gì đã học được để làm cho kế hoạch tiếp theo tốt hơn.

  **Giai đoạn Thành tựu** là giai đoạn bạn duy trì việc tự học và ngày càng có khả năng tự quản lý hành trình học tập của chính mình.

  ---

  # 🌱 → 🔥 → 🏆

  ## **Hành trình học tập của mình được xây dựng từng bước.**

  ### 🌱 Giai đoạn Phát triển

  ↓
  **Xây dựng thói quen học tập đều đặn**

  ### 🔥 Giai đoạn Thử thách

  ↓
  **Thử thách bản thân với những mục tiêu cao hơn**

  ### 🏆 Giai đoạn Thành tựu

  ↓
  **Tự đặt mục tiêu và đạt được mục tiêu bằng nỗ lực của chính mình**

  ---

  # **Điều quan trọng nhất không phải là tiền.**

  Dù bạn đang ở Giai đoạn Phát triển, Giai đoạn Thử thách hay Giai đoạn Thành tựu,

  giá trị thực sự của việc học không nằm ở số tiền bạn có thể nhận được.

  Điều quan trọng hơn là:

  ## **“Mình đang trưởng thành và tiến bộ như thế nào bằng chính nỗ lực của mình?”**

  Hôm nay mình có tốt hơn hôm qua một chút không?

  Hôm nay mình có tiến thêm một bước không?

  **Đó mới là sự trưởng thành thực sự trong việc học.**

  ---

  # 💰 Những ngôi sao có ý nghĩa gì đối với học bổng?

  Hiện tại, học bổng tại GKE StudyUp được tính theo cách sau:

  ### **⭐ 1 ngôi sao = 2, 3 hoặc 4 Won Hàn Quốc (KRW)**

  Nhưng ý nghĩa quan trọng nhất của ngôi sao không phải là tiền.

  ## **⭐ Ngôi sao là hồ sơ ghi lại quá trình học tập, nỗ lực và trưởng thành của bạn.**

  Cha mẹ có thể nhìn thấy những thành quả học tập mà bạn đã tích lũy trong suốt hành trình của mình.

  Dựa trên những thành quả và nỗ lực đó, cha mẹ có thể trao học bổng cho bạn như một cách:

  **ghi nhận sự cố gắng, khích lệ tinh thần và đồng hành cùng bạn trên con đường học tập.**

  Giá trị học bổng sẽ do cha mẹ quyết định tùy theo hoàn cảnh và khả năng của mỗi gia đình.

  Vì vậy, **ngôi sao và học bổng không mang cùng một ý nghĩa.**

  ### **Ngôi sao ghi lại nỗ lực và sự trưởng thành của bạn.**

  ### **Học bổng thể hiện sự động viên và ủng hộ của cha mẹ dành cho hành trình ấy.**

  Mục đích không phải là dùng tiền để đánh giá việc học của một đứa trẻ.

  **Tiền có thể là một lời động viên, nhưng điều quý giá hơn chính là thói quen học tập, sự tự tin, khả năng tự học và sự trưởng thành mà đứa trẻ đang từng ngày xây dựng.**

  ---

  # 🎯 Hãy luôn nhớ!

  ## **Học tập không phải là cuộc cạnh tranh với người khác.**

  Điều quan trọng không phải là bạn giỏi hơn một người khác hay không.

  Điều quan trọng là:

  **Bạn của hôm nay tốt hơn bạn của ngày hôm qua một chút,**

  và

  **Bạn của ngày mai tiến thêm một bước so với bạn của hôm nay.**

  Hôm nay bạn học thêm 10 phút.

  **Đó cũng là trưởng thành.**

  Hôm nay bạn ghi lại quá trình học tập của mình.

  **Đó cũng là trưởng thành.**

  Hôm nay bạn nhìn lại kết quả bài kiểm tra một cách nghiêm túc.

  **Đó cũng là trưởng thành.**

  Việc học hôm nay không diễn ra như kế hoạch, nhưng bạn đã lập lại kế hoạch và quyết định thử lại.

  **Đó cũng là trưởng thành.**

  ---

  # **Những nỗ lực nhỏ, khi được lặp lại, sẽ trở thành thói quen.**

  # **Thói quen được tích lũy sẽ trở thành năng lực.**

  # **Năng lực được phát triển từng ngày sẽ trở thành thành tựu.**

  ---

  # ⭐ **Mình tự tạo nên hành trình học tập của chính mình.**

  ### **Lập kế hoạch → Thực hiện → Ghi lại → Nhìn lại → Tiếp tục thử thách bản thân**

  Đừng chờ người khác nói cho bạn biết khi nào bạn phải học.

  Hãy học cách:

  **tự suy nghĩ,**

  **tự quyết định,**

  **tự hành động,**

  **tự nhìn thấy sự tiến bộ của mình,**

  và

  **tiếp tục bước về phía trước.**

  ## **Hành trình học tập của bạn thuộc về chính bạn.**

  Và bạn có thể tự mình tạo nên hành trình ấy—

  **từng bước một.**

  ---

  GKE StudyUp mong muốn giúp mỗi học sinh phát triển **năng lực tự học**,

  tự đặt mục tiêu cho bản thân,

  kiên trì tiến về phía những mục tiêu ấy,

  và từng ngày trưởng thành hơn.

  Có thể nỗ lực của bạn hôm nay rất nhỏ.

  Có thể bạn chỉ học thêm 10 phút.

  Có thể bạn viết kế hoạch cho buổi học tiếp theo.

  Có thể hôm nay bạn gặp khó khăn, nhưng vẫn quyết định bắt đầu lại.

  ## **Mỗi bước như vậy đều có giá trị.**

  Bởi vì những bước nhỏ mà chúng ta kiên trì thực hiện mỗi ngày

  có thể đưa chúng ta đến một ngày nào đó

  xa hơn rất nhiều so với nơi chúng ta từng nghĩ mình có thể đến.

  Và rồi sẽ có một ngày, khi nhìn lại con đường mình đã đi qua, bạn có thể mỉm cười và nói với chính mình:

  ## **“Thật may là ngày hôm đó mình đã không bỏ cuộc.”**

  ---

  # 🌱 Giai đoạn Phát triển → 🔥 Giai đoạn Thử thách → 🏆 Giai đoạn Thành tựu

  ## **Bước nhỏ của bạn hôm nay sẽ tạo nên bạn của ngày mai.**

  **GKE StudyUp**

  **Global Knowledge Education**
  ''', // 베트남어

    'ES': '''
   # ⭐ GKE StudyUp – Guía de becas para estudiantes

    ## **Mi aprendizaje queda registrado y mi crecimiento se convierte en un logro.**

  GKE StudyUp no es una plataforma en la que estudias simplemente porque alguien te lo ordena o te obliga a hacerlo.

  Es una plataforma de aprendizaje que te ayuda a desarrollar algo mucho más importante:

  **aprender a establecer tus propios objetivos, planificar tu estudio, convertir tus planes en acciones y asumir la responsabilidad de tu propio camino de aprendizaje.**

  El tiempo que dedicas a estudiar, tu proceso de aprendizaje, tus prácticas, tus registros y tus evaluaciones quedan registrados mediante ⭐ estrellas.

  Pero una estrella no es simplemente un número o una puntuación.

  ## ⭐ **Una estrella es la huella de que has estudiado por ti mismo.**

  Es una pequeña señal de cada esfuerzo que has hecho y de cada paso que has dado para crecer.

  Hoy estudiaste unos minutos más.

  Registraste lo que aprendiste.

  Revisaste el resultado de un examen.

  Pensaste en lo que necesitas estudiar después y preparaste un nuevo plan.

  **Cada uno de esos pequeños pasos se va acumulando y se convierte en parte de tu aprendizaje, tu crecimiento y tus logros.**

  ---

  # ⭐ ¿Cómo puedo obtener estrellas?

  ## 1. Tiempo de estudio

  ### **1 minuto de estudio = 1 ⭐ estrella**

  Cuando estudias de manera constante, cada minuto de esfuerzo queda registrado y se acumula como parte de tu camino de aprendizaje.

  ---

  # 2. Práctica y constancia en el aprendizaje

  * **Completar el 70 % o más de una sesión de estudio con el temporizador → +10 ⭐**
  * **Escribir un registro de aprendizaje después de terminar de estudiar → +10 ⭐**
  * **Estudiar 50 minutos o más en un día → +50 ⭐**
  * **Estudiar todos los días de domingo a sábado durante una semana completa, sin faltar ningún día → +300 ⭐**
  * **Estudiar todos los días durante un mes completo, sin faltar ningún día → +1,000 ⭐**

  Un día de constancia es un pequeño paso.

  Una semana de constancia puede convertirse en un hábito.

  Y un mes de constancia puede convertirse en un verdadero desafío para ti mismo.

  **Cada vez que continúas a pesar de las dificultades, no solo acumulas estrellas. También estás construyendo disciplina, confianza en ti mismo y la fuerza para seguir avanzando.**

  ---

  # 3. Evaluación y registro del aprendizaje

  * **Registrar la evaluación semanal → +10 ⭐**
  * **Registrar la evaluación de una unidad → +10 ⭐**
  * **Registrar el examen de mitad de curso → +50 ⭐**
  * **Registrar el examen final → +50 ⭐**
  * **Registrar el examen de práctica → +50 ⭐**

  ## **Las estrellas no se obtienen simplemente por conseguir una buena nota en un examen.**

  Porque para nosotros, la nota final no es lo único importante.

  También es importante que puedas mirar tu propio resultado,

  reconocer lo que hiciste bien,

  entender lo que necesitas mejorar,

  y preguntarte:

  ### **“¿Qué puedo hacer mejor la próxima vez?”**

  Mirar atrás, reflexionar sobre tu aprendizaje y utilizar lo que has aprendido para dar un paso mejor la próxima vez también forma parte de aprender.

  **Estudiar no significa solamente conseguir buenas notas.**

  **Aprender significa conocerte mejor, aprender de tus errores y avanzar un paso más cada vez.**

  ---

  # 🌱 Etapa de Crecimiento

  ## **“Estoy construyendo poco a poco mis hábitos de estudio.”**

  No necesitas hacerlo todo perfectamente desde el principio.

  Tampoco necesitas estudiar durante muchas horas desde el primer día.

  Empieza con un pequeño paso.

  Estudia un poco cada día.

  Aprende por decisión propia.

  Registra lo que has aprendido.

  Y trata de mantener el esfuerzo, incluso cuando tus avances parezcan pequeños.

  **La Etapa de Crecimiento** es el momento en el que comienzas a estudiar y vas construyendo poco a poco buenos hábitos de aprendizaje.

  ---

  # 🔥 Etapa de Desafío

  ## **“Quiero desafiarme con una meta un poco más alta.”**

  Cuando tus hábitos de estudio comienzan a consolidarse, es momento de dar un paso más.

  Establece tus propios objetivos.

  Después, avanza hacia ellos paso a paso.

  Con la práctica constante, desarrollarás tus capacidades de aprendizaje, aprenderás a estudiar de manera más eficaz y mejorarás tu capacidad para gestionar tu tiempo y tus esfuerzos.

  **La Etapa de Desafío** es el momento en el que comienzas a establecer objetivos más altos por ti mismo y a actuar activamente para alcanzarlos.

  ---

  # 🏆 Etapa de Logro

  ## **“Estoy alcanzando poco a poco los objetivos que yo mismo me he propuesto.”**

  No se trata solamente de estudiar de manera constante.

  También se trata de aprender a gestionar por ti mismo todo tu proceso de aprendizaje:

  ### **Planificar → Practicar → Registrar → Evaluar → Mejorar**

  Planifico.

  Lo pongo en práctica.

  Registro lo que he hecho.

  Reviso el resultado.

  Y utilizo lo que he aprendido para hacer mejor mi próximo plan.

  **La Etapa de Logro** es el momento en el que mantienes un aprendizaje autónomo y desarrollas cada vez más la capacidad de dirigir tu propio proceso de aprendizaje.

  ---

  # 🌱 → 🔥 → 🏆

  ## **Mi camino de aprendizaje crece paso a paso.**

  ### 🌱 Etapa de Crecimiento

  ↓
  **Construir un hábito constante de estudio**

  ### 🔥 Etapa de Desafío

  ↓
  **Desafiarme para alcanzar objetivos más altos**

  ### 🏆 Etapa de Logro

  ↓
  **Establecer mis propios objetivos y alcanzarlos con mi propio esfuerzo**

  ---

  # **Lo más importante no es el dinero.**

  Estés en la Etapa de Crecimiento, en la Etapa de Desafío o en la Etapa de Logro,

  el verdadero valor de tu aprendizaje no está en cuánto dinero puedas recibir.

  La pregunta más importante es:

  ## **“¿Cuánto estoy aprendiendo y cuánto estoy creciendo gracias a mi propio esfuerzo?”**

  ¿Soy hoy un poco mejor que ayer?

  ¿He dado hoy un paso hacia adelante?

  **Eso es lo que realmente significa crecer a través del aprendizaje.**

  ---

  # 💰 ¿Qué significado tienen las estrellas en relación con la beca?

  Actualmente, la beca de GKE StudyUp se calcula de la siguiente manera:

  ### **⭐ 1 estrella = 2, 3 o 4 wones surcoreanos (KRW)**

  Pero el significado más importante de una estrella no es el dinero.

  ## **⭐ Una estrella es un registro de tu aprendizaje, tu esfuerzo y tu crecimiento.**

  Tus padres pueden comprobar los logros de aprendizaje que has acumulado durante tu camino.

  A partir de esos logros y de tu esfuerzo constante, tus padres pueden darte una beca como una forma de:

  **reconocer tu esfuerzo, animarte a seguir adelante y acompañarte en tu camino de aprendizaje.**

  La cantidad de la beca será determinada por los padres de acuerdo con las circunstancias y las posibilidades de cada familia.

  Por eso, **las estrellas y la beca no significan lo mismo.**

  ### **Las estrellas registran tu esfuerzo y tu crecimiento.**

  ### **La beca representa el apoyo, el reconocimiento y el ánimo de tus padres hacia ese camino.**

  El propósito no es poner un precio al estudio de un niño.

  **El dinero puede ser una forma de motivación, pero lo verdaderamente valioso es el hábito de estudio, la confianza en uno mismo, la capacidad de aprender por cuenta propia y el crecimiento que el estudiante va construyendo cada día.**

  ---

  # 🎯 ¡Recuérdalo siempre!

  ## **Estudiar no es competir con los demás.**

  Lo importante no es ser mejor que otra persona.

  Lo importante es que:

  **el tú de hoy sea un poco mejor que el tú de ayer,**

  y que:

  **el tú de mañana haya avanzado un paso más que el tú de hoy.**

  Hoy estudiaste 10 minutos más.

  **Eso también es crecer.**

  Hoy escribiste tu registro de aprendizaje.

  **Eso también es crecer.**

  Hoy revisaste con sinceridad el resultado de tu examen.

  **Eso también es crecer.**

  Hoy tu estudio no salió como habías planeado, pero volviste a hacer un plan y decidiste intentarlo de nuevo.

  **Eso también es crecer.**

  ---

  # **Los pequeños esfuerzos, cuando se repiten, se convierten en hábitos.**

  # **Los hábitos acumulados se convierten en capacidades.**

  # **Y las capacidades que desarrollamos poco a poco se convierten en logros.**

  ---

  # ⭐ **Yo construyo mi propio camino de aprendizaje.**

  ### **Planifica → Practica → Registra → Reflexiona → Vuelve a desafiarte**

  No esperes a que otra persona te diga cuándo debes estudiar.

  Aprende a:

  **pensar por ti mismo,**

  **tomar tus propias decisiones,**

  **actuar por ti mismo,**

  **reconocer tu propio progreso,**

  y

  **seguir avanzando.**

  ## **Tu camino de aprendizaje te pertenece.**

  Y puedes construirlo tú mismo,

  **paso a paso.**

  ---

  GKE StudyUp quiere ayudar a cada estudiante a desarrollar **la capacidad de aprender por sí mismo**,

  a establecer sus propios objetivos,

  a avanzar constantemente hacia ellos

  y a crecer un poco más cada día.

  Puede que tu esfuerzo de hoy parezca muy pequeño.

  Tal vez solo estudiaste 10 minutos más.

  Tal vez escribiste el plan para tu próxima sesión de estudio.

  Tal vez hoy encontraste dificultades, pero decidiste volver a empezar.

  ## **Cada uno de esos pasos tiene valor.**

  Porque los pequeños pasos que seguimos dando cada día

  pueden llevarnos algún día mucho más lejos

  de lo que alguna vez imaginamos.

  Y quizá algún día, cuando mires hacia atrás y veas todo el camino que has recorrido, puedas decirte a ti mismo:

  ## **“Qué bueno que aquel día no me rendí.”**

  ---

  # 🌱 Etapa de Crecimiento → 🔥 Etapa de Desafío → 🏆 Etapa de Logro

  ## **El pequeño paso que das hoy construye a la persona que serás mañana.**

  **GKE StudyUp**

  **Global Knowledge Education**
  ''', // 스페인어

    'TH': '''
  # ⭐ GKE StudyUp – คู่มือทุนการศึกษาสำหรับนักเรียน

    ## **การเรียนของฉันได้รับการบันทึก และการเติบโตของฉันกลายเป็นความสำเร็จ**

  GKE StudyUp ไม่ใช่แพลตฟอร์มที่ทำให้คุณต้องเรียนเพียงเพราะมีใครสั่งหรือบังคับให้เรียน

  แต่เป็นแพลตฟอร์มการเรียนรู้ที่ช่วยให้คุณพัฒนาความสามารถที่สำคัญยิ่งกว่า นั่นคือ

  **การตั้งเป้าหมายด้วยตัวเอง วางแผนการเรียนด้วยตัวเอง ลงมือทำตามแผน และรับผิดชอบเส้นทางการเรียนรู้ของตัวเอง**

  เวลาที่คุณใช้เรียน กระบวนการฝึกฝน สิ่งที่คุณเรียนรู้ รวมถึงบันทึกและการประเมินผลการเรียน จะถูกบันทึกไว้ในรูปแบบของ ⭐ ดาว

  แต่ดาวไม่ได้เป็นเพียงตัวเลขหรือคะแนนธรรมดา

  ## ⭐ **ดาวคือร่องรอยของการเรียนรู้ที่คุณลงมือทำด้วยตัวเอง**

  ดาวแต่ละดวงเป็นเหมือนหลักฐานเล็ก ๆ ของความพยายาม และทุกก้าวที่คุณเดินไปบนเส้นทางแห่งการเติบโต

  วันนี้คุณเรียนเพิ่มขึ้นอีกเล็กน้อย

  คุณบันทึกสิ่งที่ได้เรียนรู้

  คุณทบทวนผลการสอบของตัวเอง

  คุณคิดถึงสิ่งที่ควรเรียนต่อไปและวางแผนใหม่

  **ทุกก้าวเล็ก ๆ เหล่านี้จะค่อย ๆ สะสม และกลายเป็นส่วนหนึ่งของการเรียนรู้ การเติบโต และความสำเร็จของคุณ**

  ---

  # ⭐ จะได้รับดาวได้อย่างไร?

  ## 1. เวลาที่ใช้ในการเรียน

  ### **เรียน 1 นาที = ⭐ 1 ดาว**

  เมื่อคุณเรียนอย่างสม่ำเสมอ ทุกนาทีแห่งความพยายามจะถูกบันทึกและสะสมไว้เป็นส่วนหนึ่งของเส้นทางการเรียนรู้ของคุณ

  ---

  # 2. การฝึกฝนและความสม่ำเสมอในการเรียน

  * **เรียนด้วย Timer และทำครบตั้งแต่ 70% ขึ้นไป → +10 ⭐**
  * **เขียนบันทึกการเรียนหลังจากเรียนเสร็จ → +10 ⭐**
  * **เรียนวันละ 50 นาทีขึ้นไป → +50 ⭐**
  * **เรียนทุกวันตั้งแต่วันอาทิตย์ถึงวันเสาร์ครบหนึ่งสัปดาห์ โดยไม่ขาดแม้แต่วันเดียว → +300 ⭐**
  * **เรียนทุกวันตลอดหนึ่งเดือน โดยไม่ขาดแม้แต่วันเดียว → +1,000 ⭐**

  การพยายามอย่างต่อเนื่องหนึ่งวัน คือก้าวเล็ก ๆ

  การพยายามอย่างต่อเนื่องหนึ่งสัปดาห์ อาจกลายเป็นนิสัย

  และการพยายามอย่างต่อเนื่องหนึ่งเดือน คือความท้าทายที่ยิ่งใหญ่สำหรับตัวคุณเอง

  **ทุกครั้งที่คุณยังคงพยายามต่อไป คุณไม่ได้เพียงสะสมดาวเท่านั้น แต่คุณกำลังสร้างวินัย ความมั่นใจในตัวเอง และพลังที่จะก้าวต่อไปด้วย**

  ---

  # 3. การประเมินและบันทึกการเรียนรู้

  * **บันทึกผลการประเมินรายสัปดาห์ → +10 ⭐**
  * **บันทึกผลการประเมินแต่ละหน่วยการเรียน → +10 ⭐**
  * **บันทึกผลสอบกลางภาค → +50 ⭐**
  * **บันทึกผลสอบปลายภาค → +50 ⭐**
  * **บันทึกผลสอบจำลอง → +50 ⭐**

  ## **คุณไม่ได้รับดาวเพียงเพราะได้คะแนนสอบสูง**

  เพราะเราเชื่อว่าคะแนนไม่ได้เป็นสิ่งสำคัญเพียงอย่างเดียว

  สิ่งสำคัญคือการที่คุณสามารถมองย้อนกลับไปยังผลการเรียนของตัวเอง

  มองเห็นว่าสิ่งใดที่คุณทำได้ดี

  เข้าใจว่าสิ่งใดที่คุณควรปรับปรุง

  และถามตัวเองว่า

  ### **“ครั้งหน้าฉันจะทำอะไรให้ดีขึ้นได้บ้าง?”**

  การทบทวนการเรียนรู้ของตัวเอง และนำสิ่งที่ได้เรียนรู้ไปปรับใช้กับก้าวต่อไป ก็เป็นส่วนสำคัญของการเรียนรู้เช่นกัน

  **การเรียนไม่ใช่เพียงการทำคะแนนให้สูง**

  **การเรียนรู้คือการเข้าใจตัวเองมากขึ้น เรียนรู้จากสิ่งที่ผิดพลาด และก้าวไปข้างหน้าอีกหนึ่งก้าวในทุกครั้ง**

  ---

  # 🌱 ช่วงแห่งการเติบโต

  ## **“ฉันกำลังสร้างนิสัยการเรียนของตัวเองทีละก้าว”**

  คุณไม่จำเป็นต้องทำทุกอย่างให้สมบูรณ์แบบตั้งแต่เริ่มต้น

  และไม่จำเป็นต้องเรียนหลายชั่วโมงตั้งแต่วันแรก

  เริ่มจากก้าวเล็ก ๆ

  เรียนวันละเล็กน้อย

  เรียนรู้ด้วยความตั้งใจของตัวเอง

  บันทึกสิ่งที่ได้เรียนรู้

  และพยายามทำอย่างต่อเนื่อง แม้ว่าความก้าวหน้าของคุณจะยังดูเล็กน้อยก็ตาม

  **ช่วงแห่งการเติบโต** คือช่วงเวลาที่คุณเริ่มต้นเรียนรู้และค่อย ๆ สร้างนิสัยการเรียนที่ดีให้กับตัวเอง

  ---

  # 🔥 ช่วงแห่งความท้าทาย

  ## **“ฉันอยากท้าทายตัวเองด้วยเป้าหมายที่สูงขึ้นอีกเล็กน้อย”**

  เมื่อเริ่มสร้างนิสัยการเรียนที่มั่นคงแล้ว ถึงเวลาที่จะก้าวไปอีกขั้น

  ตั้งเป้าหมายด้วยตัวเอง

  จากนั้นค่อย ๆ เดินไปสู่เป้าหมายนั้นทีละก้าว

  เมื่อฝึกฝนอย่างต่อเนื่อง คุณจะพัฒนาความสามารถในการเรียนรู้ เรียนได้อย่างมีประสิทธิภาพมากขึ้น และเรียนรู้ที่จะจัดการเวลาและความพยายามของตัวเอง

  **ช่วงแห่งความท้าทาย** คือช่วงเวลาที่คุณเริ่มตั้งเป้าหมายที่สูงขึ้นด้วยตัวเอง และลงมือทำอย่างจริงจังเพื่อไปให้ถึงเป้าหมายนั้น

  ---

  # 🏆 ช่วงแห่งความสำเร็จ

  ## **“ฉันกำลังทำให้เป้าหมายที่ฉันตั้งไว้ด้วยตัวเองกลายเป็นจริงทีละขั้น”**

  สิ่งนี้ไม่ได้หมายถึงเพียงการเรียนอย่างสม่ำเสมอ

  แต่หมายถึงการเรียนรู้ที่จะดูแลและจัดการกระบวนการเรียนรู้ของตัวเองทั้งหมด

  ### **วางแผนการเรียน → ลงมือทำ → บันทึก → ประเมิน → ปรับปรุง**

  ฉันวางแผน

  ฉันลงมือทำ

  ฉันบันทึกสิ่งที่ทำ

  ฉันทบทวนผลลัพธ์

  จากนั้นฉันนำสิ่งที่ได้เรียนรู้มาปรับแผนครั้งต่อไปให้ดีขึ้น

  **ช่วงแห่งความสำเร็จ** คือช่วงที่คุณสามารถเรียนรู้ด้วยตัวเองอย่างต่อเนื่อง และพัฒนาความสามารถในการจัดการเส้นทางการเรียนรู้ของตัวเองได้มากขึ้น

  ---

  # 🌱 → 🔥 → 🏆

  ## **เส้นทางการเรียนรู้ของฉันเติบโตขึ้นทีละก้าว**

  ### 🌱 ช่วงแห่งการเติบโต

  ↓
  **สร้างนิสัยการเรียนอย่างสม่ำเสมอ**

  ### 🔥 ช่วงแห่งความท้าทาย

  ↓
  **ท้าทายตัวเองด้วยเป้าหมายที่สูงขึ้น**

  ### 🏆 ช่วงแห่งความสำเร็จ

  ↓
  **ตั้งเป้าหมายด้วยตัวเองและทำให้สำเร็จด้วยความพยายามของตัวเอง**

  ---

  # **สิ่งที่สำคัญที่สุดไม่ใช่เงิน**

  ไม่ว่าคุณจะอยู่ในช่วงแห่งการเติบโต ช่วงแห่งความท้าทาย หรือช่วงแห่งความสำเร็จ

  คุณค่าที่แท้จริงของการเรียนไม่ได้อยู่ที่จำนวนเงินที่คุณจะได้รับ

  คำถามที่สำคัญกว่าคือ

  ## **“ฉันกำลังเรียนรู้และเติบโตขึ้นมากแค่ไหนจากความพยายามของตัวเอง?”**

  วันนี้ฉันดีกว่าเมื่อวานขึ้นอีกเล็กน้อยหรือไม่?

  วันนี้ฉันก้าวไปข้างหน้าอีกหนึ่งก้าวหรือไม่?

  **นี่ต่างหากคือความก้าวหน้าที่แท้จริงของการเรียนรู้**

  ---

  # 💰 ดาวมีความหมายอย่างไรต่อทุนการศึกษา?

  ปัจจุบันทุนการศึกษาของ GKE StudyUp คำนวณตามระบบดังนี้

  ### **⭐ 1 ดาว = 2, 3 หรือ 4 วอนเกาหลี (KRW)**

  แต่ความหมายที่สำคัญที่สุดของดาวไม่ใช่เงิน

  ## **⭐ ดาวคือบันทึกความพยายาม การเรียนรู้ และการเติบโตของคุณ**

  ผู้ปกครองสามารถมองเห็นความสำเร็จด้านการเรียนรู้ที่คุณสะสมมาตลอดเส้นทางการเรียนของคุณ

  จากความสำเร็จและความพยายามเหล่านั้น ผู้ปกครองสามารถมอบทุนการศึกษาให้คุณ เพื่อเป็น

  **การยอมรับในความพยายาม การให้กำลังใจ และการสนับสนุนคุณบนเส้นทางการเรียนรู้**

  จำนวนเงินทุนการศึกษาจะขึ้นอยู่กับการตัดสินใจของผู้ปกครอง โดยพิจารณาตามสถานการณ์และความสามารถของแต่ละครอบครัว

  ดังนั้น **ดาวและทุนการศึกษาจึงไม่ได้มีความหมายเดียวกัน**

  ### **ดาวบันทึกความพยายามและการเติบโตของคุณ**

  ### **ทุนการศึกษาเป็นการแสดงถึงกำลังใจ การยอมรับ และการสนับสนุนจากผู้ปกครองต่อเส้นทางของคุณ**

  จุดประสงค์ไม่ใช่การนำเงินมาเป็นตัววัดคุณค่าของการเรียนของเด็ก

  **เงินอาจเป็นกำลังใจอย่างหนึ่ง แต่สิ่งที่มีคุณค่ามากกว่าคือ นิสัยการเรียน ความมั่นใจในตัวเอง ความสามารถในการเรียนรู้ด้วยตัวเอง และการเติบโตที่เด็กแต่ละคนกำลังสร้างขึ้นในทุก ๆ วัน**

  ---

  # 🎯 จงจำไว้เสมอ!

  ## **การเรียนไม่ใช่การแข่งขันกับคนอื่น**

  สิ่งสำคัญไม่ใช่ว่าคุณเก่งกว่าคนอื่นหรือไม่

  สิ่งสำคัญคือ

  **ตัวคุณในวันนี้ดีกว่าตัวคุณเมื่อวานขึ้นอีกเล็กน้อย**

  และ

  **ตัวคุณในวันพรุ่งนี้ก้าวไปไกลกว่าตัวคุณในวันนี้อีกหนึ่งก้าว**

  วันนี้คุณเรียนเพิ่มอีก 10 นาที

  **นี่ก็เป็นการเติบโต**

  วันนี้คุณเขียนบันทึกการเรียนรู้ของตัวเอง

  **นี่ก็เป็นการเติบโต**

  วันนี้คุณทบทวนผลการสอบของตัวเองอย่างจริงจัง

  **นี่ก็เป็นการเติบโต**

  วันนี้การเรียนไม่เป็นไปตามแผน แต่คุณกลับมาวางแผนใหม่และตัดสินใจลองอีกครั้ง

  **นี่ก็เป็นการเติบโต**

  ---

  # **ความพยายามเล็ก ๆ เมื่อทำซ้ำอย่างต่อเนื่อง จะกลายเป็นนิสัย**

  # **นิสัยที่สะสมจะกลายเป็นความสามารถ**

  # **และความสามารถที่พัฒนาขึ้นทุกวัน จะกลายเป็นความสำเร็จ**

  ---

  # ⭐ **ฉันเป็นคนสร้างเส้นทางการเรียนรู้ของตัวเอง**

  ### **วางแผน → ลงมือทำ → บันทึก → ทบทวน → ท้าทายตัวเองอีกครั้ง**

  อย่ารอให้คนอื่นบอกว่าคุณควรเรียนเมื่อไร

  จงเรียนรู้ที่จะ

  **คิดด้วยตัวเอง**

  **ตัดสินใจด้วยตัวเอง**

  **ลงมือทำด้วยตัวเอง**

  **มองเห็นความก้าวหน้าของตัวเอง**

  และ

  **ก้าวต่อไปข้างหน้าอย่างต่อเนื่อง**

  ## **เส้นทางการเรียนรู้ของคุณเป็นของคุณเอง**

  และคุณสามารถสร้างเส้นทางนั้นด้วยตัวเอง

  **ทีละก้าว**

  ---

  GKE StudyUp ต้องการช่วยให้นักเรียนทุกคนพัฒนา **พลังแห่งการเรียนรู้ด้วยตัวเอง**

  ให้สามารถตั้งเป้าหมายของตัวเอง

  ก้าวไปสู่เป้าหมายนั้นอย่างต่อเนื่อง

  และเติบโตขึ้นทีละเล็กทีละน้อยในทุก ๆ วัน

  ความพยายามของคุณในวันนี้อาจดูเหมือนเป็นเรื่องเล็กมาก

  บางทีคุณอาจเรียนเพิ่มเพียง 10 นาที

  บางทีคุณอาจเขียนแผนสำหรับการเรียนครั้งต่อไป

  บางทีวันนี้คุณอาจพบกับความยากลำบาก แต่คุณก็ตัดสินใจที่จะเริ่มต้นใหม่อีกครั้ง

  ## **ทุกก้าวเหล่านี้มีคุณค่า**

  เพราะก้าวเล็ก ๆ ที่เรายังคงเดินต่อไปในทุกวัน

  อาจพาเราไปได้ไกลกว่าที่เราเคยคิดว่าตัวเองจะไปถึง

  และวันหนึ่ง เมื่อคุณหันกลับมามองเส้นทางที่เดินผ่านมา คุณอาจพูดกับตัวเองด้วยรอยยิ้มว่า

  ## **“ดีจริง ๆ ที่วันนั้นฉันไม่ยอมแพ้”**

  ---

  # 🌱 ช่วงแห่งการเติบโต → 🔥 ช่วงแห่งความท้าทาย → 🏆 ช่วงแห่งความสำเร็จ

  ## **ก้าวเล็ก ๆ ที่คุณทำในวันนี้ จะสร้างตัวคุณในวันพรุ่งนี้**

  **GKE StudyUp**

  **Global Knowledge Education**
  ''', // 태국어
  };

  // 🆕 현재 선택된 언어에 맞는 안내문 반환. 해당 언어가 아직 비어있으면(원장님이 아직
  // 안 채우신 언어) 영어로, 영어도 없으면 한국어로 자동 대체(fallback)되어 앱이
  // 절대 빈 화면을 보여주지 않도록 함.
  String get _scholarshipStudentNoticeText {
    final String code = DkeLang.current.toUpperCase();
    final String? text = _scholarshipStudentNoticeByLang[code];
    if (text != null && text.trim().isNotEmpty) return text;
    return _scholarshipStudentNoticeByLang['EN']!.trim().isNotEmpty
        ? _scholarshipStudentNoticeByLang['EN']!
        : _scholarshipStudentNoticeByLang['KO']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ThemeColors.luxuryDarkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 92,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/gsu_logo.png',
              width: 180,
              height: 24,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 0.5),
            Text(
              'MEMBER ACHIEVEMENT',
              textAlign: TextAlign.center,
              overflow: TextOverflow.fade,
              softWrap: false,
              maxLines: 1,
              style: GoogleFonts.gowunBatang(
                color: _ThemeColors.brandGolden,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DkeLang.current == 'KO'
                  ? '${_realUserName ?? "학습자"} ${_t("achievementWord")}'
                  : "${_realUserName ?? "Learner"} - ${_t('achievementWord')}",
              textAlign: TextAlign.center,
              overflow: TextOverflow.fade,
              softWrap: false,
              maxLines: 1,
              style: GoogleFonts.notoSansKr(
                color: _ThemeColors.brandGolden,
                fontWeight: FontWeight.bold,
                fontSize: 23,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isRecordsLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5C158)),
            )
          : IndexedStack(
              index: _currentBottomTab,
              children: [
                _buildLiveAchievementTabContent(),
                _buildAchievementStarsTabContent(),
              ],
            ),
      bottomNavigationBar: _isRecordsLoading
          ? null
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentBottomTab,
              backgroundColor: _ThemeColors.premiumCardBg,
              selectedItemColor: _ThemeColors.brandGolden,
              unselectedItemColor: Colors.white38,
              selectedLabelStyle: GoogleFonts.notoSansKr(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: GoogleFonts.notoSansKr(fontSize: 11),
              onTap: (index) => setState(() => _currentBottomTab = index),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.bolt_rounded),
                  label: _t('liveAchievementTab'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.emoji_events_rounded),
                  label: _t('liveStarsTab'),
                ),
              ],
            ),
    );
  }

  // 🆕 [장학금 방 UI 개편 2026-09-17] 탭1 "실시간 학습성취" — 기존에 이 화면에 있던 모든
  // 콘텐츠(종합리포트/상세분석 버튼, 레벨·별, 목표달성도, 성적 기록, 평가 차트, 일/주/월/연
  // 학습시간 그래프, 생활균형 등)를 그대로 담습니다. 내용은 단 하나도 바뀌지 않았고,
  // 감싸던 SingleChildScrollView/Padding/Column 구조만 별도 메서드로 옮겼습니다.
  Widget _buildLiveAchievementTabContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _ThemeColors.brandGolden.withOpacity(0.25),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _schoolGradeNameDisplay,
                    // 🆕 [요청 2026-09-04] 실제 "학교 학년 이름"으로 표시
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    maxLines: 1,
                    style: GoogleFonts.notoSansKr(
                      color: _ThemeColors.brandGolden,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DkeLang.currentLearnersMsg,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    maxLines: 1,
                    style: GoogleFonts.notoSansKr(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            Row(
              children: [
                _buildTopButton(
                  _t('totalReport'),
                  40,
                  _buildTotalReportContent,
                  isTotalReport: true,
                ),
                const SizedBox(width: 8),
                _buildTopButton(
                  _t('detailedAnalytics'),
                  60,
                  _buildDetailedReportContent,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 🆕 [⑤⑥⑦번] 오늘 학습한 과목 카드 - 타이머에서 기록한 오늘 세션이 이 화면에 실시간으로 보이도록 추가
            _buildTodaySessionsCard(),

            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _ThemeColors.brandGolden.withOpacity(0.25),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t('nextLevelRoad'),
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            maxLines: 1,
                            style: GoogleFonts.notoSansKr(
                              color: Colors.white70,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${_t('levelPrefix')}$_currentLevelNumber',
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            maxLines: 1,
                            style: GoogleFonts.notoSansKr(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildLuxuryGlowingStar(),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '$_totalStars ${_t('starsUnitSuffix')}',
                                  overflow: TextOverflow.fade,
                                  softWrap: false,
                                  maxLines: 1,
                                  style: GoogleFonts.gowunBatang(
                                    color: _ThemeColors.brandGolden,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            overflow: TextOverflow.fade,
                            softWrap: true,
                            text: TextSpan(
                              style: GoogleFonts.notoSansKr(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text: _t('friendRank'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                TextSpan(
                                  text: '$_realFriendRankDisplay\n\n',
                                  style: const TextStyle(
                                    color: _ThemeColors.brandGolden,
                                  ),
                                ),
                                TextSpan(
                                  text: _t('globalRank'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                TextSpan(
                                  text: _realGlobalRankDisplay,
                                  style: const TextStyle(
                                    color: _ThemeColors.brandGolden,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x2AFFFFFF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _t('targetUniversity'),
                                  overflow: TextOverflow.fade,
                                  softWrap: false,
                                  maxLines: 1,
                                  style: GoogleFonts.notoSansKr(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                // 🆕 [데이터 연결-버그 수정] 마이페이지에서 실제로 저장한 목표 대학을 표시.
                                // 아직 저장된 값이 없으면(신규 유저) 안내용 기본값(_t('snu'))을 그대로 보여줌.
                                Text(
                                  _realTargetUniversity ?? _t('snu'),
                                  style: GoogleFonts.notoSansKr(
                                    color: _ThemeColors.brandGolden,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.fade,
                                  softWrap: false,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _ThemeColors.brandGolden.withOpacity(0.25),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  _t('goalAttainment'),
                                  overflow: TextOverflow.fade,
                                  softWrap: false,
                                  maxLines: 1,
                                  style: GoogleFonts.notoSansKr(
                                    color: Colors.white70,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                "$_realGoalAttainmentPercent%",
                                style: GoogleFonts.notoSansKr(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          RichText(
                            overflow: TextOverflow.fade,
                            softWrap: true,
                            text: TextSpan(
                              style: GoogleFonts.notoSansKr(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                height: 1.5,
                              ),
                              children: [
                                TextSpan(
                                  text: _t('todayVsYesterday'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                TextSpan(
                                  text:
                                      "${_realTodayVsYesterdayPercent >= 0 ? '+' : ''}$_realTodayVsYesterdayPercent%\n\n",
                                  style: const TextStyle(
                                    color: _ThemeColors.brandGolden,
                                  ),
                                ),
                                TextSpan(
                                  text: _t('mostImprovedSubject'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                TextSpan(
                                  text:
                                      "${_realMostImprovedSubject != null ? _subjectName(_realMostImprovedSubject!) : _t('dataCollectingMsg')}\n\n",
                                  style: const TextStyle(
                                    color: _ThemeColors.brandGolden,
                                  ),
                                ),
                                TextSpan(
                                  text: _t('mostStudiedSubject'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                TextSpan(
                                  text: _realMostStudiedSubject != null
                                      ? _subjectName(_realMostStudiedSubject!)
                                      : _t('dataCollectingMsg'),
                                  style: const TextStyle(
                                    color: _ThemeColors.brandGolden,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0x1F34C759),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.greenAccent.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  RichText(
                                    overflow: TextOverflow.fade,
                                    softWrap: true,
                                    text: TextSpan(
                                      style: GoogleFonts.notoSansKr(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        height: 1.4,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: _t('totalStudyTimeLabel'),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              '${(_realTotalStudyMinutesAllTime / 60).toStringAsFixed(1)} ${_t('hoursUnitSuffix')}',
                                          style: const TextStyle(
                                            color: _ThemeColors.brandGolden,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            _buildMyExamScoreSection(),
            const SizedBox(height: 20),

            _buildFixedEvaluationChart(_selectedExamType ?? "주평가"),

            _buildBeautifulFeedbackDisplayPanel(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D1527),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: Color(0xFFE5C158),
                      width: 1.2,
                    ),
                  ),
                ),
                onPressed: () async {
                  String currentType = _selectedExamType ?? "주평가";
                  final filtered = _allRecords
                      .where((r) => r.type == currentType)
                      .toList();
                  String diagnosisText;

                  if (filtered.isEmpty) {
                    diagnosisText = _t('emptyFallbackShort');
                  } else {
                    final lastExam = filtered.last;
                    // 🆕 [2026-10-01] 저장·공유되는 진단서 (부모님 화면과 같은 글, 같은 평가는 언제 열어도 같은 글)
                    diagnosisText = await _archivedExamAnalysis(
                      type: currentType,
                      subject: lastExam.subject,
                      score: lastExam.score,
                      date: lastExam.date,
                    );
                  }

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('dke_parent_shared_type', currentType);
                  await prefs.setString(
                    'dke_parent_shared_diagnosis',
                    diagnosisText,
                  );

                  _showReportPopup(
                    context,
                    _t('diagReportTitle'),
                    diagnosisText,
                  );
                },
                icon: const Icon(
                  Icons.psychology_outlined,
                  color: Color(0xFFE5C158),
                  size: 18,
                ),
                label: Text(
                  "[${_examTypeLabel(_selectedExamType ?? '주평가')} ${_t('viewAnalysisReport')}] 🔺",
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  maxLines: 1,
                  style: GoogleFonts.notoSansKr(
                    color: const Color(0xFFE5C158),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Text(
              "Learning Duration Summary",
              overflow: TextOverflow.fade,
              softWrap: false,
              maxLines: 1,
              style: GoogleFonts.gowunBatang(
                color: _ThemeColors.brandGolden,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              _t('studyTime'),
              overflow: TextOverflow.fade,
              softWrap: false,
              maxLines: 1,
              style: GoogleFonts.notoSansKr(
                color: _ThemeColors.brandGolden,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              height: 52,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1527),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _ThemeColors.brandGolden.withOpacity(0.3),
                  width: 1.2,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorPadding: const EdgeInsets.symmetric(
                  horizontal: 0.5,
                  vertical: 3,
                ),
                indicator: const BoxDecoration(
                  color: _ThemeColors.brandGolden,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.white,
                labelStyle: GoogleFonts.notoSansKr(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 4.0,
                ),
                unselectedLabelStyle: GoogleFonts.notoSansKr(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 4.0,
                ),
                tabs: [
                  Tab(text: _t('daily')),
                  Tab(text: _t('weekly')),
                  Tab(text: _t('monthly')),
                  Tab(text: _t('yearly')),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildAdvancedChartDashboard(_tabController.index),
            _buildLiveStatusCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 🆕 [장학금 방 UI 개편 2026-09-17] 탭2 "실시간 성취별" — 기본별/보너스별 내역과
  // 안내문을 담은 "나의 성취별 현황" 카드를 별도 탭으로 분리했습니다.
  // 🆕 [부모 운동 응원별 2026-09-29] 그 바로 아래에 "부모님이 보내 준 응원별" 카드 추가
  // (자녀 본인 별·장학금과 완전히 별개 - 읽기만 함)
  Widget _buildAchievementStarsTabContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAchievementStarsCard(),
            _buildParentGiftStarsCard(),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // 🆕 [부모 운동 응원별 2026-09-29] 부모님이 운동해서 모아 보내 준 별 — 진한 황금색 카드.
  // links/{내 코드}의 parentGiftStars / parentGiftSpecialStars / parentGiftHistory를
  // 실시간으로 읽기만 함. 특별 축하 별은 따로 짙은 칸에 금색 글씨로 구분해서 보여줌.
  // ============================================================================
  Widget _buildParentGiftStarsCard() {
    if (_myLinkCode == null) return const SizedBox.shrink(); // 부모와 연결 전이면 표시 안 함
    // 🆕 [B안 2026-09-30] 금색 머리띠 + 남색 몸통 (명품 포장처럼 금색은 머리띠·숫자·테두리에만)
    // 🆕 [응원 가족 2026-09-30] 보낸 사람별(엄마·할머니·삼촌…) 목록 + 전체 합계
    const Color ink = Color(0xFF1A1203);
    const Color deepGold = Color(0xFFD4AF37);
    const Color paleGold = Color(0xFFFFE9A8);
    const Color softGold = Color(0xFFC9B27A);
    const Color cream = Color(0xFFFFF6D6);
    const Color navy = Color(0xFF0D1527);
    const Color navyInner = Color(0xFF111A2E);
    final String lang = DkeLang.current;
    final bool isKo = lang == 'KO';

    String relLabel(String rel, String relText) =>
        rel == 'other' && relText.trim().isNotEmpty ? relText.trim() : cs('rel_$rel', lang: lang);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FamilyLinkService.watch(_myLinkCode!),
      builder: (context, snapshot) {
        final Map<String, dynamic> data = snapshot.data?.data() ?? {};
        final int legacyTotal = (data['parentGiftStars'] as num?)?.toInt() ?? 0;
        final int legacySpecial = (data['parentGiftSpecialStars'] as num?)?.toInt() ?? 0;
        final List<Map<String, dynamic>> legacyRecent = ((data['parentGiftHistory'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
            .reversed
            .take(3)
            .toList();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: SupporterService.watchGifts(_myLinkCode!),
          builder: (context, giftSnap) {
            final List<Map<String, dynamic>> gifts = giftSnap.data?.docs.map((d) => d.data()).toList() ?? [];

            // 보낸 사람별로 모으기 (보호자는 예전부터 합계가 있으므로, 전체 합계에는 응원 가족 것만 더함)
            int supTotal = 0;
            int supSpecial = 0;
            final Map<String, Map<String, dynamic>> bySender = {};
            for (final g in gifts) {
              final int st = (g['stars'] as num?)?.toInt() ?? 0;
              final bool sp = g['type'] == 'special';
              if (g['role'] == 'supporter') {
                supTotal += st;
                if (sp) supSpecial += st;
              }
              final String uid = (g['fromUid'] as String?) ?? '?';
              final Map<String, dynamic> row = bySender.putIfAbsent(uid, () => {
                'name': (g['fromName'] as String?) ?? '',
                'rel': (g['fromRelation'] as String?) ?? 'other',
                'relText': (g['fromRelationText'] as String?) ?? '',
                'stars': 0,
                'special': 0,
              });
              row['stars'] = (row['stars'] as int) + st;
              if (sp) row['special'] = (row['special'] as int) + st;
            }
            final List<Map<String, dynamic>> senders = bySender.values.toList()
              ..sort((a, b) => (b['stars'] as int).compareTo(a['stars'] as int));

            final int total = legacyTotal + supTotal;
            final int special = legacySpecial + supSpecial;
            final int normal = total - special;

            // 최근 받은 응원 3개: 보낸 사람이 기록된 새 방식이 있으면 그것을, 없으면 예전 기록을 보여줌
            final bool useGifts = gifts.isNotEmpty;
            final List<Map<String, dynamic>> recent = useGifts ? gifts.take(3).toList() : legacyRecent;

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 18),
              decoration: BoxDecoration(
                color: navy,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: deepGold, width: 1.5),
                boxShadow: [BoxShadow(color: deepGold.withOpacity(0.25), blurRadius: 22, spreadRadius: 1)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------- 금색 머리띠 ----------
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE9C860), deepGold, Color(0xFFB8922A)],
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite_rounded, color: ink, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: isKo
                                ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('CHEER STARS', style: GoogleFonts.gowunBatang(color: ink, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                                Text(csKo('giftTitle'), style: GoogleFonts.notoSansKr(color: ink, fontWeight: FontWeight.w900, fontSize: 15.5)),
                              ],
                            )
                                : Text(cs('giftTitle', lang: lang), style: GoogleFonts.notoSans(color: ink, fontWeight: FontWeight.w900, fontSize: 15)),
                          ),
                        ],
                      ),
                    ),

                    // ---------- 남색 몸통 ----------
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 받은 응원별 전체
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cs('giftTotal', lang: lang), style: GoogleFonts.notoSansKr(color: softGold, fontSize: 12)),
                                    const SizedBox(height: 2),
                                    Text(
                                      cs('nStars', lang: lang, args: {'n': total}),
                                      style: GoogleFonts.notoSansKr(color: const Color(0xFFFFD700), fontWeight: FontWeight.w900, fontSize: 30),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.45), blurRadius: 18, spreadRadius: 1)],
                                ),
                                child: const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 38),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 일반 응원 / 특별 축하
                          Row(
                            children: [
                              Expanded(child: _giftStat(Icons.star_rounded, cs('giftNormal', lang: lang), cs('nStars', lang: lang, args: {'n': normal}), highlight: false)),
                              const SizedBox(width: 10),
                              Expanded(child: _giftStat(Icons.celebration_rounded, cs('giftSpecial', lang: lang), cs('nStars', lang: lang, args: {'n': special}), highlight: true)),
                            ],
                          ),

                          // 🆕 [응원 가족] 응원해 주는 가족 (보낸 사람별 합계)
                          if (senders.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(cs('giftByFamily', lang: lang), style: GoogleFonts.notoSansKr(color: deepGold, fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 8),
                            ...senders.map((r) {
                              final String rel = r['rel'] as String;
                              final String name = r['name'] as String;
                              final int sp = r['special'] as int;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                decoration: BoxDecoration(color: navyInner, borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                  children: [
                                    Text(SupporterService.relationEmoji[rel] ?? '💛', style: const TextStyle(fontSize: 17)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${relLabel(rel, r['relText'] as String)}${name.isNotEmpty ? ' ($name)' : ''}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.notoSansKr(color: cream, fontWeight: FontWeight.bold, fontSize: 12.5),
                                      ),
                                    ),
                                    Text(
                                      cs('nStars', lang: lang, args: {'n': r['stars']}),
                                      style: GoogleFonts.notoSansKr(color: const Color(0xFFFFD700), fontWeight: FontWeight.w900, fontSize: 13),
                                    ),
                                    if (sp > 0) ...[
                                      const SizedBox(width: 6),
                                      Text('🎉 $sp', style: GoogleFonts.notoSansKr(color: paleGold, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ],
                          _buildFamilyScholarSection(gifts, lang), // 🆕 [가족 장학금 2026-10-02]
                          // 최근 받은 응원 3개
                          if (recent.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(cs('giftRecent', lang: lang), style: GoogleFonts.notoSansKr(color: deepGold, fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 8),
                            ...recent.map((h) {
                              final int stars = (h['stars'] as num?)?.toInt() ?? 0;
                              final bool isSpecial = h['type'] == 'special';
                              final String message = (h['message'] as String?) ?? '';
                              final dynamic sentAt = h['sentAt'];
                              final DateTime? when = sentAt is Timestamp ? sentAt.toDate() : null;
                              final String dateText = when != null ? '${when.month}/${when.day}' : '';
                              // 보낸 사람 (새 방식 기록에만 있음)
                              final String rel = (h['fromRelation'] as String?) ?? '';
                              final String who = rel.isEmpty ? '' : relLabel(rel, (h['fromRelationText'] as String?) ?? '');
                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: navyInner,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isSpecial ? deepGold.withOpacity(0.6) : Colors.white10),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isSpecial ? '🎉' : '⭐', style: const TextStyle(fontSize: 16)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$dateText · ${cs('nStars', lang: lang, args: {'n': stars})}${who.isNotEmpty ? ' · ${SupporterService.relationEmoji[rel] ?? ''} $who' : ''}',
                                            style: GoogleFonts.notoSansKr(color: isSpecial ? paleGold : cream, fontWeight: FontWeight.bold, fontSize: 12.5),
                                          ),
                                          if (message.isNotEmpty)
                                            Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, height: 1.4)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ] else ...[
                            const SizedBox(height: 14),
                            Text(cs('giftEmpty', lang: lang), style: GoogleFonts.notoSansKr(color: Colors.white60, fontSize: 12, height: 1.5)),
                          ],
                          const SizedBox(height: 12),
                          Text(cs('giftNote', lang: lang), style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 11, height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  // ============================================================================
  // 🆕 [가족 장학금 2026-10-02] 응원 가족 각자가 정한 장학금의 이번 달 · 지난달 결산 (보기만)
  // 앱은 금액만 보여 주고, 실제 전달은 가족이 직접 함
  // ============================================================================
  Widget _buildFamilyScholarSection(List<Map<String, dynamic>> gifts, String lang) {
    const Color deepGold = Color(0xFFD4AF37);
    const Color cream = Color(0xFFFFF6D6);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: SupporterService.watchPlans(_myLinkCode!),
      builder: (context, snap) {
        final Map<String, Map<String, dynamic>> plans = {
          for (final d in snap.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[]) d.id: d.data(),
        };
        final List<FamilyScholarRow> rows =
        SupporterService.summarize(gifts, plans).where((r) => r.planCap > 0).toList();
        if (rows.isEmpty) return const SizedBox.shrink();
        final int total = rows.fold<int>(0, (s, r) => s + r.monthWon);
        final int lastTotal = rows.fold<int>(0, (s, r) => s + r.lastMonthWon);
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF111A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: deepGold.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💰 ${cs('famTitle', lang: lang)}', style: GoogleFonts.notoSansKr(color: deepGold, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              ...rows.map((r) {
                final String who = r.relation == 'other' && r.relationText.trim().isNotEmpty
                    ? r.relationText.trim()
                    : cs('rel_${r.relation}', lang: lang);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text(SupporterService.relationEmoji[r.relation] ?? '💛', style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$who${r.name.isNotEmpty ? ' (${r.name})' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.notoSansKr(color: cream, fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(famWonText(r.monthWon, lang: lang), style: GoogleFonts.notoSansKr(color: const Color(0xFFFFD700), fontWeight: FontWeight.w900, fontSize: 13)),
                    ],
                  ),
                );
              }),
              const Divider(color: Colors.white12, height: 16),
              Row(
                children: [
                  Expanded(child: Text(cs('famMonthTotal', lang: lang), style: GoogleFonts.notoSansKr(color: cream, fontSize: 12.5, fontWeight: FontWeight.bold))),
                  Text(famWonText(total, lang: lang), style: GoogleFonts.notoSansKr(color: const Color(0xFFFFD700), fontWeight: FontWeight.w900, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(child: Text(cs('famLastTotal', lang: lang), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11.5))),
                  Text(famWonText(lastTotal, lang: lang), style: GoogleFonts.notoSansKr(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12.5)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 🆕 [B안] 일반 응원 = 남색 칸 / 특별 축하 = 짙은 금빛 칸에 금테 (따로 구분)
  Widget _giftStat(IconData icon, String label, String value, {required bool highlight}) {
    const Color deepGold = Color(0xFFD4AF37);
    const Color paleGold = Color(0xFFFFE9A8);
    const Color softGold = Color(0xFFC9B27A);
    const Color cream = Color(0xFFFFF6D6);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF2A1F05) : const Color(0xFF111A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highlight ? deepGold : Colors.white10, width: highlight ? 1.2 : 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: highlight ? paleGold : deepGold, size: 20),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.notoSansKr(color: highlight ? paleGold : cream, fontWeight: FontWeight.w900, fontSize: 17)),
          Text(label, style: GoogleFonts.notoSansKr(color: highlight ? paleGold.withOpacity(0.85) : softGold, fontSize: 11.5)),
        ],
      ),
    );
  }

  // 🆕 [2, 3번] 시험 유형(주평가/단원평가 등) 한글 키는 데이터 키로 그대로 유지하되, 화면 표시만 영문 병기
  static const Map<String, Map<String, String>> _examTypeMap = {
    "주평가": {
      'KO': '주평가',
      'EN': 'Weekly',
      'JA': '週次評価',
      'ZH': '周评估',
      'FR': 'Éval. hebdo',
      'DE': 'Wochentest',
      'RU': 'Еженед. оценка',
      'AR': 'تقييم أسبوعي',
      'HI': 'साप्ताहिक मूल्यांकन',
      'VI': 'Đánh giá tuần',
      'ES': 'Eval. semanal',
      'TH': 'ประเมินรายสัปดาห์',
    },
    "단원평가": {
      'KO': '단원평가',
      'EN': 'Unit Test',
      'JA': '単元評価',
      'ZH': '单元测验',
      'FR': "Test d'unité",
      'DE': 'Einheitstest',
      'RU': 'Тест по разделу',
      'AR': 'اختبار الوحدة',
      'HI': 'यूनिट टेस्ट',
      'VI': 'Kiểm tra chương',
      'ES': 'Prueba de unidad',
      'TH': 'ทดสอบบทเรียน',
    },
    "중간고사": {
      'KO': '중간고사',
      'EN': 'Midterm',
      'JA': '中間試験',
      'ZH': '期中考试',
      'FR': 'Mi-parcours',
      'DE': 'Zwischenprüfung',
      'RU': 'Промежуточный',
      'AR': 'اختبار نصفي',
      'HI': 'मिडटर्म',
      'VI': 'Giữa kỳ',
      'ES': 'Parcial',
      'TH': 'กลางภาค',
    },
    "기말고사": {
      'KO': '기말고사',
      'EN': 'Final',
      'JA': '期末試験',
      'ZH': '期末考试',
      'FR': 'Final',
      'DE': 'Abschlussprüfung',
      'RU': 'Итоговый',
      'AR': 'اختبار نهائي',
      'HI': 'फाइनल',
      'VI': 'Cuối kỳ',
      'ES': 'Final',
      'TH': 'ปลายภาค',
    },
    "모의고사": {
      'KO': '모의고사',
      'EN': 'Mock Exam',
      'JA': '模試',
      'ZH': '模拟考试',
      'FR': 'Examen blanc',
      'DE': 'Testexamen',
      'RU': 'Пробный экзамен',
      'AR': 'اختبار تجريبي',
      'HI': 'मॉक परीक्षा',
      'VI': 'Thi thử',
      'ES': 'Examen simulado',
      'TH': 'ข้อสอบจำลอง',
    },
  };

  static String _examTypeLabel(String typeKey) {
    final map = _examTypeMap[typeKey];
    if (map == null) return typeKey;
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? typeKey;
  }

  // 🆕 [12개국 확장] 난이도 / 실수 원인 / 복습 필요 여부 — 데이터 키(한글)는 그대로 저장, 화면 표시만 다국어 병기
  static const Map<String, Map<String, String>> _difficultyMap = {
    "매우쉬움": {
      'KO': '매우쉬움',
      'EN': 'Very Easy',
      'JA': 'とても簡単',
      'ZH': '非常容易',
      'FR': 'Très facile',
      'DE': 'Sehr leicht',
      'RU': 'Очень легко',
      'AR': 'سهل جدًا',
      'HI': 'बहुत आसान',
      'VI': 'Rất dễ',
      'ES': 'Muy fácil',
      'TH': 'ง่ายมาก',
    },
    "쉬움": {
      'KO': '쉬움',
      'EN': 'Easy',
      'JA': '簡単',
      'ZH': '容易',
      'FR': 'Facile',
      'DE': 'Leicht',
      'RU': 'Легко',
      'AR': 'سهل',
      'HI': 'आसान',
      'VI': 'Dễ',
      'ES': 'Fácil',
      'TH': 'ง่าย',
    },
    "보통": {
      'KO': '보통',
      'EN': 'Normal',
      'JA': '普通',
      'ZH': '普通',
      'FR': 'Normal',
      'DE': 'Normal',
      'RU': 'Средне',
      'AR': 'متوسط',
      'HI': 'सामान्य',
      'VI': 'Trung bình',
      'ES': 'Normal',
      'TH': 'ปานกลาง',
    },
    "어려움": {
      'KO': '어려움',
      'EN': 'Hard',
      'JA': '難しい',
      'ZH': '困难',
      'FR': 'Difficile',
      'DE': 'Schwer',
      'RU': 'Сложно',
      'AR': 'صعب',
      'HI': 'कठिन',
      'VI': 'Khó',
      'ES': 'Difícil',
      'TH': 'ยาก',
    },
    "매우어려움": {
      'KO': '매우어려움',
      'EN': 'Very Hard',
      'JA': 'とても難しい',
      'ZH': '非常困难',
      'FR': 'Très difficile',
      'DE': 'Sehr schwer',
      'RU': 'Очень сложно',
      'AR': 'صعب جدًا',
      'HI': 'बहुत कठिन',
      'VI': 'Rất khó',
      'ES': 'Muy difícil',
      'TH': 'ยากมาก',
    },
  };

  static String _difficultyLabel(String key) {
    final map = _difficultyMap[key];
    if (map == null) return key;
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? key;
  }

  // 🆕 [2026-09-27] 영문 + 한글 함께 보여주기 (기본모드: 영문 위·한글 아래 / 외국어: 그 언어만)
  static String _biT(String key) {
    final map = _uiText[key];
    if (map == null) return key;
    if (DkeLang.isForeignSelected) return _t(key);
    return "${map['EN'] ?? ''}\n${map['KO'] ?? ''}";
  }

  // 🆕 [2026-09-27] 별 개수·횟수 단위 12개 언어
  static const Map<String, String> _kStarUnit = {'KO': '개', 'EN': 'stars', 'JA': '個', 'ZH': '颗', 'FR': 'étoiles', 'DE': 'Sterne', 'RU': 'звёзд', 'AR': 'نجمة', 'HI': 'सितारे', 'VI': 'sao', 'ES': 'estrellas', 'TH': 'ดวง'};
  static const Map<String, String> _kTimesUnit = {'KO': '회', 'EN': 'times', 'JA': '回', 'ZH': '次', 'FR': 'fois', 'DE': 'Mal', 'RU': 'раз', 'AR': 'مرة', 'HI': 'बार', 'VI': 'lần', 'ES': 'veces', 'TH': 'ครั้ง'};

  // 기본모드 "690개 / stars", 외국어 "690 星" 처럼
  static String _starsText(int n) {
    if (DkeLang.isForeignSelected) return '$n ${_kStarUnit[DkeLang.current] ?? 'stars'}';
    return '$n개 / stars';
  }

  // 기본모드 "3회 / times", 외국어 "3 回" 처럼
  static String _timesText(int n) {
    if (DkeLang.isForeignSelected) return '$n ${_kTimesUnit[DkeLang.current] ?? 'times'}';
    return '$n회 / times';
  }

  // 🆕 [2026-09-27] 장학금 유형 이름 12개 언어 (순서: 성장형 / 도전형 / 성취형)
  static const List<Map<String, String>> _kTypeLabels = [
    {'KO': '성장형', 'EN': 'Growth', 'JA': '成長型', 'ZH': '成长型', 'FR': 'Croissance', 'DE': 'Wachstum', 'RU': 'Рост', 'AR': 'النمو', 'HI': 'विकास', 'VI': 'Phát triển', 'ES': 'Crecimiento', 'TH': 'เติบโต'},
    {'KO': '도전형', 'EN': 'Challenge', 'JA': '挑戦型', 'ZH': '挑战型', 'FR': 'Défi', 'DE': 'Herausforderung', 'RU': 'Вызов', 'AR': 'التحدي', 'HI': 'चुनौती', 'VI': 'Thử thách', 'ES': 'Desafío', 'TH': 'ท้าทาย'},
    {'KO': '성취형', 'EN': 'Achievement', 'JA': '達成型', 'ZH': '成就型', 'FR': 'Réussite', 'DE': 'Erfolg', 'RU': 'Достижение', 'AR': 'الإنجاز', 'HI': 'उपलब्धि', 'VI': 'Thành tựu', 'ES': 'Logro', 'TH': 'ความสำเร็จ'},
  ];

  // 제목: 기본모드 "Growth · (영문 제목)" 줄 + "성장형 · (한글 제목)" 줄 / 외국어: 그 언어 한 줄
  static String _typeTitleLine(int typeIndex) {
    final Map<String, String> tl = _kTypeLabels[typeIndex];
    final Map<String, String>? title = _uiText['thisMonthEstimatedScholarship'];
    if (DkeLang.isForeignSelected) {
      return "${tl[DkeLang.current] ?? tl['EN']} · ${_t('thisMonthEstimatedScholarship')}";
    }
    return "${tl['EN']} · ${title?['EN'] ?? ''}\n${tl['KO']} · ${title?['KO'] ?? ''}";
  }

  // 🆕 [2026-09-27] 원 단위 12개 언어 - 기본모드 "13,800원 / won", 외국어 "13,800 ウォン" 처럼
  static const Map<String, String> _kWonUnit = {'KO': '원', 'EN': 'won', 'JA': 'ウォン', 'ZH': '韩元', 'FR': 'won', 'DE': 'Won', 'RU': 'вон', 'AR': 'وون', 'HI': 'वॉन', 'VI': 'won', 'ES': 'won', 'TH': 'วอน'};

  static String _wonText(String formatted) {
    if (DkeLang.isForeignSelected) return '$formatted ${_kWonUnit[DkeLang.current] ?? 'won'}';
    return '$formatted원 / won';
  }

  static const Map<String, Map<String, String>> _causeMap = {
    "개념부족": {
      'KO': '개념부족',
      'EN': 'Concept Gap',
      'JA': '概念不足',
      'ZH': '概念不足',
      'FR': 'Manque de concept',
      'DE': 'Konzeptlücke',
      'RU': 'Пробел в понятиях',
      'AR': 'ضعف في المفهوم',
      'HI': 'अवधारणा की कमी',
      'VI': 'Thiếu khái niệm',
      'ES': 'Falta de concepto',
      'TH': 'ขาดความเข้าใจแนวคิด',
    },
    "계산실수": {
      'KO': '계산실수',
      'EN': 'Calc Error',
      'JA': '計算ミス',
      'ZH': '计算错误',
      'FR': 'Erreur de calcul',
      'DE': 'Rechenfehler',
      'RU': 'Ошибка в расчёте',
      'AR': 'خطأ حسابي',
      'HI': 'गणना त्रुटि',
      'VI': 'Lỗi tính toán',
      'ES': 'Error de cálculo',
      'TH': 'คำนวณผิด',
    },
    "시간부족": {
      'KO': '시간부족',
      'EN': 'Time Short',
      'JA': '時間不足',
      'ZH': '时间不足',
      'FR': 'Manque de temps',
      'DE': 'Zeitmangel',
      'RU': 'Не хватило времени',
      'AR': 'ضيق الوقت',
      'HI': 'समय की कमी',
      'VI': 'Thiếu thời gian',
      'ES': 'Falta de tiempo',
      'TH': 'เวลาไม่พอ',
    },
    "문해력 부족": {
      'KO': '문해력 부족',
      'EN': 'Reading Gap',
      'JA': '読解力不足',
      'ZH': '阅读理解不足',
      'FR': 'Manque de lecture',
      'DE': 'Leseschwäche',
      'RU': 'Слабое понимание текста',
      'AR': 'ضعف في الفهم القرائي',
      'HI': 'पठन कमी',
      'VI': 'Thiếu kỹ năng đọc hiểu',
      'ES': 'Falta de comprensión lectora',
      'TH': 'ขาดทักษะการอ่าน',
    },
    "긴장": {
      'KO': '긴장',
      'EN': 'Nervous',
      'JA': '緊張',
      'ZH': '紧张',
      'FR': 'Nervosité',
      'DE': 'Nervosität',
      'RU': 'Нервозность',
      'AR': 'التوتر',
      'HI': 'घबराहट',
      'VI': 'Lo lắng',
      'ES': 'Nerviosismo',
      'TH': 'ความตื่นเต้น',
    },
    "집중력 부족": {
      'KO': '집중력 부족',
      'EN': 'Focus Gap',
      'JA': '集中力不足',
      'ZH': '注意力不足',
      'FR': 'Manque de concentration',
      'DE': 'Konzentrationsmangel',
      'RU': 'Недостаток концентрации',
      'AR': 'ضعف التركيز',
      'HI': 'ध्यान की कमी',
      'VI': 'Thiếu tập trung',
      'ES': 'Falta de concentración',
      'TH': 'สมาธิไม่พอ',
    },
    "기타": {
      'KO': '기타',
      'EN': 'Other',
      'JA': 'その他',
      'ZH': '其他',
      'FR': 'Autre',
      'DE': 'Sonstiges',
      'RU': 'Другое',
      'AR': 'أخرى',
      'HI': 'अन्य',
      'VI': 'Khác',
      'ES': 'Otro',
      'TH': 'อื่นๆ',
    },
  };

  static String _causeLabel(String key) {
    final map = _causeMap[key];
    if (map == null) return key;
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? key;
  }

  static const Map<String, Map<String, String>> _reviewMap = {
    "필요": {
      'KO': '필요',
      'EN': 'Needed',
      'JA': '必要',
      'ZH': '需要',
      'FR': 'Nécessaire',
      'DE': 'Nötig',
      'RU': 'Нужно',
      'AR': 'مطلوب',
      'HI': 'आवश्यक',
      'VI': 'Cần thiết',
      'ES': 'Necesario',
      'TH': 'จำเป็น',
    },
    "예정": {
      'KO': '예정',
      'EN': 'Planned',
      'JA': '予定',
      'ZH': '计划中',
      'FR': 'Prévu',
      'DE': 'Geplant',
      'RU': 'Запланировано',
      'AR': 'مخطط له',
      'HI': 'योजनाबद्ध',
      'VI': 'Đã lên kế hoạch',
      'ES': 'Planeado',
      'TH': 'วางแผนไว้',
    },
    "불필요": {
      'KO': '불필요',
      'EN': 'Not Needed',
      'JA': '不要',
      'ZH': '不需要',
      'FR': 'Non nécessaire',
      'DE': 'Nicht nötig',
      'RU': 'Не требуется',
      'AR': 'غير مطلوب',
      'HI': 'आवश्यक नहीं',
      'VI': 'Không cần',
      'ES': 'No necesario',
      'TH': 'ไม่จำเป็น',
    },
  };

  static String _reviewLabel(String key) {
    final map = _reviewMap[key];
    if (map == null) return key;
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? key;
  }

  // 🆕 [12개국 어순 대응]: 한국어는 "2학년"처럼 숫자+단어, 대부분의 다른 언어는 "Grade 2"처럼 단어+숫자 순서라
  // 단순 문자열 이어붙이기로는 어순이 깨집니다. 언어별로 순서를 맞춰 반환합니다.
  static String _gradeText(int g) {
    final word = _t('gradeLabel');
    return DkeLang.current == 'KO' ? "$g$word" : "$word $g";
  }

  static String _semesterText(int s) {
    final word = _t('semesterLabel');
    return DkeLang.current == 'KO' ? "$s$word" : "$word $s";
  }

  Widget _buildMyExamScoreSection() {
    final List<String> examTypes = ["주평가", "단원평가", "중간고사", "기말고사", "모의고사"];
    final List<String> years = ["2026년", "2027년", "2028년", "2029년", "2030년"];
    final List<String> months = List.generate(12, (i) => "${i + 1}월");
    final List<String> weeks = ["1주차", "2주차", "3주차", "4주차", "5주차"];
    final List<String> bigUnits = List.generate(12, (i) => "대단원 ${i + 1}");
    final List<String> midUnits = ["중단원 1", "중단원 2", "중단원 3", "중단원 4"];
    final List<String> semesters = ["1학기", "2학기"];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ThemeColors.premiumCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _ThemeColors.brandGolden.withOpacity(0.2),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(
              () => _isScoreSectionExpanded = !_isScoreSectionExpanded,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _t('myScoreRecord'),
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    maxLines: 1,
                    style: GoogleFonts.notoSansKr(
                      color: _ThemeColors.brandGolden,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(
                  _isScoreSectionExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _ThemeColors.brandGolden,
                  size: 22,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (_isScoreSectionExpanded) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: examTypes.map((type) {
                  bool isSelected = _selectedExamType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedExamType = isSelected ? null : type;
                          if (_selectedExamType != null) {
                            _filterExamType = _selectedExamType!;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _ThemeColors.brandGolden
                              : Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _ThemeColors.brandGolden.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          _examTypeLabel(type),
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          maxLines: 1,
                          style: GoogleFonts.notoSansKr(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            if (_selectedExamType != null) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          "[${_examTypeLabel(_selectedExamType!)} ${_t('entryAndHistory')}]",
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          maxLines: 1,
                          style: GoogleFonts.notoSansKr(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_selectedExamType == "주평가") ...[
                    _buildSubFilterLabel(_t('yearSelect')),
                    _buildSubScrollRow(
                      years,
                      _inputYear,
                      (v) => setState(() => _inputYear = v!),
                    ),
                    const SizedBox(height: 8),
                    _buildSubFilterLabel(_t('monthSelect')),
                    _buildSubScrollRow(
                      months,
                      _inputMonth,
                      (v) => setState(() => _inputMonth = v!),
                      controller: _monthScrollController,
                    ),
                    const SizedBox(height: 8),
                    _buildSubFilterLabel(_t('weekSelect')),
                    _buildSubScrollRow(
                      weeks,
                      _inputWeek,
                      (v) => setState(() => _inputWeek = v!),
                    ),
                  ] else if (_selectedExamType == "단원평가") ...[
                    _buildSubFilterLabel(
                      '${_t('bigUnitSelect')} (${DkeLang.current == 'KO' ? '여러 개 선택 가능 - 범위로 입력됨' : 'Multi-select for a range'})',
                    ),
                    _buildUnitMultiSelectRow(
                      bigUnits,
                      _inputBigUnits,
                      (item) => () {
                        setState(() {
                          if (_inputBigUnits.contains(item)) {
                            if (_inputBigUnits.length > 1)
                              _inputBigUnits.remove(item);
                          } else {
                            _inputBigUnits.add(item);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildSubFilterLabel(
                      '${_t('midUnitSelect')} (${DkeLang.current == 'KO' ? '여러 개 선택 가능 - 범위로 입력됨' : 'Multi-select for a range'})',
                    ),
                    _buildUnitMultiSelectRow(
                      midUnits,
                      _inputMidUnits,
                      (item) => () {
                        setState(() {
                          if (_inputMidUnits.contains(item)) {
                            if (_inputMidUnits.length > 1)
                              _inputMidUnits.remove(item);
                          } else {
                            _inputMidUnits.add(item);
                          }
                        });
                      },
                    ),
                  ] else ...[
                    _buildSubFilterLabel(_t('semesterSelect')),
                    Row(
                      children: semesters
                          .map(
                            (sem) => _buildSubMiniBtn(
                              sem,
                              _inputSemesterGroup == sem,
                              () => setState(() => _inputSemesterGroup = sem),
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 14),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 12),

                  Text(
                    _t('chartTarget'),
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    maxLines: 1,
                    style: GoogleFonts.notoSansKr(
                      color: _ThemeColors.brandGolden,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _filterGrade,
                              dropdownColor: _ThemeColors.premiumCardBg,
                              style: GoogleFonts.notoSansKr(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: _ThemeColors.brandGolden,
                                size: 16,
                              ),
                              items: [1, 2, 3]
                                  .map(
                                    (g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(_t('gradeLabel') + " $g"),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null)
                                  setState(() {
                                    _filterGrade = v;
                                  });
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _filterSemester,
                              dropdownColor: _ThemeColors.premiumCardBg,
                              style: GoogleFonts.notoSansKr(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: _ThemeColors.brandGolden,
                                size: 16,
                              ),
                              items: [1, 2]
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(_t('semesterLabel') + " $s"),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null)
                                  setState(() {
                                    _filterSemester = v;
                                  });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 🆕 [혼동 방지] 위쪽 "그래프 출력 타겟 지정"과 헷갈리지 않도록, 지금 입력하는 새 기록용임을 명시
              Text(
                _t('newRecordGradeSemesterLabel'),
                overflow: TextOverflow.fade,
                softWrap: false,
                maxLines: 1,
                style: GoogleFonts.notoSansKr(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _inputGrade,
                      decoration: InputDecoration(
                        labelText: _t('gradeLabel'),
                        labelStyle: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                      dropdownColor: _ThemeColors.premiumCardBg,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      items: [1, 2, 3]
                          .map(
                            (g) => DropdownMenuItem(
                              value: g,
                              child: Text(_t('gradeLabel') + " $g"),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null)
                          setState(() {
                            _inputGrade = v;
                          });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _inputSemester,
                      decoration: InputDecoration(
                        labelText: _t('semesterLabel'),
                        labelStyle: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                      dropdownColor: _ThemeColors.premiumCardBg,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      items: [1, 2]
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(_t('semesterLabel') + " $s"),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null)
                          setState(() {
                            _inputSemester = v;
                          });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subjectController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: _t('subjectHint'),
                        hintStyle: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _unitController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: _t('unitHint'),
                        hintStyle: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _scoreController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: _t('scoreLabel'),
                        hintStyle: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _ThemeColors.brandGolden,
                    ),
                    onPressed: () {
                      if (_subjectController.text.isEmpty ||
                          _scoreController.text.isEmpty)
                        return;
                      double? parsedScore = double.tryParse(
                        _scoreController.text,
                      );
                      if (parsedScore == null) return;

                      String generatedUnitLabel = _unitController.text;
                      if (_selectedExamType == "주평가") {
                        generatedUnitLabel =
                            "$_inputYear $_inputMonth $_inputWeek";
                      } else if (_selectedExamType == "단원평가") {
                        generatedUnitLabel =
                            "${_formatUnitRangeLabel(_inputBigUnits, '대단원')} (${_formatUnitRangeLabel(_inputMidUnits, '중단원')})";
                      } else {
                        generatedUnitLabel = _inputSemesterGroup;
                      }

                      _showFeedbackRegistrationDialog(
                        type: _selectedExamType!,
                        subject: _subjectController.text,
                        unit: generatedUnitLabel,
                        score: parsedScore,
                        grade: _inputGrade,
                        semester: _inputSemester,
                      );
                    },
                    child: Text(
                      _t('saveBtn'),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _getFilteredRecords(_selectedExamType!).length,
                  itemBuilder: (ctx, idx) {
                    final rec = _getFilteredRecords(_selectedExamType!)[idx];
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.only(
                        left: 10,
                        right: 4,
                        top: 4,
                        bottom: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DkeLang.current == 'KO'
                                ? "${rec.subject}[${rec.unit}]: ${rec.score.toInt()}점"
                                : "${rec.subject}[${rec.unit}]: ${rec.score.toInt()}",
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            maxLines: 1,
                            style: GoogleFonts.notoSansKr(
                              color: _ThemeColors.brandGolden,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _allRecords.removeWhere(
                                  (element) => element.id == rec.id,
                                );
                                if (_lastSavedRecordForDisplay?.id == rec.id) {
                                  _lastSavedRecordForDisplay =
                                      _allRecords.isNotEmpty
                                      ? _allRecords.last
                                      : null;
                                }
                              });
                              _persistExamRecords(); // 🆕 [데이터 연결] 삭제된 성적 기록도 즉시 영구 저장
                            },
                            child: const Icon(
                              Icons.close,
                              color: Colors.white60,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ], // 🆕 if (_isScoreSectionExpanded) 블록 닫기
        ],
      ),
    );
  }

  // 🆕 [요청] 대단원/중단원 공용 다중선택 행. items 중 tap한 항목을 selectedSet에서 토글함.
  // (최소 1개는 항상 선택된 상태를 유지해서 완전히 빈 선택이 되지 않게 함)
  Widget _buildUnitMultiSelectRow(
    List<String> items,
    Set<String> selectedSet,
    VoidCallback Function(String) onToggleBuilder,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: items.map((item) {
          final bool isSelected = selectedSet.contains(item);
          return _buildSubMiniBtn(item, isSelected, onToggleBuilder(item));
        }).toList(),
      ),
    );
  }

  // 🆕 선택된 단원 여러 개를 "대단원 1~대단원 3"(연속) 또는 "대단원 1, 대단원 3"(비연속) 형태로 조합.
  // unitWord로 "대단원"/"중단원"을 구분해서 대단원·중단원 모두에 재사용.
  String _formatUnitRangeLabel(Set<String> selected, String unitWord) {
    if (selected.isEmpty) return "";
    final List<int> nums = selected.map((s) {
      final match = RegExp(r'(\d+)').firstMatch(s);
      return match != null ? int.parse(match.group(1)!) : 0;
    }).toList()..sort();

    if (nums.length == 1) return "$unitWord ${nums.first}";

    bool isContiguous = true;
    for (int i = 1; i < nums.length; i++) {
      if (nums[i] != nums[i - 1] + 1) {
        isContiguous = false;
        break;
      }
    }

    if (isContiguous) return "$unitWord ${nums.first}~$unitWord ${nums.last}";
    return nums.map((n) => "$unitWord $n").join(", ");
  }

  // 🆕 [요청 2026-09-04] 월 선택 등 가로 스크롤 목록에 controller를 선택적으로 지정할 수 있게 변경.
  // (현재 월로 자동 스크롤하는 기능을 위해 필요 - controller가 없으면 기존과 동일하게 동작)
  Widget _buildSubScrollRow(
    List<String> items,
    String selectedValue,
    ValueChanged<String?> onSelected, {
    ScrollController? controller,
  }) {
    return SingleChildScrollView(
      controller: controller,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: items
            .map(
              (item) => _buildSubMiniBtn(
                item,
                selectedValue == item,
                () => onSelected(item),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSubFilterLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
      child: Text(
        label,
        overflow: TextOverflow.fade,
        softWrap: false,
        maxLines: 1,
        style: GoogleFonts.notoSansKr(
          color: Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSubMiniBtn(String text, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? _ThemeColors.brandGolden : Colors.black38,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _ThemeColors.brandGolden.withOpacity(
                isSelected ? 0.7 : 0.2,
              ),
            ),
          ),
          child: Text(
            text,
            overflow: TextOverflow.fade,
            softWrap: false,
            maxLines: 1,
            style: GoogleFonts.notoSansKr(
              color: isSelected ? Colors.black : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // 🆕 [⑧번] 시그니처 변경: String contentText -> Future<String> Function() contentBuilder
  // 버튼을 누르는 시점에 실시간으로 실제 데이터 기반 리포트를 생성하도록 변경.
  Widget _buildTopButton(
    String title,
    int flex,
    Future<String> Function() contentBuilder, {
    bool isTotalReport = false,
  }) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () async {
          final String content = await contentBuilder();
          if (!mounted) return;
          _showReportPopup(
            context,
            title,
            content,
            isTotalReport: isTotalReport,
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _ThemeColors.premiumCardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _ThemeColors.brandGolden.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  maxLines: 1,
                  style: GoogleFonts.notoSansKr(
                    color: _ThemeColors.brandGolden,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.play_arrow_rounded,
                color: Color(0xFFE5C158),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 [요청] Y축 시간 라벨 바로 옆에 흰색 점을 찍어서 눈금 위치를 명확히 표시
  Widget _buildYAxisDotLabel(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 9),
        ),
        const SizedBox(width: 4),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  // 🆕 [신규] 일일 전체 학습시간 - 모든 과목 합산, 날짜별 가로스크롤 막대그래프.
  // 기록이 있는 날짜만 표시(빈 날짜는 건너뜀), 오늘이 항상 맨 오른쪽에 오도록 자동 스크롤됨.
  Widget _buildDailyTotalStudyTimeGraph() {
    if (_dailyTotalHistory.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('dailyTotalStudyTime'),
            overflow: TextOverflow.fade,
            softWrap: false,
            maxLines: 1,
            style: GoogleFonts.notoSansKr(
              color: _ThemeColors.brandGolden,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 100,
            width: double.infinity,
            alignment: Alignment.center,
            child: Text(
              _t('dataCollectingMsg'),
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ],
      );
    }

    final double maxMinutes = _dailyTotalHistory
        .map((d) => (d["totalMinutes"] as int).toDouble())
        .reduce((a, b) => a > b ? a : b);
    const double barAreaHeight = 182.0; // 🆕 [요청] 세로(Y축)만 40% 확대 (130 * 1.4)

    // 🆕 [요청] Y축 슬라이딩 윈도우: 기본은 0~3시간 4단계 라벨.
    // 3시간을 넘으면(예: 6시간30분) 축 자체는 그대로 두고 "옆의 시간 숫자"만 위로 밀려서
    // 항상 4단계(예: 7,6,5,4시간)만 보이고, 그 아래 구간은 잘려서 안 보이게 함.
    double windowTopHours = (maxMinutes / 60.0).ceil().toDouble();
    if (windowTopHours < 3) windowTopHours = 3;
    final double windowBottomHours = windowTopHours - 3;
    final double windowTopMinutes = windowTopHours * 60;
    final double windowBottomMinutes = windowBottomHours * 60;
    final double windowRangeMinutes =
        windowTopMinutes - windowBottomMinutes; // 항상 180분(3시간) 폭 유지

    final List<String> yAxisLabels = [
      "${windowTopHours.toInt()}h",
      "${(windowTopHours - 1).toInt()}h",
      "${(windowTopHours - 2).toInt()}h",
      "${windowBottomHours.toInt()}h",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('dailyTotalStudyTime'),
          overflow: TextOverflow.fade,
          softWrap: false,
          maxLines: 1,
          style: GoogleFonts.notoSansKr(
            color: _ThemeColors.brandGolden,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: _ThemeColors.premiumCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _ThemeColors.brandGolden.withOpacity(0.2),
              width: 1.2,
            ),
          ),
          child: Stack(
            children: [
              SizedBox(
                height: barAreaHeight + 46,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 🆕 [Y축] 왼쪽 시간 눈금 라벨 컬럼 (라벨 바로 옆에 흰색 점 표시)
                    SizedBox(
                      width: 34,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const SizedBox(height: 16),
                          ...yAxisLabels
                              .take(3)
                              .map(
                                (label) => Expanded(
                                  child: Align(
                                    alignment: Alignment.topRight,
                                    child: _buildYAxisDotLabel(label),
                                  ),
                                ),
                              ),
                          _buildYAxisDotLabel(yAxisLabels.last),
                          const SizedBox(height: 20),
                          // 🆕 실제 막대 바닥(날짜 텍스트 위)과 맞춘 하단 간격
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 🆕 [X축] 세로 기준선 - 하단을 실제 막대 바닥(원점)과 정확히 맞춤
                    Container(
                      width: 1.5,
                      margin: const EdgeInsets.only(top: 16, bottom: 20),
                      color: _ThemeColors.brandGolden.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _dailyTotalScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _dailyTotalHistory.asMap().entries.map((
                            entry,
                          ) {
                            final int idx = entry.key;
                            final Map<String, dynamic> d = entry.value;
                            final DateTime date = d["date"] as DateTime;
                            final int minutes = d["totalMinutes"] as int;
                            final DateTime today = DateTime.now();
                            final bool isToday =
                                date.year == today.year &&
                                date.month == today.month &&
                                date.day == today.day;
                            // 🆕 [요청] 막대 색상을 무지개색 순서로 반복 (기존 _todayColors 팔레트 재사용)
                            final Color barColor =
                                _todayColors[idx % _todayColors.length];

                            // 🆕 윈도우 하단(windowBottomMinutes) 밑으로 내려가는 값은 0으로 고정해서 "가위질"된 것처럼 안 보이게 함
                            double barFraction =
                                (minutes - windowBottomMinutes) /
                                windowRangeMinutes;
                            if (barFraction < 0) barFraction = 0;
                            if (barFraction > 1) barFraction = 1;
                            double barHeight = barFraction * barAreaHeight;
                            if (barFraction > 0 && barHeight < 3)
                              barHeight = 3; // 윈도우 안에 실제 값이 있을 때만 최소 시인성 보장
                            if (barHeight > barAreaHeight)
                              barHeight = barAreaHeight;

                            return Container(
                              width: 48,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              // 🆕 [요청] 날짜 칸 간격 50% 축소(4→2)
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${(minutes / 60).toStringAsFixed(1)}h",
                                    style: GoogleFonts.notoSansKr(
                                      color: Colors.white70,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: barHeight,
                                    width: 22,
                                    decoration: BoxDecoration(
                                      color: barColor,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(3),
                                      ),
                                      border: isToday
                                          ? Border.all(
                                              color: _ThemeColors.brandGolden,
                                              width: 1.5,
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "${date.month}/${date.day}",
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    maxLines: 1,
                                    style: GoogleFonts.notoSansKr(
                                      color: isToday
                                          ? _ThemeColors.brandGolden
                                          : Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 🆕 [X축] 수평 기준선 - Y축(세로선)과 정확히 원점(0)에서 만나도록 left/bottom 보정
              Positioned(
                left: 34 + 6, // Y축 라벨 컬럼(34) + 간격(6) = 세로선이 시작하는 x좌표와 일치
                right: 0,
                bottom: 20, // 실제 막대 바닥(날짜 텍스트 위)과 정확히 일치
                child: Container(
                  height: 1.5,
                  color: _ThemeColors.brandGolden.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLuxuryGlowingStar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _ThemeColors.brandGolden.withOpacity(0.7),
                blurRadius: 7,
                spreadRadius: 2.0,
              ),
            ],
          ),
        ),
        const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 17),
      ],
    );
  }

  // 🆕 [4번] 아래 상수들이 라벨 컬럼과 그래프 플롯 영역 양쪽에서 반드시 동일해야
  // 축(눈금)과 막대그래프가 어떤 화면 크기에서도 정확히 일치합니다. (수정 절대 금지 영역)
  static const double _kChartTopPad = 25.0;
  static const double _kChartBottomPad = 44.0;

  // 🆕 [요청 2026-09-04] "오늘 학습한 과목" 카드가 날짜별로 조회 가능하도록 확장.
  // 기본값은 오늘이며, 좌우 화살표로 전날/전전날 등을 조회할 수 있음(미래 날짜는 이동 불가).
  DateTime _selectedSessionDate = DateTime.now();
  List<Map<String, dynamic>> _selectedDaySessions = [];

  bool get _isSelectedDateToday {
    final DateTime today = DateTime.now();
    return _selectedSessionDate.year == today.year &&
        _selectedSessionDate.month == today.month &&
        _selectedSessionDate.day == today.day;
  }

  // 🆕 [요청 2026-09-04] 오늘 날짜보다 이후로는 이동할 수 없도록 다음(▶) 버튼 비활성화 여부 판단.
  bool get _isNextDayDisabled => _isSelectedDateToday;

  String get _sessionCardTitle {
    if (_isSelectedDateToday) return _t('todaySessionsTitle');
    return DkeLang.current == 'KO'
        ? "${_selectedSessionDate.month}월 ${_selectedSessionDate.day}일 ${_t('sessionsGenericTitle')}"
        : "${_selectedSessionDate.month}/${_selectedSessionDate.day} ${_t('sessionsGenericTitle')}";
  }

  String get _sessionEmptyMessage =>
      _isSelectedDateToday ? _t('noSessionsToday') : _t('noSessionsOnDate');

  // 🆕 [위험한 오류 수정 2026-09-05] 세션 하나가 "강의"인지 "평가"인지, 평가라면 점수까지
  // 한눈에 보이도록 표시하는 라벨. 개념강의를 들었을 때 시험을 본 것처럼 보이는 혼동을 방지함.
  String _sessionTypeLabel(Map<String, dynamic> s) {
    final String? recordType = s['recordType'] as String?;
    final num? score = s['score'] as num?;
    if (recordType == '평가') {
      return score != null
          ? "[${_t('evaluationLabel')} $score${_t('scoreLabel')}]"
          : "[${_t('evaluationLabel')}]";
    } else if (recordType == '강의') {
      return "[${_t('lectureLabel')}]";
    }
    return '';
  }

  void _goToPreviousSessionDay() {
    final DateTime newDate = _selectedSessionDate.subtract(
      const Duration(days: 1),
    );
    setState(() => _selectedSessionDate = newDate);
    _loadSessionsForDate(newDate);
  }

  void _goToNextSessionDay() {
    if (_isNextDayDisabled) return; // 오늘이 이미 선택되어 있으면 미래로는 이동 불가
    final DateTime newDate = _selectedSessionDate.add(const Duration(days: 1));
    setState(() => _selectedSessionDate = newDate);
    _loadSessionsForDate(newDate);
  }

  // 🆕 [요청 2026-09-04] 선택된 날짜의 학습 세션을 시간순으로 불러오는 함수.
  // dke_history_{과목명} 키를 전부 훑어서 해당 날짜 하루치(00:00~다음날 00:00 직전)만 추출합니다.
  Future<void> _loadSessionsForDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Set<String> allKeys = prefs.getKeys();
      final Iterable<String> historyKeys = allKeys.where(
        (k) => k.startsWith('dke_history_'),
      );
      final DateTime dayStart = DateTime(date.year, date.month, date.day);
      final DateTime dayEnd = dayStart.add(const Duration(days: 1));

      final List<Map<String, dynamic>> sessions = [];

      for (final key in historyKeys) {
        final String subjectName = key.substring('dke_history_'.length);
        final List<String>? entries = prefs.getStringList(key);
        if (entries == null) continue;
        for (final raw in entries) {
          try {
            final Map<String, dynamic> item = jsonDecode(raw);
            final DateTime ts =
                DateTime.tryParse(
                  item['timestamp']?.toString() ?? '',
                )?.toLocal() ??
                DateTime.now();
            if (ts.isBefore(dayStart) || !ts.isBefore(dayEnd)) continue;
            final int durationSeconds =
                (item['durationSeconds'] as num?)?.toInt() ?? 0;
            final int minutes = (durationSeconds / 60).round();
            // 🆕 [위험한 오류 수정 2026-09-05] 강의(개념강의/단원정리)인지 평가인지 구분해서 표시하기 위해
            // timer_screen.dart가 저장한 recordType/lectureSubType/score 필드도 함께 읽어옴.
            sessions.add({
              "subject": subjectName,
              "minutes": minutes,
              "timestamp": ts,
              "recordType": item['recordType'] as String?,
              // '강의' 또는 '평가'
              "lectureSubType": item['lectureSubType'] as String?,
              // '개념강의' / '단원정리 및 문제해설'
              "score": item['score'],
              // 평가일 때만 int, 강의면 null
            });
          } catch (_) {
            // 손상된 기록 하나는 건너뛰고 나머지는 계속 집계
          }
        }
      }

      sessions.sort(
        (a, b) =>
            (a["timestamp"] as DateTime).compareTo(b["timestamp"] as DateTime),
      );

      if (!mounted) return;
      setState(() {
        _selectedDaySessions = sessions;
      });
    } catch (e) {
      debugPrint("[MemberAchievement] 학습 세션 불러오기 실패: $e");
    }
  }

  // 🆕 [요청 2026-09-04] "오늘 학습한 과목" 카드 위젯 - 좌우 화살표로 날짜 이동 가능.
  // 세션이 없으면 안내 문구, 있으면 교시별 목록을 보여줍니다.
  Widget _buildTodaySessionsCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ThemeColors.premiumCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _ThemeColors.brandGolden.withOpacity(0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _goToPreviousSessionDay,
                child: const Icon(
                  Icons.arrow_left_rounded,
                  color: _ThemeColors.brandGolden,
                  size: 26,
                ),
              ),
              Expanded(
                child: Text(
                  _sessionCardTitle,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  maxLines: 1,
                  style: GoogleFonts.notoSansKr(
                    color: _ThemeColors.brandGolden,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _isNextDayDisabled ? null : _goToNextSessionDay,
                child: Icon(
                  Icons.arrow_right_rounded,
                  color: _isNextDayDisabled
                      ? Colors.white12
                      : _ThemeColors.brandGolden,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_selectedDaySessions.isEmpty)
            Text(
              _sessionEmptyMessage,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            )
          else
            ..._selectedDaySessions.asMap().entries.map((entry) {
              final int idx = entry.key;
              final Map<String, dynamic> s = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          "${idx + 1}${_t('sessionOrdinal')} · ${_subjectName(s["subject"] as String)} ${_sessionTypeLabel(s)}",
                          maxLines: 1,
                          style: GoogleFonts.notoSansKr(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${s["minutes"]}${_t('minutesUnitSuffix')}",
                      style: GoogleFonts.notoSansKr(
                        color: _ThemeColors.brandGolden,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ============================================================================
  // 🆕 [리포트 저장·공유 2026-10-01] 원장님 원칙
  // - 종합 리포트: 그날 총 학습시간 구간별 문장 은행에서 꺼내 씀(새로 지어내지 않음)
  //   → 서버(links/{내 코드}/reports)에 저장 → 부모님 화면에도 똑같은 글, 다시 열어도 같은 글
  // - 같은 학생에게는 전에 받은 문장 조합을 다시 쓰지 않음
  // - "목표 달성률 60%대" 같은 문장은 목표를 정하지 않은 학생에게 맞지 않아 더 이상 쓰지 않음
  // ============================================================================
  static const Map<String, String> _kAiNote = {
    'KO': '※ 이 분석은 GKE 학습 전문 AI가 그날의 학습 기록(강의·평가·학습 시간)을 참고하여 작성했습니다. 기록이 꾸준히 쌓일수록 분석은 더 정밀해집니다.',
    'EN': "※ This analysis was written by GKE's learning-specialist AI based on that day's study records (lectures, evaluations, study time). The more consistently records build up, the more precise it becomes.",
    'JA': '※ この分析は、GKE学習専門AIがその日の学習記録（講義・評価・学習時間）をもとに作成しました。記録が積み重なるほど、分析はより精密になります。',
    'ZH': '※ 本分析由GKE学习专业AI参考当天的学习记录（课程·评估·学习时间）撰写。记录积累得越多，分析就越精准。',
    'FR': "※ Cette analyse a été rédigée par l'IA spécialisée de GKE à partir des données d'étude du jour (cours, évaluations, temps d'étude). Plus les données s'accumulent, plus elle devient précise.",
    'DE': '※ Diese Analyse wurde von der Lern-KI von GKE anhand der Lernaufzeichnungen des Tages (Unterricht, Bewertungen, Lernzeit) erstellt. Je mehr Aufzeichnungen, desto genauer wird sie.',
    'RU': '※ Этот анализ составлен учебным ИИ GKE на основе записей за день (занятия, оценки, время учёбы). Чем больше записей, тем точнее анализ.',
    'AR': '※ كُتب هذا التحليل بواسطة ذكاء GKE الاصطناعي المتخصص في التعلم استنادًا إلى سجلات ذلك اليوم (الدروس، التقييمات، وقت الدراسة). كلما تراكمت السجلات أصبح التحليل أدق.',
    'HI': '※ यह विश्लेषण GKE के लर्निंग-विशेषज्ञ AI ने उस दिन के अध्ययन रिकॉर्ड (पाठ, मूल्यांकन, अध्ययन समय) के आधार पर लिखा है। रिकॉर्ड जितने बढ़ेंगे, विश्लेषण उतना सटीक होगा।',
    'VI': '※ Phân tích này do AI chuyên về học tập của GKE viết dựa trên hồ sơ học tập trong ngày (bài giảng, đánh giá, thời gian học). Hồ sơ càng nhiều, phân tích càng chính xác.',
    'ES': '※ Este análisis fue redactado por la IA de aprendizaje de GKE a partir de los registros del día (clases, evaluaciones, tiempo de estudio). Cuantos más registros, más preciso será.',
    'TH': '※ บทวิเคราะห์นี้เขียนโดย AI ผู้เชี่ยวชาญด้านการเรียนของ GKE จากบันทึกการเรียนของวันนั้น (บทเรียน การประเมิน เวลาเรียน) ยิ่งบันทึกสะสมมาก การวิเคราะห์ยิ่งแม่นยำ',
  };
  static const Map<String, String> _kNoEvalDirection = {
    'KO': '이날은 평가 기록이 없어 학습 시간과 과목을 중심으로 기록했습니다. 평가를 기록하면 과목별 정밀 진단이 함께 제공됩니다.',
    'EN': 'There were no evaluations recorded that day, so this record focuses on study time and subjects. Log an evaluation to receive a detailed subject diagnosis.',
    'JA': 'この日は評価記録がないため、学習時間と科目を中心に記録しました。評価を記録すると、科目別の精密診断も提供されます。',
    'ZH': '当天没有评估记录，因此以学习时间和科目为主进行记录。记录评估后，将同时提供各科目的精准诊断。',
    'FR': "Aucune évaluation n'a été enregistrée ce jour-là ; ce relevé porte donc sur le temps d'étude et les matières. Enregistrez une évaluation pour obtenir un diagnostic détaillé.",
    'DE': 'An diesem Tag wurde keine Bewertung erfasst, daher konzentriert sich der Eintrag auf Lernzeit und Fächer. Erfasse eine Bewertung für eine genaue Fachdiagnose.',
    'RU': 'В этот день не было записанных оценок, поэтому запись основана на времени учёбы и предметах. Запишите оценку, чтобы получить подробную диагностику.',
    'AR': 'لم تُسجَّل تقييمات في ذلك اليوم، لذا يركز هذا السجل على وقت الدراسة والمواد. سجّل تقييمًا لتحصل على تشخيص مفصل للمادة.',
    'HI': 'उस दिन कोई मूल्यांकन दर्ज नहीं था, इसलिए यह रिकॉर्ड अध्ययन समय और विषयों पर केंद्रित है। मूल्यांकन दर्ज करें तो विषयवार विस्तृत निदान मिलेगा।',
    'VI': 'Ngày hôm đó không có đánh giá nào được ghi lại, nên bản ghi tập trung vào thời gian học và môn học. Hãy ghi đánh giá để nhận chẩn đoán chi tiết theo môn.',
    'ES': 'Ese día no hubo evaluaciones registradas, así que este registro se centra en el tiempo de estudio y las materias. Registra una evaluación para recibir un diagnóstico detallado.',
    'TH': 'วันนั้นไม่มีการบันทึกการประเมิน จึงบันทึกโดยเน้นเวลาเรียนและวิชา หากบันทึกการประเมินจะได้รับการวินิจฉัยรายวิชาอย่างละเอียด',
  };

  // 기본모드(한국어·영어)는 한글 + 영어 두 줄, 외국어는 그 언어 한 줄
  String _biMap(Map<String, String> m) {
    if (DkeLang.isForeignSelected) return m[DkeLang.current] ?? m['EN'] ?? '';
    return '${m['KO']}\n${m['EN']}';
  }

  String get _reportPersonKey => 'student_${FirebaseAuth.instance.currentUser?.uid ?? 'guest'}';

  Future<String> _archivedDailySummary(int subjectCount, int totalMin) {
    if (_myLinkCode == null) {
      // 부모님과 연결 전이면 기기 안의 문장 은행만 사용
      return DiagnosisService.getDailySummary(personKey: _reportPersonKey, subjectCount: subjectCount, totalMinutes: totalMin);
    }
    return ReportArchiveService.dailySummary(
      code: _myLinkCode!,
      personKey: _reportPersonKey,
      day: _selectedSessionDate,
      subjectCount: subjectCount,
      totalMinutes: totalMin,
    );
  }

  Future<String> _archivedExamAnalysis({required String type, required String subject, required double score, required DateTime date}) {
    if (_myLinkCode == null) {
      return DiagnosisService.getAnalysis(personKey: _reportPersonKey, type: type, subject: subject, score: score);
    }
    return ReportArchiveService.examAnalysis(
      code: _myLinkCode!,
      personKey: _reportPersonKey,
      rawExam: {'date': date.toIso8601String()},
      type: type,
      subject: subject,
      score: score,
    );
  }

  // 🆕 [2026-10-01] "종합 리포트" — 고른 날짜의 실제 학습 기록 + 저장·공유되는 총평
  Future<String> _buildTotalReportContent() async {
    if (_selectedDaySessions.isEmpty) {
      return _sessionEmptyMessage;
    }
    final bool ko = DkeLang.current == 'KO';
    final int totalMin = _selectedDaySessions.fold<int>(0, (sum, s) => sum + (s["minutes"] as int));
    final int evalCount = _selectedDaySessions.where((s) => s['recordType'] == '평가').length;
    final int lectureCount = _selectedDaySessions.length - evalCount;
    final int subjectCount = _selectedDaySessions.map((s) => s["subject"]).toSet().length;
    final String dayWord = _isSelectedDateToday
        ? (ko ? '오늘' : 'Today')
        : (ko ? '${_selectedSessionDate.month}월 ${_selectedSessionDate.day}일' : '${_selectedSessionDate.month}/${_selectedSessionDate.day}');

    final buffer = StringBuffer();
    buffer.write(ko ? '[종합 리포트]\n\n' : '[Total Report]\n\n');
    buffer.write(ko
        ? '$dayWord 총 학습시간: $totalMin분\n강의 $lectureCount건 · 평가 $evalCount건\n\n'
        : '$dayWord total study time: $totalMin min\nLectures $lectureCount · Evaluations $evalCount\n\n');
    buffer.write(await _archivedDailySummary(subjectCount, totalMin));
    buffer.write('\n\n${_biMap(_kAiNote)}');
    return buffer.toString();
  }

  // 🆕 [2026-10-01] "상세분석기록" — 교시별 기록 + (평가가 있으면) 가장 낮은 점수 평가의 저장·공유 진단서
  Future<String> _buildDetailedReportContent() async {
    if (_selectedDaySessions.isEmpty) {
      return _sessionEmptyMessage;
    }
    final bool ko = DkeLang.current == 'KO';
    final buffer = StringBuffer();
    buffer.write(ko ? '[상세분석기록]\n\n' : '[Detailed Analytics]\n\n');

    for (int i = 0; i < _selectedDaySessions.length; i++) {
      final s = _selectedDaySessions[i];
      final String period = ko ? '제${i + 1}${_t('sessionOrdinal')}' : '${_t('sessionOrdinal')} ${i + 1}';
      buffer.write("■ $period · ${_subjectName(s["subject"] as String)} ${_sessionTypeLabel(s)}\n");
      buffer.write("  ${s["minutes"]}${_t('minutesUnitSuffix')}\n\n");
    }

    buffer.write(_isSelectedDateToday
        ? (ko ? '[오늘의 방향 제안]\n' : "[Today's Direction]\n")
        : (ko ? '[그날의 방향 제안]\n' : "[That Day's Direction]\n"));

    final List<Map<String, dynamic>> evals = _selectedDaySessions
        .where((s) => s['recordType'] == '평가' && s['score'] != null)
        .toList();
    if (evals.isEmpty) {
      buffer.write(_biMap(_kNoEvalDirection));
    } else {
      evals.sort((a, b) => (a['score'] as num).compareTo(b['score'] as num));
      final Map<String, dynamic> lowest = evals.first;
      buffer.write(await _archivedExamAnalysis(
        type: '평가',
        subject: lowest["subject"] as String,
        score: (lowest['score'] as num).toDouble(),
        date: lowest["timestamp"] as DateTime,
      ));
    }
    buffer.write('\n\n${_biMap(_kAiNote)}');
    return buffer.toString();
  }

  // 🆕 [데이터 연결] 일일 목표 학습시간(분) — "목표 달성도"와 "어제 대비 오늘" 계산의 기준값.
  // 지금은 200분(약 3시간)으로 설정. 나중에 마이페이지 등에서 유저가 직접 설정하게 바꿀 수도 있음.
  // (참고: 고정 200분 목표 상수는 유동 목표(_dynamicDailyGoalMinutes)로 대체되어 제거함)

  Widget _buildFixedEvaluationChart(String type) {
    List<_ExamRecord> evalRecords = _getFilteredRecords(type);

    if (evalRecords.isEmpty) {
      return Container(
        height: 140,
        width: double.infinity,
        alignment: Alignment.center,
        child: Text(
          _t('onlyRecordedSubjectsChart'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      );
    }

    List<String> scoreLabels = ["100점", "90점", "80점", "70점", "60점"];
    const double hMax = 210.0;
    const double scoreMin = 60.0;
    const double scoreMax = 100.0;
    const double scoreRange = scoreMax - scoreMin; // = 40.0

    return SizedBox(
      height: 280,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: _kChartTopPad),
                ...scoreLabels
                    .take(4)
                    .map(
                      (label) => Expanded(
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Text(
                            label,
                            style: GoogleFonts.notoSansKr(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                Align(
                  alignment: Alignment.topRight,
                  child: Text(
                    scoreLabels.last,
                    style: GoogleFonts.notoSansKr(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: _kChartBottomPad),
              ],
            ),
          ),
          const SizedBox(width: 4),

          Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: 2.2,
                margin: const EdgeInsets.only(
                  top: _kChartTopPad,
                  bottom: _kChartBottomPad,
                ),
                color: _ThemeColors.brandGolden.withOpacity(0.6),
              ),
              Positioned.fill(
                top: _kChartTopPad,
                bottom: _kChartBottomPad,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    5,
                    (index) => Container(
                      width: 6,
                      height: 1.5,
                      color: _ThemeColors.brandGolden,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Expanded(
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Positioned.fill(
                  top: 10,
                  bottom: 0,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(width: 6),
                        ...List.generate(evalRecords.length, (idx) {
                          final rec = evalRecords[idx];
                          final Color barColor =
                              _evalColors[idx % _evalColors.length];

                          double scoreVal = rec.score.clamp(scoreMin, scoreMax);
                          double drawScoreHeight =
                              ((scoreVal - scoreMin) / scoreRange) * hMax;
                          if (drawScoreHeight < 2) drawScoreHeight = 2;
                          if (drawScoreHeight > hMax) drawScoreHeight = hMax;

                          return Container(
                            width: 32,
                            margin: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: hMax + 16,
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Positioned(
                                        bottom: 0,
                                        child: Container(
                                          height: drawScoreHeight,
                                          width: 20,
                                          decoration: BoxDecoration(
                                            color: barColor,
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(2.0),
                                                ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: drawScoreHeight + 2,
                                        child: Text(
                                          "${rec.score.toInt()}",
                                          style: TextStyle(
                                            color: barColor,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 36,
                                  child: Text(
                                    rec.subject,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    style: GoogleFonts.notoSansKr(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: _kChartBottomPad,
                  child: Container(
                    width: double.infinity,
                    height: 2.2,
                    color: _ThemeColors.brandGolden.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedChartDashboard(int tabIndex) {
    List<Map<String, dynamic>> rawData = _masterSubjectData;

    List<Map<String, dynamic>> targetSubjects = [];
    for (var item in rawData) {
      bool isValid = false;
      if (tabIndex == 0 && item["hasStudiedToday"] == true) isValid = true;
      if (tabIndex == 1 && item["hasStudiedWeekly"] == true) isValid = true;
      if (tabIndex == 2 && item["hasStudiedMonthly"] == true) isValid = true;
      if (tabIndex == 3 && item["hasStudiedYearly"] == true) isValid = true;

      if (isValid) {
        // 🆕 [위험한 오류 수정 2026-09-06] "하루 평균 × 가정 일수"로 추정하던 방식을 폐기하고,
        // 그 기간(이번 주/이번 달/올해) 안에 실제로 쌓인 분(分)을 그대로 사용함.
        final int realMinutesForTab = tabIndex == 0
            ? (item["todayRealMinutes"] as int)
            : tabIndex == 1
            ? (item["weekRealMinutes"] as int)
            : tabIndex == 2
            ? (item["monthRealMinutes"] as int)
            : (item["yearRealMinutes"] as int);
        double totalMins = realMinutesForTab.toDouble();
        if (totalMins > 0) {
          targetSubjects.add({...item, "calculatedMinutes": totalMins});
        }
      }
    }

    targetSubjects.sort(
      (a, b) => (b["calculatedMinutes"] as double).compareTo(
        a["calculatedMinutes"] as double,
      ),
    );

    double maxMinutesFound = 0.0;
    for (var item in targetSubjects) {
      if ((item["calculatedMinutes"] as double) > maxMinutesFound) {
        maxMinutesFound = item["calculatedMinutes"] as double;
      }
    }

    // 🆕 [위험한 오류 수정 2026-09-06] 예전의 "천장값 보정"(minCeiling)은 과장된 추정치를
    // 전제로 설계된 값이라(예: 연간 600시간) 실제 합산 분 기준으로 바뀐 지금은 오히려 해롭습니다
    // (실제 데이터가 적을 때 Y축이 불필요하게 커져 막대가 거의 안 보이게 됨). 완전히 제거하고,
    // 아래 슬라이딩 윈도우가 항상 기본 150분 범위에서 시작해 필요한 만큼만 자연스럽게 커지도록 함.

    // 🆕 [요청] Y축을 0m/50m/100m/150m 고정 눈금으로 통일하고, 150분을 넘어서면
    // (기존 "일일 전체 학습시간" 그래프의 슬라이딩 윈도우와 동일한 방식으로) Y축 숫자만
    // 위로 밀려서 항상 4단계(예: 200/150/100/50)만 보이고 그 아래 구간은 잘려서 안 보이게 함.
    // 일/주/월/연 전부 동일하게 적용.
    double windowTopMinutes = 150.0;
    if (maxMinutesFound > windowTopMinutes) {
      windowTopMinutes = (maxMinutesFound / 50.0).ceil() * 50.0;
    }
    final double windowBottomMinutes = windowTopMinutes - 150.0;
    final double yAxisMaxBoundary = windowTopMinutes; // 막대 높이 계산 기준(=창의 맨 위)
    final double yAxisWindowRange =
        windowTopMinutes - windowBottomMinutes; // 항상 150분 폭 유지

    List<String> dynamicYAxisLabels = [
      "${windowTopMinutes.round()}m",
      "${(windowTopMinutes - 50).round()}m",
      "${(windowTopMinutes - 100).round()}m",
      "${windowBottomMinutes.round()}m",
    ];

    List<Color> colorPalette = (tabIndex == 1) ? _weeklyColors : _todayColors;

    int totalMinutes = targetSubjects.fold<int>(0, (sum, item) {
      return sum + (item["calculatedMinutes"] as double).round();
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 240,
          child: Stack(
            children: [
              Positioned(
                left: 48,
                top: 0,
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _t('average'),
                      style: GoogleFonts.notoSansKr(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                left: 42,
                right: 0,
                top: _kChartTopPad,
                bottom: _kChartBottomPad,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    4,
                    (i) => Container(
                      width: double.infinity,
                      height: 0.8,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 42,
                top: _kChartTopPad,
                bottom: _kChartBottomPad,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    7,
                    (i) => Container(
                      width: i % 2 != 0 ? 4.0 : 0.0,
                      height: 1.5,
                      color: _ThemeColors.brandGolden.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 34,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // 🆕 [4번] 라벨 컬럼 상/하단 여백을 그래프 플롯 영역과 완전히 동일한 상수로 고정
                        // (기존 22 / 48 값이 플롯 영역의 25 / 44 와 달라 화면별로 축과 막대가 미세하게 어긋나던 원인)
                        const SizedBox(height: _kChartTopPad),
                        ...dynamicYAxisLabels
                            .take(3)
                            .map(
                              (label) => Expanded(
                                child: Text(
                                  label,
                                  style: GoogleFonts.notoSansKr(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                  ),
                                ),
                              ),
                            ),
                        Text(
                          dynamicYAxisLabels.last,
                          style: GoogleFonts.notoSansKr(
                            color: Colors.white,
                            fontSize: 9.5,
                          ),
                        ),
                        const SizedBox(height: _kChartBottomPad),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 2.2,
                    margin: const EdgeInsets.only(
                      top: _kChartTopPad,
                      bottom: _kChartBottomPad,
                    ),
                    color: _ThemeColors.brandGolden.withOpacity(0.6),
                  ),

                  Expanded(
                    child: Stack(
                      alignment: Alignment.bottomLeft,
                      children: [
                        Positioned.fill(
                          top: 7,
                          bottom: 0,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(targetSubjects.length, (
                                index,
                              ) {
                                final data = targetSubjects[index];
                                const double hMaxDashboard = 120.0;
                                final Color pCol =
                                    colorPalette[index % colorPalette.length];

                                double currentMins =
                                    data["calculatedMinutes"] as double;
                                // 🆕 [요청] 슬라이딩 윈도우 반영: windowBottomMinutes 밑으로 내려가는 값은
                                // 0으로 고정해서 "잘라낸" 것처럼 보이게 함 (일일 전체 학습시간 그래프와 동일 패턴)
                                double drawScoreHeight =
                                    ((currentMins - windowBottomMinutes) /
                                        yAxisWindowRange) *
                                    hMaxDashboard;
                                double drawAvgHeight =
                                    (((data["averageScore"] as double) *
                                                (currentMins * 0.8) -
                                            windowBottomMinutes) /
                                        yAxisWindowRange) *
                                    hMaxDashboard;

                                if (drawScoreHeight < 0) drawScoreHeight = 0;
                                if (drawAvgHeight < 0) drawAvgHeight = 0;
                                if (drawScoreHeight < 4 &&
                                    currentMins > windowBottomMinutes)
                                  drawScoreHeight = 4; // 윈도우 안에 있을 때만 최소 시인성 보장
                                if (drawAvgHeight < 2 &&
                                    currentMins > windowBottomMinutes)
                                  drawAvgHeight = 2;
                                if (drawScoreHeight > hMaxDashboard)
                                  drawScoreHeight = hMaxDashboard;
                                if (drawAvgHeight > hMaxDashboard)
                                  drawAvgHeight =
                                      hMaxDashboard; // 🆕 [버그 수정] 평균 막대도 상한 제한 - 주간/월간/연간에서 X축 아래로 삐져나오던 오버플로우 해결

                                return Container(
                                  width: 53,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 0.5,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: hMaxDashboard + 16,
                                        width: 53,
                                        child: Stack(
                                          alignment: Alignment.bottomCenter,
                                          children: [
                                            Positioned(
                                              left: 10,
                                              bottom: 0,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    "${(data["averageScore"] * 100).toInt()}%",
                                                    style: const TextStyle(
                                                      color: Colors.white54,
                                                      fontSize: 8.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Container(
                                                    height: drawAvgHeight,
                                                    width: 16,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade600,
                                                      borderRadius:
                                                          const BorderRadius.vertical(
                                                            top:
                                                                Radius.circular(
                                                                  2.5,
                                                                ),
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Positioned(
                                              left: 27,
                                              bottom: 0,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    "${(data["score"] * 100).toInt()}%",
                                                    style: TextStyle(
                                                      color: pCol,
                                                      fontSize: 9.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Container(
                                                    height: drawScoreHeight,
                                                    width: 16,
                                                    decoration: BoxDecoration(
                                                      color: pCol,
                                                      borderRadius:
                                                          const BorderRadius.vertical(
                                                            top:
                                                                Radius.circular(
                                                                  2.5,
                                                                ),
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 36,
                                        child: Text(
                                          data["subject"],
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.notoSansKr(
                                            color: Colors.white,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: _kChartBottomPad,
                          child: Container(
                            width: double.infinity,
                            height: 2.2,
                            color: _ThemeColors.brandGolden.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white10, height: 16),

        _buildDailyTotalStudyTimeGraph(),
        // 🆕 [배치 변경] 과목 학습시간 바로 아래, 종합 생활 균형 바로 위
        const SizedBox(height: 20),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('lifeBalance'),
              overflow: TextOverflow.fade,
              softWrap: false,
              maxLines: 1,
              style: GoogleFonts.gowunBatang(
                color: _ThemeColors.brandGolden,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Text(
              _t('lifeBalanceSub'),
              overflow: TextOverflow.fade,
              softWrap: false,
              maxLines: 1,
              style: GoogleFonts.notoSansKr(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              flex: 50,
              child: Center(
                child: SizedBox(
                  width: 170,
                  height: 170,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(170, 170),
                        painter: _GsuPiePainter(
                          targetSubjects: targetSubjects,
                          colors: colorPalette,
                        ),
                      ),
                      Container(
                        width: 82,
                        height: 82,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0D1527),
                          shape: BoxShape.circle,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Total',
                              style: GoogleFonts.gowunBatang(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              "$totalMinutes/m",
                              style: GoogleFonts.gowunBatang(
                                color: _ThemeColors.brandGolden,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(targetSubjects.length, (idx) {
                  final item = targetSubjects[idx];
                  final int calculatedMin =
                      (item["calculatedMinutes"] as double).round();
                  final int percent = totalMinutes > 0
                      ? ((calculatedMin / totalMinutes) * 100).round()
                      : 0;
                  final Color c = colorPalette[idx % colorPalette.length];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${item["subject"].toString().replaceAll('\n', ' ')}  $percent%",
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                                maxLines: 2,
                                // 🆕 [요청] 과목명이 길면 2줄까지 허용해서 오버플로우 방지
                                style: GoogleFonts.notoSansKr(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                item["isStarEligible"]
                                    ? "✨ +${calculatedMin} Stars"
                                    : "🚫 No Stars",
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                maxLines: 1,
                                style: GoogleFonts.notoSansKr(
                                  color: item["isStarEligible"]
                                      ? _ThemeColors.brandGolden.withOpacity(
                                          0.8,
                                        )
                                      : Colors.white38,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (targetSubjects.isEmpty)
          AnimatedBuilder(
            animation: _warningAnimation,
            builder: (c, child) => Transform.translate(
              offset: Offset(0, _warningAnimation.value),
              child: child,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _ThemeColors.brandGolden,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t('dbSyncTitle'),
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          maxLines: 1,
                          style: GoogleFonts.gowunBatang(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _t('dbSyncSub'),
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          maxLines: 1,
                          style: GoogleFonts.notoSansKr(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// 🆕 [7번] AI 등급 배정 자리(placeholder). 지금은 규칙 기반 텍스트 생성만 사용하고,
// 플레이스토어 출시 직전 실제 AI Pro / AI Light API 연결 시 이 값을 기준으로 분기 처리 예정.
enum AiTier { pro, light }

class _GsuPiePainter extends CustomPainter {
  final List<Map<String, dynamic>> targetSubjects;
  final List<Color> colors;

  _GsuPiePainter({required this.targetSubjects, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = targetSubjects.fold<double>(
      0.0,
      (s, i) => s + (i["calculatedMinutes"] as double),
    );
    if (total == 0) return;

    final Paint p = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    double start = -math.pi / 2;

    for (int i = 0; i < targetSubjects.length; i++) {
      final double calculatedMin =
          targetSubjects[i]["calculatedMinutes"] as double;
      final double sweep = (calculatedMin / total) * 2 * math.pi;
      p.color = colors[i % colors.length];
      canvas.drawArc(
        Rect.fromLTWH(0, 0, size.width, size.height),
        start,
        sweep,
        true,
        p,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) => true;
}
