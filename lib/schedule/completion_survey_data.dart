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

  const CategoryQuestion({required this.id, required this.labelEn, required this.labelKo, required this.options});
}

// 🆕 [2단계] 분야별 추가 질문 3개씩. 분야명이 categoryQuestions의 키와
// 정확히 일치해야 해당 질문이 나타남 (일치하지 않으면 2단계 자체가 생략됨).
const Map<String, List<CategoryQuestion>> categoryQuestions = {
  '운동': [
    CategoryQuestion(id: 'intensity', labelEn: 'Intensity', labelKo: '강도', options: ['낮음', '보통', '높음']),
    CategoryQuestion(id: 'targetVsActual', labelEn: 'Vs Target', labelKo: '목표 대비', options: ['다함', '일부만', '초과']),
    CategoryQuestion(id: 'afterFeeling', labelEn: 'After Feeling', labelKo: '운동 후 몸 상태', options: ['가벼움', '보통', '힘듦']),
  ],
  '공부': [
    CategoryQuestion(id: 'understanding', labelEn: 'Understanding', labelKo: '이해도', options: ['낮음', '보통', '높음']),
    CategoryQuestion(id: 'progress', labelEn: 'Progress', labelKo: '진도', options: ['계획대로', '못미침', '더함']),
    CategoryQuestion(id: 'difficulty', labelEn: 'Difficulty', labelKo: '난이도', options: ['쉬움', '보통', '어려움']),
  ],
  '독서': [
    CategoryQuestion(id: 'understanding', labelEn: 'Understanding', labelKo: '이해도', options: ['낮음', '보통', '높음']),
    CategoryQuestion(id: 'progress', labelEn: 'Progress', labelKo: '진도', options: ['계획대로', '못미침', '더함']),
    CategoryQuestion(id: 'difficulty', labelEn: 'Difficulty', labelKo: '난이도', options: ['쉬움', '보통', '어려움']),
  ],
  '업무': [
    CategoryQuestion(id: 'difficulty', labelEn: 'Difficulty', labelKo: '난이도', options: ['쉬움', '보통', '어려움']),
    CategoryQuestion(id: 'stage', labelEn: 'Stage', labelKo: '진행상황', options: ['시작만', '진행중', '거의완료']),
    CategoryQuestion(id: 'blocker', labelEn: 'Blockers', labelKo: '막힌 부분', options: ['없음', '조금', '많이']),
  ],
  '프로젝트': [
    CategoryQuestion(id: 'difficulty', labelEn: 'Difficulty', labelKo: '난이도', options: ['쉬움', '보통', '어려움']),
    CategoryQuestion(id: 'stage', labelEn: 'Stage', labelKo: '진행상황', options: ['시작만', '진행중', '거의완료']),
    CategoryQuestion(id: 'blocker', labelEn: 'Blockers', labelKo: '막힌 부분', options: ['없음', '조금', '많이']),
  ],
  '식사': [
    CategoryQuestion(id: 'mealType', labelEn: 'Type', labelKo: '종류', options: ['집밥', '외식', '배달']),
    CategoryQuestion(id: 'amount', labelEn: 'Amount', labelKo: '양', options: ['적게', '적당', '많이']),
    CategoryQuestion(id: 'afterFeeling', labelEn: 'After Feeling', labelKo: '식사 후 기분', options: ['개운함', '보통', '더부룩']),
  ],
  '수면': [
    CategoryQuestion(id: 'quality', labelEn: 'Quality', labelKo: '품질', options: ['나쁨', '보통', '좋음']),
    CategoryQuestion(id: 'wakeUps', labelEn: 'Wake-ups', labelKo: '중간에 깼는지', options: ['안깸', '1-2번', '여러번']),
    CategoryQuestion(id: 'afterFeeling', labelEn: 'After Feeling', labelKo: '일어난 후 상태', options: ['피곤', '보통', '개운']),
  ],
  '게임': [
    CategoryQuestion(id: 'satisfaction', labelEn: 'Satisfaction', labelKo: '만족도', options: ['낮음', '보통', '높음']),
    CategoryQuestion(id: 'timeManagement', labelEn: 'Time Mgmt', labelKo: '시간관리', options: ['적절', '초과함']),
    CategoryQuestion(id: 'refresh', labelEn: 'Refresh', labelKo: '재충전 정도', options: ['별로', '보통', '많이']),
  ],
  '취미': [
    CategoryQuestion(id: 'satisfaction', labelEn: 'Satisfaction', labelKo: '만족도', options: ['낮음', '보통', '높음']),
    CategoryQuestion(id: 'timeManagement', labelEn: 'Time Mgmt', labelKo: '시간관리', options: ['적절', '초과함']),
    CategoryQuestion(id: 'refresh', labelEn: 'Refresh', labelKo: '재충전 정도', options: ['별로', '보통', '많이']),
  ],
  '휴식': [
    CategoryQuestion(id: 'recovery', labelEn: 'Recovery', labelKo: '회복느낌', options: ['별로', '보통', '많이']),
    CategoryQuestion(id: 'activityType', labelEn: 'Activity', labelKo: '활동유형', options: ['누워쉼', '산책', '기타']),
    CategoryQuestion(id: 'refresh', labelEn: 'Refresh', labelKo: '재충전 정도', options: ['별로', '보통', '충분']),
  ],
};

// 🆕 [1단계] 방해요인 공통 선택지 (다중선택, '없음' 필수 포함)
const List<String> disruptionOptions = ['전화/문자', '딴생각', '피곤함', '배고픔', '소음', '없음'];

// 🆕 [1단계] 에너지 레벨 선택지
const List<String> energyLevelOptions = ['낮음', '보통', '높음'];

// 🆕 만족도 이모지 (1~5)
const List<String> satisfactionEmojis = ['😞', '😐', '🙂', '😊', '🤩'];
