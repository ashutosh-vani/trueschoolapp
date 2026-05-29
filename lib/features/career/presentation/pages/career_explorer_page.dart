import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/career/data/models/career_domain.dart';
import 'package:trueschoolapp/features/career/data/services/career_service.dart';
import 'package:trueschoolapp/features/career/presentation/pages/career_list_page.dart';

class CareerExplorerPage extends StatefulWidget {
  const CareerExplorerPage({super.key});

  @override
  State<CareerExplorerPage> createState() => _CareerExplorerPageState();
}

class _CareerExplorerPageState extends State<CareerExplorerPage> {
  List<CareerDomain> _domains = [];
  bool _isLoading = true;

  // ── Canonical domain list ────────────────────────────────────────────────
  // These are ALWAYS shown. When the API returns matching domains we only
  // borrow the real `id` so that navigation to the backend works correctly.
  // Everything visual (name, description, icon, gradient) stays hardcoded.
  static final List<CareerDomain> _canonical = [
    const CareerDomain(
      id: 'tech',
      name: 'Technology & Engineering',
      description:
          'Shaping the future through code, robotics, and complex systems.',
      icon: Icons.developer_board_outlined,
      gradientColors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
    ),
    const CareerDomain(
      id: 'medical',
      name: 'Medical & Health',
      description:
          'Dedicated to healing, wellness, and medical breakthroughs.',
      icon: Icons.medical_services_outlined,
      gradientColors: [Color(0xFF10B981), Color(0xFF34D399)],
    ),
    const CareerDomain(
      id: 'government',
      name: 'Government & Defence',
      description:
          'Serving the nation and ensuring global security and stability.',
      icon: Icons.account_balance_outlined,
      gradientColors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
    ),
    const CareerDomain(
      id: 'business',
      name: 'Business & Finance',
      description:
          'Driving the global economy and strategic corporate growth.',
      icon: Icons.account_balance_wallet_outlined,
      gradientColors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    ),
    const CareerDomain(
      id: 'law',
      name: 'Law & Policy',
      description:
          'Upholding justice and shaping the regulations of society.',
      icon: Icons.gavel_outlined,
      gradientColors: [Color(0xFF475569), Color(0xFF64748B)],
    ),
    const CareerDomain(
      id: 'education',
      name: 'Education & Research',
      description:
          'Cultivating knowledge and leading scientific innovation.',
      icon: Icons.school_outlined,
      gradientColors: [Color(0xFFEC4899), Color(0xFFF472B6)],
    ),
    const CareerDomain(
      id: 'arts',
      name: 'Arts, Media & Design',
      description:
          'Expressing creativity through visual and digital stories.',
      icon: Icons.palette_outlined,
      gradientColors: [Color(0xFFA855F7), Color(0xFFC084FC)],
    ),
    const CareerDomain(
      id: 'social',
      name: 'Social & Environment',
      description:
          'Building communities and protecting our planet for future generations.',
      icon: Icons.eco_outlined,
      gradientColors: [Color(0xFF059669), Color(0xFF10B981)],
    ),
    const CareerDomain(
      id: 'infrastructure',
      name: 'Infrastructure & Travel',
      description:
          'Designing cities, transport systems, and connecting the world.',
      icon: Icons.location_city_outlined,
      gradientColors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
    ),
    const CareerDomain(
      id: 'sports',
      name: 'Sports & Events',
      description:
          'Managing high-level competition and global entertainment.',
      icon: Icons.sports_soccer_outlined,
      gradientColors: [Color(0xFFEF4444), Color(0xFFF87171)],
    ),
  ];

  // Keywords used to match an API domain to a canonical entry
  static const Map<String, List<String>> _idKeywords = {
    'tech':           ['tech', 'engineering', 'software', 'it'],
    'medical':        ['medical', 'health', 'medicine', 'pharma'],
    'government':     ['government', 'defence', 'defense', 'public'],
    'business':       ['business', 'finance', 'commerce', 'economics'],
    'law':            ['law', 'legal', 'policy', 'justice'],
    'education':      ['education', 'research', 'academic', 'science'],
    'arts':           ['arts', 'media', 'design', 'creative'],
    'social':         ['social', 'environment', 'sustainability', 'ngo'],
    'infrastructure': ['infrastructure', 'travel', 'transport', 'civil'],
    'sports':         ['sports', 'events', 'fitness', 'recreation'],
  };

  @override
  void initState() {
    super.initState();
    _loadDomains();
  }

  Future<void> _loadDomains() async {
    final apiDomains = await CareerService.getDomains();

    if (apiDomains.isEmpty) {
      // No API data — show canonical list as-is
      setState(() {
        _domains = _canonical;
        _isLoading = false;
      });
      return;
    }

    // Try to match each canonical entry to a real API domain by keyword.
    // If matched, replace only the `id` so navigation hits the real backend.
    final merged = _canonical.map((canon) {
      final keywords = _idKeywords[canon.id] ?? [canon.id];
      final match = _findApiMatch(apiDomains, keywords);
      if (match != null) {
        return CareerDomain(
          id: match.id,           // real backend id
          name: canon.name,       // always use canonical name
          description: canon.description,
          icon: canon.icon,
          gradientColors: canon.gradientColors,
        );
      }
      return canon; // no match — keep canonical with fallback id
    }).toList();

    setState(() {
      _domains = merged;
      _isLoading = false;
    });
  }

  /// Find the first API domain whose id or name contains any of [keywords].
  static CareerDomain? _findApiMatch(
      List<CareerDomain> apiDomains, List<String> keywords) {
    for (final d in apiDomains) {
      final haystack = '${d.id} ${d.name}'.toLowerCase();
      if (keywords.any((k) => haystack.contains(k))) return d;
    }
    return null;
  }

  // ── Build ────────────────────────────────────────────────────────────────

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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Logo — solid purple rounded square
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.explore_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 10),
          const Text(
            'CareerPath AI',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          // Bell — outlined circle
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: const Icon(Icons.notifications_outlined,
                  color: AppColors.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          // Dashboard back pill
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 15, color: AppColors.primary),
                  SizedBox(width: 5),
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Career Explorer',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Explore careers by field of interest.\nDiscover your future through our curated industry pathways.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          ..._domains.map(_buildDomainCard),
          const SizedBox(height: 24),
          _buildBreadcrumb(),
          const SizedBox(height: 32),
          _buildFooter(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDomainCard(CareerDomain domain) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CareerListPage(domain: domain),
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Gradient circle with icon ──────────────────────────────
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: domain.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(domain.icon, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 18),
              // ── Domain name ────────────────────────────────────────────
              Text(
                domain.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // ── Description ───────────────────────────────────────────
              Text(
                domain.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Row(
      children: [
        Text(
          'Home',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right,
            size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        const Text(
          'Explorer',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.explore_rounded,
                    color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 10),
              const Text(
                'CareerPath AI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '\u00a9 2026 Career Explorer. All rights reserved.',
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
