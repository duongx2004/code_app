import 'question_model.dart';
import 'exercise_model.dart';

class Lesson {
  final String id;
  final String title;
  final String content;
  final String codeSample;
  final String expectedOutput;
  final List<Question> quiz;
  final List<DartExercise> exercises;
  final int order;

  Lesson({
    required this.id,
    required this.title,
    required this.content,
    required this.codeSample,
    required this.expectedOutput,
    required this.quiz,
    required this.exercises,
    required this.order,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final quizList = json['quiz'] as List? ?? [];
    final exercisesList = json['exercises'] as List? ?? [];

    List<Question> quizObjects =
        quizList.map((q) => Question.fromJson(q)).toList();
    
    List<DartExercise> exerciseObjects =
        exercisesList.map((e) => DartExercise.fromJson(e)).toList();

    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      codeSample: json['codeSample'] as String,
      expectedOutput: json['expectedOutput'] as String,
      quiz: quizObjects,
      exercises: exerciseObjects,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'codeSample': codeSample,
      'expectedOutput': expectedOutput,
      'quiz': quiz.map((question) => question.toMap()).toList(),
      'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
      'order': order,
    };
  }
}