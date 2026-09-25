import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// 🆕 [재설치 복원 2단계 2026-09-25] 계정별 개인 백업 보관함 (userBackups/{uid})
//
// 무엇을: 휴대폰에 저장된 앱 기록(플래너 일정·알람·학사 타임라인·성적관리·과목 목록·
//         일반 플래너 일정/목표/운동 등)을 통째로 서버에 보관.
// 언제 올리나: 앱을 닫거나 다른 앱으로 넘어갈 때 자동 (최소 10분 간격, 바뀐 게 없으면 안 올림)
// 언제 받나: 새로 깔고 로그인했을 때 자동 (계정마다 1번)
// 안전장치:
//   ① 휴대폰에 이미 있는 기록은 절대 덮어쓰지 않음 (없는 항목만 채움)
//   ② 복원이 끝나기 전에는 절대 백업을 올리지 않음 (빈 휴대폰이 서버 백업을 덮어쓰는 사고 방지)
//   ③ 같은 폰의 "다른 계정" 기록(이름표 끝에 다른 uid가 붙은 것)은 올리지 않음
//   ④ 가족 연결 관련 기록(family_…)은 이미 서버에 따로 있으므로 제외
// 저장 크기: 문서 하나 한도(1MB)를 넘지 않도록 70만 글자씩 조각내어 parts/p0, p1… 에 저장
// ============================================================================
class CloudBackupService with WidgetsBindingObserver {
  CloudBackupService._();
  static final CloudBackupService instance = CloudBackupService._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static const String _col = 'userBackups';
  static const String _partsCol = 'parts';
  static const int _chunkSize = 700000; // 조각 하나당 글자 수 (1MB 한도 아래)
  static const Duration _minInterval = Duration(minutes: 10);

  static const String _kLastUploadMs = 'cloud_backup_last_upload_ms';
  static const String _kLastHash = 'cloud_backup_last_hash';
  static const String _kRestoreDone = 'cloud_backup_restore_done';

  // Firebase uid는 28글자 영문·숫자 → 이름표 끝이 "_28글자"면 계정별 기록
  static final RegExp _uidSuffix = RegExp(r'_[A-Za-z0-9]{28}$');

  bool _observing = false;
  String? _startedUid;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // 홈 화면(학생·학부모·일반인)에서 부름. 여러 번 불러도 안전(계정마다 1번만 실제 동작).
  Future<void> start() async {
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    final String? uid = _uid;
    if (uid == null || uid == _startedUid) return;
    _startedUid = uid;
    await restoreIfNeeded();
    unawaited(backupNow());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱을 닫거나 다른 앱으로 넘어갈 때 자동 백업
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      unawaited(backupNow());
    }
  }

  bool _isBackupKey(String key, String uid) {
    if (key.startsWith('family_')) return false; // 가족 연결 기록은 서버에 따로 있음
    if (key.startsWith('cloud_backup_')) return false; // 백업 자체의 표시값
    if (_uidSuffix.hasMatch(key) && !key.endsWith('_$uid')) return false; // 다른 계정 기록
    return true;
  }

  Map<String, dynamic> _collect(SharedPreferences prefs, String uid) {
    final Map<String, dynamic> out = {};
    final List<String> keys = prefs.getKeys().toList()..sort();
    for (final String key in keys) {
      if (!_isBackupKey(key, uid)) continue;
      final Object? v = prefs.get(key);
      if (v is bool) {
        out[key] = {'t': 'b', 'v': v};
      } else if (v is int) {
        out[key] = {'t': 'i', 'v': v};
      } else if (v is double) {
        out[key] = {'t': 'd', 'v': v};
      } else if (v is String) {
        out[key] = {'t': 's', 'v': v};
      } else if (v is List) {
        out[key] = {'t': 'l', 'v': v.map((e) => e.toString()).toList()};
      }
    }
    return out;
  }

  // 지금 바로 백업 (force: 10분 간격·변경 여부와 상관없이)
  Future<void> backupNow({bool force = false}) async {
    final String? uid = _uid;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      // ② 안전장치: 복원이 끝나기 전에는 절대 올리지 않음
      if (prefs.getBool('${_kRestoreDone}_$uid') != true) return;

      final String lastKey = '${_kLastUploadMs}_$uid';
      final String hashKey = '${_kLastHash}_$uid';
      final int nowMs = DateTime.now().millisecondsSinceEpoch;
      final int lastMs = prefs.getInt(lastKey) ?? 0;
      if (!force && nowMs - lastMs < _minInterval.inMilliseconds) return;

      final Map<String, dynamic> data = _collect(prefs, uid);
      final String json = jsonEncode(data);
      final String hash = '${json.length}_${json.hashCode}';
      if (!force && prefs.getString(hashKey) == hash) {
        await prefs.setInt(lastKey, nowMs); // 바뀐 게 없으면 올리지 않음
        return;
      }

      final List<String> parts = [];
      for (int i = 0; i < json.length; i += _chunkSize) {
        parts.add(json.substring(i, min(i + _chunkSize, json.length)));
      }
      if (parts.isEmpty) parts.add('{}');

      final DocumentReference<Map<String, dynamic>> meta = _db.collection(_col).doc(uid);
      final WriteBatch batch = _db.batch();
      for (int i = 0; i < parts.length; i++) {
        batch.set(meta.collection(_partsCol).doc('p$i'), {'data': parts[i]});
      }
      batch.set(meta, {
        'partCount': parts.length,
        'keyCount': data.length,
        'version': 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();

      await prefs.setInt(lastKey, nowMs);
      await prefs.setString(hashKey, hash);
      debugPrint('[CloudBackup] 백업 완료: 항목 ${data.length}개, 조각 ${parts.length}개');
    } catch (e) {
      debugPrint('[CloudBackup] 백업 실패(다음에 다시 시도): $e');
    }
  }

  // 새로 깔고 로그인했을 때 서버 백업에서 "휴대폰에 없는 항목만" 채움 (계정마다 1번)
  Future<void> restoreIfNeeded() async {
    final String? uid = _uid;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String doneKey = '${_kRestoreDone}_$uid';
      if (prefs.getBool(doneKey) == true) return;

      final DocumentSnapshot<Map<String, dynamic>> meta = await _db.collection(_col).doc(uid).get();
      if (!meta.exists) {
        // 서버에 백업이 아직 없음(처음 쓰는 계정) → 복원할 것 없음, 이제부터 백업 시작
        await prefs.setBool(doneKey, true);
        debugPrint('[CloudBackup] 서버 백업 없음 - 이제부터 백업 시작');
        return;
      }

      final int count = (meta.data()?['partCount'] as num?)?.toInt() ?? 0;
      final StringBuffer buf = StringBuffer();
      for (int i = 0; i < count; i++) {
        final DocumentSnapshot<Map<String, dynamic>> part =
        await meta.reference.collection(_partsCol).doc('p$i').get();
        buf.write((part.data()?['data'] as String?) ?? '');
      }
      final Map<String, dynamic> data =
      buf.isEmpty ? <String, dynamic>{} : Map<String, dynamic>.from(jsonDecode(buf.toString()) as Map);

      int restored = 0;
      for (final MapEntry<String, dynamic> entry in data.entries) {
        if (prefs.containsKey(entry.key)) continue; // ① 휴대폰에 있는 건 절대 덮어쓰지 않음
        if (entry.value is! Map) continue;
        final Map<String, dynamic> m = Map<String, dynamic>.from(entry.value as Map);
        final dynamic v = m['v'];
        switch (m['t']) {
          case 'b':
            await prefs.setBool(entry.key, v as bool);
            break;
          case 'i':
            await prefs.setInt(entry.key, (v as num).toInt());
            break;
          case 'd':
            await prefs.setDouble(entry.key, (v as num).toDouble());
            break;
          case 's':
            await prefs.setString(entry.key, v as String);
            break;
          case 'l':
            await prefs.setStringList(entry.key, (v as List).map((e) => e.toString()).toList());
            break;
          default:
            continue;
        }
        restored++;
      }

      await prefs.setBool(doneKey, true);
      debugPrint('[CloudBackup] 복원 완료: $restored개 항목 채움 (서버 ${data.length}개 중)');
    } catch (e) {
      debugPrint('[CloudBackup] 복원 실패(다음 실행 때 다시 시도): $e');
    }
  }
}
