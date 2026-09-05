// ============================================================================
// 🆕 [일반 플래너 4단계 - 최종] GeneralPlannerHomeScreen
// 1단계(일정)+2단계(타임라인)+3단계(목표)+4단계(리포트)까지 전체 4개 대분류가
// 모두 실제로 연결된 최종 버전입니다. "약속/프로젝트/알림/일정분석"만 아직
// 준비 중이며, 나머지 모든 메뉴는 실제 데이터를 저장/불러오는 화면입니다.
// 디자인 톤: 기존 home_dashboard_screen.dart와 동일한 다크네이비+골드 테마.
//
// ✅ [2026-08-16 수정] 알람 감시자(ReminderWatcherService)가 리마인더/약속
// 화면에 들어가야만 시작되는 문제를 발견했습니다. 사용자가 그 화면들에
// 안 들어가면 감시자가 아예 안 켜져서 "매일"/"매주" 알람이 통째로 안
// 울리는 원인이 됐습니다. 그래서 앱의 진입점인 이 홈 화면에서부터 감시자를
// 시작하도록 옮겼습니다(리마인더/약속 화면에서도 계속 start()를 호출하지만,
// 싱글턴이라 중복 시작은 안전하게 무시됩니다).
//
// ✅ [2026-09-04 추가] SCHEDULE 섹션에 "운동(EXERCISE)" 메뉴 추가.
// 탭하면 ExerciseTypeScreen(운동 종목 리스트)으로 이동. 캘린더/알림/일정분석과
// 데이터가 연동되도록 exercise_data_service.dart를 공용 게이트웨이로 사용.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_language_service.dart'; // 🆕 [10개국어 확장]
import 'bilingual_text.dart'; // 🆕 [10개국어 확장] BiTitle 사용 (appLanguage도 이 파일에서 함께 제공됨)
import 'calendar_screen.dart';
import 'appointment_screen.dart';
import 'project_screen.dart';
import 'reminder_screen.dart';
import 'reminder_watcher_service.dart'; // 🆕 [2026-08-16 추가] 홈 화면에서부터 알람 감시자를 시작하기 위함
import 'schedule_analysis_screen.dart';
import 'today_schedule_screen.dart';
import 'today_timeline_screen.dart';
import 'routine_screen.dart';
import 'execution_record_screen.dart';
import 'timeline_history_screen.dart';
import 'timeline_analysis_screen.dart';
import 'timer_calculator_screen.dart'; // 🆕 일반인용 독립 타이머·계산기
import 'life_goal_screen.dart';
import 'yearly_goal_screen.dart';
import 'monthly_goal_screen.dart';
import 'weekly_goal_screen.dart';
import 'today_goal_screen.dart';
import 'todo_screen.dart';
import 'progress_screen.dart';
import 'achievement_screen.dart';
import 'daily_report_screen.dart';
import 'weekly_report_screen.dart';
import 'monthly_report_screen.dart';
import 'yearly_report_screen.dart';
import 'statistics_screen.dart';
import 'exercise_type_screen.dart'; // 🆕 [2026-09-04 추가] 운동 종목 리스트 화면
import 'exercise_analysis_screen.dart'; // 🆕 [2026-09-05 추가] 운동 분석 화면 (홈에서 바로 진입)

class GeneralPlannerHomeScreen extends StatefulWidget {
  const GeneralPlannerHomeScreen({super.key});

  @override
  State<GeneralPlannerHomeScreen> createState() => _GeneralPlannerHomeScreenState();
}

class _GeneralPlannerHomeScreenState extends State<GeneralPlannerHomeScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  @override
  void initState() {
    super.initState();
    // 🆕 [10개국어 확장] 홈 화면 진입 시 저장된 언어 설정을 불러옴
    appLanguage.initialize().then((_) {
      if (mounted) setState(() {});
    });
    // 🆕 [버그 수정] 마이페이지 등 "다른 화면"에서 언어를 바꿔도 이 화면이
    // 실시간으로 알아채도록 리스너를 계속 붙여둠 (예전엔 이 화면에 처음
    // 들어올 때 딱 한 번만 확인해서, 다른 곳에서 바꾸면 못 알아챘음)
    appLanguage.addListener(_onLanguageChanged);
    // ✅ [2026-08-16 추가] 알람 감시자를 홈 화면 진입 시점부터 시작. 리마인더나
    // 약속 화면에 안 들어가도 "매일"/"매주" 알람이 계속 감시되도록 하기 위함.
    ReminderWatcherService.instance.start();
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: BiTitle(
          en: 'GENERAL PLANNER', ko: '일반 플래너', enSize: 22, koSize: 15,
          translations: const {'JA': '一般プランナー', 'ZH': '通用规划器', 'FR': 'Planificateur Général', 'DE': 'Allgemeiner Planer', 'RU': 'Общий планировщик', 'AR': 'المخطط العام', 'HI': 'सामान्य प्लानर', 'VI': 'Trình lập kế hoạch chung', 'ES': 'Planificador General', 'TH': 'ตัววางแผนทั่วไป'},
        ), // 🆕 [빠짐 수정] 앱 최상단 제목 번역 누락 발견 및 추가
        // 🆕 [정리] 자체 언어선택 아이콘 제거함 - 마이페이지의 12개국어 전환
        // 기능을 그대로 재사용합니다 (저장 키를 공유하므로 자동으로 반영됨)
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('SCHEDULE', '일정'),
            const SizedBox(height: 12),
            _buildMenuGrid(context, [
              _MenuEntry('📅', 'CALENDAR', '캘린더', () => _navigate(context, const CalendarScreen())),
              _MenuEntry('📝', "TODAY'S SCHEDULE", '오늘의 일정', () => _navigate(context, const TodayScheduleScreen())),
              _MenuEntry('⏰', 'APPOINTMENT', '약속', () => _navigate(context, const AppointmentScreen())),
              _MenuEntry('📌', 'PROJECT', '프로젝트', () => _navigate(context, const ProjectScreen())),
              _MenuEntry('🔔', 'REMINDER', '알림', () => _navigate(context, const ReminderScreen())),
              _MenuEntry('🏃', 'EXERCISE', '운동', () => _navigate(context, const ExerciseTypeScreen())), // 🆕 [2026-09-04 추가]
              _MenuEntry('📈', 'SCHEDULE ANALYSIS', '일정 분석', () => _navigate(context, const ScheduleAnalysisScreen())),
              // 🆕 [2026-09-05 이동] 홈 상단 큰 배너였던 것을 "일정분석" 옆 빈 칸으로 이동.
              // 7개(홀수)였던 그리드가 8개(짝수)로 채워져서 빈 공간 없이 딱 맞음.
              _MenuEntry('📊', 'EXERCISE ANALYSIS', '운동 분석', () => _navigate(context, const ExerciseAnalysisScreen())),
            ]),
            const SizedBox(height: 30),

            _buildSectionTitle('TIMELINE', '타임라인'),
            const SizedBox(height: 12),
            _buildMenuGrid(context, [
              _MenuEntry('🕒', "TODAY'S TIMELINE", '오늘의 타임라인', () => _navigate(context, const TodayTimelineScreen())),
              _MenuEntry('🔁', 'ROUTINE', '루틴', () => _navigate(context, const RoutineScreen())),
              _MenuEntry('📜', 'TIMELINE HISTORY', '타임라인 기록', () => _navigate(context, const TimelineHistoryScreen())),
              _MenuEntry('✅', 'EXECUTION RECORD', '실행 기록', () => _navigate(context, const ExecutionRecordScreen())),
              _MenuEntry('📊', 'TIMELINE ANALYSIS', '타임라인 분석', () => _navigate(context, const TimelineAnalysisScreen())),
              _MenuEntry('⏱️', 'TIMER CALCULATOR', '타이머 계산기', () => _navigate(context, const TimerCalculatorScreen())),
            ]),
            const SizedBox(height: 30),

            _buildSectionTitle('GOAL', '목표'),
            const SizedBox(height: 12),
            _buildMenuGrid(context, [
              _MenuEntry('🎯', 'LIFE GOAL', '인생 목표', () => _navigate(context, const LifeGoalScreen())),
              _MenuEntry('📅', 'YEARLY GOAL', '연간 목표', () => _navigate(context, const YearlyGoalScreen())),
              _MenuEntry('📅', 'MONTHLY GOAL', '월간 목표', () => _navigate(context, const MonthlyGoalScreen())),
              _MenuEntry('📅', 'WEEKLY GOAL', '주간 목표', () => _navigate(context, const WeeklyGoalScreen())),
              _MenuEntry('📅', 'TODAY GOAL', '오늘 목표', () => _navigate(context, const TodayGoalScreen())),
              _MenuEntry('✅', 'TODO', '할 일', () => _navigate(context, const TodoScreen())),
              _MenuEntry('📈', 'PROGRESS', '진행률', () => _navigate(context, const ProgressScreen())),
              _MenuEntry('🏆', 'ACHIEVEMENT', '성취', () => _navigate(context, const AchievementScreen())),
            ]),
            const SizedBox(height: 30),

            _buildSectionTitle('REPORT', '리포트'),
            const SizedBox(height: 12),
            _buildMenuGrid(context, [
              _MenuEntry('📊', 'DAILY REPORT', '일간 리포트', () => _navigate(context, const DailyReportScreen())),
              _MenuEntry('📊', 'WEEKLY REPORT', '주간 리포트', () => _navigate(context, const WeeklyReportScreen())),
              _MenuEntry('📊', 'MONTHLY REPORT', '월간 리포트', () => _navigate(context, const MonthlyReportScreen())),
              _MenuEntry('📊', 'YEARLY REPORT', '연간 리포트', () => _navigate(context, const YearlyReportScreen())),
              _MenuEntry('📈', 'STATISTICS', '통계', () => _navigate(context, const StatisticsScreen())),
            ]),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 🆕 [10개국어 확장] 홈 화면의 모든 섹션제목/메뉴이름 번역표.
  // 키는 영문 라벨(en) 그대로 사용 - 외국어 선택 시 이 표에서 찾아서 단독 표시.
  static const Map<String, Map<String, String>> _t = {
    // 섹션 제목 4개
    'SCHEDULE': {'JA': 'スケジュール', 'ZH': '日程', 'FR': 'Planning', 'DE': 'Zeitplan', 'RU': 'Расписание', 'AR': 'الجدول', 'HI': 'शेड्यूल', 'VI': 'Lịch trình', 'ES': 'Horario', 'TH': 'ตารางเวลา'},
    'TIMELINE': {'JA': 'タイムライン', 'ZH': '时间线', 'FR': 'Chronologie', 'DE': 'Zeitleiste', 'RU': 'Хронология', 'AR': 'الجدول الزمني', 'HI': 'समयरेखा', 'VI': 'Dòng thời gian', 'ES': 'Cronología', 'TH': 'ไทม์ไลน์'},
    'GOAL': {'JA': '目標', 'ZH': '目标', 'FR': 'Objectif', 'DE': 'Ziel', 'RU': 'Цель', 'AR': 'الهدف', 'HI': 'लक्ष्य', 'VI': 'Mục tiêu', 'ES': 'Objetivo', 'TH': 'เป้าหมาย'},
    'REPORT': {'JA': 'レポート', 'ZH': '报告', 'FR': 'Rapport', 'DE': 'Bericht', 'RU': 'Отчёт', 'AR': 'التقرير', 'HI': 'रिपोर्ट', 'VI': 'Báo cáo', 'ES': 'Informe', 'TH': 'รายงาน'},
    // 일정 7개 (🆕 운동 추가)
    'CALENDAR': {'JA': 'カレンダー', 'ZH': '日历', 'FR': 'Calendrier', 'DE': 'Kalender', 'RU': 'Календарь', 'AR': 'التقويم', 'HI': 'कैलेंडर', 'VI': 'Lịch', 'ES': 'Calendario', 'TH': 'ปฏิทิน'},
    "TODAY'S SCHEDULE": {'JA': '今日の予定', 'ZH': '今日日程', 'FR': "Programme du jour", 'DE': 'Heutiger Zeitplan', 'RU': 'Расписание на сегодня', 'AR': 'جدول اليوم', 'HI': 'आज का शेड्यूल', 'VI': 'Lịch hôm nay', 'ES': 'Horario de hoy', 'TH': 'ตารางวันนี้'},
    'APPOINTMENT': {'JA': '約束', 'ZH': '约会', 'FR': 'Rendez-vous', 'DE': 'Termin', 'RU': 'Встреча', 'AR': 'موعد', 'HI': 'नियुक्ति', 'VI': 'Cuộc hẹn', 'ES': 'Cita', 'TH': 'นัดหมาย'},
    'PROJECT': {'JA': 'プロジェクト', 'ZH': '项目', 'FR': 'Projet', 'DE': 'Projekt', 'RU': 'Проект', 'AR': 'مشروع', 'HI': 'परियोजना', 'VI': 'Dự án', 'ES': 'Proyecto', 'TH': 'โครงการ'},
    'REMINDER': {'JA': 'リマインダー', 'ZH': '提醒', 'FR': 'Rappel', 'DE': 'Erinnerung', 'RU': 'Напоминание', 'AR': 'تذكير', 'HI': 'रिमाइंडर', 'VI': 'Nhắc nhở', 'ES': 'Recordatorio', 'TH': 'การแจ้งเตือน'},
    'EXERCISE': {'JA': '運動', 'ZH': '运动', 'FR': 'Exercice', 'DE': 'Sport', 'RU': 'Упражнение', 'AR': 'تمرين', 'HI': 'व्यायाम', 'VI': 'Tập thể dục', 'ES': 'Ejercicio', 'TH': 'ออกกำลังกาย'}, // 🆕 [2026-09-04 추가]
    'EXERCISE ANALYSIS': {'JA': '運動分析', 'ZH': '运动分析', 'FR': 'Analyse des exercices', 'DE': 'Sportanalyse', 'RU': 'Анализ упражнений', 'AR': 'تحليل التمارين', 'HI': 'व्यायाम विश्लेषण', 'VI': 'Phân tích tập luyện', 'ES': 'Análisis de ejercicio', 'TH': 'วิเคราะห์การออกกำลังกาย'}, // 🆕 [2026-09-05 추가]
    'SCHEDULE ANALYSIS': {'JA': 'スケジュール分析', 'ZH': '日程分析', 'FR': 'Analyse du planning', 'DE': 'Zeitplananalyse', 'RU': 'Анализ расписания', 'AR': 'تحليل الجدول', 'HI': 'शेड्यूल विश्लेषण', 'VI': 'Phân tích lịch trình', 'ES': 'Análisis de horario', 'TH': 'วิเคราะห์ตารางเวลา'},
    // 타임라인 5개
    "TODAY'S TIMELINE": {'JA': '今日のタイムライン', 'ZH': '今日时间线', 'FR': "Chronologie du jour", 'DE': 'Heutige Zeitleiste', 'RU': 'Хронология на сегодня', 'AR': 'الجدول الزمني لليوم', 'HI': 'आज की समयरेखा', 'VI': 'Dòng thời gian hôm nay', 'ES': 'Cronología de hoy', 'TH': 'ไทม์ไลน์วันนี้'},
    'ROUTINE': {'JA': 'ルーティン', 'ZH': '常规', 'FR': 'Routine', 'DE': 'Routine', 'RU': 'Распорядок', 'AR': 'الروتين', 'HI': 'दिनचर्या', 'VI': 'Thói quen', 'ES': 'Rutina', 'TH': 'กิจวัตร'},
    'TIMELINE HISTORY': {'JA': 'タイムライン履歴', 'ZH': '时间线记录', 'FR': "Historique de chronologie", 'DE': 'Zeitleisten-Verlauf', 'RU': 'История хронологии', 'AR': 'سجل الجدول الزمني', 'HI': 'समयरेखा इतिहास', 'VI': 'Lịch sử dòng thời gian', 'ES': 'Historial de cronología', 'TH': 'ประวัติไทม์ไลน์'},
    'EXECUTION RECORD': {'JA': '実行記録', 'ZH': '执行记录', 'FR': "Journal d'exécution", 'DE': 'Ausführungsprotokoll', 'RU': 'Журнал выполнения', 'AR': 'سجل التنفيذ', 'HI': 'निष्पादन रिकॉर्ड', 'VI': 'Nhật ký thực hiện', 'ES': 'Registro de ejecución', 'TH': 'บันทึกการดำเนินการ'},
    'TIMELINE ANALYSIS': {'JA': 'タイムライン分析', 'ZH': '时间线分析', 'FR': "Analyse de chronologie", 'DE': 'Zeitleistenanalyse', 'RU': 'Анализ хронологии', 'AR': 'تحليل الجدول الزمني', 'HI': 'समयरेखा विश्लेषण', 'VI': 'Phân tích dòng thời gian', 'ES': 'Análisis de cronología', 'TH': 'วิเคราะห์ไทม์ไลน์'},
    'TIMER CALCULATOR': {'JA': 'タイマー・計算機', 'ZH': '计时器・计算器', 'FR': 'Minuteur · Calculatrice', 'DE': 'Timer · Rechner', 'RU': 'Таймер · Калькулятор', 'AR': 'المؤقت · الحاسبة', 'HI': 'टाइमर · कैलकुलेटर', 'VI': 'Hẹn giờ · Máy tính', 'ES': 'Temporizador · Calculadora', 'TH': 'ตัวจับเวลา · เครื่องคิดเลข'},
    // 목표 8개
    'LIFE GOAL': {'JA': '人生の目標', 'ZH': '人生目标', 'FR': 'Objectif de vie', 'DE': 'Lebensziel', 'RU': 'Жизненная цель', 'AR': 'هدف الحياة', 'HI': 'जीवन लक्ष्य', 'VI': 'Mục tiêu cuộc đời', 'ES': 'Objetivo de vida', 'TH': 'เป้าหมายชีวิต'},
    'YEARLY GOAL': {'JA': '年間目標', 'ZH': '年度目标', 'FR': 'Objectif annuel', 'DE': 'Jahresziel', 'RU': 'Годовая цель', 'AR': 'الهدف السنوي', 'HI': 'वार्षिक लक्ष्य', 'VI': 'Mục tiêu năm', 'ES': 'Objetivo anual', 'TH': 'เป้าหมายรายปี'},
    'MONTHLY GOAL': {'JA': '月間目標', 'ZH': '月度目标', 'FR': 'Objectif mensuel', 'DE': 'Monatsziel', 'RU': 'Месячная цель', 'AR': 'الهدف الشهري', 'HI': 'मासिक लक्ष्य', 'VI': 'Mục tiêu tháng', 'ES': 'Objetivo mensual', 'TH': 'เป้าหมายรายเดือน'},
    'WEEKLY GOAL': {'JA': '週間目標', 'ZH': '每周目标', 'FR': 'Objectif hebdomadaire', 'DE': 'Wochenziel', 'RU': 'Недельная цель', 'AR': 'الهدف الأسبوعي', 'HI': 'साप्ताहिक लक्ष्य', 'VI': 'Mục tiêu tuần', 'ES': 'Objetivo semanal', 'TH': 'เป้าหมายรายสัปดาห์'},
    'TODAY GOAL': {'JA': '今日の目標', 'ZH': '今日目标', 'FR': "Objectif du jour", 'DE': 'Tagesziel', 'RU': 'Цель на сегодня', 'AR': 'هدف اليوم', 'HI': 'आज का लक्ष्य', 'VI': 'Mục tiêu hôm nay', 'ES': 'Objetivo de hoy', 'TH': 'เป้าหมายวันนี้'},
    'TODO': {'JA': 'やること', 'ZH': '待办事项', 'FR': 'À faire', 'DE': 'Aufgaben', 'RU': 'Задачи', 'AR': 'المهام', 'HI': 'कार्य सूची', 'VI': 'Việc cần làm', 'ES': 'Tareas', 'TH': 'สิ่งที่ต้องทำ'},
    'PROGRESS': {'JA': '進捗', 'ZH': '进度', 'FR': 'Progrès', 'DE': 'Fortschritt', 'RU': 'Прогресс', 'AR': 'التقدم', 'HI': 'प्रगति', 'VI': 'Tiến độ', 'ES': 'Progreso', 'TH': 'ความคืบหน้า'},
    'ACHIEVEMENT': {'JA': '達成', 'ZH': '成就', 'FR': 'Réussite', 'DE': 'Erfolg', 'RU': 'Достижение', 'AR': 'الإنجاز', 'HI': 'उपलब्धि', 'VI': 'Thành tựu', 'ES': 'Logro', 'TH': 'ความสำเร็จ'},
    // 리포트 5개
    'DAILY REPORT': {'JA': '日次レポート', 'ZH': '日报', 'FR': 'Rapport quotidien', 'DE': 'Täglicher Bericht', 'RU': 'Дневной отчёт', 'AR': 'التقرير اليومي', 'HI': 'दैनिक रिपोर्ट', 'VI': 'Báo cáo hàng ngày', 'ES': 'Informe diario', 'TH': 'รายงานรายวัน'},
    'WEEKLY REPORT': {'JA': '週次レポート', 'ZH': '周报', 'FR': 'Rapport hebdomadaire', 'DE': 'Wochenbericht', 'RU': 'Недельный отчёт', 'AR': 'التقرير الأسبوعي', 'HI': 'साप्ताहिक रिपोर्ट', 'VI': 'Báo cáo hàng tuần', 'ES': 'Informe semanal', 'TH': 'รายงานรายสัปดาห์'},
    'MONTHLY REPORT': {'JA': '月次レポート', 'ZH': '月报', 'FR': 'Rapport mensuel', 'DE': 'Monatsbericht', 'RU': 'Месячный отчёт', 'AR': 'التقرير الشهري', 'HI': 'मासिक रिपोर्ट', 'VI': 'Báo cáo hàng tháng', 'ES': 'Informe mensual', 'TH': 'รายงานรายเดือน'},
    'YEARLY REPORT': {'JA': '年次レポート', 'ZH': '年报', 'FR': 'Rapport annuel', 'DE': 'Jahresbericht', 'RU': 'Годовой отчёт', 'AR': 'التقرير السنوي', 'HI': 'वार्षिक रिपोर्ट', 'VI': 'Báo cáo hàng năm', 'ES': 'Informe anual', 'TH': 'รายงานรายปี'},
    'STATISTICS': {'JA': '統計', 'ZH': '统计', 'FR': 'Statistiques', 'DE': 'Statistik', 'RU': 'Статистика', 'AR': 'الإحصائيات', 'HI': 'सांख्यिकी', 'VI': 'Thống kê', 'ES': 'Estadísticas', 'TH': 'สถิติ'},
  };

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label screen is coming soon. ($label 화면은 준비 중입니다.)', style: GoogleFonts.notoSansKr())),
    );
  }

  Widget _buildSectionTitle(String en, String ko) {
    // 🆕 [10개국어 확장] 외국어 선택 시 번역표에서 찾아 단독 표시, 없으면 영어로 대체
    if (!appLanguage.isDefault) {
      final translated = _t[en]?[appLanguage.current] ?? en;
      return Text(translated, style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 15));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(en, style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        Text('($ko)', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildMenuGrid(BuildContext context, List<_MenuEntry> entries) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: entries.map((e) => _buildMenuButton(e)).toList(),
    );
  }

  Widget _buildMenuButton(_MenuEntry entry) {
    return InkWell(
      onTap: entry.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _containerBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _brandGolden.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Text(entry.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: appLanguage.isDefault
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.enLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansKr(color: const Color(0xFFFFF6D6), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    entry.koLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.gowunBatang(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ],
              )
              // 🆕 [10개국어 확장] 외국어 선택 시 번역표에서 찾아 한 줄로 단독 표시
                  : Text(
                _t[entry.enLabel]?[appLanguage.current] ?? entry.enLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSansKr(color: const Color(0xFFFFF6D6), fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuEntry {
  final String emoji;
  final String enLabel;
  final String koLabel;
  final VoidCallback onTap;

  _MenuEntry(this.emoji, this.enLabel, this.koLabel, this.onTap);
}
