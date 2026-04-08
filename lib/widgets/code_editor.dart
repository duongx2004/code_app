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
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: TextField(
        controller: widget.controller,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        style: const TextStyle(
          fontFamily: 'Courier',
          fontSize: 13,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }
}
