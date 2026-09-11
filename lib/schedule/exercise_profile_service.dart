// exercise_profile_service.dart
//
// 🆕 [개인정보 - 칼로리 계산용] ExerciseProfileService
//
// 칼로리 계산 공식(MET × 몸무게 × 시간)에는 몸무게가 필요한데, 지금까지는
// 평균값(65kg)으로 고정해서 추정해왔다. 실제 사용자 몸무게를 입력받아서
// 정확도를 높이기 위한 저장소.
//
// ⚠️ [개인정보 처리 원칙] 이 값은 오직 이 기기(폰) 안의 SharedPreferences에만
// 저장되며, 서버로 전송되거나 다른 곳에 공유되지 않는다. 오직 칼로리 계산
// 수식에만 쓰인다. 입력은 완전히 선택사항이며(입력 안 하면 평균값 65kg으로
// 계속 계산됨), 언제든 지우거나 바꿀 수 있다.
import 'package:shared_preferences/shared_preferences.dart';

class ExerciseProfileService {
  ExerciseProfileService._();

  static const String _kWeightKey = 'gke_exercise_body_weight_kg';
  static const double defaultWeightKg = 65.0; // 입력 안 했을 때 쓰는 평균 추정값

  /// 저장된 몸무게(kg). 입력한 적 없으면 null.
  static Future<double?> getWeightKg() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kWeightKey);
  }

  /// 칼로리 계산에 바로 쓸 몸무게. 입력 안 했으면 평균값(65kg)으로 대체.
  static Future<double> getWeightKgOrDefault() async {
    final v = await getWeightKg();
    return v ?? defaultWeightKg;
  }

  static Future<void> setWeightKg(double weightKg) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kWeightKey, weightKg);
  }

  /// 🆕 [삭제 기능] 입력했던 몸무게를 지우고 평균값으로 되돌림 - 개인정보는
  /// 언제든 삭제할 수 있어야 한다는 원칙.
  static Future<void> clearWeightKg() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kWeightKey);
  }
}
