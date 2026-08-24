import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/grade_management_service.dart';
import '../services/grade_diagnosis_service.dart';
import '../services/user_profile_service.dart';
import '../services/grade_language.dart';
import '../global_lang.dart';

/// ============================================================================
/// [GKE StudyUp] 성적 관리 화면 - 학생용
/// - 기존 "나의 성적 기록"(member_achievement_screen.dart)과는 완전히 별도의
///   독립 기능입니다. gke_exam_records 키는 절대 건드리지 않고 참고용으로만 읽습니다.
/// - 🆕 [12개국어 전면 확장] grade_language.dart 공용 사전을 통해 학부모 화면과
///   동일한 수준으로 전체 화면·팝업·다이얼로그를 다국어 처리했습니다.
/// ============================================================================

// ---------------------------------------------------------------------------
// 🆕 학생 화면 전용 번역 사전 (학부모 화면에는 없는 입력/설정/다이얼로그 문구)
// ---------------------------------------------------------------------------
const Map<String, String> kStudentIntroPopupMap = {
  'KO': "성적관리는 입력하신 지필점수·수행점수·과목 단위수·전교생 수를 반영해 자동으로 계산됩니다.\n실제 학교 공식 성적표와는 오차가 있을 수 있으니 참고용으로 확인해 주세요.\n정확한 분석을 위해 점수와 인원수를 최대한 정확하게 입력해 주시면 좋습니다.",
  'EN': "Grade Management automatically calculates your report using the written scores, performance scores, subject unit counts, and total student count you entered.\nPlease note there may be discrepancies with the school's official report card.\nFor the most accurate analysis, please enter scores and headcounts as precisely as possible.",
  'JA': "成績管理は入力された筆記点数・遂行点数・科目単位数・全校生徒数を反映して自動計算されます。\n学校の公式成績表とは誤差がある場合がありますので、参考用としてご確認ください。\n正確な分析のため、点数と人数はできるだけ正確に入力してください。",
  'ZH': "成绩管理会根据您录入的笔试成绩、表现成绩、科目单位数及全校学生人数自动计算。\n请注意，可能与学校官方成绩单存在误差，仅供参考。\n为确保分析准确，请尽量准确录入分数与人数。",
  'FR': "La gestion des notes calcule automatiquement votre bilan à partir des notes écrites, des notes de performance, du nombre d'unités par matière et de l'effectif total que vous avez saisis.\nNotez qu'il peut y avoir des écarts avec le bulletin officiel de l'école.\nPour une analyse plus précise, veuillez saisir les notes et effectifs aussi précisément que possible.",
  'DE': "Die Notenverwaltung berechnet Ihren Bericht automatisch anhand der eingegebenen schriftlichen Noten, Leistungsnoten, Fach-Einheitenzahlen und Gesamtschülerzahl.\nBitte beachten Sie, dass es Abweichungen vom offiziellen Zeugnis der Schule geben kann.\nFür die genaueste Analyse geben Sie Noten und Personenzahlen bitte so präzise wie möglich ein.",
  'RU': "Управление оценками автоматически рассчитывает отчёт на основе введённых вами письменных оценок, оценок за практическую работу, количества единиц по предметам и общего числа учеников.\nОбратите внимание, что могут быть расхождения с официальным табелем школы.\nДля наиболее точного анализа вводите баллы и численность максимально точно.",
  'AR': "تقوم إدارة الدرجات بحساب تقريرك تلقائيًا باستخدام الدرجات التحريرية ودرجات الأداء وعدد وحدات المواد وإجمالي عدد الطلاب الذي أدخلته.\nيرجى ملاحظة أنه قد تكون هناك اختلافات مع بطاقة الدرجات الرسمية للمدرسة.\nللحصول على أدق تحليل، يرجى إدخال الدرجات وأعداد الطلاب بأكبر قدر ممكن من الدقة.",
  'HI': "ग्रेड प्रबंधन आपके द्वारा दर्ज लिखित अंक, प्रदर्शन अंक, विषय इकाई संख्या और कुल छात्र संख्या के आधार पर स्वचालित रूप से आपकी रिपोर्ट की गणना करता है।\nकृपया ध्यान दें कि स्कूल के आधिकारिक रिपोर्ट कार्ड से अंतर हो सकता है।\nसबसे सटीक विश्लेषण के लिए कृपया अंक और संख्याएं यथासंभव सटीक रूप से दर्ज करें।",
  'VI': "Quản lý điểm sẽ tự động tính toán báo cáo của bạn dựa trên điểm viết, điểm thực hành, số đơn vị môn học và tổng số học sinh mà bạn đã nhập.\nLưu ý có thể có sai lệch so với học bạ chính thức của trường.\nĐể phân tích chính xác nhất, vui lòng nhập điểm và số liệu càng chính xác càng tốt.",
  'ES': "Gestión de calificaciones calcula automáticamente su informe usando las notas escritas, las notas de desempeño, el número de unidades por materia y el total de estudiantes que ingresó.\nTenga en cuenta que puede haber discrepancias con el boletín oficial de la escuela.\nPara el análisis más preciso, ingrese las notas y cifras con la mayor exactitud posible.",
  'TH': "การจัดการเกรดจะคำนวณรายงานของคุณโดยอัตโนมัติจากคะแนนข้อเขียน คะแนนภาคปฏิบัติ จำนวนหน่วยกิตของวิชา และจำนวนนักเรียนทั้งหมดที่คุณกรอก\nโปรดทราบว่าอาจมีความคลาดเคลื่อนจากสมุดพกอย่างเป็นทางการของโรงเรียน\nเพื่อการวิเคราะห์ที่แม่นยำที่สุด กรุณากรอกคะแนนและจำนวนคนให้ถูกต้องที่สุดเท่าที่ทำได้",
};

const Map<String, String> kSchoolLevelHeaderMap = {'KO': '학교 구분', 'EN': 'School Level', 'JA': '学校区分', 'ZH': '学校类别', 'FR': "Niveau scolaire", 'DE': 'Schultyp', 'RU': 'Уровень школы', 'AR': 'المرحلة الدراسية', 'HI': 'स्कूल स्तर', 'VI': 'Bậc học', 'ES': 'Nivel escolar', 'TH': 'ระดับโรงเรียน'};
const Map<String, String> kNewSubjectHintMap = {'KO': '새 과목 이름 (예: 제2외국어)', 'EN': 'New subject name (e.g. 2nd Foreign Language)', 'JA': '新しい科目名（例：第二外国語）', 'ZH': '新科目名称（例：第二外语）', 'FR': "Nom de la nouvelle matière (ex. 2e langue)", 'DE': 'Neuer Fachname (z. B. 2. Fremdsprache)', 'RU': 'Название нового предмета (напр. 2-й иностранный язык)', 'AR': 'اسم مادة جديدة (مثال: لغة أجنبية ثانية)', 'HI': 'नया विषय नाम (जैसे: द्वितीय विदेशी भाषा)', 'VI': 'Tên môn học mới (VD: Ngoại ngữ 2)', 'ES': 'Nombre de la nueva materia (ej. 2º idioma)', 'TH': 'ชื่อวิชาใหม่ (เช่น ภาษาต่างประเทศที่ 2)'};
const Map<String, String> kAddSubjectBtnMap = {'KO': '과목 추가', 'EN': 'Add Subject', 'JA': '科目追加', 'ZH': '添加科目', 'FR': 'Ajouter une matière', 'DE': 'Fach hinzufügen', 'RU': 'Добавить предмет', 'AR': 'إضافة مادة', 'HI': 'विषय जोड़ें', 'VI': 'Thêm môn học', 'ES': 'Añadir materia', 'TH': 'เพิ่มวิชา'};
const Map<String, String> kSubjectOptionsHintMap = {
  'KO': '과목명 옆 ⋮ 아이콘을 누르면 설정·수정·삭제할 수 있습니다.',
  'EN': 'Tap the ⋮ icon next to a subject name to configure, rename, or delete it.',
  'JA': '科目名の横の⋮アイコンをタップすると設定・修正・削除ができます。',
  'ZH': '点击科目名旁边的⋮图标可进行设置、修改或删除。',
  'FR': "Appuyez sur l'icône ⋮ à côté du nom de la matière pour la configurer, la renommer ou la supprimer.",
  'DE': 'Tippen Sie auf das ⋮-Symbol neben dem Fachnamen, um es zu konfigurieren, umzubenennen oder zu löschen.',
  'RU': 'Нажмите значок ⋮ рядом с названием предмета, чтобы настроить, переименовать или удалить его.',
  'AR': 'اضغط على أيقونة ⋮ بجانب اسم المادة للإعداد أو إعادة التسمية أو الحذف.',
  'HI': 'सेटिंग, नाम बदलने या हटाने के लिए विषय नाम के पास ⋮ आइकन पर टैप करें।',
  'VI': 'Nhấn biểu tượng ⋮ bên cạnh tên môn học để cài đặt, đổi tên hoặc xóa.',
  'ES': 'Toque el icono ⋮ junto al nombre de la materia para configurarla, renombrarla o eliminarla.',
  'TH': 'แตะไอคอน ⋮ ข้างชื่อวิชาเพื่อตั้งค่า เปลี่ยนชื่อ หรือลบ',
};
const Map<String, String> kInputCellMap = {'KO': '입력', 'EN': 'Enter', 'JA': '入力', 'ZH': '输入', 'FR': 'Saisir', 'DE': 'Eingeben', 'RU': 'Ввести', 'AR': 'إدخال', 'HI': 'दर्ज करें', 'VI': 'Nhập', 'ES': 'Ingresar', 'TH': 'กรอก'};

const Map<String, String> kSubjectOptionSettingsItemMap = {
  'KO': '과목 설정 (지필·수행 반영비율 / 전체학생수 / 단위수)', 'EN': 'Subject Settings (written/performance weight, total students, unit hours)',
  'JA': '科目設定（筆記・遂行反映比率／全校生徒数／単位数）', 'ZH': '科目设置（笔试/表现反映比例、全校人数、单位数）',
  'FR': "Paramètres de la matière (pondération écrit/performance, effectif total, unités)", 'DE': 'Fach-Einstellungen (Gewichtung schriftlich/Leistung, Gesamtschülerzahl, Einheiten)',
  'RU': 'Настройки предмета (вес письменной/практической части, общее число учеников, единицы)', 'AR': 'إعدادات المادة (وزن التحريري/الأداء، إجمالي الطلاب، الوحدات)',
  'HI': 'विषय सेटिंग्स (लिखित/प्रदर्शन भारांक, कुल छात्र, इकाई घंटे)', 'VI': 'Cài đặt môn học (tỷ trọng viết/thực hành, tổng học sinh, số đơn vị)',
  'ES': 'Configuración de materia (ponderación escrito/desempeño, total de estudiantes, unidades)', 'TH': 'ตั้งค่าวิชา (สัดส่วนข้อเขียน/ภาคปฏิบัติ, จำนวนนักเรียนทั้งหมด, หน่วยกิต)',
};
const Map<String, String> kSubjectOptionRenameItemMap = {'KO': '과목명 수정', 'EN': 'Rename Subject', 'JA': '科目名修正', 'ZH': '修改科目名', 'FR': 'Renommer la matière', 'DE': 'Fach umbenennen', 'RU': 'Переименовать предмет', 'AR': 'إعادة تسمية المادة', 'HI': 'विषय नाम बदलें', 'VI': 'Đổi tên môn học', 'ES': 'Renombrar materia', 'TH': 'เปลี่ยนชื่อวิชา'};
const Map<String, String> kSubjectOptionDeleteItemMap = {
  'KO': '과목 삭제 (이 학년/학기 화면에서만 제외)', 'EN': 'Delete Subject (removed from this grade/semester view only)',
  'JA': '科目削除（この学年・学期画面のみ除外）', 'ZH': '删除科目（仅从本学年/学期界面移除）',
  'FR': "Supprimer la matière (retirée uniquement de cette vue niveau/semestre)", 'DE': 'Fach löschen (nur aus dieser Klassen-/Semesteransicht entfernt)',
  'RU': 'Удалить предмет (удаляется только из этого просмотра класса/семестра)', 'AR': 'حذف المادة (تُزال من عرض هذا الصف/الفصل فقط)',
  'HI': 'विषय हटाएं (केवल इस कक्षा/सेमेस्टर दृश्य से हटेगा)', 'VI': 'Xóa môn học (chỉ xóa khỏi màn hình khối/học kỳ này)',
  'ES': 'Eliminar materia (se quita solo de esta vista de grado/semestre)', 'TH': 'ลบวิชา (ลบออกเฉพาะมุมมองระดับชั้น/ภาคเรียนนี้)',
};

String subjectConfigTitle(String subject) {
  final Map<String, String> map = {
    'KO': '${subjectLabel(subject)} 과목 설정 (연 1회)', 'EN': '${subjectLabel(subject)} Subject Settings (Once a Year)',
    'JA': '${subjectLabel(subject)} 科目設定（年1回）', 'ZH': '${subjectLabel(subject)} 科目设置（每年一次）',
    'FR': 'Paramètres de ${subjectLabel(subject)} (une fois par an)', 'DE': '${subjectLabel(subject)} Fach-Einstellungen (einmal jährlich)',
    'RU': 'Настройки предмета ${subjectLabel(subject)} (раз в год)', 'AR': 'إعدادات مادة ${subjectLabel(subject)} (مرة واحدة سنويًا)',
    'HI': '${subjectLabel(subject)} विषय सेटिंग्स (वर्ष में एक बार)', 'VI': 'Cài đặt môn ${subjectLabel(subject)} (mỗi năm một lần)',
    'ES': 'Configuración de ${subjectLabel(subject)} (una vez al año)', 'TH': 'ตั้งค่าวิชา ${subjectLabel(subject)} (ปีละครั้ง)',
  };
  return t(map);
}
const Map<String, String> kSubjectConfigDescMap = {
  'KO': '설정을 저장하면 이 과목의 기존 점수도 자동으로 다시 계산됩니다.', 'EN': 'Saving these settings will automatically recalculate existing scores for this subject.',
  'JA': '設定を保存すると、この科目の既存の点数も自動的に再計算されます。', 'ZH': '保存设置后，该科目的现有成绩也将自动重新计算。',
  'FR': "L'enregistrement de ces paramètres recalculera automatiquement les notes existantes pour cette matière.", 'DE': 'Beim Speichern dieser Einstellungen werden bestehende Noten für dieses Fach automatisch neu berechnet.',
  'RU': 'Сохранение этих настроек автоматически пересчитает существующие баллы по этому предмету.', 'AR': 'سيؤدي حفظ هذه الإعدادات إلى إعادة حساب الدرجات الحالية لهذه المادة تلقائيًا.',
  'HI': 'इन सेटिंग्स को सहेजने से इस विषय के मौजूदा अंकों की स्वचालित रूप से पुनर्गणना होगी।', 'VI': 'Lưu cài đặt này sẽ tự động tính lại điểm hiện có cho môn học này.',
  'ES': 'Guardar esta configuración recalculará automáticamente las notas existentes de esta materia.', 'TH': 'การบันทึกการตั้งค่านี้จะคำนวณคะแนนที่มีอยู่ของวิชานี้ใหม่โดยอัตโนมัติ',
};
const Map<String, String> kWrittenRatioLabelMap = {'KO': '지필 반영비율(%)', 'EN': 'Written Weight (%)', 'JA': '筆記反映比率（%）', 'ZH': '笔试反映比例（%）', 'FR': 'Pondération écrit (%)', 'DE': 'Gewichtung schriftlich (%)', 'RU': 'Вес письменной части (%)', 'AR': 'وزن التحريري (%)', 'HI': 'लिखित भारांक (%)', 'VI': 'Tỷ trọng điểm viết (%)', 'ES': 'Ponderación escrito (%)', 'TH': 'สัดส่วนข้อเขียน (%)'};
const Map<String, String> kPerfRatioLabelMap = {'KO': '수행 반영비율(%)', 'EN': 'Performance Weight (%)', 'JA': '遂行反映比率（%）', 'ZH': '表现反映比例（%）', 'FR': 'Pondération performance (%)', 'DE': 'Gewichtung Leistung (%)', 'RU': 'Вес практической части (%)', 'AR': 'وزن الأداء (%)', 'HI': 'प्रदर्शन भारांक (%)', 'VI': 'Tỷ trọng điểm thực hành (%)', 'ES': 'Ponderación desempeño (%)', 'TH': 'สัดส่วนภาคปฏิบัติ (%)'};
const Map<String, String> kRatioValidMap = {'KO': '합계 100% ✓', 'EN': 'Total 100% ✓', 'JA': '合計100% ✓', 'ZH': '合计100% ✓', 'FR': 'Total 100 % ✓', 'DE': 'Summe 100 % ✓', 'RU': 'Итого 100% ✓', 'AR': 'المجموع 100% ✓', 'HI': 'कुल 100% ✓', 'VI': 'Tổng 100% ✓', 'ES': 'Total 100% ✓', 'TH': 'รวม 100% ✓'};
const Map<String, String> kRatioInvalidMap = {
  'KO': '※ 지필+수행 반영비율의 합은 100이어야 합니다.', 'EN': '※ The written + performance weights must add up to 100.',
  'JA': '※ 筆記＋遂行の反映比率の合計は100である必要があります。', 'ZH': '※ 笔试+表现的反映比例总和须为100。',
  'FR': "※ La somme des pondérations écrit + performance doit être égale à 100.", 'DE': '※ Die Summe aus schriftlicher und Leistungsgewichtung muss 100 ergeben.',
  'RU': '※ Сумма весов письменной и практической частей должна равняться 100.', 'AR': '※ يجب أن يكون مجموع وزن التحريري + الأداء يساوي 100.',
  'HI': '※ लिखित + प्रदर्शन भारांक का योग 100 होना चाहिए।', 'VI': '※ Tổng tỷ trọng viết + thực hành phải bằng 100.',
  'ES': '※ La suma de las ponderaciones de escrito y desempeño debe ser 100.', 'TH': '※ ผลรวมของสัดส่วนข้อเขียน + ภาคปฏิบัติต้องเท่ากับ 100',
};
const Map<String, String> kTotalStudentsLabelMap = {
  'KO': '학년 전체 인원 (선택, 고등부 등급 계산용)', 'EN': 'Total Students in Grade (optional, for high school grading)',
  'JA': '学年全体人数（任意、高校部の等級計算用）', 'ZH': '年级全体人数（选填，用于高中部等级计算）',
  'FR': "Effectif total du niveau (facultatif, pour le calcul des notes au lycée)", 'DE': 'Gesamtschülerzahl der Klassenstufe (optional, für Oberschul-Notenberechnung)',
  'RU': 'Общее число учеников в классе (необязательно, для расчёта оценок в старшей школе)', 'AR': 'إجمالي عدد الطلاب في الصف (اختياري، لحساب درجات المرحلة الثانوية)',
  'HI': 'कक्षा में कुल छात्र (वैकल्पिक, हाई स्कूल ग्रेडिंग हेतु)', 'VI': 'Tổng số học sinh trong khối (không bắt buộc, dùng tính điểm THPT)',
  'ES': 'Total de estudiantes del grado (opcional, para calificación de bachillerato)', 'TH': 'จำนวนนักเรียนทั้งหมดในระดับชั้น (ไม่บังคับ ใช้คำนวณเกรดมัธยมปลาย)',
};
const Map<String, String> kUnitHoursLabelMap = {
  'KO': '단위수 (주당 시수, 예: 주4시간=4)', 'EN': 'Unit Hours (weekly hours, e.g. 4 hrs/week = 4)',
  'JA': '単位数（週の時数、例：週4時間=4）', 'ZH': '单位数（每周课时，例：每周4小时=4）',
  'FR': "Unités (heures hebdomadaires, ex. 4h/semaine = 4)", 'DE': 'Einheiten (Wochenstunden, z. B. 4 Std./Woche = 4)',
  'RU': 'Единицы (часов в неделю, напр. 4 ч/нед = 4)', 'AR': 'الوحدات (ساعات أسبوعية، مثال: 4 ساعات/أسبوع = 4)',
  'HI': 'इकाई घंटे (साप्ताहिक घंटे, जैसे: सप्ताह में 4 घंटे = 4)', 'VI': 'Số đơn vị (giờ mỗi tuần, VD: 4 giờ/tuần = 4)',
  'ES': 'Unidades (horas semanales, ej. 4 h/semana = 4)', 'TH': 'หน่วยกิต (ชั่วโมงต่อสัปดาห์ เช่น 4 ชม./สัปดาห์ = 4)',
};

const Map<String, String> kConfigNeededTitleMap = {'KO': '과목 설정이 필요합니다', 'EN': 'Subject Setup Required', 'JA': '科目設定が必要です', 'ZH': '需要先进行科目设置', 'FR': "Configuration de la matière requise", 'DE': 'Fach-Einrichtung erforderlich', 'RU': 'Требуется настройка предмета', 'AR': 'إعداد المادة مطلوب', 'HI': 'विषय सेटअप आवश्यक है', 'VI': 'Cần cài đặt môn học', 'ES': 'Se requiere configurar la materia', 'TH': 'ต้องตั้งค่าวิชาก่อน'};
String configNeededDesc(String subject) {
  final s = subjectLabel(subject);
  final Map<String, String> map = {
    'KO': '$s 과목은 아직 지필·수행 반영비율이 설정되지 않았습니다. 먼저 과목 설정을 진행해 주세요.',
    'EN': 'Written/performance weights have not been set for $s yet. Please complete the subject setup first.',
    'JA': '$s科目はまだ筆記・遂行反映比率が設定されていません。先に科目設定を行ってください。',
    'ZH': '$s科目尚未设置笔试/表现反映比例，请先完成科目设置。',
    'FR': "Les pondérations écrit/performance ne sont pas encore définies pour $s. Veuillez d'abord effectuer la configuration de la matière.",
    'DE': 'Für $s wurden noch keine Gewichtungen für schriftlich/Leistung festgelegt. Bitte richten Sie das Fach zuerst ein.',
    'RU': 'Для предмета $s ещё не заданы веса письменной/практической части. Сначала выполните настройку предмета.',
    'AR': 'لم يتم تعيين وزن التحريري/الأداء لمادة $s بعد. يرجى إكمال إعداد المادة أولاً.',
    'HI': '$s विषय के लिए अभी लिखित/प्रदर्शन भारांक सेट नहीं किया गया है। कृपया पहले विषय सेटअप पूरा करें।',
    'VI': 'Tỷ trọng viết/thực hành chưa được thiết lập cho môn $s. Vui lòng hoàn tất cài đặt môn học trước.',
    'ES': 'Aún no se han configurado las ponderaciones de escrito/desempeño para $s. Complete primero la configuración de la materia.',
    'TH': 'ยังไม่ได้ตั้งค่าสัดส่วนข้อเขียน/ภาคปฏิบัติสำหรับวิชา $s กรุณาตั้งค่าวิชาก่อน',
  };
  return t(map);
}
const Map<String, String> kGoSetupBtnMap = {'KO': '설정하러 가기', 'EN': 'Go to Setup', 'JA': '設定へ移動', 'ZH': '前往设置', 'FR': 'Aller à la configuration', 'DE': 'Zur Einrichtung', 'RU': 'Перейти к настройке', 'AR': 'الانتقال إلى الإعداد', 'HI': 'सेटअप पर जाएं', 'VI': 'Đi đến cài đặt', 'ES': 'Ir a configuración', 'TH': 'ไปตั้งค่า'};

const Map<String, String> kWrittenScoreLabelMap = {'KO': '지필점수', 'EN': 'Written Score', 'JA': '筆記点数', 'ZH': '笔试成绩', 'FR': 'Note écrite', 'DE': 'Schriftliche Note', 'RU': 'Письменный балл', 'AR': 'الدرجة التحريرية', 'HI': 'लिखित अंक', 'VI': 'Điểm viết', 'ES': 'Nota escrita', 'TH': 'คะแนนข้อเขียน'};
const Map<String, String> kPerfScoreLabelMap = {'KO': '수행점수', 'EN': 'Performance Score', 'JA': '遂行点数', 'ZH': '表现成绩', 'FR': 'Note de performance', 'DE': 'Leistungsnote', 'RU': 'Практический балл', 'AR': 'درجة الأداء', 'HI': 'प्रदर्शन अंक', 'VI': 'Điểm thực hành', 'ES': 'Nota de desempeño', 'TH': 'คะแนนภาคปฏิบัติ'};
const Map<String, String> kMockNoteMap = {
  'KO': '※ 모의고사는 지필 100%로 계산됩니다 (수행 항목 없음).', 'EN': '※ Mock exams are calculated as 100% written (no performance component).',
  'JA': '※ 模試は筆記100%で計算されます（遂行項目なし）。', 'ZH': '※ 模拟考试按笔试100%计算（无表现项目）。',
  'FR': "※ Les examens blancs sont calculés à 100 % sur l'écrit (pas de composante performance).", 'DE': '※ Testexamen werden zu 100 % schriftlich berechnet (kein Leistungsanteil).',
  'RU': '※ Пробные экзамены оцениваются на 100% по письменной части (без практического компонента).', 'AR': '※ يتم احتساب الاختبارات التجريبية بنسبة 100% تحريري (بدون مكون أداء).',
  'HI': '※ मॉक परीक्षा को 100% लिखित के रूप में गिना जाता है (कोई प्रदर्शन घटक नहीं)।', 'VI': '※ Thi thử được tính 100% điểm viết (không có phần thực hành).',
  'ES': '※ Los exámenes simulados se calculan como 100% escrito (sin componente de desempeño).', 'TH': '※ ข้อสอบจำลองคิดคะแนนข้อเขียน 100% (ไม่มีภาคปฏิบัติ)',
};
const Map<String, String> kPersonalRankLabelMap = {'KO': '개인 석차 (선택)', 'EN': 'Personal Rank (optional)', 'JA': '個人順位（任意）', 'ZH': '个人排名（选填）', 'FR': 'Classement personnel (facultatif)', 'DE': 'Persönlicher Rang (optional)', 'RU': 'Личный рейтинг (необязательно)', 'AR': 'الترتيب الشخصي (اختياري)', 'HI': 'व्यक्तिगत रैंक (वैकल्पिक)', 'VI': 'Thứ hạng cá nhân (không bắt buộc)', 'ES': 'Puesto personal (opcional)', 'TH': 'อันดับส่วนตัว (ไม่บังคับ)'};

const Map<String, String> kReflectedScoreWaitingMap = {'KO': '→ 반영점수 계산 대기 중', 'EN': '→ Waiting to calculate reflected score', 'JA': '→ 反映点数計算待ち', 'ZH': '→ 反映分数计算中', 'FR': "→ Calcul de la note reflétée en attente", 'DE': '→ Warten auf Berechnung des Gesamtwerts', 'RU': '→ Ожидание расчёта итогового балла', 'AR': '→ في انتظار حساب الدرجة المجمعة', 'HI': '→ प्रतिबिंबित स्कोर गणना प्रतीक्षारत', 'VI': '→ Đang chờ tính điểm phản ánh', 'ES': '→ Esperando cálculo de la puntuación reflejada', 'TH': '→ รอคำนวณคะแนนสะท้อน'};
String reflectedScoreText(double avg) {
  final Map<String, String> map = {
    'KO': '→ 반영점수: ${avg.toStringAsFixed(1)}', 'EN': '→ Reflected Score: ${avg.toStringAsFixed(1)}',
    'JA': '→ 反映点数: ${avg.toStringAsFixed(1)}', 'ZH': '→ 反映分数: ${avg.toStringAsFixed(1)}',
    'FR': '→ Note reflétée : ${avg.toStringAsFixed(1)}', 'DE': '→ Gesamtwert: ${avg.toStringAsFixed(1)}',
    'RU': '→ Итоговый балл: ${avg.toStringAsFixed(1)}', 'AR': '→ الدرجة المجمعة: ${avg.toStringAsFixed(1)}',
    'HI': '→ प्रतिबिंबित स्कोर: ${avg.toStringAsFixed(1)}', 'VI': '→ Điểm phản ánh: ${avg.toStringAsFixed(1)}',
    'ES': '→ Puntuación reflejada: ${avg.toStringAsFixed(1)}', 'TH': '→ คะแนนสะท้อน: ${avg.toStringAsFixed(1)}',
  };
  return t(map);
}
const Map<String, String> kAutoGradeWaitingMap = {'KO': '→ 등급 계산 대기 중', 'EN': '→ Waiting to calculate grade', 'JA': '→ 等級計算待ち', 'ZH': '→ 等级计算中', 'FR': "→ Calcul du niveau en attente", 'DE': '→ Warten auf Notenberechnung', 'RU': '→ Ожидание расчёта уровня', 'AR': '→ في انتظار حساب الدرجة', 'HI': '→ ग्रेड गणना प्रतीक्षारत', 'VI': '→ Đang chờ tính hạng', 'ES': '→ Esperando cálculo del nivel', 'TH': '→ รอคำนวณระดับ'};
String autoGradeText(String grade) {
  final g = gradeLetterLabel(grade);
  final Map<String, String> map = {
    'KO': '→ 자동계산등급: $g', 'EN': '→ Auto-Calculated Grade: $g', 'JA': '→ 自動計算等級: $g', 'ZH': '→ 自动计算等级: $g',
    'FR': '→ Niveau calculé automatiquement : $g', 'DE': '→ Automatisch berechnete Note: $g', 'RU': '→ Автоматически рассчитанный уровень: $g',
    'AR': '→ الدرجة المحسوبة تلقائيًا: $g', 'HI': '→ स्वतः गणना ग्रेड: $g', 'VI': '→ Hạng tự động tính: $g', 'ES': '→ Nivel calculado automáticamente: $g', 'TH': '→ ระดับที่คำนวณอัตโนมัติ: $g',
  };
  return t(map);
}

const Map<String, String> kWrittenScoreRequiredMap = {'KO': '지필점수를 입력해 주세요.', 'EN': 'Please enter the written score.', 'JA': '筆記点数を入力してください。', 'ZH': '请输入笔试成绩。', 'FR': "Veuillez saisir la note écrite.", 'DE': 'Bitte geben Sie die schriftliche Note ein.', 'RU': 'Пожалуйста, введите письменный балл.', 'AR': 'يرجى إدخال الدرجة التحريرية.', 'HI': 'कृपया लिखित अंक दर्ज करें।', 'VI': 'Vui lòng nhập điểm viết.', 'ES': 'Por favor, ingrese la nota escrita.', 'TH': 'กรุณากรอกคะแนนข้อเขียน'};
const Map<String, String> kPerfScoreRequiredMap = {'KO': '수행점수를 입력해 주세요.', 'EN': 'Please enter the performance score.', 'JA': '遂行点数を入力してください。', 'ZH': '请输入表现成绩。', 'FR': "Veuillez saisir la note de performance.", 'DE': 'Bitte geben Sie die Leistungsnote ein.', 'RU': 'Пожалуйста, введите практический балл.', 'AR': 'يرجى إدخال درجة الأداء.', 'HI': 'कृपया प्रदर्शन अंक दर्ज करें।', 'VI': 'Vui lòng nhập điểm thực hành.', 'ES': 'Por favor, ingrese la nota de desempeño.', 'TH': 'กรุณากรอกคะแนนภาคปฏิบัติ'};

class GradeManagementScreen extends StatefulWidget {
  const GradeManagementScreen({super.key});

  @override
  State<GradeManagementScreen> createState() => _GradeManagementScreenState();
}

class _ThemeColors {
  static const Color brandGolden = Color(0xFFE5C158);
  static const Color luxuryDarkBg = Color(0xFF030712);
  static const Color premiumCardBg = Color(0xFF0D1527);
}

// 🆕 [요청] 과목별 막대 색상 순환: 빨/파(진한 파랑)/주/초/노/남/보 반복
const List<Color> kSubjectRainbowColors = [
  Color(0xFFFF3B30), // 빨
  Color(0xFF0A4FE0), // 파 (진한 파랑)
  Color(0xFFFF9500), // 주
  Color(0xFF34C759), // 초
  Color(0xFFFFCC00), // 노
  Color(0xFF1E3A8A), // 남
  Color(0xFFAF52DE), // 보
];

class _GradeManagementScreenState extends State<GradeManagementScreen> {
  String _schoolLevel = "중등부";
  int _grade = 1;
  int _semester = 1;

  bool _isLoading = true;
  List<GradeRecord> _allRecords = [];
  List<SubjectConfig> _allConfigs = [];
  Set<String> _hiddenSubjects = {};
  final List<String> _customSubjects = [];

  final TextEditingController _newSubjectController = TextEditingController();

  String? _summaryText;
  bool _isSummaryLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showIntroPopupOnce());
  }

  @override
  void dispose() {
    _newSubjectController.dispose();
    super.dispose();
  }

  void _showIntroPopupOnce() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _ThemeColors.premiumCardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _ThemeColors.brandGolden.withOpacity(0.55), width: 1.6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t(kPopupTitleMap), style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Text(biLong(kStudentIntroPopupMap), style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13, height: 1.6)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _ThemeColors.brandGolden),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(t(kConfirmBtnMap), style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadAll() async {
    final records = await GradeManagementService.loadAll();
    final configs = await GradeManagementService.loadAllConfigs();
    final hidden = await GradeManagementService.loadHiddenSubjects();
    if (!mounted) return;
    setState(() {
      _allRecords = records;
      _allConfigs = configs;
      _hiddenSubjects = hidden;
      _isLoading = false;
    });
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final filtered = _currentFiltered;
    final overall = GradeManagementService.computeOverallSummary(filtered, _schoolLevel, _allConfigs);
    final double? avg = overall["average"] as double?;
    if (avg == null) {
      setState(() => _summaryText = null);
      return;
    }
    setState(() => _isSummaryLoading = true);
    final String? name = await DkeUserProfile.getRealName();
    final double? achievementAvg = await GradeManagementService.readAchievementAverageScore();
    final String personKey = 'student_${name ?? "unknown"}_$_schoolLevel$_grade$_semester';
    final GradeSummaryResult result = await GradeDiagnosisService.getOverallSummary(
      personKey: personKey, combinedAverage: avg, achievementAverage: achievementAvg,
    );
    if (!mounted) return;
    setState(() {
      // 🆕 [12개국어] 기본모드(KO/EN)는 한글+영문, 10개국어 선택 시 해당 언어 단독 표시
      _summaryText = result.display();
      _isSummaryLoading = false;
    });
  }

  List<String> get _baseSubjects => _schoolLevel == "중등부"
      ? GradeManagementService.middleSchoolSubjects
      : GradeManagementService.highSchoolSubjects;

  List<String> get _visibleSubjects {
    final Set<String> set = {..._baseSubjects, ..._customSubjects};
    for (final r in _currentFiltered) {
      set.add(r.subject);
    }
    final hiddenNow = _hiddenSubjects;
    return set.where((s) => !hiddenNow.contains(GradeManagementService.hiddenKey(_schoolLevel, _grade, _semester, s))).toList();
  }

  List<GradeRecord> get _currentFiltered => GradeManagementService.filterBy(
    _allRecords, schoolLevel: _schoolLevel, grade: _grade, semester: _semester,
  );

  SubjectConfig? _configFor(String subject) => GradeManagementService.findConfig(
    _allConfigs, schoolLevel: _schoolLevel, grade: _grade, semester: _semester, subject: subject,
  );

  void _addCustomSubject() {
    final text = _newSubjectController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      if (!_customSubjects.contains(text)) _customSubjects.add(text);
      _newSubjectController.clear();
    });
  }

  Future<void> _showSubjectOptionsSheet(String subject) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: _ThemeColors.premiumCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: _ThemeColors.brandGolden.withOpacity(0.4), width: 1.2),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(subjectLabel(subject), style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                ListTile(
                  leading: const Icon(Icons.settings_rounded, color: _ThemeColors.brandGolden),
                  title: Text(t(kSubjectOptionSettingsItemMap), style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13)),
                  onTap: () { Navigator.pop(ctx); _showSubjectConfigDialog(subject); },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: Colors.white70),
                  title: Text(t(kSubjectOptionRenameItemMap), style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13)),
                  onTap: () { Navigator.pop(ctx); _showRenameDialog(subject); },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  title: Text(t(kSubjectOptionDeleteItemMap), style: GoogleFonts.notoSansKr(color: Colors.redAccent, fontSize: 13)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await GradeManagementService.hideSubject(_schoolLevel, _grade, _semester, subject);
                    await _loadAll();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRenameDialog(String subject) async {
    final TextEditingController ctrl = TextEditingController(text: subject);
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _ThemeColors.premiumCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _ThemeColors.brandGolden.withOpacity(0.5), width: 1.5)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t(kSubjectOptionRenameItemMap), style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true, fillColor: Colors.black26,
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white12), borderRadius: BorderRadius.circular(6)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: _ThemeColors.brandGolden), borderRadius: BorderRadius.circular(6)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t(kCancelBtnMap), style: GoogleFonts.notoSansKr(color: Colors.white54)))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _ThemeColors.brandGolden),
                      onPressed: () async {
                        final newName = ctrl.text.trim();
                        if (newName.isEmpty) return;
                        await GradeManagementService.renameSubject(
                          schoolLevel: _schoolLevel, grade: _grade, semester: _semester, oldName: subject, newName: newName,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _loadAll();
                      },
                      child: Text(t(kSaveBtnMap), style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSubjectConfigDialog(String subject) async {
    final existing = _configFor(subject);
    final TextEditingController writtenCtrl = TextEditingController(text: (existing?.writtenRatio ?? 70).toStringAsFixed(0));
    final TextEditingController perfCtrl = TextEditingController(text: (existing?.performanceRatio ?? 30).toStringAsFixed(0));
    final TextEditingController totalCtrl = TextEditingController(text: existing?.totalStudents?.toString() ?? "");
    final TextEditingController unitCtrl = TextEditingController(text: (existing?.unitHours ?? 3).toString());

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setPopupState) {
          final int? w = int.tryParse(writtenCtrl.text);
          final int? p = int.tryParse(perfCtrl.text);
          final bool ratioValid = w != null && p != null && (w + p) == 100;

          return Dialog(
            backgroundColor: _ThemeColors.premiumCardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _ThemeColors.brandGolden.withOpacity(0.55), width: 1.6)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subjectConfigTitle(subject), style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(t(kSubjectConfigDescMap), style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10.5)),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _buildLabeledField(t(kWrittenRatioLabelMap), writtenCtrl, onChanged: () => setPopupState(() {})),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildLabeledField(t(kPerfRatioLabelMap), perfCtrl, onChanged: () => setPopupState(() {})),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ratioValid ? t(kRatioValidMap) : t(kRatioInvalidMap),
                      style: GoogleFonts.notoSansKr(color: ratioValid ? Colors.greenAccent : Colors.redAccent, fontSize: 11),
                    ),
                    const SizedBox(height: 14),
                    _buildLabeledField(t(kTotalStudentsLabelMap), totalCtrl),
                    const SizedBox(height: 4),
                    Text(t(kRankDisclaimerMap), style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10.5, height: 1.4)),
                    const SizedBox(height: 14),
                    _buildLabeledField(t(kUnitHoursLabelMap), unitCtrl),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: ratioValid ? _ThemeColors.brandGolden : Colors.white24),
                        onPressed: !ratioValid ? null : () async {
                          final config = SubjectConfig(
                            schoolLevel: _schoolLevel, grade: _grade, semester: _semester, subject: subject,
                            writtenRatio: w!.toDouble(), performanceRatio: p!.toDouble(),
                            totalStudents: int.tryParse(totalCtrl.text), unitHours: int.tryParse(unitCtrl.text) ?? 3,
                            updatedAt: DateTime.now(),
                          );
                          await GradeManagementService.saveConfig(config);
                          if (ctx.mounted) Navigator.pop(ctx);
                          await _loadAll();
                        },
                        child: Text(t(kSaveBtnMap), style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildLabeledField(String label, TextEditingController ctrl, {VoidCallback? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          onChanged: (_) => onChanged?.call(),
          decoration: InputDecoration(
            filled: true, fillColor: Colors.black26,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white12), borderRadius: BorderRadius.circular(6)),
            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: _ThemeColors.brandGolden), borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ],
    );
  }

  Future<void> _showEntryDialog({required String subject, required String examType, GradeRecord? existing}) async {
    final config = _configFor(subject);
    if (config == null) {
      final bool? goSetup = await showDialog<bool>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: _ThemeColors.premiumCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _ThemeColors.brandGolden.withOpacity(0.55), width: 1.6)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t(kConfigNeededTitleMap), style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                Text(configNeededDesc(subject), style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12.5, height: 1.5)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t(kCancelBtnMap), style: GoogleFonts.notoSansKr(color: Colors.white54)))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _ThemeColors.brandGolden),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(t(kGoSetupBtnMap), style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      if (goSetup == true) await _showSubjectConfigDialog(subject);
      return;
    }

    final bool isMock = examType == "모의고사";
    final TextEditingController writtenCtrl = TextEditingController(text: existing?.writtenScore?.toStringAsFixed(0) ?? "");
    final TextEditingController perfCtrl = TextEditingController(text: existing?.performanceScore?.toStringAsFixed(0) ?? "");
    final TextEditingController rankCtrl = TextEditingController(text: existing?.personalRank?.toString() ?? "");

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setPopupState) {
          final double? w = double.tryParse(writtenCtrl.text);
          final double? p = isMock ? null : double.tryParse(perfCtrl.text);
          final double? previewAvg = GradeManagementService.computeAverage(examType: examType, writtenScore: w, performanceScore: p, config: config);
          final int? previewRank = int.tryParse(rankCtrl.text);
          final String? previewGrade = GradeManagementService.computeGrade(
            schoolLevel: _schoolLevel, average: previewAvg, personalRank: previewRank, totalStudents: config.totalStudents,
          );

          return Dialog(
            backgroundColor: _ThemeColors.premiumCardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _ThemeColors.brandGolden.withOpacity(0.55), width: 1.6)),
            child: Container(
              width: MediaQuery.of(ctx).size.width * 0.9,
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text("${subjectLabel(subject)} · ${examTypeLabel(examType)}", style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 16))),
                        IconButton(icon: const Icon(Icons.close, color: Colors.white60, size: 20), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 16),

                    _buildLabeledField(t(kWrittenScoreLabelMap), writtenCtrl, onChanged: () => setPopupState(() {})),
                    const SizedBox(height: 12),
                    if (!isMock) ...[
                      _buildLabeledField(t(kPerfScoreLabelMap), perfCtrl, onChanged: () => setPopupState(() {})),
                      const SizedBox(height: 12),
                    ] else ...[
                      Text(t(kMockNoteMap), style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 11)),
                      const SizedBox(height: 12),
                    ],

                    if (_schoolLevel == "고등부") ...[
                      _buildLabeledField(t(kPersonalRankLabelMap), rankCtrl, onChanged: () => setPopupState(() {})),
                      const SizedBox(height: 4),
                      Text(t(kRankDisclaimerMap), style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10.5, height: 1.4)),
                      const SizedBox(height: 12),
                    ],

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            previewAvg != null ? reflectedScoreText(previewAvg) : t(kReflectedScoreWaitingMap),
                            style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            previewGrade != null ? autoGradeText(previewGrade) : t(kAutoGradeWaitingMap),
                            style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        if (existing != null) ...[
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                              onPressed: () async {
                                await GradeManagementService.deleteRecord(existing.id);
                                if (ctx.mounted) Navigator.pop(ctx);
                                await _loadAll();
                              },
                              child: Text(t(kDeleteBtnMap), style: GoogleFonts.notoSansKr(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: _ThemeColors.brandGolden, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            onPressed: () async {
                              if (w == null) {
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(t(kWrittenScoreRequiredMap), style: GoogleFonts.notoSansKr())));
                                return;
                              }
                              if (!isMock && p == null) {
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(t(kPerfScoreRequiredMap), style: GoogleFonts.notoSansKr())));
                                return;
                              }
                              await GradeManagementService.addOrUpdateRecord(
                                existingId: existing?.id,
                                schoolLevel: _schoolLevel, grade: _grade, semester: _semester,
                                examType: examType, subject: subject,
                                writtenScore: w, performanceScore: isMock ? null : p,
                                personalRank: previewRank, config: config,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              await _loadAll();
                            },
                            child: Text(t(kSaveBtnMap), style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildCell(String subject, String examType) {
    final GradeRecord? rec = _currentFiltered
        .where((r) => r.subject == subject && r.examType == examType)
        .fold<GradeRecord?>(null, (prev, r) => (prev == null || r.updatedAt.isAfter(prev.updatedAt)) ? r : prev);

    return InkWell(
      onTap: () => _showEntryDialog(subject: subject, examType: examType, existing: rec),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: rec != null ? Colors.black26 : Colors.black12,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _ThemeColors.brandGolden.withOpacity(rec != null ? 0.5 : 0.18), width: 1.2),
        ),
        child: rec == null
            ? Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(t(kInputCellMap), style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12))))
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                rec.computedAverage != null ? rec.computedAverage!.toStringAsFixed(1) : t(kNotComputedMap),
                style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                rec.computedGrade != null ? gradeLetterLabel(rec.computedGrade!) : t(kGradeNotComputedMap),
                style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 [요청] "종합" 한 줄이 아니라 중간고사/기말고사/모의고사 각 열 맨 아래에
  // 그 시험 종류만의 평균·등급을 따로 표시
  Widget _buildExamTypeSummaryCell(String examType) {
    final summary = GradeManagementService.computeExamTypeSummary(_currentFiltered, examType, _schoolLevel, _allConfigs);
    final double? avg = summary["average"] as double?;
    final String? grade = summary["grade"] as String?;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.55), width: 1.3),
      ),
      child: avg == null
          ? Center(child: Text("-", style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12)))
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(avg.toStringAsFixed(1), style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
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
  static const double _kChartBuffer = 18.0;   // 점수 숫자가 막대 위로 넘칠 공간(막대 높이 계산에는 포함 안 됨)
  static const double _kChartBarMax = 156.0;  // 100점 = 이 높이
  static const double _kChartBottomPad = 38.0; // X축 아래 과목명 표시 공간

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
    // 🆕 [요청] 알파벳/가나다 정렬이 아니라, 위쪽 성적표에 나열된 과목 순서 그대로
    // 왼쪽부터 막대가 나오도록 정렬 (3개 그래프를 나란히 비교하기 위함)
    final List<String> order = _visibleSubjects;
    final recs = _currentFiltered.where((r) => r.examType == examType && r.computedAverage != null).toList()
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
        color: _ThemeColors.premiumCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.5), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(examTypeLabel(examType), style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 14)),
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
                  // Y축 라벨 (흰 점 없이 텍스트만 — 점은 아래에서 축 선 위에 별도로 찍음)
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
                  // Y축 세로선
                  Positioned(
                    left: 38, top: _kChartBuffer, bottom: _kChartBottomPad,
                    child: Container(width: 1.6, color: _ThemeColors.brandGolden.withOpacity(0.6)),
                  ),
                  // 🆕 [요청] Y축 라벨 옆 흰 점 대신, 축 선 위에 눈금 점으로 표시
                  ..._buildYAxisTickDots(),
                  // X축 가로선 — 막대 하단(0점 기준선)과 정확히 일치
                  Positioned(
                    left: 38, right: 0, top: _kChartBuffer + _kChartBarMax,
                    child: Container(height: 1.8, color: _ThemeColors.brandGolden.withOpacity(0.6)),
                  ),
                  // 막대 + 과목명
                  Positioned(
                    left: 44, right: 0, top: 0, bottom: 0,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(recs.length, (idx) {
                          final r = recs[idx];
                          final double h = (r.computedAverage!.clamp(0, 100) / 100.0) * _kChartBarMax;
                          // 🆕 [요청] 색상은 그래프 내 나열 순서가 아니라, 성적표의 과목 고정 순서를 기준으로
                          // 배정 — 국어=빨강처럼 과목마다 3개 그래프(중간/기말/모의) 전부 동일한 색을 유지
                          final int colorIdx = order.indexOf(r.subject);
                          final Color color = kSubjectRainbowColors[(colorIdx == -1 ? idx : colorIdx) % kSubjectRainbowColors.length];
                          return Container(
                            width: 46,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 🆕 막대 영역은 정확히 _kChartBarMax(0~100점) 높이만 차지하고,
                                // 점수 숫자는 그 위(버퍼 영역)에 겹쳐서 그려 막대 높이 계산에 영향을 주지 않음
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
    return Scaffold(
      backgroundColor: _ThemeColors.luxuryDarkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("GRADE MANAGEMENT", style: GoogleFonts.notoSerif(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)),
            const SizedBox(height: 1),
            Text("성적 관리", style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5C158)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t(kSchoolLevelHeaderMap), style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: GradeManagementService.schoolLevels.map((lv) {
                  final bool isSel = _schoolLevel == lv;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () { setState(() { _schoolLevel = lv; _grade = 1; }); _loadSummary(); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSel ? _ThemeColors.brandGolden : Colors.black38,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _ThemeColors.brandGolden.withOpacity(isSel ? 0.9 : 0.3), width: 1.3),
                        ),
                        child: Text(schoolLevelLabel(lv), style: GoogleFonts.notoSansKr(color: isSel ? Colors.black : Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            Text(t(kGradeWordMap), style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: GradeManagementService.gradeRange.map((g) {
                  final bool isSel = _grade == g;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () { setState(() => _grade = g); _loadSummary(); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSel ? _ThemeColors.brandGolden : Colors.black38,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _ThemeColors.brandGolden.withOpacity(isSel ? 0.9 : 0.3), width: 1.3),
                        ),
                        child: Text(gradeChipLabel(g), style: GoogleFonts.notoSansKr(color: isSel ? Colors.black : Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            Text(t(kSemesterWordMap), style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [1, 2].map((s) {
                  final bool isSel = _semester == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () { setState(() => _semester = s); _loadSummary(); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSel ? _ThemeColors.brandGolden : Colors.black38,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _ThemeColors.brandGolden.withOpacity(isSel ? 0.9 : 0.3), width: 1.3),
                        ),
                        child: Text(semesterChipLabel(s), style: GoogleFonts.notoSansKr(color: isSel ? Colors.black : Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),

            Text(
              "MIDDLE/HIGH · REPORT CARD",
              style: GoogleFonts.notoSerif(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.8),
            ),
            Text(
              reportCardTitle(_schoolLevel, _grade, _semester),
              style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _ThemeColors.premiumCardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.5), width: 1.4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🆕 [오버플로우 근본 수정] 가로 스크롤에 의존하지 않고, 화면 폭에 맞춰
                  // 자동으로 줄어드는 Expanded 비율 레이아웃으로 전환 (과목:2, 시험종류 각 3)
                  Row(
                    children: [
                      Expanded(flex: 2, child: Text(t(kSubjectHeaderMap), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
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
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onLongPress: () => _showSubjectOptionsSheet(subject),
                              onTap: () => _showSubjectOptionsSheet(subject),
                              child: Row(
                                children: [
                                  Flexible(child: Text(subjectLabel(subject), style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                  const Icon(Icons.more_vert_rounded, color: Colors.white24, size: 14),
                                ],
                              ),
                            ),
                          ),
                          ...GradeManagementService.examTypes.map((et) => Expanded(flex: 3, child: _buildCell(subject, et))),
                        ],
                      ),
                    );
                  }),
                  const Divider(color: Colors.white10, height: 20),
                  // 🆕 [요청] "종합" 한 줄이 아니라, 중간고사/기말고사/모의고사 각 열 맨 아래에
                  // 그 시험 종류만의 평균·등급을 개별 표시
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 2, child: Text(t(kAvgGradeHeaderMap), style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontSize: 12, fontWeight: FontWeight.bold))),
                      ...GradeManagementService.examTypes.map((et) => Expanded(flex: 3, child: _buildExamTypeSummaryCell(et))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newSubjectController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: t(kNewSubjectHintMap),
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      filled: true, fillColor: _ThemeColors.premiumCardBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _ThemeColors.brandGolden.withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: _ThemeColors.brandGolden), borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _ThemeColors.brandGolden),
                  onPressed: _addCustomSubject,
                  child: Text(t(kAddSubjectBtnMap), style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(t(kSubjectOptionsHintMap), style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10.5)),
            const SizedBox(height: 24),

            Text(t(kChartSectionTitleMap), style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            _buildExamTypeChart(),
            const SizedBox(height: 24),

            Text(t(kSummaryTitleMap), style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _ThemeColors.premiumCardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.5), width: 1.4),
              ),
              child: _isSummaryLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: _ThemeColors.brandGolden)))
                  : Text(
                _summaryText ?? t(kSummaryPlaceholderMap),
                style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
