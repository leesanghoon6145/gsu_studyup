// notice_translate_service.dart  (lib/services/)
//
// 🆕 [2026-10-09] 공지 10개 언어 번역 — 관리자 폰 안의 무료 번역기(Google ML Kit, 폰 안에서만 번역)
// - 한국어 · 영어는 관리자가 직접 쓴 글을 그대로 씀 (가장 정확)
// - 나머지 10개 언어(일 · 중 · 프 · 독 · 러 · 아랍 · 힌디 · 베트남 · 스페인 · 태국)는
//   영문이 있으면 영문을, 없으면 한글을 바탕으로 공지를 올릴 때 한 번만 번역해서 함께 저장
// - 사용자는 저장된 번역을 읽기만 함 → 서버 비용 · 번역 요금 · 카드 등록 모두 필요 없음
// - 처음 한 번만 언어마다 번역 자료(약 30MB)를 관리자 폰에 내려받음 (와이파이에서 권장)
// - 줄 단위로 번역해서 줄바꿈 · ━━ 구분선 · 번호 · 이모지 모양이 그대로 남음

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class NoticeTranslateResult {
  final Map<String, String> titles; // {'ja': '…', 'zh': '…'}
  final Map<String, String> bodies;
  final List<String> failed; // 번역하지 못한 언어 (다시 저장하면 다시 시도)
  const NoticeTranslateResult(this.titles, this.bodies, this.failed);
}

class NoticeTranslateService {
  NoticeTranslateService._();

  /// 저장 이름(소문자) → 번역기 언어
  static const Map<String, TranslateLanguage> targets = {
    'ja': TranslateLanguage.japanese,
    'zh': TranslateLanguage.chinese,
    'fr': TranslateLanguage.french,
    'de': TranslateLanguage.german,
    'ru': TranslateLanguage.russian,
    'ar': TranslateLanguage.arabic,
    'hi': TranslateLanguage.hindi,
    'vi': TranslateLanguage.vietnamese,
    'es': TranslateLanguage.spanish,
    'th': TranslateLanguage.thai,
  };

  static final RegExp _hasLetter = RegExp(r'\p{L}', unicode: true);
  static final RegExp _lead = RegExp(r'^\s*');

  static Future<void> _ensureModel(OnDeviceTranslatorModelManager mm, TranslateLanguage lang) async {
    final String code = lang.bcpCode;
    if (await mm.isModelDownloaded(code)) return;
    await mm.downloadModel(code, isWifiRequired: false).timeout(const Duration(minutes: 4));
  }

  /// 여러 줄 글을 줄마다 번역 (글자가 없는 줄 — 빈 줄 · ━━ 줄 · 숫자만 — 은 그대로)
  static Future<String> _translateKeepLines(OnDeviceTranslator tr, String text) async {
    final List<String> out = [];
    final Map<String, String> cache = {}; // 같은 줄이 여러 번 나오면 한 번만 번역
    for (final String line in text.split('\n')) {
      final String core = line.trim();
      if (core.isEmpty || !_hasLetter.hasMatch(core)) {
        out.add(line);
        continue;
      }
      final String lead = _lead.stringMatch(line) ?? '';
      final String done = cache[core] ??= await tr.translateText(core).timeout(const Duration(seconds: 30));
      out.add('$lead$done');
    }
    return out.join('\n');
  }

  /// 10개 언어 한 번에 번역. onProgress(끝낸 수, 전체 수) 로 진행 상황을 알려 줌
  static Future<NoticeTranslateResult> translateAll({
    required String title,
    required String body,
    required bool fromEnglish,
    void Function(int done, int total)? onProgress,
  }) async {
    final TranslateLanguage src = fromEnglish ? TranslateLanguage.english : TranslateLanguage.korean;
    final OnDeviceTranslatorModelManager mm = OnDeviceTranslatorModelManager();
    final Map<String, String> titles = {};
    final Map<String, String> bodies = {};
    final List<String> failed = [];
    int done = 0;
    onProgress?.call(0, targets.length);
    try {
      await _ensureModel(mm, src);
    } catch (e) {
      debugPrint('[NOTICE-TR] 원문 언어 자료 받기 실패: $e');
      return NoticeTranslateResult(titles, bodies, targets.keys.toList());
    }
    for (final MapEntry<String, TranslateLanguage> t in targets.entries) {
      OnDeviceTranslator? tr;
      try {
        await _ensureModel(mm, t.value);
        tr = OnDeviceTranslator(sourceLanguage: src, targetLanguage: t.value);
        titles[t.key] = await _translateKeepLines(tr, title);
        bodies[t.key] = await _translateKeepLines(tr, body);
      } catch (e) {
        debugPrint('[NOTICE-TR] ${t.key} 번역 실패: $e');
        failed.add(t.key);
        titles.remove(t.key);
        bodies.remove(t.key);
      } finally {
        await tr?.close();
      }
      done++;
      onProgress?.call(done, targets.length);
    }
    return NoticeTranslateResult(titles, bodies, failed);
  }
}
