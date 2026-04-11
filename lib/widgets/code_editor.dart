import 'package:flutter/material.dart';

class CodeEditorWidget extends StatefulWidget {
  final TextEditingController controller;
  final int minLines;
  final int maxLines;
  final String hintText;

  const CodeEditorWidget({
    super.key,
    required this.controller,
    this.minLines = 8,
    this.maxLines = 15,
    this.hintText = 'void main() {\n  // Viết code của bạn ở đây\n}',
  });

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 380;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        style: const TextStyle(
          fontFamily: 'Courier',
          fontSize: 13.5,
          height: 1.45,
          color: Color(0xFFE2E8F0),
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 12,
            vertical: isCompact ? 10 : 12,
          ),
          filled: true,
          fillColor: Colors.transparent,
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontFamily: 'Courier',
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
