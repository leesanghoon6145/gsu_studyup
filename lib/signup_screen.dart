import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // 1. 상태 관리 변수
  bool isStudent = true;
  bool isUnder14 = false;
  bool parentConsent = false;
  bool isEmailSent = false;
  bool isPasswordVisible = false; // 🔥 비밀번호 숨김/보임 상태

  // 입력 컨트롤러
  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _emailAuthOpacityController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();

  // 🔥 새로 추가된 컨트롤러
  final TextEditingController _classCodeController = TextEditingController(); // 학생용 클래스 코드
  final TextEditingController _childEmailController = TextEditingController(); // 학부모용 자녀 이메일
  final TextEditingController _relationshipController = TextEditingController(); // 학부모용 관계

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712), // 진한 밤하늘 배경
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SIGNUP (회원가입)',
          style: GoogleFonts.gowunBatang(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 2. 학생/학부모 통합 토글 버튼
            Container(
              height: 55,
              decoration: BoxDecoration(
                color: const Color(0xFF0D1527),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildToggleButton(title: 'STUDENT (학생)', active: isStudent, onTap: () => setState(() => isStudent = true)),
                  _buildToggleButton(title: 'PARENT (학부모)', active: !isStudent, onTap: () => setState(() => isStudent = false)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 3. 무조건 보여주는 공통 정보 (국적 -> 이름 -> 이메일 -> 전화번호)
            _buildInputField(hint: 'Nationality (국적)', icon: Icons.public, controller: _nationalityController),
            _buildInputField(hint: 'Full Name (본인 이름)', icon: Icons.person, controller: _nameController),

            // 이메일 및 인증 레이아웃
            Row(
              children: [
                Expanded(
                  child: _buildInputField(hint: 'Email Address (이메일 주소)', icon: Icons.email, controller: _emailController),
                ),
                const SizedBox(width: 10),
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isEmailSent = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verification code sent! (인증번호가 발송되었습니다!)')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFCD34D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('AUTH (인증)', style: TextStyle(color: Color(0xFF030712), fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),

            if (isEmailSent) ...[
              _buildInputField(hint: 'Verification Code (인증번호 6자리 입력)', icon: Icons.lock_clock, controller: _emailAuthOpacityController),
            ],

            _buildInputField(hint: 'Phone Number (전화번호)', icon: Icons.phone, controller: _phoneController),

            // 🔥 눈동자 토글 기능이 들어간 비밀번호 입력창
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
              hideText: !isPasswordVisible, // 동일하게 연동
            ),

            // -------------------------------------------------------------------
            // 4-1. 🔥 STUDENT (학생) 전용 추가 입력 필드 (학교, 학년, 클래스 코드)
            // -------------------------------------------------------------------
            if (isStudent) ...[
              _buildInputField(hint: 'School Name (학교명)', icon: Icons.school, controller: _schoolController),
              _buildInputField(hint: 'Grade (학년)', icon: Icons.grade, controller: _gradeController),
              _buildInputField(hint: 'Class Code (클래스 코드 - 선택입력)', icon: Icons.qr_code, controller: _classCodeController), // 🔥 추가
            ],

            // -------------------------------------------------------------------
            // 4-2. 🔥 PARENT (학부모) 전용 추가 입력 필드 (자녀 이메일, 관계)
            // -------------------------------------------------------------------
            if (!isStudent) ...[
              _buildInputField(hint: "Child's Email (연동할 자녀 이메일 주소)", icon: Icons.child_care, controller: _childEmailController), // 🔥 추가
              _buildInputField(hint: 'Relationship to Child (자녀와의 관계 - 예: 부/모)', icon: Icons.family_restroom, controller: _relationshipController), // 🔥 추가
            ],

            const SizedBox(height: 10),

            // 5. 14세 미만 보호 로직 (학생일 때만 작동)
            if (isStudent) ...[
              Row(
                children: [
                  Checkbox(
                    value: isUnder14,
                    onChanged: (val) => setState(() => isUnder14 = val!),
                    activeColor: const Color(0xFFFCD34D),
                    side: const BorderSide(color: Colors.white38),
                  ),
                  const Flexible(
                    child: Text(
                      'I am under 14 years old.\n(만 14세 미만 청소년입니다.)',
                      style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              if (isUnder14) ...[
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 10),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCD34D).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCD34D).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Parental Consent Required (보호자 동의 필수)',
                        style: TextStyle(color: Color(0xFFFCD34D), fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'In accordance with international regulations (COPPA/GDPR), parental consent must be verified.\n(국제법 규정에 따라 보호자의 동의가 확인되어야 가입이 가능합니다.)',
                        style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'I confirm parental consent. (보호자 동의를 확인했습니다.)',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        value: parentConsent,
                        onChanged: (val) => setState(() => parentConsent = val!),
                        activeColor: const Color(0xFFFCD34D),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ],
            ],

            const SizedBox(height: 30),

            // 6. 다음 단계 버튼
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TermsAgreementScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFCD34D),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'NEXT STEP (다음 단계로)',
                style: TextStyle(color: Color(0xFF030712), fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 토글 버튼 부품 위젯
  Widget _buildToggleButton({
    required String title,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFCD34D) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: active ? const Color(0xFF030712) : Colors.white60,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  // 입력 필드 부품 위젯 (눈동자 버튼 탑재할 수 있도록 업그레이드)
  Widget _buildInputField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    Widget? suffixIcon,  // 🔥 우측 눈동자 아이콘용 변수 추가
    bool hideText = false, // 🔥 글자 숨김 여부 변수 추가
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
        obscureText: isPassword ? hideText : false, // 비밀번호 모드일 때만 적용
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFFFCD34D), size: 20),
          suffixIcon: suffixIcon, // 🔥 우측 아이콘 배치
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.white38,
            fontSize: 16,
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
// 7. 화면 2: 약관 동의 화면 (TermsAgreementScreen)
// -----------------------------------------------------------------------
class TermsAgreementScreen extends StatefulWidget {
  const TermsAgreementScreen({Key? key}) : super(key: key);

  @override
  State<TermsAgreementScreen> createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  bool isAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'TERMS AGREEMENT (이용약관 동의)',
          style: GoogleFonts.gowunBatang(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Please read and agree to the terms to use GSU STUDYUP.\n(GSU STUDYUP 서비스 이용을 위해 약관을 읽고 동의해 주세요.)',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.5),
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
                child: const SingleChildScrollView(
                  child: Text(
                    "[Terms & Privacy Policy / 이용약관 및 개인정보 처리방침]\n\n1. Purpose (목적)\nThis agreement outlines the terms and procedures for using GSU STUDYUP services.\n(본 약관은 GSU STUDYUP 서비스의 이용 조건 및 절차를 규정합니다.)\n\n2. International Law Compliance (국제법 준수)\nThis service strictly complies with EU GDPR and US COPPA. Parental consent is mandatory for collecting data of users under 14.\n(본 서비스는 유럽 GDPR 및 미국 COPPA 규정을 준수하며, 14세 미만 아동의 데이터 보호를 위해 법정대리인의 동의를 필수적으로 수집합니다.)\n\n3. Data Collection Items (수집 항목)\nNationality, Full Name, email, phone number, school name, and grade are collected solely for personalized study reporting.\n(국적, 이름, 이메일, 전화번호, 학교, 학년 정보를 수집하며 이는 학습 리포트 제공 목적으로만 사용됩니다.)\n\n4. Data Security & Rights (데이터 보안)\nAll information is securely encrypted (AES-256) and users retain the right to request deletion at any time.\n(모든 정보는 암호화되어 안전하게 관리되며, 사용자는 언제든 삭제를 요청할 수 있습니다.)",
                    style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.6, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            CheckboxListTile(
              title: const Text(
                'I have read and agree to all terms above.\n(위 약관의 내용을 모두 읽었으며 동의합니다.)',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              value: isAgreed,
              onChanged: (val) => setState(() => isAgreed = val!),
              activeColor: const Color(0xFFFCD34D),
              checkColor: const Color(0xFF030712),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isAgreed ? () {
                // 1. 가입 완료 메시지 띄우기
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Registration Complete! (회원가입이 완료되었습니다!)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                );

                // 2. 🔥 [완벽 수정] 약관 화면과 가입 화면을 연속으로 닫아 '로그인 화면'으로 정확히 복귀!
                int count = 0;
                Navigator.of(context).popUntil((route) {
                  return count++ >= 2; // 정확히 2개의 화면만 걷어내고 로그인 화면을 보여줍니다.
                });
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFCD34D),
                disabledBackgroundColor: Colors.white10,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'SIGNUP COMPLETE (가입 완료)',
                style: TextStyle(
                  color: Color(0xFF030712),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}