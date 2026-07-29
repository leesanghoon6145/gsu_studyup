import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'global_lang.dart';
import 'parent/parent_main_dashboard_screen.dart';

// =============================================================================
// 🆕 [12개국 다국어 연동] 2026-07-29 추가: signup_screen.dart 전용 렌더 헬퍼 함수 3종
// 기존 위젯 구조(폰트/색상/크기/레이아웃)는 전혀 변경하지 않고, 텍스트 소스만
// DkeLang의 맵으로 교체하기 위한 함수입니다. 원본이 EN(gowunBatang)+KO(notoSansKr)
// 두 가지 폰트를 섞어 쓰던 자리는 기본모드에서 그 조합을 100% 그대로 유지하고,
// 10개국어 선택시에만 해당 언어 단독 표시로 전환됩니다(그때는 문자 표현을 위해
// GoogleFonts.notoSans로 폰트가 자동 전환됩니다 - EntranceScreen에서 이미 쓰인 것과 동일한 방식).
// =============================================================================

// (A) 한 줄짜리 "EN (KO)" 형태 - 입력창 힌트 등에 사용 (원본 폰트 그대로 유지, 폰트 전환 없음)
String dkeInline(Map<String, String> map) {
  if (DkeLang.isForeignSelected) {
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? '';
  }
  return "${map['EN']} (${map['KO']})";
}

// (B) 한 Text 위젯 안에서 줄바꿈(\n)으로 EN/KO 두 줄을 표시하던 버튼용 (AUTH, VERIFY 등)
Widget dkeBilineText(Map<String, String> map, TextStyle baseStyle, {TextAlign textAlign = TextAlign.center}) {
  if (DkeLang.isForeignSelected) {
    return Text(
      map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? '',
      textAlign: textAlign,
      style: GoogleFonts.notoSans(textStyle: baseStyle),
    );
  }
  return Text(
    '${map['EN']}\n(${map['KO']})',
    textAlign: textAlign,
    style: GoogleFonts.gowunBatang(textStyle: baseStyle),
  );
}

// (C) Column 안에 EN(큰 글씨, gowunBatang)/KO(작은 글씨, notoSansKr) 두 개의 개별 Text 위젯이
// 따로 있던 자리(헤딩, NEXT STEP, SIGNUP COMPLETE, PARENT LOGIN 버튼 등)를 위한 위젯 리스트 생성기.
// 기본모드: 원본처럼 2개 위젯(EN 스타일 그대로 + KO 스타일 그대로) 유지.
// 10개국어 선택시: 이미 번역된 문장 하나만 EN 스타일 자리(더 큰 폰트)에 표시.
List<Widget> dkeColumnLines(
    Map<String, String> map, {
      required TextStyle enStyle,
      required TextStyle koStyle,
      double gapHeight = 0,
    }) {
  if (DkeLang.isForeignSelected) {
    return [
      Text(
        map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? '',
        textAlign: TextAlign.center,
        style: GoogleFonts.notoSans(textStyle: enStyle),
      ),
    ];
  }
  final List<Widget> lines = [
    Text(map['EN'] ?? '', textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(textStyle: enStyle)),
  ];
  if (gapHeight > 0) lines.add(SizedBox(height: gapHeight));
  lines.add(
    Text('(${map['KO']})', textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(textStyle: koStyle)),
  );
  return lines;
}

// (D) RichText 두 TextSpan(EN gowunBatang + KO notoSansKr)이던 자리를 위한 헬퍼.
// 기본모드: 원본과 동일하게 두 TextSpan(EN 줄바꿈 KO) 구성.
// 10개국어 선택시: 번역문 하나만 단일 TextSpan으로 표시(폰트는 notoSans로 전환).
Widget dkeBilingualRich(
    Map<String, String> map, {
      required TextStyle enStyle,
      required TextStyle koStyle,
      TextAlign textAlign = TextAlign.start,
    }) {
  if (DkeLang.isForeignSelected) {
    return Text(
      map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? '',
      textAlign: textAlign,
      style: GoogleFonts.notoSans(textStyle: koStyle),
    );
  }
  return RichText(
    textAlign: textAlign,
    text: TextSpan(
      children: [
        TextSpan(text: '${map['EN']}\n', style: GoogleFonts.gowunBatang(textStyle: enStyle)),
        TextSpan(text: '(${map['KO']})', style: GoogleFonts.notoSansKr(textStyle: koStyle)),
      ],
    ),
  );
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool isStudent = true;
  bool isGeneral = false;

  // 🆕 [법적 필수 수정] 2026-07-29: 자진 체크박스(isUnder14) 삭제.
  // 생년월일을 직접 입력받아 만 나이를 계산하는 방식으로 교체 (임의 우회 방지).
  DateTime? _selectedBirthDate;

  bool parentConsent = false;
  bool isEmailSent = false;
  bool isPasswordVisible = false;

  // 🆕 [법적 필수 수정] 보호자 실제 인증 절차용 상태값
  bool _isParentAuthSent = false;
  bool _isParentVerified = false;

  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _emailAuthOpacityController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _classCodeController = TextEditingController();
  final TextEditingController _childEmailController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();

  // 🆕 [법적 필수 수정] 보호자 연락처 및 인증번호 입력용 컨트롤러
  final TextEditingController _parentEmailController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _parentAuthCodeController = TextEditingController();

  // 🆕 [법적 필수 수정] 생년월일 기반 만 나이 계산 (국제 표준 만 나이 방식)
  int? get _calculatedAge {
    if (_selectedBirthDate == null) return null;
    final DateTime today = DateTime.now();
    int age = today.year - _selectedBirthDate!.year;
    final bool birthdayNotYetThisYear = (today.month < _selectedBirthDate!.month) ||
        (today.month == _selectedBirthDate!.month && today.day < _selectedBirthDate!.day);
    if (birthdayNotYetThisYear) age -= 1;
    return age;
  }

  // 🆕 [법적 필수 수정] 만 14세 미만 여부 - 생년월일 기반 자동 판정 (자진 신고 아님)
  bool get _isUnder14 => _calculatedAge != null && _calculatedAge! < 14;

  // 🆕 [법적 필수 수정] 만 14세 미만인데 보호자 인증이 완료되지 않았으면 다음 단계 진행 차단
  bool get _canProceedToNextStep {
    if (_selectedBirthDate == null) return false; // 생년월일 미입력 시 진행 불가
    if (_isUnder14) {
      return _isParentVerified && parentConsent; // 보호자 인증 + 동의 체크 모두 필요
    }
    return true;
  }

  // 🆕 [법적 필수 수정] 생년월일 선택 다이얼로그
  Future<void> _pickBirthDate() async {
    const Color brandGolden = Color(0xFFE5C158);
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 15, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: brandGolden,
              onPrimary: Color(0xFF030712),
              surface: Color(0xFF0D1527),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        // 생년월일이 바뀌면 이전 보호자 인증 상태는 초기화 (안전을 위한 재검증 요구)
        _isParentAuthSent = false;
        _isParentVerified = false;
        parentConsent = false;
        _parentAuthCodeController.clear();
      });
    }
  }

  String get _birthDateDisplayText {
    if (_selectedBirthDate == null) return '';
    final y = _selectedBirthDate!.year.toString();
    final m = _selectedBirthDate!.month.toString().padLeft(2, '0');
    final d = _selectedBirthDate!.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // 🚨 [법적 필수사항] 아래 보호자 인증번호 발송/확인 함수는 현재 UI 목업(시뮬레이션)입니다.
  // 실제 스토어 출시 전 반드시 실서버(SMS 발송 API 또는 이메일 발송 API)와 연동하여
  // 진짜 인증번호를 발송하고 서버에서 검증하는 로직으로 교체해야 법적 효력이 발생합니다.
  void _sendParentAuthCode() {
    if (_parentEmailController.text.trim().isEmpty && _parentPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dkeInline(DkeLang.snackParentContactMissingMap),
            style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }
    setState(() => _isParentAuthSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          dkeInline(DkeLang.snackParentCodeSentMap),
          style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _verifyParentAuthCode() {
    if (_parentAuthCodeController.text.trim().length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dkeInline(DkeLang.snackInvalidCodeMap),
            style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }
    setState(() => _isParentVerified = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          dkeInline(DkeLang.snackParentVerifiedMap),
          style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ✅ 학부모 대시보드 진입 함수 (build 밖으로 분리)
  void _goToParentDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParentMainDashboardScreen(
          parentEmail: _emailController.text.isNotEmpty
              ? _emailController.text
              : "parent@test.com",
          childName: _nameController.text.isNotEmpty
              ? _nameController.text
              : "홍길동",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color brandGolden = Color(0xFFE5C158);

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: dkeColumnLines(
            DkeLang.signupHeadingMap,
            enStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 23, letterSpacing: 1.0, color: brandGolden),
            koStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandGolden),
            gapHeight: 15,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 환영 패널
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1527),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: brandGolden.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Text(
                DkeLang.welcomeOverlay, // 🆕 [12개국 다국어] 로그인 화면과 동일한 환영 문구 재사용
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ),

            // 3단 토글 버튼
            Container(
              height: 55,
              decoration: BoxDecoration(
                color: const Color(0xFF0D1527),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildToggleButton(
                    map: DkeLang.toggleStudentMap,
                    active: isStudent && !isGeneral,
                    onTap: () => setState(() {
                      isStudent = true;
                      isGeneral = false;
                    }),
                  ),
                  _buildToggleButton(
                    map: DkeLang.toggleParentMap,
                    active: !isStudent && !isGeneral,
                    onTap: () => setState(() {
                      isStudent = false;
                      isGeneral = false;
                    }),
                  ),
                  _buildToggleButton(
                    map: DkeLang.toggleGeneralMap,
                    active: !isStudent && isGeneral,
                    onTap: () => setState(() {
                      isStudent = false;
                      isGeneral = true;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 공통 입력 필드
            _buildInputField(hint: dkeInline(DkeLang.hintNationalityMap), icon: Icons.public, controller: _nationalityController),
            _buildInputField(hint: dkeInline(DkeLang.hintFullNameMap), icon: Icons.person, controller: _nameController),

            // 🆕 [법적 필수 수정] 생년월일 입력 필드 - 모든 가입 유형(학생/학부모/일반) 공통 적용
            // 자진 체크박스가 아닌, 실제 생년월일로 만 14세 미만 여부를 자동 판별합니다.
            GestureDetector(
              onTap: _pickBirthDate,
              child: AbsorbPointer(
                child: _buildInputField(
                  hint: dkeInline(DkeLang.hintBirthDateMap),
                  icon: Icons.cake_outlined,
                  controller: TextEditingController(text: _birthDateDisplayText),
                  suffixIcon: const Icon(Icons.calendar_today, color: Colors.white38, size: 18),
                ),
              ),
            ),

            // 이메일 + 인증 버튼
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    hint: dkeInline(DkeLang.hintEmailMap),
                    icon: Icons.email,
                    controller: _emailController,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => isEmailSent = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            dkeInline(DkeLang.snackCodeSentMap),
                            style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandGolden,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: dkeBilineText(
                      DkeLang.btnAuthMap,
                      const TextStyle(color: Color(0xFF030712), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            if (isEmailSent) ...[
              _buildInputField(
                hint: dkeInline(DkeLang.hintEmailAuthCodeMap),
                icon: Icons.lock_clock,
                controller: _emailAuthOpacityController,
              ),
            ],

            _buildInputField(hint: dkeInline(DkeLang.hintPhoneMap), icon: Icons.phone, controller: _phoneController),

            _buildInputField(
              hint: dkeInline(DkeLang.hintPasswordMap),
              icon: Icons.lock,
              controller: _passwordController,
              isPassword: true,
              suffixIcon: IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white38,
                ),
                onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
              ),
              hideText: !isPasswordVisible,
            ),

            _buildInputField(
              hint: dkeInline(DkeLang.hintConfirmPasswordMap),
              icon: Icons.lock_outline,
              controller: _confirmPasswordController,
              isPassword: true,
              hideText: !isPasswordVisible,
            ),

            // 학생 전용 필드
            if (isStudent && !isGeneral) ...[
              _buildInputField(hint: dkeInline(DkeLang.hintSchoolMap), icon: Icons.school, controller: _schoolController),
              _buildInputField(hint: dkeInline(DkeLang.hintGradeMap), icon: Icons.grade, controller: _gradeController),
              _buildInputField(hint: dkeInline(DkeLang.hintClassCodeMap), icon: Icons.qr_code, controller: _classCodeController),
            ],

            // 학부모 전용 필드
            if (!isStudent && !isGeneral) ...[
              _buildInputField(hint: dkeInline(DkeLang.hintChildEmailMap), icon: Icons.child_care, controller: _childEmailController),
              _buildInputField(hint: dkeInline(DkeLang.hintRelationshipMap), icon: Icons.family_restroom, controller: _relationshipController),
            ],

            const SizedBox(height: 10),

            // 🆕 [법적 필수 수정] 생년월일 기반 자동 판정 결과 안내 배너 (모든 가입 유형 공통)
            if (_selectedBirthDate != null && _isUnder14) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: brandGolden.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: brandGolden.withValues(alpha: 0.3)),
                ),
                child: dkeBilingualRich(
                  DkeLang.bannerUnder14Map,
                  enStyle: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                  koStyle: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),

              // 🆕 [법적 필수 수정] 보호자 실제 인증 블록 - 아이가 셀프 체크하는 방식이 아니라
              // 보호자 연락처를 입력받아 인증번호를 발송/확인하는 실제 검증 절차
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: brandGolden.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: brandGolden.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DkeLang.isForeignSelected
                          ? (DkeLang.parentalTitleMap[DkeLang.current] ?? DkeLang.parentalTitleMap['EN']!)
                          : '${DkeLang.parentalTitleMap['EN']}\n(${DkeLang.parentalTitleMap['KO']})',
                      style: GoogleFonts.notoSansKr(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 23),
                    ),
                    const SizedBox(height: 5),
                    dkeBilingualRich(
                      DkeLang.parentalDescMap,
                      enStyle: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600),
                      koStyle: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),

                    // 보호자 이메일 입력
                    _buildInputField(
                      hint: dkeInline(DkeLang.hintParentEmailMap),
                      icon: Icons.email_outlined,
                      controller: _parentEmailController,
                    ),
                    // 보호자 전화번호 입력
                    _buildInputField(
                      hint: dkeInline(DkeLang.hintParentPhoneMap),
                      icon: Icons.phone_iphone,
                      controller: _parentPhoneController,
                    ),

                    // 인증번호 발송 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isParentVerified ? null : _sendParentAuthCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandGolden,
                          disabledBackgroundColor: Colors.white10,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _isParentVerified
                              ? dkeInline(DkeLang.btnParentVerifiedMap)
                              : dkeInline(DkeLang.btnSendCodeToParentMap),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.gowunBatang(
                            color: _isParentVerified ? Colors.white38 : const Color(0xFF030712),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // 인증번호 입력 + 확인 버튼 (인증번호 발송 후에만 노출)
                    if (_isParentAuthSent && !_isParentVerified) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              hint: dkeInline(DkeLang.hintParentAuthCodeMap),
                              icon: Icons.lock_clock,
                              controller: _parentAuthCodeController,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _verifyParentAuthCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandGolden,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: dkeBilineText(
                                DkeLang.btnVerifyMap,
                                const TextStyle(color: Color(0xFF030712), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // 최종 동의 체크박스 - 보호자 인증이 완료된 후에만 체크 가능하도록 제한
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: dkeBilingualRich(
                        DkeLang.checkboxParentConsentMap,
                        enStyle: TextStyle(
                          color: _isParentVerified ? Colors.white : Colors.white24,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        koStyle: TextStyle(
                          color: _isParentVerified ? Colors.white : Colors.white24,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      value: parentConsent,
                      // 🆕 [법적 필수 수정] 보호자 인증(_isParentVerified)이 완료되기 전에는
                      // 이 체크박스를 아예 누를 수 없도록 비활성화 (셀프 체크 우회 원천 차단)
                      onChanged: _isParentVerified
                          ? (val) => setState(() => parentConsent = val!)
                          : null,
                      activeColor: brandGolden,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            // NEXT STEP 버튼
            // 🆕 [법적 필수 수정] 생년월일 미입력 또는 (만14세미만인데 보호자 인증/동의 미완료) 시 버튼 비활성화
            ElevatedButton(
              onPressed: _canProceedToNextStep
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TermsAgreementScreen()),
                );
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGolden,
                disabledBackgroundColor: Colors.white10,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: dkeColumnLines(
                  DkeLang.btnNextStepMap,
                  enStyle: TextStyle(
                    color: _canProceedToNextStep ? const Color(0xFF030712) : Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  koStyle: TextStyle(
                    color: _canProceedToNextStep ? const Color(0xFF030712) : Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            // 🆕 [법적 필수 수정] 진행 불가 사유를 사용자에게 안내 (생년월일 미입력 또는 보호자 인증 미완료)
            if (!_canProceedToNextStep) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: dkeBilingualRich(
                  _selectedBirthDate == null ? DkeLang.hintNeedBirthDateMap : DkeLang.hintNeedParentVerifyMap,
                  enStyle: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
                  koStyle: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ✅ 임시 학부모 대시보드 진입 버튼
            ElevatedButton(
              onPressed: _goToParentDashboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A5F),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: dkeColumnLines(
                  DkeLang.btnParentLoginTempMap,
                  enStyle: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 18),
                  koStyle: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required Map<String, String> map,
    required bool active,
    required VoidCallback onTap,
  }) {
    const Color brandGolden = Color(0xFFE5C158);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? brandGolden : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: dkeBilineText(
            map,
            TextStyle(
              color: active ? const Color(0xFF030712) : Colors.white60,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    Widget? suffixIcon,
    bool hideText = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1527),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? hideText : false,
        style: GoogleFonts.gowunBatang(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFFE5C158), size: 20),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: GoogleFonts.gowunBatang(
            color: Colors.white38,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------
// 약관 동의 화면
// 🆕 [12개국 다국어 연동] 2026-07-29 수정: 전체 텍스트 DkeLang 게터/맵으로 교체.
// 디자인/레이아웃/색상/폰트/크기는 100% 원본 동일 유지.
// -----------------------------------------------------------------------
class TermsAgreementScreen extends StatefulWidget {
  const TermsAgreementScreen({super.key});

  @override
  State<TermsAgreementScreen> createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  bool isAgreed = false;

  @override
  Widget build(BuildContext context) {
    const Color brandGolden = Color(0xFFE5C158);

    // 🆕 [12개국 다국어 연동] 약관 섹션 제목/본문 맵 쌍 목록
    final List<List<Map<String, String>>> sections = [
      [DkeLang.terms1TitleMap, DkeLang.terms1BodyMap],
      [DkeLang.terms2TitleMap, DkeLang.terms2BodyMap],
      [DkeLang.terms3TitleMap, DkeLang.terms3BodyMap],
      [DkeLang.terms4TitleMap, DkeLang.terms4BodyMap],
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: dkeColumnLines(
            DkeLang.termsHeadingMap,
            enStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 23, color: brandGolden),
            koStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: brandGolden),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            dkeBilingualRich(
              DkeLang.termsIntroMap,
              enStyle: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, height: 1.5),
              koStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, height: 1.5),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1527),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: SingleChildScrollView(
                  child: DkeLang.isForeignSelected
                  // 🆕 [12개국 다국어] 10개국어 선택시: 번역 본문만 하나의 텍스트로 표시 (notoSans 폰트)
                      ? Text(
                    sections
                        .map((pair) =>
                    '${pair[0][DkeLang.current] ?? pair[0]['EN']}\n${pair[1][DkeLang.current] ?? pair[1]['EN']}')
                        .join('\n\n'),
                    style: GoogleFonts.notoSans(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, height: 1.6),
                  )
                  // 기본모드(EN+KO): 원본과 동일하게 각 섹션마다 EN(gowunBatang)/KO(notoSansKr) TextSpan 반복 구성
                      : RichText(
                    text: TextSpan(
                      style: const TextStyle(height: 1.6),
                      children: [
                        TextSpan(
                          text: "[Terms & Privacy Policy / 이용약관 및 개인정보 처리방침]\n\n",
                          style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        for (final pair in sections) ...[
                          TextSpan(
                            text: "${pair[0]['EN']}\n",
                            style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: "(${pair[0]['KO']})\n",
                            style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: "${pair[1]['EN']}\n",
                            style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: "(${pair[1]['KO']})\n\n",
                            style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            CheckboxListTile(
              title: dkeBilingualRich(
                DkeLang.checkboxAgreeAllMap,
                enStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                koStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              value: isAgreed,
              onChanged: (val) => setState(() => isAgreed = val!),
              activeColor: brandGolden,
              checkColor: const Color(0xFF030712),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isAgreed
                  ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      dkeInline(DkeLang.snackRegistrationCompleteMap),
                      style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                );
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGolden,
                disabledBackgroundColor: Colors.white10,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: dkeColumnLines(
                  DkeLang.btnSignupCompleteMap,
                  enStyle: const TextStyle(color: Color(0xFF030712), fontWeight: FontWeight.bold, fontSize: 18),
                  koStyle: const TextStyle(color: Color(0xFF030712), fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
