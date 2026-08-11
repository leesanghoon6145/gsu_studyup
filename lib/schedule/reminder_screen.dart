// ============================================================================
// 🆕 [일반 플래너] ReminderScreen (알림)
// 알림 목록을 관리합니다(추가/수정/삭제/켜짐끄짐 토글). 반복 유형(한번/매일/매주)
// 선택 가능. 캘린더/약속/프로젝트와 동일한 골드 글로우 팝업 디자인 + 영한 병기.
//
// ⚠️ [참고] 저장된 알림을 실제 푸시 알림으로 발송하는 기능은 아직 연결되지
// 않았습니다 (reminder_data_service.dart 상단 주석 참고).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'reminder_data_service.dart';
import 'bilingual_text.dart';
import 'notification_service.dart'; // 🆕 [권한 안내 배너]

class _RepeatOption {
  final String enLabel;
  const _RepeatOption(this.enLabel);
}

const Map<String, _RepeatOption> kRepeatOptions = {
  '한번': _RepeatOption('Once'),
  '매일': _RepeatOption('Daily'),
  '매주': _RepeatOption('Weekly'),
};

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  List<ReminderItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final items = await ReminderDataService.loadAll();
    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _toggleEnabled(ReminderItem item) async {
    item.isEnabled = !item.isEnabled;
    await ReminderDataService.update(item);
    await _load();
  }

  Future<void> _showDialog({ReminderItem? existing}) async {
    final bool isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final memoCtrl = TextEditingController(text: existing?.memo ?? '');
    DateTime selectedDate = existing != null && existing.date.isNotEmpty ? DateTime.tryParse(existing.date) ?? DateTime.now() : DateTime.now();
    TimeOfDay selectedTime = existing != null && existing.time.contains(':')
        ? TimeOfDay(hour: int.parse(existing.time.split(':')[0]), minute: int.parse(existing.time.split(':')[1]))
        : TimeOfDay.now();
    String selectedRepeat = existing?.repeatType ?? '한번';

    final String? action = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 22),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF11192E), Color(0xFF0A0F1E)]),
                border: Border.all(color: _brandGolden.withOpacity(0.45), width: 1.2),
                boxShadow: [
                  BoxShadow(color: _brandGolden.withOpacity(0.18), blurRadius: 34, spreadRadius: 1),
                  const BoxShadow(color: Colors.black, blurRadius: 24, offset: Offset(0, 10)),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isEdit ? Icons.edit_notifications_rounded : Icons.notifications_active_rounded, color: _brandGolden, size: 22),
                        const SizedBox(width: 8),
                        BiTitle(en: isEdit ? 'EDIT REMINDER' : 'ADD REMINDER', ko: isEdit ? '알림 수정' : '알림 추가', enSize: 16, koSize: 12.5),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, _brandGolden.withOpacity(0.5), Colors.transparent]))),
                    const SizedBox(height: 18),

                    _buildField(icon: Icons.title_rounded, controller: titleCtrl, hintEn: 'Title', hintKo: 'e.g. 물 마시기'),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(DateTime.now().year - 1),
                                lastDate: DateTime(DateTime.now().year + 3),
                                builder: (ctx, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: _brandGolden, onPrimary: _pageBg, surface: _containerBg)), child: child!),
                              );
                              if (picked != null) setDialogState(() => selectedDate = picked);
                            },
                            icon: const Icon(Icons.calendar_today, color: _brandGolden, size: 15),
                            label: Text('${selectedDate.year}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.day.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: () async {
                              final picked = await showTimePicker(context: context, initialTime: selectedTime);
                              if (picked != null) setDialogState(() => selectedTime = picked);
                            },
                            icon: const Icon(Icons.access_time, color: _brandGolden, size: 15),
                            label: Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    const BiInline(en: 'REPEAT', ko: '반복', color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 12),
                    const SizedBox(height: 8),
                    Row(
                      children: kRepeatOptions.entries.map((entry) {
                        final bool isSel = selectedRepeat == entry.key;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () => setDialogState(() => selectedRepeat = entry.key),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSel ? _brandGolden.withOpacity(0.18) : _pageBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isSel ? _brandGolden : Colors.white12, width: isSel ? 1.4 : 1),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(entry.value.enLabel, style: GoogleFonts.gowunBatang(color: isSel ? _brandGolden : Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                                    Text(entry.key, style: GoogleFonts.notoSansKr(color: isSel ? Colors.white : Colors.white54, fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    _buildField(icon: Icons.notes_rounded, controller: memoCtrl, hintEn: 'Memo', hintKo: '선택 사항', maxLines: 2),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (isEdit) ...[
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFDC2626)), padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              onPressed: () => Navigator.of(context).pop('delete'),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Text('Delete', style: GoogleFonts.gowunBatang(color: const Color(0xFFDC2626), fontSize: 10.5, fontWeight: FontWeight.bold)),
                                Text('삭제', style: GoogleFonts.notoSansKr(color: const Color(0xFFDC2626), fontSize: 10.5, fontWeight: FontWeight.bold)),
                              ]),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            onPressed: () => Navigator.of(context).pop(null),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Text('Cancel', style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold)),
                              Text('취소', style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold)),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: _brandGolden, padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 4, shadowColor: _brandGolden.withOpacity(0.5)),
                            onPressed: () {
                              if (titleCtrl.text.trim().isEmpty) return;
                              Navigator.of(context).pop('save');
                            },
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Text(isEdit ? 'Update' : 'Save', style: GoogleFonts.gowunBatang(color: _pageBg, fontSize: 10.5, fontWeight: FontWeight.bold)),
                              Text(isEdit ? '수정완료' : '저장', style: GoogleFonts.notoSansKr(color: _pageBg, fontSize: 10.5, fontWeight: FontWeight.bold)),
                            ]),
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

    if (action == 'delete' && existing != null) {
      await ReminderDataService.delete(existing.id);
      await _load();
      return;
    }

    if (action == 'save' && titleCtrl.text.trim().isNotEmpty) {
      final dateKey = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      final timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

      if (isEdit) {
        final updated = ReminderItem(
          id: existing!.id,
          title: titleCtrl.text.trim(),
          date: dateKey,
          time: timeStr,
          repeatType: selectedRepeat,
          isEnabled: existing.isEnabled,
          memo: memoCtrl.text.trim(),
        );
        await ReminderDataService.update(updated);
      } else {
        final newItem = ReminderItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: titleCtrl.text.trim(),
          date: dateKey,
          time: timeStr,
          repeatType: selectedRepeat,
          memo: memoCtrl.text.trim(),
        );
        await ReminderDataService.add(newItem);
      }
      await _load();
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
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: const BiTitle(en: 'REMINDER', ko: '알림', enSize: 19, koSize: 14),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : Padding(
        padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
        child: Column(
          children: [
            const NotificationPermissionBanner(), // 🆕 [권한 안내 배너] 알림이 꺼져있으면 여기 안내가 뜸
            Expanded(
              child: _items.isEmpty
                  ? Center(child: BiInline(en: 'No reminders yet', ko: '등록된 알림이 없습니다', color: Colors.white38, fontSize: 14, textAlign: TextAlign.center))
                  : ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) => _buildTile(_items[index]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _brandGolden,
        onPressed: () => _showDialog(),
        child: const Icon(Icons.add, color: _pageBg),
      ),
    );
  }

  Widget _buildTile(ReminderItem item) {
    final repeatInfo = kRepeatOptions[item.repeatType];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _containerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.isEnabled ? _brandGolden.withOpacity(0.3) : Colors.white12),
      ),
      child: Row(
        children: [
          Icon(item.isEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_outlined, color: item.isEnabled ? _brandGolden : Colors.white24, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: TextStyle(color: item.isEnabled ? Colors.white : Colors.white38, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('${item.date} ${item.time}', style: TextStyle(color: item.isEnabled ? _brandGolden : Colors.white24, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    if (repeatInfo != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(5)),
                        child: Text('${repeatInfo.enLabel} (${item.repeatType})', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: item.isEnabled,
            onChanged: (_) => _toggleEnabled(item),
            activeColor: _brandGolden,
          ),
          IconButton(icon: const _MiniPencilIcon(), onPressed: () => _showDialog(existing: item)),
        ],
      ),
    );
  }
}

class _MiniPencilIcon extends StatelessWidget {
  const _MiniPencilIcon();

  @override
  Widget build(BuildContext context) {
    const double size = 18;
    return SizedBox(
      width: size,
      height: size,
      child: Transform.rotate(
        angle: -0.78,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: size * 0.9, height: size * 0.16, margin: const EdgeInsets.symmetric(vertical: 0.6), decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(2))),
            Container(width: size * 0.9, height: size * 0.16, margin: const EdgeInsets.symmetric(vertical: 0.6), decoration: BoxDecoration(color: const Color(0xFFFACC15), borderRadius: BorderRadius.circular(2))),
            Container(width: size * 0.9, height: size * 0.16, margin: const EdgeInsets.symmetric(vertical: 0.6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
          ],
        ),
      ),
    );
  }
}
