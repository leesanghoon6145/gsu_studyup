import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// GKE STUDYUP - PLANNING SCREEN
/// 📅 1] 학습 계획 (Planning) 서브 레이어
class PlanningScreen extends StatefulWidget {
  const PlanningScreen({Key? key}) : super(key: key);

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "PLANNING LAYER READY",
        style: GoogleFonts.notoSerif(
          color: const Color(0xFFE5C158),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}