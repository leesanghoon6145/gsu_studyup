// ============================================================================
// [일반 플래너 - AI 분석용 데이터 수집] CompletionSurveyData
// 타임라인 항목을 완료할 때 물어보는 질문 목록입니다. 1단계(공통 4개)는
// 항상 표시되고, 2단계(분야별 3개)는 "더 자세히" 버튼을 눌러야 나옵니다.
// 여기 모인 답변이 나중에 AI 코멘트/분석의 재료가 됩니다.
// ============================================================================

class CategoryQuestion {
  final String id;
  final String labelEn;
  final String labelKo;
  final List<String> options;
  final Map<String, String>? labelTranslations; // 🆕 [10개국어 확장] 질문 제목만 번역 (선택지는 저장값이라 보류)

  const CategoryQuestion({required this.id, required this.labelEn, required this.labelKo, required this.options, this.labelTranslations});
}


// 🆕 [10개국어 확장] 질문 제목 공용 번역사전 (여러 분야에서 같은 라벨 재사용)
const Map<String, Map<String, String>> _qLabelTranslations = {
  'Intensity': {'JA': '強度', 'ZH': '强度', 'FR': 'Intensité', 'DE': 'Intensität', 'RU': 'Интенсивность', 'AR': 'الشدة', 'HI': 'तीव्रता', 'VI': 'Cường độ', 'ES': 'Intensidad', 'TH': 'ความเข้มข้น'},
  'Vs Target': {'JA': '目標対比', 'ZH': '与目标对比', 'FR': 'Vs objectif', 'DE': 'Vs. Ziel', 'RU': 'По сравнению с целью', 'AR': 'مقابل الهدف', 'HI': 'लक्ष्य की तुलना में', 'VI': 'So với mục tiêu', 'ES': 'Vs objetivo', 'TH': 'เทียบกับเป้าหมาย'},
  'After Feeling': {'JA': '終了後の状態', 'ZH': '结束后感觉', 'FR': 'Sensation après', 'DE': 'Gefühl danach', 'RU': 'Ощущение после', 'AR': 'الشعور بعد ذلك', 'HI': 'बाद की भावना', 'VI': 'Cảm giác sau đó', 'ES': 'Sensación después', 'TH': 'ความรู้สึกหลังจากนั้น'},
  'Understanding': {'JA': '理解度', 'ZH': '理解程度', 'FR': 'Compréhension', 'DE': 'Verständnis', 'RU': 'Понимание', 'AR': 'الفهم', 'HI': 'समझ', 'VI': 'Mức độ hiểu', 'ES': 'Comprensión', 'TH': 'ความเข้าใจ'},
  'Progress': {'JA': '進捗', 'ZH': '进度', 'FR': 'Progrès', 'DE': 'Fortschritt', 'RU': 'Прогресс', 'AR': 'التقدم', 'HI': 'प्रगति', 'VI': 'Tiến độ', 'ES': 'Progreso', 'TH': 'ความคืบหน้า'},
  'Difficulty': {'JA': '難易度', 'ZH': '难度', 'FR': 'Difficulté', 'DE': 'Schwierigkeit', 'RU': 'Сложность', 'AR': 'الصعوبة', 'HI': 'कठिनाई', 'VI': 'Độ khó', 'ES': 'Dificultad', 'TH': 'ความยาก'},
  'Stage': {'JA': '進行状況', 'ZH': '进行状况', 'FR': 'Étape', 'DE': 'Stadium', 'RU': 'Этап', 'AR': 'المرحلة', 'HI': 'चरण', 'VI': 'Giai đoạn', 'ES': 'Etapa', 'TH': 'ขั้นตอน'},
  'Blockers': {'JA': '障害', 'ZH': '障碍', 'FR': 'Obstacles', 'DE': 'Hindernisse', 'RU': 'Препятствия', 'AR': 'العوائق', 'HI': 'बाधाएं', 'VI': 'Trở ngại', 'ES': 'Obstáculos', 'TH': 'อุปสรรค'},
  'Type': {'JA': '種類', 'ZH': '种类', 'FR': 'Type', 'DE': 'Art', 'RU': 'Тип', 'AR': 'النوع', 'HI': 'प्रकार', 'VI': 'Loại', 'ES': 'Tipo', 'TH': 'ประเภท'},
  'Amount': {'JA': '量', 'ZH': '量', 'FR': 'Quantité', 'DE': 'Menge', 'RU': 'Количество', 'AR': 'الكمية', 'HI': 'मात्रा', 'VI': 'Số lượng', 'ES': 'Cantidad', 'TH': 'ปริมาณ'},
  'Quality': {'JA': '質', 'ZH': '质量', 'FR': 'Qualité', 'DE': 'Qualität', 'RU': 'Качество', 'AR': 'الجودة', 'HI': 'गुणवत्ता', 'VI': 'Chất lượng', 'ES': 'Calidad', 'TH': 'คุณภาพ'},
  'Wake-ups': {'JA': '中途覚醒', 'ZH': '中途醒来', 'FR': 'Réveils', 'DE': 'Aufwachen', 'RU': 'Пробуждения', 'AR': 'مرات الاستيقاظ', 'HI': 'बीच में जागना', 'VI': 'Thức giấc giữa chừng', 'ES': 'Despertares', 'TH': 'การตื่นกลางดึก'},
  'Satisfaction': {'JA': '満足度', 'ZH': '满意度', 'FR': 'Satisfaction', 'DE': 'Zufriedenheit', 'RU': 'Удовлетворённость', 'AR': 'الرضا', 'HI': 'संतुष्टि', 'VI': 'Sự hài lòng', 'ES': 'Satisfacción', 'TH': 'ความพึงพอใจ'},
  'Time Mgmt': {'JA': '時間管理', 'ZH': '时间管理', 'FR': 'Gestion du temps', 'DE': 'Zeitmanagement', 'RU': 'Управление временем', 'AR': 'إدارة الوقت', 'HI': 'समय प्रबंधन', 'VI': 'Quản lý thời gian', 'ES': 'Gestión del tiempo', 'TH': 'การจัดการเวลา'},
  'Refresh': {'JA': 'リフレッシュ度', 'ZH': '放松程度', 'FR': 'Ressourcement', 'DE': 'Erholung', 'RU': 'Восстановление', 'AR': 'الاسترخاء', 'HI': 'तरोताज़गी', 'VI': 'Mức độ thư giãn', 'ES': 'Recuperación', 'TH': 'ความสดชื่น'},
  'Recovery': {'JA': '回復感', 'ZH': '恢复感', 'FR': 'Récupération', 'DE': 'Erholungsgefühl', 'RU': 'Ощущение восстановления', 'AR': 'الشعور بالتعافي', 'HI': 'रिकवरी अनुभव', 'VI': 'Cảm giác phục hồi', 'ES': 'Sensación de recuperación', 'TH': 'ความรู้สึกฟื้นตัว'},
  'Activity': {'JA': '活動タイプ', 'ZH': '活动类型', 'FR': "Type d'activité", 'DE': 'Aktivitätstyp', 'RU': 'Тип активности', 'AR': 'نوع النشاط', 'HI': 'गतिविधि प्रकार', 'VI': 'Loại hoạt động', 'ES': 'Tipo de actividad', 'TH': 'ประเภทกิจกรรม'},
};

// 🆕 [2단계] 분야별 추가 질문 3개씩. 분야명이 categoryQuestions의 키와
// 정확히 일치해야 해당 질문이 나타남 (일치하지 않으면 2단계 자체가 생략됨).
final Map<String, List<CategoryQuestion>> categoryQuestions = {
  '운동': [
    CategoryQuestion(id: 'intensity', labelEn: 'Intensity', labelKo: '강도', options: ['낮음', '보통', '높음'], labelTranslations: _qLabelTranslations['Intensity']),
    CategoryQuestion(id: 'targetVsActual', labelEn: 'Vs Target', labelKo: '목표 대비', options: ['다함', '일부만', '초과'], labelTranslations: _qLabelTranslations['Vs Target']),
    CategoryQuestion(id: 'afterFeeling', labelEn: 'After Feeling', labelKo: '운동 후 몸 상태', options: ['가벼움', '보통', '힘듦'], labelTranslations: _qLabelTranslations['After Feeling']),
  ],
  '공부': [
    CategoryQuestion(id: 'understanding', labelEn: 'Understanding', labelKo: '이해도', options: ['낮음', '보통', '높음'], labelTranslations: _qLabelTranslations['Understanding']),
    CategoryQuestion(id: 'progress', labelEn: 'Progress', labelKo: '진도', options: ['계획대로', '못미침', '더함'], labelTranslations: _qLabelTranslations['Progress']),
    CategoryQuestion(id: 'difficulty', labelEn: 'Difficulty', labelKo: '난이도', options: ['쉬움', '보통', '어려움'], labelTranslations: _qLabelTranslations['Difficulty']),
  ],
  '독서': [
    CategoryQuestion(id: 'understanding', labelEn: 'Understanding', labelKo: '이해도', options: ['낮음', '보통', '높음'], labelTranslations: _qLabelTranslations['Understanding']),
    CategoryQuestion(id: 'progress', labelEn: 'Progress', labelKo: '진도', options: ['계획대로', '못미침', '더함'], labelTranslations: _qLabelTranslations['Progress']),
    CategoryQuestion(id: 'difficulty', labelEn: 'Difficulty', labelKo: '난이도', options: ['쉬움', '보통', '어려움'], labelTranslations: _qLabelTranslations['Difficulty']),
  ],
  '업무': [
    CategoryQuestion(id: 'difficulty', labelEn: 'Difficulty', labelKo: '난이도', options: ['쉬움', '보통', '어려움'], labelTranslations: _qLabelTranslations['Difficulty']),
    CategoryQuestion(id: 'stage', labelEn: 'Stage', labelKo: '진행상황', options: ['시작만', '진행중', '거의완료'], labelTranslations: _qLabelTranslations['Stage']),
    CategoryQuestion(id: 'blocker', labelEn: 'Blockers', labelKo: '막힌 부분', options: ['없음', '조금', '많이'], labelTranslations: _qLabelTranslations['Blockers']),
  ],
  '프로젝트': [
    CategoryQuestion(id: 'difficulty', labelEn: 'Difficulty', labelKo: '난이도', options: ['쉬움', '보통', '어려움'], labelTranslations: _qLabelTranslations['Difficulty']),
    CategoryQuestion(id: 'stage', labelEn: 'Stage', labelKo: '진행상황', options: ['시작만', '진행중', '거의완료'], labelTranslations: _qLabelTranslations['Stage']),
    CategoryQuestion(id: 'blocker', labelEn: 'Blockers', labelKo: '막힌 부분', options: ['없음', '조금', '많이'], labelTranslations: _qLabelTranslations['Blockers']),
  ],
  '식사': [
    CategoryQuestion(id: 'mealType', labelEn: 'Type', labelKo: '종류', options: ['집밥', '외식', '배달'], labelTranslations: _qLabelTranslations['Type']),
    CategoryQuestion(id: 'amount', labelEn: 'Amount', labelKo: '양', options: ['적게', '적당', '많이'], labelTranslations: _qLabelTranslations['Amount']),
    CategoryQuestion(id: 'afterFeeling', labelEn: 'After Feeling', labelKo: '식사 후 기분', options: ['개운함', '보통', '더부룩'], labelTranslations: _qLabelTranslations['After Feeling']),
  ],
  '수면': [
    CategoryQuestion(id: 'quality', labelEn: 'Quality', labelKo: '품질', options: ['나쁨', '보통', '좋음'], labelTranslations: _qLabelTranslations['Quality']),
    CategoryQuestion(id: 'wakeUps', labelEn: 'Wake-ups', labelKo: '중간에 깼는지', options: ['안깸', '1-2번', '여러번'], labelTranslations: _qLabelTranslations['Wake-ups']),
    CategoryQuestion(id: 'afterFeeling', labelEn: 'After Feeling', labelKo: '일어난 후 상태', options: ['피곤', '보통', '개운'], labelTranslations: _qLabelTranslations['After Feeling']),
  ],
  '게임': [
    CategoryQuestion(id: 'satisfaction', labelEn: 'Satisfaction', labelKo: '만족도', options: ['낮음', '보통', '높음'], labelTranslations: _qLabelTranslations['Satisfaction']),
    CategoryQuestion(id: 'timeManagement', labelEn: 'Time Mgmt', labelKo: '시간관리', options: ['적절', '초과함'], labelTranslations: _qLabelTranslations['Time Mgmt']),
    CategoryQuestion(id: 'refresh', labelEn: 'Refresh', labelKo: '재충전 정도', options: ['별로', '보통', '많이'], labelTranslations: _qLabelTranslations['Refresh']),
  ],
  '취미': [
    CategoryQuestion(id: 'satisfaction', labelEn: 'Satisfaction', labelKo: '만족도', options: ['낮음', '보통', '높음'], labelTranslations: _qLabelTranslations['Satisfaction']),
    CategoryQuestion(id: 'timeManagement', labelEn: 'Time Mgmt', labelKo: '시간관리', options: ['적절', '초과함'], labelTranslations: _qLabelTranslations['Time Mgmt']),
    CategoryQuestion(id: 'refresh', labelEn: 'Refresh', labelKo: '재충전 정도', options: ['별로', '보통', '많이'], labelTranslations: _qLabelTranslations['Refresh']),
  ],
  '휴식': [
    CategoryQuestion(id: 'recovery', labelEn: 'Recovery', labelKo: '회복느낌', options: ['별로', '보통', '많이'], labelTranslations: _qLabelTranslations['Recovery']),
    CategoryQuestion(id: 'activityType', labelEn: 'Activity', labelKo: '활동유형', options: ['누워쉼', '산책', '기타'], labelTranslations: _qLabelTranslations['Activity']),
    CategoryQuestion(id: 'refresh', labelEn: 'Refresh', labelKo: '재충전 정도', options: ['별로', '보통', '충분'], labelTranslations: _qLabelTranslations['Refresh']),
  ],
};

// 🆕 [1단계] 방해요인 공통 선택지 (다중선택, '없음' 필수 포함)
const List<String> disruptionOptions = ['전화/문자', '딴생각', '피곤함', '배고픔', '소음', '없음'];

// 🆕 [1단계] 에너지 레벨 선택지
const List<String> energyLevelOptions = ['낮음', '보통', '높음'];

// 🆕 만족도 이모지 (1~5)
const List<String> satisfactionEmojis = ['😞', '😐', '🙂', '😊', '🤩'];
