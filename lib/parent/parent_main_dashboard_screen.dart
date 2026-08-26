import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'parent_live_status_widget.dart';
import 'parent_detailed_analysis_widget.dart';
import 'parent_evaluation_analysis_widget.dart';
import 'parent_grade_management_widget.dart'; // 🆕 [성적 관리] 학부모 조회 전용 4번째 탭
import '../services/parent_data_service.dart';
import '../services/diagnosis_service.dart'; // 🆕 [요청] 300자 이상 AI 진단문 + 재사용 규칙 서비스
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
  String _selectedBigUnit = "대단원 1";
  String _selectedMidUnit = "중단원 1";
  int _selectedSemesterFilter = 1;

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
  Future<String> _buildSummaryReportText() async {
    if (_todaySessions.isEmpty) {
      return _biLong(kNoSessionTodayMap);
    }
    final buffer = StringBuffer();
    buffer.writeln("${_t(kReportHeaderMap)}\n");
    for (int i = 0; i < _todaySessions.length; i++) {
      final rec = _todaySessions[i];
      final String periodLabel = _isNumberFirstLang ? "제${i + 1}${_t(kPeriodWordMap)}" : "${_t(kPeriodWordMap)} ${i + 1}";
      buffer.writeln("$periodLabel · ${rec.subject} · ${rec.durationMinutes}${_t(kMinutesUnitMap)} ${_t(kFocusCompletedMap)}");
      if (rec.recordType == '평가' && rec.score != null) {
        buffer.writeln("  ${_t(kScoreLabelMap)}: ${rec.score}");
      }
    }
    buffer.writeln("\n${_t(kTodayTotalTimeMap)}: $_todayTotalMinutes${_t(kMinutesUnitMap)}");

    // 🆕 [요청] 오늘 학습한 과목 전체를 종합한 150~200자 AI 총평을 별도 문단으로 추가
    final int subjectCount = _todaySessions.map((r) => r.subject).toSet().length;
    final String dailySummary = await DiagnosisService.getDailySummary(
      personKey: 'student_$_realChildName',
      subjectCount: subjectCount,
      totalMinutes: _todayTotalMinutes,
    );
    buffer.writeln("\n${_t(kTodaySummaryHeaderMap)}");
    buffer.writeln(dailySummary);

    return buffer.toString();
  }

  // 🆕 [버그 수정] 기존엔 가장 최근 세션 1건만 보여줬음 -> 오늘 학습한 모든 세션을
  // 제1교시, 제2교시... 순서대로 전부 나열하도록 수정 (요청사항)
  String _buildDetailedAnalysisText() {
    if (_todaySessions.isEmpty) {
      return _t(kNoDetailTodayMap);
    }
    final buffer = StringBuffer();
    buffer.writeln("${_t(kDetailHeaderMap)}\n");
    for (int i = 0; i < _todaySessions.length; i++) {
      final rec = _todaySessions[i];
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

  @override
  void dispose() {
    _timeTabController.dispose();
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

      body: IndexedStack(
        index: _currentIndex,
        children: [
          ParentLiveStatusWidget(
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
            onSendEmojiMessage: (emoji, message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: premiumCardBg,
                  content: Text(
                    "${_t(kEmojiSentMap)}\n($message)",
                    style: GoogleFonts.notoSansKr(color: brandGolden, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
            onSendCustomMessage: (customText) {
              final now = DateTime.now();
              final hourText = now.hour < 10 ? '0${now.hour}' : '${now.hour}';
              final minText = now.minute < 10 ? '0${now.minute}' : '${now.minute}';

              setState(() {
                _lastSentTimeText = "$hourText:$minText";
              });

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
            },
            onStartMonitoring: () {
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
            },
          ),

          ParentDetailedAnalysisWidget(
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
            // 🆕 [지난 일자 조회] 좌우 화살표로 하루씩 이동하며 조회
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
          ),

          ParentEvaluationAnalysisWidget(
            childName: _realChildName,
            selectedEvaluationType: _selectedEvaluationType,
            selectedBigUnit: _selectedBigUnit,
            selectedMidUnit: _selectedMidUnit,
            selectedSemesterFilter: _selectedSemesterFilter,
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
            onBigUnitChanged: (unit) => setState(() => _selectedBigUnit = unit),
            onMidUnitChanged: (unit) => setState(() => _selectedMidUnit = unit),
            onSemesterFilterChanged: (filter) => setState(() => _selectedSemesterFilter = filter),
            onYearChanged: (year) => setState(() => _selectedYear = year),
            onMonthChanged: (month) => setState(() => _selectedMonth = month),
            onWeekChanged: (week) => setState(() => _selectedWeek = week),
            onShowDetailAnalysisReport: () async {
              // 🆕 [요청] 300자 이상 상세 진단 + 같은 사람에게 3개월 내 재사용 금지 + 생성된 문구는
              // 반드시 저장 후 유사한 사람(같은 점수 구간)에게 재사용. DiagnosisService가 전담 관리.
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
          ),

          // 🆕 [성적 관리] 4번째 탭 - 조회 전용 (Plan A: 같은 기기 SharedPreferences 직접 조회)
          ParentGradeManagementWidget(
            childName: _realChildName,
            premiumCardBg: premiumCardBg,
            brandGolden: brandGolden,
            luxuryDarkBg: luxuryDarkBg,
            buildCustomSectionTitle: _buildCustomSectionTitle,
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
