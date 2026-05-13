import 'package:flutter/material.dart';

class BlankInputField extends StatefulWidget {
  final int blankIndex;
  final String? hint;
  final TextEditingController controller;
  final bool showResult;
  final bool isCorrect;
  final List<String> correctAnswers;

  const BlankInputField({
    super.key,
    required this.blankIndex,
    this.hint,
    required this.controller,
    this.showResult = false,
    this.isCorrect = false,
    this.correctAnswers = const [],
  });

  @override
  State<BlankInputField> createState() => _BlankInputFieldState();
}

class _BlankInputFieldState extends State<BlankInputField> {
  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.grey;
    if (widget.showResult) {
      borderColor = widget.isCorrect ? Colors.green : Colors.red;
    }

    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: widget.controller,
            decoration: InputDecoration(
              hintText: 'Điền vào đây',
              border: OutlineInputBorder(
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14),
            enabled: !widget.showResult,
          ),
          if (widget.hint != null && widget.hint!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Gợi ý: ${widget.hint}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (widget.showResult && !widget.isCorrect)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Đáp án: ${widget.correctAnswers.join(', ')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}