// ============================================================================
// [일반 플래너 - AI 코멘트 MVP] AiCommentService
//
// ⚠️ [중요] 지금은 진짜 Claude API를 부르지 않습니다. 대신 오늘 쌓인 실제
// 데이터(완료율/만족도/방해요인)를 규칙 기반으로 조합해서 "AI가 말할 법한"
// 코멘트를 흉내내어 만듭니다. 나중에 백엔드(Firebase Functions)가 준비되면,
// _generateMockComment() 안의 로직만 실제 Claude API 호출로 바꾸면 됩니다.
// 저장/조회 구조(날짜별 캐싱)는 지금 그대로 실사용 가능합니다.
// ============================================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'report_data_service.dart';
import 'timeline_data_service.dart';

class AiComment {
  final String date; // 'yyyy-MM-dd'
  final String textEn;
  final String textKo;
  final String generatedAt; // 'yyyy-MM-dd HH:mm'

  AiComment({required this.date, required this.textEn, required this.textKo, required this.generatedAt});

  Map<String, dynamic> toJson() => {'date': date, 'textEn': textEn, 'textKo': textKo, 'generatedAt': generatedAt};

  factory AiComment.fromJson(Map<String, dynamic> json) => AiComment(
    date: json['date'] as String,
    textEn: json['textEn'] as String? ?? '',
    textKo: json['textKo'] as String? ?? '',
    generatedAt: json['generatedAt'] as String? ?? '',
  );
}

class AiCommentService {
  static const String _kKey = 'gke_ai_daily_comments_v1';

  static Future<Map<String, AiComment>> _loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kKey);
      if (raw == null || raw.isEmpty) return {};
      final Map<String, dynamic> decoded = jsonDecode(raw);
      return decoded.map((k, v) => MapEntry(k, AiComment.fromJson(Map<String, dynamic>.from(v as Map))));
    } catch (e) {
      return {};
    }
  }

  static Future<void> _saveAll(Map<String, AiComment> comments) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kKey, jsonEncode(comments.map((k, v) => MapEntry(k, v.toJson()))));
    } catch (e) {}
  }

  // 🆕 [핵심] 해당 날짜의 코멘트를 가져옴. 이미 만들어둔 게 있으면 그걸 그대로
  // 돌려주고(재생성 안 함 - 오늘 만든 게 내일도 똑같이 보이는 이유), 없으면
  // 지금 데이터로 새로 만들어서 저장한 뒤 돌려줌.
  static Future<AiComment> getOrGenerate(DateTime date) async {
    final String dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final all = await _loadAll();
    if (all.containsKey(dateKey)) {
      return all[dateKey]!;
    }

    final comment = await _generateMockComment(date, dateKey);
    all[dateKey] = comment;
    await _saveAll(all);
    return comment;
  }

  // 🆕 [기록 조회] 지금까지 생성된 코멘트를 최신순으로 전부 반환 (히스토리 화면용)
  static Future<List<AiComment>> loadHistory() async {
    final all = await _loadAll();
    final list = all.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // ⚠️ [나중에 교체할 부분] 지금은 실제 Claude API 대신, 오늘의 완료율/만족도/
  // 방해요인 데이터를 규칙 기반으로 조합해서 코멘트를 만듭니다. 백엔드 준비되면
  // 이 함수 내부만 실제 API 호출로 교체하면 되고, 위쪽 저장/조회 구조는 그대로 씁니다.
  static Future<AiComment> _generateMockComment(DateTime date, String dateKey) async {
    final summary = await ReportDataService.summarize(date, date);
    final allBlocks = await TimelineDataService.loadForDate(dateKey);
    final completedBlocks = allBlocks.where((b) => b.status == 'completed').toList();

    // 만족도 평균 계산
    final satisfactionValues = completedBlocks.where((b) => b.satisfaction != null).map((b) => b.satisfaction!).toList();
    final double? avgSatisfaction = satisfactionValues.isEmpty ? null : satisfactionValues.reduce((a, b) => a + b) / satisfactionValues.length;

    // 가장 많이 나온 방해요인 계산
    final Map<String, int> disruptionCounts = {};
    for (final b in completedBlocks) {
      for (final d in b.disruptions) {
        if (d == '없음') continue;
        disruptionCounts[d] = (disruptionCounts[d] ?? 0) + 1;
      }
    }
    String? topDisruption;
    if (disruptionCounts.isNotEmpty) {
      topDisruption = disruptionCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

    final int percent = summary.completionPercent;
    final now = DateTime.now();
    final String generatedAt = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    if (!summary.hasData) {
      return AiComment(
        date: dateKey,
        textEn: 'No records for this day yet. Complete a few timeline items and check back!',
        textKo: '이 날짜에는 아직 기록이 없습니다. 타임라인 항목을 몇 개 완료하고 다시 확인해 보세요!',
        generatedAt: generatedAt,
      );
    }

    final StringBuffer en = StringBuffer();
    final StringBuffer ko = StringBuffer();

    en.write('You completed $percent% of your plan today (${summary.completedCount}/${summary.totalCount}).');
    ko.write('오늘 계획의 $percent%를 완료하셨습니다 (${summary.completedCount}/${summary.totalCount}건).');

    if (avgSatisfaction != null) {
      en.write(' Average satisfaction was ${avgSatisfaction.toStringAsFixed(1)}/5.');
      ko.write(' 평균 만족도는 5점 중 ${avgSatisfaction.toStringAsFixed(1)}점이었습니다.');
    }

    if (topDisruption != null) {
      en.write(" The most common distraction was '$topDisruption'.");
      ko.write(" 가장 많이 나온 방해요인은 '$topDisruption'이었습니다.");
    }

    // 간단한 조언 한 줄 (규칙 기반)
    if (percent >= 80) {
      en.write(' Great consistency today - keep this rhythm going.');
      ko.write(' 오늘 정말 꾸준하게 잘하셨어요 - 이 흐름을 이어가 보세요.');
    } else if (percent >= 50) {
      en.write(' A solid effort. Try tackling your top-priority task earlier in the day tomorrow.');
      ko.write(' 나쁘지 않은 하루였어요. 내일은 가장 중요한 일을 하루 앞쪽으로 옮겨보는 건 어떨까요.');
    } else {
      en.write(' Today was tougher than usual. Consider planning fewer, more focused tasks tomorrow.');
      ko.write(' 오늘은 평소보다 힘든 하루였네요. 내일은 항목 수를 줄이고 더 집중해보는 것도 방법입니다.');
    }

    if (topDisruption != null && (topDisruption == '피곤함' || topDisruption == '배고픔')) {
      en.write(' Also, consider a short break or snack before your next focus session.');
      ko.write(' 다음 집중 시간 전에 짧은 휴식이나 간식을 챙기는 것도 도움이 될 거예요.');
    }

    return AiComment(date: dateKey, textEn: en.toString(), textKo: ko.toString(), generatedAt: generatedAt);
  }
}
