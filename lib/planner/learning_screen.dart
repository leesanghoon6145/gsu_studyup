import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../global_lang.dart'; // 👑 [12개국 연동] 전역 언어 스위치와 연결

/// GKE STUDYUP - LEARNING SCREEN
/// 📚 2] 학습 실행 (Learning) 서브 레이어
class LearningScreen extends StatefulWidget {
  const LearningScreen({Key? key}) : super(key: key);

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  // ============================================================================
  // 🆕 [12개국 언어 시스템]
  // 기본값(마이페이지에서 12개국 중 하나를 고르기 전, 즉 DkeLang.current == 'KO' 상태 포함)은
  // 항상 "영문 + 한글"이 함께 보입니다 — 12개국에 없는 다른 나라 사용자도 영어로 볼 수 있게 하기 위함.
  // 한국어/영어를 "제외한" 나머지 10개국 중 하나를 선택했을 때만 그 언어 단독으로 전환됩니다.
  // ============================================================================
  static const List<String> _foreignLanguages = ['JA', 'ZH', 'FR', 'DE', 'RU', 'AR', 'HI', 'VI', 'ES', 'TH'];
  static bool get _isForeignSelected => _foreignLanguages.contains(DkeLang.current);

  static const Map<String, Map<String, String>> _uiText = {
    'learningLayerReady': {
      'KO': '학습 실행 화면 준비 중', 'EN': 'Learning Layer Ready',
      'JA': '学習実行画面準備中', 'ZH': '学习执行页面准备中', 'FR': "Exécution en préparation",
      'DE': 'Lernausführung bereit', 'RU': 'Раздел выполнения готовится', 'AR': 'صفحة التنفيذ قيد الإعداد',
      'HI': 'लर्निंग स्क्रीन तैयार हो रही है', 'VI': 'Màn hình thực hiện đang chuẩn bị', 'ES': 'Pantalla de ejecución en preparación', 'TH': 'หน้าลงมือเรียนกำลังเตรียมพร้อม',
    },
  };

  static String _foreignOnly(Map<String, String> map) {
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? '';
  }

  // 🆕 제목형 안내문: 기본값 = 영문(위) + 한글(아래) 2줄, 10개국 선택 시 = 단일 언어 1줄
  Widget _biTitle(
      String key, {
        required TextStyle enStyle,
        required TextStyle koStyle,
        TextStyle? foreignStyle,
      }) {
    if (_isForeignSelected) {
      return Text(
        _foreignOnly(_uiText[key]!),
        style: foreignStyle ?? koStyle,
        overflow: TextOverflow.fade,
        softWrap: false,
        maxLines: 1,
      );
    }
    final map = _uiText[key]!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(map['EN']!, style: enStyle, overflow: TextOverflow.fade, softWrap: false, maxLines: 1),
        const SizedBox(height: 4),
        Text(map['KO']!, style: koStyle, overflow: TextOverflow.fade, softWrap: false, maxLines: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      // 🆕 [12개국] 기본값 = 영문+한글 2줄, 10개국 선택 시 = 단일 언어
      child: _biTitle(
        'learningLayerReady',
        enStyle: GoogleFonts.notoSerif(
          color: const Color(0xFFE5C158),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        koStyle: GoogleFonts.notoSansKr(
          color: const Color(0xFFE5C158),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        foreignStyle: GoogleFonts.notoSans(
          color: const Color(0xFFE5C158),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
