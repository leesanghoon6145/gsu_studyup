import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/scholarship_service.dart';
import '../global_lang.dart';

// ---------------------------------------------------------------------------
// 🆕 [12개국어] 이 위젯 전용 번역 헬퍼/사전. 다른 부모 화면 파일들과 동일한 규칙:
// KO/EN/JA/ZH/FR/DE/RU/AR/HI/VI/ES/TH 12개 언어 코드를 사용합니다.
// ---------------------------------------------------------------------------
String _t(Map<String, String> map) =>
    map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? '';

const Map<String, Map<String, String>> kScholarshipTypeNameMap = {
  'basic': {
    'KO': '기본형', 'EN': 'Basic', 'JA': '基本型', 'ZH': '基础型', 'FR': 'Basique',
    'DE': 'Basis', 'RU': 'Базовый', 'AR': 'أساسي', 'HI': 'बेसिक', 'VI': 'Cơ bản',
    'ES': 'Básico', 'TH': 'พื้นฐาน',
  },
  'motivation': {
    'KO': '동기부여형', 'EN': 'Motivation', 'JA': '動機付け型', 'ZH': '激励型', 'FR': 'Motivation',
    'DE': 'Motivation', 'RU': 'Мотивационный', 'AR': 'تحفيزي', 'HI': 'प्रेरणा', 'VI': 'Động lực',
    'ES': 'Motivación', 'TH': 'สร้างแรงจูงใจ',
  },
  'champion': {
    'KO': '챔피언형', 'EN': 'Champion', 'JA': 'チャンピオン型', 'ZH': '冠军型', 'FR': 'Champion',
    'DE': 'Champion', 'RU': 'Чемпион', 'AR': 'بطل', 'HI': 'चैंपियन', 'VI': 'Nhà vô địch',
    'ES': 'Campeón', 'TH': 'แชมป์',
  },
};

String scholarshipTypeName(ScholarshipType type) {
  final map = kScholarshipTypeNameMap[type.name];
  if (map == null) return type.name;
  return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? type.name;
}

String scholarshipTitle(ScholarshipType type) {
  final String typeName = scholarshipTypeName(type);
  final Map<String, String> template = {
    'KO': '자기주도학습 $typeName 장학금',
    'EN': 'Self-Directed Learning $typeName Scholarship',
    'JA': '自己主導学習$typeName奨学金',
    'ZH': '自主学习$typeName奖学金',
    'FR': "Bourse d'apprentissage autonome ($typeName)",
    'DE': 'Stipendium für selbstgesteuertes Lernen ($typeName)',
    'RU': 'Стипендия за самостоятельное обучение ($typeName)',
    'AR': 'منحة التعلم الذاتي ($typeName)',
    'HI': 'स्व-निर्देशित शिक्षण छात्रवृत्ति ($typeName)',
    'VI': 'Học bổng học tập tự định hướng ($typeName)',
    'ES': 'Beca de aprendizaje autodirigido ($typeName)',
    'TH': 'ทุนการเรียนรู้ด้วยตนเอง ($typeName)',
  };
  return template[DkeLang.current] ?? template['EN']!;
}

const Map<String, String> kStarMoneyLabelMap = {
  'KO': '별 환산액', 'EN': 'Star Value', 'JA': '星換算額', 'ZH': '星星折算额',
  'FR': 'Valeur des étoiles', 'DE': 'Sternwert', 'RU': 'Стоимость звёзд',
  'AR': 'قيمة النجوم', 'HI': 'सितारा मूल्य', 'VI': 'Giá trị sao',
  'ES': 'Valor de estrellas', 'TH': 'มูลค่าดาว',
};
const Map<String, String> kAttendanceBonusLabelMap = {
  'KO': '주간 출석 보너스', 'EN': 'Weekly Attendance Bonus', 'JA': '週間出席ボーナス', 'ZH': '每周出勤奖金',
  'FR': 'Bonus de présence hebdo', 'DE': 'Wöchentlicher Anwesenheitsbonus', 'RU': 'Еженедельный бонус за посещаемость',
  'AR': 'مكافأة الحضور الأسبوعية', 'HI': 'साप्ताहिक उपस्थिति बोनस', 'VI': 'Thưởng chuyên cần hàng tuần',
  'ES': 'Bono de asistencia semanal', 'TH': 'โบนัสการเข้าเรียนรายสัปดาห์',
};
const Map<String, String> kStreakBonusLabelMap = {
  'KO': '7일 연속 출석 보너스', 'EN': '7-Day Streak Bonus', 'JA': '7日連続出席ボーナス', 'ZH': '连续7天出勤奖金',
  'FR': 'Bonus de 7 jours consécutifs', 'DE': '7-Tage-Serienbonus', 'RU': 'Бонус за 7 дней подряд',
  'AR': 'مكافأة 7 أيام متتالية', 'HI': '7-दिन की लगातार उपस्थिति बोनस', 'VI': 'Thưởng chuyên cần 7 ngày liên tiếp',
  'ES': 'Bono de racha de 7 días', 'TH': 'โบนัสเข้าเรียนต่อเนื่อง 7 วัน',
};
const Map<String, String> kLevelUpBonusLabelMap = {
  'KO': '레벨업 보너스', 'EN': 'Level-Up Bonus', 'JA': 'レベルアップボーナス', 'ZH': '升级奖金',
  'FR': 'Bonus de niveau supérieur', 'DE': 'Levelaufstiegs-Bonus', 'RU': 'Бонус за повышение уровня',
  'AR': 'مكافأة رفع المستوى', 'HI': 'लेवल-अप बोनस', 'VI': 'Thưởng lên cấp',
  'ES': 'Bono de subida de nivel', 'TH': 'โบนัสเลื่อนระดับ',
};
const Map<String, String> kMonthlyTotalLabelMap = {
  'KO': '이번 달 합계', 'EN': "This Month's Total", 'JA': '今月の合計', 'ZH': '本月总计',
  'FR': 'Total de ce mois', 'DE': 'Gesamt diesen Monat', 'RU': 'Итого за месяц',
  'AR': 'إجمالي هذا الشهر', 'HI': 'इस महीने का कुल', 'VI': 'Tổng tháng này',
  'ES': 'Total de este mes', 'TH': 'ยอดรวมเดือนนี้',
};
const Map<String, String> kCapNoteMap = {
  'KO': '월 최대 한도 적용됨', 'EN': 'Monthly cap applied', 'JA': '月間上限適用済み', 'ZH': '已应用月度上限',
  'FR': 'Plafond mensuel appliqué', 'DE': 'Monatliches Limit angewendet', 'RU': 'Применён месячный лимит',
  'AR': 'تم تطبيق الحد الشهري', 'HI': 'मासिक सीमा लागू', 'VI': 'Đã áp dụng giới hạn hàng tháng',
  'ES': 'Límite mensual aplicado', 'TH': 'ใช้เพดานรายเดือนแล้ว',
};

const Map<String, String> kPhilosophyPopupTitleMap = {
  'KO': '왜 "장학금"일까요?',
  'EN': 'Why call it a "Scholarship"?',
  'JA': 'なぜ「奨学金」なのでしょうか？',
  'ZH': '为什么叫"奖学金"？',
  'FR': 'Pourquoi une « bourse » ?',
  'DE': 'Warum ein „Stipendium"?',
  'RU': 'Почему это «стипендия»?',
  'AR': 'لماذا "منحة دراسية"؟',
  'HI': '"छात्रवृत्ति" ही क्यों?',
  'VI': 'Tại sao gọi là "học bổng"?',
  'ES': '¿Por qué llamarlo "beca"?',
  'TH': 'ทำไมถึงเรียกว่า "ทุนการศึกษา"?',
};

const Map<String, String> kPhilosophyPopupBodyMap = {
  'KO':
  '자녀에게 매달 정해진 용돈을 그냥 건네는 대신,\n스스로 계획하고 몰입한 시간을 별로 쌓아 올리고\n그 별이 눈에 보이는 보상으로 돌아오게 해보세요.\n\n노력한 만큼 정직하게 돌아오는 이 경험이,\n아이의 마음속에 "나는 해낼 수 있다"는 확신을 심어줍니다.\n\n이 장학금은 단순한 용돈이 아니라,\n자녀의 하루하루 노력에 보내는 부모님의 가장 따뜻한 응원입니다.',
  'EN':
  "Instead of simply handing over a fixed monthly allowance, let your child's own focus and effort build up into stars — stars that return as a visible reward.\n\nThis honest exchange between effort and reward plants a lasting belief in your child: \"I can do this.\"\n\nThis scholarship isn't just pocket money. It's the warmest way to say — I see how hard you're trying, and I'm proud of you.",
  'JA':
  '毎月決まったお小遣いをそのまま渡す代わりに、お子様が自ら計画し没頭した時間を星として積み上げ、その星が目に見える報酬として返ってくるようにしてみましょう。\n\n努力した分だけ正直に返ってくるこの経験が、「自分はやればできる」という確信を子どもの心に育てます。\n\nこの奨学金は単なるお小遣いではなく、お子様の日々の努力に贈る親御様の最も温かい応援です。',
  'ZH':
  '与其每月固定给孩子零花钱，不如让孩子自己规划、专注学习的时间累积成星星，再让这些星星变成看得见的奖励回到孩子手中。\n\n这种"付出多少、收获多少"的诚实体验，会在孩子心中种下"我能做到"的信念。\n\n这份奖学金不只是零花钱，而是父母对孩子每一天努力所给予的、最温暖的鼓励。',
  'FR':
  "Plutôt que de simplement verser une allocation mensuelle fixe, laissez le temps que votre enfant consacre lui-même à sa concentration et à ses efforts se transformer en étoiles — des étoiles qui reviennent sous forme de récompense visible.\n\nCet échange honnête entre l'effort et la récompense ancre en lui une conviction durable : « J'en suis capable ».\n\nCette bourse n'est pas un simple argent de poche. C'est la façon la plus chaleureuse de lui dire : je vois combien tu travailles dur, et je suis fier(ère) de toi.",
  'DE':
  'Anstatt einfach ein festes monatliches Taschengeld zu geben, lassen Sie die Zeit, die Ihr Kind selbst plant und sich konzentriert widmet, zu Sternen heranwachsen – Sternen, die als sichtbare Belohnung zurückkehren.\n\nDiese ehrliche Verbindung zwischen Anstrengung und Belohnung pflanzt in Ihrem Kind die dauerhafte Überzeugung: „Ich kann das schaffen."\n\nDieses Stipendium ist kein einfaches Taschengeld. Es ist die herzlichste Art zu sagen: Ich sehe, wie sehr du dich bemühst, und ich bin stolz auf dich.',
  'RU':
  'Вместо того чтобы просто выдавать фиксированные карманные деньги каждый месяц, позвольте времени, которое ребёнок сам планирует и посвящает учёбе, превращаться в звёзды — звёзды, которые возвращаются в виде видимой награды.\n\nЭтот честный обмен между усилием и наградой закладывает в ребёнке стойкую убеждённость: «Я справлюсь».\n\nЭта стипендия — не просто карманные деньги. Это самый тёплый способ сказать: я вижу, как ты стараешься, и горжусь тобой.',
  'AR':
  'بدلاً من مجرد إعطاء مصروف شهري ثابت، دع الوقت الذي يخطط له طفلك بنفسه وينغمس فيه يتحول إلى نجوم — نجوم تعود كمكافأة ملموسة.\n\nهذه المبادلة الصادقة بين الجهد والمكافأة تزرع في قلب طفلك قناعة راسخة: "أستطيع فعل ذلك".\n\nهذه المنحة ليست مجرد مصروف جيب، بل أدفأ طريقة تقول بها لطفلك: أرى مدى اجتهادك، وأنا فخور بك.',
  'HI':
  'हर महीने एक तय जेबखर्च सीधे देने के बजाय, अपने बच्चे के अपने प्रयास और एकाग्रता से बिताए समय को सितारों में बदलने दें — सितारे जो एक स्पष्ट पुरस्कार के रूप में वापस आते हैं।\n\nप्रयास और पुरस्कार के बीच का यह ईमानदार आदान-प्रदान बच्चे के मन में एक स्थायी विश्वास जगाता है: "मैं यह कर सकता/सकती हूं।"\n\nयह छात्रवृत्ति केवल जेबखर्च नहीं है। यह आपके बच्चे के रोज़ के प्रयास के लिए माता-पिता की सबसे गर्मजोशी भरी सराहना है।',
  'VI':
  'Thay vì chỉ đưa một khoản tiền tiêu vặt cố định hàng tháng, hãy để thời gian con tự lên kế hoạch và chuyên tâm học tập tích lũy thành những ngôi sao — những ngôi sao trở lại dưới dạng phần thưởng hữu hình.\n\nSự trao đổi trung thực giữa nỗ lực và phần thưởng này gieo vào lòng con niềm tin bền vững: "Con có thể làm được."\n\nHọc bổng này không chỉ là tiền tiêu vặt. Đó là cách ấm áp nhất để nói với con rằng: bố mẹ thấy con đã cố gắng thế nào, và bố mẹ tự hào về con.',
  'ES':
  'En lugar de simplemente entregar una mesada mensual fija, deje que el tiempo que su hijo/a planifica y dedica por sí mismo se convierta en estrellas, estrellas que regresan como una recompensa visible.\n\nEste intercambio honesto entre esfuerzo y recompensa siembra en el niño una convicción duradera: "puedo lograrlo".\n\nEsta beca no es solo dinero de bolsillo. Es la forma más cálida de decirle: veo lo mucho que te esfuerzas, y estoy orgulloso/a de ti.',
  'TH':
  'แทนที่จะให้ค่าขนมคงที่ทุกเดือนเฉยๆ ลองปล่อยให้เวลาที่ลูกวางแผนและตั้งใจเรียนด้วยตัวเองสะสมกลายเป็นดวงดาว แล้วดาวเหล่านั้นก็กลับมาเป็นรางวัลที่จับต้องได้\n\nประสบการณ์ที่ซื่อสัตย์ระหว่างความพยายามกับผลตอบแทนนี้ จะปลูกฝังความเชื่อมั่นในใจลูกว่า "ฉันทำได้"\n\nทุนนี้ไม่ใช่แค่ค่าขนม แต่เป็นวิธีที่อบอุ่นที่สุดที่พ่อแม่จะบอกลูกว่า พ่อแม่เห็นความพยายามของลูก และภูมิใจในตัวลูกมาก',
};

const Map<String, String> kCloseBtnMap = {
  'KO': '확인', 'EN': 'Got it', 'JA': '了解', 'ZH': '知道了', 'FR': 'Compris',
  'DE': 'Verstanden', 'RU': 'Понятно', 'AR': 'حسناً', 'HI': 'समझ गया', 'VI': 'Đã hiểu',
  'ES': 'Entendido', 'TH': 'เข้าใจแล้ว',
};

// 천 단위 콤마 + 통화 표기 (한국어는 "원", 그 외 언어는 "₩" 접두)
String _formatNumber(int n) {
  return n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

String wonText(int amount) {
  final String num = _formatNumber(amount);
  if (DkeLang.current == 'KO') return '$num원';
  return '₩$num';
}

class ParentScholarshipWidget extends StatefulWidget {
  final Color premiumCardBg;
  final Color brandGolden;
  final Color luxuryDarkBg;

  const ParentScholarshipWidget({
    Key? key,
    required this.premiumCardBg,
    required this.brandGolden,
    required this.luxuryDarkBg,
  }) : super(key: key);

  @override
  State<ParentScholarshipWidget> createState() => _ParentScholarshipWidgetState();
}

class _ParentScholarshipWidgetState extends State<ParentScholarshipWidget> {
  ScholarshipType _selectedType = ScholarshipType.motivation;
  ScholarshipResult? _result;
  bool _loading = true;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ScholarshipType type = await ScholarshipService.getSelectedType();
    final ScholarshipResult result = await ScholarshipService.calculate(type);
    if (!mounted) return;
    setState(() {
      _selectedType = type;
      _result = result;
      _loading = false;
    });
  }

  Future<void> _onTypeChanged(ScholarshipType type) async {
    if (type == _selectedType) return;
    setState(() {
      _loading = true;
      _selectedType = type;
    });
    await ScholarshipService.setSelectedType(type);
    final ScholarshipResult result = await ScholarshipService.calculate(type);
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  void _showPhilosophyPopup() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF0D1527), widget.luxuryDarkBg],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.brandGolden.withValues(alpha: 0.55), width: 1.3),
            boxShadow: [
              BoxShadow(
                color: widget.brandGolden.withValues(alpha: 0.18),
                blurRadius: 26,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded, color: widget.brandGolden, size: 30),
              const SizedBox(height: 14),
              Text(
                _t(kPhilosophyPopupTitleMap),
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                  color: widget.brandGolden,
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Container(width: 36, height: 1.2, color: widget.brandGolden.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                _t(kPhilosophyPopupBodyMap),
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13.2, height: 1.75),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.brandGolden,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    _t(kCloseBtnMap),
                    style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(ScholarshipType type) {
    final bool selected = _selectedType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(
          scholarshipTypeName(type),
          style: GoogleFonts.notoSansKr(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.black : Colors.white70,
          ),
        ),
        selected: selected,
        selectedColor: widget.brandGolden,
        backgroundColor: Colors.black38,
        onSelected: (_) => _onTypeChanged(type),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, int amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12)),
          Text(amount > 0 ? wonText(amount) : wonText(0),
              style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _result == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: widget.premiumCardBg, borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.center,
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: widget.brandGolden),
        ),
      );
    }

    final ScholarshipResult result = _result!;

    return Container(
      decoration: BoxDecoration(
        color: widget.premiumCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.brandGolden.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: ScholarshipType.values.map(_buildTypeChip).toList()),
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                scholarshipTitle(_selectedType),
                                style: GoogleFonts.notoSansKr(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: _showPhilosophyPopup,
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Icon(Icons.info_outline_rounded,
                                    color: widget.brandGolden.withValues(alpha: 0.85), size: 17),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          wonText(result.finalTotal),
                          style: GoogleFonts.rajdhani(
                            color: widget.brandGolden,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white10, height: 16),
                  _buildBreakdownRow(_t(kStarMoneyLabelMap), result.starToMoney),
                  if (_selectedType != ScholarshipType.basic)
                    _buildBreakdownRow(_t(kAttendanceBonusLabelMap), result.attendanceBonus),
                  if (_selectedType != ScholarshipType.basic)
                    _buildBreakdownRow(_t(kStreakBonusLabelMap), result.streakBonus),
                  if (_selectedType == ScholarshipType.champion)
                    _buildBreakdownRow(_t(kLevelUpBonusLabelMap), result.levelUpBonus),
                  const Divider(color: Colors.white10, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _t(kMonthlyTotalLabelMap),
                        style: GoogleFonts.notoSansKr(
                            color: widget.brandGolden, fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        wonText(result.finalTotal),
                        style: GoogleFonts.rajdhani(
                            color: widget.brandGolden, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (result.cappedAway > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '(${_t(kCapNoteMap)})',
                        style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10.5),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
