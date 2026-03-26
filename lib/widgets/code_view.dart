import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:google_fonts/google_fonts.dart';

class CodeView extends StatelessWidget {
  final String code;
  const CodeView({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: HighlightView(
          code,
          language: 'dart',
          theme: draculaTheme,
          padding: const EdgeInsets.all(12),
          textStyle: GoogleFonts.firaMono(fontSize: 14),
        ),
      ),
    );
  }
}