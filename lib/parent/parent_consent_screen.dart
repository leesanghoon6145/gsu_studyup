import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/family_link_service.dart';

// ============================================================================
// 🆕 [보호자 인증 전용 2026-09-21] 만 14세 미만 학생이 회원가입 도중 발급받은
// 6자리 코드를, 부모가 로그인 여부와 무관하게 입력해서 "확인했다"고 표시하는 화면.
// 학생 코드 시스템(links 컬렉션)과 완전히 분리된 parentConsentCodes 컬렉션 사용.
// ============================================================================
class ParentConsentScreen extends StatefulWidget {
  const ParentConsentScreen({super.key});

  @override
  State<ParentConsentScreen> createState() => _ParentConsentScreenState();
}

class _ParentConsentScreenState extends State<ParentConsentScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isSubmitting = false;
  bool? _success; // null = 아직 시도 안 함, true = 성공, false = 실패

  static const Color brandGolden = Color(0xFFE5C158);

  Future<void> _submitCode() async {
    final String code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _success = false);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _success = null;
    });

    final bool ok = await FamilyLinkService.confirmConsentCode(code);

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _success = ok;
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '보호자 확인 / Parent Verification',
          style: GoogleFonts.notoSansKr(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.family_restroom_rounded, color: brandGolden, size: 48),
              const SizedBox(height: 20),
              Text(
                '자녀가 알려준 6자리 코드를 입력해주세요',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter the 6-digit code your child gave you',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(color: Colors.white, fontSize: 28, letterSpacing: 6, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFF0D1527),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: brandGolden.withOpacity(0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: brandGolden, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_success == true) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '확인되었습니다! 이제 자녀의 가입 화면으로 돌아가 계속 진행해주세요.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansKr(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ] else if (_success == false) ...[
                Text(
                  '코드를 다시 확인해주세요 (6자리 숫자)',
                  style: GoogleFonts.notoSansKr(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
              ],
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGolden,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF030712)))
                      : Text('확인 / Confirm', style: GoogleFonts.notoSansKr(color: const Color(0xFF030712), fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}