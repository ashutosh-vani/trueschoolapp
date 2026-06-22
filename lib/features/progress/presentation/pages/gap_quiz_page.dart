import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/progress/data/models/learning_gap_models.dart';
import 'package:trueschoolapp/features/progress/data/services/learning_gap_service.dart';

/// Full quiz-taking page — mirrors GapQuiz.jsx from the web frontend.
/// Fetches the quiz from the API (with local fallback), walks through each
/// question, shows instant feedback, tracks score, and submits to the backend.
class GapQuizPage extends StatefulWidget {
  final String quizId;

  const GapQuizPage({super.key, required this.quizId});

  @override
  State<GapQuizPage> createState() => _GapQuizPageState();
}

class _GapQuizPageState extends State<GapQuizPage> {
  Quiz? _quiz;
  bool _loadingQuiz = true;
  bool _submitting = false;

  // Per-question state
  int _currentIdx = 0;
  String? _selectedOptionId;
  bool _checked = false;
  bool _showHint = false;
  int _score = 0;
  bool _finished = false;

  // Accumulated answers for API submission
  final List<QuizAnswer> _allAnswers = [];

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    final quiz = await LearningGapService.getQuiz(widget.quizId);
    if (!mounted) return;
    setState(() {
      _quiz = quiz;
      _loadingQuiz = false;
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  QuizQuestion get _currentQuestion => _quiz!.questions[_currentIdx];
  int get _totalQuestions => _quiz!.questions.length;
  int get _progressPct => ((_currentIdx / _totalQuestions) * 100).round();

  QuizOption? get _correctOption => _currentQuestion.correctOption;

  bool get _isCorrect =>
      _checked &&
      _selectedOptionId != null &&
      _selectedOptionId == _correctOption?.id;

  void _checkAnswer() {
    if (_selectedOptionId == null) return;
    final isRight = _selectedOptionId == _correctOption?.id;
    setState(() {
      _checked = true;
      if (isRight) _score++;
    });
    _allAnswers.add(QuizAnswer(
      questionId: _currentQuestion.id,
      selectedOptionId: _selectedOptionId!,
    ));
  }

  Future<void> _next() async {
    if (_currentIdx < _totalQuestions - 1) {
      setState(() {
        _currentIdx++;
        _selectedOptionId = null;
        _checked = false;
        _showHint = false;
      });
    } else {
      // Last question → submit + show results
      setState(() => _submitting = true);
      await LearningGapService.submitQuiz(widget.quizId, _allAnswers);
      if (mounted) setState(() { _submitting = false; _finished = true; });
    }
  }

  Future<void> _nextWithoutChecking() async {
    if (_selectedOptionId == null) return;
    final isRight = _selectedOptionId == _correctOption?.id;
    setState(() {
      if (isRight) _score++;
    });
    _allAnswers.add(QuizAnswer(
      questionId: _currentQuestion.id,
      selectedOptionId: _selectedOptionId!,
    ));
    await _next();
  }

  void _retry() {
    setState(() {
      _currentIdx = 0;
      _selectedOptionId = null;
      _checked = false;
      _showHint = false;
      _score = 0;
      _finished = false;
      _allAnswers.clear();
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loadingQuiz) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('Loading Quiz...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_quiz == null || _quiz!.questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('Quiz'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.quiz_outlined,
                  size: 64, color: AppColors.textHint),
              const SizedBox(height: 16),
              const Text(
                'Quiz not found.',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.maybePop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_finished) return _buildFinishedScreen();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildQuestionCard(),
                    const SizedBox(height: 16),
                    if (_checked) _buildFeedbackPanel(),
                    const SizedBox(height: 80), // space for footer
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildFooter(),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _quiz!.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_off_outlined,
                    color: Colors.white, size: 13),
                SizedBox(width: 4),
                Text('No timer',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress bar ───────────────────────────────────────────────────────────

  Widget _buildProgressBar() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Q${_currentIdx + 1} of $_totalQuestions',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '$_progressPct%',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progressPct / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Question card ──────────────────────────────────────────────────────────

  Widget _buildQuestionCard() {
    final q = _currentQuestion;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Question header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Q${q.number}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        q.difficulty.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  q.prompt,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (q.equation != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      q.equation!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Options
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              children: q.options.map((opt) => _buildOption(opt)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(QuizOption opt) {
    final isSelected = _selectedOptionId == opt.id;
    final isCorrect = _checked && opt.isCorrect;
    final isWrong = _checked && isSelected && !opt.isCorrect;

    Color borderColor;
    Color bgColor;
    Color textColor;

    if (isCorrect) {
      borderColor = AppColors.success;
      bgColor = AppColors.success.withValues(alpha: 0.06);
      textColor = AppColors.success;
    } else if (isWrong) {
      borderColor = AppColors.error;
      bgColor = AppColors.error.withValues(alpha: 0.06);
      textColor = AppColors.error;
    } else if (isSelected) {
      borderColor = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.06);
      textColor = AppColors.primary;
    } else {
      borderColor = AppColors.border;
      bgColor = AppColors.background.withValues(alpha: 0.5);
      textColor = AppColors.textPrimary;
    }

    return GestureDetector(
      onTap: _checked ? null : () => setState(() => _selectedOptionId = opt.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Radio circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected || isCorrect
                    ? (isWrong ? AppColors.error : AppColors.primary)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected || isCorrect
                      ? (isWrong ? AppColors.error : AppColors.primary)
                      : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected || isCorrect
                  ? const Icon(Icons.circle, size: 10, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                opt.text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              opt.id,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Feedback panel ─────────────────────────────────────────────────────────

  Widget _buildFeedbackPanel() {
    final q = _currentQuestion;
    final correct = _correctOption;
    final borderColor = _isCorrect ? AppColors.success : AppColors.error;
    final iconColor = _isCorrect ? AppColors.success : AppColors.error;
    final bgColor = _isCorrect
        ? AppColors.success.withValues(alpha: 0.05)
        : AppColors.error.withValues(alpha: 0.05);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isCorrect ? Icons.celebration : Icons.cancel_outlined,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isCorrect
                            ? 'Correct! Well done!'
                            : 'Not quite — the answer is ${correct?.text ?? ''}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _isCorrect
                              ? AppColors.textPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        q.explanation,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Hint toggle
            if (q.hint.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () =>
                    setState(() => _showHint = !_showHint),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Hint for next time',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    AnimatedRotation(
                      turns: _showHint ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_more,
                          color: AppColors.primary, size: 18),
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    q.hint,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
                crossFadeState: _showHint
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    final correctedSoFar = _score;
    final answeredSoFar = _currentIdx + (_checked ? 1 : 0);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SCORE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '$correctedSoFar/$answeredSoFar correct',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (!_checked) ...[
              SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _selectedOptionId != null ? _checkAnswer : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: _selectedOptionId == null
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : AppColors.primary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  icon: Icon(
                    Icons.check,
                    color: _selectedOptionId == null
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.primary,
                    size: 18,
                  ),
                  label: Text(
                    'Check Answer',
                    style: TextStyle(
                      color: _selectedOptionId == null
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _selectedOptionId != null && !_submitting
                      ? _nextWithoutChecking
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  label: Text(
                    _currentIdx < _totalQuestions - 1 ? 'Next' : 'Finish',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ] else
              // Next / Finish button
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(
                          _currentIdx < _totalQuestions - 1
                              ? Icons.arrow_forward
                              : Icons.flag_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                  label: Text(
                    _currentIdx < _totalQuestions - 1
                        ? 'Next Question'
                        : 'Finish Quiz',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Finished screen ────────────────────────────────────────────────────────

  Widget _buildFinishedScreen() {
    final pct =
        _totalQuestions > 0 ? (_score / _totalQuestions * 100).round() : 0;

    String headline;
    if (pct >= 80) {
      headline = 'Excellent!';
    } else if (pct >= 60) {
      headline = 'Good Job!';
    } else {
      headline = 'Keep Practicing!';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    pct >= 70
                        ? Icons.emoji_events_outlined
                        : Icons.school_outlined,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  headline,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You scored $_score out of $_totalQuestions ($pct%)',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                // Score bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 12,
                    backgroundColor: AppColors.border,
                    color: pct >= 70 ? AppColors.success : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),
                // Retry
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _retry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Retry Quiz',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Back to gaps
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.maybePop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Back to Quizzes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
