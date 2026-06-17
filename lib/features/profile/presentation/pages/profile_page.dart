import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/profile/data/models/profile_data.dart';
import 'package:trueschoolapp/features/profile/data/services/profile_service.dart';
import 'package:trueschoolapp/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:trueschoolapp/features/profile/presentation/widgets/profile_header_card.dart';
import 'package:trueschoolapp/features/profile/presentation/widgets/ib_learner_section.dart';
import 'package:trueschoolapp/features/profile/presentation/widgets/academic_progress_section.dart';
import 'package:trueschoolapp/features/profile/presentation/widgets/projects_section.dart';
import 'package:trueschoolapp/features/profile/presentation/widgets/extracurricular_section.dart';
import 'package:trueschoolapp/features/profile/presentation/widgets/badges_section.dart';
import 'package:trueschoolapp/features/profile/presentation/widgets/appreciations_section.dart';
import 'package:trueschoolapp/shared/widgets/skeleton.dart';

class ProfilePage extends StatefulWidget {
  /// Called when the back arrow is tapped.
  /// If null, falls back to [Navigator.maybePop].
  final VoidCallback? onBack;

  const ProfilePage({super.key, this.onBack});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ProfileData? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final data = await ProfileService.getProfile();
    if (!mounted) return;
    setState(() {
      _profile = data;
      _isLoading = false;
    });
  }

  Future<void> _openEditProfile() async {
    final header = _profile?.header;
    if (header == null) return;

    final updated = await showEditProfileDialog(context, header);

    if (updated == true) {
      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) {
      return const ProfilePageSkeleton();
    }

    final profile = _profile;
    if (profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              const Text(
                'Could not load profile. Please try again.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 15, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: _loadProfile, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Header card
            ProfileHeaderCard(header: profile.header),

            // IB Learner Profile
            if (profile.ibTraits.isNotEmpty) ...[
              const SizedBox(height: 20),
              IbLearnerSection(traits: profile.ibTraits),
            ],

            // Academic Progress
            if (profile.academicProgress.subjects.isNotEmpty) ...[
              const SizedBox(height: 16),
              AcademicProgressSection(progress: profile.academicProgress),
            ],

            // Projects
            if (profile.projects.isNotEmpty) ...[
              const SizedBox(height: 16),
              ProjectsSection(projects: profile.projects),
            ],

            // Extracurricular
            if (profile.extracurriculars.isNotEmpty) ...[
              const SizedBox(height: 16),
              ExtracurricularSection(activities: profile.extracurriculars),
            ],

            // Badges & Awards
            if (profile.badges.isNotEmpty) ...[
              const SizedBox(height: 16),
              BadgesSection(badges: profile.badges),
            ],

            // Appreciations
            if (profile.appreciations.isNotEmpty) ...[
              const SizedBox(height: 16),
              AppreciationsSection(appreciations: profile.appreciations),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Logo icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'My Portfolio',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const Spacer(),

          // Edit Profile
          GestureDetector(
            onTap: _openEditProfile,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined,
                      size: 15, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Share Portfolio
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.share_rounded, size: 15, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Share',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
