import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// [GKE StudyUp] 성적관리 종합 총평 생성 서비스
/// - 비용 절감을 위해 실제 AI API를 호출하지 않고, 규칙 기반 문구뱅크에서 조합합니다.
///   (member_achievement_screen.dart의 _buildRuleBasedDiagnosisText와 동일한 원칙)
/// - 한 번 생성된 문구는 즉시 저장하고, "같은 학생(personKey)"에게는 절대 재사용하지
///   않습니다. 대신 점수대(10점 버킷)가 비슷한 "다른" 학생에게는 저장된 문구를
///   재사용할 수 있게 하여, 매번 새로 만들지 않고도 문구가 겹치지 않도록 설계했습니다.
/// - 전문용어는 반드시 괄호로 풀어서 설명합니다.
/// ============================================================================
class GradeDiagnosisService {
  GradeDiagnosisService._();

  static const String _bucketKeyPrefix = 'gke_grade_diag_bucket_';
  static const String _seenKeyPrefix = 'gke_grade_diag_seen_';
  static const String _currentKeyPrefix = 'gke_grade_diag_current_';

  /// combinedAverage: 성적관리(지필+수행 반영) 종합평균
  /// achievementAverage: "성취도"(gke_exam_records)에 기록된 전체 평가 평균(있으면 함께 반영)
  ///
  /// 🆕 [요청] 학생 화면과 학부모 화면이 항상 "동일한 문구"를 보도록, personKey별로
  /// 마지막에 보여준 문구를 별도 캐시(_currentKeyPrefix)에 저장해 둡니다.
  /// 점수대(버킷)가 바뀌지 않는 한 같은 문구를 계속 재사용하고, 점수대가 실제로
  /// 바뀌었을 때만 새 문구를 뽑아(또는 생성해) 캐시를 갱신합니다.
  static Future<String> getOverallSummary({
    required String personKey,
    required double combinedAverage,
    double? achievementAverage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final int bucket = (combinedAverage.clamp(0, 100) ~/ 10) * 10;
    final String currentKey = '$_currentKeyPrefix$personKey';

    final String? currentRaw = prefs.getString(currentKey);
    if (currentRaw != null && currentRaw.isNotEmpty) {
      try {
        final Map<String, dynamic> cached = jsonDecode(currentRaw);
        if ((cached['bucket'] as num?)?.toInt() == bucket && cached['text'] is String) {
          return cached['text'] as String;
        }
      } catch (_) {}
    }

    final String bucketKey = '$_bucketKeyPrefix$bucket';
    final String seenKey = '$_seenKeyPrefix$personKey';
    final List<String> bucketPhrases = prefs.getStringList(bucketKey) ?? [];
    final List<String> seenPhrases = prefs.getStringList(seenKey) ?? [];

    String result;
    // 1) 같은 점수대에 이미 저장된 문구 중, 본인이 아직 받아본 적 없는 것이 있으면 재사용
    final String? reusable = bucketPhrases.firstWhere((p) => !seenPhrases.contains(p), orElse: () => "");
    if (reusable != null && reusable.isNotEmpty) {
      result = reusable;
      seenPhrases.add(result);
      await prefs.setStringList(seenKey, seenPhrases);
    } else {
      // 2) 없으면 새로 생성 후 버킷/본인기록 양쪽에 저장
      result = _generate(combinedAverage, achievementAverage);
      bucketPhrases.add(result);
      seenPhrases.add(result);
      await prefs.setStringList(bucketKey, bucketPhrases);
      await prefs.setStringList(seenKey, seenPhrases);
    }

    await prefs.setString(currentKey, jsonEncode({'bucket': bucket, 'text': result}));
    return result;
  }

  static const Map<String, List<String>> _openings = {
    'excellent': [
      '지필점수와 수행점수(수업 중 과제·발표·태도 등을 평가에 반영하는 항목)를 종합한 결과, 90점대 이상의 매우 우수한 성취 수준을 보이고 있습니다. ',
      '두 영역을 합산한 종합 반영점수가 최상위권에 안정적으로 자리 잡고 있어, 그동안의 학습 밀도가 실제 성과로 정확히 이어지고 있음을 보여줍니다. ',
    ],
    'good': [
      '지필과 수행을 종합한 반영점수가 80점대 우수권에 위치해 있어, 개념 이해(핵심 원리를 스스로 설명할 수 있는 수준의 앎)와 실행력이 고르게 갖춰진 상태입니다. ',
      '전반적으로 안정적인 종합 성취 흐름을 보이고 있으며, 조금만 더 정교하게 다듬으면 최상위권 진입도 충분히 가능한 위치입니다. ',
    ],
    'mid': [
      '종합 반영점수가 70점대로, 기본기는 갖췄으나 지필과 수행 중 한쪽에서 편차(점수 차이)가 발생하고 있어 균형을 맞출 필요가 있습니다. ',
      '지필·수행 합산 결과가 중위권에 머물러 있어, 취약한 영역을 구체적으로 짚어 보완하면 단기간에 상승 폭을 기대할 수 있는 구간입니다. ',
    ],
    'low': [
      '종합 반영점수가 60점대로, 기초 개념 정착 단계에서 다소 아쉬운 결과가 확인되어 보완이 필요한 시점입니다. ',
      '지필과 수행 점수를 함께 살펴본 결과, 현재 수준에 비해 성취가 낮게 나타나고 있어 학습 습관 전반의 점검이 요구됩니다. ',
    ],
    'critical': [
      '종합 반영점수가 60점 미만으로, 기초 개념 정착부터 다시 다져야 하는 상황임을 알려주는 결과입니다. ',
      '지필·수행 합산 결과가 낮게 나타나고 있어, 조급하게 문제풀이량만 늘리기보다 기본 개념부터 차근히 재정비하는 과정이 필요합니다. ',
    ],
  };

  static const Map<String, List<String>> _closings = {
    'excellent': [
      '다만 현재 수준에 안주하지 않고, 오답 원인을 기록·분석하는 오답노트(틀린 이유를 되짚어 정리하는 습관)를 꾸준히 유지하면 흔들림 없는 최상위권을 지켜낼 수 있습니다.',
      '이 흐름을 유지하려면 수행평가 준비도 지필 못지않게 꼼꼼히 챙기는 균형 잡힌 습관을 계속 이어가시길 권합니다.',
    ],
    'good': [
      '수행평가에서 놓치는 소소한 감점 요인들을 점검하고, 지필에서는 고난도 응용 문제 위주로 보완하면 상승 여지가 충분합니다.',
      '메타인지(자신이 무엇을 알고 무엇을 모르는지 스스로 점검하는 능력)를 활용해 취약 단원을 구체적으로 짚어보는 습관을 들이면 좋겠습니다.',
    ],
    'mid': [
      '지필과 수행 중 상대적으로 약한 영역을 먼저 파악한 뒤, 그 영역에 학습 시간을 집중 배분하는 전략이 효과적일 것으로 보입니다.',
      '기본 개념을 다시 짚어보는 복습 루틴을 꾸준히 유지한다면, 다음 시험에서 의미 있는 반등을 기대할 수 있습니다.',
    ],
    'low': [
      '조급함보다는 기본 개념서를 처음부터 차분히 다시 훑어보는 방식으로 학습 밀도를 높여가는 것을 권해 드립니다.',
      '수행평가 준비 과정부터 꾸준히 챙기며 작은 성취를 쌓아가면, 자신감과 함께 점수도 서서히 회복될 것입니다.',
    ],
    'critical': [
      '지금은 문제 양보다 기본 개념 하나하나를 확실히 이해하는 데 집중하는 시기이며, 작은 성공 경험을 쌓아가는 것이 무엇보다 중요합니다.',
      '주변의 도움을 받아 취약한 기초 단원부터 차근차근 짚어나가면, 충분히 반등할 수 있는 잠재력이 있습니다.',
    ],
  };

  // 🆕 250자 전후 분량을 안정적으로 맞추기 위한 중간 문장(성적대별 공통 보완 코멘트)
  static const Map<String, List<String>> _middles = {
    'excellent': [
      ' 특히 시험 종류(중간고사·기말고사·모의고사)별로 편차 없이 고르게 좋은 흐름을 보이는 점이 인상적입니다.',
      ' 지필과 수행 두 영역의 반영비율이 달라져도 흔들리지 않을 만큼 기초가 탄탄하게 잡혀 있는 상태입니다.',
    ],
    'good': [
      ' 시험 종류별로 살펴보면 특정 유형에서 다소 아쉬운 부분이 보이므로, 해당 부분을 짚어보면 좋겠습니다.',
      ' 지필과 수행 중 상대적으로 낮은 쪽을 확인해 보완하면 더 안정적인 흐름을 만들 수 있습니다.',
    ],
    'mid': [
      ' 특히 수행평가 준비 과정에서의 꾸준함이 전체 반영점수에 큰 영향을 주는 구간이므로 유의가 필요합니다.',
      ' 시험 종류별 점수를 비교해 보면 유독 약한 영역이 눈에 띄므로, 그 부분부터 우선 점검해 보시길 권합니다.',
    ],
    'low': [
      ' 지필과 수행 어느 한쪽에 치우치지 않고 두 영역을 골고루 챙기는 습관부터 다시 잡아가는 것이 중요합니다.',
      ' 시험 종류에 따라 편차가 크게 나타나고 있어, 부족한 유형을 구체적으로 짚어주는 지도가 도움이 될 것입니다.',
    ],
    'critical': [
      ' 지필과 수행 모두에서 보완이 필요한 상태이므로, 하나씩 순서를 정해 차근히 접근하는 것이 효과적입니다.',
      ' 당장의 점수보다 학습 습관 자체를 다시 세우는 과정이 우선되어야 하는 시점으로 보입니다.',
    ],
  };

  static String _tierFor(double avg) {
    if (avg >= 90) return 'excellent';
    if (avg >= 80) return 'good';
    if (avg >= 70) return 'mid';
    if (avg >= 60) return 'low';
    return 'critical';
  }

  static String _generate(double combinedAverage, double? achievementAverage) {
    final random = math.Random();
    final String tier = _tierFor(combinedAverage);
    final List<String> openings = _openings[tier]!;
    final List<String> closings = _closings[tier]!;

    final List<String> middles = _middles[tier]!;
    String text = openings[random.nextInt(openings.length)]
        + middles[random.nextInt(middles.length)]
        + closings[random.nextInt(closings.length)];

    // 🆕 [요청] 성취도(gke_exam_records) 기록도 참고해서 한 문장 추가 (약 250자 전후 맞춤)
    if (achievementAverage != null) {
      final double gap = combinedAverage - achievementAverage;
      if (gap.abs() < 5) {
        text += ' 평소 학습 기록에 나타난 성취도 흐름과도 비슷한 수준을 유지하고 있어, 실력이 안정적으로 자리 잡았다고 볼 수 있습니다.';
      } else if (gap > 0) {
        text += ' 평소 학습 기록보다 이번 성적관리 반영점수가 더 높게 나타나, 최근 집중도가 상승한 것으로 보입니다.';
      } else {
        text += ' 평소 학습 기록에 비해 이번 반영점수가 다소 낮게 나타나, 컨디션이나 준비 과정을 함께 점검해 볼 필요가 있습니다.';
      }
    }

    return text;
  }
}
