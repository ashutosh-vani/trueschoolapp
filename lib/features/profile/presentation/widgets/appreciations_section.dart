import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/profile/data/models/profile_data.dart';

class AppreciationsSection extends StatelessWidget {
  final List<AppreciationItem> appreciations;

  const AppreciationsSection({super.key, required this.appreciations});

  @override
  Widget build(BuildContext context) {
    if (appreciations.isEmpty) return const SizedBox.shrink();

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
                Icons.chat_rounded,
                size: 20,
                color: Color(0xFFE53935),
              ),
              SizedBox(width: 8),
              Text(
                'Appreciations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Appreciation items ─────────────────────────────────────────
          ...List.generate(appreciations.length, (i) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: i < appreciations.length - 1 ? 16 : 0),
              child: _buildItem(appreciations[i]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildItem(AppreciationItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar box
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            size: 22,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name · role · date row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    item.from,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (item.role.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      item.role,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (item.date.isNotEmpty)
                    Text(
                      item.date,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),

              // Message
              if (item.message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '"${item.message}"',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                    height: 1.55,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
