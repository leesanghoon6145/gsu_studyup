import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// GKE STUDYUP - LEARNING SCREEN
/// 📚 2] 학습 실행 (Learning) 서브 레이어
class LearningScreen extends StatefulWidget {
  const LearningScreen({Key? key}) : super(key: key);

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "LEARNING LAYER READY",
        style: GoogleFonts.notoSerif(
          color: const Color(0xFFE5C158),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}