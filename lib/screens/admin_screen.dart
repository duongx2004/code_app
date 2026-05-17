import 'dart:convert';

import 'package:code_app/models/exercise_model.dart';
import 'package:code_app/models/lesson_model.dart';
import 'package:code_app/models/question_model.dart';
import 'package:code_app/services/admin_service.dart';
import 'package:code_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoading = true;
  String? _error;

  static const List<String> _fillBlankDifficultyOptions = [
    'cơ bản',
    'trung bình',
    'nâng cao',
  ];

  String _normalizeFillBlankDifficulty(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    for (final option in _fillBlankDifficultyOptions) {
      if (normalized == option) {
        return option;
      }
    }
    return _fillBlankDifficultyOptions.first;
  }

  List<_FillBlankDraftRow> _buildFillBlankRows(Map<String, dynamic>? exercise) {
    final blanks = exercise?['blanks'];
    if (blanks is List && blanks.isNotEmpty) {
      return blanks.map((blank) {
        final blankMap = blank is Map
            ? Map<String, dynamic>.from(blank as Map)
            : <String, dynamic>{};
        final correctAnswers = blankMap['correctAnswers'];

        String answer = '';
        if (correctAnswers is List && correctAnswers.isNotEmpty) {
          answer = correctAnswers.first?.toString() ?? '';
        } else if (blankMap['correct_answer'] != null) {
          answer = blankMap['correct_answer'].toString();
        } else if (blankMap['answer'] != null) {
          answer = blankMap['answer'].toString();
        }

        return _FillBlankDraftRow(
          answer: answer,
          hint: blankMap['hint']?.toString() ?? '',
        );
      }).toList();
    }

    return [_FillBlankDraftRow()];
  }

  List<Map<String, dynamic>> _serializeFillBlankRows(List<_FillBlankDraftRow> rows) {
    return rows.asMap().entries.map((entry) {
      final index = entry.key;
      final row = entry.value;
      final answer = row.answerController.text.trim();
      final hint = row.hintController.text.trim();

      return {
        'index': index,
        'position': index,
        'answer': answer,
        'correct_answer': answer,
        'correctAnswers': [answer],
        'hint': hint.isEmpty ? null : hint,
      };
    }).toList();
  }

  Future<void> _openFillBlankDialog({Map<String, dynamic>? exercise}) async {
    final isEditing = exercise != null;
    final id = exercise?['id']?.toString() ?? '';
    final titleController = TextEditingController(text: exercise?['title']?.toString() ?? '');
    final contentController = TextEditingController(text: exercise?['content']?.toString() ?? '');
    final hintController = TextEditingController(text: exercise?['hint']?.toString() ?? '');
    String selectedDifficulty = _normalizeFillBlankDifficulty(exercise?['difficulty']?.toString());
    final blankRows = _buildFillBlankRows(exercise);

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            backgroundColor: AppTheme.getSurfaceColor(context),
            child: Container(
              width: 780,
              constraints: const BoxConstraints(maxHeight: 860),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Sửa bài tập điền chỗ trống' : 'Tạo bài tập điền chỗ trống',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mỗi chỗ trống bên dưới sẽ được lưu theo thứ tự và tương thích với dữ liệu bài tập hiện có.',
                      style: TextStyle(
                        color: AppTheme.getTextSecondaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Tiêu đề *',
                        prefixIcon: Icon(Icons.title, color: AppTheme.primaryColor),
                        labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentController,
                      decoration: InputDecoration(
                        labelText: 'Nội dung *',
                        hintText: 'Ví dụ: Trong Dart, từ khóa _____ dùng để khai báo biến.',
                        prefixIcon: Icon(Icons.description, color: AppTheme.primaryColor),
                        labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedDifficulty,
                      decoration: InputDecoration(
                        labelText: 'Độ khó *',
                        prefixIcon: Icon(Icons.trending_up, color: AppTheme.primaryColor),
                        labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      dropdownColor: AppTheme.getSurfaceColor(context),
                      items: _fillBlankDifficultyOptions
                          .map(
                            (difficulty) => DropdownMenuItem(
                              value: difficulty,
                              child: Text(
                                difficulty,
                                style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedDifficulty = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: hintController,
                      decoration: InputDecoration(
                        labelText: 'Gợi ý chung',
                        hintText: 'Không bắt buộc',
                        prefixIcon: Icon(Icons.lightbulb, color: AppTheme.primaryColor),
                        labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          'Danh sách chỗ trống',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextPrimaryColor(context),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              blankRows.add(_FillBlankDraftRow());
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm chỗ trống'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (blankRows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Chưa có chỗ trống nào.',
                          style: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                        ),
                      ),
                    ...List.generate(blankRows.length, (index) {
                      final row = blankRows[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          color: AppTheme.getSurfaceColor(context),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppTheme.getTextSecondaryColor(context).withOpacity(0.18),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Chỗ trống ${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.getTextPrimaryColor(context),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (blankRows.length > 1)
                                      IconButton(
                                        tooltip: 'Xóa chỗ trống',
                                        onPressed: () {
                                          setDialogState(() {
                                            row.dispose();
                                            blankRows.removeAt(index);
                                          });
                                        },
                                        icon: Icon(Icons.delete_outline, color: AppTheme.errorColor),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: row.answerController,
                                  decoration: InputDecoration(
                                    labelText: 'Đáp án đúng *',
                                    hintText: 'Ví dụ: var, String, main, []',
                                    labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: row.hintController,
                                  decoration: InputDecoration(
                                    labelText: 'Gợi ý cho chỗ trống',
                                    hintText: 'Không bắt buộc',
                                    labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Hủy', style: TextStyle(color: AppTheme.primaryColor)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            final title = titleController.text.trim();
                            final content = contentController.text.trim();
                            final difficulty = selectedDifficulty.trim();
                            final hint = hintController.text.trim();

                            if (title.isEmpty || content.isEmpty || difficulty.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin bắt buộc')),
                              );
                              return;
                            }

                            if (blankRows.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Bạn cần thêm ít nhất một chỗ trống')),
                              );
                              return;
                            }

                            for (final row in blankRows) {
                              if (row.answerController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đáp án đúng của từng chỗ trống không được để trống')),
                                );
                                return;
                              }
                            }

                            try {
                              final blanks = _serializeFillBlankRows(blankRows);
                              if (isEditing) {
                                await AdminService.updateFillBlankExercise(
                                  id: id,
                                  title: title,
                                  content: content,
                                  difficulty: difficulty,
                                  hint: hint.isEmpty ? null : hint,
                                  blanks: blanks,
                                );
                              } else {
                                await AdminService.createFillBlankExercise(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  title: title,
                                  content: content,
                                  difficulty: difficulty,
                                  hint: hint.isEmpty ? null : hint,
                                  blanks: blanks,
                                );
                              }

                              if (mounted) Navigator.pop(context);
                              _loadAll();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEditing ? 'Đã cập nhật bài tập' : 'Tạo bài tập thành công',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi: $e')),
                                );
                              }
                            }
                          },
                          child: Text(isEditing ? 'Lưu thay đổi' : 'Tạo bài tập'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      titleController.dispose();
      contentController.dispose();
      hintController.dispose();
      for (final row in blankRows) {
        row.dispose();
      }
    }
  }

  void _editUserDialog(Map<String, dynamic> user) {
    final email = user['email']?.toString() ?? '';
    final currentName = user['name']?.toString() ?? user['display_name']?.toString() ?? '';
    final currentIsAdmin = user['is_admin'] == true;

    final nameController = TextEditingController(text: currentName);
    final passwordController = TextEditingController();
    bool isAdmin = currentIsAdmin;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.getSurfaceColor(context),
          title: Text('Quản lý tài khoản', style: TextStyle(color: AppTheme.getTextPrimaryColor(context))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên hiển thị',
                    labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                  ),
                  style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Quyền Admin', style: TextStyle(color: AppTheme.getTextPrimaryColor(context))),
                    const Spacer(),
                    Switch(
                      value: isAdmin,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (v) => setState(() => isAdmin = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới (để trống nếu không đổi)',
                    labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                  ),
                  obscureText: true,
                  style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: TextStyle(color: AppTheme.primaryColor)),
            ),
            TextButton(
              onPressed: () async {
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email không hợp lệ')));
                  return;
                }
                final password = passwordController.text.trim();
                if (password.isNotEmpty && password.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu phải có ít nhất 6 ký tự')));
                  return;
                }

                try {
                  await AdminService.updateUser(
                    email,
                    nameController.text.trim(),
                    isAdmin,
                    password: password.isEmpty ? null : password,
                  );
                  if (mounted) Navigator.pop(context);
                  _loadAll();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật tài khoản')));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                }
              },
              child: Text('Lưu', style: TextStyle(color: AppTheme.primaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  void _editLessonDialog(Lesson lesson) {
    final titleController = TextEditingController(text: lesson.title);
    final contentController = TextEditingController(text: lesson.content);
    final codeSampleController = TextEditingController(text: lesson.codeSample);
    final expectedOutputController = TextEditingController(text: lesson.expectedOutput);
    final orderController = TextEditingController(text: lesson.order.toString());
    final quizDifficultyController = TextEditingController(
      text: _quizzes.firstWhere(
        (quiz) => quiz['id']?.toString() == lesson.id,
        orElse: () => const <String, dynamic>{},
      )['difficulty']?.toString() ?? 'Cơ bản',
    );
    final quizQuestionsController = TextEditingController(
      text: jsonEncode(lesson.quiz.map((question) => question.toMap()).toList()),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceColor(context),
        title: Text('Sửa bài học', style: TextStyle(color: AppTheme.getTextPrimaryColor(context))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Tiêu đề',
                  labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                ),
                style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Nội dung',
                  labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                ),
                style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeSampleController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Mã mẫu',
                  labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                ),
                style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: expectedOutputController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Kết quả mong đợi',
                  labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                ),
                style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: orderController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Thứ tự',
                  labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                ),
                style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Trắc nghiệm',
                  style: TextStyle(
                    color: AppTheme.getTextPrimaryColor(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: quizDifficultyController.text.isNotEmpty
                    ? quizDifficultyController.text
                    : 'Cơ bản',
                decoration: InputDecoration(
                  labelText: 'Độ khó trắc nghiệm',
                  labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                ),
                dropdownColor: AppTheme.getSurfaceColor(context),
                items: const ['Cơ bản', 'Trung bình', 'Nâng cao']
                    .map((difficulty) => DropdownMenuItem(
                          value: difficulty,
                          child: Text(difficulty),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    quizDifficultyController.text = value;
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quizQuestionsController,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: 'Câu hỏi trắc nghiệm (JSON)',
                  hintText: '[{"questionText":"2+2 bằng?","options":["3","4"],"correctAnswerIndex":1}]',
                  labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                ),
                style: TextStyle(
                  color: AppTheme.getTextPrimaryColor(context),
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: AppTheme.primaryColor)),
          ),
          TextButton(
            onPressed: () async {
              try {
                final parsedQuiz = _parseQuestionsJson(quizQuestionsController.text);
                final updated = Lesson(
                  id: lesson.id,
                  title: titleController.text.trim(),
                  content: contentController.text.trim(),
                  codeSample: codeSampleController.text.trim(),
                  expectedOutput: expectedOutputController.text.trim(),
                  quiz: parsedQuiz,
                  exercises: lesson.exercises,
                  order: int.tryParse(orderController.text) ?? 0,
                );
                await AdminService.updateLesson(lesson.id, updated);
                await _syncQuizListWithLesson(
                  lessonId: lesson.id,
                  title: titleController.text.trim(),
                  description: contentController.text.trim(),
                  difficulty: quizDifficultyController.text.trim().isEmpty
                      ? 'Cơ bản'
                      : quizDifficultyController.text.trim(),
                  quiz: parsedQuiz,
                );
                if (mounted) Navigator.pop(context);
                _loadAll();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật bài học')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              }
            },
            child: Text('Lưu', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _editExerciseDialog(DartExercise exercise) {
    _openExerciseDialog(exercise: exercise);
  }

  void _editFillBlankDialog(Map<String, dynamic> exercise) {
    _openFillBlankDialog(exercise: exercise);
  }


  List<Map<String, dynamic>> _users = [];
  List<Lesson> _lessons = [];
  List<DartExercise> _exercises = [];
  List<Map<String, dynamic>> _fillBlankExercises = [];
  List<Map<String, dynamic>> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await AdminService.fetchUsers();
      final lessons = await AdminService.fetchLessons();
      final exercises = await AdminService.fetchExercises();
      final fillBlankExercises = await AdminService.fetchFillBlankExercises();
      final quizzes = await AdminService.fetchQuizzes();

      setState(() {
        _users = users;
        _lessons = lessons;
        _exercises = exercises;
        _fillBlankExercises = fillBlankExercises;
        _quizzes = quizzes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  bool _quizIdExistsOnServer(String id) {
    return _quizzes.any((q) => q['id']?.toString() == id);
  }

  List<Question> _parseQuestionsJson(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return [];
    final decoded = json.decode(t) as List<dynamic>;
    return decoded
        .map((e) => Question.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _syncQuizListWithLesson({
    required String lessonId,
    required String title,
    required String description,
    required String difficulty,
    required List<Question> quiz,
  }) async {
    if (quiz.isEmpty) {
      if (_quizIdExistsOnServer(lessonId)) {
        await AdminService.deleteQuiz(lessonId);
      }
      return;
    }

    final maps = quiz.map((q) => q.toMap()).toList();

    if (_quizIdExistsOnServer(lessonId)) {
      await AdminService.updateQuiz(
        id: lessonId,
        title: title,
        description: description,
        difficulty: difficulty,
        questions: maps,
      );
    } else {
      await AdminService.createQuiz(
        id: lessonId,
        title: title,
        description: description,
        difficulty: difficulty,
        questions: maps,
      );
    }
  }

  void _openCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceColor(context),
        title: Text(
          'Tạo mới',
          style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.people, color: AppTheme.primaryColor),
              title: Text(
                'Người dùng',
                style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
              ),
              onTap: () {
                Navigator.pop(context);
                _createUser();
              },
            ),
            ListTile(
              leading: Icon(Icons.book, color: AppTheme.secondaryColor),
              title: Text(
                'Bài học',
                style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
              ),
              onTap: () {
                Navigator.pop(context);
                _createLesson();
              },
            ),
            ListTile(
              leading: Icon(Icons.code, color: AppTheme.accentColor),
              title: Text(
                'Bài tập code',
                style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
              ),
              onTap: () {
                Navigator.pop(context);
                _createExercise();
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: AppTheme.successColor),
              title: Text(
                'Bài tập điền chỗ trống',
                style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
              ),
              onTap: () {
                Navigator.pop(context);
                _createFillBlankExercise();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createUser() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceColor(context),
        title: Text(
          'Tạo người dùng',
          style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Tên hiển thị',
                labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
              ),
              style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
              ),
              style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
              ),
              style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: AppTheme.primaryColor)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await AdminService.createUser(
                  emailController.text,
                  passwordController.text,
                  nameController.text,
                );
                if (mounted) Navigator.pop(context);
                _loadAll();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: Text('Tạo', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _createLesson() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final codeSampleController = TextEditingController();
    final expectedOutputController = TextEditingController();
    final orderController = TextEditingController(text: '0');

    // Quiz form
    final quizDifficultyController = TextEditingController(text: 'Cơ bản');
    final quizQuestionsController = TextEditingController(text: '[]');

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.getSurfaceColor(context),
        child: Container(
          width: 700,
          constraints: const BoxConstraints(maxHeight: 800),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tạo bài học + trắc nghiệm',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimaryColor(context),
                      )),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Tiêu đề *',
                      prefixIcon: Icon(Icons.title, color: AppTheme.primaryColor),
                      labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    decoration: InputDecoration(
                      labelText: 'Nội dung *',
                      prefixIcon: Icon(Icons.description, color: AppTheme.primaryColor),
                      labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeSampleController,
                    decoration: InputDecoration(
                      labelText: 'Mã mẫu',
                      prefixIcon: Icon(Icons.code, color: AppTheme.primaryColor),
                      labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: expectedOutputController,
                    decoration: InputDecoration(
                      labelText: 'Kết quả mong đợi',
                      prefixIcon: Icon(Icons.output, color: AppTheme.primaryColor),
                      labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: orderController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Thứ tự',
                      prefixIcon: Icon(Icons.sort, color: AppTheme.primaryColor),
                      labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
                  ),
                  const Divider(height: 32),

                  Text('Trắc nghiệm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimaryColor(context),
                      )),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: quizDifficultyController.text.isNotEmpty
                        ? quizDifficultyController.text
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Độ khó *',
                      prefixIcon:
                          Icon(Icons.trending_up, color: AppTheme.primaryColor),
                      labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: ['Cơ bản', 'Trung bình', 'Nâng cao']
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) quizDifficultyController.text = v;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: quizQuestionsController,
                    decoration: InputDecoration(
                      labelText: 'Câu hỏi (JSON)',
                      hintText:
                          '[{"questionText":"2+2 bằng?","options":["3","4","5","6"],"correctAnswerIndex":1}]',
                      prefixIcon:
                          Icon(Icons.help, color: AppTheme.primaryColor),
                      labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    style: TextStyle(
                      color: AppTheme.getTextPrimaryColor(context),
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                    maxLines: 8,
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Hủy',
                            style: TextStyle(color: AppTheme.primaryColor)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        onPressed: () async {
                          if (titleController.text.isEmpty ||
                              contentController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Vui lòng nhập tiêu đề và nội dung')),
                            );
                            return;
                          }

                          late final List<Question> parsedQuiz;
                          try {
                            parsedQuiz = _parseQuestionsJson(
                                quizQuestionsController.text);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('JSON câu hỏi không hợp lệ: $e')),
                            );
                            return;
                          }

                          try {
                            final lessonId =
                                DateTime.now().millisecondsSinceEpoch.toString();
                            final lesson = Lesson(
                              id: lessonId,
                              title: titleController.text.trim(),
                              content: contentController.text.trim(),
                              codeSample: codeSampleController.text.trim(),
                              expectedOutput: expectedOutputController.text.trim(),
                              quiz: parsedQuiz,
                              exercises: const [],
                              order: int.tryParse(orderController.text) ?? 0,
                            );

                            await AdminService.createLesson(lesson);

                            await _syncQuizListWithLesson(
                              lessonId: lessonId,
                              title: titleController.text.trim(),
                              description: contentController.text.trim(),
                              difficulty: quizDifficultyController.text.trim().isEmpty
                                  ? 'Cơ bản'
                                  : quizDifficultyController.text.trim(),
                              quiz: parsedQuiz,
                            );

                            if (mounted) Navigator.pop(context);
                            _loadAll();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Đã lưu bài học và đồng bộ trắc nghiệm')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('Lưu'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createExercise() async {
    await _openExerciseDialog();
  }

  String _normalizeExerciseDifficulty(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    if (normalized == 'cơ bản' || normalized == 'trung bình' || normalized == 'nâng cao') {
      return normalized;
    }
    return 'cơ bản';
  }

  List<_CodeTestCaseDraftRow> _buildExerciseTestCaseRows(DartExercise? exercise) {
    final existingCases = exercise?.testCases ?? const <TestCase>[];
    if (existingCases.isNotEmpty) {
      return existingCases
          .map(
            (testCase) => _CodeTestCaseDraftRow(
              input: testCase.input,
              output: testCase.expectedOutput,
            ),
          )
          .toList();
    }
    return [_CodeTestCaseDraftRow()];
  }

  List<Map<String, dynamic>> _serializeExerciseTestCases(List<_CodeTestCaseDraftRow> rows) {
    return rows.asMap().entries.map((entry) {
      final row = entry.value;
      return {
        'input': row.inputController.text.trim(),
        'output': row.outputController.text.trim(),
      };
    }).toList();
  }

  Future<void> _openExerciseDialog({DartExercise? exercise}) async {
    final isEditing = exercise != null;
    final id = exercise?.id ?? '';
    final titleController = TextEditingController(text: exercise?.title ?? '');
    final descriptionController = TextEditingController(text: exercise?.description ?? '');
    final inputFormatController = TextEditingController(text: exercise?.inputFormat ?? '');
    final outputFormatController = TextEditingController(text: exercise?.outputFormat ?? '');
    final hintController = TextEditingController(text: exercise?.hint ?? '');
    final timeLimitController = TextEditingController(text: (exercise?.timeLimit ?? 30).toString());
    String selectedDifficulty = _normalizeExerciseDifficulty(exercise?.difficulty);
    final testCaseRows = _buildExerciseTestCaseRows(exercise);

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            backgroundColor: AppTheme.getSurfaceColor(context),
            child: Container(
              width: 860,
              constraints: const BoxConstraints(maxHeight: 900),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Sửa bài tập code' : 'Tạo bài tập code',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Tiêu đề *',
                        prefixIcon: Icon(Icons.title, color: AppTheme.primaryColor),
                        labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Mô tả *',
                        prefixIcon: Icon(Icons.description, color: AppTheme.primaryColor),
                        labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedDifficulty,
                      decoration: InputDecoration(
                        labelText: 'Độ khó *',
                        prefixIcon: Icon(Icons.trending_up, color: AppTheme.primaryColor),
                        labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      dropdownColor: AppTheme.getSurfaceColor(context),
                      items: const ['cơ bản', 'trung bình', 'nâng cao']
                          .map(
                            (difficulty) => DropdownMenuItem(
                              value: difficulty,
                              child: Text(difficulty),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedDifficulty = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: inputFormatController,
                      decoration: InputDecoration(
                        labelText: 'Định dạng input *',
                        prefixIcon: Icon(Icons.input, color: AppTheme.primaryColor),
                        labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: outputFormatController,
                      decoration: InputDecoration(
                        labelText: 'Định dạng output *',
                        prefixIcon: Icon(Icons.output, color: AppTheme.primaryColor),
                        labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: hintController,
                      decoration: InputDecoration(
                        labelText: 'Gợi ý',
                        hintText: 'Không bắt buộc',
                        prefixIcon: Icon(Icons.lightbulb, color: AppTheme.primaryColor),
                        labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: timeLimitController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Giới hạn thời gian (giây)',
                        prefixIcon: Icon(Icons.timer, color: AppTheme.primaryColor),
                        labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          'Test cases',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextPrimaryColor(context),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              testCaseRows.add(_CodeTestCaseDraftRow());
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm test case'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mỗi test case gồm input và output mong đợi. Các test case này sẽ được dùng khi chạy kiểm tra bài code.',
                      style: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(testCaseRows.length, (index) {
                      final row = testCaseRows[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          color: AppTheme.getSurfaceColor(context),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppTheme.getTextSecondaryColor(context).withOpacity(0.18),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Test case ${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.getTextPrimaryColor(context),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (testCaseRows.length > 1)
                                      IconButton(
                                        tooltip: 'Xóa test case',
                                        onPressed: () {
                                          setDialogState(() {
                                            row.dispose();
                                            testCaseRows.removeAt(index);
                                          });
                                        },
                                        icon: Icon(Icons.delete_outline, color: AppTheme.errorColor),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: row.inputController,
                                  decoration: InputDecoration(
                                    labelText: 'Input',
                                    hintText: 'Dữ liệu đầu vào của test case',
                                    labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: row.outputController,
                                  decoration: InputDecoration(
                                    labelText: 'Output mong đợi',
                                    hintText: 'Kết quả đúng của test case',
                                    labelStyle: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Hủy', style: TextStyle(color: AppTheme.primaryColor)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            final title = titleController.text.trim();
                            final description = descriptionController.text.trim();
                            final inputFormat = inputFormatController.text.trim();
                            final outputFormat = outputFormatController.text.trim();
                            final hint = hintController.text.trim();
                            final timeLimit = int.tryParse(timeLimitController.text.trim()) ?? 30;

                            if (title.isEmpty || description.isEmpty || inputFormat.isEmpty || outputFormat.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Vui lòng nhập đầy đủ tiêu đề, mô tả, input và output')),
                              );
                              return;
                            }

                            if (testCaseRows.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Bạn cần thêm ít nhất một test case')),
                              );
                              return;
                            }

                            for (final row in testCaseRows) {
                              if (row.inputController.text.trim().isEmpty || row.outputController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Input và output của test case không được để trống')),
                                );
                                return;
                              }
                            }

                            try {
                              final testCases = _serializeExerciseTestCases(testCaseRows);
                              final testCasesJson = jsonEncode(testCases);

                              if (isEditing) {
                                final updated = DartExercise(
                                  id: exercise.id,
                                  title: title,
                                  description: description,
                                  inputFormat: inputFormat,
                                  outputFormat: outputFormat,
                                  difficulty: selectedDifficulty,
                                  hint: hint.isEmpty ? null : hint,
                                  timeLimit: timeLimit,
                                  testCases: testCaseRows
                                      .map(
                                        (row) => TestCase(
                                          input: row.inputController.text.trim(),
                                          expectedOutput: row.outputController.text.trim(),
                                        ),
                                      )
                                      .toList(),
                                );
                                await AdminService.updateExercise(exercise.id, updated);
                              } else {
                                await AdminService.createExercise(
                                  title,
                                  description,
                                  selectedDifficulty,
                                  inputFormat,
                                  outputFormat,
                                  testCasesJson,
                                  hint: hint.isEmpty ? null : hint,
                                  timeLimit: timeLimit,
                                );
                              }

                              if (mounted) Navigator.pop(context);
                              _loadAll();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isEditing ? 'Đã cập nhật bài tập code' : 'Tạo bài tập code thành công'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi: $e')),
                                );
                              }
                            }
                          },
                          child: Text(isEditing ? 'Lưu thay đổi' : 'Tạo bài tập'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      titleController.dispose();
      descriptionController.dispose();
      inputFormatController.dispose();
      outputFormatController.dispose();
      hintController.dispose();
      timeLimitController.dispose();
      for (final row in testCaseRows) {
        row.dispose();
      }
    }
  }

  Future<void> _createFillBlankExercise() async {
    await _openFillBlankDialog();
  }

  Future<void> _deleteUser(String userEmail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceColor(context),
        title: Text('Xóa người dùng',
            style: TextStyle(color: AppTheme.getTextPrimaryColor(context))),
        content: Text('Bạn có chắc muốn xóa người dùng này?',
            style: TextStyle(color: AppTheme.getTextSecondaryColor(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: AppTheme.primaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xóa', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService.deleteUser(userEmail);
        _loadAll();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  // NOTE: các hàm edit/delete bài học/exercise/fill-blank/quizzes
  // đang được dùng trong UI list bên dưới. Nếu backend không có endpoint tương ứng,
  // bạn có thể tắt icon edit/delete sau.

  Future<void> _deleteLesson(String lessonId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceColor(context),
        title: Text('Xóa bài học',
            style: TextStyle(color: AppTheme.getTextPrimaryColor(context))),
        content: Text('Bạn có chắc muốn xóa bài học này?',
            style: TextStyle(color: AppTheme.getTextSecondaryColor(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: AppTheme.primaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xóa', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService.deleteLesson(lessonId);
        if (_quizIdExistsOnServer(lessonId)) {
          await AdminService.deleteQuiz(lessonId);
        }
        _loadAll();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteExercise(String exerciseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceColor(context),
        title: Text('Xóa bài tập',
            style: TextStyle(color: AppTheme.getTextPrimaryColor(context))),
        content: Text('Bạn có chắc muốn xóa bài tập này?',
            style: TextStyle(color: AppTheme.getTextSecondaryColor(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: AppTheme.primaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xóa', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService.deleteExercise(exerciseId);
        _loadAll();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteFillBlankExercise(String exerciseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceColor(context),
        title: Text('Xóa bài tập điền vào chỗ trống',
            style: TextStyle(color: AppTheme.getTextPrimaryColor(context))),
        content: Text('Bạn có chắc muốn xóa bài tập này?',
            style: TextStyle(color: AppTheme.getTextSecondaryColor(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: AppTheme.primaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xóa', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService.deleteFillBlankExercise(exerciseId);
        _loadAll();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteQuiz(String quizId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceColor(context),
        title: Text('Xóa bài trắc nhiệm',
            style: TextStyle(color: AppTheme.getTextPrimaryColor(context))),
        content: Text('Bạn có chắc muốn xóa bài trắc nhiệm này?',
            style: TextStyle(color: AppTheme.getTextSecondaryColor(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: AppTheme.primaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xóa', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService.deleteQuiz(quizId);
        _loadAll();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  Widget _buildUsersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                user['name']?.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(user['name'] ?? ''),
            subtitle: Text(user['email'] ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editUserDialog(user),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteUser(user['email']?.toString() ?? ''),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLessonsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _lessons.length,
      itemBuilder: (context, index) {
        final lesson = _lessons[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.book, color: Colors.white),
            ),
            title: Text(lesson.title),
            subtitle: Text(
              lesson.content.length > 100
                  ? '${lesson.content.substring(0, 100)}...'
                  : lesson.content,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editLessonDialog(lesson),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteLesson(lesson.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExercisesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _exercises.length,
      itemBuilder: (context, index) {
        final exercise = _exercises[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.code, color: Colors.white),
            ),
            title: Text(exercise.title),
            subtitle: Text(
              'Độ khó: ${exercise.difficulty}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editExerciseDialog(exercise),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteExercise(exercise.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFillBlankTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _fillBlankExercises.length,
      itemBuilder: (context, index) {
        final exercise = _fillBlankExercises[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.edit, color: Colors.white),
            ),
            title: Text(exercise['title'] ?? ''),
            subtitle: Text(exercise['description'] ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editFillBlankDialog(exercise),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteFillBlankExercise(exercise['id']?.toString() ?? ''),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // FIX: Tab quiz (was missing / broken before)
  Widget _buildQuizTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _quizzes.length,
      itemBuilder: (context, index) {
        final quiz = _quizzes[index];
        final title = (quiz['title'] ?? quiz['name'] ?? '').toString();
        final description = (quiz['description'] ?? quiz['mota'] ?? '').toString();
        final difficulty = (quiz['difficulty'] ?? '').toString();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.purple,
              child: Icon(Icons.quiz, color: Colors.white),
            ),
            title: Text(title.isNotEmpty ? title : 'Bài trắc nhiệm'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description.isNotEmpty) Text(description),
                if (difficulty.isNotEmpty)
                  Text('Độ khó: $difficulty', style: const TextStyle(fontSize: 12)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteQuiz(quiz['id']?.toString() ?? ''),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.admin_panel_settings),
              const SizedBox(width: 12),
              const Text('Quản trị Hệ thống'),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.admin_panel_settings),
              const SizedBox(width: 12),
              const Text('Quản trị Hệ thống'),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Lỗi: $_error',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadAll, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings),
            const SizedBox(width: 12),
            const Text('Quản trị Hệ thống'),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
            tooltip: 'Làm mới dữ liệu',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(icon: Icon(Icons.people), text: 'Người dùng'),
                  Tab(icon: Icon(Icons.menu_book), text: 'Bài học & TN'),
                  Tab(icon: Icon(Icons.code), text: 'Bài code'),
                  Tab(icon: Icon(Icons.edit), text: 'Điền chỗ trống'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildUsersTab(),
                  _buildLessonsAndQuizTab(),
                  _buildExercisesTab(),
                  _buildFillBlankTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildLessonsAndQuizTab() {
  return _buildLessonsTab(); // hoặc _buildQuizTab()
}

}

class _FillBlankDraftRow {
  _FillBlankDraftRow({String answer = '', String hint = ''})
      : answerController = TextEditingController(text: answer),
        hintController = TextEditingController(text: hint);

  final TextEditingController answerController;
  final TextEditingController hintController;

  void dispose() {
    answerController.dispose();
    hintController.dispose();
  }
}

class _CodeTestCaseDraftRow {
  _CodeTestCaseDraftRow({String input = '', String output = ''})
      : inputController = TextEditingController(text: input),
        outputController = TextEditingController(text: output);

  final TextEditingController inputController;
  final TextEditingController outputController;

  void dispose() {
    inputController.dispose();
    outputController.dispose();
  }
}

