import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/learning_gaps/data/learning_gap_fallback.dart';
import 'package:trueschoolapp/features/learning_gaps/data/models/learning_gap_model.dart';
import 'package:trueschoolapp/features/learning_gaps/data/services/learning_gap_service.dart';
import 'package:trueschoolapp/features/learning_gaps/presentation/pages/gap_remediation_page.dart';
import 'package:trueschoolapp/features/ai_tutor/presentation/pages/ai_tutor_page.dart';

// ── Severity config ────────────────────────────────────────────────────────────
const _kSeverityLabel = {
  'critical': 'Critical',
  'moderate': 'Moderate',
  'minor': 'Minor',
};
const _kSeverityBorderColor = {
  'critical': Color(0xFFEC5B13),
  'moderate': Colors.orange,
  'minor': Colors.grey,
};
const _kSeverityBadgeBg = {
  'critical': Color(0xFFFEE2E2),
  'moderate': Color(0xFFFFF7ED),
  'minor': Color(0xFFF1F5F9),
};
const _kSeverityBadgeFg = {
  'critical': Color(0xFF991B1B),
  'moderate': Color(0xFFD97706),
  'minor': Color(0xFF475569),
};
const _kSeverityActionLabel = {
  'critical': 'Start Fixing This Gap',
  'moderate': 'Retry Concept',
  'minor': 'Quick Review',
};
const _kSubjectColor = {
  'Math': Color(0xFFF3F0FF),
  'Physics': Color(0xFFEFF6FF),
  'Chemistry': Color(0xFFECFDF5),
  'Biology': Color(0xFFECFEFF),
  'History': Color(0xFFFFFBEB),
};
const _kSubjectFg = {
  'Math': Color(0xFF7C3AED),
  'Physics': Color(0xFF1D4ED8),
  'Chemistry': Color(0xFF065F46),
  'Biology': Color(0xFF0F766E),
  'History': Color(0xFFB45309),
};

const _kSubjects = ['All', 'Math', 'Physics', 'Chemistry', 'Biology', 'History'];

class LearningGapsPage extends StatefulWidget {
  const LearningGapsPage({super.key});

  @override
  State<LearningGapsPage> createState() => _LearningGapsPageState();
}

class _LearningGapsPageState extends State<LearningGapsPage> {
  bool _isLoading = true;
  List<LearningGap> _gaps = [];
  GapHealth? _health;
  String _activeSubject = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
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
      _isLoading = false;
    });
  }

  List<LearningGap> get _filteredGaps =>
      _activeSubject == 'All' ? _gaps : _gaps.where((g) => g.subject == _activeSubject).toList();

  @override
  Widget build(BuildContext context) {
    final h = _health;
    final sevCounts = h?.severity ??
        GapSeverityCounts(
          critical: _gaps.where((g) => g.severity == 'critical').length,
          moderate: _gaps.where((g) => g.severity == 'moderate').length,
          minor: _gaps.where((g) => g.severity == 'minor').length,
        );
    final total = (sevCounts.critical + sevCounts.moderate + sevCounts.minor).clamp(1, 9999);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    children: [
                      _buildOverview(h, sevCounts, total),
                      const SizedBox(height: 20),
                      _buildFilters(),
                      const SizedBox(height: 20),
                      ..._buildGapCards(context),
                      const SizedBox(height: 20),
                      _buildVinCta(context),
                      const SizedBox(height: 32),
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
            'Learning Gap Management',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(GapHealth? h, GapSeverityCounts sevCounts, int total) {
    final score = h?.score ?? 0;
    final critPct = sevCounts.critical / total;
    final modPct = sevCounts.moderate / total;
    final minPct = sevCounts.minor / total;

    return Column(
      children: [
        // Health ring + stats
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Health ring
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Text('Gap Health Score',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: score / 100.0,
                            strokeWidth: 8,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(Color(0xFFEC5B13)),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$score',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary)),
                              Text('/${h?.maxScore ?? 100}',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (h != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.trending_up, size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(h.trend,
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        h.improvementMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Stats column
            Expanded(
              child: Column(
                children: [
                  _StatCard(
                    icon: Icons.warning_amber_rounded,
                    iconColor: const Color(0xFFEC5B13),
                    iconBg: const Color(0xFFFFF3EF),
                    label: 'Total Gaps',
                    value: '${h?.totalGaps ?? _gaps.length}',
                    trend: h?.totalGapsTrend ?? '',
                    trendColor: Colors.red.shade600,
                  ),
                  const SizedBox(height: 10),
                  _StatCard(
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.green.shade700,
                    iconBg: Colors.green.shade50,
                    label: 'Resolved',
                    value: '${h?.resolvedGaps ?? 0}',
                    trend: h?.resolvedGapsTrend ?? '',
                    trendColor: AppColors.success,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Severity breakdown bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Severity Breakdown',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      Expanded(flex: (critPct * 100).round(), child: Container(color: const Color(0xFFEC5B13))),
                      Expanded(flex: (modPct * 100).round(), child: Container(color: Colors.orange.shade300)),
                      Expanded(flex: (minPct * 100).round(), child: Container(color: Colors.grey.shade300)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SevLegend(color: const Color(0xFFEC5B13), label: '${sevCounts.critical} Critical'),
                  _SevLegend(color: Colors.orange.shade400, label: '${sevCounts.moderate} Moderate'),
                  _SevLegend(color: Colors.grey.shade400, label: '${sevCounts.minor} Minor'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Identified Learning Gaps',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _kSubjects.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final s = _kSubjects[i];
              final isActive = _activeSubject == s;
              return GestureDetector(
                onTap: () => setState(() => _activeSubject = s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    s,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGapCards(BuildContext context) {
    final filtered = _filteredGaps;
    if (filtered.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              'No gaps found for this subject.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      ];
    }
    return filtered
        .map((gap) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _GapCard(
                gap: gap,
                onFix: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GapRemediationPage(gap: gap),
                  ),
                ),
              ),
            ))
        .toList();
  }

  Widget _buildVinCta(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEC5B13).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEC5B13).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFFEC5B13).withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.psychology, color: Color(0xFFEC5B13), size: 28),
          ),
          const SizedBox(height: 12),
          const Text('Need a customized learning plan?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text(
            'Lumi can analyze all your current gaps and create a 7-day schedule to get you back on track.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AiTutorPage(),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEC5B13),
              side: const BorderSide(color: Color(0xFFEC5B13)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Talk to Lumi Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Gap Card ───────────────────────────────────────────────────────────────────
class _GapCard extends StatelessWidget {
  final LearningGap gap;
  final VoidCallback onFix;

  const _GapCard({required this.gap, required this.onFix});

  @override
  Widget build(BuildContext context) {
    final borderColor = _kSeverityBorderColor[gap.severity] ?? Colors.grey;
    final badgeBg = _kSeverityBadgeBg[gap.severity] ?? const Color(0xFFF1F5F9);
    final badgeFg = _kSeverityBadgeFg[gap.severity] ?? Colors.grey.shade700;
    final sevLabel = _kSeverityLabel[gap.severity] ?? gap.severity;
    final actionLabel = _kSeverityActionLabel[gap.severity] ?? 'Review';
    final subjBg = _kSubjectColor[gap.subject] ?? const Color(0xFFF1F5F9);
    final subjFg = _kSubjectFg[gap.subject] ?? Colors.grey.shade700;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
          top: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject + severity badges
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: subjBg, borderRadius: BorderRadius.circular(6)),
                child: Text(gap.subject,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: subjFg)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                child: Text(sevLabel.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: badgeFg)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(gap.topic,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(gap.subtopic,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 14),

          // Meta grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _MetaItem(label: 'Identified from', value: gap.identifiedFrom.title)),
              const SizedBox(width: 12),
              Expanded(child: _MetaItem(label: 'Impact', value: gap.impactAnalysis, highlight: gap.impactSubject)),
            ],
          ),
          const SizedBox(height: 12),

          // Mastery bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MASTERY',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
              Text('${gap.masteryPercent}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: gap.masteryPercent / 100.0,
              minHeight: 7,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(borderColor),
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              ...gap.correctivePath.take(2).map((cp) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CorrBtn(icon: _iconForPath(cp.icon), label: cp.label),
                  )),
              _CorrBtn(icon: Icons.smart_toy, label: 'Ask Lumi', isVin: true),
              const Spacer(),
              ElevatedButton(
                onPressed: onFix,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC5B13),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(actionLabel,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconForPath(String icon) {
    switch (icon) {
      case 'play_circle': return Icons.play_circle_outline;
      case 'menu_book':   return Icons.menu_book_outlined;
      case 'edit_note':   return Icons.edit_note;
      default:            return Icons.open_in_new;
    }
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;
  final String? highlight;

  const _MetaItem({required this.label, required this.value, this.highlight});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _CorrBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isVin;

  const _CorrBtn({required this.icon, required this.label, this.isVin = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isVin
            ? AppColors.primary.withValues(alpha: 0.1)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: isVin ? Border.all(color: AppColors.primary.withValues(alpha: 0.2)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isVin ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isVin ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small stat card ────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String trend;
  final Color trendColor;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.trend,
    required this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Row(
                  children: [
                    Text(value,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                    if (trend.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(trend,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: trendColor)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Severity legend dot ────────────────────────────────────────────────────────
class _SevLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _SevLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
      ],
    );
  }
}
