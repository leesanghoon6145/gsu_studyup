// ============================================================================
// 🆕 [일반 플래너 - 국경일 표시 + 대체공휴일 계산] KoreaHolidays
// 대한민국 공휴일을 캘린더에서 빨강으로 표시하기 위한 데이터 + 대체공휴일 계산.
//
// - 양력 고정 공휴일: 매년 같은 날짜이므로 계산으로 영구히 정확함.
// - 음력 기준 공휴일(설날/추석/부처님오신날): 2025~2030년 날짜를 표로 미리
//   넣어두었습니다. 2031년 이후에는 이 표에 새 연도 데이터만 추가하면 됩니다.
// - 🆕 [대체공휴일] 아래 대상 공휴일이 토/일요일과 겹치면, 그 다음 첫 평일
//   (다른 공휴일과도 안 겹치는 날)을 자동으로 대체공휴일로 계산합니다.
//   대체공휴일 적용 대상: 설날, 추석, 어린이날, 삼일절, 광복절, 개천절, 한글날,
//   부처님오신날, 성탄절. (신정, 현충일은 대체공휴일 적용 대상이 아님)
//   ⚠️ 참고: 대체공휴일 제도는 시기별로 계속 확대되어 왔습니다. 출시 전
//   실제 정부 발표 공휴일 달력과 한 번 대조 확인을 권장합니다.
// ============================================================================

class _HolidayBlock {
  final String baseName;
  final List<String> dates; // 'yyyy-MM-dd' 목록 (연휴 여러 날이면 여러 개)
  final bool substituteEligible;
  const _HolidayBlock({required this.baseName, required this.dates, required this.substituteEligible});
}

class KoreaHolidays {
  // 🆕 양력 고정 공휴일: 'MM-dd' -> {이름, 대체공휴일 대상 여부}
  static const Map<String, _FixedHoliday> _fixedHolidays = {
    '01-01': _FixedHoliday('신정', false),
    '03-01': _FixedHoliday('삼일절', true),
    '05-05': _FixedHoliday('어린이날', true),
    '06-06': _FixedHoliday('현충일', false),
    '08-15': _FixedHoliday('광복절', true),
    '10-03': _FixedHoliday('개천절', true),
    '10-09': _FixedHoliday('한글날', true),
    '12-25': _FixedHoliday('성탄절', true),
  };

  // 🆕 음력 기준 공휴일 블록 (연휴 단위로 그룹화 - 대체공휴일 계산에 사용)
  static const List<_HolidayBlock> _lunarBlocks = [
    // 2025년
    _HolidayBlock(baseName: '설날', dates: ['2025-01-28', '2025-01-29', '2025-01-30'], substituteEligible: true),
    _HolidayBlock(baseName: '부처님오신날', dates: ['2025-05-05'], substituteEligible: true),
    _HolidayBlock(baseName: '추석', dates: ['2025-10-05', '2025-10-06', '2025-10-07'], substituteEligible: true),
    // 2026년
    _HolidayBlock(baseName: '설날', dates: ['2026-02-16', '2026-02-17', '2026-02-18'], substituteEligible: true),
    _HolidayBlock(baseName: '부처님오신날', dates: ['2026-05-24'], substituteEligible: true),
    _HolidayBlock(baseName: '추석', dates: ['2026-09-24', '2026-09-25', '2026-09-26'], substituteEligible: true),
    // 2027년
    _HolidayBlock(baseName: '설날', dates: ['2027-02-06', '2027-02-07', '2027-02-08'], substituteEligible: true),
    _HolidayBlock(baseName: '부처님오신날', dates: ['2027-05-13'], substituteEligible: true),
    _HolidayBlock(baseName: '추석', dates: ['2027-09-14', '2027-09-15', '2027-09-16'], substituteEligible: true),
    // 2028년
    _HolidayBlock(baseName: '설날', dates: ['2028-01-26', '2028-01-27', '2028-01-28'], substituteEligible: true),
    _HolidayBlock(baseName: '부처님오신날', dates: ['2028-05-02'], substituteEligible: true),
    _HolidayBlock(baseName: '추석', dates: ['2028-10-02', '2028-10-03', '2028-10-04'], substituteEligible: true),
    // 2029년
    _HolidayBlock(baseName: '설날', dates: ['2029-02-12', '2029-02-13', '2029-02-14'], substituteEligible: true),
    _HolidayBlock(baseName: '부처님오신날', dates: ['2029-05-20'], substituteEligible: true),
    _HolidayBlock(baseName: '추석', dates: ['2029-09-21', '2029-09-22', '2029-09-23'], substituteEligible: true),
    // 2030년
    _HolidayBlock(baseName: '설날', dates: ['2030-02-02', '2030-02-03', '2030-02-04'], substituteEligible: true),
    _HolidayBlock(baseName: '부처님오신날', dates: ['2030-05-09'], substituteEligible: true),
    _HolidayBlock(baseName: '추석', dates: ['2030-09-11', '2030-09-12', '2030-09-13'], substituteEligible: true),
  ];

  // 🆕 [대체공휴일 캐시] 연도별로 한 번만 계산해서 저장 ('yyyy-MM-dd' -> 원래 공휴일 이름)
  static final Map<int, Map<String, String>> _substituteCache = {};

  static String _ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static bool _isWeekend(DateTime d) => d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

  // 🆕 해당 연도의 대체공휴일을 계산해서 캐시에 저장
  static void _ensureComputed(int year) {
    if (_substituteCache.containsKey(year)) return;

    // 1. 이 연도의 모든 공휴일(양력 고정 + 음력 블록)을 날짜 집합으로 모음
    final Set<String> allHolidayDates = {};

    _fixedHolidays.forEach((mmdd, info) {
      final parts = mmdd.split('-');
      final date = DateTime(year, int.parse(parts[0]), int.parse(parts[1]));
      allHolidayDates.add(_ymd(date));
    });

    final List<_HolidayBlock> blocksThisYear = _lunarBlocks.where((b) => b.dates.first.startsWith('$year-')).toList();
    for (final block in blocksThisYear) {
      allHolidayDates.addAll(block.dates);
    }

    final Map<String, String> substitutes = {};

    // 2. 양력 고정 공휴일 중 대체공휴일 대상만 검사 (단일 날짜 블록으로 취급)
    _fixedHolidays.forEach((mmdd, info) {
      if (!info.substituteEligible) return;
      final parts = mmdd.split('-');
      final date = DateTime(year, int.parse(parts[0]), int.parse(parts[1]));
      if (_isWeekend(date)) {
        final substituteDate = _findNextFreeWeekday(date, allHolidayDates);
        substitutes[_ymd(substituteDate)] = info.name;
        allHolidayDates.add(_ymd(substituteDate));
      }
    });

    // 3. 음력 연휴 블록(설날/추석/부처님오신날) 검사 - 블록 내 하루라도 주말이면 대체공휴일 발생
    for (final block in blocksThisYear) {
      if (!block.substituteEligible) continue;
      final dates = block.dates.map((s) {
        final p = s.split('-');
        return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      }).toList();

      final bool anyWeekend = dates.any(_isWeekend);
      if (anyWeekend) {
        final lastDay = dates.last;
        final substituteDate = _findNextFreeWeekday(lastDay, allHolidayDates);
        substitutes[_ymd(substituteDate)] = block.baseName;
        allHolidayDates.add(_ymd(substituteDate));
      }
    }

    _substituteCache[year] = substitutes;
  }

  // 🆕 주어진 날짜 다음부터, 주말도 아니고 이미 공휴일도 아닌 첫 번째 날짜를 찾음
  static DateTime _findNextFreeWeekday(DateTime from, Set<String> occupiedDates) {
    DateTime candidate = from.add(const Duration(days: 1));
    while (_isWeekend(candidate) || occupiedDates.contains(_ymd(candidate))) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  // 🆕 이 날짜가 공휴일이면 이름을 반환, 아니면 null (대체공휴일 포함)
  static String? nameOf(DateTime date) {
    final String mmdd = '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (_fixedHolidays.containsKey(mmdd)) return _fixedHolidays[mmdd]!.name;

    final String ymd = _ymd(date);
    for (final block in _lunarBlocks) {
      if (block.dates.contains(ymd)) {
        return block.dates.length > 1 && ymd != block.dates[block.dates.length ~/ 2]
            ? '${block.baseName} 연휴'
            : block.baseName;
      }
    }

    _ensureComputed(date.year);
    final substitute = _substituteCache[date.year]?[ymd];
    if (substitute != null) return '대체공휴일 ($substitute)';

    return null;
  }

  static bool isHoliday(DateTime date) => nameOf(date) != null;
}

class _FixedHoliday {
  final String name;
  final bool substituteEligible;
  const _FixedHoliday(this.name, this.substituteEligible);
}
