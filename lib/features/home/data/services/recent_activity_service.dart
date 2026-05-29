import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:trueschoolapp/config/app_config.dart';
import 'package:trueschoolapp/features/auth/data/services/token_storage.dart';
import 'package:trueschoolapp/features/home/data/models/recent_activity_item.dart';

class RecentActivityService {
  static final String _baseUrl = AppConfig.apiUrl;

  static Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Fetches recent activity from homework list.
  /// Shows the most recently assigned homework items (all statuses except completed).
  /// Falls back to showing completed items if nothing else is available.
  static Future<List<RecentActivityItem>> getRecentActivity({int limit = 5}) async {
    try {
      final headers = await _authHeaders();

      final hwResponse = await http.get(
        Uri.parse('$_baseUrl/homework/student'),
        headers: headers,
      );

      debugPrint('[RecentActivityService] GET /homework/student → ${hwResponse.statusCode}');
      if (hwResponse.statusCode != 200) {
        debugPrint('[RecentActivityService] error body: ${hwResponse.body}');
        return [];
      }

      final List<dynamic> hwData = jsonDecode(hwResponse.body);
      debugPrint('[RecentActivityService] received ${hwData.length} homework items');

      if (hwData.isEmpty) return [];

      // Convert all items to activity items
      final activities = hwData
          .map((hw) => RecentActivityItem.fromHomework(hw as Map<String, dynamic>))
          .where((a) => a.title.isNotEmpty)
          .toList();

      // Sort: non-completed first (active work), then by assignedDate descending
      // Items without a timestamp keep their original API order (already sorted by due_date asc)
      activities.sort((a, b) {
        // Prioritise active statuses over completed
        final aActive = a.status != 'completed';
        final bActive = b.status != 'completed';
        if (aActive && !bActive) return -1;
        if (!aActive && bActive) return 1;

        // Within same group, sort by timestamp descending (most recent first)
        if (a.timestamp != null && b.timestamp != null) {
          return b.timestamp!.compareTo(a.timestamp!);
        }
        if (a.timestamp != null) return -1;
        if (b.timestamp != null) return 1;
        return 0;
      });

      return activities.take(limit).toList();
    } catch (e) {
      debugPrint('[RecentActivityService] error: $e');
      return [];
    }
  }
}
