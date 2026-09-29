// family_check_dialog.dart
//
// 🆕 [가족 활동 체크 2026-09-30] 운동할 시간이 없는 부모도 자녀를 위한 작은 노력을
// 체크해서 응원별을 모으는 팝업.
// - 모양: 자기주도 플래너 "알람 설정"과 같은 가운데 금테 팝업
//   (영문/한글 칸 제목, 왼쪽 아래 빨간 Delete / 삭제, 오른쪽 Close / 닫기 + 금색 Save / 저장)
// - 오늘 / 어제 고르기 (어제는 더하기만)
// - 4개 탭: 몸 활동 · 자녀와 마음 · 가족 활동 · 자기 관리
// - 모든 항목은 ＋/− 로 통일, 옆에 "별 +N" 바로 표시
// - 아래에 "오늘 체크 별 N / 20" 항상 고정
// - 응원 문자는 자동 인정(누를 수 없음)
// - 규칙·저장은 exercise_star_service.dart, 글자는 cheer_stars_i18n.dart (12개 언어)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/exercise_star_service.dart';
import 'app_language_service.dart';
import 'cheer_stars_i18n.dart';

/// 팝업 열기. 저장해서 별이 바뀌면 true를 돌려줌.
Future<bool> showFamilyCheckDialog(BuildContext context) async {
  final String todayKey = ExerciseStarService.dateKey(DateTime.now());
  final String yesterdayKey = ExerciseStarService.dateKey(DateTime.now().subtract(const Duration(days: 1)));
  final Map<String, int> todaySaved = await ExerciseStarService.getFamilyCheckDay(todayKey);
  final Map<String, int> yesterdaySaved = await ExerciseStarService.getFamilyCheckDay(yesterdayKey);
  if (!context.mounted) return false;
  final bool? changed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (_) => _FamilyCheckDialog(
      todayKey: todayKey,
      yesterdayKey: yesterdayKey,
      todaySaved: todaySaved,
      yesterdaySaved: yesterdaySaved,
    ),
  );
  return changed == true;
}

class _FamilyCheckDialog extends StatefulWidget {
  final String todayKey;
  final String yesterdayKey;
  final Map<String, int> todaySaved;
  final Map<String, int> yesterdaySaved;

  const _FamilyCheckDialog({
    required this.todayKey,
    required this.yesterdayKey,
    required this.todaySaved,
    required this.yesterdaySaved,
  });

  @override
  State<_FamilyCheckDialog> createState() => _FamilyCheckDialogState();
}

class _FamilyCheckDialogState extends State<_FamilyCheckDialog> {
  static const Color _gold = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _popupBg = Color(0xFF050B14);
  static const Color _fieldBg = Color(0xFF111827);
  static const Color _cream = Color(0xFFFFF6D6);

  static const Map<String, IconData> _groupIcons = {
    'body': Icons.directions_walk_rounded,
    'heart': Icons.favorite_rounded,
    'family': Icons.family_restroom_rounded,
    'self': Icons.spa_rounded,
  };

  static const Map<String, IconData> _itemIcons = {
    'walk': Icons.directions_walk_rounded,
    'stretch': Icons.accessibility_new_rounded,
    'stairs': Icons.stairs_rounded,
    'steps': Icons.directions_run_rounded,
    'cheerMsg': Icons.mark_chat_read_rounded,
    'talk': Icons.forum_rounded,
    'homework': Icons.menu_book_rounded,
    'praise': Icons.thumb_up_alt_rounded,
    'meal': Icons.restaurant_rounded,
    'familyWalk': Icons.hiking_rounded,
    'readTogether': Icons.auto_stories_rounded,
    'outing': Icons.park_rounded,
    'reading': Icons.chrome_reader_mode_rounded,
    'earlySleep': Icons.bedtime_rounded,
  };

  bool _isToday = true;
  String _group = 'body';
  bool _saving = false;
  String? _errorText;
  late Map<String, int> _todayUnits;
  late Map<String, int> _yesterdayUnits;

  @override
  void initState() {
    super.initState();
    _todayUnits = Map<String, int>.from(widget.todaySaved);
    _yesterdayUnits = Map<String, int>.from(widget.yesterdaySaved);
  }

  Map<String, int> get _units => _isToday ? _todayUnits : _yesterdayUnits;
  Map<String, int> get _saved => _isToday ? widget.todaySaved : widget.yesterdaySaved;
  int get _stars => ExerciseStarService.familyStarsOf(_units);
  int get _cap => ExerciseStarService.familyDailyCap;

  String _unitText(FamilyCheckItemDef item, int count) {
    return cs('fcUnit_${item.unitType}', args: {'n': item.unitSize * count});
  }

  bool _canPlus(FamilyCheckItemDef item) {
    if (item.auto || _saving) return false;
    final int u = _units[item.key] ?? 0;
    return u < item.maxUnits && _stars + item.starsPerUnit <= _cap;
  }

  bool _canMinus(FamilyCheckItemDef item) {
    if (item.auto || _saving) return false;
    final int u = _units[item.key] ?? 0;
    if (u <= 0) return false;
    if (!_isToday && u <= (_saved[item.key] ?? 0)) return false; // 어제는 더하기만
    return true;
  }

  void _change(FamilyCheckItemDef item, int diff) {
    setState(() {
      _errorText = null;
      _units[item.key] = ((_units[item.key] ?? 0) + diff).clamp(0, item.maxUnits).toInt();
    });
  }

  String _errorToText(String code) {
    if (code == 'fcErrLogin') return cs('errLogin');
    return cs(code);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _errorText = null;
    });
    final String dayKey = _isToday ? widget.todayKey : widget.yesterdayKey;
    final (int delta, String? error) = await ExerciseStarService.saveFamilyCheck(dayKey: dayKey, units: _units);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _errorText = _errorToText(error);
      });
      return;
    }
    final String msg = delta > 0
        ? cs('fcSaved', args: {'n': delta})
        : (delta < 0 ? cs('fcRemoved', args: {'n': -delta}) : cs('fcNoChange'));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.notoSansKr())));
    Navigator.of(context).pop(delta != 0);
  }

  Future<void> _clearToday() async {
    final bool? sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _popupBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _gold, width: 1.2)),
        title: Text(cs('fcClearTitle'), style: GoogleFonts.notoSansKr(color: _gold, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(cs('fcClearMsg'), style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, height: 1.6)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cs('btnCancel'), style: GoogleFonts.notoSansKr(color: Colors.white60, fontWeight: FontWeight.bold))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(cs('btnDel'), style: GoogleFonts.notoSansKr(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    setState(() {
      _isToday = true;
      for (final item in ExerciseStarService.familyCheckItems) {
        if (!item.auto) _todayUnits[item.key] = 0;
      }
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final double maxH = MediaQuery.of(context).size.height * 0.86;
    final bool isKo = appLanguage.isDefault;
    final bool hasTodaySaved = widget.todaySaved.entries.any((e) => e.key != 'cheerMsg' && e.value > 0);
    final List<FamilyCheckItemDef> items =
    ExerciseStarService.familyCheckItems.where((i) => i.group == _group).toList();
    final bool atLimit = _stars >= _cap;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          decoration: BoxDecoration(
            color: _popupBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _gold, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- 제목 ----------
              if (isKo) ...[
                Text('FAMILY CHECK', style: GoogleFonts.gowunBatang(color: _gold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
                Text(cs('fcTitle'), style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19)),
              ] else
                Text(cs('fcTitle'), style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 6),
              Text(cs('fcIntro'), style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 11.5, height: 1.5)),
              const SizedBox(height: 14),

              // ---------- 오늘 / 어제 ----------
              Row(
                children: [
                  Expanded(child: _dayChip(cs('fcToday'), _isToday, () => setState(() => _isToday = true))),
                  const SizedBox(width: 8),
                  Expanded(child: _dayChip(cs('fcYesterday'), !_isToday, () => setState(() => _isToday = false))),
                ],
              ),
              if (!_isToday) ...[
                const SizedBox(height: 6),
                Text(cs('fcYesterdayNote'), style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 11)),
              ],
              const SizedBox(height: 12),

              // ---------- 4개 탭 ----------
              Row(
                children: ExerciseStarService.familyGroups.map((g) {
                  final bool sel = _group == g;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: g == 'self' ? 0 : 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => _group = g),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          decoration: BoxDecoration(
                            color: sel ? _gold : _fieldBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: sel ? _gold : Colors.white12),
                          ),
                          child: Column(
                            children: [
                              Icon(_groupIcons[g], size: 18, color: sel ? _pageBg : _gold),
                              const SizedBox(height: 3),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  cs('grp_$g'),
                                  style: GoogleFonts.notoSansKr(color: sel ? _pageBg : Colors.white70, fontWeight: FontWeight.bold, fontSize: 11.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // ---------- 항목 목록 (이 부분만 스크롤) ----------
              Flexible(
                child: SingleChildScrollView(
                  child: Column(children: items.map(_itemRow).toList()),
                ),
              ),
              const SizedBox(height: 12),

              // ---------- 합계 (항상 고정) ----------
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cs('fcTotal', args: {'n': _stars, 'cap': _cap}),
                      style: GoogleFonts.notoSansKr(color: _cream, fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (_stars / _cap).clamp(0.0, 1.0).toDouble(),
                  minHeight: 8,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(atLimit ? const Color(0xFFFFD700) : _gold),
                ),
              ),
              if (atLimit) ...[
                const SizedBox(height: 4),
                Text(cs('fcLimit', args: {'cap': _cap}), style: GoogleFonts.notoSansKr(color: const Color(0xFFFFD700), fontSize: 11)),
              ],
              if (_errorText != null) ...[
                const SizedBox(height: 6),
                Text(_errorText!, style: GoogleFonts.notoSansKr(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
              const SizedBox(height: 14),

              // ---------- 아래 버튼 (알람 설정 팝업과 같은 배치) ----------
              Row(
                children: [
                  if (_isToday && hasTodaySaved)
                    Flexible(
                      child: TextButton(
                        onPressed: _saving ? null : _clearToday,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(cs('btnDelete'), style: GoogleFonts.notoSansKr(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                    child: Text(cs('btnClose'), style: GoogleFonts.notoSansKr(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      disabledBackgroundColor: const Color(0xFF1F2937),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      _saving ? cs('btnSaving') : cs('btnSave'),
                      style: GoogleFonts.notoSansKr(color: _pageBg, fontWeight: FontWeight.bold, fontSize: 15),
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

  Widget _dayChip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _saving ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _gold.withOpacity(0.18) : _fieldBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _gold : Colors.white12, width: selected ? 1.3 : 1),
        ),
        child: Text(label, style: GoogleFonts.notoSansKr(color: selected ? _gold : Colors.white60, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  Widget _itemRow(FamilyCheckItemDef item) {
    final int u = _units[item.key] ?? 0;
    final int starsHere = u * item.starsPerUnit;
    final String rule = item.auto
        ? cs('fcAuto', args: {'n': u, 'm': item.maxUnits})
        : cs('fcPerUnit', args: {'u': _unitText(item, 1), 's': item.starsPerUnit});

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: u > 0 ? _gold.withOpacity(0.55) : Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(_itemIcons[item.key] ?? Icons.star_outline_rounded, color: _gold, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cs('it_${item.key}'), style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(rule, style: GoogleFonts.notoSansKr(color: item.auto ? _gold.withOpacity(0.8) : Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          if (item.auto)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.lock_clock_rounded, color: _gold.withOpacity(0.7), size: 20),
            )
          else ...[
            _roundBtn(Icons.remove_rounded, _canMinus(item) ? () => _change(item, -1) : null),
            SizedBox(
              width: 58,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  u == 0 ? '0' : _unitText(item, u),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(color: u > 0 ? _cream : Colors.white38, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            _roundBtn(Icons.add_rounded, _canPlus(item) ? () => _change(item, 1) : null),
          ],
          SizedBox(
            width: 36,
            child: Text(
              starsHere > 0 ? '+$starsHere' : '',
              textAlign: TextAlign.right,
              style: GoogleFonts.notoSansKr(color: const Color(0xFFFFD700), fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback? onTap) {
    final bool enabled = onTap != null;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? _gold.withOpacity(0.15) : Colors.transparent,
          border: Border.all(color: enabled ? _gold : Colors.white12),
        ),
        child: Icon(icon, size: 18, color: enabled ? _gold : Colors.white24),
      ),
    );
  }
}
