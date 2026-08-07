// 🆕 [일반 플래너 3단계] YearlyGoalScreen - period_goal_screen.dart의 공용 구현을
// 연간 목표용으로 얇게 감싼 화면입니다. 실제 로직/디자인은 PeriodGoalScreen에 있습니다.
import 'package:flutter/material.dart';
import 'period_goal_screen.dart';

class YearlyGoalScreen extends StatelessWidget {
  const YearlyGoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PeriodGoalScreen(
      goalType: 'yearly',
      enTitle: 'YEARLY GOAL',
      koTitle: '연간 목표',
    );
  }
}
