import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';

class HomeworkCard extends StatefulWidget {
  final String subject;
  final String status;
  final String title;
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
      case 'pending':    return 'Start Homework';
      case 'in_progress': return 'Continue Homework';
      case 'overdue':    return 'Complete Now';
      case 'completed':  return 'View Feedback';
      default:           return 'Open';
    }
  }

  bool get _isCompleted => widget.status.toLowerCase().replaceAll(' ', '_') == 'completed';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 3),
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
          const SizedBox(height: 12),
          _buildEstimatedTime(),
          // Show progress bar only for in_progress
          if (!_isCompleted) ...[
            const SizedBox(height: 16),
            _buildProgressSection(),
          ],
          // Expandable: teacher feedback for completed
          if (_expanded && _isCompleted && widget.teacherFeedback != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Teacher Feedback:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(widget.teacherFeedback!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                ],
              ),
            ),
          ],
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
          widget.subject,
          AppColors.primary.withValues(alpha: 0.1),
          AppColors.primary,
        ),
        const SizedBox(width: 8),
        _buildBadge(
          widget.status,
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
    return Row(
      children: [
        const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          widget.dueDate,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 20),
        Icon(Icons.bar_chart, size: 14, color: _getDifficultyColor()),
        const SizedBox(width: 6),
        Text(
          'Difficulty: ${widget.difficulty}',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _getDifficultyColor()),
        ),
      ],
    );
  }

  Widget _buildEstimatedTime() {
    return Row(
      children: [
        const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          widget.estimatedTime,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
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

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
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
        // Expand/collapse for details (feedback)
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
            child: Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 20),
          ),
        ),
      ],
    );
  }
}
