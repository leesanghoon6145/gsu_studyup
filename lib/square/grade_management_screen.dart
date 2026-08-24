import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/grade_management_service.dart';
import '../services/grade_diagnosis_service.dart';
import '../services/user_profile_service.dart';
import '../global_lang.dart';

// 🆕 [요청] 학생 화면도 안내 팝업/종합 총평에 영문이 함께 보이도록 최소 다국어 처리 적용.
// (전체 화면 다국어화는 범위 밖이며, 이번에 신고된 두 항목만 우선 반영했습니다.)
String _bi(String ko, String en) => DkeLang.isForeignSelected ? en : "$ko\n$en";

const String kStudentIntroPopupEn =
    "Grade Management automatically calculates your report using the written scores, performance scores, subject unit counts, and total student count you entered.\n"
    "Please note there may be discrepancies with the school's official report card.\n"
    "For the most accurate analysis, please enter scores and headcounts as precisely as possible.";

/// ============================================================================
/// [GKE StudyUp] 성적 관리 화면 - 학생용
/// - 기존 "나의 성적 기록"(member_achievement_screen.dart)과는 완전히 별도의
///   독립 기능입니다. gke_exam_records 키는 절대 건드리지 않고 참고용으로만 읽습니다.
/// ============================================================================
class GradeManagementScreen extends StatefulWidget {
  const GradeManagementScreen({super.key});

  @override
  State<GradeManagementScreen> createState() => _GradeManagementScreenState();
}

class _ThemeColors {
  static const Color brandGolden = Color(0xFFE5C158);
  static const Color luxuryDarkBg = Color(0xFF030712);
  static const Color premiumCardBg = Color(0xFF0D1527);
}

// 🆕 [요청] 과목별 막대 색상 순환: 빨/파(진한 파랑)/주/초/노/남/보 반복
const List<Color> kSubjectRainbowColors = [
  Color(0xFFFF3B30), // 빨
  Color(0xFF0A4FE0), // 파 (진한 파랑)
  Color(0xFFFF9500), // 주
  Color(0xFF34C759), // 초
  Color(0xFFFFCC00), // 노
  Color(0xFF1E3A8A), // 남
  Color(0xFFAF52DE), // 보
];

class _GradeManagementScreenState extends State<GradeManagementScreen> {
  String _schoolLevel = "중등부";
  int _grade = 1;
  int _semester = 1;

  bool _isLoading = true;
  List<GradeRecord> _allRecords = [];
  List<SubjectConfig> _allConfigs = [];
  Set<String> _hiddenSubjects = {};
  final List<String> _customSubjects = [];

  final TextEditingController _newSubjectController = TextEditingController();

  String? _summaryText;
  bool _isSummaryLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showIntroPopupOnce());
  }

  @override
  void dispose() {
    _newSubjectController.dispose();
    super.dispose();
  }

  void _showIntroPopupOnce() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _ThemeColors.premiumCardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _ThemeColors.brandGolden.withOpacity(0.55), width: 1.6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("성적관리 안내", style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Text(_bi(GradeManagementService.studentIntroPopupText, kStudentIntroPopupEn), style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13, height: 1.6)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _ThemeColors.brandGolden),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("확인", style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadAll() async {
    final records = await GradeManagementService.loadAll();
    final configs = await GradeManagementService.loadAllConfigs();
    final hidden = await GradeManagementService.loadHiddenSubjects();
    if (!mounted) return;
    setState(() {
      _allRecords = records;
      _allConfigs = configs;
      _hiddenSubjects = hidden;
      _isLoading = false;
    });
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final filtered = _currentFiltered;
    final overall = GradeManagementService.computeOverallSummary(filtered, _schoolLevel, _allConfigs);
    final double? avg = overall["average"] as double?;
    if (avg == null) {
      setState(() => _summaryText = null);
      return;
    }
    setState(() => _isSummaryLoading = true);
    final String? name = await DkeUserProfile.getRealName();
    final double? achievementAvg = await GradeManagementService.readAchievementAverageScore();
    final String personKey = 'student_${name ?? "unknown"}_$_schoolLevel$_grade$_semester';
    final GradeSummaryResult result = await GradeDiagnosisService.getOverallSummary(
      personKey: personKey, combinedAverage: avg, achievementAverage: achievementAvg,
    );
    if (!mounted) return;
    setState(() {
      // 🆕 [요청] 종합 총평에 영문 병기 (기본모드: 한글+영문 / 10개국어 선택 시: 영문 대체)
      _summaryText = DkeLang.isForeignSelected ? result.en : "${result.ko}\n\n${result.en}";
      _isSummaryLoading = false;
    });
  }

  List<String> get _baseSubjects => _schoolLevel == "중등부"
      ? GradeManagementService.middleSchoolSubjects
      : GradeManagementService.highSchoolSubjects;

  List<String> get _visibleSubjects {
    final Set<String> set = {..._baseSubjects, ..._customSubjects};
    for (final r in _currentFiltered) {
      set.add(r.subject);
    }
    final hiddenNow = _hiddenSubjects;
    return set.where((s) => !hiddenNow.contains(GradeManagementService.hiddenKey(_schoolLevel, _grade, _semester, s))).toList();
  }

  List<GradeRecord> get _currentFiltered => GradeManagementService.filterBy(
    _allRecords, schoolLevel: _schoolLevel, grade: _grade, semester: _semester,
  );

  SubjectConfig? _configFor(String subject) => GradeManagementService.findConfig(
    _allConfigs, schoolLevel: _schoolLevel, grade: _grade, semester: _semester, subject: subject,
  );

  void _addCustomSubject() {
    final text = _newSubjectController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      if (!_customSubjects.contains(text)) _customSubjects.add(text);
      _newSubjectController.clear();
    });
  }

  Future<void> _showSubjectOptionsSheet(String subject) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: _ThemeColors.premiumCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: _ThemeColors.brandGolden.withOpacity(0.4), width: 1.2),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(subject, style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                ListTile(
                  leading: const Icon(Icons.settings_rounded, color: _ThemeColors.brandGolden),
                  title: Text("과목 설정 (지필·수행 반영비율 / 전체학생수 / 단위수)", style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13)),
                  onTap: () { Navigator.pop(ctx); _showSubjectConfigDialog(subject); },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: Colors.white70),
                  title: Text("과목명 수정", style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13)),
                  onTap: () { Navigator.pop(ctx); _showRenameDialog(subject); },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  title: Text("과목 삭제 (이 학년/학기 화면에서만 제외)", style: GoogleFonts.notoSansKr(color: Colors.redAccent, fontSize: 13)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await GradeManagementService.hideSubject(_schoolLevel, _grade, _semester, subject);
                    await _loadAll();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRenameDialog(String subject) async {
    final TextEditingController ctrl = TextEditingController(text: subject);
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _ThemeColors.premiumCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _ThemeColors.brandGolden.withOpacity(0.5), width: 1.5)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("과목명 수정", style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true, fillColor: Colors.black26,
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white12), borderRadius: BorderRadius.circular(6)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: _ThemeColors.brandGolden), borderRadius: BorderRadius.circular(6)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text("취소", style: GoogleFonts.notoSansKr(color: Colors.white54)))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _ThemeColors.brandGolden),
                      onPressed: () async {
                        final newName = ctrl.text.trim();
                        if (newName.isEmpty) return;
                        await GradeManagementService.renameSubject(
                          schoolLevel: _schoolLevel, grade: _grade, semester: _semester, oldName: subject, newName: newName,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _loadAll();
                      },
                      child: Text("저장", style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSubjectConfigDialog(String subject) async {
    final existing = _configFor(subject);
    final TextEditingController writtenCtrl = TextEditingController(text: (existing?.writtenRatio ?? 70).toStringAsFixed(0));
    final TextEditingController perfCtrl = TextEditingController(text: (existing?.performanceRatio ?? 30).toStringAsFixed(0));
    final TextEditingController totalCtrl = TextEditingController(text: existing?.totalStudents?.toString() ?? "");
    final TextEditingController unitCtrl = TextEditingController(text: (existing?.unitHours ?? 3).toString());

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setPopupState) {
          final int? w = int.tryParse(writtenCtrl.text);
          final int? p = int.tryParse(perfCtrl.text);
          final bool ratioValid = w != null && p != null && (w + p) == 100;

          return Dialog(
            backgroundColor: _ThemeColors.premiumCardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _ThemeColors.brandGolden.withOpacity(0.55), width: 1.6)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$subject 과목 설정 (연 1회)", style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text("설정을 저장하면 이 과목의 기존 점수도 자동으로 다시 계산됩니다.", style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10.5)),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _buildLabeledField("지필 반영비율(%)", writtenCtrl, onChanged: () => setPopupState(() {})),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildLabeledField("수행 반영비율(%)", perfCtrl, onChanged: () => setPopupState(() {})),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ratioValid ? "합계 100% ✓" : "※ 지필+수행 반영비율의 합은 100이어야 합니다.",
                      style: GoogleFonts.notoSansKr(color: ratioValid ? Colors.greenAccent : Colors.redAccent, fontSize: 11),
                    ),
                    const SizedBox(height: 14),
                    _buildLabeledField("학년 전체 인원 (선택, 고등부 등급 계산용)", totalCtrl),
                    const SizedBox(height: 4),
                    Text(GradeManagementService.rankDisclaimerText, style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10.5, height: 1.4)),
                    const SizedBox(height: 14),
                    _buildLabeledField("단위수 (주당 시수, 예: 주4시간=4)", unitCtrl),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: ratioValid ? _ThemeColors.brandGolden : Colors.white24),
                        onPressed: !ratioValid ? null : () async {
                          final config = SubjectConfig(
                            schoolLevel: _schoolLevel, grade: _grade, semester: _semester, subject: subject,
                            writtenRatio: w!.toDouble(), performanceRatio: p!.toDouble(),
                            totalStudents: int.tryParse(totalCtrl.text), unitHours: int.tryParse(unitCtrl.text) ?? 3,
                            updatedAt: DateTime.now(),
                          );
                          await GradeManagementService.saveConfig(config);
                          if (ctx.mounted) Navigator.pop(ctx);
                          await _loadAll();
                        },
                        child: Text("저장", style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildLabeledField(String label, TextEditingController ctrl, {VoidCallback? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          onChanged: (_) => onChanged?.call(),
          decoration: InputDecoration(
            filled: true, fillColor: Colors.black26,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white12), borderRadius: BorderRadius.circular(6)),
            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: _ThemeColors.brandGolden), borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ],
    );
  }

  Future<void> _showEntryDialog({required String subject, required String examType, GradeRecord? existing}) async {
    final config = _configFor(subject);
    if (config == null) {
      final bool? goSetup = await showDialog<bool>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: _ThemeColors.premiumCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _ThemeColors.brandGolden.withOpacity(0.55), width: 1.6)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("과목 설정이 필요합니다", style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                Text("$subject 과목은 아직 지필·수행 반영비율이 설정되지 않았습니다. 먼저 과목 설정을 진행해 주세요.", style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12.5, height: 1.5)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("취소", style: GoogleFonts.notoSansKr(color: Colors.white54)))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _ThemeColors.brandGolden),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text("설정하러 가기", style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      if (goSetup == true) await _showSubjectConfigDialog(subject);
      return;
    }

    final bool isMock = examType == "모의고사";
    final TextEditingController writtenCtrl = TextEditingController(text: existing?.writtenScore?.toStringAsFixed(0) ?? "");
    final TextEditingController perfCtrl = TextEditingController(text: existing?.performanceScore?.toStringAsFixed(0) ?? "");
    final TextEditingController rankCtrl = TextEditingController(text: existing?.personalRank?.toString() ?? "");

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setPopupState) {
          final double? w = double.tryParse(writtenCtrl.text);
          final double? p = isMock ? null : double.tryParse(perfCtrl.text);
          final double? previewAvg = GradeManagementService.computeAverage(examType: examType, writtenScore: w, performanceScore: p, config: config);
          final int? previewRank = int.tryParse(rankCtrl.text);
          final String? previewGrade = GradeManagementService.computeGrade(
            schoolLevel: _schoolLevel, average: previewAvg, personalRank: previewRank, totalStudents: config.totalStudents,
          );

          return Dialog(
            backgroundColor: _ThemeColors.premiumCardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _ThemeColors.brandGolden.withOpacity(0.55), width: 1.6)),
            child: Container(
              width: MediaQuery.of(ctx).size.width * 0.9,
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text("$subject · $examType", style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 16))),
                        IconButton(icon: const Icon(Icons.close, color: Colors.white60, size: 20), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 16),

                    _buildLabeledField("지필점수", writtenCtrl, onChanged: () => setPopupState(() {})),
                    const SizedBox(height: 12),
                    if (!isMock) ...[
                      _buildLabeledField("수행점수", perfCtrl, onChanged: () => setPopupState(() {})),
                      const SizedBox(height: 12),
                    ] else ...[
                      Text("※ 모의고사는 지필 100%로 계산됩니다 (수행 항목 없음).", style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 11)),
                      const SizedBox(height: 12),
                    ],

                    if (_schoolLevel == "고등부") ...[
                      _buildLabeledField("개인 석차 (선택)", rankCtrl, onChanged: () => setPopupState(() {})),
                      const SizedBox(height: 4),
                      Text(GradeManagementService.rankDisclaimerText, style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10.5, height: 1.4)),
                      const SizedBox(height: 12),
                    ],

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            previewAvg != null ? "→ 반영점수: ${previewAvg.toStringAsFixed(1)}점" : "→ 반영점수 계산 대기 중",
                            style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            previewGrade != null ? "→ 자동계산등급: ${GradeManagementService.formatGradeLabel(previewGrade)}" : "→ 등급 계산 대기 중",
                            style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        if (existing != null) ...[
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                              onPressed: () async {
                                await GradeManagementService.deleteRecord(existing.id);
                                if (ctx.mounted) Navigator.pop(ctx);
                                await _loadAll();
                              },
                              child: Text("삭제", style: GoogleFonts.notoSansKr(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: _ThemeColors.brandGolden, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            onPressed: () async {
                              if (w == null) {
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('지필점수를 입력해 주세요.', style: GoogleFonts.notoSansKr())));
                                return;
                              }
                              if (!isMock && p == null) {
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('수행점수를 입력해 주세요.', style: GoogleFonts.notoSansKr())));
                                return;
                              }
                              await GradeManagementService.addOrUpdateRecord(
                                existingId: existing?.id,
                                schoolLevel: _schoolLevel, grade: _grade, semester: _semester,
                                examType: examType, subject: subject,
                                writtenScore: w, performanceScore: isMock ? null : p,
                                personalRank: previewRank, config: config,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              await _loadAll();
                            },
                            child: Text("저장", style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildCell(String subject, String examType) {
    final GradeRecord? rec = _currentFiltered
        .where((r) => r.subject == subject && r.examType == examType)
        .fold<GradeRecord?>(null, (prev, r) => (prev == null || r.updatedAt.isAfter(prev.updatedAt)) ? r : prev);

    return InkWell(
      onTap: () => _showEntryDialog(subject: subject, examType: examType, existing: rec),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: rec != null ? Colors.black26 : Colors.black12,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _ThemeColors.brandGolden.withOpacity(rec != null ? 0.5 : 0.18), width: 1.2),
        ),
        child: rec == null
            ? Center(child: Text("입력", style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12)))
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                rec.computedAverage != null ? "${rec.computedAverage!.toStringAsFixed(1)}점" : "미산출",
                style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                rec.computedGrade != null ? GradeManagementService.formatGradeLabel(rec.computedGrade!) : "등급 미산출",
                style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 [요청] "종합" 한 줄이 아니라 중간고사/기말고사/모의고사 각 열 맨 아래에
  // 그 시험 종류만의 평균·등급을 따로 표시
  Widget _buildExamTypeSummaryCell(String examType) {
    final summary = GradeManagementService.computeExamTypeSummary(_currentFiltered, examType, _schoolLevel, _allConfigs);
    final double? avg = summary["average"] as double?;
    final String? grade = summary["grade"] as String?;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.55), width: 1.3),
      ),
      child: avg == null
          ? Center(child: Text("-", style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12)))
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text("${avg.toStringAsFixed(1)}점", style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(grade != null ? GradeManagementService.formatGradeLabel(grade) : "-", style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // 🆕 [요청] 시험 종류(중간/기말/모의)마다 별도 그래프, X축·Y축 정렬 근본 수정,
  // Y축 라벨 옆 흰 점을 축 선 위 눈금으로 이동, 점수 밝은 흰색+볼드, 과목별 무지개 색상 순환
  static const double _kChartBuffer = 18.0;   // 점수 숫자가 막대 위로 넘칠 공간(막대 높이 계산에는 포함 안 됨)
  static const double _kChartBarMax = 156.0;  // 100점 = 이 높이 (요청: Y축+막대 세로 20% 확대, 130→156)
  static const double _kChartBottomPad = 38.0; // X축 아래 과목명 표시 공간

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
    // 🆕 [요청] 알파벳/가나다 정렬이 아니라, 위쪽 성적표에 나열된 과목 순서 그대로
    // 왼쪽부터 막대가 나오도록 정렬 (3개 그래프를 나란히 비교하기 위함)
    final List<String> order = _visibleSubjects;
    final recs = _currentFiltered.where((r) => r.examType == examType && r.computedAverage != null).toList()
      ..sort((a, b) {
        final int ia = order.indexOf(a.subject);
        final int ib = order.indexOf(b.subject);
        return (ia == -1 ? order.length : ia).compareTo(ib == -1 ? order.length : ib);
      });
    final List<String> yLabels = ["100점", "80점", "60점", "40점", "20점", "0점"];
    final double totalHeight = _kChartBuffer + _kChartBarMax + _kChartBottomPad;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ThemeColors.premiumCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.5), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(examType, style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          if (recs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text("$examType 점수가 입력되면 그래프가 표시됩니다.", style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 12))),
            )
          else
            SizedBox(
              height: totalHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Y축 라벨 (흰 점 없이 텍스트만 — 점은 아래에서 축 선 위에 별도로 찍음)
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
                  // Y축 세로선
                  Positioned(
                    left: 38, top: _kChartBuffer, bottom: _kChartBottomPad,
                    child: Container(width: 1.6, color: _ThemeColors.brandGolden.withOpacity(0.6)),
                  ),
                  // 🆕 [요청] Y축 라벨 옆 흰 점 대신, 축 선 위에 눈금 점으로 표시
                  ..._buildYAxisTickDots(),
                  // X축 가로선 — 막대 하단(0점 기준선)과 정확히 일치
                  Positioned(
                    left: 38, right: 0, top: _kChartBuffer + _kChartBarMax,
                    child: Container(height: 1.8, color: _ThemeColors.brandGolden.withOpacity(0.6)),
                  ),
                  // 막대 + 과목명
                  Positioned(
                    left: 44, right: 0, top: 0, bottom: 0,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(recs.length, (idx) {
                          final r = recs[idx];
                          final double h = (r.computedAverage!.clamp(0, 100) / 100.0) * _kChartBarMax;
                          // 🆕 [요청] 색상은 그래프 내 나열 순서가 아니라, 성적표의 과목 고정 순서를 기준으로
                          // 배정 — 국어=빨강처럼 과목마다 3개 그래프(중간/기말/모의) 전부 동일한 색을 유지
                          final int colorIdx = order.indexOf(r.subject);
                          final Color color = kSubjectRainbowColors[(colorIdx == -1 ? idx : colorIdx) % kSubjectRainbowColors.length];
                          return Container(
                            width: 46,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 🆕 막대 영역은 정확히 _kChartBarMax(0~100점) 높이만 차지하고,
                                // 점수 숫자는 그 위(버퍼 영역)에 겹쳐서 그려 막대 높이 계산에 영향을 주지 않음
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
                                    r.subject,
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
    return Scaffold(
      backgroundColor: _ThemeColors.luxuryDarkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("GRADE MANAGEMENT", style: GoogleFonts.notoSerif(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)),
            const SizedBox(height: 1),
            Text("성적 관리", style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5C158)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("학교 구분", style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: GradeManagementService.schoolLevels.map((lv) {
                final bool isSel = _schoolLevel == lv;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () { setState(() { _schoolLevel = lv; _grade = 1; }); _loadSummary(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel ? _ThemeColors.brandGolden : Colors.black38,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _ThemeColors.brandGolden.withOpacity(isSel ? 0.9 : 0.3), width: 1.3),
                      ),
                      child: Text(lv, style: GoogleFonts.notoSansKr(color: isSel ? Colors.black : Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            Text("학년", style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: GradeManagementService.gradeRange.map((g) {
                  final bool isSel = _grade == g;
                  final String label = "$g학년";
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () { setState(() => _grade = g); _loadSummary(); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSel ? _ThemeColors.brandGolden : Colors.black38,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _ThemeColors.brandGolden.withOpacity(isSel ? 0.9 : 0.3), width: 1.3),
                        ),
                        child: Text(label, style: GoogleFonts.notoSansKr(color: isSel ? Colors.black : Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            Text("학기", style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [1, 2].map((s) {
                final bool isSel = _semester == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () { setState(() => _semester = s); _loadSummary(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSel ? _ThemeColors.brandGolden : Colors.black38,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _ThemeColors.brandGolden.withOpacity(isSel ? 0.9 : 0.3), width: 1.3),
                      ),
                      child: Text("$s학기", style: GoogleFonts.notoSansKr(color: isSel ? Colors.black : Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            Text(
              "MIDDLE/HIGH · REPORT CARD",
              style: GoogleFonts.notoSerif(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.8),
            ),
            Text(
              "$_schoolLevel·$_grade학년·$_semester학기 성적표",
              style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _ThemeColors.premiumCardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.5), width: 1.4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🆕 [오버플로우 근본 수정] 가로 스크롤에 의존하지 않고, 화면 폭에 맞춰
                  // 자동으로 줄어드는 Expanded 비율 레이아웃으로 전환 (과목:2, 시험종류 각 3)
                  Row(
                    children: [
                      Expanded(flex: 2, child: Text("과목", style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
                      Expanded(flex: 3, child: Center(child: Text("중간고사", style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)))),
                      Expanded(flex: 3, child: Center(child: Text("기말고사", style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)))),
                      Expanded(flex: 3, child: Center(child: Text("모의고사", style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)))),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 20),
                  ..._visibleSubjects.map((subject) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onLongPress: () => _showSubjectOptionsSheet(subject),
                              onTap: () => _showSubjectOptionsSheet(subject),
                              child: Row(
                                children: [
                                  Flexible(child: Text(subject, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                  const Icon(Icons.more_vert_rounded, color: Colors.white24, size: 14),
                                ],
                              ),
                            ),
                          ),
                          ...GradeManagementService.examTypes.map((et) => Expanded(flex: 3, child: _buildCell(subject, et))),
                        ],
                      ),
                    );
                  }),
                  const Divider(color: Colors.white10, height: 20),
                  // 🆕 [요청] "종합" 한 줄이 아니라, 중간고사/기말고사/모의고사 각 열 맨 아래에
                  // 그 시험 종류만의 평균·등급을 개별 표시
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 2, child: Text("평균/등급", style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontSize: 12, fontWeight: FontWeight.bold))),
                      ...GradeManagementService.examTypes.map((et) => Expanded(flex: 3, child: _buildExamTypeSummaryCell(et))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newSubjectController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "새 과목 이름 (예: 제2외국어)",
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      filled: true, fillColor: _ThemeColors.premiumCardBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _ThemeColors.brandGolden.withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: _ThemeColors.brandGolden), borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _ThemeColors.brandGolden),
                  onPressed: _addCustomSubject,
                  child: Text("과목 추가", style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text("과목명 옆 ⋮ 아이콘을 누르면 설정·수정·삭제할 수 있습니다.", style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10.5)),
            const SizedBox(height: 24),

            Text("시험 종류별 그래프", style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            _buildExamTypeChart(),
            const SizedBox(height: 24),

            Text("종합 총평", style: GoogleFonts.notoSansKr(color: _ThemeColors.brandGolden, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _ThemeColors.premiumCardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _ThemeColors.brandGolden.withOpacity(0.5), width: 1.4),
              ),
              child: _isSummaryLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: _ThemeColors.brandGolden)))
                  : Text(
                _summaryText ?? _bi("지필·수행 점수가 입력되면 지필+수행 종합 결과를 바탕으로 총평이 표시됩니다.", "Once written and performance scores are entered, a summary based on the combined result will appear here."),
                style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
