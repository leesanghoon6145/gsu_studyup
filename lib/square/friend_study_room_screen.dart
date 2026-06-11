import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FriendStudyRoomScreen extends StatefulWidget {
  const FriendStudyRoomScreen({Key? key}) : super(key: key);

  @override
  State<FriendStudyRoomScreen> createState() => _FriendStudyRoomScreenState();
}

// 🏠 [4번 버그 교정]: 전 페이지로 나갔다 들어와도 생성된 방이 리셋되지 않도록 리스트 데이터를 클래스 외부에 철통 고정 보존
final List<Map<String, dynamic>> _globalRooms = [
  {
    "title": "Room A",
    "sub": "2 / 2 Users (2명방)",
    "maxUsers": 2,
    "currentUsers": 2,
    "hasPassword": false,
    "isCreator": false
  },
  {
    "title": "Room B",
    "sub": "0 / 3 Users (3명방)",
    "maxUsers": 3,
    "currentUsers": 0,
    "hasPassword": false,
    "isCreator": false
  },
];

class _FriendStudyRoomScreenState extends State<FriendStudyRoomScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ⏰ 10분 지연 자동 삭제 처리를 위한 백그라운드 타이머 보관소
  final Map<String, Timer> _inactiveTimers = {};

  // 🌟 학생들이 받은 이모지 응원 내역을 실시간 누적 보관하는 데이터 센터
  final Map<String, List<Map<String, String>>> _emojiInbox = {
    "Seunghun Kim (김승훈)": [
      {"emoji": "👍", "from": "Gyuhyeon Lee (이규현)"},
    ],
    "Gyuhyeon Lee (이규현)": [
      {"emoji": "🔥", "from": "Yubin Shin (신유빈)"},
    ],
    "Yubin Shin (신유빈)": [],
  };

  @override
  void dispose() {
    _nameController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _inactiveTimers.forEach((key, timer) => timer.cancel());
    super.dispose();
  }

  // ⏰ [4번 지시사항]: 10분 백그라운드 카운트다운 타이머 완벽 안착 수식
  void _startInactivityTimer(String roomTitle) {
    _inactiveTimers[roomTitle]?.cancel();
    _inactiveTimers[roomTitle] = Timer(const Duration(minutes: 10), () {
      if (mounted) {
        setState(() {
          _globalRooms.removeWhere((r) => r["title"] == roomTitle);
        });
        _inactiveTimers.remove(roomTitle);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color brandGolden = Color(0xFFE5C158);

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        toolbarHeight: 85,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Friends Study Room',
              style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 21),
            ),
            const SizedBox(height: 4),
            Text(
              '(친구 학습방)',
              style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.normal, fontSize: 17),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandGolden,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_circle_outline, color: Colors.black, size: 20),
                label: Text(
                  'Create Room (방 생성)',
                  style: GoogleFonts.gowunBatang(fontWeight: FontWeight.bold, fontSize: 18.5),
                ),
                onPressed: () => _showCreateRoomDialog(context),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  // 📐 [1번 지시사항]: 세로 폭을 추가로 10% 더 압축하기 위해 배율을 2.38 -> 2.65로 정밀 수정
                  childAspectRatio: 2.65,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: _globalRooms.length,
                itemBuilder: (context, index) {
                  final room = _globalRooms[index];
                  final bool isRoomOnline = room["currentUsers"] > 0;

                  return InkWell(
                    onTap: () => _enterRoom(room, index),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // [2번 교정]: 패딩 압축
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: brandGolden.withOpacity(0.2), width: 1.0),
                      ),
                      // 🚨 [2번 버그 교정]: 상자가 세로로 줄어들었을 때 안쪽 컴포넌트가 삐져나오지 않도록 정밀 간격 압축
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isRoomOnline ? const Color(0xFF00F0FF) : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  room["title"],
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                              ),
                              if (room["hasPassword"])
                                const Icon(Icons.lock, color: brandGolden, size: 13),
                              if (room["isCreator"] == true)
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 18),
                                    // 🗑️ [3번 지시사항]: 즉시 삭제를 차단하고 진짜 지울 것인지 더블 체크 팝업 띄우기
                                    onPressed: () => _showDeleteConfirmDialog(context, index),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 1), // 오버플로우 차단을 위한 유격 최소화
                          Text(
                            room["sub"],
                            style: GoogleFonts.gowunBatang(
                              color: isRoomOnline ? const Color(0xFF00F0FF) : Colors.white60,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🗑️ [3번 지시사항]: 권한 확인 및 방 삭제 더블 체크 모달 연산 수식
  void _showDeleteConfirmDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: Text(
          'Delete Room (방 삭제 알림)',
          style: GoogleFonts.gowunBatang(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'Are you sure you want to delete this room?\n(방을 정말로 삭제하시겠습니까?)',
          style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel (취소)', style: GoogleFonts.gowunBatang(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _globalRooms.removeAt(index);
              });
              Navigator.pop(ctx);
            },
            child: Text('Delete (삭제)', style: GoogleFonts.gowunBatang(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _enterRoom(Map<String, dynamic> room, int roomIndex) {
    if (room["currentUsers"] >= room["maxUsers"]) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            'The room is full. Cannot enter. (정원이 초과되어 더 이상 입장할 수 없습니다.)',
            style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    final List<Map<String, dynamic>> virtualStudents = [
      {
        "id_name": "Seunghun Kim (김승훈)", "level": "Lv.7", "stars": "1,250",
        "status": "🟢 Studying (공부 중)", "statusColor": const Color(0xFF00F0FF),
        "streak": "🔥 23 Days (23일 연속)", "activity": "📖 Math (수학)",
        "time": "⏰ Today 2h 15m (오늘 2시간 15분)", "target": "🎯 Target 82% (목표 82%)"
      },
      {
        "id_name": "Gyuhyeon Lee (이규현)", "level": "Lv.9", "stars": "1,800",
        "status": "🟢 Studying (공부 중)", "statusColor": const Color(0xFF00F0FF),
        "streak": "🔥 45 Days (45일 연속)", "activity": "📖 English (영어)",
        "time": "⏰ Today 3h 22m (오늘 3시간 22분)", "target": "🎯 Target 95% (목표 95%)"
      },
      {
        "id_name": "Yubin Shin (신유빈)", "level": "Lv.5", "stars": "700",
        "status": "⚫ Offline (오프라인)", "statusColor": Colors.grey,
        "streak": "🔥 102 Days (102일 연속)", "activity": "📚 Reading (독서)",
        "time": "⏰ Today 0h 00m (오늘 0시간 0분)", "target": "🎯 Target 0% (목표 0%)"
      },
    ];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
            builder: (context, setRoomState) {
              const Color brandGolden = Color(0xFFE5C158);

              return Scaffold(
                backgroundColor: const Color(0xFF16161A),
                appBar: AppBar(
                  backgroundColor: const Color(0xFF16161A),
                  elevation: 0,
                  title: Text(
                    '${room["title"]} - Study Room',
                    style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold),
                  ),
                  centerTitle: true,
                ),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22222A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: brandGolden.withOpacity(0.3), width: 1),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Room Statistics (방 전체 통계)',
                              style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text('Total: ⏰ 17h 35m\n(오늘 방 누적 17시간 35분)', textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 13, height: 1.3)),
                                Text('Avg: ⏰ 3h 31m\n(오늘 방 평균 3시간 31분)', textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 13, height: 1.3)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Members (참여 학생 목록)',
                        style: GoogleFonts.gowunBatang(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: virtualStudents.length,
                          itemBuilder: (context, studentIndex) {
                            final student = virtualStudents[studentIndex];
                            final String targetStudent = student["id_name"];
                            final List<Map<String, String>> inbox = _emojiInbox[targetStudent] ?? [];

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E24),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: ExpansionTile(
                                iconColor: brandGolden,
                                collapsedIconColor: Colors.white60,
                                title: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(shape: BoxShape.circle, color: student["statusColor"]),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '$targetStudent [${student["level"]}]',
                                        style: GoogleFonts.gowunBatang(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ),
                                    if (inbox.isNotEmpty)
                                      Row(
                                        children: inbox.map((msg) {
                                          return GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  backgroundColor: const Color(0xFF222222),
                                                  title: Text('Support Sender (응원 보낸 사람)', style: GoogleFonts.gowunBatang(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 16)),
                                                  content: Text('From: ${msg["from"]}\n\n"${msg["from"]} 학생이 ${msg["emoji"]} 응원을 보냈습니다!"', style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 14, height: 1.4)),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Confirm (확인)', style: GoogleFonts.gowunBatang(color: brandGolden)))
                                                  ],
                                                ),
                                              );
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 2),
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                                              child: Text(msg["emoji"]!, style: const TextStyle(fontSize: 14)),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 0, left: 16, right: 16, bottom: 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Divider(color: Colors.white12),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Level: ${student["level"]} (등급)', style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 13)),
                                            Text('Stars: ⭐ ${student["stars"]} (보유 별)', style: GoogleFonts.gowunBatang(color: brandGolden, fontSize: 13, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text('Status: ${student["status"]}', style: GoogleFonts.gowunBatang(color: student["statusColor"], fontSize: 13, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text('Streak: ${student["streak"]}', style: GoogleFonts.gowunBatang(color: Colors.orangeAccent, fontSize: 13)),
                                        const SizedBox(height: 4),
                                        Text('Activity: ${student["activity"]}', style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 13)),
                                        const SizedBox(height: 4),
                                        Text('Time: ${student["time"]}', style: GoogleFonts.gowunBatang(color: Colors.white, fontSize: 13)),
                                        const SizedBox(height: 4),
                                        Text('Target: ${student["target"]}', style: GoogleFonts.gowunBatang(color: Colors.greenAccent, fontSize: 13)),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C2C35), foregroundColor: brandGolden),
                                              onPressed: () {
                                                setState(() {
                                                  _emojiInbox[targetStudent]?.add({"emoji": "👍", "from": "My Self (나 자신)"});
                                                });
                                                setRoomState(() {});
                                              },
                                              child: Text('👍 Cheer (칭찬)', style: GoogleFonts.gowunBatang(fontSize: 12, fontWeight: FontWeight.bold)),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C2C35), foregroundColor: brandGolden),
                                              onPressed: () {
                                                setState(() {
                                                  _emojiInbox[targetStudent]?.add({"emoji": "🔥", "from": "My Self (나 자신)"});
                                                });
                                                setRoomState(() {});
                                              },
                                              child: Text('🔥 Motivate (응원)', style: GoogleFonts.gowunBatang(fontSize: 12, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
        ),
      ),
    ).then((_) {
      if (roomIndex >= 0 && roomIndex < _globalRooms.length) {
        if (_globalRooms[roomIndex]["currentUsers"] == 0) {
          _startInactivityTimer(_globalRooms[roomIndex]["title"]);
        }
      }
    });
  }

  void _showCreateRoomDialog(BuildContext context) {
    _nameController.clear();
    _userController.clear();
    _passwordController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF222222),
          title: Text(
            'Create New Room (새 방 생성)',
            style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Room Name (방 이름)',
                  labelStyle: GoogleFonts.gowunBatang(color: Colors.white70),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                ),
              ),
              TextField(
                controller: _userController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Max Users (수용 인원)',
                  labelStyle: GoogleFonts.gowunBatang(color: Colors.white70),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                ),
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password (비밀번호 설정)',
                  labelStyle: GoogleFonts.gowunBatang(color: Colors.white70),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel (취소)', style: GoogleFonts.gowunBatang(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty && _userController.text.isNotEmpty) {
                  final String newTitle = _nameController.text;
                  int max = int.tryParse(_userController.text) ?? 2;

                  setState(() {
                    _globalRooms.add({
                      "title": newTitle,
                      "sub": "0 / $max Users (${_userController.text}명방)",
                      "maxUsers": max,
                      "currentUsers": 0,
                      "hasPassword": true,
                      "isCreator": true
                    });
                  });
                  _startInactivityTimer(newTitle);
                }
                Navigator.pop(context);
              },
              child: Text('Create (생성)', style: GoogleFonts.gowunBatang(color: const Color(0xFFE5C158), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

extension SafeListAccess on List {
  bool isValidIndex(int index) => index >= 0 && index < length;
}