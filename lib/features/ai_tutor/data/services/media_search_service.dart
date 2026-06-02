import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:trueschoolapp/config/app_config.dart';
import 'package:trueschoolapp/features/auth/data/services/token_storage.dart';

class MediaResult {
  final String title;
  final String thumbnailUrl;
  final String linkUrl;
  final String? source;

  const MediaResult({
    required this.title,
    required this.thumbnailUrl,
    required this.linkUrl,
    this.source,
  });
}

class MediaSearchService {
  static final String _base = AppConfig.apiUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// POST /media/images — returns image results from the backend.
  static Future<List<MediaResult>> searchImages(
    String query, {
    String grade = '6',
    String board = 'CBSE',
    int maxResults = 6,
  }) async {
    try {
      final headers = await _headers();
      final body = jsonEncode({
        'query': query,
        'grade': grade,
        'board': board,
        'max_results': maxResults,
      });
      final res = await http
          .post(Uri.parse('$_base/media/images'), headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      debugPrint('[MediaSearch] POST /media/images → ${res.statusCode}');
      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);
      final items = _extractList(data);
      return items.map(_parseImageResult).whereType<MediaResult>().toList();
    } catch (e) {
      debugPrint('[MediaSearch] searchImages error: $e');
      return [];
    }
  }

  /// POST /media/videos — returns video results from the backend.
  static Future<List<MediaResult>> searchVideos(
    String query, {
    String grade = '6',
    String board = 'CBSE',
    int maxResults = 4,
  }) async {
    try {
      final headers = await _headers();
      final body = jsonEncode({
        'query': query,
        'grade': grade,
        'board': board,
        'max_results': maxResults,
      });
      final res = await http
          .post(Uri.parse('$_base/media/videos'), headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      debugPrint('[MediaSearch] POST /media/videos → ${res.statusCode}');
      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);
      final items = _extractList(data);
      return items.map(_parseVideoResult).whereType<MediaResult>().toList();
    } catch (e) {
      debugPrint('[MediaSearch] searchVideos error: $e');
      return [];
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// The backend may return a list directly or wrap it in a key.
  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      // Try common wrapper keys
      for (final key in ['results', 'images', 'videos', 'items', 'data']) {
        if (data[key] is List) return data[key] as List;
      }
      // Single object — wrap it
      return [data];
    }
    return [];
  }

  static MediaResult? _parseImageResult(dynamic item) {
    if (item is! Map) return null;
    final title = (item['title'] ?? item['name'] ?? '').toString();
    // thumbnail: try multiple common field names
    final thumb = (item['thumbnail'] ??
            item['thumbnailUrl'] ??
            item['thumbnail_url'] ??
            item['image'] ??
            item['url'] ??
            '')
        .toString();
    final link = (item['link'] ??
            item['url'] ??
            item['contextLink'] ??
            item['source_url'] ??
            thumb)
        .toString();
    final source = (item['source'] ??
            item['displayLink'] ??
            item['domain'] ??
            '')
        .toString();
    if (thumb.isEmpty && link.isEmpty) return null;
    return MediaResult(
      title: title,
      thumbnailUrl: thumb.isNotEmpty ? thumb : link,
      linkUrl: link.isNotEmpty ? link : thumb,
      source: source.isNotEmpty ? source : null,
    );
  }

  static MediaResult? _parseVideoResult(dynamic item) {
    if (item is! Map) return null;
    final title = (item['title'] ?? item['name'] ?? '').toString();
    final thumb = (item['thumbnail'] ??
            item['thumbnailUrl'] ??
            item['thumbnail_url'] ??
            '')
        .toString();
    final link = (item['url'] ??
            item['link'] ??
            item['videoUrl'] ??
            item['video_url'] ??
            '')
        .toString();
    final source = (item['channel'] ??
            item['channelTitle'] ??
            item['source'] ??
            '')
        .toString();
    if (link.isEmpty) return null;
    return MediaResult(
      title: title,
      thumbnailUrl: thumb,
      linkUrl: link,
      source: source.isNotEmpty ? source : null,
    );
  }
}
