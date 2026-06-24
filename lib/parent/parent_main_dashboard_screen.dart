import 'package:flutter/material.dart';

class ParentMainDashboardScreen extends StatefulWidget {
  final String parentEmail;
  final String childName;

  const ParentMainDashboardScreen({
    Key? key,
    required this.parentEmail,
    this.childName = "홍길동",
  }) : super(key: key);

  @override
  _ParentMainDashboardScreenState createState() => _ParentMainDashboardScreenState();
}

class _ParentMainDashboardScreenState extends State<ParentMainDashboardScreen> {
  int _currentIndex = 0;
  bool _isVipMember = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(
          '${widget.childName} 케어 매니저',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isVipMember ? const Color(0xFFF59E0B) : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isVipMember ? "VIP 프리미엄" : "일반회원",
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildLiveStatusTab(),
          _buildTimelineTab(),
          _buildAnalysisReportTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: const Color(0xFF38BDF8),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: '실시간 현황'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: '상세 기록'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: '평가 분석'),
        ],
      ),
    );
  }

  // 1. 실시간 현황 탭
  Widget _buildLiveStatusTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("🔥 자녀의 현재 상태", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 10),
          Text(
            "${widget.childName}님은 현재 수학 집중 중 (35분째)",
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${widget.childName}님에게 응원을 보냈습니다! 🎉')),
              );
            },
            icon: const Icon(Icons.favorite, color: Colors.white),
            label: const Text("열공 응원 아이템 보내기", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // 2. 상세 기록 타임라인 탭
  Widget _buildTimelineTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildRecordCard(
          subject: "수학",
          time: "10:20 PM",
          duration: "60분 집중 완료",
          content: "미적분 수능 기출 문제집 20p~25p 개념 정리 및 오답 풀이",
          score: "95점",
          understanding: "80%",
          condition: "😊 좋음",
        ),
        _buildRecordCard(
          subject: "영어",
          time: "08:15 PM",
          duration: "45분 집중 완료",
          content: "EBS 수능특강 영단어 15강~17강 암기 및 예문 체크",
          score: "80점",
          understanding: "60%",
          condition: "😴 피곤함",
        ),
      ],
    );
  }

  // 타임라인 내 개별 카드 컴포넌트
  Widget _buildRecordCard({
    required String subject,
    required String time,
    required String duration,
    required String content,
    required String score,
    required String understanding,
    required String condition,
  }) {
    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "[$subject] $duration",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
                Text(
                  time,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 20),
            const Text("📝 상세 내용", style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            Text('"$content"', style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.white)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMiniInfoBox("💯 점수", score)),
                Expanded(child: _buildMiniInfoBox("🎯 이해도", understanding)),
                Expanded(child: _buildMiniInfoBox("💪 컨디션", condition)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMiniInfoBox(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  // 3. VIP 평가 분석 리포트 탭
  Widget _buildAnalysisReportTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: _isVipMember
            ? const Text("📊 AI 주간 분석표 내용 노출 (VIP 상태)", style: TextStyle(color: Colors.white))
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              "정밀 학습 평가 및 취약점 분석",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "자녀의 집중 패턴 분석 및 오답 추적 리포트는\nVIP 프리미엄 회원에게만 매주 제공됩니다.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () {
                setState(() {
                  _isVipMember = true;
                });
              },
              child: const Text(
                "월 1,900원으로 패키지 구독하기",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
