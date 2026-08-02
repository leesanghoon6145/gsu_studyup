import 'dart:convert'; // [주석] 마스터 데이터 JSON 직렬화 및 역직렬화를 위한 패키지 임포트
import 'package:flutter/material.dart';
// [주석] 구글 폰트 패키지 임포트
import 'package:google_fonts/google_fonts.dart';
// [주석] 사용자의 마지막 제어 상태 및 마스터 데이터를 기기 내부에 영구 보존하기 위한 shared_preferences 임포트
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/study_timeline_section.dart'; // [주석] 새로 분가한 학습 타임라인 섹션 임포트
import 'widgets/planner_calendar_view.dart'; // [주석] 새로 분가한 플래너 달력 그리드 위젯 임포트
import 'widgets/daily_todo_list_section.dart'; // [주석] 새로 분가한 하루 주요 일정 섹션 임포트
import 'widgets/study_timelines.dart';
import '../global_lang.dart'; // 👑 [12개국 연동] 전역 언어 스위치와 연결
/// ============================================================================
/// [GKE StudyUp] 자기주도 학습 플래너 - 학습 계획 스크린 (planning_screen.dart)
/// ============================================================================
class PlanningScreen extends StatefulWidget {
  // [주석] 상위 컨트롤러에서 전달받을 필수 데이터 및 콜백 정의
  final DateTime selectedDate;
  final String currentWeekday;
  final List<String> mainSchedules;
  final Function(DateTime) onDateTap;

  const PlanningScreen({
    Key? key,
    required this.selectedDate,
    required this.currentWeekday,
    required this.mainSchedules,
    required this.onDateTap,
  }) : super(key: key);

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 👑 [주석] 탭 전환 시 화면 유지 및 버벅임 방지

  // [주석] 상단 [연간][월간][주간][일간] 4개 탭 제어 컨트롤러
  late TabController _tabController;

  // [주석] 카테고리별 테마 색상 (지시사항 엄격 준수)
  final Color schoolColor = const Color(0xFF3B82F6);  // 학교 일정 (파랑색)
  final Color academyColor = const Color(0xFFFACC15);   // 🆕 학원 일정 (노랑색으로 변경)
  final Color examColor = const Color(0xFFEF4444);    // 시험 일정 (빨강색)
  final Color personalColor = const Color(0xFF8B5CF6); // 🆕 개인 일정 (보라색으로 변경)
  final Color goldColor = const Color(0xFFD4AF37);     // 공식 황금색

  // [주석] 테마 컬러 상수 정의
  final Color slate300 = const Color(0xFFCBD5E1);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color slate500 = const Color(0xFF64748B);
  final Color slate800 = const Color(0xFF1E293B);

  // [주석] 확장 및 숨김 상태 제어 변수
  bool _isYearTargetExpanded = true;
  bool _isDayCalendarVisible = true;

  // [주석] 연간, 월간, 주간, 일간 독립형 이원화 선택 패널 제어 변수
  bool _isYearTargetSelected = true;
  bool _isMonthTargetSelected = true;
  bool _isWeekTimelineSelected = true;
  bool _isTimeViewSelected = true;

  // [주석] 연간 뷰 가로 스크롤 연도 리스트 (동적 생성 지원을 위해 가변 리스트로 변경)
  int _selectedYearIndex = 0;
  late List<String> _scrollableYears;

  // [주석] 월간 뷰 가로 스크롤 인덱스 (기본값: 0, initState에서 오늘 날짜 기준으로 동적 재매핑됨)
  int _selectedMonthIndex = 0;

  // [주석] 주간 뷰 가로 스크롤 주차 리스트
  int _selectedWeekIndex = 0;
  final List<String> _scrollableWeeks = ['1주차', '2주차', '3주차', '4주차', '5주차'];

  // 🆕 [2026-08-02] 주간(Week) 탭 전용 - "실제 캘린더 주(일~토)" 시작일(일요일) 상태 변수
  // 앱 진입(initState) 시 항상 오늘이 속한 실제 주의 일요일로 자동 설정됨. 이전 세션 상태를 복원하지
  // 않고 매번 "오늘이 속한 주"를 기본값으로 보여주는 것이 사용자 요구사항이므로 SharedPreferences에는
  // 저장/복원하지 않음 (탭 전환 중 KeepAlive로 인한 세션 내 유지만 허용됨).
  late DateTime _weekViewRangeStart;

  // 🆕 [2026-08-02] 주간 탭 - 칩 가로 스크롤 리스트 컨트롤러 및 "이번 주 최초 자동 중앙 정렬" 1회성 플래그
  // 🆕 [2026-08-03] 이전의 postFrameCallback/Timer 재시도 방식은 "빌드가 끝난 뒤 나중에 스크롤을
  // 밀어넣는" 방식이라 타이밍에 따라 실패하는 경우가 있었음. 이번에는 애초에 ScrollController를
  // 생성하는 시점에 MediaQuery로 화면 폭을 읽어 "이번 주가 중앙에 오는 시작 위치"를 계산해서
  // initialScrollOffset으로 바로 지정 — 화면이 그려지는 첫 프레임부터 정확한 위치에서 시작되므로
  // 재시도/타이밍 문제 자체가 발생하지 않음. late final이라 첫 사용 시 딱 한 번만 생성됨.
  late final ScrollController _weekChipScrollController;
  bool _weekChipScrollControllerReady = false;

  // [주석] 일간 뷰 동적 날짜 선택 변수 (기본값: DateTime.now() 오늘 날짜로 자동 매핑 및 결합)
  late DateTime _selectedDayDate;

  // ============================================================================
  // [GKE StudyUp] 글로벌 마스터 데이터 센터
  // ============================================================================
  late Map<String, List<Map<String, dynamic>>> _yearlyTargetsMap;
  // 🆕 [2026-08-03] 월간 "학습 리스트" 체크리스트 - 연간 목표 리스트와 동일한 방식(체크박스+줄긋기)으로
  // 동작하도록 함. 월(1~12) 번호를 키로 사용하며, 각 항목은 번역 카탈로그 키(labelKey)와 완료 여부(done)만
  // 저장함 — 실제 표시 문구는 언어 설정에 따라 _t(labelKey)로 매번 새로 생성되므로 다국어가 항상 정확함.
  late Map<int, List<Map<String, dynamic>>> _monthlyTargetsMap;
  late List<Map<String, dynamic>> _globalSchedules;

  // [주석] 5개 주차(0~4) × 7개 요일(1~7) 단위의 순환형 주간 고정 시간표 템플릿 마스터 (토/일 스펙 템플릿은 삭제됨)
  late Map<int, Map<int, List<Map<String, dynamic>>>> _weeklyTemplateMaster;

  // [주석] 사용자가 특정 날짜에 수행하고 완료(별 획득)한 실제 기록 인스턴스 저장소
  late Map<String, List<Map<String, dynamic>>> _dailyExecutionInstanceMap;

  // [주석] 일간 날짜별 정밀 고정 타임라인 관리 실시간 화면 매핑 변수
  late List<Map<String, dynamic>> _fixedDayTimelines;

  // [주석] 역방향 폭포수 연동을 위한 월간 실시간 달성도 지표 게이지 (0.0 ~ 1.0)
  double _monthlyProgressGauge = 0.0;

  // ============================================================================
  // 🆕 [12개국 언어 시스템] 기본 인프라
  // 기본값(마이페이지에서 12개국 중 하나를 고르기 전, 즉 DkeLang.current == 'KO' 상태 포함)은
  // 항상 "영문 + 한글"이 함께 보입니다. 한국어/영어를 "제외한" 나머지 10개국 중 하나를 선택했을
  // 때만 그 언어 단독으로 전환됩니다.
  // ============================================================================
  static const List<String> _foreignLanguages = ['JA', 'ZH', 'FR', 'DE', 'RU', 'AR', 'HI', 'VI', 'ES', 'TH'];
  static bool get _isForeignSelected => _foreignLanguages.contains(DkeLang.current);

  // 🆕 [12개국 UI 문구 카탈로그] + 조회 헬퍼 _t()
  static const Map<String, Map<String, String>> _uiText = {
    'tabYear': {'KO': '연간', 'EN': 'Year', 'JA': '年間', 'ZH': '年度', 'FR': 'Année', 'DE': 'Jahr', 'RU': 'Год', 'AR': 'سنوي', 'HI': 'वार्षिक', 'VI': 'Năm', 'ES': 'Año', 'TH': 'รายปี'},
    'tabMonth': {'KO': '월간', 'EN': 'Month', 'JA': '月間', 'ZH': '月度', 'FR': 'Mois', 'DE': 'Monat', 'RU': 'Месяц', 'AR': 'شهري', 'HI': 'मासिक', 'VI': 'Tháng', 'ES': 'Mes', 'TH': 'รายเดือน'},
    'tabWeek': {'KO': '주간', 'EN': 'Week', 'JA': '週間', 'ZH': '周度', 'FR': 'Semaine', 'DE': 'Woche', 'RU': 'Неделя', 'AR': 'أسبوعي', 'HI': 'साप्ताहिक', 'VI': 'Tuần', 'ES': 'Semana', 'TH': 'รายสัปดาห์'},
    'tabDay': {'KO': '일간', 'EN': 'Day', 'JA': '日別', 'ZH': '日度', 'FR': 'Jour', 'DE': 'Tag', 'RU': 'День', 'AR': 'يومي', 'HI': 'दैनिक', 'VI': 'Ngày', 'ES': 'Día', 'TH': 'รายวัน'},
    'sectionYearlyTarget': {'KO': '연간 계획 및 일정 제어', 'EN': 'Yearly Target System', 'JA': '年間計画・日程管理', 'ZH': '年度计划与日程管理', 'FR': 'Système d\'objectifs annuels', 'DE': 'Jahresziel-System', 'RU': 'Годовая система целей', 'AR': 'نظام الأهداف السنوية', 'HI': 'वार्षिक लक्ष्य प्रणाली', 'VI': 'Hệ thống mục tiêu hằng năm', 'ES': 'Sistema de objetivos anuales', 'TH': 'ระบบเป้าหมายรายปี'},
    'sectionMonthlyMgmt': {'KO': '월간 학습 계획 관리', 'EN': 'Monthly Management', 'JA': '月間学習計画管理', 'ZH': '月度学习计划管理', 'FR': 'Gestion mensuelle', 'DE': 'Monatliche Verwaltung', 'RU': 'Ежемесячное управление', 'AR': 'الإدارة الشهرية', 'HI': 'मासिक प्रबंधन', 'VI': 'Quản lý hằng tháng', 'ES': 'Gestión mensual', 'TH': 'การจัดการรายเดือน'},
    'sectionWeeklyAnalytics': {'KO': '주간 시간표 및 일정 스위칭', 'EN': 'Weekly Analytics', 'JA': '週間時間割・日程切替', 'ZH': '周课程表与日程切换', 'FR': 'Analyse hebdomadaire', 'DE': 'Wöchentliche Analyse', 'RU': 'Еженедельная аналитика', 'AR': 'التحليلات الأسبوعية', 'HI': 'साप्ताहिक विश्लेषण', 'VI': 'Phân tích hằng tuần', 'ES': 'Análisis semanal', 'TH': 'การวิเคราะห์รายสัปดาห์'},
    'sectionDailyScheduler': {'KO': '오늘 일정 관리 및 날짜 변경 레일', 'EN': 'Daily Scheduler Navi', 'JA': '本日の日程管理・日付変更', 'ZH': '今日日程管理与日期切换', 'FR': 'Planificateur quotidien', 'DE': 'Tagesplaner', 'RU': 'Ежедневный планировщик', 'AR': 'مخطط اليوم', 'HI': 'दैनिक शेड्यूलर', 'VI': 'Lịch trình hằng ngày', 'ES': 'Planificador diario', 'TH': 'ตัวจัดตารางรายวัน'},
    'yearTargetListWord': {'KO': '목표 리스트', 'EN': 'Target List', 'JA': '目標リスト', 'ZH': '目标清单', 'FR': 'Liste des objectifs', 'DE': 'Zielliste', 'RU': 'Список целей', 'AR': 'قائمة الأهداف', 'HI': 'लक्ष्य सूची', 'VI': 'Danh sách mục tiêu', 'ES': 'Lista de objetivos', 'TH': 'รายการเป้าหมาย'},
    'yearMainScheduleWord': {'KO': '주요 일정', 'EN': 'Main Schedule', 'JA': '主要日程', 'ZH': '主要日程', 'FR': 'Programme principal', 'DE': 'Hauptplan', 'RU': 'Основное расписание', 'AR': 'الجدول الرئيسي', 'HI': 'मुख्य कार्यक्रम', 'VI': 'Lịch chính', 'ES': 'Horario principal', 'TH': 'ตารางหลัก'},
    'monthTargetListWord': {'KO': '학습 리스트', 'EN': 'Target List', 'JA': '学習リスト', 'ZH': '学习清单', 'FR': 'Liste d\'étude', 'DE': 'Lernliste', 'RU': 'Список обучения', 'AR': 'قائمة الدراسة', 'HI': 'अध्ययन सूची', 'VI': 'Danh sách học tập', 'ES': 'Lista de estudio', 'TH': 'รายการการเรียน'},
    'weekTimelineWord': {'KO': '학습 타임라인', 'EN': 'Study Timeline', 'JA': '学習タイムライン', 'ZH': '学习时间线', 'FR': 'Chronologie d\'étude', 'DE': 'Lernzeitleiste', 'RU': 'Учебная хронология', 'AR': 'الجدول الزمني للدراسة', 'HI': 'अध्ययन समयरेखा', 'VI': 'Dòng thời gian học tập', 'ES': 'Cronología de estudio', 'TH': 'ไทม์ไลน์การเรียน'},
    'dateTimelineDetail': {'KO': '일정 타임라인 상세', 'EN': 'Date Timeline', 'JA': '日程タイムライン詳細', 'ZH': '日程时间线详情', 'FR': 'Détail chronologique', 'DE': 'Zeitleisten-Details', 'RU': 'Подробная хронология', 'AR': 'تفاصيل الجدول الزمني', 'HI': 'विस्तृत समयरेखा', 'VI': 'Chi tiết dòng thời gian', 'ES': 'Detalle de cronología', 'TH': 'รายละเอียดไทม์ไลน์'},
    'todayMainSchedule': {'KO': '오늘 주요 일정', 'EN': 'Main Schedule', 'JA': '本日の主要日程', 'ZH': '今日主要日程', 'FR': 'Programme du jour', 'DE': 'Heutiger Hauptplan', 'RU': 'Основное расписание на сегодня', 'AR': 'الجدول الرئيسي لليوم', 'HI': 'आज का मुख्य कार्यक्रम', 'VI': 'Lịch chính hôm nay', 'ES': 'Horario principal de hoy', 'TH': 'ตารางหลักวันนี้'},
    'achievementGauge': {'KO': '월간 달성도 게이지', 'EN': 'Monthly Achievement Gauge', 'JA': '月間達成度ゲージ', 'ZH': '月度达成度仪表', 'FR': 'Jauge de réussite mensuelle', 'DE': 'Monatliche Erfolgsanzeige', 'RU': 'Индикатор месячных достижений', 'AR': 'مؤشر الإنجاز الشهري', 'HI': 'मासिक उपलब्धि गेज', 'VI': 'Thước đo thành tích hằng tháng', 'ES': 'Indicador de logro mensual', 'TH': 'มาตรวัดความสำเร็จรายเดือน'},
    'emptyYearTarget': {'KO': '등록된 연간 목표 목표치가 없습니다.', 'EN': 'No yearly targets registered yet.', 'JA': '登録された年間目標がありません。', 'ZH': '尚未登记年度目标。', 'FR': 'Aucun objectif annuel enregistré.', 'DE': 'Keine Jahresziele registriert.', 'RU': 'Годовые цели ещё не добавлены.', 'AR': 'لا توجد أهداف سنوية مسجلة.', 'HI': 'कोई वार्षिक लक्ष्य दर्ज नहीं है।', 'VI': 'Chưa có mục tiêu năm nào được đăng ký.', 'ES': 'Aún no hay objetivos anuales registrados.', 'TH': 'ยังไม่มีการลงทะเบียนเป้าหมายรายปี'},
    'emptyYearSchedule': {'KO': '해당 연도에 편성된 주요 일정이 없습니다.', 'EN': 'No main schedules for this year yet.', 'JA': 'この年に登録された主要日程がありません。', 'ZH': '该年度暂无主要日程。', 'FR': 'Aucun programme principal pour cette année.', 'DE': 'Keine Hauptpläne für dieses Jahr.', 'RU': 'На этот год пока нет расписания.', 'AR': 'لا يوجد جدول رئيسي لهذا العام.', 'HI': 'इस वर्ष के लिए कोई मुख्य कार्यक्रम नहीं है।', 'VI': 'Chưa có lịch chính nào cho năm này.', 'ES': 'Aún no hay horarios principales para este año.', 'TH': 'ยังไม่มีตารางหลักสำหรับปีนี้'},
    'emptyMonthSchedule': {'KO': '해당 월에 배정된 메인 주요 일정이 존재하지 않습니다.', 'EN': 'No main schedules assigned for this month.', 'JA': 'この月に割り当てられた主要日程がありません。', 'ZH': '该月暂无分配的主要日程。', 'FR': 'Aucun programme principal ce mois-ci.', 'DE': 'Keine Hauptpläne für diesen Monat.', 'RU': 'На этот месяц расписание не назначено.', 'AR': 'لا يوجد جدول رئيسي مخصص لهذا الشهر.', 'HI': 'इस महीने के लिए कोई मुख्य कार्यक्रम निर्धारित नहीं है।', 'VI': 'Chưa có lịch chính nào được gán cho tháng này.', 'ES': 'No hay horarios principales asignados para este mes.', 'TH': 'ไม่มีตารางหลักที่กำหนดไว้สำหรับเดือนนี้'},
    'emptyDaySchedule': {'KO': '해당 날짜에 등록된 일정이 없습니다.', 'EN': 'No schedule registered for this date.', 'JA': 'この日に登録された日程がありません。', 'ZH': '该日期暂无已登记的日程。', 'FR': 'Aucun programme enregistré pour cette date.', 'DE': 'Kein Termin für dieses Datum registriert.', 'RU': 'На эту дату расписание не добавлено.', 'AR': 'لا يوجد جدول مسجل لهذا التاريخ.', 'HI': 'इस तारीख के लिए कोई शेड्यूल दर्ज नहीं है।', 'VI': 'Chưa có lịch nào được đăng ký cho ngày này.', 'ES': 'No hay horario registrado para esta fecha.', 'TH': 'ไม่มีตารางที่ลงทะเบียนไว้สำหรับวันที่นี้'},
    'emptyDayMainSchedule2': {'KO': '해당 날짜에 등록된 주요 일정이 없습니다.', 'EN': 'No main schedule registered for this date.', 'JA': 'この日に登録された主要日程がありません。', 'ZH': '该日期暂无已登记的主要日程。', 'FR': 'Aucun programme principal enregistré pour cette date.', 'DE': 'Kein Hauptplan für dieses Datum registriert.', 'RU': 'На эту дату основное расписание не добавлено.', 'AR': 'لا يوجد جدول رئيسي مسجل لهذا التاريخ.', 'HI': 'इस तारीख के लिए कोई मुख्य कार्यक्रम दर्ज नहीं है।', 'VI': 'Chưa có lịch chính nào được đăng ký cho ngày này.', 'ES': 'No hay horario principal registrado para esta fecha.', 'TH': 'ไม่มีตารางหลักที่ลงทะเบียนไว้สำหรับวันที่นี้'},
    'monthMasterPack': {'KO': '핵심 학습 마스터 팩', 'EN': 'Core Study Master Pack', 'JA': 'コア学習マスターパック', 'ZH': '核心学习方案包', 'FR': 'Pack maître d\'étude essentiel', 'DE': 'Kernlern-Masterpaket', 'RU': 'Основной учебный пакет', 'AR': 'حزمة الدراسة الأساسية', 'HI': 'मुख्य अध्ययन पैक', 'VI': 'Gói học tập cốt lõi', 'ES': 'Paquete maestro de estudio', 'TH': 'แพ็กเรียนหลัก'},
    'monthPrepScheduleItem': {'KO': '내신 선행 진도 격파 스케줄', 'EN': 'Advance progress breakthrough schedule', 'JA': '内申先取り進度攻略スケジュール', 'ZH': '内部成绩超前进度攻克计划', 'FR': 'Programme d\'avance sur le programme scolaire', 'DE': 'Vorlauf-Fortschrittsplan', 'RU': 'График опережающего изучения программы', 'AR': 'جدول تجاوز المنهج المسبق', 'HI': 'पाठ्यक्रम अग्रिम प्रगति योजना', 'VI': 'Lịch trình vượt tiến độ chương trình', 'ES': 'Cronograma de avance del programa escolar', 'TH': 'ตารางเร่งความก้าวหน้าล่วงหน้า'},
    'monthMockExamItem': {'KO': '모의고사 취약 유형 누적 복습 트랙', 'EN': 'Mock exam weak-type review track', 'JA': '模試弱点タイプ累積復習トラック', 'ZH': '模拟考试薄弱题型累积复习计划', 'FR': 'Révision des points faibles aux examens blancs', 'DE': 'Übungsprüfung-Schwachpunkte-Wiederholung', 'RU': 'Повторение слабых мест пробных экзаменов', 'AR': 'مراجعة نقاط الضعف في الاختبارات التجريبية', 'HI': 'मॉक परीक्षा कमजोर प्रकार समीक्षा ट्रैक', 'VI': 'Lộ trình ôn tập điểm yếu qua thi thử', 'ES': 'Repaso de puntos débiles en exámenes simulados', 'TH': 'แทร็กทบทวนจุดอ่อนจากข้อสอบจำลอง'},
    'monthStarCollectItem': {'KO': '별 수집 목표 달성 트랙', 'EN': 'Star collection achievement track', 'JA': '星収集達成トラック', 'ZH': '星星收集达成计划', 'FR': 'Suivi de collecte des étoiles', 'DE': 'Sternesammel-Fortschritt', 'RU': 'Трек сбора звёзд', 'AR': 'مسار جمع النجوم', 'HI': 'स्टार संग्रह ट्रैक', 'VI': 'Lộ trình thu thập sao', 'ES': 'Seguimiento de recolección de estrellas', 'TH': 'แทร็กสะสมดาว'},
    'weekendMockExamBinding': {'KO': '주말 전국단위 오프라인 모의평가 스케줄 바인딩', 'EN': 'Weekend nationwide offline mock exam schedule', 'JA': '週末全国オフライン模試スケジュール連携', 'ZH': '周末全国线下模拟考试日程绑定', 'FR': 'Programme d\'examen blanc national le week-end', 'DE': 'Wochenend-Testprüfung landesweit', 'RU': 'Расписание общенационального пробного экзамена по выходным', 'AR': 'جدول الاختبار التجريبي الوطني في عطلة نهاية الأسبوع', 'HI': 'सप्ताहांत राष्ट्रव्यापी मॉक परीक्षा शेड्यूल', 'VI': 'Lịch thi thử toàn quốc cuối tuần', 'ES': 'Programa de examen simulado nacional de fin de semana', 'TH': 'ตารางข้อสอบจำลองทั่วประเทศช่วงสุดสัปดาห์'},
    'weekdayLectureCheck': {'KO': '주중 피드백 심화 인강 주기적 스트리밍 점검', 'EN': 'Weekday feedback lecture streaming check', 'JA': '平日フィードバック講義配信定期チェック', 'ZH': '工作日反馈深化网课定期检查', 'FR': 'Vérification des cours vidéo en semaine', 'DE': 'Wochentags-Feedback-Kursprüfung', 'RU': 'Проверка потоковых лекций по будням', 'AR': 'فحص دوري لبث محاضرات التغذية الراجعة أيام الأسبوع', 'HI': 'सप्ताह के दिनों की फीडबैक लेक्चर स्ट्रीमिंग जांच', 'VI': 'Kiểm tra định kỳ video bài giảng phản hồi trong tuần', 'ES': 'Revisión periódica de clases en video entre semana', 'TH': 'ตรวจสอบการสตรีมวิดีโอฟีดแบ็กประจำวันธรรมดา'},
    'weekdayTemplateOverview': {'KO': '요일별 고정 기본 템플릿 정보 조망', 'EN': 'Weekday fixed template overview', 'JA': '曜日別固定テンプレート概要', 'ZH': '按星期查看固定模板概览', 'FR': 'Aperçu du modèle fixe par jour', 'DE': 'Übersicht des Wochentag-Vorlage', 'RU': 'Обзор фиксированного шаблона по дням недели', 'AR': 'نظرة عامة على القالب الثابت حسب أيام الأسبوع', 'HI': 'सप्ताह के दिन के अनुसार निश्चित टेम्पलेट अवलोकन', 'VI': 'Tổng quan mẫu cố định theo từng ngày', 'ES': 'Resumen de plantilla fija por día de la semana', 'TH': 'ภาพรวมเทมเพลตคงที่รายวัน'},
    'weeklyFixedBriefing': {'KO': '주간 고정 결합 일정 브리핑', 'EN': 'Weekly fixed schedule briefing', 'JA': '週間固定連携日程ブリーフィング', 'ZH': '周固定联动日程简报', 'FR': 'Résumé du programme hebdomadaire fixe', 'DE': 'Wöchentliches Fixplan-Briefing', 'RU': 'Сводка фиксированного недельного расписания', 'AR': 'ملخص الجدول الأسبوعي الثابت', 'HI': 'साप्ताहिक निश्चित शेड्यूल ब्रीफिंग', 'VI': 'Tóm tắt lịch cố định hằng tuần', 'ES': 'Resumen del horario semanal fijo', 'TH': 'สรุปตารางคงที่รายสัปดาห์'},
    'selfStudyDefaultTrack': {'KO': '자율 학습 설정 트랙', 'EN': 'Self-directed study track', 'JA': '自律学習設定トラック', 'ZH': '自主学习设置轨道', 'FR': 'Piste d\'étude autonome', 'DE': 'Selbststudium-Track', 'RU': 'Трек самостоятельного обучения', 'AR': 'مسار الدراسة الذاتية', 'HI': 'स्व-अध्ययन ट्रैक', 'VI': 'Lộ trình tự học', 'ES': 'Pista de estudio autónomo', 'TH': 'แทร็กการเรียนด้วยตนเอง'},
    'fixedTemplateRoutineMemo': {'KO': '순환형 주차 톱니바퀴 결합에 따른 고정 템플릿 루틴 구간입니다.', 'EN': 'A fixed routine segment based on the rotating weekly cycle.', 'JA': '循環型週次サイクルに基づく固定テンプレートルーティン区間です。', 'ZH': '基于循环周周期的固定模板例程区段。', 'FR': 'Segment de routine fixe basé sur le cycle hebdomadaire rotatif.', 'DE': 'Fester Routineabschnitt basierend auf dem rotierenden Wochenzyklus.', 'RU': 'Фиксированный сегмент рутины на основе циклической недельной ротации.', 'AR': 'قطاع روتيني ثابت يعتمد على الدورة الأسبوعية المتناوبة.', 'HI': 'यह घूर्णन साप्ताहिक चक्र पर आधारित एक निश्चित नियमित खंड है।', 'VI': 'Đây là đoạn quy trình cố định dựa trên chu kỳ tuần luân phiên.', 'ES': 'Un segmento de rutina fija basado en el ciclo semanal rotativo.', 'TH': 'ส่วนกิจวัตรคงที่ตามรอบสัปดาห์แบบหมุนเวียน'},
    'fixedTemplateLabel': {'KO': '고정 템플릿', 'EN': 'Fixed Template', 'JA': '固定テンプレート', 'ZH': '固定模板', 'FR': 'Modèle fixe', 'DE': 'Feste Vorlage', 'RU': 'Фиксированный шаблон', 'AR': 'قالب ثابت', 'HI': 'निश्चित टेम्पलेट', 'VI': 'Mẫu cố định', 'ES': 'Plantilla fija', 'TH': 'เทมเพลตคงที่'},
    'todayStatusLabel': {'KO': '오늘의 일정상태', 'EN': 'Today\'s Status', 'JA': '本日の日程状況', 'ZH': '今日日程状态', 'FR': 'Statut du jour', 'DE': 'Heutiger Status', 'RU': 'Статус на сегодня', 'AR': 'حالة اليوم', 'HI': 'आज की स्थिति', 'VI': 'Tình trạng hôm nay', 'ES': 'Estado de hoy', 'TH': 'สถานะวันนี้'},
    'selectedDateToday': {'KO': '선택 날짜 / 오늘 상태', 'EN': 'Selected Date / Today Status', 'JA': '選択日 / 本日の状況', 'ZH': '所选日期／今日状态', 'FR': 'Date sélectionnée / Statut du jour', 'DE': 'Gewähltes Datum / Heutiger Status', 'RU': 'Выбранная дата / статус на сегодня', 'AR': 'التاريخ المحدد / حالة اليوم', 'HI': 'चयनित तिथि / आज की स्थिति', 'VI': 'Ngày đã chọn / Trạng thái hôm nay', 'ES': 'Fecha seleccionada / Estado de hoy', 'TH': 'วันที่เลือก / สถานะวันนี้'},
    'selectedDateArchive': {'KO': '선택 날짜 / 기록 상태', 'EN': 'Selected Date / Archive Status', 'JA': '選択日 / 記録状況', 'ZH': '所选日期／记录状态', 'FR': 'Date sélectionnée / Statut archivé', 'DE': 'Gewähltes Datum / Archivstatus', 'RU': 'Выбранная дата / статус архива', 'AR': 'التاريخ المحدد / حالة الأرشيف', 'HI': 'चयनित तिथि / अभिलेख स्थिति', 'VI': 'Ngày đã chọn / Trạng thái lưu trữ', 'ES': 'Fecha seleccionada / Estado archivado', 'TH': 'วันที่เลือก / สถานะที่บันทึกไว้'},
    'gradeWeekPrefix': {'KO': '주차', 'EN': 'Week', 'JA': '週', 'ZH': '第 周', 'FR': 'Semaine', 'DE': 'Woche', 'RU': 'Неделя', 'AR': 'الأسبوع', 'HI': 'सप्ताह', 'VI': 'Tuần', 'ES': 'Semana', 'TH': 'สัปดาห์'},
    'yearTargetWord': {'KO': '목표', 'EN': 'Target', 'JA': '目標', 'ZH': '目标', 'FR': 'Objectif', 'DE': 'Ziel', 'RU': 'Цель', 'AR': 'الهدف', 'HI': 'लक्ष्य', 'VI': 'Mục tiêu', 'ES': 'Objetivo', 'TH': 'เป้าหมาย'},

    // 🆕 [C범위] 팝업/다이얼로그 신규 카탈로그
    'popupDateMainSchedulesTitle': {'KO': '주요 일정 브리핑', 'EN': 'Main Schedule Briefing', 'JA': '主要日程ブリーフィング', 'ZH': '主要日程简报', 'FR': 'Résumé du programme principal', 'DE': 'Hauptplan-Briefing', 'RU': 'Сводка основного расписания', 'AR': 'ملخص الجدول الرئيسي', 'HI': 'मुख्य कार्यक्रम ब्रीफिंग', 'VI': 'Tóm tắt lịch chính', 'ES': 'Resumen del horario principal', 'TH': 'สรุปตารางหลัก'},
    'popupAddCalendarEntryTitle': {'KO': '새 주요 일정 추가', 'EN': 'Add New Calendar Entry', 'JA': '新規主要日程追加', 'ZH': '添加新的主要日程', 'FR': 'Ajouter un nouveau programme', 'DE': 'Neuen Termin hinzufügen', 'RU': 'Добавить новое расписание', 'AR': 'إضافة جدول رئيسي جديد', 'HI': 'नया मुख्य कार्यक्रम जोड़ें', 'VI': 'Thêm lịch chính mới', 'ES': 'Añadir nuevo horario principal', 'TH': 'เพิ่มตารางหลักใหม่'},
    'popupMissionDetailsTitle': {'KO': '학습 계획 상세 조회', 'EN': 'Study Plan Details', 'JA': '学習計画詳細照会', 'ZH': '学习计划详情查看', 'FR': 'Détails du plan d\'étude', 'DE': 'Lernplan-Details', 'RU': 'Подробности учебного плана', 'AR': 'تفاصيل خطة الدراسة', 'HI': 'अध्ययन योजना विवरण', 'VI': 'Chi tiết kế hoạch học tập', 'ES': 'Detalles del plan de estudio', 'TH': 'รายละเอียดแผนการเรียน'},
    'popupEditModeTitle': {'KO': '학습 계획 편집 및 변경', 'EN': 'Edit Study Plan', 'JA': '学習計画編集・変更', 'ZH': '学习计划编辑与修改', 'FR': 'Modifier le plan d\'étude', 'DE': 'Lernplan bearbeiten', 'RU': 'Изменить учебный план', 'AR': 'تعديل خطة الدراسة', 'HI': 'अध्ययन योजना संपादित करें', 'VI': 'Chỉnh sửa kế hoạch học tập', 'ES': 'Editar el plan de estudio', 'TH': 'แก้ไขแผนการเรียน'},
    'popupAddNewEntryTitle': {'KO': '새 리스트 추가하기', 'EN': 'Add New List Item', 'JA': '新規リスト追加', 'ZH': '添加新列表项', 'FR': 'Ajouter un nouvel élément', 'DE': 'Neuen Listeneintrag hinzufügen', 'RU': 'Добавить новый элемент', 'AR': 'إضافة عنصر قائمة جديد', 'HI': 'नई सूची आइटम जोड़ें', 'VI': 'Thêm mục danh sách mới', 'ES': 'Añadir nuevo elemento a la lista', 'TH': 'เพิ่มรายการใหม่'},
    'btnClose': {'KO': '닫기', 'EN': 'Close', 'JA': '閉じる', 'ZH': '关闭', 'FR': 'Fermer', 'DE': 'Schließen', 'RU': 'Закрыть', 'AR': 'إغلاق', 'HI': 'बंद करें', 'VI': 'Đóng', 'ES': 'Cerrar', 'TH': 'ปิด'},
    'btnAdd': {'KO': '일정 추가', 'EN': 'Add', 'JA': '日程追加', 'ZH': '添加日程', 'FR': 'Ajouter', 'DE': 'Hinzufügen', 'RU': 'Добавить', 'AR': 'إضافة', 'HI': 'जोड़ें', 'VI': 'Thêm', 'ES': 'Añadir', 'TH': 'เพิ่ม'},
    'btnSaveApply': {'KO': '일정 등록 저장하기', 'EN': 'Save & Apply', 'JA': '登録・保存する', 'ZH': '保存并应用', 'FR': 'Enregistrer et appliquer', 'DE': 'Speichern & anwenden', 'RU': 'Сохранить и применить', 'AR': 'حفظ وتطبيق', 'HI': 'सहेजें और लागू करें', 'VI': 'Lưu và áp dụng', 'ES': 'Guardar y aplicar', 'TH': 'บันทึกและใช้งาน'},
    'btnSaveApplyLink': {'KO': '저장 및 연동 적용하기', 'EN': 'Save & Apply', 'JA': '保存・連携適用する', 'ZH': '保存并联动应用', 'FR': 'Enregistrer et lier', 'DE': 'Speichern & verknüpfen', 'RU': 'Сохранить и связать', 'AR': 'حفظ وربط', 'HI': 'सहेजें और लिंक करें', 'VI': 'Lưu và liên kết', 'ES': 'Guardar y vincular', 'TH': 'บันทึกและเชื่อมโยง'},
    'btnEdit': {'KO': '수정·삭제', 'EN': 'Edit', 'JA': '編集・削除', 'ZH': '编辑·删除', 'FR': 'Modifier', 'DE': 'Bearbeiten', 'RU': 'Изменить', 'AR': 'تعديل', 'HI': 'संपादित करें', 'VI': 'Chỉnh sửa', 'ES': 'Editar', 'TH': 'แก้ไข'},
    'btnDelete': {'KO': '삭제', 'EN': 'Delete', 'JA': '削除', 'ZH': '删除', 'FR': 'Supprimer', 'DE': 'Löschen', 'RU': 'Удалить', 'AR': 'حذف', 'HI': 'हटाएं', 'VI': 'Xóa', 'ES': 'Eliminar', 'TH': 'ลบ'},
    'btnSave': {'KO': '저장', 'EN': 'Save', 'JA': '保存', 'ZH': '保存', 'FR': 'Enregistrer', 'DE': 'Speichern', 'RU': 'Сохранить', 'AR': 'حفظ', 'HI': 'सहेजें', 'VI': 'Lưu', 'ES': 'Guardar', 'TH': 'บันทึก'},
    'labelTime': {'KO': '시간 설정', 'EN': 'Time', 'JA': '時間設定', 'ZH': '时间设置', 'FR': 'Heure', 'DE': 'Uhrzeit', 'RU': 'Время', 'AR': 'الوقت', 'HI': 'समय', 'VI': 'Thời gian', 'ES': 'Hora', 'TH': 'เวลา'},
    'labelTitleField': {'KO': '계획 명칭', 'EN': 'Title', 'JA': '計画名称', 'ZH': '计划名称', 'FR': 'Titre', 'DE': 'Titel', 'RU': 'Название', 'AR': 'العنوان', 'HI': 'शीर्षक', 'VI': 'Tiêu đề', 'ES': 'Título', 'TH': 'ชื่อเรื่อง'},
    'labelCategory': {'KO': '학습 형태', 'EN': 'Category', 'JA': '学習形態', 'ZH': '学习形式', 'FR': 'Catégorie', 'DE': 'Kategorie', 'RU': 'Категория', 'AR': 'الفئة', 'HI': 'श्रेणी', 'VI': 'Danh mục', 'ES': 'Categoría', 'TH': 'หมวดหมู่'},
    'labelTextbook': {'KO': '교재 정보', 'EN': 'Textbook', 'JA': '教材情報', 'ZH': '教材信息', 'FR': 'Manuel', 'DE': 'Lehrbuch', 'RU': 'Учебник', 'AR': 'الكتاب المدرسي', 'HI': 'पाठ्यपुस्तक', 'VI': 'Sách giáo khoa', 'ES': 'Libro de texto', 'TH': 'หนังสือเรียน'},
    'labelMemo': {'KO': '상세 계획', 'EN': 'Memo', 'JA': '詳細計画', 'ZH': '详细计划', 'FR': 'Mémo', 'DE': 'Notiz', 'RU': 'Заметка', 'AR': 'ملاحظة', 'HI': 'ज्ञापन', 'VI': 'Ghi chú', 'ES': 'Nota', 'TH': 'บันทึกช่วยจำ'},
    'labelNoMemo': {'KO': '기록된 메모 내역이 존재하지 않습니다.', 'EN': 'No memo recorded.', 'JA': '記録されたメモがありません。', 'ZH': '暂无记录的备注。', 'FR': 'Aucune note enregistrée.', 'DE': 'Keine Notiz vorhanden.', 'RU': 'Заметок нет.', 'AR': 'لا توجد ملاحظة مسجلة.', 'HI': 'कोई ज्ञापन दर्ज नहीं है।', 'VI': 'Chưa có ghi chú nào.', 'ES': 'No hay ninguna nota registrada.', 'TH': 'ไม่มีบันทึกที่บันทึกไว้'},
    'labelAllDay': {'KO': '종일 설정됨', 'EN': 'All day', 'JA': '終日設定', 'ZH': '全天', 'FR': 'Toute la journée', 'DE': 'Ganztägig', 'RU': 'Весь день', 'AR': 'طوال اليوم', 'HI': 'पूरा दिन', 'VI': 'Cả ngày', 'ES': 'Todo el día', 'TH': 'ทั้งวัน'},
    'starCollected': {'KO': '별 수집 완료', 'EN': 'Star Collected', 'JA': '星収集完了', 'ZH': '星星收集完成', 'FR': 'Étoile collectée', 'DE': 'Stern gesammelt', 'RU': 'Звезда собрана', 'AR': 'تم جمع النجمة', 'HI': 'स्टार एकत्रित', 'VI': 'Đã thu thập sao', 'ES': 'Estrella recolectada', 'TH': 'เก็บดาวแล้ว'},
    'starCollectAction': {'KO': '미션 완료! 별 수집하기', 'EN': 'Complete! Collect Star', 'JA': 'ミッション完了！星を集める', 'ZH': '任务完成！收集星星', 'FR': 'Mission accomplie ! Collecter l\'étoile', 'DE': 'Erledigt! Stern sammeln', 'RU': 'Готово! Собрать звезду', 'AR': 'اكتملت! اجمع النجمة', 'HI': 'पूर्ण! स्टार एकत्र करें', 'VI': 'Hoàn thành! Thu thập sao', 'ES': '¡Completado! Recolectar estrella', 'TH': 'สำเร็จ! เก็บดาว'},
    'labelCategorySelect': {'KO': '일정 분류', 'EN': 'Category', 'JA': '日程分類', 'ZH': '日程分类', 'FR': 'Catégorie du programme', 'DE': 'Terminkategorie', 'RU': 'Категория расписания', 'AR': 'تصنيف الجدول', 'HI': 'कार्यक्रम श्रेणी', 'VI': 'Phân loại lịch', 'ES': 'Categoría del horario', 'TH': 'หมวดหมู่ตาราง'},
    'hintScheduleTitle': {'KO': '간단한 일정 제목을 입력하세요', 'EN': 'Enter a brief schedule title', 'JA': '簡単な日程タイトルを入力してください', 'ZH': '请输入简短的日程标题', 'FR': 'Saisissez un titre de programme', 'DE': 'Kurzen Termintitel eingeben', 'RU': 'Введите краткое название', 'AR': 'أدخل عنوانًا موجزًا للجدول', 'HI': 'संक्षिप्त कार्यक्रम शीर्षक दर्ज करें', 'VI': 'Nhập tiêu đề lịch ngắn gọn', 'ES': 'Ingrese un título breve del horario', 'TH': 'กรอกชื่อตารางแบบสั้น'},
    'hintScheduleDetail': {'KO': '상세 일정 내용(메모)을 입력하세요', 'EN': 'Enter schedule details (memo)', 'JA': '詳細な日程内容(メモ)を入力してください', 'ZH': '请输入详细日程内容(备注)', 'FR': 'Saisissez les détails (mémo)', 'DE': 'Termindetails (Notiz) eingeben', 'RU': 'Введите подробности (заметка)', 'AR': 'أدخل تفاصيل الجدول (ملاحظة)', 'HI': 'विवरण दर्ज करें (ज्ञापन)', 'VI': 'Nhập chi tiết lịch (ghi chú)', 'ES': 'Ingrese los detalles (nota)', 'TH': 'กรอกรายละเอียด (บันทึกช่วยจำ)'},
    'hintTitleGeneric': {'KO': '일정 제목', 'EN': 'Title', 'JA': '日程タイトル', 'ZH': '日程标题', 'FR': 'Titre du programme', 'DE': 'Termintitel', 'RU': 'Название расписания', 'AR': 'عنوان الجدول', 'HI': 'कार्यक्रम शीर्षक', 'VI': 'Tiêu đề lịch', 'ES': 'Título del horario', 'TH': 'ชื่อตาราง'},
    'hintTargetGeneric': {'KO': '목표 내용', 'EN': 'Target Content', 'JA': '目標内容', 'ZH': '目标内容', 'FR': 'Contenu de l\'objectif', 'DE': 'Zielinhalt', 'RU': 'Содержание цели', 'AR': 'محتوى الهدف', 'HI': 'लक्ष्य सामग्री', 'VI': 'Nội dung mục tiêu', 'ES': 'Contenido del objetivo', 'TH': 'เนื้อหาเป้าหมาย'},
    'hintMonth': {'KO': '월 숫자', 'EN': 'Month', 'JA': '月数値', 'ZH': '月份数字', 'FR': 'Mois', 'DE': 'Monat', 'RU': 'Месяц', 'AR': 'الشهر', 'HI': 'महीना', 'VI': 'Tháng', 'ES': 'Mes', 'TH': 'เดือน'},
    'hintDay': {'KO': '일 숫자', 'EN': 'Day', 'JA': '日数値', 'ZH': '日期数字', 'FR': 'Jour', 'DE': 'Tag', 'RU': 'День', 'AR': 'اليوم', 'HI': 'दिन', 'VI': 'Ngày', 'ES': 'Día', 'TH': 'วัน'},
    'hintMemoPlan': {'KO': '상세 내용 계획 기입', 'EN': 'Enter detailed plan', 'JA': '詳細計画を記入', 'ZH': '填写详细计划内容', 'FR': 'Saisissez le plan détaillé', 'DE': 'Detaillierten Plan eingeben', 'RU': 'Введите подробный план', 'AR': 'أدخل الخطة التفصيلية', 'HI': 'विस्तृत योजना दर्ज करें', 'VI': 'Nhập kế hoạch chi tiết', 'ES': 'Ingrese el plan detallado', 'TH': 'กรอกแผนโดยละเอียด'},
    'entryTypeSchedule': {'KO': '일정', 'EN': 'Schedule', 'JA': '日程', 'ZH': '日程', 'FR': 'Programme', 'DE': 'Termin', 'RU': 'Расписание', 'AR': 'الجدول', 'HI': 'कार्यक्रम', 'VI': 'Lịch', 'ES': 'Horario', 'TH': 'ตาราง'},
    'entryTypeTarget': {'KO': '목표', 'EN': 'Target', 'JA': '目標', 'ZH': '目标', 'FR': 'Objectif', 'DE': 'Ziel', 'RU': 'Цель', 'AR': 'الهدف', 'HI': 'लक्ष्य', 'VI': 'Mục tiêu', 'ES': 'Objetivo', 'TH': 'เป้าหมาย'},
    'catSchool': {'KO': '학교', 'EN': 'School', 'JA': '学校', 'ZH': '学校', 'FR': 'École', 'DE': 'Schule', 'RU': 'Школа', 'AR': 'المدرسة', 'HI': 'स्कूल', 'VI': 'Trường học', 'ES': 'Escuela', 'TH': 'โรงเรียน'},
    'catCompany': {'KO': '회사', 'EN': 'Work', 'JA': '会社', 'ZH': '公司', 'FR': 'Travail', 'DE': 'Arbeit', 'RU': 'Работа', 'AR': 'العمل', 'HI': 'कार्य', 'VI': 'Công ty', 'ES': 'Trabajo', 'TH': 'บริษัท'},
    'catAcademy': {'KO': '학원', 'EN': 'Academy', 'JA': '塾', 'ZH': '补习班', 'FR': 'Institut', 'DE': 'Institut', 'RU': 'Академия', 'AR': 'المعهد', 'HI': 'अकादमी', 'VI': 'Trung tâm', 'ES': 'Academia', 'TH': 'สถาบันกวดวิชา'},
    'catExam': {'KO': '시험', 'EN': 'Exam', 'JA': '試験', 'ZH': '考试', 'FR': 'Examen', 'DE': 'Prüfung', 'RU': 'Экзамен', 'AR': 'الاختبار', 'HI': 'परीक्षा', 'VI': 'Kỳ thi', 'ES': 'Examen', 'TH': 'ข้อสอบ'},
    'catPersonal': {'KO': '개인', 'EN': 'Personal', 'JA': '個人', 'ZH': '个人', 'FR': 'Personnel', 'DE': 'Persönlich', 'RU': 'Личное', 'AR': 'شخصي', 'HI': 'व्यक्तिगत', 'VI': 'Cá nhân', 'ES': 'Personal', 'TH': 'ส่วนตัว'},
    'catVideo': {'KO': '동영상', 'EN': 'Video', 'JA': '動画', 'ZH': '视频', 'FR': 'Vidéo', 'DE': 'Video', 'RU': 'Видео', 'AR': 'فيديو', 'HI': 'वीडियो', 'VI': 'Video', 'ES': 'Video', 'TH': 'วิดีโอ'},
    'catWorkbook': {'KO': '문제집', 'EN': 'Workbook', 'JA': '問題集', 'ZH': '习题集', 'FR': 'Cahier d\'exercices', 'DE': 'Übungsbuch', 'RU': 'Сборник задач', 'AR': 'كتاب التمارين', 'HI': 'अभ्यास पुस्तिका', 'VI': 'Sách bài tập', 'ES': 'Libro de ejercicios', 'TH': 'หนังสือแบบฝึกหัด'},
    'catTextbook': {'KO': '교과서', 'EN': 'Textbook', 'JA': '教科書', 'ZH': '教科书', 'FR': 'Manuel scolaire', 'DE': 'Schulbuch', 'RU': 'Учебник', 'AR': 'الكتاب المدرسي', 'HI': 'पाठ्यपुस्तक', 'VI': 'Sách giáo khoa', 'ES': 'Libro de texto', 'TH': 'ตำราเรียน'},
    'catEtc': {'KO': '기타', 'EN': 'Other', 'JA': 'その他', 'ZH': '其他', 'FR': 'Autre', 'DE': 'Sonstiges', 'RU': 'Другое', 'AR': 'أخرى', 'HI': 'अन्य', 'VI': 'Khác', 'ES': 'Otro', 'TH': 'อื่นๆ'},
    'hintWorkbookName': {'KO': '예) "블랙라벨"', 'EN': 'e.g. "Black Label"', 'JA': '例）「ブラックラベル」', 'ZH': '例如："黑标"', 'FR': 'ex. « Black Label »', 'DE': 'z. B. „Black Label"', 'RU': 'напр. «Чёрная метка»', 'AR': 'مثال: "بلاك ليبل"', 'HI': 'उदा. "ब्लैक लेबल"', 'VI': 'VD: "Black Label"', 'ES': 'ej. "Black Label"', 'TH': 'เช่น "Black Label"'},
    'labelSubjectTitle': {'KO': '제목 입력', 'EN': 'Enter Title', 'JA': 'タイトル入力', 'ZH': '输入标题', 'FR': 'Saisir le titre', 'DE': 'Titel eingeben', 'RU': 'Введите название', 'AR': 'أدخل العنوان', 'HI': 'शीर्षक दर्ज करें', 'VI': 'Nhập tiêu đề', 'ES': 'Ingrese el título', 'TH': 'กรอกชื่อเรื่อง'},
    'hintTimeInput': {'KO': '시간 입력', 'EN': 'Enter Time', 'JA': '時間入力', 'ZH': '输入时间', 'FR': 'Saisir l\'heure', 'DE': 'Zeit eingeben', 'RU': 'Введите время', 'AR': 'أدخل الوقت', 'HI': 'समय दर्ज करें', 'VI': 'Nhập thời gian', 'ES': 'Ingrese la hora', 'TH': 'กรอกเวลา'},
    'hintMemoInput': {'KO': '상세 메모 입력', 'EN': 'Enter Memo', 'JA': '詳細メモ入力', 'ZH': '输入详细备注', 'FR': 'Saisir un mémo', 'DE': 'Notiz eingeben', 'RU': 'Введите заметку', 'AR': 'أدخل ملاحظة', 'HI': 'ज्ञापन दर्ज करें', 'VI': 'Nhập ghi chú', 'ES': 'Ingrese una nota', 'TH': 'กรอกบันทึกช่วยจำ'},

    // 🆕 [A/B범위] 연간·월간 뷰 잔존 문자열 보간부 신규 카탈로그
    'yearTargetAnalysisRail': {'KO': '목표 분석 레일', 'EN': 'Target Analysis Rail', 'JA': '目標分析レール', 'ZH': '目标分析轨道', 'FR': 'Rail d\'analyse des objectifs', 'DE': 'Zielanalyse-Leiste', 'RU': 'Панель анализа целей', 'AR': 'مسار تحليل الأهداف', 'HI': 'लक्ष्य विश्लेषण रेल', 'VI': 'Thanh phân tích mục tiêu', 'ES': 'Panel de análisis de objetivos', 'TH': 'แถบวิเคราะห์เป้าหมาย'},
    'registeredScheduleCount': {'KO': '등록 스케줄 건수', 'EN': 'Registered Schedules', 'JA': '登録スケジュール件数', 'ZH': '已登记日程数', 'FR': 'Programmes enregistrés', 'DE': 'Registrierte Termine', 'RU': 'Зарегистрировано расписаний', 'AR': 'عدد الجداول المسجلة', 'HI': 'पंजीकृत शेड्यूल संख्या', 'VI': 'Số lịch đã đăng ký', 'ES': 'Horarios registrados', 'TH': 'จำนวนตารางที่ลงทะเบียน'},
    'yearChecklistPopupTimeLabel': {'KO': '전반 마스터 리전', 'EN': 'Full-Year Master Region', 'JA': '通年マスターリージョン', 'ZH': '全年主控区域', 'FR': 'Région maîtresse annuelle', 'DE': 'Ganzjahres-Masterbereich', 'RU': 'Годовой мастер-регион', 'AR': 'المنطقة الرئيسية السنوية', 'HI': 'वार्षिक मास्टर क्षेत्र', 'VI': 'Khu vực chủ đạo cả năm', 'ES': 'Región maestra anual', 'TH': 'พื้นที่หลักตลอดปี'},
    'yearChecklistPopupMemo': {'KO': '국내 및 글로벌 상용화 목표 달성을 위한 연간 전개 스케줄 목표치입니다.', 'EN': 'An annual rollout target for domestic and global commercialization goals.', 'JA': '国内及びグローバル商用化目標達成のための年間展開スケジュール目標値です。', 'ZH': '为实现国内及全球商业化目标而制定的年度推进计划目标。', 'FR': 'Un objectif de déploiement annuel pour la commercialisation nationale et mondiale.', 'DE': 'Ein jährliches Rollout-Ziel für nationale und globale Kommerzialisierungsziele.', 'RU': 'Годовая цель развёртывания для внутренней и глобальной коммерциализации.', 'AR': 'هدف نشر سنوي لتحقيق أهداف التسويق التجاري المحلية والعالمية.', 'HI': 'घरेलू और वैश्विक व्यावसायीकरण लक्ष्यों हेतु वार्षिक विस्तार लक्ष्य।', 'VI': 'Mục tiêu triển khai hằng năm cho các mục tiêu thương mại hóa trong nước và toàn cầu.', 'ES': 'Un objetivo de implementación anual para metas de comercialización nacional y global.', 'TH': 'เป้าหมายการขยายผลรายปีเพื่อการค้าทั้งในและต่างประเทศ'},
    'monthChecklistPopupMemo': {'KO': '이번 달 핵심 학습 마스터 팩 안에 포함된 세부 목표 항목입니다.', 'EN': 'A detailed target item included in this month\'s Core Study Master Pack.', 'JA': '今月のコア学習マスターパックに含まれる詳細目標項目です。', 'ZH': '本月核心学习方案包中包含的具体目标项。', 'FR': 'Un objectif détaillé inclus dans le pack maître d\'étude de ce mois-ci.', 'DE': 'Ein detailliertes Ziel im diesmonatigen Kernlern-Masterpaket.', 'RU': 'Подробная цель, входящая в основной учебный пакет этого месяца.', 'AR': 'عنصر هدف مفصل ضمن حزمة الدراسة الأساسية لهذا الشهر.', 'HI': 'इस महीने के मुख्य अध्ययन पैक में शामिल एक विस्तृत लक्ष्य आइटम।', 'VI': 'Mục tiêu chi tiết nằm trong gói học tập cốt lõi của tháng này.', 'ES': 'Un objetivo detallado incluido en el paquete maestro de estudio de este mes.', 'TH': 'รายการเป้าหมายโดยละเอียดในแพ็กเรียนหลักของเดือนนี้'},
    'academicTimelineEmptyState': {'KO': '해당 타임라인에 등록된 상세 일정 내역이 없습니다.', 'EN': 'No detailed schedule registered for this timeline.', 'JA': 'このタイムラインに登録された詳細日程がありません。', 'ZH': '该时间线暂无已登记的详细日程。', 'FR': 'Aucun programme détaillé enregistré pour cette chronologie.', 'DE': 'Kein detaillierter Termin für diese Zeitleiste registriert.', 'RU': 'Для этой хронологии не зарегистрировано подробное расписание.', 'AR': 'لا يوجد جدول تفصيلي مسجل لهذا الجدول الزمني.', 'HI': 'इस समयरेखा के लिए कोई विस्तृत शेड्यूल दर्ज नहीं है।', 'VI': 'Chưa có lịch chi tiết nào được đăng ký cho dòng thời gian này.', 'ES': 'No hay horario detallado registrado para esta cronología.', 'TH': 'ไม่มีตารางโดยละเอียดที่ลงทะเบียนไว้สำหรับไทม์ไลน์นี้'},

    // 🆕 [2026-08-02] 주간(Week) 탭 - 실제 캘린더 주 전환에 따른 신규 문구
    'weekGoToday': {'KO': '오늘로 이동', 'EN': 'Go to Today', 'JA': '今日に移動', 'ZH': '回到今天', 'FR': 'Aller à aujourd\'hui', 'DE': 'Zu heute springen', 'RU': 'Перейти к сегодня', 'AR': 'الانتقال لليوم', 'HI': 'आज पर जाएं', 'VI': 'Về hôm nay', 'ES': 'Ir a hoy', 'TH': 'ไปที่วันนี้'},
    'weekEmptyMain': {'KO': '이번 주에 등록된 주요 일정이 없습니다.', 'EN': 'No main schedule registered for this week.', 'JA': '今週登録された主要日程がありません。', 'ZH': '本周暂无已登记的主要日程。', 'FR': 'Aucun programme principal cette semaine.', 'DE': 'Kein Hauptplan für diese Woche registriert.', 'RU': 'На эту неделю основное расписание не добавлено.', 'AR': 'لا يوجد جدول رئيسي مسجل لهذا الأسبوع.', 'HI': 'इस सप्ताह के लिए कोई मुख्य कार्यक्रम दर्ज नहीं है।', 'VI': 'Chưa có lịch chính nào được đăng ký cho tuần này.', 'ES': 'No hay horario principal registrado para esta semana.', 'TH': 'ไม่มีตารางหลักที่ลงทะเบียนไว้สำหรับสัปดาห์นี้'},
  };

  static String _t(String key) {
    final map = _uiText[key];
    if (map == null) return key;
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? key;
  }

  // 🆕 [12개국 - 한 줄 문구] 기본값 = "EN / KO", 10개국 선택 시 = 단일 언어
  static String _biStr(String key) {
    final map = _uiText[key];
    if (map == null) return key;
    if (_isForeignSelected) {
      return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? key;
    }
    return '${map['EN'] ?? ''} / ${map['KO'] ?? ''}';
  }

  // 🆕 [12개국 - 제목형 2단] 기본값 = 영문(위) + 한글(아래) 2줄, 10개국 선택 시 = 단일 언어 1줄
  static Widget _biTitle(
      String key, {
        required TextStyle enStyle,
        required TextStyle koStyle,
        TextStyle? foreignStyle,
      }) {
    final map = _uiTextLookup(key);
    if (_isForeignSelected) {
      return Text(
        map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? key,
        style: foreignStyle ?? koStyle,
        overflow: TextOverflow.fade,
        softWrap: false,
        maxLines: 1,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(map['EN'] ?? '', style: enStyle, overflow: TextOverflow.fade, softWrap: false, maxLines: 1),
        Text(map['KO'] ?? '', style: koStyle, overflow: TextOverflow.fade, softWrap: false, maxLines: 1),
      ],
    );
  }

  static Map<String, String> _uiTextLookup(String key) => _uiText[key] ?? {'EN': key, 'KO': key};

  // 🆕 [2026-07-30] 월/영문 축약 리스트 (가로 한 줄 EN/KO 표시용)
  static const List<String> _monthAbbrEn = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  // 🆕 [2026-07-30] 동적 텍스트를 "EN / KO" 가로 한 줄로 합쳐 표시 (월 선택 칩용)
  static Widget _biCompoundInline({
    required String enText,
    required String koText,
    required TextStyle style,
    String? foreignText,
  }) {
    if (_isForeignSelected) {
      return Text(foreignText ?? koText, style: style, overflow: TextOverflow.fade, softWrap: false, maxLines: 1);
    }
    return Text('$enText / $koText', style: style, overflow: TextOverflow.fade, softWrap: false, maxLines: 1);
  }

  // 🆕 [2026-07-30] 동적 텍스트를 영문(위)/한글(아래) 2줄로 쌓아서 표시 (주 선택 칩, 토글 버튼용)
  static Widget _biCompoundStack({
    required String enText,
    required String koText,
    required TextStyle enStyle,
    required TextStyle koStyle,
    String? foreignText,
    TextStyle? foreignStyle,
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
  }) {
    if (_isForeignSelected) {
      return Text(foreignText ?? koText, style: foreignStyle ?? koStyle, overflow: TextOverflow.fade, softWrap: false, maxLines: 1);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        Text(enText, style: enStyle, overflow: TextOverflow.fade, softWrap: false, maxLines: 1),
        Text(koText, style: koStyle, overflow: TextOverflow.fade, softWrap: false, maxLines: 1),
      ],
    );
  }

  static String _yearNumText(String rawKoreanYear) {
    if (DkeLang.current == 'KO') return rawKoreanYear;
    return rawKoreanYear.replaceAll('년', '');
  }

  static String _monthNumText(int month) {
    return DkeLang.current == 'KO' ? '$month월' : '$month';
  }

  static String _weekNumText(int weekNum) {
    return DkeLang.current == 'KO' ? '$weekNum주차' : '${_t('gradeWeekPrefix')} $weekNum';
  }

  // 🆕 [C범위] 팝업 안에서 "$month월 $day일" 형태로 쓰던 부분을 언어별로 자연스럽게 표기
  static String _monthDayText(int month, int day) {
    return DkeLang.current == 'KO' ? '$month월 $day일' : '$month/$day';
  }

  static const Map<String, List<String>> _weekdaySunFirst = {
    'KO': ['일','월','화','수','목','금','토'], 'EN': ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'],
    'JA': ['日','月','火','水','木','金','土'], 'ZH': ['日','一','二','三','四','五','六'],
    'FR': ['Dim','Lun','Mar','Mer','Jeu','Ven','Sam'], 'DE': ['So','Mo','Di','Mi','Do','Fr','Sa'],
    'RU': ['Вс','Пн','Вт','Ср','Чт','Пт','Сб'], 'AR': ['أحد','اثنين','ثلاثاء','أربعاء','خميس','جمعة','سبت'],
    'HI': ['रवि','सोम','मंगल','बुध','गुरु','शुक्र','शनि'], 'VI': ['CN','T2','T3','T4','T5','T6','T7'],
    'ES': ['Dom','Lun','Mar','Mié','Jue','Vie','Sáb'], 'TH': ['อา','จ','อ','พ','พฤ','ศ','ส'],
  };
  static const Map<String, List<String>> _weekdayMonFirst = {
    'KO': ['월','화','수','목','금','토','일'], 'EN': ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'],
    'JA': ['月','火','水','木','金','土','日'], 'ZH': ['一','二','三','四','五','六','日'],
    'FR': ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'], 'DE': ['Mo','Di','Mi','Do','Fr','Sa','So'],
    'RU': ['Пн','Вт','Ср','Чт','Пт','Сб','Вс'], 'AR': ['اثنين','ثلاثاء','أربعاء','خميس','جمعة','سبت','أحد'],
    'HI': ['सोम','मंगल','बुध','गुरु','शुक्र','शनि','रवि'], 'VI': ['T2','T3','T4','T5','T6','T7','CN'],
    'ES': ['Lun','Mar','Mié','Jue','Vie','Sáb','Dom'], 'TH': ['จ','อ','พ','พฤ','ศ','ส','อา'],
  };
  static List<String> _weekdaysSunFirst() => _weekdaySunFirst[DkeLang.current] ?? _weekdaySunFirst['EN']!;
  static List<String> _weekdaysMonFirst() => _weekdayMonFirst[DkeLang.current] ?? _weekdayMonFirst['EN']!;

  void _checkAndExpandYears(int currentYear) {
    String targetStr = '$currentYear년';
    if (!_scrollableYears.contains(targetStr)) {
      _scrollableYears.add(targetStr);
      if (!_yearlyTargetsMap.containsKey(targetStr)) {
        _yearlyTargetsMap[targetStr] = [];
      }
    }
  }

  // 🆕 [2026-08-02] 주어진 날짜가 속한 "실제 캘린더 주"의 일요일(주 시작일)을 계산
  // DateTime.weekday: 월=1 ... 일=7 이므로, 일요일까지 거슬러 올라갈 일수는 (weekday % 7)
  DateTime _computeWeekStart(DateTime date) {
    final DateTime dayOnly = DateTime(date.year, date.month, date.day);
    return dayOnly.subtract(Duration(days: dayOnly.weekday % 7));
  }

  // 🆕 [2026-08-02] 두 날짜가 같은 실제 캘린더 주(일~토)에 속하는지 비교
  bool _isSameRealWeek(DateTime a, DateTime b) {
    return _computeWeekStart(a).isAtSameMomentAs(_computeWeekStart(b));
  }

  bool _isSameCalendarDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // 🆕 [2026-08-02] 주간 탭 - 가로 스크롤 칩에 표시할 실제 주(일요일 시작일) 목록.
  // 오늘이 속한 실제 주를 기준으로 이전 6주 ~ 이후 12주, 총 19개 주를 생성함 (기존 칩 UI와 동일한
  // 가로 스크롤 방식으로 동작하되, 내용만 "1~5주차" 가상 라벨 대신 실제 날짜 범위로 표시됨).
  List<DateTime> get _weekChipWindow {
    final DateTime baseWeekStart = _computeWeekStart(DateTime.now());
    return List.generate(19, (i) => baseWeekStart.add(Duration(days: 7 * (i - 6))));
  }

  // 🆕 [2026-08-03] "이번 주가 화면 중앙에 오는 시작 스크롤 위치"를 계산해서 ScrollController를
  // 그 위치로 생성함. context가 있어야 MediaQuery로 실제 화면 폭을 읽을 수 있으므로, build 단계에서
  // (State가 mounted된 이후) 딱 한 번만 호출됨. 이후 재호출되어도 _weekChipScrollControllerReady
  // 플래그로 막혀 다시 생성되지 않음 — 즉 사용자가 이후에 직접 스크롤한 위치는 건드리지 않음.
  void _ensureWeekChipScrollControllerReady() {
    if (_weekChipScrollControllerReady) return;

    final double screenWidth = MediaQuery.of(context).size.width;
    // 주간 화면 바깥 ListView의 좌우 padding(16+16=32)을 뺀 값이 칩 리스트의 실제 가로 폭
    final double viewportWidthApprox = (screenWidth - 32.0).clamp(0.0, double.infinity);

    final List<DateTime> window = _weekChipWindow;
    final int todayIndex = window.indexWhere((w) => _isSameRealWeek(w, DateTime.now()));

    const double estimatedChipWidth = 108.0; // 패딩(32) + 텍스트(~66) + 우측 마진(10) 근사치
    final double totalEstimatedWidth = window.length * estimatedChipWidth;

    double initialOffset = 0.0;
    if (todayIndex != -1) {
      final double targetOffset = (todayIndex * estimatedChipWidth) - (viewportWidthApprox / 2) + (estimatedChipWidth / 2);
      final double maxOffsetEstimate = (totalEstimatedWidth - viewportWidthApprox) < 0 ? 0.0 : (totalEstimatedWidth - viewportWidthApprox);
      initialOffset = targetOffset.clamp(0.0, maxOffsetEstimate);
    }

    debugPrint('[GKE StudyUp] 주간 칩 시작 위치 계산: todayIndex=$todayIndex, screenWidth=$screenWidth, initialOffset=$initialOffset');

    _weekChipScrollController = ScrollController(initialScrollOffset: initialOffset);
    _weekChipScrollControllerReady = true;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    final DateTime today = DateTime.now();
    _selectedDayDate = DateTime(today.year, today.month, today.day);

    // 🆕 [2026-08-02] 진입 시 항상 오늘이 속한 실제 캘린더 주(일~토)로 초기화
    _weekViewRangeStart = _computeWeekStart(today);

    _scrollableYears = ['2026년', '2027년', '2028년', '2029년', '2030년'];
    _checkAndExpandYears(today.year);
    if (today.year > 2030) {
      _checkAndExpandYears(today.year);
    }

    final String currentYearStr = '${today.year}년';
    final int matchedYearIdx = _scrollableYears.indexOf(currentYearStr);
    _selectedYearIndex = matchedYearIdx != -1 ? matchedYearIdx : 0;
    _selectedMonthIndex = today.month - 1;

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _saveState();
      }
    });

    _weeklyTemplateMaster = {
      for (int w = 0; w < 5; w++)
        w: {
          for (int d = 1; d <= 7; d++)
            d: [
              {'time': '06:00 ~ 07:00', 'title': '기상 및 암기', 'memo': '새벽 기상 후 핵심 단어 및 암기과정 마스터 리프레시', 'category': '기타', 'custom_book': '', 'is_starred': false},
              {'time': '07:00 ~ 08:00', 'title': '등교', 'memo': '오전 등교 및 주간 자율 플래너 로드 진입 완료', 'category': '기타', 'custom_book': '', 'is_starred': false},
              {'time': '08:00 ~ 16:00', 'title': '학교생활', 'memo': '학교 정규 교과 수업 집중 이수 및 학업 성취도 빌드업', 'category': '교과서', 'custom_book': '', 'is_starred': false},
              {'time': '16:00 ~ 17:00', 'title': '휴식', 'memo': '에너지 충전 및 하교 후 자기주도 학습 모드 전환 휴식', 'category': '기타', 'custom_book': '', 'is_starred': false},
              {'time': '17:00 ~ 18:00', 'title': '고등수학', 'memo': '고등 수학 기본 개념 맵핑 및 유형별 고난도 문제 격파', 'category': '문제집', 'custom_book': '블랙라벨', 'is_starred': false},
              {'time': '18:00 ~ 19:00', 'title': '저녁식사', 'memo': '균형 잡힌 영양 섭취 및 야간 집중 자습 리커버리 시간', 'category': '기타', 'custom_book': '', 'is_starred': false},
              {'time': '19:00 ~ 20:00', 'title': '고등영어 자이스토리 실전', 'memo': '자이스토리 실전 모의고사 분석 및 고난도 구문 독해 트레이닝', 'category': '문제집', 'custom_book': '기출문제집', 'is_starred': false},
              {'time': '20:00 ~ 21:00', 'title': '중등2-2 진도', 'memo': '중등 2학년 2학기 핵심 기하 파트 심화 진도 선행 점검', 'category': '동영상', 'custom_book': '', 'is_starred': false},
              {'time': '21:00 ~ 22:00', 'title': '세계사', 'memo': '세계사 주요 연표 마인드맵핑 및 흐름 정리 암기 트랙', 'category': '교과서', 'custom_book': '', 'is_starred': false},
              {'time': '22:00 ~ 23:00', 'title': '오늘것 오답 또는 총정리', 'memo': '오늘 진행된 전체 진도 오답노트 정밀 기록 및 최종 스터디업 클로징', 'category': '문제집', 'custom_book': '', 'is_starred': false},
            ],
        }
    };

    _yearlyTargetsMap = {
      '2026년': [
        {'title': '2026 민사고 합격 독점 스케줄', 'done': true},
        {'title': '2026 수학 내신 1등급 완성', 'done': false},
        {'title': '2026 영어 수능 최저학력기준 충족', 'done': false},
      ],
      '2027년': [{'title': '2027 고등 전과목 심화 마스터', 'done': false}],
      '2028년': [], '2029년': [], '2030년': [],
    };

    _monthlyTargetsMap = {
      for (int m = 1; m <= 12; m++)
        m: [
          {'labelKey': 'monthPrepScheduleItem', 'done': false},
          {'labelKey': 'monthMockExamItem', 'done': false},
          {'labelKey': 'monthStarCollectItem', 'done': false},
        ],
    };

    _globalSchedules = [
      {
        'year': 2026, 'month': 7, 'day': 3, 'time': '12:00',
        'title': '자기주도 학습 핵심 아키텍처 가동', 'color': schoolColor, 'memo': '시스템 리팩토링 및 캘린더 엔진 결합',
      }
    ];
    _fixedDayTimelines = [];

    _sortGlobalSchedules();

    _initStorageAndLoad().then((_) {
      _syncDailyTimelineForDate(_selectedDayDate);
      _calculateMonthlyProgress();
    });
  }

  int _getContinuousWeekIndex(DateTime date) {
    final DateTime yearStart = DateTime(date.year, 1, 1);
    final int daysDiff = date.difference(yearStart).inDays;
    final int yearWeekNumber = ((daysDiff + yearStart.weekday) / 7).ceil();
    return (yearWeekNumber - 1) % 5;
  }

  void _syncDailyTimelineForDate(DateTime date) async {
    _checkAndExpandYears(date.year);

    final String dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final prefs = await SharedPreferences.getInstance();

    final String? examType = prefs.getString('gke_selected_exam_type');
    final String? startStr = prefs.getString('gke_exam_start_date');
    final String? endStr = prefs.getString('gke_exam_end_date');
    final String? prepPeriod = prefs.getString('gke_exam_prep_period');
    final bool timelineEnabled = prefs.getBool('gke_exam_timeline_enabled') ?? false;

    final String? studyTimelineData = prefs.getString('gke_study_timeline_data');
    if (studyTimelineData != null && studyTimelineData.isNotEmpty) {
      debugPrint('[GKE StudyUp] Academic study timeline synced: $studyTimelineData');
    }

    bool isExamModeActive = false;
    String examStatusTitleEn = "REGULAR STUDY RUN";
    String examStatusTitleKo = "평상시 자율 학습 계획 트랙";

    if (timelineEnabled && startStr != null && endStr != null) {
      final DateTime examStartDate = DateTime.parse(startStr);
      final DateTime examEndDate = DateTime.parse(endStr);

      int prepDays = 28;
      if (prepPeriod == '2주 전') prepDays = 14;
      if (prepPeriod == '3주 전') prepDays = 21;

      final DateTime prepStartDate = examStartDate.subtract(Duration(days: prepDays));
      final DateTime examEndMidnight = DateTime(examEndDate.year, examEndDate.month, examEndDate.day).add(const Duration(days: 1));

      if ((date.isAfter(prepStartDate) || date.isAtSameMomentAs(prepStartDate)) && date.isBefore(examEndMidnight)) {
        isExamModeActive = true;

        int daysDiffFromStart = date.difference(prepStartDate).inDays;
        int currentExamWeek = (daysDiffFromStart / 7).floor() + 1;
        int currentExamDayNum = (daysDiffFromStart % 7) + 1;

        int dDayCount = DateTime(examStartDate.year, examStartDate.month, examStartDate.day).difference(date).inDays;
        String dDayLabel = "";
        if (dDayCount > 0) {
          dDayLabel = "D-$dDayCount";
        } else if (dDayCount == 0) {
          dDayLabel = "D-Day";
        } else {
          dDayLabel = "D+${dDayCount.abs()}";
        }

        examStatusTitleEn = "EXAM PREP: WEEK $currentExamWeek DAY $currentExamDayNum ($dDayLabel)";
        examStatusTitleKo = "[$examType 대비] $currentExamWeek주차 $currentExamDayNum일차 실전 모드 ($dDayLabel)";
      }
    }

    if (!_dailyExecutionInstanceMap.containsKey(dateKey)) {
      List<Map<String, dynamic>> freshInstance = [];

      if (isExamModeActive) {
        freshInstance = [
          {'time': '06:00 ~ 08:00', 'title': 'EXAM INTENSIVE MEMORY\n[시험과목 핵심 요약 암기 특강]', 'memo': examStatusTitleKo, 'category': '교과서', 'custom_book': '', 'is_starred': false},
          {'time': '08:00 ~ 16:00', 'title': 'SCHOOL EXAM CONTEXT\n[학교 시험 대비 집중 수업 청취]', 'memo': '학교 기출 유형 완벽 분석 및 오답 정리', 'category': '교과서', 'custom_book': '', 'is_starred': false},
          {'time': '16:00 ~ 18:00', 'title': 'MOCK EXAM PRACTICE\n[기출문제집 실전 모의고사 제한시간 격파]', 'memo': '과거 3개년 인근 학교 족보 정밀 마스터', 'category': '문제집', 'custom_book': '기출문제집', 'is_starred': false},
          {'time': '18:00 ~ 22:00', 'title': 'INTENSIVE WEAKNESS FEEDBACK\n[단원별 취약점 파괴 및 1:1 오답 클리닉]', 'memo': '완벽한 개념 이해를 위한 수집 레이스 트랙', 'category': '문제집', 'custom_book': '오답노트', 'is_starred': false},
          {'time': '22:00 ~ 23:00', 'title': 'CLOSING SUMMARY & STAR COLLECT\n[오늘 시험 범위 최종 마감 및 별 수집]', 'memo': '자정 전 완벽 리커버리', 'category': '기타', 'custom_book': '', 'is_starred': false},
        ];
      } else {
        int calculatedWeekIdx = _getContinuousWeekIndex(date);
        int weekdayIdx = date.weekday;
        List<Map<String, dynamic>> templateList = _weeklyTemplateMaster[calculatedWeekIdx]?[weekdayIdx] ?? [];
        freshInstance = templateList.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      _dailyExecutionInstanceMap[dateKey] = freshInstance;
    } else {
      if (isExamModeActive && _dailyExecutionInstanceMap[dateKey]!.isNotEmpty) {
        _dailyExecutionInstanceMap[dateKey]![0]['memo'] = examStatusTitleKo;
      }
    }

    if (mounted) {
      setState(() {
        _fixedDayTimelines = _dailyExecutionInstanceMap[dateKey]!;
        _selectedWeekIndex = _getContinuousWeekIndex(date);
      });
    }
  }

  void _calculateMonthlyProgress() {
    int totalTasks = 0;
    int completedTasks = 0;
    final String monthPrefix = "${_selectedDayDate.year}-${_selectedDayDate.month.toString().padLeft(2, '0')}-";

    _dailyExecutionInstanceMap.forEach((key, list) {
      if (key.startsWith(monthPrefix)) {
        for (var task in list) {
          totalTasks++;
          if (task['is_starred'] == true) { completedTasks++; }
        }
      }
    });

    setState(() {
      _monthlyProgressGauge = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;
    });
  }

  Future<void> _initStorageAndLoad() async {
    await _loadMasterData();
    await _loadSavedState();
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('gke_tab_index', _tabController.index);
      await prefs.setInt('gke_selected_year_index', _selectedYearIndex);
      await prefs.setInt('gke_selected_month_index', _selectedMonthIndex);
      await prefs.setInt('gke_selected_week_index', _selectedWeekIndex);
      await prefs.setString('gke_selected_day_date', _selectedDayDate.toIso8601String());

      await prefs.setBool('gke_is_year_target_selected', _isYearTargetSelected);
      await prefs.setBool('gke_is_month_target_selected', _isMonthTargetSelected);
      await prefs.setBool('gke_is_week_timeline_selected', _isWeekTimelineSelected);
      await prefs.setBool('gke_is_time_view_selected', _isTimeViewSelected);
      await prefs.setBool('gke_is_year_target_expanded', _isYearTargetExpanded);
      await prefs.setBool('gke_is_day_calendar_visible', _isDayCalendarVisible);
    } catch (e) {
      debugPrint('[GKE StudyUp] Error saving configuration state: $e');
    }
  }

  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? savedTabIndex = prefs.getInt('gke_tab_index');
      final int? savedYearIndex = prefs.getInt('gke_selected_year_index');
      final int? savedMonthIndex = prefs.getInt('gke_selected_month_index');
      final int? savedWeekIndex = prefs.getInt('gke_selected_week_index');

      final bool? savedYearTargetSel = prefs.getBool('gke_is_year_target_selected');
      final bool? savedMonthTargetSel = prefs.getBool('gke_is_month_target_selected');
      final bool? savedWeekTimelineSel = prefs.getBool('gke_is_week_timeline_selected');
      final bool? savedTimeViewSel = prefs.getBool('gke_is_time_view_selected');
      final bool? savedYearTargetExp = prefs.getBool('gke_is_year_target_expanded');
      final bool? savedDayCalendarVis = prefs.getBool('gke_is_day_calendar_visible');

      setState(() {
        if (savedTabIndex != null) { _tabController.index = savedTabIndex; }
        if (savedYearIndex != null && savedYearIndex < _scrollableYears.length) { _selectedYearIndex = savedYearIndex; }
        if (savedMonthIndex != null && savedMonthIndex < 12) { _selectedMonthIndex = savedMonthIndex; }
        if (savedWeekIndex != null && savedWeekIndex < _scrollableWeeks.length) { _selectedWeekIndex = savedWeekIndex; }

        if (savedYearTargetSel != null) _isYearTargetSelected = savedYearTargetSel;
        if (savedMonthTargetSel != null) _isMonthTargetSelected = savedMonthTargetSel;
        if (savedWeekTimelineSel != null) _isWeekTimelineSelected = savedWeekTimelineSel;
        if (savedTimeViewSel != null) _isTimeViewSelected = savedTimeViewSel;
        if (savedYearTargetExp != null) _isYearTargetExpanded = savedYearTargetExp;
        if (savedDayCalendarVis != null) _isDayCalendarVisible = savedDayCalendarVis;
      });

      _syncDailyTimelineForDate(_selectedDayDate);
    } catch (e) {
      debugPrint('[GKE StudyUp] Error loading configuration state: $e');
    }
  }

  Future<void> _saveMasterData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gke_yearly_targets_map', jsonEncode(_yearlyTargetsMap));
      await prefs.setString('gke_monthly_targets_map', jsonEncode(_monthlyTargetsMap.map((key, value) => MapEntry(key.toString(), value))));

      final List<Map<String, dynamic>> serializableSchedules = _globalSchedules.map((item) {
        final Map<String, dynamic> copy = Map.from(item);
        if (copy['color'] is Color) { copy['color'] = (copy['color'] as Color).value; }
        return copy;
      }).toList();
      await prefs.setString('gke_global_schedules', jsonEncode(serializableSchedules));
      await prefs.setString('gke_daily_execution_instance_map', jsonEncode(_dailyExecutionInstanceMap));
    } catch (e) {
      debugPrint('[GKE StudyUp] Error serializing master data: $e');
    }
  }

  Future<void> _loadMasterData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? yearlyTargetsJson = prefs.getString('gke_yearly_targets_map');
      if (yearlyTargetsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(yearlyTargetsJson);
        setState(() {
          _yearlyTargetsMap = decoded.map((key, value) {
            final List<dynamic> list = value as List<dynamic>;
            return MapEntry(key, list.map((item) => Map<String, dynamic>.from(item as Map)).toList());
          });
        });
      }

      final String? monthlyTargetsJson = prefs.getString('gke_monthly_targets_map');
      if (monthlyTargetsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(monthlyTargetsJson);
        setState(() {
          _monthlyTargetsMap = decoded.map((key, value) {
            final List<dynamic> list = value as List<dynamic>;
            return MapEntry(int.parse(key), list.map((item) => Map<String, dynamic>.from(item as Map)).toList());
          });
        });
      }

      final String? globalSchedulesJson = prefs.getString('gke_global_schedules');
      if (globalSchedulesJson != null) {
        final List<dynamic> decodedList = jsonDecode(globalSchedulesJson);
        setState(() {
          _globalSchedules = decodedList.map((item) {
            final Map<String, dynamic> map = Map<String, dynamic>.from(item as Map);
            if (map['color'] is int) { map['color'] = Color(map['color'] as int); }
            return map;
          }).toList();
          _sortGlobalSchedules();
        });
      }

      final String? dailyExecJson = prefs.getString('gke_daily_execution_instance_map');
      if (dailyExecJson != null) {
        final Map<String, dynamic> decodedMap = jsonDecode(dailyExecJson);
        setState(() {
          _dailyExecutionInstanceMap = decodedMap.map((key, value) {
            final List<dynamic> list = value as List<dynamic>;
            return MapEntry(key, list.map((item) => Map<String, dynamic>.from(item as Map)).toList());
          });
        });
      }
    } catch (e) {
      debugPrint('[GKE StudyUp] Error deserializing master data: $e');
    }
  }

  void _sortGlobalSchedules() {
    _globalSchedules.sort((a, b) {
      int yearComp = (a['year'] as int).compareTo(b['year'] as int);
      if (yearComp != 0) return yearComp;
      int monthComp = (a['month'] as int).compareTo(b['month'] as int);
      if (monthComp != 0) return monthComp;
      int dayComp = (a['day'] as int).compareTo(b['day'] as int);
      if (dayComp != 0) return dayComp;
      return (a['time'] as String).compareTo(b['time'] as String);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (_weekChipScrollControllerReady) { _weekChipScrollController.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 8),
        child: AppBar(
          backgroundColor: const Color(0xFF020617),
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: TabBar(
              controller: _tabController,
              indicatorColor: goldColor,
              labelColor: goldColor,
              unselectedLabelColor: slate400,
              tabs: [
                Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _biTitle(
                        'tabYear',
                        enStyle: GoogleFonts.gowunBatang(fontSize: 10, fontWeight: FontWeight.bold),
                        koStyle: GoogleFonts.notoSansKr(fontSize: 14, fontWeight: FontWeight.bold),
                        foreignStyle: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _biTitle(
                        'tabMonth',
                        enStyle: GoogleFonts.gowunBatang(fontSize: 10, fontWeight: FontWeight.bold),
                        koStyle: GoogleFonts.notoSansKr(fontSize: 14, fontWeight: FontWeight.bold),
                        foreignStyle: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _biTitle(
                        'tabWeek',
                        enStyle: GoogleFonts.gowunBatang(fontSize: 10, fontWeight: FontWeight.bold),
                        koStyle: GoogleFonts.notoSansKr(fontSize: 14, fontWeight: FontWeight.bold),
                        foreignStyle: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _biTitle(
                        'tabDay',
                        enStyle: GoogleFonts.gowunBatang(fontSize: 10, fontWeight: FontWeight.bold),
                        koStyle: GoogleFonts.notoSansKr(fontSize: 14, fontWeight: FontWeight.bold),
                        foreignStyle: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildYearView(),
          _buildMonthView(),
          _buildWeekView(),
          _buildDayView(),
        ],
      ),
    );
  }

  Widget _buildYearView() {
    String currentYearKey = _scrollableYears[_selectedYearIndex];
    List<Map<String, dynamic>> currentTargets = _yearlyTargetsMap[currentYearKey] ?? [];
    int numericYear = int.tryParse(currentYearKey.replaceAll('년', '')) ?? 2026;
    List<Map<String, dynamic>> filteredYearSchedules = _globalSchedules.where((s) => (s['year'] ?? 2026) == numericYear).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      children: [
        _buildDynamicSectionHeader('sectionYearlyTarget', () { _showAddScheduleBottomSheet(context, '목표'); }),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _scrollableYears.length,
            itemBuilder: (context, index) {
              bool isSelected = _selectedYearIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() { _selectedYearIndex = index; });
                  _saveState();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? goldColor.withValues(alpha: 0.15) : const Color(0xFF020617),
                    border: Border.all(color: isSelected ? goldColor : slate800, width: 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text('${_yearNumText(_scrollableYears[index])} ${_t('yearTargetWord')}', overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(fontSize: 12, color: isSelected ? goldColor : slate300)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () { setState(() { _isYearTargetSelected = true; }); _saveState(); },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isYearTargetSelected ? goldColor : slate800, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_yearNumText(currentYearKey)} ${_t('yearTargetListWord')}',
                        overflow: TextOverflow.fade, softWrap: false, maxLines: 1,
                        style: GoogleFonts.notoSansKr(fontSize: 13, color: _isYearTargetSelected ? goldColor : slate400, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () { setState(() { _isYearTargetSelected = false; }); _saveState(); },
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: !_isYearTargetSelected ? goldColor : slate800, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_yearNumText(currentYearKey)} ${_t('yearMainScheduleWord')}',
                        overflow: TextOverflow.fade, softWrap: false, maxLines: 1,
                        style: GoogleFonts.notoSansKr(fontSize: 13, color: !_isYearTargetSelected ? goldColor : slate400, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isYearTargetSelected) ...[
          Card(
            color: const Color(0xFF020617),
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(side: BorderSide(color: slate800)),
            child: ExpansionTile(
              key: ValueKey(currentYearKey),
              initiallyExpanded: _isYearTargetExpanded,
              title: Text('${_yearNumText(currentYearKey)} ${_biStr('yearTargetAnalysisRail')}', overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold)),
              iconColor: goldColor,
              collapsedIconColor: slate400,
              onExpansionChanged: (val) { setState(() { _isYearTargetExpanded = val; }); _saveState(); },
              children: [
                if (currentTargets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Text(_t('emptyYearTarget'), style: GoogleFonts.notoSansKr(color: slate500, fontSize: 12)),
                  )
                else
                  ...currentTargets.asMap().entries.map((entry) {
                    return _buildYearChecklistItem(entry.value['title'], entry.value['done'], entry.key, currentYearKey);
                  }).toList(),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ] else ...[
          if (filteredYearSchedules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Center(child: Text(_t('emptyYearSchedule'), style: GoogleFonts.notoSansKr(color: slate500, fontSize: 12))),
            )
          else
            ...filteredYearSchedules.asMap().entries.map((entry) {
              return _buildScheduleTimelineItem(_monthDayText(entry.value['month'], entry.value['day']), entry.value['title'], entry.value['color'], _globalSchedules.indexOf(entry.value), entry.value['memo'] ?? '');
            }).toList(),
        ],
      ],
    );
  }

  Widget _buildMonthView() {
    int targetMonth = _selectedMonthIndex + 1;
    List<Map<String, dynamic>> filteredMonthSchedules = _globalSchedules.where((s) => s['month'] == targetMonth).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      children: [
        _buildDynamicSectionHeader('sectionMonthlyMgmt', () { _showAddScheduleBottomSheet(context, '일정'); }),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(10), border: Border.all(color: slate800)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_biStr('achievementGauge'), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(fontSize: 12, color: goldColor, fontWeight: FontWeight.bold)),
                  Text('${(_monthlyProgressGauge * 100).toStringAsFixed(1)}%', style: GoogleFonts.notoSerif(fontSize: 13, color: goldColor, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _monthlyProgressGauge,
                  minHeight: 8,
                  backgroundColor: const Color(0xFF0F172A),
                  valueColor: AlwaysStoppedAnimation<Color>(goldColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 12,
            itemBuilder: (context, index) {
              bool isSelected = _selectedMonthIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() { _selectedMonthIndex = index; });
                  _saveState();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? goldColor.withValues(alpha: 0.15) : const Color(0xFF020617),
                    border: Border.all(color: isSelected ? goldColor : slate800, width: 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: _biCompoundInline(
                      enText: _monthAbbrEn[index],
                      koText: '${index + 1}월',
                      foreignText: _monthNumText(index + 1),
                      style: GoogleFonts.notoSansKr(fontSize: 12, color: isSelected ? goldColor : slate300),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () { setState(() { _isMonthTargetSelected = true; }); _saveState(); },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isMonthTargetSelected ? goldColor : slate800, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _biCompoundStack(
                        enText: '${_monthAbbrEn[targetMonth - 1]} ${_uiTextLookup('monthTargetListWord')['EN']}',
                        koText: '${targetMonth}월 ${_t('monthTargetListWord')}',
                        foreignText: '${_monthNumText(targetMonth)} ${_t('monthTargetListWord')}',
                        enStyle: GoogleFonts.gowunBatang(fontSize: 10, color: _isMonthTargetSelected ? goldColor : slate400, fontWeight: FontWeight.bold),
                        koStyle: GoogleFonts.notoSansKr(fontSize: 13, color: _isMonthTargetSelected ? goldColor : slate400, fontWeight: FontWeight.bold),
                        foreignStyle: GoogleFonts.notoSans(fontSize: 13, color: _isMonthTargetSelected ? goldColor : slate400, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () { setState(() { _isMonthTargetSelected = false; }); _saveState(); },
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: !_isMonthTargetSelected ? goldColor : slate800, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _biCompoundStack(
                        enText: '${_monthAbbrEn[targetMonth - 1]} ${_uiTextLookup('yearMainScheduleWord')['EN']}',
                        koText: '${targetMonth}월 ${_t('yearMainScheduleWord')}',
                        foreignText: '${_monthNumText(targetMonth)} ${_t('yearMainScheduleWord')}',
                        enStyle: GoogleFonts.gowunBatang(fontSize: 10, color: !_isMonthTargetSelected ? goldColor : slate400, fontWeight: FontWeight.bold),
                        koStyle: GoogleFonts.notoSansKr(fontSize: 13, color: !_isMonthTargetSelected ? goldColor : slate400, fontWeight: FontWeight.bold),
                        foreignStyle: GoogleFonts.notoSans(fontSize: 13, color: !_isMonthTargetSelected ? goldColor : slate400, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isMonthTargetSelected) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(10), border: Border.all(color: slate800)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_monthNumText(targetMonth)} ${_t('monthMasterPack')}', overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(fontSize: 13, color: goldColor, fontWeight: FontWeight.bold)),
                const Divider(color: Color(0xFF1E293B), height: 16),
                ...(_monthlyTargetsMap[targetMonth] ?? []).asMap().entries.map((entry) {
                  return _buildMonthChecklistItem(entry.value['labelKey'], entry.value['done'], entry.key, targetMonth);
                }).toList(),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(10), border: Border.all(color: slate800)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_monthNumText(targetMonth)} ${_biStr('registeredScheduleCount')}', overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(fontSize: 12, color: slate400)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: goldColor, borderRadius: BorderRadius.circular(12)),
                      child: Text('${filteredMonthSchedules.length}', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF020617), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF1E293B), height: 16),
                if (filteredMonthSchedules.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(_t('emptyMonthSchedule'), style: GoogleFonts.notoSansKr(fontSize: 12, color: slate500)),
                  )
                else
                  ...filteredMonthSchedules.map((schedule) {
                    final String dateTimeLabel = '${(schedule['month'] as int).toString().padLeft(2, '0')}/${(schedule['day'] as int).toString().padLeft(2, '0')}, ${schedule['time'] ?? ''}';
                    return GestureDetector(
                      onTap: () { _showUnifiedPopupTrack(schedule, typeKey: 'MONTH'); },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6), border: Border.all(color: slate800)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 76,
                              child: Text(dateTimeLabel, style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                            ),
                            Container(width: 3, height: 32, margin: const EdgeInsets.symmetric(horizontal: 10), color: schedule['color'] ?? goldColor),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(schedule['title'] ?? '', style: GoogleFonts.notoSansKr(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                  if ((schedule['memo'] ?? '').toString().isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(schedule['memo'], style: GoogleFonts.notoSansKr(fontSize: 11, color: slate400), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ],
                              ),
                            ),
                            _buildEditActionIcon(size: 14),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================================
  // 🆕 [2026-08-02] 주간(Week) 탭 전면 재설계
  // - "1~5주차 순환 템플릿" 방식의 가상 주차 개념을 버리고, 실제 일~토 캘린더 주 기준으로 전환.
  // - 진입 시 항상 오늘이 속한 실제 주가 기본 선택됨 (initState의 _weekViewRangeStart 참고).
  // - ◀ ▶ 로 실제 주 단위 이동, "오늘로 이동" 버튼으로 즉시 복귀.
  // - [학습 타임라인] 서브탭: 요일별 고정 템플릿(_weeklyTemplateMaster) 로직 자체는 그대로 유지하되,
  //   이제 그 주의 "실제 날짜"에 맞춰 계산(_getContinuousWeekIndex(실제날짜))하여 표시 — 일간 탭과 동일한
  //   계산식을 쓰므로 일간에서 보이는 고정 시간표와 항상 일치함.
  // - [주요 일정] 서브탭: 더 이상 정적 문구가 아니라, 실제 _globalSchedules 중 이 주 범위(일~토)에 속하는
  //   항목만 필터링해서 보여주고, 탭하면 기존 수정/삭제 팝업과 연결됨(typeKey: 'WEEK_MAIN').
  // ============================================================================
  Widget _buildWeekView() {
    _ensureWeekChipScrollControllerReady();
    final DateTime weekStart = _weekViewRangeStart;
    final List<DateTime> weekDates = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final DateTime weekEndInclusive = weekDates.last;
    final List<String> weekdays = _weekdaysSunFirst();

    final String weekRangeLabel = '${weekStart.month}/${weekStart.day} ~ ${weekEndInclusive.month}/${weekEndInclusive.day}';

    // 🆕 실제 주 범위(일~토)에 속하는 진짜 일정만 필터링
    List<Map<String, dynamic>> weekMainSchedules = _globalSchedules.where((s) {
      final DateTime d = DateTime(s['year'] as int, s['month'] as int, s['day'] as int);
      return !d.isBefore(weekStart) && !d.isAfter(weekEndInclusive);
    }).toList();
    weekMainSchedules.sort((a, b) {
      final DateTime da = DateTime(a['year'] as int, a['month'] as int, a['day'] as int);
      final DateTime db = DateTime(b['year'] as int, b['month'] as int, b['day'] as int);
      int c = da.compareTo(db);
      if (c != 0) return c;
      return (a['time'] ?? '').toString().compareTo((b['time'] ?? '').toString());
    });

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      children: [
        _buildDynamicSectionHeader('sectionWeeklyAnalytics', () { _showAddScheduleBottomSheet(context, '일정'); }),
        const SizedBox(height: 12),

        // 🆕 [2026-08-02] 사용자 요청으로 이동 화살표 레일 대신 기존 가로 스크롤 칩 UI로 복원.
        // 칩 라벨만 "1~5주차" 가상 명칭 대신 실제 날짜 범위(예: 7/27~8/2)로 바뀌었을 뿐, 높이(50)와
        // 조작 방식(가로 스크롤 + 탭 선택)은 기존과 동일함. 오늘이 속한 실제 주는 골드 테두리로 표시됨.
        SizedBox(
          height: 50,
          child: ListView.builder(
            controller: _weekChipScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: _weekChipWindow.length,
            itemBuilder: (context, index) {
              final DateTime chipWeekStart = _weekChipWindow[index];
              final DateTime chipWeekEnd = chipWeekStart.add(const Duration(days: 6));
              final bool isSelected = _isSameRealWeek(chipWeekStart, weekStart);
              final bool isTodayChip = _isSameRealWeek(chipWeekStart, DateTime.now());
              final String chipLabel = '${chipWeekStart.month}/${chipWeekStart.day}~${chipWeekEnd.month}/${chipWeekEnd.day}';
              return GestureDetector(
                onTap: () {
                  setState(() { _weekViewRangeStart = chipWeekStart; });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? goldColor : const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? goldColor : (isTodayChip ? goldColor.withValues(alpha: 0.6) : slate800), width: isTodayChip && !isSelected ? 1.4 : 1),
                  ),
                  child: Center(
                    child: Text(
                      chipLabel,
                      overflow: TextOverflow.fade, softWrap: false, maxLines: 1,
                      style: GoogleFonts.notoSansKr(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF020617) : (isTodayChip ? goldColor : slate300)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () { setState(() { _isWeekTimelineSelected = true; }); _saveState(); },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isWeekTimelineSelected ? goldColor : slate800, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _biCompoundStack(
                        enText: '$weekRangeLabel ${_uiTextLookup('weekTimelineWord')['EN']}',
                        koText: '$weekRangeLabel ${_t('weekTimelineWord')}',
                        foreignText: '$weekRangeLabel ${_t('weekTimelineWord')}',
                        enStyle: GoogleFonts.gowunBatang(fontSize: 10, color: _isWeekTimelineSelected ? goldColor : slate400, fontWeight: FontWeight.bold),
                        koStyle: GoogleFonts.notoSansKr(fontSize: 13, color: _isWeekTimelineSelected ? goldColor : slate400, fontWeight: FontWeight.bold),
                        foreignStyle: GoogleFonts.notoSans(fontSize: 13, color: _isWeekTimelineSelected ? goldColor : slate400, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () { setState(() { _isWeekTimelineSelected = false; }); _saveState(); },
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: !_isWeekTimelineSelected ? goldColor : slate800, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _biCompoundStack(
                        enText: '$weekRangeLabel ${_uiTextLookup('yearMainScheduleWord')['EN']}',
                        koText: '$weekRangeLabel ${_t('yearMainScheduleWord')}',
                        foreignText: '$weekRangeLabel ${_t('yearMainScheduleWord')}',
                        enStyle: GoogleFonts.gowunBatang(fontSize: 10, color: !_isWeekTimelineSelected ? goldColor : slate400, fontWeight: FontWeight.bold),
                        koStyle: GoogleFonts.notoSansKr(fontSize: 13, color: !_isWeekTimelineSelected ? goldColor : slate400, fontWeight: FontWeight.bold),
                        foreignStyle: GoogleFonts.notoSans(fontSize: 13, color: !_isWeekTimelineSelected ? goldColor : slate400, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isWeekTimelineSelected) ...[
          Text('$weekRangeLabel ${_t('weekdayTemplateOverview')}', style: GoogleFonts.notoSansKr(fontSize: 12, color: slate400)),
          const SizedBox(height: 10),
          ...weekDates.asMap().entries.map((entry) {
            int i = entry.key; // 0=일 ... 6=토
            DateTime actualDate = entry.value;
            String dayLabel = weekdays[i];
            bool isSunday = i == 0;
            bool isToday = _isSameCalendarDate(actualDate, DateTime.now());

            // 🆕 일간 탭과 완전히 동일한 계산식으로 그 실제 날짜의 고정 템플릿을 가져옴
            int calculatedWeekIdx = _getContinuousWeekIndex(actualDate);
            int weekdayIdx = actualDate.weekday;
            var list = _weeklyTemplateMaster[calculatedWeekIdx]?[weekdayIdx] ?? [];
            String mainTaskTitle = list.isNotEmpty ? list[0]['title'] : _t('selfStudyDefaultTrack');

            Map<String, dynamic> weekSummary = {
              'title': '${actualDate.month}/${actualDate.day}($dayLabel): $mainTaskTitle',
              'memo': _t('fixedTemplateRoutineMemo'),
              'time': _t('fixedTemplateLabel'),
              'color': goldColor
            };

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isToday ? goldColor : slate800, width: isToday ? 1.5 : 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: isSunday ? examColor : goldColor.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: Text(dayLabel, style: GoogleFonts.notoSansKr(fontSize: 12, color: isSunday ? Colors.white : goldColor, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(weekSummary['title'], style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
                        Text(weekSummary['memo'], style: GoogleFonts.notoSansKr(fontSize: 12, color: slate500), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Icon(Icons.lock_clock, color: slate500, size: 16),
                ],
              ),
            );
          }).toList(),
        ] else ...[
          // 🆕 실제 데이터(_globalSchedules) 기반 "주요 일정" 목록 — 탭하면 수정/삭제 가능
          if (weekMainSchedules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30.0),
              child: Center(child: Text(_t('weekEmptyMain'), style: GoogleFonts.notoSansKr(color: slate500, fontSize: 12))),
            )
          else
            ...weekMainSchedules.map((schedule) {
              final DateTime scheduleDate = DateTime(schedule['year'] as int, schedule['month'] as int, schedule['day'] as int);
              final int weekdayArrIdx = scheduleDate.weekday % 7; // 0=일 ... 6=토 (weekdaysSunFirst 인덱스와 일치)
              final String dateBadge = '${scheduleDate.month}/${scheduleDate.day}(${weekdays[weekdayArrIdx]})';

              return GestureDetector(
                onTap: () { _showUnifiedPopupTrack(schedule, typeKey: 'WEEK_MAIN'); },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(8), border: Border.all(color: slate800)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 62,
                        child: Text(dateBadge, style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                      ),
                      Container(width: 3, height: 32, margin: const EdgeInsets.symmetric(horizontal: 10), color: schedule['color'] ?? goldColor),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(schedule['title'] ?? '', style: GoogleFonts.notoSansKr(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                            if ((schedule['memo'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(schedule['memo'], style: GoogleFonts.notoSansKr(fontSize: 11, color: slate400)),
                            ],
                          ],
                        ),
                      ),
                      _buildEditActionIcon(size: 14),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ],
    );
  }

  Widget _buildDayView() {
    List<Map<String, dynamic>> targetDaySchedules = _globalSchedules
        .where((s) => s['year'] == _selectedDayDate.year && s['month'] == _selectedDayDate.month && s['day'] == _selectedDayDate.day)
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      children: [
        _buildDynamicSectionHeader('sectionDailyScheduler', () { _showAddScheduleBottomSheet(context, '일정'); }),
        const SizedBox(height: 12),
        PlannerCalendarView(
          selectedDayDate: _selectedDayDate,
          isDayCalendarVisible: _isDayCalendarVisible,
          globalSchedules: _globalSchedules,
          goldColor: goldColor,
          examColor: examColor,
          schoolColor: schoolColor,
          academyColor: academyColor,
          personalColor: personalColor,
          slate400: slate400,
          slate500: slate500,
          slate800: slate800,
          onToggleCalendar: () {
            setState(() { _isDayCalendarVisible = !_isDayCalendarVisible; });
            _saveState();
          },
          onDaySelected: (newDate) {
            setState(() { _selectedDayDate = newDate; });
            _saveState();
            _syncDailyTimelineForDate(_selectedDayDate);
            _calculateMonthlyProgress();
            _showCalendarDaySchedulesPopup(_selectedDayDate.day);
          },
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(10), border: Border.all(color: slate800, width: 1.5)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: goldColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: goldColor, width: 1.5)),
                child: Text(
                  '${_selectedDayDate.month.toString().padLeft(2, '0')}/${_selectedDayDate.day.toString().padLeft(2, '0')}',
                  style: GoogleFonts.notoSerif(fontSize: 23, color: goldColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _biTitle(
                      (_selectedDayDate.year == DateTime.now().year && _selectedDayDate.month == DateTime.now().month && _selectedDayDate.day == DateTime.now().day)
                          ? 'selectedDateToday'
                          : 'selectedDateArchive',
                      enStyle: GoogleFonts.gowunBatang(fontSize: 10, color: goldColor, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      koStyle: GoogleFonts.notoSansKr(fontSize: 12, color: goldColor, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      foreignStyle: GoogleFonts.notoSans(fontSize: 12, color: goldColor, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    _biCompoundStack(
                      enText: '"${_weekdayMonFirst['EN']![_selectedDayDate.weekday - 1]}" ${_uiTextLookup('todayStatusLabel')['EN']}',
                      koText: '"${_weekdaysMonFirst()[_selectedDayDate.weekday - 1]}요일" ${_t('todayStatusLabel')}',
                      foreignText: '"${_weekdaysMonFirst()[_selectedDayDate.weekday - 1]}" ${_t('todayStatusLabel')}',
                      enStyle: GoogleFonts.gowunBatang(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                      koStyle: GoogleFonts.notoSansKr(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600),
                      foreignStyle: GoogleFonts.notoSans(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () { setState(() { _isTimeViewSelected = true; }); _saveState(); },
                child: Container(
                  margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(8), border: Border.all(color: _isTimeViewSelected ? goldColor : slate800, width: 1.5)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _biTitle(
                        'dateTimelineDetail',
                        enStyle: GoogleFonts.gowunBatang(fontSize: 11, color: _isTimeViewSelected ? goldColor : slate400, fontWeight: FontWeight.bold),
                        koStyle: GoogleFonts.notoSansKr(fontSize: 13, color: _isTimeViewSelected ? goldColor : slate400, fontWeight: FontWeight.bold),
                        foreignStyle: GoogleFonts.notoSans(fontSize: 13, color: _isTimeViewSelected ? goldColor : slate400, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () { setState(() { _isTimeViewSelected = false; }); _saveState(); },
                child: Container(
                  margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(8), border: Border.all(color: !_isTimeViewSelected ? goldColor : slate800, width: 1.5)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _biTitle(
                        'todayMainSchedule',
                        enStyle: GoogleFonts.gowunBatang(fontSize: 11, color: !_isTimeViewSelected ? goldColor : slate400, fontWeight: FontWeight.bold),
                        koStyle: GoogleFonts.notoSansKr(fontSize: 13, color: !_isTimeViewSelected ? goldColor : slate400, fontWeight: FontWeight.bold),
                        foreignStyle: GoogleFonts.notoSans(fontSize: 13, color: !_isTimeViewSelected ? goldColor : slate400, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Builder(
          builder: (context) {
            List<Map<String, dynamic>> sortedDaySchedules = List<Map<String, dynamic>>.from(targetDaySchedules);
            sortedDaySchedules.sort((a, b) => (a['time'] ?? '').toString().compareTo((b['time'] ?? '').toString()));

            if (sortedDaySchedules.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    _t('emptyDaySchedule'),
                    style: GoogleFonts.notoSansKr(color: slate500, fontSize: 12),
                  ),
                ),
              );
            }

            return Column(
              children: sortedDaySchedules.map((item) {
                return GestureDetector(
                  onTap: () { _showUnifiedPopupTrack(item, typeKey: 'DAY_MAIN'); },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF020617),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: slate800),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 56,
                          child: Text(
                            item['time'] ?? '',
                            style: GoogleFonts.notoSerif(fontSize: 12, color: goldColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(width: 3, height: 32, margin: const EdgeInsets.symmetric(horizontal: 10), color: item['color'] ?? goldColor),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['title'] ?? '', style: GoogleFonts.notoSansKr(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                              if ((item['memo'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(item['memo'], style: GoogleFonts.notoSansKr(fontSize: 11, color: slate400)),
                              ],
                            ],
                          ),
                        ),
                        _buildEditActionIcon(size: 14),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showCalendarDaySchedulesPopup(int dayNum) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext innerContext, StateSetter setPopupState) {
            List<Map<String, dynamic>> targetSchedules = _globalSchedules
                .where((s) => s['year'] == _selectedDayDate.year && s['month'] == _selectedDayDate.month && s['day'] == dayNum)
                .toList();

            return AlertDialog(
              backgroundColor: const Color(0xFF020617),
              shape: RoundedRectangleBorder(side: BorderSide(color: goldColor, width: 1.5), borderRadius: BorderRadius.circular(12)),
              title: _biTitle(
                'popupDateMainSchedulesTitle',
                enStyle: GoogleFonts.notoSerif(fontSize: 14, color: goldColor, fontWeight: FontWeight.bold),
                koStyle: GoogleFonts.notoSansKr(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
                foreignStyle: GoogleFonts.notoSans(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(_monthDayText(_selectedDayDate.month, dayNum), style: GoogleFonts.notoSerif(fontSize: 12, color: goldColor, fontWeight: FontWeight.bold)),
                      ),
                      const Divider(color: Color(0xFF1E293B), height: 10),
                      const SizedBox(height: 8),
                      if (targetSchedules.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(child: Text(_t('emptyDayMainSchedule2'), style: GoogleFonts.notoSansKr(fontSize: 12, color: slate500))),
                        )
                      else
                        ...targetSchedules.map((item) {
                          String catStr = '[${_biStr('catSchool')}]';
                          if (item['color'] == academyColor) { catStr = '[${_biStr('catAcademy')}]'; }
                          if (item['color'] == examColor) catStr = '[${_biStr('catExam')}]';
                          if (item['color'] == personalColor) catStr = '[${_biStr('catPersonal')}]';

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 5), padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8), border: Border.all(color: item['color'].withValues(alpha: 0.4), width: 1)),
                            child: Row(
                              children: [
                                Text('■ ', style: TextStyle(color: item['color'], fontSize: 16)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('$catStr ${item['title']}', style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                                      if ((item['memo'] ?? '').toString().isNotEmpty)
                                        Padding(padding: const EdgeInsets.only(top: 2.0), child: Text(item['memo'], style: GoogleFonts.notoSansKr(fontSize: 11, color: slate400))),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () { Navigator.of(dialogContext).pop(); _showActualEditorPopup(item, typeKey: 'DAY_MAIN'); },
                                  child: Icon(Icons.settings, color: goldColor, size: 16),
                                )
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () { Navigator.of(dialogContext).pop(); },
                      child: Text(_biStr('btnClose'), style: GoogleFonts.notoSansKr(color: slate400, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: goldColor, visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.add, size: 14, color: Color(0xFF020617)),
                      label: Text(_biStr('btnAdd'), style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF020617), fontWeight: FontWeight.bold)),
                      onPressed: () { Navigator.of(dialogContext).pop(); _showCalendarQuickAddPopup(dayNum); },
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

  // [주석] 일정 추가 클릭 시 호출되는 팝업: 학교, 회사, 학원, 시험, 개인 항목 중 "개인"을 학교 아래로 줄 바꿔 배치
  // 🆕 [12개국] 카테고리 내부 값(tempCategory)은 기존 로직/색상 매핑 호환을 위해 한국어 키를 그대로 유지하고,
  // 화면에 보이는 라벨만 _biStr()로 번역 처리합니다.
  void _showCalendarQuickAddPopup(int dayNum) {
    final TextEditingController quickTitleController = TextEditingController();
    final TextEditingController quickMemoController = TextEditingController();
    String tempCategory = '학교';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext popContext, StateSetter setPopState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF020617),
              shape: RoundedRectangleBorder(side: BorderSide(color: goldColor, width: 1.5), borderRadius: BorderRadius.circular(12)),
              title: _biTitle(
                'popupAddCalendarEntryTitle',
                enStyle: GoogleFonts.notoSerif(fontSize: 14, color: goldColor, fontWeight: FontWeight.bold),
                koStyle: GoogleFonts.notoSansKr(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                foreignStyle: GoogleFonts.notoSans(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(_monthDayText(_selectedDayDate.month, dayNum), style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                      ),
                      Text(_biStr('labelCategorySelect'), style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 6,
                        children: [
                          {'value': '학교', 'labelKey': 'catSchool'},
                          {'value': '학원', 'labelKey': 'catAcademy'},
                          {'value': '시험', 'labelKey': 'catExam'},
                          {'value': '개인', 'labelKey': 'catPersonal'},
                        ].map((cat) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: cat['value']!,
                                groupValue: tempCategory,
                                activeColor: goldColor,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                onChanged: (value) { setPopState(() { tempCategory = value!; }); },
                              ),
                              Container(width: 12, height: 12, margin: const EdgeInsets.only(right: 4), decoration: BoxDecoration(color: _categoryColorFor(cat['value']!), borderRadius: BorderRadius.circular(2))),
                              Text(_biStr(cat['labelKey']!), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(fontSize: 11, color: Colors.white)),
                            ],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Text(_biStr('labelTitleField'), style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: quickTitleController, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: _biStr('hintScheduleTitle'), hintStyle: GoogleFonts.notoSansKr(color: slate500, fontSize: 12),
                          filled: true, fillColor: const Color(0xFF0F172A),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(_biStr('labelMemo'), style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: quickMemoController, maxLines: 2, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: _biStr('hintScheduleDetail'), hintStyle: GoogleFonts.notoSansKr(color: slate500, fontSize: 12),
                          filled: true, fillColor: const Color(0xFF0F172A),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: goldColor),
                      onPressed: () {
                        if (quickTitleController.text.trim().isEmpty) return;
                        Color choiceColor = schoolColor;
                        if (tempCategory == '개인') choiceColor = personalColor;
                        if (tempCategory == '학원') choiceColor = academyColor;
                        if (tempCategory == '시험') choiceColor = examColor;

                        setState(() {
                          _globalSchedules.add({
                            'year': _selectedDayDate.year, 'month': _selectedDayDate.month, 'day': dayNum, 'time': '12:00',
                            'title': quickTitleController.text.trim(), 'color': choiceColor, 'memo': quickMemoController.text.trim(),
                          });
                          _sortGlobalSchedules();
                        });

                        _saveMasterData();
                        Navigator.of(dialogContext).pop();
                        _showCalendarDaySchedulesPopup(dayNum);
                      },
                      child: Text(_biStr('btnSaveApply'), style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF020617), fontWeight: FontWeight.bold)),
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

  // 🆕 [2026-08-02] 일간/주간/월간/연간 리스트 항목 공통 "탭하여 수정" 표시 아이콘.
  // 기존 눈(remove_red_eye) 아이콘 대신 3선(메뉴) + 연필 조합으로 통일 표시함.
  Widget _buildEditActionIcon({double size = 14}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.menu, color: goldColor.withValues(alpha: 0.45), size: size),
        SizedBox(width: size * 0.18),
        Icon(Icons.edit, color: goldColor.withValues(alpha: 0.85), size: size),
      ],
    );
  }

  Widget _buildReadOnlyStaticTargetItem(String targetText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(Icons.adjust, color: goldColor, size: 14),
          const SizedBox(width: 10),
          Expanded(child: Text(targetText, style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white))),
        ],
      ),
    );
  }

  void _showUnifiedPopupTrack(Map<String, dynamic> targetItem, {required String typeKey, int index = 0}) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        bool isStarred = targetItem['is_starred'] ?? false;

        return StatefulBuilder(
          builder: (BuildContext viewContext, StateSetter setViewState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF020617),
              shape: RoundedRectangleBorder(side: BorderSide(color: goldColor, width: 1.5), borderRadius: BorderRadius.circular(12)),
              titlePadding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 4),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: _biTitle(
                'popupMissionDetailsTitle',
                enStyle: GoogleFonts.notoSerif(fontSize: 14, color: goldColor, fontWeight: FontWeight.bold),
                koStyle: GoogleFonts.notoSansKr(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
                foreignStyle: GoogleFonts.notoSans(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: Color(0xFF1E293B), height: 10),
                    const SizedBox(height: 8),
                    _buildReadOnlyLine('⏰ ${_biStr('labelTime')}', targetItem['time'] ?? _biStr('labelAllDay')),
                    _buildReadOnlyLine('📚 ${_biStr('labelTitleField')}', targetItem['title'] ?? ''),
                    if (typeKey == 'DAY_TIME') ...[
                      _buildReadOnlyLine('📂 ${_biStr('labelCategory')}', '[${_categoryDisplayLabel(targetItem['category'])}]'),
                      if (targetItem['category'] == '문제집' && (targetItem['custom_book'] ?? '').toString().isNotEmpty)
                        _buildReadOnlyLine('📘 ${_biStr('labelTextbook')}', targetItem['custom_book']),
                    ],
                    _buildReadOnlyLine('📢 ${_biStr('labelMemo')}', targetItem['memo'] ?? _biStr('labelNoMemo')),
                    const SizedBox(height: 10),
                    if (typeKey == 'DAY_TIME') ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: isStarred ? slate500 : goldColor, width: 1.5),
                            backgroundColor: isStarred ? Colors.transparent : goldColor.withValues(alpha: 0.08),
                          ),
                          icon: Icon(isStarred ? Icons.star : Icons.star_border, color: goldColor, size: 18),
                          label: Text(
                            isStarred ? _biStr('starCollected') : _biStr('starCollectAction'),
                            style: GoogleFonts.notoSansKr(fontSize: 12, color: isStarred ? slate400 : goldColor, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            setViewState(() { isStarred = !isStarred; });
                            setState(() { _fixedDayTimelines[index]['is_starred'] = isStarred; });
                            _calculateMonthlyProgress();
                            _saveMasterData();
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () { Navigator.of(dialogContext).pop(); },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text(_biStr('btnClose'), style: GoogleFonts.notoSansKr(color: slate400, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: goldColor, visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.settings, size: 14, color: Color(0xFF020617)),
                      label: Text(_biStr('btnEdit'), style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF020617), fontWeight: FontWeight.bold)),
                      onPressed: () { Navigator.of(dialogContext).pop(); _showActualEditorPopup(targetItem, typeKey: typeKey, index: index); },
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

  // 🆕 [2026-07-30] 시간 미입력 시 사용할 현재 시각 문자열 (HH:mm)
  String _currentTimeString() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  // 🆕 [2026-07-30] 카테고리 값(한국어 고정 키) → 실제 테마 색상 매핑 (색깔 정사각형 표시용)
  Color _categoryColorFor(String catValue) {
    switch (catValue) {
      case '학원': return academyColor;
      case '시험': return examColor;
      case '개인': return personalColor;
      default: return schoolColor;
    }
  }

  // 🆕 [12개국] 내부 카테고리 값(한국어 고정 키)을 화면 표시용 번역 라벨로 변환
  String _categoryDisplayLabel(String? category) {
    switch (category) {
      case '학원': return _biStr('catAcademy');
      case '동영상': return _biStr('catVideo');
      case '문제집': return _biStr('catWorkbook');
      case '교과서': return _biStr('catTextbook');
      case '기타': return _biStr('catEtc');
      default: return category ?? _biStr('catEtc');
    }
  }

  Widget _buildReadOnlyLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showActualEditorPopup(Map<String, dynamic> targetItem, {required String typeKey, int index = 0}) {
    final TextEditingController editTimeController = TextEditingController(text: targetItem['time'] ?? '');
    final TextEditingController editTitleController = TextEditingController(text: targetItem['title'] ?? '');
    final TextEditingController editMemoController = TextEditingController(text: targetItem['memo'] ?? '');
    String currentCategory = targetItem['category'] ?? '기타';
    final List<Map<String, String>> categoriesList = [
      {'value': '학원', 'labelKey': 'catAcademy'},
      {'value': '동영상', 'labelKey': 'catVideo'},
      {'value': '문제집', 'labelKey': 'catWorkbook'},
      {'value': '교과서', 'labelKey': 'catTextbook'},
      {'value': '기타', 'labelKey': 'catEtc'},
    ];
    final TextEditingController bookInputController = TextEditingController(text: targetItem['custom_book'] ?? '');

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext popContext, StateSetter setPopState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF020617),
              shape: RoundedRectangleBorder(side: BorderSide(color: goldColor, width: 1), borderRadius: BorderRadius.circular(12)),
              title: _biTitle(
                'popupEditModeTitle',
                enStyle: GoogleFonts.notoSerif(fontSize: 14, color: goldColor, fontWeight: FontWeight.bold),
                koStyle: GoogleFonts.notoSansKr(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
                foreignStyle: GoogleFonts.notoSans(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_biStr('labelTime'), style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                    TextField(
                      controller: editTimeController, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: _biStr('hintTimeInput'), hintStyle: GoogleFonts.notoSansKr(color: slate400, fontSize: 12),
                        filled: true, fillColor: const Color(0xFF0F172A),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(_biStr('labelTitleField'), style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                    TextField(
                      controller: editTitleController, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: _biStr('labelSubjectTitle'), hintStyle: GoogleFonts.notoSansKr(color: slate400, fontSize: 12),
                        filled: true, fillColor: const Color(0xFF0F172A),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (typeKey == 'DAY_TIME') ...[
                      Text(_biStr('labelCategorySelect'), style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 6, runSpacing: 4,
                        children: categoriesList.map((category) {
                          bool isSel = currentCategory == category['value'];
                          return ChoiceChip(
                            label: Text(_biStr(category['labelKey']!), style: GoogleFonts.notoSansKr(fontSize: 11, color: isSel ? const Color(0xFF020617) : Colors.white, fontWeight: FontWeight.bold)),
                            selected: isSel, selectedColor: goldColor, backgroundColor: const Color(0xFF0F172A),
                            checkmarkColor: const Color(0xFF020617), side: BorderSide(color: isSel ? goldColor : slate800),
                            onSelected: (bool selected) { if (selected) { setPopState(() { currentCategory = category['value']!; }); } },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      if (currentCategory == '문제집') ...[
                        Text(_biStr('labelTextbook'), style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                        TextField(
                          controller: bookInputController, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: _biStr('hintWorkbookName'), hintStyle: GoogleFonts.notoSansKr(color: slate500, fontSize: 12),
                            filled: true, fillColor: const Color(0xFF0F172A),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                    Text(_biStr('labelMemo'), style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                    TextField(
                      controller: editMemoController, maxLines: 2, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: _biStr('hintMemoInput'), hintStyle: GoogleFonts.notoSansKr(color: slate400, fontSize: 12),
                        filled: true, fillColor: const Color(0xFF0F172A),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (typeKey == 'DAY_TIME')
                      TextButton(
                        onPressed: () {
                          final String dateKey = "${_selectedDayDate.year}-${_selectedDayDate.month.toString().padLeft(2, '0')}-${_selectedDayDate.day.toString().padLeft(2, '0')}";
                          setState(() {
                            _fixedDayTimelines.removeAt(index);
                            _dailyExecutionInstanceMap[dateKey] = _fixedDayTimelines;
                          });
                          _calculateMonthlyProgress();
                          _saveMasterData();
                          Navigator.of(dialogContext).pop();
                        },
                        child: Text(_biStr('btnDelete'), style: GoogleFonts.notoSansKr(color: examColor, fontSize: 13, fontWeight: FontWeight.bold)),
                      )
                    else if (typeKey != 'DAY_TIME')
                      TextButton(
                        onPressed: () {
                          setState(() { _globalSchedules.removeWhere((s) => s['title'] == targetItem['title'] && s['day'] == targetItem['day'] && s['month'] == targetItem['month']); });
                          _saveMasterData();
                          Navigator.of(dialogContext).pop();
                        },
                        child: Text(_biStr('btnDelete'), style: GoogleFonts.notoSansKr(color: examColor, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        String newTime = editTimeController.text.trim();
                        String newTitle = editTitleController.text.trim();
                        String newMemo = editMemoController.text.trim();
                        if (newTitle.isEmpty) return;

                        setState(() {
                          if (typeKey == 'DAY_TIME') {
                            _fixedDayTimelines[index]['time'] = newTime.isEmpty ? _fixedDayTimelines[index]['time'] : newTime;
                            _fixedDayTimelines[index]['title'] = newTitle;
                            _fixedDayTimelines[index]['memo'] = newMemo;
                            _fixedDayTimelines[index]['category'] = currentCategory;
                            _fixedDayTimelines[index]['custom_book'] = currentCategory == '문제집' ? bookInputController.text.trim() : '';
                          } else {
                            int idx = _globalSchedules.indexOf(targetItem);
                            if (idx != -1) {
                              _globalSchedules[idx]['time'] = newTime;
                              _globalSchedules[idx]['title'] = newTitle;
                              _globalSchedules[idx]['memo'] = newMemo;
                              _sortGlobalSchedules();
                            }
                          }
                        });

                        _calculateMonthlyProgress();
                        _saveMasterData();
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text(_biStr('btnSave'), style: GoogleFonts.notoSansKr(color: goldColor, fontSize: 13, fontWeight: FontWeight.bold)),
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

  Widget _buildDynamicSectionHeader(String textKey, VoidCallback onAddTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          // 🆕 [폰트/언어 수정 2026-07-29] 한글 단독 표시 버그 수정 - 영문(고운바탕)+한글(노토산스) 2줄 기본,
          // 10개국어 선택 시 단일 언어로 자동 전환. 오버플로우도 _biTitle 내부에서 자동 방지됨.
          child: _biTitle(
            textKey,
            enStyle: GoogleFonts.gowunBatang(fontSize: 13, color: goldColor, fontWeight: FontWeight.bold),
            koStyle: GoogleFonts.notoSansKr(fontSize: 16, color: goldColor, fontWeight: FontWeight.bold),
            foreignStyle: GoogleFonts.notoSans(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onAddTap,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: goldColor, width: 1.5), color: goldColor.withValues(alpha: 0.08)),
            child: Icon(Icons.add, color: goldColor, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildYearChecklistItem(String title, bool isChecked, int index, String yearKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() { _yearlyTargetsMap[yearKey]![index]['done'] = !isChecked; });
              _saveMasterData();
            },
            child: Container(
              padding: const EdgeInsets.all(4.0), color: Colors.transparent,
              child: Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank, color: isChecked ? goldColor : slate500, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                _showUnifiedPopupTrack({
                  'time': '${_yearNumText(yearKey)} ${_biStr('yearChecklistPopupTimeLabel')}', 'title': title,
                  'memo': _biStr('yearChecklistPopupMemo'), 'done': isChecked,
                }, typeKey: 'YEAR');
              },
              child: Container(
                color: Colors.transparent, alignment: Alignment.centerLeft,
                child: Text(title, style: GoogleFonts.notoSansKr(fontSize: 12, color: isChecked ? slate400 : Colors.white, decoration: isChecked ? TextDecoration.lineThrough : null)),
              ),
            ),
          ),
          _buildEditActionIcon(size: 14),
        ],
      ),
    );
  }

  // 🆕 [2026-08-03] 월간 "학습 리스트" 체크리스트 항목 - 연간 체크리스트와 완전히 동일한 스타일
  // (체크박스 탭 → 완료 처리 + 줄긋기, 텍스트 탭 → 상세 팝업). labelKey는 번역 카탈로그 키이므로
  // 표시 문구는 항상 현재 언어 설정에 맞게 다시 생성됨.
  Widget _buildMonthChecklistItem(String labelKey, bool isChecked, int index, int monthKey) {
    final String displayTitle = '${_monthNumText(monthKey)} ${_t(labelKey)}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() { _monthlyTargetsMap[monthKey]![index]['done'] = !isChecked; });
              _saveMasterData();
            },
            child: Container(
              padding: const EdgeInsets.all(4.0), color: Colors.transparent,
              child: Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank, color: isChecked ? goldColor : slate500, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                _showUnifiedPopupTrack({
                  'time': '${_monthNumText(monthKey)} ${_t('monthMasterPack')}', 'title': displayTitle,
                  'memo': _biStr('monthChecklistPopupMemo'), 'done': isChecked,
                }, typeKey: 'MONTH_TARGET');
              },
              child: Container(
                color: Colors.transparent, alignment: Alignment.centerLeft,
                child: Text(displayTitle, style: GoogleFonts.notoSansKr(fontSize: 12, color: isChecked ? slate400 : Colors.white, decoration: isChecked ? TextDecoration.lineThrough : null)),
              ),
            ),
          ),
          _buildEditActionIcon(size: 14),
        ],
      ),
    );
  }

  Widget _buildScheduleTimelineItem(String timeLabel, String eventTitle, Color leftBarColor, int index, String memo) {
    return GestureDetector(
      onTap: () { if (index >= 0 && index < _globalSchedules.length) { _showUnifiedPopupTrack(_globalSchedules[index], typeKey: 'YEAR'); } },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF020617), border: Border(left: BorderSide(color: leftBarColor, width: 4))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(timeLabel, style: GoogleFonts.notoSerif(fontSize: 12, color: goldColor)),
            Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14.0), child: Text(eventTitle, style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.right))),
            _buildEditActionIcon(size: 14),
          ],
        ),
      ),
    );
  }

  // 🆕 [12개국] 내부 entryType/selectedCategory 값(한국어 고정 키)은 그대로 유지, 표시 라벨만 번역
  void _showAddScheduleBottomSheet(BuildContext context, String initialType) {
    String entryType = initialType; String selectedCategory = '학교';
    final TextEditingController titleController = TextEditingController();
    final TextEditingController monthController = TextEditingController();
    final TextEditingController dayController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    final TextEditingController memoController = TextEditingController();

    final List<Map<String, String>> entryTypeOptions = [
      {'value': '일정', 'labelKey': 'entryTypeSchedule'},
      {'value': '목표', 'labelKey': 'entryTypeTarget'},
    ];
    final List<Map<String, String>> scheduleCategoryOptions = [
      {'value': '학교', 'labelKey': 'catSchool'},
      {'value': '학원', 'labelKey': 'catAcademy'},
      {'value': '시험', 'labelKey': 'catExam'},
      {'value': '개인', 'labelKey': 'catPersonal'},
    ];

    showModalBottomSheet(
      context: context, backgroundColor: const Color(0xFF020617), isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (BuildContext bc) {
        return StatefulBuilder(
          builder: (BuildContext modalContext, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _biTitle(
                      'popupAddNewEntryTitle',
                      enStyle: GoogleFonts.notoSerif(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold),
                      koStyle: GoogleFonts.notoSansKr(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
                      foreignStyle: GoogleFonts.notoSans(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 20),
                    Row(
                      children: entryTypeOptions.map((type) {
                        return Row(children: [
                          Radio<String>(value: type['value']!, groupValue: entryType, activeColor: goldColor, onChanged: (value) { setModalState(() { entryType = value!; }); }),
                          Text(_biStr(type['labelKey']!), style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white)), const SizedBox(width: 20),
                        ]);
                      }).toList(),
                    ),
                    if (entryType == '일정') ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: scheduleCategoryOptions.map((cat) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 14.0),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Radio<String>(value: cat['value']!, groupValue: selectedCategory, activeColor: goldColor, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact, onChanged: (value) { setModalState(() { selectedCategory = value!; }); }),
                                Container(width: 12, height: 12, margin: const EdgeInsets.only(right: 4), decoration: BoxDecoration(color: _categoryColorFor(cat['value']!), borderRadius: BorderRadius.circular(2))),
                                Text(_biStr(cat['labelKey']!), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white)),
                              ]),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleController, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(hintText: entryType == '일정' ? _biStr('hintTitleGeneric') : _biStr('hintTargetGeneric'), filled: true, fillColor: const Color(0xFF0F172A), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor))),
                    ),

                    if (entryType == '일정') ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: monthController, keyboardType: TextInputType.number, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12), decoration: InputDecoration(hintText: _biStr('hintMonth'), filled: true, fillColor: const Color(0xFF0F172A), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor))))),
                          const SizedBox(width: 10),
                          Expanded(child: TextField(controller: dayController, keyboardType: TextInputType.number, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12), decoration: InputDecoration(hintText: _biStr('hintDay'), filled: true, fillColor: const Color(0xFF0F172A), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor))))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(_biStr('labelTime'), style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: timeController,
                        style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: '${_biStr('hintTimeInput')} (${_currentTimeString()})',
                          hintStyle: GoogleFonts.notoSansKr(color: slate500, fontSize: 11),
                          filled: true, fillColor: const Color(0xFF0F172A),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: memoController, maxLines: 2, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(hintText: _biStr('hintMemoPlan'), filled: true, fillColor: const Color(0xFF0F172A), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor))),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity, height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: goldColor),
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) return;
                          if (entryType == '목표') {
                            String currentYearKey = _scrollableYears[_selectedYearIndex];
                            setState(() { _yearlyTargetsMap[currentYearKey]!.add({'title': titleController.text.trim(), 'done': false}); });
                            _saveMasterData();
                          } else {
                            Color sColor = schoolColor;
                            if (selectedCategory == '학원') sColor = academyColor;
                            if (selectedCategory == '시험') sColor = examColor;
                            if (selectedCategory == '개인') sColor = personalColor;
                            int inputMonth = int.tryParse(monthController.text.trim()) ?? 7;
                            int inputDay = int.tryParse(dayController.text.trim()) ?? 1;
                            String finalTime = timeController.text.trim().isEmpty ? _currentTimeString() : timeController.text.trim();

                            setState(() {
                              _globalSchedules.add({
                                'year': 2026, 'month': inputMonth, 'day': inputDay, 'time': finalTime,
                                'title': titleController.text.trim(), 'color': sColor, 'memo': memoController.text.trim(),
                              });
                              _sortGlobalSchedules();
                              _selectedDayDate = DateTime(2026, inputMonth, inputDay);
                            });

                            _syncDailyTimelineForDate(_selectedDayDate);
                            _calculateMonthlyProgress();
                            _saveState();
                            _saveMasterData();
                          }
                          Navigator.pop(modalContext);
                        },
                        child: Text(_biStr('btnSaveApplyLink'), style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF020617), fontWeight: FontWeight.bold)),
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
// [주석] 학사 타임라인 타이틀 및 선택된 시간표 리스트 동적 렌더링 위젯
  Widget _buildAcademicTimelineSection(String modeTitleEn, String modeTitleKo, List<Map<String, String>> timelineItems) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: slate800, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // [주석] 타이틀 영역: 영문 명조체(크기 15) + 노토 산스 한글(크기 15, 황금색)
          Text(modeTitleEn, style: GoogleFonts.notoSerif(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(modeTitleKo, style: GoogleFonts.notoSansKr(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold)),
          const Divider(color: Color(0xFF1E293B), height: 16),

          // [주석] 바로 아래 시간표 이름 및 상세 내용 리스트 렌더링
          if (timelineItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(_biStr('academicTimelineEmptyState'), style: GoogleFonts.notoSansKr(color: slate500, fontSize: 12)),
            )
          else
            ...timelineItems.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 90,
                      // [주석] 시간 표시 (일반글자크기 12, 황금색 명조)
                      child: Text(item['time'] ?? '', style: GoogleFonts.notoSerif(fontSize: 12, color: goldColor, fontWeight: FontWeight.bold)),
                    ),
                    Container(width: 3, height: 24, margin: const EdgeInsets.symmetric(horizontal: 8), color: goldColor),
                    Expanded(
                      // [주석] 과목 및 태스크명 표시 (일반글자크기 12, 노토 산스 한글)
                      child: Text(item['task'] ?? '', style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
