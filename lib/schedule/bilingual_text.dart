// ============================================================================
// 🆕 [일반 플래너 - 다국어 정리] BiText 계열 공용 위젯
// 지금까지 각 화면에서 "EN" Text와 "KO" Text를 따로따로 두 줄로 작성하던 것을
// 한 번의 호출로 끝낼 수 있도록 만든 공용 헬퍼입니다. 앞으로 새로 만들거나
// 수정하는 모든 화면의 제목/버튼/힌트/안내문은 이 위젯들을 사용해서
// 영어+한글이 항상 함께 표시되도록 통일합니다.
//
// 사용 예시:
//   BiTitle(en: 'CALENDAR', ko: '캘린더')                    // 화면 상단 제목용 (2줄, 큰 글씨)
//   BiInline(en: 'Save', ko: '저장')                          // 버튼/라벨용 (1줄, "Save (저장)")
//   biHint('Enter title', '제목을 입력하세요')                // TextField 힌트용 문자열
//   biSnack(context, 'Saved', '저장되었습니다')                // SnackBar 문구용
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_language_service.dart'; // 🆕 [10개국어 확장] 언어 상태 서비스
export 'app_language_service.dart'; // 🆕 [에러 수정] 이 파일을 import하는 모든 화면이 appLanguage/AppLanguageService를 자동으로 쓸 수 있게 함

// 🆕 화면 상단 AppBar 제목처럼 "영문 큰 글씨 + 한글 작은 글씨" 2줄 구조
//
// [10개국어 확장 - 하위호환 보장] 기존처럼 en/ko만 넣으면 그대로 예전과
// 100% 동일하게 작동합니다(코드 한 글자도 안 고쳐도 됨). 외국어 10개국어
// 번역을 추가하고 싶은 곳만 선택적으로 translations 맵을 넣어주면 됩니다.
// 아직 번역을 안 넣은 화면은, 외국어를 선택해도 영어로 대체 표시되어
// 화면이 깨지지 않습니다(점진적으로 번역을 채워나갈 수 있는 안전장치).
class BiTitle extends StatefulWidget {
  final String en;
  final String ko;
  final Color color;
  final double enSize;
  final double koSize;
  final Map<String, String>? translations; // 🆕 {'JA': '...', 'ZH': '...', ...} 선택사항

  const BiTitle({
    super.key,
    required this.en,
    required this.ko,
    this.color = const Color(0xFFE5C158),
    this.enSize = 18,
    this.koSize = 13,
    this.translations,
  });

  @override
  State<BiTitle> createState() => _BiTitleState();
}

class _BiTitleState extends State<BiTitle> {
  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_onLanguageChanged); // 🆕 언어가 바뀌면 이 위젯만 즉시 다시 그려짐
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // 🆕 기본값(영+한)이면 예전과 완전히 동일하게 2줄로 표시
    if (appLanguage.isDefault) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.en, style: GoogleFonts.gowunBatang(color: widget.color, fontWeight: FontWeight.bold, fontSize: widget.enSize)),
          Text(widget.ko, style: GoogleFonts.notoSansKr(color: widget.color, fontWeight: FontWeight.bold, fontSize: widget.koSize)),
        ],
      );
    }
    // 🆕 외국어 선택 시: 번역이 있으면 그 언어만, 없으면 영어로 대체(화면 안 깨짐)
    final String displayText = widget.translations?[appLanguage.current] ?? widget.en;
    return Text(displayText, style: GoogleFonts.gowunBatang(color: widget.color, fontWeight: FontWeight.bold, fontSize: widget.enSize));
  }
}

// 🆕 버튼/라벨/섹션제목처럼 한 줄로 "EN (KO)" 형태로 보여주는 인라인 텍스트
// [10개국어 확장] BiTitle과 동일한 하위호환 원칙 적용.
class BiInline extends StatefulWidget {
  final String en;
  final String ko;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final int? maxLines;
  final Map<String, String>? translations; // 🆕 선택사항

  const BiInline({
    super.key,
    required this.en,
    required this.ko,
    this.color = Colors.white,
    this.fontSize = 14,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.translations,
  });

  @override
  State<BiInline> createState() => _BiInlineState();
}

class _BiInlineState extends State<BiInline> {
  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final String displayText = appLanguage.isDefault ? '${widget.en} (${widget.ko})' : (widget.translations?[appLanguage.current] ?? widget.en);
    return Text(
      displayText,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.maxLines != null ? TextOverflow.ellipsis : null,
      style: GoogleFonts.notoSansKr(color: widget.color, fontWeight: widget.fontWeight, fontSize: widget.fontSize),
    );
  }
}

// 🆕 [10개국어 확장] 여러 화면에서 반복되는 공통 버튼 단어 번역사전.
// "Delete"/"Cancel"/"Save" 등은 앱 전체에서 수십 번 나오므로, 파일마다
// 따로 번역을 넣지 않고 여기 한 곳에서만 관리합니다.
const Map<String, Map<String, String>> commonButtonTranslations = {
  'Delete': {'JA': '削除', 'ZH': '删除', 'FR': 'Supprimer', 'DE': 'Löschen', 'RU': 'Удалить', 'AR': 'حذف', 'HI': 'हटाएं', 'VI': 'Xóa', 'ES': 'Eliminar', 'TH': 'ลบ'},
  'Cancel': {'JA': 'キャンセル', 'ZH': '取消', 'FR': 'Annuler', 'DE': 'Abbrechen', 'RU': 'Отмена', 'AR': 'إلغاء', 'HI': 'रद्द करें', 'VI': 'Hủy', 'ES': 'Cancelar', 'TH': 'ยกเลิก'},
  'Save': {'JA': '保存', 'ZH': '保存', 'FR': 'Enregistrer', 'DE': 'Speichern', 'RU': 'Сохранить', 'AR': 'حفظ', 'HI': 'सहेजें', 'VI': 'Lưu', 'ES': 'Guardar', 'TH': 'บันทึก'},
  'Update': {'JA': '更新', 'ZH': '更新', 'FR': 'Mettre à jour', 'DE': 'Aktualisieren', 'RU': 'Обновить', 'AR': 'تحديث', 'HI': 'अपडेट करें', 'VI': 'Cập nhật', 'ES': 'Actualizar', 'TH': 'อัปเดต'},
  'Copy': {'JA': 'コピー', 'ZH': '复制', 'FR': 'Copier', 'DE': 'Kopieren', 'RU': 'Копировать', 'AR': 'نسخ', 'HI': 'कॉपी करें', 'VI': 'Sao chép', 'ES': 'Copiar', 'TH': 'คัดลอก'},
  'Add': {'JA': '追加', 'ZH': '添加', 'FR': 'Ajouter', 'DE': 'Hinzufügen', 'RU': 'Добавить', 'AR': 'إضافة', 'HI': 'जोड़ें', 'VI': 'Thêm', 'ES': 'Añadir', 'TH': 'เพิ่ม'},
  'Reset': {'JA': 'リセット', 'ZH': '重置', 'FR': 'Réinitialiser', 'DE': 'Zurücksetzen', 'RU': 'Сбросить', 'AR': 'إعادة تعيين', 'HI': 'रीसेट करें', 'VI': 'Đặt lại', 'ES': 'Restablecer', 'TH': 'รีเซ็ต'},
  'Confirm': {'JA': '確認', 'ZH': '确认', 'FR': 'Confirmer', 'DE': 'Bestätigen', 'RU': 'Подтвердить', 'AR': 'تأكيد', 'HI': 'पुष्टि करें', 'VI': 'Xác nhận', 'ES': 'Confirmar', 'TH': 'ยืนยัน'},
  'No data': {'JA': 'データなし', 'ZH': '暂无数据', 'FR': 'Aucune donnée', 'DE': 'Keine Daten', 'RU': 'Нет данных', 'AR': 'لا توجد بيانات', 'HI': 'कोई डेटा नहीं', 'VI': 'Không có dữ liệu', 'ES': 'Sin datos', 'TH': 'ไม่มีข้อมูล'},
  'Keep': {'JA': '維持', 'ZH': '保留', 'FR': 'Conserver', 'DE': 'Beibehalten', 'RU': 'Оставить', 'AR': 'الاحتفاظ', 'HI': 'रखें', 'VI': 'Giữ nguyên', 'ES': 'Mantener', 'TH': 'เก็บไว้'},
  'Undo': {'JA': '元に戻す', 'ZH': '撤销', 'FR': 'Annuler', 'DE': 'Rückgängig', 'RU': 'Отменить', 'AR': 'تراجع', 'HI': 'पूर्ववत करें', 'VI': 'Hoàn tác', 'ES': 'Deshacer', 'TH': 'เลิกทำ'},
  'Got it': {'JA': '了解しました', 'ZH': '知道了', 'FR': "J'ai compris", 'DE': 'Verstanden', 'RU': 'Понятно', 'AR': 'حسناً', 'HI': 'समझ गया', 'VI': 'Đã hiểu', 'ES': 'Entendido', 'TH': 'เข้าใจแล้ว'},
};

// 🆕 [10개국어 확장] 공용 사전에서 찾아서 없으면 영어 그대로 반환하는 헬퍼
String tButton(String enKey) => commonButtonTranslations[enKey]?[appLanguage.current] ?? enKey;

String biHint(String en, String ko, {Map<String, String>? translations}) {
  if (!appLanguage.isDefault) {
    return translations?[appLanguage.current] ?? en;
  }
  return '$en ($ko)';
}

// 🆕 SnackBar 문구용 헬퍼 - 바로 ScaffoldMessenger에 넘겨서 사용
void biSnack(BuildContext context, String en, String ko, {Color? backgroundColor}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$en ($ko)', style: GoogleFonts.notoSansKr()),
      backgroundColor: backgroundColor,
    ),
  );
}

// 🆕 [가로형 3선 연필 아이콘 - 빨강/노랑/파랑] 타임기록/실행기록 화면의 수정 버튼용.
// 기존 대각선(파랑/노랑/흰색) 연필 아이콘과는 별도로, 이번 화면들은 가로로
// 놓인 3선(빨강/노랑/파랑)으로 표시합니다.
class HorizontalPencilIcon extends StatelessWidget {
  final double size;
  const HorizontalPencilIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: size * 0.9, height: size * 0.16, margin: const EdgeInsets.symmetric(vertical: 0.8), decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(2))),
          Container(width: size * 0.9, height: size * 0.16, margin: const EdgeInsets.symmetric(vertical: 0.8), decoration: BoxDecoration(color: const Color(0xFFFACC15), borderRadius: BorderRadius.circular(2))),
          Container(width: size * 0.9, height: size * 0.16, margin: const EdgeInsets.symmetric(vertical: 0.8), decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }
}

// 🆕 [고급 팝업 공용 컨테이너] 골드 테두리를 더 선명하고 진하게, 글로우를 강하게 준 버전.
// 캘린더 등 기존 화면보다 한 단계 더 고급스러운 느낌을 원할 때 이 위젯으로 감싸서 사용.
class LuxuryDialogFrame extends StatelessWidget {
  final Widget child;
  const LuxuryDialogFrame({super.key, required this.child});

  static const Color _brandGolden = Color(0xFFE5C158);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF141D33), Color(0xFF090D1A)],
        ),
        border: Border.all(color: _brandGolden.withOpacity(0.75), width: 1.6), // 🆕 더 선명한 골드 테두리
        boxShadow: [
          BoxShadow(color: _brandGolden.withOpacity(0.32), blurRadius: 42, spreadRadius: 2), // 🆕 강한 골드 글로우
          const BoxShadow(color: Colors.black, blurRadius: 26, offset: Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
      child: child,
    );
  }
}

// 🆕 [고급 팝업 헤더] 아이콘 + 영/한 제목 + 진한 골드 구분선
Widget luxuryDialogHeader({required IconData icon, required String en, required String ko, Map<String, String>? translations}) {
  const Color brandGolden = Color(0xFFE5C158);
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: brandGolden, size: 22),
          const SizedBox(width: 8),
          BiTitle(en: en, ko: ko, enSize: 16, koSize: 12.5, translations: translations),
        ],
      ),
      const SizedBox(height: 10),
      Container(
        height: 1.4,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.transparent, brandGolden.withOpacity(0.85), Colors.transparent]), // 🆕 더 선명한 구분선
        ),
      ),
      const SizedBox(height: 18),
    ],
  );
}

// 🆕 [맨 아래 버튼 한 줄] Delete(선택)/Cancel/Save를 한 줄에 배치하는 공용 위젯.
// showDelete가 true면 3개, false면 Cancel/Save 2개만 표시.
Widget luxuryBottomActions({
  required VoidCallback onCancel,
  required VoidCallback onSave,
  VoidCallback? onDelete,
  bool isEdit = false,
}) {
  const Color brandGolden = Color(0xFFE5C158);
  const Color pageBg = Color(0xFF030712);
  final bool isDefaultLang = appLanguage.isDefault; // 🆕 [10개국어 확장]

  return Row(
    children: [
      if (onDelete != null) ...[
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFDC2626)), padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: onDelete,
            child: isDefaultLang
                ? Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Delete', style: GoogleFonts.gowunBatang(color: const Color(0xFFDC2626), fontSize: 10.5, fontWeight: FontWeight.bold)),
              Text('삭제', style: GoogleFonts.notoSansKr(color: const Color(0xFFDC2626), fontSize: 10.5, fontWeight: FontWeight.bold)),
            ])
                : Text(tButton('Delete'), style: GoogleFonts.notoSansKr(color: const Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 8),
      ],
      Expanded(
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: onCancel,
          child: isDefaultLang
              ? Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Cancel', style: GoogleFonts.gowunBatang(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold)),
            Text('취소', style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold)),
          ])
              : Text(tButton('Cancel'), style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: brandGolden, padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 4, shadowColor: brandGolden.withOpacity(0.5)),
          onPressed: onSave,
          child: isDefaultLang
              ? Column(mainAxisSize: MainAxisSize.min, children: [
            Text(isEdit ? 'Update' : 'Save', style: GoogleFonts.gowunBatang(color: pageBg, fontSize: 10.5, fontWeight: FontWeight.bold)),
            Text(isEdit ? '수정완료' : '저장', style: GoogleFonts.notoSansKr(color: pageBg, fontSize: 10.5, fontWeight: FontWeight.bold)),
          ])
              : Text(tButton(isEdit ? 'Update' : 'Save'), style: GoogleFonts.notoSansKr(color: pageBg, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
    ],
  );
}

// ============================================================================
// 🆕 [최종 확정 아이콘] ThreeColorPencilIcon
// 빨강/노랑/파랑 3선을 가로로(대각선 아님) 놓고, 그 위에 실제 연필 모양을
// 겹쳐서 "3색선 + 연필"을 동시에 만족합니다. 앱 전체의 모든 수정 버튼은
// 이제부터 이 아이콘 하나로 통일합니다. (기존 TriColorPencilIcon,
// HorizontalPencilIcon, EditPencilIcon은 전부 이걸로 교체 예정)
// ============================================================================
class ThreeColorPencilIcon extends StatelessWidget {
  final double size;
  const ThreeColorPencilIcon({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 3색 가로선 (배경, 살짝 왼쪽 위 정렬)
          Positioned(
            left: 0,
            top: size * 0.12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: size * 0.62, height: size * 0.13, margin: EdgeInsets.symmetric(vertical: size * 0.045), decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(2))),
                Container(width: size * 0.62, height: size * 0.13, margin: EdgeInsets.symmetric(vertical: size * 0.045), decoration: BoxDecoration(color: const Color(0xFFFACC15), borderRadius: BorderRadius.circular(2))),
                Container(width: size * 0.62, height: size * 0.13, margin: EdgeInsets.symmetric(vertical: size * 0.045), decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ),
          // 진짜 연필 모양 (오른쪽 아래에 겹쳐서 배치)
          Positioned(
            right: -size * 0.05,
            bottom: -size * 0.08,
            child: Icon(Icons.edit_rounded, size: size * 0.58, color: const Color(0xFFE5C158)),
          ),
        ],
      ),
    );
  }
}

