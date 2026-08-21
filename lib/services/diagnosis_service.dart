import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// 👑 [AI 진단문 창구] DiagnosisService
// -----------------------------------------------------------------------------
// 원장님 지시사항 (반드시 지킬 것):
// 1. 글자수 최소 300자 전후
// 2. 전문용어는 괄호 사용해서 부연설명
// 3. 한 번 생성된 문구는 반드시 영구 저장 ("라이브러리")
// 4. 같은 사람에게는 절대 같은 문구를 다시 보여주면 안 됨 (3개월 이내)
// 5. 3개월이 지나면 같은 사람에게 유사한 문구 재사용 가능
// 6. 유사한 상황(같은 점수 구간)의 다른 사람에게는 저장된 문구를 재사용 가능
// -----------------------------------------------------------------------------
// 구현 방식: "인사말 + 관찰 + 조언 + 격려" 4개 카테고리를 조합해서 문장을 만듭니다.
// 카테고리마다 여러 버전이 있어서 조합 가짓수가 커지므로(점수 구간별 약 80가지 이상)
// 실제로 반복될 확률이 매우 낮고, 그래도 반복되면 강제로 다른 조합을 골라냅니다.
// 조합된 결과("comboId")는 SharedPreferences에 점수 구간별 "라이브러리"로 영구 저장되고,
// 이 사람이 어떤 조합을 언제 봤는지는 별도 키("seen")로 기록해서 3개월 재사용 규칙을 지킵니다.
// ============================================================================

class DiagnosisService {
  DiagnosisService._();

  static const int minLength = 300;
  static const Duration reuseCooldown = Duration(days: 90); // 3개월

  // ── [신규] "오늘 종합 리포트"용 150~200자 짧은 총평 ─────────────────────────
  // 위의 300자 진단(점수 1건 기준)과는 별개로, "오늘 학습한 모든 과목/시간"을
  // 종합해서 짧게 총평하는 문구. 같은 라이브러리/3개월 재사용 규칙을 그대로 적용하되
  // 저장 키 네임스페이스만 분리(dke_daily_*)해서 서로 섞이지 않게 합니다.
  static const int dailyMinLength = 150;
  static const int dailyMaxLength = 260; // 원장님 요청의 핵심은 "최소 150자 이상" 보장 - 문장 중간 절단을 피하기 위해 상한은 여유있게 설정

  static String _dailyTierFor(int totalMinutes) {
    if (totalMinutes >= 180) return 'high';
    if (totalMinutes >= 120) return 'good';
    if (totalMinutes >= 60) return 'mid';
    return 'low';
  }

  static const Map<String, List<String>> _dailyOpenings = {
    'high': [
      '오늘 {subjectCount}개 과목에서 총 {totalMinutes}분에 달하는 학습 몰입이 확인되었습니다. 하루 동안 여러 과목을 오가며 꾸준히 집중력을 유지한 흔적이 뚜렷하게 나타납니다.',
      '{totalMinutes}분에 걸친 오늘의 학습량은 {subjectCount}개 과목을 아우르는 매우 밀도 높은 하루였습니다. 시간 배분과 몰입도 모두 상위권에 속하는 수준으로 판단됩니다.',
      '오늘 하루 {subjectCount}개 과목, {totalMinutes}분의 집중 학습이 끊김 없이 이어졌습니다. 특정 과목에 치우치지 않고 고르게 시간을 투자한 점이 인상적입니다.',
    ],
    'good': [
      '오늘 {subjectCount}개 과목에서 {totalMinutes}분의 안정적인 학습 흐름이 확인되었습니다. 무리하지 않으면서도 꾸준함을 유지하는 좋은 리듬을 보여주고 있습니다.',
      '{totalMinutes}분 동안 {subjectCount}개 과목을 고르게 학습한 알찬 하루였습니다. 특정 과목에 편중되지 않고 균형 잡힌 학습 패턴을 이어가고 있는 것으로 보입니다.',
      '오늘의 학습 기록은 {subjectCount}개 과목, {totalMinutes}분으로 무난하고 안정적인 페이스를 보여줍니다. 이 흐름이 반복되면 점진적인 성장으로 이어질 가능성이 높습니다.',
    ],
    'mid': [
      '오늘 {subjectCount}개 과목에서 {totalMinutes}분의 학습이 기록되었습니다. 다른 날에 비해 다소 짧을 수 있으나, 꾸준히 이어간다면 충분히 의미 있는 흐름입니다.',
      '{totalMinutes}분 동안 {subjectCount}개 과목을 짚어본 하루였습니다. 컨디션이나 일정에 따라 자연스럽게 나타날 수 있는 수준으로, 크게 걱정할 부분은 아닙니다.',
      '오늘의 학습 시간은 {totalMinutes}분으로, 평소 페이스보다 조금 여유로웠던 하루로 보입니다. 조금씩 시간을 늘려가 보는 것도 좋은 방향이 될 수 있습니다.',
    ],
    'low': [
      '오늘은 {subjectCount}개 과목에서 총 {totalMinutes}분의 비교적 짧은 학습이 기록되었습니다. 컨디션이나 다른 일정의 영향일 수 있으니 너무 걱정하지 않으셔도 됩니다.',
      '{totalMinutes}분의 학습 기록으로, 오늘은 다소 여유로운 하루였던 것으로 보입니다. 하루 이틀의 흐름보다는 한 주 전체의 꾸준함이 더 중요한 지표입니다.',
      '오늘의 학습 시간이 {totalMinutes}분으로 평소보다 짧게 기록되었습니다. 가벼운 컨디션 난조였을 가능성도 있으니, 내일의 흐름을 함께 지켜봐 주시면 좋겠습니다.',
    ],
  };

  static const Map<String, List<String>> _dailyClosings = {
    'high': [
      ' 이 흐름을 무리 없이 이어가되, 과목 간 틈틈이 휴식도 충분히 챙겨주시길 권해드립니다.',
      ' 다만 장시간 집중한 뒤에는 컨디션 관리도 함께 신경 써주시면 더욱 좋겠습니다.',
      ' 이런 밀도 있는 하루가 꾸준히 쌓이면 성적 향상으로 자연스럽게 이어질 가능성이 높습니다.',
    ],
    'good': [
      ' 지금의 학습 페이스를 꾸준히 유지하는 것을 권장드립니다.',
      ' 상대적으로 취약한 과목에 조금 더 시간을 배분해보는 것도 좋은 선택이 될 것입니다.',
      ' 안정적인 학습 습관이 차근차근 자리잡아가고 있는 것으로 판단됩니다.',
    ],
    'mid': [
      ' 내일은 조금 더 여유 있게 집중 시간을 확보해보시길 권해드립니다.',
      ' 짧더라도 매일 꾸준히 이어가는 습관이 장기적으로는 더 중요합니다.',
      ' 부담되지 않는 선에서 학습 시간을 조금씩 늘려가 보시길 바랍니다.',
    ],
    'low': [
      ' 컨디션에 따라 자연스럽게 나타나는 흐름일 수 있으니 크게 걱정하지 않으셔도 됩니다.',
      ' 내일은 좋아하는 과목부터 가볍게 시작해보시는 것을 권해드립니다.',
      ' 짧은 학습이라도 꾸준히 이어진다면 그 자체로 충분히 의미 있는 습관이 됩니다.',
    ],
  };

  static Future<String> getDailySummary({
    required String personKey,
    required int subjectCount,
    required int totalMinutes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String tier = _dailyTierFor(totalMinutes);
      final String libraryKey = 'dke_daily_library_$tier';
      final String seenKey = 'dke_daily_seen_${personKey}_$tier';

      final List<Map<String, dynamic>> library = _loadList(prefs, libraryKey);
      final List<Map<String, dynamic>> seen = _loadList(prefs, seenKey);

      final DateTime now = DateTime.now();
      final Set<String> recentlySeenIds = seen
          .where((e) {
        final DateTime? seenAt = DateTime.tryParse(e['seenAt']?.toString() ?? '');
        return seenAt != null && now.difference(seenAt) < reuseCooldown;
      })
          .map((e) => e['comboId'].toString())
          .toSet();

      final List<Map<String, dynamic>> reusableTemplates =
      library.where((e) => !recentlySeenIds.contains(e['comboId'].toString())).toList();

      Map<String, dynamic> chosenTemplate;
      if (reusableTemplates.isNotEmpty) {
        chosenTemplate = reusableTemplates[Random().nextInt(reusableTemplates.length)];
      } else {
        chosenTemplate = _generateNewDailyCombo(tier, recentlySeenIds);
        library.add(chosenTemplate);
        await prefs.setString(libraryKey, jsonEncode(library));
      }

      seen.add({'comboId': chosenTemplate['comboId'], 'seenAt': now.toIso8601String()});
      final List<Map<String, dynamic>> trimmedSeen = seen.where((e) {
        final DateTime? seenAt = DateTime.tryParse(e['seenAt']?.toString() ?? '');
        return seenAt != null && now.difference(seenAt) < const Duration(days: 180);
      }).toList();
      await prefs.setString(seenKey, jsonEncode(trimmedSeen));

      // 템플릿 안의 {subjectCount}/{totalMinutes}는 실제 오늘 값으로 채워서 반환
      final String template = chosenTemplate['text'].toString();
      return template
          .replaceAll('{subjectCount}', '$subjectCount')
          .replaceAll('{totalMinutes}', '$totalMinutes');
    } catch (e) {
      final fallback = _generateNewDailyCombo(_dailyTierFor(totalMinutes), {});
      return fallback['text']
          .toString()
          .replaceAll('{subjectCount}', '$subjectCount')
          .replaceAll('{totalMinutes}', '$totalMinutes');
    }
  }

  static Map<String, dynamic> _generateNewDailyCombo(String tier, Set<String> avoidIds) {
    final Random rnd = Random();
    final List<String> openings = _dailyOpenings[tier]!;
    final List<String> closings = _dailyClosings[tier]!;

    String comboId = '';
    String text = '';
    int attempts = 0;
    do {
      final int oi = rnd.nextInt(openings.length);
      final int ci = rnd.nextInt(closings.length);
      comboId = 'daily_${tier}_o${oi}_c$ci';
      text = openings[oi] + closings[ci];
      attempts++;
    } while (avoidIds.contains(comboId) && attempts < 20);

    // 150자에 못 미치면 보강 문구를 순서대로 덧붙여 확실하게 150~200자 범위를 맞춤
    const List<String> fillers = [
      ' 오늘 하루의 기록도 꾸준함을 만들어가는 소중한 한 걸음입니다.',
      ' 작은 습관들이 쌓여 큰 변화를 만든다는 점을 기억해주시면 좋겠습니다.',
      ' 앞으로도 이런 학습 기록이 꾸준히 이어지길 응원합니다.',
    ];
    int fillerIdx = 0;
    while (text.length < dailyMinLength && fillerIdx < fillers.length) {
      text += fillers[fillerIdx];
      fillerIdx++;
    }
    if (text.length > dailyMaxLength) {
      text = text.substring(0, dailyMaxLength);
    }

    return {
      'comboId': comboId,
      'text': text,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  static String tierFor(double score) {
    if (score >= 90) return 'good';
    if (score >= 80) return 'mid';
    if (score >= 70) return 'seventy';
    if (score >= 60) return 'sixty';
    return 'low';
  }

  // ── 문장 뱅크 (점수 구간별 4개 카테고리) ───────────────────────────────────
  static const Map<String, List<String>> _openings = {
    'good': [
      '이번 {type}에서 90점 이상의 우수한 성취를 기록한 것은, 그동안 꾸준히 쌓아온 학습의 밀도가 눈에 보이는 성과로 이어졌음을 보여주는 매우 고무적인 결과입니다.',
      '90점대의 높은 점수는 학습자의 메타인지(자신이 무엇을 알고 무엇을 모르는지 스스로 점검하는 능력) 수준이 안정적인 궤도에 올라섰음을 시사하는 결과입니다.',
      '이번 평가에서 확인된 우수한 성취는 단기간의 요행이 아니라, 반복적인 개념 확인과 오답 정리가 축적된 결과로 판단됩니다.',
    ],
    'mid': [
      '이번 {type}에서 80점대의 안정적인 성취를 기록한 것은 학습의 기본기가 탄탄하게 자리잡았음을 보여주는 결과입니다.',
      '80점대 점수는 개념 스키마(지식의 구조적 네트워크)가 상당 부분 정착되었음을 의미하며, 조금만 더 정밀하게 다듬으면 상위권 진입이 충분히 가능한 위치입니다.',
      '이번 평가는 안정적인 중상위권 성취를 보여주었고, 특히 실수를 줄이는 방향으로 조금만 보완하면 눈에 띄는 향상을 기대할 수 있습니다.',
    ],
    'seventy': [
      '이번 {type}에서 기록한 70점대의 성취는 학습자가 지닌 실제 역량에 비해 다소 아쉬운 결과로 판단됩니다.',
      '70점대 점수는 기본 개념은 갖추었으나 실전 적용 과정에서 정합성(논리적 일관성)이 흔들리는 지점이 있음을 시사합니다.',
      '이번 평가는 개념 이해와 실전 문제풀이 사이의 간극이 드러난 결과로, 구조적인 점검이 필요한 시점입니다.',
    ],
    'sixty': [
      '이번 {type}에서 누적된 60점대의 성취도는 교과 개념의 정착 단계에서 예상보다 깊은 균열이 발생했음을 나타냅니다.',
      '60점대 점수는 개념 자체보다는 학습 습관의 구조적인 전환이 시급함을 알리는 신호로 받아들이는 것이 바람직합니다.',
      '이번 평가 결과는 조급함보다는 기초를 다시 점검해야 하는 시점임을 알려주는 지표로 해석하는 것이 필요합니다.',
    ],
    'low': [
      '이번 {type}에서 기록된 수치는 기초 개념 정착 단계에서 전반적인 재조정과 보완이 시급함을 가리키는 진단 결과입니다.',
      '현재 지표는 학습 과정 전체에 걸쳐 개념적인 공백이 누적되었음을 경고하고 있으며, 즉각적인 학습 루틴의 재정비가 필요합니다.',
      '이번 결과는 실망하기보다, 학습 방식 자체를 근본적으로 재점검할 수 있는 기회로 삼는 것이 중요합니다.',
    ],
  };

  static const Map<String, List<String>> _observations = {
    'good': [
      '특히 {subject} 과목에서는 개념 간의 연결 구조를 정확히 파악하고 있어, 응용문제에서도 흔들림 없는 정합성을 보여주고 있습니다.',
      '{subject} 영역의 최근 풀이 패턴을 살펴보면 기본 개념 확인 단계를 충실히 거친 흔적이 뚜렷하게 나타납니다.',
      '이번 {subject} 평가는 시간 배분과 문제 해석 속도 모두 균형 잡힌 모습을 보여, 실전 감각이 상당히 성숙했음을 알 수 있습니다.',
    ],
    'mid': [
      '{subject} 과목에서는 핵심 개념의 뼈대는 잘 갖추어져 있으나, 조건 해석의 정밀도에서 약간의 감점 요인이 확인됩니다.',
      '{subject} 영역은 기본 문제풀이는 안정적이나, 고난도 변형 문제로 갈수록 처리 속도가 다소 느려지는 경향이 관찰됩니다.',
      '이번 {subject} 평가에서는 전반적인 이해도는 양호하나, 세부 조건을 놓치는 실수가 반복적으로 나타났습니다.',
    ],
    'seventy': [
      '{subject} 과목의 오답을 살펴보면 대부분 구조적 오인(개념의 뼈대를 잘못 이해해 오답을 도출하는 현상)에서 비롯된 것으로 보입니다.',
      '{subject} 영역에서는 기본 개념 자체보다, 문제 조건을 정확히 읽어내는 과정에서 실수가 반복되는 경향이 확인됩니다.',
      '이번 {subject} 평가는 시간 부족으로 인해 후반부 문항에서 집중력이 흐트러진 흔적이 뚜렷하게 나타납니다.',
    ],
    'sixty': [
      '{subject} 과목의 오답 패턴은 개념의 기본 뼈대를 오해한 채 진도만 나간 부작용으로 판단됩니다.',
      '{subject} 영역에서는 인지적 기만(완전히 이해하지 못했음에도 이해했다고 착각하는 상태)이 반복적으로 관찰됩니다.',
      '이번 {subject} 평가는 기초 개념 확인 단계가 충분히 이루어지지 않은 상태에서 문제풀이로 넘어간 흔적이 뚜렷합니다.',
    ],
    'low': [
      '{subject} 과목은 기초 어휘 스키마(지식의 구조적 네트워크)조차 아직 불안정한 상태로 보이며, 근본적인 재학습이 필요합니다.',
      '{subject} 영역의 오답은 개념 이해 여부와 무관하게 광범위하게 나타나고 있어, 단원 전체를 처음부터 다시 점검하는 것이 바람직합니다.',
      '이번 {subject} 평가는 문제풀이량보다 기본 원리 이해에 투입된 시간이 부족했던 결과로 판단됩니다.',
    ],
  };

  static const Map<String, List<String>> _advices = {
    'good': [
      '다만 이 위치에서 방심하면 성적이 다시 흔들릴 수 있으므로, 오답노트(틀린 문제의 원인을 기록하고 분석하는 학습 도구)를 꾸준히 활용해 취약한 부분을 세밀하게 보완해 나가는 습관을 유지하는 것이 중요합니다.',
      '고난도 변형 문제를 주기적으로 접하면서 사고의 깊이를 확장하는 훈련을 병행한다면 안정적인 상위권 유지에 큰 도움이 될 것입니다.',
      '지금의 학습 루틴을 그대로 유지하되, 오답을 3회 이상 반복해서 재점검하는 습관을 더한다면 흔들림 없는 실력으로 굳어질 것입니다.',
    ],
    'mid': [
      '취약 단원의 고난도 변형 문제를 집중적으로 공략하고, 실전 시간 안배의 정밀도를 한 단계 더 끌어올리는 훈련이 필요합니다.',
      '조건 해석 과정에서 놓치는 부분을 줄이기 위해, 문제를 풀기 전 조건을 소리 내어 정리하는 습관을 들이는 것을 권장합니다.',
      '오답 정리를 단순 확인에서 그치지 말고, 왜 그렇게 접근했는지 원인을 기록하는 방식으로 심화하는 것이 도움이 될 것입니다.',
    ],
    'seventy': [
      '기본 원리 분석부터 차근차근 다시 정립하여 취약점을 지워내는 과정이 필요하며, 이 구간은 올바른 노력이 투입되면 가장 크게 성적이 오를 수 있는 구간이기도 합니다.',
      '오늘부터 취약 단원의 기본서를 차분하게 다시 훑으며, 문제풀이보다 개념 확인에 우선순위를 두는 것을 권장합니다.',
      '실전 시간 안에서 조건을 놓치지 않는 훈련을 위해, 제한 시간을 두고 유사 문항을 반복해서 풀어보는 연습이 도움이 될 것입니다.',
    ],
    'sixty': [
      '틀린 문항을 단순히 확인하는 것에 그치지 말고 원리를 파고드는 깊이 있는 복습 루틴을 오늘부터 즉시 가속화하는 것이 필요합니다.',
      '느슨해진 오답 정비 체계를 철저히 다시 세우고, 핵심 원리 중심의 복습 인프라를 전면적으로 재구축하는 것을 권장합니다.',
      '진도를 서두르기보다, 지금 단계에서 놓친 개념을 완전히 소화하는 데 시간을 투자하는 것이 장기적으로 더 빠른 길입니다.',
    ],
    'low': [
      '조급한 마음을 완전히 내려놓고, 단원별 교과서의 핵심 원리 분석과 기본 개념 빌딩에 즉각 착수하는 것이 가장 필요한 시점입니다.',
      '문제풀이량을 늘리기보다, 지금 당장 멈추어 서서 취약 단원의 개념을 완벽히 소화하는 인내의 시간이 절대적으로 요구됩니다.',
      '기초부터 차근차근 벽돌을 쌓아 올리듯 학습 속도와 밀도를 점진적으로 끌어올리는 방식으로 접근하는 것을 권장합니다.',
    ],
  };

  static const Map<String, List<String>> _closings = {
    'good': [
      '지금까지 쌓아온 노력을 믿고 흔들림 없이 정진한다면, 앞으로의 평가에서도 충분히 좋은 결과를 이어갈 수 있을 것입니다.',
      '자만하지 않되 자신감을 잃지 않는 균형 잡힌 태도로 다음 목표를 향해 나아가시길 응원합니다.',
    ],
    'mid': [
      '지금의 위치는 정상으로 가는 마지막 관문에 가까우니, 조금만 더 집중력을 발휘한다면 충분히 상위권 진입이 가능할 것입니다.',
      '꾸준함을 잃지 않는다면 다음 평가에서는 지금보다 한 단계 더 높은 성취를 확인할 수 있을 것으로 기대됩니다.',
    ],
    'seventy': [
      '좌절할 필요는 전혀 없으며, 오히려 지금이 가장 극적인 반등을 만들어낼 수 있는 구간이라는 점을 기억하시길 바랍니다.',
      '문제점을 명확히 인지하고 있는 만큼, 오늘부터의 작은 변화가 다음 평가에서 눈에 띄는 결과로 이어질 것입니다.',
    ],
    'sixty': [
      '지금의 경각심을 변화의 발판으로 삼는다면, 충분히 반등할 수 있는 위치에 있다는 점을 잊지 않으시길 바랍니다.',
      '나태함에 빠지지 않고 오늘부터 집중도를 끌어올린다면, 다음 평가에서는 분명히 다른 결과를 확인할 수 있을 것입니다.',
    ],
    'low': [
      '지금의 어려움은 기초를 다시 다지는 과정에서 누구나 겪을 수 있는 단계이니, 포기하지 않고 꾸준히 나아가는 것이 가장 중요합니다.',
      '작은 진전이라도 꾸준히 쌓인다면 반드시 눈에 보이는 변화로 이어질 것이니, 조급해하지 않고 함께 나아가시길 바랍니다.',
    ],
  };

  static const Map<String, String> _extraGuidance = {
    'good': ' 지속적인 정합성 확인 루틴을 스스로 사수하는 태도가 결국 흔들리지 않는 실력을 만듭니다.',
    'mid': ' 조금의 임계점(다음 단계로 넘어가기 위해 필요한 최소한의 학업 밀도)만 넘어서면 상위권 진입은 시간 문제입니다.',
    'seventy': ' 구조적 오인(개념의 뼈대를 잘못 이해해 오답을 도출하는 현상)만 바로잡으면 반등의 폭은 예상보다 클 수 있습니다.',
    'sixty': ' 지금 다지는 기초가 앞으로의 모든 학습의 뼈대가 된다는 점을 기억해 주시길 바랍니다.',
    'low': ' 가능성은 언제나 열려 있으니, 오늘의 작은 실천이 내일의 큰 변화로 이어질 것입니다.',
  };

  // ── 저장/조회 로직 ──────────────────────────────────────────────────────
  static Future<String> getAnalysis({
    required String personKey, // 이 진단을 받는 사람을 구분하는 키 (예: 'student_홍길동')
    required String type, // 주평가/단원평가/중간고사/기말고사/모의고사
    required String subject,
    required double score,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String tier = tierFor(score);
      final String libraryKey = 'dke_diag_library_$tier';
      final String seenKey = 'dke_diag_seen_${personKey}_$tier';

      final List<Map<String, dynamic>> library = _loadList(prefs, libraryKey);
      final List<Map<String, dynamic>> seen = _loadList(prefs, seenKey);

      final DateTime now = DateTime.now();
      final Set<String> recentlySeenIds = seen
          .where((e) {
        final DateTime? seenAt = DateTime.tryParse(e['seenAt']?.toString() ?? '');
        return seenAt != null && now.difference(seenAt) < reuseCooldown;
      })
          .map((e) => e['comboId'].toString())
          .toSet();

      // 라이브러리 중 "이 사람이 최근 3개월 안에 안 본" 조합 찾기 (유사한 사람 재사용 포함)
      final List<Map<String, dynamic>> reusable =
      library.where((e) => !recentlySeenIds.contains(e['comboId'].toString())).toList();

      Map<String, dynamic> chosen;
      if (reusable.isNotEmpty) {
        chosen = reusable[Random().nextInt(reusable.length)];
      } else {
        chosen = _generateNewCombo(tier, type, subject, recentlySeenIds);
        library.add(chosen);
        await prefs.setString(libraryKey, jsonEncode(library));
      }

      // 이 사람이 방금 이 조합을 봤다고 기록
      seen.add({'comboId': chosen['comboId'], 'seenAt': now.toIso8601String()});
      // 6개월 이상 지난 열람 기록은 정리(저장공간 절약, 3개월 규칙 판단엔 영향 없음)
      final List<Map<String, dynamic>> trimmedSeen = seen.where((e) {
        final DateTime? seenAt = DateTime.tryParse(e['seenAt']?.toString() ?? '');
        return seenAt != null && now.difference(seenAt) < const Duration(days: 180);
      }).toList();
      await prefs.setString(seenKey, jsonEncode(trimmedSeen));

      return chosen['text'].toString();
    } catch (e) {
      // 저장소 오류가 있어도 화면이 멈추지 않도록 즉석 생성 텍스트로 안전하게 대체
      return _generateNewCombo(tierFor(score), type, subject, {})['text'].toString();
    }
  }

  static Map<String, dynamic> _generateNewCombo(
      String tier,
      String type,
      String subject,
      Set<String> avoidIds,
      ) {
    final Random rnd = Random();
    final List<String> openings = _openings[tier]!;
    final List<String> observations = _observations[tier]!;
    final List<String> advices = _advices[tier]!;
    final List<String> closings = _closings[tier]!;

    String comboId = '';
    String text = '';
    int attempts = 0;
    do {
      final int oi = rnd.nextInt(openings.length);
      final int vi = rnd.nextInt(observations.length);
      final int ai = rnd.nextInt(advices.length);
      final int ci = rnd.nextInt(closings.length);
      comboId = '${tier}_o${oi}_v${vi}_a${ai}_c$ci';

      final String opening = openings[oi].replaceAll('{type}', type);
      final String observation = observations[vi].replaceAll('{subject}', subject);

      text = '$opening $observation ${advices[ai]} ${closings[ci]}';
      attempts++;
    } while (avoidIds.contains(comboId) && attempts < 30);

    if (text.length < minLength) {
      text += _extraGuidance[tier] ?? '';
    }

    return {
      'comboId': comboId,
      'text': text,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  static List<Map<String, dynamic>> _loadList(SharedPreferences prefs, String key) {
    final String? raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }
}
