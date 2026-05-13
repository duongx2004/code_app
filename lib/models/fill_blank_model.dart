class FillBlankExercise {
  final String id;
  final String title;
  final String content;
  final String difficulty;
  final String? hint;
  final List<FillBlank> blanks;

  FillBlankExercise({
    required this.id,
    required this.title,
    required this.content,
    required this.difficulty,
    this.hint,
    required this.blanks,
  });

  factory FillBlankExercise.fromJson(Map<String, dynamic> json) {
    final blanksJson = json['blanks'] as List? ?? [];
    List<FillBlank> blanks = blanksJson.map((b) => FillBlank.fromJson(b)).toList();

    return FillBlankExercise(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      difficulty: json['difficulty'] as String,
      hint: json['hint'] as String?,
      blanks: blanks,
    );
  }
}

class FillBlank {
  final int index;
  final List<String> correctAnswers;
  final String? hint;

  FillBlank({
    required this.index,
    required this.correctAnswers,
    this.hint,
  });

  factory FillBlank.fromJson(Map<String, dynamic> json) {
    return FillBlank(
      index: json['index'] as int,
      correctAnswers: (json['correctAnswers'] as List?)?.map((e) => e as String).toList() ?? [],
      hint: json['hint'] as String?,
    );
  }
}

class FillBlankResult {
  final int score;
  final int totalBlanks;
  final bool completed;
  final List<BlankResult> results;

  FillBlankResult({
    required this.score,
    required this.totalBlanks,
    required this.completed,
    required this.results,
  });

  factory FillBlankResult.fromJson(Map<String, dynamic> json) {
    final resultsJson = json['results'] as List? ?? [];
    List<BlankResult> results = resultsJson.map((r) => BlankResult.fromJson(r)).toList();

    return FillBlankResult(
      score: json['score'] as int,
      totalBlanks: json['totalBlanks'] as int,
      completed: json['completed'] as bool,
      results: results,
    );
  }
}

class BlankResult {
  final int blankIndex;
  final String userAnswer;
  final bool isCorrect;
  final List<String> correctAnswers;

  BlankResult({
    required this.blankIndex,
    required this.userAnswer,
    required this.isCorrect,
    required this.correctAnswers,
  });

  factory BlankResult.fromJson(Map<String, dynamic> json) {
    final correctAnswersJson = json['correctAnswers'] as List? ?? [];
    List<String> correctAnswers = correctAnswersJson.map((a) => a as String).toList();

    return BlankResult(
      blankIndex: json['blankIndex'] as int,
      userAnswer: json['userAnswer'] as String,
      isCorrect: json['isCorrect'] as bool,
      correctAnswers: correctAnswers,
    );
  }
}