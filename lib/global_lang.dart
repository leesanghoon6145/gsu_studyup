import 'package:shared_preferences/shared_preferences.dart';

class DkeLang {
  // 👑 [DKE 언어 중앙 제어 스위치]: 기본값은 한국어('KO')
  static String current = 'KO';

  // 👑 [국적 데이터 로드 엔진]: 앱이 켜질 때 저장된 국적 정보를 가져옴
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedLang = prefs.getString('user_country');
      if (savedLang != null && savedLang.isNotEmpty) {
        current = savedLang;
      }
    } catch (e) {
      current = 'KO'; // 에러 발생 시 한국어 기본 모드로 안전하게 방어
    }
  }

  // 👑 [국적 변경 스위치]: 유저가 언어를 바꿀 때 즉시 기기에 저장
  static Future<void> setLanguage(String langCode) async {
    current = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_country', langCode);
  }

  // =========================================================================
  // 🎯 [DKE 9개 챕터 통합 언어 매핑 사전]
  // =========================================================================

  // 공통 타이틀 및 상단 정보 벨트 (지시하신 글자 크기 23 철칙 적용 구역)
  static String get schoolInfo => current == 'KO' ? "GSU고등학교 2학년 이제임스" : "GSU High School 2nd Grade - James Lee";
  static String get memberAchievementTitle => current == 'KO' ? "동시 접속자" : "Simultaneous Users"; // 🚨 동시접속자 타이틀 수정 반영!
  static String get currentLearnersMsg => current == 'KO' ? "(현재도 전국 전 세계 사람들 학습중입니다.)" : "(People all over the world are studying right now.)";

  // 팝업 및 알림문구 챕터
  static String get stopLearningAlert => current == 'KO' ? "학습을 중단하시겠습니까?" : "Are you sure you want to stop learning?";
  static String get targetAchievedSuccess => current == 'KO' ? "수고 하셨습니다. 학습 목표를 성공적으로 달성 하였습니다." : "Good job! You have successfully achieved your learning goals.";
}