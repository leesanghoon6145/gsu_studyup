import 'package:firebase_auth/firebase_auth.dart';

// 실제 로그인/회원가입을 담당하는 서비스 (단일 게이트웨이 패턴)
// Firebase Authentication과 직접 통신하는 곳은 이 파일 하나뿐입니다.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // 현재 로그인된 사용자 (없으면 null)
  static User? get currentUser => _auth.currentUser;

  // 로그인 상태 실시간 감지 (자동 로그인 유지 등에 활용 가능)
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // [회원가입] 이메일/비밀번호로 진짜 계정 생성. 실패 시 한국어 에러 메시지를 던짐.
  static Future<User?> signUp({required String email, required String password}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  // [로그인] 이메일/비밀번호 검증. 실패 시 한국어 에러 메시지를 던짐.
  static Future<User?> signIn({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  static Future<void> signOut() => _auth.signOut();

  // 🆕 [A안: 공식 이메일 인증] 방금 가입한 계정으로 인증 링크가 담긴 이메일을 발송
  static Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  // 🆕 [A안] 서버에서 최신 인증 상태를 다시 불러와서, 사용자가 메일의 링크를 눌렀는지 확인
  static Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // 🆕 [비밀번호를 잊어버렸을 때] 이것도 완전 무료 공식 기능 (재설정 링크 이메일 발송)
  static Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  // Firebase의 영어 에러 코드를 사용자에게 보여줄 한국어 문구로 변환
  static String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return '이미 가입된 이메일입니다.';
      case 'invalid-email':
        return '이메일 형식이 올바르지 않습니다.';
      case 'weak-password':
        return '비밀번호가 너무 약합니다. 6자 이상 입력하세요.';
      case 'user-not-found':
        return '가입되지 않은 이메일입니다.';
      case 'wrong-password':
      case 'invalid-credential':
        return '이메일 또는 비밀번호가 올바르지 않습니다.';
      case 'too-many-requests':
        return '너무 많이 시도했습니다. 잠시 후 다시 시도하세요.';
      case 'network-request-failed':
        return '인터넷 연결을 확인해주세요.';
      default:
        return '오류가 발생했습니다. (${e.code})';
    }
  }
}
