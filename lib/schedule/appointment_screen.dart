// ============================================================================
// 🆕 [일반 플래너] AppointmentScreen (약속)
// 약속(누구와, 언제, 어디서) 목록을 시간순으로 보여줍니다. 캘린더 화면과
// 동일한 고급 팝업 디자인(골드 글로우 테두리)과 영한 병기 규칙을 적용했습니다.
//
// ✅ [수정 완료] 저장된 약속을 실제 푸시 알림(NotificationService)으로 발송하는
// 기능을 연결했습니다. 시간이 설정된 약속만 추가/수정 시 scheduleAt(), 삭제 시
// cancel() 호출. (다른 로직/디자인/다국어는 전혀 변경하지 않았습니다)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'appointment_data_service.dart';
import 'bilingual_text.dart';
import 'notification_service.dart'; // 🆕 [권한 안내 배너 + 알림 예약/취소]

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  List<AppointmentItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final items = await AppointmentDataService.loadAll();
    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _toggleComplete(AppointmentItem item) async {
    item.isCompleted = !item.isCompleted;
    await AppointmentDataService.update(item);
    await _load();
  }

  Future<void> _showDialog({AppointmentItem? existing}) async {
    final bool isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final personCtrl = TextEditingController(text: existing?.withPerson ?? '');
    final locationCtrl = TextEditingController(text: existing?.location ?? '');
    final memoCtrl = TextEditingController(text: existing?.memo ?? '');
    DateTime selectedDate = existing != null && existing.date.isNotEmpty
        ? DateTime.tryParse(existing.date) ?? DateTime.now()
        : DateTime.now();
    TimeOfDay? selectedTime = existing != null && existing.time.contains(':')
        ? TimeOfDay(hour: int.parse(existing.time.split(':')[0]), minute: int.parse(existing.time.split(':')[1]))
        : null;

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
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF11192E), Color(0xFF0A0F1E)],
                ),
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
                        Icon(isEdit ? Icons.edit_calendar_rounded : Icons.handshake_rounded, color: _brandGolden, size: 22),
                        const SizedBox(width: 8),
                        BiTitle(
                          en: isEdit ? 'EDIT APPOINTMENT' : 'ADD APPOINTMENT',
                          ko: isEdit ? '약속 수정' : '약속 추가',
                          enSize: 16,
                          koSize: 12.5,
                          translations: isEdit
                              ? {'JA': '約束を編集', 'ZH': '编辑约会', 'FR': 'Modifier le rendez-vous', 'DE': 'Termin bearbeiten', 'RU': 'Изменить встречу', 'AR': 'تعديل الموعد', 'HI': 'नियुक्ति संपादित करें', 'VI': 'Sửa cuộc hẹn', 'ES': 'Editar cita', 'TH': 'แก้ไขนัดหมาย'}
                              : {'JA': '約束を追加', 'ZH': '添加约会', 'FR': 'Ajouter un rendez-vous', 'DE': 'Termin hinzufügen', 'RU': 'Добавить встречу', 'AR': 'إضافة موعد', 'HI': 'नियुक्ति जोड़ें', 'VI': 'Thêm cuộc hẹn', 'ES': 'Añadir cita', 'TH': 'เพิ่มนัดหมาย'},
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.transparent, _brandGolden.withOpacity(0.5), Colors.transparent]),
                      ),
                    ),
                    const SizedBox(height: 18),

                    _buildField(icon: Icons.title_rounded, controller: titleCtrl, hintEn: 'Title', hintKo: 'e.g. 동창 모임'),
                    const SizedBox(height: 12),
                    _buildField(icon: Icons.person_outline_rounded, controller: personCtrl, hintEn: 'With', hintKo: '누구와 (예: 김철수)'),
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
                                builder: (ctx, child) => Theme(
                                  data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: _brandGolden, onPrimary: _pageBg, surface: _containerBg)),
                                  child: child!,
                                ),
                              );
                              if (picked != null) setDialogState(() => selectedDate = picked);
                            },
                            icon: const Icon(Icons.calendar_today, color: _brandGolden, size: 15),
                            label: Text('${selectedDate.year}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime ?? TimeOfDay.now(),
                              );
                              if (picked != null) setDialogState(() => selectedTime = picked);
                            },
                            icon: const Icon(Icons.access_time, color: _brandGolden, size: 15),
                            label: Text(
                              selectedTime != null
                                  ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                                  : biHint('Time', '시간'),
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildField(icon: Icons.place_outlined, controller: locationCtrl, hintEn: 'Location', hintKo: '장소, 비워도 됨'),
                    const SizedBox(height: 12),
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
      await AppointmentDataService.delete(existing.id);
      await NotificationService.cancel(existing.id); // 🆕 [알림 연동] 삭제 시 예약된 알람도 취소
      await _load();
      return;
    }

    if (action == 'save' && titleCtrl.text.trim().isNotEmpty) {
      final dateKey = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      final timeStr = selectedTime != null ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}' : '';

      if (isEdit) {
        final updated = AppointmentItem(
          id: existing!.id,
          title: titleCtrl.text.trim(),
          withPerson: personCtrl.text.trim(),
          date: dateKey,
          time: timeStr,
          location: locationCtrl.text.trim(),
          memo: memoCtrl.text.trim(),
          isCompleted: existing.isCompleted,
        );
        await AppointmentDataService.update(updated);
        // 🆕 [알림 연동] 시간이 설정되어 있으면 알람 재예약, 시간이 없으면 취소
        if (updated.time.isNotEmpty) {
          await NotificationService.scheduleAt(
            id: updated.id,
            title: updated.title,
            body: updated.location.isNotEmpty ? '${updated.withPerson} · ${updated.location}' : updated.withPerson,
            date: updated.date,
            time: updated.time,
          );
        } else {
          await NotificationService.cancel(updated.id);
        }
      } else {
        final newItem = AppointmentItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: titleCtrl.text.trim(),
          withPerson: personCtrl.text.trim(),
          date: dateKey,
          time: timeStr,
          location: locationCtrl.text.trim(),
          memo: memoCtrl.text.trim(),
        );
        await AppointmentDataService.add(newItem);
        // 🆕 [알림 연동] 시간이 설정된 약속만 알람 예약
        if (newItem.time.isNotEmpty) {
          await NotificationService.scheduleAt(
            id: newItem.id,
            title: newItem.title,
            body: newItem.location.isNotEmpty ? '${newItem.withPerson} · ${newItem.location}' : newItem.withPerson,
            date: newItem.date,
            time: newItem.time,
          );
        }
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
        title: BiTitle(
          en: 'APPOINTMENT', ko: '약속', enSize: 19, koSize: 14,
          translations: const {'JA': '約束', 'ZH': '约会', 'FR': 'Rendez-vous', 'DE': 'Termin', 'RU': 'Встреча', 'AR': 'موعد', 'HI': 'नियुक्ति', 'VI': 'Cuộc hẹn', 'ES': 'Cita', 'TH': 'นัดหมาย'},
        ),
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
                  ? Center(
                child: BiInline(
                  en: 'No appointments yet', ko: '등록된 약속이 없습니다', color: Colors.white38, fontSize: 14, textAlign: TextAlign.center,
                  translations: const {'JA': 'まだ約束がありません', 'ZH': '暂无约会', 'FR': 'Aucun rendez-vous pour le moment', 'DE': 'Noch keine Termine', 'RU': 'Пока нет встреч', 'AR': 'لا توجد مواعيد بعد', 'HI': 'अभी तक कोई नियुक्ति नहीं', 'VI': 'Chưa có cuộc hẹn nào', 'ES': 'Aún no hay citas', 'TH': 'ยังไม่มีนัดหมาย'},
                ),
              )
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

  Widget _buildTile(AppointmentItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _brandGolden.withOpacity(0.25))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _toggleComplete(item),
            child: Icon(item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, color: item.isCompleted ? _brandGolden : Colors.white38, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        item.time.isNotEmpty ? '${item.date} ${item.time}' : item.date,
                        style: const TextStyle(color: _brandGolden, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  style: TextStyle(
                    color: item.isCompleted ? Colors.white38 : Colors.white,
                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (item.withPerson.isNotEmpty || item.location.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        if (item.withPerson.isNotEmpty) ...[
                          const Icon(Icons.person_outline_rounded, color: Colors.white38, size: 13),
                          const SizedBox(width: 3),
                          Text(item.withPerson, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(width: 10),
                        ],
                        if (item.location.isNotEmpty) ...[
                          const Icon(Icons.place_outlined, color: Colors.white38, size: 13),
                          const SizedBox(width: 3),
                          Text(item.location, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const ThreeColorPencilIcon(size: 22),
            onPressed: () => _showDialog(existing: item),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48), // 🆕 [터치범위 확대]
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }
}

// 🆕 캘린더와 동일한 3선 연필 아이콘 (파랑/노랑/흰색)
// (연필 아이콘은 bilingual_text.dart의 ThreeColorPencilIcon으로 통일됨)
