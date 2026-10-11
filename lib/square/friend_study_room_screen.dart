// friend_study_room_screen.dart
//
// 🆕 [2026-10-11] 친구 학습방 — 가상 학생 5명 · 가상 방 · 폰 안에만 저장되던 방 모두 삭제
// - 방은 서버(studyRooms)에 만들어져 다른 학생 폰에서도 똑같이 보이고 함께 들어감
// - 참여 학생은 이름 + 학교 · 공부 중 여부 · 오늘 공부 시간 · 레벨 · 별이 보임 (5분마다 새로)
// - 👍 🔥 응원은 서버(cheers)로 진짜 전달되고, 오늘 받은 응원이 이름 옆에 보임
// - 글자체: 영문 = 진한 명조(고운바탕 굵게) / 한글 = 노토산스 KR / 10개 외국어 = 그 나라 말 한 줄

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsu_studyup/global_lang.dart';
import 'package:gsu_studyup/home_dashboard_screen.dart';
import 'package:gsu_studyup/services/presence_service.dart';
import 'package:gsu_studyup/services/study_room_service.dart';
import 'package:gsu_studyup/services/subject_category.dart';
import 'package:gsu_studyup/timer/timer_screen.dart';
import 'package:gsu_studyup/square/academic_timeline/academic_timeline_screen.dart'; // 🆕 [함께 공부] 학사 타임라인 연결 // 🆕 [함께 공부] 평소와 같은 타이머를 그대로 엶 (타이머 파일은 수정 안 함)
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const Color _kBg = Color(0xFF030712);
const Color _kCard = Color(0xFF0D1527);
const Color _kGold = Color(0xFFE5C158);
const Color _kWhite = Color(0xFFEFEFEF);
const Color _kCyan = Color(0xFF00F0FF);

const Map<String, Map<String, String>> _tx = {
  'title': {'KO': '친구 학습방', 'EN': 'Friends Study Room', 'JA': 'フレンド学習ルーム', 'ZH': '好友自习室', 'FR': 'Salle d\'étude entre amis', 'DE': 'Freunde-Lernraum', 'RU': 'Комната учёбы с друзьями', 'AR': 'غرفة الدراسة مع الأصدقاء', 'HI': 'मित्र अध्ययन कक्ष', 'VI': 'Phòng học cùng bạn', 'ES': 'Sala de estudio con amigos', 'TH': 'ห้องเรียนกับเพื่อน'},
  'createRoom': {'KO': '방 만들기', 'EN': 'Create Room', 'JA': 'ルームを作る', 'ZH': '创建房间', 'FR': 'Créer une salle', 'DE': 'Raum erstellen', 'RU': 'Создать комнату', 'AR': 'إنشاء غرفة', 'HI': 'कक्ष बनाएँ', 'VI': 'Tạo phòng', 'ES': 'Crear sala', 'TH': 'สร้างห้อง'},
  'noRooms': {'KO': '아직 열린 학습방이 없어요. 첫 방을 만들어 친구를 불러 보세요!', 'EN': 'No study rooms yet. Create the first one and invite your friends!', 'JA': 'まだルームがありません。最初のルームを作って友達を呼ぼう！', 'ZH': '还没有自习室。创建第一个房间邀请朋友吧！', 'FR': 'Aucune salle pour l\'instant. Crée la première et invite tes amis !', 'DE': 'Noch keine Räume. Erstelle den ersten und lade Freunde ein!', 'RU': 'Комнат пока нет. Создай первую и позови друзей!', 'AR': 'لا توجد غرف بعد. أنشئ أول غرفة وادعُ أصدقاءك!', 'HI': 'अभी कोई कक्ष नहीं। पहला कक्ष बनाकर दोस्तों को बुलाएँ!', 'VI': 'Chưa có phòng nào. Hãy tạo phòng đầu tiên và mời bạn bè!', 'ES': 'Aún no hay salas. ¡Crea la primera e invita a tus amigos!', 'TH': 'ยังไม่มีห้อง สร้างห้องแรกแล้วชวนเพื่อนกัน!'},
  'membersCount': {'KO': '{n} / {max}명', 'EN': '{n} / {max} members', 'JA': '{n} / {max}人', 'ZH': '{n} / {max}人', 'FR': '{n} / {max} membres', 'DE': '{n} / {max} Mitglieder', 'RU': '{n} / {max} участников', 'AR': '{n} / {max} أعضاء', 'HI': '{n} / {max} सदस्य', 'VI': '{n} / {max} người', 'ES': '{n} / {max} miembros', 'TH': '{n} / {max} คน'},
  'deleteRoom': {'KO': '방 삭제', 'EN': 'Delete Room', 'JA': 'ルーム削除', 'ZH': '删除房间', 'FR': 'Supprimer la salle', 'DE': 'Raum löschen', 'RU': 'Удалить комнату', 'AR': 'حذف الغرفة', 'HI': 'कक्ष हटाएँ', 'VI': 'Xóa phòng', 'ES': 'Eliminar sala', 'TH': 'ลบห้อง'},
  'deleteAsk': {'KO': '이 방을 정말 삭제할까요?', 'EN': 'Do you really want to delete this room?', 'JA': 'このルームを削除しますか？', 'ZH': '确定要删除这个房间吗？', 'FR': 'Supprimer vraiment cette salle ?', 'DE': 'Diesen Raum wirklich löschen?', 'RU': 'Удалить эту комнату?', 'AR': 'هل تريد حذف هذه الغرفة؟', 'HI': 'क्या यह कक्ष हटाना है?', 'VI': 'Bạn có chắc muốn xóa phòng này?', 'ES': '¿Seguro que quieres eliminar esta sala?', 'TH': 'ต้องการลบห้องนี้จริงไหม?'},
  'cancel': {'KO': '취소', 'EN': 'Cancel', 'JA': 'キャンセル', 'ZH': '取消', 'FR': 'Annuler', 'DE': 'Abbrechen', 'RU': 'Отмена', 'AR': 'إلغاء', 'HI': 'रद्द करें', 'VI': 'Hủy', 'ES': 'Cancelar', 'TH': 'ยกเลิก'},
  'delete': {'KO': '삭제', 'EN': 'Delete', 'JA': '削除', 'ZH': '删除', 'FR': 'Supprimer', 'DE': 'Löschen', 'RU': 'Удалить', 'AR': 'حذف', 'HI': 'हटाएँ', 'VI': 'Xóa', 'ES': 'Eliminar', 'TH': 'ลบ'},
  'create': {'KO': '만들기', 'EN': 'Create', 'JA': '作成', 'ZH': '创建', 'FR': 'Créer', 'DE': 'Erstellen', 'RU': 'Создать', 'AR': 'إنشاء', 'HI': 'बनाएँ', 'VI': 'Tạo', 'ES': 'Crear', 'TH': 'สร้าง'},
  'enter': {'KO': '입장', 'EN': 'Enter', 'JA': '入室', 'ZH': '进入', 'FR': 'Entrer', 'DE': 'Betreten', 'RU': 'Войти', 'AR': 'دخول', 'HI': 'प्रवेश', 'VI': 'Vào', 'ES': 'Entrar', 'TH': 'เข้า'},
  'roomFull': {'KO': '정원이 다 차서 들어갈 수 없어요.', 'EN': 'This room is full.', 'JA': '満員のため入れません。', 'ZH': '房间已满，无法进入。', 'FR': 'La salle est complète.', 'DE': 'Der Raum ist voll.', 'RU': 'Комната заполнена.', 'AR': 'الغرفة ممتلئة.', 'HI': 'कक्ष भरा हुआ है।', 'VI': 'Phòng đã đủ người.', 'ES': 'La sala está llena.', 'TH': 'ห้องเต็มแล้ว'},
  'roomName': {'KO': '방 이름', 'EN': 'Room name', 'JA': 'ルーム名', 'ZH': '房间名称', 'FR': 'Nom de la salle', 'DE': 'Raumname', 'RU': 'Название комнаты', 'AR': 'اسم الغرفة', 'HI': 'कक्ष का नाम', 'VI': 'Tên phòng', 'ES': 'Nombre de la sala', 'TH': 'ชื่อห้อง'},
  'maxUsers': {'KO': '최대 인원 (2~10명)', 'EN': 'Max members (2–10)', 'JA': '最大人数（2〜10人）', 'ZH': '最多人数（2~10人）', 'FR': 'Membres max (2–10)', 'DE': 'Max. Mitglieder (2–10)', 'RU': 'Макс. участников (2–10)', 'AR': 'الحد الأقصى (2–10)', 'HI': 'अधिकतम सदस्य (2–10)', 'VI': 'Tối đa (2–10 người)', 'ES': 'Máx. miembros (2–10)', 'TH': 'จำนวนสูงสุด (2–10 คน)'},
  'passwordOpt': {'KO': '비밀번호 (없어도 돼요)', 'EN': 'Password (optional)', 'JA': 'パスワード（任意）', 'ZH': '密码（可选）', 'FR': 'Mot de passe (facultatif)', 'DE': 'Passwort (optional)', 'RU': 'Пароль (необязательно)', 'AR': 'كلمة المرور (اختياري)', 'HI': 'पासवर्ड (वैकल्पिक)', 'VI': 'Mật khẩu (không bắt buộc)', 'ES': 'Contraseña (opcional)', 'TH': 'รหัสผ่าน (ไม่บังคับ)'},
  'enterPw': {'KO': '비밀번호 입력', 'EN': 'Enter password', 'JA': 'パスワード入力', 'ZH': '输入密码', 'FR': 'Saisir le mot de passe', 'DE': 'Passwort eingeben', 'RU': 'Введите пароль', 'AR': 'أدخل كلمة المرور', 'HI': 'पासवर्ड दर्ज करें', 'VI': 'Nhập mật khẩu', 'ES': 'Introduce la contraseña', 'TH': 'ใส่รหัสผ่าน'},
  'wrongPw': {'KO': '비밀번호가 맞지 않아요.', 'EN': 'Wrong password.', 'JA': 'パスワードが違います。', 'ZH': '密码错误。', 'FR': 'Mot de passe incorrect.', 'DE': 'Falsches Passwort.', 'RU': 'Неверный пароль.', 'AR': 'كلمة المرور غير صحيحة.', 'HI': 'गलत पासवर्ड।', 'VI': 'Sai mật khẩu.', 'ES': 'Contraseña incorrecta.', 'TH': 'รหัสผ่านไม่ถูกต้อง'},
  'needName': {'KO': '방 이름을 넣어 주세요.', 'EN': 'Please enter a room name.', 'JA': 'ルーム名を入力してください。', 'ZH': '请输入房间名称。', 'FR': 'Saisis un nom de salle.', 'DE': 'Bitte einen Raumnamen eingeben.', 'RU': 'Введите название комнаты.', 'AR': 'يرجى إدخال اسم الغرفة.', 'HI': 'कृपया कक्ष का नाम लिखें।', 'VI': 'Vui lòng nhập tên phòng.', 'ES': 'Escribe un nombre de sala.', 'TH': 'กรุณาใส่ชื่อห้อง'},
  'failed': {'KO': '잠시 후 다시 시도해 주세요.', 'EN': 'Something went wrong. Please try again.', 'JA': 'しばらくしてから再度お試しください。', 'ZH': '请稍后重试。', 'FR': 'Réessaie plus tard.', 'DE': 'Bitte später erneut versuchen.', 'RU': 'Попробуйте позже.', 'AR': 'حاول مرة أخرى لاحقًا.', 'HI': 'कृपया बाद में फिर कोशिश करें।', 'VI': 'Vui lòng thử lại sau.', 'ES': 'Inténtalo de nuevo más tarde.', 'TH': 'กรุณาลองใหม่ภายหลัง'},
  'roomStats': {'KO': '방 통계 (오늘)', 'EN': 'Room Statistics (Today)', 'JA': 'ルーム統計（今日）', 'ZH': '房间统计（今天）', 'FR': 'Statistiques de la salle (aujourd\'hui)', 'DE': 'Raumstatistik (heute)', 'RU': 'Статистика комнаты (сегодня)', 'AR': 'إحصائيات الغرفة (اليوم)', 'HI': 'कक्ष आँकड़े (आज)', 'VI': 'Thống kê phòng (hôm nay)', 'ES': 'Estadísticas de la sala (hoy)', 'TH': 'สถิติห้อง (วันนี้)'},
  'total': {'KO': '합계', 'EN': 'Total', 'JA': '合計', 'ZH': '合计', 'FR': 'Total', 'DE': 'Gesamt', 'RU': 'Всего', 'AR': 'المجموع', 'HI': 'कुल', 'VI': 'Tổng', 'ES': 'Total', 'TH': 'รวม'},
  'average': {'KO': '평균', 'EN': 'Average', 'JA': '平均', 'ZH': '平均', 'FR': 'Moyenne', 'DE': 'Durchschnitt', 'RU': 'В среднем', 'AR': 'المتوسط', 'HI': 'औसत', 'VI': 'Trung bình', 'ES': 'Promedio', 'TH': 'เฉลี่ย'},
  'members': {'KO': '참여 학생', 'EN': 'Members', 'JA': '参加メンバー', 'ZH': '参与学生', 'FR': 'Membres', 'DE': 'Mitglieder', 'RU': 'Участники', 'AR': 'الأعضاء', 'HI': 'सदस्य', 'VI': 'Thành viên', 'ES': 'Miembros', 'TH': 'สมาชิก'},
  'aloneHere': {'KO': '아직 나 혼자예요. 친구에게 방 이름을 알려 주세요!', 'EN': "You're the only one here. Tell your friends the room name!", 'JA': 'まだ自分だけです。友達にルーム名を教えよう！', 'ZH': '目前只有你一人，把房间名告诉朋友吧！', 'FR': 'Tu es seul ici. Donne le nom de la salle à tes amis !', 'DE': 'Du bist allein hier. Sag Freunden den Raumnamen!', 'RU': 'Пока ты один. Скажи друзьям название комнаты!', 'AR': 'أنت الوحيد هنا. أخبر أصدقاءك باسم الغرفة!', 'HI': 'अभी आप अकेले हैं। दोस्तों को कक्ष का नाम बताएँ!', 'VI': 'Bạn đang ở một mình. Hãy báo tên phòng cho bạn bè!', 'ES': 'Estás solo. ¡Dile a tus amigos el nombre de la sala!', 'TH': 'ตอนนี้มีแค่คุณ บอกชื่อห้องให้เพื่อนสิ!'},
  'studying': {'KO': '공부 중', 'EN': 'Studying', 'JA': '勉強中', 'ZH': '学习中', 'FR': 'Étudie', 'DE': 'Lernt', 'RU': 'Учится', 'AR': 'يدرس', 'HI': 'पढ़ रहे हैं', 'VI': 'Đang học', 'ES': 'Estudiando', 'TH': 'กำลังเรียน'},
  'resting': {'KO': '쉬는 중', 'EN': 'Resting', 'JA': '休憩中', 'ZH': '休息中', 'FR': 'En pause', 'DE': 'Pause', 'RU': 'Отдыхает', 'AR': 'يستريح', 'HI': 'आराम', 'VI': 'Đang nghỉ', 'ES': 'Descansando', 'TH': 'กำลังพัก'},
  'today': {'KO': '오늘', 'EN': 'Today', 'JA': '今日', 'ZH': '今天', 'FR': 'Aujourd\'hui', 'DE': 'Heute', 'RU': 'Сегодня', 'AR': 'اليوم', 'HI': 'आज', 'VI': 'Hôm nay', 'ES': 'Hoy', 'TH': 'วันนี้'},
  'cheer': {'KO': '칭찬', 'EN': 'Cheer', 'JA': 'いいね', 'ZH': '点赞', 'FR': 'Bravo', 'DE': 'Lob', 'RU': 'Похвала', 'AR': 'إشادة', 'HI': 'शाबाश', 'VI': 'Khen', 'ES': 'Bravo', 'TH': 'ชม'},
  'motivate': {'KO': '응원', 'EN': 'Motivate', 'JA': '応援', 'ZH': '加油', 'FR': 'Courage', 'DE': 'Anfeuern', 'RU': 'Поддержать', 'AR': 'تشجيع', 'HI': 'हौसला', 'VI': 'Cổ vũ', 'ES': 'Ánimo', 'TH': 'เชียร์'},
  'cheerSent': {'KO': '응원을 보냈어요!', 'EN': 'Cheer sent!', 'JA': '応援を送りました！', 'ZH': '已发送鼓励！', 'FR': 'Encouragement envoyé !', 'DE': 'Anfeuerung gesendet!', 'RU': 'Поддержка отправлена!', 'AR': 'تم إرسال التشجيع!', 'HI': 'प्रोत्साहन भेजा गया!', 'VI': 'Đã gửi lời cổ vũ!', 'ES': '¡Ánimo enviado!', 'TH': 'ส่งกำลังใจแล้ว!'},
  'cheersFrom': {'KO': '오늘 받은 응원', 'EN': 'Cheers received today', 'JA': '今日もらった応援', 'ZH': '今天收到的鼓励', 'FR': 'Encouragements reçus aujourd\'hui', 'DE': 'Heute erhaltene Anfeuerungen', 'RU': 'Поддержка за сегодня', 'AR': 'التشجيعات المستلمة اليوم', 'HI': 'आज मिले प्रोत्साहन', 'VI': 'Cổ vũ nhận hôm nay', 'ES': 'Ánimos recibidos hoy', 'TH': 'กำลังใจที่ได้รับวันนี้'},
  'me': {'KO': '나', 'EN': 'Me', 'JA': '自分', 'ZH': '我', 'FR': 'Moi', 'DE': 'Ich', 'RU': 'Я', 'AR': 'أنا', 'HI': 'मैं', 'VI': 'Tôi', 'ES': 'Yo', 'TH': 'ฉัน'},
  'studySettings': {'KO': '학습 설정', 'EN': 'Study Settings', 'JA': '学習設定', 'ZH': '学习设置', 'FR': 'Réglages d\'étude', 'DE': 'Lerneinstellungen', 'RU': 'Настройки учёбы', 'AR': 'إعدادات الدراسة', 'HI': 'अध्ययन सेटिंग', 'VI': 'Cài đặt học tập', 'ES': 'Ajustes de estudio', 'TH': 'ตั้งค่าการเรียน'},
  'refresh5': {'KO': '5분마다 새로 보여 줘요', 'EN': 'Updated every 5 minutes', 'JA': '5分ごとに更新', 'ZH': '每5分钟更新', 'FR': 'Mis à jour toutes les 5 min', 'DE': 'Alle 5 Minuten aktualisiert', 'RU': 'Обновляется каждые 5 минут', 'AR': 'يتم التحديث كل 5 دقائق', 'HI': 'हर 5 मिनट में अपडेट', 'VI': 'Cập nhật mỗi 5 phút', 'ES': 'Se actualiza cada 5 minutos', 'TH': 'อัปเดตทุก 5 นาที'},
  'openRooms': {'KO': '열린 학습방', 'EN': 'Open Study Rooms', 'JA': '開いている学習ルーム', 'ZH': '开放的自习室', 'FR': 'Salles ouvertes', 'DE': 'Offene Lernräume', 'RU': 'Открытые комнаты', 'AR': 'الغرف المفتوحة', 'HI': 'खुले अध्ययन कक्ष', 'VI': 'Phòng học đang mở', 'ES': 'Salas abiertas', 'TH': 'ห้องเรียนที่เปิดอยู่'},
  'studyRoom': {'KO': '함께 공부하는 방', 'EN': 'Study Together Room', 'JA': '一緒に勉強するルーム', 'ZH': '一起学习的房间', 'FR': 'Salle d\'étude commune', 'DE': 'Gemeinsamer Lernraum', 'RU': 'Комната совместной учёбы', 'AR': 'غرفة الدراسة المشتركة', 'HI': 'साथ पढ़ने का कक्ष', 'VI': 'Phòng học cùng nhau', 'ES': 'Sala de estudio en grupo', 'TH': 'ห้องเรียนด้วยกัน'},
  'members2': {'KO': '참여', 'EN': 'Members', 'JA': '参加', 'ZH': '参与', 'FR': 'Membres', 'DE': 'Mitglieder', 'RU': 'Участники', 'AR': 'الأعضاء', 'HI': 'सदस्य', 'VI': 'Thành viên', 'ES': 'Miembros', 'TH': 'สมาชิก'},
  'locked': {'KO': '비밀번호 방', 'EN': 'Private', 'JA': 'パスワード付き', 'ZH': '密码房', 'FR': 'Privée', 'DE': 'Privat', 'RU': 'С паролем', 'AR': 'خاصة', 'HI': 'निजी', 'VI': 'Có mật khẩu', 'ES': 'Privada', 'TH': 'มีรหัสผ่าน'},
  'open': {'KO': '누구나 입장', 'EN': 'Open to all', 'JA': '誰でも入室', 'ZH': '任何人可进', 'FR': 'Ouverte', 'DE': 'Offen', 'RU': 'Открыта', 'AR': 'مفتوحة للجميع', 'HI': 'सभी के लिए', 'VI': 'Ai cũng vào được', 'ES': 'Abierta', 'TH': 'ใครก็เข้าได้'},
  'close': {'KO': '닫기', 'EN': 'Close', 'JA': '閉じる', 'ZH': '关闭', 'FR': 'Fermer', 'DE': 'Schließen', 'RU': 'Закрыть', 'AR': 'إغلاق', 'HI': 'बंद करें', 'VI': 'Đóng', 'ES': 'Cerrar', 'TH': 'ปิด'},
  // 🆕 [함께 공부 2026-10-11]
  'groupStart': {'KO': '함께 공부 시작', 'EN': 'Start Group Study', 'JA': '一緒に勉強を開始', 'ZH': '开始一起学习', 'FR': 'Lancer l\'étude en groupe', 'DE': 'Gruppenlernen starten', 'RU': 'Начать совместную учёбу', 'AR': 'ابدأ الدراسة الجماعية', 'HI': 'साथ पढ़ाई शुरू करें', 'VI': 'Bắt đầu học cùng nhau', 'ES': 'Iniciar estudio en grupo', 'TH': 'เริ่มเรียนด้วยกัน'},
  'hostTag': {'KO': '방장', 'EN': 'Host', 'JA': 'ホスト', 'ZH': '房主', 'FR': 'Hôte', 'DE': 'Gastgeber', 'RU': 'Хозяин', 'AR': 'المضيف', 'HI': 'होस्ट', 'VI': 'Chủ phòng', 'ES': 'Anfitrión', 'TH': 'หัวหน้าห้อง'},
  'setSubject': {'KO': '과목', 'EN': 'Subject', 'JA': '科目', 'ZH': '科目', 'FR': 'Matière', 'DE': 'Fach', 'RU': 'Предмет', 'AR': 'المادة', 'HI': 'विषय', 'VI': 'Môn học', 'ES': 'Materia', 'TH': 'วิชา'},
  'setMinutes': {'KO': '공부 시간', 'EN': 'Study time', 'JA': '学習時間', 'ZH': '学习时间', 'FR': 'Durée d\'étude', 'DE': 'Lernzeit', 'RU': 'Время учёбы', 'AR': 'وقت الدراسة', 'HI': 'अध्ययन समय', 'VI': 'Thời gian học', 'ES': 'Tiempo de estudio', 'TH': 'เวลาเรียน'},
  'setExam': {'KO': '시험 종류', 'EN': 'Exam type', 'JA': '試験の種類', 'ZH': '考试类型', 'FR': 'Type d\'examen', 'DE': 'Prüfungsart', 'RU': 'Тип экзамена', 'AR': 'نوع الاختبار', 'HI': 'परीक्षा प्रकार', 'VI': 'Loại kỳ thi', 'ES': 'Tipo de examen', 'TH': 'ประเภทการสอบ'},
  'setSound': {'KO': '백색소음', 'EN': 'White noise', 'JA': 'ホワイトノイズ', 'ZH': '白噪音', 'FR': 'Bruit blanc', 'DE': 'Weißes Rauschen', 'RU': 'Белый шум', 'AR': 'الضوضاء البيضاء', 'HI': 'व्हाइट नॉइज़', 'VI': 'Tiếng ồn trắng', 'ES': 'Ruido blanco', 'TH': 'เสียงไวท์นอยส์'},
  'none': {'KO': '없음', 'EN': 'None', 'JA': 'なし', 'ZH': '无', 'FR': 'Aucun', 'DE': 'Keins', 'RU': 'Нет', 'AR': 'لا شيء', 'HI': 'कोई नहीं', 'VI': 'Không', 'ES': 'Ninguno', 'TH': 'ไม่มี'},
  'startNow': {'KO': '시작', 'EN': 'Start', 'JA': '開始', 'ZH': '开始', 'FR': 'Démarrer', 'DE': 'Start', 'RU': 'Начать', 'AR': 'ابدأ', 'HI': 'शुरू', 'VI': 'Bắt đầu', 'ES': 'Iniciar', 'TH': 'เริ่ม'},
  'joinTogether': {'KO': '같이 시작', 'EN': 'Start Together', 'JA': '一緒に開始', 'ZH': '一起开始', 'FR': 'Commencer ensemble', 'DE': 'Zusammen starten', 'RU': 'Начать вместе', 'AR': 'ابدأ معًا', 'HI': 'साथ शुरू करें', 'VI': 'Bắt đầu cùng', 'ES': 'Empezar juntos', 'TH': 'เริ่มพร้อมกัน'},
  'startLater': {'KO': '나중에 시작', 'EN': 'Start Later', 'JA': '後で開始', 'ZH': '稍后开始', 'FR': 'Plus tard', 'DE': 'Später starten', 'RU': 'Начать позже', 'AR': 'ابدأ لاحقًا', 'HI': 'बाद में शुरू करें', 'VI': 'Bắt đầu sau', 'ES': 'Empezar después', 'TH': 'เริ่มทีหลัง'},
  'startMine': {'KO': '지금 시작', 'EN': 'Start Now', 'JA': '今すぐ開始', 'ZH': '现在开始', 'FR': 'Commencer maintenant', 'DE': 'Jetzt starten', 'RU': 'Начать сейчас', 'AR': 'ابدأ الآن', 'HI': 'अभी शुरू करें', 'VI': 'Bắt đầu ngay', 'ES': 'Empezar ahora', 'TH': 'เริ่มตอนนี้'},
  'sessionPopup': {'KO': '{host}님이 함께 공부를 시작했어요!', 'EN': '{host} started a group study!', 'JA': '{host}さんが一緒に勉強を始めました！', 'ZH': '{host}开始了一起学习！', 'FR': '{host} a lancé une étude en groupe !', 'DE': '{host} hat Gruppenlernen gestartet!', 'RU': '{host} начал совместную учёбу!', 'AR': 'بدأ {host} دراسة جماعية!', 'HI': '{host} ने साथ पढ़ाई शुरू की!', 'VI': '{host} đã bắt đầu học cùng nhau!', 'ES': '¡{host} inició un estudio en grupo!', 'TH': '{host} เริ่มเรียนด้วยกันแล้ว!'},
  'groupNow': {'KO': '함께 공부 중', 'EN': 'Group Study in Progress', 'JA': '一緒に勉強中', 'ZH': '一起学习中', 'FR': 'Étude en groupe en cours', 'DE': 'Gruppenlernen läuft', 'RU': 'Идёт совместная учёба', 'AR': 'الدراسة الجماعية جارية', 'HI': 'साथ पढ़ाई जारी', 'VI': 'Đang học cùng nhau', 'ES': 'Estudio en grupo en curso', 'TH': 'กำลังเรียนด้วยกัน'},
  'groupDone': {'KO': '오늘의 함께 공부 (끝남)', 'EN': "Today's Group Study (ended)", 'JA': '今日の一緒に勉強（終了）', 'ZH': '今日一起学习（已结束）', 'FR': 'Étude en groupe du jour (terminée)', 'DE': 'Heutiges Gruppenlernen (beendet)', 'RU': 'Совместная учёба сегодня (завершена)', 'AR': 'الدراسة الجماعية اليوم (انتهت)', 'HI': 'आज की साथ पढ़ाई (समाप्त)', 'VI': 'Buổi học chung hôm nay (đã xong)', 'ES': 'Estudio en grupo de hoy (terminado)', 'TH': 'เรียนด้วยกันวันนี้ (จบแล้ว)'},
  'leftTime': {'KO': '{t} 남음', 'EN': '{t} left', 'JA': '残り{t}', 'ZH': '剩余{t}', 'FR': 'Reste {t}', 'DE': 'Noch {t}', 'RU': 'Осталось {t}', 'AR': 'متبقٍ {t}', 'HI': '{t} बाकी', 'VI': 'Còn {t}', 'ES': 'Quedan {t}', 'TH': 'เหลือ {t}'},
  'togetherHint': {'KO': '같이 시작하면 방장과 같은 시각에 끝나요. 나중에 시작하면 그때부터 정해진 시간만큼 공부해요. 학습 기록장은 각자 따로 저장돼요.', 'EN': 'Start Together ends at the same time as the host. Start Later gives you the full time from when you begin. Study logs are saved separately for each student.', 'JA': '「一緒に開始」はホストと同じ時刻に終わります。「後で開始」は開始時から決められた時間だけ勉強します。学習記録は各自で保存されます。', 'ZH': '“一起开始”与房主同时结束；“稍后开始”从你开始时计算完整时间。学习记录各自单独保存。', 'FR': '« Commencer ensemble » finit en même temps que l\'hôte. « Plus tard » te donne la durée complète. Les journaux d\'étude sont enregistrés séparément.', 'DE': '„Zusammen starten“ endet gleichzeitig mit dem Gastgeber. „Später“ gibt dir die volle Zeit ab deinem Start. Lernprotokolle werden einzeln gespeichert.', 'RU': '«Начать вместе» закончится одновременно с хозяином. «Позже» — полное время с момента старта. Дневники учёбы сохраняются отдельно.', 'AR': '«ابدأ معًا» ينتهي مع المضيف. «لاحقًا» يمنحك الوقت كاملًا من لحظة البدء. تُحفظ سجلات الدراسة لكل طالب على حدة.', 'HI': '"साथ शुरू" होस्ट के साथ ही खत्म होगा। "बाद में" शुरू करने पर पूरा समय मिलेगा। अध्ययन रिकॉर्ड अलग-अलग सहेजे जाते हैं।', 'VI': '"Bắt đầu cùng" kết thúc cùng lúc với chủ phòng. "Bắt đầu sau" tính đủ thời gian từ lúc bạn bắt đầu. Nhật ký học được lưu riêng.', 'ES': '«Empezar juntos» termina a la vez que el anfitrión. «Después» te da el tiempo completo. Los registros se guardan por separado.', 'TH': '"เริ่มพร้อมกัน" จะจบพร้อมหัวหน้าห้อง "เริ่มทีหลัง" จะได้เวลาเต็มนับจากตอนเริ่ม บันทึกการเรียนแยกของแต่ละคน'},
  'chooseSubject': {'KO': '과목을 골라 주세요.', 'EN': 'Please choose a subject.', 'JA': '科目を選んでください。', 'ZH': '请选择科目。', 'FR': 'Choisis une matière.', 'DE': 'Bitte ein Fach wählen.', 'RU': 'Выберите предмет.', 'AR': 'يرجى اختيار مادة.', 'HI': 'कृपया विषय चुनें।', 'VI': 'Vui lòng chọn môn học.', 'ES': 'Elige una materia.', 'TH': 'กรุณาเลือกวิชา'},
  'hostStarted': {'KO': '내가 시작한 함께 공부', 'EN': 'Group study I started', 'JA': '自分が始めた一緒に勉強', 'ZH': '我发起的一起学习', 'FR': 'Étude en groupe que j\'ai lancée', 'DE': 'Von mir gestartetes Gruppenlernen', 'RU': 'Совместная учёба, которую я начал', 'AR': 'دراسة جماعية بدأتها', 'HI': 'मेरे द्वारा शुरू की गई साथ पढ़ाई', 'VI': 'Buổi học chung tôi bắt đầu', 'ES': 'Estudio en grupo que inicié', 'TH': 'การเรียนด้วยกันที่ฉันเริ่ม'},
  // 🆕 [초대 2026-10-11]
  'inviteFriends': {'KO': '친구 초대', 'EN': 'Invite Friends', 'JA': '友達を招待', 'ZH': '邀请朋友', 'FR': 'Inviter des amis', 'DE': 'Freunde einladen', 'RU': 'Пригласить друзей', 'AR': 'دعوة الأصدقاء', 'HI': 'दोस्तों को बुलाएँ', 'VI': 'Mời bạn bè', 'ES': 'Invitar amigos', 'TH': 'ชวนเพื่อน'},
  'inviteSend': {'KO': '초대 보내기', 'EN': 'Send Invites', 'JA': '招待を送る', 'ZH': '发送邀请', 'FR': 'Envoyer', 'DE': 'Einladen', 'RU': 'Отправить', 'AR': 'إرسال الدعوات', 'HI': 'निमंत्रण भेजें', 'VI': 'Gửi lời mời', 'ES': 'Enviar invitaciones', 'TH': 'ส่งคำชวน'},
  'inviteTitle': {'KO': '학습방 초대', 'EN': 'Study Room Invitation', 'JA': '学習ルームへの招待', 'ZH': '自习室邀请', 'FR': 'Invitation à une salle', 'DE': 'Einladung in einen Lernraum', 'RU': 'Приглашение в комнату', 'AR': 'دعوة إلى غرفة دراسة', 'HI': 'अध्ययन कक्ष निमंत्रण', 'VI': 'Lời mời vào phòng học', 'ES': 'Invitación a una sala', 'TH': 'คำชวนเข้าห้องเรียน'},
  'inviteBody': {'KO': '{host}님이 \'{room}\' 방에 초대했어요', 'EN': '{host} invited you to "{room}"', 'JA': '{host}さんが「{room}」に招待しました', 'ZH': '{host}邀请你加入「{room}」', 'FR': '{host} t\'invite dans « {room} »', 'DE': '{host} lädt dich in „{room}“ ein', 'RU': '{host} приглашает тебя в «{room}»', 'AR': 'دعاك {host} إلى «{room}»', 'HI': '{host} ने आपको "{room}" में बुलाया', 'VI': '{host} mời bạn vào "{room}"', 'ES': '{host} te invitó a «{room}»', 'TH': '{host} ชวนคุณเข้าห้อง "{room}"'},
  'accept': {'KO': '수락', 'EN': 'Accept', 'JA': '承諾', 'ZH': '接受', 'FR': 'Accepter', 'DE': 'Annehmen', 'RU': 'Принять', 'AR': 'قبول', 'HI': 'स्वीकार', 'VI': 'Đồng ý', 'ES': 'Aceptar', 'TH': 'ตอบรับ'},
  'decline': {'KO': '거절', 'EN': 'Decline', 'JA': '断る', 'ZH': '拒绝', 'FR': 'Refuser', 'DE': 'Ablehnen', 'RU': 'Отклонить', 'AR': 'رفض', 'HI': 'अस्वीकार', 'VI': 'Từ chối', 'ES': 'Rechazar', 'TH': 'ปฏิเสธ'},
  'invitesSent': {'KO': '{n}명에게 초대를 보냈어요', 'EN': 'Invitations sent to {n}', 'JA': '{n}人に招待を送りました', 'ZH': '已向{n}人发送邀请', 'FR': 'Invitations envoyées à {n}', 'DE': 'Einladungen an {n} gesendet', 'RU': 'Приглашения отправлены: {n}', 'AR': 'تم إرسال الدعوة إلى {n}', 'HI': '{n} लोगों को निमंत्रण भेजा', 'VI': 'Đã gửi lời mời tới {n} người', 'ES': 'Invitaciones enviadas a {n}', 'TH': 'ส่งคำชวนถึง {n} คนแล้ว'},
  'inviteCooldown': {'KO': '{name}님은 거절한 지 1시간이 지나지 않아 다시 초대할 수 없어요', 'EN': "{name} declined less than an hour ago and can't be invited yet", 'JA': '{name}さんは断ってから1時間経っていないため招待できません', 'ZH': '{name}拒绝未满1小时，暂时无法再次邀请', 'FR': '{name} a refusé il y a moins d\'une heure', 'DE': '{name} hat vor weniger als 1 Stunde abgelehnt', 'RU': '{name} отказался менее часа назад', 'AR': 'رفض {name} قبل أقل من ساعة', 'HI': '{name} ने एक घंटे से कम पहले मना किया', 'VI': '{name} vừa từ chối chưa đầy 1 giờ', 'ES': '{name} rechazó hace menos de una hora', 'TH': '{name} ปฏิเสธไม่ถึง 1 ชั่วโมง'},
  'noClassmates': {'KO': '초대할 같은 학교 · 학년 친구가 아직 없어요.', 'EN': 'No classmates from your school & grade to invite yet.', 'JA': '招待できる同じ学校・学年の友達がまだいません。', 'ZH': '还没有可邀请的同校同年级朋友。', 'FR': 'Aucun camarade à inviter pour l\'instant.', 'DE': 'Noch keine Mitschüler zum Einladen.', 'RU': 'Пока некого пригласить.', 'AR': 'لا يوجد زملاء لدعوتهم بعد.', 'HI': 'अभी बुलाने के लिए कोई सहपाठी नहीं।', 'VI': 'Chưa có bạn cùng trường, cùng khối để mời.', 'ES': 'Aún no hay compañeros para invitar.', 'TH': 'ยังไม่มีเพื่อนร่วมชั้นให้ชวน'},
  'pickFriends': {'KO': '초대할 친구를 골라 주세요.', 'EN': 'Choose friends to invite.', 'JA': '招待する友達を選んでください。', 'ZH': '请选择要邀请的朋友。', 'FR': 'Choisis des amis à inviter.', 'DE': 'Wähle Freunde zum Einladen.', 'RU': 'Выберите друзей.', 'AR': 'اختر الأصدقاء لدعوتهم.', 'HI': 'बुलाने के लिए दोस्त चुनें।', 'VI': 'Hãy chọn bạn để mời.', 'ES': 'Elige amigos para invitar.', 'TH': 'เลือกเพื่อนที่จะชวน'},
  'onlineNow': {'KO': '접속 중', 'EN': 'Online', 'JA': '接続中', 'ZH': '在线', 'FR': 'En ligne', 'DE': 'Online', 'RU': 'В сети', 'AR': 'متصل', 'HI': 'ऑनलाइन', 'VI': 'Trực tuyến', 'ES': 'En línea', 'TH': 'ออนไลน์'},
  'inviteHint': {'KO': '초대는 10분 동안 남아 있어요. 친구가 앱을 켜 두었으면 바로, 아니면 앱을 여는 순간 팝업이 떠요.', 'EN': 'Invites last 10 minutes. Friends see a popup right away if the app is open, or as soon as they open it.', 'JA': '招待は10分間有効です。アプリを開いていればすぐに、閉じていれば開いた時に表示されます。', 'ZH': '邀请保留10分钟。朋友打开应用时会立即弹出。', 'FR': 'Les invitations durent 10 min et s\'affichent dès que l\'appli est ouverte.', 'DE': 'Einladungen gelten 10 Minuten und erscheinen, sobald die App offen ist.', 'RU': 'Приглашение действует 10 минут и появится, когда приложение открыто.', 'AR': 'تبقى الدعوة 10 دقائق وتظهر عند فتح التطبيق.', 'HI': 'निमंत्रण 10 मिनट रहता है; ऐप खुलते ही दिखता है।', 'VI': 'Lời mời giữ 10 phút, hiện ngay khi bạn bè mở ứng dụng.', 'ES': 'Las invitaciones duran 10 minutos y aparecen al abrir la app.', 'TH': 'คำชวนอยู่ได้ 10 นาที จะเด้งขึ้นเมื่อเพื่อนเปิดแอป'},
  // 🆕 [함께 공부 설정 팝업 2026-10-11]
  'setMode': {'KO': '학사 모드', 'EN': 'Academic mode', 'JA': '学事モード', 'ZH': '学习阶段', 'FR': 'Période scolaire', 'DE': 'Schulphase', 'RU': 'Учебный период', 'AR': 'الفترة الدراسية', 'HI': 'शैक्षणिक मोड', 'VI': 'Giai đoạn học', 'ES': 'Periodo académico', 'TH': 'ช่วงการเรียน'},
  'modeNormal': {'KO': '평상시', 'EN': 'Normal', 'JA': '通常', 'ZH': '平时', 'FR': 'Normal', 'DE': 'Normal', 'RU': 'Обычно', 'AR': 'عادي', 'HI': 'सामान्य', 'VI': 'Bình thường', 'ES': 'Normal', 'TH': 'ปกติ'},
  'modeVacation': {'KO': '방학', 'EN': 'Vacation', 'JA': '休み', 'ZH': '假期', 'FR': 'Vacances', 'DE': 'Ferien', 'RU': 'Каникулы', 'AR': 'العطلة', 'HI': 'छुट्टी', 'VI': 'Kỳ nghỉ', 'ES': 'Vacaciones', 'TH': 'ปิดเทอม'},
  'modeExamBefore': {'KO': '시험 준비', 'EN': 'Exam Prep', 'JA': '試験準備', 'ZH': '备考', 'FR': 'Préparation aux examens', 'DE': 'Prüfungsvorbereitung', 'RU': 'Подготовка к экзаменам', 'AR': 'التحضير للاختبار', 'HI': 'परीक्षा की तैयारी', 'VI': 'Ôn thi', 'ES': 'Preparación de exámenes', 'TH': 'เตรียมสอบ'},
  'modeExamDuring': {'KO': '시험 중', 'EN': 'During Exams', 'JA': '試験期間中', 'ZH': '考试期间', 'FR': 'Pendant les examens', 'DE': 'Während der Prüfungen', 'RU': 'Во время экзаменов', 'AR': 'أثناء الاختبارات', 'HI': 'परीक्षा के दौरान', 'VI': 'Trong kỳ thi', 'ES': 'Durante los exámenes', 'TH': 'ช่วงสอบ'},
  'tapToChoose': {'KO': '눌러서 고르기', 'EN': 'Tap to choose', 'JA': 'タップして選択', 'ZH': '点击选择', 'FR': 'Touche pour choisir', 'DE': 'Zum Auswählen tippen', 'RU': 'Нажмите, чтобы выбрать', 'AR': 'اضغط للاختيار', 'HI': 'चुनने के लिए टैप करें', 'VI': 'Chạm để chọn', 'ES': 'Toca para elegir', 'TH': 'แตะเพื่อเลือก'},
  // 🆕 [함께 공부 갈래 2026-10-11]
  'groupMenuTimeline': {'KO': '학사 타임라인', 'EN': 'Academic Timeline', 'JA': '学事タイムライン', 'ZH': '学业时间线', 'FR': 'Calendrier scolaire', 'DE': 'Schul-Zeitplan', 'RU': 'Учебный график', 'AR': 'الجدول الأكاديمي', 'HI': 'शैक्षणिक समयरेखा', 'VI': 'Lịch học tập', 'ES': 'Calendario académico', 'TH': 'ไทม์ไลน์การเรียน'},
  'groupMenuTimelineDesc': {'KO': '학사 타이머 시간표로 공부해요. 타이머를 켜는 순간 친구들에게 함께 시작 팝업이 가요.', 'EN': 'Study with the academic timer. Friends get a join popup the moment you start.', 'JA': '学事タイマーの時間割で勉強。開始と同時に友達へ通知されます。', 'ZH': '按学业计时器的课表学习，开始时朋友会收到一起开始的弹窗。', 'FR': 'Étudie avec le minuteur scolaire ; tes amis reçoivent une invitation dès le départ.', 'DE': 'Lerne mit dem Schul-Timer; Freunde erhalten beim Start ein Popup.', 'RU': 'Учись по учебному таймеру — друзья получат приглашение при старте.', 'AR': 'ادرس بمؤقت الجدول الأكاديمي؛ يصل أصدقاءك إشعار عند البدء.', 'HI': 'शैक्षणिक टाइमर से पढ़ें; शुरू करते ही दोस्तों को पॉपअप जाएगा।', 'VI': 'Học theo hẹn giờ học tập; bạn bè nhận thông báo khi bạn bắt đầu.', 'ES': 'Estudia con el temporizador académico; tus amigos reciben aviso al empezar.', 'TH': 'เรียนตามตัวจับเวลาการเรียน เพื่อนจะได้รับป๊อปอัปทันทีที่เริ่ม'},
  'groupMenuFree': {'KO': '자유 과목', 'EN': 'Free Subject', 'JA': '自由科目', 'ZH': '自由科目', 'FR': 'Matière libre', 'DE': 'Freies Fach', 'RU': 'Свободный предмет', 'AR': 'مادة حرة', 'HI': 'मुक्त विषय', 'VI': 'Môn tự chọn', 'ES': 'Materia libre', 'TH': 'วิชาอิสระ'},
  'groupMenuFreeDesc': {'KO': '과목 · 공부 시간 · 시험 종류 · 백색소음을 직접 골라 시작해요.', 'EN': 'Choose subject, study time, exam type and white noise yourself.', 'JA': '科目・時間・試験・ホワイトノイズを自分で選んで開始。', 'ZH': '自行选择科目、时间、考试类型和白噪音后开始。', 'FR': 'Choisis matière, durée, examen et bruit blanc.', 'DE': 'Fach, Zeit, Prüfung und Rauschen selbst wählen.', 'RU': 'Выбери предмет, время, экзамен и белый шум.', 'AR': 'اختر المادة والوقت ونوع الاختبار والضوضاء البيضاء.', 'HI': 'विषय, समय, परीक्षा और व्हाइट नॉइज़ खुद चुनें।', 'VI': 'Tự chọn môn, thời gian, kỳ thi và tiếng ồn trắng.', 'ES': 'Elige materia, tiempo, examen y ruido blanco.', 'TH': 'เลือกวิชา เวลา ประเภทสอบ และเสียงเอง'},
  'roomGone': {'KO': '방이 삭제되었어요.', 'EN': 'This room has been deleted.', 'JA': 'ルームは削除されました。', 'ZH': '房间已被删除。', 'FR': 'La salle a été supprimée.', 'DE': 'Der Raum wurde gelöscht.', 'RU': 'Комната удалена.', 'AR': 'تم حذف الغرفة.', 'HI': 'कक्ष हटा दिया गया।', 'VI': 'Phòng đã bị xóa.', 'ES': 'La sala ha sido eliminada.', 'TH': 'ห้องถูกลบแล้ว'},
};

bool get _foreign => DkeLang.isForeignSelected;
String _lang() => _foreign ? DkeLang.current : 'KO';

String _s(String k, [Map<String, Object>? args]) {
  final Map<String, String>? m = _tx[k];
  String v = m == null ? k : (m[_lang()] ?? m['EN'] ?? m['KO'] ?? k);
  args?.forEach((a, b) => v = v.replaceAll('{$a}', '$b'));
  return v;
}

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

/// 두 줄: 영문(진한 명조) 위 + 한글(노토산스) 아래 / 외국어는 한 줄
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

/// 한 줄: 영문(명조) + 한글(노토산스) / 외국어는 그 나라 말
Widget _bi1(String k, {double size = 13, Color color = _kWhite, Map<String, Object>? args, int maxLines = 1, TextAlign ta = TextAlign.start}) {
  if (_foreign) {
    return Text(_s(k, args), textAlign: ta, maxLines: maxLines, overflow: TextOverflow.ellipsis, style: _koStyle(size, color: color, w: FontWeight.w600));
  }
  return Text.rich(
    TextSpan(children: [
      TextSpan(text: '${_e(k, args)}  ', style: _enStyle(size - 1, color: color.withValues(alpha: 0.75))),
      TextSpan(text: _s(k, args), style: _koStyle(size, color: color, w: FontWeight.w600)),
    ]),
    textAlign: ta,
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
  );
}

String _fmtMin(int m) {
  final int h = m ~/ 60, r = m % 60;
  if (_lang() == 'KO') return h > 0 ? '$h시간 ${r.toString().padLeft(2, '0')}분' : '$r분';
  return h > 0 ? '${h}h ${r.toString().padLeft(2, '0')}m' : '${r}m';
}

void _snack(BuildContext context, String k, {Color bg = _kCard}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(backgroundColor: bg, content: _bi1(k, size: 13.5, color: _kGold, maxLines: 3)),
  );
}

// ============================================================================
// 🎨 [2026-10-11] 고급 디자인 부품 — 금테 · 어두운 남색 그라데이션 · 은은한 금빛
// ============================================================================
const Color _kGoldDeep = Color(0xFFB8962E);
const LinearGradient _kCardGrad = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF141E36), Color(0xFF0A1020)],
);
const LinearGradient _kGoldGrad = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF6DD8A), Color(0xFFD4AF37)],
);

BoxDecoration _luxBox({bool bright = false, double radius = 16}) => BoxDecoration(
  gradient: _kCardGrad,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: _kGold.withValues(alpha: bright ? 0.85 : 0.35), width: bright ? 1.4 : 1),
  boxShadow: [
    BoxShadow(color: _kGold.withValues(alpha: bright ? 0.18 : 0.06), blurRadius: bright ? 16 : 8, offset: const Offset(0, 3)),
  ],
);

/// 금색 버튼 (꽉 찬)
Widget _goldButton({required Widget child, required VoidCallback? onTap, double height = 48, IconData? icon}) {
  return Opacity(
    opacity: onTap == null ? 0.5 : 1,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: _kGoldGrad,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: _kGold.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, color: Colors.black, size: 20), const SizedBox(width: 8)],
            Flexible(child: child),
          ],
        ),
      ),
    ),
  );
}

/// 금테 버튼 (속이 빈)
Widget _outlineButton({required Widget child, required VoidCallback onTap, Color color = _kGold, double height = 44}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: child,
    ),
  );
}

/// 입력 칸
Widget _luxField(TextEditingController c, String k, {bool obscure = false, TextInputType? type, int? maxLength, bool autofocus = false, IconData? icon}) {
  return TextField(
    controller: c,
    obscureText: obscure,
    keyboardType: type,
    maxLength: maxLength,
    autofocus: autofocus,
    style: _koStyle(15, color: Colors.white, w: FontWeight.w500),
    cursorColor: _kGold,
    decoration: InputDecoration(
      label: _bi1(k, size: 12.5, color: Colors.white70),
      prefixIcon: icon == null ? null : Icon(icon, color: _kGold, size: 20),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      counterStyle: _koStyle(10.5, color: Colors.white38, w: FontWeight.normal),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _kGold.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kGold, width: 1.4),
      ),
    ),
  );
}

/// 금테 팝업 (가운데) — 위: 아이콘 + 영문/한글 제목, 가운데: 내용, 아래: 버튼
Future<T?> _showLuxDialog<T>(
    BuildContext context, {
      required IconData icon,
      required String titleKey,
      required Widget Function(BuildContext ctx, StateSetter setD) content,
      required List<Widget> Function(BuildContext ctx, StateSetter setD) actions,
      Color accent = _kGold,
    }) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (dctx) => StatefulBuilder(
      builder: (ctx, setD) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            gradient: _kCardGrad,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.9), width: 1.5),
            boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.22), blurRadius: 24)],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.12),
                    border: Border.all(color: accent.withValues(alpha: 0.7)),
                  ),
                  child: Icon(icon, color: accent, size: 26),
                ),
                const SizedBox(height: 12),
                _bi2(titleKey, size: 18, color: accent, align: CrossAxisAlignment.center, ta: TextAlign.center),
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.transparent, accent.withValues(alpha: 0.6), Colors.transparent]),
                  ),
                ),
                const SizedBox(height: 18),
                content(ctx, setD),
                const SizedBox(height: 20),
                Row(children: actions(ctx, setD)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _avatar(String name, {bool active = false, double size = 42}) {
  final String t = name.trim().isEmpty ? '?' : String.fromCharCode(name.trim().runes.first);
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: active ? _kGoldGrad : const LinearGradient(colors: [Color(0xFF2A3350), Color(0xFF1A2138)]),
      border: Border.all(color: active ? _kGold : Colors.white24, width: 1.2),
      boxShadow: active ? [BoxShadow(color: _kGold.withValues(alpha: 0.35), blurRadius: 10)] : null,
    ),
    child: Text(t, style: _koStyle(size * 0.42, color: active ? Colors.black : Colors.white70)),
  );
}

Widget _statusChip(bool studying) {
  final Color c = studying ? _kCyan : Colors.white38;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: c.withValues(alpha: 0.5)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c,
            boxShadow: studying ? [BoxShadow(color: c.withValues(alpha: 0.8), blurRadius: 6)] : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(_s(studying ? 'studying' : 'resting'), style: _koStyle(11, color: c)),
      ],
    ),
  );
}

// ============================================================================
// 방 목록
// ============================================================================
class FriendStudyRoomScreen extends StatefulWidget {
  const FriendStudyRoomScreen({Key? key}) : super(key: key);

  @override
  State<FriendStudyRoomScreen> createState() => _FriendStudyRoomScreenState();
}

class _FriendStudyRoomScreenState extends State<FriendStudyRoomScreen> {
  late final Stream<List<StudyRoom>> _rooms = StudyRoomService.watchRooms();

  @override
  void initState() {
    super.initState();
    PresenceService.beat(); // 나도 접속 중으로 (5분에 한 번만 실제로 씀)
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
              Text(_s('title'), textAlign: TextAlign.center, style: _koStyle(20))
            else ...[
              Text('FRIENDS STUDY ROOM', textAlign: TextAlign.center, style: GoogleFonts.gowunBatang(color: _kGold, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              Text('친구 학습방', textAlign: TextAlign.center, style: _koStyle(23)),
            ],
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: _goldButton(
                icon: Icons.add_circle_outline_rounded,
                height: 54,
                onTap: _showCreateRoomDialog,
                child: _bi1('createRoom', size: 16.5, color: Colors.black),
              ),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: StreamBuilder<List<StudyRoom>>(
                stream: _rooms,
                builder: (context, snap) {
                  if (snap.hasError) return Center(child: _bi1('failed', color: Colors.white54, maxLines: 3, ta: TextAlign.center));
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: _kGold));
                  final List<StudyRoom> rooms = snap.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: _bi2('openRooms', size: 15)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: _kGold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _kGold.withValues(alpha: 0.5)),
                            ),
                            child: Text('${rooms.length}', style: _enStyle(13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: rooms.isEmpty
                            ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: _luxBox(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.meeting_room_outlined, color: _kGold.withValues(alpha: 0.7), size: 40),
                                const SizedBox(height: 12),
                                _bi2('noRooms', size: 14, color: Colors.white70, align: CrossAxisAlignment.center, ta: TextAlign.center),
                              ],
                            ),
                          ),
                        )
                            : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: rooms.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) => _roomCard(rooms[i]),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roomCard(StudyRoom r) {
    final bool active = r.members.isNotEmpty;
    final bool mine = r.creatorUid == PresenceService.myUid;
    final bool full = r.members.length >= r.maxUsers;
    return InkWell(
      onTap: () => _tryEnter(r),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
        decoration: _luxBox(bright: active),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: active ? _kGoldGrad : null,
                color: active ? null : Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: _kGold.withValues(alpha: active ? 1 : 0.4)),
              ),
              child: Icon(r.hasPassword ? Icons.lock_rounded : Icons.menu_book_rounded, color: active ? Colors.black : _kGold, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _koStyle(16, color: Colors.white)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _miniChip(Icons.people_alt_rounded, _s('membersCount', {'n': r.members.length, 'max': r.maxUsers}),
                          full ? Colors.redAccent : (active ? _kCyan : Colors.white54)),
                      _miniChip(r.hasPassword ? Icons.lock_outline_rounded : Icons.lock_open_rounded, _s(r.hasPassword ? 'locked' : 'open'), _kGold),
                    ],
                  ),
                ],
              ),
            ),
            if (mine)
              IconButton(
                tooltip: _s('deleteRoom'),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                onPressed: () => _confirmDelete(r),
              ),
            Icon(Icons.chevron_right_rounded, color: _kGold.withValues(alpha: 0.8)),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(IconData icon, String text, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c, size: 12),
          const SizedBox(width: 4),
          Text(text, style: _koStyle(11, color: c)),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(StudyRoom r) async {
    final bool? ok = await _showLuxDialog<bool>(
      context,
      icon: Icons.delete_forever_rounded,
      titleKey: 'deleteRoom',
      accent: Colors.redAccent,
      content: (ctx, setD) => Column(
        children: [
          Text(r.title, textAlign: TextAlign.center, style: _koStyle(16, color: Colors.white)),
          const SizedBox(height: 8),
          _bi1('deleteAsk', size: 13.5, color: Colors.white70, maxLines: 3, ta: TextAlign.center),
        ],
      ),
      actions: (ctx, setD) => [
        Expanded(child: _outlineButton(onTap: () => Navigator.pop(ctx, false), color: Colors.white54, child: _bi1('cancel', color: Colors.white70))),
        const SizedBox(width: 10),
        Expanded(child: _outlineButton(onTap: () => Navigator.pop(ctx, true), color: Colors.redAccent, child: _bi1('delete', color: Colors.redAccent))),
      ],
    );
    if (ok != true) return;
    final bool done = await StudyRoomService.deleteRoom(r.id);
    if (!done && mounted) _snack(context, 'failed');
  }

  Future<void> _tryEnter(StudyRoom r) async {
    final String? me = PresenceService.myUid;
    final bool already = me != null && r.members.contains(me);
    if (!already && r.members.length >= r.maxUsers) {
      _snack(context, 'roomFull', bg: Colors.redAccent);
      return;
    }
    if (r.hasPassword && r.creatorUid != me && !already) {
      final TextEditingController pw = TextEditingController();
      final bool? ok = await _showLuxDialog<bool>(
        context,
        icon: Icons.lock_rounded,
        titleKey: 'enterPw',
        content: (ctx, setD) => Column(
          children: [
            Text(r.title, textAlign: TextAlign.center, style: _koStyle(16, color: Colors.white)),
            const SizedBox(height: 14),
            _luxField(pw, 'enterPw', obscure: true, autofocus: true, icon: Icons.key_rounded),
          ],
        ),
        actions: (ctx, setD) => [
          Expanded(child: _outlineButton(onTap: () => Navigator.pop(ctx, false), color: Colors.white54, child: _bi1('cancel', color: Colors.white70))),
          const SizedBox(width: 10),
          Expanded(child: _goldButton(onTap: () => Navigator.pop(ctx, true), height: 44, child: _bi1('enter', color: Colors.black))),
        ],
      );
      if (ok != true) return;
      if (StudyRoomService.hashPw(pw.text.trim()) != r.pwHash) {
        if (mounted) _snack(context, 'wrongPw', bg: Colors.redAccent);
        return;
      }
    }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => _RoomPage(roomId: r.id, title: r.title, hasPassword: r.hasPassword)));
  }

  void _showCreateRoomDialog() {
    final TextEditingController name = TextEditingController();
    final TextEditingController pw = TextEditingController();
    int maxUsers = 5;
    bool saving = false;
    _showLuxDialog<void>(
      context,
      icon: Icons.add_home_work_rounded,
      titleKey: 'createRoom',
      content: (ctx, setD) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _luxField(name, 'roomName', maxLength: 20, icon: Icons.edit_rounded),
          const SizedBox(height: 6),
          _bi1('maxUsers', size: 12.5, color: Colors.white70),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kGold.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, color: _kGold),
                  onPressed: maxUsers > StudyRoomService.minUsers ? () => setD(() => maxUsers--) : null,
                ),
                Expanded(
                  child: Text(
                    _lang() == 'KO' ? '$maxUsers명' : '$maxUsers',
                    textAlign: TextAlign.center,
                    style: _enStyle(22),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: _kGold),
                  onPressed: maxUsers < StudyRoomService.maxUsersLimit ? () => setD(() => maxUsers++) : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _luxField(pw, 'passwordOpt', obscure: true, icon: Icons.lock_outline_rounded),
        ],
      ),
      actions: (ctx, setD) => [
        Expanded(child: _outlineButton(onTap: () => Navigator.pop(ctx), color: Colors.white54, child: _bi1('cancel', color: Colors.white70))),
        const SizedBox(width: 10),
        Expanded(
          child: _goldButton(
            height: 44,
            onTap: saving
                ? null
                : () async {
              final String title = name.text.trim();
              if (title.isEmpty) {
                _snack(context, 'needName');
                return;
              }
              setD(() => saving = true);
              final String? id = await StudyRoomService.createRoom(title: title, maxUsers: maxUsers, password: pw.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              if (id == null) {
                // 실패 이유(예: permission-denied)를 함께 보여 줌
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: Colors.redAccent,
                  content: Text('${_s('failed')}\n(${StudyRoomService.lastError})', style: _koStyle(13, color: Colors.white)),
                ));
                return;
              }
              Navigator.push(context, MaterialPageRoute(builder: (_) => _RoomPage(roomId: id, title: title, hasPassword: pw.text.trim().isNotEmpty)));
            },
            child: saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : _bi1('create', color: Colors.black),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 방 안 — 참여 학생 · 오늘 공부 시간 · 응원
// ============================================================================
class _RoomPage extends StatefulWidget {
  final String roomId;
  final String title;
  final bool hasPassword;
  const _RoomPage({required this.roomId, required this.title, this.hasPassword = false});

  @override
  State<_RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<_RoomPage> {
  late final Stream<StudyRoom?> _room = StudyRoomService.watchRoom(widget.roomId);
  Timer? _timer;
  List<String> _memberIds = [];
  List<PresenceInfo> _people = [];
  Map<String, List<CheerItem>> _cheers = {};
  bool _left = false;
  bool _loaded = false;
  bool _gotFirst = false; // 서버에서 방을 한 번이라도 받았는지 (처음 빈 응답을 "삭제됨"으로 착각하지 않게)
  // 🆕 [함께 공부] 이미 팝업을 보여 준 함께 공부 (같은 것을 두 번 띄우지 않게) · 남은 시간 표시용 시계
  final Set<String> _seenSessions = {};
  Timer? _clock;
  bool _popupOpen = false;

  @override
  void initState() {
    super.initState();
    _enter();
    _timer = Timer.periodic(PresenceService.beatInterval, (_) => _loadPeople());
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {}); // 남은 시간 글자만 새로 그림 (서버 읽기 없음)
    });
  }

  Future<void> _enter() async {
    await StudyRoomService.join(widget.roomId);
    await PresenceService.beat(force: true); // 방에 들어오면 내 정보를 바로 올림
    _loadPeople();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clock?.cancel();
    if (!_left) StudyRoomService.leave(widget.roomId);
    super.dispose();
  }

  Future<void> _loadPeople() async {
    final List<String> ids = List<String>.from(_memberIds);
    final results = await Future.wait([
      PresenceService.fetchMany(ids),
      StudyRoomService.fetchTodayCheers(ids),
    ]);
    if (!mounted) return;
    final List<PresenceInfo> people = results[0] as List<PresenceInfo>;
    people.sort((a, b) {
      if (a.studying != b.studying) return a.studying ? -1 : 1;
      return b.todayMinutes.compareTo(a.todayMinutes);
    });
    setState(() {
      _people = people;
      _cheers = results[1] as Map<String, List<CheerItem>>;
      _loaded = true;
    });
  }

  void _onMembers(List<String> ids) {
    final List<String> a = [...ids]..sort();
    final List<String> b = [..._memberIds]..sort();
    if (a.join(',') == b.join(',')) return;
    _memberIds = ids;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPeople());
  }

  Future<void> _cheer(PresenceInfo p, String emoji) async {
    final bool ok = await StudyRoomService.sendCheer(to: p.uid, emoji: emoji);
    if (!mounted) return;
    _snack(context, ok ? 'cheerSent' : 'failed');
    if (ok) _loadPeople();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: _foreign
            ? Text(_s('studyRoom'), style: _koStyle(17))
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('STUDY TOGETHER ROOM', style: GoogleFonts.gowunBatang(color: _kGold, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.2)),
            Text('함께 공부하는 방', style: _koStyle(16)),
          ],
        ),
      ),
      body: StreamBuilder<StudyRoom?>(
        stream: _room,
        builder: (context, snap) {
          if (snap.hasData) _gotFirst = true;
          final StudyRoom? room = snap.data;
          if (room == null) {
            if (!_gotFirst || snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _kGold));
            }
            _left = true;
            return Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: _luxBox(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.door_back_door_outlined, color: _kGold, size: 40),
                    const SizedBox(height: 10),
                    _bi1('roomGone', size: 14, color: Colors.white70),
                  ],
                ),
              ),
            );
          }
          _onMembers(room.members);
          _maybeShowSessionPopup(room);
          final int total = _people.fold(0, (a, p) => a + p.todayMinutes);
          final int avg = _people.isEmpty ? 0 : (total / _people.length).round();
          return Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _heroCard(room),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _statCard(Icons.timer_outlined, 'total', _fmtMin(total))),
                          const SizedBox(width: 10),
                          Expanded(child: _statCard(Icons.insights_rounded, 'average', _fmtMin(avg))),
                          const SizedBox(width: 10),
                          Expanded(child: _statCard(Icons.people_alt_rounded, 'members2', '${room.members.length}/${room.maxUsers}')),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _sessionArea(room), // 🆕 [함께 공부] 방장 시작 버튼 · 진행 중 안내
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: _bi2('members', size: 15)),
                          Flexible(child: _bi1('refresh5', size: 10.5, color: Colors.white38)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (!_loaded)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator(color: _kGold)),
                        )
                      else ...[
                        if (_people.length <= 1)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _kGold.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _kGold.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.campaign_outlined, color: _kGold, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: _bi1('aloneHere', size: 12.5, color: Colors.white70, maxLines: 3)),
                              ],
                            ),
                          ),
                        for (final PresenceInfo p in _people) ...[
                          _memberCard(p),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: _outlineButton(
                    height: 50,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeDashboardScreen())),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune_rounded, color: _kGold, size: 20),
                        const SizedBox(width: 8),
                        Flexible(child: _bi1('studySettings', size: 15, color: _kGold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================================================
  // 🆕 [함께 공부 2026-10-11] 방장이 과목 · 시간 · 시험 · 백색소음을 정해 시작
  // → 다른 학생에게 [같이 시작] [나중에 시작] 팝업. 타이머는 각자 평소와 같은 타이머
  //   (별 · 학부모방 · 학습 기록장 모두 각자 따로). 시험 날짜는 학생마다 학교가 달라 넘기지 않음.
  // ==========================================================================
  static const List<Map<String, String>> _kSounds = [
    {'en': 'Crickets', 'ko': '귀뚜라미 소리', 'file': 'crickets.mp3'},
    {'en': 'Spring Morning', 'ko': '봄 아침소리', 'file': 'spring_morning.mp3'},
    {'en': 'Forest Birds', 'ko': '숲속의 새소리', 'file': 'forest_birds.mp3'},
    {'en': 'Cool Rain', 'ko': '시원한 빗소리', 'file': 'cool_rain.mp3'},
    {'en': 'Clear Stream', 'ko': '맑은 시냇물', 'file': 'clear_stream.mp3'},
    {'en': 'Blue Waves', 'ko': '푸른 파도소리', 'file': 'blue_waves.mp3'},
  ];
  static const List<String> _kDefaultExams = ['중간고사', '기말고사', '학기중 학습', '공무원 시험', 'TOEIC', '2027 대학수능'];
  static const List<int> _kMinuteChoices = [25, 30, 45, 50, 60, 90, 120];
  static const List<String> _kModes = ['normal', 'vacation', 'examBefore', 'examDuring'];
  static const Map<String, String> _kModeKey = {'normal': 'modeNormal', 'vacation': 'modeVacation', 'examBefore': 'modeExamBefore', 'examDuring': 'modeExamDuring'};
  static const Map<String, IconData> _kModeIcon = {'normal': Icons.school_rounded, 'vacation': Icons.beach_access_rounded, 'examBefore': Icons.edit_calendar_rounded, 'examDuring': Icons.assignment_rounded};

  bool _isHost(StudyRoom room) => room.creatorUid == PresenceService.myUid;

  String _soundLabel(String file) {
    for (final Map<String, String> m in _kSounds) {
      if (m['file'] == file) return _foreign ? m['en']! : m['ko']!;
    }
    return _s('none');
  }

  void _maybeShowSessionPopup(StudyRoom room) {
    final GroupSession? gs = room.session;
    if (gs == null || _popupOpen || _seenSessions.contains(gs.id)) return;
    _seenSessions.add(gs.id);
    if (gs.hostUid == PresenceService.myUid || !gs.isActive || gs.remainingMinutes < 1) return;
    _popupOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) await _showSessionPopup(gs);
      _popupOpen = false;
    });
  }

  Widget _sessionInfo(GroupSession gs) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _infoPill('🗓 ${_s(_kModeKey[gs.mode] ?? 'modeNormal')}'),
        _infoPill('📖 ${gs.subject}'),
        _infoPill('⏱ ${_fmtMin(gs.minutes)}'),
        if (gs.examTitle.isNotEmpty) _infoPill('📝 ${gs.examTitle}'),
        _infoPill('🎧 ${_soundLabel(gs.sound)}'),
      ],
    );
  }

  Future<void> _showSessionPopup(GroupSession gs) async {
    final String? choice = await _showLuxDialog<String>(
      context,
      icon: Icons.groups_rounded,
      titleKey: 'groupNow',
      content: (ctx, setD) => Column(
        children: [
          Text(
            _s('sessionPopup', {'host': gs.hostName.isEmpty ? _s('hostTag') : gs.hostName}),
            textAlign: TextAlign.center,
            style: _koStyle(15.5, color: Colors.white),
          ),
          const SizedBox(height: 14),
          _sessionInfo(gs),
          const SizedBox(height: 12),
          Text(_s('leftTime', {'t': _fmtMin(gs.remainingMinutes)}), style: _koStyle(14, color: _kCyan)),
          const SizedBox(height: 12),
          _bi1('togetherHint', size: 11.5, color: Colors.white60, maxLines: 8, ta: TextAlign.center),
        ],
      ),
      actions: (ctx, setD) => [
        Expanded(child: _outlineButton(onTap: () => Navigator.pop(ctx, 'later'), color: Colors.white54, child: _bi1('startLater', color: Colors.white70))),
        const SizedBox(width: 10),
        Expanded(child: _goldButton(height: 44, onTap: () => Navigator.pop(ctx, 'together'), child: _bi1('joinTogether', color: Colors.black))),
      ],
    );
    if (choice == 'together' && mounted && gs.remainingMinutes > 0) {
      await _launchTimer(gs, gs.remainingMinutes);
    }
  }

  /// 평소와 같은 타이머를 엶 (방장이 정한 과목 · 시간 · 시험 이름 · 백색소음)
  Future<void> _launchTimer(GroupSession gs, int minutes) async {
    if (minutes < 1) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String univ = prefs.getString('saved_target_university') ?? 'Seoul National University (서울대학교)';
    final bool vip = prefs.getBool('saved_vip_status') ?? false;
    // 🆕 [학사 모드] 시험 전 · 시험 중이면 "내" 시험 날짜(내가 첫 화면에서 정해 둔 것)로 D-day 표시.
    //    방장의 날짜를 넘기지 않으므로 친구들의 시험 일정은 절대 바뀌지 않음. 날짜가 없으면 목표만 표시.
    final bool examMode = gs.mode == 'examBefore' || gs.mode == 'examDuring';
    final DateTime? myExamStart = examMode ? DateTime.tryParse(prefs.getString('gke_exam_start_date') ?? '') : null;
    final DateTime? myExamEnd = examMode ? DateTime.tryParse(prefs.getString('gke_exam_end_date') ?? '') : null;
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TimerScreen(
          selectedSubject: gs.subject,
          selectedDurationMinutes: minutes,
          dynamicTestTitle: gs.examTitle,
          targetExamDate: myExamStart,
          targetExamEndDate: myExamEnd,
          prepPeriodStr: '',
          needTimelineGen: false,
          selectedSoundFile: gs.sound,
          targetUniversity: univ,
          isVipMember: vip,
          isExamTrackMode: myExamStart != null,
        ),
      ),
    );
    if (mounted) _loadPeople();
  }

  Widget _sessionArea(StudyRoom room) {
    final GroupSession? gs = room.session;
    final bool host = _isHost(room);
    final bool show = gs != null && gs.isToday;
    if (!host && !show) return const SizedBox.shrink();
    final bool mineSession = gs != null && gs.hostUid == PresenceService.myUid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (gs != null && show)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: _luxBox(bright: gs.isActive, radius: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(gs.isActive ? Icons.notifications_active_rounded : Icons.history_rounded, color: _kGold, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: _bi2(mineSession ? 'hostStarted' : (gs.isActive ? 'groupNow' : 'groupDone'), size: 14)),
                    if (gs.isActive)
                      Text(_s('leftTime', {'t': _fmtMin(gs.remainingMinutes)}), style: _koStyle(13, color: _kCyan)),
                  ],
                ),
                const SizedBox(height: 10),
                _sessionInfo(gs),
                if (!mineSession) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (gs.isActive) ...[
                        Expanded(
                          child: _goldButton(
                            height: 42,
                            onTap: () => _launchTimer(gs, gs.remainingMinutes),
                            child: _bi1('joinTogether', size: 12.5, color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: _outlineButton(
                          height: 42,
                          onTap: () => _launchTimer(gs, gs.minutes),
                          child: _bi1('startMine', size: 12.5, color: _kGold),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        if (host) ...[
          if (show) const SizedBox(height: 10),
          _goldButton(
            icon: Icons.play_circle_fill_rounded,
            height: 50,
            onTap: () => _openGroupMenu(room),
            child: _bi1('groupStart', size: 15, color: Colors.black),
          ),
          const SizedBox(height: 10),
          _outlineButton(
            height: 46,
            onTap: () => _openInvite(room),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_add_alt_1_rounded, color: _kGold, size: 20),
                const SizedBox(width: 8),
                Flexible(child: _bi1('inviteFriends', size: 14, color: _kGold)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<List<String>> _mySubjects() async {
    final List<String> out = [];
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString('gke_saved_subjects_v1');
      if (raw != null && raw.isNotEmpty) {
        for (final dynamic e in jsonDecode(raw) as List) {
          final Map m = e as Map;
          out.add('${m['en']} (${m['ko']})');
        }
      }
    } catch (_) {}
    for (final SubjectCategory c in kSubjectCategories) {
      final String v = '${c.en} (${c.ko})';
      if (!out.contains(v)) out.add(v);
    }
    return out;
  }

  Future<List<String>> _myExams() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? saved = prefs.getStringList('gke_saved_exam_types_v1');
      if (saved != null && saved.isNotEmpty) return saved;
    } catch (_) {}
    return List<String>.from(_kDefaultExams);
  }

  /// 고르기 팝업 하나 (목록에서 하나를 누르면 바로 닫힘)
  Future<String?> _pickOne({
    required String titleKey,
    required IconData icon,
    required List<String> values,
    required String Function(String v) label,
    required String current,
    IconData Function(String v)? iconOf,
  }) {
    return _showLuxDialog<String>(
      context,
      icon: icon,
      titleKey: titleKey,
      content: (ctx, setD) => ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 380),
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final String v in values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(ctx, v),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: v == current ? _kGoldGrad : null,
                      color: v == current ? null : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kGold.withValues(alpha: v == current ? 1 : 0.3)),
                    ),
                    child: Row(
                      children: [
                        if (iconOf != null) ...[
                          Icon(iconOf(v), color: v == current ? Colors.black : _kGold, size: 20),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(label(v), maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: _koStyle(14, color: v == current ? Colors.black : Colors.white, w: v == current ? FontWeight.bold : FontWeight.w500)),
                        ),
                        if (v == current) const Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: (ctx, setD) => [
        Expanded(child: _outlineButton(onTap: () => Navigator.pop(ctx), color: Colors.white54, child: _bi1('close', color: Colors.white70))),
      ],
    );
  }

  /// 설정 한 줄 (아이콘 · 항목 이름 · 고른 값 · ▶) — 누르면 고르기 팝업
  Widget _setRow({required IconData icon, required String k, required String value, required VoidCallback onTap, bool empty = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kGold.withValues(alpha: empty ? 0.3 : 0.7)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _kGold.withValues(alpha: 0.12), border: Border.all(color: _kGold.withValues(alpha: 0.6))),
                child: Icon(icon, color: _kGold, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bi1(k, size: 11.5, color: Colors.white60),
                    const SizedBox(height: 2),
                    Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: _koStyle(14.5, color: empty ? Colors.white38 : Colors.white, w: empty ? FontWeight.w500 : FontWeight.bold)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _kGold),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // 🆕 [함께 공부 갈래 2026-10-11] ① 학사 타임라인 (평상시 · 방학 · 시험 준비 · 시험 중) ② 자유 과목
  // ① 학사 타이머 화면의 그 탭이 열리고, 방장이 거기서 타이머를 켜는 순간 방 친구들에게 같은 과목 ·
  //    같은 끝나는 시각으로 [같이 시작] 팝업이 감
  // ==========================================================================
  static const Map<String, String> _kTrackOfMode = {
    'normal': 'NORMAL_PERIOD',
    'vacation': 'VACATION_SUMMER_WINTER',
    'examBefore': 'EXAM_PREP_PERIOD',
    'examDuring': 'EXAM_DAY_TRACK',
  };
  static const Map<String, String> _kModeOfTrack = {
    'NORMAL_PERIOD': 'normal',
    'VACATION_SUMMER_WINTER': 'vacation',
    'EXAM_PREP_PERIOD': 'examBefore',
    'EXAM_DAY_TRACK': 'examDuring',
  };

  Future<void> _openGroupMenu(StudyRoom room) async {
    final String? pick = await _showLuxDialog<String>(
      context,
      icon: Icons.play_circle_outline_rounded,
      titleKey: 'groupStart',
      content: (ctx, setD) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note_rounded, color: _kGold, size: 18),
              const SizedBox(width: 6),
              Expanded(child: _bi1('groupMenuTimeline', size: 14, color: _kGold)),
            ],
          ),
          const SizedBox(height: 4),
          _bi1('groupMenuTimelineDesc', size: 11, color: Colors.white54, maxLines: 4),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.3,
            children: [
              for (final String m in _kModes)
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.pop(ctx, m),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _kGold.withValues(alpha: 0.7)),
                    ),
                    child: Row(
                      children: [
                        Icon(_kModeIcon[m]!, color: _kGold, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: _bi2(_kModeKey[m]!, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: _kGold.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.pop(ctx, 'free'),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: _kGoldGrad,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: _kGold.withValues(alpha: 0.3), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.black, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bi1('groupMenuFree', size: 15, color: Colors.black),
                        const SizedBox(height: 2),
                        _bi1('groupMenuFreeDesc', size: 10.5, color: Colors.black87, maxLines: 3),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.black),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: (ctx, setD) => [
        Expanded(child: _outlineButton(onTap: () => Navigator.pop(ctx), color: Colors.white54, child: _bi1('close', color: Colors.white70))),
      ],
    );
    if (pick == null || !mounted) return;
    if (pick == 'free') {
      await _openSetup(room);
      return;
    }
    final String track = _kTrackOfMode[pick] ?? 'NORMAL_PERIOD';
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AcademicTimelineScreen(
          initialTrack: track,
          // 방장이 학사 타이머에서 타이머를 켜는 순간 → 방 친구들에게 [같이 시작] 팝업
          onGroupTimerStart: (String subject, int minutes, String examTitle, String sound, String usedTrack) {
            StudyRoomService.startSession(
              room.id,
              subject: subject,
              minutes: minutes,
              examTitle: examTitle,
              sound: sound,
              mode: _kModeOfTrack[usedTrack] ?? 'normal',
            );
          },
        ),
      ),
    );
    if (mounted) _loadPeople();
  }

  Future<void> _openSetup(StudyRoom room) async {
    final List<String> subjects = await _mySubjects();
    final List<String> exams = await _myExams();
    if (!mounted) return;
    String mode = 'normal';
    String subject = '';
    int minutes = 50;
    String exam = '';
    String sound = '';
    bool saving = false;
    await _showLuxDialog<void>(
      context,
      icon: Icons.play_circle_outline_rounded,
      titleKey: 'groupStart',
      content: (ctx, setD) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _setRow(
            icon: Icons.menu_book_rounded,
            k: 'setSubject',
            value: subject.isEmpty ? _s('tapToChoose') : subject,
            empty: subject.isEmpty,
            onTap: () async {
              final String? v = await _pickOne(titleKey: 'setSubject', icon: Icons.menu_book_rounded, values: subjects, label: (x) => x, current: subject);
              if (v != null) setD(() => subject = v);
            },
          ),
          _setRow(
            icon: Icons.timer_outlined,
            k: 'setMinutes',
            value: _fmtMin(minutes),
            onTap: () async {
              final String? v = await _pickOne(
                titleKey: 'setMinutes',
                icon: Icons.timer_outlined,
                values: [for (final int m in _kMinuteChoices) '$m'],
                label: (x) => _fmtMin(int.parse(x)),
                current: '$minutes',
              );
              if (v != null) setD(() => minutes = int.parse(v));
            },
          ),
          _setRow(
            icon: Icons.assignment_outlined,
            k: 'setExam',
            value: exam.isEmpty ? _s('none') : exam,
            empty: exam.isEmpty,
            onTap: () async {
              final String? v = await _pickOne(
                titleKey: 'setExam',
                icon: Icons.assignment_outlined,
                values: ['', ...exams],
                label: (x) => x.isEmpty ? _s('none') : x,
                current: exam,
              );
              if (v != null) setD(() => exam = v);
            },
          ),
          _setRow(
            icon: Icons.headphones_rounded,
            k: 'setSound',
            value: sound.isEmpty ? _s('none') : _soundLabel(sound),
            empty: sound.isEmpty,
            onTap: () async {
              final String? v = await _pickOne(
                titleKey: 'setSound',
                icon: Icons.headphones_rounded,
                values: ['', for (final Map<String, String> m in _kSounds) m['file']!],
                label: (x) => x.isEmpty ? _s('none') : _soundLabel(x),
                current: sound,
              );
              if (v != null) setD(() => sound = v);
            },
          ),
          const SizedBox(height: 4),
          _bi1('togetherHint', size: 11, color: Colors.white54, maxLines: 8),
        ],
      ),
      actions: (ctx, setD) => [
        Expanded(child: _outlineButton(onTap: () => Navigator.pop(ctx), color: Colors.white54, child: _bi1('cancel', color: Colors.white70))),
        const SizedBox(width: 10),
        Expanded(
          child: _goldButton(
            height: 44,
            onTap: saving
                ? null
                : () async {
              if (subject.isEmpty) {
                _snack(context, 'chooseSubject');
                return;
              }
              setD(() => saving = true);
              final bool ok = await StudyRoomService.startSession(room.id, subject: subject, minutes: minutes, examTitle: exam, sound: sound, mode: mode);
              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: Colors.redAccent,
                  content: Text('${_s('failed')}\n(${StudyRoomService.lastError})', style: _koStyle(13, color: Colors.white)),
                ));
                return;
              }
              final DateTime now = DateTime.now();
              await _launchTimer(
                GroupSession(
                  id: '${now.millisecondsSinceEpoch}',
                  subject: subject,
                  minutes: minutes,
                  examTitle: exam,
                  sound: sound,
                  mode: mode,
                  hostUid: PresenceService.myUid ?? '',
                  hostName: PresenceService.myName,
                  startAt: now,
                  endAt: now.add(Duration(minutes: minutes)),
                ),
                minutes,
              );
            },
            child: saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : _bi1('startNow', color: Colors.black),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // 🆕 [초대 2026-10-11] 같은 학교 · 학년 친구를 골라 초대
  // ==========================================================================
  Future<void> _openInvite(StudyRoom room) async {
    final List<PresenceInfo> all = await PresenceService.fetchFriends();
    if (!mounted) return;
    final List<PresenceInfo> list = all.where((p) => !room.members.contains(p.uid)).toList();
    final Set<String> picked = {};
    bool sending = false;
    await _showLuxDialog<void>(
      context,
      icon: Icons.person_add_alt_1_rounded,
      titleKey: 'inviteFriends',
      content: (ctx, setD) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _bi1('noClassmates', size: 13, color: Colors.white60, maxLines: 3, ta: TextAlign.center),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final PresenceInfo p in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setD(() => picked.contains(p.uid) ? picked.remove(p.uid) : picked.add(p.uid)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: picked.contains(p.uid) ? _kGold.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kGold.withValues(alpha: picked.contains(p.uid) ? 0.9 : 0.25)),
                          ),
                          child: Row(
                            children: [
                              _avatar(p.name, active: p.studying, size: 36),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _koStyle(14, color: Colors.white)),
                                    Text(p.school, maxLines: 1, overflow: TextOverflow.ellipsis, style: _koStyle(11, color: Colors.white54, w: FontWeight.normal)),
                                  ],
                                ),
                              ),
                              if (_isOnline(p)) ...[
                                Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1DD1A1))),
                                const SizedBox(width: 4),
                                Text(_s('onlineNow'), style: _koStyle(10.5, color: const Color(0xFF1DD1A1))),
                                const SizedBox(width: 6),
                              ],
                              Icon(
                                picked.contains(p.uid) ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                color: picked.contains(p.uid) ? _kGold : Colors.white38,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          _bi1('inviteHint', size: 11, color: Colors.white54, maxLines: 6),
        ],
      ),
      actions: (ctx, setD) => [
        Expanded(child: _outlineButton(onTap: () => Navigator.pop(ctx), color: Colors.white54, child: _bi1('cancel', color: Colors.white70))),
        const SizedBox(width: 10),
        Expanded(
          child: _goldButton(
            height: 44,
            onTap: (sending || list.isEmpty)
                ? null
                : () async {
              if (picked.isEmpty) {
                _snack(context, 'pickFriends');
                return;
              }
              setD(() => sending = true);
              int ok = 0;
              final List<String> cooled = [];
              for (final PresenceInfo p in list.where((x) => picked.contains(x.uid))) {
                final String r = await StudyRoomService.sendInvite(to: p.uid, roomId: room.id, roomTitle: room.title);
                if (r == 'ok') ok++;
                if (r == 'cooldown') cooled.add(p.name);
              }
              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              final List<String> lines = [
                if (ok > 0) _s('invitesSent', {'n': ok}),
                for (final String n in cooled) _s('inviteCooldown', {'name': n}),
                if (ok == 0 && cooled.isEmpty) '${_s('failed')} (${StudyRoomService.lastError})',
              ];
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: ok > 0 ? _kCard : Colors.redAccent,
                content: Text(lines.join('\n'), style: _koStyle(13, color: ok > 0 ? _kGold : Colors.white)),
              ));
            },
            child: sending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : _bi1('inviteSend', color: Colors.black),
          ),
        ),
      ],
    );
  }

  bool _isOnline(PresenceInfo p) =>
      p.lastSeen != null && DateTime.now().difference(p.lastSeen!) < PresenceService.onlineWindow;

  Widget _heroCard(StudyRoom room) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: _luxBox(bright: true, radius: 20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _kGoldGrad,
              boxShadow: [BoxShadow(color: _kGold.withValues(alpha: 0.4), blurRadius: 14)],
            ),
            child: const Icon(Icons.auto_stories_rounded, color: Colors.black, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: _koStyle(21, color: Colors.white)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(room.hasPassword ? Icons.lock_rounded : Icons.lock_open_rounded, color: _kGoldDeep, size: 14),
                    const SizedBox(width: 4),
                    Flexible(child: _bi1(room.hasPassword ? 'locked' : 'open', size: 11.5, color: _kGold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String k, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: _luxBox(radius: 14),
      child: Column(
        children: [
          Icon(icon, color: _kGold, size: 20),
          const SizedBox(height: 6),
          FittedBox(fit: BoxFit.scaleDown, child: Text(v, style: _koStyle(15, color: Colors.white))),
          const SizedBox(height: 2),
          FittedBox(fit: BoxFit.scaleDown, child: _foreign ? Text(_s(k), style: _koStyle(10.5, color: Colors.white54, w: FontWeight.w500)) : Column(
            children: [
              Text(_e(k), style: _enStyle(9.5, color: Colors.white38)),
              Text(_s(k), style: _koStyle(10.5, color: Colors.white54, w: FontWeight.w500)),
            ],
          )),
        ],
      ),
    );
  }

  Widget _memberCard(PresenceInfo p) {
    final bool isMe = p.uid == PresenceService.myUid;
    final List<CheerItem> got = _cheers[p.uid] ?? [];
    return Container(
      decoration: _luxBox(bright: p.studying || isMe, radius: 14),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
          iconColor: _kGold,
          collapsedIconColor: Colors.white54,
          leading: _avatar(p.name, active: p.studying),
          title: Text(
            isMe ? '${p.name} (${_s('me')})' : p.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _koStyle(15, color: Colors.white),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(p.school, maxLines: 1, overflow: TextOverflow.ellipsis, style: _koStyle(11.5, color: Colors.white54, w: FontWeight.normal)),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _statusChip(p.studying),
              const SizedBox(height: 4),
              Text(_fmtMin(p.todayMinutes), style: _koStyle(13, color: _kGold)),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 1, color: _kGold.withValues(alpha: 0.15)),
                  const SizedBox(height: 10),
                  if (p.studying && p.subject.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, color: _kCyan, size: 15),
                        const SizedBox(width: 6),
                        Expanded(child: Text(p.subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: _koStyle(13, color: _kWhite, w: FontWeight.w500))),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _infoPill('⏱ ${_s('today')} ${_fmtMin(p.todayMinutes)}'),
                      _infoPill('🏅 Lv.${p.level}'),
                      _infoPill('⭐ ${p.totalStars}'),
                    ],
                  ),
                  if (got.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _bi1('cheersFrom', size: 12, color: Colors.white60),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: got
                          .map((c) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kGold.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kGold.withValues(alpha: 0.3)),
                        ),
                        child: Text('${c.emoji} ${c.fromName}', style: _koStyle(11.5, color: _kWhite, w: FontWeight.w500)),
                      ))
                          .toList(),
                    ),
                  ],
                  if (!isMe) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _cheerBtn('👍', 'cheer', () => _cheer(p, '👍'))),
                        const SizedBox(width: 10),
                        Expanded(child: _cheerBtn('🔥', 'motivate', () => _cheer(p, '🔥'))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPill(String t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(t, style: _koStyle(12, color: _kGold, w: FontWeight.w600)),
    );
  }

  Widget _cheerBtn(String emoji, String k, VoidCallback onTap) {
    return _outlineButton(
      height: 42,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Flexible(child: _bi1(k, size: 12.5, color: _kGold)),
        ],
      ),
    );
  }
}

// ============================================================================
// 🆕 [초대 2026-10-11] 학생 첫 화면에 붙이는 "초대 듣기"
// - 나에게 온 초대를 실시간으로 지켜보다가 금테 팝업 → [수락]이면 바로 그 방으로 입장
// - 타이머로 공부 중일 때는 팝업을 미뤘다가, 공부가 끝나면 보여 줌 (30초마다 확인)
// ============================================================================
class RoomInviteWatcher {
  StreamSubscription<List<RoomInvite>>? _sub;
  Timer? _tick;
  List<RoomInvite> _pending = [];
  final Set<String> _shown = {};
  bool _busy = false;
  BuildContext Function()? _ctx;
  bool Function()? _alive;

  void start(BuildContext Function() getContext, bool Function() isMounted) {
    _ctx = getContext;
    _alive = isMounted;
    PresenceService.loadProfile();
    _sub?.cancel();
    _sub = StudyRoomService.watchMyInvites().listen((list) {
      _pending = list;
      _tryShow();
    }, onError: (e) => debugPrint('[RoomInvite] 초대 듣기 실패: $e'));
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => _tryShow());
  }

  void stop() {
    _sub?.cancel();
    _tick?.cancel();
  }

  Future<void> _tryShow() async {
    if (_busy || _alive == null || !_alive!() || PresenceService.isStudyingNow) return;
    final List<RoomInvite> todo = _pending.where((i) => i.isValid && !_shown.contains(i.id + (i.expiresAt?.toIso8601String() ?? ''))).toList();
    if (todo.isEmpty) return;
    final RoomInvite inv = todo.first;
    _shown.add(inv.id + (inv.expiresAt?.toIso8601String() ?? ''));
    _busy = true;
    try {
      final BuildContext context = _ctx!();
      final bool? accept = await _showLuxDialog<bool>(
        context,
        icon: Icons.mark_email_unread_rounded,
        titleKey: 'inviteTitle',
        content: (ctx, setD) => Column(
          children: [
            Text(
              _s('inviteBody', {'host': inv.fromName.isEmpty ? _s('hostTag') : inv.fromName, 'room': inv.roomTitle}),
              textAlign: TextAlign.center,
              style: _koStyle(15.5, color: Colors.white),
            ),
          ],
        ),
        actions: (ctx, setD) => [
          Expanded(child: _outlineButton(onTap: () => Navigator.pop(ctx, false), color: Colors.white54, child: _bi1('decline', color: Colors.white70))),
          const SizedBox(width: 10),
          Expanded(child: _goldButton(height: 44, onTap: () => Navigator.pop(ctx, true), child: _bi1('accept', color: Colors.black))),
        ],
      );
      if (accept == null) return; // 바깥을 눌러 닫음 → 답하지 않은 채로 둠
      await StudyRoomService.answerInvite(inv.id, accept);
      if (!accept || _alive == null || !_alive!()) return;
      final StudyRoom? room = await StudyRoomService.getRoom(inv.roomId);
      if (_alive == null || !_alive!()) return;
      final BuildContext ctx2 = _ctx!();
      if (room == null) {
        _snack(ctx2, 'roomGone', bg: Colors.redAccent);
        return;
      }
      final String? me = PresenceService.myUid;
      if (me != null && !room.members.contains(me) && room.members.length >= room.maxUsers) {
        _snack(ctx2, 'roomFull', bg: Colors.redAccent);
        return;
      }
      await Navigator.push(ctx2, MaterialPageRoute(builder: (_) => _RoomPage(roomId: room.id, title: room.title, hasPassword: room.hasPassword)));
    } catch (e) {
      debugPrint('[RoomInvite] 초대 팝업 실패: $e');
    } finally {
      _busy = false;
    }
  }
}

// 예전 파일에 있던 도우미 (다른 파일에서 쓰고 있을 수 있어 그대로 둠)
extension SafeListAccess on List {
  bool isValidIndex(int index) => index >= 0 && index < length;
}
