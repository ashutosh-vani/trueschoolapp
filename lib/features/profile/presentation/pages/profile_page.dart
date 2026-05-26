import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/profile/presentation/widgets/profile_header_card.dart';
import 'package:trueschoolapp/features/profile/presentation/widgets/ib_learner_section.dart';
import 'package:trueschoolapp/features/profile/presentation/widgets/academic_progress_section.dart';
import 'package:trueschoolapp/features/profile/presentation/widgets/projects_section.dart';
import 'package:trueschoolapp/features/profile/presentation/widgets/extracurricular_section.dart';
import 'package:trueschoolapp/features/profile/presentation/widgets/badges_section.dart';
import 'package:trueschoolapp/features/profile/presentation/widgets/appreciations_section.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: const [
                    SizedBox(height: 16),
                    ProfileHeaderCard(),
                    SizedBox(height: 24),
                    IbLearnerSection(),
                    SizedBox(height: 24),
                    AcademicProgressSection(),
                    SizedBox(height: 24),
                    ProjectsSection(),
                    SizedBox(height: 24),
                    ExtracurricularSection(),
                    SizedBox(height: 24),
                    BadgesSection(),
                    SizedBox(height: 24),
                    AppreciationsSection(),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book, size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'M...',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {},
            child: const Row(
              children: [
                Icon(Icons.edit_outlined, size: 16, color: AppColors.textPrimary),
                SizedBox(width: 4),
                Text(
                  'Edit\nProfile',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.share, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Share\nPortfolio',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
