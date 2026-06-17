import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/progress/data/models/learning_gap_models.dart';
import 'package:trueschoolapp/features/progress/data/services/learning_gap_service.dart';
import 'package:trueschoolapp/features/progress/presentation/pages/gap_quiz_page.dart';

class QuizSelectorPage extends StatefulWidget {
  const QuizSelectorPage({super.key});

  @override
  State<QuizSelectorPage> createState() => _QuizSelectorPageState();
}

class _QuizSelectorPageState extends State<QuizSelectorPage> {
  List<QuizSummary> _quizzes = [];
  bool _loading = true;
  String _subjectFilter = 'All';
  String _diffFilter = 'All';

  static const _difficulties = ['All', 'easy', 'medium', 'hard'];

  static const _diffColors = {
    'easy': Color(0xFF057A55),
    'medium': Color(0xFFB45309),
    'hard': AppColors.error,
  };

  static const _subjectColors = {
    'Math': Color(0xFF7E3AF2),
    'Physics': Color(0xFF1A56DB),
    'Chemistry': Color(0xFF057A55),
    'Biology': Color(0xFF047481),
    'History': Color(0xFFB45309),
    'English': Color(0xFFBE185D),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final quizzes = await LearningGapService.getQuizList();
    if (!mounted) return;
    setState(() {
      _quizzes = quizzes;
      _loading = false;
    });
  }

  List<String> get _subjects =>
      ['All', ..._quizzes.map((q) => q.subject).toSet().toList()..sort()];

  List<QuizSummary> get _filtered => _quizzes.where((q) {
        final matchSub =
            _subjectFilter == 'All' || q.subject == _subjectFilter;
        final matchDiff =
            _diffFilter == 'All' || q.difficulty == _diffFilter;
        return matchSub && matchDiff;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFilters(),
                            const SizedBox(height: 20),
                            _buildGrid(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back,
                color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          const Text(
            'Self-Assessment Quizzes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subject filters
        _filterLabel('Subject:'),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _subjects.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final s = _subjects[i];
              return _filterChip(
                label: s,
                active: s == _subjectFilter,
                onTap: () => setState(() => _subjectFilter = s),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        // Difficulty filters
        _filterLabel('Difficulty:'),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _difficulties.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final d = _difficulties[i];
              return _filterChip(
                label: d == 'All' ? 'All' : _capitalize(d),
                active: d == _diffFilter,
                onTap: () => setState(() => _diffFilter = d),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? AppColors.primary : AppColors.border),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off,
                  size: 48, color: AppColors.textHint),
              SizedBox(height: 12),
              Text(
                'No quizzes match your filters.',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    // Two-column grid
    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth =
          (constraints.maxWidth - 12) / 2; // 12 = gap between columns
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: filtered
            .map((quiz) => SizedBox(
                  width: cardWidth,
                  child: _QuizCard(
                    quiz: quiz,
                    subjectColor: _subjectColors[quiz.subject] ??
                        AppColors.textSecondary,
                    diffColor:
                        _diffColors[quiz.difficulty] ?? AppColors.textHint,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              GapQuizPage(quizId: quiz.id),
                        ),
                      );
                    },
                  ),
                ))
            .toList(),
      );
    });
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Quiz Card ─────────────────────────────────────────────────────────────────

class _QuizCard extends StatelessWidget {
  final QuizSummary quiz;
  final Color subjectColor;
  final Color diffColor;
  final VoidCallback onTap;

  const _QuizCard({
    required this.quiz,
    required this.subjectColor,
    required this.diffColor,
    required this.onTap,
  });

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject + difficulty badges
            Row(
              children: [
                _badge(quiz.subject, subjectColor),
                const Spacer(),
                _badge(_capitalize(quiz.difficulty), diffColor),
              ],
            ),
            const SizedBox(height: 10),
            // Title
            Text(
              quiz.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (quiz.topic.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                quiz.topic,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            // Meta row
            Row(
              children: [
                const Icon(Icons.quiz_outlined,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 3),
                Text(
                  '${quiz.totalQuestions} Qs',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                if (quiz.estimatedMinutes > 0) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.schedule_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Text(
                    '${quiz.estimatedMinutes}m',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
                const Spacer(),
                const Icon(Icons.arrow_forward,
                    size: 16, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3),
      ),
    );
  }
}
