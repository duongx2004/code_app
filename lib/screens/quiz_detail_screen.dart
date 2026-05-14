import 'package:flutter/material.dart';
import 'package:code_app/models/models.dart';
import 'package:provider/provider.dart';
import 'package:code_app/services/progress_service.dart';
import 'package:code_app/theme/app_theme.dart';
import 'package:code_app/widgets/custom_card.dart';
import 'package:code_app/main.dart';

class QuizDetailScreen extends StatefulWidget {
  final Quiz quiz;
  const QuizDetailScreen({super.key, required this.quiz});

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  int currentQuestionIndex = 0;
  int score = 0;

  @override
  void initState() {
    super.initState();
  }

  void checkAnswer(int selectedIndex) {
    bool isCorrect = selectedIndex == widget.quiz.questions[currentQuestionIndex].correctAnswerIndex;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCorrect ? "Chính xác! 🎉" : "Sai rồi, cố lên! 💪",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
        duration: const Duration(milliseconds: 600),
      ),
    );

    if (isCorrect) {
      score++;
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (currentQuestionIndex < widget.quiz.questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
        });
      } else {
        showResult();
      }
    });
  }

  void showResult() {
    final percentage = (score / widget.quiz.questions.length * 100).round();
    final passed = percentage >= 70; // 70% to pass

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          passed ? 'Chúc mừng! 🎉' : 'Cố gắng hơn nhé! 💪',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Điểm số: $score/${widget.quiz.questions.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tỷ lệ: $percentage%',
              style: TextStyle(
                fontSize: 16,
                color: passed ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              passed
                  ? 'Bạn đã hoàn thành quiz thành công!'
                  : 'Bạn cần đạt ít nhất 70% để qua quiz.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (passed) {
                try {
                  await Provider.of<ProgressService>(context, listen: false)
                      .markQuizAsCompleted(widget.quiz.id);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi lưu tiến độ: $e')),
                  );
                }
              }
              // Close dialog
              Navigator.of(context).pop();
              // Replace whole stack with MainNavigation and open Home tab (index 1)
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (c) => const MainNavigation(initialIndex: 1)),
                (route) => false,
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.quiz.questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / widget.quiz.questions.length,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Câu ${currentQuestionIndex + 1}/${widget.quiz.questions.length}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Question
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  question.questionText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Options
            ...List.generate(
              question.options.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: () => checkAnswer(index),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    question.options[index],
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Score display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Điểm hiện tại: $score/${widget.quiz.questions.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}