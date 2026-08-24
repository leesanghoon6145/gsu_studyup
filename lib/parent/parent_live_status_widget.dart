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

String lastSessionText(String childName, String subject) {
  final Map<String, String> map = {
    'KO': '$childName님의 가장 최근 학습: "$subject"', 'EN': "$childName's most recent study: \"$subject\"",
    'JA': '$childName様の直近の学習：「$subject」', 'ZH': '$childName最近的学习："$subject"',
    'FR': "Étude la plus récente de $childName : « $subject »", 'DE': 'Letzte Lernaktivität von $childName: „$subject"',
    'RU': 'Последнее занятие $childName: «$subject»', 'AR': 'أحدث دراسة لـ $childName: "$subject"',
    'HI': '$childName की हाल की पढ़ाई: "$subject"', 'VI': 'Buổi học gần nhất của $childName: "$subject"',
    'ES': 'Estudio más reciente de $childName: "$subject"', 'TH': 'การเรียนล่าสุดของ $childName: "$subject"',
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
  "집중도 최고야!": {'KO': '집중도 최고야!', 'EN': 'Your focus is amazing!', 'JA': '集中力最高だよ！', 'ZH': '专注度满分！', 'FR': 'Ta concentration est incroyable !', 'DE': 'Deine Konzentration ist super!', 'RU': 'Твоя концентрация на высоте!', 'AR': 'تركيزك رائع جدًا!', 'HI': 'तुम्हारा फोकस कमाल का है!', 'VI': 'Sự tập trung của con tuyệt vời!', 'ES': '¡Tu concentración es increíble!', 'TH': 'สมาธิของลูกยอดเยี่ยมมาก!'},
  "포기하지 마라!": {'KO': '포기하지 마라!', 'EN': "Don't give up!", 'JA': '諦めないで！', 'ZH': '不要放弃！', 'FR': "N'abandonne pas !", 'DE': 'Gib nicht auf!', 'RU': 'Не сдавайся!', 'AR': 'لا تستسلم!', 'HI': 'हार मत मानो!', 'VI': 'Đừng bỏ cuộc nhé!', 'ES': '¡No te rindas!', 'TH': 'อย่ายอมแพ้นะ!'},
  "너의 노력을 응원해": {'KO': '너의 노력을 응원해', 'EN': "I'm cheering for your effort", 'JA': 'あなたの努力を応援するよ', 'ZH': '为你的努力加油', 'FR': "J'encourage tes efforts", 'DE': 'Ich unterstütze deine Mühe', 'RU': 'Я поддерживаю твои старания', 'AR': 'أنا أشجع مجهودك', 'HI': 'मैं तुम्हारी मेहनत का हौसला बढ़ाता/ती हूं', 'VI': 'Bố/mẹ cổ vũ cho nỗ lực của con', 'ES': 'Apoyo tu esfuerzo', 'TH': 'เป็นกำลังใจให้ความพยายามของลูก'},
  "최고의 집중력이야": {'KO': '최고의 집중력이야', 'EN': "That's the best focus ever", 'JA': '最高の集中力だよ', 'ZH': '这是最棒的专注力', 'FR': "C'est la meilleure concentration", 'DE': 'Das ist beste Konzentration', 'RU': 'Это лучшая концентрация', 'AR': 'هذا أفضل تركيز على الإطلاق', 'HI': 'यह सबसे बेहतरीन फोकस है', 'VI': 'Đây là sự tập trung tuyệt vời nhất', 'ES': 'Es la mejor concentración', 'TH': 'นี่คือสมาธิที่ดีที่สุด'},
};
String emojiMessage(String koMsg) => kEmojiMessageMap[koMsg]?[DkeLang.current] ?? kEmojiMessageMap[koMsg]?['EN'] ?? koMsg;

const Map<String, String> kSectionEncourageEngMap = {'KO': '자기주도 학습 응원하기', 'EN': 'Encourage Self-Directed Learning', 'JA': '自己主導学習を応援する', 'ZH': '为自主学习加油', 'FR': "Encourager l'apprentissage autonome", 'DE': 'Selbstgesteuertes Lernen fördern', 'RU': 'Поддержка самостоятельного обучения', 'AR': 'تشجيع التعلم الذاتي', 'HI': 'स्व-निर्देशित सीखने को प्रोत्साहित करें', 'VI': 'Cổ vũ học tập tự định hướng', 'ES': 'Fomentar el aprendizaje autodirigido', 'TH': 'ให้กำลังใจการเรียนรู้ด้วยตนเอง'};

const Map<String, String> kQuickPhrasesHintMap = {'KO': '자주 쓰는 응원 문구 (터치 시 자동 입력)', 'EN': 'Frequently used phrases (tap to auto-fill)', 'JA': 'よく使う応援フレーズ（タップで自動入力）', 'ZH': '常用鼓励语（点击自动输入）', 'FR': "Phrases fréquentes (touchez pour remplir automatiquement)", 'DE': 'Häufig genutzte Sätze (antippen zum Ausfüllen)', 'RU': 'Часто используемые фразы (нажмите для автозаполнения)', 'AR': 'العبارات الشائعة (اضغط للتعبئة التلقائية)', 'HI': 'अक्सर इस्तेमाल वाक्यांश (टैप कर स्वतः भरें)', 'VI': 'Câu nói thường dùng (chạm để tự động điền)', 'ES': 'Frases frecuentes (toca para autocompletar)', 'TH': 'ข้อความให้กำลังใจที่ใช้บ่อย (แตะเพื่อกรอกอัตโนมัติ)'};

const List<Map<String, String>> kQuickMessages = [
  {'KO': '우리 아이 정말 대단해! 자랑스럽고 고맙다.', 'EN': "You're truly amazing! I'm proud of you and grateful.", 'JA': 'うちの子、本当にすごい！誇らしくて感謝してるよ。', 'ZH': '我们的孩子真的很棒！为你骄傲，也很感激。', 'FR': "Tu es vraiment formidable ! Je suis fier(ère) et reconnaissant(e).", 'DE': 'Du bist wirklich toll! Ich bin stolz auf dich und dankbar.', 'RU': 'Ты правда молодец! Горжусь тобой и благодарен(на).', 'AR': 'أنت رائع حقًا! أنا فخور بك وممتن.', 'HI': 'तुम सच में कमाल हो! मुझे तुम पर गर्व है और आभार भी।', 'VI': 'Con thật tuyệt vời! Bố/mẹ tự hào và biết ơn con.', 'ES': '¡Eres increíble! Estoy orgulloso/a y agradecido/a.', 'TH': 'ลูกของเรานี่สุดยอดจริงๆ! ภูมิใจและขอบคุณนะ'},
  {'KO': '조금만 더 힘내! 네 노력은 절대 헛되지 않아.', 'EN': "Just a bit more! Your effort will never be wasted.", 'JA': 'あと少し頑張って！あなたの努力は決して無駄にならないよ。', 'ZH': '再加把劲！你的努力绝不会白费。', 'FR': "Encore un petit effort ! Tes efforts ne seront jamais vains.", 'DE': 'Noch ein bisschen! Deine Mühe ist nie vergebens.', 'RU': 'Ещё немного! Твои усилия никогда не пропадут зря.', 'AR': 'القليل بعد! جهدك لن يذهب سدى أبدًا.', 'HI': 'थोड़ा और हिम्मत रखो! तुम्हारी मेहनत कभी बेकार नहीं जाएगी।', 'VI': 'Cố lên thêm chút nữa! Nỗ lực của con không bao giờ vô ích.', 'ES': '¡Un poco más de esfuerzo! Tu esfuerzo nunca será en vano.', 'TH': 'อีกนิดเดียวเท่านั้น! ความพยายามของลูกไม่มีวันสูญเปล่า'},
  {'KO': '노력하는 모습 볼 때마다 가슴이 따뜻해져.', 'EN': "My heart warms every time I see you trying so hard.", 'JA': '頑張る姿を見るたびに心が温かくなるよ。', 'ZH': '每次看到你努力的样子，心里都很温暖。', 'FR': "Mon cœur se réchauffe à chaque fois que je te vois faire des efforts.", 'DE': 'Mein Herz wird warm, wenn ich sehe, wie sehr du dich bemühst.', 'RU': 'Сердце теплеет каждый раз, когда вижу твои старания.', 'AR': 'يدفأ قلبي كلما رأيت اجتهادك.', 'HI': 'तुम्हारी मेहनत देखकर हर बार दिल गर्मजोशी से भर जाता है।', 'VI': 'Mỗi lần thấy con cố gắng, lòng bố/mẹ lại ấm áp.', 'ES': 'Mi corazón se enternece cada vez que veo tu esfuerzo.', 'TH': 'ทุกครั้งที่เห็นลูกพยายาม หัวใจก็อบอุ่นขึ้นมา'},
  {'KO': '최선을 다하는 너, 이미 충분히 멋져!', 'EN': "Doing your best already makes you amazing!", 'JA': '最善を尽くすあなた、もう十分素敵だよ！', 'ZH': '尽力而为的你，已经很了不起了！', 'FR': "Toi qui fais de ton mieux, tu es déjà formidable !", 'DE': 'Du gibst dein Bestes – das macht dich schon großartig!', 'RU': 'Ты уже прекрасен(на), стараясь изо всех сил!', 'AR': 'أنت رائع بالفعل وأنت تبذل قصارى جهدك!', 'HI': 'अपना सर्वश्रेष्ठ देने वाले तुम पहले से ही शानदार हो!', 'VI': 'Con đã cố hết sức, thế là quá tuyệt rồi!', 'ES': '¡Dar lo mejor de ti ya te hace increíble!', 'TH': 'ลูกที่พยายามอย่างเต็มที่ ก็เจ๋งพอแล้ว!'},
  {'KO': '힘들 때마다 네가 떠올라. 네가 제일 좋아.', 'EN': "I think of you whenever things get tough. I love you the most.", 'JA': 'つらい時はいつもあなたを思うよ。あなたが一番大好き。', 'ZH': '每当辛苦时我都会想起你。你是我的最爱。', 'FR': "Je pense à toi chaque fois que c'est difficile. Je t'aime le plus.", 'DE': 'Wenn es schwer wird, denke ich immer an dich. Ich hab dich am liebsten.', 'RU': 'Каждый раз, когда трудно, я думаю о тебе. Ты для меня самый(ая) дорогой(ая).', 'AR': 'أفكر فيك كلما صعبت الأمور. أنت أغلى ما لدي.', 'HI': 'जब भी मुश्किल होती है, तुम याद आते हो। मुझे तुमसे सबसे ज़्यादा प्यार है।', 'VI': 'Mỗi khi khó khăn, bố/mẹ lại nghĩ đến con. Con là người bố/mẹ yêu nhất.', 'ES': 'Pienso en ti cada vez que las cosas se ponen difíciles. Te quiero más que a nada.', 'TH': 'ทุกครั้งที่เหนื่อย ก็นึกถึงลูก ลูกคือคนที่รักที่สุด'},
  {'KO': '작은 노력이 큰 꿈을 만들어. 항상 응원해!', 'EN': "Small efforts build big dreams. Always cheering for you!", 'JA': '小さな努力が大きな夢を作るよ。いつも応援してる！', 'ZH': '微小的努力铸就伟大的梦想。永远支持你！', 'FR': "Les petits efforts construisent de grands rêves. Toujours à tes côtés !", 'DE': 'Kleine Bemühungen erschaffen große Träume. Ich stehe immer hinter dir!', 'RU': 'Маленькие усилия создают большие мечты. Всегда болею за тебя!', 'AR': 'الجهود الصغيرة تبني أحلامًا كبيرة. أنا أدعمك دائمًا!', 'HI': 'छोटी मेहनत बड़े सपने बनाती है। हमेशा तुम्हारे साथ हूं!', 'VI': 'Những nỗ lực nhỏ tạo nên ước mơ lớn. Luôn cổ vũ con!', 'ES': 'Los pequeños esfuerzos construyen grandes sueños. ¡Siempre apoyándote!', 'TH': 'ความพยายามเล็กๆ สร้างความฝันที่ยิ่งใหญ่ เป็นกำลังใจให้เสมอนะ!'},
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
  // 🆕 [실데이터 연동] "현재 진행 중"을 실제로 감지할 방법이 없어(부모 화면은 별도 프로세스이므로),
  // 가장 최근 학습 세션 정보로 대체 표시합니다. 값이 없으면 lastSessionSubject가 null입니다.
  final String? lastSessionSubject;
  final int lastSessionDurationMinutes;
  final int totalCollectedStars;
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
    required this.childName,
    required this.lastSessionSubject,
    required this.lastSessionDurationMinutes,
    required this.totalCollectedStars,
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
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: widget.premiumCardBg,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: widget.brandGolden.withValues(alpha: 0.3), width: 1.2),
            ),
            child: Column(
              children: [
                Text(
                  widget.lastSessionSubject != null
                      ? lastSessionText(widget.childName, widget.lastSessionSubject!)
                      : noSessionYetText(widget.childName),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    color: Colors.white,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.lastSessionSubject != null)
                  Text(
                    focusDurationText(widget.lastSessionDurationMinutes),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansKr(
                      color: widget.brandGolden,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
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
                  _t(kEncourageMsgSectionMap),
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
                Text(
                  _t(kQuickPhrasesHintMap),
                  style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11),
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
                              // 🆕 [다국어] 실제로 자녀에게 전송되는 문구는 현재 선택된 언어로 채워 넣습니다.
                              _customMessageController.text = DkeLang.isForeignSelected ? displayText : koText;
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
                  maxLength: 50,
                  style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13),
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                    return Text(
                      charCounterText(currentLength, maxLength ?? 50),
                      style: GoogleFonts.rajdhani(color: widget.brandGolden, fontSize: 11, fontWeight: FontWeight.bold),
                    );
                  },
                  decoration: InputDecoration(
                    hintText: _t(kMessageHintMap),
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
                    Text(
                      widget.lastSentTimeText.isNotEmpty
                          ? lastSentText(widget.lastSentTimeText)
                          : _t(kWaitingMap),
                      style: GoogleFonts.notoSansKr(color: widget.brandGolden.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.brandGolden,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        _t(kSendBtnMap),
                        style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
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
