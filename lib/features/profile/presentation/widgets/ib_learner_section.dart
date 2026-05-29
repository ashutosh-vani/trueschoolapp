import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/profile/data/models/profile_data.dart';

class IbLearnerSection extends StatelessWidget {
  final List<IbTrait> traits;

  const IbLearnerSection({super.key, required this.traits});

  @override
  Widget build(BuildContext context) {
    if (traits.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section heading ────────────────────────────────────────────
          const Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 22,
                color: AppColors.textPrimary,
              ),
              SizedBox(width: 8),
              Text(
                'IB Learner Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Trait cards ────────────────────────────────────────────────
          ...List.generate(traits.length, (i) {
            return Padding(
              padding: EdgeInsets.only(bottom: i < traits.length - 1 ? 12 : 0),
              child: _TraitCard(trait: traits[i]),
            );
          }),
        ],
      ),
    );
  }
}

class _TraitCard extends StatelessWidget {
  final IbTrait trait;
  const _TraitCard({required this.trait});

  @override
  Widget build(BuildContext context) {
    final style = _styleForTrait(trait.title);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          // ── Icon  +  Evidence badge ────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon box
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: style.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(style.icon, color: style.color, size: 24),
              ),

              const Spacer(),

              // Evidence — plain colored text, no background box
              Text(
                '${trait.evidenceCount} Evidence',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: style.color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Trait name ─────────────────────────────────────────────────
          Text(
            trait.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 14),

          // ── Progress bar + % ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: trait.progress,
                    minHeight: 7,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(style.color),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 40,
                child: Text(
                  '${(trait.progress * 100).toInt()}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: style.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _TraitStyle _styleForTrait(String title) {
    switch (title.toLowerCase()) {
      case 'principled':
        return _TraitStyle(
          icon: Icons.balance,
          bgColor: const Color(0xFFE6F4EA),
          color: const Color(0xFF2E7D32),
        );
      case 'balanced':
        return _TraitStyle(
          icon: Icons.self_improvement,
          bgColor: const Color(0xFFFFF3E0),
          color: const Color(0xFFE65100),
        );
      case 'thinker':
        return _TraitStyle(
          icon: Icons.lightbulb_outline,
          bgColor: const Color(0xFFEEF2FF),
          color: AppColors.primary,
        );
      case 'caring':
        return _TraitStyle(
          icon: Icons.favorite_outline,
          bgColor: const Color(0xFFFCE4EC),
          color: const Color(0xFFE53935),
        );
      case 'inquirer':
        return _TraitStyle(
          icon: Icons.search,
          bgColor: const Color(0xFFE8EAF6),
          color: const Color(0xFF3949AB),
        );
      case 'knowledgeable':
        return _TraitStyle(
          icon: Icons.menu_book_outlined,
          bgColor: const Color(0xFFF3E5F5),
          color: const Color(0xFF7B1FA2),
        );
      case 'communicator':
        return _TraitStyle(
          icon: Icons.chat_bubble_outline,
          bgColor: const Color(0xFFE0F7FA),
          color: const Color(0xFF00838F),
        );
      case 'open-minded':
        return _TraitStyle(
          icon: Icons.public,
          bgColor: const Color(0xFFFFF8E1),
          color: const Color(0xFFF9A825),
        );
      case 'risk-taker':
        return _TraitStyle(
          icon: Icons.rocket_launch_outlined,
          bgColor: const Color(0xFFFFEBEE),
          color: const Color(0xFFB71C1C),
        );
      case 'reflective':
        return _TraitStyle(
          icon: Icons.self_improvement,
          bgColor: const Color(0xFFE8F5E9),
          color: const Color(0xFF388E3C),
        );
      default:
        return _TraitStyle(
          icon: Icons.star_outline,
          bgColor: const Color(0xFFEEF2FF),
          color: AppColors.primary,
        );
    }
  }
}

class _TraitStyle {
  final IconData icon;
  final Color bgColor;
  final Color color;
  const _TraitStyle(
      {required this.icon, required this.bgColor, required this.color});
}
