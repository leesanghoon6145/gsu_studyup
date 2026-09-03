import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:convert'; // 🆕 [데이터 연결] 성적 기록 JSON 직렬화용
import 'package:shared_preferences/shared_preferences.dart';
import '../global_lang.dart'; // 👑 글로벌 사전 연결
import '../services/user_profile_service.dart'; // 🆕 [실사용 전환] 실제 가입자 이름 조회용
import 'package:firebase_auth/firebase_auth.dart'; // 🆕 [반복 방지] 사람 구분(uid)용
import '../star_economy.dart'; // 🆕 [버그 수정] DkeStars 클래스 사용을 위한 import 누락 수정 (Undefined name 'DkeStars' 에러의 원인)

class MemberAchievementScreen extends StatefulWidget {
  const MemberAchievementScreen({Key? key}) : super(key: key);

  @override
  State<MemberAchievementScreen> createState() => _MemberAchievementScreenState();
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
  final int grade;   // 1, 2, 3학년
  final int semester; // 1, 2학기
  final DateTime date;
  final String subject;
  final String unit;
  final double score;

  // 🆕 [선배님 지시사항]: 팝업창 저장 데이터 세션 확장 바인딩
  final String durationText;   // 소요시간 (예: 45분)
  final String difficultyLevel; // 난이도 (매우쉬움, 쉬움, 보통, 어려움, 매우어려움)
  final int starSatisfaction;  // 시험 만족도 (별점 1~5)
  final List<String> errorCauses; // 실수 원인 복수 선택 리스트
  final String reviewRequired;  // 복습 필요 여부 (필요, 예정, 불필요)

  // 모의고사 전용 추가 필드
  final String mockMonth;      // 몇월 모의고사
  final String mockRank;       // 등급 또는 석차

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
    id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
    errorCauses: (json['errorCauses'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const ["개념부족"],
    reviewRequired: json['reviewRequired'] as String? ?? "필요",
    mockMonth: json['mockMonth'] as String? ?? "",
    mockRank: json['mockRank'] as String? ?? "",
  );
}

class _MemberAchievementScreenState extends State<MemberAchievementScreen> with TickerProviderStateMixin {
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
    const Color(0xFFFF3B30), const Color(0xFFFF9500), const Color(0xFFFFCC00),
    const Color(0xFF34C759), const Color(0xFF007AFF), const Color(0xFF0500FF),
    const Color(0xFFAF52DE), const Color(0xFF5856D6),
  ];

  final List<Color> _weeklyColors = [
    const Color(0xFF34C759), const Color(0xFF0500FF), const Color(0xFF007AFF),
    const Color(0xFFAF52DE), const Color(0xFFFF3B30), const Color(0xFFFF9500),
    const Color(0xFFFFCC00), const Color(0xFF5856D6),
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
    "수학": {'KO':'수학','EN':'Math','JA':'数学','ZH':'数学','FR':'Maths','DE':'Mathe','RU':'Матем.','AR':'رياضيات','HI':'गणित','VI':'Toán','ES':'Mate','TH':'คณิต'},
    "영어": {'KO':'영어','EN':'En','JA':'英語','ZH':'英语','FR':'Anglais','DE':'Englisch','RU':'Англ.','AR':'إنجليزي','HI':'अंग्रेज़ी','VI':'Tiếng Anh','ES':'Inglés','TH':'อังกฤษ'},
    "국어": {'KO':'국어','EN':'Kor','JA':'国語','ZH':'语文','FR':'Coréen','DE':'Koreanisch','RU':'Кор. яз.','AR':'كورية','HI':'कोरियाई','VI':'Tiếng Hàn','ES':'Coreano','TH':'ภาษาเกาหลี'},
    "과학": {'KO':'과학','EN':'Sci','JA':'理科','ZH':'科学','FR':'Sciences','DE':'Wissen.','RU':'Наука','AR':'علوم','HI':'विज्ञान','VI':'Khoa học','ES':'Ciencia','TH':'วิทย์'},
    "사회": {'KO':'사회','EN':'Soc','JA':'社会','ZH':'社会','FR':'Sociales','DE':'Sozial.','RU':'Обществ.','AR':'اجتماعيات','HI':'सामाजिक','VI':'Xã hội','ES':'Sociales','TH':'สังคม'},
    "도덕": {'KO':'도덕','EN':'Eth','JA':'道徳','ZH':'道德','FR':'Éthique','DE':'Ethik','RU':'Этика','AR':'أخلاق','HI':'नैतिक','VI':'Đạo đức','ES':'Ética','TH':'ศีลธรรม'},
    "역사": {'KO':'역사','EN':'Hist','JA':'歴史','ZH':'历史','FR':'Histoire','DE':'Gesch.','RU':'История','AR':'تاريخ','HI':'इतिहास','VI':'Lịch sử','ES':'Historia','TH':'ประวัติ'},
    "정보": {'KO':'정보','EN':'Info','JA':'情報','ZH':'信息','FR':'Info','DE':'Info','RU':'Информ.','AR':'معلوماتية','HI':'सूचना','VI':'CNTT','ES':'Informát.','TH':'ไอที'},
  };

  static String _subjectName(String koKey) {
    final map = _subjectNames[koKey];
    if (map == null) return koKey;
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? koKey;
  }

  // 🆕 [12개국 UI 문구 카탈로그] + 조회 헬퍼 _t()
  static const Map<String, Map<String, String>> _uiText = {
    'lv26': {'KO': '학습레벨 26', 'EN': 'Lv.26', 'JA': 'レベル26', 'ZH': '等级26', 'FR': 'Niv. 26', 'DE': 'Lvl. 26', 'RU': 'Уровень 26', 'AR': 'المستوى 26', 'HI': 'लेवल 26', 'VI': 'Cấp 26', 'ES': 'Nivel 26', 'TH': 'เลเวล 26'},
    'timerDetailDefault': {'KO': '개념 및 심화, 문제풀이 25문제', 'EN': 'Solved concepts and problems, 25 issues', 'JA': '概念と応用問題25問を解答', 'ZH': '概念与拓展，完成25道题', 'FR': 'Concepts et exercices, 25 problèmes résolus', 'DE': 'Konzepte und Übungen, 25 Aufgaben gelöst', 'RU': 'Концепции и задачи, решено 25 заданий', 'AR': 'مفاهيم وتطبيقات، تم حل 25 مسألة', 'HI': 'अवधारणाएं और अभ्यास, 25 प्रश्न हल किए', 'VI': 'Khái niệm và bài tập nâng cao, giải 25 câu', 'ES': 'Conceptos y ejercicios, 25 problemas resueltos', 'TH': 'แนวคิดและโจทย์เชิงลึก แก้ไปแล้ว 25 ข้อ'},
    'completed': {'KO': '정리함', 'EN': 'COMPLETED', 'JA': '整理済み', 'ZH': '已整理', 'FR': 'TERMINÉ', 'DE': 'ERLEDIGT', 'RU': 'ЗАВЕРШЕНО', 'AR': 'مكتمل', 'HI': 'पूर्ण', 'VI': 'ĐÃ HOÀN THÀNH', 'ES': 'COMPLETADO', 'TH': 'เรียบร้อยแล้ว'},
    'examSummaryHeader': {'KO': '\n\n[직접 작성 주평가 실시간 연동]\n', 'EN': '\n\n[Live-Linked Weekly Evaluations]\n', 'JA': '\n\n[週次評価のリアルタイム連携]\n', 'ZH': '\n\n[实时联动的每周评估]\n', 'FR': '\n\n[Évaluations hebdomadaires liées en direct]\n', 'DE': '\n\n[Live verknüpfte wöchentliche Bewertungen]\n', 'RU': '\n\n[Еженедельные оценки в реальном времени]\n', 'AR': '\n\n[التقييمات الأسبوعية المرتبطة مباشرة]\n', 'HI': '\n\n[लाइव-लिंक्ड साप्ताहिक मूल्यांकन]\n', 'VI': '\n\n[Đánh giá hằng tuần được liên kết trực tiếp]\n', 'ES': '\n\n[Evaluaciones semanales vinculadas en vivo]\n', 'TH': '\n\n[การประเมินรายสัปดาห์ที่เชื่อมโยงสด]\n'},
    'diagReportTitle': {'KO': '👑 DKE 교육성취 정밀 진단서', 'EN': '👑 DKE Achievement Diagnosis Report', 'JA': '👑 DKE 教育成果 精密診断書', 'ZH': '👑 DKE 教育成果精密诊断报告', 'FR': '👑 Rapport de diagnostic de réussite DKE', 'DE': '👑 DKE Leistungsdiagnosebericht', 'RU': '👑 Отчёт по диагностике успеваемости DKE', 'AR': '👑 تقرير تشخيص التحصيل الدراسي DKE', 'HI': '👑 DKE उपलब्धि निदान रिपोर्ट', 'VI': '👑 Báo cáo chẩn đoán thành tích DKE', 'ES': '👑 Informe de diagnóstico de logros DKE', 'TH': '👑 รายงานวินิจฉัยผลสัมฤทธิ์ DKE'},
    'mockMonthLabel': {'KO': '• 몇 월 모의고사 (직접 입력)', 'EN': '• Which Month (custom input)', 'JA': '• 何月の模試か（直接入力）', 'ZH': '• 几月的模拟考（自定义输入）', 'FR': '• Quel mois (saisie libre)', 'DE': '• Welcher Monat (freie Eingabe)', 'RU': '• Какой месяц (произвольный ввод)', 'AR': '• أي شهر (إدخال مخصص)', 'HI': '• कौन सा महीना (कस्टम इनपुट)', 'VI': '• Tháng nào (nhập tùy chỉnh)', 'ES': '• Qué mes (entrada personalizada)', 'TH': '• เดือนไหน (กรอกเอง)'},
    'mockRankLabel': {'KO': '• 등급 또는 석차 (직접 입력)', 'EN': '• Grade or Rank (custom input)', 'JA': '• 等級または順位（直接入力）', 'ZH': '• 等级或排名（自定义输入）', 'FR': '• Note ou rang (saisie libre)', 'DE': '• Note oder Rang (freie Eingabe)', 'RU': '• Оценка или ранг (произвольный ввод)', 'AR': '• الدرجة أو الترتيب (إدخال مخصص)', 'HI': '• ग्रेड या रैंक (कस्टम इनपुट)', 'VI': '• Xếp hạng hoặc thứ hạng (nhập tùy chỉnh)', 'ES': '• Nota o clasificación (entrada personalizada)', 'TH': '• เกรดหรืออันดับ (กรอกเอง)'},
    'label1Duration': {'KO': '1. 소요시간 (직접 입력)', 'EN': '1. Duration (custom input)', 'JA': '1. 所要時間（直接入力）', 'ZH': '1. 所用时间（自定义输入）', 'FR': '1. Durée (saisie libre)', 'DE': '1. Dauer (freie Eingabe)', 'RU': '1. Продолжительность (произвольный ввод)', 'AR': '1. المدة (إدخال مخصص)', 'HI': '1. अवधि (कस्टम इनपुट)', 'VI': '1. Thời gian (nhập tùy chỉnh)', 'ES': '1. Duración (entrada personalizada)', 'TH': '1. ระยะเวลา (กรอกเอง)'},
    'label2Difficulty': {'KO': '2. 난이도 설정 (단일 선택)', 'EN': '2. Difficulty (single select)', 'JA': '2. 難易度設定（単一選択）', 'ZH': '2. 难度设置（单选）', 'FR': '2. Difficulté (choix unique)', 'DE': '2. Schwierigkeit (Einzelauswahl)', 'RU': '2. Сложность (один вариант)', 'AR': '2. مستوى الصعوبة (اختيار واحد)', 'HI': '2. कठिनाई स्तर (एकल चयन)', 'VI': '2. Độ khó (chọn một)', 'ES': '2. Dificultad (selección única)', 'TH': '2. ระดับความยาก (เลือกเดียว)'},
    'label3Satisfaction': {'KO': '3. 시험 만족도 지표', 'EN': '3. Satisfaction Rating', 'JA': '3. 試験満足度指標', 'ZH': '3. 考试满意度指标', 'FR': '3. Indice de satisfaction', 'DE': '3. Zufriedenheitsbewertung', 'RU': '3. Оценка удовлетворённости', 'AR': '3. مؤشر الرضا عن الاختبار', 'HI': '3. संतुष्टि रेटिंग', 'VI': '3. Mức độ hài lòng', 'ES': '3. Índice de satisfacción', 'TH': '3. คะแนนความพึงพอใจ'},
    'label4ErrorMulti': {'KO': '4. 실수 원인 진단 (복수 선택 가능)', 'EN': '4. Error Causes (multi-select)', 'JA': '4. ミスの原因診断（複数選択可）', 'ZH': '4. 失分原因诊断（可多选）', 'FR': '4. Causes d\'erreurs (choix multiple)', 'DE': '4. Fehlerursachen (Mehrfachauswahl)', 'RU': '4. Причины ошибок (можно выбрать несколько)', 'AR': '4. أسباب الأخطاء (اختيار متعدد)', 'HI': '4. गलती के कारण (बहु-चयन)', 'VI': '4. Nguyên nhân sai sót (chọn nhiều)', 'ES': '4. Causas de error (selección múltiple)', 'TH': '4. สาเหตุข้อผิดพลาด (เลือกได้หลายข้อ)'},
    'label5ReviewSelect': {'KO': '5. 복습 필요 여부 선택', 'EN': '5. Review Needed?', 'JA': '5. 復習が必要か選択', 'ZH': '5. 是否需要复习', 'FR': '5. Révision nécessaire ?', 'DE': '5. Wiederholung nötig?', 'RU': '5. Нужно повторение?', 'AR': '5. هل تحتاج إلى مراجعة؟', 'HI': '5. क्या पुनरीक्षण आवश्यक है?', 'VI': '5. Có cần ôn lại không?', 'ES': '5. ¿Necesita repaso?', 'TH': '5. ต้องทบทวนหรือไม่'},
    'confirmBtn': {'KO': '확인', 'EN': 'Confirm', 'JA': '確認', 'ZH': '确认', 'FR': 'Confirmer', 'DE': 'Bestätigen', 'RU': 'Подтвердить', 'AR': 'تأكيد', 'HI': 'पुष्टि करें', 'VI': 'Xác nhận', 'ES': 'Confirmar', 'TH': 'ยืนยัน'},
    'label1DurationShort': {'KO': '1. 시험 소요시간', 'EN': '1. Duration', 'JA': '1. 試験所要時間', 'ZH': '1. 考试用时', 'FR': '1. Durée', 'DE': '1. Dauer', 'RU': '1. Продолжительность', 'AR': '1. المدة', 'HI': '1. अवधि', 'VI': '1. Thời gian', 'ES': '1. Duración', 'TH': '1. ระยะเวลา'},
    'label2DifficultyShort': {'KO': '2. 출제 난이도', 'EN': '2. Difficulty', 'JA': '2. 出題難易度', 'ZH': '2. 出题难度', 'FR': '2. Difficulté', 'DE': '2. Schwierigkeit', 'RU': '2. Сложность', 'AR': '2. مستوى الصعوبة', 'HI': '2. कठिनाई', 'VI': '2. Độ khó', 'ES': '2. Dificultad', 'TH': '2. ความยาก'},
    'label3SatisfactionShort': {'KO': '3. 시험 만족도', 'EN': '3. Satisfaction', 'JA': '3. 試験満足度', 'ZH': '3. 考试满意度', 'FR': '3. Satisfaction', 'DE': '3. Zufriedenheit', 'RU': '3. Удовлетворённость', 'AR': '3. الرضا', 'HI': '3. संतुष्टि', 'VI': '3. Mức hài lòng', 'ES': '3. Satisfacción', 'TH': '3. ความพึงพอใจ'},
    'label4ErrorShort': {'KO': '4. 주요 실수 원인', 'EN': '4. Error Causes', 'JA': '4. 主なミス原因', 'ZH': '4. 主要失分原因', 'FR': '4. Causes d\'erreurs', 'DE': '4. Fehlerursachen', 'RU': '4. Причины ошибок', 'AR': '4. أسباب الأخطاء', 'HI': '4. गलती के कारण', 'VI': '4. Nguyên nhân sai sót', 'ES': '4. Causas de error', 'TH': '4. สาเหตุข้อผิดพลาด'},
    'label5ReviewShort': {'KO': '5. 복습 필요 여부', 'EN': '5. Review Needed', 'JA': '5. 復習の必要性', 'ZH': '5. 是否需要复习', 'FR': '5. Révision nécessaire', 'DE': '5. Wiederholung nötig', 'RU': '5. Нужно повторение', 'AR': '5. الحاجة للمراجعة', 'HI': '5. पुनरीक्षण आवश्यक', 'VI': '5. Cần ôn lại', 'ES': '5. Necesita repaso', 'TH': '5. ต้องทบทวน'},
    'totalReport': {'KO': '종합 리포트', 'EN': 'Total Report', 'JA': '総合レポート', 'ZH': '综合报告', 'FR': 'Rapport global', 'DE': 'Gesamtbericht', 'RU': 'Общий отчёт', 'AR': 'التقرير الشامل', 'HI': 'समग्र रिपोर्ट', 'VI': 'Báo cáo tổng hợp', 'ES': 'Informe general', 'TH': 'รายงานสรุป'},
    'detailedAnalytics': {'KO': '상세분석기록', 'EN': 'Detailed Analytics', 'JA': '詳細分析記録', 'ZH': '详细分析记录', 'FR': 'Analyse détaillée', 'DE': 'Detaillierte Analyse', 'RU': 'Подробная аналитика', 'AR': 'تحليل تفصيلي', 'HI': 'विस्तृत विश्लेषण', 'VI': 'Phân tích chi tiết', 'ES': 'Análisis detallado', 'TH': 'บันทึกวิเคราะห์เชิงลึก'},
    'nextLevelRoad': {'KO': '학습레벨로드', 'EN': 'Next Level Road', 'JA': '次のレベルへの道', 'ZH': '下一等级之路', 'FR': 'Vers le niveau suivant', 'DE': 'Weg zum nächsten Level', 'RU': 'Путь к следующему уровню', 'AR': 'الطريق إلى المستوى التالي', 'HI': 'अगले स्तर की राह', 'VI': 'Lộ trình cấp độ tiếp theo', 'ES': 'Camino al siguiente nivel', 'TH': 'เส้นทางสู่เลเวลถัดไป'},
    'todaySessionsTitle': {'KO': '오늘 학습한 과목', 'EN': "Today's Study Sessions", 'JA': '本日の学習科目', 'ZH': '今日学习科目', 'FR': "Sessions d'étude du jour", 'DE': 'Heutige Lernsitzungen', 'RU': 'Сегодняшние занятия', 'AR': 'جلسات الدراسة اليوم', 'HI': 'आज के अध्ययन सत्र', 'VI': 'Buổi học hôm nay', 'ES': 'Sesiones de estudio de hoy', 'TH': 'วิชาที่เรียนวันนี้'},
    'noSessionsToday': {'KO': '오늘 진행한 학습 세션이 아직 없습니다.', 'EN': 'No study sessions recorded today yet.', 'JA': '本日の学習セッションはまだありません。', 'ZH': '今天还没有学习记录。', 'FR': "Aucune session d'étude aujourd'hui pour l'instant.", 'DE': 'Heute wurden noch keine Lernsitzungen aufgezeichnet.', 'RU': 'Сегодня пока нет записанных занятий.', 'AR': 'لا توجد جلسات دراسة مسجلة اليوم بعد.', 'HI': 'आज तक कोई अध्ययन सत्र दर्ज नहीं हुआ।', 'VI': 'Hôm nay chưa có buổi học nào được ghi lại.', 'ES': 'Aún no se han registrado sesiones de estudio hoy.', 'TH': 'วันนี้ยังไม่มีการบันทึกการเรียน'},
    'sessionOrdinal': {'KO': '교시', 'EN': 'Session', 'JA': '時限目', 'ZH': '节', 'FR': 'Séance', 'DE': 'Einheit', 'RU': 'Занятие', 'AR': 'حصة', 'HI': 'सत्र', 'VI': 'Tiết', 'ES': 'Sesión', 'TH': 'คาบ'},
    'minutesUnitSuffix': {'KO': '분', 'EN': 'min', 'JA': '分', 'ZH': '分钟', 'FR': 'min', 'DE': 'Min', 'RU': 'мин', 'AR': 'دقيقة', 'HI': 'मिनट', 'VI': 'phút', 'ES': 'min', 'TH': 'นาที'},
    'starsCount': {'KO': '23,487 개', 'EN': '23,487 Stars', 'JA': '23,487個', 'ZH': '23,487颗', 'FR': '23 487 étoiles', 'DE': '23.487 Sterne', 'RU': '23 487 звёзд', 'AR': '23,487 نجمة', 'HI': '23,487 स्टार्स', 'VI': '23.487 sao', 'ES': '23.487 estrellas', 'TH': '23,487 ดาว'},
    // 🆕 [데이터 연결] 아래 4개는 실제 숫자와 조합해서 쓰는 "단위/접두어" 문구 (숫자 자체는 더 이상 하드코딩하지 않음)
    'levelPrefix': {'KO': '학습레벨 ', 'EN': 'Lv.', 'JA': 'レベル', 'ZH': '等级', 'FR': 'Niv. ', 'DE': 'Lvl. ', 'RU': 'Уровень ', 'AR': 'المستوى ', 'HI': 'लेवल ', 'VI': 'Cấp ', 'ES': 'Nivel ', 'TH': 'เลเวล '},
    'starsUnitSuffix': {'KO': '개', 'EN': 'Stars', 'JA': '個', 'ZH': '颗', 'FR': 'étoiles', 'DE': 'Sterne', 'RU': 'звёзд', 'AR': 'نجمة', 'HI': 'स्टार्स', 'VI': 'sao', 'ES': 'estrellas', 'TH': 'ดาว'},
    'hoursUnitSuffix': {'KO': '시간', 'EN': 'hrs', 'JA': '時間', 'ZH': '小时', 'FR': 'h', 'DE': 'Std.', 'RU': 'ч', 'AR': 'ساعة', 'HI': 'घंटे', 'VI': 'giờ', 'ES': 'h', 'TH': 'ชม.'},
    'dataCollectingMsg': {'KO': '데이터 수집중', 'EN': 'Collecting data', 'JA': 'データ収集中', 'ZH': '数据收集中', 'FR': 'Collecte de données...', 'DE': 'Daten werden gesammelt', 'RU': 'Сбор данных...', 'AR': 'جمع البيانات...', 'HI': 'डेटा एकत्रित हो रहा है', 'VI': 'Đang thu thập dữ liệu', 'ES': 'Recopilando datos...', 'TH': 'กำลังรวบรวมข้อมูล'},
    'friendRank': {'KO': '친구 학습 랭킹: ', 'EN': 'Friend Rank: ', 'JA': '友達学習ランキング: ', 'ZH': '好友学习排名：', 'FR': 'Classement amis : ', 'DE': 'Freunde-Rang: ', 'RU': 'Рейтинг друзей: ', 'AR': 'ترتيب الأصدقاء: ', 'HI': 'मित्र रैंक: ', 'VI': 'Xếp hạng bạn bè: ', 'ES': 'Ranking de amigos: ', 'TH': 'อันดับเพื่อน: '},
    'rank3': {'KO': '3위\n\n', 'EN': '#3\n\n', 'JA': '3位\n\n', 'ZH': '第3名\n\n', 'FR': '#3\n\n', 'DE': '#3\n\n', 'RU': '#3\n\n', 'AR': '#3\n\n', 'HI': '#3\n\n', 'VI': '#3\n\n', 'ES': '#3\n\n', 'TH': 'อันดับ 3\n\n'},
    'globalRank': {'KO': '전 세계 학습 랭킹:\n', 'EN': 'Global Rank:\n', 'JA': '世界学習ランキング：\n', 'ZH': '全球学习排名：\n', 'FR': 'Classement mondial :\n', 'DE': 'Weltweiter Rang:\n', 'RU': 'Мировой рейтинг:\n', 'AR': 'الترتيب العالمي:\n', 'HI': 'वैश्विक रैंक:\n', 'VI': 'Xếp hạng toàn cầu:\n', 'ES': 'Ranking mundial:\n', 'TH': 'อันดับโลก:\n'},
    'top12pct': {'KO': '상위 1.2%', 'EN': 'Top 1.2%', 'JA': '上位1.2%', 'ZH': '前1.2%', 'FR': 'Top 1,2 %', 'DE': 'Top 1,2 %', 'RU': 'Топ 1,2%', 'AR': 'الأعلى 1.2٪', 'HI': 'शीर्ष 1.2%', 'VI': 'Top 1.2%', 'ES': 'Top 1.2%', 'TH': 'ท็อป 1.2%'},
    'targetUniversity': {'KO': '목표 대학', 'EN': 'Target University', 'JA': '目標大学', 'ZH': '目标大学', 'FR': 'Université cible', 'DE': 'Zieluniversität', 'RU': 'Целевой университет', 'AR': 'الجامعة المستهدفة', 'HI': 'लक्ष्य विश्वविद्यालय', 'VI': 'Trường mục tiêu', 'ES': 'Universidad objetivo', 'TH': 'มหาวิทยาลัยเป้าหมาย'},
    'snu': {'KO': '서울대학교', 'EN': 'Seoul National University', 'JA': 'ソウル大学校', 'ZH': '首尔大学', 'FR': 'Université Nationale de Séoul', 'DE': 'Nationaluniversität Seoul', 'RU': 'Сеульский национальный университет', 'AR': 'جامعة سيول الوطنية', 'HI': 'सियोल नेशनल यूनिवर्सिटी', 'VI': 'Đại học Quốc gia Seoul', 'ES': 'Universidad Nacional de Seúl', 'TH': 'มหาวิทยาลัยแห่งชาติโซล'},
    'goalAttainment': {'KO': '목표 달성도', 'EN': 'Goal Attainment', 'JA': '目標達成度', 'ZH': '目标达成度', 'FR': 'Taux d\'atteinte', 'DE': 'Zielerreichung', 'RU': 'Достижение цели', 'AR': 'نسبة تحقيق الهدف', 'HI': 'लक्ष्य प्राप्ति', 'VI': 'Mức đạt mục tiêu', 'ES': 'Logro de objetivos', 'TH': 'อัตราการบรรลุเป้าหมาย'},
    'todayVsYesterday': {'KO': '어제 대비 오늘 ', 'EN': 'Today vs Yesterday ', 'JA': '昨日比 本日 ', 'ZH': '今日较昨日 ', 'FR': 'Aujourd\'hui vs hier ', 'DE': 'Heute vs. gestern ', 'RU': 'Сегодня к вчера ', 'AR': 'اليوم مقارنة بالأمس ', 'HI': 'आज बनाम कल ', 'VI': 'Hôm nay so với hôm qua ', 'ES': 'Hoy vs ayer ', 'TH': 'วันนี้เทียบเมื่อวาน '},
    'mostImprovedSubject': {'KO': '가장 성장한 학습과목\n', 'EN': 'Most Improved Subject\n', 'JA': '最も伸びた科目\n', 'ZH': '进步最大的科目\n', 'FR': 'Matière la plus améliorée\n', 'DE': 'Am meisten verbessertes Fach\n', 'RU': 'Предмет с наибольшим ростом\n', 'AR': 'أكثر مادة تحسنًا\n', 'HI': 'सबसे अधिक सुधार वाला विषय\n', 'VI': 'Môn học tiến bộ nhất\n', 'ES': 'Materia más mejorada\n', 'TH': 'วิชาที่พัฒนามากที่สุด\n'},
    'mostStudiedSubject': {'KO': '가장 많이 학습한 과목\n', 'EN': 'Most Studied Subject\n', 'JA': '最も学習した科目\n', 'ZH': '学习最多的科目\n', 'FR': 'Matière la plus étudiée\n', 'DE': 'Meist gelerntes Fach\n', 'RU': 'Самый изучаемый предмет\n', 'AR': 'أكثر مادة تمت دراستها\n', 'HI': 'सबसे अधिक पढ़ा गया विषय\n', 'VI': 'Môn học được học nhiều nhất\n', 'ES': 'Materia más estudiada\n', 'TH': 'วิชาที่เรียนมากที่สุด\n'},
    'totalStudyTimeLabel': {'KO': '총 학습시간:\n', 'EN': 'Total Study Time:\n', 'JA': '総学習時間：\n', 'ZH': '总学习时间：\n', 'FR': 'Temps d\'étude total :\n', 'DE': 'Gesamte Lernzeit:\n', 'RU': 'Общее время учёбы:\n', 'AR': 'إجمالي وقت الدراسة:\n', 'HI': 'कुल अध्ययन समय:\n', 'VI': 'Tổng thời gian học:\n', 'ES': 'Tiempo total de estudio:\n', 'TH': 'เวลาเรียนทั้งหมด:\n'},
    'totalStudyHours': {'KO': '1,257시간', 'EN': '1,257 hrs', 'JA': '1,257時間', 'ZH': '1,257小时', 'FR': '1 257 h', 'DE': '1.257 Std.', 'RU': '1 257 ч', 'AR': '1,257 ساعة', 'HI': '1,257 घंटे', 'VI': '1.257 giờ', 'ES': '1.257 h', 'TH': '1,257 ชม.'},
    'studyTime': {'KO': '과목 학습 시간', 'EN': 'Subject Study Time', 'JA': '科目別学習時間', 'ZH': '科目学习时间', 'FR': 'Temps d\'étude par matière', 'DE': 'Lernzeit pro Fach', 'RU': 'Время учёбы по предметам', 'AR': 'وقت الدراسة حسب المادة', 'HI': 'विषयवार अध्ययन समय', 'VI': 'Thời gian học theo môn', 'ES': 'Tiempo de estudio por materia', 'TH': 'เวลาเรียนตามวิชา'},
    'dailyTotalStudyTime': {'KO': '일일 전체 학습시간', 'EN': 'Daily Total Study Time', 'JA': '日別総学習時間', 'ZH': '每日总学习时间', 'FR': 'Temps d\'étude quotidien total', 'DE': 'Tägliche Gesamtlernzeit', 'RU': 'Общее время учёбы за день', 'AR': 'إجمالي وقت الدراسة اليومي', 'HI': 'दैनिक कुल अध्ययन समय', 'VI': 'Tổng thời gian học mỗi ngày', 'ES': 'Tiempo total de estudio diario', 'TH': 'เวลาเรียนรวมต่อวัน'},
    'daily': {'KO': '일 간', 'EN': 'Daily', 'JA': '日別', 'ZH': '日', 'FR': 'Jour', 'DE': 'Täglich', 'RU': 'День', 'AR': 'يومي', 'HI': 'दैनिक', 'VI': 'Ngày', 'ES': 'Diario', 'TH': 'รายวัน'},
    'weekly': {'KO': '주 간', 'EN': 'Weekly', 'JA': '週別', 'ZH': '周', 'FR': 'Semaine', 'DE': 'Wöchentlich', 'RU': 'Неделя', 'AR': 'أسبوعي', 'HI': 'साप्ताहिक', 'VI': 'Tuần', 'ES': 'Semanal', 'TH': 'รายสัปดาห์'},
    'monthly': {'KO': '월 간', 'EN': 'Monthly', 'JA': '月別', 'ZH': '月', 'FR': 'Mois', 'DE': 'Monatlich', 'RU': 'Месяц', 'AR': 'شهري', 'HI': 'मासिक', 'VI': 'Tháng', 'ES': 'Mensual', 'TH': 'รายเดือน'},
    'yearly': {'KO': '연 간', 'EN': 'Yearly', 'JA': '年別', 'ZH': '年', 'FR': 'Année', 'DE': 'Jährlich', 'RU': 'Год', 'AR': 'سنوي', 'HI': 'वार्षिक', 'VI': 'Năm', 'ES': 'Anual', 'TH': 'รายปี'},
    'myScoreRecord': {'KO': '나의 성적 기록 직접 작성', 'EN': 'My Score Self Record', 'JA': '自分の成績を記録する', 'ZH': '自主记录我的成绩', 'FR': 'Mon carnet de notes', 'DE': 'Meine Notenaufzeichnung', 'RU': 'Мои записи об оценках', 'AR': 'سجل درجاتي الخاص', 'HI': 'मेरा स्कोर रिकॉर्ड', 'VI': 'Tự ghi điểm của tôi', 'ES': 'Mi registro de notas', 'TH': 'บันทึกคะแนนของฉัน'},
    'yearSelect': {'KO': '년도 선택', 'EN': 'Year', 'JA': '年を選択', 'ZH': '选择年份', 'FR': 'Année', 'DE': 'Jahr', 'RU': 'Год', 'AR': 'السنة', 'HI': 'वर्ष', 'VI': 'Năm', 'ES': 'Año', 'TH': 'ปี'},
    'monthSelect': {'KO': '월 선택', 'EN': 'Month', 'JA': '月を選択', 'ZH': '选择月份', 'FR': 'Mois', 'DE': 'Monat', 'RU': 'Месяц', 'AR': 'الشهر', 'HI': 'महीना', 'VI': 'Tháng', 'ES': 'Mes', 'TH': 'เดือน'},
    'weekSelect': {'KO': '주 선택', 'EN': 'Week', 'JA': '週を選択', 'ZH': '选择周次', 'FR': 'Semaine', 'DE': 'Woche', 'RU': 'Неделя', 'AR': 'الأسبوع', 'HI': 'सप्ताह', 'VI': 'Tuần', 'ES': 'Semana', 'TH': 'สัปดาห์'},
    'bigUnitSelect': {'KO': '대단원 선택', 'EN': 'Major Unit', 'JA': '大単元を選択', 'ZH': '选择大单元', 'FR': 'Unité principale', 'DE': 'Haupteinheit', 'RU': 'Основной раздел', 'AR': 'الوحدة الرئيسية', 'HI': 'मुख्य यूनिट', 'VI': 'Chương lớn', 'ES': 'Unidad principal', 'TH': 'บทหลัก'},
    'midUnitSelect': {'KO': '중단원 선택', 'EN': 'Sub Unit', 'JA': '中単元を選択', 'ZH': '选择中单元', 'FR': 'Sous-unité', 'DE': 'Untereinheit', 'RU': 'Подраздел', 'AR': 'الوحدة الفرعية', 'HI': 'सब-यूनिट', 'VI': 'Chương nhỏ', 'ES': 'Subunidad', 'TH': 'บทย่อย'},
    'semesterSelect': {'KO': '학기 선택', 'EN': 'Semester', 'JA': '学期を選択', 'ZH': '选择学期', 'FR': 'Semestre', 'DE': 'Semester', 'RU': 'Семестр', 'AR': 'الفصل الدراسي', 'HI': 'सेमेस्टर', 'VI': 'Học kỳ', 'ES': 'Semestre', 'TH': 'ภาคเรียน'},
    'chartTarget': {'KO': '그래프 출력 타겟 지정 (학년 / 학기)', 'EN': 'Chart Target (Grade / Semester)', 'JA': 'グラフ対象指定（学年／学期）', 'ZH': '图表目标设置（年级／学期）', 'FR': 'Cible du graphique (année / semestre)', 'DE': 'Diagrammziel (Klasse / Semester)', 'RU': 'Цель графика (класс / семестр)', 'AR': 'هدف الرسم البياني (الصف / الفصل)', 'HI': 'चार्ट लक्ष्य (कक्षा / सेमेस्टर)', 'VI': 'Mục tiêu biểu đồ (khối / học kỳ)', 'ES': 'Objetivo del gráfico (grado / semestre)', 'TH': 'เป้าหมายกราฟ (ระดับชั้น/ภาคเรียน)'},
    'newRecordGradeSemesterLabel': {'KO': '지금 입력할 새 기록의 학년 / 학기', 'EN': 'Grade / Semester for this new entry', 'JA': '今回入力する記録の学年／学期', 'ZH': '本次输入记录的年级／学期', 'FR': 'Année / semestre de cette nouvelle entrée', 'DE': 'Klasse / Semester für diesen neuen Eintrag', 'RU': 'Класс / семестр для новой записи', 'AR': 'الصف / الفصل لهذا السجل الجديد', 'HI': 'इस नई प्रविष्टि के लिए कक्षा / सेमेस्टर', 'VI': 'Khối / học kỳ cho mục nhập mới này', 'ES': 'Grado / semestre para esta nueva entrada', 'TH': 'ระดับชั้น/ภาคเรียนสำหรับรายการใหม่นี้'},
    'gradeLabel': {'KO': '학년', 'EN': 'Grade', 'JA': '学年', 'ZH': '年级', 'FR': 'Année', 'DE': 'Klasse', 'RU': 'Класс', 'AR': 'الصف', 'HI': 'कक्षा', 'VI': 'Khối lớp', 'ES': 'Grado', 'TH': 'ระดับชั้น'},
    'semesterLabel': {'KO': '학기', 'EN': 'Semester', 'JA': '学期', 'ZH': '学期', 'FR': 'Semestre', 'DE': 'Semester', 'RU': 'Семестр', 'AR': 'الفصل الدراسي', 'HI': 'सेमेस्टर', 'VI': 'Học kỳ', 'ES': 'Semestre', 'TH': 'ภาคเรียน'},
    'subjectHint': {'KO': '과목생성', 'EN': 'Subject', 'JA': '科目作成', 'ZH': '创建科目', 'FR': 'Matière', 'DE': 'Fach', 'RU': 'Предмет', 'AR': 'المادة', 'HI': 'विषय', 'VI': 'Môn học', 'ES': 'Materia', 'TH': 'วิชา'},
    'unitHint': {'KO': '단원생성', 'EN': 'Unit', 'JA': '単元作成', 'ZH': '创建单元', 'FR': 'Unité', 'DE': 'Einheit', 'RU': 'Раздел', 'AR': 'الوحدة', 'HI': 'यूनिट', 'VI': 'Chương', 'ES': 'Unidad', 'TH': 'บท'},
    'scoreHint': {'KO': '점수', 'EN': 'Score', 'JA': '点数', 'ZH': '分数', 'FR': 'Score', 'DE': 'Punktzahl', 'RU': 'Балл', 'AR': 'الدرجة', 'HI': 'स्कोर', 'VI': 'Điểm', 'ES': 'Puntuación', 'TH': 'คะแนน'},
    'saveBtn': {'KO': '저장', 'EN': 'Save', 'JA': '保存', 'ZH': '保存', 'FR': 'Enregistrer', 'DE': 'Speichern', 'RU': 'Сохранить', 'AR': 'حفظ', 'HI': 'सहेजें', 'VI': 'Lưu', 'ES': 'Guardar', 'TH': 'บันทึก'},
    'onlyRecordedSubjectsChart': {'KO': '평가가 기록된 과목만 그래프에 나타나게한다', 'EN': 'Only subjects with recorded evaluations appear on the chart.', 'JA': '評価が記録された科目だけがグラフに表示されます。', 'ZH': '仅显示已记录评估的科目。', 'FR': 'Seules les matières évaluées apparaissent sur le graphique.', 'DE': 'Nur bewertete Fächer werden im Diagramm angezeigt.', 'RU': 'На графике отображаются только оценённые предметы.', 'AR': 'تظهر في الرسم البياني فقط المواد التي تم تسجيل تقييم لها.', 'HI': 'चार्ट में केवल मूल्यांकित विषय ही दिखाए जाते हैं।', 'VI': 'Chỉ các môn đã có điểm đánh giá mới hiển thị trên biểu đồ.', 'ES': 'Solo las materias con evaluaciones registradas aparecen en el gráfico.', 'TH': 'กราฟจะแสดงเฉพาะวิชาที่มีการบันทึกผลประเมินเท่านั้น'},
    'average': {'KO': '평균', 'EN': 'Average', 'JA': '平均', 'ZH': '平均', 'FR': 'Moyenne', 'DE': 'Durchschnitt', 'RU': 'Среднее', 'AR': 'المتوسط', 'HI': 'औसत', 'VI': 'Trung bình', 'ES': 'Promedio', 'TH': 'ค่าเฉลี่ย'},
    'lifeBalance': {'KO': '종합 생활 균형', 'EN': 'Comprehensive Life Balance', 'JA': '総合生活バランス', 'ZH': '综合生活平衡', 'FR': 'Équilibre de vie global', 'DE': 'Ganzheitliche Lebensbalance', 'RU': 'Общий баланс жизни', 'AR': 'التوازن الشامل في الحياة', 'HI': 'समग्र जीवन संतुलन', 'VI': 'Cân bằng cuộc sống tổng thể', 'ES': 'Equilibrio integral de vida', 'TH': 'ความสมดุลชีวิตโดยรวม'},
    'lifeBalanceSub': {'KO': '(종합 생활 균형 밸런스 분석)', 'EN': '(Comprehensive life balance analysis)', 'JA': '（総合生活バランス分析）', 'ZH': '（综合生活平衡分析）', 'FR': '(Analyse de l\'équilibre de vie global)', 'DE': '(Analyse der ganzheitlichen Lebensbalance)', 'RU': '(Анализ общего баланса жизни)', 'AR': '(تحليل التوازن الشامل في الحياة)', 'HI': '(समग्र जीवन संतुलन विश्लेषण)', 'VI': '(Phân tích cân bằng cuộc sống tổng thể)', 'ES': '(Análisis del equilibrio integral de vida)', 'TH': '(การวิเคราะห์ความสมดุลชีวิตโดยรวม)'},
    'dbSyncTitle': {'KO': '데이터베이스 동기화 알림', 'EN': 'Database Sync Notification', 'JA': 'データベース同期通知', 'ZH': '数据库同步通知', 'FR': 'Notification de synchronisation', 'DE': 'Datenbank-Synchronisierung', 'RU': 'Уведомление о синхронизации', 'AR': 'إشعار مزامنة قاعدة البيانات', 'HI': 'डेटाबेस सिंक सूचना', 'VI': 'Thông báo đồng bộ dữ liệu', 'ES': 'Notificación de sincronización', 'TH': 'การแจ้งเตือนซิงค์ข้อมูล'},
    'dbSyncSub': {'KO': '(데이터를 안전하게 동기화 중입니다...)', 'EN': '(Synchronizing data storage safely...)', 'JA': '（データを安全に同期しています...）', 'ZH': '（正在安全同步数据...）', 'FR': '(Synchronisation sécurisée des données...)', 'DE': '(Daten werden sicher synchronisiert...)', 'RU': '(Безопасная синхронизация данных...)', 'AR': '(تتم مزامنة البيانات بأمان...)', 'HI': '(डेटा को सुरक्षित रूप से सिंक किया जा रहा है...)', 'VI': '(Đang đồng bộ dữ liệu an toàn...)', 'ES': '(Sincronizando datos de forma segura...)', 'TH': '(กำลังซิงค์ข้อมูลอย่างปลอดภัย...)'},
    'mockDiagTitle': {'KO': '모의고사 정밀 평가 진단', 'EN': 'Mock Exam Detailed Diagnosis', 'JA': '模試精密評価診断', 'ZH': '模拟考试精密诊断', 'FR': 'Diagnostic détaillé de l\'examen blanc', 'DE': 'Detaillierte Diagnose des Testexamens', 'RU': 'Подробная диагностика пробного экзамена', 'AR': 'تشخيص دقيق للاختبار التجريبي', 'HI': 'मॉक परीक्षा विस्तृत निदान', 'VI': 'Chẩn đoán chi tiết kỳ thi thử', 'ES': 'Diagnóstico detallado del examen simulado', 'TH': 'การวินิจฉัยเชิงลึกข้อสอบจำลอง'},
    'examDiagTitle': {'KO': '시험 성취도 세부 피드백 설정', 'EN': 'Exam Achievement Feedback Setup', 'JA': '試験成果詳細フィードバック設定', 'ZH': '考试成果详细反馈设置', 'FR': 'Configuration du retour détaillé sur l\'examen', 'DE': 'Detailliertes Feedback zur Prüfungsleistung', 'RU': 'Настройка подробной обратной связи по экзамену', 'AR': 'إعداد ملاحظات تفصيلية عن نتيجة الاختبار', 'HI': 'परीक्षा उपलब्धि विस्तृत फ़ीडबैक सेटअप', 'VI': 'Thiết lập phản hồi chi tiết về kết quả thi', 'ES': 'Configuración de retroalimentación detallada del examen', 'TH': 'ตั้งค่าฟีดแบ็กผลสอบแบบละเอียด'},
    'emptyFallbackShort': {'KO': '현재 해당 카테고리에 누적된 데이터셋이 식별되지 않아 기본 정성 분석을 수행합니다.\n\n학습자의 메타인지 상태는 평균치에 도달했으나 실전 정합성을 높이기 위한 개념 오답 관리가 요구됩니다. 용기를 잃지 말고 내일의 세션에 몰입하십시오.', 'EN': 'No accumulated dataset found for this category, so a general qualitative analysis is provided.\n\nThe learner\'s metacognitive state is average, but reviewing conceptual mistakes will help solidify readiness. Stay confident and stay focused for tomorrow\'s session.', 'JA': 'このカテゴリーには蓄積データが見つからないため、基本的な定性分析を行います。\n\n学習者のメタ認知状態は平均的ですが、実戦力を高めるには概念の誤答管理が必要です。勇気を失わず、明日のセッションに集中しましょう。', 'ZH': '该类别暂无累积数据，因此进行基础定性分析。\n\n学习者的元认知水平处于平均水平，但需要加强概念性错题管理以提升实战能力。请保持信心，专注于明天的学习。', 'FR': 'Aucune donnée cumulée n\'a été trouvée pour cette catégorie ; une analyse qualitative générale est donc fournie.\n\nLe niveau métacognitif de l\'apprenant est moyen, mais revoir les erreurs conceptuelles renforcera sa préparation. Restez confiant pour la prochaine session.', 'DE': 'Für diese Kategorie wurden keine gesammelten Daten gefunden, daher wird eine allgemeine qualitative Analyse bereitgestellt.\n\nDer metakognitive Zustand des Lernenden ist durchschnittlich, aber die Überprüfung konzeptioneller Fehler wird die Vorbereitung stärken. Bleiben Sie zuversichtlich für die nächste Sitzung.', 'RU': 'Накопленных данных по этой категории не найдено, поэтому предоставлен общий качественный анализ.\n\nМетакогнитивное состояние учащегося среднее, но разбор концептуальных ошибок поможет закрепить готовность. Сохраняйте уверенность перед следующим занятием.', 'AR': 'لم يتم العثور على بيانات متراكمة لهذه الفئة، لذا يتم تقديم تحليل نوعي عام.\n\nحالة الإدراك الفوقي للمتعلم متوسطة، ولكن مراجعة الأخطاء المفاهيمية ستعزز الاستعداد. حافظ على ثقتك وركز على الجلسة القادمة.', 'HI': 'इस श्रेणी के लिए कोई संचित डेटा नहीं मिला, इसलिए एक सामान्य गुणात्मक विश्लेषण प्रदान किया गया है।\n\nसीखने वाले की मेटाकॉग्निटिव स्थिति औसत है, लेकिन वैचारिक गलतियों की समीक्षा तैयारी को मजबूत करेगी। आत्मविश्वास बनाए रखें और आगामी सत्र पर ध्यान दें।', 'VI': 'Không tìm thấy dữ liệu tích lũy cho hạng mục này, vì vậy đây là phân tích định tính chung.\n\nTrạng thái nhận thức của người học ở mức trung bình, nhưng việc xem lại các lỗi khái niệm sẽ giúp cải thiện. Hãy giữ tự tin và tập trung cho buổi học tiếp theo.', 'ES': 'No se encontraron datos acumulados para esta categoría, por lo que se ofrece un análisis cualitativo general.\n\nEl estado metacognitivo del estudiante es promedio, pero revisar los errores conceptuales fortalecerá su preparación. Mantén la confianza para la próxima sesión.', 'TH': 'ไม่พบข้อมูลสะสมในหมวดนี้ จึงขอนำเสนอการวิเคราะห์เชิงคุณภาพทั่วไป\n\nสภาวะการรู้คิดของผู้เรียนอยู่ในระดับเฉลี่ย แต่การทบทวนข้อผิดพลาดด้านแนวคิดจะช่วยเสริมความพร้อม รักษาความมั่นใจและตั้งใจกับครั้งถัดไป'},
    'emptyFallbackLong': {'KO': '현재 해당 카테고리에 누적된 성적 메트릭이 식별되지 않아 기본 정성 분석을 수행합니다.\n\n학습자의 메타인지(자신의 인지 활동을 모니터링하고 조절하는 능력) 수준은 양호하나 과목 간 편차가 존재할 수 있습니다. 실전에서 흔들리지 않기 위해서는 개념 정합성 확인 프로세스를 고도화해야 합니다. 언제나 가능성이 열려있으니 포기하지 말고 전진합시다.', 'EN': 'No accumulated score metrics were found for this category, so a general qualitative analysis is provided.\n\nThe learner\'s metacognitive level appears sound, though gaps between subjects may exist. To stay steady under real test conditions, strengthen the concept-verification process. Possibility is always open — keep moving forward.', 'JA': 'このカテゴリーには蓄積された成績データが見つからないため、基本的な定性分析を行います。\n\n学習者のメタ認知（自身の認知活動を監視・調整する能力）は良好ですが、科目間の差が存在する可能性があります。実戦で動揺しないためには概念の整合性確認プロセスを高度化する必要があります。可能性は常に開かれているので、諦めずに前進しましょう。', 'ZH': '该类别暂无累积成绩数据，因此进行基础定性分析。\n\n学习者的元认知水平（监控和调节自身认知活动的能力）良好，但学科间可能存在差异。为了在实战中保持稳定，需要提升概念一致性确认流程。可能性始终存在，不要放弃，继续前进。', 'FR': 'Aucune métrique de score cumulée n\'a été trouvée pour cette catégorie ; une analyse qualitative générale est donc fournie.\n\nLe niveau métacognitif de l\'apprenant semble bon, bien que des écarts entre matières puissent exister. Pour rester stable en conditions réelles, il faut renforcer le processus de vérification des concepts. Les possibilités restent ouvertes — continuez d\'avancer.', 'DE': 'Für diese Kategorie wurden keine gesammelten Notenmetriken gefunden, daher wird eine allgemeine qualitative Analyse bereitgestellt.\n\nDas metakognitive Niveau des Lernenden erscheint solide, wobei Unterschiede zwischen Fächern bestehen können. Um unter realen Testbedingungen stabil zu bleiben, sollte der Konzeptüberprüfungsprozess gestärkt werden. Die Möglichkeit bleibt immer offen — bleiben Sie in Bewegung.', 'RU': 'Накопленных показателей успеваемости по этой категории не найдено, поэтому предоставлен общий качественный анализ.\n\nМетакогнитивный уровень учащегося выглядит хорошим, хотя между предметами могут быть расхождения. Чтобы сохранять устойчивость в реальных условиях, нужно усилить процесс проверки концепций. Возможность всегда открыта — продолжайте двигаться вперёд.', 'AR': 'لم يتم العثور على مقاييس درجات متراكمة لهذه الفئة، لذا يتم تقديم تحليل نوعي عام.\n\nيبدو مستوى الإدراك الفوقي للمتعلم جيدًا، على الرغم من احتمال وجود فجوات بين المواد. للحفاظ على الثبات في ظروف الاختبار الحقيقية، يجب تعزيز عملية التحقق من المفاهيم. الإمكانية مفتوحة دائمًا — استمر في التقدم.', 'HI': 'इस श्रेणी के लिए कोई संचित स्कोर मेट्रिक्स नहीं मिला, इसलिए एक सामान्य गुणात्मक विश्लेषण प्रदान किया गया है।\n\nसीखने वाले का मेटाकॉग्निटिव स्तर अच्छा प्रतीत होता है, हालांकि विषयों के बीच अंतर हो सकता है। वास्तविक परीक्षा स्थितियों में स्थिर रहने के लिए, अवधारणा-सत्यापन प्रक्रिया को मजबूत करें। संभावना हमेशा खुली है — आगे बढ़ते रहें।', 'VI': 'Không tìm thấy chỉ số điểm tích lũy cho hạng mục này, vì vậy đây là phân tích định tính chung.\n\nMức độ nhận thức của người học có vẻ tốt, dù có thể có sự chênh lệch giữa các môn. Để giữ ổn định trong điều kiện thi thực tế, cần củng cố quy trình xác minh khái niệm. Khả năng luôn rộng mở — hãy tiếp tục tiến lên.', 'ES': 'No se encontraron métricas de puntuación acumuladas para esta categoría, por lo que se ofrece un análisis cualitativo general.\n\nEl nivel metacognitivo del estudiante parece sólido, aunque puede haber diferencias entre materias. Para mantenerse estable en condiciones de examen real, fortalece el proceso de verificación de conceptos. La posibilidad siempre está abierta: sigue avanzando.', 'TH': 'ไม่พบข้อมูลคะแนนสะสมในหมวดนี้ จึงขอนำเสนอการวิเคราะห์เชิงคุณภาพทั่วไป\n\nระดับการรู้คิดของผู้เรียนดูเหมาะสมดี แม้อาจมีความแตกต่างระหว่างวิชา เพื่อรักษาความมั่นคงในสถานการณ์สอบจริง ควรเสริมกระบวนการตรวจสอบแนวคิดให้แข็งแกร่งขึ้น โอกาสเปิดกว้างเสมอ อย่าหยุดที่จะก้าวต่อไป'},
    'achievementWord': {'KO': '성취도', 'EN': 'Achievement', 'JA': '成果', 'ZH': '成就度', 'FR': 'Réussite', 'DE': 'Leistung', 'RU': 'Успеваемость', 'AR': 'التحصيل', 'HI': 'उपलब्धि', 'VI': 'Thành tích', 'ES': 'Logro', 'TH': 'ผลสัมฤทธิ์'},
    'highSchoolGrade2': {'KO': 'GKE 고등학교 2학년', 'EN': 'GKE High School, Grade 11', 'JA': 'GKE高校2年生', 'ZH': 'GKE高中二年级', 'FR': 'GKE Lycée, 2e année', 'DE': 'GKE Gymnasium, 2. Klasse', 'RU': 'GKE школа, 2 курс', 'AR': 'GKE الصف الثاني الثانوي', 'HI': 'GKE हाई स्कूल कक्षा 2', 'VI': 'GKE Cấp 3, lớp 11', 'ES': 'GKE Bachillerato, 2º año', 'TH': 'GKE มัธยมปลาย ปีที่ 2'},
    'recentFeedbackPrefix': {'KO': '[최근 작성]', 'EN': '[Recent]', 'JA': '[最近作成]', 'ZH': '[最近]', 'FR': '[Récent]', 'DE': '[Zuletzt]', 'RU': '[Недавнее]', 'AR': '[الأحدث]', 'HI': '[हाल का]', 'VI': '[Gần đây]', 'ES': '[Reciente]', 'TH': '[ล่าสุด]'},
    'achievementFeedbackMetrics': {'KO': '성취 피드백 메트릭스', 'EN': 'Achievement Feedback Metrics', 'JA': '成果フィードバック指標', 'ZH': '成果反馈指标', 'FR': 'Indicateurs de progression', 'DE': 'Leistungs-Feedback-Metriken', 'RU': 'Метрики обратной связи по успеваемости', 'AR': 'مؤشرات ملاحظات التحصيل', 'HI': 'उपलब्धि फ़ीडबैक मेट्रिक्स', 'VI': 'Chỉ số phản hồi thành tích', 'ES': 'Métricas de retroalimentación de logros', 'TH': 'ตัวชี้วัดฟีดแบ็กผลสัมฤทธิ์'},
    'targetSubjectLabel': {'KO': '타겟 과목', 'EN': 'Target', 'JA': '対象科目', 'ZH': '目标科目', 'FR': 'Matière ciblée', 'DE': 'Zielfach', 'RU': 'Целевой предмет', 'AR': 'المادة المستهدفة', 'HI': 'लक्ष्य विषय', 'VI': 'Môn mục tiêu', 'ES': 'Materia objetivo', 'TH': 'วิชาเป้าหมาย'},
    'scoreLabel': {'KO': '점수', 'EN': 'Score', 'JA': '点数', 'ZH': '分数', 'FR': 'Score', 'DE': 'Punktzahl', 'RU': 'Балл', 'AR': 'الدرجة', 'HI': 'स्कोर', 'VI': 'Điểm', 'ES': 'Puntuación', 'TH': 'คะแนน'},
    'viewAnalysisReport': {'KO': '분석 보고서 조회하기', 'EN': 'View Analysis Report', 'JA': '分析レポートを見る', 'ZH': '查看分析报告', 'FR': 'Voir le rapport d\'analyse', 'DE': 'Analysebericht ansehen', 'RU': 'Просмотреть отчёт анализа', 'AR': 'عرض تقرير التحليل', 'HI': 'विश्लेषण रिपोर्ट देखें', 'VI': 'Xem báo cáo phân tích', 'ES': 'Ver informe de análisis', 'TH': 'ดูรายงานการวิเคราะห์'},
    'entryAndHistory': {'KO': '입력 및 과거 선택 조회', 'EN': 'Entry & History', 'JA': '入力と履歴の確認', 'ZH': '输入与历史查看', 'FR': 'Saisie et historique', 'DE': 'Eingabe & Verlauf', 'RU': 'Ввод и история', 'AR': 'الإدخال والسجل', 'HI': 'प्रविष्टि और इतिहास', 'VI': 'Nhập liệu & lịch sử', 'ES': 'Entrada e historial', 'TH': 'บันทึกและประวัติ'},
    'summaryReportBody': {'KO': '[종합 리포트]\n\n자기주도 학습 1교시\n1번 학습일시: 2026-06-18 21:36 ~ 22:36 끝남 UTC\n2. 학습과목: 수학\n3. 학습시간: 72분 / 90분\n4. 목표달성률: 80%\n5. 별 갯수: ****(4/5)\n\n자기주도학습 2교시\n1번 학습일시:\n2026-06-18 21:36 ~ 22:36 끝남 UTC\n2. 학습과목: 영어\n3. 학습시간: 72분 / 90분\n4. 목표달성률: 80%\n5. 별 갯수: ****(4/5)\n\n[종합 진단 피드백]\n금일 진행된 이규현 회원의 학습 세션은 시간 관리와 핵심 문항 분석 면에서 고도의 진취성을 나타냈습니다. 계획된 90분의 집중 타임라인 중 실제 몰입 시간의 밀도가 높았으며, 과목 간 균형도 안정적입니다. 다만 학습 개시 단계에서 개념 정립에 소요되는 시간이 평균치보다 다소 길어지는 지체 현상이 관찰되었습니다. 이는 후반부 응용 문제 풀이의 정밀도를 저해하는 요인이 될 수 있으므로, 초기 몰입 속도를 제고하려는 의도적인 노력이 요구됩니다. 전반적인 과목 이해도는 상위권 진입에 무리가 없는 수준이나, 오답을 선별하고 피드백 리포트를 구성할 때 본인의 주관적 판단에만 의존하는 경향은 확실히 교정해야 할 지점입니다. 현재 유지하고 있는 연속 학습의 패턴은 장기적 성과 도출을 위한 훌륭한 기반이 되므로, 스스로의 역량을 확신하고 정진하기 바랍니다. 미진한 영역을 명확히 보완하여 내일의 학습 효율성을 한층 더 고도화할 수 있도록 냉철하게 관리해 나갈 것을 엄중히 제언합니다.', 'EN': '[Total Report]\n\nSelf-Directed Learning Session 1\n1. TIMESTAMP: 2026-06-18 21:36 ~ 22:36 End UTC\n2. SUBJECT: Math\n3. TIME: 72 Mins / 90 Mins\n4. ACHIEVEMENT RATE: 80%\n5. STARS: ****(4/5)\n\nSelf-Directed Learning Session 2\n1. TIMESTAMP:\n2026-06-18 21:36 ~ 22:36 End UTC\n2. SUBJECT: En\n3. TIME: 72 Mins / 90 Mins\n4. ACHIEVEMENT RATE: 80%\n5. STARS: ****(4/5)\n\nToday\'s learning sessions showed great progress. Keep moving forward toward your target with strong motivation.', 'JA': '[総合レポート]\n\n自己主導学習 第1時限\n1. 学習日時：2026-06-18 21:36〜22:36 終了 UTC\n2. 学習科目：数学\n3. 学習時間：72分／90分\n4. 目標達成率：80%\n5. 星の数：****(4/5)\n\n自己主導学習 第2時限\n1. 学習日時：\n2026-06-18 21:36〜22:36 終了 UTC\n2. 学習科目：英語\n3. 学習時間：72分／90分\n4. 目標達成率：80%\n5. 星の数：****(4/5)\n\n[総合診断フィードバック]\n本日のイ・ギュヒョン会員の学習セッションは時間管理と重要項目の分析において高い積極性を示しました。よく集中して取り組めていますが、概念整理に時間がかかる傾向が見られます。明日はより早く集中に入れるよう意識してみましょう。', 'ZH': '[综合报告]\n\n自主学习 第1节\n1. 学习时间：2026-06-18 21:36～22:36 结束 UTC\n2. 学习科目：数学\n3. 学习时长：72分钟／90分钟\n4. 目标达成率：80%\n5. 星星数量：****(4/5)\n\n自主学习 第2节\n1. 学习时间：\n2026-06-18 21:36～22:36 结束 UTC\n2. 学习科目：英语\n3. 学习时长：72分钟／90分钟\n4. 目标达成率：80%\n5. 星星数量：****(4/5)\n\n[综合诊断反馈]\n今日李圭贤会员的学习表现出较高的时间管理与重点分析能力。整体学习节奏稳定，但在概念梳理阶段耗时略长于平均水平。建议明天从一开始就加快进入专注状态。', 'FR': '[Rapport global]\n\nSession d\'apprentissage autonome 1\n1. HORODATAGE : 2026-06-18 21:36 ~ 22:36 Fin UTC\n2. MATIÈRE : Maths\n3. DURÉE : 72 min / 90 min\n4. TAUX DE RÉUSSITE : 80 %\n5. ÉTOILES : ****(4/5)\n\nSession d\'apprentissage autonome 2\n1. HORODATAGE :\n2026-06-18 21:36 ~ 22:36 Fin UTC\n2. MATIÈRE : Anglais\n3. DURÉE : 72 min / 90 min\n4. TAUX DE RÉUSSITE : 80 %\n5. ÉTOILES : ****(4/5)\n\n[Retour de diagnostic global]\nLa session d\'apprentissage de Lee Gyu-hyun d\'aujourd\'hui a montré une bonne gestion du temps et une analyse solide des points clés. Le rythme reste stable, mais la phase de mise en place des concepts prend un peu plus de temps que la moyenne. Essayez de démarrer plus rapidement demain.', 'DE': '[Gesamtbericht]\n\nSelbstgesteuerte Lerneinheit 1\n1. ZEITSTEMPEL: 2026-06-18 21:36 ~ 22:36 Ende UTC\n2. FACH: Mathe\n3. DAUER: 72 Min / 90 Min\n4. ERFOLGSQUOTE: 80 %\n5. STERNE: ****(4/5)\n\nSelbstgesteuerte Lerneinheit 2\n1. ZEITSTEMPEL:\n2026-06-18 21:36 ~ 22:36 Ende UTC\n2. FACH: Englisch\n3. DAUER: 72 Min / 90 Min\n4. ERFOLGSQUOTE: 80 %\n5. STERNE: ****(4/5)\n\n[Gesamtdiagnose-Feedback]\nDie heutige Lernsitzung von Lee Gyu-hyun zeigte gutes Zeitmanagement und eine solide Analyse der Kernpunkte. Das Tempo bleibt stabil, doch die Konzeptaufbauphase dauert etwas länger als der Durchschnitt. Morgen sollte der Fokus schneller aufgebaut werden.', 'RU': '[Общий отчёт]\n\nСамостоятельное занятие 1\n1. ВРЕМЯ: 2026-06-18 21:36 ~ 22:36 Завершено UTC\n2. ПРЕДМЕТ: Математика\n3. ВРЕМЯ ЗАНЯТИЯ: 72 мин / 90 мин\n4. ДОСТИЖЕНИЕ ЦЕЛИ: 80%\n5. ЗВЁЗДЫ: ****(4/5)\n\nСамостоятельное занятие 2\n1. ВРЕМЯ:\n2026-06-18 21:36 ~ 22:36 Завершено UTC\n2. ПРЕДМЕТ: Английский\n3. ВРЕМЯ ЗАНЯТИЯ: 72 мин / 90 мин\n4. ДОСТИЖЕНИЕ ЦЕЛИ: 80%\n5. ЗВЁЗДЫ: ****(4/5)\n\n[Общая диагностическая обратная связь]\nСегодняшнее занятие ученика Ли Гю Хёна показало хороший тайм-менеджмент и качественный анализ ключевых заданий. Темп остаётся стабильным, но этап усвоения понятий занимает немного больше времени, чем в среднем. Завтра стоит быстрее выходить на нужную концентрацию.', 'AR': '[التقرير الشامل]\n\nجلسة التعلم الذاتي 1\n1. الوقت: 2026-06-18 21:36 ~ 22:36 انتهى UTC\n2. المادة: رياضيات\n3. المدة: 72 دقيقة / 90 دقيقة\n4. نسبة تحقيق الهدف: 80٪\n5. النجوم: ****(4/5)\n\nجلسة التعلم الذاتي 2\n1. الوقت:\n2026-06-18 21:36 ~ 22:36 انتهى UTC\n2. المادة: إنجليزي\n3. المدة: 72 دقيقة / 90 دقيقة\n4. نسبة تحقيق الهدف: 80٪\n5. النجوم: ****(4/5)\n\n[ملاحظات التشخيص الشامل]\nأظهرت جلسة تعلم لي جيو-هيون اليوم إدارة جيدة للوقت وتحليلًا قويًا للنقاط الأساسية. الوتيرة مستقرة، لكن مرحلة بناء المفاهيم استغرقت وقتًا أطول قليلاً من المتوسط. يُنصح بالتركيز بشكل أسرع غدًا.', 'HI': '[समग्र रिपोर्ट]\n\nस्व-निर्देशित शिक्षण सत्र 1\n1. समय: 2026-06-18 21:36 ~ 22:36 समाप्त UTC\n2. विषय: गणित\n3. अवधि: 72 मिनट / 90 मिनट\n4. लक्ष्य प्राप्ति दर: 80%\n5. स्टार: ****(4/5)\n\nस्व-निर्देशित शिक्षण सत्र 2\n1. समय:\n2026-06-18 21:36 ~ 22:36 समाप्त UTC\n2. विषय: अंग्रेज़ी\n3. अवधि: 72 मिनट / 90 मिनट\n4. लक्ष्य प्राप्ति दर: 80%\n5. स्टार: ****(4/5)\n\n[समग्र निदान फ़ीडबैक]\nआज ली ग्यू-ह्युन के अध्ययन सत्र में समय प्रबंधन और मुख्य बिंदुओं का विश्लेषण अच्छा रहा। गति स्थिर है, लेकिन अवधारणा-निर्माण चरण में औसत से थोड़ा अधिक समय लगा। कल जल्दी ध्यान केंद्रित करने का प्रयास करें।', 'VI': '[Báo cáo tổng hợp]\n\nBuổi học tự định hướng 1\n1. THỜI GIAN: 2026-06-18 21:36 ~ 22:36 Kết thúc UTC\n2. MÔN HỌC: Toán\n3. THỜI LƯỢNG: 72 phút / 90 phút\n4. TỶ LỆ ĐẠT MỤC TIÊU: 80%\n5. SỐ SAO: ****(4/5)\n\nBuổi học tự định hướng 2\n1. THỜI GIAN:\n2026-06-18 21:36 ~ 22:36 Kết thúc UTC\n2. MÔN HỌC: Tiếng Anh\n3. THỜI LƯỢNG: 72 phút / 90 phút\n4. TỶ LỆ ĐẠT MỤC TIÊU: 80%\n5. SỐ SAO: ****(4/5)\n\n[Phản hồi chẩn đoán tổng hợp]\nBuổi học hôm nay của Lee Gyu-hyun cho thấy khả năng quản lý thời gian tốt và phân tích trọng điểm chắc chắn. Nhịp độ ổn định, nhưng giai đoạn xây dựng khái niệm mất nhiều thời gian hơn mức trung bình. Ngày mai nên tập trung nhanh hơn ngay từ đầu.', 'ES': '[Informe general]\n\nSesión de aprendizaje autónomo 1\n1. MARCA DE TIEMPO: 2026-06-18 21:36 ~ 22:36 Fin UTC\n2. MATERIA: Matemáticas\n3. DURACIÓN: 72 min / 90 min\n4. TASA DE LOGRO: 80%\n5. ESTRELLAS: ****(4/5)\n\nSesión de aprendizaje autónomo 2\n1. MARCA DE TIEMPO:\n2026-06-18 21:36 ~ 22:36 Fin UTC\n2. MATERIA: Inglés\n3. DURACIÓN: 72 min / 90 min\n4. TASA DE LOGRO: 80%\n5. ESTRELLAS: ****(4/5)\n\n[Retroalimentación de diagnóstico general]\nLa sesión de estudio de hoy de Lee Gyu-hyun mostró buena gestión del tiempo y un análisis sólido de los puntos clave. El ritmo se mantiene estable, aunque la fase de consolidación de conceptos tomó algo más de tiempo que el promedio. Se recomienda concentrarse más rápido desde el inicio de mañana.', 'TH': '[รายงานสรุป]\n\nช่วงเรียนด้วยตนเอง ครั้งที่ 1\n1. เวลา: 2026-06-18 21:36 ~ 22:36 สิ้นสุด UTC\n2. วิชา: คณิตศาสตร์\n3. ระยะเวลา: 72 นาที / 90 นาที\n4. อัตราการบรรลุเป้าหมาย: 80%\n5. จำนวนดาว: ****(4/5)\n\nช่วงเรียนด้วยตนเอง ครั้งที่ 2\n1. เวลา:\n2026-06-18 21:36 ~ 22:36 สิ้นสุด UTC\n2. วิชา: ภาษาอังกฤษ\n3. ระยะเวลา: 72 นาที / 90 นาที\n4. อัตราการบรรลุเป้าหมาย: 80%\n5. จำนวนดาว: ****(4/5)\n\n[ฟีดแบ็กการวินิจฉัยโดยรวม]\nช่วงเรียนของ Lee Gyu-hyun วันนี้แสดงถึงการจัดการเวลาที่ดีและการวิเคราะห์ประเด็นสำคัญที่มั่นคง จังหวะการเรียนคงที่ดี แต่ขั้นตอนปูพื้นแนวคิดใช้เวลานานกว่าค่าเฉลี่ยเล็กน้อย ควรตั้งใจโฟกัสให้เร็วขึ้นตั้งแต่เริ่มพรุ่งนี้'},
    'detailedReportBody': {'KO': '[상세분석기록]\n\n• 상세내용: 개념 및 심화,문제풀이 25문제\n• 오답노타: 정리함\n• 이 해 도: 80%\n• 난 이 도: 보통\n• 집중도: 높음\n• 학습컨디션: 좋음\n• 다음목표: 함수 심화문제\n\n[심층 교육 제언]\n차기 목표로 설정된 함수 심화 파트는 고도의 논리적 추론이 수반되는 영역이나, 현재 이규현 회원이 보여준 오답 정리 정밀도와 개념 분석력이라면 충분히 안정적으로 돌파해 낼 수 있습니다. 장래의 목표를 실현하기 위한 과정에서 마주하는 고난도 문항은 성장의 기회가 될 것입니다. 단, 난이도가 보통인 문항 스펙트럼에서도 실수가 일부 식별된 점은 자만을 경계하고 기초를 더 철저히 해야 한다는 경고입니다. 스스로의 가능성을 믿고 의욕적으로 도전하되 명밀하게 검토하는 태도를 기르십시오.', 'EN': '[Detailed Analytics]\n\n• DETAILS: Concepts & Problems, 25 issues\n• INCORRECT NOTE: COMPLETED\n• UNDERSTANDING: 80%\n• DIFFICULTY: Normal\n• CONCENTRATION: High\n• CONDITION: Good\n• NEXT GOAL: Advanced Function Problems\n\nYour potential is unlimited. Learn from your minor mistakes and focus deeper on the next advanced targets.', 'JA': '[詳細分析記録]\n\n• 詳細内容：概念と応用、25問を解答\n• 誤答ノート：整理済み\n• 理解度：80%\n• 難易度：普通\n• 集中度：高い\n• 学習状態：良好\n• 次の目標：関数の応用問題\n\n[深層教育アドバイス]\n次の目標である関数の応用パートは高度な論理的推論を要しますが、現在の誤答整理の精度と概念分析力があれば十分に突破できます。自信を持って挑戦しつつ、慎重に確認する姿勢を保ちましょう。', 'ZH': '[详细分析记录]\n\n• 详细内容：概念与拓展，共25题\n• 错题笔记：已整理\n• 理解度：80%\n• 难度：普通\n• 专注度：高\n• 学习状态：良好\n• 下一目标：函数拓展题\n\n[深度教育建议]\n下一目标——函数拓展部分需要较强的逻辑推理能力，但凭借目前的错题整理精度和概念分析力，完全可以稳步突破。请保持自信积极挑战，同时养成细致检查的习惯。', 'FR': '[Analyse détaillée]\n\n• DÉTAILS : Concepts et exercices, 25 problèmes\n• NOTE D\'ERREUR : TERMINÉ\n• COMPRÉHENSION : 80 %\n• DIFFICULTÉ : Normale\n• CONCENTRATION : Élevée\n• ÉTAT : Bon\n• PROCHAIN OBJECTIF : Problèmes de fonctions avancés\n\nVotre potentiel est illimité. Apprenez de vos petites erreurs et concentrez-vous davantage sur les prochains objectifs avancés.', 'DE': '[Detaillierte Analyse]\n\n• DETAILS: Konzepte & Übungen, 25 Aufgaben\n• FEHLERNOTIZ: ERLEDIGT\n• VERSTÄNDNIS: 80 %\n• SCHWIERIGKEIT: Normal\n• KONZENTRATION: Hoch\n• ZUSTAND: Gut\n• NÄCHSTES ZIEL: Fortgeschrittene Funktionsaufgaben\n\nIhr Potenzial ist unbegrenzt. Lernen Sie aus kleinen Fehlern und konzentrieren Sie sich stärker auf die nächsten fortgeschrittenen Ziele.', 'RU': '[Подробная аналитика]\n\n• ДЕТАЛИ: Концепции и задачи, 25 заданий\n• ЗАМЕТКА ОБ ОШИБКАХ: ЗАВЕРШЕНО\n• ПОНИМАНИЕ: 80%\n• СЛОЖНОСТЬ: Средняя\n• КОНЦЕНТРАЦИЯ: Высокая\n• СОСТОЯНИЕ: Хорошее\n• СЛЕДУЮЩАЯ ЦЕЛЬ: Продвинутые задачи по функциям\n\nВаш потенциал безграничен. Учитесь на небольших ошибках и глубже сосредоточьтесь на следующих продвинутых целях.', 'AR': '[تحليل تفصيلي]\n\n• التفاصيل: مفاهيم وتطبيقات، 25 مسألة\n• ملاحظة الأخطاء: مكتمل\n• الفهم: 80٪\n• الصعوبة: متوسطة\n• التركيز: مرتفع\n• الحالة: جيدة\n• الهدف التالي: مسائل الدوال المتقدمة\n\nإمكاناتك غير محدودة. تعلّم من أخطائك الصغيرة وركّز بعمق أكبر على الأهداف المتقدمة القادمة.', 'HI': '[विस्तृत विश्लेषण]\n\n• विवरण: अवधारणाएं और अभ्यास, 25 प्रश्न\n• त्रुटि नोट: पूर्ण\n• समझ: 80%\n• कठिनाई: सामान्य\n• एकाग्रता: उच्च\n• स्थिति: अच्छी\n• अगला लक्ष्य: उन्नत फलन प्रश्न\n\nआपकी क्षमता असीम है। छोटी गलतियों से सीखें और आगामी उन्नत लक्ष्यों पर अधिक गहराई से ध्यान दें।', 'VI': '[Phân tích chi tiết]\n\n• CHI TIẾT: Khái niệm và bài tập, 25 câu\n• GHI CHÚ LỖI: ĐÃ HOÀN THÀNH\n• MỨC HIỂU: 80%\n• ĐỘ KHÓ: Trung bình\n• TẬP TRUNG: Cao\n• TRẠNG THÁI: Tốt\n• MỤC TIÊU TIẾP THEO: Bài tập hàm số nâng cao\n\nTiềm năng của bạn là vô hạn. Hãy học từ những lỗi nhỏ và tập trung sâu hơn vào các mục tiêu nâng cao tiếp theo.', 'ES': '[Análisis detallado]\n\n• DETALLES: Conceptos y ejercicios, 25 problemas\n• NOTA DE ERRORES: COMPLETADO\n• COMPRENSIÓN: 80%\n• DIFICULTAD: Normal\n• CONCENTRACIÓN: Alta\n• CONDICIÓN: Buena\n• PRÓXIMO OBJETIVO: Problemas avanzados de funciones\n\nTu potencial es ilimitado. Aprende de tus pequeños errores y concéntrate más en los próximos objetivos avanzados.', 'TH': '[บันทึกวิเคราะห์เชิงลึก]\n\n• รายละเอียด: แนวคิดและโจทย์เชิงลึก 25 ข้อ\n• บันทึกข้อผิดพลาด: เรียบร้อยแล้ว\n• ความเข้าใจ: 80%\n• ความยาก: ปานกลาง\n• สมาธิ: สูง\n• สภาพการเรียน: ดี\n• เป้าหมายถัดไป: โจทย์ฟังก์ชันขั้นสูง\n\nศักยภาพของคุณไม่มีขีดจำกัด เรียนรู้จากข้อผิดพลาดเล็กๆ และตั้งใจกับเป้าหมายขั้นสูงถัดไปให้มากขึ้น'},
  };

  static String _t(String key) {
    final map = _uiText[key];
    if (map == null) return key;
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? key;
  }

  // 🆕 [데이터 연결-버그 수정] 그래프 함수(_buildAdvancedChartDashboard)는 절대 손대지 않고,
  // 이 getter가 반환하는 "데이터 소스"만 실제 기록 기반으로 교체합니다.
  // (그래프 내부는 그대로 이 리스트를 baseMinutes × 기간별 배수로 계산하는 기존 로직을 그대로 사용함)
  List<Map<String, dynamic>> get _masterSubjectData => _realSubjectStudyData;

  // 🆕 [데이터 연결] timer_screen.dart가 세션마다 저장하는 'dke_history_{과목명}' 실제 기록을
  // 모든 과목에 대해 훑어서(SharedPreferences.getKeys() 사용, 과목명을 미리 알 필요 없음) 집계합니다.
  // - hasStudiedToday/Weekly/Monthly/Yearly: 실제 그 기간에 학습한 적이 있는지 여부(정확함)
  // - baseMinutes: "과목당 실제로 공부한 날의 평균 학습분(分)" — 그래프 함수가 이 값에 기간별 배수를
  //   곱해서 주/월/연을 추정하는 기존 구조이기 때문에, "오늘 0분이라도 이번 주엔 공부했다"가
  //   반영되도록 평균값을 사용합니다. (그래프 함수 자체의 배수 로직은 이번에 손대지 않았습니다)
  Future<void> _loadRealSubjectStudyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Set<String> allKeys = prefs.getKeys();
      final Iterable<String> historyKeys = allKeys.where((k) => k.startsWith('dke_history_'));

      final DateTime now = DateTime.now();
      final DateTime todayStart = DateTime(now.year, now.month, now.day);
      final DateTime yesterdayStart = todayStart.subtract(const Duration(days: 1));
      final DateTime weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
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

        bool studiedToday = false, studiedWeekly = false, studiedMonthly = false, studiedYearly = false;
        int totalMinutesAllTime = 0;
        int subjectTodayMinutes = 0; // 🆕 이 과목의 오늘 학습분
        int subjectYesterdayMinutes = 0; // 🆕 이 과목의 어제 학습분
        final Set<String> activeDayKeys = {};
        double latestScoreRatio = 0.0;
        DateTime? latestTimestamp;

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

        if (!(studiedToday || studiedWeekly || studiedMonthly || studiedYearly)) continue;

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
        final int avgMinutesPerActiveDay = (totalMinutesAllTime / activeDays).round();

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
    final int pct = ((_todayTotalStudyMinutes / _dynamicDailyGoalMinutes) * 100).round();
    return pct.clamp(0, 100);
  }

  // 🆕 어제 대비 오늘 증감(%) = (오늘 - 어제) / 어제 × 100. 어제 기록이 없으면(0분) 오늘 학습한 만큼 +100%로 표시.
  int get _realTodayVsYesterdayPercent {
    if (_yesterdayTotalStudyMinutes <= 0) {
      return _todayTotalStudyMinutes > 0 ? 100 : 0;
    }
    return (((_todayTotalStudyMinutes - _yesterdayTotalStudyMinutes) / _yesterdayTotalStudyMinutes) * 100).round();
  }

  // 🆕 [데이터 연결] 가장 많이 학습한 과목(전체 기간 누적 분 기준) - "가장 많이 학습한 과목" 표시용
  // 🆕 [요청] 서버가 아직 없어서 비교 대상이 나 혼자뿐이므로, 지금은 항상 1위로 표시.
  // 추후 서버(다른 유저 데이터베이스)가 연결되면 이 두 게터 안의 로직만 실제 순위 계산으로 교체하면
  // 화면 쪽은 손댈 필요 없이 자동으로 실제 순위가 반영됨.
  String get _realFriendRankDisplay {
    // TODO(서버 연결 시): 친구 목록 중 학습 별/시간 기준 실제 순위 계산으로 교체
    return "1위";
  }

  String get _realGlobalRankDisplay {
    // TODO(서버 연결 시): 전체 유저 중 실제 퍼센타일 계산으로 교체
    return "1위";
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
      final Iterable<String> historyKeys = allKeys.where((k) => k.startsWith('dke_history_'));

      final Map<String, int> minutesByDay = {};
      final Map<String, DateTime> dateByDayKey = {};

      for (final key in historyKeys) {
        final List<String>? entries = prefs.getStringList(key);
        if (entries == null) continue;
        for (final raw in entries) {
          try {
            final Map<String, dynamic> item = jsonDecode(raw);
            final DateTime ts = DateTime.tryParse(item['timestamp']?.toString() ?? '')?.toLocal() ?? DateTime.now();
            final int durationSeconds = (item['durationSeconds'] as num?)?.toInt() ?? 0;
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

      list.sort((a, b) => (a["date"] as DateTime).compareTo(b["date"] as DateTime));

      // 최근(=날짜가 가장 늦은) 15개까지만 유지 - 오늘이 마지막(맨 오른쪽) 항목이 됨
      final List<Map<String, dynamic>> last15 = list.length > 15 ? list.sublist(list.length - 15) : list;

      if (!mounted) return;
      setState(() {
        _dailyTotalHistory = last15;
      });

      // 🆕 오늘 날짜가 항상 화면 맨 오른쪽에 보이도록, 로딩 후 스크롤을 맨 끝으로 자동 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_dailyTotalScrollController.hasClients) {
          _dailyTotalScrollController.jumpTo(_dailyTotalScrollController.position.maxScrollExtent);
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
  Set<String> _inputBigUnits = {"대단원 1"}; // 🆕 [요청] 대단원도 중단원과 동일하게 다중선택(범위) 가능하도록 전환
  Set<String> _inputMidUnits = {"중단원 1"}; // 🆕 [버그 수정] 중단원 여러 개(범위) 선택 가능하도록 단일값→집합으로 전환
  String _inputSemesterGroup = "1학기";

  _ExamRecord? _lastSavedRecordForDisplay;

  // 🆕 [6번] 서버(클라우드) 저장소 재조회 스로틀링용 마지막 동기화 시각
  DateTime? _lastRemoteSyncAt;
  static const Duration _remoteSyncInterval = Duration(hours: 1);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() { if (!_tabController.indexIsChanging) setState(() {}); });
    _warningAnimController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)..repeat(reverse: true);
    _warningAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(CurvedAnimation(parent: _warningAnimController, curve: Curves.easeInOut));

    _syncTimerSharedDataPackets();
    _loadExamRecords(); // 🆕 [데이터 연결] 가상 데이터 대신 실제 저장된 성적 기록을 불러옴
    _loadRealTargetUniversity(); // 🆕 [데이터 연결] 마이페이지에서 저장한 실제 목표 대학 불러옴
    _loadStarsAndLevel(); // 🆕 [데이터 연결] 가상 레벨/별 대신 star_economy.dart의 실제 누적치를 불러옴
    _loadRealSubjectStudyData(); // 🆕 [데이터 연결] 가상 8과목 그래프 대신 실제 학습기록을 집계해서 불러옴
    _loadDailyTotalHistory(); // 🆕 [데이터 연결] 일일 전체 학습시간(가로스크롤) 그래프용 데이터 로드
    _loadRealUserName(); // 🆕 [데이터 연결 2026-07-29] 실제 가입자 이름 불러옴
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
            loaded.add(_ExamRecord.fromJson(Map<String, dynamic>.from(e as Map)));
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
      final String encoded = jsonEncode(_allRecords.map((r) => r.toJson()).toList());
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
        _realTargetUniversity = (saved != null && saved.isNotEmpty) ? saved : null;
      });
    } catch (e) {
      debugPrint("[MemberAchievement] 목표 대학 불러오기 실패: $e");
    }
  }

  List<_ExamRecord> _getFilteredRecords(String type) {
    return _allRecords.where((rec) {
      bool baseMatch = rec.type == type
          && rec.grade == _filterGrade
          && rec.semester == _filterSemester;

      if (type == "주평가") {
        return baseMatch && rec.unit.contains(_inputYear) && rec.unit.contains(_inputMonth) && rec.unit.contains(_inputWeek);
      } else if (type == "단원평가") {
        return baseMatch && _inputBigUnits.any((bu) => rec.unit.contains(bu)) && _inputMidUnits.any((mu) => rec.unit.contains(mu));
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
        _timerDurationMinutes = tempSeconds != null ? (tempSeconds ~/ 60 == 0 ? 72 : tempSeconds ~/ 60) : 72;
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
    final String seenKey = 'dke_diagnosis_seen_${personKey}_${lang}_${type}_$bucket';

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
    final String generated = _buildRuleBasedDiagnosisText(type: type, score: score, subject: subject);
    library.add(generated);
    await prefs.setStringList(libraryKey, library);
    seenIndices.add('${library.length - 1}');
    await prefs.setStringList(seenKey, seenIndices);
    return generated;
  }

  // 🆕 [12개국 확장] 진단 문단 뱅크: 한국어/영어는 기존 2개 버전 유지, 나머지 10개 언어는 1개 버전
  static const Map<String, Map<String, List<String>>> _diagOpenings = {
    'good': {'KO': ['이번 평가에서 90점 이상의 우수한 고득점을 기록한 것은 학습자의 숨겨진 잠재력이 마침내 표면 위로 발현되기 시작했음을 증명하는 매우 기쁜 소식입니다. ', '이번에 달성한 높은 성적은 그동안 묵묵히 쌓아온 학습의 밀도가 드디어 가시적인 성과로 도출되었음을 시사하는 대단히 고무적인 결과물입니다. '], 'EN': ['Scoring above 90 on this evaluation is wonderful news — it shows the learner\'s hidden potential is finally surfacing. ', 'This high score signals that the quiet, steady effort invested until now has finally produced a clearly visible result. '], 'JA': ['今回90点以上の優秀な高得点を記録したことは、学習者の隠れた潜在力がついに表面化し始めたことを示す非常に嬉しい知らせです。'], 'ZH': ['本次评估取得90分以上的优异成绩，说明学习者潜藏的实力终于开始显现，这是非常令人欣喜的结果。'], 'FR': ['Obtenir plus de 90 points à cette évaluation est une excellente nouvelle : le potentiel caché de l\'apprenant commence enfin à se révéler.'], 'DE': ['Eine Punktzahl von über 90 bei dieser Bewertung ist eine großartige Nachricht — das verborgene Potenzial des Lernenden zeigt sich endlich.'], 'RU': ['Результат выше 90 баллов на этой оценке — прекрасная новость: скрытый потенциал ученика наконец начал проявляться.'], 'AR': ['الحصول على أكثر من 90 درجة في هذا التقييم خبر رائع يدل على أن الإمكانات الكامنة لدى المتعلم بدأت تظهر أخيرًا.'], 'HI': ['इस मूल्यांकन में 90 से अधिक अंक प्राप्त करना बहुत अच्छी खबर है — यह दिखाता है कि सीखने वाले की छिपी क्षमता आखिरकार सामने आने लगी है।'], 'VI': ['Đạt trên 90 điểm trong lần đánh giá này là tin rất đáng mừng — tiềm năng tiềm ẩn của người học cuối cùng đã bắt đầu bộc lộ.'], 'ES': ['Obtener más de 90 puntos en esta evaluación es una excelente noticia: el potencial oculto del estudiante finalmente está saliendo a la luz.'], 'TH': ['การได้คะแนนมากกว่า 90 ในการประเมินครั้งนี้เป็นข่าวดีมาก แสดงว่าศักยภาพที่ซ่อนอยู่ของผู้เรียนเริ่มปรากฏออกมาแล้ว']},
    'mid': {'KO': ['현재 도달한 성취도의 위치는 조금만 더 정밀하게 메타인지(자신의 인지 활동을 모니터링하고 조절하는 능력)를 조율하면 언제든 만점까지 단숨에 바라볼 수 있는 고지가 바로 눈앞에 와 있는 단계입니다. ', '이번에 확보한 상위권 점수는 안정적인 성장을 의미하지만, 동시에 조금의 임계점만 넘어서면 언제든 최상위권의 벽을 깨부수고 만점으로 직행할 수 있는 가장 중요한 기로의 점수대입니다. '], 'EN': ['This score sits right at the doorstep of a perfect score — a little sharper metacognitive tuning is all that stands between here and the top. ', 'This upper-tier score reflects steady growth, but it also sits at the exact tipping point where one more push could break straight through to the very top. '], 'JA': ['現在到達した成績のポジションは、もう少し精密にメタ認知（自身の認知活動を監視・調整する能力）を調整すれば、いつでも満点を視野に入れられる段階です。'], 'ZH': ['目前所处的成绩位置，只要再稍微精细地调节元认知（监控并调节自身认知活动的能力），随时都有望冲击满分。'], 'FR': ['Le niveau actuel n\'est qu\'à un pas d\'un score parfait — un réglage plus fin de la métacognition suffirait pour franchir le cap.'], 'DE': ['Das aktuelle Niveau liegt direkt vor der Bestnote — eine feinere metakognitive Justierung genügt, um den letzten Schritt zu schaffen.'], 'RU': ['Текущий уровень находится буквально на пороге максимального балла — небольшая настройка метапознания способна привести к вершине.'], 'AR': ['المستوى الحالي يقترب كثيرًا من الدرجة الكاملة — يكفي ضبط أدق للإدراك الفوقي للوصول إلى القمة في أي وقت.'], 'HI': ['वर्तमान स्कोर पूर्ण अंकों की दहलीज पर है — थोड़ा और सटीक मेटाकॉग्निटिव समायोजन शिखर तक पहुंचा सकता है।'], 'VI': ['Vị trí điểm số hiện tại đã rất gần điểm tuyệt đối — chỉ cần điều chỉnh nhận thức tinh tế hơn một chút là có thể vươn tới đỉnh cao.'], 'ES': ['El nivel actual está a un paso del puntaje perfecto: un ajuste metacognitivo más preciso podría llevarte a la cima en cualquier momento.'], 'TH': ['ตำแหน่งคะแนนตอนนี้อยู่ใกล้คะแนนเต็มมาก เพียงปรับกระบวนการรู้คิดให้ละเอียดขึ้นอีกนิดก็สามารถไปถึงจุดสูงสุดได้ทุกเมื่อ']},
    'seventy': {'KO': ['이번 평가에서 기록한 70점대의 수치는 학습자가 현재 지닌 역량에 비해 다소 아쉬운 결과이며, 현재의 약점을 방치할 경우 아래 점수대로 내려갈 수 있는 경계선에 있습니다. ', '현재 포지션은 탄탄한 도약이냐 지체냐를 결정짓는 중대한 기로입니다. 구조적 점검이 신속하게 이루어지지 않는다면 다음 평가에서 예상치 못한 하락세를 맞이할 위험이 공존합니다. '], 'EN': ['This 70s-range score falls a bit short of the learner\'s real ability, and leaving current weak points unaddressed risks a slide into the lower range. ', 'This is a genuine fork in the road between a strong leap forward and stagnation. Without a quick structural check, an unexpected drop could show up on the next evaluation. '], 'JA': ['今回の評価で記録された70点台の数値は、学習者が現在持つ実力に比べてやや惜しい結果であり、現在の弱点を放置すればさらに下の点数帯に落ちる可能性がある境界線にあります。'], 'ZH': ['本次评估记录的70分段成绩，相较于学习者当前实际具备的能力略显可惜，若放任目前的弱点不管，很可能滑向更低的分数段。'], 'FR': ['Ce score dans les 70 est un peu en deçà du véritable niveau de l\'apprenant, et ignorer les faiblesses actuelles risque de faire chuter encore le résultat.'], 'DE': ['Dieses Ergebnis im 70er-Bereich liegt etwas unter dem tatsächlichen Können des Lernenden, und wenn die aktuellen Schwächen ignoriert werden, droht ein weiterer Abstieg.'], 'RU': ['Результат в диапазоне 70 баллов немного не дотягивает до реального уровня ученика, и если не устранить текущие слабости, есть риск дальнейшего снижения.'], 'AR': ['هذه النتيجة في السبعينيات أقل قليلاً من القدرة الحقيقية للمتعلم، وإهمال نقاط الضعف الحالية قد يؤدي إلى مزيد من التراجع.'], 'HI': ['70 के दशक का यह स्कोर सीखने वाले की वास्तविक क्षमता से थोड़ा कम है, और वर्तमान कमजोरियों को नज़रअंदाज़ करने से स्कोर और गिर सकता है।'], 'VI': ['Điểm số trong khoảng 70 này thấp hơn một chút so với năng lực thực sự của người học, và nếu bỏ qua điểm yếu hiện tại, điểm số có thể tiếp tục giảm.'], 'ES': ['Este puntaje en el rango de los 70 queda un poco por debajo de la capacidad real del estudiante, y si se ignoran las debilidades actuales, podría bajar aún más.'], 'TH': ['คะแนนช่วง 70 นี้ต่ำกว่าความสามารถที่แท้จริงของผู้เรียนเล็กน้อย และหากปล่อยจุดอ่อนปัจจุบันไว้ อาจทำให้คะแนนลดลงไปอีก']},
    'sixty': {'KO': ['현재 누적된 60점대의 성취도는 교과 개념의 정착 단계에서 예상보다 깊은 균열이 발생했음을 나타내며, 신속히 반등의 불씨를 지피지 않으면 하락세를 멈추기 어려운 주의 단계입니다. ', '현재 점수대는 냉정하게 직시했을 때 하위권으로 정착할 것인가, 혹은 상위권으로 치고 올라갈 것인가를 가르는 매우 엄중한 인지적 기로에 서 있음을 뜻합니다. '], 'EN': ['A score in the 60s points to a deeper-than-expected crack in the foundation, and without acting quickly, the downward trend will be hard to stop. ', 'Looking at this honestly, this score sits right at the fork between settling into the lower tier or fighting back up toward the top. '], 'JA': ['現在累積された60点台の成績は、教科概念の定着段階で予想より深い亀裂が生じたことを示しており、迅速に反騰の火種を灯さなければ下降を止めにくい注意段階です。'], 'ZH': ['目前累积的60分段成绩，说明在学科概念巩固阶段出现了比预期更深的裂痕，若不尽快点燃反弹的契机，下滑趋势将很难止住，需引起重视。'], 'FR': ['Ce score dans les 60 révèle une fissure plus profonde que prévu dans la consolidation des concepts ; sans réaction rapide, la baisse sera difficile à enrayer.'], 'DE': ['Diese Punktzahl im 60er-Bereich zeigt einen tieferen Riss in der Konzeptfestigung als erwartet; ohne schnelles Gegensteuern wird der Abwärtstrend schwer zu stoppen sein.'], 'RU': ['Результат в диапазоне 60 баллов указывает на более глубокий разрыв в закреплении понятий, чем ожидалось; без быстрой реакции остановить спад будет трудно.'], 'AR': ['هذه النتيجة في الستينيات تكشف عن فجوة أعمق من المتوقع في ترسيخ المفاهيم؛ وبدون تحرك سريع، سيصعب وقف التراجع.'], 'HI': ['60 के दशक का यह स्कोर अवधारणा सुदृढ़ीकरण में अपेक्षा से अधिक गहरी दरार दिखाता है; तेज़ी से कार्रवाई किए बिना गिरावट को रोकना मुश्किल होगा।'], 'VI': ['Điểm số trong khoảng 60 này cho thấy một vết nứt sâu hơn dự kiến trong việc củng cố khái niệm; nếu không hành động nhanh, xu hướng giảm sẽ khó ngăn lại.'], 'ES': ['Este puntaje en el rango de los 60 revela una grieta más profunda de lo esperado en la consolidación de conceptos; sin actuar rápido, será difícil detener la caída.'], 'TH': ['คะแนนช่วง 60 นี้แสดงถึงรอยร้าวในการปูพื้นฐานแนวคิดที่ลึกกว่าที่คาดไว้ หากไม่รีบดำเนินการ แนวโน้มขาลงจะหยุดได้ยาก']},
    'low': {'KO': ['현재 기록된 평가 수치는 기초 개념 정착 단계에서 전반적인 재조정과 보완이 시급함을 가리키는 엄중한 진단서입니다. ', '현재의 지표는 학습 프로세스 전체에 걸쳐 개념적 누수가 누적되었음을 경고하고 있으며, 즉각적인 학습 루틴의 전면적인 개혁이 필요한 순간입니다. '], 'EN': ['This score is a serious signal that the foundational concepts need a full reset and reinforcement. ', 'This result warns that conceptual gaps have accumulated across the whole learning process, and the study routine needs an immediate, full overhaul. '], 'JA': ['現在記録された評価数値は、基礎概念の定着段階で全般的な再調整と補完が急がれることを示す厳重な診断書です。'], 'ZH': ['当前记录的评估结果，是一份严肃的诊断书，表明在基础概念巩固阶段亟需全面调整与补强。'], 'FR': ['Ce résultat est un signal sérieux indiquant qu\'un réajustement complet des concepts fondamentaux est nécessaire de toute urgence.'], 'DE': ['Dieses Ergebnis ist ein ernstes Signal dafür, dass eine umfassende Neuausrichtung der Grundkonzepte dringend erforderlich ist.'], 'RU': ['Этот результат — серьёзный сигнал о том, что необходима срочная и всесторонняя перестройка базовых понятий.'], 'AR': ['هذه النتيجة إشارة جادة إلى ضرورة إعادة ضبط شاملة وعاجلة للمفاهيم الأساسية.'], 'HI': ['यह स्कोर एक गंभीर संकेत है कि बुनियादी अवधारणाओं में तत्काल और व्यापक पुनर्समायोजन आवश्यक है।'], 'VI': ['Kết quả này là tín hiệu nghiêm túc cho thấy cần điều chỉnh và củng cố toàn diện các khái niệm nền tảng ngay lập tức.'], 'ES': ['Este resultado es una señal seria de que se necesita un reajuste integral y urgente de los conceptos fundamentales.'], 'TH': ['ผลคะแนนนี้เป็นสัญญาณที่ต้องให้ความสำคัญว่าจำเป็นต้องปรับพื้นฐานแนวคิดใหม่อย่างเร่งด่วนและครอบคลุม']},
  };

  static const Map<String, Map<String, List<String>>> _diagClosings = {
    'good': {'KO': ['그러나 현재의 기초 체급을 고려할 때, 이번 결과에 취해 단 한순간이라도 안일해지는 즉시 성적은 하락세로 돌아설 수 있습니다. 진정한 만점자로 안착하기 위해서는 실전에서 발생한 미세한 균열을 메워야 하므로, 틀린 문제는 반드시 누적 오답정리(틀린 원인을 기록하고 분석하는 과정)를 완수하고 최소 3번 이상 반복하여 완전히 본인의 것으로 만드는 철저한 회독 습관을 기르십시오. 자만하지 않고 이 정합성 확인 루틴을 성실히 유지한다면, 다음 실전에서도 흔들리지 않는 진짜 탑클래스로 우뚝 설 것입니다.', '다만 지금의 위치에서 방심하여 루틴이 느슨해진다면 차기 평가에서는 아쉬운 결과를 맛보게 될 수 있습니다. 완전무결한 성취를 지속하기 위해서는 취약 문항의 누적 오답정리(틀린 원인을 기록하고 분석하는 과정)를 철저히 이행하고, 오답을 3번 이상 재차 정밀 분석하여 풀어내는 훈련이 필수적입니다. 나태함을 경계하고 메타인지 루틴을 사수하여 흔들림 없는 정점에 도달하십시오.'], 'EN': ['That said, given the current foundation, even a moment of complacency could send the score back down. To truly lock in top-tier status, log every mistake in an error journal, review it at least three times, and make it fully your own. Keep this consistency routine honest and unshaken results in the next real test will follow.', 'Be careful not to let the routine loosen just because of this win — a lapse now could mean a disappointing result next time. Keep logging and re-analyzing every weak item at least three times. Guard against complacency and protect your metacognitive routine to reach an unshakeable peak.'], 'JA': ['ただし現在の基礎レベルを考えると、この結果に浮かれて一瞬でも油断すればすぐに成績は下降する可能性があります。真のトップクラスとして定着するためには、間違えた問題は必ず誤答ノート（間違えた原因を記録・分析する過程）を完成させ、最低3回以上繰り返して完全に自分のものにする徹底した復習習慣を身につけてください。慢心せずこの整合性確認ルーティンを誠実に維持すれば、次の実戦でも揺るがない本物のトップクラスとして立つでしょう。'], 'ZH': ['不过考虑到目前的基础水平，若因这次结果而有片刻松懈，成绩很可能立刻出现下滑。要真正稳居顶尖水平，必须将错题整理（记录并分析出错原因的过程）坚持完成，并至少反复复习三次以上，使其完全内化为自己的知识。只要不骄傲自满、认真维持这一巩固流程，下次实战中也能稳如泰山地站在真正的顶尖行列。'], 'FR': ['Cependant, compte tenu du niveau actuel des bases, le moindre relâchement pourrait faire chuter les résultats. Pour consolider durablement ce niveau, notez chaque erreur dans un journal, révisez-la au moins trois fois et faites-en une habitude rigoureuse. En maintenant cette routine avec sérieux, vous resterez stable au sommet lors de la prochaine évaluation.'], 'DE': ['Angesichts der aktuellen Grundlagen könnte jedoch schon ein Moment der Nachlässigkeit die Note wieder sinken lassen. Um wirklich an der Spitze zu bleiben, sollten Sie jeden Fehler in einem Fehlerprotokoll festhalten, mindestens dreimal wiederholen und vollständig verinnerlichen. Bleiben Sie diszipliniert bei dieser Routine, um auch beim nächsten Test stabil an der Spitze zu stehen.'], 'RU': ['Однако, учитывая текущий уровень базы, малейшее самодовольство может привести к падению результатов. Чтобы закрепиться на вершине, обязательно фиксируйте каждую ошибку в журнале ошибок, повторяйте её минимум три раза и полностью усваивайте. Сохраняя эту дисциплину, вы останетесь уверенно на вершине и в следующий раз.'], 'AR': ['لكن نظرًا للمستوى الأساسي الحالي، فإن أي تراخٍ ولو للحظة قد يؤدي إلى تراجع النتيجة. للحفاظ على مكانتك في القمة، سجّل كل خطأ في دفتر الأخطاء وراجعه ثلاث مرات على الأقل حتى تتقنه تمامًا. حافظ على هذا الروتين بجدية لتبقى ثابتًا في القمة في الاختبار القادم أيضًا.'], 'HI': ['लेकिन वर्तमान आधार स्तर को देखते हुए, इस परिणाम से एक पल के लिए भी लापरवाह होना स्कोर को नीचे ला सकता है। शीर्ष स्तर पर स्थिर रहने के लिए, हर गलती को एक त्रुटि पत्रिका में दर्ज करें, कम से कम तीन बार दोहराएं और उसे पूरी तरह आत्मसात करें। इस अनुशासन को बनाए रखें ताकि अगली बार भी शीर्ष पर मजबूती से खड़े रहें।'], 'VI': ['Tuy nhiên, xét theo nền tảng hiện tại, chỉ cần một khoảnh khắc lơ là cũng có thể khiến điểm số giảm sút. Để duy trì vững chắc vị trí hàng đầu, hãy ghi lại mọi lỗi sai vào nhật ký lỗi, ôn lại ít nhất ba lần và biến nó thành kiến thức của riêng mình. Duy trì kỷ luật này để tiếp tục đứng vững ở vị trí cao trong lần đánh giá tới.'], 'ES': ['Sin embargo, dado el nivel base actual, un momento de exceso de confianza podría hacer bajar la puntuación. Para consolidarte en la cima, registra cada error en un diario de errores, repásalo al menos tres veces y asimílalo por completo. Mantén esta rutina con disciplina para seguir firme en la cima la próxima vez.'], 'TH': ['อย่างไรก็ตาม เมื่อพิจารณาระดับพื้นฐานในปัจจุบัน หากเผลอตัวแม้เพียงชั่วขณะ คะแนนก็อาจลดลงได้ทันที เพื่อรักษาตำแหน่งระดับสูงสุดอย่างแท้จริง ควรบันทึกทุกข้อผิดพลาดลงในสมุดบันทึกข้อผิดพลาดและทบทวนอย่างน้อย 3 ครั้งจนเป็นความรู้ของตัวเองอย่างสมบูรณ์ รักษาวินัยนี้ไว้เพื่อยืนหยัดอยู่จุดสูงสุดอย่างมั่นคงในครั้งต่อไป']},
    'mid': {'KO': ['지금 단계에서 가장 유의해야 할 것은 \'이 정도면 됐다\'는 주관적인 안주와 타협입니다. 문항 분석 시 개념 스키마(지식의 구조적 네트워크)의 뼈대는 훌륭하나, 조건 해석의 정밀도가 다소 부족하여 감점이 발생하고 있습니다. 취약 단원의 고난도 변형 문제를 집중 공략하고 실전 시간 안배의 정밀도를 한 단계만 가속화하십시오. 정상으로 가는 마지막 관문이니, 조금만 더 고도의 학업적 몰입도를 발휘해 만점의 영광을 함께 쟁취합시다!', '현재 상태에서 성장을 한 단계 더 정체시키는 원인은 주관적인 안일함에 있을 수 있습니다. 인지 구조 내의 기본 스키마(지식의 구조적 네트워크)는 안정적이나, 세부 변별 과정에서 집중력의 미세한 누수가 관찰됩니다. 안일함을 지워내고 문항 단독 피드백 검토 단계를 한층 더 확장하십시오. 조금만 더 치열하게 벽을 두드린다면 반드시 차기 세션에서 만점을 거머쥘 수 있습니다.'], 'EN': ['The biggest risk right now is settling for \'good enough.\' The core concept structure is solid, but precision in reading question conditions is costing points. Target the hardest variant problems in weak units and tighten exam-time pacing one more notch. This is the final gate to the top — push a little harder and claim it!', 'The one thing holding growth back may be quiet complacency. The core knowledge structure is stable, but small lapses in concentration show up during fine-grained discrimination. Shed the complacency and expand item-by-item review. A bit more persistence and a perfect score is within reach next session.'], 'JA': ['今の段階で最も気をつけるべきは「これくらいで十分」という主観的な妥協です。問題分析の際、概念スキーマ（知識の構造的ネットワーク）の骨組みは優れていますが、条件解釈の精密さがやや不足して減点が生じています。弱点単元の高難度応用問題を集中攻略し、実戦の時間配分の精度をもう一段階高めてください。頂上への最後の関門なので、もう少し学業への没入度を高めて満点の栄光を勝ち取りましょう！'], 'ZH': ['目前阶段最需要警惕的就是“这样就够了”的主观妥协心态。分析题目时，概念框架（知识的结构性网络）已经相当扎实，但对条件的解读精度略有不足，从而导致失分。请集中攻克薄弱单元的高难度变式题，并将实战时间分配的精度再提升一个层次。这是通往顶峰的最后一关，只要再多投入一点学习专注度，就能共同夺得满分的荣耀！'], 'FR': ['À ce stade, le principal danger est de se satisfaire d\'un « c\'est déjà bien ». La structure conceptuelle est solide, mais la précision dans l\'interprétation des énoncés fait encore perdre des points. Concentrez-vous sur les variantes les plus difficiles des unités faibles et affinez la gestion du temps en conditions réelles. C\'est la dernière étape avant le sommet — un effort supplémentaire suffira à décrocher la perfection !'], 'DE': ['In dieser Phase besteht die größte Gefahr darin, sich mit „das reicht schon“ zufriedenzugeben. Die Konzeptstruktur ist solide, doch die Präzision beim Verständnis der Aufgabenbedingungen kostet noch Punkte. Konzentrieren Sie sich auf die schwierigsten Variantenaufgaben der schwachen Einheiten und verfeinern Sie das Zeitmanagement unter Prüfungsbedingungen. Dies ist das letzte Tor zum Gipfel — mit etwas mehr Einsatz ist die Bestnote erreichbar!'], 'RU': ['На этом этапе главная опасность — успокоиться на достигнутом. Концептуальная база прочная, но точность понимания условий заданий пока стоит баллов. Сосредоточьтесь на самых сложных вариациях заданий в слабых разделах и отточите распределение времени на экзамене. Это последний рубеж перед вершиной — ещё немного усилий, и максимальный балл будет достигнут!'], 'AR': ['في هذه المرحلة، أكبر خطر هو الرضا بـ«هذا يكفي». البنية المفاهيمية قوية، لكن دقة فهم شروط الأسئلة ما زالت تكلفك درجات. ركّز على أصعب أنواع الأسئلة في الوحدات الضعيفة، واضبط إدارة الوقت في ظروف الاختبار الحقيقية بدقة أكبر. هذه هي البوابة الأخيرة نحو القمة — القليل من الجهد الإضافي كافٍ لتحقيق الدرجة الكاملة!'], 'HI': ['इस चरण में सबसे बड़ा खतरा है \'इतना ही काफी है\' सोचकर संतुष्ट हो जाना। अवधारणा संरचना मजबूत है, लेकिन प्रश्नों की शर्तों को समझने की सटीकता में अभी भी अंक छूट रहे हैं। कमजोर यूनिट्स के सबसे कठिन प्रश्नों पर ध्यान केंद्रित करें और वास्तविक परीक्षा समय प्रबंधन को और सटीक बनाएं। यह शिखर की अंतिम सीढ़ी है — थोड़ा और प्रयास और पूर्ण अंक आपके हैं!'], 'VI': ['Ở giai đoạn này, nguy hiểm lớn nhất là hài lòng với suy nghĩ \'thế này là đủ rồi\'. Cấu trúc khái niệm đã vững, nhưng độ chính xác khi hiểu điều kiện câu hỏi vẫn khiến mất điểm. Hãy tập trung vào các dạng bài khó nhất ở những chương yếu, đồng thời tinh chỉnh việc phân bổ thời gian làm bài thực tế. Đây là cánh cửa cuối cùng trước đỉnh cao — chỉ cần nỗ lực thêm một chút là đạt điểm tuyệt đối!'], 'ES': ['En esta etapa, el mayor peligro es conformarse con un \'esto ya es suficiente\'. La estructura conceptual es sólida, pero la precisión al interpretar las condiciones de las preguntas todavía resta puntos. Concéntrate en las variantes más difíciles de las unidades débiles y afina la gestión del tiempo en condiciones reales. Esta es la última puerta hacia la cima: ¡un poco más de esfuerzo y la puntuación perfecta será tuya!'], 'TH': ['ในขั้นตอนนี้ สิ่งที่ต้องระวังที่สุดคือความคิดที่ว่า \'แค่นี้ก็พอแล้ว\' โครงสร้างแนวคิดแข็งแรงดี แต่ความแม่นยำในการตีความเงื่อนไขโจทย์ยังทำให้เสียคะแนนอยู่ ควรมุ่งเน้นโจทย์แบบยากในหน่วยที่ยังอ่อน และปรับการจัดสรรเวลาสอบจริงให้แม่นยำขึ้นอีกขั้น นี่คือด่านสุดท้ายก่อนถึงจุดสูงสุด เพียงทุ่มเทเพิ่มอีกนิดก็จะได้คะแนนเต็ม!']},
    'seventy': {'KO': ['하지만 역설적으로, 지금 이 순간 올바른 피드백을 통해 노력을 올바르게 투입한다면 전체 점수대 중 가장 폭발적이고 드라마틱하게 성적이 오를 수 있는 최고의 황금 구간이기도 합니다. 발생하는 오답들은 구조적 오인(개념의 뼈대를 잘못 이해하고 오답을 도출하는 현상)을 다듬으면 충분히 해결 가능한 자산입니다. 기본 원리 분석부터 차근차근 다시 정립하여 취약점을 지워내십시오. 가장 극적인 반등의 주인공은 바로 학습자가 될 수 있습니다.', '좌절할 필요는 전혀 없습니다. 이 구간은 문제점을 명확히 인지하고 혁신하기만 하면 교과과정 전체에서 가장 웅장한 점수 상승 폭을 기록할 수 있는 기회의 땅입니다. 현재의 부진은 눈으로만 대충 훑어본 인지적 기만(이해했다고 착각하는 심리 상태)에서 비롯된 균열일 뿐입니다. 오늘부터 취약 단원 기본서 피드백을 차분하고 독하게 이행해 나간다면 차기 평가에서 가장 놀라운 도약을 이루어낼 것입니다.'], 'EN': ['Ironically, this is also the golden zone where the right feedback applied right now can produce the single biggest jump in scores across the whole range. Most of the current mistakes trace back to misreading concept structure — a fixable asset once corrected. Rebuild from first principles, unit by unit, and erase the weak spots. The most dramatic turnaround story could belong to this learner.', 'There\'s no need to feel discouraged. Once the real problem is clearly identified, this range offers the biggest potential score jump in the whole curriculum. The current slump mostly comes from skimming material without truly absorbing it. Starting today, work calmly and thoroughly through core-textbook feedback on weak units for the most dramatic leap yet.'], 'JA': ['しかし逆説的に、今この瞬間正しいフィードバックを通じて努力を正しく投入すれば、全体の点数帯の中で最も劇的に成績が上がる可能性を秘めた黄金区間でもあります。発生している誤答は構造的誤解（概念の骨組みを誤って理解し誤答を導く現象）を整えれば十分解決可能な資産です。基本原理の分析から一つずつ再構築して弱点を消してください。最も劇的な反騰の主人公はまさに学習者になれます。'], 'ZH': ['然而矛盾的是，如果此刻能通过正确的反馈投入恰当的努力，这也正是整个分数段中最有可能实现戏剧性飞跃的黄金区间。目前出现的错题，只要纠正结构性误解（错误理解概念框架而导致答错的现象），完全是可以解决的宝贵资产。请从基本原理分析开始，逐步重建，消除薄弱环节。最具戏剧性的逆转主角完全可能就是这位学习者。'], 'FR': ['Paradoxalement, c\'est aussi la zone la plus propice à un bond spectaculaire si le bon effort est fourni maintenant. La plupart des erreurs viennent d\'une mauvaise compréhension de la structure conceptuelle — un point tout à fait corrigible. Reconstruisez les bases unité par unité pour effacer les faiblesses ; le plus grand rebond pourrait bien être signé par cet apprenant.'], 'DE': ['Paradoxerweise ist dies auch der Bereich, in dem der richtige Einsatz jetzt den dramatischsten Sprung in der Punktzahl bewirken kann. Die meisten Fehler beruhen auf einem Missverständnis der Konzeptstruktur — ein durchaus behebbarer Punkt. Bauen Sie die Grundlagen Einheit für Einheit neu auf, um die Schwächen zu beseitigen; der größte Aufschwung könnte genau von diesem Lernenden kommen.'], 'RU': ['Как ни парадоксально, именно этот диапазон даёт наибольший потенциал для резкого скачка результатов при правильных усилиях сейчас. Большинство ошибок связано с неверным пониманием концептуальной структуры — это вполне исправимо. Перестройте основы раздел за разделом, чтобы устранить слабые места; самый впечатляющий рывок вполне может совершить именно этот ученик.'], 'AR': ['من المفارقات أن هذا النطاق يوفر أكبر إمكانية لقفزة درامية في النتيجة إذا بُذل الجهد الصحيح الآن. معظم الأخطاء الحالية ناتجة عن سوء فهم للبنية المفاهيمية، وهو أمر قابل للتصحيح تمامًا. أعد بناء الأساسيات وحدة تلو الأخرى لإزالة نقاط الضعف؛ قد يكون هذا المتعلم بطل أكبر قفزة في النتائج.'], 'HI': ['विडंबना यह है कि सही प्रयास से यह श्रेणी सबसे नाटकीय स्कोर उछाल की संभावना भी रखती है। अधिकांश गलतियां अवधारणा संरचना की गलतफहमी से आती हैं — जिसे सुधारा जा सकता है। कमजोरियों को मिटाने के लिए यूनिट-दर-यूनिट आधार फिर से बनाएं; सबसे नाटकीय वापसी की कहानी इसी सीखने वाले की हो सकती है।'], 'VI': ['Trớ trêu thay, đây cũng chính là vùng điểm có tiềm năng bứt phá ngoạn mục nhất nếu nỗ lực đúng cách ngay từ bây giờ. Hầu hết lỗi sai đến từ việc hiểu sai cấu trúc khái niệm — điều hoàn toàn có thể khắc phục. Hãy xây dựng lại nền tảng từng chương một để xóa bỏ điểm yếu; câu chuyện bứt phá ấn tượng nhất có thể chính là của người học này.'], 'ES': ['Paradójicamente, este también es el rango con mayor potencial de un salto dramático en la puntuación si se aplica el esfuerzo correcto ahora. La mayoría de los errores provienen de una mala comprensión de la estructura conceptual, algo totalmente corregible. Reconstruye las bases unidad por unidad para eliminar las debilidades; el protagonista del giro más espectacular bien podría ser este estudiante.'], 'TH': ['ที่น่าแปลกคือ ช่วงคะแนนนี้กลับมีศักยภาพในการพลิกผันคะแนนได้มากที่สุด หากทุ่มเทอย่างถูกวิธีตั้งแต่ตอนนี้ ข้อผิดพลาดส่วนใหญ่มาจากความเข้าใจผิดในโครงสร้างแนวคิด ซึ่งแก้ไขได้อย่างแน่นอน ควรปรับพื้นฐานใหม่ทีละหน่วยเพื่อลบล้างจุดอ่อน เรื่องราวการพลิกผันที่น่าทึ่งที่สุดอาจเป็นของผู้เรียนคนนี้ก็ได้']},
    'sixty': {'KO': ['불안해하기보다는 학습 습관의 구조적 전환이 시급함을 깨닫는 계기로 삼아야 합니다. 주관적인 인지적 기만(완전히 이해하지 못했음에도 이해했다고 착각하는 상태)을 완전히 걷어내고, 기본 스키마(지식의 구조적 네트워크) 확장에 몰입해야 합니다. 틀린 문항을 단순히 확인하는 것에 그치지 말고 원리를 파고드는 깊이 있는 복습 루틴을 오늘부터 즉시 가속화하십시오. 지금의 경각심을 변화의 발판으로 삼는다면 충분히 반등할 수 있습니다.', '현재의 성적은 노력이 부족했다기보다는 문항을 분석하고 접근하는 과정에서 고질적인 구조적 오인(개념의 뼈대를 잘못 매핑하는 현상)이 반복되고 있음을 방증합니다. 느슨해진 오답 정비 체계를 철저히 다시 채찍질하고, 핵심 원리 중심의 복습 인프라를 전면 재구축하십시오. 지금 태도를 혁신하지 않으면 다음 평가의 반등은 어려워집니다. 마음을 다잡고 오늘부터 집중도를 극대화합시다.'], 'EN': ['Rather than worry, treat this as the signal that study habits need a structural overhaul. Drop the illusion of understanding, and commit fully to rebuilding the core concept structure. Don\'t just check off wrong answers — dig into the underlying principles starting today. Turn this alarm into the springboard for a real turnaround.', 'This score likely reflects not a lack of effort but a recurring habit of misreading concept structure. Rebuild the error-review system from the ground up around core principles. Without a real change in approach, the next evaluation won\'t turn around either — so commit fully starting today.'], 'JA': ['不安になるよりも、学習習慣の構造的転換が急務であることに気づく契機とすべきです。主観的な認知的欺瞞（完全に理解していないのに理解したと錯覚する状態）を完全に取り除き、基本スキーマ（知識の構造的ネットワーク）の拡張に没頭してください。間違えた問題を単に確認するだけでなく、原理を掘り下げる深みのある復習ルーティンを今日から即座に加速させてください。今の警戒心を変化の足場とすれば十分に反騰できます。'], 'ZH': ['与其感到不安，不如把这当作意识到学习习惯需要结构性转变的契机。请彻底摆脱“自以为理解了”的认知错觉，全力投入基础知识框架（知识的结构性网络）的扩展。不要只是确认错题，而要从今天起立刻加快深入原理的复习节奏。只要把现在的警觉当作改变的跳板，完全有机会实现反弹。'], 'FR': ['Plutôt que de s\'inquiéter, voyez-y le signal qu\'une refonte des habitudes d\'étude est nécessaire. Abandonnez l\'illusion de compréhension et investissez pleinement dans la reconstruction de la structure conceptuelle de base. Ne vous contentez pas de vérifier les erreurs — creusez les principes sous-jacents dès aujourd\'hui. Transformez cette vigilance en tremplin pour un vrai rebond.'], 'DE': ['Statt sich zu sorgen, sollte dies als Signal für eine strukturelle Überarbeitung der Lerngewohnheiten dienen. Verabschieden Sie sich von der Illusion des Verstehens und investieren Sie voll in den Wiederaufbau der grundlegenden Konzeptstruktur. Prüfen Sie Fehler nicht nur oberflächlich — gehen Sie den zugrunde liegenden Prinzipien ab heute intensiv auf den Grund. Verwandeln Sie diese Wachsamkeit in ein Sprungbrett für einen echten Aufschwung.'], 'RU': ['Вместо беспокойства воспримите это как сигнал к структурной перестройке учебных привычек. Откажитесь от иллюзии понимания и полностью посвятите себя восстановлению базовой концептуальной структуры. Не просто проверяйте ошибки — с сегодняшнего дня углубляйтесь в лежащие в основе принципы. Превратите эту тревогу в трамплин для настоящего подъёма.'], 'AR': ['بدلاً من القلق، اعتبر هذا إشارة إلى ضرورة إعادة هيكلة عادات الدراسة. تخلَّ عن وهم الفهم واستثمر جهدك بالكامل في إعادة بناء البنية المفاهيمية الأساسية. لا تكتفِ بمراجعة الأخطاء سطحيًا — تعمّق في المبادئ الأساسية ابتداءً من اليوم. حوّل هذا التنبيه إلى نقطة انطلاق لتحسن حقيقي.'], 'HI': ['चिंता करने के बजाय, इसे अध्ययन की आदतों में संरचनात्मक बदलाव की आवश्यकता का संकेत मानें। समझने के भ्रम को छोड़ें और मूल अवधारणा संरचना के पुनर्निर्माण में पूरी तरह जुट जाएं। गलतियों की सिर्फ जांच न करें — आज से ही अंतर्निहित सिद्धांतों में गहराई से उतरें। इस सतर्कता को वास्तविक सुधार का आधार बनाएं।'], 'VI': ['Thay vì lo lắng, hãy xem đây là tín hiệu cho thấy cần thay đổi cấu trúc thói quen học tập. Từ bỏ ảo tưởng đã hiểu và toàn tâm đầu tư xây dựng lại cấu trúc khái niệm cơ bản. Đừng chỉ kiểm tra lỗi sai qua loa — hãy đào sâu các nguyên lý nền tảng ngay từ hôm nay. Biến sự cảnh giác này thành bàn đạp cho một sự cải thiện thực sự.'], 'ES': ['En lugar de preocuparte, considera esto una señal de que los hábitos de estudio necesitan una reestructuración. Abandona la ilusión de haber entendido e invierte por completo en reconstruir la estructura conceptual básica. No te limites a revisar los errores superficialmente: profundiza en los principios subyacentes desde hoy. Convierte esta alerta en el trampolín para una mejora real.'], 'TH': ['แทนที่จะกังวล ควรมองว่านี่คือสัญญาณว่าต้องปรับโครงสร้างพฤติกรรมการเรียนใหม่ ละทิ้งภาพลวงตาว่าเข้าใจแล้ว และทุ่มเทสร้างโครงสร้างแนวคิดพื้นฐานขึ้นใหม่อย่างเต็มที่ อย่าแค่ตรวจข้อผิดพลาดผ่านๆ แต่ให้เจาะลึกหลักการพื้นฐานตั้งแต่วันนี้ เปลี่ยนความตื่นตัวนี้ให้เป็นจุดเริ่มต้นของการพลิกฟื้นที่แท้จริง']},
    'low': {'KO': ['기초가 흔들린 상태에서 문제 풀이에만 집착하는 것은 인지적 과부하를 가중시킬 뿐입니다. 조급한 마음을 완전히 가라앉히고, 단원별 교과서 핵심 원리 분석과 기본 어휘 스키마(지식의 구조적 네트워크) 빌딩에 즉각 착수하십시오. 기초부터 차근차근 벽돌을 쌓아 올린다면 성적은 반드시 정직하게 반응합니다. 나태해진 마음을 다잡고 오늘 밤부터 기초 평정 수치를 메우는 복습에 집중해 주십시오.', '현재 발생하는 대부분의 오답은 구조적 오인(개념의 기본 뼈대를 오해하는 현상)을 방치한 채 진도만 나간 부작용입니다. 지금 당장 멈추어 서서 취약 단원의 개념을 완벽히 소화하는 인내의 시간이 절대적으로 요구됩니다. 무기력함에 빠지지 말고, 베이스라인부터 다시 견고하게 다지겠다는 단단한 각오로 오늘부터 학습 속도와 밀도를 점진적으로 끌어올려 주십시오.'], 'EN': ['Pushing straight into more problems while the foundation is shaky only adds cognitive overload. Slow down, and start immediately with unit-by-unit textbook fundamentals and basic concept-building. Scores respond honestly to bricks laid one at a time from the ground up. Refocus tonight on filling the foundational gaps.', 'Most of the current mistakes come from pushing through material while misunderstanding core concepts. Stop now and take the time needed to fully digest the weak units. Don\'t fall into discouragement — commit to rebuilding the baseline and gradually raising study pace and depth starting today.'], 'JA': ['基礎が揺らいでいる状態で問題演習にばかり執着するのは、認知的過負荷を加重するだけです。焦る気持ちを完全に落ち着かせ、単元別教科書の核心原理分析と基本語彙スキーマ（知識の構造的ネットワーク）構築に即座に着手してください。基礎からじっくり積み上げれば、成績は必ず正直に反応します。今夜から基礎固めの復習に集中してください。'], 'ZH': ['在基础尚不牢固的情况下一味执着于刷题，只会加重认知负荷。请彻底平复急躁的心态，立即着手逐单元梳理教材核心原理，构建基础词汇框架（知识的结构性网络）。只要从基础一步步扎实积累，成绩必然会诚实地作出回应。请从今晚开始专注于弥补基础的复习。'], 'FR': ['S\'acharner sur les exercices alors que les bases vacillent ne fait qu\'aggraver la surcharge cognitive. Calmez-vous complètement et commencez immédiatement par une analyse des principes fondamentaux, unité par unité. En construisant patiemment depuis la base, les résultats répondront honnêtement. Concentrez-vous dès ce soir sur le renforcement des fondamentaux.'], 'DE': ['Sich bei wackligen Grundlagen nur auf das Üben von Aufgaben zu versteifen, erhöht nur die kognitive Überlastung. Beruhigen Sie sich vollständig und beginnen Sie sofort mit einer einheitenweisen Analyse der Kernprinzipien. Wenn die Grundlagen Stein für Stein aufgebaut werden, reagieren die Noten ehrlich darauf. Konzentrieren Sie sich ab heute Abend auf die Grundlagenwiederholung.'], 'RU': ['Упорное решение задач при шатких основах лишь усиливает когнитивную перегрузку. Полностью успокойтесь и немедленно начните разбор ключевых принципов по разделам. Если выстраивать основы кирпичик за кирпичиком, результаты честно отреагируют. Сегодня же вечером сосредоточьтесь на повторении основ.'], 'AR': ['الإصرار على حل المزيد من المسائل بينما الأساس غير ثابت يزيد فقط من العبء الإدراكي. اهدأ تمامًا وابدأ فورًا بتحليل المبادئ الأساسية وحدة تلو الأخرى. عند بناء الأساس لبنة بلبنة، ستستجيب النتيجة بصدق. ركّز الليلة على مراجعة الأساسيات.'], 'HI': ['जब आधार ही कमजोर है, तो केवल अभ्यास प्रश्नों पर अड़े रहना केवल संज्ञानात्मक बोझ बढ़ाता है। पूरी तरह शांत हों और तुरंत यूनिट-दर-यूनिट मूल सिद्धांतों के विश्लेषण से शुरुआत करें। यदि आधार ईंट-दर-ईंट मजबूत किया जाए, तो स्कोर निश्चित रूप से ईमानदारी से प्रतिक्रिया देगा। आज रात से ही आधार को मजबूत करने वाले पुनरीक्षण पर ध्यान दें।'], 'VI': ['Khi nền tảng còn lung lay mà cứ cố làm thêm bài tập chỉ khiến quá tải nhận thức. Hãy bình tĩnh hoàn toàn và bắt đầu ngay việc phân tích nguyên lý cốt lõi theo từng chương. Khi xây nền tảng từng viên gạch một cách chắc chắn, điểm số chắc chắn sẽ phản ánh trung thực. Hãy tập trung củng cố nền tảng ngay từ tối nay.'], 'ES': ['Insistir en más ejercicios cuando la base aún es inestable solo aumenta la sobrecarga cognitiva. Cálmate por completo y comienza de inmediato con un análisis de los principios básicos unidad por unidad. Si construyes la base ladrillo a ladrillo, la puntuación responderá con honestidad. Concéntrate esta misma noche en repasar los fundamentos.'], 'TH': ['การมุ่งแต่ทำโจทย์ทั้งที่พื้นฐานยังไม่มั่นคงมีแต่จะเพิ่มภาระทางความคิด ควรใจเย็นลงอย่างเต็มที่และเริ่มวิเคราะห์หลักการสำคัญทีละหน่วยทันที หากค่อยๆ สร้างพื้นฐานอย่างมั่นคงทีละก้าว คะแนนจะตอบสนองอย่างซื่อตรงแน่นอน ตั้งแต่คืนนี้ควรตั้งใจทบทวนเพื่อเสริมพื้นฐานให้แข็งแรง']},
  };

  static const Map<String, String> _diagAdditionalGuidance = {
    'KO': ' [추가 정밀 권고] 현재 학습 체계의 임계점(성취도가 도약하기 위해 필요한 최소한의 학업 밀도)을 넘어서기 위해서는 절대 주관적인 타협이나 나태함에 빠져서는 안 됩니다. 스스로의 가능성을 신뢰하고 정합성 확인 루틴을 독하게 사수하십시오!',
    'EN': ' [Additional Guidance] To clear the critical threshold needed for the next jump in achievement, never settle for subjective compromise or complacency. Trust your own potential and hold firmly to the review-and-verify routine!',
    'JA': ' [追加精密アドバイス] 現在の学習体系の臨界点（成果が飛躍するために必要な最小限の学習密度）を超えるためには、決して主観的な妥協や怠慢に陥ってはいけません。自身の可能性を信じ、整合性確認ルーティンを徹底的に守り抜いてください！',
    'ZH': ' [额外精细建议] 要突破当前学习体系的临界点（成绩实现飞跃所需的最低学习密度），绝不能陷入主观妥协或懈怠。请相信自己的潜力，坚定地坚持这一巩固流程！',
    'FR': ' [Conseil supplémentaire] Pour franchir le seuil critique nécessaire à un bond de niveau, ne cédez jamais au compromis ou à la complaisance. Faites confiance à votre potentiel et maintenez fermement cette routine de vérification !',
    'DE': ' [Zusätzlicher Hinweis] Um die kritische Schwelle für den nächsten Leistungssprung zu überwinden, dürfen Sie sich niemals mit Kompromissen oder Nachlässigkeit zufriedengeben. Vertrauen Sie auf Ihr Potenzial und halten Sie konsequent an dieser Überprüfungsroutine fest!',
    'RU': ' [Дополнительная рекомендация] Чтобы преодолеть критический порог, необходимый для следующего скачка в успеваемости, никогда не идите на компромисс с собой и не позволяйте себе расслабляться. Верьте в свой потенциал и твёрдо придерживайтесь этой проверочной дисциплины!',
    'AR': ' [توصية إضافية] لتجاوز العتبة الحرجة اللازمة للقفزة التالية في التحصيل، لا تستسلم أبدًا للتنازل الذاتي أو التراخي. ثق بإمكاناتك والتزم بحزم بروتين المراجعة والتحقق هذا!',
    'HI': ' [अतिरिक्त सटीक सलाह] अगली उपलब्धि छलांग के लिए आवश्यक महत्वपूर्ण सीमा को पार करने के लिए, कभी भी व्यक्तिपरक समझौते या लापरवाही में न पड़ें। अपनी क्षमता पर भरोसा रखें और इस सत्यापन दिनचर्या को दृढ़ता से बनाए रखें!',
    'VI': ' [Lời khuyên bổ sung] Để vượt qua ngưỡng quan trọng cần thiết cho bước nhảy vọt tiếp theo về thành tích, đừng bao giờ thỏa hiệp chủ quan hay lơ là. Hãy tin vào tiềm năng của bản thân và kiên định duy trì thói quen xác minh này!',
    'ES': ' [Recomendación adicional] Para superar el umbral crítico necesario para el próximo salto en el rendimiento, nunca cedas a la complacencia ni al compromiso subjetivo. Confía en tu potencial y mantén con firmeza esta rutina de verificación.',
    'TH': ' [คำแนะนำเพิ่มเติมอย่างละเอียด] เพื่อก้าวข้ามจุดวิกฤตที่จำเป็นสำหรับการก้าวกระโดดของผลสัมฤทธิ์ครั้งต่อไป ห้ามยอมประนีประนอมหรือเผลอเลินเล่อเด็ดขาด จงเชื่อมั่นในศักยภาพของตนเองและรักษาวินัยการตรวจสอบนี้ไว้อย่างเคร่งครัด!',
  };

  String _buildRuleBasedDiagnosisText({required String type, required double score, required String subject}) {
    final random = math.Random();
    final String lang = DkeLang.current;

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

    final List<String> openings = _diagOpenings[tier]![lang] ?? _diagOpenings[tier]!['EN']!;
    final List<String> closings = _diagClosings[tier]![lang] ?? _diagClosings[tier]!['EN']!;

    String diagnosisText = openings[random.nextInt(openings.length)] + closings[random.nextInt(closings.length)];

    if (diagnosisText.length < 350) {
      diagnosisText += _diagAdditionalGuidance[lang] ?? _diagAdditionalGuidance['EN']!;
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
    super.dispose();
  }

  void _showReportPopup(BuildContext context, String mainTitle, String content, {bool isTotalReport = false}) {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.3), width: 1.5),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      scrollbarTheme: ScrollbarThemeData(
                        thumbColor: MaterialStateProperty.all(_ThemeColors.brandGolden.withOpacity(0.5)),
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
                                  ? GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 23)
                                  : GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 22)
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close, color: Colors.white60), onPressed: () => Navigator.pop(context))
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 20, thickness: 1.2),
                  Text(finalContent, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14.5, height: 1.6)),
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
    final TextEditingController durationController = TextEditingController(text: "45분");
    final TextEditingController mockMonthController = TextEditingController(text: "6월");
    final TextEditingController mockRankController = TextEditingController(text: "1등급");

    String difficulty = "보통";
    int rating = 5;
    List<String> selectedCauses = ["개념부족"];
    String reviewStatus = "필요";

    final List<String> diffOptions = ["매우쉬움", "쉬움", "보통", "어려움", "매우어려움"];
    final List<String> causeOptions = ["개념부족", "계산실수", "시간부족", "문해력 부족", "긴장", "집중력 부족", "기타"];
    final List<String> reviewOptions = ["필요", "예정", "불필요"];

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          return StatefulBuilder(
              builder: (context, setPopupState) {
                return Dialog(
                  backgroundColor: _ThemeColors.premiumCardBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.4), width: 1.5),
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
                                      style: GoogleFonts.gowunBatang(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    Text(
                                      type == "모의고사" ? _t('mockDiagTitle') : _t('examDiagTitle'),
                                      overflow: TextOverflow.fade,
                                      softWrap: false,
                                      maxLines: 1,
                                      style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                                onPressed: () => Navigator.pop(ctx),
                              )
                            ],
                          ),
                          const Divider(color: Colors.white10, height: 16),

                          if (type == "모의고사") ...[
                            Text(_t('mockMonthLabel'), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: mockMonthController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                filled: true, fillColor: Colors.black26,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white12), borderRadius: BorderRadius.circular(6)),
                                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: _ThemeColors.brandGolden), borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(_t('mockRankLabel'), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: mockRankController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                filled: true, fillColor: Colors.black26,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white12), borderRadius: BorderRadius.circular(6)),
                                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: _ThemeColors.brandGolden), borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          Text(_t('label1Duration'), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: durationController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              filled: true, fillColor: Colors.black26,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white12), borderRadius: BorderRadius.circular(6)),
                              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: _ThemeColors.brandGolden), borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                          const SizedBox(height: 14),

                          Text(_t('label2Difficulty'), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4, runSpacing: 4,
                            children: diffOptions.map((d) {
                              bool isSel = difficulty == d;
                              return ChoiceChip(
                                label: Text(_difficultyLabel(d), style: TextStyle(color: isSel ? Colors.black : Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                selected: isSel,
                                selectedColor: _ThemeColors.brandGolden,
                                backgroundColor: Colors.black38,
                                onSelected: (bool selected) { if (selected) setPopupState(() => difficulty = d); },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),

                          Text(_t('label3Satisfaction'), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            children: List.generate(5, (index) {
                              int currentStarWeight = index + 1;
                              bool isActive = currentStarWeight <= rating;
                              return GestureDetector(
                                onTap: () => setPopupState(() => rating = currentStarWeight),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: Icon(
                                    Icons.star_rounded,
                                    color: isActive ? _ThemeColors.brandGolden : Colors.white24,
                                    size: 28,
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 14),

                          Text(_t('label4ErrorMulti'), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              children: causeOptions.map((cause) {
                                bool isChecked = selectedCauses.contains(cause);
                                return CheckboxListTile(
                                  title: Text(_causeLabel(cause), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  value: isChecked,
                                  dense: true,
                                  activeColor: _ThemeColors.brandGolden,
                                  checkColor: Colors.black,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (bool? checked) {
                                    setPopupState(() {
                                      if (checked == true) {
                                        if (!selectedCauses.contains(cause)) selectedCauses.add(cause);
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

                          Text(_t('label5ReviewSelect'), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: reviewOptions.map((r) {
                              bool isSel = reviewStatus == r;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: ChoiceChip(
                                  label: Text(_reviewLabel(r), style: TextStyle(color: isSel ? Colors.black : Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  selected: isSel,
                                  selectedColor: _ThemeColors.brandGolden,
                                  backgroundColor: Colors.black38,
                                  onSelected: (bool selected) { if (selected) setPopupState(() => reviewStatus = r); },
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: _ThemeColors.brandGolden, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              onPressed: () async {
                                String finalUnitLabel = unit;
                                if (type == "모의고사") {
                                  finalUnitLabel = "${mockMonthController.text} ${_examTypeLabel("모의고사")} (${mockRankController.text})";
                                }

                                final newRecord = _ExamRecord(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
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
                                  mockMonth: type == "모의고사" ? mockMonthController.text : "",
                                  mockRank: type == "모의고사" ? mockRankController.text : "",
                                );

                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setString('dke_parent_shared_type', type);
                                await prefs.setString('dke_parent_shared_subject', subject);
                                await prefs.setDouble('dke_parent_shared_score', score);
                                await prefs.setString('dke_parent_shared_duration', durationController.text);
                                await prefs.setString('dke_parent_shared_difficulty', difficulty);

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
                              child: Text(_t('confirmBtn'), style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
          );
        }
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
        border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.35), width: 1.2),
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
            style: GoogleFonts.gowunBatang(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            "${_t('recentFeedbackPrefix')} ${rec.type} ${_t('achievementFeedbackMetrics')}",
            overflow: TextOverflow.fade,
            softWrap: false,
            maxLines: 1,
            style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            DkeLang.current == 'KO'
                ? "${_t('targetSubjectLabel')}: ${rec.subject} (${rec.unit}) | ${_t('scoreLabel')}: ${rec.score.toInt()}점"
                : "${_t('targetSubjectLabel')}: ${rec.subject} (${rec.unit}) | ${_t('scoreLabel')}: ${rec.score.toInt()}",
            overflow: TextOverflow.fade,
            softWrap: false,
            maxLines: 1,
            style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),

          _buildMetricDisplayItem(_t('label1DurationShort'), rec.durationText, Icons.timer_outlined),
          _buildMetricDisplayItem(_t('label2DifficultyShort'), _difficultyLabel(rec.difficultyLevel), Icons.speed_outlined),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_outline_rounded, color: _ThemeColors.brandGolden, size: 14),
                    const SizedBox(width: 6),
                    Text(_t('label3SatisfactionShort'), style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12.5)),
                  ],
                ),
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      Icons.star_rounded,
                      color: (i < rec.starSatisfaction) ? _ThemeColors.brandGolden : Colors.white12,
                      size: 14,
                    );
                  }),
                ),
              ],
            ),
          ),

          _buildMetricDisplayItem(_t('label4ErrorShort'), rec.errorCauses.map(_causeLabel).join(", "), Icons.report_problem_outlined),
          _buildMetricDisplayItem(_t('label5ReviewShort'), _reviewLabel(rec.reviewRequired), Icons.flaky_outlined),
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
              Text(label, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12.5)),
            ],
          ),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.fade,
              softWrap: false,
              maxLines: 1,
              textAlign: TextAlign.right,
              style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5C158)))
          : SingleChildScrollView(
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
                  border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.25), width: 1.2),
                ),
                child: Column(
                  children: [
                    Text(
                      DkeLang.current == 'KO'
                          ? '${_t("highSchoolGrade2")} ${_realUserName ?? "학습자"}'
                          : "${_t('highSchoolGrade2')}, ${_realUserName ?? "Learner"}",
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
                  _buildTopButton(_t('totalReport'), 40, _buildTotalReportContent, isTotalReport: true),
                  const SizedBox(width: 8),
                  _buildTopButton(_t('detailedAnalytics'), 60, _buildDetailedReportContent),
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
                          border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.25), width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_t('nextLevelRoad'), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 14.5, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text('${_t('levelPrefix')}$_currentLevelNumber', overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
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
                                    style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            RichText(
                              overflow: TextOverflow.fade,
                              softWrap: true,
                              text: TextSpan(
                                style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.bold),
                                children: [
                                  TextSpan(text: _t('friendRank'), style: const TextStyle(color: Colors.white)),
                                  TextSpan(text: '$_realFriendRankDisplay\n\n', style: const TextStyle(color: _ThemeColors.brandGolden)),
                                  TextSpan(text: _t('globalRank'), style: const TextStyle(color: Colors.white)),
                                  TextSpan(text: _realGlobalRankDisplay, style: const TextStyle(color: _ThemeColors.brandGolden)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              decoration: BoxDecoration(color: const Color(0x2AFFFFFF), borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_t('targetUniversity'), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(height: 3),
                                  // 🆕 [데이터 연결-버그 수정] 마이페이지에서 실제로 저장한 목표 대학을 표시.
                                  // 아직 저장된 값이 없으면(신규 유저) 안내용 기본값(_t('snu'))을 그대로 보여줌.
                                  Text(_realTargetUniversity ?? _t('snu'), style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.fade, softWrap: false, maxLines: 1),
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
                          border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.25), width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(child: Text(_t('goalAttainment'), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 14.5, fontWeight: FontWeight.bold))),
                                Text("$_realGoalAttainmentPercent%", style: GoogleFonts.notoSansKr(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13.2)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            RichText(
                              overflow: TextOverflow.fade,
                              softWrap: true,
                              text: TextSpan(
                                style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.bold, height: 1.5),
                                children: [
                                  TextSpan(text: _t('todayVsYesterday'), style: const TextStyle(color: Colors.white)),
                                  TextSpan(text: "${_realTodayVsYesterdayPercent >= 0 ? '+' : ''}$_realTodayVsYesterdayPercent%\n\n", style: const TextStyle(color: _ThemeColors.brandGolden)),
                                  TextSpan(text: _t('mostImprovedSubject'), style: const TextStyle(color: Colors.white)),
                                  TextSpan(text: "${_realMostImprovedSubject != null ? _subjectName(_realMostImprovedSubject!) : _t('dataCollectingMsg')}\n\n", style: const TextStyle(color: _ThemeColors.brandGolden)),
                                  TextSpan(text: _t('mostStudiedSubject'), style: const TextStyle(color: Colors.white)),
                                  TextSpan(text: _realMostStudiedSubject != null ? _subjectName(_realMostStudiedSubject!) : _t('dataCollectingMsg'), style: const TextStyle(color: _ThemeColors.brandGolden)),
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
                                  border: Border.all(color: Colors.greenAccent.withOpacity(0.2), width: 1),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    RichText(
                                      overflow: TextOverflow.fade,
                                      softWrap: true,
                                      text: TextSpan(
                                        style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.bold, height: 1.4),
                                        children: [
                                          TextSpan(text: _t('totalStudyTimeLabel'), style: const TextStyle(color: Colors.white)),
                                          TextSpan(text: '${(_realTotalStudyMinutesAllTime / 60).toStringAsFixed(1)} ${_t('hoursUnitSuffix')}', style: const TextStyle(color: _ThemeColors.brandGolden)),
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
                      side: const BorderSide(color: Color(0xFFE5C158), width: 1.2),
                    ),
                  ),
                  onPressed: () async {
                    String currentType = _selectedExamType ?? "주평가";
                    final filtered = _allRecords.where((r) => r.type == currentType).toList();
                    String diagnosisText;

                    if (filtered.isEmpty) {
                      diagnosisText = _t('emptyFallbackShort');
                    } else {
                      final lastExam = filtered.last;
                      // 🆕 [5번] 유사 점수대 진단은 캐시 재사용 / [7번] 일반 리포트 = AI Light 배정 예정
                      diagnosisText = await _generateOrReuseDiagnosis(
                        type: currentType,
                        score: lastExam.score,
                        subject: lastExam.subject,
                        tier: AiTier.light,
                      );
                    }

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('dke_parent_shared_type', currentType);
                    await prefs.setString('dke_parent_shared_diagnosis', diagnosisText);

                    _showReportPopup(context, _t('diagReportTitle'), diagnosisText);
                  },
                  icon: const Icon(Icons.psychology_outlined, color: Color(0xFFE5C158), size: 18),
                  label: Text(
                    "[${_examTypeLabel(_selectedExamType ?? '주평가')} ${_t('viewAnalysisReport')}] 🔺",
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    maxLines: 1,
                    style: GoogleFonts.notoSansKr(color: const Color(0xFFE5C158), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Text(
                "Learning Duration Summary",
                overflow: TextOverflow.fade,
                softWrap: false,
                maxLines: 1,
                style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
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
                  border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.3), width: 1.2),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorPadding: const EdgeInsets.symmetric(horizontal: 0.5, vertical: 3),
                  indicator: const BoxDecoration(color: _ThemeColors.brandGolden, borderRadius: BorderRadius.all(Radius.circular(8))),
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.white,
                  labelStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 4.0),
                  unselectedLabelStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 4.0),
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
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 [2, 3번] 시험 유형(주평가/단원평가 등) 한글 키는 데이터 키로 그대로 유지하되, 화면 표시만 영문 병기
  static const Map<String, Map<String, String>> _examTypeMap = {
    "주평가": {'KO':'주평가','EN':'Weekly','JA':'週次評価','ZH':'周评估','FR':'Éval. hebdo','DE':'Wochentest','RU':'Еженед. оценка','AR':'تقييم أسبوعي','HI':'साप्ताहिक मूल्यांकन','VI':'Đánh giá tuần','ES':'Eval. semanal','TH':'ประเมินรายสัปดาห์'},
    "단원평가": {'KO':'단원평가','EN':'Unit Test','JA':'単元評価','ZH':'单元测验','FR':"Test d'unité",'DE':'Einheitstest','RU':'Тест по разделу','AR':'اختبار الوحدة','HI':'यूनिट टेस्ट','VI':'Kiểm tra chương','ES':'Prueba de unidad','TH':'ทดสอบบทเรียน'},
    "중간고사": {'KO':'중간고사','EN':'Midterm','JA':'中間試験','ZH':'期中考试','FR':'Mi-parcours','DE':'Zwischenprüfung','RU':'Промежуточный','AR':'اختبار نصفي','HI':'मिडटर्म','VI':'Giữa kỳ','ES':'Parcial','TH':'กลางภาค'},
    "기말고사": {'KO':'기말고사','EN':'Final','JA':'期末試験','ZH':'期末考试','FR':'Final','DE':'Abschlussprüfung','RU':'Итоговый','AR':'اختبار نهائي','HI':'फाइनल','VI':'Cuối kỳ','ES':'Final','TH':'ปลายภาค'},
    "모의고사": {'KO':'모의고사','EN':'Mock Exam','JA':'模試','ZH':'模拟考试','FR':'Examen blanc','DE':'Testexamen','RU':'Пробный экзамен','AR':'اختبار تجريبي','HI':'मॉक परीक्षा','VI':'Thi thử','ES':'Examen simulado','TH':'ข้อสอบจำลอง'},
  };

  static String _examTypeLabel(String typeKey) {
    final map = _examTypeMap[typeKey];
    if (map == null) return typeKey;
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? typeKey;
  }

  // 🆕 [12개국 확장] 난이도 / 실수 원인 / 복습 필요 여부 — 데이터 키(한글)는 그대로 저장, 화면 표시만 다국어 병기
  static const Map<String, Map<String, String>> _difficultyMap = {
    "매우쉬움": {'KO':'매우쉬움','EN':'Very Easy','JA':'とても簡単','ZH':'非常容易','FR':'Très facile','DE':'Sehr leicht','RU':'Очень легко','AR':'سهل جدًا','HI':'बहुत आसान','VI':'Rất dễ','ES':'Muy fácil','TH':'ง่ายมาก'},
    "쉬움": {'KO':'쉬움','EN':'Easy','JA':'簡単','ZH':'容易','FR':'Facile','DE':'Leicht','RU':'Легко','AR':'سهل','HI':'आसान','VI':'Dễ','ES':'Fácil','TH':'ง่าย'},
    "보통": {'KO':'보통','EN':'Normal','JA':'普通','ZH':'普通','FR':'Normal','DE':'Normal','RU':'Средне','AR':'متوسط','HI':'सामान्य','VI':'Trung bình','ES':'Normal','TH':'ปานกลาง'},
    "어려움": {'KO':'어려움','EN':'Hard','JA':'難しい','ZH':'困难','FR':'Difficile','DE':'Schwer','RU':'Сложно','AR':'صعب','HI':'कठिन','VI':'Khó','ES':'Difícil','TH':'ยาก'},
    "매우어려움": {'KO':'매우어려움','EN':'Very Hard','JA':'とても難しい','ZH':'非常困难','FR':'Très difficile','DE':'Sehr schwer','RU':'Очень сложно','AR':'صعب جدًا','HI':'बहुत कठिन','VI':'Rất khó','ES':'Muy difícil','TH':'ยากมาก'},
  };
  static String _difficultyLabel(String key) {
    final map = _difficultyMap[key];
    if (map == null) return key;
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? key;
  }

  static const Map<String, Map<String, String>> _causeMap = {
    "개념부족": {'KO':'개념부족','EN':'Concept Gap','JA':'概念不足','ZH':'概念不足','FR':'Manque de concept','DE':'Konzeptlücke','RU':'Пробел в понятиях','AR':'ضعف في المفهوم','HI':'अवधारणा की कमी','VI':'Thiếu khái niệm','ES':'Falta de concepto','TH':'ขาดความเข้าใจแนวคิด'},
    "계산실수": {'KO':'계산실수','EN':'Calc Error','JA':'計算ミス','ZH':'计算错误','FR':'Erreur de calcul','DE':'Rechenfehler','RU':'Ошибка в расчёте','AR':'خطأ حسابي','HI':'गणना त्रुटि','VI':'Lỗi tính toán','ES':'Error de cálculo','TH':'คำนวณผิด'},
    "시간부족": {'KO':'시간부족','EN':'Time Short','JA':'時間不足','ZH':'时间不足','FR':'Manque de temps','DE':'Zeitmangel','RU':'Не хватило времени','AR':'ضيق الوقت','HI':'समय की कमी','VI':'Thiếu thời gian','ES':'Falta de tiempo','TH':'เวลาไม่พอ'},
    "문해력 부족": {'KO':'문해력 부족','EN':'Reading Gap','JA':'読解力不足','ZH':'阅读理解不足','FR':'Manque de lecture','DE':'Leseschwäche','RU':'Слабое понимание текста','AR':'ضعف في الفهم القرائي','HI':'पठन कमी','VI':'Thiếu kỹ năng đọc hiểu','ES':'Falta de comprensión lectora','TH':'ขาดทักษะการอ่าน'},
    "긴장": {'KO':'긴장','EN':'Nervous','JA':'緊張','ZH':'紧张','FR':'Nervosité','DE':'Nervosität','RU':'Нервозность','AR':'التوتر','HI':'घबराहट','VI':'Lo lắng','ES':'Nerviosismo','TH':'ความตื่นเต้น'},
    "집중력 부족": {'KO':'집중력 부족','EN':'Focus Gap','JA':'集中力不足','ZH':'注意力不足','FR':'Manque de concentration','DE':'Konzentrationsmangel','RU':'Недостаток концентрации','AR':'ضعف التركيز','HI':'ध्यान की कमी','VI':'Thiếu tập trung','ES':'Falta de concentración','TH':'สมาธิไม่พอ'},
    "기타": {'KO':'기타','EN':'Other','JA':'その他','ZH':'其他','FR':'Autre','DE':'Sonstiges','RU':'Другое','AR':'أخرى','HI':'अन्य','VI':'Khác','ES':'Otro','TH':'อื่นๆ'},
  };
  static String _causeLabel(String key) {
    final map = _causeMap[key];
    if (map == null) return key;
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? key;
  }

  static const Map<String, Map<String, String>> _reviewMap = {
    "필요": {'KO':'필요','EN':'Needed','JA':'必要','ZH':'需要','FR':'Nécessaire','DE':'Nötig','RU':'Нужно','AR':'مطلوب','HI':'आवश्यक','VI':'Cần thiết','ES':'Necesario','TH':'จำเป็น'},
    "예정": {'KO':'예정','EN':'Planned','JA':'予定','ZH':'计划中','FR':'Prévu','DE':'Geplant','RU':'Запланировано','AR':'مخطط له','HI':'योजनाबद्ध','VI':'Đã lên kế hoạch','ES':'Planeado','TH':'วางแผนไว้'},
    "불필요": {'KO':'불필요','EN':'Not Needed','JA':'不要','ZH':'不需要','FR':'Non nécessaire','DE':'Nicht nötig','RU':'Не требуется','AR':'غير مطلوب','HI':'आवश्यक नहीं','VI':'Không cần','ES':'No necesario','TH':'ไม่จำเป็น'},
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
        border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.2), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isScoreSectionExpanded = !_isScoreSectionExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _t('myScoreRecord'),
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    maxLines: 1,
                    style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Icon(
                  _isScoreSectionExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? _ThemeColors.brandGolden : Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.4)),
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
                          style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_selectedExamType == "주평가") ...[
                    _buildSubFilterLabel(_t('yearSelect')),
                    _buildSubScrollRow(years, _inputYear, (v) => setState(() => _inputYear = v!)),
                    const SizedBox(height: 8),
                    _buildSubFilterLabel(_t('monthSelect')),
                    _buildSubScrollRow(months, _inputMonth, (v) => setState(() => _inputMonth = v!)),
                    const SizedBox(height: 8),
                    _buildSubFilterLabel(_t('weekSelect')),
                    _buildSubScrollRow(weeks, _inputWeek, (v) => setState(() => _inputWeek = v!)),
                  ] else if (_selectedExamType == "단원평가") ...[
                    _buildSubFilterLabel('${_t('bigUnitSelect')} (${DkeLang.current == 'KO' ? '여러 개 선택 가능 - 범위로 입력됨' : 'Multi-select for a range'})'),
                    _buildUnitMultiSelectRow(bigUnits, _inputBigUnits, (item) => () {
                      setState(() {
                        if (_inputBigUnits.contains(item)) {
                          if (_inputBigUnits.length > 1) _inputBigUnits.remove(item);
                        } else {
                          _inputBigUnits.add(item);
                        }
                      });
                    }),
                    const SizedBox(height: 8),
                    _buildSubFilterLabel('${_t('midUnitSelect')} (${DkeLang.current == 'KO' ? '여러 개 선택 가능 - 범위로 입력됨' : 'Multi-select for a range'})'),
                    _buildUnitMultiSelectRow(midUnits, _inputMidUnits, (item) => () {
                      setState(() {
                        if (_inputMidUnits.contains(item)) {
                          if (_inputMidUnits.length > 1) _inputMidUnits.remove(item);
                        } else {
                          _inputMidUnits.add(item);
                        }
                      });
                    }),
                  ] else ...[
                    _buildSubFilterLabel(_t('semesterSelect')),
                    Row(
                      children: semesters.map((sem) => _buildSubMiniBtn(sem, _inputSemesterGroup == sem, () => setState(() => _inputSemesterGroup = sem))).toList(),
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
                    style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _filterGrade,
                              dropdownColor: _ThemeColors.premiumCardBg,
                              style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              icon: const Icon(Icons.arrow_drop_down, color: _ThemeColors.brandGolden, size: 16),
                              items: [1, 2, 3].map((g) => DropdownMenuItem(value: g, child: Text(_t('gradeLabel') + " $g"))).toList(),
                              onChanged: (v) { if (v != null) setState(() { _filterGrade = v; }); },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _filterSemester,
                              dropdownColor: _ThemeColors.premiumCardBg,
                              style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              icon: const Icon(Icons.arrow_drop_down, color: _ThemeColors.brandGolden, size: 16),
                              items: [1, 2].map((s) => DropdownMenuItem(value: s, child: Text(_t('semesterLabel') + " $s"))).toList(),
                              onChanged: (v) { if (v != null) setState(() { _filterSemester = v; }); },
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
              Text(_t('newRecordGradeSemesterLabel'), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _inputGrade,
                      decoration: InputDecoration(labelText: _t('gradeLabel'), labelStyle: const TextStyle(color: Colors.white60, fontSize: 11)),
                      dropdownColor: _ThemeColors.premiumCardBg,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      items: [1, 2, 3].map((g) => DropdownMenuItem(value: g, child: Text(_t('gradeLabel') + " $g"))).toList(),
                      onChanged: (v) { if (v != null) setState(() { _inputGrade = v; }); },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _inputSemester,
                      decoration: InputDecoration(labelText: _t('semesterLabel'), labelStyle: const TextStyle(color: Colors.white60, fontSize: 11)),
                      dropdownColor: _ThemeColors.premiumCardBg,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      items: [1, 2].map((s) => DropdownMenuItem(value: s, child: Text(_t('semesterLabel') + " $s"))).toList(),
                      onChanged: (v) { if (v != null) setState(() { _inputSemester = v; }); },
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
                      decoration: InputDecoration(hintText: _t('subjectHint'), hintStyle: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _unitController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(hintText: _t('unitHint'), hintStyle: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _scoreController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(hintText: _t('scoreLabel'), hintStyle: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _ThemeColors.brandGolden),
                    onPressed: () {
                      if (_subjectController.text.isEmpty || _scoreController.text.isEmpty) return;
                      double? parsedScore = double.tryParse(_scoreController.text);
                      if (parsedScore == null) return;

                      String generatedUnitLabel = _unitController.text;
                      if (_selectedExamType == "주평가") {
                        generatedUnitLabel = "$_inputYear $_inputMonth $_inputWeek";
                      } else if (_selectedExamType == "단원평가") {
                        generatedUnitLabel = "${_formatUnitRangeLabel(_inputBigUnits, '대단원')} (${_formatUnitRangeLabel(_inputMidUnits, '중단원')})";
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
                    child: Text(_t('saveBtn'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
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
                      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
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
                            style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _allRecords.removeWhere((element) => element.id == rec.id);
                                if (_lastSavedRecordForDisplay?.id == rec.id) {
                                  _lastSavedRecordForDisplay = _allRecords.isNotEmpty ? _allRecords.last : null;
                                }
                              });
                              _persistExamRecords(); // 🆕 [데이터 연결] 삭제된 성적 기록도 즉시 영구 저장
                            },
                            child: const Icon(Icons.close, color: Colors.white60, size: 14),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ]
          ], // 🆕 if (_isScoreSectionExpanded) 블록 닫기
        ],
      ),
    );
  }

  // 🆕 [요청] 대단원/중단원 공용 다중선택 행. items 중 tap한 항목을 selectedSet에서 토글함.
  // (최소 1개는 항상 선택된 상태를 유지해서 완전히 빈 선택이 되지 않게 함)
  Widget _buildUnitMultiSelectRow(List<String> items, Set<String> selectedSet, VoidCallback Function(String) onToggleBuilder) {
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
    }).toList()
      ..sort();

    if (nums.length == 1) return "$unitWord ${nums.first}";

    bool isContiguous = true;
    for (int i = 1; i < nums.length; i++) {
      if (nums[i] != nums[i - 1] + 1) { isContiguous = false; break; }
    }

    if (isContiguous) return "$unitWord ${nums.first}~$unitWord ${nums.last}";
    return nums.map((n) => "$unitWord $n").join(", ");
  }

  Widget _buildSubScrollRow(List<String> items, String selectedValue, ValueChanged<String?> onSelected) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: items.map((item) => _buildSubMiniBtn(item, selectedValue == item, () => onSelected(item))).toList(),
      ),
    );
  }

  Widget _buildSubFilterLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
      child: Text(label, overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500)),
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
            border: Border.all(color: _ThemeColors.brandGolden.withOpacity(isSelected ? 0.7 : 0.2)),
          ),
          child: Text(text, overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(color: isSelected ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // 🆕 [⑧번] 시그니처 변경: String contentText -> Future<String> Function() contentBuilder
  // 버튼을 누르는 시점에 실시간으로 실제 데이터 기반 리포트를 생성하도록 변경.
  Widget _buildTopButton(String title, int flex, Future<String> Function() contentBuilder, {bool isTotalReport = false}) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () async {
          final String content = await contentBuilder();
          if (!mounted) return;
          _showReportPopup(context, title, content, isTotalReport: isTotalReport);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _ThemeColors.premiumCardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.3)),
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
                  style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.play_arrow_rounded, color: Color(0xFFE5C158), size: 14),
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
        Text(label, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 9)),
        const SizedBox(width: 4),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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
          Text(_t('dailyTotalStudyTime'), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 10),
          Container(
            height: 100,
            width: double.infinity,
            alignment: Alignment.center,
            child: Text(_t('dataCollectingMsg'), style: const TextStyle(color: Colors.white38, fontSize: 12)),
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
    final double windowRangeMinutes = windowTopMinutes - windowBottomMinutes; // 항상 180분(3시간) 폭 유지

    final List<String> yAxisLabels = [
      "${windowTopHours.toInt()}h",
      "${(windowTopHours - 1).toInt()}h",
      "${(windowTopHours - 2).toInt()}h",
      "${windowBottomHours.toInt()}h",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('dailyTotalStudyTime'), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: _ThemeColors.premiumCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.2), width: 1.2),
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
                          ...yAxisLabels.take(3).map((label) => Expanded(
                            child: Align(
                              alignment: Alignment.topRight,
                              child: _buildYAxisDotLabel(label),
                            ),
                          )),
                          _buildYAxisDotLabel(yAxisLabels.last),
                          const SizedBox(height: 20), // 🆕 실제 막대 바닥(날짜 텍스트 위)과 맞춘 하단 간격
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 🆕 [X축] 세로 기준선 - 하단을 실제 막대 바닥(원점)과 정확히 맞춤
                    Container(width: 1.5, margin: const EdgeInsets.only(top: 16, bottom: 20), color: _ThemeColors.brandGolden.withOpacity(0.6)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _dailyTotalScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _dailyTotalHistory.asMap().entries.map((entry) {
                            final int idx = entry.key;
                            final Map<String, dynamic> d = entry.value;
                            final DateTime date = d["date"] as DateTime;
                            final int minutes = d["totalMinutes"] as int;
                            final DateTime today = DateTime.now();
                            final bool isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                            // 🆕 [요청] 막대 색상을 무지개색 순서로 반복 (기존 _todayColors 팔레트 재사용)
                            final Color barColor = _todayColors[idx % _todayColors.length];

                            // 🆕 윈도우 하단(windowBottomMinutes) 밑으로 내려가는 값은 0으로 고정해서 "가위질"된 것처럼 안 보이게 함
                            double barFraction = (minutes - windowBottomMinutes) / windowRangeMinutes;
                            if (barFraction < 0) barFraction = 0;
                            if (barFraction > 1) barFraction = 1;
                            double barHeight = barFraction * barAreaHeight;
                            if (barFraction > 0 && barHeight < 3) barHeight = 3; // 윈도우 안에 실제 값이 있을 때만 최소 시인성 보장
                            if (barHeight > barAreaHeight) barHeight = barAreaHeight;

                            return Container(
                              width: 48,
                              margin: const EdgeInsets.symmetric(horizontal: 2), // 🆕 [요청] 날짜 칸 간격 50% 축소(4→2)
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${(minutes / 60).toStringAsFixed(1)}h",
                                    style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: barHeight,
                                    width: 22,
                                    decoration: BoxDecoration(
                                      color: barColor,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                      border: isToday ? Border.all(color: _ThemeColors.brandGolden, width: 1.5) : null,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "${date.month}/${date.day}",
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    maxLines: 1,
                                    style: GoogleFonts.notoSansKr(
                                      color: isToday ? _ThemeColors.brandGolden : Colors.white,
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
                child: Container(height: 1.5, color: _ThemeColors.brandGolden.withOpacity(0.6)),
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
          width: 16, height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: _ThemeColors.brandGolden.withOpacity(0.7), blurRadius: 7, spreadRadius: 2.0),
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

  // 🆕 [⑤번] 오늘 학습한 과목 목록 (timer_screen.dart가 저장한 dke_history_* 기록 중 오늘 것만 필터링)
  List<Map<String, dynamic>> _todaySessions = [];

  // 🆕 [⑤번] 오늘 진행한 학습 세션을 시간순으로 불러오는 함수.
  // dke_history_{과목명} 키를 전부 훑어서 오늘 날짜에 해당하는 기록만 추출합니다.
  Future<void> _loadTodaySessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Set<String> allKeys = prefs.getKeys();
      final Iterable<String> historyKeys = allKeys.where((k) => k.startsWith('dke_history_'));
      final DateTime now = DateTime.now();
      final DateTime todayStart = DateTime(now.year, now.month, now.day);

      final List<Map<String, dynamic>> sessions = [];

      for (final key in historyKeys) {
        final String subjectName = key.substring('dke_history_'.length);
        final List<String>? entries = prefs.getStringList(key);
        if (entries == null) continue;
        for (final raw in entries) {
          try {
            final Map<String, dynamic> item = jsonDecode(raw);
            final DateTime ts = DateTime.tryParse(item['timestamp']?.toString() ?? '')?.toLocal() ?? now;
            if (ts.isBefore(todayStart)) continue;
            final int durationSeconds = (item['durationSeconds'] as num?)?.toInt() ?? 0;
            final int minutes = (durationSeconds / 60).round();
            sessions.add({
              "subject": subjectName,
              "minutes": minutes,
              "timestamp": ts,
            });
          } catch (_) {
            // 손상된 기록 하나는 건너뛰고 나머지는 계속 집계
          }
        }
      }

      sessions.sort((a, b) => (a["timestamp"] as DateTime).compareTo(b["timestamp"] as DateTime));

      if (!mounted) return;
      setState(() {
        _todaySessions = sessions;
      });
    } catch (e) {
      debugPrint("[MemberAchievement] 오늘 학습 세션 불러오기 실패: $e");
    }
  }

  // 🆕 [⑤번] "오늘 학습한 과목" 카드 위젯. 오늘 진행한 세션이 없으면 안내 문구, 있으면 교시별 목록을 보여줍니다.
  Widget _buildTodaySessionsCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ThemeColors.premiumCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.25), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('todaySessionsTitle'),
            overflow: TextOverflow.fade,
            softWrap: false,
            maxLines: 1,
            style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 10),
          if (_todaySessions.isEmpty)
            Text(_t('noSessionsToday'), style: const TextStyle(color: Colors.white38, fontSize: 12))
          else
            ..._todaySessions.asMap().entries.map((entry) {
              final int idx = entry.key;
              final Map<String, dynamic> s = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        "${idx + 1}${_t('sessionOrdinal')} · ${_subjectName(s["subject"] as String)}",
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        maxLines: 1,
                        style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      "${s["minutes"]}${_t('minutesUnitSuffix')}",
                      style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // 🆕 [⑤⑦번] "종합 리포트" 버튼용 실시간 콘텐츠 생성 함수.
  // 기존의 "이규현" 가짜 고정 텍스트(summaryReportBody)를 대체하며, 오늘 실제 학습 세션과
  // 실제 목표 달성도를 반영한 진단 피드백을 실시간으로 구성합니다.
  Future<String> _buildTotalReportContent() async {
    if (_todaySessions.isEmpty) {
      return _t('noSessionsToday');
    }

    final buffer = StringBuffer();
    buffer.write(DkeLang.current == 'KO' ? '[종합 리포트]\n\n' : '[Total Report]\n\n');

    for (int i = 0; i < _todaySessions.length; i++) {
      final s = _todaySessions[i];
      final DateTime ts = s["timestamp"] as DateTime;
      final String timeStr = "${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}";
      buffer.write(DkeLang.current == 'KO'
          ? "${i + 1}${_t('sessionOrdinal')}\n"
          : "${_t('sessionOrdinal')} ${i + 1}\n");
      buffer.write("• ${_subjectName(s["subject"] as String)}: ${s["minutes"]}${_t('minutesUnitSuffix')} ($timeStr)\n\n");
    }

    final String topSubject = _todaySessions.first["subject"] as String;
    final String diagnosis = await _generateOrReuseDiagnosis(
      type: "일일종합",
      score: _realGoalAttainmentPercent.toDouble(),
      subject: topSubject,
      tier: AiTier.light,
    );
    buffer.write(DkeLang.current == 'KO' ? '[종합 진단 피드백]\n' : '[Overall Diagnostic Feedback]\n');
    buffer.write(diagnosis);

    return buffer.toString();
  }

  // 🆕 [⑤⑦번] "상세분석기록" 버튼용 실시간 콘텐츠 생성 함수.
  // 기존의 "이규현" 가짜 고정 텍스트(detailedReportBody)를 대체하며, 오늘 실제 학습시간과
  // 가장 많이 학습한 과목을 반영한 상세 진단을 실시간으로 구성합니다.
  Future<String> _buildDetailedReportContent() async {
    if (_todaySessions.isEmpty) {
      return _t('noSessionsToday');
    }

    final int totalTodayMin = _todaySessions.fold<int>(0, (sum, s) => sum + (s["minutes"] as int));
    final String topSubject = _todaySessions.first["subject"] as String;

    final buffer = StringBuffer();
    buffer.write(DkeLang.current == 'KO' ? '[상세분석기록]\n\n' : '[Detailed Analytics]\n\n');
    buffer.write("• ${_t('studyTime')}: $totalTodayMin${_t('minutesUnitSuffix')}\n");
    buffer.write("• ${_t('mostStudiedSubject').replaceAll('\n', '')}: ${_subjectName(topSubject)}\n\n");

    final String diagnosis = await _generateOrReuseDiagnosis(
      type: "일일상세",
      score: _realGoalAttainmentPercent.toDouble(),
      subject: topSubject,
      tier: AiTier.pro,
    );
    buffer.write(diagnosis);

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
                ...scoreLabels.take(4).map((label) => Expanded(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Text(label, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                    )
                )),
                Align(
                  alignment: Alignment.topRight,
                  child: Text(scoreLabels.last, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
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
                margin: const EdgeInsets.only(top: _kChartTopPad, bottom: _kChartBottomPad),
                color: _ThemeColors.brandGolden.withOpacity(0.6),
              ),
              Positioned.fill(
                top: _kChartTopPad,
                bottom: _kChartBottomPad,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (index) => Container(
                    width: 6,
                    height: 1.5,
                    color: _ThemeColors.brandGolden,
                  )),
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
                          final Color barColor = _evalColors[idx % _evalColors.length];

                          double scoreVal = rec.score.clamp(scoreMin, scoreMax);
                          double drawScoreHeight = ((scoreVal - scoreMin) / scoreRange) * hMax;
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
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(2.0)),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: drawScoreHeight + 2,
                                        child: Text(
                                          "${rec.score.toInt()}",
                                          style: TextStyle(color: barColor, fontSize: 9.5, fontWeight: FontWeight.bold),
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
                  left: 0, right: 0, bottom: _kChartBottomPad,
                  child: Container(width: double.infinity, height: 2.2, color: _ThemeColors.brandGolden.withOpacity(0.6)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAdvancedChartDashboard(int tabIndex) {
    List<Map<String, dynamic>> rawData = _masterSubjectData;
    double multiplier = (tabIndex == 0) ? 1.0 : (tabIndex == 1) ? 5.0 : (tabIndex == 2) ? 22.0 : 250.0;

    List<Map<String, dynamic>> targetSubjects = [];
    for (var item in rawData) {
      bool isValid = false;
      if (tabIndex == 0 && item["hasStudiedToday"] == true) isValid = true;
      if (tabIndex == 1 && item["hasStudiedWeekly"] == true) isValid = true;
      if (tabIndex == 2 && item["hasStudiedMonthly"] == true) isValid = true;
      if (tabIndex == 3 && item["hasStudiedYearly"] == true) isValid = true;

      if (isValid) {
        double totalMins = (item["baseMinutes"] as int).toDouble() * multiplier;
        if (totalMins > 0) {
          targetSubjects.add({
            ...item,
            "calculatedMinutes": totalMins,
          });
        }
      }
    }

    targetSubjects.sort((a, b) => (b["calculatedMinutes"] as double).compareTo(a["calculatedMinutes"] as double));

    double maxMinutesFound = 0.0;
    for (var item in targetSubjects) {
      if ((item["calculatedMinutes"] as double) > maxMinutesFound) {
        maxMinutesFound = item["calculatedMinutes"] as double;
      }
    }

    // 🆕 [Y축 목표 천장값 보정] 일간 200분(≈3시간) / 주간 14시간(하루 2시간×7일) /
    // 월간 약 50시간 / 연간 약 600시간(수정예정) — 말씀하신 기준값으로 반영.
    // (기존에는 월간·연간이 똑같이 "5시간"으로 되어있던 버그가 있었어서 함께 수정함)
    double minCeiling = 200.0;
    if (tabIndex == 1) minCeiling = 14.0 * 60.0;
    if (tabIndex == 2) minCeiling = 50.0 * 60.0;
    if (tabIndex == 3) minCeiling = 600.0 * 60.0;

    if (maxMinutesFound < minCeiling) {
      maxMinutesFound = minCeiling;
    }

    double yAxisMaxBoundary = maxMinutesFound / 0.90;
    if (yAxisMaxBoundary <= 0) yAxisMaxBoundary = 100.0;

    if (tabIndex == 1 && yAxisMaxBoundary > 25.0 * 60.0) yAxisMaxBoundary = 25.0 * 60.0;
    if (tabIndex == 2 && yAxisMaxBoundary > 120.0 * 60.0) yAxisMaxBoundary = 120.0 * 60.0;
    if (tabIndex == 3 && yAxisMaxBoundary > 1500.0 * 60.0) yAxisMaxBoundary = 1500.0 * 60.0;

    List<String> dynamicYAxisLabels = [];
    for (int i = 4; i >= 0; i--) {
      double currentSliceValue = (yAxisMaxBoundary / 4) * i;
      if (tabIndex == 0) {
        dynamicYAxisLabels.add("${currentSliceValue.round()}m");
      } else {
        double hoursValue = currentSliceValue / 60.0;
        dynamicYAxisLabels.add("${hoursValue.toStringAsFixed(1)}h");
      }
    }

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
                left: 48, top: 0,
                child: Row(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 5),
                  Text(_t('average'), style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),
              Positioned.fill(
                left: 42, right: 0, top: _kChartTopPad, bottom: _kChartBottomPad,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (i) => Container(width: double.infinity, height: 0.8, color: Colors.white.withOpacity(0.08))),
                ),
              ),
              Positioned(
                left: 42, top: _kChartTopPad, bottom: _kChartBottomPad,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(9, (i) => Container(width: i % 2 != 0 ? 4.0 : 0.0, height: 1.5, color: _ThemeColors.brandGolden.withOpacity(0.4))),
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
                        ...dynamicYAxisLabels.take(4).map((label) => Expanded(child: Text(label, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 9.5)))),
                        Text(dynamicYAxisLabels.last, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 9.5)),
                        const SizedBox(height: _kChartBottomPad),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 2.2, margin: const EdgeInsets.only(top: _kChartTopPad, bottom: _kChartBottomPad), color: _ThemeColors.brandGolden.withOpacity(0.6)),

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
                              children: List.generate(targetSubjects.length, (index) {
                                final data = targetSubjects[index];
                                const double hMaxDashboard = 120.0;
                                final Color pCol = colorPalette[index % colorPalette.length];

                                double currentMins = data["calculatedMinutes"] as double;
                                double drawScoreHeight = (currentMins / yAxisMaxBoundary) * hMaxDashboard;
                                double drawAvgHeight = ((data["averageScore"] as double) * (currentMins * 0.8) / yAxisMaxBoundary) * hMaxDashboard;

                                if (drawScoreHeight < 4) drawScoreHeight = 4;
                                if (drawAvgHeight < 2) drawAvgHeight = 2;
                                if (drawScoreHeight > hMaxDashboard) drawScoreHeight = hMaxDashboard;
                                if (drawAvgHeight > hMaxDashboard) drawAvgHeight = hMaxDashboard; // 🆕 [버그 수정] 평균 막대도 상한 제한 - 주간/월간/연간에서 X축 아래로 삐져나오던 오버플로우 해결

                                return Container(
                                  width: 53,
                                  margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: hMaxDashboard + 16, width: 53,
                                        child: Stack(
                                          alignment: Alignment.bottomCenter,
                                          children: [
                                            Positioned(
                                              left: 10, bottom: 0,
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Text("${(data["averageScore"] * 100).toInt()}%", style: const TextStyle(color: Colors.white54, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                                  Container(
                                                    height: drawAvgHeight, width: 16,
                                                    decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: const BorderRadius.vertical(top: Radius.circular(2.5))),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Positioned(
                                              left: 27, bottom: 0,
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Text("${(data["score"] * 100).toInt()}%", style: TextStyle(color: pCol, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                                  Container(
                                                    height: drawScoreHeight, width: 16,
                                                    decoration: BoxDecoration(color: pCol, borderRadius: const BorderRadius.vertical(top: Radius.circular(2.5))),
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
                                        child: Text(data["subject"], textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold, height: 1.2)),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0, right: 0, bottom: _kChartBottomPad,
                          child: Container(width: double.infinity, height: 2.2, color: _ThemeColors.brandGolden.withOpacity(0.6)),
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

        _buildDailyTotalStudyTimeGraph(), // 🆕 [배치 변경] 과목 학습시간 바로 아래, 종합 생활 균형 바로 위
        const SizedBox(height: 20),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('lifeBalance'), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
            Text(_t('lifeBalanceSub'), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              flex: 50,
              child: Center(
                child: SizedBox(
                  width: 170, height: 170,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(170, 170),
                        painter: _GsuPiePainter(targetSubjects: targetSubjects, colors: colorPalette),
                      ),
                      Container(
                        width: 82, height: 82,
                        decoration: const BoxDecoration(color: Color(0xFF0D1527), shape: BoxShape.circle),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Total', style: GoogleFonts.gowunBatang(color: Colors.white38, fontSize: 10)),
                            Text("$totalMinutes/m", style: GoogleFonts.gowunBatang(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
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
                  final int calculatedMin = (item["calculatedMinutes"] as double).round();
                  final int percent = totalMinutes > 0 ? ((calculatedMin / totalMinutes) * 100).round() : 0;
                  final Color c = colorPalette[idx % colorPalette.length];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: Row(
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${item["subject"].toString().replaceAll('\n', ' ')}  $percent%",
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                                maxLines: 2, // 🆕 [요청] 과목명이 길면 2줄까지 허용해서 오버플로우 방지
                                style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                item["isStarEligible"] ? "✨ +${calculatedMin} Stars" : "🚫 No Stars",
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                maxLines: 1,
                                style: GoogleFonts.notoSansKr(color: item["isStarEligible"] ? _ThemeColors.brandGolden.withOpacity(0.8) : Colors.white38, fontSize: 10),
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
            builder: (c, child) => Transform.translate(offset: Offset(0, _warningAnimation.value), child: child),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _ThemeColors.brandGolden,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.2),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
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
                          style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                      ),
                      Text(
                          _t('dbSyncSub'),
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          maxLines: 1,
                          style: GoogleFonts.notoSansKr(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w600)
                      ),
                    ],
                  ),
                ),
              ]),
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
    final double total = targetSubjects.fold<double>(0.0, (s, i) => s + (i["calculatedMinutes"] as double));
    if (total == 0) return;

    final Paint p = Paint()..style = PaintingStyle.fill..isAntiAlias = true;
    double start = -math.pi / 2;

    for (int i = 0; i < targetSubjects.length; i++) {
      final double calculatedMin = targetSubjects[i]["calculatedMinutes"] as double;
      final double sweep = (calculatedMin / total) * 2 * math.pi;
      p.color = colors[i % colors.length];
      canvas.drawArc(Rect.fromLTWH(0, 0, size.width, size.height), start, sweep, true, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) => true;
}
