import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/parent_data_service.dart';
import '../global_lang.dart'; // 🆕 [12개국어 연동] 글로벌 사전

class ParentDetailedAnalysisWidget extends StatelessWidget {
  final String childName;
  final Color premiumCardBg;
  final Color brandGolden;
  final Color luxuryDarkBg;
  final VoidCallback onShowReportPopup;
  final VoidCallback onShowDetailedAnalysisPopup;
  // 🆕 [12개국어 연동] foreignTitle(선택) 추가 - 외국어 선택 시 번역된 한 줄만 표시하기 위함
  final Widget Function(String, String, {required double fontSize, String? foreignTitle}) buildCustomSectionTitle;

  // 🆕 [지난 일자 조회] 좌우 화살표로 하루씩 이동하며 조회할 날짜와 콜백
  final DateTime selectedDate;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final bool isViewingToday; // true면 오른쪽(다음날) 화살표를 비활성화 (미래 날짜 조회 방지)

  // 🆕 [실데이터 연동] 선택된 날짜의 실제 학습 세션 목록 (강의+평가 전부 포함, 시간순 정렬됨)
  final List<ParentSessionRecord> sessionsForDate;

  // 🆕 [실데이터 연동] 전날 대비 / 1주 평균 대비 학습시간 변화량 계산용 (선택된 날짜 기준)
  final int todayTotalMinutes;
  final int yesterdayTotalMinutes;
  final int weeklyAvgMinutesPerDay;

  // 🆕 [실데이터 연동] 평가 평균 점수 기준 가장 잘하는 과목 / 가장 취약한 과목
  final String? strongestSubject;
  final String? weakestSubject;

  const ParentDetailedAnalysisWidget({
    Key? key,
    required this.childName,
    required this.premiumCardBg,
    required this.brandGolden,
    required this.luxuryDarkBg,
    required this.onShowReportPopup,
    required this.onShowDetailedAnalysisPopup,
    required this.buildCustomSectionTitle,
    required this.selectedDate,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.isViewingToday,
    required this.sessionsForDate,
    required this.todayTotalMinutes,
    required this.yesterdayTotalMinutes,
    required this.weeklyAvgMinutesPerDay,
    this.strongestSubject,
    this.weakestSubject,
  }) : super(key: key);

  // ============================================================================
  // 🆕 [12개국어 연동] UI 문구 카탈로그 + 조회 헬퍼 _t()/_tf()
  // ⚠️ rec.recordType('강의'/'평가') 등 내부 데이터 매칭/비교용 원본 값은 절대 번역하지 않음
  // (하드 룰 6번). 화면에 "표시"만 할 때는 _recordTypeDisplay()로 별도 변환.
  // 🆕 [지난 일자 조회] "오늘"을 하드코딩한 문구들은 {day} 토큰으로 바꿔 선택된 날짜에
  // 맞춰 "오늘" 또는 "2026.08.15"처럼 실제 날짜가 들어가도록 처리했습니다.
  // ============================================================================
  static const Map<String, Map<String, String>> _uiText = {
    'todayWord': {'KO': '오늘', 'EN': 'Today', 'JA': '本日', 'ZH': '今天', 'FR': "Aujourd'hui", 'DE': 'Heute', 'RU': 'Сегодня', 'AR': 'اليوم', 'HI': 'आज', 'VI': 'Hôm nay', 'ES': 'Hoy', 'TH': 'วันนี้'},
    'sectionTitle1Foreign': {'KO': '{name} {day} 자기주도 학습 성취도 상세보기', 'EN': "{name}'s Self-Directed Learning Achievement Details ({day})", 'JA': '{name} 自己主導学習成果詳細（{day}）', 'ZH': '{name} 自主学习成果详情（{day}）', 'FR': "Détails de la réussite en apprentissage autonome de {name} ({day})", 'DE': '{name} - Details zur selbstgesteuerten Lernleistung ({day})', 'RU': '{name} - Подробности успехов в самостоятельном обучении ({day})', 'AR': '{name} - تفاصيل إنجاز التعلم الذاتي ({day})', 'HI': '{name} - स्व-निर्देशित शिक्षण उपलब्धि का विवरण ({day})', 'VI': '{name} - Chi tiết thành tích học tập tự định hướng ({day})', 'ES': '{name} - Detalles del logro de aprendizaje autónomo ({day})', 'TH': '{name} - รายละเอียดผลสัมฤทธิ์การเรียนรู้ด้วยตนเอง ({day})'},
    'sectionTitle2Foreign': {'KO': '최근 학습 변화량 분석 데이터', 'EN': 'Recent Learning Change Analysis', 'JA': '最近の学習変化量分析データ', 'ZH': '近期学习变化量分析数据', 'FR': "Analyse récente des variations d'apprentissage", 'DE': 'Analyse der jüngsten Lernveränderungen', 'RU': 'Анализ недавних изменений в учёбе', 'AR': 'تحليل التغيّرات الأخيرة في التعلم', 'HI': 'हाल के अध्ययन परिवर्तन का विश्लेषण', 'VI': 'Phân tích biến động học tập gần đây', 'ES': 'Análisis reciente de la variación de aprendizaje', 'TH': 'การวิเคราะห์ความเปลี่ยนแปลงการเรียนล่าสุด'},
    'sectionTitle3Foreign': {'KO': '학습 기록 분석 진단 센터', 'EN': 'Learning Record Diagnostic Center', 'JA': '学習記録分析診断センター', 'ZH': '学习记录分析诊断中心', 'FR': "Centre de diagnostic des données d'apprentissage", 'DE': 'Diagnosezentrum für Lernaufzeichnungen', 'RU': 'Диагностический центр учебных записей', 'AR': 'مركز تشخيص سجلات التعلم', 'HI': 'अध्ययन रिकॉर्ड निदान केंद्र', 'VI': 'Trung tâm chẩn đoán hồ sơ học tập', 'ES': 'Centro de diagnóstico de registros de aprendizaje', 'TH': 'ศูนย์วินิจฉัยบันทึกการเรียนรู้'},
    'todayEmptyMsg': {'KO': '{day}에는 아직 기록된 학습 세션이 없습니다.', 'EN': '{day}: No study sessions have been recorded yet.', 'JA': '{day}はまだ記録された学習セッションがありません。', 'ZH': '{day}还没有记录的学习记录。', 'FR': "{day} : aucune session d'étude n'a encore été enregistrée.", 'DE': '{day}: Es wurden noch keine Lerneinheiten aufgezeichnet.', 'RU': '{day}: пока не записано ни одной учебной сессии.', 'AR': '{day}: لم يتم تسجيل أي جلسة دراسية بعد.', 'HI': '{day}: अभी तक कोई अध्ययन सत्र दर्ज नहीं हुआ है।', 'VI': '{day}: chưa có buổi học nào được ghi lại.', 'ES': '{day}: todavía no se ha registrado ninguna sesión de estudio.', 'TH': '{day}: ยังไม่มีการบันทึกช่วงเรียน'},
    'periodLabel': {'KO': '제{n}교시', 'EN': 'Period {n}', 'JA': '第{n}時限', 'ZH': '第{n}节', 'FR': '{n}e période', 'DE': '{n}. Einheit', 'RU': '{n}-й урок', 'AR': 'الحصة {n}', 'HI': '{n} पीरियड', 'VI': 'Tiết {n}', 'ES': 'Periodo {n}', 'TH': 'คาบที่ {n}'},
    'durationFocusedLabel': {'KO': '{min}분 집중완료', 'EN': '{min} min focused study completed', 'JA': '{min}分 集中学習完了', 'ZH': '专注学习{min}分钟完成', 'FR': "{min} min d'étude concentrée terminée", 'DE': '{min} Min. konzentriertes Lernen abgeschlossen', 'RU': '{min} мин сосредоточенной учёбы завершено', 'AR': 'اكتمال {min} دقيقة من الدراسة المركزة', 'HI': '{min} मिनट केंद्रित अध्ययन पूर्ण', 'VI': 'Hoàn thành {min} phút học tập trung', 'ES': '{min} min de estudio enfocado completados', 'TH': 'เรียนแบบตั้งใจครบ {min} นาที'},
    'lectureStudyDefault': {'KO': '강의 학습', 'EN': 'Lecture study', 'JA': '講義学習', 'ZH': '讲课学习', 'FR': 'Étude en cours', 'DE': 'Vorlesungslernen', 'RU': 'Изучение лекции', 'AR': 'دراسة المحاضرة', 'HI': 'व्याख्यान अध्ययन', 'VI': 'Học theo bài giảng', 'ES': 'Estudio de clase', 'TH': 'เรียนแบบบรรยาย'},
    'evalRecordDefault': {'KO': '평가 기록', 'EN': 'Evaluation record', 'JA': '評価記録', 'ZH': '评估记录', 'FR': "Enregistrement d'évaluation", 'DE': 'Bewertungseintrag', 'RU': 'Запись оценивания', 'AR': 'سجل التقييم', 'HI': 'मूल्यांकन रिकॉर्ड', 'VI': 'Ghi chú đánh giá', 'ES': 'Registro de evaluación', 'TH': 'บันทึกการประเมิน'},
    'scoreSuffix': {'KO': '{score}점', 'EN': '{score} pts', 'JA': '{score}点', 'ZH': '{score}分', 'FR': '{score} pts', 'DE': '{score} Pkt.', 'RU': '{score} баллов', 'AR': '{score} نقطة', 'HI': '{score} अंक', 'VI': '{score} điểm', 'ES': '{score} pts', 'TH': '{score} คะแนน'},
    'recordTypeLecture': {'KO': '강의', 'EN': 'Lecture', 'JA': '講義', 'ZH': '讲课', 'FR': 'Cours', 'DE': 'Vorlesung', 'RU': 'Лекция', 'AR': 'محاضرة', 'HI': 'व्याख्यान', 'VI': 'Bài giảng', 'ES': 'Clase', 'TH': 'บรรยาย'},
    'recordTypeEval': {'KO': '평가', 'EN': 'Evaluation', 'JA': '評価', 'ZH': '评估', 'FR': 'Évaluation', 'DE': 'Bewertung', 'RU': 'Оценка', 'AR': 'تقييم', 'HI': 'मूल्यांकन', 'VI': 'Đánh giá', 'ES': 'Evaluación', 'TH': 'ประเมิน'},
    'todayStudyTimeLabel': {'KO': '{day} 학습시간', 'EN': '{day} Study Time', 'JA': '{day}の学習時間', 'ZH': '{day}学习时间', 'FR': "Temps d'étude ({day})", 'DE': 'Lernzeit ({day})', 'RU': 'Учебное время ({day})', 'AR': 'وقت الدراسة ({day})', 'HI': '{day} का अध्ययन समय', 'VI': 'Thời gian học ({day})', 'ES': 'Tiempo de estudio ({day})', 'TH': 'เวลาเรียน ({day})'},
    'vsYesterdayFormat': {'KO': '전날 대비 {pct}% {arrow}', 'EN': 'vs previous day {pct}% {arrow}', 'JA': '前日比 {pct}% {arrow}', 'ZH': '较前一日 {pct}% {arrow}', 'FR': "vs jour précédent {pct}% {arrow}", 'DE': 'vs. Vortag {pct}% {arrow}', 'RU': 'к предыдущему дню {pct}% {arrow}', 'AR': 'مقارنة باليوم السابق {pct}% {arrow}', 'HI': 'पिछले दिन की तुलना में {pct}% {arrow}', 'VI': 'so với ngày trước {pct}% {arrow}', 'ES': 'vs día anterior {pct}% {arrow}', 'TH': 'เทียบวันก่อนหน้า {pct}% {arrow}'},
    'vsWeeklyAvgFormat': {'KO': '1주 평균 대비 {pct}% {arrow}', 'EN': 'vs weekly avg {pct}% {arrow}', 'JA': '週平均比 {pct}% {arrow}', 'ZH': '较周平均 {pct}% {arrow}', 'FR': 'vs moyenne hebdo {pct}% {arrow}', 'DE': 'vs. Wochendurchschnitt {pct}% {arrow}', 'RU': 'к недельному среднему {pct}% {arrow}', 'AR': 'مقارنة بمتوسط الأسبوع {pct}% {arrow}', 'HI': 'साप्ताहिक औसत की तुलना में {pct}% {arrow}', 'VI': 'so với TB tuần {pct}% {arrow}', 'ES': 'vs promedio semanal {pct}% {arrow}', 'TH': 'เทียบค่าเฉลี่ยรายสัปดาห์ {pct}% {arrow}'},
    'todaySessionCountLabel': {'KO': '{day} 학습 세션 수', 'EN': '{day} Session Count', 'JA': '{day}の学習セッション数', 'ZH': '{day}学习记录数', 'FR': "Nombre de sessions ({day})", 'DE': 'Anzahl Lerneinheiten ({day})', 'RU': 'Количество сессий ({day})', 'AR': 'عدد الجلسات ({day})', 'HI': '{day} के सत्रों की संख्या', 'VI': 'Số buổi học ({day})', 'ES': 'Sesiones ({day})', 'TH': 'จำนวนช่วงเรียน ({day})'},
    'sessionsRecordedFormat': {'KO': '{count}개 세션 기록됨', 'EN': '{count} sessions recorded', 'JA': '{count}件のセッション記録', 'ZH': '已记录{count}节', 'FR': '{count} sessions enregistrées', 'DE': '{count} Einheiten erfasst', 'RU': 'Записано сессий: {count}', 'AR': 'تم تسجيل {count} جلسة', 'HI': '{count} सत्र दर्ज', 'VI': 'Đã ghi {count} buổi', 'ES': '{count} sesiones registradas', 'TH': 'บันทึกแล้ว {count} ช่วง'},
    'totalFocusFormat': {'KO': '총 {min}분 집중', 'EN': 'Total {min} min focused', 'JA': '計{min}分集中', 'ZH': '共专注{min}分钟', 'FR': '{min} min de concentration au total', 'DE': 'Insgesamt {min} Min. konzentriert', 'RU': 'Всего {min} мин сосредоточенно', 'AR': 'إجمالي {min} دقيقة تركيز', 'HI': 'कुल {min} मिनट केंद्रित', 'VI': 'Tổng {min} phút tập trung', 'ES': 'Total {min} min enfocado', 'TH': 'รวมตั้งใจเรียน {min} นาที'},
    'noRecordYet': {'KO': '아직 기록 없음', 'EN': 'No record yet', 'JA': 'まだ記録なし', 'ZH': '暂无记录', 'FR': "Pas encore d'enregistrement", 'DE': 'Noch keine Aufzeichnung', 'RU': 'Записей пока нет', 'AR': 'لا يوجد سجل بعد', 'HI': 'अभी तक कोई रिकॉर्ड नहीं', 'VI': 'Chưa có ghi chú', 'ES': 'Aún sin registro', 'TH': 'ยังไม่มีบันทึก'},
    'strongSubjectLabel': {'KO': '✨ 잘하고 있는 과목', 'EN': '✨ Strongest Subject', 'JA': '✨ 得意な科目', 'ZH': '✨ 表现最好的科目', 'FR': '✨ Matière la plus forte', 'DE': '✨ Stärkstes Fach', 'RU': '✨ Сильный предмет', 'AR': '✨ المادة الأقوى', 'HI': '✨ सबसे मजबूत विषय', 'VI': '✨ Môn học tốt nhất', 'ES': '✨ Materia más fuerte', 'TH': '✨ วิชาที่ทำได้ดี'},
    'weakSubjectLabel': {'KO': '🌋 가장 성적이 안나오는 과목', 'EN': '🌋 Weakest Subject', 'JA': '🌋 成績が振るわない科目', 'ZH': '🌋 成绩最弱的科目', 'FR': '🌋 Matière la plus faible', 'DE': '🌋 Schwächstes Fach', 'RU': '🌋 Слабый предмет', 'AR': '🌋 المادة الأضعف', 'HI': '🌋 सबसे कमजोर विषय', 'VI': '🌋 Môn học yếu nhất', 'ES': '🌋 Materia más débil', 'TH': '🌋 วิชาที่คะแนนต่ำที่สุด'},
    'dataCollectingMsg': {'KO': '데이터 수집 중', 'EN': 'Collecting data', 'JA': 'データ収集中', 'ZH': '数据收集中', 'FR': 'Collecte de données...', 'DE': 'Daten werden gesammelt', 'RU': 'Сбор данных...', 'AR': 'جمع البيانات...', 'HI': 'डेटा एकत्रित हो रहा है', 'VI': 'Đang thu thập dữ liệu', 'ES': 'Recopilando datos...', 'TH': 'กำลังรวบรวมข้อมูล'},
    'homeSupportLabel': {'KO': '🛡️ 가정에서 도와줄 포인트', 'EN': '🛡️ How to Help at Home', 'JA': '🛡️ 家庭でのサポートポイント', 'ZH': '🛡️ 家庭辅导要点', 'FR': '🛡️ Conseils pour aider à la maison', 'DE': '🛡️ Unterstützungstipps für zu Hause', 'RU': '🛡️ Как помочь дома', 'AR': '🛡️ نصائح للمساعدة في المنزل', 'HI': '🛡️ घर पर मदद के तरीके', 'VI': '🛡️ Cách hỗ trợ tại nhà', 'ES': '🛡️ Cómo ayudar en casa', 'TH': '🛡️ แนวทางช่วยเหลือที่บ้าน'},
    'weakSubjectAdviceFormat': {'KO': '{subject} 학습 시간 확보 및 오답 정리 지원 권장', 'EN': 'Recommend securing more study time for {subject} and reviewing mistakes', 'JA': '{subject}の学習時間確保と誤答整理のサポートを推奨します', 'ZH': '建议为{subject}安排更多学习时间并协助整理错题', 'FR': 'Il est recommandé de consacrer plus de temps à {subject} et de revoir les erreurs', 'DE': 'Empfohlen wird, mehr Lernzeit für {subject} einzuplanen und Fehler zu überprüfen', 'RU': 'Рекомендуется выделить больше времени на {subject} и разобрать ошибки', 'AR': 'يُنصح بتخصيص وقت أطول لدراسة {subject} ومراجعة الأخطاء', 'HI': '{subject} के लिए अधिक अध्ययन समय और गलतियों की समीक्षा में सहायता की सिफारिश की जाती है', 'VI': 'Nên dành thêm thời gian học {subject} và hỗ trợ xem lại lỗi sai', 'ES': 'Se recomienda dedicar más tiempo de estudio a {subject} y repasar los errores', 'TH': 'แนะนำให้จัดสรรเวลาเรียนวิชา {subject} เพิ่มขึ้นและช่วยทบทวนข้อผิดพลาด'},
    'waitForEvalMsg': {'KO': '평가 기록이 쌓이면 안내됩니다', 'EN': 'Guidance will appear once evaluation records accumulate', 'JA': '評価記録が蓄積されるとご案内します', 'ZH': '累积评估记录后将提供指导', 'FR': 'Des conseils apparaîtront une fois les évaluations accumulées', 'DE': 'Hinweise erscheinen, sobald Bewertungsdaten vorliegen', 'RU': 'Рекомендации появятся после накопления записей оценивания', 'AR': 'سيتم تقديم إرشادات بمجرد تراكم سجلات التقييم', 'HI': 'मूल्यांकन रिकॉर्ड जमा होने पर मार्गदर्शन दिखाई देगा', 'VI': 'Hướng dẫn sẽ xuất hiện khi có đủ dữ liệu đánh giá', 'ES': 'Se mostrará orientación cuando se acumulen registros de evaluación', 'TH': 'คำแนะนำจะปรากฏเมื่อมีการสะสมข้อมูลการประเมิน'},
    'viewSummaryBtn': {'KO': '오늘 종합 리포트 보기 🔺', 'EN': "View Today's Overall Report 🔺", 'JA': '本日の総合レポートを見る 🔺', 'ZH': '查看今日综合报告 🔺', 'FR': 'Voir le rapport global du jour 🔺', 'DE': 'Heutigen Gesamtbericht ansehen 🔺', 'RU': 'Смотреть общий отчёт за сегодня 🔺', 'AR': 'عرض التقرير الشامل لليوم 🔺', 'HI': 'आज की समग्र रिपोर्ट देखें 🔺', 'VI': 'Xem báo cáo tổng hợp hôm nay 🔺', 'ES': 'Ver informe general de hoy 🔺', 'TH': 'ดูรายงานสรุปวันนี้ 🔺'},
    'viewDetailBtn': {'KO': '오늘 상세 분석 보기 🔺', 'EN': "View Today's Detailed Analysis 🔺", 'JA': '本日の詳細分析を見る 🔺', 'ZH': '查看今日详细分析 🔺', 'FR': "Voir l'analyse détaillée du jour 🔺", 'DE': 'Heutige detaillierte Analyse ansehen 🔺', 'RU': 'Смотреть подробный анализ за сегодня 🔺', 'AR': 'عرض التحليل التفصيلي لليوم 🔺', 'HI': 'आज का विस्तृत विश्लेषण देखें 🔺', 'VI': 'Xem phân tích chi tiết hôm nay 🔺', 'ES': 'Ver análisis detallado de hoy 🔺', 'TH': 'ดูการวิเคราะห์เชิงลึกวันนี้ 🔺'},
    'metricScore': {'KO': '점수', 'EN': 'Score', 'JA': '点数', 'ZH': '分数', 'FR': 'Score', 'DE': 'Punktzahl', 'RU': 'Балл', 'AR': 'الدرجة', 'HI': 'स्कोर', 'VI': 'Điểm', 'ES': 'Puntuación', 'TH': 'คะแนน'},
    'metricUnderstanding': {'KO': '이해도', 'EN': 'Understanding', 'JA': '理解度', 'ZH': '理解度', 'FR': 'Compréhension', 'DE': 'Verständnis', 'RU': 'Понимание', 'AR': 'الفهم', 'HI': 'समझ', 'VI': 'Mức hiểu', 'ES': 'Comprensión', 'TH': 'ความเข้าใจ'},
    'metricDifficulty': {'KO': '난이도', 'EN': 'Difficulty', 'JA': '難易度', 'ZH': '难度', 'FR': 'Difficulté', 'DE': 'Schwierigkeit', 'RU': 'Сложность', 'AR': 'الصعوبة', 'HI': 'कठिनाई', 'VI': 'Độ khó', 'ES': 'Dificultad', 'TH': 'ความยาก'},
    'metricConcentration': {'KO': '집중도', 'EN': 'Concentration', 'JA': '集中度', 'ZH': '专注度', 'FR': 'Concentration', 'DE': 'Konzentration', 'RU': 'Концентрация', 'AR': 'التركيز', 'HI': 'एकाग्रता', 'VI': 'Mức tập trung', 'ES': 'Concentración', 'TH': 'สมาธิ'},
    'metricCondition': {'KO': '학습컨디션', 'EN': 'Condition', 'JA': 'コンディション', 'ZH': '状态', 'FR': 'État', 'DE': 'Zustand', 'RU': 'Состояние', 'AR': 'الحالة', 'HI': 'स्थिति', 'VI': 'Tình trạng', 'ES': 'Condición', 'TH': 'สภาพ'},
    'metricIncorrect': {'KO': '오답정리', 'EN': 'Error Review', 'JA': '誤答整理', 'ZH': '错题整理', 'FR': 'Correction des erreurs', 'DE': 'Fehleraufarbeitung', 'RU': 'Разбор ошибок', 'AR': 'مراجعة الأخطاء', 'HI': 'गलती समीक्षा', 'VI': 'Chỉnh sửa lỗi', 'ES': 'Revisión de errores', 'TH': 'ทบทวนข้อผิดพลาด'},
    'detailContentFormat': {'KO': '"상세내용 - {content}"', 'EN': '"Details - {content}"', 'JA': '「詳細内容 - {content}」', 'ZH': '"详细内容 - {content}"', 'FR': '« Détails - {content} »', 'DE': '„Details - {content}"', 'RU': '«Подробности - {content}»', 'AR': '"التفاصيل - {content}"', 'HI': '"विवरण - {content}"', 'VI': '"Chi tiết - {content}"', 'ES': '"Detalles - {content}"', 'TH': '"รายละเอียด - {content}"'},
  };

  static String _t(String key) {
    final map = _uiText[key];
    if (map == null) return key;
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? key;
  }

  static String _tf(String key, Map<String, String> values) {
    String result = _t(key);
    values.forEach((token, value) {
      result = result.replaceAll('{$token}', value);
    });
    return result;
  }

  // 🆕 [12개국어 연동] rec.recordType('강의'/'평가') 원본값을 화면 표시용 번역 문구로 변환
  static String _recordTypeDisplay(String raw) => raw == '평가' ? _t('recordTypeEval') : _t('recordTypeLecture');

  // 🆕 [지난 일자 조회] 선택된 날짜가 오늘이면 "오늘"(각 언어), 아니면 "YYYY.MM.DD" 형식으로 표시
  bool get _isToday {
    final now = DateTime.now();
    return selectedDate.year == now.year && selectedDate.month == now.month && selectedDate.day == now.day;
  }

  String get _dayLabel {
    if (_isToday) return _t('todayWord');
    return "${selectedDate.year}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.day.toString().padLeft(2, '0')}";
  }

  // 기본모드(KO/EN) korTitle 파라미터에 들어갈 한글 전용 날짜 라벨 (foreignTitle과 별개로 항상 필요)
  String get _dayLabelKo {
    if (_isToday) return '오늘';
    return "${selectedDate.year}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.day.toString().padLeft(2, '0')}";
  }

  int get _todayVsYesterdayPercent {
    if (yesterdayTotalMinutes <= 0) return todayTotalMinutes > 0 ? 100 : 0;
    return (((todayTotalMinutes - yesterdayTotalMinutes) / yesterdayTotalMinutes) * 100).round();
  }

  int get _todayVsWeeklyAvgPercent {
    if (weeklyAvgMinutesPerDay <= 0) return todayTotalMinutes > 0 ? 100 : 0;
    return (((todayTotalMinutes - weeklyAvgMinutesPerDay) / weeklyAvgMinutesPerDay) * 100).round();
  }

  // 🆕 [지난 일자 조회] 좌우 화살표 + 현재 조회 중인 날짜 표시 헤더
  Widget _buildDateNavHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: onPreviousDay,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.chevron_left_rounded, color: brandGolden, size: 24),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 100),
            alignment: Alignment.center,
            child: Text(
              _dayLabel,
              style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          InkWell(
            onTap: isViewingToday ? null : onNextDay,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.chevron_right_rounded, color: isViewingToday ? Colors.white24 : brandGolden, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        buildCustomSectionTitle(
          "Self-Directed Learning Records",
          "$childName $_dayLabelKo 자기주도 학습 성취도 상세보기",
          fontSize: 14.0,
          foreignTitle: _tf('sectionTitle1Foreign', {'name': childName, 'day': _dayLabel}),
        ),
        // 🆕 [지난 일자 조회] 좌우 화살표로 하루씩 이동
        _buildDateNavHeader(),
        const SizedBox(height: 4),

        // 🆕 [실데이터 연동] 선택된 날짜의 실제 세션 목록을 제1교시부터 순서대로 표시 (강의/평가 전부 포함)
        if (sessionsForDate.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: premiumCardBg,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              _tf('todayEmptyMsg', {'day': _dayLabel}),
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 13),
            ),
          )
        else
          ...List.generate(sessionsForDate.length, (idx) {
            final rec = sessionsForDate[idx];
            return _buildAdvancedTimelineCard(
              period: _tf('periodLabel', {'n': '${idx + 1}'}),
              subject: rec.subject,
              duration: _tf('durationFocusedLabel', {'min': '${rec.durationMinutes}'}),
              content: rec.details.isNotEmpty
                  ? rec.details
                  : (rec.recordType == '강의' ? (rec.lectureSubType ?? _t('lectureStudyDefault')) : _t('evalRecordDefault')),
              score: rec.recordType == '평가' && rec.score != null ? _tf('scoreSuffix', {'score': '${rec.score}'}) : null,
              understanding: rec.understanding != null ? "${rec.understanding}%" : null,
              difficulty: rec.difficulty,
              concentration: rec.concentration,
              condition: rec.condition,
              incorrect: rec.incorrectNote,
              recordTypeLabel: rec.recordType,
            );
          }),
        const SizedBox(height: 16),

        buildCustomSectionTitle(
          "Learning Variation Analytics",
          "최근 학습 변화량 분석 데이터",
          fontSize: 14.0,
          foreignTitle: _t('sectionTitle2Foreign'),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: premiumCardBg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: brandGolden.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              _buildAlignedVariationRow(
                _tf('todayStudyTimeLabel', {'day': _dayLabel}),
                _tf('vsYesterdayFormat', {'pct': '${_todayVsYesterdayPercent >= 0 ? '+' : ''}$_todayVsYesterdayPercent', 'arrow': _todayVsYesterdayPercent >= 0 ? '🔺' : '🔻'}),
                _tf('vsWeeklyAvgFormat', {'pct': '${_todayVsWeeklyAvgPercent >= 0 ? '+' : ''}$_todayVsWeeklyAvgPercent', 'arrow': _todayVsWeeklyAvgPercent >= 0 ? '🔺' : '🔻'}),
              ),
              const Divider(color: Colors.white10, height: 20),
              _buildAlignedVariationRow(
                _tf('todaySessionCountLabel', {'day': _dayLabel}),
                _tf('sessionsRecordedFormat', {'count': '${sessionsForDate.length}'}),
                todayTotalMinutes > 0 ? _tf('totalFocusFormat', {'min': '$todayTotalMinutes'}) : _t('noRecordYet'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: brandGolden.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextFeatureRow(_t('strongSubjectLabel'), strongestSubject ?? _t('dataCollectingMsg')),
              const Divider(color: Colors.white10, height: 18),
              _buildTextFeatureRow(_t('weakSubjectLabel'), weakestSubject ?? _t('dataCollectingMsg')),
              const Divider(color: Colors.white10, height: 18),
              _buildTextFeatureRow(
                _t('homeSupportLabel'),
                weakestSubject != null ? _tf('weakSubjectAdviceFormat', {'subject': weakestSubject!}) : _t('waitForEvalMsg'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        buildCustomSectionTitle(
          "Diagnostic Qualitative Analysis",
          "학습 기록 분석 진단 센터",
          fontSize: 14.0,
          foreignTitle: _t('sectionTitle3Foreign'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: premiumCardBg,
                  side: BorderSide(color: brandGolden, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onShowReportPopup,
                icon: Icon(Icons.analytics_rounded, color: brandGolden, size: 16),
                label: Text(
                  _t('viewSummaryBtn'),
                  style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: premiumCardBg,
                  side: BorderSide(color: brandGolden, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onShowDetailedAnalysisPopup,
                icon: Icon(Icons.manage_search_rounded, color: brandGolden, size: 16),
                label: Text(
                  _t('viewDetailBtn'),
                  style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedTimelineCard({
    required String period,
    required String subject,
    required String duration,
    required String content,
    required String recordTypeLabel,
    String? score,
    String? understanding,
    String? difficulty,
    String? concentration,
    String? condition,
    String? incorrect,
  }) {
    // 🆕 [실데이터 연동] 값이 있는 지표만 동적으로 구성 (강의 기록은 점수/오답노트가 없을 수 있음)
    final List<MapEntry<String, String>> metrics = [];
    if (score != null) metrics.add(MapEntry(_t('metricScore'), score));
    if (understanding != null) metrics.add(MapEntry(_t('metricUnderstanding'), understanding));
    if (difficulty != null) metrics.add(MapEntry(_t('metricDifficulty'), difficulty));
    if (concentration != null) metrics.add(MapEntry(_t('metricConcentration'), concentration));
    if (condition != null) metrics.add(MapEntry(_t('metricCondition'), condition));
    if (incorrect != null) metrics.add(MapEntry(_t('metricIncorrect'), incorrect));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: premiumCardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "[$period $subject] $duration",
                  style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: recordTypeLabel == '강의' ? Colors.blueAccent.withValues(alpha: 0.2) : brandGolden.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _recordTypeDisplay(recordTypeLabel),
                  style: GoogleFonts.notoSansKr(
                    color: recordTypeLabel == '강의' ? Colors.lightBlueAccent : brandGolden,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _tf('detailContentFormat', {'content': content}),
            style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: metrics.map((m) => _buildMiniMetricBox(m.key, m.value)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniMetricBox(String label, String val) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: luxuryDarkBg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(val, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAlignedVariationRow(String title, String yesterday, String weekly) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text("- $title", style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(yesterday, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12)),
              Text(weekly, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 11.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextFeatureRow(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: "$label : ", style: GoogleFonts.notoSansKr(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
          TextSpan(text: value, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}
