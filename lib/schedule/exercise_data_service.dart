// exercise_data_service.dart
//
// EXERCISE 모듈의 단일 데이터 게이트웨이.
// 앱 내 다른 화면(캘린더/알림/일정분석/타임라인/목표/리포트)은 운동 데이터가 필요하면
// 반드시 이 서비스를 거쳐서 읽어간다 (parent_data_service.dart 등과 동일한 "단일 게이트웨이" 패턴).
//
// 책임 범위:
// 1) 종목(ExerciseType) CRUD - 기본 16종 seed, 사용자 추가/수정/삭제
// 2) 기록(ExerciseRecord) CRUD - 저장/조회/수정/삭제
// 3) 분석에 필요한 집계 함수 제공 (종목별/기간별 조회) - 실제 통계 계산은
//    exercise_analysis_screen.dart에서 이 데이터를 받아 처리한다.
//
// 저장소: 현재는 SharedPreferences(JSON 문자열)를 사용한다.
// 추후 Firestore 전환 시에도 이 클래스의 public 메서드 시그니처는 그대로 유지하고
// 내부 구현만 교체하면 되도록 설계했다 (다른 화면은 이 클래스만 알면 됨).

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'exercise_models.dart';
import 'exercise_type_data.dart';

class ExerciseDataService {
  ExerciseDataService._internal();
  static final ExerciseDataService instance = ExerciseDataService._internal();

  static const _kTypesKey = 'exercise_types_v1';
  static const _kRecordsKey = 'exercise_records_v1';

  // ✅ [2026-09-06 추가 - 종목 정의 자동 최신화] 예전엔 종목 정의(필드/영문라벨/
  // 중복선택 여부 등)를 최초 1회만 seed하고, 그 뒤로는 폰에 저장된 옛날 값을
  // 계속 재사용해서, exercise_type_data.dart를 아무리 업데이트해도 사용자
  // 화면에는 반영이 안 되는 문제가 있었다(앱 데이터를 지워야만 해결됨).
  // 이 버전 번호를 올릴 때마다, 저장된 기본종목 정의를 최신 exercise_type_data.dart
  // 내용으로 자동 병합(마이그레이션)한다. 기록된 운동 데이터나 사용자가 만든
  // 커스텀 종목, 숨김 처리 등은 전혀 건드리지 않는다.
  static const int _kTypesSchemaVersion = 8; // 🆕 [헬스 장비 옵션 추가] 버전
  static const String _kTypesSchemaVersionKey = 'exercise_types_schema_version';

  List<ExerciseType>? _typesCache;
  List<ExerciseRecord>? _recordsCache;

  // -------------------------------------------------------------------------
  // 종목(ExerciseType) CRUD
  // -------------------------------------------------------------------------

  /// 전체 종목 목록을 반환한다 (숨김 종목 포함 여부 선택 가능).
  /// 최초 실행 시 기본 16종을 자동으로 seed한다.
  Future<List<ExerciseType>> getExerciseTypes({bool includeHidden = false}) async {
    if (_typesCache == null) {
      await _loadTypes();
    }
    final all = List<ExerciseType>.from(_typesCache!);
    all.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (includeHidden) return all;
    return all.where((t) => !t.isHidden).toList();
  }

  Future<void> _loadTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTypesKey);
    if (raw == null) {
      // 최초 실행: 기본 16종 seed
      _typesCache = List<ExerciseType>.from(kDefaultExerciseTypes);
      await _saveTypes();
      await prefs.setInt(_kTypesSchemaVersionKey, _kTypesSchemaVersion);
    } else {
      final list = jsonDecode(raw) as List;
      _typesCache = list
          .map((e) => ExerciseType.fromJson(e as Map<String, dynamic>))
          .toList();

      // ✅ [자동 최신화] 저장된 버전이 지금 코드의 버전과 다르면, 기본종목
      // 정의(이름/아이콘/필드 구성)만 exercise_type_data.dart의 최신 내용으로
      // 새로 덮어쓴다. 사용자가 만든 커스텀 종목과 숨김 여부는 그대로 유지한다.
      final int savedVersion = prefs.getInt(_kTypesSchemaVersionKey) ?? 1;
      if (savedVersion != _kTypesSchemaVersion) {
        _migrateDefaultTypes();
        await _saveTypes();
        await prefs.setInt(_kTypesSchemaVersionKey, _kTypesSchemaVersion);
      }
    }
  }

  // ✅ [2026-09-06 추가] 저장된 목록 중 "기본 제공 종목"(id가 kDefaultExerciseTypes에
  // 있는 것들)만 최신 정의로 교체한다. 사용자가 이름을 바꿨거나 숨김 처리한
  // 경우를 대비해 isHidden/sortOrder는 저장된 값을 그대로 유지하고, 이름/
  // 아이콘/필드 구성(영문라벨/중복선택 등)만 최신 내용으로 갱신한다. 새로
  // 추가된 기본종목이 있으면 목록 끝에 추가하고, 사용자가 만든 커스텀
  // 종목(kDefaultExerciseTypes에 없는 id)은 손대지 않는다.
  void _migrateDefaultTypes() {
    final Map<String, ExerciseType> defaultsById = {for (final t in kDefaultExerciseTypes) t.id: t};
    final List<ExerciseType> merged = [];
    final Set<String> seenIds = {};

    for (final existing in _typesCache!) {
      final latestDefault = defaultsById[existing.id];
      if (latestDefault != null) {
        // 🆕 기본종목이면 필드/이름/아이콘을 최신으로 교체, 사용자 설정(숨김/순서)은 유지
        merged.add(existing.copyWith(
          name: latestDefault.name,
          icon: latestDefault.icon,
          fields: latestDefault.fields,
        ));
      } else {
        // 🆕 사용자 커스텀 종목은 그대로 유지
        merged.add(existing);
      }
      seenIds.add(existing.id);
    }

    // 🆕 새로 추가된 기본종목이 있으면 뒤에 추가
    for (final def in kDefaultExerciseTypes) {
      if (!seenIds.contains(def.id)) merged.add(def);
    }

    _typesCache = merged;
  }

  Future<void> _saveTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_typesCache!.map((t) => t.toJson()).toList());
    await prefs.setString(_kTypesKey, raw);
  }

  /// 사용자 커스텀 종목 추가. id는 자동 생성(timestamp 기반).
  Future<ExerciseType> addExerciseType({
    required String name,
    required String icon,
    required List<ExerciseField> fields,
  }) async {
    if (_typesCache == null) await _loadTypes();
    final newType = ExerciseType(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      icon: icon,
      isDefault: false,
      sortOrder: _typesCache!.length + 1,
      fields: fields,
    );
    _typesCache!.add(newType);
    await _saveTypes();
    return newType;
  }

  /// 종목 수정 (이름/아이콘/필드 구성 변경). 기본종목도 필드 커스터마이징 가능.
  Future<void> updateExerciseType(ExerciseType updated) async {
    if (_typesCache == null) await _loadTypes();
    final index = _typesCache!.indexWhere((t) => t.id == updated.id);
    if (index == -1) {
      throw StateError('종목을 찾을 수 없습니다: ${updated.id}');
    }
    _typesCache![index] = updated;
    await _saveTypes();
  }

  /// 종목 삭제.
  /// - 기본종목(isDefault=true): 완전 삭제하지 않고 숨김(isHidden=true) 처리.
  ///   과거 기록이 이 종목 id를 참조하고 있을 수 있으므로 데이터 무결성을 보호한다.
  /// - 커스텀종목: 해당 종목의 기록이 하나도 없으면 완전 삭제, 기록이 있으면 마찬가지로 숨김 처리.
  Future<void> deleteExerciseType(String typeId) async {
    if (_typesCache == null) await _loadTypes();
    final index = _typesCache!.indexWhere((t) => t.id == typeId);
    if (index == -1) return;

    final hasRecords = (await getRecordsByType(typeId)).isNotEmpty;
    final target = _typesCache![index];

    if (!target.isDefault && !hasRecords) {
      _typesCache!.removeAt(index);
    } else {
      _typesCache![index] = target.copyWith(isHidden: true);
    }
    await _saveTypes();
  }

  /// 숨김 처리된 종목을 다시 보이게 복원.
  Future<void> restoreExerciseType(String typeId) async {
    if (_typesCache == null) await _loadTypes();
    final index = _typesCache!.indexWhere((t) => t.id == typeId);
    if (index == -1) return;
    _typesCache![index] = _typesCache![index].copyWith(isHidden: false);
    await _saveTypes();
  }

  /// id로 종목 하나 조회.
  Future<ExerciseType?> getExerciseTypeById(String typeId) async {
    if (_typesCache == null) await _loadTypes();
    try {
      return _typesCache!.firstWhere((t) => t.id == typeId);
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // 기록(ExerciseRecord) CRUD
  // -------------------------------------------------------------------------

  Future<List<ExerciseRecord>> getAllRecords() async {
    if (_recordsCache == null) await _loadRecords();
    return List<ExerciseRecord>.from(_recordsCache!);
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kRecordsKey);
    if (raw == null) {
      _recordsCache = [];
    } else {
      final list = jsonDecode(raw) as List;
      _recordsCache = list
          .map((e) => ExerciseRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_recordsCache!.map((r) => r.toJson()).toList());
    await prefs.setString(_kRecordsKey, raw);
  }

  /// 새 운동 기록 저장.
  Future<ExerciseRecord> addRecord(ExerciseRecord record) async {
    if (_recordsCache == null) await _loadRecords();
    _recordsCache!.add(record);
    await _saveRecords();
    return record;
  }

  Future<void> updateRecord(ExerciseRecord updated) async {
    if (_recordsCache == null) await _loadRecords();
    final index = _recordsCache!.indexWhere((r) => r.recordId == updated.recordId);
    if (index == -1) {
      throw StateError('기록을 찾을 수 없습니다: ${updated.recordId}');
    }
    _recordsCache![index] = updated;
    await _saveRecords();
  }

  Future<void> deleteRecord(String recordId) async {
    if (_recordsCache == null) await _loadRecords();
    _recordsCache!.removeWhere((r) => r.recordId == recordId);
    await _saveRecords();
  }

  /// 특정 종목의 모든 기록 (종목별 분석/필드 삭제 가능 여부 판단에 사용).
  Future<List<ExerciseRecord>> getRecordsByType(String exerciseTypeId) async {
    final all = await getAllRecords();
    return all.where((r) => r.exerciseTypeId == exerciseTypeId).toList();
  }

  /// 특정 날짜 범위의 기록 (캘린더/오늘의 일정/일정분석 연동용).
  Future<List<ExerciseRecord>> getRecordsBetween(DateTime start, DateTime end) async {
    final all = await getAllRecords();
    return all.where((r) => !r.date.isBefore(start) && !r.date.isAfter(end)).toList();
  }

  /// 특정 날짜 하루의 기록 (캘린더 셀 아이콘 표시, 오늘의 일정 노출에 사용).
  Future<List<ExerciseRecord>> getRecordsOnDate(DateTime date) async {
    final all = await getAllRecords();
    return all
        .where((r) =>
    r.date.year == date.year &&
        r.date.month == date.month &&
        r.date.day == date.day)
        .toList();
  }

  // -------------------------------------------------------------------------
  // 캐시 초기화 (테스트/로그아웃 시 사용)
  // -------------------------------------------------------------------------
  void clearCache() {
    _typesCache = null;
    _recordsCache = null;
  }
}
