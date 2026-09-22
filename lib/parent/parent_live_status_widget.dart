import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../global_lang.dart';


// ---------------------------------------------------------------------------
// 🆕 [12개국어] 이 화면 전용 번역 헬퍼/사전. 기본모드(KO/EN)는 한글+영문 동시,
// 10개국어(JA/ZH/FR/DE/RU/AR/HI/VI/ES/TH) 선택 시 해당 언어만 단독 표시.
// ---------------------------------------------------------------------------
String _t(Map<String, String> map) => map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? '';
String _bi(Map<String, String> map) {
  if (DkeLang.isForeignSelected) return _t(map);
  return "${map['KO']}/${map['EN']}";
}

// 🆕 [요청 2026-09-08] "한글/English" 한 줄 대신, 한글 한 줄 + 영문 한 줄로 나눠서 보여주는
// 위젯 버전. 기본모드(KO/EN)에서 문구가 길 때 한 줄에 욱여넣지 않고 읽기 편하게 함.
Widget _biTwoLineWidget(Map<String, String> map, {required TextStyle koStyle, required TextStyle enStyle}) {
  if (DkeLang.isForeignSelected) {
    return Text(_t(map), style: koStyle);
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(map['KO'] ?? '', style: koStyle),
      Text(map['EN'] ?? '', style: enStyle),
    ],
  );
}

// 🆕 [요청] "OO님의 가장 최근 학습: 과목" 한 줄 형식 대신, 아래 3줄 형식으로 변경:
// 1줄: "OO님 가장최근 학습 상태"  2줄: "학습과목명칭: 과목"  3줄: "최근 세션 집중학습 : N분"
String recentStatusTitle(String childName) {
  final Map<String, String> map = {
    'KO': '$childName님 가장최근 학습 상태', 'EN': "$childName's Most Recent Study Status",
    'JA': '$childName様の直近の学習状況', 'ZH': '$childName最近的学习状态',
    'FR': "État d'étude le plus récent de $childName", 'DE': 'Neuester Lernstatus von $childName',
    'RU': 'Последний статус обучения $childName', 'AR': 'أحدث حالة دراسية لـ $childName',
    'HI': '$childName की हाल की अध्ययन स्थिति', 'VI': 'Trạng thái học gần nhất của $childName',
    'ES': 'Estado de estudio más reciente de $childName', 'TH': 'สถานะการเรียนล่าสุดของ $childName',
  };
  return _t(map);
}

String subjectNameLine(String subject) {
  final Map<String, String> map = {
    'KO': '학습과목명칭: $subject 과목', 'EN': 'Subject: $subject',
    'JA': '学習科目名称：$subject科目', 'ZH': '学习科目名称：$subject科目',
    'FR': 'Matière étudiée : $subject', 'DE': 'Lernfach: $subject',
    'RU': 'Предмет: $subject', 'AR': 'اسم مادة الدراسة: $subject',
    'HI': 'अध्ययन विषय का नाम: $subject', 'VI': 'Tên môn học: $subject',
    'ES': 'Nombre de la asignatura: $subject', 'TH': 'ชื่อวิชาที่เรียน: $subject',
  };
  return _t(map);
}

String recentFocusLine(int minutes) {
  final Map<String, String> map = {
    'KO': '최근 세션 집중학습 : $minutes분', 'EN': 'Recent session focused study: $minutes min',
    'JA': '直近セッション集中学習：$minutes分', 'ZH': '最近会话专注学习：$minutes分钟',
    'FR': "Étude concentrée de la dernière session : $minutes min", 'DE': 'Fokussiertes Lernen der letzten Sitzung: $minutes Min.',
    'RU': 'Сосредоточенное обучение за последнее занятие: $minutes мин', 'AR': 'الدراسة المركزة للجلسة الأخيرة: $minutes دقيقة',
    'HI': 'हाल के सत्र का केंद्रित अध्ययन: $minutes मिनट', 'VI': 'Học tập trung phiên gần nhất: $minutes phút',
    'ES': 'Estudio concentrado de la sesión reciente: $minutes min', 'TH': 'การเรียนแบบตั้งใจเซสชันล่าสุด: $minutes นาที',
  };
  return _t(map);
}

String noSessionYetText(String childName) {
  final Map<String, String> map = {
    'KO': '$childName님의 학습 기록이 아직 없습니다', 'EN': "$childName doesn't have any study records yet",
    'JA': '$childName様の学習記録がまだありません', 'ZH': '$childName尚无学习记录',
    'FR': "Aucun enregistrement d'étude pour $childName pour le moment", 'DE': 'Für $childName liegen noch keine Lernaufzeichnungen vor',
    'RU': 'У $childName пока нет учебных записей', 'AR': 'لا توجد سجلات دراسية لـ $childName بعد',
    'HI': '$childName का अभी तक कोई अध्ययन रिकॉर्ड नहीं है', 'VI': '$childName chưa có hồ sơ học tập nào',
    'ES': '$childName aún no tiene registros de estudio', 'TH': '$childName ยังไม่มีบันทึกการเรียน',
  };
  return _t(map);
}

String focusDurationText(int minutes) {
  final Map<String, String> map = {
    'KO': "최근 세션 집중시간 '$minutes분'", 'EN': "Recent session focus time: '$minutes min'",
    'JA': "直近セッション集中時間「$minutes分」", 'ZH': "最近会话专注时长「$minutes分钟」",
    'FR': "Temps de concentration de la dernière session : « $minutes min »", 'DE': "Fokuszeit der letzten Sitzung: „$minutes Min.“",
    'RU': "Время концентрации последнего занятия: «$minutes мин»", 'AR': "وقت التركيز في الجلسة الأخيرة: '$minutes دقيقة'",
    'HI': "हाल के सत्र का फोकस समय: '$minutes मिनट'", 'VI': "Thời gian tập trung phiên gần nhất: '$minutes phút'",
    'ES': "Tiempo de concentración de la sesión reciente: '$minutes min'", 'TH': "เวลาโฟกัสเซสชันล่าสุด: '$minutes นาที'",
  };
  return _t(map);
}

const Map<String, String> kEncourageMsgSectionMap = {'KO': '격려 메세지 전송', 'EN': 'Send Encouragement', 'JA': '応援メッセージ送信', 'ZH': '发送鼓励消息', 'FR': "Envoyer un message d'encouragement", 'DE': 'Ermutigungsnachricht senden', 'RU': 'Отправить сообщение поддержки', 'AR': 'إرسال رسالة تشجيع', 'HI': 'प्रोत्साहन संदेश भेजें', 'VI': 'Gửi tin nhắn động viên', 'ES': 'Enviar mensaje de ánimo', 'TH': 'ส่งข้อความให้กำลังใจ'};

// 이모지 버튼 라벨 + 실제 전송 문구 (한글 원문 kept for the actual sent data key logic; 표시만 번역)
const Map<String, Map<String, String>> kEmojiLabelMap = {
  "밝음": {'KO': '밝음', 'EN': 'Bright', 'JA': '明るい', 'ZH': '开朗', 'FR': 'Joyeux', 'DE': 'Fröhlich', 'RU': 'Бодро', 'AR': 'مشرق', 'HI': 'उज्ज्वल', 'VI': 'Vui vẻ', 'ES': 'Alegre', 'TH': 'สดใส'},
  "최고": {'KO': '최고', 'EN': 'Great', 'JA': '最高', 'ZH': '最棒', 'FR': 'Super', 'DE': 'Top', 'RU': 'Отлично', 'AR': 'رائع', 'HI': 'शानदार', 'VI': 'Tuyệt vời', 'ES': 'Genial', 'TH': 'ยอดเยี่ยม'},
  "열공": {'KO': '열공', 'EN': 'Focused', 'JA': '猛勉強', 'ZH': '努力学习', 'FR': 'Concentré', 'DE': 'Fokussiert', 'RU': 'Усердие', 'AR': 'مجتهد', 'HI': 'मेहनती', 'VI': 'Chăm học', 'ES': 'Enfocado', 'TH': 'ตั้งใจเรียน'},
  "1등": {'KO': '1등', 'EN': '#1', 'JA': '1位', 'ZH': '第一', 'FR': 'N°1', 'DE': 'Nr. 1', 'RU': '№1', 'AR': 'الأول', 'HI': '#1', 'VI': 'Số 1', 'ES': 'N.º 1', 'TH': 'อันดับ 1'},
};
String emojiLabel(String koLabel) => _bi(kEmojiLabelMap[koLabel] ?? {'KO': koLabel, 'EN': koLabel});

const Map<String, Map<String, String>> kEmojiMessageMap = {
  "집중도 최고야!": {'KO': '🙂 우리 아이, 잘하고 있어. 화이팅!', 'EN': "🙂 You're doing great! Fighting!"},
  "포기하지 마라!": {'KO': '👍 힘내! 엄마 아빠가 응원할게! 사랑해~^^', 'EN': '👍 Keep going! Mom and Dad are cheering for you! Love you~^^'},
  "너의 노력을 응원해": {'KO': '🔥 열심히 하는 모습이 정말 자랑스럽고 대견하다. 고마워~^^', 'EN': "🔥 We're so proud of how hard you're working. Thank you~^^"},
  "최고의 집중력이야": {'KO': '👑 네 꿈을 향한 걸음, 함께 응원할게! 화이팅~^^', 'EN': "👑 We're cheering every step toward your dream! Fighting~^^"},
};
// 🆕 [요청 2026-09-22] 한글 한 줄 + 영문 한 줄로 학생 화면에 표시하기 위해,
// 단일 문자열 대신 두 줄을 개행(\n)으로 합쳐서 반환. main.dart의 이모지 오버레이가
// 이 문자열을 그대로 Text(maxLines: 2)로 표시하므로 별도 위젯 변경 없이 반영됨.
String emojiMessage(String koMsg) {
  final map = kEmojiMessageMap[koMsg];
  if (map == null) return koMsg;
  if (DkeLang.isForeignSelected) return map['EN'] ?? koMsg;
  return "${map['KO']}\n${map['EN']}";
}

const Map<String, String> kSectionEncourageEngMap = {'KO': '자기주도 학습 응원하기', 'EN': 'Encourage Self-Directed Learning', 'JA': '自己主導学習を応援する', 'ZH': '为自主学习加油', 'FR': "Encourager l'apprentissage autonome", 'DE': 'Selbstgesteuertes Lernen fördern', 'RU': 'Поддержка самостоятельного обучения', 'AR': 'تشجيع التعلم الذاتي', 'HI': 'स्व-निर्देशित सीखने को प्रोत्साहित करें', 'VI': 'Cổ vũ học tập tự định hướng', 'ES': 'Fomentar el aprendizaje autodirigido', 'TH': 'ให้กำลังใจการเรียนรู้ด้วยตนเอง'};

const Map<String, String> kQuickPhrasesHintMap = {'KO': '자주 쓰는 응원 문구 (터치 시 자동 입력)', 'EN': 'Frequently used phrases (tap to auto-fill)', 'JA': 'よく使う応援フレーズ（タップで自動入力）', 'ZH': '常用鼓励语（点击自动输入）', 'FR': "Phrases fréquentes (touchez pour remplir automatiquement)", 'DE': 'Häufig genutzte Sätze (antippen zum Ausfüllen)', 'RU': 'Часто используемые фразы (нажмите для автозаполнения)', 'AR': 'العبارات الشائعة (اضغط للتعبئة التلقائية)', 'HI': 'अक्सर इस्तेमाल वाक्यांश (टैप कर स्वतः भरें)', 'VI': 'Câu nói thường dùng (chạm để tự động điền)', 'ES': 'Frases frecuentes (toca para autocompletar)', 'TH': 'ข้อความให้กำลังใจที่ใช้บ่อย (แตะเพื่อกรอกอัตโนมัติ)'};

const List<Map<String, String>> kQuickMessages = [
  {'KO': '① 지금 흘리는 땀과 노력은 반드시 너의 꿈을 이루는 소중한 힘이 될 거야.', 'EN': '① The sweat and effort you put in now will surely become the strength that fulfills your dream.'},
  {'KO': '② 힘들고 지칠 때도 있겠지만, 엄마 아빠는 언제나 너를 믿고 응원하고 있어.', 'EN': '② There may be tough and tiring days, but Mom and Dad always believe in you and cheer for you.'},
  {'KO': '③ 잘해야 한다는 부담은 내려놓아도 괜찮아. 오늘 최선을 다하는 너를 우리는 사랑해.', 'EN': "③ It's okay to let go of the pressure to be perfect. We love you for doing your best today."},
  {'KO': '④ 한 걸음이 느려도 괜찮아. 포기하지 않고 나아가는 네 모습이 정말 자랑스러워.', 'EN': "④ It's okay if a step is slow. We're truly proud of you for moving forward without giving up."},
  {'KO': '⑤ 오늘의 작은 노력이 훗날 큰 꿈을 이루는 순간, 가장 빛나는 기억이 될 거야.', 'EN': "⑤ Today's small effort will become the brightest memory when your big dream comes true."},
  {'KO': '⑥ 공부하는 지금의 시간이 너의 미래를 만들어가고 있어. 우리 아이, 조금만 더 힘내자.', 'EN': '⑥ This time you spend studying now is shaping your future. Our child, just a little more, keep going.'},
];

const Map<String, String> kCharCountSuffixMap = {'KO': '자', 'EN': '', 'JA': '文字', 'ZH': '字', 'FR': '', 'DE': '', 'RU': '', 'AR': '', 'HI': '', 'VI': ' ký tự', 'ES': '', 'TH': ' ตัวอักษร'};
String charCounterText(int current, int max) {
  final suffix = kCharCountSuffixMap[DkeLang.current] ?? '';
  return "$current / $max$suffix";
}

const Map<String, String> kMessageHintMap = {
  'KO': '자녀의 타이머 세션을 점유할 문구를 입력하세요.', 'EN': "Enter a message to take over your child's timer session.",
  'JA': 'お子様のタイマーセッションに表示する文言を入力してください。', 'ZH': '请输入将占用孩子计时会话的文字。',
  'FR': "Saisissez un message à afficher sur la session minuteur de votre enfant.", 'DE': 'Geben Sie eine Nachricht ein, die die Timer-Sitzung Ihres Kindes belegt.',
  'RU': 'Введите сообщение для отображения в сеансе таймера ребёнка.', 'AR': 'أدخل رسالة لعرضها على جلسة مؤقت طفلك.',
  'HI': 'बच्चे के टाइमर सत्र पर दिखाने के लिए संदेश दर्ज करें।', 'VI': 'Nhập nội dung để hiển thị trên phiên hẹn giờ của con.',
  'ES': 'Ingrese un mensaje para mostrar en la sesión del temporizador de su hijo/a.', 'TH': 'กรอกข้อความที่จะแสดงในเซสชันจับเวลาของบุตรหลาน',
};

String lastSentText(String time) {
  final Map<String, String> map = {
    'KO': '[최근 전송 성공 - $time]', 'EN': '[Last sent successfully - $time]',
    'JA': '[直近送信成功 - $time]', 'ZH': '[最近发送成功 - $time]',
    'FR': '[Dernier envoi réussi - $time]', 'DE': '[Zuletzt erfolgreich gesendet - $time]',
    'RU': '[Последняя отправка успешна - $time]', 'AR': '[آخر إرسال ناجح - $time]',
    'HI': '[अंतिम सफल भेजा गया - $time]', 'VI': '[Gửi thành công gần nhất - $time]',
    'ES': '[Último envío exitoso - $time]', 'TH': '[ส่งสำเร็จล่าสุด - $time]',
  };
  return _t(map);
}
const Map<String, String> kWaitingMap = {'KO': '대기 중...', 'EN': 'Waiting...', 'JA': '待機中...', 'ZH': '等待中...', 'FR': 'En attente...', 'DE': 'Warten...', 'RU': 'Ожидание...', 'AR': 'في الانتظار...', 'HI': 'प्रतीक्षा में...', 'VI': 'Đang chờ...', 'ES': 'Esperando...', 'TH': 'กำลังรอ...'};
const Map<String, String> kSendBtnMap = {'KO': '응원 문자 전송', 'EN': 'Send Message', 'JA': '応援メッセージ送信', 'ZH': '发送鼓励短信', 'FR': 'Envoyer le message', 'DE': 'Nachricht senden', 'RU': 'Отправить сообщение', 'AR': 'إرسال الرسالة', 'HI': 'संदेश भेजें', 'VI': 'Gửi tin nhắn', 'ES': 'Enviar mensaje', 'TH': 'ส่งข้อความ'};

const Map<String, String> kSectionStarsEngMap = {'KO': "Today's Accumulated Stars", 'EN': "Today's Accumulated Stars", 'JA': "Today's Accumulated Stars", 'ZH': "Today's Accumulated Stars", 'FR': "Today's Accumulated Stars", 'DE': "Today's Accumulated Stars", 'RU': "Today's Accumulated Stars", 'AR': "Today's Accumulated Stars", 'HI': "Today's Accumulated Stars", 'VI': "Today's Accumulated Stars", 'ES': "Today's Accumulated Stars", 'TH': "Today's Accumulated Stars"};
String starsSectionKorTitle(int count) {
  final Map<String, String> map = {
    'KO': '오늘의 별 수집 현황 : $count개', 'EN': "Today's Star Collection: $count",
    'JA': '本日の星収集状況：$count個', 'ZH': '今日星星收集情况：$count个',
    'FR': "Étoiles collectées aujourd'hui : $count", 'DE': 'Heute gesammelte Sterne: $count',
    'RU': 'Собрано звёзд сегодня: $count', 'AR': 'النجوم المجمّعة اليوم: $count',
    'HI': 'आज एकत्रित सितारे: $count', 'VI': 'Số sao thu thập hôm nay: $count',
    'ES': 'Estrellas recolectadas hoy: $count', 'TH': 'จำนวนดาวที่สะสมวันนี้: $count',
  };
  return _t(map);
}
String starsSectionForeignTitle(int count) => starsSectionKorTitle(count);

class ParentLiveStatusWidget extends StatefulWidget {
  final String childName;
  // 🆕 [실시간 학습 현황 2026-09-19] 진짜 "지금 이 순간" 학습 중인지를 나타냄.
  final bool isStudyingNow;
  final String liveSubject;
  final int liveElapsedSeconds;
  final int liveTotalSeconds;
  // 🆕 [실시간 연동] "현재 진행 중"을...  (172번째 줄부터는 원래 있던 내용 그대로 이어짐)
  // 🆕 [실데이터 연동] "현재 진행 중"을 실제로 감지할 방법이 없어(부모 화면은 별도 프로세스이므로),
  // 가장 최근 학습 세션 정보로 대체 표시합니다. 값이 없으면 lastSessionSubject가 null입니다.
  final String? lastSessionSubject;
  final int lastSessionDurationMinutes;
  final int totalCollectedStars;
  // 🆕 [버그 수정 2026-09-06] 자녀 선택(Firestore 연동) 시, 그 자녀의 실제 전체 누적 별
  // 개수를 장학금 위젯에도 함께 전달하기 위한 필드. null이면(연결된 자녀 없음) 장학금
  // 위젯이 원래처럼 이 기기의 로컬 데이터를 사용합니다.
  final int? allTimeTotalStars;
  final bool isMonitoringActive;
  final int monitoringCountdown;
  final Color premiumCardBg;
  final Color brandGolden;
  final Color luxuryDarkBg;
  final VoidCallback onStartMonitoring;
  final Function(String, String) onSendEmojiMessage;
  final Function(String) onSendCustomMessage;
  final String lastSentTimeText;
  final Widget Function(String, String, {required double fontSize, String? foreignTitle}) buildCustomSectionTitle;

  const ParentLiveStatusWidget({
    Key? key,
    this.isStudyingNow = false,
    this.liveSubject = '',
    this.liveElapsedSeconds = 0,
    this.liveTotalSeconds = 0,
    required this.childName,
    required this.lastSessionSubject,
    required this.lastSessionDurationMinutes,
    required this.totalCollectedStars,
    this.allTimeTotalStars,
    required this.isMonitoringActive,
    required this.monitoringCountdown,
    required this.premiumCardBg,
    required this.brandGolden,
    required this.luxuryDarkBg,
    required this.onStartMonitoring,
    required this.onSendEmojiMessage,
    required this.onSendCustomMessage,
    required this.lastSentTimeText,
    required this.buildCustomSectionTitle,
  }) : super(key: key);

  @override
  State<ParentLiveStatusWidget> createState() => _ParentLiveStatusWidgetState();
}

class _ParentLiveStatusWidgetState extends State<ParentLiveStatusWidget> {
  final TextEditingController _customMessageController = TextEditingController();

  // ============================================================================
  // 🆕 [실시간 학습 현황 2026-09-19] "지금 학습 중" 카드. 학생 타이머 화면의
  // 막대그래프(6색 구간, 목표시간 기준 자동 분할, 분/% 자동표시)와 100% 동일한
  // 구조를 부모방에도 재현함. 동그라미는 학습 중=진한 파랑 입체, 쉬는 중=흰색 입체.
  // ============================================================================
  Widget _buildLiveStudyingCard() {
    final bool isStudying = widget.isStudyingNow;
    final int elapsed = widget.liveElapsedSeconds;
    final int total = widget.liveTotalSeconds;
    final double progress = (total > 0) ? (elapsed / total).clamp(0.0, 1.0) : 0.0;
    final int elapsedMinutes = elapsed ~/ 60;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: widget.premiumCardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: widget.brandGolden.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${widget.childName}'s Most Recent Study Status",
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            "${widget.childName}님 가장 최근 학습 상태",
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // 🆕 학습 중 = 진한 파랑 입체 동그라미 / 쉬는 중(정지·종료 모두) = 흰색 입체 동그라미
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isStudying
                        ? [const Color(0xFF5AA7FF), const Color(0xFF0D47C7)]
                        : [Colors.white, const Color(0xFFB8BCC4)],
                    center: const Alignment(-0.3, -0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isStudying ? const Color(0xFF1565C0) : Colors.black26).withValues(alpha: 0.6),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 🆕 [요청 2026-09-21] 상태 줄만 영문 한 줄 + 한글 한 줄 2줄 구성으로 변경.
              // 학습 중이면 파란색 + 과목명, 정지/종료 중이면 흰색(Colors.white70) + "휴식중" 문구로
              // 이 두 줄만 바뀌고, 그 아래 무지개 바/퍼센트 등 나머지 레이아웃은 그대로 유지됨.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: isStudying
                      ? [
                    Text(
                      "지금 학습중(Studying now)",
                      style: GoogleFonts.notoSansKr(
                        color: const Color(0xFF5AA7FF),
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "- ${widget.liveSubject} (${elapsedMinutes}분째)",
                      style: GoogleFonts.notoSansKr(
                        color: const Color(0xFF5AA7FF),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]
                      : [
                    Text(
                      "현재 잠시 휴식중(Currently resting)",
                      style: GoogleFonts.notoSansKr(
                        color: Colors.white70,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 14),
            // 🆕 학생 타이머 화면과 동일한 6색 구간 막대그래프
            LayoutBuilder(
              builder: (context, constraints) {
                final List<Color> rainbowColors = [
                  const Color(0xFFFF3B30),
                  const Color(0xFFFF9500),
                  const Color(0xFFFFCC00),
                  const Color(0xFF34C759),
                  const Color(0xFF007AFF),
                  const Color(0xFF5856D6),
                ];
                return Container(
                  width: constraints.maxWidth,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1527),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: widget.brandGolden.withValues(alpha: 0.3), width: 1.0),
                  ),
                  child: Row(
                    children: List.generate(6, (index) {
                      final double itemWidth = (constraints.maxWidth - 2.0) / 6;
                      final double startFactor = index / 6.0;
                      final double endFactor = (index + 1) / 6.0;
                      double itemProgress;
                      if (progress >= endFactor) {
                        itemProgress = 1.0;
                      } else if (progress <= startFactor) {
                        itemProgress = 0.0;
                      } else {
                        itemProgress = (progress - startFactor) / (endFactor - startFactor);
                      }
                      return Container(
                        width: itemWidth,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          border: index < 5
                              ? Border(right: BorderSide(color: widget.brandGolden.withValues(alpha: 0.25), width: 1.0))
                              : null,
                        ),
                        child: Stack(
                          children: [
                            if (itemProgress > 0)
                              FractionallySizedBox(
                                widthFactor: itemProgress,
                                child: Container(color: rainbowColors[index]),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            // 🆕 목표시간 기준 자동 계산되는 분/% 표시 (학생 화면과 동일한 방식)
            LayoutBuilder(
              builder: (context, constraints) {
                final double totalMinutes = total / 60.0;
                final double interval = totalMinutes / 6.0;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    final double currentInterval = interval * (index + 1);
                    final int currentPercentage = ((index + 1) / 6.0 * 100).round();
                    final double itemWidth = constraints.maxWidth / 6;
                    return SizedBox(
                      width: itemWidth,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "${currentInterval.toStringAsFixed(1)}m\n($currentPercentage%)",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, height: 1.2),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              "목표 시간: ${elapsedMinutes}m / ${(total / 60).round()}m",
              style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _customMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 🆕 [실시간 학습 현황 2026-09-19] "지금 이 순간 학습 중"이면 이 카드를
          // 통째로 실시간 카드로 교체함. 쉬는 중이면 기존 과거 세션 요약 카드를
          // 그대로 보여줌 (아래 원래 있던 Container는 그대로 유지, 손대지 않음).
          if (widget.liveTotalSeconds > 0)
            _buildLiveStudyingCard()
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: widget.premiumCardBg,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: widget.brandGolden.withValues(alpha: 0.3), width: 1.2),
              ),
              child: Column(
                children: widget.lastSessionSubject != null
                  ? [
                // 🆕 [요청] 3줄 형식: 1) OO님 가장최근 학습 상태  2) 학습과목명칭: 과목  3) 최근 세션 집중학습 : N분
                Text(
                  recentStatusTitle(widget.childName),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  subjectNameLine(widget.lastSessionSubject!),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13.0, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  recentFocusLine(widget.lastSessionDurationMinutes),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontSize: 14.5, fontWeight: FontWeight.bold),
                ),
              ]
                  : [
                Text(
                  noSessionYetText(widget.childName),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bi(kEncourageMsgSectionMap),
                  style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildEmojiButton("😊", "밝음", "집중도 최고야!"),
                    _buildEmojiButton("👍", "최고", "포기하지 마라!"),
                    _buildEmojiButton("🔥", "열공", "너의 노력을 응원해"),
                    _buildEmojiButton("👑", "1등", "최고의 집중력이야"),
                  ],
                ),
              ],
            ),
          ),

          widget.buildCustomSectionTitle("Encourage Self-Directed Learning", "자기주도 학습 응원하기", fontSize: 14.0, foreignTitle: _t(kSectionEncourageEngMap)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.premiumCardBg,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: widget.brandGolden.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _biTwoLineWidget(
                  kQuickPhrasesHintMap,
                  koStyle: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                  enStyle: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 34,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: kQuickMessages.length,
                    itemBuilder: (context, index) {
                      final String displayText = _t(kQuickMessages[index]);
                      final String koText = kQuickMessages[index]['KO']!;
                      final String enText = kQuickMessages[index]['EN']!;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ActionChip(
                          backgroundColor: Colors.black38,
                          side: BorderSide(color: widget.brandGolden.withValues(alpha: 0.15)),
                          label: Text(
                            displayText,
                            style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 11),
                          ),
                          onPressed: () {
                            setState(() {
                              // 🆕 [요청 2026-09-22] 기본모드(KO/EN)에서는 한글+영문 2줄을 합쳐서
                              // 입력창에 채워, 학생 화면에도 두 언어가 함께 전달되도록 함.
                              _customMessageController.text = DkeLang.isForeignSelected ? displayText : "$koText\n$enText";
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _customMessageController,
                  maxLength: 200,
                  maxLines: 3,
                  style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13),
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                    return Text(
                      charCounterText(currentLength, maxLength ?? 50),
                      style: GoogleFonts.rajdhani(color: widget.brandGolden, fontSize: 11, fontWeight: FontWeight.bold),
                    );
                  },
                  decoration: InputDecoration(
                    hintText: _bi(kMessageHintMap),
                    hintStyle: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12),
                    filled: true,
                    fillColor: Colors.black45,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: widget.brandGolden),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 🆕 [오버플로우 수정 2026-09-06] 한글+영문 병기로 문구가 길어져서
                    // 버튼과 함께 배치했을 때 화면 폭을 넘던 문제 - Expanded로 감싸고
                    // 1줄로 말줄임 처리해서 버튼 자리를 항상 확보합니다.
                    Expanded(
                      child: Text(
                        widget.lastSentTimeText.isNotEmpty
                            ? lastSentText(widget.lastSentTimeText)
                            : _bi(kWaitingMap),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSansKr(color: widget.brandGolden.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.brandGolden,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        if (_customMessageController.text.trim().isEmpty) return;
                        widget.onSendCustomMessage(_customMessageController.text.trim());
                        _customMessageController.clear();
                        FocusScope.of(context).unfocus();
                      },
                      icon: const Icon(Icons.send_rounded, color: Colors.black, size: 14),
                      label: Text(
                        _bi(kSendBtnMap),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          widget.buildCustomSectionTitle("Today's Accumulated Stars", "오늘의 별 수집 현황 : ${widget.totalCollectedStars}개", fontSize: 14.0, foreignTitle: starsSectionForeignTitle(widget.totalCollectedStars)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildEmojiButton(String emoji, String koLabel, String koMessage) {
    return InkWell(
      onTap: () => widget.onSendEmojiMessage(emoji, emojiMessage(koMessage)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.luxuryDarkBg,
              shape: BoxShape.circle,
              border: Border.all(color: widget.brandGolden.withValues(alpha: 0.3)),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: 6),
          Text(
            emojiLabel(koLabel),
            style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 🪐 FullMirrorTimerScreen — 실데이터와 무관한 데모용 미러 타이머 화면이라 원본 그대로 유지
// (기존 코드 주석에 따라 이번 다국어 작업에서도 그대로 보존합니다)
// ============================================================================
class FullMirrorTimerScreen extends StatefulWidget {
  final Color brandGolden;
  final String childName;
  const FullMirrorTimerScreen({Key? key, required this.brandGolden, required this.childName}) : super(key: key);

  @override
  State<FullMirrorTimerScreen> createState() => _FullMirrorTimerScreenState();
}

class _FullMirrorTimerScreenState extends State<FullMirrorTimerScreen> {
  Timer? _runningTimer;
  int _totalSeconds = 0;
  final int _maxLoopSecs = 30;

  @override
  void initState() {
    super.initState();
    _runningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _totalSeconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _runningTimer?.cancel();
    super.dispose();
  }

  String _formatToClock(int secs) {
    int h = secs ~/ 3600;
    int m = (secs % 3600) ~/ 60;
    int s = secs % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    double progressRatio = (_totalSeconds % _maxLoopSecs) / _maxLoopSecs;
    int currentSec = _totalSeconds % _maxLoopSecs;

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/timer.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF020617)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 25),
                  Text(
                    "GKE\nSTUDYUP",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansKr(
                      color: widget.brandGolden,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Image.asset(
                    'assets/images/crown_wings.png',
                    width: 150,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.wb_twighlight, color: Color(0xFFE5C158), size: 35),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "— 2027 대학수능 —",
                    style: GoogleFonts.nanumMyeongjo(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "D - Day",
                    style: GoogleFonts.notoSansKr(
                      color: const Color(0xFFFFFDF0),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Icon(Icons.star_rounded, color: Color(0xFFE5C158), size: 105),
                  const SizedBox(height: 15),
                  Text(
                    "★ 배속 실험 모드 가동 : $currentSec / 30 Secs",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Gothic',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatToClock(_totalSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Gothic',
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.volume_up_rounded, color: Color(0xFFFCD34D), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "Native Language (국어)",
                        style: GoogleFonts.gowunBatang(
                          color: const Color(0xFFFCD34D),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "실시간 집중 모드 (실험)",
                        style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "목표 시간: 30분",
                        style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progressRatio,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFF0000),
                                Color(0xFFFF7F00),
                                Color(0xFFFFFF00),
                                Color(0xFF00FF00),
                                Color(0xFF0000FF),
                                Color(0xFF4B0082),
                                Color(0xFF8B00FF),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${currentSec.toDouble().toStringAsFixed(1)}초 (${(progressRatio * 100).toStringAsFixed(0)}%)",
                        style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "30.0초 (100%)",
                        style: TextStyle(color: widget.brandGolden, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12, right: 2),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: widget.brandGolden.withValues(alpha: 0.4), width: 1.2),
                        ),
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 12),
                          label: Text(
                            "뒤로가기  ",
                            style: GoogleFonts.notoSansKr(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
