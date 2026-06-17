import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/learning_gaps/data/models/learning_gap_model.dart';
import 'package:trueschoolapp/features/learning_gaps/data/services/learning_gap_service.dart';
import 'package:trueschoolapp/features/learning_gaps/presentation/pages/gap_quiz_page.dart';

class GapRemediationPage extends StatefulWidget {
  final LearningGap gap;

  const GapRemediationPage({super.key, required this.gap});

  @override
  State<GapRemediationPage> createState() => _GapRemediationPageState();
}

class _GapRemediationPageState extends State<GapRemediationPage> {
  RemediationContent? _remContent;
  bool _isLoading = true;
  final TextEditingController _answerController = TextEditingController();
  bool _submitted = false;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _loadRemediation();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadRemediation() async {
    final result = await LearningGapService.getRemediation(widget.gap.id);
    if (!mounted) return;
    setState(() {
      _remContent = result?.remediation;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gap = widget.gap;
    final sevColor = gap.severity == 'critical'
        ? const Color(0xFFEC5B13)
        : gap.severity == 'moderate'
            ? Colors.orange
            : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, gap, sevColor),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // On wider screens show sidebar, on narrow stack vertically
                      if (MediaQuery.of(context).size.width > 600) ...[
                        SizedBox(width: 280, child: _buildSidebar(gap)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildWorkspace(gap)),
                      ] else
                        Expanded(
                          child: Column(
                            children: [
                              _buildSidebar(gap),
                              const SizedBox(height: 16),
                              _buildWorkspace(gap),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LearningGap gap, Color sevColor) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Learning Gap Remediation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sevColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${gap.severity[0].toUpperCase()}${gap.severity.substring(1)} Severity',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sevColor),
                ),
              ),
              const SizedBox(width: 8),
              Text('${gap.subject} • ${gap.subtopic}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(gap.topic,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildSidebar(LearningGap gap) {
    return Column(
      children: [
        _buildDetectionContext(gap),
        const SizedBox(height: 12),
        _buildPrerequisiteMap(gap),
        const SizedBox(height: 12),
        _buildCorrectivePath(gap),
      ],
    );
  }

  Widget _buildDetectionContext(LearningGap gap) {
    return _SideCard(
      icon: Icons.analytics,
      title: 'Gap Detection Context',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gap.identifiedFrom.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text(
                  '${gap.identifiedFrom.type.toUpperCase()} · ${gap.identifiedFrom.date}',
                  style: TextStyle(fontSize: 11, color: AppColors.primary.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              children: [
                const TextSpan(
                  text: 'Error Summary: ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                TextSpan(text: gap.aiErrorSummary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrerequisiteMap(LearningGap gap) {
    return _SideCard(
      icon: Icons.account_tree,
      title: 'Prerequisite Map',
      child: Column(
        children: gap.prerequisites.asMap().entries.map((entry) {
          final i = entry.key;
          final pre = entry.value;
          final isLast = i == gap.prerequisites.length - 1;
          Color dotColor;
          Color dotBg;
          IconData dotIcon;
          String statusText;
          if (pre.status == 'mastered') {
            dotColor = Colors.green.shade700;
            dotBg = Colors.green.shade50;
            dotIcon = Icons.check_circle;
            statusText = 'Mastered (${pre.masteryPercent}%)';
          } else if (pre.status == 'current') {
            dotColor = Colors.white;
            dotBg = AppColors.primary;
            dotIcon = Icons.adjust;
            statusText = 'Current Goal';
          } else {
            dotColor = Colors.amber.shade700;
            dotBg = Colors.amber.shade50;
            dotIcon = Icons.warning_amber_rounded;
            statusText = 'Weak (${pre.masteryPercent}%)';
          }
          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: dotBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(dotIcon, size: 18, color: dotColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pre.topic,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text(statusText,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: pre.status == 'current'
                                    ? AppColors.primary
                                    : pre.status == 'mastered'
                                        ? Colors.green.shade700
                                        : Colors.amber.shade700)),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 17),
                  child: Container(
                    width: 2,
                    height: 18,
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCorrectivePath(LearningGap gap) {
    final iconMap = {
      'play_circle': Icons.play_circle_outline,
      'menu_book': Icons.menu_book_outlined,
      'edit_note': Icons.edit_note,
    };

    return _SideCard(
      icon: Icons.route,
      title: 'Corrective Path',
      child: Column(
        children: gap.correctivePath.map((cp) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(iconMap[cp.icon] ?? Icons.open_in_new,
                          size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cp.label,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Text(cp.detail,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary.withValues(alpha: 0.6))),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey.shade300),
                  ],
                ),
              ),
            )).toList(),
      ),
    );
  }

  Widget _buildWorkspace(LearningGap gap) {
    return Column(
      children: [
        _buildRemediationWorkspace(gap),
        if (gap.visualRef != null) ...[
          const SizedBox(height: 12),
          _buildVisualRef(gap.visualRef!),
        ],
        const SizedBox(height: 12),
        _buildQuizCta(gap),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildRemediationWorkspace(LearningGap gap) {
    return Container(
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
          // Workspace header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Remediation Workspace',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text('Practice until mastery',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.all_inclusive, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text('UNLIMITED RETRIES',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.8)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI remediation content from API
                if (_remContent != null) _buildAiContent(_remContent!),
                const SizedBox(height: 16),
                // Question
                _buildQuestion(gap),
                const SizedBox(height: 16),
                // Answer input
                _buildAnswerInput(gap),
                const SizedBox(height: 16),
                // Improvement tracker
                _buildImprovementTracker(gap),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiContent(RemediationContent content) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('AI Remediation Guide',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          if (content.explanation != null) ...[
            const SizedBox(height: 8),
            Text(content.explanation!,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
          if (content.keyPoints.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...content.keyPoints.map((pt) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(child: Text(pt, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestion(LearningGap gap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.quiz, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('New but Similar Question',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(gap.retryQuestion.text,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5)),
              if (gap.retryQuestion.equation != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    gap.retryQuestion.equation!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerInput(LearningGap gap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Solution',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _answerController,
          enabled: !_submitted,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Show your working here...',
            hintStyle: const TextStyle(color: AppColors.textHint),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 12),
        if (_submitted)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Submitted! Vin is reviewing your answer.',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                      const SizedBox(height: 4),
                      Text(gap.aiLastFeedback,
                          style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Save Draft'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _answerController.text.trim().isEmpty
                    ? null
                    : () {
                        if (_answerController.text.trim().isNotEmpty) {
                          setState(() => _submitted = true);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Submit Answer'),
              ),
            ],
          ),
        // Listen to controller changes to enable/disable submit
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _answerController,
          builder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildImprovementTracker(LearningGap gap) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Attempt history
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('IMPROVEMENT TRACKER',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
                const SizedBox(height: 12),
                ...gap.attempts.map((att) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 64,
                            child: Text('Attempt ${att.attemptNumber}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: att.score / 100.0,
                                minHeight: 6,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  att.score < 50
                                      ? Colors.red.shade400
                                      : att.score < 75
                                          ? Colors.amber.shade400
                                          : AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${att.score}%',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: att.score < 50
                                      ? Colors.red
                                      : att.score < 75
                                          ? Colors.amber.shade700
                                          : AppColors.primary)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // AI feedback
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text('Instant AI Explanation',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('"${gap.aiLastFeedback}"',
                    style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary)),
                // Hint toggle
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => setState(() => _showHint = !_showHint),
                  child: Row(
                    children: [
                      Text('Hint for next time',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                      Icon(_showHint ? Icons.expand_less : Icons.expand_more,
                          size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
                if (_showHint)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      gap.retryQuestion.text.length > 80
                          ? 'Re-read the question carefully and consider all cases.'
                          : gap.retryQuestion.text,
                      style: TextStyle(
                          fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade500),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualRef(VisualRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.functions, size: 28, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ref.label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(ref.detail,
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary.withValues(alpha: 0.7))),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Expand',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
              Icon(Icons.open_in_full, size: 14, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCta(LearningGap gap) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const GapQuizPage(quizId: 'quiz001'),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF685AE7), Color(0xFF8E82F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ready to test yourself?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Take a targeted quiz on ${gap.topic}',
                      style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.quiz, size: 32, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// ── Reusable sidebar card ──────────────────────────────────────────────────────
class _SideCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SideCard({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
