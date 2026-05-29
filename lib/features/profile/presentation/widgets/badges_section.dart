import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/profile/data/models/profile_data.dart';

class BadgesSection extends StatelessWidget {
  final List<BadgeItem> badges;

  const BadgesSection({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();

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
                Icons.emoji_events_outlined,
                size: 22,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Text(
                'Badges & Awards',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Badge row — evenly spaced ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ...List.generate(badges.length, (i) {
                final b = badges[i];
                final style = _styleForBadge(b.iconName, b.title, b.colorHex);
                return Padding(
                  padding: EdgeInsets.only(right: i < badges.length - 1 ? 24 : 0),
                  child: _buildBadge(
                    icon: style.icon,
                    color: style.color,
                    bgColor: style.bgColor,
                    title: b.title,
                    date: b.date,
                  ),
                );
              }),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 3),
        Text(
          date,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  _BadgeStyle _styleForBadge(String? iconName, String title, String? colorHex) {
    final hint = (iconName ?? title).toLowerCase();

    Color? customColor;
    if (colorHex != null && colorHex.isNotEmpty) {
      try {
        final hex = colorHex.replaceAll('#', '');
        customColor = Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }

    if (hint.contains('streak') || hint.contains('fire')) {
      final c = customColor ?? const Color(0xFFFF5722);
      return _BadgeStyle(
          icon: Icons.local_fire_department,
          color: c,
          bgColor: const Color(0xFFFBE9E7));
    } else if (hint.contains('excellence') || hint.contains('star')) {
      final c = customColor ?? const Color(0xFFFFC107);
      return _BadgeStyle(
          icon: Icons.star_rounded,
          color: c,
          bgColor: const Color(0xFFFFF8E1));
    } else if (hint.contains('sport') || hint.contains('soccer') ||
        hint.contains('cricket') || hint.contains('athletic') ||
        hint.contains('sportsmanship')) {
      final c = customColor ?? const Color(0xFF42A5F5);
      return _BadgeStyle(
          icon: Icons.sports_soccer,
          color: c,
          bgColor: const Color(0xFFE3F2FD));
    } else if (hint.contains('leader') || hint.contains('captain')) {
      final c = customColor ?? const Color(0xFF9C27B0);
      return _BadgeStyle(
          icon: Icons.military_tech,
          color: c,
          bgColor: const Color(0xFFF3E5F5));
    } else if (hint.contains('creative') || hint.contains('art')) {
      final c = customColor ?? const Color(0xFFE91E63);
      return _BadgeStyle(
          icon: Icons.palette,
          color: c,
          bgColor: const Color(0xFFFCE4EC));
    } else if (hint.contains('science') || hint.contains('research')) {
      final c = customColor ?? const Color(0xFF00BCD4);
      return _BadgeStyle(
          icon: Icons.science,
          color: c,
          bgColor: const Color(0xFFE0F7FA));
    }

    final c = customColor ?? AppColors.primary;
    return _BadgeStyle(
        icon: Icons.emoji_events,
        color: c,
        bgColor: c.withValues(alpha: 0.12));
  }
}

class _BadgeStyle {
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _BadgeStyle(
      {required this.icon, required this.color, required this.bgColor});
}
