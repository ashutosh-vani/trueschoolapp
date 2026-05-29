import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/profile/data/models/profile_data.dart';

class ProfileHeaderCard extends StatelessWidget {
  final ProfileHeader header;

  const ProfileHeaderCard({super.key, required this.header});

  @override
  Widget build(BuildContext context) {
    final initial =
        header.name.isNotEmpty ? header.name[0].toUpperCase() : '?';

    // "Class Grade 6-A · Roll No. 001"
    final classInfo = [
      if (header.classLabel.isNotEmpty) 'Class ${header.classLabel}',
      if (header.rollNo.isNotEmpty) 'Roll No. ${header.rollNo}',
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.greetingGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        children: [
          // ── Avatar circle ──────────────────────────────────────────────
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 2.5,
              ),
            ),
            child: ClipOval(
              child: header.avatarUrl != null && header.avatarUrl!.isNotEmpty
                  ? Image.network(
                      header.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => _initialWidget(initial),
                    )
                  : _initialWidget(initial),
            ),
          ),

          const SizedBox(height: 18),

          // ── Name ───────────────────────────────────────────────────────
          Text(
            header.name.isNotEmpty ? header.name : '—',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 6),

          // ── Class · Roll ───────────────────────────────────────────────
          if (classInfo.isNotEmpty)
            Text(
              classInfo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),

          const SizedBox(height: 10),

          // ── School row ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined,
                size: 15,
                color: Colors.white.withValues(alpha: 0.65),
              ),
              const SizedBox(width: 6),
              Text(
                header.schoolName.isNotEmpty ? header.schoolName : '—',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),

          // ── Bio ────────────────────────────────────────────────────────
          const SizedBox(height: 14),
          Text(
            header.bio,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialWidget(String initial) {
    return Container(
      color: Colors.white.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
