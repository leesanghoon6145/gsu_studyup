import '../global_lang.dart';

/// ============================================================================
/// [GKE StudyUp] 성적관리(Grade Management) 다국어 공용 사전
/// - grade_management_screen.dart(학생용)와 parent_grade_management_widget.dart
///   (학부모용) 양쪽에서 공통으로 쓰는 번역 사전/헬퍼를 이 파일 하나로 모았습니다.
///   (두 화면이 서로를 import하는 순환참조를 피하기 위한 목적)
/// - 기본모드(KO/EN 선택 시): 한글+영문 동시 표시
/// - 10개국어(JA/ZH/FR/DE/RU/AR/HI/VI/ES/TH) 선택 시: 해당 언어만 단독 표시
/// - 실제 데이터 저장 키(과목명·시험종류 등 한글 원문)는 절대 바꾸지 않고,
///   화면 표시할 때만 이 사전을 거칩니다.
/// ============================================================================

String t(Map<String, String> map) => map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? '';

String bi(Map<String, String> map) {
  if (DkeLang.isForeignSelected) return t(map);
  return "${map['KO']}/${map['EN']}";
}

String biLong(Map<String, String> map) {
  if (DkeLang.isForeignSelected) return t(map);
  return "${map['KO']}\n${map['EN']}";
}

bool get isNumberFirstLang => ['KO', 'JA', 'ZH'].contains(DkeLang.current);

// ---------------------------------------------------------------------------
// 과목명 약어 사전
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
  return bi(map);
}

// ---------------------------------------------------------------------------
// 시험 종류
// ---------------------------------------------------------------------------
const Map<String, Map<String, String>> kExamTypeLabelMap = {
  "중간고사": {'KO': '중간고사', 'EN': 'Midterm', 'JA': '中間試験', 'ZH': '期中考试', 'FR': 'Mi-parcours', 'DE': 'Zwischenprüfung', 'RU': 'Промежуточный', 'AR': 'اختبار نصفي', 'HI': 'मिडटर्म', 'VI': 'Giữa kỳ', 'ES': 'Parcial', 'TH': 'กลางภาค'},
  "기말고사": {'KO': '기말고사', 'EN': 'Final', 'JA': '期末試験', 'ZH': '期末考试', 'FR': 'Final', 'DE': 'Abschlussprüfung', 'RU': 'Итоговый', 'AR': 'اختبار نهائي', 'HI': 'फाइनल', 'VI': 'Cuối kỳ', 'ES': 'Final', 'TH': 'ปลายภาค'},
  "모의고사": {'KO': '모의고사', 'EN': 'Mock Exam', 'JA': '模試', 'ZH': '模拟考试', 'FR': 'Examen blanc', 'DE': 'Testexamen', 'RU': 'Пробный экзамен', 'AR': 'اختبار تجريبي', 'HI': 'मॉक परीक्षा', 'VI': 'Thi thử', 'ES': 'Examen simulado', 'TH': 'ข้อสอบจำลอง'},
};
String examTypeLabel(String koType) => bi(kExamTypeLabelMap[koType] ?? {'KO': koType, 'EN': koType});

// ---------------------------------------------------------------------------
// 학교구분 / 학년 / 학기 / 등급
// ---------------------------------------------------------------------------
const Map<String, String> kSchoolLevelMiddleMap = {'KO': '중등부', 'EN': 'Middle School', 'JA': '中学部', 'ZH': '初中部', 'FR': 'Collège', 'DE': 'Mittelschule', 'RU': 'Средняя школа', 'AR': 'المرحلة المتوسطة', 'HI': 'मिडिल स्कूल', 'VI': 'THCS', 'ES': 'Secundaria', 'TH': 'มัธยมต้น'};
const Map<String, String> kSchoolLevelHighMap = {'KO': '고등부', 'EN': 'High School', 'JA': '高校部', 'ZH': '高中部', 'FR': 'Lycée', 'DE': 'Oberschule', 'RU': 'Старшая школа', 'AR': 'المرحلة الثانوية', 'HI': 'हाई स्कूल', 'VI': 'THPT', 'ES': 'Bachillerato', 'TH': 'มัธยมปลาย'};
String schoolLevelLabel(String koLevel) => bi(koLevel == "중등부" ? kSchoolLevelMiddleMap : kSchoolLevelHighMap);

const Map<String, String> kGradeWordMap = {'KO': '학년', 'EN': 'Grade', 'JA': '学年', 'ZH': '年级', 'FR': 'Niveau', 'DE': 'Klasse', 'RU': 'Класс', 'AR': 'الصف', 'HI': 'कक्षा', 'VI': 'Lớp', 'ES': 'Grado', 'TH': 'ระดับชั้น'};
const Map<String, String> kSemesterWordMap = {'KO': '학기', 'EN': 'Semester', 'JA': '学期', 'ZH': '学期', 'FR': 'Semestre', 'DE': 'Semester', 'RU': 'Семестр', 'AR': 'الفصل', 'HI': 'सेमेस्टर', 'VI': 'Học kỳ', 'ES': 'Semestre', 'TH': 'ภาคเรียน'};
const Map<String, String> kGradeSuffixMap = {'KO': '등급', 'EN': 'Grade', 'JA': '等級', 'ZH': '等级', 'FR': 'Niveau', 'DE': 'Note', 'RU': 'Уровень', 'AR': 'درجة', 'HI': 'ग्रेड', 'VI': 'Hạng', 'ES': 'Nivel', 'TH': 'ระดับ'};

String gradeChipLabel(int g) {
  final word = t(kGradeWordMap);
  if (DkeLang.isForeignSelected) return isNumberFirstLang ? "$g$word" : "$word $g";
  return "$g${kGradeWordMap['KO']}/${kGradeWordMap['EN']} $g";
}

String semesterChipLabel(int s) {
  final word = t(kSemesterWordMap);
  if (DkeLang.isForeignSelected) return isNumberFirstLang ? "$s$word" : "$word $s";
  return "$s${kSemesterWordMap['KO']}/${kSemesterWordMap['EN']} $s";
}

String gradeLetterLabel(String grade) {
  final word = t(kGradeSuffixMap);
  if (DkeLang.isForeignSelected) return isNumberFirstLang ? "$grade$word" : "$word $grade";
  return "$grade${kGradeSuffixMap['KO']}/${kGradeSuffixMap['EN']}$grade";
}

// ---------------------------------------------------------------------------
// 공용 화면 문구 (학생/학부모 공통)
// ---------------------------------------------------------------------------
const Map<String, String> kSubjectHeaderMap = {'KO': '과목', 'EN': 'Subject', 'JA': '科目', 'ZH': '科目', 'FR': 'Matière', 'DE': 'Fach', 'RU': 'Предмет', 'AR': 'المادة', 'HI': 'विषय', 'VI': 'Môn học', 'ES': 'Materia', 'TH': 'วิชา'};
const Map<String, String> kAvgGradeHeaderMap = {'KO': '평균/등급', 'EN': 'Avg/Grade', 'JA': '平均/等級', 'ZH': '平均/等级', 'FR': 'Moy./Niveau', 'DE': 'Ø/Note', 'RU': 'Средн/Уровень', 'AR': 'المعدل/الدرجة', 'HI': 'औसत/ग्रेड', 'VI': 'TB/Hạng', 'ES': 'Prom/Nivel', 'TH': 'เฉลี่ย/ระดับ'};
const Map<String, String> kNoRecordCellMap = {'KO': '기록없음', 'EN': 'No data', 'JA': '記録なし', 'ZH': '无记录', 'FR': 'Aucune donnée', 'DE': 'Keine Daten', 'RU': 'Нет данных', 'AR': 'لا بيانات', 'HI': 'कोई डेटा नहीं', 'VI': 'Không có', 'ES': 'Sin datos', 'TH': 'ไม่มีข้อมูล'};
const Map<String, String> kNotComputedMap = {'KO': '미산출', 'EN': 'N/A', 'JA': '未算出', 'ZH': '未计算', 'FR': 'N/D', 'DE': 'N/V', 'RU': 'Н/Д', 'AR': 'غير محسوب', 'HI': 'गणना नहीं', 'VI': 'Chưa tính', 'ES': 'N/D', 'TH': 'ยังไม่คำนวณ'};
const Map<String, String> kGradeNotComputedMap = {'KO': '등급 미산출', 'EN': 'Grade N/A', 'JA': '等級未算出', 'ZH': '等级未计算', 'FR': 'Niveau N/D', 'DE': 'Note N/V', 'RU': 'Уровень Н/Д', 'AR': 'الدرجة غير محسوبة', 'HI': 'ग्रेड नहीं', 'VI': 'Chưa xếp hạng', 'ES': 'Nivel N/D', 'TH': 'ยังไม่มีระดับ'};

const Map<String, String> kChartSectionTitleMap = {'KO': '시험 종류별 그래프', 'EN': 'Score Graph by Exam Type', 'JA': '試験種類別グラフ', 'ZH': '按考试类型的图表', 'FR': "Graphique par type d'examen", 'DE': 'Diagramm nach Prüfungsart', 'RU': 'График по типу экзамена', 'AR': 'الرسم البياني حسب نوع الاختبار', 'HI': 'परीक्षा प्रकार अनुसार ग्राफ', 'VI': 'Biểu đồ theo loại kỳ thi', 'ES': 'Gráfico por tipo de examen', 'TH': 'กราฟตามประเภทข้อสอบ'};
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
  return t(map);
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

const Map<String, String> kConfirmBtnMap = {'KO': '확인', 'EN': 'OK', 'JA': '確認', 'ZH': '确认', 'FR': 'OK', 'DE': 'OK', 'RU': 'ОК', 'AR': 'موافق', 'HI': 'ठीक है', 'VI': 'Xác nhận', 'ES': 'Aceptar', 'TH': 'ตกลง'};
const Map<String, String> kCancelBtnMap = {'KO': '취소', 'EN': 'Cancel', 'JA': 'キャンセル', 'ZH': '取消', 'FR': 'Annuler', 'DE': 'Abbrechen', 'RU': 'Отмена', 'AR': 'إلغاء', 'HI': 'रद्द करें', 'VI': 'Hủy', 'ES': 'Cancelar', 'TH': 'ยกเลิก'};
const Map<String, String> kSaveBtnMap = {'KO': '저장', 'EN': 'Save', 'JA': '保存', 'ZH': '保存', 'FR': 'Enregistrer', 'DE': 'Speichern', 'RU': 'Сохранить', 'AR': 'حفظ', 'HI': 'सहेजें', 'VI': 'Lưu', 'ES': 'Guardar', 'TH': 'บันทึก'};
const Map<String, String> kDeleteBtnMap = {'KO': '삭제', 'EN': 'Delete', 'JA': '削除', 'ZH': '删除', 'FR': 'Supprimer', 'DE': 'Löschen', 'RU': 'Удалить', 'AR': 'حذف', 'HI': 'हटाएं', 'VI': 'Xóa', 'ES': 'Eliminar', 'TH': 'ลบ'};
const Map<String, String> kNoneMap = {'KO': '없음', 'EN': 'None', 'JA': 'なし', 'ZH': '无', 'FR': 'Aucun', 'DE': 'Keine', 'RU': 'Нет', 'AR': 'لا شيء', 'HI': 'कोई नहीं', 'VI': 'Không có', 'ES': 'Ninguno', 'TH': 'ไม่มี'};

const Map<String, String> kReportCardSuffixMap = {
  'KO': '성적표', 'EN': 'Report Card', 'JA': '成績表', 'ZH': '成绩单', 'FR': 'Bulletin', 'DE': 'Zeugnis',
  'RU': 'Табель', 'AR': 'بطاقة الدرجات', 'HI': 'रिपोर्ट कार्ड', 'VI': 'Học bạ', 'ES': 'Boletín', 'TH': 'สมุดพก',
};
String reportCardTitle(String schoolLevel, int grade, int semester) {
  final scope = "${schoolLevelLabel(schoolLevel)}·${gradeChipLabel(grade)}·${semesterChipLabel(semester)}";
  return "$scope ${t(kReportCardSuffixMap)}";
}

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
  return t(map);
}

// 🆕 성적관리 안내 팝업 제목 - 학생/학부모 화면 공용
const Map<String, String> kPopupTitleMap = {'KO': '성적관리 안내', 'EN': 'Grade Management Notice', 'JA': '成績管理のご案内', 'ZH': '成绩管理说明', 'FR': 'Avis de gestion des notes', 'DE': 'Hinweis zur Notenverwaltung', 'RU': 'Уведомление об управлении оценками', 'AR': 'إشعار إدارة الدرجات', 'HI': 'ग्रेड प्रबंधन सूचना', 'VI': 'Thông báo quản lý điểm', 'ES': 'Aviso de gestión de calificaciones', 'TH': 'ประกาศการจัดการเกรด'};

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
