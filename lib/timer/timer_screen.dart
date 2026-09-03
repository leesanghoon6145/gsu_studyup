import 'dart:convert'; // 🎯 과목별 객체 데이터 인코딩용 패키지 주입
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
// 👑 파일 트리 구조 분석에 따른 무결점 순정 상대 경로 임포트 고정 완료
import '../square/my_page_screen.dart';
import '../planner/widgets/study_timelines.dart'; // 타임라인 연동용 임포트
import '../star_economy.dart'; // 🆕 [별 경제 시스템] 별 적립 속도/누적저장/레벨계산을 한 곳에서 관리
import '../services/family_link_service.dart'; // 🆕 [학부모 가시성 확보 2026-09-02] 학습 기록을 Firestore에도 함께 올리기 위함

class TimerScreen extends StatefulWidget {
  final String selectedSubject;
  final int selectedDurationMinutes;
  final String dynamicTestTitle;
  final DateTime? targetExamDate;
  final String selectedSoundFile;
  final DateTime? targetExamEndDate;
  final String prepPeriodStr;
  final bool needTimelineGen;
  final String targetUniversity;
  final bool isVipMember;
  final bool isFinalExamMode; // [추가] 기말고사 여부 (기본값 false = 중간고사)
  final bool isExamTrackMode; // 🆕 [2026-07-29] true=시험준비/시험당일에서 실행됨(D-day 표시), false=평상시/방학/개인시간표(목표만 표시)

  const TimerScreen({
    Key? key,
    required this.selectedSubject,
    required this.selectedDurationMinutes,
    required this.dynamicTestTitle,
    this.targetExamDate,
    required this.targetExamEndDate,
    required this.prepPeriodStr,
    required this.needTimelineGen,
    required this.selectedSoundFile,
    this.targetUniversity = "Seoul National University (서울대학교)",
    this.isVipMember = false,
    this.isFinalExamMode = false, // [추가]
    this.isExamTrackMode = true, // 🆕 [2026-07-29 수정] 기본값 true로 되돌림 - home_dashboard_screen.dart 등 기존 호출부는 안 건드리고 원래대로 작동. academic_timeline_screen.dart만 평상시/방학/개인시간표일 때 명시적으로 false를 넘겨서 "목표"만 표시함.
  }) : super(key: key);
  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  // 타임라인 관련 상태 변수
  late DateTime _currentSelectedDate;
  List<Map<String, String>> _activeTimeline = [];

  late int _totalSeconds;
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _isRunning = false;
  double progressPercent = 0.0;

  late AudioPlayer _timerAudioPlayer;
  late AudioPlayer _cueAudioPlayer; // [추가] 시작/종료 알림음 전용 플레이어

  // 👑 10분 락 연동용 초정밀 타이밍 제어 변수 스펙
  int _animationCycleSeconds = 0;
  bool _showVipOverlay = false;

  // 🆕 [별 경제 시스템] 실시간 자동 적립 카운터 - DkeStars.starAccrualInterval 마다 별 1개씩 즉시 저장.
  // 30분 단위로 몰아서 저장하지 않고, 적립 주기 그대로 바로 SharedPreferences에 반영해서
  // 앱이 중간에 꺼져도 이미 적립된 별은 안전하게 보존됨.
  int _secondsSinceLastStarAccrual = 0;
  int _starsEarnedThisSession = 0;

  late String _currentUniversity;
  String _currentLanguageCode = 'ko';
  bool _currentIsVip = false; // 👈 🎯 영구 동기화용 실시간 VIP 상태 필터 스펙 추가

  // 👑 하단 자식 애니메이션 엔진을 타이머 화면에서 직접 흔들어 깨우기 위한 고유 Key 부품 신설
  final GlobalKey<_DkeBigStarTargetAnimationModuleState> _animKey = GlobalKey<_DkeBigStarTargetAnimationModuleState>();

  // ============================================================================
  // 🆕 [12개국어 완전 지원 2026-09-02] 이 화면(timer_screen.dart) 전용 번역 카탈로그.
  // DkeBigStarTargetAnimationModule이 이미 쓰던 방식(_currentLanguageCode 대문자 비교)과
  // 완전히 동일한 방식으로 동작함 - 전역 DkeLang 대신 이 화면 자체 상태값(_currentLanguageCode)을
  // 기준으로 판단하므로 별도 import 없이 안전하게 적용됨.
  // 기본모드(EN+KO 병기): "EN (KO)" 형태 또는 EN 굵게+KO 작게 2줄. 10개국어 선택 시: 해당 언어만 표시.
  // ============================================================================
  static const List<String> _foreignLangs = ['JA', 'ZH', 'FR', 'DE', 'RU', 'AR', 'HI', 'VI', 'ES', 'TH'];
  bool get _isForeign => _foreignLangs.contains(_currentLanguageCode.toUpperCase());
  String get _cur => _currentLanguageCode.toUpperCase();

  // (A) 인라인 "EN (KO)" 또는 선택 언어 단독 문자열 반환 (버튼/칩/힌트용)
  String _bi(Map<String, String> m) {
    if (_isForeign) return m[_cur] ?? m['EN'] ?? m['KO'] ?? '';
    return "${m['EN']} (${m['KO']})";
  }

  // (B) 다이얼로그 제목처럼 EN(굵게, gowunBatang) + KO(작게, notoSansKr) 2줄 구성.
  // 10개국어 선택 시: 번역문 하나만 단일 Text로 표시.
  List<Widget> _biLines(Map<String, String> m, {required TextStyle enStyle, TextStyle? koStyle}) {
    if (_isForeign) {
      return [
        Text(
          m[_cur] ?? m['EN'] ?? m['KO'] ?? '',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSans(textStyle: enStyle),
        ),
      ];
    }
    return [
      Text(m['EN'] ?? '', textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(textStyle: enStyle)),
      const SizedBox(height: 6),
      Text('(${m['KO']})', textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(textStyle: koStyle ?? enStyle)),
    ];
  }

  // (C) 원래 한글 단독으로만 표시되던 칩/라벨(영문 병기 없던 것들) 전용.
  // 기본모드(EN+KO 병기 상태)에서는 원본 그대로 한글만 표시(디자인 100% 유지),
  // 10개국어 선택시에만 해당 언어로 전환.
  String _koOnly(Map<String, String> m) {
    if (_isForeign) return m[_cur] ?? m['EN'] ?? m['KO'] ?? '';
    return m['KO'] ?? '';
  }

  // 🆕 [12개국어] "필수" 표시 - 라벨 뒤에 붙는 접미사
  static const Map<String, String> _requiredMap = {
    'EN': '*Required', 'KO': '*필수', 'JA': '*必須', 'ZH': '*必填', 'FR': '*Requis', 'DE': '*Erforderlich',
    'RU': '*Обязательно', 'AR': '*مطلوب', 'HI': '*आवश्यक', 'VI': '*Bắt buộc', 'ES': '*Obligatorio', 'TH': '*จำเป็น',
  };
  String get _required => _isForeign ? (_requiredMap[_cur] ?? _requiredMap['EN']!) : _requiredMap['KO']!;

  // 🆕 [12개국어] "분" (시간 단위)
  static const Map<String, String> _minuteUnitMap = {
    'EN': 'min', 'KO': '분', 'JA': '分', 'ZH': '分钟', 'FR': 'min', 'DE': 'Min',
    'RU': 'мин', 'AR': 'دقيقة', 'HI': 'मिनट', 'VI': 'phút', 'ES': 'min', 'TH': 'นาที',
  };
  String get _minuteUnit => _isForeign ? (_minuteUnitMap[_cur] ?? _minuteUnitMap['EN']!) : _minuteUnitMap['KO']!;

  // 🆕 [12개국어] 다이얼로그/버튼 텍스트 카탈로그
  static const Map<String, Map<String, String>> _dlg = {
    'continuePrompt': {
      'EN': 'Would you like to continue from where you left off?', 'KO': '이어서 학습하시겠습니까?',
      'JA': '続きから学習しますか？', 'ZH': '要从上次的地方继续吗？', 'FR': 'Voulez-vous continuer où vous en étiez ?',
      'DE': 'Möchten Sie dort weitermachen, wo Sie aufgehört haben?', 'RU': 'Хотите продолжить с того места, где остановились?',
      'AR': 'هل تريد المتابعة من حيث توقفت؟', 'HI': 'क्या आप वहीं से जारी रखना चाहते हैं जहाँ आपने छोड़ा था?',
      'VI': 'Bạn có muốn tiếp tục từ nơi đã dừng lại không?', 'ES': '¿Deseas continuar desde donde lo dejaste?', 'TH': 'คุณต้องการเรียนต่อจากที่ค้างไว้หรือไม่?',
    },
    'no': {
      'EN': 'NO', 'KO': '아니오', 'JA': 'いいえ', 'ZH': '否', 'FR': 'NON', 'DE': 'NEIN',
      'RU': 'НЕТ', 'AR': 'لا', 'HI': 'नहीं', 'VI': 'KHÔNG', 'ES': 'NO', 'TH': 'ไม่ใช่',
    },
    'yes': {
      'EN': 'YES', 'KO': '예', 'JA': 'はい', 'ZH': '是', 'FR': 'OUI', 'DE': 'JA',
      'RU': 'ДА', 'AR': 'نعم', 'HI': 'हाँ', 'VI': 'CÓ', 'ES': 'SÍ', 'TH': 'ใช่',
    },
    'stopConfirm': {
      'EN': 'Are you sure you want to stop learning?', 'KO': '학습을 중단하시겠습니까?',
      'JA': '学習を中止しますか？', 'ZH': '确定要停止学习吗？', 'FR': 'Voulez-vous vraiment arrêter d\'étudier ?',
      'DE': 'Möchten Sie das Lernen wirklich beenden?', 'RU': 'Вы уверены, что хотите прекратить обучение?',
      'AR': 'هل أنت متأكد من أنك تريد التوقف عن التعلم؟', 'HI': 'क्या आप वाकई सीखना बंद करना चाहते हैं?',
      'VI': 'Bạn có chắc muốn dừng học không?', 'ES': '¿Seguro que deseas dejar de estudiar?', 'TH': 'คุณแน่ใจหรือไม่ว่าต้องการหยุดเรียน?',
    },
    'resume': {
      'EN': 'RESUME', 'KO': '재시작', 'JA': '再開', 'ZH': '继续', 'FR': 'REPRENDRE', 'DE': 'FORTSETZEN',
      'RU': 'ПРОДОЛЖИТЬ', 'AR': 'استئناف', 'HI': 'फिर से शुरू करें', 'VI': 'TIẾP TỤC', 'ES': 'REANUDAR', 'TH': 'เริ่มต่อ',
    },
    'finish': {
      'EN': 'FINISH', 'KO': '끝내기', 'JA': '終了', 'ZH': '结束', 'FR': 'TERMINER', 'DE': 'BEENDEN',
      'RU': 'ЗАВЕРШИТЬ', 'AR': 'إنهاء', 'HI': 'समाप्त करें', 'VI': 'KẾT THÚC', 'ES': 'FINALIZAR', 'TH': 'เสร็จสิ้น',
    },
    'recordWarn': {
      'EN': 'Please leave a record of your efforts! The more records you have, the more accurate the learning analysis will be.',
      'KO': '노력의 기록을 남겨주세요! 기록이 많을 수록 학습분석이 더욱 정확해집니다.',
      'JA': '努力の記録を残してください！記録が多いほど学習分析がより正確になります。',
      'ZH': '请留下你努力的记录！记录越多，学习分析越准确。',
      'FR': 'Veuillez laisser une trace de vos efforts ! Plus vous avez d\'enregistrements, plus l\'analyse sera précise.',
      'DE': 'Bitte hinterlassen Sie einen Nachweis Ihrer Bemühungen! Je mehr Aufzeichnungen, desto genauer die Lernanalyse.',
      'RU': 'Пожалуйста, оставьте запись о своих усилиях! Чем больше записей, тем точнее анализ обучения.',
      'AR': 'يرجى ترك سجل لجهودك! كلما زادت السجلات، كان تحليل التعلم أكثر دقة.',
      'HI': 'कृपया अपने प्रयासों का रिकॉर्ड छोड़ें! जितने अधिक रिकॉर्ड होंगे, विश्लेषण उतना ही सटीक होगा।',
      'VI': 'Hãy để lại ghi chép về nỗ lực của bạn! Càng nhiều ghi chép, phân tích học tập càng chính xác.',
      'ES': '¡Deja un registro de tu esfuerzo! Cuantos más registros tengas, más preciso será el análisis.',
      'TH': 'กรุณาบันทึกความพยายามของคุณ! ยิ่งมีบันทึกมาก การวิเคราะห์การเรียนก็ยิ่งแม่นยำ',
    },
    'writeRecord': {
      'EN': 'WRITE RECORD', 'KO': '기록하기', 'JA': '記録する', 'ZH': '写记录', 'FR': 'ÉCRIRE UN RAPPORT', 'DE': 'EINTRAG SCHREIBEN',
      'RU': 'ЗАПИСАТЬ', 'AR': 'كتابة سجل', 'HI': 'रिकॉर्ड लिखें', 'VI': 'GHI LẠI', 'ES': 'ESCRIBIR REGISTRO', 'TH': 'บันทึกข้อมูล',
    },
    'completion': {
      'EN': 'Good job! You have successfully achieved your learning goals.', 'KO': '수고 하셨습니다. 학습 목표를 성공적으로 달성 하였습니다.',
      'JA': 'よく頑張りました！学習目標を達成しました。', 'ZH': '做得好！你已成功达成学习目标。',
      'FR': 'Bravo ! Vous avez atteint vos objectifs d\'apprentissage.', 'DE': 'Gut gemacht! Sie haben Ihre Lernziele erfolgreich erreicht.',
      'RU': 'Отличная работа! Вы успешно достигли своих учебных целей.', 'AR': 'أحسنت! لقد حققت أهدافك التعليمية بنجاح.',
      'HI': 'शाबाश! आपने अपने सीखने के लक्ष्य सफलतापूर्वक हासिल कर लिए हैं।', 'VI': 'Làm tốt lắm! Bạn đã đạt được mục tiêu học tập.',
      'ES': '¡Buen trabajo! Has alcanzado tus objetivos de aprendizaje.', 'TH': 'เยี่ยมมาก! คุณบรรลุเป้าหมายการเรียนสำเร็จแล้ว',
    },
    'ok': {
      'EN': 'OK', 'KO': '확인', 'JA': 'OK', 'ZH': '确定', 'FR': 'OK', 'DE': 'OK',
      'RU': 'ОК', 'AR': 'موافق', 'HI': 'ठीक है', 'VI': 'OK', 'ES': 'OK', 'TH': 'ตกลง',
    },
    'growthStep': {
      'EN': 'Record a step of your growth.\nThe more records you have, the more accurate the learning analysis will be.',
      'KO': '성장의 한 걸음을 기록해 보세요\n기록이 많을 수록 학습분석이 더욱 정확해집니다.',
      'JA': '成長の一歩を記録しましょう\n記録が多いほど学習分析がより正確になります。',
      'ZH': '记录你成长的一步\n记录越多，学习分析越准确。',
      'FR': 'Enregistrez une étape de votre progression.\nPlus vous avez d\'enregistrements, plus l\'analyse sera précise.',
      'DE': 'Halten Sie einen Schritt Ihres Wachstums fest.\nJe mehr Aufzeichnungen, desto genauer die Lernanalyse.',
      'RU': 'Запишите шаг своего роста.\nЧем больше записей, тем точнее анализ обучения.',
      'AR': 'سجّل خطوة من نموك.\nكلما زادت السجلات، كان تحليل التعلم أكثر دقة.',
      'HI': 'अपनी प्रगति का एक कदम रिकॉर्ड करें\nजितने अधिक रिकॉर्ड होंगे, विश्लेषण उतना ही सटीक होगा।',
      'VI': 'Hãy ghi lại một bước trưởng thành của bạn\nCàng nhiều ghi chép, phân tích càng chính xác.',
      'ES': 'Registra un paso de tu crecimiento.\nCuantos más registros tengas, más preciso será el análisis.',
      'TH': 'บันทึกก้าวหนึ่งของการเติบโตของคุณ\nยิ่งมีบันทึกมาก การวิเคราะห์ก็ยิ่งแม่นยำ',
    },
    'studyRecord': {
      'EN': 'STUDY RECORD', 'KO': '학습 기록 작성', 'JA': '学習記録作成', 'ZH': '撰写学习记录', 'FR': 'FICHE D\'ÉTUDE', 'DE': 'LERNPROTOKOLL',
      'RU': 'ЗАПИСЬ ОБУЧЕНИЯ', 'AR': 'سجل الدراسة', 'HI': 'अध्ययन रिकॉर्ड', 'VI': 'GHI CHÉP HỌC TẬP', 'ES': 'REGISTRO DE ESTUDIO', 'TH': 'บันทึกการเรียน',
    },
    'subject': {
      'EN': 'SUBJECT', 'KO': '과목', 'JA': '科目', 'ZH': '科目', 'FR': 'MATIÈRE', 'DE': 'FACH',
      'RU': 'ПРЕДМЕТ', 'AR': 'المادة', 'HI': 'विषय', 'VI': 'MÔN HỌC', 'ES': 'ASIGNATURA', 'TH': 'วิชา',
    },
    'recordType': {
      'EN': 'RECORD TYPE', 'KO': '기록 유형', 'JA': '記録タイプ', 'ZH': '记录类型', 'FR': 'TYPE D\'ENREGISTREMENT', 'DE': 'EINTRAGSTYP',
      'RU': 'ТИП ЗАПИСИ', 'AR': 'نوع السجل', 'HI': 'रिकॉर्ड प्रकार', 'VI': 'LOẠI GHI CHÉP', 'ES': 'TIPO DE REGISTRO', 'TH': 'ประเภทบันทึก',
    },
    'lecture': {
      'EN': 'Lecture', 'KO': '강의', 'JA': '講義', 'ZH': '讲课', 'FR': 'Cours', 'DE': 'Vorlesung',
      'RU': 'Лекция', 'AR': 'محاضرة', 'HI': 'व्याख्यान', 'VI': 'Bài giảng', 'ES': 'Clase', 'TH': 'บรรยาย',
    },
    'evaluation': {
      'EN': 'Evaluation', 'KO': '평가', 'JA': '評価', 'ZH': '评估', 'FR': 'Évaluation', 'DE': 'Bewertung',
      'RU': 'Оценка', 'AR': 'تقييم', 'HI': 'मूल्यांकन', 'VI': 'Đánh giá', 'ES': 'Evaluación', 'TH': 'ประเมิน',
    },
    'lectureType': {
      'EN': 'LECTURE TYPE', 'KO': '강의 세부 유형', 'JA': '講義の種類', 'ZH': '讲课细类', 'FR': 'TYPE DE COURS', 'DE': 'VORLESUNGSART',
      'RU': 'ТИП ЛЕКЦИИ', 'AR': 'نوع المحاضرة', 'HI': 'व्याख्यान प्रकार', 'VI': 'LOẠI BÀI GIẢNG', 'ES': 'TIPO DE CLASE', 'TH': 'ประเภทการบรรยาย',
    },
    'conceptLecture': {
      'EN': 'Concept Lecture', 'KO': '개념강의', 'JA': '概念講義', 'ZH': '概念讲解', 'FR': 'Cours théorique', 'DE': 'Konzeptvorlesung',
      'RU': 'Лекция по теории', 'AR': 'محاضرة مفاهيمية', 'HI': 'अवधारणा व्याख्यान', 'VI': 'Bài giảng khái niệm', 'ES': 'Clase teórica', 'TH': 'บรรยายแนวคิด',
    },
    'unitReview': {
      'EN': 'Unit Review & Problems', 'KO': '단원정리 및 문제해설', 'JA': '単元整理と問題解説', 'ZH': '单元整理与题目讲解', 'FR': 'Révision & Exercices',
      'DE': 'Einheit & Übungen', 'RU': 'Повторение и задачи', 'AR': 'مراجعة الوحدة وحل المسائل', 'HI': 'इकाई समीक्षा और समस्याएं',
      'VI': 'Ôn tập & Bài tập', 'ES': 'Repaso y ejercicios', 'TH': 'ทบทวนบทและโจทย์',
    },
    'details': {
      'EN': 'DETAILS', 'KO': '상세 내용', 'JA': '詳細内容', 'ZH': '详细内容', 'FR': 'DÉTAILS', 'DE': 'DETAILS',
      'RU': 'ДЕТАЛИ', 'AR': 'التفاصيل', 'HI': 'विवरण', 'VI': 'CHI TIẾT', 'ES': 'DETALLES', 'TH': 'รายละเอียด',
    },
    'detailsHint': {
      'EN': 'e.g., Solved concepts and problems.', 'KO': '예: 개념 및 문제풀이 함', 'JA': '例：概念と問題を解いた',
      'ZH': '例如：完成了概念与解题', 'FR': 'ex : Concepts et exercices résolus', 'DE': 'z. B. Konzepte und Aufgaben gelöst',
      'RU': 'напр., изучил теорию и решил задачи', 'AR': 'مثال: تم حل المفاهيم والمسائل', 'HI': 'उदा., अवधारणाएँ और समस्याएँ हल कीं',
      'VI': 'VD: Đã giải khái niệm và bài tập', 'ES': 'ej. Conceptos y ejercicios resueltos', 'TH': 'เช่น แก้แนวคิดและโจทย์แล้ว',
    },
    'score': {
      'EN': 'SCORE', 'KO': '점수', 'JA': '点数', 'ZH': '分数', 'FR': 'SCORE', 'DE': 'PUNKTZAHL',
      'RU': 'БАЛЛ', 'AR': 'الدرجة', 'HI': 'स्कोर', 'VI': 'ĐIỂM SỐ', 'ES': 'PUNTUACIÓN', 'TH': 'คะแนน',
    },
    'points': {
      'EN': 'Points', 'KO': '점', 'JA': '点', 'ZH': '分', 'FR': 'Points', 'DE': 'Punkte',
      'RU': 'баллов', 'AR': 'نقاط', 'HI': 'अंक', 'VI': 'điểm', 'ES': 'Puntos', 'TH': 'คะแนน',
    },
    'examCategory': {
      'EN': 'EXAM CATEGORY', 'KO': '시험 유형', 'JA': '試験種別', 'ZH': '考试类型', 'FR': 'TYPE D\'EXAMEN', 'DE': 'PRÜFUNGSART',
      'RU': 'ТИП ЭКЗАМЕНА', 'AR': 'نوع الاختبار', 'HI': 'परीक्षा प्रकार', 'VI': 'LOẠI KỲ THI', 'ES': 'TIPO DE EXAMEN', 'TH': 'ประเภทการสอบ',
    },
    'weeklyAssess': {
      'EN': 'Weekly Assessment', 'KO': '주평가', 'JA': '週間評価', 'ZH': '周评估', 'FR': 'Éval. hebdo', 'DE': 'Wochentest',
      'RU': 'Недельная оценка', 'AR': 'تقييم أسبوعي', 'HI': 'साप्ताहिक मूल्यांकन', 'VI': 'Đánh giá tuần', 'ES': 'Evaluación semanal', 'TH': 'ประเมินรายสัปดาห์',
    },
    'unitTest': {
      'EN': 'Unit Test', 'KO': '단원평가', 'JA': '単元テスト', 'ZH': '单元测验', 'FR': 'Contrôle d\'unité', 'DE': 'Einheitstest',
      'RU': 'Тест по разделу', 'AR': 'اختبار الوحدة', 'HI': 'इकाई परीक्षण', 'VI': 'Kiểm tra bài', 'ES': 'Examen de unidad', 'TH': 'ทดสอบบท',
    },
    'midterm': {
      'EN': 'Midterm Exam', 'KO': '중간고사', 'JA': '中間試験', 'ZH': '期中考试', 'FR': 'Examen partiel', 'DE': 'Zwischenprüfung',
      'RU': 'Промежуточный экзамен', 'AR': 'اختبار منتصف الفصل', 'HI': 'मध्यावधि परीक्षा', 'VI': 'Thi giữa kỳ', 'ES': 'Examen parcial', 'TH': 'สอบกลางภาค',
    },
    'final': {
      'EN': 'Final Exam', 'KO': '기말고사', 'JA': '期末試験', 'ZH': '期末考试', 'FR': 'Examen final', 'DE': 'Abschlussprüfung',
      'RU': 'Итоговый экзамен', 'AR': 'اختبار نهائي', 'HI': 'अंतिम परीक्षा', 'VI': 'Thi cuối kỳ', 'ES': 'Examen final', 'TH': 'สอบปลายภาค',
    },
    'mock': {
      'EN': 'Mock Exam', 'KO': '모의고사', 'JA': '模擬試験', 'ZH': '模拟考试', 'FR': 'Examen blanc', 'DE': 'Probeprüfung',
      'RU': 'Пробный экзамен', 'AR': 'اختبار تجريبي', 'HI': 'मॉक परीक्षा', 'VI': 'Thi thử', 'ES': 'Examen simulacro', 'TH': 'สอบจำลอง',
    },
    'bigUnit': {
      'EN': 'Big Unit', 'KO': '대단원', 'JA': '大単元', 'ZH': '大单元', 'FR': 'Grande unité', 'DE': 'Hauptkapitel',
      'RU': 'Раздел', 'AR': 'الوحدة الكبرى', 'HI': 'बड़ी इकाई', 'VI': 'Chương lớn', 'ES': 'Unidad principal', 'TH': 'บทใหญ่',
    },
    'midUnit': {
      'EN': 'Mid Unit', 'KO': '중단원', 'JA': '中単元', 'ZH': '中单元', 'FR': 'Sous-unité', 'DE': 'Unterkapitel',
      'RU': 'Подраздел', 'AR': 'الوحدة الفرعية', 'HI': 'मध्य इकाई', 'VI': 'Chương nhỏ', 'ES': 'Subunidad', 'TH': 'บทย่อย',
    },
    'multiSelectHint': {
      'EN': 'multi-select', 'KO': '복수 선택 가능', 'JA': '複数選択可', 'ZH': '可多选', 'FR': 'choix multiple', 'DE': 'Mehrfachauswahl',
      'RU': 'можно выбрать несколько', 'AR': 'اختيار متعدد', 'HI': 'बहु-चयन', 'VI': 'chọn nhiều', 'ES': 'selección múltiple', 'TH': 'เลือกได้หลายข้อ',
    },
    'mockMonth': {
      'EN': 'MOCK EXAM MONTH', 'KO': '몇 월 모의고사', 'JA': '模試の月', 'ZH': '模拟考试月份', 'FR': 'MOIS DE L\'EXAMEN BLANC',
      'DE': 'MONAT DER PROBEPRÜFUNG', 'RU': 'МЕСЯЦ ПРОБНОГО ЭКЗАМЕНА', 'AR': 'شهر الاختبار التجريبي', 'HI': 'मॉक परीक्षा का महीना',
      'VI': 'THÁNG THI THỬ', 'ES': 'MES DEL SIMULACRO', 'TH': 'เดือนที่สอบจำลอง',
    },
    'mockMonthHint': {
      'EN': 'e.g., June', 'KO': '예: 6월', 'JA': '例：6月', 'ZH': '例如：6月', 'FR': 'ex : Juin', 'DE': 'z. B. Juni',
      'RU': 'напр., июнь', 'AR': 'مثال: يونيو', 'HI': 'उदा., जून', 'VI': 'VD: Tháng 6', 'ES': 'ej. Junio', 'TH': 'เช่น มิถุนายน',
    },
    'mockRank': {
      'EN': 'GRADE OR RANK', 'KO': '등급 또는 석차', 'JA': '等級または順位', 'ZH': '等级或名次', 'FR': 'NIVEAU OU RANG',
      'DE': 'NOTE ODER RANG', 'RU': 'УРОВЕНЬ ИЛИ РЕЙТИНГ', 'AR': 'الدرجة أو الترتيب', 'HI': 'ग्रेड या रैंक',
      'VI': 'HẠNG HOẶC XẾP HẠNG', 'ES': 'NIVEL O RANGO', 'TH': 'เกรดหรืออันดับ',
    },
    'mockRankHint': {
      'EN': 'e.g., Grade 1', 'KO': '예: 1등급', 'JA': '例：1等級', 'ZH': '例如：1级', 'FR': 'ex : Niveau 1', 'DE': 'z. B. Note 1',
      'RU': 'напр., 1 уровень', 'AR': 'مثال: الدرجة 1', 'HI': 'उदा., ग्रेड 1', 'VI': 'VD: Hạng 1', 'ES': 'ej. Nivel 1', 'TH': 'เช่น เกรด 1',
    },
    'grade': {
      'EN': 'GRADE', 'KO': '학년', 'JA': '学年', 'ZH': '年级', 'FR': 'NIVEAU SCOLAIRE', 'DE': 'KLASSENSTUFE',
      'RU': 'КЛАСС', 'AR': 'الصف الدراسي', 'HI': 'कक्षा', 'VI': 'LỚP', 'ES': 'GRADO', 'TH': 'ชั้นปี',
    },
    'gradeWord': {
      'EN': 'Grade', 'KO': '학년', 'JA': '学年', 'ZH': '年级', 'FR': 'Niveau', 'DE': 'Klasse',
      'RU': 'Класс', 'AR': 'الصف', 'HI': 'कक्षा', 'VI': 'Lớp', 'ES': 'Grado', 'TH': 'ชั้นปี',
    },
    'semesterLabel': {
      'EN': 'SEMESTER', 'KO': '학기', 'JA': '学期', 'ZH': '学期', 'FR': 'SEMESTRE', 'DE': 'SEMESTER',
      'RU': 'СЕМЕСТР', 'AR': 'الفصل الدراسي', 'HI': 'सेमेस्टर', 'VI': 'HỌC KỲ', 'ES': 'SEMESTRE', 'TH': 'ภาคเรียน',
    },
    'semester1': {
      'EN': 'Semester 1', 'KO': '1학기', 'JA': '1学期', 'ZH': '第一学期', 'FR': 'Semestre 1', 'DE': 'Semester 1',
      'RU': 'Семестр 1', 'AR': 'الفصل 1', 'HI': 'सेमेस्टर 1', 'VI': 'Học kỳ 1', 'ES': 'Semestre 1', 'TH': 'ภาคเรียนที่ 1',
    },
    'semester2': {
      'EN': 'Semester 2', 'KO': '2학기', 'JA': '2学期', 'ZH': '第二学期', 'FR': 'Semestre 2', 'DE': 'Semester 2',
      'RU': 'Семестр 2', 'AR': 'الفصل 2', 'HI': 'सेमेस्टर 2', 'VI': 'Học kỳ 2', 'ES': 'Semestre 2', 'TH': 'ภาคเรียนที่ 2',
    },
    'incorrectNoteStatus': {
      'EN': 'INCORRECT NOTE STATUS', 'KO': '오답노트 상태', 'JA': '誤答ノート状態', 'ZH': '错题本状态', 'FR': 'STATUT DU CAHIER D\'ERREURS',
      'DE': 'FEHLERNOTIZ-STATUS', 'RU': 'СТАТУС ЗАПИСИ ОШИБОК', 'AR': 'حالة دفتر الأخطاء', 'HI': 'गलत उत्तर नोट स्थिति',
      'VI': 'TRẠNG THÁI SỔ TAY SAI', 'ES': 'ESTADO DEL CUADERNO DE ERRORES', 'TH': 'สถานะสมุดข้อผิดพลาด',
    },
    'completed': {
      'EN': 'COMPLETED', 'KO': '정리함', 'JA': '整理済み', 'ZH': '已整理', 'FR': 'TERMINÉ', 'DE': 'ERLEDIGT',
      'RU': 'ЗАВЕРШЕНО', 'AR': 'تم الإنجاز', 'HI': 'पूर्ण किया गया', 'VI': 'ĐÃ HOÀN THÀNH', 'ES': 'COMPLETADO', 'TH': 'จัดการแล้ว',
    },
    'notYet': {
      'EN': 'NOT YET', 'KO': '정리 안함', 'JA': '未整理', 'ZH': '未整理', 'FR': 'PAS ENCORE', 'DE': 'NOCH NICHT',
      'RU': 'ЕЩЁ НЕТ', 'AR': 'ليس بعد', 'HI': 'अभी नहीं', 'VI': 'CHƯA', 'ES': 'AÚN NO', 'TH': 'ยังไม่จัดการ',
    },
    'understanding': {
      'EN': 'UNDERSTANDING', 'KO': '이해도', 'JA': '理解度', 'ZH': '理解程度', 'FR': 'COMPRÉHENSION', 'DE': 'VERSTÄNDNIS',
      'RU': 'ПОНИМАНИЕ', 'AR': 'مستوى الفهم', 'HI': 'समझ', 'VI': 'MỨC ĐỘ HIỂU', 'ES': 'COMPRENSIÓN', 'TH': 'ความเข้าใจ',
    },
    'difficulty': {
      'EN': 'DIFFICULTY', 'KO': '난이도', 'JA': '難易度', 'ZH': '难度', 'FR': 'DIFFICULTÉ', 'DE': 'SCHWIERIGKEIT',
      'RU': 'СЛОЖНОСТЬ', 'AR': 'مستوى الصعوبة', 'HI': 'कठिनाई', 'VI': 'ĐỘ KHÓ', 'ES': 'DIFICULTAD', 'TH': 'ความยาก',
    },
    'veryHard': {
      'EN': 'Very Hard', 'KO': '매우어려움', 'JA': '非常に難しい', 'ZH': '非常难', 'FR': 'Très difficile', 'DE': 'Sehr schwer',
      'RU': 'Очень сложно', 'AR': 'صعب جدًا', 'HI': 'बहुत कठिन', 'VI': 'Rất khó', 'ES': 'Muy difícil', 'TH': 'ยากมาก',
    },
    'hard': {
      'EN': 'Hard', 'KO': '어려움', 'JA': '難しい', 'ZH': '难', 'FR': 'Difficile', 'DE': 'Schwer',
      'RU': 'Сложно', 'AR': 'صعب', 'HI': 'कठिन', 'VI': 'Khó', 'ES': 'Difícil', 'TH': 'ยาก',
    },
    'normal': {
      'EN': 'Normal', 'KO': '보통', 'JA': '普通', 'ZH': '一般', 'FR': 'Normal', 'DE': 'Normal',
      'RU': 'Средне', 'AR': 'متوسط', 'HI': 'सामान्य', 'VI': 'Bình thường', 'ES': 'Normal', 'TH': 'ปานกลาง',
    },
    'easy': {
      'EN': 'Easy', 'KO': '쉬움', 'JA': '簡単', 'ZH': '容易', 'FR': 'Facile', 'DE': 'Leicht',
      'RU': 'Легко', 'AR': 'سهل', 'HI': 'आसान', 'VI': 'Dễ', 'ES': 'Fácil', 'TH': 'ง่าย',
    },
    'concentration': {
      'EN': 'CONCENTRATION', 'KO': '집중도', 'JA': '集中度', 'ZH': '专注度', 'FR': 'CONCENTRATION', 'DE': 'KONZENTRATION',
      'RU': 'КОНЦЕНТРАЦИЯ', 'AR': 'مستوى التركيز', 'HI': 'एकाग्रता', 'VI': 'MỨC ĐỘ TẬP TRUNG', 'ES': 'CONCENTRACIÓN', 'TH': 'สมาธิ',
    },
    'high': {
      'EN': 'High', 'KO': '높음', 'JA': '高い', 'ZH': '高', 'FR': 'Élevé', 'DE': 'Hoch',
      'RU': 'Высокая', 'AR': 'مرتفع', 'HI': 'उच्च', 'VI': 'Cao', 'ES': 'Alta', 'TH': 'สูง',
    },
    'low': {
      'EN': 'Low', 'KO': '낮음', 'JA': '低い', 'ZH': '低', 'FR': 'Faible', 'DE': 'Niedrig',
      'RU': 'Низкая', 'AR': 'منخفض', 'HI': 'कम', 'VI': 'Thấp', 'ES': 'Baja', 'TH': 'ต่ำ',
    },
    'learningCondition': {
      'EN': 'LEARNING CONDITION', 'KO': '학습 컨디션', 'JA': '学習コンディション', 'ZH': '学习状态', 'FR': 'CONDITION D\'ÉTUDE',
      'DE': 'LERNZUSTAND', 'RU': 'СОСТОЯНИЕ ОБУЧЕНИЯ', 'AR': 'حالة الاستعداد للدراسة', 'HI': 'अध्ययन स्थिति',
      'VI': 'TÌNH TRẠNG HỌC TẬP', 'ES': 'CONDICIÓN DE ESTUDIO', 'TH': 'สภาพการเรียน',
    },
    'good': {
      'EN': 'Good', 'KO': '좋음', 'JA': '良い', 'ZH': '好', 'FR': 'Bien', 'DE': 'Gut',
      'RU': 'Хорошо', 'AR': 'جيد', 'HI': 'अच्छा', 'VI': 'Tốt', 'ES': 'Bien', 'TH': 'ดี',
    },
    'tired': {
      'EN': 'Tired', 'KO': '피곤함', 'JA': '疲れた', 'ZH': '疲惫', 'FR': 'Fatigué', 'DE': 'Müde',
      'RU': 'Устал', 'AR': 'متعب', 'HI': 'थका हुआ', 'VI': 'Mệt mỏi', 'ES': 'Cansado', 'TH': 'เหนื่อย',
    },
    'nextGoal': {
      'EN': 'NEXT GOAL', 'KO': '다음 목표', 'JA': '次の目標', 'ZH': '下一个目标', 'FR': 'PROCHAIN OBJECTIF', 'DE': 'NÄCHSTES ZIEL',
      'RU': 'СЛЕДУЮЩАЯ ЦЕЛЬ', 'AR': 'الهدف التالي', 'HI': 'अगला लक्ष्य', 'VI': 'MỤC TIÊU TIẾP THEO', 'ES': 'SIGUIENTE OBJETIVO', 'TH': 'เป้าหมายถัดไป',
    },
    'nextGoalHint': {
      'EN': 'e.g., Advanced function problems', 'KO': '예: 함수 심화문제', 'JA': '例：関数の応用問題', 'ZH': '例如：函数深化题目',
      'FR': 'ex : Problèmes avancés de fonctions', 'DE': 'z. B. Fortgeschrittene Funktionsaufgaben',
      'RU': 'напр., сложные задачи по функциям', 'AR': 'مثال: مسائل متقدمة في الدوال', 'HI': 'उदा., फ़ंक्शन के उन्नत प्रश्न',
      'VI': 'VD: Bài tập hàm số nâng cao', 'ES': 'ej. Problemas avanzados de funciones', 'TH': 'เช่น โจทย์ฟังก์ชันขั้นสูง',
    },
    'saveRecord': {
      'EN': 'SAVE RECORD', 'KO': '성장 데이터 저장', 'JA': '成長データ保存', 'ZH': '保存成长数据', 'FR': 'ENREGISTRER LES DONNÉES', 'DE': 'DATEN SPEICHERN',
      'RU': 'СОХРАНИТЬ ДАННЫЕ', 'AR': 'حفظ بيانات النمو', 'HI': 'रिकॉर्ड सहेजें', 'VI': 'LƯU DỮ LIỆU', 'ES': 'GUARDAR DATOS', 'TH': 'บันทึกข้อมูลการเติบโต',
    },
    'nextSubjectTitle': {
      'EN': 'Set your next learning subject and target time.\nPlanned learning is the beginning of steady growth.',
      'KO': '다음 학습 과목과 목표 시간을 설정해 보세요\n계획적인 학습은 꾸준한 성장의 시작입니다.',
      'JA': '次の学習科目と目標時間を設定しましょう\n計画的な学習は着実な成長の始まりです。',
      'ZH': '设置下一个学习科目和目标时间吧\n有计划的学习是稳步成长的开始。',
      'FR': 'Définissez votre prochaine matière et votre temps cible.\nUn apprentissage planifié est le début d\'une croissance régulière.',
      'DE': 'Legen Sie Ihr nächstes Lernfach und Ihre Zielzeit fest.\nGeplantes Lernen ist der Beginn stetigen Wachstums.',
      'RU': 'Задайте следующий предмет и целевое время.\nПланомерное обучение - начало устойчивого роста.',
      'AR': 'حدد مادتك التالية ووقتك المستهدف.\nالتعلم المخطط هو بداية النمو المستمر.',
      'HI': 'अपना अगला विषय और लक्ष्य समय निर्धारित करें\nसुनियोजित अध्ययन निरंतर विकास की शुरुआत है।',
      'VI': 'Hãy đặt môn học và thời gian mục tiêu tiếp theo\nHọc tập có kế hoạch là khởi đầu của sự phát triển bền vững.',
      'ES': 'Establece tu próxima materia y tiempo objetivo.\nEl aprendizaje planificado es el inicio de un crecimiento constante.',
      'TH': 'ตั้งวิชาถัดไปและเวลาเป้าหมายของคุณ\nการเรียนอย่างมีแผนคือจุดเริ่มต้นของการเติบโตที่มั่นคง',
    },
    'startFocus': {
      'EN': 'START FOCUS', 'KO': '공부 시작', 'JA': '集中開始', 'ZH': '开始学习', 'FR': 'COMMENCER', 'DE': 'STARTEN',
      'RU': 'НАЧАТЬ', 'AR': 'ابدأ التركيز', 'HI': 'शुरू करें', 'VI': 'BẮT ĐẦU', 'ES': 'EMPEZAR', 'TH': 'เริ่มเรียน',
    },
    'pauseBtn': {
      'EN': 'PAUSE', 'KO': '일시 중지', 'JA': '一時停止', 'ZH': '暂停', 'FR': 'PAUSE', 'DE': 'PAUSE',
      'RU': 'ПАУЗА', 'AR': 'إيقاف مؤقت', 'HI': 'रोकें', 'VI': 'TẠM DỪNG', 'ES': 'PAUSA', 'TH': 'หยุดชั่วคราว',
    },
    'realtimeFocusMode': {
      'EN': 'Real-time Focus Mode', 'KO': '실시간 집중 모드', 'JA': 'リアルタイム集中モード', 'ZH': '实时专注模式',
      'FR': 'Mode concentration en direct', 'DE': 'Echtzeit-Fokusmodus', 'RU': 'Режим концентрации в реальном времени',
      'AR': 'وضع التركيز الفوري', 'HI': 'रीयल-टाइम फोकस मोड', 'VI': 'Chế độ tập trung trực tiếp', 'ES': 'Modo enfoque en tiempo real', 'TH': 'โหมดสมาธิเรียลไทม์',
    },
    'targetLabel': {
      'EN': 'Target', 'KO': '목표', 'JA': '目標', 'ZH': '目标', 'FR': 'Objectif', 'DE': 'Ziel',
      'RU': 'Цель', 'AR': 'الهدف', 'HI': 'लक्ष्य', 'VI': 'Mục tiêu', 'ES': 'Objetivo', 'TH': 'เป้าหมาย',
    },
    'targetTimeLabel': {
      'EN': 'Target Time', 'KO': '목표 시간', 'JA': '目標時間', 'ZH': '目标时间', 'FR': 'Temps cible', 'DE': 'Zielzeit',
      'RU': 'Целевое время', 'AR': 'الوقت المستهدف', 'HI': 'लक्ष्य समय', 'VI': 'Thời gian mục tiêu', 'ES': 'Tiempo objetivo', 'TH': 'เวลาเป้าหมาย',
    },
    'liveStars': {
      'EN': 'Live Stars', 'KO': '실시간 별', 'JA': 'リアルタイムスター', 'ZH': '实时星星', 'FR': 'Étoiles en direct', 'DE': 'Live-Sterne',
      'RU': 'Звёзды в реальном времени', 'AR': 'النجوم الفورية', 'HI': 'लाइव सितारे', 'VI': 'Sao trực tiếp', 'ES': 'Estrellas en vivo', 'TH': 'ดาวเรียลไทม์',
    },
    'starsCountUnit': {
      'EN': '', 'KO': '개', 'JA': '個', 'ZH': '颗', 'FR': '', 'DE': '',
      'RU': '', 'AR': '', 'HI': '', 'VI': '', 'ES': '', 'TH': 'ดวง',
    },
    'starsEarned': {
      'EN': 'stars earned.', 'KO': '개의 별을 획득했습니다.', 'JA': '個の星を獲得しました。', 'ZH': '颗星星。', 'FR': 'étoiles gagnées.', 'DE': 'Sterne verdient.',
      'RU': 'звёзд получено.', 'AR': 'نجوم تم كسبها.', 'HI': 'सितारे अर्जित किए।', 'VI': 'ngôi sao nhận được.', 'ES': 'estrellas ganadas.', 'TH': 'ดาวที่ได้รับ',
    },
    'cumulative': {
      'EN': 'Total', 'KO': '누적', 'JA': '累積', 'ZH': '累计', 'FR': 'Total', 'DE': 'Gesamt',
      'RU': 'Всего', 'AR': 'الإجمالي', 'HI': 'कुल', 'VI': 'Tổng cộng', 'ES': 'Total', 'TH': 'สะสม',
    },
    'leaveWarnTitle': {
      'EN': 'Please Stay on This Screen', 'KO': '이 화면에 머물러 주세요',
      'JA': 'この画面にとどまってください', 'ZH': '请留在此屏幕', 'FR': 'Veuillez rester sur cet écran',
      'DE': 'Bitte bleiben Sie auf diesem Bildschirm', 'RU': 'Пожалуйста, оставайтесь на этом экране',
      'AR': 'يرجى البقاء في هذه الشاشة', 'HI': 'कृपया इसी स्क्रीन पर बने रहें',
      'VI': 'Vui lòng ở lại màn hình này', 'ES': 'Por favor, permanece en esta pantalla', 'TH': 'กรุณาอยู่ที่หน้าจอนี้',
    },
    'leaveWarnBody': {
      'EN': 'Leaving this screen or switching apps while studying may cause your progress to be lost. For a safe, uninterrupted session, please keep this screen open until you finish.',
      'KO': '학습 중 다른 화면으로 이동하거나 다른 앱을 사용하면 진행 상황이 사라질 수 있어요. 안전한 학습을 위해 끝날 때까지 이 화면을 열어 두어 주세요.',
      'JA': '学習中に他の画面へ移動したり他のアプリを使用すると、進行状況が失われることがあります。安全に学習するため、終わるまでこの画面を開いたままにしてください。',
      'ZH': '学习过程中切换画面或使用其他应用可能导致进度丢失。为了安全学习，请在结束前保持此画面开启。',
      'FR': 'Quitter cet écran ou changer d\'application pendant l\'étude peut entraîner la perte de votre progression. Pour une session sûre et ininterrompue, veuillez garder cet écran ouvert jusqu\'à la fin.',
      'DE': 'Das Verlassen dieses Bildschirms oder der Wechsel der App während des Lernens kann zum Verlust Ihres Fortschritts führen. Bitte lassen Sie diesen Bildschirm bis zum Ende geöffnet.',
      'RU': 'Уход с этого экрана или переключение приложений во время учёбы может привести к потере прогресса. Для безопасного занятия держите этот экран открытым до конца.',
      'AR': 'قد يؤدي ترك هذه الشاشة أو التبديل بين التطبيقات أثناء الدراسة إلى فقدان تقدمك. للحصول على جلسة آمنة وغير منقطعة، يرجى إبقاء هذه الشاشة مفتوحة حتى الانتهاء.',
      'HI': 'अध्ययन के दौरान इस स्क्रीन को छोड़ने या ऐप बदलने से आपकी प्रगति खो सकती है। सुरक्षित और निर्बाध सत्र के लिए, कृपया समाप्त होने तक इस स्क्रीन को खुला रखें।',
      'VI': 'Rời khỏi màn hình này hoặc chuyển sang ứng dụng khác trong khi học có thể làm mất tiến trình của bạn. Để có một buổi học an toàn, không bị gián đoạn, vui lòng giữ màn hình này mở cho đến khi kết thúc.',
      'ES': 'Salir de esta pantalla o cambiar de aplicación mientras estudias puede hacer que se pierda tu progreso. Para una sesión segura e ininterrumpida, mantén esta pantalla abierta hasta terminar.',
      'TH': 'การออกจากหน้าจอนี้หรือสลับแอปขณะเรียนอาจทำให้ความคืบหน้าหายไป เพื่อการเรียนที่ปลอดภัยและไม่สะดุด กรุณาเปิดหน้าจอนี้ไว้จนกว่าจะเสร็จสิ้น',
    },
    'gotIt': {
      'EN': 'Got It', 'KO': '확인했습니다', 'JA': '了解しました', 'ZH': '知道了', 'FR': 'Compris', 'DE': 'Verstanden',
      'RU': 'Понятно', 'AR': 'حسنًا', 'HI': 'समझ गया', 'VI': 'Đã hiểu', 'ES': 'Entendido', 'TH': 'เข้าใจแล้ว',
    },
  };

  @override
  void initState() {
    super.initState();
    // 🆕 [데이터 보호 2026-09-02] 앱이 백그라운드로 가는 순간(최근 앱 화면 등)을 감지하기 위해 등록.
    WidgetsBinding.instance.addObserver(this);
    _totalSeconds = widget.selectedDurationMinutes * 60; // 🆕 [버그 수정 2026-07-29] 1초=1분 테스트모드 폐기, 정상적으로 분→초 변환

    // 초기값 셋팅
    _currentUniversity = widget.targetUniversity;
    _currentIsVip = widget.isVipMember;

    // 타임라인 초기화
    _currentSelectedDate = DateTime.now();
    _updateActiveTimeline();

    tz.initializeTimeZones();
    _timerAudioPlayer = AudioPlayer();
    _timerAudioPlayer.setReleaseMode(ReleaseMode.loop);
    _cueAudioPlayer = AudioPlayer(); // [추가]

    // 🆕 [버그 수정] 시험 일정을 SharedPreferences에 실제로 저장.
    // 기존엔 targetExamDate/needTimelineGen 등이 이 화면의 파라미터로만 존재하고 저장이 안 되어서,
    // planning_screen.dart의 학사 타임라인과 home_dashboard_screen.dart의 D-day 팝업이
    // 둘 다 "시험 일정 없음" 상태로 판정되어 아예 동작하지 않았음.
    _persistExamScheduleToPrefs();

    // ⚡ [0초 정각 초강력 동기화 트리거]: 화면이 픽셀로 안착하자마자 기기 저장 데이터를 강제 복원
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _forceSyncSavedDataOnStartup();
      _checkResumeInterceptionData();
    });
  }

  // 🆕 [버그 수정] planning_screen.dart / home_dashboard_screen.dart가 읽는 것과 동일한 키로 저장.
  // 이 저장이 빠져있어서 D-day 팝업이 조건상 항상 "시험 일정 없음"으로 판정되고 있었음.
  Future<void> _persistExamScheduleToPrefs() async {
    if (widget.targetExamDate == null) return; // 시험 일정 없이 들어온 일반 학습 세션이면 저장하지 않음
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gke_selected_exam_type', widget.dynamicTestTitle);
      await prefs.setString('gke_exam_start_date', widget.targetExamDate!.toIso8601String());
      if (widget.targetExamEndDate != null) {
        await prefs.setString('gke_exam_end_date', widget.targetExamEndDate!.toIso8601String());
      }
      await prefs.setString('gke_exam_prep_period', widget.prepPeriodStr);
      await prefs.setBool('gke_exam_timeline_enabled', widget.needTimelineGen);
    } catch (e) {
      debugPrint("[TimerScreen] 시험 일정 저장 실패: $e");
    }
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _currentSelectedDate = newDate;
      _updateActiveTimeline();
    });
  }

  void _updateActiveTimeline() {
    _activeTimeline = StudyTimelines.getTimelineForDate(
      _currentSelectedDate,
      widget.targetExamDate ?? DateTime.now(),
      isFinalExam: widget.isFinalExamMode, // [수정] 기말고사 버그 수정
    );
  }

  // 👑 🎯 요구사항 완전 해결 장치: 앱을 완전히 껐다 켜도 마이페이지 데이터 백업 세션을 100% 즉시 복원하는 유일한 마스터 스케줄러
  Future<void> _forceSyncSavedDataOnStartup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedUniv = prefs.getString('saved_target_university');
      final String savedLang = prefs.getString('saved_language_code') ?? 'ko';
      final bool savedVipStatus = prefs.getBool('saved_vip_status') ?? widget.isVipMember;

      if (!mounted) return;

      setState(() {
        if (savedUniv != null && savedUniv.isNotEmpty) {
          _currentUniversity = savedUniv;
        }
        _currentLanguageCode = savedLang;
        _currentIsVip = savedVipStatus; // 👈 껐다 켜도 마이페이지 VIP 인증 내역을 완벽하게 계승
      });
    } catch (e) {
      debugPrint("앱 기동 즉시 저장소 강제 복원 에러: $e");
    }
  }

  Future<void> _checkResumeInterceptionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? tempSubject = prefs.getString('dke_temp_subject');
      final int? tempSeconds = prefs.getInt('dke_temp_elapsed');

      if (tempSubject == widget.selectedSubject && tempSeconds != null && tempSeconds > 0) {
        const Color brandGolden = Color(0xFFE5C158);
        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0D1527),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Column(
              children: _biLines(
                _dlg['continuePrompt']!,
                enStyle: TextStyle(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 16),
                koStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              Navigator.canPop(context) ? ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () async {
                  await prefs.remove('dke_temp_subject');
                  await prefs.remove('dke_temp_elapsed');
                  Navigator.of(context).pop();
                },
                child: Text(_bi(_dlg['no']!), style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold)),
              ) : const SizedBox.shrink(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: brandGolden, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () {
                  setState(() {
                    _elapsedSeconds = tempSeconds;
                    progressPercent = _elapsedSeconds / _totalSeconds;
                    _animationCycleSeconds = _elapsedSeconds % 630;
                    if (_animationCycleSeconds < 30) {
                      _showVipOverlay = true;
                    }
                  });
                  Navigator.of(context).pop();
                },
                child: Text(_bi(_dlg['yes']!), style: GoogleFonts.gowunBatang(color: const Color(0xFF030712), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint("임시저장 추적 오류: $e");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSavedUniversity();
  }

  Future<void> _loadSavedUniversity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedUniv = prefs.getString('saved_target_university');
      final String savedLang = prefs.getString('saved_language_code') ?? 'ko';
      final bool savedVipStatus = prefs.getBool('saved_vip_status') ?? widget.isVipMember;

      if (savedUniv != null && savedUniv.isNotEmpty) {
        if (_currentUniversity != savedUniv || _currentLanguageCode != savedLang || _currentIsVip != savedVipStatus) {
          setState(() {
            _currentUniversity = savedUniv;
            _currentLanguageCode = savedLang;
            _currentIsVip = savedVipStatus;
          });
        }
      }
    } catch (e) {
      debugPrint("저장소 대학명 로드 에러: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 🆕 [데이터 보호] 감시 해제
    _timer?.cancel();
    _timerAudioPlayer.stop();
    _timerAudioPlayer.dispose();
    _cueAudioPlayer.dispose(); // [추가]
    super.dispose();
  }

  // ============================================================================
  // 🆕 [데이터 보호 2026-09-02] 최근 앱(멀티태스킹) 화면으로 나가거나, 다른 앱으로
  // 전환되거나, 화면이 꺼지는 등 "이 화면이 더 이상 최상단에서 보이지 않는 순간"을
  // 감지합니다. 이때 타이머를 자동으로 멈추고(=몰래 계속 흐르지 않게), 진행 상황을
  // SharedPreferences에 즉시 저장해둡니다. 복귀했을 때는 자동으로 다시 흐르지 않고,
  // 사용자가 직접 "START FOCUS/PAUSE" 버튼을 눌러야만 다시 작동합니다
  // (검색하거나 다른 앱을 쓰면서 몰래 타이머만 흘러가는 것을 방지).
  // ============================================================================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _autoPauseAndSaveOnLeave();
    }
  }

  Future<void> _autoPauseAndSaveOnLeave() async {
    if (!_isRunning) return; // 이미 멈춰있으면 할 일 없음
    _timer?.cancel();
    setState(() => _isRunning = false);
    await _timerAudioPlayer.pause();
    _animKey.currentState?.pauseEngine();
    await _persistTempProgress(); // 🆕 프로세스가 완전히 종료되는 최악의 경우에도 대비해 즉시 저장
  }

  // 🆕 [데이터 보호] "이어서 학습" 기능이 이미 조회하는 것과 동일한 키에 저장 →
  // 다음에 같은 과목으로 다시 들어오면 자동으로 "이어서 하시겠습니까?" 안내가 뜸.
  Future<void> _persistTempProgress() async {
    if (_elapsedSeconds <= 0) return; // 아직 시작 안 했으면 저장할 것 없음
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dke_temp_subject', widget.selectedSubject);
      await prefs.setInt('dke_temp_elapsed', _elapsedSeconds);
    } catch (e) {
      debugPrint("[TimerScreen] 임시저장 실패: $e");
    }
  }

  // 🆕 [데이터 보호 2026-09-02] 뒤로가기(< 버튼, 스와이프 등) 눌렀을 때, 화면이 그냥
  // 사라지기 전에 먼저 진행 상황을 저장합니다. 저장이 끝난 뒤에 실제로 화면을 닫습니다.
  Future<void> _handleBackPressed() async {
    await _persistTempProgress();
    if (mounted) Navigator.of(context).pop();
  }

  // 👑 🎯 10분 주기 무한 루프 제어 엔진 교차 검증 완료판
  void _runVipStarStrictRotationEngine() {
    if (!_currentIsVip) return; // 👈 실시간 영구 연동 변수로 전면 전환 보호막 장착

    _animationCycleSeconds++;

    if (_animationCycleSeconds == 1) {
      setState(() {
        _showVipOverlay = true;
      });
      _animKey.currentState?.resetAndPlay();
    }
    else if (_animationCycleSeconds == 30) {
      setState(() {
        _showVipOverlay = false;
      });
    }
    else if (_animationCycleSeconds >= 630) {
      _animationCycleSeconds = 0;
    }
  }

  // ============================================================================
  // 🆕 [별 경제 시스템] 실시간 자동 별 적립 체크.
  // Timer.periodic 1초 틱마다 호출되며, DkeStars.starAccrualInterval(지금 1초, 실사용 시 1분)에
  // 도달할 때마다 별 1개를 즉시 DkeStars에 저장합니다. 30분 몰아서 저장하지 않고 그때그때 저장하므로
  // 앱이 중간에 꺼져도 이미 적립된 별은 안전합니다.
  // ============================================================================
  void _checkAndAccrueStar() {
    _secondsSinceLastStarAccrual++;
    final int intervalSeconds = DkeStars.starAccrualInterval.inSeconds;
    if (intervalSeconds <= 0) return;

    if (_secondsSinceLastStarAccrual >= intervalSeconds) {
      _secondsSinceLastStarAccrual = 0;
      _starsEarnedThisSession += 1;
      // 저장 자체는 비동기로 흘려보내되(화면 끊김 없게), 실패해도 다음 틱에서 계속 누적되므로 안전.
      DkeStars.addStars(1, subject: widget.selectedSubject);
    }
  }

  // ============================================================================
  // 🆕 [알람 순서 보장] 학습 시작 알림음(start_bell.mp3, 13초)이 실제로 "재생 완료"될 때까지
  // 이벤트 기반으로 기다린 뒤, 다음 단계(백색소음 재생)로 넘어가는 헬퍼.
  // 기존엔 고정된 ms(600ms)만큼 기다렸다가 넘어가서, 벨소리 파일 실제 길이와 안 맞으면
  // 백색소음이 벨소리를 덮어버리거나(너무 짧게 기다림) 어색한 정적이 생기는(너무 길게 기다림) 문제가 있었음.
  // onPlayerComplete 이벤트를 직접 기다리므로 벨소리 파일 길이가 바뀌어도 항상 정확히 이어짐.
  // 혹시 이벤트가 발생하지 않는 예외 상황을 대비해 최대 15초 안전장치(timeout)를 둠.
  // ============================================================================
  Future<void> _playStartBellAndWait() async {
    try {
      final Completer<void> completer = Completer<void>();
      late final StreamSubscription<void> sub;
      sub = _cueAudioPlayer.onPlayerComplete.listen((event) {
        sub.cancel();
        if (!completer.isCompleted) completer.complete();
      });

      await _cueAudioPlayer.play(AssetSource('sounds/start_bell.mp3'));

      // 혹시 onPlayerComplete가 발생하지 않는 예외 상황 대비, 안전장치(timeout).
      // start_bell.mp3가 13초이므로 그보다 넉넉한 15초로 설정 (너무 짧으면 정상 재생 중에도 잘릴 위험).
      await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          sub.cancel();
        },
      );
    } catch (e) {
      debugPrint("시작 알림음 재생 대기 오류: $e");
    }
  }

  // ============================================================================
  // 🆕 [고급스러운 안내 팝업 2026-09-02] 학습을 처음 시작할 때 한 번 보여주는
  // 우아한 안내창. 골드 테두리 + 은은한 아이콘으로 앱의 다크 네이비/골드 톤과
  // 통일된 디자인이며, 12개국어를 모두 지원함.
  // ============================================================================
  Future<void> _showLeaveWarningDialog() async {
    const Color brandGolden = Color(0xFFE5C158);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF11192E), Color(0xFF0A0F1E)]),
            border: Border.all(color: brandGolden.withOpacity(0.5), width: 1.2),
            boxShadow: [
              BoxShadow(color: brandGolden.withOpacity(0.15), blurRadius: 30, spreadRadius: 1),
              const BoxShadow(color: Colors.black, blurRadius: 20, offset: Offset(0, 8)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_moon_outlined, color: brandGolden, size: 34),
              const SizedBox(height: 14),
              ..._biLines(
                _dlg['leaveWarnTitle']!,
                enStyle: const TextStyle(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 16),
                koStyle: const TextStyle(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              ..._biLines(
                _dlg['leaveWarnBody']!,
                enStyle: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12.5, height: 1.5),
                koStyle: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11.5, height: 1.5),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGolden,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(_bi(_dlg['gotIt']!), style: const TextStyle(color: Color(0xFF030712), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleTimer() async {
    try {
      if (_isRunning) {
        _timer?.cancel();
        setState(() => _isRunning = false);
        await _timerAudioPlayer.pause();
        _animKey.currentState?.pauseEngine();
        _showPauseChoiceDialog();
      } else {
        setState(() => _isRunning = true);
        // 🆕 [고급 안내 팝업] 처음 시작할 때만 한 번, 다른 화면으로 이동 시 데이터가
        // 사라질 수 있음을 부드럽게 안내
        if (_elapsedSeconds == 0) {
          await _showLeaveWarningDialog();
        }
        // 🆕 [알람 순서 보장] 학습 시작 알림음이 실제로 끝날 때까지 기다린 뒤 백색소음 재생
        if (_elapsedSeconds == 0) {
          await _playStartBellAndWait();
        }
        if (widget.selectedSoundFile.isNotEmpty) {
          await _timerAudioPlayer.play(AssetSource('sounds/${widget.selectedSoundFile}'));
        }

        if (_currentIsVip) {
          _animKey.currentState?.resumeEngine();
          if (_elapsedSeconds == 0) {
            _animationCycleSeconds = 0;
            setState(() {
              _showVipOverlay = true;
            });
          }
        }

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            if (_elapsedSeconds < _totalSeconds) {
              _elapsedSeconds++;
              progressPercent = _elapsedSeconds / _totalSeconds;
              _runVipStarStrictRotationEngine();
              _checkAndAccrueStar(); // 🆕 [별 경제 시스템] 실시간 자동 적립 체크
            } else {
              _timer?.cancel();
              _isRunning = false;
              _timerAudioPlayer.stop();
              // [추가] 학습 종료(목표 달성) 알림음 (트랙 공통 1개) - 백색소음 정지 후 반드시 재생됨
              _cueAudioPlayer.play(AssetSource('sounds/end_bell.mp3'));
              _showCompletionDialog();
            }
          });
        });
      }
    } catch (e) {
      debugPrint("타이머 에러: $e");
    }
  }

  void _showPauseChoiceDialog() {
    const Color brandGolden = Color(0xFFE5C158);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1527),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: _biLines(
            _dlg['stopConfirm']!,
            enStyle: TextStyle(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 16),
            koStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () { Navigator.of(context).pop(); _toggleTimer(); },
            child: Text(_bi(_dlg['resume']!), style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandGolden, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('dke_temp_subject', widget.selectedSubject);
              await prefs.setInt('dke_temp_elapsed', _elapsedSeconds);

              if (!mounted) return;
              Navigator.of(context).pop();
              _showRecordWarningDialog();
            },
            child: Text(_bi(_dlg['finish']!), style: GoogleFonts.gowunBatang(color: const Color(0xFF030712), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRecordWarningDialog() {
    const Color brandGolden = Color(0xFFE5C158);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1527),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: _biLines(
            _dlg['recordWarn']!,
            enStyle: TextStyle(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 15),
            koStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandGolden, minimumSize: const Size(140, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () { Navigator.of(context).pop(); _showStudyInputFieldForm(); },
            child: Text(_bi(_dlg['writeRecord']!), style: GoogleFonts.gowunBatang(color: const Color(0xFF030712), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    const Color brandGolden = Color(0xFFE5C158);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1527),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: _biLines(
            _dlg['completion']!,
            enStyle: TextStyle(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 16),
            koStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showGrowthBridgeDialog();
              },
              child: Text(_bi(_dlg['ok']!), style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 16))
          ),
        ],
      ),
    );
  }

  void _showGrowthBridgeDialog() {
    const Color brandGolden = Color(0xFFE5C158);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1527),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: _biLines(
            _dlg['growthStep']!,
            enStyle: TextStyle(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 15),
            koStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showStudyInputFieldForm();
              },
              child: Text(_bi(_dlg['ok']!), style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 16))
          ),
        ],
      ),
    );
  }

  void _showStudyInputFieldForm() {
    const Color brandGolden = Color(0xFFE5C158);
    final TextEditingController detailController = TextEditingController();
    final TextEditingController scoreController = TextEditingController();
    final TextEditingController nextGoalController = TextEditingController();

    final ScrollController dialogScrollController = ScrollController();

    int? selectedUnderstanding;
    String? selectedDifficulty;
    String? selectedFocus;
    String? selectedCondition;
    bool? isIncorrectNoted;
    // 🆕 [기록 유형 구분] 개념강의만 들은 경우엔 점수가 없을 수 있으므로,
    // "강의"와 "평가"를 먼저 구분해서 강의는 세부 유형만, 평가는 기존처럼 점수를 기록하도록 분기함.
    String? selectedRecordType; // '강의' 또는 '평가'
    String? selectedLectureSubType; // '개념강의' 또는 '단원정리 및 문제해설' (강의일 때만 사용)

    // 🆕 [버그 수정 2026-08-10] 각 입력 구간(섹션)에 고유 GlobalKey를 부여해서,
    // 선택할 때마다 "다음에 입력해야 할 항목"이 화면에 정확히 보이도록 Scrollable.ensureVisible로
    // 스크롤을 이동시킴. 기존엔 고정된 픽셀 offset(140, 180, 260...)을 그대로 스크롤했는데,
    // 강의/평가 선택에 따라 위에 있는 항목 개수/높이가 달라지므로 실제 콘텐츠 위치와 offset이 어긋나서
    // 필요 이상으로 더 내려가거나 다음 입력칸이 화면 밖으로 벗어나는 문제가 있었음.
    final GlobalKey keyLectureType = GlobalKey();
    final GlobalKey keyDetails = GlobalKey();
    final GlobalKey keyScore = GlobalKey();
    final GlobalKey keyIncorrectNote = GlobalKey();
    final GlobalKey keyUnderstanding = GlobalKey();
    final GlobalKey keyDifficulty = GlobalKey();
    final GlobalKey keyFocus = GlobalKey();
    final GlobalKey keyCondition = GlobalKey();
    final GlobalKey keyNextGoal = GlobalKey();
    final GlobalKey keySaveButton = GlobalKey();

    // 🆕 [연동 2026-08-10] 타이머에서 [평가] 기록 시, 그 점수를 '나의 성적 기록'(gke_exam_records,
    // 주평가/단원평가/중간고사/기말고사/모의고사)에도 자동으로 반영하기 위한 추가 상태값들.
    String? selectedExamCategory; // 주평가/단원평가/중간고사/기말고사/모의고사
    // 🆕 [요청 #3 2026-09-03] 대단원/중단원 모두 다중 선택 가능하도록 int? -> Set<int>로 전환
    // (member_achievement_screen.dart의 _inputBigUnits/_inputMidUnits와 동일한 패턴)
    Set<int> selectedBigUnitNums = {}; // 단원평가일 때만 사용 (1~12로 확장)
    Set<int> selectedMidUnitNums = {}; // 단원평가일 때만 사용 (1~4 유지)
    int selectedGradeNum = 2; // 학년 (기본값 2학년 - member_achievement_screen.dart 기본값과 동일)
    final TextEditingController mockMonthController = TextEditingController(); // 모의고사일 때만 사용
    final TextEditingController mockRankController = TextEditingController(); // 모의고사일 때만 사용

    final GlobalKey keyExamCategory = GlobalKey();
    final GlobalKey keyUnitDetail = GlobalKey(); // 단원평가(대/중단원) 또는 모의고사(월/등급) 입력칸 공용
    final GlobalKey keyGrade = GlobalKey();

    // 🆕 [연동] member_achievement_screen.dart의 주평가 단원명 자동 생성 로직과 동일한 방식으로
    // "몇주차"를 계산 (일요일을 한 주의 시작으로 보고, 그 달 1일이 포함된 주를 1주차로 계산).
    String computeWeekOfMonthLabel(DateTime now) {
      final DateTime firstOfMonth = DateTime(now.year, now.month, 1);
      final int sundayIndex = firstOfMonth.weekday % 7;
      final int weekNum = ((now.day - 1 + sundayIndex) ~/ 7) + 1;
      return "$weekNum주차";
    }

    // 🆕 [연동] 3~8월=1학기, 9~2월=2학기로 자동 판별 (한국 학사일정 기준 근사치).
    // 🆕 [요청 #3] 이 자동계산 값은 이제 "학기 선택 UI"의 기본값으로만 사용되고,
    // 실제 저장 시에는 selectedSemesterLabel(사용자가 직접 바꿀 수 있는 값)을 사용함.
    String computeSemesterLabel(DateTime now) {
      return (now.month >= 3 && now.month <= 8) ? "1학기" : "2학기";
    }

    // 🆕 [요청 #3 2026-09-03] "학기" 선택 항목이 아예 없던 문제 수정.
    // 학년(GRADE) 바로 아래에 1학기/2학기를 직접 선택할 수 있는 UI를 추가함.
    // 기본값은 위 computeSemesterLabel()의 자동 판별값으로 미리 채워두되, 사용자가 바꿀 수 있음.
    String selectedSemesterLabel = computeSemesterLabel(DateTime.now());

    // 🆕 [요청 #3/#4 2026-09-03] member_achievement_screen.dart의 다중선택 라벨 조합 로직과
    // 같은 목적(대단원/중단원 여러 개 선택)을 갖되, 그 화면의 필터링 로직(rec.unit.contains(bu))과
    // 100% 확실히 호환되도록 범위 압축("대단원 1~대단원 3") 없이 선택된 번호를 전부 개별
    // 나열합니다("대단원 1, 대단원 2, 대단원 3"). 압축 표기를 쓰면 중간 번호(예: 2)가 문자열에
    // 그대로 남지 않아서, 학부모/학생이 "대단원 2"만 필터링했을 때 이 기록이 조회되지 않는
    // 문제가 생길 수 있어 안전한 방식으로 저장합니다.
    String formatUnitLabelForSave(Set<int> selected, String unitWord) {
      if (selected.isEmpty) return "";
      final List<int> nums = selected.toList()..sort();
      return nums.map((n) => "$unitWord $n").join(", ");
    }

    // 🆕 [연동] 시험 유형별로 member_achievement_screen.dart가 저장/조회에 사용하는 것과
    // 동일한 형식의 단원명(unit) 문자열을 생성. 이 형식이 어긋나면 "주평가"/"단원평가" 탭의
    // 필터(연도/월/주차, 대단원/중단원 일치검사)에서 기록이 조회되지 않으므로 형식을 정확히 맞춤.
    String buildExamUnitLabel(String category) {
      final DateTime now = DateTime.now();
      switch (category) {
        case '주평가':
          return "${now.year}년 ${now.month}월 ${computeWeekOfMonthLabel(now)}";
        case '단원평가':
          return "${formatUnitLabelForSave(selectedBigUnitNums, '대단원')} (${formatUnitLabelForSave(selectedMidUnitNums, '중단원')})";
        case '모의고사':
          return "${mockMonthController.text.trim()} 모의고사 (${mockRankController.text.trim()})";
        default: // 중간고사, 기말고사
          return selectedSemesterLabel; // 🆕 [요청 #3] 자동계산 대신 사용자가 선택한 학기 값을 그대로 사용
      }
    }

    // 🆕 [요청 #3] 저장 시 학기 문자열("1학기"/"2학기")을 member_achievement_screen.dart와
    // 동일한 정수(1/2) 형식으로 변환.
    int semesterLabelToInt(String label) => label == '1학기' ? 1 : 2;

    // 🆕 [연동] member_achievement_screen.dart의 _ExamRecord.toJson()과 완전히 동일한 필드 구조로
    // gke_exam_records(SharedPreferences, 단일 JSON 배열 문자열)에 새 레코드를 이어붙여 저장.
    Future<void> appendExamRecord({
      required String category,
      required String subject,
      required double score,
      required String difficulty,
      required int understandingPercent,
      required int durationMinutes,
    }) async {
      final prefs = await SharedPreferences.getInstance();
      final String? existingJson = prefs.getString('gke_exam_records');
      List<dynamic> list = [];
      if (existingJson != null && existingJson.isNotEmpty) {
        try {
          list = jsonDecode(existingJson) as List<dynamic>;
        } catch (_) {
          list = [];
        }
      }

      // 이해도(%)를 만족도 별점(1~5)으로 환산 (100%->5, 80%->4 ... 20%->1)
      final int starSatisfaction = (understandingPercent / 20).round().clamp(1, 5);
      // 이해도가 80% 이상이면 복습 불필요로, 그 미만이면 복습 필요로 자동 판단
      final String reviewRequired = understandingPercent >= 80 ? "불필요" : "필요";

      final Map<String, dynamic> newRecord = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': category,
        'grade': selectedGradeNum,
        'semester': semesterLabelToInt(selectedSemesterLabel), // 🆕 [요청 #3] 사용자가 선택한 학기값 사용
        'date': DateTime.now().toIso8601String(),
        'subject': subject,
        'unit': buildExamUnitLabel(category),
        'score': score,
        'durationText': "$durationMinutes분",
        'difficultyLevel': difficulty,
        'starSatisfaction': starSatisfaction,
        'errorCauses': const ["개념부족"],
        'reviewRequired': reviewRequired,
        'mockMonth': category == '모의고사' ? mockMonthController.text.trim() : "",
        'mockRank': category == '모의고사' ? mockRankController.text.trim() : "",
      };

      list.add(newRecord);
      await prefs.setString('gke_exam_records', jsonEncode(list));
    }

    // 다음 표시할 항목의 key로 정확히 스크롤 이동. 고정 offset을 쓰지 않으므로
    // 현재 화면에 어떤 항목이 조건부로 보이거나 안 보이는지와 관계없이 항상 정확하게 동작함.
    void scrollToNext(GlobalKey targetKey) {
      Future.delayed(const Duration(milliseconds: 150), () {
        final ctx = targetKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            alignment: 0.05, // 화면 상단 쪽에 가깝게 배치해서 다음 항목이 확실히 보이게 함
          );
        }
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (context, setDialogState) {

            // 🆕 [기록 유형 구분] "평가"일 때만 점수(SCORE)를 필수로 요구.
            // "강의"일 때는 세부 유형(개념강의/단원정리 및 문제해설) 선택을 필수로 요구.
            // "오답노트 상태"는 평가이거나, 강의 중 "단원정리 및 문제해설"(문제를 실제로 풀어본 경우)일 때만 필요.
            final bool needsIncorrectNoteField = selectedRecordType == '평가' ||
                (selectedRecordType == '강의' && selectedLectureSubType == '단원정리 및 문제해설');

            // 🆕 [연동 2026-08-10] "평가" 기록일 때 시험 유형 선택 + 유형별 상세 입력까지 필수로 검증.
            // 🆕 [요청 #3] 단원평가는 이제 다중선택(Set)이므로 isNotEmpty로 검증.
            final bool examCategoryDetailFilled = selectedExamCategory == null
                ? false
                : (selectedExamCategory == '단원평가'
                ? (selectedBigUnitNums.isNotEmpty && selectedMidUnitNums.isNotEmpty)
                : (selectedExamCategory == '모의고사'
                ? (mockMonthController.text.trim().isNotEmpty && mockRankController.text.trim().isNotEmpty)
                : true));

            bool isAllFilled = detailController.text.trim().isNotEmpty &&
                nextGoalController.text.trim().isNotEmpty &&
                selectedUnderstanding != null &&
                selectedDifficulty != null &&
                selectedFocus != null &&
                selectedCondition != null &&
                selectedRecordType != null &&
                (selectedRecordType == '평가'
                    ? (scoreController.text.trim().isNotEmpty && examCategoryDetailFilled)
                    : selectedLectureSubType != null) &&
                (!needsIncorrectNoteField || isIncorrectNoted != null);

            return AlertDialog(
              backgroundColor: const Color(0xFF0D1527),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isAllFilled ? brandGolden : Colors.white12, width: 1)),
              title: Column(
                children: _biLines(
                  _dlg['studyRecord']!,
                  enStyle: TextStyle(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 23),
                  koStyle: TextStyle(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              content: Container(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  controller: dialogScrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('${_bi(_dlg['subject']!)} : ', style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(widget.selectedSubject, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), softWrap: true),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 🆕 [기록 유형 구분] 강의(개념강의/단원정리)만 들은 경우엔 점수가 없을 수 있으므로,
                      // 먼저 "강의"인지 "평가"인지 선택하게 하고, 이에 따라 아래 항목이 달라짐.
                      Text('${_bi(_dlg['recordType']!)} $_required', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      // 🆕 [버그 수정 2026-08-10] Row → Wrap 교체.
                      // "강의 (Lecture)" / "평가 (Evaluation)" 라벨이 길어서, 화면이 좁은 기기에서
                      // Row 안의 ChoiceChip 두 개가 가로 폭을 초과해 우측이 잘리는(오버플로우) 문제가 있었음.
                      // Wrap은 폭이 부족하면 자동으로 다음 줄로 넘어가므로 어떤 화면 크기에서도 잘리지 않음.
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: ['강의', '평가'].map((type) {
                          final bool isSel = selectedRecordType == type;
                          return ChoiceChip(
                            label: Text(
                              _bi(type == '강의' ? _dlg['lecture']! : _dlg['evaluation']!),
                              style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            selected: isSel,
                            selectedColor: brandGolden,
                            backgroundColor: const Color(0xFF050B14),
                            onSelected: (_) {
                              setDialogState(() {
                                selectedRecordType = type;
                                if (type == '평가') {
                                  selectedLectureSubType = null; // 평가로 바꾸면 강의 세부유형 초기화
                                } else {
                                  scoreController.clear(); // 강의로 바꾸면 점수 입력값 초기화
                                }
                              });
                              // 강의를 고르면 다음 필수 항목은 "강의 세부 유형", 평가를 고르면 곧바로 "상세 내용"
                              scrollToNext(type == '강의' ? keyLectureType : keyDetails);
                            },
                          );
                        }).toList(),
                      ),

                      // 🆕 [기록 유형 구분] "강의" 선택 시에만 세부 유형(개념강의/단원정리 및 문제해설) 선택 노출
                      if (selectedRecordType == '강의') ...[
                        const SizedBox(height: 12),
                        Column(
                          key: keyLectureType,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_bi(_dlg['lectureType']!)} $_required', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6.0,
                              runSpacing: 6.0,
                              children: ['개념강의', '단원정리 및 문제해설'].map((val) {
                                final bool isSel = selectedLectureSubType == val;
                                return ChoiceChip(
                                  label: Text(_koOnly(val == '개념강의' ? _dlg['conceptLecture']! : _dlg['unitReview']!), style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                                  selected: isSel,
                                  selectedColor: brandGolden,
                                  backgroundColor: const Color(0xFF050B14),
                                  onSelected: (_) {
                                    setDialogState(() => selectedLectureSubType = val);
                                    scrollToNext(keyDetails);
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),

                      Column(
                        key: keyDetails,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_bi(_dlg['details']!)} $_required', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: detailController,
                            maxLines: 2,
                            style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14),
                            onChanged: (_) => setDialogState(() {}),
                            onSubmitted: (_) => scrollToNext(
                                selectedRecordType == '평가' ? keyScore : (needsIncorrectNoteField ? keyIncorrectNote : keyUnderstanding)),
                            decoration: InputDecoration(
                              hintText: _bi(_dlg['detailsHint']!),
                              hintStyle: GoogleFonts.notoSansKr(color: Colors.white.withOpacity(0.24), fontSize: 12),
                              filled: true,
                              fillColor: const Color(0xFF050B14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.all(10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 🆕 [기록 유형 구분] "평가"일 때만 SCORE 필드 노출 (강의는 점수 없음)
                      if (selectedRecordType == '평가') ...[
                        Column(
                          key: keyScore,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_bi(_dlg['score']!)} $_required', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: scoreController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              onChanged: (_) => setDialogState(() {}),
                              onSubmitted: (_) => scrollToNext(keyExamCategory),
                              decoration: InputDecoration(
                                hintText: '100',
                                hintStyle: GoogleFonts.rajdhani(color: Colors.white24, fontSize: 18),
                                suffixText: _bi(_dlg['points']!),
                                suffixStyle: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 12),
                                filled: true,
                                fillColor: const Color(0xFF050B14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 🆕 [연동 2026-08-10] "평가" 기록의 점수를 '나의 성적 기록'(주평가/단원평가/중간고사/
                        // 기말고사/모의고사)에도 자동으로 반영하기 위해, 어떤 시험 유형인지 반드시 선택하게 함.
                        Column(
                          key: keyExamCategory,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_bi(_dlg['examCategory']!)} $_required', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6.0,
                              runSpacing: 6.0,
                              children: ['주평가', '단원평가', '중간고사', '기말고사', '모의고사'].map((cat) {
                                final bool isSel = selectedExamCategory == cat;
                                final Map<String, Map<String, String>> catMap = {
                                  '주평가': _dlg['weeklyAssess']!, '단원평가': _dlg['unitTest']!, '중간고사': _dlg['midterm']!,
                                  '기말고사': _dlg['final']!, '모의고사': _dlg['mock']!,
                                };
                                return ChoiceChip(
                                  label: Text(_koOnly(catMap[cat]!), style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                                  selected: isSel,
                                  selectedColor: brandGolden,
                                  backgroundColor: const Color(0xFF050B14),
                                  onSelected: (_) {
                                    setDialogState(() {
                                      selectedExamCategory = cat;
                                      // 시험 유형이 바뀌면 이전에 입력해둔 단원평가/모의고사 전용 값은 초기화
                                      selectedBigUnitNums = {}; // 🆕 [요청 #3] 다중선택 Set 초기화
                                      selectedMidUnitNums = {};
                                      mockMonthController.clear();
                                      mockRankController.clear();
                                    });
                                    if (cat == '단원평가' || cat == '모의고사') {
                                      scrollToNext(keyUnitDetail);
                                    } else {
                                      scrollToNext(keyGrade);
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),

                        // 🆕 [요청 #3] "단원평가" 선택 시에만 대단원(1~12, 다중선택)/중단원(1~4, 다중선택) 노출
                        if (selectedExamCategory == '단원평가') ...[
                          const SizedBox(height: 16),
                          Column(
                            key: keyUnitDetail,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_bi(_dlg['bigUnit']!)} $_required (${_bi(_dlg['multiSelectHint']!)})', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6.0,
                                runSpacing: 6.0,
                                children: List.generate(12, (i) => i + 1).map((n) {
                                  final bool isSel = selectedBigUnitNums.contains(n);
                                  return ChoiceChip(
                                    label: Text('${_koOnly(_dlg['bigUnit']!)} $n', style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                                    selected: isSel,
                                    selectedColor: brandGolden,
                                    backgroundColor: const Color(0xFF050B14),
                                    onSelected: (_) {
                                      setDialogState(() {
                                        if (isSel) {
                                          selectedBigUnitNums.remove(n);
                                        } else {
                                          selectedBigUnitNums.add(n);
                                        }
                                      });
                                      if (selectedMidUnitNums.isNotEmpty) scrollToNext(keyGrade);
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              Text('${_bi(_dlg['midUnit']!)} $_required (${_bi(_dlg['multiSelectHint']!)})', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6.0,
                                runSpacing: 6.0,
                                children: [1, 2, 3, 4].map((n) {
                                  final bool isSel = selectedMidUnitNums.contains(n);
                                  return ChoiceChip(
                                    label: Text('${_koOnly(_dlg['midUnit']!)} $n', style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                                    selected: isSel,
                                    selectedColor: brandGolden,
                                    backgroundColor: const Color(0xFF050B14),
                                    onSelected: (_) {
                                      setDialogState(() {
                                        if (isSel) {
                                          selectedMidUnitNums.remove(n);
                                        } else {
                                          selectedMidUnitNums.add(n);
                                        }
                                      });
                                      if (selectedBigUnitNums.isNotEmpty) scrollToNext(keyGrade);
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ],

                        // 🆕 [연동] "모의고사" 선택 시에만 몇월/등급(석차) 직접 입력 노출
                        if (selectedExamCategory == '모의고사') ...[
                          const SizedBox(height: 16),
                          Column(
                            key: keyUnitDetail,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_bi(_dlg['mockMonth']!)} $_required', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: mockMonthController,
                                style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14),
                                onChanged: (_) => setDialogState(() {}),
                                onSubmitted: (_) => scrollToNext(keyGrade),
                                decoration: InputDecoration(
                                  hintText: _bi(_dlg['mockMonthHint']!),
                                  hintStyle: GoogleFonts.notoSansKr(color: Colors.white.withOpacity(0.24), fontSize: 12),
                                  filled: true,
                                  fillColor: const Color(0xFF050B14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text('${_bi(_dlg['mockRank']!)} $_required', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: mockRankController,
                                style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14),
                                onChanged: (_) => setDialogState(() {}),
                                onSubmitted: (_) => scrollToNext(keyGrade),
                                decoration: InputDecoration(
                                  hintText: _bi(_dlg['mockRankHint']!),
                                  hintStyle: GoogleFonts.notoSansKr(color: Colors.white.withOpacity(0.24), fontSize: 12),
                                  filled: true,
                                  fillColor: const Color(0xFF050B14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // 🆕 [연동] 시험 유형이 선택된 이후, 학년 + 학기 선택
                        // (grade/semester 필드는 member_achievement_screen.dart의 filter 매칭에 필요)
                        if (selectedExamCategory != null) ...[
                          const SizedBox(height: 16),
                          Column(
                            key: keyGrade,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_bi(_dlg['grade']!)} $_required', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6.0,
                                runSpacing: 6.0,
                                children: [1, 2, 3].map((n) {
                                  final bool isSel = selectedGradeNum == n;
                                  return ChoiceChip(
                                    label: Text(_isForeign ? '${_koOnly(_dlg['gradeWord']!)} $n' : '$n${_koOnly(_dlg['gradeWord']!)}', style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                                    selected: isSel,
                                    selectedColor: brandGolden,
                                    backgroundColor: const Color(0xFF050B14),
                                    onSelected: (_) {
                                      setDialogState(() => selectedGradeNum = n);
                                    },
                                  );
                                }).toList(),
                              ),
                              // 🆕 [요청 #3 2026-09-03] 학년 옆에 학기(1학기/2학기) 선택 UI 신규 추가.
                              // 기본값은 오늘 날짜 기준 자동 판별값이며, 필요 시 직접 변경 가능.
                              const SizedBox(height: 12),
                              Text('${_bi(_dlg['semesterLabel']!)} $_required', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6.0,
                                runSpacing: 6.0,
                                children: ['1학기', '2학기'].map((sem) {
                                  final bool isSel = selectedSemesterLabel == sem;
                                  final Map<String, Map<String, String>> semMap = {
                                    '1학기': _dlg['semester1']!, '2학기': _dlg['semester2']!,
                                  };
                                  return ChoiceChip(
                                    label: Text(_koOnly(semMap[sem]!), style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                                    selected: isSel,
                                    selectedColor: brandGolden,
                                    backgroundColor: const Color(0xFF050B14),
                                    onSelected: (_) {
                                      setDialogState(() => selectedSemesterLabel = sem);
                                      scrollToNext(needsIncorrectNoteField ? keyIncorrectNote : keyUnderstanding);
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],

                      // 🆕 [기록 유형 구분] 평가이거나, 강의 중 "단원정리 및 문제해설"(문제풀이 포함)일 때만 노출
                      if (needsIncorrectNoteField) ...[
                        Column(
                          key: keyIncorrectNote,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_bi(_dlg['incorrectNoteStatus']!)} $_required', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(color: const Color(0xFF050B14), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        setDialogState(() => isIncorrectNoted = true);
                                        scrollToNext(keyUnderstanding);
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                            color: isIncorrectNoted == true ? brandGolden : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8)
                                        ),
                                        child: Text(_bi(_dlg['completed']!), style: GoogleFonts.notoSansKr(color: isIncorrectNoted == true ? const Color(0xFF030712) : Colors.white60, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        setDialogState(() => isIncorrectNoted = false);
                                        scrollToNext(keyUnderstanding);
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                            color: isIncorrectNoted == false ? brandGolden : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8)
                                        ),
                                        child: Text(_bi(_dlg['notYet']!), style: GoogleFonts.notoSansKr(color: isIncorrectNoted == false ? const Color(0xFF030712) : Colors.white60, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ], // needsIncorrectNoteField 조건부 블록 닫힘

                      Column(
                        key: keyUnderstanding,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_bi(_dlg['understanding']!)} $_required', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [20, 40, 60, 80, 100].map((val) {
                                final bool isSel = selectedUnderstanding == val;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6.0),
                                  child: ChoiceChip(
                                    label: Text('$val%', style: GoogleFonts.rajdhani(color: isSel ? const Color(0xFF030712) : Colors.white60, fontWeight: FontWeight.bold)),
                                    selected: isSel,
                                    selectedColor: brandGolden,
                                    backgroundColor: const Color(0xFF050B14),
                                    onSelected: (_) {
                                      setDialogState(() => selectedUnderstanding = val);
                                      scrollToNext(keyDifficulty);
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Column(
                        key: keyDifficulty,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_bi(_dlg['difficulty']!)} $_required', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6.0,
                            runSpacing: 6.0,
                            children: ['매우어려움', '어려움', '보통', '쉬움'].map((val) {
                              final bool isSel = selectedDifficulty == val;
                              final Map<String, Map<String, String>> diffMap = {
                                '매우어려움': _dlg['veryHard']!, '어려움': _dlg['hard']!, '보통': _dlg['normal']!, '쉬움': _dlg['easy']!,
                              };
                              return ChoiceChip(
                                label: Text(_koOnly(diffMap[val]!), style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                                selected: isSel,
                                selectedColor: brandGolden,
                                backgroundColor: const Color(0xFF050B14),
                                onSelected: (_) {
                                  setDialogState(() => selectedDifficulty = val);
                                  scrollToNext(keyFocus);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Column(
                        key: keyFocus,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_bi(_dlg['concentration']!)} $_required', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6.0,
                            runSpacing: 6.0,
                            children: ['높음', '보통', '낮음'].map((val) {
                              final bool isSel = selectedFocus == val;
                              final Map<String, Map<String, String>> focusMap = {
                                '높음': _dlg['high']!, '보통': _dlg['normal']!, '낮음': _dlg['low']!,
                              };
                              return ChoiceChip(
                                label: Text(_koOnly(focusMap[val]!), style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                                selected: isSel,
                                selectedColor: brandGolden,
                                backgroundColor: const Color(0xFF050B14),
                                onSelected: (_) {
                                  setDialogState(() => selectedFocus = val);
                                  scrollToNext(keyCondition);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Column(
                        key: keyCondition,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_bi(_dlg['learningCondition']!)} $_required', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6.0,
                            runSpacing: 6.0,
                            children: [
                              {'label': '좋음', 'emoji': '😊'},
                              {'label': '보통', 'emoji': '😐'},
                              {'label': '피곤함', 'emoji': '😴'}
                            ].map((item) {
                              final String val = item['label']!;
                              final String emoji = item['emoji']!;
                              final bool isSel = selectedCondition == val;
                              final Map<String, Map<String, String>> condMap = {
                                '좋음': _dlg['good']!, '보통': _dlg['normal']!, '피곤함': _dlg['tired']!,
                              };
                              return ChoiceChip(
                                label: Text('$emoji ${_koOnly(condMap[val]!)}', style: GoogleFonts.notoSansKr(color: isSel ? const Color(0xFF030712) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                                selected: isSel,
                                selectedColor: brandGolden,
                                backgroundColor: const Color(0xFF050B14),
                                onSelected: (_) {
                                  setDialogState(() => selectedCondition = val);
                                  scrollToNext(keyNextGoal);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Column(
                        key: keyNextGoal,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_bi(_dlg['nextGoal']!)} $_required', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nextGoalController,
                            style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14),
                            onChanged: (_) => setDialogState(() {}),
                            onSubmitted: (_) => scrollToNext(keySaveButton),
                            decoration: InputDecoration(
                              hintText: _bi(_dlg['nextGoalHint']!),
                              hintStyle: GoogleFonts.notoSansKr(color: Colors.white.withOpacity(0.24), fontSize: 12),
                              filled: true,
                              fillColor: const Color(0xFF050B14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(key: keySaveButton, height: 4),
                    ],
                  ),
                ),
              ),
              actions: [
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAllFilled ? brandGolden : const Color(0xFF1F2937),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: isAllFilled ? 4 : 0,
                    ),
                    onPressed: !isAllFilled ? null : () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('dke_temp_subject');
                      await prefs.remove('dke_temp_elapsed');

                      final String subjectKey = "dke_history_${widget
                          .selectedSubject}";

                      // 🆕 [기록 유형 구분] "강의"(특히 개념강의) 기록은 실제 점수가 없으므로
                      // score/incorrectNote를 0이나 임의값으로 채우지 않고 null로 저장함.
                      // (0을 저장하면 나중에 성취도 화면의 평균 점수 계산에 실제 0점처럼 섞여 통계가 왜곡됨)
                      final Map<String, dynamic> dkeFinalPacket = {
                        'subject': widget.selectedSubject,
                        'recordType': selectedRecordType, // '강의' 또는 '평가'
                        'lectureSubType': selectedLectureSubType, // '개념강의' / '단원정리 및 문제해설' (강의일 때만)
                        'details': detailController.text.trim(),
                        'score': selectedRecordType == '평가'
                            ? (int.tryParse(scoreController.text.trim()) ?? 0)
                            : null,
                        'incorrectNote': needsIncorrectNoteField
                            ? (isIncorrectNoted == true ? '정리함' : '정리 안함')
                            : null,
                        'understanding': selectedUnderstanding,
                        'difficulty': selectedDifficulty,
                        'concentration': selectedFocus,
                        'condition': selectedCondition,
                        'nextGoal': nextGoalController.text.trim(),
                        'durationSeconds': _elapsedSeconds,
                        'timestamp': DateTime.now().toUtc().toString(),
                      };

                      List<String> subjectHistoryList = prefs.getStringList(
                          subjectKey) ?? [];
                      subjectHistoryList.add(jsonEncode(dkeFinalPacket));
                      await prefs.setStringList(subjectKey, subjectHistoryList);

                      // 🆕 [학부모 가시성 확보 2026-09-02] 로컬 저장은 그대로 두고,
                      // 같은 기록 요약을 Firestore(학생 코드 문서의 sessionHistory 배열)에도
                      // 함께 올림. 실패해도 로컬 저장은 이미 끝난 상태라 학생 화면엔 영향 없음.
                      await FamilyLinkService.pushSessionRecord(dkeFinalPacket);

                      // 🆕 [연동 2026-08-10] "평가" 기록이면서 시험 유형(주평가/단원평가/중간고사/기말고사/모의고사)이
                      // 선택된 경우, 같은 점수를 member_achievement_screen.dart의 "나의 성적 기록"(gke_exam_records)에도
                      // 자동으로 이어붙여 저장함. 이제 학생이 같은 점수를 두 번 입력할 필요가 없음.
                      if (selectedRecordType == '평가' && selectedExamCategory != null) {
                        await appendExamRecord(
                          category: selectedExamCategory!,
                          subject: widget.selectedSubject,
                          score: (int.tryParse(scoreController.text.trim()) ?? 0).toDouble(),
                          difficulty: selectedDifficulty ?? "보통",
                          understandingPercent: selectedUnderstanding ?? 60,
                          durationMinutes: (_elapsedSeconds / 60).round(),
                        );
                      }

                      // 🆕 [별 경제 시스템] 별은 이미 학습 중 실시간으로 DkeStars에 적립/저장되어 있으므로
                      // 여기서는 다시 계산해서 더하지 않고, 이번 세션에서 쌓인 값 + 현재 전체 누적치만 조회함.
                      // (기존 _calcStarsFromSeconds/_saveStarsAndGetTotal은 이중 적립을 막기 위해 제거하고 DkeStars로 통합함)
                      final int earnedStars = _starsEarnedThisSession;
                      final int newAllTimeTotal = await DkeStars.getTotalStars();

                      if (!mounted) return;
                      Navigator.of(context).pop();
                      _showFinalSubjectSetupRedirectDialog(
                          earnedStars, newAllTimeTotal);
                    },

                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _biLines(
                        _dlg['saveRecord']!,
                        enStyle: TextStyle(color: isAllFilled ? const Color(0xFF030712) : Colors.white38, fontWeight: FontWeight.bold, fontSize: 15),
                        koStyle: TextStyle(color: isAllFilled ? const Color(0xFF030712) : Colors.white24, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showFinalSubjectSetupRedirectDialog(int earnedStars, int allTimeTotalStars) {
    const Color brandGolden = Color(0xFFE5C158);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1527),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(Icons.star, color: brandGolden, size: 32),
            const SizedBox(height: 8),
            Text(
              _isForeign
                  ? '$earnedStars ${_dlg['starsEarned']![_cur] ?? _dlg['starsEarned']!['EN']}'
                  : '$earnedStars${_dlg['starsCountUnit']!['KO']}의 별을 획득했습니다.',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              '${_bi(_dlg['cumulative']!)} $allTimeTotalStars${_koOnly(_dlg['starsCountUnit']!)}',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 12),
            ),
            const Divider(color: Colors.white24, height: 24),
            Column(
              children: _biLines(
                _dlg['nextSubjectTitle']!,
                enStyle: TextStyle(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 15),
                koStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(allTimeTotalStars);
            },
            child: Text(_bi(_dlg['ok']!), style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  String _formatDisplayTime(int totalSeconds) {
    int mins = totalSeconds ~/ 60;
    int secs = totalSeconds % 60;
    String minStr = mins < 10 ? "0$mins" : "$mins";
    String secStr = secs < 10 ? "0$secs" : "$secs";
    return "00:$minStr:$secStr";
  }

  @override
  Widget build(BuildContext context) {
    const Color brandGolden = Color(0xFFE5C158);
    return PopScope(
      // 🆕 [데이터 보호 2026-09-02] 뒤로가기(< 버튼, 스와이프 등)를 직접 가로채서,
      // 화면이 사라지기 전에 진행 상황을 먼저 저장한 뒤에 실제로 닫히게 함.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPressed();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF050B14),
        body: Container(
          width: double.infinity, height: double.infinity,
          decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/timer.png'), fit: BoxFit.cover)),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Column(
                    children: [
                      const SizedBox(height: 163),
// 🆕 [2026-07-29] 시험준비/시험당일 트랙에서 실행된 경우에만 시험명+D-day 표시.
                      // 평상시/방학/개인시간표에서 실행된 경우에는 마이페이지에서 설정한 실제 목표
                      // (예: 서울대학교, 민족사관고등학교, 사법고시 등)를 그대로 표시하고 D-day는 제거.
                      widget.isExamTrackMode
                          ? Builder(builder: (context) {
                        final DateTime baseDate = widget.targetExamDate ?? DateTime.now();
                        final DateTime nowUtc = DateTime.now().toUtc();
                        final tz.Location targetLocation = tz.getLocation('Asia/Seoul');
                        final tz.TZDateTime examTargetLocal = tz.TZDateTime(targetLocation, baseDate.year, baseDate.month, baseDate.day);
                        final int difference = (examTargetLocal.toUtc().difference(nowUtc).inHours / 24).ceil();
                        String dDayString = difference < 0 ? "D+${difference.abs()}" : (difference == 0 ? "D-Day" : "D-$difference");
                        return Column(mainAxisSize: MainAxisSize.min, children: [
                          Image.asset('assets/images/crown_wings.png', width: 100, fit: BoxFit.contain),
                          const SizedBox(height: 2),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Text("✧───  ", style: TextStyle(color: Color(0xFFE5C158), fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(widget.dynamicTestTitle, style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                            const Text("  ───✧", style: TextStyle(color: Color(0xFFE5C158), fontSize: 12, fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 4),
                          Text(dDayString, style: GoogleFonts.gowunBatang(color: const Color(0xFFFFF6D6), fontSize: 34, fontWeight: FontWeight.bold, height: 1.0, letterSpacing: 0.5)),
                        ]);
                      })
                          : Column(mainAxisSize: MainAxisSize.min, children: [
                        Image.asset('assets/images/crown_wings.png', width: 100, fit: BoxFit.contain),
                        const SizedBox(height: 2),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Text("✧───  ", style: TextStyle(color: Color(0xFFE5C158), fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(_koOnly(_dlg['targetLabel']!), style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                          const Text("  ───✧", style: TextStyle(color: Color(0xFFE5C158), fontSize: 12, fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            _currentUniversity, // 🆕 마이페이지에서 실제 저장한 목표 (대학/고교/고시 등 무엇이든 그대로 표시)
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.gowunBatang(color: const Color(0xFFFFF6D6), fontSize: 24, fontWeight: FontWeight.bold, height: 1.0, letterSpacing: 0.5),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 260),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        // 🆕 [정리 2026-07-29] "배속 실험 모드 가동" 디버그 표시줄 삭제함
                        // (테스트용 임시 문구였고, 바로 아래 큰 타이머와 중복 표시였음)
                        Text(_formatDisplayTime(_elapsedSeconds), style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 78, fontWeight: FontWeight.w700, letterSpacing: 1.0, height: 0.9)),
                      ]),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [Expanded(child: Text("🔊 ${widget.selectedSubject}", style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))]),
                          const SizedBox(height: 4),
                          // 🆕 [실시간 별 표시 2026-09-02] 아이콘 없이 순수 텍스트로만 표시.
                          // 세션 중 실시간으로 쌓이는 별 개수(_starsEarnedThisSession)를 그대로 보여줌.
                          // DkeStars에는 이미 실시간으로 저장되고 있으므로 여기서는 화면 표시만 추가함
                          // (저장 로직 변경 없음).
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _isForeign
                                  ? '${_koOnly(_dlg['liveStars']!)}: $_starsEarnedThisSession'
                                  : '${_koOnly(_dlg['liveStars']!)} $_starsEarnedThisSession${_koOnly(_dlg['starsCountUnit']!)}',
                              style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(_koOnly(_dlg['realtimeFocusMode']!), style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 13, fontWeight: FontWeight.bold)),
                            Text('${_koOnly(_dlg['targetTimeLabel']!)}: ${widget.selectedDurationMinutes}$_minuteUnit', textAlign: TextAlign.end, style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 10),

                          LayoutBuilder(
                            builder: (context, constraints) {
                              final List<Color> rainbowColors = [
                                const Color(0xFFFF3B30),
                                const Color(0xFFFF9500),
                                const Color(0xFFFFCC00),
                                const Color(0xFF34C759),
                                const Color(0xFF007AFF),
                                const Color(0xFF5856D6),
                              ];
                              return Container(
                                width: constraints.maxWidth,
                                height: 18,
                                decoration: BoxDecoration(
                                    color: const Color(0xFF0D1527),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFE5C158).withOpacity(0.3), width: 1.0)
                                ),
                                child: Row(
                                  children: List.generate(6, (index) {
                                    double itemWidth = (constraints.maxWidth - 2.0) / 6;
                                    double startFactor = index / 6.0;
                                    double endFactor = (index + 1) / 6.0;
                                    double itemProgress = 0.0;

                                    if (progressPercent >= endFactor) {
                                      itemProgress = 1.0;
                                    } else if (progressPercent <= startFactor) {
                                      itemProgress = 0.0;
                                    } else {
                                      itemProgress = (progressPercent - startFactor) / (endFactor - startFactor);
                                    }

                                    return Container(
                                      width: itemWidth,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                          border: index < 5 ? Border(right: BorderSide(color: const Color(0xFFE5C158).withOpacity(0.25), width: 1.0)) : null
                                      ),
                                      child: Stack(
                                        children: [
                                          if (itemProgress > 0)
                                            FractionallySizedBox(
                                              widthFactor: itemProgress,
                                              child: Container(color: rainbowColors[index]),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 6),

                          LayoutBuilder(
                            builder: (context, constraints) {
                              double interval = widget.selectedDurationMinutes / 6.0;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(6, (index) {
                                  double currentInterval = interval * (index + 1);
                                  int currentPercentage = ((index + 1) / 6.0 * 100).round();
                                  double itemWidth = constraints.maxWidth / 6;
                                  return SizedBox(
                                    width: itemWidth,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                          "${currentInterval.toStringAsFixed(1)}$_minuteUnit\n($currentPercentage%)",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1.2)
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ]),
                      ),
                      const Spacer(flex: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50.0),
                        child: GestureDetector(
                          onTap: _toggleTimer,
                          child: Container(
                            width: double.infinity, height: 60,
                            decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/btn_start.png'), fit: BoxFit.fill)),
                            child: Center(child: Text(_isRunning ? _bi(_dlg['pauseBtn']!) : _bi(_dlg['startFocus']!), style: GoogleFonts.gowunBatang(color: const Color(0xFFFFF6D6), fontSize: 17, fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                if (_currentIsVip && _showVipOverlay) // 👈 🎯 수정한 부분: widget.isVipMember 대신 실시간 강제 복원된 _currentIsVip 사용!
                  Positioned.fill(
                    child: Center(
                      child: SizedBox(
                        width: 340,
                        height: 300,
                        child: DkeBigStarTargetAnimationModule(
                          key: _animKey,
                          targetUniversityName: _currentUniversity,
                          currentLanguageCode: _currentLanguageCode,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double outerRadius = size.width * 0.48;
    final double innerRadius = size.width * 0.21;
    double angle = -math.pi / 2;
    final double angleStep = math.pi / 5;

    path.moveTo(cx + outerRadius * math.cos(angle), cy + outerRadius * math.sin(angle));
    for (int i = 0; i < 10; i++) {
      angle += angleStep;
      double r = (i % 2 == 0) ? innerRadius : outerRadius;
      path.lineTo(cx + r * math.cos(angle), cy + r * math.sin(angle));
    }
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class DkeBigStarTargetAnimationModule extends StatefulWidget {
  final String targetUniversityName;
  final String currentLanguageCode;

  const DkeBigStarTargetAnimationModule({
    Key? key,
    required this.targetUniversityName,
    required this.currentLanguageCode,
  }) : super(key: key);

  @override
  State<DkeBigStarTargetAnimationModule> createState() => _DkeBigStarTargetAnimationModuleState();
}

class _DkeBigStarTargetAnimationModuleState extends State<DkeBigStarTargetAnimationModule> with TickerProviderStateMixin {
  late AnimationController _timelineController;
  late Animation<double> _targetWordScale;
  late Animation<double> _targetWordOpacity;
  late Animation<double> _uniWordScale;
  late Animation<double> _uniWordOpacity;

  @override
  void initState() {
    super.initState();

    _timelineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );

    _targetWordScale = TweenSequence<double>([
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.fastOutSlowIn)), weight: 10),
      TweenSequenceItem<double>(tween: ConstantTween<double>(1.0), weight: 10),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.fastOutSlowIn)), weight: 10),
      TweenSequenceItem<double>(tween: ConstantTween<double>(0.0), weight: 70),
    ]).animate(_timelineController);

    _targetWordOpacity = TweenSequence<double>([
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem<double>(tween: ConstantTween<double>(1.0), weight: 10),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 10),
      TweenSequenceItem<double>(tween: ConstantTween<double>(0.0), weight: 70),
    ]).animate(_timelineController);

    _uniWordScale = TweenSequence<double>([
      TweenSequenceItem<double>(tween: ConstantTween<double>(0.0), weight: 30),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.0, end: 1.8).chain(CurveTween(curve: Curves.linearToEaseOut)), weight: 23),
      TweenSequenceItem<double>(tween: ConstantTween<double>(1.8), weight: 23),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.8, end: 0.0).chain(CurveTween(curve: Curves.fastOutSlowIn)), weight: 24),
    ]).animate(_timelineController);

    _uniWordOpacity = TweenSequence<double>([
      TweenSequenceItem<double>(tween: ConstantTween<double>(0.0), weight: 30),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 23),
      TweenSequenceItem<double>(tween: ConstantTween<double>(1.0), weight: 23),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 24),
    ]).animate(_timelineController);
  }

  void resetAndPlay() {
    if (mounted) _timelineController.forward(from: 0.0);
  }

  void pauseEngine() {
    if (mounted && _timelineController.isAnimating) _timelineController.stop();
  }

  void resumeEngine() {
    if (mounted && !_timelineController.isAnimating && _timelineController.value > 0.0 && _timelineController.value < 1.0) {
      _timelineController.forward();
    }
  }

  // 🆕 [수정: 2026-08-07] 12개국어 완전 지원으로 교체.
  // 기존엔 'ko'/'ja'/'zh'/'en' 4개만 처리하고 나머지 8개 언어(FR/DE/RU/AR/HI/VI/ES/TH)는
  // 전부 영어로 표시되던 문제를 수정함. 또한 main.dart의 DkeLang 언어코드 표기(대문자: JA, ZH...)와
  // 이 화면이 SharedPreferences에서 불러오는 saved_language_code 값의 대소문자가 어긋나 있을 가능성에
  // 대비해, 비교 시 대소문자를 구분하지 않도록(toUpperCase) 안전장치를 추가함.
  // 디자인/폰트/색상/레이아웃은 100% 원본 그대로이며, 오직 이 함수의 번역 매핑만 확장함.
  String _getTranslatedTarget() {
    final String code = widget.currentLanguageCode.toUpperCase();
    switch (code) {
      case 'KO':
        return '목표';
      case 'EN':
        return 'Target';
      case 'JA':
        return '目標';
      case 'ZH':
        return '目标';
      case 'FR':
        return 'Objectif';
      case 'DE':
        return 'Ziel';
      case 'RU':
        return 'Цель';
      case 'AR':
        return 'الهدف';
      case 'HI':
        return 'लक्ष्य';
      case 'VI':
        return 'Mục tiêu';
      case 'ES':
        return 'Objetivo';
      case 'TH':
        return 'เป้าหมาย';
      default:
      // 알 수 없는 코드가 들어와도 앱이 멈추지 않도록 기본(한글) 표시로 안전하게 처리
        return '목표';
    }
  }

  @override
  void dispose() {
    _timelineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          FadeTransition(
            opacity: _targetWordOpacity,
            child: ScaleTransition(
              scale: _targetWordScale,
              child: Text(
                _getTranslatedTarget(),
                style: GoogleFonts.notoSansKr(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE5C158),
                  shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _uniWordOpacity,
            child: ScaleTransition(
              scale: _uniWordScale,
              child: SizedBox(
                width: 280,
                height: 150,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      top: 30,
                      child: Image.asset(
                        'assets/images/crown_wings.png',
                        width: 150,
                        height: 60,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    Positioned(
                      top: 70,
                      left: 0,
                      right: 0,
                      child: Text(
                        widget.targetUniversityName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: GoogleFonts.gowunBatang(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
