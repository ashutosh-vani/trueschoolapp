import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/career/data/models/career_domain.dart';
import 'package:trueschoolapp/features/career/data/services/career_service.dart';
import 'package:trueschoolapp/features/career/presentation/pages/career_detail_page.dart';

// Cycling gradient pairs for career cards (matching web CARD_GRADIENTS)
const List<List<Color>> _cardGradients = [
  [Color(0xFF695BE6), Color(0xFF8E82F3)],
  [Color(0xFF2563EB), Color(0xFF4338CA)],
  [Color(0xFF059669), Color(0xFF0F766E)],
  [Color(0xFFD97706), Color(0xFFEA580C)],
  [Color(0xFFE11D48), Color(0xFFDB2777)],
  [Color(0xFF475569), Color(0xFF1E293B)],
];

class CareerListPage extends StatefulWidget {
  final CareerDomain domain;

  const CareerListPage({super.key, required this.domain});

  @override
  State<CareerListPage> createState() => _CareerListPageState();
}

class _CareerListPageState extends State<CareerListPage> {
  List<Career> _careers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCareers();
  }

  Future<void> _loadCareers() async {
    final careers =
        await CareerService.getCareersForDomain(widget.domain.id);
    setState(() {
      _careers = careers;
      _isLoading = false;
    });
  }

  // Extract the first word of the domain name for the page title
  String get _domainFirstWord {
    final parts = widget.domain.name.split(' ');
    return parts.isNotEmpty ? parts.first : widget.domain.name;
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

  // ── App bar (matches CareerExplorerPage style) ─────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.explore_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          const Text(
            'CareerPath AI',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          // Bell
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: const Icon(Icons.notifications_outlined,
                color: AppColors.textPrimary, size: 19),
          ),
          const SizedBox(width: 10),
          // Home button
          GestureDetector(
            onTap: () {
              // Pop back to explorer, then pop again to dashboard
              int count = 0;
              Navigator.of(context).popUntil((_) => count++ >= 2);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: const Icon(Icons.home_outlined,
                  color: AppColors.textPrimary, size: 19),
            ),
          ),
        ],
      ),
    );
  }

  // ── Main scrollable content ────────────────────────────────────────────
  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumb
                _buildBreadcrumb(),
                const SizedBox(height: 20),
                // Title
                Text(
                  'Career Categories\n— $_domainFirstWord',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                // Description
                Text(
                  widget.domain.description,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),

          // Careers section
          if (_careers.isEmpty)
            _buildEmptyState()
          else
            _buildCareersSection(),

          const SizedBox(height: 40),
          _buildFooter(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'All Categories',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right,
            size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            widget.domain.name,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Careers section with row title + horizontal scroll ─────────────────
  Widget _buildCareersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Careers in this field',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Horizontal scrollable career cards
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _careers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _buildCareerCard(_careers[index], index);
            },
          ),
        ),
      ],
    );
  }

  // ── Individual career card (gradient + badge overlay) ──────────────────
  Widget _buildCareerCard(Career career, int index) {
    final gradient = _cardGradients[index % _cardGradients.length];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CareerDetailPage(
            career: career,
            domainColors: widget.domain.gradientColors,
            domainName: widget.domain.name,
          ),
        ),
      ),
      child: SizedBox(
        width: 260,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Gradient background
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.work_outline,
                    color: Colors.white.withValues(alpha: 0.15),
                    size: 90,
                  ),
                ),
              ),

              // Bottom fade overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 130,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.75),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Badge (top-left)
              Positioned(
                top: 14,
                left: 14,
                child: _buildBadge(career),
              ),

              // Title & subtitle (bottom)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      career.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    if (career.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        career.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Badge chip on career card ──────────────────────────────────────────
  Widget _buildBadge(Career career) {
    // Pick badge text and color based on available data
    String label;
    Color bgColor;

    if (career.salary != null && career.salary!.isNotEmpty) {
      label = 'TOP PAYING';
      bgColor = const Color(0xFFF59E0B);
    } else if (career.education != null &&
        career.education!.toLowerCase().contains('phd')) {
      label = 'RESEARCH';
      bgColor = const Color(0xFF8B5CF6);
    } else if (career.skills.length >= 5) {
      label = 'HIGH DEMAND';
      bgColor = AppColors.primary;
    } else {
      label = 'PRESTIGIOUS';
      bgColor = const Color(0xFF10B981);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.work_off_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'Career details for this domain\nare coming soon.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Back to Explorer',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.explore_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              const Text(
                'CareerPath AI',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '© 2026 CareerPath AI. All rights reserved.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
