import 'package:shared_preferences/shared_preferences.dart';

class DkeLang {
  // 👑 [DKE 언어 중앙 제어 스위치]: 기본값은 한국어('KO')
  // 🌐 [12개국 확장]: 언어 코드는 항상 대문자로 통일해서 관리합니다.
  //    (마이페이지 등 다른 화면에서 코드를 넘길 때도 setLanguage()를 거치면 자동으로 대문자로 정규화됩니다.)
  static String current = 'KO';

  // 🌐 [12개국 지원 목록]: 여기 목록이 앱 전체에서 지원하는 언어의 기준(Source of Truth)입니다.
  static const List<String> supportedLanguages = [
    'KO', 'EN', 'JA', 'ZH', 'FR', 'DE', 'RU', 'AR', 'HI', 'VI', 'ES', 'TH',
  ];

  // 👑 [국적 데이터 로드 엔진]: 앱이 켜질 때 저장된 언어 정보를 가져옴
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedLang = prefs.getString('user_country');
      if (savedLang != null && savedLang.isNotEmpty) {
        final String normalized = savedLang.toUpperCase();
        current = supportedLanguages.contains(normalized) ? normalized : 'KO';
      }
    } catch (e) {
      current = 'KO'; // 에러 발생 시 한국어 기본 모드로 안전하게 방어
    }
  }

  // 👑 [국적 변경 스위치]: 유저가 언어를 바꿀 때 즉시 기기에 저장
  // 🌐 [12개국 확장]: 소문자로 넘어와도('zh' 등) 대문자로 정규화해서 저장/적용합니다.
  //    지원하지 않는 코드가 들어오면 안전하게 영어(EN)로 대체합니다.
  static Future<void> setLanguage(String langCode) async {
    final String normalized = langCode.toUpperCase();
    current = supportedLanguages.contains(normalized) ? normalized : 'EN';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_country', current);
  }

  // 🌐 아랍어는 오른쪽에서 왼쪽으로 읽는 언어라, 화면 방향(RTL) 판단이 필요한 화면에서 공용으로 사용
  static bool get isRtl => current == 'AR';

  // =========================================================================
  // 🎯 [DKE 언어 매핑 사전] - 12개국 공통 조회 헬퍼
  // 각 문구는 map에 12개 언어를 전부 채워두고, 값이 없으면 EN → KO 순으로 대체합니다.
  // =========================================================================
  static String _t(Map<String, String> map) {
    return map[current] ?? map['EN'] ?? map['KO'] ?? '';
  }

  // 공통 타이틀 및 상단 정보 벨트 (지시하신 글자 크기 23 철칙 적용 구역)
  static String get schoolInfo => _t(const {
    'KO': "GSU고등학교 2학년 이제임스",
    'EN': "GSU High School 2nd Grade - James Lee",
    'JA': "GSU高校2年生 ジェームズ・リー",
    'ZH': "GSU高中二年级 李詹姆斯",
    'FR': "GSU Lycée, 2e année - James Lee",
    'DE': "GSU Gymnasium, 2. Klasse - James Lee",
    'RU': "GSU школа, 2 курс - Джеймс Ли",
    'AR': "جيمس لي - الصف الثاني الثانوي GSU",
    'HI': "GSU हाई स्कूल कक्षा 2 - जेम्स ली",
    'VI': "GSU Cấp 3, lớp 11 - James Lee",
    'ES': "GSU Bachillerato, 2º año - James Lee",
    'TH': "GSU มัธยมปลาย ปีที่ 2 - เจมส์ ลี",
  });

  static String get memberAchievementTitle => _t(const {
    'KO': "동시 접속자",
    'EN': "Simultaneous Users",
    'JA': "同時接続者",
    'ZH': "同时在线人数",
    'FR': "Utilisateurs simultanés",
    'DE': "Gleichzeitige Nutzer",
    'RU': "Одновременные пользователи",
    'AR': "المستخدمون المتزامنون",
    'HI': "समवर्ती उपयोगकर्ता",
    'VI': "Người dùng đang trực tuyến",
    'ES': "Usuarios simultáneos",
    'TH': "ผู้ใช้ที่ออนไลน์พร้อมกัน",
  });

  static String get currentLearnersMsg => _t(const {
    'KO': "(현재도 전국 전 세계 사람들 학습중입니다.)",
    'EN': "(People all over the world are studying right now.)",
    'JA': "(現在も世界中の人々が学習しています。)",
    'ZH': "(现在全世界的人们都在学习。)",
    'FR': "(Des gens du monde entier étudient actuellement.)",
    'DE': "(Menschen auf der ganzen Welt lernen gerade jetzt.)",
    'RU': "(Люди по всему миру сейчас учатся.)",
    'AR': "(يدرس أشخاص حول العالم في هذه اللحظة.)",
    'HI': "(दुनिया भर के लोग अभी भी पढ़ रहे हैं।)",
    'VI': "(Mọi người trên toàn thế giới vẫn đang học tập.)",
    'ES': "(Personas de todo el mundo están estudiando ahora mismo.)",
    'TH': "(ผู้คนทั่วโลกกำลังเรียนอยู่ในขณะนี้)",
  });

  // 팝업 및 알림문구 챕터
  static String get stopLearningAlert => _t(const {
    'KO': "학습을 중단하시겠습니까?",
    'EN': "Are you sure you want to stop learning?",
    'JA': "学習を中断しますか？",
    'ZH': "确定要中断学习吗？",
    'FR': "Voulez-vous vraiment arrêter d'étudier ?",
    'DE': "Möchten Sie das Lernen wirklich beenden?",
    'RU': "Вы уверены, что хотите прервать обучение?",
    'AR': "هل أنت متأكد أنك تريد التوقف عن الدراسة؟",
    'HI': "क्या आप वाकई सीखना बंद करना चाहते हैं?",
    'VI': "Bạn có chắc muốn dừng học không?",
    'ES': "¿Seguro que quieres dejar de estudiar?",
    'TH': "แน่ใจหรือไม่ว่าต้องการหยุดการเรียน?",
  });

  static String get targetAchievedSuccess => _t(const {
    'KO': "수고 하셨습니다. 학습 목표를 성공적으로 달성 하였습니다.",
    'EN': "Good job! You have successfully achieved your learning goals.",
    'JA': "お疲れ様でした。学習目標を達成しました。",
    'ZH': "辛苦了，您已成功达成学习目标。",
    'FR': "Bravo ! Vous avez atteint votre objectif d'apprentissage.",
    'DE': "Gut gemacht! Sie haben Ihr Lernziel erfolgreich erreicht.",
    'RU': "Отличная работа! Вы успешно достигли учебной цели.",
    'AR': "أحسنت! لقد حققت هدفك التعليمي بنجاح.",
    'HI': "बहुत बढ़िया! आपने अपना सीखने का लक्ष्य सफलतापूर्वक हासिल कर लिया है।",
    'VI': "Làm tốt lắm! Bạn đã hoàn thành mục tiêu học tập thành công.",
    'ES': "¡Buen trabajo! Has alcanzado tu objetivo de aprendizaje con éxito.",
    'TH': "เยี่ยมมาก! คุณบรรลุเป้าหมายการเรียนได้สำเร็จแล้ว",
  });
}
