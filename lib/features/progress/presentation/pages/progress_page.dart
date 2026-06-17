import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/auth/data/services/token_storage.dart';
import 'package:trueschoolapp/features/progress/data/models/learning_gap_models.dart';
import 'package:trueschoolapp/features/progress/data/services/learning_gap_service.dart';
import 'package:trueschoolapp/features/progress/presentation/pages/learning_gaps_list_page.dart';
import 'package:trueschoolapp/features/progress/presentation/pages/quiz_selector_page.dart';

class ProgressPage extends StatefulWidget {
  /// Called when the back arrow is tapped.
  /// If null, falls back to [Navigator.maybePop].
  final VoidCallback? onBack;

  const ProgressPage({super.key, this.onBack});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  GapHealth _health = GapHealth.fallback;
  bool _loading = true;
  String _userInitial = '';

  @override
  void initState() {
    super.initState();
    _load();
    _loadUserInitial();
  }

  Future<void> _loadUserInitial() async {
    final name = await TokenStorage.getName();
    if (mounted && name != null && name.isNotEmpty) {
      setState(() => _userInitial = name.trim()[0].toUpperCase());
    }
  }

  Future<void> _load() async {
    final health = await LearningGapService.getHealth();
    if (!mounted) return;
    setState(() {
      _health = health;
      _loading = false;
    });
  }

  void _goBack(BuildContext context) {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.maybePop(context);
    }
  }

  void _openLearningGaps() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LearningGapsListPage()),
    );
  }

  void _openQuizSelector() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuizSelectorPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildHeroBanner(),
                      const SizedBox(height: 24),
                      _buildLearningGapsCard(),
                      const SizedBox(height: 20),
                      _buildQuizzesCard(),
                      const SizedBox(height: 24),
                      _buildCommunitySection(),
                      const SizedBox(height: 20),
                      _buildPoweredBy(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'REMEDIATION HUB',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Close Your\nLearning Gaps',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Identify your weak spots and master new concepts with targeted practice and instant feedback.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningGapsCard() {
    final criticalCount = _loading ? 0 : _health.severity.critical;
    final healthScore = _loading ? 100 : _health.score;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.trending_up,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'My Learning Gaps',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'View detailed analysis of your academic weak spots and fix them. Based on your recent quiz performance and homework.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            _buildLoadingBadge()
          else ...[
            _buildAlertBadge(
              icon: Icons.error_outline,
              text: '$criticalCount Critical gap${criticalCount == 1 ? '' : 's'} identified',
              color: AppColors.error,
            ),
            const SizedBox(height: 10),
            _buildAlertBadge(
              icon: Icons.shield_outlined,
              text: 'Health Score: $healthScore%',
              color: AppColors.textPrimary,
            ),
          ],
          const SizedBox(height: 20),
          _buildPrimaryButton('View My Gaps', _openLearningGaps),
        ],
      ),
    );
  }

  Widget _buildLoadingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Loading data...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizzesCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.quiz_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Self-Assessment\nQuizzes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Take unlimited practice tests to strengthen your concepts. Choose by subject, topic, or difficulty level.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, size: 16, color: AppColors.success),
                const SizedBox(width: 6),
                const Text(
                  'New quizzes available',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildPrimaryButton('Take a Quiz', _openQuizSelector),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAvatar(const Color(0xFFE8B5CE)),
              _buildAvatar(const Color(0xFFB5D8E8)),
              _buildAvatar(const Color(0xFFD4E8B5)),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '+12k',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Join 12,000+ students mastering their courses today.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Color color) {
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }

  Widget _buildPoweredBy() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text(
            'POWERED BY LUMITUTOR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
