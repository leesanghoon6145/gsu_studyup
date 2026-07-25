import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../global_lang.dart'; // 👑 [12개국 연동] 전역 언어 스위치와 연결

/// ============================================================================
/// [GKE StudyUp] 일간 뷰 - 오늘 주요 일정(Todo) 목록 전담 위젯 섹션
/// ============================================================================
class DailyTodoListSection extends StatelessWidget {
  final List<Map<String, dynamic>> targetDaySchedules;

  // [주석] 카테고리별 구분을 위한 테마 색상팩 바인딩
  final Color schoolColor;
  final Color academyColor;
  final Color examColor;
  final Color personalColor;
  final Color goldColor;
  final Color slate500;

  // [주석] 부모 위젯과의 팝업 연동 콜백 채널
  final Function(Map<String, dynamic>) onUnifiedPopupTrack;

  const DailyTodoListSection({
    Key? key,
    required this.targetDaySchedules,
    required this.schoolColor,
    required this.academyColor,
    required this.examColor,
    required this.personalColor,
    required this.goldColor,
    required this.slate500,
    required this.onUnifiedPopupTrack,
  }) : super(key: key);

  // ============================================================================
  // 🆕 [12개국 언어 시스템]
  // 기본값(마이페이지에서 12개국 중 하나를 고르기 전, 즉 DkeLang.current == 'KO' 상태 포함)은
  // 항상 "영문 + 한글"이 함께 보입니다 — 12개국에 없는 다른 나라 사용자도 영어로 볼 수 있게 하기 위함.
  // 한국어/영어를 "제외한" 나머지 10개국 중 하나를 선택했을 때만 그 언어 단독으로 전환됩니다.
  // ============================================================================
  static const List<String> _foreignLanguages = ['JA', 'ZH', 'FR', 'DE', 'RU', 'AR', 'HI', 'VI', 'ES', 'TH'];
  static bool get _isForeignSelected => _foreignLanguages.contains(DkeLang.current);

  static const Map<String, Map<String, String>> _uiText = {
    'emptyTodayMainSchedule': {
      'KO': '오늘 등록된 주요 일정이 없습니다.', 'EN': 'No main schedule registered for today.',
      'JA': '本日登録された主要日程がありません。', 'ZH': '今日暂无已登记的主要日程。', 'FR': "Aucun programme principal enregistré aujourd'hui.",
      'DE': 'Heute ist kein Hauptplan registriert.', 'RU': 'На сегодня основное расписание не добавлено.', 'AR': 'لا يوجد جدول رئيسي مسجل لليوم.',
      'HI': 'आज के लिए कोई मुख्य कार्यक्रम दर्ज नहीं है।', 'VI': 'Chưa có lịch chính nào được đăng ký cho hôm nay.', 'ES': 'No hay horario principal registrado para hoy.', 'TH': 'ไม่มีตารางหลักที่ลงทะเบียนไว้สำหรับวันนี้',
    },
  };

  static const Map<String, Map<String, String>> _categoryMap = {
    "학교": {'KO': '학교', 'EN': 'School', 'JA': '学校', 'ZH': '学校', 'FR': 'École', 'DE': 'Schule', 'RU': 'Школа', 'AR': 'المدرسة', 'HI': 'स्कूल', 'VI': 'Trường học', 'ES': 'Escuela', 'TH': 'โรงเรียน'},
    "학원": {'KO': '학원', 'EN': 'Academy', 'JA': '塾', 'ZH': '补习班', 'FR': 'Institut', 'DE': 'Nachhilfeschule', 'RU': 'Курсы', 'AR': 'المعهد', 'HI': 'कोचिंग', 'VI': 'Trung tâm luyện thi', 'ES': 'Academia', 'TH': 'สถาบันกวดวิชา'},
    "시험": {'KO': '시험', 'EN': 'Exam', 'JA': '試験', 'ZH': '考试', 'FR': 'Examen', 'DE': 'Prüfung', 'RU': 'Экзамен', 'AR': 'اختبار', 'HI': 'परीक्षा', 'VI': 'Kỳ thi', 'ES': 'Examen', 'TH': 'สอบ'},
    "개인": {'KO': '개인', 'EN': 'Personal', 'JA': '個人', 'ZH': '个人', 'FR': 'Personnel', 'DE': 'Persönlich', 'RU': 'Личное', 'AR': 'شخصي', 'HI': 'व्यक्तिगत', 'VI': 'Cá nhân', 'ES': 'Personal', 'TH': 'ส่วนตัว'},
  };

  static String _foreignOnly(Map<String, String> map) {
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? '';
  }

  // 🆕 한 줄짜리 문자열(카테고리 라벨 등)에서 사용: 기본값 = "EN / KO" 한 줄, 10개국 선택 시 = 단일 언어
  static String _biStr(String key) {
    if (_isForeignSelected) return _foreignOnly(_uiText[key]!);
    final map = _uiText[key]!;
    return '${map['EN']} / ${map['KO']}';
  }

  // 🆕 카테고리(학교/학원/시험/개인) 전용: 기본값 = "School / 학교", 10개국 선택 시 = 단일 언어
  static String _biCategory(String koKey) {
    final map = _categoryMap[koKey];
    if (map == null) return koKey;
    if (_isForeignSelected) return _foreignOnly(map);
    return '${map['EN']} / ${map['KO']}';
  }

  // 🆕 문장형 안내문에서 사용: 기본값 = 영문 문장 + 한글 문장 두 줄, 10개국 선택 시 = 단일 언어
  static Widget _biParagraph(
      String key, {
        required TextStyle enStyle,
        required TextStyle koStyle,
        TextStyle? foreignStyle,
        TextAlign? textAlign,
      }) {
    if (_isForeignSelected) {
      return Text(_foreignOnly(_uiText[key]!), style: foreignStyle ?? koStyle, textAlign: textAlign);
    }
    final map = _uiText[key]!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(map['EN']!, style: enStyle, textAlign: textAlign),
        const SizedBox(height: 4),
        Text(map['KO']!, style: koStyle, textAlign: textAlign),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // [주석] 오늘 등록된 일정이 아예 없을 때의 예외 가드 뷰
    if (targetDaySchedules.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          // 🆕 [12개국] 기본값 = 영문 문장+한글 문장, 10개국 선택 시 = 단일 언어
          child: _biParagraph(
            'emptyTodayMainSchedule',
            textAlign: TextAlign.center,
            enStyle: GoogleFonts.notoSans(color: slate500, fontSize: 12),
            koStyle: GoogleFonts.notoSansKr(color: slate500, fontSize: 12), // 원장님 지시: 일반글자 크기 12 준수
            foreignStyle: GoogleFonts.notoSans(color: slate500, fontSize: 12),
          ),
        ),
      );
    }

    // [주석] 일정이 존재할 경우 카테고리별 마스터 팩 루프 구동
    return Column(
      children: targetDaySchedules.map((item) {
        String categoryKey = '학교';
        Color squareColor = schoolColor;

        if (item['color'] == academyColor) {
          categoryKey = '학원';
          squareColor = academyColor;
        } else if (item['color'] == examColor) {
          categoryKey = '시험';
          squareColor = examColor;
        } else if (item['color'] == personalColor) {
          categoryKey = '개인';
          squareColor = personalColor;
        }

        // 🆕 [12개국] 기본값 = "[School / 학교]", 10개국 선택 시 = "[Trường học]" 처럼 단일 언어
        String categoryLabel = '[${_biCategory(categoryKey)}]';

        return GestureDetector(
          onTap: () => onUnifiedPopupTrack(item),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFF020617),
                border: Border.all(color: squareColor.withOpacity(0.3))
            ),
            child: Row(
              children: [
                Text(
                    '■ ',
                    style: TextStyle(color: squareColor, fontSize: 26, fontWeight: FontWeight.bold)
                ),
                Flexible(
                  child: Text(
                    '$categoryLabel ',
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    maxLines: 1,
                    style: GoogleFonts.notoSans(
                        color: squareColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold
                    ), // 원장님 지시: 일반글자 크기 12 준수
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(
                        '${item['time']} - ${item['title']}',
                        style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold
                        ),
                        overflow: TextOverflow.ellipsis
                    )
                ),
                Icon(Icons.remove_red_eye, color: goldColor.withOpacity(0.7), size: 18),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
