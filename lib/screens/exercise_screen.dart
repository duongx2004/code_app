import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:code_app/models/exercise_model.dart';
import 'package:code_app/screens/exercise_detail_screen.dart';
import 'package:code_app/services/exercise_service.dart';
import 'package:code_app/services/progress_service.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  List<DartExercise> exercises = [];
  List<DartExercise> filteredExercises = [];
  final TextEditingController _searchController = TextEditingController();
  String selectedDifficulty = 'Tất cả';
  bool isLoading = true;

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'cơ bản':
        return Colors.green;
      case 'trung bình':
        return Colors.orange;
      case 'nâng cao':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getExerciseIcon(String id) {
    switch (id) {
      case 'ex1':
        return Icons.calculate;
      case 'ex2':
        return Icons.star;
      case 'ex3':
        return Icons.crop_square;
      case 'ex4':
        return Icons.trending_up;
      case 'ex5':
        return Icons.functions;
      case 'ex6':
        return Icons.verified;
      case 'ex7':
        return Icons.auto_graph;
      default:
        return Icons.code;
    }
  }

  Future<void> _loadExercises() async {
    setState(() => isLoading = true);
    try {
      final loaded = await ExerciseService.loadExercises();
      setState(() {
        exercises = loaded;
        filteredExercises = loaded;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _filterExercises() {
    setState(() {
      filteredExercises = exercises.where((ex) {
        final matchesSearch = _searchController.text.isEmpty ||
            ex.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            ex.description.toLowerCase().contains(_searchController.text.toLowerCase());
        final matchesDifficulty = selectedDifficulty == 'Tất cả' ||
            ex.difficulty == selectedDifficulty;
        return matchesSearch && matchesDifficulty;
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _searchController.addListener(_filterExercises);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressService = context.watch<ProgressService>();
    final completedCount = exercises
        .where((exercise) => progressService.isExerciseCompleted(exercise.id))
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: RefreshIndicator(
        onRefresh: _loadExercises,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 140,
                    floating: true,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    forceElevated: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const SafeArea(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Bài tập Dart',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Rèn luyện kỹ năng lập trình Dart qua các bài tập thực tế',
                                  style: TextStyle(fontSize: 18, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 18),
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm bài tập...',
                              prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => _searchController.clear(),
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: ['Tất cả', 'cơ bản', 'trung bình', 'nâng cao']
                                  .map(
                                    (diff) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(diff),
                                        selected: selectedDifficulty == diff,
                                        onSelected: (selected) {
                                          setState(() {
                                            selectedDifficulty = selected ? diff : selectedDifficulty;
                                          });
                                          _filterExercises();
                                        },
                                        selectedColor: _getDifficultyColor(diff).withValues(alpha: 0.12),
                                        backgroundColor: Colors.white,
                                        labelStyle: TextStyle(
                                          color: selectedDifficulty == diff ? Colors.white : Colors.grey.shade800,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${filteredExercises.length} bài tập phù hợp • Đã hoàn thành $completedCount/${exercises.length}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: completedCount == 0
                                    ? null
                                    : () => _confirmResetProgress(context),
                                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                                label: const Text('Xóa tiến độ'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: filteredExercises.isEmpty
                        ? SliverToBoxAdapter(
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Không tìm thấy bài tập phù hợp',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Hãy thử đổi từ khóa tìm kiếm hoặc bộ lọc độ khó.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              childCount: filteredExercises.length,
                              (context, index) => _buildExerciseCard(
                                context,
                                filteredExercises[index],
                                progressService.isExerciseCompleted(
                                  filteredExercises[index].id,
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _confirmResetProgress(BuildContext context) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa tiến độ bài tập?'),
        content: const Text(
          'Tất cả bài tập đã hoàn thành sẽ bị xóa trạng thái. Bạn có muốn làm lại từ đầu?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xóa tiến độ'),
          ),
        ],
      ),
    );

    if (shouldReset == true && context.mounted) {
      await context.read<ProgressService>().resetExerciseProgress();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa tiến độ bài tập. Bạn có thể làm lại từ đầu.'),
        ),
      );
    }
  }

  Widget _buildExerciseCard(
    BuildContext context,
    DartExercise exercise,
    bool isCompleted,
  ) {
    final color = _getDifficultyColor(exercise.difficulty);
    final icon = _getExerciseIcon(exercise.id);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: isCompleted ? 0.55 : 1,
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.08), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (context) => ExerciseDetailScreen(exercise: exercise),
            ),
          )
              .then((result) {
            if (result == true && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã hoàn thành: ${exercise.title}'),
                  backgroundColor: const Color(0xFF16A34A),
                ),
              );
            }
            if (mounted) {
              setState(() {});
            }
          }),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exercise.description.split('\n').first,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCompleted)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Đã xong',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        exercise.difficulty,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade600),
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
}
