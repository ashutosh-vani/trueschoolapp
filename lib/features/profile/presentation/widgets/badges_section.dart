import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';

class BadgesSection extends StatelessWidget {
  const BadgesSection({super.key});

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
          const Row(
            children: [
              Icon(Icons.emoji_events_outlined, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Badges & Awards',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildBadge(
                icon: Icons.local_fire_department,
                color: const Color(0xFFFF5722),
                bgColor: const Color(0xFFFBE9E7),
                title: 'Streak Master',
                date: 'Mar 12',
              ),
              const SizedBox(width: 16),
              _buildBadge(
                icon: Icons.star,
                color: const Color(0xFFFFC107),
                bgColor: const Color(0xFFFFF8E1),
                title: 'Excellence',
                date: 'Feb 28',
              ),
              const SizedBox(width: 16),
              _buildBadge(
                icon: Icons.sports_soccer,
                color: const Color(0xFF2196F3),
                bgColor: const Color(0xFFE3F2FD),
                title: 'Sportsmanship',
                date: 'Jan 15',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String date,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          date,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
