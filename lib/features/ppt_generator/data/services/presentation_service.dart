import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:trueschoolapp/config/app_config.dart';
import 'package:trueschoolapp/features/auth/data/services/token_storage.dart';
import 'package:trueschoolapp/features/ppt_generator/data/models/presentation_model.dart';

class PresentationService {
  static final String _baseUrl = AppConfig.apiUrl;

  static Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// POST /teacher/ai-tool with tool="presentation"
  /// Mirrors the web frontend's runAiTool dispatch exactly.
  static Future<PresentationResult?> generatePresentation({
    required String topic,
    required String subject,
    required String grade,
    required int numSlides,
    required int durationMinutes,
    required String purpose,
    required String visualStyle,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = jsonEncode({
        'tool': 'presentation',
        'subject': subject,
        'topic': topic,
        'grade': grade,
        'extra': {
          'num_slides': numSlides,
          'duration_minutes': durationMinutes,
          'purpose': purpose,
          'visual_style': visualStyle,
        },
      });

      debugPrint('[PresentationService] POST /teacher/ai-tool → topic=$topic');

      final response = await http.post(
        Uri.parse('$_baseUrl/teacher/ai-tool'),
        headers: headers,
        body: body,
      );

      debugPrint(
          '[PresentationService] response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return PresentationResult.fromJson(decoded);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[PresentationService] generatePresentation error: $e');
      return null;
    }
  }
}
