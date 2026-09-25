import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../global_lang.dart';
import '../services/notice_counsel_service.dart';
import '../schedule/bilingual_text.dart' as gp; // 🆕 일반인(일반 플래너) 언어 설정 읽기용

// ============================================================================
// 🆕 [2026-09-24] 공지 및 교육상담 화면 (학생·학부모 공용)
// 학생: 탭 3개 📢 공지사항 / 🗣️ 게시판(비공개) / 🎓 교육상담(1:1)
// 학부모: 탭 3개 📢 공지 / 💬 의견함 / 🎓 교육상담
// 일반인(일반 플래너): 탭 2개 📢 공지 / 💬 의견함 (교육상담 없음)
// 교육상담 안: 🩺 실력진단(준비중) / 📚 교재 길잡이(준비중) / 💬 1:1 학습상담 / 📖 자주 묻는 상담(준비중)
// 기본모드(KO/EN): 한글+영문 동시 표시 / 10개국어 선택 시 해당 언어만 표시
// ============================================================================

const Color _kBg = Color(0xFF030712);
const Color _kCard = Color(0xFF0D1527);
const Color _kGold = Color(0xFFE5C158);

const Map<String, Map<String, String>> _tx = {
  'screenTitle': {'KO': '공지 및 교육상담', 'EN': 'Notice & Counseling', 'JA': 'お知らせ・教育相談', 'ZH': '公告与教育咨询', 'FR': 'Avis & Conseil', 'DE': 'Hinweise & Beratung', 'RU': 'Объявления и консультации', 'AR': 'الإعلانات والاستشارات', 'HI': 'सूचना और परामर्श', 'VI': 'Thông báo & Tư vấn', 'ES': 'Avisos y Asesoría', 'TH': 'ประกาศและให้คำปรึกษา'},
  'tabNotice': {'KO': '공지', 'EN': 'Notice', 'JA': 'お知らせ', 'ZH': '公告', 'FR': 'Avis', 'DE': 'Hinweise', 'RU': 'Объявления', 'AR': 'الإعلانات', 'HI': 'सूचना', 'VI': 'Thông báo', 'ES': 'Avisos', 'TH': 'ประกาศ'},
  'tabFeedback': {'KO': '의견함', 'EN': 'Feedback', 'JA': 'ご意見', 'ZH': '意见箱', 'FR': 'Suggestions', 'DE': 'Feedback', 'RU': 'Отзывы', 'AR': 'الملاحظات', 'HI': 'सुझाव', 'VI': 'Góp ý', 'ES': 'Opiniones', 'TH': 'ความคิดเห็น'},
  'tabCounsel': {'KO': '교육상담', 'EN': 'Counseling', 'JA': '教育相談', 'ZH': '教育咨询', 'FR': 'Conseil', 'DE': 'Beratung', 'RU': 'Консультации', 'AR': 'الاستشارات', 'HI': 'परामर्श', 'VI': 'Tư vấn', 'ES': 'Asesoría', 'TH': 'ให้คำปรึกษา'},
  'noNotice': {'KO': '아직 등록된 공지가 없습니다.', 'EN': 'No notices yet.', 'JA': 'まだお知らせはありません。', 'ZH': '暂无公告。', 'FR': 'Aucun avis pour le moment.', 'DE': 'Noch keine Hinweise.', 'RU': 'Пока нет объявлений.', 'AR': 'لا توجد إعلانات بعد.', 'HI': 'अभी कोई सूचना नहीं है।', 'VI': 'Chưa có thông báo nào.', 'ES': 'Aún no hay avisos.', 'TH': 'ยังไม่มีประกาศ'},
  'loadFailed': {'KO': '불러오지 못했습니다. 잠시 후 다시 시도해 주세요.', 'EN': "Couldn't load. Please try again shortly.", 'JA': '読み込めませんでした。しばらくしてから再試行してください。', 'ZH': '加载失败，请稍后重试。', 'FR': 'Chargement impossible. Réessayez plus tard.', 'DE': 'Laden fehlgeschlagen. Bitte später erneut versuchen.', 'RU': 'Не удалось загрузить. Повторите позже.', 'AR': 'تعذر التحميل. يرجى المحاولة لاحقًا.', 'HI': 'लोड नहीं हो सका। कृपया बाद में पुनः प्रयास करें।', 'VI': 'Không tải được. Vui lòng thử lại sau.', 'ES': 'No se pudo cargar. Inténtalo más tarde.', 'TH': 'โหลดไม่สำเร็จ กรุณาลองใหม่ภายหลัง'},
  'writeNotice': {'KO': '공지 쓰기', 'EN': 'Write Notice', 'JA': 'お知らせ作成', 'ZH': '发布公告', 'FR': 'Rédiger un avis', 'DE': 'Hinweis schreiben', 'RU': 'Написать объявление', 'AR': 'كتابة إعلان', 'HI': 'सूचना लिखें', 'VI': 'Viết thông báo', 'ES': 'Escribir aviso', 'TH': 'เขียนประกาศ'},
  'fieldTitle': {'KO': '제목', 'EN': 'Title', 'JA': 'タイトル', 'ZH': '标题', 'FR': 'Titre', 'DE': 'Titel', 'RU': 'Заголовок', 'AR': 'العنوان', 'HI': 'शीर्षक', 'VI': 'Tiêu đề', 'ES': 'Título', 'TH': 'หัวข้อ'},
  'fieldContent': {'KO': '내용', 'EN': 'Content', 'JA': '内容', 'ZH': '内容', 'FR': 'Contenu', 'DE': 'Inhalt', 'RU': 'Содержание', 'AR': 'المحتوى', 'HI': 'विषय-वस्तु', 'VI': 'Nội dung', 'ES': 'Contenido', 'TH': 'เนื้อหา'},
  'pinTop': {'KO': '맨 위 고정', 'EN': 'Pin to top', 'JA': '上部に固定', 'ZH': '置顶', 'FR': 'Épingler en haut', 'DE': 'Oben anheften', 'RU': 'Закрепить сверху', 'AR': 'تثبيت في الأعلى', 'HI': 'ऊपर पिन करें', 'VI': 'Ghim lên đầu', 'ES': 'Fijar arriba', 'TH': 'ปักหมุดไว้บนสุด'},
  'cancel': {'KO': '취소', 'EN': 'Cancel', 'JA': 'キャンセル', 'ZH': '取消', 'FR': 'Annuler', 'DE': 'Abbrechen', 'RU': 'Отмена', 'AR': 'إلغاء', 'HI': 'रद्द करें', 'VI': 'Hủy', 'ES': 'Cancelar', 'TH': 'ยกเลิก'},
  'submit': {'KO': '보내기', 'EN': 'Submit', 'JA': '送信', 'ZH': '提交', 'FR': 'Envoyer', 'DE': 'Senden', 'RU': 'Отправить', 'AR': 'إرسال', 'HI': 'भेजें', 'VI': 'Gửi', 'ES': 'Enviar', 'TH': 'ส่ง'},
  'save': {'KO': '저장', 'EN': 'Save', 'JA': '保存', 'ZH': '保存', 'FR': 'Enregistrer', 'DE': 'Speichern', 'RU': 'Сохранить', 'AR': 'حفظ', 'HI': 'सहेजें', 'VI': 'Lưu', 'ES': 'Guardar', 'TH': 'บันทึก'},
  'privacyNote': {'KO': '작성한 글은 본인과 관리자만 볼 수 있습니다.', 'EN': 'Only you and the administrator can see what you write.', 'JA': '投稿内容はご本人と管理者のみ閲覧できます。', 'ZH': '您发布的内容仅本人和管理员可见。', 'FR': "Seuls vous et l'administrateur pouvez voir ce que vous écrivez.", 'DE': 'Nur Sie und der Administrator können Ihre Beiträge sehen.', 'RU': 'Ваши записи видите только вы и администратор.', 'AR': 'لا يمكن رؤية ما تكتبه إلا أنت والمسؤول.', 'HI': 'आप जो लिखते हैं उसे केवल आप और व्यवस्थापक देख सकते हैं।', 'VI': 'Chỉ bạn và quản trị viên có thể xem nội dung bạn viết.', 'ES': 'Solo tú y el administrador pueden ver lo que escribes.', 'TH': 'เฉพาะคุณและผู้ดูแลระบบเท่านั้นที่เห็นสิ่งที่คุณเขียน'},
  'adminNote': {'KO': '관리자 모드: 모든 사용자의 글이 보입니다.', 'EN': 'Admin mode: showing posts from all users.', 'JA': '管理者モード：全ユーザーの投稿を表示中。', 'ZH': '管理员模式：显示所有用户的内容。', 'FR': 'Mode admin : publications de tous les utilisateurs.', 'DE': 'Admin-Modus: Beiträge aller Nutzer.', 'RU': 'Режим администратора: записи всех пользователей.', 'AR': 'وضع المسؤول: عرض منشورات جميع المستخدمين.', 'HI': 'व्यवस्थापक मोड: सभी उपयोगकर्ताओं की पोस्ट।', 'VI': 'Chế độ quản trị: hiển thị bài của mọi người dùng.', 'ES': 'Modo administrador: publicaciones de todos los usuarios.', 'TH': 'โหมดผู้ดูแล: แสดงโพสต์ของผู้ใช้ทั้งหมด'},
  'writeFeedback': {'KO': '의견 보내기', 'EN': 'Send Feedback', 'JA': 'ご意見を送る', 'ZH': '提交意见', 'FR': 'Envoyer une suggestion', 'DE': 'Feedback senden', 'RU': 'Отправить отзыв', 'AR': 'إرسال ملاحظة', 'HI': 'सुझाव भेजें', 'VI': 'Gửi góp ý', 'ES': 'Enviar opinión', 'TH': 'ส่งความคิดเห็น'},
  'applyCounsel': {'KO': '상담 신청하기', 'EN': 'Request Counseling', 'JA': '相談を申し込む', 'ZH': '申请咨询', 'FR': 'Demander un conseil', 'DE': 'Beratung anfragen', 'RU': 'Записаться на консультацию', 'AR': 'طلب استشارة', 'HI': 'परामर्श का अनुरोध करें', 'VI': 'Đăng ký tư vấn', 'ES': 'Solicitar asesoría', 'TH': 'ขอรับคำปรึกษา'},
  'noPosts': {'KO': '아직 작성한 글이 없습니다.', 'EN': "You haven't written anything yet.", 'JA': 'まだ投稿はありません。', 'ZH': '尚未发布任何内容。', 'FR': "Vous n'avez encore rien écrit.", 'DE': 'Sie haben noch nichts geschrieben.', 'RU': 'Вы ещё ничего не написали.', 'AR': 'لم تكتب أي شيء بعد.', 'HI': 'आपने अभी तक कुछ नहीं लिखा है।', 'VI': 'Bạn chưa viết gì.', 'ES': 'Aún no has escrito nada.', 'TH': 'คุณยังไม่ได้เขียนอะไร'},
  'waitingReply': {'KO': '답변 대기 중', 'EN': 'Awaiting reply', 'JA': '回答待ち', 'ZH': '等待回复', 'FR': 'En attente de réponse', 'DE': 'Antwort ausstehend', 'RU': 'Ожидает ответа', 'AR': 'بانتظار الرد', 'HI': 'उत्तर की प्रतीक्षा', 'VI': 'Đang chờ trả lời', 'ES': 'Esperando respuesta', 'TH': 'รอการตอบกลับ'},
  'replyLabel': {'KO': '답변', 'EN': 'Reply', 'JA': '回答', 'ZH': '回复', 'FR': 'Réponse', 'DE': 'Antwort', 'RU': 'Ответ', 'AR': 'الرد', 'HI': 'उत्तर', 'VI': 'Trả lời', 'ES': 'Respuesta', 'TH': 'คำตอบ'},
  'writeReply': {'KO': '답변하기', 'EN': 'Write Reply', 'JA': '回答する', 'ZH': '回复', 'FR': 'Répondre', 'DE': 'Antworten', 'RU': 'Ответить', 'AR': 'كتابة رد', 'HI': 'उत्तर दें', 'VI': 'Trả lời', 'ES': 'Responder', 'TH': 'ตอบกลับ'},
  'delete': {'KO': '삭제', 'EN': 'Delete', 'JA': '削除', 'ZH': '删除', 'FR': 'Supprimer', 'DE': 'Löschen', 'RU': 'Удалить', 'AR': 'حذف', 'HI': 'हटाएं', 'VI': 'Xóa', 'ES': 'Eliminar', 'TH': 'ลบ'},
  'deleteConfirm': {'KO': '이 글을 삭제하시겠습니까?', 'EN': 'Delete this post?', 'JA': 'この投稿を削除しますか？', 'ZH': '确定删除此内容吗？', 'FR': 'Supprimer cette publication ?', 'DE': 'Diesen Beitrag löschen?', 'RU': 'Удалить эту запись?', 'AR': 'هل تريد حذف هذا المنشور؟', 'HI': 'क्या यह पोस्ट हटाएं?', 'VI': 'Xóa bài viết này?', 'ES': '¿Eliminar esta publicación?', 'TH': 'ลบโพสต์นี้หรือไม่?'},
  'crisis': {'KO': '급하게 도움이 필요하면 청소년상담 ☎1388 (24시간)', 'EN': 'Need urgent help? Youth Counseling ☎1388 (24 hours, Korea)', 'JA': '緊急の助けが必要なら青少年相談 ☎1388（24時間・韓国）', 'ZH': '如需紧急帮助，请拨打青少年咨询 ☎1388（24小时，韩国）', 'FR': "Besoin d'aide urgente ? Conseil jeunesse ☎1388 (24h/24, Corée)", 'DE': 'Dringend Hilfe nötig? Jugendberatung ☎1388 (24 Std., Korea)', 'RU': 'Нужна срочная помощь? Молодёжная линия ☎1388 (24 часа, Корея)', 'AR': 'هل تحتاج إلى مساعدة عاجلة؟ خط استشارات الشباب ☎1388 (24 ساعة، كوريا)', 'HI': 'तुरंत मदद चाहिए? युवा परामर्श ☎1388 (24 घंटे, कोरिया)', 'VI': 'Cần giúp đỡ khẩn cấp? Tư vấn thanh thiếu niên ☎1388 (24 giờ, Hàn Quốc)', 'ES': '¿Necesitas ayuda urgente? Orientación Juvenil ☎1388 (24 h, Corea)', 'TH': 'ต้องการความช่วยเหลือด่วน? สายด่วนเยาวชน ☎1388 (24 ชม., เกาหลี)'},
  'crisisSub': {'KO': '이곳 상담은 실시간 답변이 어렵습니다. 위급한 일은 바로 전화하세요.', 'EN': 'Replies here are not real-time. For emergencies, call right away.', 'JA': 'ここでの相談はリアルタイムの回答が難しいです。緊急時はすぐにお電話ください。', 'ZH': '此处咨询无法实时回复，紧急情况请立即致电。', 'FR': "Les réponses ici ne sont pas immédiates. En cas d'urgence, appelez tout de suite.", 'DE': 'Antworten hier erfolgen nicht sofort. Im Notfall bitte sofort anrufen.', 'RU': 'Ответы здесь не мгновенные. В экстренных случаях звоните сразу.', 'AR': 'الردود هنا ليست فورية. في حالات الطوارئ اتصل فورًا.', 'HI': 'यहाँ उत्तर तुरंत नहीं मिलते। आपात स्थिति में तुरंत कॉल करें।', 'VI': 'Tư vấn tại đây không trả lời ngay. Khẩn cấp hãy gọi ngay.', 'ES': 'Aquí las respuestas no son inmediatas. En emergencias, llama de inmediato.', 'TH': 'การให้คำปรึกษาที่นี่ไม่ได้ตอบทันที หากเร่งด่วนโปรดโทรทันที'},
  'btnDiag': {'KO': '실력진단', 'EN': 'Skill Check', 'JA': '実力診断', 'ZH': '能力诊断', 'FR': 'Diagnostic de niveau', 'DE': 'Leistungscheck', 'RU': 'Проверка уровня', 'AR': 'تشخيص المستوى', 'HI': 'कौशल जाँच', 'VI': 'Chẩn đoán năng lực', 'ES': 'Diagnóstico de nivel', 'TH': 'วัดระดับความรู้'},
  'btnTextbook': {'KO': '교재 길잡이', 'EN': 'Textbook Guide', 'JA': '教材ガイド', 'ZH': '教材指南', 'FR': 'Guide des manuels', 'DE': 'Lehrbuch-Ratgeber', 'RU': 'Подбор учебников', 'AR': 'دليل الكتب', 'HI': 'पाठ्यपुस्तक गाइड', 'VI': 'Hướng dẫn giáo trình', 'ES': 'Guía de libros', 'TH': 'แนะนำหนังสือเรียน'},
  'btnOneOnOne': {'KO': '1:1 학습상담', 'EN': '1:1 Counseling', 'JA': '1:1学習相談', 'ZH': '1对1学习咨询', 'FR': 'Conseil 1:1', 'DE': '1:1-Beratung', 'RU': 'Консультация 1:1', 'AR': 'استشارة فردية', 'HI': '1:1 परामर्श', 'VI': 'Tư vấn 1:1', 'ES': 'Asesoría 1:1', 'TH': 'ปรึกษา 1:1'},
  'btnFaq': {'KO': '자주 묻는 상담', 'EN': 'Common Questions', 'JA': 'よくある相談', 'ZH': '常见咨询', 'FR': 'Questions fréquentes', 'DE': 'Häufige Fragen', 'RU': 'Частые вопросы', 'AR': 'الأسئلة الشائعة', 'HI': 'आम प्रश्न', 'VI': 'Câu hỏi thường gặp', 'ES': 'Preguntas frecuentes', 'TH': 'คำถามที่พบบ่อย'},
  'descDiag': {'KO': '지금 실력 수준 알기', 'EN': 'Check current level', 'JA': '今のレベルを知る', 'ZH': '了解当前水平', 'FR': 'Connaître le niveau actuel', 'DE': 'Aktuelles Niveau ermitteln', 'RU': 'Узнать текущий уровень', 'AR': 'معرفة المستوى الحالي', 'HI': 'वर्तमान स्तर जानें', 'VI': 'Biết trình độ hiện tại', 'ES': 'Conocer el nivel actual', 'TH': 'รู้ระดับปัจจุบัน'},
  'descTextbook': {'KO': '수준에 맞는 교재 찾기', 'EN': 'Find books for your level', 'JA': 'レベルに合う教材', 'ZH': '找到适合的教材', 'FR': 'Trouver le bon manuel', 'DE': 'Passende Bücher finden', 'RU': 'Подобрать учебник', 'AR': 'إيجاد الكتاب المناسب', 'HI': 'सही किताब खोजें', 'VI': 'Tìm sách phù hợp', 'ES': 'Encontrar el libro adecuado', 'TH': 'หาหนังสือที่เหมาะ'},
  'descOneOnOne': {'KO': '전문가에게 직접 묻기', 'EN': 'Ask an expert directly', 'JA': '専門家に直接相談', 'ZH': '直接咨询专家', 'FR': 'Demander à un expert', 'DE': 'Direkt Experten fragen', 'RU': 'Спросить эксперта', 'AR': 'اسأل خبيرًا مباشرة', 'HI': 'विशेषज्ञ से सीधे पूछें', 'VI': 'Hỏi chuyên gia trực tiếp', 'ES': 'Preguntar a un experto', 'TH': 'ถามผู้เชี่ยวชาญโดยตรง'},
  'tabNoticeStudent': {'KO': '공지사항', 'EN': 'Notices', 'JA': 'お知らせ', 'ZH': '公告事项', 'FR': 'Annonces', 'DE': 'Mitteilungen', 'RU': 'Объявления', 'AR': 'الإعلانات', 'HI': 'सूचनाएं', 'VI': 'Thông báo', 'ES': 'Avisos', 'TH': 'ประกาศ'},
  'tabBoard': {'KO': '게시판', 'EN': 'Board', 'JA': '掲示板', 'ZH': '留言板', 'FR': 'Tableau', 'DE': 'Pinnwand', 'RU': 'Доска', 'AR': 'لوحة الرسائل', 'HI': 'संदेश बोर्ड', 'VI': 'Bảng tin', 'ES': 'Tablón', 'TH': 'กระดาน'},
  'writeBoard': {'KO': '게시판에 글쓰기', 'EN': 'Write a Post', 'JA': '掲示板に書く', 'ZH': '发表留言', 'FR': 'Écrire un message', 'DE': 'Beitrag schreiben', 'RU': 'Написать сообщение', 'AR': 'كتابة منشور', 'HI': 'पोस्ट लिखें', 'VI': 'Viết bài', 'ES': 'Escribir publicación', 'TH': 'เขียนโพสต์'},
  'writeComment': {'KO': '댓글 달기', 'EN': 'Add Comment', 'JA': 'コメントする', 'ZH': '添加评论', 'FR': 'Ajouter un commentaire', 'DE': 'Kommentar hinzufügen', 'RU': 'Добавить комментарий', 'AR': 'إضافة تعليق', 'HI': 'टिप्पणी जोड़ें', 'VI': 'Thêm bình luận', 'ES': 'Añadir comentario', 'TH': 'เพิ่มความคิดเห็น'},
  'catSuggest': {'KO': '앱 건의·불편', 'EN': 'App Suggestions', 'JA': 'アプリ要望・不具合', 'ZH': '应用建议·问题', 'FR': "Suggestions pour l'app", 'DE': 'App-Vorschläge', 'RU': 'Предложения по приложению', 'AR': 'اقتراحات التطبيق', 'HI': 'ऐप सुझाव', 'VI': 'Góp ý ứng dụng', 'ES': 'Sugerencias de la app', 'TH': 'ข้อเสนอแนะแอป'},
  'catIdea': {'KO': '아이디어 제안', 'EN': 'Ideas', 'JA': 'アイデア提案', 'ZH': '创意建议', 'FR': 'Idées', 'DE': 'Ideen', 'RU': 'Идеи', 'AR': 'أفكار', 'HI': 'विचार', 'VI': 'Ý tưởng', 'ES': 'Ideas', 'TH': 'ไอเดีย'},
  'catWorry': {'KO': '공부 고민', 'EN': 'Study Worries', 'JA': '勉強の悩み', 'ZH': '学习烦恼', 'FR': "Soucis d'études", 'DE': 'Lernsorgen', 'RU': 'Трудности с учёбой', 'AR': 'هموم الدراسة', 'HI': 'पढ़ाई की चिंता', 'VI': 'Lo lắng học tập', 'ES': 'Preocupaciones de estudio', 'TH': 'ความกังวลเรื่องเรียน'},
  'catCheer': {'KO': '칭찬·응원 한마디', 'EN': 'Cheers & Thanks', 'JA': '称賛・応援の一言', 'ZH': '称赞·加油', 'FR': 'Encouragements', 'DE': 'Lob & Dank', 'RU': 'Похвала и поддержка', 'AR': 'تشجيع وشكر', 'HI': 'प्रशंसा और शुभकामनाएं', 'VI': 'Khen ngợi & Cổ vũ', 'ES': 'Ánimos y gracias', 'TH': 'คำชมและกำลังใจ'},
  'catStudyMethod': {'KO': '공부 방법', 'EN': 'Study Methods', 'JA': '勉強方法', 'ZH': '学习方法', 'FR': "Méthodes d'étude", 'DE': 'Lernmethoden', 'RU': 'Методы учёбы', 'AR': 'طرق الدراسة', 'HI': 'पढ़ाई के तरीके', 'VI': 'Phương pháp học', 'ES': 'Métodos de estudio', 'TH': 'วิธีการเรียน'},
  'catColumn': {'KO': '공부법 칼럼', 'EN': 'Study Tips Column', 'JA': '勉強法コラム', 'ZH': '学习方法专栏', 'FR': "Chronique méthodes d'étude", 'DE': 'Lerntipps-Kolumne', 'RU': 'Колонка о методах учёбы', 'AR': 'عمود نصائح الدراسة', 'HI': 'पढ़ाई टिप्स कॉलम', 'VI': 'Chuyên mục mẹo học', 'ES': 'Columna de técnicas de estudio', 'TH': 'คอลัมน์เคล็ดลับการเรียน'},
  'edit': {'KO': '수정', 'EN': 'Edit', 'JA': '編集', 'ZH': '修改', 'FR': 'Modifier', 'DE': 'Bearbeiten', 'RU': 'Изменить', 'AR': 'تعديل', 'HI': 'संपादित करें', 'VI': 'Sửa', 'ES': 'Editar', 'TH': 'แก้ไข'},
  'editPost': {'KO': '글 수정하기', 'EN': 'Edit Post', 'JA': '投稿を編集', 'ZH': '修改内容', 'FR': 'Modifier la publication', 'DE': 'Beitrag bearbeiten', 'RU': 'Изменить запись', 'AR': 'تعديل المنشور', 'HI': 'पोस्ट संपादित करें', 'VI': 'Sửa bài viết', 'ES': 'Editar publicación', 'TH': 'แก้ไขโพสต์'},
  'editNotice': {'KO': '공지 수정하기', 'EN': 'Edit Notice', 'JA': 'お知らせを編集', 'ZH': '修改公告', 'FR': "Modifier l'avis", 'DE': 'Hinweis bearbeiten', 'RU': 'Изменить объявление', 'AR': 'تعديل الإعلان', 'HI': 'सूचना संपादित करें', 'VI': 'Sửa thông báo', 'ES': 'Editar aviso', 'TH': 'แก้ไขประกาศ'},
  'editComment': {'KO': '댓글 수정하기', 'EN': 'Edit Comment', 'JA': 'コメントを編集', 'ZH': '修改评论', 'FR': 'Modifier le commentaire', 'DE': 'Kommentar bearbeiten', 'RU': 'Изменить комментарий', 'AR': 'تعديل التعليق', 'HI': 'टिप्पणी संपादित करें', 'VI': 'Sửa bình luận', 'ES': 'Editar comentario', 'TH': 'แก้ไขความคิดเห็น'},
  'editedMark': {'KO': '수정됨', 'EN': 'edited', 'JA': '編集済み', 'ZH': '已修改', 'FR': 'modifié', 'DE': 'bearbeitet', 'RU': 'изменено', 'AR': 'معدّل', 'HI': 'संपादित', 'VI': 'đã sửa', 'ES': 'editado', 'TH': 'แก้ไขแล้ว'},
  'close': {'KO': '닫기', 'EN': 'Close', 'JA': '閉じる', 'ZH': '关闭', 'FR': 'Fermer', 'DE': 'Schließen', 'RU': 'Закрыть', 'AR': 'إغلاق', 'HI': 'बंद करें', 'VI': 'Đóng', 'ES': 'Cerrar', 'TH': 'ปิด'},
  'categoryLabel': {'KO': '분류', 'EN': 'Category', 'JA': '分類', 'ZH': '分类', 'FR': 'Catégorie', 'DE': 'Kategorie', 'RU': 'Категория', 'AR': 'التصنيف', 'HI': 'श्रेणी', 'VI': 'Phân loại', 'ES': 'Categoría', 'TH': 'หมวดหมู่'},
  'deleted': {'KO': '삭제되었습니다.', 'EN': 'Deleted.', 'JA': '削除しました。', 'ZH': '已删除。', 'FR': 'Supprimé.', 'DE': 'Gelöscht.', 'RU': 'Удалено.', 'AR': 'تم الحذف.', 'HI': 'हटा दिया गया।', 'VI': 'Đã xóa.', 'ES': 'Eliminado.', 'TH': 'ลบแล้ว'},
  'seriesPrev': {'KO': '이전 편', 'EN': 'Previous', 'JA': '前編', 'ZH': '上一篇', 'FR': 'Précédent', 'DE': 'Vorheriger Teil', 'RU': 'Предыдущая часть', 'AR': 'الجزء السابق', 'HI': 'पिछला भाग', 'VI': 'Phần trước', 'ES': 'Anterior', 'TH': 'ตอนก่อนหน้า'},
  'seriesNext': {'KO': '다음 편', 'EN': 'Next', 'JA': '次編', 'ZH': '下一篇', 'FR': 'Suivant', 'DE': 'Nächster Teil', 'RU': 'Следующая часть', 'AR': 'الجزء التالي', 'HI': 'अगला भाग', 'VI': 'Phần tiếp', 'ES': 'Siguiente', 'TH': 'ตอนถัดไป'},
  'seriesLink': {'KO': '이어지는 공지 (이전 편 선택)', 'EN': 'Continues from (previous part)', 'JA': '続きのお知らせ（前編を選択）', 'ZH': '续篇公告（选择上一篇）', 'FR': 'Suite de (partie précédente)', 'DE': 'Fortsetzung von (vorheriger Teil)', 'RU': 'Продолжение (выберите предыдущую часть)', 'AR': 'تكملة لـ (الجزء السابق)', 'HI': 'आगे का भाग (पिछला भाग चुनें)', 'VI': 'Tiếp nối (chọn phần trước)', 'ES': 'Continuación de (parte anterior)', 'TH': 'ต่อจาก (เลือกตอนก่อนหน้า)'},
  'seriesNone': {'KO': '없음 (첫 편 또는 단독 공지)', 'EN': 'None (first part or standalone)', 'JA': 'なし（第1編または単独）', 'ZH': '无（第一篇或单独公告）', 'FR': 'Aucune (première partie ou seule)', 'DE': 'Keine (erster Teil oder einzeln)', 'RU': 'Нет (первая часть или отдельно)', 'AR': 'لا شيء (الجزء الأول أو منفرد)', 'HI': 'कोई नहीं (पहला भाग या अकेला)', 'VI': 'Không có (phần đầu hoặc đơn lẻ)', 'ES': 'Ninguna (primera parte o única)', 'TH': 'ไม่มี (ตอนแรกหรือเดี่ยว)'},
  'descFaq': {'KO': '기다림 없이 바로 보기', 'EN': 'Instant answers', 'JA': 'すぐに見られる', 'ZH': '即时查看', 'FR': 'Réponses immédiates', 'DE': 'Sofort-Antworten', 'RU': 'Мгновенные ответы', 'AR': 'إجابات فورية', 'HI': 'तुरंत उत्तर', 'VI': 'Xem ngay', 'ES': 'Respuestas al instante', 'TH': 'ดูได้ทันที'},
  'comingSoon': {'KO': '준비 중입니다. 곧 열립니다!', 'EN': 'Coming soon!', 'JA': '準備中です。まもなく公開！', 'ZH': '准备中，即将开放！', 'FR': 'Bientôt disponible !', 'DE': 'Demnächst verfügbar!', 'RU': 'Скоро будет доступно!', 'AR': 'قريبًا!', 'HI': 'जल्द आ रहा है!', 'VI': 'Sắp ra mắt!', 'ES': '¡Próximamente!', 'TH': 'เร็ว ๆ นี้!'},
  'chooseCategory': {'KO': '상담 분야 선택', 'EN': 'Choose a topic', 'JA': '相談分野を選択', 'ZH': '选择咨询领域', 'FR': 'Choisir un sujet', 'DE': 'Thema wählen', 'RU': 'Выберите тему', 'AR': 'اختر الموضوع', 'HI': 'विषय चुनें', 'VI': 'Chọn lĩnh vực', 'ES': 'Elige un tema', 'TH': 'เลือกหัวข้อ'},
  'replyTime': {'KO': '답변은 보통 2~3일 안에 드립니다.', 'EN': 'Replies usually arrive within 2–3 days.', 'JA': '回答は通常2〜3日以内です。', 'ZH': '通常在2~3天内回复。', 'FR': 'Réponse généralement sous 2 à 3 jours.', 'DE': 'Antwort meist innerhalb von 2–3 Tagen.', 'RU': 'Ответ обычно в течение 2–3 дней.', 'AR': 'عادةً يصل الرد خلال 2-3 أيام.', 'HI': 'उत्तर आमतौर पर 2–3 दिनों में।', 'VI': 'Thường trả lời trong 2–3 ngày.', 'ES': 'Respuesta normalmente en 2–3 días.', 'TH': 'โดยปกติจะตอบภายใน 2–3 วัน'},
  'enterContent': {'KO': '내용을 입력해 주세요.', 'EN': 'Please enter content.', 'JA': '内容を入力してください。', 'ZH': '请输入内容。', 'FR': 'Veuillez saisir un contenu.', 'DE': 'Bitte Inhalt eingeben.', 'RU': 'Введите текст.', 'AR': 'يرجى إدخال المحتوى.', 'HI': 'कृपया सामग्री दर्ज करें।', 'VI': 'Vui lòng nhập nội dung.', 'ES': 'Introduce el contenido.', 'TH': 'กรุณากรอกเนื้อหา'},
  'sent': {'KO': '전송되었습니다.', 'EN': 'Sent.', 'JA': '送信しました。', 'ZH': '已发送。', 'FR': 'Envoyé.', 'DE': 'Gesendet.', 'RU': 'Отправлено.', 'AR': 'تم الإرسال.', 'HI': 'भेजा गया।', 'VI': 'Đã gửi.', 'ES': 'Enviado.', 'TH': 'ส่งแล้ว'},
  'failed': {'KO': '실패했습니다. 다시 시도해 주세요.', 'EN': 'Failed. Please try again.', 'JA': '失敗しました。再試行してください。', 'ZH': '失败，请重试。', 'FR': 'Échec. Veuillez réessayer.', 'DE': 'Fehlgeschlagen. Bitte erneut versuchen.', 'RU': 'Ошибка. Попробуйте снова.', 'AR': 'فشل. يرجى المحاولة مرة أخرى.', 'HI': 'विफल। कृपया पुनः प्रयास करें।', 'VI': 'Thất bại. Vui lòng thử lại.', 'ES': 'Error. Inténtalo de nuevo.', 'TH': 'ล้มเหลว กรุณาลองอีกครั้ง'},
  // 공지 분류 (저장되는 값은 key 이름 그대로 - 번역되지 않는 고정 코드)
  'catImportant': {'KO': '중요', 'EN': 'Important', 'JA': '重要', 'ZH': '重要', 'FR': 'Important', 'DE': 'Wichtig', 'RU': 'Важно', 'AR': 'مهم', 'HI': 'महत्वपूर्ण', 'VI': 'Quan trọng', 'ES': 'Importante', 'TH': 'สำคัญ'},
  'catOperation': {'KO': '운영', 'EN': 'Operations', 'JA': '運営', 'ZH': '运营', 'FR': 'Fonctionnement', 'DE': 'Betrieb', 'RU': 'Работа сервиса', 'AR': 'التشغيل', 'HI': 'संचालन', 'VI': 'Vận hành', 'ES': 'Operación', 'TH': 'การดำเนินงาน'},
  'catUpdate': {'KO': '업데이트', 'EN': 'Update', 'JA': 'アップデート', 'ZH': '更新', 'FR': 'Mise à jour', 'DE': 'Update', 'RU': 'Обновление', 'AR': 'تحديث', 'HI': 'अपडेट', 'VI': 'Cập nhật', 'ES': 'Actualización', 'TH': 'อัปเดต'},
  'catEvent': {'KO': '행사', 'EN': 'Event', 'JA': 'イベント', 'ZH': '活动', 'FR': 'Événement', 'DE': 'Veranstaltung', 'RU': 'Мероприятие', 'AR': 'فعالية', 'HI': 'कार्यक्रम', 'VI': 'Sự kiện', 'ES': 'Evento', 'TH': 'กิจกรรม'},
  // 🆕 공지 대상 (저장되는 값: all / student / parent)
  'audienceLabel': {'KO': '공지 대상', 'EN': 'Audience', 'JA': 'お知らせ対象', 'ZH': '公告对象', 'FR': 'Destinataires', 'DE': 'Zielgruppe', 'RU': 'Для кого', 'AR': 'الفئة المستهدفة', 'HI': 'किसके लिए', 'VI': 'Đối tượng', 'ES': 'Destinatarios', 'TH': 'กลุ่มเป้าหมาย'},
  'audAll': {'KO': '전체', 'EN': 'Everyone', 'JA': '全員', 'ZH': '全部', 'FR': 'Tout le monde', 'DE': 'Alle', 'RU': 'Для всех', 'AR': 'الجميع', 'HI': 'सभी', 'VI': 'Tất cả', 'ES': 'Todos', 'TH': 'ทุกคน'},
  'audStudent': {'KO': '학생만', 'EN': 'Students only', 'JA': '生徒のみ', 'ZH': '仅学生', 'FR': 'Élèves seulement', 'DE': 'Nur Schüler', 'RU': 'Только ученики', 'AR': 'الطلاب فقط', 'HI': 'केवल छात्र', 'VI': 'Chỉ học sinh', 'ES': 'Solo estudiantes', 'TH': 'เฉพาะนักเรียน'},
  'audParent': {'KO': '학부모만', 'EN': 'Parents only', 'JA': '保護者のみ', 'ZH': '仅家长', 'FR': 'Parents seulement', 'DE': 'Nur Eltern', 'RU': 'Только родители', 'AR': 'أولياء الأمور فقط', 'HI': 'केवल अभिभावक', 'VI': 'Chỉ phụ huynh', 'ES': 'Solo padres', 'TH': 'เฉพาะผู้ปกครอง'},
  'audGeneral': {'KO': '일반인', 'EN': 'General users', 'JA': '一般ユーザー', 'ZH': '普通用户', 'FR': 'Utilisateurs généraux', 'DE': 'Allgemeine Nutzer', 'RU': 'Обычные пользователи', 'AR': 'المستخدمون العامون', 'HI': 'सामान्य उपयोगकर्ता', 'VI': 'Người dùng chung', 'ES': 'Usuarios generales', 'TH': 'ผู้ใช้ทั่วไป'},
  'chooseAudience': {'KO': '공지 대상을 하나 이상 선택해 주세요.', 'EN': 'Please select at least one audience.', 'JA': 'お知らせ対象を1つ以上選択してください。', 'ZH': '请至少选择一个公告对象。', 'FR': 'Veuillez choisir au moins un destinataire.', 'DE': 'Bitte mindestens eine Zielgruppe wählen.', 'RU': 'Выберите хотя бы одну группу.', 'AR': 'يرجى اختيار فئة واحدة على الأقل.', 'HI': 'कृपया कम से कम एक समूह चुनें।', 'VI': 'Vui lòng chọn ít nhất một đối tượng.', 'ES': 'Elige al menos un destinatario.', 'TH': 'กรุณาเลือกกลุ่มเป้าหมายอย่างน้อยหนึ่งกลุ่ม'},
  'screenTitleGeneral': {'KO': '공지 및 의견', 'EN': 'Notice & Feedback', 'JA': 'お知らせ・ご意見', 'ZH': '公告与意见', 'FR': 'Avis & Suggestions', 'DE': 'Hinweise & Feedback', 'RU': 'Объявления и отзывы', 'AR': 'الإعلانات والملاحظات', 'HI': 'सूचना और सुझाव', 'VI': 'Thông báo & Góp ý', 'ES': 'Avisos y Opiniones', 'TH': 'ประกาศและความคิดเห็น'},
  // 상담 분류
  'catParent': {'KO': '학부모 고민', 'EN': 'Parent Concerns', 'JA': '保護者の悩み', 'ZH': '家长烦恼', 'FR': 'Soucis des parents', 'DE': 'Anliegen der Eltern', 'RU': 'Вопросы родителей', 'AR': 'مخاوف الوالدين', 'HI': 'अभिभावक की चिंता', 'VI': 'Nỗi lo phụ huynh', 'ES': 'Inquietudes de padres', 'TH': 'ความกังวลของผู้ปกครอง'},
  'catStudent': {'KO': '학생 고민', 'EN': 'Student Concerns', 'JA': '生徒の悩み', 'ZH': '学生烦恼', 'FR': "Soucis de l'élève", 'DE': 'Anliegen der Schüler', 'RU': 'Вопросы ученика', 'AR': 'مخاوف الطالب', 'HI': 'छात्र की चिंता', 'VI': 'Nỗi lo học sinh', 'ES': 'Inquietudes del estudiante', 'TH': 'ความกังวลของนักเรียน'},
  'catChild': {'KO': '자녀 학습', 'EN': "Child's Learning", 'JA': '子どもの学習', 'ZH': '子女学习', 'FR': "Apprentissage de l'enfant", 'DE': 'Lernen des Kindes', 'RU': 'Учёба ребёнка', 'AR': 'تعلم الطفل', 'HI': 'बच्चे की पढ़ाई', 'VI': 'Việc học của con', 'ES': 'Aprendizaje del hijo', 'TH': 'การเรียนของบุตร'},
  'catSubject': {'KO': '과목 상담', 'EN': 'Subject Help', 'JA': '科目相談', 'ZH': '科目咨询', 'FR': 'Aide par matière', 'DE': 'Fachberatung', 'RU': 'Помощь по предмету', 'AR': 'مساعدة في المادة', 'HI': 'विषय सहायता', 'VI': 'Tư vấn môn học', 'ES': 'Ayuda por materia', 'TH': 'ปรึกษารายวิชา'},
  'catCareer': {'KO': '진로·진학', 'EN': 'Career & Admissions', 'JA': '進路・進学', 'ZH': '升学与职业', 'FR': 'Orientation', 'DE': 'Laufbahn & Zulassung', 'RU': 'Профориентация', 'AR': 'المسار والقبول', 'HI': 'करियर और प्रवेश', 'VI': 'Hướng nghiệp & tuyển sinh', 'ES': 'Carrera y admisiones', 'TH': 'อาชีพและการศึกษาต่อ'},
  'catFeedback': {'KO': '의견', 'EN': 'Feedback', 'JA': 'ご意見', 'ZH': '意见', 'FR': 'Suggestion', 'DE': 'Feedback', 'RU': 'Отзыв', 'AR': 'ملاحظة', 'HI': 'सुझाव', 'VI': 'Góp ý', 'ES': 'Opinión', 'TH': 'ความคิดเห็น'},
};

// ---------------------------------------------------------------------------
// 번역 도우미
// ---------------------------------------------------------------------------
// 🆕 일반인 화면은 일반 플래너의 언어 설정(appLanguage)을, 학생·학부모는 DkeLang을 따름
bool _useGeneralLang = false;
String get _curLang => _useGeneralLang ? gp.appLanguage.current : DkeLang.current;
bool get _isForeign => _useGeneralLang ? !gp.appLanguage.isDefault : DkeLang.isForeignSelected;

String _t(String k) {
  final Map<String, String>? m = _tx[k];
  if (m == null) return k;
  return m[_curLang] ?? m['EN'] ?? m['KO'] ?? k;
}

String _bi(String k) {
  final Map<String, String>? m = _tx[k];
  if (m == null) return k;
  if (_isForeign) return _t(k);
  return "${m['KO']}/${m['EN']}";
}

String _biLong(String k) {
  final Map<String, String>? m = _tx[k];
  if (m == null) return k;
  if (_isForeign) return _t(k);
  return "${m['KO']}\n${m['EN']}";
}

// 제목: 기본모드는 영문(명조체) 위 + 한글(노토산스) 아래, 외국어는 해당 언어 1줄
Widget _biTitle(String k, {double size = 15}) {
  final Map<String, String>? m = _tx[k];
  if (m == null || _isForeign) {
    return Text(_t(k), style: GoogleFonts.notoSansKr(color: _kGold, fontWeight: FontWeight.bold, fontSize: size));
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(m['EN'] ?? '', style: GoogleFonts.gowunBatang(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: size - 2)),
      Text(m['KO'] ?? '', style: GoogleFonts.notoSansKr(color: _kGold, fontWeight: FontWeight.bold, fontSize: size)),
    ],
  );
}

String _fmtDate(DateTime d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

void _snack(BuildContext context, String k) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: _kCard,
      content: Text(_biLong(k), style: GoogleFonts.notoSansKr(color: _kGold, fontWeight: FontWeight.bold, height: 1.4)),
    ),
  );
}

Widget _chip(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.notoSansKr(color: color, fontSize: 10.5, fontWeight: FontWeight.bold),
    ),
  );
}

// ============================================================================
// 🆕 [2026-09-25] 팝업 공통 디자인 - 자기주도 플래너 "알람 설정" 팝업과 같은 모양
// 금색 테두리 + 진한 남색 / 항목 제목 "English / 한글" 금색 명조체
// 아래 버튼: 왼쪽 빨간 Delete / 삭제, 오른쪽 Close / 닫기 + 금색 둥근 Save / 저장
// ============================================================================
const Color _kDlgBg = Color(0xFF070D1B);
const Color _kFieldBg = Color(0xFF111A2E);

// 기본모드: "English / 한글", 10개국어: 해당 언어만
String _enKo(String k) {
  final Map<String, String>? m = _tx[k];
  if (m == null) return k;
  if (_isForeign) return _t(k);
  return "${m['EN']} / ${m['KO']}";
}

// 팝업 안 항목 제목 (예: Category / 분류)
Widget _secLabel(String k) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(_enKo(k), style: GoogleFonts.gowunBatang(color: _kGold, fontWeight: FontWeight.bold, fontSize: 15)),
  );
}

// 선택 버튼 (선택 안 됨: 색 네모 + 글자 / 선택됨: 그 색으로 꽉 채움)
Widget _pill({required String label, required bool selected, required Color color, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? color : _kFieldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? color : Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!selected) ...[
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
          ],
          Text(label, style: GoogleFonts.notoSansKr(color: selected ? Colors.black : Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}

// 팝업 틀
Widget _luxDialog({required String titleKey, required List<Widget> children, required Widget actions}) {
  final String title = _isForeign ? _t(titleKey) : (_tx[titleKey]?['KO'] ?? titleKey);
  return Dialog(
    backgroundColor: _kDlgBg,
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: _kGold, width: 1.5),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
          const SizedBox(height: 14),
          actions,
        ],
      ),
    ),
  );
}

// 팝업 아래 버튼 줄
// 🆕 [2026-09-25 수정] Delete / Close / Save 세 글자 크기를 14로 똑같이 통일.
// 화면이 좁으면 세 버튼이 "함께 같은 비율로" 살짝 작아지므로 크기가 서로 달라지지 않음.
Widget _luxActions({
  required VoidCallback onClose,
  required VoidCallback? onSave,
  bool saving = false,
  String saveKey = 'save',
  VoidCallback? onDelete,
  bool redSave = false,
}) {
  const double fs = 14; // 🆕 세 버튼 공통 글자 크기
  final Widget deleteBtn = onDelete == null
      ? const SizedBox.shrink()
      : TextButton(
    onPressed: saving ? null : onDelete,
    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
    child: Text(_enKo('delete'), style: GoogleFonts.notoSansKr(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: fs)),
  );
  final Widget closeBtn = TextButton(
    onPressed: onClose,
    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
    child: Text(_enKo('close'), style: GoogleFonts.notoSansKr(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: fs)),
  );
  final Widget saveBtn = ElevatedButton(
    onPressed: saving ? null : onSave,
    style: ElevatedButton.styleFrom(
      backgroundColor: redSave ? Colors.redAccent : _kGold,
      disabledBackgroundColor: _kGold.withValues(alpha: 0.5),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    ),
    child: saving
        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _kBg))
        : Text(_enKo(saveKey), style: GoogleFonts.notoSansKr(color: redSave ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: fs)),
  );
  return LayoutBuilder(
    builder: (context, c) {
      // 버튼 세 개가 들어갈 최소 폭(330). 팝업이 이보다 좁으면 줄 전체를 같은 비율로 줄임
      final double rowWidth = c.maxWidth < 330 ? 330 : c.maxWidth;
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: rowWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              deleteBtn,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [closeBtn, const SizedBox(width: 4), saveBtn],
              ),
            ],
          ),
        ),
      );
    },
  );
}

// 입력 칸 (진한 칸 + 옅은 테두리)
InputDecoration _inputDeco(String hintKey) {
  return InputDecoration(
    hintText: _bi(hintKey),
    hintStyle: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 13),
    filled: true,
    fillColor: _kFieldBg,
    counterStyle: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.white12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _kGold),
    ),
  );
}

// 삭제 확인 팝업 (같은 디자인)
Future<bool> _confirmDelete(BuildContext context) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (dctx) => _luxDialog(
      titleKey: 'delete',
      children: [
        Text(_biLong('deleteConfirm'), style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 14, height: 1.5)),
      ],
      actions: _luxActions(
        onClose: () => Navigator.pop(dctx, false),
        onSave: () => Navigator.pop(dctx, true),
        saveKey: 'delete',
        redSave: true,
      ),
    ),
  );
  return ok == true;
}

const Map<String, Color> _noticeCatColors = {
  'catImportant': Color(0xFFFF3B30),
  'catOperation': Color(0xFF60A5FA),
  'catUpdate': Color(0xFF34C759),
  'catEvent': Color(0xFFAF52DE),
  'catColumn': Color(0xFFFF9500), // 🆕 공부법 칼럼
};

// 🆕 공지 대상 코드 → 번역 키 / 색
const Map<String, String> _audienceKeys = {'student': 'audStudent', 'parent': 'audParent', 'general': 'audGeneral'};
const Map<String, Color> _audienceColors = {
  'student': Color(0xFF60A5FA),
  'parent': Color(0xFFFF9500),
  'general': Color(0xFF34C759),
};

// 관리자용 대상 표시 문구: 3개 모두면 "전체", 아니면 "학생 + 학부모" 처럼
String _audienceText(List<String> auds) {
  if (kAllAudiences.every(auds.contains)) return _bi('audAll');
  return kAllAudiences.where(auds.contains).map((a) => _bi(_audienceKeys[a]!)).join(' + ');
}

// 🆕 [2026-09-25] 분류 목록
// 학부모 1:1 상담
const List<String> _parentCounselCategories = ['catParent', 'catChild', 'catSubject', 'catCareer'];
// 학생 1:1 상담
const List<String> _studentCounselCategories = ['catStudent', 'catStudyMethod', 'catSubject', 'catCareer'];
// 학생 게시판 (비공개 - 관리자만 봄)
const List<String> _studentBoardCategories = ['catSuggest', 'catIdea', 'catWorry', 'catCheer'];

// ============================================================================
// 화면 본체
// ============================================================================
class NoticeCounselScreen extends StatefulWidget {
  final bool isParent;
  final bool isGeneral; // 🆕 일반 플래너(일반인) 이용자 - 공지 + 의견함만 표시
  const NoticeCounselScreen({Key? key, required this.isParent, this.isGeneral = false}) : super(key: key);

  @override
  State<NoticeCounselScreen> createState() => _NoticeCounselScreenState();
}

class _NoticeCounselScreenState extends State<NoticeCounselScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: widget.isGeneral ? 2 : 3, vsync: this);

  // 이용자 종류: student / parent / general
  String get _role => widget.isGeneral ? 'general' : (widget.isParent ? 'parent' : 'student');
  bool get _isStudent => _role == 'student';

  // 🆕 [빨간 점 2026-09-25] 탭별 새 소식 표시
  Map<String, bool> _unread = const {'notice': false, 'board': false, 'counsel': false};
  static const List<String> _tabKeys = ['notice', 'board', 'counsel'];
  static const Map<String, String> _seenBase = {
    'notice': NoticeCounselService.kSeenNotice,
    'board': NoticeCounselService.kSeenBoard,
    'counsel': NoticeCounselService.kSeenCounsel,
  };

  @override
  void initState() {
    super.initState();
    _useGeneralLang = widget.isGeneral;
    if (widget.isGeneral) gp.appLanguage.addListener(_onLang);
    _loadUnread();
    _tab.addListener(() {
      if (!_tab.indexIsChanging) _markTabSeen(_tab.index);
    });
  }

  Future<void> _loadUnread() async {
    final Map<String, bool> r = await NoticeCounselService.checkUnread(viewer: _role);
    if (!mounted) return;
    setState(() => _unread = r);
    _markTabSeen(_tab.index); // 지금 보고 있는 첫 탭은 바로 "봤음"
  }

  void _markTabSeen(int index) {
    if (index < 0 || index >= _tabKeys.length) return;
    final String key = _tabKeys[index];
    NoticeCounselService.markSeen(_seenBase[key]!);
    if (_unread[key] == true && mounted) {
      setState(() => _unread = {..._unread, key: false});
    }
  }

  // 탭 글자 + 빨간 점
  Widget _tabLabel(String text, String key) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (_unread[key] == true) ...[
            const SizedBox(width: 4),
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
          ],
        ],
      ),
    );
  }

  void _onLang() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (widget.isGeneral) gp.appLanguage.removeListener(_onLang);
    _useGeneralLang = false;
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kGold),
        title: _biTitle(widget.isGeneral ? 'screenTitleGeneral' : 'screenTitle', size: 17),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: _kGold,
          labelColor: _kGold,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold, fontSize: 13.5),
          unselectedLabelStyle: GoogleFonts.notoSansKr(fontSize: 13),
          tabs: [
            _tabLabel('📢 ${_bi(_isStudent ? 'tabNoticeStudent' : 'tabNotice')}', 'notice'),
            _tabLabel(_isStudent ? '🗣️ ${_bi('tabBoard')}' : '💬 ${_bi('tabFeedback')}', 'board'),
            if (!widget.isGeneral) _tabLabel('🎓 ${_bi('tabCounsel')}', 'counsel'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _NoticeTab(viewer: _role),
          // 학생: 게시판(분류 4개, 비공개) / 학부모·일반인: 의견함
          _PrivatePostList(
            collection: NoticeCounselService.feedbackCol,
            role: _role,
            categories: _isStudent ? _studentBoardCategories : const <String>[],
            showCrisis: false,
            showReplyTime: false,
            writeLabelKey: _isStudent ? 'writeBoard' : 'writeFeedback',
          ),
          // 학생: 1:1 상담 목록 바로 / 학부모: 세부 버튼 화면
          if (_isStudent)
            _PrivatePostList(
              collection: NoticeCounselService.counselCol,
              role: 'student',
              categories: _studentCounselCategories,
              showCrisis: true,
              showReplyTime: true,
              writeLabelKey: 'applyCounsel',
            )
          else if (!widget.isGeneral)
            const _CounselTab(),
        ],
      ),
    );
  }
}

// ============================================================================
// 📢 공지 탭
// ============================================================================
class _NoticeTab extends StatefulWidget {
  final String viewer; // student / parent / general
  const _NoticeTab({required this.viewer});

  @override
  State<_NoticeTab> createState() => _NoticeTabState();
}

class _NoticeTabState extends State<_NoticeTab> {
  late final Stream<List<NoticeItem>> _stream = NoticeCounselService.watchNotices(viewer: widget.viewer);

  // 🆕 [연재 2026-09-25] 지금 화면에 보이는 공지 목록 (이전 편 고르기·다음 편 찾기에 사용)
  List<NoticeItem> _latest = [];

  NoticeItem? _prevOf(NoticeItem n) {
    if (n.prevId == null) return null;
    for (final NoticeItem x in _latest) {
      if (x.id == n.prevId) return x;
    }
    return null;
  }

  NoticeItem? _nextOf(NoticeItem n) {
    for (final NoticeItem x in _latest) {
      if (x.prevId == n.id) return x;
    }
    return null;
  }

  // 같은 연재는 1편 → 2편 → 3편 순서로 붙여서 보여줌.
  // 연재 묶음의 위치는 묶음 안에서 가장 위에 올 공지(고정·최신)의 자리를 따름.
  List<NoticeItem> _orderSeries(List<NoticeItem> list) {
    final Map<String, int> pos = {for (int i = 0; i < list.length; i++) list[i].id: i};
    final Map<String, NoticeItem> nextOf = {};
    for (final NoticeItem n in list) {
      if (n.prevId != null && pos.containsKey(n.prevId)) nextOf[n.prevId!] = n;
    }
    final Set<String> used = {};
    final List<List<NoticeItem>> chains = [];
    for (final NoticeItem n in list) {
      final bool hasVisiblePrev = n.prevId != null && pos.containsKey(n.prevId);
      if (hasVisiblePrev || used.contains(n.id)) continue;
      final List<NoticeItem> chain = [];
      NoticeItem? cur = n;
      while (cur != null && !used.contains(cur.id)) {
        chain.add(cur);
        used.add(cur.id);
        cur = nextOf[cur.id];
      }
      chains.add(chain);
    }
    for (final NoticeItem n in list) {
      if (!used.contains(n.id)) {
        chains.add([n]);
        used.add(n.id);
      }
    }
    int topPos(List<NoticeItem> c) => c.fold<int>(1 << 30, (m, e) => pos[e.id]! < m ? pos[e.id]! : m);
    chains.sort((a, b) => topPos(a).compareTo(topPos(b)));
    return chains.expand((c) => c).toList();
  }

  // 🆕 [연재] 공지 읽기 팝업 - 안에서 이전 편 / 다음 편으로 바로 넘겨 읽기
  Future<void> _openReader(NoticeItem start) async {
    NoticeItem cur = start;
    await showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final NoticeItem? prev = _prevOf(cur);
          final NoticeItem? next = _nextOf(cur);
          return Dialog(
            backgroundColor: _kDlgBg,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: _kGold, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cur.title, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(_fmtDate(cur.createdAt), style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 11)),
                  const SizedBox(height: 14),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(cur.body, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 14, height: 1.8)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (prev != null)
                        Expanded(child: _seriesButton(isNext: false, target: prev, onTap: () => setD(() => cur = prev)))
                      else
                        const Spacer(),
                      const SizedBox(width: 8),
                      if (next != null)
                        Expanded(child: _seriesButton(isNext: true, target: next, onTap: () => setD(() => cur = next)))
                      else
                        const Spacer(),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(dctx),
                      child: Text(_enKo('close'), style: GoogleFonts.notoSansKr(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 🆕 existing이 있으면 "공지 수정"(왼쪽 아래 Delete / 삭제 포함), 없으면 "새 공지 쓰기"
  Future<void> _openWriteNotice({NoticeItem? existing}) async {
    final TextEditingController titleCtrl = TextEditingController(text: existing?.title ?? '');
    final TextEditingController bodyCtrl = TextEditingController(text: existing?.body ?? '');
    String cat = existing?.category ?? 'catOperation';
    // 🆕 기본값: 전체(학생+학부모+일반인) 체크 - 필요한 대상만 남기고 해제
    final Set<String> audiences = Set<String>.from(existing?.audiences ?? kAllAudiences);
    bool pinned = existing?.pinned ?? false;
    String? prevId = existing?.prevId; // 🆕 [연재] 이전 편
    // 이전 편으로 고를 수 있는 공지: 자기 자신 제외
    final List<NoticeItem> prevChoices = _latest.where((n) => n.id != existing?.id).toList();
    if (prevId != null && !prevChoices.any((n) => n.id == prevId)) prevId = null;
    bool sending = false;
    await showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (ctx, setD) => _luxDialog(
          titleKey: existing == null ? 'writeNotice' : 'editNotice',
          children: [
            // 공지 대상 (여러 개 동시 선택): 학생 / 학부모 / 일반인
            _secLabel('audienceLabel'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kAllAudiences.map((a) {
                final bool sel = audiences.contains(a);
                return _pill(
                  label: _enKo(_audienceKeys[a]!),
                  selected: sel,
                  color: _audienceColors[a]!,
                  onTap: () => setD(() => sel ? audiences.remove(a) : audiences.add(a)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _secLabel('categoryLabel'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _noticeCatColors.keys.map((c) {
                return _pill(
                  label: _enKo(c),
                  selected: cat == c,
                  color: _noticeCatColors[c]!,
                  onTap: () => setD(() => cat = c),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _secLabel('fieldTitle'),
            TextField(
              controller: titleCtrl,
              maxLength: 60,
              style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14),
              decoration: _inputDeco('fieldTitle'),
            ),
            const SizedBox(height: 8),
            _secLabel('fieldContent'),
            TextField(
              controller: bodyCtrl,
              maxLines: 7,
              maxLength: 3000,
              style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14),
              decoration: _inputDeco('fieldContent'),
            ),
            const SizedBox(height: 8),
            // 🆕 [연재 2026-09-25] 이어지는 공지: 2편을 쓸 때 1편을 고르면 자동 연결
            _secLabel('seriesLink'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _kFieldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: prevId,
                  isExpanded: true,
                  dropdownColor: _kCard,
                  iconEnabledColor: _kGold,
                  style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(_enKo('seriesNone'), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    ...prevChoices.map((n) => DropdownMenuItem<String?>(
                      value: n.id,
                      child: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    )),
                  ],
                  onChanged: (v) => setD(() => prevId = v),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 맨 위 고정 (플래너의 "알람 켜기" 줄과 같은 모양)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _kFieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.push_pin_outlined, color: _kGold, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_enKo('pinTop'), style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
                  Switch(
                    value: pinned,
                    activeColor: _kGold,
                    onChanged: (v) => setD(() => pinned = v),
                  ),
                ],
              ),
            ),
          ],
          actions: _luxActions(
            saving: sending,
            onClose: () => Navigator.pop(dctx),
            onDelete: existing == null
                ? null
                : () async {
              if (!await _confirmDelete(context)) return;
              setD(() => sending = true);
              final bool ok = await NoticeCounselService.deleteNotice(existing.id);
              if (dctx.mounted) Navigator.pop(dctx);
              if (mounted) _snack(context, ok ? 'deleted' : 'failed');
            },
            onSave: () async {
              final String title = titleCtrl.text.trim();
              final String body = bodyCtrl.text.trim();
              if (title.isEmpty || body.isEmpty) {
                _snack(context, 'enterContent');
                return;
              }
              if (audiences.isEmpty) {
                _snack(context, 'chooseAudience');
                return;
              }
              setD(() => sending = true);
              final List<String> auds = kAllAudiences.where(audiences.contains).toList();
              final bool ok = existing == null
                  ? await NoticeCounselService.addNotice(
                title: title,
                body: body,
                category: cat,
                audiences: auds,
                pinned: pinned,
                prevId: prevId,
              )
                  : await NoticeCounselService.updateNotice(
                existing.id,
                title: title,
                body: body,
                category: cat,
                audiences: auds,
                pinned: pinned,
                prevId: prevId,
              );
              if (dctx.mounted) Navigator.pop(dctx);
              if (mounted) _snack(context, ok ? 'sent' : 'failed');
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool admin = NoticeCounselService.isAdmin;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: admin
          ? FloatingActionButton.extended(
        backgroundColor: _kGold,
        onPressed: () => _openWriteNotice(),
        icon: const Icon(Icons.edit_note_rounded, color: Colors.black),
        label: Text(_bi('writeNotice'), style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
      )
          : null,
      body: StreamBuilder<List<NoticeItem>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) return _EmptyBox(textKey: 'loadFailed');
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: _kGold));
          final List<NoticeItem> list = _orderSeries(snap.data!); // 🆕 [연재] 1편→2편 순서로 붙임
          _latest = list;
          if (list.isEmpty) return _EmptyBox(textKey: 'noNotice');
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _NoticeCard(
              item: list[i],
              admin: admin,
              onEdit: () => _openWriteNotice(existing: list[i]),
              prev: _prevOf(list[i]),
              next: _nextOf(list[i]),
              onOpen: _openReader,
            ),
          );
        },
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final NoticeItem item;
  final bool admin;
  final VoidCallback onEdit;
  final NoticeItem? prev; // 🆕 [연재] 이전 편
  final NoticeItem? next; // 🆕 [연재] 다음 편
  final void Function(NoticeItem) onOpen; // 🆕 [연재] 읽기 팝업 열기
  const _NoticeCard({
    required this.item,
    required this.admin,
    required this.onEdit,
    this.prev,
    this.next,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final Color catColor = _noticeCatColors[item.category] ?? _kGold;
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGold.withValues(alpha: item.pinned ? 0.7 : 0.2), width: item.pinned ? 1.4 : 1.0),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: _kGold,
          collapsedIconColor: Colors.white54,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (item.pinned) const Text('📌 ', style: TextStyle(fontSize: 13)),
                  Flexible(child: _chip(_bi(item.category), catColor)),
                  // 🆕 관리자에게만 공지 대상(공통/학생만/학부모만) 표시
                  if (admin) ...[
                    const SizedBox(width: 6),
                    Flexible(child: _chip(_audienceText(item.audiences), Colors.white70)),
                    const Spacer(),
                    // 🆕 관리자: 삼색선+연필 → 수정 / 삭제
                    _EditMenuIcon(
                      onEdit: onEdit,
                      onDelete: () async {
                        if (!await _confirmDelete(context)) return;
                        final bool ok = await NoticeCounselService.deleteNotice(item.id);
                        if (!ok && context.mounted) _snack(context, 'failed');
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(item.title, style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_fmtDate(item.createdAt), style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10.5)),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(item.body, style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 13, height: 1.7)),
            ),
            // 🆕 [연재 2026-09-25] ◀ 이전 편 / 다음 편 ▶ - 누르면 읽기 팝업으로 바로 이동
            if (prev != null || next != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (prev != null)
                    Expanded(child: _seriesButton(isNext: false, target: prev!, onTap: () => onOpen(prev!)))
                  else
                    const Spacer(),
                  const SizedBox(width: 8),
                  if (next != null)
                    Expanded(child: _seriesButton(isNext: true, target: next!, onTap: () => onOpen(next!)))
                  else
                    const Spacer(),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 🆕 [연재 2026-09-25] ◀ 이전 편 / 다음 편 ▶ 버튼 (위: 이전·다음, 아래: 그 공지 제목)
Widget _seriesButton({required bool isNext, required NoticeItem target, required VoidCallback onTap}) {
  return InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _kGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kGold.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: isNext ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            isNext ? '${_bi('seriesNext')} ▶' : '◀ ${_bi('seriesPrev')}',
            style: GoogleFonts.notoSansKr(color: _kGold, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            target.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: isNext ? TextAlign.right : TextAlign.left,
            style: GoogleFonts.notoSansKr(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

// ============================================================================
// 🆕 [2026-09-25] 수정·삭제 아이콘 (삼색선 + 연필) - 자기주도 플래너 일정 목록과 같은 모양
// 누르면 가운데 팝업: 본인 글·공지·댓글 = 수정 팝업(왼쪽 아래 Delete / 삭제) / 관리자가 남의 글 = 삭제 확인 팝업
// ============================================================================
class _EditMenuIcon extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback onDelete;
  const _EditMenuIcon({this.onEdit, required this.onDelete});

  // 🆕 수정 가능하면 바로 수정 팝업(안에 Delete / 삭제 있음), 삭제만 가능하면 삭제 확인 팝업
  void _open() {
    if (onEdit != null) {
      onEdit!();
    } else {
      onDelete();
    }
  }

  Widget _bar(double top, double width, Color color) {
    return Positioned(
      left: 0,
      top: top,
      child: Container(
        width: width,
        height: 3.5,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _open,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          width: 26,
          height: 22,
          child: Stack(
            children: [
              _bar(2, 20, const Color(0xFFFF3B30)), // 빨강
              _bar(8, 20, const Color(0xFFFFCC00)), // 노랑
              _bar(14, 14, const Color(0xFF3B82F6)), // 파랑
              const Positioned(
                right: 0,
                bottom: 0,
                child: Icon(Icons.edit, color: _kGold, size: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String textKey;
  const _EmptyBox({required this.textKey});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          _biLong(textKey),
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 13, height: 1.6),
        ),
      ),
    );
  }
}

// ============================================================================
// ☎ 1388 위기 안내 띠
// ============================================================================
class _CrisisBanner extends StatelessWidget {
  const _CrisisBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A0F12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.support_agent_rounded, color: Colors.redAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_biLong('crisis'), style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5, height: 1.4)),
                const SizedBox(height: 4),
                Text(_biLong('crisisSub'), style: GoogleFonts.notoSansKr(color: Colors.white60, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 💬 게시판 / 의견함 / 1:1 상담 공용 목록 (본인 글만, 관리자는 전체)
// 🆕 [2026-09-25] 댓글은 관리자만 여러 개 달 수 있음 (학생·학부모·일반인은 댓글 불가)
// ============================================================================
class _PrivatePostList extends StatefulWidget {
  final String collection;
  final String role; // student / parent / general
  final List<String> categories; // 비어 있으면 분류 선택 없음
  final bool showCrisis; // 1388 안내 표시 여부
  final bool showReplyTime; // "2~3일 안에 답변" 안내 표시 여부
  final String writeLabelKey;

  const _PrivatePostList({
    required this.collection,
    required this.role,
    required this.categories,
    required this.showCrisis,
    required this.showReplyTime,
    required this.writeLabelKey,
  });

  @override
  State<_PrivatePostList> createState() => _PrivatePostListState();
}

class _PrivatePostListState extends State<_PrivatePostList> {
  late final Stream<List<PrivatePost>> _stream = NoticeCounselService.watchPosts(widget.collection);

  Widget _infoLine(IconData icon, String k) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _kGold.withValues(alpha: 0.8), size: 15),
        const SizedBox(width: 6),
        Expanded(child: Text(_biLong(k), style: GoogleFonts.notoSansKr(color: Colors.white60, fontSize: 11, height: 1.4))),
      ],
    );
  }

  // 🆕 existing이 있으면 "글 수정"(왼쪽 아래 Delete / 삭제 포함), 없으면 "새 글 쓰기"
  Future<void> _openWriteDialog({PrivatePost? existing}) async {
    final TextEditingController ctrl = TextEditingController(text: existing?.text ?? '');
    final List<String> cats = widget.categories;
    String cat = existing?.category ?? (cats.isNotEmpty ? cats.first : 'catFeedback');
    bool sending = false;
    await showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (ctx, setD) => _luxDialog(
          titleKey: existing == null ? widget.writeLabelKey : 'editPost',
          children: [
            if (cats.isNotEmpty) ...[
              _secLabel('categoryLabel'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cats.map((c) {
                  return _pill(
                    label: _enKo(c),
                    selected: cat == c,
                    color: _kGold,
                    onTap: () => setD(() => cat = c),
                  );
                }).toList(),
              ),
              // 마음 고민·공부 고민을 고르면 1388 안내를 한 번 더 보여줌
              if (cat == 'catStudent' || cat == 'catWorry') ...[
                const SizedBox(height: 12),
                const _CrisisBanner(),
              ],
              const SizedBox(height: 16),
            ],
            _secLabel('fieldContent'),
            TextField(
              controller: ctrl,
              maxLines: 6,
              maxLength: 1000,
              style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14),
              decoration: _inputDeco('fieldContent'),
            ),
          ],
          actions: _luxActions(
            saving: sending,
            saveKey: existing == null ? 'submit' : 'save',
            onClose: () => Navigator.pop(dctx),
            onDelete: existing == null
                ? null
                : () async {
              if (!await _confirmDelete(context)) return;
              setD(() => sending = true);
              final bool ok = await NoticeCounselService.deletePost(widget.collection, existing.id);
              if (dctx.mounted) Navigator.pop(dctx);
              if (mounted) _snack(context, ok ? 'deleted' : 'failed');
            },
            onSave: () async {
              final String text = ctrl.text.trim();
              if (text.isEmpty) {
                _snack(context, 'enterContent');
                return;
              }
              setD(() => sending = true);
              final bool ok = existing == null
                  ? await NoticeCounselService.addPost(
                widget.collection,
                text: text,
                category: cat,
                role: widget.role,
              )
                  : await NoticeCounselService.updatePost(
                widget.collection,
                existing.id,
                text: text,
                category: cat,
              );
              if (dctx.mounted) Navigator.pop(dctx);
              if (mounted) _snack(context, ok ? 'sent' : 'failed');
            },
          ),
        ),
      ),
    );
  }

  // 🆕 관리자 댓글 달기 (여러 번 가능) / existing이 있으면 "댓글 수정"(Delete / 삭제 포함)
  Future<void> _openCommentDialog(PrivatePost p, {PostComment? existing}) async {
    final TextEditingController ctrl = TextEditingController(text: existing?.text ?? '');
    bool sending = false;
    await showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (ctx, setD) => _luxDialog(
          titleKey: existing == null ? 'writeComment' : 'editComment',
          children: [
            _secLabel('fieldContent'),
            TextField(
              controller: ctrl,
              maxLines: 6,
              maxLength: 2000,
              style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 14),
              decoration: _inputDeco('fieldContent'),
            ),
          ],
          actions: _luxActions(
            saving: sending,
            onClose: () => Navigator.pop(dctx),
            onDelete: existing == null
                ? null
                : () async {
              if (!await _confirmDelete(context)) return;
              setD(() => sending = true);
              final bool ok = await NoticeCounselService.deleteComment(widget.collection, p.id, existing);
              if (dctx.mounted) Navigator.pop(dctx);
              if (mounted) _snack(context, ok ? 'deleted' : 'failed');
            },
            onSave: () async {
              final String text = ctrl.text.trim();
              if (text.isEmpty) {
                _snack(context, 'enterContent');
                return;
              }
              setD(() => sending = true);
              final bool ok = existing == null
                  ? await NoticeCounselService.addComment(widget.collection, p.id, text)
                  : await NoticeCounselService.editComment(widget.collection, p.id, existing, text);
              if (dctx.mounted) Navigator.pop(dctx);
              if (mounted) _snack(context, ok ? 'sent' : 'failed');
            },
          ),
        ),
      ),
    );
  }

  Widget _commentBox(PrivatePost p, PostComment c, bool admin) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kGold.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mark_chat_read_rounded, color: _kGold, size: 15),
              const SizedBox(width: 6),
              Expanded(child: Text(_bi('replyLabel'), style: GoogleFonts.notoSansKr(color: _kGold, fontWeight: FontWeight.bold, fontSize: 12))),
              Text(_fmtDate(c.createdAt), style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10)),
              if (admin) ...[
                const SizedBox(width: 4),
                // 🆕 관리자 댓글: 삼색선+연필 → 수정 / 삭제
                _EditMenuIcon(
                  onEdit: () => _openCommentDialog(p, existing: c),
                  onDelete: () async {
                    if (!await _confirmDelete(context)) return;
                    final bool ok = await NoticeCounselService.deleteComment(widget.collection, p.id, c);
                    if (!ok && mounted) _snack(context, 'failed');
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(c.text, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }

  Widget _postCard(PrivatePost p, bool admin) {
    final bool mine = p.uid == NoticeCounselService.myUid;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGold.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.categories.isNotEmpty || admin) Flexible(child: _chip(_bi(p.category), _kGold)),
              if (admin) ...[
                const SizedBox(width: 6),
                Text(p.role == 'parent' ? '👪' : (p.role == 'general' ? '🗓️' : '🎒'), style: const TextStyle(fontSize: 14)),
              ],
              const Spacer(),
              Text(
                p.edited ? '${_fmtDate(p.createdAt)} · ${_t('editedMark')}' : _fmtDate(p.createdAt),
                style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 10.5),
              ),
              if (mine || admin) ...[
                const SizedBox(width: 4),
                // 🆕 삼색선+연필 → 수정(본인 글만) / 삭제(본인 글 + 관리자)
                _EditMenuIcon(
                  onEdit: mine ? () => _openWriteDialog(existing: p) : null,
                  onDelete: () async {
                    if (!await _confirmDelete(context)) return;
                    final bool ok = await NoticeCounselService.deletePost(widget.collection, p.id);
                    if (!ok && mounted) _snack(context, 'failed');
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(p.text, style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 13, height: 1.6)),
          const SizedBox(height: 4),
          if (p.comments.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('⏳ ${_bi('waitingReply')}', style: GoogleFonts.notoSansKr(color: Colors.white38, fontSize: 11.5)),
            )
          else
            ...p.comments.map((c) => _commentBox(p, c, admin)),
          if (admin)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _openCommentDialog(p),
                icon: const Icon(Icons.add_comment_rounded, color: _kGold, size: 18),
                label: Text(_bi('writeComment'), style: GoogleFonts.notoSansKr(color: _kGold, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool admin = NoticeCounselService.isAdmin;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              if (widget.showCrisis) ...[
                const _CrisisBanner(),
                const SizedBox(height: 10),
              ],
              _infoLine(Icons.lock_outline_rounded, admin ? 'adminNote' : 'privacyNote'),
              if (widget.showReplyTime) ...[
                const SizedBox(height: 4),
                _infoLine(Icons.schedule_rounded, 'replyTime'),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _openWriteDialog(),
                  icon: const Icon(Icons.edit_rounded, color: Colors.black, size: 18),
                  label: Text(_bi(widget.writeLabelKey), style: GoogleFonts.notoSansKr(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<PrivatePost>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return _EmptyBox(textKey: 'loadFailed');
              if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: _kGold));
              final List<PrivatePost> list = snap.data!;
              if (list.isEmpty) return _EmptyBox(textKey: 'noPosts');
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _postCard(list[i], admin),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 🎓 학부모용 교육상담 탭 - 세부 버튼 4개 (학생은 1:1 상담 목록이 바로 나옴)
// ============================================================================
class _CounselTab extends StatelessWidget {
  const _CounselTab();

  Widget _menuTile(BuildContext context, String emoji, String titleKey, String descKey, VoidCallback onTap) {
    return Material(
      color: _kCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kGold.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                _bi(titleKey),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSansKr(color: _kGold, fontWeight: FontWeight.bold, fontSize: 12.5, height: 1.3),
              ),
              const SizedBox(height: 4),
              Text(
                _bi(descKey),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSansKr(color: Colors.white54, fontSize: 10, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _CrisisBanner(),
        const SizedBox(height: 18),
        _biTitle('tabCounsel'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: [
            _menuTile(context, '🩺', 'btnDiag', 'descDiag', () => _snack(context, 'comingSoon')),
            _menuTile(context, '📚', 'btnTextbook', 'descTextbook', () => _snack(context, 'comingSoon')),
            _menuTile(context, '💬', 'btnOneOnOne', 'descOneOnOne', () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _OneOnOnePage()),
              );
            }),
            _menuTile(context, '📖', 'btnFaq', 'descFaq', () => _snack(context, 'comingSoon')),
          ],
        ),
      ],
    );
  }
}

class _OneOnOnePage extends StatelessWidget {
  const _OneOnOnePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kGold),
        title: _biTitle('btnOneOnOne', size: 16),
      ),
      body: const _PrivatePostList(
        collection: NoticeCounselService.counselCol,
        role: 'parent',
        categories: _parentCounselCategories,
        showCrisis: true,
        showReplyTime: true,
        writeLabelKey: 'applyCounsel',
      ),
    );
  }
}
