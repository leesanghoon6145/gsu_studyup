import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/family_link_service.dart';
import 'star_economy.dart';

// 🧪 [테스트 전용 화면] 학생-부모 서로 다른 기기 연결이 실제로 되는지 확인하기 위한 화면.
// 실제 학습 데이터 연결이 확인되면, 이 화면 대신 진짜 화면으로 교체 예정.
class FamilyLinkTestScreen extends StatefulWidget {
  const FamilyLinkTestScreen({super.key});

  @override
  State<FamilyLinkTestScreen> createState() => _FamilyLinkTestScreenState();
}

class _FamilyLinkTestScreenState extends State<FamilyLinkTestScreen> {
  bool _isParentMode = false;
  String? _studentCode; // 👑 [수정] 탭 전환해도 사라지지 않도록 최상위에서 코드 관리

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: const Color(0xFF030712),
        title: const Text('연결 테스트', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 학생 모드 / 부모 모드 전환 스위치
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('학생 모드'),
                    selected: !_isParentMode,
                    onSelected: (_) => setState(() => _isParentMode = false),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('부모 모드'),
                    selected: _isParentMode,
                    onSelected: (_) => setState(() => _isParentMode = true),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Expanded(
                child: _isParentMode
                    ? const _ParentSide()
                    : _StudentSide(
                  code: _studentCode,
                  onCodeGenerated: (c) => setState(() => _studentCode = c),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------
// 학생 쪽 화면
// -----------------------------
class _StudentSide extends StatefulWidget {
  final String? code;
  final ValueChanged<String> onCodeGenerated;
  const _StudentSide({required this.code, required this.onCodeGenerated});

  @override
  State<_StudentSide> createState() => _StudentSideState();
}

class _StudentSideState extends State<_StudentSide> {
  bool _loading = false;

  Future<void> _makeCode() async {
    setState(() => _loading = true);
    final code = await FamilyLinkService.generateLinkCode();
    widget.onCodeGenerated(code);
    setState(() => _loading = false);
  }

  Future<void> _sendMessage() async {
    if (widget.code == null) return;
    await FamilyLinkService.sendTestMessage(
      widget.code!,
      '테스트 성공! 지금 시각: ${DateTime.now().hour}시 ${DateTime.now().minute}분',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('부모 화면으로 메시지를 보냈습니다!')),
      );
    }
  }

  // 🆕 [실제 데이터 테스트] 별 50개를 실제로 적립 → DkeStars.addStars()가
  // 자동으로 Firestore에도 올려줌 (family_link_code가 저장돼 있어야 함, 즉 코드 생성 후 바로 됨)
  Future<void> _addRealStars() async {
    final newTotal = await DkeStars.addStars(50, subject: '수학');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('별 50개 적립! (전체 누적: $newTotal개) → 부모 화면 자동 반영')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.code == null) ...[
            const Text(
              '학생용: 아래 버튼을 눌러 코드를 생성하세요',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _makeCode,
              child: Text(_loading ? '생성 중...' : '코드 생성'),
            ),
          ] else ...[
            const Text('이 코드를 부모님 폰에 입력하세요', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            Text(
              widget.code!,
              style: const TextStyle(
                color: Color(0xFFE5C158),
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _sendMessage,
              child: const Text('테스트 메시지 보내기'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _addRealStars,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5C158)),
              child: const Text('⭐ 별 50개 실제 적립 (진짜 데이터 테스트)'),
            ),
          ],
        ],
      ),
    );
  }
}

// -----------------------------
// 부모 쪽 화면 (최대 5명 자녀 지원)
// -----------------------------
class _ParentSide extends StatefulWidget {
  const _ParentSide();

  @override
  State<_ParentSide> createState() => _ParentSideState();
}

class _ParentSideState extends State<_ParentSide> {
  final TextEditingController _controller = TextEditingController();
  List<String> _linkedCodes = [];
  String? _errorText;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadLinkedCodes();
  }

  Future<void> _loadLinkedCodes() async {
    final codes = await FamilyLinkService.getLinkedCodes();
    setState(() {
      _linkedCodes = codes;
      _loaded = true;
    });
  }

  Future<void> _connect() async {
    final code = _controller.text.trim();
    if (code.length != 6) {
      setState(() => _errorText = '6자리 숫자를 입력하세요');
      return;
    }
    if (_linkedCodes.length >= FamilyLinkService.maxChildren) {
      setState(() => _errorText = '최대 ${FamilyLinkService.maxChildren}명까지만 연결할 수 있습니다');
      return;
    }
    final ok = await FamilyLinkService.connectWithCode(code);
    if (ok) {
      _controller.clear();
      setState(() => _errorText = null);
      await _loadLinkedCodes();
    } else {
      setState(() => _errorText = '존재하지 않는 코드입니다');
    }
  }

  Future<void> _remove(String code) async {
    await FamilyLinkService.removeLinkedCode(code);
    await _loadLinkedCodes();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // 자녀 추가 입력창 (5명 미만일 때만 표시)
        if (_linkedCodes.length < FamilyLinkService.maxChildren) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '자녀 코드 입력 (${_linkedCodes.length}/${FamilyLinkService.maxChildren})',
                    errorText: _errorText,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _connect, child: const Text('연결')),
            ],
          ),
          const SizedBox(height: 16),
        ] else ...[
          const Text('자녀 5명이 모두 연결되었습니다', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 16),
        ],

        // 연결된 자녀 목록
        Expanded(
          child: _linkedCodes.isEmpty
              ? const Center(
            child: Text('아직 연결된 자녀가 없습니다', style: TextStyle(color: Colors.white54)),
          )
              : ListView.builder(
            itemCount: _linkedCodes.length,
            itemBuilder: (context, index) {
              final code = _linkedCodes[index];
              return _ChildCard(code: code, onRemove: () => _remove(code));
            },
          ),
        ),
      ],
    );
  }
}

// 자녀 1명의 실시간 데이터를 보여주는 카드
class _ChildCard extends StatelessWidget {
  final String code;
  final VoidCallback onRemove;
  const _ChildCard({required this.code, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FamilyLinkService.watch(code),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final totalStars = data?['totalStars'];
        final todayStars = data?['todayStars'];
        final level = data?['level'];
        return Card(
          color: const Color(0xFF0D1527),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('코드: $code', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 6),
                      if (totalStars != null) ...[
                        Text('⭐ 전체 누적: $totalStars개',
                            style: const TextStyle(color: Color(0xFFE5C158), fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('오늘: $todayStars개  |  레벨: $level',
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ] else
                        const Text('(아직 학습 데이터 없음)', style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                  onPressed: onRemove,
                  tooltip: '연결 해제',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
