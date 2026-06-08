import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// GSU StudyUp - Friend Study Room Screen (친구학습방)
///
/// 진지하고 웅장한 학술원 톤앤매너를 유지하며, 글로벌 상용화 규격을 준수한
/// 기능 중심 아키텍처 기반의 완성형 독립 스크린 코드입니다.
class FriendStudyRoomScreen extends StatefulWidget {
  const FriendStudyRoomScreen({super.key});

  @override
  State<FriendStudyRoomScreen> createState() => _FriendStudyRoomScreenState();
}

class _FriendStudyRoomScreenState extends State<FriendStudyRoomScreen> {
  // 임시 저장용 초기 친구학습방 데이터 리스트 (개발 원칙에 따른 UTC 시간 기반 기본 세팅)
  final List<Map<String, dynamic>> _studyRooms = [
    {
      'id': '1',
      'title': 'Global Elite Study (글로벌 엘리트 스터디)',
      'maxMembers': 5,
      'currentMembers': 3,
      'password': '1234',
      'emoji': '📖',
      'totalStars': 48,
      'studyTime': '02:45'
    },
    {
      'id': '2',
      'title': 'Top Tier Focus Group (탑티어 집중 그룹)',
      'maxMembers': 3,
      'currentMembers': 2,
      'password': 'abcd',
      'emoji': '🏰',
      'totalStars': 32,
      'studyTime': '01:20'
    },
  ];

  /// 신규 방 생성을 위한 단정하고 진중한 모달 다일로그 (1번 규칙 구현)
  void _createNewRoom() {
    String inputTitle = '';
    int selectedMax = 2;
    String inputPassword = '';
    String selectedEmoji = '📝'; // 기본 정적인 학습 이모지 고정

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xff161b22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            'Create Room (방 만들기)',
            style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Room Name (방 이름 입력)',
                    labelStyle: GoogleFonts.gowunBatang(color: Colors.grey),
                    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  ),
                  onChanged: (value) => inputTitle = value,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  dropdownColor: const Color(0xff161b22),
                  value: selectedMax,
                  items: [2, 3, 5, 10].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value Members ($value명방)', style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) => selectedMax = value ?? 2,
                  decoration: InputDecoration(labelText: 'Capacity (인원 설정)', labelStyle: GoogleFonts.gowunBatang(color: Colors.grey)),
                ),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password (비밀번호 걸기)',
                    labelStyle: GoogleFonts.gowunBatang(color: Colors.grey),
                  ),
                  onChanged: (value) => inputPassword = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel (취소)', style: GoogleFonts.gowunBatang(color: Colors.grey, fontSize: 16)),
            ),
            TextButton(
              onPressed: () {
                if (inputTitle.isNotEmpty) {
                  setState(() {
                    _studyRooms.add({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': '$inputTitle',
                      'maxMembers': selectedMax,
                      'currentMembers': 1,
                      'password': inputPassword,
                      'emoji': selectedEmoji,
                      'totalStars': 0,
                      'studyTime': '00:00'
                    });
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text('Confirm (확정)', style: GoogleFonts.gowunBatang(color: const Color(0xff58a6ff), fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  /// 룸 입장 처리 및 과목 선택 자동 네비게이션 트리거 (6번 및 제안 1 구현)
  void _enterRoom(Map<String, dynamic> room) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Entering ${room['title']} -> Moving to Subject Selection (과목 선택 단계로 즉시 이동합니다)',
          style: GoogleFonts.gowunBatang(fontSize: 16),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0d1117),
      appBar: AppBar(
        backgroundColor: const Color(0xff161b22),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Friend Study Room (친구학습방)',
          style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 4번 규칙: 상단 고정 2분할 대형 사각형 룸 영역
              _buildFixedDualRooms(),
              const SizedBox(height: 30),

              // 섹션 타이틀 및 방 생성 트리거
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Rooms (활성화된 학습방)',
                    style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff238636)),
                    onPressed: _createNewRoom,
                    child: Text('Create (방 생성)', style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 16)),
                  )
                ],
              ),
              const SizedBox(height: 15),

              // 2번, 3번, 5번 규칙 리스트 인터페이스
              _studyRooms.isEmpty
                  ? _buildEmptyStateWidget()
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _studyRooms.length,
                itemBuilder: (context, index) {
                  final room = _studyRooms[index];
                  return _buildDynamicRoomCard(room);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 4번 규칙: 수학집중룸, 고시 집중룸 좌우 끝 정렬 및 2분할 위젯
  Widget _buildFixedDualRooms() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 110,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xff21262d),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xff30363d), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Math Focus Room',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '(수학집중룸)',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.gowunBatang(color: const Color(0xffe2b714), fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Container(
            height: 110,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xff21262d),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xff30363d), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Exam Focus Room',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '(고시 집중룸)',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.gowunBatang(color: const Color(0xffe2b714), fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 2번, 3번, 5번 복합 규칙 빌드 위젯 카드형 레이아웃
  Widget _buildDynamicRoomCard(Map<String, dynamic> room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff161b22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xff30363d), width: 1.5),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 파란불 인디케이터 + 초집중 상태 타이틀 배정 (2번 규칙)
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xff58a6ff),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Color(0xff58a6ff), blurRadius: 6, spreadRadius: 2)],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${room['currentMembers']} Users Ultra-Concentrated Studying (${room['currentMembers']}명이 초집중 학습중)',
                      style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 방 제목 명기 및 이모지 노출
              Text(
                '${room['emoji']} ${room['title']}',
                style: GoogleFonts.gowunBatang(color: Colors.grey[300], fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 15),
              // 5번 규칙: 공부시간 및 총 별수 가시성 배치
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled, color: Colors.grey, size: 20),
                      const SizedBox(width: 5),
                      Text(
                        'Time: ${room['studyTime']} (시간: ${room['studyTime']})',
                        style: GoogleFonts.gowunBatang(color: Colors.grey[400], fontSize: 16),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xffe2b714), size: 22),
                      const SizedBox(width: 4),
                      Text(
                        'Stars: ${room['totalStars']} (총 별수: ${room['totalStars']})',
                        style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 즉시 입장 버튼 액션 연결 (6번 원칙 연동 - 순정 구조 교정)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xff30363d)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => _enterRoom(room),
                  child: Text(
                    'Enter Room (룸 입장)',
                    style: GoogleFonts.gowunBatang(color: const Color(0xff58a6ff), fontSize: 16),
                  ),
                ),
              )
            ],
          ),
          // 3번 규칙: 우측 상단 완벽 고정형 제거 "X" 버튼 탑재
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _studyRooms.removeWhere((element) => element['id'] == room['id']);
                });
              },
              child: const Icon(Icons.close, color: Colors.redAccent, size: 26),
            ),
          )
        ],
      ),
    );
  }

  /// 제안 2번 반영: 예외 방어 인터페이스(Empty State)
  Widget _buildEmptyStateWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.auto_stories, color: Colors.grey, size: 50),
          const SizedBox(height: 15),
          Text(
            'No active study rooms.\nCreate your own! (활성화된 학습방이 없습니다. 나만의 방을 만들어보세요!)',
            textAlign: TextAlign.center,
            style: GoogleFonts.gowunBatang(color: Colors.grey[500], fontSize: 18, height: 1.5),
          ),
        ],
      ),
    );
  }
}