import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:trueschoolapp/config/app_config.dart';
import 'package:trueschoolapp/features/auth/data/services/token_storage.dart';
import 'package:trueschoolapp/features/notifications/data/models/notification_item.dart';

class NotificationService {
  static final String _baseUrl = AppConfig.apiUrl;

  static Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// GET /student/notifications
  static Future<List<NotificationItem>> getNotifications() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/student/notifications'),
        headers: headers,
      );

      debugPrint('[NotificationService] GET /student/notifications → ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((d) => NotificationItem.fromJson(d as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[NotificationService] error: $e');
      return [];
    }
  }

  /// PATCH /student/notifications/:id/read
  static Future<bool> markAsRead(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/student/notifications/$id/read'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[NotificationService] markAsRead error: $e');
      return false;
    }
  }
}
