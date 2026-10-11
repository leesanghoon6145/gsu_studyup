// live_active_users_screen.dart
//
// 🆕 [2026-10-11] 동시 접속자 — 가상 숫자 · 가상 인원 모두 삭제, 실제 학생 기록으로만 표시
// - 5분마다 한 번 새로 셈 (화면이 열려 있을 때만)
// - 친구 = 같은 학교 · 같은 학년 학생 → 이름 + 학교까지 보임
// - 전체 랭킹 · 성취 알림은 다른 학교 학생도 섞이므로 이름을 가림 (김○○)
// - 글자체: 영문 = 진한 명조(고운바탕 굵게) / 한글 = 노토산스 KR / 10개 외국어 = 그 나라 말 한 줄

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gsu_studyup/global_lang.dart';
import 'package:gsu_studyup/star_economy.dart';
import 'package:gsu_studyup/services/presence_service.dart';
import 'package:gsu_studyup/services/ranking_service.dart';
import 'package:gsu_studyup/services/subject_category.dart';

const Color _kBg = Color(0xFF050B14);
const Color _kCard = Color(0xFF0D1527);
const Color _kGold = Color(0xFFE5C158);
const Color _kWhite = Color(0xFFEFEFEF);
const Color _kGreen = Color(0xFF1DD1A1);
const Color _kBlue = Color(0xFF54A0FF);

const Map<String, Map<String, String>> _tx = {
  'appBarTitleEn': {'EN': 'LIVE ACTIVE USERS'},
  'appBarTitleKo': {'KO': '동시 접속자', 'EN': 'Live Active Users', 'JA': '同時接続者', 'ZH': '同时在线用户', 'FR': 'Utilisateurs actifs en direct', 'DE': 'Live aktive Nutzer', 'RU': 'Активные пользователи', 'AR': 'المستخدمون النشطون الآن', 'HI': 'लाइव सक्रिय उपयोगकर्ता', 'VI': 'Người dùng trực tuyến', 'ES': 'Usuarios activos en vivo', 'TH': 'ผู้ใช้ที่ออนไลน์อยู่ขณะนี้'},
  'subtitle': {'KO': '지금도 전국 · 전 세계 친구들이 함께 공부하고 있어요', 'EN': 'Students across the country and the world are studying with you', 'JA': '今も全国・世界中の仲間が一緒に勉強しています', 'ZH': '此刻全国和全世界的同学正和你一起学习', 'FR': 'Des élèves du pays et du monde entier étudient avec vous', 'DE': 'Schüler im ganzen Land und weltweit lernen gerade mit dir', 'RU': 'Ученики по всей стране и миру учатся вместе с тобой', 'AR': 'طلاب من أنحاء البلاد والعالم يدرسون معك الآن', 'HI': 'देश और दुनिया भर के छात्र अभी आपके साथ पढ़ रहे हैं', 'VI': 'Học sinh khắp cả nước và thế giới đang học cùng bạn', 'ES': 'Estudiantes de todo el país y del mundo estudian contigo', 'TH': 'นักเรียนทั่วประเทศและทั่วโลกกำลังเรียนไปพร้อมกับคุณ'},
  'catLive': {'KO': '지금 공부 중인 학생', 'EN': 'Studying Right Now', 'JA': '今勉強中の生徒', 'ZH': '正在学习的学生', 'FR': 'En train d\'étudier', 'DE': 'Lernen gerade', 'RU': 'Учатся прямо сейчас', 'AR': 'يدرسون الآن', 'HI': 'अभी पढ़ रहे छात्र', 'VI': 'Đang học ngay lúc này', 'ES': 'Estudiando ahora', 'TH': 'กำลังเรียนอยู่ตอนนี้'},
  'catFriends': {'KO': '우리 학교 · 학년 친구', 'EN': 'Classmates (Same School & Grade)', 'JA': '同じ学校・学年の友達', 'ZH': '同校同年级的朋友', 'FR': 'Camarades (même école et niveau)', 'DE': 'Mitschüler (gleiche Schule & Stufe)', 'RU': 'Одноклассники (та же школа и класс)', 'AR': 'زملاء الصف (نفس المدرسة والصف)', 'HI': 'सहपाठी (एक ही स्कूल व कक्षा)', 'VI': 'Bạn cùng trường · cùng khối', 'ES': 'Compañeros (misma escuela y curso)', 'TH': 'เพื่อนร่วมโรงเรียนและชั้นเดียวกัน'},
  'catMyRanking': {'KO': '내 순위', 'EN': 'My Ranking', 'JA': '自分の順位', 'ZH': '我的排名', 'FR': 'Mon classement', 'DE': 'Meine Platzierung', 'RU': 'Мой рейтинг', 'AR': 'ترتيبي', 'HI': 'मेरी रैंकिंग', 'VI': 'Xếp hạng của tôi', 'ES': 'Mi clasificación', 'TH': 'อันดับของฉัน'},
  'catTodayRanking': {'KO': '오늘 실시간 랭킹', 'EN': "Today's Live Ranking", 'JA': '本日のリアルタイムランキング', 'ZH': '今日实时排名', 'FR': 'Classement du jour', 'DE': 'Heutige Live-Rangliste', 'RU': 'Рейтинг за сегодня', 'AR': 'الترتيب المباشر لليوم', 'HI': 'आज की लाइव रैंकिंग', 'VI': 'Xếp hạng trực tiếp hôm nay', 'ES': 'Clasificación de hoy', 'TH': 'อันดับสดวันนี้'},
  'catTargets': {'KO': '오늘의 인기 목표', 'EN': "Today's Popular Targets", 'JA': '本日の人気目標', 'ZH': '今日热门目标', 'FR': 'Objectifs populaires du jour', 'DE': 'Beliebte Ziele heute', 'RU': 'Популярные цели сегодня', 'AR': 'الأهداف الشائعة اليوم', 'HI': 'आज के लोकप्रिय लक्ष्य', 'VI': 'Mục tiêu phổ biến hôm nay', 'ES': 'Objetivos populares de hoy', 'TH': 'เป้าหมายยอดนิยมวันนี้'},
  'catStats': {'KO': '오늘의 전체 통계', 'EN': "Today's Global Statistics", 'JA': '本日の全体統計', 'ZH': '今日全体统计', 'FR': 'Statistiques du jour', 'DE': 'Heutige Gesamtstatistik', 'RU': 'Общая статистика за сегодня', 'AR': 'إحصائيات اليوم', 'HI': 'आज के कुल आँकड़े', 'VI': 'Thống kê hôm nay', 'ES': 'Estadísticas de hoy', 'TH': 'สถิติรวมวันนี้'},
  'catAlerts': {'KO': '실시간 성취 알림', 'EN': 'Real-time Achievement Alerts', 'JA': 'リアルタイム達成通知', 'ZH': '实时成就提醒', 'FR': 'Alertes de réussite', 'DE': 'Erfolgsmeldungen live', 'RU': 'Достижения в реальном времени', 'AR': 'تنبيهات الإنجاز الفورية', 'HI': 'लाइव उपलब्धि सूचनाएँ', 'VI': 'Thông báo thành tích', 'ES': 'Alertas de logros', 'TH': 'แจ้งเตือนความสำเร็จ'},
  'catSubjects': {'KO': '오늘 전체 과목 비율', 'EN': "Today's Subject Ratio", 'JA': '本日の科目別割合', 'ZH': '今日科目比例', 'FR': 'Répartition des matières du jour', 'DE': 'Fächerverteilung heute', 'RU': 'Доля предметов сегодня', 'AR': 'نسبة المواد اليوم', 'HI': 'आज का विषय अनुपात', 'VI': 'Tỷ lệ môn học hôm nay', 'ES': 'Proporción de materias hoy', 'TH': 'สัดส่วนวิชาวันนี้'},
  'studying': {'KO': '공부 중', 'EN': 'Studying', 'JA': '勉強中', 'ZH': '学习中', 'FR': 'Étudie', 'DE': 'Lernt', 'RU': 'Учится', 'AR': 'يدرس', 'HI': 'पढ़ रहे हैं', 'VI': 'Đang học', 'ES': 'Estudiando', 'TH': 'กำลังเรียน'},
  'resting': {'KO': '쉬는 중', 'EN': 'Resting', 'JA': '休憩中', 'ZH': '休息中', 'FR': 'En pause', 'DE': 'Pause', 'RU': 'Отдыхает', 'AR': 'يستريح', 'HI': 'आराम', 'VI': 'Đang nghỉ', 'ES': 'Descansando', 'TH': 'กำลังพัก'},
  'online': {'KO': '지금 접속 중', 'EN': 'Online now', 'JA': '現在接続中', 'ZH': '当前在线', 'FR': 'En ligne', 'DE': 'Gerade online', 'RU': 'Сейчас онлайн', 'AR': 'متصل الآن', 'HI': 'अभी ऑनलाइन', 'VI': 'Đang trực tuyến', 'ES': 'En línea', 'TH': 'ออนไลน์อยู่'},
  'people': {'KO': '명', 'EN': '', 'JA': '人', 'ZH': '人', 'FR': '', 'DE': '', 'RU': '', 'AR': '', 'HI': '', 'VI': '', 'ES': '', 'TH': ' คน'},
  'refresh5': {'KO': '5분마다 새로 세어요', 'EN': 'Updated every 5 minutes', 'JA': '5分ごとに更新', 'ZH': '每5分钟更新', 'FR': 'Mis à jour toutes les 5 min', 'DE': 'Alle 5 Minuten aktualisiert', 'RU': 'Обновляется каждые 5 минут', 'AR': 'يتم التحديث كل 5 دقائق', 'HI': 'हर 5 मिनट में अपडेट', 'VI': 'Cập nhật mỗi 5 phút', 'ES': 'Se actualiza cada 5 minutos', 'TH': 'อัปเดตทุก 5 นาที'},
  'lastUpdate': {'KO': '마지막 갱신', 'EN': 'Last update', 'JA': '最終更新', 'ZH': '最后更新', 'FR': 'Mise à jour', 'DE': 'Zuletzt', 'RU': 'Обновлено', 'AR': 'آخر تحديث', 'HI': 'अंतिम अपडेट', 'VI': 'Cập nhật lúc', 'ES': 'Actualizado', 'TH': 'อัปเดตล่าสุด'},
  'noFriends': {'KO': '아직 앱을 쓰는 같은 학교 · 학년 친구가 없어요. 친구에게 GKE StudyUp을 알려 주세요!', 'EN': 'No classmates from your school & grade are using the app yet. Invite your friends!', 'JA': 'まだ同じ学校・学年の友達がいません。友達を招待しよう！', 'ZH': '还没有同校同年级的朋友使用本应用，邀请朋友吧！', 'FR': 'Aucun camarade de ton école et niveau pour l\'instant. Invite tes amis !', 'DE': 'Noch keine Mitschüler deiner Schule und Stufe. Lade Freunde ein!', 'RU': 'Пока нет одноклассников из твоей школы. Пригласи друзей!', 'AR': 'لا يوجد زملاء من مدرستك وصفك بعد. ادعُ أصدقاءك!', 'HI': 'अभी आपके स्कूल व कक्षा का कोई सहपाठी नहीं है। दोस्तों को आमंत्रित करें!', 'VI': 'Chưa có bạn cùng trường, cùng khối. Hãy mời bạn bè nhé!', 'ES': 'Aún no hay compañeros de tu escuela y curso. ¡Invita a tus amigos!', 'TH': 'ยังไม่มีเพื่อนร่วมโรงเรียนและชั้นเดียวกัน ชวนเพื่อนมาสิ!'},
  'noSchool': {'KO': '가입할 때 학교 · 학년을 넣은 학생끼리 친구로 보여요.', 'EN': 'Classmates appear when school & grade are set at sign-up.', 'JA': '登録時に学校・学年を入力した生徒同士が表示されます。', 'ZH': '注册时填写学校和年级的同学会显示在这里。', 'FR': 'Les camarades apparaissent si l\'école et le niveau sont renseignés.', 'DE': 'Mitschüler erscheinen, wenn Schule und Stufe angegeben sind.', 'RU': 'Одноклассники видны, если указаны школа и класс.', 'AR': 'يظهر الزملاء عند إدخال المدرسة والصف عند التسجيل.', 'HI': 'पंजीकरण में स्कूल व कक्षा भरने पर सहपाठी दिखते हैं।', 'VI': 'Bạn bè hiện khi đã nhập trường và khối lúc đăng ký.', 'ES': 'Los compañeros aparecen si indicaste escuela y curso.', 'TH': 'เพื่อนจะแสดงเมื่อกรอกโรงเรียนและชั้นตอนสมัคร'},
  'friendRank': {'KO': '친구 순위', 'EN': 'Among classmates', 'JA': '友達内順位', 'ZH': '好友排名', 'FR': 'Parmi les camarades', 'DE': 'Unter Mitschülern', 'RU': 'Среди одноклассников', 'AR': 'بين الزملاء', 'HI': 'सहपाठियों में', 'VI': 'Trong bạn bè', 'ES': 'Entre compañeros', 'TH': 'ในกลุ่มเพื่อน'},
  'worldRank': {'KO': '전 세계 순위', 'EN': 'Worldwide', 'JA': '世界順位', 'ZH': '全球排名', 'FR': 'Mondial', 'DE': 'Weltweit', 'RU': 'В мире', 'AR': 'عالميًا', 'HI': 'विश्व स्तर पर', 'VI': 'Toàn cầu', 'ES': 'Mundial', 'TH': 'ทั่วโลก'},
  'rankBasis': {'KO': '이번 달 공부 시간 기준', 'EN': "Based on this month's study time", 'JA': '今月の学習時間基準', 'ZH': '按本月学习时间', 'FR': 'Selon le temps d\'étude du mois', 'DE': 'Nach Lernzeit dieses Monats', 'RU': 'По времени учёбы за месяц', 'AR': 'حسب وقت الدراسة هذا الشهر', 'HI': 'इस महीने के अध्ययन समय के आधार पर', 'VI': 'Theo thời gian học tháng này', 'ES': 'Según el tiempo de estudio del mes', 'TH': 'ตามเวลาเรียนเดือนนี้'},
  'rankOf': {'KO': '{rank}위 / {total}명', 'EN': 'No. {rank} of {total}', 'JA': '{total}人中 {rank}位', 'ZH': '{total}人中第{rank}名', 'FR': '{rank}e sur {total}', 'DE': 'Platz {rank} von {total}', 'RU': '{rank} из {total}', 'AR': '{rank} من {total}', 'HI': '{total} में {rank}', 'VI': 'Hạng {rank}/{total}', 'ES': '{rank}º de {total}', 'TH': 'อันดับ {rank} จาก {total}'},
  'noData': {'KO': '아직 오늘 기록이 없어요', 'EN': 'No records yet today', 'JA': '今日の記録はまだありません', 'ZH': '今天还没有记录', 'FR': 'Pas encore de données aujourd\'hui', 'DE': 'Heute noch keine Daten', 'RU': 'Сегодня данных пока нет', 'AR': 'لا توجد سجلات اليوم بعد', 'HI': 'आज अभी कोई रिकॉर्ड नहीं', 'VI': 'Hôm nay chưa có dữ liệu', 'ES': 'Aún no hay registros hoy', 'TH': 'วันนี้ยังไม่มีข้อมูล'},
  'statTime': {'KO': '오늘 총 공부 시간', 'EN': 'Total study time today', 'JA': '本日の総学習時間', 'ZH': '今日总学习时间', 'FR': 'Temps d\'étude total', 'DE': 'Gesamtlernzeit heute', 'RU': 'Всего учёбы сегодня', 'AR': 'إجمالي وقت الدراسة اليوم', 'HI': 'आज कुल अध्ययन समय', 'VI': 'Tổng thời gian học hôm nay', 'ES': 'Tiempo total de estudio', 'TH': 'เวลาเรียนรวมวันนี้'},
  'statStudents': {'KO': '오늘 공부한 학생', 'EN': 'Students who studied today', 'JA': '本日学習した生徒', 'ZH': '今日学习人数', 'FR': 'Élèves ayant étudié', 'DE': 'Schüler, die heute lernten', 'RU': 'Учились сегодня', 'AR': 'طلاب درسوا اليوم', 'HI': 'आज पढ़ने वाले छात्र', 'VI': 'Học sinh đã học hôm nay', 'ES': 'Estudiantes de hoy', 'TH': 'นักเรียนที่เรียนวันนี้'},
  'statGoal': {'KO': '하루 50분 달성', 'EN': 'Reached 50 min today', 'JA': '1日50分達成', 'ZH': '今日达成50分钟', 'FR': '50 min atteintes', 'DE': '50 Min. erreicht', 'RU': 'Достигли 50 минут', 'AR': 'حققوا 50 دقيقة', 'HI': '50 मिनट पूरे', 'VI': 'Đạt 50 phút', 'ES': 'Lograron 50 min', 'TH': 'ทำได้ 50 นาที'},
  'alertTime': {'KO': '{name}님 오늘 {time} 공부했어요', 'EN': '{name} studied {time} today', 'JA': '{name}さんが今日{time}勉強しました', 'ZH': '{name}今天学习了{time}', 'FR': '{name} a étudié {time} aujourd\'hui', 'DE': '{name} hat heute {time} gelernt', 'RU': '{name} сегодня учился {time}', 'AR': 'درس {name} اليوم {time}', 'HI': '{name} ने आज {time} पढ़ाई की', 'VI': '{name} đã học {time} hôm nay', 'ES': '{name} estudió {time} hoy', 'TH': '{name} เรียนวันนี้ {time}'},
  'alertLevel': {'KO': '{name}님 레벨 {level} 달성!', 'EN': '{name} reached Level {level}!', 'JA': '{name}さんがレベル{level}達成！', 'ZH': '{name}达到{level}级！', 'FR': '{name} a atteint le niveau {level} !', 'DE': '{name} hat Level {level} erreicht!', 'RU': '{name} достиг уровня {level}!', 'AR': 'وصل {name} إلى المستوى {level}!', 'HI': '{name} ने स्तर {level} पाया!', 'VI': '{name} đạt cấp {level}!', 'ES': '¡{name} alcanzó el nivel {level}!', 'TH': '{name} ถึงเลเวล {level} แล้ว!'},
  'subjectOf': {'KO': '과목', 'EN': 'Subject', 'JA': '科目', 'ZH': '科目', 'FR': 'Matière', 'DE': 'Fach', 'RU': 'Предмет', 'AR': 'المادة', 'HI': 'विषय', 'VI': 'Môn', 'ES': 'Materia', 'TH': 'วิชา'},
  'others': {'KO': '그 밖의 과목', 'EN': 'Others', 'JA': 'その他', 'ZH': '其他', 'FR': 'Autres', 'DE': 'Andere', 'RU': 'Другие', 'AR': 'أخرى', 'HI': 'अन्य', 'VI': 'Khác', 'ES': 'Otros', 'TH': 'อื่น ๆ'},
  'today': {'KO': '오늘', 'EN': 'Today', 'JA': '今日', 'ZH': '今天', 'FR': 'Aujourd\'hui', 'DE': 'Heute', 'RU': 'Сегодня', 'AR': 'اليوم', 'HI': 'आज', 'VI': 'Hôm nay', 'ES': 'Hoy', 'TH': 'วันนี้'},
  'close': {'KO': '닫기', 'EN': 'Close', 'JA': '閉じる', 'ZH': '关闭', 'FR': 'Fermer', 'DE': 'Schließen', 'RU': 'Закрыть', 'AR': 'إغلاق', 'HI': 'बंद करें', 'VI': 'Đóng', 'ES': 'Cerrar', 'TH': 'ปิด'},
};

bool get _foreign => DkeLang.isForeignSelected;
String _lang() => _foreign ? DkeLang.current : 'KO';

/// 지금 언어 글자 하나 (기본 = 한글)
String _s(String k, [Map<String, Object>? args]) {
  final Map<String, String>? m = _tx[k];
  String v = m == null ? k : (m[_lang()] ?? m['EN'] ?? m['KO'] ?? k);
  args?.forEach((a, b) => v = v.replaceAll('{$a}', '$b'));
  return v;
}

/// 영문 글자 (기본 모드 윗줄)
String _e(String k, [Map<String, Object>? args]) {
  final Map<String, String>? m = _tx[k];
  String v = m == null ? k : (m['EN'] ?? m['KO'] ?? k);
  args?.forEach((a, b) => v = v.replaceAll('{$a}', '$b'));
  return v;
}

TextStyle _enStyle(double size, {Color color = _kGold}) =>
    GoogleFonts.gowunBatang(color: color, fontSize: size, fontWeight: FontWeight.bold);
TextStyle _koStyle(double size, {Color color = _kGold, FontWeight w = FontWeight.bold}) =>
    GoogleFonts.notoSansKr(color: color, fontSize: size, fontWeight: w);

/// 제목 두 줄: 영문(진한 명조) 위 + 한글(노토산스) 아래 / 외국어는 그 나라 말 한 줄
Widget _bi2(String k, {double size = 15, Color color = _kGold, CrossAxisAlignment align = CrossAxisAlignment.start, TextAlign ta = TextAlign.start}) {
  if (_foreign) return Text(_s(k), textAlign: ta, style: _koStyle(size, color: color));
  return Column(
    crossAxisAlignment: align,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(_e(k), textAlign: ta, style: _enStyle(size - 2, color: color.withValues(alpha: 0.75))),
      Text(_s(k), textAlign: ta, style: _koStyle(size, color: color)),
    ],
  );
}

/// 한 줄 안에 영문(명조) + 한글(노토산스) / 외국어는 그 나라 말
Widget _bi1(String k, {double size = 13, Color color = _kWhite, Map<String, Object>? args, int maxLines = 1}) {
  if (_foreign) {
    return Text(_s(k, args), maxLines: maxLines, overflow: TextOverflow.ellipsis, style: _koStyle(size, color: color, w: FontWeight.w600));
  }
  return Text.rich(
    TextSpan(children: [
      TextSpan(text: '${_e(k, args)}  ', style: _enStyle(size - 1, color: color.withValues(alpha: 0.7))),
      TextSpan(text: _s(k, args), style: _koStyle(size, color: color, w: FontWeight.w600)),
    ]),
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
  );
}

String _fmtMin(int m) {
  final int h = m ~/ 60, r = m % 60;
  if (_lang() == 'KO') return h > 0 ? '$h시간 ${r.toString().padLeft(2, '0')}분' : '$r분';
  return h > 0 ? '${h}h ${r.toString().padLeft(2, '0')}m' : '${r}m';
}

String _num(int n) {
  final String s = n.toString();
  final StringBuffer b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

String _people(int n) => '${_num(n)}${_s('people')}';

class LiveActiveUsersScreen extends StatefulWidget {
  const LiveActiveUsersScreen({Key? key}) : super(key: key);

  @override
  State<LiveActiveUsersScreen> createState() => _LiveActiveUsersScreenState();
}

class _LiveActiveUsersScreenState extends State<LiveActiveUsersScreen> {
  Timer? _timer;
  bool _loading = true;
  DateTime? _updatedAt;
  PresenceStats? _stats;
  List<PresenceInfo> _friends = [];
  List<PresenceInfo> _top = [];
  RankResult? _friendRank;
  RankResult? _worldRank;
  bool _hasGroup = true;

  static const List<Color> _pieColors = [
    Color(0xFFFF4D4D), Color(0xFFFF9F43), Color(0xFFFECA57), Color(0xFF1DD1A1), Color(0xFF54A0FF), Color(0xFF8E7CC3),
  ];

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(PresenceService.beatInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    await PresenceService.beat(); // 나도 접속 중으로 (5분에 한 번만 실제로 씀)
    final results = await Future.wait([
      PresenceService.fetchStats(),
      PresenceService.fetchFriends(),
      PresenceService.fetchTodayTop(),
    ]);
    RankResult? fr, wr;
    bool hasGroup = PresenceService.myGroupKey.isNotEmpty;
    try {
      final r = await RankingService.updateAndFetch(await DkeStars.getMonthlyBaseStars());
      fr = r.friend;
      wr = r.global;
      hasGroup = r.hasGroup;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _stats = results[0] as PresenceStats;
      _friends = results[1] as List<PresenceInfo>;
      _top = results[2] as List<PresenceInfo>;
      _friendRank = fr;
      _worldRank = wr;
      _hasGroup = hasGroup;
      _updatedAt = DateTime.now();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 140,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/gsu_logo.png', width: 190, height: 26, fit: BoxFit.contain),
            const SizedBox(height: 4),
            if (_foreign)
              Text(_s('appBarTitleKo'), textAlign: TextAlign.center, style: _koStyle(20))
            else ...[
              Text('LIVE ACTIVE USERS', textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: _kGold, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.5)),
              Text('동시 접속자', textAlign: TextAlign.center, style: _koStyle(23)),
            ],
          ],
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kGold))
          : RefreshIndicator(
        color: _kGold,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _bi2('subtitle', size: 14, color: const Color(0xFFFFF6D6), align: CrossAxisAlignment.center, ta: TextAlign.center)),
              const SizedBox(height: 22),
              _card(1, 'catLive', _liveSection()),
              _card(2, 'catFriends', _friendSection()),
              _card(3, 'catMyRanking', _rankSection()),
              _card(4, 'catTodayRanking', _topSection()),
              _card(5, 'catTargets', _targetSection()),
              _card(6, 'catStats', _statsSection()),
              _card(7, 'catAlerts', _alertSection()),
              _card(8, 'catSubjects', _subjectSection()),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(int n, String titleKey, Widget content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGold.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$n. ', style: _enStyle(16)),
              Expanded(child: _bi2(titleKey, size: 15)),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: Colors.white12, height: 1)),
          content,
        ],
      ),
    );
  }

  Widget _empty(String k) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: _bi1(k, size: 12.5, color: Colors.white54, maxLines: 3),
  );

  // 1. 지금 공부 중
  Widget _liveSection() {
    final PresenceStats s = _stats!;
    final String t = _updatedAt == null
        ? ''
        : '${_updatedAt!.hour.toString().padLeft(2, '0')}:${_updatedAt!.minute.toString().padLeft(2, '0')}';
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.circle, color: _kGreen, size: 12),
            const SizedBox(width: 8),
            Text(_people(s.studying), style: GoogleFonts.gowunBatang(color: _kGold, fontSize: 30, fontWeight: FontWeight.w900)),
            const SizedBox(width: 8),
            _bi1('studying', size: 14, color: _kGold),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.circle, color: _kBlue, size: 9),
            const SizedBox(width: 6),
            Flexible(child: _bi1('online', size: 13, color: Colors.white70)),
            Text('  ${_people(s.online)}', style: _koStyle(13, color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.autorenew_rounded, color: Colors.white38, size: 14),
            const SizedBox(width: 4),
            Flexible(child: _bi1('refresh5', size: 11, color: Colors.white38)),
            Text('  · $t', style: _koStyle(11, color: Colors.white38, w: FontWeight.normal)),
          ],
        ),
      ],
    );
  }

  // 2. 같은 학교 · 학년 친구 (이름 + 학교)
  Widget _friendSection() {
    if (!_hasGroup) return _empty('noSchool');
    if (_friends.isEmpty) return _empty('noFriends');
    final List<PresenceInfo> list = _friends.take(20).toList();
    return Column(
      children: [
        for (int i = 0; i < list.length; i++) ...[
          if (i > 0) const Divider(color: Colors.white10, height: 18),
          _friendRow(list[i]),
        ],
      ],
    );
  }

  Widget _friendRow(PresenceInfo p) {
    return InkWell(
      onTap: () => _showFriend(p),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: p.studying ? _kBlue : Colors.grey),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name.isEmpty ? '—' : p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _koStyle(14, color: _kWhite)),
                Text(p.school, maxLines: 1, overflow: TextOverflow.ellipsis, style: _koStyle(11.5, color: Colors.white54, w: FontWeight.normal)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_s(p.studying ? 'studying' : 'resting'), style: _koStyle(11.5, color: p.studying ? _kBlue : Colors.white38)),
              Text(_fmtMin(p.todayMinutes), style: _koStyle(13, color: _kGold)),
            ],
          ),
        ],
      ),
    );
  }

  void _showFriend(PresenceInfo p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          side: BorderSide(color: _kGold, width: 1.5),
        ),
        title: Column(
          children: [
            Text(p.name, textAlign: TextAlign.center, style: _koStyle(18)),
            Text(p.school, textAlign: TextAlign.center, style: _koStyle(12.5, color: Colors.white60, w: FontWeight.normal)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _bi1(p.studying ? 'studying' : 'resting', size: 14, color: p.studying ? _kBlue : Colors.white54),
            if (p.studying && p.subject.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(p.subject, textAlign: TextAlign.center, style: _koStyle(13, color: _kWhite, w: FontWeight.w500)),
            ],
            const SizedBox(height: 10),
            Text('${_s('today')} ${_fmtMin(p.todayMinutes)}  ·  Lv.${p.level}  ·  ⭐ ${_num(p.totalStars)}', textAlign: TextAlign.center, style: _koStyle(13.5, color: _kGold)),
          ],
        ),
        actions: [
          Center(child: TextButton(onPressed: () => Navigator.pop(ctx), child: _bi1('close', color: _kGold))),
        ],
      ),
    );
  }

  // 3. 내 순위
  Widget _rankSection() {
    Widget line(String k, RankResult? r) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(child: _bi1(k, size: 13.5)),
            Text(
              r == null ? '—' : _s('rankOf', {'rank': _num(r.rank), 'total': _num(r.total)}),
              style: _koStyle(14.5, color: _kGold),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasGroup) line('friendRank', _friendRank),
        line('worldRank', _worldRank),
        const SizedBox(height: 4),
        _bi1('rankBasis', size: 11, color: Colors.white38),
      ],
    );
  }

  // 4. 오늘 실시간 랭킹 (다른 학교 학생도 있어 이름을 가림)
  Widget _topSection() {
    if (_top.isEmpty) return _empty('noData');
    const List<String> medals = ['🥇', '🥈', '🥉'];
    const List<Color> colors = [Color(0xFFF1C40F), Color(0xFFBDC3C7), Color(0xFFE67E22)];
    final List<PresenceInfo> list = _top.take(3).toList();
    return Column(
      children: [
        for (int i = 0; i < list.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(medals[i], style: const TextStyle(fontSize: 17)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    list[i].uid == PresenceService.myUid ? list[i].name : PresenceService.maskName(list[i].name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _koStyle(14, color: colors[i]),
                  ),
                ),
                Text(_fmtMin(list[i].todayMinutes), style: _koStyle(14, color: _kGold)),
              ],
            ),
          ),
      ],
    );
  }

  // 5. 오늘의 인기 목표
  Widget _targetSection() {
    final Map<String, int> counts = {};
    for (final PresenceInfo p in _top) {
      final String t = p.target.trim();
      if (t.isEmpty) continue;
      counts[t] = (counts[t] ?? 0) + 1;
    }
    if (counts.isEmpty) return _empty('noData');
    final List<MapEntry<String, int>> list = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final List<MapEntry<String, int>> top5 = list.take(5).toList();
    return Column(
      children: [
        for (int i = 0; i < top5.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text('${i + 1}.', style: _enStyle(15)),
                const SizedBox(width: 12),
                Expanded(child: Text(top5[i].key, maxLines: 1, overflow: TextOverflow.ellipsis, style: _koStyle(14, color: _kWhite, w: FontWeight.w600))),
                Text(_people(top5[i].value), style: _koStyle(12.5, color: _kGold)),
              ],
            ),
          ),
      ],
    );
  }

  // 6. 오늘의 전체 통계
  Widget _statsSection() {
    final PresenceStats s = _stats!;
    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: _bi1(k, size: 13.5)),
          const SizedBox(width: 10),
          Text(v, style: _koStyle(14.5, color: _kGold)),
        ],
      ),
    );
    return Column(
      children: [
        row('statTime', _fmtMin(s.minutesToday)),
        const Divider(color: Colors.white10, height: 8),
        row('statStudents', _people(s.studentsToday)),
        const Divider(color: Colors.white10, height: 8),
        row('statGoal', _people(s.goalToday)),
      ],
    );
  }

  // 7. 실시간 성취 알림 (오늘 1시간 이상 공부한 학생 · 레벨, 이름 가림)
  Widget _alertSection() {
    final List<Widget> rows = [];
    for (final PresenceInfo p in _top) {
      if (rows.length >= 5) break;
      final String name = p.uid == PresenceService.myUid ? p.name : PresenceService.maskName(p.name);
      if (p.todayMinutes >= 60) {
        rows.add(_alertRow(p.todayMinutes >= 180 ? '🔥' : '⭐', 'alertTime', {'name': name, 'time': _fmtMin(p.todayMinutes)}));
      }
      if (p.level >= 5 && rows.length < 5) {
        rows.add(_alertRow('👑', 'alertLevel', {'name': name, 'level': p.level}));
      }
    }
    if (rows.isEmpty) return _empty('noData');
    return Column(children: rows);
  }

  Widget _alertRow(String icon, String k, Map<String, Object> args) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 10),
          Expanded(child: _bi1(k, size: 13, color: Colors.white70, args: args, maxLines: 2)),
        ],
      ),
    );
  }

  // 8. 오늘 전체 과목 비율 (교과별 합계)
  Widget _subjectSection() {
    final List<int> cats = _stats!.categoryMinutes;
    final int total = cats.fold(0, (a, b) => a + b);
    if (total <= 0) return _empty('noData');
    final List<int> order = List<int>.generate(cats.length, (i) => i)..sort((a, b) => cats[b].compareTo(cats[a]));
    final List<int> shown = order.where((i) => cats[i] > 0).take(5).toList();
    final int rest = total - shown.fold(0, (a, i) => a + cats[i]);
    final List<_Slice> slices = [
      for (int j = 0; j < shown.length; j++)
        _Slice(subjectCategoryLabel(kSubjectCategories[shown[j]], _lang()), cats[shown[j]], _pieColors[j]),
      if (rest > 0) _Slice(_s('others'), rest, _pieColors[5]),
    ];
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 40,
              sections: [
                for (final _Slice sl in slices)
                  PieChartSectionData(
                    color: sl.color,
                    value: sl.minutes.toDouble(),
                    title: '${(sl.minutes * 100 / total).round()}%',
                    radius: 52,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final _Slice sl in slices)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: sl.color, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 12),
                Expanded(child: Text(sl.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _koStyle(13.5, color: Colors.white70, w: FontWeight.w600))),
                Text('${(sl.minutes * 100 / total).round()}%  ·  ${_fmtMin(sl.minutes)}', style: _koStyle(13, color: _kGold)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Slice {
  final String label;
  final int minutes;
  final Color color;
  const _Slice(this.label, this.minutes, this.color);
}
