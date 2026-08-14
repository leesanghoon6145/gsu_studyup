// ============================================================================
// 🆕 [일반 플래너 3단계] AchievementScreen
// "성취 완료" 처리된 목표들의 기록을 모아 보여줍니다. GoalDataService에
// 저장된 AchievementRecord만 표시하며, 실제로 달성한 것이 없으면 빈 상태
// 안내만 보여줍니다 (가짜 트로피 없음).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'goal_data_service.dart';
import 'bilingual_text.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  static const Color _brandGolden = Color(0xFFE5C158);
  static const Color _pageBg = Color(0xFF030712);
  static const Color _containerBg = Color(0xFF0D1527);

  static const Map<String, String> _typeLabels = {
    'life': '인생 목표',
    'yearly': '연간 목표',
    'monthly': '월간 목표',
    'weekly': '주간 목표',
    'today': '오늘 목표',
  };
  static const Map<String, String> _typeLabelsEn = {
    'life': 'Life Goal',
    'yearly': 'Yearly Goal',
    'monthly': 'Monthly Goal',
    'weekly': 'Weekly Goal',
    'today': 'Today Goal',
  };
  // 🆕 [10개국어 확장] 목표 유형별 이름 번역
  static const Map<String, Map<String, String>> _typeLabelsTranslations = {
    'life': {'JA': '人生の目標', 'ZH': '人生目标', 'FR': 'Objectif de vie', 'DE': 'Lebensziel', 'RU': 'Жизненная цель', 'AR': 'هدف الحياة', 'HI': 'जीवन लक्ष्य', 'VI': 'Mục tiêu cuộc đời', 'ES': 'Objetivo de vida', 'TH': 'เป้าหมายชีวิต'},
    'yearly': {'JA': '年間目標', 'ZH': '年度目标', 'FR': 'Objectif annuel', 'DE': 'Jahresziel', 'RU': 'Годовая цель', 'AR': 'الهدف السنوي', 'HI': 'वार्षिक लक्ष्य', 'VI': 'Mục tiêu năm', 'ES': 'Objetivo anual', 'TH': 'เป้าหมายรายปี'},
    'monthly': {'JA': '月間目標', 'ZH': '月度目标', 'FR': 'Objectif mensuel', 'DE': 'Monatsziel', 'RU': 'Месячная цель', 'AR': 'الهدف الشهري', 'HI': 'मासिक लक्ष्य', 'VI': 'Mục tiêu tháng', 'ES': 'Objetivo mensual', 'TH': 'เป้าหมายรายเดือน'},
    'weekly': {'JA': '週間目標', 'ZH': '每周目标', 'FR': 'Objectif hebdomadaire', 'DE': 'Wochenziel', 'RU': 'Недельная цель', 'AR': 'الهدف الأسبوعي', 'HI': 'साप्ताहिक लक्ष्य', 'VI': 'Mục tiêu tuần', 'ES': 'Objetivo semanal', 'TH': 'เป้าหมายรายสัปดาห์'},
    'today': {'JA': '今日の目標', 'ZH': '今日目标', 'FR': "Objectif du jour", 'DE': 'Tagesziel', 'RU': 'Цель на сегодня', 'AR': 'هدف اليوم', 'HI': 'आज का लक्ष्य', 'VI': 'Mục tiêu hôm nay', 'ES': 'Objetivo de hoy', 'TH': 'เป้าหมายวันนี้'},
  };

  List<AchievementRecord> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);
    final list = await GoalDataService.loadAchievements();
    if (!mounted) return;
    setState(() {
      _achievements = list;
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
        title: BiTitle(
          en: 'ACHIEVEMENT', ko: '성취', enSize: 17, koSize: 13,
          translations: const {'JA': '達成', 'ZH': '成就', 'FR': 'Réussite', 'DE': 'Erfolg', 'RU': 'Достижение', 'AR': 'الإنجاز', 'HI': 'उपलब्धि', 'VI': 'Thành tựu', 'ES': 'Logro', 'TH': 'ความสำเร็จ'},
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGolden))
          : _achievements.isEmpty
          ? Center(
        child: BiInline(
          en: 'No achievements yet.\nToggle "Achieved" in a goal to record one.',
          ko: '아직 달성한 목표가 없습니다.\n목표 화면에서 "달성함"을 켜보세요.',
          color: Colors.white38,
          fontSize: 14,
          textAlign: TextAlign.center,
          translations: const {
            'JA': 'まだ達成した目標がありません。\n目標画面で「達成済み」をオンにしてください。',
            'ZH': '暂无已达成的目标。\n请在目标页面开启"已达成"。',
            'FR': 'Aucune réussite pour le moment.\nActivez "Atteint" sur un objectif pour en enregistrer une.',
            'DE': 'Noch keine Erfolge.\nAktivieren Sie "Erreicht" bei einem Ziel, um es aufzuzeichnen.',
            'RU': 'Пока нет достижений.\nВключите "Достигнуто" у цели, чтобы записать её.',
            'AR': 'لا توجد إنجازات بعد.\nفعّل "تم تحقيقه" في أحد الأهداف لتسجيله.',
            'HI': 'अभी तक कोई उपलब्धि नहीं है।\nरिकॉर्ड करने के लिए किसी लक्ष्य में "हासिल किया" चालू करें।',
            'VI': 'Chưa có thành tựu nào.\nBật "Đã đạt được" trong một mục tiêu để ghi nhận.',
            'ES': 'Aún no hay logros.\nActiva "Logrado" en un objetivo para registrarlo.',
            'TH': 'ยังไม่มีความสำเร็จ\nเปิด "บรรลุแล้ว" ในเป้าหมายเพื่อบันทึก',
          },
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandGolden.withOpacity(0.45))),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: _brandGolden, size: 32),
                const SizedBox(width: 12),
                BiInline(
                  en: 'Total ${_achievements.length} achieved', ko: '총 ${_achievements.length}개 달성', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16,
                  translations: {
                    'JA': '合計 ${_achievements.length}件達成', 'ZH': '共达成 ${_achievements.length} 个', 'FR': '${_achievements.length} réussites au total', 'DE': 'Insgesamt ${_achievements.length} erreicht',
                    'RU': 'Всего достигнуто ${_achievements.length}', 'AR': 'إجمالي ${_achievements.length} تم تحقيقه', 'HI': 'कुल ${_achievements.length} हासिल किए', 'VI': 'Tổng ${_achievements.length} đã đạt được',
                    'ES': 'Total ${_achievements.length} logrados', 'TH': 'บรรลุแล้วทั้งหมด ${_achievements.length} รายการ',
                  },
                ),
              ],
            ),
          ),
          ..._achievements.map((a) => _buildAchievementTile(a)),
        ],
      ),
    );
  }

  Widget _buildAchievementTile(AchievementRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _containerBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: _brandGolden, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.goalTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                BiInline(
                  en: '${_typeLabelsEn[record.goalType] ?? record.goalType} · ${record.achievedDate}',
                  ko: '${_typeLabels[record.goalType] ?? record.goalType} · ${record.achievedDate}',
                  color: Colors.white38,
                  fontSize: 10.5,
                  translations: _typeLabelsTranslations[record.goalType] != null
                      ? {for (final e in _typeLabelsTranslations[record.goalType]!.entries) e.key: '${e.value} · ${record.achievedDate}'}
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
