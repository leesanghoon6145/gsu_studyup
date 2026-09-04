import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/grade_management_service.dart';
import '../services/grade_diagnosis_service.dart';
import '../services/parent_data_service.dart';
import '../services/grade_language.dart';
import '../square/grade_management_screen.dart' show kSubjectRainbowColors;
import '../global_lang.dart';

/// ============================================================================
/// [GKE StudyUp] 학부모 화면 - [성적 관리] 탭 (조회 전용)
/// - 학생용 grade_management_screen.dart에서 입력한 데이터를 ParentDataService
///   게이트웨이를 통해서만 읽습니다.
/// - 총평 문구와 그래프는 학생 화면과 완전히 동일하게 미러링됩니다.
/// - 🆕 [12개국어 전면 확장] 공용 번역 사전(grade_language.dart)을 사용합니다.
///   기본모드(KO/EN 선택)는 한글+영문 동시 표시, 10개국어(JA/ZH/FR/DE/RU/AR/HI/VI/ES/TH)
///   선택 시 해당 언어만 단독 표시. 실제 데이터 저장 키(과목명·시험종류 등 한글 원문)는
///   절대 바꾸지 않고, 화면에 보여줄 때만 번역 사전을 거쳐 표시합니다.
/// - 🆕 [자녀 선택 UI + Firestore 연동 2026-09-04] overrideRecords/overrideConfigs가
///   주어지면(다른 기기의 자녀를 선택한 경우) 그 데이터를 그대로 사용하고, 주어지지 않으면
///   (기존 단일기기 사용자) 원래처럼 ParentDataService로 이 기기의 로컬 데이터를 읽습니다.
/// ============================================================================

// ---------------------------------------------------------------------------
// 🆕 학부모 화면 전용 번역 사전 (학생 화면에는 없는 이 화면 고유 문구)
// ---------------------------------------------------------------------------
const Map<String, String> kTitleEngMap = {'KO': 'GRADE MANAGEMENT', 'EN': 'GRADE MANAGEMENT', 'JA': 'GRADE MANAGEMENT', 'ZH': 'GRADE MANAGEMENT', 'FR': 'GRADE MANAGEMENT', 'DE': 'GRADE MANAGEMENT', 'RU': 'GRADE MANAGEMENT', 'AR': 'GRADE MANAGEMENT', 'HI': 'GRADE MANAGEMENT', 'VI': 'GRADE MANAGEMENT', 'ES': 'GRADE MANAGEMENT', 'TH': 'GRADE MANAGEMENT'};
const Map<String, String> kScreenSubtitleMap = {
  'KO': '성적 관리 조회', 'EN': 'Grade Report Viewer',
  'JA': '成績管理 照会', 'ZH': '成绩管理查询', 'FR': 'Consultation des notes', 'DE': 'Notenübersicht',
  'RU': 'Просмотр успеваемости', 'AR': 'عرض إدارة الدرجات', 'HI': 'ग्रेड रिपोर्ट व्यूअर', 'VI': 'Xem quản lý điểm',
  'ES': 'Consulta de calificaciones', 'TH': 'ดูการจัดการเกรด',
};
const Map<String, String> kScreenDescMap = {
  'KO': '학생이 직접 작성한 성적 기록을 조회 전용으로 확인합니다.', 'EN': "View-only access to the student's own grade records.",
  'JA': '生徒本人が入力した成績記録を照会専用で確認します。', 'ZH': '仅供查看学生本人录入的成绩记录。',
  'FR': "Consultation en lecture seule des notes saisies par l'élève.", 'DE': 'Nur-Lese-Ansicht der vom Schüler eingegebenen Noten.',
  'RU': 'Просмотр только для чтения записей об успеваемости, введённых учеником.', 'AR': 'عرض للقراءة فقط لسجلات الدرجات التي أدخلها الطالب.',
  'HI': 'छात्र द्वारा दर्ज किए गए ग्रेड रिकॉर्ड का केवल-दृश्य एक्सेस।', 'VI': 'Chỉ xem hồ sơ điểm do học sinh tự nhập.',
  'ES': 'Acceso de solo lectura a los registros de calificaciones del estudiante.', 'TH': 'ดูข้อมูลบันทึกเกรดที่นักเรียนกรอกเองแบบดูอย่างเดียว',
};
const Map<String, String> kNoRecordsAtAllMap = {
  'KO': '아직 자녀가 입력한 성적 기록이 없습니다. 자녀가 [성적 관리] 화면에서 성적을 입력하면 여기에 표시됩니다.',
  'EN': "Your child hasn't entered any grades yet. Once they do in the [Grade Management] screen, records will appear here.",
  'JA': 'まだお子様が入力した成績記録がありません。お子様が[成績管理]画面で成績を入力すると、ここに表示されます。',
  'ZH': '孩子尚未录入任何成绩记录。孩子在[成绩管理]页面录入成绩后，将显示在此处。',
  'FR': "Votre enfant n'a pas encore saisi de notes. Une fois saisies dans l'écran [Gestion des notes], elles apparaîtront ici.",
  'DE': 'Ihr Kind hat noch keine Noten eingetragen. Sobald dies im Bildschirm [Notenverwaltung] geschieht, erscheinen sie hier.',
  'RU': 'Ваш ребёнок ещё не ввёл оценки. После ввода на экране [Управление оценками] они появятся здесь.',
  'AR': 'لم يقم طفلك بإدخال أي درجات بعد. بمجرد إدخالها في شاشة [إدارة الدرجات]، ستظهر هنا.',
  'HI': 'आपके बच्चे ने अभी तक कोई ग्रेड दर्ज नहीं किया है। [ग्रेड प्रबंधन] स्क्रीन में दर्ज करते ही यहाँ दिखाई देगा।',
  'VI': 'Con bạn chưa nhập điểm nào. Khi nhập ở màn hình [Quản lý điểm], hồ sơ sẽ hiển thị tại đây.',
  'ES': 'Su hijo/a aún no ha ingresado calificaciones. Una vez que lo haga en la pantalla [Gestión de calificaciones], aparecerán aquí.',
  'TH': 'บุตรหลานยังไม่ได้กรอกคะแนน เมื่อกรอกในหน้าจอ [จัดการเกรด] แล้ว จะแสดงที่นี่',
};

const Map<String, String> kParentIntroPopupMap = {
  'KO': "이 성적표는 자녀가 직접 입력한 자율 기록을 바탕으로 자동 계산된 참고용 자료입니다.\n학교에서 공식적으로 발표한 성적표와는 차이가 있을 수 있는 점 양해 부탁드립니다.\n자녀의 학업 흐름을 살펴보는 참고 자료로 편하게 활용해 주세요.",
  'EN': "This report is a reference automatically calculated from records your child entered independently.\nPlease note it may differ from the school's official report card.\nFeel free to use it as a casual reference for your child's learning trends.",
  'JA': "この成績表は、お子様ご自身が入力した自律的な記録をもとに自動計算された参考資料です。\n学校が公式に発表する成績表とは差がある場合がありますので、ご了承ください。\nお子様の学習の流れを把握する参考資料として、お気軽にご活用ください。",
  'ZH': "此成绩单是根据孩子自行录入的记录自动计算得出的参考资料。\n请注意，可能与学校官方发布的成绩单存在差异。\n请将其作为了解孩子学习状况的参考资料轻松使用。",
  'FR': "Ce bulletin est une référence calculée automatiquement à partir des données saisies par votre enfant.\nIl peut différer du bulletin officiel de l'école.\nUtilisez-le simplement comme repère pour suivre les progrès de votre enfant.",
  'DE': "Dieses Zeugnis ist ein automatisch berechneter Referenzwert basierend auf den von Ihrem Kind selbst eingegebenen Daten.\nEs kann vom offiziellen Zeugnis der Schule abweichen.\nNutzen Sie es einfach als lockere Orientierung für den Lernfortschritt Ihres Kindes.",
  'RU': "Этот табель — справочные данные, автоматически рассчитанные на основе записей, которые ваш ребёнок ввёл самостоятельно.\nОн может отличаться от официального табеля школы.\nИспользуйте его как удобный ориентир для отслеживания успеваемости ребёнка.",
  'AR': "بطاقة الدرجات هذه مرجع محسوب تلقائيًا بناءً على السجلات التي أدخلها طفلك بنفسه.\nيرجى ملاحظة أنها قد تختلف عن بطاقة الدرجات الرسمية للمدرسة.\nاستخدمها بحرية كمرجع لمتابعة تقدم طفلك الدراسي.",
  'HI': "यह रिपोर्ट कार्ड आपके बच्चे द्वारा स्वयं दर्ज किए गए रिकॉर्ड के आधार पर स्वचालित रूप से गणना किया गया संदर्भ है।\nकृपया ध्यान दें कि यह स्कूल के आधिकारिक रिपोर्ट कार्ड से भिन्न हो सकता है।\nइसे अपने बच्चे की सीखने की प्रवृत्ति देखने के लिए सहज संदर्भ के रूप में उपयोग करें।",
  'VI': "Học bạ này là tài liệu tham khảo được tự động tính toán từ hồ sơ do con bạn tự nhập.\nCó thể sẽ khác với học bạ chính thức của trường.\nHãy thoải mái dùng để tham khảo xu hướng học tập của con.",
  'ES': "Este boletín es una referencia calculada automáticamente a partir de los registros que su hijo/a ingresó por su cuenta.\nTenga en cuenta que puede diferir del boletín oficial de la escuela.\nÚselo libremente como referencia para ver la tendencia de aprendizaje de su hijo/a.",
  'TH': "สมุดพกนี้เป็นข้อมูลอ้างอิงที่คำนวณอัตโนมัติจากบันทึกที่บุตรหลานกรอกเอง\nอาจแตกต่างจากสมุดพกที่โรงเรียนประกาศอย่างเป็นทางการ\nโปรดใช้เป็นข้อมูลอ้างอิงแบบสบาย ๆ เพื่อดูแนวโน้มการเรียนของบุตรหลาน",
};

class ParentGradeManagementWidget extends StatefulWidget {
  final String childName;
  final Color premiumCardBg;
  final Color brandGolden;
  final Color luxuryDarkBg;
  final Widget Function(String engTitle, String korTitle, {required double fontSize}) buildCustomSectionTitle;

  // 🆕 [자녀 선택 UI + Firestore 연동] 다른 기기의 자녀를 선택한 경우, 대시보드가
  // Firestore에서 읽어온 데이터를 여기로 넘겨줍니다. null이면(연결된 자녀가 없는
  // 기존 단일기기 사용자) 원래처럼 이 기기의 로컬 데이터(ParentDataService)를 읽습니다.
  final List<GradeRecord>? overrideRecords;
  final List<SubjectConfig>? overrideConfigs;
  final double? overrideAchievementAverage;

  const ParentGradeManagementWidget({
    Key? key,
    required this.childName,
    required this.premiumCardBg,
    required this.brandGolden,
    required this.luxuryDarkBg,
    required this.buildCustomSectionTitle,
    this.overrideRecords,
    this.overrideConfigs,
    this.overrideAchievementAverage,
  }) : super(key: key);

  @override
  State<ParentGradeManagementWidget> createState() => _ParentGradeManagementWidgetState();
}

class _ParentGradeManagementWidgetState extends State<ParentGradeManagementWidget> {
  bool _isLoading = true;
  List<GradeRecord> _allRecords = [];
  List<SubjectConfig> _allConfigs = [];

  String _schoolLevel = "중등부";
  int _grade = 1;
  int _semester = 1;

  String? _summaryText;
  bool _isSummaryLoading = false;
  bool _introShown = false;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  // 🆕 [자녀 선택 UI + Firestore 연동] 부모가 다른 자녀로 전환하면(overrideRecords가
  // 다른 데이터로 바뀌면) 화면을 그 자녀 데이터로 다시 불러옵니다.
  @override
  void didUpdateWidget(covariant ParentGradeManagementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool usingOverride = widget.overrideRecords != null;
    final bool childChanged = widget.childName != oldWidget.childName;
    if (usingOverride && (childChanged || !identical(widget.overrideRecords, oldWidget.overrideRecords))) {
      _introShown = false; // 자녀가 바뀌면 안내 팝업도 다시 보여줄 수 있게 초기화
      _loadRecords();
    }
  }

  void _showIntroPopupOnce() {
    if (_introShown || !mounted) return;
    _introShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: widget.premiumCardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: widget.brandGolden.withOpacity(0.55), width: 1.6),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t(kPopupTitleMap), style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Text(biLong(kParentIntroPopupMap), style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13, height: 1.6)),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: widget.brandGolden),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(t(kConfirmBtnMap), style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Future<void> _loadRecords() async {
    // 🆕 [자녀 선택 UI + Firestore 연동] override 데이터가 있으면(다른 기기의 자녀 선택 중)
    // 그것을 그대로 쓰고, 없으면 기존처럼 이 기기의 로컬 데이터를 읽습니다.
    final List<GradeRecord> all;
    final List<SubjectConfig> configs;
    if (widget.overrideRecords != null) {
      all = widget.overrideRecords!;
      configs = widget.overrideConfigs ?? [];
    } else {
      all = await ParentDataService.loadGradeManagementRecords();
      configs = await ParentDataService.loadGradeSubjectConfigs();
    }
    if (!mounted) return;

    // 🆕 가장 최근에 입력된 기록의 학교구분/학년/학기를 초기 선택값으로 자동 설정
    if (all.isNotEmpty) {
      final latest = all.reduce((a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b);
      _schoolLevel = latest.schoolLevel;
      _grade = latest.grade;
      _semester = latest.semester;
    }

    setState(() {
      _allRecords = all;
      _allConfigs = configs;
      _isLoading = false;
    });
    _showIntroPopupOnce();
    _loadSummary();
  }

  bool _notEnoughSubjects = false;

  Future<void> _loadSummary() async {
    // 🆕 [요청] 국/영/수/과 등 최소 4개 "과목"에 성적이 입력되어야 총평을 제공합니다
    final Set<String> subjectsWithScore = _filtered.where((r) => r.computedAverage != null).map((r) => r.subject).toSet();
    if (subjectsWithScore.length < 4) {
      setState(() {
        _summaryText = null;
        _notEnoughSubjects = true;
      });
      return;
    }
    final overall = GradeManagementService.computeOverallSummary(_filtered, _schoolLevel, _allConfigs);
    final double? avg = overall["average"] as double?;
    if (avg == null) {
      setState(() {
        _summaryText = null;
        _notEnoughSubjects = true;
      });
      return;
    }
    setState(() { _isSummaryLoading = true; _notEnoughSubjects = false; });
    // 🆕 [자녀 선택 UI + Firestore 연동] override 모드면 대시보드가 Firestore examRecords로
    // 계산해서 넘겨준 값을 그대로 쓰고, 아니면 기존처럼 이 기기의 로컬 값을 읽습니다.
    final double? achievementAvg = widget.overrideRecords != null
        ? widget.overrideAchievementAverage
        : await GradeManagementService.readAchievementAverageScore();
    // 🆕 [요청] 학생 화면과 동일한 personKey 규칙을 사용해 "동일한 문구"가 그대로 조회됩니다.
    final String personKey = 'student_${widget.childName}_$_schoolLevel$_grade$_semester';
    final GradeSummaryResult result = await GradeDiagnosisService.getOverallSummary(
      personKey: personKey, combinedAverage: avg, achievementAverage: achievementAvg,
    );
    if (!mounted) return;
    setState(() {
      // 🆕 [12개국어] 기본모드(KO/EN)는 한글+영문, 10개국어 선택 시 해당 언어 단독 표시
      _summaryText = result.display();
      _isSummaryLoading = false;
    });
  }

  List<GradeRecord> get _filtered => GradeManagementService.filterBy(
    _allRecords, schoolLevel: _schoolLevel, grade: _grade, semester: _semester,
  );

  List<String> get _visibleSubjects {
    final Set<String> set = {};
    for (final r in _filtered) {
      set.add(r.subject);
    }
    return set.toList();
  }

  GradeRecord? _cellRecord(String subject, String examType) {
    return _filtered
        .where((r) => r.subject == subject && r.examType == examType)
        .fold<GradeRecord?>(null, (prev, r) => (prev == null || r.updatedAt.isAfter(prev.updatedAt)) ? r : prev);
  }

  Widget _buildSelectorChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? widget.brandGolden : Colors.black38,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.brandGolden.withOpacity(isSelected ? 0.9 : 0.3), width: 1.3),
          ),
          child: Text(label, style: GoogleFonts.notoSansKr(color: isSelected ? Colors.black : Colors.white70, fontWeight: FontWeight.bold, fontSize: 12.5)),
        ),
      ),
    );
  }

  Widget _buildReadOnlyCell(String subject, String examType) {
    final rec = _cellRecord(subject, examType);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: rec != null ? Colors.black26 : Colors.black12,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.brandGolden.withOpacity(rec != null ? 0.5 : 0.18), width: 1.2),
      ),
      child: rec == null
          ? Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(t(kNoRecordCellMap), style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10.5))))
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              rec.computedAverage != null ? rec.computedAverage!.toStringAsFixed(1) : t(kNotComputedMap),
              style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              rec.computedGrade != null ? gradeLetterLabel(rec.computedGrade!) : t(kGradeNotComputedMap),
              style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 [요청] "종합" 한 줄이 아니라 중간고사/기말고사/모의고사 각 열 맨 아래에
  // 그 시험 종류만의 평균·등급을 따로 표시 (학생 화면과 동일)
  Widget _buildExamTypeSummaryCell(String examType) {
    final summary = GradeManagementService.computeExamTypeSummary(_filtered, examType, _schoolLevel, _allConfigs);
    final double? avg = summary["average"] as double?;
    final String? grade = summary["grade"] as String?;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.brandGolden.withOpacity(0.55), width: 1.3),
      ),
      child: avg == null
          ? Center(child: Text("-", style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12)))
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(avg.toStringAsFixed(1), style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(grade != null ? gradeLetterLabel(grade) : "-", style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // 🆕 [요청] 시험 종류(중간/기말/모의)마다 별도 그래프, X축·Y축 정렬 근본 수정,
  // Y축 라벨 옆 흰 점을 축 선 위 눈금으로 이동, 점수 밝은 흰색+볼드, 과목별 무지개 색상 순환
  // (학생 화면 _buildSingleExamChart와 동일 디자인으로 미러링)
  static const double _kChartBuffer = 18.0;
  static const double _kChartBarMax = 156.0; // 요청: Y축+막대 세로 20% 확대, 130→156 (학생 화면과 동일)
  static const double _kChartBottomPad = 38.0;

  List<Widget> _buildYAxisTickDots() {
    const List<int> values = [100, 80, 60, 40, 20, 0];
    return values.map((v) {
      final double y = _kChartBuffer + (100 - v) / 100.0 * _kChartBarMax;
      return Positioned(
        left: 36.5, top: y - 2,
        child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
      );
    }).toList();
  }

  Widget _buildSingleExamChart(String examType) {
    // 🆕 [요청] 성적표에 나열된 과목 순서 그대로 왼쪽부터 막대가 나오도록 정렬(학생 화면과 동일)
    final List<String> order = _visibleSubjects;
    final recs = _filtered.where((r) => r.examType == examType && r.computedAverage != null).toList()
      ..sort((a, b) {
        final int ia = order.indexOf(a.subject);
        final int ib = order.indexOf(b.subject);
        return (ia == -1 ? order.length : ia).compareTo(ib == -1 ? order.length : ib);
      });
    final List<String> yLabels = ["100", "80", "60", "40", "20", "0"];
    final double totalHeight = _kChartBuffer + _kChartBarMax + _kChartBottomPad;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.premiumCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.brandGolden.withOpacity(0.5), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(examTypeLabel(examType), style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          if (recs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text(chartEmptyText(examType), textAlign: TextAlign.center, style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12))),
            )
          else
            SizedBox(
              height: totalHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0, top: 0, bottom: 0, width: 34,
                    child: Column(
                      children: [
                        SizedBox(height: _kChartBuffer),
                        SizedBox(
                          height: _kChartBarMax,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: yLabels.map((l) => Text(l, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 9))).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 38, top: _kChartBuffer, bottom: _kChartBottomPad,
                    child: Container(width: 1.6, color: widget.brandGolden.withOpacity(0.6)),
                  ),
                  ..._buildYAxisTickDots(),
                  Positioned(
                    left: 38, right: 0, top: _kChartBuffer + _kChartBarMax,
                    child: Container(height: 1.8, color: widget.brandGolden.withOpacity(0.6)),
                  ),
                  Positioned(
                    left: 44, right: 0, top: 0, bottom: 0,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(recs.length, (idx) {
                          final r = recs[idx];
                          final double h = (r.computedAverage!.clamp(0, 100) / 100.0) * _kChartBarMax;
                          // 🆕 [요청] 색상은 성적표의 과목 고정 순서를 기준으로 배정 (학생 화면과 동일)
                          final int colorIdx = order.indexOf(r.subject);
                          final Color color = kSubjectRainbowColors[(colorIdx == -1 ? idx : colorIdx) % kSubjectRainbowColors.length];
                          return Container(
                            width: 46,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: _kChartBuffer + _kChartBarMax,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Positioned(
                                        bottom: 0,
                                        child: Container(height: h, width: 20, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))),
                                      ),
                                      Positioned(
                                        bottom: h + 4,
                                        child: Text(r.computedAverage!.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: 46,
                                  child: Text(
                                    subjectLabel(r.subject),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, height: 1.15),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExamTypeChart() {
    return Column(
      children: GradeManagementService.examTypes.map((et) => _buildSingleExamChart(et)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: widget.brandGolden));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t(kTitleEngMap), style: GoogleFonts.notoSerif(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)),
          const SizedBox(height: 2),
          Text("${widget.childName} ${bi(kScreenSubtitleMap)}", style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 4),
          Text(biLong(kScreenDescMap), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 18),

          if (_allRecords.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.premiumCardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: widget.brandGolden.withOpacity(0.5), width: 1.4),
              ),
              child: Text(
                biLong(kNoRecordsAtAllMap),
                style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 12.5, height: 1.5),
              ),
            )
          else ...[
            // 🆕 [요청] 학년(1학년/2학년/3학년 등) 칩이 다국어 표기로 길어져 오른쪽이 잘리는
            // 문제를 막기 위해 세 칩 줄 모두 가로 스크롤로 감쌌습니다.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: GradeManagementService.schoolLevels.map((lv) =>
                  _buildSelectorChip(schoolLevelLabel(lv), _schoolLevel == lv, () { setState(() => _schoolLevel = lv); _loadSummary(); })).toList()),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: GradeManagementService.gradeRange.map((g) {
                return _buildSelectorChip(gradeChipLabel(g), _grade == g, () { setState(() => _grade = g); _loadSummary(); });
              }).toList()),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [1, 2].map((s) =>
                  _buildSelectorChip(semesterChipLabel(s), _semester == s, () { setState(() => _semester = s); _loadSummary(); })).toList()),
            ),
            const SizedBox(height: 6),
            Text(
              reportCardTitle(_schoolLevel, _grade, _semester),
              style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (_visibleSubjects.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.premiumCardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: widget.brandGolden.withOpacity(0.5), width: 1.4),
                ),
                child: Text(
                  noRecordsAtScopeText(_schoolLevel, _grade, _semester),
                  style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 12.5),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.premiumCardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: widget.brandGolden.withOpacity(0.5), width: 1.4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🆕 [오버플로우 근본 수정] 학생 화면과 동일하게 Expanded 비율 레이아웃 적용
                    Row(
                      children: [
                        Expanded(flex: 2, child: Text(t(kSubjectHeaderMap), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(flex: 3, child: Center(child: Text(examTypeLabel("중간고사"), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)))),
                        Expanded(flex: 3, child: Center(child: Text(examTypeLabel("기말고사"), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)))),
                        Expanded(flex: 3, child: Center(child: Text(examTypeLabel("모의고사"), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)))),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 20),
                    ..._visibleSubjects.map((subject) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(flex: 2, child: Text(subjectLabel(subject), style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                            ...GradeManagementService.examTypes.map((et) => Expanded(flex: 3, child: _buildReadOnlyCell(subject, et))),
                          ],
                        ),
                      );
                    }),
                    const Divider(color: Colors.white10, height: 20),
                    // 🆕 [요청] 중간고사/기말고사/모의고사 각 열 맨 아래에 그 시험 종류만의 평균·등급 표시
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 2, child: Text(t(kAvgGradeHeaderMap), style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontSize: 12, fontWeight: FontWeight.bold))),
                        ...GradeManagementService.examTypes.map((et) => Expanded(flex: 3, child: _buildExamTypeSummaryCell(et))),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            Text(t(kChartSectionTitleMap), style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            _buildExamTypeChart(),
            const SizedBox(height: 24),

            Text(t(kSummaryTitleMap), style: GoogleFonts.notoSansKr(color: widget.brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.premiumCardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: widget.brandGolden.withOpacity(0.5), width: 1.4),
              ),
              child: _isSummaryLoading
                  ? Center(child: Padding(padding: const EdgeInsets.all(12), child: CircularProgressIndicator(color: widget.brandGolden)))
                  : Text(
                // 🆕 [요청] 4개 과목 미만이면 흐릿한 안내 문구, 4개 이상이면 실제 총평 표시
                _summaryText ?? (_notEnoughSubjects ? t(kMinSubjectsNeededMap) : t(kSummaryPlaceholderMap)),
                style: GoogleFonts.notoSansKr(
                  color: _summaryText != null ? Colors.white : Colors.white38,
                  fontSize: 13, height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              t(kRankDisclaimerMap),
              style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10.5, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
