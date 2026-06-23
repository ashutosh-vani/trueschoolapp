import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';

class HomeworkCard extends StatefulWidget {
  final String subject;
  final String status;
  final String title;
  final String description;
  final String assignedBy;
  final String dueDate;
  final String difficulty;
  final String estimatedTime;
  final double progress;
  final String? grade;
  final String? teacherFeedback;
  final VoidCallback? onTap;

  const HomeworkCard({
    super.key,
    required this.subject,
    required this.status,
    required this.title,
    this.description = '',
    required this.assignedBy,
    required this.dueDate,
    required this.difficulty,
    required this.estimatedTime,
    required this.progress,
    this.grade,
    this.teacherFeedback,
    this.onTap,
  });

  @override
  State<HomeworkCard> createState() => _HomeworkCardState();
}

class _HomeworkCardState extends State<HomeworkCard> {
  bool _expanded = false;

  Color _getStatusColor() {
    switch (widget.status.toLowerCase().replaceAll(' ', '_')) {
      case 'in_progress':
        return const Color(0xFF2E7D32);
      case 'overdue':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
      case 'awaiting_evaluation':
      case 'submitted':
        return const Color(0xFFD97706); // Amber
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getDifficultyColor() {
    switch (widget.difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _actionLabel {
    switch (widget.status.toLowerCase().replaceAll(' ', '_')) {
      case 'pending':
        return 'Start Homework';
      case 'in_progress':
        return 'Continue Homework';
      case 'overdue':
        return 'Complete Now';
      case 'completed':
        return 'View Feedback';
      case 'awaiting_evaluation':
      case 'submitted':
        return 'View Submission';
      default:
        return 'Open';
    }
  }

  bool get _isCompleted => widget.status.toLowerCase().replaceAll(' ', '_') == 'completed';

  bool get _isAwaitingEvaluation =>
      widget.status.toLowerCase().replaceAll(' ', '_') == 'awaiting_evaluation' ||
      widget.status.toLowerCase().replaceAll(' ', '_') == 'submitted';

  bool get _isSubmitted => _isCompleted || _isAwaitingEvaluation;

  String get _submissionDateText {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return 'Submitted ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: _getStatusColor(), width: 3),
        ),
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
          _buildBadges(),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(widget.assignedBy, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              // Show grade for completed homework
              if (_isCompleted && widget.grade != null) ...[
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(widget.grade!, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green)),
                    const Text('GRADE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8)),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _buildMetaRow(),
          
          _buildNoticeBox(),

          // Show progress bar only if not submitted/completed
          if (!_isSubmitted) ...[
            const SizedBox(height: 16),
            _buildProgressSection(),
          ],

          _buildExpandableDetails(),

          const SizedBox(height: 16),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildBadges() {
    return Row(
      children: [
        _buildBadge(
          widget.subject.toUpperCase(),
          AppColors.primary.withValues(alpha: 0.1),
          AppColors.primary,
        ),
        const SizedBox(width: 8),
        _buildBadge(
          widget.status.toUpperCase(),
          _getStatusColor().withValues(alpha: 0.1),
          _getStatusColor(),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMetaRow() {
    final isSubmitted = _isSubmitted;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Date item (Submitted Date or Due Date)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSubmitted ? Icons.check_circle_outline_rounded : Icons.calendar_today_outlined,
              size: 14,
              color: isSubmitted ? Colors.green : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              isSubmitted ? _submissionDateText : widget.dueDate,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        // Difficulty item
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, size: 14, color: _getDifficultyColor()),
            const SizedBox(width: 6),
            Text(
              'Difficulty: ${widget.difficulty}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _getDifficultyColor()),
            ),
          ],
        ),
        // Third item (Submitted with star or Est. Time with clock)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSubmitted ? Icons.star_outline_rounded : Icons.access_time,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              isSubmitted ? 'Submitted' : widget.estimatedTime,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoticeBox() {
    if (!_isAwaitingEvaluation) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Amber 50
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFEF3C7)), // Amber 100
      ),
      child: const Row(
        children: [
          Icon(Icons.hourglass_empty_rounded, color: Color(0xFFD97706), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Submitted — waiting for teacher evaluation',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB45309), // Amber 800
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final progressPercent = (widget.progress * 100).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('PROGRESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
            Text('$progressPercent%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: widget.progress,
            minHeight: 6,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableDetails() {
    if (!_expanded) return const SizedBox.shrink();
    return Column(
      children: [
        // Description Container
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC), // Slate 50
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Description:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (widget.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  widget.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Teacher Feedback Container (if any)
        if (_isCompleted && widget.teacherFeedback != null && widget.teacherFeedback!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4), // Green 50
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Teacher Feedback:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.teacherFeedback!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF166534),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions() {
    final isAwaiting = _isAwaitingEvaluation;
    return Row(
      children: [
        Expanded(
          child: isAwaiting
              ? ElevatedButton(
                  onPressed: widget.onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9), // Slate 100
                    foregroundColor: const Color(0xFF1E293B), // Slate 800
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Text(_actionLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                )
              : OutlinedButton(
                  onPressed: widget.onTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _isCompleted ? Colors.grey.shade700 : AppColors.primary,
                    side: BorderSide(color: _isCompleted ? Colors.grey.shade300 : AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(_actionLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
        ),
        const SizedBox(width: 12),
        // Expand/collapse details (Description)
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: Colors.grey.shade200),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}

