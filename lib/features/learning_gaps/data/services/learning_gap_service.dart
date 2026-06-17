import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:trueschoolapp/config/app_config.dart';
import 'package:trueschoolapp/features/auth/data/services/token_storage.dart';
import 'package:trueschoolapp/features/learning_gaps/data/models/learning_gap_model.dart';

class LearningGapService {
  static final String _baseUrl = AppConfig.apiUrl;

  static Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// GET /learning-gaps/ — all learning gaps for the student
  static Future<List<LearningGap>> getLearningGaps() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/learning-gaps/'),
        headers: headers,
      );
      debugPrint('[LearningGapService] GET /learning-gaps/ → ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((d) => LearningGap.fromJson(d as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[LearningGapService] getLearningGaps error: $e');
      return [];
    }
  }

  /// GET /learning-gaps/health — gap health score
  static Future<GapHealth?> getGapHealth() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/learning-gaps/health'),
        headers: headers,
      );
      debugPrint('[LearningGapService] GET /learning-gaps/health → ${response.statusCode}');
      if (response.statusCode == 200) {
        return GapHealth.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('[LearningGapService] getGapHealth error: $e');
      return null;
    }
  }

  /// GET /learning-gaps/{gapId}/remediation — gap detail + AI content
  static Future<GapRemediation?> getRemediation(String gapId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/learning-gaps/$gapId/remediation'),
        headers: headers,
      );
      debugPrint('[LearningGapService] GET /learning-gaps/$gapId/remediation → ${response.statusCode}');
      if (response.statusCode == 200) {
        return GapRemediation.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('[LearningGapService] getRemediation error: $e');
      return null;
    }
  }

  /// GET /learning-gaps/quizzes — list of available quizzes
  static Future<List<Quiz>> getQuizList() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/learning-gaps/quizzes'),
        headers: headers,
      );
      debugPrint('[LearningGapService] GET /learning-gaps/quizzes → ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((d) => Quiz.fromJson(d as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[LearningGapService] getQuizList error: $e');
      return [];
    }
  }

  /// GET /learning-gaps/quiz/{quizId} — full quiz with questions
  static Future<Quiz?> getQuiz(String quizId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/learning-gaps/quiz/$quizId'),
        headers: headers,
      );
      debugPrint('[LearningGapService] GET /learning-gaps/quiz/$quizId → ${response.statusCode}');
      if (response.statusCode == 200) {
        return Quiz.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('[LearningGapService] getQuiz error: $e');
      return null;
    }
  }

  /// POST /learning-gaps/quiz/submit — submit quiz answers
  static Future<Map<String, dynamic>?> submitQuiz({
    required String quizId,
    required List<Map<String, String>> answers,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = jsonEncode({'quiz_id': quizId, 'answers': answers});
      final response = await http.post(
        Uri.parse('$_baseUrl/learning-gaps/quiz/submit'),
        headers: headers,
        body: body,
      );
      debugPrint('[LearningGapService] POST /learning-gaps/quiz/submit → ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('[LearningGapService] submitQuiz error: $e');
      return null;
    }
  }
}
