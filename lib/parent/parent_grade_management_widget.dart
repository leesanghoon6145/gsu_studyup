import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/grade_management_service.dart';
import '../services/grade_diagnosis_service.dart';
import '../services/parent_data_service.dart';
import '../square/grade_management_screen.dart' show kSubjectRainbowColors;
import '../global_lang.dart';

/// ============================================================================
/// [GKE StudyUp] 학부모 화면 - [성적 관리] 탭 (조회 전용)
/// - 학생용 grade_management_screen.dart에서 입력한 데이터를 ParentDataService
///   게이트웨이를 통해서만 읽습니다.
/// - 총평 문구와 그래프는 학생 화면과 완전히 동일하게 미러링됩니다.
/// - 🆕 [다국어] DkeLang 연동: 기본모드(KO/EN 선택)는 한글+영문 동시 표시,
///   10개국어(JA/ZH/FR/DE/RU/AR/HI/VI/ES/TH) 선택 시 해당 언어만 단독 표시.
///   실제 데이터 저장 키(과목명·시험종류 등 한글 원문)는 절대 바꾸지 않고,
///   화면에 보여줄 때만 이 파일 안의 번역 사전을 거쳐 표시합니다.
/// ============================================================================

// 🆕 [다국어] 공용 조회 헬퍼: 외국어 선택 시 해당 언어만, 기본모드는 KO/EN 동시 표시
String _t(Map<String, String> map) {
  return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? '';
}

// 짧은 라벨(칩, 셀 등)용 - 기본모드는 "한글/EN" 슬래시 결합으로 공간 절약
String _bi(Map<String, String> map) {
  if (DkeLang.isForeignSelected) return _t(map);
  return "${map['KO']}/${map['EN']}";
}

// 문단형 텍스트(안내문, 팝업 본문)용 - 기본모드는 "한글\nEnglish" 줄바꿈 결합
String _biLong(Map<String, String> map) {
  if (DkeLang.isForeignSelected) return _t(map);
  return "${map['KO']}\n${map['EN']}";
}

// ---------------------------------------------------------------------------
// 🆕 [다국어] 과목명 약어 사전 (원장님 확정 스펙 과목 전체) - 데이터 키(한글)는 그대로,
// 화면 표시만 이 사전을 거쳐 각 언어의 축약형으로 보여줍니다.
// ---------------------------------------------------------------------------
const Map<String, Map<String, String>> kSubjectLabelMap = {
  "국어": {'KO': '국어', 'EN': 'Kor', 'JA': '国語', 'ZH': '语文', 'FR': 'Coréen', 'DE': 'Koreanisch', 'RU': 'Кор.яз', 'AR': 'كورية', 'HI': 'कोरियाई', 'VI': 'T.Hàn', 'ES': 'Coreano', 'TH': 'ภาษาเกาหลี'},
  "수학": {'KO': '수학', 'EN': 'Math', 'JA': '数学', 'ZH': '数学', 'FR': 'Maths', 'DE': 'Mathe', 'RU': 'Матем', 'AR': 'رياضيات', 'HI': 'गणित', 'VI': 'Toán', 'ES': 'Mate', 'TH': 'คณิต'},
  "영어": {'KO': '영어', 'EN': 'Eng', 'JA': '英語', 'ZH': '英语', 'FR': 'Anglais', 'DE': 'Englisch', 'RU': 'Англ', 'AR': 'إنجليزي', 'HI': 'अंग्रेज़ी', 'VI': 'T.Anh', 'ES': 'Inglés', 'TH': 'อังกฤษ'},
  "과학": {'KO': '과학', 'EN': 'Sci', 'JA': '理科', 'ZH': '科学', 'FR': 'Sciences', 'DE': 'Wissen', 'RU': 'Наука', 'AR': 'علوم', 'HI': 'विज्ञान', 'VI': 'KHọc', 'ES': 'Ciencia', 'TH': 'วิทย์'},
  "사회": {'KO': '사회', 'EN': 'Soc', 'JA': '社会', 'ZH': '社会', 'FR': 'Sociales', 'DE': 'Sozial', 'RU': 'Общ', 'AR': 'اجتماعيات', 'HI': 'सामाजिक', 'VI': 'XHội', 'ES': 'Sociales', 'TH': 'สังคม'},
  "세계사": {'KO': '세계사', 'EN': 'World Hist', 'JA': '世界史', 'ZH': '世界史', 'FR': 'Hist.Monde', 'DE': 'Weltgesch', 'RU': 'Всемир.ист', 'AR': 'تاريخ عالمي', 'HI': 'विश्व इतिहास', 'VI': 'LSử TG', 'ES': 'Hist.Mundial', 'TH': 'ประวัติโลก'},
  "역사": {'KO': '역사', 'EN': 'Hist', 'JA': '歴史', 'ZH': '历史', 'FR': 'Histoire', 'DE': 'Gesch', 'RU': 'История', 'AR': 'تاريخ', 'HI': 'इतिहास', 'VI': 'LSử', 'ES': 'Historia', 'TH': 'ประวัติ'},
  "도덕": {'KO': '도덕', 'EN': 'Eth', 'JA': '道徳', 'ZH': '道德', 'FR': 'Éthique', 'DE': 'Ethik', 'RU': 'Этика', 'AR': 'أخلاق', 'HI': 'नैतिक', 'VI': 'Đđức', 'ES': 'Ética', 'TH': 'ศีลธรรม'},
  "기술·가정": {'KO': '기술가정', 'EN': 'Tech&HE', 'JA': '技術家庭', 'ZH': '技术家政', 'FR': 'Tech.Fam', 'DE': 'Tech&Haus', 'RU': 'Техн.дом', 'AR': 'تقنية ومنزل', 'HI': 'तकनीक-गृह', 'VI': 'CN-GĐ', 'ES': 'Tec.Hogar', 'TH': 'เทคโนโลยี'},
  "한문": {'KO': '한문', 'EN': 'Hanja', 'JA': '漢文', 'ZH': '汉文', 'FR': 'Hanja', 'DE': 'Hanja', 'RU': 'Ханча', 'AR': 'هانجا', 'HI': 'हंजा', 'VI': 'Hán văn', 'ES': 'Hanja', 'TH': 'ฮันจา'},
  "정보": {'KO': '정보', 'EN': 'Info', 'JA': '情報', 'ZH': '信息', 'FR': 'Info', 'DE': 'Info', 'RU': 'Информ', 'AR': 'معلوماتية', 'HI': 'सूचना', 'VI': 'CNTT', 'ES': 'Informát', 'TH': 'ไอที'},
  "음악": {'KO': '음악', 'EN': 'Music', 'JA': '音楽', 'ZH': '音乐', 'FR': 'Musique', 'DE': 'Musik', 'RU': 'Музыка', 'AR': 'موسيقى', 'HI': 'संगीत', 'VI': 'Â.Nhạc', 'ES': 'Música', 'TH': 'ดนตรี'},
  "미술": {'KO': '미술', 'EN': 'Art', 'JA': '美術', 'ZH': '美术', 'FR': 'Art', 'DE': 'Kunst', 'RU': 'Искусство', 'AR': 'فنون', 'HI': 'कला', 'VI': 'M.Thuật', 'ES': 'Arte', 'TH': 'ศิลปะ'},
  "체육": {'KO': '체육', 'EN': 'PE', 'JA': '体育', 'ZH': '体育', 'FR': 'EPS', 'DE': 'Sport', 'RU': 'Физк', 'AR': 'رياضة', 'HI': 'शारीरिक शिक्षा', 'VI': 'TDục', 'ES': 'Ed.Física', 'TH': 'พละ'},
  "통합사회": {'KO': '통합사회', 'EN': 'Int.Social', 'JA': '統合社会', 'ZH': '综合社会', 'FR': 'Soc.Intég', 'DE': 'Int.Sozial', 'RU': 'Интегр.общ', 'AR': 'اجتماعيات متكاملة', 'HI': 'एकीकृत सामाजिक', 'VI': 'XH Tích hợp', 'ES': 'Soc.Integ', 'TH': 'สังคมบูรณาการ'},
  "통합과학": {'KO': '통합과학', 'EN': 'Int.Sci', 'JA': '統合科学', 'ZH': '综合科学', 'FR': 'Sci.Intég', 'DE': 'Int.Wissen', 'RU': 'Интегр.наука', 'AR': 'علوم متكاملة', 'HI': 'एकीकृत विज्ञान', 'VI': 'KH Tích hợp', 'ES': 'Cien.Integ', 'TH': 'วิทย์บูรณาการ'},
  "한국사": {'KO': '한국사', 'EN': 'Kor.Hist', 'JA': '韓国史', 'ZH': '韩国史', 'FR': 'Hist.Corée', 'DE': 'Kor.Gesch', 'RU': 'Ист.Кореи', 'AR': 'تاريخ كوري', 'HI': 'कोरियाई इतिहास', 'VI': 'LSử Hàn', 'ES': 'Hist.Corea', 'TH': 'ประวัติเกาหลี'},
  "제2외국어": {'KO': '제2외국어', 'EN': '2nd FL', 'JA': '第二外語', 'ZH': '第二外语', 'FR': '2e Langue', 'DE': '2.Fremdspr', 'RU': '2-й ин.яз', 'AR': 'لغة أجنبية2', 'HI': 'द्वि.विदेशी', 'VI': 'NN2', 'ES': '2ºIdioma', 'TH': 'ภาษาที่2'},
};

String subjectLabel(String koSubject) {
  final map = kSubjectLabelMap[koSubject];
  if (map == null) return koSubject; // 사용자가 직접 추가한 과목명은 번역 사전이 없으므로 원문 그대로 표시
  return _bi(map);
}

// 🆕 [다국어] 시험 종류 (member_achievement_screen.dart와 동일한 번역 세트 재사용)
const Map<String, Map<String, String>> kExamTypeLabelMap = {
  "중간고사": {'KO': '중간고사', 'EN': 'Midterm', 'JA': '中間試験', 'ZH': '期中考试', 'FR': 'Mi-parcours', 'DE': 'Zwischenprüfung', 'RU': 'Промежуточный', 'AR': 'اختبار نصفي', 'HI': 'मिडटर्म', 'VI': 'Giữa kỳ', 'ES': 'Parcial', 'TH': 'กลางภาค'},
  "기말고사": {'KO': '기말고사', 'EN': 'Final', 'JA': '期末試験', 'ZH': '期末考试', 'FR': 'Final', 'DE': 'Abschlussprüfung', 'RU': 'Итоговый', 'AR': 'اختبار نهائي', 'HI': 'फाइनल', 'VI': 'Cuối kỳ', 'ES': 'Final', 'TH': 'ปลายภาค'},
  "모의고사": {'KO': '모의고사', 'EN': 'Mock Exam', 'JA': '模試', 'ZH': '模拟考试', 'FR': 'Examen blanc', 'DE': 'Testexamen', 'RU': 'Пробный экзамен', 'AR': 'اختبار تجريبي', 'HI': 'मॉक परीक्षा', 'VI': 'Thi thử', 'ES': 'Examen simulado', 'TH': 'ข้อสอบจำลอง'},
};
String examTypeLabel(String koType) => _bi(kExamTypeLabelMap[koType] ?? {'KO': koType, 'EN': koType});

const Map<String, String> kSchoolLevelMiddleMap = {'KO': '중등부', 'EN': 'Middle School', 'JA': '中学部', 'ZH': '初中部', 'FR': 'Collège', 'DE': 'Mittelschule', 'RU': 'Средняя школа', 'AR': 'المرحلة المتوسطة', 'HI': 'मिडिल स्कूल', 'VI': 'THCS', 'ES': 'Secundaria', 'TH': 'มัธยมต้น'};
const Map<String, String> kSchoolLevelHighMap = {'KO': '고등부', 'EN': 'High School', 'JA': '高校部', 'ZH': '高中部', 'FR': 'Lycée', 'DE': 'Oberschule', 'RU': 'Старшая школа', 'AR': 'المرحلة الثانوية', 'HI': 'हाई स्कूल', 'VI': 'THPT', 'ES': 'Bachillerato', 'TH': 'มัธยมปลาย'};
String schoolLevelLabel(String koLevel) => _bi(koLevel == "중등부" ? kSchoolLevelMiddleMap : kSchoolLevelHighMap);

const Map<String, String> kGradeWordMap = {'KO': '학년', 'EN': 'Grade', 'JA': '学年', 'ZH': '年级', 'FR': 'Niveau', 'DE': 'Klasse', 'RU': 'Класс', 'AR': 'الصف', 'HI': 'कक्षा', 'VI': 'Lớp', 'ES': 'Grado', 'TH': 'ระดับชั้น'};
const Map<String, String> kSemesterWordMap = {'KO': '학기', 'EN': 'Semester', 'JA': '学期', 'ZH': '学期', 'FR': 'Semestre', 'DE': 'Semester', 'RU': 'Семестр', 'AR': 'الفصل', 'HI': 'सेमेस्टर', 'VI': 'Học kỳ', 'ES': 'Semestre', 'TH': 'ภาคเรียน'};
const Map<String, String> kGradeSuffixMap = {'KO': '등급', 'EN': 'Grade', 'JA': '等級', 'ZH': '等级', 'FR': 'Niveau', 'DE': 'Note', 'RU': 'Уровень', 'AR': 'درجة', 'HI': 'ग्रेड', 'VI': 'Hạng', 'ES': 'Nivel', 'TH': 'ระดับ'};

// 한국어/일본어/중국어는 "숫자+단어" 어순, 그 외 대부분은 "단어+숫자" 어순
bool get _isNumberFirstLang => ['KO', 'JA', 'ZH'].contains(DkeLang.current);

String gradeChipLabel(int g) {
  final word = _t(kGradeWordMap);
  if (DkeLang.isForeignSelected) return _isNumberFirstLang ? "$g$word" : "$word $g";
  return "$g${kGradeWordMap['KO']}/${kGradeWordMap['EN']} $g";
}

String semesterChipLabel(int s) {
  final word = _t(kSemesterWordMap);
  if (DkeLang.isForeignSelected) return _isNumberFirstLang ? "$s$word" : "$word $s";
  return "$s${kSemesterWordMap['KO']}/${kSemesterWordMap['EN']} $s";
}

String gradeLetterLabel(String grade) {
  final word = _t(kGradeSuffixMap);
  if (DkeLang.isForeignSelected) return _isNumberFirstLang ? "$grade$word" : "$word $grade";
  return "$grade${kGradeSuffixMap['KO']}/${kGradeSuffixMap['EN']}$grade";
}

// ---------------------------------------------------------------------------
// 🆕 [다국어] 화면 문구 전체
// ---------------------------------------------------------------------------
const Map<String, String> kTitleEngMap = {'KO': 'GRADE MANAGEMENT', 'EN': 'GRADE MANAGEMENT', 'JA': 'GRADE MANAGEMENT', 'ZH': 'GRADE MANAGEMENT', 'FR': 'GRADE MANAGEMENT', 'DE': 'GRADE MANAGEMENT', 'RU': 'GRADE MANAGEMENT', 'AR': 'GRADE MANAGEMENT', 'HI': 'GRADE MANAGEMENT', 'VI': 'GRADE MANAGEMENT', 'ES': 'GRADE MANAGEMENT', 'TH': 'GRADE MANAGEMENT'};
const Map<String, String> kScreenSubtitleMap = {
  'KO': '성적 관리 조회', 'EN': 'Grade Report Viewer',
  'JA': '成績管理 照会', 'ZH': '成绩管理查询', 'FR': 'Consultation des notes', 'DE': 'Notenübersicht',
  'RU': 'Просмотр успеваемости', 'AR': 'عرض إدارة الدرجات', 'HI': 'ग्रेड रिपोर्ट व्यूअर', 'VI': 'Xem quản lý điểm',
  'ES': 'Consulta de calificaciones', 'TH': 'ดูการจัดการเกรด',
};
const Map<String, String> kScreenDescMap = {
  'KO': '학생이 직접 작성한 성적 기록을 조회 전용으로 확인합니다.', 'EN': "View-only access to the student's own grade records.",
  'JA': '生徒本人が入力した成績記録を照会専用で確認します。', 'ZH': '仅供查看学生本人录入的成绩记录。',
  'FR': "Consultation en lecture seule des notes saisies par l'élève.", 'DE': 'Nur-Lese-Ansicht der vom Schüler eingegebenen Noten.',
  'RU': 'Просмотр только для чтения записей об успеваемости, введённых учеником.', 'AR': 'عرض للقراءة فقط لسجلات الدرجات التي أدخلها الطالب.',
  'HI': 'छात्र द्वारा दर्ज किए गए ग्रेड रिकॉर्ड का केवल-दृश्य एक्सेस।', 'VI': 'Chỉ xem hồ sơ điểm do học sinh tự nhập.',
  'ES': 'Acceso de solo lectura a los registros de calificaciones del estudiante.', 'TH': 'ดูข้อมูลบันทึกเกรดที่นักเรียนกรอกเองแบบดูอย่างเดียว',
};
const Map<String, String> kNoRecordsAtAllMap = {
  'KO': '아직 자녀가 입력한 성적 기록이 없습니다. 자녀가 [성적 관리] 화면에서 성적을 입력하면 여기에 표시됩니다.',
  'EN': "Your child hasn't entered any grades yet. Once they do in the [Grade Management] screen, records will appear here.",
  'JA': 'まだお子様が入力した成績記録がありません。お子様が[成績管理]画面で成績を入力すると、ここに表示されます。',
  'ZH': '孩子尚未录入任何成绩记录。孩子在[成绩管理]页面录入成绩后，将显示在此处。',
  'FR': "Votre enfant n'a pas encore saisi de notes. Une fois saisies dans l'écran [Gestion des notes], elles apparaîtront ici.",
  'DE': 'Ihr Kind hat noch keine Noten eingetragen. Sobald dies im Bildschirm [Notenverwaltung] geschieht, erscheinen sie hier.',
  'RU': 'Ваш ребёнок ещё не ввёл оценки. После ввода на экране [Управление оценками] они появятся здесь.',
  'AR': 'لم يقم طفلك بإدخال أي درجات بعد. بمجرد إدخالها في شاشة [إدارة الدرجات]، ستظهر هنا.',
  'HI': 'आपके बच्चे ने अभी तक कोई ग्रेड दर्ज नहीं किया है। [ग्रेड प्रबंधन] स्क्रीन में दर्ज करते ही यहाँ दिखाई देगा।',
  'VI': 'Con bạn chưa nhập điểm nào. Khi nhập ở màn hình [Quản lý điểm], hồ sơ sẽ hiển thị tại đây.',
  'ES': 'Su hijo/a aún no ha ingresado calificaciones. Una vez que lo haga en la pantalla [Gestión de calificaciones], aparecerán aquí.',
  'TH': 'บุตรหลานยังไม่ได้กรอกคะแนน เมื่อกรอกในหน้าจอ [จัดการเกรด] แล้ว จะแสดงที่นี่',
};
String noRecordsAtScopeText(String schoolLevel, int grade, int semester) {
  final scope = "${schoolLevelLabel(schoolLevel)} · ${gradeChipLabel(grade)} · ${semesterChipLabel(semester)}";
  final Map<String, String> map = {
    'KO': '선택한 $scope에는 기록된 성적이 없습니다.',
    'EN': 'No grades recorded for $scope.',
    'JA': '選択した$scopeには記録された成績がありません。',
    'ZH': '所选$scope暂无成绩记录。',
    'FR': 'Aucune note enregistrée pour $scope.',
    'DE': 'Keine Noten für $scope erfasst.',
    'RU': 'Нет оценок для $scope.',
    'AR': 'لا توجد درجات مسجلة لـ $scope.',
    'HI': '$scope के लिए कोई ग्रेड दर्ज नहीं है।',
    'VI': 'Không có điểm nào được ghi cho $scope.',
    'ES': 'No hay calificaciones registradas para $scope.',
    'TH': 'ไม่มีคะแนนที่บันทึกไว้สำหรับ $scope',
  };
  return _t(map);
}
const Map<String, String> kReportCardSuffixMap = {
  'KO': '성적표', 'EN': 'Report Card', 'JA': '成績表', 'ZH': '成绩单', 'FR': 'Bulletin', 'DE': 'Zeugnis',
  'RU': 'Табель', 'AR': 'بطاقة الدرجات', 'HI': 'रिपोर्ट कार्ड', 'VI': 'Học bạ', 'ES': 'Boletín', 'TH': 'สมุดพก',
};
String reportCardTitle(String schoolLevel, int grade, int semester) {
  final scope = "${schoolLevelLabel(schoolLevel)}·${gradeChipLabel(grade)}·${semesterChipLabel(semester)}";
  return "$scope ${_t(kReportCardSuffixMap)}";
}

const Map<String, String> kSubjectHeaderMap = {'KO': '과목', 'EN': 'Subject', 'JA': '科目', 'ZH': '科目', 'FR': 'Matière', 'DE': 'Fach', 'RU': 'Предмет', 'AR': 'المادة', 'HI': 'विषय', 'VI': 'Môn học', 'ES': 'Materia', 'TH': 'วิชา'};
const Map<String, String> kAvgGradeHeaderMap = {'KO': '평균/등급', 'EN': 'Avg/Grade', 'JA': '平均/等級', 'ZH': '平均/等级', 'FR': 'Moy./Niveau', 'DE': 'Ø/Note', 'RU': 'Средн/Уровень', 'AR': 'المعدل/الدرجة', 'HI': 'औसत/ग्रेड', 'VI': 'TB/Hạng', 'ES': 'Prom/Nivel', 'TH': 'เฉลี่ย/ระดับ'};
const Map<String, String> kNoRecordCellMap = {'KO': '기록없음', 'EN': 'No data', 'JA': '記録なし', 'ZH': '无记录', 'FR': 'Aucune donnée', 'DE': 'Keine Daten', 'RU': 'Нет данных', 'AR': 'لا بيانات', 'HI': 'कोई डेटा नहीं', 'VI': 'Không có', 'ES': 'Sin datos', 'TH': 'ไม่มีข้อมูล'};
const Map<String, String> kNotComputedMap = {'KO': '미산출', 'EN': 'N/A', 'JA': '未算出', 'ZH': '未计算', 'FR': 'N/D', 'DE': 'N/V', 'RU': 'Н/Д', 'AR': 'غير محسوب', 'HI': 'गणना नहीं', 'VI': 'Chưa tính', 'ES': 'N/D', 'TH': 'ยังไม่คำนวณ'};
const Map<String, String> kGradeNotComputedMap = {'KO': '등급 미산출', 'EN': 'Grade N/A', 'JA': '等級未算出', 'ZH': '等级未计算', 'FR': 'Niveau N/D', 'DE': 'Note N/V', 'RU': 'Уровень Н/Д', 'AR': 'الدرجة غير محسوبة', 'HI': 'ग्रेड नहीं', 'VI': 'Chưa xếp hạng', 'ES': 'Nivel N/D', 'TH': 'ยังไม่มีระดับ'};

const Map<String, String> kChartSectionTitleMap = {'KO': '시험 종류별 그래프', 'EN': 'Score Graph by Exam Type', 'JA': '試験種類別グラフ', 'ZH': '按考试类型的图表', 'FR': 'Graphique par type d\'examen', 'DE': 'Diagramm nach Prüfungsart', 'RU': 'График по типу экзамена', 'AR': 'الرسم البياني حسب نوع الاختبار', 'HI': 'परीक्षा प्रकार अनुसार ग्राफ', 'VI': 'Biểu đồ theo loại kỳ thi', 'ES': 'Gráfico por tipo de examen', 'TH': 'กราฟตามประเภทข้อสอบ'};
String chartEmptyText(String koExamType) {
  final et = examTypeLabel(koExamType);
  final Map<String, String> map = {
    'KO': '$et 점수가 입력되면 그래프가 표시됩니다.',
    'EN': 'The graph will appear once $et scores are entered.',
    'JA': '$etの点数が入力されるとグラフが表示されます。',
    'ZH': '录入$et成绩后将显示图表。',
    'FR': "Le graphique s'affichera une fois les notes de $et saisies.",
    'DE': 'Das Diagramm erscheint, sobald $et-Noten eingegeben wurden.',
    'RU': 'График появится после ввода баллов за $et.',
    'AR': 'سيظهر الرسم البياني بعد إدخال درجات $et.',
    'HI': '$et अंक दर्ज होते ही ग्राफ दिखाई देगा।',
    'VI': 'Biểu đồ sẽ hiển thị sau khi nhập điểm $et.',
    'ES': 'El gráfico aparecerá una vez ingresadas las notas de $et.',
    'TH': 'กราฟจะแสดงเมื่อกรอกคะแนน $et แล้ว',
  };
  return _t(map);
}

const Map<String, String> kSummaryTitleMap = {'KO': '종합 총평', 'EN': 'Overall Summary', 'JA': '総合総評', 'ZH': '综合总评', 'FR': 'Bilan général', 'DE': 'Gesamtbewertung', 'RU': 'Общий отзыв', 'AR': 'التقييم الشامل', 'HI': 'समग्र सारांश', 'VI': 'Nhận xét tổng hợp', 'ES': 'Resumen general', 'TH': 'บทสรุปโดยรวม'};
const Map<String, String> kSummaryPlaceholderMap = {
  'KO': '지필·수행 점수가 입력되면 지필+수행 종합 결과를 바탕으로 총평이 표시됩니다.',
  'EN': 'Once written and performance scores are entered, a summary based on the combined result will appear here.',
  'JA': '筆記・遂行評価の点数が入力されると、その合算結果に基づいた総評が表示されます。',
  'ZH': '录入笔试与表现评价成绩后，将基于综合结果显示总评。',
  'FR': "Une fois les notes écrites et de performance saisies, un bilan basé sur le résultat combiné s'affichera.",
  'DE': 'Sobald schriftliche und Leistungsnoten eingegeben wurden, erscheint hier eine Gesamtbewertung.',
  'RU': 'После ввода баллов за письменную и практическую части здесь появится общий отзыв.',
  'AR': 'بمجرد إدخال درجات الاختبار التحريري والأداء، سيظهر تقييم شامل هنا.',
  'HI': 'लिखित एवं प्रदर्शन अंक दर्ज होते ही, संयुक्त परिणाम पर आधारित सारांश यहाँ दिखाई देगा।',
  'VI': 'Sau khi nhập điểm viết và điểm thực hành, nhận xét tổng hợp sẽ hiển thị tại đây.',
  'ES': 'Una vez ingresadas las notas escritas y de desempeño, aparecerá aquí un resumen del resultado combinado.',
  'TH': 'เมื่อกรอกคะแนนข้อเขียนและคะแนนภาคปฏิบัติแล้ว บทสรุปจากผลรวมจะแสดงที่นี่',
};

const Map<String, String> kPopupTitleMap = {'KO': '성적관리 안내', 'EN': 'Grade Management Notice', 'JA': '成績管理のご案内', 'ZH': '成绩管理说明', 'FR': 'Avis de gestion des notes', 'DE': 'Hinweis zur Notenverwaltung', 'RU': 'Уведомление об управлении оценками', 'AR': 'إشعار إدارة الدرجات', 'HI': 'ग्रेड प्रबंधन सूचना', 'VI': 'Thông báo quản lý điểm', 'ES': 'Aviso de gestión de calificaciones', 'TH': 'ประกาศการจัดการเกรด'};
const Map<String, String> kConfirmBtnMap = {'KO': '확인', 'EN': 'OK', 'JA': '確認', 'ZH': '确认', 'FR': 'OK', 'DE': 'OK', 'RU': 'ОК', 'AR': 'موافق', 'HI': 'ठीक है', 'VI': 'Xác nhận', 'ES': 'Aceptar', 'TH': 'ตกลง'};

const Map<String, String> kParentIntroPopupMap = {
  'KO': "이 성적표는 자녀가 직접 입력한 자율 기록을 바탕으로 자동 계산된 참고용 자료입니다.\n학교에서 공식적으로 발표한 성적표와는 차이가 있을 수 있는 점 양해 부탁드립니다.\n자녀의 학업 흐름을 살펴보는 참고 자료로 편하게 활용해 주세요.",
  'EN': "This report is a reference automatically calculated from records your child entered independently.\nPlease note it may differ from the school's official report card.\nFeel free to use it as a casual reference for your child's learning trends.",
  'JA': "この成績表は、お子様ご自身が入力した自律的な記録をもとに自動計算された参考資料です。\n学校が公式に発表する成績表とは差がある場合がありますので、ご了承ください。\nお子様の学習の流れを把握する参考資料として、お気軽にご活用ください。",
  'ZH': "此成绩单是根据孩子自行录入的记录自动计算得出的参考资料。\n请注意，可能与学校官方发布的成绩单存在差异。\n请将其作为了解孩子学习状况的参考资料轻松使用。",
  'FR': "Ce bulletin est une référence calculée automatiquement à partir des données saisies par votre enfant.\nIl peut différer du bulletin officiel de l'école.\nUtilisez-le simplement comme repère pour suivre les progrès de votre enfant.",
  'DE': "Dieses Zeugnis ist ein automatisch berechneter Referenzwert basierend auf den von Ihrem Kind selbst eingegebenen Daten.\nEs kann vom offiziellen Zeugnis der Schule abweichen.\nNutzen Sie es einfach als lockere Orientierung für den Lernfortschritt Ihres Kindes.",
  'RU': "Этот табель — справочные данные, автоматически рассчитанные на основе записей, которые ваш ребёнок ввёл самостоятельно.\nОн может отличаться от официального табеля школы.\nИспользуйте его как удобный ориентир для отслеживания успеваемости ребёнка.",
  'AR': "بطاقة الدرجات هذه مرجع محسوب تلقائيًا بناءً على السجلات التي أدخلها طفلك بنفسه.\nيرجى ملاحظة أنها قد تختلف عن بطاقة الدرجات الرسمية للمدرسة.\nاستخدمها بحرية كمرجع لمتابعة تقدم طفلك الدراسي.",
  'HI': "यह रिपोर्ट कार्ड आपके बच्चे द्वारा स्वयं दर्ज किए गए रिकॉर्ड के आधार पर स्वचालित रूप से गणना किया गया संदर्भ है।\nकृपया ध्यान दें कि यह स्कूल के आधिकारिक रिपोर्ट कार्ड से भिन्न हो सकता है।\nइसे अपने बच्चे की सीखने की प्रवृत्ति देखने के लिए सहज संदर्भ के रूप में उपयोग करें।",
  'VI': "Học bạ này là tài liệu tham khảo được tự động tính toán từ hồ sơ do con bạn tự nhập.\nCó thể sẽ khác với học bạ chính thức của trường.\nHãy thoải mái dùng để tham khảo xu hướng học tập của con.",
  'ES': "Este boletín es una referencia calculada automáticamente a partir de los registros que su hijo/a ingresó por su cuenta.\nTenga en cuenta que puede diferir del boletín oficial de la escuela.\nÚselo libremente como referencia para ver la tendencia de aprendizaje de su hijo/a.",
  'TH': "สมุดพกนี้เป็นข้อมูลอ้างอิงที่คำนวณอัตโนมัติจากบันทึกที่บุตรหลานกรอกเอง\nอาจแตกต่างจากสมุดพกที่โรงเรียนประกาศอย่างเป็นทางการ\nโปรดใช้เป็นข้อมูลอ้างอิงแบบสบาย ๆ เพื่อดูแนวโน้มการเรียนของบุตรหลาน",
};

const Map<String, String> kRankDisclaimerMap = {
  'KO': "※ 학교에서 공식적으로 발표한 석차가 아닌, 본인이 예상으로 입력한 참고용 수치입니다.",
  'EN': "※ Not an official school-published rank — this is a self-estimated figure for reference only.",
  'JA': "※ 学校が公式に発表した順位ではなく、本人が予想して入力した参考用の数値です。",
  'ZH': "※ 并非学校官方公布的排名，仅为本人预估录入的参考数值。",
  'FR': "※ Il ne s'agit pas d'un classement officiel de l'école, mais d'une estimation personnelle à titre indicatif.",
  'DE': "※ Kein offiziell von der Schule veröffentlichter Rang, sondern ein selbst geschätzter Referenzwert.",
  'RU': "※ Это не официальный рейтинг школы, а ориентировочное значение, введённое самим учеником.",
  'AR': "※ ليس ترتيبًا رسميًا معلنًا من المدرسة، بل رقم تقديري ذاتي للرجوع فقط.",
  'HI': "※ यह स्कूल द्वारा आधिकारिक रूप से घोषित रैंक नहीं है, बल्कि स्वयं अनुमानित संदर्भ मान है।",
  'VI': "※ Đây không phải thứ hạng chính thức do trường công bố, mà là số liệu tự ước tính để tham khảo.",
  'ES': "※ No es un ranking oficial publicado por la escuela, sino una cifra estimada por el propio estudiante como referencia.",
  'TH': "※ ไม่ใช่อันดับที่โรงเรียนประกาศอย่างเป็นทางการ แต่เป็นตัวเลขที่กรอกเองเพื่อการอ้างอิงเท่านั้น",
};

class ParentGradeManagementWidget extends StatefulWidget {
  final String childName;
  final Color premiumCardBg;
  final Color brandGolden;
  final Color luxuryDarkBg;
  final Widget Function(String engTitle, String korTitle, {required double fontSize}) buildCustomSectionTitle;

  const ParentGradeManagementWidget({
    Key? key,
    required this.childName,
    required this.premiumCardBg,
    required this.brandGolden,
    required this.luxuryDarkBg,
    required this.buildCustomSectionTitle,
  }) : super(key: key);

  @override
  State<ParentGradeManagementWidget> createState() => _ParentGradeManagementWidgetState();
}

class _ParentGradeManagementWidgetState extends State<ParentGradeManagementWidget> {
  bool _isLoading = true;
  List<GradeRecord> _allRecords = [];
  List<SubjectConfig> _allConfigs = [];

  String _schoolLevel = "중등부";
  int _grade = 1;
  int _semester = 1;

  String? _summaryText;
  bool _isSummaryLoading = false;
  bool _introShown = false;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _showIntroPopupOnce() {
    if (_introShown || !mounted) return;
    _introShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: widget.premiumCardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: widget.brandGolden.withOpacity(0.55), width: 1.6),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_t(kPopupTitleMap), style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Text(_biLong(kParentIntroPopupMap), style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13, height: 1.6)),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: widget.brandGolden),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(_t(kConfirmBtnMap), style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Future<void> _loadRecords() async {
    final all = await ParentDataService.loadGradeManagementRecords();
    final configs = await ParentDataService.loadGradeSubjectConfigs();
    if (!mounted) return;

    // 🆕 가장 최근에 입력된 기록의 학교구분/학년/학기를 초기 선택값으로 자동 설정
    if (all.isNotEmpty) {
      final latest = all.reduce((a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b);
      _schoolLevel = latest.schoolLevel;
      _grade = latest.grade;
      _semester = latest.semester;
    }

    setState(() {
      _allRecords = all;
      _allConfigs = configs;
      _isLoading = false;
    });
    _showIntroPopupOnce();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final overall = GradeManagementService.computeOverallSummary(_filtered, _schoolLevel, _allConfigs);
    final double? avg = overall["average"] as double?;
    if (avg == null) {
      setState(() => _summaryText = null);
      return;
    }
    setState(() => _isSummaryLoading = true);
    // 🆕 [요청] 학생 화면과 동일한 personKey 규칙을 사용해 "동일한 문구"가 그대로 조회됩니다.
    final double? achievementAvg = await GradeManagementService.readAchievementAverageScore();
    final String personKey = 'student_${widget.childName}_$_schoolLevel$_grade$_semester';
    final GradeSummaryResult result = await GradeDiagnosisService.getOverallSummary(
      personKey: personKey, combinedAverage: avg, achievementAverage: achievementAvg,
    );
    if (!mounted) return;
    setState(() {
      // 🆕 [요청] 종합 총평에 영문 병기 - 기본모드(KO/EN)는 한글+영문, 10개국어 선택 시엔
      // 전용 번역 문구뱅크가 아직 없어 영문으로 대체 표시합니다.
      _summaryText = DkeLang.isForeignSelected ? result.en : "${result.ko}\n\n${result.en}";
      _isSummaryLoading = false;
    });
  }

  List<GradeRecord> get _filtered => GradeManagementService.filterBy(
    _allRecords, schoolLevel: _schoolLevel, grade: _grade, semester: _semester,
  );

  List<String> get _visibleSubjects {
    final Set<String> set = {};
    for (final r in _filtered) {
      set.add(r.subject);
    }
    return set.toList();
  }

  GradeRecord? _cellRecord(String subject, String examType) {
    return _filtered
        .where((r) => r.subject == subject && r.examType == examType)
        .fold<GradeRecord?>(null, (prev, r) => (prev == null || r.updatedAt.isAfter(prev.updatedAt)) ? r : prev);
  }

  Widget _buildSelectorChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? widget.brandGolden : Colors.black38,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.brandGolden.withOpacity(isSelected ? 0.9 : 0.3), width: 1.3),
          ),
          child: Text(label, style: GoogleFonts.notoSansKr(color: isSelected ? Colors.black : Colors.white70, fontWeight: FontWeight.bold, fontSize: 12.5)),
        ),
      ),
    );
  }

  Widget _buildReadOnlyCell(String subject, String examType) {
    final rec = _cellRecord(subject, examType);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: rec != null ? Colors.black26 : Colors.black12,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.brandGolden.withOpacity(rec != null ? 0.5 : 0.18), width: 1.2),
      ),
      child: rec == null
          ? Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(_t(kNoRecordCellMap), style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10.5))))
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              rec.computedAverage != null ? "${rec.computedAverage!.toStringAsFixed(1)}" : _t(kNotComputedMap),
              style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              rec.computedGrade != null ? gradeLetterLabel(rec.computedGrade!) : _t(kGradeNotComputedMap),
              style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 [요청] "종합" 한 줄이 아니라 중간고사/기말고사/모의고사 각 열 맨 아래에
  // 그 시험 종류만의 평균·등급을 따로 표시 (학생 화면과 동일)
  Widget _buildExamTypeSummaryCell(String examType) {
    final summary = GradeManagementService.computeExamTypeSummary(_filtered, examType, _schoolLevel, _allConfigs);
    final double? avg = summary["average"] as double?;
    final String? grade = summary["grade"] as String?;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.brandGolden.withOpacity(0.55), width: 1.3),
      ),
      child: avg == null
          ? Center(child: Text("-", style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12)))
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text("${avg.toStringAsFixed(1)}", style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(grade != null ? gradeLetterLabel(grade) : "-", style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // 🆕 [요청] 시험 종류(중간/기말/모의)마다 별도 그래프, X축·Y축 정렬 근본 수정,
  // Y축 라벨 옆 흰 점을 축 선 위 눈금으로 이동, 점수 밝은 흰색+볼드, 과목별 무지개 색상 순환
  // (학생 화면 _buildSingleExamChart와 동일 디자인으로 미러링)
  static const double _kChartBuffer = 18.0;
  static const double _kChartBarMax = 156.0; // 요청: Y축+막대 세로 20% 확대, 130→156 (학생 화면과 동일)
  static const double _kChartBottomPad = 38.0;

  List<Widget> _buildYAxisTickDots() {
    const List<int> values = [100, 80, 60, 40, 20, 0];
    return values.map((v) {
      final double y = _kChartBuffer + (100 - v) / 100.0 * _kChartBarMax;
      return Positioned(
        left: 36.5, top: y - 2,
        child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
      );
    }).toList();
  }

  Widget _buildSingleExamChart(String examType) {
    // 🆕 [요청] 성적표에 나열된 과목 순서 그대로 왼쪽부터 막대가 나오도록 정렬(학생 화면과 동일)
    final List<String> order = _visibleSubjects;
    final recs = _filtered.where((r) => r.examType == examType && r.computedAverage != null).toList()
      ..sort((a, b) {
        final int ia = order.indexOf(a.subject);
        final int ib = order.indexOf(b.subject);
        return (ia == -1 ? order.length : ia).compareTo(ib == -1 ? order.length : ib);
      });
    final List<String> yLabels = ["100", "80", "60", "40", "20", "0"];
    final double totalHeight = _kChartBuffer + _kChartBarMax + _kChartBottomPad;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.premiumCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.brandGolden.withOpacity(0.5), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(examTypeLabel(examType), style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          if (recs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text(chartEmptyText(examType), textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12))),
            )
          else
            SizedBox(
              height: totalHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0, top: 0, bottom: 0, width: 34,
                    child: Column(
                      children: [
                        SizedBox(height: _kChartBuffer),
                        SizedBox(
                          height: _kChartBarMax,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: yLabels.map((l) => Text(l, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 9))).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 38, top: _kChartBuffer, bottom: _kChartBottomPad,
                    child: Container(width: 1.6, color: widget.brandGolden.withOpacity(0.6)),
                  ),
                  ..._buildYAxisTickDots(),
                  Positioned(
                    left: 38, right: 0, top: _kChartBuffer + _kChartBarMax,
                    child: Container(height: 1.8, color: widget.brandGolden.withOpacity(0.6)),
                  ),
                  Positioned(
                    left: 44, right: 0, top: 0, bottom: 0,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(recs.length, (idx) {
                          final r = recs[idx];
                          final double h = (r.computedAverage!.clamp(0, 100) / 100.0) * _kChartBarMax;
                          // 🆕 [요청] 색상은 성적표의 과목 고정 순서를 기준으로 배정 (학생 화면과 동일)
                          final int colorIdx = order.indexOf(r.subject);
                          final Color color = kSubjectRainbowColors[(colorIdx == -1 ? idx : colorIdx) % kSubjectRainbowColors.length];
                          return Container(
                            width: 46,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: _kChartBuffer + _kChartBarMax,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Positioned(
                                        bottom: 0,
                                        child: Container(height: h, width: 20, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))),
                                      ),
                                      Positioned(
                                        bottom: h + 4,
                                        child: Text(r.computedAverage!.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: 46,
                                  child: Text(
                                    subjectLabel(r.subject),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, height: 1.15),
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
            ),
        ],
      ),
    );
  }

  Widget _buildExamTypeChart() {
    return Column(
      children: GradeManagementService.examTypes.map((et) => _buildSingleExamChart(et)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: widget.brandGolden));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t(kTitleEngMap), style: GoogleFonts.notoSerif(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)),
          const SizedBox(height: 2),
          Text("${widget.childName} ${_bi(kScreenSubtitleMap)}", style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 4),
          Text(_biLong(kScreenDescMap), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 18),

          if (_allRecords.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.premiumCardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: widget.brandGolden.withOpacity(0.5), width: 1.4),
              ),
              child: Text(
                _biLong(kNoRecordsAtAllMap),
                style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 12.5, height: 1.5),
              ),
            )
          else ...[
            // 🆕 [요청] 학년(1학년/2학년/3학년 등) 칩이 다국어 표기로 길어져 오른쪽이 잘리는
            // 문제를 막기 위해 세 칩 줄 모두 가로 스크롤로 감쌌습니다.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: GradeManagementService.schoolLevels.map((lv) =>
                  _buildSelectorChip(schoolLevelLabel(lv), _schoolLevel == lv, () { setState(() => _schoolLevel = lv); _loadSummary(); })).toList()),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: GradeManagementService.gradeRange.map((g) {
                return _buildSelectorChip(gradeChipLabel(g), _grade == g, () { setState(() => _grade = g); _loadSummary(); });
              }).toList()),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [1, 2].map((s) =>
                  _buildSelectorChip(semesterChipLabel(s), _semester == s, () { setState(() => _semester = s); _loadSummary(); })).toList()),
            ),
            const SizedBox(height: 6),
            Text(
              reportCardTitle(_schoolLevel, _grade, _semester),
              style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (_visibleSubjects.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.premiumCardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: widget.brandGolden.withOpacity(0.5), width: 1.4),
                ),
                child: Text(
                  noRecordsAtScopeText(_schoolLevel, _grade, _semester),
                  style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 12.5),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.premiumCardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: widget.brandGolden.withOpacity(0.5), width: 1.4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🆕 [오버플로우 근본 수정] 학생 화면과 동일하게 Expanded 비율 레이아웃 적용
                    Row(
                      children: [
                        Expanded(flex: 2, child: Text(_t(kSubjectHeaderMap), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(flex: 3, child: Center(child: Text(examTypeLabel("중간고사"), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)))),
                        Expanded(flex: 3, child: Center(child: Text(examTypeLabel("기말고사"), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)))),
                        Expanded(flex: 3, child: Center(child: Text(examTypeLabel("모의고사"), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)))),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 20),
                    ..._visibleSubjects.map((subject) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(flex: 2, child: Text(subjectLabel(subject), style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                            ...GradeManagementService.examTypes.map((et) => Expanded(flex: 3, child: _buildReadOnlyCell(subject, et))),
                          ],
                        ),
                      );
                    }),
                    const Divider(color: Colors.white10, height: 20),
                    // 🆕 [요청] 중간고사/기말고사/모의고사 각 열 맨 아래에 그 시험 종류만의 평균·등급 표시
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 2, child: Text(_t(kAvgGradeHeaderMap), style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontSize: 12, fontWeight: FontWeight.bold))),
                        ...GradeManagementService.examTypes.map((et) => Expanded(flex: 3, child: _buildExamTypeSummaryCell(et))),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            Text(_t(kChartSectionTitleMap), style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            _buildExamTypeChart(),
            const SizedBox(height: 24),

            Text(_t(kSummaryTitleMap), style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.premiumCardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: widget.brandGolden.withOpacity(0.5), width: 1.4),
              ),
              child: _isSummaryLoading
                  ? Center(child: Padding(padding: const EdgeInsets.all(12), child: CircularProgressIndicator(color: widget.brandGolden)))
                  : Text(
                _summaryText ?? _t(kSummaryPlaceholderMap),
                style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13, height: 1.6),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _t(kRankDisclaimerMap),
              style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10.5, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
