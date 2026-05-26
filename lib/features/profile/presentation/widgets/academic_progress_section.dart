import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';

class AcademicProgressSection extends StatelessWidget {
  const AcademicProgressSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_outlined, size: 22, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              const Text(
                'Academic\nProgress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                'Semester 2 •\n2026',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSubjectRow('Mathematics', 0.85),
          const SizedBox(height: 16),
          _buildSubjectRow('Science', 0.92),
          const SizedBox(height: 16),
          _buildSubjectRow('English Literature', 0.78),
          const SizedBox(height: 16),
          _buildSubjectRow('Computer Science', 0.92),
          const SizedBox(height: 16),
          _buildSubjectRow('History', 0.74),
          const SizedBox(height: 28),
          _buildStatsRow(),
        ],
      ),
    );
  }

  Widget _buildSubjectRow(String subject, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              subject,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem('0', 'CONCEPTS\nMASTERED', AppColors.primary),
        ),
        Expanded(
          child: _buildStatItem('+12%', 'IMPROVEMENT', AppColors.success),
        ),
        Expanded(
          child: _buildStatItem('Top\n15%', 'CLASS RANK', AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
