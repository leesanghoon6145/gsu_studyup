import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AiConsultingRoomScreen extends StatefulWidget {
  const AiConsultingRoomScreen({Key? key}) : super(key: key);

  @override
  State<AiConsultingRoomScreen> createState() => _AiConsultingRoomScreenState();
}

class _AiConsultingRoomScreenState extends State<AiConsultingRoomScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    // 👑 [자동 진단 인사말]: 제미나이 스타일의 깔끔한 가독성으로 출력
    _messages.add({
      'role': 'ai',
      'text': "반갑네, 학습자여. 자네가 이번 주에 땀 흘려 쌓아 올린 학업의 탑을 내가 먼저 정밀하게 들여다보았네.\n\n"
          "✦ 이번 주 총 학습 시간: 32시간 (전주 대비 15% 진격)\n"
          "✦ 과목별 집중도: 수학 60%, 영어 10%, 과학 30%\n"
          "✦ 주간 획득 영광의 별: 350개\n\n"
          "자네의 통계를 보니 수학의 기둥은 견고하나 영어의 탑이 다소 위태롭군. 현재 목표 달성을 향해 나아가는 과정에서 어떤 점이 가장 불안하고 답답한가? 아래에 자네의 고민을 솔직하게 적어보게나."
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  void _handleSendMessage() {
    if (_chatController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'text': _chatController.text,
      });

      _messages.add({
        'role': 'ai',
        'text': "수학에 집중하느라 영어 비율이 10%까지 떨어진 상황에서 '${_chatController.text}'와 같은 고민을 하고 있었군! 자네가 입력한 내용을 적극 반영하여 새로운 시간표를 처방하네.\n\n내일부터는 심야 타이머 가동 직후 최초 30분간은 무조건 영어 단어 탑을 먼저 쌓고 수학으로 넘어가게나. 내가 뒤에서 자네의 시간 전선을 늘 감시하고 수호하겠네.",
      });
    });

    _chatController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    const Color bgSpaceDark = Color(0xFF050B14);
    const Color cardSpaceDark = Color(0xFF0D1527);
    const Color textWhite = Color(0xFFEFEFEF);
    const Color brandGolden = Color(0xFFE5C158);

    return Scaffold(
      backgroundColor: bgSpaceDark,
      appBar: AppBar(
        backgroundColor: bgSpaceDark,
        elevation: 0,
        toolbarHeight: 75,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textWhite, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // 👑 [글꼴 교체 1]: 상단 타이틀을 제미나이 특유의 세련되고 꽉 찬 모던 고딕체로 전격 리폼
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "AI Real-time Consulting",
              style: GoogleFonts.roboto(color: textWhite, fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              "(AI 실시간 컨설팅방)",
              style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.3),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                physics: const BouncingScrollPhysics(),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isAi = msg['role'] == 'ai';

                  return Align(
                    alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: isAi ? cardSpaceDark : brandGolden.withOpacity(0.15),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(15),
                          topRight: const Radius.circular(15),
                          bottomLeft: Radius.circular(isAi ? 0 : 15),
                          bottomRight: Radius.circular(isAi ? 15 : 0),
                        ),
                        border: Border.all(
                          color: isAi ? brandGolden.withOpacity(0.4) : brandGolden,
                          width: 1,
                        ),
                      ),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                      // 👑 [글꼴 교체 2]: 말풍선 내부 텍스트를 지금 이 제미나이 답변창과 똑같은 Noto Sans 깔끔 서체로 변경
                      child: Text(
                        msg['text']!,
                        style: GoogleFonts.notoSansKr(
                          color: isAi ? textWhite : brandGolden,
                          fontSize: 14.0,
                          height: 1.5, // 줄간격도 제미나이처럼 시원하게 조정
                          fontWeight: isAi ? FontWeight.w400 : FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 하단 입력창 구역
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: const BoxDecoration(
                color: cardSpaceDark,
                border: Border(top: BorderSide(color: Colors.white10, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      // 👑 [글꼴 교체 3]: 유저가 타자 치는 텍스트와 힌트까지 제미나이 폰트로 통일
                      style: GoogleFonts.notoSansKr(color: textWhite, fontSize: 14),
                      onTap: () {
                        Future.delayed(const Duration(milliseconds: 200), _scrollToBottom);
                      },
                      decoration: InputDecoration(
                        hintText: "고민을 타자로 입력하게나...",
                        hintStyle: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 13),
                        filled: true,
                        fillColor: bgSpaceDark,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: brandGolden.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(color: brandGolden),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: brandGolden, size: 28),
                    onPressed: _handleSendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}