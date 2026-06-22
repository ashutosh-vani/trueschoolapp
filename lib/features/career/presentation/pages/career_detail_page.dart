import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/ai_tutor/presentation/pages/ai_tutor_page.dart';
import 'package:trueschoolapp/features/career/data/models/career_domain.dart';
import 'package:trueschoolapp/features/career/data/services/career_service.dart';

// Skill category badge colors
const Map<String, Color> _categoryColors = {
  'Technical': Color(0xFF695BE6),
  'Analytical': Color(0xFF2563EB),
  'Soft Skill': Color(0xFF10B981),
};

class CareerDetailPage extends StatefulWidget {
  final Career career;
  final List<Color> domainColors;
  final String? domainName;

  const CareerDetailPage({
    super.key,
    required this.career,
    required this.domainColors,
    this.domainName,
  });

  @override
  State<CareerDetailPage> createState() => _CareerDetailPageState();
}

class _CareerDetailPageState extends State<CareerDetailPage> {
  late Career _career;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _career = widget.career;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final detail = await CareerService.getCareerDetail(
      _career.domainId,
      _career.id,
    );
    setState(() {
      if (detail != null) _career = detail;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Logo
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.analytics_outlined,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'CareerPath AI',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          // Dashboard button
          GestureDetector(
            onTap: () {
              int count = 0;
              Navigator.of(context).popUntil((_) => count++ >= 3);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Main scrollable content ────────────────────────────────────────────
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          _buildBreadcrumb(),
          const SizedBox(height: 20),

          // Hero banner
          _buildHeroBanner(),
          const SizedBox(height: 28),

          // What They Do
          if (_career.whatTheyDo != null &&
              _career.whatTheyDo!.isNotEmpty) ...[
            _buildSectionTitle(Icons.description_outlined, 'What They Do'),
            const SizedBox(height: 12),
            Text(
              _career.whatTheyDo!,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
          ],

          // A Day in the Life
          if (_career.dayInLife.isNotEmpty) ...[
            _buildSectionTitle(Icons.today_outlined, 'A Day in the Life'),
            const SizedBox(height: 14),
            ..._career.dayInLife.asMap().entries.map(
                  (e) => _buildDayInLifeItem(e.key + 1, e.value),
                ),
            const SizedBox(height: 28),
          ],

          // Education Path
          if (_career.educationPath.isNotEmpty) ...[
            _buildSectionTitle(Icons.school_outlined, 'Education Path'),
            const SizedBox(height: 14),
            _buildEducationPath(),
            const SizedBox(height: 28),
          ],

          // Top Colleges
          if (_career.topColleges.isNotEmpty) ...[
            _buildSectionTitle(
                Icons.account_balance_outlined, 'Top Colleges'),
            const SizedBox(height: 14),
            _buildTopColleges(),
            const SizedBox(height: 28),
          ],

          // Quick Stats
          if (_career.avgSalary != null ||
              _career.growthOutlook != null ||
              _career.jobOpenings != null ||
              _career.yearsToQualify != null) ...[
            _buildSectionTitle(null, 'Quick Stats'),
            const SizedBox(height: 14),
            _buildQuickStats(),
            const SizedBox(height: 28),
          ],

          // Key Skills (progress bars)
          if (_career.keySkills.isNotEmpty) ...[
            _buildSectionTitle(Icons.psychology_outlined, 'Key Skills'),
            const SizedBox(height: 14),
            _buildKeySkills(),
            const SizedBox(height: 28),
          ],

          // Similar Careers
          if (_career.similarCareers.isNotEmpty) ...[
            _buildSectionTitle(
                Icons.compare_arrows_outlined, 'Similar Careers'),
            const SizedBox(height: 14),
            _buildSimilarCareers(),
            const SizedBox(height: 28),
          ],

          // Lumi CTA
          _buildVinCta(),
          const SizedBox(height: 32),

          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  // ── Breadcrumb ─────────────────────────────────────────────────────────
  Widget _buildBreadcrumb() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              int count = 0;
              Navigator.of(context).popUntil((_) => count++ >= 2);
            },
            child: const Text(
              'All Categories',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right,
              size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              widget.domainName ?? _career.domain ?? 'Category',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right,
              size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            _career.title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero banner ────────────────────────────────────────────────────────
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            widget.domainColors.first,
            widget.domainColors.last.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat pills row (top-right aligned)
          if (_career.matchPercent != null ||
              _career.avgSalary != null ||
              _career.jobOpenings != null)
            Align(
              alignment: Alignment.topRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_career.matchPercent != null)
                    _heroStatPill('${_career.matchPercent}%', 'Your Match'),
                  if (_career.avgSalary != null)
                    _heroStatPill(_career.avgSalary!, 'Avg Salary'),
                  if (_career.jobOpenings != null)
                    _heroStatPill(_career.jobOpenings!, 'Job Openings'),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Domain badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _career.domain ?? widget.domainName ?? '',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Career title
          Text(
            _career.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            _career.whatTheyDo ??
                _career.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _heroStatPill(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section title with icon ────────────────────────────────────────────
  Widget _buildSectionTitle(IconData? icon, String title) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ── Day in the Life ────────────────────────────────────────────────────
  Widget _buildDayInLifeItem(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Education Path (timeline) ──────────────────────────────────────────
  Widget _buildEducationPath() {
    return Column(
      children: _career.educationPath.map((step) {
        final isDone = step.status == 'done';
        final isCurrent = step.status == 'current';

        Color circleColor;
        Color textColor;
        if (isDone) {
          circleColor = AppColors.primary;
          textColor = Colors.white;
        } else if (isCurrent) {
          circleColor = AppColors.primary.withValues(alpha: 0.15);
          textColor = AppColors.primary;
        } else {
          circleColor = const Color(0xFFF1F5F9);
          textColor = AppColors.textSecondary;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circle indicator
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: circleColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isDone
                          ? Icon(Icons.check, size: 18, color: textColor)
                          : Text(
                              '${step.step}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                    ),
                  ),
                  // Vertical line (except last)
                  if (step != _career.educationPath.last)
                    Container(
                      width: 2,
                      height: 24,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            step.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Current',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Top Colleges ───────────────────────────────────────────────────────
  Widget _buildTopColleges() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _career.topColleges.length,
      itemBuilder: (context, index) {
        final college = _career.topColleges[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      college.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${college.type} · ${college.exam}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Quick Stats ────────────────────────────────────────────────────────
  Widget _buildQuickStats() {
    final stats = <_QuickStat>[
      if (_career.avgSalary != null)
        _QuickStat(Icons.payments_outlined, 'AVG SALARY', _career.avgSalary!),
      if (_career.growthOutlook != null)
        _QuickStat(
            Icons.trending_up, 'GROWTH OUTLOOK', _career.growthOutlook!),
      if (_career.jobOpenings != null)
        _QuickStat(Icons.work_outline, 'JOB OPENINGS', _career.jobOpenings!),
      if (_career.yearsToQualify != null)
        _QuickStat(
            Icons.schedule_outlined, 'YEARS TO QUALIFY', _career.yearsToQualify!),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: stats
            .map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color:
                              AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(s.icon,
                            size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.7),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.value,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ── Key Skills (progress bars) ─────────────────────────────────────────
  Widget _buildKeySkills() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _career.keySkills.map((skill) {
          final catColor =
              _categoryColors[skill.category] ?? AppColors.primary;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              skill.skill,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              skill.category,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: catColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${skill.level}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: skill.level / 100,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Similar Careers ────────────────────────────────────────────────────
  Widget _buildSimilarCareers() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _career.similarCareers.map((sc) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    sc.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${sc.matchPercent}% match',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward,
                        size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Lumi CTA ──────────────────────────────────────────────────────────────────
  Widget _buildVinCta() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF695BE6), Color(0xFF8E82F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_outlined,
                color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ask Lumi about this career',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Get personalised advice based on your academic profile.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiTutorPage()),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Chat with Lumi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF695BE6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.analytics_outlined,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'CareerPath AI',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '© 2026 CareerPath AI. All rights reserved.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper data class for Quick Stats
class _QuickStat {
  final IconData icon;
  final String label;
  final String value;
  const _QuickStat(this.icon, this.label, this.value);
}
