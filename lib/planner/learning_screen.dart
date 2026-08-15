import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../global_lang.dart'; // 👑 [12개국 연동] 전역 언어 스위치와 연결
import 'widgets/three_color_pencil_icon.dart'; // 🆕 [2026-08-15] 앱 전체 통일 3색+연필 수정 아이콘

// ============================================================================
// 🆕 [2026-08-14] 자기주도 플래너 "실행" 탭 전용 알람 서비스.
// 학사 타이머의 Timer2Service(하루 전체 시작 알림), 일반 플래너의 알람 기능과는
// 완전히 독립된 채널 ID와 알림 ID 체계를 사용해서 서로 절대 충돌하지 않음.
// ============================================================================
class PlannerAlarmService {
  PlannerAlarmService._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const String _channelId = 'gsu_self_directed_planner_alarm_channel';
  static const String _channelName = 'GKE 자기주도 플래너 일정 알람';
  static const String _channelDesc = '자기주도 플래너 실행 탭에 등록된 일정의 알람을 울려줍니다';

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

      const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = InitializationSettings(android: androidInit);
      await _plugin.initialize(initSettings);

      final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      try {
        await androidImpl?.requestNotificationsPermission();
      } catch (e) {
        debugPrint('[PlannerAlarmService] 알림 권한 요청 실패: $e');
      }

      // 🆕 [버그 수정 2026-08-16] 기존엔 _initialized가 메모리 변수라서 Hot Restart할 때마다
      // 초기화되어, 재시작할 때마다 "정확한 알람" 권한을 다시 요청함 -> 안드로이드 12+에서는
      // 이미 허용되어 있어도 매번 설정 화면으로 튕겨나가는 것처럼 보이던 원인이었음. 이제
      // SharedPreferences에 "이미 한 번 요청했음"을 영구 기록해서, 앱을 설치한 뒤 딱 한 번만
      // 요청하도록 함(이후엔 사용자가 설정에서 직접 켜야 함).
      try {
        final prefs = await SharedPreferences.getInstance();
        final bool alreadyRequested = prefs.getBool('gsu_exact_alarm_permission_requested') ?? false;
        if (!alreadyRequested) {
          await androidImpl?.requestExactAlarmsPermission();
          await prefs.setBool('gsu_exact_alarm_permission_requested', true);
        }
      } catch (e) {
        debugPrint('[PlannerAlarmService] 정확한 알람 권한 요청 실패(구버전 OS일 수 있음): $e');
      }

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      );
      await androidImpl?.createNotificationChannel(channel);

      _initialized = true;
    } catch (e) {
      debugPrint('[PlannerAlarmService] 초기화 실패: $e');
    }
  }

  // 일정의 고유 id 문자열을 32bit 정수 알림 ID로 안전하게 변환 (다른 서비스와 충돌 방지 위해
  // 최상위 비트를 항상 0으로 마스킹해서 양수 범위로 고정)
  static int _idFor(String scheduleId) => scheduleId.hashCode & 0x7fffffff;

  /// 지정한 날짜/시각에 알람(알림)을 예약함. 이미 지난 시각이면 예약하지 않고 false를 반환.
  static Future<bool> scheduleAlarm({
    required String scheduleId,
    required DateTime dateTime,
    required String title,
    required String body,
  }) async {
    await initialize();
    if (dateTime.isBefore(DateTime.now())) {
      debugPrint('[PlannerAlarmService] 이미 지난 시각이라 예약하지 않음: $dateTime');
      return false;
    }
    final int id = _idFor(scheduleId);
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(dateTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      return true;
    } catch (e) {
      debugPrint('[PlannerAlarmService] 알람 예약 실패: $e');
      return false;
    }
  }

  static Future<void> cancelAlarm(String scheduleId) async {
    await initialize();
    try {
      await _plugin.cancel(_idFor(scheduleId));
    } catch (e) {
      debugPrint('[PlannerAlarmService] 알람 취소 실패: $e');
    }
  }
}

/// ============================================================================
/// [GKE StudyUp] 자기주도 학습 플래너 - 실행 스크린 (learning_screen.dart)
/// 계획 탭에서 등록한 일정(gke_global_schedules)을 그대로 이어받아 달력으로 보여주고,
/// 날짜를 탭하면 알람(시간설정/수정/삭제/저장) 팝업을 띄움. 여기서 새로 추가한 일정도
/// 똑같이 gke_global_schedules에 저장되므로 계획 탭에도 그대로 나타남(양방향 연동).
/// ============================================================================
class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => LearningScreenState();
}

class LearningScreenState extends State<LearningScreen> with AutomaticKeepAliveClientMixin {
  // 🆕 [버그 수정 2026-08-15] 계획 탭(PlanningScreenState)과 동일하게 AutomaticKeepAliveClientMixin
  // 적용 - 이게 빠져있어서 계획→실행 탭으로 전환할 때마다 달력/알람서비스/데이터를 처음부터 다시
  // 만드느라 눈에 띄게 버벅였음(원인 확정). 이제 한 번 만든 화면은 탭을 오가도 그대로 유지됨.
  @override
  bool get wantKeepAlive => true;

  final Color schoolColor = const Color(0xFF3B82F6);
  final Color academyColor = const Color(0xFFFACC15);
  final Color examColor = const Color(0xFFEF4444);
  final Color personalColor = const Color(0xFF8B5CF6);
  final Color goldColor = const Color(0xFFD4AF37);
  final Color slate300 = const Color(0xFFCBD5E1);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color slate500 = const Color(0xFF64748B);
  final Color slate800 = const Color(0xFF1E293B);

  List<Map<String, dynamic>> _globalSchedules = [];
  bool _loaded = false;
  late DateTime _displayedMonth;
  late DateTime _selectedDate;

  // ============================================================================
  // 🆕 [12개국 언어 시스템] - 나머지 화면들과 동일한 방식(기본=영+한 2단, 10개국 선택 시 단독)
  // ============================================================================
  static const List<String> _foreignLanguages = ['JA', 'ZH', 'FR', 'DE', 'RU', 'AR', 'HI', 'VI', 'ES', 'TH'];
  static bool get _isForeignSelected => _foreignLanguages.contains(DkeLang.current);

  static const Map<String, Map<String, String>> _uiText = {
    'sectionExecution': {'KO': '오늘 실행 및 알람 캘린더', 'EN': 'Execution & Alarm Calendar', 'JA': '実行・アラームカレンダー', 'ZH': '执行与闹钟日历', 'FR': 'Exécution et calendrier d\'alarme', 'DE': 'Ausführung & Alarmkalender', 'RU': 'Календарь выполнения и будильников', 'AR': 'التنفيذ وتقويم المنبه', 'HI': 'निष्पादन और अलार्म कैलेंडर', 'VI': 'Lịch thực hiện & báo thức', 'ES': 'Calendario de ejecución y alarmas', 'TH': 'ปฏิทินการดำเนินการและปลุก'},
    'upcomingList': {'KO': '다가오는 일정', 'EN': 'Upcoming Schedule', 'JA': '近日の日程', 'ZH': '即将到来的日程', 'FR': 'Programme à venir', 'DE': 'Bevorstehender Termin', 'RU': 'Ближайшее расписание', 'AR': 'الجدول القادم', 'HI': 'आगामी कार्यक्रम', 'VI': 'Lịch sắp tới', 'ES': 'Próximo horario', 'TH': 'ตารางที่กำลังจะมาถึง'},
    'emptySchedule': {'KO': '등록된 일정이 없습니다.', 'EN': 'No schedule registered.', 'JA': '登録された日程がありません。', 'ZH': '暂无已登记的日程。', 'FR': 'Aucun programme enregistré.', 'DE': 'Kein Termin registriert.', 'RU': 'Расписание не добавлено.', 'AR': 'لا يوجد جدول مسجل.', 'HI': 'कोई कार्यक्रम दर्ज नहीं है।', 'VI': 'Chưa có lịch nào được đăng ký.', 'ES': 'No hay horario registrado.', 'TH': 'ไม่มีตารางที่ลงทะเบียนไว้'},
    'alarmSettingTitle': {'KO': '알람 설정', 'EN': 'Alarm Settings', 'JA': 'アラーム設定', 'ZH': '闹钟设置', 'FR': 'Paramètres d\'alarme', 'DE': 'Alarmeinstellungen', 'RU': 'Настройки будильника', 'AR': 'إعدادات المنبه', 'HI': 'अलार्म सेटिंग्स', 'VI': 'Cài đặt báo thức', 'ES': 'Configuración de alarma', 'TH': 'ตั้งค่าปลุก'},
    'alarmOnLabel': {'KO': '알람 켜기', 'EN': 'Turn On Alarm', 'JA': 'アラームをオン', 'ZH': '开启闹钟', 'FR': 'Activer l\'alarme', 'DE': 'Alarm einschalten', 'RU': 'Включить будильник', 'AR': 'تفعيل المنبه', 'HI': 'अलार्म चालू करें', 'VI': 'Bật báo thức', 'ES': 'Activar alarma', 'TH': 'เปิดปลุก'},
    'alarmScheduledBadge': {'KO': '알람 설정됨', 'EN': 'Alarm Set', 'JA': 'アラーム設定済み', 'ZH': '闹钟已设置', 'FR': 'Alarme réglée', 'DE': 'Alarm eingestellt', 'RU': 'Будильник установлен', 'AR': 'تم ضبط المنبه', 'HI': 'अलार्म सेट किया गया', 'VI': 'Đã đặt báo thức', 'ES': 'Alarma configurada', 'TH': 'ตั้งปลุกแล้ว'},
    'noAlarmToday': {'KO': '이 날짜에 등록된 일정이 없습니다.', 'EN': 'No schedule for this date.', 'JA': 'この日に登録された日程がありません。', 'ZH': '该日期暂无已登记的日程。', 'FR': 'Aucun programme pour cette date.', 'DE': 'Kein Termin für dieses Datum.', 'RU': 'На эту дату расписание не добавлено.', 'AR': 'لا يوجد جدول لهذا التاريخ.', 'HI': 'इस तारीख के लिए कोई कार्यक्रम नहीं है।', 'VI': 'Không có lịch cho ngày này.', 'ES': 'No hay horario para esta fecha.', 'TH': 'ไม่มีตารางสำหรับวันที่นี้'},
    'btnAddNew': {'KO': '새 일정 추가', 'EN': 'Add Schedule', 'JA': '新規日程追加', 'ZH': '添加日程', 'FR': 'Ajouter un programme', 'DE': 'Termin hinzufügen', 'RU': 'Добавить расписание', 'AR': 'إضافة جدول', 'HI': 'कार्यक्रम जोड़ें', 'VI': 'Thêm lịch', 'ES': 'Añadir horario', 'TH': 'เพิ่มตาราง'},
    'labelTime': {'KO': '시간 설정', 'EN': 'Time', 'JA': '時間設定', 'ZH': '时间设置', 'FR': 'Heure', 'DE': 'Uhrzeit', 'RU': 'Время', 'AR': 'الوقت', 'HI': 'समय', 'VI': 'Thời gian', 'ES': 'Hora', 'TH': 'เวลา'},
    'labelTitleField': {'KO': '일정 제목', 'EN': 'Title', 'JA': '日程タイトル', 'ZH': '日程标题', 'FR': 'Titre', 'DE': 'Titel', 'RU': 'Название', 'AR': 'العنوان', 'HI': 'शीर्षक', 'VI': 'Tiêu đề', 'ES': 'Título', 'TH': 'ชื่อเรื่อง'},
    'labelCategorySelect': {'KO': '일정 분류', 'EN': 'Category', 'JA': '日程分類', 'ZH': '日程分类', 'FR': 'Catégorie', 'DE': 'Kategorie', 'RU': 'Категория', 'AR': 'التصنيف', 'HI': 'श्रेणी', 'VI': 'Phân loại', 'ES': 'Categoría', 'TH': 'หมวดหมู่'},
    'btnClose': {'KO': '닫기', 'EN': 'Close', 'JA': '閉じる', 'ZH': '关闭', 'FR': 'Fermer', 'DE': 'Schließen', 'RU': 'Закрыть', 'AR': 'إغلاق', 'HI': 'बंद करें', 'VI': 'Đóng', 'ES': 'Cerrar', 'TH': 'ปิด'},
    'btnDelete': {'KO': '삭제', 'EN': 'Delete', 'JA': '削除', 'ZH': '删除', 'FR': 'Supprimer', 'DE': 'Löschen', 'RU': 'Удалить', 'AR': 'حذف', 'HI': 'हटाएं', 'VI': 'Xóa', 'ES': 'Eliminar', 'TH': 'ลบ'},
    'btnSave': {'KO': '저장', 'EN': 'Save', 'JA': '保存', 'ZH': '保存', 'FR': 'Enregistrer', 'DE': 'Speichern', 'RU': 'Сохранить', 'AR': 'حفظ', 'HI': 'सहेजें', 'VI': 'Lưu', 'ES': 'Guardar', 'TH': 'บันทึก'},
    'catSchool': {'KO': '학교', 'EN': 'School', 'JA': '学校', 'ZH': '学校', 'FR': 'École', 'DE': 'Schule', 'RU': 'Школа', 'AR': 'المدرسة', 'HI': 'स्कूल', 'VI': 'Trường học', 'ES': 'Escuela', 'TH': 'โรงเรียน'},
    'catAcademy': {'KO': '학원', 'EN': 'Academy', 'JA': '塾', 'ZH': '补习班', 'FR': 'Institut', 'DE': 'Institut', 'RU': 'Академия', 'AR': 'المعهد', 'HI': 'अकादमी', 'VI': 'Trung tâm', 'ES': 'Academia', 'TH': 'สถาบันกวดวิชา'},
    'catExam': {'KO': '시험', 'EN': 'Exam', 'JA': '試験', 'ZH': '考试', 'FR': 'Examen', 'DE': 'Prüfung', 'RU': 'Экзамен', 'AR': 'الاختبار', 'HI': 'परीक्षा', 'VI': 'Kỳ thi', 'ES': 'Examen', 'TH': 'ข้อสอบ'},
    'catPersonal': {'KO': '개인', 'EN': 'Personal', 'JA': '個人', 'ZH': '个人', 'FR': 'Personnel', 'DE': 'Persönlich', 'RU': 'Личное', 'AR': 'شخصي', 'HI': 'व्यक्तिगत', 'VI': 'Cá nhân', 'ES': 'Personal', 'TH': 'ส่วนตัว'},
    'hintScheduleTitle': {'KO': '간단한 일정 제목을 입력하세요', 'EN': 'Enter a brief schedule title', 'JA': '簡単な日程タイトルを入力してください', 'ZH': '请输入简短的日程标题', 'FR': 'Saisissez un titre de programme', 'DE': 'Kurzen Termintitel eingeben', 'RU': 'Введите краткое название', 'AR': 'أدخل عنوانًا موجزًا للجدول', 'HI': 'संक्षिप्त कार्यक्रम शीर्षक दर्ज करें', 'VI': 'Nhập tiêu đề lịch ngắn gọn', 'ES': 'Ingrese un título breve del horario', 'TH': 'กรอกชื่อตารางแบบสั้น'},
  };

  static String _t(String key) {
    final map = _uiText[key];
    if (map == null) return key;
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? key;
  }

  static String _biStr(String key) {
    final map = _uiText[key];
    if (map == null) return key;
    if (_isForeignSelected) {
      return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? key;
    }
    return '${map['EN'] ?? ''} / ${map['KO'] ?? ''}';
  }

  static Widget _biTitle(
      String key, {
        required TextStyle enStyle,
        required TextStyle koStyle,
        TextStyle? foreignStyle,
      }) {
    final map = _uiText[key] ?? {'EN': key, 'KO': key};
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

  static const Map<String, List<String>> _weekdaySunFirst = {
    'KO': ['일', '월', '화', '수', '목', '금', '토'], 'EN': ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    'JA': ['日', '月', '火', '水', '木', '金', '土'], 'ZH': ['日', '一', '二', '三', '四', '五', '六'],
    'FR': ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'], 'DE': ['So', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa'],
    'RU': ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'], 'AR': ['أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'],
    'HI': ['रवि', 'सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि'], 'VI': ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'],
    'ES': ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'], 'TH': ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'],
  };
  static List<String> _weekdaysSunFirst() => _weekdaySunFirst[DkeLang.current] ?? _weekdaySunFirst['EN']!;

  @override
  void initState() {
    super.initState();
    PlannerAlarmService.initialize();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _loadSchedules();
  }

  // 🆕 다른 탭(계획 탭)에서 방금 등록/수정한 일정을 실행 탭으로 돌아왔을 때 최신화하기 위한
  // 공개 메서드. main_self_learning_planner_screen.dart가 탭 전환 시 호출해줌.
  Future<void> refreshSchedules() async {
    await _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString('gke_global_schedules');
      List<Map<String, dynamic>> list = [];
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        list = decoded.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          if (map['color'] is int) {
            map['color'] = Color(map['color'] as int);
          }
          return map;
        }).toList();
      }
      if (mounted) {
        setState(() {
          _globalSchedules = list;
          _loaded = true;
        });
      }
    } catch (e) {
      debugPrint('[LearningScreen] 일정 로드 실패: $e');
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _saveSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> serializable = _globalSchedules.map((item) {
        final Map<String, dynamic> copy = Map<String, dynamic>.from(item);
        if (copy['color'] is Color) {
          copy['color'] = (copy['color'] as Color).toARGB32();
        }
        return copy;
      }).toList();
      await prefs.setString('gke_global_schedules', jsonEncode(serializable));
    } catch (e) {
      debugPrint('[LearningScreen] 일정 저장 실패: $e');
    }
  }

  String _genScheduleId() => 'sch_${DateTime.now().microsecondsSinceEpoch}_${_globalSchedules.length}';

  // 🆕 카테고리 색상 매핑 - "수행"은 별도 카테고리로 두지 않고, 분류가 없거나 알 수 없는 값은
  // 모두 "학교"(파랑)로 처리함 (원장님 지시사항).
  Color _categoryColorFor(String? catValue) {
    switch (catValue) {
      case '학원':
        return academyColor;
      case '시험':
        return examColor;
      case '개인':
        return personalColor;
      default:
        return schoolColor;
    }
  }

  DateTime _itemDateTime(Map<String, dynamic> item) {
    final String timeStr = (item['time'] ?? '00:00').toString();
    final List<String> parts = timeStr.split(':');
    int hh = 0, mm = 0;
    try {
      hh = int.parse(parts[0]);
      mm = parts.length > 1 ? int.parse(parts[1]) : 0;
    } catch (_) {}
    return DateTime(item['year'] as int, item['month'] as int, item['day'] as int, hh, mm);
  }

  // 🆕 원장님 지시: "최근(맨위)순서" - 알람 목록이므로 지금 이 순간과 가장 가까운 일정이 맨 위로 오도록
  // 현재 시각과의 시간차 절댓값 기준으로 정렬함.
  List<Map<String, dynamic>> get _sortedByProximity {
    final DateTime now = DateTime.now();
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(_globalSchedules);
    list.sort((a, b) {
      final Duration diffA = _itemDateTime(a).difference(now).abs();
      final Duration diffB = _itemDateTime(b).difference(now).abs();
      return diffA.compareTo(diffB);
    });
    return list;
  }

  void _goToPreviousMonth() {
    setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1));
  }

  void _goToNextMonth() {
    setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1));
  }

  int get _firstDayWeekdayIndex => DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday;
  int get _emptyPrefixCellsCount => _firstDayWeekdayIndex == 7 ? 0 : _firstDayWeekdayIndex;
  int get _totalDaysInMonth => DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
  int get _prevMonthTotalDays => DateTime(_displayedMonth.year, _displayedMonth.month, 0).day;
  int get _totalCalendarGridItemsCount {
    int count = _emptyPrefixCellsCount + _totalDaysInMonth;
    if (count % 7 != 0) count += (7 - (count % 7));
    return count;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수 호출
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    }
    final List<Map<String, dynamic>> sortedList = _sortedByProximity;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _biTitle(
            'sectionExecution',
            enStyle: GoogleFonts.gowunBatang(fontSize: 13, color: goldColor, fontWeight: FontWeight.bold),
            koStyle: GoogleFonts.notoSansKr(fontSize: 16, color: goldColor, fontWeight: FontWeight.bold),
            foreignStyle: GoogleFonts.notoSans(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildCalendarCard(),
          const SizedBox(height: 20),
          _biTitle(
            'upcomingList',
            enStyle: GoogleFonts.gowunBatang(fontSize: 12, color: goldColor, fontWeight: FontWeight.bold),
            koStyle: GoogleFonts.notoSansKr(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold),
            foreignStyle: GoogleFonts.notoSans(fontSize: 14, color: goldColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (sortedList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(child: Text(_t('emptySchedule'), style: GoogleFonts.notoSansKr(color: slate500, fontSize: 12))),
            )
          else
            ...sortedList.map((item) {
              final DateTime dt = _itemDateTime(item);
              final Color catColor = item['color'] is Color ? item['color'] as Color : _categoryColorFor(null);
              final bool alarmOn = item['alarmOn'] == true;
              return GestureDetector(
                onTap: () => _showDateAlarmSheet(DateTime(dt.year, dt.month, dt.day)),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(8), border: Border.all(color: slate800)),
                  child: Row(
                    children: [
                      Container(width: 14, height: 14, decoration: BoxDecoration(color: catColor, borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 76,
                        child: Text(
                          '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${item['time'] ?? ''}',
                          overflow: TextOverflow.fade, softWrap: false, maxLines: 1,
                          style: GoogleFonts.notoSerif(fontSize: 11, color: goldColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(item['title'] ?? '', style: GoogleFonts.notoSansKr(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      ),
                      if (alarmOn) Icon(Icons.notifications_active, color: goldColor, size: 16),
                      const ThreeColorPencilIcon(size: 14),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(12), border: Border.all(color: slate800)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(onTap: _goToPreviousMonth, child: Icon(Icons.chevron_left, color: goldColor, size: 22)),
              Text('${_displayedMonth.year} / ${_displayedMonth.month}', style: GoogleFonts.notoSansKr(fontSize: 14, color: goldColor, fontWeight: FontWeight.bold)),
              GestureDetector(onTap: _goToNextMonth, child: Icon(Icons.chevron_right, color: goldColor, size: 22)),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 7,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1.6),
            itemBuilder: (context, index) {
              final Color c = index == 0 ? examColor : (index == 6 ? schoolColor : slate400);
              return Center(child: Text(_weekdaysSunFirst()[index], style: GoogleFonts.notoSansKr(fontSize: 11, color: c, fontWeight: FontWeight.bold)));
            },
          ),
          const Divider(color: Color(0xFF1E293B), height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _totalCalendarGridItemsCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4, childAspectRatio: 0.85),
            itemBuilder: (context, index) {
              int displayDayNum = 1;
              bool isBlurred = false;
              if (index < _emptyPrefixCellsCount) {
                displayDayNum = _prevMonthTotalDays - (_emptyPrefixCellsCount - index - 1);
                isBlurred = true;
              } else if (index >= (_emptyPrefixCellsCount + _totalDaysInMonth)) {
                displayDayNum = index - (_emptyPrefixCellsCount + _totalDaysInMonth) + 1;
                isBlurred = true;
              } else {
                displayDayNum = index - _emptyPrefixCellsCount + 1;
              }

              List<Color> dayColors = [];
              if (!isBlurred) {
                final List<Map<String, dynamic>> daySchedules = _globalSchedules.where((s) => s['year'] == _displayedMonth.year && s['month'] == _displayedMonth.month && s['day'] == displayDayNum).toList();
                final Set<int> seen = {};
                for (final s in daySchedules) {
                  final Color c = s['color'] is Color ? s['color'] as Color : _categoryColorFor(null);
                  if (seen.add(c.toARGB32()) && dayColors.length < 4) dayColors.add(c);
                }
              }

              final bool isToday = !isBlurred && _displayedMonth.year == DateTime.now().year && _displayedMonth.month == DateTime.now().month && displayDayNum == DateTime.now().day;
              final bool isSelected = !isBlurred && _selectedDate.year == _displayedMonth.year && _selectedDate.month == _displayedMonth.month && _selectedDate.day == displayDayNum;

              return GestureDetector(
                onTap: () {
                  if (isBlurred) return;
                  final DateTime tapped = DateTime(_displayedMonth.year, _displayedMonth.month, displayDayNum);
                  setState(() => _selectedDate = tapped);
                  _showDateAlarmSheet(tapped);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? goldColor.withValues(alpha: 0.15) : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSelected ? goldColor : (isToday ? goldColor.withValues(alpha: 0.5) : slate800), width: isSelected ? 1.5 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$displayDayNum', style: GoogleFonts.notoSerif(fontSize: 12, color: isBlurred ? slate500 : (isSelected ? goldColor : Colors.white), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      if (dayColors.isNotEmpty)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 2,
                          children: dayColors.map((c) => Container(width: 6, height: 6, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(1.5)))).toList(),
                        )
                      else
                        const SizedBox(height: 6),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 🆕 날짜를 탭하면 뜨는 알람 설정 시트. 목록 화면 ↔ 입력 화면을 같은 시트 안에서 전환하는
  // 구조(오늘 주간 탭에서 검증된 안정적인 방식)를 그대로 따라서 만듦 - 별도 팝업 중첩 없음.
  // ============================================================================
  // ============================================================================
  // 🆕 [버그 수정 2026-08-15] 네 번째로 재발한 "바텀시트 안에서 화면 전환 시 먹통" 문제를
  // 근본적으로 없애기 위해 완전히 재설계함. 바텀시트는 이제 "목록 표시" 역할만 하고(이 부분은
  // 계속 정상 작동해왔음), 편집/추가는 바텀시트 안이 아니라 완전히 별도의 새 페이지(전체 화면
  // Navigator.push)로 분리함. 전체 화면 이동은 이 앱에서 이미 안정적으로 작동하는 가장 기본적인
  // 네비게이션 방식이라, 바텀시트 내부 상태 전환에서 반복되던 문제를 원천적으로 피해감.
  // ============================================================================
  void _showDateAlarmSheet(DateTime date) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: const Color(0xFF020617),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (BuildContext bc) {
        return StatefulBuilder(
          builder: (BuildContext modalContext, StateSetter setModalState) {
            List<int> globalIndicesForDate() {
              final List<int> idxs = [];
              for (int i = 0; i < _globalSchedules.length; i++) {
                final s = _globalSchedules[i];
                if (s['year'] == date.year && s['month'] == date.month && s['day'] == date.day) idxs.add(i);
              }
              return idxs;
            }

            Future<void> openEditPage({int? globalIdx}) async {
              final Map<String, dynamic>? item = globalIdx != null ? _globalSchedules[globalIdx] : null;
              // 🆕 [버그 수정 2026-08-15] 정확한 원인 확정: 바텀시트가 열려있는 상태에서 그 위로
              // Navigator.push()로 새 페이지를 얹으면 이 앱에서 화면이 사라지는 문제가 있었음
              // (showDialog만 쓰는 "주요일정"은 문제없이 작동한다는 점에서 확인됨). 그래서 새 화면으로
              // 넘어가기 "전에" 먼저 이 바텀시트를 완전히 닫고, 편집이 끝나면 목록을 다시 열어줌.
              Navigator.of(context).pop();
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => _AlarmEditPage(
                  date: date,
                  initialTime: item?['time'] as String?,
                  initialTitle: item?['title'] as String?,
                  initialCategory: item?['category'] as String?,
                  initialAlarmOn: item?['alarmOn'] == true,
                  isNew: globalIdx == null,
                  goldColor: goldColor, slate400: slate400, slate500: slate500, slate800: slate800,
                  categoryColorFor: _categoryColorFor,
                  tFunc: _t, biStrFunc: _biStr,
                  onSave: (String time, String title, String category, bool alarmOn) async {
                    // 🆕 [버그 수정 2026-08-15] scheduleId를 setState 콜백 "밖"에서 먼저 계산해둠.
                    // 콜백 안에서만 대입하면 Dart 정적 분석이 "사용 전 대입 여부"를 클로저 내부까지
                    // 추적하지 못해 "must be assigned before it can be used" 컴파일 오류가 남.
                    final String scheduleId = (globalIdx == null)
                        ? _genScheduleId()
                        : ((_globalSchedules[globalIdx]['id'] as String?) ?? _genScheduleId());

                    setState(() {
                      if (globalIdx == null) {
                        _globalSchedules.add({
                          'id': scheduleId,
                          'year': date.year, 'month': date.month, 'day': date.day,
                          'time': time, 'title': title,
                          'category': category,
                          'color': _categoryColorFor(category),
                          'memo': '',
                          'alarmOn': alarmOn,
                        });
                      } else {
                        _globalSchedules[globalIdx]['id'] = scheduleId;
                        _globalSchedules[globalIdx]['time'] = time;
                        _globalSchedules[globalIdx]['title'] = title;
                        _globalSchedules[globalIdx]['category'] = category;
                        _globalSchedules[globalIdx]['color'] = _categoryColorFor(category);
                        _globalSchedules[globalIdx]['alarmOn'] = alarmOn;
                      }
                    });
                    await _saveSchedules();

                    final List<String> tp = time.split(':');
                    int hh = 0, mm = 0;
                    try { hh = int.parse(tp[0]); mm = tp.length > 1 ? int.parse(tp[1]) : 0; } catch (_) {}
                    final DateTime alarmDateTime = DateTime(date.year, date.month, date.day, hh, mm);

                    if (alarmOn) {
                      await PlannerAlarmService.scheduleAlarm(
                        scheduleId: scheduleId,
                        dateTime: alarmDateTime,
                        title: title,
                        body: '${date.month}/${date.day} ${_t('alarmSettingTitle')}',
                      );
                    } else {
                      await PlannerAlarmService.cancelAlarm(scheduleId);
                    }
                  },
                  onDelete: globalIdx == null
                      ? null
                      : () async {
                    final String? scheduleId = _globalSchedules[globalIdx]['id'] as String?;
                    setState(() => _globalSchedules.removeAt(globalIdx));
                    await _saveSchedules();
                    if (scheduleId != null) await PlannerAlarmService.cancelAlarm(scheduleId);
                  },
                ),
              ));
              if (mounted) _showDateAlarmSheet(date);
            }

            final List<int> dateIdxs = globalIndicesForDate();

            return SizedBox(
              height: MediaQuery.of(modalContext).size.height * 0.75,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${date.month}/${date.day} ${_t('alarmSettingTitle')}',
                            overflow: TextOverflow.fade, softWrap: false, maxLines: 1,
                            style: GoogleFonts.notoSansKr(fontSize: 15, color: goldColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => openEditPage(),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: goldColor, width: 1.5), color: goldColor.withValues(alpha: 0.08)),
                            child: Icon(Icons.add, color: goldColor, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 20),
                    Expanded(
                      child: dateIdxs.isEmpty
                          ? Center(child: Text(_t('noAlarmToday'), style: GoogleFonts.notoSansKr(color: slate500, fontSize: 12)))
                          : ListView.builder(
                        itemCount: dateIdxs.length,
                        itemBuilder: (context, i) {
                          final int gIdx = dateIdxs[i];
                          final item = _globalSchedules[gIdx];
                          final Color catColor = item['color'] is Color ? item['color'] as Color : _categoryColorFor(item['category'] as String?);
                          final bool alarmOnFlag = item['alarmOn'] == true;
                          return GestureDetector(
                            onTap: () => openEditPage(globalIdx: gIdx),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8), border: Border.all(color: slate800)),
                              child: Row(
                                children: [
                                  Container(width: 14, height: 14, decoration: BoxDecoration(color: catColor, borderRadius: BorderRadius.circular(3))),
                                  const SizedBox(width: 10),
                                  SizedBox(width: 60, child: Text(item['time'] ?? '', overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSerif(fontSize: 12, color: goldColor, fontWeight: FontWeight.bold))),
                                  Expanded(child: Text(item['title'] ?? '', style: GoogleFonts.notoSansKr(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                                  if (alarmOnFlag) Icon(Icons.notifications_active, color: goldColor, size: 16),
                                  const ThreeColorPencilIcon(size: 14),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) => _loadSchedules());
  }
}

// ============================================================================
// 🆕 [버그 수정 2026-08-15] 알람 추가/수정 전용 독립 페이지. 바텀시트 안이 아니라 완전한 별도
// 화면(전체 화면 Navigator.push)으로 열림 - 바텀시트 내부 상태 전환에서 반복되던 먹통 문제를
// 피하기 위한 설계.
// ============================================================================
class _AlarmEditPage extends StatefulWidget {
  final DateTime date;
  final String? initialTime;
  final String? initialTitle;
  final String? initialCategory;
  final bool initialAlarmOn;
  final bool isNew;
  final Color goldColor;
  final Color slate400;
  final Color slate500;
  final Color slate800;
  final Color Function(String?) categoryColorFor;
  final String Function(String) tFunc;
  final String Function(String) biStrFunc;
  final Future<void> Function(String time, String title, String category, bool alarmOn) onSave;
  final Future<void> Function()? onDelete;

  const _AlarmEditPage({
    super.key,
    required this.date,
    this.initialTime,
    this.initialTitle,
    this.initialCategory,
    this.initialAlarmOn = false,
    required this.isNew,
    required this.goldColor,
    required this.slate400,
    required this.slate500,
    required this.slate800,
    required this.categoryColorFor,
    required this.tFunc,
    required this.biStrFunc,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_AlarmEditPage> createState() => _AlarmEditPageState();
}

class _AlarmEditPageState extends State<_AlarmEditPage> {
  late final TextEditingController _timeController;
  late final TextEditingController _titleController;
  late String _selectedCategory;
  late bool _alarmOn;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _timeController = TextEditingController(text: widget.initialTime ?? '');
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _selectedCategory = widget.initialCategory ?? '학교';
    _alarmOn = widget.initialAlarmOn;
  }

  @override
  void dispose() {
    _timeController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final String time = _timeController.text.trim();
    final String title = _titleController.text.trim();
    if (time.isEmpty || title.isEmpty) return;
    setState(() => _saving = true);
    await widget.onSave(time, title, _selectedCategory, _alarmOn);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _handleDelete() async {
    if (widget.onDelete == null) return;
    setState(() => _saving = true);
    await widget.onDelete!();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: widget.goldColor), onPressed: () => Navigator.of(context).pop()),
        title: Text(
          '${widget.date.month}/${widget.date.day} ${widget.tFunc('alarmSettingTitle')}',
          overflow: TextOverflow.fade, softWrap: false, maxLines: 1,
          style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.biStrFunc('labelCategorySelect'), style: GoogleFonts.notoSerif(fontSize: 11, color: widget.goldColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: [
                {'value': '학교', 'labelKey': 'catSchool'},
                {'value': '학원', 'labelKey': 'catAcademy'},
                {'value': '시험', 'labelKey': 'catExam'},
                {'value': '개인', 'labelKey': 'catPersonal'},
              ].map((cat) {
                final bool isSel = _selectedCategory == cat['value'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat['value']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel ? widget.categoryColorFor(cat['value']) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isSel ? widget.categoryColorFor(cat['value']) : widget.slate800),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 10, height: 10, margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(color: widget.categoryColorFor(cat['value']), borderRadius: BorderRadius.circular(2))),
                        Text(widget.biStrFunc(cat['labelKey']!), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(fontSize: 11, color: isSel ? const Color(0xFF020617) : Colors.white)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(widget.biStrFunc('labelTitleField'), style: GoogleFonts.notoSerif(fontSize: 11, color: widget.goldColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(
              controller: _titleController, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: widget.biStrFunc('hintScheduleTitle'), hintStyle: GoogleFonts.notoSansKr(color: widget.slate500, fontSize: 12),
                filled: true, fillColor: const Color(0xFF0F172A),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.goldColor)),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.biStrFunc('labelTime'), style: GoogleFonts.notoSerif(fontSize: 11, color: widget.goldColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(
              controller: _timeController, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: '09:00', hintStyle: GoogleFonts.notoSansKr(color: widget.slate500, fontSize: 12),
                filled: true, fillColor: const Color(0xFF0F172A),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.slate800)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.goldColor)),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8), border: Border.all(color: widget.slate800)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications_active_outlined, color: widget.goldColor, size: 18),
                      const SizedBox(width: 8),
                      Text(widget.biStrFunc('alarmOnLabel'), style: GoogleFonts.notoSansKr(fontSize: 13, color: Colors.white)),
                    ],
                  ),
                  Switch(
                    value: _alarmOn,
                    activeColor: widget.goldColor,
                    onChanged: (v) => setState(() => _alarmOn = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.onDelete != null)
                  Flexible(
                    child: TextButton(
                      onPressed: _saving ? null : _handleDelete,
                      child: Text(widget.biStrFunc('btnDelete'), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Row(
                  children: [
                    Flexible(
                      child: TextButton(
                        onPressed: _saving ? null : () => Navigator.of(context).pop(),
                        child: Text(widget.biStrFunc('btnClose'), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(color: widget.slate400, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: widget.goldColor),
                        onPressed: _saving ? null : _handleSave,
                        child: Text(widget.biStrFunc('btnSave'), overflow: TextOverflow.fade, softWrap: false, maxLines: 1, style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF020617), fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
