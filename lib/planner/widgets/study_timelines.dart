// [주석] GKE StudyUp - 스터디 타임라인 데이터 통합 관리 파일
class StudyTimelines {

  // ==========================================
  // 3. EXAM_PREP_PERIOD: 중간/기말 준비 타임라인 변수 (누락분 3주 전 평일/주말 복구 완료)
  // ==========================================
  static final List<Map<String, String>> midTermWeek4Weekday = [{'time': '06:00', 'task': '중간고사 준비 4주전 평일'}];
  static final List<Map<String, String>> midTermWeek4Weekend = [{'time': '06:00', 'task': '중간고사 준비 4주전 주말'}];
  static final List<Map<String, String>> midTermWeek3Weekday = [{'time': '06:00', 'task': '중간고사 준비 3주전 평일'}]; // 👈 누락분 복구
  static final List<Map<String, String>> midTermWeek3Weekend = [{'time': '06:00', 'task': '중간고사 준비 3주전 주말'}]; // 👈 누락분 복구
  static final List<Map<String, String>> midTermWeek2Weekday = [{'time': '06:00', 'task': '중간고사 준비 2주전 평일'}];
  static final List<Map<String, String>> midTermWeek2Weekend = [{'time': '06:00', 'task': '중간고사 준비 2주전 주말'}];
  static final List<Map<String, String>> midTermWeek1Weekday = [{'time': '06:00', 'task': '중간고사 준비 1주전 평일'}];
  static final List<Map<String, String>> midTermWeek1Saturday = [{'time': '06:00', 'task': '중간고사 준비 1주전 토요일'}];
  static final List<Map<String, String>> midTermWeek1Sunday = [{'time': '06:00', 'task': '중간고사 준비 1주전 일요일'}];

  static final List<Map<String, String>> finalTermWeek4Weekday = [{'time': '06:00', 'task': '기말고사 준비 4주전 평일'}];
  static final List<Map<String, String>> finalTermWeek4Weekend = [{'time': '06:00', 'task': '기말고사 준비 4주전 주말'}];
  static final List<Map<String, String>> finalTermWeek3Weekday = [{'time': '06:00', 'task': '기말고사 준비 3주전 평일'}];
  static final List<Map<String, String>> finalTermWeek3Weekend = [{'time': '06:00', 'task': '기말고사 준비 3주전 주말'}];
  static final List<Map<String, String>> finalTermWeek2Weekday = [{'time': '06:00', 'task': '기말고사 준비 2주전 평일'}];
  static final List<Map<String, String>> finalTermWeek2Weekend = [{'time': '06:00', 'task': '기말고사 준비 2주전 주말'}];
  static final List<Map<String, String>> finalTermWeek1Weekday = [{'time': '06:00', 'task': '기말고사 준비 1주전 평일'}];
  static final List<Map<String, String>> finalTermWeek1Saturday = [{'time': '06:00', 'task': '기말고사 준비 1주전 토요일'}];
  static final List<Map<String, String>> finalTermWeek1Sunday = [{'time': '06:00', 'task': '기말고사 준비 1주전 일요일'}];

  // ==========================================
  // 4. EXAM_DAY_TRACK: 시험 당일 요일별 타임라인 데이터 (월~금)
  // ==========================================
  static final List<Map<String, String>> midMonD3 = [{'time': '06:00', 'task': '중간 월요 D-3'}];
  static final List<Map<String, String>> midMonD2 = [{'time': '06:00', 'task': '중간 월요 D-2'}];
  static final List<Map<String, String>> midMonD1 = [{'time': '06:00', 'task': '중간 월요 D-1'}];
  static final List<Map<String, String>> midMonDDay = [{'time': '06:00', 'task': '중간 월요 D-Day'}];
  static final List<Map<String, String>> midMonDPlus1 = [{'time': '06:00', 'task': '중간 월요 D+1'}];
  static final List<Map<String, String>> midMonDPlus2 = [{'time': '06:00', 'task': '중간 월요 D+2'}];
  static final List<Map<String, String>> midMonDPlus3 = [{'time': '06:00', 'task': '중간 월요 D+3'}];

  static final List<Map<String, String>> midTueD3 = [{'time': '06:00', 'task': '중간 화요 D-3'}];
  static final List<Map<String, String>> midTueD2 = [{'time': '06:00', 'task': '중간 화요 D-2'}];
  static final List<Map<String, String>> midTueD1 = [{'time': '06:00', 'task': '중간 화요 D-1'}];
  static final List<Map<String, String>> midTueDDay = [{'time': '06:00', 'task': '중간 화요 D-Day'}];
  static final List<Map<String, String>> midTueDPlus1 = [{'time': '06:00', 'task': '중간 화요 D+1'}];
  static final List<Map<String, String>> midTueDPlus2 = [{'time': '06:00', 'task': '중간 화요 D+2'}];
  static final List<Map<String, String>> midTueDPlus3 = [{'time': '06:00', 'task': '중간 화요 D+3'}];

  static final List<Map<String, String>> midWedD3 = [{'time': '06:00', 'task': '중간 수요 D-3'}];
  static final List<Map<String, String>> midWedD2 = [{'time': '06:00', 'task': '중간 수요 D-2'}];
  static final List<Map<String, String>> midWedD1 = [{'time': '06:00', 'task': '중간 수요 D-1'}];
  static final List<Map<String, String>> midWedDDay = [{'time': '06:00', 'task': '중간 수요 D-Day'}];
  static final List<Map<String, String>> midWedDPlus1 = [{'time': '06:00', 'task': '중간 수요 D+1'}];
  static final List<Map<String, String>> midWedDPlus2 = [{'time': '06:00', 'task': '중간 수요 D+2'}];
  static final List<Map<String, String>> midWedDPlus3 = [{'time': '06:00', 'task': '중간 수요 D+3'}];
  static final List<Map<String, String>> midWedDPlus4 = [{'time': '06:00', 'task': '중간 수요 D+4'}];

  static final List<Map<String, String>> midThuD3 = [{'time': '06:00', 'task': '중간 목요 D-3'}];
  static final List<Map<String, String>> midThuD2 = [{'time': '06:00', 'task': '중간 목요 D-2'}];
  static final List<Map<String, String>> midThuD1 = [{'time': '06:00', 'task': '중간 목요 D-1'}];
  static final List<Map<String, String>> midThuDDay = [{'time': '06:00', 'task': '중간 목요 D-Day'}];
  static final List<Map<String, String>> midThuDPlus1 = [{'time': '06:00', 'task': '중간 목요 D+1'}];
  static final List<Map<String, String>> midThuDPlus2 = [{'time': '06:00', 'task': '중간 목요 D+2'}];
  static final List<Map<String, String>> midThuDPlus3 = [{'time': '06:00', 'task': '중간 목요 D+3'}];
  static final List<Map<String, String>> midThuDPlus4 = [{'time': '06:00', 'task': '중간 목요 D+4'}];

  static final List<Map<String, String>> midFriD3 = [{'time': '06:00', 'task': '중간 금요 D-3'}];
  static final List<Map<String, String>> midFriD2 = [{'time': '06:00', 'task': '중간 금요 D-2'}];
  static final List<Map<String, String>> midFriD1 = [{'time': '06:00', 'task': '중간 금요 D-1'}];
  static final List<Map<String, String>> midFriDDay = [{'time': '06:00', 'task': '중간 금요 D-Day'}];
  static final List<Map<String, String>> midFriDPlus1 = [{'time': '06:00', 'task': '중간 금요 D+1'}];
  static final List<Map<String, String>> midFriDPlus2 = [{'time': '06:00', 'task': '중간 금요 D+2'}];
  static final List<Map<String, String>> midFriDPlus3 = [{'time': '06:00', 'task': '중간 금요 D+3'}];
  static final List<Map<String, String>> midFriDPlus4 = [{'time': '06:00', 'task': '중간 금요 D+4'}];

  static final List<Map<String, String>> finalMonD3 = [{'time': '06:00', 'task': '기말 월요 D-3'}];
  static final List<Map<String, String>> finalMonD2 = [{'time': '06:00', 'task': '기말 월요 D-2'}];
  static final List<Map<String, String>> finalMonD1 = [{'time': '06:00', 'task': '기말 월요 D-1'}];
  static final List<Map<String, String>> finalMonDDay = [{'time': '06:00', 'task': '기말 월요 D-Day'}];
  static final List<Map<String, String>> finalMonDPlus1 = [{'time': '06:00', 'task': '기말 월요 D+1'}];
  static final List<Map<String, String>> finalMonDPlus2 = [{'time': '06:00', 'task': '기말 월요 D+2'}];
  static final List<Map<String, String>> finalMonDPlus3 = [{'time': '06:00', 'task': '기말 월요 D+3'}];

  static final List<Map<String, String>> finalTueD3 = [{'time': '06:00', 'task': '기말 화요 D-3'}];
  static final List<Map<String, String>> finalTueD2 = [{'time': '06:00', 'task': '기말 화요 D-2'}];
  static final List<Map<String, String>> finalTueD1 = [{'time': '06:00', 'task': '기말 화요 D-1'}];
  static final List<Map<String, String>> finalTueDDay = [{'time': '06:00', 'task': '기말 화요 D-Day'}];
  static final List<Map<String, String>> finalTueDPlus1 = [{'time': '06:00', 'task': '기말 화요 D+1'}];
  static final List<Map<String, String>> finalTueDPlus2 = [{'time': '06:00', 'task': '기말 화요 D+2'}];
  static final List<Map<String, String>> finalTueDPlus3 = [{'time': '06:00', 'task': '기말 화요 D+3'}];

  static final List<Map<String, String>> finalWedD3 = [{'time': '06:00', 'task': '기말 수요 D-3'}];
  static final List<Map<String, String>> finalWedD2 = [{'time': '06:00', 'task': '기말 수요 D-2'}];
  static final List<Map<String, String>> finalWedD1 = [{'time': '06:00', 'task': '기말 수요 D-1'}];
  static final List<Map<String, String>> finalWedDDay = [{'time': '06:00', 'task': '기말 수요 D-Day'}];
  static final List<Map<String, String>> finalWedDPlus1 = [{'time': '06:00', 'task': '기말 수요 D+1'}];
  static final List<Map<String, String>> finalWedDPlus2 = [{'time': '06:00', 'task': '기말 수요 D+2'}];
  static final List<Map<String, String>> finalWedDPlus3 = [{'time': '06:00', 'task': '기말 수요 D+3'}];
  static final List<Map<String, String>> finalWedDPlus4 = [{'time': '06:00', 'task': '기말 수요 D+4'}];

  static final List<Map<String, String>> finalThuD3 = [{'time': '06:00', 'task': '기말 목요 D-3'}];
  static final List<Map<String, String>> finalThuD2 = [{'time': '06:00', 'task': '기말 목요 D-2'}];
  static final List<Map<String, String>> finalThuD1 = [{'time': '06:00', 'task': '기말 목요 D-1'}];
  static final List<Map<String, String>> finalThuDDay = [{'time': '06:00', 'task': '기말 목요 D-Day'}];
  static final List<Map<String, String>> finalThuDPlus1 = [{'time': '06:00', 'task': '기말 목요 D+1'}];
  static final List<Map<String, String>> finalThuDPlus2 = [{'time': '06:00', 'task': '기말 목요 D+2'}];
  static final List<Map<String, String>> finalThuDPlus3 = [{'time': '06:00', 'task': '기말 목요 D+3'}];
  static final List<Map<String, String>> finalThuDPlus4 = [{'time': '06:00', 'task': '기말 목요 D+4'}];

  static final List<Map<String, String>> finalFriD3 = [{'time': '06:00', 'task': '기말 금요 D-3'}];
  static final List<Map<String, String>> finalFriD2 = [{'time': '06:00', 'task': '기말 금요 D-2'}];
  static final List<Map<String, String>> finalFriD1 = [{'time': '06:00', 'task': '기말 금요 D-1'}];
  static final List<Map<String, String>> finalFriDDay = [{'time': '06:00', 'task': '기말 금요 D-Day'}];
  static final List<Map<String, String>> finalFriDPlus1 = [{'time': '06:00', 'task': '기말 금요 D+1'}];
  static final List<Map<String, String>> finalFriDPlus2 = [{'time': '06:00', 'task': '기말 금요 D+2'}];
  static final List<Map<String, String>> finalFriDPlus3 = [{'time': '06:00', 'task': '기말 금요 D+3'}];
  static final List<Map<String, String>> finalFriDPlus4 = [{'time': '06:00', 'task': '기말 금요 D+4'}];

// ==========================================
// 5. getTimelineForDate: D-day 요일 및 우선순위 충돌 제어 매칭 메서드
// [수정] 더미 데이터 대신 StudyTimelinesMidTermAllDays의 실제 상세 시간표를 연결
// ==========================================
  static List<Map<String, String>> getTimelineForDate(
      DateTime selectedDate,
      DateTime examDDay, {
        bool isExamPeriod = true,
        bool isActualExamWeek = true,
        bool isFinalExam = false,
      }) {
    int differenceInDays = selectedDate.difference(examDDay).inDays;
    int dDayWeekday = examDDay.weekday; // 1: 월, 2: 화, 3: 수, 4: 목, 5: 금

    if (isExamPeriod && isActualExamWeek) {
      if (!isFinalExam) {
        // ---------- 중간고사 ----------
        if (dDayWeekday == 1) {
          switch (differenceInDays) {
            case -3: return StudyTimelinesMidTermAllDays.midMonD3;
            case -2: return StudyTimelinesMidTermAllDays.midMonD2;
            case -1: return StudyTimelinesMidTermAllDays.midMonD1;
            case 0:  return StudyTimelinesMidTermAllDays.midMonDDay;
            case 1:  return StudyTimelinesMidTermAllDays.midMonDPlus1;
            case 2:  return StudyTimelinesMidTermAllDays.midMonDPlus2;
            case 3:  return StudyTimelinesMidTermAllDays.midMonDPlus3;
          }
        } else if (dDayWeekday == 2) {
          switch (differenceInDays) {
            case -3: return StudyTimelinesMidTermAllDays.midTueD3;
            case -2: return StudyTimelinesMidTermAllDays.midTueD2;
            case -1: return StudyTimelinesMidTermAllDays.midTueD1;
            case 0:  return StudyTimelinesMidTermAllDays.midTueDDay;
            case 1:  return StudyTimelinesMidTermAllDays.midTueDPlus1;
            case 2:  return StudyTimelinesMidTermAllDays.midTueDPlus2;
            case 3:  return StudyTimelinesMidTermAllDays.midTueDPlus3;
          }
        } else if (dDayWeekday == 3) {
          switch (differenceInDays) {
            case -3: return StudyTimelinesMidTermAllDays.midWedD3;
            case -2: return StudyTimelinesMidTermAllDays.midWedD2;
            case -1: return StudyTimelinesMidTermAllDays.midWedD1;
            case 0:  return StudyTimelinesMidTermAllDays.midWedDDay;
            case 1:  return StudyTimelinesMidTermAllDays.midWedDPlus1;
            case 2:  return StudyTimelinesMidTermAllDays.midWedDPlus2;
            case 3:  return StudyTimelinesMidTermAllDays.midWedDPlus3;
            case 4:  return StudyTimelinesMidTermAllDays.midWedDPlus4;
          }
        } else if (dDayWeekday == 4) {
          switch (differenceInDays) {
            case -3: return StudyTimelinesMidTermAllDays.midThuD3;
            case -2: return StudyTimelinesMidTermAllDays.midThuD2;
            case -1: return StudyTimelinesMidTermAllDays.midThuD1;
            case 0:  return StudyTimelinesMidTermAllDays.midThuDDay;
            case 1:  return StudyTimelinesMidTermAllDays.midThuDPlus1;
            case 2:  return StudyTimelinesMidTermAllDays.midThuDPlus2;
            case 3:  return StudyTimelinesMidTermAllDays.midThuDPlus3;
            case 4:  return StudyTimelinesMidTermAllDays.midThuDPlus4;
          }
        } else if (dDayWeekday == 5) {
          switch (differenceInDays) {
            case -3: return StudyTimelinesMidTermAllDays.midFriD3;
            case -2: return StudyTimelinesMidTermAllDays.midFriD2;
            case -1: return StudyTimelinesMidTermAllDays.midFriD1;
            case 0:  return StudyTimelinesMidTermAllDays.midFriDDay;
            case 1:  return StudyTimelinesMidTermAllDays.midFriDPlus1;
            case 2:  return StudyTimelinesMidTermAllDays.midFriDPlus2;
            case 3:  return StudyTimelinesMidTermAllDays.midFriDPlus3;
            case 4:  return StudyTimelinesMidTermAllDays.midFriDPlus4;
          }
        }
      } else {
        // ---------- 기말고사 ----------
        if (dDayWeekday == 1) {
          switch (differenceInDays) {
            case -3: return StudyTimelinesMidTermAllDays.finalMonD3;
            case -2: return StudyTimelinesMidTermAllDays.finalMonD2;
            case -1: return StudyTimelinesMidTermAllDays.finalMonD1;
            case 0:  return StudyTimelinesMidTermAllDays.finalMonDDay;
            case 1:  return StudyTimelinesMidTermAllDays.finalMonDPlus1;
            case 2:  return StudyTimelinesMidTermAllDays.finalMonDPlus2;
            case 3:  return StudyTimelinesMidTermAllDays.finalMonDPlus3;
          }
        } else if (dDayWeekday == 2) {
          switch (differenceInDays) {
            case -3: return StudyTimelinesMidTermAllDays.finalTueD3;
            case -2: return StudyTimelinesMidTermAllDays.finalTueD2;
            case -1: return StudyTimelinesMidTermAllDays.finalTueD1;
            case 0:  return StudyTimelinesMidTermAllDays.finalTueDDay;
            case 1:  return StudyTimelinesMidTermAllDays.finalTueDPlus1;
            case 2:  return StudyTimelinesMidTermAllDays.finalTueDPlus2;
            case 3:  return StudyTimelinesMidTermAllDays.finalTueDPlus3;
          }
        } else if (dDayWeekday == 3) {
          switch (differenceInDays) {
            case -3: return StudyTimelinesMidTermAllDays.finalWedD3;
            case -2: return StudyTimelinesMidTermAllDays.finalWedD2;
            case -1: return StudyTimelinesMidTermAllDays.finalWedD1;
            case 0:  return StudyTimelinesMidTermAllDays.finalWedDDay;
            case 1:  return StudyTimelinesMidTermAllDays.finalWedDPlus1;
            case 2:  return StudyTimelinesMidTermAllDays.finalWedDPlus2;
            case 3:  return StudyTimelinesMidTermAllDays.finalWedDPlus3;
            case 4:  return StudyTimelinesMidTermAllDays.finalWedDPlus4;
          }
        } else if (dDayWeekday == 4) {
          switch (differenceInDays) {
            case -3: return StudyTimelinesMidTermAllDays.finalThuD3;
            case -2: return StudyTimelinesMidTermAllDays.finalThuD2;
            case -1: return StudyTimelinesMidTermAllDays.finalThuD1;
            case 0:  return StudyTimelinesMidTermAllDays.finalThuDDay;
            case 1:  return StudyTimelinesMidTermAllDays.finalThuDPlus1;
            case 2:  return StudyTimelinesMidTermAllDays.finalThuDPlus2;
            case 3:  return StudyTimelinesMidTermAllDays.finalThuDPlus3;
            case 4:  return StudyTimelinesMidTermAllDays.finalThuDPlus4;
          }
        } else if (dDayWeekday == 5) {
          switch (differenceInDays) {
            case -3: return StudyTimelinesMidTermAllDays.finalFriD3;
            case -2: return StudyTimelinesMidTermAllDays.finalFriD2;
            case -1: return StudyTimelinesMidTermAllDays.finalFriD1;
            case 0:  return StudyTimelinesMidTermAllDays.finalFriDDay;
            case 1:  return StudyTimelinesMidTermAllDays.finalFriDPlus1;
            case 2:  return StudyTimelinesMidTermAllDays.finalFriDPlus2;
            case 3:  return StudyTimelinesMidTermAllDays.finalFriDPlus3;
            case 4:  return StudyTimelinesMidTermAllDays.finalFriDPlus4;
          }
        }
      }
    }

    // 기본값 (시험 기간 외 일반 타임라인)
    return isFinalExam ? StudyTimelinesMidTermAllDays.finalMonDDay : StudyTimelinesMidTermAllDays.midMonDDay;
  }


  // 1. NOMAL_PERIOD: 평상시 기본 타임라인 (월~일)
  static final Map<String, List<Map<String, String>>> normalPeriod = {
    'Monday': [
      {'time': '06:00 ~ 06:30', 'task': '기상 및 체조'},
      {'time': '06:30 ~ 07:00', 'task': '아침식사'},
      {'time': '07:00 ~ 08:00', 'task': '0)아침 사회.세계사.역사 보기'},
      {'time': '08:00 ~ 16:00', 'task': '즐거운 학교생활'},
      {'time': '16:00 ~ 17:00', 'task': '휴식'},
      {'time': '17:00 ~ 17:50', 'task': '1)영어(GM) 집중 학습 (50분)'},
      {'time': '17:50 ~ 18:00', 'task': '휴식 (10분)'},
      {'time': '18:00 ~ 19:00', 'task': '저녁식사 및 휴식 (60분)'},
      {'time': '19:00 ~ 19:50', 'task': '2)수학(이2-2) 집중 학습 (50분)'},
      {'time': '19:50 ~ 20:00', 'task': '휴식 (10분)'},
      {'time': '20:00 ~ 20:50', 'task': '3)고등수학 집중 학습 (50분)'},
      {'time': '20:50 ~ 21:00', 'task': '휴식 (10분)'},
      {'time': '21:00 ~ 21:50', 'task': '4)과학 집중 학습 (50분)'},
      {'time': '21:50 ~ 22:00', 'task': '휴식 (10분)'},
      {'time': '22:00 ~ 22:50', 'task': '5)수학(최블) 집중 학습 (50분)'},
      {'time': '22:50 ~ 23:00', 'task': '휴식 취침준비'},
      {'time': '23:00 ~ 06:00', 'task': '취침'},
    ],
    'Tuesday': [
      {'time': '06:00 ~ 06:30', 'task': '기상 및 체조'},
      {'time': '06:30 ~ 07:00', 'task': '아침식사'},
      {'time': '07:00 ~ 08:00', 'task': '0)아침 사회.세계사.역사 보기'},
      {'time': '08:00 ~ 16:00', 'task': '즐거운 학교생활'},
      {'time': '16:00 ~ 17:00', 'task': '휴식'},
      {'time': '17:00 ~ 17:50', 'task': '1)영어(RC) 집중 학습 (50분)'},
      {'time': '17:50 ~ 18:00', 'task': '휴식 (10분)'},
      {'time': '18:00 ~ 19:00', 'task': '저녁식사 및 휴식 (60분)'},
      {'time': '19:00 ~ 19:50', 'task': '2)수학(이3) 집중 학습 (50분)'},
      {'time': '19:50 ~ 20:00', 'task': '휴식 (10분)'},
      {'time': '20:00 ~ 20:50', 'task': '3)국어 집중 학습 (50분)'},
      {'time': '20:50 ~ 21:00', 'task': '휴식 (10분)'},
      {'time': '21:00 ~ 21:50', 'task': '4)과학 집중 학습 (50분)'},
      {'time': '21:50 ~ 22:00', 'task': '휴식 (10분)'},
      {'time': '22:00 ~ 22:50', 'task': '5)수학(A급) 집중 학습 (50분)'},
      {'time': '22:50 ~ 23:00', 'task': '휴식 취침준비'},
      {'time': '23:00 ~ 06:00', 'task': '취침'},
    ],
    'Wednesday': [
      {'time': '06:00 ~ 06:30', 'task': '기상 및 체조'},
      {'time': '06:30 ~ 07:00', 'task': '아침식사'},
      {'time': '07:00 ~ 08:00', 'task': '0)아침 사회.세계사.역사 보기'},
      {'time': '08:00 ~ 16:00', 'task': '즐거운 학교생활'},
      {'time': '16:00 ~ 17:00', 'task': '휴식'},
      {'time': '17:00 ~ 17:50', 'task': '1)영어(GR) 집중 학습 (50분)'},
      {'time': '17:50 ~ 18:00', 'task': '휴식 (10분)'},
      {'time': '18:00 ~ 19:00', 'task': '저녁식사 및 휴식 (60분)'},
      {'time': '19:00 ~ 19:50', 'task': '2)수학(이2-2) 집중 학습 (50분)'},
      {'time': '19:50 ~ 20:00', 'task': '휴식 (10분)'},
      {'time': '20:00 ~ 20:50', 'task': '3)영어(L/C) 집중 학습 (50분)'},
      {'time': '20:50 ~ 21:00', 'task': '휴식 (10분)'},
      {'time': '21:00 ~ 21:50', 'task': '4)고등수학 집중 학습 (50분)'},
      {'time': '21:50 ~ 22:00', 'task': '휴식 (10분)'},
      {'time': '22:00 ~ 22:50', 'task': '5)수학(최블) 집중 학습 (50분)'},
      {'time': '22:50 ~ 23:00', 'task': '휴식 취침준비'},
      {'time': '23:00 ~ 23:30', 'task': '취침'},
    ],
    'Thursday': [
      {'time': '06:00 ~ 06:30', 'task': '기상 및 체조'},
      {'time': '06:30 ~ 07:00', 'task': '아침식사'},
      {'time': '07:00 ~ 08:00', 'task': '0)아침 사회.세계사.역사 보기'},
      {'time': '08:00 ~ 16:00', 'task': '즐거운 학교생활'},
      {'time': '16:00 ~ 17:00', 'task': '휴식'},
      {'time': '17:00 ~ 17:50', 'task': '1)영어(RC) 집중 학습 (50분)'},
      {'time': '17:50 ~ 18:00', 'task': '휴식 (10분)'},
      {'time': '18:00 ~ 19:00', 'task': '저녁식사 및 휴식 (60분)'},
      {'time': '19:00 ~ 19:50', 'task': '2)수학(A급) 집중 학습 (50분)'},
      {'time': '19:50 ~ 20:00', 'task': '휴식 (10분)'},
      {'time': '20:00 ~ 20:50', 'task': '3)국어 집중 학습 (50분)'},
      {'time': '20:50 ~ 21:00', 'task': '휴식 (10분)'},
      {'time': '21:00 ~ 21:50', 'task': '4)과학 집중 학습 (50분)'},
      {'time': '21:50 ~ 22:00', 'task': '휴식 (10분)'},
      {'time': '22:00 ~ 22:50', 'task': '5)수학(최블) 집중 학습 (50분)'},
      {'time': '22:50 ~ 23:00', 'task': '휴식 취침준비'},
      {'time': '23:00 ~ 06:00', 'task': '취침'},
    ],
    'Friday': [
      {'time': '06:00 ~ 06:30', 'task': '기상 및 체조'},
      {'time': '06:30 ~ 07:00', 'task': '아침식사'},
      {'time': '07:00 ~ 08:00', 'task': '0)아침 사회.세계사.역사 보기'},
      {'time': '08:00 ~ 16:00', 'task': '즐거운 학교생활'},
      {'time': '16:00 ~ 17:00', 'task': '휴식'},
      {'time': '17:00 ~ 17:50', 'task': '1)영어(GM) 집중 학습 (50분)'},
      {'time': '17:50 ~ 18:00', 'task': '휴식 (10분)'},
      {'time': '18:00 ~ 19:00', 'task': '저녁식사 및 휴식 (60분)'},
      {'time': '19:00 ~ 19:50', 'task': '2)수학(이3) 집중 학습 (50분)'},
      {'time': '19:50 ~ 20:00', 'task': '휴식 (10분)'},
      {'time': '20:00 ~ 20:50', 'task': '3)영어(L/C) 집중 학습 (50분)'},
      {'time': '20:50 ~ 21:00', 'task': '휴식 (10분)'},
      {'time': '21:00 ~ 21:50', 'task': '4)고등수학 집중 학습 (50분)'},
      {'time': '21:50 ~ 22:00', 'task': '휴식 (10분)'},
      {'time': '22:00 ~ 22:50', 'task': '5)수학(A급) 집중 학습 (50분)'},
      {'time': '22:50 ~ 23:00', 'task': '휴식 취침준비'},
      {'time': '23:00 ~ 06:00', 'task': '취침'},
    ],
    'Saturday': [
      {'time': '07:00 ~ 08:00', 'task': '기상 + 가벼운 운동 / 아침식사'},
      {'time': '08:00 ~ 09:00', 'task': '1)사회 (60분)'},
      {'time': '09:00 ~ 09:20', 'task': '휴식 (20분)'},
      {'time': '09:20 ~ 10:20', 'task': '2)영어(RC) (60분)'},
      {'time': '10:20 ~ 10:40', 'task': '휴식 (20분)'},
      {'time': '10:40 ~ 11:40', 'task': '3)수학(A급) (60분)'},
      {'time': '11:40 ~ 13:00', 'task': '점심 및 휴식 (80분)'},
      {'time': '13:00 ~ 14:00', 'task': '4)국어 (60분)'},
      {'time': '14:00 ~ 14:20', 'task': '휴식 (20분)'},
      {'time': '14:20 ~ 15:20', 'task': '5)과학 (60분)'},
      {'time': '15:20 ~ 15:40', 'task': '휴식 (20분)'},
      {'time': '15:40 ~ 16:40', 'task': '6)수학(이유2) (60분)'},
      {'time': '16:40 ~ 17:00', 'task': '휴식 (20분)'},
      {'time': '17:00 ~ 17:50', 'task': '과학 학습단원 평가 (50분)'},
      {'time': '17:50 ~ 19:00', 'task': '저녁식사 및 휴식 (60분)'},
      {'time': '19:00 ~ 19:50', 'task': '사회 학습단워 평가 (50분)'},
      {'time': '19:50 ~ 20:10', 'task': '휴식 (20분)'},
      {'time': '20:10 ~ 21:10', 'task': '부족 과목 보충 1 (60분)'},
      {'time': '21:10 ~ 21:30', 'task': '휴식 (20분)'},
      {'time': '21:30 ~ 22:30', 'task': '기술·가정 / 한문 암기 및 평가 (60분)'},
      {'time': '22:30 ~ 22:50', 'task': '휴식 및 취침준비 (20분)'},
      {'time': '22:50 ~ 07:00', 'task': '취침'},
    ],
    'Sunday': [
      {'time': '07:00 ~ 08:00', 'task': '기상 + 가벼운 운동 / 아침식사'},
      {'time': '08:00 ~ 09:00', 'task': '1)사회 진도 총정리 (60분)'},
      {'time': '09:00 ~ 09:20', 'task': '휴식 (20분)'},
      {'time': '09:20 ~ 10:20', 'task': '2)영어 (GM) (60분)'},
      {'time': '10:20 ~ 10:40', 'task': '휴식 (20분)'},
      {'time': '10:40 ~ 11:40', 'task': '3)수학 (최.블) (60분)'},
      {'time': '11:40 ~ 13:00', 'task': '휴식 및 점심 (80분)'},
      {'time': '13:00 ~ 14:00', 'task': '4)국어 (60분)'},
      {'time': '14:00 ~ 14:20', 'task': '휴식 (20분)'},
      {'time': '14:20 ~ 15:20', 'task': '5)고등수학 (60분)'},
      {'time': '15:20 ~ 15:40', 'task': '휴식 (20분)'},
      {'time': '15:40 ~ 16:40', 'task': '수학 (이유3) (60분)'},
      {'time': '16:40 ~ 17:00', 'task': '휴식 (20분)'},
      {'time': '17:00 ~ 17:50', 'task': '국어 학습단원 평가 (50분)'},
      {'time': '17:50 ~ 19:00', 'task': '저녁식사 및 휴식 (70분)'},
      {'time': '19:00 ~ 19:50', 'task': '영어 학습단원 평가 (50분)'},
      {'time': '19:50 ~ 20:10', 'task': '휴식 (20분)'},
      {'time': '20:10 ~ 21:00', 'task': '수학 학습단원 및 전체평가 (50분)'},
      {'time': '21:00 ~ 21:20', 'task': '휴식 (20분)'},
      {'time': '21:20 ~ 22:20', 'task': '기술·가정 / 한문 암기 + 학습단원 평가 (60분)'},
      {'time': '22:20 ~ 22:40', 'task': '휴식 및 취침 준비 (20분)'},
      {'time': '22:40 ~ 06:00', 'task': '취침'},
    ]
  };

  // 2. VACATION_SUMMER_WINTER: 방학 포모도로 타임라인 1~4
  static final List<Map<String, String>> vacationPomodoro1 = [
    {'time': '06:00 ~ 06:30', 'task': '기상 및 체조'},
    {'time': '06:30 ~ 07:00', 'task': '아침식사'},
    {'time': '07:00 ~ 07:25', 'task': '초집중 수학'},
    {'time': '07:25 ~ 07:30', 'task': '휴식'},
    {'time': '07:30 ~ 07:55', 'task': '초집중 국어'},
    {'time': '07:55 ~ 08:00', 'task': '휴식'},
    {'time': '08:00 ~ 08:25', 'task': '초집중 과학'},
    {'time': '08:25 ~ 08:55', 'task': '긴 휴식(30분)'},
    {'time': '08:55 ~ 09:20', 'task': '초집중 영어'},
    {'time': '09:20 ~ 09:25', 'task': '휴식'},
    {'time': '09:25 ~ 09:50', 'task': '초집중 수학'},
    {'time': '09:50 ~ 09:55', 'task': '휴식'},
    {'time': '09:55 ~ 10:20', 'task': '초집중 사회'},
    {'time': '10:20 ~ 10:50', 'task': '긴 휴식(30분)'},
    {'time': '10:50 ~ 11:15', 'task': '초집중 과학'},
    {'time': '11:15 ~ 11:20', 'task': '휴식'},
    {'time': '11:20 ~ 11:45', 'task': '초집중 영어'},
    {'time': '11:45 ~ 11:50', 'task': '휴식'},
    {'time': '11:50 ~ 12:15', 'task': '초집중 국어'},
    {'time': '12:15 ~ 12:45', 'task': '긴 휴식(30분)'},
    {'time': '12:45 ~ 14:15', 'task': '점심 및 휴식'},
    {'time': '14:15 ~ 14:40', 'task': '초집중 사회.세계사'},
    {'time': '14:40 ~ 14:45', 'task': '휴식'},
    {'time': '14:45 ~ 15:10', 'task': '초집중 수학'},
    {'time': '15:10 ~ 15:15', 'task': '휴식'},
    {'time': '15:15 ~ 15:40', 'task': '초집중 영어'},
    {'time': '15:40 ~ 16:10', 'task': '긴 휴식(30분)'},
    {'time': '16:10 ~ 16:35', 'task': '초집중 국어'},
    {'time': '16:35 ~ 16:40', 'task': '휴식'},
    {'time': '16:40 ~ 17:05', 'task': '초집중 과학'},
    {'time': '17:05 ~ 17:10', 'task': '휴식'},
    {'time': '17:10 ~ 17:35', 'task': '초집중 사회.세계사'},
    {'time': '17:35 ~ 18:05', 'task': '긴 휴식 (30분)'},
    {'time': '18:05 ~ 19:05', 'task': '저녁식사'},
    {'time': '19:05 ~ 19:30', 'task': '초집중 수학'},
    {'time': '19:30 ~ 19:35', 'task': '휴식'},
    {'time': '19:35 ~ 20:00', 'task': '초집중 국어'},
    {'time': '20:00 ~ 20:05', 'task': '휴식'},
    {'time': '20:05 ~ 20:30', 'task': '초집중 과학'},
    {'time': '20:30 ~ 21:00', 'task': '긴 휴식(30분)'},
    {'time': '21:00 ~ 21:25', 'task': '초집중 영어'},
    {'time': '21:25 ~ 21:30', 'task': '휴식'},
    {'time': '21:30 ~ 21:55', 'task': '초집중 수학'},
    {'time': '21:55 ~ 22:00', 'task': '휴식'},
    {'time': '22:00 ~ 22:25', 'task': '초집중 국어'},
    {'time': '22:25 ~ 22:55', 'task': '긴 휴식(30분)'},
    {'time': '22:55 ~ 23:20', 'task': '마무리 & 취침 준비'},
  ];

  static final List<Map<String, String>> vacationPomodoro2 = [
    {'time': '06:00 ~ 06:30', 'task': '기상 및 체조'},
    {'time': '06:30 ~ 07:00', 'task': '아침식사'},
    {'time': '07:00 ~ 07:40', 'task': '집중 수학'},
    {'time': '07:40 ~ 07:50', 'task': '휴식'},
    {'time': '07:50 ~ 08:30', 'task': '집중 국어'},
    {'time': '08:30 ~ 08:40', 'task': '휴식'},
    {'time': '08:40 ~ 09:20', 'task': '집중 과학'},
    {'time': '09:20 ~ 09:30', 'task': '휴식'},
    {'time': '09:30 ~ 10:10', 'task': '집중 영어'},
    {'time': '10:10 ~ 10:20', 'task': '휴식'},
    {'time': '10:20 ~ 11:00', 'task': '집중 수학'},
    {'time': '11:00 ~ 11:10', 'task': '휴식'},
    {'time': '11:10 ~ 12:40', 'task': '점심식사'},
    {'time': '12:40 ~ 13:20', 'task': '집중 사회,세계사'},
    {'time': '13:20 ~ 13:30', 'task': '휴식'},
    {'time': '13:30 ~ 14:10', 'task': '집중 과학'},
    {'time': '14:10 ~ 14:20', 'task': '휴식'},
    {'time': '14:20 ~ 15:00', 'task': '집중 영어'},
    {'time': '15:00 ~ 15:10', 'task': '휴식'},
    {'time': '15:10 ~ 15:50', 'task': '집중 국어'},
    {'time': '15:50 ~ 16:00', 'task': '휴식'},
    {'time': '16:00 ~ 16:40', 'task': '집중 사회.세계사'},
    {'time': '16:40 ~ 16:50', 'task': '휴식'},
    {'time': '16:50 ~ 17:30', 'task': '집중 수학'},
    {'time': '17:30 ~ 17:40', 'task': '휴식'},
    {'time': '17:40 ~ 19:00', 'task': '저녁식사'},
    {'time': '19:00 ~ 19:40', 'task': '집중 영어'},
    {'time': '19:40 ~ 20:50', 'task': '휴식'},
    {'time': '20:50 ~ 20:30', 'task': '집중 국어'},
    {'time': '20:30 ~ 20:40', 'task': '휴식'},
    {'time': '20:40 ~ 21:20', 'task': '집중 과학'},
    {'time': '21:20 ~ 21:30', 'task': '휴식'},
    {'time': '21:30 ~ 22:10', 'task': '집중 사회.세계사'},
    {'time': '22:10 ~ 22:20', 'task': '휴식 및 취침준비'},
  ];

  static final List<Map<String, String>> vacationPomodoro3 = [
    {'time': '06:00 ~ 06:30', 'task': '기상 및 간단한 체조'},
    {'time': '06:30 ~ 07:00', 'task': '아침식사'},
    {'time': '07:00 ~ 07:45', 'task': '제1과목 1차 초집중 수학'},
    {'time': '07:45 ~ 07:50', 'task': '휴식 (5분)'},
    {'time': '07:50 ~ 08:35', 'task': '제1과목 2차 초집중 국어'},
    {'time': '08:35 ~ 08:45', 'task': '휴식 (10분)'},
    {'time': '08:45 ~ 09:30', 'task': '제1과목 3차 초집중 과학'},
    {'time': '09:30 ~ 10:10', 'task': '긴 휴식 (40분) - 밖에서 5분 속보 걷기 필수'},
    {'time': '10:10 ~ 10:55', 'task': '제2과목 1차 초집중 영어'},
    {'time': '10:55 ~ 11:00', 'task': '휴식 (5분)'},
    {'time': '11:00 ~ 11:45', 'task': '제2과목 2차 초집중 사회(세계사)'},
    {'time': '11:45 ~ 11:55', 'task': '휴식 (10분)'},
    {'time': '11:55 ~ 12:40', 'task': '제2과목 3차 초집중 수학'},
    {'time': '12:40 ~ 13:20', 'task': '긴 휴식 (40분) - 밖에서 5분 속보 걷기 필수'},
    {'time': '13:20 ~ 14:20', 'task': '점심 및 휴식'},
    {'time': '14:20 ~ 15:05', 'task': '제3과목 1차 초집중 과학'},
    {'time': '15:05 ~ 15:10', 'task': '휴식 (5분)'},
    {'time': '15:10 ~ 15:55', 'task': '제3과목 2차 초집중 국어'},
    {'time': '15:55 ~ 16:05', 'task': '휴식 (10분)'},
    {'time': '16:05 ~ 16:50', 'task': '제3과목 3차 초집중 영어'},
    {'time': '16:50 ~ 17:30', 'task': '긴 휴식 (40분) - 밖에서 5분 속보 걷기 필수'},
    {'time': '17:30 ~ 18:30', 'task': '저녁식사'},
    {'time': '18:30 ~ 19:15', 'task': '제4과목 1차 초집중 사회(세계사)'},
    {'time': '19:15 ~ 19:20', 'task': '휴식 (5분)'},
    {'time': '19:20 ~ 20:05', 'task': '제4과목 2차 초집중 수학'},
    {'time': '20:05 ~ 20:15', 'task': '휴식 (10분)'},
    {'time': '20:15 ~ 21:00', 'task': '제4과목 3차 초집중 영어'},
    {'time': '21:00 ~ 21:40', 'task': '긴 휴식 (40분)'},
    {'time': '21:40 ~ 22:25', 'task': '제5과목 1차 초집중 국어'},
    {'time': '22:25 ~ 22:30', 'task': '휴식 (5분)'},
    {'time': '22:30 ~ 23:15', 'task': '마무리 및 취침 준비'},
  ];

  static final List<Map<String, String>> vacationPomodoro4 = [
    {'time': '06:00 ~ 06:30', 'task': '기상 및 체조'},
    {'time': '06:30 ~ 07:00', 'task': '아침식사'},
    {'time': '07:00 ~ 08:00', 'task': '집중 수학'},
    {'time': '08:00 ~ 08:10', 'task': '휴식'},
    {'time': '08:10 ~ 09:10', 'task': '집중 국어'},
    {'time': '09:10 ~ 09:30', 'task': '긴 휴식 (20분)'},
    {'time': '09:30 ~ 10:30', 'task': '집중 과학'},
    {'time': '10:30 ~ 10:40', 'task': '휴식'},
    {'time': '10:40 ~ 11:40', 'task': '집중 영어'},
    {'time': '11:40 ~ 12:00', 'task': '긴 휴식 (20분)'},
    {'time': '12:00 ~ 13:30', 'task': '점심 및 휴식'},
    {'time': '13:30 ~ 14:30', 'task': '집중 수학'},
    {'time': '14:30 ~ 14:40', 'task': '휴식'},
    {'time': '14:40 ~ 15:40', 'task': '집중 국어'},
    {'time': '15:40 ~ 16:00', 'task': ' 긴 휴식 (20분)'},
    {'time': '16:00 ~ 17:00', 'task': '집중 과학'},
    {'time': '17:00 ~ 17:10', 'task': '휴식'},
    {'time': '17:10 ~ 18:10', 'task': '집중 영어'},
    {'time': '18:10 ~ 18:30', 'task': '긴 휴식 (20분)'},
    {'time': '18:30 ~ 20:00', 'task': '저녁 및 휴식'},
    {'time': '20:00 ~ 21:00', 'task': '집중 수학'},
    {'time': '21:00 ~ 21:10', 'task': '휴식'},
    {'time': '21:10 ~ 22:10', 'task': '집중 영어'},
    {'time': '22:10 ~ 22:30', 'task': '마무리 및 취침 준비'},
  ];
}
// [주석] DKE StudyUp - 스터디 타임라인 데이터 관리 파일 (2단계: 중간고사 준비 기간)
class StudyTimelinesExamPrepMid {

  // 1. 중간고사 4주 전 평일 (D-28 ~ D-24)
  static final List<Map<String, String>> midTermWeek4Weekday = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '사회 시험대비 개념1강/ 문제풀이 20%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활'},
    {'time': '16:00 ~ 17:00', 'task': '휴식'},
    {'time': '17:00 ~ 18:00', 'task': '과학 시험대비 개념1강/ 문제풀이 20%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '국어 시험대비 개념1강/문제풀이 20%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '수학 시험대비 개념1강40%/문제풀이 60%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '영어 시험대비 개념1강/문제풀이 20%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식 및 취침준비'},
    {'time': '23:00 ~ 06:00', 'task': '취침'},
  ];

  // 2. 중간고사 4주 전 토·일 타임라인 (4주차 주말)(D-23, D-22 등 반복 구간)
  static final List<Map<String, String>> midTermWeek4Weekend = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사'},
    {'time': '08:00 ~ 09:00', 'task': '사회 개념1강/ 문제풀이 20%'},
    {'time': '09:00 ~ 09:20', 'task': '휴식'},
    {'time': '09:20 ~ 10:20', 'task': '과학 개념1강/ 문제풀이 20%'},
    {'time': '10:20 ~ 10:40', 'task': '휴식'},
    {'time': '10:40 ~ 11:30', 'task': '사회 1주 평가'},
    {'time': '11:30 ~ 13:00', 'task': '휴식 및 점심시간'},
    {'time': '13:00 ~ 14:00', 'task': '국어 개념1강/ 문제풀이 20%'},
    {'time': '14:00 ~ 14:20', 'task': '휴식'},
    {'time': '14:20 ~ 15:10', 'task': '과학 1주 평가'},
    {'time': '15:10 ~ 16:10', 'task': '수학 심화문제 50%/문제풀이 50%'},
    {'time': '16:10 ~ 16:30', 'task': '휴식'},
    {'time': '16:30 ~ 17:20', 'task': '국어 1주 평가'},
    {'time': '17:20 ~ 18:30', 'task': '저녁식사'},
    {'time': '18:30 ~ 19:30', 'task': '영어 개념1강/ 문제풀이 20%'},
    {'time': '19:30 ~ 19:50', 'task': '휴식'},
    {'time': '19:50 ~ 20:40', 'task': '수학 1주 평가'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 21:50', 'task': '영어 1주 평가'},
    {'time': '21:50 ~ 22:10', 'task': '휴식 및 취침준비'},
    {'time': '22:10 ~ 07:00', 'task': '취침 (토요일, 일요일 아침 07:00기상)'},
  ];

  // 3. 중간고사 3주 전 평일 (D-21 ~ D-17 )
  static final List<Map<String, String>> midTermWeek3Weekday = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '사회 시험대비 개념 정리 40%/ 문제풀이 60%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활'},
    {'time': '16:00 ~ 17:00', 'task': '휴식'},
    {'time': '17:00 ~ 18:00', 'task': '과학 시험대비 개념정리40%/ 문제풀이 60%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '국어 시험대비 개념정리 40%/문제풀이 60%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '수학 시험대비 개념정리20%/문제풀이 80%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '영어 시험대비 개념정리40%/문제풀이 60%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식 및 취침준비'},
    {'time': '23:00 ~ 06:00', 'task': '취침'},
  ];

  // 4. 중간고사 3주 전 토·일 타임라인 (3주차 주말) (D-16, D-15 반복)
  static final List<Map<String, String>> midTermWeek3Weekend = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사'},
    {'time': '08:00 ~ 09:00', 'task': '사회 개념1강/ 문제풀이 20%'},
    {'time': '09:00 ~ 09:20', 'task': '휴식'},
    {'time': '09:20 ~ 10:20', 'task': '과학 개념1강/ 문제풀이 20%'},
    {'time': '10:20 ~ 10:40', 'task': '휴식'},
    {'time': '10:40 ~ 11:30', 'task': '사회 1,2주 평가'},
    {'time': '11:30 ~ 13:00', 'task': '휴식 및 점심시간'},
    {'time': '13:00 ~ 14:00', 'task': '국어 개념1강/ 문제풀이 20%'},
    {'time': '14:00 ~ 14:20', 'task': '휴식'},
    {'time': '14:20 ~ 15:10', 'task': '과학 1,2주 평가'},
    {'time': '15:10 ~ 16:10', 'task': '수학 심화문제 50%/문제풀이 50%'},
    {'time': '16:10 ~ 16:30', 'task': '휴식'},
    {'time': '16:30 ~ 17:20', 'task': '국어 1,2주 평가'},
    {'time': '17:20 ~ 18:30', 'task': '저녁식사'},
    {'time': '18:30 ~ 19:30', 'task': '영어 개념1강/ 문제풀이 20%'},
    {'time': '19:30 ~ 19:50', 'task': '휴식'},
    {'time': '19:50 ~ 20:40', 'task': '수학 1,2주 평가'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 21:50', 'task': '영어 1,2주 평가'},
    {'time': '21:50 ~ 22:10', 'task': '휴식 및 취침준비'},
    {'time': '22:10 ~ 07:00', 'task': '취침 (토요일, 일요일 아침 07:00기상)'},
  ];

  // 5. 중간고사 2주 전 평일 (D-14 ~ D-10)
  static final List<Map<String, String>> midTermWeek2Weekday = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '사회 시험대비 개념 정리 30%/ 문제풀이 70%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활'},
    {'time': '16:00 ~ 17:00', 'task': '휴식'},
    {'time': '17:00 ~ 18:00', 'task': '과학 시험대비 개념정리30%/ 문제풀이 70%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '국어 시험대비 개념정리 30%/문제풀이 70%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '수학 시험대비 심화문제50%/문제풀이 50%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '영어 시험대비 개념정리40%/문제풀이 60%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식 및 취침준비'},
    {'time': '23:00 ~ 06:00', 'task': '취침'},
  ];

  // 6. 중간고사 2주 전 토·일 타임라인 (2주차 주말)(D-6, D-5)
  static final List<Map<String, String>> midTermWeek2Weekend = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사'},
    {'time': '08:00 ~ 09:00', 'task': '사회 개념1강/ 문제풀이 20%'},
    {'time': '09:00 ~ 09:20', 'task': '휴식'},
    {'time': '09:20 ~ 10:20', 'task': '과학 개념1강/ 문제풀이 20%'},
    {'time': '10:20 ~ 10:40', 'task': '휴식'},
    {'time': '10:40 ~ 11:30', 'task': '사회 전범위 평가'},
    {'time': '11:30 ~ 13:00', 'task': '휴식 및 점심시간'},
    {'time': '13:00 ~ 14:00', 'task': '국어 개념1강/ 문제풀이 20%'},
    {'time': '14:00 ~ 14:20', 'task': '휴식'},
    {'time': '14:20 ~ 15:10', 'task': '과학 전범위 평가'},
    {'time': '15:10 ~ 16:10', 'task': '수학 심화문제 50%/문제풀이 50%'},
    {'time': '16:10 ~ 16:30', 'task': '휴식'},
    {'time': '16:30 ~ 17:20', 'task': '국어 전범위 평가'},
    {'time': '17:20 ~ 18:30', 'task': '저녁식사'},
    {'time': '18:30 ~ 19:30', 'task': '영어 개념1강/ 문제풀이 20%'},
    {'time': '19:30 ~ 19:50', 'task': '휴식'},
    {'time': '19:50 ~ 20:40', 'task': '수학 전범위 평가'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 21:50', 'task': '영어 전범위 평가'},
    {'time': '21:50 ~ 22:10', 'task': '휴식 및 취침준비'},
    {'time': '22:10 ~ 07:00', 'task': '취침 (토요일, 일요일 아침 07:00기상)'},
  ];

  // 7. 중간고사 1주 전 평일 (D-7 ~ D-3)
  static final List<Map<String, String>> midTermWeek1Weekday = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '사회 시험대비 총정리 암기점검20%/ 오답+기문제 80%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활'},
    {'time': '16:00 ~ 17:00', 'task': '휴식'},
    {'time': '17:00 ~ 18:00', 'task': '과학 시험대비 총정리 암기점검20%/ 오답+기출문제 80%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '국어 시험대비 개념정리 20%/오답+기출문제 80%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '수학 시험대비 심화문제 50%/오답+기출문제 50%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '영어 시험대비 개념정리10%/오답+기출문제 90%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식 및 취침준비'},
    {'time': '23:00 ~ 06:00', 'task': '취침'},
  ];

  // 8. 중간고사 1주 전 토요일 (D-2) (1주차 주말)
  static final List<Map<String, String>> midTermWeek1Saturday = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사'},
    {'time': '08:00 ~ 09:00', 'task': '사회 총정리/문제풀이 70%'},
    {'time': '09:00 ~ 09:20', 'task': '휴식'},
    {'time': '09:20 ~ 10:20', 'task': '과학 총정리/문제풀이 70%'},
    {'time': '10:20 ~ 10:40', 'task': '휴식'},
    {'time': '10:40 ~ 11:30', 'task': '사회 전체평가'},
    {'time': '11:30 ~ 13:00', 'task': '휴식'},
    {'time': '13:00 ~ 14:00', 'task': '국어 총정리/문제풀이 70%'},
    {'time': '14:00 ~ 14:20', 'task': '휴식'},
    {'time': '14:20 ~ 15:10', 'task': '과학 전체평가'},
    {'time': '15:10 ~ 16:10', 'task': '수학 심화문제 50%/문제풀이 50%'},
    {'time': '16:10 ~ 16:30', 'task': '휴식'},
    {'time': '16:30 ~ 17:20', 'task': '국어 전체평가'},
    {'time': '17:20 ~ 18:30', 'task': '저녁식사'},
    {'time': '18:30 ~ 19:30', 'task': '영어 총정리/문제풀이 70%'},
    {'time': '19:30 ~ 19:50', 'task': '휴식'},
    {'time': '19:50 ~ 20:40', 'task': '수학 전체평가'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 21:50', 'task': '영어 전체평가'},
    {'time': '21:50 ~ 22:10', 'task': '휴식 및 취침준비'},
    {'time': '22:10 ~ 07:00', 'task': '취침'},
  ];

  // 9. 중간고사 1주 전 일요일 (D-1) (1주차 주말)— 팝업 안내 포함
  static const String sundayPopupNotice = "‘아는 것을 절대 안 틀리게 만들기’ 핵심 요약본을 3~5회 본다.";
  static final List<Map<String, String>> midTermWeek1Sunday = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사'},
    {'time': '08:00 ~ 09:00', 'task': '사회 총정리 or 익일 과목 대체가능'},
    {'time': '09:00 ~ 09:20', 'task': '휴식'},
    {'time': '09:20 ~ 10:20', 'task': '과학 총정리 or 익일 과목 대체가능'},
    {'time': '10:20 ~ 10:40', 'task': '휴식'},
    {'time': '10:40 ~ 11:30', 'task': '사회 전체평가'},
    {'time': '11:30 ~ 13:00', 'task': '휴식'},
    {'time': '13:00 ~ 14:00', 'task': '국어 총정리 or 익일 과목 대체가능'},
    {'time': '14:00 ~ 14:20', 'task': '휴식'},
    {'time': '14:20 ~ 15:10', 'task': '과학 전체평가'},
    {'time': '15:10 ~ 16:10', 'task': '수학 심화문제50%/문제풀이50%'},
    {'time': '16:10 ~ 16:30', 'task': '휴식'},
    {'time': '16:30 ~ 17:20', 'task': '국어 전체평가'},
    {'time': '17:20 ~ 18:30', 'task': '저녁식사'},
    {'time': '18:30 ~ 19:30', 'task': '영어 총정리 or 익일 과목 대체가능'},
    {'time': '19:30 ~ 19:50', 'task': '휴식'},
    {'time': '19:50 ~ 20:40', 'task': '수학 전체평가'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 21:50', 'task': '영어 전체평가'},
    {'time': '21:50 ~ 22:10', 'task': '휴식 및 취침준비'},
    {'time': '22:10 ~ 06:00', 'task': '취침'},
  ];
}
// [주석] DKE StudyUp - 스터디 타임라인 데이터 관리 파일 (3단계: 기말고사 준비 기간)
class StudyTimelinesExamPrepFinal {

  // 1. 기말고사 4주 전 평일 (D-28 ~ D-24) — 자정(24:00) 기술·가정/한문 암기 포함
  static final List<Map<String, String>> finalTermWeek4Weekday = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '사회 시험대비 개념1강/ 문제풀이 20%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활'},
    {'time': '16:00 ~ 17:00', 'task': '휴식'},
    {'time': '17:00 ~ 18:00', 'task': '과학 시험대비 개념1강/ 문제풀이 20%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '국어 시험대비 개념1강/문제풀이 20%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '수학 시험대비 개념1강40%/문제풀이 60%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '영어 시험대비 개념1강/문제풀y이 20%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식'},
    {'time': '23:00 ~ 24:00', 'task': '기술.가정/한문 개념정리 및 암기'},
    {'time': '24:00 ~ 06:00', 'task': '취침'},
  ];

  // 2. 기말고사 4주 전 토·일 타임라인 (D-23, D-22)(4주차 주말)
  static final List<Map<String, String>> finalTermWeek4Weekend = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사'},
    {'time': '08:00 ~ 09:00', 'task': '사회 시험대비 개념1강/ 문제풀이 20%'},
    {'time': '09:00 ~ 09:20', 'task': '휴식'},
    {'time': '09:20 ~ 10:20', 'task': '과학 시험대비 개념1강/ 문제풀이 20%'},
    {'time': '10:20 ~ 10:40', 'task': '휴식'},
    {'time': '10:40 ~ 11:30', 'task': '사회 1주 평가'},
    {'time': '11:30 ~ 13:00', 'task': '휴식 및 점심시간'},
    {'time': '13:00 ~ 14:00', 'task': '국어 시험대비 개념1강/문제풀이 20%'},
    {'time': '14:00 ~ 14:20', 'task': '휴식'},
    {'time': '14:20 ~ 15:10', 'task': '과학 1주 평가'},
    {'time': '15:10 ~ 15:30', 'task': '휴식'},
    {'time': '15:30 ~ 16:30', 'task': '수학 시험대비 개념1강40%/문제풀이 60%'},
    {'time': '16:30 ~ 16:50', 'task': '휴식'},
    {'time': '16:50 ~ 17:40', 'task': '국어 1주 평가'},
    {'time': '17:40 ~ 19:00', 'task': '휴식 및 저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '영어 시험대비 개념1강/문제풀이 20%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:10', 'task': '수학 1주평가'},
    {'time': '21:10 ~ 21:30', 'task': '휴식'},
    {'time': '21:30 ~ 22:30', 'task': '기술.가정 암기 및 문제풀이'},
    {'time': '22:30 ~ 22:50', 'task': '휴식'},
    {'time': '22:50 ~ 23:10', 'task': '영어 1주평가'},
    {'time': '23:10 ~ 24:00', 'task': '한문 암기 및 문제풀이'},
    {'time': '24:00 ~ 24:10', 'task': '휴식 및 취침'},
    {'time': '24:10 ~ 07:00', 'task': '취침(토요일,일요일 07시기상)'},
  ];

  // 3. 기말고사 3주 전 평일 (D-21 ~ D-17)
  static final List<Map<String, String>> finalTermWeek3Weekday = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '사회 시험대비 개념 정리 40%/ 문제풀이 60%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활'},
    {'time': '16:00 ~ 17:00', 'task': '휴식'},
    {'time': '17:00 ~ 18:00', 'task': '과학 시험대비 개념정리40%/ 문제풀이 60%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '국어 시험대비 개념정리 40%/문제풀이 60%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '수학 시험대비 개념정리20%/문제풀이 80%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '영어 시험대비 개념정리40%/문제풀이 60%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식'},
    {'time': '23:00 ~ 24:00', 'task': '기술.가정/한문 격일로 개념정리 및 암기'},
    {'time': '24:00 ~ 06:00', 'task': '취침'},
  ];

  // 4. 기말고사 3주 전 토·일 타임라인 (D-16, D-15)(3주차 주말)
  static final List<Map<String, String>> finalTermWeek3Weekend = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사'},
    {'time': '08:00 ~ 09:00', 'task': '사회 시험대비 개념정리 30%/ 문제풀이 70%'},
    {'time': '09:00 ~ 09:20', 'task': '휴식'},
    {'time': '09:20 ~ 10:20', 'task': '과학 시험대비 개념정리30%/ 문제풀이 70%'},
    {'time': '10:20 ~ 10:40', 'task': '휴식'},
    {'time': '10:40 ~ 11:30', 'task': '사회 1,2주 평가'},
    {'time': '11:30 ~ 13:00', 'task': '휴식 및 점심시간'},
    {'time': '13:00 ~ 14:00', 'task': '국어 시험대비 개념정리 30%/문제풀이 70%'},
    {'time': '14:00 ~ 14:20', 'task': '휴식'},
    {'time': '14:20 ~ 15:10', 'task': '과학 1,2주 평가'},
    {'time': '15:10 ~ 15:30', 'task': '휴식'},
    {'time': '15:30 ~ 16:30', 'task': '수학 시험대비 심화문제50%/문제풀이 50%'},
    {'time': '16:30 ~ 16:50', 'task': '휴식'},
    {'time': '16:50 ~ 17:40', 'task': '국어 1,2주 평가'},
    {'time': '17:40 ~ 19:00', 'task': '휴식 및 저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '영어 시험대비 개념정리30%/문제풀이 70%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:10', 'task': '수학 1,2주평가'},
    {'time': '21:10 ~ 21:30', 'task': '휴식'},
    {'time': '21:30 ~ 22:30', 'task': '기술.가정 암기 및 문제풀이'},
    {'time': '22:30 ~ 22:50', 'task': '휴식'},
    {'time': '22:50 ~ 23:10', 'task': '영어 1,2주평가'},
    {'time': '23:10 ~ 24:00', 'task': '한문 암기 및 문제풀이'},
    {'time': '24:00 ~ 24:10', 'task': '휴식 및 취침'},
    {'time': '24:10 ~ 07:00', 'task': '취침(토요일,일요일 07시기상)'},
  ];

  // 5. 기말고사 2주 전 평일 (D-14 ~ D-10)
  static final List<Map<String, String>> finalTermWeek2Weekday = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '사회 시험대비 개념 정리 30%/ 문제풀이 70%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활'},
    {'time': '16:00 ~ 17:00', 'task': '휴식'},
    {'time': '17:00 ~ 18:00', 'task': '과학 시험대비 개념정리30%/ 문제풀이 70%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '국어 시험대비 개념정리 30%/문제풀이 70%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '수학 시험대비 심화문제50%/문제풀이 50%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '영어 시험대비 개념정리40%/문제풀이 60%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식'},
    {'time': '23:00 ~ 24:00', 'task': '기술.가정/한문 격일로 개념정리 및 암기'},
    {'time': '24:00 ~ 06:00', 'task': '취침'},
  ];

  // 6. 기말고사 2주 전 토·일 타임라인 ( D-9 ~ D-8)(2주차 주말)
  static final List<Map<String, String>> finalTermWeek2Weekend = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사'},
    {'time': '08:00 ~ 09:00', 'task': '사회 시험대비 개념정리 40%/ 문제풀이 60%'},
    {'time': '09:00 ~ 09:20', 'task': '휴식'},
    {'time': '09:20 ~ 10:20', 'task': '과학 시험대비 개념정리40%/ 문제풀이 60%'},
    {'time': '10:20 ~ 10:40', 'task': '휴식'},
    {'time': '10:40 ~ 11:30', 'task': '사회 1,2,3주 평가'},
    {'time': '11:30 ~ 13:00', 'task': '휴식 및 점심시간'},
    {'time': '13:00 ~ 14:00', 'task': '국어 시험대비 개념정리 40%/문제풀이 60%'},
    {'time': '14:00 ~ 14:20', 'task': '휴식'},
    {'time': '14:20 ~ 15:10', 'task': '과학 1,2,3주 평가'},
    {'time': '15:10 ~ 15:30', 'task': '휴식'},
    {'time': '15:30 ~ 16:30', 'task': '수학 시험대비 심화문제50%/문제풀이 50%'},
    {'time': '16:30 ~ 16:50', 'task': '휴식'},
    {'time': '16:50 ~ 17:40', 'task': '국어 1,2,3주 평가'},
    {'time': '17:40 ~ 19:00', 'task': '휴식 및 저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '영어 시험대비 개념정리40%/문제풀이 60%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:10', 'task': '수학 1,2,3주평가'},
    {'time': '21:10 ~ 21:30', 'task': '휴식'},
    {'time': '21:30 ~ 22:30', 'task': '기술.가정 암기 및 문제풀이'},
    {'time': '22:30 ~ 22:50', 'task': '휴식'},
    {'time': '22:50 ~ 23:10', 'task': '영어 1,2,3주평가'},
    {'time': '23:10 ~ 24:00', 'task': '한문 암기 및 문제풀이'},
    {'time': '24:00 ~ 24:10', 'task': '휴식 및 취침'},
    {'time': '24:10 ~ 07:00', 'task': '취침(토요일,일요일 07시기상)'},
  ];

  // 7. 기말고사 1주 전 평일 (D-7 ~ D-3)
  static final List<Map<String, String>> finalTermWeek1Weekday = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '사회 시험대비 총정리 암기점검20%/ 오답+기문제 80%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활'},
    {'time': '16:00 ~ 17:00', 'task': '휴식'},
    {'time': '17:00 ~ 18:00', 'task': '과학 시험대비 총정리 암기점검20%/ 오답+기출문제 80%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '국어 시험대비 개념정리 20%/오답+기출문제 80%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '수학 시험대비 심화문제 50%/오답+기출문제 50%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '영어 시험대비 개념정리10%/오답+기출문제 90%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식'},
    {'time': '23:00 ~ 24:00', 'task': '기술.가정/한문 격일로 개념정리 및 암기'},
    {'time': '24:00 ~ 06:00', 'task': '취침'},
  ];

  // 8. 기말고사 1주 전 토요일 (D-2)(1주차 주말)
  static final List<Map<String, String>> finalTermWeek1Saturday = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사'},
    {'time': '08:00 ~ 09:00', 'task': '사회 총정리/오답정리 및 암기'},
    {'time': '09:00 ~ 09:20', 'task': '휴식'},
    {'time': '09:20 ~ 10:20', 'task': '과학 총정리/오답정리 및 암기'},
    {'time': '10:20 ~ 10:40', 'task': '휴식'},
    {'time': '10:40 ~ 11:30', 'task': '사회 전체평가'},
    {'time': '11:30 ~ 13:00', 'task': '휴식 및 점심시간'},
    {'time': '13:00 ~ 14:00', 'task': '국어 총정리/오답정리 및 암기'},
    {'time': '14:00 ~ 14:20', 'task': '휴식'},
    {'time': '14:20 ~ 15:10', 'task': '과학 전체평가'},
    {'time': '15:10 ~ 16:10', 'task': '수학 심화문제50%/오답문제50%'},
    {'time': '16:10 ~ 16:30', 'task': '휴식'},
    {'time': '16:30 ~ 17:20', 'task': '국어 전체평가'},
    {'time': '17:20 ~ 18:30', 'task': '저녁식사'},
    {'time': '18:30 ~ 19:30', 'task': '영어 총정리/오답정리 및 암기'},
    {'time': '19:30 ~ 19:50', 'task': '휴식'},
    {'time': '19:50 ~ 20:40', 'task': '수학 전체평가'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 22:00', 'task': '기술.가정/한문 암기 및 평가'},
    {'time': '22:00 ~ 22:50', 'task': '영어 전체평가'},
    {'time': '22:50 ~ 23:10', 'task': '휴식 및 취침준비'},
    {'time': '23:10 ~ 06:00', 'task': '취침'},
  ];

  // 9. 기말고사 1주 전 일요일 (D-1)(1주차 주말) — 팝업 안내 포함
  static const String finalSundayPopupNotice = "‘아는 것을 절대 안 틀리게 만들기’ 핵심 요약본을 3~5회 본다.";
  static final List<Map<String, String>> finalTermWeek1Sunday = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사'},
    {'time': '08:00 ~ 09:00', 'task': '사회 총정리 or 익일 과목 대체가능'},
    {'time': '09:00 ~ 09:20', 'task': '휴식'},
    {'time': '09:20 ~ 10:20', 'task': '과학 총정리 or 익일 과목 대체가능'},
    {'time': '10:20 ~ 10:40', 'task': '휴식'},
    {'time': '10:40 ~ 11:30', 'task': '사회 전체평가'},
    {'time': '11:30 ~ 11:50', 'task': '휴식'},
    {'time': '11:50 ~ 13:00', 'task': '점심 시간'},
    {'time': '13:00 ~ 14:00', 'task': '국어 총정리 or 익일 과목 대체가능'},
    {'time': '14:00 ~ 14:20', 'task': '휴식'},
    {'time': '14:20 ~ 15:10', 'task': '과학 전체평가'},
    {'time': '15:10 ~ 16:10', 'task': '수학 심화문제50%/or 익일 과목 대체가능'},
    {'time': '16:10 ~ 16:30', 'task': '휴식'},
    {'time': '16:30 ~ 17:20', 'task': '국어 전체평가'},
    {'time': '17:20 ~ 18:30', 'task': '저녁식사'},
    {'time': '18:30 ~ 19:30', 'task': '영어 총정리 or 익일 과목 대체가능'},
    {'time': '19:30 ~ 19:50', 'task': '휴식'},
    {'time': '19:50 ~ 20:40', 'task': '수학 전체평가'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 22:00', 'task': '기술.가정/한문 암기 및 평가'},
    {'time': '22:00 ~ 22:50', 'task': '영어 전체평가'},
    {'time': '22:50 ~ 23:10', 'task': '휴식 및 취침준비'},
    {'time': '23:10 ~ 06:00', 'task': '취침'},
  ];
}
// [주석] DKE StudyUp - 중간고사 D-Day별(월~금) 맞춤형 트래커 및 팝업/타임라인 데이터
class StudyTimelinesMidDayTrack {

  // 1. 공통 응원 및 팝업 팁 데이터 정의
  static const String popEncouragementBase = "오늘은 그동안의 노력이 빛을 발하는 날입니다. 수많은 시간 쌓아온 땀과 끈기는 결코 당신을 배신하지 않습니다. 한 문제, 한 문제 자신 있게. 당신은 이미 충분히 준비되었습니다. 최고의 하루를 만들어 보세요!";
  static const String popEncouragementMid = "지금까지의 노력은 결코 배신하지 않습니다. 침착하게, 자신 있게, 한 문제씩 풀어나가세요. 오늘은 당신이 준비한 실력을 마음껏 보여줄 시간입니다.";
  static const String popEncouragementSoft = "완벽하려고 하지 말고, 끝까지 최선을 다하세요. 아는 문제는 정확하게, 어려운 문제는 침착하게. 당신의 꾸준함이 오늘 최고의 결과를 만들어 줄 것입니다.";
  static const String popEncouragementFinal = "오늘은 결과보다 자신의 실력을 믿는 날입니다. 긴장은 잠시, 자신감은 오래. 끝까지 포기하지 않는 사람이 가장 강합니다. 당신의 빛나는 도전을 진심으로 응원합니다!";

  static const String popReviewTips =
      "이거 한번만 더 보자!\n"
      "아침 식사 가볍게 하기.\n"
      "요약 노트만 확인하기.\n"
      "공식, 단어, 암기사항만 확인한다.\n"
      "문제를 끝까지 읽는다.\n"
      "조건 및 등, 부호 실수, 단위 실수, 풀지 않은 것 확인.\n"
      "쉬운 문제 먼저.\n"
      "어려운 문제는 별 표시 후 넘어가기.\n"
      "마지막에 다시 도전.\n"
      "3~5분 이상 막히면 별 표시 후 넘어간다.";
  static const String popCoreSummary = "‘아는 것을 절대 안 틀리게 만들기’ 핵심 요약본을 3~5회 본다.";

  // 2. 중간고사 D-Day가 월요일인 경우의 타임라인
  static final List<Map<String, String>> midMonDayTimeline = [
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 시험 중'},
    {'time': '14:00 ~ 15:00', 'task': '휴식'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리'},
    {'time': '16:00 ~ 16:20', 'task': '휴식'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리'},
    {'time': '17:20 ~ 17:40', 'task': '휴식'},
    {'time': '17:40 ~ 18:40', 'task': '저녁식사 및 휴식'},
    {'time': '18:40 ~ 19:40', 'task': '내일 시험과목3 총정리'},
    {'time': '19:40 ~ 20:00', 'task': '휴식'},
    {'time': '20:00 ~ 21:00', 'task': '내일 시험과목1 총정리'},
    {'time': '21:00 ~ 21:20', 'task': '휴식'},
    {'time': '21:20 ~ 22:20', 'task': '내일 시험과목2 총정리'},
    {'time': '22:20 ~ 22:40', 'task': '휴식'},
    {'time': '22:40 ~ 23:40', 'task': '내일 시험과목3 총정리'},
    {'time': '23:40 ~ 06:00', 'task': '취침'},
  ];

  // 3. 중간고사 D-Day가 화요일인 경우 (D-1일 월요일 등)
  static final List<Map<String, String>> midTueD1Timeline = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '사회 총정리 암기점검20%/ 오답+기문제 80%, 익일과목 대체가능'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활'},
    {'time': '16:00 ~ 17:00', 'task': '휴식'},
    {'time': '17:00 ~ 18:00', 'task': '과학 총정리 암기점검20%/ 오답+기출문제 80%, 익일과목 대체가능'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '국어 개념정리 20%/오답+기출문제 80% 익일과목 대체가능'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '수학 심화문제 50%/오답+기출문제 50%,익일과목 대체가능'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '영어 정리10%/오답+기출문제 90%,익일과목 대체가능'},
    {'time': '22:40 ~ 23:00', 'task': '휴식 및 취침준비'},
    {'time': '23:00 ~ 06:00', 'task': '취침'},
  ];

  // 4. 중간고사 D-Day가 수요일인 경우 (D-1일 화요일 등)
  static final List<Map<String, String>> midWedD1Timeline = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '사회 시험대비 총정리 암기점검20%/ 오답+기문제 80%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활'},
    {'time': '16:00 ~ 17:00', 'task': '휴식'},
    {'time': '17:00 ~ 18:00', 'task': '과학 시험대비 총정리 암기점검20%/ 오답+기출문제 80%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '국어 시험대비 개념정리 20%/오답+기출문제 80%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '수학 시험대비 심화문제 50%/오답+기출문제 50%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '영어 시험대비 개념정리10%/오답+기출문제 90%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식 및 취침준비'},
    {'time': '23:00 ~ 06:00', 'task': '취침'},
  ];

  // 5. 시험 직후 주말 평가 블록 (D+3 / D+4 토·일)
  static final List<Map<String, String>> postExamWeekendBlock = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동'},
    {'time': '08:00 ~ 08:30', 'task': '아침식사'},
    {'time': '08:30 ~ 09:30', 'task': '시험대비1 총정리'},
    {'time': '09:30 ~ 09:50', 'task': '휴식'},
    {'time': '09:50 ~ 10:50', 'task': '시험대비1 문제풀이'},
    {'time': '10:50 ~ 11:10', 'task': '휴식'},
    {'time': '11:10 ~ 12:10', 'task': '시험대비2 총정리'},
    {'time': '12:10 ~ 14:00', 'task': '점심식사 및 휴식'},
    {'time': '14:00 ~ 15:00', 'task': '시험대비2 문제풀이'},
    {'time': '15:00 ~ 15:20', 'task': '휴식'},
    {'time': '15:20 ~ 16:20', 'task': '시험대비3 총정리'},
    {'time': '16:20 ~ 16:40', 'task': '휴식'},
    {'time': '17:40 ~ 19:00', 'task': '저녁식사 및 휴식'},
    {'time': '19:00 ~ 20:00', 'task': '시험대비1 총정리'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '시험대비1 문제풀이'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '시험대비2 총정리'},
    {'time': '22:40 ~ 23:00', 'task': '취침준비'},
    {'time': '23:00 ~ 07:00', 'task': '취침'},
  ];
}
// [주석] DKE StudyUp - 중간고사 D-Day 요일별(월~금) 맞춤형 전후 일자 및 타임라인 데이터 매니저
class StudyTimelinesMidTermAllDays {

  // ==========================================
  // 0. 공통 응원 및 팝업 지침 데이터 정의
  // ==========================================
  static const Map<String, String> midPopups = {
    'dDayEncourageMon': "오늘은 그동안의 노력이 빛을 발하는 날입니다. 수많은 시간 쌓아온 땀과 끈기는 결코 당신을 배신하지 않습니다. 한 문제, 한 문제 자신 있게. 당신은 이미 충분히 준비되었습니다. 최고의 하루를 만들어 보세요!",
    'dDayEncourageTue': "오늘은 그동안의 노력이 빛을 발하는 날입니다. 수많은 시간 쌓아온 땀과 끈기는 결코 당신을 배신하지 않습니다. 한 문제, 한 문제 자신 있게. 당신은 이미 충분히 준비되었습니다. 최고의 하루를 만들어 보세요!",
    'dDayEncourageWed': "오늘은 그동안의 노력이 빛을 발하는 날입니다. 수많은 시간 쌓아온 땀과 끈기는 결코 당신을 배신하지 않습니다. 한 문제, 한 문제 자신 있게. 당신은 이미 충분히 준비되었습니다. 최고의 하루를 만들어 보세요!",
    'dDayEncourageThu': "오늘은 그동안의 노력이 빛을 발하는 날입니다. 수많은 시간 쌓아온 땀과 끈기는 결코 당신을 배신하지 않습니다. 한 문제, 한 문제 자신 있게. 당신은 이미 충분히 준비되었습니다. 최고의 하루를 만들어 보세요!",
    'dDayEncourageFri': "오늘은 그동안의 노력이 빛을 발하는 날입니다. 수많은 시간 쌓아온 땀과 끈기는 결코 당신을 배신하지 않습니다. 한 문제, 한 문제 자신 있게. 당신은 이미 충분히 준비되었습니다. 최고의 하루를 만들어 보세요!",

    'inProgressTue': "지금까지의 노력은 결코 배신하지 않습니다. 침착하게, 자신 있게, 한 문제씩 풀어나가세요. 오늘은 당신이 준비한 실력을 마음껏 보여줄 시간입니다.",
    'inProgressWed': "완벽하려고 하지 말고, 끝까지 최선을 다하세요. 아는 문제는 정확하게, 어려운 문제는 침착하게. 당신의 꾸준함이 오늘 최고의 결과를 만들어 줄 것입니다.",
    'inProgressThu': "오늘은 결과보다 자신의 실력을 믿는 날입니다. 긴장은 잠시, 자신감은 오래. 끝까지 포기하지 않는 사람이 가장 강합니다. 당신의 빛나는 도전을 진심으로 응원합니다!",

    'reviewTips': "이거 한번 만 보아 주세요\n.아침 식사 가볍게 하기\n.요약 노트만 확인하기\n. 공식, 단어, 암기사항 만 확인한다.\n. 문제를 끝까지 읽는다.\n. 이런거 실수 조심하기: 조건 못 봄, 부호 실수, 단위 실수, “옳지 않은 것”\n. 쉬운 문제 먼저\n. 어려운 문제, 애매한 문제 별 표시 후 넘어가기\n. 마지막에 다시 도전\n. 3~5분 이상 막히면 별 표시 후 넘어간다.",
    'coreSummaryNotice': "‘아는 것을 절대 안 틀리게 만들기’ 핵심 요약본을 3~5회 본다."
  };

  // ==========================================
  // 1. EXAM_MON: 중간고사 D-Day가 월요일인 경우
  // ==========================================
  static final List<Map<String, String>> midMonD3 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '사회 시험대비 총정리 암기점검20%/ 오답+기문제 80%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활'},
    {'time': '16:00 ~ 17:00', 'task': '휴식'},
    {'time': '17:00 ~ 18:00', 'task': '과학 시험대비 총정리 암기점검20%/ 오답+기출문제 80%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '국어 시험대비 개념정리 20%/오답+기출문제 80%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '수학 시험대비 심화문제 50%/오답+기출문제 50%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '영어 시험대비 개념정리10%/오답+기출문제 90%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식 및 취침준비'},
    {'time': '23:00 ~ 07:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midMonD2 = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사'},
    {'time': '08:00 ~ 09:00', 'task': '사회 총정리 or 익일 과목 대체가능'},
    {'time': '09:00 ~ 09:20', 'task': '휴식'},
    {'time': '09:20 ~ 10:20', 'task': '과학 총정리 or 익일 과목 대체가능'},
    {'time': '10:20 ~ 10:40', 'task': '휴식'},
    {'time': '10:40 ~ 11:30', 'task': '사회 전체평가'},
    {'time': '11:30 ~ 11:50', 'task': '휴식'},
    {'time': '11:50 ~ 13:00', 'task': '점심 시간'},
    {'time': '13:00 ~ 14:00', 'task': '국어 총정리 or 익일 과목 대체가능'},
    {'time': '14:00 ~ 14:20', 'task': '휴식'},
    {'time': '14:20 ~ 15:10', 'task': '과학 전체평가'},
    {'time': '15:10 ~ 16:10', 'task': '수학 심화문제50%/or 익일 과목 대체가능'},
    {'time': '16:10 ~ 16:30', 'task': '휴식'},
    {'time': '16:30 ~ 17:20', 'task': '국어 전체평가'},
    {'time': '17:20 ~ 18:30', 'task': '저녁식사'},
    {'time': '18:30 ~ 19:30', 'task': '영어 총정리 or 익일 과목 대체가능'},
    {'time': '19:30 ~ 19:50', 'task': '휴식'},
    {'time': '19:50 ~ 20:40', 'task': '수학 전체평가'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 21:50', 'task': '영어 전체평가'},
    {'time': '21:50 ~ 22:10', 'task': '휴식 및 취침준비'},
    {'time': '22:10 ~ 06:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midMonD1 = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사'},
    {'time': '08:00 ~ 09:00', 'task': '사회 총정리 or 익일 과목 대체가능'},
    {'time': '09:00 ~ 09:20', 'task': '휴식'},
    {'time': '09:20 ~ 10:20', 'task': '과학 총정리 or 익일 과목 대체가능'},
    {'time': '10:20 ~ 10:40', 'task': '휴식'},
    {'time': '10:40 ~ 11:30', 'task': '사회 전체평가'},
    {'time': '11:30 ~ 11:50', 'task': '휴식'},
    {'time': '11:50 ~ 13:00', 'task': '점심 시간'},
    {'time': '13:00 ~ 14:00', 'task': '국어 총정리 or 익일 과목 대체가능'},
    {'time': '14:00 ~ 14:20', 'task': '휴식'},
    {'time': '14:20 ~ 15:10', 'task': '과학 전체평가'},
    {'time': '15:10 ~ 16:10', 'task': '수학 심화문제50%/or 익일 과목 대체가능'},
    {'time': '16:10 ~ 16:30', 'task': '휴식'},
    {'time': '16:30 ~ 17:20', 'task': '국어 전체평가'},
    {'time': '17:20 ~ 18:30', 'task': '저녁식사'},
    {'time': '18:30 ~ 19:30', 'task': '영어 총정리 or 익일 과목 대체가능'},
    {'time': '19:30 ~ 19:50', 'task': '휴식'},
    {'time': '19:50 ~ 20:40', 'task': '수학 전체평가'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 21:50', 'task': '영어 전체평가'},
    {'time': '21:50 ~ 22:10', 'task': '휴식 및 취침준비'},
    {'time': '22:10 ~ 06:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midMonDDay = [
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 시험 중'},
    {'time': '14:00 ~ 15:00', 'task': '휴식'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리'},
    {'time': '16:00 ~ 16:20', 'task': '휴식'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리'},
    {'time': '17:20 ~ 17:40', 'task': '휴식'},
    {'time': '17:40 ~ 18:40', 'task': '저녁식사 및 휴식'},
    {'time': '18:40 ~ 19:40', 'task': '내일 시험과목3 총정리'},
    {'time': '19:40 ~ 20:00', 'task': '휴식'},
    {'time': '20:00 ~ 21:00', 'task': '내일 시험과목1 총정리'},
    {'time': '21:00 ~ 21:20', 'task': '휴식'},
    {'time': '21:20 ~ 22:20', 'task': '내일 시험과목2 총정리'},
    {'time': '22:20 ~ 22:40', 'task': '휴식'},
    {'time': '22:40 ~ 23:40', 'task': '내일 시험과목3 총정리'},
    {'time': '23:40 ~ 06:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midMonDPlus1 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 중간고사 시험중'},
    {'time': '14:00 ~ 15:00', 'task': '휴식'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리'},
    {'time': '16:00 ~ 16:20', 'task': '휴식'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리'},
    {'time': '19:20 ~ 19:40', 'task': '휴식'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리'},
    {'time': '22:00 ~ 22:20', 'task': '휴식'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리'},
    {'time': '23:20 ~ 06:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midMonDPlus2 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 시험중'},
    {'time': '14:00 ~ 15:00', 'task': '휴식'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리'},
    {'time': '16:00 ~ 16:20', 'task': '휴식'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리'},
    {'time': '19:20 ~ 19:40', 'task': '휴식'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리'},
    {'time': '22:00 ~ 22:20', 'task': '휴식'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리'},
    {'time': '23:20 ~ 06:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midMonDPlus3 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 시험중'},
    {'time': '14:00 ~ 15:00', 'task': '휴식'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리'},
    {'time': '16:00 ~ 16:20', 'task': '휴식'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리'},
    {'time': '19:20 ~ 19:40', 'task': '휴식'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리'},
    {'time': '22:00 ~ 22:20', 'task': '휴식'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리'},
    {'time': '23:20 ~ 06:00', 'task': '취침'},
  ];

// ==========================================
  // 중간고사 D-Day 화요일, 수요일 맞춤형 데이터
  // ==========================================

  // [화요일 D-Day] D-3 ~ D+3
  static final List<Map<String, String>> midTueD3 = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사'},
    {'time': '08:00 ~ 09:00', 'task': '사회 시험대비 총정리/ 문제풀이 70%'},
    {'time': '09:00 ~ 09:20', 'task': '휴식'},
    {'time': '09:20 ~ 10:20', 'task': '과학 시험대비 총정리/ 문제풀이 70%'},
    {'time': '10:20 ~ 10:40', 'task': '휴식'},
    {'time': '10:40 ~ 11:30', 'task': '사회 전체평가'},
    {'time': '11:30 ~ 11:50', 'task': '휴식'},
    {'time': '11:50 ~ 12:50', 'task': '국어 시험대비 총정리/문제풀이 70%'},
    {'time': '12:50 ~ 14:00', 'task': '점심식사 및 휴식'},
    {'time': '14:00 ~ 14:50', 'task': '과학 전체평가'},
    {'time': '14:50 ~ 15:10', 'task': '휴식'},
    {'time': '15:10 ~ 16:10', 'task': '수학 시험대비 심화문제50%/오답정리 50%'},
    {'time': '16:10 ~ 16:30', 'task': '휴식'},
    {'time': '16:30 ~ 17:20', 'task': '국어 전체평가'},
    {'time': '17:20 ~ 17:40', 'task': '휴식'},
    {'time': '17:40 ~ 18:40', 'task': '영어 시험대비 총정리 및 오답정리'},
    {'time': '18:40 ~ 20:00', 'task': '저녁식사'},
    {'time': '20:00 ~ 20:50', 'task': '수학 전체평가'},
    {'time': '20:50 ~ 21:10', 'task': '휴식'},
    {'time': '21:10 ~ 22:00', 'task': '영어전체 평가'},
    {'time': '22:00 ~ 22:20', 'task': '휴식 및 취침준비'},
    {'time': '22:20 ~ 07:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midTueD2 = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사'},
    {'time': '08:00 ~ 09:00', 'task': '사회 시험대비 총정리 및 오답정리'},
    {'time': '09:00 ~ 09:20', 'task': '휴식'},
    {'time': '09:20 ~ 10:20', 'task': '과학 시험대비 총정리 및 오답정리'},
    {'time': '10:20 ~ 10:40', 'task': '휴식'},
    {'time': '10:40 ~ 11:30', 'task': '사회 전체평가'},
    {'time': '11:30 ~ 11:50', 'task': '휴식'},
    {'time': '11:50 ~ 12:50', 'task': '국어 시험대비 총정리 및 오답정리'},
    {'time': '12:50 ~ 14:00', 'task': '점심식사 및 휴식'},
    {'time': '14:00 ~ 14:50', 'task': '과학 전체평가'},
    {'time': '14:50 ~ 15:10', 'task': '휴식'},
    {'time': '15:10 ~ 16:10', 'task': '수학 시험대비 심화문제50%/오답정리 50%'},
    {'time': '16:10 ~ 16:30', 'task': '휴식'},
    {'time': '16:30 ~ 17:20', 'task': '국어 전체평가'},
    {'time': '17:20 ~ 17:40', 'task': '휴식'},
    {'time': '17:40 ~ 18:40', 'task': '영어 시험대비 총정리 및 오답정리'},
    {'time': '18:40 ~ 20:00', 'task': '저녁식사'},
    {'time': '20:00 ~ 20:50', 'task': '수학 전체평가'},
    {'time': '20:50 ~ 21:10', 'task': '휴식'},
    {'time': '21:10 ~ 22:00', 'task': '영어전체 평가'},
    {'time': '22:00 ~ 22:20', 'task': '휴식 및 취침준비'},
    {'time': '22:20 ~ 07:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midTueD1 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '사회 총정리 암기점검20%/ 오답+기문제 80%, 익일과목 대체가능'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활'},
    {'time': '16:00 ~ 17:00', 'task': '휴식'},
    {'time': '17:00 ~ 18:00', 'task': '과학 총정리 암기점검20%/ 오답+기출문제 80%, 익일과목 대체가능'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '국어 개념정리 20%/오답+기출문제 80% 익일과목 대체가능'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '수학 심화문제 50%/오답+기출문제 50%,익일과목 대체가능'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '영어 정리10%/오답+기출문제 90%,익일과목 대체가능'},
    {'time': '22:40 ~ 23:00', 'task': '휴식 및 취침준비'},
    {'time': '23:00 ~ 06:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midTueDDay = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활'},
    {'time': '14:00 ~ 15:00', 'task': '휴식'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리'},
    {'time': '16:00 ~ 16:20', 'task': '휴식'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리'},
    {'time': '17:20 ~ 17:40', 'task': '휴식'},
    {'time': '17:40 ~ 18:40', 'task': '저녁식사 및 휴식'},
    {'time': '18:40 ~ 19:40', 'task': '내일 시험과목3 총정리'},
    {'time': '19:40 ~ 20:00', 'task': '휴식'},
    {'time': '20:00 ~ 21:00', 'task': '내일 시험과목1 총정리'},
    {'time': '21:00 ~ 21:20', 'task': '휴식'},
    {'time': '21:20 ~ 22:20', 'task': '내일 시험과목2 총정리'},
    {'time': '22:20 ~ 22:40', 'task': '휴식'},
    {'time': '22:40 ~ 23:40', 'task': '내일 시험과목3 총정리'},
    {'time': '23:40 ~ 06:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midTueDPlus1 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 중간고사 시험중'},
    {'time': '14:00 ~ 15:00', 'task': '휴식'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리'},
    {'time': '16:00 ~ 16:20', 'task': '휴식'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리'},
    {'time': '19:20 ~ 19:40', 'task': '휴식'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리'},
    {'time': '22:00 ~ 22:20', 'task': '휴식'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리'},
    {'time': '23:20 ~ 06:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midTueDPlus2 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 시험중'},
    {'time': '14:00 ~ 15:00', 'task': '휴식'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리'},
    {'time': '16:00 ~ 16:20', 'task': '휴식'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리'},
    {'time': '19:20 ~ 19:40', 'task': '휴식'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리'},
    {'time': '22:00 ~ 22:20', 'task': '휴식'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리'},
    {'time': '23:20 ~ 23:30', 'task': '휴식 및 취침준비'},
    {'time': '23:30 ~ 06:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midTueDPlus3 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 시험중'},
    {'time': '14:00 ~ 15:00', 'task': '휴식'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리'},
    {'time': '16:00 ~ 16:20', 'task': '휴식'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리'},
    {'time': '19:20 ~ 19:40', 'task': '휴식'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리'},
    {'time': '22:00 ~ 22:20', 'task': '휴식'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리'},
    {'time': '23:20 ~ 07:00', 'task': '취침'},
  ];

  // [수요일 D-Day] D-3 ~ D+3
  static final List<Map<String, String>> midWedD3 = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사'},
    {'time': '08:00 ~ 09:00', 'task': '사회 시험대비 총정리 및 오답정리'},
    {'time': '09:00 ~ 09:20', 'task': '휴식'},
    {'time': '09:20 ~ 10:20', 'task': '과학 시험대비 총정리 및 오답정리'},
    {'time': '10:20 ~ 10:40', 'task': '휴식'},
    {'time': '10:40 ~ 11:30', 'task': '사회 전체평가'},
    {'time': '11:30 ~ 11:50', 'task': '휴식'},
    {'time': '11:50 ~ 12:50', 'task': '국어 시험대비 총정리 및 오답정리'},
    {'time': '12:50 ~ 14:00', 'task': '점심식사 및 휴식'},
    {'time': '14:00 ~ 14:50', 'task': '과학 전체평가'},
    {'time': '14:50 ~ 15:10', 'task': '휴식'},
    {'time': '15:10 ~ 16:10', 'task': '수학 시험대비 심화문제50%/오답정리 50%'},
    {'time': '16:10 ~ 16:30', 'task': '휴식'},
    {'time': '16:30 ~ 17:20', 'task': '국어 전체평가'},
    {'time': '17:20 ~ 17:40', 'task': '휴식'},
    {'time': '17:40 ~ 18:40', 'task': '영어 시험대비 총정리 및 오답정리'},
    {'time': '18:40 ~ 20:00', 'task': '저녁식사'},
    {'time': '20:00 ~ 20:50', 'task': '수학 전체평가'},
    {'time': '20:50 ~ 21:10', 'task': '휴식'},
    {'time': '21:10 ~ 22:00', 'task': '영어전체 평가'},
    {'time': '22:00 ~ 22:20', 'task': '휴식 및 취침준비'},
    {'time': '22:20 ~ 07:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midWedD2 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '사회 시험대비 총정리 암기점검20%/ 오답+기출문제 80%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활'},
    {'time': '16:00 ~ 17:00', 'task': '휴식'},
    {'time': '17:00 ~ 18:00', 'task': '과학 시험대비 총정리 암기점검20%/ 오답+기출문제 80%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '국어 시험대비 개념정리 20%/오답+기출문제 80%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '수학 시험대비 심화문제 50%/오답+기출문제 50%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '영어 시험대비 개념정리10%/오답+기출문제 90%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식 및 취침준비'},
    {'time': '23:00 ~ 06:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midWedD1 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '사회 시험대비 총정리 암기점검20%/ 오답+기문제 80%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활'},
    {'time': '16:00 ~ 17:00', 'task': '휴식'},
    {'time': '17:00 ~ 18:00', 'task': '과학 시험대비 총정리 암기점검20%/ 오답+기출문제 80%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '국어 시험대비 개념정리 20%/오답+기출문제 80%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '수학 시험대비 심화문제 50%/오답+기출문제 50%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '영어 시험대비 개념정리10%/오답+기출문제 90%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식 및 취침준비'},
    {'time': '23:00 ~ 06:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midWedDDay = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 시험중'},
    {'time': '14:00 ~ 15:00', 'task': '휴식'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리'},
    {'time': '16:00 ~ 16:20', 'task': '휴식'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리'},
    {'time': '19:20 ~ 19:40', 'task': '휴식'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리'},
    {'time': '22:00 ~ 22:20', 'task': '휴식'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리'},
    {'time': '23:20 ~ 06:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midWedDPlus1 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 시험중'},
    {'time': '14:00 ~ 15:00', 'task': '휴식'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리'},
    {'time': '16:00 ~ 16:20', 'task': '휴식'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리'},
    {'time': '19:20 ~ 19:40', 'task': '휴식'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리'},
    {'time': '22:00 ~ 22:20', 'task': '휴식'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리'},
    {'time': '23:20 ~ 06:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midWedDPlus2 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 시험중'},
    {'time': '14:00 ~ 15:00', 'task': '휴식'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리'},
    {'time': '16:00 ~ 16:20', 'task': '휴식'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리'},
    {'time': '19:20 ~ 19:40', 'task': '휴식'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리'},
    {'time': '22:00 ~ 22:20', 'task': '휴식'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리'},
    {'time': '23:20 ~ 23:30', 'task': '휴식 및 취침준비'},
    {'time': '23:30 ~ 07:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midWedDPlus3 = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동'},
    {'time': '08:00 ~ 08:30', 'task': '아침식사'},
    {'time': '08:30 ~ 09:30', 'task': '시험대비1 총정리'},
    {'time': '09:30 ~ 09:50', 'task': '휴식'},
    {'time': '09:50 ~ 10:50', 'task': '시험대비1 문제풀이'},
    {'time': '10:50 ~ 11:10', 'task': '휴식'},
    {'time': '11:10 ~ 12:10', 'task': '시험대비2 총정리'},
    {'time': '12:10 ~ 14:00', 'task': '점심식사 및 휴식'},
    {'time': '14:00 ~ 15:00', 'task': '시험대비2 문제풀이'},
    {'time': '15:00 ~ 15:20', 'task': '휴식'},
    {'time': '15:20 ~ 16:20', 'task': '시험대비3 총정리'},
    {'time': '16:20 ~ 16:40', 'task': '휴식'},
    {'time': '16:40 ~ 17:40', 'task': '시험대비3 문제풀이'},
    {'time': '17:40 ~ 19:00', 'task': '저녁식사 및 휴식'},
    {'time': '19:00 ~ 20:00', 'task': '시험대비1 총정리'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '시험대비1 문제풀이'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '시험대비2 총정리'},
    {'time': '22:40 ~ 23:00', 'task': '취침준비'},
    {'time': '23:00 ~ 07:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midWedDPlus4 = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동'},
    {'time': '08:00 ~ 08:30', 'task': '아침식사'},
    {'time': '08:30 ~ 09:30', 'task': '시험대비1 총정리'},
    {'time': '09:30 ~ 09:50', 'task': '휴식'},
    {'time': '09:50 ~ 10:50', 'task': '시험대비1 문제풀이'},
    {'time': '10:50 ~ 11:10', 'task': '휴식'},
    {'time': '11:10 ~ 12:10', 'task': '시험대비2 총정리'},
    {'time': '12:10 ~ 14:00', 'task': '점심식사 및 휴식'},
    {'time': '14:00 ~ 15:00', 'task': '시험대비2 문제풀이'},
    {'time': '15:00 ~ 15:20', 'task': '휴식'},
    {'time': '15:20 ~ 16:20', 'task': '시험대비3 총정리'},
    {'time': '16:20 ~ 16:40', 'task': '휴식'},
    {'time': '16:40 ~ 17:40', 'task': '시험대비3 문제풀이'},
    {'time': '17:40 ~ 19:00', 'task': '저녁식사 및 휴식'},
    {'time': '19:00 ~ 20:00', 'task': '시험대비1 총정리'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '시험대비1 문제풀이'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '시험대비2 총정리'},
    {'time': '22:40 ~ 23:00', 'task': '취침준비'},
    {'time': '23:00 ~ 06:00', 'task': '취침'},
  ];

  // [목요일 D-Day] D-3 ~ D+3
  static final List<Map<String, String>> midThuD3 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '사회 시험대비 총정리 암기점검20%/ 오답+기출문제 80%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활'},
    {'time': '16:00 ~ 17:00', 'task': '휴식'},
    {'time': '17:00 ~ 18:00', 'task': '과학 시험대비 총정리 암기점검20%/ 오답+기출문제 80%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '국어 시험대비 개념정리 20%/오답+기출문제 80%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '수학 시험대비 심화문제 50%/오답+기출문제 50%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '영어 시험대비 개념정리10%/오답+기출문제 90%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식 및 취침준비'},
    {'time': '23:00 ~ 06:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midThuD2 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '사회 시험대비 총정리 암기점검20%/ 오답+기출문제 80%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활'},
    {'time': '16:00 ~ 17:00', 'task': '휴식'},
    {'time': '17:00 ~ 18:00', 'task': '과학 시험대비 총정리 암기점검20%/ 오답+기출문제 80%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '국어 시험대비 개념정리 20%/오답+기출문제 80%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '수학 시험대비 심화문제 50%/오답+기출문제 50%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '영어 시험대비 개념정리10%/오답+기출문제 90%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식 및 취침준비'},
    {'time': '23:00 ~ 06:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midThuD1 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '사회 시험대비 총정리 암기점검20%/ 오답+기출문제 80%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활'},
    {'time': '16:00 ~ 17:00', 'task': '휴식'},
    {'time': '17:00 ~ 18:00', 'task': '과학 시험대비 총정리 암기점검20%/ 오답+기출문제 80%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '국어 시험대비 개념정리 20%/오답+기출문제 80%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '수학 시험대비 심화문제 50%/오답+기출문제 50%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '영어 시험대비 개념정리10%/오답+기출문제 90%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식 및 취침준비'},
    {'time': '23:00 ~ 06:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midThuDDay = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭 (스트레칭으로 긴장감풀기 – 팝업)'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 시험중'},
    {'time': '14:00 ~ 15:00', 'task': '휴식'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리'},
    {'time': '16:00 ~ 16:20', 'task': '휴식'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리'},
    {'time': '19:20 ~ 19:40', 'task': '휴식'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리'},
    {'time': '22:00 ~ 22:20', 'task': '휴식'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리'},
    {'time': '23:20 ~ 06:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midThuDPlus1 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭 (스트레칭으로 긴장감풀기 – 팝업)'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 시험중'},
    {'time': '14:00 ~ 15:00', 'task': '휴식'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리'},
    {'time': '16:00 ~ 16:20', 'task': '휴식'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리'},
    {'time': '19:20 ~ 19:40', 'task': '휴식'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리'},
    {'time': '22:00 ~ 22:20', 'task': '휴식'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리'},
    {'time': '23:20 ~ 06:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midThuDPlus2 = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동'},
    {'time': '08:00 ~ 08:30', 'task': '아침식사'},
    {'time': '08:30 ~ 09:30', 'task': '시험대비1 총정리'},
    {'time': '09:30 ~ 09:50', 'task': '휴식'},
    {'time': '09:50 ~ 10:50', 'task': '시험대비1 문제풀이'},
    {'time': '10:50 ~ 11:10', 'task': '휴식'},
    {'time': '11:10 ~ 12:10', 'task': '시험대비2 총정리'},
    {'time': '12:10 ~ 14:00', 'task': '점심식사 및 휴식'},
    {'time': '14:00 ~ 15:00', 'task': '시험대비2 문제풀이'},
    {'time': '15:00 ~ 15:20', 'task': '휴식'},
    {'time': '15:20 ~ 16:20', 'task': '시험대비3 총정리'},
    {'time': '16:20 ~ 16:40', 'task': '휴식'},
    {'time': '16:40 ~ 17:40', 'task': '시험대비3 문제풀이'},
    {'time': '17:40 ~ 19:00', 'task': '저녁식사 및 휴식'},
    {'time': '19:00 ~ 20:00', 'task': '시험대비1 총정리'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '시험대비1 문제풀이'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '시험대비2 총정리'},
    {'time': '22:40 ~ 23:00', 'task': '취침준비'},
    {'time': '23:00 ~ 07:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midThuDPlus3 = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동'},
    {'time': '08:00 ~ 08:30', 'task': '아침식사'},
    {'time': '08:30 ~ 09:30', 'task': '시험대비1 총정리'},
    {'time': '09:30 ~ 09:50', 'task': '휴식'},
    {'time': '09:50 ~ 10:50', 'task': '시험대비1 문제풀이'},
    {'time': '10:50 ~ 11:10', 'task': '휴식'},
    {'time': '11:10 ~ 12:10', 'task': '시험대비2 총정리'},
    {'time': '12:10 ~ 14:00', 'task': '점심식사 및 휴식'},
    {'time': '14:00 ~ 15:00', 'task': '시험대비2 문제풀이'},
    {'time': '15:00 ~ 15:20', 'task': '휴식'},
    {'time': '15:20 ~ 16:20', 'task': '시험대비3 총정리'},
    {'time': '16:20 ~ 16:40', 'task': '휴식'},
    {'time': '16:40 ~ 17:40', 'task': '시험대비3 문제풀이'},
    {'time': '17:40 ~ 19:00', 'task': '저녁식사 및 휴식'},
    {'time': '19:00 ~ 20:00', 'task': '시험대비1 총정리'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '시험대비1 문제풀이'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '시험대비2 총정리'},
    {'time': '22:40 ~ 23:00', 'task': '취침준비'},
    {'time': '23:00 ~ 06:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> midThuDPlus4 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭 (스트레칭으로 긴장감풀기 – 팝업)'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 시험중'},
    {'time': '14:00 ~ 15:00', 'task': '휴식'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리'},
    {'time': '16:00 ~ 16:20', 'task': '휴식'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리'},
    {'time': '19:20 ~ 19:40', 'task': '휴식'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리'},
    {'time': '22:00 ~ 22:20', 'task': '휴식'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리'},
    {'time': '23:20 ~ 07:00', 'task': '취침'},
  ];

  // [금요일 D-Day] D-3 ~ D+3
  static final List<Map<String, String>> midFriD3 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '사회 시험대비 총정리 암기점검 20% / 오답+기출문제 80%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활'},
    {'time': '16:00 ~ 17:00', 'task': '휴식'},
    {'time': '17:00 ~ 18:00', 'task': '과학 시험대비 총정리 암기점검 20% / 오답+기출문제 80%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '국어 시험대비 개념정리 20% / 오답+기출문제 80%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '수학 시험대비 심화문제 50% / 오답+기출문제 50%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '영어 시험대비 개념정리 10% / 오답+기출문제 90%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식 및 취침준비'},
    {'time': '23:00 ~ 06:00', 'task': '취침'}
  ];

  static final List<Map<String, String>> midFriD2 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '사회 시험대비 총정리 암기점검 20% / 오답+기출문제 80%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활'},
    {'time': '16:00 ~ 17:00', 'task': '휴식'},
    {'time': '17:00 ~ 18:00', 'task': '과학 시험대비 총정리 암기점검 20% / 오답+기출문제 80%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '국어 시험대비 개념정리 20% / 오답+기출문제 80%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '수학 시험대비 심화문제 50% / 오답+기출문제 50%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '영어 시험대비 개념정리 10% / 오답+기출문제 90%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식 및 취침준비'},
    {'time': '23:00 ~ 06:00', 'task': '취침'}
  ];

  static final List<Map<String, String>> midFriD1 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '사회 시험대비 총정리 암기점검 20% / 오답+기출문제 80%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활'},
    {'time': '16:00 ~ 17:00', 'task': '휴식'},
    {'time': '17:00 ~ 18:00', 'task': '과학 시험대비 총정리 암기점검 20% / 오답+기출문제 80%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '국어 시험대비 개념정리 20% / 오답+기출문제 80%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '수학 시험대비 심화문제 50% / 오답+기출문제 50%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '영어 시험대비 개념정리 10% / 오답+기출문제 90%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식 및 취침준비'},
    {'time': '23:00 ~ 06:00', 'task': '취침'}
  ];

  static final List<Map<String, String>> midFriDDay = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭 (스트레칭으로 긴장감풀기 – 팝업)'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 시험중'},
    {'time': '14:00 ~ 15:00', 'task': '휴식'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리'},
    {'time': '16:00 ~ 16:20', 'task': '휴식'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리'},
    {'time': '19:20 ~ 19:40', 'task': '휴식'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리'},
    {'time': '22:00 ~ 22:20', 'task': '휴식'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리'},
    {'time': '23:20 ~ 06:00', 'task': '취침'}
  ];

  static final List<Map<String, String>> midFriDPlus1 = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동'},
    {'time': '08:00 ~ 08:30', 'task': '아침식사'},
    {'time': '08:30 ~ 09:30', 'task': '시험대비1 총정리'},
    {'time': '09:30 ~ 09:50', 'task': '휴식'},
    {'time': '09:50 ~ 10:50', 'task': '시험대비1 문제풀이'},
    {'time': '10:50 ~ 11:10', 'task': '휴식'},
    {'time': '11:10 ~ 12:10', 'task': '시험대비2 총정리'},
    {'time': '12:10 ~ 14:00', 'task': '점심식사 및 휴식'},
    {'time': '14:00 ~ 15:00', 'task': '시험대비2 문제풀이'},
    {'time': '15:00 ~ 15:20', 'task': '휴식'},
    {'time': '15:20 ~ 16:20', 'task': '시험대비3 총정리'},
    {'time': '16:20 ~ 16:40', 'task': '휴식'},
    {'time': '16:40 ~ 17:40', 'task': '시험대비3 문제풀이'},
    {'time': '17:40 ~ 19:00', 'task': '저녁식사 및 휴식'},
    {'time': '19:00 ~ 20:00', 'task': '시험대비1 총정리'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '시험대비1 문제풀이'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '시험대비2 총정리'},
    {'time': '22:40 ~ 23:00', 'task': '취침준비'},
    {'time': '23:00 ~ 07:00', 'task': '취침'}
  ];

  static final List<Map<String, String>> midFriDPlus2 = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동'},
    {'time': '08:00 ~ 08:30', 'task': '아침식사'},
    {'time': '08:30 ~ 09:30', 'task': '시험대비1 총정리'},
    {'time': '09:30 ~ 09:50', 'task': '휴식'},
    {'time': '09:50 ~ 10:50', 'task': '시험대비1 문제풀이'},
    {'time': '10:50 ~ 11:10', 'task': '휴식'},
    {'time': '11:10 ~ 12:10', 'task': '시험대비2 총정리'},
    {'time': '12:10 ~ 14:00', 'task': '점심식사 및 휴식'},
    {'time': '14:00 ~ 15:00', 'task': '시험대비2 문제풀이'},
    {'time': '15:00 ~ 15:20', 'task': '휴식'},
    {'time': '15:20 ~ 16:20', 'task': '시험대비3 총정리'},
    {'time': '16:20 ~ 16:40', 'task': '휴식'},
    {'time': '16:40 ~ 17:40', 'task': '시험대비3 문제풀이'},
    {'time': '17:40 ~ 19:00', 'task': '저녁식사 및 휴식'},
    {'time': '19:00 ~ 20:00', 'task': '시험대비1 총정리'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '시험대비1 문제풀이'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '시험대비2 총정리'},
    {'time': '22:40 ~ 23:00', 'task': '취침준비'},
    {'time': '23:00 ~ 06:00', 'task': '취침'}
  ];

  static final List<Map<String, String>> midFriDPlus3 = [
    {'time': '06:00 ~ 06:30', 'task': '기상'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 시험중'},
    {'time': '14:00 ~ 15:00', 'task': '휴식'},
    {'time': '15:00 ~ 16:00', 'task': '시험과목1 정리'},
    {'time': '16:00 ~ 16:20', 'task': '휴식'},
    {'time': '16:20 ~ 17:20', 'task': '시험과목2 정리'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사'},
    {'time': '18:20 ~ 19:20', 'task': '시험과목3 정리'},
    {'time': '19:20 ~ 19:40', 'task': '휴식'},
    {'time': '19:40 ~ 20:40', 'task': '시험과목1 정리'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 22:00', 'task': '시험과목2 정리'},
    {'time': '22:00 ~ 22:20', 'task': '휴식'},
    {'time': '22:20 ~ 23:20', 'task': '시험과목3 정리'},
    {'time': '23:20 ~ 23:10', 'task': '휴식 및 취침준비'},
    {'time': '23:10 ~ 06:00', 'task': '취침'}
  ];

  static final List<Map<String, String>> midFriDPlus4 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭 (스트레칭으로 긴장감풀기 – 팝업)'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 시험중'},
    {'time': '14:00 ~ 15:00', 'task': '휴식'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리'},
    {'time': '16:00 ~ 16:20', 'task': '휴식'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리'},
    {'time': '19:20 ~ 19:40', 'task': '휴식'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리'},
    {'time': '20:40 ~ 21:00', 'task': '휴식'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리'},
    {'time': '22:00 ~ 22:20', 'task': '휴식'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리'},
    {'time': '23:20 ~ 07:00', 'task': '취침'}
  ];

// ==========================================
// 1. EXAM_MON: 기말고사 D-Day가 월요일인 경우
// ==========================================

  /// D-3일까지 (금요일) 타임라인 원본 복원
  static final List<Map<String, String>> finalMonD3 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭'},
    {'time': '06:30 ~ 07:30', 'task': '사회 시험대비 총정리 암기점검20%/ 오답+기출문제 80%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활'},
    {'time': '16:00 ~ 17:00', 'task': '휴식'},
    {'time': '17:00 ~ 18:00', 'task': '과학 시험대비 총정리 암기점검20%/ 오답+기출문제 80%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사'},
    {'time': '19:00 ~ 20:00', 'task': '국어 시험대비 개념정리 20%/오답+기출문제 80%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식'},
    {'time': '20:20 ~ 21:20', 'task': '수학 시험대비 심화문제 50%/오답+기출문제 50%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식'},
    {'time': '21:40 ~ 22:40', 'task': '영어 시험대비 개념정리10%/오답+기출문제 90%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식'},
    {'time': '23:00 ~ 24:00', 'task': '기술.가정/한문 격일로 개념정리 및 암기'},
    {'time': '24:00 ~ 07:00', 'task': '취침'},
  ];

  static final List<Map<String, String>> finalMonD2 = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사\nWake up + Light exercise/Breakfast'},
    {'time': '08:00 ~ 09:00', 'task': '사회 총정리/오답정리 및 암기\nSocial Studies total review/Mistakes & memory'},
    {'time': '09:00 ~ 09:20', 'task': '휴식\nBreak time'},
    {'time': '09:20 ~ 10:20', 'task': '과학 총정리/오답정리 및 암기\nScience total review/Mistakes & memory'},
    {'time': '10:20 ~ 10:40', 'task': '휴식\nBreak time'},
    {'time': '10:40 ~ 11:30', 'task': '사회 전체평가\nSocial Studies comprehensive evaluation'},
    {'time': '11:30 ~ 11:50', 'task': '휴식\nBreak time'},
    {'time': '11:50 ~ 13:00', 'task': '점심 시간\nLunch time'},
    {'time': '13:00 ~ 14:00', 'task': '국어 총정리/오답정리 및 암기\nKorean total review/Mistakes & memory'},
    {'time': '14:00 ~ 14:20', 'task': '휴식\nBreak time'},
    {'time': '14:20 ~ 15:10', 'task': '과학 전체평가\nScience comprehensive evaluation'},
    {'time': '15:10 ~ 16:10', 'task': '수학 심화문제50%/오답문제50%\nMath advanced problems 50% / Mistakes 50%'},
    {'time': '16:10 ~ 16:30', 'task': '휴식\nBreak time'},
    {'time': '16:30 ~ 17:20', 'task': '국어 전체평가\nKorean comprehensive evaluation'},
    {'time': '17:20 ~ 18:30', 'task': '저녁식사\nDinner'},
    {'time': '18:30 ~ 19:30', 'task': '영어 총정리/오답정리 및 암기\nEnglish total review/Mistakes & memory'},
    {'time': '19:30 ~ 19:50', 'task': '휴식\nBreak time'},
    {'time': '19:50 ~ 20:40', 'task': '수학 전체평가\nMath comprehensive evaluation'},
    {'time': '20:40 ~ 21:00', 'task': '휴식\nBreak time'},
    {'time': '21:00 ~ 22:00', 'task': '기술.가정/한문 암기 및 평가\nTech & Home / Hanja memory & evaluation'},
    {'time': '22:00 ~ 22:50', 'task': '영어 전체평가\nEnglish comprehensive evaluation'},
    {'time': '22:50 ~ 23:10', 'task': '휴식 및 취침준비\nBreak time & Prep for bed'},
    {'time': '23:10 ~ 07:00', 'task': '취침\nBedtime'},
  ];

  static final List<Map<String, String>> finalMonD1 = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사\nWake up + Light exercise/Breakfast'},
    {'time': '08:00 ~ 09:00', 'task': '사회 총정리 or 익일 과목 대체가능\nSocial Studies total review or substitute next day subject'},
    {'time': '09:00 ~ 09:20', 'task': '휴식\nBreak time'},
    {'time': '09:20 ~ 10:20', 'task': '과학 총정리 or 익일 과목 대체가능\nScience total review or substitute next day subject'},
    {'time': '10:20 ~ 10:40', 'task': '휴식\nBreak time'},
    {'time': '10:40 ~ 11:30', 'task': '사회 전체평가\nSocial Studies comprehensive evaluation'},
    {'time': '11:30 ~ 11:50', 'task': '휴식\nBreak time'},
    {'time': '11:50 ~ 13:00', 'task': '점심 시간\nLunch time'},
    {'time': '13:00 ~ 14:00', 'task': '국어 총정리 or 익일 과목 대체가능\nKorean total review or substitute next day subject'},
    {'time': '14:00 ~ 14:20', 'task': '휴식\nBreak time'},
    {'time': '14:20 ~ 15:10', 'task': '과학 전체평가\nScience comprehensive evaluation'},
    {'time': '15:10 ~ 16:10', 'task': '수학 심화문제50%/or 익일 과목 대체가능\nMath advanced problems 50% or substitute next day subject'},
    {'time': '16:10 ~ 16:30', 'task': '휴식\nBreak time'},
    {'time': '16:30 ~ 17:20', 'task': '국어 전체평가\nKorean comprehensive evaluation'},
    {'time': '17:20 ~ 18:30', 'task': '저녁식사\nDinner'},
    {'time': '18:30 ~ 19:30', 'task': '영어 총정리 or 익일 과목 대체가능\nEnglish total review or substitute next day subject'},
    {'time': '19:30 ~ 19:50', 'task': '휴식\nBreak time'},
    {'time': '19:50 ~ 20:40', 'task': '수학 전체평가\nMath comprehensive evaluation'},
    {'time': '20:40 ~ 21:00', 'task': '휴식\nBreak time'},
    {'time': '21:00 ~ 22:00', 'task': '기술.가정/한문 암기 및 평가\nTech & Home / Hanja memory & evaluation'},
    {'time': '22:00 ~ 22:50', 'task': '영어 전체평가\nEnglish comprehensive evaluation'},
    {'time': '22:50 ~ 23:10', 'task': '휴식 및 취침준비\nBreak time & Prep for bed'},
    {'time': '23:10 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  static final List<Map<String, String>> finalMonDDay = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭 (스트레칭으로 긴장감풀기 – 팝업)\nWake up + Light exercise/Stretching'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 총정리\nFinal review of today\'s exam subject'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활, 기말고사\nSchool life, Final exams'},
    {'time': '14:00 ~ 15:00', 'task': '휴식\nBreak time'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 총정리\nTotal review for tomorrow\'s subject 1'},
    {'time': '16:00 ~ 16:20', 'task': '휴식\nBreak time'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 총정리\nTotal review for tomorrow\'s subject 2'},
    {'time': '17:20 ~ 17:40', 'task': '휴식\nBreak time'},
    {'time': '17:40 ~ 18:40', 'task': '저녁식사 및 휴식\nDinner and break'},
    {'time': '18:40 ~ 19:40', 'task': '내일 시험과목3 총정리\nTotal review for tomorrow\'s subject 3'},
    {'time': '19:40 ~ 20:00', 'task': '휴식\nBreak time'},
    {'time': '20:00 ~ 21:00', 'task': '내일 시험과목1 총정리\nTotal review for tomorrow\'s subject 1'},
    {'time': '21:00 ~ 21:20', 'task': '휴식\nBreak time'},
    {'time': '21:20 ~ 22:20', 'task': '내일 시험과목2 총정리\nTotal review for tomorrow\'s subject 2'},
    {'time': '22:20 ~ 22:40', 'task': '휴식\nBreak time'},
    {'time': '22:40 ~ 23:40', 'task': '내일 시험과목3 총정리\nTotal review for tomorrow\'s subject 3'},
    {'time': '23:40 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  /// D+1일까지 (화요일) 타임라인
  static final List<Map<String, String>> finalMonDPlus1 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭 (스트레칭으로 긴장감풀기 – 팝업)\nWake up + Light exercise/Stretching (Popup: Relieve tension)'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리\nReview of today\'s exam subject'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 기말 시험중\nSchool life, Taking final exams'},
    {'time': '14:00 ~ 15:00', 'task': '휴식\nBreak time'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리\nReview for tomorrow\'s subject 1'},
    {'time': '16:00 ~ 16:20', 'task': '휴식\nBreak time'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리\nReview for tomorrow\'s subject 2'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사\nDinner'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리\nReview for tomorrow\'s subject 3'},
    {'time': '19:20 ~ 19:40', 'task': '휴식\nBreak time'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리\nReview for tomorrow\'s subject 1'},
    {'time': '20:40 ~ 21:00', 'task': '휴식\nBreak time'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리\nReview for tomorrow\'s subject 2'},
    {'time': '22:00 ~ 22:20', 'task': '휴식\nBreak time'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리\nReview for tomorrow\'s subject 3'},
    {'time': '23:20 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  /// D+2일까지 (수요일) 타임라인
  static final List<Map<String, String>> finalMonDPlus2 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭 (스트레칭으로 긴장감풀기 – 팝업)\nWake up + Light exercise/Stretching (Popup: Relieve tension)'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리\nReview of today\'s exam subject'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 시험중\nSchool life, Taking exams'},
    {'time': '14:00 ~ 15:00', 'task': '휴식\nBreak time'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리\nReview for tomorrow\'s subject 1'},
    {'time': '16:00 ~ 16:20', 'task': '휴식\nBreak time'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리\nReview for tomorrow\'s subject 2'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사\nDinner'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리\nReview for tomorrow\'s subject 3'},
    {'time': '19:20 ~ 19:40', 'task': '휴식\nBreak time'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리\nReview for tomorrow\'s subject 1'},
    {'time': '20:40 ~ 21:00', 'task': '휴식\nBreak time'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리\nReview for tomorrow\'s subject 2'},
    {'time': '22:00 ~ 22:20', 'task': '휴식\nBreak time'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리\nReview for tomorrow\'s subject 3'},
    {'time': '23:20 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  /// D+3일까지 (목요일) 타임라인
  static final List<Map<String, String>> finalMonDPlus3 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭 (스트레칭으로 긴장감풀기 – 팝업)\nWake up + Light exercise/Stretching (Popup: Relieve tension)'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리\nReview of today\'s exam subject'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 시험중\nSchool life, Taking exams'},
    {'time': '14:00 ~ 15:00', 'task': '휴식\nBreak time'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리\nReview for tomorrow\'s subject 1'},
    {'time': '16:00 ~ 16:20', 'task': '휴식\nBreak time'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리\nReview for tomorrow\'s subject 2'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사\nDinner'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리\nReview for tomorrow\'s subject 3'},
    {'time': '19:20 ~ 19:40', 'task': '휴식\nBreak time'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리\nReview for tomorrow\'s subject 1'},
    {'time': '20:40 ~ 21:00', 'task': '휴식\nBreak time'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리\nReview for tomorrow\'s subject 2'},
    {'time': '22:00 ~ 22:20', 'task': '휴식\nBreak time'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리\nReview for tomorrow\'s subject 3'},
    {'time': '23:20 ~ 06:00', 'task': '취침\nBedtime'},
  ];
// ==========================================
// 1. EXAM_MON: 기말고사 D-Day가 화요일인 경우
// ==========================================

  /// D-3일 (토요일) 타임라인
  static final List<Map<String, String>> finalTueD3 = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사\nWake up + Light exercise/Breakfast'},
    {'time': '08:00 ~ 09:00', 'task': '사회 시험대비 총정리/ 문제풀이 70%\nSocial Studies total review / Problem solving 70%'},
    {'time': '09:00 ~ 09:20', 'task': '휴식\nBreak time'},
    {'time': '09:20 ~ 10:20', 'task': '과학 시험대비 총정리/ 문제풀이 70%\nScience total review / Problem solving 70%'},
    {'time': '10:20 ~ 10:40', 'task': '휴식\nBreak time'},
    {'time': '10:40 ~ 11:30', 'task': '사회 전체평가\nSocial Studies comprehensive evaluation'},
    {'time': '11:30 ~ 11:50', 'task': '휴식\nBreak time'},
    {'time': '11:50 ~ 12:50', 'task': '국어 시험대비 총정리/문제풀이 70%\nKorean total review / Problem solving 70%'},
    {'time': '12:50 ~ 14:00', 'task': '점심식사 및 휴식\nLunch and break'},
    {'time': '14:00 ~ 14:50', 'task': '과학 전체평가\nScience comprehensive evaluation'},
    {'time': '14:50 ~ 15:10', 'task': '휴식\nBreak time'},
    {'time': '15:10 ~ 16:10', 'task': '수학 시험대비 심화문제50%/오답정리 50%\nMath advanced problems 50% / Mistakes 50%'},
    {'time': '16:10 ~ 16:30', 'task': '휴식\nBreak time'},
    {'time': '16:30 ~ 17:20', 'task': '국어 전체평가\nKorean comprehensive evaluation'},
    {'time': '17:20 ~ 17:40', 'task': '휴식\nBreak time'},
    {'time': '17:40 ~ 18:40', 'task': '영어 시험대비 총정리 및 오답정리\nEnglish total review and mistakes'},
    {'time': '18:40 ~ 20:00', 'task': '저녁식사\nDinner'},
    {'time': '20:00 ~ 20:50', 'task': '수학 전체평가\nMath comprehensive evaluation'},
    {'time': '20:50 ~ 21:10', 'task': '휴식\nBreak time'},
    {'time': '21:10 ~ 22:10', 'task': '기술.가정/한문 암기 및 평가\nTech & Home / Hanja memory & evaluation'},
    {'time': '22:10 ~ 22:20', 'task': '휴식\nBreak time'},
    {'time': '22:20 ~ 23:10', 'task': '영어전체 평가\nEnglish comprehensive evaluation'},
    {'time': '23:10 ~ 23:20', 'task': '휴식 및 취침준비\nBreak time & Prep for bed'},
    {'time': '23:20 ~ 07:00', 'task': '취침\nBedtime'},
  ];

  /// D-2일 (일요일) 타임라인
  static final List<Map<String, String>> finalTueD2 = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사\nWake up + Light exercise/Breakfast'},
    {'time': '08:00 ~ 09:00', 'task': '사회 시험대비 총정리 및 오답정리\nSocial Studies total review and mistakes'},
    {'time': '09:00 ~ 09:20', 'task': '휴식\nBreak time'},
    {'time': '09:20 ~ 10:20', 'task': '과학 시험대비 총정리 및 오답정리\nScience total review and mistakes'},
    {'time': '10:20 ~ 10:40', 'task': '휴식\nBreak time'},
    {'time': '10:40 ~ 11:30', 'task': '사회 전체평가\nSocial Studies comprehensive evaluation'},
    {'time': '11:30 ~ 11:50', 'task': '휴식\nBreak time'},
    {'time': '11:50 ~ 12:50', 'task': '국어 시험대비 총정리 및 오답정리\nKorean total review and mistakes'},
    {'time': '12:50 ~ 14:00', 'task': '점심식사 및 휴식\nLunch and break'},
    {'time': '14:00 ~ 14:50', 'task': '과학 전체평가\nScience comprehensive evaluation'},
    {'time': '14:50 ~ 15:10', 'task': '휴식\nBreak time'},
    {'time': '15:10 ~ 16:10', 'task': '수학 시험대비 심화문제50%/오답정리 50%\nMath advanced problems 50% / Mistakes 50%'},
    {'time': '16:10 ~ 16:30', 'task': '휴식\nBreak time'},
    {'time': '16:30 ~ 17:20', 'task': '국어 전체평가\nKorean comprehensive evaluation'},
    {'time': '17:20 ~ 17:40', 'task': '휴식\nBreak time'},
    {'time': '17:40 ~ 18:40', 'task': '영어 시험대비 총정리 및 오답정리\nEnglish total review and mistakes'},
    {'time': '18:40 ~ 20:00', 'task': '저녁식사\nDinner'},
    {'time': '20:00 ~ 20:50', 'task': '수학 전체평가\nMath comprehensive evaluation'},
    {'time': '20:50 ~ 21:10', 'task': '휴식\nBreak time'},
    {'time': '21:10 ~ 22:10', 'task': '기술.가정/한문 암기 및 평가\nTech & Home / Hanja memory & evaluation'},
    {'time': '22:10 ~ 22:20', 'task': '휴식\nBreak time'},
    {'time': '22:20 ~ 23:10', 'task': '영어전체 평가\nEnglish comprehensive evaluation'},
    {'time': '23:10 ~ 23:20', 'task': '휴식 및 취침준비\nBreak time & Prep for bed'},
    {'time': '23:20 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  /// D-1일까지 (월요일) 타임라인
  static final List<Map<String, String>>  finalTueD1 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭\nWake up + Light exercise/Stretching'},
    {'time': '06:30 ~ 07:30', 'task': '사회 총정리 암기점검20%/ 오답+기출문제 80%, 익일과목 대체가능\nSocial Studies review 20% / Mistakes 80%, Substituted available'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활\nSchool life'},
    {'time': '16:00 ~ 17:00', 'task': '휴식\nBreak time'},
    {'time': '17:00 ~ 18:00', 'task': '과학 총정리 암기점검20%/ 오답+기출문제 80%, 익일과목 대체가능\nScience review 20% / Mistakes 80%, Substituted available'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사\nDinner'},
    {'time': '19:00 ~ 20:00', 'task': '국어 개념정리 20%/오답+기출문제 80%, 익일과목 대체가능\nKorean review 20% / Mistakes 80%, Substituted available'},
    {'time': '20:00 ~ 20:20', 'task': '휴식\nBreak time'},
    {'time': '20:20 ~ 21:20', 'task': '수학 심화문제 50%/오답+기출문제 50% 익일과목 대체가능\nMath advanced 50% / Mistakes 50%, Substituted available'},
    {'time': '21:20 ~ 21:40', 'task': '휴식\nBreak time'},
    {'time': '21:40 ~ 22:40', 'task': '영어 개념정리10%/오답+기출문제 90%, 익일과목 대체가능\nEnglish review 10% / Mistakes 90%, Substituted available'},
    {'time': '22:40 ~ 23:00', 'task': '휴식\nBreak time'},
    {'time': '23:00 ~ 24:00', 'task': '기술.가정/한문 총정리 및 암기\nTech & Home / Hanja total review & memory'},
    {'time': '24:00 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  /// 기말고사 D-Day (화요일) 타임라인
  static final List<Map<String, String>>  finalTueDDay = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭 (스트레칭으로 긴장감풀기 – 팝업)\nWake up + Light exercise/Stretching (Popup: Relieve tension)'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 총정리\nFinal review of today\'s exam subject'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활, 기말고사\nSchool life, Final exams'},
    {'time': '14:00 ~ 15:00', 'task': '휴식\nBreak time'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 총정리\nTotal review for tomorrow\'s subject 1'},
    {'time': '16:00 ~ 16:20', 'task': '휴식\nBreak time'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 총정리\nTotal review for tomorrow\'s subject 2'},
    {'time': '17:20 ~ 17:40', 'task': '휴식\nBreak time'},
    {'time': '17:40 ~ 18:40', 'task': '저녁식사 및 휴식\nDinner and break'},
    {'time': '18:40 ~ 19:40', 'task': '내일 시험과목3 총정리\nTotal review for tomorrow\'s subject 3'},
    {'time': '19:40 ~ 20:00', 'task': '휴식\nBreak time'},
    {'time': '20:00 ~ 21:00', 'task': '내일 시험과목1 총정리\nTotal review for tomorrow\'s subject 1'},
    {'time': '21:00 ~ 21:20', 'task': '휴식\nBreak time'},
    {'time': '21:20 ~ 22:20', 'task': '내일 시험과목2 총정리\nTotal review for tomorrow\'s subject 2'},
    {'time': '22:20 ~ 22:40', 'task': '휴식\nBreak time'},
    {'time': '22:40 ~ 23:40', 'task': '내일 시험과목3 총정리\nTotal review for tomorrow\'s subject 3'},
    {'time': '23:40 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  /// D+1일까지 (수요일) 타임라인
  static final List<Map<String, String>> finalTueDPlus1 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭 (스트레칭으로 긴장감풀기 – 팝업)\nWake up + Light exercise/Stretching (Popup: Relieve tension)'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리\nReview of today\'s exam subject'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 기말 시험중\nSchool life, Taking final exams'},
    {'time': '14:00 ~ 15:00', 'task': '휴식\nBreak time'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리\nReview for tomorrow\'s subject 1'},
    {'time': '16:00 ~ 16:20', 'task': '휴식\nBreak time'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리\nReview for tomorrow\'s subject 2'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사\nDinner'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리\nReview for tomorrow\'s subject 3'},
    {'time': '19:20 ~ 19:40', 'task': '휴식\nBreak time'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리\nReview for tomorrow\'s subject 1'},
    {'time': '20:40 ~ 21:00', 'task': '휴식\nBreak time'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리\nReview for tomorrow\'s subject 2'},
    {'time': '22:00 ~ 22:20', 'task': '휴식\nBreak time'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리\nReview for tomorrow\'s subject 3'},
    {'time': '23:20 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  /// D+2일까지 (목요일) 타임라인
  static final List<Map<String, String>> finalTueDPlus2 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭 (스트레칭으로 긴장감풀기 – 팝업)\nWake up + Light exercise/Stretching (Popup: Relieve tension)'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리\nReview of today\'s exam subject'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 기말 시험중\nSchool life, Taking final exams'},
    {'time': '14:00 ~ 15:00', 'task': '휴식\nBreak time'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리\nReview for tomorrow\'s subject 1'},
    {'time': '16:00 ~ 16:20', 'task': '휴식\nBreak time'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리\nReview for tomorrow\'s subject 2'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사\nDinner'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리\nReview for tomorrow\'s subject 3'},
    {'time': '19:20 ~ 19:40', 'task': '휴식\nBreak time'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리\nReview for tomorrow\'s subject 1'},
    {'time': '20:40 ~ 21:00', 'task': '휴식\nBreak time'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리\nReview for tomorrow\'s subject 2'},
    {'time': '22:00 ~ 22:20', 'task': '휴식\nBreak time'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리\nReview for tomorrow\'s subject 3'},
    {'time': '23:20 ~ 23:30', 'task': '휴식 및 취침준비\nBreak time & Prep for bed'},
    {'time': '23:30 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  /// D+3일까지 (금요일) 타임라인
  static final List<Map<String, String>> finalTueDPlus3 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭 (스트레칭으로 긴장감풀기 – 팝업)\nWake up + Light exercise/Stretching (Popup: Relieve tension)'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리\nReview of today\'s exam subject'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 기말 시험중\nSchool life, Taking final exams'},
    {'time': '14:00 ~ 15:00', 'task': '휴식\nBreak time'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리\nReview for tomorrow\'s subject 1'},
    {'time': '16:00 ~ 16:20', 'task': '휴식\nBreak time'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리\nReview for tomorrow\'s subject 2'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사\nDinner'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리\nReview for tomorrow\'s subject 3'},
    {'time': '19:20 ~ 19:40', 'task': '휴식\nBreak time'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리\nReview for tomorrow\'s subject 1'},
    {'time': '20:40 ~ 21:00', 'task': '휴식\nBreak time'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리\nReview for tomorrow\'s subject 2'},
    {'time': '22:00 ~ 22:20', 'task': '휴식\nBreak time'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리\nReview for tomorrow\'s subject 3'},
    {'time': '23:20 ~ 07:00', 'task': '취침\nBedtime'},
  ];

// ==========================================
// 1. EXAM_MON: 기말고사 D-Day가 수요일인 경우
// ==========================================
  static final List<Map<String, String>> finalWedD3 = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사\nWake up + Light exercise/Breakfast'},
    {'time': '08:00 ~ 09:00', 'task': '사회 시험대비 총정리 및 오답정리\nSocial Studies total review and mistakes'},
    {'time': '09:00 ~ 09:20', 'task': '휴식\nBreak time'},
    {'time': '09:20 ~ 10:20', 'task': '과학 시험대비 총정리 및 오답정리\nScience total review and mistakes'},
    {'time': '10:20 ~ 10:40', 'task': '휴식\nBreak time'},
    {'time': '10:40 ~ 11:30', 'task': '사회 전체평가\nSocial Studies comprehensive evaluation'},
    {'time': '11:30 ~ 11:50', 'task': '휴식\nBreak time'},
    {'time': '11:50 ~ 12:50', 'task': '국어 시험대비 총정리 및 오답정리\nKorean total review and mistakes'},
    {'time': '12:50 ~ 14:00', 'task': '점심식사 및 휴식\nLunch and break'},
    {'time': '14:00 ~ 14:50', 'task': '과학 전체평가\nScience comprehensive evaluation'},
    {'time': '14:50 ~ 15:10', 'task': '휴식\nBreak time'},
    {'time': '15:10 ~ 16:10', 'task': '수학 시험대비 심화문제50%/오답정리 50%\nMath advanced problems 50% / Mistakes 50%'},
    {'time': '16:10 ~ 16:30', 'task': '휴식\nBreak time'},
    {'time': '16:30 ~ 17:20', 'task': '국어 전체평가\nKorean comprehensive evaluation'},
    {'time': '17:20 ~ 17:40', 'task': '휴식\nBreak time'},
    {'time': '17:40 ~ 18:40', 'task': '영어 시험대비 총정리 및 오답정리\nEnglish total review and mistakes'},
    {'time': '18:40 ~ 20:00', 'task': '저녁식사\nDinner'},
    {'time': '20:00 ~ 20:50', 'task': '수학 전체평가\nMath comprehensive evaluation'},
    {'time': '20:50 ~ 21:10', 'task': '휴식\nBreak time'},
    {'time': '21:10 ~ 22:10', 'task': '기술.가정/한문 암기 및 평가\nTech & Home / Hanja memory & evaluation'},
    {'time': '22:10 ~ 22:20', 'task': '휴식\nBreak time'},
    {'time': '22:20 ~ 23:10', 'task': '영어전체 평가\nEnglish comprehensive evaluation'},
    {'time': '23:10 ~ 23:20', 'task': '휴식 및 취침준비\nBreak time & Prep for bed'},
    {'time': '23:20 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  /// D-2일까지 (월요일) 타임라인
  static final List<Map<String, String>> finalWedD2 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭\nWake up + Light exercise/Stretching'},
    {'time': '06:30 ~ 07:30', 'task': '사회 시험대비 총정리 암기점검20%/ 오답+기출문제 80%\nSocial Studies final review & memorization 20% / Mistakes+Past exams 80%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활\nSchool life'},
    {'time': '16:00 ~ 17:00', 'task': '휴식\nBreak time'},
    {'time': '17:00 ~ 18:00', 'task': '과학 시험대비 총정리 암기점검20%/ 오답+기출문제 80%\nScience final review & memorization 20% / Mistakes+Past exams 80%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사\nDinner'},
    {'time': '19:00 ~ 20:00', 'task': '국어 시험대비 개념정리 20%/오답+기출문제 80%\nKorean concept review 20% / Mistakes+Past exams 80%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식\nBreak time'},
    {'time': '20:20 ~ 21:20', 'task': '수학 시험대비 심화문제 50%/오답+기출문제 50%\nMath advanced problems 50% / Mistakes+Past exams 50%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식\nBreak time'},
    {'time': '21:40 ~ 22:40', 'task': '영어 시험대비 개념정리10%/오답+기출문제 90%\nEnglish concept review 10% / Mistakes+Past exams 90%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식\nBreak time'},
    {'time': '23:00 ~ 24:00', 'task': '기술.가정/한문 격일로 개념정리 및 암기\nTech & Home / Hanja alternate concept review & memory'},
    {'time': '24:00 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  /// D-1일까지 (화요일) 타임라인
  static final List<Map<String, String>> finalWedD1 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭\nWake up + Light exercise/Stretching'},
    {'time': '06:30 ~ 07:30', 'task': '사회 총정리 암기점검20%/ 오답+기출문제 80%, 익일과목 대체가능\nSocial Studies review 20% / Mistakes 80%, Substituted available'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활\nSchool life'},
    {'time': '16:00 ~ 17:00', 'task': '휴식\nBreak time'},
    {'time': '17:00 ~ 18:00', 'task': '과학 총정리 암기점검20%/ 오답+기출문제 80%, 익일과목 대체가능\nScience review 20% / Mistakes 80%, Substituted available'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사\nDinner'},
    {'time': '19:00 ~ 20:00', 'task': '국어 개념정리 20%/오답+기출문제 80%, 익일과목 대체가능\nKorean review 20% / Mistakes 80%, Substituted available'},
    {'time': '20:00 ~ 20:20', 'task': '휴식\nBreak time'},
    {'time': '20:20 ~ 21:20', 'task': '수학 심화문제 50%/오답+기출문제 50% 익일과목 대체가능\nMath advanced 50% / Mistakes 50%, Substituted available'},
    {'time': '21:20 ~ 21:40', 'task': '휴식\nBreak time'},
    {'time': '21:40 ~ 22:40', 'task': '영어 개념정리10%/오답+기출문제 90%, 익일과목 대체가능\nEnglish review 10% / Mistakes 90%, Substituted available'},
    {'time': '22:40 ~ 23:00', 'task': '휴식\nBreak time'},
    {'time': '23:00 ~ 24:00', 'task': '기술.가정/한문 총정리 및 암기\nTech & Home / Hanja total review & memory'},
    {'time': '24:00 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  /// 기말고사 D-Day (수요일) 타임라인
  static final List<Map<String, String>> finalWedDDay = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭 (스트레칭으로 긴장감풀기 – 팝업)\nWake up + Light exercise/Stretching (Popup: Relieve tension)'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 총정리\nFinal review of today\'s exam subject'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활, 기말고사\nSchool life, Final exams'},
    {'time': '14:00 ~ 15:00', 'task': '휴식\nBreak time'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 총정리\nTotal review for tomorrow\'s subject 1'},
    {'time': '16:00 ~ 16:20', 'task': '휴식\nBreak time'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 총정리\nTotal review for tomorrow\'s subject 2'},
    {'time': '17:20 ~ 17:40', 'task': '휴식\nBreak time'},
    {'time': '17:40 ~ 18:40', 'task': '저녁식사 및 휴식\nDinner and break'},
    {'time': '18:40 ~ 19:40', 'task': '내일 시험과목3 총정리\nTotal review for tomorrow\'s subject 3'},
    {'time': '19:40 ~ 20:00', 'task': '휴식\nBreak time'},
    {'time': '20:00 ~ 21:00', 'task': '내일 시험과목1 총정리\nTotal review for tomorrow\'s subject 1'},
    {'time': '21:00 ~ 21:20', 'task': '휴식\nBreak time'},
    {'time': '21:20 ~ 22:20', 'task': '내일 시험과목2 총정리\nTotal review for tomorrow\'s subject 2'},
    {'time': '22:20 ~ 22:40', 'task': '휴식\nBreak time'},
    {'time': '22:40 ~ 23:40', 'task': '내일 시험과목3 총정리\nTotal review for tomorrow\'s subject 3'},
    {'time': '23:40 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  /// D+1일까지 (목요일) 타임라인
  static final List<Map<String, String>> finalWedDPlus1 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭 (스트레칭으로 긴장감풀기 – 팝업)\nWake up + Light exercise/Stretching (Popup: Relieve tension)'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리\nReview of today\'s exam subject'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 기말 시험중\nSchool life, Taking final exams'},
    {'time': '14:00 ~ 15:00', 'task': '휴식\nBreak time'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리\nReview for tomorrow\'s subject 1'},
    {'time': '16:00 ~ 16:20', 'task': '휴식\nBreak time'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리\nReview for tomorrow\'s subject 2'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사\nDinner'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리\nReview for tomorrow\'s subject 3'},
    {'time': '19:20 ~ 19:40', 'task': '휴식\nBreak time'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리\nReview for tomorrow\'s subject 1'},
    {'time': '20:40 ~ 21:00', 'task': '휴식\nBreak time'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리\nReview for tomorrow\'s subject 2'},
    {'time': '22:00 ~ 22:20', 'task': '휴식\nBreak time'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리\nReview for tomorrow\'s subject 3'},
    {'time': '23:20 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  /// D+2일까지 (금요일) 타임라인
  static final List<Map<String, String>> finalWedDPlus2 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭 (스트레칭으로 긴장감풀기 – 팝업)\nWake up + Light exercise/Stretching (Popup: Relieve tension)'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리\nReview of today\'s exam subject'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 기말 시험중\nSchool life, Taking final exams'},
    {'time': '14:00 ~ 15:00', 'task': '휴식\nBreak time'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리\nReview for tomorrow\'s subject 1'},
    {'time': '16:00 ~ 16:20', 'task': '휴식\nBreak time'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리\nReview for tomorrow\'s subject 2'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사\nDinner'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리\nReview for tomorrow\'s subject 3'},
    {'time': '19:20 ~ 19:40', 'task': '휴식\nBreak time'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리\nReview for tomorrow\'s subject 1'},
    {'time': '20:40 ~ 21:00', 'task': '휴식\nBreak time'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리\nReview for tomorrow\'s subject 2'},
    {'time': '22:00 ~ 22:20', 'task': '휴식\nBreak time'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리\nReview for tomorrow\'s subject 3'},
    {'time': '23:20 ~ 23:30', 'task': '휴식 및 취침준비\nBreak time & Prep for bed'},
    {'time': '23:30 ~ 07:00', 'task': '취침\nBedtime'},
  ];
  /// D+3일까지 (토요일) 타임라인
  static final List<Map<String, String>> finalWedDPlus3 = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사\nWake up + Light exercise/Breakfast'},
    {'time': '08:00 ~ 09:00', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '09:00 ~ 09:20', 'task': '휴식\nBreak time'},
    {'time': '09:20 ~ 10:20', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '10:20 ~ 10:40', 'task': '휴식\nBreak time'},
    {'time': '10:40 ~ 11:30', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '11:30 ~ 11:50', 'task': '휴식\nBreak time'},
    {'time': '11:50 ~ 12:50', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '12:50 ~ 14:00', 'task': '점심식사 및 휴식\nLunch and break'},
    {'time': '14:00 ~ 14:50', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '14:50 ~ 15:10', 'task': '휴식\nBreak time'},
    {'time': '15:10 ~ 16:10', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '16:10 ~ 16:30', 'task': '휴식\nBreak time'},
    {'time': '16:30 ~ 17:20', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '17:20 ~ 17:40', 'task': '휴식\nBreak time'},
    {'time': '17:40 ~ 18:40', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '18:40 ~ 20:00', 'task': '저녁식사\nDinner'},
    {'time': '20:00 ~ 20:50', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '20:50 ~ 21:10', 'task': '휴식\nBreak time'},
    {'time': '21:10 ~ 22:10', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '22:10 ~ 22:20', 'task': '휴식 취침준비\nBreak time & Prep for bed'},
    {'time': '22:20 ~ 07:00', 'task': '취침\nBedtime'},
  ];

  /// D+4일까지 (일요일) 타임라인
  static final List<Map<String, String>> finalWedDPlus4 = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사\nWake up + Light exercise/Breakfast'},
    {'time': '08:00 ~ 09:00', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '09:00 ~ 09:20', 'task': '휴식\nBreak time'},
    {'time': '09:20 ~ 10:20', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '10:20 ~ 10:40', 'task': '휴식\nBreak time'},
    {'time': '10:40 ~ 11:30', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '11:30 ~ 11:50', 'task': '휴식\nBreak time'},
    {'time': '11:50 ~ 12:50', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '12:50 ~ 14:00', 'task': '점심식사 및 휴식\nLunch and break'},
    {'time': '14:00 ~ 14:50', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '14:50 ~ 15:10', 'task': '휴식\nBreak time'},
    {'time': '15:10 ~ 16:10', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '16:10 ~ 16:30', 'task': '휴식\nBreak time'},
    {'time': '16:30 ~ 17:20', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '17:20 ~ 17:40', 'task': '휴식\nBreak time'},
    {'time': '17:40 ~ 18:40', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '18:40 ~ 20:00', 'task': '저녁식사\nDinner'},
    {'time': '20:00 ~ 20:50', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '20:50 ~ 21:10', 'task': '휴식\nBreak time'},
    {'time': '21:10 ~ 22:10', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '22:10 ~ 22:20', 'task': '휴식 취침준비\nBreak time & Prep for bed'},
    {'time': '22:20 ~ 06:00', 'task': '취침\nBedtime'},
  ];

// ==========================================
// 1. EXAM_MON: 기말고사 D-Day가 목요일인 경우
// ==========================================
  /// D-3일까지 (월요일) 타임라인
  static final List<Map<String, String>> finalThuD3 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭\nWake up + Light exercise/Stretching'},
    {'time': '06:30 ~ 07:30', 'task': '사회 총정리 암기점검20%/ 오답+기출문제 80%\nSocial Studies review 20% / Mistakes 80%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활\nSchool life'},
    {'time': '16:00 ~ 17:00', 'task': '휴식\nBreak time'},
    {'time': '17:00 ~ 18:00', 'task': '과학 총정리 암기점검20%/ 오답+기출문제 80%\nScience review 20% / Mistakes 80%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사\nDinner'},
    {'time': '19:00 ~ 20:00', 'task': '국어 개념정리 20%/오답+기출문제 80%\nKorean review 20% / Mistakes 80%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식\nBreak time'},
    {'time': '20:20 ~ 21:20', 'task': '수학 심화문제 50%/오답+기출문제 50%\nMath advanced 50% / Mistakes 50%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식\nBreak time'},
    {'time': '21:40 ~ 22:40', 'task': '영어 개념정리10%/오답+기출문제 90%\nEnglish review 10% / Mistakes 90%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식\nBreak time'},
    {'time': '23:00 ~ 24:00', 'task': '기술.가정/한문 격일로 개념정리 및 암기\nTech & Home / Hanja alternate concept review & memory'},
    {'time': '24:00 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  /// D-2일까지 (화요일) 타임라인
  static final List<Map<String, String>> finalThuD2 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭\nWake up + Light exercise/Stretching'},
    {'time': '06:30 ~ 07:30', 'task': '사회 총정리 암기점검20%/ 오답+기출문제 80%\nSocial Studies review 20% / Mistakes 80%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활\nSchool life'},
    {'time': '16:00 ~ 17:00', 'task': '휴식\nBreak time'},
    {'time': '17:00 ~ 18:00', 'task': '과학 총정리 암기점검20%/ 오답+기출문제 80%\nScience review 20% / Mistakes 80%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사\nDinner'},
    {'time': '19:00 ~ 20:00', 'task': '국어 개념정리 20%/오답+기출문제 80%\nKorean review 20% / Mistakes 80%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식\nBreak time'},
    {'time': '20:20 ~ 21:20', 'task': '수학 심화문제 50%/오답+기출문제 50%\nMath advanced 50% / Mistakes 50%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식\nBreak time'},
    {'time': '21:40 ~ 22:40', 'task': '영어 개념정리10%/오답+기출문제 90%\nEnglish review 10% / Mistakes 90%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식\nBreak time'},
    {'time': '23:00 ~ 24:00', 'task': '기술.가정/한문 격일로 개념정리 및 암기\nTech & Home / Hanja alternate concept review & memory'},
    {'time': '24:00 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  /// D-1일까지 (수요일) 타임라인
  static final List<Map<String, String>> finalThuD1 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭\nWake up + Light exercise/Stretching'},
    {'time': '06:30 ~ 07:30', 'task': '사회 총정리 암기점검20%/ 오답+기출문제 80%, 익일과목 대체가능\nSocial Studies review 20% / Mistakes 80%, Substituted available'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활\nSchool life'},
    {'time': '16:00 ~ 17:00', 'task': '휴식\nBreak time'},
    {'time': '17:00 ~ 18:00', 'task': '과학 총정리 암기점검20%/ 오답+기출문제 80%, 익일과목 대체가능\nScience review 20% / Mistakes 80%, Substituted available'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사\nDinner'},
    {'time': '19:00 ~ 20:00', 'task': '국어 개념정리 20%/오답+기출문제 80%, 익일과목 대체가능\nKorean review 20% / Mistakes 80%, Substituted available'},
    {'time': '20:00 ~ 20:20', 'task': '휴식\nBreak time'},
    {'time': '20:20 ~ 21:20', 'task': '수학 심화문제 50%/오답+기출문제 50% 익일과목 대체가능\nMath advanced 50% / Mistakes 50%, Substituted available'},
    {'time': '21:20 ~ 21:40', 'task': '휴식\nBreak time'},
    {'time': '21:40 ~ 22:40', 'task': '영어 개념정리10%/오답+기출문제 90%, 익일과목 대체가능\nEnglish review 10% / Mistakes 90%, Substituted available'},
    {'time': '22:40 ~ 23:00', 'task': '휴식\nBreak time'},
    {'time': '23:00 ~ 24:00', 'task': '기술.가정/한문 총정리 및 암기\nTech & Home / Hanja total review & memory'},
    {'time': '24:00 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  /// 기말고사 D-Day (목요일) 타임라인
  static final List<Map<String, String>> finalThuDDay = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭 (스트레칭으로 긴장감풀기 – 팝업)\nWake up + Light exercise/Stretching (Popup: Relieve tension)'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 총정리\nFinal review of today\'s exam subject'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활, 기말고사\nSchool life, Final exams'},
    {'time': '14:00 ~ 15:00', 'task': '휴식\nBreak time'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 총정리\nTotal review for tomorrow\'s subject 1'},
    {'time': '16:00 ~ 16:20', 'task': '휴식\nBreak time'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 총정리\nTotal review for tomorrow\'s subject 2'},
    {'time': '17:20 ~ 17:40', 'task': '휴식\nBreak time'},
    {'time': '17:40 ~ 18:40', 'task': '저녁식사 및 휴식\nDinner and break'},
    {'time': '18:40 ~ 19:40', 'task': '내일 시험과목3 총정리\nTotal review for tomorrow\'s subject 3'},
    {'time': '19:40 ~ 20:00', 'task': '휴식\nBreak time'},
    {'time': '20:00 ~ 21:00', 'task': '내일 시험과목1 총정리\nTotal review for tomorrow\'s subject 1'},
    {'time': '21:00 ~ 21:20', 'task': '휴식\nBreak time'},
    {'time': '21:20 ~ 22:20', 'task': '내일 시험과목2 총정리\nTotal review for tomorrow\'s subject 2'},
    {'time': '22:20 ~ 22:40', 'task': '휴식\nBreak time'},
    {'time': '22:40 ~ 23:40', 'task': '내일 시험과목3 총정리\nTotal review for tomorrow\'s subject 3'},
    {'time': '23:40 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  /// D+1일까지 (금요일) 타임라인
  static final List<Map<String, String>> finalThuDPlus1 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭 (스트레칭으로 긴장감풀기 – 팝업)\nWake up + Light exercise/Stretching (Popup: Relieve tension)'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리\nReview of today\'s exam subject'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 기말 시험중\nSchool life, Taking final exams'},
    {'time': '14:00 ~ 15:00', 'task': '휴식\nBreak time'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리\nReview for tomorrow\'s subject 1'},
    {'time': '16:00 ~ 16:20', 'task': '휴식\nBreak time'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리\nReview for tomorrow\'s subject 2'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사\nDinner'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리\nReview for tomorrow\'s subject 3'},
    {'time': '19:20 ~ 19:40', 'task': '휴식\nBreak time'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리\nReview for tomorrow\'s subject 1'},
    {'time': '20:40 ~ 21:00', 'task': '휴식\nBreak time'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리\nReview for tomorrow\'s subject 2'},
    {'time': '22:00 ~ 22:20', 'task': '휴식\nBreak time'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리\nReview for tomorrow\'s subject 3'},
    {'time': '23:20 ~ 23:30', 'task': '휴식 및 취침준비\nBreak time & Prep for bed'},
    {'time': '23:30 ~ 07:00', 'task': '취침\nBedtime'},
  ];
  /// D+2일까지 (토요일) 타임라인
  static final List<Map<String, String>> finalThuDPlus2 = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사\nWake up + Light exercise/Breakfast'},
    {'time': '08:00 ~ 09:00', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '09:00 ~ 09:20', 'task': '휴식\nBreak time'},
    {'time': '09:20 ~ 10:20', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '10:20 ~ 10:40', 'task': '휴식\nBreak time'},
    {'time': '10:40 ~ 11:30', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '11:30 ~ 11:50', 'task': '휴식\nBreak time'},
    {'time': '11:50 ~ 12:50', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '12:50 ~ 14:00', 'task': '점심식사 및 휴식\nLunch and break'},
    {'time': '14:00 ~ 14:50', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '14:50 ~ 15:10', 'task': '휴식\nBreak time'},
    {'time': '15:10 ~ 16:10', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '16:10 ~ 16:30', 'task': '휴식\nBreak time'},
    {'time': '16:30 ~ 17:20', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '17:20 ~ 17:40', 'task': '휴식\nBreak time'},
    {'time': '17:40 ~ 18:40', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '18:40 ~ 20:00', 'task': '저녁식사\nDinner'},
    {'time': '20:00 ~ 20:50', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '20:50 ~ 21:10', 'task': '휴식\nBreak time'},
    {'time': '21:10 ~ 22:10', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '22:10 ~ 22:20', 'task': '휴식 취침준비\nBreak time & Prep for bed'},
    {'time': '22:20 ~ 07:00', 'task': '취침\nBedtime'},
  ];

  /// D+3일까지 (일요일) 타임라인
  static final List<Map<String, String>> finalThuDPlus3 = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사\nWake up + Light exercise/Breakfast'},
    {'time': '08:00 ~ 09:00', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '09:00 ~ 09:20', 'task': '휴식\nBreak time'},
    {'time': '09:20 ~ 10:20', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '10:20 ~ 10:40', 'task': '휴식\nBreak time'},
    {'time': '10:40 ~ 11:30', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '11:30 ~ 11:50', 'task': '휴식\nBreak time'},
    {'time': '11:50 ~ 12:50', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '12:50 ~ 14:00', 'task': '점심식사 및 휴식\nLunch and break'},
    {'time': '14:00 ~ 14:50', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '14:50 ~ 15:10', 'task': '휴식\nBreak time'},
    {'time': '15:10 ~ 16:10', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '16:10 ~ 16:30', 'task': '휴식\nBreak time'},
    {'time': '16:30 ~ 17:20', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '17:20 ~ 17:40', 'task': '휴식\nBreak time'},
    {'time': '17:40 ~ 18:40', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '18:40 ~ 20:00', 'task': '저녁식사\nDinner'},
    {'time': '20:00 ~ 20:50', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '20:50 ~ 21:10', 'task': '휴식\nBreak time'},
    {'time': '21:10 ~ 22:10', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '22:10 ~ 22:20', 'task': '휴식 취침준비\nBreak time & Prep for bed'},
    {'time': '22:20 ~ 06:00', 'task': '취침\nBedtime'},
  ];
  /// D+4일까지 (월요일) 타임라인
  static final List<Map<String, String>> finalThuDPlus4 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭 (스트레칭으로 긴장감풀기 – 팝업)\nWake up + Light exercise/Stretching (Popup: Relieve tension)'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리\nReview of today\'s exam subject'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 기말 시험중\nSchool life, Taking final exams'},
    {'time': '14:00 ~ 15:00', 'task': '휴식\nBreak time'},
    {'time': '15:00 ~ 16:00', 'task': '익일 시험과목1 정리\nReview for next day subject 1'},
    {'time': '16:00 ~ 16:20', 'task': '휴식\nBreak time'},
    {'time': '16:20 ~ 17:20', 'task': '익일 시험과목2 정리\nReview for next day subject 2'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사\nDinner'},
    {'time': '18:20 ~ 19:20', 'task': '익일 시험과목3 정리\nReview for next day subject 3'},
    {'time': '19:20 ~ 19:40', 'task': '휴식\nBreak time'},
    {'time': '19:40 ~ 20:40', 'task': '익일 시험과목1 정리\nReview for next day subject 1'},
    {'time': '20:40 ~ 21:00', 'task': '휴식\nBreak time'},
    {'time': '21:00 ~ 22:00', 'task': '익일시험과목2 정리\nReview for next day subject 2'},
    {'time': '22:00 ~ 22:20', 'task': '휴식\nBreak time'},
    {'time': '22:20 ~ 23:20', 'task': '익일시험과목3 정리\nReview for next day subject 3'},
    {'time': '23:20 ~ 23:30', 'task': '휴식 및 취침준비\nBreak time & Prep for bed'},
    {'time': '23:30 ~ 07:00', 'task': '취침\nBedtime'},
  ];

// ==========================================
// 1. EXAM_MON: 기말고사 D-Day가 금요일인 경우
// ==========================================
  /// D-3일까지 (화요일) 타임라인
  static final List<Map<String, String>> finalFriD3 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭\nWake up + Light exercise/Stretching'},
    {'time': '06:30 ~ 07:30', 'task': '사회 총정리 암기점검20%/ 오답+기출문제 80%\nSocial Studies review 20% / Mistakes 80%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활\nSchool life'},
    {'time': '16:00 ~ 17:00', 'task': '휴식\nBreak time'},
    {'time': '17:00 ~ 18:00', 'task': '과학 총정리 암기점검20%/ 오답+기출문제 80%\nScience review 20% / Mistakes 80%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사\nDinner'},
    {'time': '19:00 ~ 20:00', 'task': '국어 개념정리 20%/오답+기출문제 80%\nKorean review 20% / Mistakes 80%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식\nBreak time'},
    {'time': '20:20 ~ 21:20', 'task': '수학 심화문제 50%/오답+기출문제 50%\nMath advanced 50% / Mistakes 50%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식\nBreak time'},
    {'time': '21:40 ~ 22:40', 'task': '영어 개념정리10%/오답+기출문제 90%\nEnglish review 10% / Mistakes 90%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식\nBreak time'},
    {'time': '23:00 ~ 24:00', 'task': '기술.가정/한문 격일로 개념정리 및 암기\nTech & Home / Hanja alternate concept review & memory'},
    {'time': '24:00 ~ 07:00', 'task': '취침\nBedtime'},
  ];

  /// D-2일까지 (수요일) 타임라인
  static final List<Map<String, String>> finalFriD2 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭\nWake up + Light exercise/Stretching'},
    {'time': '06:30 ~ 07:30', 'task': '사회 총정리 암기점검20%/ 오답+기출문제 80%\nSocial Studies review 20% / Mistakes 80%'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활\nSchool life'},
    {'time': '16:00 ~ 17:00', 'task': '휴식\nBreak time'},
    {'time': '17:00 ~ 18:00', 'task': '과학 총정리 암기점검20%/ 오답+기출문제 80%\nScience review 20% / Mistakes 80%'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사\nDinner'},
    {'time': '19:00 ~ 20:00', 'task': '국어 개념정리 20%/오답+기출문제 80%\nKorean review 20% / Mistakes 80%'},
    {'time': '20:00 ~ 20:20', 'task': '휴식\nBreak time'},
    {'time': '20:20 ~ 21:20', 'task': '수학 심화문제 50%/오답+기출문제 50%\nMath advanced 50% / Mistakes 50%'},
    {'time': '21:20 ~ 21:40', 'task': '휴식\nBreak time'},
    {'time': '21:40 ~ 22:40', 'task': '영어 개념정리10%/오답+기출문제 90%\nEnglish review 10% / Mistakes 90%'},
    {'time': '22:40 ~ 23:00', 'task': '휴식\nBreak time'},
    {'time': '23:00 ~ 24:00', 'task': '기술.가정/한문 격일로 개념정리 및 암기\nTech & Home / Hanja alternate concept review & memory'},
    {'time': '24:00 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  /// D-1일까지 (목요일) 타임라인
  static final List<Map<String, String>> finalFriD1 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭\nWake up + Light exercise/Stretching'},
    {'time': '06:30 ~ 07:30', 'task': '사회 총정리 암기점검20%/ 오답+기출문제 80%, 익일과목 대체가능\nSocial Studies review 20% / Mistakes 80%, Substituted available'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 16:00', 'task': '학교생활\nSchool life'},
    {'time': '16:00 ~ 17:00', 'task': '휴식\nBreak time'},
    {'time': '17:00 ~ 18:00', 'task': '과학 총정리 암기점검20%/ 오답+기출문제 80%, 익일과목 대체가능\nScience review 20% / Mistakes 80%, Substituted available'},
    {'time': '18:00 ~ 19:00', 'task': '저녁식사\nDinner'},
    {'time': '19:00 ~ 20:00', 'task': '국어 개념정리 20%/오답+기출문제 80%, 익일과목 대체가능\nKorean review 20% / Mistakes 80%, Substituted available'},
    {'time': '20:00 ~ 20:20', 'task': '휴식\nBreak time'},
    {'time': '20:20 ~ 21:20', 'task': '수학 심화문제 50%/오답+기출문제 50% 익일과목 대체가능\nMath advanced 50% / Mistakes 50%, Substituted available'},
    {'time': '21:20 ~ 21:40', 'task': '휴식\nBreak time'},
    {'time': '21:40 ~ 22:40', 'task': '영어 개념정리10%/오답+기출문제 90%, 익일과목 대체가능\nEnglish review 10% / Mistakes 90%, Substituted available'},
    {'time': '22:40 ~ 23:00', 'task': '휴식\nBreak time'},
    {'time': '23:00 ~ 24:00', 'task': '기술.가정/한문 총정리 및 암기\nTech & Home / Hanja total review & memory'},
    {'time': '23:00 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  /// 기말고사 D-Day (금요일) 타임라인
  static final List<Map<String, String>> finalFriDDay = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭 (스트레칭으로 긴장감풀기 – 팝업)\nWake up + Light exercise/Stretching (Popup: Relieve tension)'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 총정리\nFinal review of today\'s exam subject'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활, 기말고사\nSchool life, Final exams'},
    {'time': '14:00 ~ 15:00', 'task': '휴식\nBreak time'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 총정리\nTotal review for tomorrow\'s subject 1'},
    {'time': '16:00 ~ 16:20', 'task': '휴식\nBreak time'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 총정리\nTotal review for tomorrow\'s subject 2'},
    {'time': '17:20 ~ 17:40', 'task': '휴식\nBreak time'},
    {'time': '17:40 ~ 18:40', 'task': '저녁식사 및 휴식\nDinner and break'},
    {'time': '18:40 ~ 19:40', 'task': '내일 시험과목3 총정리\nTotal review for tomorrow\'s subject 3'},
    {'time': '19:40 ~ 20:00', 'task': '휴식\nBreak time'},
    {'time': '20:00 ~ 21:00', 'task': '내일 시험과목1 총정리\nTotal review for tomorrow\'s subject 1'},
    {'time': '21:00 ~ 21:20', 'task': '휴식\nBreak time'},
    {'time': '21:20 ~ 22:20', 'task': '내일 시험과목2 총정리\nTotal review for tomorrow\'s subject 2'},
    {'time': '22:20 ~ 22:40', 'task': '휴식\nBreak time'},
    {'time': '22:40 ~ 23:40', 'task': '내일 시험과목3 총정리\nTotal review for tomorrow\'s subject 3'},
    {'time': '23:40 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  /// D+1일까지 (토요일) 타임라인
  static final List<Map<String, String>> finalFriDPlus1 = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사\nWake up + Light exercise/Breakfast'},
    {'time': '08:00 ~ 09:00', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '09:00 ~ 09:20', 'task': '휴식\nBreak time'},
    {'time': '09:20 ~ 10:20', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '10:20 ~ 10:40', 'task': '휴식\nBreak time'},
    {'time': '10:40 ~ 11:30', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '11:30 ~ 11:50', 'task': '휴식\nBreak time'},
    {'time': '11:50 ~ 12:50', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '12:50 ~ 14:00', 'task': '점심식사 및 휴식\nLunch and break'},
    {'time': '14:00 ~ 14:50', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '14:50 ~ 15:10', 'task': '휴식\nBreak time'},
    {'time': '15:10 ~ 16:10', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '16:10 ~ 16:30', 'task': '휴식\nBreak time'},
    {'time': '16:30 ~ 17:20', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '17:20 ~ 17:40', 'task': '휴식\nBreak time'},
    {'time': '17:40 ~ 18:40', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '18:40 ~ 20:00', 'task': '저녁식사\nDinner'},
    {'time': '20:00 ~ 20:50', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '20:50 ~ 21:10', 'task': '휴식\nBreak time'},
    {'time': '21:10 ~ 22:10', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '22:10 ~ 22:20', 'task': '휴식 취침준비\nBreak time & Prep for bed'},
    {'time': '22:20 ~ 07:00', 'task': '취침\nBedtime'},
  ];

  /// D+2일까지 (일요일) 타임라인
  static final List<Map<String, String>> finalFriDPlus2 = [
    {'time': '07:00 ~ 08:00', 'task': '기상+가벼운 운동/아침식사\nWake up + Light exercise/Breakfast'},
    {'time': '08:00 ~ 09:00', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '09:00 ~ 09:20', 'task': '휴식\nBreak time'},
    {'time': '09:20 ~ 10:20', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '10:20 ~ 10:40', 'task': '휴식\nBreak time'},
    {'time': '10:40 ~ 11:30', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '11:30 ~ 11:50', 'task': '휴식\nBreak time'},
    {'time': '11:50 ~ 12:50', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '12:50 ~ 14:00', 'task': '점심식사 및 휴식\nLunch and break'},
    {'time': '14:00 ~ 14:50', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '14:50 ~ 15:10', 'task': '휴식\nBreak time'},
    {'time': '15:10 ~ 16:10', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '16:10 ~ 16:30', 'task': '휴식\nBreak time'},
    {'time': '16:30 ~ 17:20', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '17:20 ~ 17:40', 'task': '휴식\nBreak time'},
    {'time': '17:40 ~ 18:40', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '18:40 ~ 20:00', 'task': '저녁식사\nDinner'},
    {'time': '20:00 ~ 20:50', 'task': '나머지 과목 전체평가\nRemaining subjects comprehensive evaluation'},
    {'time': '20:50 ~ 21:10', 'task': '휴식\nBreak time'},
    {'time': '21:10 ~ 22:10', 'task': '나머지 과목 총정리 집중\nFocus on remaining subjects total review'},
    {'time': '22:10 ~ 22:20', 'task': '휴식 취침준비\nBreak time & Prep for bed'},
    {'time': '22:20 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  /// D+3일까지 (월요일) 타임라인
  static final List<Map<String, String>> finalFriDPlus3 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭 (스트레칭으로 긴장감풀기 – 팝업)\nWake up + Light exercise/Stretching (Popup: Relieve tension)'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리\nReview of today\'s exam subject'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 기말 시험중\nSchool life, Taking final exams'},
    {'time': '14:00 ~ 15:00', 'task': '휴식\nBreak time'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리\nReview for tomorrow\'s subject 1'},
    {'time': '16:00 ~ 16:20', 'task': '휴식\nBreak time'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리\nReview for tomorrow\'s subject 2'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사\nDinner'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리\nReview for tomorrow\'s subject 3'},
    {'time': '19:20 ~ 19:40', 'task': '휴식\nBreak time'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리\nReview for tomorrow\'s subject 1'},
    {'time': '20:40 ~ 21:00', 'task': '휴식\nBreak time'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리\nReview for tomorrow\'s subject 2'},
    {'time': '22:00 ~ 22:20', 'task': '휴식\nBreak time'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리\nReview for tomorrow\'s subject 3'},
    {'time': '23:20 ~ 23:30', 'task': '휴식 및 취침준비\nBreak time & Prep for bed'},
    {'time': '23:30 ~ 06:00', 'task': '취침\nBedtime'},
  ];

  /// D+4일까지 (화요일) 타임라인
  static final List<Map<String, String>> finalFriDPlus4 = [
    {'time': '06:00 ~ 06:30', 'task': '기상+가벼운 운동/스트레칭 (스트레칭으로 긴장감풀기 – 팝업)\nWake up + Light exercise/Stretching (Popup: Relieve tension)'},
    {'time': '06:30 ~ 07:30', 'task': '당일 시험과목 정리\nReview of today\'s exam subject'},
    {'time': '07:30 ~ 08:00', 'task': '아침식사 / 등교\nBreakfast / Going to school'},
    {'time': '08:00 ~ 14:00', 'task': '학교생활 기말 시험중\nSchool life, Taking final exams'},
    {'time': '14:00 ~ 15:00', 'task': '휴식\nBreak time'},
    {'time': '15:00 ~ 16:00', 'task': '내일 시험과목1 정리\nReview for tomorrow\'s subject 1'},
    {'time': '16:00 ~ 16:20', 'task': '휴식\nBreak time'},
    {'time': '16:20 ~ 17:20', 'task': '내일 시험과목2 정리\nReview for tomorrow\'s subject 2'},
    {'time': '17:20 ~ 18:20', 'task': '저녁식사\nDinner'},
    {'time': '18:20 ~ 19:20', 'task': '내일 시험과목3 정리\nReview for tomorrow\'s subject 3'},
    {'time': '19:20 ~ 19:40', 'task': '휴식\nBreak time'},
    {'time': '19:40 ~ 20:40', 'task': '내일 시험과목1 정리\nReview for tomorrow\'s subject 1'},
    {'time': '20:40 ~ 21:00', 'task': '휴식\nBreak time'},
    {'time': '21:00 ~ 22:00', 'task': '내일시험과목2 정리\nReview for tomorrow\'s subject 2'},
    {'time': '22:00 ~ 22:20', 'task': '휴식\nBreak time'},
    {'time': '22:20 ~ 23:20', 'task': '내일시험과목3 정리\nReview for tomorrow\'s subject 3'},
    {'time': '23:20 ~ 23:30', 'task': '휴식 및 취침준비\nBreak time & Prep for bed'},
    {'time': '23:30 ~ 06:00', 'task': '취침\nBedtime'},
  ];
  }

