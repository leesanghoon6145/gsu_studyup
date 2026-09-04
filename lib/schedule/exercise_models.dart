// exercise_models.dart (v2)
//
// v1 대비 변경점:
// - ExerciseIntensity(낮음/보통/높음 3단계) 제거 -> rpe(1~10, Borg RPE 계열 자각운동강도)로 교체.
//   근거: 실제 트레이닝 앱/스포츠과학에서 강도는 3단계보다 RPE 1~10이 표준이며,
//         종목이 달라도(골프든 러닝이든) 동일 척도로 비교 분석이 가능해짐.
// - avgHeartRateBpm / maxHeartRateBpm 을 모든 종목 공통 선택 필드로 추가.
//   근거: 심박수는 종목 불문 가장 보편적인 운동강도 지표(러닝/수영/사이클/구기 공통 사용).
// - 이 두 값은 "공통 필드"이므로 종목별 detail 맵이 아니라 ExerciseRecord 최상위에 둔다.
//   -> 종목이 달라도 심박수/RPE 기반 분석(예: 이번주 평균강도 추이)이 한 쿼리로 가능해짐.

/// 종목별 상세 필드가 가질 수 있는 입력 타입.
enum ExerciseFieldType {
  number, // 숫자 입력 (예: 거리, 타수, 중량)
  duration, // 시간 입력 (분 단위 저장)
  select, // 사전 정의된 옵션 중 하나 선택
  counter, // +/- 버튼으로 증감하는 정수
  text, // 자유 텍스트
  multiSet, // 세트별 반복 입력 배열 (예: 헬스 세트x횟수x중량)
}

ExerciseFieldType exerciseFieldTypeFromString(String value) {
  return ExerciseFieldType.values.firstWhere(
        (e) => e.name == value,
    orElse: () => ExerciseFieldType.text,
  );
}

/// 종목 하나가 가지는 상세 필드 정의 (스키마).
class ExerciseField {
  final String key;
  final ExerciseFieldType type;
  final String label;
  final String? unit;
  final List<String>? options;

  /// 자동계산 필드 여부 (예: 페이스, SWOLF, 추정1RM). true면 입력 UI 대신 계산된 값만 표시.
  /// 계산 공식은 exercise_calculations.dart 참고.
  final bool isCalculated;

  final bool isRequired;

  const ExerciseField({
    required this.key,
    required this.type,
    required this.label,
    this.unit,
    this.options,
    this.isCalculated = false,
    this.isRequired = false,
  });

  Map<String, dynamic> toJson() => {
    'key': key,
    'type': type.name,
    'label': label,
    'unit': unit,
    'options': options,
    'isCalculated': isCalculated,
    'isRequired': isRequired,
  };

  factory ExerciseField.fromJson(Map<String, dynamic> json) {
    return ExerciseField(
      key: json['key'] as String,
      type: exerciseFieldTypeFromString(json['type'] as String),
      label: json['label'] as String,
      unit: json['unit'] as String?,
      options: (json['options'] as List?)?.map((e) => e.toString()).toList(),
      isCalculated: json['isCalculated'] as bool? ?? false,
      isRequired: json['isRequired'] as bool? ?? false,
    );
  }

  ExerciseField copyWith({
    String? key,
    ExerciseFieldType? type,
    String? label,
    String? unit,
    List<String>? options,
    bool? isCalculated,
    bool? isRequired,
  }) {
    return ExerciseField(
      key: key ?? this.key,
      type: type ?? this.type,
      label: label ?? this.label,
      unit: unit ?? this.unit,
      options: options ?? this.options,
      isCalculated: isCalculated ?? this.isCalculated,
      isRequired: isRequired ?? this.isRequired,
    );
  }
}

/// 운동 종목 하나 (기본 16종 + 사용자 추가 종목 공통 구조).
class ExerciseType {
  final String id;
  final String name;
  final String icon;

  /// 기본 제공 종목 여부.
  final bool isDefault;

  /// 숨김 여부. 기본종목은 완전 삭제 대신 숨김 처리를 권장(과거 기록 참조 보호).
  /// 사용자 커스텀 종목은 기록이 하나도 없으면 완전 삭제 가능(exercise_data_service에서 판단).
  final bool isHidden;

  final List<ExerciseField> fields;
  final int sortOrder;

  const ExerciseType({
    required this.id,
    required this.name,
    required this.icon,
    required this.fields,
    this.isDefault = false,
    this.isHidden = false,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'isDefault': isDefault,
    'isHidden': isHidden,
    'sortOrder': sortOrder,
    'fields': fields.map((f) => f.toJson()).toList(),
  };

  factory ExerciseType.fromJson(Map<String, dynamic> json) {
    return ExerciseType(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      isHidden: json['isHidden'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
      fields: (json['fields'] as List)
          .map((f) => ExerciseField.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }

  ExerciseType copyWith({
    String? id,
    String? name,
    String? icon,
    bool? isDefault,
    bool? isHidden,
    int? sortOrder,
    List<ExerciseField>? fields,
  }) {
    return ExerciseType(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      isHidden: isHidden ?? this.isHidden,
      sortOrder: sortOrder ?? this.sortOrder,
      fields: fields ?? this.fields,
    );
  }
}

/// 헬스처럼 "세트를 여러 번 반복"하는 필드(multiSet)의 개별 세트 데이터.
class SetEntry {
  final int setNumber;
  final double? weightKg;
  final int? reps;

  /// 세트별 자각강도(RPE 1~10, 선택). 세트 단위로 기록하면 추정 1RM 계산 정확도가 올라간다.
  final int? rpe;

  const SetEntry({
    required this.setNumber,
    this.weightKg,
    this.reps,
    this.rpe,
  });

  Map<String, dynamic> toJson() => {
    'setNumber': setNumber,
    'weightKg': weightKg,
    'reps': reps,
    'rpe': rpe,
  };

  factory SetEntry.fromJson(Map<String, dynamic> json) {
    return SetEntry(
      setNumber: json['setNumber'] as int,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      reps: json['reps'] as int?,
      rpe: json['rpe'] as int?,
    );
  }
}

/// 실제 저장되는 운동 기록 1건.
class ExerciseRecord {
  final String recordId;
  final String exerciseTypeId;
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;
  final int durationMin;

  /// 자각 운동강도 (RPE, 1~10). 1=매우 가벼움 ~ 10=최대 노력.
  /// 모든 종목 공통 지표이므로 detail이 아닌 최상위 필드로 둔다.
  final int? rpe;

  /// 평균 심박수 (bpm, 선택). 웨어러블 기기가 없으면 비워둘 수 있다.
  final int? avgHeartRateBpm;

  /// 최고 심박수 (bpm, 선택).
  final int? maxHeartRateBpm;

  final String memo;

  /// 종목별 상세 필드 값. key는 ExerciseField.key와 매칭.
  /// multiSet 필드는 List<Map> (SetEntry.toJson() 리스트) 형태로 저장.
  final Map<String, dynamic> detail;

  /// [일정 > 알림]에서 생성된 기록인지 추적 (선택).
  final String? sourceReminderId;

  const ExerciseRecord({
    required this.recordId,
    required this.exerciseTypeId,
    required this.date,
    required this.durationMin,
    this.startTime,
    this.endTime,
    this.rpe,
    this.avgHeartRateBpm,
    this.maxHeartRateBpm,
    this.memo = '',
    this.detail = const {},
    this.sourceReminderId,
  });

  Map<String, dynamic> toJson() => {
    'recordId': recordId,
    'exerciseTypeId': exerciseTypeId,
    'date': date.toIso8601String(),
    'startTime': startTime?.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'durationMin': durationMin,
    'rpe': rpe,
    'avgHeartRateBpm': avgHeartRateBpm,
    'maxHeartRateBpm': maxHeartRateBpm,
    'memo': memo,
    'detail': detail,
    'sourceReminderId': sourceReminderId,
  };

  factory ExerciseRecord.fromJson(Map<String, dynamic> json) {
    return ExerciseRecord(
      recordId: json['recordId'] as String,
      exerciseTypeId: json['exerciseTypeId'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      durationMin: json['durationMin'] as int,
      rpe: json['rpe'] as int?,
      avgHeartRateBpm: json['avgHeartRateBpm'] as int?,
      maxHeartRateBpm: json['maxHeartRateBpm'] as int?,
      memo: json['memo'] as String? ?? '',
      detail: Map<String, dynamic>.from(json['detail'] as Map? ?? {}),
      sourceReminderId: json['sourceReminderId'] as String?,
    );
  }

  ExerciseRecord copyWith({
    String? recordId,
    String? exerciseTypeId,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMin,
    int? rpe,
    int? avgHeartRateBpm,
    int? maxHeartRateBpm,
    String? memo,
    Map<String, dynamic>? detail,
    String? sourceReminderId,
  }) {
    return ExerciseRecord(
      recordId: recordId ?? this.recordId,
      exerciseTypeId: exerciseTypeId ?? this.exerciseTypeId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMin: durationMin ?? this.durationMin,
      rpe: rpe ?? this.rpe,
      avgHeartRateBpm: avgHeartRateBpm ?? this.avgHeartRateBpm,
      maxHeartRateBpm: maxHeartRateBpm ?? this.maxHeartRateBpm,
      memo: memo ?? this.memo,
      detail: detail ?? this.detail,
      sourceReminderId: sourceReminderId ?? this.sourceReminderId,
    );
  }
}

/// RPE 1~10 각 단계의 한글 라벨 (Borg CR10 스케일 변형, 자각운동강도 표준).
const Map<int, String> kRpeLabels = {
  1: '매우 가벼움',
  2: '가벼움',
  3: '약간 가벼움',
  4: '보통',
  5: '약간 힘듦',
  6: '힘듦',
  7: '매우 힘듦',
  8: '힘듦(고강도)',
  9: '매우 고강도',
  10: '최대 노력',
};
