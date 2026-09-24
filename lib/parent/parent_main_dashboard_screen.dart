import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🆕 [자녀 선택 UI] DocumentSnapshot 타입 참조용

import 'parent_live_status_widget.dart';
import 'parent_detailed_analysis_widget.dart';
import 'parent_evaluation_analysis_widget.dart';
import 'parent_grade_management_widget.dart'; // 🆕 [성적 관리] 학부모 조회 전용 4번째 탭
import '../services/parent_data_service.dart';
import '../services/diagnosis_service.dart'; // 🆕 [요청] 300자 이상 AI 진단문 + 재사용 규칙 서비스
import '../services/family_link_service.dart'; // 🆕 [자녀 추가] 가족 연결 코드 서비스
import '../services/grade_management_service.dart'; // 🆕 [성적 관리] GradeRecord/SubjectConfig 타입 참조용
import '../services/auth_service.dart'; // 🆕 [로그아웃 기능] 실제 로그인/로그아웃 처리
import '../main.dart' show EntranceScreen; // 🆕 [로그아웃 기능] 로그아웃 후 돌아갈 대문 화면
import '../global_lang.dart';
import '../services/scholarship_service.dart'; // 🆕 [장학금 방 2026-09-17] 유형별 금액 계산

// ---------------------------------------------------------------------------
// 🆕 [다국어] DkeLang 연동: 기본모드(KO/EN)는 한글+영문 동시 표시,
// 10개국어(JA/ZH/FR/DE/RU/AR/HI/VI/ES/TH) 선택 시 해당 언어만 단독 표시.
// 실제 데이터 비교 로직(예: rec.recordType == '평가')은 절대 건드리지 않고,
// 화면에 보여줄 때만 이 파일 안의 번역 사전을 거쳐 표시합니다.
// ---------------------------------------------------------------------------
String _t(Map<String, String> map) {
  return map[DkeLang.current] ?? map['EN'] ?? map['KO'] ?? '';
}

String _bi(Map<String, String> map) {
  if (DkeLang.isForeignSelected) return _t(map);
  return "${map['KO']}/${map['EN']}";
}

String _biLong(Map<String, String> map) {
  if (DkeLang.isForeignSelected) return _t(map);
  return "${map['KO']}\n${map['EN']}";
}

bool get _isNumberFirstLang => DkeLang.current == 'KO';

const Map<String, String> kVipLinkMap = {
  'KO': '회원 연동',
  'EN': 'Link Account',
  'JA': '会員連携',
  'ZH': '会员关联',
  'FR': 'Lier le compte',
  'DE': 'Konto verknüpfen',
  'RU': 'Связать аккаунт',
  'AR': 'ربط الحساب',
  'HI': 'खाता लिंक करें',
  'VI': 'Liên kết TK',
  'ES': 'Vincular cuenta',
  'TH': 'เชื่อมบัญชี',
};
const Map<String, String> kVipBadgeMap = {
  'KO': '👑 VIP',
  'EN': '👑 VIP',
  'JA': '👑 VIP',
  'ZH': '👑 VIP',
  'FR': '👑 VIP',
  'DE': '👑 VIP',
  'RU': '👑 VIP',
  'AR': '👑 VIP',
  'HI': '👑 VIP',
  'VI': '👑 VIP',
  'ES': '👑 VIP',
  'TH': '👑 VIP',
};

const Map<String, String> kEmojiSentMap = {
  'KO': '자녀의 타이머 세션 상단에 격려 팝업 발송 완료 ☆',
  'EN': 'Encouragement popup sent to the top of your child\'s timer session ☆',
  'JA': 'お子様のタイマーセッション上部に応援ポップアップを送信しました ☆',
  'ZH': '已在孩子的计时会话顶部发送鼓励弹窗 ☆',
  'FR':
      'Pop-up d\'encouragement envoyé en haut de la session minuteur de votre enfant ☆',
  'DE': 'Ermutigungs-Popup oben in der Timer-Sitzung Ihres Kindes gesendet ☆',
  'RU':
      'Всплывающее сообщение поддержки отправлено в начало сеанса таймера ребёнка ☆',
  'AR': 'تم إرسال نافذة تشجيع أعلى جلسة المؤقت لطفلك ☆',
  'HI': 'आपके बच्चे के टाइमर सत्र के शीर्ष पर प्रोत्साहन पॉपअप भेजा गया ☆',
  'VI': 'Đã gửi thông báo động viên lên đầu phiên hẹn giờ của con ☆',
  'ES':
      'Ventana de ánimo enviada a la parte superior de la sesión del temporizador de su hijo/a ☆',
  'TH': 'ส่งป๊อปอัปให้กำลังใจไปด้านบนของเซสชันจับเวลาของบุตรหลานแล้ว ☆',
};
const Map<String, String> kForceInterventionMap = {
  'KO': '👑 [강제 개입] 자녀 타이머 점유 완료 (답장차단 모달 제어 중)',
  'EN': '👑 [Override] Child\'s timer taken over (reply-blocking modal active)',
  'JA': '👑 [強制介入] お子様のタイマーを占有しました（返信ブロックモーダル制御中）',
  'ZH': '👑 [强制介入] 已占用孩子的计时器（回复屏蔽弹窗控制中）',
  'FR':
      '👑 [Intervention forcée] Minuteur de l\'enfant repris (fenêtre modale de blocage active)',
  'DE':
      '👑 [Zwangseingriff] Timer des Kindes übernommen (Antwortsperr-Modal aktiv)',
  'RU':
      '👑 [Принудительное вмешательство] Таймер ребёнка перехвачен (модальное окно блокировки ответа активно)',
  'AR': '👑 [تدخل إجباري] تم الاستحواذ على مؤقت الطفل (نافذة حظر الرد نشطة)',
  'HI':
      '👑 [जबरन हस्तक्षेप] बच्चे का टाइमर अधिग्रहित (उत्तर-अवरोधक मोडल सक्रिय)',
  'VI':
      '👑 [Can thiệp bắt buộc] Đã chiếm quyền hẹn giờ của con (hộp thoại chặn phản hồi đang hoạt động)',
  'ES':
      '👑 [Intervención forzada] Temporizador del hijo/a tomado (modal de bloqueo de respuesta activo)',
  'TH':
      '👑 [แทรกแซงบังคับ] เข้าควบคุมตัวจับเวลาของบุตรหลานแล้ว (โมดัลบล็อกการตอบกลับทำงานอยู่)',
};
const Map<String, String> kMessageContentLabelMap = {
  'KO': '내용',
  'EN': 'Message',
  'JA': '内容',
  'ZH': '内容',
  'FR': 'Message',
  'DE': 'Nachricht',
  'RU': 'Сообщение',
  'AR': 'الرسالة',
  'HI': 'संदेश',
  'VI': 'Nội dung',
  'ES': 'Mensaje',
  'TH': 'ข้อความ',
};

const Map<String, String> kMonitorTimeoutMap = {
  'KO': '1분 경과로 인한 automatic 블로킹 활성화 (종료됨)',
  'EN': 'Automatic blocking activated after 1 minute elapsed (ended)',
  'JA': '1分経過による自動ブロックが有効化されました（終了）',
  'ZH': '经过1分钟后自动屏蔽已启用（已结束）',
  'FR': 'Blocage automatique activé après 1 minute (terminé)',
  'DE': 'Automatische Blockierung nach 1 Minute aktiviert (beendet)',
  'RU': 'Автоматическая блокировка активирована через 1 минуту (завершено)',
  'AR': 'تم تفعيل الحظر التلقائي بعد مرور دقيقة واحدة (انتهى)',
  'HI': '1 मिनट बीतने पर स्वचालित ब्लॉकिंग सक्रिय (समाप्त)',
  'VI': 'Đã kích hoạt chặn tự động sau 1 phút (đã kết thúc)',
  'ES': 'Bloqueo automático activado tras 1 minuto (finalizado)',
  'TH': 'เปิดใช้งานการบล็อกอัตโนมัติหลังผ่านไป 1 นาที (สิ้นสุดแล้ว)',
};

const Map<String, String> kNoSessionTodayMap = {
  'KO': '오늘 아직 기록된 학습 세션이 없습니다. 자녀가 학습을 마치고 기록을 저장하면 이곳에 요약이 표시됩니다.',
  'EN':
      "No study sessions recorded yet today. Once your child finishes studying and saves a record, a summary will appear here.",
  'JA': '本日はまだ記録された学習セッションがありません。お子様が学習を終えて記録を保存すると、ここに要約が表示されます。',
  'ZH': '今天尚无学习会话记录。孩子完成学习并保存记录后，摘要将显示在此处。',
  'FR':
      "Aucune session d'étude enregistrée aujourd'hui. Un résumé apparaîtra ici une fois que votre enfant aura terminé et enregistré une session.",
  'DE':
      'Heute wurden noch keine Lernsitzungen aufgezeichnet. Sobald Ihr Kind eine Sitzung speichert, erscheint hier eine Zusammenfassung.',
  'RU':
      'Сегодня пока не записано ни одного учебного занятия. После того как ребёнок закончит и сохранит запись, здесь появится сводка.',
  'AR':
      'لا توجد جلسات دراسية مسجلة اليوم بعد. بمجرد أن ينتهي طفلك من الدراسة ويحفظ سجلاً، سيظهر الملخص هنا.',
  'HI':
      'आज तक कोई अध्ययन सत्र दर्ज नहीं हुआ है। जैसे ही आपका बच्चा पढ़ाई पूरी कर रिकॉर्ड सहेजेगा, सारांश यहाँ दिखाई देगा।',
  'VI':
      'Hôm nay chưa có phiên học nào được ghi lại. Khi con bạn học xong và lưu hồ sơ, bản tóm tắt sẽ hiển thị tại đây.',
  'ES':
      'Aún no se ha registrado ninguna sesión de estudio hoy. Cuando su hijo/a termine y guarde un registro, aparecerá aquí un resumen.',
  'TH':
      'วันนี้ยังไม่มีการบันทึกเซสชันการเรียน เมื่อบุตรหลานเรียนเสร็จและบันทึกข้อมูลแล้ว บทสรุปจะแสดงที่นี่',
};
const Map<String, String> kReportHeaderMap = {
  'KO': '[종합 리포트]',
  'EN': '[Overall Report]',
  'JA': '[総合レポート]',
  'ZH': '[综合报告]',
  'FR': '[Rapport global]',
  'DE': '[Gesamtbericht]',
  'RU': '[Общий отчёт]',
  'AR': '[التقرير الشامل]',
  'HI': '[समग्र रिपोर्ट]',
  'VI': '[Báo cáo tổng hợp]',
  'ES': '[Informe general]',
  'TH': '[รายงานสรุป]',
};
const Map<String, String> kPeriodWordMap = {
  'KO': '교시',
  'EN': 'Period',
  'JA': '時限',
  'ZH': '节',
  'FR': 'Séance',
  'DE': 'Einheit',
  'RU': 'Занятие',
  'AR': 'حصة',
  'HI': 'पीरियड',
  'VI': 'Tiết',
  'ES': 'Sesión',
  'TH': 'คาบ',
};
const Map<String, String> kFocusCompletedMap = {
  'KO': '분 집중완료',
  'EN': 'min focused',
  'JA': '分 集中完了',
  'ZH': '分钟 专注完成',
  'FR': 'min de concentration terminées',
  'DE': 'Min. fokussiert',
  'RU': 'мин сосредоточенности',
  'AR': 'دقيقة تركيز مكتمل',
  'HI': 'मिनट फोकस पूर्ण',
  'VI': 'phút tập trung hoàn thành',
  'ES': 'min de concentración',
  'TH': 'นาที โฟกัสสำเร็จ',
};
const Map<String, String> kScoreLabelMap = {
  'KO': '점수',
  'EN': 'Score',
  'JA': '点数',
  'ZH': '分数',
  'FR': 'Score',
  'DE': 'Punktzahl',
  'RU': 'Балл',
  'AR': 'الدرجة',
  'HI': 'स्कोर',
  'VI': 'Điểm',
  'ES': 'Puntuación',
  'TH': 'คะแนน',
};
const Map<String, String> kTodayTotalTimeMap = {
  'KO': '오늘 총 학습시간',
  'EN': "Today's Total Study Time",
  'JA': '本日の総学習時間',
  'ZH': '今日总学习时间',
  'FR': "Temps d'étude total aujourd'hui",
  'DE': 'Heutige Gesamtlernzeit',
  'RU': 'Общее время учёбы сегодня',
  'AR': 'إجمالي وقت الدراسة اليوم',
  'HI': 'आज कुल अध्ययन समय',
  'VI': 'Tổng thời gian học hôm nay',
  'ES': 'Tiempo total de estudio de hoy',
  'TH': 'เวลาเรียนรวมวันนี้',
};
const Map<String, String> kMinutesUnitMap = {
  'KO': '분',
  'EN': 'min',
  'JA': '分',
  'ZH': '分钟',
  'FR': 'min',
  'DE': 'Min.',
  'RU': 'мин',
  'AR': 'دقيقة',
  'HI': 'मिनट',
  'VI': 'phút',
  'ES': 'min',
  'TH': 'นาที',
};
const Map<String, String> kTodaySummaryHeaderMap = {
  'KO': '[오늘의 종합 분석]',
  'EN': "[Today's Overall Analysis]",
  'JA': '[本日の総合分析]',
  'ZH': '[今日综合分析]',
  'FR': "[Analyse globale du jour]",
  'DE': '[Heutige Gesamtanalyse]',
  'RU': '[Общий анализ за сегодня]',
  'AR': '[التحليل الشامل لليوم]',
  'HI': '[आज का समग्र विश्लेषण]',
  'VI': '[Phân tích tổng hợp hôm nay]',
  'ES': '[Análisis general de hoy]',
  'TH': '[การวิเคราะห์โดยรวมวันนี้]',
};

const Map<String, String> kNoDetailTodayMap = {
  'KO': '오늘 상세 분석할 학습 기록이 아직 없습니다.',
  'EN': "No study records available for detailed analysis today.",
  'JA': '本日、詳細分析できる学習記録がまだありません。',
  'ZH': '今天尚无可供详细分析的学习记录。',
  'FR':
      "Aucun enregistrement d'étude disponible pour une analyse détaillée aujourd'hui.",
  'DE':
      'Heute liegen noch keine Lernaufzeichnungen für eine detaillierte Analyse vor.',
  'RU': 'Сегодня пока нет учебных записей для подробного анализа.',
  'AR': 'لا توجد سجلات دراسية متاحة للتحليل التفصيلي اليوم.',
  'HI': 'आज विस्तृत विश्लेषण के लिए कोई अध्ययन रिकॉर्ड उपलब्ध नहीं है।',
  'VI': 'Hôm nay chưa có hồ sơ học tập nào để phân tích chi tiết.',
  'ES':
      'Hoy no hay registros de estudio disponibles para un análisis detallado.',
  'TH': 'วันนี้ยังไม่มีบันทึกการเรียนสำหรับการวิเคราะห์เชิงลึก',
};
const Map<String, String> kDetailHeaderMap = {
  'KO': '[상세분석기록 - 오늘 학습한 모든 세션]',
  'EN': '[Detailed Records - All Sessions Today]',
  'JA': '[詳細分析記録 - 本日の全セッション]',
  'ZH': '[详细分析记录 - 今日全部会话]',
  'FR': "[Analyse détaillée - Toutes les sessions du jour]",
  'DE': '[Detaillierte Aufzeichnung - Alle heutigen Sitzungen]',
  'RU': '[Подробная запись - все занятия за сегодня]',
  'AR': '[سجل تفصيلي - جميع جلسات اليوم]',
  'HI': '[विस्तृत रिकॉर्ड - आज के सभी सत्र]',
  'VI': '[Hồ sơ chi tiết - Tất cả phiên học hôm nay]',
  'ES': '[Registro detallado - Todas las sesiones de hoy]',
  'TH': '[บันทึกเชิงลึก - ทุกเซสชันวันนี้]',
};
const Map<String, String> kDetailContentLabelMap = {
  'KO': '상세내용',
  'EN': 'Details',
  'JA': '詳細内容',
  'ZH': '详细内容',
  'FR': 'Détails',
  'DE': 'Details',
  'RU': 'Подробности',
  'AR': 'التفاصيل',
  'HI': 'विवरण',
  'VI': 'Chi tiết',
  'ES': 'Detalles',
  'TH': 'รายละเอียด',
};
const Map<String, String> kNoRecordMap = {
  'KO': '기록 없음',
  'EN': 'No record',
  'JA': '記録なし',
  'ZH': '无记录',
  'FR': 'Aucun enregistrement',
  'DE': 'Keine Aufzeichnung',
  'RU': 'Нет записи',
  'AR': 'لا يوجد سجل',
  'HI': 'कोई रिकॉर्ड नहीं',
  'VI': 'Không có',
  'ES': 'Sin registro',
  'TH': 'ไม่มีบันทึก',
};
const Map<String, String> kUnderstandingLabelMap = {
  'KO': '이해도',
  'EN': 'Understanding',
  'JA': '理解度',
  'ZH': '理解度',
  'FR': 'Compréhension',
  'DE': 'Verständnis',
  'RU': 'Понимание',
  'AR': 'مستوى الفهم',
  'HI': 'समझ',
  'VI': 'Mức hiểu',
  'ES': 'Comprensión',
  'TH': 'ความเข้าใจ',
};
const Map<String, String> kDifficultyLabelMap = {
  'KO': '난이도',
  'EN': 'Difficulty',
  'JA': '難易度',
  'ZH': '难度',
  'FR': 'Difficulté',
  'DE': 'Schwierigkeit',
  'RU': 'Сложность',
  'AR': 'الصعوبة',
  'HI': 'कठिनाई',
  'VI': 'Độ khó',
  'ES': 'Dificultad',
  'TH': 'ความยาก',
};
const Map<String, String> kConcentrationLabelMap = {
  'KO': '집중도',
  'EN': 'Concentration',
  'JA': '集中度',
  'ZH': '专注度',
  'FR': 'Concentration',
  'DE': 'Konzentration',
  'RU': 'Концентрация',
  'AR': 'التركيز',
  'HI': 'एकाग्रता',
  'VI': 'Mức tập trung',
  'ES': 'Concentración',
  'TH': 'สมาธิ',
};
const Map<String, String> kConditionLabelMap = {
  'KO': '학습컨디션',
  'EN': 'Condition',
  'JA': '学習コンディション',
  'ZH': '学习状态',
  'FR': "État d'étude",
  'DE': 'Lernzustand',
  'RU': 'Состояние',
  'AR': 'حالة الدراسة',
  'HI': 'अध्ययन स्थिति',
  'VI': 'Tình trạng học',
  'ES': 'Estado de estudio',
  'TH': 'สภาพการเรียน',
};
const Map<String, String> kIncorrectNoteLabelMap = {
  'KO': '오답정리',
  'EN': 'Error Review',
  'JA': '誤答整理',
  'ZH': '错题整理',
  'FR': "Révision des erreurs",
  'DE': 'Fehlerüberprüfung',
  'RU': 'Разбор ошибок',
  'AR': 'مراجعة الأخطاء',
  'HI': 'त्रुटि समीक्षा',
  'VI': 'Xem lại lỗi sai',
  'ES': 'Revisión de errores',
  'TH': 'ทบทวนข้อผิดพลาด',
};
const Map<String, String> kNextGoalLabelMap = {
  'KO': '다음목표',
  'EN': 'Next Goal',
  'JA': '次の目標',
  'ZH': '下一目标',
  'FR': 'Prochain objectif',
  'DE': 'Nächstes Ziel',
  'RU': 'Следующая цель',
  'AR': 'الهدف التالي',
  'HI': 'अगला लक्ष्य',
  'VI': 'Mục tiêu tiếp theo',
  'ES': 'Próximo objetivo',
  'TH': 'เป้าหมายถัดไป',
};

const Map<String, String> kRecordTypeLectureMap = {
  'KO': '강의',
  'EN': 'Lecture',
  'JA': '講義',
  'ZH': '讲课',
  'FR': 'Cours',
  'DE': 'Vorlesung',
  'RU': 'Лекция',
  'AR': 'محاضرة',
  'HI': 'व्याख्यान',
  'VI': 'Bài giảng',
  'ES': 'Clase',
  'TH': 'บรรยาย',
};
const Map<String, String> kRecordTypeEvalMap = {
  'KO': '평가',
  'EN': 'Evaluation',
  'JA': '評価',
  'ZH': '评估',
  'FR': 'Évaluation',
  'DE': 'Bewertung',
  'RU': 'Оценка',
  'AR': 'تقييم',
  'HI': 'मूल्यांकन',
  'VI': 'Đánh giá',
  'ES': 'Evaluación',
  'TH': 'การประเมิน',
};

String _recordTypeLabel(String koType) =>
    _t(koType == '평가' ? kRecordTypeEvalMap : kRecordTypeLectureMap);

const Map<String, String> kTodayOverallReportTitleMap = {
  'KO': '오늘 종합 리포트 조회',
  'EN': "Today's Overall Report",
  'JA': '本日の総合レポート照会',
  'ZH': '今日综合报告查询',
  'FR': "Rapport global du jour",
  'DE': 'Heutiger Gesamtbericht',
  'RU': 'Общий отчёт за сегодня',
  'AR': 'عرض التقرير الشامل لليوم',
  'HI': 'आज की समग्र रिपोर्ट',
  'VI': 'Xem báo cáo tổng hợp hôm nay',
  'ES': 'Informe general de hoy',
  'TH': 'ดูรายงานสรุปวันนี้',
};
const Map<String, String> kTodayDetailReportTitleMap = {
  'KO': '오늘 상세 분석기록 조회',
  'EN': "Today's Detailed Analysis",
  'JA': '本日の詳細分析記録照会',
  'ZH': '今日详细分析记录查询',
  'FR': "Analyse détaillée du jour",
  'DE': 'Heutige detaillierte Analyse',
  'RU': 'Подробный анализ за сегодня',
  'AR': 'عرض سجل التحليل التفصيلي لليوم',
  'HI': 'आज का विस्तृत विश्लेषण रिकॉर्ड',
  'VI': 'Xem hồ sơ phân tích chi tiết hôm nay',
  'ES': 'Análisis detallado de hoy',
  'TH': 'ดูบันทึกวิเคราะห์เชิงลึกวันนี้',
};
const Map<String, String> kDiagReportTitleMap = {
  'KO': '👑 오늘의 교육성취 정밀 진단서',
  'EN': '👑 Today\'s Precision Achievement Report',
  'JA': '👑 本日の教育成果精密診断書',
  'ZH': '👑 今日教育成果精密诊断报告',
  'FR': "👑 Rapport de diagnostic de réussite du jour",
  'DE': '👑 Heutiger Leistungsdiagnosebericht',
  'RU': '👑 Сегодняшний отчёт по диагностике успеваемости',
  'AR': '👑 تقرير تشخيص التحصيل الدراسي لليوم',
  'HI': '👑 आज की उपलब्धि निदान रिपोर्ट',
  'VI': '👑 Báo cáo chẩn đoán thành tích hôm nay',
  'ES': '👑 Informe de diagnóstico de logros de hoy',
  'TH': '👑 รายงานวินิจฉัยผลสัมฤทธิ์วันนี้',
};
const Map<String, String> kNoExamDataMap = {
  'KO': '아직 기록된 평가 데이터가 없습니다. 평가가 기록되면 정밀 분석 리포트가 제공됩니다.',
  'EN':
      'No evaluation data recorded yet. A detailed analysis report will be provided once evaluations are recorded.',
  'JA': 'まだ記録された評価データがありません。評価が記録されると精密分析レポートが提供されます。',
  'ZH': '尚无已记录的评估数据。评估记录后将提供精密分析报告。',
  'FR':
      "Aucune donnée d'évaluation enregistrée pour le moment. Un rapport d'analyse détaillé sera fourni une fois les évaluations enregistrées.",
  'DE':
      'Es liegen noch keine Bewertungsdaten vor. Sobald Bewertungen erfasst sind, wird ein detaillierter Analysebericht bereitgestellt.',
  'RU':
      'Данные оценивания ещё не записаны. Подробный аналитический отчёт будет предоставлен после записи оценок.',
  'AR':
      'لا توجد بيانات تقييم مسجلة بعد. سيتم تقديم تقرير تحليل دقيق بمجرد تسجيل التقييمات.',
  'HI':
      'अभी तक कोई मूल्यांकन डेटा दर्ज नहीं है। मूल्यांकन दर्ज होते ही विस्तृत विश्लेषण रिपोर्ट प्रदान की जाएगी।',
  'VI':
      'Chưa có dữ liệu đánh giá nào được ghi lại. Báo cáo phân tích chi tiết sẽ được cung cấp khi có đánh giá được ghi nhận.',
  'ES':
      'Aún no se han registrado datos de evaluación. Se proporcionará un informe de análisis detallado una vez registradas las evaluaciones.',
  'TH':
      'ยังไม่มีข้อมูลการประเมินที่บันทึกไว้ รายงานวิเคราะห์เชิงลึกจะถูกจัดเตรียมเมื่อมีการบันทึกผลประเมิน',
};

const Map<String, String> kTabLiveStatusMap = {
  'KO': '실시간 현황',
  'EN': 'Live Status',
  'JA': 'リアルタイム状況',
  'ZH': '实时状况',
  'FR': 'État en direct',
  'DE': 'Live-Status',
  'RU': 'В реальном времени',
  'AR': 'الحالة المباشرة',
  'HI': 'लाइव स्थिति',
  'VI': 'Trạng thái trực tiếp',
  'ES': 'Estado en vivo',
  'TH': 'สถานะเรียลไทม์',
};
const Map<String, String> kTabDetailedMap = {
  'KO': '상세 보기',
  'EN': 'Detailed View',
  'JA': '詳細表示',
  'ZH': '详细查看',
  'FR': 'Vue détaillée',
  'DE': 'Detailansicht',
  'RU': 'Подробный просмотр',
  'AR': 'عرض تفصيلي',
  'HI': 'विस्तृत दृश्य',
  'VI': 'Xem chi tiết',
  'ES': 'Vista detallada',
  'TH': 'ดูรายละเอียด',
};
const Map<String, String> kTabEvaluationMap = {
  'KO': '평가 분석',
  'EN': 'Evaluation Analysis',
  'JA': '評価分析',
  'ZH': '评估分析',
  'FR': 'Analyse des évaluations',
  'DE': 'Bewertungsanalyse',
  'RU': 'Анализ оценок',
  'AR': 'تحليل التقييم',
  'HI': 'मूल्यांकन विश्लेषण',
  'VI': 'Phân tích đánh giá',
  'ES': 'Análisis de evaluación',
  'TH': 'วิเคราะห์การประเมิน',
};
const Map<String, String> kTabGradeMap = {
  'KO': '성적 관리',
  'EN': 'Grade Mgmt',
  'JA': '成績管理',
  'ZH': '成绩管理',
  'FR': 'Gestion des notes',
  'DE': 'Notenverwaltung',
  'RU': 'Управление оценками',
  'AR': 'إدارة الدرجات',
  'HI': 'ग्रेड प्रबंधन',
  'VI': 'Quản lý điểm',
  'ES': 'Gestión de notas',
  'TH': 'จัดการเกรด',
};
const Map<String, String> kTabScholarshipMap = {
  'KO': '장학금',
  'EN': 'Scholarship',
  'JA': '奨学金',
  'ZH': '奖学金',
  'FR': 'Bourse',
  'DE': 'Stipendium',
  'RU': 'Стипендия',
  'AR': 'المنحة',
  'HI': 'छात्रवृत्ति',
  'VI': 'Học bổng',
  'ES': 'Beca',
  'TH': 'ทุนการศึกษา',
};
const Map<String, String> kScholarshipTitleMap = {
  'KO': '이번 달 장학금',
  'EN': "This Month's Scholarship",
  'JA': '今月の奨学金',
  'ZH': '本月奖学金',
  'FR': 'Bourse de ce mois-ci',
  'DE': 'Stipendium diesen Monat',
  'RU': 'Стипендия за этот месяц',
  'AR': 'منحة هذا الشهر',
  'HI': 'इस महीने की छात्रवृत्ति',
  'VI': 'Học bổng tháng này',
  'ES': 'Beca de este mes',
  'TH': 'ทุนการศึกษาเดือนนี้',
};
const Map<String, String> kScholarshipPickTypeMap = {
  'KO': '이번 달 지급 유형을 선택해 주세요',
  'EN': 'Please choose this month\'s type',
  'JA': '今月の支給タイプを選んでください',
  'ZH': '请选择本月发放类型',
  'FR': 'Choisissez le type pour ce mois',
  'DE': 'Wählen Sie den Typ für diesen Monat',
  'RU': 'Выберите тип за этот месяц',
  'AR': 'يرجى اختيار نوع هذا الشهر',
  'HI': 'इस महीने का प्रकार चुनें',
  'VI': 'Vui lòng chọn loại tháng này',
  'ES': 'Elige el tipo de este mes',
  'TH': 'กรุณาเลือกประเภทของเดือนนี้',
};
const Map<String, String> kScholarshipMonthlyStarsMap = {
  'KO': '이번 달 누적 별',
  'EN': 'Stars This Month',
  'JA': '今月の累積スター',
  'ZH': '本月累计星星',
  'FR': 'Étoiles ce mois-ci',
  'DE': 'Sterne diesen Monat',
  'RU': 'Звёзды за месяц',
  'AR': 'نجوم هذا الشهر',
  'HI': 'इस महीने के सितारे',
  'VI': 'Sao tháng này',
  'ES': 'Estrellas este mes',
  'TH': 'ดาวสะสมเดือนนี้',
};
const Map<String, String> kScholarshipAmountMap = {
  'KO': '예상 장학금',
  'EN': 'Estimated Amount',
  'JA': '予想奨学金',
  'ZH': '预计奖学金',
  'FR': 'Montant estimé',
  'DE': 'Geschätzter Betrag',
  'RU': 'Расчётная сумма',
  'AR': 'المبلغ المتوقع',
  'HI': 'अनुमानित राशि',
  'VI': 'Số tiền dự kiến',
  'ES': 'Monto estimado',
  'TH': 'จำนวนเงินโดยประมาณ',
};
const Map<String, String> kScholarshipNoChildMap = {'KO': '장학금 계산은 연결된 자녀를 선택하신 뒤에 확인하실 수 있습니다.\n상단에서 자녀를 추가/선택해 주세요.', 'EN': 'Select a linked child above to view scholarship calculations.', 'JA': '奨学金の計算は、上部で連携済みのお子様を選択すると確認できます。', 'ZH': '选择上方已连接的孩子后即可查看奖学金计算。', 'FR': 'Sélectionnez un enfant connecté ci-dessus pour voir le calcul de la bourse.', 'DE': 'Wählen Sie oben ein verknüpftes Kind aus, um die Stipendienberechnung zu sehen.', 'RU': 'Выберите подключённого ребёнка выше, чтобы увидеть расчёт стипендии.', 'AR': 'اختر طفلاً متصلاً أعلاه لعرض حساب المنحة.', 'HI': 'छात्रवृत्ति देखने के लिए ऊपर जुड़े बच्चे को चुनें।', 'VI': 'Chọn một con đã liên kết ở trên để xem tính toán học bổng.', 'ES': 'Selecciona un hijo/a vinculado arriba para ver el cálculo de la beca.', 'TH': 'เลือกบุตรหลานที่เชื่อมต่อด้านบนเพื่อดูการคำนวณทุนการศึกษา'};

// 🆕 [장학금 방 다국어 2026-09-18] 부모 화면 나머지 문구
const Map<String, String> kScholarshipTapToSelectMap = {'KO': '탭하여 이번 달 지급 유형으로 선택하세요', 'EN': 'Tap to select this month\'s payout type', 'JA': 'タップして今月の支給タイプを選択', 'ZH': '点击选择本月发放类型', 'FR': 'Appuyez pour choisir le type de ce mois', 'DE': 'Tippen, um den Typ für diesen Monat zu wählen', 'RU': 'Нажмите, чтобы выбрать тип за этот месяц', 'AR': 'اضغط لاختيار نوع هذا الشهر', 'HI': 'इस महीने का प्रकार चुनने के लिए टैप करें', 'VI': 'Chạm để chọn loại tháng này', 'ES': 'Toca para elegir el tipo de este mes', 'TH': 'แตะเพื่อเลือกประเภทของเดือนนี้'};
const Map<String, String> kScholarshipBonusDetailTitleMap = {'KO': '이번 달 보너스별 상세 내역', 'EN': 'This Month\'s Bonus Star Details', 'JA': '今月のボーナススター詳細', 'ZH': '本月奖励星详情', 'FR': 'Détails des étoiles bonus de ce mois', 'DE': 'Bonusstern-Details diesen Monat', 'RU': 'Подробности бонусных звёзд за месяц', 'AR': 'تفاصيل النجوم الإضافية لهذا الشهر', 'HI': 'इस महीने के बोनस सितारे विवरण', 'VI': 'Chi tiết sao thưởng tháng này', 'ES': 'Detalles de estrellas bonus de este mes', 'TH': 'รายละเอียดดาวโบนัสเดือนนี้'};
const Map<String, String> kScholarshipMonthlyCapPrefixMap = {'KO': '월 최대', 'EN': 'Monthly max', 'JA': '月最大', 'ZH': '每月最高', 'FR': 'Max mensuel', 'DE': 'Monatl. Max.', 'RU': 'Макс. в месяц', 'AR': 'الحد الأقصى الشهري', 'HI': 'मासिक अधिकतम', 'VI': 'Tối đa tháng', 'ES': 'Máx. mensual', 'TH': 'สูงสุดต่อเดือน'};
const Map<String, String> kScholarshipStarsTimesRateMap = {'KO': '별 %s개 × %s원', 'EN': '%s stars × %s won', 'JA': '星%s個 × %s ウォン', 'ZH': '星星%s颗 × %s韩元', 'FR': '%s étoiles × %s won', 'DE': '%s Sterne × %s Won', 'RU': '%s звёзд × %s вон', 'AR': '%s نجوم × %s وون', 'HI': '%s सितारे × %s वॉन', 'VI': '%s sao × %s won', 'ES': '%s estrellas × %s won', 'TH': '%s ดาว × %s วอน'};
const Map<String, String> kScholarshipCapAppliedMap = {'KO': '= %s원 → 월 한도 적용', 'EN': '= %s won → monthly cap applied', 'JA': '= %s ウォン → 月上限適用', 'ZH': '= %s韩元 → 已适用月度上限', 'FR': '= %s won → plafond mensuel appliqué', 'DE': '= %s Won → Monatslimit angewendet', 'RU': '= %s вон → применён месячный лимит', 'AR': '= %s وون → تم تطبيق الحد الشهري', 'HI': '= %s वॉन → मासिक सीमा लागू', 'VI': '= %s won → đã áp dụng giới hạn tháng', 'ES': '= %s won → tope mensual aplicado', 'TH': '= %s วอน → ใช้เพดานรายเดือนแล้ว'};
const Map<String, String> kScholarshipFooterNoteMap = {'KO': '장학금 지급은 의무가 아니며, 가정의 상황에 따라 자유롭게 운영하실 수 있습니다.', 'EN': 'Paying the scholarship is not mandatory — each family can run it freely based on their own circumstances.', 'JA': '奨学金の支給は義務ではなく、各家庭の状況に応じて自由に運用できます。', 'ZH': '奖学金发放并非义务，可根据各家庭情况自由运营。', 'FR': 'Le versement de la bourse n\'est pas obligatoire ; chaque famille peut l\'organiser librement selon sa situation.', 'DE': 'Die Zahlung des Stipendiums ist nicht verpflichtend — jede Familie kann sie frei nach ihrer Situation gestalten.', 'RU': 'Выплата стипендии необязательна — каждая семья может управлять ею свободно по своим обстоятельствам.', 'AR': 'دفع المنحة ليس إلزاميًا، ويمكن لكل أسرة إدارتها بحرية وفقًا لظروفها.', 'HI': 'छात्रवृत्ति देना अनिवार्य नहीं है, प्रत्येक परिवार अपनी स्थिति के अनुसार स्वतंत्र रूप से इसे चला सकता है।', 'VI': 'Việc trả học bổng không bắt buộc, mỗi gia đình có thể tự do vận hành tùy theo hoàn cảnh.', 'ES': 'Pagar la beca no es obligatorio; cada familia puede gestionarla libremente según su situación.', 'TH': 'การจ่ายทุนการศึกษาไม่ใช่ข้อบังคับ แต่ละครอบครัวสามารถดำเนินการได้อย่างอิสระตามสถานการณ์ของตน'};
const Map<String, String> kScholarshipParentNoticeDialogTitleMap = {'KO': '💛 학부모 장학금 안내', 'EN': '💛 Parent Scholarship Guide', 'JA': '💛 保護者向け奨学金案内', 'ZH': '💛 家长奖学金指南', 'FR': '💛 Guide de la bourse pour les parents', 'DE': '💛 Elternleitfaden zum Stipendium', 'RU': '💛 Руководство по стипендии для родителей', 'AR': '💛 دليل المنحة لأولياء الأمور', 'HI': '💛 अभिभावक छात्रवृत्ति गाइड', 'VI': '💛 Hướng dẫn học bổng cho phụ huynh', 'ES': '💛 Guía de becas para padres', 'TH': '💛 คู่มือทุนการศึกษาสำหรับผู้ปกครอง'};
const Map<String, String> kScholarshipInfoBtnMap = {'KO': '장학금 안내', 'EN': 'Scholarship Info', 'JA': '奨学金案内', 'ZH': '奖学金说明', 'FR': 'Infos bourse', 'DE': 'Stipendium-Info', 'RU': 'О стипендии', 'AR': 'معلومات المنحة', 'HI': 'छात्रवृत्ति जानकारी', 'VI': 'Thông tin học bổng', 'ES': 'Info de beca', 'TH': 'ข้อมูลทุนการศึกษา'};

// 🆕 보너스 항목 라벨 (다국어) — member_achievement_screen.dart와 동일한 번역
const Map<String, Map<String, String>> kScholarshipBonusTypeLabelByLang = {
  'timer70': {'KO': '타이머 70% 이상 완주', 'EN': 'Timer 70%+ Complete', 'JA': 'タイマー70%以上完走', 'ZH': '计时器完成70%以上', 'FR': 'Minuteur 70%+ terminé', 'DE': 'Timer 70%+ abgeschlossen', 'RU': 'Таймер завершён на 70%+', 'AR': 'إكمال المؤقت 70%+', 'HI': 'टाइमर 70%+ पूर्ण', 'VI': 'Hoàn thành hẹn giờ 70%+', 'ES': 'Temporizador 70%+ completo', 'TH': 'จับเวลาครบ 70%+'},
  'recordwrite': {'KO': '학습기록 작성', 'EN': 'Study Record Written', 'JA': '学習記録作成', 'ZH': '撰写学习记录', 'FR': "Fiche d'étude rédigée", 'DE': 'Lernprotokoll erstellt', 'RU': 'Запись обучения создана', 'AR': 'كتابة سجل الدراسة', 'HI': 'अध्ययन रिकॉर्ड लिखा गया', 'VI': 'Đã ghi chép học tập', 'ES': 'Registro de estudio escrito', 'TH': 'บันทึกการเรียนแล้ว'},
  'weekly': {'KO': '주간평가 기록', 'EN': 'Weekly Assessment Logged', 'JA': '週間評価記録', 'ZH': '周评估记录', 'FR': 'Éval. hebdo enregistrée', 'DE': 'Wochentest erfasst', 'RU': 'Недельная оценка записана', 'AR': 'تسجيل التقييم الأسبوعي', 'HI': 'साप्ताहिक मूल्यांकन दर्ज', 'VI': 'Đã ghi đánh giá tuần', 'ES': 'Evaluación semanal registrada', 'TH': 'บันทึกประเมินรายสัปดาห์'},
  'unittest': {'KO': '단원평가 기록', 'EN': 'Unit Test Logged', 'JA': '単元テスト記録', 'ZH': '单元测验记录', 'FR': "Contrôle d'unité enregistré", 'DE': 'Einheitstest erfasst', 'RU': 'Тест по разделу записан', 'AR': 'تسجيل اختبار الوحدة', 'HI': 'इकाई परीक्षण दर्ज', 'VI': 'Đã ghi kiểm tra bài', 'ES': 'Examen de unidad registrado', 'TH': 'บันทึกทดสอบบทแล้ว'},
  'midterm': {'KO': '중간고사 기록', 'EN': 'Midterm Logged', 'JA': '中間試験記録', 'ZH': '期中考试记录', 'FR': 'Examen partiel enregistré', 'DE': 'Zwischenprüfung erfasst', 'RU': 'Промежуточный экзамен записан', 'AR': 'تسجيل اختبار منتصف الفصل', 'HI': 'मध्यावधि परीक्षा दर्ज', 'VI': 'Đã ghi thi giữa kỳ', 'ES': 'Examen parcial registrado', 'TH': 'บันทึกสอบกลางภาคแล้ว'},
  'final': {'KO': '기말고사 기록', 'EN': 'Final Exam Logged', 'JA': '期末試験記録', 'ZH': '期末考试记录', 'FR': 'Examen final enregistré', 'DE': 'Abschlussprüfung erfasst', 'RU': 'Итоговый экзамен записан', 'AR': 'تسجيل الاختبار النهائي', 'HI': 'अंतिम परीक्षा दर्ज', 'VI': 'Đã ghi thi cuối kỳ', 'ES': 'Examen final registrado', 'TH': 'บันทึกสอบปลายภาคแล้ว'},
  'mock': {'KO': '모의고사 기록', 'EN': 'Mock Exam Logged', 'JA': '模試記録', 'ZH': '模拟考试记录', 'FR': 'Examen blanc enregistré', 'DE': 'Probeprüfung erfasst', 'RU': 'Пробный экзамен записан', 'AR': 'تسجيل الاختبار التجريبي', 'HI': 'मॉक परीक्षा दर्ज', 'VI': 'Đã ghi thi thử', 'ES': 'Examen simulacro registrado', 'TH': 'บันทึกสอบจำลองแล้ว'},
  'dailyattend': {'KO': '일일 출석 보너스', 'EN': 'Daily Attendance Bonus', 'JA': '日次出席ボーナス', 'ZH': '每日出勤奖励', 'FR': 'Bonus de présence quotidien', 'DE': 'Täglicher Anwesenheitsbonus', 'RU': 'Ежедневный бонус посещаемости', 'AR': 'مكافأة الحضور اليومي', 'HI': 'दैनिक उपस्थिति बोनस', 'VI': 'Thưởng chuyên cần ngày', 'ES': 'Bono de asistencia diaria', 'TH': 'โบนัสการเข้าเรียนรายวัน'},
  'weeklyattend': {'KO': '주간 개근 보너스', 'EN': 'Weekly Perfect Attendance', 'JA': '週間皆勤ボーナス', 'ZH': '每周全勤奖励', 'FR': 'Bonus de présence parfaite hebdo', 'DE': 'Wöchentlicher Vollanwesenheitsbonus', 'RU': 'Недельный бонус за посещаемость', 'AR': 'مكافأة الحضور الأسبوعي الكامل', 'HI': 'साप्ताहिक पूर्ण उपस्थिति बोनस', 'VI': 'Thưởng chuyên cần tuần', 'ES': 'Bono de asistencia perfecta semanal', 'TH': 'โบนัสขยันเรียนรายสัปดาห์'},
  'monthlyattend': {'KO': '월간 개근 보너스', 'EN': 'Monthly Perfect Attendance', 'JA': '月間皆勤ボーナス', 'ZH': '每月全勤奖励', 'FR': 'Bonus de présence parfaite mensuel', 'DE': 'Monatlicher Vollanwesenheitsbonus', 'RU': 'Месячный бонус за посещаемость', 'AR': 'مكافأة الحضور الشهري الكامل', 'HI': 'मासिक पूर्ण उपस्थिति बोनस', 'VI': 'Thưởng chuyên cần tháng', 'ES': 'Bono de asistencia perfecta mensual', 'TH': 'โบนัสขยันเรียนรายเดือน'},
};
String kBonusLabelForType(String key) {
  final m = kScholarshipBonusTypeLabelByLang[key];
  if (m == null) return key;
  return m[DkeLang.current] ?? m['EN'] ?? m['KO'] ?? key;
}

// 🆕 [장학금 방 상세화 2026-09-17] 보너스별 항목 코드 → 한글 라벨 (부모방 상세 계산 표시용)
const Map<String, String> kScholarshipBonusTypeLabelMap = {
  'timer70': '타이머 70% 이상 완주',
  'recordwrite': '학습기록 작성',
  'weekly': '주간평가 기록',
  'unittest': '단원평가 기록',
  'midterm': '중간고사 기록',
  'final': '기말고사 기록',
  'mock': '모의고사 기록',
  'dailyattend': '일일 출석 보너스',
  'weeklyattend': '주간 개근 보너스',
  'monthlyattend': '월간 개근 보너스',
};
const Map<String, int> kBonusTypeStarAmountMap = {
  'timer70': ScholarshipService.bonusTimer70Completion,
  'recordwrite': ScholarshipService.bonusRecordWrite,
  'weekly': ScholarshipService.bonusWeeklyAssessment,
  'unittest': ScholarshipService.bonusUnitTest,
  'midterm': ScholarshipService.bonusMidterm,
  'final': ScholarshipService.bonusFinalExam,
  'mock': ScholarshipService.bonusMockExam,
  'dailyattend': ScholarshipService.bonusDailyAttendance,
  'weeklyattend': ScholarshipService.bonusWeeklyAttendance,
  'monthlyattend': ScholarshipService.bonusMonthlyAttendance,
};
const Map<String, Color> kBonusTypeColorMap = {
  'timer70': Color(0xFFFF9500),
  'recordwrite': Color(0xFF34C759),
  'weekly': Color(0xFF60A5FA),
  'unittest': Color(0xFFAF52DE),
  'midterm': Color(0xFFFF3B30),
  'final': Color(0xFFFFCC00),
  'mock': Color(0xFF5856D6),
  'dailyattend': Color(0xFF00C7BE),
  'weeklyattend': Color(0xFFFF2D55),
  'monthlyattend': Color(0xFFFFD700),
};

// 🆕 [장학금 방 2026-09-17 최종] 학부모용 안내문 원문 (출석 보너스 3종 반영 최종본)
// 🆕 [다국어 2026-09-18] 언어별 학부모 안내문 맵. 'KO'/'EN'은 확정 완료.
// 나머지 10개(JA/ZH/FR/DE/RU/AR/HI/VI/ES/TH)는 원장님이 번역해서
// 큰따옴표 3개(''') 사이에 그대로 채워 넣으시면 됩니다.
const Map<String, String> kScholarshipParentNoticeByLang = {
  'KO': '''
GKE StudyUp 학부모 장학금 안내

우리 아이의 공부를 '보상'하는 것이 아니라, 스스로 성장하는 과정을 응원합니다.

GKE StudyUp의 장학금 제도는 단순히 공부한 시간에 돈을 지급하기 위한 제도가 아닙니다.

아이 스스로 학습계획을 세우고, 정해진 학습을 실천하고, 학습기록과 평가를 남기면서 자신의 공부를 관리하는 습관을 만들어 가는 과정을 부모님께서 인정하고 응원하는 제도입니다.

아이에게는 "공부하면 돈을 받는다"는 의미보다,

"내가 스스로 계획하고 노력한 것을 부모님이 알아주고 응원해 주신다."

라는 긍정적인 경험을 만들어 주는 것을 목표로 합니다.


⭐ 별은 아이의 학습 성취 기록입니다.

GKE StudyUp에서는 학습 활동에 따라 별이 적립됩니다.

별은 단순한 게임 점수가 아니라 아이가 실제로 학습을 실천하고 자신의 학습을 관리한 기록입니다.

별 적립 기준
- 타이머 학습이 70% 이상 진행되면 +10별
- 타이머 학습 종료 후 학습기록 작성 시 +10별
- 주간평가 기록 시 +10별
- 단원평가 기록 시 +10별
- 중간고사 기록 시 +50별
- 기말고사 기록 시 +50별
- 모의고사 기록 시 +50별
- 하루 50분 이상 타이머가 작동하여 학습하면 +50별 (일일 출석 보너스)
- 일주일(일요일~토요일) 동안 빠짐없이 매일 타이머가 작동하여 학습하면 +300별 (주간 개근 보너스)
- 한 달 동안 빠짐없이 매일 타이머가 작동하여 학습하면 +1,000별 (월간 개근 보너스)

특히 시험 관련 별은 높은 점수를 받았을 때 주어지는 것이 아니라, 시험 결과를 기록하고 자신의 학습을 돌아보는 행동에 대해 적립됩니다. 출석 보너스 역시 성적이 아니라 "꾸준함" 그 자체를 인정하기 위한 것입니다.

※ 출석 인정 기준은 앱을 열어본 것이 아니라, 반드시 타이머가 실제로 작동하여 학습한 시간만을 기준으로 합니다.

🌱 성장형 → 🔥 도전형 → 🏆 성취형

아이의 학습 실천과 성취 수준에 따라 장학금 유형이 성장해 갑니다.

🌱 성장형
꾸준히 학습을 시작하고 학습습관을 만들어 가는 단계

🔥 도전형
학습량과 학습 실천을 한 단계 높이고 목표에 도전하는 단계

🏆 성취형
꾸준한 학습과 자기관리, 평가와 기록을 통해 높은 수준의 학습 성취를 만들어 가는 단계

유형은 단순히 부모님이나 학생이 더 많은 장학금을 받기 위해 선택하는 것이 아니라, 아이의 실제 학습 실천과 성취 과정에 따라 결정되는 것을 원칙으로 합니다. 매달 아이의 학습 기록과 별 적립 현황을 살펴보시고, 그 모습에 맞는 유형을 부모님께서 직접 선택해 주시면 됩니다.

💰 장학금은 어떻게 계산되나요?

📌 장학금 계산 예시

예를 들어 A학생이 하루 2교시(100분)씩 학습하고, 타이머 70% 완주와 학습기록 작성을 매번 빠짐없이 실천하며, 그 달 하루도 빠짐없이 학습했다면

일일 학습 보너스
기본별 100개(100분) + 타이머70%완주 2회(+20별) + 학습기록작성 2회(+20별) + 일일 출석 보너스(+50별) = 하루 190별

주간 학습 보너스
하루 190별 × 7일 + 주간평가 기록 1회(+10별) + 주간 개근 보너스(+300별) = 1주일 1,640별

월간 학습 성취 보너스
하루 190별 × 30일 + 주간평가 4회(+40별) + 단원평가 1회(+10별) + 중간고사 1회(+50별) + 기말고사 1회(+50별) + 모의고사 1회(+50별) + 월간 개근 보너스(+1,000별) = 한 달 6,900별

여기에 성장형은 1별 2원, 도전형은 1별 3원, 성취형은 1별 4원이 적용되어

🌱 성장형: 6,900 × 2원 = 13,800원 → 월 한도 20,000원 이내
🔥 도전형: 6,900 × 3원 = 20,700원 → 월 한도 30,000원 이내
🏆 성취형: 6,900 × 4원 = 27,600원 → 월 한도 50,000원 이내

이 됩니다.

따라서 해당 월의 장학금은 부모님께서 선택하신 유형에 따라 위 금액 중 하나로 자동 계산되어 지급됩니다.

※ 실제 지급액은 학생의 실제 별 개수와 달성한 학습 보너스에 따라 자동 계산되며 달라집니다. 아이가 학습을 마칠 때마다 이번 달 누적 별과 예상 장학금이 이 화면에 실시간으로 반영되며, 위 예시는 이해를 돕기 위한 참고용 숫자입니다.

💛 부모님의 응원이 아이에게 큰 힘이 됩니다
아이에게 공부는 때로 쉽지 않은 도전입니다.

하지만 부모님께서

"얼마나 공부했니?"

라고 묻는 것에서 한 걸음 더 나아가,

"네가 스스로 계획하고 꾸준히 노력한 것을 엄마·아빠가 알고 있어."

라고 말해 주신다면
아이에게는 그 자체가 큰 격려가 될 수 있습니다.

장학금은 공부의 대가가 아니라
자녀의 노력과 성취를 부모님께서 인정하고 격려해 주는 하나의 방법입니다.

따라서 장학금 지급 여부와 지급 금액은
각 가정의 상황과 교육방침에 따라 부모님께서 자유롭게 결정하실 수 있습니다.

GKE StudyUp은 부모님께 지급을 요구하거나 강제하지 않습니다.

다만 자녀가 자신의 노력에 대해
부모님의 따뜻한 인정을 경험할 수 있도록
장학금 제도를 마련했습니다.



❤️ 부모님께서 꼭 알아주세요.

GKE StudyUp은 부모님께 장학금 지급을 의무화하지 않습니다.

장학금은 각 가정의 상황과 부모님의 교육방침에 따라 자유롭게 운영하실 수 있습니다.

중요한 것은 장학금의 금액 자체가 아니라,

"우리 아이가 스스로 계획하고 실천하고 성장하고 있다는 것을 부모가 인정해 주는 것"

입니다.

아이에게 이렇게 이야기해 주세요.

"공부한 시간만 보는 것이 아니라, 네가 스스로 계획하고 노력하고 기록하면서 성장하는 모습을 엄마·아빠가 보고 있어. 그래서 네 노력을 응원하고 싶어."

작은 실천이 습관이 되고,
습관이 실력이 되고,
실력이 성취가 됩니다.

계획하고 → 실천하고 → 기록하고 → 돌아보고 → 다시 도전하는 
GKE StudyUp은 우리 아이가 스스로 공부할 수 있는 힘을 키워가는 과정을 응원합니다.

GKE StudyUp
Global Knowledge Education
''',
  'EN': '''
GKE StudyUp Parent Scholarship Guide

We're not "rewarding" your child's studying — we're cheering on their journey of self-driven growth.

GKE StudyUp's scholarship program isn't simply about paying for hours studied.

It's a way for parents to recognize and encourage the process by which children set their own study plans, follow through, and build the habit of managing their own learning by leaving records and evaluations behind.

For your child, the goal isn't "I get paid for studying" — it's the positive experience of "My parents notice and cheer on the effort I put in on my own."


⭐ Stars are a record of your child's learning achievements.

GKE StudyUp awards stars based on study activity.

Stars aren't just a game score — they're a record that your child actually studied and managed their own learning.

How stars are earned
- Completing 70%+ of a timer session → +10 stars
- Writing a study record after finishing a timer session → +10 stars
- Logging a weekly assessment → +10 stars
- Logging a unit test → +10 stars
- Logging a midterm exam → +50 stars
- Logging a final exam → +50 stars
- Logging a mock exam → +50 stars
- Studying 50+ minutes in a day with the timer running → +50 stars (Daily Attendance Bonus)
- Studying every day for a full week (Sunday–Saturday) with the timer running → +300 stars (Weekly Perfect Attendance Bonus)
- Studying every day for a full month with the timer running → +1,000 stars (Monthly Perfect Attendance Bonus)

Exam-related stars aren't awarded for high scores — they're awarded for the act of recording results and reflecting on their own learning. The attendance bonuses, too, recognize "consistency" itself rather than performance.

※ Attendance is counted only when the timer actually ran — simply opening the app does not count.

🌱 Growth Type → 🔥 Challenge Type → 🏆 Achievement Type

The scholarship type grows along with your child's learning practice and level of achievement.

🌱 Growth Type
The stage of starting to study consistently and building a study habit

🔥 Challenge Type
The stage of raising the amount and consistency of study, taking on higher goals

🏆 Achievement Type
The stage of sustained study and self-management, reaching a high level of achievement through evaluation and record-keeping

The type isn't something chosen simply to receive a larger scholarship — as a principle, it should reflect your child's actual study practice and achievement. Please review your child's study records and star totals each month, and choose the type that matches what you see.

💰 How is the scholarship calculated?

📌 Calculation Example

Say Student A studies two periods a day (100 minutes), always completes 70%+ of the timer and writes a study record, and studies every single day of the month without missing one:

Daily Bonus
Base stars 100 (100 min) + Timer 70%+ completion ×2 (+20) + Study record written ×2 (+20) + Daily attendance bonus (+50) = 190 stars/day

Weekly Bonus
190 stars × 7 days + Weekly assessment logged once (+10) + Weekly perfect attendance bonus (+300) = 1,640 stars/week

Monthly Bonus
190 stars × 30 days + Weekly assessment ×4 (+40) + Unit test ×1 (+10) + Midterm ×1 (+50) + Final ×1 (+50) + Mock exam ×1 (+50) + Monthly perfect attendance bonus (+1,000) = 6,900 stars/month

Applying 2 won/star for Growth, 3 won/star for Challenge, and 4 won/star for Achievement:

🌱 Growth: 6,900 × 2 won = 13,800 won → within the 20,000 won monthly cap
🔥 Challenge: 6,900 × 3 won = 20,700 won → within the 30,000 won monthly cap
🏆 Achievement: 6,900 × 4 won = 27,600 won → within the 50,000 won monthly cap

So that month's scholarship is calculated automatically as one of the amounts above, based on whichever type you select.

※ The actual amount is calculated automatically based on your child's real star count and bonuses earned, and will differ from this example. Every time your child finishes studying, this month's accumulated stars and estimated scholarship update in real time on this screen — the example above is only for illustration.

💛 Your encouragement means a great deal to your child
Studying isn't always easy for a child.

But when a parent goes beyond simply asking

"How much did you study?"

and instead says,

"I can see you've been planning and working hard on your own — Mom and Dad notice."

that alone can be a huge source of encouragement.

A scholarship isn't payment for studying — it's one way for parents to recognize and encourage their child's effort and achievement.

So whether to give a scholarship, and how much, is entirely up to each family's circumstances and parenting approach.

GKE StudyUp never requires or pressures parents to pay.

We simply created this scholarship program so that children can experience their parents' warm recognition of their own effort.



❤️ A few things parents should know

GKE StudyUp does not require parents to pay a scholarship.

Scholarships can be managed freely according to each family's circumstances and educational approach.

What matters isn't the amount itself —

it's recognizing that "my child is planning, acting, and growing on their own."

Try telling your child this:

"I'm not just looking at how long you studied — I can see you planning, working hard, and keeping records as you grow. That's why I want to cheer you on."

Small actions become habits. Habits become skill. Skill becomes achievement.

Plan → Act → Record → Reflect → Try again —
GKE StudyUp is here to support your child's journey toward building the power to study on their own.

GKE StudyUp
Global Knowledge Education
''',
  // 🔽 원장님이 채워주실 자리 (10개국어) — 큰따옴표 3개 사이에 번역문을 그대로 붙여넣으시면 됩니다
  'JA': '', // 일본어
  'ZH': '', // 중국어
  'FR': '', // 프랑스어
  'DE': '', // 독일어
  'RU': '', // 러시아어
  'AR': '', // 아랍어
  'HI': '', // 힌디어
  'VI': '', // 베트남어
  'ES': '', // 스페인어
  'TH': '', // 태국어
};

// 🆕 현재 선택된 언어에 맞는 학부모 안내문 반환. 언어가 아직 비어있으면(원장님이
// 아직 안 채우신 언어) 영어로, 영어도 없으면 한국어로 자동 대체됨.
String getScholarshipParentNoticeText(String languageCode) {
  final String code = languageCode.toUpperCase();
  final String? text = kScholarshipParentNoticeByLang[code];
  if (text != null && text.trim().isNotEmpty) return text;
  return kScholarshipParentNoticeByLang['EN']!.trim().isNotEmpty
      ? kScholarshipParentNoticeByLang['EN']!
      : kScholarshipParentNoticeByLang['KO']!;
}

// 🆕 [2026-09-23] 상단 버튼 + 장학금 탭 단위 다국어 사전
const Map<String, String> kLogoutLabelMap = {'KO': '로그아웃', 'EN': 'Log out', 'JA': 'ログアウト', 'ZH': '退出登录', 'FR': 'Déconnexion', 'DE': 'Abmelden', 'RU': 'Выйти', 'AR': 'تسجيل الخروج', 'HI': 'लॉग आउट', 'VI': 'Đăng xuất', 'ES': 'Cerrar sesión', 'TH': 'ออกจากระบบ'};
const Map<String, String> kNoticeCounselMap = {'KO': '공지 및 교육상담', 'EN': 'Notice & Counseling', 'JA': 'お知らせ・教育相談', 'ZH': '公告与教育咨询', 'FR': 'Avis & Conseil', 'DE': 'Hinweise & Beratung', 'RU': 'Объявления и консультации', 'AR': 'الإعلانات والاستشارات', 'HI': 'सूचना और परामर्श', 'VI': 'Thông báo & Tư vấn', 'ES': 'Avisos y Asesoría', 'TH': 'ประกาศและให้คำปรึกษา'};
const Map<String, String> kComingSoonMap = {'KO': '공지 및 교육상담은 곧 열립니다. 조금만 기다려 주세요!', 'EN': 'Notice & Counseling is coming soon. Please stay tuned!', 'JA': 'お知らせ・教育相談は近日公開予定です。もう少しお待ちください！', 'ZH': '公告与教育咨询即将开放，敬请期待！', 'FR': 'Avis & Conseil arrive bientôt. Merci de patienter !', 'DE': 'Hinweise & Beratung kommen bald. Bitte noch etwas Geduld!', 'RU': 'Раздел объявлений и консультаций скоро откроется. Пожалуйста, подождите!', 'AR': 'قسم الإعلانات والاستشارات قادم قريبًا. يرجى الانتظار!', 'HI': 'सूचना और परामर्श जल्द आ रहा है। कृपया थोड़ा इंतज़ार करें!', 'VI': 'Thông báo & Tư vấn sắp ra mắt. Vui lòng chờ thêm chút nhé!', 'ES': 'Avisos y Asesoría llegará pronto. ¡Gracias por esperar!', 'TH': 'ประกาศและให้คำปรึกษาจะเปิดเร็ว ๆ นี้ กรุณารอสักครู่!'};
const Map<String, String> kStarCountUnitMap = {'KO': '개', 'EN': 'stars', 'JA': '個', 'ZH': '颗', 'FR': 'étoiles', 'DE': 'Sterne', 'RU': 'звёзд', 'AR': 'نجمة', 'HI': 'सितारे', 'VI': 'sao', 'ES': 'estrellas', 'TH': 'ดวง'};
const Map<String, String> kWonUnitMap = {'KO': '원', 'EN': 'won', 'JA': 'ウォン', 'ZH': '韩元', 'FR': 'won', 'DE': 'Won', 'RU': 'вон', 'AR': 'وون', 'HI': 'वॉन', 'VI': 'won', 'ES': 'won', 'TH': 'วอน'};
const Map<String, String> kBaseWordMap = {'KO': '기본', 'EN': 'Base', 'JA': '基本', 'ZH': '基本', 'FR': 'Base', 'DE': 'Basis', 'RU': 'Базовые', 'AR': 'أساسي', 'HI': 'मूल', 'VI': 'Cơ bản', 'ES': 'Base', 'TH': 'พื้นฐาน'};
const Map<String, String> kBonusWordMap = {'KO': '보너스', 'EN': 'Bonus', 'JA': 'ボーナス', 'ZH': '奖励', 'FR': 'Bonus', 'DE': 'Bonus', 'RU': 'Бонус', 'AR': 'مكافأة', 'HI': 'बोनस', 'VI': 'Thưởng', 'ES': 'Bono', 'TH': 'โบนัส'};

const Map<String, String> kAvgWordMap = {
  'KO': '평균',
  'EN': 'Avg',
  'JA': '平均',
  'ZH': '平均',
  'FR': 'Moy.',
  'DE': 'Ø',
  'RU': 'Средн.',
  'AR': 'المعدل',
  'HI': 'औसत',
  'VI': 'TB',
  'ES': 'Prom.',
  'TH': 'เฉลี่ย',
};

class ParentMainDashboardScreen extends StatefulWidget {
  final String parentEmail;
  final String childName;

  const ParentMainDashboardScreen({
    Key? key,
    required this.parentEmail,
    this.childName = "학습자",
  }) : super(key: key);

  @override
  _ParentMainDashboardScreenState createState() =>
      _ParentMainDashboardScreenState();
}

class _ParentMainDashboardScreenState extends State<ParentMainDashboardScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  // 🆕 [영문 표기 보강 2026-09-21] ScholarshipType.values 순서(성장형/도전형/성취형)와
  // 1:1로 대응하는 영문 라벨. 실제 enum 멤버 이름을 몰라도 index로 안전하게 매칭.
  static const List<String> _scholarshipTypeEnLabels = ['Growth', 'Challenge', 'Achievement'];
  bool _isVipMember = false;
  bool _isLoading = true;

  static const Color luxuryDarkBg = Color(0xFF030712);
  static const Color premiumCardBg = Color(0xFF0D1527);
  static const Color brandGolden = Color(0xFFE5C158);

  bool _isMonitoringActive = false;
  int _monitoringCountdown = 60;
  int _totalCollectedStars = 0;

  String _lastSentTimeText = "";

  String _selectedEvaluationType = "주평가";

  // 🆕 [다중선택] 대단원/중단원을 String 단일값 대신 Set<String>으로 관리 - 복수 선택 지원
  // (평가결과에서 중간고사/기말고사/모의고사가 삭제되면서 학년/학기 필터(_selectedSemesterFilter)는
  //  더 이상 쓰이지 않아 함께 제거했습니다.)
  Set<String> _selectedBigUnits = {"대단원 1"};
  Set<String> _selectedMidUnits = {"중단원 1"};

  // 🆕 [자녀 추가] 연결된 자녀 코드 목록 (최대 5명, 언제든 추가 가능)
  List<String> _linkedChildCodes = [];
  bool _loadingLinkedChildren = true;
  final TextEditingController _addChildCodeController = TextEditingController();

  // 🆕 [자녀 선택 UI + Firestore 연동] 상단 자녀 칩 중 현재 선택된 자녀 코드.
  // null이면 "연결된 자녀 없음" 상태 - 이때는 기존처럼 이 기기의 로컬 데이터를 그대로 보여줌
  // (기존 단일기기 사용자 하위호환을 위해 유지).
  String? _selectedChildCode;

  // 🆕 [버그 수정] 주평가 전용 년/월/주차 상태 신설 - 기존엔 단원평가용 변수(_selectedBigUnit/
  // _selectedMidUnit)를 그대로 빌려쓰고 있어서 월/주차 선택이 서로 충돌하고 필터링도 안 됐음.
  // 오늘 날짜를 기준으로 자동 초기화(member_achievement_screen.dart의 주차 계산과 동일한 방식).
  static String _computeCurrentWeekOfMonth() {
    final DateTime now = DateTime.now();
    final DateTime firstOfMonth = DateTime(now.year, now.month, 1);
    final int sundayIndex = firstOfMonth.weekday % 7; // 0=일, 1=월, ... 6=토
    final int weekNum = ((now.day - 1 + sundayIndex) ~/ 7) + 1;
    return "$weekNum주차";
  }

  String _selectedYear = "${DateTime.now().year}년";
  String _selectedMonth = "${DateTime.now().month}월";
  String _selectedWeek = _computeCurrentWeekOfMonth();

  late TabController _timeTabController;

  // 🆕 [실데이터 연동] 아래 필드들은 전부 ParentDataService를 통해 채워집니다.
  String _realChildName = "학습자";
  List<ParentSessionRecord> _todaySessions = [];
  List<ParentSessionRecord> _allSessions = [];
  List<ParentExamRecord> _examRecords = [];
  List<Map<String, dynamic>> _subjectAggregates = [];

  int _todayTotalMinutes = 0;
  int _yesterdayTotalMinutes = 0;
  int _weeklyAvgMinutesPerDay = 0;
  String? _strongestSubject;
  String? _weakestSubject;

  // 🆕 [지난 일자 조회] 상세보기 화면에서 좌우 화살표로 이동할 조회 대상 날짜
  DateTime _detailedViewDate = DateTime.now();

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _isViewingToday => _isSameDate(_detailedViewDate, DateTime.now());

  List<ParentSessionRecord> get _sessionsForDetailedDate => _allSessions
      .where((r) => _isSameDate(r.timestamp, _detailedViewDate))
      .toList();

  int get _detailedDayTotalMinutes {
    final d = DateTime(
      _detailedViewDate.year,
      _detailedViewDate.month,
      _detailedViewDate.day,
    );
    return ParentDataService.totalMinutesForDay(_allSessions, d);
  }

  int get _detailedDayBeforeMinutes {
    final d = DateTime(
      _detailedViewDate.year,
      _detailedViewDate.month,
      _detailedViewDate.day,
    ).subtract(const Duration(days: 1));
    return ParentDataService.totalMinutesForDay(_allSessions, d);
  }

  // 🆕 조회 중인 날짜 이전 7일(해당 날짜 제외)의 학습분 평균 - 기존 "오늘 vs 1주 평균" 로직을
  // 선택된 날짜 기준으로 그대로 이동
  int get _detailedWeeklyAvgMinutes {
    final base = DateTime(
      _detailedViewDate.year,
      _detailedViewDate.month,
      _detailedViewDate.day,
    );
    int total = 0;
    for (int i = 1; i <= 7; i++) {
      total += ParentDataService.totalMinutesForDay(
        _allSessions,
        base.subtract(Duration(days: i)),
      );
    }
    return (total / 7).round();
  }

  void _goToPreviousDetailDay() {
    setState(
      () => _detailedViewDate = _detailedViewDate.subtract(
        const Duration(days: 1),
      ),
    );
  }

  void _goToNextDetailDay() {
    if (_isViewingToday) return; // 🆕 미래 날짜 조회 방지
    setState(
      () => _detailedViewDate = _detailedViewDate.add(const Duration(days: 1)),
    );
  }

  @override
  void initState() {
    super.initState();
    _timeTabController = TabController(length: 4, vsync: this);
    _timeTabController.addListener(() {
      if (!_timeTabController.indexIsChanging) setState(() {});
    });
    _loadRealData();
    _loadLinkedChildren(); // 🆕 [자녀 추가] 연결된 자녀 코드 목록 불러오기
  }

  // 🆕 [자녀 추가] 이 계정에 연결된 자녀 코드 목록을 불러옴
  Future<void> _loadLinkedChildren() async {
    final codes = await FamilyLinkService.getLinkedCodes();
    if (!mounted) return;
    setState(() {
      _linkedChildCodes = codes;
      _loadingLinkedChildren = false;
      // 🆕 [자녀 선택 UI] 연결된 자녀가 있고 아직 선택된 자녀가 없으면 첫 번째 자녀를 기본 선택
      if (_selectedChildCode == null && codes.isNotEmpty) {
        _selectedChildCode = codes.first;
      }
    });
  }

  // 🆕 [자녀 추가] 코드 입력 다이얼로그를 띄우고, 연결 성공하면 목록을 새로고침
  Future<void> _showAddChildDialog() async {
    _addChildCodeController.clear();
    String? errorText;
    bool isConnecting = false;
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: premiumCardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              '자녀 추가/Add Child',
              style: GoogleFonts.notoSansKr(
                color: brandGolden,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '자녀에게 받은 6자리 연결 코드를 입력하세요\nEnter the 6-digit code from your child',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addChildCodeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSans(
                    color: Colors.white,
                    fontSize: 22,
                    letterSpacing: 4,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    errorText: errorText,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: brandGolden.withValues(alpha: 0.4),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: brandGolden),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  '취소/Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: brandGolden),
                onPressed: isConnecting ? null : () async {
                  final code = _addChildCodeController.text.trim();
                  if (code.length != 6) {
                    setDialogState(
                          () => errorText = '6자리 숫자를 입력하세요 / Enter 6 digits',
                    );
                    return;
                  }
                  setDialogState(() {
                    errorText = null;
                    isConnecting = true;
                  });
                  debugPrint('[자녀연결시도] code=$code 시작');
                  try {
                    final ConnectResult result = await FamilyLinkService
                        .connectWithCodeResult(code)
                        .timeout(const Duration(seconds: 15));
                    debugPrint('[자녀연결결과] $result');
                    if (result == ConnectResult.success) {
                      if (context.mounted) Navigator.pop(dialogContext);
                      await _loadLinkedChildren();
                    } else {
                      setDialogState(() {
                        isConnecting = false;
                        errorText = switch (result) {
                          ConnectResult.codeNotFound => '존재하지 않는 코드입니다 / Code not found',
                          ConnectResult.capacityFull => '이미 정원이 가득 찼습니다 / Already full',
                          ConnectResult.notLoggedIn => '로그인이 필요합니다 / Please log in',
                          _ => '연결에 실패했습니다 / Connection failed',
                        };
                      });
                    }
                  } catch (e) {
                    debugPrint('[자녀연결오류] $e');
                    setDialogState(() {
                      isConnecting = false;
                      errorText = '오류가 발생했습니다: $e';
                    });
                  }
                },
                child: isConnecting
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF030712)),
                )
                    : const Text(
                  '연결하기/Connect',
                  style: TextStyle(
                    color: Color(0xFF030712),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🆕 [자녀 추가] 대시보드 상단에 표시할 "연결된 자녀 명단 + 추가" 가로 바
  Widget _buildLinkedChildrenBar() {
    if (_loadingLinkedChildren) {
      return const SizedBox(
        height: 92,
        child: Center(
          child: CircularProgressIndicator(color: brandGolden, strokeWidth: 2),
        ),
      );
    }
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        children: [
          ..._linkedChildCodes.map((code) => _buildChildChip(code)),
          if (_linkedChildCodes.length < FamilyLinkService.maxChildren)
            _buildAddChildChip(),
        ],
      ),
    );
  }

  // 🆕 [자녀 선택 UI] 칩을 탭하면 해당 자녀가 선택되어, 실시간현황 탭이 이 자녀의
  // Firestore 데이터를 보여주도록 전환됩니다. 선택된 칩은 골드 테두리로 강조 표시.
  Widget _buildChildChip(String code) {
    final bool isSelected = _selectedChildCode == code;
    return GestureDetector(
      onTap: () => setState(() => _selectedChildCode = code),
      child: StreamBuilder(
        stream: FamilyLinkService.watch(code),
        builder: (context, snapshot) {
          final data = (snapshot.data as dynamic)?.data();
          final totalStars = data?['totalStars'];
          final level = data?['level'];
          final String? studentName = data?['studentName'] as String?;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 130,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? brandGolden.withValues(alpha: 0.15)
                      : premiumCardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: brandGolden.withValues(
                      alpha: isSelected ? 1.0 : 0.4,
                    ),
                    width: isSelected ? 1.6 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      studentName != null && studentName.isNotEmpty
                          ? studentName
                          : '코드 $code',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansKr(
                        color: isSelected ? brandGolden : Colors.white38,
                        fontSize: isSelected ? 11 : 9,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalStars != null ? '⭐ $totalStars개' : '데이터 없음',
                      style: GoogleFonts.notoSansKr(
                        color: brandGolden,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (level != null)
                      Text(
                        '레벨/Lv. $level',
                        style: GoogleFonts.notoSansKr(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              // 🆕 [요청] 정식 부모 화면에는 자녀 연결 해제 버튼이 없었음 - 오른쪽 위에
              // 작은 X 아이콘으로 추가. 실수로 지우는 걸 막기 위해 확인 팝업을 거침.
              Positioned(
                top: -6,
                right: 2,
                child: GestureDetector(
                  onTap: () => _confirmRemoveChild(code, studentName),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFF030712),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🆕 [요청] 자녀 연결 해제 확인 팝업. 실수로 지우는 걸 막기 위해 반드시 한 번 더 확인.
  // 🆕 [요청 2026-09-08] 로그아웃 확인 팝업 - 실수로 눌러서 바로 로그아웃되지 않도록 확인 절차 추가
  // 🆕 [요청 2026-09-09] 12개 언어 이름을 화면에 짧게 보여주기 위한 표시용 이름표.
  // (실제 저장/적용은 DkeLang.setLanguage()가 그대로 처리 - 학생 마이페이지와 완전히 동일한 방식)
  static const Map<String, String> _langDisplayNames = {
    'KO': '한국어',
    'EN': 'English',
    'JA': '日本語',
    'ZH': '中文',
    'FR': 'Français',
    'DE': 'Deutsch',
    'RU': 'Русский',
    'AR': 'العربية',
    'HI': 'हिन्दी',
    'VI': 'Tiếng Việt',
    'ES': 'Español',
    'TH': 'ไทย',
  };

  String _languageDisplayName(String code) => _langDisplayNames[code] ?? code;

  // 🆕 [요청 2026-09-09] 각 언어 옆에 표시할 국기 이모지
  static const Map<String, String> _langFlags = {
    'KO': '🇰🇷',
    'EN': '🇺🇸',
    'JA': '🇯🇵',
    'ZH': '🇨🇳',
    'FR': '🇫🇷',
    'DE': '🇩🇪',
    'RU': '🇷🇺',
    'AR': '🇸🇦',
    'HI': '🇮🇳',
    'VI': '🇻🇳',
    'ES': '🇪🇸',
    'TH': '🇹🇭',
  };

  // 🆕 [요청 2026-09-09] 부모가 직접 언어를 고르는 팝업 - 고급스러운 디자인으로 재설계.
  // 진한 황금 테두리 + 그라디언트 배경, 국기 아이콘, 선택 시 줄 전체가 황금색으로 채워짐.
  Future<void> _showLanguagePicker() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 520),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF11192E), Color(0xFF0A0F1E)],
            ),
            border: Border.all(color: brandGolden, width: 2.0),
            // 🆕 진한 황금 테두리
            boxShadow: [
              BoxShadow(
                color: brandGolden.withValues(alpha: 0.25),
                blurRadius: 26,
                spreadRadius: 1,
              ),
              const BoxShadow(
                color: Colors.black,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 16),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '언어 선택 ',
                        style: GoogleFonts.notoSansKr(
                          color: brandGolden,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      TextSpan(
                        text: '/ Language',
                        style: GoogleFonts.gowunBatang(
                          color: brandGolden,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(
                color: brandGolden.withValues(alpha: 0.25),
                height: 1,
                thickness: 1,
                indent: 20,
                endIndent: 20,
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(14),
                  itemCount: DkeLang.supportedLanguages.length,
                  itemBuilder: (ctx, idx) {
                    final String code = DkeLang.supportedLanguages[idx];
                    final bool isSelected = DkeLang.current == code;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            await DkeLang.setLanguage(code);
                            if (!mounted) return;
                            Navigator.pop(dialogContext);
                            setState(() {}); // 화면 전체를 새 언어로 다시 그림
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              // 🆕 [요청] 선택 시 줄 전체가 황금색으로 채워지도록
                              color: isSelected
                                  ? brandGolden
                                  : Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? brandGolden
                                    : Colors.white12,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _langFlags[code] ?? '🏳️',
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _languageDisplayName(code),
                                    style: GoogleFonts.notoSansKr(
                                      color: isSelected
                                          ? const Color(0xFF030712)
                                          : Colors.white,
                                      fontWeight: isSelected
                                          ? FontWeight.w900
                                          : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF030712),
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 [2026-09-23] 상단 버튼 4개(로그아웃/회원연동/공지및교육상담/언어)의 공용 모양.
  static const double _kTopButtonHeight = 30;
  static const double _kTopSectionGap = 10; // 🆕 상단 큰 항목 사이 간격 (이 숫자 하나로 조정)

  Widget _buildTopPillButton({
    IconData? icon,
    required String label,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    final Color fg = filled ? Colors.black : brandGolden;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _kTopButtonHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: filled ? brandGolden : Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: brandGolden.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: fg, size: 14),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSansKr(
                  color: fg,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 [2026-09-23] 공지 및 교육상담 화면이 완성되기 전까지 임시 안내
  void _showNoticeComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: premiumCardBg,
        content: Text(
          _biLong(kComingSoonMap),
          style: GoogleFonts.notoSansKr(
            color: brandGolden,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: premiumCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '로그아웃/Log out',
          style: GoogleFonts.notoSansKr(
            color: brandGolden,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '로그아웃 하시겠습니까?\nAre you sure you want to log out?',
          style: GoogleFonts.notoSansKr(
            color: Colors.white70,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              '취소/Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandGolden),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              '로그아웃/Log out',
              style: TextStyle(
                color: Color(0xFF030712),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await AuthService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const EntranceScreen()),
      (route) => false,
    );
  }

  Future<void> _confirmRemoveChild(String code, String? studentName) async {
    final String displayName = (studentName != null && studentName.isNotEmpty)
        ? studentName
        : '코드 $code';
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: premiumCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '자녀 연결 해제/Disconnect Child',
          style: GoogleFonts.notoSansKr(
            color: brandGolden,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '$displayName 자녀와의 연결을 해제하시겠습니까?\n연결을 해제하면 이 목록에서 사라지고, 다시 보려면 자녀 코드를 재입력해야 합니다.\n\nDisconnect from $displayName? They will be removed from this list until you re-enter their code.',
          style: GoogleFonts.notoSansKr(
            color: Colors.white70,
            fontSize: 12.5,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              '취소/Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              '연결 해제/Disconnect',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FamilyLinkService.removeLinkedCode(code);
    if (!mounted) return;
    setState(() {
      _linkedChildCodes.remove(code);
      // 지금 지운 자녀가 선택되어 있었다면, 선택을 풀거나 남은 자녀 중 하나로 자동 전환
      if (_selectedChildCode == code) {
        _selectedChildCode = _linkedChildCodes.isNotEmpty
            ? _linkedChildCodes.first
            : null;
      }
    });
  }

  Widget _buildAddChildChip() {
    return GestureDetector(
      onTap: _showAddChildDialog,
      child: Container(
        width: 130,
        // 🆕 [요청 2026-09-08] 자녀 칩(130)과 폭을 통일 - 예전엔 90이라 줄이 안 맞았음
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        // 🆕 자녀 칩과 동일한 패딩
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12), // 🆕 자녀 칩과 동일한 모서리 둥글기
          border: Border.all(
            color: brandGolden.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, color: brandGolden, size: 22),
            const SizedBox(height: 4),
            Text(
              '자녀 추가',
              style: GoogleFonts.notoSansKr(
                color: brandGolden,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Add Child',
              style: GoogleFonts.notoSansKr(
                color: brandGolden.withValues(alpha: 0.7),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 [실데이터 연동] ParentDataService를 통해 학생의 실제 학습 데이터를 불러옵니다.
  Future<void> _loadRealData() async {
    try {
      final String? realName = await ParentDataService.getStudentName();
      final List<ParentSessionRecord> today =
          await ParentDataService.loadTodaySessions();
      final List<ParentSessionRecord> all =
          await ParentDataService.loadAllSessions();
      final List<ParentExamRecord> exams =
          await ParentDataService.loadExamRecords();
      final List<Map<String, dynamic>> aggregates =
          await ParentDataService.loadSubjectAggregates();
      final int todayStars = await ParentDataService.getTodayStars();

      final DateTime now = DateTime.now();
      final DateTime todayStart = DateTime(now.year, now.month, now.day);
      final DateTime yesterdayStart = todayStart.subtract(
        const Duration(days: 1),
      );

      final int todayMinutes = ParentDataService.totalMinutesForDay(
        all,
        todayStart,
      );
      final int yesterdayMinutes = ParentDataService.totalMinutesForDay(
        all,
        yesterdayStart,
      );

      // 최근 7일(오늘 제외) 총 학습분 / 7 = 일 평균
      int weeklyTotal = 0;
      for (int i = 1; i <= 7; i++) {
        weeklyTotal += ParentDataService.totalMinutesForDay(
          all,
          todayStart.subtract(Duration(days: i)),
        );
      }
      final int weeklyAvg = (weeklyTotal / 7).round();

      final Map<String, double> subjectAvgScores =
          ParentDataService.computeSubjectAverageScores(exams);
      String? strongest;
      String? weakest;
      if (subjectAvgScores.isNotEmpty) {
        final sorted = subjectAvgScores.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        strongest =
            "${sorted.first.key} (${_t(kAvgWordMap)} ${sorted.first.value.toStringAsFixed(0)})";
        weakest =
            "${sorted.last.key} (${_t(kAvgWordMap)} ${sorted.last.value.toStringAsFixed(0)})";
      }

      if (!mounted) return;
      setState(() {
        _realChildName = realName ?? widget.childName;
        _todaySessions = today;
        _allSessions = all;
        _examRecords = exams;
        _subjectAggregates = aggregates;
        _totalCollectedStars = todayStars;
        _todayTotalMinutes = todayMinutes;
        _yesterdayTotalMinutes = yesterdayMinutes;
        _weeklyAvgMinutesPerDay = weeklyAvg;
        _strongestSubject = strongest;
        _weakestSubject = weakest;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("[ParentDashboard] 실데이터 로딩 실패: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🆕 [실데이터 연동] 오늘 세션 목록 + 실제 AI 종합 총평(150~200자, DiagnosisService)을 함께 보여줍니다.
  // 🆕 [자녀 선택 UI] 매개변수화된 버전(_buildSummaryReportTextFor)에 위임 - 로컬 모드는 자신의
  // state(_realChildName/_todaySessions/_todayTotalMinutes)를 그대로 넘기므로 동작 변경 없음.
  Future<String> _buildSummaryReportText() => _buildSummaryReportTextFor(
    _realChildName,
    _todaySessions,
    _todayTotalMinutes,
  );

  Future<String> _buildSummaryReportTextFor(
    String childName,
    List<ParentSessionRecord> todaySessions,
    int todayTotalMinutes,
  ) async {
    if (todaySessions.isEmpty) {
      return _biLong(kNoSessionTodayMap);
    }
    final buffer = StringBuffer();
    buffer.writeln("${_t(kReportHeaderMap)}\n");
    for (int i = 0; i < todaySessions.length; i++) {
      final rec = todaySessions[i];
      final String periodLabel = _isNumberFirstLang
          ? "제${i + 1}${_t(kPeriodWordMap)}"
          : "${_t(kPeriodWordMap)} ${i + 1}";
      buffer.writeln(
        "$periodLabel · ${rec.subject} · ${rec.durationMinutes}${_t(kMinutesUnitMap)} ${_t(kFocusCompletedMap)}",
      );
      if (rec.recordType == '평가' && rec.score != null) {
        buffer.writeln("  ${_t(kScoreLabelMap)}: ${rec.score}");
      }
    }
    buffer.writeln(
      "\n${_t(kTodayTotalTimeMap)}: $todayTotalMinutes${_t(kMinutesUnitMap)}",
    );

    // 🆕 [요청] 오늘 학습한 과목 전체를 종합한 150~200자 AI 총평을 별도 문단으로 추가
    final int subjectCount = todaySessions.map((r) => r.subject).toSet().length;
    final String dailySummary = await DiagnosisService.getDailySummary(
      personKey: 'student_$childName',
      subjectCount: subjectCount,
      totalMinutes: todayTotalMinutes,
    );
    buffer.writeln("\n${_t(kTodaySummaryHeaderMap)}");
    buffer.writeln(dailySummary);

    return buffer.toString();
  }

  // 🆕 [버그 수정] 기존엔 가장 최근 세션 1건만 보여줬음 -> 오늘 학습한 모든 세션을
  // 제1교시, 제2교시... 순서대로 전부 나열하도록 수정 (요청사항)
  // 🆕 [자녀 선택 UI] 매개변수화된 버전(_buildDetailedAnalysisTextFor)에 위임
  String _buildDetailedAnalysisText() =>
      _buildDetailedAnalysisTextFor(_todaySessions);

  String _buildDetailedAnalysisTextFor(
    List<ParentSessionRecord> todaySessions,
  ) {
    if (todaySessions.isEmpty) {
      return _t(kNoDetailTodayMap);
    }
    final buffer = StringBuffer();
    buffer.writeln("${_t(kDetailHeaderMap)}\n");
    for (int i = 0; i < todaySessions.length; i++) {
      final rec = todaySessions[i];
      final String periodLabel = _isNumberFirstLang
          ? "제${i + 1}${_t(kPeriodWordMap)}"
          : "${_t(kPeriodWordMap)} ${i + 1}";
      buffer.writeln(
        "■ $periodLabel · ${rec.subject} (${_recordTypeLabel(rec.recordType)})",
      );
      buffer.writeln(
        "  ${_t(kDetailContentLabelMap)}: ${rec.details.isNotEmpty ? rec.details : _t(kNoRecordMap)}",
      );
      if (rec.recordType == '평가' && rec.score != null)
        buffer.writeln("  ${_t(kScoreLabelMap)}: ${rec.score}");
      if (rec.understanding != null)
        buffer.writeln(
          "  ${_t(kUnderstandingLabelMap)}: ${rec.understanding}%",
        );
      if (rec.difficulty != null)
        buffer.writeln("  ${_t(kDifficultyLabelMap)}: ${rec.difficulty}");
      if (rec.concentration != null)
        buffer.writeln("  ${_t(kConcentrationLabelMap)}: ${rec.concentration}");
      if (rec.condition != null)
        buffer.writeln("  ${_t(kConditionLabelMap)}: ${rec.condition}");
      if (rec.incorrectNote != null)
        buffer.writeln("  ${_t(kIncorrectNoteLabelMap)}: ${rec.incorrectNote}");
      if (rec.nextGoal.isNotEmpty)
        buffer.writeln("  ${_t(kNextGoalLabelMap)}: ${rec.nextGoal}");
      buffer.writeln();
    }
    return buffer.toString();
  }

  void _showReportPopup(
    BuildContext context,
    String mainTitle,
    String content,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: premiumCardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: brandGolden.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          mainTitle,
                          style: GoogleFonts.notoSansKr(
                            color: brandGolden,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white60,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(
                    color: Colors.white10,
                    height: 16,
                    thickness: 1.2,
                  ),
                  Text(
                    content,
                    style: GoogleFonts.notoSansKr(
                      color: Colors.white,
                      fontSize: 13.5,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMonitorTimeoutSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E1E2D),
        content: Text(
          _t(kMonitorTimeoutMap),
          style: GoogleFonts.notoSansKr(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 🆕 [다국어] foreignTitle 파라미터 추가: 자식 위젯(parent_detailed_analysis_widget.dart 등)이
  // 이미 10개국어 대응을 위해 이 파라미터를 요구하는 시그니처로 되어 있어 타입을 맞춰줍니다.
  // 외국어(10개국) 선택 시에는 foreignTitle 한 줄만, 기본모드(KO/EN)는 기존처럼 영문+한글 2줄 표시.
  Widget _buildCustomSectionTitle(
    String engTitle,
    String korTitle, {
    required double fontSize,
    String? foreignTitle,
  }) {
    if (DkeLang.isForeignSelected &&
        foreignTitle != null &&
        foreignTitle.isNotEmpty) {
      return Text(
        foreignTitle,
        style: GoogleFonts.notoSansKr(
          color: brandGolden,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          height: 1.3,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          engTitle,
          style: GoogleFonts.gowunBatang(
            color: Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: fontSize - 2.0,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          korTitle,
          style: GoogleFonts.notoSansKr(
            color: brandGolden,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  // 🆕 [정리] 대단원/중단원 토글 로직을 공용 메서드로 분리 - 로컬 모드/Firestore 모드
  // 양쪽의 ParentEvaluationAnalysisWidget 인스턴스가 동일하게 재사용합니다.
  void _toggleBigUnit(String unit) {
    setState(() {
      if (_selectedBigUnits.contains(unit)) {
        if (_selectedBigUnits.length > 1) _selectedBigUnits.remove(unit);
      } else {
        _selectedBigUnits.add(unit);
      }
    });
  }

  void _toggleMidUnit(String unit) {
    setState(() {
      if (_selectedMidUnits.contains(unit)) {
        if (_selectedMidUnits.length > 1) _selectedMidUnits.remove(unit);
      } else {
        _selectedMidUnits.add(unit);
      }
    });
  }

  // 🆕 [자녀 선택 UI + Firestore 연동] Firestore 문서의 sessionHistory 배열을
  // ParentSessionRecord 리스트로 파싱 (로컬 파싱 로직과 동일한 모델을 그대로 재사용)
  List<ParentSessionRecord> _parseSessionHistory(Map<String, dynamic> data) {
    final List<dynamic> raw = (data['sessionHistory'] as List<dynamic>?) ?? [];
    final List<ParentSessionRecord> list = [];
    for (final e in raw) {
      try {
        list.add(
          ParentSessionRecord.fromJson(Map<String, dynamic>.from(e as Map)),
        );
      } catch (_) {
        // 손상된 기록 1건은 건너뛰고 나머지는 계속 집계
      }
    }
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  // 🆕 [자녀 선택 UI + Firestore 연동] Firestore 문서의 examRecords 배열을
  // ParentExamRecord 리스트로 파싱
  List<ParentExamRecord> _parseExamRecords(Map<String, dynamic> data) {
    final List<dynamic> raw = (data['examRecords'] as List<dynamic>?) ?? [];
    final List<ParentExamRecord> list = [];
    for (final e in raw) {
      try {
        list.add(
          ParentExamRecord.fromJson(Map<String, dynamic>.from(e as Map)),
        );
      } catch (_) {}
    }
    return list;
  }

  bool _isSameDateHelper(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<ParentSessionRecord> _todaySessionsFrom(List<ParentSessionRecord> all) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return all.where((r) => !r.timestamp.isBefore(start)).toList();
  }

  // 🆕 [자녀 선택 UI + Firestore 연동] ParentDataService.loadSubjectAggregates()와
  // 동일한 집계 로직을 Firestore에서 받아온 세션 리스트에 대해 그대로 적용
  // (로컬 SharedPreferences 대신 이미 메모리에 있는 리스트를 입력으로 받는 순수 함수 버전)
  List<Map<String, dynamic>> _computeSubjectAggregatesFrom(
      List<ParentSessionRecord> all,
      ) {
    final DateTime now = DateTime.now();
    final DateTime todayStart = DateTime(now.year, now.month, now.day);
    // 🆕 [2026-09-24] 주의 시작을 일요일로 통일 (일~토, 장학금 주간 개근과 같은 기준)
    final DateTime weekStart = todayStart.subtract(
      Duration(days: now.weekday % 7),
    );
    final DateTime monthStart = DateTime(now.year, now.month, 1);
    final DateTime yearStart = DateTime(now.year, 1, 1);

    final Map<String, List<ParentSessionRecord>> bySubject = {};
    for (final r in all) {
      bySubject.putIfAbsent(r.subject, () => []).add(r);
    }

    final List<Map<String, dynamic>> aggregated = [];
    bySubject.forEach((subject, sessions) {
      // 🆕 [2026-09-24] 기간별 "실제" 학습 합계(분) - 예상치가 아닌 진짜 합산
      int todayMinutes = 0, weekMinutes = 0, monthMinutes = 0, yearMinutes = 0;
      int totalMinutesAllTime = 0;
      final Set<String> activeDayKeys = {};

      for (final s in sessions) {
        final DateTime ts = s.timestamp;
        final int m = s.durationMinutes;
        if (!ts.isBefore(yearStart)) yearMinutes += m;
        if (!ts.isBefore(monthStart)) monthMinutes += m;
        if (!ts.isBefore(weekStart)) weekMinutes += m;
        if (!ts.isBefore(todayStart)) todayMinutes += m;
        totalMinutesAllTime += m;
        activeDayKeys.add("${ts.year}-${ts.month}-${ts.day}");
      }

      if (todayMinutes + weekMinutes + monthMinutes + yearMinutes == 0) return;

      final int activeDays = activeDayKeys.isEmpty ? 1 : activeDayKeys.length;
      final int avgMinutesPerActiveDay = (totalMinutesAllTime / activeDays).round();

      aggregated.add({
        "subject": subject,
        "hasStudiedToday": todayMinutes > 0,
        "hasStudiedWeekly": weekMinutes > 0,
        "hasStudiedMonthly": monthMinutes > 0,
        "hasStudiedYearly": yearMinutes > 0,
        "baseMinutes": avgMinutesPerActiveDay, // 기존 호환용으로 유지
        "todayMinutes": todayMinutes,
        "weekMinutes": weekMinutes,
        "monthMinutes": monthMinutes,
        "yearMinutes": yearMinutes,
      });
    });
    return aggregated;
  }

  // 🆕 [자녀 선택 UI + Firestore 연동] 상세보기 탭 - 자녀가 선택되어 있으면 Firestore의
  // sessionHistory를 기반으로 지난 일자 조회를, 없으면 기존처럼 로컬 데이터를 사용합니다.
  Widget _buildDetailedAnalysisTabContent() {
    if (_selectedChildCode == null) {
      return ParentDetailedAnalysisWidget(
        childName: _realChildName,
        premiumCardBg: premiumCardBg,
        brandGolden: brandGolden,
        luxuryDarkBg: luxuryDarkBg,
        buildCustomSectionTitle: _buildCustomSectionTitle,
        onShowReportPopup: () async {
          final String content = await _buildSummaryReportText();
          if (!mounted) return;
          _showReportPopup(context, _t(kTodayOverallReportTitleMap), content);
        },
        onShowDetailedAnalysisPopup: () => _showReportPopup(
          context,
          _t(kTodayDetailReportTitleMap),
          _buildDetailedAnalysisText(),
        ),
        selectedDate: _detailedViewDate,
        onPreviousDay: _goToPreviousDetailDay,
        onNextDay: _goToNextDetailDay,
        isViewingToday: _isViewingToday,
        sessionsForDate: _sessionsForDetailedDate,
        todayTotalMinutes: _detailedDayTotalMinutes,
        yesterdayTotalMinutes: _detailedDayBeforeMinutes,
        weeklyAvgMinutesPerDay: _detailedWeeklyAvgMinutes,
        strongestSubject: _strongestSubject,
        weakestSubject: _weakestSubject,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FamilyLinkService.watch(_selectedChildCode!),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !(snapshot.data?.exists ?? false)) {
          return const Center(
            child: CircularProgressIndicator(color: brandGolden),
          );
        }
        final Map<String, dynamic> data = snapshot.data!.data() ?? {};
        final String childName =
            (data['studentName'] as String?)?.trim().isNotEmpty == true
            ? (data['studentName'] as String)
            : '학습자';
        final List<ParentSessionRecord> allSessions = _parseSessionHistory(
          data,
        );
        final List<ParentExamRecord> examRecords = _parseExamRecords(data);

        final DateTime d = DateTime(
          _detailedViewDate.year,
          _detailedViewDate.month,
          _detailedViewDate.day,
        );
        final int todayTotal = ParentDataService.totalMinutesForDay(
          allSessions,
          d,
        );
        final int yesterdayTotal = ParentDataService.totalMinutesForDay(
          allSessions,
          d.subtract(const Duration(days: 1)),
        );
        int weeklyTotal = 0;
        for (int i = 1; i <= 7; i++) {
          weeklyTotal += ParentDataService.totalMinutesForDay(
            allSessions,
            d.subtract(Duration(days: i)),
          );
        }
        final int weeklyAvg = (weeklyTotal / 7).round();

        final Map<String, double> subjectAvgScores =
            ParentDataService.computeSubjectAverageScores(examRecords);
        String? strongest;
        String? weakest;
        if (subjectAvgScores.isNotEmpty) {
          final sorted = subjectAvgScores.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          strongest =
              "${sorted.first.key} (${_t(kAvgWordMap)} ${sorted.first.value.toStringAsFixed(0)})";
          weakest =
              "${sorted.last.key} (${_t(kAvgWordMap)} ${sorted.last.value.toStringAsFixed(0)})";
        }

        final List<ParentSessionRecord> sessionsForDate = allSessions
            .where((r) => _isSameDateHelper(r.timestamp, _detailedViewDate))
            .toList();
        final bool isToday = _isSameDateHelper(
          _detailedViewDate,
          DateTime.now(),
        );

        return ParentDetailedAnalysisWidget(
          childName: childName,
          premiumCardBg: premiumCardBg,
          brandGolden: brandGolden,
          luxuryDarkBg: luxuryDarkBg,
          buildCustomSectionTitle: _buildCustomSectionTitle,
          onShowReportPopup: () async {
            final String content = await _buildSummaryReportTextFor(
              childName,
              _todaySessionsFrom(allSessions),
              todayTotal,
            );
            if (!mounted) return;
            _showReportPopup(context, _t(kTodayOverallReportTitleMap), content);
          },
          onShowDetailedAnalysisPopup: () => _showReportPopup(
            context,
            _t(kTodayDetailReportTitleMap),
            _buildDetailedAnalysisTextFor(_todaySessionsFrom(allSessions)),
          ),
          selectedDate: _detailedViewDate,
          onPreviousDay: _goToPreviousDetailDay,
          onNextDay: _goToNextDetailDay,
          isViewingToday: isToday,
          sessionsForDate: sessionsForDate,
          todayTotalMinutes: todayTotal,
          yesterdayTotalMinutes: yesterdayTotal,
          weeklyAvgMinutesPerDay: weeklyAvg,
          strongestSubject: strongest,
          weakestSubject: weakest,
        );
      },
    );
  }

  // 🆕 [자녀 선택 UI + Firestore 연동] 평가분석 탭 - 자녀가 선택되어 있으면 Firestore의
  // examRecords/sessionHistory를 기반으로, 없으면 기존처럼 로컬 데이터를 사용합니다.
  Widget _buildEvaluationAnalysisTabContent() {
    if (_selectedChildCode == null) {
      return ParentEvaluationAnalysisWidget(
        childName: _realChildName,
        selectedEvaluationType: _selectedEvaluationType,
        selectedBigUnits: _selectedBigUnits,
        selectedMidUnits: _selectedMidUnits,
        selectedYear: _selectedYear,
        selectedMonth: _selectedMonth,
        selectedWeek: _selectedWeek,
        timeTabController: _timeTabController,
        mirroredExamRecords: _examRecords,
        parentMasterTimeData: _computeSubjectAggregatesFrom(_allSessions),
        premiumCardBg: premiumCardBg,
        brandGolden: brandGolden,
        luxuryDarkBg: luxuryDarkBg,
        buildCustomSectionTitle: _buildCustomSectionTitle,
        onEvaluationTypeChanged: (type) =>
            setState(() => _selectedEvaluationType = type),
        onBigUnitChanged: _toggleBigUnit,
        onMidUnitChanged: _toggleMidUnit,
        onYearChanged: (year) => setState(() => _selectedYear = year),
        onMonthChanged: (month) => setState(() => _selectedMonth = month),
        onWeekChanged: (week) => setState(() => _selectedWeek = week),
        onShowDetailAnalysisReport: () async {
          if (_examRecords.isEmpty) {
            _showReportPopup(
              context,
              _t(kDiagReportTitleMap),
              _t(kNoExamDataMap),
            );
            return;
          }
          final lastExam = _examRecords.last;
          final String content = await DiagnosisService.getAnalysis(
            personKey: 'student_$_realChildName',
            type: lastExam.type,
            subject: lastExam.subject,
            score: lastExam.score,
          );
          if (!mounted) return;
          _showReportPopup(context, _t(kDiagReportTitleMap), content);
        },
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FamilyLinkService.watch(_selectedChildCode!),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !(snapshot.data?.exists ?? false)) {
          return const Center(
            child: CircularProgressIndicator(color: brandGolden),
          );
        }
        final Map<String, dynamic> data = snapshot.data!.data() ?? {};
        final String childName =
            (data['studentName'] as String?)?.trim().isNotEmpty == true
            ? (data['studentName'] as String)
            : '학습자';
        final List<ParentSessionRecord> allSessions = _parseSessionHistory(
          data,
        );
        final List<ParentExamRecord> examRecords = _parseExamRecords(data);
        final List<Map<String, dynamic>> subjectAggregates =
            _computeSubjectAggregatesFrom(allSessions);

        return ParentEvaluationAnalysisWidget(
          childName: childName,
          selectedEvaluationType: _selectedEvaluationType,
          selectedBigUnits: _selectedBigUnits,
          selectedMidUnits: _selectedMidUnits,
          selectedYear: _selectedYear,
          selectedMonth: _selectedMonth,
          selectedWeek: _selectedWeek,
          timeTabController: _timeTabController,
          mirroredExamRecords: examRecords,
          parentMasterTimeData: subjectAggregates,
          premiumCardBg: premiumCardBg,
          brandGolden: brandGolden,
          luxuryDarkBg: luxuryDarkBg,
          buildCustomSectionTitle: _buildCustomSectionTitle,
          onEvaluationTypeChanged: (type) =>
              setState(() => _selectedEvaluationType = type),
          onBigUnitChanged: _toggleBigUnit,
          onMidUnitChanged: _toggleMidUnit,
          onYearChanged: (year) => setState(() => _selectedYear = year),
          onMonthChanged: (month) => setState(() => _selectedMonth = month),
          onWeekChanged: (week) => setState(() => _selectedWeek = week),
          onShowDetailAnalysisReport: () async {
            if (examRecords.isEmpty) {
              _showReportPopup(
                context,
                _t(kDiagReportTitleMap),
                _t(kNoExamDataMap),
              );
              return;
            }
            final lastExam = examRecords.last;
            final String content = await DiagnosisService.getAnalysis(
              personKey: 'student_$childName',
              type: lastExam.type,
              subject: lastExam.subject,
              score: lastExam.score,
            );
            if (!mounted) return;
            _showReportPopup(context, _t(kDiagReportTitleMap), content);
          },
        );
      },
    );
  }

  // 🆕 [자녀 선택 UI + Firestore 연동] 성적관리 탭 - 자녀가 선택되어 있으면 Firestore의
  // gradeRecords/gradeConfigs/examRecords를 기반으로, 없으면 기존처럼 로컬 데이터를 사용합니다.
  Widget _buildGradeManagementTabContent() {
    if (_selectedChildCode == null) {
      return ParentGradeManagementWidget(
        childName: _realChildName,
        premiumCardBg: premiumCardBg,
        brandGolden: brandGolden,
        luxuryDarkBg: luxuryDarkBg,
        buildCustomSectionTitle: _buildCustomSectionTitle,
        isActiveTab: _currentIndex == 3,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FamilyLinkService.watch(_selectedChildCode!),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !(snapshot.data?.exists ?? false)) {
          return const Center(
            child: CircularProgressIndicator(color: brandGolden),
          );
        }
        final Map<String, dynamic> data = snapshot.data!.data() ?? {};
        final String childName =
            (data['studentName'] as String?)?.trim().isNotEmpty == true
            ? (data['studentName'] as String)
            : '학습자';

        final List<dynamic> rawRecords =
            (data['gradeRecords'] as List<dynamic>?) ?? [];
        final List<GradeRecord> records = [];
        for (final e in rawRecords) {
          try {
            records.add(
              GradeRecord.fromJson(Map<String, dynamic>.from(e as Map)),
            );
          } catch (_) {}
        }

        final List<dynamic> rawConfigs =
            (data['gradeConfigs'] as List<dynamic>?) ?? [];
        final List<SubjectConfig> configs = [];
        for (final e in rawConfigs) {
          try {
            configs.add(
              SubjectConfig.fromJson(Map<String, dynamic>.from(e as Map)),
            );
          } catch (_) {}
        }

        // 🆕 [연동] readAchievementAverageScore()와 동일한 방식(score 필드 평균)으로
        // Firestore의 examRecords 배열에서 계산 - 로컬 전용 함수를 대체하는 순수 계산 버전
        final List<dynamic> rawExamRecords =
            (data['examRecords'] as List<dynamic>?) ?? [];
        final List<double> scores = [];
        for (final e in rawExamRecords) {
          try {
            final map = Map<String, dynamic>.from(e as Map);
            final double? s = (map['score'] as num?)?.toDouble();
            if (s != null) scores.add(s);
          } catch (_) {}
        }
        final double? achievementAvg = scores.isEmpty
            ? null
            : scores.reduce((a, b) => a + b) / scores.length;

        return ParentGradeManagementWidget(
          childName: childName,
          premiumCardBg: premiumCardBg,
          brandGolden: brandGolden,
          luxuryDarkBg: luxuryDarkBg,
          buildCustomSectionTitle: _buildCustomSectionTitle,
          overrideRecords: records,
          overrideConfigs: configs,
          overrideAchievementAverage: achievementAvg,
          isActiveTab: _currentIndex == 3,
        );
      },
    );
  }

  // ============================================================================
  // 🆕 [장학금 방 2026-09-17] 5번째 탭 - 부모가 매달 유형(성장형/도전형/성취형)을
  // 직접 선택하면, 선택된 자녀의 이번 달 누적 별(기본+보너스)을 기준으로 계산된
  // 최종 금액을 보여줍니다. 유형 자동판정이 아니라 부모의 수동 선택이라는 점이 핵심.
  // ============================================================================
  void _showParentScholarshipNoticeDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: premiumCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 580),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: brandGolden.withValues(alpha: 0.35),
              width: 1.3,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(_t(kScholarshipParentNoticeDialogTitleMap), style: GoogleFonts.notoSansKr(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 17))),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 18),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(getScholarshipParentNoticeText(DkeLang.current), style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13, height: 1.7)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  String _koOnlyManwon() => DkeLang.current == 'KO' ? '만원' : 'k KRW';
  Widget _buildScholarshipTabContent() {
    if (_selectedChildCode == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _biLong(kScholarshipNoChildMap),
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              color: Colors.white54,
              fontSize: 13,
              height: 1.7,
            ),
          ),
        ),
      );
    }

    final String monthKey =
        '${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FamilyLinkService.watch(_selectedChildCode!),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !(snapshot.data?.exists ?? false)) {
          return const Center(
            child: CircularProgressIndicator(color: brandGolden),
          );
        }
        final Map<String, dynamic> data = snapshot.data!.data() ?? {};
        final String childName =
            (data['studentName'] as String?)?.trim().isNotEmpty == true
            ? (data['studentName'] as String)
            : '학습자';

        final Map<String, dynamic> scholarshipMap = Map<String, dynamic>.from(
          (data['scholarship'] as Map?) ?? {},
        );
        final Map<String, dynamic> monthData = Map<String, dynamic>.from(
          (scholarshipMap[monthKey] as Map?) ?? {},
        );
        final int baseStars =
            (monthData['monthlyBaseStars'] as num?)?.toInt() ?? 0;
        final int bonusStars =
            (monthData['monthlyBonusStars'] as num?)?.toInt() ?? 0;
        final int totalStars = baseStars + bonusStars;
        final Map<String, dynamic> bonusBreakdownRaw =
            Map<String, dynamic>.from(
              (monthData['bonusBreakdown'] as Map?) ?? {},
            );

        final Map<String, dynamic> typeSelections = Map<String, dynamic>.from(
          (data['scholarshipTypeSelections'] as Map?) ?? {},
        );
        final String? selectedTypeKey = typeSelections[monthKey] as String?;
        final ScholarshipType? selectedType = ScholarshipService.typeFromKey(
          selectedTypeKey,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildCustomSectionTitle(
                      'SCHOLARSHIP',
                      '$childName - ${_t(kScholarshipTitleMap)}',
                      fontSize: 19,
                    ),
                  ),
                  IconButton(
                padding: const EdgeInsets.only(top: 8, left: 12),
                onPressed: _showParentScholarshipNoticeDialog,
                icon: Icon(
                  Icons.info_outline_rounded,
                  color: brandGolden,
                  size: 40,
                ),
              ),
                ],
              ),
              const SizedBox(height: 6),

              // 이번 달 누적 별 요약 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      brandGolden.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: brandGolden.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t(kScholarshipMonthlyStarsMap),
                          style: GoogleFonts.notoSansKr(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildNumberWithUnit(
                          '$totalStars',
                          kStarCountUnitMap,
                          fontSize: 26,
                          color: brandGolden,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _baseBonusText(baseStars, bonusStars),
                          style: GoogleFonts.notoSansKr(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFD700),
                      size: 34,
                    ),
                  ],
                ),
              ),

              // 보너스별 상세 내역 (학생 화면과 100% 동일한 색상/구성)
              if (bonusBreakdownRaw.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(_t(kScholarshipBonusDetailTitleMap), style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 12.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: premiumCardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: bonusBreakdownRaw.entries.map((entry) {
                      final String typeKey = entry.key;
                      final int count = (entry.value as num?)?.toInt() ?? 0;
                      final String label = kBonusLabelForType(typeKey);
                      final int perEvent = kBonusTypeStarAmountMap[typeKey] ?? 0;
                      final Color chipColor = kBonusTypeColorMap[typeKey] ?? brandGolden;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: chipColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${kScholarshipBonusTypeLabelByLang[typeKey]?['EN'] ?? label} (+$perEvent × $count times)",
                                    style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 10.5),
                                  ),
                                  Text(
                                    "$label (+$perEvent × ${count}회)",
                                    style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "+${perEvent * count}",
                              style: GoogleFonts.notoSansKr(color: chipColor, fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 22),
              Text(
                _t(kScholarshipPickTypeMap),
                style: GoogleFonts.notoSansKr(
                  color: brandGolden,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(_t(kScholarshipTapToSelectMap), style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10.5)),
              const SizedBox(height: 12),

              // 🆕 [상세화] 3개 유형을 동시에 나열, 각각 계산식과 최종금액을 함께 표시.
              // 선택된 유형은 골드 테두리로 강조됨.
              ...ScholarshipType.values.map((type) {
                final bool isSel = selectedType == type;
                final int rate = ScholarshipService.starRateWon[type]!;
                final int cap = ScholarshipService.monthlyCapWon[type]!;
                final int amount = ScholarshipService.calculateAmountWon(
                  monthlyTotalStars: totalStars,
                  type: type,
                );
                final int rawTotal = totalStars * rate;
                final bool isCapped = rawTotal > cap;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => FamilyLinkService.setScholarshipType(
                      _selectedChildCode!,
                      monthKey: monthKey,
                      typeKey: ScholarshipService.typeToKey(type),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: isSel
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF11192E), Color(0xFF0A0F1E)],
                              )
                            : null,
                        color: isSel ? null : premiumCardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: brandGolden.withValues(
                            alpha: isSel ? 1.0 : 0.25,
                          ),
                          width: isSel ? 1.6 : 1.0,
                        ),
                        boxShadow: isSel
                            ? [
                                BoxShadow(
                                  color: brandGolden.withValues(alpha: 0.15),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "${_scholarshipTypeEnLabels[type.index]} / ${ScholarshipService.typeLabelKo[type]!}",
                                    style: GoogleFonts.notoSansKr(
                                      color: isSel ? brandGolden : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (isSel) ...[
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: brandGolden,
                                      size: 16,
                                    ),
                                  ],
                                ],
                              ),
                              Text("${_t(kScholarshipMonthlyCapPrefixMap)} ${(cap / 10000).toStringAsFixed(0)}${_koOnlyManwon()}", style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10.5)),
                            ],
                          ),
                          const SizedBox(height: 10),
                      Text(
                        _t(kScholarshipStarsTimesRateMap).replaceFirst('%s', '$totalStars').replaceFirst('%s', '$rate'),
                        style: GoogleFonts.notoSansKr(color: Colors.white60, fontSize: 11.5),
                      ),
                          if (isCapped)
                            Text(
                              _t(kScholarshipCapAppliedMap).replaceFirst('%s', _formatWon(rawTotal)),
                              style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10.5),
                            ),
                          const SizedBox(height: 8),
                          _buildNumberWithUnit(
                            _formatWon(amount),
                            kWonUnitMap,
                            fontSize: 22,
                            color: isSel ? brandGolden : Colors.white70,
                            weight: FontWeight.w900,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),


              const SizedBox(height: 10),
              Text(
                _t(kScholarshipFooterNoteMap),
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 11, height: 1.5),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🆕 [장학금 방 상세화 2026-09-17] 시뮬레이션 표 한 줄. showMoney가 true인 경우(월간 기준)에만
  // 3개 유형의 예상 금액까지 함께 보여줌.
  Widget _buildScholarshipSimulationRow({
    required String label,
    required String detail,
    required int stars,
    required bool showMoney,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: premiumCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.notoSansKr(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "$stars개",
                style: GoogleFonts.notoSansKr(
                  color: brandGolden,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: GoogleFonts.notoSansKr(
              color: Colors.white38,
              fontSize: 10.5,
            ),
          ),
          if (showMoney) ...[
            const Divider(color: Colors.white10, height: 16),
            ...ScholarshipType.values.map((type) {
              final int amount = ScholarshipService.calculateAmountWon(
                monthlyTotalStars: stars,
                type: type,
              );
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ScholarshipService.typeLabelKo[type]!,
                      style: GoogleFonts.notoSansKr(
                        color: Colors.white70,
                        fontSize: 11.5,
                      ),
                    ),
                    Text(
                      "${_formatWon(amount)}원",
                      style: GoogleFonts.notoSansKr(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // 🆕 [장학금 방 상세화 2026-09-17] 천 단위 콤마 포맷 헬퍼

  // 🆕 [장학금 방 상세화 2026-09-17] 천 단위 콤마 포맷 헬퍼
  static String _formatWon(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
  );

  // 🆕 [2026-09-23] 숫자 + 단위 표시 (장학금 탭 "개"/"원" 영문 병기)
  Widget _buildNumberWithUnit(
      String number,
      Map<String, String> unitMap, {
        required double fontSize,
        required Color color,
        FontWeight weight = FontWeight.bold,
      }) {
    if (DkeLang.isForeignSelected) {
      return Text(
        "$number ${_t(unitMap)}",
        style: GoogleFonts.notoSansKr(
          color: color,
          fontWeight: weight,
          fontSize: fontSize,
        ),
      );
    }
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "$number${unitMap['KO']}",
            style: GoogleFonts.notoSansKr(
              color: color,
              fontWeight: weight,
              fontSize: fontSize,
            ),
          ),
          TextSpan(
            text: " / ${unitMap['EN']}",
            style: GoogleFonts.gowunBatang(
              color: color.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
              fontSize: fontSize * 0.55,
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 [2026-09-23] "(기본 N + 보너스 N)" 영문 병기
  String _baseBonusText(int base, int bonus) {
    if (DkeLang.isForeignSelected) {
      return "(${_t(kBaseWordMap)} $base + ${_t(kBonusWordMap)} $bonus)";
    }
    return "(기본 $base + 보너스 $bonus)\n(Base $base + Bonus $bonus)";
  }

  // 🆕 [자녀 선택 UI + Firestore 연동] 실시간현황 탭 - 자녀가 선택되어 있으면 해당 자녀의
  // Firestore 문서(links/{code})를 실시간 구독해서 이름/최근세션/별을 보여주고,
  // 연결된 자녀가 없으면(기존 단일기기 사용자) 원래대로 이 기기의 로컬 데이터를 보여줍니다.
  Widget _buildLiveStatusTabContent() {
    // 🆕 [실시간 학습 현황 - 비용 절감 2026-09-19] IndexedStack은 화면 전환 시
    // 위젯을 없애지 않고 계속 메모리에 살려두는 방식이라, 부모가 다른 탭(예:
    // 장학금 탭)을 보고 있어도 이 함수의 Firestore 실시간 구독(watch)이 계속
    // 유지되어 불필요한 읽기 비용이 발생하고 있었음. 지금 실제로 이 탭(인덱스 0)이
    // 화면에 보이고 있을 때만 구독을 만들고, 다른 탭을 보는 중이면 아예 빈 화면만
    // 반환해서 구독 자체가 생기지 않도록 함.
    if (_currentIndex != 0) {
      return const SizedBox.shrink();
    }
    if (_selectedChildCode == null) {
      return ParentLiveStatusWidget(
        childName: _realChildName,
        lastSessionSubject: _todaySessions.isNotEmpty
            ? _todaySessions.last.subject
            : null,
        lastSessionDurationMinutes: _todaySessions.isNotEmpty
            ? _todaySessions.last.durationMinutes
            : 0,
        totalCollectedStars: _totalCollectedStars,
        isMonitoringActive: _isMonitoringActive,
        monitoringCountdown: _monitoringCountdown,
        premiumCardBg: premiumCardBg,
        brandGolden: brandGolden,
        luxuryDarkBg: luxuryDarkBg,
        lastSentTimeText: _lastSentTimeText,
        buildCustomSectionTitle: _buildCustomSectionTitle,
        onSendEmojiMessage: _handleSendEmojiMessage,
        onSendCustomMessage: _handleSendCustomMessage,
        onStartMonitoring: _handleStartMonitoring,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FamilyLinkService.watch(_selectedChildCode!),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !(snapshot.data?.exists ?? false)) {
          return const Center(
            child: CircularProgressIndicator(color: brandGolden),
          );
        }
        final Map<String, dynamic> data = snapshot.data!.data() ?? {};
        // 🆕 [실시간 학습 현황 2026-09-19] 학생 쪽에서 pushLiveStudyStatus()로
        // 올린 현재 학습 상태를 꺼냄. 필드가 아직 없으면(한 번도 타이머를
        // 안 돌렸으면) 전부 기본값(쉬는 중)으로 처리.
        final Map<String, dynamic> liveStatus =
            (data['liveStatus'] as Map<String, dynamic>?) ?? {};
        final bool isStudyingNow = liveStatus['isStudying'] as bool? ?? false;
        final String liveSubject = (liveStatus['subject'] as String?) ?? '';
        final int liveElapsedSeconds = (liveStatus['elapsedSeconds'] as num?)?.toInt() ?? 0;
        final int liveTotalSeconds = (liveStatus['totalSeconds'] as num?)?.toInt() ?? 0;
        // 🆕 오래된 값 방치 방지: 업데이트가 5분 넘게 안 됐으면 "쉬는 중"으로 간주
        // (학생이 인터넷 끊긴 채로 앱만 켜놓고 나갔을 때, 화면에 "학습 중"이
        // 영원히 박제되는 것을 막기 위한 안전장치)
        final Timestamp? liveUpdatedAt = liveStatus['updatedAt'] as Timestamp?;
        final bool isLiveStatusFresh = liveUpdatedAt != null &&
            DateTime.now().difference(liveUpdatedAt.toDate()).inMinutes < 5;
        final bool showAsStudying = isStudyingNow && isLiveStatusFresh;

        final String childName =
        (data['studentName'] as String?)?.trim().isNotEmpty == true
            ? (data['studentName'] as String)
            : '학습자';
        final int totalStars = (data['todayStars'] as num?)?.toInt() ?? 0;
        // 🆕 [버그 수정 2026-09-06] "오늘의 별" 대신 전체 누적 별 개수 - 장학금 위젯이
        // 이 값으로 계산해야 상단 자녀 칩(⭐)의 숫자와 항상 일치합니다.
        final int allTimeStars = (data['totalStars'] as num?)?.toInt() ?? 0;
        final List<dynamic> sessionHistory =
            (data['sessionHistory'] as List<dynamic>?) ?? [];

        String? lastSubject;
        int lastDurationMinutes = 0;
        if (sessionHistory.isNotEmpty) {
          try {
            final Map<String, dynamic> last = Map<String, dynamic>.from(
              sessionHistory.last as Map,
            );
            lastSubject = last['subject'] as String?;
            final int durationSeconds =
                (last['durationSeconds'] as num?)?.toInt() ?? 0;
            lastDurationMinutes = (durationSeconds / 60).round();
          } catch (_) {
            // 손상된 마지막 기록 1건은 건너뜀 - 화면은 "학습 기록 없음" 상태로 정상 표시됨
          }
        }

        return ParentLiveStatusWidget(
          childName: childName,
          isStudyingNow: showAsStudying,
          liveSubject: liveSubject,
          liveElapsedSeconds: liveElapsedSeconds,
          liveTotalSeconds: liveTotalSeconds,
          lastSessionSubject: lastSubject,
          lastSessionDurationMinutes: lastDurationMinutes,
          totalCollectedStars: totalStars,
          allTimeTotalStars: allTimeStars,
          isMonitoringActive: _isMonitoringActive,
          monitoringCountdown: _monitoringCountdown,
          premiumCardBg: premiumCardBg,
          brandGolden: brandGolden,
          luxuryDarkBg: luxuryDarkBg,
          lastSentTimeText: _lastSentTimeText,
          buildCustomSectionTitle: _buildCustomSectionTitle,
          onSendEmojiMessage: _handleSendEmojiMessage,
          onSendCustomMessage: _handleSendCustomMessage,
          onStartMonitoring: _handleStartMonitoring,
        );
      },
    );
  }

  // 🆕 [정리] 기존에 IndexedStack 안에 인라인으로 있던 콜백들을 재사용 가능하도록 메서드로 분리
  // (로컬 모드/Firestore 모드 양쪽에서 동일한 콜백을 그대로 씁니다 - 동작 변경 없음)
  // 🆕 [부모-자녀 응원 시스템 2026-09-04] 실제로 학생 기기에 도달하도록, 선택된 자녀의
  // Firestore 문서에 이모지를 전송합니다. 부모 화면의 스낵바는 "전송 확인" 용도로 유지합니다.
  void _handleSendEmojiMessage(String emoji, String message) {
    if (_selectedChildCode != null) {
      FamilyLinkService.pushEmojiToChild(
        _selectedChildCode!,
        emoji: emoji,
        message: message,
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: premiumCardBg,
        content: Text(
          "${_t(kEmojiSentMap)}\n($message)",
          style: GoogleFonts.notoSansKr(
            color: brandGolden,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 🆕 [부모-자녀 응원 시스템 2026-09-04] 실제로 학생 기기에 도달하도록, 선택된 자녀의
  // Firestore 문서에 응원 문구를 전송합니다 (학생 화면에 팝업으로 표시, 답장 없음).
  void _handleSendCustomMessage(String customText) {
    final now = DateTime.now();
    final hourText = now.hour < 10 ? '0${now.hour}' : '${now.hour}';
    final minText = now.minute < 10 ? '0${now.minute}' : '${now.minute}';

    setState(() {
      _lastSentTimeText = "$hourText:$minText";
    });

    if (_selectedChildCode != null) {
      FamilyLinkService.pushEncouragementToChild(
        _selectedChildCode!,
        message: customText,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF040B19),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          side: BorderSide(color: brandGolden, width: 1),
        ),
        duration: const Duration(seconds: 4),
        content: Text(
          "${_t(kForceInterventionMap)}\n${_t(kMessageContentLabelMap)}: \"$customText\"",
          style: GoogleFonts.notoSansKr(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _handleStartMonitoring() {
    setState(() {
      _isMonitoringActive = true;
      _monitoringCountdown = 60;
    });
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isMonitoringActive) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_monitoringCountdown > 1) {
          _monitoringCountdown--;
        } else {
          _isMonitoringActive = false;
          timer.cancel();
          _showMonitorTimeoutSnackbar();
        }
      });
    });
  }

  @override
  void dispose() {
    _timeTabController.dispose();
    _addChildCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: luxuryDarkBg,
        body: const Center(
          child: CircularProgressIndicator(color: brandGolden),
        ),
      );
    }

    return Scaffold(
      backgroundColor: luxuryDarkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 78,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 14.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/gsu_logo.png',
                width: 180,
                height: 24,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) =>
                const SizedBox(height: 24),
              ),
              const SizedBox(height: 1.0),
              Text(
                'PARENT GKE STUDYUP',
                textAlign: TextAlign.center,
                style: GoogleFonts.gowunBatang(
                  color: brandGolden,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // 🆕 [2026-09-23] 로그아웃(왼쪽) / 회원 연동(오른쪽) - 제목 아래로 이동 (로고 겹침 해소)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: _buildTopPillButton(
                    icon: Icons.logout_rounded,
                    label: _bi(kLogoutLabelMap),
                    onTap: _confirmLogout,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: _buildTopPillButton(
                    icon: _isVipMember ? null : Icons.link_rounded,
                    label: _isVipMember ? _t(kVipBadgeMap) : _bi(kVipLinkMap),
                    filled: _isVipMember,
                    onTap: () => setState(() => _isVipMember = true),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: _kTopSectionGap),
          _buildLinkedChildrenBar(), // 🆕 [자녀 추가] 상단에 항상 표시되는 연결된 자녀 명단 + 추가 버튼
          const SizedBox(height: _kTopSectionGap),
          // 🆕 [2026-09-23] 공지 및 교육상담(왼쪽) / 언어 선택(오른쪽)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: _buildTopPillButton(
                    icon: Icons.campaign_rounded,
                    label: _bi(kNoticeCounselMap),
                    onTap: _showNoticeComingSoon,
                  ),
                ),
                const SizedBox(width: 10),
                _buildTopPillButton(
                  icon: Icons.language_rounded,
                  label: _languageDisplayName(DkeLang.current),
                  onTap: _showLanguagePicker,
                ),
              ],
            ),
          ),
          const SizedBox(height: _kTopSectionGap),

          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                // 🆕 [자녀 선택 UI + Firestore 연동] 자녀가 선택되어 있으면 해당 자녀의 Firestore
                // 데이터를, 없으면(단일기기 사용자) 기존처럼 로컬 데이터를 보여줌
                _buildLiveStatusTabContent(),

                // 🆕 [자녀 선택 UI + Firestore 연동] 상세보기/평가분석 탭 - 자녀가 선택되어 있으면
                // 해당 자녀의 Firestore 데이터를, 없으면(단일기기 사용자) 기존처럼 로컬 데이터를 보여줌
                _buildDetailedAnalysisTabContent(),

                _buildEvaluationAnalysisTabContent(),

                // 🆕 [성적 관리] 4번째 탭 - 자녀가 선택되어 있으면 Firestore 데이터를,
                // 없으면(단일기기 사용자) 기존처럼 로컬 데이터를 보여줌
                _buildGradeManagementTabContent(),

                // 🆕 [장학금 방 2026-09-17] 5번째 탭
                _buildScholarshipTabContent(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        // 🆕 [성적 관리] 4번째 탭 추가로 인해 명시 - 기본 shifting 애니메이션/색상 변경 방지, 기존 3탭과 동일한 스타일 유지
        currentIndex: _currentIndex,
        backgroundColor: premiumCardBg,
        selectedItemColor: brandGolden,
        unselectedItemColor: Colors.white38,
        selectedLabelStyle: GoogleFonts.notoSansKr(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.notoSansKr(fontSize: 11),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.bolt_rounded),
            label: _bi(kTabLiveStatusMap),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assignment_rounded),
            label: _bi(kTabDetailedMap),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.analytics_rounded),
            label: _bi(kTabEvaluationMap),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.grading_rounded),
            label: _bi(kTabGradeMap),
          ), // 🆕 4번째 탭
          BottomNavigationBarItem(
            icon: const Icon(Icons.card_giftcard_rounded),
            label: _bi(kTabScholarshipMap),
          ), // 🆕 5번째 탭 - 장학금
        ],
      ),
    );
  }
}
