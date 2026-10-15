// lib/community/textbook_guide_screen.dart
//
// 🆕 [2026-10-12] 교재 길잡이 (교육상담 → 📚 교재 길잡이)
// 🔧 [2026-10-12 2차] 원장님 설계로 변경
// - 실력 진단 = 진단평가 점수 + 질문 10개(교과 공통 5 + 과목별 5) → 점수 · 선행 · 문해력 세 가지로 판정
//   · 기본 : 60점 이하, 또는 선행 안 됨(90점 미만)          → 개념원리 · 이유있는 수학 → 집중 문제집 RPM
//   · 실력 : 선행 됨 + 90점 미만 (문해력 보강 필요)          → 쎈 수학 B단계 집중
//            또는 90점 이상이지만 선행 · 문해력 중 하나 부족
//   · 심화 : 90점 이상 + 선행 됨 + 문해력 좋음               → 최고수준 → 블랙라벨 → A급 수학 순서
// - 진단 결과는 자녀 · 과목별로 폰에 저장 (다시 들어와도 유지)
// - 추천 교재는 "푸는 순서" 번호대로 보여 줌. 순서 · 단계 · 학년은 원장님이 관리 화면에서 직접 정함
// - 관리자(원장님 계정)에게만 화면 맨 위에 [교재 관리] 금색 막대가 보임
// 🔧 [2026-10-14 12차] 학생 모드 (TextbookGuideScreen(isStudent: true)) — 공지 및 교육상담 → 상담 탭 금색 버튼
//   · 학생 안내 팝업 · 본인 성적으로 판정 · [부모님께 이 교재 알리기] · [부모님께 진단 결과 알리기]
//   · 알림은 links/{학생 코드} 문서의 textbookPick · textbookDiag → 부모님 교재 길잡이 자녀 칸 아래 💌 카드
// 🔧 [2026-10-14 11차] 국어 · 과학 · 사회 교재 다시 정리 (시중 인기 교재, 4단계)
//   · 중등부 5과목 [내신] 교과서 평가문제집 + 학교 기출문제집(백발백중 등) 필수
//   · 고등부 [수능 파이널] (고3 · N수생) 국어 · 수학 · 영어 · 과탐 · 사탐 / 통합과학 · 통합사회 칸에서 고2 · 고3 = 과탐 · 사탐
// 🔧 [2026-10-14 10차] 국어 · 수학 · 과학 · 사회(통합사회) 진단도 원장님 진단지로 교체
//   · 과목 공통 6문항 + [초등부][중등부][고등부] 선택 버튼 → 교과 10문항 (통합과학 → 과학, 통합사회 → 사회 세트)
//   · 역사 · 세계사 · 기술/가정 · 한문 · 제2외국어는 기존 전교과 공통 6 + 과목 5문항 그대로
// 🔧 [2026-10-14 9차] 영어 진단: 영어 공통 6문항 + 초등부 · 중등부 · 고등부 영어 교과 각 10문항 (선택 버튼)
//   · 측정 의도는 코드에만, 리포트에 지표별 🟢🟡🔴 + 문항별 처방(원장님 'AI/리포트 활용')
//   · 영어는 선행 문항이 없어 점수 + 문해력으로 판정, 상향 문항 2개 이상 '그렇다'면 한 단계 올림(실력까지)
// 🔧 [2026-10-14 8차] 원장님 영어 교재 DB (초 · 중 · 고, 문법 · 독해 · 듣기 · 쓰기) 반영
//   · 시중에 있는 책 이름으로 확인 · 교체 (교보 · 예스24 · 출판사 확인), 제목 앞 [문법] [독해] [듣기] [쓰기]
// 🔧 [2026-10-13 7차] 원장님 설계대로 4단계: 🌱 개념 · 🌿 기본 · 🌳 실력 · 🌲 심화
//   · 판정: 60점 미만 개념 / 60~79 기본 / 80~89 실력(선행 됨, 아니면 기본) / 90 이상 심화(선행 + 문해력, 아니면 실력)
//   · 수학 교재 다시 배치: 개념서 → 개념 단계, 기본 유형서 → 기본 단계, 실력서 → 실력, 심화서 → 심화
//   · 중등부 · 고등부 학년은 [중등부 1][중등부 2][중등부 3] 직사각형 3칸 (초등부는 그대로)
//   · 교재 길잡이를 열면 🌸 안내 팝업 (원장님 글), 화면 위 ⓘ 로 다시 보기
// 🔧 [2026-10-13 6차] 교재 설명 제목을 '왜 이 교재인가요 / 이렇게 공부하세요'로 되돌리고
//   수학 48권 내용을 '특징 + 추천 이유' / '어떤 학생에게 + 구체적 공부법'으로 합쳐 정리
//   관리 화면에 [전체 지우고 기본 목록 새로 넣기] (확인 두 번) 추가
// 🔧 [2026-10-13 5차] 원장님 수학 교재 DB (초 · 중 · 고) 반영
//   · 단계 4칸: 개념서 · 기본 유형서 · 실력서 · 심화서 (+ 기출 · 내신)
//   · 개념 · 기본 → 기본 단계 / 실력 → 실력 단계 / 심화 → 심화 단계
//   · 푸는 순서 1~9 = 순서대로 풀 교재(번호 표시) / 10 이상 = '이런 교재도 좋아요'(다른 선택지)
// 🔧 [2026-10-13 4차] 원장님 진단지 적용 (수학 먼저)
//   · 전교과 공통 6문항 + 수학 9문항. 측정 의도는 코드(_Q.intent)에만 있고 질문 화면에는 안 보임
//   · 판정 후 [진단 리포트] 화면: 지표별 🟢 우수 / 🟡 보통 / 🔴 보완 필요 + 입체 분석 + 종합 처방 + 추천 교재
//   · 부모님이 리포트를 보고 [이대로 진행 (확인)]을 눌러야 단계가 적용됨
//   · 다른 과목은 아직 이전 5문항 (수학 확인 후 같은 틀로 작업 예정)
// 🔧 [2026-10-12 3차] 학부 → 학년 → 과목 순서로 선택
//   · 초등부: 국어 · 수학 · 영어 · 과학 · 사회
//   · 중등부: 국어 · 영어 · 수학 · 과학 · 사회 · 역사 · 세계사 · 기술/가정 · 한문
//   · 고등부: 국어 · 영어 · 수학 · 제2외국어 · 통합사회 · 통합과학 · 역사
//   · 기본 교재 목록(예시)을 모든 학부 · 과목에 넣을 수 있고, 관리 화면에서 학부 · 과목별로 보며 추가 · 수정
// - 글자체: 영문 = 진한 명조(고운바탕 굵게) / 한글 = 노토산스 KR / 10개 외국어 = 그 나라 말 한 줄
//   (진단 질문은 한글 · 영어만, 다른 언어는 영어로 보임)

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gsu_studyup/global_lang.dart';
import 'package:gsu_studyup/services/family_link_service.dart';
import 'package:gsu_studyup/services/notice_counsel_service.dart';
import 'package:gsu_studyup/services/subject_category.dart';

const Color _kBg = Color(0xFF030712);
const Color _kGold = Color(0xFFE5C158);
const Color _kWhite = Color(0xFFEFEFEF);
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

// ============================================================================
// 글자 (12개 언어). 관리자 화면 글자는 KO · EN만
// ============================================================================
const Map<String, Map<String, String>> _tx = {
  'title': {'KO': '교재 길잡이', 'EN': 'Textbook Guide', 'JA': '教材ガイド', 'ZH': '教材指南', 'FR': 'Guide des manuels', 'DE': 'Lehrbuch-Ratgeber', 'RU': 'Гид по учебникам', 'AR': 'دليل الكتب الدراسية', 'HI': 'पाठ्यपुस्तक गाइड', 'VI': 'Hướng dẫn chọn sách', 'ES': 'Guía de libros', 'TH': 'คู่มือเลือกหนังสือ'},
  'pickChild': {'KO': '자녀', 'EN': 'Child', 'JA': '子ども', 'ZH': '孩子', 'FR': 'Enfant', 'DE': 'Kind', 'RU': 'Ребёнок', 'AR': 'الطفل', 'HI': 'बच्चा', 'VI': 'Con', 'ES': 'Hijo/a', 'TH': 'บุตร'},
  'noChild': {'KO': '연결된 자녀가 없어요. 학년과 과목을 직접 골라 보세요.', 'EN': 'No linked child. Choose the grade and subject yourself.', 'JA': '連携した子どもがいません。学年と科目を選んでください。', 'ZH': '没有关联的孩子，请自行选择年级和科目。', 'FR': 'Aucun enfant lié. Choisis le niveau et la matière.', 'DE': 'Kein Kind verknüpft. Wähle Stufe und Fach selbst.', 'RU': 'Нет связанного ребёнка. Выберите класс и предмет.', 'AR': 'لا يوجد طفل مرتبط. اختر الصف والمادة بنفسك.', 'HI': 'कोई बच्चा जुड़ा नहीं। कक्षा और विषय स्वयं चुनें।', 'VI': 'Chưa liên kết con. Hãy tự chọn lớp và môn.', 'ES': 'No hay hijo vinculado. Elige curso y materia.', 'TH': 'ยังไม่ได้เชื่อมบุตร เลือกชั้นและวิชาเองได้'},
  'division': {'KO': '학부', 'EN': 'School Level', 'JA': '学部', 'ZH': '学段', 'FR': 'Cycle', 'DE': 'Schulstufe', 'RU': 'Ступень', 'AR': 'المرحلة', 'HI': 'स्तर', 'VI': 'Cấp học', 'ES': 'Etapa', 'TH': 'ระดับชั้น'},
  'divElem': {'KO': '초등부', 'EN': 'Elementary', 'JA': '小学部', 'ZH': '小学部', 'FR': 'Primaire', 'DE': 'Grundschule', 'RU': 'Начальная', 'AR': 'الابتدائية', 'HI': 'प्राथमिक', 'VI': 'Tiểu học', 'ES': 'Primaria', 'TH': 'ประถม'},
  'divMid': {'KO': '중등부', 'EN': 'Middle School', 'JA': '中学部', 'ZH': '初中部', 'FR': 'Collège', 'DE': 'Mittelstufe', 'RU': 'Средняя', 'AR': 'المتوسطة', 'HI': 'माध्यमिक', 'VI': 'THCS', 'ES': 'Secundaria', 'TH': 'มัธยมต้น'},
  'divHigh': {'KO': '고등부', 'EN': 'High School', 'JA': '高校部', 'ZH': '高中部', 'FR': 'Lycée', 'DE': 'Oberstufe', 'RU': 'Старшая', 'AR': 'الثانوية', 'HI': 'उच्च माध्यमिक', 'VI': 'THPT', 'ES': 'Bachillerato', 'TH': 'มัธยมปลาย'},
  'grade': {'KO': '학년', 'EN': 'Grade', 'JA': '学年', 'ZH': '年级', 'FR': 'Niveau', 'DE': 'Klasse', 'RU': 'Класс', 'AR': 'الصف', 'HI': 'कक्षा', 'VI': 'Lớp', 'ES': 'Curso', 'TH': 'ชั้น'},
  'subject': {'KO': '과목', 'EN': 'Subject', 'JA': '科目', 'ZH': '科目', 'FR': 'Matière', 'DE': 'Fach', 'RU': 'Предмет', 'AR': 'المادة', 'HI': 'विषय', 'VI': 'Môn', 'ES': 'Materia', 'TH': 'วิชา'},
  'level': {'KO': '실력 단계', 'EN': 'Skill Level', 'JA': '実力段階', 'ZH': '实力阶段', 'FR': 'Niveau', 'DE': 'Leistungsstufe', 'RU': 'Уровень', 'AR': 'مستوى المهارة', 'HI': 'स्तर', 'VI': 'Trình độ', 'ES': 'Nivel', 'TH': 'ระดับ'},
  'lvConcept': {'KO': '개념', 'EN': 'Concept', 'JA': '概念', 'ZH': '概念', 'FR': 'Notions', 'DE': 'Grundbegriffe', 'RU': 'Понятия', 'AR': 'المفاهيم', 'HI': 'अवधारणा', 'VI': 'Khái niệm', 'ES': 'Conceptos', 'TH': 'แนวคิด'},
  'lvBasic': {'KO': '기본', 'EN': 'Basic', 'JA': '基本', 'ZH': '基础', 'FR': 'Base', 'DE': 'Basis', 'RU': 'Базовый', 'AR': 'أساسي', 'HI': 'बुनियादी', 'VI': 'Cơ bản', 'ES': 'Básico', 'TH': 'พื้นฐาน'},
  'lvSkilled': {'KO': '실력', 'EN': 'Intermediate', 'JA': '実力', 'ZH': '提高', 'FR': 'Intermédiaire', 'DE': 'Mittel', 'RU': 'Средний', 'AR': 'متوسط', 'HI': 'मध्यम', 'VI': 'Khá', 'ES': 'Intermedio', 'TH': 'กลาง'},
  'lvAdvanced': {'KO': '심화', 'EN': 'Advanced', 'JA': '発展', 'ZH': '拔高', 'FR': 'Avancé', 'DE': 'Fortgeschritten', 'RU': 'Продвинутый', 'AR': 'متقدم', 'HI': 'उन्नत', 'VI': 'Nâng cao', 'ES': 'Avanzado', 'TH': 'ขั้นสูง'},
  'lvConceptDesc': {'KO': '수학의 재미를 느끼고 탄탄한 기초를 쌓는 자신감의 시작 (60점 미만)', 'EN': 'Enjoy math and build solid foundations (below 60)', 'JA': '数学の楽しさを知り基礎を固める自信の第一歩（60点未満）', 'ZH': '感受数学乐趣、打牢基础的自信起点（60分以下）', 'FR': 'Aimer les maths et poser des bases solides (< 60)', 'DE': 'Freude an Mathe und solide Grundlagen (unter 60)', 'RU': 'Полюбить математику и заложить основу (ниже 60)', 'AR': 'الاستمتاع بالرياضيات وبناء أساس متين (أقل من 60)', 'HI': 'गणित का आनंद और मज़बूत आधार (60 से कम)', 'VI': 'Yêu toán và xây nền tảng vững (dưới 60)', 'ES': 'Disfrutar las mates y crear bases sólidas (< 60)', 'TH': 'สนุกกับคณิตและปูพื้นให้แน่น (ต่ำกว่า 60)'},
  'lvBasicDesc': {'KO': '원리를 바로 알고 스스로 풀어내는 성취감의 경험 (60~79점)', 'EN': 'Understand principles and solve on your own (60–79)', 'JA': '原理を理解し自力で解く達成感（60〜79点）', 'ZH': '理解原理、独立解题的成就感（60~79分）', 'FR': 'Comprendre et résoudre seul (60–79)', 'DE': 'Prinzipien verstehen, selbst lösen (60–79)', 'RU': 'Понимать принципы и решать самому (60–79)', 'AR': 'فهم المبادئ والحل الذاتي (60–79)', 'HI': 'सिद्धांत समझकर खुद हल करना (60–79)', 'VI': 'Hiểu nguyên lý và tự giải (60–79)', 'ES': 'Entender y resolver solo (60–79)', 'TH': 'เข้าใจหลักการและแก้โจทย์เอง (60–79)'},
  'lvSkilledDesc': {'KO': '다양한 응용 문제로 사고력을 넓히는 도약 (80점 이상 · 선행 됨)', 'EN': 'Leap forward with varied applied problems (80+ · studied ahead)', 'JA': '多様な応用問題で思考力を広げる飛躍（80点以上・先取り済）', 'ZH': '用多样应用题拓展思维的飞跃（80分以上 · 已预习）', 'FR': 'Progresser avec des problèmes variés (80+ · avance)', 'DE': 'Sprung nach vorn mit Anwendungsaufgaben (ab 80 · vorgelernt)', 'RU': 'Рывок с прикладными задачами (80+ · опережение)', 'AR': 'قفزة بمسائل تطبيقية متنوعة (80+ · تعلم مسبق)', 'HI': 'विविध अनुप्रयोग प्रश्नों से छलांग (80+ · अग्रिम पढ़ाई)', 'VI': 'Bứt phá với bài vận dụng (≥80 · đã học trước)', 'ES': 'Dar el salto con problemas aplicados (80+ · adelanto)', 'TH': 'ก้าวกระโดดด้วยโจทย์ประยุกต์ (80+ · เรียนล่วงหน้า)'},
  'lvAdvancedDesc': {'KO': '최고난도에 기꺼이 도전하며 한계를 넘어서는 결실 (90점 이상 · 선행 · 문해력 좋음)', 'EN': 'Take on the hardest problems and go beyond limits (90+ · ahead · strong reading)', 'JA': '最難関に挑み限界を超える実り（90点以上・先取り・読解力良好）', 'ZH': '挑战最高难度、突破极限（90分以上 · 已预习 · 阅读力好）', 'FR': 'Relever les défis les plus durs (90+ · avance · bonne lecture)', 'DE': 'Schwerste Aufgaben meistern (ab 90 · vorgelernt · gutes Lesen)', 'RU': 'Сложнейшие задачи и новые высоты (90+ · опережение · чтение)', 'AR': 'تحدي أصعب المسائل وتجاوز الحدود (90+ · تعلم مسبق · قراءة جيدة)', 'HI': 'सबसे कठिन प्रश्नों की चुनौती (90+ · अग्रिम · अच्छा पठन)', 'VI': 'Chinh phục bài khó nhất (≥90 · học trước · đọc hiểu tốt)', 'ES': 'Retar lo más difícil (90+ · adelanto · buena lectura)', 'TH': 'ท้าทายโจทย์ยากสุด (90+ · ล่วงหน้า · อ่านดี)'},
  'autoFrom': {'KO': '최근 {subject} 점수 평균 {avg}점 ({n}회)으로 판정했어요', 'EN': 'Based on the recent {subject} average of {avg} ({n} records)', 'JA': '最近の{subject}平均{avg}点（{n}回）で判定しました', 'ZH': '根据最近{subject}平均{avg}分（{n}次）判定', 'FR': 'D\'après la moyenne récente en {subject} : {avg} ({n})', 'DE': 'Nach dem aktuellen {subject}-Schnitt {avg} ({n})', 'RU': 'По среднему баллу {subject}: {avg} ({n})', 'AR': 'بناءً على متوسط {subject} الأخير {avg} ({n})', 'HI': 'हाल के {subject} औसत {avg} ({n}) के आधार पर', 'VI': 'Dựa trên điểm TB {subject} gần đây {avg} ({n} lần)', 'ES': 'Según la media reciente de {subject}: {avg} ({n})', 'TH': 'จากคะแนนเฉลี่ย {subject} ล่าสุด {avg} ({n} ครั้ง)'},
  'needDiag': {'KO': '선행 · 문해력까지 보려면 [진단하기]를 눌러 주세요. 심화 단계는 진단 후에 열려요.', 'EN': 'Tap [Diagnose] to check studying ahead and reading. Advanced opens after diagnosis.', 'JA': '先取り・読解力も見るには[診断する]を。発展段階は診断後に開きます。', 'ZH': '点击[诊断]查看预习和阅读力，拔高阶段需诊断后开放。', 'FR': 'Touche [Diagnostiquer] pour l\'avance et la lecture. L\'avancé s\'ouvre après.', 'DE': 'Tippe [Diagnose starten] für Vorlernen und Lesen. Fortgeschritten erst danach.', 'RU': 'Нажмите [Диагностика], чтобы учесть опережение и чтение. Продвинутый — после неё.', 'AR': 'اضغط [تشخيص] لمعرفة التعلم المسبق والقراءة. المتقدم بعد التشخيص.', 'HI': 'अग्रिम पढ़ाई और पठन जाँचने के लिए [निदान करें] दबाएँ। उन्नत स्तर निदान के बाद।', 'VI': 'Nhấn [Chẩn đoán] để xét học trước và đọc hiểu. Nâng cao mở sau chẩn đoán.', 'ES': 'Toca [Diagnosticar] para ver adelanto y lectura. Avanzado se abre después.', 'TH': 'แตะ [วินิจฉัย] เพื่อดูการเรียนล่วงหน้าและการอ่าน ขั้นสูงเปิดหลังวินิจฉัย'},
  'noRecord': {'KO': '{subject} 성적 기록이 없어요. [진단하기]로 판정해 보세요.', 'EN': 'No {subject} scores yet. Tap [Diagnose] to find the level.', 'JA': '{subject}の成績記録がありません。[診断する]で判定しましょう。', 'ZH': '暂无{subject}成绩记录，请点击[诊断]判定。', 'FR': 'Pas de notes en {subject}. Touche [Diagnostiquer].', 'DE': 'Noch keine {subject}-Noten. Tippe [Diagnose starten].', 'RU': 'Оценок по {subject} нет. Нажмите [Диагностика].', 'AR': 'لا توجد درجات في {subject}. اضغط [تشخيص].', 'HI': '{subject} के अंक नहीं हैं। [निदान करें] दबाएँ।', 'VI': 'Chưa có điểm {subject}. Nhấn [Chẩn đoán].', 'ES': 'Sin notas de {subject}. Toca [Diagnosticar].', 'TH': 'ยังไม่มีคะแนน {subject} แตะ [วินิจฉัย]'},
  'diagnose': {'KO': '진단하기', 'EN': 'Diagnose', 'JA': '診断する', 'ZH': '诊断', 'FR': 'Diagnostiquer', 'DE': 'Diagnose starten', 'RU': 'Диагностика', 'AR': 'تشخيص', 'HI': 'निदान करें', 'VI': 'Chẩn đoán', 'ES': 'Diagnosticar', 'TH': 'วินิจฉัย'},
  'diagAgain': {'KO': '다시 진단하기', 'EN': 'Diagnose again', 'JA': 'もう一度診断', 'ZH': '重新诊断', 'FR': 'Refaire le diagnostic', 'DE': 'Erneut diagnostizieren', 'RU': 'Пройти снова', 'AR': 'إعادة التشخيص', 'HI': 'फिर से निदान', 'VI': 'Chẩn đoán lại', 'ES': 'Repetir diagnóstico', 'TH': 'วินิจฉัยอีกครั้ง'},
  'diagTitle': {'KO': '실력 진단', 'EN': 'Skill Diagnosis', 'JA': '実力診断', 'ZH': '实力诊断', 'FR': 'Diagnostic de niveau', 'DE': 'Leistungsdiagnose', 'RU': 'Диагностика уровня', 'AR': 'تشخيص المستوى', 'HI': 'स्तर निदान', 'VI': 'Chẩn đoán trình độ', 'ES': 'Diagnóstico de nivel', 'TH': 'วินิจฉัยระดับ'},
  'diagTip': {'KO': '학교 · 학원 진단평가 점수를 넣으면 가장 정확해요', 'EN': 'Most accurate with a school or academy diagnostic test score', 'JA': '学校・塾の診断テストの点数を入れると最も正確です', 'ZH': '填入学校或补习班的诊断测试分数最准确', 'FR': 'Plus précis avec une note de test diagnostique', 'DE': 'Am genauesten mit einem Einstufungstest-Ergebnis', 'RU': 'Точнее всего — с баллом диагностического теста', 'AR': 'الأدق مع درجة اختبار تشخيصي', 'HI': 'नैदानिक परीक्षा अंक डालने पर सबसे सटीक', 'VI': 'Chính xác nhất khi nhập điểm kiểm tra chẩn đoán', 'ES': 'Más preciso con la nota de un test diagnóstico', 'TH': 'แม่นยำที่สุดเมื่อใส่คะแนนสอบวินิจฉัย'},
  'diagScore': {'KO': '진단평가 점수 (100점 만점)', 'EN': 'Diagnostic test score (out of 100)', 'JA': '診断テストの点数（100点満点）', 'ZH': '诊断测试分数（满分100）', 'FR': 'Note du test diagnostique (/100)', 'DE': 'Punktzahl Einstufungstest (von 100)', 'RU': 'Балл диагностического теста (из 100)', 'AR': 'درجة الاختبار التشخيصي (من 100)', 'HI': 'नैदानिक परीक्षा अंक (100 में से)', 'VI': 'Điểm kiểm tra chẩn đoán (thang 100)', 'ES': 'Nota del test diagnóstico (sobre 100)', 'TH': 'คะแนนสอบวินิจฉัย (เต็ม 100)'},
  'diagScoreHint': {'KO': '모르면 비워 두세요 (답변으로 추정해요)', 'EN': 'Leave blank if unknown (estimated from answers)', 'JA': 'わからなければ空欄で（回答から推定）', 'ZH': '不知道可留空（根据回答估算）', 'FR': 'Laisse vide si inconnu (estimé)', 'DE': 'Leer lassen, falls unbekannt (geschätzt)', 'RU': 'Оставьте пустым — оценим по ответам', 'AR': 'اتركه فارغًا إن لم تعرف (يُقدَّر)', 'HI': 'पता न हो तो खाली छोड़ें (अनुमान लगेगा)', 'VI': 'Bỏ trống nếu không biết (sẽ ước tính)', 'ES': 'Déjalo vacío si no lo sabes (se estima)', 'TH': 'ถ้าไม่ทราบเว้นว่างไว้ (จะประเมินให้)'},
  'commonQ': {'KO': '전교과 공통 질문', 'EN': 'Common questions', 'JA': '共通質問', 'ZH': '通用问题', 'FR': 'Questions communes', 'DE': 'Allgemeine Fragen', 'RU': 'Общие вопросы', 'AR': 'أسئلة عامة', 'HI': 'सामान्य प्रश्न', 'VI': 'Câu hỏi chung', 'ES': 'Preguntas comunes', 'TH': 'คำถามทั่วไป'},
  'subjectQ': {'KO': '교과 질문 - {subject}', 'EN': '{subject} questions', 'JA': '{subject}の質問', 'ZH': '{subject}问题', 'FR': 'Questions de {subject}', 'DE': 'Fragen zu {subject}', 'RU': 'Вопросы: {subject}', 'AR': 'أسئلة {subject}', 'HI': '{subject} प्रश्न', 'VI': 'Câu hỏi {subject}', 'ES': 'Preguntas de {subject}', 'TH': 'คำถาม{subject}'},
  'answerAll': {'KO': '모든 질문에 답해 주세요.', 'EN': 'Please answer every question.', 'JA': 'すべての質問に答えてください。', 'ZH': '请回答所有问题。', 'FR': 'Réponds à toutes les questions.', 'DE': 'Bitte alle Fragen beantworten.', 'RU': 'Ответьте на все вопросы.', 'AR': 'يرجى الإجابة عن جميع الأسئلة.', 'HI': 'कृपया सभी प्रश्नों का उत्तर दें।', 'VI': 'Vui lòng trả lời tất cả câu hỏi.', 'ES': 'Responde todas las preguntas.', 'TH': 'กรุณาตอบทุกข้อ'},
  'byDiag': {'KO': '진단 결과 · 점수 {score}{est} · 선행 {pre} · 문해력 {lit}', 'EN': 'Diagnosis · score {score}{est} · studied ahead {pre} · reading {lit}', 'JA': '診断結果・点数{score}{est}・先取り{pre}・読解力{lit}', 'ZH': '诊断结果 · 分数{score}{est} · 预习{pre} · 阅读力{lit}', 'FR': 'Diagnostic · note {score}{est} · avance {pre} · lecture {lit}', 'DE': 'Diagnose · Punkte {score}{est} · Vorlernen {pre} · Lesen {lit}', 'RU': 'Диагностика · балл {score}{est} · опережение {pre} · чтение {lit}', 'AR': 'التشخيص · الدرجة {score}{est} · تعلم مسبق {pre} · القراءة {lit}', 'HI': 'निदान · अंक {score}{est} · अग्रिम पढ़ाई {pre} · पठन {lit}', 'VI': 'Chẩn đoán · điểm {score}{est} · học trước {pre} · đọc hiểu {lit}', 'ES': 'Diagnóstico · nota {score}{est} · adelanto {pre} · lectura {lit}', 'TH': 'ผลวินิจฉัย · คะแนน {score}{est} · เรียนล่วงหน้า {pre} · การอ่าน {lit}'},
  'est': {'KO': '(추정)', 'EN': ' (est.)', 'JA': '（推定）', 'ZH': '（估算）', 'FR': ' (est.)', 'DE': ' (geschätzt)', 'RU': ' (оценка)', 'AR': ' (تقديري)', 'HI': ' (अनुमान)', 'VI': ' (ước tính)', 'ES': ' (estim.)', 'TH': ' (ประมาณ)'},
  'preYes': {'KO': '됨', 'EN': 'yes', 'JA': 'あり', 'ZH': '有', 'FR': 'oui', 'DE': 'ja', 'RU': 'да', 'AR': 'نعم', 'HI': 'हाँ', 'VI': 'có', 'ES': 'sí', 'TH': 'มี'},
  'preNo': {'KO': '안 됨', 'EN': 'no', 'JA': 'なし', 'ZH': '无', 'FR': 'non', 'DE': 'nein', 'RU': 'нет', 'AR': 'لا', 'HI': 'नहीं', 'VI': 'chưa', 'ES': 'no', 'TH': 'ไม่มี'},
  'litGood': {'KO': '좋음', 'EN': 'strong', 'JA': '良い', 'ZH': '好', 'FR': 'bonne', 'DE': 'gut', 'RU': 'хорошее', 'AR': 'جيدة', 'HI': 'अच्छा', 'VI': 'tốt', 'ES': 'buena', 'TH': 'ดี'},
  'litWeak': {'KO': '보강 필요', 'EN': 'needs work', 'JA': '要強化', 'ZH': '需加强', 'FR': 'à renforcer', 'DE': 'ausbaufähig', 'RU': 'подтянуть', 'AR': 'تحتاج تقوية', 'HI': 'सुधार चाहिए', 'VI': 'cần cải thiện', 'ES': 'a reforzar', 'TH': 'ต้องเสริม'},
  'tapLevel': {'KO': '단계를 눌러 직접 바꿀 수도 있어요', 'EN': 'Tap a level to change it yourself', 'JA': '段階をタップして変更できます', 'ZH': '也可点击阶段自行更改', 'FR': 'Touche un niveau pour le changer', 'DE': 'Tippe auf eine Stufe, um sie zu ändern', 'RU': 'Нажмите на уровень, чтобы изменить', 'AR': 'اضغط على المستوى لتغييره', 'HI': 'स्तर बदलने के लिए टैप करें', 'VI': 'Chạm để tự đổi trình độ', 'ES': 'Toca un nivel para cambiarlo', 'TH': 'แตะเพื่อเปลี่ยนระดับเองได้'},
  'byHand': {'KO': '직접 고른 단계예요', 'EN': 'Level chosen by you', 'JA': '手動で選んだ段階です', 'ZH': '手动选择的阶段', 'FR': 'Niveau choisi par toi', 'DE': 'Selbst gewählte Stufe', 'RU': 'Уровень выбран вручную', 'AR': 'مستوى اخترته بنفسك', 'HI': 'आपके द्वारा चुना स्तर', 'VI': 'Trình độ do bạn chọn', 'ES': 'Nivel elegido por ti', 'TH': 'ระดับที่เลือกเอง'},
  'orderList': {'KO': '추천 교재 · 푸는 순서', 'EN': 'Recommended Books · Study Order', 'JA': 'おすすめ教材・解く順番', 'ZH': '推荐教材 · 学习顺序', 'FR': 'Livres conseillés · ordre', 'DE': 'Empfohlene Bücher · Reihenfolge', 'RU': 'Рекомендуемые книги · порядок', 'AR': 'الكتب المقترحة · الترتيب', 'HI': 'सुझाई पुस्तकें · क्रम', 'VI': 'Sách gợi ý · thứ tự học', 'ES': 'Libros recomendados · orden', 'TH': 'หนังสือแนะนำ · ลำดับการทำ'},
  'stConcept': {'KO': '개념서', 'EN': 'Concept Book', 'JA': '概念書', 'ZH': '概念书', 'FR': 'Manuel de notions', 'DE': 'Grundlagenbuch', 'RU': 'Теория', 'AR': 'كتاب المفاهيم', 'HI': 'अवधारणा पुस्तक', 'VI': 'Sách khái niệm', 'ES': 'Libro de conceptos', 'TH': 'หนังสือแนวคิด'},
  'stPattern': {'KO': '기본 유형서', 'EN': 'Core Practice', 'JA': '基本問題集', 'ZH': '基础题型书', 'FR': 'Exercices de base', 'DE': 'Grundübungen', 'RU': 'Базовые задачи', 'AR': 'تمارين أساسية', 'HI': 'मूल अभ्यास', 'VI': 'Sách bài tập cơ bản', 'ES': 'Práctica básica', 'TH': 'แบบฝึกพื้นฐาน'},
  'stSkill': {'KO': '실력서', 'EN': 'Skill Builder', 'JA': '実力問題集', 'ZH': '提高练习册', 'FR': 'Niveau intermédiaire', 'DE': 'Aufbauübungen', 'RU': 'Задачи среднего уровня', 'AR': 'تمارين المهارة', 'HI': 'कौशल पुस्तक', 'VI': 'Sách nâng kỹ năng', 'ES': 'Libro de refuerzo', 'TH': 'หนังสือเพิ่มทักษะ'},
  'stAdvanced': {'KO': '심화서', 'EN': 'Advanced Book', 'JA': '発展書', 'ZH': '拔高书', 'FR': 'Niveau avancé', 'DE': 'Vertiefung', 'RU': 'Углублённый', 'AR': 'كتاب متقدم', 'HI': 'उन्नत पुस्तक', 'VI': 'Sách nâng cao', 'ES': 'Libro avanzado', 'TH': 'หนังสือขั้นสูง'},
  'stExam': {'KO': '기출 · 내신', 'EN': 'Past Exams', 'JA': '過去問・定期試験', 'ZH': '真题·校考', 'FR': 'Annales', 'DE': 'Prüfungsaufgaben', 'RU': 'Экзаменационные', 'AR': 'اختبارات سابقة', 'HI': 'पिछले प्रश्नपत्र', 'VI': 'Đề thi', 'ES': 'Exámenes anteriores', 'TH': 'ข้อสอบเก่า'},
  'stFinal': {'KO': '수능 파이널', 'EN': 'CSAT Final', 'JA': '修能ファイナル', 'ZH': '高考冲刺', 'FR': 'Finale du CSAT', 'DE': 'CSAT-Endspurt', 'RU': 'Финал CSAT', 'AR': 'المراجعة النهائية', 'HI': 'CSAT फ़ाइनल', 'VI': 'Nước rút CSAT', 'ES': 'Final del CSAT', 'TH': 'CSAT ช่วงสุดท้าย'},
  'noBooks': {'KO': '이 단계에 등록된 교재가 아직 없어요', 'EN': 'No textbooks registered for this level yet', 'JA': 'この段階の教材はまだありません', 'ZH': '此阶段暂无教材', 'FR': 'Aucun manuel pour ce niveau', 'DE': 'Noch keine Bücher für diese Stufe', 'RU': 'Учебников для этого уровня пока нет', 'AR': 'لا توجد كتب لهذا المستوى بعد', 'HI': 'इस स्तर के लिए अभी कोई पुस्तक नहीं', 'VI': 'Chưa có sách cho mức này', 'ES': 'Aún no hay libros para este nivel', 'TH': 'ยังไม่มีหนังสือในระดับนี้'},
  'why': {'KO': '왜 이 교재인가요', 'EN': 'Why this book', 'JA': 'この教材を選ぶ理由', 'ZH': '为何推荐', 'FR': 'Pourquoi ce livre', 'DE': 'Warum dieses Buch', 'RU': 'Почему эта книга', 'AR': 'لماذا هذا الكتاب', 'HI': 'यह पुस्तक क्यों', 'VI': 'Vì sao chọn sách này', 'ES': 'Por qué este libro', 'TH': 'ทำไมเล่มนี้'},
  'howTo': {'KO': '이렇게 공부하세요', 'EN': 'How to study', 'JA': '使い方', 'ZH': '学习方法', 'FR': 'Comment l\'utiliser', 'DE': 'So lernst du damit', 'RU': 'Как заниматься', 'AR': 'طريقة الدراسة', 'HI': 'कैसे पढ़ें', 'VI': 'Cách học', 'ES': 'Cómo estudiar', 'TH': 'วิธีเรียน'},
  'altBooks': {'KO': '이런 교재도 좋아요 (다른 선택지)', 'EN': 'Other good choices', 'JA': 'こちらもおすすめ（他の選択肢）', 'ZH': '其他可选教材', 'FR': 'Autres bons choix', 'DE': 'Weitere gute Optionen', 'RU': 'Другие хорошие варианты', 'AR': 'خيارات جيدة أخرى', 'HI': 'अन्य अच्छे विकल्प', 'VI': 'Lựa chọn khác', 'ES': 'Otras buenas opciones', 'TH': 'ตัวเลือกอื่นที่ดี'},
  'daily': {'KO': '하루 분량', 'EN': 'Daily amount', 'JA': '1日の量', 'ZH': '每日量', 'FR': 'Par jour', 'DE': 'Pro Tag', 'RU': 'В день', 'AR': 'الكمية اليومية', 'HI': 'प्रतिदिन', 'VI': 'Mỗi ngày', 'ES': 'Por día', 'TH': 'ต่อวัน'},
  'period': {'KO': '예상 기간', 'EN': 'Expected period', 'JA': '目安期間', 'ZH': '预计时间', 'FR': 'Durée prévue', 'DE': 'Dauer', 'RU': 'Срок', 'AR': 'المدة المتوقعة', 'HI': 'अनुमानित अवधि', 'VI': 'Thời gian', 'ES': 'Duración', 'TH': 'ระยะเวลา'},
  'weeksN': {'KO': '약 {n}주', 'EN': 'About {n} weeks', 'JA': '約{n}週', 'ZH': '约{n}周', 'FR': 'Environ {n} semaines', 'DE': 'Etwa {n} Wochen', 'RU': 'Около {n} недель', 'AR': 'حوالي {n} أسابيع', 'HI': 'लगभग {n} सप्ताह', 'VI': 'Khoảng {n} tuần', 'ES': 'Unas {n} semanas', 'TH': 'ประมาณ {n} สัปดาห์'},
  'sendChild': {'KO': '자녀에게 추천 보내기', 'EN': 'Send to my child', 'JA': '子どもに送る', 'ZH': '推荐给孩子', 'FR': 'Envoyer à mon enfant', 'DE': 'An mein Kind senden', 'RU': 'Отправить ребёнку', 'AR': 'أرسل لطفلي', 'HI': 'बच्चे को भेजें', 'VI': 'Gửi cho con', 'ES': 'Enviar a mi hijo/a', 'TH': 'ส่งให้บุตร'},
  'sent': {'KO': '자녀 타이머 화면에 추천을 보냈어요', 'EN': 'Sent to your child\'s timer screen', 'JA': '子どものタイマー画面に送りました', 'ZH': '已发送到孩子的计时器界面', 'FR': 'Envoyé sur l\'écran minuteur de ton enfant', 'DE': 'An den Timer deines Kindes gesendet', 'RU': 'Отправлено на экран таймера ребёнка', 'AR': 'أُرسل إلى شاشة مؤقت طفلك', 'HI': 'बच्चे की टाइमर स्क्रीन पर भेजा गया', 'VI': 'Đã gửi tới màn hình hẹn giờ của con', 'ES': 'Enviado a la pantalla del temporizador', 'TH': 'ส่งไปยังหน้าจอจับเวลาของบุตรแล้ว'},
  'childMsg': {'KO': '📚 엄마 아빠 추천 교재: {title} ({pub}) · 하루 {daily}', 'EN': '📚 Recommended book: {title} ({pub}) · {daily} a day', 'JA': '📚 おすすめ教材：{title}（{pub}）・1日{daily}', 'ZH': '📚 推荐教材：{title}（{pub}）· 每天{daily}', 'FR': '📚 Livre conseillé : {title} ({pub}) · {daily}/jour', 'DE': '📚 Buchtipp: {title} ({pub}) · {daily} pro Tag', 'RU': '📚 Советуем: {title} ({pub}) · {daily} в день', 'AR': '📚 كتاب مقترح: {title} ({pub}) · {daily} يوميًا', 'HI': '📚 सुझाई गई पुस्तक: {title} ({pub}) · रोज़ {daily}', 'VI': '📚 Sách gợi ý: {title} ({pub}) · mỗi ngày {daily}', 'ES': '📚 Libro recomendado: {title} ({pub}) · {daily} al día', 'TH': '📚 หนังสือแนะนำ: {title} ({pub}) · วันละ {daily}'},
  'close': {'KO': '닫기', 'EN': 'Close', 'JA': '閉じる', 'ZH': '关闭', 'FR': 'Fermer', 'DE': 'Schließen', 'RU': 'Закрыть', 'AR': 'إغلاق', 'HI': 'बंद करें', 'VI': 'Đóng', 'ES': 'Cerrar', 'TH': 'ปิด'},
  'failed': {'KO': '잠시 후 다시 시도해 주세요.', 'EN': 'Please try again later.', 'JA': 'しばらくしてから再度お試しください。', 'ZH': '请稍后重试。', 'FR': 'Réessaie plus tard.', 'DE': 'Bitte später erneut versuchen.', 'RU': 'Попробуйте позже.', 'AR': 'حاول لاحقًا.', 'HI': 'कृपया बाद में पुनः प्रयास करें।', 'VI': 'Vui lòng thử lại sau.', 'ES': 'Inténtalo más tarde.', 'TH': 'กรุณาลองใหม่ภายหลัง'},
  'disclaimer': {'KO': '정확한 교재 추천은 진단평가 후 분석이 기본이에요. 고민되시면 교육상담의 1:1 상담으로 편하게 물어봐 주세요.', 'EN': 'The best recommendation comes after a diagnostic test. Feel free to ask through 1:1 counseling.', 'JA': '正確な推薦は診断テストの分析が基本です。迷ったら1:1相談へ。', 'ZH': '准确推荐以诊断测试分析为基础，如有疑问请使用1:1咨询。', 'FR': 'La meilleure recommandation suit un test diagnostique. Pose tes questions en conseil 1:1.', 'DE': 'Die beste Empfehlung folgt einem Einstufungstest. Frag gern in der 1:1-Beratung.', 'RU': 'Точная рекомендация — после диагностического теста. Спросите в личной консультации.', 'AR': 'التوصية الأدق تأتي بعد اختبار تشخيصي. اسأل عبر الاستشارة الفردية.', 'HI': 'सटीक सुझाव नैदानिक परीक्षा के बाद। 1:1 परामर्श में पूछें।', 'VI': 'Gợi ý chính xác nhất là sau bài kiểm tra chẩn đoán. Hãy hỏi qua tư vấn 1:1.', 'ES': 'La mejor recomendación llega tras un test diagnóstico. Pregunta en la asesoría 1:1.', 'TH': 'คำแนะนำที่แม่นยำมาจากการสอบวินิจฉัย สอบถามได้ที่ปรึกษา 1:1'},
  'foreignNote': {'KO': '', 'EN': 'Titles are Korean textbooks; the study order works for any book.', 'JA': '教材名は韓国の教材です。学習順序はどの教材にも使えます。', 'ZH': '书名为韩国教材；学习顺序适用于任何教材。', 'FR': 'Les titres sont coréens ; l\'ordre vaut pour tout livre.', 'DE': 'Titel sind koreanische Bücher; die Reihenfolge gilt für jedes Buch.', 'RU': 'Названия — корейские учебники; порядок подходит для любых книг.', 'AR': 'العناوين كتب كورية؛ ترتيب الدراسة يصلح لأي كتاب.', 'HI': 'शीर्षक कोरियाई पुस्तकें हैं; क्रम किसी भी पुस्तक पर लागू होता है।', 'VI': 'Tên sách là sách Hàn Quốc; thứ tự học áp dụng cho mọi sách.', 'ES': 'Los títulos son coreanos; el orden sirve para cualquier libro.', 'TH': 'ชื่อหนังสือเป็นของเกาหลี แต่ลำดับใช้ได้กับทุกเล่ม'},
  'ansYes': {'KO': '그렇다', 'EN': 'Yes', 'JA': 'はい', 'ZH': '是', 'FR': 'Oui', 'DE': 'Ja', 'RU': 'Да', 'AR': 'نعم', 'HI': 'हाँ', 'VI': 'Có', 'ES': 'Sí', 'TH': 'ใช่'},
  'ansMid': {'KO': '보통', 'EN': 'Sometimes', 'JA': '時々', 'ZH': '一般', 'FR': 'Parfois', 'DE': 'Manchmal', 'RU': 'Иногда', 'AR': 'أحيانًا', 'HI': 'कभी-कभी', 'VI': 'Thỉnh thoảng', 'ES': 'A veces', 'TH': 'บางครั้ง'},
  'ansNo': {'KO': '아니다', 'EN': 'No', 'JA': 'いいえ', 'ZH': '否', 'FR': 'Non', 'DE': 'Nein', 'RU': 'Нет', 'AR': 'لا', 'HI': 'नहीं', 'VI': 'Không', 'ES': 'No', 'TH': 'ไม่'},
  'checkDone': {'KO': '판정하기', 'EN': 'See result', 'JA': '判定する', 'ZH': '查看结果', 'FR': 'Voir le résultat', 'DE': 'Ergebnis', 'RU': 'Результат', 'AR': 'عرض النتيجة', 'HI': 'परिणाम देखें', 'VI': 'Xem kết quả', 'ES': 'Ver resultado', 'TH': 'ดูผล'},
  // ---- 관리자 (KO · EN)
  'admin': {'KO': '교재 관리', 'EN': 'Manage Textbooks'},
  'adminBar': {'KO': '교재 관리 (원장님 전용) — 교재 넣기 · 고치기 · 순서 정하기', 'EN': 'Manage Textbooks (admin only)'},
  'addBook': {'KO': '교재 추가', 'EN': 'Add Textbook'},
  'editBook': {'KO': '교재 수정', 'EN': 'Edit Textbook'},
  'seedAll': {'KO': '기본 교재 목록 넣기 (초 · 중 · 고 전 과목 · 없는 교재만 추가)', 'EN': 'Add the basic list (all subjects)'},
  'all': {'KO': '전체', 'EN': 'All'},
  'fDiv': {'KO': '학부', 'EN': 'School level'},
  'seedDone': {'KO': '교재 {n}권을 넣었어요. 하나씩 확인해 고쳐 주세요.', 'EN': '{n} books added. Please review each.'},
  'seedNone': {'KO': '이미 모두 들어 있어요.', 'EN': 'Already added.'},
  'resetAll': {'KO': '전체 지우고 기본 목록 새로 넣기', 'EN': 'Delete all & reload the basic list'},
  'resetAsk1': {'KO': '서버에 있는 교재를 모두 지우고, 기본 목록(원장님 교재 DB 포함)을 새로 넣습니다. 직접 고치거나 추가한 교재도 모두 지워져요. 계속할까요?', 'EN': 'All textbooks will be deleted and the basic list reloaded. Continue?'},
  'resetAsk2': {'KO': '정말 지울까요? 되돌릴 수 없어요.', 'EN': 'Really delete? This cannot be undone.'},
  'resetDone': {'KO': '모두 지우고 교재 {n}권을 새로 넣었어요.', 'EN': 'Reset done: {n} books added.'},
  'yes': {'KO': '네, 진행', 'EN': 'Yes'},
  'ruleErr': {'KO': '서버가 저장을 막았어요. Firestore 규칙에 textbooks 칸을 넣고 [게시]했는지, 원장님 계정으로 로그인했는지 확인해 주세요.', 'EN': 'Blocked by server rules. Check the textbooks rule is published.'},
  'fTitle': {'KO': '교재 이름', 'EN': 'Title'},
  'fPub': {'KO': '출판사', 'EN': 'Publisher'},
  'fWhy': {'KO': '왜 이 교재인가요 (특징 + 추천 이유)', 'EN': 'Why this book'},
  'fHow': {'KO': '이렇게 공부하세요 (어떤 학생에게 + 공부법)', 'EN': 'How to study'},
  'fDaily': {'KO': '하루 분량 (예: 4쪽)', 'EN': 'Daily amount'},
  'fWeeks': {'KO': '예상 기간 (주)', 'EN': 'Weeks'},
  'fOrder': {'KO': '푸는 순서 (1~9 = 순서대로 풀 교재 · 10 이상 = 다른 선택지)', 'EN': 'Order (1–9 main, 10+ alternatives)'},
  'fType': {'KO': '종류', 'EN': 'Type'},
  'fLevels': {'KO': '맞는 단계 (여러 개)', 'EN': 'Levels'},
  'fGrades': {'KO': '맞는 학년 (여러 개)', 'EN': 'Grades'},
  'fActive': {'KO': '보이기', 'EN': 'Visible'},
  'save': {'KO': '저장', 'EN': 'Save'},
  'delete': {'KO': '삭제', 'EN': 'Delete'},
  'deleteAsk': {'KO': '이 교재를 삭제할까요?', 'EN': 'Delete this book?'},
  'hidden': {'KO': '숨김', 'EN': 'Hidden'},
  'needTitle': {'KO': '교재 이름 · 학년 · 단계를 넣어 주세요.', 'EN': 'Fill in title, grades and levels.'},
  'emptyAdmin': {'KO': '여기에 등록된 교재가 없어요. 위 버튼으로 기본 목록을 넣거나, 아래 [교재 추가]로 직접 넣으세요.', 'EN': 'No textbooks yet.'},
  'ruleTitle': {'KO': '판정 기준', 'EN': 'Level rules'},
  'rule1': {'KO': '🌱 개념 : 60점 미만', 'EN': 'Concept: < 60'},
  'rule2': {'KO': '🌿 기본 : 60~79점, 또는 80~89점이지만 선행 안 됨', 'EN': 'Basic: 60–79, or 80–89 without studying ahead'},
  'rule3': {'KO': '🌳 실력 : 80~89점 + 선행 됨 / 90점 이상이지만 선행 · 문해력 중 하나 부족', 'EN': 'Intermediate: 80–89 + ahead, or 90+ missing one'},
  'rule4': {'KO': '🌲 심화 : 90점 이상 + 선행 됨 + 문해력 좋음', 'EN': 'Advanced: 90+ · ahead · strong reading'},
};

bool get _foreign => DkeLang.isForeignSelected;
String _lang() => _foreign ? DkeLang.current : 'KO';

String _s(String k, [Map<String, Object>? args]) {
  final Map<String, String>? m = _tx[k];
  String v = m == null ? k : (m[_lang()] ?? m['EN'] ?? m['KO'] ?? k);
  args?.forEach((a, b) => v = v.replaceAll('{$a}', '$b'));
  return v;
}

String _e(String k) => _tx[k]?['EN'] ?? k;
String _k(String k, [Map<String, Object>? args]) {
  String v = _tx[k]?['KO'] ?? k;
  args?.forEach((a, b) => v = v.replaceAll('{$a}', '$b'));
  return v;
}

TextStyle _enStyle(double size, {Color color = _kGold}) =>
    GoogleFonts.gowunBatang(color: color, fontSize: size, fontWeight: FontWeight.bold);
TextStyle _koStyle(double size, {Color color = _kGold, FontWeight w = FontWeight.bold}) =>
    GoogleFonts.notoSansKr(color: color, fontSize: size, fontWeight: w);

/// 두 줄: 영문(진한 명조) 위 + 한글(노토산스) 아래 / 외국어는 한 줄
Widget _bi2(String k, {double size = 15, Color color = _kGold, CrossAxisAlignment align = CrossAxisAlignment.start}) {
  if (_foreign) return Text(_s(k), style: _koStyle(size, color: color));
  return Column(
    crossAxisAlignment: align,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(_e(k), style: _enStyle(size - 2, color: color.withValues(alpha: 0.75))),
      Text(_s(k), style: _koStyle(size, color: color)),
    ],
  );
}

/// 한 줄: 영문(명조) + 한글(노토산스) / 외국어는 그 나라 말
Widget _bi1(String k, {double size = 13, Color color = _kWhite, int maxLines = 1, TextAlign ta = TextAlign.start}) {
  if (_foreign) {
    return Text(_s(k), textAlign: ta, maxLines: maxLines, overflow: TextOverflow.ellipsis, style: _koStyle(size, color: color, w: FontWeight.w600));
  }
  return Text.rich(
    TextSpan(children: [
      TextSpan(text: '${_e(k)}  ', style: _enStyle(size - 1, color: color.withValues(alpha: 0.75))),
      TextSpan(text: _s(k), style: _koStyle(size, color: color, w: FontWeight.w600)),
    ]),
    textAlign: ta,
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
  );
}

BoxDecoration _luxBox({bool bright = false, double radius = 16}) => BoxDecoration(
  gradient: _kCardGrad,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: _kGold.withValues(alpha: bright ? 0.9 : 0.3), width: bright ? 1.5 : 1),
  boxShadow: bright ? [BoxShadow(color: _kGold.withValues(alpha: 0.2), blurRadius: 14)] : null,
);

Widget _chip(String label, bool sel, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: sel ? _kGoldGrad : null,
        color: sel ? null : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGold.withValues(alpha: sel ? 1 : 0.35)),
      ),
      child: Text(label, style: _koStyle(12.5, color: sel ? Colors.black : Colors.white70, w: sel ? FontWeight.bold : FontWeight.w500)),
    ),
  );
}

void _snack(BuildContext context, String text, {Color bg = const Color(0xFF0D1527)}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(backgroundColor: bg, content: Text(text, style: _koStyle(13, color: bg == const Color(0xFF0D1527) ? _kGold : Colors.white))),
  );
}

// ============================================================================
// 기본 값들
// ============================================================================
// 학부 → 학년 · 과목 (원장님 지정)
const List<String> kTbDivs = ['elem', 'mid', 'high'];
const Map<String, String> _kDivKey = {'elem': 'divElem', 'mid': 'divMid', 'high': 'divHigh'};
const Map<String, List<String>> kTbDivGrades = {
  'elem': ['초1', '초2', '초3', '초4', '초5', '초6'],
  'mid': ['중1', '중2', '중3'],
  'high': ['고1', '고2', '고3'],
};
const Map<String, List<String>> kTbDivSubjects = {
  'elem': ['국어', '수학', '영어', '과학', '사회'],
  'mid': ['국어', '영어', '수학', '과학', '사회', '역사', '세계사', '기술/가정', '한문'],
  'high': ['국어', '영어', '수학', '제2외국어', '통합사회', '통합과학', '역사'],
};
const List<String> kTbGrades = ['초1', '초2', '초3', '초4', '초5', '초6', '중1', '중2', '중3', '고1', '고2', '고3'];
const List<String> kTbSubjects = ['국어', '영어', '수학', '과학', '사회', '역사', '세계사', '기술/가정', '한문', '제2외국어', '통합사회', '통합과학'];
const Map<String, String> _kGradeEn = {
  '초1': 'Gr.1', '초2': 'Gr.2', '초3': 'Gr.3', '초4': 'Gr.4', '초5': 'Gr.5', '초6': 'Gr.6',
  '중1': 'Gr.7', '중2': 'Gr.8', '중3': 'Gr.9', '고1': 'Gr.10', '고2': 'Gr.11', '고3': 'Gr.12',
};
const Map<String, String> _kSubjEn = {
  '국어': 'Korean', '영어': 'English', '수학': 'Math', '과학': 'Science', '사회': 'Social Studies', '역사': 'History',
  '세계사': 'World History', '기술/가정': 'Tech & Home Ec.', '한문': 'Classical Chinese', '제2외국어': '2nd Foreign Language',
  '통합사회': 'Integrated Social Studies', '통합과학': 'Integrated Science',
};
const Set<String> _kBasicSix = {'국어', '영어', '수학', '과학', '사회', '역사'};
String divOf(String grade) => grade.startsWith('초') ? 'elem' : (grade.startsWith('고') ? 'high' : 'mid');
const List<String> kTbLevels = ['concept', 'basic', 'skilled', 'advanced'];
const List<String> kTbTypes = ['concept', 'pattern', 'skill', 'advanced', 'final', 'exam'];
const Map<String, String> _kLevelKey = {'concept': 'lvConcept', 'basic': 'lvBasic', 'skilled': 'lvSkilled', 'advanced': 'lvAdvanced'};
const Map<String, String> _kLevelEmoji = {'concept': '🌱', 'basic': '🌿', 'skilled': '🌳', 'advanced': '🌲'};
const Map<String, String> _kLevelDescKey = {'concept': 'lvConceptDesc', 'basic': 'lvBasicDesc', 'skilled': 'lvSkilledDesc', 'advanced': 'lvAdvancedDesc'};
const Map<String, String> _kTypeKey = {'concept': 'stConcept', 'pattern': 'stPattern', 'skill': 'stSkill', 'advanced': 'stAdvanced', 'final': 'stFinal', 'exam': 'stExam'};
/// 푸는 순서 10 이상 = 다른 선택지 (번호 없이 따로 보여 줌)
const int kTbAltOrder = 10;

String _gradeLabel(String g) => _lang() == 'KO' ? g : (_kGradeEn[g] ?? g);

/// 중등부 1 · 고등부 2 처럼 긴 이름 (직사각형 버튼용)
String _gradeLong(String g) {
  if (_lang() != 'KO') return _kGradeEn[g] ?? g;
  if (g.startsWith('중')) return '중등부 ${g.substring(1)}';
  if (g.startsWith('고')) return '고등부 ${g.substring(1)}';
  return g;
}
String _subjectLabel(String ko) {
  if (_lang() == 'KO') return ko;
  if (_kBasicSix.contains(ko)) {
    final SubjectCategory? c = subjectCategoryByKo(ko);
    if (c != null) return subjectCategoryLabel(c, _lang());
  }
  return _kSubjEn[ko] ?? ko;
}

/// 원장님 판정 기준 (4단계 · 2026-10-13)
/// 🌱 개념 : 60점 미만
/// 🌿 기본 : 60~79점, 또는 80~89점이지만 선행 안 됨
/// 🌳 실력 : 80~89점 + 선행 됨 / 90점 이상이지만 선행 · 문해력 중 하나 부족
/// 🌲 심화 : 90점 이상 + 선행 됨 + 문해력 좋음
String diagnoseLevel(int score, bool ahead, bool reading) {
  if (score < 60) return 'concept';
  if (score < 80) return 'basic';
  if (score < 90) return ahead ? 'skilled' : 'basic';
  return (ahead && reading) ? 'advanced' : 'skilled';
}

// ============================================================================
// 진단 질문 — 원장님 설계 (2026-10-13)
// · 화면에는 질문 + [그렇다 / 보통 / 아니다]만 보임
// · ind(지표) · intent(측정 의도)는 코드 참고용 + 진단 리포트에서만 사용 (질문 화면에 절대 표시하지 않음)
// · role: base = 기초 실력 / pre = 선행 / lit = 문해력 (단계 판정에 쓰임)
// · reverse: '그렇다'가 나쁜 답인 문항 (점수를 거꾸로 계산)
// ============================================================================
class _Q {
  final String tag; // role
  final String ko;
  final String en;
  final String ind; // 지표 (비어 있으면 role로 정함)
  final bool reverse;
  final String intent; // 측정 의도 (코드 참고용)
  final String rx; // 🆕 [영어 2026-10-14] '보완 필요'일 때 리포트 처방 문장 (한글)
  final String rxEn; // 같은 문장 (영어)
  final bool up; // 🆕 '그렇다'일 때 단계 상향에 쓰는 문항
  const _Q(this.tag, this.ko, this.en, {this.ind = '', this.reverse = false, this.intent = '', this.rx = '', this.rxEn = '', this.up = false});

  String get indicator => ind.isNotEmpty ? ind : (tag == 'lit' ? 'reading' : (tag == 'pre' ? 'ahead' : 'subjBase'));
}

/// 📋 전교과 공통 질문 (6문항) — 학습 태도 · 메타인지 · 자기주도성 · 학습 환경
const List<_Q> _kCommonQ = [
  _Q('base', '학교 수업 내용을 그날 바로 복습(정리)하나요?', 'Does your child review (organize) each day\'s lessons the same day?',
      ind: 'review', intent: '일일 학습 유지력 및 복습 습관'),
  _Q('base', '숙제나 과제를 미루지 않고 스스로 끝까지 해내나요?', 'Does your child finish homework on their own without putting it off?',
      ind: 'selfDirected', intent: '과제 집착력 및 자기주도성'),
  _Q('lit', '긴 지문이나 복잡한 문제를 읽고 무엇을 묻는지 핵심을 바로 파악하나요?', 'Does your child quickly grasp what a long or complex question is asking?',
      ind: 'reading', intent: '독해력 및 문제 이해 속도'),
  _Q('base', '학습한 내용을 다른 사람(또는 나 자신)에게 말로 설명할 수 있나요?', 'Can your child explain what they learned out loud to someone (or themselves)?',
      ind: 'metacog', intent: '메타인지 및 개념의 진정한 이해도'),
  _Q('base', '시험이나 과제에서 틀린 이유를 분석하고 오답을 확실히 내 것으로 만드나요?', 'Does your child analyze why they got something wrong and truly master it?',
      ind: 'errorMgmt', intent: '오답 관리 및 피드백 수용성'),
  _Q('base', '디지털 기기(스마트폰, 게임 등)나 주변 환경으로 인해 학습 흐름이 자주 끊기나요?', 'Is your child\'s study often interrupted by devices (phone, games) or surroundings?',
      ind: 'focus', reverse: true, intent: '학습 집중도 및 방해 요소 관리'),
];

const Map<String, List<_Q>> _kSubjectQ = {
  /// 📐 수학 (9문항) — 개념 이해 · 연산 · 심화 사고력 · 선행 상태
  '수학': [
    _Q('base', '교과서 예제와 기본 문제를 다른 사람의 도움 없이 혼자 힘으로 풀 수 있나요?', 'Can your child solve textbook examples and basic problems without help?',
        ind: 'mBasic', intent: '최소한의 기본 개념 도달 여부'),
    _Q('base', '사칙연산이나 단순 대입 등에서 계산 실수가 적은 편인가요?', 'Does your child make few mistakes in arithmetic and simple substitution?',
        ind: 'mCalc', intent: '연산 정확도 및 감점 요인 파악'),
    _Q('pre', '다음 학기(또는 다음 학년) 수학 개념서를 혼자서라도 한 번 이상 끝내 보았나요?', 'Has your child finished next term\'s (or year\'s) math concept book at least once, even alone?',
        ind: 'ahead', intent: '선행 학습 경험 및 진도 소화 상태'),
    _Q('base', '공식이나 개념을 단순히 암기하지 않고, \'왜 그렇게 되는지\' 유도 과정을 이해하나요?', 'Does your child understand why a formula works, not just memorize it?',
        ind: 'mPrinciple', intent: '암기식 수학 vs 원리 이해식 수학 구분'),
    _Q('lit', '서술형이나 문장제(말글로 된) 문제를 읽고 수학적 식이나 방정식으로 바꿀 수 있나요?', 'Can your child turn word problems into equations?',
        ind: 'mModeling', intent: '식 세우기 능력 및 응용력 기초'),
    _Q('base', '도형의 성질이나 그래프를 보고 머릿속으로 입체적 · 시각적으로 회전하거나 변형할 수 있나요?', 'Can your child picture shapes and graphs rotating or changing in their head?',
        ind: 'mVisual', intent: '기하 및 시각적 직관력'),
    _Q('base', '모르는 문제를 마주쳤을 때, 답지를 보기 전에 최소 20분 이상 깊이 고민하고 매달리나요?', 'Does your child think hard for 20+ minutes before looking at the answer key?',
        ind: 'grit', intent: '수학적 끈기 및 과제 집착력'),
    _Q('base', '유형서(예: RPM, 쎈 B 등)에 나오는 반복 유형 문제는 능숙하게 해결하나요?', 'Does your child handle standard problem types (e.g. RPM, Ssen B) with ease?',
        ind: 'mPattern', intent: '준유형 해결 능력'),
    _Q('base', '최고난도 문제(예: 쎈 C단계, 일품, 블랙라벨 등)를 보면 도전하고 싶은 의욕이 생기나요?', 'Does your child feel eager to try the hardest problems (e.g. Ssen C, Ilpum, Black Label)?',
        ind: 'challenge', intent: '심화 학습 수용도 및 도전 정신'),
  ],
  '영어': [
    _Q('base', '교과서 단어를 대부분 알고 있나요?', 'Does your child know most of the textbook vocabulary?'),
    _Q('base', '기본 문법(시제 · 문장 형식)을 설명할 수 있나요?', 'Can your child explain basic grammar (tenses, sentence forms)?'),
    _Q('lit', '긴 지문을 읽고 주제를 찾을 수 있나요?', 'Can your child find the main idea of a long passage?'),
    _Q('pre', '다음 학년 영어(문법 · 독해)를 미리 공부했나요?', 'Has your child studied next year\'s English in advance?'),
    _Q('base', '영어 문장을 스스로 써 볼 수 있나요?', 'Can your child write English sentences on their own?'),
  ],
  '국어': [
    _Q('lit', '문학 작품을 읽고 인물의 마음을 설명할 수 있나요?', 'Can your child explain a character\'s feelings in a story?'),
    _Q('lit', '설명문 · 논설문의 중심 내용을 찾을 수 있나요?', 'Can your child find the main point of an essay or article?'),
    _Q('base', '문법(품사 · 문장 성분) 개념을 알고 있나요?', 'Does your child know Korean grammar basics (parts of speech)?'),
    _Q('base', '책을 꾸준히 읽는 편인가요?', 'Does your child read books regularly?'),
    _Q('pre', '다음 학기 국어 교과서를 미리 읽어 보았나요?', 'Has your child read next term\'s Korean textbook in advance?'),
  ],
  '과학': [
    _Q('base', '교과서 핵심 용어를 정확히 알고 있나요?', 'Does your child know the key science terms accurately?'),
    _Q('lit', '실험 과정과 결과를 글로 설명할 수 있나요?', 'Can your child describe an experiment and its result in writing?'),
    _Q('base', '그래프 · 표를 보고 해석할 수 있나요?', 'Can your child read graphs and tables?'),
    _Q('base', '공식을 이용한 계산 문제를 풀 수 있나요?', 'Can your child solve calculation problems using formulas?'),
    _Q('pre', '다음 학기 과학을 미리 공부했나요?', 'Has your child studied next term\'s science in advance?'),
  ],
  '사회': [
    _Q('base', '교과서 핵심 개념을 자기 말로 설명할 수 있나요?', 'Can your child explain key concepts in their own words?'),
    _Q('base', '지도 · 도표 · 자료를 해석할 수 있나요?', 'Can your child interpret maps, charts and data?'),
    _Q('lit', '뉴스나 시사 글을 읽고 이해하나요?', 'Does your child understand news or current-affairs articles?'),
    _Q('lit', '서술형 답을 논리적으로 쓸 수 있나요?', 'Can your child write logical short-essay answers?'),
    _Q('pre', '다음 학기 사회를 미리 공부했나요?', 'Has your child studied next term\'s social studies in advance?'),
  ],
  '역사': [
    _Q('base', '시대의 순서(흐름)를 알고 있나요?', 'Does your child know the order of historical periods?'),
    _Q('base', '주요 사건의 원인과 결과를 설명할 수 있나요?', 'Can your child explain causes and results of key events?'),
    _Q('lit', '사료(옛 글)를 읽고 뜻을 짐작할 수 있나요?', 'Can your child make sense of historical sources?'),
    _Q('lit', '서술형 답을 논리적으로 쓸 수 있나요?', 'Can your child write logical short-essay answers?'),
    _Q('pre', '다음 학기 역사를 미리 공부했나요?', 'Has your child studied next term\'s history in advance?'),
  ],
};

const Map<String, List<_Q>> _kSubjectQ2 = {
  '세계사': [
    _Q('base', '시대별 주요 문명과 나라를 구분할 수 있나요?', 'Can your child tell apart major civilizations by period?'),
    _Q('base', '주요 사건의 원인과 결과를 설명할 수 있나요?', 'Can your child explain causes and results of key events?'),
    _Q('base', '지도에서 주요 나라 · 지역의 위치를 찾을 수 있나요?', 'Can your child locate key countries and regions on a map?'),
    _Q('lit', '긴 설명 글을 읽고 핵심을 정리할 수 있나요?', 'Can your child summarize a long explanatory text?'),
    _Q('pre', '다음 학기 세계사를 미리 공부했나요?', 'Has your child studied next term\'s world history in advance?'),
  ],
  '기술/가정': [
    _Q('base', '교과서 핵심 용어를 정확히 알고 있나요?', 'Does your child know the key terms accurately?'),
    _Q('base', '그림 · 도표(제도, 회로, 영양표)를 읽을 수 있나요?', 'Can your child read drawings and charts (plans, circuits, nutrition tables)?'),
    _Q('lit', '실습 과정을 순서대로 글로 설명할 수 있나요?', 'Can your child describe a practical task step by step in writing?'),
    _Q('lit', '서술형 답을 조리 있게 쓸 수 있나요?', 'Can your child write clear short-essay answers?'),
    _Q('pre', '다음 학기 내용을 미리 살펴보았나요?', 'Has your child looked at next term\'s content in advance?'),
  ],
  '한문': [
    _Q('base', '기초 한자의 뜻과 음을 알고 있나요?', 'Does your child know the meaning and sound of basic Chinese characters?'),
    _Q('base', '한자어의 짜임(구성)을 설명할 수 있나요?', 'Can your child explain how Sino-Korean words are built?'),
    _Q('lit', '짧은 한문 문장을 풀이할 수 있나요?', 'Can your child interpret short classical Chinese sentences?'),
    _Q('lit', '고사성어의 뜻과 유래를 설명할 수 있나요?', 'Can your child explain the meaning and origin of idioms?'),
    _Q('pre', '다음 학기 한문을 미리 공부했나요?', 'Has your child studied next term\'s classical Chinese in advance?'),
  ],
  '제2외국어': [
    _Q('base', '문자와 발음을 정확히 읽을 수 있나요?', 'Can your child read the letters and pronunciation accurately?'),
    _Q('base', '기본 단어를 꾸준히 외우고 있나요?', 'Does your child keep memorizing basic vocabulary?'),
    _Q('base', '기본 문법(문장 순서 · 동사 변화)을 알고 있나요?', 'Does your child know basic grammar (word order, verb forms)?'),
    _Q('lit', '짧은 글을 읽고 뜻을 파악할 수 있나요?', 'Can your child understand a short text?'),
    _Q('pre', '다음 학기 내용을 미리 공부했나요?', 'Has your child studied next term\'s content in advance?'),
  ],
};

/// 과목별 질문 5개 (통합사회 → 사회, 통합과학 → 과학 질문 사용)
List<_Q> _subjectQs(String subject) {
  const Map<String, String> alias = {'통합사회': '사회', '통합과학': '과학'};
  final String key = alias[subject] ?? subject;
  return _kSubjectQ[key] ?? _kSubjectQ2[key] ?? const [];
}


// ============================================================================
// 🔤 영어 진단 질문 — 원장님 설계 (2026-10-14)
// [Part 1] 영어 공통 6문항 + [Part 2~4] 초등부 · 중등부 · 고등부 영어 교과 각 10문항
// · intent = 질문 이유 · 평가 항목 (코드 참고용, 질문 화면에는 안 보임)
// · rx = '아니다'(보완 필요)일 때 리포트 종합 처방에 나오는 문장 (원장님 'AI/리포트 활용')
// · up = '그렇다'일 때 단계 상향에 쓰는 문항 → 상향 문항 중 2개 이상 '그렇다'면 개념·기본 단계를 한 단계 올림 (실력까지)
// · 영어에는 선행 문항이 없어 선행 조건 없이 점수 + 문해력(lit)으로 판정
// ============================================================================
const List<_Q> _kEngCommonQ = [
  _Q('base', '영어 단어를 외울 때 뜻뿐만 아니라 예문이나 소리(발음)도 함께 확인하나요?', 'When memorizing words, does your child also check example sentences and pronunciation?',
      ind: 'eVocabDepth', intent: '어휘 학습 깊이 및 소리-의미 결합력',
      rx: '단어를 뜻만 외우고 있습니다. 예문과 음원이 풍부한 어휘 교재로, 단어마다 예문을 소리 내어 읽으며 외우게 하세요.',
      rxEn: 'Words are memorized by meaning only. Use a vocabulary book with example sentences and audio, and read each example aloud.'),
  _Q('lit', '영어 지문을 읽거나 들을 때 모르는 단어가 나와도 당황하지 않고 앞뒤 맥락으로 뜻을 짐작해 보나요?', 'When an unknown word appears, does your child guess its meaning from the context?',
      ind: 'eContext', intent: '문맥 유추력 및 독해 담력',
      rx: '모르는 단어에서 독해가 멈춥니다. 문맥 중심 독해 훈련으로, 모르는 단어에 표시만 하고 끝까지 읽은 뒤 뜻을 짐작해 보게 하세요.',
      rxEn: 'Reading stops at unknown words. Practice context-based reading: mark the word, read to the end, then guess the meaning.'),
  _Q('lit', '영어로 된 글이나 문제를 풀 때, 문제의 조건과 출제 의도를 정확히 파악하나요?', 'Does your child accurately grasp the conditions and intent of English questions?',
      ind: 'eTask', intent: '문제 이해도 및 조건 파악 능력',
      rx: '문제의 조건을 놓쳐 실수가 생깁니다. 유형별 문제 해결 가이드가 있는 교재로, 문제를 읽을 때 조건에 밑줄을 긋는 습관을 들이세요.',
      rxEn: 'Missed conditions cause mistakes. Use a book with type-by-type guides and underline the conditions in each question.'),
  _Q('base', '학습한 영어 문법이나 구문 원리를 다른 사람(또는 나 자신)에게 말로 설명할 수 있나요?', 'Can your child explain English grammar or sentence-structure rules out loud?',
      ind: 'eMeta', up: true, intent: '메타인지 및 문법 · 구문 원리 이해도',
      rx: '문법을 문제로만 풀고 원리 설명이 어렵습니다. 하루 한 문법을 부모님께 설명하는 "선생님 놀이"를 권합니다.',
      rxEn: 'Grammar is solved but not explained. Try "teacher time": explain one grammar rule to a parent each day.'),
  _Q('base', "틀린 문제를 오답 정리할 때, 내가 '왜 잘못 해석했는지' 또는 '왜 오답을 골랐는지' 원인을 분석하나요?", 'When reviewing mistakes, does your child analyze why they misread or chose the wrong answer?',
      ind: 'eError', intent: '영어 오답 관리 습관 및 피드백 수용성',
      rx: '오답 원인 분석이 약합니다. 해설이 자세한 기출 교재와 함께 [오답 노트]를 쓰세요. (틀린 문장 → 잘못 해석한 부분 → 바른 해석)',
      rxEn: 'Error analysis is weak. Keep an error notebook with a well-explained past-exam book: wrong sentence → misread part → correct reading.'),
  _Q('base', '영어 공부를 할 때 집중력이 흐트러지거나 음원 · 교재에 몰입하지 못하는 경우가 자주 있나요?', 'Does your child often lose focus during English study or audio?',
      ind: 'eFocus', reverse: true, intent: '영어 몰입 지속력 및 학습 집중도',
      rx: '영어 공부의 흐름이 자주 끊깁니다. 분량이 짧고 회당 목표가 분명한 교재를 고르고, [학사 타임라인 → 포모도로 시간표]로 25분 집중 → 5분 휴식을 지켜 주세요.',
      rxEn: 'English study is often interrupted. Choose short, clearly-targeted lessons and use the Pomodoro timetable: 25 min focus → 5 min break.'),
];

const Map<String, List<_Q>> _kEngQ = {
  // 🔤 [Part 2] 초등부 — 파닉스 · 기초 어휘 · 읽기 유창성 · 기초 듣기 · 쓰기
  'elem': [
    _Q('base', '알파벳 소리와 단어 발음 규칙(파닉스)을 알고 처음 보는 단어도 읽을 수 있나요?', 'Does your child know phonics and read new words?',
        ind: 'ePhonics', intent: '파닉스 및 소리-문자 결합력',
        rx: '파닉스가 아직 자리 잡지 않았습니다. 다른 교재보다 파닉스 보완 교재를 가장 먼저 끝내 주세요.',
        rxEn: 'Phonics is not yet solid. Finish a phonics book before anything else.'),
    _Q('base', '하루에 초등 필수 단어를 10~15개 이상 꾸준히 외우고 기억하나요?', 'Does your child memorize 10–15 essential words a day?',
        ind: 'eVocab', intent: '기초 어휘량 및 암기 습관',
        rx: '기초 어휘가 부족합니다. 그림 중심의 초등 단어 워크북으로 하루 10개씩, 다음 날 다시 확인하는 습관을 들이세요.',
        rxEn: 'Basic vocabulary is lacking. Use a picture word workbook: 10 words a day, checked again the next day.'),
    _Q('lit', '짧은 영어 문장을 읽을 때 소리 내어 머뭇거림 없이 읽을 수 있나요?', 'Can your child read short sentences aloud without hesitation?',
        ind: 'eFluency', intent: '읽기 유창성 및 텍스트 친숙도',
        rx: '소리 내어 읽기가 아직 어렵습니다. 음원이 잘 갖춰진 쉬운 독해서(Bricks Reading 50~80)로 하루 1지문 따라 읽기를 하세요.',
        rxEn: 'Reading aloud is still hard. Use easy readers with audio (Bricks Reading 50–80) and shadow one passage a day.'),
    _Q('lit', '쉬운 영어 지문을 읽고 전체적으로 무슨 내용(주제나 줄거리)인지 이해하나요?', 'Does your child understand the main idea of an easy passage?',
        ind: 'eGist', up: true, intent: '대의 파악 및 맥락 이해력',
        rx: '글 전체의 내용을 잡기 어렵습니다. 그림이 강조된 기초 독해서로, 읽은 뒤 한국어로 한 줄 줄거리를 말하게 하세요.',
        rxEn: 'The main idea is hard to grasp. Use picture-rich readers and retell the story in one line afterwards.'),
    _Q('base', '쉬운 영어 문장의 주어(누가)와 동사(무엇을 한다)를 구분할 수 있나요?', 'Can your child tell the subject and verb in an easy sentence?',
        ind: 'eStructure', intent: '문장 구조 인지 및 기초 어순 감각',
        rx: '문장의 뼈대(주어 · 동사)가 아직 안 보입니다. 패턴 중심 초등 문법서(Grammar Space 등)로 주어 · 동사에 표시하는 연습을 하세요.',
        rxEn: 'Sentence structure is not yet clear. Use a pattern-based grammar book (e.g. Grammar Space) and mark subject and verb.'),
    _Q('base', '영어 듣기 파일이나 동화를 들을 때 핵심 단어나 말을 알아듣나요?', 'Does your child catch key words when listening to English audio or stories?',
        ind: 'eListen', intent: '기초 청해력 및 소리 적응력',
        rx: '듣기 기초가 약합니다. 받아쓰기(Dictation)가 들어 있는 초등 리스닝 교재(Listen Up 등)로 하루 1과 듣고 받아쓰세요.',
        rxEn: 'Listening basics are weak. Use a listening book with dictation (e.g. Listen Up), one lesson a day.'),
    _Q('base', '그림이나 단어 카드를 참고하여 쉬운 영어 문장(3~5단어)을 직접 쓸 수 있나요?', 'Can your child write an easy 3–5 word sentence using pictures or word cards?',
        ind: 'eWrite', intent: '기초 쓰기 표현력',
        rx: '쓰기 표현이 아직 어렵습니다. 그래픽 오거나이저(생각 정리표) 형태의 초등 라이팅 입문서로 하루 한 문장씩 써 보세요.',
        rxEn: 'Writing is still hard. Use a beginner writing book with graphic organizers and write one sentence a day.'),
    _Q('base', '영어 동화책이나 짧은 지문을 읽는 것에 대해 재미와 흥미를 느끼나요?', 'Does your child enjoy reading English storybooks or short passages?',
        ind: 'eInterest', intent: '영어 흥미도 및 정서적 친숙도',
        rx: '영어에 대한 흥미가 낮습니다. 흥미 중심의 스토리형 독해집으로 시작하고, 다 읽으면 응원별로 칭찬해 주세요.',
        rxEn: 'Interest in English is low. Start with story-based readers and praise with cheer stars when finished.'),
    _Q('base', '맞춤법(스펠링)을 신경 써서 단어를 올바르게 적으려고 노력하나요?', 'Does your child try to spell words correctly?',
        ind: 'eSpelling', intent: '기초 정서법 및 철자 정확도',
        rx: '철자 실수가 많습니다. 단어 쓰기 노트를 함께 쓰며, 틀린 단어는 3번씩 소리 내어 쓰게 하세요.',
        rxEn: 'Spelling mistakes are frequent. Keep a word-writing notebook and write each wrong word three times aloud.'),
    _Q('base', '일주일에 적어도 2~3회 이상 꾸준히 영어 교재나 동화책을 읽나요?', 'Does your child read English books 2–3 times a week or more?',
        ind: 'eExposure', up: true, intent: '영어 노출 빈도 및 습관 유지력',
        rx: '영어 노출이 부족합니다. 매일 10분이면 끝나는 단기 완결 교재로 영어를 매일 만나게 해 주세요.',
        rxEn: 'English exposure is low. Use a short daily book that takes 10 minutes so English is met every day.'),
  ],
  // 🔤 [Part 3] 중등부 — 교과서 어휘 · 기초 구문 · 내신 문법 · 독해 · 내신 서술형
  'mid': [
    _Q('base', '중학 필수 어휘를 하루 20~30개 이상 꾸준히 암기하고 시험해 보나요?', 'Does your child memorize and self-test 20–30 middle-school words a day?',
        ind: 'emVocab', intent: '중등 어휘력 및 암기 지속력',
        rx: '중등 어휘가 부족합니다. 중학 필수 어휘집(예: 워드마스터 중등)으로 하루 20개 외우고 다음 날 스스로 시험 보세요.',
        rxEn: 'Middle-school vocabulary is lacking. Use a core word book: 20 words a day and a self-test the next day.'),
    _Q('base', '문장의 형식(1~5형식)과 접속사, 관계대명사의 기본 역할을 구분할 수 있나요?', 'Can your child identify sentence patterns, conjunctions and relative pronouns?',
        ind: 'emSyntax', intent: '중등 기초 구문 및 문장 구조 파악력',
        rx: '긴 문장의 구조가 안 보입니다. 주니어 천일문 Basic으로 문장마다 끊어 읽기 표시를 하는 것부터 시작하세요.',
        rxEn: 'Long sentence structure is unclear. Start with Junior Cheonilmun Basic and mark chunks in every sentence.'),
    _Q('base', '중학 내신 문법 개념(시제, 조동사, 부정사, 동명사 등)의 규칙을 이해하고 문제에 적용하나요?', 'Does your child apply school grammar rules (tenses, modals, infinitives, gerunds)?',
        ind: 'emGrammar', intent: '중등 내신 문법 개념 적용력',
        rx: '문법을 감으로 풉니다. Grammar Inside로 개념을 정리하고 중학영문법 3800제로 문제에 적용하는 연습을 하세요.',
        rxEn: 'Grammar is solved by feel. Organize concepts with Grammar Inside and apply them with Middle School Grammar 3800.'),
    _Q('lit', '중학 독해 지문을 읽을 때 앞에서부터 끊어 읽는 직독직해(Chunk) 방식으로 해석하나요?', 'Does your child read passages chunk by chunk from the front?',
        ind: 'emChunk', intent: '직독직해 능력 및 독해 속도',
        rx: '뒤에서부터 번역하듯 읽어 느립니다. 끊어 읽기 안내가 잘 된 독해집(리딩튜터 중학 등)으로 앞에서부터 읽는 연습을 하세요.',
        rxEn: 'Reading is slow, translating from the back. Use a reader with chunking guides (e.g. Reading Tutor) and read front to back.'),
    _Q('lit', '글을 읽고 문단별 중심 내용을 파악하여 글 전체의 주제를 찾을 수 있나요?', 'Can your child find each paragraph\'s main point and the overall topic?',
        ind: 'emTopic', up: true, intent: '주제 도출력 및 중심 내용 파악력',
        rx: '주제 찾기가 어렵습니다. 유형별 독해서로 문단마다 중심 문장에 밑줄을 긋고 주제를 한 줄로 쓰게 하세요.',
        rxEn: 'Finding the topic is hard. Use a type-based reader, underline each key sentence and write the topic in one line.'),
    _Q('base', '중학 영어 듣기평가나 모의고사 문제를 풀 때 놓치는 문제 없이 잘 알아듣나요?', 'Does your child catch everything in school listening tests?',
        ind: 'emListen', intent: '중등 실전 청해력',
        rx: '듣기평가에서 놓치는 문항이 있습니다. 마더텅 중학영어듣기로 평가 4주 전부터 하루 1회 풀고, 틀린 문항은 받아쓰세요.',
        rxEn: 'Some listening items are missed. Do one Mothertongue listening test a day for 4 weeks before the exam and dictate missed items.'),
    _Q('base', '내신 서술형 시험에서 문법 조건(시제, 수일치, 지정 단어 활용)에 맞게 문장을 쓸 수 있나요?', 'Can your child write answers that meet grammar conditions in written tests?',
        ind: 'emWriting', intent: '조건 제시형 영작 능력 및 정서법 정확도',
        rx: '서술형 조건에서 감점됩니다. 문법이 쓰기다 서술형 집중훈련으로 조건에 동그라미 → 답 쓰기 → 채점 기준 비교를 반복하세요.',
        rxEn: 'Points are lost on written conditions. Practice with a written-test training book: circle conditions → write → compare with the rubric.'),
    _Q('base', '모르는 단어가 많거나 길어진 지문을 마주해도 끝까지 포기하지 않고 읽나요?', 'Does your child keep reading long or difficult passages to the end?',
        ind: 'emGrit', intent: '독해 과제 집착력 및 지구력',
        rx: '긴 지문 앞에서 쉽게 포기합니다. 분량이 적당하고 소재가 흥미로운 교재로 "끝까지 읽기" 성공 경험을 쌓게 하세요.',
        rxEn: 'Gives up on long passages. Use moderate, interesting passages to build the experience of finishing.'),
    _Q('base', '틀린 문법이나 어법 문제를 풀 때 해설지를 보고 왜 틀렸는지 확실히 이해하나요?', 'Does your child understand from the explanation why a grammar answer was wrong?',
        ind: 'emFeedback', intent: '어법 피드백 및 오류 교정력',
        rx: '문법 오답을 그냥 넘깁니다. 오답 해설이 자세한 자습형 문법서로, 틀린 문제마다 규칙을 한 줄씩 적게 하세요.',
        rxEn: 'Grammar mistakes are skipped. Use a self-study grammar book with detailed explanations and write the rule for each mistake.'),
    _Q('base', '주 2~3회 이상 중등 독해 지문을 규칙적으로 푸는 습관이 있나요?', 'Does your child regularly do reading passages 2–3 times a week?',
        ind: 'emRoutine', up: true, intent: '독해 감각 유지력 및 루틴 성실도',
        rx: '독해 루틴이 없습니다. 매일 소량 푸는 주간 독해집으로 하루 1지문을 학사 타임라인에 넣어 습관으로 만드세요.',
        rxEn: 'No reading routine. Use a weekly reader with one passage a day and put it in the academic timeline.'),
  ],
  // 🔤 [Part 4] 고등부 — 수능 어휘 · 고난도 어법 · 구문 · 논리 독해 · 수능 실전
  'high': [
    _Q('base', '수능 · 내신 고난도 어휘를 하루 30~50개 이상 외우고, 다의어와 유의어까지 구분하나요?', 'Does your child memorize 30–50 advanced words a day, including multiple meanings and synonyms?',
        ind: 'ehVocab', intent: '수능 어휘력 및 다의어 · 유의어 파악력',
        rx: '수능 어휘가 부족합니다. 수능 기출 어휘집(워드마스터 수능 · 하이퍼 등)으로 하루 30개, 다의어는 예문과 함께 외우세요.',
        rxEn: 'Exam vocabulary is lacking. Use a CSAT word book (e.g. Word Master): 30 words a day, with example sentences for multiple meanings.'),
    _Q('base', '절(Clause)과 구(Phrase)가 복잡하게 얽힌 길고 난해한 고등 문장의 구조를 빠르게 분석하나요?', 'Does your child quickly analyze long, complex sentences with clauses and phrases?',
        ind: 'ehSyntax', intent: '고난도 구문 분석력',
        rx: '긴 문장의 구조 분석이 약합니다. 천일문 기본 · 핵심으로 하루 20문장씩 끊어 읽고 해석을 써 보세요.',
        rxEn: 'Complex sentence analysis is weak. Use Cheonilmun Basic/Core: 20 sentences a day, chunked and translated.'),
    _Q('base', '수능 · 내신 어법 출제 포인트(수일치, 관계사 vs 접속사, 준동사 등)를 파악하고 문제를 푸나요?', 'Does your child solve grammar questions by spotting the tested point?',
        ind: 'ehGrammar', intent: '고등 어법 출제 포인트 파악 및 적용력',
        rx: '어법을 감으로 풉니다. 어법끝으로 출제 포인트를 익히고, 마더텅 수능기출문제집 영어 어법 · 어휘로 문제에 적용하세요.',
        rxEn: 'Grammar is solved by feel. Learn tested points with Eobeopkkeut and apply them with Mothertongue past-exam grammar/vocabulary.'),
    _Q('lit', '제한된 시간 내에 긴 비문학 지문을 직독직해로 빠르게 소화하는 독해 속도가 나오나요?', 'Can your child read long non-fiction passages quickly within the time limit?',
        ind: 'ehSpeed', intent: '직독직해 속도 및 시간 배분 능력',
        rx: '시험 시간이 부족합니다. 기출 문제집(자이스토리 · 마더텅)으로 지문마다 시간을 재고 푸는 훈련을 하세요.',
        rxEn: 'Time runs out in tests. Use past-exam books (Xistory, Mothertongue) and time every passage.'),
    _Q('lit', '글의 논리적 흐름(주제, 반전, 예시, 원인-결과)을 파악하여 주제문과 요지를 찾나요?', 'Does your child follow the logical flow and find the topic sentence and main point?',
        ind: 'ehLogic', up: true, intent: '글의 논리 구조 파악력 및 주제 도출력',
        rx: '글의 논리 흐름을 놓칩니다. 빠른독해 바른독해 같은 유형서로 반전 · 예시 신호어에 표시하며 읽게 하세요.',
        rxEn: 'Logical flow is missed. Use a type-based book like Ppa-ba and mark contrast and example signal words.'),
    _Q('lit', '수능 고난도 킬러 유형(빈칸 추론, 글의 순서, 문장 삽입)의 논리적 해결 접근법을 아나요?', 'Does your child know how to approach blank-filling, ordering and insertion questions?',
        ind: 'ehKiller', intent: '고난도 킬러 유형 논리 추론력',
        rx: '고난도 유형에서 막힙니다. 자이스토리 고난도 영어 독해(1등급 독해)로 하루 3~5문항, 정답 근거 문장에 표시하며 푸세요.',
        rxEn: 'Stuck on killer types. Use Xistory advanced reading: 3–5 items a day, marking the evidence sentence.'),
    _Q('base', '수능 듣기 평가(17문항) 시 1.2~1.4배속 음성도 놓치지 않고 완벽히 만점을 받나요?', 'Does your child get full marks on CSAT listening, even at 1.2–1.4x speed?',
        ind: 'ehListen', intent: '수능 청해 정밀도 및 만점 유지력',
        rx: '듣기 만점이 흔들립니다. 마더텅 수능기출 영어듣기 모의고사로 1배속 → 1.2배속 순서로 듣고 받아쓰세요.',
        rxEn: 'Listening full marks are unstable. Use Mothertongue CSAT listening tests: 1x then 1.2x speed with dictation.'),
    _Q('base', '고등 내신 서술형 시험에서 복잡한 영작 조건(구문 활용, 어형 변화)을 실수 없이 충족하나요?', 'Does your child meet complex writing conditions in school tests without mistakes?',
        ind: 'ehWriting', intent: '고등 내신 영작 정교성 및 어형 변형력',
        rx: '서술형 영작에서 감점됩니다. 어법끝 서술형 · RANK 77 고등 영어 서술형으로 조건 표시 → 답 쓰기 → 채점 기준 비교를 반복하세요.',
        rxEn: 'Points are lost in written tasks. Practice with Eobeopkkeut Writing / RANK 77: mark conditions → write → compare with the rubric.'),
    _Q('base', "독해 문제를 풀고 오답을 할 때, 내가 '잘못 해석한 문장'을 지문에 직접 찾아 표시하나요?", 'When reviewing reading mistakes, does your child mark the misread sentence in the passage?',
        ind: 'ehFeedback', intent: '오답 독해 분석력 및 정교성',
        rx: '감으로 푼 문제를 그냥 넘깁니다. 해설이 자세한 기출서로, 틀린 문제마다 잘못 해석한 문장을 지문에 직접 표시하게 하세요.',
        rxEn: 'Guessed answers are left unchecked. With a well-explained past-exam book, mark the misread sentence for every mistake.'),
    _Q('base', '주 3회 이상 꾸준히 수능 · 모의고사 1회분 또는 고난도 독해 지문 3~5개를 시간에 맞춰 푸나요?', 'Does your child time a full mock test or 3–5 hard passages 3+ times a week?',
        ind: 'ehRoutine', up: true, intent: '학습 지속성 및 시간 배분 실전력',
        rx: '실전 훈련이 부족합니다. 유형별 기출 훈련서로 주 3회, 시간을 재고 푸는 일정을 학사 타임라인에 넣으세요.',
        rxEn: 'Not enough timed practice. Use a type-based past-exam book three times a week, timed, in the academic timeline.'),
  ],
};


// ============================================================================
// 📚 과목별 진단 질문 세트 — 원장님 설계 (2026-10-14)
// 국어 · 수학 · 과학 · 사회(통합사회): [과목 공통 6문항] + [초등부 · 중등부 · 고등부 교과 10문항]
// · ind = 평가 항목(리포트 지표 이름) / intent = 질문 이유 (코드 참고용, 질문 화면에는 안 보임)
// · rx = '아니다'(보완 필요)일 때 리포트 처방 / up = '그렇다'일 때 단계 상향 문항 / reverse = '그렇다'가 나쁜 답
// · 영어 이외 질문은 한국어만 (다른 언어 화면에서도 한국어로 보임)
// ============================================================================
const List<_Q> _kKorCommonQ = [
  _Q('lit', '글을 읽다가 모르는 어휘가 나와도 당황하지 않고 앞뒤 문맥을 통해 뜻을 짐작해 보나요?', '', ind: '어휘 유추력 · 문맥 파악', intent: '어휘 막힘 때 스스로 의미를 유추하는 능동적 독해 태도',
      rx: '모르는 어휘에서 독해가 멈춥니다. 문맥 기반 어휘 학습이 강화된 교재로, 모르는 낱말에 표시만 하고 끝까지 읽은 뒤 뜻을 짐작해 보게 하세요.'),
  _Q('lit', '국어 글을 읽거나 문제를 풀 때, 문제의 조건과 출제자의 의도를 정확히 파악하나요?', '', ind: '문제 이해도 · 조건 파악', intent: '정답의 조건을 읽어내는 인지 능력',
      rx: '문제 조건을 놓쳐 실점합니다. 문제 조건 분석 훈련이 포함된 유형서로, 발문의 조건에 밑줄을 긋는 습관을 들이세요.'),
  _Q('base', '읽은 글의 핵심 내용이나 문학 작품의 줄거리를 다른 사람(또는 나 자신)에게 말로 설명할 수 있나요?', '', ind: '메타인지 · 지문 완전 이해', up: true, intent: '읽은 내용을 정확히 이해하는지 확인하는 메타인지',
      rx: '눈으로만 읽고 있습니다. 읽은 글을 부모님께 3문장으로 설명하는 "선생님 놀이"를 권합니다.'),
  _Q('base', "틀린 문제를 오답 정리할 때, '왜 잘못 해석했는지' 또는 '왜 이 오답 함정에 걸렸는지' 이유를 분석하나요?", '', ind: '국어 오답 관리', intent: '동일한 독해 · 개념 실수 반복 방지',
      rx: '오답 원인 분석이 약합니다. 해설이 정교한 기출 분석서와 함께 [오답 노트]를 쓰세요. (틀린 선지 → 함정의 이유 → 지문 근거)'),
  _Q('base', '긴 국어 지문이나 책을 읽을 때 딴생각을 하지 않고 끝까지 몰입해서 읽나요?', '', ind: '독해 몰입 · 집중도', intent: '텍스트 집중 몰입도와 독서 지구력',
      rx: '긴 글에서 집중이 끊깁니다. 지문 길이가 적당하고 회당 목표가 분명한 교재로, [학사 타임라인 → 포모도로 시간표] 25분 집중을 지켜 주세요.'),
  _Q('base', '주 2~3회 이상 국어 지문이나 책을 읽는 규칙적인 국어 공부 습관이 형성되어 있나요?', '', ind: '국어 학습 루틴', up: true, intent: '국어 감각을 유지하는 노출 · 루틴',
      rx: '국어 공부 루틴이 없습니다. 매일 소량 푸는 일일 독해집으로 하루 1지문을 학사 타임라인에 넣어 습관으로 만드세요.'),
];

const Map<String, List<_Q>> _kKorQ = {
  'elem': [
    _Q('base', '교과서나 책에 나오는 한자어의 뜻을 대략이라도 알고 있나요?', '', ind: '한자어 기초 어휘력', intent: '국어 어휘의 바탕이 되는 기초 한자어',
        rx: '한자어 어휘가 약합니다. 초등 한자 어휘력 교재를 꼭 함께 해 주세요. 하루 5개, 뜻과 예문을 함께 익힙니다.'),
    _Q('lit', '한 단락(문단)을 읽고 "이 문단은 무슨 내용이다"라고 한 문장으로 요약할 수 있나요?', '', ind: '문단 요약력', intent: '문단의 핵심 내용 요약 능력',
        rx: '문단 요약이 어렵습니다. 문단 요약 훈련이 들어간 독해집으로, 문단마다 한 문장 요약을 써 보게 하세요.'),
    _Q('lit', '글의 전체적인 줄거리나 사건의 순서(원인과 결과)를 생각하며 읽나요?', '', ind: '글의 구조 · 인과관계 파악', intent: '인과관계와 서사 구조를 파악하는 논리적 독해',
        rx: '글의 흐름을 놓칩니다. 그래픽 오거나이저(글 구조도)가 들어간 독해서로, 읽은 뒤 사건 순서를 그림으로 정리하게 하세요.'),
    _Q('base', '시나 이야기책을 읽고 인물의 마음이나 기분을 상상하며 공감할 수 있나요?', '', ind: '문학적 공감력', intent: '인물의 정서를 수용하는 감상 능력',
        rx: '인물의 마음 읽기가 어렵습니다. 감정 표현 어휘를 다루는 교재로, "이때 인물의 기분은?"을 함께 이야기해 주세요.'),
    _Q('base', '설명하는 글(비문학)을 읽고 새로운 지식이나 사실을 이해하는 것을 좋아하나요?', '', ind: '비문학 수용도', intent: '정보 전달형 글에 대한 흥미와 호기심',
        rx: '설명하는 글에 흥미가 낮습니다. 아이가 좋아하는 주제(동물, 우주 등)의 쉬운 설명문부터 읽게 하세요.'),
    _Q('base', '글을 읽은 후 내 생각이나 느낌을 글(한두 문장)이나 말로 표현할 수 있나요?', '', ind: '사고 표현력 · 기초 쓰기', intent: '읽은 내용을 표현으로 바꾸는 능력',
        rx: '읽은 뒤 표현이 어렵습니다. 한 줄 감상평 쓰기가 연계된 독해집으로 매일 한 문장씩 생각을 쓰게 하세요.'),
    _Q('base', '맞춤법이나 띄어쓰기를 크게 틀리지 않고 올바르게 쓰나요?', '', ind: '맞춤법 · 띄어쓰기', intent: '글쓰기의 기초 규범',
        rx: '맞춤법 · 띄어쓰기 실수가 많습니다. 맞춤법 · 띄어쓰기 교재로 하루 한 쪽, 틀린 낱말은 3번씩 고쳐 쓰게 하세요.'),
    _Q('base', '시의 운율(리듬감)이나 재미있는 말의 느낌을 살려 읽을 수 있나요?', '', ind: '시적 표현 감각', intent: '시적 언어와 표현법 감각',
        rx: '시의 맛을 느끼기 어려워합니다. 동시 감상 교재로 소리 내어 읽고, 재미있는 표현에 동그라미를 치게 하세요.'),
    _Q('lit', '글 속에 등장하는 대명사(이것, 그것, 그 사람)가 무엇을 가리키는지 찾을 수 있나요?', '', ind: '지시어 · 접속어 파악', intent: '문장 간 연결성 파악',
        rx: '문장 연결을 놓칩니다. 지시어 · 접속어 훈련이 강화된 독해서로, "그것"이 가리키는 말에 화살표를 그리게 하세요.'),
    _Q('base', '일주일에 적어도 책 한 권 이상을 스스로 찾아 읽나요?', '', ind: '독서 자발성', up: true, intent: '자발적 독서량 및 독서 습관',
        rx: '스스로 읽는 습관이 약합니다. 쉬운 독해서부터 시작하고, 주말마다 함께 서점이나 도서관에 가 주세요.'),
  ],
  'mid': [
    _Q('base', '중학 국어 교과서에 나오는 한자 어휘와 기초 개념어의 뜻을 정확히 파악하며 읽나요?', '', ind: '중등 국어 어휘력', intent: '중등 국어 학습의 바탕 어휘력',
        rx: '국어 어휘가 부족합니다. 중학 국어 어휘 전문 교재로 하루 10개씩 익히고 예문을 만들어 보게 하세요.'),
    _Q('lit', '비문학 지문을 읽을 때 문단별 중심 내용과 전체 구조를 메모하거나 밑줄 치며 읽나요?', '', ind: '비문학 구조 독해', intent: '비교 · 대조 · 인과 구조를 파악하는 독해 습관',
        rx: '구조를 보지 않고 읽습니다. 중학 비문학 독해집(빠작 비문학 등)으로 문단마다 중심 문장에 밑줄을 긋게 하세요.'),
    _Q('base', '시를 읽을 때 화자의 상황, 정서, 태도 및 시어의 의미(긍정/부정)를 구분할 수 있나요?', '', ind: '시 분석력', intent: '운문 문학의 핵심 출제 요소',
        rx: '시 분석이 약합니다. 시 분석 특화 교재로 화자 · 정서 · 태도를 표로 정리하는 연습을 하세요.'),
    _Q('base', '소설을 읽을 때 등장인물 간의 갈등 구조와 서술자의 시점(1인칭/3인칭)을 파악하나요?', '', ind: '소설 분석력', intent: '인물 갈등 · 시점 파악',
        rx: '소설 분석이 약합니다. 소설 갈래별 특화 교재(빠작 문학 등)로 인물 관계도와 시점을 정리하게 하세요.'),
    _Q('base', '국어 문법(품사, 문장성분, 음운 변동 등)의 기본 규칙을 이해하고 문제에 적용할 수 있나요?', '', ind: '국어 문법 적용력', intent: '규칙에 의한 문법 문제 해결',
        rx: '국어 문법을 감으로 풉니다. 중학 국어 문법 문제집(체크체크 등)을 꼭 함께 해, 규칙을 정리하고 문제에 적용하세요.'),
    _Q('base', '긴 비문학 지문을 읽을 때 독해 속도가 느려 시험 시간이 부족하다고 느끼나요?', '', ind: '독해 속도 · 시간 관리', reverse: true, intent: '제한 시간 내 지문 소화 속도',
        rx: '독해 속도가 느립니다. 지문마다 시간을 재고 푸는 타이머 독해 훈련을 하세요.'),
    _Q('lit', "문제를 풀 때 지문에서 정답의 '확실한 근거 문장'을 찾아 표시하는 습관이 있나요?", '', ind: '근거 찾기 습관', intent: '감 풀이를 배제한 근거 수집 태도',
        rx: '감으로 답을 고릅니다. 정답 근거 표시란이 잘 된 독해집으로, 모든 문제에 근거 문장을 표시하게 하세요.'),
    _Q('base', '중학 필수 문학 개념어(예: 비유, 상징, 반어, 역설 등)의 정확한 뜻을 아나요?', '', ind: '문학 개념어', intent: '선지에 자주 나오는 개념어',
        rx: '문학 개념어가 부족합니다. 중등 국어 개념어 교재로 개념어마다 예시 작품을 함께 익히세요.'),
    _Q('base', '내신 서술형 문제에서 조건(단어 포함, 문장 성분 등)에 맞춰 정확하게 답안을 작성하나요?', '', ind: '서술형 조건 충족', intent: '내신 서술형 감점 방지',
        rx: '서술형 조건에서 감점됩니다. 중등 내신 서술형 문제집으로 조건 표시 → 답 쓰기 → 채점 기준 비교를 반복하세요.'),
    _Q('base', '수필이나 설명문, 논설문 등 다양한 갈래의 글을 읽고 각 갈래의 특징을 구분하나요?', '', ind: '갈래별 독해 전략', intent: '갈래 특성에 맞춘 독해 전략',
        rx: '갈래 구분이 약합니다. 갈래별 문학 · 비문학 유형서로 갈래마다 읽는 법을 정리하세요.'),
  ],
  'high': [
    _Q('base', '지문 속에 나오는 고난도 한자 어휘나 수능/내신 필수 어휘의 정확한 의미를 파악하며 읽나요?', '', ind: '고등 고급 어휘력', intent: '수능 · 내신 지문의 어휘 장벽',
        rx: '고급 어휘가 부족합니다. 수능 · 내신 국어 어휘집을 꼭 함께 하세요. 하루 20개, 예문과 함께 외웁니다.'),
    _Q('lit', '고난도 비문학(독서 - 철학, 경제, 기술 등) 지문의 문단 간 논리적 구조를 정확히 파악하나요?', '', ind: '고난도 비문학 독해', intent: '수능 킬러 지문의 논리 흐름',
        rx: '고난도 비문학이 약합니다. 기출 분석서(자이스토리 · 마더텅 · 매3비)로 하루 2지문, 문단 구조를 정리하세요.'),
    _Q('base', '시/고전시가를 읽을 때 화자의 정서/태도와 고전 시어의 현대어 해석이 가능하나요?', '', ind: '운문 · 고전시가 해석', intent: '고등 운문 · 고전시가 해석',
        rx: '고전시가 해석이 약합니다. 고전시가 특강 교재로 자주 나오는 고전 시어를 정리하세요.'),
    _Q('base', '고전소설 및 현대소설 지문에서 서술상의 특징(서술자 개입, 장면의 전환 등)을 찾아내나요?', '', ind: '소설 서술상 특징', intent: '서술 방식 문제 해결',
        rx: '서술상 특징 문제에서 막힙니다. 문학 기출 유형집으로 서술상 특징 유형만 모아 풀어 보세요.'),
    _Q('base', '언어와 매체(문법) 영역의 고난도 문법 체계(음운, 단어, 문장, 중세국어)를 다 체화했나요?', '', ind: '언어와 매체(문법)', intent: '내신 · 수능 언매 적용력',
        rx: '문법(언매)이 약합니다. 고등 국어 문법 개념서 · 문제집으로 단원별 개념을 정리하고 기출에 적용하세요.'),
    _Q('base', '수능 국어 80분 동안 45문항을 풀 때 시간 배분(화작/언매, 문학, 비문학)이 안정적인가요?', '', ind: '실전 시간 배분', intent: '실전 타임어택 배분 능력',
        rx: '시간 배분이 흔들립니다. 실전 모의고사로 영역별 목표 시간을 정하고 지키는 연습을 하세요.'),
    _Q('base', '선지에 나오는 고난도 문학 개념어(예: 객관적 상관물, 감정이입, 공간의 이동 등)를 완벽히 아나요?', '', ind: '고등 문학 개념어', intent: '개념어 함정 회피',
        rx: '문학 개념어 함정에 걸립니다. 고등 문학 개념어 교재로 개념어마다 기출 선지를 함께 익히세요.'),
    _Q('lit', '비문학의 3점 킬러 문제(보기 적용 문제)를 논리적으로 접근하여 해결하나요?', '', ind: '고난도 추론 · 적용', up: true, intent: '추론 · 적용 고득점 문항',
        rx: '보기 적용 문제에서 막힙니다. 기본 기출서로 보기와 지문을 하나씩 대응시키는 연습부터 하세요.'),
    _Q('base', '틀린 문제를 오답할 때, 매력적인 오답 선지가 왜 틀렸는지 지문에서 근거를 적어 보나요?', '', ind: '오답 함정 분석', intent: '매력적 오답 회피 분석력',
        rx: '오답 선지 분석이 약합니다. 자습형 기출 분석서로 틀린 선지마다 지문 근거를 한 줄씩 적게 하세요.'),
    _Q('base', '주 3회 이상 수능/모의고사 기출 지문을 시간에 맞춰 풀고 분석하는 루틴이 있나요?', '', ind: '기출 분석 루틴', up: true, intent: '실전 독해 감각 유지',
        rx: '기출 루틴이 없습니다. 유형별 기출서로 주 3회, 시간을 재고 푸는 일정을 학사 타임라인에 넣으세요.'),
  ],
};

const List<_Q> _kMathCommonQ = [
  _Q('base', '수학 공식을 암기할 때, 왜 그 공식이 성립하는지 개념과 원리를 이해하려고 하나요?', '', ind: '수학 개념 · 원리 이해', intent: '원리 이해 중심 학습 태도',
      rx: '공식을 외우기만 합니다. 개념 설명이 친절한 개념서(개념원리 등)로 "왜 그런지"를 읽고 직접 유도해 보게 하세요.'),
  _Q('base', '문제를 풀 때 풀이 과정을 단계별로 깔끔하게 적어 내려가는 습관이 있나요?', '', ind: '풀이 과정 정교성', intent: '연산 실수 방지 · 서술형 대비',
      rx: '풀이를 머리로만 합니다. 풀이 노트를 따로 두고 한 줄에 한 단계씩 쓰는 습관을 들이세요.'),
  _Q('base', '모르는 문제를 만났을 때, 바로 답지나 선생님에게 묻지 않고 최소 15~20분 이상 스스로 고민하나요?', '', ind: '수학적 끈기', up: true, intent: '수학적 사고력의 핵심인 과제 집착력',
      rx: '모르는 문제에 금방 답지를 봅니다. 준유형서로 자신감을 쌓고, "답지 보기 전 15분 고민" 규칙을 앱 타이머로 지켜 보세요.'),
  _Q('base', '수학 풀이 과정 중 계산 실수나 단순 대입 실수가 적은 편인가요?', '', ind: '연산 정확도', intent: '연산 정확도 및 감점 요인',
      rx: '계산 실수로 점수를 잃습니다. 연산 교재(기적의 계산법 · 라이트쎈 등)를 하루 10분 함께 하고 검산 습관을 붙이세요.'),
  _Q('base', "틀린 수학 문제를 오답 정리할 때, '어느 풀이 단계에서 왜 틀렸는지' 정확히 분석하고 다시 푸나요?", '', ind: '수학 오답 피드백', intent: '오답 피드백을 통한 약점 보완',
      rx: '오답 정리가 약합니다. [오답 클리닉 노트]를 쓰세요. (틀린 단계 → 이유 한 줄 → 3일 뒤 다시 풀기)'),
  _Q('base', '매일 규칙적으로 일정량의 수학 문제를 풀며 공부 감각을 유지하고 있나요?', '', ind: '수학 학습 루틴', up: true, intent: '수학 감각을 유지하는 지속성',
      rx: '수학 루틴이 없습니다. 하루 분량을 정한 데일리 학습지로 매일 같은 시간에 풀게 하세요.'),
];

const Map<String, List<_Q>> _kMathQ = {
  'elem': [
    _Q('base', '자연수의 사칙연산(덧셈, 뺄셈, 곱셈, 나눗셈)을 실수 없이 빠르고 정확하게 하나요?', '', ind: '기초 연산력', intent: '초등 기초 연산 완성도',
        rx: '기초 연산이 흔들립니다. 연산 전문 교재(기적의 계산법 등)를 꼭 함께 해 주세요. 하루 2쪽, 시간을 재고 풉니다.'),
    _Q('base', '분수와 소수의 개념을 이해하고, 분수/소수의 사칙연산을 풀 수 있나요?', '', ind: '분수 · 소수', intent: '초등 고학년 핵심 개념',
        rx: '분수 · 소수가 약합니다. 분수 · 소수 특강 교재로 그림과 함께 개념부터 다시 잡아 주세요.'),
    _Q('base', '교과서에 나오는 예제와 기본 문제를 다른 사람의 도움 없이 혼자 힘으로 푸나요?', '', ind: '기본 개념 도달', intent: '최소한의 기본 개념 도달 여부',
        rx: '기본 개념이 아직입니다. 디딤돌 초등수학 원리 같은 개념서로 예제를 혼자 다시 푸는 연습부터 하세요.'),
    _Q('lit', '문장으로 된 문제(문장제)를 읽고 무엇을 구해야 하는지 식을 세울 수 있나요?', '', ind: '문장제 식 세우기', intent: '문장을 식으로 바꾸는 응용력',
        rx: '문장제에서 막힙니다. 문장제 특화 문제집으로 조건에 밑줄, 구하는 것에 동그라미를 치고 식을 세우게 하세요.'),
    _Q('base', '여러 가지 평면도형과 입체도형의 이름과 성질(변, 꼭짓점, 면 등)을 아나요?', '', ind: '도형 기초 개념', intent: '초등 도형 기초 개념',
        rx: '도형 기초가 약합니다. 도형 특화 교재로 직접 그리고 접어 보며 성질을 익히게 하세요.'),
    _Q('base', '도형의 넓이, 둘레, 입체도형의 부피를 구하는 공식을 원리와 함께 이해하나요?', '', ind: '도형 측정 공식', intent: '측정 공식의 원리 이해',
        rx: '넓이 · 부피 공식을 외우기만 합니다. 원리 중심 도형 교재로 공식이 나오는 과정을 그림으로 확인하게 하세요.'),
    _Q('base', '규칙 찾기, 비와 비율 개념을 이해하고 실생활 문제에 적용하나요?', '', ind: '규칙성 · 비와 비율', intent: '중등 함수 · 방정식의 바탕',
        rx: '비와 비율이 약합니다. 비와 비율 집중 훈련서로 실생활 예(할인, 지도 축척)와 함께 연습하세요.'),
    _Q('base', '디딤돌 응용이나 쎈 B단계 정도의 문항을 혼자 힘으로 풀어내나요?', '', ind: '응용 문제 해결력', up: true, intent: '기본~응용 유형 해결 수준'),
    _Q('base', '최상위수학이나 경시대회 수준의 고난도 문제를 보면 도전하고 싶은 의욕이 생기나요?', '', ind: '심화 도전 의지', up: true, intent: '최고난도 도전 정신'),
    _Q('pre', '다음 학기 수학 개념서를 스스로 한 번 이상 읽거나 선행 공부해 본 적이 있나요?', '', ind: '선행 학습', intent: '선행 학습 경험 및 진도 소화',
        rx: '예습이 되어 있지 않습니다. 방학 때 예습형 개념서로 다음 학기 개념을 한 번 훑어 두세요.'),
  ],
  'mid': [
    _Q('base', '소수, 합성수, 인수분해, 유리수 등 중등 수와 연산의 개념을 정확히 이해하나요?', '', ind: '수 체계 이해', intent: '중등 수 체계 기본기',
        rx: '수 체계가 약합니다. 수와 연산 단원을 개념서로 다시 정리하고 라이트쎈으로 보완하세요.'),
    _Q('lit', '문자와 식, 일차방정식/연립방정식을 자유롭게 풀고 활용 문제에 식을 세우나요?', '', ind: '방정식 · 식 세우기', intent: '중등 대수 핵심 해결 능력',
        rx: '방정식 활용이 약합니다. 방정식 활용 특강 교재로 문장을 식으로 바꾸는 연습을 집중하세요.'),
    _Q('base', '일차함수와 이차함수의 그래프를 그리고, 함수와 방정식의 관계를 이해하나요?', '', ind: '함수 · 그래프', intent: '고등 수학 연계 핵심',
        rx: '함수가 약합니다. 중등 함수 집중서로 그래프를 직접 그리며 식과 그래프를 연결하세요.'),
    _Q('base', '삼각비, 피타고라스 정리, 원의 성질 등 중등 기하 공식을 증명하고 적용하나요?', '', ind: '기하 증명 · 적용', intent: '중등 도형 원리 이해 및 적용',
        rx: '기하가 약합니다. 중등 기하 특화 교재로 그림을 직접 그리며 증명 과정을 따라 써 보세요.'),
    _Q('base', '유형서(RPM, 쎈 B단계 등)에 나오는 대표 유형 문제들을 막힘없이 풀 수 있나요?', '', ind: '대표 유형 숙련도', up: true, intent: '유형별 풀이 숙련도',
        rx: '대표 유형이 아직 손에 익지 않았습니다. RPM · 쎈 B단계를 한 번 더 돌리는 것이 심화보다 먼저입니다.'),
    _Q('base', '서술형 문제에서 감점 없이 식과 이유를 정확히 적어 완벽한 답안을 작성하나요?', '', ind: '서술형 완성도', intent: '내신 서술형 감점 방지',
        rx: '서술형에서 감점됩니다. 서술형 집중 훈련서로 식 → 이유 → 답 순서로 쓰는 연습을 하세요.'),
    _Q('base', '최고난도 문제(쎈 C단계, 일품, A급수학 등)를 만나면 포기하지 않고 도전하나요?', '', ind: '심화 도전력', up: true, intent: '고난도 심화 도전 정신'),
    _Q('base', '계산 과정에서 부호 실수, 분수 계산 실수가 적은 편인가요?', '', ind: '연산 정교성', intent: '중등 연산의 정교함',
        rx: '부호 · 분수 계산 실수가 많습니다. 라이트쎈 · RPM 연산 파트로 하루 10문제씩 보완하세요.'),
    _Q('pre', '다음 학기(또는 다음 학년) 수학 개념서를 혼자 힘으로 한 번 이상 완독해 보았나요?', '', ind: '선행 소화력', intent: '선행 학습 소화 및 독학 능력',
        rx: '선행이 되어 있지 않습니다. 방학 때 예습용 개념서로 다음 학기 개념을 한 번 끝내 두세요.'),
    _Q('base', '확률과 통계(경우의 수, 확률) 파트의 조건을 정확히 나누어 풀어내나요?', '', ind: '경우의 수 · 확률', intent: '확통 조건 분류 능력',
        rx: '경우의 수가 약합니다. 경우의 수 특화 교재로 표 · 나뭇가지 그림을 그려 조건을 나누는 연습을 하세요.'),
  ],
  'high': [
    _Q('base', '다항식, 인수분해, 복소수, 이차방정식/이차함수의 연계 원리를 완벽히 파악하고 있나요?', '', ind: '고등 대수 기초', intent: '공통수학1 대수 기본기',
        rx: '고등 대수 기초가 약합니다. 개념원리 · 마플교과서 같은 기본 개념서로 단원별 연계를 정리하세요.'),
    _Q('base', '지수·로그함수, 삼각함수의 그래프와 성질을 이해하고 방정식/부등식에 적용하나요?', '', ind: '수Ⅰ 함수 · 그래프', intent: '수Ⅰ 핵심 영역 이해',
        rx: '수Ⅰ 함수가 약합니다. RPM · 마플시너지 같은 유형집으로 그래프 유형을 집중 연습하세요.'),
    _Q('lit', '함수의 극대·극소, 미분계수, 정적분의 정의를 활용하여 고난도 그래프를 해석하나요?', '', ind: '수Ⅱ 미적분 추론', intent: '수Ⅱ 미적분 기초 및 그래프 추론',
        rx: '수Ⅱ 그래프 추론이 약합니다. 수Ⅱ 기본서 · 실력서로 그래프를 직접 그리며 개념을 연결하세요.'),
    _Q('base', '쎈 C단계나 마플시너지 상위권 문제를 혼자 힘으로 풀어내나요?', '', ind: '응용 · 준심화 해결력', up: true, intent: '내신 상위권 문제 소화력'),
    _Q('lit', '수능/모의고사 기출문제(4점 문항)의 출제 의도를 파악하고 해석해 내나요?', '', ind: '수능 4점 분석력', up: true, intent: '수능 기출 4점 해결 능력'),
    _Q('lit', '조건 제시형 문항(가, 나, 다 조건)이 주어졌을 때, 논리적으로 케이스를 나누어 푸나요?', '', ind: '케이스 분류 · 논리 추론', up: true, intent: '킬러 문항 조건 분류 능력'),
    _Q('base', '제한된 시험 시간(50분/100분) 동안 시간 부족 없이 검산까지 완벽히 마치나요?', '', ind: '실전 시간 배분', intent: '실전 타임어택 배분',
        rx: '시험 시간이 부족합니다. 실전 모의고사 훈련서로 시간을 재고 푸는 연습을 주 2회 하세요.'),
    _Q('base', "모르는 문제를 해설지를 보고 공부할 때, '내가 떠올리지 못한 아이디어'를 노트에 정리하나요?", '', ind: '발상력 피드백', intent: '수학적 발상력 보완 습관',
        rx: '해설을 읽고 넘어갑니다. 자습형 기출 해설서로 "떠올리지 못한 아이디어"를 노트에 한 줄씩 모으세요.'),
    _Q('base', '내신 서술형 문제에서 감점 요인(조건 미충족, 범위 미지정) 없이 완벽히 식을 쓰나요?', '', ind: '고등 서술형 완성도', intent: '고등 내신 서술형 정교성',
        rx: '서술형에서 감점됩니다. 내신 서술형 대비집으로 조건 · 범위를 빠짐없이 쓰는 연습을 하세요.'),
    _Q('base', '주 3회 이상 고등 수학 문제를 꾸준히 풀며 풀이 속도와 감각을 유지하나요?', '', ind: '고등 수학 루틴', intent: '학습 감각 유지',
        rx: '수학 감각이 끊깁니다. 유형서로 주 3회 이상 일정을 학사 타임라인에 넣어 꾸준히 푸세요.'),
  ],
};

const List<_Q> _kSciCommonQ = [
  _Q('base', "과학 개념이나 원리를 배울 때, 단순히 암기하지 않고 '왜 그 현상이 일어나는지' 원리를 이해하려고 하나요?", '', ind: '과학 원리 이해', intent: '단순 암기와 원리 이해 구분',
      rx: '외우기만 합니다. 원리 설명이 잘 된 개념서로 "왜?"를 한 줄씩 적어 보게 하세요.'),
  _Q('base', '과학 탐구 과정(가설 설정, 실험 설계, 변인 통제, 결과 해석)의 흐름을 이해하고 있나요?', '', ind: '탐구 과정 파악', intent: '과학적 탐구 기능 및 실험 해석',
      rx: '탐구 과정이 약합니다. 실험 탐구 특화 교재로 가설 → 실험 → 결과 → 결론을 표로 정리하게 하세요.'),
  _Q('lit', '과학 문제의 그래프, 표, 그림 자료를 보고 필요한 정보와 의미를 올바르게 해석하나요?', '', ind: '자료 해석력', intent: '과학 시험의 핵심인 자료 해석',
      rx: '자료 해석이 약합니다. 자료 해석 유형집으로 그래프의 축과 단위부터 읽는 습관을 들이세요.'),
  _Q('base', '배운 과학 원리를 나 자신이나 다른 사람에게 쉬운 말로 설명할 수 있나요?', '', ind: '메타인지 · 개념 완전 학습', up: true, intent: '과학 개념의 완전 학습',
      rx: '설명하지 못하는 개념이 있습니다. 하루 한 개념을 부모님께 설명하는 "선생님 놀이"를 권합니다.'),
  _Q('base', "틀린 과학 문제를 오답 정리할 때, '어떤 개념을 오해했는지' 원리에 기반하여 분석하나요?", '', ind: '과학 오답 피드백', intent: '과학 오답 분석 태도',
      rx: '오답 분석이 약합니다. [오답 개념 클리닉] 노트로 틀린 문제마다 오해한 개념을 한 줄씩 적게 하세요.'),
  _Q('base', '일상생활에서 일어나는 자연 현상이나 과학 뉴스에 호기심을 느끼고 원리를 생각해 보나요?', '', ind: '과학 흥미 · 호기심', intent: '과학에 대한 흥미와 친숙도',
      rx: '과학 흥미가 낮습니다. 재미있는 교양 과학책이나 실험 영상으로 호기심부터 키워 주세요.'),
];

const Map<String, List<_Q>> _kSciQ = {
  'elem': [
    _Q('base', '동식물의 생김새, 자라는 과정, 서식지 등 생물 영역의 기초 사실을 잘 알고 있나요?', '', ind: '생명과학 기초', intent: '초등 생명과학 기초 지식',
        rx: '생물 기초가 약합니다. 그림 중심 생물 교재로 관찰 일기를 함께 써 보세요.'),
    _Q('base', '물체의 상태 변화(기체, 액체, 고체)와 물질의 성질을 구분할 수 있나요?', '', ind: '화학 기초', intent: '초등 화학 기초 개념',
        rx: '물질의 상태가 헷갈립니다. 물질 상태 특화 교재로 얼음 · 물 · 수증기 예부터 정리하세요.'),
    _Q('base', '자석의 성질, 자석의 극, 그림자의 생김새 등 물리학의 기초 현상을 이해하나요?', '', ind: '물리 기초 현상', intent: '초등 물리 기초 현상',
        rx: '물리 현상이 약합니다. 실험 연계 물리 교재로 집에서 자석 · 그림자 실험을 해 보세요.'),
    _Q('base', '계절의 변화, 날씨, 지형, 태양계와 달의 운동 등 지구과학 기초를 아나요?', '', ind: '지구과학 기초', intent: '초등 지구과학 기초',
        rx: '지구과학 기초가 약합니다. 시각 자료 중심 지구과학 교재로 달 모양 · 계절 변화를 그림으로 정리하세요.'),
    _Q('base', '실험 도구(돋보기, 온도계, 저울 등)의 올바른 사용법과 측정 방법을 아나요?', '', ind: '탐구 도구 사용', intent: '과학 탐구 도구 사용 능력',
        rx: '실험 도구 사용이 서툽니다. 탐구 가이드 교재로 도구마다 사용법을 사진과 함께 익히게 하세요.'),
    _Q('lit', '실험 결과를 보고 "무엇 때문에 이런 결과가 나왔다"라고 원인을 말할 수 있나요?', '', ind: '실험 결과 인과관계', intent: '실험 결과 해석 능력',
        rx: '결과의 원인 설명이 어렵습니다. 결과 해석 중심 문제집으로 "왜냐하면"으로 시작하는 문장을 써 보게 하세요.'),
    _Q('base', '과학 단원 평가나 문제집을 풀 때 문항의 핵심 내용을 읽고 문제를 올바르게 푸나요?', '', ind: '과학 문제 해결력', up: true, intent: '초등 과학 정답률'),
    _Q('base', '과학 교과서에 나오는 핵심 용어(예: 증발, 응결, 용해 등)의 뜻을 설명할 수 있나요?', '', ind: '과학 용어력', intent: '초등 과학 용어 이해',
        rx: '과학 용어가 약합니다. 과학 용어 교재로 용어마다 예를 하나씩 붙여 익히게 하세요.'),
    _Q('base', '학교 과학 실험 시간에 직접 실험하고 관찰하는 것을 즐기나요?', '', ind: '실험 참여 태도', intent: '과학 실험 태도',
        rx: '실험 참여가 소극적입니다. 쉬운 실험 영상과 함께 집에서 할 수 있는 실험부터 해 보세요.'),
    _Q('base', '과학 동화나 어린이 과학 잡지/책을 스스로 찾아 읽나요?', '', ind: '과학 독서 자발성', up: true, intent: '자발적 과학 독서량',
        rx: '과학 독서가 적습니다. 기본 교재와 함께 어린이 과학 잡지를 한 달에 한 권 함께 읽어 주세요.'),
  ],
  'mid': [
    _Q('base', '물리 영역(운동, 힘, 전기와 자기, 열과 에너지)을 공식과 함께 이해하고 문제를 푸나요?', '', ind: '물리 개념 · 계산', intent: '중등 물리 공식 적용',
        rx: '물리 계산이 약합니다. 물리 집중 개념서로 공식마다 단위와 예제를 함께 정리하세요.'),
    _Q('base', '화학 영역(물질의 구성, 이온, 화학 반응식, 농도)의 원소 기호와 반응식을 이해하나요?', '', ind: '화학 원소 · 반응식', intent: '중등 화학 반응식 원리',
        rx: '화학 반응식이 약합니다. 화학 반응식 특강 교재로 원소 기호부터 매일 5개씩 익히세요.'),
    _Q('base', '생명과학 영역(식물과 에너지, 동물과 에너지, 자극과 반응, 생식과 유전)의 구조를 아나요?', '', ind: '생명과학 체계', intent: '중등 생명과학 구조 · 암기 체계',
        rx: '생명과학 정리가 약합니다. 완자 · 오투 생물 파트로 구조를 그림으로 그려 정리하세요.'),
    _Q('base', '지구과학 영역(지구 시스템, 수권, 기권과 날씨, 별과 우주)의 지형/천체 현상을 이해하나요?', '', ind: '지구과학 현상', intent: '중등 지구과학 시각적 이해',
        rx: '지구과학이 약합니다. 도표 · 그림 중심 지구과학 교재로 현상을 그림으로 설명해 보게 하세요.'),
    _Q('lit', '과학 문제에 나오는 그래프의 가로축(독립변인)과 세로축(종속변인)의 관계를 분석하나요?', '', ind: '그래프 변인 분석', intent: '중등 과학 시험 핵심 그래프 분석',
        rx: '그래프 분석이 약합니다. 오투 과학 · 체크체크 과학으로 그래프 문제를 집중해서 푸세요.'),
    _Q('base', '탐구 실험 문제에서 조작 변인, 통제 변인, 종속 변인을 정확히 구분해 내나요?', '', ind: '변인 통제 이해', intent: '탐구 문제 변인 통제',
        rx: '변인 구분이 헷갈립니다. 탐구 문제 집중 교재로 실험마다 변인을 표로 정리하게 하세요.'),
    _Q('base', '과학 공식을 이용한 계산 문제에서 단위(N, m/s, J, V, A 등)를 틀리지 않고 올바르게 쓰나요?', '', ind: '단위 · 계산 정교성', intent: '과학 계산 정교성',
        rx: '단위 실수가 많습니다. 계산 문제마다 답에 단위를 쓰는 규칙을 정하고, 계산 클리닉 교재로 보완하세요.'),
    _Q('base', '중등 내신 서술형 문제에서 과학 원리를 단어 조건에 맞춰 서술할 수 있나요?', '', ind: '과학 서술형 표현', intent: '중등 과학 서술형 대비',
        rx: '서술형에서 감점됩니다. 내신 서술형 특화 문제집으로 원리를 조건 단어에 맞춰 쓰는 연습을 하세요.'),
    _Q('base', '오투(O2)나 완자 중등 과학의 대표 유형 문제를 문제없이 풀어내나요?', '', ind: '대표 유형 소화력', up: true, intent: '표준 문제집 소화 능력'),
    _Q('base', '주 2회 이상 과학 개념을 복습하고 문제를 푸는 꾸준한 학습 습관이 있나요?', '', ind: '과학 학습 루틴', up: true, intent: '중등 과학 학습 지속성',
        rx: '과학 복습 루틴이 없습니다. 단기 완결 교재로 주 2회 복습 일정을 학사 타임라인에 넣으세요.'),
  ],
  'high': [
    _Q('base', '통합과학 / 물화생지Ⅰ의 핵심 개념을 체계적으로 요약·정리할 수 있나요?', '', ind: '고등 과학 개념 체계화', intent: '고등 과학 기본 개념 체계화',
        rx: '개념 정리가 약합니다. 완자 · 개념완성 같은 고등 개념서로 단원마다 한 쪽 요약을 만들게 하세요.'),
    _Q('base', '물리학Ⅰ(역학, 전자기학, 파동)의 고난도 역학적 에너지/전자기 유도 계산을 풀어내나요?', '', ind: '물리Ⅰ 킬러 계산', intent: '물리Ⅰ 킬러 파트 해결',
        rx: '물리Ⅰ 고난도 계산이 약합니다. 물리Ⅰ 특화 기출서로 같은 유형을 반복해 풀이 틀을 익히세요.'),
    _Q('base', '화학Ⅰ(몰농도, 화학양론, 중화반응, 산화환원)의 고난도 양적 관계 계산을 해결하나요?', '', ind: '화학Ⅰ 양적 관계', intent: '화학Ⅰ 킬러 양적 관계',
        rx: '화학Ⅰ 양적 관계가 약합니다. 화학Ⅰ 기출 킬러 특강집으로 표를 그려 푸는 연습을 하세요.'),
    _Q('lit', '생명과학Ⅰ(유전, 신경 자극 전달, 근수축)의 고난도 유전 확률 추론 문제를 푸나요?', '', ind: '생명과학Ⅰ 유전 추론', intent: '생명과학Ⅰ 킬러 유전 추론',
        rx: '유전 추론이 약합니다. 생명과학Ⅰ 유전 특화 문제집으로 가계도 문제를 하루 2문제씩 푸세요.'),
    _Q('lit', '지구과학Ⅰ(고지자기, 천체 관측, 기후 변화)의 복잡한 시각 자료를 정확히 해석하나요?', '', ind: '지구과학Ⅰ 자료 분석', intent: '지구과학Ⅰ 고난도 자료 해석',
        rx: '지구과학Ⅰ 자료 해석이 약합니다. 지구과학Ⅰ 기출 분석서로 자료 유형별로 모아 푸세요.'),
    _Q('lit', '수능/모의고사 기출문제(3점 킬러 문항)의 자료를 해석하고 출제 의도를 파악하나요?', '', ind: '수능 3점 기출 분석', up: true, intent: '수능 과탐 3점 문항 해결'),
    _Q('base', '제한된 시험 시간(30분 20문항) 동안 시간 부족 없이 검산까지 마치나요?', '', ind: '실전 시간 배분', intent: '탐구 영역 실전 타임어택',
        rx: '시험 시간이 부족합니다. 실전 모의고사 훈련서로 30분 타이머를 맞추고 푸세요.'),
    _Q('base', '내신 과학 시험에서 고난도 객관식 및 조건 제시형 서술형을 감점 없이 푸나요?', '', ind: '내신 고난도 정교성', intent: '고등 내신 1~2등급 정교성',
        rx: '내신 고난도에서 감점됩니다. 1등급 만들기 같은 내신 고난도 문제집으로 시험 3주 전부터 대비하세요.'),
    _Q('base', '틀린 문제를 오답할 때, 내가 잘못 판단한 개념이나 자료 해석 오류를 노트에 적어 보나요?', '', ind: '과학 오답 분석', intent: '오답 원인 분석 습관',
        rx: '오답 분석이 약합니다. 자습형 기출 분석서로 틀린 문제마다 잘못 판단한 부분을 노트에 적게 하세요.'),
    _Q('base', '주 3회 이상 고등 과학 개념 복습과 기출 문제를 시간에 맞춰 풀고 있나요?', '', ind: '고등 과학 루틴', up: true, intent: '고등 과학 학습 지속성',
        rx: '과학 루틴이 없습니다. 유형별 기출서로 주 3회, 시간을 재고 푸는 일정을 학사 타임라인에 넣으세요.'),
  ],
};

const List<_Q> _kSocCommonQ = [
  _Q('base', "사회 개념이나 용어를 배울 때, 단순 암기가 아니라 '왜 그런 현상이 발생하는지' 원리를 이해하려고 하나요?", '', ind: '사회 현상 원리 이해', intent: '단순 암기와 원리 이해 중심 학습 구분',
      rx: '외우기만 합니다. 원리와 배경 설명이 풍부한 기본 개념서로 "왜?"를 한 줄씩 적게 하세요.'),
  _Q('lit', '지도, 그래프, 통계표, 뉴스 기사, 사료 등 다양한 자료를 보고 핵심 정보를 올바르게 해석하나요?', '', ind: '자료 분석력 (지도 · 표 · 그래프)', intent: '사회 시험의 핵심인 자료 해석',
      rx: '자료 해석이 약합니다. 도표 · 지도 · 자료 집중 분석 교재로 자료의 제목 · 단위 · 범례부터 읽는 습관을 들이세요.'),
  _Q('lit', '사회적 이슈를 마주했을 때 다양한 관점(지리적, 역사적, 사회적, 윤리적)에서 생각해 보나요?', '', ind: '통합적 사고력', up: true, intent: '4가지 통합적 관점 형성',
      rx: '한 가지 관점으로만 봅니다. 유형별 기본서로 하나의 사건을 지리 · 역사 · 사회 · 윤리 관점으로 나눠 정리해 보세요.'),
  _Q('base', '배운 사회 개념이나 법/경제 원리를 나 자신이나 다른 사람에게 쉬운 말로 설명할 수 있나요?', '', ind: '메타인지 · 개념 완전 학습', up: true, intent: '사회 개념의 완전 학습',
      rx: '설명하지 못하는 개념이 있습니다. 하루 한 개념을 부모님께 설명하는 "선생님 놀이"를 권합니다.'),
  _Q('base', "틀린 문제를 오답 정리할 때, '어떤 개념을 착각했는지' 또는 '자료의 어느 부분을 놓쳤는지' 분석하나요?", '', ind: '사회 오답 피드백', intent: '함정 회피 및 개념 보완 습관',
      rx: '오답 분석이 약합니다. [오답 개념 클리닉] 노트로 착각한 개념과 놓친 자료를 한 줄씩 적게 하세요.'),
  _Q('base', '시사 뉴스나 신문, 일상생활의 사회 현상에 호기심을 갖고 교과서 내용과 연결지어 생각하나요?', '', ind: '사회 흥미 · 시사 연계', intent: '사회 과목 흥미와 친숙도',
      rx: '사회 흥미가 낮습니다. 생활 밀착형 교양 사회책이나 어린이 · 청소년 신문을 주 1회 함께 읽어 주세요.'),
];

const Map<String, List<_Q>> _kSocQ = {
  'elem': [
    _Q('base', '우리가 사는 지역의 위치, 지형, 기후적 특징과 주민들의 생활 모습을 연결 지어 이해하나요?', '', ind: '지리 기초', intent: '초등 지리 기초 개념',
        rx: '지리 기초가 약합니다. 지도 · 지리 특화 초등 사회 교재로 우리 지역 지도부터 함께 보세요.'),
    _Q('base', '우리나라의 역사적 인물이나 주요 역사 사건(고려, 조선 등)의 순서와 의미를 알고 있나요?', '', ind: '역사 시대 흐름', intent: '초등 역사 흐름 파악',
        rx: '역사 흐름이 약합니다. 스토리텔링 중심 초등 역사책으로 시대 순서를 연표로 그려 보게 하세요.'),
    _Q('base', '촌락과 도시의 특징, 인구 변화, 산업의 발전 모습을 구분할 수 있나요?', '', ind: '인문지리 · 사회 변화', intent: '초등 인문지리 및 사회 변화',
        rx: '사회 변화 개념이 약합니다. 교과서 사회 개념서로 촌락과 도시를 표로 비교해 정리하세요.'),
    _Q('base', '헌법, 국민의 권리와 의무, 법의 역할 등 기초적인 법과 정치 개념을 이해하나요?', '', ind: '법과 정치 기초', intent: '초등 정치 · 법 기본 개념',
        rx: '법과 정치 개념이 어렵습니다. 쉽게 풀이된 법 · 정치 교재로 생활 속 예와 함께 익히게 하세요.'),
    _Q('base', '생산, 소비, 선택의 문제, 합리적 소비 등 기초적인 경제 개념을 이해하나요?', '', ind: '경제 기초', intent: '초등 경제 기초',
        rx: '경제 개념이 약합니다. 실생활 경제 개념서로 용돈 기입장을 함께 써 보세요.'),
    _Q('lit', '지도표시(방위, 기호, 축척, 등고선)를 읽고 지도가 나타내는 뜻을 파악할 수 있나요?', '', ind: '지도 읽기', intent: '초등 사회의 핵심인 지도 읽기',
        rx: '지도 읽기가 약합니다. 지도 읽기 특강 교재로 방위 · 기호 · 축척을 하나씩 익히세요.'),
    _Q('base', '사회 교과서에 나오는 핵심 어휘(예: 인권, 민주주의, 무역, 문화재 등)의 뜻을 아나요?', '', ind: '사회 어휘력', intent: '초등 사회 교과 어휘',
        rx: '사회 어휘가 약합니다. 초등 사회 어휘 교재로 단원마다 핵심 낱말을 정리하게 하세요.'),
    _Q('base', '다양한 문화(외국 문화, 다문화)를 편견 없이 존중하고 이해하는 태도를 갖고 있나요?', '', ind: '문화 이해 · 다문화 수용', intent: '다문화 수용성 및 가치관',
        rx: '다른 문화 이해가 부족합니다. 세계 문화 연계 책으로 여러 나라의 생활을 함께 알아보세요.'),
    _Q('base', '사회 단원 평가나 문제집을 풀 때 문제를 잘 읽고 정답을 문제없이 찾아내나요?', '', ind: '사회 문제 해결력', up: true, intent: '초등 사회 단원 성취도'),
    _Q('base', '일주일에 사회/역사 관련 학습 만화나 어린이 사회책을 찾아 읽나요?', '', ind: '사회 독서 자발성', up: true, intent: '사회 배경지식 자발적 습득',
        rx: '사회 독서가 적습니다. 기본 교재와 함께 역사 · 사회 학습 만화를 주 1권 읽게 하세요.'),
  ],
  'mid': [
    _Q('base', '지형, 기후, 자연재해 등 자연환경이 인간 생활에 미치는 영향을 지리적 원리로 설명하나요?', '', ind: '자연지리', intent: '중등 자연지리 원리',
        rx: '자연지리가 약합니다. 중등 지리 특화 개념서로 지형 · 기후를 그림과 함께 정리하세요.'),
    _Q('lit', '자원, 산업, 도시화, 인구 이동 등 인문지리 현상의 원인과 결과 관계를 분석하나요?', '', ind: '인문지리 분석', intent: '중등 인문지리 관계 분석',
        rx: '인문지리 분석이 약합니다. 완자 · 오투 사회 지리 파트로 원인 → 결과를 화살표로 정리하세요.'),
    _Q('base', '헌법의 기본 원리, 기본권, 국가 기관(국회, 정부, 법원)의 역할과 견제 관계를 아나요?', '', ind: '정치 · 법 구조', intent: '중등 정치와 법 체계',
        rx: '정치 · 법 구조가 약합니다. 정치 · 법 특화 문제집으로 국가 기관 관계도를 그려 보게 하세요.'),
    _Q('base', '수요와 공급의 법칙, 시장 가격 형성, 기회비용, 자산 관리 등 경제 원리를 풀 수 있나요?', '', ind: '경제 원리 · 계산', intent: '중등 경제 원리 적용',
        rx: '경제 원리가 약합니다. 경제 파트 문제집으로 수요 · 공급 그래프를 직접 그려 푸는 연습을 하세요.'),
    _Q('base', '사회화, 사회 집단, 사회 불평등 현상, 문화 변동 등 사회·문화 개념을 구분하나요?', '', ind: '사회 · 문화 현상', intent: '중등 사회 · 문화 현상 구분',
        rx: '사회 · 문화 개념이 헷갈립니다. 사회 · 문화 개념서로 비슷한 개념을 표로 비교하세요.'),
    _Q('base', '한국사/세계사의 주요 사건을 연표와 함께 시대별 흐름(원인-경과-결과)으로 파악하나요?', '', ind: '역사 인과 · 흐름', intent: '중등 역사 인과관계 및 흐름',
        rx: '역사 흐름이 약합니다. 중학 역사 연표 · 지도 교재로 사건마다 원인 → 경과 → 결과를 정리하세요.'),
    _Q('lit', '사회 시험에서 지도, 통계 그래프, 사료 자료가 결합된 문제를 분석하여 답을 찾나요?', '', ind: '고난도 자료 해석', intent: '중등 내신 고난도 자료 문제',
        rx: '복합 자료 문제가 약합니다. 체크체크 사회 · 완자 사회의 자료 문제를 모아 집중해서 푸세요.'),
    _Q('base', '사회 문제의 핵심 용어(예: 스태그플레이션, 입법권, 기후 변동 등)의 뜻을 정확히 아나요?', '', ind: '중등 사회 어휘력', intent: '중등 사회 필수 어휘',
        rx: '사회 용어가 약합니다. 중학 사회 용어집으로 단원마다 핵심 용어를 자기 말로 설명해 보게 하세요.'),
    _Q('base', '중등 내신 서술형 문제에서 사회 현상의 원인과 결과를 문장 조건에 맞춰 쓰나요?', '', ind: '사회 서술형 표현', intent: '중등 사회 서술형',
        rx: '서술형에서 감점됩니다. 내신 서술형 대비집으로 원인 · 결과를 조건에 맞춰 쓰는 연습을 하세요.'),
    _Q('base', '주 2회 이상 사회/역사 개념을 복습하고 문제집을 풀어내는 루틴이 형성되어 있나요?', '', ind: '사회 학습 루틴', up: true, intent: '중등 사회 학습 지속성',
        rx: '사회 복습 루틴이 없습니다. 단기 완결 교재로 주 2회 복습 일정을 학사 타임라인에 넣으세요.'),
  ],
  'high': [
    _Q('lit', '공간적(지리), 시간적(역사), 사회적(사회/법), 윤리적(윤리) 관점을 통합하여 지문을 읽나요?', '', ind: '통합사회 4대 관점', intent: '통합사회 4가지 관점 적용',
        rx: '통합적 관점이 약합니다. 완자 통합사회 같은 개념 기본서로 단원마다 4가지 관점을 정리하세요.'),
    _Q('base', '자연환경과 인간 생활(기후, 지형), 생태계와 환경 문제, 지속 가능한 발전 원리를 아나요?', '', ind: '지리 · 생태 파트', intent: '통합사회 지리 · 환경 파트',
        rx: '지리 · 환경 파트가 약합니다. 지리 영역 자료 분석 교재로 기후 그래프 · 지도 문제를 집중 연습하세요.'),
    _Q('base', '인권의 역사적 발전 과정, 현대 사회의 인권 침해 사례, 헌법상 기본권 보장 체계를 아나요?', '', ind: '인권 · 헌법 체계', intent: '통합사회 인권과 법 파트',
        rx: '인권 · 헌법 파트가 약합니다. 법과 사회 영역 문제집으로 기본권 체계를 표로 정리하세요.'),
    _Q('base', '시장 경제의 발전, 자산 관리와 금융, 무역의 확대와 경제적 불평등 문제를 계산/분석하나요?', '', ind: '경제 계산 · 분석', intent: '통합사회 경제 킬러 파트',
        rx: '경제 파트가 약합니다. 경제 파트 고난도 문제로 자산 관리 · 무역 계산 문제를 반복 연습하세요.'),
    _Q('base', '정의의 의미(분배적 정의, 교정적 정의), 동서양 윤리 사상가들의 정의관을 구분하나요?', '', ind: '윤리 사상가 비교', intent: '롤스 · 노직 · 왈처 등 정의론',
        rx: '사상가 구분이 약합니다. 사상가 비교 교재로 사상가마다 핵심 주장을 한 줄씩 표로 정리하세요.'),
    _Q('base', '문화 다양성, 문화 상대주의와 보편 윤리, 대중문화와 글로벌화 문제를 분석하나요?', '', ind: '문화 파트 관점 구분', intent: '통합사회 문화 단원 관점 구분',
        rx: '문화 단원 관점 구분이 약합니다. 대표 유형서로 문화 상대주의 · 보편 윤리 문제를 모아 푸세요.'),
    _Q('lit', '고등 내신/수능형 복합 자료(지도+통계+사상가 제시문)가 결합된 고난도 문항을 풀어내나요?', '', ind: '복합 자료 분석', up: true, intent: '통합사회 고난도 1등급 문항'),
    _Q('base', "고등 내신 시험에서 변형된 선지의 '말장난'이나 세부 개념 함정을 놓치지 않고 찾아내나요?", '', ind: '선지 정교성', intent: '선지 함정 회피',
        rx: '선지 함정에 자주 걸립니다. 오답 선지 분석 교재로 틀린 선지의 함정 부분에 표시하는 연습을 하세요.'),
    _Q('base', "틀린 문제를 오답할 때, '잘못 고른 선지'가 왜 틀렸는지 지문과 교과서에서 확인하나요?", '', ind: '오답 원인 분석', intent: '오답 원인 분석 습관',
        rx: '오답 확인이 약합니다. 해설이 정교한 기출서로 틀린 선지마다 교과서 근거를 찾아 적게 하세요.'),
    _Q('base', '주 2~3회 이상 통합사회 개념을 복습하고, 기출/내신 문제를 시간에 맞춰 푸나요?', '', ind: '통합사회 학습 루틴', up: true, intent: '통합사회 학습 지속성',
        rx: '통합사회 루틴이 없습니다. 유형서로 주 2~3회 복습 · 문제 풀이 일정을 학사 타임라인에 넣으세요.'),
  ],
};

/// 과목 → (공통 6문항, 학부별 10문항). 통합사회 → 사회, 통합과학 → 과학 세트
const Map<String, List<_Q>> _kDivCommon = {
  '국어': _kKorCommonQ, '수학': _kMathCommonQ, '영어': _kEngCommonQ,
  '과학': _kSciCommonQ, '통합과학': _kSciCommonQ, '사회': _kSocCommonQ, '통합사회': _kSocCommonQ,
};
const Map<String, Map<String, List<_Q>>> _kDivSets = {
  '국어': _kKorQ, '수학': _kMathQ, '영어': _kEngQ,
  '과학': _kSciQ, '통합과학': _kSciQ, '사회': _kSocQ, '통합사회': _kSocQ,
};

/// 과목별 진단 세트(공통 6 + 학부별 10)가 있는 과목인지 — 국어 · 수학 · 영어 · 과학 · 사회 · 통합과학 · 통합사회
bool _hasDivSet(String subject) => _kDivSets.containsKey(subject);

/// 진단 공통 질문 (세트가 있는 과목은 그 과목 공통 6문항, 그 밖은 전교과 공통)
List<_Q> _commonQsFor(String subject) => _kDivCommon[subject] ?? _kCommonQ;

/// 진단 교과 질문 (세트가 있는 과목은 초등부 · 중등부 · 고등부 10문항, 그 밖의 과목은 기존 5문항)
List<_Q> _subjQsFor(String subject, String div) {
  final Map<String, List<_Q>>? m = _kDivSets[subject];
  if (m == null) return _subjectQs(subject);
  return m[div] ?? m['mid']!;
}

/// 질문 글 (영어 문장이 없는 질문은 어느 언어에서나 한국어)
String _qText(_Q q) => (_lang() == 'KO' || q.en.isEmpty) ? q.ko : q.en;

/// 진단 결과 (자녀 · 과목별로 폰에 저장). answers: 'c0'~'c5'(공통) · 's0'~(과목) → 0/1/2 (원래 응답)
class _Diag {
  final int score;
  final bool estimated;
  final bool ahead;
  final bool reading;
  final Map<String, int> answers;
  final String date; // yyyy-MM-dd
  final String qdiv; // 🆕 [영어] 어느 학부 문항으로 진단했는지 ('elem' · 'mid' · 'high', 영어가 아니면 '')
  final bool hasPre; // 🆕 선행 문항이 있었는지 (영어는 없음 → 선행 조건 없이 판정)
  final int boost; // 🆕 상향 문항 결과 (1 = 개념 · 기본 단계를 한 단계 올림)
  const _Diag(this.score, this.estimated, this.ahead, this.reading,
      {this.answers = const {}, this.date = '', this.qdiv = '', this.hasPre = true, this.boost = 0});

  String get level {
    final String b = diagnoseLevel(score, ahead, reading);
    if (boost <= 0 || b == 'skilled' || b == 'advanced') return b;
    return b == 'concept' ? 'basic' : 'skilled';
  }

  bool get hasReport => answers.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'score': score, 'est': estimated, 'ahead': ahead, 'reading': reading, 'answers': answers, 'date': date,
    'qdiv': qdiv, 'hasPre': hasPre, 'boost': boost,
  };

  static _Diag? fromJson(Map<String, dynamic> m) {
    final num? s = m['score'] as num?;
    if (s == null) return null;
    final Map<String, int> a = {};
    final dynamic raw = m['answers'];
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is num) a['$k'] = v.toInt();
      });
    }
    return _Diag(s.toInt(), m['est'] == true, m['ahead'] == true, m['reading'] == true,
        answers: a,
        date: (m['date'] as String?) ?? '',
        qdiv: (m['qdiv'] as String?) ?? '',
        hasPre: m['hasPre'] != false,
        boost: (m['boost'] as num?)?.toInt() ?? 0);
  }
}

/// 응답 → 진단 결과 계산 (reverse 문항은 거꾸로)
_Diag _computeDiag(List<_Q> common, List<_Q> subj, List<int> ans, int? typedScore, {String qdiv = ''}) {
  final List<_Q> all = [...common, ...subj];
  int sum = 0, preSum = 0, preMax = 0, litSum = 0, litMax = 0, upYes = 0;
  final Map<String, int> raw = {};
  for (int i = 0; i < all.length; i++) {
    final int a = ans[i];
    raw[i < common.length ? 'c$i' : 's${i - common.length}'] = a;
    final int v = all[i].reverse ? 2 - a : a;
    sum += v;
    if (all[i].up && a == 2) upYes++;
    if (all[i].tag == 'pre') {
      preSum += v;
      preMax += 2;
    } else if (all[i].tag == 'lit') {
      litSum += v;
      litMax += 2;
    }
  }
  // 🆕 선행 문항이 없는 과목(영어)은 선행 조건 없이 판정
  final bool ahead = preMax == 0 ? true : preSum / preMax >= 0.75;
  final bool reading = litMax > 0 && litSum / litMax >= 0.7;
  final int score = typedScore == null ? (40 + 60 * sum / (2 * all.length)).round() : typedScore.clamp(0, 100).toInt();
  final DateTime n = DateTime.now();
  final String date = '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  return _Diag(score, typedScore == null, ahead, reading,
      answers: raw, date: date, qdiv: qdiv, hasPre: preMax > 0, boost: upYes >= 2 ? 1 : 0);
}

// ============================================================================
// 진단 리포트용 지표 이름 · 평가 · 처방 (한글 / 그 밖의 언어는 영어)
// ============================================================================
const Map<String, List<String>> _kInd = {
  'review': ['일일 복습 습관', 'Daily review habit'],
  'selfDirected': ['자기주도성 (과제 완수)', 'Self-direction'],
  'reading': ['독해력 · 문제 이해', 'Reading comprehension'],
  'metacog': ['메타인지 (설명 능력)', 'Metacognition'],
  'errorMgmt': ['오답 관리', 'Error review'],
  'focus': ['학습 집중도', 'Focus'],
  'mBasic': ['기본 개념 도달', 'Basic concepts'],
  'mCalc': ['연산 정확도', 'Calculation accuracy'],
  'ahead': ['선행 학습', 'Studying ahead'],
  'mPrinciple': ['원리 이해', 'Understanding principles'],
  'mModeling': ['식 세우기 (문장제)', 'Word problems to equations'],
  'mVisual': ['도형 · 시각 직관', 'Visual & geometric intuition'],
  'grit': ['끈기 (과제 집착력)', 'Persistence'],
  'mPattern': ['유형 해결력', 'Standard problem types'],
  'challenge': ['심화 도전 의지', 'Drive for challenge'],
  'subjBase': ['과목 기본 실력', 'Subject basics'],
  // 🆕 영어 지표 (원장님 '평가 항목')
  'eVocabDepth': ['어휘 학습 깊이 (소리 · 예문)', 'Depth of vocabulary study'],
  'eContext': ['문맥 유추력', 'Guessing from context'],
  'eTask': ['문제 조건 파악', 'Grasping question conditions'],
  'eMeta': ['메타인지 (문법 · 구문 설명)', 'Metacognition (explaining grammar)'],
  'eError': ['영어 오답 관리', 'English error review'],
  'eFocus': ['영어 몰입도 · 집중', 'Focus in English study'],
  'ePhonics': ['파닉스 (소리-문자)', 'Phonics'],
  'eVocab': ['기초 어휘량', 'Basic vocabulary'],
  'eFluency': ['읽기 유창성', 'Reading fluency'],
  'eGist': ['대의 파악', 'Main idea'],
  'eStructure': ['문장 구조 인지 (주어 · 동사)', 'Sentence structure'],
  'eListen': ['기초 청해력', 'Basic listening'],
  'eWrite': ['기초 쓰기 표현', 'Basic writing'],
  'eInterest': ['영어 흥미도', 'Interest in English'],
  'eSpelling': ['철자 정확도', 'Spelling accuracy'],
  'eExposure': ['영어 노출 습관', 'English exposure habit'],
  'emVocab': ['중등 어휘력', 'Middle-school vocabulary'],
  'emSyntax': ['기초 구문 (문장 구조)', 'Basic syntax'],
  'emGrammar': ['내신 문법 적용력', 'School grammar'],
  'emChunk': ['직독직해 (끊어 읽기)', 'Chunk reading'],
  'emTopic': ['주제 · 중심 내용 파악', 'Finding the topic'],
  'emListen': ['중등 실전 듣기', 'Listening tests'],
  'emWriting': ['서술형 영작 (조건)', 'Conditional writing'],
  'emGrit': ['독해 지구력', 'Reading persistence'],
  'emFeedback': ['어법 오답 교정력', 'Grammar error correction'],
  'emRoutine': ['독해 루틴', 'Reading routine'],
  'ehVocab': ['수능 어휘력 (다의어 · 유의어)', 'CSAT vocabulary'],
  'ehSyntax': ['고난도 구문 분석', 'Complex syntax'],
  'ehGrammar': ['어법 출제 포인트', 'Tested grammar points'],
  'ehSpeed': ['독해 속도 · 시간 배분', 'Reading speed'],
  'ehLogic': ['글의 논리 구조 파악', 'Logical structure'],
  'ehKiller': ['킬러 유형 추론 (빈칸 · 순서 · 삽입)', 'Killer question types'],
  'ehListen': ['수능 듣기 정밀도', 'CSAT listening accuracy'],
  'ehWriting': ['서술형 영작 정교성', 'Written test accuracy'],
  'ehFeedback': ['오답 독해 분석', 'Reading error analysis'],
  'ehRoutine': ['실전 훈련 루틴', 'Timed practice routine'],
};

bool get _ko => _lang() == 'KO';
String _kr(String ko, String en) => _ko ? ko : en;
String _indName(String k) => _kr(_kInd[k]?[0] ?? k, _kInd[k]?[1] ?? k);

/// 지표 한 줄 (리포트용)
class _IndRow {
  final String key;
  final List<int> qNums; // 화면 문항 번호 (1부터)
  final double value; // 0~2 (reverse 반영)
  final bool common; // 공통(학습 체력) / 과목
  const _IndRow(this.key, this.qNums, this.value, this.common);

  /// 2 = 우수 / 1 = 보통 / 0 = 보완 필요
  int get grade => value >= 1.5 ? 2 : (value >= 0.75 ? 1 : 0);
}

List<_IndRow> _indRows(_Diag d, List<_Q> common, List<_Q> subj) {
  final List<_Q> all = [...common, ...subj];
  final Map<String, List<int>> nums = {};
  final Map<String, List<int>> vals = {};
  final Map<String, bool> isCommon = {};
  for (int i = 0; i < all.length; i++) {
    final String id = i < common.length ? 'c$i' : 's${i - common.length}';
    final int? a = d.answers[id];
    if (a == null) continue;
    final String k = all[i].indicator;
    nums.putIfAbsent(k, () => []).add(i + 1);
    vals.putIfAbsent(k, () => []).add(all[i].reverse ? 2 - a : a);
    isCommon.putIfAbsent(k, () => i < common.length);
  }
  return [
    for (final String k in nums.keys)
      _IndRow(k, nums[k]!, vals[k]!.reduce((a, b) => a + b) / vals[k]!.length, isCommon[k]!),
  ];
}

/// 종합 처방 문장
List<String> _prescriptions(_Diag d, List<_IndRow> rows, String subject, [List<_Q> common = const [], List<_Q> subj = const []]) {
  final Map<String, int> g = {for (final _IndRow r in rows) r.key: r.grade};
  int? at(String k) => g[k];
  final String lv = d.level;
  final List<String> p = [];
  // 🆕 [영어 2026-10-14] 문항별 처방 (원장님 'AI/리포트 활용') — 보완 필요(아니다)일 때
  final List<_Q> allQ = [...common, ...subj];
  for (int i = 0; i < allQ.length; i++) {
    final _Q q = allQ[i];
    if (q.rx.isEmpty) continue;
    final int? a = d.answers[i < common.length ? 'c$i' : 's${i - common.length}'];
    if (a == null) continue;
    final int v = q.reverse ? 2 - a : a;
    if (v == 0) p.add(_kr(q.rx, q.rxEn.isEmpty ? q.rx : q.rxEn));
  }
  if (at('errorMgmt') == 0) {
    p.add(_kr('오답 정리 습관이 약합니다. 교재와 함께 [오답 클리닉 노트]를 쓰세요. (틀린 문제 → 틀린 이유 한 줄 → 3일 뒤 다시 풀기)',
        'Weak error review. Keep an error clinic notebook: wrong problem → one-line reason → re-solve in 3 days.'));
  }
  if (at('focus') == 0) {
    p.add(_kr('공부 흐름이 자주 끊깁니다. 스마트폰은 다른 방에 두고 [학사 타임라인 → 포모도로 시간표]로 공부하세요. '
        '방법: ① 학사 타임라인을 열고 ② 포모도로 시간표를 고른 뒤 ③ 25분 집중 → 5분 휴식을 한 묶음으로 반복하고 ④ 4묶음마다 15~20분 길게 쉽니다. '
        '25분 포모도로는 22분 이상 공부하면 보너스별도 받아요.',
        'Study is often interrupted. Keep the phone in another room and use [Academic Timeline → Pomodoro timetable]: '
            '① open the Academic Timeline ② choose the Pomodoro timetable ③ repeat 25 min focus → 5 min break ④ take a 15–20 min break after every 4 rounds. '
            'Studying 22+ minutes in a 25-minute Pomodoro also earns bonus stars.'));
  }
  if (at('review') == 0) {
    p.add(_kr('배운 날 10분 복습이 가장 큰 약입니다. 잠들기 전 그날 배운 내용을 한 쪽으로 정리하게 해 주세요.',
        'A 10-minute review on the same day is the best medicine. Summarize the day\'s lesson on one page before bed.'));
  }
  if (at('metacog') == 0) {
    p.add(_kr('아는 것 같은 느낌과 설명할 수 있는 것은 다릅니다. 하루 한 개념을 부모님께 설명하는 "선생님 놀이"를 권합니다.',
        'Feeling you know is not the same as being able to explain. Try "teacher time": explain one concept to a parent each day.'));
  }
  if (at('selfDirected') == 0) {
    p.add(_kr('과제를 끝까지 하는 힘이 필요합니다. 하루 목표를 작게 쪼개고, 끝내면 응원별로 칭찬해 주세요.',
        'Build follow-through: split daily goals into small pieces and praise with cheer stars when done.'));
  }
  if (at('reading') == 0 || at('mModeling') == 0) {
    p.add(_kr('긴 지문 · 문장제에서 막힙니다. 문제의 조건에 밑줄, 구하는 것에 동그라미를 치는 습관을 만드세요.',
        'Long texts and word problems are a hurdle. Underline the conditions and circle what is asked.'));
  }
  if (subject == '수학') {
    if (at('mBasic') == 0) {
      p.add(_kr('교과서 예제부터 혼자 풀 수 있어야 합니다. 개념서 예제를 해설 없이 다시 푸는 연습이 먼저입니다.',
          'First, solve textbook examples alone. Re-solve concept-book examples without the explanation.'));
    }
    if (at('mCalc') == 0) {
      p.add(_kr('계산 실수로 점수를 잃고 있습니다. 하루 10분 연산 연습과 검산(답을 거꾸로 대입) 습관을 붙여 주세요.',
          'Calculation slips cost points. Add 10 minutes of daily arithmetic and always check answers by substitution.'));
    }
    if (at('mPrinciple') == 0) {
      p.add(_kr('공식을 외우기만 하는 경향이 있습니다. 개념서의 "왜 그런지" 설명을 읽고 직접 유도해 보게 하세요.',
          'Tends to memorize formulas. Read the "why" in the concept book and derive formulas by hand.'));
    }
    if (at('mVisual') == 0) {
      p.add(_kr('도형 · 그래프 단원은 직접 그리고, 오리고, 접어 보며 공부하면 크게 좋아집니다.',
          'For shapes and graphs, draw, cut and fold by hand — it helps a lot.'));
    }
    if (at('grit') == 0) {
      p.add(_kr('모르는 문제에 금방 답지를 봅니다. "답지 보기 전 15분 고민" 규칙을 앱 타이머로 지켜 보세요.',
          'Opens the answer key too quickly. Use the app timer for a "15 minutes before the answer key" rule.'));
    }
    if (at('mPattern') == 0 && (lv == 'skilled' || lv == 'advanced')) {
      p.add(_kr('반복 유형이 아직 손에 익지 않았습니다. 심화보다 유형서(RPM · 쎈 B)를 한 번 더 돌리는 것이 먼저입니다.',
          'Standard types are not yet solid. Do another round of RPM / Ssen B before advanced books.'));
    }
    if (lv == 'skilled' && at('challenge') == 2 && at('grit') == 2) {
      p.add(_kr('도전 의지와 끈기가 좋습니다. 쎈 C단계 · 일품으로 심화의 문을 두드려 보세요.',
          'Great drive and persistence. Knock on the advanced door with Ssen C and Ilpum.'));
    }
  }
  if (at('ahead') == 0 && d.score >= 80) {
    p.add(_kr('실력에 비해 선행이 늦습니다. 방학을 이용해 다음 학기 개념서 1회독을 권합니다.',
        'Studying ahead lags behind ability. Use the vacation to finish next term\'s concept book once.'));
  }
  if (p.isEmpty) {
    p.add(_kr('전반적으로 고르게 잘하고 있습니다. 지금 단계 교재를 꾸준히 이어 가세요.',
        'Well balanced overall. Keep going steadily with the books for this level.'));
  }
  return p;
}

/// 입체 분석 한 문장
String _headline(_Diag d, List<_IndRow> rows) {
  final List<String> good = [for (final _IndRow r in rows) if (r.grade == 2 && r.key != 'ahead') _indName(r.key)];
  final List<String> weak = [for (final _IndRow r in rows) if (r.grade == 0 && r.key != 'ahead') _indName(r.key)];
  final String sc = '${d.score}';
  if (d.score < 90 && good.isNotEmpty) {
    final String g = good.take(2).map((e) => "'$e'").join(_kr('와 ', ' and '));
    return _kr('점수는 $sc점이지만 $g 지표가 우수해 발전 가능성이 큽니다.', 'The score is $sc, but strong $g show great potential.');
  }
  if (d.score >= 90 && weak.isNotEmpty) {
    final String w = weak.take(2).map((e) => "'$e'").join(_kr(', ', ', '));
    return _kr('점수는 $sc점으로 높지만, $w 부분을 보완하면 더 단단해집니다.', 'A high score of $sc — strengthening $w will make it even more solid.');
  }
  if (good.isEmpty) {
    return _kr('기초 습관부터 하나씩 잡아 가면 충분히 올라갈 수 있습니다.', 'Build the basic habits one by one and the score will follow.');
  }
  return _kr('점수 $sc점, 지금 단계에서 차근차근 실력을 쌓아 갈 시기입니다.', 'Score $sc — time to build skills steadily at this level.');
}

// ============================================================================
// 교재 자료 (서버 textbooks)
// ============================================================================
class Textbook {
  final String id;
  final String subject; // 교과 한글 (수학 · 영어 …)
  final List<String> grades;
  final List<String> levels;
  final String type;
  final String title;
  final String publisher;
  final String why;
  final String howTo;
  final String daily;
  final int weeks;
  final int order; // 푸는 순서
  final bool active;

  const Textbook({
    required this.id,
    required this.subject,
    required this.grades,
    required this.levels,
    required this.type,
    required this.title,
    required this.publisher,
    required this.why,
    required this.howTo,
    required this.daily,
    required this.weeks,
    required this.order,
    required this.active,
  });

  factory Textbook.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final Map<String, dynamic> m = d.data() ?? {};
    List<String> ls(String k) => ((m[k] as List?) ?? []).map((e) => e.toString()).toList();
    return Textbook(
      id: d.id,
      subject: (m['subject'] as String?) ?? '',
      grades: ls('grades'),
      levels: ls('levels'),
      type: (m['type'] as String?) ?? 'concept',
      title: (m['title'] as String?) ?? '',
      publisher: (m['publisher'] as String?) ?? '',
      why: (m['why'] as String?) ?? '',
      howTo: (m['howTo'] as String?) ?? '',
      daily: (m['daily'] as String?) ?? '',
      weeks: (m['weeks'] as num?)?.toInt() ?? 0,
      order: (m['order'] as num?)?.toInt() ?? 0,
      active: m['active'] != false,
    );
  }

  Map<String, dynamic> toMap() => {
    'subject': subject,
    'grades': grades,
    'levels': levels,
    'type': type,
    'title': title,
    'publisher': publisher,
    'why': why,
    'howTo': howTo,
    'daily': daily,
    'weeks': weeks,
    'order': order,
    'active': active,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class TextbookService {
  TextbookService._();
  static final CollectionReference<Map<String, dynamic>> _col = FirebaseFirestore.instance.collection('textbooks');

  /// 마지막 실패 이유 (규칙 문제인지 알려 주기용)
  static String lastError = '';
  static bool get lastWasRule => lastError.contains('permission-denied') || lastError.contains('PERMISSION_DENIED');

  static int _lvIdx(Textbook b) => b.levels.isEmpty ? 9 : b.levels.map(kTbLevels.indexOf).reduce((a, c) => a < c ? a : c);

  static Stream<List<Textbook>> watchAll() => _col.snapshots().map((s) {
    final List<Textbook> l = s.docs.map(Textbook.fromDoc).toList();
    l.sort((a, b) {
      final int c = kTbSubjects.indexOf(a.subject).compareTo(kTbSubjects.indexOf(b.subject));
      if (c != 0) return c;
      final int lv = _lvIdx(a).compareTo(_lvIdx(b));
      return lv != 0 ? lv : a.order.compareTo(b.order);
    });
    return l;
  });

  static Future<bool> save(Textbook b, {String? id}) async {
    try {
      if (id == null || id.isEmpty) {
        await _col.add({...b.toMap(), 'createdAt': FieldValue.serverTimestamp()});
      } else {
        await _col.doc(id).set(b.toMap(), SetOptions(merge: true));
      }
      lastError = '';
      return true;
    } catch (e) {
      lastError = e.toString();
      debugPrint('[Textbook] 저장 실패: $e');
      return false;
    }
  }

  static Future<bool> delete(String id) async {
    try {
      await _col.doc(id).delete();
      lastError = '';
      return true;
    } catch (e) {
      lastError = e.toString();
      debugPrint('[Textbook] 삭제 실패: $e');
      return false;
    }
  }

  /// 기본 교재 목록 (초 · 중 · 고 전 과목). 같은 학부 · 과목 · 이름이 이미 있으면 건너뜀
  /// 결과: 넣은 권수 / 실패면 -1
  /// ※ 예시 목록입니다. 원장님이 관리 화면에서 확인 · 수정해 주세요.
  /// 서버의 교재를 모두 지우고 기본 목록을 새로 넣음 (원장님 전용 · 확인 두 번)
  /// 결과: 넣은 권수 / 실패면 -1
  static Future<int> resetAll() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> cur = await _col.get();
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = cur.docs;
      for (int i = 0; i < docs.length; i += 400) {
        final WriteBatch b = FirebaseFirestore.instance.batch();
        for (final d in docs.sublist(i, (i + 400) > docs.length ? docs.length : i + 400)) {
          b.delete(d.reference);
        }
        await b.commit();
      }
    } catch (e) {
      lastError = e.toString();
      debugPrint('[Textbook] 전체 지우기 실패: $e');
      return -1;
    }
    return seedAll();
  }

  static Future<int> seedAll() async {
    const List<String> all = ['concept', 'basic', 'skilled', 'advanced'];
    const List<String> bs = ['concept', 'basic', 'skilled'];
    const List<String> sa = ['skilled', 'advanced'];
    const List<String> elem = ['초1', '초2', '초3', '초4', '초5', '초6'];
    const List<String> elem36 = ['초3', '초4', '초5', '초6'];
    const List<String> mid = ['중1', '중2', '중3'];
    const List<String> high = ['고1', '고2', '고3'];
    const List<String> high1 = ['고1'];
    final List<Textbook> list = [];
    void t(String subject, List<String> grades, List<String> levels, String type, int order, String title, String pub, String why, String how, [String daily = '', int weeks = 0]) {
      list.add(Textbook(
        id: '', subject: subject, grades: grades, levels: levels, type: type, title: title, publisher: pub,
        why: why, howTo: how, daily: daily, weeks: weeks, order: order, active: true,
      ));
    }

    // 교과서 중심 기본 3종 (자습서 → 평가문제집 → 학교 기출)
    void basic3(String subject, List<String> grades) {
      t(subject, grades, all, 'concept', 1, '$subject 교과서 자습서', '교과서 출판사별',
          '우리 학교 교과서와 똑같은 순서로 개념을 정리해 주어, 수업 내용을 가장 정확하게 복습할 수 있습니다.',
          '수업한 날 해당 쪽을 읽고 핵심 용어에 밑줄을 긋습니다. 모르는 부분은 다음 수업 전에 질문합니다.', '1단원', 0);
      t(subject, grades, all, 'pattern', 2, '$subject 교과서 평가문제집', '교과서 출판사별',
          '교과서 단원별 문제로 배운 내용을 바로 확인할 수 있습니다.',
          '자습서로 정리한 단원을 이어서 풀고, 틀린 문제는 교과서에서 근거를 찾아 표시합니다.', '1단원', 0);
      t(subject, grades, all, 'exam', 9, '학교 기출문제집 (내신 대비)', '학교별',
          '우리 학교 선생님의 출제 경향을 익히는 데 가장 좋습니다.',
          '시험 3주 전부터 실제 시험처럼 시간을 재고 풉니다.', '1회분', 3);
    }

    // ================= 초등부 =================
    // 수학 (원장님 교재 DB · 2026-10-13) — 단계: 개념 → 기본 → 실력 → 심화
    // 왜 이 교재인가요 = 특징 + 추천 이유 / 이렇게 공부하세요 = 주요 활용(어떤 학생) + 구체적 공부법
    // 푸는 순서 1~9 = 순서대로 풀 교재 / 10 이상 = 함께 고를 수 있는 다른 교재
    // 개념 → 개념 단계(concept) / 기본 → 기본 단계(basic) / 실력 → 실력 단계(skilled) / 심화 → 심화 단계(advanced)
    // [개념]
    t('수학', elem, ['concept'], 'concept', 1, '디딤돌 초등수학 원리', '디딤돌',
        '교과서 원리를 쉬운 문제와 익힘책 수준으로 차근차근 다져 주어, 수학이 약한 아이도 부담 없이 시작할 수 있습니다.',
        '진단점수 60점 미만 학생의 첫 개념서로 가장 무난합니다. 개념 설명을 소리 내어 읽고 예제를 혼자 풀어 본 뒤, 틀린 문제는 다음 날 다시 풉니다.', '3쪽', 8);
    t('수학', elem, ['concept'], 'concept', 10, '개념클릭 초등수학', '천재교육',
        '만화와 쉬운 그림 자료로 수학의 진입장벽을 낮춘 기초서라, 수학을 두려워하는 아이의 마음을 먼저 열어 줍니다.',
        '수학을 두려워하거나 기초 학력이 부족한 학생의 복습 · 선행용입니다. 만화로 개념을 먼저 읽고 바로 아래 문제를 푼 뒤, "왜 그런지" 부모님께 한 줄로 말해 보게 하세요.');
    t('수학', elem, ['concept'], 'concept', 11, '그림으로 개념 잡는 키 수학', '키출판사',
        '직관적인 그림과 시각 이미지로 수학 원리를 보여 주어, 글보다 그림으로 이해하는 아이에게 잘 맞습니다.',
        '글 읽기(독해력)가 부족하거나 셈 개념이 약한 초등 저 · 중학년에게 권합니다. 그림을 손가락으로 짚으며 설명하게 하고, 같은 그림을 공책에 직접 그려 봅니다.');
    t('수학', elem, ['concept'], 'concept', 14, '만점왕 수학', 'EBS',
        '교과서 흐름을 그대로 따라가며 개념과 기본 문제를 함께 익힐 수 있습니다.',
        '학교 진도에 맞춰 복습하고 싶은 학생에게 좋습니다. 그날 배운 단원을 바로 풀고, 틀린 문제는 개념 설명을 다시 읽은 뒤 풉니다.', '4쪽', 8);
    // [기본]
    t('수학', elem, ['concept', 'basic'], 'pattern', 2, '디딤돌 초등수학 기본', '디딤돌',
        '대한민국 대표 초등 기본서로, 교과서 유형과 기본 문제가 균형 있게 배치되어 학기 실력을 고르게 다집니다.',
        '진단점수 60~80점 학생의 표준 학기 주교재입니다. 학교 진도에 맞춰 풀고, 틀린 문제는 별표를 쳐 두었다가 주말에 별표 문제만 다시 풉니다.', '4쪽', 10);
    t('수학', elem, ['basic'], 'pattern', 12, '수학리더 기본', '천재교육',
        "'개념 - 복습 - 평가' 3단계 구성이라 예습과 복습을 한 권으로 끝낼 수 있습니다.",
        '스스로 공부하는 습관이 조금 약하고 단원평가 대비가 필요한 학생에게 좋습니다. 수업 전날 개념을 훑고, 수업한 날 복습 문제를 풀고, 단원이 끝나면 평가를 시간을 재고 풉니다.');
    t('수학', elem, ['basic'], 'pattern', 13, '큐브수학 개념 · 기본', '동아출판',
        '매칭북(서술형 · 복습)으로 유형 진단과 반복 학습이 쉬워, 기본기를 빈틈없이 채워 줍니다.',
        '학기 중 학교 진도에 맞춰 기본기를 완벽히 다지고 싶을 때 씁니다. 본책을 푼 날 매칭북의 같은 단원을 이어서 풀어 확인합니다.');
    // [실력]
    t('수학', elem, ['skilled'], 'skill', 1, '디딤돌 초등수학 기본+응용', '디딤돌',
        '기본 개념과 서술형 · 응용 유형을 한 권으로 이어 주는 베스트셀러라, 실력 단계로 넘어가는 디딤돌이 됩니다.',
        '진단점수 70~80점대 학생 중 실력 단계로 빠르게 넘어가고 싶은 학생에게 좋습니다. 기본 문제는 빠르게, 응용 문제는 한 문제에 10분 이상 생각하고, 서술형은 풀이를 문장으로 씁니다.', '4쪽', 10);
    t('수학', elem, ['skilled'], 'skill', 2, '초등 쎈 수학', '좋은책신사고',
        'A(기본) - B(유형) - C(응용 · 심화) 단계로 문항이 이어지는 대표 유형서라, 풀이 양과 속도를 함께 키웁니다.',
        '문제 풀이 양을 늘리고 해결 속도와 정확도를 올려야 하는 학생에게 좋습니다. A단계는 빠르게, B단계는 꼼꼼히 풀고, 틀린 번호는 오답 노트에 옮깁니다.', '15문제', 10);
    t('수학', elem, ['skilled'], 'skill', 10, '수학리더 응용 · 실력', '천재교육',
        '상위권 도약을 위한 응용 문제 해결력과 각종 경시 유형을 담아, 기본과 심화 사이를 이어 줍니다.',
        '기본 단계는 완벽하나 심화서로 가기 전 다리(브릿지)가 필요한 학생에게 좋습니다. 하루 정해진 쪽수만 풀되, 틀린 문제는 해설을 보기 전에 한 번 더 도전합니다.');
    t('수학', elem, ['skilled'], 'skill', 11, '응용 해결의 법칙', '천재교육',
        '기본을 넘어 응용 문제로 넘어가는 다리 역할을 합니다.',
        '기본서를 끝내고 응용력을 키우고 싶은 학생에게 좋습니다. 한 문제를 10분 이상 생각해 보고, 막히면 힌트만 보고 다시 풉니다.', '8문제', 10);
    // [심화]
    t('수학', elem, ['advanced'], 'advanced', 1, '최상위수학 S', '디딤돌',
        "최상위수학보다 접근하기 쉬운 '느낌으로 이해하는 심화서'라, 처음 심화를 만나는 아이도 자신감을 잃지 않습니다.",
        '진단점수 80~90점 미만 학생의 첫 심화 입문용입니다. 한 문제에 15분 이상 고민하고, 못 푼 문제는 다음 날 다시 도전한 뒤 해설을 봅니다.', '5문제', 10);
    t('수학', elem, ['advanced'], 'advanced', 2, '최상위 수학', '디딤돌',
        '초등 최상위권의 필수 코스로, 높은 수준의 문제와 경시 경향을 담아 사고력을 깊게 다집니다.',
        '진단점수 90점 이상이고 수학 끈기가 높게 나온 학생에게 권합니다. 최상위수학 S를 끝낸 뒤 시작하고, 풀이를 끝까지 노트에 씁니다.', '4문제', 12);
    t('수학', elem, ['advanced'], 'advanced', 10, '최강 TOT', '천재교육',
        '사고력 · 창의력과 최고난도 융합 유형 문제 중심이라, 극상위권의 생각의 폭을 넓혀 줍니다.',
        '영재교육원 · 경시대회 준비와 극상위권 사고력 확장용입니다. 한 문제를 여러 방법으로 풀어 보고, 가장 짧은 풀이를 찾아 설명하게 하세요.');
    t('수학', elem, ['advanced'], 'advanced', 11, '생각수학 1031 최상급', '시매쓰',
        '과정 중심 서술형 문제와 고난도 사고력 문항이 많아, 풀이 과정을 조리 있게 쓰는 힘을 길러 줍니다.',
        '서술형 표현력과 문제 해결 과정을 끈질기게 다듬고 싶을 때 씁니다. 답보다 풀이 과정을 문장으로 쓰고, 부모님이 읽어서 이해되는지 확인해 주세요.');
    t('수학', elem, ['advanced'], 'advanced', 12, '최고수준 수학', '천재교육',
        '사고력과 응용력을 기르는 심화 문제집입니다.',
        '심화서를 한 권 더 풀고 싶은 학생에게 좋습니다. 못 푼 문제는 바로 해설을 보지 말고 다음 날 다시 도전합니다.', '5문제', 12);
    // 영어 (원장님 영어 교재 DB · 2026-10-14) — 제목 앞 [문법] [독해] [듣기] [쓰기] = 4대 영역
    // 푸는 순서: 1 문법 · 2 독해 · 3 듣기 · 4 쓰기 (단계마다 영역별 주교재 1권) / 10 이상 = 다른 선택지
    // [문법]
    t('영어', elem, ['concept'], 'concept', 1, '[문법] Grammar Space Starter / Beginner', 'NE능률',
        '초등 문법의 대명사로, 시각적 이미지와 표가 잘 되어 있어 영어 문법을 처음 만나는 아이도 부담 없이 시작할 수 있습니다.',
        '영어 문법을 처음 접하는 초등 3~4학년의 첫 문법서입니다. 한 단원을 이틀에 나눠 표를 소리 내어 읽고, 예문을 공책에 2번씩 따라 씁니다.', '2쪽', 10);
    t('영어', elem, ['concept', 'basic'], 'concept', 11, '[문법] My First Grammar / My Next Grammar', 'e-future',
        '원서형 문법 교재의 베스트셀러로, 나선형 구조라 같은 문법을 반복해 만나며 기초 개념이 자연스럽게 잡힙니다.',
        '영어로 된 설명에 거부감이 없는 학생, 원서 수업을 하는 학원생에게 좋습니다. First → Next 순서로 같은 문법을 두 번 익힙니다.');
    t('영어', elem36, ['basic', 'skilled'], 'pattern', 1, '[문법] 초등영문법 3800제', '마더텅',
        '풍부한 문제량으로 문법 개념을 정교하게 다지고 실수를 줄여 주는 한국형 문법 연습서입니다.',
        '문법 설명은 알지만 문제에서 자주 틀리는 학생에게 좋습니다. 개념서로 배운 단원을 바로 이어 풀고, 틀린 문제는 규칙을 한 줄로 적어 둡니다.', '2쪽', 10);
    t('영어', elem36, ['basic', 'skilled'], 'pattern', 12, '[문법] 초등 영문법 문법이 쓰기다', '키출판사',
        '배운 문법을 바로 문장 쓰기로 연결해, 문법을 "아는 것"에서 "쓰는 것"으로 바꿔 줍니다.',
        '문법 문제는 맞히는데 문장을 못 만드는 학생에게 좋습니다. 단원마다 배운 문법으로 내 문장을 3개씩 만들어 씁니다.');
    t('영어', elem36, ['skilled', 'advanced'], 'skill', 1, '[문법] 초등 영어 구문이 독해다 (Starter · 1 · 2)', '키출판사',
        '문법을 독해 문장의 구조(구문)로 바로 연결해, 긴 문장을 읽는 힘을 길러 줍니다.',
        '문법을 끝내고 독해로 넘어가는 초등 5~6학년에게 좋습니다. 문장마다 주어 · 동사에 표시하고 의미 단위로 끊어 해석합니다.');
    // [독해]
    t('영어', elem, all, 'concept', 2, '[독해] Bricks Reading (50 / 80 / 100 / 150)', '사회평론',
        '초등 영어 독해의 절대강자로, 단어 수별로 세분화되어 있어 단계별 성장이 명확합니다.',
        '아이 수준에 맞는 단어 수부터 시작합니다(개념 50 → 기본 80 · 100 → 실력 150). 하루 1지문, 음원 따라 읽기 → 문제 → 모르는 단어 단어장 정리 순서로 공부합니다.', '1지문', 10);
    t('영어', elem, ['concept', 'basic'], 'concept', 12, '[독해] 기적의 영어리딩', '길벗스쿨',
        '혼자서도 따라갈 수 있게 구성되어, 영어 읽기 습관을 들이기 좋은 자기주도 학습용 독해서입니다.',
        '혼자 공부하는 습관을 들이고 싶은 학생에게 좋습니다. 문장을 의미 단위로 끊어 / 표시를 하고 앞에서부터 해석하는 연습을 합니다.');
    t('영어', elem36, ['basic'], 'pattern', 13, '[독해] READING FUTURE', '웅진컴퍼스 (Compass Publishing)',
        '최신 주제와 생동감 있는 사진 · 이미지로 학생들의 흥미를 잘 이끌어 내는 독해서입니다.',
        '영어 독해에 흥미가 낮은 학생의 동기 부여용입니다. 사진을 보고 내용을 먼저 짐작한 뒤 읽게 하면 집중력이 올라갑니다.');
    t('영어', elem36, ['basic', 'skilled'], 'pattern', 14, '[독해] 주니어 리딩튜터', 'NE능률',
        '중학 리딩튜터로 이어지는 초등 고학년용 독해서로, 흥미로운 소재와 단계별 구성이 장점입니다.',
        '초등 5~6학년이 중학 독해로 넘어가기 전 다리 역할을 합니다. 지문마다 주제문을 찾아 밑줄을 긋습니다.');
    t('영어', elem36, ['skilled', 'advanced'], 'skill', 2, '[독해] Subject Link Starter / Subject Link', 'NE능률',
        '과학 · 사회 · 예술 등 배경지식을 연결한 독해서라, 설명문 읽는 힘과 배경지식을 함께 키웁니다.',
        '이야기 글은 잘 읽지만 설명문에 약한 초등 고학년에게 좋습니다. 지문을 읽은 뒤 핵심 내용을 한국어로 두 줄 요약하게 하세요.');
    // [듣기]
    t('영어', elem, ['concept', 'basic'], 'concept', 3, '[듣기] Listen Up Starter / Listen Up', 'NE능률',
        '초등 리스닝의 표준으로, 파닉스 연계부터 받아쓰기(Dictation)까지 체계적으로 구성되어 있습니다.',
        '듣기를 처음 시작하는 학생의 주교재입니다. 하루 1과, 듣고 → 문제 → 받아쓰기 → 따라 말하기(쉐도잉) 순서로 합니다.', '1과', 10);
    t('영어', elem36, ['basic', 'skilled'], 'pattern', 14, '[듣기] Bricks Listening Beginner / Intermediate', '사회평론',
        '독해 교재와 연계성이 뛰어나고, 실전 듣기 유형과 짧은 받아쓰기가 잘 갖춰져 있습니다.',
        'Bricks Reading을 쓰는 학생에게 특히 좋습니다. 틀린 문항은 음원을 0.8배속으로 다시 듣고 받아씁니다.');
    t('영어', elem36, ['concept', 'basic'], 'concept', 15, '[듣기] 초등 영어듣기평가 완벽대비', 'EBS',
        '학교 영어듣기평가 유형에 맞춘 교재로, 무료 강의와 함께 공부할 수 있습니다.',
        '학교 듣기평가를 앞둔 학생에게 좋습니다. 평가 3주 전부터 하루 1회씩 풀고, 틀린 문항은 받아쓰기로 다시 듣습니다.');
    t('영어', elem36, ['skilled', 'advanced'], 'skill', 3, '[듣기] 초집중 초등 고학년 집중 영어듣기', '키출판사',
        '초등 고학년의 실전 듣기를 집중 훈련하는 교재로, 들어야 할 핵심을 잡는 힘을 길러 줍니다.',
        '단어는 아는데 문장으로 들으면 놓치는 학생에게 좋습니다. 1배속으로 풀고, 틀린 문장은 3번 따라 말합니다.');
    // [쓰기]
    t('영어', elem, ['concept'], 'concept', 4, '[쓰기] My First Writing', 'e-future',
        '그림과 단어 카드를 활용해 초등 저학년도 부담 없이 첫 문장을 쓸 수 있게 돕는 기초서입니다.',
        '영어 쓰기를 처음 하는 초등 저학년용입니다. 하루 한 문장, 그림을 보고 단어 카드로 문장을 만든 뒤 소리 내어 읽습니다.');
    t('영어', elem36, ['basic'], 'pattern', 4, '[쓰기] Writing Tutor Starter / Basic', 'NE능률',
        '문장 완성부터 시작해 한 단락(Paragraph) 완성까지 자연스럽게 이끌어 줍니다.',
        '문장 쓰기에서 단락 쓰기로 넘어가는 학생에게 좋습니다. 주 2회 한 단락씩 쓰고 부모님이나 선생님께 고쳐 받습니다.');
    t('영어', elem36, ['skilled', 'advanced'], 'skill', 4, '[쓰기] Write Right', 'e-future',
        '초등 라이팅의 베스트셀러로, 그래픽 오거나이저(생각 정리표)로 글의 구조를 잡고 쓰게 합니다.',
        '문장은 쓰지만 글로 이어 쓰기 어려운 학생에게 좋습니다. 생각 정리표를 먼저 채운 뒤 글을 씁니다.');

    // ================= 중등부 =================
    // 수학 : 원장님 기준 (1~3번 순서) + 원장님 교재 DB (10번 이상 = 다른 선택지)
    // [개념]
    t('수학', mid, ['concept'], 'concept', 1, '개념원리', '개념원리',
        '개념 정리가 깔끔하고 예제 - 유형 연결이 가장 직관적인 표준 개념서라, 혼자서도 원리를 이해하기 좋습니다.',
        '중등 수학을 처음 시작하는 대다수 학생의 입문서입니다. 개념을 읽고 예제를 먼저 혼자 풀어 본 뒤 해설과 비교하세요. 틀린 예제는 표시해 두고 다음 날 다시 풉니다.', '4쪽', 8);
    t('수학', mid, ['concept'], 'concept', 2, '이유있는 수학', '',
        '왜 그렇게 되는지 이유부터 설명해 주어, 개념이 약한 학생이 원리를 납득하며 따라가기 좋습니다.',
        '개념원리와 같은 단원을 나란히 보며, 이해가 안 되는 부분을 이 책의 설명으로 보충합니다.', '4쪽', 8);
    t('수학', mid, ['concept'], 'concept', 10, '개념플러스유형 라이트', '비상교육',
        '개념북과 리뷰북(1:1 유형 맞춤)으로 구성되어, 배운 개념을 바로 복습하기에 가장 알맞습니다.',
        '개념은 이해했는데 문제에 적용이 잘 안되는 60점 미만 학생에게 좋습니다. 개념북 한 단원을 끝낸 날 리뷰북의 같은 유형을 바로 풀어 확인합니다.');
    t('수학', mid, ['concept'], 'concept', 11, '숨마쿰라우데 개념기본서', '이룸이앤비',
        '줄글 형태의 친절하고 자세한 설명과 수학 원리 풀이가 뛰어나, 깊이 있게 혼자 공부하기 좋습니다.',
        '독해력이 좋고 원리를 깊이 독학하고 싶은 학생에게 권합니다. 설명을 읽은 뒤 책을 덮고 핵심 원리를 공책에 다시 써 보세요.');
    // [기본]
    t('수학', mid, ['concept', 'basic'], 'pattern', 3, 'RPM', '개념원리',
        '개념원리와 문항 구조가 완벽히 이어지는 표준 유형 문제집(집중 문제집)이라, 배운 개념을 유형별로 반복해 손에 익힙니다.',
        '개념원리로 개념을 배운 뒤 필수 유형을 다지는 주교재입니다. 유형별 대표 문제를 먼저 풀고, 막히면 개념서의 해당 개념으로 돌아갑니다. 틀린 번호는 오답 노트에 옮깁니다.', '15문제', 8);
    t('수학', mid, ['basic'], 'pattern', 4, '라이트쎈', '좋은책신사고',
        '쎈 B단계 난이도를 잘게 나누어 부담 없이 유형을 연습할 수 있습니다.',
        '연산 실수가 많거나 계산 연습이 더 필요한 학생에게 좋습니다. 하루 정해진 문제를 시간을 재고 풀고, 계산 실수는 빨간 펜으로 따로 표시해 같은 실수를 줄입니다.');
    t('수학', mid, ['basic'], 'pattern', 13, '체크체크 수학', '천재교육',
        '진도 교재와 개념 기본서의 중간 성격으로 학교 내신 대비에 특화되어 있습니다.',
        '짧은 기간에 내신 기본 유형을 마스터하고 싶을 때 씁니다. 시험 4주 전부터 시험 범위를 하루 한 소단원씩 풉니다.');
    // [실력]
    t('수학', mid, ['skilled'], 'skill', 1, '쎈 수학 (B단계 집중)', '좋은책신사고',
        '모든 내신 출제 유형을 총망라한 중등 수학 판매 1위 문제집으로, B단계가 학교 시험 실력의 중심입니다.',
        '내신 A등급(90점 이상) 진입을 위한 필수 실력 문제집입니다. A단계는 빠르게 확인, B단계는 꼼꼼히 끝까지, C단계는 여유가 생기면 도전합니다. 문장제는 조건에 밑줄을 긋고 읽는 습관을 들이세요.', '20문제', 10);
    t('수학', mid, ['skilled'], 'skill', 10, '개념플러스유형 파워', '비상교육',
        '라이트보다 유형 난이도가 높아 내신 실력 · 응용 문항을 집중 공략할 수 있습니다.',
        '내신 80점대 학생이 상위권으로 도약하기 위한 응용 교재입니다. 쎈 B단계와 같은 단원을 나란히 풀며, 틀린 유형만 골라 다시 풉니다.');
    t('수학', mid, ['skilled'], 'skill', 11, '우공비Q 발전편', '좋은책신사고',
        '난이도 높은 유형과 서술형 특화 문제를 전면에 배치했습니다.',
        '서술형 평가에서 자주 감점되는 학생의 집중 보완용입니다. 서술형은 채점 기준처럼 단계별로 풀이를 쓰고, 빠진 단계를 해설과 비교합니다.');
    // [심화]
    t('수학', mid, ['advanced'], 'advanced', 1, '최고수준 수학', '천재교육',
        '심화의 첫 단계로, 응용력과 사고력을 차근차근 끌어올립니다.',
        '심화를 처음 시작하는 학생의 첫 교재입니다. 한 문제에 15분 이상 생각해 보고, 못 푼 문제는 다음 날 다시 도전한 뒤 해설을 봅니다.', '6문제', 10);
    t('수학', mid, ['advanced'], 'advanced', 2, '블랙라벨', '진학사',
        '신유형 · 변별력 문제와 강남 8학군 기출을 바탕으로 한 최상위 내신서라, 최상위권을 굳혀 줍니다.',
        '학교 시험 100점을 목표로 하는 전교권 학생에게 권합니다. 하루 적은 문제를 깊게 풀고, 풀이 과정을 노트에 끝까지 쓰는 습관을 들이세요.', '5문제', 12);
    t('수학', mid, ['advanced'], 'advanced', 3, 'A급 수학', '에이급열린수학',
        'C - B - A 단계 중 A단계 난이도가 매우 높은 전통의 최고 심화서로, 최상위 마무리 단계입니다.',
        '과제 집착력(끈기)이 매우 높고 최고 난이도에 도전하는 최상위권에게 권합니다. 블랙라벨을 끝낸 뒤 시작하고, 막힌 문제는 일주일 뒤 다시 풉니다.', '4문제', 12);
    t('수학', mid, ['advanced'], 'advanced', 10, '일품 중등수학', '좋은책신사고',
        '내신 고득점 핵심 문항과 준심화(상위 10%) 위주의 깔끔한 구성입니다.',
        '블랙라벨 · A급에 들어가기 전에 거쳐 가는 준심화 교재입니다. 한 문제 15분 고민 규칙을 지키고, 해설은 마지막에 봅니다.');
    t('수학', mid, ['advanced'], 'advanced', 11, '최상위 수학 (중등)', '디딤돌',
        '중등 개념을 넓혀 고등 수학 개념과 연결되는 고난도 문항을 담았습니다.',
        '특목고 · 자사고 준비생과 고등 선행 전 심화 완성용입니다. 고등 개념과 이어지는 문제는 표시해 두었다가 고등 선행 때 다시 봅니다.');
    // 국어
    // 영어 (원장님 영어 교재 DB · 2026-10-14) — 1·2 문법 · 3·4 독해 · 5 듣기 · 6 쓰기 · 9 기출 / 10 이상 = 다른 선택지
    // [문법]
    t('영어', mid, ['concept', 'basic', 'skilled'], 'concept', 1, '[문법] Grammar Zone 중학 (기초 / 기본 / 종합)', 'NE능률',
        '문법 원리 설명이 가장 명쾌하고 논리적이어서 중학 문법 개념을 정리하기에 가장 좋습니다.',
        '문법 개념서로 씁니다(개념 기초 → 기본 기본 → 실력 종합). 설명을 읽고 연습 문제를 풀며, 틀린 문법은 예문을 소리 내어 3번 읽습니다.', '1단원', 8);
    t('영어', mid, ['basic', 'skilled', 'advanced'], 'pattern', 2, '[문법] 중학영문법 3800제 (1 · 2 · 3학년)', '마더텅',
        '중등 내신 문법의 끝판왕으로, 압도적인 문항 수와 내신 기출 반영으로 학원가 필수 교재입니다.',
        '개념서로 배운 문법을 문제로 굳히는 주 문제집입니다. 단원별로 풀고, 시험 3주 전에는 틀린 문제만 다시 풉니다. 중간 · 기말 대비편도 함께 쓸 수 있습니다.', '2쪽', 10);
    t('영어', mid, ['basic'], 'pattern', 11, '[문법] 그래머 인사이드 (Grammar Inside 1~3)', 'NE능률',
        '깔끔한 편집과 알맞은 난이도로 수업용 부교재와 자습용으로 인기가 매우 높습니다.',
        '학년별 학교 진도에 맞춰 혼자 공부하기 좋습니다. 단원 끝 서술형 문제를 꼭 풀고 답을 소리 내어 읽습니다.');
    t('영어', mid, ['skilled'], 'skill', 12, '[문법] 중학 영문법 문법이 쓰기다 (1~3학년)', '키출판사',
        '문법을 서술형과 문장 쓰기로 바르게 연결하는 실전형 중등 문법서입니다.',
        '문법 문제는 맞히는데 서술형에서 활용을 못 하는 학생에게 좋습니다. 배운 문법으로 직접 문장을 만들어 씁니다.');
    // [독해]
    t('영어', mid, ['concept', 'basic', 'skilled'], 'concept', 4, '[독해] 리딩튜터 (Reading Tutor) 중학', 'NE능률',
        '재미있고 상식적인 최신 지문으로 독해 흥미와 실력을 함께 잡는 스테디셀러입니다.',
        '꾸준히 읽는 습관을 들이는 주 독해서입니다. 하루 1~2지문, 모르는 단어는 단어장에 적고 다음 날 복습합니다.', '2지문', 8);
    t('영어', mid, ['basic', 'skilled'], 'pattern', 3, '[독해] 주니어 천일문 (Basic / Complete)', '쎄듀',
        '구문 독해의 명가로, 문장 구조를 분석하고 끊어 읽는 힘을 길러 주는 대표 구문독해서입니다.',
        '문장이 길어지면 해석이 무너지는 학생에게 좋습니다. 하루 정해진 문장을 끊어 읽기 표시 → 해석 쓰기 → 해설 비교 순서로 합니다.', '20문장', 10);
    t('영어', mid, ['skilled'], 'skill', 13, '[독해] 빠른독해 바른독해 (빠바) 중학', 'NE능률',
        '핵심 구문을 중심으로 독해에 바로 적용하는 훈련을 시켜 주는 교재입니다.',
        '구문 공부를 마친 뒤 독해에 바로 적용해 보는 단계에 좋습니다. 지문마다 핵심 구문을 찾아 표시하고 해석합니다.');
    t('영어', mid, ['advanced'], 'advanced', 3, '[독해] Bricks Intensive Reading 1~3', '사회평론',
        '중등 상위권과 특목고 준비생을 위한 긴 지문 중심의 고난도 독해서입니다.',
        '리딩튜터가 쉬운 상위권 학생에게 권합니다. 시간을 재고 읽은 뒤 지문 구조(서론 · 본론 · 결론)를 표로 정리합니다.');
    // [듣기]
    t('영어', mid, ['concept', 'basic', 'skilled', 'advanced'], 'pattern', 5, '[듣기] 마더텅 중학영어듣기 (1 · 2 · 3학년)', '마더텅',
        '시 · 도 교육청 중학 영어듣기평가를 완벽히 대비하는 실전 모의고사 교재입니다.',
        '학교 영어듣기평가 4주 전부터 하루 1회씩 풉니다. 틀린 문항은 받아쓰기로 다시 듣고, 문장을 따라 말합니다.', '1회', 4);
    t('영어', mid, ['basic', 'skilled', 'advanced'], 'pattern', 14, '[듣기] 능률 중학영어 듣기 모의고사 22회 (Level 1~3)', 'NE능률',
        '2023 개정판 실전 듣기 모의고사로, 학년별 수준에 맞춰 듣기평가를 대비할 수 있습니다.',
        '마더텅과 함께 또는 대신 쓰기 좋습니다. 1회를 시간 재고 풀고, 틀린 유형만 골라 다시 듣습니다.');
    t('영어', mid, ['concept', 'basic'], 'concept', 15, '[듣기] 리스닝 튜터 (Listening Tutor) 중학', 'NE능률',
        '듣기 지문의 소재가 다양하고, 받아쓰기 훈련으로 세부 정보를 잡는 힘을 키워 줍니다.',
        '듣기 기초를 다지는 학생에게 좋습니다. 하루 1과, 받아쓰기 후 틀린 부분을 소리 내어 따라 말합니다.');
    t('영어', mid, ['concept', 'basic'], 'concept', 16, '[듣기] 중학영어듣기평가', 'EBS',
        '학교 영어듣기평가 대비용 EBS 교재로, 무료 강의와 함께 공부할 수 있습니다.',
        '혼자 듣기를 준비하는 학생에게 좋습니다. 강의를 보며 유형을 익힌 뒤 문제를 풉니다.');
    // [쓰기]
    t('영어', mid, ['concept', 'basic'], 'concept', 6, '[쓰기] Writing Wise (Level 1~3)', '좋은책신사고',
        '문법 포인트를 바탕으로 교과서 서술형 문장을 직접 완성하는 체계적인 쓰기 교재입니다.',
        '문법은 아는데 문장을 써 본 경험이 적은 학생에게 좋습니다. 하루 5문장씩 쓰고 틀린 문장은 다시 씁니다.');
    t('영어', mid, ['skilled'], 'skill', 6, '[쓰기] 중학 영문법 문법이 쓰기다 서술형 집중훈련', '키출판사',
        '중등 내신에서 가장 점수가 깎이기 쉬운 서술형 조건을 집중 훈련하는 교재입니다.',
        '서술형에서 자주 감점되는 학생에게 좋습니다. 조건(단어 수, 시제, 주어진 단어)에 동그라미를 친 뒤 답을 쓰고 채점 기준과 비교합니다.');
    t('영어', mid, ['basic', 'skilled'], 'pattern', 17, '[쓰기] 쓰기로 마스터하는 중학 서술형', 'NE능률',
        '학년별 서술형 유형을 쓰기 연습으로 익히는 내신 서술형 대비서입니다.',
        '서술형 문제를 처음 체계적으로 준비하는 학생에게 좋습니다. 하루 1유형씩 쓰고 모범 답안과 비교합니다.');
    t('영어', mid, ['advanced'], 'advanced', 6, '[쓰기] Write It! (1~3)', 'build&grow',
        '수필 · 편지 · 설명문 등 다양한 장르의 글쓰기를 단계별로 익히는 창의적 라이팅 교재입니다.',
        '수행평가 글쓰기나 영어 에세이를 준비하는 학생에게 좋습니다. 주 1편, 초안 → 고쳐 쓰기 → 완성본 순서로 씁니다.');
    // 과학 · 사회
    basic3('역사', mid);
    basic3('세계사', mid);
    basic3('기술/가정', mid);
    basic3('한문', mid);

    // ================= 고등부 =================
    // 수학 (공통수학1 · 2, 수학Ⅰ, 수학Ⅱ 등) — 원장님 교재 DB
    // [개념]
    t('수학', high, ['concept'], 'concept', 1, '개념원리 (고등)', '개념원리',
        '전국 고등학교와 학원에서 가장 널리 쓰이는 표준 고등 개념 입문서로, 고등 수학의 첫 단추를 탄탄히 잡아 줍니다.',
        '고등 수학의 기본 틀을 잡고 공식 유도를 빠르게 익힐 때 씁니다. 개념 → 예제 → 확인 문제 순서로, 하루 한 소단원씩 진행합니다.', '4쪽', 10);
    t('수학', high, ['concept'], 'concept', 10, '수학의 바이블', '이투스북',
        '개념 해설 - 예제 - 표준 - 다짐 문제 3단계 구성을 갖춘 친절한 개념서입니다.',
        '혼자 공부하거나 개념원리보다 해설이 자세한 교재를 원할 때 씁니다. 해설을 읽은 뒤 예제를 가리고 혼자 풀어 보세요.');
    t('수학', high, ['concept'], 'concept', 11, '풍산자', '풍산자',
        '명쾌하고 짧은 말투의 설명으로 고등 수학의 부담을 크게 줄인 교재입니다.',
        '수학을 포기할 위기의 학생이나, 개념을 빠르게 한 번 훑는 속진용입니다. 2~3주 안에 1회독을 끝내고 주교재로 넘어갑니다.');
    t('수학', high, ['concept'], 'concept', 12, '수학의 정석 (기본편)', '성지출판',
        '수식의 엄밀함과 원리 증명이 완벽하게 담긴 전통의 명저입니다.',
        '논리적 사고력이 좋고 끈기 있게 수식을 읽어 낼 수 있는 학생에게 권합니다. 증명을 따라 쓰며 읽고, 연습문제는 한 문제씩 끝까지 풉니다.');
    // [기본]
    t('수학', high, ['concept', 'basic'], 'pattern', 2, 'RPM (고등)', '개념원리',
        '개념원리와 연결되어 내신 기본 유형을 빠르게 점검할 수 있는 유형서입니다.',
        '내신 3~4등급대 학생의 기본 유형 반복 훈련용입니다. 유형별 대표 문제를 먼저 풀고, 막히면 개념원리로 돌아갑니다.', '15문제', 10);
    t('수학', high, ['basic'], 'pattern', 3, '라이트쎈 (고등)', '좋은책신사고',
        '고등 수학의 복잡한 연산과 필수 유형을 부담 없이 다지는 교재입니다.',
        '고등 진입 후 개념은 알지만 문제 적용에 시간이 오래 걸릴 때 씁니다. 시간을 재고 풀며 문제당 풀이 시간을 조금씩 줄여 갑니다.');
    t('수학', high, ['basic'], 'pattern', 14, '마플시너지', '마플',
        '내신에 나올 수 있는 모든 변형 문제를 담은 2,000여 문항의 유형 모음입니다.',
        '문제를 많이 풀며 유형을 몸에 익혀야 하는 내신 2~3등급 목표 학생에게 좋습니다. 하루 분량을 정해 꾸준히 풀고, 틀린 유형은 3회 반복합니다.');
    // [실력]
    t('수학', high, ['skilled'], 'skill', 1, '쎈 (고등 · B단계 집중)', '좋은책신사고',
        'B단계 유형과 C단계 응용 문항으로 내신 실력 향상의 표준 기준이 되는 교재입니다.',
        '내신 2~3등급 진입을 목표로 하는 학생의 필독서입니다. B단계를 중심으로 풀고, 틀린 문제는 3회 반복해 완전히 내 것으로 만듭니다.', '25문제', 12);
    t('수학', high, ['skilled'], 'skill', 2, '일품', '좋은책신사고',
        'C단계급 이상과 내신 변별력 문제만 모아 놓은 상위권 준심화서로, 중상위권을 상위권으로 이어 줍니다.',
        '쎈 B단계를 완벽히 끝낸 뒤 상위권으로 도약할 때 씁니다. 한 문제에 15분 이상 생각해 보고, 해설은 마지막에 봅니다.', '8문제', 10);
    t('수학', high, ['skilled'], 'skill', 10, '마플교과서', '마플',
        '개념서와 수능 · 모의고사 기출 응용서의 장점을 합친 대용량 교재입니다.',
        '내신과 수능 기초를 한 번에 잡고 싶은 상위권 학생에게 좋습니다. 개념을 읽은 날 같은 단원의 기출 응용 문제까지 이어서 풉니다.');
    t('수학', high, ['skilled'], 'skill', 11, '자이스토리 수학', '수경출판사',
        '수능 · 평가원 · 교육청 기출문제를 단원별, 난이도별로 담은 기출문제집입니다.',
        '고1~고3 내신과 수능 모의고사 실전 감각을 다질 때 씁니다. 단원을 끝낼 때마다 해당 기출을 풀고, 틀린 문제는 출제 의도를 한 줄로 적어 둡니다.');
    // [심화]
    t('수학', high, ['advanced'], 'advanced', 1, '블랙라벨 (고등)', '진학사',
        '특목고 · 자사고와 일반고 내신 1등급을 결정짓는 최고난도 문제집입니다.',
        '진단점수 90점 이상, 내신 1등급과 전교 1등을 목표로 하는 학생에게 권합니다. 하루 적은 문제를 깊게, 풀이를 끝까지 써서 풉니다.', '5문제', 12);
    t('수학', high, ['advanced'], 'advanced', 10, '수학의 정석 (실력편)', '성지출판',
        '높은 난이도의 증명과 논술형 최고난도 문항으로 구성된 심화서입니다.',
        '의약학계열 · 서울대 등 극상위권 목표 학생의 사고력 완성용입니다. 하루에 다 못 풀어도 괜찮으니, 스스로 끝까지 증명해 봅니다.');
    t('수학', high, ['advanced'], 'advanced', 11, '531 프로젝트 SG / HY', '이투스북',
        '얇은 두께로 최고난도 유형과 1등급 변별력 문항만 짧은 기간에 끝냅니다.',
        '시험 직전 고난도 문제만 빠르게 여러 번 풀어 보고 싶을 때 씁니다. 시험 2주 전 1회독, 1주 전 틀린 문제만 2회독합니다.');
    t('수학', high, ['advanced'], 'advanced', 12, 'Absolute (앱솔루트)', '메가스터디',
        '수능 킬러 문항과 내신 서술형 최고난도 변형 문제를 담았습니다.',
        '최고 수준의 수학적 사고력이 필요한 문항을 훈련할 때 씁니다. 실제 시험처럼 시간을 재고 풀고, 풀이 전략을 노트에 정리합니다.');
    t('수학', high, all, 'exam', 9, '마더텅 수능기출문제집 수학', '마더텅',
        '수능 · 평가원 · 교육청 기출문제를 단원별, 난이도별로 담은 기출문제집으로 실전 감각을 기릅니다.',
        '고1~고3 실전 감각 다지기에 좋습니다. 한 회를 시간 재고 풀고, 틀린 유형을 정리합니다.', '1회', 8);
    // 영어 (원장님 영어 교재 DB · 2026-10-14) — 1·2 문법 · 3·4 독해 · 5 듣기 · 6 쓰기 · 9 기출 / 10 이상 = 다른 선택지
    // [문법 · 어법]
    t('영어', high, ['concept', 'basic'], 'concept', 1, '[문법] Grammar Zone 기본편 / 종합편', 'NE능률',
        '고등 문법을 체계적으로 정리하는 대표 문법 개념서입니다.',
        '고등 문법을 처음부터 다시 정리해야 하는 학생에게 좋습니다(개념 기본편 → 기본 종합편). 한 단원씩 설명 → 문제 → 틀린 예문 소리 내어 읽기.', '1단원', 10);
    t('영어', high, ['basic', 'skilled', 'advanced'], 'pattern', 2, '[문법] 어법끝 (Start / ESSENTIAL / REASONING)', '쎄듀',
        '수능과 고등 내신 어법의 출제 포인트를 가장 정교하게 분류해 놓은 고등 어법 대표 교재입니다.',
        '어법 문제를 감으로 푸는 학생에게 좋습니다(기본 Start → 실력 ESSENTIAL → 심화 REASONING). 틀린 문제는 왜 틀렸는지 어법 포인트를 한 줄로 적습니다.', '1과', 8);
    t('영어', high, ['skilled', 'advanced'], 'skill', 11, '[문법] 마더텅 수능기출문제집 영어 어법 · 어휘', '마더텅',
        '수능 · 모의고사 기출 어법과 어휘 문제를 모아, 문제를 많이 풀며 출제 패턴을 익히기 좋습니다.',
        '어법 개념을 끝내고 문제로 굳히는 단계에 좋습니다. 하루 20문제, 틀린 패턴을 오답 노트에 모읍니다.');
    t('영어', high, ['advanced'], 'advanced', 12, '[문법] 블랙라벨 영어 내신 어법', '진학사',
        '고1~고3 내신 고난도 어법과 서술형 문제를 함께 담은 상위권 어법서입니다.',
        '내신 1등급을 노리는 학생의 마무리 어법서입니다. 시험 3주 전부터 단원별로 풀고, 서술형은 조건에 표시한 뒤 씁니다.');
    t('영어', high, ['basic', 'skilled'], 'pattern', 13, '[문법] 매3영 문장구조 구문독해', '키출판사',
        '매일 3단계로 문장 구조와 구문을 연습해, 실수를 줄이고 꾸준한 습관을 만드는 자습형 교재입니다.',
        '매일 조금씩 꾸준히 공부하는 습관을 들이는 학생에게 좋습니다. 하루 1회분을 시간을 재고 풀고 바로 채점합니다.');
    // [독해 · 구문]
    t('영어', high, all, 'concept', 3, '[독해] 천일문 (입문 / 기본 / 핵심 / 완성)', '쎄듀',
        '고등 구문 독해의 대표 교재로, 문장 해석의 원리를 알려 주는 필수 코스입니다.',
        '단계에 맞는 권을 고릅니다(개념 입문 → 기본 기본 → 실력 핵심 → 심화 완성). 하루 정해진 문장을 끊어 읽고 해석을 쓴 뒤, 주말에 한 주 분량을 복습합니다.', '20문장', 10);
    t('영어', high, ['concept', 'basic'], 'concept', 4, '[독해] EBS 올림포스 영어 · 영어독해의 기본', 'EBS',
        '고1~고2 내신과 학력평가 대비의 기본서로, 학교 부교재로 많이 쓰입니다.',
        '학교에서 부교재로 쓰면 내신 범위가 되므로 반드시 본문을 정리합니다. 지문마다 주제문에 밑줄을 긋습니다.');
    t('영어', high, ['basic', 'skilled'], 'pattern', 14, '[독해] 빠른독해 바른독해 (고등)', 'NE능률',
        '중학 빠바에서 이어지는 고등 구문 · 독해 연결 교재입니다.',
        '천일문 기본과 함께 쓰면 구문 → 독해 적용이 자연스럽게 이어집니다. 지문마다 핵심 구문을 찾아 해석합니다.');
    t('영어', high, ['skilled'], 'skill', 4, '[독해] 자이스토리 영어 독해 (기본 / 완성)', '수경출판사',
        '최신 수능 · 평가원 · 학평 기출문제를 해설과 함께 세밀하게 분석한 유형별 기출서입니다.',
        '유형별로 약점을 찾는 학생에게 좋습니다. 많이 틀리는 유형(빈칸, 순서 등)을 골라 집중해서 풉니다.');
    t('영어', high, ['skilled', 'advanced'], 'skill', 15, '[독해] EBS 수능특강 영어 · 영어독해연습', 'EBS',
        '수능 연계 교재로, 고3 학교 수업과 내신의 중심 교재입니다.',
        '고3은 지문 내용을 꼭 익혀 둡니다. 지문마다 주제 · 요지를 한 줄로 정리합니다.');
    t('영어', high, ['skilled', 'advanced'], 'skill', 16, '[독해] 마더텅 수능기출문제집 영어', '마더텅',
        '검은책으로 불리는 기출 문제집의 대명사로, 상세한 어휘 풀이와 직독직해 해설이 강점입니다.',
        '실전 감각을 기르는 단계입니다. 한 회를 시간을 재고 풀고, 해설의 직독직해로 틀린 지문을 다시 읽습니다.');
    t('영어', high, ['advanced'], 'advanced', 4, '[독해] 자이스토리 고난도 영어 독해 (1등급 독해)', '수경출판사',
        '빈칸추론, 순서배열, 문장삽입 등 킬러 문항을 집중 공략하는 최상위권 독해서입니다.',
        '2등급에서 1등급으로 올라가려는 학생에게 권합니다. 하루 3~5문항을 깊게 풀고, 정답 근거 문장에 표시합니다.');
    t('영어', high, ['advanced'], 'advanced', 17, '[독해] 매3영 빈순삽', '키출판사',
        '빈칸 · 순서 · 삽입 고난도 유형을 매일 3개씩 꾸준히 푸는 훈련서입니다.',
        '고난도 유형에서 시간이 부족한 학생에게 좋습니다. 매일 3문항을 시간을 재고 풀고, 근거 문장을 표시합니다.');
    // [듣기]
    t('영어', high, ['concept', 'basic'], 'concept', 5, '[듣기] EBS 수능특강 영어듣기', 'EBS',
        '수능 직접 연계와 평가원 출제 경향을 그대로 담은 고등 듣기의 필수 기본서입니다.',
        '수능 연계 듣기 대비용입니다. 하루 1강, 틀린 문항은 받아쓰기로 다시 듣습니다.');
    t('영어', high, ['skilled', 'advanced'], 'skill', 5, '[듣기] 마더텅 수능기출 영어듣기 모의고사', '마더텅',
        '1.2배속 · 1.4배속 음원으로 실전보다 빠르게 연습해 듣기 만점을 노리는 문제집입니다.',
        '듣기 만점을 노리는 학생에게 좋습니다. 1배속으로 풀고, 다시 1.2배속으로 들으며 받아씁니다.');
    t('영어', high, ['basic', 'skilled'], 'pattern', 18, '[듣기] 자이스토리 수능 영어 듣기 모의고사', '수경출판사',
        '연도별 · 유형별 기출을 반영하고 받아쓰기 노트가 연계되어 듣기 실수를 줄여 줍니다.',
        '듣기에서 1~2문항씩 자주 틀리는 학생에게 좋습니다. 받아쓰기 노트로 놓친 부분을 확인합니다.');
    // [쓰기 · 서술형]
    t('영어', high, ['basic', 'skilled'], 'pattern', 6, '[쓰기] 어법끝 서술형', '쎄듀',
        '어법을 서술형 답안 쓰기로 연결해, 고등 내신 서술형의 기본기를 잡아 줍니다.',
        '서술형 감점이 잦은 학생에게 좋습니다. 조건에 표시 → 답 쓰기 → 채점 기준 비교 순서로 합니다.');
    t('영어', high, ['skilled', 'advanced'], 'skill', 19, '[쓰기] RANK 77 고등 영어 서술형', '쎄듀',
        '고등 내신에 자주 나오는 서술형 유형을 출제 빈도 순으로 정리한 교재입니다.',
        '시험 직전 서술형을 빠르게 점검하고 싶을 때 씁니다. 자주 나오는 유형부터 순서대로 풉니다.');
    t('영어', high, ['advanced'], 'advanced', 6, '[쓰기] 해커스 고등 서술형 쓰기의 기술 (기본편 / 실력편)', '해커스',
        '조건 영작 · 요약문 · 어순 배열 등 고등 서술형 쓰기 기술을 단계별로 익히는 교재입니다.',
        '서술형으로 1등급이 갈리는 상위권 학생에게 권합니다. 매일 5문항씩 쓰고 틀린 문장은 통째로 외웁니다.');
    t('영어', high, all, 'exam', 9, '학교 기출문제 + 교과서 본문 암기', '학교별',
        '고등 내신 영어도 교과서와 부교재 본문이 핵심입니다.',
        '시험 3주 전부터 본문을 소리 내어 읽고, 빈칸 · 서술형으로 스스로 시험 봅니다.', '본문 1과', 3);
    basic3('역사', high);
    t('역사', high, sa, 'advanced', 3, '수능특강 한국사', 'EBS',
        '수능 한국사 출제 흐름에 맞춰 핵심을 정리합니다.',
        '시대 흐름표를 먼저 보고 단원을 공부합니다.', '1단원', 8);
    basic3('제2외국어', high);

    // ======================================================================
    // 🆕 [2026-10-14 11차] 국어 · 과학 · 사회 교재 다시 정리 (시중 판매 확인 · 현장 인기 교재)
    //  + 중등부 5과목(국 · 영 · 수 · 과 · 사) [교과서 평가문제집] + [학교 기출문제집(내신 대비)] 필수
    //  + 고등부 [수능 파이널] (고3 · N수생) — 국어 · 수학 · 영어 · 과탐 · 사탐
    // ======================================================================
    const List<String> high23 = ['고2', '고3'];
    const List<String> high3 = ['고3'];

    // 중등부 필수 2종 (5과목 모두)
    void midExam(String subject, String extra) {
      t(subject, mid, all, 'exam', 8, '[내신] $subject 교과서 평가문제집', '교과서 출판사별',
          '우리 학교 교과서와 같은 출판사의 평가문제집이라, 단원마다 학교 시험과 가장 비슷한 문제로 확인할 수 있습니다.',
          '학교 진도에 맞춰 단원이 끝날 때마다 풉니다. 서점에서 "학교 교과서 출판사 + 평가문제집"으로 고르세요.$extra', '1단원', 0);
      t(subject, mid, all, 'exam', 9, '[내신] 학교 기출문제집 (내신 대비 · 백발백중 등)', '에듀원 등',
          '우리 학교 · 같은 교과서의 실제 기출문제를 모은 내신 대비서로, 시험 직전 실전 감각을 잡아 줍니다.',
          '시험 3주 전부터 실제 시험처럼 시간을 재고 풉니다. 틀린 문제는 교과서에서 근거를 찾아 표시합니다.$extra', '1회분', 3);
    }

    // ---------------- 초등부 국어
    t('국어', elem36, ['concept', 'basic'], 'concept', 1, '한끝 초등 국어', '비상교육',
        '교과서 내용을 한 권으로 끝내도록 개념 정리와 문제를 담은, 현장에서 가장 많이 쓰는 초등 국어 기본서입니다.',
        '학교 진도에 맞춰 단원마다 개념을 읽고 문제를 풉니다. 모르는 낱말은 국어사전에서 찾아 적어 둡니다.', '4쪽', 8);
    t('국어', elem, ['concept', 'basic'], 'concept', 11, '만점왕 국어', 'EBS',
        '교과서 흐름을 그대로 따라가며 개념과 기본 문제를 함께 익힐 수 있어, 학교 수업 복습에 가장 좋습니다.',
        '학교 진도에 맞춰 복습하고 싶은 학생에게 좋습니다. 그날 배운 단원을 읽고 문제를 풀며, 모르는 낱말은 국어사전에서 찾습니다.', '4쪽', 8);
    t('국어', elem, ['concept'], 'concept', 2, '초등 어휘가 문해력이다', '어린이동아',
        '교과서 어휘를 한자 뜻과 함께 익혀, 글을 읽는 힘(문해력)의 바탕인 어휘력을 키워 줍니다.',
        '어휘가 약해 글 읽기가 어려운 학생에게 좋습니다. 하루 1과, 낱말마다 예문을 소리 내어 읽고 내 문장을 하나 만듭니다.', '1과', 8);
    t('국어', elem, ['basic', 'skilled'], 'pattern', 3, '뿌리깊은 초등국어 독해력', '마더텅',
        '짧은 글을 매일 읽고 문제를 풀며 문해력의 뿌리를 기르는 초등 독해 대표 교재입니다.',
        '독해 습관을 들이는 주교재입니다. 하루 1회분을 소리 내어 읽고 풀며, 문단마다 중심 문장에 밑줄을 긋습니다.', '1회분', 10);
    t('국어', elem, ['skilled', 'advanced'], 'skill', 4, '뿌리깊은 초등국어 독해력 도약편', '마더텅',
        '뿌리깊은 독해력보다 길고 깊은 글로, 고학년의 독해력을 한 단계 끌어올립니다.',
        '기본 독해력을 끝낸 학생에게 좋습니다. 글을 읽은 뒤 내용을 3문장으로 요약하고 문제를 풉니다.', '1회분', 10);
    t('국어', elem, ['skilled', 'advanced'], 'skill', 5, '기적의 독서 논술', '길벗스쿨',
        '읽고 생각하고 쓰는 힘을 함께 기르는 독서 논술 교재입니다.',
        '읽기는 되는데 생각을 글로 쓰기 어려운 학생에게 좋습니다. 글을 읽은 뒤 자기 생각을 3줄 이상 씁니다.', '1회분', 10);
    t('국어', elem, ['basic'], 'pattern', 10, '우등생 해법 국어', '천재교육',
        '교과서 단원별 문제와 단원 평가로 학교 시험을 대비하기 좋습니다.',
        '단원평가를 앞둔 학생에게 좋습니다. 단원이 끝나면 평가 문제를 풀고 틀린 부분을 교과서에서 다시 읽습니다.');

    // ---------------- 초등부 과학
    t('과학', elem36, ['concept', 'basic'], 'concept', 1, '만점왕 과학', 'EBS',
        '교과서 실험과 개념을 쉽게 정리해 주어, 수업 복습과 개념 다지기에 좋습니다.',
        '학교 진도에 맞춰 복습하는 학생에게 좋습니다. 수업한 날 해당 단원을 읽고 문제를 풉니다.', '4쪽', 8);
    t('과학', elem36, ['basic', 'skilled', 'advanced'], 'pattern', 2, '오투 초등 과학', '비상교육',
        '중등까지 이어지는 오투 과학의 초등판으로, 개념 설명과 실험 · 탐구 문제가 잘 짜여 있습니다.',
        '단원마다 개념을 읽고 실험 과정을 그림으로 정리한 뒤 문제를 풉니다. 틀린 문제는 실험 결과와 연결해 다시 봅니다.', '4쪽', 8);
    t('과학', elem36, ['basic', 'skilled'], 'pattern', 11, '우등생 해법 과학', '천재교육',
        '단원 평가 문제와 서술형까지 담아, 배운 내용을 확인하고 실력을 넓히기 좋습니다.',
        '단원이 끝나면 평가 문제를 풀고, 틀린 개념은 실험 과정과 함께 다시 정리합니다.', '1단원', 8);
    t('과학', elem, all, 'concept', 10, 'Why? 과학 학습만화 시리즈', '예림당',
        '재미있는 만화로 과학 원리를 쉽게 풀어 주어, 과학에 대한 흥미와 배경지식을 함께 키웁니다.',
        '과학을 어려워하거나 흥미가 낮은 학생에게 좋습니다. 교과서 단원과 같은 주제의 책을 골라 함께 읽게 하세요.');

    // ---------------- 초등부 사회
    t('사회', elem36, ['concept', 'basic', 'skilled'], 'concept', 1, '한끝 초등 사회', '비상교육',
        '교과서 내용을 한 권으로 끝내도록 개념 정리와 지도 · 자료 문제를 담은 초등 사회 기본서입니다.',
        '수업한 날 단원을 읽고 핵심 낱말을 정리합니다. 지도 · 자료 문제는 제목과 범례부터 읽고 풉니다.', '4쪽', 8);
    t('사회', elem36, ['concept', 'basic'], 'concept', 11, '만점왕 사회', 'EBS',
        '교과서 개념과 지도 · 자료를 쉽게 정리해 주어, 수업 복습과 개념 다지기에 좋습니다.',
        '학교 진도에 맞춰 복습하는 학생에게 좋습니다. 수업한 날 단원을 읽고 핵심 낱말을 정리합니다.', '4쪽', 8);
    t('사회', elem36, ['basic', 'skilled', 'advanced'], 'pattern', 2, '우등생 해법 사회', '천재교육',
        '단원 평가 문제와 자료 해석 문제로 배운 내용을 확인하기 좋습니다.',
        '지도 · 그래프 문제는 자료의 제목과 단위를 먼저 읽고 풉니다. 틀린 문제는 교과서에서 근거를 찾습니다.', '1단원', 8);
    t('사회', elem, all, 'concept', 10, '용선생 만화 한국사', '사회평론',
        '역사 흐름을 재미있는 만화로 풀어 주어, 초등 역사 단원의 배경지식을 쌓기 좋습니다.',
        '역사에 흥미가 낮은 학생에게 좋습니다. 5학년 역사 단원 전에 시대 순서대로 읽게 하세요.');

    // ---------------- 중등부 국어
    t('국어', mid, ['concept', 'basic'], 'concept', 1, '한끝 중등 국어', '비상교육',
        '학교 교과서별로 작품 · 문법 개념과 문제를 한 권에 정리한, 현장에서 가장 많이 쓰는 중학 국어 내신 기본서입니다.',
        '우리 학교 교과서 출판사에 맞는 책을 고릅니다. 수업한 날 해당 작품의 개념 정리를 읽고 문제를 풉니다.', '1단원', 8);
    t('국어', mid, ['basic', 'skilled'], 'pattern', 12, '체크체크 중학 국어', '천재교육',
        '교과서별 내신 문제를 고르게 담아 학교 시험 유형을 연습하기 좋습니다.',
        '시험 4주 전부터 시험 범위를 하루 한 소단원씩 풉니다.');
    t('국어', mid, ['concept'], 'concept', 10, '국어 교과서 자습서', '교과서 출판사별',
        '우리 학교 교과서 작품과 문법을 수업 순서대로 정리해 주어, 내신의 기본을 잡아 줍니다.',
        '수업한 날 해당 작품의 핵심 정리를 읽고 교과서에 표시합니다.', '1단원', 0);
    t('국어', mid, ['basic', 'skilled'], 'pattern', 2, '뿌리깊은 중학국어 독해력', '마더텅',
        '매일 짧은 지문으로 중학 독해의 기본기를 다지는 독해 습관 교재입니다.',
        '독해 습관이 없는 학생에게 좋습니다. 하루 1회분, 문단마다 중심 문장에 밑줄을 긋고 풉니다.', '1회분', 10);
    t('국어', mid, ['basic', 'skilled'], 'pattern', 3, '빠작 중학 국어 비문학 독해', '동아출판',
        '설명문 · 논설문을 구조적으로 읽는 법을 익혀 중심 내용을 찾는 힘(문해력)을 기릅니다.',
        '비문학이 약한 학생에게 좋습니다. 하루 1지문, 문단 구조를 표시하며 읽고 문제를 풉니다.', '1지문', 8);
    t('국어', mid, ['skilled', 'advanced'], 'skill', 4, '빠작 중학 국어 문학 독해', '동아출판',
        '시 · 소설 작품을 읽고 해석하는 방법을 갈래별로 익히는 문학 독해서입니다.',
        '문학 분석이 약한 학생에게 좋습니다. 작품을 먼저 읽고 화자 · 인물 · 정서를 스스로 정리한 뒤 문제를 풉니다.', '1작품', 8);
    t('국어', mid, ['basic', 'skilled'], 'pattern', 11, '빠작 중학 국어 문법', '동아출판',
        '품사 · 문장 성분 · 음운 변동 등 중학 문법을 개념과 문제로 정리합니다.',
        '국어 문법을 감으로 푸는 학생에게 좋습니다. 단원마다 규칙을 표로 정리하고 문제에 적용합니다.');
    t('국어', ['중3'], ['advanced'], 'advanced', 5, '예비 매3비', '키출판사',
        '고등 국어 비문학으로 넘어가는 다리 역할을 하는, 매일 3지문 훈련서입니다.',
        '고등 국어를 미리 준비하는 중3 상위권에게 권합니다. 매일 3지문을 시간을 재고 풀고, 틀린 문제는 근거 문장을 표시합니다.', '3지문', 8);

    // ---------------- 중등부 과학
    t('과학', mid, ['concept', 'basic'], 'concept', 1, '완자 중등 과학', '비상교육',
        '자세한 설명과 그림으로 개념을 혼자서도 이해하기 좋은 중학 과학 개념서입니다.',
        '수업한 날 해당 단원을 읽고 확인 문제를 풉니다. 그림을 공책에 따라 그리며 정리합니다.', '4쪽', 8);
    t('과학', mid, ['basic', 'skilled'], 'pattern', 2, '오투 중등 과학', '비상교육',
        '개념 정리와 다양한 문제로 실력을 넓히는 중학 과학 대표 문제집(판매 상위권)입니다.',
        '그래프 · 실험 문제는 조건과 변인을 먼저 표시하고 풉니다. 틀린 문제는 개념 쪽으로 돌아가 확인합니다.', '4쪽', 8);
    t('과학', mid, ['basic'], 'pattern', 10, '체크체크 중학 과학', '천재교육',
        '교과서별 내신 대비에 강한 문제집으로, 학교 시험 유형을 고르게 연습합니다.',
        '시험 4주 전부터 시험 범위를 하루 한 소단원씩 풉니다.');
    t('과학', mid, ['skilled', 'advanced'], 'advanced', 3, '하이탑 중학교 과학', '동아출판',
        '깊이 있는 설명과 고난도 문제로 과학고 · 상위권을 준비하는 중학 과학 심화서입니다.',
        '오투를 끝낸 상위권 학생에게 권합니다. 한 단원씩 원리를 깊게 읽고, 고난도 문제는 풀이 과정을 끝까지 씁니다.', '1단원', 12);

    // ---------------- 중등부 사회
    t('사회', mid, ['concept', 'basic'], 'concept', 1, '완자 중등 사회', '비상교육',
        '개념과 자료 해석을 함께 정리해 주는 중학 사회 개념서입니다.',
        '수업한 날 단원을 읽고 핵심 용어를 자기 말로 정리합니다.', '4쪽', 8);
    t('사회', mid, ['basic', 'skilled'], 'pattern', 2, '체크체크 중학 사회', '천재교육',
        '교과서별 내신 대비에 강하고, 지도 · 도표 자료 문제를 고르게 연습할 수 있습니다.',
        '지도 · 도표 문제는 자료의 제목 · 단위 · 범례부터 읽고 풉니다.', '4쪽', 8);
    t('사회', mid, ['skilled', 'advanced'], 'skill', 3, 'EBS 중학 뉴런 사회', 'EBS',
        '무료 강의와 함께 공부할 수 있는 중학 사회 기본서로, 개념부터 실전 문제까지 이어집니다.',
        '강의를 들으며 단원을 정리하고, 단원 끝 문제로 실력을 확인합니다.');

    // ---------------- 중등부 필수: 교과서 평가문제집 + 학교 기출문제집 (국 · 영 · 수 · 과 · 사)
    midExam('국어', '');
    midExam('영어', ' 영어는 교과서 본문을 소리 내어 읽고 빈칸 · 서술형으로 스스로 시험 보는 것도 함께 합니다.');
    midExam('수학', '');
    midExam('과학', '');
    midExam('사회', '');

    // ---------------- 고등부 국어
    t('국어', high, ['concept', 'basic'], 'concept', 1, 'EBS 윤혜정의 개념의 나비효과', 'EBS',
        '국어 문학 · 독서의 개념과 읽는 법을 처음부터 잡아 주는 수능 국어의 대표 출발점입니다.',
        '국어 개념이 없는 고1 · 고2에게 권합니다. 강의와 함께 개념을 정리하고, 개념어마다 예시 작품을 붙여 둡니다.', '1강', 8);
    t('국어', high, ['basic', 'skilled'], 'pattern', 2, '매3비 · 매3문 (매일 지문 3개씩)', '키출판사',
        '매일 기출 지문 3개씩 풀며 오답 피드백으로 독해의 기본 틀을 다지는 베스트셀러 자습서입니다.',
        '독해 습관과 기본기가 필요한 학생에게 좋습니다. 매일 3지문을 시간을 재고 풀고, 틀린 문제는 책의 피드백 방법대로 다시 읽습니다.', '3지문', 10);
    t('국어', high, ['skilled'], 'skill', 3, '자이스토리 국어 (독서 · 문학)', '수경출판사',
        '평가원 · 수능 기출을 유형별로 모아 출제 패턴을 체화하는 필수 기출서입니다.',
        '기출을 체계적으로 공부하려는 학생에게 좋습니다. 유형별로 풀고, 틀린 선지마다 지문 근거를 찾아 적습니다.', '3지문', 10);
    t('국어', high, ['skilled', 'advanced'], 'skill', 4, '마더텅 수능기출문제집 국어', '마더텅',
        '수능 · 모의고사 기출을 회차 · 영역별로 담아 실전 감각을 끌어올립니다.',
        '한 회를 시간 재고 풀고, 틀린 문항은 해설로 출제 의도를 확인한 뒤 다시 풉니다.', '1회', 8);
    t('국어', high, ['basic', 'skilled'], 'pattern', 11, 'EBS 수능특강 국어 (독서 · 문학 · 언어와 매체)', 'EBS',
        '수능 연계 교재로, 고3 학교 수업과 내신의 중심 교재입니다.',
        '고3은 연계 작품 · 지문을 꼭 정리해 둡니다. 작품마다 핵심 정서와 주제를 한 줄로 적습니다.');
    t('국어', high, ['concept'], 'concept', 12, '국어 교과서 자습서', '교과서 출판사별',
        '우리 학교 교과서 작품과 문법을 수업 순서대로 정리해 줍니다.',
        '내신 대비의 기본입니다. 수업한 날 해당 작품의 핵심 정리를 읽고 교과서에 표시합니다.');
    t('국어', high, all, 'exam', 9, '[내신] 학교 기출문제집 (내신 대비)', '학교별',
        '우리 학교 선생님의 출제 경향을 익히는 데 가장 좋습니다.',
        '시험 3주 전부터 실제 시험처럼 시간을 재고 풉니다.', '1회분', 3);

    // ---------------- 고등부 통합과학 (고1)
    t('통합과학', high1, ['concept', 'basic'], 'concept', 1, '완자 통합과학', '비상교육',
        '자세한 설명과 그림으로 통합과학 개념의 공백을 메워 주는 대표 개념서입니다.',
        '수업한 날 단원을 읽고 확인 문제를 풉니다. 단원마다 한 쪽 요약을 만듭니다.', '4쪽', 10);
    t('통합과학', high1, ['basic'], 'pattern', 11, '우공비 통합과학', '좋은책신사고',
        '교과서 핵심 자료와 기본 문항을 짝지어 내신 기초를 다져 줍니다.',
        '교과서 자료(그래프 · 표)를 눈에 익히며 단원별로 풉니다.', '1단원', 8);
    t('통합과학', high1, ['basic', 'skilled'], 'pattern', 2, '오투 통합과학', '비상교육',
        '완자 · 체크체크와 함께 과학 시장 점유율 1위를 다투는 오투의 고등판으로, 개념 정리와 다양한 문제로 내신 실력을 넓힙니다.',
        '그래프 · 실험 문제는 조건을 먼저 표시하고 풉니다.');
    t('통합과학', high1, ['skilled', 'advanced'], 'skill', 3, '1등급 만들기 통합과학', '미래엔',
        '내신 고난도 문항과 서술형으로 상위권 실력을 완성하는 내신 대비서입니다.',
        '시험 3주 전부터 단원별로 풀고, 서술형은 조건에 맞춰 끝까지 씁니다.');
    t('통합과학', high1, all, 'exam', 9, '[내신] 학교 기출문제집 (내신 대비)', '학교별',
        '우리 학교 선생님의 출제 경향을 익히는 데 가장 좋습니다.',
        '시험 3주 전부터 실제 시험처럼 시간을 재고 풉니다.', '1회분', 3);
    // ---------------- 고2 · 고3 과학탐구 (통합과학 칸에서 고2 · 고3을 고르면 보임)
    t('통합과학', high23, ['concept', 'basic'], 'concept', 1, '[과탐] EBS 수능특강 과학탐구 (물리학Ⅰ · 화학Ⅰ · 생명과학Ⅰ · 지구과학Ⅰ)', 'EBS',
        '수능 연계 교재로, 과탐 개념의 뼈대를 세우고 연계 자료를 익히는 필수서입니다.',
        '선택 과목 하나씩 단원별로 정리하고, 연계 자료(그래프 · 표)를 따로 모아 둡니다.', '1강', 10);
    t('통합과학', high23, ['concept'], 'concept', 10, '[과탐] 완자 과학탐구 (물 · 화 · 생 · 지Ⅰ)', '비상교육',
        '자세한 설명으로 과탐 선택 과목의 개념 공백을 메워 주는 개념서입니다.',
        '개념이 부족한 과목부터 시작해, 단원마다 한 쪽 요약을 만듭니다.');
    t('통합과학', high23, ['basic', 'skilled'], 'pattern', 2, '[과탐] 자이스토리 과학탐구', '수경출판사',
        '수능 · 평가원 기출을 유형별로 모아 3점 문항 진입을 위한 준킬러 훈련에 좋습니다.',
        '유형별로 풀고, 틀린 문제는 오해한 개념을 노트에 한 줄씩 적습니다.', '1유형', 10);
    t('통합과학', high23, ['skilled', 'advanced'], 'skill', 3, '[과탐] 마더텅 수능기출문제집 과학탐구', '마더텅',
        '수능 · 모의고사 기출을 담아 자료 해석과 실전 감각을 기릅니다.',
        '한 회(20문항)를 30분 타이머로 풀고, 틀린 문항은 자료 해석 오류를 확인합니다.', '1회', 8);
    t('통합과학', high23, ['advanced'], 'advanced', 4, '[과탐] 하이탑 (물리학 · 화학 · 생명과학 · 지구과학)', '동아출판',
        '깊이 있는 원리 설명과 고난도 문제로 과탐 최상위권을 완성하는 심화서입니다.',
        '킬러 단원(역학 · 양적 관계 · 유전 등)의 원리를 깊게 읽고 고난도 문제를 풉니다.');
    t('통합과학', high3, ['skilled', 'advanced'], 'final', 6, '[수능 파이널] EBS 수능완성 과학탐구', 'EBS',
        '수능 직전 연계 마무리와 실전 모의고사를 함께 담은 고3 필수 파이널 교재입니다.',
        '9월 이후 실전 모의고사를 30분에 맞춰 풀고, 연계 자료를 다시 정리합니다.');
    t('통합과학', high3, ['advanced'], 'final', 7, '[수능 파이널] 과탐 N제 · 사설 실전 모의고사', '인강 강사 · 학원 출판',
        '킬러 양적 관계 · 유전 · 역학 계산 등 고난도 유형을 집중 훈련하는 1등급 · 만점용 파이널입니다.',
        '수능 2달 전부터 주 2~3회 실전처럼 풀고, 틀린 유형만 모아 다시 풉니다. (인강 · 학원에서 판매)');

    // ---------------- 고등부 통합사회 (고1)
    t('통합사회', high1, ['concept', 'basic'], 'concept', 1, '완자 통합사회', '비상교육',
        '자세한 설명과 자료로 통합사회 개념을 혼자서도 이해할 수 있는 대표 개념서입니다.',
        '수업한 날 단원을 읽고 핵심 개념을 자기 말로 정리합니다.', '4쪽', 10);
    t('통합사회', high1, ['basic'], 'pattern', 2, '우공비 통합사회', '좋은책신사고',
        '도표 · 지도 · 사료 등 교과서 필수 자료를 눈에 익히는 기본 내신서입니다.',
        '단원마다 자료 문제를 먼저 풀고, 자료의 제목 · 단위를 확인하는 습관을 들입니다.', '1단원', 8);
    t('통합사회', high1, ['basic', 'skilled'], 'pattern', 10, '개념완성 통합사회', 'EBS',
        '핵심 개념과 문제를 함께 정리해 내신과 학력평가에 대비합니다.',
        '단원을 마칠 때마다 문제를 풀고 틀린 개념을 다시 봅니다.');
    t('통합사회', high1, ['skilled', 'advanced'], 'skill', 3, '1등급 만들기 통합사회', '미래엔',
        '선지 말장난과 고난도 자료 분석 문항으로 실력의 완성도를 높이는 내신 대비서입니다.',
        '시험 3주 전부터 단원별로 풀고, 틀린 선지는 함정 부분에 표시합니다.');
    t('통합사회', high1, all, 'exam', 9, '[내신] 학교 기출문제집 (내신 대비)', '학교별',
        '우리 학교 선생님의 출제 경향을 익히는 데 가장 좋습니다.',
        '시험 3주 전부터 실제 시험처럼 시간을 재고 풉니다.', '1회분', 3);
    // ---------------- 고2 · 고3 사회탐구 (통합사회 칸에서 고2 · 고3을 고르면 보임)
    t('통합사회', high23, ['concept', 'basic'], 'concept', 1, '[사탐] EBS 수능특강 사회탐구 (생활과 윤리 · 사회 · 문화 등)', 'EBS',
        '수능 연계 교재로, 사탐 선택 과목의 개념 백과사전 역할을 합니다.',
        '선택 과목 하나씩 단원별로 정리하고, 사상가 · 개념을 표로 만들어 둡니다.', '1강', 10);
    t('통합사회', high23, ['basic', 'skilled'], 'pattern', 2, '[사탐] 자이스토리 사회탐구', '수경출판사',
        '수능 · 평가원 기출을 유형별로 모아 자료 분석과 선지 판별을 훈련합니다.',
        '유형별로 풀고, 틀린 선지는 왜 틀렸는지 교과서 근거를 적습니다.', '1유형', 10);
    t('통합사회', high23, ['skilled', 'advanced'], 'skill', 3, '[사탐] 마더텅 수능기출문제집 사회탐구', '마더텅',
        '수능 · 모의고사 기출을 담아 사상가 선지 판별 · 경제 계산 · 도표 추론을 실전처럼 연습합니다.',
        '한 회(20문항)를 30분 타이머로 풀고, 틀린 문항은 해설로 함정을 확인합니다.', '1회', 8);
    t('통합사회', high3, ['skilled', 'advanced'], 'final', 6, '[수능 파이널] EBS 수능완성 사회탐구', 'EBS',
        '수능 직전 연계 마무리와 실전 모의고사를 함께 담은 고3 필수 파이널 교재입니다.',
        '9월 이후 실전 모의고사를 30분에 맞춰 풀고, 연계 개념을 다시 정리합니다.');
    t('통합사회', high3, ['advanced'], 'final', 7, '[수능 파이널] 사탐 실전 모의고사', '인강 강사 · 학원 출판',
        '사탐 50점 만점을 목표로 사상가 선지 · 경제 계산 · 사회문화 도표 추론을 끝내는 최종 마무리 모의고사입니다.',
        '수능 2달 전부터 주 2~3회 실전처럼 풀고, 틀린 유형만 모아 다시 풉니다. (인강 · 학원에서 판매)');

    // ---------------- 고등부 수능 파이널 — 국어 · 수학 · 영어 (고3 · N수생)
    t('국어', high3, ['skilled', 'advanced'], 'final', 6, '[수능 파이널] EBS 수능완성 국어', 'EBS',
        '수능 직전 연계 마무리와 실전 모의고사를 함께 담은 고3 필수 파이널 교재입니다.',
        '9월 이후 실전 모의고사를 80분에 맞춰 풀고, 연계 작품 · 지문을 다시 정리합니다.');
    t('국어', high3, ['advanced'], 'final', 7, '[수능 파이널] 상상국어 N제 · 간쓸개 + 사설 실전 모의고사', '상상국어 · 대성 · 이투스 등',
        '수능 직전 낯선 킬러 지문을 제한 시간 안에 돌파하는 최상위권 실전 파이널입니다.',
        '수능 2달 전부터 주 2회 실전 모의고사를 80분에 맞춰 풀고, 간쓸개로 매일 감각을 유지합니다.');
    t('수학', high3, ['skilled', 'advanced'], 'final', 6, '[수능 파이널] EBS 수능완성 수학', 'EBS',
        '수능 직전 연계 마무리와 실전 모의고사를 함께 담은 고3 필수 파이널 교재입니다.',
        '9월 이후 실전 모의고사를 100분에 맞춰 풀고, 틀린 4점 문항만 모아 다시 풉니다.');
    t('수학', high3, ['advanced'], 'final', 7, '[수능 파이널] 수학 N제 · 사설 실전 모의고사', '인강 강사 · 학원 출판',
        '수능 1등급 · 만점을 가르는 4점 킬러 · 준킬러 문항을 극복하는 실전 마무리입니다.',
        '수능 2달 전부터 주 2회 실전 모의고사를 100분에 맞춰 풀고, 시간 배분을 기록합니다. (인강 · 학원에서 판매)');
    t('영어', high3, ['skilled', 'advanced'], 'final', 7, '[수능 파이널] EBS 수능완성 영어', 'EBS',
        '수능 직전 연계 지문과 실전 모의고사를 함께 담은 고3 필수 파이널 교재입니다.',
        '9월 이후 실전 모의고사를 70분에 맞춰 풀고, 연계 지문의 주제 · 요지를 다시 정리합니다.');
    t('영어', high3, ['advanced'], 'final', 8, '[수능 파이널] 영어 실전 모의고사', '인강 강사 · 학원 출판',
        '영어 만점을 위한 킬러 유형과 실전 타임어택 훈련용 모의고사입니다.',
        '수능 2달 전부터 주 2회, 듣기까지 포함해 실전처럼 풉니다. (인강 · 학원에서 판매)');
    try {
      final QuerySnapshot<Map<String, dynamic>> cur = await _col.get();
      String keyOf(String subject, String title, List<dynamic> grades) =>
          '$subject|$title|${grades.isEmpty ? '' : divOf(grades.first.toString())}';
      final Set<String> have = cur.docs
          .map((d) => keyOf('${d.data()['subject']}', '${d.data()['title']}', (d.data()['grades'] as List?) ?? const []))
          .toSet();
      final WriteBatch b = FirebaseFirestore.instance.batch();
      int n = 0;
      for (final Textbook x in list) {
        final String k = keyOf(x.subject, x.title, x.grades);
        if (have.contains(k)) continue;
        have.add(k);
        b.set(_col.doc(), {...x.toMap(), 'createdAt': FieldValue.serverTimestamp()});
        n++;
      }
      if (n > 0) await b.commit();
      lastError = '';
      return n;
    } catch (e) {
      lastError = e.toString();
      debugPrint('[Textbook] 기본 목록 넣기 실패: $e');
      return -1;
    }
  }
}

// ============================================================================
// 자녀 성적 → 과목별 평균 (성적 관리 gradeRecords + 평가 examRecords)
// ============================================================================
class _ChildInfo {
  final String code;
  final String name;
  final Map<String, List<double>> scores; // 교과 한글 → 점수들
  final Map<String, dynamic>? pick; // 🆕 [학생 모드] 학생이 고른 교재 (부모님 화면에 보임)
  final Map<String, dynamic>? diagNote; // 🆕 학생이 스스로 한 진단 결과
  const _ChildInfo(this.code, this.name, this.scores, {this.pick, this.diagNote});
}

/// 🆕 [학생 모드 2026-10-14] 학생 → 부모님 알림: links/{내 연결 코드} 문서에 기록 (부모님 교재 길잡이에 보임)
Future<bool> _notifyParent(String code, Map<String, dynamic> data) async {
  if (code.isEmpty) return false;
  try {
    await FirebaseFirestore.instance.collection('links').doc(code).set(data, SetOptions(merge: true));
    return true;
  } catch (e) {
    debugPrint('[Textbook] 부모님 알림 실패: $e');
    return false;
  }
}

String _fmtDate(dynamic ts) {
  if (ts is Timestamp) {
    final DateTime d = ts.toDate();
    return '${d.month}/${d.day}';
  }
  return '';
}

Map<String, List<double>> _collectScores(Map<String, dynamic> data) {
  final Map<String, List<double>> out = {};
  void addFrom(dynamic raw) {
    if (raw is! List) return;
    for (final dynamic e in raw) {
      if (e is! Map) continue;
      final Map<String, dynamic> m = Map<String, dynamic>.from(e);
      String subject = '';
      for (final String k in m.keys) {
        if (k.toLowerCase().contains('subject') && m[k] is String) {
          subject = m[k] as String;
          break;
        }
      }
      if (subject.isEmpty) continue;
      final String cat = subjectCategoryOf(subject).ko;
      m.forEach((k, v) {
        final String lk = k.toLowerCase();
        final bool scoreKey = lk.contains('score') || lk.contains('midterm') || lk.contains('final') || lk.contains('mock');
        if (!scoreKey) return;
        double? s;
        if (v is num) s = v.toDouble();
        if (v is String) s = double.tryParse(v);
        if (s != null && s > 0 && s <= 100) out.putIfAbsent(cat, () => []).add(s);
      });
    }
  }

  addFrom(data['gradeRecords']);
  addFrom(data['examRecords']);
  return out;
}

// ============================================================================
// 🌸 교재 길잡이 첫 안내 팝업 (원장님 글 · 2026-10-13)
// 교재 길잡이를 열 때마다 보이고, [다시 보지 않기]를 누르면 다음부터 안 보임
// 화면 위 ⓘ 버튼으로 언제든 다시 볼 수 있음. 한국어 외 언어는 영어로 보임
// ============================================================================
const String _kIntroHideKey = 'tb_intro_hide';
const String _kIntroHideKeyStudent = 'tb_intro_hide_student';

Future<void> _showTextbookIntro(BuildContext context, {bool student = false}) async {
  final bool ko = _lang() == 'KO';
  Widget para(String t, {bool strong = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      t,
      style: _koStyle(strong ? 14 : 13.2, color: strong ? _kGold : _kWhite, w: strong ? FontWeight.bold : FontWeight.w500).copyWith(height: 1.6),
    ),
  );
  Widget section(String emoji, String t) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$emoji ', style: const TextStyle(fontSize: 16)),
        Expanded(child: Text(t, style: _koStyle(15, color: _kGold).copyWith(height: 1.4))),
      ],
    ),
  );
  Widget stage(String emoji, String name, String desc) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: _kGold.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _kGold.withValues(alpha: 0.35)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: _koStyle(13.5, color: _kGold)),
              const SizedBox(height: 2),
              Text(desc, style: _koStyle(12.5, color: _kWhite, w: FontWeight.w500).copyWith(height: 1.45)),
            ],
          ),
        ),
      ],
    ),
  );
  final Widget divider = Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(child: Container(height: 1, color: _kGold.withValues(alpha: 0.25))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.auto_awesome, color: _kGold.withValues(alpha: 0.7), size: 14)),
        Expanded(child: Container(height: 1, color: _kGold.withValues(alpha: 0.25))),
      ],
    ),
  );

  await showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (dctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A2440), Color(0xFF0A1020)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kGold, width: 1.5),
          boxShadow: [BoxShadow(color: _kGold.withValues(alpha: 0.25), blurRadius: 30)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---- 머리
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
                gradient: LinearGradient(colors: [_kGold.withValues(alpha: 0.18), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
              child: Column(
                children: [
                  const Text('🌸', style: TextStyle(fontSize: 34)),
                  const SizedBox(height: 6),
                  Text('Every child blooms at their own pace', textAlign: TextAlign.center, style: _enStyle(12.5, color: _kGold.withValues(alpha: 0.8))),
                  const SizedBox(height: 4),
                  Text(
                    student
                        ? _kr('너는 너만의 속도로\n피어나는 꽃이야', 'You bloom\nat your own pace')
                        : (ko ? '모든 아이는 저마다의 속도로\n피어나는 꽃입니다' : 'Every child is a flower\nthat blooms at its own pace'),
                    textAlign: TextAlign.center,
                    style: _koStyle(18, color: _kGold).copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
            // ---- 본문
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: student
                      ? [
                    // 🆕 학생용 안내 (한국어 · 영어)
                    para(_kr('어떤 문제집을 사야 할지 막막했나요? 친구가 푸는 책, 유명한 책이 꼭 나에게 맞는 책은 아니에요.',
                        'Not sure which workbook to buy? A famous book or your friend\'s book is not always the right one for you.')),
                    para(_kr("공부에서 가장 중요한 것은 '남보다 빠른 속도'가 아니라 '지금 나에게 맞는 첫걸음'이에요.",
                        "What matters most is not 'going faster than others' but 'the right first step for me now'."), strong: true),
                    divider,
                    section('✨', _kr('나에게 맞는 교재 찾기, 이렇게 해요', 'How to find your book')),
                    stage('①', _kr('진단하기', 'Diagnose'), _kr('과목을 고르고 질문에 솔직하게 답해요. 정답은 없어요!', 'Pick a subject and answer honestly — there are no wrong answers!')),
                    stage('②', _kr('진단 리포트', 'Report'), _kr('내 강점과 보완할 점, 공부법 처방을 확인해요.', 'See your strengths, what to improve and study tips.')),
                    stage('③', _kr('추천 교재', 'Books'), _kr('🌱개념 · 🌿기본 · 🌳실력 · 🌲심화 중 내 단계의 교재를 순서대로 봐요.', 'See books for your level, in order.')),
                    stage('④', _kr('부모님께 알리기', 'Tell parents'), _kr('마음에 드는 교재를 부모님께 알려 함께 정해요.', 'Share your pick with your parents and decide together.')),
                    divider,
                    para(_kr('나에게 꼭 맞는 교재로 시작하면 "나도 할 수 있구나!" 하는 자신감이 생겨요.', 'Starting with the right book builds the confidence that "I can do this!"')),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(_kr('GKE StudyUp이 항상 응원해요! 💪', 'GKE StudyUp is always cheering for you! 💪'), style: _koStyle(14, color: _kGold)),
                    ),
                  ]
                      : ko
                      ? [
                    para('부모님, 혹시 우리 아이에게 딱 맞는 수학 교재를 찾느라 고민이 깊으셨나요?'),
                    para('남들과 똑같은 문제집, 남들보다 앞서가는 정답만을 좇는 공부는 자녀를 지치게 만들기도 합니다.'),
                    para("수학 학습에서 가장 중요한 것은 '남들과 비교하는 속도'가 아니라, '아이의 눈높이에 맞는 올바른 첫걸음'입니다.", strong: true),
                    divider,
                    section('✨', "우리 아이만을 위한 '맞춤형 수학 길잡이'"),
                    para('GKE StudyUp은 단순한 진단평가 점수뿐만 아니라, 아이의 학습 습관, 문제 앞에서의 끈기, 생각하는 힘(메타인지)까지 섬세하게 살피어 4단계 맞춤 교재 정밀 진단을 완성했습니다.'),
                    stage('🌱', '개념 단계', '수학의 재미를 느끼고 탄탄한 기초를 쌓는 자신감의 시작'),
                    stage('🌿', '기본 단계', '원리를 바로 알고 스스로 문제를 풀어내는 성취감의 경험'),
                    stage('🌳', '실력 단계', '다양한 응용 문제를 깊이 생각하며 확장하는 사고력의 도약'),
                    stage('🌲', '심화 단계', '최고난도 문제에 기꺼이 도전하며 한계를 넘어서는 빛나는 결실'),
                    divider,
                    section('💌', '부모님의 따뜻한 믿음이 아이의 가장 큰 힘이 됩니다'),
                    para('아이에게 꼭 맞는 옷을 입혀주듯, 지금 아이의 위치에 딱 맞는 교재로 시작할 때 "나도 수학을 할 수 있구나!" 하는 깊은 울림과 자신감이 싹틉니다.'),
                    para('분석 리포트를 통해 안내해 드리는 추천 교재는 아이의 현재와 미래를 이어줄 가장 확실한 다리가 되어줄 것입니다.'),
                    para('아이의 눈부신 성장의 여정에 부모님과 늘 함께하겠습니다.'),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('GKE StudyUp이 항상 응원합니다.', style: _koStyle(14, color: _kGold)),
                    ),
                  ]
                      : [
                    para('Have you been searching hard for the math book that truly fits your child?'),
                    para('Chasing the same workbooks as everyone else, or racing ahead for the right answers, can wear a child out.'),
                    para("What matters most in math is not 'speed compared with others' but 'the right first step at your child's own level'.", strong: true),
                    divider,
                    section('✨', 'A math guide made just for your child'),
                    para('GKE StudyUp looks beyond the diagnostic test score — at study habits, persistence in front of a problem and thinking skills (metacognition) — to complete a precise 4-stage textbook diagnosis.'),
                    stage('🌱', 'Concept', 'Enjoy math and build solid foundations — the start of confidence'),
                    stage('🌿', 'Basic', 'Understand principles and solve on your own — the joy of achievement'),
                    stage('🌳', 'Intermediate', 'Think deeply through varied applied problems — a leap in thinking'),
                    stage('🌲', 'Advanced', 'Gladly take on the hardest problems — the bright fruit of going beyond limits'),
                    divider,
                    section('💌', 'Your warm trust is your child\'s greatest strength'),
                    para('Like clothes that fit perfectly, starting with the book that fits where your child is now plants the confidence of "I can do math too!"'),
                    para('The books recommended in the analysis report will be the surest bridge between your child\'s present and future.'),
                    para('We will always walk alongside you on your child\'s journey of growth.'),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('GKE StudyUp is always cheering for you.', style: _enStyle(14)),
                    ),
                  ],
                ),
              ),
            ),
            // ---- 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kGold,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(dctx),
                      icon: const Icon(Icons.auto_stories_rounded, color: Colors.black, size: 20),
                      label: Text(student ? _kr('나의 교재 찾기 시작', 'Find my book') : (ko ? '우리 아이 길잡이 시작하기' : 'Start my child\'s guide'), style: _koStyle(15, color: Colors.black)),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        final SharedPreferences prefs = await SharedPreferences.getInstance();
                        await prefs.setBool(student ? _kIntroHideKeyStudent : _kIntroHideKey, true);
                      } catch (_) {}
                      if (dctx.mounted) Navigator.pop(dctx);
                    },
                    child: Text(ko ? '다시 보지 않기 (위 ⓘ 버튼으로 다시 볼 수 있어요)' : 'Don\'t show again (tap ⓘ above to see it)',
                        style: _koStyle(11.5, color: Colors.white54, w: FontWeight.normal)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ============================================================================
// 교재 길잡이 화면
// ============================================================================
class TextbookGuideScreen extends StatefulWidget {
  /// 🆕 [2026-10-14] true = 학생 본인이 사용 (공지 및 교육상담 → 상담 탭 금색 버튼)
  final bool isStudent;
  // 🆕 [2026-10-15] 실력진단 리포트에서 열 때: 학년 · 과목 · 단계를 미리 골라 둠
  final String? initialGrade;
  final String? initialSubject;
  final String? initialLevel;
  const TextbookGuideScreen({super.key, this.isStudent = false, this.initialGrade, this.initialSubject, this.initialLevel});

  @override
  State<TextbookGuideScreen> createState() => _TextbookGuideScreenState();
}

class _TextbookGuideScreenState extends State<TextbookGuideScreen> {
  final Stream<List<Textbook>> _books = TextbookService.watchAll();
  List<_ChildInfo> _children = [];
  bool _loadingKids = true;
  int _childIdx = 0;
  String _grade = '중2';
  String _subject = '수학';
  String? _manualLevel; // 직접 고른 단계
  _Diag? _diag; // 진단 결과
  List<Textbook> _latestBooks = const []; // 서버 교재 목록 (리포트용)

  @override
  void initState() {
    super.initState();
    // 🆕 [2026-10-15] 실력진단에서 넘어오면 그 학년 · 과목 · 판정 단계로 바로 보여 줌 (안내 팝업 생략)
    if (widget.initialGrade != null && kTbGrades.contains(widget.initialGrade)) _grade = widget.initialGrade!;
    if (widget.initialSubject != null) _subject = widget.initialSubject!;
    if (widget.initialLevel != null && kTbLevels.contains(widget.initialLevel)) _manualLevel = widget.initialLevel;
    _loadChildren();
    if (widget.initialLevel == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowIntro());
    }
  }

  /// 처음 열 때 안내 팝업 (다시 보지 않기를 고르지 않았으면)
  Future<void> _maybeShowIntro() async {
    bool hide = false;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      hide = prefs.getBool(widget.isStudent ? _kIntroHideKeyStudent : _kIntroHideKey) ?? false;
    } catch (_) {}
    if (!hide && mounted) await _showTextbookIntro(context, student: widget.isStudent);
  }

  Future<void> _loadChildren() async {
    final List<_ChildInfo> kids = [];
    if (widget.isStudent) {
      // 🆕 학생 본인: 내 연결 코드의 성적으로 판정 (연결 전이면 성적 없이 진단으로)
      String code = '';
      Map<String, dynamic> d = {};
      try {
        code = (await FamilyLinkService.getMyLinkCode()) ?? '';
        if (code.isNotEmpty) d = (await FirebaseFirestore.instance.collection('links').doc(code).get()).data() ?? {};
      } catch (_) {}
      kids.add(_ChildInfo(code, _kr('나', 'Me'), _collectScores(d)));
    } else {
      try {
        final List<String> codes = await FamilyLinkService.getLinkedCodes();
        for (final String code in codes) {
          try {
            final snap = await FirebaseFirestore.instance.collection('links').doc(code).get();
            final Map<String, dynamic> d = snap.data() ?? {};
            final String name = ((d['studentName'] as String?) ?? '').trim();
            kids.add(_ChildInfo(code, name.isEmpty ? code : name, _collectScores(d),
                pick: d['textbookPick'] is Map ? Map<String, dynamic>.from(d['textbookPick'] as Map) : null,
                diagNote: d['textbookDiag'] is Map ? Map<String, dynamic>.from(d['textbookDiag'] as Map) : null));
          } catch (_) {}
        }
      } catch (_) {}
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _children = kids;
      _loadingKids = false;
      if (kids.isNotEmpty) {
        final String g = prefs.getString('tb_grade_${kids.first.code}') ?? _grade;
        if (kTbGrades.contains(g)) _grade = g;
      }
    });
    await _loadDiag();
  }

  String get _diagKey => 'tb_diag_${_child?.code ?? 'me'}_$_subject';

  Future<void> _loadDiag() async {
    _Diag? d;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_diagKey);
      if (raw != null) d = _Diag.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _diag = d;
      _manualLevel = null;
    });
  }

  Future<void> _saveDiag(_Diag d) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_diagKey, jsonEncode(d.toJson()));
    } catch (_) {}
  }

  Future<void> _rememberGrade() async {
    if (_children.isEmpty) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('tb_grade_${_children[_childIdx].code}', _grade);
    } catch (_) {}
  }

  _ChildInfo? get _child => _children.isEmpty ? null : _children[_childIdx];

  String get _div => divOf(_grade);

  /// 학년 바꾸기 (학부가 바뀌면 그 학부에 없는 과목은 첫 과목으로)
  Future<void> _setGrade(String g) async {
    final String oldSubject = _subject;
    setState(() {
      _grade = g;
      final List<String> subs = kTbDivSubjects[divOf(g)]!;
      if (!subs.contains(_subject)) _subject = subs.contains('수학') ? '수학' : subs.first;
    });
    _rememberGrade();
    if (oldSubject != _subject) await _loadDiag();
  }

  List<double> get _scores => _child?.scores[_subject] ?? const [];

  double? get _avg {
    final List<double> s = _scores;
    if (s.isEmpty) return null;
    final List<double> recent = s.length > 6 ? s.sublist(s.length - 6) : s; // 최근 6개
    return recent.reduce((a, b) => a + b) / recent.length;
  }

  /// 단계: 직접 고름 > 진단 결과 > 앱 성적(심화는 진단 후에만)
  String get _level {
    if (_manualLevel != null) return _manualLevel!;
    final _Diag? d = _diag;
    if (d != null) return d.level;
    final double? a = _avg;
    if (a == null) return 'basic';
    return a < 60 ? 'concept' : (a < 80 ? 'basic' : 'skilled');
  }

  @override
  Widget build(BuildContext context) {
    final bool admin = NoticeCounselService.isAdmin;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kGold),
        centerTitle: true,
        title: _foreign
            ? Text(_s('title'), style: _koStyle(18))
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('TEXTBOOK GUIDE', style: GoogleFonts.gowunBatang(color: _kGold, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.2)),
            Text('교재 길잡이', style: _koStyle(17)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _kr('안내 다시 보기', 'About this guide'),
            icon: const Icon(Icons.info_outline_rounded, color: _kGold),
            onPressed: () => _showTextbookIntro(context, student: widget.isStudent),
          ),
          if (admin)
            IconButton(
              tooltip: _k('admin'),
              icon: const Icon(Icons.library_add_rounded, color: _kGold),
              onPressed: _openAdmin,
            ),
        ],
      ),
      body: _loadingKids
          ? const Center(child: CircularProgressIndicator(color: _kGold))
          : StreamBuilder<List<Textbook>>(
        stream: _books,
        builder: (context, snap) {
          final List<Textbook> all = snap.data ?? const [];
          _latestBooks = all; // 진단 리포트에서 추천 교재를 보여 주기 위해 기억
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
            children: [
              if (admin) ...[
                _adminBar(),
                const SizedBox(height: 12),
              ],
              _pickCard(),
              const SizedBox(height: 14),
              _levelCard(),
              const SizedBox(height: 20),
              _bi2('orderList', size: 16),
              const SizedBox(height: 10),
              if (!snap.hasData)
                const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: _kGold)))
              else
                ..._orderedBooks(all),
              if (_foreign) ...[
                const SizedBox(height: 6),
                Text(_s('foreignNote'), style: _koStyle(11, color: Colors.white38, w: FontWeight.normal)),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kGold.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.support_agent_rounded, color: _kGold, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: _bi1('disclaimer', size: 11.5, color: Colors.white70, maxLines: 4)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openAdmin() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _TextbookAdminScreen()));
  }

  // ---------------------------------------------------------------- 관리자 금색 막대 (원장님 계정에서만)
  Widget _adminBar() {
    return GestureDetector(
      onTap: _openAdmin,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: _kGoldGrad,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: _kGold.withValues(alpha: 0.3), blurRadius: 12)],
        ),
        child: Row(
          children: [
            const Icon(Icons.library_add_rounded, color: Colors.black, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_e('adminBar'), style: _enStyle(11.5, color: Colors.black87)),
                  Text(_k('adminBar'), style: _koStyle(13, color: Colors.black)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black),
          ],
        ),
      ),
    );
  }

  // 🆕 자녀가 보낸 교재 선택 · 진단 결과 카드 (부모님 화면)
  Widget _childNoteCard(_ChildInfo c) {
    final Map<String, dynamic>? p = c.pick;
    final Map<String, dynamic>? d = c.diagNote;
    String lv(dynamic k) => _s(_kLevelKey['$k'] ?? 'lvBasic');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGold.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_kr('💌 ${c.name}의 교재 이야기', '💌 From ${c.name}'), style: _koStyle(13, color: _kGold)),
          if (d != null) ...[
            const SizedBox(height: 4),
            Text(
              _kr('📋 스스로 진단: ${_subjectLabel('${d['subject'] ?? ''}')} · ${lv(d['level'])} 단계 · ${d['score'] ?? '-'}점 ${_fmtDate(d['at'])}',
                  '📋 Self-diagnosis: ${_subjectLabel('${d['subject'] ?? ''}')} · ${lv(d['level'])} · ${d['score'] ?? '-'} ${_fmtDate(d['at'])}'),
              style: _koStyle(12, color: _kWhite, w: FontWeight.w500),
            ),
          ],
          if (p != null) ...[
            const SizedBox(height: 4),
            Text(
              _kr('📚 고른 교재: ${p['title'] ?? ''} (${_subjectLabel('${p['subject'] ?? ''}')} · ${lv(p['level'])}) ${_fmtDate(p['at'])}',
                  '📚 Picked: ${p['title'] ?? ''} (${_subjectLabel('${p['subject'] ?? ''}')} · ${lv(p['level'])}) ${_fmtDate(p['at'])}'),
              style: _koStyle(12, color: _kWhite, w: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- 자녀 · 학년 · 과목
  Widget _pickCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _luxBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isStudent) ...[
            _bi1('pickChild', size: 12.5, color: _kGold),
            const SizedBox(height: 8),
            if (_children.isEmpty)
              _bi1('noChild', size: 12, color: Colors.white54, maxLines: 3)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < _children.length; i++)
                    _chip(_children[i].name, i == _childIdx, () async {
                      final SharedPreferences prefs = await SharedPreferences.getInstance();
                      final String g = prefs.getString('tb_grade_${_children[i].code}') ?? _grade;
                      setState(() => _childIdx = i);
                      await _setGrade(kTbGrades.contains(g) ? g : _grade);
                      await _loadDiag();
                    }),
                ],
              ),
            // 🆕 자녀가 스스로 고른 교재 · 진단 결과 (학생 → 부모님 알림)
            if (_child != null && (_child!.pick != null || _child!.diagNote != null)) ...[
              const SizedBox(height: 10),
              _childNoteCard(_child!),
            ],
            const SizedBox(height: 14),
          ],
          _bi1('division', size: 12.5, color: _kGold),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final String dv in kTbDivs) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => _setGrade(kTbDivGrades[dv]!.contains(_grade) ? _grade : kTbDivGrades[dv]!.first),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: _div == dv ? _kGoldGrad : null,
                        color: _div == dv ? null : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kGold.withValues(alpha: _div == dv ? 1 : 0.35)),
                      ),
                      child: Text(_s(_kDivKey[dv]!), style: _koStyle(14, color: _div == dv ? Colors.black : Colors.white70)),
                    ),
                  ),
                ),
                if (dv != kTbDivs.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _bi1('grade', size: 12.5, color: _kGold),
          const SizedBox(height: 8),
          if (_div == 'elem')
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final String g in kTbDivGrades[_div]!)
                  _chip(_gradeLabel(g), g == _grade, () => _setGrade(g)),
              ],
            )
          else
            Row(
              children: [
                for (final String g in kTbDivGrades[_div]!) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _setGrade(g),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: g == _grade ? _kGoldGrad : null,
                          color: g == _grade ? null : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kGold.withValues(alpha: g == _grade ? 1 : 0.35)),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(_gradeLong(g), style: _koStyle(13.5, color: g == _grade ? Colors.black : Colors.white70)),
                        ),
                      ),
                    ),
                  ),
                  if (g != kTbDivGrades[_div]!.last) const SizedBox(width: 8),
                ],
              ],
            ),
          const SizedBox(height: 14),
          _bi1('subject', size: 12.5, color: _kGold),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final String sb in kTbDivSubjects[_div]!)
                _chip(_subjectLabel(sb), sb == _subject, () async {
                  setState(() => _subject = sb);
                  await _loadDiag();
                }),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- 실력 단계
  Widget _levelCard() {
    final double? avg = _avg;
    final _Diag? d = _diag;
    final List<String> reasons = [];
    if (_manualLevel != null) {
      reasons.add(_s('byHand'));
    } else if (d != null) {
      reasons.add(_s('byDiag', {
        'score': d.score,
        'est': d.estimated ? _s('est') : '',
        'pre': d.hasPre ? _s(d.ahead ? 'preYes' : 'preNo') : '—',
        'lit': _s(d.reading ? 'litGood' : 'litWeak'),
      }));
    } else if (avg != null) {
      reasons.add(_s('autoFrom', {'subject': _subjectLabel(_subject), 'avg': avg.round(), 'n': _scores.length > 6 ? 6 : _scores.length}));
      reasons.add(_s('needDiag'));
    } else {
      reasons.add(_s('noRecord', {'subject': _subjectLabel(_subject)}));
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _luxBox(bright: true, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: _kGold, size: 20),
              const SizedBox(width: 8),
              Expanded(child: _bi2('level', size: 15)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final String lv in kTbLevels) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _manualLevel = lv),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: _level == lv ? _kGoldGrad : null,
                        color: _level == lv ? null : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kGold.withValues(alpha: _level == lv ? 1 : 0.3)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_kLevelEmoji[lv]!, style: const TextStyle(fontSize: 15)),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(_s(_kLevelKey[lv]!), style: _koStyle(14, color: _level == lv ? Colors.black : Colors.white70)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (lv != kTbLevels.last) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(_s(_kLevelDescKey[_level]!), style: _koStyle(13, color: _kWhite, w: FontWeight.w600)),
          const SizedBox(height: 4),
          for (final String r in reasons)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(r, style: _koStyle(11.5, color: Colors.white54, w: FontWeight.normal)),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGold,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _openDiagnosis,
              icon: const Icon(Icons.fact_check_outlined, color: Colors.black, size: 19),
              label: Text(_s(d == null ? 'diagnose' : 'diagAgain'), style: _koStyle(14, color: Colors.black)),
            ),
          ),
          if (d != null && d.hasReport && _manualLevel == null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kGold),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final String? r = await _openReport(d);
                  if (r == 'again' && mounted) await _openDiagnosis();
                },
                icon: const Icon(Icons.assessment_outlined, color: _kGold, size: 19),
                label: Text(_kr('진단 리포트 보기', 'View diagnosis report'), style: _koStyle(13.5, color: _kGold)),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Center(child: _bi1('tapLevel', size: 10.5, color: Colors.white38)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- 진단 (점수 + 공통 6 + 과목 질문) → 리포트 → 부모님 확인
  Future<void> _openDiagnosis() async {
    final bool eng = _hasDivSet(_subject); // 🆕 [2026-10-14] 국 · 수 · 영 · 과 · 사: 학부별 문항 선택
    String engDiv = _div; // 초등부 · 중등부 · 고등부 문항 선택 (처음엔 지금 학부)
    final List<_Q> common = _commonQsFor(_subject);
    List<_Q> subj = _subjQsFor(_subject, engDiv);
    List<_Q> all = [...common, ...subj];
    List<int?> ans = List<int?>.filled(all.length, null);
    final double? avg = _avg;
    final TextEditingController scoreCtl = TextEditingController(
      text: _diag != null && !_diag!.estimated ? '${_diag!.score}' : (avg == null ? '' : '${avg.round()}'),
    );

    Widget sectionTitle(String text) => Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Row(
        children: [
          Container(width: 4, height: 16, decoration: BoxDecoration(gradient: _kGoldGrad, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: _koStyle(14, color: _kGold))),
        ],
      ),
    );

    final _Diag? result = await showDialog<_Diag>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dctx) => StatefulBuilder(
        builder: (ctx, setD) {
          Widget qRow(int i) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${i + 1}. ${_qText(all[i])}', style: _koStyle(13.5, color: Colors.white)),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final MapEntry<String, int> a in const {'ansYes': 2, 'ansMid': 1, 'ansNo': 0}.entries) ...[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setD(() => ans[i] = a.value),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: ans[i] == a.value ? _kGoldGrad : null,
                            color: ans[i] == a.value ? null : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _kGold.withValues(alpha: ans[i] == a.value ? 1 : 0.3)),
                          ),
                          child: Text(_s(a.key), style: _koStyle(12.5, color: ans[i] == a.value ? Colors.black : Colors.white70)),
                        ),
                      ),
                    ),
                    if (a.key != 'ansNo') const SizedBox(width: 6),
                  ],
                ],
              ),
              const SizedBox(height: 14),
            ],
          );

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              decoration: BoxDecoration(
                gradient: _kCardGrad,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kGold, width: 1.5),
                boxShadow: [BoxShadow(color: _kGold.withValues(alpha: 0.2), blurRadius: 24)],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: _bi2('diagTitle', size: 17, align: CrossAxisAlignment.center)),
                    const SizedBox(height: 4),
                    Center(child: Text('${_subjectLabel(_subject)} · ${_gradeLabel(_grade)}', style: _koStyle(12, color: Colors.white54, w: FontWeight.w500))),
                    const SizedBox(height: 14),
                    sectionTitle(_s('diagScore')),
                    TextField(
                      controller: scoreCtl,
                      keyboardType: TextInputType.number,
                      style: _koStyle(16, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _s('diagScoreHint'),
                        hintStyle: _koStyle(12, color: Colors.white38, w: FontWeight.normal),
                        suffixText: _lang() == 'KO' ? '점' : '',
                        suffixStyle: _koStyle(14, color: _kGold),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _kGold.withValues(alpha: 0.3))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kGold)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_s('diagTip'), style: _koStyle(10.5, color: Colors.white38, w: FontWeight.normal)),
                    const SizedBox(height: 14),
                    sectionTitle(eng ? _kr('${_subjectLabel(_subject)} 학습 공통 질문', '${_subjectLabel(_subject)} common questions') : _s('commonQ')),
                    for (int i = 0; i < common.length; i++) qRow(i),
                    sectionTitle(_s('subjectQ', {'subject': _subjectLabel(_subject)})),
                    // 🆕 [영어] 초등부 · 중등부 · 고등부 문항 선택 버튼 (바꾸면 교과 질문만 새로 답함)
                    if (eng) ...[
                      Row(
                        children: [
                          for (final String dv in kTbDivs) ...[
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setD(() {
                                  if (engDiv == dv) return;
                                  engDiv = dv;
                                  subj = _subjQsFor(_subject, dv);
                                  final List<int?> keep = ans.sublist(0, common.length);
                                  all = [...common, ...subj];
                                  ans = [...keep, ...List<int?>.filled(subj.length, null)];
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: engDiv == dv ? _kGoldGrad : null,
                                    color: engDiv == dv ? null : Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _kGold.withValues(alpha: engDiv == dv ? 1 : 0.35)),
                                  ),
                                  child: Text(_s(_kDivKey[dv]!), style: _koStyle(13, color: engDiv == dv ? Colors.black : Colors.white70)),
                                ),
                              ),
                            ),
                            if (dv != kTbDivs.last) const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    for (int i = common.length; i < all.length; i++) qRow(i),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38), padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(_s('close'), style: _koStyle(13, color: Colors.white70)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: _kGold, padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: () {
                              if (ans.any((a) => a == null)) {
                                _snack(context, _s('answerAll'));
                                return;
                              }
                              Navigator.pop(
                                ctx,
                                _computeDiag(common, subj, [for (final int? a in ans) a ?? 0], int.tryParse(scoreCtl.text.trim()),
                                    qdiv: eng ? engDiv : ''),
                              );
                            },
                            child: Text(_s('checkDone'), style: _koStyle(13, color: Colors.black)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (result == null || !mounted) return;
    // 진단 리포트를 먼저 보여 주고, 부모님이 [이대로 진행]을 눌러야 적용
    final String? ans2 = await _openReport(result, confirmMode: true);
    if (!mounted) return;
    if (ans2 == 'ok') {
      await _saveDiag(result);
      if (!mounted) return;
      setState(() {
        _diag = result;
        _manualLevel = null;
      });
    } else if (ans2 == 'again') {
      await _openDiagnosis();
    }
  }

  /// 진단 리포트 화면 열기. confirmMode = 막 진단을 마친 경우 ([이대로 진행] 버튼)
  Future<String?> _openReport(_Diag d, {bool confirmMode = false}) {
    final _ChildInfo? child = _child;
    return Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => _DiagReportScreen(
          diag: d,
          subject: _subject,
          grade: _grade,
          childName: child?.name ?? '',
          childCode: child?.code,
          books: _booksFor(_latestBooks, d.level),
          confirmMode: confirmMode,
          isStudent: widget.isStudent,
        ),
      ),
    );
  }

  List<Textbook> _booksFor(List<Textbook> all, String level) => all
      .where((b) => b.active && b.subject == _subject && b.grades.contains(_grade) && b.levels.contains(level))
      .toList()
    ..sort((a, b) {
      final int o = a.order.compareTo(b.order);
      return o != 0 ? o : kTbTypes.indexOf(a.type).compareTo(kTbTypes.indexOf(b.type));
    });

  // ---------------------------------------------------------------- 추천 교재 (푸는 순서)
  List<Widget> _orderedBooks(List<Textbook> all) {
    final List<Textbook> books = all
        .where((b) => b.active && b.subject == _subject && b.grades.contains(_grade) && b.levels.contains(_level))
        .toList()
      ..sort((a, b) {
        final int o = a.order.compareTo(b.order);
        return o != 0 ? o : kTbTypes.indexOf(a.type).compareTo(kTbTypes.indexOf(b.type));
      });
    if (books.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _luxBox(),
          child: Row(
            children: [
              const Icon(Icons.menu_book_outlined, color: Colors.white38),
              const SizedBox(width: 10),
              Expanded(child: Text(_s('noBooks'), style: _koStyle(12.5, color: Colors.white54, w: FontWeight.normal))),
            ],
          ),
        ),
      ];
    }
    final List<Textbook> main = books.where((b) => b.order < kTbAltOrder).toList();
    final List<Textbook> alt = books.where((b) => b.order >= kTbAltOrder).toList();
    return [
      for (int i = 0; i < main.length; i++) ...[
        _orderTile(i + 1, main[i]),
        if (i != main.length - 1)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Center(child: Icon(Icons.keyboard_arrow_down_rounded, color: _kGold, size: 20)),
          ),
      ],
      if (alt.isNotEmpty) ...[
        SizedBox(height: main.isEmpty ? 0 : 16),
        _bi1('altBooks', size: 13, color: _kGold),
        const SizedBox(height: 8),
        for (final Textbook b in alt) ...[
          _orderTile(0, b),
          const SizedBox(height: 8),
        ],
      ],
    ];
  }

  Widget _orderTile(int n, Textbook b) {
    final List<String> sub = [
      _s(_kTypeKey[b.type] ?? 'stConcept'),
      if (b.publisher.isNotEmpty) b.publisher,
      if (b.daily.isNotEmpty) '${_s('daily')} ${b.daily}',
      if (b.weeks > 0) _s('weeksN', {'n': b.weeks}),
    ];
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openBook(b),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: _luxBox(bright: n == 1, radius: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: n == 1 ? _kGoldGrad : null,
                color: n == 1 ? null : _kGold.withValues(alpha: 0.1),
                border: Border.all(color: _kGold.withValues(alpha: 0.7)),
              ),
              child: n == 0
                  ? const Icon(Icons.menu_book_rounded, color: _kGold, size: 17)
                  : Text('$n', style: _enStyle(16, color: n == 1 ? Colors.black : _kGold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _koStyle(15, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(sub.join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: _koStyle(11, color: Colors.white54, w: FontWeight.normal)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kGold),
          ],
        ),
      ),
    );
  }

  Future<void> _openBook(Textbook b) async {
    final _ChildInfo? child = _child;
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            gradient: _kCardGrad,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kGold, width: 1.5),
            boxShadow: [BoxShadow(color: _kGold.withValues(alpha: 0.22), blurRadius: 24)],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _kGoldGrad),
                    child: const Icon(Icons.auto_stories_rounded, color: Colors.black, size: 26),
                  ),
                ),
                const SizedBox(height: 12),
                Center(child: Text(b.title, textAlign: TextAlign.center, style: _koStyle(19, color: Colors.white))),
                if (b.publisher.isNotEmpty) Center(child: Text(b.publisher, style: _koStyle(12.5, color: Colors.white54, w: FontWeight.normal))),
                const SizedBox(height: 10),
                Center(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _pill(_subjectLabel(b.subject)),
                      _pill(_s(_kTypeKey[b.type] ?? 'stConcept')),
                      for (final String lv in b.levels) _pill(_s(_kLevelKey[lv] ?? 'lvBasic')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: _kGold.withValues(alpha: 0.3)),
                const SizedBox(height: 14),
                if (b.why.isNotEmpty) ...[
                  _bi1('why', size: 12.5, color: _kGold),
                  const SizedBox(height: 4),
                  Text(b.why, style: _koStyle(13.5, color: _kWhite, w: FontWeight.w500)),
                  const SizedBox(height: 14),
                ],
                if (b.howTo.isNotEmpty) ...[
                  _bi1('howTo', size: 12.5, color: _kGold),
                  const SizedBox(height: 4),
                  Text(b.howTo, style: _koStyle(13.5, color: _kWhite, w: FontWeight.w500)),
                  const SizedBox(height: 14),
                ],
                Row(
                  children: [
                    if (b.daily.isNotEmpty) Expanded(child: _infoBox('daily', b.daily)),
                    if (b.daily.isNotEmpty && b.weeks > 0) const SizedBox(width: 10),
                    if (b.weeks > 0) Expanded(child: _infoBox('period', _s('weeksN', {'n': b.weeks}))),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38), padding: const EdgeInsets.symmetric(vertical: 12)),
                        onPressed: () => Navigator.pop(dctx),
                        child: Text(_s('close'), style: _koStyle(13, color: Colors.white70)),
                      ),
                    ),
                    if (child != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: _kGold, padding: const EdgeInsets.symmetric(vertical: 12)),
                          onPressed: () async {
                            Navigator.pop(dctx);
                            if (widget.isStudent) {
                              // 🆕 학생 → 부모님께 이 교재 알리기
                              if (child.code.isEmpty) {
                                _snack(context, _kr('부모님과 가족 연결을 먼저 해 주세요.', 'Please link with your parents first.'), bg: Colors.redAccent);
                                return;
                              }
                              final bool ok = await _notifyParent(child.code, {
                                'textbookPick': {
                                  'title': b.title, 'publisher': b.publisher, 'subject': _subject, 'grade': _grade,
                                  'level': _level, 'at': FieldValue.serverTimestamp(),
                                },
                              });
                              if (mounted) {
                                _snack(context, ok ? _kr('부모님께 알렸어요! 부모님 교재 길잡이에 보여요.', 'Sent! Your parents can see it in their guide.') : _s('failed'),
                                    bg: ok ? const Color(0xFF0D1527) : Colors.redAccent);
                              }
                              return;
                            }
                            try {
                              await FamilyLinkService.pushEncouragementToChild(
                                child.code,
                                message: _s('childMsg', {'title': b.title, 'pub': b.publisher.isEmpty ? '-' : b.publisher, 'daily': b.daily.isEmpty ? '-' : b.daily}),
                              );
                              if (mounted) _snack(context, _s('sent'));
                            } catch (_) {
                              if (mounted) _snack(context, _s('failed'), bg: Colors.redAccent);
                            }
                          },
                          icon: const Icon(Icons.send_rounded, color: Colors.black, size: 18),
                          label: Text(widget.isStudent ? _kr('부모님께 이 교재 알리기', 'Tell my parents') : _s('sendChild'), style: _koStyle(13, color: Colors.black)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: _kGold.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _kGold.withValues(alpha: 0.4)),
    ),
    child: Text(t, style: _koStyle(11, color: _kGold)),
  );

  Widget _infoBox(String k, String v) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _kGold.withValues(alpha: 0.3)),
    ),
    child: Column(
      children: [
        Text(_s(k), style: _koStyle(11, color: Colors.white54, w: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(v, textAlign: TextAlign.center, style: _koStyle(14, color: Colors.white)),
      ],
    ),
  );
}

// ============================================================================
// 📊 진단 리포트 (부모님이 보고 [이대로 진행]을 눌러야 적용)
// - 질문별 응답을 지표(측정 의도)로 묶어 🟢 우수 / 🟡 보통 / 🔴 보완 필요로 표시
// - 입체 분석 한 문장 + 강점 · 보완점 + 종합 처방 + 추천 교재(푸는 순서)
// ============================================================================
class _DiagReportScreen extends StatelessWidget {
  final _Diag diag;
  final String subject;
  final String grade;
  final String childName;
  final bool isStudent; // 🆕 학생 본인이 보는 리포트
  final String? childCode;
  final List<Textbook> books;
  final bool confirmMode;

  const _DiagReportScreen({
    required this.diag,
    required this.subject,
    required this.grade,
    required this.childName,
    required this.childCode,
    required this.books,
    required this.confirmMode,
    this.isStudent = false,
  });

  static const Color _cGood = Color(0xFF4ADE80);
  static const Color _cMid = Color(0xFFFACC15);
  static const Color _cBad = Color(0xFFF87171);

  String _gradeEmoji(int g) => g == 2 ? '🟢' : (g == 1 ? '🟡' : '🔴');
  String _gradeText(int g) => g == 2 ? _kr('우수', 'Strong') : (g == 1 ? _kr('보통', 'Average') : _kr('보완 필요', 'Needs work'));
  Color _gradeColor(int g) => g == 2 ? _cGood : (g == 1 ? _cMid : _cBad);

  Widget _card({required Widget child, bool bright = false}) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: _luxBox(bright: bright, radius: 16),
    child: child,
  );

  Widget _title(String ko, String en, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, color: _kGold, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: _ko
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(en, style: _enStyle(11.5, color: _kGold.withValues(alpha: 0.75))),
              Text(ko, style: _koStyle(15)),
            ],
          )
              : Text(en, style: _enStyle(15)),
        ),
      ],
    ),
  );

  Widget _indRow(_IndRow r) {
    final String nums = r.qNums.join(', ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🎯 ', style: TextStyle(fontSize: 13)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_indName(r.key), style: _koStyle(13.5, color: Colors.white, w: FontWeight.w600)),
                Text(_kr('문항 $nums 응답 기반', 'Based on Q$nums'), style: _koStyle(10.5, color: Colors.white38, w: FontWeight.normal)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: _gradeColor(r.grade).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _gradeColor(r.grade).withValues(alpha: 0.6)),
            ),
            child: Text('${_gradeEmoji(r.grade)} ${_gradeText(r.grade)}', style: _koStyle(11.5, color: _gradeColor(r.grade))),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, {bool good = true}) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (good ? _kGold : _cBad).withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Text(label, style: _koStyle(10.5, color: Colors.white54, w: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(value, textAlign: TextAlign.center, style: _koStyle(14, color: good ? Colors.white : _cBad)),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final List<_Q> common = _commonQsFor(subject);
    final List<_Q> subj = _subjQsFor(subject, diag.qdiv.isEmpty ? divOf(grade) : diag.qdiv);
    // 예전(영어 새 문항 전) 영어 진단은 문항이 달라 자세한 분석을 빼고 다시 진단을 안내
    final bool oldEng = _hasDivSet(subject) && diag.qdiv.isEmpty;
    final List<_IndRow> rows = oldEng ? <_IndRow>[] : _indRows(diag, common, subj);
    final List<_IndRow> habit = rows.where((r) => r.common).toList();
    final List<_IndRow> skill = rows.where((r) => !r.common).toList();
    final List<String> strong = [for (final _IndRow r in rows) if (r.grade == 2) _indName(r.key)];
    final List<String> weak = [for (final _IndRow r in rows) if (r.grade == 0) _indName(r.key)];
    final List<String> rx = oldEng ? <String>[] : _prescriptions(diag, rows, subject, common, subj);
    final bool errWeak = rows.any((r) => r.key == 'errorMgmt' && r.grade == 0);
    final String level = diag.level;
    final List<Textbook> mainBooks = books.where((b) => b.order < kTbAltOrder).toList();
    final List<Textbook> altBooks = books.where((b) => b.order >= kTbAltOrder).toList();
    final List<Textbook> comboBooks = mainBooks.where((b) => b.type != 'exam').take(3).toList();
    final String combo = comboBooks.isEmpty
        ? ''
        : '[${comboBooks.map((b) => b.title).join(' → ')}${errWeak ? _kr(' + 오답 클리닉 노트', ' + error clinic notebook') : ''}]';

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kGold),
        centerTitle: true,
        title: _ko
            ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('DIAGNOSIS REPORT', style: GoogleFonts.gowunBatang(color: _kGold, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
            Text('진단 리포트', style: _koStyle(17)),
          ],
        )
            : Text('Diagnosis Report', style: _enStyle(17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
        children: [
          // ---- 종합 판정
          _card(
            bright: true,
            child: Column(
              children: [
                Text(
                  [
                    if (childName.isNotEmpty) childName,
                    _gradeLabel(grade),
                    _subjectLabel(subject),
                    if (diag.qdiv.isNotEmpty) _kr('${_s(_kDivKey[diag.qdiv]!)} 문항', '${_s(_kDivKey[diag.qdiv]!)} questions'),
                    if (diag.date.isNotEmpty) diag.date,
                  ].join(' · '),
                  style: _koStyle(12, color: Colors.white54, w: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                  decoration: BoxDecoration(gradient: _kGoldGrad, borderRadius: BorderRadius.circular(30)),
                  child: Text(_s(_kLevelKey[level]!), style: _koStyle(22, color: Colors.black)),
                ),
                const SizedBox(height: 8),
                Text(_s(_kLevelDescKey[level]!), textAlign: TextAlign.center, style: _koStyle(12.5, color: _kWhite, w: FontWeight.w600)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _statChip(_kr('진단 점수', 'Score'), '${diag.score}${diag.estimated ? _s('est') : _kr('점', '')}'),
                    const SizedBox(width: 8),
                    _statChip(_kr('선행', 'Ahead'), diag.hasPre ? _s(diag.ahead ? 'preYes' : 'preNo') : '—', good: !diag.hasPre || diag.ahead),
                    const SizedBox(width: 8),
                    _statChip(_kr('문해력', 'Reading'), _s(diag.reading ? 'litGood' : 'litWeak'), good: diag.reading),
                  ],
                ),
              ],
            ),
          ),
          // ---- 입체 분석 한 문장
          _card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔎 ', style: TextStyle(fontSize: 16)),
                Expanded(child: Text(_headline(diag, rows), style: _koStyle(14, color: Colors.white, w: FontWeight.w600))),
              ],
            ),
          ),
          if (!diag.hasReport || oldEng)
            _card(child: Text(_kr('이전 방식으로 진단한 결과라 자세한 분석이 없어요. [다시 진단하기]를 해 주세요.', 'This result was made with the old check. Please diagnose again for the full report.'),
                style: _koStyle(12.5, color: Colors.white60, w: FontWeight.normal))),
          // ---- 학습 체력 및 성향
          if (habit.isNotEmpty)
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title('학습 체력 및 성향 분석', 'Study Habits & Attitude', Icons.psychology_outlined),
                  for (final _IndRow r in habit) _indRow(r),
                ],
              ),
            ),
          // ---- 과목 실력
          if (skill.isNotEmpty)
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title('${_subjectLabel(subject)} 실력 분석', '${_kSubjEn[subject] ?? subject} Skill Analysis', Icons.calculate_outlined),
                  for (final _IndRow r in skill) _indRow(r),
                ],
              ),
            ),
          // ---- 강점 · 보완점
          if (rows.isNotEmpty)
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title('강점과 보완점', 'Strengths & Areas to Improve', Icons.compare_arrows_rounded),
                  Text('🟢 ${_kr('강점', 'Strengths')}', style: _koStyle(13, color: _cGood)),
                  const SizedBox(height: 4),
                  Text(strong.isEmpty ? _kr('아직 뚜렷한 강점이 보이지 않아요. 하나씩 만들어 가요.', 'No clear strengths yet — let\'s build them.') : strong.join(' · '),
                      style: _koStyle(12.5, color: _kWhite, w: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Text('🔴 ${_kr('보완점', 'To improve')}', style: _koStyle(13, color: _cBad)),
                  const SizedBox(height: 4),
                  Text(weak.isEmpty ? _kr('크게 부족한 부분이 없어요.', 'No major weak points.') : weak.join(' · '),
                      style: _koStyle(12.5, color: _kWhite, w: FontWeight.w500)),
                ],
              ),
            ),
          // ---- 종합 처방
          _card(
            bright: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title('종합 처방', 'Overall Prescription', Icons.lightbulb_outline_rounded),
                for (final String t in rx)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡 ', style: TextStyle(fontSize: 13)),
                        Expanded(child: Text(t, style: _koStyle(13, color: _kWhite, w: FontWeight.w500))),
                      ],
                    ),
                  ),
                if (combo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kGold.withValues(alpha: 0.5)),
                    ),
                    child: Text('${_kr('추천 조합', 'Recommended set')}  $combo', style: _koStyle(13, color: _kGold)),
                  ),
                ],
              ],
            ),
          ),
          // ---- 추천 교재 · 푸는 순서
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title('추천 교재 · 푸는 순서', 'Recommended Books · Study Order', Icons.menu_book_rounded),
                if (books.isEmpty)
                  Text(_s('noBooks'), style: _koStyle(12.5, color: Colors.white54, w: FontWeight.normal))
                else ...[
                  for (int i = 0; i < mainBooks.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: i == 0 ? _kGoldGrad : null,
                              border: Border.all(color: _kGold.withValues(alpha: 0.7)),
                            ),
                            child: Text('${i + 1}', style: _enStyle(12, color: i == 0 ? Colors.black : _kGold)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${mainBooks[i].title}${mainBooks[i].publisher.isEmpty ? '' : '  (${mainBooks[i].publisher})'}',
                              style: _koStyle(13.5, color: Colors.white, w: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (altBooks.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(_s('altBooks'), style: _koStyle(12.5, color: _kGold)),
                    const SizedBox(height: 4),
                    for (final Textbook b in altBooks)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          '• ${b.title}${b.publisher.isEmpty ? '' : '  (${b.publisher})'}${b.howTo.isEmpty ? '' : '\n   ${b.howTo}'}',
                          style: _koStyle(12.5, color: _kWhite, w: FontWeight.w500),
                        ),
                      ),
                  ],
                ],
              ],
            ),
          ),
          // ---- 버튼
          if (childCode != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kGold),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (isStudent) {
                    // 🆕 학생 → 부모님께 진단 결과 알리기
                    if (childCode!.isEmpty) {
                      _snack(context, _kr('부모님과 가족 연결을 먼저 해 주세요.', 'Please link with your parents first.'), bg: Colors.redAccent);
                      return;
                    }
                    final bool ok = await _notifyParent(childCode!, {
                      'textbookDiag': {'subject': subject, 'grade': grade, 'level': level, 'score': diag.score, 'at': FieldValue.serverTimestamp()},
                    });
                    if (context.mounted) {
                      _snack(context, ok ? _kr('부모님께 진단 결과를 알렸어요!', 'Your result was sent to your parents!') : _s('failed'),
                          bg: ok ? const Color(0xFF0D1527) : Colors.redAccent);
                    }
                    return;
                  }
                  final String first = books.isEmpty ? '-' : books.first.title;
                  final String msg = _kr(
                    '📋 ${_subjectLabel(subject)} 진단 결과: ${_s(_kLevelKey[level]!)} 단계 · 첫 교재 [$first]부터 함께 시작해 보자! 💪',
                    '📋 ${_subjectLabel(subject)} diagnosis: ${_s(_kLevelKey[level]!)} level · let\'s start with [$first]! 💪',
                  );
                  try {
                    await FamilyLinkService.pushEncouragementToChild(childCode!, message: msg);
                    if (context.mounted) _snack(context, _s('sent'));
                  } catch (_) {
                    if (context.mounted) _snack(context, _s('failed'), bg: Colors.redAccent);
                  }
                },
                icon: const Icon(Icons.send_rounded, color: _kGold, size: 18),
                label: Text(isStudent ? _kr('부모님께 진단 결과 알리기', 'Tell my parents my result') : _kr('자녀에게 결과 보내기', 'Send result to my child'), style: _koStyle(13.5, color: _kGold)),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, 'again'),
                  child: Text(_kr('다시 진단', 'Diagnose again'), style: _koStyle(13.5, color: Colors.white70)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGold,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, 'ok'),
                  icon: Icon(confirmMode ? Icons.check_circle_rounded : Icons.close_rounded, color: Colors.black, size: 19),
                  label: Text(confirmMode ? _kr('이대로 진행 (확인)', 'Apply this result') : _kr('닫기', 'Close'), style: _koStyle(14, color: Colors.black)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 관리자: 교재 추가 · 수정 · 숨기기 · 삭제 · 순서 (원장님 계정에서만 보임)
// ============================================================================
class _TextbookAdminScreen extends StatefulWidget {
  const _TextbookAdminScreen();

  @override
  State<_TextbookAdminScreen> createState() => _TextbookAdminState();
}

class _TextbookAdminState extends State<_TextbookAdminScreen> {
  String _fDiv = 'mid'; // 목록 보기: 학부
  String _fSubj = 'all'; // 목록 보기: 과목 (all = 전체)

  void _failSnack(BuildContext context) {
    _snack(context, TextbookService.lastWasRule ? _k('ruleErr') : '${_s('failed')}\n${TextbookService.lastError}', bg: Colors.redAccent);
  }

  Widget _ruleCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: _luxBox(bright: true, radius: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_k('ruleTitle'), style: _koStyle(14, color: _kGold)),
        const SizedBox(height: 6),
        for (final String r in ['rule1', 'rule2', 'rule3', 'rule4'])
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text('• ${_k(r)}', style: _koStyle(12, color: _kWhite, w: FontWeight.w500)),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kGold),
        title: Text('${_k('admin')} / ${_e('admin')}', style: _koStyle(16)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kGold,
        onPressed: () => _editBook(context, null),
        icon: const Icon(Icons.add_rounded, color: Colors.black),
        label: Text(_k('addBook'), style: _koStyle(14, color: Colors.black)),
      ),
      body: StreamBuilder<List<Textbook>>(
        stream: TextbookService.watchAll(),
        builder: (context, snap) {
          final List<Textbook> list = (snap.data ?? const <Textbook>[])
              .where((b) => b.grades.any((g) => divOf(g) == _fDiv) && (_fSubj == 'all' || b.subject == _fSubj))
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            children: [
              _ruleCard(),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kGold),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final int n = await TextbookService.seedAll();
                  if (!context.mounted) return;
                  if (n < 0) {
                    _failSnack(context);
                  } else {
                    _snack(context, n == 0 ? _k('seedNone') : _k('seedDone', {'n': n}));
                  }
                },
                icon: const Icon(Icons.download_rounded, color: _kGold),
                label: Text(_k('seedAll'), style: _koStyle(13, color: _kGold)),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  Future<bool> ask(String k) async =>
                      await showDialog<bool>(
                        context: context,
                        builder: (c2) => AlertDialog(
                          backgroundColor: const Color(0xFF0D1527),
                          content: Text(_k(k), style: _koStyle(14, color: Colors.white, w: FontWeight.w500)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c2, false), child: Text(_s('close'), style: _koStyle(13, color: Colors.white70))),
                            TextButton(onPressed: () => Navigator.pop(c2, true), child: Text(_k('yes'), style: _koStyle(13, color: Colors.redAccent))),
                          ],
                        ),
                      ) ==
                          true;
                  if (!await ask('resetAsk1')) return;
                  if (!context.mounted || !await ask('resetAsk2')) return;
                  final int n = await TextbookService.resetAll();
                  if (!context.mounted) return;
                  if (n < 0) {
                    _failSnack(context);
                  } else {
                    _snack(context, _k('resetDone', {'n': n}));
                  }
                },
                icon: const Icon(Icons.restart_alt_rounded, color: Colors.redAccent, size: 20),
                label: Text(_k('resetAll'), style: _koStyle(12.5, color: Colors.redAccent)),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final String dv in kTbDivs)
                  _chip(_k(_kDivKey[dv]!), _fDiv == dv, () => setState(() {
                    _fDiv = dv;
                    if (_fSubj != 'all' && !kTbDivSubjects[dv]!.contains(_fSubj)) _fSubj = 'all';
                  })),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                _chip(_k('all'), _fSubj == 'all', () => setState(() => _fSubj = 'all')),
                for (final String sb in kTbDivSubjects[_fDiv]!) _chip(sb, _fSubj == sb, () => setState(() => _fSubj = sb)),
              ]),
              const SizedBox(height: 14),
              if (snap.hasError)
                Text('${_k('ruleErr')}\n${snap.error}', style: _koStyle(12, color: Colors.redAccent, w: FontWeight.normal))
              else if (!snap.hasData)
                const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: _kGold)))
              else if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_k('emptyAdmin'), textAlign: TextAlign.center, style: _koStyle(13, color: Colors.white60, w: FontWeight.normal)),
                  )
                else
                  for (final Textbook b in list) ...[
                    _adminTile(context, b),
                    const SizedBox(height: 8),
                  ],
            ],
          );
        },
      ),
    );
  }

  Widget _adminTile(BuildContext context, Textbook b) {
    return InkWell(
      onTap: () => _editBook(context, b),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _luxBox(radius: 12),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _kGold.withValues(alpha: 0.6))),
              child: Text('${b.order}', style: _enStyle(12, color: _kGold)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${b.title}${b.active ? '' : '  (${_k('hidden')})'}', style: _koStyle(14, color: b.active ? Colors.white : Colors.white38)),
                  Text(
                    '${b.subject} · ${_k(_kTypeKey[b.type] ?? 'stConcept')} · ${b.grades.join(',')} · ${b.levels.map((l) => _k(_kLevelKey[l] ?? l)).join(',')}',
                    style: _koStyle(11, color: Colors.white54, w: FontWeight.normal),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_rounded, color: _kGold, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _editBook(BuildContext context, Textbook? b) async {
    final TextEditingController title = TextEditingController(text: b?.title ?? '');
    final TextEditingController pub = TextEditingController(text: b?.publisher ?? '');
    final TextEditingController why = TextEditingController(text: b?.why ?? '');
    final TextEditingController how = TextEditingController(text: b?.howTo ?? '');
    final TextEditingController daily = TextEditingController(text: b?.daily ?? '');
    final TextEditingController weeks = TextEditingController(text: b == null || b.weeks == 0 ? '' : '${b.weeks}');
    final TextEditingController order = TextEditingController(text: b == null ? '1' : '${b.order}');
    String div = b != null && b.grades.isNotEmpty ? divOf(b.grades.first) : _fDiv;
    String subject = b?.subject ?? (_fSubj != 'all' ? _fSubj : '수학');
    String type = b?.type ?? 'concept';
    final Set<String> grades = {...?b?.grades};
    final Set<String> levels = {...?b?.levels};
    bool active = b?.active ?? true;
    bool saving = false;

    InputDecoration deco(String k) => InputDecoration(
      labelText: _k(k),
      labelStyle: _koStyle(12, color: Colors.white60, w: FontWeight.normal),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _kGold.withValues(alpha: 0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kGold)),
    );

    Widget label(String k) => Padding(padding: const EdgeInsets.only(top: 12, bottom: 6), child: Text(_k(k), style: _koStyle(12, color: _kGold)));

    await showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (ctx, setD) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
          child: Container(
            decoration: BoxDecoration(gradient: _kCardGrad, borderRadius: BorderRadius.circular(18), border: Border.all(color: _kGold, width: 1.5)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(child: Text(_k(b == null ? 'addBook' : 'editBook'), style: _koStyle(17))),
                  const SizedBox(height: 12),
                  TextField(controller: title, style: _koStyle(14, color: Colors.white, w: FontWeight.w500), decoration: deco('fTitle')),
                  const SizedBox(height: 8),
                  TextField(controller: pub, style: _koStyle(14, color: Colors.white, w: FontWeight.w500), decoration: deco('fPub')),
                  label('fDiv'),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final String dv in kTbDivs)
                      _chip(_k(_kDivKey[dv]!), div == dv, () => setD(() {
                        if (div == dv) return;
                        div = dv;
                        grades.clear();
                        if (!kTbDivSubjects[dv]!.contains(subject)) subject = '수학';
                      })),
                  ]),
                  label('subject'),
                  Wrap(spacing: 6, runSpacing: 6, children: [for (final String sb in kTbDivSubjects[div]!) _chip(sb, subject == sb, () => setD(() => subject = sb))]),
                  label('fLevels'),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final String l in kTbLevels)
                      _chip(_k(_kLevelKey[l]!), levels.contains(l), () => setD(() => levels.contains(l) ? levels.remove(l) : levels.add(l))),
                  ]),
                  label('fGrades'),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final String g in kTbDivGrades[div]!) _chip(g, grades.contains(g), () => setD(() => grades.contains(g) ? grades.remove(g) : grades.add(g))),
                  ]),
                  label('fType'),
                  Wrap(spacing: 6, runSpacing: 6, children: [for (final String t in kTbTypes) _chip(_k(_kTypeKey[t]!), type == t, () => setD(() => type = t))]),
                  const SizedBox(height: 12),
                  TextField(controller: order, keyboardType: TextInputType.number, style: _koStyle(14, color: Colors.white, w: FontWeight.w500), decoration: deco('fOrder')),
                  const SizedBox(height: 8),
                  TextField(controller: why, maxLines: 3, style: _koStyle(13, color: Colors.white, w: FontWeight.w500), decoration: deco('fWhy')),
                  const SizedBox(height: 8),
                  TextField(controller: how, maxLines: 3, style: _koStyle(13, color: Colors.white, w: FontWeight.w500), decoration: deco('fHow')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: daily, style: _koStyle(13, color: Colors.white, w: FontWeight.w500), decoration: deco('fDaily'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: weeks, keyboardType: TextInputType.number, style: _koStyle(13, color: Colors.white, w: FontWeight.w500), decoration: deco('fWeeks'))),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: _kGold,
                    title: Text(_k('fActive'), style: _koStyle(13, color: Colors.white)),
                    value: active,
                    onChanged: (v) => setD(() => active = v),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (b != null)
                        TextButton(
                          onPressed: () async {
                            final bool? yes = await showDialog<bool>(
                              context: ctx,
                              builder: (c2) => AlertDialog(
                                backgroundColor: const Color(0xFF0D1527),
                                content: Text(_k('deleteAsk'), style: _koStyle(14, color: Colors.white)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(c2, false), child: Text(_s('close'), style: _koStyle(13, color: Colors.white70))),
                                  TextButton(onPressed: () => Navigator.pop(c2, true), child: Text(_k('delete'), style: _koStyle(13, color: Colors.redAccent))),
                                ],
                              ),
                            );
                            if (yes != true) return;
                            final bool ok = await TextbookService.delete(b.id);
                            if (dctx.mounted) Navigator.pop(dctx);
                            if (!ok && context.mounted) _failSnack(context);
                          },
                          child: Text(_k('delete'), style: _koStyle(13, color: Colors.redAccent)),
                        ),
                      const Spacer(),
                      TextButton(onPressed: () => Navigator.pop(dctx), child: Text(_s('close'), style: _koStyle(13, color: Colors.white70))),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _kGold),
                        onPressed: saving
                            ? null
                            : () async {
                          if (title.text.trim().isEmpty || grades.isEmpty || levels.isEmpty) {
                            _snack(context, _k('needTitle'), bg: Colors.redAccent);
                            return;
                          }
                          setD(() => saving = true);
                          final bool ok = await TextbookService.save(
                            Textbook(
                              id: b?.id ?? '',
                              subject: subject,
                              grades: kTbGrades.where(grades.contains).toList(),
                              levels: kTbLevels.where(levels.contains).toList(),
                              type: type,
                              title: title.text.trim(),
                              publisher: pub.text.trim(),
                              why: why.text.trim(),
                              howTo: how.text.trim(),
                              daily: daily.text.trim(),
                              weeks: int.tryParse(weeks.text.trim()) ?? 0,
                              order: int.tryParse(order.text.trim()) ?? 1,
                              active: active,
                            ),
                            id: b?.id,
                          );
                          if (ok) {
                            if (dctx.mounted) Navigator.pop(dctx);
                          } else {
                            setD(() => saving = false);
                            if (context.mounted) _failSnack(context);
                          }
                        },
                        child: Text(_k('save'), style: _koStyle(13, color: Colors.black)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
