import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/learning_gaps/data/learning_gap_fallback.dart';
import 'package:trueschoolapp/features/learning_gaps/data/models/learning_gap_model.dart';
import 'package:trueschoolapp/features/learning_gaps/data/services/learning_gap_service.dart';

class GapQuizPage extends StatefulWidget {
  final String quizId;

  const GapQuizPage({super.key, required this.quizId});

  @override
  State<GapQuizPage> createState() => _GapQuizPageState();
}

class _GapQuizPageState extends State<GapQuizPage> {
  Quiz? _quiz;
  bool _isLoading = true;

  int _currentIdx = 0;
  String? _selected; // selected option id
  bool _checked = false;
  int _score = 0;
  bool _finished = false;
  bool _showHint = false;
  final List<Map<String, String>> _allAnswers = [];

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    final apiQuiz = await LearningGapService.getQuiz(widget.quizId);
    if (!mounted) return;
    setState(() {
      if (apiQuiz != null && apiQuiz.questions.isNotEmpty) {
        _quiz = apiQuiz;
      } else {
        _quiz = kFallbackQuizzes.where((q) => q.id == widget.quizId).firstOrNull ??
            (kFallbackQuizzes.isNotEmpty ? kFallbackQuizzes.first : null);
      }
      _isLoading = false;
    });
  }

  void _handleCheck() {
    if (_selected == null) return;
    final q = _quiz!.questions[_currentIdx];
    final correct = q.options.firstWhere((o) => o.isCorrect, orElse: () => q.options.first);
    final isRight = _selected == correct.id;
    setState(() {
      _checked = true;
      if (isRight) _score++;
      _allAnswers.add({'question_id': q.id, 'selected_option_id': _selected!});
    });
  }

  void _handleNext() {
    final questions = _quiz!.questions;
    if (_currentIdx < questions.length - 1) {
      setState(() {
        _currentIdx++;
        _selected = null;
        _checked = false;
        _showHint = false;
      });
    } else {
      // Submit to API (fire and forget)
      LearningGapService.submitQuiz(quizId: widget.quizId, answers: _allAnswers);
      setState(() => _finished = true);
    }
  }

  void _handleNextWithoutChecking() {
    if (_selected == null) return;
    final q = _quiz!.questions[_currentIdx];
    final correct = q.options.firstWhere((o) => o.isCorrect, orElse: () => q.options.first);
    final isRight = _selected == correct.id;
    setState(() {
      if (isRight) _score++;
      _allAnswers.add({'question_id': q.id, 'selected_option_id': _selected!});
    });
    _handleNext();
  }

  void _restart() {
    setState(() {
      _currentIdx = 0;
      _selected = null;
      _checked = false;
      _score = 0;
      _finished = false;
      _showHint = false;
      _allAnswers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_quiz == null || _quiz!.questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Quiz not found.',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_finished) return _buildFinishScreen();

    final questions = _quiz!.questions;
    final q = questions[_currentIdx];
    final totalQ = questions.length;
    final progressPct = _currentIdx / totalQ;
    final correct = q.options.firstWhere((o) => o.isCorrect, orElse: () => q.options.first);
    final isCorrect = _checked && _selected == correct.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header with gradient
          _buildQuizHeader(q, progressPct),
          // Question + options
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildQuestionCard(q),
                  const SizedBox(height: 12),
                  if (_checked) _buildFeedbackCard(q, isCorrect, correct),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          // Footer
          _buildFooter(q, isCorrect, correct),
        ],
      ),
    );
  }

  Widget _buildQuizHeader(QuizQuestion q, double progressPct) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF685AE7), Color(0xFF8E82F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _quiz!.title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_off, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text('No timer',
                            style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'QUIZ PROGRESS',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.8),
                  ),
                  const Spacer(),
                  Text(
                    '${(progressPct * 100).round()}%',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressPct,
                  minHeight: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(QuizQuestion q) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Q${q.number}',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(q.difficulty.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (q.prompt.isNotEmpty)
            Text(q.prompt,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          if (q.equation != null && q.equation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(q.equation!,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
          const SizedBox(height: 16),
          // Options
          ...q.options.map((opt) {
            final isSel = _selected == opt.id;
            final isGood = _checked && opt.isCorrect;
            final isBad = _checked && isSel && !opt.isCorrect;

            Color border;
            Color bg;
            if (isGood) {
              border = Colors.green.shade400;
              bg = Colors.green.shade50;
            } else if (isBad) {
              border = Colors.red.shade400;
              bg = Colors.red.shade50;
            } else if (isSel) {
              border = AppColors.primary;
              bg = AppColors.primary.withValues(alpha: 0.06);
            } else {
              border = AppColors.border;
              bg = const Color(0xFFFAFAFC);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: _checked ? null : () => setState(() => _selected = opt.id),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? AppColors.primary : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          color: isSel ? AppColors.primary : Colors.transparent,
                        ),
                        child: isSel
                            ? const Icon(Icons.circle, size: 10, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          opt.text,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(opt.id,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSel ? AppColors.primary : Colors.grey.shade400)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(QuizQuestion q, bool isCorrect, QuizOption correct) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: isCorrect ? Colors.green.shade400 : Colors.red.shade400,
            width: 5,
          ),
          top: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCorrect ? Icons.celebration : Icons.cancel,
                  color: isCorrect ? Colors.green.shade600 : Colors.red.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCorrect ? 'Correct! Well done!' : 'Not quite — the answer is ${correct.text}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(q.explanation,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _showHint = !_showHint),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hint for next time',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                Icon(_showHint ? Icons.expand_less : Icons.expand_more,
                    size: 18, color: AppColors.primary),
              ],
            ),
          ),
          if (_showHint) ...[
            const SizedBox(height: 6),
            Text(q.hint,
                style: TextStyle(
                    fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade500)),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(QuizQuestion q, bool isCorrect, QuizOption correct) {
    final answered = _checked ? _currentIdx + 1 : _currentIdx;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('CURRENT SESSION',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8)),
                Text('Score: $_score/$answered correct',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
            const Spacer(),
            if (!_checked) ...[
              OutlinedButton.icon(
                onPressed: _selected == null ? null : _handleCheck,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Check Answer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: _selected == null
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.primary,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _selected == null ? null : _handleNextWithoutChecking,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: Text(_currentIdx < _quiz!.questions.length - 1 ? 'Next' : 'Finish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  elevation: 0,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
            ] else
              ElevatedButton.icon(
                onPressed: _handleNext,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: Text(_currentIdx < _quiz!.questions.length - 1 ? 'Next Question' : 'Finish Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 0,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishScreen() {
    final totalQ = _quiz!.questions.length;
    final pct = totalQ > 0 ? ((_score / totalQ) * 100).round() : 0;
    final label = pct >= 80 ? 'Excellent!' : pct >= 60 ? 'Good Job!' : 'Keep Practicing!';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      pct >= 70 ? Icons.emoji_events : Icons.school,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text('You scored $_score out of $totalQ ($pct%)',
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: pct / 100.0,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _restart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Retry Quiz',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Back to Gaps',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
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
