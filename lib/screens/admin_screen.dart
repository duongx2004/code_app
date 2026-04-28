import 'package:flutter/material.dart';
import 'package:code_app/models/exercise_model.dart';
import 'package:code_app/models/lesson_model.dart';
import 'package:code_app/services/admin_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  List<Lesson> _lessons = [];
  List<DartExercise> _exercises = [];
  String? _error;
  int _currentTab = 0;

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
      setState(() {
        _users = users;
        _lessons = lessons;
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(String email) async {
    final confirmed = await _confirmDialog('Xóa người dùng', 'Bạn có chắc muốn xóa $email?');
    if (!confirmed) return;
    await AdminService.deleteUser(email);
    await _loadAll();
  }

  Future<void> _deleteLesson(String id) async {
    final confirmed = await _confirmDialog('Xóa bài học', 'Bạn có chắc muốn xóa bài học $id?');
    if (!confirmed) return;
    await AdminService.deleteLesson(id);
    await _loadAll();
  }

  Future<void> _deleteExercise(String id) async {
    final confirmed = await _confirmDialog('Xóa bài tập', 'Bạn có chắc muốn xóa bài tập $id?');
    if (!confirmed) return;
    await AdminService.deleteExercise(id);
    await _loadAll();
  }

  Future<bool> _confirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xác nhận')),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _openCreateDialog() async {
    if (_currentTab == 0) {
      await _showCreateUserDialog();
    } else if (_currentTab == 1) {
      await _showCreateLessonDialog();
    } else {
      await _showCreateExerciseDialog();
    }
    await _loadAll();
  }

  Future<void> _showCreateUserDialog() async {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    var isAdmin = false;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo người dùng mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên hiển thị')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Mật khẩu'), obscureText: true),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setState) => CheckboxListTile(
                value: isAdmin,
                title: const Text('Là quản trị viên'),
                onChanged: (value) {
                  setState(() {
                    isAdmin = value == true;
                  });
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              await AdminService.createUser(
                emailController.text.trim(),
                passwordController.text,
                nameController.text.trim(),
                isAdmin: isAdmin,
              );
              Navigator.pop(context);
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateLessonDialog() async {
    final idController = TextEditingController();
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final codeController = TextEditingController();
    final outputController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo bài học mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: idController, decoration: const InputDecoration(labelText: 'ID')),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Tiêu đề')),
              TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Nội dung'), maxLines: 3),
              TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Code mẫu'), maxLines: 3),
              TextField(controller: outputController, decoration: const InputDecoration(labelText: 'Kết quả mong muốn')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              await AdminService.createLesson(
                Lesson(
                  id: idController.text.trim(),
                  title: titleController.text.trim(),
                  content: contentController.text.trim(),
                  codeSample: codeController.text.trim(),
                  expectedOutput: outputController.text.trim(),
                  quiz: [],
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateExerciseDialog() async {
    final idController = TextEditingController();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final inputController = TextEditingController();
    final outputController = TextEditingController();
    final difficultyController = TextEditingController(text: 'cơ bản');
    final timeLimitController = TextEditingController(text: '30');
    final hintController = TextEditingController();
    final testCaseInputController = TextEditingController();
    final testCaseOutputController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo bài tập mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: idController, decoration: const InputDecoration(labelText: 'ID')),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Tiêu đề')),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Mô tả'), maxLines: 3),
              TextField(controller: inputController, decoration: const InputDecoration(labelText: 'Định dạng input')),
              TextField(controller: outputController, decoration: const InputDecoration(labelText: 'Định dạng output')),
              TextField(controller: difficultyController, decoration: const InputDecoration(labelText: 'Độ khó')),
              TextField(controller: timeLimitController, decoration: const InputDecoration(labelText: 'Thời gian (giây)'), keyboardType: TextInputType.number),
              TextField(controller: hintController, decoration: const InputDecoration(labelText: 'Gợi ý')),
              const SizedBox(height: 12),
              const Text('Test case mẫu', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: testCaseInputController, decoration: const InputDecoration(labelText: 'Input mẫu')),
              TextField(controller: testCaseOutputController, decoration: const InputDecoration(labelText: 'Output mẫu')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              await AdminService.createExercise(
                DartExercise(
                  id: idController.text.trim(),
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  inputFormat: inputController.text.trim(),
                  outputFormat: outputController.text.trim(),
                  difficulty: difficultyController.text.trim(),
                  hint: hintController.text.trim().isEmpty ? null : hintController.text.trim(),
                  timeLimit: int.tryParse(timeLimitController.text.trim()) ?? 30,
                  testCases: [
                    TestCase(
                      input: testCaseInputController.text.trim(),
                      expectedOutput: testCaseOutputController.text.trim(),
                    ),
                  ],
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: _currentTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAll,
            ),
          ],
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                _currentTab = index;
              });
            },
            tabs: const [
              Tab(text: 'Người dùng'),
              Tab(text: 'Bài học'),
              Tab(text: 'Bài tập'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Lỗi: $_error'))
                : TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildUsersTab(),
                      _buildLessonsTab(),
                      _buildExercisesTab(),
                    ],
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreateDialog,
          icon: const Icon(Icons.add),
          label: const Text('Tạo mới'),
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_users.isEmpty) {
      return const Center(child: Text('Chưa có người dùng')); 
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = _users[index];
        final isAdmin = user['is_admin'] == true || user['is_admin'] == 1;
        return Card(
          child: ListTile(
            title: Text(user['display_name'] as String? ?? ''),
            subtitle: Text('${user['email'] as String? ?? ''} • ${isAdmin ? 'Admin' : 'User'}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteUser(user['email'] as String),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLessonsTab() {
    if (_lessons.isEmpty) {
      return const Center(child: Text('Chưa có bài học')); 
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _lessons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final lesson = _lessons[index];
        return Card(
          child: ListTile(
            title: Text(lesson.title),
            subtitle: Text('ID: ${lesson.id}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteLesson(lesson.id),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExercisesTab() {
    if (_exercises.isEmpty) {
      return const Center(child: Text('Chưa có bài tập')); 
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _exercises.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final exercise = _exercises[index];
        return Card(
          child: ListTile(
            title: Text(exercise.title),
            subtitle: Text('ID: ${exercise.id} • ${exercise.difficulty}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteExercise(exercise.id),
            ),
          ),
        );
      },
    );
  }
}
