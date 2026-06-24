import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'parent/parent_main_dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool isStudent = true;
  bool isGeneral = false;
  bool isUnder14 = false;
  bool parentConsent = false;
  bool isEmailSent = false;
  bool isPasswordVisible = false;

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
          children: [
            Text(
              'SIGNUP',
              textAlign: TextAlign.center,
              style: GoogleFonts.gowunBatang(
                color: brandGolden,
                fontWeight: FontWeight.bold,
                fontSize: 23,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              '(회원가입)',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(
                color: brandGolden,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
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
                "Welcome to GKE STUDYUP! ( GKE STUDYUP에 들어 오신것을 환영합니다 )",
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
                    title: 'STUDENT\n(학생)',
                    active: isStudent && !isGeneral,
                    onTap: () => setState(() {
                      isStudent = true;
                      isGeneral = false;
                    }),
                  ),
                  _buildToggleButton(
                    title: 'PARENT\n(학부모)',
                    active: !isStudent && !isGeneral,
                    onTap: () => setState(() {
                      isStudent = false;
                      isGeneral = false;
                    }),
                  ),
                  _buildToggleButton(
                    title: 'GENERAL\n(일반)',
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
            _buildInputField(hint: 'Nationality (국적)', icon: Icons.public, controller: _nationalityController),
            _buildInputField(hint: 'Full Name (본인 이름)', icon: Icons.person, controller: _nameController),

            // 이메일 + 인증 버튼
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    hint: 'Email Address (이메일 주소)',
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
                            'Verification code sent!\n(인증번호가 발송되었습니다!)',
                            style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandGolden,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'AUTH\n(인증)',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.gowunBatang(
                        color: const Color(0xFF030712),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (isEmailSent) ...[
              _buildInputField(
                hint: 'Verification Code (인증번호 6자리 입력)',
                icon: Icons.lock_clock,
                controller: _emailAuthOpacityController,
              ),
            ],

            _buildInputField(hint: 'Phone Number (전화번호)', icon: Icons.phone, controller: _phoneController),

            _buildInputField(
              hint: 'Password (비밀번호)',
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
              hint: 'Confirm Password (비밀번호 확인)',
              icon: Icons.lock_outline,
              controller: _confirmPasswordController,
              isPassword: true,
              hideText: !isPasswordVisible,
            ),

            // 학생 전용 필드
            if (isStudent && !isGeneral) ...[
              _buildInputField(hint: 'School Name (학교명)', icon: Icons.school, controller: _schoolController),
              _buildInputField(hint: 'Grade (학년)', icon: Icons.grade, controller: _gradeController),
              _buildInputField(hint: 'Class Code (클래스 코드 - 선택입력)', icon: Icons.qr_code, controller: _classCodeController),
            ],

            // 학부모 전용 필드
            if (!isStudent && !isGeneral) ...[
              _buildInputField(hint: "Child's Email (연동할 자녀 이메일 주소)", icon: Icons.child_care, controller: _childEmailController),
              _buildInputField(hint: 'Relationship to Child (자녀와의 관계 - 예: 부/모)', icon: Icons.family_restroom, controller: _relationshipController),
            ],

            const SizedBox(height: 10),

            // 14세 미만 체크박스
            if (isStudent && !isGeneral) ...[
              Row(
                children: [
                  Checkbox(
                    value: isUnder14,
                    onChanged: (val) => setState(() => isUnder14 = val!),
                    activeColor: brandGolden,
                    side: const BorderSide(color: Colors.white38),
                  ),
                  Flexible(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'I am under 14 years old.\n',
                            style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: '(만 14세 미만 청소년입니다.)',
                            style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (isUnder14) ...[
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 10),
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
                        'Parental Consent Required\n(보호자 동의 필수)',
                        style: GoogleFonts.notoSansKr(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 23),
                      ),
                      const SizedBox(height: 5),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'In accordance with international regulations (COPPA/GDPR), parental consent must be verified.\n',
                              style: GoogleFonts.gowunBatang(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            TextSpan(
                              text: '(국제법 규정에 따라 보호자의 동의가 확인되어야 가입이 가능합니다.)',
                              style: GoogleFonts.notoSansKr(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'I confirm parental consent.\n',
                                style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: '(보호자 동의를 확인했습니다.)',
                                style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        value: parentConsent,
                        onChanged: (val) => setState(() => parentConsent = val!),
                        activeColor: brandGolden,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ],
            ],

            const SizedBox(height: 30),

            // NEXT STEP 버튼
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TermsAgreementScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGolden,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'NEXT STEP',
                    style: GoogleFonts.gowunBatang(
                      color: const Color(0xFF030712),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '(다음 단계로)',
                    style: GoogleFonts.notoSansKr(
                      color: const Color(0xFF030712),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

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
                children: [
                  Text(
                    'PARENT LOGIN (임시)',
                    style: GoogleFonts.gowunBatang(
                      color: const Color(0xFF38BDF8),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '(학부모 대시보드 진입)',
                    style: GoogleFonts.notoSansKr(
                      color: const Color(0xFF38BDF8),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String title,
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
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.gowunBatang(
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

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TERMS AGREEMENT',
              textAlign: TextAlign.center,
              style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 23),
            ),
            Text(
              '(이용약관 동의)',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Please read and agree to the terms to use GKE STUDYUP.\n',
                    style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, height: 1.5),
                  ),
                  TextSpan(
                    text: '(GKE STUDYUP 서비스 이용을 위해 약관을 읽고 동의해 주세요.)',
                    style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, height: 1.5),
                  ),
                ],
              ),
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
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(height: 1.6),
                      children: [
                        TextSpan(
                          text: "[Terms & Privacy Policy / 이용약관 및 개인정보 처리방침]\n\n1. Purpose\n",
                          style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: "(목적)\n",
                          style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: "This agreement outlines the terms and procedures for using GKE STUDYUP services.\n",
                          style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: "(본 약관은 GKE STUDYUP 서비스의 이용 조건 및 절차를 규정합니다.)\n\n",
                          style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: "2. International Law Compliance\n",
                          style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: "(국제법 준수)\n",
                          style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: "This service strictly complies with EU GDPR and US COPPA. Parental consent is mandatory for collecting data of users under 14.\n",
                          style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: "(본 서비스는 유럽 GDPR 및 미국 COPPA 규정을 준수하며, 14세 미만 아동의 데이터 보호를 위해 법정대리인의 동의를 필수적으로 수집합니다.)\n\n",
                          style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: "3. Data Collection Items\n",
                          style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: "(수집 항목)\n",
                          style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: "Nationality, Full Name, email, phone number, school name, and grade are collected solely for personalized study reporting.\n",
                          style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: "(국적, 이름, 이메일, 전화번호, 학교, 학년 정보를 수집하며 이는 학습 리포트 제공 목적으로만 사용됩니다.)\n\n",
                          style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: "4. Data Security & Rights\n",
                          style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: "(데이터 보안)\n",
                          style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: "All information is securely encrypted (AES-256) and users retain the right to request deletion at any time.\n",
                          style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: "(모든 정보는 암호화되어 안전하게 관리되며, 사용자는 언제든 삭제를 요청할 수 있습니다.)",
                          style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            CheckboxListTile(
              title: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'I have read and agree to all terms above.\n',
                      style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: '(위 약관의 내용을 모두 읽었으며 동의합니다.)',
                      style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
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
                      'Registration Complete! (회원가입이 완료되었습니다!)',
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
                children: [
                  Text(
                    'SIGNUP COMPLETE',
                    style: GoogleFonts.gowunBatang(
                      color: const Color(0xFF030712),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '(가입 완료)',
                    style: GoogleFonts.notoSansKr(
                      color: const Color(0xFF030712),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
