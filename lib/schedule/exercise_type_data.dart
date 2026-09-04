// exercise_type_data.dart (v2)
//
// 각 종목의 필드는 아래 실제 트래킹 관행/스포츠과학 자료를 근거로 선정했다.
// - 골프: 페어웨이 안착률·그린 적중률(GIR)이 스코어와 가장 상관관계가 높은 지표
//         (Arccos/Shot Scope 트래킹 데이터, MyGolfSpy·GOLF.com 분석 기준)
// - 수영: SWOLF(스트로크수+시간)가 대표적 효율 지표 (MySwimPro 등 표준)
// - 러닝: 페이스·케이던스·심박수가 3대 핵심 지표 (COROS/Garmin/TrainingPeaks 공통)
// - 헬스: 볼륨(세트x횟수x중량)과 RPE/추정1RM이 표준 트레이닝 지표 (RPE 기반 자기조절 트레이닝)
// - 등산/자전거: 누적 상승고도가 거리보다 체력 소모를 더 잘 설명 (Strava Elevation 기준)
//
// 위 근거 지표는 "필수 입력"이 아니라 "제공되는 필드"다. 사용자가 부담스러우면
// isRequired: false인 필드는 비워둘 수 있다.

import 'exercise_models.dart';

// ---------------------------------------------------------------------------
// 여러 종목이 공유하는 필드 (재사용 헬퍼)
// ---------------------------------------------------------------------------

ExerciseField _distanceKmField({String label = '거리', String unit = 'km'}) =>
    ExerciseField(
      key: 'distanceKm',
      type: ExerciseFieldType.number,
      label: label,
      unit: unit,
    );

ExerciseField _caloriesField() => const ExerciseField(
  key: 'calories',
  type: ExerciseFieldType.number,
  label: '칼로리',
  unit: 'kcal',
  isCalculated: true,
);

ExerciseField _courseField({String label = '코스/장소'}) => ExerciseField(
  key: 'course',
  type: ExerciseFieldType.text,
  label: label,
);

ExerciseField _elevationGainField() => const ExerciseField(
  key: 'elevationGainM',
  type: ExerciseFieldType.number,
  label: '누적 상승고도',
  unit: 'm',
);

/// 라켓 구기종목(테니스/배드민턴/탁구) 공통 필드.
/// 스포츠과학적으로 승패/세트스코어 외에 "위너-언포스드에러 비율"이 경기력 지표로 쓰이나,
/// 취미 기록 수준에서는 부담을 줄여 선택 입력으로 둔다.
List<ExerciseField> _racketSportFields() => const [
  ExerciseField(
    key: 'matchType',
    type: ExerciseFieldType.select,
    label: '경기 방식',
    options: ['단식', '복식'],
  ),
  ExerciseField(
    key: 'setScore',
    type: ExerciseFieldType.text,
    label: '세트 스코어',
  ),
  ExerciseField(
    key: 'result',
    type: ExerciseFieldType.select,
    label: '승패',
    options: ['승', '패'],
  ),
  ExerciseField(
    key: 'winners',
    type: ExerciseFieldType.number,
    label: '위너(득점타)',
    isRequired: false,
  ),
  ExerciseField(
    key: 'unforcedErrors',
    type: ExerciseFieldType.number,
    label: '언포스드 에러',
    isRequired: false,
  ),
  ExerciseField(
    key: 'opponent',
    type: ExerciseFieldType.text,
    label: '상대',
    isRequired: false,
  ),
];

/// 팀 구기종목(농구/축구) 공통 필드.
List<ExerciseField> _teamSportFields() => const [
  ExerciseField(
    key: 'position',
    type: ExerciseFieldType.text,
    label: '포지션',
  ),
  ExerciseField(
    key: 'points',
    type: ExerciseFieldType.number,
    label: '득점',
  ),
  ExerciseField(
    key: 'assists',
    type: ExerciseFieldType.number,
    label: '어시스트',
    isRequired: false,
  ),
  ExerciseField(
    key: 'distanceKm',
    type: ExerciseFieldType.number,
    label: '이동거리(추정)',
    unit: 'km',
    isRequired: false,
  ),
];

// ---------------------------------------------------------------------------
// 기본 제공 16개 운동 종목
// ---------------------------------------------------------------------------

final List<ExerciseType> kDefaultExerciseTypes = [
  // 1. 골프 - Arccos/Shot Scope 데이터 기준 페어웨이/GIR/퍼팅이 스코어를 가장 잘 설명
  ExerciseType(
    id: 'golf',
    name: '골프',
    icon: '🏌️',
    isDefault: true,
    sortOrder: 1,
    fields: const [
      ExerciseField(
        key: 'holeType',
        type: ExerciseFieldType.select,
        label: '홀 수',
        options: ['9홀', '18홀'],
      ),
      ExerciseField(
        key: 'totalScore',
        type: ExerciseFieldType.number,
        label: '총타수',
      ),
      ExerciseField(
        key: 'scoreToPar',
        type: ExerciseFieldType.number,
        label: '오버파(스코어-기준파)',
        isCalculated: true,
      ),
      ExerciseField(
        key: 'fairwaysHit',
        type: ExerciseFieldType.number,
        label: '페어웨이 안착 (14개 중)',
      ),
      ExerciseField(
        key: 'greensInRegulation',
        type: ExerciseFieldType.number,
        label: '그린 적중 GIR (18개 중)',
      ),
      ExerciseField(
        key: 'putts',
        type: ExerciseFieldType.number,
        label: '총 퍼팅수',
      ),
      ExerciseField(
        key: 'threePutts',
        type: ExerciseFieldType.counter,
        label: '3퍼팅 횟수',
        isRequired: false,
      ),
      ExerciseField(
        key: 'birdie',
        type: ExerciseFieldType.counter,
        label: '버디',
      ),
      ExerciseField(
        key: 'bogeyOrWorse',
        type: ExerciseFieldType.counter,
        label: '보기 이상',
      ),
      ExerciseField(
        key: 'ob',
        type: ExerciseFieldType.counter,
        label: 'OB/벌타',
      ),
      ExerciseField(
        key: 'course',
        type: ExerciseFieldType.text,
        label: '코스명',
      ),
    ],
  ),

  // 2. 수영 - SWOLF(효율), 페이스, 영법별 구분이 표준 (MySwimPro 등)
  ExerciseType(
    id: 'swimming',
    name: '수영',
    icon: '🏊',
    isDefault: true,
    sortOrder: 2,
    fields: const [
      ExerciseField(
        key: 'distanceM',
        type: ExerciseFieldType.number,
        label: '총 거리',
        unit: 'm',
      ),
      ExerciseField(
        key: 'stroke',
        type: ExerciseFieldType.select,
        label: '주 영법',
        options: ['자유형', '평영', '배영', '접영', '혼계영'],
      ),
      ExerciseField(
        key: 'laps',
        type: ExerciseFieldType.number,
        label: '레인(25m) 왕복 수',
      ),
      ExerciseField(
        key: 'strokeCountPerLap',
        type: ExerciseFieldType.number,
        label: '25m당 평균 스트로크수',
        isRequired: false,
      ),
      ExerciseField(
        key: 'swolf',
        type: ExerciseFieldType.number,
        label: 'SWOLF (25m 시간+스트로크수)',
        isCalculated: true,
      ),
      ExerciseField(
        key: 'pacePer100m',
        type: ExerciseFieldType.number,
        label: '페이스 (100m당)',
        unit: '분',
        isCalculated: true,
      ),
    ],
  ),

  // 3. 달리기 - 페이스/케이던스/심박수 3대 핵심 지표 (Garmin/COROS/TrainingPeaks 공통 권고)
  ExerciseType(
    id: 'running',
    name: '달리기',
    icon: '🏃',
    isDefault: true,
    sortOrder: 3,
    fields: [
      _distanceKmField(),
      const ExerciseField(
        key: 'paceMinPerKm',
        type: ExerciseFieldType.number,
        label: '페이스(km당)',
        unit: '분',
        isCalculated: true,
      ),
      const ExerciseField(
        key: 'cadenceSpm',
        type: ExerciseFieldType.number,
        label: '케이던스',
        unit: 'spm(분당 걸음)',
        isRequired: false,
      ),
      _elevationGainField(),
      _caloriesField(),
      _courseField(),
    ],
  ),

  // 4. 걷기
  ExerciseType(
    id: 'walking',
    name: '걷기',
    icon: '🚶',
    isDefault: true,
    sortOrder: 4,
    fields: [
      _distanceKmField(),
      const ExerciseField(
        key: 'steps',
        type: ExerciseFieldType.number,
        label: '걸음수',
        unit: '보',
      ),
      const ExerciseField(
        key: 'paceMinPerKm',
        type: ExerciseFieldType.number,
        label: '페이스(km당)',
        unit: '분',
        isCalculated: true,
      ),
      _caloriesField(),
    ],
  ),

  // 5. 헬스 - 볼륨(세트x횟수x중량)과 세트별 RPE가 표준 진행상황 추적 지표
  ExerciseType(
    id: 'gym',
    name: '헬스',
    icon: '🏋️',
    isDefault: true,
    sortOrder: 5,
    fields: const [
      ExerciseField(
        key: 'bodyPart',
        type: ExerciseFieldType.select,
        label: '운동 부위',
        options: ['가슴', '등', '하체', '어깨', '팔', '복근', '전신'],
      ),
      ExerciseField(
        key: 'exerciseName',
        type: ExerciseFieldType.text,
        label: '종목명',
      ),
      ExerciseField(
        key: 'sets',
        type: ExerciseFieldType.multiSet,
        label: '세트 (중량x횟수, 세트별 RPE 포함)',
      ),
      ExerciseField(
        key: 'volumeLoad',
        type: ExerciseFieldType.number,
        label: '총 볼륨 (중량x횟수 합)',
        unit: 'kg',
        isCalculated: true,
      ),
      ExerciseField(
        key: 'estimated1rm',
        type: ExerciseFieldType.number,
        label: '추정 1RM (Epley 공식)',
        unit: 'kg',
        isCalculated: true,
      ),
    ],
  ),

  // 6. 필라테스
  ExerciseType(
    id: 'pilates',
    name: '필라테스',
    icon: '🧘',
    isDefault: true,
    sortOrder: 6,
    fields: const [
      ExerciseField(
        key: 'programName',
        type: ExerciseFieldType.text,
        label: '프로그램명',
      ),
      ExerciseField(
        key: 'equipment',
        type: ExerciseFieldType.select,
        label: '기구 유형',
        options: ['매트', '리포머', '캐딜락', '기타'],
        isRequired: false,
      ),
      ExerciseField(
        key: 'difficulty',
        type: ExerciseFieldType.select,
        label: '난이도',
        options: ['초급', '중급', '고급'],
      ),
      ExerciseField(
        key: 'instructor',
        type: ExerciseFieldType.text,
        label: '강사',
        isRequired: false,
      ),
    ],
  ),

  // 7. 요가
  ExerciseType(
    id: 'yoga',
    name: '요가',
    icon: '🧘',
    isDefault: true,
    sortOrder: 7,
    fields: const [
      ExerciseField(
        key: 'style',
        type: ExerciseFieldType.select,
        label: '유형',
        options: ['하타', '빈야사', '아쉬탕가', '인요가', '기타'],
        isRequired: false,
      ),
      ExerciseField(
        key: 'programName',
        type: ExerciseFieldType.text,
        label: '프로그램명',
      ),
      ExerciseField(
        key: 'difficulty',
        type: ExerciseFieldType.select,
        label: '난이도',
        options: ['초급', '중급', '고급'],
      ),
    ],
  ),

  // 8. 등산 - 거리보다 누적 상승/하강 고도가 체력 소모를 더 잘 설명 (Strava/트레일 표준)
  ExerciseType(
    id: 'hiking',
    name: '등산',
    icon: '🥾',
    isDefault: true,
    sortOrder: 8,
    fields: [
      _courseField(label: '산/코스명'),
      _distanceKmField(),
      _elevationGainField(),
      const ExerciseField(
        key: 'elevationLossM',
        type: ExerciseFieldType.number,
        label: '누적 하강고도',
        unit: 'm',
        isRequired: false,
      ),
      const ExerciseField(
        key: 'difficulty',
        type: ExerciseFieldType.select,
        label: '난이도',
        options: ['쉬움', '보통', '어려움'],
        isRequired: false,
      ),
    ],
  ),

  // 9. 자전거 - 평균/최고속도, 케이던스, 파워가 표준 지표 (Strava/사이클링 파워미터 관행)
  ExerciseType(
    id: 'cycling',
    name: '자전거',
    icon: '🚴',
    isDefault: true,
    sortOrder: 9,
    fields: [
      _distanceKmField(),
      const ExerciseField(
        key: 'avgSpeedKmh',
        type: ExerciseFieldType.number,
        label: '평균속도',
        unit: 'km/h',
        isCalculated: true,
      ),
      const ExerciseField(
        key: 'maxSpeedKmh',
        type: ExerciseFieldType.number,
        label: '최고속도',
        unit: 'km/h',
        isRequired: false,
      ),
      const ExerciseField(
        key: 'avgCadenceRpm',
        type: ExerciseFieldType.number,
        label: '평균 케이던스',
        unit: 'rpm',
        isRequired: false,
      ),
      const ExerciseField(
        key: 'avgPowerWatts',
        type: ExerciseFieldType.number,
        label: '평균 파워',
        unit: 'W',
        isRequired: false,
      ),
      _elevationGainField(),
    ],
  ),

  // 10~12. 라켓 구기종목
  ExerciseType(
    id: 'tennis',
    name: '테니스',
    icon: '🎾',
    isDefault: true,
    sortOrder: 10,
    fields: _racketSportFields(),
  ),
  ExerciseType(
    id: 'badminton',
    name: '배드민턴',
    icon: '🏸',
    isDefault: true,
    sortOrder: 11,
    fields: _racketSportFields(),
  ),
  ExerciseType(
    id: 'tabletennis',
    name: '탁구',
    icon: '🏓',
    isDefault: true,
    sortOrder: 12,
    fields: _racketSportFields(),
  ),

  // 13~14. 팀 구기종목
  ExerciseType(
    id: 'basketball',
    name: '농구',
    icon: '🏀',
    isDefault: true,
    sortOrder: 13,
    fields: _teamSportFields(),
  ),
  ExerciseType(
    id: 'soccer',
    name: '축구',
    icon: '⚽',
    isDefault: true,
    sortOrder: 14,
    fields: _teamSportFields(),
  ),

  // 15. 스키
  ExerciseType(
    id: 'skiing',
    name: '스키',
    icon: '⛷️',
    isDefault: true,
    sortOrder: 15,
    fields: const [
      ExerciseField(
        key: 'slopeDifficulty',
        type: ExerciseFieldType.select,
        label: '슬로프 난이도',
        options: ['초급', '중급', '상급'],
      ),
      ExerciseField(
        key: 'runCount',
        type: ExerciseFieldType.counter,
        label: '활강 횟수',
      ),
      ExerciseField(
        key: 'totalDistanceKm',
        type: ExerciseFieldType.number,
        label: '총 활강거리',
        unit: 'km',
        isRequired: false,
      ),
      ExerciseField(
        key: 'maxSpeedKmh',
        type: ExerciseFieldType.number,
        label: '최고속도',
        unit: 'km/h',
        isRequired: false,
      ),
    ],
  ),

  // 16. 기타 - 커스텀 종목을 만들기 전 임시 범용 기록용
  ExerciseType(
    id: 'etc',
    name: '기타',
    icon: '💪',
    isDefault: true,
    sortOrder: 16,
    fields: const [
      ExerciseField(
        key: 'activityName',
        type: ExerciseFieldType.text,
        label: '운동명',
      ),
      ExerciseField(
        key: 'note',
        type: ExerciseFieldType.text,
        label: '상세 내용',
        isRequired: false,
      ),
    ],
  ),
];
