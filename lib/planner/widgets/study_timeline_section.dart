import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../global_lang.dart'; // 👑 [12개국 연동] 전역 언어 스위치와 연결

/// ============================================================================
/// [GKE StudyUp] 학습 타임라인 및 시험대비 자동 전환 전담 위젯 섹션
/// ============================================================================
class StudyTimelineSection extends StatelessWidget {
  final List<Map<String, dynamic>> fixedDayTimelines;
  final DateTime selectedDayDate;
  final Color goldColor;
  final Color slate400;
  final Color slate800;
  final Color examColor;
  final Function(Map<String, dynamic>, int) onUnifiedPopupTrack;
  final VoidCallback onAddNewTimeSlot;

  const StudyTimelineSection({
    Key? key,
    required this.fixedDayTimelines,
    required this.selectedDayDate,
    required this.goldColor,
    required this.slate400,
    required this.slate800,
    required this.examColor,
    required this.onUnifiedPopupTrack,
    required this.onAddNewTimeSlot,
  }) : super(key: key);

  // ============================================================================
  // 🆕 [12개국 언어 시스템]
  // 기본값(마이페이지에서 12개국 중 하나를 고르기 전, 즉 DkeLang.current == 'KO' 상태 포함)은
  // 항상 "영문 + 한글"이 함께 보입니다 — 12개국에 없는 다른 나라 사용자도 영어로 볼 수 있게 하기 위함.
  // 마이페이지에서 한국/영어를 "제외한" 나머지 10개국 중 하나를 선택했을 때만
  // 그 선택한 언어 단독으로 화면이 전환됩니다.
  // ============================================================================
  static const List<String> _foreignLanguages = ['JA', 'ZH', 'FR', 'DE', 'RU', 'AR', 'HI', 'VI', 'ES', 'TH'];
  static bool get _isForeignSelected => _foreignLanguages.contains(DkeLang.current);

  static const Map<String, Map<String, String>> _uiText = {
    'extendTimeline': {
      'KO': '새로운 학습 시간대 확장 추가', 'EN': 'EXTEND TIMELINE',
      'JA': '新しい学習時間枠を追加', 'ZH': '添加新的学习时间段', 'FR': "Ajouter un nouveau créneau d'étude",
      'DE': 'Neuen Lernzeitraum hinzufügen', 'RU': 'Добавить новый учебный интервал', 'AR': 'إضافة فترة دراسة جديدة',
      'HI': 'नया अध्ययन समय स्लॉट जोड़ें', 'VI': 'Thêm khung giờ học mới', 'ES': 'Añadir nuevo bloque de estudio', 'TH': 'เพิ่มช่วงเวลาเรียนใหม่',
    },
    'academicTimeline': {
      'KO': '학사 타임라인', 'EN': 'ACADEMIC TIMELINE',
      'JA': '学事タイムライン', 'ZH': '学业时间线', 'FR': 'Chronologie académique',
      'DE': 'Akademische Zeitleiste', 'RU': 'Учебная хронология', 'AR': 'الجدول الزمني الأكاديمي',
      'HI': 'शैक्षणिक समयरेखा', 'VI': 'Dòng thời gian học tập', 'ES': 'Cronología académica', 'TH': 'ไทม์ไลน์การเรียน',
    },
    'emptyAcademicTimeline': {
      'KO': '등록된 타임라인 상세 일정이 없습니다.', 'EN': 'No detailed timeline schedule registered.',
      'JA': '登録されたタイムライン詳細日程がありません。', 'ZH': '暂无已登记的详细时间线安排。', 'FR': 'Aucun programme détaillé enregistré.',
      'DE': 'Kein detaillierter Zeitplan registriert.', 'RU': 'Подробное расписание не добавлено.', 'AR': 'لا يوجد جدول زمني تفصيلي مسجل.',
      'HI': 'कोई विस्तृत समयरेखा शेड्यूल दर्ज नहीं है।', 'VI': 'Chưa có lịch trình chi tiết nào được đăng ký.', 'ES': 'No hay horario detallado registrado.', 'TH': 'ไม่มีตารางเวลาโดยละเอียดที่ลงทะเบียนไว้',
    },
    'editTaskDialogTitle': {
      'KO': '타임라인 항목 수정', 'EN': 'Edit Timeline Item',
      'JA': 'タイムライン項目編集', 'ZH': '编辑时间线项目', 'FR': "Modifier l'élément de chronologie",
      'DE': 'Zeitleisten-Eintrag bearbeiten', 'RU': 'Изменить элемент хронологии', 'AR': 'تعديل عنصر الجدول الزمني',
      'HI': 'समयरेखा आइटम संपादित करें', 'VI': 'Chỉnh sửa mục dòng thời gian', 'ES': 'Editar elemento de cronología', 'TH': 'แก้ไขรายการไทม์ไลน์',
    },
    'timeFieldLabel': {
      'KO': '시간', 'EN': 'Time', 'JA': '時間', 'ZH': '时间', 'FR': 'Heure', 'DE': 'Zeit',
      'RU': 'Время', 'AR': 'الوقت', 'HI': 'समय', 'VI': 'Thời gian', 'ES': 'Hora', 'TH': 'เวลา',
    },
    'contentSubjectFieldLabel': {
      'KO': '내용/과목', 'EN': 'Content / Subject', 'JA': '内容／科目', 'ZH': '内容／科目', 'FR': 'Contenu / Matière', 'DE': 'Inhalt / Fach',
      'RU': 'Содержание / Предмет', 'AR': 'المحتوى / المادة', 'HI': 'सामग्री / विषय', 'VI': 'Nội dung / Môn học', 'ES': 'Contenido / Materia', 'TH': 'เนื้อหา/วิชา',
    },
    'cancelBtn': {
      'KO': '취소', 'EN': 'Cancel', 'JA': 'キャンセル', 'ZH': '取消', 'FR': 'Annuler', 'DE': 'Abbrechen',
      'RU': 'Отмена', 'AR': 'إلغاء', 'HI': 'रद्द करें', 'VI': 'Hủy', 'ES': 'Cancelar', 'TH': 'ยกเลิก',
    },
    'saveBtn': {
      'KO': '저장', 'EN': 'Save', 'JA': '保存', 'ZH': '保存', 'FR': 'Enregistrer', 'DE': 'Speichern',
      'RU': 'Сохранить', 'AR': 'حفظ', 'HI': 'सहेजें', 'VI': 'Lưu', 'ES': 'Guardar', 'TH': 'บันทึก',
    },
    'deleteTaskDialogTitle': {
      'KO': '항목 삭제', 'EN': 'Delete Item', 'JA': '項目削除', 'ZH': '删除项目', 'FR': "Supprimer l'élément", 'DE': 'Eintrag löschen',
      'RU': 'Удалить элемент', 'AR': 'حذف العنصر', 'HI': 'आइटम हटाएं', 'VI': 'Xóa mục', 'ES': 'Eliminar elemento', 'TH': 'ลบรายการ',
    },
    'deleteConfirmMsg': {
      'KO': '선택하신 타임라인 일정을 정말 삭제하시겠습니까?', 'EN': 'Are you sure you want to delete the selected timeline entry?',
      'JA': '選択したタイムライン日程を本当に削除しますか？', 'ZH': '确定要删除所选的时间线日程吗？', 'FR': "Voulez-vous vraiment supprimer l'entrée de chronologie sélectionnée ?",
      'DE': 'Möchten Sie den ausgewählten Zeitleisteneintrag wirklich löschen?', 'RU': 'Вы уверены, что хотите удалить выбранную запись хронологии?', 'AR': 'هل أنت متأكد أنك تريد حذف إدخال الجدول الزمني المحدد؟',
      'HI': 'क्या आप वाकई चयनित समयरेखा प्रविष्टि हटाना चाहते हैं?', 'VI': 'Bạn có chắc muốn xóa mục dòng thời gian đã chọn không?', 'ES': '¿Seguro que quieres eliminar la entrada de cronología seleccionada?', 'TH': 'แน่ใจหรือไม่ว่าต้องการลบรายการไทม์ไลน์ที่เลือก?',
    },
    'deleteBtn': {
      'KO': '삭제', 'EN': 'Delete', 'JA': '削除', 'ZH': '删除', 'FR': 'Supprimer', 'DE': 'Löschen',
      'RU': 'Удалить', 'AR': 'حذف', 'HI': 'हटाएं', 'VI': 'Xóa', 'ES': 'Eliminar', 'TH': 'ลบ',
    },
    'editTooltip': {
      'KO': '수정', 'EN': 'Edit', 'JA': '編集', 'ZH': '编辑', 'FR': 'Modifier', 'DE': 'Bearbeiten',
      'RU': 'Изменить', 'AR': 'تعديل', 'HI': 'संपादित करें', 'VI': 'Sửa', 'ES': 'Editar', 'TH': 'แก้ไข',
    },
  };

  static String _foreignOnly(String key) {
    final map = _uiText[key]!;
    return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? key;
  }

  // 🆕 한 줄짜리 문자열이 필요한 곳(라벨, 버튼, 툴팁)에서 사용:
  // 기본값 = "EN / KO" 한 줄 표기, 10개국 선택 시 = 그 언어 단독
  static String _biStr(String key) {
    if (_isForeignSelected) return _foreignOnly(key);
    final map = _uiText[key]!;
    return '${map['EN']} / ${map['KO']}';
  }

  // 🆕 제목처럼 "영문 위 / 한글 아래" 2단으로 보여줘야 하는 곳에서 사용:
  // 기본값 = 2줄(영문+한글), 10개국 선택 시 = 그 언어 단독 1줄
  static Widget _biTitle(
      String key, {
        required TextStyle enStyle,
        required TextStyle koStyle,
        TextStyle? foreignStyle,
        CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
      }) {
    if (_isForeignSelected) {
      return Text(
        _foreignOnly(key),
        style: foreignStyle ?? koStyle,
        overflow: TextOverflow.fade,
        softWrap: false,
        maxLines: 1,
      );
    }
    final map = _uiText[key]!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(map['EN']!, style: enStyle, overflow: TextOverflow.fade, softWrap: false, maxLines: 1),
        Text(map['KO']!, style: koStyle, overflow: TextOverflow.fade, softWrap: false, maxLines: 1),
      ],
    );
  }

  // 🆕 안내문처럼 문장이 긴 곳에서 사용: 기본값 = 영문 문장 + 한글 문장 두 줄, 10개국 선택 시 = 그 언어 단독
  static Widget _biParagraph(
      String key, {
        required TextStyle enStyle,
        required TextStyle koStyle,
        TextStyle? foreignStyle,
        TextAlign? textAlign,
      }) {
    if (_isForeignSelected) {
      return Text(_foreignOnly(key), style: foreignStyle ?? koStyle, textAlign: textAlign);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // [주석] 타임라인 인스턴스 리스트 루프 생성 구간
        ...fixedDayTimelines.asMap().entries.map((entry) {
          final timelineItem = entry.value;
          final index = entry.key;

          return GestureDetector(
            onTap: () => onUnifiedPopupTrack(timelineItem, index),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: slate800),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // [주석] 시간대 레이블 표시 구역
                  SizedBox(
                    width: 105,
                    child: Text(
                      timelineItem['time'],
                      style: GoogleFonts.notoSerif(
                        fontSize: 15, // 원장님 지시: 타이틀/강조 글자크기 15 준수
                        color: goldColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // [주석] 학습 계획 명칭 및 세부 메모 영역 (자동 줄바꿈 커버)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                timelineItem['title'],
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 12, // 원장님 지시: 일반 글자크기 12 준수
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                softWrap: true,
                              ),
                            ),
                            if (timelineItem['is_starred'] == true) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.star, color: goldColor, size: 14),
                            ]
                          ],
                        ),
                        if ((timelineItem['memo'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            timelineItem['memo'],
                            style: GoogleFonts.notoSansKr(
                              fontSize: 12, // 원장님 지시: 일반 글자크기 12 준수
                              color: slate400,
                            ),
                            softWrap: true,
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.remove_red_eye, color: Colors.blueGrey, size: 14),
                ],
              ),
            ),
          );
        }).toList(),

        const SizedBox(height: 12),

        // [주석] 새로운 학습 시간대 확장 추가 버튼 레일
        SizedBox(
          width: double.infinity,
          height: 48, // 가독성을 위해 크기 최적화
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: goldColor.withOpacity(0.5)),
              backgroundColor: const Color(0xFF020617),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: Icon(Icons.more_time, color: goldColor, size: 16),
            // 🆕 [12개국] 기본값 = 영문(EXTEND TIMELINE)+한글 2단 표시, 10개국 선택 시 = 단일 언어
            label: _biTitle(
              'extendTimeline',
              crossAxisAlignment: CrossAxisAlignment.center,
              enStyle: GoogleFonts.notoSerif(fontSize: 12, color: goldColor, fontWeight: FontWeight.bold),
              koStyle: GoogleFonts.notoSansKr(fontSize: 12, color: goldColor, fontWeight: FontWeight.bold),
              foreignStyle: GoogleFonts.notoSans(fontSize: 12, color: goldColor, fontWeight: FontWeight.bold),
            ),
            onPressed: onAddNewTimeSlot,
          ),
        ),
      ],
    );
  }

  // [주석] 학사 타임라인 전용 렌더링 및 수정/삭제 팝업 연동 위젯 (study_timeline_section.dart 최하단 추가)
  Widget _buildAcademicTimelineSection(BuildContext context, String timelineName, List<Map<String, String>> scheduleList) {
    return ListView(
      shrinkWrap: true, // 👈 스크롤 충돌 방지
      physics: const NeverScrollableScrollPhysics(), // 👈 외부 스크롤과 연동
      padding: EdgeInsets.zero, // 👈 사이공간 없이 최소한으로 붙이기 위한 패딩 제거
      children: [
        // 1. gsu_logo.png 최상단 밀착 배치 (사이공간 최소화)
        Image.asset(
          'assets/gsu_logo.png',
          height: 40,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
        ),
        const SizedBox(height: 4), // 👈 로고와 타이틀 사이 최소한의 간격

        // 2. 타이틀 영역: 🆕 [12개국] 기본값 = 영문 명조체 + 노토 산스 한글 2단, 10개국 선택 시 = 단일 언어
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: _biTitle(
            'academicTimeline',
            enStyle: GoogleFonts.notoSerif(fontSize: 16, color: goldColor, fontWeight: FontWeight.bold),
            koStyle: GoogleFonts.notoSansKr(fontSize: 18, color: goldColor, fontWeight: FontWeight.bold),
            foreignStyle: GoogleFonts.notoSans(fontSize: 17, color: goldColor, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(color: Color(0xFF1E293B), height: 20),

        // 3. 타임라인 명칭 표시 (좌측 정렬 뱃지 스타일) — 데이터값이라 언어 처리 대상 아님
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: goldColor, width: 1),
          ),
          child: Text(
            timelineName,
            style: GoogleFonts.notoSansKr(fontSize: 13, color: goldColor, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),

        // 4. 시간표 목록 아래로 좌악 렌더링 + 각 타임별 [수정] / [삭제] 팝업 연동
        if (scheduleList.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: _biParagraph(
                'emptyAcademicTimeline',
                textAlign: TextAlign.center,
                enStyle: GoogleFonts.notoSans(color: Colors.grey, fontSize: 12),
                koStyle: GoogleFonts.notoSansKr(color: Colors.grey, fontSize: 13),
                foreignStyle: GoogleFonts.notoSans(color: Colors.grey, fontSize: 13),
              ),
            ),
          )
        else
          ...scheduleList.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, String> item = entry.value;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 85,
                    child: Text(item['time'] ?? '', style: GoogleFonts.notoSerif(fontSize: 12, color: goldColor, fontWeight: FontWeight.bold)),
                  ),
                  Container(width: 2, height: 28, margin: const EdgeInsets.symmetric(horizontal: 8), color: goldColor),
                  Expanded(
                    child: Text(item['task'] ?? '', style: GoogleFonts.notoSansKr(fontSize: 12, color: Colors.white)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16, color: Colors.amberAccent),
                    tooltip: _biStr('editTooltip'), // 🆕 [12개국] 기본값 "Edit / 수정", 10개국 선택 시 단일 언어
                    onPressed: () {
                      _showEditTaskPopup(context, index, item);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 16, color: Colors.redAccent),
                    tooltip: _biStr('deleteBtn'), // 🆕 [12개국] 기본값 "Delete / 삭제", 10개국 선택 시 단일 언어
                    onPressed: () {
                      _showDeleteTaskPopup(context, index);
                    },
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  void _showEditTaskPopup(BuildContext context, int index, Map<String, String> currentItem) {
    TextEditingController timeController = TextEditingController(text: currentItem['time']);
    TextEditingController taskController = TextEditingController(text: currentItem['task']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          // 🆕 [12개국] 기본값 = 영문+한글 2단, 10개국 선택 시 = 단일 언어
          title: _biTitle(
            'editTaskDialogTitle',
            enStyle: GoogleFonts.notoSerif(fontSize: 14, color: goldColor, fontWeight: FontWeight.bold),
            koStyle: GoogleFonts.notoSansKr(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold),
            foreignStyle: GoogleFonts.notoSans(color: goldColor, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: timeController,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(labelText: _biStr('timeFieldLabel'), labelStyle: const TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: taskController,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(labelText: _biStr('contentSubjectFieldLabel'), labelStyle: const TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(_biStr('cancelBtn'), style: const TextStyle(color: Colors.grey))),
            TextButton(onPressed: () => Navigator.pop(context), child: Text(_biStr('saveBtn'), style: TextStyle(color: goldColor))),
          ],
        );
      },
    );
  }

  void _showDeleteTaskPopup(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          // 🆕 [12개국] 기본값 = 영문+한글 2단, 10개국 선택 시 = 단일 언어
          title: _biTitle(
            'deleteTaskDialogTitle',
            enStyle: GoogleFonts.notoSerif(fontSize: 14, color: Colors.redAccent, fontWeight: FontWeight.bold),
            koStyle: GoogleFonts.notoSansKr(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.bold),
            foreignStyle: GoogleFonts.notoSans(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          // 🆕 [12개국] 기본값 = 영문 문장+한글 문장, 10개국 선택 시 = 단일 언어
          content: _biParagraph(
            'deleteConfirmMsg',
            enStyle: GoogleFonts.notoSans(color: Colors.white, fontSize: 12),
            koStyle: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
            foreignStyle: GoogleFonts.notoSans(color: Colors.white, fontSize: 12),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(_biStr('cancelBtn'), style: const TextStyle(color: Colors.grey))),
            TextButton(onPressed: () => Navigator.pop(context), child: Text(_biStr('deleteBtn'), style: const TextStyle(color: Colors.redAccent))),
          ],
        );
      },
    );
  }
}
