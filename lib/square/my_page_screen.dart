import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyPageScreen extends StatefulWidget {
  final bool isVipMember;
  final Function(bool, String) onSave;

  const MyPageScreen({
    super.key,
    required this.isVipMember,
    required this.onSave,
  });

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  // 🎯 10대 글로벌 다국어 데이터 팩 맵핑 (선택된 언어 1개만 매끄럽게 출력)
  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸', 'title': 'My Page', 'target': 'Target School', 'hint': 'Enter school name', 'save': 'Save Settings', 'vip': 'VIP Premium Member', 'normal': 'Regular Member'},
    {'code': 'ko', 'name': '한국어', 'flag': '🇰🇷', 'title': '마이 페이지', 'target': '목표 학교', 'hint': '학교명을 입력하세요', 'save': '설정 저장', 'vip': 'VIP 프리미엄 회원', 'normal': '일반 회원'},
    {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵', 'title': 'マイページ', 'target': '目標学校', 'hint': '学校名を入力してください', 'save': '設定保存', 'vip': 'VIPプレミアム会員', 'normal': '一般会員'},
    {'code': 'zh', 'name': '简体中文', 'flag': '🇨🇳', 'title': '个人中心', 'target': '目标学校', 'hint': '请输入学校名称', 'save': '保存设置', 'vip': 'VIP高级会员', 'normal': '普通会员'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦', 'title': 'صفحتي', 'target': 'المدرسة المستهدفة', 'hint': 'أدخل اسم المدرسة', 'save': 'حفظ الإعدادات', 'vip': 'عضو VIP ممتاز', 'normal': 'عضو عادي'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸', 'title': 'Mi Cuenta', 'target': 'Escuela Objetivo', 'hint': 'Ingrese el nombre', 'save': 'Guardar', 'vip': 'Miembro VIP', 'normal': 'Miembro Regular'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷', 'title': 'Mon Profil', 'target': 'École Cible', 'hint': 'Entrez le nom', 'save': 'Enregistrer', 'vip': 'Membre VIP', 'normal': 'Membre Régulier'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪', 'title': 'Mein Profil', 'target': 'Zielschule', 'hint': 'Schulnamen eingeben', 'save': 'Speichern', 'vip': 'VIP-Mitglied', 'normal': 'Reguläres Mitglied'},
    {'code': 'vi', 'name': 'Tiếng Việt', 'flag': '🇻🇳', 'title': 'Trang Của Tôi', 'target': 'Trường Mục Tiêu', 'hint': 'Nhập tên trường', 'save': 'Lưu Cài Đặt', 'vip': 'Thành viên VIP', 'normal': 'Thành viên Thường'},
    {'code': 'id', 'name': 'Bahasa', 'flag': '🇮🇩', 'title': 'Profil Saya', 'target': 'Sekolah Target', 'hint': 'Masukkan nama sekolah', 'save': 'Simpan Pengaturan', 'vip': 'Anggota VIP', 'normal': 'Anggota Reguler'},
  ];

  int _currentLangIndex = 1; // 기본값 한국어
  final TextEditingController _uniController = TextEditingController();
  bool _isVip = false;

  @override
  void initState() {
    super.initState();
    _isVip = widget.isVipMember;
    _loadSavedSettings();
  }

  // 🕒 SharedPreferences에서 목표 데이터 실시간 읽어오기 (5일뒤 수정해도 완벽 대응)
  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String savedUni = prefs.getString('saved_target_university') ?? '';
    String savedLang = prefs.getString('saved_language_code') ?? 'ko';

    int langIdx = _languages.indexWhere((lang) => lang['code'] == savedLang);
    if (langIdx == -1) langIdx = 1;

    setState(() {
      _uniController.text = savedUni;
      _currentLangIndex = langIdx;
    });
  }

  // 💾 [저장 기능] 여기서 누르면 타이머 화면과 100% 즉시 동기화 영구 소독
  Future<void> _saveAndPop() async {
    final prefs = await SharedPreferences.getInstance();
    String finalUni = _uniController.text.trim();
    String currentLangCode = _languages[_currentLangIndex]['code']!;

    if (finalUni.isEmpty) {
      finalUni = _currentLangIndex == 1 ? "서울대학교" : "Seoul National University";
    }

    await prefs.setString('saved_target_university', finalUni);
    await prefs.setString('saved_language_code', currentLangCode);

    widget.onSave(_isVip, finalUni);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _uniController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = _languages[_currentLangIndex];
    // 아랍어(ar)일 경우에만 우측정렬(RTL) 레이아웃 자동 변환 스펙 적용
    bool isRtl = currentLang['code'] == 'ar';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        // 🌌 홈 대시보드와 100% 일치하는 웅장한 다크네이비 바탕색 적용
        backgroundColor: const Color(0xFF030712),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          // 👑 'DKE', 'STUDYUP' 배치의 진한 명조체 타이포그래피 포인트 가미
          title: Text(
            'DKE STUDYUP',
            style: GoogleFonts.gowunBatang(
              color: const Color(0xFFFFD700), // 웅장한 황금색 현상태 유지
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🛡️ 타이틀: 노토산스 한글 크기 23 단일화 (한국어 선택 시)
              Text(
                currentLang['title']!,
                style: currentLang['code'] == 'ko'
                    ? const TextStyle(fontFamily: 'NotoSansKR', fontSize: 23, fontWeight: FontWeight.bold, color: Colors.white)
                    : GoogleFonts.gowunBatang(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 24),

              // 👑 1. VIP 멤버십 등급 박스 섹션
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFD700), width: 1.5), // 황금색 포인트 테두리
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Color(0xFFFFD700), size: 32),
                    const SizedBox(width: 16),
                    Text(
                      _isVip ? currentLang['vip']! : currentLang['normal']!,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 🎯 2. 실시간 목표 학교 설정 섹션
              Text(
                currentLang['target']!,
                style: const TextStyle(color: Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _uniController,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: currentLang['hint']!,
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1F2937),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFFD700)),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 🌐 3. 글로벌 10대 다국어 즉시 전환 그리드 섹션
              const Text(
                'GLOBAL LANGUAGE (다국어 선택)',
                style: TextStyle(color: Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.bold),
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
                  bool isSelected = _currentLangIndex == index;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _currentLangIndex = index;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFD700).withOpacity(0.2) : const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_languages[index]['flag']!, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            _languages[index]['name']!,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFFFFD700) : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),

              // 💾 4. 최종 설정 저장 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveAndPop,
                  child: Text(
                    currentLang['save']!,
                    style: const TextStyle(color: Color(0xFF030712), fontSize: 18, fontWeight: FontWeight.bold),
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