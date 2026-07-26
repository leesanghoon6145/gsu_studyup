import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../global_lang.dart'; // 👑 [12개국 연동] 전역 언어 스위치와 연결

class LiveActiveUsersScreen extends StatefulWidget {
  const LiveActiveUsersScreen({Key? key}) : super(key: key);

  @override
  State<LiveActiveUsersScreen> createState() => _LiveActiveUsersScreenState();
}

class _LiveActiveUsersScreenState extends State<LiveActiveUsersScreen> {
  int _liveUserCount = 1287;
  Timer? _updateTimer;
  bool _isTimerRunning = true;

  // ============================================================================
  // 🆕 [12개국 언어 시스템] 기본 인프라
  // 기본값(마이페이지에서 12개국 중 하나를 고르기 전, 즉 DkeLang.current == 'KO' 상태 포함)은
  // 항상 "영문 + 한글"이 함께 보입니다. 한국어/영어를 "제외한" 나머지 10개국 중 하나를 선택했을
  // 때만 그 언어 단독으로 전환됩니다.
  // ============================================================================
  static const List<String> _foreignLanguages = ['JA', 'ZH', 'FR', 'DE', 'RU', 'AR', 'HI', 'VI', 'ES', 'TH'];
  static bool get _isForeignSelected => _foreignLanguages.contains(DkeLang.current);

  static const Map<String, Map<String, String>> _uiText = {
    'appBarTitleEn': {'KO': 'LIVE ACTIVE USERS', 'EN': 'LIVE ACTIVE USERS', 'JA': 'LIVE ACTIVE USERS', 'ZH': 'LIVE ACTIVE USERS', 'FR': 'LIVE ACTIVE USERS', 'DE': 'LIVE ACTIVE USERS', 'RU': 'LIVE ACTIVE USERS', 'AR': 'LIVE ACTIVE USERS', 'HI': 'LIVE ACTIVE USERS', 'VI': 'LIVE ACTIVE USERS', 'ES': 'LIVE ACTIVE USERS', 'TH': 'LIVE ACTIVE USERS'},
    'appBarTitleKo': {'KO': '동시 접속자', 'EN': 'Live Active Users', 'JA': '同時接続者', 'ZH': '同时在线用户', 'FR': 'Utilisateurs actifs en direct', 'DE': 'Live aktive Nutzer', 'RU': 'Активные пользователи', 'AR': 'المستخدمون النشطون الآن', 'HI': 'लाइव सक्रिय उपयोगकर्ता', 'VI': 'Người dùng trực tuyến', 'ES': 'Usuarios activos en vivo', 'TH': 'ผู้ใช้ที่ออนไลน์อยู่ขณะนี้'},
    'subtitleEn': {'KO': 'Global Live Studying Platform', 'EN': 'Global Live Studying Platform', 'JA': 'Global Live Studying Platform', 'ZH': 'Global Live Studying Platform', 'FR': 'Global Live Studying Platform', 'DE': 'Global Live Studying Platform', 'RU': 'Global Live Studying Platform', 'AR': 'Global Live Studying Platform', 'HI': 'Global Live Studying Platform', 'VI': 'Global Live Studying Platform', 'ES': 'Global Live Studying Platform', 'TH': 'Global Live Studying Platform'},
    'subtitleKo': {'KO': '현재도 전국 전세계 사람들 학습중입니다.', 'EN': 'People across the country and around the world are studying right now.', 'JA': '今この瞬間も、全国そして世界中の人々が学習しています。', 'ZH': '此刻，全国和全世界的人们都在学习。', 'FR': 'En ce moment, des personnes partout dans le pays et le monde étudient.', 'DE': 'Gerade jetzt lernen Menschen im ganzen Land und weltweit.', 'RU': 'Прямо сейчас люди по всей стране и по всему миру учатся.', 'AR': 'في هذه اللحظة، يدرس الناس في جميع أنحاء البلاد والعالم.', 'HI': 'अभी इस समय पूरे देश और दुनिया भर में लोग पढ़ाई कर रहे हैं।', 'VI': 'Ngay lúc này, mọi người trên cả nước và toàn thế giới đang học tập.', 'ES': 'En este momento, personas de todo el país y del mundo están estudiando.', 'TH': 'ขณะนี้ผู้คนทั่วประเทศและทั่วโลกกำลังเรียนอยู่'},

    'catLiveActiveUsers': {'KO': '세계 현재 학습중', 'EN': 'Live Active Users', 'JA': '世界のリアルタイム学習者', 'ZH': '全球实时学习者', 'FR': 'Utilisateurs actifs dans le monde', 'DE': 'Weltweit aktive Nutzer', 'RU': 'Активные пользователи в мире', 'AR': 'المستخدمون النشطون في العالم', 'HI': 'विश्व में सक्रिय उपयोगकर्ता', 'VI': 'Người học trực tuyến toàn cầu', 'ES': 'Usuarios activos en el mundo', 'TH': 'ผู้ใช้ที่กำลังเรียนทั่วโลก'},
    'catFriendsStudying': {'KO': '현재 학습중인 친구', 'EN': 'Friends Studying Now', 'JA': '現在学習中の友達', 'ZH': '正在学习的朋友', 'FR': 'Amis en train d\'étudier', 'DE': 'Freunde, die gerade lernen', 'RU': 'Друзья, которые сейчас учатся', 'AR': 'الأصدقاء الذين يدرسون الآن', 'HI': 'अभी पढ़ रहे मित्र', 'VI': 'Bạn bè đang học lúc này', 'ES': 'Amigos estudiando ahora', 'TH': 'เพื่อนที่กำลังเรียนอยู่ตอนนี้'},
    'catMyRanking': {'KO': '내 순위', 'EN': 'My Ranking', 'JA': '自分の順位', 'ZH': '我的排名', 'FR': 'Mon classement', 'DE': 'Meine Rangliste', 'RU': 'Мой рейтинг', 'AR': 'ترتيبي', 'HI': 'मेरी रैंकिंग', 'VI': 'Xếp hạng của tôi', 'ES': 'Mi clasificación', 'TH': 'อันดับของฉัน'},
    'catTodaysLiveRanking': {'KO': '오늘 실시간 랭킹', 'EN': "Today's Live Ranking", 'JA': '本日のリアルタイムランキング', 'ZH': '今日实时排名', 'FR': 'Classement en direct du jour', 'DE': 'Heutige Live-Rangliste', 'RU': 'Сегодняшний рейтинг в реальном времени', 'AR': 'الترتيب المباشر لليوم', 'HI': 'आज की लाइव रैंकिंग', 'VI': 'Bảng xếp hạng trực tiếp hôm nay', 'ES': 'Clasificación en vivo de hoy', 'TH': 'อันดับสดวันนี้'},
    'catPopularTargets': {'KO': '오늘의 인기 목표', 'EN': "Today's Popular Targets", 'JA': '本日の人気目標', 'ZH': '今日热门目标', 'FR': 'Objectifs populaires du jour', 'DE': 'Beliebte Ziele heute', 'RU': 'Популярные цели сегодня', 'AR': 'الأهداف الشائعة اليوم', 'HI': 'आज के लोकप्रिय लक्ष्य', 'VI': 'Mục tiêu phổ biến hôm nay', 'ES': 'Objetivos populares de hoy', 'TH': 'เป้าหมายที่นิยมวันนี้'},
    'catGlobalStats': {'KO': '오늘의 전체 통계', 'EN': "Today's Global Statistics", 'JA': '本日の全体統計', 'ZH': '今日全球统计', 'FR': 'Statistiques globales du jour', 'DE': 'Heutige globale Statistik', 'RU': 'Сегодняшняя общая статистика', 'AR': 'الإحصائيات العالمية لليوم', 'HI': 'आज का वैश्विक आँकड़ा', 'VI': 'Số liệu toàn cầu hôm nay', 'ES': 'Estadísticas globales de hoy', 'TH': 'สถิติทั่วโลกวันนี้'},
    'catRealtimeAlerts': {'KO': '실시간 성취 알림', 'EN': 'Real-time Achievement Alerts', 'JA': 'リアルタイム達成アラート', 'ZH': '实时成就提醒', 'FR': 'Alertes de réussite en direct', 'DE': 'Echtzeit-Erfolgsbenachrichtigungen', 'RU': 'Уведомления о достижениях в реальном времени', 'AR': 'تنبيهات الإنجاز الفورية', 'HI': 'रीयल-टाइम उपलब्धि सूचनाएं', 'VI': 'Thông báo thành tích trực tiếp', 'ES': 'Alertas de logros en tiempo real', 'TH': 'การแจ้งเตือนความสำเร็จแบบเรียลไทม์'},
    'catSubjectRatio': {'KO': '세계 총 과목비율', 'EN': 'Global Total Subject Ratio', 'JA': '世界の科目別割合', 'ZH': '全球科目比例', 'FR': 'Répartition mondiale des matières', 'DE': 'Weltweite Fächerverteilung', 'RU': 'Мировое распределение по предметам', 'AR': 'نسبة المواد الدراسية العالمية', 'HI': 'विश्वव्यापी विषय अनुपात', 'VI': 'Tỷ lệ môn học toàn cầu', 'ES': 'Proporción global de materias', 'TH': 'สัดส่วนวิชาทั่วโลก'},

    'usersStudyingSuffix': {'KO': 'Users Studying', 'EN': 'Users Studying', 'JA': '人が学習中', 'ZH': '人正在学习', 'FR': 'utilisateurs étudient', 'DE': 'Nutzer lernen gerade', 'RU': 'пользователей учатся', 'AR': 'مستخدم يدرس الآن', 'HI': 'उपयोगकर्ता पढ़ रहे हैं', 'VI': 'người đang học', 'ES': 'usuarios estudiando', 'TH': 'ผู้ใช้กำลังเรียนอยู่'},
    'liveCountKoLine': {'KO': '(현재 {count}명 학습중) ==> 실시간 갱신', 'EN': 'Real-time update', 'JA': 'リアルタイム更新中', 'ZH': '实时更新中', 'FR': 'Mise à jour en direct', 'DE': 'Live-Aktualisierung', 'RU': 'Обновление в реальном времени', 'AR': 'تحديث فوري', 'HI': 'रीयल-टाइम अपडेट', 'VI': 'Đang cập nhật trực tiếp', 'ES': 'Actualización en tiempo real', 'TH': 'อัปเดตแบบเรียลไทม์'},

    'timerStatusControlLabel': {'KO': '타이머 상태 제어', 'EN': 'Timer Status Control', 'JA': 'タイマー状態制御', 'ZH': '计时器状态控制', 'FR': 'Contrôle du statut du minuteur', 'DE': 'Timer-Statussteuerung', 'RU': 'Управление статусом таймера', 'AR': 'التحكم في حالة المؤقت', 'HI': 'टाइमर स्थिति नियंत्रण', 'VI': 'Điều khiển trạng thái hẹn giờ', 'ES': 'Control del estado del temporizador', 'TH': 'ควบคุมสถานะตัวจับเวลา'},

    'studyingStatusLabel': {'KO': '학습중', 'EN': 'Studying', 'JA': '学習中', 'ZH': '学习中', 'FR': "En train d'étudier", 'DE': 'Lernt gerade', 'RU': 'Учится', 'AR': 'يدرس الآن', 'HI': 'पढ़ रहे हैं', 'VI': 'Đang học', 'ES': 'Estudiando', 'TH': 'กำลังเรียน'},
    'restingStatusLabel': {'KO': '휴식중', 'EN': 'Resting', 'JA': '休憩中', 'ZH': '休息中', 'FR': 'En pause', 'DE': 'Pausiert', 'RU': 'Отдыхает', 'AR': 'يستريح الآن', 'HI': 'आराम कर रहे हैं', 'VI': 'Đang nghỉ', 'ES': 'Descansando', 'TH': 'กำลังพัก'},

    'goldMedalLabel': {'KO': '금메달', 'EN': 'Gold Medal', 'JA': '金メダル', 'ZH': '金牌', 'FR': 'Médaille d\'or', 'DE': 'Goldmedaille', 'RU': 'Золотая медаль', 'AR': 'الميدالية الذهبية', 'HI': 'स्वर्ण पदक', 'VI': 'Huy chương vàng', 'ES': 'Medalla de oro', 'TH': 'เหรียญทอง'},
    'silverMedalLabel': {'KO': '은메달', 'EN': 'Silver Medal', 'JA': '銀メダル', 'ZH': '银牌', 'FR': 'Médaille d\'argent', 'DE': 'Silbermedaille', 'RU': 'Серебряная медаль', 'AR': 'الميدالية الفضية', 'HI': 'रजत पदक', 'VI': 'Huy chương bạc', 'ES': 'Medalla de plata', 'TH': 'เหรียญเงิน'},
    'bronzeMedalLabel': {'KO': '동메달', 'EN': 'Bronze Medal', 'JA': '銅メダル', 'ZH': '铜牌', 'FR': 'Médaille de bronze', 'DE': 'Bronzemedaille', 'RU': 'Бронзовая медаль', 'AR': 'الميدالية البرونزية', 'HI': 'कांस्य पदक', 'VI': 'Huy chương đồng', 'ES': 'Medalla de bronce', 'TH': 'เหรียญทองแดง'},

    'rankerLabel': {'KO': '참가자', 'EN': 'Ranker', 'JA': 'ランカー', 'ZH': '排名者', 'FR': 'Participant', 'DE': 'Rangteilnehmer', 'RU': 'Участник рейтинга', 'AR': 'المتصدر', 'HI': 'रैंकर', 'VI': 'Người xếp hạng', 'ES': 'Clasificado', 'TH': 'ผู้อยู่ในอันดับ'},
    'timeLabel': {'KO': '시간', 'EN': 'Time', 'JA': '時間', 'ZH': '时间', 'FR': 'Temps', 'DE': 'Zeit', 'RU': 'Время', 'AR': 'الوقت', 'HI': 'समय', 'VI': 'Thời gian', 'ES': 'Tiempo', 'TH': 'เวลา'},
    'currentRankLabel': {'KO': '현재 순위', 'EN': 'Current Rank', 'JA': '現在の順位', 'ZH': '当前排名', 'FR': 'Rang actuel', 'DE': 'Aktueller Rang', 'RU': 'Текущий рейтинг', 'AR': 'الترتيب الحالي', 'HI': 'वर्तमान रैंक', 'VI': 'Hạng hiện tại', 'ES': 'Rango actual', 'TH': 'อันดับปัจจุบัน'},
    'totalUsersLabel': {'KO': '총 사용자', 'EN': 'Total Users', 'JA': '総ユーザー数', 'ZH': '总用户数', 'FR': 'Utilisateurs totaux', 'DE': 'Gesamtnutzer', 'RU': 'Всего пользователей', 'AR': 'إجمالي المستخدمين', 'HI': 'कुल उपयोगकर्ता', 'VI': 'Tổng số người dùng', 'ES': 'Usuarios totales', 'TH': 'ผู้ใช้ทั้งหมด'},
    'globalStatsDetailTitle': {'KO': '전체 통계 상세', 'EN': 'Global Statistics Detail', 'JA': '全体統計詳細', 'ZH': '全球统计详情', 'FR': 'Détail des statistiques globales', 'DE': 'Details zur globalen Statistik', 'RU': 'Подробная глобальная статистика', 'AR': 'تفاصيل الإحصائيات العالمية', 'HI': 'वैश्विक आँकड़े विवरण', 'VI': 'Chi tiết số liệu toàn cầu', 'ES': 'Detalle de estadísticas globales', 'TH': 'รายละเอียดสถิติทั่วโลก'},
    'systemAchievementAlertTitle': {'KO': '시스템 성취 알림', 'EN': 'System Achievement Alert', 'JA': 'システム達成アラート', 'ZH': '系统成就提醒', 'FR': 'Alerte de réussite système', 'DE': 'System-Erfolgsbenachrichtigung', 'RU': 'Системное уведомление о достижении', 'AR': 'تنبيه إنجاز النظام', 'HI': 'सिस्टम उपलब्धि सूचना', 'VI': 'Thông báo thành tích hệ thống', 'ES': 'Alerta de logro del sistema', 'TH': 'การแจ้งเตือนความสำเร็จของระบบ'},
    'notificationLabel': {'KO': '알림', 'EN': 'Notification', 'JA': '通知', 'ZH': '通知', 'FR': 'Notification', 'DE': 'Benachrichtigung', 'RU': 'Уведомление', 'AR': 'إشعار', 'HI': 'सूचना', 'VI': 'Thông báo', 'ES': 'Notificación', 'TH': 'การแจ้งเตือน'},
    'closeButtonLabel': {'KO': '닫기', 'EN': 'Close', 'JA': '閉じる', 'ZH': '关闭', 'FR': 'Fermer', 'DE': 'Schließen', 'RU': 'Закрыть', 'AR': 'إغلاق', 'HI': 'बंद करें', 'VI': 'Đóng', 'ES': 'Cerrar', 'TH': 'ปิด'},
  };

  // 🆕 [12개국 - 한 줄 문구] 기본값 = "EN (KO)" 결합, 10개국 선택 시 = 단일 언어
  static String _biStr(String key) {
    final map = _uiText[key];
    if (map == null) return key;
    if (_isForeignSelected) {
      return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? key;
    }
    return '${map['EN'] ?? ''} (${map['KO'] ?? ''})';
  }

  // 🆕 [12개국 - 제목형 2단] 기본값 = 영문(위) + 한글(아래) 2줄, 10개국 선택 시 = 단일 언어 1줄
  static Widget _biTitle(
      String enKey,
      String koKey, {
        required TextStyle enStyle,
        required TextStyle koStyle,
        TextStyle? foreignStyle,
      }) {
    if (_isForeignSelected) {
      final map = _uiText[koKey] ?? _uiText[enKey];
      return Text(
        map?[DkeLang.current] ?? map?['EN'] ?? map?['KO'] ?? koKey,
        textAlign: TextAlign.center,
        style: foreignStyle ?? koStyle,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_uiText[enKey]?['EN'] ?? enKey, textAlign: TextAlign.center, style: enStyle),
        Text(_uiText[koKey]?['KO'] ?? koKey, textAlign: TextAlign.center, style: koStyle),
      ],
    );
  }

  // 🆕 [실시간 인원수 캡션] {count} 치환 + 기본값 2줄(영문/한글) / 10개국 선택 시 단일 언어 1줄
  static Widget _liveCountCaption(int count, {required TextStyle mainStyle, required TextStyle subStyle}) {
    if (_isForeignSelected) {
      final template = _uiText['liveCountKoLine']?[DkeLang.current] ?? _uiText['liveCountKoLine']?['EN'] ?? '';
      return Text('$count $template', style: subStyle);
    }
    final koTemplate = _uiText['liveCountKoLine']?['KO'] ?? '';
    return Text(koTemplate.replaceAll('{count}', '$count'), style: subStyle);
  }

  @override
  void initState() {
    super.initState();
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _liveUserCount = 1280 + (math.Random().nextInt(15));
        });
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _showDetailPopup(BuildContext context, String title, String line1, String line2) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1527),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          side: BorderSide(color: Color(0xFFE5C158), width: 1.5),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(line1, textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: const Color(0xFFEFEFEF), fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(line2, textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_biStr('closeButtonLabel'), style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgSpaceDark = Color(0xFF050B14);
    const Color cardSpaceDark = Color(0xFF0D1527);
    const Color brandGolden = Color(0xFFE5C158);
    const Color textWhite = Color(0xFFEFEFEF);

    return Scaffold(
      backgroundColor: bgSpaceDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 140, // 🎯 로고와 타이틀이 모두 여유롭고 예쁘게 들어가도록 높이 확보
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 👑 1. L부터 S까지 타이틀 라인을 예쁘게 감싸도록 배치한 정품 로고 이미지
            Image.asset(
              'assets/images/gsu_logo.png',
              width: 190, // 🎯 타이틀 너비와 시각적 밸런스를 맞추기 위해 정밀 스케일업
              height: 26,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 4), // 🎯 로고와 첫 줄 타이틀 사이 품격 있는 간격

            // 👑 2·3. 기본값 = 영문(위)+한글(아래) 2줄, 10개국 선택 시 = 단일 언어
            _biTitle(
              'appBarTitleEn',
              'appBarTitleKo',
              enStyle: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.5),
              koStyle: GoogleFonts.notoSansKr(color: const Color(0xFFE5C158), fontWeight: FontWeight.bold, fontSize: 23),
              foreignStyle: GoogleFonts.notoSans(color: const Color(0xFFE5C158), fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    // 👑 [지시사항 2번 수호]: 영문 타이틀 크기를 한글과 동일한 16으로 웅장하게 확대!
                    // 📐 줄 터짐(Overflow) 방지 공학: 글자 간격(`letterSpacing`)을 최소화하여 넘침을 철벽 가두리!
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        _uiText['subtitleEn']!['EN']!,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        maxLines: 1,
                        style: GoogleFonts.gowunBatang(color: textWhite.withOpacity(0.6), fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2), // 크기 12 -> 16 / 간격 최소화
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isForeignSelected
                          ? (_uiText['subtitleKo']![DkeLang.current] ?? _uiText['subtitleKo']!['EN']!)
                          : '(${_uiText['subtitleKo']!['KO']})',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      maxLines: 2,
                      style: GoogleFonts.gowunBatang(color: const Color(0xFFFFF6D6), fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // 1. Live Active Users (세계 현재 학습중)
              _buildCategoryWrapper(
                cardSpaceDark, brandGolden, "1. ${_biStr('catLiveActiveUsers')}",
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.circle, color: Color(0xFF1DD1A1), size: 12),
                        const SizedBox(width: 8),
                        Text(
                          _isForeignSelected
                              ? "$_liveUserCount ${_uiText['usersStudyingSuffix']![DkeLang.current] ?? _uiText['usersStudyingSuffix']!['EN']}"
                              : "$_liveUserCount ${_uiText['usersStudyingSuffix']!['EN']}",
                          style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 28, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _liveCountCaption(
                      _liveUserCount,
                      mainStyle: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 14.5, fontWeight: FontWeight.bold),
                      subStyle: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 14.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // 2. Friends Studying New (현재 학습중인 친구)
              _buildCategoryWrapper(
                cardSpaceDark, brandGolden, "2. ${_biStr('catFriendsStudying')}",
                Column(
                  children: [
                    _buildFriendOverflowRow(context, _isTimerRunning, "이규현 (Lee Kyu-hyun)", "3시간 22분 (3h 22m)"),
                    const Divider(color: Colors.white10, height: 20),
                    _buildFriendOverflowRow(context, _isTimerRunning, "심유빈 (Sim Yu-bin)", "1시간 08분 (1h 08m)"),
                    const Divider(color: Colors.white10, height: 20),
                    _buildFriendOverflowRow(context, false, "김승훈 (Kim Seung-hoon)", "2시간 15분 (2h 15m)"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text("${_biStr('timerStatusControlLabel')}: ", style: const TextStyle(color: Colors.white30, fontSize: 11)),
                        Switch(
                          value: _isTimerRunning,
                          activeColor: const Color(0xFF1DD1A1),
                          inactiveThumbColor: Colors.grey,
                          onChanged: (val) => setState(() => _isTimerRunning = val),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              // 3. My Ranking (내 순위)
              _buildCategoryWrapper(
                cardSpaceDark, brandGolden, "3. ${_biStr('catMyRanking')}",
                InkWell(
                  onTap: () => _showDetailPopup(context, _biStr('catMyRanking'), "${_biStr('currentRankLabel')}: 156", "${_biStr('totalUsersLabel')}: 15,789명"),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_biStr('currentRankLabel'), style: GoogleFonts.gowunBatang(color: textWhite, fontSize: 15, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          "156 / 15,789 Users (156위/15,789명)...",
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Today's Live Ranking (오늘 실시간 랭킹)
              _buildCategoryWrapper(
                cardSpaceDark, brandGolden, "4. ${_biStr('catTodaysLiveRanking')}",
                Column(
                  children: [
                    _buildMedalOverflowRow(context, "🥇 ${_biStr('goldMedalLabel')}", "이규현 (Lee Kyu-hyun)", "4시간 12분 (4h 12m)", const Color(0xFFF1C40F)),
                    const SizedBox(height: 12),
                    _buildMedalOverflowRow(context, "🥈 ${_biStr('silverMedalLabel')}", "심유빈 (Sim Yu-bin)", "3시간 58분 (3h 58m)", const Color(0xFFBDC3C7)),
                    const SizedBox(height: 12),
                    _buildMedalOverflowRow(context, "🥉 ${_biStr('bronzeMedalLabel')}", "김승훈 (Kim Seung-hoon)", "3시간 57분 (3h 57m)", const Color(0xFFE67E22)),
                  ],
                ),
              ),

              // 6. Today's Popular Targets (오늘의 인기 목표)
              _buildCategoryWrapper(
                cardSpaceDark, brandGolden, "6. ${_biStr('catPopularTargets')}",
                Column(
                  children: [
                    _buildPopularTargetRow(brandGolden, "1", "Seoul National University (서울대학교)"),
                    _buildPopularTargetRow(brandGolden, "2", "Medical Doctor (의사)"),
                    _buildPopularTargetRow(brandGolden, "3", "TOEIC 900 (토익 900)"),
                    _buildPopularTargetRow(brandGolden, "4", "Public Official (공무원)"),
                    _buildPopularTargetRow(brandGolden, "5", "Police Officer (경찰)"),
                  ],
                ),
              ),

              // 7. Today's Global Statistics (오늘의 전체 통계)
              _buildCategoryWrapper(
                cardSpaceDark, brandGolden, "7. ${_biStr('catGlobalStats')}",
                Column(
                  children: [
                    _buildStatsOverflowRow(context, textWhite, brandGolden, "Total Study Time (총 학습시간)", "23,345/h"),
                    const Divider(color: Colors.white10, height: 16),
                    _buildStatsOverflowRow(context, textWhite, brandGolden, "Total Stars Collected (총 획득 별)", "1,187,520 ✨"),
                    const Divider(color: Colors.white10, height: 16),
                    _buildStatsOverflowRow(context, textWhite, brandGolden, "Target Achieved (목표 달성)", "1,532 Users (1,532명)"),
                  ],
                ),
              ),

              // 8. Real-time Achievement Alerts (실시간 성취 알림)
              _buildCategoryWrapper(
                cardSpaceDark, brandGolden, "8. ${_biStr('catRealtimeAlerts')}",
                Column(
                  children: [
                    _buildAlertOverflowRow(context, "⭐", "Kim○○ has reached Lv.10 (김○○님 Lv.10 달성)"),
                    const SizedBox(height: 10),
                    _buildAlertOverflowRow(context, "🔥", "Park○○ achieved 30 days consecutive study (박○○님 30일 연속 학습)"),
                    const SizedBox(height: 10),
                    _buildAlertOverflowRow(context, "👑", "Lee○○ collected 1,000 stars (이○○님 별 1,000개 달성)"),
                  ],
                ),
              ),

              // 9. Global Total Subject Ratio (세계 총 과목비율)
              _buildCategoryWrapper(
                cardSpaceDark, brandGolden, "9. ${_biStr('catSubjectRatio')}",
                Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(color: const Color(0xFFFF4D4D), value: 35, title: '35%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                PieChartSectionData(color: const Color(0xFFFF9F43), value: 25, title: '25%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                PieChartSectionData(color: const Color(0xFFFECA57), value: 19, title: '19%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                PieChartSectionData(color: const Color(0xFF1DD1A1), value: 12, title: '12%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                PieChartSectionData(color: const Color(0xFF54A0FF), value: 10, title: '10%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4.0),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.star, color: brandGolden, size: 32);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildRatioLegendRow(const Color(0xFFFF4D4D), "Mathematics (수학)", "35%"),
                    _buildRatioLegendRow(const Color(0xFFFF9F43), "English (영어)", "25%"),
                    _buildRatioLegendRow(const Color(0xFFFECA57), "Native Language (자국어)", "19%"),
                    _buildRatioLegendRow(const Color(0xFF1DD1A1), "Science (과학)", "12%"),
                    _buildRatioLegendRow(const Color(0xFF54A0FF), "Others (기타)", "10%"),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryWrapper(Color cardBg, Color golden, String title, Widget content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20.0),
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: golden.withOpacity(0.25), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.gowunBatang(color: golden, fontSize: 15, fontWeight: FontWeight.w900, height: 1.3),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Divider(color: Colors.white12, height: 1)),
          const SizedBox(height: 6),
          content,
        ],
      ),
    );
  }

  Widget _buildFriendOverflowRow(BuildContext context, bool isRunning, String name, String time) {
    return InkWell(
      onTap: () => _showDetailPopup(context, isRunning ? _biStr('studyingStatusLabel') : _biStr('restingStatusLabel'), name, time),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRunning ? const Color(0xFF54A0FF) : Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$name - ${isRunning ? _biStr('studyingStatusLabel') : _biStr('restingStatusLabel')}",
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.gowunBatang(color: const Color(0xFFEFEFEF), fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "${time.substring(0, math.min(8, time.length))}...",
            style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMedalOverflowRow(BuildContext context, String medalTitle, String name, String time, Color medalColor) {
    return InkWell(
      onTap: () => _showDetailPopup(context, medalTitle, "${_biStr('rankerLabel')}: $name", "${_biStr('timeLabel')}: $time"),
      child: Row(
        children: [
          Text(medalTitle.split(" ")[0], style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            time,
            style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 13.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverflowRow(BuildContext context, Color textWhite, Color golden, String title, String value) {
    return InkWell(
      onTap: () => _showDetailPopup(context, _biStr('globalStatsDetailTitle'), title, value),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.gowunBatang(color: textWhite, fontSize: 13.5, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 15),
          Text(
            value,
            style: GoogleFonts.gowunBatang(color: golden, fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertOverflowRow(BuildContext context, String icon, String systemText) {
    return InkWell(
      onTap: () => _showDetailPopup(context, _biStr('systemAchievementAlertTitle'), _biStr('notificationLabel'), systemText),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              systemText,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularTargetRow(Color golden, String rank, String targetName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        children: [
          Text("$rank.", style: GoogleFonts.gowunBatang(color: golden, fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(width: 12),
          Expanded(child: Text(targetName, style: GoogleFonts.gowunBatang(color: const Color(0xFFEFEFEF), fontSize: 14.5, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildRatioLegendRow(Color color, String subjectName, String percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 12),
          Expanded(child: Text(subjectName, style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold))),
          Text(percentage, style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontSize: 14, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
