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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Back arrow
          GestureDetector(
            onTap: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.maybePop(context);
              }
            },
            child: const Icon(Icons.arrow_back,
                size: 22, color: AppColors.textPrimary),
          ),

          const SizedBox(width: 10),

          // Book icon pill — "My Portfolio"
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book_rounded,
                    size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'My Portfolio',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Edit Profile
          GestureDetector(
            onTap: _openEditProfile,
            child: const Row(
              children: [
                Icon(Icons.edit_outlined,
                    size: 15, color: AppColors.textPrimary),
                SizedBox(width: 4),
                Text(
                  'Edit\nProfile',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Share Portfolio pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.share_rounded, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Share\nPortfolio',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.25,
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
