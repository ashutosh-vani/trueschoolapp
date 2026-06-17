import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/progress/data/models/learning_gap_models.dart';
import 'package:trueschoolapp/features/progress/data/services/learning_gap_service.dart';

class GapRemediationPage extends StatefulWidget {
  final String gapId;
  final LearningGap? gap;

  const GapRemediationPage({super.key, required this.gapId, this.gap});

  @override
  State<GapRemediationPage> createState() => _GapRemediationPageState();
}

class _GapRemediationPageState extends State<GapRemediationPage> {
  LearningGap? _gap;
  RemediationContent? _remediation;
  bool _loading = true;
  bool _submitted = false;
  final TextEditingController _answerCtrl = TextEditingController();
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _gap = widget.gap;
    _load();
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      if (_gap == null) LearningGapService.getGap(widget.gapId),
      LearningGapService.getRemediation(widget.gapId),
    ]);

    if (!mounted) return;
    setState(() {
      if (_gap == null && results[0] != null) {
        _gap = results[0] as LearningGap;
      }
      _remediation = (_gap == null
          ? results[0]
          : results[results.length == 2 ? 1 : 0]) as RemediationContent?;
      _loading = false;
    });
  }

  static const _sevColors = {
    'critical': AppColors.error,
    'moderate': AppColors.warning,
    'minor': AppColors.textHint,
  };

  static const _sevLabels = {
    'critical': 'Critical Severity',
    'moderate': 'Moderate Severity',
    'minor': 'Minor Severity',
  };

  static const _statusIcons = {
    'mastered': Icons.check_circle,
    'weak': Icons.warning_amber_rounded,
    'current': Icons.my_location,
  };

  static const _statusColors = {
    'mastered': AppColors.success,
    'weak': AppColors.warning,
    'current': AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    if (_loading && _gap == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    final gap = _gap;
    if (gap == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          title: const Text('Gap not found'),
          elevation: 0,
        ),
        body: const Center(
          child:
              Text('Gap not found.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final sevColor =
        _sevColors[gap.severity] ?? AppColors.textSecondary;
    final sevLabel = _sevLabels[gap.severity] ?? gap.severity;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, gap),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title section
                    Row(
                      children: [
                        _severityBadge(sevLabel, sevColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${gap.subject} · ${gap.subtopic}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      gap.topic,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Detected context card
                    _sectionCard(
                      title: 'Gap Detection Context',
                      icon: Icons.analytics_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gap.identifiedFrom.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${gap.identifiedFrom.type.toUpperCase()} · ${gap.identifiedFrom.date}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Error Summary: ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            gap.aiErrorSummary,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Prerequisite map
                    _sectionCard(
                      title: 'Prerequisite Map',
                      icon: Icons.account_tree_outlined,
                      child: Column(
                        children: gap.prerequisites
                            .asMap()
                            .entries
                            .map((entry) {
                          final i = entry.key;
                          final pre = entry.value;
                          final icon =
                              _statusIcons[pre.status] ?? Icons.circle;
                          final color =
                              _statusColors[pre.status] ?? AppColors.textHint;
                          final isLast =
                              i == gap.prerequisites.length - 1;

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(icon,
                                        color: color, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pre.topic,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          pre.status == 'current'
                                              ? 'Current Goal'
                                              : pre.status == 'mastered'
                                                  ? 'Mastered (${pre.masteryPercent}%)'
                                                  : 'Weak (${pre.masteryPercent}%)',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: color),
                                        ),
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
                                    height: 20,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.25),
                                          width: 2,
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Corrective path
                    _sectionCard(
                      title: 'Corrective Path',
                      icon: Icons.route_outlined,
                      child: Column(
                        children: gap.correctivePath.map((cp) {
                          final icon = _correctiveIcon(cp.icon);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.15)),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Icon(icon,
                                        color: AppColors.primary,
                                        size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cp.label,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          cp.detail,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      color: AppColors.textHint),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // AI Remediation content (if loaded from API)
                    if (_remediation != null) ...[
                      _sectionCard(
                        title: 'AI Remediation Guide',
                        icon: Icons.auto_awesome,
                        headerColor: AppColors.primary,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_remediation!.explanation.isNotEmpty) ...[
                              Text(
                                _remediation!.explanation,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (_remediation!.keyPoints.isNotEmpty) ...[
                              ..._remediation!.keyPoints.map((pt) =>
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 6),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.check_circle,
                                            size: 16,
                                            color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            pt,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color:
                                                  AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              const SizedBox(height: 8),
                            ],
                            if (_remediation!.examples.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'EXAMPLES',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ..._remediation!.examples.map(
                                        (ex) => Padding(
                                              padding:
                                                  const EdgeInsets.only(
                                                      bottom: 4),
                                              child: Text('• $ex',
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      color: AppColors
                                                          .textSecondary)),
                                            )),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Remediation workspace
                    _sectionCard(
                      title: 'Remediation Workspace',
                      icon: Icons.quiz_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Retry question
                          if (gap.retryQuestion != null) ...[
                            const Text(
                              'New but Similar Question',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.15)),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    gap.retryQuestion!.text,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                      height: 1.5,
                                    ),
                                  ),
                                  if (gap.retryQuestion!.equation !=
                                      null) ...[
                                    const SizedBox(height: 12),
                                    Center(
                                      child: Text(
                                        gap.retryQuestion!.equation!,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Answer input
                          const Text(
                            'Your Solution',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _answerCtrl,
                            enabled: !_submitted,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText:
                                  'Show your working here...',
                              hintStyle: const TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 13),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (_submitted)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.success
                                    .withValues(alpha: 0.08),
                                border: Border.all(
                                    color: AppColors.success
                                        .withValues(alpha: 0.3)),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: AppColors.success,
                                      size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Submitted! Review below.',
                                          style: TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                            color: AppColors.success,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          gap.aiLastFeedback,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors
                                                .textSecondary,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_answerCtrl.text.trim().isEmpty)
                                    return;
                                  setState(
                                      () => _submitted = true);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Submit Answer',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),

                          // Hint toggle
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _showHint = !_showHint),
                            child: Row(
                              children: [
                                const Text(
                                  'Hint for next time',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  _showHint
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                          if (_showHint && gap.aiLastFeedback.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                gap.aiLastFeedback,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Improvement tracker
                    if (gap.attempts.isNotEmpty)
                      _sectionCard(
                        title: 'Improvement Tracker',
                        icon: Icons.show_chart,
                        child: Column(
                          children: [
                            ...gap.attempts.map(
                              (att) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 72,
                                      child: Text(
                                        'Attempt ${att.attemptNumber}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: att.score / 100,
                                          minHeight: 8,
                                          backgroundColor:
                                              AppColors.border,
                                          color: att.score < 50
                                              ? AppColors.error
                                              : att.score < 75
                                                  ? AppColors.warning
                                                  : AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${att.score}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: att.score < 50
                                            ? AppColors.error
                                            : att.score < 75
                                                ? AppColors.warning
                                                : AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (gap.visualRef != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.functions,
                                  color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    gap.visualRef!.label,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    gap.visualRef!.detail,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LearningGap gap) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              gap.topic,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _severityBadge(String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Color headerColor = AppColors.primary,
  }) {
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Icon(icon, color: headerColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: headerColor == AppColors.primary
                        ? AppColors.textPrimary
                        : headerColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  IconData _correctiveIcon(String iconName) {
    switch (iconName) {
      case 'play_circle':
        return Icons.play_circle_outline;
      case 'menu_book':
        return Icons.menu_book;
      case 'edit_note':
        return Icons.edit_note;
      default:
        return Icons.help_outline;
    }
  }
}
