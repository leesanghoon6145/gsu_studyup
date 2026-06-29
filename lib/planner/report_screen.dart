import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// GKE STUDYUP - REPORT SCREEN
/// 📊 3] 학습 리포트 (Report) 서브 레이어
class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "REPORT LAYER READY",
        style: GoogleFonts.notoSerif(
          color: const Color(0xFFE5C158),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}