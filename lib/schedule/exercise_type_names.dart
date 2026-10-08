// exercise_type_names.dart
//
// 🆕 [2026-10-08] 운동 종목 이름 12개 언어표
// - 한국어(KO): 위 영문(고운바탕 굵게) · 아래 한글(노토산스) → 화면 쪽에서 두 줄로 표시
// - English(EN): 영어만
// - 10개 외국어: 그 나라 말만
// - 사용자가 직접 추가한 종목(표에 없는 id)은 사용자가 적은 이름 그대로 보여줌
// - 'etc'(자유 운동)는 예전에 저장된 이름이 '기타'여도 자유 운동으로 보임

import 'exercise_models.dart';
import 'app_language_service.dart';

const Map<String, Map<String, String>> kExerciseTypeNames = {
  'golf': {'KO': '골프', 'EN': 'Golf', 'JA': 'ゴルフ', 'ZH': '高尔夫', 'FR': 'Golf', 'DE': 'Golf', 'RU': 'Гольф', 'AR': 'الغولف', 'HI': 'गोल्फ़', 'VI': 'Golf', 'ES': 'Golf', 'TH': 'กอล์ฟ'},
  'swimming': {'KO': '수영', 'EN': 'Swimming', 'JA': '水泳', 'ZH': '游泳', 'FR': 'Natation', 'DE': 'Schwimmen', 'RU': 'Плавание', 'AR': 'السباحة', 'HI': 'तैराकी', 'VI': 'Bơi lội', 'ES': 'Natación', 'TH': 'ว่ายน้ำ'},
  'running': {'KO': '러닝', 'EN': 'Running', 'JA': 'ランニング', 'ZH': '跑步', 'FR': 'Course à pied', 'DE': 'Laufen', 'RU': 'Бег', 'AR': 'الجري', 'HI': 'दौड़', 'VI': 'Chạy bộ', 'ES': 'Correr', 'TH': 'วิ่ง'},
  'walking': {'KO': '걷기', 'EN': 'Walking', 'JA': 'ウォーキング', 'ZH': '步行', 'FR': 'Marche', 'DE': 'Gehen', 'RU': 'Ходьба', 'AR': 'المشي', 'HI': 'पैदल चलना', 'VI': 'Đi bộ', 'ES': 'Caminar', 'TH': 'เดิน'},
  'gym': {'KO': '헬스', 'EN': 'Gym', 'JA': 'ジム', 'ZH': '健身', 'FR': 'Musculation', 'DE': 'Fitnessstudio', 'RU': 'Тренажёрный зал', 'AR': 'الصالة الرياضية', 'HI': 'जिम', 'VI': 'Tập gym', 'ES': 'Gimnasio', 'TH': 'ฟิตเนส'},
  'pilates': {'KO': '필라테스', 'EN': 'Pilates', 'JA': 'ピラティス', 'ZH': '普拉提', 'FR': 'Pilates', 'DE': 'Pilates', 'RU': 'Пилатес', 'AR': 'البيلاتس', 'HI': 'पिलाटेस', 'VI': 'Pilates', 'ES': 'Pilates', 'TH': 'พิลาทิส'},
  'yoga': {'KO': '요가', 'EN': 'Yoga', 'JA': 'ヨガ', 'ZH': '瑜伽', 'FR': 'Yoga', 'DE': 'Yoga', 'RU': 'Йога', 'AR': 'اليوغا', 'HI': 'योग', 'VI': 'Yoga', 'ES': 'Yoga', 'TH': 'โยคะ'},
  'hiking': {'KO': '등산', 'EN': 'Hiking', 'JA': '登山', 'ZH': '登山', 'FR': 'Randonnée', 'DE': 'Wandern', 'RU': 'Поход', 'AR': 'التنزه الجبلي', 'HI': 'पर्वतारोहण', 'VI': 'Leo núi', 'ES': 'Senderismo', 'TH': 'เดินป่า'},
  'cycling': {'KO': '자전거', 'EN': 'Cycling', 'JA': 'サイクリング', 'ZH': '骑行', 'FR': 'Cyclisme', 'DE': 'Radfahren', 'RU': 'Велоспорт', 'AR': 'ركوب الدراجات', 'HI': 'साइकिलिंग', 'VI': 'Đạp xe', 'ES': 'Ciclismo', 'TH': 'ปั่นจักรยาน'},
  'tennis': {'KO': '테니스', 'EN': 'Tennis', 'JA': 'テニス', 'ZH': '网球', 'FR': 'Tennis', 'DE': 'Tennis', 'RU': 'Теннис', 'AR': 'التنس', 'HI': 'टेनिस', 'VI': 'Quần vợt', 'ES': 'Tenis', 'TH': 'เทนนิส'},
  'badminton': {'KO': '배드민턴', 'EN': 'Badminton', 'JA': 'バドミントン', 'ZH': '羽毛球', 'FR': 'Badminton', 'DE': 'Badminton', 'RU': 'Бадминтон', 'AR': 'الريشة الطائرة', 'HI': 'बैडमिंटन', 'VI': 'Cầu lông', 'ES': 'Bádminton', 'TH': 'แบดมินตัน'},
  'tabletennis': {'KO': '탁구', 'EN': 'Table Tennis', 'JA': '卓球', 'ZH': '乒乓球', 'FR': 'Tennis de table', 'DE': 'Tischtennis', 'RU': 'Настольный теннис', 'AR': 'تنس الطاولة', 'HI': 'टेबल टेनिस', 'VI': 'Bóng bàn', 'ES': 'Tenis de mesa', 'TH': 'ปิงปอง'},
  'basketball': {'KO': '농구', 'EN': 'Basketball', 'JA': 'バスケットボール', 'ZH': '篮球', 'FR': 'Basket-ball', 'DE': 'Basketball', 'RU': 'Баскетбол', 'AR': 'كرة السلة', 'HI': 'बास्केटबॉल', 'VI': 'Bóng rổ', 'ES': 'Baloncesto', 'TH': 'บาสเกตบอล'},
  'soccer': {'KO': '축구', 'EN': 'Soccer', 'JA': 'サッカー', 'ZH': '足球', 'FR': 'Football', 'DE': 'Fußball', 'RU': 'Футбол', 'AR': 'كرة القدم', 'HI': 'फ़ुटबॉल', 'VI': 'Bóng đá', 'ES': 'Fútbol', 'TH': 'ฟุตบอล'},
  'skiing': {'KO': '스키', 'EN': 'Skiing', 'JA': 'スキー', 'ZH': '滑雪', 'FR': 'Ski', 'DE': 'Skifahren', 'RU': 'Лыжи', 'AR': 'التزلج', 'HI': 'स्कीइंग', 'VI': 'Trượt tuyết', 'ES': 'Esquí', 'TH': 'สกี'},
  'etc': {'KO': '자유 운동', 'EN': 'Free Workout', 'JA': '自由運動', 'ZH': '自由运动', 'FR': 'Entraînement libre', 'DE': 'Freies Training', 'RU': 'Свободная тренировка', 'AR': 'تمرين حر', 'HI': 'फ्री वर्कआउट', 'VI': 'Tập tự do', 'ES': 'Entrenamiento libre', 'TH': 'ออกกำลังกายอิสระ'},
};

/// 지금 고른 언어로 종목 이름 하나 (KO면 한글, EN이면 영어, 외국어면 그 나라 말)
String exerciseLocalName(ExerciseType t) => exerciseNameIn(t.id, t.name, appLanguage.current);

/// 언어를 직접 지정해서 종목 이름 찾기 (표에 없는 종목은 사용자가 적은 이름)
String exerciseNameIn(String id, String fallbackName, String lang) {
  // 한국어는 사용자가 저장해 둔 한글 이름을 그대로 존중 (자유 운동만 예외)
  if (lang == 'KO') return id == 'etc' ? '자유 운동' : fallbackName;
  final Map<String, String>? row = kExerciseTypeNames[id];
  if (row == null) return fallbackName;
  return row[lang] ?? row['EN'] ?? fallbackName;
}

/// BiTitle의 translations 칸에 바로 넣는 10개 외국어 표
Map<String, String>? exerciseTitleTranslations(String id) {
  final Map<String, String>? row = kExerciseTypeNames[id];
  if (row == null) return null;
  return Map<String, String>.fromEntries(row.entries.where((e) => e.key != 'KO' && e.key != 'EN'));
}

/// "세부 기록" 낱말 (today_exercise 화면 아래쪽 제목용)
const Map<String, String> kExerciseDetailsWord = {
  'JA': '詳細記録', 'ZH': '详细记录', 'FR': 'Détails', 'DE': 'Details', 'RU': 'Подробности',
  'AR': 'التفاصيل', 'HI': 'विस्तृत रिकॉर्ड', 'VI': 'Chi tiết', 'ES': 'Detalles', 'TH': 'รายละเอียด',
};

/// "기록을 저장했습니다" 알림 문구
String exerciseSavedMessage(ExerciseType t) {
  final String n = exerciseLocalName(t);
  switch (appLanguage.current) {
    case 'KO': return "'$n' 기록을 저장했습니다.";
    case 'JA': return '「$n」の記録を保存しました。';
    case 'ZH': return '已保存「$n」记录。';
    case 'FR': return 'Séance « $n » enregistrée.';
    case 'DE': return '„$n“ wurde gespeichert.';
    case 'RU': return 'Запись «$n» сохранена.';
    case 'AR': return 'تم حفظ سجل «$n».';
    case 'HI': return '"$n" रिकॉर्ड सहेजा गया।';
    case 'VI': return 'Đã lưu bản ghi "$n".';
    case 'ES': return 'Registro de «$n» guardado.';
    case 'TH': return 'บันทึก "$n" แล้ว';
    default: return '"$n" saved.';
  }
}

/// 요일 짧은 이름 (월~일 순서) — 분석 화면 막대 아래 글자
const Map<String, List<String>> kWeekdayShort = {
  'KO': ['월', '화', '수', '목', '금', '토', '일'],
  'EN': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  'JA': ['月', '火', '水', '木', '金', '土', '日'],
  'ZH': ['一', '二', '三', '四', '五', '六', '日'],
  'FR': ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'],
  'DE': ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'],
  'RU': ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'],
  'AR': ['ن', 'ث', 'ع', 'خ', 'ج', 'س', 'ح'],
  'HI': ['सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'रवि'],
  'VI': ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'],
  'ES': ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'],
  'TH': ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'],
};

List<String> weekdayShortLabels() => kWeekdayShort[appLanguage.current] ?? kWeekdayShort['EN']!;
