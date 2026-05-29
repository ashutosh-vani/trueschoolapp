import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/profile/data/models/profile_data.dart';

class AcademicProgressSection extends StatelessWidget {
  final AcademicProgress progress;

  const AcademicProgressSection({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    // "Semester 2 •\n2026"
    final semesterLine1 = progress.semester.isNotEmpty ? progress.semester : '';
    final semesterLine2 = progress.year.isNotEmpty ? progress.year : '';
    final semesterLabel = [semesterLine1, semesterLine2]
        .where((s) => s.isNotEmpty)
        .join(' •\n');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
          // ── Header row ─────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                size: 24,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Academic\nProgress',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                ),
              ),
              if (semesterLabel.isNotEmpty)
                Text(
                  semesterLabel,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Subject rows ───────────────────────────────────────────────
          ...List.generate(progress.subjects.length, (i) {
            final s = progress.subjects[i];
            return Padding(
              padding: EdgeInsets.only(
                  bottom: i < progress.subjects.length - 1 ? 18 : 0),
              child: _buildSubjectRow(s.subject, s.progress),
            );
          }),

          const SizedBox(height: 28),

          // ── Stats row ──────────────────────────────────────────────────
          _buildStatsRow(),
        ],
      ),
    );
  }

  Widget _buildSubjectRow(String subject, double value) {
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
              '${(value * 100).toInt()}%',
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
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            '${progress.conceptsMastered}',
            'CONCEPTS\nMASTERED',
            AppColors.primary,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            progress.improvement.isNotEmpty ? progress.improvement : '—',
            'IMPROVEMENT',
            AppColors.success,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            progress.classRank.isNotEmpty ? progress.classRank : '—',
            'CLASS RANK',
            AppColors.primary,
          ),
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
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.4,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
