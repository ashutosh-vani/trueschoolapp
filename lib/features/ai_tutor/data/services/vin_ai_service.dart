import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:trueschoolapp/config/app_config.dart';
import 'package:trueschoolapp/features/auth/data/services/token_storage.dart';

/// Service for all /vin-ai/* endpoints.
class VinAiService {
  static final String _base = AppConfig.apiUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── SSE streaming chat ──────────────────────────────────────────────────────

  /// Streams XML tokens from POST /vin-ai/chat.
  /// Yields raw XML string chunks; caller accumulates them.
  /// Completes when [DONE] is received.
  static Stream<String> streamChat({
    required String message,
    required List<Map<String, String>> history,
  }) async* {
    yield* _streamSSE(
      '/vin-ai/chat',
      {'message': message, 'history': history},
    );
  }

  /// Streams XML tokens from POST /vin-ai/answer (MCQ feedback).
  static Stream<String> streamAnswer({
    required String question,
    required String chosen,
    required bool correct,
    required List<Map<String, String>> history,
  }) async* {
    yield* _streamSSE(
      '/vin-ai/answer',
      {
        'question': question,
        'chosen': chosen,
        'correct': correct,
        'history': history,
      },
    );
  }

  static Stream<String> _streamSSE(
    String path,
    Map<String, dynamic> body,
  ) async* {
    final headers = await _headers();
    final uri = Uri.parse('$_base$path');

    final request = http.Request('POST', uri);
    request.headers.addAll(headers);
    request.body = jsonEncode(body);

    try {
      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode != 200) {
        debugPrint('[VinAiService] SSE error: ${response.statusCode}');
        yield _errorXml;
        return;
      }

      final buffer = StringBuffer();

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer.write(chunk);
        // Process complete lines
        final text = buffer.toString();
        final lines = text.split('\n');

        // Keep the last (possibly incomplete) line in the buffer
        buffer.clear();
        buffer.write(lines.last);

        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6);
          if (data == '[DONE]') {
            client.close();
            return;
          }
          // Backend escapes newlines as \n — restore them
          final token = data.replaceAll(r'\n', '\n');
          yield token;
        }
      }
      client.close();
    } catch (e) {
      debugPrint('[VinAiService] stream error: $e');
      yield _errorXml;
    }
  }

  static const _errorXml =
      '<response><subject>General</subject><content>Sorry, something went wrong. Please try again.</content><followups><followup>Try again</followup></followups></response>';

  // ── History ─────────────────────────────────────────────────────────────────

  /// GET /vin-ai/history — last 50 conversation turns.
  static Future<List<DoubtHistoryItem>> getHistory() async {
    try {
      final headers = await _headers();
      final response = await http.get(
        Uri.parse('$_base/vin-ai/history'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((d) => DoubtHistoryItem.fromJson(d as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[VinAiService] getHistory error: $e');
    }
    return [];
  }

  /// POST /vin-ai/history/{id}/star — toggle star.
  static Future<bool> toggleStar(String id) async {
    try {
      final headers = await _headers();
      final response = await http.post(
        Uri.parse('$_base/vin-ai/history/$id/star'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['starred'] as bool? ?? false;
      }
    } catch (e) {
      debugPrint('[VinAiService] toggleStar error: $e');
    }
    return false;
  }
}

// ── Model ────────────────────────────────────────────────────────────────────

class DoubtHistoryItem {
  final String id;
  final String question;
  final String subject;
  final String preview;
  final String fullXml;
  bool starred;
  final String createdAt;

  DoubtHistoryItem({
    required this.id,
    required this.question,
    required this.subject,
    required this.preview,
    required this.fullXml,
    required this.starred,
    required this.createdAt,
  });

  factory DoubtHistoryItem.fromJson(Map<String, dynamic> json) =>
      DoubtHistoryItem(
        id: json['_id'] ?? json['id'] ?? '',
        question: json['question'] ?? '',
        subject: json['subject'] ?? 'General',
        preview: json['preview'] ?? '',
        fullXml: json['full_xml'] ?? '',
        starred: json['starred'] ?? false,
        createdAt: json['created_at'] ?? '',
      );
}
