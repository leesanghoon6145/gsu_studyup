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

// 🆕 [요청] 한글+영문 병기 - 기본모드(KO/EN 미선택)는 "한글/English" 동시 표시,
// 10개국어 선택 시엔 해당 언어만 단독 표시 (다른 부모 화면 파일들과 동일한 관례)
String _bi(Map<String, String> map) {
  if (DkeLang.isForeignSelected) return _t(map);
  return "${map['KO']}/${map['EN']}";
}

// 🆕 [요청] 유형 명칭 변경: 기본형→성장형 / 동기부여형→도전형 / 챔피언형→성취형
const Map<String, Map<String, String>> kScholarshipTypeNameMap = {
  'basic': {
    'KO': '성장형', 'EN': 'Growth', 'JA': '成長型', 'ZH': '成长型', 'FR': 'Croissance',
    'DE': 'Wachstum', 'RU': 'Рост', 'AR': 'نمو', 'HI': 'विकास', 'VI': 'Tăng trưởng',
    'ES': 'Crecimiento', 'TH': 'การเติบโต',
  },
  'motivation': {
    'KO': '도전형', 'EN': 'Challenge', 'JA': 'チャレンジ型', 'ZH': '挑战型', 'FR': 'Défi',
    'DE': 'Herausforderung', 'RU': 'Вызов', 'AR': 'تحدي', 'HI': 'चुनौती', 'VI': 'Thử thách',
    'ES': 'Desafío', 'TH': 'ความท้าทาย',
  },
  'champion': {
    'KO': '성취형', 'EN': 'Achievement', 'JA': '達成型', 'ZH': '成就型', 'FR': 'Accomplissement',
    'DE': 'Erfolg', 'RU': 'Достижение', 'AR': 'إنجاز', 'HI': 'उपलब्धि', 'VI': 'Thành tựu',
    'ES': 'Logro', 'TH': 'ความสำเร็จ',
  },
};

String scholarshipTypeName(ScholarshipType type) {
  final map = kScholarshipTypeNameMap[type.name];
  if (map == null) return type.name;
  return _bi(map);
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
  'KO': '자녀 학습 장학금 안내',
  'EN': "Notice: Your Child's Study Scholarship",
};

const Map<String, String> kPhilosophyPopupBodyMap = {
  'KO':
  '매일 한 걸음씩 꾸준히 공부하며 모은 별은\n단순한 숫자가 아니라 자녀의 노력과 성취를 기록한 소중한 결과입니다.\n\nGKE StudyUp에서는 학생이 스스로 세운 목표를 실천하고\n꾸준히 학습한 만큼 별을 모아 장학금으로 환산할 수 있습니다.\n\n그리고 이 장학금은\n부모님께서 자녀의 노력에 대한 따뜻한 격려와 응원의 마음을 직접 전해주는 것을 권장합니다.\n\n"공부해라"라는 말보다\n"네가 노력한 만큼 정말 잘했다."라는 한마디가\n아이에게는 더 큰 힘이 될 수 있습니다.\n\n오늘도 열심히 노력한 자녀에게\n부모님의 작은 응원을 선물해 주세요. 💛\n\n※ 장학금 지급 여부와 금액은 가정의 상황에 맞게 부모님께서 자율적으로 결정하실 수 있습니다.',
  'EN':
  "The stars your child collects by studying steadily, one step at a time, aren't just numbers — they're a precious record of your child's effort and achievement.\n\nOn GKE StudyUp, students can turn the stars they earn from working toward their own goals into a scholarship.\n\nAnd we encourage parents to use this scholarship as a way to directly express warm encouragement and support for your child's effort.\n\nMore than saying \"go study,\"\na single \"I'm proud of how hard you worked\" can mean so much more to your child.\n\nGive your child, who worked hard again today,\na small gift of your encouragement. 💛\n\n※ Whether to give the scholarship and how much is entirely up to each family to decide as fits their situation.",
};

const Map<String, String> kCloseBtnMap = {
  'KO': '부모님께 안내하기', 'EN': 'Guide for Parents',
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

// 🆕 [요청] "🌟 자녀의 학습 별 2,480개" 형식의 헤더 줄 (한글+영문 병기)
String studyStarsLine(int count) {
  final String formatted = _formatNumber(count);
  if (DkeLang.isForeignSelected) {
    return "🌟 Child's Study Stars: $formatted";
  }
  return "🌟 자녀의 학습 별 $formatted개 / Child's Study Stars: $formatted";
}

// 🆕 [요청] "장학금 환산액 ○○○원 (자동 환산됨)" 형식 (한글+영문 병기)
String scholarshipAmountLine(int amount) {
  final String money = wonText(amount);
  if (DkeLang.isForeignSelected) {
    return 'Scholarship value: $money (auto-calculated)';
  }
  return '장학금 환산액 $money (자동 환산됨) / Scholarship value: $money (auto-calculated)';
}

class ParentScholarshipWidget extends StatefulWidget {
  final Color premiumCardBg;
  final Color brandGolden;
  final Color luxuryDarkBg;

  // 🆕 [버그 수정 2026-09-06] 자녀를 선택한 상태(Firestore 연동)일 때, 부모 대시보드가
  // 그 자녀의 실제 누적 별 개수를 여기로 넘겨줍니다. null이면(연결된 자녀 없음 - 기존
  // 단일기기 사용자) 원래처럼 이 기기의 로컬 별 데이터를 사용합니다.
  final int? overrideTotalStars;

  const ParentScholarshipWidget({
    Key? key,
    required this.premiumCardBg,
    required this.brandGolden,
    required this.luxuryDarkBg,
    this.overrideTotalStars,
  }) : super(key: key);

  @override
  State<ParentScholarshipWidget> createState() => _ParentScholarshipWidgetState();
}

class _ParentScholarshipWidgetState extends State<ParentScholarshipWidget> {
  ScholarshipType _selectedType = ScholarshipType.motivation;
  ScholarshipResult? _result;
  bool _loading = true;
  bool _expanded = false;
  bool _introShown = false; // 🆕 [반복 방지] 이 화면에 처음 들어왔을 때 딱 한 번만 안내 팝업 자동 표시

  @override
  void initState() {
    super.initState();
    _load();
  }

  // 🆕 [버그 수정 2026-09-06] 부모가 다른 자녀로 전환하면(overrideTotalStars 값이 바뀌면)
  // 그 자녀의 별 개수 기준으로 다시 계산합니다.
  @override
  void didUpdateWidget(covariant ParentScholarshipWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.overrideTotalStars != null && widget.overrideTotalStars != oldWidget.overrideTotalStars) {
      _load();
    }
  }

  Future<void> _load() async {
    final ScholarshipType type = await ScholarshipService.getSelectedType();
    // 🆕 [버그 수정 2026-09-06] 자녀가 선택되어 있으면(overrideTotalStars != null) 그 자녀의
    // 실제 Firestore 별 개수로 계산하고, 없으면 기존처럼 이 기기의 로컬 데이터를 사용합니다.
    final ScholarshipResult result = widget.overrideTotalStars != null
        ? ScholarshipService.calculateFromStars(type: type, totalStars: widget.overrideTotalStars!)
        : await ScholarshipService.calculate(type);
    if (!mounted) return;
    setState(() {
      _selectedType = type;
      _result = result;
      _loading = false;
    });
    // 🆕 [요청 변경] 화면 진입 시가 아니라, "오늘의 별 수집 현황" 3개 유형 중
    // 하나를 처음 탭했을 때 딱 한 번만 안내 팝업이 뜨도록 변경 (_onTypeChanged에서 트리거)
  }

  // 🆕 [반복 방지] _introShown 플래그로 세션당 한 번만 자동 표시. 이후엔 ⓘ 아이콘으로
  // 언제든 다시 볼 수 있음(수동 트리거는 그대로 유지).
  void _showIntroPopupOnce() {
    if (_introShown || !mounted) return;
    _introShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showPhilosophyPopup();
    });
  }

  // 🆕 [요청] 유형 3개(성장형/도전형/성취형) 중 하나를 탭하면, 처음 한 번만 안내 팝업을
  // 보여줍니다. 🆕 [화면 튐 수정] 예전엔 전환 중 _loading=true로 전체를 로딩 스피너로
  // 바꿔서, 카드 높이가 갑자기 줄었다가 늘어나며 상위 스크롤이 튀는 것처럼 보였습니다.
  // 이제 계산이 끝날 때까지 기존 카드 내용을 그대로 유지한 채 결과만 갱신합니다.
  Future<void> _onTypeChanged(ScholarshipType type) async {
    if (type == _selectedType) return;
    _showIntroPopupOnce(); // 처음 탭했을 때만 실제로 뜸 (플래그로 이후엔 무시됨)
    setState(() {
      _selectedType = type; // 카드 레이아웃은 그대로 유지, 유형명만 먼저 바뀜
    });
    await ScholarshipService.setSelectedType(type);
    final ScholarshipResult result = widget.overrideTotalStars != null
        ? ScholarshipService.calculateFromStars(type: type, totalStars: widget.overrideTotalStars!)
        : await ScholarshipService.calculate(type);
    if (!mounted) return;
    setState(() {
      _result = result;
    });
  }

  void _showPhilosophyPopup() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: ConstrainedBox(
          // 🆕 [오버플로우 수정] 문구가 길어져도 화면 높이를 넘지 않도록 최대 높이를 제한하고,
          // 그 안에서 내용만 스크롤되게 합니다. 버튼은 항상 하단에 고정됩니다.
          constraints: BoxConstraints(maxHeight: MediaQuery.of(dialogContext).size.height * 0.82),
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
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: widget.brandGolden, size: 30),
                        const SizedBox(height: 14),
                        Text(
                          _bi(kPhilosophyPopupTitleMap),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSansKr(
                            color: widget.brandGolden,
                            fontSize: 15.5,
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
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
                      _bi(kCloseBtnMap),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
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
                                studyStarsLine(result.starToMoney ~/ 3),
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
                        const SizedBox(height: 6),
                        Text(
                          scholarshipTypeName(_selectedType),
                          style: GoogleFonts.notoSansKr(
                            color: widget.brandGolden,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scholarshipAmountLine(result.finalTotal),
                          style: GoogleFonts.notoSansKr(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
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
