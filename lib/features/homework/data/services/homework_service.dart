import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:trueschoolapp/config/app_config.dart';
import 'package:trueschoolapp/features/auth/data/services/token_storage.dart';
import 'package:trueschoolapp/features/homework/data/models/homework_item.dart';
import 'package:trueschoolapp/features/homework/data/models/homework_question.dart';

class HomeworkService {
  static final String _baseUrl = AppConfig.apiUrl;

  static Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// GET /homework/student — list all homework for the student
  static Future<List<HomeworkItem>> getStudentHomework() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/homework/student'),
        headers: headers,
      );

      debugPrint('[HomeworkService] GET /homework/student → ${response.statusCode}');
      debugPrint('[HomeworkService] body: ${response.body.substring(0, response.body.length.clamp(0, 300))}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((d) => HomeworkItem.fromJson(d as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[HomeworkService] error: $e');
      return [];
    }
  }

  /// GET /homework/{homeworkId} — get homework metadata
  static Future<Map<String, dynamic>?> getHomeworkDetail(String homeworkId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/homework/$homeworkId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// GET /homework/{homeworkId}/questions — get questions for a homework
  static Future<List<HomeworkQuestion>> getQuestions(String homeworkId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/homework/$homeworkId/questions'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((d) => HomeworkQuestion.fromJson(d as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// POST /homework/upload-file — upload a file and return its URL
  static Future<String?> uploadFile(File file) async {
    try {
      final token = await TokenStorage.getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/homework/upload-file'),
      )
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      debugPrint('[HomeworkService] POST /homework/upload-file → ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['url'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('[HomeworkService] uploadFile error: $e');
      return null;
    }
  }

  /// POST /homework/submit — submit answers
  static Future<Map<String, dynamic>?> submitHomework({
    required String homeworkId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/homework/submit'),
        headers: headers,
        body: jsonEncode({
          'homework_id': homeworkId,
          'answers': answers,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// GET /homework/{homeworkId}/result — get submission result
  static Future<Map<String, dynamic>?> getResult(String homeworkId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/homework/$homeworkId/result'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
