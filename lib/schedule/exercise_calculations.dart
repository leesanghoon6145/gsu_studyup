// exercise_calculations.dart
//
// exercise_type_data.dart에서 isCalculated: true로 표시한 필드들의 실제 계산 로직.
// UI(today_exercise_screen 등)에서 사용자가 원본 값(거리/시간/세트 등)을 입력하면
// 이 파일의 함수로 계산된 값을 detail 맵에 채워 넣는다.
//
// 계산 공식 출처:
// - 추정 1RM: Epley 공식 (1RM = weight × (1 + reps/30)) — 스트렝스 트레이닝 표준 공식
// - SWOLF: 25m 기준 (시간(초) + 스트로크수) — MySwimPro 등 표준 정의
// - 페이스/평균속도: 거리/시간 기반 표준 계산

import 'exercise_models.dart';

/// 러닝/걷기: 분/km 페이스 계산.
/// 예) 5km를 40분에 뛰었다면 -> 8.0 (분/km)
double calcPaceMinPerKm({required double distanceKm, required int durationMin}) {
  if (distanceKm <= 0) return 0;
  return durationMin / distanceKm;
}

/// 자전거: 평균속도(km/h) 계산.
double calcAvgSpeedKmh({required double distanceKm, required int durationMin}) {
  if (durationMin <= 0) return 0;
  return distanceKm / (durationMin / 60.0);
}

/// 수영: 100m당 페이스(분) 계산.
double calcSwimPacePer100m({required double distanceM, required int durationMin}) {
  if (distanceM <= 0) return 0;
  final totalSeconds = durationMin * 60;
  return (totalSeconds / distanceM) * 100 / 60.0;
}

/// 수영: SWOLF 계산 (25m 기준, 표준 정의).
/// lapTimeSeconds: 25m를 수영하는 데 걸린 시간(초)
/// strokeCount: 그 25m 구간의 스트로크 수
int calcSwolf({required int lapTimeSeconds, required int strokeCount}) {
  return lapTimeSeconds + strokeCount;
}

/// 헬스: 세트 목록으로부터 총 볼륨(중량 x 횟수의 합) 계산.
/// 볼륨 로드는 저항 트레이닝에서 가장 널리 쓰이는 총량 지표.
double calcVolumeLoad(List<SetEntry> sets) {
  double total = 0;
  for (final s in sets) {
    if (s.weightKg != null && s.reps != null) {
      total += s.weightKg! * s.reps!;
    }
  }
  return total;
}

/// 헬스: Epley 공식을 이용한 추정 1RM 계산.
/// 1RM = weight × (1 + reps / 30)
/// 세트가 여러 개면 그중 가장 높은 추정치를 대표값으로 사용.
double calcEstimated1Rm(List<SetEntry> sets) {
  double best = 0;
  for (final s in sets) {
    if (s.weightKg != null && s.reps != null && s.reps! > 0) {
      final estimate = s.weightKg! * (1 + s.reps! / 30.0);
      if (estimate > best) best = estimate;
    }
  }
  return best;
}

/// 골프: 총타수 - 기준파(보통 18홀 72, 9홀 36)로 오버파 계산.
int calcScoreToPar({required int totalScore, required String holeType}) {
  final standardPar = holeType == '9홀' ? 36 : 72;
  return totalScore - standardPar;
}

/// 칼로리 추정 (MET 공식 간이 버전).
/// calories(kcal) = MET × 체중(kg) × 시간(hour)
/// 체중 정보가 없으면 65kg(성인 평균)을 기본값으로 사용 — 추후 사용자 프로필 연동 시 교체.
double calcCaloriesByMet({
  required double met,
  required int durationMin,
  double bodyWeightKg = 65,
}) {
  return met * bodyWeightKg * (durationMin / 60.0);
}

/// 종목별 대표 MET 값 (Compendium of Physical Activities 근사치).
/// 정밀한 값이 아니라 "칼로리 자동추정"용 근사 계수임을 명시.
const Map<String, double> kExerciseMetValues = {
  'running': 9.8, // 보통 속도 조깅 기준
  'walking': 3.8, // 보통 속도 걷기 기준
  'swimming': 7.0, // 보통 강도 자유형 기준
  'cycling': 7.5, // 보통 강도 기준
  'hiking': 6.0,
};
