import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/exam_prep/data/models/exam_prep_model.dart';
import 'package:trueschoolapp/features/exam_prep/data/services/exam_prep_service.dart';
import 'package:trueschoolapp/features/exam_prep/presentation/pages/create_exam_prep_page.dart';
import 'package:trueschoolapp/features/exam_prep/presentation/pages/exam_prep_detail_page.dart';

/// ── Exam Prep List Page ─────────────────────────────────────────────────────
/// Matches the screenshot:
///   - Header "Exam Preparation / Your study plans" + "+ New Prep" button
///   - "N exam prep(s)" count
///   - One card per plan with class·board, status badge, subject chips,
///     status line + "Start Over" or "View" action, and "Remove" button
class ExamPrepListPage extends StatefulWidget {
  const ExamPrepListPage({super.key});

  @override
  State<ExamPrepListPage> createState() => _ExamPrepListPageState();
}

class _ExamPrepListPageState extends State<ExamPrepListPage> {
  bool _isLoading = true;
  List<_PlanCard> _plans = [];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);

    final apiPlans = await ExamPrepService.getExamPreps();

    if (!mounted) return;
    setState(() {
      _plans = apiPlans.map((p) => _PlanCard.fromApi(p)).toList();
      _isLoading = false;
    });
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _openCreatePage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateExamPrepPage()),
    );
    if (result == true) _loadPlans();
  }

  Future<void> _removePlan(_PlanCard plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove plan?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text(
          'Remove the "${plan.studentClass} · ${plan.board}" exam prep plan?',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Optimistic removal from UI immediately
    setState(() => _plans.removeWhere((p) => p.id == plan.id));

    // Real API plan — fire-and-forget, ignore failures
    await ExamPrepService.deleteExamPrep(plan.id);
  }

  void _startOver(_PlanCard plan) async {
    // Mark as re-started: remove + reopen create flow
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Start Over?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: const Text(
          'This will reset your progress for this plan and create a new one.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Start Over',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Remove old plan — optimistic then persist
    setState(() => _plans.removeWhere((p) => p.id == plan.id));
    await ExamPrepService.deleteExamPrep(plan.id);

    // Launch create flow
    if (!mounted) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateExamPrepPage()),
    );
    if (result == true || result == null) _loadPlans();
  }

  void _openDetail(_PlanCard plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamPrepDetailPage(
          planId: plan.id,
          studentClass: plan.studentClass,
          board: plan.board,
          status: plan.status,
          subjects: plan.subjects,
        ),
      ),
    ).then((_) => _loadPlans());
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            if (_isLoading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadPlans,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    children: [
                      // Count line
                      Text(
                        '${_plans.length} exam prep${_plans.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Plan cards
                      ..._plans.map((plan) => _buildPlanCard(plan)),

                      // Empty state
                      if (_plans.isEmpty) _buildEmptyState(),

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

  // ── App Bar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back,
                color: AppColors.textPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exam Preparation',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Your study plans',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // "+ New Prep" button
          GestureDetector(
            onTap: _openCreatePage,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'New Prep',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Plan Card (matches screenshot) ────────────────────────────────────────

  Widget _buildPlanCard(_PlanCard plan) {
    final isCompleted = plan.status == 'completed';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: isCompleted ? null : () => _openDetail(plan),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF0F0F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Top section ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Class · Board + Status badge
                          Row(
                            children: [
                              Text(
                                _planTitle(plan),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _statusBadge(plan.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Subject count · progress label
                          Text(
                            _planSubtitle(plan),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Subject chips
                          if (plan.subjects.isNotEmpty)
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: plan.subjects
                                  .take(4)
                                  .map((s) => _subjectChip(s))
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                    // Chevron — only if active/paused
                    if (!isCompleted)
                      const Icon(Icons.chevron_right,
                          color: AppColors.textSecondary, size: 22),
                  ],
                ),
              ),

              // ── Divider ──────────────────────────────────────────────
              const Divider(height: 1, color: Color(0xFFF0F0F0)),

              // ── Bottom action row ─────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: status message
                    Text(
                      _statusMessage(plan),
                      style: TextStyle(
                        fontSize: 13,
                        color: isCompleted
                            ? AppColors.textSecondary
                            : AppColors.primary,
                        fontWeight: isCompleted
                            ? FontWeight.normal
                            : FontWeight.w500,
                      ),
                    ),

                    // Right: contextual action
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCompleted) ...[
                          GestureDetector(
                            onTap: () => _startOver(plan),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.refresh_rounded,
                                    size: 15, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Start Over',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          GestureDetector(
                            onTap: () => _openDetail(plan),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.open_in_new_rounded,
                                    size: 14,
                                    color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'View',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ── Remove row (inside same card, separated) ──────────────
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _removePlan(plan),
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 15, color: Colors.grey.shade400),
                  label: Text(
                    'Remove',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Status badge pill ─────────────────────────────────────────────────────

  Widget _statusBadge(String status) {
    Color fg;
    Color bg;
    String label;
    switch (status) {
      case 'completed':
      case 'past':
        fg = const Color(0xFF6B7280);
        bg = const Color(0xFFF3F4F6);
        label = 'Completed';
        break;
      case 'paused':
        fg = const Color(0xFFD97706);
        bg = const Color(0xFFFFFBEB);
        label = 'Paused';
        break;
      case 'upcoming':
        fg = AppColors.primary;
        bg = AppColors.primary.withValues(alpha: 0.1);
        label = 'Upcoming';
        break;
      default:
        fg = const Color(0xFF10B981);
        bg = const Color(0xFFD1FAE5);
        label = 'Active';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  // ── Subject chip ──────────────────────────────────────────────────────────

  Color _subjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'maths':
      case 'mathematics':
        return const Color(0xFF695BE6);
      case 'science':
      case 'physics':
        return const Color(0xFFFB923C);
      case 'chemistry':
      case 'biology':
        return const Color(0xFF10B981);
      case 'english':
        return const Color(0xFF60A5FA);
      case 'social':
        return const Color(0xFF34D399);
      case 'hindi':
        return const Color(0xFFF472B6);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  Widget _subjectChip(String subject) {
    final color = _subjectColor(subject);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        subject,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _planTitle(_PlanCard plan) {
    final parts = <String>[];
    if (plan.studentClass.isNotEmpty) parts.add(plan.studentClass);
    if (plan.board.isNotEmpty) parts.add(plan.board);
    if (parts.isEmpty) return 'Exam Prep';
    return parts.join(' · ');
  }

  String _planSubtitle(_PlanCard plan) {
    final count = plan.subjects.length;
    final subjectPart = '$count ${count == 1 ? 'subject' : 'subjects'}';
    final status = ExamPrepPlan.calculatePlanStatus(plan.rawSubjects);
    final upcoming = plan.getUpcomingExam();
    
    if (upcoming != null) {
      final examDate = DateTime.parse(upcoming.examDate!);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final days = examDate.difference(today).inDays;
      return '$subjectPart · Next: ${upcoming.name} in ${days < 0 ? 0 : days}d';
    } else if (status == 'completed' || status == 'past') {
      return '$subjectPart · All exams done';
    } else {
      return '$subjectPart · In progress';
    }
  }

  String _statusMessage(_PlanCard plan) {
    final status = ExamPrepPlan.calculatePlanStatus(plan.rawSubjects);
    switch (status) {
      case 'completed':
      case 'past':
        return 'All exams completed';
      case 'paused':
        return 'Plan paused';
      default:
        final upcoming = plan.getUpcomingExam();
        if (upcoming != null) {
          final examDate = DateTime.parse(upcoming.examDate!);
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final days = examDate.difference(today).inDays;
          final finalDays = days < 0 ? 0 : days;
          return '$finalDays day${finalDays == 1 ? '' : 's'} left';
        }
        return 'Active plan';
    }
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.menu_book_outlined,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No exam preps yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap "+ New Prep" to create your first study plan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _openCreatePage,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'New Prep',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Internal view model ────────────────────────────────────────────────────────

class _PlanCard {
  final String id;
  final String studentClass;
  final String board;
  final List<String> subjects;
  final List<ExamPrepSubject> rawSubjects;
  final String status;
  final int? daysLeft;
  final int? progressPercent;

  _PlanCard({
    required this.id,
    required this.studentClass,
    required this.board,
    required this.subjects,
    required this.rawSubjects,
    this.status = 'active',
    this.daysLeft,
    this.progressPercent,
  });

  /// Build from API ExamPrepPlan
  factory _PlanCard.fromApi(ExamPrepPlan plan) {
    return _PlanCard(
      id: plan.id,
      studentClass: plan.studentClass,
      board: plan.board,
      subjects: plan.subjects,
      rawSubjects: plan.rawSubjects,
      status: plan.status,
      daysLeft: plan.daysLeft,
      progressPercent: plan.progressPercent,
    );
  }

  ExamPrepSubject? getUpcomingExam() {
    if (rawSubjects.isEmpty) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    List<ExamPrepSubject> upcoming = [];
    for (final s in rawSubjects) {
      if (s.examDate == null || s.examDate!.isEmpty) continue;
      try {
        final parsedDate = DateTime.parse(s.examDate!);
        final examDay = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
        if (examDay.isAfter(today) || examDay.isAtSameMomentAs(today)) {
          upcoming.add(s);
        }
      } catch (_) {}
    }
    
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) {
      final ad = DateTime.parse(a.examDate!);
      final bd = DateTime.parse(b.examDate!);
      return ad.compareTo(bd);
    });
    return upcoming.first;
  }
}
