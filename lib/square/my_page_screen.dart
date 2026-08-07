import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../global_lang.dart'; // 👑 [12개국 연동] 전역 언어 스위치와 실제로 연결

class MyPageScreen extends StatefulWidget {
  final bool isVipMember;
  final void Function(bool isVip, String targetUniversity) onSave;

  const MyPageScreen({
    super.key,
    required this.isVipMember,
    required this.onSave,
  });

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  // 🌐 [명칭: 글로벌 12개국 다국어 사전 탑재] - 요구사항: 12개국 언어 지원 스펙 완벽 확장
  // 🆕 코드는 항상 대문자로 통일합니다 (global_lang.dart의 DkeLang.supportedLanguages와 동일 기준).
  //    스페인어(ES), 태국어(TH) 2개 언어를 신규 추가했습니다.
  final List<Map<String, String>> _languages = const [
    {
      'code': 'EN',
      'name': 'English',
      'flag': '🇺🇸',
      'title': 'My Page',
      'target': 'Target School Setting',
      'hint': 'Enter target name',
      'save': 'Save Settings',
      'vip': 'VIP Premium Member',
      'normal': 'Regular Member',
      'personal': 'Personal Info',
      'email': 'Email Address',
      'password': 'Password Update',
      'passwordHint': 'Enter new password',
      'language': 'Global Language',
      'vipLocked': 'Locked for VIP members only',
      'vipButton': 'Apply VIP and set target',
      'vipDone': 'VIP Premium Member Activated',
      'disabledHint': 'Available after VIP approval',
      'saved': 'My Page settings have been saved.',
      'snackVip': 'VIP membership approved. You can now set your target.',
      'defaultSchool': 'Seoul National University',
      'targetWord': 'Target',
      'savePersonalInfo': 'Save Personal Info',
      'savedPersonalInfo': 'Personal info has been saved.',
    },
    {
      'code': 'KO',
      'name': '한국어',
      'flag': '🇰🇷',
      'title': '마이 페이지',
      'target': '목표 학교 설정',
      'hint': '목표명을 입력하세요',
      'save': '설정 저장',
      'vip': 'VIP 프리미엄 회원',
      'normal': '일반 회원',
      'personal': '개인정보 수정',
      'email': '이메일 주소',
      'password': '비밀번호 변경',
      'passwordHint': '새 비밀번호를 입력하세요',
      'language': '다국어 선택',
      'vipLocked': 'VIP 결제 전용 잠김',
      'vipButton': '회원결제(VIP) 신청하고 목표 학교 설정하기',
      'vipDone': 'VIP 프리미엄 회원 활성화 완료',
      'disabledHint': '아래 [회원결제(VIP)] 승인 후 활성화됩니다.',
      'saved': '마이페이지 설정이 저장되었습니다.',
      'snackVip': 'VIP 회원 결제가 승인되었습니다! 이제 목표를 자유롭게 직접 설정할 수 있습니다.',
      'defaultSchool': '서울대학교',
      'targetWord': '목표',
      'savePersonalInfo': '개인정보 저장',
      'savedPersonalInfo': '개인정보가 저장되었습니다.',
    },
    {
      'code': 'JA',
      'name': '日本語',
      'flag': '🇯🇵',
      'title': 'マイページ',
      'target': '目標校設定',
      'hint': '目標名を入力してください',
      'save': '設定保存',
      'vip': 'VIPプレミアム会員',
      'normal': '一般会員',
      'personal': '個人情報の修正',
      'email': 'メールアドレス',
      'password': 'パスワード変更',
      'passwordHint': '新しいパスワードを入力してください',
      'language': '言語選択',
      'vipLocked': 'VIP会員専用ロック',
      'vipButton': 'VIPを申請して目標を設定',
      'vipDone': 'VIPプレミアム会員有効化完了',
      'disabledHint': 'VIP承認後に有効になります。',
      'saved': 'マイページ設定が保存されました。',
      'snackVip': 'VIP会員登録が承認されました。目標を設定できます。',
      'defaultSchool': 'ソウル大学校',
      'targetWord': '目標',
      'savePersonalInfo': '個人情報を保存',
      'savedPersonalInfo': '個人情報が保存されました。',
    },
    {
      'code': 'ZH',
      'name': '简体中文',
      'flag': '🇨🇳',
      'title': '个人中心',
      'target': '目标学校设置',
      'hint': '请输入目标名称',
      'save': '保存设置',
      'vip': 'VIP高级会员',
      'normal': '普通会员',
      'personal': '个人信息修改',
      'email': '电子邮箱',
      'password': '修改密码',
      'passwordHint': '请输入新密码',
      'language': '多语言选择',
      'vipLocked': '仅限VIP会员',
      'vipButton': '申请VIP并设置目标',
      'vipDone': 'VIP高级会员已激活',
      'disabledHint': 'VIP批准后可启用',
      'saved': '个人中心设置已保存。',
      'snackVip': 'VIP会员已批准，现在可以自由设置目标。',
      'defaultSchool': '首尔大学',
      'targetWord': '目标',
      'savePersonalInfo': '保存个人信息',
      'savedPersonalInfo': '个人信息已保存。',
    },
    {
      'code': 'FR',
      'name': 'Français',
      'flag': '🇫🇷',
      'title': 'Ma Page',
      'target': "Réglage de l'école cible",
      'hint': 'Entrez le nom de la cible',
      'save': 'Enregistrer',
      'vip': 'Membre Premium VIP',
      'normal': 'Membre Régulier',
      'personal': 'Modifier les infos',
      'email': 'Adresse e-mail',
      'password': 'Changer le mot de passe',
      'passwordHint': 'Entrez le nouveau mot de passe',
      'language': 'Choix de la langue',
      'vipLocked': 'Verrouillé pour les membres VIP',
      'vipButton': 'Demander un accès VIP et définir la cible',
      'vipDone': 'Membre Premium VIP Activé',
      'disabledHint': 'Disponible après approbation VIP',
      'saved': 'Les paramètres ont été enregistrés.',
      'snackVip': "L'accès VIP a été approuvé. Vous pouvez définir votre cible.",
      'defaultSchool': 'Université Nationale de Séoul',
      'targetWord': 'Cible',
      'savePersonalInfo': 'Enregistrer les infos',
      'savedPersonalInfo': 'Les informations personnelles ont été enregistrées.',
    },
    {
      'code': 'DE',
      'name': 'Deutsch',
      'flag': '🇩🇪',
      'title': 'Meine Seite',
      'target': 'Zielschule einstellen',
      'hint': 'Zielnamen eingeben',
      'save': 'Einstellungen speichern',
      'vip': 'VIP-Premium-Mitglied',
      'normal': 'Reguläres Mitglied',
      'personal': 'Info bearbeiten',
      'email': 'E-Mail-Adresse',
      'password': 'Kennwort ändern',
      'passwordHint': 'Neues Kennwort eingeben',
      'language': 'Sprachauswahl',
      'vipLocked': 'Nur für VIP-Mitglieder gesperrt',
      'vipButton': 'VIP beantragen und Ziel festlegen',
      'vipDone': 'VIP-Premium-Mitglied Aktiviert',
      'disabledHint': 'Verfügbar nach VIP-Genehmigung',
      'saved': 'Einstellungen wurden gespeichert.',
      'snackVip': 'VIP-Mitgliedschaft genehmigt. Sie können nun Ihr Ziel festlegen.',
      'defaultSchool': 'Nationaluniversität Seoul',
      'targetWord': 'Ziel',
      'savePersonalInfo': 'Persönliche Daten speichern',
      'savedPersonalInfo': 'Persönliche Daten wurden gespeichert.',
    },
    {
      'code': 'RU',
      'name': 'Русский',
      'flag': '🇷🇺',
      'title': 'Моя страница',
      'target': 'Настройка целевой школы',
      'hint': 'Введите название цели',
      'save': 'Сохранить настройки',
      'vip': 'VIP Премиум Участник',
      'normal': 'Обычный Участник',
      'personal': 'Изменить инфо',
      'email': 'E-mail адрес',
      'password': 'Сменить пароль',
      'passwordHint': 'Введите новый пароль',
      'language': 'Выбор языка',
      'vipLocked': 'Заблокировано для VIP',
      'vipButton': 'Подать заявку на VIP и установить цель',
      'vipDone': 'VIP Премиум Участник Активирован',
      'disabledHint': 'Доступно после одобрения VIP',
      'saved': 'Настройки сохранены.',
      'snackVip': 'VIP-членство одобрено. Теперь вы можете установить цель.',
      'defaultSchool': 'Сеульский национальный университет',
      'targetWord': 'Цель',
      'savePersonalInfo': 'Сохранить личные данные',
      'savedPersonalInfo': 'Личные данные сохранены.',
    },
    {
      'code': 'AR',
      'name': 'العربية',
      'flag': '🇸🇦',
      'title': 'صفحتي',
      'target': 'إعداد المدرسة المستهدفة',
      'hint': 'أدخل اسم الهدف',
      'save': 'حفظ الإعدادات',
      'vip': 'عضو VIP ممتاز',
      'normal': 'عضو عادي',
      'personal': 'تعديل البيانات',
      'email': 'البريد الإلكتروني',
      'password': 'تغيير كلمة المرور',
      'passwordHint': 'أدخل كلمة المرور الجديدة',
      'language': 'اختيار اللغة',
      'vipLocked': 'مغلق لأعضاء VIP فقط',
      'vipButton': 'طلب VIP وتحديد الهدف',
      'vipDone': 'تم تفعيل عضوية VIP الممتازة',
      'disabledHint': 'متاح بعد الموافقة على VIP',
      'saved': 'تم حفظ الإعدادات.',
      'snackVip': 'تمت الموافقة على عضوية VIP. يمكنك الآن تحديد هدفك.',
      'defaultSchool': 'جامعة سيول الوطنية',
      'targetWord': 'الهدف',
      'savePersonalInfo': 'حفظ البيانات الشخصية',
      'savedPersonalInfo': 'تم حفظ البيانات الشخصية.',
    },
    {
      'code': 'HI',
      'name': 'हिन्दी',
      'flag': '🇮🇳',
      'title': 'मेरा पृष्ठ',
      'target': 'लक्ष्य विद्यालय सेटिंग',
      'hint': 'लक्ष्य का नाम दर्ज करें',
      'save': 'सेटिंग्स सहेजें',
      'vip': 'वीआईपी प्रीमियम सदस्य',
      'normal': 'सामान्य सदस्य',
      'personal': 'जानकारी बदलें',
      'email': 'ईमेल पता',
      'password': 'पासवर्ड बदलें',
      'passwordHint': 'नया पासवर्ड दर्ज करें',
      'language': 'भाषा चयन',
      'vipLocked': 'केवल वीआईपी सदस्यों के लिए लॉक',
      'vipButton': 'वीआईपी के लिए आवेदन करें और लक्ष्य सेट करें',
      'vipDone': 'वीआईपी प्रीमियम सदस्य सक्रिय',
      'disabledHint': 'वीआईपी अनुमोदन के बाद उपलब्ध',
      'saved': 'सेटिंग्स सहेज ली गई हैं।',
      'snackVip': 'वीआईपी सदस्यता स्वीकृत। अब आप अपना लक्ष्य सेट कर सकते हैं।',
      'defaultSchool': 'सियोल नेशनल यूनिवर्सिटी',
      'targetWord': 'लक्ष्य',
      'savePersonalInfo': 'व्यक्तिगत जानकारी सहेजें',
      'savedPersonalInfo': 'व्यक्तिगत जानकारी सहेज ली गई है।',
    },
    {
      'code': 'VI',
      'name': 'Tiếng Việt',
      'flag': '🇻🇳',
      'title': 'Trang của tôi',
      'target': 'Cài đặt trường mục tiêu',
      'hint': 'Nhập tên mục tiêu',
      'save': 'Lưu cài đặt',
      'vip': 'Thành viên Premium VIP',
      'normal': 'Thành viên thường',
      'personal': 'Sửa thông tin',
      'email': 'Địa chỉ Email',
      'password': 'Đổi mật khẩu',
      'passwordHint': 'Nhập mật khẩu mới',
      'language': 'Chọn ngôn ngữ',
      'vipLocked': 'Chỉ dành cho thành viên VIP',
      'vipButton': 'Đăng ký VIP và đặt mục tiêu',
      'vipDone': 'Đã kích hoạt thành viên Premium VIP',
      'disabledHint': 'Sẽ khả dụng sau khi phê duyệt VIP',
      'saved': 'Cài đặt đã được lưu thành công.',
      'snackVip': 'Đã phê duyệt thành viên VIP. Bạn có thể tự do đặt mục tiêu.',
      'defaultSchool': 'Đại học Quốc gia Seoul',
      'targetWord': 'Mục tiêu',
      'savePersonalInfo': 'Lưu thông tin cá nhân',
      'savedPersonalInfo': 'Đã lưu thông tin cá nhân.',
    },
    // 🆕 [신규 추가] 스페인어
    {
      'code': 'ES',
      'name': 'Español',
      'flag': '🇪🇸',
      'title': 'Mi Página',
      'target': 'Configuración de escuela objetivo',
      'hint': 'Ingresa el nombre del objetivo',
      'save': 'Guardar configuración',
      'vip': 'Miembro Premium VIP',
      'normal': 'Miembro Regular',
      'personal': 'Editar información personal',
      'email': 'Correo electrónico',
      'password': 'Actualizar contraseña',
      'passwordHint': 'Ingresa la nueva contraseña',
      'language': 'Idioma global',
      'vipLocked': 'Bloqueado solo para miembros VIP',
      'vipButton': 'Solicitar VIP y definir objetivo',
      'vipDone': 'Miembro Premium VIP Activado',
      'disabledHint': 'Disponible tras la aprobación VIP',
      'saved': 'La configuración de Mi Página se ha guardado.',
      'snackVip': 'Membresía VIP aprobada. Ahora puedes definir tu objetivo.',
      'defaultSchool': 'Universidad Nacional de Seúl',
      'targetWord': 'Objetivo',
      'savePersonalInfo': 'Guardar información personal',
      'savedPersonalInfo': 'La información personal se ha guardado.',
    },
    // 🆕 [신규 추가] 태국어
    {
      'code': 'TH',
      'name': 'ภาษาไทย',
      'flag': '🇹🇭',
      'title': 'หน้าของฉัน',
      'target': 'ตั้งค่าโรงเรียนเป้าหมาย',
      'hint': 'กรอกชื่อเป้าหมาย',
      'save': 'บันทึกการตั้งค่า',
      'vip': 'สมาชิก VIP พรีเมียม',
      'normal': 'สมาชิกทั่วไป',
      'personal': 'แก้ไขข้อมูลส่วนตัว',
      'email': 'อีเมล',
      'password': 'เปลี่ยนรหัสผ่าน',
      'passwordHint': 'กรอกรหัสผ่านใหม่',
      'language': 'เลือกภาษา',
      'vipLocked': 'ล็อกไว้สำหรับสมาชิก VIP เท่านั้น',
      'vipButton': 'สมัคร VIP และตั้งเป้าหมาย',
      'vipDone': 'เปิดใช้งานสมาชิก VIP พรีเมียมแล้ว',
      'disabledHint': 'ใช้งานได้หลังจากได้รับการอนุมัติ VIP',
      'saved': 'บันทึกการตั้งค่าหน้าของฉันแล้ว',
      'snackVip': 'อนุมัติสมาชิก VIP แล้ว ตอนนี้คุณสามารถตั้งเป้าหมายได้',
      'defaultSchool': 'มหาวิทยาลัยแห่งชาติโซล',
      'targetWord': 'เป้าหมาย',
      'savePersonalInfo': 'บันทึกข้อมูลส่วนตัว',
      'savedPersonalInfo': 'บันทึกข้อมูลส่วนตัวแล้ว',
    },
  ];

  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _containerBg = Color(0xFF0D1527);
  static const Color _pageBg = Color(0xFF030712);

  int _currentLangIndex = 1;
  bool _isVip = false;

  final TextEditingController _uniController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(text: 'studyup@dke.com');
  final TextEditingController _passwordController = TextEditingController();

  Map<String, String> get _lang => _languages[_currentLangIndex];
  bool get _isRtl => _lang['code'] == 'AR';

  @override
  void initState() {
    super.initState();
    _isVip = widget.isVipMember;
    _loadSavedSettings();
  }

  // 🕒 기기 저장소에서 영구 가입된 VIP 상태와 목표 데이터를 실시간 로드 및 복원
  // 🆕 [12개국 연동] 언어는 더 이상 마이페이지 전용 키로 따로 저장하지 않고,
  //    DkeLang(전역 스위치, 'user_country' 키)을 그대로 기준으로 삼습니다. (한 곳에서만 관리 -> 화면 간 불일치 방지)
  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUni = prefs.getString('saved_target_university') ?? '';

    // 👑 🎯 핵심 반영: 기기에 저장된 VIP 가입 이력이 있으면 기본 위젯 상태를 제치고 무조건 복원 승격!
    final bool savedVipStatus = prefs.getBool('saved_vip_status') ?? widget.isVipMember;

    int langIdx = _languages.indexWhere((lang) => lang['code'] == DkeLang.current);
    if (langIdx == -1) langIdx = 1; // 못 찾으면 한국어(KO) 기본값

    if (!mounted) return;

    setState(() {
      _uniController.text = savedUni;
      _currentLangIndex = langIdx;
      _isVip = savedVipStatus;
    });
  }

  // 💾 [설정 저장] 버튼을 누를 때 대학 이름, 언어, 가입 승인 상태를 동시에 기기에 영구 고정
  // 🆕 [12개국 연동] 언어 저장은 DkeLang.setLanguage()에게 위임합니다.
  //    이 한 번의 호출로 (1) DkeLang.current가 즉시 바뀌고 (2) 'user_country' 키에 영구 저장까지 함께 처리됩니다.
  Future<void> _saveAndPop() async {
    final prefs = await SharedPreferences.getInstance();

    String finalUni = _uniController.text.trim();
    if (finalUni.isEmpty) {
      finalUni = _lang['defaultSchool'] ?? '서울대학교';
    }

    final currentLangCode = _lang['code'] ?? 'KO';

    await prefs.setString('saved_target_university', finalUni);
    await prefs.setBool('saved_vip_status', _isVip);
    await DkeLang.setLanguage(currentLangCode); // 🆕 전역 언어 스위치 갱신 + 영구 저장

    // 👑 요구사항 2번 가이드 장치: 실시간 메모리 데이터 세션 동기화 호출단 연동 유지
    widget.onSave(_isVip, finalUni);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_lang['saved'] ?? '저장되었습니다.'),
        backgroundColor: _containerBg,
      ),
    );

    Navigator.pop(context);
  }

  // ============================================================================
  // 🆕 [버그 점검/수정] VIP 활성화 버튼 처리
  // 기존 문제 1: SharedPreferences 호출이 실패해도 아무 에러 표시 없이 조용히 멈춰서
  //           "버튼이 먹통"처럼 보였음 -> try/catch로 감싸서 실패 시 반드시 안내 문구 표시.
  // 기존 문제 2: 버튼을 눌러도 [설정 저장]을 누르기 전까지는 부모 화면(홈 대시보드)에
  //           VIP 상태가 반영되지 않아서, 화면을 나갔다 오면 목표 학교 입력이 다시 잠긴 것처럼
  //           보일 수 있었음 -> 활성화 즉시 widget.onSave()도 함께 호출해서 바로 동기화.
  // ============================================================================
  Future<void> _activateVip() async {
    try {
      final localPrefs = await SharedPreferences.getInstance();
      // 👑 요구사항 2번 구현 핵심 장치: 결제 승인과 동시에 로컬 캐시에 영구 플래그 보전 유도
      await localPrefs.setBool('saved_vip_status', true);

      if (!mounted) return;
      setState(() {
        _isVip = true;
      });

      // 🆕 활성화 즉시 부모 화면에도 바로 반영 (설정 저장 버튼을 누르기 전이라도 동기화됨)
      widget.onSave(_isVip, _uniController.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 ${_lang['snackVip'] ?? 'VIP 회원이 승인되었습니다.'}'),
          backgroundColor: _brandGolden,
        ),
      );
    } catch (e) {
      debugPrint('[MyPageScreen] VIP 활성화 실패: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('VIP 활성화에 실패했습니다. 앱을 완전히 재시작한 뒤 다시 시도해 주세요.\n($e)'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ============================================================================
  // 🆕 [2026-08-04] 개인정보(이메일/비밀번호) 저장 버튼 처리
  // 기존 문제: 이메일/비밀번호 입력창은 있었지만 저장하는 로직이 전혀 없어서,
  //           입력해도 화면을 나가면 그대로 사라지는 문제가 있었음.
  // ⚠️ 참고: 아직 서버(계정 인증 백엔드)가 없어서 SharedPreferences(로컬)에만 저장합니다.
  //         서버 연동 시 이 함수 내부만 실제 계정 API 호출로 교체하면 됩니다.
  // ============================================================================
  Future<void> _savePersonalInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String email = _emailController.text.trim();
      if (email.isNotEmpty) {
        await prefs.setString('saved_user_email', email);
      }

      // 비밀번호는 입력했을 때만 저장하고, 저장 후에는 화면에 남기지 않도록 입력창을 비웁니다.
      final String password = _passwordController.text.trim();
      if (password.isNotEmpty) {
        await prefs.setString('saved_user_password', password);
        _passwordController.clear();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_lang['savedPersonalInfo'] ?? '개인정보가 저장되었습니다.'),
          backgroundColor: _containerBg,
        ),
      );
    } catch (e) {
      debugPrint('[MyPageScreen] 개인정보 저장 실패: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('개인정보 저장에 실패했습니다. 다시 시도해 주세요.\n($e)'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  TextStyle _localizedTextStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    required Color color,
    double? letterSpacing,
  }) {
    return GoogleFonts.notoSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: _localizedTextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: _brandGolden,
      ),
    );
  }

  InputDecoration _underlineDecoration({
    required String labelText,
    required String? hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: const TextStyle(color: _brandGolden),
      hintStyle: const TextStyle(color: Colors.white38),
      prefixIcon: Icon(icon, color: _brandGolden),
      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _brandGolden)),
    );
  }

  @override
  void dispose() {
    _uniController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _pageBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          toolbarHeight: 90,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 165,
                height: 32,
                child: Image.asset(
                  'assets/images/gsu_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'MY PAGE GKE STUDYUP',
                style: GoogleFonts.gowunBatang(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: _brandGolden,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '마이페이지',
                style: GoogleFonts.notoSansKr(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _brandGolden,
                ),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('PERSONAL INFO EDIT (${_lang['personal'] ?? '개인정보 수정'})'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _containerBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _brandGolden.withOpacity(0.4), width: 1),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: _underlineDecoration(
                        labelText: _lang['email'] ?? 'Email Address',
                        hintText: 'studyup@dke.com',
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: _underlineDecoration(
                        labelText: _lang['password'] ?? 'Password Update',
                        hintText: _lang['passwordHint'],
                        icon: Icons.lock_reset_rounded,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _brandGolden, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          backgroundColor: _brandGolden.withOpacity(0.05),
                        ),
                        onPressed: _savePersonalInfo,
                        child: Text(
                          _lang['savePersonalInfo'] ?? '개인정보 저장',
                          style: const TextStyle(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      _lang['target'] ?? 'Target',
                      style: _localizedTextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _brandGolden,
                      ),
                    ),
                  ),
                  if (!_isVip) ...[
                    const SizedBox(width: 12),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline_rounded, color: _brandGolden, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _lang['vipLocked'] ?? 'VIP 잠김',
                              overflow: TextOverflow.ellipsis,
                              style: _localizedTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _brandGolden,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _uniController,
                enabled: _isVip,
                style: TextStyle(
                  color: _isVip ? Colors.white : Colors.white38,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: _isVip ? (_lang['hint'] ?? '목표명을 입력하세요') : (_lang['disabledHint'] ?? 'VIP 승인 후 활성화됩니다.'),
                  hintStyle: TextStyle(color: _isVip ? Colors.white38 : _brandGolden.withOpacity(0.5)),
                  filled: true,
                  fillColor: _isVip ? _containerBg : Colors.white.withOpacity(0.05),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _brandGolden, width: 1.5),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _brandGolden.withOpacity(0.15)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _isVip ? Colors.white38 : _brandGolden, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: _isVip ? Colors.transparent : _brandGolden.withOpacity(0.05),
                  ),
                  onPressed: _isVip ? null : _activateVip,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isVip ? Icons.verified_user_rounded : Icons.payment_rounded,
                        color: _isVip ? Colors.white38 : _brandGolden,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _isVip ? (_lang['vipDone'] ?? 'VIP 활성화 완료') : (_lang['vipButton'] ?? 'VIP 신청'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isVip ? Colors.white38 : _brandGolden,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('GLOBAL LANGUAGE (${_lang['language'] ?? '다국어 선택'})'),
              const SizedBox(height: 12),
              // 🌐 다국어 선택 그리드 뷰 섹션 (12개국)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _languages.length, // 👈 확장된 12개국 언어 팩 리스트 길이 연동
                itemBuilder: (context, index) {
                  final isSelected = _currentLangIndex == index;
                  final item = _languages[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _currentLangIndex = index;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? _brandGolden.withOpacity(0.15) : _containerBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _brandGolden : Colors.white12,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item['flag'] ?? '', style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              item['name'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected ? _brandGolden : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandGolden,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveAndPop,
                  child: Text(
                    _lang['save'] ?? '설정 저장',
                    style: const TextStyle(color: _pageBg, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
