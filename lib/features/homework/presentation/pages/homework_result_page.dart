import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/homework/data/models/homework_question.dart';
import 'package:trueschoolapp/features/homework/presentation/pages/homework_attempt_page.dart';

/// Full result screen shown after homework submission — mirrors web HomeworkResult.jsx.
class HomeworkResultPage extends StatelessWidget {
  final String homeworkId;
  final String homeworkTitle;
  final Map<String, dynamic>? apiResult;

  /// The full question list (needed for per-question review).
  final List<HomeworkQuestion> questionSet;

  /// Student's answers: question_id → selected option id or typed string.
  final Map<String, String?> answers;

  /// True if this was a file/handwritten submission.
  final bool fileSubmission;

  const HomeworkResultPage({
    super.key,
    required this.homeworkId,
    required this.homeworkTitle,
    this.apiResult,
    this.questionSet = const [],
    this.answers = const {},
    this.fileSubmission = false,
  });

  // ── Score helpers ──────────────────────────────────────────────
  static Color _scoreColor(int pct) {
    if (pct >= 80) return Colors.green;
    if (pct >= 50) return const Color(0xFFF59E0B);
    return AppColors.error;
  }

  static String _grade(int pct) {
    if (pct >= 90) return 'A+';
    if (pct >= 80) return 'A';
    if (pct >= 70) return 'B+';
    if (pct >= 60) return 'B';
    if (pct >= 50) return 'C';
    return 'D';
  }

  static String _encouragement(int pct) {
    if (pct >= 80) return 'Outstanding work! You\'ve mastered this topic.';
    if (pct >= 60) return 'Good effort! A little more practice and you\'ll nail it.';
    return 'Keep going! Every attempt makes you stronger.';
  }

  static String _emoji(int pct) {
    if (pct >= 80) return '🎉';
    if (pct >= 60) return '👍';
    return '💪';
  }

  @override
  Widget build(BuildContext context) {
    if (fileSubmission) return _buildFileResult(context);

    // ── Compute score ──
    final serverPct = apiResult?['auto_score_pct'] as int?;
    final mcqEarned = (apiResult?['mcq_earned'] ?? 0) as int;
    final mcqTotal = (apiResult?['mcq_total'] ?? 0) as int;

    final mcqQuestions = questionSet.where((q) => q.answerType == 'mcq').toList();
    int localMcqCorrect = 0;
    for (final q in mcqQuestions) {
      final ans = answers[q.id];
      if (ans != null) {
        final correctOpt = q.options.firstWhere(
          (o) => o.isCorrect,
          orElse: () => QuestionOption(id: '', text: ''),
        );
        if (correctOpt.id.isNotEmpty && ans == correctOpt.id) localMcqCorrect++;
      }
    }

    final finalMcqCorrect = apiResult != null ? mcqEarned : localMcqCorrect;
    final finalMcqTotal = apiResult != null ? mcqTotal : mcqQuestions.fold(0, (s, q) => s + q.maxPoints);
    final totalPoints = questionSet.fold(0, (s, q) => s + q.maxPoints);
    final answeredCount = questionSet.where((q) => (answers[q.id] ?? '').isNotEmpty).length;

    final nonMcqAnswered = questionSet.where((q) => q.answerType != 'mcq' && (answers[q.id] ?? '').isNotEmpty).toList();
    final estimatedNonMcq = nonMcqAnswered.fold(0, (s, q) => s + (q.maxPoints * 0.7).round());
    final estimatedScore = finalMcqCorrect + estimatedNonMcq;
    final scorePct = serverPct ?? (totalPoints > 0 ? ((estimatedScore / totalPoints) * 100).round() : 0);
    final grade = _grade(scorePct);
    final color = _scoreColor(scorePct);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    _buildScoreCard(scorePct, grade, color),
                    const SizedBox(height: 16),
                    _buildStatsRow(answeredCount, finalMcqCorrect, finalMcqTotal, nonMcqAnswered.length, estimatedScore, totalPoints),
                    const SizedBox(height: 16),
                    _buildVinFeedback(scorePct, finalMcqCorrect, finalMcqTotal),
                    const SizedBox(height: 20),
                    _buildQuestionReview(),
                    const SizedBox(height: 20),
                    _buildActions(context),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.menu_book_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(homeworkTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const Text('Submission Summary', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Score card with ring ─────────────────────────────────────────
  Widget _buildScoreCard(int scorePct, String grade, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _ScoreRing(pct: scorePct, grade: grade, color: color),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(_emoji(scorePct), style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 6),
                        Text(
                          scorePct >= 80 ? 'EXCELLENT' : scorePct >= 60 ? 'GOOD JOB' : 'KEEP TRYING',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_encouragement(scorePct), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.4)),
                    const SizedBox(height: 8),
                    const Text('Typed and upload answers are pending teacher review.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats row ────────────────────────────────────────────────────
  Widget _buildStatsRow(int answered, int mcqCorrect, int mcqTotal, int pending, int estimated, int total) {
    final stats = [
      {'label': 'Questions', 'value': '$answered/${questionSet.length}', 'icon': Icons.quiz_outlined, 'color': AppColors.primary},
      {'label': 'MCQ Score', 'value': '$mcqCorrect/$mcqTotal', 'icon': Icons.check_circle_outline, 'color': Colors.green},
      {'label': 'Pending', 'value': '$pending answers', 'icon': Icons.pending_outlined, 'color': const Color(0xFFF59E0B)},
      {'label': 'Est. Score', 'value': '$estimated/$total', 'icon': Icons.stars_outlined, 'color': Colors.purple},
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.0,
      children: stats.map((s) {
        final color = s['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
          child: Row(
            children: [
              Icon(s['icon'] as IconData, size: 22, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(s['value'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text(s['label'] as String, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Lumi feedback panel ────────────────────────────────────────────────
  Widget _buildVinFeedback(int scorePct, int mcqCorrect, int mcqTotal) {
    final msg = scorePct >= 80
        ? 'Great work on the MCQ section! You correctly answered $mcqCorrect out of $mcqTotal objective questions.'
        : scorePct >= 50
            ? "You're on the right track! You got $mcqCorrect/$mcqTotal MCQs correct. Review the questions you missed."
            : "Don't worry — this topic takes practice. You answered $mcqCorrect/$mcqTotal MCQs correctly. Revisit the key concepts.";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo.shade50, Colors.purple.shade50]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(22)),
            child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lumi Feedback', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                Text(msg, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {},
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('Get personalised study plan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Per-question review ──────────────────────────────────────────
  Widget _buildQuestionReview() {
    if (questionSet.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Question Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        ...questionSet.asMap().entries.map((entry) {
          final i = entry.key;
          final q = entry.value;
          return Padding(padding: const EdgeInsets.only(bottom: 10), child: _QuestionReviewCard(question: q, studentAnswer: answers[q.id], index: i));
        }),
      ],
    );
  }

  // ── Action buttons ───────────────────────────────────────────────
  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => HomeworkAttemptPage(
                    homeworkId: homeworkId,
                    title: homeworkTitle,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.replay, size: 18),
            label: const Text('Retry Homework', style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back to Homework', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  // ── File submission result ───────────────────────────────────────
  Widget _buildFileResult(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(40)),
                  child: const Icon(Icons.cloud_done_outlined, color: Colors.green, size: 40),
                ),
                const SizedBox(height: 20),
                const Text('Submitted!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                const Text('Your work has been uploaded successfully.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                const Text('Your teacher will review it and publish your grade. You\'ll be notified when it\'s ready.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Back to Homework', style: TextStyle(fontWeight: FontWeight.bold)),
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

// ── Score Ring widget ────────────────────────────────────────────
class _ScoreRing extends StatelessWidget {
  final int pct;
  final String grade;
  final Color color;

  const _ScoreRing({required this.pct, required this.grade, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(110, 110),
            painter: _RingPainter(pct: pct, color: color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(grade, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              Text('$pct%', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final int pct;
  final Color color;
  const _RingPainter({required this.pct, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    final trackPaint = Paint()..color = const Color(0xFFE8E9F2)..strokeWidth = 10..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final fillPaint = Paint()..color = color..strokeWidth = 10..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    final sweepAngle = 2 * math.pi * pct / 100;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, sweepAngle, false, fillPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.pct != pct || old.color != color;
}

// ── Per-question review card ─────────────────────────────────────
class _QuestionReviewCard extends StatelessWidget {
  final HomeworkQuestion question;
  final String? studentAnswer;
  final int index;

  const _QuestionReviewCard({required this.question, this.studentAnswer, required this.index});

  @override
  Widget build(BuildContext context) {
    final answered = studentAnswer != null && studentAnswer!.isNotEmpty;
    final isMcq = question.answerType == 'mcq';
    final isUpload = question.answerType == 'upload';

    // Determine correctness for MCQ
    bool? mcqCorrect;
    String? selectedText;
    String? correctText;
    if (isMcq && answered) {
      final selectedOpt = question.options.where((o) => o.id == studentAnswer).firstOrNull;
      final correctOpt = question.options.where((o) => o.isCorrect).firstOrNull;
      mcqCorrect = selectedOpt?.isCorrect ?? false;
      selectedText = selectedOpt?.text;
      correctText = correctOpt?.text;
    }

    // Status icon + color
    IconData statusIcon;
    Color statusColor;
    if (!answered) {
      statusIcon = Icons.remove_circle_outline;
      statusColor = Colors.grey.shade300;
    } else if (isUpload) {
      statusIcon = Icons.cloud_done_outlined;
      statusColor = Colors.blue;
    } else if (isMcq) {
      statusIcon = (mcqCorrect ?? false) ? Icons.check_circle_outline : Icons.cancel_outlined;
      statusColor = (mcqCorrect ?? false) ? Colors.green : AppColors.error;
    } else {
      statusIcon = Icons.pending_outlined;
      statusColor = const Color(0xFFF59E0B);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(statusIcon, size: 22, color: statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Q${index + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(width: 6),
                    Text(question.answerType, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const Spacer(),
                    Text('${question.maxPoints} pt${question.maxPoints > 1 ? "s" : ""}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(question.questionText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (answered) ...[
                  const SizedBox(height: 6),
                  if (isMcq && selectedText != null)
                    Text(
                      'Your answer: $selectedText${(mcqCorrect == false && correctText != null) ? ' · Correct: $correctText' : ''}',
                      style: TextStyle(fontSize: 11, color: (mcqCorrect ?? false) ? Colors.green : AppColors.error, fontWeight: FontWeight.w500),
                    ),
                  if (!isMcq && !isUpload)
                    Text('"$studentAnswer"', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (isUpload)
                    const Text('File uploaded', style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w500)),
                ],
                if (!answered)
                  const Text('Not answered', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
