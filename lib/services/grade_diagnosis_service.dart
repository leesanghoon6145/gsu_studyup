import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../global_lang.dart';

/// ============================================================================
/// [GKE StudyUp] 성적관리 종합 총평 생성 서비스
/// - 비용 절감을 위해 실제 AI API를 호출하지 않고, 규칙 기반 문구뱅크에서 조합합니다.
/// - 한 번 생성된 문구는 즉시 저장하고, "같은 학생(personKey)"에게는 절대 재사용하지
///   않습니다. 대신 점수대(10점 버킷)가 비슷한 "다른" 학생에게는 저장된 문구를
///   재사용할 수 있게 하여, 매번 새로 만들지 않고도 문구가 겹치지 않도록 설계했습니다.
/// - 🆕 [12개국어 전면 확장] 한 번 생성할 때 12개 언어(KO/EN/JA/ZH/FR/DE/RU/AR/HI/VI/ES/TH)를
///   전부 함께 만들어 저장합니다. 화면에서는 DkeLang 설정에 따라 기본모드(한글+영문 동시)
///   또는 선택된 1개 언어만 표시합니다.
/// ============================================================================
class GradeSummaryResult {
  final Map<String, String> texts; // 언어코드 -> 총평 텍스트
  const GradeSummaryResult(this.texts);

  String forLang(String code) => texts[code] ?? texts['EN'] ?? texts['KO'] ?? '';

  /// DkeLang 현재 설정에 맞춰 표시용 문자열 생성
  /// - 10개국어 선택 시: 해당 언어 단독
  /// - 기본모드(KO/EN): 한글+영문 동시(두 줄바꿈으로 구분)
  String display() {
    if (DkeLang.isForeignSelected) return forLang(DkeLang.current);
    return "${forLang('KO')}\n\n${forLang('EN')}";
  }

  Map<String, dynamic> toJson() => texts;
  factory GradeSummaryResult.fromJson(Map<String, dynamic> json) =>
      GradeSummaryResult(json.map((k, v) => MapEntry(k, v.toString())));
}

class GradeDiagnosisService {
  GradeDiagnosisService._();

  static const String _bucketKeyPrefix = 'gke_grade_diag_bucket_';
  static const String _seenKeyPrefix = 'gke_grade_diag_seen_';
  static const String _currentKeyPrefix = 'gke_grade_diag_current_';

  static const List<String> _langCodes = ['KO', 'EN', 'JA', 'ZH', 'FR', 'DE', 'RU', 'AR', 'HI', 'VI', 'ES', 'TH'];

  /// combinedAverage: 성적관리(지필+수행 반영) 종합평균
  /// achievementAverage: "성취도"(gke_exam_records)에 기록된 전체 평가 평균(있으면 함께 반영)
  ///
  /// 🆕 학생 화면과 학부모 화면이 항상 "동일한 문구"를 보도록, personKey별로 마지막에
  /// 보여준 문구 세트를 캐시(_currentKeyPrefix)에 저장합니다. 점수대(버킷)가 바뀌지 않는
  /// 한 같은 문구를 계속 재사용하고, 점수대가 실제로 바뀌었을 때만 새로 뽑습니다.
  static Future<GradeSummaryResult> getOverallSummary({
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
        if ((cached['bucket'] as num?)?.toInt() == bucket && cached['texts'] is Map) {
          return GradeSummaryResult.fromJson(Map<String, dynamic>.from(cached['texts'] as Map));
        }
      } catch (_) {}
    }

    final String bucketKey = '$_bucketKeyPrefix$bucket';
    final String seenKey = '$_seenKeyPrefix$personKey';
    final List<String> bucketSetsRaw = prefs.getStringList(bucketKey) ?? [];
    final List<String> seenSetsRaw = prefs.getStringList(seenKey) ?? [];

    String resultRaw;
    // 1) 같은 점수대에 이미 저장된 문구 세트 중, 본인이 아직 받아본 적 없는 것이 있으면 재사용
    final String reusable = bucketSetsRaw.firstWhere((p) => !seenSetsRaw.contains(p), orElse: () => "");
    if (reusable.isNotEmpty) {
      resultRaw = reusable;
      seenSetsRaw.add(resultRaw);
      await prefs.setStringList(seenKey, seenSetsRaw);
    } else {
      // 2) 없으면 새로 생성(12개 언어 동시) 후 버킷/본인기록 양쪽에 저장
      final GradeSummaryResult generated = _generate(combinedAverage, achievementAverage);
      resultRaw = jsonEncode(generated.texts);
      bucketSetsRaw.add(resultRaw);
      seenSetsRaw.add(resultRaw);
      await prefs.setStringList(bucketKey, bucketSetsRaw);
      await prefs.setStringList(seenKey, seenSetsRaw);
    }

    final Map<String, dynamic> decoded = jsonDecode(resultRaw);
    final GradeSummaryResult result = GradeSummaryResult.fromJson(Map<String, dynamic>.from(decoded));
    await prefs.setString(currentKey, jsonEncode({'bucket': bucket, 'texts': result.texts}));
    return result;
  }

  // ==========================================================================
  // 문구뱅크: tier(excellent/good/mid/low/critical) -> lang -> [변형1, 변형2]
  // ==========================================================================
  static const Map<String, Map<String, List<String>>> _openings = {
    'excellent': {
      'KO': ['지필점수와 수행점수(수업 중 과제·발표·태도 등을 평가에 반영하는 항목)를 종합한 결과, 90점대 이상의 매우 우수한 성취 수준을 보이고 있습니다. ', '두 영역을 합산한 종합 반영점수가 최상위권에 안정적으로 자리 잡고 있어, 그동안의 학습 밀도가 실제 성과로 정확히 이어지고 있음을 보여줍니다. '],
      'EN': ['Combining written and performance scores (performance reflects coursework such as assignments, presentations, and class participation), the result shows an outstanding achievement level in the 90s. ', 'The combined reflected score sits solidly in the top tier, showing that sustained study effort is translating directly into real results. '],
      'JA': ['筆記点数と遂行評価点数（授業中の課題・発表・態度などを反映する項目）を総合した結果、90点台以上の非常に優れた成果水準を示しています。 ', '両領域を合算した総合反映点数が最上位圏に安定して位置しており、これまでの学習密度が実際の成果に正確につながっていることを示します。 '],
      'ZH': ['综合笔试成绩与表现评价成绩（表现评价包括课堂作业、发表、态度等）后，取得了90分以上的优异成绩水平。 ', '两项合并后的综合反映分数稳居最高水平，表明长期以来的学习密度已经切实转化为实际成果。 '],
      'FR': ["En combinant les notes écrites et de performance (la performance reflète les travaux, présentations et participation en classe), le résultat montre un niveau de réussite exceptionnel dans les 90. ", "Le score combiné se situe solidement dans le peloton de tête, montrant que l'effort d'étude soutenu se traduit directement en résultats concrets. "],
      'DE': ['Die Kombination aus schriftlicher und Leistungsnote (Leistung umfasst Aufgaben, Präsentationen und Unterrichtsbeteiligung) zeigt ein hervorragendes Ergebnis im 90er-Bereich. ', 'Der kombinierte Gesamtwert liegt solide in der Spitzengruppe, was zeigt, dass anhaltender Lerneinsatz sich direkt in echten Ergebnissen niederschlägt. '],
      'RU': ['Сочетание письменной оценки и оценки за практическую работу (задания, презентации, участие на занятиях) показывает выдающийся уровень достижений — выше 90 баллов. ', 'Итоговый совокупный балл стабильно держится в верхнем эшелоне, что показывает, как устойчивые учебные усилия напрямую превращаются в реальные результаты. '],
      'AR': ['بجمع الدرجة التحريرية ودرجة الأداء (الأداء يشمل الواجبات والعروض والمشاركة الصفية)، تُظهر النتيجة مستوى تحصيل ممتاز يتجاوز 90 درجة. ', 'تستقر الدرجة المجمعة بثبات في الفئة العليا، مما يدل على أن الجهد الدراسي المستمر يترجم مباشرة إلى نتائج حقيقية. '],
      'HI': ['लिखित अंक और प्रदर्शन अंक (प्रदर्शन में असाइनमेंट, प्रस्तुति, कक्षा भागीदारी शामिल है) को मिलाकर देखने पर, परिणाम 90 के दशक में उत्कृष्ट उपलब्धि स्तर दर्शाता है। ', 'संयुक्त स्कोर शीर्ष स्तर पर मजबूती से टिका है, जो दिखाता है कि निरंतर अध्ययन प्रयास सीधे वास्तविक परिणामों में बदल रहा है। '],
      'VI': ['Kết hợp điểm viết và điểm thực hành (thực hành phản ánh bài tập, thuyết trình, thái độ trên lớp), kết quả cho thấy mức thành tích xuất sắc trên 90 điểm. ', 'Điểm tổng hợp giữ vững ở nhóm dẫn đầu, cho thấy nỗ lực học tập bền bỉ đang chuyển hóa trực tiếp thành kết quả thực tế. '],
      'ES': ['Al combinar las notas escritas y de desempeño (el desempeño refleja tareas, presentaciones y participación en clase), el resultado muestra un nivel de logro sobresaliente por encima de 90. ', 'La puntuación combinada se mantiene sólidamente en el nivel más alto, mostrando que el esfuerzo constante se traduce directamente en resultados reales. '],
      'TH': ['เมื่อรวมคะแนนข้อเขียนและคะแนนภาคปฏิบัติ (ภาคปฏิบัติสะท้อนงานที่ได้รับมอบหมาย การนำเสนอ และการมีส่วนร่วมในชั้นเรียน) ผลลัพธ์แสดงถึงระดับความสำเร็จที่ยอดเยี่ยมในช่วง 90 ขึ้นไป ', 'คะแนนรวมอยู่ในกลุ่มสูงสุดอย่างมั่นคง แสดงให้เห็นว่าความทุ่มเทในการเรียนอย่างต่อเนื่องได้แปลงเป็นผลลัพธ์จริงโดยตรง '],
    },
    'good': {
      'KO': ['지필과 수행을 종합한 반영점수가 80점대 우수권에 위치해 있어, 개념 이해(핵심 원리를 스스로 설명할 수 있는 수준의 앎)와 실행력이 고르게 갖춰진 상태입니다. ', '전반적으로 안정적인 종합 성취 흐름을 보이고 있으며, 조금만 더 정교하게 다듬으면 최상위권 진입도 충분히 가능한 위치입니다. '],
      'EN': ['The combined written and performance score sits in the strong 80s range, showing solid conceptual understanding (the ability to explain core principles independently) paired with consistent execution. ', 'Overall achievement has been on a steady, stable trend, and with a bit more refinement, reaching the very top tier is well within reach. '],
      'JA': ['筆記と遂行を総合した反映点数が80点台の優秀圏に位置しており、概念理解（核心原理を自ら説明できる水準の知識）と実行力がバランスよく備わっています。 ', '全般的に安定した総合成果の流れを見せており、もう少し精緻に仕上げれば最上位圏への到達も十分可能な位置です。 '],
      'ZH': ['笔试与表现综合反映分数处于80分段的优秀区间，概念理解（能独立说明核心原理的知识水平）与执行力都较为均衡。 ', '整体呈现稳定的综合成就趋势，只要再精细打磨一下，完全有能力冲击最高水平。 '],
      'FR': ["Le score combiné écrit et performance se situe dans la solide fourchette des 80, montrant une bonne compréhension conceptuelle (capacité à expliquer les principes de base de façon autonome) alliée à une exécution constante. ", "La réussite globale suit une tendance stable, et avec un peu plus de raffinement, atteindre le tout premier rang est tout à fait accessible. "],
      'DE': ['Der kombinierte Wert aus schriftlicher und Leistungsnote liegt im soliden 80er-Bereich und zeigt ein gutes konzeptionelles Verständnis (die Fähigkeit, Kernprinzipien selbstständig zu erklären) gepaart mit stetiger Umsetzung. ', 'Die Gesamtleistung zeigt einen stabilen Trend, und mit etwas mehr Feinschliff ist die absolute Spitzengruppe gut erreichbar. '],
      'RU': ['Совокупный балл письменной и практической части находится в уверенном диапазоне 80-х, что показывает хорошее понимание концепций (умение самостоятельно объяснить базовые принципы) наряду со стабильным исполнением. ', 'Общая успеваемость демонстрирует стабильную тенденцию, и при небольшой доработке выход на самый верхний уровень вполне достижим. '],
      'AR': ['تقع الدرجة المجمعة للتحريري والأداء في نطاق الثمانينيات القوي، مما يظهر فهمًا مفاهيميًا جيدًا (القدرة على شرح المبادئ الأساسية بشكل مستقل) إلى جانب أداء ثابت. ', 'يُظهر التحصيل العام اتجاهًا مستقرًا، ومع القليل من الصقل الإضافي يصبح الوصول إلى أعلى مستوى ممكنًا تمامًا. '],
      'HI': ['लिखित और प्रदर्शन का संयुक्त स्कोर मजबूत 80 के दशक की सीमा में है, जो ठोस अवधारणा समझ (मूल सिद्धांतों को स्वतंत्र रूप से समझाने की क्षमता) के साथ निरंतर क्रियान्वयन दिखाता है। ', 'समग्र उपलब्धि स्थिर प्रवृत्ति में रही है, और थोड़े और परिष्करण के साथ शीर्ष स्तर तक पहुंचना पूरी तरह संभव है। '],
      'VI': ['Điểm tổng hợp giữa điểm viết và điểm thực hành nằm trong khoảng 80 vững chắc, cho thấy sự hiểu biết khái niệm tốt (khả năng tự giải thích nguyên lý cốt lõi) đi kèm với thực hiện ổn định. ', 'Thành tích tổng thể duy trì xu hướng ổn định, và chỉ cần trau chuốt thêm một chút là hoàn toàn có thể vươn tới nhóm dẫn đầu. '],
      'ES': ['La puntuación combinada de escrito y desempeño se sitúa en el sólido rango de los 80, mostrando buena comprensión conceptual (capacidad de explicar principios básicos de forma independiente) junto con una ejecución constante. ', 'El logro general ha mostrado una tendencia estable, y con un poco más de refinamiento, alcanzar el nivel más alto está totalmente al alcance. '],
      'TH': ['คะแนนรวมของข้อเขียนและภาคปฏิบัติอยู่ในช่วง 80 ที่แข็งแกร่ง แสดงถึงความเข้าใจแนวคิดที่ดี (ความสามารถในการอธิบายหลักการสำคัญได้ด้วยตนเอง) ควบคู่กับการปฏิบัติที่สม่ำเสมอ ', 'ผลสัมฤทธิ์โดยรวมมีแนวโน้มที่มั่นคง และหากขัดเกลาเพิ่มอีกเล็กน้อยก็สามารถก้าวสู่ระดับสูงสุดได้อย่างแน่นอน '],
    },
    'mid': {
      'KO': ['종합 반영점수가 70점대로, 기본기는 갖췄으나 지필과 수행 중 한쪽에서 편차(점수 차이)가 발생하고 있어 균형을 맞출 필요가 있습니다. ', '지필·수행 합산 결과가 중위권에 머물러 있어, 취약한 영역을 구체적으로 짚어 보완하면 단기간에 상승 폭을 기대할 수 있는 구간입니다. '],
      'EN': ['The combined score sits in the 70s — the basics are in place, but a gap between the written and performance components suggests some rebalancing is needed. ', 'The combined written and performance result is in the mid tier; identifying and reinforcing specific weak spots could bring a meaningful rise in the short term. '],
      'JA': ['総合反映点数が70点台であり、基礎力はあるものの筆記と遂行の間に偏差（点数差）が生じており、バランス調整が必要です。 ', '筆記・遂行の合算結果が中位圏にとどまっており、弱点領域を具体的に把握して補強すれば短期間で伸びが期待できる区間です。 '],
      'ZH': ['综合反映分数在70分段，虽具备基础，但笔试与表现之间存在偏差（分数差），需要调整平衡。 ', '笔试与表现的合计结果处于中等水平，若能明确找出薄弱环节加以补强，短期内可期待明显提升。 '],
      'FR': ["Le score combiné se situe dans les 70 — les bases sont acquises, mais un écart entre l'écrit et la performance suggère un rééquilibrage nécessaire. ", "Le résultat combiné écrit et performance se situe dans la moyenne ; identifier et renforcer des points faibles précis pourrait apporter une hausse significative à court terme. "],
      'DE': ['Der kombinierte Wert liegt im 70er-Bereich — die Grundlagen sind vorhanden, aber eine Diskrepanz zwischen schriftlicher und Leistungsnote deutet auf Nachjustierungsbedarf hin. ', 'Das kombinierte Ergebnis liegt im Mittelfeld; das gezielte Erkennen und Stärken schwacher Bereiche könnte kurzfristig zu einer spürbaren Verbesserung führen. '],
      'RU': ['Совокупный балл находится в диапазоне 70-х — базовые навыки присутствуют, но разница между письменной и практической частью указывает на необходимость выравнивания баланса. ', 'Итоговый результат находится на среднем уровне; выявление и укрепление конкретных слабых мест может дать заметный рост в короткие сроки. '],
      'AR': ['تقع الدرجة المجمعة في نطاق السبعينيات — الأساسيات موجودة، لكن الفجوة بين التحريري والأداء تشير إلى ضرورة إعادة التوازن. ', 'تقع النتيجة المجمعة للتحريري والأداء في المستوى المتوسط؛ تحديد نقاط الضعف المحددة وتعزيزها قد يحقق ارتفاعًا ملموسًا في وقت قصير. '],
      'HI': ['संयुक्त स्कोर 70 के दशक में है — बुनियादी बातें मौजूद हैं, लेकिन लिखित और प्रदर्शन के बीच अंतर संतुलन की आवश्यकता दर्शाता है। ', 'लिखित और प्रदर्शन का संयुक्त परिणाम मध्य स्तर पर है; विशिष्ट कमजोर क्षेत्रों की पहचान कर उन्हें मजबूत करने से जल्द ही सार्थक सुधार संभव है। '],
      'VI': ['Điểm tổng hợp nằm trong khoảng 70 — nền tảng cơ bản đã có, nhưng khoảng cách giữa điểm viết và điểm thực hành cho thấy cần cân bằng lại. ', 'Kết quả tổng hợp giữa viết và thực hành ở mức trung bình; việc xác định và củng cố những điểm yếu cụ thể có thể mang lại sự cải thiện đáng kể trong thời gian ngắn. '],
      'ES': ['La puntuación combinada se sitúa en los 70 — las bases están presentes, pero una brecha entre lo escrito y el desempeño sugiere que se necesita reequilibrar. ', 'El resultado combinado de escrito y desempeño está en el nivel medio; identificar y reforzar puntos débiles específicos podría traer una mejora significativa a corto plazo. '],
      'TH': ['คะแนนรวมอยู่ในช่วง 70 — พื้นฐานมีอยู่แล้ว แต่ช่องว่างระหว่างข้อเขียนและภาคปฏิบัติบ่งชี้ว่าต้องปรับสมดุลใหม่ ', 'ผลรวมของข้อเขียนและภาคปฏิบัติอยู่ในระดับกลาง การระบุและเสริมจุดอ่อนที่เฉพาะเจาะจงอาจนำมาซึ่งการพัฒนาที่ชัดเจนในระยะเวลาอันสั้น '],
    },
    'low': {
      'KO': ['종합 반영점수가 60점대로, 기초 개념 정착 단계에서 다소 아쉬운 결과가 확인되어 보완이 필요한 시점입니다. ', '지필과 수행 점수를 함께 살펴본 결과, 현재 수준에 비해 성취가 낮게 나타나고 있어 학습 습관 전반의 점검이 요구됩니다. '],
      'EN': ['The combined score sits in the 60s, pointing to some gaps in foundational concepts that need attention at this stage. ', 'Looking at both written and performance scores together, achievement is running lower than expected for the current level, calling for a review of overall study habits. '],
      'JA': ['総合反映点数が60点台であり、基礎概念の定着段階でやや惜しい結果が確認され、補強が必要な時期です。 ', '筆記と遂行の点数を合わせて見ると、現在のレベルに比べて成果がやや低く、学習習慣全般の点検が求められます。 '],
      'ZH': ['综合反映分数在60分段，说明在基础概念巩固阶段出现了略显遗憾的结果，需要加以补强。 ', '综合来看笔试与表现分数，成绩低于当前水平应有的表现，需要全面检视学习习惯。 '],
      'FR': ["Le score combiné se situe dans les 60, révélant certaines lacunes dans les concepts fondamentaux qui méritent attention à ce stade. ", "En considérant à la fois l'écrit et la performance, la réussite est en dessous du niveau attendu, ce qui appelle une révision globale des habitudes d'étude. "],
      'DE': ['Der kombinierte Wert liegt im 60er-Bereich, was auf Lücken in den Grundkonzepten hinweist, die in dieser Phase Aufmerksamkeit brauchen. ', 'Betrachtet man schriftliche und Leistungsnote zusammen, liegt die Leistung unter dem erwarteten Niveau, was eine Überprüfung der gesamten Lerngewohnheiten nahelegt. '],
      'RU': ['Совокупный балл находится в диапазоне 60-х, что указывает на пробелы в базовых понятиях, требующие внимания на этом этапе. ', 'Если рассматривать письменную и практическую оценки вместе, успеваемость ниже ожидаемого уровня, что требует пересмотра общих учебных привычек. '],
      'AR': ['تقع الدرجة المجمعة في نطاق الستينيات، مما يشير إلى بعض الثغرات في المفاهيم الأساسية التي تحتاج إلى اهتمام في هذه المرحلة. ', 'بالنظر إلى درجتي التحريري والأداء معًا، يبدو التحصيل أقل من المتوقع لهذا المستوى، مما يستدعي مراجعة عادات الدراسة العامة. '],
      'HI': ['संयुक्त स्कोर 60 के दशक में है, जो इस चरण में ध्यान देने योग्य कुछ बुनियादी अवधारणा अंतराल की ओर इशारा करता है। ', 'लिखित और प्रदर्शन दोनों अंकों को साथ देखने पर, वर्तमान स्तर के अनुसार अपेक्षा से कम उपलब्धि दिख रही है, जिससे समग्र अध्ययन आदतों की समीक्षा आवश्यक है। '],
      'VI': ['Điểm tổng hợp nằm trong khoảng 60, cho thấy một số khoảng trống trong khái niệm nền tảng cần được chú ý ở giai đoạn này. ', 'Nhìn vào cả điểm viết và điểm thực hành, thành tích đang thấp hơn mức kỳ vọng, đòi hỏi phải xem xét lại toàn bộ thói quen học tập. '],
      'ES': ['La puntuación combinada se sitúa en los 60, señalando algunas brechas en los conceptos fundamentales que requieren atención en esta etapa. ', 'Al observar juntas las notas escritas y de desempeño, el logro está por debajo de lo esperado para el nivel actual, lo que exige revisar los hábitos de estudio en general. '],
      'TH': ['คะแนนรวมอยู่ในช่วง 60 บ่งชี้ถึงช่องว่างบางประการในแนวคิดพื้นฐานที่ต้องให้ความสนใจในขั้นนี้ ', 'เมื่อพิจารณาคะแนนข้อเขียนและภาคปฏิบัติร่วมกัน ผลสัมฤทธิ์ต่ำกว่าที่คาดไว้สำหรับระดับปัจจุบัน จำเป็นต้องทบทวนพฤติกรรมการเรียนโดยรวม '],
    },
    'critical': {
      'KO': ['종합 반영점수가 60점 미만으로, 기초 개념 정착부터 다시 다져야 하는 상황임을 알려주는 결과입니다. ', '지필·수행 합산 결과가 낮게 나타나고 있어, 조급하게 문제풀이량만 늘리기보다 기본 개념부터 차근히 재정비하는 과정이 필요합니다. '],
      'EN': ['The combined score is below 60, signaling that foundational concepts need to be rebuilt from the ground up. ', 'The combined written and performance result is low, so rather than rushing into more practice volume, it is time to methodically rebuild the fundamentals. '],
      'JA': ['総合反映点数が60点未満であり、基礎概念の定着からやり直す必要がある状況を示す結果です。 ', '筆記・遂行の合算結果が低く、焦って問題演習量だけを増やすより基礎概念から着実に立て直す過程が必要です。 '],
      'ZH': ['综合反映分数低于60分，说明需要从基础概念开始重新夯实。 ', '笔试与表现的合计结果偏低，与其急于增加刷题量，不如从基础概念开始稳步重整。 '],
      'FR': ["Le score combiné est inférieur à 60, signalant que les concepts fondamentaux doivent être reconstruits depuis la base. ", "Le résultat combiné écrit et performance étant faible, plutôt que de se précipiter sur davantage d'exercices, il est temps de reconstruire méthodiquement les bases. "],
      'DE': ['Der kombinierte Wert liegt unter 60, was signalisiert, dass die Grundkonzepte von Grund auf neu aufgebaut werden müssen. ', 'Da das kombinierte Ergebnis niedrig ist, sollte man statt hastig mehr Übungsaufgaben zu machen die Grundlagen methodisch neu aufbauen. '],
      'RU': ['Совокупный балл ниже 60, что сигнализирует о необходимости заново выстроить базовые понятия с нуля. ', 'Поскольку итоговый результат низкий, вместо поспешного увеличения количества практики стоит методично восстановить основы. '],
      'AR': ['الدرجة المجمعة أقل من 60، مما يشير إلى ضرورة إعادة بناء المفاهيم الأساسية من الصفر. ', 'بما أن النتيجة المجمعة منخفضة، فبدلاً من التسرع في زيادة حجم التدريب، حان وقت إعادة بناء الأساسيات بشكل منهجي. '],
      'HI': ['संयुक्त स्कोर 60 से कम है, जो दर्शाता है कि बुनियादी अवधारणाओं को शुरू से फिर से मजबूत करने की आवश्यकता है। ', 'लिखित और प्रदर्शन का संयुक्त परिणाम कम है, इसलिए जल्दबाजी में अभ्यास की मात्रा बढ़ाने के बजाय, बुनियादी बातों को व्यवस्थित रूप से फिर से बनाने का समय है। '],
      'VI': ['Điểm tổng hợp dưới 60, cho thấy cần xây dựng lại các khái niệm nền tảng từ đầu. ', 'Kết quả tổng hợp giữa viết và thực hành thấp, vì vậy thay vì vội vàng tăng khối lượng luyện tập, đây là lúc cần xây dựng lại nền tảng một cách có hệ thống. '],
      'ES': ['La puntuación combinada está por debajo de 60, lo que indica que los conceptos fundamentales deben reconstruirse desde cero. ', 'Como el resultado combinado de escrito y desempeño es bajo, en lugar de aumentar apresuradamente el volumen de práctica, es momento de reconstruir metódicamente los fundamentos. '],
      'TH': ['คะแนนรวมต่ำกว่า 60 บ่งชี้ว่าต้องปูพื้นฐานแนวคิดใหม่ตั้งแต่ต้น ', 'ผลรวมของข้อเขียนและภาคปฏิบัติต่ำ ดังนั้นแทนที่จะเร่งเพิ่มปริมาณการฝึกฝน ควรใช้เวลาปรับฐานรากอย่างเป็นระบบ '],
    },
  };

  static const Map<String, Map<String, List<String>>> _middles = {
    'excellent': {
      'KO': [' 특히 시험 종류(중간고사·기말고사·모의고사)별로 편차 없이 고르게 좋은 흐름을 보이는 점이 인상적입니다.', ' 지필과 수행 두 영역의 반영비율이 달라져도 흔들리지 않을 만큼 기초가 탄탄하게 잡혀 있는 상태입니다.'],
      'EN': [' Notably, performance stays consistently strong across exam types (midterm, final, mock), which is impressive.', ' The foundation is solid enough that changes to the written/performance weighting would not shake the results.'],
      'JA': [' 特に試験種類（中間・期末・模試）別に偏差なく良い流れを見せている点が印象的です。', ' 筆記と遂行の反映比率が変わっても揺るがないほど基礎が堅固に固まっている状態です。'],
      'ZH': [' 特别是在各类考试（期中、期末、模拟）中都表现出均衡良好的趋势，令人印象深刻。', ' 即使笔试与表现的反映比例发生变化，基础也足够牢固，不易受影响。'],
      'FR': [" Notamment, les résultats restent constants et solides selon les types d'examen (mi-parcours, final, blanc), ce qui est impressionnant.", " Les bases sont assez solides pour ne pas être affectées même si la pondération écrit/performance change."],
      'DE': [' Bemerkenswert ist die durchgehend starke Leistung über alle Prüfungsarten (Zwischen-, Abschluss-, Testprüfung) hinweg.', ' Die Grundlage ist solide genug, dass Änderungen der Gewichtung von schriftlicher und Leistungsnote die Ergebnisse nicht erschüttern würden.'],
      'RU': [' Особенно впечатляет стабильно высокий результат по всем типам экзаменов (промежуточный, итоговый, пробный).', ' База достаточно прочная, чтобы изменение соотношения весов письменной и практической частей не повлияло на результат.'],
      'AR': [' من اللافت أن الأداء يظل قويًا باستمرار عبر جميع أنواع الاختبارات (نصفي، نهائي، تجريبي).', ' الأساس متين بما يكفي بحيث لا تتأثر النتائج حتى مع تغيير أوزان التحريري والأداء.'],
      'HI': [' विशेष रूप से, सभी परीक्षा प्रकारों (मिडटर्म, फाइनल, मॉक) में प्रदर्शन लगातार मजबूत बना हुआ है, जो प्रभावशाली है।', ' आधार इतना मजबूत है कि लिखित/प्रदर्शन भारांक बदलने पर भी परिणाम प्रभावित नहीं होंगे।'],
      'VI': [' Đáng chú ý, thành tích duy trì mạnh mẽ đồng đều ở mọi loại kỳ thi (giữa kỳ, cuối kỳ, thi thử), điều này rất ấn tượng.', ' Nền tảng đủ vững chắc để không bị lung lay dù tỷ trọng viết/thực hành có thay đổi.'],
      'ES': [' Cabe destacar que el rendimiento se mantiene sólido de forma constante en todos los tipos de examen (parcial, final, simulado), lo cual es impresionante.', ' La base es lo bastante sólida como para no verse afectada aunque cambie la ponderación entre escrito y desempeño.'],
      'TH': [' ที่น่าประทับใจคือผลการเรียนยังคงแข็งแกร่งสม่ำเสมอในทุกประเภทข้อสอบ (กลางภาค ปลายภาค ข้อสอบจำลอง)', ' พื้นฐานแข็งแรงพอที่จะไม่สั่นคลอนแม้สัดส่วนคะแนนข้อเขียน/ภาคปฏิบัติจะเปลี่ยนไป'],
    },
    'good': {
      'KO': [' 시험 종류별로 살펴보면 특정 유형에서 다소 아쉬운 부분이 보이므로, 해당 부분을 짚어보면 좋겠습니다.', ' 지필과 수행 중 상대적으로 낮은 쪽을 확인해 보완하면 더 안정적인 흐름을 만들 수 있습니다.'],
      'EN': [' Looking at scores by exam type, one particular type shows a bit of a dip worth addressing.', ' Identifying whichever of written or performance is relatively weaker and reinforcing it would make results more consistent.'],
      'JA': [' 試験種類別に見ると特定の類型でやや惜しい部分が見られるため、その部分を確認すると良いでしょう。', ' 筆記と遂行のうち相対的に低い方を確認して補強すれば、より安定した流れを作れます。'],
      'ZH': [' 按考试类型来看，某一类型稍显不足，值得关注和改善。', ' 找出笔试与表现中相对薄弱的一方加以补强，可形成更稳定的趋势。'],
      'FR': [" En examinant les scores par type d'examen, un type en particulier montre une légère baisse à corriger.", " Identifier lequel de l'écrit ou de la performance est relativement plus faible et le renforcer rendrait les résultats plus constants."],
      'DE': [' Betrachtet man die Ergebnisse nach Prüfungsart, zeigt ein bestimmter Typ einen leichten Einbruch, der Beachtung verdient.', ' Das relativ schwächere der beiden Bereiche (schriftlich oder Leistung) zu identifizieren und zu stärken würde die Ergebnisse konsistenter machen.'],
      'RU': [' При рассмотрении баллов по типам экзаменов один из них показывает небольшой спад, на который стоит обратить внимание.', ' Определение более слабой стороны (письменной или практической) и её укрепление сделает результаты более стабильными.'],
      'AR': [' عند النظر إلى الدرجات حسب نوع الاختبار، يظهر نوع معين تراجعًا طفيفًا يستحق المعالجة.', ' تحديد الجانب الأضعف نسبيًا (التحريري أو الأداء) وتعزيزه سيجعل النتائج أكثر اتساقًا.'],
      'HI': [' परीक्षा प्रकार अनुसार देखने पर एक विशेष प्रकार में थोड़ी कमी दिखती है, जिस पर ध्यान देना उचित होगा।', ' लिखित या प्रदर्शन में से जो अपेक्षाकृत कमजोर है उसे पहचानकर मजबूत करने से परिणाम अधिक स्थिर होंगे।'],
      'VI': [' Nhìn theo từng loại kỳ thi, có một loại cho thấy hơi sụt giảm cần lưu ý.', ' Xác định điểm viết hay thực hành đang yếu hơn tương đối và củng cố nó sẽ giúp kết quả ổn định hơn.'],
      'ES': [' Al observar las puntuaciones por tipo de examen, un tipo en particular muestra una ligera caída que merece atención.', ' Identificar cuál de los dos (escrito o desempeño) es relativamente más débil y reforzarlo haría los resultados más consistentes.'],
      'TH': [' เมื่อดูคะแนนแยกตามประเภทข้อสอบ มีประเภทหนึ่งที่ลดลงเล็กน้อยซึ่งควรให้ความสนใจ', ' การระบุว่าข้อเขียนหรือภาคปฏิบัติส่วนใดอ่อนกว่ากันแล้วเสริมส่วนนั้น จะทำให้ผลลัพธ์สม่ำเสมอขึ้น'],
    },
    'mid': {
      'KO': [' 특히 수행평가 준비 과정에서의 꾸준함이 전체 반영점수에 큰 영향을 주는 구간이므로 유의가 필요합니다.', ' 시험 종류별 점수를 비교해 보면 유독 약한 영역이 눈에 띄므로, 그 부분부터 우선 점검해 보시길 권합니다.'],
      'EN': [' Consistency in performance-evaluation preparation in particular has a big impact on the combined score, so it is worth watching closely.', ' Comparing scores by exam type reveals one clearly weaker area — starting there is recommended.'],
      'JA': [' 特に遂行評価準備過程での継続性が全体反映点数に大きく影響する区間なので注意が必要です。', ' 試験種類別の点数を比較すると特に弱い領域が見られるため、その部分から優先的に点検することをお勧めします。'],
      'ZH': [' 尤其是表现评价准备过程中的持续性对整体反映分数影响较大，需要留意。', ' 比较各类考试分数会发现明显薄弱的领域，建议优先从该处入手检视。'],
      'FR': [" La régularité dans la préparation des évaluations de performance a un impact particulièrement important sur le score combiné, à surveiller de près.", " La comparaison des scores par type d'examen révèle un domaine clairement plus faible — il est recommandé de commencer par là."],
      'DE': [' Besonders die Beständigkeit bei der Vorbereitung auf Leistungsbewertungen hat großen Einfluss auf den Gesamtwert, daher lohnt sich genaues Beobachten.', ' Der Vergleich der Ergebnisse nach Prüfungsart zeigt einen deutlich schwächeren Bereich — dort sollte man ansetzen.'],
      'RU': [' Особенно сильно на итоговый балл влияет постоянство в подготовке к практическим оценкам, поэтому стоит внимательно за этим следить.', ' Сравнение баллов по типам экзаменов выявляет явно более слабую область — рекомендуется начать именно с неё.'],
      'AR': [' يؤثر الانتظام في التحضير لتقييمات الأداء بشكل خاص وكبير على الدرجة المجمعة، لذا يستحق المتابعة الدقيقة.', ' مقارنة الدرجات حسب نوع الاختبار تكشف عن مجال أضعف بوضوح — يُنصح بالبدء منه.'],
      'HI': [' विशेष रूप से प्रदर्शन-मूल्यांकन तैयारी में निरंतरता का संयुक्त स्कोर पर बड़ा प्रभाव पड़ता है, इसलिए इस पर बारीकी से ध्यान देना चाहिए।', ' परीक्षा प्रकार अनुसार अंकों की तुलना करने पर एक स्पष्ट रूप से कमजोर क्षेत्र सामने आता है — वहीं से शुरुआत करने की सलाह दी जाती है।'],
      'VI': [' Đặc biệt, sự đều đặn trong chuẩn bị đánh giá thực hành có ảnh hưởng lớn đến điểm tổng hợp, nên cần theo dõi sát sao.', ' So sánh điểm theo từng loại kỳ thi cho thấy một khu vực rõ ràng yếu hơn — nên bắt đầu từ đó trước.'],
      'ES': [' En particular, la constancia en la preparación de las evaluaciones de desempeño tiene un gran impacto en la puntuación combinada, por lo que conviene vigilarla de cerca.', ' Comparar las puntuaciones por tipo de examen revela un área claramente más débil — se recomienda empezar por ahí.'],
      'TH': [' โดยเฉพาะความสม่ำเสมอในการเตรียมตัวสำหรับการประเมินภาคปฏิบัติมีผลอย่างมากต่อคะแนนรวม จึงควรจับตาดูอย่างใกล้ชิด', ' การเปรียบเทียบคะแนนตามประเภทข้อสอบพบว่ามีจุดที่อ่อนแอชัดเจน แนะนำให้เริ่มจากจุดนั้นก่อน'],
    },
    'low': {
      'KO': [' 지필과 수행 어느 한쪽에 치우치지 않고 두 영역을 골고루 챙기는 습관부터 다시 잡아가는 것이 중요합니다.', ' 시험 종류에 따라 편차가 크게 나타나고 있어, 부족한 유형을 구체적으로 짚어주는 지도가 도움이 될 것입니다.'],
      'EN': [' Building the habit of giving equal attention to both written and performance components, rather than favoring one, matters here.', ' Scores vary noticeably by exam type, so pinpointing the weaker areas and guiding practice there would help.'],
      'JA': [' 筆記と遂行のどちらか一方に偏らず、両領域を均等に整える習慣から立て直すことが重要です。', ' 試験種類による偏差が大きく現れているため、不足している類型を具体的に指摘する指導が助けになります。'],
      'ZH': [' 重要的是重新养成兼顾笔试与表现两方面、不偏废任何一方的习惯。', ' 各类考试之间的差异较大，针对薄弱类型给予具体指导将有所帮助。'],
      'FR': [" Reconstruire l'habitude d'accorder une attention égale à l'écrit et à la performance, sans favoriser l'un ou l'autre, est essentiel ici.", " Les scores varient sensiblement selon le type d'examen, donc cibler précisément les points faibles et guider la pratique serait utile."],
      'DE': [' Wichtig ist, die Gewohnheit wieder aufzubauen, beiden Bereichen – schriftlich und Leistung – gleich viel Aufmerksamkeit zu schenken.', ' Die Ergebnisse schwanken deutlich je nach Prüfungsart; eine gezielte Anleitung zu den schwächeren Typen wäre hilfreich.'],
      'RU': [' Важно вновь выработать привычку уделять равное внимание письменной и практической частям, не отдавая предпочтение одной из них.', ' Баллы заметно различаются в зависимости от типа экзамена, поэтому точное определение слабых сторон и целевая подготовка помогут.'],
      'AR': [' من المهم إعادة بناء عادة الاهتمام المتساوي بالتحريري والأداء دون تفضيل أحدهما.', ' تتفاوت الدرجات بشكل ملحوظ حسب نوع الاختبار، لذا فإن تحديد المجالات الأضعف بدقة وتوجيه التدريب إليها سيكون مفيدًا.'],
      'HI': [' लिखित और प्रदर्शन में से किसी एक को प्राथमिकता दिए बिना दोनों पर समान ध्यान देने की आदत फिर से बनाना महत्वपूर्ण है।', ' परीक्षा प्रकार के अनुसार अंकों में उल्लेखनीय अंतर है, इसलिए कमजोर क्षेत्रों की सटीक पहचान कर वहीं मार्गदर्शन देना सहायक होगा।'],
      'VI': [' Quan trọng là xây dựng lại thói quen chú ý đồng đều đến cả điểm viết và thực hành, không thiên vị bên nào.', ' Điểm số dao động rõ rệt theo từng loại kỳ thi, vì vậy việc xác định chính xác điểm yếu và hướng dẫn luyện tập ở đó sẽ hữu ích.'],
      'ES': [' Es importante recuperar el hábito de prestar atención equilibrada tanto a lo escrito como al desempeño, sin favorecer uno sobre otro.', ' Las puntuaciones varían notablemente según el tipo de examen, por lo que identificar con precisión las áreas más débiles y orientar la práctica ahí ayudaría.'],
      'TH': [' สิ่งสำคัญคือต้องสร้างนิสัยใหม่ในการดูแลทั้งข้อเขียนและภาคปฏิบัติอย่างเท่าเทียม ไม่เอนเอียงไปทางใดทางหนึ่ง', ' คะแนนแตกต่างกันอย่างเห็นได้ชัดตามประเภทข้อสอบ การชี้จุดอ่อนที่ชัดเจนและแนะแนวการฝึกฝนตรงจุดจะช่วยได้มาก'],
    },
    'critical': {
      'KO': [' 지필과 수행 모두에서 보완이 필요한 상태이므로, 하나씩 순서를 정해 차근히 접근하는 것이 효과적입니다.', ' 당장의 점수보다 학습 습관 자체를 다시 세우는 과정이 우선되어야 하는 시점으로 보입니다.'],
      'EN': [' Both written and performance areas need reinforcement, so tackling them one at a time in order will be more effective.', ' Rather than focusing on scores right now, the priority should be rebuilding study habits from the ground up.'],
      'JA': [' 筆記と遂行の両方で補強が必要な状態なので、順序を決めて一つずつ着実に取り組むことが効果的です。', ' 目先の点数よりも学習習慣そのものを立て直す過程が優先されるべき時期と見られます。'],
      'ZH': [' 笔试与表现两方面都需要补强，因此按顺序逐一稳步推进会更有效。', ' 与其纠结于眼前的分数，现阶段更应优先重新建立学习习惯本身。'],
      'FR': [" Les domaines écrit et performance nécessitent tous deux d'être renforcés, donc les aborder un par un, dans l'ordre, sera plus efficace.", " Plutôt que de se concentrer sur les notes pour l'instant, la priorité devrait être de reconstruire les habitudes d'étude depuis la base."],
      'DE': [' Beide Bereiche – schriftlich und Leistung – müssen gestärkt werden, daher ist es effektiver, sie der Reihe nach anzugehen.', ' Statt sich jetzt auf die Noten zu konzentrieren, sollte der Fokus auf dem grundlegenden Wiederaufbau der Lerngewohnheiten liegen.'],
      'RU': [' Требуется усиление и по письменной, и по практической части, поэтому эффективнее заниматься ими по очереди.', ' Сейчас важнее не сосредотачиваться на баллах, а в первую очередь заново выстроить учебные привычки с нуля.'],
      'AR': [' يحتاج كل من الجانب التحريري والأداء إلى تعزيز، لذا فإن معالجتهما واحدًا تلو الآخر بترتيب سيكون أكثر فعالية.', ' بدلاً من التركيز على الدرجات الآن، ينبغي أن تكون الأولوية لإعادة بناء عادات الدراسة من الصفر.'],
      'HI': [' लिखित और प्रदर्शन दोनों क्षेत्रों में सुदृढ़ीकरण की आवश्यकता है, इसलिए क्रम तय कर एक-एक करके आगे बढ़ना अधिक प्रभावी होगा।', ' अभी अंकों पर ध्यान देने के बजाय, अध्ययन आदतों को नए सिरे से बनाने को प्राथमिकता देनी चाहिए।'],
      'VI': [' Cả điểm viết và thực hành đều cần được củng cố, vì vậy giải quyết lần lượt theo thứ tự sẽ hiệu quả hơn.', ' Thay vì tập trung vào điểm số lúc này, ưu tiên nên là xây dựng lại thói quen học tập từ đầu.'],
      'ES': [' Tanto el área escrita como la de desempeño necesitan refuerzo, por lo que abordarlas una por una, en orden, será más eficaz.', ' En lugar de centrarse en las notas ahora mismo, la prioridad debería ser reconstruir los hábitos de estudio desde cero.'],
      'TH': [' ทั้งข้อเขียนและภาคปฏิบัติต้องการการเสริมความแข็งแกร่ง การจัดลำดับและแก้ไขทีละจุดจะมีประสิทธิภาพมากกว่า', ' แทนที่จะจดจ่อกับคะแนนตอนนี้ ควรให้ความสำคัญกับการสร้างพฤติกรรมการเรียนใหม่ตั้งแต่ต้นก่อน'],
    },
  };

  static const Map<String, Map<String, List<String>>> _closings = {
    'excellent': {
      'KO': ['다만 현재 수준에 안주하지 않고, 오답 원인을 기록·분석하는 오답노트(틀린 이유를 되짚어 정리하는 습관)를 꾸준히 유지하면 흔들림 없는 최상위권을 지켜낼 수 있습니다.', '이 흐름을 유지하려면 수행평가 준비도 지필 못지않게 꼼꼼히 챙기는 균형 잡힌 습관을 계속 이어가시길 권합니다.'],
      'EN': ['That said, keeping an error journal (recording and reviewing the reasons behind mistakes) will help protect this top-tier standing without complacency.', 'To keep this trend going, continue preparing for performance evaluations as carefully as for written exams, maintaining a well-balanced routine.'],
      'JA': ['ただし現在の水準に安住せず、誤答ノート（間違えた理由を振り返って整理する習慣）を継続すれば揺るがない最上位圏を維持できます。', 'この流れを維持するには遂行評価の準備も筆記に劣らず丁寧に行うバランスの取れた習慣を続けることをお勧めします。'],
      'ZH': ['不过不应满足于现有水平，坚持记录并分析错题原因（错题笔记，即回顾整理错误原因的习惯）才能稳固最高水平。', '若想保持这一趋势，建议持续保持对表现评价的重视程度不亚于笔试的均衡习惯。'],
      'FR': ["Cela dit, tenir un journal des erreurs (noter et revoir les raisons des erreurs) aidera à préserver ce rang de tête sans complaisance.", "Pour maintenir cette tendance, continuez à préparer les évaluations de performance avec autant de soin que les examens écrits, en gardant une routine équilibrée."],
      'DE': ['Dennoch hilft ein Fehlerprotokoll (das Festhalten und Überprüfen der Gründe für Fehler), diesen Spitzenplatz ohne Selbstzufriedenheit zu sichern.', 'Um diesen Trend fortzusetzen, sollten Leistungsbewertungen ebenso sorgfältig vorbereitet werden wie schriftliche Prüfungen, in einer ausgewogenen Routine.'],
      'RU': ['Тем не менее, ведение журнала ошибок (запись и разбор причин ошибок) поможет удержать этот высокий уровень без самоуспокоенности.', 'Чтобы сохранить эту тенденцию, продолжайте готовиться к практическим оценкам так же тщательно, как к письменным экзаменам, придерживаясь сбалансированного режима.'],
      'AR': ['ومع ذلك، فإن الاحتفاظ بدفتر أخطاء (تسجيل ومراجعة أسباب الأخطاء) سيساعد في الحفاظ على هذا المستوى المتقدم دون رضا زائد عن النفس.', 'للحفاظ على هذا الاتجاه، استمر في التحضير لتقييمات الأداء بعناية مماثلة للتحضير للاختبارات التحريرية، مع الحفاظ على روتين متوازن.'],
      'HI': ['फिर भी, त्रुटि डायरी (गलतियों के कारणों को दर्ज कर समीक्षा करना) बनाए रखने से यह शीर्ष स्थिति बिना आत्मसंतोष के सुरक्षित रहेगी।', 'इस प्रवृत्ति को बनाए रखने के लिए, लिखित परीक्षाओं जितनी ही सावधानी से प्रदर्शन मूल्यांकन की तैयारी जारी रखें और संतुलित दिनचर्या बनाए रखें।'],
      'VI': ['Tuy nhiên, việc duy trì nhật ký lỗi sai (ghi lại và xem lại nguyên nhân sai sót) sẽ giúp giữ vững vị trí hàng đầu này mà không tự mãn.', 'Để duy trì xu hướng này, hãy tiếp tục chuẩn bị cho đánh giá thực hành cẩn thận không kém gì thi viết, giữ thói quen cân bằng.'],
      'ES': ['Aun así, mantener un diario de errores (registrar y repasar las razones de los fallos) ayudará a proteger esta posición de primer nivel sin caer en la autocomplacencia.', 'Para mantener esta tendencia, siga preparando las evaluaciones de desempeño con el mismo cuidado que los exámenes escritos, manteniendo una rutina equilibrada.'],
      'TH': ['อย่างไรก็ตาม การจดบันทึกข้อผิดพลาด (บันทึกและทบทวนสาเหตุของความผิดพลาด) จะช่วยรักษาตำแหน่งระดับสูงสุดนี้ไว้ได้โดยไม่ประมาท', 'เพื่อรักษาแนวโน้มนี้ไว้ ควรเตรียมตัวสำหรับการประเมินภาคปฏิบัติอย่างพิถีพิถันไม่แพ้ข้อเขียน โดยรักษาความสมดุลไว้อย่างต่อเนื่อง'],
    },
    'good': {
      'KO': ['수행평가에서 놓치는 소소한 감점 요인들을 점검하고, 지필에서는 고난도 응용 문제 위주로 보완하면 상승 여지가 충분합니다.', '메타인지(자신이 무엇을 알고 무엇을 모르는지 스스로 점검하는 능력)를 활용해 취약 단원을 구체적으로 짚어보는 습관을 들이면 좋겠습니다.'],
      'EN': ['Checking for small point losses in performance evaluations, and reinforcing advanced application problems on the written side, should open up further room to improve.', 'Using metacognition (checking what you do and do not understand) to pinpoint weak units would be a good habit to build.'],
      'JA': ['遂行評価で見逃す小さな減点要因を点検し、筆記では高難度応用問題を中心に補強すれば上昇の余地は十分にあります。', 'メタ認知（自分が何を知っていて何を知らないかを自ら点検する能力）を活用して弱点単元を具体的に把握する習慣を身につけると良いでしょう。'],
      'ZH': ['检查表现评价中容易忽略的小失分因素，并在笔试中着重补强高难度应用题，仍有充分的提升空间。', '建议利用元认知（自我检查知与不知的能力）来具体找出薄弱单元的习惯。'],
      'FR': ["Vérifier les petites pertes de points dans les évaluations de performance, et renforcer les problèmes d'application avancés à l'écrit, devrait ouvrir davantage de marge de progression.", "Utiliser la métacognition (vérifier ce que l'on sait et ne sait pas) pour cibler précisément les unités faibles serait une bonne habitude à développer."],
      'DE': ['Kleine Punktverluste bei Leistungsbewertungen zu prüfen und anspruchsvolle Anwendungsaufgaben im schriftlichen Bereich zu stärken, sollte weiteren Verbesserungsspielraum eröffnen.', 'Metakognition zu nutzen (zu prüfen, was man weiß und nicht weiß), um schwache Einheiten gezielt zu erkennen, wäre eine gute Gewohnheit.'],
      'RU': ['Проверка небольших потерь баллов в практических оценках и усиление сложных прикладных задач в письменной части должны открыть дополнительные возможности для роста.', 'Использование метапознания (проверка того, что вы знаете и чего не знаете) для точного выявления слабых разделов было бы полезной привычкой.'],
      'AR': ['التحقق من خسائر النقاط الصغيرة في تقييمات الأداء، وتعزيز مسائل التطبيق المتقدمة في الجانب التحريري، سيفتح مجالًا أكبر للتحسن.', 'استخدام الإدراك الفوقي (معرفة ما تفهمه وما لا تفهمه) لتحديد الوحدات الضعيفة بدقة سيكون عادة جيدة.'],
      'HI': ['प्रदर्शन मूल्यांकन में छूटे छोटे अंक-हानि कारणों की जांच करना और लिखित में उच्च-कठिनाई अनुप्रयोग प्रश्नों को मजबूत करना, सुधार की पर्याप्त गुंजाइश खोलेगा।', 'मेटाकॉग्निशन (आप क्या जानते और क्या नहीं जानते इसकी स्वयं जांच करने की क्षमता) का उपयोग कर कमजोर इकाइयों को सटीक रूप से पहचानना अच्छी आदत होगी।'],
      'VI': ['Kiểm tra những điểm mất nhỏ trong đánh giá thực hành, và củng cố các bài toán ứng dụng nâng cao ở phần viết, sẽ mở ra nhiều khả năng cải thiện hơn.', 'Sử dụng nhận thức về nhận thức (tự kiểm tra những gì mình biết và không biết) để xác định chính xác các chương yếu sẽ là thói quen tốt cần xây dựng.'],
      'ES': ['Revisar las pequeñas pérdidas de puntos en las evaluaciones de desempeño, y reforzar los problemas de aplicación avanzados en lo escrito, debería abrir más margen de mejora.', 'Usar la metacognición (comprobar qué se sabe y qué no) para identificar con precisión las unidades débiles sería un buen hábito a desarrollar.'],
      'TH': ['ตรวจสอบจุดที่เสียคะแนนเล็กน้อยในการประเมินภาคปฏิบัติ และเสริมโจทย์ประยุกต์ระดับสูงในข้อเขียน จะเปิดโอกาสให้พัฒนาต่อได้อีก', 'การใช้เมทาค็อกนิชัน (ความสามารถในการตรวจสอบว่าตนเองรู้หรือไม่รู้อะไร) เพื่อชี้จุดอ่อนของแต่ละหน่วยอย่างชัดเจนจะเป็นนิสัยที่ดี'],
    },
    'mid': {
      'KO': ['지필과 수행 중 상대적으로 약한 영역을 먼저 파악한 뒤, 그 영역에 학습 시간을 집중 배분하는 전략이 효과적일 것으로 보입니다.', '기본 개념을 다시 짚어보는 복습 루틴을 꾸준히 유지한다면, 다음 시험에서 의미 있는 반등을 기대할 수 있습니다.'],
      'EN': ['Identifying whichever of written or performance is relatively weaker and concentrating study time there would be an effective strategy.', 'Keeping up a steady review routine covering core concepts should lead to a meaningful rebound on the next assessment.'],
      'JA': ['筆記と遂行のうち相対的に弱い領域を先に把握した後、その領域に学習時間を集中配分する戦略が効果的と見られます。', '基本概念を再確認する復習ルーティンを継続すれば、次回の試験で意味のある反騰が期待できます。'],
      'ZH': ['先明确笔试与表现中相对薄弱的领域，再将学习时间集中分配到该领域，这一策略较为有效。', '若能坚持重新梳理基本概念的复习节奏，下次考试有望出现明显反弹。'],
      'FR': ["Identifier lequel de l'écrit ou de la performance est relativement plus faible, puis y concentrer le temps d'étude, serait une stratégie efficace.", "Maintenir une routine de révision constante couvrant les concepts fondamentaux devrait mener à un rebond significatif au prochain examen."],
      'DE': ['Den relativ schwächeren Bereich (schriftlich oder Leistung) zu identifizieren und die Lernzeit dort zu konzentrieren, wäre eine wirksame Strategie.', 'Eine konsequente Wiederholungsroutine der Grundkonzepte sollte bei der nächsten Bewertung zu einer spürbaren Erholung führen.'],
      'RU': ['Определение относительно более слабой стороны (письменной или практической) и концентрация учебного времени именно там будет эффективной стратегией.', 'Регулярное повторение базовых понятий должно привести к заметному улучшению на следующей проверке.'],
      'AR': ['تحديد الجانب الأضعف نسبيًا (التحريري أو الأداء) وتركيز وقت الدراسة عليه سيكون استراتيجية فعالة.', 'الحفاظ على روتين مراجعة ثابت يغطي المفاهيم الأساسية يجب أن يؤدي إلى تحسن ملموس في التقييم القادم.'],
      'HI': ['लिखित या प्रदर्शन में जो अपेक्षाकृत कमजोर है उसे पहचानकर वहीं अध्ययन समय केंद्रित करना एक प्रभावी रणनीति होगी।', 'मूल अवधारणाओं को कवर करने वाली नियमित पुनरीक्षण दिनचर्या बनाए रखने से अगली परीक्षा में सार्थक सुधार की उम्मीद है।'],
      'VI': ['Xác định điểm viết hay thực hành đang tương đối yếu hơn rồi tập trung thời gian học vào đó sẽ là chiến lược hiệu quả.', 'Duy trì thói quen ôn tập đều đặn bao quát các khái niệm cốt lõi sẽ dẫn đến sự bứt phá đáng kể ở lần đánh giá tiếp theo.'],
      'ES': ['Identificar cuál de los dos (escrito o desempeño) es relativamente más débil y concentrar ahí el tiempo de estudio sería una estrategia eficaz.', 'Mantener una rutina de repaso constante de los conceptos básicos debería llevar a una recuperación significativa en la próxima evaluación.'],
      'TH': ['การระบุว่าข้อเขียนหรือภาคปฏิบัติส่วนใดอ่อนกว่าแล้วทุ่มเวลาเรียนไปที่จุดนั้นจะเป็นกลยุทธ์ที่มีประสิทธิภาพ', 'การรักษาการทบทวนแนวคิดพื้นฐานอย่างสม่ำเสมอจะนำไปสู่การฟื้นตัวที่ชัดเจนในการประเมินครั้งถัดไป'],
    },
    'low': {
      'KO': ['조급함보다는 기본 개념서를 처음부터 차분히 다시 훑어보는 방식으로 학습 밀도를 높여가는 것을 권해 드립니다.', '수행평가 준비 과정부터 꾸준히 챙기며 작은 성취를 쌓아가면, 자신감과 함께 점수도 서서히 회복될 것입니다.'],
      'EN': ['Rather than rushing, calmly working back through the basic concept textbook from the start is recommended to build up study density.', 'Steadily preparing for performance evaluations and stacking up small wins should gradually restore both confidence and scores.'],
      'JA': ['焦らず基本概念書を最初から落ち着いて見直す方式で学習密度を高めることをお勧めします。', '遂行評価の準備過程から着実に取り組み、小さな成功を積み重ねれば自信とともに点数も徐々に回復するでしょう。'],
      'ZH': ['建议不要急躁，而是从头冷静地重新梳理基础概念书，逐步提高学习密度。', '从表现评价准备阶段开始持续用心，积累小的成就，自信心与分数都会逐渐恢复。'],
      'FR': ["Plutôt que de se précipiter, revoir calmement le manuel des concepts de base depuis le début est recommandé pour renforcer la densité d'étude.", "Se préparer régulièrement aux évaluations de performance et accumuler de petites réussites devrait progressivement restaurer confiance et résultats."],
      'DE': ['Statt zu hetzen, wird empfohlen, das Grundlagenlehrbuch ruhig von Anfang an durchzuarbeiten, um die Lerndichte zu erhöhen.', 'Beständige Vorbereitung auf Leistungsbewertungen und das Sammeln kleiner Erfolge sollten schrittweise sowohl Selbstvertrauen als auch Noten wiederherstellen.'],
      'RU': ['Вместо спешки рекомендуется спокойно заново пройти базовый учебник концепций с самого начала, повышая плотность обучения.', 'Стабильная подготовка к практическим оценкам и накопление небольших успехов постепенно восстановят и уверенность, и баллы.'],
      'AR': ['بدلاً من التسرع، يُنصح بمراجعة كتاب المفاهيم الأساسية بهدوء من البداية لزيادة كثافة الدراسة.', 'التحضير المستمر لتقييمات الأداء وتراكم الانتصارات الصغيرة سيعيد تدريجيًا كلاً من الثقة والدرجات.'],
      'HI': ['जल्दबाजी के बजाय, शांतिपूर्वक शुरुआत से बुनियादी अवधारणा पुस्तक को फिर से देखने की सलाह दी जाती है ताकि अध्ययन घनत्व बढ़े।', 'प्रदर्शन मूल्यांकन की तैयारी से लगातार शुरुआत कर छोटी उपलब्धियां जमा करने से आत्मविश्वास के साथ अंक भी धीरे-धीरे लौटेंगे।'],
      'VI': ['Thay vì vội vàng, nên bình tĩnh xem lại sách khái niệm cơ bản từ đầu để tăng mật độ học tập.', 'Chuẩn bị đều đặn cho đánh giá thực hành và tích lũy những thành công nhỏ sẽ dần khôi phục cả sự tự tin lẫn điểm số.'],
      'ES': ['En lugar de apresurarse, se recomienda repasar con calma el libro de conceptos básicos desde el principio para aumentar la densidad de estudio.', 'Prepararse de forma constante para las evaluaciones de desempeño y acumular pequeños logros restaurará gradualmente tanto la confianza como las notas.'],
      'TH': ['แนะนำให้ทบทวนตำราแนวคิดพื้นฐานตั้งแต่ต้นอย่างใจเย็นแทนการเร่งรีบ เพื่อเพิ่มความเข้มข้นในการเรียน', 'การเตรียมตัวสำหรับการประเมินภาคปฏิบัติอย่างสม่ำเสมอและสะสมความสำเร็จเล็กๆ จะค่อยๆ ฟื้นฟูทั้งความมั่นใจและคะแนน'],
    },
    'critical': {
      'KO': ['지금은 문제 양보다 기본 개념 하나하나를 확실히 이해하는 데 집중하는 시기이며, 작은 성공 경험을 쌓아가는 것이 무엇보다 중요합니다.', '주변의 도움을 받아 취약한 기초 단원부터 차근차근 짚어나가면, 충분히 반등할 수 있는 잠재력이 있습니다.'],
      'EN': ['Right now, the priority is understanding each basic concept solidly rather than increasing practice volume — building small wins one at a time matters most.', 'With some outside support, working step by step through the weakest foundational units should reveal real potential to turn things around.'],
      'JA': ['今は問題量よりも基本概念一つ一つを確実に理解することに集中する時期であり、小さな成功体験を積み重ねることが何より重要です。', '周囲の助けを借りて弱い基礎単元から着実に取り組めば、十分に反騰できる潜在力があります。'],
      'ZH': ['现阶段比起题量，更应专注于确实理解每一个基本概念，积累小的成功经验尤为重要。', '借助周围的帮助，从薄弱的基础单元开始逐步夯实，完全具备反弹的潜力。'],
      'FR': ["Pour l'instant, la priorité est de bien comprendre chaque concept de base plutôt que d'augmenter le volume d'exercices — accumuler de petites réussites une à la fois est essentiel.", "Avec un peu de soutien extérieur, revoir étape par étape les unités fondamentales les plus faibles devrait révéler un vrai potentiel de redressement."],
      'DE': ['Im Moment liegt die Priorität darin, jedes Grundkonzept solide zu verstehen, statt das Übungsvolumen zu erhöhen — kleine Erfolge nacheinander aufzubauen zählt am meisten.', 'Mit etwas externer Unterstützung sollte das schrittweise Durcharbeiten der schwächsten Grundlageneinheiten echtes Umkehrpotenzial zeigen.'],
      'RU': ['Сейчас приоритет — прочно понять каждое базовое понятие, а не увеличивать объём практики; накопление небольших успехов важнее всего.', 'При некоторой внешней поддержке пошаговая проработка самых слабых базовых разделов должна раскрыть реальный потенциал для перелома ситуации.'],
      'AR': ['الآن، الأولوية هي فهم كل مفهوم أساسي بشكل راسخ بدلاً من زيادة حجم التدريب — بناء انتصارات صغيرة واحدة تلو الأخرى هو الأهم.', 'مع بعض الدعم الخارجي، فإن العمل خطوة بخطوة عبر أضعف الوحدات الأساسية يجب أن يكشف عن إمكانية حقيقية لتغيير الوضع.'],
      'HI': ['अभी प्राथमिकता अभ्यास की मात्रा बढ़ाने के बजाय हर बुनियादी अवधारणा को मजबूती से समझना है — एक-एक कर छोटी सफलताएं बनाना सबसे महत्वपूर्ण है।', 'कुछ बाहरी सहायता के साथ, सबसे कमजोर बुनियादी इकाइयों पर चरणबद्ध तरीके से काम करने से स्थिति बदलने की वास्तविक संभावना दिखेगी।'],
      'VI': ['Hiện tại, ưu tiên là hiểu vững từng khái niệm cơ bản thay vì tăng khối lượng luyện tập — xây dựng từng thành công nhỏ một là quan trọng nhất.', 'Với một chút hỗ trợ từ bên ngoài, việc xử lý từng bước các chương nền tảng yếu nhất sẽ cho thấy tiềm năng thực sự để thay đổi tình hình.'],
      'ES': ['En este momento, la prioridad es comprender sólidamente cada concepto básico en lugar de aumentar el volumen de práctica — construir pequeños logros uno a la vez es lo más importante.', 'Con algo de apoyo externo, trabajar paso a paso las unidades fundamentales más débiles debería revelar un verdadero potencial de mejora.'],
      'TH': ['ตอนนี้สิ่งสำคัญที่สุดคือการทำความเข้าใจแนวคิดพื้นฐานแต่ละอย่างให้แน่นมากกว่าการเพิ่มปริมาณโจทย์ การสั่งสมความสำเร็จเล็กๆ ทีละอย่างสำคัญที่สุด', 'หากได้รับความช่วยเหลือจากรอบข้าง การไล่ทบทวนหน่วยพื้นฐานที่อ่อนแอที่สุดทีละขั้นจะแสดงให้เห็นศักยภาพที่แท้จริงในการพลิกสถานการณ์'],
    },
  };

  // 성취도(gke_exam_records) 기록 비교 문장: gap 근접/양수/음수 3가지
  static const Map<String, List<String>> _achievementGap = {
    'KO': [
      ' 평소 학습 기록에 나타난 성취도 흐름과도 비슷한 수준을 유지하고 있어, 실력이 안정적으로 자리 잡았다고 볼 수 있습니다.',
      ' 평소 학습 기록보다 이번 성적관리 반영점수가 더 높게 나타나, 최근 집중도가 상승한 것으로 보입니다.',
      ' 평소 학습 기록에 비해 이번 반영점수가 다소 낮게 나타나, 컨디션이나 준비 과정을 함께 점검해 볼 필요가 있습니다.',
    ],
    'EN': [
      ' This is also in line with the trend seen in regular study records, suggesting the current level is fairly stable.',
      ' This is higher than the trend seen in regular study records, suggesting recent focus has improved.',
      ' This is a bit lower than the trend seen in regular study records, so it may help to check recent condition or preparation.',
    ],
    'JA': [
      ' 普段の学習記録に現れる成果の流れとも似た水準を維持しており、実力が安定して定着したと言えます。',
      ' 普段の学習記録よりも今回の反映点数が高く現れており、最近の集中度が上昇したものと見られます。',
      ' 普段の学習記録に比べて今回の反映点数がやや低く現れており、コンディションや準備過程を一緒に点検する必要があります。',
    ],
    'ZH': [
      ' 与平时学习记录中呈现的成就趋势保持相似水平，说明实力已趋于稳定。',
      ' 本次反映分数高于平时学习记录，说明近期专注度有所提升。',
      ' 本次反映分数低于平时学习记录，建议一并检查身体状态或准备过程。',
    ],
    'FR': [
      " Cela correspond également à la tendance observée dans les registres d'étude habituels, suggérant un niveau assez stable.",
      " Ce résultat est supérieur à la tendance des registres d'étude habituels, ce qui suggère une concentration récemment améliorée.",
      " Ce résultat est légèrement inférieur à la tendance des registres d'étude habituels ; il peut être utile de vérifier l'état ou la préparation récente.",
    ],
    'DE': [
      ' Dies entspricht auch dem Trend der regulären Lernaufzeichnungen, was auf ein recht stabiles aktuelles Niveau hindeutet.',
      ' Dies liegt über dem Trend der regulären Lernaufzeichnungen, was auf eine verbesserte jüngste Konzentration hindeutet.',
      ' Dies liegt etwas unter dem Trend der regulären Lernaufzeichnungen, daher könnte es helfen, den aktuellen Zustand oder die Vorbereitung zu überprüfen.',
    ],
    'RU': [
      ' Это также согласуется с тенденцией, отражённой в обычных учебных записях, что говорит о довольно стабильном текущем уровне.',
      ' Это выше тенденции обычных учебных записей, что говорит об улучшении концентрации в последнее время.',
      ' Это немного ниже тенденции обычных учебных записей, поэтому может быть полезно проверить состояние или подготовку в последнее время.',
    ],
    'AR': [
      ' يتماشى هذا أيضًا مع الاتجاه الظاهر في سجلات الدراسة المعتادة، مما يشير إلى استقرار المستوى الحالي إلى حد كبير.',
      ' هذا أعلى من الاتجاه الظاهر في سجلات الدراسة المعتادة، مما يشير إلى تحسن التركيز مؤخرًا.',
      ' هذا أقل قليلاً من الاتجاه الظاهر في سجلات الدراسة المعتادة، لذا قد يكون من المفيد مراجعة الحالة أو التحضير الأخير.',
    ],
    'HI': [
      ' यह सामान्य अध्ययन रिकॉर्ड में दिखने वाली प्रवृत्ति के अनुरूप भी है, जो दर्शाता है कि वर्तमान स्तर काफी स्थिर है।',
      ' यह सामान्य अध्ययन रिकॉर्ड की प्रवृत्ति से अधिक है, जो हाल में बेहतर एकाग्रता का संकेत देता है।',
      ' यह सामान्य अध्ययन रिकॉर्ड की प्रवृत्ति से थोड़ा कम है, इसलिए हाल की स्थिति या तैयारी की जांच करना सहायक हो सकता है।',
    ],
    'VI': [
      ' Điều này cũng phù hợp với xu hướng thấy trong hồ sơ học tập thường ngày, cho thấy mức độ hiện tại khá ổn định.',
      ' Điều này cao hơn xu hướng trong hồ sơ học tập thường ngày, cho thấy sự tập trung gần đây đã cải thiện.',
      ' Điều này thấp hơn một chút so với xu hướng trong hồ sơ học tập thường ngày, nên có thể cần kiểm tra tình trạng hoặc quá trình chuẩn bị gần đây.',
    ],
    'ES': [
      ' Esto también coincide con la tendencia observada en los registros de estudio habituales, lo que sugiere un nivel actual bastante estable.',
      ' Esto es más alto que la tendencia de los registros de estudio habituales, lo que sugiere una mejora reciente en la concentración.',
      ' Esto es un poco más bajo que la tendencia de los registros de estudio habituales, por lo que podría ser útil revisar el estado o la preparación reciente.',
    ],
    'TH': [
      ' สอดคล้องกับแนวโน้มที่ปรากฏในบันทึกการเรียนตามปกติ แสดงว่าระดับปัจจุบันค่อนข้างมั่นคง',
      ' สูงกว่าแนวโน้มในบันทึกการเรียนตามปกติ แสดงว่าความตั้งใจในช่วงนี้ดีขึ้น',
      ' ต่ำกว่าแนวโน้มในบันทึกการเรียนตามปกติเล็กน้อย จึงควรตรวจสอบสภาพร่างกายหรือการเตรียมตัวช่วงนี้ด้วย',
    ],
  };

  static String _tierFor(double avg) {
    if (avg >= 90) return 'excellent';
    if (avg >= 80) return 'good';
    if (avg >= 70) return 'mid';
    if (avg >= 60) return 'low';
    return 'critical';
  }

  static GradeSummaryResult _generate(double combinedAverage, double? achievementAverage) {
    final random = math.Random();
    final String tier = _tierFor(combinedAverage);

    // 🆕 모든 언어가 같은 뉘앙스를 유지하도록 동일한 인덱스를 뽑아 12개 언어에 동시 적용
    final int openIdx = random.nextInt(_openings[tier]!['KO']!.length);
    final int midIdx = random.nextInt(_middles[tier]!['KO']!.length);
    final int closeIdx = random.nextInt(_closings[tier]!['KO']!.length);

    int? gapIdx;
    if (achievementAverage != null) {
      final double gap = combinedAverage - achievementAverage;
      gapIdx = gap.abs() < 5 ? 0 : (gap > 0 ? 1 : 2);
    }

    final Map<String, String> texts = {};
    for (final lang in _langCodes) {
      String text = _openings[tier]![lang]![openIdx] + _middles[tier]![lang]![midIdx] + _closings[tier]![lang]![closeIdx];
      if (gapIdx != null) {
        text += _achievementGap[lang]![gapIdx];
      }
      texts[lang] = text;
    }

    return GradeSummaryResult(texts);
  }
}
