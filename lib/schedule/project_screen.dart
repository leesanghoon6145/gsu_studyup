// ============================================================================
// 🆕 [일반 플래너] ProjectScreen (프로젝트)
// 프로젝트(제목/분야/마감일/상태)와 하위 작업을 관리합니다. 진행률은 연결된
// 작업 완료 비율로 실시간 계산됩니다. 캘린더/약속 화면과 동일한 골드 글로우
// 팝업 디자인과 영한 병기 규칙을 적용했습니다.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'project_data_service.dart';
import 'bilingual_text.dart';

class _StatusInfo {
  final String enLabel;
  final Color color;
  const _StatusInfo(this.enLabel, this.color);
}

const Map<String, _StatusInfo> kProjectStatuses = {
  '진행중': _StatusInfo('In Progress', Color(0xFF3B82F6)),
  '완료': _StatusInfo('Done', Color(0xFF22C55E)),
  '보류': _StatusInfo('On Hold', Color(0xFF9CA3AF)),
};

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  List<ProjectItem> _projects = [];
  Map<String, double> _progressCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final projects = await ProjectDataService.loadAll();
    final Map<String, double> progressMap = {};
    for (final p in projects) {
      progressMap[p.id] = await ProjectDataService.calcProgress(p.id);
    }
    if (!mounted) return;
    setState(() {
      _projects = projects;
      _progressCache = progressMap;
      _isLoading = false;
    });
  }

  int? _dDay(String deadline) {
    if (deadline.isEmpty) return null;
    final parts = deadline.split('-');
    if (parts.length != 3) return null;
    final target = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final now = DateTime.now();
    final todayZero = DateTime(now.year, now.month, now.day);
    return target.difference(todayZero).inDays;
  }

  Future<void> _showProjectDialog({ProjectItem? existing}) async {
    final bool isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final categoryCtrl = TextEditingController(text: existing?.category ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    DateTime? deadline = existing != null && existing.deadline.isNotEmpty ? DateTime.tryParse(existing.deadline) : null;
    String selectedStatus = existing?.status ?? '진행중';

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
                        Icon(isEdit ? Icons.edit_note_rounded : Icons.rocket_launch_rounded, color: _brandGolden, size: 22),
                        const SizedBox(width: 8),
                        BiTitle(en: isEdit ? 'EDIT PROJECT' : 'ADD PROJECT', ko: isEdit ? '프로젝트 수정' : '프로젝트 추가', enSize: 16, koSize: 12.5),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, _brandGolden.withOpacity(0.5), Colors.transparent]))),
                    const SizedBox(height: 18),

                    const BiInline(en: 'STATUS', ko: '상태', color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 12),
                    const SizedBox(height: 8),
                    Row(
                      children: kProjectStatuses.entries.map((entry) {
                        final bool isSel = selectedStatus == entry.key;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () => setDialogState(() => selectedStatus = entry.key),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: isSel ? entry.value.color.withOpacity(0.18) : _pageBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isSel ? entry.value.color : Colors.white12, width: isSel ? 1.4 : 1),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(width: 14, height: 14, decoration: BoxDecoration(color: entry.value.color, shape: BoxShape.circle)),
                                    const SizedBox(height: 6),
                                    Text(entry.value.enLabel, style: GoogleFonts.gowunBatang(color: isSel ? Colors.white70 : Colors.white38, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                    Text(entry.key, style: GoogleFonts.notoSansKr(color: isSel ? Colors.white : Colors.white54, fontSize: 10.5, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    _buildField(icon: Icons.title_rounded, controller: titleCtrl, hintEn: 'Title', hintKo: 'e.g. 신제품 기획'),
                    const SizedBox(height: 12),
                    _buildField(icon: Icons.category_outlined, controller: categoryCtrl, hintEn: 'Category', hintKo: '분야, 비워도 됨'),
                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 12), minimumSize: const Size(double.infinity, 0)),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: deadline ?? DateTime.now(),
                          firstDate: DateTime(DateTime.now().year - 1),
                          lastDate: DateTime(DateTime.now().year + 5),
                          builder: (ctx, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: _brandGolden, onPrimary: _pageBg, surface: _containerBg)), child: child!),
                        );
                        if (picked != null) setDialogState(() => deadline = picked);
                      },
                      icon: const Icon(Icons.event_rounded, color: _brandGolden, size: 16),
                      label: Text(
                        deadline != null ? 'Deadline (마감일): ${deadline!.year}.${deadline!.month.toString().padLeft(2, '0')}.${deadline!.day.toString().padLeft(2, '0')}' : biHint('Deadline', '마감일 선택, 선택 사항'),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildField(icon: Icons.notes_rounded, controller: descCtrl, hintEn: 'Description', hintKo: '설명, 선택 사항', maxLines: 3),

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
      await ProjectDataService.delete(existing.id);
      await _load();
      return;
    }

    if (action == 'save' && titleCtrl.text.trim().isNotEmpty) {
      final deadlineStr = deadline != null ? '${deadline!.year}-${deadline!.month.toString().padLeft(2, '0')}-${deadline!.day.toString().padLeft(2, '0')}' : '';

      if (isEdit) {
        final updated = ProjectItem(
          id: existing!.id,
          title: titleCtrl.text.trim(),
          category: categoryCtrl.text.trim().isEmpty ? '일반' : categoryCtrl.text.trim(),
          deadline: deadlineStr,
          status: selectedStatus,
          description: descCtrl.text.trim(),
          createdAt: existing.createdAt,
        );
        await ProjectDataService.update(updated);
      } else {
        final newItem = ProjectItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: titleCtrl.text.trim(),
          category: categoryCtrl.text.trim().isEmpty ? '일반' : categoryCtrl.text.trim(),
          deadline: deadlineStr,
          status: selectedStatus,
          description: descCtrl.text.trim(),
          createdAt: DateTime.now().toIso8601String(),
        );
        await ProjectDataService.add(newItem);
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

  Future<void> _showTasksSheet(ProjectItem project) async {
    final tasks = await ProjectDataService.loadTasksForProject(project.id);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: _containerBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BiInline(en: project.title, ko: '하위 작업', color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 15),
                const SizedBox(height: 12),
                if (tasks.isEmpty)
                  BiInline(en: 'No tasks yet', ko: '등록된 작업이 없습니다', color: Colors.white38, fontSize: 13)
                else
                  ...tasks.map((t) => CheckboxListTile(
                    value: t.isCompleted,
                    onChanged: (val) async {
                      t.isCompleted = val ?? false;
                      await ProjectDataService.updateTask(t);
                      setSheetState(() {});
                      await _load();
                    },
                    title: Text(t.title, style: TextStyle(color: t.isCompleted ? Colors.white38 : Colors.white, decoration: t.isCompleted ? TextDecoration.lineThrough : null)),
                    activeColor: _brandGolden,
                    checkColor: _pageBg,
                    controlAffinity: ListTileControlAffinity.leading,
                  )),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final controller = TextEditingController();
                    final added = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: _pageBg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const BiTitle(en: 'ADD TASK', ko: '작업 추가', enSize: 15, koSize: 12),
                        content: TextField(
                          controller: controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(hintText: biHint('Task', '작업 내용'), hintStyle: const TextStyle(color: Colors.white38), border: InputBorder.none),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const BiInline(en: 'Cancel', ko: '취소', color: Colors.white54)),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: _brandGolden),
                            onPressed: () {
                              if (controller.text.trim().isEmpty) return;
                              Navigator.pop(context, true);
                            },
                            child: const BiInline(en: 'Add', ko: '추가', color: _pageBg, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                    if (added == true && controller.text.trim().isNotEmpty) {
                      await ProjectDataService.addTask(ProjectTask(id: DateTime.now().microsecondsSinceEpoch.toString(), projectId: project.id, title: controller.text.trim()));
                      setSheetState(() {});
                      Navigator.pop(context);
                      await _load();
                    }
                  },
                  icon: const Icon(Icons.add, color: _brandGolden, size: 18),
                  label: const BiInline(en: 'Add Task', ko: '작업 추가', color: _brandGolden, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
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
        title: const BiTitle(en: 'PROJECT', ko: '프로젝트', enSize: 19, koSize: 14),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : _projects.isEmpty
          ? Center(child: BiInline(en: 'No projects yet', ko: '등록된 프로젝트가 없습니다', color: Colors.white38, fontSize: 14, textAlign: TextAlign.center))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _projects.length,
        itemBuilder: (context, index) => _buildProjectCard(_projects[index]),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _brandGolden,
        onPressed: () => _showProjectDialog(),
        child: const Icon(Icons.add, color: _pageBg),
      ),
    );
  }

  Widget _buildProjectCard(ProjectItem project) {
    final double progress = _progressCache[project.id] ?? 0.0;
    final int percent = (progress * 100).round();
    final statusInfo = kProjectStatuses[project.status] ?? const _StatusInfo('', Colors.white38);
    final int? dday = _dDay(project.deadline);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _brandGolden.withOpacity(0.25))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusInfo.color.withOpacity(0.18), borderRadius: BorderRadius.circular(6), border: Border.all(color: statusInfo.color)),
                child: Text('${statusInfo.enLabel} (${project.status})', style: TextStyle(color: statusInfo.color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              if (dday != null)
                Text(
                  dday == 0 ? 'D-DAY' : (dday > 0 ? 'D-$dday' : 'D+${dday.abs()}'),
                  style: TextStyle(color: dday <= 0 ? Colors.redAccent : _brandGolden, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              IconButton(icon: const _TriColorPencilIconMini2(), onPressed: () => _showProjectDialog(existing: project)),
            ],
          ),
          Text(project.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text('(${project.category})', style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation<Color>(_brandGolden)),
          ),
          const SizedBox(height: 6),
          Text('$percent% Complete (진행)', style: const TextStyle(color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(side: const BorderSide(color: _brandGolden), minimumSize: const Size(double.infinity, 0), padding: const EdgeInsets.symmetric(vertical: 10)),
            onPressed: () => _showTasksSheet(project),
            icon: const Icon(Icons.checklist, color: _brandGolden, size: 16),
            label: const BiInline(en: 'View Tasks', ko: '할 일 보기', color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _TriColorPencilIconMini2 extends StatelessWidget {
  const _TriColorPencilIconMini2();

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
