import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimerCalculatorScreen extends StatefulWidget {
  const TimerCalculatorScreen({super.key});

  @override
  State<TimerCalculatorScreen> createState() => _TimerCalculatorScreenState();
}

class _TimerCalculatorScreenState extends State<TimerCalculatorScreen> {
  static const Color _bg = Color(0xFF050A14);
  static const Color _panel = Color(0xFF0D1627);
  static const Color _panelLight = Color(0xFF131F34);
  static const Color _gold = Color(0xFFE5C158);
  static const Color _goldLight = Color(0xFFFFF3C4);
  static const Color _text = Color(0xFFF5F1E4);
  static const Color _muted = Color(0xFF9DA8BA);

  Timer? _timer;

  int _timerSeconds = 5 * 60;
  int _remainingSeconds = 5 * 60;
  bool _timerRunning = false;

  Stopwatch _stopwatch = Stopwatch();
  Timer? _stopwatchTicker;
  Duration _stopwatchDisplay = Duration.zero;

  TimeOfDay? _alarmTime;
  bool _alarmEnabled = false;

  String _calculatorDisplay = '0';
  double? _firstNumber;
  String? _operation;
  bool _waitingForSecondNumber = false;

  final TextEditingController _amountController =
  TextEditingController(text: '100');

  final TextEditingController _rateController =
  TextEditingController(text: '1350');

  String _fromCurrency = 'USD';
  String _toCurrency = 'KRW';

  final List<String> _currencies = const [
    'KRW',
    'USD',
    'JPY',
    'EUR',
    'CNY',
    'GBP',
    'AUD',
    'CAD',
  ];

  @override
  void initState() {
    super.initState();

    _stopwatch = Stopwatch();
    _stopwatchTicker = Timer.periodic(
      const Duration(milliseconds: 30),
          (_) {
        if (!mounted) return;
        if (_stopwatch.isRunning) {
          setState(() {
            _stopwatchDisplay = _stopwatch.elapsed;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatchTicker?.cancel();
    _amountController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // TIMER
  // --------------------------------------------------------------------------

  void _startTimer() {
    if (_remainingSeconds <= 0) return;

    _timer?.cancel();

    setState(() {
      _timerRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();

        setState(() {
          _remainingSeconds = 0;
          _timerRunning = false;
        });

        _showMessage('타이머가 종료되었습니다.');
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();

    setState(() {
      _timerRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();

    setState(() {
      _timerRunning = false;
      _remainingSeconds = _timerSeconds;
    });
  }

  Future<void> _setTimer() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        int minutes = (_remainingSeconds ~/ 60).clamp(1, 999);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _panel,
              title: Text(
                '타이머 설정',
                style: GoogleFonts.notoSansKr(
                  color: _goldLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$minutes분',
                    style: GoogleFonts.notoSansKr(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: minutes.toDouble(),
                    min: 1,
                    max: 180,
                    divisions: 179,
                    activeColor: _gold,
                    onChanged: (value) {
                      setDialogState(() {
                        minutes = value.round();
                      });
                    },
                  ),
                  Text(
                    '1분 ~ 180분',
                    style: GoogleFonts.notoSansKr(color: _muted),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, minutes),
                  child: Text(
                    '설정',
                    style: TextStyle(color: _gold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    _timer?.cancel();

    setState(() {
      _timerSeconds = result * 60;
      _remainingSeconds = _timerSeconds;
      _timerRunning = false;
    });
  }

  String _formatTimer(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  // --------------------------------------------------------------------------
  // STOPWATCH
  // --------------------------------------------------------------------------

  void _toggleStopwatch() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
      } else {
        _stopwatch.start();
      }
    });
  }

  void _resetStopwatch() {
    setState(() {
      _stopwatch.stop();
      _stopwatch.reset();
      _stopwatchDisplay = Duration.zero;
    });
  }

  String _formatStopwatch(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final hundredths =
    (duration.inMilliseconds.remainder(1000) ~/ 10);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${hundredths.toString().padLeft(2, '0')}';
  }

  // --------------------------------------------------------------------------
  // ALARM
  // --------------------------------------------------------------------------

  Future<void> _selectAlarmTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _alarmTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _gold,
              surface: _panel,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _alarmTime = picked;
      _alarmEnabled = true;
    });
  }

  // --------------------------------------------------------------------------
  // CALCULATOR
  // --------------------------------------------------------------------------

  void _calculatorInput(String value) {
    setState(() {
      if (_calculatorDisplay == '0' || _waitingForSecondNumber) {
        _calculatorDisplay = value;
        _waitingForSecondNumber = false;
      } else {
        _calculatorDisplay += value;
      }
    });
  }

  void _calculatorDecimal() {
    setState(() {
      if (_waitingForSecondNumber) {
        _calculatorDisplay = '0.';
        _waitingForSecondNumber = false;
      } else if (!_calculatorDisplay.contains('.')) {
        _calculatorDisplay += '.';
      }
    });
  }

  void _calculatorOperation(String operation) {
    final current = double.tryParse(_calculatorDisplay);

    if (current == null) return;

    setState(() {
      if (_firstNumber != null && _operation != null) {
        final result = _calculate(_firstNumber!, current, _operation!);
        _calculatorDisplay = _formatNumber(result);
        _firstNumber = result;
      } else {
        _firstNumber = current;
      }

      _operation = operation;
      _waitingForSecondNumber = true;
    });
  }

  void _calculatorEquals() {
    final second = double.tryParse(_calculatorDisplay);

    if (_firstNumber == null || _operation == null || second == null) {
      return;
    }

    final result = _calculate(_firstNumber!, second, _operation!);

    setState(() {
      _calculatorDisplay = _formatNumber(result);
      _firstNumber = null;
      _operation = null;
      _waitingForSecondNumber = true;
    });
  }

  double _calculate(double a, double b, String operation) {
    switch (operation) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        return b == 0 ? 0 : a / b;
      default:
        return b;
    }
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(8)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  void _calculatorClear() {
    setState(() {
      _calculatorDisplay = '0';
      _firstNumber = null;
      _operation = null;
      _waitingForSecondNumber = false;
    });
  }

  void _calculatorDelete() {
    setState(() {
      if (_calculatorDisplay.length <= 1) {
        _calculatorDisplay = '0';
      } else {
        _calculatorDisplay =
            _calculatorDisplay.substring(0, _calculatorDisplay.length - 1);
      }
    });
  }

  // --------------------------------------------------------------------------
  // CURRENCY
  // --------------------------------------------------------------------------

  double _currencyResult() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;

    return amount * rate;
  }

  void _swapCurrency() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
  }

  // --------------------------------------------------------------------------
  // WORLD TIME
  // --------------------------------------------------------------------------

  String _worldTime(int utcOffset) {
    final utc = DateTime.now().toUtc();
    final local = utc.add(Duration(hours: utcOffset));

    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  // --------------------------------------------------------------------------
  // UI
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _gold),
        title: Column(
          children: [
            Text(
              'TIMER CALCULATOR',
              style: GoogleFonts.gowunBatang(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              '타이머 계산기',
              style: GoogleFonts.notoSansKr(
                color: _gold,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          child: Column(
            children: [
              _buildTimerCard(),
              const SizedBox(height: 16),
              _buildStopwatchCard(),
              const SizedBox(height: 16),
              _buildAlarmCard(),
              const SizedBox(height: 16),
              _buildWorldClockCard(),
              const SizedBox(height: 16),
              _buildCalculatorCard(),
              const SizedBox(height: 16),
              _buildCurrencyCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(18),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _gold.withOpacity(0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(
      String english,
      String korean,
      IconData icon,
      ) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _gold.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _gold.withOpacity(0.20),
            ),
          ),
          child: Icon(
            icon,
            color: _gold,
            size: 20,
          ),
        ),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              english,
              style: GoogleFonts.gowunBatang(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              korean,
              style: GoogleFonts.notoSansKr(
                color: _gold,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimerCard() {
    final progress = _timerSeconds == 0
        ? 0.0
        : _remainingSeconds / _timerSeconds;

    return _buildCard(
      child: Column(
        children: [
          _sectionHeader(
            'TIMER',
            '시간 측정',
            Icons.timer_outlined,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: 190,
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 7,
                    backgroundColor: Colors.white.withOpacity(0.06),
                    valueColor:
                    const AlwaysStoppedAnimation<Color>(_gold),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatTimer(_remainingSeconds),
                      style: GoogleFonts.notoSans(
                        color: _goldLight,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      _timerRunning ? 'RUNNING' : 'READY',
                      style: GoogleFonts.notoSans(
                        color: _muted,
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: _timerRunning ? '일시정지' : '시작',
                  icon: _timerRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  onTap:
                  _timerRunning ? _pauseTimer : _startTimer,
                  primary: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  label: '설정',
                  icon: Icons.tune_rounded,
                  onTap: _setTimer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  label: '초기화',
                  icon: Icons.refresh_rounded,
                  onTap: _resetTimer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStopwatchCard() {
    return _buildCard(
      child: Column(
        children: [
          _sectionHeader(
            'STOPWATCH',
            '스톱워치',
            Icons.speed_rounded,
          ),
          const SizedBox(height: 22),
          Text(
            _formatStopwatch(_stopwatchDisplay),
            style: GoogleFonts.notoSans(
              color: _goldLight,
              fontSize: 32,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: _stopwatch.isRunning ? '일시정지' : '시작',
                  icon: _stopwatch.isRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  onTap: _toggleStopwatch,
                  primary: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  label: '초기화',
                  icon: Icons.refresh_rounded,
                  onTap: _resetStopwatch,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmCard() {
    return _buildCard(
      child: Column(
        children: [
          _sectionHeader(
            'ALARM',
            '알람',
            Icons.alarm_rounded,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectAlarmTime,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _panelLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: _gold,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _alarmTime == null
                              ? '--:--'
                              : _alarmTime!.format(context),
                          style: GoogleFonts.notoSans(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: _alarmEnabled,
                activeColor: _gold,
                onChanged: _alarmTime == null
                    ? null
                    : (value) {
                  setState(() {
                    _alarmEnabled = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _alarmTime == null
                  ? '알람 시간을 설정해 주세요.'
                  : _alarmEnabled
                  ? '알람이 설정되었습니다.'
                  : '알람이 꺼져 있습니다.',
              style: GoogleFonts.notoSansKr(
                color: _muted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorldClockCard() {
    const cities = [
      ('서울', 'SEOUL', 9),
      ('도쿄', 'TOKYO', 9),
      ('런던', 'LONDON', 0),
      ('파리', 'PARIS', 1),
      ('두바이', 'DUBAI', 4),
      ('뉴욕', 'NEW YORK', -4),
      ('LA', 'LOS ANGELES', -7),
      ('싱가포르', 'SINGAPORE', 8),
    ];

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'WORLD CLOCK',
            '세계시간',
            Icons.public_rounded,
          ),
          const SizedBox(height: 18),
          GridView.builder(
            itemCount: cities.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.15,
            ),
            itemBuilder: (context, index) {
              final city = cities[index];

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _panelLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      city.$1,
                      style: GoogleFonts.notoSansKr(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      city.$2,
                      style: GoogleFonts.notoSans(
                        color: _muted,
                        fontSize: 8,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _worldTime(city.$3),
                      style: GoogleFonts.notoSans(
                        color: _gold,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorCard() {
    final buttons = [
      'AC',
      '⌫',
      '÷',
      '×',
      '7',
      '8',
      '9',
      '-',
      '4',
      '5',
      '6',
      '+',
      '1',
      '2',
      '3',
      '=',
      '0',
      '.',
    ];

    return _buildCard(
      child: Column(
        children: [
          _sectionHeader(
            'CALCULATOR',
            '계산기',
            Icons.calculate_outlined,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF080E19),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              _calculatorDisplay,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.notoSans(
                color: _goldLight,
                fontSize: 30,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            itemCount: buttons.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.45,
            ),
            itemBuilder: (context, index) {
              final value = buttons[index];

              return _calculatorButton(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _calculatorButton(String value) {
    final isOperator =
    ['÷', '×', '-', '+', '='].contains(value);

    final isClear = value == 'AC' || value == '⌫';

    return InkWell(
      onTap: () {
        if (value == 'AC') {
          _calculatorClear();
        } else if (value == '⌫') {
          _calculatorDelete();
        } else if (value == '.') {
          _calculatorDecimal();
        } else if (isOperator) {
          if (value == '=') {
            _calculatorEquals();
          } else {
            _calculatorOperation(value);
          }
        } else {
          _calculatorInput(value);
        }
      },
      borderRadius: BorderRadius.circular(13),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isOperator
              ? _gold.withOpacity(0.15)
              : isClear
              ? Colors.white.withOpacity(0.07)
              : _panelLight,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isOperator
                ? _gold.withOpacity(0.20)
                : Colors.white.withOpacity(0.04),
          ),
        ),
        child: Text(
          value,
          style: GoogleFonts.notoSans(
            color: isOperator ? _gold : Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'CURRENCY',
            '환율 계산',
            Icons.currency_exchange_rounded,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _currencyDropdown(
                  value: _fromCurrency,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _fromCurrency = value;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: IconButton(
                  onPressed: _swapCurrency,
                  icon: const Icon(
                    Icons.swap_horiz_rounded,
                    color: _gold,
                  ),
                ),
              ),
              Expanded(
                child: _currencyDropdown(
                  value: _toCurrency,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _toCurrency = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('금액'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _rateController,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(
              '환율  1 $_fromCurrency = ? $_toCurrency',
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _gold.withOpacity(0.16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '계산 결과',
                  style: GoogleFonts.notoSansKr(
                    color: _muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatNumber(_currencyResult())} $_toCurrency',
                  style: GoogleFonts.notoSans(
                    color: _goldLight,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '※ 현재 환율은 직접 입력하여 계산합니다. 실시간 환율 API는 별도 연결 단계에서 적용합니다.',
            style: GoogleFonts.notoSansKr(
              color: _muted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _currencyDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _panelLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: _panel,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _gold,
          ),
          style: GoogleFonts.notoSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          items: _currencies.map((currency) {
            return DropdownMenuItem(
              value: currency,
              child: Text(currency),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.notoSansKr(
        color: _muted,
        fontSize: 11,
      ),
      filled: true,
      fillColor: _panelLight,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: _gold,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: primary
                ? _gold.withOpacity(0.16)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: primary
                  ? _gold.withOpacity(0.28)
                  : Colors.white.withOpacity(0.07),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: primary ? _gold : Colors.white70,
                size: 19,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.notoSansKr(
                  color: primary ? _goldLight : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.notoSansKr(),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}