import 'package:flutter/material.dart';
import 'package:code_app/models/models.dart';
import 'package:provider/provider.dart';
import 'package:code_app/services/progress_service.dart';

class QuizScreen extends StatefulWidget {
  final Lesson lesson;
  const QuizScreen({super.key, required this.lesson});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  int score = 0;

  void checkAnswer(int selectedIndex) {
    bool isCorrect = selectedIndex == widget.lesson.quiz[currentQuestionIndex].correctAnswerIndex;

    // Hiển thị thông báo đúng/sai nhanh
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCorrect ? "Chính xác! 🎉" : "Sai rồi, cố lên! 💪",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
        duration: const Duration(milliseconds: 600),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (isCorrect) {
      score++;
    }

    // Đợi SnackBar hiện xong một chút rồi mới chuyển câu
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (currentQuestionIndex < widget.lesson.quiz.length - 1) {
        setState(() {
          currentQuestionIndex++;
        });
      } else {
        showResult();
      }
    });
  }

  void showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Center(child: Text("Kết quả học tập 🏆")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$score / ${widget.lesson.quiz.length}",
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 10),
            Text(
              score == widget.lesson.quiz.length
                  ? "Tuyệt vời! Bạn đã nắm vững bài này."
                  : "Khá tốt! Hãy ôn lại những phần chưa rõ nhé.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Đóng Dialog
                Navigator.pop(context); // Quay lại bài học
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
              child: const Text("Hoàn thành"),
            ),
          ),
        ],
      ),
    );
    void showResult() {
      // Nếu trả lời đúng hết (hoặc trên 80%), đánh dấu hoàn thành
      if (score == widget.lesson.quiz.length) {
        Provider.of<ProgressService>(context, listen: false).markAsCompleted(widget.lesson.id);
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          // ... (giữ nguyên phần UI Dialog cũ)
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.lesson.quiz[currentQuestionIndex];
    double progress = (currentQuestionIndex + 1) / widget.lesson.quiz.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kiểm tra"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh tiến độ
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              color: Colors.blueAccent,
              minHeight: 8,
            ),
            const SizedBox(height: 20),

            Text(
                "Câu hỏi ${currentQuestionIndex + 1} trên ${widget.lesson.quiz.length}:",
                style: TextStyle(color: Colors.grey[600], fontSize: 14)
            ),
            const SizedBox(height: 10),
            Text(
                question.questionText,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 30),

            // Danh sách các lựa chọn
            Expanded(
              child: ListView.builder(
                itemCount: question.options.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton(
                      onPressed: () => checkAnswer(index),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: Colors.blueAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        question.options[index],
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}