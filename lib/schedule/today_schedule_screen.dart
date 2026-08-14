// ============================================================================
// 🆕 [일반 플래너 - 신규 고급 팝업 전면 교체] TodayScheduleScreen
// 오늘 날짜의 일정만 모아서 시간순으로 보여줍니다.
//
// 🆕 [전면 교체] 기존엔 체크박스+삭제 아이콘만 있던 화면이었는데, 캘린더
// 화면과 완전히 동일한 수준으로 업그레이드했습니다:
//   - 중요일정(빨강)/회사일정(진파랑)/개인일정(진노랑) 카테고리 선택
//   - LuxuryDialogFrame 골드 글로우 팝업
//   - 캘린더와 동일한 대각선 3선(파랑/노랑/흰색) 연필 아이콘으로 수정 진입
//   - 팝업 맨 아래 삭제/취소/저장 한 줄 배치
//   - 캘린더와 같은 ScheduleDataService를 쓰므로, 캘린더에서 오늘 추가한
//     일정이 여기 그대로 보이고, 여기서 수정하면 캘린더에도 반영됩니다.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'schedule_data_service.dart';
import 'calendar_screen.dart' show kScheduleCategories, categoryColorOf;
import 'bilingual_text.dart';

class TodayScheduleScreen extends StatefulWidget {
  const TodayScheduleScreen({super.key});

  @override
  State<TodayScheduleScreen> createState() => _TodayScheduleScreenState();
}

class _TodayScheduleScreenState extends State<TodayScheduleScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  List<ScheduleItem> _todayItems = [];
  bool _isLoading = true;

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadTodaySchedule();
  }

  Future<void> _loadTodaySchedule() async {
    setState(() => _isLoading = true);
    final items = await ScheduleDataService.loadForDate(_todayKey);
    if (!mounted) return;
    setState(() {
      _todayItems = items;
      _isLoading = false;
    });
  }

  int get _completedCount => _todayItems.where((e) => e.isCompleted).length;
  double get _completionRate => _todayItems.isEmpty ? 0 : _completedCount / _todayItems.length;

  Future<void> _toggleComplete(ScheduleItem item) async {
    item.isCompleted = !item.isCompleted;
    await ScheduleDataService.update(item);
    await _loadTodaySchedule();
  }

  // 🆕 [신 팝업 전면 교체] 일정 추가/수정 - 카테고리 선택 + 삭제/취소/저장 한 줄
  Future<void> _showScheduleDialog({ScheduleItem? existing}) async {
    final bool isEdit = existing != null;
    final titleController = TextEditingController(text: existing?.title ?? '');
    final timeController = TextEditingController(text: existing?.time ?? '');
    final memoController = TextEditingController(text: existing?.memo ?? '');
    String? selectedCategory = existing?.category ?? kScheduleCategories.last.koLabel; // 기본값: 개인일정

    final String? action = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: LuxuryDialogFrame(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    luxuryDialogHeader(icon: isEdit ? Icons.edit_calendar_rounded : Icons.event_available_rounded, en: isEdit ? 'EDIT SCHEDULE' : 'ADD SCHEDULE', ko: isEdit ? '일정 수정' : '일정 추가'),

                    BiInline(
                      en: 'CATEGORY', ko: '분류', color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 12,
                      translations: const {'JA': 'カテゴリー', 'ZH': '分类', 'FR': 'Catégorie', 'DE': 'Kategorie', 'RU': 'Категория', 'AR': 'الفئة', 'HI': 'श्रेणी', 'VI': 'Danh mục', 'ES': 'Categoría', 'TH': 'หมวดหมู่'},
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: kScheduleCategories.map((cat) {
                        final bool isSel = selectedCategory == cat.koLabel;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () => setDialogState(() => selectedCategory = cat.koLabel),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                                decoration: BoxDecoration(
                                  color: isSel ? cat.color.withOpacity(0.18) : _pageBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isSel ? cat.color : Colors.white12, width: isSel ? 1.4 : 1),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(width: 14, height: 14, decoration: BoxDecoration(color: cat.color, borderRadius: BorderRadius.circular(3))),
                                    const SizedBox(height: 6),
                                    Text(cat.enLabel, style: GoogleFonts.gowunBatang(color: isSel ? Colors.white70 : Colors.white38, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                    Text(cat.koLabel, style: GoogleFonts.notoSansKr(color: isSel ? Colors.white : Colors.white54, fontSize: 10.5, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    _buildField(icon: Icons.title_rounded, controller: titleController, hintEn: 'Title', hintKo: 'e.g. 병원 예약'),
                    const SizedBox(height: 12),
                    _buildField(icon: Icons.access_time_rounded, controller: timeController, hintEn: 'Time', hintKo: '예: 14:30, 비워도 됨'),
                    const SizedBox(height: 12),
                    _buildField(icon: Icons.notes_rounded, controller: memoController, hintEn: 'Memo', hintKo: '선택 사항', maxLines: 2),

                    const SizedBox(height: 20),
                    luxuryBottomActions(
                      isEdit: isEdit,
                      onDelete: isEdit ? () => Navigator.of(context).pop('delete') : null,
                      onCancel: () => Navigator.of(context).pop(null),
                      onSave: () {
                        if (titleController.text.trim().isEmpty) return;
                        Navigator.of(context).pop('save');
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (action == 'delete' && existing != null) {
      await ScheduleDataService.delete(existing.id);
      await _loadTodaySchedule();
      return;
    }

    if (action == 'save' && titleController.text.trim().isNotEmpty) {
      if (isEdit) {
        final updated = ScheduleItem(
          id: existing!.id,
          date: existing.date,
          time: timeController.text.trim(),
          title: titleController.text.trim(),
          memo: memoController.text.trim(),
          category: selectedCategory ?? existing.category,
          isCompleted: existing.isCompleted,
        );
        await ScheduleDataService.update(updated);
      } else {
        final newItem = ScheduleItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          date: _todayKey,
          time: timeController.text.trim(),
          title: titleController.text.trim(),
          memo: memoController.text.trim(),
          category: selectedCategory ?? '개인일정',
        );
        await ScheduleDataService.add(newItem);
      }
      await _loadTodaySchedule();
    }
  }

  Widget _buildField({required IconData icon, required TextEditingController controller, required String hintEn, required String hintKo, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final String todayDisplay = '${now.month}/${now.day} (${weekdayNames[now.weekday - 1]})';

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: BiTitle(
          en: "TODAY'S SCHEDULE", ko: '오늘의 일정', enSize: 16, koSize: 13,
          translations: const {'JA': '今日の予定', 'ZH': '今日日程', 'FR': 'Programme du jour', 'DE': 'Heutiger Zeitplan', 'RU': 'Расписание на сегодня', 'AR': 'جدول اليوم', 'HI': 'आज का शेड्यूल', 'VI': 'Lịch hôm nay', 'ES': 'Horario de hoy', 'TH': 'ตารางวันนี้'},
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : RefreshIndicator(
        color: _brandGolden,
        backgroundColor: _containerBg,
        onRefresh: _loadTodaySchedule,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(todayDisplay, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildProgressCard(),
            const SizedBox(height: 20),
            if (_todayItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: BiInline(
                    en: 'No schedules for today.\nTap + to add one.', ko: '오늘 등록된 일정이 없습니다.\n+ 버튼으로 추가해 보세요.', color: Colors.white38, fontSize: 14, textAlign: TextAlign.center,
                    translations: const {
                      'JA': '今日の予定がありません。\n+ボタンで追加してください。',
                      'ZH': '今天没有日程。\n点击+号添加。',
                      'FR': "Aucun programme aujourd'hui.\nAppuyez sur + pour en ajouter.",
                      'DE': 'Keine Termine heute.\nTippen Sie auf +, um einen hinzuzufügen.',
                      'RU': 'На сегодня нет событий.\nНажмите +, чтобы добавить.',
                      'AR': 'لا توجد مواعيد اليوم.\nاضغط + للإضافة.',
                      'HI': 'आज कोई शेड्यूल नहीं है।\nजोड़ने के लिए + टैप करें।',
                      'VI': 'Không có lịch trình hôm nay.\nNhấn + để thêm.',
                      'ES': 'No hay horarios hoy.\nToca + para añadir uno.',
                      'TH': 'ไม่มีตารางเวลาวันนี้\nแตะ + เพื่อเพิ่ม',
                    },
                  ),
                ),
              )
            else
              ..._todayItems.map((item) => _buildScheduleTile(item)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _brandGolden,
        onPressed: () => _showScheduleDialog(),
        child: const Icon(Icons.add, color: _pageBg),
      ),
    );
  }

  Widget _buildProgressCard() {
    final int total = _todayItems.length;
    final int done = _completedCount;
    final int percent = (total == 0) ? 0 : (_completionRate * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BiInline(
                en: "Today's Completion", ko: '오늘의 완료율', color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,
                translations: const {'JA': '今日の達成率', 'ZH': '今日完成率', 'FR': "Taux d'achèvement du jour", 'DE': 'Heutige Fertigstellungsrate', 'RU': 'Процент выполнения сегодня', 'AR': 'نسبة الإنجاز اليوم', 'HI': 'आज की पूर्णता दर', 'VI': 'Tỷ lệ hoàn thành hôm nay', 'ES': 'Finalización de hoy', 'TH': 'อัตราความสำเร็จวันนี้'},
              ),
              Text('$done / $total', style: const TextStyle(color: _brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: _completionRate, minHeight: 10, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation<Color>(_brandGolden)),
          ),
          const SizedBox(height: 6),
          Text('$percent%', style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildScheduleTile(ScheduleItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _brandGolden.withOpacity(0.35))),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleComplete(item),
            child: Icon(item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, color: item.isCompleted ? _brandGolden : Colors.white38, size: 24),
          ),
          const SizedBox(width: 10),
          // 🆕 카테고리 색상 정사각형 (한글 글자 크기)
          Container(width: 14, height: 14, decoration: BoxDecoration(color: categoryColorOf(item.category), borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          if (item.time.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(6)),
              child: Text(item.time, style: const TextStyle(color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(color: item.isCompleted ? Colors.white38 : Colors.white, decoration: item.isCompleted ? TextDecoration.lineThrough : null, fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          // 🆕 [신 팝업] 삭제 아이콘 제거 -> 캘린더와 동일한 대각선 3선 연필로 교체
          IconButton(
            icon: const ThreeColorPencilIcon(size: 18),
            onPressed: () => _showScheduleDialog(existing: item),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }
}
