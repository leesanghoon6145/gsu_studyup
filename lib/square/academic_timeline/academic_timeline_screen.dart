import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart'; // 🆕 [백색소음 선택] 미리듣기 재생용
import 'dart:async'; // 🆕 [백색소음 선택] 미리듣기 자동정지 Timer용
import 'dart:convert'; // 🆕 [버그 수정 2026-07-29] 커스텀 시간표/시험기록 영구저장용
import '../../planner/widgets/study_timelines.dart';
import '../../timer/timer_screen.dart';
import '../global_lang.dart'; // 👑 [12개국 연동] 전역 언어 스위치와 연결

class AcademicTimelineScreen extends StatefulWidget {
  const AcademicTimelineScreen({super.key});

  @override
  State<AcademicTimelineScreen> createState() => _AcademicTimelineScreenState();
}

class _AcademicTimelineScreenState extends State<AcademicTimelineScreen> {
  // ============================================================
  // 색상 및 폰트 테마 (기존 앱과 통일)
  // ============================================================
  final Color goldColor = const Color(0xFFD4AF37);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color slate500 = const Color(0xFF64748B);
  final Color slate800 = const Color(0xFF1E293B);
  final Color darkGrey = const Color(0xFF333333);

  final List<Color> _rainbowColors = [
    Colors.red,
    Colors.blue,
    Colors.yellow,
    Colors.green,
    Colors.orange,
    Colors.indigo,
    Colors.purple,
  ];

  String _selectedTrack = 'PERSONAL_TIMETABLE'; // 🆕 [2026-07-29] 학사 타이머 진입 시 기본으로 개인 시간표 탭 선택

  // 1. 평상시
  String _selectedWeekdayEn = 'Monday';
  final List<Map<String, String>> _weekdayOptions = [
    {'en': 'Monday', 'ko': '월요일', 'abbr': 'Mon'},
    {'en': 'Tuesday', 'ko': '화요일', 'abbr': 'Tue'},
    {'en': 'Wednesday', 'ko': '수요일', 'abbr': 'Wed'},
    {'en': 'Thursday', 'ko': '목요일', 'abbr': 'Thu'},
    {'en': 'Friday', 'ko': '금요일', 'abbr': 'Fri'},
    {'en': 'Saturday', 'ko': '토요일', 'abbr': 'Sat'},
    {'en': 'Sunday', 'ko': '일요일', 'abbr': 'Sun'},
  ];
  bool _isNormalWeekdayExpanded = true;

  // 🆕 [개인 시간표 2026-07-29] 평상시와 동일한 구조의 "나만의 시간표" 탭 전용 상태
  String _selectedPersonalWeekdayEn = 'Monday';
  bool _isPersonalWeekdayExpanded = true;

  // 🆕 [개인 시간표 2026-07-29] 작성 형식을 보여주는 가이드용 샘플 2개 (실제 저장/실행 대상 아님)
  static const List<Map<String, String>> _personalScheduleGuideSamples = [
    {'time': '09:00 - 10:00', 'task': '수학 개념정리 (예시)'},
    {'time': '10:10 - 11:00', 'task': '영어 단어암기 (예시)'},
  ];

  // 2. 방학
  DateTime? _vacationStartDate;
  DateTime? _vacationEndDate;
  String? _selectedPomodoroKey;
  bool _isPomodoroFreeModeEnabled = false;
  bool _isVacationStyleExpanded = true;

  // 3 & 4. 시험 공통
  bool _isFinalExamMode = false;
  DateTime? _examStartDate;
  DateTime? _examEndDate; // [추가] 시험 종료일
  int? _manualExamPrepWeek; // [추가] 4/3/2주 수동 선택 (null=날짜 자동계산)
  bool _isExamSettingExpanded = true;
  bool _isExamDaySettingExpanded = true; // 🆕 [시험당일] EXAM INFO 접기/펴기 상태
  final List<Map<String, String>> _customExamRecords = [];

  final Map<String, List<Map<String, String>>> _customSchedules = {};
  int? _selectedScheduleIndex; // [추가] 사용자가 선택한 시간표 항목의 인덱스

  // ============================================================
  // 🆕 [백색소음 선택] "START TIMER" 팝업에서 선택하는 백색소음 목록.
  // home_dashboard_screen.dart와 동일한 asset 파일 및 디자인을 사용.
  // ============================================================
  String _selectedSoundFile = '';
  String _previewingSoundDisplayName = '';
  late AudioPlayer _previewAudioPlayer;
  Timer? _previewTimer;

  final List<Map<String, String>> _whiteNoiseSounds = [
    {'en': 'Crickets', 'ko': '귀뚜라미 소리', 'file': 'crickets.mp3'},
    {'en': 'Spring Morning', 'ko': '봄 아침소리', 'file': 'spring_morning.mp3'},
    {'en': 'Forest Birds', 'ko': '숲속의 새소리', 'file': 'forest_birds.mp3'},
    {'en': 'Cool Rain', 'ko': '시원한 빗소리', 'file': 'cool_rain.mp3'},
    {'en': 'Clear Stream', 'ko': '맑은 시냇물', 'file': 'clear_stream.mp3'},
    {'en': 'Blue Waves', 'ko': '푸른 파도소리', 'file': 'blue_waves.mp3'},
  ];

  // ============================================================================
  // 🆕 [12개국 언어 시스템] - learning_screen.dart / planning_screen.dart와 동일한 패턴
  // 기본값(KO/EN, 즉 10개국을 아직 선택 안 한 상태)은 항상 "영문 + 한글"이 함께 보입니다.
  // 한국어/영어를 "제외한" 나머지 10개국 중 하나를 선택했을 때만 그 언어 단독으로 전환됩니다.
  // ⚠️ 내부 데이터 키(_weekdayOptions의 'en' 값, SharedPreferences 캐시 키 등)는 절대 건드리지
  //    않고, "화면에 보여주는 문구"만 이 카탈로그를 거쳐서 표시합니다.
  // ============================================================================
  static const List<String> _foreignLanguages = ['JA', 'ZH', 'FR', 'DE', 'RU', 'AR', 'HI', 'VI', 'ES', 'TH'];
  static bool get _isForeignSelected => _foreignLanguages.contains(DkeLang.current);

  static const Map<String, Map<String, String>> _uiText = {
    'appBarTitle': {'KO': '학사 타이머', 'EN': 'ACADEMIC TIMER', 'JA': '学事タイマー', 'ZH': '学业计时器', 'FR': 'Minuteur académique', 'DE': 'Akademik-Timer', 'RU': 'Академический таймер', 'AR': 'المؤقت الأكاديمي', 'HI': 'एकेडमिक टाइमर', 'VI': 'Đồng hồ học tập', 'ES': 'Temporizador académico', 'TH': 'ตัวจับเวลาการเรียน'},

    'weekdayMonday': {'KO': '월요일', 'EN': 'Monday', 'JA': '月曜日', 'ZH': '星期一', 'FR': 'Lundi', 'DE': 'Montag', 'RU': 'Понедельник', 'AR': 'الإثنين', 'HI': 'सोमवार', 'VI': 'Thứ Hai', 'ES': 'Lunes', 'TH': 'วันจันทร์'},
    'weekdayTuesday': {'KO': '화요일', 'EN': 'Tuesday', 'JA': '火曜日', 'ZH': '星期二', 'FR': 'Mardi', 'DE': 'Dienstag', 'RU': 'Вторник', 'AR': 'الثلاثاء', 'HI': 'मंगलवार', 'VI': 'Thứ Ba', 'ES': 'Martes', 'TH': 'วันอังคาร'},
    'weekdayWednesday': {'KO': '수요일', 'EN': 'Wednesday', 'JA': '水曜日', 'ZH': '星期三', 'FR': 'Mercredi', 'DE': 'Mittwoch', 'RU': 'Среда', 'AR': 'الأربعاء', 'HI': 'बुधवार', 'VI': 'Thứ Tư', 'ES': 'Miércoles', 'TH': 'วันพุธ'},
    'weekdayThursday': {'KO': '목요일', 'EN': 'Thursday', 'JA': '木曜日', 'ZH': '星期四', 'FR': 'Jeudi', 'DE': 'Donnerstag', 'RU': 'Четверг', 'AR': 'الخميس', 'HI': 'गुरुवार', 'VI': 'Thứ Năm', 'ES': 'Jueves', 'TH': 'วันพฤหัสบดี'},
    'weekdayFriday': {'KO': '금요일', 'EN': 'Friday', 'JA': '金曜日', 'ZH': '星期五', 'FR': 'Vendredi', 'DE': 'Freitag', 'RU': 'Пятница', 'AR': 'الجمعة', 'HI': 'शुक्रवार', 'VI': 'Thứ Sáu', 'ES': 'Viernes', 'TH': 'วันศุกร์'},
    'weekdaySaturday': {'KO': '토요일', 'EN': 'Saturday', 'JA': '土曜日', 'ZH': '星期六', 'FR': 'Samedi', 'DE': 'Samstag', 'RU': 'Субота', 'AR': 'السبت', 'HI': 'शनिवार', 'VI': 'Thứ Bảy', 'ES': 'Sábado', 'TH': 'วันเสาร์'},
    'weekdaySunday': {'KO': '일요일', 'EN': 'Sunday', 'JA': '日曜日', 'ZH': '星期日', 'FR': 'Dimanche', 'DE': 'Sonntag', 'RU': 'Воскресенье', 'AR': 'الأحد', 'HI': 'रविवार', 'VI': 'Chủ Nhật', 'ES': 'Domingo', 'TH': 'วันอาทิตย์'},

    'tabNormal': {'KO': '평상시', 'EN': 'Normal', 'JA': '通常', 'ZH': '日常', 'FR': 'Normal', 'DE': 'Normal', 'RU': 'Обычный', 'AR': 'عادي', 'HI': 'सामान्य', 'VI': 'Bình thường', 'ES': 'Normal', 'TH': 'ปกติ'},
    'tabVacation': {'KO': '방학', 'EN': 'Vacation', 'JA': '休暇', 'ZH': '假期', 'FR': 'Vacances', 'DE': 'Ferien', 'RU': 'Каникулы', 'AR': 'العطلة', 'HI': 'छुट्टी', 'VI': 'Kỳ nghỉ', 'ES': 'Vacaciones', 'TH': 'วันหยุด'},
    'tabExamPrep': {'KO': '시험준비', 'EN': 'Exam Prep', 'JA': '試験準備', 'ZH': '备考', 'FR': 'Préparation Examen', 'DE': 'Prüfungsvorb.', 'RU': 'Подготовка к экз.', 'AR': 'التحضير للامتحان', 'HI': 'परीक्षा तैयारी', 'VI': 'Ôn thi', 'ES': 'Preparación Examen', 'TH': 'เตรียมสอบ'},
    'tabExamDay': {'KO': '시험당일', 'EN': 'Exam Day', 'JA': '試験当日', 'ZH': '考试日', 'FR': "Jour d'examen", 'DE': 'Prüfungstag', 'RU': 'День экзамена', 'AR': 'يوم الامتحان', 'HI': 'परीक्षा दिवस', 'VI': 'Ngày thi', 'ES': 'Día de Examen', 'TH': 'วันสอบ'},
    'tabPersonal': {'KO': '개인 시간표', 'EN': 'Personal', 'JA': '個人時間表', 'ZH': '个人时间表', 'FR': 'Emploi Personnel', 'DE': 'Persönl. Plan', 'RU': 'Личный график', 'AR': 'الجدول الشخصي', 'HI': 'व्यक्तिगत समय सारणी', 'VI': 'Thời gian biểu cá nhân', 'ES': 'Horario Personal', 'TH': 'ตารางส่วนตัว'},

    'normalTitleEn': {'KO': 'NORMAL PERIOD', 'EN': 'NORMAL PERIOD', 'JA': '通常期間', 'ZH': '日常时段', 'FR': 'PÉRIODE NORMALE', 'DE': 'NORMALE PERIODE', 'RU': 'ОБЫЧНЫЙ ПЕРИОД', 'AR': 'الفترة العادية', 'HI': 'सामान्य अवधि', 'VI': 'GIAI ĐOẠN BÌNH THƯỜNG', 'ES': 'PERÍODO NORMAL', 'TH': 'ช่วงเวลาปกติ'},
    'normalSubtitle': {'KO': '평상시 기본 타임라인 - 오늘 요일 자동', 'EN': "Normal default timeline - today's weekday auto-selected", 'JA': '通常の基本タイムライン - 今日の曜日を自動選択', 'ZH': '日常基础时间表 - 自动选择今天星期', 'FR': "Chronologie normale - jour actuel sélectionné automatiquement", 'DE': 'Normaler Standardzeitplan - heutiger Wochentag automatisch', 'RU': 'Обычное расписание - сегодняшний день недели авто', 'AR': 'الجدول الزمني الافتراضي - يتم تحديد يوم اليوم تلقائيًا', 'HI': 'सामान्य डिफ़ॉल्ट समयरेखा - आज का दिन स्वचालित रूप से चयनित', 'VI': 'Lịch trình mặc định - tự động chọn ngày hôm nay', 'ES': 'Cronología normal - día de hoy seleccionado automáticamente', 'TH': 'ไทม์ไลน์พื้นฐานปกติ - เลือกวันนี้อัตโนมัติ'},
    'selectWeekdayLabel': {'KO': '요일선택', 'EN': 'Select Weekday', 'JA': '曜日選択', 'ZH': '选择星期', 'FR': 'Choisir le jour', 'DE': 'Wochentag wählen', 'RU': 'Выбор дня недели', 'AR': 'اختر اليوم', 'HI': 'दिन चुनें', 'VI': 'Chọn thứ', 'ES': 'Elegir día', 'TH': 'เลือกวัน'},

    'personalTitleEn': {'KO': 'PERSONAL TIMETABLE', 'EN': 'PERSONAL TIMETABLE', 'JA': '個人時間表', 'ZH': '个人时间表', 'FR': 'EMPLOI DU TEMPS PERSONNEL', 'DE': 'PERSÖNLICHER STUNDENPLAN', 'RU': 'ЛИЧНОЕ РАСПИСАНИЕ', 'AR': 'الجدول الزمني الشخصي', 'HI': 'व्यक्तिगत समय सारणी', 'VI': 'THỜI GIAN BIỂU CÁ NHÂN', 'ES': 'HORARIO PERSONAL', 'TH': 'ตารางเวลาส่วนตัว'},
    'personalSubtitle': {'KO': '개인 시간표 - 나만의 시간표 직접 작성', 'EN': 'Personal timetable - create your own schedule', 'JA': '個人時間表 - 自分だけの時間表を作成', 'ZH': '个人时间表 - 自行制定专属时间表', 'FR': 'Emploi personnel - créez votre propre horaire', 'DE': 'Persönlicher Plan - eigenen Zeitplan erstellen', 'RU': 'Личное расписание - создайте свой график', 'AR': 'الجدول الشخصي - أنشئ جدولك الخاص', 'HI': 'व्यक्तिगत समय सारणी - अपनी समय सारणी बनाएं', 'VI': 'Thời gian biểu cá nhân - tự tạo lịch của riêng bạn', 'ES': 'Horario personal - crea tu propio horario', 'TH': 'ตารางส่วนตัว - สร้างตารางเวลาของคุณเอง'},
    'personalSampleLabel': {'KO': '작성 예시 (참고용, 저장되지 않음)', 'EN': 'SAMPLE (for reference only, not saved)', 'JA': '記入例（参考用、保存されません）', 'ZH': '填写示例（仅供参考，不会保存）', 'FR': "EXEMPLE (référence uniquement, non enregistré)", 'DE': 'BEISPIEL (nur zur Referenz, nicht gespeichert)', 'RU': 'ПРИМЕР (только для справки, не сохраняется)', 'AR': 'مثال (للمرجعية فقط، لا يتم الحفظ)', 'HI': 'उदाहरण (केवल संदर्भ के लिए, सहेजा नहीं गया)', 'VI': 'VÍ DỤ (chỉ để tham khảo, không lưu)', 'ES': 'EJEMPLO (solo referencia, no se guarda)', 'TH': 'ตัวอย่าง (สำหรับอ้างอิงเท่านั้น ไม่บันทึก)'},
    'personalOwnScheduleLabel': {'KO': '나만의 시간표 (아래에 직접 추가하세요)', 'EN': 'My own timetable (add items below)', 'JA': '自分だけの時間表（下に直接追加してください）', 'ZH': '我的专属时间表（请在下方添加）', 'FR': 'Mon propre horaire (ajoutez ci-dessous)', 'DE': 'Mein eigener Zeitplan (unten hinzufügen)', 'RU': 'Мой личный график (добавьте ниже)', 'AR': 'جدولي الخاص (أضف أدناه)', 'HI': 'मेरी अपनी समय सारणी (नीचे जोड़ें)', 'VI': 'Thời gian biểu của tôi (thêm bên dưới)', 'ES': 'Mi propio horario (agregar abajo)', 'TH': 'ตารางเวลาของฉัน (เพิ่มด้านล่าง)'},
    'personalGuideTitle': {'KO': '개인 시간표', 'EN': 'Personal Timetable', 'JA': '個人時間表', 'ZH': '个人时间表', 'FR': 'Emploi du temps personnel', 'DE': 'Persönlicher Stundenplan', 'RU': 'Личное расписание', 'AR': 'الجدول الزمني الشخصي', 'HI': 'व्यक्तिगत समय सारणी', 'VI': 'Thời gian biểu cá nhân', 'ES': 'Horario personal', 'TH': 'ตารางเวลาส่วนตัว'},
    'personalGuideBody': {
      'KO': '이 화면은 유저가 직접 학습할 시간과 과목 및 단원을 기록하여 저장한 뒤 사용할 곳입니다.\n\n위에 있는 예시 2개를 참고해서, 그 아래 빈 공간에 "+Add/항목 추가"로 원하는 시간표를 직접 작성해보세요.',
      'EN': 'This screen is where you record and save your own study times, subjects, and units to use.\n\nRefer to the 2 samples above, then use "+Add" below to write your own schedule.',
      'JA': 'この画面は、自分で学習する時間と科目・単元を記録して保存し、使用する場所です。\n\n上の2つの記入例を参考に、下の空欄に「+Add/項目追加」でご自身の時間表を作成してください。',
      'ZH': '此界面用于记录并保存您自己要学习的时间、科目和单元。\n\n请参考上方的2个示例，在下方空白处点击"+Add/添加项目"来编写您的时间表。',
      'FR': "Cet écran vous permet d'enregistrer vos propres horaires, matières et unités d'étude.\n\nConsultez les 2 exemples ci-dessus, puis utilisez « +Ajouter » ci-dessous pour créer votre horaire.",
      'DE': 'In diesem Bildschirm können Sie Ihre eigenen Lernzeiten, Fächer und Einheiten speichern und nutzen.\n\nSchauen Sie sich die 2 Beispiele oben an und nutzen Sie unten „+Hinzufügen", um Ihren eigenen Plan zu erstellen.',
      'RU': 'На этом экране вы можете записывать и сохранять собственное время учёбы, предметы и темы.\n\nПосмотрите 2 примера выше, затем используйте «+Добавить» ниже, чтобы составить свой график.',
      'AR': 'هذه الشاشة هي المكان الذي تسجل فيه وتحفظ أوقات دراستك ومواضيعك ووحداتك الخاصة لاستخدامها.\n\nراجع المثالين أعلاه، ثم استخدم "+إضافة" أدناه لكتابة جدولك الخاص.',
      'HI': 'यह स्क्रीन वह जगह है जहाँ आप अपने स्वयं के अध्ययन समय, विषय और इकाइयाँ दर्ज करके सहेजते हैं।\n\nऊपर दिए गए 2 उदाहरणों को देखें, फिर नीचे "+जोड़ें" का उपयोग करके अपनी समय सारणी लिखें।',
      'VI': 'Đây là nơi bạn ghi lại và lưu thời gian học, môn học và đơn vị bài học của riêng bạn.\n\nHãy xem 2 ví dụ ở trên, sau đó dùng "+Thêm" bên dưới để viết lịch của riêng bạn.',
      'ES': 'Esta pantalla es donde registras y guardas tus propios horarios de estudio, materias y unidades.\n\nConsulta los 2 ejemplos anteriores y usa "+Agregar" abajo para crear tu propio horario.',
      'TH': 'หน้าจอนี้ใช้สำหรับบันทึกและเก็บเวลาเรียน วิชา และหน่วยเรียนของคุณเอง\n\nดูตัวอย่างทั้ง 2 ด้านบน แล้วใช้ "+เพิ่ม" ด้านล่างเพื่อสร้างตารางของคุณเอง',
    },
    'okConfirmLabel': {'KO': '확인', 'EN': 'OK', 'JA': '確認', 'ZH': '确认', 'FR': 'OK', 'DE': 'OK', 'RU': 'ОК', 'AR': 'موافق', 'HI': 'ठीक है', 'VI': 'Đồng ý', 'ES': 'OK', 'TH': 'ตกลง'},

    'vacationTitleEn': {'KO': 'VACATION SUMMER/WINTER', 'EN': 'VACATION SUMMER/WINTER', 'JA': '休暇（夏・冬）', 'ZH': '假期（夏/冬）', 'FR': 'VACANCES ÉTÉ/HIVER', 'DE': 'FERIEN SOMMER/WINTER', 'RU': 'КАНИКУЛЫ ЛЕТО/ЗИМА', 'AR': 'عطلة الصيف/الشتاء', 'HI': 'छुट्टी गर्मी/सर्दी', 'VI': 'NGHỈ HÈ/ĐÔNG', 'ES': 'VACACIONES VERANO/INVIERNO', 'TH': 'วันหยุดฤดูร้อน/หนาว'},
    'vacationSubtitle': {'KO': '방학 포모도로 타임라인 - 기간 및 스타일 설정', 'EN': 'Vacation Pomodoro timeline - set period and style', 'JA': '休暇ポモドーロタイムライン - 期間とスタイルを設定', 'ZH': '假期番茄钟时间表 - 设置期间和样式', 'FR': "Chronologie Pomodoro de vacances - définir période et style", 'DE': 'Ferien-Pomodoro-Zeitplan - Zeitraum und Stil einstellen', 'RU': 'Расписание Pomodoro на каникулах - настройка периода и стиля', 'AR': 'الجدول الزمني لبومودورو العطلة - تحديد الفترة والنمط', 'HI': 'छुट्टी पोमोडोरो समयरेखा - अवधि और स्टाइल सेट करें', 'VI': 'Lịch trình Pomodoro kỳ nghỉ - đặt thời gian và kiểu', 'ES': 'Cronología Pomodoro de vacaciones - configurar período y estilo', 'TH': 'ไทม์ไลน์โปโมโดโรวันหยุด - ตั้งค่าช่วงเวลาและสไตล์'},
    'vacationPeriodLabel': {'KO': '방학 기간', 'EN': 'VACATION PERIOD', 'JA': '休暇期間', 'ZH': '假期时段', 'FR': 'PÉRIODE DE VACANCES', 'DE': 'FERIENZEITRAUM', 'RU': 'ПЕРИОД КАНИКУЛ', 'AR': 'فترة العطلة', 'HI': 'छुट्टी की अवधि', 'VI': 'THỜI GIAN NGHỈ', 'ES': 'PERÍODO DE VACACIONES', 'TH': 'ช่วงวันหยุด'},
    'startDateSelect': {'KO': '시작일 선택', 'EN': 'Select Start Date', 'JA': '開始日を選択', 'ZH': '选择开始日期', 'FR': 'Choisir la date de début', 'DE': 'Startdatum wählen', 'RU': 'Выбрать дату начала', 'AR': 'اختر تاريخ البدء', 'HI': 'प्रारंभ तिथि चुनें', 'VI': 'Chọn ngày bắt đầu', 'ES': 'Seleccionar fecha de inicio', 'TH': 'เลือกวันเริ่มต้น'},
    'endDateSelect': {'KO': '종료일 선택', 'EN': 'Select End Date', 'JA': '終了日を選択', 'ZH': '选择结束日期', 'FR': 'Choisir la date de fin', 'DE': 'Enddatum wählen', 'RU': 'Выбрать дату окончания', 'AR': 'اختر تاريخ الانتهاء', 'HI': 'समाप्ति तिथि चुनें', 'VI': 'Chọn ngày kết thúc', 'ES': 'Seleccionar fecha de fin', 'TH': 'เลือกวันสิ้นสุด'},
    'pomodoroStyleTitleEn': {'KO': 'POMODORO STYLE', 'EN': 'POMODORO STYLE', 'JA': 'ポモドーロスタイル', 'ZH': '番茄钟样式', 'FR': 'STYLE POMODORO', 'DE': 'POMODORO-STIL', 'RU': 'СТИЛЬ POMODORO', 'AR': 'نمط بومودورو', 'HI': 'पोमोडोरो स्टाइल', 'VI': 'KIỂU POMODORO', 'ES': 'ESTILO POMODORO', 'TH': 'สไตล์โปโมโดโร'},
    'pomodoroStyleSubtitle': {'KO': '포모도로 스타일 (직접 선택)', 'EN': 'Pomodoro style (choose manually)', 'JA': 'ポモドーロスタイル（直接選択）', 'ZH': '番茄钟样式（自行选择）', 'FR': 'Style Pomodoro (choix manuel)', 'DE': 'Pomodoro-Stil (manuell wählen)', 'RU': 'Стиль Pomodoro (выбор вручную)', 'AR': 'نمط بومودورو (اختيار يدوي)', 'HI': 'पोमोडोरो स्टाइल (मैन्युअल चयन)', 'VI': 'Kiểu Pomodoro (chọn thủ công)', 'ES': 'Estilo Pomodoro (elección manual)', 'TH': 'สไตล์โปโมโดโร (เลือกเอง)'},
    'pomodoroHint': {'KO': '스타일마다 구성이 달라 자동 전환하지 않습니다. 원하는 스타일을 직접 골라주세요.', 'EN': 'Each style is structured differently, so it does not auto-switch. Please choose your preferred style.', 'JA': 'スタイルごとに構成が異なるため自動切替はしません。ご希望のスタイルを選んでください。', 'ZH': '每种样式结构不同，不会自动切换，请自行选择所需样式。', 'FR': "Chaque style est structuré différemment et ne change pas automatiquement. Choisissez votre style.", 'DE': 'Jeder Stil ist unterschiedlich aufgebaut und wechselt nicht automatisch. Bitte wählen Sie Ihren Stil.', 'RU': 'Каждый стиль устроен по-разному и не переключается автоматически. Пожалуйста, выберите стиль вручную.', 'AR': 'يختلف تكوين كل نمط، فلا يتم التبديل تلقائيًا. يرجى اختيار النمط المطلوب.', 'HI': 'हर स्टाइल की संरचना अलग होती है, इसलिए यह स्वचालित रूप से नहीं बदलता। कृपया अपनी पसंद की स्टाइल चुनें।', 'VI': 'Mỗi kiểu có cấu trúc khác nhau nên không tự động chuyển. Vui lòng chọn kiểu bạn muốn.', 'ES': 'Cada estilo tiene una estructura diferente, por lo que no cambia automáticamente. Elige tu estilo preferido.', 'TH': 'แต่ละสไตล์มีโครงสร้างต่างกัน จึงไม่สลับอัตโนมัติ กรุณาเลือกสไตล์ที่ต้องการเอง'},
    'pomodoroFreeMode': {'KO': '평일에도 이 스타일 자유롭게 사용', 'EN': 'Use this style freely on weekdays too', 'JA': '平日でもこのスタイルを自由に使用', 'ZH': '平日也可自由使用此样式', 'FR': 'Utiliser ce style librement aussi en semaine', 'DE': 'Diesen Stil auch werktags frei nutzen', 'RU': 'Использовать этот стиль свободно и в будни', 'AR': 'استخدم هذا النمط بحرية أيضًا في أيام الأسبوع', 'HI': 'सप्ताह के दिनों में भी इस स्टाइल का स्वतंत्र रूप से उपयोग करें', 'VI': 'Sử dụng kiểu này tự do cả vào ngày thường', 'ES': 'Usar este estilo libremente también en días de semana', 'TH': 'ใช้สไตล์นี้ได้อย่างอิสระในวันธรรมดาด้วย'},
    'pomodoroStyle1': {'KO': '스타일 1 (초집중 25분형)', 'EN': 'Style 1 (Ultra Focus 25m)', 'JA': 'スタイル1（超集中25分型）', 'ZH': '样式1（超集中25分钟型）', 'FR': 'Style 1 (Ultra Focus 25 min)', 'DE': 'Stil 1 (Ultrafokus 25 Min)', 'RU': 'Стиль 1 (Ультрафокус 25 мин)', 'AR': 'النمط 1 (تركيز فائق 25 دقيقة)', 'HI': 'स्टाइल 1 (अल्ट्रा फोकस 25 मिनट)', 'VI': 'Kiểu 1 (Siêu tập trung 25 phút)', 'ES': 'Estilo 1 (Enfoque ultra 25 min)', 'TH': 'สไตล์ 1 (โฟกัสสุดขีด 25 นาที)'},
    'pomodoroStyle2': {'KO': '스타일 2 (집중 40분형)', 'EN': 'Style 2 (Focus 40m)', 'JA': 'スタイル2（集中40分型）', 'ZH': '样式2（集中40分钟型）', 'FR': 'Style 2 (Focus 40 min)', 'DE': 'Stil 2 (Fokus 40 Min)', 'RU': 'Стиль 2 (Фокус 40 мин)', 'AR': 'النمط 2 (تركيز 40 دقيقة)', 'HI': 'स्टाइल 2 (फोकस 40 मिनट)', 'VI': 'Kiểu 2 (Tập trung 40 phút)', 'ES': 'Estilo 2 (Enfoque 40 min)', 'TH': 'สไตล์ 2 (โฟกัส 40 นาที)'},
    'pomodoroStyle3': {'KO': '스타일 3 (과목별 45분형)', 'EN': 'Style 3 (Subject 45m)', 'JA': 'スタイル3（科目別45分型）', 'ZH': '样式3（分科45分钟型）', 'FR': 'Style 3 (Matière 45 min)', 'DE': 'Stil 3 (Fach 45 Min)', 'RU': 'Стиль 3 (По предметам 45 мин)', 'AR': 'النمط 3 (حسب المادة 45 دقيقة)', 'HI': 'स्टाइल 3 (विषयवार 45 मिनट)', 'VI': 'Kiểu 3 (Theo môn 45 phút)', 'ES': 'Estilo 3 (Por materia 45 min)', 'TH': 'สไตล์ 3 (แยกวิชา 45 นาที)'},
    'pomodoroStyle4': {'KO': '스타일 4 (집중 60분형)', 'EN': 'Style 4 (Focus 60m)', 'JA': 'スタイル4（集中60分型）', 'ZH': '样式4（集中60分钟型）', 'FR': 'Style 4 (Focus 60 min)', 'DE': 'Stil 4 (Fokus 60 Min)', 'RU': 'Стиль 4 (Фокус 60 мин)', 'AR': 'النمط 4 (تركيز 60 دقيقة)', 'HI': 'स्टाइल 4 (फोकस 60 मिनट)', 'VI': 'Kiểu 4 (Tập trung 60 phút)', 'ES': 'Estilo 4 (Enfoque 60 min)', 'TH': 'สไตล์ 4 (โฟกัส 60 นาที)'},
    'pomodoroNotSelected': {'KO': '미선택', 'EN': 'Not Selected', 'JA': '未選択', 'ZH': '未选择', 'FR': 'Non sélectionné', 'DE': 'Nicht ausgewählt', 'RU': 'Не выбрано', 'AR': 'غير محدد', 'HI': 'अचयनित', 'VI': 'Chưa chọn', 'ES': 'No seleccionado', 'TH': 'ยังไม่เลือก'},
    'noPomodoroSelected': {'KO': '선택된 포모도로 스타일이 없습니다. 위에서 스타일을 선택해주세요.', 'EN': 'No Pomodoro style selected. Please choose a style above.', 'JA': '選択されたポモドーロスタイルがありません。上でスタイルを選択してください。', 'ZH': '未选择番茄钟样式，请在上方选择样式。', 'FR': "Aucun style Pomodoro sélectionné. Choisissez un style ci-dessus.", 'DE': 'Kein Pomodoro-Stil ausgewählt. Bitte wählen Sie oben einen Stil.', 'RU': 'Стиль Pomodoro не выбран. Пожалуйста, выберите стиль выше.', 'AR': 'لم يتم اختيار نمط بومودورو. يرجى اختيار نمط أعلاه.', 'HI': 'कोई पोमोडोरो स्टाइल चयनित नहीं है। कृपया ऊपर एक स्टाइल चुनें।', 'VI': 'Chưa chọn kiểu Pomodoro. Vui lòng chọn kiểu ở trên.', 'ES': 'No se seleccionó ningún estilo Pomodoro. Elige un estilo arriba.', 'TH': 'ยังไม่ได้เลือกสไตล์โปโมโดโร กรุณาเลือกสไตล์ด้านบน'},

    'examPrepTitleEn': {'KO': 'EXAM PREP PERIOD', 'EN': 'EXAM PREP PERIOD', 'JA': '試験準備期間', 'ZH': '备考期间', 'FR': "PÉRIODE DE PRÉPARATION À L'EXAMEN", 'DE': 'PRÜFUNGSVORBEREITUNGSZEIT', 'RU': 'ПЕРИОД ПОДГОТОВКИ К ЭКЗАМЕНУ', 'AR': 'فترة التحضير للامتحان', 'HI': 'परीक्षा तैयारी अवधि', 'VI': 'GIAI ĐOẠN ÔN THI', 'ES': 'PERÍODO DE PREPARACIÓN DEL EXAMEN', 'TH': 'ช่วงเตรียมสอบ'},
    'examPrepSubtitle': {'KO': '시험 준비 타임라인 - 시험 정보 및 날짜별 자동 연동', 'EN': 'Exam prep timeline - auto-linked with exam info and date', 'JA': '試験準備タイムライン - 試験情報と日付に自動連動', 'ZH': '备考时间表 - 与考试信息及日期自动联动', 'FR': "Chronologie de préparation - liée automatiquement aux infos et à la date d'examen", 'DE': 'Prüfungsvorbereitungszeitplan - automatisch mit Prüfungsinfo und Datum verknüpft', 'RU': 'Расписание подготовки - авто-связь с информацией и датой экзамена', 'AR': 'الجدول الزمني للتحضير - مرتبط تلقائيًا بمعلومات الامتحان والتاريخ', 'HI': 'परीक्षा तैयारी समयरेखा - परीक्षा जानकारी व तिथि से स्वचालित रूप से जुड़ी', 'VI': 'Lịch trình ôn thi - tự động liên kết với thông tin và ngày thi', 'ES': 'Cronología de preparación - vinculada automáticamente con info y fecha del examen', 'TH': 'ไทม์ไลน์เตรียมสอบ - เชื่อมโยงอัตโนมัติกับข้อมูลและวันสอบ'},
    'examInfoSettingTitle': {'KO': '시험 정보 설정', 'EN': 'EXAM INFO', 'JA': '試験情報設定', 'ZH': '考试信息设置', 'FR': "INFOS D'EXAMEN", 'DE': 'PRÜFUNGSINFO', 'RU': 'ИНФОРМАЦИЯ ОБ ЭКЗАМЕНЕ', 'AR': 'معلومات الامتحان', 'HI': 'परीक्षा जानकारी', 'VI': 'THÔNG TIN KỲ THI', 'ES': 'INFO DEL EXAMEN', 'TH': 'ข้อมูลการสอบ'},
    'examInfoInputTitle': {'KO': '시험 정보 입력', 'EN': 'EXAM INFO', 'JA': '試験情報入力', 'ZH': '考试信息输入', 'FR': "SAISIR INFOS D'EXAMEN", 'DE': 'PRÜFUNGSINFO EINGEBEN', 'RU': 'ВВОД ИНФОРМАЦИИ ОБ ЭКЗАМЕНЕ', 'AR': 'إدخال معلومات الامتحان', 'HI': 'परीक्षा जानकारी दर्ज करें', 'VI': 'NHẬP THÔNG TIN KỲ THI', 'ES': 'INGRESAR INFO DEL EXAMEN', 'TH': 'กรอกข้อมูลการสอบ'},
    'radioMidterm': {'KO': '중간고사', 'EN': 'Midterm Exam', 'JA': '中間試験', 'ZH': '期中考试', 'FR': "Examen de mi-parcours", 'DE': 'Zwischenprüfung', 'RU': 'Промежуточный экзамен', 'AR': 'امتحان نصف الفصل', 'HI': 'मध्यावधि परीक्षा', 'VI': 'Thi giữa kỳ', 'ES': 'Examen parcial', 'TH': 'สอบกลางภาค'},
    'radioFinal': {'KO': '기말고사', 'EN': 'Final Exam', 'JA': '期末試験', 'ZH': '期末考试', 'FR': 'Examen final', 'DE': 'Abschlussprüfung', 'RU': 'Итоговый экзамен', 'AR': 'الامتحان النهائي', 'HI': 'अंतिम परीक्षा', 'VI': 'Thi cuối kỳ', 'ES': 'Examen final', 'TH': 'สอบปลายภาค'},
    'weeksBeforeSuffix': {'KO': '주 전', 'EN': 'Weeks Before', 'JA': '週間前', 'ZH': '周前', 'FR': 'semaines avant', 'DE': 'Wochen vorher', 'RU': 'недели до', 'AR': 'أسابيع قبل', 'HI': 'सप्ताह पहले', 'VI': 'tuần trước', 'ES': 'semanas antes', 'TH': 'สัปดาห์ก่อน'},
    'examPrepGuidance': {'KO': '선택 시 날짜와 무관하게 해당 주차 시간표를 미리 봅니다. 다시 누르면 해제(자동계산으로 복귀).', 'EN': "Selecting this previews that week's schedule regardless of date. Tap again to deselect (returns to auto-calculation).", 'JA': '選択すると日付にかかわらず該当週のスケジュールを事前確認できます。再度タップで解除（自動計算に戻る）。', 'ZH': '选择后无论日期都可预览该周的时间表。再次点击可取消（恢复自动计算）。', 'FR': "En sélectionnant, vous prévisualisez le planning de cette semaine, quelle que soit la date. Appuyez à nouveau pour désélectionner (retour au calcul automatique).", 'DE': 'Bei Auswahl wird der Zeitplan dieser Woche unabhängig vom Datum angezeigt. Erneut tippen zum Abwählen (zurück zur automatischen Berechnung).', 'RU': 'При выборе показывается расписание этой недели независимо от даты. Нажмите снова, чтобы снять выбор (вернуться к автоматическому расчёту).', 'AR': 'عند التحديد، تتم معاينة جدول هذا الأسبوع بغض النظر عن التاريخ. اضغط مرة أخرى لإلغاء التحديد (العودة إلى الحساب التلقائي).', 'HI': 'चयन करने पर तिथि की परवाह किए बिना उस सप्ताह की समय सारणी दिखेगी। फिर से टैप करने पर चयन रद्द होगा (स्वचालित गणना पर वापसी)।', 'VI': 'Khi chọn, lịch trình của tuần đó sẽ hiện ra bất kể ngày. Nhấn lại để bỏ chọn (quay lại tính tự động).', 'ES': 'Al seleccionar, se previsualiza el horario de esa semana sin importar la fecha. Toca de nuevo para deseleccionar (vuelve al cálculo automático).', 'TH': 'เมื่อเลือก จะแสดงตารางของสัปดาห์นั้นโดยไม่คำนึงถึงวันที่ แตะอีกครั้งเพื่อยกเลิก (กลับไปคำนวณอัตโนมัติ)'},
    'examPrepManualWarning': {'KO': '수동 미리보기 중입니다 (오늘 날짜 자동계산 아님)', 'EN': 'Manual preview in progress (not auto-calculated from today)', 'JA': '手動プレビュー中です（本日の日付からの自動計算ではありません）', 'ZH': '正在手动预览（非今日日期自动计算）', 'FR': "Aperçu manuel en cours (non calculé automatiquement à partir d'aujourd'hui)", 'DE': 'Manuelle Vorschau aktiv (nicht automatisch aus heutigem Datum berechnet)', 'RU': 'Ручной предпросмотр активен (не рассчитывается автоматически от сегодняшней даты)', 'AR': 'المعاينة اليدوية قيد التشغيل (ليست محسوبة تلقائيًا من تاريخ اليوم)', 'HI': 'मैनुअल पूर्वावलोकन जारी है (आज की तिथि से स्वचालित गणना नहीं)', 'VI': 'Đang xem trước thủ công (không tự động tính từ ngày hôm nay)', 'ES': 'Vista previa manual en curso (no calculado automáticamente desde hoy)', 'TH': 'กำลังแสดงตัวอย่างแบบเลือกเอง (ไม่ได้คำนวณอัตโนมัติจากวันนี้)'},
    'addExamRecordBtnEn': {'KO': '시험 과목 및 범위 기록 추가 (연속 입력)', 'EN': 'Add Exam Subject & Scope (Continuous Entry)', 'JA': '試験科目・範囲の記録を追加（連続入力）', 'ZH': '添加考试科目及范围记录（连续输入）', 'FR': "Ajouter matière/portée d'examen (saisie continue)", 'DE': 'Prüfungsfach & Umfang hinzufügen (fortlaufende Eingabe)', 'RU': 'Добавить предмет и объём экзамена (непрерывный ввод)', 'AR': 'إضافة مادة ونطاق الامتحان (إدخال متتابع)', 'HI': 'परीक्षा विषय एवं दायरा जोड़ें (निरंतर प्रविष्टि)', 'VI': 'Thêm môn thi & phạm vi (nhập liên tục)', 'ES': 'Agregar materia y alcance del examen (entrada continua)', 'TH': 'เพิ่มวิชาสอบและขอบเขต (กรอกต่อเนื่อง)'},
    'registeredExamRecordsLabel': {'KO': '등록된 시험 과목 및 범위', 'EN': 'Registered exam subjects & scope', 'JA': '登録済みの試験科目・範囲', 'ZH': '已注册的考试科目及范围', 'FR': "Matières/portées d'examen enregistrées", 'DE': 'Registrierte Prüfungsfächer & Umfang', 'RU': 'Зарегистрированные предметы и объём экзамена', 'AR': 'مواد ونطاق الامتحان المسجلة', 'HI': 'दर्ज परीक्षा विषय और दायरा', 'VI': 'Môn thi & phạm vi đã đăng ký', 'ES': 'Materias y alcance registrados', 'TH': 'วิชาสอบและขอบเขตที่บันทึกไว้'},
    'rangeLabel': {'KO': '범위', 'EN': 'Scope', 'JA': '範囲', 'ZH': '范围', 'FR': 'Portée', 'DE': 'Umfang', 'RU': 'Объём', 'AR': 'النطاق', 'HI': 'दायरा', 'VI': 'Phạm vi', 'ES': 'Alcance', 'TH': 'ขอบเขต'},

    'examDayTitleEn': {'KO': 'EXAM DAY TRACK', 'EN': 'EXAM DAY TRACK', 'JA': '試験当日トラック', 'ZH': '考试日轨道', 'FR': "PARCOURS JOUR D'EXAMEN", 'DE': 'PRÜFUNGSTAG-ABLAUF', 'RU': 'ТРЕК ДНЯ ЭКЗАМЕНА', 'AR': 'مسار يوم الامتحان', 'HI': 'परीक्षा दिवस ट्रैक', 'VI': 'LỘ TRÌNH NGÀY THI', 'ES': 'PISTA DEL DÍA DE EXAMEN', 'TH': 'แทร็กวันสอบ'},
    'examDaySubtitle': {'KO': '시험 당일 D-day 타임라인 - 자동 계산', 'EN': 'Exam day D-day timeline - auto-calculated', 'JA': '試験当日D-dayタイムライン - 自動計算', 'ZH': '考试当天D-day时间表 - 自动计算', 'FR': "Chronologie D-day du jour d'examen - calculée automatiquement", 'DE': 'Prüfungstag D-Day-Zeitplan - automatisch berechnet', 'RU': 'Расписание D-day дня экзамена - автоматический расчёт', 'AR': 'الجدول الزمني D-day ليوم الامتحان - محسوب تلقائيًا', 'HI': 'परीक्षा दिवस D-day समयरेखा - स्वचालित गणना', 'VI': 'Lịch trình D-day ngày thi - tính toán tự động', 'ES': 'Cronología D-day del día de examen - calculada automáticamente', 'TH': 'ไทม์ไลน์ D-day วันสอบ - คำนวณอัตโนมัติ'},
    'examDayNoStartDate': {'KO': '시험 시작일을 입력하면 D-3 ~ D+4 구간의 정확한 트랙이 자동으로 표시됩니다.', 'EN': 'Once you enter the exam start date, the exact D-3 ~ D+4 track will be shown automatically.', 'JA': '試験開始日を入力すると、D-3〜D+4の正確なトラックが自動的に表示されます。', 'ZH': '输入考试开始日期后，将自动显示D-3至D+4区间的精确轨道。', 'FR': "Une fois la date de début saisie, le parcours exact D-3 à D+4 s'affichera automatiquement.", 'DE': 'Nach Eingabe des Prüfungsstartdatums wird der genaue D-3- bis D+4-Ablauf automatisch angezeigt.', 'RU': 'После указания даты начала экзамена автоматически появится точный трек D-3 ~ D+4.', 'AR': 'بعد إدخال تاريخ بدء الامتحان، سيتم عرض المسار الدقيق من D-3 إلى D+4 تلقائيًا.', 'HI': 'परीक्षा प्रारंभ तिथि दर्ज करने पर D-3 से D+4 तक का सटीक ट्रैक स्वचालित रूप से दिखाई देगा।', 'VI': 'Khi nhập ngày bắt đầu thi, lộ trình chính xác D-3 ~ D+4 sẽ tự động hiển thị.', 'ES': 'Al ingresar la fecha de inicio del examen, se mostrará automáticamente la pista exacta D-3 a D+4.', 'TH': 'เมื่อกรอกวันเริ่มสอบ ระบบจะแสดงแทร็กช่วง D-3 ถึง D+4 ที่ถูกต้องโดยอัตโนมัติ'},
    'examDayOutOfRangePrefix': {'KO': '오늘은 시험 당일 트랙 구간(D-3 ~ D+4)이 아닙니다. 현재 기준', 'EN': "Today is outside the exam day track range (D-3 ~ D+4). Currently", 'JA': '本日は試験当日トラック区間（D-3〜D+4）ではありません。現在', 'ZH': '今天不在考试当天轨道区间（D-3~D+4）内。当前为', 'FR': "Aujourd'hui n'est pas dans la plage du parcours (D-3 ~ D+4). Actuellement", 'DE': 'Heute liegt nicht im Prüfungstag-Ablaufbereich (D-3 ~ D+4). Aktuell', 'RU': 'Сегодня выходит за диапазон трека дня экзамена (D-3 ~ D+4). Сейчас', 'AR': 'اليوم ليس ضمن نطاق مسار يوم الامتحان (D-3 ~ D+4). حاليًا', 'HI': 'आज परीक्षा दिवस ट्रैक की सीमा (D-3 ~ D+4) में नहीं है। वर्तमान में', 'VI': 'Hôm nay không thuộc phạm vi lộ trình ngày thi (D-3 ~ D+4). Hiện tại', 'ES': 'Hoy está fuera del rango de la pista del día de examen (D-3 ~ D+4). Actualmente', 'TH': 'วันนี้ไม่อยู่ในช่วงแทร็กวันสอบ (D-3 ~ D+4) ขณะนี้'},
    'examDayIsSuffix': {'KO': '입니다.', 'EN': '.', 'JA': 'です。', 'ZH': '。', 'FR': '.', 'DE': '.', 'RU': '.', 'AR': '.', 'HI': 'है।', 'VI': '.', 'ES': '.', 'TH': ''},
    'prepTimelineSuffix': {'KO': '준비 타임라인', 'EN': 'Prep Timeline', 'JA': '準備タイムライン', 'ZH': '备考时间表', 'FR': 'chronologie de préparation', 'DE': 'Vorbereitungszeitplan', 'RU': 'расписание подготовки', 'AR': 'الجدول الزمني للتحضير', 'HI': 'तैयारी समयरेखा', 'VI': 'lịch trình ôn thi', 'ES': 'cronología de preparación', 'TH': 'ไทม์ไลน์เตรียมสอบ'},
    'examEndedNormalEn': {'KO': '평상시 시간표 (시험 종료)', 'EN': 'Normal Period (Exam Ended)', 'JA': '通常時間表（試験終了）', 'ZH': '日常时间表（考试结束）', 'FR': 'Période normale (examen terminé)', 'DE': 'Normale Periode (Prüfung beendet)', 'RU': 'Обычный период (экзамен завершён)', 'AR': 'الفترة العادية (انتهى الامتحان)', 'HI': 'सामान्य अवधि (परीक्षा समाप्त)', 'VI': 'Giai đoạn bình thường (đã hết kỳ thi)', 'ES': 'Período normal (examen finalizado)', 'TH': 'ช่วงเวลาปกติ (สอบเสร็จแล้ว)'},

    'examDayNoStartDate2': {'KO': '시험 시작일(D-day) 선택', 'EN': 'Select Exam Start Date (D-day)', 'JA': '試験開始日（D-day）を選択', 'ZH': '选择考试开始日期（D-day）', 'FR': "Sélectionner la date de début (D-day)", 'DE': 'Prüfungsstartdatum wählen (D-Day)', 'RU': 'Выбрать дату начала экзамена (D-day)', 'AR': 'اختر تاريخ بدء الامتحان (D-day)', 'HI': 'परीक्षा प्रारंभ तिथि चुनें (D-day)', 'VI': 'Chọn ngày bắt đầu thi (D-day)', 'ES': 'Seleccionar fecha de inicio (D-day)', 'TH': 'เลือกวันเริ่มสอบ (D-day)'},
    'examDayStartDatePrefix': {'KO': '시험 시작일', 'EN': 'Exam Start Date', 'JA': '試験開始日', 'ZH': '考试开始日期', 'FR': "Date de début d'examen", 'DE': 'Prüfungsstartdatum', 'RU': 'Дата начала экзамена', 'AR': 'تاريخ بدء الامتحان', 'HI': 'परीक्षा प्रारंभ तिथि', 'VI': 'Ngày bắt đầu thi', 'ES': 'Fecha de inicio del examen', 'TH': 'วันเริ่มสอบ'},
    'dayTrackSuffix': {'KO': '시험 당일 트랙', 'EN': 'Exam Day Track', 'JA': '試験当日トラック', 'ZH': '考试日轨道', 'FR': "parcours du jour d'examen", 'DE': 'Prüfungstag-Ablauf', 'RU': 'трек дня экзамена', 'AR': 'مسار يوم الامتحان', 'HI': 'परीक्षा दिवस ट्रैक', 'VI': 'lộ trình ngày thi', 'ES': 'pista del día de examen', 'TH': 'แทร็กวันสอบ'},
    'addBtnLabel': {'KO': '항목 추가', 'EN': 'Add', 'JA': '項目追加', 'ZH': '添加项目', 'FR': 'Ajouter', 'DE': 'Hinzufügen', 'RU': 'Добавить', 'AR': 'إضافة', 'HI': 'जोड़ें', 'VI': 'Thêm', 'ES': 'Agregar', 'TH': 'เพิ่ม'},
    'editedBadge': {'KO': '편집됨', 'EN': 'Edited', 'JA': '編集済み', 'ZH': '已编辑', 'FR': 'Modifié', 'DE': 'Bearbeitet', 'RU': 'Изменено', 'AR': 'تم التعديل', 'HI': 'संपादित', 'VI': 'Đã sửa', 'ES': 'Editado', 'TH': 'แก้ไขแล้ว'},
    'resetBtn': {'KO': '리셋', 'EN': 'Reset', 'JA': 'リセット', 'ZH': '重置', 'FR': 'Réinit.', 'DE': 'Zurücksetzen', 'RU': 'Сброс', 'AR': 'إعادة تعيين', 'HI': 'रीसेट', 'VI': 'Đặt lại', 'ES': 'Restablecer', 'TH': 'รีเซ็ต'},
    'noDataAvailable': {'KO': '표시할 데이터가 없습니다.', 'EN': 'No data available.', 'JA': '表示するデータがありません。', 'ZH': '没有可显示的数据。', 'FR': 'Aucune donnée disponible.', 'DE': 'Keine Daten verfügbar.', 'RU': 'Нет данных для отображения.', 'AR': 'لا توجد بيانات متاحة.', 'HI': 'दिखाने के लिए कोई डेटा नहीं है।', 'VI': 'Không có dữ liệu để hiển thị.', 'ES': 'No hay datos disponibles.', 'TH': 'ไม่มีข้อมูลที่จะแสดง'},

    'resetDialogTitleEn': {'KO': '원본 리셋', 'EN': 'Reset', 'JA': 'リセット', 'ZH': '重置', 'FR': 'Réinitialiser', 'DE': 'Zurücksetzen', 'RU': 'Сброс', 'AR': 'إعادة تعيين', 'HI': 'रीसेट', 'VI': 'Đặt lại', 'ES': 'Restablecer', 'TH': 'รีเซ็ต'},
    'resetDialogBody': {'KO': '현재 화면의 타임라인을 원본 기본 데이터로 초기화하시겠습니까?', 'EN': "Reset this screen's timeline to the original default data?", 'JA': '現在の画面のタイムラインを元の基本データにリセットしますか？', 'ZH': '要将当前屏幕的时间表重置为原始默认数据吗？', 'FR': "Réinitialiser la chronologie de cet écran aux données par défaut ?", 'DE': 'Zeitplan dieses Bildschirms auf die ursprünglichen Standarddaten zurücksetzen?', 'RU': 'Сбросить расписание этого экрана к исходным данным по умолчанию?', 'AR': 'هل تريد إعادة تعيين الجدول الزمني لهذه الشاشة إلى البيانات الافتراضية الأصلية؟', 'HI': 'क्या इस स्क्रीन की समयरेखा को मूल डिफ़ॉल्ट डेटा पर रीसेट करना चाहते हैं?', 'VI': 'Đặt lại lịch trình của màn hình này về dữ liệu mặc định gốc?', 'ES': '¿Restablecer la cronología de esta pantalla a los datos originales predeterminados?', 'TH': 'ต้องการรีเซ็ตไทม์ไลน์ของหน้านี้กลับไปเป็นข้อมูลเริ่มต้นหรือไม่?'},
    'cancelBtn': {'KO': '취소', 'EN': 'Cancel', 'JA': 'キャンセル', 'ZH': '取消', 'FR': 'Annuler', 'DE': 'Abbrechen', 'RU': 'Отмена', 'AR': 'إلغاء', 'HI': 'रद्द करें', 'VI': 'Hủy', 'ES': 'Cancelar', 'TH': 'ยกเลิก'},
    'confirmResetBtn': {'KO': '리셋 확인', 'EN': 'Confirm Reset', 'JA': 'リセット確認', 'ZH': '确认重置', 'FR': 'Confirmer', 'DE': 'Bestätigen', 'RU': 'Подтвердить', 'AR': 'تأكيد', 'HI': 'पुष्टि करें', 'VI': 'Xác nhận', 'ES': 'Confirmar', 'TH': 'ยืนยันรีเซ็ต'},

    'startTimerTitleEn': {'KO': '타이머 시작', 'EN': 'START TIMER', 'JA': 'タイマー開始', 'ZH': '开始计时器', 'FR': 'DÉMARRER LE MINUTEUR', 'DE': 'TIMER STARTEN', 'RU': 'ЗАПУСК ТАЙМЕРА', 'AR': 'بدء المؤقت', 'HI': 'टाइमर शुरू करें', 'VI': 'BẮT ĐẦU HẸN GIỜ', 'ES': 'INICIAR TEMPORIZADOR', 'TH': 'เริ่มตัวจับเวลา'},
    'whiteNoiseTitleEn': {'KO': '백색소음 선택', 'EN': 'White Noise Selection', 'JA': 'ホワイトノイズ選択', 'ZH': '白噪音选择', 'FR': 'Sélection de bruit blanc', 'DE': 'Weißes-Rauschen-Auswahl', 'RU': 'Выбор белого шума', 'AR': 'اختيار الضجيج الأبيض', 'HI': 'व्हाइट नॉइज़ चयन', 'VI': 'Chọn tiếng ồn trắng', 'ES': 'Selección de ruido blanco', 'TH': 'เลือกเสียงไวท์นอยส์'},
    'whiteNoiseHint': {'KO': '학습 시작 시 시작 알림음 다음에 이어서 재생됩니다. (선택 안 해도 됩니다)', 'EN': 'Plays right after the start chime when studying begins. (Optional)', 'JA': '学習開始時、開始通知音の後に続けて再生されます。（選択不要）', 'ZH': '学习开始时会在开始提示音之后接续播放。（可不选择）', 'FR': "Se joue juste après le carillon de début d'étude. (Facultatif)", 'DE': 'Wird direkt nach dem Start-Signalton beim Lernbeginn abgespielt. (Optional)', 'RU': 'Воспроизводится сразу после стартового сигнала при начале учёбы. (Необязательно)', 'AR': 'يتم تشغيله مباشرة بعد نغمة البدء عند بدء الدراسة. (اختياري)', 'HI': 'अध्ययन शुरू होने पर स्टार्ट अलर्ट के बाद बजेगा। (वैकल्पिक)', 'VI': 'Sẽ phát ngay sau âm báo bắt đầu khi bắt đầu học. (Không bắt buộc)', 'ES': 'Se reproduce justo después del sonido de inicio al comenzar a estudiar. (Opcional)', 'TH': 'จะเล่นต่อจากเสียงแจ้งเตือนเริ่มต้นเมื่อเริ่มเรียน (ไม่บังคับเลือก)'},
    'listenLabel': {'KO': '미리듣기', 'EN': 'LISTEN 10s', 'JA': '試聴', 'ZH': '试听', 'FR': 'ÉCOUTER 10s', 'DE': 'ANHÖREN 10s', 'RU': 'ПРОСЛУШАТЬ 10с', 'AR': 'استماع 10 ث', 'HI': 'सुनें 10s', 'VI': 'NGHE 10s', 'ES': 'ESCUCHAR 10s', 'TH': 'ฟัง 10 วิ'},
    'stopLabel': {'KO': '정지', 'EN': 'STOP', 'JA': '停止', 'ZH': '停止', 'FR': 'ARRÊTER', 'DE': 'STOPP', 'RU': 'СТОП', 'AR': 'إيقاف', 'HI': 'रोकें', 'VI': 'DỪNG', 'ES': 'PARAR', 'TH': 'หยุด'},
    'selectLabel': {'KO': '선택', 'EN': 'SELECT', 'JA': '選択', 'ZH': '选择', 'FR': 'CHOISIR', 'DE': 'AUSWÄHLEN', 'RU': 'ВЫБРАТЬ', 'AR': 'اختيار', 'HI': 'चुनें', 'VI': 'CHỌN', 'ES': 'ELEGIR', 'TH': 'เลือก'},
    'unselectLabel': {'KO': '해제', 'EN': 'UNSELECT', 'JA': '解除', 'ZH': '取消选择', 'FR': 'DÉSÉLECTIONNER', 'DE': 'ABWÄHLEN', 'RU': 'ОТМЕНИТЬ', 'AR': 'إلغاء التحديد', 'HI': 'अचयनित करें', 'VI': 'BỎ CHỌN', 'ES': 'DESELECCIONAR', 'TH': 'ยกเลิกเลือก'},
    'runSelectedLabel': {'KO': '선택항목 실행', 'EN': 'Run Selected', 'JA': '選択項目を実行', 'ZH': '运行所选项目', 'FR': 'Exécuter la sélection', 'DE': 'Auswahl ausführen', 'RU': 'Запустить выбранное', 'AR': 'تشغيل المحدد', 'HI': 'चयनित चलाएं', 'VI': 'Chạy mục đã chọn', 'ES': 'Ejecutar seleccionado', 'TH': 'เริ่มรายการที่เลือก'},
    'closeLabel': {'KO': '닫기', 'EN': 'CLOSE', 'JA': '閉じる', 'ZH': '关闭', 'FR': 'FERMER', 'DE': 'SCHLIESSEN', 'RU': 'ЗАКРЫТЬ', 'AR': 'إغلاق', 'HI': 'बंद करें', 'VI': 'ĐÓNG', 'ES': 'CERRAR', 'TH': 'ปิด'},

    'missionDetailsTitleEn': {'KO': '학습 계획 상세 조회', 'EN': 'MISSION DETAILS', 'JA': '学習計画詳細', 'ZH': '学习计划详情', 'FR': "DÉTAILS DE LA MISSION", 'DE': 'MISSIONSDETAILS', 'RU': 'ДЕТАЛИ ЗАДАЧИ', 'AR': 'تفاصيل المهمة', 'HI': 'मिशन विवरण', 'VI': 'CHI TIẾT NHIỆM VỤ', 'ES': 'DETALLES DE LA MISIÓN', 'TH': 'รายละเอียดภารกิจ'},
    'subjectLabelEn': {'KO': '시험 과목', 'EN': 'SUBJECT', 'JA': '試験科目', 'ZH': '考试科目', 'FR': 'MATIÈRE', 'DE': 'FACH', 'RU': 'ПРЕДМЕТ', 'AR': 'المادة', 'HI': 'विषय', 'VI': 'MÔN THI', 'ES': 'MATERIA', 'TH': 'วิชาสอบ'},
    'subjectHint': {'KO': '예: 수학 (함수 ~ 미적분)', 'EN': 'e.g. Math (Functions ~ Calculus)', 'JA': '例：数学（関数〜微積分）', 'ZH': '例：数学（函数～微积分）', 'FR': 'ex. Maths (Fonctions ~ Calcul)', 'DE': 'z. B. Mathe (Funktionen ~ Analysis)', 'RU': 'напр. Математика (Функции ~ Анализ)', 'AR': 'مثال: رياضيات (الدوال ~ التفاضل والتكامل)', 'HI': 'उदा. गणित (फ़ंक्शन ~ कैलकुलस)', 'VI': 'VD: Toán (Hàm số ~ Giải tích)', 'ES': 'ej. Matemáticas (Funciones ~ Cálculo)', 'TH': 'เช่น คณิตศาสตร์ (ฟังก์ชัน ~ แคลคูลัส)'},
    'scopeLabelEn': {'KO': '시험 범위', 'EN': 'SCOPE', 'JA': '試験範囲', 'ZH': '考试范围', 'FR': 'PORTÉE', 'DE': 'UMFANG', 'RU': 'ОБЪЁМ', 'AR': 'النطاق', 'HI': 'दायरा', 'VI': 'PHẠM VI', 'ES': 'ALCANCE', 'TH': 'ขอบเขต'},
    'scopeHint': {'KO': '예: 교과서 p.12 ~ p.45', 'EN': 'e.g. Textbook p.12 ~ p.45', 'JA': '例：教科書p.12〜p.45', 'ZH': '例：教材第12～45页', 'FR': 'ex. Manuel p.12 ~ p.45', 'DE': 'z. B. Lehrbuch S.12 ~ S.45', 'RU': 'напр. Учебник стр.12 ~ стр.45', 'AR': 'مثال: الكتاب ص12 ~ ص45', 'HI': 'उदा. पाठ्यपुस्तक पृ.12 ~ पृ.45', 'VI': 'VD: SGK trang 12 ~ 45', 'ES': 'ej. Libro pág.12 ~ pág.45', 'TH': 'เช่น หนังสือ หน้า 12 ~ 45'},
    'nextBtn': {'KO': '다음', 'EN': 'NEXT', 'JA': '次へ', 'ZH': '下一步', 'FR': 'SUIVANT', 'DE': 'WEITER', 'RU': 'ДАЛЕЕ', 'AR': 'التالي', 'HI': 'आगे', 'VI': 'TIẾP', 'ES': 'SIGUIENTE', 'TH': 'ถัดไป'},
    'saveBtn': {'KO': '저장', 'EN': 'SAVE', 'JA': '保存', 'ZH': '保存', 'FR': 'ENREGISTRER', 'DE': 'SPEICHERN', 'RU': 'СОХРАНИТЬ', 'AR': 'حفظ', 'HI': 'सहेजें', 'VI': 'LƯU', 'ES': 'GUARDAR', 'TH': 'บันทึก'},
    'saveExamScheduleTitleEn': {'KO': '시험 일정 저장', 'EN': 'Save Exam Schedule', 'JA': '試験日程を保存', 'ZH': '保存考试日程', 'FR': "Enregistrer le calendrier d'examen", 'DE': 'Prüfungstermin speichern', 'RU': 'Сохранить расписание экзамена', 'AR': 'حفظ جدول الامتحان', 'HI': 'परीक्षा अनुसूची सहेजें', 'VI': 'Lưu lịch thi', 'ES': 'Guardar horario de examen', 'TH': 'บันทึกกำหนดการสอบ'},
    'saveExamScheduleBody': {'KO': '시험 일정과 과목이 적용됩니다. 저장하시겠습니까?', 'EN': 'The exam schedule and subjects will be applied. Save?', 'JA': '試験日程と科目が適用されます。保存しますか？', 'ZH': '将应用考试日程与科目，是否保存？', 'FR': "Le calendrier et les matières seront appliqués. Enregistrer ?", 'DE': 'Prüfungstermin und Fächer werden übernommen. Speichern?', 'RU': 'Будут применены расписание и предметы экзамена. Сохранить?', 'AR': 'سيتم تطبيق جدول الامتحان والمواد. هل تريد الحفظ؟', 'HI': 'परीक्षा अनुसूची और विषय लागू होंगे। सहेजें?', 'VI': 'Lịch thi và các môn sẽ được áp dụng. Lưu không?', 'ES': 'Se aplicarán el horario y las materias del examen. ¿Guardar?', 'TH': 'จะใช้กำหนดการสอบและวิชาที่กรอก ต้องการบันทึกหรือไม่?'},
    'confirmBtn': {'KO': '확인', 'EN': 'Confirm', 'JA': '確認', 'ZH': '确认', 'FR': 'Confirmer', 'DE': 'Bestätigen', 'RU': 'Подтвердить', 'AR': 'تأكيد', 'HI': 'पुष्टि करें', 'VI': 'Xác nhận', 'ES': 'Confirmar', 'TH': 'ยืนยัน'},
    'editModeTitleEn': {'KO': '수정 및 삭제', 'EN': 'EDIT MODE', 'JA': '編集・削除', 'ZH': '编辑与删除', 'FR': 'MODIFIER / SUPPRIMER', 'DE': 'BEARBEITEN / LÖSCHEN', 'RU': 'РЕДАКТИРОВАТЬ / УДАЛИТЬ', 'AR': 'تعديل / حذف', 'HI': 'संपादित/हटाएं', 'VI': 'SỬA / XÓA', 'ES': 'EDITAR / ELIMINAR', 'TH': 'แก้ไข/ลบ'},
    'subjectOrTitleLabel': {'KO': '시험 과목', 'EN': 'SUBJECT OR TITLE', 'JA': '試験科目', 'ZH': '考试科目', 'FR': 'MATIÈRE', 'DE': 'FACH', 'RU': 'ПРЕДМЕТ', 'AR': 'المادة', 'HI': 'विषय', 'VI': 'MÔN THI', 'ES': 'MATERIA', 'TH': 'วิชาสอบ'},
    'memoDetailsLabel': {'KO': '시험 범위', 'EN': 'MEMO / DETAILS', 'JA': '試験範囲', 'ZH': '考试范围', 'FR': 'PORTÉE', 'DE': 'UMFANG', 'RU': 'ОБЪЁМ', 'AR': 'النطاق', 'HI': 'दायरा', 'VI': 'PHẠM VI', 'ES': 'ALCANCE', 'TH': 'ขอบเขต'},
    'delBtn': {'KO': '삭제', 'EN': 'DEL', 'JA': '削除', 'ZH': '删除', 'FR': 'SUPPR.', 'DE': 'LÖSCHEN', 'RU': 'УДАЛИТЬ', 'AR': 'حذف', 'HI': 'हटाएं', 'VI': 'XÓA', 'ES': 'ELIM.', 'TH': 'ลบ'},

    'addScheduleTitleEn': {'KO': '타임라인 항목 추가', 'EN': 'ADD SCHEDULE', 'JA': 'タイムライン項目追加', 'ZH': '添加时间表项目', 'FR': "AJOUTER À L'HORAIRE", 'DE': 'ZEITPLAN HINZUFÜGEN', 'RU': 'ДОБАВИТЬ В РАСПИСАНИЕ', 'AR': 'إضافة إلى الجدول', 'HI': 'शेड्यूल जोड़ें', 'VI': 'THÊM LỊCH TRÌNH', 'ES': 'AGREGAR AL HORARIO', 'TH': 'เพิ่มรายการในตาราง'},
    'timeFieldLabel': {'KO': '시간 (예: 09:00 - 10:00)', 'EN': 'TIME (e.g. 09:00 - 10:00)', 'JA': '時間（例：09:00〜10:00）', 'ZH': '时间（例：09:00～10:00）', 'FR': 'HEURE (ex. 09:00 - 10:00)', 'DE': 'ZEIT (z. B. 09:00 - 10:00)', 'RU': 'ВРЕМЯ (напр. 09:00 - 10:00)', 'AR': 'الوقت (مثال: 09:00 - 10:00)', 'HI': 'समय (उदा. 09:00 - 10:00)', 'VI': 'THỜI GIAN (VD: 09:00 - 10:00)', 'ES': 'HORA (ej. 09:00 - 10:00)', 'TH': 'เวลา (เช่น 09:00 - 10:00)'},
    'contentFieldLabel': {'KO': '내용', 'EN': 'CONTENT', 'JA': '内容', 'ZH': '内容', 'FR': 'CONTENU', 'DE': 'INHALT', 'RU': 'СОДЕРЖАНИЕ', 'AR': 'المحتوى', 'HI': 'सामग्री', 'VI': 'NỘI DUNG', 'ES': 'CONTENIDO', 'TH': 'เนื้อหา'},
    'deleteBtnSlash': {'KO': '삭제', 'EN': 'DELETE', 'JA': '削除', 'ZH': '删除', 'FR': 'SUPPRIMER', 'DE': 'LÖSCHEN', 'RU': 'УДАЛИТЬ', 'AR': 'حذف', 'HI': 'हटाएं', 'VI': 'XÓA', 'ES': 'ELIMINAR', 'TH': 'ลบ'},

    'noScheduleItemToRun': {'KO': '실행할 시간표 항목이 없습니다.', 'EN': 'There is no schedule item to run.', 'JA': '実行するタイムライン項目がありません。', 'ZH': '没有可运行的时间表项目。', 'FR': "Aucun élément d'horaire à exécuter.", 'DE': 'Kein Zeitplaneintrag zum Ausführen vorhanden.', 'RU': 'Нет пунктов расписания для запуска.', 'AR': 'لا يوجد عنصر جدول لتشغيله.', 'HI': 'चलाने के लिए कोई शेड्यूल आइटम नहीं है।', 'VI': 'Không có mục lịch trình để chạy.', 'ES': 'No hay un elemento del horario para ejecutar.', 'TH': 'ไม่มีรายการในตารางที่จะเริ่ม'},
    'selectScheduleItemFirst': {'KO': '먼저 학습할 시간표 항목을 선택해주세요.', 'EN': 'Please select a schedule item to study first.', 'JA': 'まず学習するタイムライン項目を選択してください。', 'ZH': '请先选择要学习的时间表项目。', 'FR': "Veuillez d'abord sélectionner un élément de l'horaire.", 'DE': 'Bitte wählen Sie zuerst einen Zeitplaneintrag zum Lernen aus.', 'RU': 'Пожалуйста, сначала выберите пункт расписания для изучения.', 'AR': 'يرجى اختيار عنصر الجدول للدراسة أولاً.', 'HI': 'कृपया पहले अध्ययन के लिए शेड्यूल आइटम चुनें।', 'VI': 'Vui lòng chọn mục lịch trình để học trước.', 'ES': 'Selecciona primero un elemento del horario para estudiar.', 'TH': 'กรุณาเลือกรายการในตารางที่จะเรียนก่อน'},
  };

  static String _foreignOnly(Map<String, String> map) {
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? '';
  }

  // 🆕 문자열 하나만 필요한 곳(버튼 라벨, 스낵바 등)에서 사용: 기본값은 "EN (KO)" 형태,
  // 10개국 선택 시 그 언어 단독 텍스트를 반환합니다.
  static String _biStr(String key, {String joiner = ' / '}) {
    final map = _uiText[key]!;
    if (_isForeignSelected) return _foreignOnly(map);
    return "${map['EN']}$joiner${map['KO']}";
  }

  // 🆕 기존에 영문 단독(ALL CAPS 헤더 등)으로만 표시되던 자리: 기본모드(KO/EN)는 그대로 영문만,
  // 10개국 선택 시에는 해당 언어로 전환됩니다.
  static String _enOrForeign(String key) {
    final map = _uiText[key]!;
    return _isForeignSelected ? _foreignOnly(map) : (map['EN'] ?? map['KO'] ?? '');
  }

  // 🆕 기존에 한글 단독으로만 표시되던 자리: 기본모드(KO/EN)는 그대로 한글만,
  // 10개국 선택 시에는 해당 언어로 전환됩니다.
  static String _koOrForeign(String key) {
    final map = _uiText[key]!;
    return _isForeignSelected ? _foreignOnly(map) : (map['KO'] ?? map['EN'] ?? '');
  }

  // 🆕 두 줄(영문 위 / 한글 아래)이 필요한 제목·본문형 위젯에서 사용
  Widget _biTitle(
      String key, {
        required TextStyle enStyle,
        TextStyle? koStyle,
        TextStyle? foreignStyle,
        TextAlign textAlign = TextAlign.start,
      }) {
    final TextStyle koFinal = koStyle ?? enStyle;
    if (_isForeignSelected) {
      return Text(
        _foreignOnly(_uiText[key]!),
        style: foreignStyle ?? koFinal,
        textAlign: textAlign,
        overflow: TextOverflow.fade,
        softWrap: false,
        maxLines: 1,
      );
    }
    final map = _uiText[key]!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: textAlign == TextAlign.start ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(map['EN']!, style: enStyle, textAlign: textAlign, overflow: TextOverflow.fade, softWrap: false, maxLines: 1),
        Text(map['KO']!, style: koFinal, textAlign: textAlign, overflow: TextOverflow.fade, softWrap: false, maxLines: 1),
      ],
    );
  }

  // 🆕 요일 표시 전용: 내부 캐시 키(en)는 절대 바꾸지 않고, 화면 표시 문구만 언어별로 변환.
  //    기본(KO/EN) 상태에서는 기존 "Mon / 월요일" 형태(축약형+한글)를 그대로 유지합니다.
  String _weekdayDisplay(Map<String, String> dayOption) {
    if (_isForeignSelected) {
      final String weekdayKey = 'weekday${dayOption['en']}';
      return _foreignOnly(_uiText[weekdayKey] ?? _uiText['weekdayMonday']!);
    }
    return '${dayOption['abbr']} / ${dayOption['ko']}';
  }

  @override
  void initState() {
    super.initState();
    _initAutoWeekday();
    _loadAllSettings();
    _loadCustomSchedules(); // 🆕 [버그 수정 2026-07-29] 수정/삭제한 시간표 실제 복원
    _loadCustomExamRecords(); // 🆕 [버그 수정 2026-07-29] 시험 과목/범위 기록 실제 복원
    _previewAudioPlayer = AudioPlayer(); // 🆕 [백색소음 선택] 미리듣기 전용 플레이어 초기화
    _previewAudioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _previewAudioPlayer.stop();
    _previewAudioPlayer.dispose();
    super.dispose();
  }

  void _initAutoWeekday() {
    final int weekdayNum = DateTime.now().weekday;
    const weekdayMap = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
    _selectedWeekdayEn = weekdayMap[weekdayNum] ?? 'Monday';
    _selectedPersonalWeekdayEn = weekdayMap[weekdayNum] ?? 'Monday'; // 🆕 [개인 시간표] 오늘 요일 자동 선택
  }

  // ============================================================
  // 설정 저장 / 불러오기 (날짜 파싱 오류 방어 및 동기화 강화)
  // ============================================================
  Future<void> _loadAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? vacStart = prefs.getString('gke_vacation_start_date');
    final String? vacEnd = prefs.getString('gke_vacation_end_date');
    final String? pomodoroKey = prefs.getString('gke_selected_pomodoro_key');
    final bool freeMode = prefs.getBool('gke_pomodoro_free_mode') ?? false;
    final String? examType = prefs.getString('gke_selected_exam_type');
    final String? examStartStr = prefs.getString('gke_exam_start_date');
    final String? examEndStr = prefs.getString('gke_exam_end_date');

    if (mounted) {
      setState(() {
        _vacationStartDate = vacStart != null ? DateTime.tryParse(vacStart) : null;
        _vacationEndDate = vacEnd != null ? DateTime.tryParse(vacEnd) : null;
        _selectedPomodoroKey = pomodoroKey;
        _isPomodoroFreeModeEnabled = freeMode;
        _isFinalExamMode = (examType == '기말고사');
        _examStartDate = examStartStr != null ? DateTime.tryParse(examStartStr) : null;
        _examEndDate = examEndStr != null ? DateTime.tryParse(examEndStr) : null;
      });
    }
  }

  // 🆕 [버그 수정 2026-07-29] 시간표 항목을 직접 추가/수정/삭제한 결과(_customSchedules)를
  // 영구 저장. 기존엔 이 저장 코드가 아예 없어서 화면을 나갔다 오면 원본으로 초기화되던 버그.
  Future<void> _saveCustomSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gke_custom_schedules', jsonEncode(_customSchedules));
    } catch (e) {
      debugPrint("[AcademicTimeline] 커스텀 시간표 저장 실패: $e");
    }
  }

  Future<void> _loadCustomSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString('gke_custom_schedules');
      if (raw == null || raw.isEmpty) return;
      final Map<String, dynamic> decoded = jsonDecode(raw);
      final Map<String, List<Map<String, String>>> restored = {};
      decoded.forEach((key, value) {
        if (value is List) {
          restored[key] = value.map((e) => Map<String, String>.from(e as Map)).toList();
        }
      });
      if (!mounted) return;
      setState(() {
        _customSchedules.clear();
        _customSchedules.addAll(restored);
      });
    } catch (e) {
      debugPrint("[AcademicTimeline] 커스텀 시간표 불러오기 실패: $e");
    }
  }

  // 🆕 [버그 수정 2026-07-29] 시험 과목/범위 기록(_customExamRecords)도 동일하게 저장 코드가
  // 없었어서 화면을 나갔다 오면 사라지던 버그. 위와 같은 방식으로 영구 저장/복원.
  Future<void> _saveCustomExamRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gke_custom_exam_records', jsonEncode(_customExamRecords));
    } catch (e) {
      debugPrint("[AcademicTimeline] 시험 과목/범위 기록 저장 실패: $e");
    }
  }

  Future<void> _loadCustomExamRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString('gke_custom_exam_records');
      if (raw == null || raw.isEmpty) return;
      final List<dynamic> decoded = jsonDecode(raw);
      final List<Map<String, String>> restored =
      decoded.map((e) => Map<String, String>.from(e as Map)).toList();
      if (!mounted) return;
      setState(() {
        _customExamRecords.clear();
        _customExamRecords.addAll(restored);
      });
    } catch (e) {
      debugPrint("[AcademicTimeline] 시험 과목/범위 기록 불러오기 실패: $e");
    }
  }

  Future<void> _saveVacationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (_vacationStartDate != null) {
      await prefs.setString('gke_vacation_start_date', _vacationStartDate!.toIso8601String());
    } else {
      await prefs.remove('gke_vacation_start_date');
    }
    if (_vacationEndDate != null) {
      await prefs.setString('gke_vacation_end_date', _vacationEndDate!.toIso8601String());
    } else {
      await prefs.remove('gke_vacation_end_date');
    }
    if (_selectedPomodoroKey != null) {
      await prefs.setString('gke_selected_pomodoro_key', _selectedPomodoroKey!);
    } else {
      await prefs.remove('gke_selected_pomodoro_key');
    }
    await prefs.setBool('gke_pomodoro_free_mode', _isPomodoroFreeModeEnabled);
  }

  Future<void> _saveExamSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gke_selected_exam_type', _isFinalExamMode ? '기말고사' : '중간고사');
    if (_examStartDate != null) {
      await prefs.setString('gke_exam_start_date', _examStartDate!.toIso8601String());
    } else {
      await prefs.remove('gke_exam_start_date');
    }
    if (_examEndDate != null) {
      await prefs.setString('gke_exam_end_date', _examEndDate!.toIso8601String());
    } else {
      await prefs.remove('gke_exam_end_date');
    }
    // 🆕 [D-day 팝업 근본 수정] 이 함수가 시험 날짜를 저장하는 진짜 원천 지점인데,
    // 여태까지 여기서 gke_exam_timeline_enabled를 저장하는 코드가 아예 없었음.
    // 그래서 "시험준비/시험당일" 탭에서 날짜만 등록하고 타이머를 안 켠 경우,
    // 이 값이 계속 false로 남아 D-day 팝업이 항상 꺼져 있었던 것으로 확인됨.
    // 시작일이 있으면 true, 없으면(삭제되면) false로 자동 설정.
    await prefs.setBool('gke_exam_timeline_enabled', _examStartDate != null);
  }

  // ============================================================
  // 데이터 매핑 및 타임라인 연동 로직
  // ============================================================
  List<Map<String, String>> _getCurrentActiveSchedule() {
    String cacheKey = '';
    List<Map<String, String>> defaultList = [];

    if (_selectedTrack == 'NORMAL_PERIOD') {
      cacheKey = 'NORMAL_PERIOD_$_selectedWeekdayEn';
      defaultList = StudyTimelines.normalPeriod[_selectedWeekdayEn] ?? [];
    } else if (_selectedTrack == 'VACATION_SUMMER_WINTER') {
      cacheKey = 'VACATION_${_selectedPomodoroKey ?? 'none'}';
      defaultList = _selectedPomodoroKey != null ? _getPomodoroListByKey(_selectedPomodoroKey!) : [];
    } else if (_selectedTrack == 'EXAM_PREP_PERIOD') {
      final DateTime today = DateTime.now();
      if (_isAfterExamEnd()) {
        final int wd = DateTime.now().weekday;
        final String todayEn = _weekdayOptions[wd - 1]['en']!;
        cacheKey = 'NORMAL_PERIOD_$todayEn';
        defaultList = StudyTimelines.normalPeriod[todayEn] ?? [];
      } else {
        final DateTime cleanToday = DateTime(today.year, today.month, today.day);

        if (_manualExamPrepWeek != null) {
          final String dayType = _calcExamPrepDayTypeForDate(cleanToday, _manualExamPrepWeek!);
          cacheKey = 'EXAM_PREP_${_isFinalExamMode ? "final" : "mid"}_w${_manualExamPrepWeek}_$dayType';
          defaultList = _getExamPrepList(_manualExamPrepWeek!, dayType, _isFinalExamMode);
        } else if (_examStartDate != null) {
          final DateTime cleanExamStart = DateTime(_examStartDate!.year, _examStartDate!.month, _examStartDate!.day);
          final int diffDays = cleanExamStart.difference(cleanToday).inDays;

          if (diffDays >= -3 && diffDays <= 4) {
            defaultList = StudyTimelines.getTimelineForDate(
              cleanToday,
              cleanExamStart,
              isExamPeriod: true,
              isActualExamWeek: true,
              isFinalExam: _isFinalExamMode,
            );
            cacheKey = 'EXAM_PREP_OVERLAP_${_isFinalExamMode ? "final" : "mid"}_diff_$diffDays';
          } else {
            int weekNum = _calcExamPrepWeekNum(diffDays);
            final String dayType = _calcExamPrepDayTypeForDate(cleanToday, weekNum);
            cacheKey = 'EXAM_PREP_${_isFinalExamMode ? "final" : "mid"}_w${weekNum}_$dayType';
            defaultList = _getExamPrepList(weekNum, dayType, _isFinalExamMode);
          }
        } else {
          cacheKey = 'EXAM_PREP_${_isFinalExamMode ? "final" : "mid"}_w4_weekday';
          defaultList = _getExamPrepList(4, 'weekday', _isFinalExamMode);
        }
      }

    } else if (_selectedTrack == 'EXAM_DAY_TRACK') {
      final DateTime today = DateTime.now();
      if (_isAfterExamEnd()) {
        // 🆕 [버그 수정] 기존엔 여기서 바로 return 해버려서 아래 공통 커스텀 편집(_customSchedules)
        // 확인 로직을 건너뛰었음. EXAM_PREP_PERIOD와 동일하게 cacheKey/defaultList를 설정해서
        // 시험 종료 후에도 사용자가 편집한 내용이 정상적으로 반영되도록 수정.
        final int wd = DateTime.now().weekday;
        final String todayEn = _weekdayOptions[wd - 1]['en']!;
        cacheKey = 'NORMAL_PERIOD_$todayEn';
        defaultList = StudyTimelines.normalPeriod[todayEn] ?? [];
      } else {
        final DateTime cleanToday = DateTime(today.year, today.month, today.day);
        final DateTime cleanExamStart = _examStartDate != null
            ? DateTime(_examStartDate!.year, _examStartDate!.month, _examStartDate!.day)
            : cleanToday;
        final int diff = cleanToday.difference(cleanExamStart).inDays;
        cacheKey = 'EXAM_DAY_${_isFinalExamMode ? "final" : "mid"}_diff_$diff';

        // 7월 20일 시험일 지정 시 D-3(Diff = -3)부터 정확히 타임라인이 표출되도록 방어 로직 적용
        if (_examStartDate != null && diff >= -3 && diff <= 4) {
          defaultList = StudyTimelines.getTimelineForDate(
            cleanToday,
            cleanExamStart,
            isExamPeriod: true,
            isActualExamWeek: true,
            isFinalExam: _isFinalExamMode,
          );
        } else if (_examStartDate != null) {
          defaultList = StudyTimelines.getTimelineForDate(
            cleanToday,
            cleanExamStart,
            isExamPeriod: true,
            isActualExamWeek: diff >= -3 && diff <= 4,
            isFinalExam: _isFinalExamMode,
          );
        } else {
          defaultList = [];
        }
      }
    } else if (_selectedTrack == 'PERSONAL_TIMETABLE') {
      // 🆕 [개인 시간표 2026-07-29] 평상시와 동일한 방식이지만, 기본 제공 데이터가 없는
      // 완전히 빈 시간표 - 사용자가 처음부터 직접 작성해야 함.
      cacheKey = 'PERSONAL_$_selectedPersonalWeekdayEn';
      defaultList = [];
    }

    if (_customSchedules.containsKey(cacheKey)) {
      return _customSchedules[cacheKey]!;
    }
    return defaultList;
  }

  String _getCurrentCacheKey() {
    if (_selectedTrack == 'NORMAL_PERIOD') {
      return 'NORMAL_PERIOD_$_selectedWeekdayEn';
    } else if (_selectedTrack == 'VACATION_SUMMER_WINTER') {
      return 'VACATION_${_selectedPomodoroKey ?? 'none'}';
    } else if (_selectedTrack == 'EXAM_PREP_PERIOD') {
      // 🆕 [버그 수정] _getCurrentActiveSchedule()과 동일하게 시험 종료 후에는
      // 'NORMAL_PERIOD_요일' 키를 써야 편집/저장이 실제 표시 내용과 일치합니다.
      if (_isAfterExamEnd()) {
        final int wd = DateTime.now().weekday;
        final String todayEn = _weekdayOptions[wd - 1]['en']!;
        return 'NORMAL_PERIOD_$todayEn';
      }
      final DateTime today = DateTime.now();
      final DateTime cleanToday = DateTime(today.year, today.month, today.day);
      if (_examStartDate != null) {
        final DateTime cleanExamStart = DateTime(_examStartDate!.year, _examStartDate!.month, _examStartDate!.day);
        final int diffDays = cleanExamStart.difference(cleanToday).inDays;
        if (diffDays >= -3 && diffDays <= 4) {
          return 'EXAM_PREP_OVERLAP_${_isFinalExamMode ? "final" : "mid"}_diff_$diffDays';
        }
        int weekNum = (diffDays > 21) ? 4 : (diffDays > 14 ? 3 : (diffDays > 7 ? 2 : 1));
        final String dayType = _calcExamPrepDayTypeForDate(cleanToday, weekNum);
        return 'EXAM_PREP_${_isFinalExamMode ? "final" : "mid"}_w${weekNum}_$dayType';
      }
      return 'EXAM_PREP_${_isFinalExamMode ? "final" : "mid"}_w4_weekday';
    } else if (_selectedTrack == 'PERSONAL_TIMETABLE') {
      return 'PERSONAL_$_selectedPersonalWeekdayEn';
    } else {
      // 🆕 [버그 수정] EXAM_DAY_TRACK도 시험 종료 후에는 동일한 'NORMAL_PERIOD_요일' 키를 사용.
      if (_isAfterExamEnd()) {
        final int wd = DateTime.now().weekday;
        final String todayEn = _weekdayOptions[wd - 1]['en']!;
        return 'NORMAL_PERIOD_$todayEn';
      }
      final DateTime today = DateTime.now();
      final DateTime cleanToday = DateTime(today.year, today.month, today.day);
      final DateTime cleanExamStart = _examStartDate != null
          ? DateTime(_examStartDate!.year, _examStartDate!.month, _examStartDate!.day)
          : cleanToday;
      final int diff = cleanToday.difference(cleanExamStart).inDays;
      return 'EXAM_DAY_${_isFinalExamMode ? "final" : "mid"}_diff_$diff';
    }
  }

  String _calcExamPrepDayTypeForDate(DateTime targetDate, int weekNum) {
    if (weekNum == 1) {
      return targetDate.weekday == 6 ? 'saturday' : (targetDate.weekday == 7 ? 'sunday' : 'weekday');
    } else {
      return (targetDate.weekday == 6 || targetDate.weekday == 7) ? 'weekend' : 'weekday';
    }
  }
// [추가] 주차 계산 통합 (중복 로직 제거)
  int _calcExamPrepWeekNum(int diffDays) {
    if (diffDays > 21) return 4;
    if (diffDays > 14) return 3;
    if (diffDays > 7) return 2;
    return 1;
  }

  // [추가] 시험 종료일 23시가 지났는지 체크 → 지났으면 평일 시간표로 자동 복귀
  bool _isAfterExamEnd() {
    if (_examEndDate == null) return false;
    final DateTime cutoff = DateTime(_examEndDate!.year, _examEndDate!.month, _examEndDate!.day, 23, 0);
    return DateTime.now().isAfter(cutoff);
  }

  // [추가] 'yyyy.m.d' 형식 문자열을 DateTime으로 파싱
  DateTime? _parseRecordDate(String formatted) {
    try {
      final parts = formatted.split('.');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
    } catch (_) {}
    return null;
  }

  List<Map<String, String>> _getPomodoroListByKey(String key) {
    switch (key) {
      case 'vacationPomodoro1':
        return StudyTimelines.vacationPomodoro1;
      case 'vacationPomodoro2':
        return StudyTimelines.vacationPomodoro2;
      case 'vacationPomodoro3':
        return StudyTimelines.vacationPomodoro3;
      case 'vacationPomodoro4':
        return StudyTimelines.vacationPomodoro4;
      default:
        return [];
    }
  }

  // 🆕 [12개국 연동] key(예: 'pomodoroStyle1')를 그대로 카탈로그 조회에 사용
  static const Map<String, String> _pomodoroKeyMap = {
    'vacationPomodoro1': 'pomodoroStyle1',
    'vacationPomodoro2': 'pomodoroStyle2',
    'vacationPomodoro3': 'pomodoroStyle3',
    'vacationPomodoro4': 'pomodoroStyle4',
  };

  String _getPomodoroDisplayName(String key) {
    final String uiKey = _pomodoroKeyMap[key] ?? 'pomodoroNotSelected';
    return _biStr(uiKey);
  }

  List<Map<String, String>> _getExamPrepList(int weekNum, String dayType, bool isFinal) {
    if (!isFinal) {
      switch (weekNum) {
        case 4:
          return dayType == 'weekday' ? StudyTimelinesExamPrepMid.midTermWeek4Weekday : StudyTimelinesExamPrepMid.midTermWeek4Weekend;
        case 3:
          return dayType == 'weekday' ? StudyTimelinesExamPrepMid.midTermWeek3Weekday : StudyTimelinesExamPrepMid.midTermWeek3Weekend;
        case 2:
          return dayType == 'weekday' ? StudyTimelinesExamPrepMid.midTermWeek2Weekday : StudyTimelinesExamPrepMid.midTermWeek2Weekend;
        default:
          if (dayType == 'weekday') return StudyTimelinesExamPrepMid.midTermWeek1Weekday;
          if (dayType == 'saturday') return StudyTimelinesExamPrepMid.midTermWeek1Saturday;
          return StudyTimelinesExamPrepMid.midTermWeek1Sunday;
      }
    } else {
      switch (weekNum) {
        case 4:
          return dayType == 'weekday' ? StudyTimelinesExamPrepFinal.finalTermWeek4Weekday : StudyTimelinesExamPrepFinal.finalTermWeek4Weekend;
        case 3:
          return dayType == 'weekday' ? StudyTimelinesExamPrepFinal.finalTermWeek3Weekday : StudyTimelinesExamPrepFinal.finalTermWeek3Weekend;
        case 2:
          return dayType == 'weekday' ? StudyTimelinesExamPrepFinal.finalTermWeek2Weekday : StudyTimelinesExamPrepFinal.finalTermWeek2Weekend;
        default:
          if (dayType == 'weekday') return StudyTimelinesExamPrepFinal.finalTermWeek1Weekday;
          if (dayType == 'saturday') return StudyTimelinesExamPrepFinal.finalTermWeek1Saturday;
          return StudyTimelinesExamPrepFinal.finalTermWeek1Sunday;
      }
    }
  }

  bool _isTimePassed(String timeStr) {
    try {
      final parts = timeStr.split(RegExp(r'[-~–]'));
      if (parts.isNotEmpty) {
        final endTimeStr = parts.last.trim();
        final hm = endTimeStr.split(':');
        if (hm.length >= 2) {
          final int endHour = int.parse(hm[0]);
          final int endMinute = int.parse(hm[1]);

          final now = DateTime.now();
          final targetTime = DateTime(now.year, now.month, now.day, endHour, endMinute);

          return now.isAfter(targetTime);
        }
      }
    } catch (_) {}
    return false;
  }
// [추가] "09:00 ~ 09:50" 형식에서 시작 시각만 분(分) 단위로 파싱 (항목 추가 시 시간순 삽입 위치 계산용)
  int? _parseStartMinutes(String timeStr) {
    try {
      final parts = timeStr.split(RegExp(r'[-~–]'));
      if (parts.isEmpty) return null;
      final startParts = parts.first.trim().split(':');
      if (startParts.length < 2) return null;
      return int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    } catch (_) {
      return null;
    }
  }

// [추가] "09:00 ~ 09:50" 형식에서 실제 분(分) 길이 계산 (자정 넘김 보정 포함)
  int? _calcDurationMinutes(String timeStr) {
    try {
      final parts = timeStr.split(RegExp(r'[-~–]'));
      if (parts.length < 2) return null;
      final startParts = parts.first.trim().split(':');
      final endParts = parts.last.trim().split(':');
      if (startParts.length < 2 || endParts.length < 2) return null;
      int startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      int endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      if (endMin <= startMin) endMin += 24 * 60;
      return endMin - startMin;
    } catch (_) {
      return null;
    }
  }

  // 🆕 [백색소음 선택] 팝업 안에서 10초간 미리듣기 재생/정지 토글
  // (Future<void>로 선언해서 호출부에서 완료를 기다린 뒤 팝업을 다시 그리도록 함 -
  //  기존엔 완료를 안 기다리고 팝업을 먼저 다시 그려서 탭이 한 번에 반영 안 되는 문제가 있었음)
  Future<void> _handleSoundPreview(String displayName, String fileName) async {
    try {
      _previewTimer?.cancel();
      await _previewAudioPlayer.stop();

      if (_previewingSoundDisplayName == displayName) {
        setState(() => _previewingSoundDisplayName = '');
      } else {
        setState(() => _previewingSoundDisplayName = displayName);
        await _previewAudioPlayer.play(AssetSource('sounds/$fileName'));

        _previewTimer = Timer(const Duration(seconds: 10), () async {
          await _previewAudioPlayer.stop();
          if (mounted) {
            setState(() => _previewingSoundDisplayName = '');
          }
        });
      }
    } catch (e) {
      debugPrint("오디오 미리듣기 재생 실패: $e");
    }
  }

  // 🆕 [백색소음 선택] SELECT / UNSELECT 토글. 선택된 파일은 타이머 실행 시 그대로 전달됨.
  // (Future<void>로 선언해서 호출부에서 완료를 기다린 뒤 팝업을 다시 그리도록 함)
  Future<void> _handleSoundSelect(String fileName) async {
    _previewTimer?.cancel();
    await _previewAudioPlayer.stop();
    setState(() {
      _previewingSoundDisplayName = '';
      if (_selectedSoundFile == fileName) {
        _selectedSoundFile = '';
      } else {
        _selectedSoundFile = fileName;
      }
    });
  }

  // [추가] TIM 버튼 실행 로직: 사용자가 선택한 항목으로 TimerScreen 이동. 선택 없으면 안내
  void _runTimerAction(List<Map<String, String>> schedule) {
    if (schedule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_koOrForeign('noScheduleItemToRun'), style: GoogleFonts.notoSerif())),
      );
      return;
    }
    if (_selectedScheduleIndex == null || _selectedScheduleIndex! >= schedule.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_koOrForeign('selectScheduleItemFirst'), style: GoogleFonts.notoSerif())),
      );
      return;
    }
    final item = schedule[_selectedScheduleIndex!];
    final String taskText = item['task'] ?? '학습';
    final int? durationMinutes = _calcDurationMinutes(item['time'] ?? '');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimerScreen(
          selectedSubject: taskText,
          selectedDurationMinutes: durationMinutes ?? 30,
          dynamicTestTitle: _isFinalExamMode ? '기말고사' : '중간고사',
          targetExamDate: _examStartDate,
          targetExamEndDate: _examEndDate,
          prepPeriodStr: _manualExamPrepWeek != null ? '${_manualExamPrepWeek}주 전' : '',
          // 🆕 [D-day 팝업 버그 수정] 기존엔 이 값이 항상 false로 고정되어 있어서,
          // 학사 타임라인에서 타이머를 실행할 때마다 gke_exam_timeline_enabled가 false로
          // 덮어써지며 D-day 팝업이 통째로 꺼지는 문제가 있었음. 시험 시작일이 설정돼 있으면
          // 자동으로 true가 되도록 수정.
          needTimelineGen: _examStartDate != null,
          selectedSoundFile: _selectedSoundFile, // 🆕 [백색소음 선택] 팝업에서 고른 소리를 그대로 전달
          isFinalExamMode: _isFinalExamMode,
          // 🆕 [2026-07-29] 시험준비/시험당일 트랙에서 실행할 때만 시험명+D-day 표시,
          // 평상시/방학/개인시간표에서 실행하면 "목표"만 표시됨
          isExamTrackMode: _selectedTrack == 'EXAM_PREP_PERIOD' || _selectedTrack == 'EXAM_DAY_TRACK',
        ),
      ),
    );
  }

// [수정] timer_play_btn.png 이미지로 교체된 TIM 실행 버튼
  Widget _buildTimButton(List<Map<String, String>> Function() scheduleGetter) {
    return GestureDetector(
      onTap: () => _showTimActionPopup(scheduleGetter),
      child: Image.asset(
        'assets/images/timer_play_btn.png',
        width: 100,
        height: 60,
        fit: BoxFit.contain,
      ),
    );
  }

  // ============================================================
  // 🆕 [수정] TIM 버튼 팝업: 백색소음 선택 목록 + 선택항목 실행 / 닫기
  // ("오늘 하루 전체 시작" 기능은 실제 타이머와 연동되지 않는 문제로 인해 삭제하고,
  //  대신 실제로 즉시 체감되는 백색소음 선택 기능을 그 자리에 추가함)
  // ============================================================
  void _showTimActionPopup(List<Map<String, String>> Function() scheduleGetter) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0B0F19),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
              ),
              title: Text(
                _biStr('startTimerTitleEn'),
                style: GoogleFonts.notoSerif(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _biStr('whiteNoiseTitleEn'),
                        style: GoogleFonts.notoSerif(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _koOrForeign('whiteNoiseHint'),
                        style: GoogleFonts.notoSerif(color: slate400, fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      ..._whiteNoiseSounds.map((snd) {
                        final String displayName = '${snd['en']} (${snd['ko']})';
                        final String fileName = snd['file']!;
                        final bool isSelected = _selectedSoundFile == fileName;
                        final bool isPreviewing = _previewingSoundDisplayName == displayName;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? goldColor : const Color(0xFF0D1527),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? goldColor : Colors.white12, width: 1.2),
                          ),
                          child: Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await _handleSoundPreview(displayName, fileName);
                                  if (context.mounted) setPopupState(() {});
                                },
                                icon: Icon(
                                  isPreviewing ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                                  size: 16,
                                  color: isSelected ? const Color(0xFF020617) : goldColor,
                                ),
                                label: Text(
                                  _isForeignSelected
                                      ? _foreignOnly(_uiText[isPreviewing ? 'stopLabel' : 'listenLabel']!)
                                      : (isPreviewing
                                          ? "${_uiText['stopLabel']!['EN']}\n[${_uiText['stopLabel']!['KO']}]"
                                          : "${_uiText['listenLabel']!['EN']}\n[${_uiText['listenLabel']!['KO']}]"),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.notoSerif(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? const Color(0xFF020617) : Colors.white70,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected ? Colors.black.withOpacity(0.15) : Colors.black45,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  minimumSize: const Size(0, 38), // 🆕 탭 영역 확대 (기존 Size.zero → 최소 높이 38 확보)
                                  tapTargetSize: MaterialTapTargetSize.padded,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "${snd['en']} ",
                                        style: GoogleFonts.notoSerif(
                                          color: isSelected ? const Color(0xFF020617) : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      TextSpan(
                                        text: "(${snd['ko']})",
                                        style: GoogleFonts.notoSerif(
                                          color: isSelected ? const Color(0xFF020617) : goldColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  await _handleSoundSelect(fileName);
                                  if (context.mounted) setPopupState(() {});
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected ? const Color(0xFF020617) : Colors.black45,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: const Size(0, 38), // 🆕 탭 영역 확대 (기존 Size.zero → 최소 높이 38 확보)
                                  tapTargetSize: MaterialTapTargetSize.padded,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    side: BorderSide(color: isSelected ? Colors.transparent : goldColor.withOpacity(0.5)),
                                  ),
                                ),
                                child: Text(
                                  _isForeignSelected
                                      ? _foreignOnly(_uiText[isSelected ? 'unselectLabel' : 'selectLabel']!)
                                      : (isSelected
                                          ? "${_uiText['unselectLabel']!['EN']}\n[${_uiText['unselectLabel']!['KO']}]"
                                          : "${_uiText['selectLabel']!['EN']}\n[${_uiText['selectLabel']!['KO']}]"),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.notoSerif(fontSize: 9, fontWeight: FontWeight.bold, color: goldColor),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              actions: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: goldColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        _previewTimer?.cancel();
                        _previewAudioPlayer.stop();
                        Navigator.pop(context);
                        _runTimerAction(scheduleGetter());
                      },
                      child: Text(_koOrForeign('runSelectedLabel'), style: GoogleFonts.notoSerif(color: const Color(0xFF020617), fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        _previewTimer?.cancel();
                        _previewAudioPlayer.stop();
                        Navigator.pop(context);
                      },
                      child: Text(_biStr('closeLabel'), style: GoogleFonts.notoSerif(color: slate400, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getTimelineBarColor(String track, String timeText, String taskText, int index) {
    // [추가] 방학 스타일2의 마지막 항목은 키워드 규칙보다 우선하여 보라색 지정

    if (track == 'VACATION_SUMMER_WINTER' && _selectedPomodoroKey == 'vacationPomodoro2' && index == 33) {
      return Colors.purple;
    }
    if (taskText.contains('기상') ||
        taskText.contains('체조') ||
        taskText.contains('아침식사') ||
        taskText.contains('점심') ||
        taskText.contains('저녁') ||
        taskText.contains('학교생활') ||
        taskText.contains('취침 준비') ||
        taskText.contains('마무리')) {
      return Colors.purple;
    }
    if (taskText.contains('취침')) {
      return darkGrey;
    }

    // [추가] 방학 스타일 1 전용 구간별 색상 지정
    if (track == 'VACATION_SUMMER_WINTER' && _selectedPomodoroKey == 'vacationPomodoro1') {
      if (index >= 2 && index <= 7) return Colors.red;
      if (index >= 8 && index <= 13) return Colors.blue;
      if (index >= 14 && index <= 19) return Colors.amber; // 노랑
      if (index >= 21 && index <= 26) return Colors.green;
      if (index >= 27 && index <= 32) return Colors.orange;
      if (index >= 34 && index <= 39) return Colors.indigo; // 남색
      if (index >= 40 && index <= 45) return Colors.red;
    }

    // [추가] 방학 스타일 2 전용 구간별 색상 지정
    if (track == 'VACATION_SUMMER_WINTER' && _selectedPomodoroKey == 'vacationPomodoro2') {
      if (index == 2 || index == 3) return Colors.red;
      if (index == 4 || index == 5) return Colors.blue;
      if (index == 6 || index == 7) return Colors.amber;
      if (index == 8 || index == 9) return Colors.green;
      if (index == 10 || index == 11) return Colors.orange;
      if (index == 13 || index == 14) return Colors.green;
      if (index == 15 || index == 16) return Colors.orange;
      if (index == 17 || index == 18) return Colors.indigo;
      if (index == 19 || index == 20) return Colors.red;
      if (index == 21 || index == 22) return Colors.blue;
      if (index == 23 || index == 24) return Colors.amber;
      if (index == 26 || index == 27) return Colors.green;
      if (index == 28 || index == 29) return Colors.orange;
      if (index == 30 || index == 31) return Colors.indigo;
      if (index == 32) return Colors.red;
    }

    // [추가] 방학 스타일 3 전용 구간별 색상 지정
    if (track == 'VACATION_SUMMER_WINTER' && _selectedPomodoroKey == 'vacationPomodoro3') {
      if (index >= 2 && index <= 7) return Colors.red;
      if (index >= 8 && index <= 13) return Colors.blue;
      if (index >= 15 && index <= 20) return Colors.amber;
      if (index >= 22 && index <= 27) return Colors.green;
      if (index == 28 || index == 29) return Colors.indigo;
    }

    // [추가] 방학 스타일 4 전용 구간별 색상 지정
    if (track == 'VACATION_SUMMER_WINTER' && _selectedPomodoroKey == 'vacationPomodoro4') {
      if (index >= 2 && index <= 5) return Colors.red;
      if (index >= 6 && index <= 9) return Colors.blue;
      if (index >= 11 && index <= 14) return Colors.amber;
      if (index >= 15 && index <= 18) return Colors.green;
      if (index >= 20 && index <= 22) return Colors.indigo;
    }
    if (track == 'NORMAL_PERIOD') {
      if (_selectedWeekdayEn == 'Saturday' || _selectedWeekdayEn == 'Sunday') {
        if (timeText.contains('07:00') && timeText.contains('08:00')) {
          return Colors.purple;
        }
        int adjustedIndex = (index > 0 ? index - 1 : 0) ~/ 2;
        return _rainbowColors[adjustedIndex % _rainbowColors.length];
      } else {
        if (timeText.contains('07:00') && timeText.contains('08:00')) {
          return Colors.red;
        }
        if ((timeText.contains('08:00') && timeText.contains('16:00')) ||
            (timeText.contains('16:00') && timeText.contains('17:00'))) {
          return Colors.purple;
        }
        int adjustedIndex = index >= 3 ? (index - 3) ~/ 2 : index;
        return _rainbowColors[adjustedIndex % _rainbowColors.length];
      }
    }

    return _rainbowColors[index % _rainbowColors.length];
  }

  // ============================================================
  // 효율적인 연속 입력 달력 및 일괄 저장 시스템 (오버플로우 및 커서 튀는 현상 완벽 해결)
  // ============================================================
  Future<void> _handleExamRecordFlow() async {
    List<Map<String, String>> sessionRecords = [];
    DateTime? nextTargetDate = firstSelectedDateOrDefault();
    bool isAdding = true;

    while (isAdding) {
      // [요구사항 2] 달력 색상 및 선택 날짜 황금색 강조 적용, 연속 입력 시 다음 날짜로 포커스 이동 유지
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: nextTargetDate ?? DateTime.now(),
        firstDate: DateTime(2024),
        lastDate: DateTime(2035),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: goldColor,
                onPrimary: const Color(0xFF020617),
                surface: const Color(0xFF0B0F19),
                onSurface: Colors.white,
              ),
              dialogBackgroundColor: const Color(0xFF0B0F19),
            ),
            child: child!,
          );
        },
      );

      if (pickedDate == null) {
        return;
      }

      nextTargetDate = pickedDate.add(const Duration(days: 1)); // 다음 날짜 자동 포커스 준비
      String formattedDate = '${pickedDate.year}.${pickedDate.month}.${pickedDate.day}';

      if (!mounted) return;

      final TextEditingController subjectController = TextEditingController();
      final TextEditingController scopeController = TextEditingController();

      // [요구사항 1] 팝업 내부 버튼 그룹 오버플로우 방지를 위한 Flexible/Wrap 구조 적용 및 우아한 디자인 유지
      String? actionType = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0B0F19),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
              side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _enOrForeign('missionDetailsTitleEn'),
                  style: GoogleFonts.notoSerif(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  '[$formattedDate] ${_koOrForeign('missionDetailsTitleEn')}',
                  style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Divider(color: Color(0xFF1E293B), height: 1),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⏰ ${_biStr('subjectLabelEn')}', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: subjectController,
                    style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: _koOrForeign('subjectHint'),
                      hintStyle: GoogleFonts.notoSerif(color: slate500, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF1E293B).withValues(alpha: 0.5),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: slate800)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: goldColor)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('📚 ${_biStr('scopeLabelEn')}', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: scopeController,
                    style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: _koOrForeign('scopeHint'),
                      hintStyle: GoogleFonts.notoSerif(color: slate500, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF1E293B).withValues(alpha: 0.5),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: slate800)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: goldColor)),
                    ),
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancel'),
                child: Text(_enOrForeign('closeLabel'), style: GoogleFonts.notoSerif(color: slate400, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: goldColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 38), // 🆕 [탭 영역 확대] 기존 Size.zero → 최소 높이 38 확보
                      tapTargetSize: MaterialTapTargetSize.padded,
                    ),
                    onPressed: () {
                      if (subjectController.text.trim().isEmpty) return;
                      Navigator.pop(context, 'next');
                    },
                    child: Text(_enOrForeign('nextBtn'), style: GoogleFonts.notoSerif(color: goldColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 38), // 🆕 [탭 영역 확대] 기존 Size.zero → 최소 높이 38 확보
                      tapTargetSize: MaterialTapTargetSize.padded,
                    ),
                    onPressed: () {
                      if (subjectController.text.trim().isEmpty) return;
                      Navigator.pop(context, 'save');
                    },
                    child: Text(_enOrForeign('saveBtn'), style: GoogleFonts.notoSerif(color: const Color(0xFF020617), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          );
        },
      );

      if (actionType == 'cancel' || actionType == null) {
        return;
      }

      sessionRecords.add({
        'date': formattedDate,
        'subject': subjectController.text.trim(),
        'scope': scopeController.text.trim(),
      });

      if (actionType == 'save') {
        isAdding = false;
      }
    }

    if (!mounted) return;
    bool? confirmSave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0B0F19),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
          ),
          title: Text(
            _biStr('saveExamScheduleTitleEn'),
            style: GoogleFonts.notoSerif(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: Text(
            _koOrForeign('saveExamScheduleBody'),
            style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 13),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(_biStr('cancelBtn'), style: GoogleFonts.notoSerif(color: slate400, fontSize: 12)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: goldColor),
              onPressed: () => Navigator.pop(context, true),
              child: Text(_biStr('confirmBtn'), style: GoogleFonts.notoSerif(color: const Color(0xFF020617), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmSave == true) {
      setState(() {
        _customExamRecords.addAll(sessionRecords);
      });
      await _saveCustomExamRecords(); // 🆕 [버그 수정 2026-07-29] 시험 과목/범위 기록 실제 영구 저장

      // [추가] 등록된 시험 기록의 최소/최대 날짜로 시험 시작일·종료일 자동 연동
      List<DateTime> allDates = _customExamRecords
          .map((r) => _parseRecordDate(r['date'] ?? ''))
          .whereType<DateTime>()
          .toList();
      if (allDates.isNotEmpty) {
        allDates.sort();
        setState(() {
          _examStartDate = allDates.first;
          _examEndDate = allDates.last;
        });
        await _saveExamSettings();
      }
    }
  }

  DateTime firstSelectedDateOrDefault() {
    if (_examStartDate != null) return _examStartDate!;
    return DateTime.now();
  }

  void _showEditExamRecordDialog(int index) {
    final record = _customExamRecords[index];
    final TextEditingController subjectController = TextEditingController(text: record['subject']);
    final TextEditingController scopeController = TextEditingController(text: record['scope']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0B0F19),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
          ),
          title: Text(
            '[${record['date']}] ${_biStr('editModeTitleEn')}',
            style: GoogleFonts.notoSerif(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: _biStr('subjectOrTitleLabel'),
                  labelStyle: GoogleFonts.notoSerif(color: slate400, fontSize: 12),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: slate800)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: scopeController,
                style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: _biStr('memoDetailsLabel'),
                  labelStyle: GoogleFonts.notoSerif(color: slate400, fontSize: 12),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: slate800)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () async {
                setState(() {
                  _customExamRecords.removeAt(index);
                });
                await _saveCustomExamRecords(); // 🆕 [버그 수정 2026-07-29] 실제 영구 저장
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(_biStr('delBtn'), style: GoogleFonts.notoSerif(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: goldColor),
              onPressed: () async {
                if (subjectController.text.trim().isEmpty) return;
                setState(() {
                  _customExamRecords[index] = {
                    'date': record['date']!,
                    'subject': subjectController.text.trim(),
                    'scope': scopeController.text.trim(),
                  };
                });
                await _saveCustomExamRecords(); // 🆕 [버그 수정 2026-07-29] 실제 영구 저장
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(_biStr('saveBtn'), style: GoogleFonts.notoSerif(color: const Color(0xFF020617), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showEditItemDialog({int? index, String? initialTime, String? initialTask}) {
    final TextEditingController timeController = TextEditingController(text: initialTime ?? '');
    final TextEditingController taskController = TextEditingController(text: initialTask ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0B0F19),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
          ),
          title: Text(
            index == null ? _biStr('addScheduleTitleEn') : _biStr('editModeTitleEn'),
            style: GoogleFonts.notoSerif(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: timeController,
                style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: _biStr('timeFieldLabel'),
                  labelStyle: GoogleFonts.notoSerif(color: slate400, fontSize: 12),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: slate800)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: taskController,
                style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: _biStr('contentFieldLabel'),
                  labelStyle: GoogleFonts.notoSerif(color: slate400, fontSize: 12),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: slate800)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          actions: [
            Row(
              children: [
                if (index != null)
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 2)),
                      onPressed: () async {
                        setState(() {
                          String cacheKey = _getCurrentCacheKey();
                          List<Map<String, String>> currentList = List.from(_getCurrentActiveSchedule());
                          currentList.removeAt(index);
                          _customSchedules[cacheKey] = currentList;
                        });
                        await _saveCustomSchedules(); // 🆕 [버그 수정 2026-07-29] 실제 영구 저장
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(_biStr('deleteBtnSlash'), maxLines: 1, style: GoogleFonts.notoSerif(color: Colors.redAccent, fontSize: 12)),
                      ),
                    ),
                  ),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 2)),
                    onPressed: () => Navigator.pop(context),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(_biStr('closeLabel', joiner: '/'), maxLines: 1, style: GoogleFonts.notoSerif(color: slate400, fontSize: 12)),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldColor,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                    ),
                    onPressed: () async {
                      if (timeController.text.trim().isEmpty || taskController.text.trim().isEmpty) return;
                      setState(() {
                        String cacheKey = _getCurrentCacheKey();
                        List<Map<String, String>> currentList = List.from(_getCurrentActiveSchedule());
                        if (index == null) {
                          // 🆕 [시간순 자동 배치] 새 항목을 맨 끝에 붙이지 않고,
                          // 시작 시각을 기준으로 기존 항목들 사이의 올바른 위치에 삽입함.
                          // (예: 08:00~16:00 "즐거운 학교생활" 사이에 새 항목을 넣으면 그 시간대 순서에 맞게 배치됨)
                          final newItem = {'time': timeController.text.trim(), 'task': taskController.text.trim()};
                          final int? newStartMinutes = _parseStartMinutes(newItem['time']!);

                          int insertAt = currentList.length; // 시각 파싱 실패 시 기본은 맨 끝
                          if (newStartMinutes != null) {
                            insertAt = currentList.indexWhere((existing) {
                              final int? existingStart = _parseStartMinutes(existing['time'] ?? '');
                              return existingStart != null && existingStart > newStartMinutes;
                            });
                            if (insertAt == -1) insertAt = currentList.length; // 가장 늦은 시각이면 맨 끝
                          }
                          currentList.insert(insertAt, newItem);
                        } else {
                          currentList[index] = {'time': timeController.text.trim(), 'task': taskController.text.trim()};
                        }
                        _customSchedules[cacheKey] = currentList;
                      });
                      await _saveCustomSchedules(); // 🆕 [버그 수정 2026-07-29] 실제 영구 저장
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(_biStr('saveBtn', joiner: '/'), maxLines: 1, style: GoogleFonts.notoSerif(color: const Color(0xFF020617), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _resetToDefaultSchedule() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0B0F19),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
          ),
          title: Text(_biStr('resetDialogTitleEn'), style: GoogleFonts.notoSerif(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold)),
          content: Text(_koOrForeign('resetDialogBody'), style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 14)),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_biStr('cancelBtn'), style: GoogleFonts.notoSerif(color: slate400, fontSize: 12)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: goldColor),
              onPressed: () async {
                setState(() {
                  String cacheKey = _getCurrentCacheKey();
                  _customSchedules.remove(cacheKey);
                });
                await _saveCustomSchedules(); // 🆕 [버그 수정 2026-07-29] 리셋 결과도 실제 영구 저장
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(_biStr('confirmResetBtn'), style: GoogleFonts.notoSerif(color: const Color(0xFF020617), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        automaticallyImplyLeading: false,
        toolbarHeight: 90,
        title: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/gsu_logo.png',
                width: 180,
                height: 28,
              ),
              const SizedBox(height: 0.5),
              _biTitle(
                'appBarTitle',
                textAlign: TextAlign.center,
                enStyle: GoogleFonts.notoSerif(color: goldColor, fontSize: 20, fontWeight: FontWeight.bold),
                koStyle: GoogleFonts.notoSerif(color: goldColor, fontSize: 17, fontWeight: FontWeight.bold),
                foreignStyle: GoogleFonts.notoSerif(color: goldColor, fontSize: 19, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTrackSelector(),
          const Divider(color: Color(0xFF1E293B), height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildTrackBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackSelector() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      // 🆕 [개인 시간표 2026-07-29] 탭이 5개로 늘어나서 좌우 스크롤 가능하도록 변경
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            SizedBox(width: 82, child: _trackButton('tabNormal', 'NORMAL_PERIOD')),
            const SizedBox(width: 6),
            SizedBox(width: 82, child: _trackButton('tabVacation', 'VACATION_SUMMER_WINTER')),
            const SizedBox(width: 6),
            SizedBox(width: 82, child: _trackButton('tabExamPrep', 'EXAM_PREP_PERIOD')),
            const SizedBox(width: 6),
            SizedBox(width: 82, child: _trackButton('tabExamDay', 'EXAM_DAY_TRACK')),
            const SizedBox(width: 6),
            SizedBox(
              width: 82,
              child: _trackButton(
                'tabPersonal',
                'PERSONAL_TIMETABLE',
                onBeforeSelect: _showPersonalTimetableGuideDialog, // 🆕 탭 누를 때마다 안내 팝업
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trackButton(String uiKey, String trackKey, {VoidCallback? onBeforeSelect}) {
    bool isSelected = _selectedTrack == trackKey;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? goldColor : slate800,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        minimumSize: const Size(0, 44),
      ),
      onPressed: () {
        onBeforeSelect?.call(); // 🆕 [개인 시간표 2026-07-29] 지정된 경우, 탭 전환 전에 먼저 실행
        setState(() {
          _selectedTrack = trackKey;
          _selectedScheduleIndex = null;
        });
      },

      // 🆕 [12개국 연동] 기본값(KO/EN) = 영문 1줄+한글 1줄, 10개국 선택 시 = 해당 언어 1줄
      child: _biTitle(
        uiKey,
        textAlign: TextAlign.center,
        enStyle: GoogleFonts.notoSerif(
          color: isSelected ? const Color(0xFF020617) : Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildTrackBody() {
    switch (_selectedTrack) {
      case 'NORMAL_PERIOD':
        return _buildNormalPeriodBody();
      case 'VACATION_SUMMER_WINTER':
        return _buildVacationBody();
      case 'EXAM_PREP_PERIOD':
        return _buildExamPrepBody();
      case 'EXAM_DAY_TRACK':
        return _buildExamDayBody();
      case 'PERSONAL_TIMETABLE':
        return _buildPersonalTimetableBody();
      default:
        return _buildNormalPeriodBody();
    }
  }

  Widget _buildNormalPeriodBody() {
    List<Map<String, String>> schedule = _getCurrentActiveSchedule();

    final currentSelectedObj = _weekdayOptions.firstWhere((d) => d['en'] == _selectedWeekdayEn, orElse: () => _weekdayOptions[0]);
    // [수정] 평상시 화면에서는 D-day 대신 현재 선택된 요일을 표시 (요일 펼침메뉴가 접혀있어도 바로 확인 가능)
    final String dDayText = _weekdayDisplay(currentSelectedObj);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_enOrForeign('normalTitleEn'), style: GoogleFonts.notoSerif(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_koOrForeign('normalSubtitle'), style: GoogleFonts.notoSerif(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buildTimButton(() => _getCurrentActiveSchedule()),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: slate800.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: slate800),
          ),
          child: ExpansionTile(
            initiallyExpanded: _isNormalWeekdayExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _isNormalWeekdayExpanded = expanded;
              });
            },
            collapsedTextColor: goldColor,
            textColor: goldColor,
            iconColor: goldColor,
            collapsedIconColor: slate400,
            title: Text(
              '${_koOrForeign('selectWeekdayLabel')} ($dDayText)',
              style: GoogleFonts.notoSerif(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 3.5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: _weekdayOptions.map((day) {
                    bool isSel = _selectedWeekdayEn == day['en'];
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedWeekdayEn = day['en']!;
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSel ? goldColor : slate800,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSel ? goldColor : slate800),
                        ),
                        child: Text(
                          _weekdayDisplay(day),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade, // 🆕 [오버플로우 방지 2026-07-29]
                          style: GoogleFonts.notoSerif(
                            fontSize: 12,
                            color: isSel ? const Color(0xFF020617) : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: goldColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: goldColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  dDayText,
                  style: GoogleFonts.notoSerif(
                    color: goldColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildScheduleHeaderBar(),
          ],
        ),
        const SizedBox(height: 8),
        ..._buildScheduleList(schedule),
      ],
    );
  }

  // 🆕 [개인 시간표 2026-07-29] 탭을 누를 때마다 뜨는 안내 팝업
  void _showPersonalTimetableGuideDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0B0F19),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
          ),
          title: Text(
            _biStr('personalGuideTitle'),
            style: GoogleFonts.notoSerif(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: Text(
            _isForeignSelected
                ? _foreignOnly(_uiText['personalGuideBody']!)
                : "${_uiText['personalGuideBody']!['EN']}\n\n(${_uiText['personalGuideBody']!['KO']})",
            style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 13, height: 1.5),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: goldColor),
              onPressed: () => Navigator.pop(context),
              child: Text(_biStr('okConfirmLabel'), style: GoogleFonts.notoSerif(color: const Color(0xFF020617), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // 🆕 [개인 시간표 2026-07-29] 평상시(_buildNormalPeriodBody)와 100% 동일한 구조.
  // 다른 점은 기본 제공 시간표가 없다는 것뿐이라, 대신 작성 형식을 보여주는 샘플 2개를
  // "+Add/항목 추가" 버튼 아래에 고정 표시하고, 그 아래 실제 편집 가능한 빈 목록을 둠.
  Widget _buildPersonalTimetableBody() {
    List<Map<String, String>> schedule = _getCurrentActiveSchedule();

    final currentSelectedObj = _weekdayOptions.firstWhere(
          (d) => d['en'] == _selectedPersonalWeekdayEn,
      orElse: () => _weekdayOptions[0],
    );
    final String dDayText = _weekdayDisplay(currentSelectedObj);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_enOrForeign('personalTitleEn'), style: GoogleFonts.notoSerif(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_koOrForeign('personalSubtitle'), style: GoogleFonts.notoSerif(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buildTimButton(() => _getCurrentActiveSchedule()),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: slate800.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: slate800),
          ),
          child: ExpansionTile(
            initiallyExpanded: _isPersonalWeekdayExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _isPersonalWeekdayExpanded = expanded;
              });
            },
            collapsedTextColor: goldColor,
            textColor: goldColor,
            iconColor: goldColor,
            collapsedIconColor: slate400,
            title: Text(
              '${_koOrForeign('selectWeekdayLabel')} (${_weekdayDisplay(currentSelectedObj)})',
              style: GoogleFonts.notoSerif(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 3.5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: _weekdayOptions.map((day) {
                    bool isSel = _selectedPersonalWeekdayEn == day['en'];
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedPersonalWeekdayEn = day['en']!;
                          _selectedScheduleIndex = null;
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSel ? goldColor : slate800,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSel ? goldColor : slate800),
                        ),
                        child: Text(
                          _weekdayDisplay(day),
                          style: GoogleFonts.notoSerif(
                            fontSize: 12,
                            color: isSel ? const Color(0xFF020617) : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: goldColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: goldColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  dDayText,
                  style: GoogleFonts.notoSerif(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildScheduleHeaderBar(),
          ],
        ),
        const SizedBox(height: 12),

        // 🆕 작성 형식을 보여주는 가이드용 샘플 2개 - 저장/실행 대상 아님, 참고용 표시만
        Text(_biStr('personalSampleLabel'), style: GoogleFonts.notoSerif(color: slate400, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ..._personalScheduleGuideSamples.map((sample) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: slate800),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 92,
                child: Text(sample['time']!, style: GoogleFonts.notoSerif(color: slate400, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(sample['task']!, style: GoogleFonts.notoSerif(color: slate400, fontSize: 13))),
            ],
          ),
        )),
        const SizedBox(height: 14),
        Text(_koOrForeign('personalOwnScheduleLabel'), style: GoogleFonts.notoSerif(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._buildScheduleList(schedule),
      ],
    );
  }

  // ------------------------------------------------------------
  // 2. 방학 바디 (시작일 ~ 종료일 완벽 표출 반영)
  // ------------------------------------------------------------
  Widget _buildVacationBody() {
    List<Map<String, String>> schedule = _getCurrentActiveSchedule();

    String vacationPeriodDisplay = '방학 기간 미설정';
    if (_vacationStartDate != null && _vacationEndDate != null) {
      vacationPeriodDisplay = '방학 기간: ${_vacationStartDate!.year}.${_vacationStartDate!.month}.${_vacationStartDate!.day} ~ ${_vacationEndDate!.year}.${_vacationEndDate!.month}.${_vacationEndDate!.day}';
    } else if (_vacationStartDate != null) {
      vacationPeriodDisplay = '방학 시작일: ${_vacationStartDate!.year}.${_vacationStartDate!.month}.${_vacationStartDate!.day} ~ (종료일 미설정)';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_enOrForeign('vacationTitleEn'), style: GoogleFonts.notoSerif(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_koOrForeign('vacationSubtitle'), style: GoogleFonts.notoSerif(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buildTimButton(() => _getCurrentActiveSchedule()),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: slate800.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: slate800)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_biStr('vacationPeriodLabel'), style: GoogleFonts.notoSerif(fontSize: 16, color: goldColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(side: BorderSide(color: slate800)),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _vacationStartDate ?? DateTime.now(),
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2035),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: ColorScheme.dark(primary: goldColor, onPrimary: const Color(0xFF020617), surface: const Color(0xFF0B0F19), onSurface: Colors.white),
                                dialogBackgroundColor: const Color(0xFF0B0F19),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _vacationStartDate = picked;
                          });
                          await _saveVacationSettings();
                        }
                      },
                      child: Text(
                        _vacationStartDate == null
                            ? _koOrForeign('startDateSelect')
                            : '${_vacationStartDate!.year}.${_vacationStartDate!.month}.${_vacationStartDate!.day}',
                        style: GoogleFonts.notoSerif(fontSize: 14, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('~', style: GoogleFonts.notoSerif(color: slate400)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(side: BorderSide(color: slate800)),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _vacationEndDate ?? (_vacationStartDate ?? DateTime.now()),
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2035),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: ColorScheme.dark(primary: goldColor, onPrimary: const Color(0xFF020617), surface: const Color(0xFF0B0F19), onSurface: Colors.white),
                                dialogBackgroundColor: const Color(0xFF0B0F19),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _vacationEndDate = picked;
                          });
                          await _saveVacationSettings();
                        }
                      },
                      child: Text(
                        _vacationEndDate == null
                            ? _koOrForeign('endDateSelect')
                            : '${_vacationEndDate!.year}.${_vacationEndDate!.month}.${_vacationEndDate!.day}',
                        style: GoogleFonts.notoSerif(fontSize: 14, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: slate800.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: slate800),
          ),
          child: ExpansionTile(
            initiallyExpanded: _isVacationStyleExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _isVacationStyleExpanded = expanded;
              });
            },
            collapsedTextColor: goldColor,
            textColor: goldColor,
            iconColor: goldColor,
            collapsedIconColor: slate400,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _enOrForeign('pomodoroStyleTitleEn'),
                  style: GoogleFonts.notoSerif(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  _koOrForeign('pomodoroStyleSubtitle'),
                  style: GoogleFonts.notoSerif(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_koOrForeign('pomodoroHint'),
                        style: GoogleFonts.notoSerif(fontSize: 12, color: slate500)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['vacationPomodoro1', 'vacationPomodoro2', 'vacationPomodoro3', 'vacationPomodoro4'].map((key) {
                        bool isSel = _selectedPomodoroKey == key;
                        return ChoiceChip(
                          label: Text(
                            _getPomodoroDisplayName(key),
                            style: GoogleFonts.notoSerif(
                                fontSize: 12, color: isSel ? const Color(0xFF020617) : Colors.white, fontWeight: FontWeight.bold),
                          ),
                          selected: isSel,
                          selectedColor: goldColor,
                          backgroundColor: const Color(0xFF0F172A),
                          side: BorderSide(color: isSel ? goldColor : slate800),
                          onSelected: (selected) async {
                            setState(() {
                              _selectedPomodoroKey = selected ? key : null;
                            });
                            await _saveVacationSettings();
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(_koOrForeign('pomodoroFreeMode'),
                              style: GoogleFonts.notoSerif(fontSize: 12, color: Colors.white)),
                        ),
                        Switch(
                          value: _isPomodoroFreeModeEnabled,
                          activeColor: goldColor,
                          onChanged: (val) async {
                            setState(() {
                              _isPomodoroFreeModeEnabled = val;
                            });
                            await _saveVacationSettings();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFF1E293B), height: 30),
        if (_selectedPomodoroKey == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Text(_koOrForeign('noPomodoroSelected'),
                style: GoogleFonts.notoSerif(color: slate500, fontSize: 12)),
          )
        else ...[
          Builder(builder: (context) {
            // 🆕 [12개국 연동] 기본값(KO/EN)은 영문/한글 두 줄, 10개국 선택 시 해당 언어 한 줄
            final String uiKey = _pomodoroKeyMap[_selectedPomodoroKey!] ?? 'pomodoroNotSelected';

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _biTitle(
                    uiKey,
                    enStyle: GoogleFonts.notoSerif(color: goldColor.withValues(alpha: 0.8), fontSize: 15, fontWeight: FontWeight.bold),
                    koStyle: GoogleFonts.notoSerif(color: goldColor.withValues(alpha: 0.7), fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                _buildAddButton(), // [추가] 오른쪽 끝에 항목 추가 버튼
              ],
            );
          }),
          const SizedBox(height: 10),
          _buildScheduleHeaderBar(showAddButton: false), // [수정] Add는 위에서 이미 표시했으므로 Edited/Reset만
          const SizedBox(height: 5),
          ..._buildScheduleList(schedule),
        ],
      ],
    );
  }

  // ------------------------------------------------------------
  // 3. 시험 준비 바디 (시험 시작일 정확한 날짜 연동 표출 반영)
  // ------------------------------------------------------------
  Widget _buildExamPrepBody() {
    List<Map<String, String>> schedule = _getCurrentActiveSchedule();

    // 🆕 [버그 수정] 시험이 끝난(종료일 23시 이후) 상태인지 미리 확인.
    // 이 값이 true면 아래 타이틀도 "준비 타임라인/D-day" 문구 대신 평상시로 복귀했음을 보여줍니다.
    final bool afterExamEnd = _isAfterExamEnd();

    String dDayDisplay = '';
    if (_examStartDate != null) {
      final DateTime today = DateTime.now();
      final DateTime cleanToday = DateTime(today.year, today.month, today.day);
      final DateTime cleanExamStart = DateTime(_examStartDate!.year, _examStartDate!.month, _examStartDate!.day);
      final int diff = cleanExamStart.difference(cleanToday).inDays;
      if (diff == 0) {
        dDayDisplay = ' (D-Day)';
      } else if (diff > 0) {
        dDayDisplay = ' (D-$diff)';
      } else {
        dDayDisplay = ' (D+${diff.abs()})';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_enOrForeign('examPrepTitleEn'), style: GoogleFonts.notoSerif(color: goldColor, fontSize: 17, fontWeight: FontWeight.bold)),
        Text(_koOrForeign('examPrepSubtitle'),
            style: GoogleFonts.notoSerif(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: slate800.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: slate800),
          ),
          child: ExpansionTile(
            initiallyExpanded: _isExamSettingExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _isExamSettingExpanded = expanded;
              });
            },
            collapsedTextColor: goldColor,
            textColor: goldColor,
            iconColor: goldColor,
            collapsedIconColor: slate400,
            title: Row(
              children: [
                Text(_biStr('examInfoSettingTitle'), style: GoogleFonts.notoSerif(fontSize: 14, color: goldColor, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Text(
                  '(${_isFinalExamMode ? "Final/기말" : "Mid/중간"})',
                  style: GoogleFonts.notoSerif(fontSize: 13, color: slate400),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        {'ko': '중간고사', 'uiKey': 'radioMidterm'},
                        {'ko': '기말고사', 'uiKey': 'radioFinal'},
                      ].map((typeMap) {
                        final String type = typeMap['ko']!;
                        return Padding(
                          padding: const EdgeInsets.only(right: 17.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: type,
                                groupValue: _isFinalExamMode ? '기말고사' : '중간고사',
                                activeColor: goldColor,
                                onChanged: (value) async {
                                  setState(() {
                                    _isFinalExamMode = (value == '기말고사');
                                  });
                                  await _saveExamSettings();
                                },
                              ),
                              // 🆕 [12개국 연동] 기본값(KO/EN)=영문+한글 두 줄, 10개국 선택 시=해당 언어 한 줄
                              _biTitle(
                                typeMap['uiKey']!,
                                enStyle: GoogleFonts.notoSerif(fontSize: 13, color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [4, 3, 2].map((w) {
                        bool sel = _manualExamPrepWeek == w;
                        final Color txtColor = sel ? const Color(0xFF020617) : goldColor;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: w != 2 ? 6 : 0),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: sel ? goldColor : null,
                                side: BorderSide(color: goldColor),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              onPressed: () {
                                setState(() {
                                  _manualExamPrepWeek = sel ? null : w;
                                });
                              },
                              // 🆕 [12개국 연동] 기본값(KO/EN)=영문+한글 두 줄, 10개국 선택 시=해당 언어 한 줄
                              child: _isForeignSelected
                                  ? Text(
                                      '$w ${_foreignOnly(_uiText['weeksBeforeSuffix']!)}',
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.fade,
                                      style: GoogleFonts.notoSerif(color: txtColor, fontSize: 11, fontWeight: FontWeight.bold),
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$w ${_uiText['weeksBeforeSuffix']!['EN']}',
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          softWrap: false,
                                          overflow: TextOverflow.fade,
                                          style: GoogleFonts.notoSerif(color: txtColor, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '시험$w${_uiText['weeksBeforeSuffix']!['KO']}',
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          softWrap: false,
                                          overflow: TextOverflow.fade,
                                          style: GoogleFonts.notoSerif(color: txtColor, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 3, right: 4),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Colors.redAccent),
                        ),
                        // 🆕 [12개국 연동] 기본값(KO/EN)=영문+한글 두 줄, 10개국 선택 시=해당 언어 한 줄
                        Expanded(
                          child: _biTitle(
                            'examPrepGuidance',
                            enStyle: GoogleFonts.notoSerif(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (_manualExamPrepWeek != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.redAccent),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.redAccent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '시험$_manualExamPrepWeek${_uiText['weeksBeforeSuffix']!['KO']} - ${_koOrForeign('examPrepManualWarning')}',
                                style: GoogleFonts.notoSerif(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(side: BorderSide(color: slate800)),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _examStartDate ?? DateTime.now(),
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2035),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.dark().copyWith(
                                      colorScheme: ColorScheme.dark(primary: goldColor, onPrimary: const Color(0xFF020617), surface: const Color(0xFF0B0F19), onSurface: Colors.white),
                                      dialogBackgroundColor: const Color(0xFF0B0F19),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  _examStartDate = picked;
                                });
                                await _saveExamSettings();
                              }
                            },
                            child: Text(
                              _examStartDate == null ? _koOrForeign('startDateSelect') : '${_examStartDate!.year}.${_examStartDate!.month}.${_examStartDate!.day}',
                              style: GoogleFonts.notoSerif(fontSize: 12, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('~', style: GoogleFonts.notoSerif(color: slate400)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(side: BorderSide(color: slate800)),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _examEndDate ?? (_examStartDate ?? DateTime.now()),
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2035),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.dark().copyWith(
                                      colorScheme: ColorScheme.dark(primary: goldColor, onPrimary: const Color(0xFF020617), surface: const Color(0xFF0B0F19), onSurface: Colors.white),
                                      dialogBackgroundColor: const Color(0xFF0B0F19),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  _examEndDate = picked;
                                });
                                await _saveExamSettings();
                              }
                            },
                            child: Text(
                              _examEndDate == null ? _koOrForeign('endDateSelect') : '${_examEndDate!.year}.${_examEndDate!.month}.${_examEndDate!.day}',
                              style: GoogleFonts.notoSerif(fontSize: 12, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: goldColor),
                      onPressed: _handleExamRecordFlow,
                      icon: const Icon(Icons.calendar_today, size: 14, color: Color(0xFF020617)),
                      // 🆕 [12개국 연동] 기본값(KO/EN)=영문+한글 두 줄, 10개국 선택 시=해당 언어 한 줄
                      label: _biTitle(
                        'addExamRecordBtnEn',
                        textAlign: TextAlign.center,
                        enStyle: GoogleFonts.notoSerif(color: const Color(0xFF020617), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_customExamRecords.isNotEmpty) ...[
                      Text('${_koOrForeign('registeredExamRecordsLabel')} (${_customExamRecords.length})', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._customExamRecords.asMap().entries.map((entry) {
                        int idx = entry.key;
                        Map<String, String> record = entry.value;
                        return GestureDetector(
                          onTap: () => _showEditExamRecordDialog(idx),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Text('[${record['date']}] ', style: GoogleFonts.notoSerif(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
                                Text('${record['subject']} : ', style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    '${_koOrForeign('rangeLabel')}: ${record['scope']}',
                                    style: GoogleFonts.notoSerif(color: slate400, fontSize: 12),
                                  ),
                                ),
                                Icon(Icons.edit, size: 12, color: slate500),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFF1E293B), height: 30),

        // 그려주신 스케치 구조 반영: 좌측(타이틀 + 추가 버튼) vs 우측(TIM 실행 버튼) 배치
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🆕 [버그 수정] 시험이 끝났으면(afterExamEnd) "준비 타임라인/D-day" 문구 대신
                  // 평상시로 복귀했음을 정확히 표시. (기존엔 시험이 끝나도 계속 D-day 문구가 남아있었음)
                  Text(
                    afterExamEnd
                        ? _koOrForeign('examEndedNormalEn')
                        : _isForeignSelected
                            ? '${_foreignOnly(_uiText[_isFinalExamMode ? "radioFinal" : "radioMidterm"]!)} ${_foreignOnly(_uiText['prepTimelineSuffix']!)}$dDayDisplay'
                            : '${_isFinalExamMode ? "기말고사" : "중간고사"} 준비 타임라인$dDayDisplay',
                    style: GoogleFonts.notoSerif(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAddButton(), // [수정] 제목 바로 아래, 왼쪽 정렬로 세로 배치
                      const SizedBox(width: 8),
                      _buildScheduleHeaderBar(showAddButton: false), // Edited/Reset 표시 (있을 때만)
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildTimButton(() => _getCurrentActiveSchedule()),
          ],
        ),
        const SizedBox(height: 12),
        ..._buildScheduleList(schedule),
      ],
    );
  }

  // ------------------------------------------------------------
  // 4. 시험 당일 트랙
  // ------------------------------------------------------------
  Widget _buildExamDayBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_enOrForeign('examDayTitleEn'), style: GoogleFonts.notoSerif(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_koOrForeign('examDaySubtitle'),
                      style: GoogleFonts.notoSerif(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buildTimButton(() => _getCurrentActiveSchedule()),
          ],
        ),
        const SizedBox(height: 16),
        _buildExamSettingsCardForExamDay(),
        const Divider(color: Color(0xFF1E293B), height: 30),
        _buildExamDayResult(),
      ],
    );
  }

  Widget _buildExamSettingsCardForExamDay() {
    String examDateText = _koOrForeign('examDayNoStartDate2');
    if (_examStartDate != null) {
      // 🆕 [0패딩] 월/일을 2자리로 고정 표기 (7 → 07)
      final String mm = _examStartDate!.month.toString().padLeft(2, '0');
      final String dd = _examStartDate!.day.toString().padLeft(2, '0');
      examDateText = '${_koOrForeign('examDayStartDatePrefix')}: ${_examStartDate!.year}.$mm.$dd';
    }

    return Container(
      decoration: BoxDecoration(
        color: slate800.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: slate800),
      ),
      child: ExpansionTile(
        // 🆕 [접기/펴기] EXAM INFO 섹션을 다른 화면(시험준비)과 동일하게 접었다 펼 수 있도록 전환
        initiallyExpanded: _isExamDaySettingExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExamDaySettingExpanded = expanded;
          });
        },
        collapsedTextColor: goldColor,
        textColor: goldColor,
        iconColor: goldColor,
        collapsedIconColor: slate400,
        title: Text(_biStr('examInfoInputTitle'), style: GoogleFonts.notoSerif(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: ['중간고사', '기말고사'].map((type) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 17.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<String>(
                            value: type,
                            groupValue: _isFinalExamMode ? '기말고사' : '중간고사',
                            activeColor: goldColor,
                            onChanged: (value) async {
                              setState(() {
                                _isFinalExamMode = (value == '기말고사');
                              });
                              await _saveExamSettings();
                            },
                          ),
                          Text(type, style: GoogleFonts.notoSerif(fontSize: 13, color: Colors.white)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(side: BorderSide(color: slate800)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _examStartDate ?? DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2035),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: ColorScheme.dark(primary: goldColor, onPrimary: const Color(0xFF020617), surface: const Color(0xFF0B0F19), onSurface: Colors.white),
                            dialogBackgroundColor: const Color(0xFF0B0F19),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        _examStartDate = picked;
                      });
                      await _saveExamSettings();
                    }
                  },
                  child: Text(
                    examDateText,
                    style: GoogleFonts.notoSerif(fontSize: 15, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamDayResult() {
    if (_examStartDate == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Text(_koOrForeign('examDayNoStartDate'),
            style: GoogleFonts.notoSerif(color: slate500, fontSize: 13)),
      );
    }

    // 🆕 [버그 수정] 시험이 끝난(종료일 23시 이후) 상태면, 실제 표시되는 시간표 내용은
    // (_getCurrentActiveSchedule에서) 이미 평상시로 복귀했는데도 이 위젯은 그 사실을 몰라서
    // D-day 범위(diff)만 보고 계속 "Exam Day Track (D+n)" 제목을 보여주던 문제를 수정.
    if (_isAfterExamEnd()) {
      List<Map<String, String>> normalSchedule = _getCurrentActiveSchedule();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _biTitle(
                  'examEndedNormalEn',
                  enStyle: GoogleFonts.notoSerif(color: goldColor, fontSize: 14, fontWeight: FontWeight.bold),
                  koStyle: GoogleFonts.notoSerif(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              _buildAddButton(),
            ],
          ),
          const SizedBox(height: 12),
          _buildScheduleHeaderBar(showAddButton: false),
          const SizedBox(height: 8),
          ..._buildScheduleList(normalSchedule),
        ],
      );
    }

    final DateTime today = DateTime.now();
    final DateTime cleanToday = DateTime(today.year, today.month, today.day);
    final DateTime cleanExamStart = DateTime(_examStartDate!.year, _examStartDate!.month, _examStartDate!.day);
    final int diff = cleanToday.difference(cleanExamStart).inDays;

    if (diff < -3 || diff > 4) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Text(
          '${_koOrForeign('examDayOutOfRangePrefix')} ${diff > 0 ? "D+$diff" : "D$diff"}${_koOrForeign('examDayIsSuffix')}',
          style: GoogleFonts.notoSerif(color: slate500, fontSize: 12),
        ),
      );
    }

    List<Map<String, String>> schedule = _getCurrentActiveSchedule();
    String dDayLabel = diff == 0 ? 'D-Day' : (diff < 0 ? 'D$diff' : 'D+$diff');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isForeignSelected
                        ? '${_foreignOnly(_uiText[_isFinalExamMode ? "radioFinal" : "radioMidterm"]!)} ${_foreignOnly(_uiText['dayTrackSuffix']!)} ($dDayLabel)'
                        : '${_isFinalExamMode ? "Final" : "Mid-term"} Exam Day Track ($dDayLabel)',
                    style: GoogleFonts.notoSerif(color: goldColor, fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 1, // [추가] 한 줄로 제한
                    overflow: TextOverflow.ellipsis, // [추가] 넘치면 "..." 표시
                  ),
                  if (!_isForeignSelected)
                    Text(
                      '${_isFinalExamMode ? "기말고사" : "중간고사"} 시험 당일 트랙 ($dDayLabel)',
                      style: GoogleFonts.notoSerif(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildAddButton(),
          ],
        ),
        const SizedBox(height: 12),
        _buildScheduleHeaderBar(showAddButton: false),
        const SizedBox(height: 8),
        ..._buildScheduleList(schedule),
      ],
    );
  }

// [추가] "+Add/항목 추가" 버튼만 별도로 분리 (시험준비 화면에서 재사용하기 위함)
  Widget _buildAddButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: slate800,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(0, 38), // 🆕 [탭 영역 확대] 기존 Size.zero → 최소 높이 38 확보
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      onPressed: () => _showEditItemDialog(),
      icon: const Icon(Icons.add, size: 14, color: Colors.white),
      label: Text(_biStr('addBtnLabel'), style: GoogleFonts.notoSerif(color: Colors.white, fontSize: 11)),
    );
  }

  Widget _buildScheduleHeaderBar({bool showAddButton = true}) {
    bool isCustomized = _customSchedules.containsKey(_getCurrentCacheKey());
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCustomized)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: goldColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                child: Text(_biStr('editedBadge'), style: GoogleFonts.notoSerif(color: goldColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            if (isCustomized)
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 30)),
                onPressed: _resetToDefaultSchedule,
                icon: const Icon(Icons.refresh, size: 14, color: Colors.amberAccent),
                label: Text(_enOrForeign('resetBtn'), style: GoogleFonts.notoSerif(color: Colors.amberAccent, fontSize: 11)),
              ),
          ],
        ),
        if (showAddButton) const SizedBox(width: 8),
        if (showAddButton) _buildAddButton(),
      ],
    );
  }
  List<Widget> _buildScheduleList(List<Map<String, String>> schedule) {
    if (schedule.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text(_biStr('noDataAvailable'), style: GoogleFonts.notoSerif(color: slate500, fontSize: 14)),
        )
      ];
    }
    return schedule.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, String> item = entry.value;

      final String timeText = item['time'] ?? '';
      final String taskText = item['task'] ?? '';
      final bool timePassed = _isTimePassed(timeText);

      final Color barColor = _getTimelineBarColor(_selectedTrack, timeText, taskText, index);

      final Color timeColor = timePassed ? slate500 : goldColor;
      final Color taskColor = timePassed ? slate400 : Colors.white;

      String engText = _getEnglishTaskTranslation(taskText);
      String korText = taskText;
      final bool isSelected = _selectedScheduleIndex == index;

      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedScheduleIndex = isSelected ? null : index;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? goldColor.withValues(alpha: 0.18)
                : (timePassed ? const Color(0xFF0F172A) : const Color(0xFF1E293B)),
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: goldColor, width: 2)
                : (timePassed ? Border.all(color: slate800.withValues(alpha: 0.5)) : null),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 92,
                child: Text(
                  timeText,
                  style: GoogleFonts.notoSerif(
                    color: isSelected ? goldColor : timeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 3.0,
                height: 32.0,
                color: isSelected ? goldColor : (timePassed ? slate500 : barColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      engText,
                      style: GoogleFonts.notoSerif(
                        color: taskColor.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      korTest(korText),
                      style: GoogleFonts.notoSerif(
                        color: isSelected ? Colors.white : taskColor,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, size: 20, color: Colors.amberAccent)
              else
                GestureDetector(
                  behavior: HitTestBehavior.opaque, // [추가] 투명 영역까지 탭 인식되도록
                  onTap: () => _showEditItemDialog(
                    index: index,
                    initialTime: timeText,
                    initialTask: taskText,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10), // [추가] 탭 가능 영역을 눈에 보이는 것보다 넓게 확장
                    child: Icon(
                      Icons.edit_note, // [수정] 자기주도플래너와 동일한 스타일 아이콘으로 교체
                      size: 20,
                      color: timePassed ? slate500 : goldColor.withValues(alpha: 0.85),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  String korTest(String kor) {
    return kor;
  }

  String _getEnglishTaskTranslation(String kor) {
    if (kor.contains('기상')) return 'Wake up & Stretching';
    if (kor.contains('아침식사')) return 'Breakfast';
    if (kor.contains('점심')) return 'Lunch & Break';
    if (kor.contains('저녁')) return 'Dinner & Break';
    if (kor.contains('휴식')) return 'Break Time';
    if (kor.contains('수학')) return 'Focused Mathematics';
    if (kor.contains('국어')) return 'Focused Korean Literature';
    if (kor.contains('영어')) return 'Focused English';
    if (kor.contains('과학')) return 'Focused Science';
    if (kor.contains('취침')) return 'Sleep & Bedtime Routine';
    if (kor.contains('학교')) return 'School Schedule';
    return 'Study Session';
  }
}
