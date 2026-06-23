import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final List<Map<String, String>> _languages = const [
    {
      'code': 'en',
      'name': 'English',
      'flag': '🇺🇸',
      'title': 'My Page',
      'target': 'Target School',
      'hint': 'Enter school name',
      'save': 'Save Settings',
      'vip': 'VIP Premium Member',
      'normal': 'Regular Member',
      'personal': 'Personal Info',
      'email': 'Email Address',
      'password': 'Password Update',
      'passwordHint': 'Enter new password',
      'language': 'Global Language',
      'vipLocked': 'Locked for VIP members only',
      'vipButton': 'Apply VIP and set target school',
      'vipDone': 'VIP Premium Member Activated',
      'disabledHint': 'Available after VIP approval',
      'saved': 'My Page settings have been saved.',
      'snackVip':
      'VIP membership approved. You can now set your target school.',
      'defaultSchool': 'Seoul National University',
      'targetWord': 'Target',
    },
    {
      'code': 'ko',
      'name': '한국어',
      'flag': '🇰🇷',
      'title': '마이 페이지',
      'target': '목표 학교',
      'hint': '학교명을 입력하세요',
      'save': '설정 저장',
      'vip': 'VIP 프리미엄 회원',
      'normal': '일반 회원',
      'personal': '개인정보 수정',
      'email': '이메일 주소',
      'password': '비밀번호 변경',
      'passwordHint': '새 비밀번호를 입력하세요',
      'language': '다국어 선택',
      'vipLocked': 'VIP 결제 전용 잠김',
      'vipButton': '회원결제(VIP) 신청하고 목표학교 설정하기',
      'vipDone': 'VIP 프리미엄 회원 활성화 완료',
      'disabledHint': '아래 [회원결제(VIP)] 승인 후 활성화됩니다.',
      'saved': '마이페이지 설정이 저장되었습니다.',
      'snackVip':
      'VIP 회원 결제가 승인되었습니다! 이제 목표 학교를 자유롭게 직접 설정할 수 있습니다.',
      'defaultSchool': '서울대학교',
      'targetWord': '목표',
    },
    {
      'code': 'ja',
      'name': '日本語',
      'flag': '🇯🇵',
      'title': 'マイページ',
      'target': '目標学校',
      'hint': '学校名を入力してください',
      'save': '設定保存',
      'vip': 'VIPプレミアム会員',
      'normal': '一般会員',
      'personal': '個人情報の修正',
      'email': 'メールアドレス',
      'password': 'パスワード変更',
      'passwordHint': '新しいパスワードを入力してください',
      'language': '言語選択',
      'vipLocked': 'VIP会員専用ロック',
      'vipButton': 'VIPを申請して目標学校を設定',
      'vipDone': 'VIPプレミアム会員有効化完了',
      'disabledHint': 'VIP承認後に有効になります。',
      'saved': 'マイページ設定が保存されました。',
      'snackVip': 'VIP会員登録が承認されました。目標学校を設定できます。',
      'defaultSchool': 'ソウル大学校',
      'targetWord': '目標',
    },
    {
      'code': 'zh',
      'name': '简体中文',
      'flag': '🇨🇳',
      'title': '个人中心',
      'target': '目标学校',
      'hint': '请输入学校名称',
      'save': '保存设置',
      'vip': 'VIP高级会员',
      'normal': '普通会员',
      'personal': '个人信息修改',
      'email': '电子邮箱',
      'password': '修改密码',
      'passwordHint': '请输入新密码',
      'language': '多语言选择',
      'vipLocked': '仅限VIP会员',
      'vipButton': '申请VIP并设置目标学校',
      'vipDone': 'VIP高级会员已激活',
      'disabledHint': 'VIP批准后可启用',
      'saved': '个人中心设置已保存。',
      'snackVip': 'VIP会员已批准，现在可以自由设置目标学校。',
      'defaultSchool': '首尔大学',
      'targetWord': '目标',
    },
    {
      'code': 'ar',
      'name': 'العربية',
      'flag': '🇸🇦',
      'title': 'صفحتي',
      'target': 'المدرسة المستهدفة',
      'hint': 'أدخل اسم المدرسة',
      'save': 'حفظ الإعدادات',
      'vip': 'عضو VIP ممتاز',
      'normal': 'عضو عادي',
      'personal': 'تعديل المعلومات الشخصية',
      'email': 'البريد الإلكتروني',
      'password': 'تحديث كلمة المرور',
      'passwordHint': 'أدخل كلمة مرور جديدة',
      'language': 'اختيار اللغة',
      'vipLocked': 'مقفل لأعضاء VIP فقط',
      'vipButton': 'التقديم على VIP وتحديد المدرسة المستهدفة',
      'vipDone': 'تم تفعيل عضوية VIP',
      'disabledHint': 'سيتوفر بعد الموافقة على VIP',
      'saved': 'تم حفظ إعدادات صفحتي.',
      'snackVip': 'تمت الموافقة على عضوية VIP. يمكنك الآن تعيين المدرسة المستهدفة.',
      'defaultSchool': 'جامعة سيول الوطنية',
      'targetWord': 'الهدف',
    },
    {
      'code': 'es',
      'name': 'Español',
      'flag': '🇪🇸',
      'title': 'Mi Cuenta',
      'target': 'Escuela Objetivo',
      'hint': 'Ingrese el nombre',
      'save': 'Guardar',
      'vip': 'Miembro VIP',
      'normal': 'Miembro Regular',
      'personal': 'Editar información personal',
      'email': 'Correo electrónico',
      'password': 'Cambiar contraseña',
      'passwordHint': 'Ingrese una nueva contraseña',
      'language': 'Idioma global',
      'vipLocked': 'Bloqueado solo para VIP',
      'vipButton': 'Solicitar VIP y configurar escuela objetivo',
      'vipDone': 'VIP activado',
      'disabledHint': 'Disponible después de la aprobación VIP',
      'saved': 'La configuración se ha guardado.',
      'snackVip':
      'La membresía VIP ha sido aprobada. Ahora puedes configurar tu escuela objetivo.',
      'defaultSchool': 'Universidad Nacional de Seúl',
      'targetWord': 'Objetivo',
    },
    {
      'code': 'fr',
      'name': 'Français',
      'flag': '🇫🇷',
      'title': 'Mon Profil',
      'target': 'École Cible',
      'hint': 'Entrez le nom',
      'save': 'Enregistrer',
      'vip': 'Membre VIP',
      'normal': 'Membre Régulier',
      'personal': 'Modifier les informations personnelles',
      'email': 'Adresse e-mail',
      'password': 'Changer le mot de passe',
      'passwordHint': 'Entrez un nouveau mot de passe',
      'language': 'Langue globale',
      'vipLocked': 'Réservé aux membres VIP',
      'vipButton': 'Demander le VIP et définir l’école cible',
      'vipDone': 'VIP activé',
      'disabledHint': 'Disponible après approbation VIP',
      'saved': 'Les paramètres ont été enregistrés.',
      'snackVip':
      'L’adhésion VIP a été approuvée. Vous pouvez maintenant définir votre école cible.',
      'defaultSchool': 'Université nationale de Séoul',
      'targetWord': 'Objectif',
    },
    {
      'code': 'de',
      'name': 'Deutsch',
      'flag': '🇩🇪',
      'title': 'Mein Profil',
      'target': 'Zielschule',
      'hint': 'Schulnamen eingeben',
      'save': 'Speichern',
      'vip': 'VIP-Mitglied',
      'normal': 'Reguläres Mitglied',
      'personal': 'Persönliche Daten bearbeiten',
      'email': 'E-Mail-Adresse',
      'password': 'Passwort ändern',
      'passwordHint': 'Neues Passwort eingeben',
      'language': 'Globale Sprache',
      'vipLocked': 'Nur für VIP-Mitglieder',
      'vipButton': 'VIP beantragen und Zielschule festlegen',
      'vipDone': 'VIP aktiviert',
      'disabledHint': 'Nach VIP-Freigabe verfügbar',
      'saved': 'Die Einstellungen wurden gespeichert.',
      'snackVip':
      'Die VIP-Mitgliedschaft wurde genehmigt. Jetzt können Sie Ihre Zielschule festlegen.',
      'defaultSchool': 'Nationale Universität Seoul',
      'targetWord': 'Ziel',
    },
    {
      'code': 'vi',
      'name': 'Tiếng Việt',
      'flag': '🇻🇳',
      'title': 'Trang Của Tôi',
      'target': 'Trường Mục Tiêu',
      'hint': 'Nhập tên trường',
      'save': 'Lưu Cài Đặt',
      'vip': 'Thành viên VIP',
      'normal': 'Thành viên Thường',
      'personal': 'Chỉnh sửa thông tin cá nhân',
      'email': 'Địa chỉ email',
      'password': 'Đổi mật khẩu',
      'passwordHint': 'Nhập mật khẩu mới',
      'language': 'Ngôn ngữ',
      'vipLocked': 'Chỉ dành cho VIP',
      'vipButton': 'Đăng ký VIP và đặt trường mục tiêu',
      'vipDone': 'Đã kích hoạt VIP',
      'disabledHint': 'Khả dụng sau khi VIP được phê duyệt',
      'saved': 'Đã lưu cài đặt.',
      'snackVip':
      'Tư cách thành viên VIP đã được phê duyệt. Bây giờ bạn có thể đặt trường mục tiêu.',
      'defaultSchool': 'Đại học Quốc gia Seoul',
      'targetWord': 'Mục tiêu',
    },
    {
      'code': 'id',
      'name': 'Bahasa',
      'flag': '🇮🇩',
      'title': 'Profil Saya',
      'target': 'Sekolah Target',
      'hint': 'Masukkan nama sekolah',
      'save': 'Simpan Pengaturan',
      'vip': 'Anggota VIP',
      'normal': 'Anggota Reguler',
      'personal': 'Ubah info pribadi',
      'email': 'Alamat email',
      'password': 'Ubah kata sandi',
      'passwordHint': 'Masukkan kata sandi baru',
      'language': 'Bahasa Global',
      'vipLocked': 'Hanya untuk anggota VIP',
      'vipButton': 'Ajukan VIP dan atur sekolah target',
      'vipDone': 'VIP aktif',
      'disabledHint': 'Tersedia setelah persetujuan VIP',
      'saved': 'Pengaturan telah disimpan.',
      'snackVip':
      'Keanggotaan VIP telah disetujui. Sekarang Anda dapat mengatur sekolah target.',
      'defaultSchool': 'Universitas Nasional Seoul',
      'targetWord': 'Target',
    },
  ];

  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _containerBg = Color(0xFF0D1527);
  static const Color _pageBg = Color(0xFF030712);

  int _currentLangIndex = 1;
  bool _isVip = false;

  final TextEditingController _uniController = TextEditingController();
  final TextEditingController _emailController =
  TextEditingController(text: 'studyup@dke.com');
  final TextEditingController _passwordController = TextEditingController();

  Map<String, String> get _lang => _languages[_currentLangIndex];

  bool get _isRtl => _lang['code'] == 'ar';

  @override
  void initState() {
    super.initState();
    _isVip = widget.isVipMember;
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUni = prefs.getString('saved_target_university') ?? '';
    final savedLang = prefs.getString('saved_language_code') ?? 'ko';

    int langIdx = _languages.indexWhere((lang) => lang['code'] == savedLang);
    if (langIdx == -1) langIdx = 1;

    if (!mounted) return;

    setState(() {
      _uniController.text = savedUni;
      _currentLangIndex = langIdx;
    });
  }

  Future<void> _saveAndPop() async {
    final prefs = await SharedPreferences.getInstance();

    String finalUni = _uniController.text.trim();
    if (finalUni.isEmpty) {
      finalUni = _lang['defaultSchool'] ?? '서울대학교';
    }

    final currentLangCode = _lang['code'] ?? 'ko';

    await prefs.setString('saved_target_university', finalUni);
    await prefs.setString('saved_language_code', currentLangCode);

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

  TextStyle _localizedTextStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    required Color color,
    double? letterSpacing,
  }) {
    final code = _lang['code'];

    if (code == 'ar') {
      return GoogleFonts.notoNaskhArabic(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
    }

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
        fontSize: 14,
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
      labelStyle: TextStyle(color: _brandGolden),
      hintStyle: const TextStyle(color: Colors.white38),
      prefixIcon: Icon(icon, color: _brandGolden),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white12),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: _brandGolden),
      ),
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
                width: 255,
                height: 48,
                child: Image.asset(
                  'assets/images/gsu_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'MY PAGE DKE STUDYUP',
                style: _localizedTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _brandGolden,
                  letterSpacing: 1.5,
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
              Text(
                _lang['title'] ?? 'My Page',
                style: _localizedTextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle(
                'PERSONAL INFO EDIT (${_lang['personal'] ?? '개인정보 수정'})',
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _containerBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _brandGolden.withOpacity(0.4),
                    width: 1,
                  ),
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
                      _lang['target'] ?? 'Target School',
                      style: _localizedTextStyle(
                        fontSize: 16,
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
                          Icon(
                            Icons.lock_outline_rounded,
                            color: _brandGolden,
                            size: 16,
                          ),
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
                  hintText: _isVip
                      ? (_lang['hint'] ?? '학교명을 입력하세요')
                      : (_lang['disabledHint'] ?? 'VIP 승인 후 활성화됩니다.'),
                  hintStyle: TextStyle(
                    color: _isVip
                        ? Colors.white38
                        : _brandGolden.withOpacity(0.5),
                  ),
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
                    borderSide: BorderSide(
                      color: _brandGolden.withOpacity(0.15),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _isVip ? Colors.white38 : _brandGolden,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor:
                    _isVip ? Colors.transparent : _brandGolden.withOpacity(0.05),
                  ),
                  onPressed: _isVip
                      ? null
                      : () {
                    setState(() {
                      _isVip = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '🎉 ${_lang['snackVip'] ?? 'VIP 회원이 승인되었습니다.'}',
                        ),
                        backgroundColor: _brandGolden,
                      ),
                    );
                  },
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
                          _isVip
                              ? (_lang['vipDone'] ?? 'VIP 활성화 완료')
                              : (_lang['vipButton'] ?? 'VIP 신청'),
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

              _buildSectionTitle(
                'GLOBAL LANGUAGE (${_lang['language'] ?? '다국어 선택'})',
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _languages.length,
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
                        color: isSelected
                            ? _brandGolden.withOpacity(0.15)
                            : _containerBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _brandGolden : Colors.white12,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item['flag'] ?? '',
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              item['name'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected ? _brandGolden : Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveAndPop,
                  child: Text(
                    _lang['save'] ?? '설정 저장',
                    style: const TextStyle(
                      color: _pageBg,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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

class DkeBigStarTargetAnimationModule extends StatefulWidget {
  final String targetUniversityName;
  final String currentLanguageCode;

  const DkeBigStarTargetAnimationModule({
    super.key,
    required this.targetUniversityName,
    required this.currentLanguageCode,
  });

  @override
  State<DkeBigStarTargetAnimationModule> createState() =>
      _DkeBigStarTargetAnimationModuleState();
}

class _DkeBigStarTargetAnimationModuleState
    extends State<DkeBigStarTargetAnimationModule>
    with TickerProviderStateMixin {
  late final AnimationController _timelineController;
  late final Animation<double> _targetWordScale;
  late final Animation<double> _targetWordOpacity;
  late final Animation<double> _uniWordScale;
  late final Animation<double> _uniWordOpacity;

  static const Color _brandGolden = Color(0xFFE5C158);

  @override
  void initState() {
    super.initState();

    _timelineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );

    _targetWordScale = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1).chain(
          CurveTween(curve: Curves.fastOutSlowIn),
        ),
        weight: 10,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(1),
        weight: 10,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 0).chain(
          CurveTween(curve: Curves.fastOutSlowIn),
        ),
        weight: 10,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0),
        weight: 70,
      ),
    ]).animate(_timelineController);

    _targetWordOpacity = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1),
        weight: 10,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(1),
        weight: 10,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 0),
        weight: 10,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0),
        weight: 70,
      ),
    ]).animate(_timelineController);

    _uniWordScale = TweenSequence<double>([
      KeyframeTween(30, 0),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1.8).chain(
          CurveTween(curve: Curves.linearToEaseOut),
        ),
        weight: 23,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(1.8),
        weight: 23,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.8, end: 0).chain(
          CurveTween(curve: Curves.fastOutSlowIn),
        ),
        weight: 24,
      ),
    ]).animate(_timelineController);

    _uniWordOpacity = TweenSequence<double>([
      KeyframeTween(30, 0),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1),
        weight: 23,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(1),
        weight: 23,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 0),
        weight: 24,
      ),
    ]).animate(_timelineController);

    _timelineController.forward();
  }

  String _getTranslatedTarget() {
    switch (widget.currentLanguageCode) {
      case 'ko':
        return '목표';
      case 'ja':
        return '目標';
      case 'zh':
        return '目标';
      case 'ar':
        return 'الهدف';
      case 'es':
        return 'Objetivo';
      case 'fr':
        return 'Objectif';
      case 'de':
        return 'Ziel';
      case 'vi':
        return 'Mục tiêu';
      case 'id':
      case 'en':
      default:
        return 'Target';
    }
  }

  TextStyle _targetTextStyle() {
    if (widget.currentLanguageCode == 'ar') {
      return GoogleFonts.notoNaskhArabic(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: _brandGolden,
        shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
      );
    }

    return GoogleFonts.notoSans(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: _brandGolden,
      shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
    );
  }

  @override
  void dispose() {
    _timelineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = widget.currentLanguageCode == 'ar';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            FadeTransition(
              opacity: _targetWordOpacity,
              child: ScaleTransition(
                scale: _targetWordScale,
                child: Text(
                  _getTranslatedTarget(),
                  style: _targetTextStyle(),
                ),
              ),
            ),
            FadeTransition(
              opacity: _uniWordOpacity,
              child: ScaleTransition(
                scale: _uniWordScale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/crown_wings.png',
                      width: 32,
                      height: 18,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Text(
                        widget.targetUniversityName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KeyframeTween extends TweenSequenceItem<double> {
  KeyframeTween(int percentageWeight, double value)
      : super(
    tween: ConstantTween<double>(value),
    weight: percentageWeight.toDouble(),
  );
}
