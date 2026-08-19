// ============================================================================
// 🆕 [일반 플래너] ReminderScreen (알림)
// 알림 목록을 관리합니다(추가/수정/삭제/켜짐끄짐 토글). 반복 유형(한번/매일/매주)
// 선택 가능. 캘린더/약속/프로젝트와 동일한 골드 글로우 팝업 디자인 + 영한 병기.
//
// ✅ [수정 완료] 저장된 알림을 실제 푸시 알림(NotificationService)으로 발송하는
// 기능을 연결했습니다. 추가/수정 시 scheduleAt(), 삭제/끄기 시 cancel() 호출.
// (다른 로직/디자인/다국어는 전혀 변경하지 않았습니다)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🆕 [2026-08-16 추가] 알람 안내 팝업 확인여부/시간선택 저장용
import 'reminder_data_service.dart';
import 'bilingual_text.dart';
import 'notification_service.dart'; // 🆕 [권한 안내 배너 + 알림 예약/취소]
import 'reminder_watcher_service.dart'; // 🆕 [2026-08-16 우회로] 예약 자동발동 실패 문제로 직접 감시하는 방식 추가

class _RepeatOption {
  final String enLabel;
  const _RepeatOption(this.enLabel);
}

const Map<String, _RepeatOption> kRepeatOptions = {
  '한번': _RepeatOption('Once'),
  '매일': _RepeatOption('Daily'),
  '매주': _RepeatOption('Weekly'),
};

// ✅ [2026-08-16 추가] 요일 다중선택 UI에 쓰이는 라벨 (DateTime.weekday 기준: 월=1~일=7)
const Map<int, String> _kWeekdayLabels = {
  1: '월',
  2: '화',
  3: '수',
  4: '목',
  5: '금',
  6: '토',
  7: '일',
};

// ✅ [2026-08-16 추가] 저장된 weekdays 문자열("2,5" 등)을 편집 화면 초기값으로
// 변환. 비어있으면(예전 데이터) date의 요일 하나만 담아서 예전 방식대로 보여줌.
Set<int> _parseWeekdaysForEdit(String weekdays, String fallbackDate) {
  if (weekdays.trim().isEmpty) {
    final DateTime? d = DateTime.tryParse(fallbackDate);
    return d != null ? {d.weekday} : {DateTime.now().weekday};
  }
  final parsed = weekdays
      .split(',')
      .map((s) => int.tryParse(s.trim()))
      .where((v) => v != null && v >= 1 && v <= 7)
      .map((v) => v!)
      .toSet();
  return parsed.isEmpty ? {DateTime.now().weekday} : parsed;
}

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
    ReminderWatcherService.instance.start(); // 🆕 [2026-08-16 우회로] 예약 자동발동 대신 직접 감시 시작
    WidgetsBinding.instance.addPostFrameCallback((_) => _showAlarmOnboardingIfNeeded()); // 🆕 [2026-08-16 추가] 첫 진입 시 알람 안내 팝업
  }

  // 🆕 [2026-08-16 추가] 리마인더 화면에 처음 들어왔을 때 딱 한 번, 반복
  // 알람의 특성(직접 앱에서 꺼야 함)을 정중하게 안내하고, 안전 정지 시간을
  // 사용자가 직접 고르게 하는 팝업. 한 번 확인하면 다시 안 뜹니다.
  static const String _onboardingShownKey = 'gke_alarm_onboarding_shown_v1';

  Future<void> _showAlarmOnboardingIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final bool alreadyShown = prefs.getBool(_onboardingShownKey) ?? false;
    if (alreadyShown) return;
    if (!mounted) return;

    int selectedMinutes = 1;

    await showDialog<void>(
      context: context,
      barrierDismissible: false, // 🆕 반드시 아래 버튼으로 확인해야 닫힘 (뒤로가기/바깥 탭으로 못 닫음)
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return PopScope(
            canPop: false, // 🆕 뒤로가기 버튼으로도 못 닫게 함
            child: Dialog(
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
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_active_rounded, color: _brandGolden, size: 24),
                          const SizedBox(width: 8),
                          Text('학습 알람 안내', style: GoogleFonts.notoSansKr(color: _brandGolden, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, _brandGolden.withOpacity(0.5), Colors.transparent]))),
                      const SizedBox(height: 18),
                      Text(
                        '설정하신 시각이 되면, 학습 알람이 정성껏 울려드립니다.\n\n'
                            '이 알람은 스스로 멈추지 않고 계속 이어지며, 화면에 나타나는 붉은색 "지금 울리는 알람 끄기" 버튼을 눌러주셔야 비로소 멈춥니다. 알림창을 통해서는 꺼지지 않으니, 이 점 미리 헤아려주시기 바랍니다.\n\n'
                            '혹시 곧바로 손이 닿지 않는 상황을 대비하여, 알람이 스스로 멈추는 시간을 아래에서 미리 정해두실 수 있습니다.',
                        style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 12.5, height: 1.6),
                      ),
                      const SizedBox(height: 20),
                      Text('안전 정지 시간', style: GoogleFonts.notoSansKr(color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setDialogState(() => selectedMinutes = 1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selectedMinutes == 1 ? _brandGolden.withOpacity(0.18) : _pageBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: selectedMinutes == 1 ? _brandGolden : Colors.white12, width: selectedMinutes == 1 ? 1.4 : 1),
                                ),
                                child: Text('1분 후', style: GoogleFonts.notoSansKr(color: selectedMinutes == 1 ? Colors.white : Colors.white54, fontSize: 13, fontWeight: selectedMinutes == 1 ? FontWeight.bold : FontWeight.normal)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setDialogState(() => selectedMinutes = 5),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selectedMinutes == 5 ? _brandGolden.withOpacity(0.18) : _pageBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: selectedMinutes == 5 ? _brandGolden : Colors.white12, width: selectedMinutes == 5 ? 1.4 : 1),
                                ),
                                child: Text('5분 후', style: GoogleFonts.notoSansKr(color: selectedMinutes == 5 ? Colors.white : Colors.white54, fontSize: 13, fontWeight: selectedMinutes == 5 ? FontWeight.bold : FontWeight.normal)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: _brandGolden, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 4, shadowColor: _brandGolden.withOpacity(0.5)),
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setInt(NotificationService.prefsAlarmRingMinutesKey, selectedMinutes);
                            await prefs.setBool(_onboardingShownKey, true);
                            if (context.mounted) Navigator.of(context).pop();
                          },
                          child: Text('안내를 확인했습니다', style: GoogleFonts.notoSansKr(color: _pageBg, fontSize: 13.5, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
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
    // 🆕 [알림 연동] 켜짐/꺼짐에 따라 실제 알람도 예약/취소
    if (item.isEnabled) {
      await NotificationService.scheduleAt(
        id: item.id,
        title: item.title,
        body: item.memo.isNotEmpty ? item.memo : item.title,
        date: item.date,
        time: item.time,
        repeatType: item.repeatType,
      );
    } else {
      await NotificationService.cancel(item.id);
    }
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
    // ✅ [2026-08-16 추가] '매주' 선택 시 여러 요일(월화수목금토일)을 고를 수 있는 상태.
    // 기존 항목을 수정하는 경우, 저장된 weekdays를 파싱해서 미리 체크해둠.
    // weekdays가 비어있으면(예전 데이터) 원래 날짜의 요일 하나만 자동으로 체크됨.
    Set<int> selectedWeekdays = existing != null
        ? _parseWeekdaysForEdit(existing.weekdays, existing.date)
        : {selectedDate.weekday};

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
                        BiTitle(
                          en: isEdit ? 'EDIT REMINDER' : 'ADD REMINDER', ko: isEdit ? '알림 수정' : '알림 추가', enSize: 16, koSize: 12.5,
                          translations: isEdit
                              ? {'JA': 'リマインダーを編集', 'ZH': '编辑提醒', 'FR': 'Modifier le rappel', 'DE': 'Erinnerung bearbeiten', 'RU': 'Изменить напоминание', 'AR': 'تعديل التذكير', 'HI': 'रिमाइंडर संपादित करें', 'VI': 'Sửa nhắc nhở', 'ES': 'Editar recordatorio', 'TH': 'แก้ไขการแจ้งเตือน'}
                              : {'JA': 'リマインダーを追加', 'ZH': '添加提醒', 'FR': 'Ajouter un rappel', 'DE': 'Erinnerung hinzufügen', 'RU': 'Добавить напоминание', 'AR': 'إضافة تذكير', 'HI': 'रिमाइंडर जोड़ें', 'VI': 'Thêm nhắc nhở', 'ES': 'Añadir recordatorio', 'TH': 'เพิ่มการแจ้งเตือน'},
                        ),
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

                    BiInline(
                      en: 'REPEAT', ko: '반복', color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 12,
                      translations: const {'JA': '繰り返し', 'ZH': '重复', 'FR': 'Répéter', 'DE': 'Wiederholen', 'RU': 'Повтор', 'AR': 'تكرار', 'HI': 'दोहराएं', 'VI': 'Lặp lại', 'ES': 'Repetir', 'TH': 'ทำซ้ำ'},
                    ),
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

                    // ✅ [2026-08-16 추가] '매주' 선택 시에만 나타나는 요일 다중선택.
                    // 예: 화요일 + 금요일처럼 여러 요일을 함께 고를 수 있음.
                    if (selectedRepeat == '매주') ...[
                      const SizedBox(height: 14),
                      BiInline(
                        en: 'REPEAT ON', ko: '반복 요일', color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 12,
                        translations: const {'JA': '繰り返す曜日', 'ZH': '重复星期', 'FR': 'Jours de répétition', 'DE': 'Wiederholungstage', 'RU': 'Дни повтора', 'AR': 'أيام التكرار', 'HI': 'दोहराने के दिन', 'VI': 'Ngày lặp lại', 'ES': 'Días de repetición', 'TH': 'วันที่ทำซ้ำ'},
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: _kWeekdayLabels.entries.map((entry) {
                          final int wd = entry.key;
                          final bool isSel = selectedWeekdays.contains(wd);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: GestureDetector(
                                onTap: () => setDialogState(() {
                                  if (isSel) {
                                    // 마지막 하나 남은 요일은 해제 못 하게 함 (최소 1개는 있어야 함)
                                    if (selectedWeekdays.length > 1) selectedWeekdays.remove(wd);
                                  } else {
                                    selectedWeekdays.add(wd);
                                  }
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSel ? _brandGolden.withOpacity(0.18) : _pageBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isSel ? _brandGolden : Colors.white12, width: isSel ? 1.4 : 1),
                                  ),
                                  child: Text(
                                    entry.value,
                                    style: GoogleFonts.notoSansKr(color: isSel ? Colors.white : Colors.white54, fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

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
      await NotificationService.cancel(existing.id); // 🆕 [알림 연동] 삭제 시 예약된 알람도 취소
      await _load();
      return;
    }

    if (action == 'save' && titleCtrl.text.trim().isNotEmpty) {
      final dateKey = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      final timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      // ✅ [2026-08-16 추가] '매주'일 때만 선택한 요일들을 "2,5" 형태 문자열로 저장. 그 외에는 빈 문자열.
      final String weekdaysStr = selectedRepeat == '매주' ? (selectedWeekdays.toList()..sort()).join(',') : '';

      if (isEdit) {
        final updated = ReminderItem(
          id: existing!.id,
          title: titleCtrl.text.trim(),
          date: dateKey,
          time: timeStr,
          repeatType: selectedRepeat,
          isEnabled: existing.isEnabled,
          memo: memoCtrl.text.trim(),
          weekdays: weekdaysStr,
        );
        await ReminderDataService.update(updated);
        // 🆕 [알림 연동] 수정된 내용으로 알람 재예약 (켜져 있을 때만, 꺼져있으면 취소)
        if (updated.isEnabled) {
          await NotificationService.scheduleAt(
            id: updated.id,
            title: updated.title,
            body: updated.memo.isNotEmpty ? updated.memo : updated.title,
            date: updated.date,
            time: updated.time,
            repeatType: updated.repeatType,
          );
        } else {
          await NotificationService.cancel(updated.id);
        }
      } else {
        final newItem = ReminderItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: titleCtrl.text.trim(),
          date: dateKey,
          time: timeStr,
          repeatType: selectedRepeat,
          memo: memoCtrl.text.trim(),
          weekdays: weekdaysStr,
        );
        await ReminderDataService.add(newItem);
        // 🆕 [알림 연동] 새로 추가된 알림을 실제 알람으로 예약
        await NotificationService.scheduleAt(
          id: newItem.id,
          title: newItem.title,
          body: newItem.memo.isNotEmpty ? newItem.memo : newItem.title,
          date: newItem.date,
          time: newItem.time,
          repeatType: newItem.repeatType,
        );
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
          en: 'REMINDER', ko: '알림', enSize: 19, koSize: 14,
          translations: const {'JA': 'リマインダー', 'ZH': '提醒', 'FR': 'Rappel', 'DE': 'Erinnerung', 'RU': 'Напоминание', 'AR': 'تذكير', 'HI': 'रिमाइंडर', 'VI': 'Nhắc nhở', 'ES': 'Recordatorio', 'TH': 'การแจ้งเตือน'},
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : Padding(
        padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
        child: Column(
          children: [
            const RingingAlarmStopBanner(), // 🆕 [2026-08-16 추가] 지금 울리는 알람을 확실하게 끄는 버튼, 울릴 때만 보임
            const NotificationPermissionBanner(), // 🆕 [권한 안내 배너] 알림이 꺼져있으면 여기 안내가 뜸
            // ✅ [2026-08-16 제거] 진단용 테스트 버튼(30초 예약 테스트, 즉시 알림, 60초 영어전용 테스트)은
            // 원인 파악용이었고 실제 해결책(우회로 감시자 + 안내 팝업)이 완성되어 더 이상 필요 없어져서 제거함.
            Expanded(
              child: _items.isEmpty
                  ? Center(
                child: BiInline(
                  en: 'No reminders yet', ko: '등록된 알림이 없습니다', color: Colors.white38, fontSize: 14, textAlign: TextAlign.center,
                  translations: const {'JA': 'まだリマインダーがありません', 'ZH': '暂无提醒', 'FR': 'Aucun rappel pour le moment', 'DE': 'Noch keine Erinnerungen', 'RU': 'Пока нет напоминаний', 'AR': 'لا توجد تذكيرات بعد', 'HI': 'अभी तक कोई रिमाइंडर नहीं', 'VI': 'Chưa có nhắc nhở nào', 'ES': 'Aún no hay recordatorios', 'TH': 'ยังไม่มีการแจ้งเตือน'},
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
          IconButton(icon: const ThreeColorPencilIcon(size: 20), onPressed: () => _showDialog(existing: item)),
        ],
      ),
    );
  }
}

// (자체 연필 아이콘 정의는 제거하고 calendar_screen.dart의 공용 TriColorPencilIcon을 사용합니다)
