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
import '../global_lang.dart';

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

const Map<String, String> kVipLinkMap = {'KO': '회원 연동', 'EN': 'Link Account', 'JA': '会員連携', 'ZH': '会员关联', 'FR': 'Lier le compte', 'DE': 'Konto verknüpfen', 'RU': 'Связать аккаунт', 'AR': 'ربط الحساب', 'HI': 'खाता लिंक करें', 'VI': 'Liên kết TK', 'ES': 'Vincular cuenta', 'TH': 'เชื่อมบัญชี'};
const Map<String, String> kVipBadgeMap = {'KO': '👑 VIP', 'EN': '👑 VIP', 'JA': '👑 VIP', 'ZH': '👑 VIP', 'FR': '👑 VIP', 'DE': '👑 VIP', 'RU': '👑 VIP', 'AR': '👑 VIP', 'HI': '👑 VIP', 'VI': '👑 VIP', 'ES': '👑 VIP', 'TH': '👑 VIP'};

const Map<String, String> kEmojiSentMap = {
  'KO': '자녀의 타이머 세션 상단에 격려 팝업 발송 완료 ☆', 'EN': 'Encouragement popup sent to the top of your child\'s timer session ☆',
  'JA': 'お子様のタイマーセッション上部に応援ポップアップを送信しました ☆', 'ZH': '已在孩子的计时会话顶部发送鼓励弹窗 ☆',
  'FR': 'Pop-up d\'encouragement envoyé en haut de la session minuteur de votre enfant ☆', 'DE': 'Ermutigungs-Popup oben in der Timer-Sitzung Ihres Kindes gesendet ☆',
  'RU': 'Всплывающее сообщение поддержки отправлено в начало сеанса таймера ребёнка ☆', 'AR': 'تم إرسال نافذة تشجيع أعلى جلسة المؤقت لطفلك ☆',
  'HI': 'आपके बच्चे के टाइमर सत्र के शीर्ष पर प्रोत्साहन पॉपअप भेजा गया ☆', 'VI': 'Đã gửi thông báo động viên lên đầu phiên hẹn giờ của con ☆',
  'ES': 'Ventana de ánimo enviada a la parte superior de la sesión del temporizador de su hijo/a ☆', 'TH': 'ส่งป๊อปอัปให้กำลังใจไปด้านบนของเซสชันจับเวลาของบุตรหลานแล้ว ☆',
};
const Map<String, String> kForceInterventionMap = {
  'KO': '👑 [강제 개입] 자녀 타이머 점유 완료 (답장차단 모달 제어 중)', 'EN': '👑 [Override] Child\'s timer taken over (reply-blocking modal active)',
  'JA': '👑 [強制介入] お子様のタイマーを占有しました（返信ブロックモーダル制御中）', 'ZH': '👑 [强制介入] 已占用孩子的计时器（回复屏蔽弹窗控制中）',
  'FR': '👑 [Intervention forcée] Minuteur de l\'enfant repris (fenêtre modale de blocage active)', 'DE': '👑 [Zwangseingriff] Timer des Kindes übernommen (Antwortsperr-Modal aktiv)',
  'RU': '👑 [Принудительное вмешательство] Таймер ребёнка перехвачен (модальное окно блокировки ответа активно)', 'AR': '👑 [تدخل إجباري] تم الاستحواذ على مؤقت الطفل (نافذة حظر الرد نشطة)',
  'HI': '👑 [जबरन हस्तक्षेप] बच्चे का टाइमर अधिग्रहित (उत्तर-अवरोधक मोडल सक्रिय)', 'VI': '👑 [Can thiệp bắt buộc] Đã chiếm quyền hẹn giờ của con (hộp thoại chặn phản hồi đang hoạt động)',
  'ES': '👑 [Intervención forzada] Temporizador del hijo/a tomado (modal de bloqueo de respuesta activo)', 'TH': '👑 [แทรกแซงบังคับ] เข้าควบคุมตัวจับเวลาของบุตรหลานแล้ว (โมดัลบล็อกการตอบกลับทำงานอยู่)',
};
const Map<String, String> kMessageContentLabelMap = {'KO': '내용', 'EN': 'Message', 'JA': '内容', 'ZH': '内容', 'FR': 'Message', 'DE': 'Nachricht', 'RU': 'Сообщение', 'AR': 'الرسالة', 'HI': 'संदेश', 'VI': 'Nội dung', 'ES': 'Mensaje', 'TH': 'ข้อความ'};

const Map<String, String> kMonitorTimeoutMap = {
  'KO': '1분 경과로 인한 automatic 블로킹 활성화 (종료됨)', 'EN': 'Automatic blocking activated after 1 minute elapsed (ended)',
  'JA': '1分経過による自動ブロックが有効化されました（終了）', 'ZH': '经过1分钟后自动屏蔽已启用（已结束）',
  'FR': 'Blocage automatique activé après 1 minute (terminé)', 'DE': 'Automatische Blockierung nach 1 Minute aktiviert (beendet)',
  'RU': 'Автоматическая блокировка активирована через 1 минуту (завершено)', 'AR': 'تم تفعيل الحظر التلقائي بعد مرور دقيقة واحدة (انتهى)',
  'HI': '1 मिनट बीतने पर स्वचालित ब्लॉकिंग सक्रिय (समाप्त)', 'VI': 'Đã kích hoạt chặn tự động sau 1 phút (đã kết thúc)',
  'ES': 'Bloqueo automático activado tras 1 minuto (finalizado)', 'TH': 'เปิดใช้งานการบล็อกอัตโนมัติหลังผ่านไป 1 นาที (สิ้นสุดแล้ว)',
};

const Map<String, String> kNoSessionTodayMap = {
  'KO': '오늘 아직 기록된 학습 세션이 없습니다. 자녀가 학습을 마치고 기록을 저장하면 이곳에 요약이 표시됩니다.',
  'EN': "No study sessions recorded yet today. Once your child finishes studying and saves a record, a summary will appear here.",
  'JA': '本日はまだ記録された学習セッションがありません。お子様が学習を終えて記録を保存すると、ここに要約が表示されます。',
  'ZH': '今天尚无学习会话记录。孩子完成学习并保存记录后，摘要将显示在此处。',
  'FR': "Aucune session d'étude enregistrée aujourd'hui. Un résumé apparaîtra ici une fois que votre enfant aura terminé et enregistré une session.",
  'DE': 'Heute wurden noch keine Lernsitzungen aufgezeichnet. Sobald Ihr Kind eine Sitzung speichert, erscheint hier eine Zusammenfassung.',
  'RU': 'Сегодня пока не записано ни одного учебного занятия. После того как ребёнок закончит и сохранит запись, здесь появится сводка.',
  'AR': 'لا توجد جلسات دراسية مسجلة اليوم بعد. بمجرد أن ينتهي طفلك من الدراسة ويحفظ سجلاً، سيظهر الملخص هنا.',
  'HI': 'आज तक कोई अध्ययन सत्र दर्ज नहीं हुआ है। जैसे ही आपका बच्चा पढ़ाई पूरी कर रिकॉर्ड सहेजेगा, सारांश यहाँ दिखाई देगा।',
  'VI': 'Hôm nay chưa có phiên học nào được ghi lại. Khi con bạn học xong và lưu hồ sơ, bản tóm tắt sẽ hiển thị tại đây.',
  'ES': 'Aún no se ha registrado ninguna sesión de estudio hoy. Cuando su hijo/a termine y guarde un registro, aparecerá aquí un resumen.',
  'TH': 'วันนี้ยังไม่มีการบันทึกเซสชันการเรียน เมื่อบุตรหลานเรียนเสร็จและบันทึกข้อมูลแล้ว บทสรุปจะแสดงที่นี่',
};
const Map<String, String> kReportHeaderMap = {'KO': '[종합 리포트]', 'EN': '[Overall Report]', 'JA': '[総合レポート]', 'ZH': '[综合报告]', 'FR': '[Rapport global]', 'DE': '[Gesamtbericht]', 'RU': '[Общий отчёт]', 'AR': '[التقرير الشامل]', 'HI': '[समग्र रिपोर्ट]', 'VI': '[Báo cáo tổng hợp]', 'ES': '[Informe general]', 'TH': '[รายงานสรุป]'};
const Map<String, String> kPeriodWordMap = {'KO': '교시', 'EN': 'Period', 'JA': '時限', 'ZH': '节', 'FR': 'Séance', 'DE': 'Einheit', 'RU': 'Занятие', 'AR': 'حصة', 'HI': 'पीरियड', 'VI': 'Tiết', 'ES': 'Sesión', 'TH': 'คาบ'};
const Map<String, String> kFocusCompletedMap = {'KO': '분 집중완료', 'EN': 'min focused', 'JA': '分 集中完了', 'ZH': '分钟 专注完成', 'FR': 'min de concentration terminées', 'DE': 'Min. fokussiert', 'RU': 'мин сосредоточенности', 'AR': 'دقيقة تركيز مكتمل', 'HI': 'मिनट फोकस पूर्ण', 'VI': 'phút tập trung hoàn thành', 'ES': 'min de concentración', 'TH': 'นาที โฟกัสสำเร็จ'};
const Map<String, String> kScoreLabelMap = {'KO': '점수', 'EN': 'Score', 'JA': '点数', 'ZH': '分数', 'FR': 'Score', 'DE': 'Punktzahl', 'RU': 'Балл', 'AR': 'الدرجة', 'HI': 'स्कोर', 'VI': 'Điểm', 'ES': 'Puntuación', 'TH': 'คะแนน'};
const Map<String, String> kTodayTotalTimeMap = {'KO': '오늘 총 학습시간', 'EN': "Today's Total Study Time", 'JA': '本日の総学習時間', 'ZH': '今日总学习时间', 'FR': "Temps d'étude total aujourd'hui", 'DE': 'Heutige Gesamtlernzeit', 'RU': 'Общее время учёбы сегодня', 'AR': 'إجمالي وقت الدراسة اليوم', 'HI': 'आज कुल अध्ययन समय', 'VI': 'Tổng thời gian học hôm nay', 'ES': 'Tiempo total de estudio de hoy', 'TH': 'เวลาเรียนรวมวันนี้'};
const Map<String, String> kMinutesUnitMap = {'KO': '분', 'EN': 'min', 'JA': '分', 'ZH': '分钟', 'FR': 'min', 'DE': 'Min.', 'RU': 'мин', 'AR': 'دقيقة', 'HI': 'मिनट', 'VI': 'phút', 'ES': 'min', 'TH': 'นาที'};
const Map<String, String> kTodaySummaryHeaderMap = {'KO': '[오늘의 종합 분석]', 'EN': "[Today's Overall Analysis]", 'JA': '[本日の総合分析]', 'ZH': '[今日综合分析]', 'FR': "[Analyse globale du jour]", 'DE': '[Heutige Gesamtanalyse]', 'RU': '[Общий анализ за сегодня]', 'AR': '[التحليل الشامل لليوم]', 'HI': '[आज का समग्र विश्लेषण]', 'VI': '[Phân tích tổng hợp hôm nay]', 'ES': '[Análisis general de hoy]', 'TH': '[การวิเคราะห์โดยรวมวันนี้]'};

const Map<String, String> kNoDetailTodayMap = {
  'KO': '오늘 상세 분석할 학습 기록이 아직 없습니다.', 'EN': "No study records available for detailed analysis today.",
  'JA': '本日、詳細分析できる学習記録がまだありません。', 'ZH': '今天尚无可供详细分析的学习记录。',
  'FR': "Aucun enregistrement d'étude disponible pour une analyse détaillée aujourd'hui.", 'DE': 'Heute liegen noch keine Lernaufzeichnungen für eine detaillierte Analyse vor.',
  'RU': 'Сегодня пока нет учебных записей для подробного анализа.', 'AR': 'لا توجد سجلات دراسية متاحة للتحليل التفصيلي اليوم.',
  'HI': 'आज विस्तृत विश्लेषण के लिए कोई अध्ययन रिकॉर्ड उपलब्ध नहीं है।', 'VI': 'Hôm nay chưa có hồ sơ học tập nào để phân tích chi tiết.',
  'ES': 'Hoy no hay registros de estudio disponibles para un análisis detallado.', 'TH': 'วันนี้ยังไม่มีบันทึกการเรียนสำหรับการวิเคราะห์เชิงลึก',
};
const Map<String, String> kDetailHeaderMap = {'KO': '[상세분석기록 - 오늘 학습한 모든 세션]', 'EN': '[Detailed Records - All Sessions Today]', 'JA': '[詳細分析記録 - 本日の全セッション]', 'ZH': '[详细分析记录 - 今日全部会话]', 'FR': "[Analyse détaillée - Toutes les sessions du jour]", 'DE': '[Detaillierte Aufzeichnung - Alle heutigen Sitzungen]', 'RU': '[Подробная запись - все занятия за сегодня]', 'AR': '[سجل تفصيلي - جميع جلسات اليوم]', 'HI': '[विस्तृत रिकॉर्ड - आज के सभी सत्र]', 'VI': '[Hồ sơ chi tiết - Tất cả phiên học hôm nay]', 'ES': '[Registro detallado - Todas las sesiones de hoy]', 'TH': '[บันทึกเชิงลึก - ทุกเซสชันวันนี้]'};
const Map<String, String> kDetailContentLabelMap = {'KO': '상세내용', 'EN': 'Details', 'JA': '詳細内容', 'ZH': '详细内容', 'FR': 'Détails', 'DE': 'Details', 'RU': 'Подробности', 'AR': 'التفاصيل', 'HI': 'विवरण', 'VI': 'Chi tiết', 'ES': 'Detalles', 'TH': 'รายละเอียด'};
const Map<String, String> kNoRecordMap = {'KO': '기록 없음', 'EN': 'No record', 'JA': '記録なし', 'ZH': '无记录', 'FR': 'Aucun enregistrement', 'DE': 'Keine Aufzeichnung', 'RU': 'Нет записи', 'AR': 'لا يوجد سجل', 'HI': 'कोई रिकॉर्ड नहीं', 'VI': 'Không có', 'ES': 'Sin registro', 'TH': 'ไม่มีบันทึก'};
const Map<String, String> kUnderstandingLabelMap = {'KO': '이해도', 'EN': 'Understanding', 'JA': '理解度', 'ZH': '理解度', 'FR': 'Compréhension', 'DE': 'Verständnis', 'RU': 'Понимание', 'AR': 'مستوى الفهم', 'HI': 'समझ', 'VI': 'Mức hiểu', 'ES': 'Comprensión', 'TH': 'ความเข้าใจ'};
const Map<String, String> kDifficultyLabelMap = {'KO': '난이도', 'EN': 'Difficulty', 'JA': '難易度', 'ZH': '难度', 'FR': 'Difficulté', 'DE': 'Schwierigkeit', 'RU': 'Сложность', 'AR': 'الصعوبة', 'HI': 'कठिनाई', 'VI': 'Độ khó', 'ES': 'Dificultad', 'TH': 'ความยาก'};
const Map<String, String> kConcentrationLabelMap = {'KO': '집중도', 'EN': 'Concentration', 'JA': '集中度', 'ZH': '专注度', 'FR': 'Concentration', 'DE': 'Konzentration', 'RU': 'Концентрация', 'AR': 'التركيز', 'HI': 'एकाग्रता', 'VI': 'Mức tập trung', 'ES': 'Concentración', 'TH': 'สมาธิ'};
const Map<String, String> kConditionLabelMap = {'KO': '학습컨디션', 'EN': 'Condition', 'JA': '学習コンディション', 'ZH': '学习状态', 'FR': "État d'étude", 'DE': 'Lernzustand', 'RU': 'Состояние', 'AR': 'حالة الدراسة', 'HI': 'अध्ययन स्थिति', 'VI': 'Tình trạng học', 'ES': 'Estado de estudio', 'TH': 'สภาพการเรียน'};
const Map<String, String> kIncorrectNoteLabelMap = {'KO': '오답정리', 'EN': 'Error Review', 'JA': '誤答整理', 'ZH': '错题整理', 'FR': "Révision des erreurs", 'DE': 'Fehlerüberprüfung', 'RU': 'Разбор ошибок', 'AR': 'مراجعة الأخطاء', 'HI': 'त्रुटि समीक्षा', 'VI': 'Xem lại lỗi sai', 'ES': 'Revisión de errores', 'TH': 'ทบทวนข้อผิดพลาด'};
const Map<String, String> kNextGoalLabelMap = {'KO': '다음목표', 'EN': 'Next Goal', 'JA': '次の目標', 'ZH': '下一目标', 'FR': 'Prochain objectif', 'DE': 'Nächstes Ziel', 'RU': 'Следующая цель', 'AR': 'الهدف التالي', 'HI': 'अगला लक्ष्य', 'VI': 'Mục tiêu tiếp theo', 'ES': 'Próximo objetivo', 'TH': 'เป้าหมายถัดไป'};

const Map<String, String> kRecordTypeLectureMap = {'KO': '강의', 'EN': 'Lecture', 'JA': '講義', 'ZH': '讲课', 'FR': 'Cours', 'DE': 'Vorlesung', 'RU': 'Лекция', 'AR': 'محاضرة', 'HI': 'व्याख्यान', 'VI': 'Bài giảng', 'ES': 'Clase', 'TH': 'บรรยาย'};
const Map<String, String> kRecordTypeEvalMap = {'KO': '평가', 'EN': 'Evaluation', 'JA': '評価', 'ZH': '评估', 'FR': 'Évaluation', 'DE': 'Bewertung', 'RU': 'Оценка', 'AR': 'تقييم', 'HI': 'मूल्यांकन', 'VI': 'Đánh giá', 'ES': 'Evaluación', 'TH': 'การประเมิน'};
String _recordTypeLabel(String koType) => _t(koType == '평가' ? kRecordTypeEvalMap : kRecordTypeLectureMap);

const Map<String, String> kTodayOverallReportTitleMap = {'KO': '오늘 종합 리포트 조회', 'EN': "Today's Overall Report", 'JA': '本日の総合レポート照会', 'ZH': '今日综合报告查询', 'FR': "Rapport global du jour", 'DE': 'Heutiger Gesamtbericht', 'RU': 'Общий отчёт за сегодня', 'AR': 'عرض التقرير الشامل لليوم', 'HI': 'आज की समग्र रिपोर्ट', 'VI': 'Xem báo cáo tổng hợp hôm nay', 'ES': 'Informe general de hoy', 'TH': 'ดูรายงานสรุปวันนี้'};
const Map<String, String> kTodayDetailReportTitleMap = {'KO': '오늘 상세 분석기록 조회', 'EN': "Today's Detailed Analysis", 'JA': '本日の詳細分析記録照会', 'ZH': '今日详细分析记录查询', 'FR': "Analyse détaillée du jour", 'DE': 'Heutige detaillierte Analyse', 'RU': 'Подробный анализ за сегодня', 'AR': 'عرض سجل التحليل التفصيلي لليوم', 'HI': 'आज का विस्तृत विश्लेषण रिकॉर्ड', 'VI': 'Xem hồ sơ phân tích chi tiết hôm nay', 'ES': 'Análisis detallado de hoy', 'TH': 'ดูบันทึกวิเคราะห์เชิงลึกวันนี้'};
const Map<String, String> kDiagReportTitleMap = {'KO': '👑 오늘의 교육성취 정밀 진단서', 'EN': '👑 Today\'s Precision Achievement Report', 'JA': '👑 本日の教育成果精密診断書', 'ZH': '👑 今日教育成果精密诊断报告', 'FR': "👑 Rapport de diagnostic de réussite du jour", 'DE': '👑 Heutiger Leistungsdiagnosebericht', 'RU': '👑 Сегодняшний отчёт по диагностике успеваемости', 'AR': '👑 تقرير تشخيص التحصيل الدراسي لليوم', 'HI': '👑 आज की उपलब्धि निदान रिपोर्ट', 'VI': '👑 Báo cáo chẩn đoán thành tích hôm nay', 'ES': '👑 Informe de diagnóstico de logros de hoy', 'TH': '👑 รายงานวินิจฉัยผลสัมฤทธิ์วันนี้'};
const Map<String, String> kNoExamDataMap = {
  'KO': '아직 기록된 평가 데이터가 없습니다. 평가가 기록되면 정밀 분석 리포트가 제공됩니다.',
  'EN': 'No evaluation data recorded yet. A detailed analysis report will be provided once evaluations are recorded.',
  'JA': 'まだ記録された評価データがありません。評価が記録されると精密分析レポートが提供されます。',
  'ZH': '尚无已记录的评估数据。评估记录后将提供精密分析报告。',
  'FR': "Aucune donnée d'évaluation enregistrée pour le moment. Un rapport d'analyse détaillé sera fourni une fois les évaluations enregistrées.",
  'DE': 'Es liegen noch keine Bewertungsdaten vor. Sobald Bewertungen erfasst sind, wird ein detaillierter Analysebericht bereitgestellt.',
  'RU': 'Данные оценивания ещё не записаны. Подробный аналитический отчёт будет предоставлен после записи оценок.',
  'AR': 'لا توجد بيانات تقييم مسجلة بعد. سيتم تقديم تقرير تحليل دقيق بمجرد تسجيل التقييمات.',
  'HI': 'अभी तक कोई मूल्यांकन डेटा दर्ज नहीं है। मूल्यांकन दर्ज होते ही विस्तृत विश्लेषण रिपोर्ट प्रदान की जाएगी।',
  'VI': 'Chưa có dữ liệu đánh giá nào được ghi lại. Báo cáo phân tích chi tiết sẽ được cung cấp khi có đánh giá được ghi nhận.',
  'ES': 'Aún no se han registrado datos de evaluación. Se proporcionará un informe de análisis detallado una vez registradas las evaluaciones.',
  'TH': 'ยังไม่มีข้อมูลการประเมินที่บันทึกไว้ รายงานวิเคราะห์เชิงลึกจะถูกจัดเตรียมเมื่อมีการบันทึกผลประเมิน',
};

const Map<String, String> kTabLiveStatusMap = {'KO': '실시간 현황', 'EN': 'Live Status', 'JA': 'リアルタイム状況', 'ZH': '实时状况', 'FR': 'État en direct', 'DE': 'Live-Status', 'RU': 'В реальном времени', 'AR': 'الحالة المباشرة', 'HI': 'लाइव स्थिति', 'VI': 'Trạng thái trực tiếp', 'ES': 'Estado en vivo', 'TH': 'สถานะเรียลไทม์'};
const Map<String, String> kTabDetailedMap = {'KO': '상세 보기', 'EN': 'Detailed View', 'JA': '詳細表示', 'ZH': '详细查看', 'FR': 'Vue détaillée', 'DE': 'Detailansicht', 'RU': 'Подробный просмотр', 'AR': 'عرض تفصيلي', 'HI': 'विस्तृत दृश्य', 'VI': 'Xem chi tiết', 'ES': 'Vista detallada', 'TH': 'ดูรายละเอียด'};
const Map<String, String> kTabEvaluationMap = {'KO': '평가 분석', 'EN': 'Evaluation Analysis', 'JA': '評価分析', 'ZH': '评估分析', 'FR': 'Analyse des évaluations', 'DE': 'Bewertungsanalyse', 'RU': 'Анализ оценок', 'AR': 'تحليل التقييم', 'HI': 'मूल्यांकन विश्लेषण', 'VI': 'Phân tích đánh giá', 'ES': 'Análisis de evaluación', 'TH': 'วิเคราะห์การประเมิน'};
const Map<String, String> kTabGradeMap = {'KO': '성적 관리', 'EN': 'Grade Mgmt', 'JA': '成績管理', 'ZH': '成绩管理', 'FR': 'Gestion des notes', 'DE': 'Notenverwaltung', 'RU': 'Управление оценками', 'AR': 'إدارة الدرجات', 'HI': 'ग्रेड प्रबंधन', 'VI': 'Quản lý điểm', 'ES': 'Gestión de notas', 'TH': 'จัดการเกรด'};
const Map<String, String> kAvgWordMap = {'KO': '평균', 'EN': 'Avg', 'JA': '平均', 'ZH': '平均', 'FR': 'Moy.', 'DE': 'Ø', 'RU': 'Средн.', 'AR': 'المعدل', 'HI': 'औसत', 'VI': 'TB', 'ES': 'Prom.', 'TH': 'เฉลี่ย'};

class ParentMainDashboardScreen extends StatefulWidget {
  final String parentEmail;
  final String childName;

  const ParentMainDashboardScreen({
    Key? key,
    required this.parentEmail,
    this.childName = "학습자",
  }) : super(key: key);

  @override
  _ParentMainDashboardScreenState createState() => _ParentMainDashboardScreenState();
}

class _ParentMainDashboardScreenState extends State<ParentMainDashboardScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
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

  bool _isSameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  bool get _isViewingToday => _isSameDate(_detailedViewDate, DateTime.now());

  List<ParentSessionRecord> get _sessionsForDetailedDate =>
      _allSessions.where((r) => _isSameDate(r.timestamp, _detailedViewDate)).toList();

  int get _detailedDayTotalMinutes {
    final d = DateTime(_detailedViewDate.year, _detailedViewDate.month, _detailedViewDate.day);
    return ParentDataService.totalMinutesForDay(_allSessions, d);
  }

  int get _detailedDayBeforeMinutes {
    final d = DateTime(_detailedViewDate.year, _detailedViewDate.month, _detailedViewDate.day).subtract(const Duration(days: 1));
    return ParentDataService.totalMinutesForDay(_allSessions, d);
  }

  // 🆕 조회 중인 날짜 이전 7일(해당 날짜 제외)의 학습분 평균 - 기존 "오늘 vs 1주 평균" 로직을
  // 선택된 날짜 기준으로 그대로 이동
  int get _detailedWeeklyAvgMinutes {
    final base = DateTime(_detailedViewDate.year, _detailedViewDate.month, _detailedViewDate.day);
    int total = 0;
    for (int i = 1; i <= 7; i++) {
      total += ParentDataService.totalMinutesForDay(_allSessions, base.subtract(Duration(days: i)));
    }
    return (total / 7).round();
  }

  void _goToPreviousDetailDay() {
    setState(() => _detailedViewDate = _detailedViewDate.subtract(const Duration(days: 1)));
  }

  void _goToNextDetailDay() {
    if (_isViewingToday) return; // 🆕 미래 날짜 조회 방지
    setState(() => _detailedViewDate = _detailedViewDate.add(const Duration(days: 1)));
  }

  @override
  void initState() {
    super.initState();
    _timeTabController = TabController(length: 4, vsync: this);
    _timeTabController.addListener(() { if (!_timeTabController.indexIsChanging) setState(() {}); });
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
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: premiumCardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('자녀 추가', style: GoogleFonts.notoSansKr(color: brandGolden, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('자녀에게 받은 6자리 연결 코드를 입력하세요',
                    style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 12),
                TextField(
                  controller: _addChildCodeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSans(color: Colors.white, fontSize: 22, letterSpacing: 4),
                  decoration: InputDecoration(
                    counterText: '',
                    errorText: errorText,
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: brandGolden.withValues(alpha: 0.4))),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: brandGolden)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('취소', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: brandGolden),
                onPressed: () async {
                  final code = _addChildCodeController.text.trim();
                  if (code.length != 6) {
                    setDialogState(() => errorText = '6자리 숫자를 입력하세요');
                    return;
                  }
                  final bool ok = await FamilyLinkService.connectWithCode(code);
                  if (ok) {
                    if (context.mounted) Navigator.pop(dialogContext);
                    await _loadLinkedChildren();
                  } else {
                    setDialogState(() => errorText = '존재하지 않는 코드이거나 이미 5명이 연결되었습니다');
                  }
                },
                child: const Text('연결하기', style: TextStyle(color: Color(0xFF030712), fontWeight: FontWeight.bold)),
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
        height: 78,
        child: Center(child: CircularProgressIndicator(color: brandGolden, strokeWidth: 2)),
      );
    }
    return SizedBox(
      height: 78,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        children: [
          ..._linkedChildCodes.map((code) => _buildChildChip(code)),
          if (_linkedChildCodes.length < FamilyLinkService.maxChildren) _buildAddChildChip(),
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
          return Container(
            width: 130,
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? brandGolden.withValues(alpha: 0.15) : premiumCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: brandGolden.withValues(alpha: isSelected ? 1.0 : 0.4), width: isSelected ? 1.6 : 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  studentName != null && studentName.isNotEmpty ? studentName : '코드 $code',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSansKr(color: isSelected ? brandGolden : Colors.white38, fontSize: isSelected ? 11 : 9, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                ),
                const SizedBox(height: 4),
                Text(
                  totalStars != null ? '⭐ $totalStars개' : '데이터 없음',
                  style: GoogleFonts.notoSansKr(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (level != null)
                  Text('레벨 $level', style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddChildChip() {
    return GestureDetector(
      onTap: _showAddChildDialog,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: brandGolden.withValues(alpha: 0.6), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, color: brandGolden, size: 22),
            const SizedBox(height: 4),
            Text('자녀 추가', style: GoogleFonts.notoSansKr(color: brandGolden, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // 🆕 [실데이터 연동] ParentDataService를 통해 학생의 실제 학습 데이터를 불러옵니다.
  Future<void> _loadRealData() async {
    try {
      final String? realName = await ParentDataService.getStudentName();
      final List<ParentSessionRecord> today = await ParentDataService.loadTodaySessions();
      final List<ParentSessionRecord> all = await ParentDataService.loadAllSessions();
      final List<ParentExamRecord> exams = await ParentDataService.loadExamRecords();
      final List<Map<String, dynamic>> aggregates = await ParentDataService.loadSubjectAggregates();
      final int todayStars = await ParentDataService.getTodayStars();

      final DateTime now = DateTime.now();
      final DateTime todayStart = DateTime(now.year, now.month, now.day);
      final DateTime yesterdayStart = todayStart.subtract(const Duration(days: 1));

      final int todayMinutes = ParentDataService.totalMinutesForDay(all, todayStart);
      final int yesterdayMinutes = ParentDataService.totalMinutesForDay(all, yesterdayStart);

      // 최근 7일(오늘 제외) 총 학습분 / 7 = 일 평균
      int weeklyTotal = 0;
      for (int i = 1; i <= 7; i++) {
        weeklyTotal += ParentDataService.totalMinutesForDay(all, todayStart.subtract(Duration(days: i)));
      }
      final int weeklyAvg = (weeklyTotal / 7).round();

      final Map<String, double> subjectAvgScores = ParentDataService.computeSubjectAverageScores(exams);
      String? strongest;
      String? weakest;
      if (subjectAvgScores.isNotEmpty) {
        final sorted = subjectAvgScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        strongest = "${sorted.first.key} (${_t(kAvgWordMap)} ${sorted.first.value.toStringAsFixed(0)})";
        weakest = "${sorted.last.key} (${_t(kAvgWordMap)} ${sorted.last.value.toStringAsFixed(0)})";
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
  Future<String> _buildSummaryReportText() =>
      _buildSummaryReportTextFor(_realChildName, _todaySessions, _todayTotalMinutes);

  Future<String> _buildSummaryReportTextFor(
      String childName, List<ParentSessionRecord> todaySessions, int todayTotalMinutes) async {
    if (todaySessions.isEmpty) {
      return _biLong(kNoSessionTodayMap);
    }
    final buffer = StringBuffer();
    buffer.writeln("${_t(kReportHeaderMap)}\n");
    for (int i = 0; i < todaySessions.length; i++) {
      final rec = todaySessions[i];
      final String periodLabel = _isNumberFirstLang ? "제${i + 1}${_t(kPeriodWordMap)}" : "${_t(kPeriodWordMap)} ${i + 1}";
      buffer.writeln("$periodLabel · ${rec.subject} · ${rec.durationMinutes}${_t(kMinutesUnitMap)} ${_t(kFocusCompletedMap)}");
      if (rec.recordType == '평가' && rec.score != null) {
        buffer.writeln("  ${_t(kScoreLabelMap)}: ${rec.score}");
      }
    }
    buffer.writeln("\n${_t(kTodayTotalTimeMap)}: $todayTotalMinutes${_t(kMinutesUnitMap)}");

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
  String _buildDetailedAnalysisText() => _buildDetailedAnalysisTextFor(_todaySessions);

  String _buildDetailedAnalysisTextFor(List<ParentSessionRecord> todaySessions) {
    if (todaySessions.isEmpty) {
      return _t(kNoDetailTodayMap);
    }
    final buffer = StringBuffer();
    buffer.writeln("${_t(kDetailHeaderMap)}\n");
    for (int i = 0; i < todaySessions.length; i++) {
      final rec = todaySessions[i];
      final String periodLabel = _isNumberFirstLang ? "제${i + 1}${_t(kPeriodWordMap)}" : "${_t(kPeriodWordMap)} ${i + 1}";
      buffer.writeln("■ $periodLabel · ${rec.subject} (${_recordTypeLabel(rec.recordType)})");
      buffer.writeln("  ${_t(kDetailContentLabelMap)}: ${rec.details.isNotEmpty ? rec.details : _t(kNoRecordMap)}");
      if (rec.recordType == '평가' && rec.score != null) buffer.writeln("  ${_t(kScoreLabelMap)}: ${rec.score}");
      if (rec.understanding != null) buffer.writeln("  ${_t(kUnderstandingLabelMap)}: ${rec.understanding}%");
      if (rec.difficulty != null) buffer.writeln("  ${_t(kDifficultyLabelMap)}: ${rec.difficulty}");
      if (rec.concentration != null) buffer.writeln("  ${_t(kConcentrationLabelMap)}: ${rec.concentration}");
      if (rec.condition != null) buffer.writeln("  ${_t(kConditionLabelMap)}: ${rec.condition}");
      if (rec.incorrectNote != null) buffer.writeln("  ${_t(kIncorrectNoteLabelMap)}: ${rec.incorrectNote}");
      if (rec.nextGoal.isNotEmpty) buffer.writeln("  ${_t(kNextGoalLabelMap)}: ${rec.nextGoal}");
      buffer.writeln();
    }
    return buffer.toString();
  }

  void _showReportPopup(BuildContext context, String mainTitle, String content) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: premiumCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: brandGolden.withValues(alpha: 0.4), width: 1.5),
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
                          style: GoogleFonts.notoSansKr(color: brandGolden, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 16, thickness: 1.2),
                  Text(
                    content,
                    style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13.5, height: 1.6),
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
          style: GoogleFonts.notoSansKr(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // 🆕 [다국어] foreignTitle 파라미터 추가: 자식 위젯(parent_detailed_analysis_widget.dart 등)이
  // 이미 10개국어 대응을 위해 이 파라미터를 요구하는 시그니처로 되어 있어 타입을 맞춰줍니다.
  // 외국어(10개국) 선택 시에는 foreignTitle 한 줄만, 기본모드(KO/EN)는 기존처럼 영문+한글 2줄 표시.
  Widget _buildCustomSectionTitle(String engTitle, String korTitle, {required double fontSize, String? foreignTitle}) {
    if (DkeLang.isForeignSelected && foreignTitle != null && foreignTitle.isNotEmpty) {
      return Text(
        foreignTitle,
        style: GoogleFonts.notoSansKr(color: brandGolden, fontWeight: FontWeight.bold, fontSize: fontSize, height: 1.3),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          engTitle,
          style: GoogleFonts.gowunBatang(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: fontSize - 2.0, height: 1.2),
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
        list.add(ParentSessionRecord.fromJson(Map<String, dynamic>.from(e as Map)));
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
        list.add(ParentExamRecord.fromJson(Map<String, dynamic>.from(e as Map)));
      } catch (_) {}
    }
    return list;
  }

  bool _isSameDateHelper(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  List<ParentSessionRecord> _todaySessionsFrom(List<ParentSessionRecord> all) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return all.where((r) => !r.timestamp.isBefore(start)).toList();
  }

  // 🆕 [자녀 선택 UI + Firestore 연동] ParentDataService.loadSubjectAggregates()와
  // 동일한 집계 로직을 Firestore에서 받아온 세션 리스트에 대해 그대로 적용
  // (로컬 SharedPreferences 대신 이미 메모리에 있는 리스트를 입력으로 받는 순수 함수 버전)
  List<Map<String, dynamic>> _computeSubjectAggregatesFrom(List<ParentSessionRecord> all) {
    final DateTime now = DateTime.now();
    final DateTime todayStart = DateTime(now.year, now.month, now.day);
    final DateTime weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final DateTime monthStart = DateTime(now.year, now.month, 1);
    final DateTime yearStart = DateTime(now.year, 1, 1);

    final Map<String, List<ParentSessionRecord>> bySubject = {};
    for (final r in all) {
      bySubject.putIfAbsent(r.subject, () => []).add(r);
    }

    final List<Map<String, dynamic>> aggregated = [];
    bySubject.forEach((subject, sessions) {
      bool studiedToday = false, studiedWeekly = false, studiedMonthly = false, studiedYearly = false;
      int totalMinutesAllTime = 0;
      final Set<String> activeDayKeys = {};

      for (final s in sessions) {
        final DateTime ts = s.timestamp;
        if (!ts.isBefore(yearStart)) studiedYearly = true;
        if (!ts.isBefore(monthStart)) studiedMonthly = true;
        if (!ts.isBefore(weekStart)) studiedWeekly = true;
        if (!ts.isBefore(todayStart)) studiedToday = true;
        totalMinutesAllTime += s.durationMinutes;
        activeDayKeys.add("${ts.year}-${ts.month}-${ts.day}");
      }

      if (!(studiedToday || studiedWeekly || studiedMonthly || studiedYearly)) return;

      final int activeDays = activeDayKeys.isEmpty ? 1 : activeDayKeys.length;
      final int avgMinutesPerActiveDay = (totalMinutesAllTime / activeDays).round();

      aggregated.add({
        "subject": subject,
        "hasStudiedToday": studiedToday,
        "hasStudiedWeekly": studiedWeekly,
        "hasStudiedMonthly": studiedMonthly,
        "hasStudiedYearly": studiedYearly,
        "baseMinutes": avgMinutesPerActiveDay,
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
        onShowDetailedAnalysisPopup: () => _showReportPopup(context, _t(kTodayDetailReportTitleMap), _buildDetailedAnalysisText()),
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
          return const Center(child: CircularProgressIndicator(color: brandGolden));
        }
        final Map<String, dynamic> data = snapshot.data!.data() ?? {};
        final String childName = (data['studentName'] as String?)?.trim().isNotEmpty == true
            ? (data['studentName'] as String)
            : '학습자';
        final List<ParentSessionRecord> allSessions = _parseSessionHistory(data);
        final List<ParentExamRecord> examRecords = _parseExamRecords(data);

        final DateTime d = DateTime(_detailedViewDate.year, _detailedViewDate.month, _detailedViewDate.day);
        final int todayTotal = ParentDataService.totalMinutesForDay(allSessions, d);
        final int yesterdayTotal = ParentDataService.totalMinutesForDay(allSessions, d.subtract(const Duration(days: 1)));
        int weeklyTotal = 0;
        for (int i = 1; i <= 7; i++) {
          weeklyTotal += ParentDataService.totalMinutesForDay(allSessions, d.subtract(Duration(days: i)));
        }
        final int weeklyAvg = (weeklyTotal / 7).round();

        final Map<String, double> subjectAvgScores = ParentDataService.computeSubjectAverageScores(examRecords);
        String? strongest;
        String? weakest;
        if (subjectAvgScores.isNotEmpty) {
          final sorted = subjectAvgScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          strongest = "${sorted.first.key} (${_t(kAvgWordMap)} ${sorted.first.value.toStringAsFixed(0)})";
          weakest = "${sorted.last.key} (${_t(kAvgWordMap)} ${sorted.last.value.toStringAsFixed(0)})";
        }

        final List<ParentSessionRecord> sessionsForDate =
        allSessions.where((r) => _isSameDateHelper(r.timestamp, _detailedViewDate)).toList();
        final bool isToday = _isSameDateHelper(_detailedViewDate, DateTime.now());

        return ParentDetailedAnalysisWidget(
          childName: childName,
          premiumCardBg: premiumCardBg,
          brandGolden: brandGolden,
          luxuryDarkBg: luxuryDarkBg,
          buildCustomSectionTitle: _buildCustomSectionTitle,
          onShowReportPopup: () async {
            final String content = await _buildSummaryReportTextFor(childName, _todaySessionsFrom(allSessions), todayTotal);
            if (!mounted) return;
            _showReportPopup(context, _t(kTodayOverallReportTitleMap), content);
          },
          onShowDetailedAnalysisPopup: () => _showReportPopup(
              context, _t(kTodayDetailReportTitleMap), _buildDetailedAnalysisTextFor(_todaySessionsFrom(allSessions))),
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
        parentMasterTimeData: _subjectAggregates,
        premiumCardBg: premiumCardBg,
        brandGolden: brandGolden,
        luxuryDarkBg: luxuryDarkBg,
        buildCustomSectionTitle: _buildCustomSectionTitle,
        onEvaluationTypeChanged: (type) => setState(() => _selectedEvaluationType = type),
        onBigUnitChanged: _toggleBigUnit,
        onMidUnitChanged: _toggleMidUnit,
        onYearChanged: (year) => setState(() => _selectedYear = year),
        onMonthChanged: (month) => setState(() => _selectedMonth = month),
        onWeekChanged: (week) => setState(() => _selectedWeek = week),
        onShowDetailAnalysisReport: () async {
          if (_examRecords.isEmpty) {
            _showReportPopup(context, _t(kDiagReportTitleMap), _t(kNoExamDataMap));
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
          return const Center(child: CircularProgressIndicator(color: brandGolden));
        }
        final Map<String, dynamic> data = snapshot.data!.data() ?? {};
        final String childName = (data['studentName'] as String?)?.trim().isNotEmpty == true
            ? (data['studentName'] as String)
            : '학습자';
        final List<ParentSessionRecord> allSessions = _parseSessionHistory(data);
        final List<ParentExamRecord> examRecords = _parseExamRecords(data);
        final List<Map<String, dynamic>> subjectAggregates = _computeSubjectAggregatesFrom(allSessions);

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
          onEvaluationTypeChanged: (type) => setState(() => _selectedEvaluationType = type),
          onBigUnitChanged: _toggleBigUnit,
          onMidUnitChanged: _toggleMidUnit,
          onYearChanged: (year) => setState(() => _selectedYear = year),
          onMonthChanged: (month) => setState(() => _selectedMonth = month),
          onWeekChanged: (week) => setState(() => _selectedWeek = week),
          onShowDetailAnalysisReport: () async {
            if (examRecords.isEmpty) {
              _showReportPopup(context, _t(kDiagReportTitleMap), _t(kNoExamDataMap));
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
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FamilyLinkService.watch(_selectedChildCode!),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !(snapshot.data?.exists ?? false)) {
          return const Center(child: CircularProgressIndicator(color: brandGolden));
        }
        final Map<String, dynamic> data = snapshot.data!.data() ?? {};
        final String childName = (data['studentName'] as String?)?.trim().isNotEmpty == true
            ? (data['studentName'] as String)
            : '학습자';

        final List<dynamic> rawRecords = (data['gradeRecords'] as List<dynamic>?) ?? [];
        final List<GradeRecord> records = [];
        for (final e in rawRecords) {
          try {
            records.add(GradeRecord.fromJson(Map<String, dynamic>.from(e as Map)));
          } catch (_) {}
        }

        final List<dynamic> rawConfigs = (data['gradeConfigs'] as List<dynamic>?) ?? [];
        final List<SubjectConfig> configs = [];
        for (final e in rawConfigs) {
          try {
            configs.add(SubjectConfig.fromJson(Map<String, dynamic>.from(e as Map)));
          } catch (_) {}
        }

        // 🆕 [연동] readAchievementAverageScore()와 동일한 방식(score 필드 평균)으로
        // Firestore의 examRecords 배열에서 계산 - 로컬 전용 함수를 대체하는 순수 계산 버전
        final List<dynamic> rawExamRecords = (data['examRecords'] as List<dynamic>?) ?? [];
        final List<double> scores = [];
        for (final e in rawExamRecords) {
          try {
            final map = Map<String, dynamic>.from(e as Map);
            final double? s = (map['score'] as num?)?.toDouble();
            if (s != null) scores.add(s);
          } catch (_) {}
        }
        final double? achievementAvg = scores.isEmpty ? null : scores.reduce((a, b) => a + b) / scores.length;

        return ParentGradeManagementWidget(
          childName: childName,
          premiumCardBg: premiumCardBg,
          brandGolden: brandGolden,
          luxuryDarkBg: luxuryDarkBg,
          buildCustomSectionTitle: _buildCustomSectionTitle,
          overrideRecords: records,
          overrideConfigs: configs,
          overrideAchievementAverage: achievementAvg,
        );
      },
    );
  }

  // 🆕 [자녀 선택 UI + Firestore 연동] 실시간현황 탭 - 자녀가 선택되어 있으면 해당 자녀의
  // Firestore 문서(links/{code})를 실시간 구독해서 이름/최근세션/별을 보여주고,
  // 연결된 자녀가 없으면(기존 단일기기 사용자) 원래대로 이 기기의 로컬 데이터를 보여줍니다.
  Widget _buildLiveStatusTabContent() {
    if (_selectedChildCode == null) {
      return ParentLiveStatusWidget(
        childName: _realChildName,
        lastSessionSubject: _todaySessions.isNotEmpty ? _todaySessions.last.subject : null,
        lastSessionDurationMinutes: _todaySessions.isNotEmpty ? _todaySessions.last.durationMinutes : 0,
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
          return const Center(child: CircularProgressIndicator(color: brandGolden));
        }
        final Map<String, dynamic> data = snapshot.data!.data() ?? {};
        final String childName = (data['studentName'] as String?)?.trim().isNotEmpty == true
            ? (data['studentName'] as String)
            : '학습자';
        final int totalStars = (data['todayStars'] as num?)?.toInt() ?? 0;
        final List<dynamic> sessionHistory = (data['sessionHistory'] as List<dynamic>?) ?? [];

        String? lastSubject;
        int lastDurationMinutes = 0;
        if (sessionHistory.isNotEmpty) {
          try {
            final Map<String, dynamic> last = Map<String, dynamic>.from(sessionHistory.last as Map);
            lastSubject = last['subject'] as String?;
            final int durationSeconds = (last['durationSeconds'] as num?)?.toInt() ?? 0;
            lastDurationMinutes = (durationSeconds / 60).round();
          } catch (_) {
            // 손상된 마지막 기록 1건은 건너뜀 - 화면은 "학습 기록 없음" 상태로 정상 표시됨
          }
        }

        return ParentLiveStatusWidget(
          childName: childName,
          lastSessionSubject: lastSubject,
          lastSessionDurationMinutes: lastDurationMinutes,
          totalCollectedStars: totalStars,
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
      FamilyLinkService.pushEmojiToChild(_selectedChildCode!, emoji: emoji, message: message);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: premiumCardBg,
        content: Text(
          "${_t(kEmojiSentMap)}\n($message)",
          style: GoogleFonts.notoSansKr(color: brandGolden, fontWeight: FontWeight.bold),
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
      FamilyLinkService.pushEncouragementToChild(_selectedChildCode!, message: customText);
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
          style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
        body: const Center(child: CircularProgressIndicator(color: brandGolden)),
      );
    }

    return Scaffold(
      backgroundColor: luxuryDarkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 90,
        automaticallyImplyLeading: false,
        title: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 14.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/gsu_logo.png',
                      width: 180,
                      height: 24,
                      fit: BoxFit.fill,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(height: 24),
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
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isVipMember = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isVipMember ? brandGolden : Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: brandGolden.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _isVipMember ? _t(kVipBadgeMap) : _bi(kVipLinkMap),
                    style: GoogleFonts.notoSansKr(
                      color: _isVipMember ? Colors.black : brandGolden,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          _buildLinkedChildrenBar(), // 🆕 [자녀 추가] 상단에 항상 표시되는 연결된 자녀 명단 + 추가 버튼
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
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 🆕 [성적 관리] 4번째 탭 추가로 인해 명시 - 기본 shifting 애니메이션/색상 변경 방지, 기존 3탭과 동일한 스타일 유지
        currentIndex: _currentIndex,
        backgroundColor: premiumCardBg,
        selectedItemColor: brandGolden,
        unselectedItemColor: Colors.white38,
        selectedLabelStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.notoSansKr(fontSize: 11),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.bolt_rounded), label: _bi(kTabLiveStatusMap)),
          BottomNavigationBarItem(icon: const Icon(Icons.assignment_rounded), label: _bi(kTabDetailedMap)),
          BottomNavigationBarItem(icon: const Icon(Icons.analytics_rounded), label: _bi(kTabEvaluationMap)),
          BottomNavigationBarItem(icon: const Icon(Icons.grading_rounded), label: _bi(kTabGradeMap)), // 🆕 4번째 탭
        ],
      ),
    );
  }
}
