import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/learning_gaps/data/learning_gap_fallback.dart';
import 'package:trueschoolapp/features/learning_gaps/data/models/learning_gap_model.dart';
import 'package:trueschoolapp/features/learning_gaps/data/services/learning_gap_service.dart';
import 'package:trueschoolapp/features/learning_gaps/presentation/pages/learning_gaps_page.dart';
import 'package:trueschoolapp/features/learning_gaps/presentation/pages/quiz_selector_page.dart';

class LearningGapHubPage extends StatefulWidget {
  const LearningGapHubPage({super.key});

  @override
  State<LearningGapHubPage> createState() => _LearningGapHubPageState();
}

class _LearningGapHubPageState extends State<LearningGapHubPage> {
  List<LearningGap> _gaps = [];
  GapHealth? _health;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      LearningGapService.getLearningGaps(),
      LearningGapService.getGapHealth(),
    ]);
    if (!mounted) return;
    final gaps = results[0] as List<LearningGap>;
    final health = results[1] as GapHealth?;
    setState(() {
      _gaps = gaps.isNotEmpty ? gaps : kFallbackGaps;
      _health = health ?? kFallbackGapHealth;
    });
  }

  @override
  Widget build(BuildContext context) {
    final criticalCount = _gaps.where((g) => g.severity == 'critical').length;
    final healthScore = _health?.score ?? 100;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildHero(),
                    const SizedBox(height: 32),
                    _buildActionCards(context, criticalCount, healthScore),
                    const SizedBox(height: 40),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          const Text(
            'Learning Gaps',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'REMEDIATION HUB',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Close Your Learning Gaps',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Identify your weak spots and master new concepts with targeted practice and instant feedback.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCards(BuildContext context, int criticalCount, int healthScore) {
    return Column(
      children: [
        // My Learning Gaps card
        _ActionCard(
          icon: Icons.insights,
          title: 'My Learning Gaps',
          description:
              'View detailed analysis of your academic weak spots and fix them. Based on your recent quiz performance and homework.',
          badges: [
            _BadgeInfo(
              icon: Icons.priority_high,
              text: '$criticalCount Critical gaps identified',
              color: Colors.red.shade700,
              bg: Colors.red.shade50,
            ),
            _BadgeInfo(
              icon: Icons.health_and_safety,
              text: 'Health Score: $healthScore%',
              color: AppColors.primary,
              bg: AppColors.primary.withValues(alpha: 0.1),
            ),
          ],
          buttonText: 'View My Gaps',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LearningGapsPage()),
          ),
        ),
        const SizedBox(height: 20),
        // Self-Assessment Quizzes card
        _ActionCard(
          icon: Icons.quiz,
          title: 'Self-Assessment Quizzes',
          description:
              'Take unlimited practice tests to strengthen your concepts. Choose by subject, topic, or difficulty level.',
          badges: [
            _BadgeInfo(
              icon: Icons.bolt,
              text: 'New quizzes available',
              color: Colors.green.shade700,
              bg: Colors.green.shade50,
            ),
          ],
          buttonText: 'Take a Quiz',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuizSelectorPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...['bg-purple', 'bg-blue', 'bg-green'].map((c) => Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: -6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.contains('purple')
                        ? Colors.purple.shade200
                        : c.contains('blue')
                            ? Colors.blue.shade200
                            : Colors.green.shade200,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                )),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.2),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '+12k',
                  style: TextStyle(
                    fontSize: 6,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Join 12,000+ students mastering their courses today.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 16, color: AppColors.primary.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Text(
              'POWERED BY TRUESCHOOLAI',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────
class _BadgeInfo {
  final IconData icon;
  final String text;
  final Color color;
  final Color bg;
  _BadgeInfo({required this.icon, required this.text, required this.color, required this.bg});
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<_BadgeInfo> badges;
  final String buttonText;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.badges,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(description,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 16),
          ...badges.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: b.bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(b.icon, size: 14, color: b.color),
                      const SizedBox(width: 6),
                      Text(b.text,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: b.color)),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
