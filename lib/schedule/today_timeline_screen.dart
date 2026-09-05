// ============================================================================
// [일반 플래너] TodayTimelineScreen
// 오늘의 시간 블록을 시간순으로 보여줍니다. [시작] 버튼으로 실행을 시작하고
// [완료] 버튼으로 종료하면 실제 시작/종료 시간이 자동 기록되어 계획 시간과의
// 차이가 즉시 계산됩니다.
//
// [자동 기본 틀] 화면을 처음 열었을 때 아무 항목도 없으면, 버튼을 누를 필요
// 없이 자동으로 05:00부터 24:00까지 1시간 간격(19칸)으로 채워집니다.
// [지금 이 시간] 현재 시각이 포함된 계획 칸에 반짝이는 NOW 표시가 붙어서
// 지금 뭘 해야 할지 한눈에 보입니다.
// [지나간 시간] 이미 지나갔고 아직 시작 안 한(손 안 댄) 칸은 회색으로 흐리게
// 표시됩니다 - 기능(수정/삭제/시작)은 동일하게 전부 됩니다, 보여지는 것만 다름.
// [기본 틀 재설정] 앱바의 격자 아이콘을 누르면 언제든 05:00~24:00 기본 틀로
// 다시 초기화할 수 있습니다 (이미 항목이 있으면 확인 팝업이 먼저 뜸).
//
// ✅ [2026-09-04 추가] 운동(EXERCISE) 연동. 오늘 운동 기록이 있으면 상단
// "현재 시간" 카드 아래에 읽기 전용 요약 카드를 추가로 보여줌 (TimelineBlock
// 데이터 구조는 건드리지 않는 순수 정보성 카드).
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'timeline_data_service.dart';
import 'routine_screen.dart';
import 'bilingual_text.dart';
import 'completion_survey_data.dart'; // 🆕 [AI 분석용 데이터 수집] 완료 설문 질문지
import 'exercise_data_service.dart'; // 🆕 [운동 연동]
import 'exercise_models.dart'; // 🆕 [운동 연동]

class TodayTimelineScreen extends StatefulWidget {
  const TodayTimelineScreen({super.key});

  @override
  State<TodayTimelineScreen> createState() => _TodayTimelineScreenState();
}

class _TodayTimelineScreenState extends State<TodayTimelineScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  List<TimelineBlock> _blocks = [];
  List<ExerciseRecord> _todayExercises = []; // 🆕 [운동 연동]
  bool _isLoading = true;

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String get _nowHHmm {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  int get _nowMinutesSinceMidnight {
    final now = DateTime.now();
    return now.hour * 60 + now.minute;
  }

  int _hhmmToMinutes(String hhmm) {
    if (!hhmm.contains(':')) return -1;
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Timer? _autoCheckTimer; // 🆕 [자동 실행] 화면이 열려있는 동안 30초마다 시각을 확인해서 자동으로 상태를 갱신함

  @override
  void initState() {
    super.initState();
    _loadTimeline();
    // 🆕 [자동 실행] 화면을 계속 보고 있으면 30초마다 자동으로 다시 확인해서,
    // 계획된 시작 시각이 되면 사용자가 버튼을 누르지 않아도 자동으로 "실행중"으로 바뀜.
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadTimeline();
    });
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  // 🆕 [자동 실행 판정] 아직 "계획" 상태인 항목 중, 지금 시각이 계획 구간 안에
  // 들어온 것이 있으면 자동으로 "실행중" 상태로 바꿔줌 (시작 버튼 없이 자동).
  // 실제 시작 시각은 계획된 시작 시각으로 간주함(정확한 순간 감지는 화면이
  // 열려있을 때만 가능하므로, 그 사이 시간은 계획대로 시작한 것으로 처리).
  Future<void> _autoStartDueBlocks(List<TimelineBlock> blocks) async {
    final int nowMin = _nowMinutesSinceMidnight;
    for (final b in blocks) {
      if (b.status != 'planned') continue;
      final int startMin = _hhmmToMinutes(b.plannedStart);
      final int endMinRaw = _hhmmToMinutes(b.plannedEnd);
      final int endMin = endMinRaw <= startMin ? endMinRaw + 24 * 60 : endMinRaw;
      if (startMin >= 0 && nowMin >= startMin && nowMin < endMin) {
        b.actualStart = b.plannedStart;
        b.status = 'running';
        await TimelineDataService.updateBlock(b);
      }
    }
  }

  // 🆕 [운동 연동] 오늘의 운동 기록 조회 (TimelineBlock과는 별개 데이터 소스)
  Future<List<ExerciseRecord>> _loadTodayExerciseRecords() async {
    final all = await ExerciseDataService.instance.getAllRecords();
    final now = DateTime.now();
    return all.where((r) => r.date.year == now.year && r.date.month == now.month && r.date.day == now.day).toList();
  }

  Future<void> _loadTimeline() async {
    setState(() => _isLoading = true);
    final blocks = await TimelineDataService.loadForDate(_todayKey);
    final todayExercises = await _loadTodayExerciseRecords(); // 🆕 [운동 연동]

    // 🆕 [요청 반영] 오늘 항목이 하나도 없으면, 무조건 새 기본틀(자유시간)로
    // 초기화하는 대신 - 먼저 "어제" 시간표가 있는지 확인해서 그대로 이어받음.
    // 사용자가 직접 수정하지 않는 한, 어제 만들어둔 나만의 시간표가 매일 계속
    // 이어지는 게 목표. 어제도 기록이 없을 때(정말 처음 쓰는 경우)만 기본틀 생성.
    if (blocks.isEmpty) {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final String yesterdayKey = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      final yesterdayBlocks = await TimelineDataService.loadForDate(yesterdayKey);

      if (yesterdayBlocks.isNotEmpty) {
        // 🆕 [전날 이어받기] 어제 만들어둔 제목/시간/분류를 그대로 복사해서 오늘 것으로 만듦.
        // 실행 상태(시작/완료/설문 답변)는 새로 시작하는 오늘 것이므로 초기화함.
        for (final yb in yesterdayBlocks) {
          final carriedOver = TimelineBlock(
            id: '${DateTime.now().microsecondsSinceEpoch}_${yb.id}',
            date: _todayKey,
            plannedStart: yb.plannedStart,
            plannedEnd: yb.plannedEnd,
            title: yb.title,
            category: yb.category,
            isRoutine: yb.isRoutine,
          );
          await TimelineDataService.addBlock(carriedOver);
        }
        final carried = await TimelineDataService.loadForDate(_todayKey);
        await _autoStartDueBlocks(carried);
        if (!mounted) return;
        setState(() {
          _blocks = carried;
          _todayExercises = todayExercises; // 🆕 [운동 연동]
          _isLoading = false;
        });
        return;
      }

      // 어제도 기록이 없는 경우(정말 처음 사용하는 경우)에만 기본 틀 생성
      await _generateDefaultSlots();
      final refilled = await TimelineDataService.loadForDate(_todayKey);
      await _autoStartDueBlocks(refilled);
      if (!mounted) return;
      setState(() {
        _blocks = refilled;
        _todayExercises = todayExercises; // 🆕 [운동 연동]
        _isLoading = false;
      });
      if (mounted) {
        biSnack(context, 'Default timeline created - tap any slot to customize', '기본 타임라인이 자동으로 만들어졌습니다 - 칸을 눌러 자유롭게 바꿔보세요');
      }
      return;
    }

    await _autoStartDueBlocks(blocks);
    if (!mounted) return;
    setState(() {
      _blocks = blocks;
      _todayExercises = todayExercises; // 🆕 [운동 연동]
      _isLoading = false;
    });
  }

  Future<void> _generateDefaultSlots() async {
    for (int hour = 5; hour < 24; hour++) {
      final block = TimelineBlock(
        id: '${DateTime.now().microsecondsSinceEpoch}_$hour',
        date: _todayKey,
        plannedStart: '${hour.toString().padLeft(2, '0')}:00',
        plannedEnd: '${(hour + 1).toString().padLeft(2, '0')}:00',
        title: 'Free Time (자유 시간)',
        category: '일반',
      );
      await TimelineDataService.addBlock(block);
    }
  }

  // ---------------------------------------------------------------------
  // 기본 틀 재설정 (앱바 버튼으로 언제든 실행 - 기존 항목 있으면 확인)
  // ---------------------------------------------------------------------

  Future<void> _createDefaultTimeline() async {
    if (_blocks.isNotEmpty) {
      final bool confirmed = await _showResetConfirmDialog();
      if (!confirmed) return;
      for (final b in _blocks) {
        await TimelineDataService.deleteBlock(b.id);
      }
    }

    await _generateDefaultSlots();
    final refilled = await TimelineDataService.loadForDate(_todayKey);
    if (!mounted) return;
    setState(() => _blocks = refilled);
    await _showGuideDialog();
  }

  Future<bool> _showResetConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: LuxuryDialogFrame(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                luxuryDialogHeader(icon: Icons.restore_rounded, en: 'RESET TIMELINE', ko: '타임라인 초기화'),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s timeline items will all be deleted and replaced with a fresh 05:00 to 24:00 template. This cannot be undone.',
                        style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 12, height: 1.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '오늘의 타임라인 항목이 모두 삭제되고, 05:00부터 24:00까지 새 기본 틀로 만들어집니다. 되돌릴 수 없습니다.',
                        style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: appLanguage.isDefault
                            ? Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('Cancel', style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('취소', style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                        ])
                            : Text(tButton('Cancel'), style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 4),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: appLanguage.isDefault
                            ? Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('Reset', style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('초기화', style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ])
                            : Text(tButton('Reset'), style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  Future<void> _showGuideDialog() async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: LuxuryDialogFrame(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                luxuryDialogHeader(icon: Icons.auto_awesome_rounded, en: 'TIMELINE READY', ko: '타임라인이 준비됐어요'),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _brandGolden.withOpacity(0.3))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Slots were created from 05:00 to 24:00, one per hour. Tap the pencil icon on any slot to rename it, change the time, or delete it. Make it your own personal timeline. If you get tired of it, tap the grid icon above anytime to reset back to this template.',
                        style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 12, height: 1.6),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '05시부터 24시까지 한 시간 간격으로 칸이 만들어졌습니다. 각 칸의 연필 아이콘을 눌러 이름이나 시간을 바꾸거나 삭제해서 나만의 개인 타임라인으로 자유롭게 사용하세요. 지겨워지면 위쪽 격자 아이콘을 눌러 언제든 다시 기본 틀로 초기화할 수 있습니다.',
                        style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _brandGolden, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 6, shadowColor: _brandGolden.withOpacity(0.5)),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: appLanguage.isDefault
                        ? Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('Got it', style: GoogleFonts.gowunBatang(color: _pageBg, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('확인했어요', style: GoogleFonts.notoSansKr(color: _pageBg, fontSize: 12, fontWeight: FontWeight.bold)),
                    ])
                        : Text(tButton('Got it'), style: GoogleFonts.notoSansKr(color: _pageBg, fontSize: 12.5, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // 항목 추가
  // ---------------------------------------------------------------------

  Future<void> _showAddBlockDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController categoryController = TextEditingController();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(hour: (TimeOfDay.now().hour + 1) % 24, minute: TimeOfDay.now().minute);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 22),
            child: LuxuryDialogFrame(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    luxuryDialogHeader(icon: Icons.timer_outlined, en: 'ADD TIMELINE', ko: '타임라인 추가'),

                    _buildField(icon: Icons.title_rounded, controller: titleController, hintEn: 'Title', hintKo: 'e.g. exercise'),
                    const SizedBox(height: 6),
                    _buildField(icon: Icons.category_outlined, controller: categoryController, hintEn: 'Category', hintKo: 'optional'),
                    const SizedBox(height: 7),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: startTime,
                                builder: (ctx, child) => Theme(
                                  data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: _brandGolden, onPrimary: _pageBg, surface: _containerBg, onSurface: Colors.white)),
                                  child: child!,
                                ),
                              );
                              if (picked != null) setDialogState(() => startTime = picked);
                            },
                            icon: const Icon(Icons.play_circle_outline, color: _brandGolden, size: 15),
                            label: Text('${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: endTime,
                                builder: (ctx, child) => Theme(
                                  data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: _brandGolden, onPrimary: _pageBg, surface: _containerBg, onSurface: Colors.white)),
                                  child: child!,
                                ),
                              );
                              if (picked != null) setDialogState(() => endTime = picked);
                            },
                            icon: const Icon(Icons.stop_circle_outlined, color: _brandGolden, size: 15),
                            label: Text('${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            onPressed: () => Navigator.of(dialogContext).pop(false),
                            child: BiInline(en: 'Cancel', ko: '취소', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13, translations: commonButtonTranslations['Cancel']),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: _brandGolden, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 4),
                            onPressed: () {
                              if (titleController.text.trim().isEmpty) return;
                              Navigator.of(dialogContext).pop(true);
                            },
                            child: BiInline(en: 'Save', ko: '저장', color: _pageBg, fontWeight: FontWeight.bold, fontSize: 13, translations: commonButtonTranslations['Save']),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (confirmed == true && titleController.text.trim().isNotEmpty) {
      final newBlock = TimelineBlock(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        date: _todayKey,
        plannedStart: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
        plannedEnd: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
        title: titleController.text.trim(),
        category: categoryController.text.trim().isEmpty ? '일반' : categoryController.text.trim(),
      );
      await TimelineDataService.addBlock(newBlock);
      await _loadTimeline();
    }
  }

  // 🆕 [수정 팝업] 기본 틀로 생성된 칸도 자유롭게 이름/시간을 바꿀 수 있도록 함
  Future<void> _showEditBlockDialog(TimelineBlock block) async {
    final TextEditingController titleController = TextEditingController(text: block.title);
    final TextEditingController categoryController = TextEditingController(text: block.category);
    TimeOfDay startTime = TimeOfDay(hour: int.parse(block.plannedStart.split(':')[0]), minute: int.parse(block.plannedStart.split(':')[1]));
    TimeOfDay endTime = TimeOfDay(hour: int.parse(block.plannedEnd.split(':')[0]) % 24, minute: int.parse(block.plannedEnd.split(':')[1]));

    final String? action = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 22),
            child: LuxuryDialogFrame(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    luxuryDialogHeader(icon: Icons.edit_note_rounded, en: 'EDIT TIMELINE', ko: '타임라인 수정'),

                    _buildField(icon: Icons.title_rounded, controller: titleController, hintEn: 'Title', hintKo: 'e.g. exercise'),
                    const SizedBox(height: 6),
                    _buildField(icon: Icons.category_outlined, controller: categoryController, hintEn: 'Category', hintKo: 'optional'),
                    const SizedBox(height: 7),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: startTime,
                                builder: (ctx, child) => Theme(
                                  data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: _brandGolden, onPrimary: _pageBg, surface: _containerBg, onSurface: Colors.white)),
                                  child: child!,
                                ),
                              );
                              if (picked != null) setDialogState(() => startTime = picked);
                            },
                            icon: const Icon(Icons.play_circle_outline, color: _brandGolden, size: 15),
                            label: Text('${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: endTime,
                                builder: (ctx, child) => Theme(
                                  data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: _brandGolden, onPrimary: _pageBg, surface: _containerBg, onSurface: Colors.white)),
                                  child: child!,
                                ),
                              );
                              if (picked != null) setDialogState(() => endTime = picked);
                            },
                            icon: const Icon(Icons.stop_circle_outlined, color: _brandGolden, size: 15),
                            label: Text('${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    // 🆕 [버튼 교체] 취소는 필요 없어서 빼고, 그 자리에 복사를 넣음: 삭제 / 복사 / 저장
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFDC2626)), padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            onPressed: () => Navigator.of(dialogContext).pop('delete'),
                            child: appLanguage.isDefault
                                ? Column(mainAxisSize: MainAxisSize.min, children: [
                              Text('Delete', style: GoogleFonts.gowunBatang(color: const Color(0xFFDC2626), fontSize: 13, fontWeight: FontWeight.bold)),
                              Text('삭제', style: GoogleFonts.notoSansKr(color: const Color(0xFFDC2626), fontSize: 13, fontWeight: FontWeight.bold)),
                            ])
                                : Text(tButton('Delete'), style: GoogleFonts.notoSansKr(color: const Color(0xFFDC2626), fontSize: 13.5, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            onPressed: () => Navigator.of(dialogContext).pop('copy'),
                            child: appLanguage.isDefault
                                ? Column(mainAxisSize: MainAxisSize.min, children: [
                              Text('Copy', style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                              Text('복사', style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                            ])
                                : Text(tButton('Copy'), style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13.5, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: _brandGolden, padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 4, shadowColor: _brandGolden.withOpacity(0.5)),
                            onPressed: () {
                              if (titleController.text.trim().isEmpty) return;
                              Navigator.of(dialogContext).pop('save');
                            },
                            child: appLanguage.isDefault
                                ? Column(mainAxisSize: MainAxisSize.min, children: [
                              Text('Update', style: GoogleFonts.gowunBatang(color: _pageBg, fontSize: 13, fontWeight: FontWeight.bold)),
                              Text('수정완료', style: GoogleFonts.notoSansKr(color: _pageBg, fontSize: 13, fontWeight: FontWeight.bold)),
                            ])
                                : Text(tButton('Update'), style: GoogleFonts.notoSansKr(color: _pageBg, fontSize: 13.5, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (action == 'delete') {
      await TimelineDataService.deleteBlock(block.id);
      await _loadTimeline();
    } else if (action == 'copy') {
      await _copyBlock(block); // 🆕 [복사 버튼] 기존 값 그대로 복제
    } else if (action == 'save' && titleController.text.trim().isNotEmpty) {
      final updated = TimelineBlock(
        id: block.id,
        date: block.date,
        plannedStart: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
        plannedEnd: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
        title: titleController.text.trim(),
        category: categoryController.text.trim().isEmpty ? '일반' : categoryController.text.trim(),
        isRoutine: block.isRoutine,
        actualStart: block.actualStart,
        actualEnd: block.actualEnd,
        status: block.status,
      );
      await TimelineDataService.updateBlock(updated);
      await _loadTimeline();
    }
  }

  Widget _buildField({required IconData icon, required TextEditingController controller, required String hintEn, required String hintKo}) {
    return Container(
      decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _brandGolden.withOpacity(0.85), size: 19),
          hintText: biHint(hintEn, hintKo),
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Future<void> _startExecution(TimelineBlock block) async {
    block.actualStart = _nowHHmm;
    block.status = 'running';
    await TimelineDataService.updateBlock(block);
    await _loadTimeline();
  }

  Future<void> _completeExecution(TimelineBlock block) async {
    block.actualEnd = _nowHHmm;
    block.status = 'completed';
    await TimelineDataService.updateBlock(block);
    await _loadTimeline();
  }

  // 🆕 [AI 분석용 데이터 수집] 완료 버튼을 누르면 바로 완료 처리하지 않고,
  // 먼저 이 설문 팝업을 띄웁니다. 1단계(만족도/방해요인/에너지/메모)는 항상
  // 나오고, 2단계(분야별 3문항)는 "더 자세히" 버튼을 눌러야 나옵니다.
  // 여기서 모은 답변이 나중에 일간/주간/월간 AI 코멘트의 재료가 됩니다.
  Future<void> _showCompletionSurveyDialog(TimelineBlock block) async {
    int? satisfaction; // 0~4 (인덱스), 이모지 5단계
    final Set<String> disruptions = {};
    String energyLevel = '';
    final TextEditingController memoController = TextEditingController();
    bool showDetail = false;
    final Map<String, String> extraAnswers = {};

    final List<CategoryQuestion> extraQuestions = categoryQuestions[block.category] ?? [];

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: LuxuryDialogFrame(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    luxuryDialogHeader(icon: Icons.check_circle_outline_rounded, en: 'HOW DID IT GO?', ko: '어떠셨나요?'),

                    // 🆕 [Q1] 만족도/집중도 - 이모지 5단계
                    BiInline(
                      en: 'Satisfaction / Focus', ko: '만족도 / 집중도', color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 12,
                      translations: const {'JA': '満足度 / 集中度', 'ZH': '满意度 / 专注度', 'FR': 'Satisfaction / Concentration', 'DE': 'Zufriedenheit / Fokus', 'RU': 'Удовлетворённость / Концентрация', 'AR': 'الرضا / التركيز', 'HI': 'संतुष्टि / एकाग्रता', 'VI': 'Sự hài lòng / Tập trung', 'ES': 'Satisfacción / Concentración', 'TH': 'ความพึงพอใจ / สมาธิ'},
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(satisfactionEmojis.length, (i) {
                        final bool isSel = satisfaction == i;
                        return GestureDetector(
                          onTap: () => setDialogState(() => satisfaction = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSel ? _brandGolden.withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSel ? _brandGolden : Colors.transparent),
                            ),
                            child: Text(satisfactionEmojis[i], style: TextStyle(fontSize: isSel ? 26 : 22)),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),

                    // 🆕 [Q2] 방해요인 - 다중선택 칩
                    BiInline(
                      en: 'Distractions', ko: '방해요인', color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 12,
                      translations: const {'JA': '邪魔要因', 'ZH': '干扰因素', 'FR': 'Distractions', 'DE': 'Ablenkungen', 'RU': 'Отвлекающие факторы', 'AR': 'عوامل التشتيت', 'HI': 'ध्यान भटकाने वाले कारक', 'VI': 'Yếu tố gây xao nhãng', 'ES': 'Distracciones', 'TH': 'สิ่งรบกวน'},
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: disruptionOptions.map((opt) {
                        final bool isSel = disruptions.contains(opt);
                        return GestureDetector(
                          onTap: () => setDialogState(() {
                            if (opt == '없음') {
                              disruptions.clear();
                              disruptions.add('없음');
                            } else {
                              disruptions.remove('없음');
                              if (isSel) {
                                disruptions.remove(opt);
                              } else {
                                disruptions.add(opt);
                              }
                            }
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? _brandGolden.withOpacity(0.2) : _pageBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSel ? _brandGolden : Colors.white12),
                            ),
                            child: Text(opt, style: TextStyle(color: isSel ? Colors.white : Colors.white54, fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // 🆕 [Q3] 에너지 레벨
                    BiInline(
                      en: 'Energy Level', ko: '에너지 레벨', color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 12,
                      translations: const {'JA': 'エネルギーレベル', 'ZH': '能量水平', 'FR': "Niveau d'énergie", 'DE': 'Energielevel', 'RU': 'Уровень энергии', 'AR': 'مستوى الطاقة', 'HI': 'ऊर्जा स्तर', 'VI': 'Mức năng lượng', 'ES': 'Nivel de energía', 'TH': 'ระดับพลังงาน'},
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: energyLevelOptions.map((opt) {
                        final bool isSel = energyLevel == opt;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () => setDialogState(() => energyLevel = opt),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSel ? _brandGolden.withOpacity(0.2) : _pageBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isSel ? _brandGolden : Colors.white12),
                                ),
                                child: Text(opt, style: TextStyle(color: isSel ? Colors.white : Colors.white54, fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // 🆕 [Q4] 한줄 메모 (선택)
                    BiInline(
                      en: 'Memo (optional)', ko: '한줄 메모 (선택)', color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 12,
                      translations: const {'JA': 'メモ（任意）', 'ZH': '备注（选填）', 'FR': 'Mémo (facultatif)', 'DE': 'Notiz (optional)', 'RU': 'Заметка (необязательно)', 'AR': 'ملاحظة (اختياري)', 'HI': 'नोट (वैकल्पिक)', 'VI': 'Ghi chú (không bắt buộc)', 'ES': 'Nota (opcional)', 'TH': 'บันทึกย่อ (ไม่บังคับ)'},
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                      child: TextField(
                        controller: memoController,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: biHint('Optional', '입력 안 해도 됨'),
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),

                    // 🆕 [2단계] "더 자세히" - 분야별 질문 3개 (해당 분야일 때만 버튼 노출)
                    if (extraQuestions.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      if (!showDetail)
                        TextButton.icon(
                          onPressed: () => setDialogState(() => showDetail = true),
                          icon: const Icon(Icons.expand_more_rounded, color: _brandGolden, size: 18),
                          label: BiInline(
                            en: 'More Details (${block.category})', ko: '더 자세히 (${block.category})', color: _brandGolden, fontWeight: FontWeight.bold,
                            translations: {
                              'JA': '詳細を見る (${block.category})', 'ZH': '查看详情 (${block.category})', 'FR': 'Plus de détails (${block.category})', 'DE': 'Mehr Details (${block.category})',
                              'RU': 'Подробнее (${block.category})', 'AR': 'مزيد من التفاصيل (${block.category})', 'HI': 'अधिक विवरण (${block.category})', 'VI': 'Chi tiết hơn (${block.category})',
                              'ES': 'Más detalles (${block.category})', 'TH': 'รายละเอียดเพิ่มเติม (${block.category})',
                            },
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: extraQuestions.map((q) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  BiInline(en: q.labelEn, ko: q.labelKo, color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11.5, translations: q.labelTranslations),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: q.options.map((opt) {
                                      final bool isSel = extraAnswers[q.id] == opt;
                                      return Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 6),
                                          child: GestureDetector(
                                            onTap: () => setDialogState(() => extraAnswers[q.id] = opt),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: isSel ? _brandGolden.withOpacity(0.2) : _pageBg,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: isSel ? _brandGolden : Colors.white12),
                                              ),
                                              child: Text(opt, style: TextStyle(color: isSel ? Colors.white : Colors.white54, fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _brandGolden, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 6, shadowColor: _brandGolden.withOpacity(0.5)),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: BiInline(en: 'Done', ko: '완료', color: _pageBg, fontWeight: FontWeight.bold, translations: const {'JA': '完了', 'ZH': '完成', 'FR': 'Terminé', 'DE': 'Fertig', 'RU': 'Готово', 'AR': 'تم', 'HI': 'पूर्ण', 'VI': 'Hoàn tất', 'ES': 'Hecho', 'TH': 'เสร็จสิ้น'}),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (confirmed == true) {
      // 🆕 [버그 수정] 계획 상태에서 시작도 안 한 채 바로 완료 처리하는 경우,
      // 시작시각이 비어있으면 계획된 시작시각으로 채워서 기록이 비지 않게 함.
      if (block.actualStart == null || block.actualStart!.isEmpty) {
        block.actualStart = block.plannedStart;
      }
      block.actualEnd = _nowHHmm;
      block.status = 'completed';
      block.satisfaction = satisfaction != null ? satisfaction! + 1 : null; // 1~5로 저장
      block.disruptions = disruptions.toList();
      block.energyLevel = energyLevel;
      block.memo = memoController.text.trim();
      block.extraAnswers = extraAnswers;
      await TimelineDataService.updateBlock(block);
      await _loadTimeline();
    }
  }

  // 🆕 [되돌림 기능] 시작/완료된 칸을 다시 "계획" 상태로 되돌림. 확인 팝업을
  // 한 번 거쳐서, 실수로 눌러서 진짜 기록을 날리는 일이 없도록 함.
  Future<void> _undoBlockStatus(TimelineBlock block) async {
    final bool confirmed = await _showUndoConfirmDialog(block);
    if (!confirmed) return;

    // 🆕 [버그 수정] 무조건 "계획"으로 완전히 초기화하지 않고, 한 단계씩만 되돌림.
    // 완료 -> 실행중(시작시각/설문답변은 유지, 종료시각만 지움)
    // 실행중 -> 계획(시작시각도 지움)
    // 이렇게 해야 완료 처리했던 설문 답변 등 자료가 갑자기 사라지지 않음.
    if (block.status == 'completed') {
      block.status = 'running';
      block.actualEnd = null;
      // satisfaction/disruptions/energyLevel/memo/extraAnswers는 유지 - 다시 완료하면 그대로 씀
    } else if (block.status == 'running') {
      block.status = 'planned';
      block.actualStart = null;
    }
    await TimelineDataService.updateBlock(block);
    await _loadTimeline();
    if (mounted) {
      biSnack(context, 'Reverted to previous state', '이전 상태로 되돌렸습니다');
    }
  }

  Future<bool> _showUndoConfirmDialog(TimelineBlock block) async {
    final bool wasCompleted = block.status == 'completed';
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: LuxuryDialogFrame(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                luxuryDialogHeader(icon: Icons.replay_circle_filled, en: 'UNDO', ko: '되돌리기'),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wasCompleted
                            ? 'This will undo the completion and clear the recorded start/end times and survey answers for this slot.'
                            : 'This will cancel the current run and reset this slot back to planned.',
                        style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 12, height: 1.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        wasCompleted
                            ? '완료 처리를 취소하고, 기록된 시작/종료 시각과 설문 답변이 지워집니다.'
                            : '지금 실행중인 상태를 취소하고, 다시 계획 상태로 되돌립니다.',
                        style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: appLanguage.isDefault
                            ? Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('Keep', style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('유지', style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        ])
                            : Text(tButton('Keep'), style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 4),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: appLanguage.isDefault
                            ? Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('Undo', style: GoogleFonts.gowunBatang(color: _pageBg, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('되돌리기', style: GoogleFonts.notoSansKr(color: _pageBg, fontSize: 12, fontWeight: FontWeight.bold)),
                        ])
                            : Text(tButton('Undo'), style: GoogleFonts.notoSansKr(color: _pageBg, fontSize: 12.5, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  Future<void> _copyBlock(TimelineBlock block) async {
    final copy = TimelineBlock(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: block.date,
      plannedStart: block.plannedStart,
      plannedEnd: block.plannedEnd,
      title: '${block.title} (Copy)',
      category: block.category,
    );
    await TimelineDataService.addBlock(copy);
    await _loadTimeline();
  }

  Future<void> _applyRoutine() async {
    final applied = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => RoutineScreen(applyToDate: _todayKey)),
    );
    if (applied == true) {
      await _loadTimeline();
    }
  }

  @override
  Widget build(BuildContext context) {
    final int completed = _blocks.where((b) => b.status == 'completed').length;
    final int total = _blocks.length;
    final double rate = total == 0 ? 0 : completed / total;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: BiTitle(
          en: "TODAY'S TIMELINE", ko: '오늘의 타임라인', enSize: 16, koSize: 13,
          translations: const {'JA': '今日のタイムライン', 'ZH': '今日时间线', 'FR': 'Chronologie du jour', 'DE': 'Heutige Zeitleiste', 'RU': 'Хронология на сегодня', 'AR': 'الجدول الزمني لليوم', 'HI': 'आज की समयरेखा', 'VI': 'Dòng thời gian hôm nay', 'ES': 'Cronología de hoy', 'TH': 'ไทม์ไลน์วันนี้'},
        ),
        actions: [
          IconButton(icon: const Icon(Icons.grid_view_rounded, color: _brandGolden), tooltip: 'Default Timeline', onPressed: _createDefaultTimeline),
          IconButton(icon: const Icon(Icons.repeat, color: _brandGolden), tooltip: 'Apply Routine', onPressed: _applyRoutine),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : RefreshIndicator(
        color: _brandGolden,
        backgroundColor: _containerBg,
        onRefresh: _loadTimeline,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCurrentTimeCard(), // 🆕 [현재 시간 표시 복구] 항상 고정으로 보이는 현재 시각 카드
            if (_todayExercises.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildExerciseSummaryCard(), // 🆕 [운동 연동]
            ],
            const SizedBox(height: 12),
            _buildProgressCard(completed, total, rate),
            const SizedBox(height: 16),
            ..._blocks.map((b) => _buildTimelineTile(b)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _brandGolden,
        onPressed: _showAddBlockDialog,
        child: const Icon(Icons.add, color: _pageBg),
      ),
    );
  }

  // 🆕 [현재 시간 표시 복구] 작은 배지에만 의존하지 않고, 화면 맨 위에
  // "지금 몇 시인지"를 항상 고정으로 보여주는 카드. 30초마다 자동 새로고침되는
  // 타이머(_autoCheckTimer)와 함께 계속 최신 시각으로 갱신됨.
  Widget _buildCurrentTimeCard() {
    final now = DateTime.now();
    final String nowText = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_brandGolden.withOpacity(0.18), _brandGolden.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _brandGolden.withOpacity(0.5), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_filled_rounded, color: _brandGolden, size: 20),
          const SizedBox(width: 10),
          BiInline(
            en: 'Current Time', ko: '현재 시간', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12,
            translations: const {'JA': '現在の時刻', 'ZH': '当前时间', 'FR': 'Heure actuelle', 'DE': 'Aktuelle Zeit', 'RU': 'Текущее время', 'AR': 'الوقت الحالي', 'HI': 'वर्तमान समय', 'VI': 'Thời gian hiện tại', 'ES': 'Hora actual', 'TH': 'เวลาปัจจุบัน'},
          ),
          const Spacer(),
          Text(nowText, style: GoogleFonts.rajdhani(color: _brandGolden, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 🆕 [운동 연동] 오늘의 운동 요약 카드 (읽기 전용, TimelineBlock 구조 변경 없음)
  Widget _buildExerciseSummaryCard() {
    final totalMinutes = _todayExercises.fold<int>(0, (sum, r) => sum + r.durationMin);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _containerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _brandGolden.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.fitness_center_rounded, color: _brandGolden, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: BiInline(
              en: "Today's Exercise", ko: '오늘의 운동', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12,
              translations: const {'JA': '今日の運動', 'ZH': '今日运动', 'FR': "Exercice du jour", 'DE': 'Heutiges Training', 'RU': 'Тренировка сегодня', 'AR': 'تمرين اليوم', 'HI': 'आज का व्यायाम', 'VI': 'Tập luyện hôm nay', 'ES': 'Ejercicio de hoy', 'TH': 'ออกกำลังกายวันนี้'},
            ),
          ),
          Text('${_todayExercises.length}회 · $totalMinutes분', style: GoogleFonts.rajdhani(color: _brandGolden, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int completed, int total, double rate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _containerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _brandGolden.withOpacity(0.45)),
        boxShadow: [BoxShadow(color: _brandGolden.withOpacity(0.08), blurRadius: 18, spreadRadius: 1)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BiInline(
                en: 'Completion Rate', ko: '완료율', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
                translations: const {'JA': '達成率', 'ZH': '完成率', 'FR': "Taux d'achèvement", 'DE': 'Fertigstellungsrate', 'RU': 'Процент выполнения', 'AR': 'نسبة الإنجاز', 'HI': 'पूर्णता दर', 'VI': 'Tỷ lệ hoàn thành', 'ES': 'Tasa de finalización', 'TH': 'อัตราความสำเร็จ'},
              ),
              Text('$completed / $total', style: const TextStyle(color: _brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: rate, minHeight: 10, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation<Color>(_brandGolden)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTile(TimelineBlock block) {
    final bool isPlanned = block.status == 'planned';
    final bool isRunning = block.status == 'running';
    final bool isCompleted = block.status == 'completed';

    // 🆕 [지금 이 시간 / 지나간 시간] 계획 시작~종료 구간과 현재 시각을 비교
    final int startMin = _hhmmToMinutes(block.plannedStart);
    final int endMinRaw = _hhmmToMinutes(block.plannedEnd);
    final int endMin = endMinRaw <= startMin ? endMinRaw + 24 * 60 : endMinRaw; // 24:00 같은 경계 처리
    final int nowMin = _nowMinutesSinceMidnight;

    // 🆕 [자동 실행 반영] 이제 "지금 시간대"는 planned뿐 아니라 자동으로 실행중이 된
    // 항목에도 적용됨(현재 진행 중인 칸을 강조하기 위함).
    final bool isNow = startMin >= 0 && nowMin >= startMin && nowMin < endMin && !isCompleted;

    // 🆕 [회색 처리 버그 수정] 자동 실행 기능 때문에 지나간 칸도 "실행중" 상태로
    // 계속 남아 회색 처리가 안 되는 문제가 있었음. 이제는 상태가 무엇이든
    // (planned/running) 완료(completed)만 안 됐고 시간이 지났으면 전부 회색 처리함.
    final bool isPastUnfinished = !isCompleted && endMin >= 0 && nowMin >= endMin;

    // 🆕 [요청 반영] 배경색/테두리는 절대 바꾸지 않고, 글자만 흐릿하게 통일함.
    // (배경색이 갑자기 바뀌면 놀란다는 피드백을 받아 원상태 유지로 변경)
    final Color tileBg = _containerBg;
    final Color borderColor = isRunning
        ? _brandGolden
        : isNow
        ? _brandGolden.withOpacity(0.8)
        : _brandGolden.withOpacity(0.35);

    final Color timeTextColor = isPastUnfinished ? Colors.white38 : _brandGolden;
    final Color titleTextColor = isCompleted ? Colors.white38 : (isPastUnfinished ? Colors.white38 : Colors.white);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: (isRunning || isNow) ? 1.6 : 1),
        boxShadow: (isRunning || isNow) ? [BoxShadow(color: _brandGolden.withOpacity(0.2), blurRadius: 14, spreadRadius: 1)] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(6)),
                child: Text('${block.plannedStart}~${block.plannedEnd}', style: TextStyle(color: timeTextColor, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              // 🆕 [NOW 배지도 회색 처리 대상이면 숨김] 이미 지나서 미완료인 칸은 "지금"이 아니므로 NOW를 보여주지 않음
              if (isNow && !isPastUnfinished)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: _brandGolden, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: _brandGolden.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)]),
                  child: const Text('● NOW', style: TextStyle(color: _pageBg, fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              const SizedBox(width: 5),
              if (block.isRoutine) Icon(Icons.repeat, color: isPastUnfinished ? Colors.white24 : Colors.white38, size: 13),
              const Spacer(),
              // 🆕 [되돌림 버튼] 실수로 시작/완료를 눌렀거나, 처음 써보면서 시행착오를
              // 겪을 수 있으므로, 이미 시작됐거나 완료된 칸은 언제든 "계획" 상태로
              // 되돌릴 수 있게 함. 3선 연필 바로 왼쪽에 배치.
              if (block.status != 'planned')
                IconButton(
                  icon: Icon(Icons.replay_circle_filled, color: isPastUnfinished ? Colors.white24 : Colors.orangeAccent.withOpacity(0.85), size: 20), // 🆕 [정확한 모양] 동그라미 안에 화살표 모양 아이콘
                  tooltip: 'Undo (되돌리기)',
                  onPressed: () => _undoBlockStatus(block),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
              IconButton(
                icon: Opacity(
                  opacity: isPastUnfinished ? 0.35 : 1.0,
                  child: const ThreeColorPencilIcon(size: 17),
                ),
                onPressed: () => _showEditBlockDialog(block),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                block.title,
                style: TextStyle(color: titleTextColor, decoration: isCompleted ? TextDecoration.lineThrough : null, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                '  |  ${block.category}',
                style: GoogleFonts.notoSansKr(color: isPastUnfinished ? Colors.white24 : Colors.white38, fontSize: 12),
              ),
            ],
          ),

          // 🆕 [결과 사라짐 버그 수정] 완료된 칸뿐 아니라, 시간이 지나서 회색이 된 칸도
          // (복사로 만들어져 시작/완료 기록이 비어있더라도) 결과 카드가 항상 보이도록 함.
          if (isCompleted || isPastUnfinished) ...[
            const SizedBox(height: 6),
            _buildCompletionSummary(block, isPastUnfinished: isPastUnfinished),
          ],

          // 🆕 [문구 수정] "완료" 라는 액션성 문구는 뺴고, 지금 상태를 그대로 보여주는
          // "Started 10:20  실행중" 형식으로 표시. "실행중"은 눈에 띄게 진하게.
          // 버튼을 누르면 여전히 완료 처리가 됨(기능은 그대로, 문구만 상태 표시로 바뀜).
          if (isRunning) const SizedBox(height: 8),
          if (isRunning)
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: () => _showCompletionSurveyDialog(block), // 🆕 [설문 연동] 바로 완료 대신 설문 먼저
                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.shade400),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Started ${block.actualStart}',
                      style: const TextStyle(color: _pageBg, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '실행중',
                      // 🆕 [진하게 하지 않음 + 글자크기 통일] w900 -> w600으로 낮추고, 크기도 옆 글자와 동일하게(13)
                      style: const TextStyle(color: _pageBg, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          // 🆕 [버그 수정] 시간이 지나도록 손 안 댄(planned) 칸은 지금까지 완료할 방법이
          // 아예 없었음(버튼이 "실행중"일 때만 보였기 때문). 이제 계획 상태여도
          // 완료 처리를 할 수 있도록 버튼을 추가함.
          if (isPlanned) const SizedBox(height: 8),
          if (isPlanned)
            SizedBox(
              width: double.infinity,
              height: 36,
              child: OutlinedButton(
                onPressed: () => _showCompletionSurveyDialog(block),
                style: OutlinedButton.styleFrom(side: BorderSide(color: _brandGolden.withOpacity(0.6))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, color: _brandGolden.withOpacity(0.9), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Mark as Complete (완료 처리)',
                      style: TextStyle(color: _brandGolden.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 🆕 [결과 사라짐 버그 수정] isPastUnfinished 매개변수 추가 - 완료 안 된 채로
  // 회색이 된 칸도 호출되므로, actualStart/actualEnd가 비어있을 수 있음을 감안해서
  // "시작 안 함"/"완료 안 함"으로 안전하게 표시함 (숫자 계산이 불가능하면 "-").
  Widget _buildCompletionSummary(TimelineBlock block, {bool isPastUnfinished = false}) {
    final bool hasStart = block.actualStart != null && block.actualStart!.isNotEmpty;
    final bool hasEnd = block.actualEnd != null && block.actualEnd!.isNotEmpty;
    final int? diff = block.diffMinutes;
    final String diffText = diff == null ? '-' : (diff == 0 ? 'On time' : (diff > 0 ? '+${diff}min over' : '${diff.abs()}min saved'));
    final String diffTextKo = diff == null ? '-' : (diff == 0 ? '정확히 맞춤' : (diff > 0 ? '${diff}분 초과' : '${diff.abs()}분 단축'));
    final Color diffColor = (diff == null || diff == 0) ? Colors.white54 : (diff > 0 ? Colors.orangeAccent : Colors.lightGreenAccent);
    final Color mainTextColor = isPastUnfinished ? Colors.white54 : Colors.white;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasStart ? 'Started (시작) ${block.actualStart}' : 'Not started (시작 안 함)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: hasStart ? mainTextColor : Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasEnd ? 'Complete (완료) ${block.actualEnd}' : 'Not completed (완료 안 함)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: hasEnd ? mainTextColor : Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Planned (계획) ${block.plannedMinutes}min', style: const TextStyle(color: Colors.white54, fontSize: 10.5)),
              if (hasStart && hasEnd) Text('Diff (차이) $diffText / $diffTextKo', style: TextStyle(color: diffColor, fontSize: 10.5, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String en, String ko, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BiInline(en: en, ko: ko, color: Colors.white38, fontSize: 9),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
