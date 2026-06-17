import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/learning_gaps/data/learning_gap_fallback.dart';
import 'package:trueschoolapp/features/learning_gaps/data/models/learning_gap_model.dart';
import 'package:trueschoolapp/features/learning_gaps/data/services/learning_gap_service.dart';
import 'package:trueschoolapp/features/learning_gaps/presentation/pages/gap_quiz_page.dart';

const _kDifficultyBg = {
  'easy':   Color(0xFFDCFCE7),
  'medium': Color(0xFFFFF7ED),
  'hard':   Color(0xFFFEE2E2),
};
const _kDifficultyFg = {
  'easy':   Color(0xFF15803D),
  'medium': Color(0xFFD97706),
  'hard':   Color(0xFF991B1B),
};
const _kSubjectBg = {
  'Math':      Color(0xFFF3F0FF),
  'Physics':   Color(0xFFEFF6FF),
  'Chemistry': Color(0xFFECFDF5),
  'Biology':   Color(0xFFECFEFF),
  'History':   Color(0xFFFFFBEB),
};
const _kSubjectFg = {
  'Math':      Color(0xFF7C3AED),
  'Physics':   Color(0xFF1D4ED8),
  'Chemistry': Color(0xFF065F46),
  'Biology':   Color(0xFF0F766E),
  'History':   Color(0xFFB45309),
};

class QuizSelectorPage extends StatefulWidget {
  const QuizSelectorPage({super.key});

  @override
  State<QuizSelectorPage> createState() => _QuizSelectorPageState();
}

class _QuizSelectorPageState extends State<QuizSelectorPage> {
  bool _isLoading = true;
  List<Quiz> _quizzes = [];
  String _subjectFilter = 'All';
  String _diffFilter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final apiQuizzes = await LearningGapService.getQuizList();
    if (!mounted) return;
    setState(() {
      _quizzes = apiQuizzes.isNotEmpty ? apiQuizzes : kFallbackQuizzes;
      _isLoading = false;
    });
  }

  List<String> get _subjects =>
      ['All', ...{..._quizzes.map((q) => q.subject)}];

  List<String> get _difficulties => ['All', 'easy', 'medium', 'hard'];

  List<Quiz> get _filtered => _quizzes.where((q) {
        final matchSub = _subjectFilter == 'All' || q.subject == _subjectFilter;
        final matchDiff = _diffFilter == 'All' || q.difficulty == _diffFilter;
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
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildFilters(),
                      const SizedBox(height: 16),
                      if (_filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.search_off, size: 48, color: AppColors.textSecondary),
                                SizedBox(height: 8),
                                Text('No quizzes match your filters.',
                                    style: TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._filtered.map((quiz) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _QuizCard(
                                quiz: quiz,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GapQuizPage(quizId: quiz.id),
                                  ),
                                ),
                              ),
                            )),
                    ],
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
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          const Text(
            'Self-Assessment Quizzes',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterRow(
          label: 'Subject',
          values: _subjects,
          selected: _subjectFilter,
          onSelect: (s) => setState(() => _subjectFilter = s),
        ),
        const SizedBox(height: 10),
        _FilterRow(
          label: 'Difficulty',
          values: _difficulties,
          selected: _diffFilter,
          onSelect: (d) => setState(() => _diffFilter = d),
          capitalize: true,
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String label;
  final List<String> values;
  final String selected;
  final void Function(String) onSelect;
  final bool capitalize;

  const _FilterRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.onSelect,
    this.capitalize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label:',
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final v = values[i];
                final isActive = selected == v;
                final display = capitalize && v != 'All'
                    ? '${v[0].toUpperCase()}${v.substring(1)}'
                    : v;
                return GestureDetector(
                  onTap: () => onSelect(v),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      display,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _QuizCard extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback onTap;

  const _QuizCard({required this.quiz, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final subjBg = _kSubjectBg[quiz.subject] ?? const Color(0xFFF1F5F9);
    final subjFg = _kSubjectFg[quiz.subject] ?? Colors.grey.shade700;
    final diffBg = _kDifficultyBg[quiz.difficulty] ?? const Color(0xFFF1F5F9);
    final diffFg = _kDifficultyFg[quiz.difficulty] ?? Colors.grey.shade700;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: subjBg, borderRadius: BorderRadius.circular(8)),
                  child: Text(quiz.subject,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: subjFg)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: diffBg, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    '${quiz.difficulty[0].toUpperCase()}${quiz.difficulty.substring(1)}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: diffFg),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(quiz.title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            if (quiz.topic.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(quiz.topic,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.quiz, size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      '${quiz.totalQuestions > 0 ? quiz.totalQuestions : quiz.questions.length} Qs',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    if (quiz.estimatedMinutes > 0) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.schedule, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text('${quiz.estimatedMinutes}m',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ],
                ),
                Icon(Icons.arrow_forward, size: 18, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
