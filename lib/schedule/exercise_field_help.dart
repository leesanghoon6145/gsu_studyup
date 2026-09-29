// exercise_field_help.dart
//
// 🆕 [2026-09-29] 운동 세부 기록 입력칸 아래에 회색 작은 글씨로 보여주는 "한 줄 설명".
// 뜻을 모르면 기록을 못 한다는 요청에 따라, 어려운 항목만 골라 쉬운 말로 풀어 두었다.
// - 한국어(기본) 모드에서만 보인다 (today_exercise_screen.dart의 _helpFor)
// - 찾는 순서: '종목id.칸이름' → '칸이름'  (같은 칸 이름이라도 종목마다 뜻이 다를 때 앞의 것을 씀)
// - 여기 없는 칸은 설명 없이 이름만 보인다

const Map<String, String> kExerciseFieldHelpKo = {
  // ---------------- 여러 종목 공통 ----------------
  'calories': '몸무게와 운동 시간으로 자동 계산됩니다',
  'elevationGainM': '오르막을 올라간 높이를 모두 더한 값',
  'elevationLossM': '내리막을 내려간 높이를 모두 더한 값',
  'winners': '상대가 받지 못해 바로 점수가 난 내 공격 수',
  'unforcedErrors': '상대의 압박 없이 내 실수로 잃은 점수',
  'avgRallyLength': '한 점이 날 때까지 공을 주고받은 평균 횟수',
  'assists': '내 패스로 동료가 득점한 횟수',
  'paceMinPerKm': '1km를 가는 데 걸린 평균 시간 (자동 계산) · 짧을수록 빠름',
  'maxPaceMinPerKm': '가장 빨랐던 1km 구간의 시간',
  'cadenceSpm': '1분 동안 발을 디딘 횟수 · 달리기는 보통 160~180',
  'maxCadenceSpm': '가장 빨리 걸음을 옮긴 순간의 1분당 걸음 수',
  'avgStrideCm': '한 걸음의 평균 길이',
  'avgStrideM': '한 걸음의 평균 길이',

  // ---------------- 골프 ----------------
  'golf.roundCount': '오늘 친 경기 횟수 · 18홀 한 번이 1라운드',
  'golf.teePosition': '첫 샷을 치는 자리 · 블랙이 가장 멀고 레드가 가장 가까움',
  'golf.parTotal': '모든 홀의 기준 타수(파)를 더한 값 · 18홀은 보통 72',
  'golf.totalScore': '18홀(또는 9홀) 동안 친 타수 전부',
  'golf.scoreToPar': '내가 친 타수 − 기준 타수 (자동 계산)',
  'golf.putts': '그린에 올라간 뒤 굴려서 친 타수(퍼팅) 합계',
  'golf.threePutts': '그린 위에서 3번 이상 굴려 친 홀의 수',
  'golf.eagle': '이글 · 기준 타수보다 2타 적게 끝낸 홀',
  'golf.birdie': '버디 · 기준 타수보다 1타 적게 끝낸 홀',
  'golf.bogeyOrWorse': '보기 이상 · 기준 타수보다 1타 이상 더 친 홀',
  'golf.fairwaysHit': '첫 샷이 잘 깎인 잔디 길(페어웨이)에 떨어진 홀 수 · 짧은 홀(파3) 빼고 14개 중',
  'golf.greensInRegulation': '기준 타수보다 2타 적게 그린에 올린 홀 수 · 18개 중',
  'golf.ob': '공이 경기 구역 밖으로 나가거나 물에 빠져 받은 벌점 타수',

  // ---------------- 수영 ----------------
  'swimming.laps': '25m 수영장을 한 번 끝까지 가면 1회',
  'swimming.pacePer100m': '100m를 가는 데 걸린 평균 시간 (자동 계산)',
  'swimming.maxPacePer100m': '가장 빨랐던 100m 구간의 시간',
  'swimming.strokeCountPerLap': '25m를 가는 동안 팔을 저은 평균 횟수',
  'swimming.swolf': '25m 걸린 초 + 팔 젓기 횟수 (자동 계산) · 낮을수록 효율이 좋음',

  // ---------------- 헬스 ----------------
  'gym.exerciseName': '예: 벤치프레스, 스쿼트, 랫풀다운',
  'gym.rir': '세트를 마쳤을 때 힘이 남아 더 할 수 있었던 횟수',
  'gym.tempo': '예: 3-1-1 → 내리기 3초, 멈춤 1초, 올리기 1초',
  'gym.toFailure': '마지막 세트를 더 이상 못 할 때까지 했는지',
  'gym.volumeLoad': '무게 × 횟수를 모든 세트에서 더한 값 (자동 계산)',
  'gym.estimated1rm': '한 번에 들 수 있는 가장 무거운 무게를 계산한 값 (자동 계산)',

  // ---------------- 필라테스 · 요가 ----------------
  'pilates.coreHoldTimeSec': '배와 허리(코어)에 힘을 주고 버틴 시간 합계',
  'pilates.breathScore': '동작에 맞춰 숨을 잘 쉬었는지 스스로 매긴 점수',
  'yoga.asanaCount': '오늘 한 요가 자세(아사나)의 수',
  'yoga.breathingTimeMin': '호흡만 따로 수련한 시간',
  'yoga.inversionCount': '물구나무처럼 머리가 아래로 가는 동작의 수',

  // ---------------- 등산 ----------------
  'hiking.peakAltitudeM': '오른 곳 중 가장 높은 지점의 높이 (바다 높이 기준)',
  'hiking.ascentPaceMinPerKm': '오르막에서 1km를 가는 데 걸린 평균 시간',

  // ---------------- 자전거 ----------------
  'cycling.avgSpeedKmh': '거리 ÷ 시간으로 자동 계산',
  'cycling.avgCadenceRpm': '1분 동안 페달을 돌린 횟수 · 보통 80~100',
  'cycling.maxCadenceRpm': '가장 빨리 페달을 돌린 순간의 1분당 회전 수',
  'cycling.avgPowerWatts': '페달을 밟은 힘의 평균 · 파워미터가 있을 때만 적으세요',
  'cycling.maxPowerWatts': '가장 세게 밟은 순간의 힘 · 파워미터가 있을 때만',

  // ---------------- 테니스 · 배드민턴 · 탁구 ----------------
  'tennis.gamesWon': '모든 세트에서 내가 이긴 게임 수를 더한 값',
  'tennis.aces': '상대가 라켓에 대지도 못한 서브 (에이스)',
  'tennis.doubleFaults': '두 번의 서브가 모두 들어가지 않아 잃은 점수 (더블폴트)',
  'tennis.firstServePct': '첫 서브가 들어간 비율 (자동 계산)',
  'tennis.firstServePointsPct': '첫 서브가 들어간 점수 중 내가 이긴 비율',
  'badminton.smashAttempts': '높이 뜬 공을 강하게 내리꽂은 공격 횟수',
  'badminton.dropShotSuccessRate': '네트 앞에 살짝 떨어뜨린 공(드롭샷)이 성공한 비율',
  'tabletennis.serveSpinType': '톱스핀=앞으로 도는 공 · 백스핀=뒤로 도는 공',
  'tabletennis.forehandWinners': '라켓 든 손 쪽(포핸드)으로 쳐서 바로 딴 점수',
  'tabletennis.backhandWinners': '라켓 반대쪽(백핸드)으로 쳐서 바로 딴 점수',

  // ---------------- 농구 · 축구 ----------------
  'basketball.reboundsOff': '우리 편 슛이 빗나가 튕긴 공을 잡은 횟수 (공격 리바운드)',
  'basketball.reboundsDef': '상대 슛이 빗나가 튕긴 공을 잡은 횟수 (수비 리바운드)',
  'soccer.position': 'GK 골키퍼 · DF 수비 · MF 가운데 · FW 공격',
  'soccer.sprintCount': '온 힘을 다해 짧게 달린 횟수',
  'soccer.shotsOnTarget': '빗나가지 않고 골대 안쪽으로 날아간 슛 수',
  'soccer.tackleSuccessRate': '발을 뻗어 상대 공을 빼앗는 데 성공한 비율',

  // ---------------- 스키 ----------------
  'skiing.slopeType': '알파인=일반 슬로프 · 크로스컨트리=평지 이동 · 백컨트리=정비 안 된 산',
  'skiing.totalDescentM': '내려온 높이를 모두 더한 값',
};

/// 입력칸 한 줄 설명 찾기 ('종목id.칸이름' 먼저, 없으면 '칸이름')
String? exerciseFieldHelp(String typeId, String fieldKey) {
  return kExerciseFieldHelpKo['$typeId.$fieldKey'] ?? kExerciseFieldHelpKo[fieldKey];
}
