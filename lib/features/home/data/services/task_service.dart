import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:trueschoolapp/config/app_config.dart';
import 'package:trueschoolapp/features/auth/data/services/token_storage.dart';
import 'package:trueschoolapp/features/home/data/models/task_item.dart';

class TaskService {
  static final String _baseUrl = AppConfig.apiUrl;

  static Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// GET /student/tasks
  static Future<List<TaskItem>> getTasks() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/student/tasks'),
        headers: headers,
      );
      debugPrint('[TaskService] GET /student/tasks → ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((d) => TaskItem.fromJson(d as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[TaskService] getTasks error: $e');
      return [];
    }
  }

  /// POST /student/tasks?title=...&subject=...
  /// Returns the full refreshed task list so the caller always has clean server state.
  static Future<TaskItem?> addTask(String title, {String subject = 'Custom'}) async {
    try {
      final headers = await _authHeaders();
      // Backend expects query params, not a JSON body
      final uri = Uri.parse('$_baseUrl/student/tasks')
          .replace(queryParameters: {'title': title, 'subject': subject});
      final response = await http.post(uri, headers: headers);
      debugPrint('[TaskService] POST /student/tasks → ${response.statusCode}');
      debugPrint('[TaskService] response body: ${response.body}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          // Backend returns {"id": "...", "_id": ObjectId (may be serialised oddly), ...}
          // Normalise: prefer "id" field, fall back to "_id"
          final id = (body['id'] ?? body['_id'] ?? '').toString();
          return TaskItem(
            id: id,
            title: (body['title'] ?? title).toString(),
            subject: (body['subject'] ?? subject).toString(),
            done: body['done'] == true,
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('[TaskService] addTask error: $e');
      return null;
    }
  }

  /// PATCH /student/tasks/:id/toggle
  static Future<bool?> toggleTask(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/student/tasks/$id/toggle'),
        headers: headers,
      );
      debugPrint('[TaskService] PATCH /student/tasks/$id/toggle → ${response.statusCode}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['done'] as bool?;
      }
      return null;
    } catch (e) {
      debugPrint('[TaskService] toggleTask error: $e');
      return null;
    }
  }
}
