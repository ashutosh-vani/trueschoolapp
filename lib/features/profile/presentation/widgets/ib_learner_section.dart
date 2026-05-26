import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';

class IbLearnerSection extends StatelessWidget {
  const IbLearnerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.public, size: 20, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text(
                'IB Learner Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTraitCard(
            icon: Icons.account_balance,
            iconBgColor: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF2E7D32),
            title: 'Principled',
            evidence: 12,
            progress: 0.85,
            progressColor: AppColors.success,
          ),
          const SizedBox(height: 12),
          _buildTraitCard(
            icon: Icons.balance,
            iconBgColor: const Color(0xFFFFF3E0),
            iconColor: const Color(0xFFE65100),
            title: 'Balanced',
            evidence: 8,
            progress: 0.70,
            progressColor: const Color(0xFFFF9800),
          ),
          const SizedBox(height: 12),
          _buildTraitCard(
            icon: Icons.lightbulb_outline,
            iconBgColor: const Color(0xFFE3F2FD),
            iconColor: AppColors.primary,
            title: 'Thinker',
            evidence: 15,
            progress: 0.95,
            progressColor: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _buildTraitCard(
            icon: Icons.favorite_outline,
            iconBgColor: const Color(0xFFFCE4EC),
            iconColor: const Color(0xFFC62828),
            title: 'Caring',
            evidence: 10,
            progress: 0.90,
            progressColor: const Color(0xFFC62828),
          ),
        ],
      ),
    );
  }

  Widget _buildTraitCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required int evidence,
    required double progress,
    required Color progressColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$evidence Evidence',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: progressColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: progressColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
