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

  // =========================================================================
  // 🆕 [로그인/회원가입 화면(main.dart LoginSignupScreen) 다국어 - 2026-07-29 추가]
  // 원칙: 기본모드(KO 또는 EN 선택 상태) = 한/영 동시 표시, 10개국어 선택 시 = 해당 언어만 단독 표시
  // 🌐 [10개국어 판별 목록] - EntranceScreen과 동일한 기준을 앱 전역에서 재사용할 수 있도록 공개 헬퍼로 제공
  // =========================================================================
  static const List<String> foreignLanguages = [
    'JA', 'ZH', 'FR', 'DE', 'RU', 'AR', 'HI', 'VI', 'ES', 'TH',
  ];
  static bool get isForeignSelected => foreignLanguages.contains(current);

  // --- 로그인 화면 상단 응원 태그라인 (기본모드: KO 줄바꿈 EN) ---
  static const Map<String, String> _loginTaglineMap = {
    'KO': "노력하는 너를 응원하는 별이 되어 줄게",
    'EN': "I'll be the star cheering for your effort",
    'JA': "努力するあなたを応援する星になるよ",
    'ZH': "我愿成为为你的努力加油的星星",
    'FR': "Je serai l'étoile qui encourage tes efforts",
    'DE': "Ich werde der Stern sein, der deine Mühe anfeuert",
    'RU': "Я стану звездой, которая поддерживает твои старания",
    'AR': "سأكون النجمة التي تشجع مجهودك",
    'HI': "मैं तुम्हारी मेहनत का हौसला बढ़ाने वाला सितारा बनूंगा",
    'VI': "Tôi sẽ là ngôi sao cổ vũ cho nỗ lực của bạn",
    'ES': "Seré la estrella que anime tu esfuerzo",
    'TH': "ฉันจะเป็นดาวที่คอยเป็นกำลังใจให้ความพยายามของเธอ",
  };
  static String get loginTagline => isForeignSelected
      ? _t(_loginTaglineMap)
      : "${_loginTaglineMap['KO']}\n${_loginTaglineMap['EN']}";

  // --- 이메일 입력창 힌트 (기본모드: "한글 / English") ---
  static const Map<String, String> _emailHintMap = {
    'KO': "이메일 주소",
    'EN': "Email Address",
    'JA': "メールアドレス",
    'ZH': "电子邮箱",
    'FR': "Adresse e-mail",
    'DE': "E-Mail-Adresse",
    'RU': "Электронная почта",
    'AR': "البريد الإلكتروني",
    'HI': "ईमेल पता",
    'VI': "Địa chỉ email",
    'ES': "Correo electrónico",
    'TH': "ที่อยู่อีเมล",
  };
  static String get emailHint => isForeignSelected
      ? _t(_emailHintMap)
      : "${_emailHintMap['KO']} / ${_emailHintMap['EN']}";

  // --- 비밀번호 입력창 힌트 (기본모드: "한글 / English") ---
  static const Map<String, String> _passwordHintMap = {
    'KO': "비밀번호",
    'EN': "Password",
    'JA': "パスワード",
    'ZH': "密码",
    'FR': "Mot de passe",
    'DE': "Passwort",
    'RU': "Пароль",
    'AR': "كلمة المرور",
    'HI': "पासवर्ड",
    'VI': "Mật khẩu",
    'ES': "Contraseña",
    'TH': "รหัสผ่าน",
  };
  static String get passwordHint => isForeignSelected
      ? _t(_passwordHintMap)
      : "${_passwordHintMap['KO']} / ${_passwordHintMap['EN']}";

  // --- 이메일/패스워드 기억하기 체크박스 문구 (기본모드: "한글 / English") ---
  static const Map<String, String> _rememberMeMap = {
    'KO': "이메일 / 패스워드 기억하기",
    'EN': "Remember Email / Password",
    'JA': "メール / パスワードを記憶する",
    'ZH': "记住邮箱 / 密码",
    'FR': "Se souvenir de l'e-mail / mot de passe",
    'DE': "E-Mail / Passwort merken",
    'RU': "Запомнить email / пароль",
    'AR': "تذكر البريد الإلكتروني / كلمة المرور",
    'HI': "ईमेल / पासवर्ड याद रखें",
    'VI': "Ghi nhớ email / mật khẩu",
    'ES': "Recordar correo / contraseña",
    'TH': "จดจำอีเมล / รหัสผ่าน",
  };
  static String get rememberMe => isForeignSelected
      ? _t(_rememberMeMap)
      : "${_rememberMeMap['KO']} / ${_rememberMeMap['EN']}";

  // --- 회원가입 버튼 (원본 형식 "EN (KO)" 유지) ---
  static const Map<String, String> _createAccountMap = {
    'KO': "회원가입",
    'EN': "CREATE ACCOUNT",
    'JA': "アカウント作成",
    'ZH': "创建账户",
    'FR': "CRÉER UN COMPTE",
    'DE': "KONTO ERSTELLEN",
    'RU': "СОЗДАТЬ АККАУНТ",
    'AR': "إنشاء حساب",
    'HI': "खाता बनाएं",
    'VI': "TẠO TÀI KHOẢN",
    'ES': "CREAR CUENTA",
    'TH': "สร้างบัญชี",
  };
  static String get createAccountBtn => isForeignSelected
      ? _t(_createAccountMap)
      : "${_createAccountMap['EN']} (${_createAccountMap['KO']})";

  // --- 로그인 버튼 (원본 형식 "EN (KO)" 유지) ---
  static const Map<String, String> _signInMap = {
    'KO': "로그인",
    'EN': "SIGN IN",
    'JA': "ログイン",
    'ZH': "登录",
    'FR': "CONNEXION",
    'DE': "ANMELDEN",
    'RU': "ВОЙТИ",
    'AR': "تسجيل الدخول",
    'HI': "साइन इन करें",
    'VI': "ĐĂNG NHẬP",
    'ES': "INICIAR SESIÓN",
    'TH': "เข้าสู่ระบบ",
  };
  static String get signInBtn => isForeignSelected
      ? _t(_signInMap)
      : "${_signInMap['EN']} (${_signInMap['KO']})";

  // --- 로그인 성공 환영 오버레이 문구 (원본 형식 "EN! (KO)" 유지) ---
  static const Map<String, String> _welcomeMap = {
    'KO': "GKE STUDYUP에 들어 오신것을 환영합니다",
    'EN': "Welcome to GKE STUDYUP!",
    'JA': "GKE STUDYUPへようこそ！",
    'ZH': "欢迎来到 GKE STUDYUP！",
    'FR': "Bienvenue sur GKE STUDYUP !",
    'DE': "Willkommen bei GKE STUDYUP!",
    'RU': "Добро пожаловать в GKE STUDYUP!",
    'AR': "مرحبًا بك في GKE STUDYUP!",
    'HI': "GKE STUDYUP में आपका स्वागत है!",
    'VI': "Chào mừng bạn đến với GKE STUDYUP!",
    'ES': "¡Bienvenido a GKE STUDYUP!",
    'TH': "ยินดีต้อนรับสู่ GKE STUDYUP!",
  };
  static String get welcomeOverlay => isForeignSelected
      ? _t(_welcomeMap)
      : "${_welcomeMap['EN']} (${_welcomeMap['KO']})";

  // =========================================================================
  // 🆕 [회원가입/약관동의 화면(signup_screen.dart) 다국어 - 2026-07-29 추가]
  // 원칙: 기본모드(KO 또는 EN 선택 상태) = 한/영 동시 표시, 10개국어 선택 시 = 해당 언어만 단독 표시
  // 아래 맵들은 signup_screen.dart 화면 파일에서 직접 참조하여 위젯을 구성합니다
  // (헤딩/버튼처럼 폰트가 EN·KO 서로 다르게 적용되는 요소는 화면 파일에서 map['EN']/map['KO']를 직접 꺼내 씁니다.)
  // =========================================================================

  static const Map<String, String> signupHeadingMap = {
    'KO': "회원가입", 'EN': "SIGNUP",
    'JA': "サインアップ", 'ZH': "注册", 'FR': "INSCRIPTION", 'DE': "REGISTRIERUNG",
    'RU': "РЕГИСТРАЦИЯ", 'AR': "التسجيل", 'HI': "साइन अप", 'VI': "ĐĂNG KÝ",
    'ES': "REGISTRO", 'TH': "สมัครสมาชิก",
  };

  static const Map<String, String> termsHeadingMap = {
    'KO': "이용약관 동의", 'EN': "TERMS AGREEMENT",
    'JA': "利用規約への同意", 'ZH': "服务条款同意", 'FR': "ACCORD DES CONDITIONS", 'DE': "NUTZUNGSBEDINGUNGEN",
    'RU': "СОГЛАСИЕ С УСЛОВИЯМИ", 'AR': "الموافقة على الشروط", 'HI': "नियम एवं शर्तों की सहमति", 'VI': "ĐỒNG Ý ĐIỀU KHOẢN",
    'ES': "ACEPTACIÓN DE TÉRMINOS", 'TH': "ยอมรับข้อกำหนด",
  };

  static const Map<String, String> toggleStudentMap = {
    'KO': "학생", 'EN': "STUDENT",
    'JA': "生徒", 'ZH': "学生", 'FR': "ÉTUDIANT", 'DE': "SCHÜLER",
    'RU': "УЧЕНИК", 'AR': "طالب", 'HI': "छात्र", 'VI': "HỌC SINH",
    'ES': "ESTUDIANTE", 'TH': "นักเรียน",
  };
  static const Map<String, String> toggleParentMap = {
    'KO': "학부모", 'EN': "PARENT",
    'JA': "保護者", 'ZH': "家长", 'FR': "PARENT", 'DE': "ELTERNTEIL",
    'RU': "РОДИТЕЛЬ", 'AR': "ولي الأمر", 'HI': "अभिभावक", 'VI': "PHỤ HUYNH",
    'ES': "PADRE/MADRE", 'TH': "ผู้ปกครอง",
  };
  static const Map<String, String> toggleGeneralMap = {
    'KO': "일반", 'EN': "GENERAL",
    'JA': "一般", 'ZH': "普通用户", 'FR': "GÉNÉRAL", 'DE': "ALLGEMEIN",
    'RU': "ОБЩИЙ", 'AR': "عام", 'HI': "सामान्य", 'VI': "CHUNG",
    'ES': "GENERAL", 'TH': "ทั่วไป",
  };

  static const Map<String, String> hintNationalityMap = {
    'KO': "국적", 'EN': "Nationality",
    'JA': "国籍", 'ZH': "国籍", 'FR': "Nationalité", 'DE': "Nationalität",
    'RU': "Гражданство", 'AR': "الجنسية", 'HI': "राष्ट्रीयता", 'VI': "Quốc tịch",
    'ES': "Nacionalidad", 'TH': "สัญชาติ",
  };
  static const Map<String, String> hintFullNameMap = {
    'KO': "본인 이름", 'EN': "Full Name",
    'JA': "氏名", 'ZH': "姓名", 'FR': "Nom complet", 'DE': "Vollständiger Name",
    'RU': "Полное имя", 'AR': "الاسم الكامل", 'HI': "पूरा नाम", 'VI': "Họ và tên",
    'ES': "Nombre completo", 'TH': "ชื่อ-นามสกุล",
  };
  static const Map<String, String> hintBirthDateMap = {
    'KO': "생년월일", 'EN': "Date of Birth",
    'JA': "生年月日", 'ZH': "出生日期", 'FR': "Date de naissance", 'DE': "Geburtsdatum",
    'RU': "Дата рождения", 'AR': "تاريخ الميلاد", 'HI': "जन्म तिथि", 'VI': "Ngày sinh",
    'ES': "Fecha de nacimiento", 'TH': "วันเกิด",
  };
  static const Map<String, String> hintEmailMap = {
    'KO': "이메일 주소", 'EN': "Email Address",
    'JA': "メールアドレス", 'ZH': "电子邮箱", 'FR': "Adresse e-mail", 'DE': "E-Mail-Adresse",
    'RU': "Электронная почта", 'AR': "البريد الإلكتروني", 'HI': "ईमेल पता", 'VI': "Địa chỉ email",
    'ES': "Correo electrónico", 'TH': "ที่อยู่อีเมล",
  };
  static const Map<String, String> hintEmailAuthCodeMap = {
    'KO': "인증번호 6자리 입력", 'EN': "Verification Code",
    'JA': "認証番号（6桁を入力）", 'ZH': "验证码（请输入6位数字）", 'FR': "Code de vérification (6 chiffres)", 'DE': "Bestätigungscode (6-stellig)",
    'RU': "Код подтверждения (6 цифр)", 'AR': "رمز التحقق (6 أرقام)", 'HI': "सत्यापन कोड (6 अंक दर्ज करें)", 'VI': "Mã xác minh (nhập 6 số)",
    'ES': "Código de verificación (6 dígitos)", 'TH': "รหัสยืนยัน (กรอก 6 หลัก)",
  };
  static const Map<String, String> hintPhoneMap = {
    'KO': "전화번호", 'EN': "Phone Number",
    'JA': "電話番号", 'ZH': "电话号码", 'FR': "Numéro de téléphone", 'DE': "Telefonnummer",
    'RU': "Номер телефона", 'AR': "رقم الهاتف", 'HI': "फ़ोन नंबर", 'VI': "Số điện thoại",
    'ES': "Número de teléfono", 'TH': "หมายเลขโทรศัพท์",
  };
  static const Map<String, String> hintPasswordMap = {
    'KO': "비밀번호", 'EN': "Password",
    'JA': "パスワード", 'ZH': "密码", 'FR': "Mot de passe", 'DE': "Passwort",
    'RU': "Пароль", 'AR': "كلمة المرور", 'HI': "पासवर्ड", 'VI': "Mật khẩu",
    'ES': "Contraseña", 'TH': "รหัสผ่าน",
  };
  static const Map<String, String> hintConfirmPasswordMap = {
    'KO': "비밀번호 확인", 'EN': "Confirm Password",
    'JA': "パスワード確認", 'ZH': "确认密码", 'FR': "Confirmer le mot de passe", 'DE': "Passwort bestätigen",
    'RU': "Подтвердите пароль", 'AR': "تأكيد كلمة المرور", 'HI': "पासवर्ड की पुष्टि करें", 'VI': "Xác nhận mật khẩu",
    'ES': "Confirmar contraseña", 'TH': "ยืนยันรหัสผ่าน",
  };
  static const Map<String, String> hintSchoolMap = {
    'KO': "학교명", 'EN': "School Name",
    'JA': "学校名", 'ZH': "学校名称", 'FR': "Nom de l'école", 'DE': "Schulname",
    'RU': "Название школы", 'AR': "اسم المدرسة", 'HI': "स्कूल का नाम", 'VI': "Tên trường",
    'ES': "Nombre de la escuela", 'TH': "ชื่อโรงเรียน",
  };
  static const Map<String, String> hintGradeMap = {
    'KO': "학년", 'EN': "Grade",
    'JA': "学年", 'ZH': "年级", 'FR': "Niveau scolaire", 'DE': "Klassenstufe",
    'RU': "Класс", 'AR': "الصف الدراسي", 'HI': "कक्षा", 'VI': "Lớp",
    'ES': "Grado escolar", 'TH': "ระดับชั้น",
  };
  static const Map<String, String> hintClassCodeMap = {
    'KO': "클래스 코드 - 선택입력", 'EN': "Class Code (optional)",
    'JA': "クラスコード（任意）", 'ZH': "班级代码（选填）", 'FR': "Code de classe (facultatif)", 'DE': "Klassencode (optional)",
    'RU': "Код класса (необязательно)", 'AR': "رمز الفصل (اختياري)", 'HI': "कक्षा कोड (वैकल्पिक)", 'VI': "Mã lớp (không bắt buộc)",
    'ES': "Código de clase (opcional)", 'TH': "รหัสห้องเรียน (ไม่บังคับ)",
  };
  static const Map<String, String> hintChildEmailMap = {
    'KO': "연동할 자녀 이메일 주소", 'EN': "Child's Email",
    'JA': "お子様のメールアドレス", 'ZH': "孩子的电子邮箱", 'FR': "E-mail de l'enfant", 'DE': "E-Mail des Kindes",
    'RU': "Email ребёнка", 'AR': "البريد الإلكتروني للطفل", 'HI': "बच्चे का ईमेल", 'VI': "Email của con",
    'ES': "Correo del hijo/a", 'TH': "อีเมลของบุตรหลาน",
  };
  static const Map<String, String> hintRelationshipMap = {
    'KO': "자녀와의 관계 - 예: 부/모", 'EN': "Relationship to Child",
    'JA': "お子様との関係（例：父/母）", 'ZH': "与孩子的关系（例：父/母）", 'FR': "Lien de parenté (ex. Père/Mère)", 'DE': "Verwandtschaft zum Kind (z. B. Vater/Mutter)",
    'RU': "Родство с ребёнком (напр. отец/мать)", 'AR': "صلة القرابة بالطفل (مثال: أب/أم)", 'HI': "बच्चे से संबंध (जैसे: पिता/माता)", 'VI': "Quan hệ với con (VD: Bố/Mẹ)",
    'ES': "Relación con el hijo/a (ej. Padre/Madre)", 'TH': "ความสัมพันธ์กับบุตรหลาน (เช่น พ่อ/แม่)",
  };
  static const Map<String, String> hintParentEmailMap = {
    'KO': "보호자 이메일", 'EN': "Parent's Email",
    'JA': "保護者のメールアドレス", 'ZH': "监护人电子邮箱", 'FR': "E-mail du parent", 'DE': "E-Mail des Elternteils",
    'RU': "Email родителя", 'AR': "البريد الإلكتروني لولي الأمر", 'HI': "अभिभावक का ईमेल", 'VI': "Email phụ huynh",
    'ES': "Correo del padre/madre", 'TH': "อีเมลผู้ปกครอง",
  };
  static const Map<String, String> hintParentPhoneMap = {
    'KO': "보호자 전화번호", 'EN': "Parent's Phone Number",
    'JA': "保護者の電話番号", 'ZH': "监护人电话号码", 'FR': "Téléphone du parent", 'DE': "Telefonnummer des Elternteils",
    'RU': "Телефон родителя", 'AR': "رقم هاتف ولي الأمر", 'HI': "अभिभावक का फ़ोन नंबर", 'VI': "Số điện thoại phụ huynh",
    'ES': "Teléfono del padre/madre", 'TH': "เบอร์โทรศัพท์ผู้ปกครอง",
  };
  static const Map<String, String> hintParentAuthCodeMap = {
    'KO': "인증번호 입력", 'EN': "Verification Code",
    'JA': "認証番号を入力", 'ZH': "请输入验证码", 'FR': "Code de vérification", 'DE': "Bestätigungscode eingeben",
    'RU': "Введите код подтверждения", 'AR': "أدخل رمز التحقق", 'HI': "सत्यापन कोड दर्ज करें", 'VI': "Nhập mã xác minh",
    'ES': "Introducir código de verificación", 'TH': "กรอกรหัสยืนยัน",
  };

  static const Map<String, String> btnAuthMap = {
    'KO': "인증", 'EN': "AUTH",
    'JA': "認証", 'ZH': "验证", 'FR': "VÉRIFIER", 'DE': "VERIFIZIEREN",
    'RU': "ПРОВЕРИТЬ", 'AR': "تحقق", 'HI': "सत्यापित करें", 'VI': "XÁC THỰC",
    'ES': "VERIFICAR", 'TH': "ยืนยันตัวตน",
  };
  static const Map<String, String> snackCodeSentMap = {
    'KO': "인증번호가 발송되었습니다!", 'EN': "Verification code sent!",
    'JA': "認証番号が送信されました！", 'ZH': "验证码已发送！", 'FR': "Code de vérification envoyé !", 'DE': "Bestätigungscode wurde gesendet!",
    'RU': "Код подтверждения отправлен!", 'AR': "تم إرسال رمز التحقق!", 'HI': "सत्यापन कोड भेज दिया गया है!", 'VI': "Đã gửi mã xác minh!",
    'ES': "¡Código de verificación enviado!", 'TH': "ส่งรหัสยืนยันแล้ว!",
  };
  static const Map<String, String> bannerUnder14Map = {
    'KO': "입력하신 생년월일 기준 만 14세 미만으로 확인되었습니다.", 'EN': "Under 14 detected based on date of birth.",
    'JA': "生年月日に基づき満14歳未満と確認されました。", 'ZH': "根据出生日期确认为未满14周岁。",
    'FR': "Détecté comme ayant moins de 14 ans selon la date de naissance.", 'DE': "Anhand des Geburtsdatums wurde festgestellt, dass die Person unter 14 Jahre alt ist.",
    'RU': "На основании даты рождения установлено, что пользователю меньше 14 лет.", 'AR': "تم تحديد أن العمر أقل من 14 عامًا بناءً على تاريخ الميلاد.",
    'HI': "जन्म तिथि के आधार पर 14 वर्ष से कम आयु की पुष्टि हुई है।", 'VI': "Đã xác định dưới 14 tuổi dựa trên ngày sinh.",
    'ES': "Se detectó que es menor de 14 años según la fecha de nacimiento.", 'TH': "ตรวจพบว่าอายุต่ำกว่า 14 ปี จากวันเกิดที่กรอก",
  };
  static const Map<String, String> parentalTitleMap = {
    'KO': "보호자 동의 필수", 'EN': "Parental Consent Required",
    'JA': "保護者の同意が必要です", 'ZH': "需要监护人同意", 'FR': "Consentement parental requis", 'DE': "Elterliche Zustimmung erforderlich",
    'RU': "Требуется согласие родителя", 'AR': "موافقة ولي الأمر مطلوبة", 'HI': "अभिभावक की सहमति आवश्यक है", 'VI': "Cần có sự đồng ý của phụ huynh",
    'ES': "Se requiere consentimiento parental", 'TH': "จำเป็นต้องได้รับความยินยอมจากผู้ปกครอง",
  };
  static const Map<String, String> parentalDescMap = {
    'KO': "국제법(COPPA/GDPR) 및 국내 개인정보보호법에 따라, 검증된 보호자의 동의가 확인되어야 가입이 가능합니다.",
    'EN': "In accordance with international regulations (COPPA/GDPR) and Korean law (PIPA), verified parental consent is required.",
    'JA': "国際規定（COPPA/GDPR）および韓国の個人情報保護法に基づき、確認された保護者の同意が必要です。",
    'ZH': "根据国际法规（COPPA/GDPR）及韩国个人信息保护法，须确认监护人同意后方可注册。",
    'FR': "Conformément aux réglementations internationales (COPPA/GDPR) et à la loi coréenne (PIPA), un consentement parental vérifié est requis.",
    'DE': "Gemäß internationalen Vorschriften (COPPA/GDPR) und dem koreanischen Datenschutzgesetz (PIPA) ist eine verifizierte elterliche Zustimmung erforderlich.",
    'RU': "В соответствии с международными нормами (COPPA/GDPR) и корейским законом о защите персональных данных (PIPA) требуется подтверждённое согласие родителя.",
    'AR': "وفقًا للأنظمة الدولية (COPPA/GDPR) والقانون الكوري لحماية البيانات (PIPA)، يجب التحقق من موافقة ولي الأمر.",
    'HI': "अंतरराष्ट्रीय नियमों (COPPA/GDPR) और कोरियाई गोपनीयता कानून (PIPA) के अनुसार, सत्यापित अभिभावक सहमति आवश्यक है।",
    'VI': "Theo quy định quốc tế (COPPA/GDPR) và luật bảo vệ dữ liệu cá nhân Hàn Quốc (PIPA), cần có sự đồng ý đã được xác minh của phụ huynh.",
    'ES': "De acuerdo con las normativas internacionales (COPPA/GDPR) y la ley coreana de protección de datos (PIPA), se requiere el consentimiento parental verificado.",
    'TH': "ตามกฎระเบียบสากล (COPPA/GDPR) และกฎหมายคุ้มครองข้อมูลส่วนบุคคลของเกาหลี (PIPA) จำเป็นต้องมีการยืนยันความยินยอมจากผู้ปกครอง",
  };
  static const Map<String, String> snackParentContactMissingMap = {
    'KO': "보호자 이메일 또는 전화번호를 먼저 입력해 주세요.", 'EN': "Please enter parent email or phone first.",
    'JA': "先に保護者のメールまたは電話番号を入力してください。", 'ZH': "请先输入监护人的电子邮箱或电话号码。",
    'FR': "Veuillez d'abord saisir l'e-mail ou le téléphone du parent.", 'DE': "Bitte geben Sie zuerst die E-Mail oder Telefonnummer des Elternteils ein.",
    'RU': "Пожалуйста, сначала введите email или телефон родителя.", 'AR': "يرجى إدخال البريد الإلكتروني أو رقم هاتف ولي الأمر أولاً.",
    'HI': "कृपया पहले अभिभावक का ईमेल या फ़ोन नंबर दर्ज करें।", 'VI': "Vui lòng nhập email hoặc số điện thoại phụ huynh trước.",
    'ES': "Introduzca primero el correo o teléfono del padre/madre.", 'TH': "กรุณากรอกอีเมลหรือเบอร์โทรศัพท์ผู้ปกครองก่อน",
  };
  static const Map<String, String> snackParentCodeSentMap = {
    'KO': "보호자에게 인증번호가 발송되었습니다!", 'EN': "Verification code sent to parent!",
    'JA': "保護者に認証番号が送信されました！", 'ZH': "验证码已发送给监护人！", 'FR': "Code envoyé au parent !", 'DE': "Bestätigungscode wurde an den Elternteil gesendet!",
    'RU': "Код отправлен родителю!", 'AR': "تم إرسال رمز التحقق إلى ولي الأمر!", 'HI': "अभिभावक को सत्यापन कोड भेज दिया गया!", 'VI': "Đã gửi mã xác minh cho phụ huynh!",
    'ES': "¡Código enviado al padre/madre!", 'TH': "ส่งรหัสยืนยันให้ผู้ปกครองแล้ว!",
  };
  static const Map<String, String> snackInvalidCodeMap = {
    'KO': "올바른 인증번호를 입력해 주세요.", 'EN': "Please enter a valid verification code.",
    'JA': "有効な認証番号を入力してください。", 'ZH': "请输入有效的验证码。", 'FR': "Veuillez saisir un code de vérification valide.", 'DE': "Bitte geben Sie einen gültigen Bestätigungscode ein.",
    'RU': "Введите корректный код подтверждения.", 'AR': "يرجى إدخال رمز تحقق صالح.", 'HI': "कृपया एक मान्य सत्यापन कोड दर्ज करें।", 'VI': "Vui lòng nhập mã xác minh hợp lệ.",
    'ES': "Introduzca un código de verificación válido.", 'TH': "กรุณากรอกรหัสยืนยันที่ถูกต้อง",
  };
  static const Map<String, String> snackParentVerifiedMap = {
    'KO': "보호자 인증이 완료되었습니다!", 'EN': "Parent identity verified!",
    'JA': "保護者の本人確認が完了しました！", 'ZH': "监护人身份验证完成！", 'FR': "Identité du parent vérifiée !", 'DE': "Identität des Elternteils verifiziert!",
    'RU': "Личность родителя подтверждена!", 'AR': "تم التحقق من هوية ولي الأمر!", 'HI': "अभिभावक की पहचान सत्यापित हो गई!", 'VI': "Đã xác minh danh tính phụ huynh!",
    'ES': "¡Identidad del padre/madre verificada!", 'TH': "ยืนยันตัวตนผู้ปกครองเรียบร้อยแล้ว!",
  };
  static const Map<String, String> btnParentVerifiedMap = {
    'KO': "인증완료", 'EN': "VERIFIED",
    'JA': "認証完了", 'ZH': "已验证", 'FR': "VÉRIFIÉ", 'DE': "VERIFIZIERT",
    'RU': "ПРОВЕРЕНО", 'AR': "تم التحقق", 'HI': "सत्यापित", 'VI': "ĐÃ XÁC THỰC",
    'ES': "VERIFICADO", 'TH': "ยืนยันแล้ว",
  };
  static const Map<String, String> btnSendCodeToParentMap = {
    'KO': "보호자에게 인증번호 발송", 'EN': "SEND CODE TO PARENT",
    'JA': "保護者に認証番号を送信", 'ZH': "向监护人发送验证码", 'FR': "ENVOYER LE CODE AU PARENT", 'DE': "CODE AN ELTERNTEIL SENDEN",
    'RU': "ОТПРАВИТЬ КОД РОДИТЕЛЮ", 'AR': "إرسال الرمز إلى ولي الأمر", 'HI': "अभिभावक को कोड भेजें", 'VI': "GỬI MÃ CHO PHỤ HUYNH",
    'ES': "ENVIAR CÓDIGO AL PADRE/MADRE", 'TH': "ส่งรหัสให้ผู้ปกครอง",
  };
  static const Map<String, String> btnVerifyMap = {
    'KO': "확인", 'EN': "VERIFY",
    'JA': "確認", 'ZH': "确认", 'FR': "VÉRIFIER", 'DE': "BESTÄTIGEN",
    'RU': "ПОДТВЕРДИТЬ", 'AR': "تأكيد", 'HI': "पुष्टि करें", 'VI': "XÁC NHẬN",
    'ES': "CONFIRMAR", 'TH': "ยืนยัน",
  };
  static const Map<String, String> checkboxParentConsentMap = {
    'KO': "보호자 인증이 완료되었음을 확인했습니다.", 'EN': "I confirm parental consent has been verified.",
    'JA': "保護者の認証が完了したことを確認しました。", 'ZH': "已确认监护人认证完成。",
    'FR': "Je confirme que le consentement parental a été vérifié.", 'DE': "Ich bestätige, dass die elterliche Zustimmung verifiziert wurde.",
    'RU': "Я подтверждаю, что согласие родителя было подтверждено.", 'AR': "أؤكد أنه تم التحقق من موافقة ولي الأمر.",
    'HI': "मैं पुष्टि करता/करती हूँ कि अभिभावक की सहमति सत्यापित हो चुकी है।", 'VI': "Tôi xác nhận sự đồng ý của phụ huynh đã được xác minh.",
    'ES': "Confirmo que el consentimiento parental ha sido verificado.", 'TH': "ฉันยืนยันว่าความยินยอมจากผู้ปกครองได้รับการตรวจสอบแล้ว",
  };
  static const Map<String, String> btnNextStepMap = {
    'KO': "다음 단계로", 'EN': "NEXT STEP",
    'JA': "次のステップへ", 'ZH': "下一步", 'FR': "ÉTAPE SUIVANTE", 'DE': "NÄCHSTER SCHRITT",
    'RU': "СЛЕДУЮЩИЙ ШАГ", 'AR': "الخطوة التالية", 'HI': "अगला चरण", 'VI': "BƯỚC TIẾP THEO",
    'ES': "SIGUIENTE PASO", 'TH': "ขั้นตอนถัดไป",
  };
  static const Map<String, String> hintNeedBirthDateMap = {
    'KO': "계속하려면 생년월일을 입력해 주세요.", 'EN': "Please enter your date of birth to continue.",
    'JA': "続けるには生年月日を入力してください。", 'ZH': "请输入出生日期以继续。", 'FR': "Veuillez saisir votre date de naissance pour continuer.", 'DE': "Bitte geben Sie Ihr Geburtsdatum ein, um fortzufahren.",
    'RU': "Введите дату рождения, чтобы продолжить.", 'AR': "يرجى إدخال تاريخ الميلاد للمتابعة.", 'HI': "जारी रखने के लिए कृपया अपनी जन्म तिथि दर्ज करें।", 'VI': "Vui lòng nhập ngày sinh để tiếp tục.",
    'ES': "Introduzca su fecha de nacimiento para continuar.", 'TH': "กรุณากรอกวันเกิดเพื่อดำเนินการต่อ",
  };
  static const Map<String, String> hintNeedParentVerifyMap = {
    'KO': "계속하려면 보호자 인증이 필요합니다.", 'EN': "Parental verification required to continue.",
    'JA': "続けるには保護者の認証が必要です。", 'ZH': "需完成监护人验证才能继续。", 'FR': "Une vérification parentale est requise pour continuer.", 'DE': "Zum Fortfahren ist eine elterliche Verifizierung erforderlich.",
    'RU': "Для продолжения требуется подтверждение родителя.", 'AR': "التحقق من ولي الأمر مطلوب للمتابعة.", 'HI': "जारी रखने के लिए अभिभावक सत्यापन आवश्यक है।", 'VI': "Cần xác minh phụ huynh để tiếp tục.",
    'ES': "Se requiere verificación parental para continuar.", 'TH': "จำเป็นต้องยืนยันตัวตนผู้ปกครองเพื่อดำเนินการต่อ",
  };
  static const Map<String, String> btnParentLoginTempMap = {
    'KO': "학부모 대시보드 진입 (임시)", 'EN': "PARENT LOGIN (Temporary)",
    'JA': "保護者ログイン（仮）", 'ZH': "家长登录（临时）", 'FR': "CONNEXION PARENT (temporaire)", 'DE': "ELTERN-LOGIN (temporär)",
    'RU': "ВХОД РОДИТЕЛЯ (временно)", 'AR': "دخول ولي الأمر (مؤقت)", 'HI': "अभिभावक लॉगिन (अस्थायी)", 'VI': "ĐĂNG NHẬP PHỤ HUYNH (tạm thời)",
    'ES': "ACCESO PADRE/MADRE (temporal)", 'TH': "เข้าสู่ระบบผู้ปกครอง (ชั่วคราว)",
  };

  // --- 약관동의 화면(TermsAgreementScreen) ---
  static const Map<String, String> termsIntroMap = {
    'KO': "GKE STUDYUP 서비스 이용을 위해 약관을 읽고 동의해 주세요.", 'EN': "Please read and agree to the terms to use GKE STUDYUP.",
    'JA': "GKE STUDYUPをご利用いただくには、規約をお読みの上、同意してください。", 'ZH': "为使用GKE STUDYUP服务，请阅读并同意以下条款。",
    'FR': "Veuillez lire et accepter les conditions pour utiliser GKE STUDYUP.", 'DE': "Bitte lesen Sie die Bedingungen und stimmen Sie ihnen zu, um GKE STUDYUP zu nutzen.",
    'RU': "Пожалуйста, ознакомьтесь с условиями и примите их для использования GKE STUDYUP.", 'AR': "يرجى قراءة الشروط والموافقة عليها لاستخدام GKE STUDYUP.",
    'HI': "GKE STUDYUP का उपयोग करने के लिए कृपया शर्तें पढ़ें और सहमति दें।", 'VI': "Vui lòng đọc và đồng ý với điều khoản để sử dụng GKE STUDYUP.",
    'ES': "Lea y acepte los términos para usar GKE STUDYUP.", 'TH': "โปรดอ่านและยอมรับข้อกำหนดเพื่อใช้งาน GKE STUDYUP",
  };

  static const Map<String, String> terms1TitleMap = {
    'KO': "1. 목적", 'EN': "1. Purpose",
    'JA': "1. 目的", 'ZH': "1. 目的", 'FR': "1. Objet", 'DE': "1. Zweck",
    'RU': "1. Цель", 'AR': "1. الغرض", 'HI': "1. उद्देश्य", 'VI': "1. Mục đích",
    'ES': "1. Propósito", 'TH': "1. วัตถุประสงค์",
  };
  static const Map<String, String> terms1BodyMap = {
    'KO': "본 약관은 GKE STUDYUP 서비스의 이용 조건 및 절차를 규정합니다.",
    'EN': "This agreement outlines the terms and procedures for using GKE STUDYUP services.",
    'JA': "本規約はGKE STUDYUPサービスの利用条件および手続きを定めるものです。",
    'ZH': "本协议规定了使用GKE STUDYUP服务的条款和程序。",
    'FR': "Cet accord définit les conditions et procédures d'utilisation des services GKE STUDYUP.",
    'DE': "Diese Vereinbarung legt die Bedingungen und Verfahren für die Nutzung der GKE STUDYUP-Dienste fest.",
    'RU': "Настоящее соглашение устанавливает условия и порядок использования сервисов GKE STUDYUP.",
    'AR': "توضح هذه الاتفاقية شروط وإجراءات استخدام خدمات GKE STUDYUP.",
    'HI': "यह समझौता GKE STUDYUP सेवाओं के उपयोग की शर्तों और प्रक्रियाओं को रेखांकित करता है।",
    'VI': "Thỏa thuận này quy định các điều khoản và quy trình sử dụng dịch vụ GKE STUDYUP.",
    'ES': "Este acuerdo describe los términos y procedimientos para usar los servicios de GKE STUDYUP.",
    'TH': "ข้อตกลงนี้ระบุเงื่อนไขและขั้นตอนการใช้บริการ GKE STUDYUP",
  };

  static const Map<String, String> terms2TitleMap = {
    'KO': "2. 국제법 준수", 'EN': "2. International Law Compliance",
    'JA': "2. 国際法の遵守", 'ZH': "2. 国际法合规", 'FR': "2. Conformité aux lois internationales", 'DE': "2. Einhaltung internationaler Gesetze",
    'RU': "2. Соответствие международному законодательству", 'AR': "2. الامتثال للقوانين الدولية", 'HI': "2. अंतरराष्ट्रीय कानून अनुपालन", 'VI': "2. Tuân thủ luật pháp quốc tế",
    'ES': "2. Cumplimiento de leyes internacionales", 'TH': "2. การปฏิบัติตามกฎหมายสากล",
  };
  static const Map<String, String> terms2BodyMap = {
    'KO': "본 서비스는 유럽 GDPR 및 미국 COPPA 규정을 준수하며, 14세 미만 아동의 데이터 보호를 위해 법정대리인의 동의를 필수적으로 수집합니다.",
    'EN': "This service strictly complies with EU GDPR and US COPPA. Parental consent is mandatory for collecting data of users under 14.",
    'JA': "本サービスはEUのGDPRおよび米国のCOPPAを厳格に遵守しています。14歳未満の利用者のデータ収集には保護者の同意が必須です。",
    'ZH': "本服务严格遵守欧盟GDPR和美国COPPA法规。收集未满14周岁用户的数据必须获得监护人同意。",
    'FR': "Ce service respecte strictement le RGPD de l'UE et le COPPA des États-Unis. Le consentement parental est obligatoire pour la collecte de données des utilisateurs de moins de 14 ans.",
    'DE': "Dieser Dienst hält sich strikt an die EU-DSGVO und den US-amerikanischen COPPA. Für die Datenerhebung bei Nutzern unter 14 Jahren ist eine elterliche Zustimmung zwingend erforderlich.",
    'RU': "Данный сервис строго соблюдает европейский GDPR и американский COPPA. Согласие родителя обязательно для сбора данных пользователей младше 14 лет.",
    'AR': "تلتزم هذه الخدمة بصرامة بلائحة GDPR الأوروبية وقانون COPPA الأمريكي. موافقة ولي الأمر إلزامية لجمع بيانات المستخدمين دون سن 14 عامًا.",
    'HI': "यह सेवा यूरोपीय GDPR और अमेरिकी COPPA का सख्ती से पालन करती है। 14 वर्ष से कम आयु के उपयोगकर्ताओं का डेटा एकत्र करने के लिए अभिभावक की सहमति अनिवार्य है।",
    'VI': "Dịch vụ này tuân thủ nghiêm ngặt GDPR của EU và COPPA của Hoa Kỳ. Việc thu thập dữ liệu của người dùng dưới 14 tuổi bắt buộc phải có sự đồng ý của phụ huynh.",
    'ES': "Este servicio cumple estrictamente con el RGPD de la UE y la COPPA de EE. UU. El consentimiento parental es obligatorio para recopilar datos de usuarios menores de 14 años.",
    'TH': "บริการนี้ปฏิบัติตาม GDPR ของสหภาพยุโรปและ COPPA ของสหรัฐอเมริกาอย่างเคร่งครัด จำเป็นต้องได้รับความยินยอมจากผู้ปกครองสำหรับการเก็บข้อมูลผู้ใช้ที่อายุต่ำกว่า 14 ปี",
  };

  static const Map<String, String> terms3TitleMap = {
    'KO': "3. 수집 항목", 'EN': "3. Data Collection Items",
    'JA': "3. 収集項目", 'ZH': "3. 收集项目", 'FR': "3. Données collectées", 'DE': "3. Erhobene Daten",
    'RU': "3. Собираемые данные", 'AR': "3. عناصر جمع البيانات", 'HI': "3. डेटा संग्रहण आइटम", 'VI': "3. Các mục dữ liệu thu thập",
    'ES': "3. Datos recopilados", 'TH': "3. ข้อมูลที่จัดเก็บ",
  };
  static const Map<String, String> terms3BodyMap = {
    'KO': "국적, 이름, 생년월일, 이메일, 전화번호, 학교, 학년 정보를 수집하며 이는 학습 리포트 제공 목적으로만 사용됩니다.",
    'EN': "Nationality, Full Name, date of birth, email, phone number, school name, and grade are collected solely for personalized study reporting.",
    'JA': "国籍、氏名、生年月日、メールアドレス、電話番号、学校名、学年は、学習レポート提供の目的のみで収集されます。",
    'ZH': "收集国籍、姓名、出生日期、电子邮箱、电话号码、学校名称及年级信息，仅用于提供个性化学习报告。",
    'FR': "La nationalité, le nom complet, la date de naissance, l'e-mail, le numéro de téléphone, le nom de l'école et le niveau scolaire sont collectés uniquement à des fins de rapport d'étude personnalisé.",
    'DE': "Nationalität, vollständiger Name, Geburtsdatum, E-Mail, Telefonnummer, Schulname und Klassenstufe werden ausschließlich zum Zweck personalisierter Lernberichte erhoben.",
    'RU': "Гражданство, полное имя, дата рождения, email, номер телефона, название школы и класс собираются исключительно для составления персонализированных отчётов об обучении.",
    'AR': "يتم جمع الجنسية والاسم الكامل وتاريخ الميلاد والبريد الإلكتروني ورقم الهاتف واسم المدرسة والصف الدراسي فقط لغرض تقديم تقارير دراسية مخصصة.",
    'HI': "राष्ट्रीयता, पूरा नाम, जन्म तिथि, ईमेल, फ़ोन नंबर, स्कूल का नाम और कक्षा केवल व्यक्तिगत अध्ययन रिपोर्ट प्रदान करने के उद्देश्य से एकत्र किए जाते हैं।",
    'VI': "Quốc tịch, họ tên, ngày sinh, email, số điện thoại, tên trường và lớp được thu thập chỉ nhằm mục đích cung cấp báo cáo học tập cá nhân hóa.",
    'ES': "La nacionalidad, el nombre completo, la fecha de nacimiento, el correo electrónico, el teléfono, el nombre de la escuela y el grado se recopilan únicamente con fines de informes de estudio personalizados.",
    'TH': "สัญชาติ ชื่อ-นามสกุล วันเกิด อีเมล เบอร์โทรศัพท์ ชื่อโรงเรียน และระดับชั้น จะถูกเก็บรวบรวมเพื่อวัตถุประสงค์ในการรายงานผลการเรียนส่วนบุคคลเท่านั้น",
  };

  static const Map<String, String> terms4TitleMap = {
    'KO': "4. 데이터 보안", 'EN': "4. Data Security & Rights",
    'JA': "4. データセキュリティと権利", 'ZH': "4. 数据安全与权利", 'FR': "4. Sécurité des données et droits", 'DE': "4. Datensicherheit & Rechte",
    'RU': "4. Безопасность данных и права", 'AR': "4. أمن البيانات والحقوق", 'HI': "4. डेटा सुरक्षा और अधिकार", 'VI': "4. Bảo mật dữ liệu & Quyền lợi",
    'ES': "4. Seguridad de datos y derechos", 'TH': "4. ความปลอดภัยของข้อมูลและสิทธิ์",
  };
  static const Map<String, String> terms4BodyMap = {
    'KO': "모든 정보는 암호화되어 안전하게 관리되며, 사용자는 언제든 삭제를 요청할 수 있습니다.",
    'EN': "All information is securely encrypted (AES-256) and users retain the right to request deletion at any time.",
    'JA': "すべての情報はAES-256により安全に暗号化され、利用者はいつでも削除を要求する権利を有します。",
    'ZH': "所有信息均通过AES-256加密安全保存，用户可随时要求删除数据。",
    'FR': "Toutes les informations sont sécurisées par un cryptage AES-256 et les utilisateurs conservent le droit de demander leur suppression à tout moment.",
    'DE': "Alle Informationen werden sicher mit AES-256 verschlüsselt, und Nutzer behalten das Recht, jederzeit die Löschung zu verlangen.",
    'RU': "Вся информация надёжно зашифрована (AES-256), и пользователи сохраняют право запросить удаление в любое время.",
    'AR': "يتم تشفير جميع المعلومات بأمان باستخدام AES-256، ويحتفظ المستخدمون بالحق في طلب الحذف في أي وقت.",
    'HI': "सभी जानकारी AES-256 द्वारा सुरक्षित रूप से एन्क्रिप्ट की जाती है, और उपयोगकर्ता किसी भी समय हटाने का अनुरोध करने का अधिकार रखते हैं।",
    'VI': "Mọi thông tin đều được mã hóa an toàn bằng AES-256 và người dùng có quyền yêu cầu xóa dữ liệu bất cứ lúc nào.",
    'ES': "Toda la información está protegida con cifrado AES-256 y los usuarios conservan el derecho de solicitar su eliminación en cualquier momento.",
    'TH': "ข้อมูลทั้งหมดได้รับการเข้ารหัสอย่างปลอดภัยด้วย AES-256 และผู้ใช้มีสิทธิ์ขอให้ลบข้อมูลได้ตลอดเวลา",
  };

  static const Map<String, String> checkboxAgreeAllMap = {
    'KO': "위 약관의 내용을 모두 읽었으며 동의합니다.", 'EN': "I have read and agree to all terms above.",
    'JA': "上記のすべての規約を読み、同意します。", 'ZH': "本人已阅读并同意以上所有条款。",
    'FR': "J'ai lu et j'accepte tous les termes ci-dessus.", 'DE': "Ich habe alle oben genannten Bedingungen gelesen und stimme ihnen zu.",
    'RU': "Я прочитал(а) и принимаю все указанные выше условия.", 'AR': "لقد قرأت ووافقت على جميع الشروط أعلاه.",
    'HI': "मैंने ऊपर दी गई सभी शर्तें पढ़ ली हैं और सहमत हूं।", 'VI': "Tôi đã đọc và đồng ý với tất cả các điều khoản trên.",
    'ES': "He leído y acepto todos los términos anteriores.", 'TH': "ฉันได้อ่านและยอมรับข้อกำหนดทั้งหมดข้างต้น",
  };
  static const Map<String, String> btnSignupCompleteMap = {
    'KO': "가입 완료", 'EN': "SIGNUP COMPLETE",
    'JA': "登録完了", 'ZH': "注册完成", 'FR': "INSCRIPTION TERMINÉE", 'DE': "REGISTRIERUNG ABGESCHLOSSEN",
    'RU': "РЕГИСТРАЦИЯ ЗАВЕРШЕНА", 'AR': "اكتمل التسجيل", 'HI': "पंजीकरण पूर्ण", 'VI': "HOÀN TẤT ĐĂNG KÝ",
    'ES': "REGISTRO COMPLETADO", 'TH': "สมัครสมาชิกสำเร็จ",
  };
  static const Map<String, String> snackRegistrationCompleteMap = {
    'KO': "회원가입이 완료되었습니다!", 'EN': "Registration Complete!",
    'JA': "登録が完了しました！", 'ZH': "注册成功！", 'FR': "Inscription terminée !", 'DE': "Registrierung abgeschlossen!",
    'RU': "Регистрация завершена!", 'AR': "اكتمل التسجيل!", 'HI': "पंजीकरण पूर्ण हुआ!", 'VI': "Đăng ký hoàn tất!",
    'ES': "¡Registro completado!", 'TH': "สมัครสมาชิกสำเร็จแล้ว!",
  };
}
