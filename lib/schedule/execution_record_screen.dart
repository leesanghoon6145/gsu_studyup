// ============================================================================
// 🆕 [일반 플래너 2단계] ExecutionRecordScreen
// 완료(status='completed')된 타임라인 블록 전체를 최신순으로 모아 보여줍니다.
// 계획시간/실제시간/차이가 한눈에 보이도록 정리되어, "내가 계획한 시간표를
// 실제로 얼마나 지켰는지" 되돌아보는 화면입니다. 실제 저장된 데이터만
// 표시하며(가짜 데이터 없음), 데이터가 없으면 빈 상태 안내만 보여줍니다.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'timeline_data_service.dart';

class ExecutionRecordScreen extends StatefulWidget {
  const ExecutionRecordScreen({super.key});

  @override
  State<ExecutionRecordScreen> createState() => _ExecutionRecordScreenState();
}

class _ExecutionRecordScreenState extends State<ExecutionRecordScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  List<TimelineBlock> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final records = await TimelineDataService.loadCompletedBlocks();
    if (!mounted) return;
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('EXECUTION RECORD', style: GoogleFonts.gowunBatang(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('실행 기록', style: GoogleFonts.notoSansKr(color: _brandGolden, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : _records.isEmpty
          ? Center(
        child: Text(
          '아직 완료된 실행 기록이 없습니다.\n타임라인에서 항목을 실행하고 완료하면\n여기에 자동으로 기록됩니다.',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 14),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _records.length,
        itemBuilder: (context, index) => _buildRecordTile(_records[index]),
      ),
    );
  }

  Widget _buildRecordTile(TimelineBlock block) {
    final int? diff = block.diffMinutes;
    final String diffText = diff == null
        ? '-'
        : (diff == 0 ? '정확히 맞춤' : (diff > 0 ? '+$diff분 초과' : '${diff.abs()}분 단축'));
    final Color diffColor = (diff == null || diff == 0)
        ? Colors.white54
        : (diff > 0 ? Colors.orangeAccent : Colors.lightGreenAccent);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _containerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(block.date, style: const TextStyle(color: _brandGolden, fontSize: 12, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('(${block.category})', style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Text(block.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Expanded(child: _buildStat('계획', '${block.plannedStart}~${block.plannedEnd}')),
                Expanded(child: _buildStat('실제', '${block.actualStart}~${block.actualEnd}')),
                Expanded(child: _buildStat('차이', diffText, color: diffColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10)),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
