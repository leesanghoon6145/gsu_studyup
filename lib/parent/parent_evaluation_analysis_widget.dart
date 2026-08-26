import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../services/grade_language.dart';
import '../global_lang.dart';

// ---------------------------------------------------------------------------
// 🆕 [12개국어] 이 화면 전용 번역 사전. 공통 개념(학년/학기/숫자 어순 등)은
// grade_language.dart를 그대로 재사용하고, 이 화면에만 있는 문구만 여기 추가합니다.
// ---------------------------------------------------------------------------
const Map<String, Map<String, String>> kEvalTypeLabelMap = {
  "주평가": {'KO': '주평가', 'EN': 'Weekly', 'JA': '週評価', 'ZH': '周评价', 'FR': 'Hebdo', 'DE': 'Wöchentlich', 'RU': 'Недельная', 'AR': 'أسبوعي', 'HI': 'साप्ताहिक', 'VI': 'Hàng tuần', 'ES': 'Semanal', 'TH': 'รายสัปดาห์'},
  "단원평가": {'KO': '단원평가', 'EN': 'Unit Test', 'JA': '単元評価', 'ZH': '单元评价', 'FR': 'Unité', 'DE': 'Einheitstest', 'RU': 'По разделу', 'AR': 'اختبار الوحدة', 'HI': 'इकाई परीक्षण', 'VI': 'KT chương', 'ES': 'Examen de unidad', 'TH': 'ทดสอบหน่วย'},
  "중간고사": {'KO': '중간고사', 'EN': 'Midterm', 'JA': '中間試験', 'ZH': '期中考试', 'FR': 'Mi-parcours', 'DE': 'Zwischenprüfung', 'RU': 'Промежуточный', 'AR': 'اختبار نصفي', 'HI': 'मिडटर्म', 'VI': 'Giữa kỳ', 'ES': 'Parcial', 'TH': 'กลางภาค'},
  "기말고사": {'KO': '기말고사', 'EN': 'Final', 'JA': '期末試験', 'ZH': '期末考试', 'FR': 'Final', 'DE': 'Abschlussprüfung', 'RU': 'Итоговый', 'AR': 'اختبار نهائي', 'HI': 'फाइनल', 'VI': 'Cuối kỳ', 'ES': 'Final', 'TH': 'ปลายภาค'},
  "모의고사": {'KO': '모의고사', 'EN': 'Mock Exam', 'JA': '模試', 'ZH': '模拟考试', 'FR': 'Examen blanc', 'DE': 'Testexamen', 'RU': 'Пробный экзамен', 'AR': 'اختبار تجريبي', 'HI': 'मॉक परीक्षा', 'VI': 'Thi thử', 'ES': 'Examen simulado', 'TH': 'ข้อสอบจำลอง'},
};
String evalTypeLabel(String koType) => bi(kEvalTypeLabelMap[koType] ?? {'KO': koType, 'EN': koType});

String childRecordTitle(String childName) {
  final Map<String, String> map = {
    'KO': '"$childName" 성적 기록 보기', 'EN': 'Viewing "$childName" Grade Records',
    'JA': '「$childName」の成績記録を見る', 'ZH': '查看"$childName"的成绩记录',
    'FR': 'Voir les notes de "$childName"', 'DE': 'Noten von "$childName" ansehen',
    'RU': 'Просмотр оценок «$childName»', 'AR': 'عرض درجات "$childName"',
    'HI': '"$childName" के ग्रेड रिकॉर्ड देखें', 'VI': 'Xem điểm của "$childName"',
    'ES': 'Ver calificaciones de "$childName"', 'TH': 'ดูบันทึกคะแนนของ "$childName"',
  };
  return t(map);
}

const Map<String, String> kWeeklyPastFilterMap = {'KO': '[주평가 과거 선택 조회]', 'EN': '[Browse Past Weekly Evaluations]', 'JA': '[週評価 過去照会]', 'ZH': '[查询过往周评价]', 'FR': '[Consulter les évaluations hebdo passées]', 'DE': '[Frühere wöchentliche Bewertungen]', 'RU': '[Просмотр прошлых недельных оценок]', 'AR': '[استعراض التقييمات الأسبوعية السابقة]', 'HI': '[पिछली साप्ताहिक समीक्षाएं देखें]', 'VI': '[Xem đánh giá tuần trước]', 'ES': '[Ver evaluaciones semanales anteriores]', 'TH': '[ดูการประเมินรายสัปดาห์ที่ผ่านมา]'};
const Map<String, String> kYearSelectLabelMap = {'KO': '년도 선택', 'EN': 'Select Year', 'JA': '年度選択', 'ZH': '选择年份', 'FR': "Sélectionner l'année", 'DE': 'Jahr auswählen', 'RU': 'Выбор года', 'AR': 'اختيار السنة', 'HI': 'वर्ष चुनें', 'VI': 'Chọn năm', 'ES': 'Seleccionar año', 'TH': 'เลือกปี'};
const Map<String, String> kMonthSelectLabelMap = {'KO': '월 선택', 'EN': 'Select Month', 'JA': '月選択', 'ZH': '选择月份', 'FR': 'Sélectionner le mois', 'DE': 'Monat auswählen', 'RU': 'Выбор месяца', 'AR': 'اختيار الشهر', 'HI': 'माह चुनें', 'VI': 'Chọn tháng', 'ES': 'Seleccionar mes', 'TH': 'เลือกเดือน'};
const Map<String, String> kWeekSelectLabelMap = {'KO': '주 평가 선택', 'EN': 'Select Week', 'JA': '週選択', 'ZH': '选择周次', 'FR': 'Sélectionner la semaine', 'DE': 'Woche auswählen', 'RU': 'Выбор недели', 'AR': 'اختيار الأسبوع', 'HI': 'सप्ताह चुनें', 'VI': 'Chọn tuần', 'ES': 'Seleccionar semana', 'TH': 'เลือกสัปดาห์'};
const Map<String, String> kBigUnitSelectLabelMap = {'KO': '대단원 선택', 'EN': 'Select Unit', 'JA': '大単元選択', 'ZH': '选择大单元', 'FR': "Sélectionner l'unité", 'DE': 'Einheit auswählen', 'RU': 'Выбор раздела', 'AR': 'اختيار الوحدة', 'HI': 'इकाई चुनें', 'VI': 'Chọn chương lớn', 'ES': 'Seleccionar unidad', 'TH': 'เลือกหน่วยใหญ่'};
const Map<String, String> kMidUnitSelectLabelMap = {'KO': '중단원 선택', 'EN': 'Select Sub-unit', 'JA': '中単元選択', 'ZH': '选择中单元', 'FR': "Sélectionner la sous-unité", 'DE': 'Untereinheit auswählen', 'RU': 'Выбор подраздела', 'AR': 'اختيار الوحدة الفرعية', 'HI': 'उप-इकाई चुनें', 'VI': 'Chọn chương nhỏ', 'ES': 'Seleccionar subunidad', 'TH': 'เลือกหน่วยย่อย'};
const Map<String, String> kGradeThenSemesterHintMap = {
  'KO': '학년 선택하면 해당 학기가 활성화됩니다', 'EN': 'Select a grade to activate its semesters',
  'JA': '学年を選択すると該当学期が有効になります', 'ZH': '选择年级后将激活对应学期',
  'FR': 'Sélectionnez un niveau pour activer ses semestres', 'DE': 'Klasse auswählen, um die Semester zu aktivieren',
  'RU': 'Выберите класс, чтобы активировать его семестры', 'AR': 'اختر الصف لتفعيل فصوله الدراسية',
  'HI': 'सेमेस्टर सक्रिय करने के लिए कक्षा चुनें', 'VI': 'Chọn khối để kích hoạt học kỳ tương ứng',
  'ES': 'Seleccione un grado para activar sus semestres', 'TH': 'เลือกระดับชั้นเพื่อเปิดใช้งานภาคเรียน',
};
const Map<String, String> kSemesterSelectLabelMap = {'KO': '학기 선택', 'EN': 'Select Semester', 'JA': '学期選択', 'ZH': '选择学期', 'FR': 'Sélectionner le semestre', 'DE': 'Semester auswählen', 'RU': 'Выбор семестра', 'AR': 'اختيار الفصل الدراسي', 'HI': 'सेमेस्टर चुनें', 'VI': 'Chọn học kỳ', 'ES': 'Seleccionar semestre', 'TH': 'เลือกภาคเรียน'};
const Map<String, String> kGraphTargetInfraMap = {
  'KO': '그래프 출력 타겟 지정 (학년/학기 연동 인프라 대기 완료)', 'EN': 'Graph output target set (grade/semester integration ready)',
  'JA': 'グラフ出力対象を指定（学年・学期連動インフラ待機完了）', 'ZH': '已指定图表输出目标（年级/学期联动基础设施就绪）',
  'FR': "Cible du graphique définie (intégration niveau/semestre prête)", 'DE': 'Diagrammziel festgelegt (Klasse/Semester-Integration bereit)',
  'RU': 'Цель графика задана (интеграция класс/семестр готова)', 'AR': 'تم تحديد هدف الرسم البياني (تكامل الصف/الفصل جاهز)',
  'HI': 'ग्राफ आउटपुट लक्ष्य निर्धारित (कक्षा/सेमेस्टर एकीकरण तैयार)', 'VI': 'Đã đặt mục tiêu biểu đồ (đã sẵn sàng tích hợp khối/học kỳ)',
  'ES': 'Objetivo del gráfico establecido (integración de grado/semestre lista)', 'TH': 'กำหนดเป้าหมายกราฟแล้ว (พร้อมเชื่อมโยงระดับชั้น/ภาคเรียน)',
};

const Map<String, String> kDailyTabMap = {'KO': '일간', 'EN': 'Daily', 'JA': '日間', 'ZH': '日', 'FR': 'Jour', 'DE': 'Täglich', 'RU': 'День', 'AR': 'يومي', 'HI': 'दैनिक', 'VI': 'Ngày', 'ES': 'Diario', 'TH': 'รายวัน'};
const Map<String, String> kWeeklyTabMap = {'KO': '주간', 'EN': 'Weekly', 'JA': '週間', 'ZH': '周', 'FR': 'Semaine', 'DE': 'Wöchentlich', 'RU': 'Неделя', 'AR': 'أسبوعي', 'HI': 'साप्ताहिक', 'VI': 'Tuần', 'ES': 'Semanal', 'TH': 'รายสัปดาห์'};
const Map<String, String> kMonthlyTabMap = {'KO': '월간', 'EN': 'Monthly', 'JA': '月間', 'ZH': '月', 'FR': 'Mois', 'DE': 'Monatlich', 'RU': 'Месяц', 'AR': 'شهري', 'HI': 'मासिक', 'VI': 'Tháng', 'ES': 'Mensual', 'TH': 'รายเดือน'};
const Map<String, String> kYearlyTabMap = {'KO': '연간', 'EN': 'Yearly', 'JA': '年間', 'ZH': '年', 'FR': 'Année', 'DE': 'Jährlich', 'RU': 'Год', 'AR': 'سنوي', 'HI': 'वार्षिक', 'VI': 'Năm', 'ES': 'Anual', 'TH': 'รายปี'};

const Map<String, String> kTodayAnalysisReportBtnMap = {
  'KO': '금일 자녀 학업 성취도 정밀 분석 리포트 조회', 'EN': "View Today's Detailed Achievement Analysis Report",
  'JA': '本日のお子様学業成就度精密分析レポート照会', 'ZH': '查询今日孩子学业成就精密分析报告',
  'FR': "Voir le rapport d'analyse détaillé de réussite du jour", 'DE': 'Heutigen detaillierten Leistungsanalysebericht ansehen',
  'RU': 'Смотреть подробный отчёт об успеваемости за сегодня', 'AR': 'عرض تقرير التحليل الدقيق لتحصيل الطفل اليوم',
  'HI': 'आज के बच्चे की उपलब्धि विश्लेषण रिपोर्ट देखें', 'VI': 'Xem báo cáo phân tích thành tích chi tiết hôm nay',
  'ES': 'Ver informe de análisis detallado de logros de hoy', 'TH': 'ดูรายงานวิเคราะห์ผลสัมฤทธิ์อย่างละเอียดวันนี้',
};

String noEvalRecordsText(String koType) {
  final type = evalTypeLabel(koType);
  final Map<String, String> map = {
    'KO': '아직 "$type" 기록이 없습니다.\n평가가 기록되면 자동으로 표시됩니다.',
    'EN': 'No "$type" records yet.\nThey will appear automatically once evaluations are recorded.',
    'JA': 'まだ「$type」記録がありません。\n評価が記録されると自動的に表示されます。',
    'ZH': '暂无"$type"记录。\n评价录入后将自动显示。',
    'FR': "Aucun enregistrement « $type » pour le moment.\nIls apparaîtront automatiquement une fois les évaluations enregistrées.",
    'DE': 'Noch keine „$type"-Einträge.\nSie erscheinen automatisch, sobald Bewertungen erfasst werden.',
    'RU': 'Пока нет записей «$type».\nОни появятся автоматически после записи оценок.',
    'AR': 'لا توجد سجلات "$type" بعد.\nستظهر تلقائيًا بمجرد تسجيل التقييمات.',
    'HI': 'अभी तक कोई "$type" रिकॉर्ड नहीं है।\nमूल्यांकन दर्ज होते ही स्वतः दिखाई देंगे।',
    'VI': 'Chưa có hồ sơ "$type" nào.\nSẽ tự động hiển thị khi có đánh giá được ghi nhận.',
    'ES': 'Aún no hay registros de "$type".\nAparecerán automáticamente cuando se registren evaluaciones.',
    'TH': 'ยังไม่มีบันทึก "$type"\nจะแสดงโดยอัตโนมัติเมื่อมีการบันทึกผลประเมิน',
  };
  return t(map);
}

const Map<String, String> kSelfSubjectAvgMap = {'KO': '본인 과목 평균', 'EN': 'Own Subject Average', 'JA': '本人科目平均', 'ZH': '本人科目平均', 'FR': 'Moyenne perso. par matière', 'DE': 'Eigener Fachdurchschnitt', 'RU': 'Средн. по своим предметам', 'AR': 'متوسط مواد الطالب', 'HI': 'स्वयं का विषय औसत', 'VI': 'TB môn của bản thân', 'ES': 'Promedio propio por materia', 'TH': 'ค่าเฉลี่ยวิชาของตนเอง'};
const Map<String, String> kNoTimeDataMap = {'KO': '아직 집계된 학습시간 기록이 없습니다.', 'EN': 'No study time data aggregated yet.', 'JA': 'まだ集計された学習時間記録がありません。', 'ZH': '暂无汇总的学习时间记录。', 'FR': "Aucune donnée de temps d'étude agrégée pour le moment.", 'DE': 'Noch keine aggregierten Lernzeitdaten.', 'RU': 'Пока нет агрегированных данных о времени учёбы.', 'AR': 'لا توجد بيانات وقت دراسة مجمعة بعد.', 'HI': 'अभी तक कोई संकलित अध्ययन समय डेटा नहीं है।', 'VI': 'Chưa có dữ liệu tổng hợp thời gian học.', 'ES': 'Aún no hay datos agregados de tiempo de estudio.', 'TH': 'ยังไม่มีข้อมูลเวลาเรียนที่รวบรวมไว้'};

// 🆕 [12개국어] 섹션 타이틀 대괄호 표기 - 외국어 선택 시 표시 (기본모드는 기존 영문+한글 유지)
const Map<String, String> kSecEvalResultMap = {'FR': '[ Résultats des évaluations ]', 'DE': '[ Bewertungsergebnisse ]', 'RU': '[ Результаты оценок ]', 'AR': '[ نتائج التقييم ]', 'HI': '[ मूल्यांकन परिणाम ]', 'VI': '[ Kết quả đánh giá ]', 'ES': '[ Resultados de evaluación ]', 'TH': '[ ผลการประเมิน ]', 'JA': '[ 評価結果 ]', 'ZH': '[ 评价结果 ]'};
const Map<String, String> kSecSubjectScoresMap = {'FR': '[ Notes par matière ]', 'DE': '[ Fachnoten ]', 'RU': '[ Баллы по предметам ]', 'AR': '[ درجات المواد ]', 'HI': '[ विषय अंक ]', 'VI': '[ Điểm môn học ]', 'ES': '[ Notas por materia ]', 'TH': '[ คะแนนวิชา ]', 'JA': '[ 科目点数 ]', 'ZH': '[ 科目分数 ]'};
const Map<String, String> kSecTimeDashboardMap = {'FR': "[ Temps d'étude ]", 'DE': '[ Lernzeit ]', 'RU': '[ Время учёбы ]', 'AR': '[ وقت الدراسة ]', 'HI': '[ अध्ययन समय ]', 'VI': '[ Thời gian học ]', 'ES': '[ Tiempo de estudio ]', 'TH': '[ เวลาเรียน ]', 'JA': '[ 学習時間 ]', 'ZH': '[ 学习时间 ]'};
const Map<String, String> kSecDiagAnalysisMap = {'FR': "[ Analyse d'évaluation du jour ]", 'DE': '[ Heutige Bewertungsanalyse ]', 'RU': '[ Анализ оценок за сегодня ]', 'AR': '[ تحليل تقييم اليوم ]', 'HI': '[ आज का मूल्यांकन विश्लेषण ]', 'VI': '[ Phân tích đánh giá hôm nay ]', 'ES': '[ Análisis de evaluación de hoy ]', 'TH': '[ วิเคราะห์ผลประเมินวันนี้ ]', 'JA': '[ 本日の評価分析 ]', 'ZH': '[ 今日评价分析 ]'};
const Map<String, String> kSecSubjectRatioMap = {'FR': '[ Répartition par matière ]', 'DE': '[ Fächerverteilung ]', 'RU': '[ Доля по предметам ]', 'AR': '[ نسبة المواد ]', 'HI': '[ विषय अनुपात ]', 'VI': '[ Tỷ lệ môn học ]', 'ES': '[ Proporción por materia ]', 'TH': '[ สัดส่วนวิชา ]', 'JA': '[ 科目比率 ]', 'ZH': '[ 科目比例 ]'};

// ---------------------------------------------------------------------------
// 🆕 [12개국어] 연/월/주 칩 - 숫자+단어 어순은 grade_language.dart의 isNumberFirstLang 재사용
// [요청] "2026년/2026" 같은 한글+영문 병기 대신, 현재 선택된 언어 하나로만 "2026 year" 형태로 표시
// ---------------------------------------------------------------------------
const Map<String, String> kYearWordMap = {'KO': '년', 'EN': 'year', 'JA': '年', 'ZH': '年', 'FR': 'an', 'DE': 'Jahr', 'RU': 'год', 'AR': 'عام', 'HI': 'वर्ष', 'VI': 'năm', 'ES': 'año', 'TH': 'ปี'};
const Map<String, String> kMonthWordMap = {'KO': '월', 'EN': '', 'JA': '月', 'ZH': '月', 'FR': '', 'DE': '', 'RU': '', 'AR': '', 'HI': '', 'VI': '', 'ES': '', 'TH': ''};
const Map<String, String> kWeekWordMap = {'KO': '주차', 'EN': 'Week', 'JA': '週目', 'ZH': '周', 'FR': 'Semaine', 'DE': 'Woche', 'RU': 'Неделя', 'AR': 'أسبوع', 'HI': 'सप्ताह', 'VI': 'Tuần', 'ES': 'Semana', 'TH': 'สัปดาห์'};
const Map<String, String> kBigUnitWordMap = {'KO': '대단원', 'EN': 'Unit', 'JA': '大単元', 'ZH': '大单元', 'FR': 'Unité', 'DE': 'Einheit', 'RU': 'Раздел', 'AR': 'الوحدة', 'HI': 'इकाई', 'VI': 'Chương', 'ES': 'Unidad', 'TH': 'หน่วยใหญ่'};
const Map<String, String> kMidUnitWordMap = {'KO': '중단원', 'EN': 'Sub-unit', 'JA': '中単元', 'ZH': '中单元', 'FR': 'Sous-unité', 'DE': 'Untereinheit', 'RU': 'Подраздел', 'AR': 'الوحدة الفرعية', 'HI': 'उप-इकाई', 'VI': 'Chương nhỏ', 'ES': 'Subunidad', 'TH': 'หน่วยย่อย'};

// 🆕 [요청] 월 표기는 KO/JA/ZH만 "N월/N月" 그대로 두고, 나머지 전 언어는
// "07 Jul"처럼 2자리 숫자 + 영문 약어로 통일 (국제적으로 통용되는 날짜 표기 관례)
const List<String> kEnMonthAbbrev = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String yearChipLabel(int year) {
  // 🆕 [요청] "2026년/2026" 병기 대신 현재 언어로만 "2026 year"/"2026년" 형태로 단일 표시
  final w = t(kYearWordMap);
  return isNumberFirstLang ? "$year$w" : "$year $w";
}

String monthChipLabel(int month) {
  if (['KO', 'JA', 'ZH'].contains(DkeLang.current)) {
    return "$month${t(kMonthWordMap)}";
  }
  final String mm = month.toString().padLeft(2, '0');
  return "$mm ${kEnMonthAbbrev[month - 1]}";
}

String weekChipLabel(int week) {
  final w = t(kWeekWordMap);
  return isNumberFirstLang ? "$week$w" : "$w $week";
}

String bigUnitChipLabel(int n) {
  final w = t(kBigUnitWordMap);
  if (DkeLang.isForeignSelected) return "$w $n";
  return "${kBigUnitWordMap['KO']} $n/${kBigUnitWordMap['EN']} $n";
}

String midUnitChipLabel(int n) {
  final w = t(kMidUnitWordMap);
  if (DkeLang.isForeignSelected) return "$w $n";
  return "${kMidUnitWordMap['KO']} $n/${kMidUnitWordMap['EN']} $n";
}

class ParentEvaluationAnalysisWidget extends StatelessWidget {
  final String childName;
  final String selectedEvaluationType;
  final String selectedBigUnit;
  final String selectedMidUnit;
  final int selectedSemesterFilter;
  // 🆕 [버그 수정] 주평가 전용 년/월/주차 상태 - 기존엔 단원평가용 selectedBigUnit/selectedMidUnit을
  // 그대로 빌려쓰고 있어서 월/주차가 서로 덮어쓰며 충돌했고, 애초에 필터링에 반영도 안 되고 있었음.
  final String selectedYear;
  final String selectedMonth;
  final String selectedWeek;
  final TabController timeTabController;
  final List<dynamic> mirroredExamRecords;
  final List<Map<String, dynamic>> parentMasterTimeData;
  final Color premiumCardBg;
  final Color brandGolden;
  final Color luxuryDarkBg;
  final Function(String) onEvaluationTypeChanged;
  final Function(String) onBigUnitChanged;
  final Function(String) onMidUnitChanged;
  final Function(int) onSemesterFilterChanged;
  final Function(String) onYearChanged;
  final Function(String) onMonthChanged;
  final Function(String) onWeekChanged;
  final VoidCallback onShowDetailAnalysisReport;
  final Widget Function(String, String, {required double fontSize, String? foreignTitle}) buildCustomSectionTitle;

  const ParentEvaluationAnalysisWidget({
    Key? key,
    required this.childName,
    required this.selectedEvaluationType,
    required this.selectedBigUnit,
    required this.selectedMidUnit,
    required this.selectedSemesterFilter,
    required this.selectedYear,
    required this.selectedMonth,
    required this.selectedWeek,
    required this.timeTabController,
    required this.mirroredExamRecords,
    required this.parentMasterTimeData,
    required this.premiumCardBg,
    required this.brandGolden,
    required this.luxuryDarkBg,
    required this.onEvaluationTypeChanged,
    required this.onBigUnitChanged,
    required this.onMidUnitChanged,
    required this.onSemesterFilterChanged,
    required this.onYearChanged,
    required this.onMonthChanged,
    required this.onWeekChanged,
    required this.onShowDetailAnalysisReport,
    required this.buildCustomSectionTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(child: buildCustomSectionTitle("Academic Evaluation Matrix", "[ 평가 결과 ]", fontSize: 14.0, foreignTitle: t(kSecEvalResultMap))),
              const SizedBox(width: 8),
              // 🆕 [오버플로우 수정] 영문 등 긴 언어에서 이름이 길어지면 오른쪽 끝으로 말줄임 처리
              Flexible(
                child: Text(
                  childRecordTitle(childName),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ["주평가", "단원평가", "중간고사", "기말고사", "모의고사"].map((type) {
                bool isSelected = selectedEvaluationType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(evalTypeLabel(type), style: GoogleFonts.notoSansKr(color: isSelected ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    selected: isSelected,
                    selectedColor: brandGolden,
                    backgroundColor: premiumCardBg,
                    onSelected: (_) => onEvaluationTypeChanged(type),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: premiumCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: brandGolden.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectedEvaluationType == "주평가") ...[
                  Text(t(kWeeklyPastFilterMap), style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(t(kYearSelectLabelMap), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ["2026년", "2027년", "2028년", "2029년", "2030년"].map((y) {
                        final int yearNum = int.parse(y.replaceAll('년', ''));
                        return Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: _buildInlineFilterChip(yearChipLabel(yearNum), selectedYear == y, () => onYearChanged(y)),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(t(kMonthSelectLabelMap), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    dropdownColor: premiumCardBg,
                    value: selectedMonth,
                    style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                    items: List.generate(12, (i) => "${i + 1}월").map((m) {
                      final int monthNum = int.parse(m.replaceAll('월', ''));
                      return DropdownMenuItem<String>(value: m, child: Text(monthChipLabel(monthNum)));
                    }).toList(),
                    onChanged: (val) => onMonthChanged(val!),
                  ),
                  const SizedBox(height: 8),
                  Text(t(kWeekSelectLabelMap), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ["1주차", "2주차", "3주차", "4주차", "5주차"].map((w) {
                        final int weekNum = int.parse(w.replaceAll('주차', ''));
                        return Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: _buildInlineFilterChip(weekChipLabel(weekNum), selectedWeek == w, () => onWeekChanged(w)),
                        );
                      }).toList(),
                    ),
                  ),
                ] else if (selectedEvaluationType == "단원평가") ...[
                  // 🆕 [단원 확장] 과목마다 대단원 개수가 다름(4단원짜리도, 12단원짜리도 있음)을 고려해
                  // 대단원 1~12까지 전부 노출하고 가로 스크롤로 넘겨볼 수 있게 함.
                  Text(t(kBigUnitSelectLabelMap), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(12, (i) => "대단원 ${i + 1}").map((v) {
                        final int n = int.parse(v.replaceAll('대단원 ', ''));
                        return Padding(padding: const EdgeInsets.only(right:4), child: _buildInlineFilterChip(bigUnitChipLabel(n), selectedBigUnit == v, () => onBigUnitChanged(v)));
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(t(kMidUnitSelectLabelMap), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ["중단원 1", "중단원 2", "중단원 3", "중단원 4"].map((v) {
                        final int n = int.parse(v.replaceAll('중단원 ', ''));
                        return Padding(padding: const EdgeInsets.only(right:4), child: _buildInlineFilterChip(midUnitChipLabel(n), selectedMidUnit == v, () => onMidUnitChanged(v)));
                      }).toList(),
                    ),
                  ),
                ] else ...[
                  Text(t(kGradeThenSemesterHintMap), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ["1학년", "2학년", "3학년"].map((g) {
                        final int n = int.parse(g.replaceAll('학년', ''));
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _buildInlineFilterChip(gradeChipLabel(n), selectedBigUnit == g, () { onBigUnitChanged(g); onSemesterFilterChanged(1); }),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(t(kSemesterSelectLabelMap), style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildInlineFilterChip(semesterChipLabel(1), selectedSemesterFilter == 1, () => onSemesterFilterChanged(1)),
                      const SizedBox(width: 6),
                      _buildInlineFilterChip(semesterChipLabel(2), selectedSemesterFilter == 2, () => onSemesterFilterChanged(2)),
                    ],
                  ),
                ],
                const Divider(color: Colors.white10, height: 16),
                Text(t(kGraphTargetInfraMap), style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          buildCustomSectionTitle("Subject Scores", "[ 과목 점수 ]", fontSize: 14.0, foreignTitle: t(kSecSubjectScoresMap)),
          const SizedBox(height: 12),
          _buildParentEvaluationChart(selectedEvaluationType),
          const SizedBox(height: 24),

          buildCustomSectionTitle("Learning Time Dashboard", "[ 학습시간 ]", fontSize: 14.0, foreignTitle: t(kSecTimeDashboardMap)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity, height: 42, padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFF0D1527), borderRadius: BorderRadius.circular(10), border: Border.all(color: brandGolden.withValues(alpha: 0.3))),
            child: TabBar(
              controller: timeTabController,
              indicator: BoxDecoration(color: brandGolden, borderRadius: const BorderRadius.all(Radius.circular(6))),
              labelColor: Colors.black, unselectedLabelColor: Colors.white,
              labelStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.w900, fontSize: 12),
              unselectedLabelStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold, fontSize: 12),
              tabs: [Tab(text: t(kDailyTabMap)), Tab(text: t(kWeeklyTabMap)), Tab(text: t(kMonthlyTabMap)), Tab(text: t(kYearlyTabMap))],
            ),
          ),
          const SizedBox(height: 14),

          _buildParentTimeChartDashboard(timeTabController.index),

          const Divider(color: Colors.white10, height: 32),
          buildCustomSectionTitle("Diagnostic Evaluation Analysis", "[ 오늘의 평가 분석 ]", fontSize: 14.0, foreignTitle: t(kSecDiagAnalysisMap)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D1527),
              side: BorderSide(color: brandGolden, width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              shadowColor: brandGolden.withValues(alpha: 0.1),
            ),
            onPressed: onShowDetailAnalysisReport,
            icon: Icon(Icons.analytics_rounded, color: brandGolden, size: 18),
            label: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 🆕 [오버플로우 수정] 영문 등 긴 언어에서 버튼 안 문구가 넘치지 않도록
                // Expanded + 2줄 허용으로 감싸고, 화살표 아이콘은 고정 폭 유지
                Expanded(
                  child: Text(
                    t(kTodayAnalysisReportBtnMap),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded, color: brandGolden, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 [실데이터 연동] mirroredExamRecords(gke_exam_records 실제 데이터)만 사용,
  // 기록이 없으면 가짜 점수 대신 빈 상태 안내를 표시합니다.
  Widget _buildParentEvaluationChart(String type) {
    List<dynamic> rawRecords = mirroredExamRecords.where((rec) => rec.type == type).toList();

    // 🆕 [버그 수정] 년도/월/주차 선택이 화면에 전혀 반영되지 않던 문제 - 필터링 로직이 아예
    // 없었음. 학생 화면(member_achievement_screen.dart _getFilteredRecords)과 동일하게
    // rec.unit에 선택한 년/월/주차 문자열이 모두 포함된 기록만 남기도록 수정.
    if (type == "주평가") {
      rawRecords = rawRecords.where((rec) {
        final String unit = rec.unit.toString();
        return unit.contains(selectedYear) && unit.contains(selectedMonth) && unit.contains(selectedWeek);
      }).toList();
    }

    if (rawRecords.isEmpty) {
      return Container(
        height: 140,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: premiumCardBg, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text(
          noEvalRecordsText(type),
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12, height: 1.5),
        ),
      );
    }

    final List<Color> scoreColors = [
      const Color(0xFF34C759),
      const Color(0xFFFF3B30),
      const Color(0xFF007AFF),
      const Color(0xFFFFCC00),
      const Color(0xFFAF52DE),
      const Color(0xFFFF9500),
      const Color(0xFF0500FF),
    ];

    // 🆕 [버그 수정] 막대 스케일과 Y축 라벨 위치가 서로 다른 기준으로 계산되어 어긋나던 문제 -
    // Y축 세로 폭을 줄이고(220→190) 카드 전체 높이는 넉넉하게 늘려서(275→300) 막대가 X축을 넘지 않도록 함
    const double chartMaxHeight = 210.0;
    // 🆕 [12개국어] "점" 단위는 언어마다 표기가 달라 숫자만 표시(전 언어 공통)
    final List<String> scores = ["100", "90", "80", "70", "60"];
    // 🆕 [원장님 최종 확정] 막대 폭 32 / 20 고정 (member_achievement_screen.dart와 동일 원칙)
    const double barWidth = 20.0;
    // 🆕 [요청] X축 아래 과목명칭 영역이 좁아서 조금 넓힘 (6→9)
    const double barMargin = 9.0;

    return Container(
      height: 300,
      padding: const EdgeInsets.only(top: 24, bottom: 4, left: 12, right: 12),
      decoration: BoxDecoration(color: premiumCardBg, borderRadius: BorderRadius.circular(12)),
      // 🆕 [버그 수정] 막대+라벨을 스크롤 하나로 합치는 과정에서 실수로 빠졌던 X축 기준선(60점 가로선)을
      // Stack + Positioned로 복원. 스크롤 여부와 무관하게 항상 고정된 위치(60점 높이)에 표시됩니다.
      child: Stack(
        children: [
          Row(
            // 🆕 [버그 수정] stretch로 인해 Y축 라벨/세로선이 카드 전체 높이만큼 늘어나서
            // "60점" 라벨이 실제 막대 스케일(chartMaxHeight)보다 훨씬 아래에 표시되던 근본 원인 수정.
            // 이제 Y축도 막대와 정확히 같은 chartMaxHeight를 기준으로 그려서 눈금과 막대가 딱 맞습니다.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 17),
                child: SizedBox(
                  width: 37,
                  height: chartMaxHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: scores.map((s) => Container(
                      height: 16,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(s, style: GoogleFonts.rajdhani(color: brandGolden, fontSize: 12, fontWeight: FontWeight.w600)),
                    )).toList(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 17),
                child: SizedBox(
                  height: chartMaxHeight,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(width: 2.5, color: brandGolden),
                      Positioned.fill(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(5, (idx) => Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 🆕 [버그 수정] 막대와 과목명 라벨을 같은 스크롤 안에 하나로 합쳐서, 막대만 스크롤되고
              // 라벨은 고정된 채 화면 밖으로 튕겨나가던(오른쪽 오버플로우) 문제를 근본적으로 해결
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(rawRecords.length, (idx) {
                      final rec = rawRecords[idx];
                      Color barColor = scoreColors[idx % scoreColors.length];

                      double normalizedScore = (rec.score - 60).clamp(0.0, 40.0);
                      // 🆕 [요청] 100점일 때 점수 숫자가 위쪽 여백 부족으로 안 보이던 문제 수정 -
                      // 막대 최대 높이를 chartMaxHeight의 82%로 제한해서 점수 라벨이 들어갈 여유 공간을 확보
                      double finalBarHeight = (normalizedScore / 40) * (chartMaxHeight * 0.99);

                      return Container(
                        width: barWidth + (barMargin * 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: chartMaxHeight + 15,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  Positioned(
                                    bottom: finalBarHeight + 1,
                                    child: Text(
                                      "${rec.score.toInt()}%",
                                      style: GoogleFonts.rajdhani(color: barColor, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -0,
                                    child: Container(
                                      height: finalBarHeight < 4 ? 4 : finalBarHeight,
                                      width: barWidth,
                                      decoration: BoxDecoration(
                                        color: barColor,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 30,
                              child: Text(
                                rec.subject,
                                textAlign: TextAlign.center,
                                maxLines: 2, // 🆕 [요청] 과목명이 길어도 2줄까지 허용, 넘치면 말줄임
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, height: 1.2),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
          // 🆕 [버그 수정] X축 기준선(60점 라인) - 세로선이 시작하는 지점부터 오른쪽 끝까지, 60점 높이에 고정 표시
          Positioned(
            left: 37,
            right: 0,
            top: chartMaxHeight +15,
            child: Container(height: 2.5, color: brandGolden),
          ),
        ],
      ),
    );
  }

  // 🆕 [실데이터 연동] parentMasterTimeData(ParentDataService.loadSubjectAggregates() 결과)를
  // 사용해 실제 학습시간 막대그래프를 그립니다. "평균"은 다른 학생과 비교할 서버 데이터가 없는
  // 현재로서는 본인 과목들의 평균값으로 표시합니다(member_achievement_screen.dart와 동일한 처리 방식).
  Widget _buildParentTimeChartDashboard(int tabIndex) {
    final List<String> flagKeys = ["hasStudiedToday", "hasStudiedWeekly", "hasStudiedMonthly", "hasStudiedYearly"];
    final String flagKey = flagKeys[tabIndex];
    final String unitLabel = tabIndex == 0 ? "" : "h";
    double multiplier = (tabIndex == 0) ? 1.0 : (tabIndex == 1) ? 5.0 : (tabIndex == 2) ? 22.0 : 250.0;

    List<Map<String, dynamic>> subjectData = parentMasterTimeData
        .where((e) => e[flagKey] == true)
        .map((e) => {
      "subject": e["subject"] as String,
      "value": (e["baseMinutes"] as int) * multiplier,
    })
        .where((e) => (e["value"] as double) > 0)
        .toList();

    subjectData.sort((a, b) => (b["value"] as double).compareTo(a["value"] as double));

    if (subjectData.isEmpty) {
      return Container(
        height: 160,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: premiumCardBg, borderRadius: BorderRadius.circular(12)),
        child: Text(t(kNoTimeDataMap), style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12)),
      );
    }

    final double overallAvg = subjectData.map((e) => e["value"] as double).reduce((a, b) => a + b) / subjectData.length;
    for (final item in subjectData) {
      item["avg"] = overallAvg;
    }

    double allMax = subjectData.map((e) => (e["value"] as double) > (e["avg"] as double) ? (e["value"] as double) : (e["avg"] as double)).reduce((a, b) => a > b ? a : b);
    double allMin = subjectData.map((e) => (e["value"] as double) < (e["avg"] as double) ? (e["value"] as double) : (e["avg"] as double)).reduce((a, b) => a < b ? a : b);

    double yMax = tabIndex == 0 ? allMax + 20.0 : allMax + 1.0;
    double yMin = tabIndex == 0 ? (allMin - 20.0).clamp(0.0, double.infinity) : (allMin - 1.0).clamp(0.0, double.infinity);
    double step = (yMax - yMin) / 3;
    List<String> yTicks = List.generate(4, (i) => "${(yMax - step * i).toStringAsFixed(tabIndex == 0 ? 0 : 1)}$unitLabel").toList();

    const double barW = 17.0;
    const double pairGap = 0.7;
    const double groupGap = 8.4; // 🆕 [요청] 과목 간 간격 40% 축소 (14 → 8.4)
    const double chartH = 190.0;

    int totalMinutes = subjectData.fold<int>(0, (sum, e) => sum + (e["value"] as double).round());

    final List<Color> subjectColors = [
      const Color(0xFFFF3B30),
      const Color(0xFF007AFF),
      const Color(0xFF34C759),
      const Color(0xFFFF9500),
      const Color(0xFFAF52DE),
      const Color(0xFFFFCC00),
    ];

    double calcBarH(double val) {
      double delta = (yMax - yMin) == 0 ? 1 : (yMax - yMin);
      // 🆕 [버그 수정] 막대가 꽉 차면 그 위의 숫자 라벨이 위쪽 밖으로 넘치던(overflow) 문제 -
      // 최대 높이를 85%로 제한해서 라벨이 들어갈 여유 공간을 항상 확보
      return ((val - yMin) / delta * chartH).clamp(2.0, chartH * 0.85);
    }

    // 🆕 [요청] "2)수학(A급) 집중 학습 (50분)"처럼 긴 원본 과목명을
    // "2)수학(A급)" / "집중 학습 50분" 두 줄로 자동 정리. "집중 학습" 표현이 없는
    // 과목명은 그대로 두고 화면에서 2줄까지만 허용(넘치면 말줄임).
    List<String> shortSubjectLines(String raw) {
      const marker = '집중 학습';
      final idx = raw.indexOf(marker);
      if (idx > 0) {
        final String line1 = raw.substring(0, idx).trim();
        String line2 = raw.substring(idx).trim();
        line2 = line2.replaceAllMapped(RegExp(r'\((\d+분)\)'), (m) => m.group(1)!);
        return [line1, line2];
      }
      return [raw];
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 12, 0),
          decoration: BoxDecoration(
            color: const Color(0xFF070E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: brandGolden.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(width: 10, height: 10, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(t(kSelfSubjectAvgMap), style: GoogleFonts.notoSansKr(color: Colors.white60, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 6),
              // 🆕 [버그 수정] Y축(왼쪽 눈금)+막대 스크롤 영역을 Stack으로 감싸서, 병합 과정에서
              // 실수로 빠졌던 X축 기준선(0 높이 가로선)을 다시 그려 넣습니다.
              Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          SizedBox(
                            height: chartH,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: 55,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: yTicks.map((t) {
                                      String formattedText = t.contains('h') ? t : '${t.replaceAll('m', '')}m';
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 6.0),
                                        child: Text(
                                          formattedText,
                                          style: GoogleFonts.rajdhani(color: brandGolden, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(width: 2, color: brandGolden),
                                    Positioned.fill(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: List.generate(4, (idx) => Container(
                                          width: 6, height: 6,
                                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                        )),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(subjectData.length, (idx) {
                              final item = subjectData[idx];
                              double avgH = calcBarH((item["avg"] as double));
                              double valH = calcBarH((item["value"] as double));
                              Color col = subjectColors[idx % subjectColors.length];
                              final List<String> labelLines = shortSubjectLines(item["subject"] as String);
                              return Padding(
                                padding: EdgeInsets.only(left: groupGap),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: chartH,
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Text("${(item["avg"] as double).toStringAsFixed(1)}$unitLabel", style: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 2),
                                              Container(width: barW, height: avgH, decoration: const BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.vertical(top: Radius.circular(3)))),
                                            ],
                                          ),
                                          const SizedBox(width: pairGap),
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Text("${(item["value"] as double).toStringAsFixed(1)}$unitLabel", style: GoogleFonts.rajdhani(color: col, fontSize: 8, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 2),
                                              Container(width: barW, height: valH, decoration: BoxDecoration(color: col, borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // 🆕 [버그 수정] 라벨이 1줄이든 2줄이든 항상 같은 높이(28)를 차지하도록 고정 -
                                    // 라벨 줄 수가 다르면 Row(crossAxisAlignment:end) 때문에 막대 자체가
                                    // 위아래로 어긋나 보이던(연간 탭 맨 끝 "수학" 막대만 아래로 처짐) 문제 해결
                                    SizedBox(
                                      width: 64,
                                      height: 28,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: labelLines.map((line) => Text(
                                          line,
                                          textAlign: TextAlign.center,
                                          maxLines: labelLines.length > 1 ? 1 : 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, height: 1.25),
                                        )).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 🆕 [버그 수정] X축 기준선(0 높이 가로선) - Y축 눈금 컬럼(55) 바로 옆부터 오른쪽 끝까지,
                  // 막대 그래프 영역(chartH) 바닥과 정확히 일치하는 위치에 고정 표시
                  Positioned(
                    left: 57,
                    right: 0,
                    top: chartH,
                    child: Container(height: 2, color: brandGolden),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        const Divider(color: Colors.white10, height: 24),
        buildCustomSectionTitle("Subject Ratio", "[ 과목비율 ]", fontSize: 13.0, foreignTitle: t(kSecSubjectRatioMap)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 6,
              child: Center(
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(180, 180),
                        painter: _ParentDashboardPiePainterComponent(subjectData: subjectData, colors: subjectColors),
                      ),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(color: premiumCardBg, shape: BoxShape.circle),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Total', style: GoogleFonts.gowunBatang(color: Colors.white38, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text("${totalMinutes}m", style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(subjectData.length, (idx) {
                  final item = subjectData[idx];
                  final int percent = totalMinutes > 0 ? (((item["value"] as double).round() / totalMinutes) * 100).round() : 0;
                  final Color col = subjectColors[idx % subjectColors.length];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3.0),
                          child: Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // 🆕 [버그 수정] 과목명이 길어 오른쪽으로 넘치던 문제 - Expanded + 2줄 허용으로 해결
                        Expanded(
                          child: Text(
                            "${shortSubjectLines(item["subject"] as String).join(' ')} ($percent%)",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, height: 1.3),
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
      ],
    );
  }

  Widget _buildInlineFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? brandGolden : Colors.black38,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: brandGolden.withValues(alpha: 0.25)),
        ),
        child: Text(label, style: GoogleFonts.notoSansKr(color: isSelected ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// 🆕 [실데이터 연동] 실제 subjectData(value 비중)에 맞춰 파이차트 조각을 그립니다.
class _ParentDashboardPiePainterComponent extends CustomPainter {
  final List<Map<String, dynamic>> subjectData;
  final List<Color> colors;

  _ParentDashboardPiePainterComponent({required this.subjectData, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = subjectData.fold<double>(0.0, (s, i) => s + (i["value"] as double));
    if (total == 0) return;

    final Paint p = Paint()..style = PaintingStyle.fill..isAntiAlias = true;
    double start = -math.pi / 2;

    for (int i = 0; i < subjectData.length; i++) {
      final double value = subjectData[i]["value"] as double;
      final double sweep = (value / total) * 2 * math.pi;
      p.color = colors[i % colors.length];
      canvas.drawArc(Rect.fromLTWH(0, 0, size.width, size.height), start, sweep, true, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) => true;
}
