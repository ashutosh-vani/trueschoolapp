import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/ai_tutor/data/services/media_search_service.dart';

/// Bottom sheet that shows image + video search results for a topic.
/// Matches the "Related Media" panel in the screenshot.
Future<void> showRelatedMediaSheet(
  BuildContext context, {
  required String topic,
  required bool startOnVideos,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RelatedMediaSheet(
      initialTopic: topic,
      startOnVideos: startOnVideos,
    ),
  );
}

class _RelatedMediaSheet extends StatefulWidget {
  final String initialTopic;
  final bool startOnVideos;

  const _RelatedMediaSheet({
    required this.initialTopic,
    required this.startOnVideos,
  });

  @override
  State<_RelatedMediaSheet> createState() => _RelatedMediaSheetState();
}

class _RelatedMediaSheetState extends State<_RelatedMediaSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  late final TextEditingController _searchCtrl;

  List<MediaResult> _images = [];
  List<MediaResult> _videos = [];
  bool _loadingImages = false;
  bool _loadingVideos = false;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.startOnVideos ? 1 : 0,
    );
    _searchCtrl = TextEditingController(text: widget.initialTopic);
    // Auto-search on open
    WidgetsBinding.instance.addPostFrameCallback((_) => _doSearch());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loadingImages = true;
      _loadingVideos = true;
      _searched = true;
    });

    final results = await Future.wait([
      MediaSearchService.searchImages(q),
      MediaSearchService.searchVideos(q),
    ]);

    if (!mounted) return;
    setState(() {
      _images = results[0];
      _videos = results[1];
      _loadingImages = false;
      _loadingVideos = false;
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Related Media',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'CBSE · Grade 6-A',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close,
                      color: Color(0xFF6B7280), size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5FA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.search,
                            color: Color(0xFF9CA3AF), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style: const TextStyle(
                                fontSize: 13, fontFamily: 'Poppins'),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 12),
                            ),
                            onSubmitted: (_) => _doSearch(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _doSearch,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Search',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: false,
              labelColor: AppColors.primary,
              unselectedLabelColor: const Color(0xFF6B7280),
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.image_outlined, size: 16),
                      const SizedBox(width: 6),
                      const Text('Images'),
                      if (_images.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _CountBadge(_images.length),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_circle_outline, size: 16),
                      const SizedBox(width: 6),
                      const Text('Videos'),
                      if (_videos.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _CountBadge(_videos.length),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildImagesTab(),
                _buildVideosTab(),
              ],
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: const Center(
              child: Text(
                'Images via Google · Videos via YouTube · Cached 30 days',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9CA3AF),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesTab() {
    if (_loadingImages) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searched && _images.isEmpty) {
      return _buildEmptyState(
        icon: Icons.image_search,
        message: 'No images found.\nTry a different search term.',
        fallbackLabel: 'Search on Google Images',
        fallbackUrl:
            'https://www.google.com/search?tbm=isch&q=${Uri.encodeComponent(_searchCtrl.text)}',
      );
    }
    if (!_searched) {
      return const Center(
        child: Text('Enter a topic and tap Search',
            style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 13,
                fontFamily: 'Poppins')),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _images.length,
      itemBuilder: (_, i) => _ImageCard(
        result: _images[i],
        onTap: () => _openUrl(_images[i].linkUrl),
      ),
    );
  }

  Widget _buildVideosTab() {
    if (_loadingVideos) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searched && _videos.isEmpty) {
      return _buildEmptyState(
        icon: Icons.play_circle_outline,
        message: 'No videos found.\nTry a different search term.',
        fallbackLabel: 'Search on YouTube',
        fallbackUrl:
            'https://www.youtube.com/results?search_query=${Uri.encodeComponent(_searchCtrl.text)}',
      );
    }
    if (!_searched) {
      return const Center(
        child: Text('Enter a topic and tap Search',
            style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 13,
                fontFamily: 'Poppins')),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _videos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _VideoCard(
        result: _videos[i],
        onTap: () => _openUrl(_videos[i].linkUrl),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String fallbackLabel,
    required String fallbackUrl,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFFE5E7EB)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontFamily: 'Poppins',
                  height: 1.5),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _openUrl(fallbackUrl),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  fallbackLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Image card ────────────────────────────────────────────────────────────────
class _ImageCard extends StatelessWidget {
  final MediaResult result;
  final VoidCallback onTap;

  const _ImageCard({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: result.thumbnailUrl.isNotEmpty
                    ? Image.network(
                        result.thumbnailUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF5F5FA),
                          child: const Icon(Icons.broken_image_outlined,
                              color: Color(0xFFD1D5DB), size: 32),
                        ),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: const Color(0xFFF5F5FA),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: const Color(0xFFF5F5FA),
                        child: const Icon(Icons.image_outlined,
                            color: Color(0xFFD1D5DB), size: 32),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                result.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A2E),
                  fontFamily: 'Poppins',
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Video card ────────────────────────────────────────────────────────────────
class _VideoCard extends StatelessWidget {
  final MediaResult result;
  final VoidCallback onTap;

  const _VideoCard({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail with play overlay
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
              child: Stack(
                children: [
                  result.thumbnailUrl.isNotEmpty
                      ? Image.network(
                          result.thumbnailUrl,
                          width: 110,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 110,
                            height: 72,
                            color: const Color(0xFFF5F5FA),
                            child: const Icon(Icons.broken_image_outlined,
                                color: Color(0xFFD1D5DB)),
                          ),
                        )
                      : Container(
                          width: 110,
                          height: 72,
                          color: const Color(0xFFF5F5FA),
                          child: const Icon(Icons.play_circle_outline,
                              color: Color(0xFFD1D5DB), size: 32),
                        ),
                  // Play button overlay
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Title + source
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                        fontFamily: 'Poppins',
                        height: 1.3,
                      ),
                    ),
                    if (result.source != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        result.source!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9CA3AF),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Count badge ───────────────────────────────────────────────────────────────
class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge(this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B7280),
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
