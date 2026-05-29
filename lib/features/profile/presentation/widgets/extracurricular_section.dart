import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/profile/data/models/profile_data.dart';

class ExtracurricularSection extends StatelessWidget {
  final List<ExtracurricularItem> activities;

  const ExtracurricularSection({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
          // ── Section heading ────────────────────────────────────────────
          const Row(
            children: [
              Icon(
                Icons.people_rounded,
                size: 22,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Text(
                'Extracurricular',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── 2-column grid ──────────────────────────────────────────────
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.4,
            ),
            itemBuilder: (context, i) {
              final a = activities[i];
              return _buildChip(
                icon: _iconForActivity(a.iconName, a.name),
                name: a.name,
                role: a.role,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String name,
    required String role,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForActivity(String? iconName, String name) {
    final hint = (iconName ?? name).toLowerCase();
    if (hint.contains('code') || hint.contains('coding') || hint.contains('programming')) {
      return Icons.code;
    } else if (hint.contains('math')) {
      return Icons.functions;
    } else if (hint.contains('cricket')) {
      return Icons.sports_cricket;
    } else if (hint.contains('football') || hint.contains('soccer')) {
      return Icons.sports_soccer;
    } else if (hint.contains('basketball')) {
      return Icons.sports_basketball;
    } else if (hint.contains('debate') || hint.contains('speech')) {
      return Icons.record_voice_over;
    } else if (hint.contains('music') || hint.contains('band') || hint.contains('choir')) {
      return Icons.music_note;
    } else if (hint.contains('art') || hint.contains('paint') || hint.contains('draw')) {
      return Icons.palette;
    } else if (hint.contains('science') || hint.contains('lab')) {
      return Icons.science;
    } else if (hint.contains('drama') || hint.contains('theatre')) {
      return Icons.theater_comedy;
    } else if (hint.contains('chess')) {
      return Icons.grid_on;
    } else if (hint.contains('robot')) {
      return Icons.precision_manufacturing;
    } else if (hint.contains('environment') || hint.contains('eco')) {
      return Icons.eco;
    }
    return Icons.groups_outlined;
  }
}
